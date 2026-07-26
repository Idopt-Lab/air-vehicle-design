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
| `convert_sweep(Lambda_LE_deg, AR, lambda, x)` | **MIRRORED** surfaces (wing, conventional HT): `tan(Lambda_x) = tan(Lambda_LE) - (4/AR)*x*(1-lambda)/(1+lambda)`; `x=0.25` gives quarter-chord, `x=1.0` trailing-edge | Standard swept-wing planform identity |
| `convert_sweep_panel(Lambda_LE_deg, AR, lambda, x)` | **SINGLE-PANEL** surfaces (vertical tail): same identity with `2/AR` — exactly half the mirrored coefficient | Same identity, specialized to one panel |

### Sweep-angle conversion — mirrored vs. single-panel

`GeometryBase.m`'s `convert_sweep` / `convert_sweep_panel` citation notes point readers here.

The coefficient follows from what root→tip spans:

- **Mirrored** (`convert_sweep`): root→tip spans the **semi**span `b/2`, and `AR = b²/S` is defined
  on the full mirrored planform. `tan(Λ_x) = tan(Λ_LE) − x·(c_root − c_tip)/(b/2)`, which with
  `c_root = 2S/(b(1+λ))` gives the **4/AR** form.
- **Single panel** (`convert_sweep_panel`): a vertical tail is one panel — root→tip spans the
  **full** `b`, and `AR = b²/S` is defined on that single panel. The same derivation over `b`
  instead of `b/2` gives **2/AR**.

Passing a single-panel AR to `convert_sweep` double-counts the taper term. That was a live defect
until 2026-07-25: the F-16's VT trailing-edge sweep read a physically impossible **0.33°** where
the correct value is **22.90°** (quarter-chord 32.24° → **36.31°**). Verified against the repo's own
VT chords (`readme_geom.md` §4.3: `S_vt = 60`, `AR_vt = 1.6`, `λ_vt = 0.5` → `b_vt = 9.798`,
`c_root = 8.165`, `c_tip = 4.082`).

Both are cited as a standard planform-geometry identity rather than a specific textbook equation
number: no Raymer/Roskam edition and equation could be pinned to either against the references
available in this repo.

Argument validators guard the denominators: `lambda` is `mustBeNonnegative` (protects
`1+lambda`), areas/spans/chords are `mustBePositive`, and `x` is constrained to `[0,1]`.
