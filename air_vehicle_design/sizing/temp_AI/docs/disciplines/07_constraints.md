# Constraint Analysis Discipline

## 1. Abstract Interface

**File:** `src/base/ConstraintBase.m`

```matlab
classdef ConstraintBase < handle
    methods (Abstract)
        result = optimal_point(obj, aero, prop)
    end
end
```

Returns a struct with at minimum:
- `result.W_S` — optimal wing loading (lb/ft²)
- `result.T_W` — required thrust-to-weight ratio at that wing loading (dimensionless)

`aero` and `prop` are passed so the constraint analysis can use current-iteration drag and thrust models.

### Why This Is the Only Abstract Method

The constraint analysis produces one key output: the design point (W/S, T/W) that simultaneously satisfies all performance constraints. This is what the sizing loop needs to compute wing area and thrust level.

All the intermediate quantities (constraint curves, constraint intersections, feasible design space) are internal to the constraint analysis implementation. They are relevant for plotting design space visualizations but are not needed by the sizing loop.

### Why `optimal_point` Instead of `constraint_diagram`

The sizing loop doesn't need the full constraint diagram — it needs the optimal point on the diagram. A method named `constraint_diagram` would imply returning a data structure representing the whole space. `optimal_point` makes the purpose clear and keeps the interface minimal.

---

## 2. F-16 Constraint Analysis

**File:** `examples/.../disciplines/Constraints/F16ConstraintAnalysis.m`

This is the only concrete implementation. There is no generic `ConstraintLevel1/2/3` class because the constraint equations depend on specific performance requirements (mission segments, maneuver speeds, field lengths), which are aircraft-specific. A generic constraint class would be so parameterized that it provides no reusable physics — it would just be empty storage.

### Performance Constraints

Six flight-performance constraints + takeoff + landing:

| Constraint | Operating condition | Active for F-16? |
|---|---|---|
| Cruise (sustained level flight) | 40,000 ft / M 0.87 | Establishes minimum T/W |
| Dash (max speed) | 40,000 ft / M 1.2 | Active for supersonic dash |
| Combat turn 1 | 25,000 ft / M 0.87 / n=5g | Usually design driver |
| Combat turn 2 | Sea level / M 0.87 / n=7g | Sometimes design driver |
| Acceleration | Ps = 0 at 40,000 ft / M 0.87 | Level-flight sustained |
| Ceiling | 40,000 ft / excess Ps > 100 ft/s | Service ceiling requirement |
| Takeoff | Ground-roll ≤ 1500 ft | BFL constraint |
| Landing | W/S ≤ W/S_land_max | CLmax constraint, upper W/S bound |

### Master Equation

All continuous flight-performance constraints (cruise, dash, turn, acceleration, ceiling) share the same master equation derived from the point-performance equation of motion:

```matlab
function TW = master_eq(beta, alpha, q, V, CD0, K, n, Ps, W0S)
    betaW0S = beta * W0S;
    TW = (beta/alpha) * (q*CD0/betaW0S + K*n^2*betaW0S/q + Ps/V);
end
```

Variables:
- `beta = W_current / W_TO` — weight fraction at operating condition (accounts for fuel burned to reach this point)
- `alpha = T_available / T_SL` — thrust lapse from `prop.thrust_lapse(state)`
- `q` — dynamic pressure at operating condition (from `AircraftState`)
- `V` — velocity (ft/s)
- `CD0, K` — drag polar from `aero.drag_polar(state)` (K = K2 at L1/L2; K = K1 + K2 used together at L3)
- `n` — load factor for the maneuver
- `Ps` — required specific excess power (ft/s) — 0 for sustained maneuver, > 0 for climb/acceleration
- `W0S` — wing loading W_TO/S_ref being swept (psf)

This single equation unifies all steady flight constraints. The differences between cruise, dash, turn, and ceiling come from different values of `beta`, `alpha`, `n`, and `Ps`.

### Takeoff Constraint

```
T/W ≥ (k1 * W/S) / (sigma * CLmax_to) + k2 * CD0_to / CLmax_to
```

where `sigma = rho/rho_SL`, `CLmax_to` includes flap deflection, and `k1`, `k2` are ground-roll constants from Raymer. This establishes the minimum T/W for a given W/S to meet the field-length requirement.

### Landing Constraint (W/S Upper Bound)

Landing sets an upper limit on W/S from the stall speed constraint:

```
V_stall_land ≤ V_stall_max   →   W/S ≤ q_stall_max * CLmax_land
```

This is not a T/W constraint — it's a vertical line on the constraint diagram that excludes high-W/S designs that would stall too fast to land within the required field length.

### Optimal Point Selection

`optimal_point` sweeps `W_S_range = 20:2:180 psf`. At each W/S:
1. Evaluates T/W from each flight constraint using `master_eq`
2. Evaluates T/W from the takeoff constraint
3. Takes the maximum T/W across all constraints (the "upper envelope")
4. Excludes W/S values beyond the landing limit

The optimal W/S is the one that minimizes T/W on the upper envelope (maximum-performance point: you satisfy all constraints with the least thrust relative to weight).

### Why `aero` and `prop` Are Passed

The constraint equations require `CD0`, `K2`, and `thrust_lapse`. Passing `aero` and `prop` objects allows the constraint analysis to use current-iteration drag and thrust values, ensuring that as the sizing loop updates `prop.T0` and the aerodynamics responds to the current `S_ref`, the constraint diagram also updates.

If CD0 and TSFC were fixed parameters passed in the constructor, the constraint diagram would not respond to changes in fidelity or to within-loop updates.

---

## 3. Constraint Diagram and the Design Space

At a given fidelity level, the constraint diagram looks like:

```
T/W
 |        ← max turn    ← dash
 |           /              /
 |          /              /       ceiling
 |         /     _________/________
 |        /     /                  |
 |       / T.O./                   | landing
 |      /     /    FEASIBLE        | bound
 |     /     /      REGION         |
 |    /     /_____________________ |
 +---+-------------------------------- W/S
    optimal →
```

The design point is at the "knee" of the upper envelope — the minimum T/W that satisfies all constraints simultaneously, which also happens to minimize fuel burn (lower T/W means less engine mass, less fuel).

---

## 4. Key Design Decisions

**Why a concrete F16-specific class rather than parameterized generic:** The constraint analysis receives specific mission requirements (cruise altitude, dash Mach, turn g-load, field length). These are all F-16-specific. A generic constraint class would have a constructor with 20+ arguments and would provide no reuse benefit. The abstraction layer is the `ConstraintBase` interface, which other aircraft's constraint classes must implement.

**Why `beta` weight fractions are not iterated:** The weight fraction at each operating condition (`beta`) is an input, estimated from Roskam fuel fractions for the mission legs leading up to that constraint. This avoids a nested loop within the constraint analysis. The error is small (~2–3%) because the fuel burned to reach cruise altitude is a small fraction of W_TO.

**Why K1 is not used in the master equation at L1/L2:** K1 (the linear CL term from camber) is zero at L1/L2 (symmetric drag polar). The K term in `master_eq` is `K2` directly. At L3, K1 is non-zero for cambered airfoils; the constraint equations use `K1*CL + K2*CL²` but since the sweep is in W/S (not CL), the master equation becomes slightly more complex with a linear correction. At L1/L2 this is zero.
