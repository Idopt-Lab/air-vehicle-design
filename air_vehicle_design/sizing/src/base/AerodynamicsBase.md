# AerodynamicsBase

Tier-1 abstract enforcer (`classdef (Abstract) AerodynamicsBase < handle`) for every aerodynamics
discipline class. It declares only the two methods orchestrators actually call, and provides two
fidelity-independent utilities every level inherits unchanged. No equations, no coefficients.

---

## 1. Inheritance

```
AerodynamicsBase → AeroModelLN (abstract) → F16AeroLN (concrete)
```

Each `AeroModelLN` enforcer inherits `AerodynamicsBase` **directly**, not `AeroModelL(N-1)`.

The `AeroL1` / `AeroL2` / `AeroL3` static toolboxes hold the equations and are **not** in this chain
— concrete classes call them as `AeroLN.method(...)`.

## 2. Abstract contract

| Method | Returns | Called by |
|---|---|---|
| `drag_polar(obj, state)` | `struct(CD0, K1, K2)` | `ConstraintAnalysis`, and the future mission / sizing loops |
| `get_CLmax(obj, state)` | scalar | as above |

No abstract **properties**. The former computed-quantity block (`e_osw_clean`, `CD0`, `CDi`, `CL`,
`CD`, `CL_minD`, `CL_max_clean`, `Cf`, `K1`, `K2`) was removed: those are derived outputs, not stored
inputs, and forcing every concrete class to carry them as frozen `= 0` plain properties was
stale-by-construction — a frozen `K1 = 0` never reflected a mutated `AR`. Derived quantities now live
either in the struct `drag_polar` returns or in a concrete class's own `Dependent` getters.

## 3. Concrete utilities

Inherited unchanged by every fidelity level.

| Method | Formula | Source |
|---|---|---|
| `compute_CD(~, CD0, K1, K2, CL)` | `CD = CD0 + K1·CL² + K2·CL` | Mattingly, *Aircraft Engine Design*, 2nd ed., Eq. 2.9 (Brandt `Aero!G17` form) |
| `compute_CL(~, L, q, S_ref)` | `CL = L/(q·S_ref)` | definitional (Nicolai Eq. 2.1); steady level flight |

`compute_CL` guards `q` and `S_ref` as `mustBePositive` — they are division denominators.

## 4. Conventions

**K-convention (Convention A), settled:**

```
CD = CD0 + K1·CL² + K2·CL
```

`K1` is the quadratic / induced factor, `K2` the linear / camber-offset term. This matches Mattingly
Eq. 2.9, Brandt `Aero!G17`, the constraint classes and every `AeroLN` toolbox. The K1/K2-swapped
"Convention B" that appears in the stale `temp_AI/docs` is **not** followed here.

Author-specific K decompositions (Mattingly `K'`/`K''`, Brandt's single `e0`, Raymer's single `K`)
stay inside the level toolboxes. The base sees only the assembled `{CD0, K1, K2}`.

## 5. To-dos

None. This file is a contract, not a model.
