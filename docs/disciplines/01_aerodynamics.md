# Aerodynamics Discipline

## 1. Abstract Interface

**File:** `src/base/AerodynamicsBase.m`

```matlab
classdef AerodynamicsBase < handle
    methods (Abstract)
        polar = drag_polar(obj, state)   % state: AircraftState object
        CL    = CLmax(obj, state)
    end
end
```

`state` is an `AircraftState` object that carries altitude, Mach, atmospheric properties (T, P, rho, a, V, q) in English units. It is constructed by `AircraftState(alt_ft, mach)` which calls MATLAB's `atmosisa` internally.

### Why These Two Methods

The sizing loop and mission analysis need to compute thrust required and fuel burn. Both depend on the drag polar coefficients, not on CD directly. Passing coefficients rather than CD allows the consumer to evaluate CD at any CL, which is needed for:
- Cruise: CL is back-calculated from lift equilibrium `CL = W / (q * S_ref)`.
- Sustained turn: `CL = n * W / (q * S_ref)`.
- Takeoff constraint: the CL at liftoff.

If only CD at the current operating point were returned, the constraint analysis could not sweep W/S and evaluate drag at each candidate design point.

`CLmax` is separate because its value depends on flap configuration and, at higher fidelity, on Reynolds number and Mach number. It is used by the stall-speed constraint (landing W/S upper bound) and by the ceiling constraint (maximum CL at which lift equals weight).

### Why CD0, K1, K2 Separately

The drag model throughout the framework is:

```
CD = CD0 + K1*CL + K2*CL^2
```

Returning `{CD0, K1, K2}` is the correct decomposition because:
- `CD0` (zero-lift drag) is used in the takeoff constraint formula separately from the induced drag terms.
- `K1` is the linear CL term arising from camber (K1 = 0 for a symmetric polar).
- `K2` is the induced drag factor. In the Breguet range equation, the optimal CL for range is where `d(CD/CL)/dCL = 0`, which requires knowing K2 and CD0 independently.

Returning only CD at a single operating point would prevent these computations.

---

## 2. Level 1 Aerodynamics

**File:** `src/Disciplines/Aerodynamics/AeroLevel1.m`

**Physics:** Type-based Cf table + K_LD factor.

### drag_polar

```
CD0 = Cf * S_wet / S_ref
AR_wet = b^2 / S_wet
LD_max = K_LD * sqrt(AR_wet)
K2 = 1 / (4 * LD_max^2 * CD0)
K1 = 0
```

The formula `K2 = 1/(4 * LD_max^2 * CD0)` is derived from the condition that at the L/D maximum, `dCD/dCL = 0`:
```
CD = CD0 + K2*CL^2
CL_opt = sqrt(CD0 / K2)
LD_max = CL_opt / (2*CD0) = 1 / (2*sqrt(K2*CD0))
=> K2 = 1 / (4 * LD_max^2 * CD0)
```

**Cf values (Raymer Table 12.3):**

| Type | Cf |
|------|----|
| Air Force fighter | 0.0035 |
| Navy fighter | 0.0040 |
| Civil transport | 0.0026 |
| Military cargo | 0.0035 |
| Supercruise | 0.0025 |

**K_LD values (Raymer, 6th ed., p. 40):**

| Type | K_LD |
|------|------|
| Jet fighter / military jet | 14 |
| Civil jet | 15.5 |
| Retractable prop | 11 |

**AR_wet definition:** `AR_wet = b^2 / S_wet`. This is the wetted aspect ratio (also called span loading over wetted area). It characterises how much of the span is devoted to generating lift versus friction drag.

### CLmax

Returned from Raymer's historical table (built into `AeroLevel1.CLmax_table`). For fighters, typical clean CLmax = 1.2 to 1.8; the mean 1.5 is used by default. This method does not use `state` — CLmax at L1 is a constant for the aircraft type.

### F-16 at L1

Using Cf = 0.0035 (air force fighter), S_wet from Roskam regression, S_ref = 300 ft², b = 30 ft:
- The Roskam regression gives S_wet roughly 1200–1400 ft² for W_TO near 31,000 lb.
- CD0 ≈ 0.0035 * 1300 / 300 ≈ 0.0152, which is lower than Brandt's mission CD0 of 0.0270.
- The discrepancy is expected at L1. The Raymer Cf table value is calibrated for CDmin in clean cruise, not for the effective mission CD0 that includes gear, stores, and CDx increments.

---

## 3. Level 2 Aerodynamics

**File:** `src/Disciplines/Aerodynamics/AeroLevel2.m`

**Physics:** Oswald efficiency factor replaces the K_LD approximation. Cfe (effective skin friction coefficient) replaces the Raymer type-table Cf.

### drag_polar

```
CD0 = Cfe * S_wet / S_ref
K2  = 1 / (pi * AR * e_osw)
K1  = 0
```

**Why e_osw instead of K_LD:** The K_LD method implicitly assumes a fixed relationship between AR_wet and induced drag. The Oswald efficiency factor explicitly captures the non-elliptic lift distribution over the physical wing planform. For a low-AR, highly swept fighter wing (F-16: AR = 3.0), the difference matters.

**Why Cfe instead of Cf at L2:** For the F-16, the Brandt spreadsheet gives the effective Cf back-calculated from the mission CD0 and the known S_wet:

```
Cfe = CD0_mission * S_ref / S_wet
    = 0.0270 * 300 / 1331.09
    = 0.005908
```

This Cfe captures not just skin friction but also the pressure drag, interference drag, and the CDx contributions baked into the mission-average CD0. Using 0.005908 instead of 0.0035 (Raymer type table) gives CD0 calibrated to match Brandt's validated mission analysis.

**Source in JSON:** `aero.Cfe = 0.005908` is stored in `f16a_geometry.json`.

### CLmax

Same tabular lookup as L1. No improvement in CLmax fidelity at L2.

### Known Limitations

- K1 = 0 is still assumed. For the F-16's cambered wing (NACA 1404), the true K1 ≈ -0.00630. This shifts the optimal CL slightly and affects the sustained-turn constraint.
- S_wet is still from the Roskam regression (or passed in from GeometryLevel2 which also uses the regression plus an explicit wing calculation). The regression uncertainty propagates into CD0.

---

## 4. Level 3 Aerodynamics

**File:** `src/Disciplines/Aerodynamics/AeroLevel3.m`

**Physics:** Reynolds-number-based turbulent Cf for each component; K1 computed from CL_minD.

### drag_polar

**Component buildup:**
```
CD0 = sum_i [ Cf_turb(Re_i, M) * FF_i * Q_i * S_wet_i ] / S_ref
```
where:
- `Cf_turb(Re, M)` = turbulent flat-plate friction coefficient from the Schlichting formula (or Raymer's empirical fit)
- `FF_i` = form factor for component i (wing, fuselage, nacelle, etc.)
- `Q_i` = interference factor
- `S_wet_i` = wetted area of component i

**K1 from CL_minD:** When the wing has camber (non-zero design lift coefficient CL_d), the drag polar minimum shifts:
```
K1 = -2 * K2 * CL_minD
```
The F-16 wing (NACA 1404 airfoil) has a very thin camber line (max camber = 1% chord), giving CL_minD ≈ 0.027. With K2 ≈ 0.1160, K1 ≈ -0.00630, consistent with the Brandt value.

K1 cannot be computed without knowing CL_minD, which requires the explicit airfoil and planform geometry available at L3. This is why K1 = 0 is accepted at L1 and L2.

**Reynolds number dependency:** `Re = rho * V * c_ref / mu`. At altitude, rho and mu both change. The `state` object carries the atmospheric properties needed to evaluate Re. This is why `drag_polar` takes a `state` argument rather than a fixed value.

### CLmax at L3

Still primarily table-based, but modified by:
- Flap deflection angle (TE flap increases CLmax by up to 0.6)
- Leading edge device effectiveness (L3 geometry provides leading edge chord fractions)
- Mach number correction (CLmax decreases at high subsonic Mach)

### F-16 at L3

Target values from Brandt:
- CDmin (Aero tab) = 0.0170 (subsonic CDmin without CDx, clean)
- K2 = 0.1160
- K1 = -0.00630
- CLmax clean = 0.984
- CLmax TO = 1.276
- CLmax land = 1.426

The L3 component buildup should approach CD0 ≈ 0.0170 in clean subsonic cruise. The mission CD0 of 0.0270 is obtained by adding the segment-specific CDx (landing gear, stores) in the mission analysis, not in the aerodynamics module.

---

## 5. Level 4 Aerodynamics

**File:** `src/Disciplines/Aerodynamics/AeroLevel4.m`

**Physics:** L3 + wave drag correction for M > M_crit.

### Wave Drag Addition

```
CD_wave = CD_wave_body + CD_wave_wing
```

Brandt uses a wave drag factor based on the Sears-Haack body equivalent and the wing thickness-to-chord ratio:
```
CD_wave_wing ≈ Ewd * (t/c)^2 * k_wave(M, sweep)
```
where `Ewd = 2.2` for the F-16 (from `f16a_geometry.json` `aero.Ewd`).

At M < M_crit, wave drag = 0. At M > M_div, wave drag increases steeply. The exact M_crit and M_div depend on the wing t/c and sweep.

The F-16 M_crit = 0.873 (from JSON `aircraft.Mcrit`). The constraint analysis at M = 1.60 (max Mach sprint) requires L4 drag; using L3 without wave drag underpredicts T/W for that constraint.

---

## 6. The CD0 Two-Values Problem

Brandt's Excel has two different CD0 entries for the F-16:
- **Aero tab CDmin_sub = 0.01691** — the pure subsonic minimum drag coefficient from the component-buildup model (Cf * Swet / Sref using Cfe_tab = 0.00370, which is the Raymer-type lookup value).
- **Miss tab CD0 = 0.0270** — the effective mission drag coefficient used in the mission fuel computation.

The Miss tab CD0 is larger because it includes:
- CDx from landing gear and external stores during certain segments
- An effective Cfe that absorbs pressure drag, interference drag, and installation effects

The framework uses CD0 = 0.0270 for mission and constraint analysis at L1 and L2 (by using Cfe = 0.005908). At L3, the aerodynamics module returns CDmin ≈ 0.0170, and the mission analysis module adds the segment-specific CDx increment on top, reconstructing the effective 0.0270 for segments with gear or stores out.

**Key design decision:** The constraint analysis at L1/L2 sources CD0 from the aerodynamics module, which at L2 is calibrated to 0.0270. This means the constraint analysis at L2 is using the full mission-drag CD0, not the clean CDmin. This is conservative for performance constraints but matches the Brandt validation approach.

At L3, the constraint analysis sources CD0 from the aerodynamics module (which returns CDmin ≈ 0.0170 subsonic) and adds the CDx from the constraint conditions. For the F-16 constraints, CDx = 0 for all except takeoff (CDx = 0.035). The Brandt validation uses CDmin_sub from the Aero tab for constraint conditions.

---

## 7. K1 = 0 Assumption at L1 and L2

**When it matters:**

For a symmetric polar (K1 = 0), the minimum drag point is at CL = 0. The drag at any CL is:
```
CD = CD0 + K2 * CL^2
```

For a cambered polar (K1 != 0), the minimum drag point is at CL = -K1 / (2*K2) > 0, and:
```
CD = CD0 + K1*CL + K2*CL^2
```

The effect at typical cruise CL (~0.3 for the F-16): with K1 = -0.00630 and CL = 0.3, the K1 term contributes -0.00630 * 0.3 = -0.00189 to CD. This is about a 7% correction to CD0 = 0.0270. For the constraint analysis sustained-turn condition (CL ~ 0.8), the correction is about -0.00504, roughly 19% of CD0.

K1 = 0 at L1/L2 therefore slightly overpredicts required T/W for sustained-turn constraints and underpredicts range at high CL. The error is accepted at these fidelity levels.

---

## 8. Known Limitations

1. `AeroLevel1.CLmax` ignores Mach and altitude — acceptable at L1 where state is not used.
2. The S_wet input to L1/L2 comes from geometry, which at early iterations is based on a W_TO guess. This creates a circularity (see framework overview, Section 11).
3. L2 Cfe = 0.005908 is calibrated to the F-16. For a different aircraft, this value must be back-calculated from a known CD0 or estimated differently.
4. The wave drag model at L4 uses a simplified formula (Brandt Ewd factor) rather than a full transonic aerodynamic computation.
