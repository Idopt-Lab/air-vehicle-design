# Decision log — `sizing/`

This file records design decisions and change history for the sizing framework.
Keep source-file headers short. Put the history here, not in the headers.

Each entry: a date, the decision, and the reason. Newest first. Cite the file or
equation when it helps. Do not repeat equation citations that already live in the
code — those stay in the code.

---

## 2026-08-16 — Removed unused code; de-duplicated two helpers

- Deleted the unused non-afterburning engine family from `PropL2` (Raymer
  Eq. 10.4–10.9: `engine_weight_nonAB`, `engine_length_nonAB`,
  `engine_diam_nonAB`, `SFC_max_nonAB`, `thrust_cruise_nonAB`,
  `SFC_cruise_nonAB`), plus `engine_diam_AB` (Eq. 10.12), `thrust_cruise_AB`
  (Eq. 10.14), and `warnIfImplausibleEngineDiameter`. No caller used them.
  Recover from git if a non-afterburning transport needs the non-AB set.
  Reason: dead code depressed coverage and advertised a false public API.
- Kept `engine_weight_AB` (wired through weights DI) and the test-only
  `engine_length_AB` / `SFC_max_AB` / `SFC_cruise_AB`.
- Deleted six unused mid-level wrappers in `AeroL3` (`compute_Cf_lam`,
  `compute_Cf_turb`, `compute_FF_surface`, `compute_FF_fus`, `compute_Cf`,
  `get_R_cutoff`). The drag build-up calls the low-level statics directly.
- De-duplicated the JSON cell/struct normalizer. `ConstraintSetImporter` and
  `MissionProfileReader` now both call `src/core/json_as_struct_array.m`.
- De-duplicated the tail-area formula. `TailL1` and `TailL2` `compute_S_HT` /
  `compute_S_VT` now call `TailSizingBase.tail_volume_area`. Each keeps its own
  citation (Raymer Table 6.4 / Nicolai Eq. 11.1–11.2).
- Kept `GeomL3.compute_frame_cs_area_exact` — it is a tracked design option
  (`todo.md §20`: a one-line swap worth +0.759 % on `Amax`), not dead code.

## Property pattern — inputs vs. derived (Dependent)

Concrete Tier-3 classes split properties into two blocks:
- **Inputs** — plain, mutable spec data an optimizer varies. The constructor
  sets these from JSON.
- **Derived** — `Dependent` getters that recompute from the inputs on every
  read. There is no cached copy, so a derived value cannot go stale when the
  sizing loop mutates an input.
Do not freeze a derived quantity in the constructor. `F16GeomL2.m` is the
reference implementation.

Review findings that led to this pattern (formerly quoted in the weights
headers): a frozen `W_all_else_empty` and a frozen strake term went stale under
mutation. Both are now `Dependent`.

## 2026-07-29 — Strake (LERX) weight term

Added a 90.00 lbf strake term to the F-16 L2/L3 weights
(`k_strake = 4.5 lbf/ft² × S_strake = 20 ft²`, `[Brandt Main!D18 / Wt!H7]`).
It is a `Dependent` group weight (`W_strake`), folded into OEW. This raised the
as-built OEW by exactly 90 lbf at both levels:
- L2 OEW(31377): 15664.648 → 15754.648 lbf
- L3 OEW(31377): 15705.331 → 15795.331 lbf

## Geometry has an L3 tier (reinstated 2026-07-24, promoted 2026-07-25)

`GeomL3` / `GeometryModelL3` / `F16GeomL3` are the full L3 geometry tier,
consumed by L3 geometry, aerodynamics, and weights. L3 is the physical / T.O.
tier: where a physical or T.O. 1F-16A-1 value differs from Brandt's, L3 uses
the physical one. Comparison reports mark those divergences `BY DESIGN`
(VT LE sweep 47.5°, fuselage length 47.5 ft, HT span 18.5 ft as primary).

`Amax` is tier-specific by design: L2 uses the fuselage-envelope ellipse; L3
uses the whole-aircraft area-ruled build-up (what Raymer Eq. 12.44 needs). Do
not unify them — the envelope form at L3 is a fidelity inversion.

## 2026-08-15 — Agnostic geometry / weights cores

`GeometryModelL2` declares only the L2 core every aircraft supplies. The F-16
drag-build-up detail (per-surface t/c, sweeps, inlet duct, wave drag) is
concrete on `F16GeomL2`, not an abstract obligation on every L2 geometry.
`WeightsModelL2` is the agnostic component-build-up enforcer. `B777GeomL2` and
`B777WeightsL2` inherit the slim cores.

## 2026-08-17 — Tail L1 uses injected geometry; L2 is a stub

L1 tail sizing (F16TailL1 / B777TailL1 / Aero481TailL1) now takes an injected
geometry object at construction and reads S_ref / b_wing / cbar_wing / L_fus
from it live in size(obj) -- the same DI style the sizing loops use.
SizingLoopL2 and TSDiagram now call tail.size() (no scalar arguments). The
TailL1 equation toolbox stays scalar (unchanged); only the concrete classes
read the injected geometry.

The injected geometry is typed GeometryBase (not GeometryModelL2): Aero481
injects an L1 geometry (Aero481GeomL1, which provides b_wing/cbar_wing/L_fus as
Dependents) and f16_brandt_stack injects a BrandtMissionGeomAdapter.

L2 tail sizing is now a not-implemented stub: TailL2.size and F16TailL2.size
throw 'TailL2:notImplemented'. The former Nicolai & Carichner L2 coefficient
path was removed; L2 is reserved for a future higher-fidelity method with real,
cited equations. Recover the old L2 equations from git if needed.

## 2026-08-16 — Tail sizing has no L3 tier

Removed the never-implemented Level-3 tail-sizing stub (`TailL3`,
`TailSizingModelL3`, `F16TailL3`, `TestTailL3`). `size()` only threw
`TailL3:citationNotAvailable`; no aircraft constructed it; and the Raymer
Ch. 16 stability-and-control sizing equations it needed are not in the repo.
Tail sizing now has L1 and L2 only, like propulsion. If S&C-based tail sizing
is built later, add the tier back with real, cited equations.

## Propulsion has no L3 tier

There is no `PropL3` / `PropulsionModelL3` / `F16PropL3`, and none is planned.
The L3 rung pairs `F16AeroL3` with `F16PropL2`. Report L3 propulsion numbers as
"computed by `F16PropL2`".
