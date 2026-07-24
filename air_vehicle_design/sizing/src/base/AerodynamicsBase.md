# AerodynamicsBase

Tier-1 abstract base (`handle`) for every aerodynamics discipline class.

Inheritance per fidelity level: `AerodynamicsBase → AeroModelLN (abstract) → F16AeroLN (concrete)`.
The `AeroL1`/`AeroL2`/`AeroL3` static toolboxes hold the equations and are **not** in this
chain — concrete classes call them as `AeroLN.method(...)`.

## Contract enforced

Two abstract methods, the only ones the orchestrators (constraint / mission / sizing) call:

| Method | Returns |
|---|---|
| `drag_polar(state)` | `struct(CD0, K1, K2)` |
| `get_CLmax(state)`  | scalar |

## Concrete utilities (inherited unchanged by every level)

| Method | Formula | Source |
|---|---|---|
| `compute_CD(CD0,K1,K2,CL)` | `CD = CD0 + K1·CL² + K2·CL` | Mattingly, *Aircraft Engine Design* 2nd ed., Eq. 2.9 |
| `compute_CL(L,q,S_ref)`    | `CL = L/(q·S_ref)` (q, S_ref guarded positive) | definitional (Nicolai Eq. 2.1) |

## K-convention (Convention A)

`CD = CD0 + K1·CL² + K2·CL` — `K1` quadratic/induced, `K2` linear/camber. Matches Mattingly Eq. 2.9,
Brandt Aero!G17, the constraint code, and every `AeroLN` toolbox.

The base stores no computed quantities: every derived output lives in the `drag_polar` struct or in
a concrete class's `Dependent` getters, so nothing goes stale when a design variable changes.
