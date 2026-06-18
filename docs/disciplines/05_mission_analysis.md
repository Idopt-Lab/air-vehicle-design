# Mission Analysis Discipline

## 1. Abstract Interface

**File:** `src/base/MissionBase.m`

```matlab
classdef MissionBase < handle
    methods (Abstract)
        W_fuel = compute_fuel(obj, aero, prop, W_TO, req)
    end
end
```

`req` is a struct that must contain at minimum:
- `req.W_payload` — payload weight (lbf)
- `req.S_ref` — wing reference area (ft²)
- `req.AR` — aspect ratio
- `req.aircraft_type` — string (used for L1 table lookups)
- `req.segments` — struct array defining the mission profile

### Why One Method

The sizing loop needs a single scalar: how much fuel does this aircraft burn on its design mission? Everything else (segment durations, intermediate weights, lift/drag at each point) is discipline-internal. Returning `W_fuel` as a scalar allows the sizing loop to close the weight equation regardless of how the mission was analyzed.

### Why `aero` and `prop` Are Passed

At L2+, `compute_fuel` calls `aero.drag_polar(state)` and `prop.TSFC(state)` at each segment. Passing the discipline objects in rather than reading cached values allows any combination of fidelity levels to work together without modification.

At L1, these arguments are received but ignored — L1 uses tabulated LD and TSFC from Roskam/Raymer tables directly.

### Why `req.AR` Is Needed

`aero.drag_polar(state)` returns `{CD0, K1, K2}`. To evaluate lift-to-drag ratio at cruise CL, the mission analysis needs to solve for optimal CL (range equation) or at-weight CL (prescribed trajectory). The Breguet range equation requires the Oswald efficiency, which L2/L3 aerodynamics stores as `e = 1/(π·AR·K2)`. The AR must therefore flow into the mission analysis to back-calculate `e_osw` from `K2`.

---

## 2. Level I Mission Analysis

**File:** `src/Disciplines/MissionAnalysis/MissionAnalysisLevel1.m`

**Physics:** Roskam Table 2.1 segment fuel fractions + tabulated Breguet for cruise and loiter.

### Segment Fuel Fractions

For segments where the physics is driven primarily by propulsion throttle scheduling (startup, taxi, takeoff, climb, descent, landing), Roskam Table 2.1 provides historical weight ratios `W_i / W_{i-1}` by aircraft type. These are hard-coded as a `Constant` property table in `MissionAnalysisLevel1`.

| Segment | Fighter typical | Transport typical |
|---|---|---|
| Startup | 0.990 | 0.990 |
| Taxi | 0.990 | 0.990 |
| Takeoff | 0.990 | 0.995 |
| Climb | 0.980 | 0.980 |
| Descent | 0.995 | 0.990 |
| Landing | 0.992 | 0.992 |

### Cruise and Loiter

For cruise and loiter segments, tabulated LD and TSFC values replace the fuel fractions. The Breguet equation is evaluated once at fixed conditions (single-point, not integrated):

**Cruise (Breguet range):**
```
W_f / W_i = 1 - exp( -R * TSFC / V_cruise * CD/CL )
```
where `CD/CL = 1/LD_cruise` and `LD_cruise` comes from the Roskam table (not from the `aero` object). The table gives LD at best-cruise conditions for each aircraft type.

**Loiter (Breguet endurance):**
```
W_f / W_i = 1 - exp( -E * TSFC * CD/CL )
```
where `E` is endurance in seconds.

### The 0.866 Cruise Correction

The Roskam table gives L/D*max* for the aircraft type. For best range cruise, the optimal CL is not at L/D_max but at:

```
CL_opt_range = CL_minD / √3    (for a parabolic polar with K1=0)
```

which gives:

```
(L/D)_opt_range = (√3 / 4) * L/D_max ≈ 0.866 * L/D_max
```

The segment methods apply this 0.866 correction internally. The tabulated L/D is L/D_max; the correction converts it to the L/D achievable at best-range cruise.

### Bug Fix: Non-Existent AeroLevel1 Methods

Casey's original implementation called `AeroLevel1.get_LDmax_cruise(LD_cr, engine_type)` and `AeroLevel1.get_LDmax_loiter(LD_lt, engine_type)` — neither of these methods exists in `AeroLevel1`. The fix: use the raw tabulated LD values directly from the `cruise_LD` and `loiter_LD` Constant tables, and apply the 0.866 correction inside the segment methods.

---

## 3. Level II Mission Analysis

**File:** `src/Disciplines/MissionAnalysis/MissionAnalysisLevel2.m`

**Physics:** Single-point Breguet per segment, calling `aero.drag_polar` and `prop.TSFC`.

### Segment Loop

For each segment in `req.segments`:
1. Construct `AircraftState(seg.altitude_ft, seg.mach)`
2. Call `polar = aero.drag_polar(state)` → get `CD0, K1, K2`
3. Call `TSFC = prop.TSFC(state)` → get TSFC in 1/s
4. Compute current CL from lift equilibrium: `CL = W_mid / (state.q * S_ref)`
5. Compute `CD = CD0 + K1*CL + K2*CL^2`
6. Apply Breguet: `W_f / W_i = 1 - exp(-segment_fuel_fraction)`

The mid-segment weight `W_mid` is estimated as the weight at the start of the segment (start-of-segment fuel fraction applied to W_TO). This is the standard single-point approximation.

### Difference from L1

L2 calls into `aero` and `prop` discipline objects rather than reading tables. This means:
- CD0 reflects the aircraft's actual configuration (component drag buildup at L3)
- K2 reflects the actual Oswald efficiency
- TSFC reflects altitude and Mach dependence

The single-point approximation remains: CL is evaluated at one operating point per segment, not integrated over the changing weight.

---

## 4. Level III Mission Analysis

**File:** `src/Disciplines/MissionAnalysis/MissionAnalysisLevel3.m`

**Physics:** Sub-segmented Breguet integration; L/D recomputed as weight changes.

### Sub-Segment Integration

For cruise and dash segments, the segment is divided into `n_sub` sub-intervals (default 20). At each sub-interval:
- `W_sub` is updated from the previous sub-interval fuel burn
- `CL = W_sub / (q * S_ref)` is recomputed
- `CD = CD0 + K1*CL + K2*CL^2` is recomputed
- Fuel for the sub-interval is computed from single-point Breguet

This captures the effect of the aircraft getting lighter as it burns fuel. At cruise, a lighter aircraft wants to fly at a lower CL (same altitude/speed), moving up the drag polar and improving L/D. Over a long-range cruise, this effect (called the "cruise-climb" or Breguet improvement) is significant.

### Energy-Height Climb

For climb segments, `MissionAnalysisLevel3` uses an energy-height method rather than a simple fuel fraction:

```
dh_e/dt = (T - D) * V / W   % excess specific power
dW_fuel/dt = TSFC * T

t_climb = ∫ dh_e / (excess_Ps)   (numerical integration)
W_fuel_climb = ∫ TSFC * T * dt
```

This requires a thrust model (`prop.thrust_lapse`) and a drag model (`aero.drag_polar`) at each altitude step. The integration uses `atmosisa` at each altitude to get the correct atmospheric properties.

### `compute_LD_revised`

A static method used internally:

```matlab
function LD = compute_LD_revised(W, q, S, CD0, e, AR)
    K2 = 1/(pi * e * AR);
    CL = W / (q * S);
    CD = CD0 + K2 * CL^2;
    LD = CL / CD;
end
```

This is the correct name. Casey's original L4 code called `compute_revised_LD_ratio` (which does not exist), causing a silent error.

---

## 5. Level IV Mission Analysis

**File:** `src/Disciplines/MissionAnalysis/MissionAnalysisLevel4.m`

**Physics:** Delegates entirely to `MissionAnalysisLevel3`. The L4 tag is reserved for future higher-fidelity mission integration (e.g., 3-DOF trajectory optimization).

**Bug fix:** Casey's original called `MissionAnalysisLevel3.compute_revised_LD_ratio`, which doesn't exist. The fix renames all calls to `compute_LD_revised` (the actual method name in L3).

---

## 6. Mission Profile Format

`req.segments` is a struct array. Each element has:

| Field | Type | Required for | Example |
|---|---|---|---|
| `name` | string | All levels | `'cruise'`, `'loiter'`, `'climb'` |
| `altitude_ft` | scalar | All levels | `40000` |
| `mach` | scalar | All levels | `0.87` |
| `range_ft` | scalar | cruise, dash | `190.8 * 6076` (nmi → ft) |
| `time_min` | scalar | loiter, combat | `20` |
| `W_drop` | scalar | combat | `4400` (weapons released) |

If a required field is absent for a segment type, the segment method raises an error.

---

## 7. F-16 Mission Profile Discrepancy

Brandt's F-16 sizing uses 14 mission segments (with patrol loiters and a second climb leg). The design study scripts use a simplified 11-segment profile (patrol legs omitted). Consequently:

- L1 fuel estimates are 15–25% lower than Brandt's 6,000 lb
- L2/L3 estimates are 10–20% lower

This is not an error — it is a deliberate simplification for the design study. The key check is that fuel estimates are *within the right order of magnitude* and that W_TO converges to approximately 31,000–33,000 lb.
