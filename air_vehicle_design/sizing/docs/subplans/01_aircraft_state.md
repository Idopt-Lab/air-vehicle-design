# Subplan 01 — AircraftState

**Status:** Implemented (`src/core/AircraftState.m`)
**Depends on:** Nothing
**Blocks:** All subsequent steps

---

## Objectives

Implement `AircraftState`, the common flight-condition input passed to every discipline method. Computes standard atmosphere properties once at construction and stores them so disciplines can read `state.rho`, `state.q`, etc. without re-querying the atmosphere.

---

## Files to Create

| File | Purpose |
|------|---------|
| `src/core/AircraftState.m` | Core class |
| `tests/core/TestAircraftState.m` | Unit tests |

---

## Design Notes

- **Value class (not handle)** — immutable. All fields are `SetAccess = private` and set once in the constructor; there is no set-method, so reassigning after construction (e.g. `s.mach = ...`) errors.
- Constructor: `AircraftState(altitude_ft, mach)`
- Calls MATLAB `atmosisa` internally; converts all outputs to **English units** (°R, lbf/ft², slug/ft³, ft/s)
- Also carries the dimensionless ratios `theta`/`delta`/`theta_0`/`delta_0` (Mattingly Eq. 2.52) used by constraint/mission equations
- No `Dependent` properties and nothing is cached-then-mutated — every field is a plain private property computed once at construction, so no value can go stale
- Inspired by NPTEL `AircraftState` (Python) but in English units and immutable-value semantics

---

## Equations & References

| Property | Equation | Reference |
|----------|----------|-----------|
| T_atm (°R) | from `atmosisa` output × 1.8 | MATLAB atmosisa documentation |
| P_atm (lbf/ft²) | from `atmosisa` × 0.020885 | unit conversion |
| rho (slug/ft³) | from `atmosisa` × 0.00194032 | unit conversion |
| a (ft/s) | from `atmosisa` × 3.28084 | unit conversion |
| V (ft/s) | V = mach × a | definition |
| q (lbf/ft²) | q = 0.5 × rho × V² | definition |
| alpha (rad) | atan2(w, u) | definition |
| beta (rad) | asin(v / V) | definition |

---

## Tests to Write (`tests/core/TestAircraftState.m`)

| Test | Condition | Expected | Tolerance |
|------|-----------|----------|-----------|
| Sea-level, M=0 | alt=0, M=0 | rho=0.002377 slug/ft³, T=518.67°R | ±0.1% |
| Tropopause, M=1 | alt=36,089 ft, M=1 | q matches 1/2 rho a² | ±0.1% |
| F-16 cruise | alt=2,500 ft, M=0.85 | q finite and positive | — |
| Defaults | alt=10k, M=0.5 | alpha=0, beta=0, phi=0 | exact |
| Immutability | attempt to reassign `mach` after construction | assignment errors (private, read-only) | exact |

---

## Verification

```matlab
runtests('tests/core/TestAircraftState.m')
```
All tests must pass before Step 2 begins.
