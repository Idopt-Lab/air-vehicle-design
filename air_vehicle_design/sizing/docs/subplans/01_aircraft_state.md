# Subplan 01 — AircraftState

**Status:** Placeholder — not started
**Depends on:** Step 0 (baseline JSON)
**Blocks:** All subsequent steps

---

## Objectives

Implement `AircraftState`, the common flight-condition input passed to every discipline method. Must compute and cache standard atmosphere properties at construction so disciplines can call `state.rho`, `state.q`, etc. without re-querying the atmosphere.

---

## Files to Create

| File | Purpose |
|------|---------|
| `src/core/AircraftState.m` | Core class |
| `tests/core/TestAircraftState.m` | Unit tests |

---

## Design Notes

- Handle class (reference semantics — same object passed to aero, prop, etc.)
- Constructor: `AircraftState(altitude_ft, mach)`
- Calls MATLAB `atmosisa` internally; converts all outputs to **English units** (°R, lbf/ft², slug/ft³, ft/s)
- Body velocities (u, v, w) and angles (alpha, beta, phi, theta) default to trimmed straight-and-level flight; L1/L2 disciplines only read `altitude`, `mach`, `q`, `rho`, `V`
- Inspired by NPTEL `AircraftState` (Python) but: English units, MATLAB `Dependent` properties where recomputation is needed, atmosphere cached at construction (not recomputed on every property access)

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
| Immutability of atmosphere | change mach after construction | q does NOT update (cached) | exact |

---

## Verification

```matlab
runtests('tests/core/TestAircraftState.m')
```
All tests must pass before Step 2 begins.
