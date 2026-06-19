# Propulsion Discipline

## 1. Abstract Interface

**File:** `src/base/PropulsionBase.m`

```matlab
classdef PropulsionBase < handle
    properties
        T0   % sea-level thrust (lbf); set externally by sizing loop
    end
    methods (Abstract)
        alpha = thrust_lapse(obj, state)   % dimensionless, [0,1]
        cj    = TSFC(obj, state)           % 1/s
    end
end
```

`state` is an `AircraftState` object: altitude, Mach, atmospheric properties in English units.

### Why Two Methods

The sizing loop and mission analysis need two separate pieces of propulsion information:

- **`thrust_lapse(state)`** scales installed sea-level thrust to actual thrust at altitude and Mach. It is used by the constraint analysis to determine how much of the sea-level thrust rating is available at each operating condition.
- **`TSFC(state)`** returns the instantaneous thrust-specific fuel consumption. It is used by `compute_fuel` in the mission analysis to integrate fuel burn over each segment.

Returning separate thrust lapse and TSFC is the correct decomposition because cruise TSFC and climb thrust are independent quantities that improve with different physics (BPR affects TSFC more than lapse rate; compression ratio affects lapse more than TSFC).

### Why `T0` Is a Settable Property

The sea-level thrust `T0` is not known until the sizing loop converges. It is computed as `T0 = T_W_opt × W_TO` during each iteration. The propulsion object must be updated in place (MATLAB handle semantics: `prop.T0 = T_SL`) so that `TSFC(state)` can normalize correctly. If `T0` were a constructor argument, the sizing loop could not update it without creating a new object each iteration.

---

## 2. Level I Propulsion

**File:** `src/Disciplines/Propulsion/PropulsionLevel1.m`

**Physics:** Lookup tables from Raymer and Roskam. No atmospheric equations.

### TSFC

Type-based table from Raymer Table 3.3 (turbojet) and Table 3.4 (turbofan). Values are representative of cruise TSFC at `~ 36,000 ft / M 0.8` for each engine class.

| Engine type | Cruise TSFC (1/hr) | Source |
|---|---|---|
| `turbojet` | 0.9 | Raymer T3.3 |
| `low-bypass turbofan` | 0.8 | Raymer T3.4 |
| `high-bypass turbofan` | 0.5 | Raymer T3.4 |
| `turboprop` | 0.5 | Roskam |

The `engine_type` string is passed in the constructor; `TSFC(state)` returns the tabulated value regardless of `state` (the method ignores altitude and Mach at L1).

### Thrust Lapse

The density-ratio approximation: `alpha = (rho / rho_SL)^0.6`

This exponent (0.6) is the Raymer typified value for turbofans. No Mach correction is applied at L1.

### What Is Not Captured

- Mach-number dependence of lapse rate (transonic thrust bucket for afterburning engines)
- Afterburner TSFC vs military TSFC distinction
- Installation losses (inlet/nozzle efficiency)

These omissions are acceptable at L1 where the goal is W_TO closure, not engine cycle design.

---

## 3. Level II Propulsion

**File:** `src/Disciplines/Propulsion/PropulsionLevel2.m`

**Physics:** Mattingly installed thrust and TSFC correlations.

### TSFC

Mattingly's simplified non-installed TSFC model for turbojet/turbofan:

```
TSFC_installed = TSFC_non-installed * installation_factor
```

The installation factor accounts for intake pressure recovery and nozzle losses. Typical values: 1.04–1.08 for a fighter, 1.02–1.05 for a transport.

TSFC has a Mach-number correction:
```
TSFC(M) = TSFC_ref * (1 + kM * M)
```
where `kM ≈ 0.2` for low-BPR turbofans (Mattingly, Elements of Gas Turbine Propulsion, Table 1.1).

### Thrust Lapse

Mattingly density-ratio lapse with Mach correction:

```
alpha = (rho/rho_SL)^n * (1 - C_M*(M - M_ref))  for M > M_ref
```

The Mach correction captures the transonic thrust reduction. For afterburning engines, the military and afterburning power settings have different exponents.

---

## 4. Level III Propulsion

**File:** `src/Disciplines/Propulsion/PropulsionLevel3.m`

**Physics:** Same Mattingly correlations as L2 but with separate dry (military) and wet (afterburner) lapse rates. Distinguishes between different throttle settings.

The F-16 carries both military (non-afterburning, T_mil ≈ 15,000 lbf) and afterburning (T_AB ≈ 23,770 lbf) ratings. At L3, the `thrust_lapse` method returns the lapse relative to whichever rating is set as `T0`. This matters for the constraint analysis: the sustained-turn constraint runs at military thrust; the dash and energy-maneuverability constraints run at afterburner.

---

## 5. Level IV Propulsion

**File:** `src/Disciplines/Propulsion/PropulsionLevel4.m`

**Physics:** Same as L3, plus optional `scale_engine` method (Raymer Ch 10) to resize a reference engine cycle to a new thrust rating.

At AOE 4065 fidelity, L4 propulsion is functionally identical to L3; the `scale_engine` path is a placeholder for students who want to account for how engine weight changes with thrust.

---

## 6. Discrepancies Between Fidelity Levels

| Quantity | Brandt GT | L1 | L2 | L3 |
|---|---|---|---|---|
| TSFC_mil cruise (1/hr) | 0.70 | ~0.80 (table) | Mattingly correlation | Mattingly with correction |
| TSFC_AB cruise (1/hr) | 2.20 | Not distinguished | ~2.0–2.4 | ~2.0–2.4 |
| Thrust lapse at 36k ft / M0.87 | ~0.34 (AB) | ~0.30–0.40 (density ratio) | Mattingly | Mattingly |
| Military vs AB distinction | Yes | No | Yes (separate T0) | Yes |

The largest source of error at L1 is treating the engine as a single operating point (fixed TSFC regardless of conditions). L2 and above recover approximately correct trends with altitude and Mach.

---

## 7. Key Design Decisions

**Why TSFC in 1/s not 1/hr:** The mission segment equations integrate fuel flow over time in seconds. Storing TSFC in 1/s avoids unit conversion inside each mission segment calculation.

**Why `T0` defaults to `T_AB_SLS` from JSON:** At the beginning of sizing, no converged thrust is known. Initializing to the afterburner rating from the Brandt Excel file (`engine.T_AB_SLS_lb`) gives a reasonable starting point for the first iteration. The sizing loop overwrites this value at the start of each iteration.

**Why not return specific thrust:** Returning specific thrust (F/ṁ) instead of `thrust_lapse` would require knowing mass flow, which is not available at L1. The lapse approach is abstraction-appropriate at these fidelity levels.
