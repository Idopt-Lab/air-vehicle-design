# GeometryBase

Tier-1 abstract enforcer (`classdef (Abstract) GeometryBase < handle`) for every geometry discipline
class. It declares the minimum contract orchestrators rely on, and provides the fidelity-independent
identities every level shares. No per-aircraft data, no per-fidelity equations.

---

## 1. Inheritance

```
GeometryBase → GeometryModelLN (abstract) → F16GeomLN (concrete)
```

Each `GeometryModelLN` enforcer inherits `GeometryBase` **directly**, not `GeometryModelL(N-1)`.

The `GeomL1` / `GeomL2` / `GeomL3` static toolboxes hold the per-fidelity equations and are **not**
in this chain — concrete classes call them as `GeomLN.method(...)`.

**Geometry has all three tiers, L1 / L2 / L3.** L1 is statistical (regressions on `W_TO`), L2 is the
Brandt-reference tier, L3 is the physical / T.O. 1F-16A-1 tier.

## 2. Abstract contract

Properties every concrete class must define:

| Property | Meaning |
|---|---|
| `S_ref` | wing reference area, ft² |
| `S_wet` | total aircraft wetted area, ft² |

Methods every concrete class must implement:

| Method | Notes |
|---|---|
| `get_S_ref(obj)` | wing reference area, ft² |
| `get_S_wet(obj, W_TO)` | total wetted area, ft². The `(obj, W_TO)` signature is the widest any implementer needs — L1's statistical regression needs TOGW, while L2/L3 have real planform geometry and implement `get_S_wet(obj)` with no second argument. MATLAB does not enforce matching arity between an abstract declaration and its concrete override, so this is legal |

This contract is deliberately **narrow**, and that has a consequence worth knowing: a bare
`GeometryBase` type guard is too weak for anything that reads real geometry. `F16AeroL2`/`L3` read
~20 members off the injected object, so their guards were narrowed to
`mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`.

## 3. Concrete utilities

Fidelity-independent identities, shared unchanged across all levels. Each takes only scalars and
returns a scalar.

| Method | Formula | Source |
|---|---|---|
| `compute_root_chord(S_ref, b, lambda)` | `2·S_ref/(b(1+λ))` | Raymer 7th ed. Eq. 7.6 |
| `compute_tip_chord(c_root, lambda)` | `λ·c_root` | Raymer 7th ed. Eq. 7.7 |
| `compute_mac(c_root, lambda)` | `(2/3)·c_root·(1+λ+λ²)/(1+λ)` | Raymer 7th ed. Eq. 7.8 |
| `compute_span(AR, S_ref)` | `sqrt(AR·S_ref)` | definitional (`AR = b²/S_ref`) |
| `convert_sweep(Lambda_LE_deg, AR, lambda, x)` | **MIRRORED** surfaces: `tan Λ_x = tan Λ_LE − (4/AR)·x(1−λ)/(1+λ)`; `x = 0.25` gives quarter-chord, `x = 1.0` trailing edge | standard planform identity (§4) |
| `convert_sweep_panel(Lambda_LE_deg, AR, lambda, x)` | **SINGLE-PANEL** surfaces: same identity with `2/AR` | as above (§4) |
| `compute_Amax_elliptical(W_max, H_max)` | `(π/4)·W_max·H_max` — the max cross-section of the equivalent elliptical fuselage the model already assumes when it feeds `D_fus = (W+H)/2` into Roskam Eq. 12.3 | standard elliptical identity (§5) |
| `compute_nacelle_diameter(T_AB_SLS_lb)` | `sqrt(T_AB_SLS/1900)`; F-16A → 3.537 ft | [Brandt `Engn(s)` tab `D_engine`; `readme_geom.md` §3] |

Argument validators guard the denominators: `lambda` is `mustBeNonnegative` (protects `1+λ`), areas /
spans / chords are `mustBePositive`, and `x` is constrained to `[0,1]`.

The last two live here rather than in a per-fidelity toolbox because both `F16GeomL2` and `F16GeomL3`
call them. They were briefly authored into `GeomL3`, which made the L2 concrete class depend on the
L3 toolbox — a layering inversion, moved here to remove it.

## 4. Conventions — sweep-angle conversion, mirrored vs. single-panel

`GeometryBase.m`'s `convert_sweep` / `convert_sweep_panel` citation notes point readers here.

The coefficient follows from what root→tip spans:

- **Mirrored** (`convert_sweep`) — root→tip spans the **semi**span `b/2`, and `AR = b²/S` is defined
  on the full mirrored planform. `tan Λ_x = tan Λ_LE − x(c_root − c_tip)/(b/2)`, which with
  `c_root = 2S/(b(1+λ))` gives the **4/AR** form. Use for the wing and a conventional horizontal tail.
- **Single panel** (`convert_sweep_panel`) — a vertical tail is one panel: root→tip spans the **full**
  `b`, and `AR = b²/S` is defined on that single panel. The same derivation over `b` instead of `b/2`
  gives **2/AR**, exactly half.

Passing a single-panel AR to `convert_sweep` double-counts the taper term. That was a live defect
until 2026-07-25: the F-16's VT trailing-edge sweep read a physically impossible **0.33°** where the
correct value is **22.90°** (quarter-chord 32.24° → **36.31°**). Verified against the repo's own VT
chords (`readme_geom.md` §4.3: `S_vt` = 60, `AR_vt` = 1.6, `λ_vt` = 0.5 → `b_vt` = 9.798,
`c_root` = 8.165, `c_tip` = 4.082).

## 5. To-dos

| Item | Status |
|---|---|
| `convert_sweep` and `convert_sweep_panel` are cited as a standard planform-geometry identity, not to a specific textbook equation — no Raymer/Roskam edition and equation could be pinned to either against the references in this repo | accepted by decision (2026-07-21) |
| `compute_Amax_elliptical` likewise has **no** known Raymer/Roskam/Mattingly/Brandt equation number and appears in no reference extract here. Documented as a standard identity following the `convert_sweep` precedent; no equation number was invented | todo §4 — pin a citation or accept the status in writing |
| `compute_nacelle_diameter` hardcodes **1900**, which silently assumes an afterburning engine — Brandt uses `Engn(s)!L22` = 1900 only when `T_dry ≠ T_AB`, and `L10` = 2000 otherwise | todo §18 |

Brandt's `Geom!B20` = 25.110556 ft² is **not** a comparison target for `compute_Amax_elliptical`: it
is a whole-aircraft area-ruled `MAX` net of an engine flow-through deduction, a different quantity
(F-16A envelope 27.4889, +9.47 %). L3 computes the area-ruled figure instead — see `F16GeomL3.md` §4.
