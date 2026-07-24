# GeometryBase

Tier-1 abstract enforcer (`classdef (Abstract) GeometryBase < handle`) for every geometry
discipline class. Inheritance chain per fidelity level:

    GeometryBase -> GeometryModelLN (abstract) -> F16GeomLN (concrete)

The `GeomLN` static toolboxes hold the equations and are called by the concrete classes; they
are not part of this chain. Geometry has only L1 and L2 tiers (no L3).

## Abstract contract

Properties every concrete class must define:

| Property | Meaning |
|----------|---------|
| `S_ref`  | Wing reference area, ft^2 |
| `S_wet`  | Total aircraft wetted area, ft^2 |

Methods every concrete class must implement:

| Method | Notes |
|--------|-------|
| `get_S_ref(obj)`       | Wing reference area, ft^2 |
| `get_S_wet(obj, W_TO)` | Total wetted area, ft^2. The `(obj, W_TO)` signature is the widest any implementer needs: L1's statistical regression needs `W_TO` (TOGW), while L2 has real planform geometry and implements `get_S_wet(obj)` with no second argument. MATLAB does not enforce matching arity between an abstract declaration and its concrete override, so this is legal. |

## Concrete static utilities

Fidelity-independent planform identities, shared unchanged across all levels. Each takes only
scalars and returns a scalar.

| Method | Formula | Source |
|--------|---------|--------|
| `compute_root_chord(S_ref, b, lambda)` | `2*S_ref / (b*(1+lambda))` | Raymer 7th ed., Eq. 7.6 |
| `compute_tip_chord(c_root, lambda)`    | `lambda*c_root` | Raymer 7th ed., Eq. 7.7 |
| `compute_mac(c_root, lambda)`          | `(2/3)*c_root*(1+lambda+lambda^2)/(1+lambda)` | Raymer 7th ed., Eq. 7.8 |
| `compute_span(AR, S_ref)`              | `sqrt(AR*S_ref)` | Definitional (AR = b^2/S_ref) |
| `convert_sweep(Lambda_LE_deg, AR, lambda, x)` | `tan(Lambda_x) = tan(Lambda_LE) - (4/AR)*x*(1-lambda)/(1+lambda)`; `x=0.25` gives quarter-chord, `x=1.0` trailing-edge | Standard swept-wing planform identity |

`convert_sweep` is cited as a standard swept-wing identity rather than a specific textbook
equation number: no Raymer/Roskam edition and equation could be pinned to it against the
references available in this repo.

Argument validators guard the denominators: `lambda` is `mustBeNonnegative` (protects
`1+lambda`), areas/spans/chords are `mustBePositive`, and `x` is constrained to `[0,1]`.
