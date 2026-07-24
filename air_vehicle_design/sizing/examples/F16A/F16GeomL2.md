# F16GeomL2

F-16A Block 10 Level-2 geometry concrete class (`classdef F16GeomL2 < GeometryModelL2`). Every
abstract method is a single delegation line into the `GeomL2` / `GeometryBase` statics; no
equations are duplicated here. This is the reference implementation of the INPUT vs DERIVED
optimization-ready property pattern that every future Tier-3 class follows.

## Constructor
`F16GeomL2(json_path)` requires a spec-file path (`f16a_spec_path(2)`) and reads the `.geometry`
block of `examples/F16A/f16a_L2.json`; the same file's `.aerodynamics` block feeds `F16AeroL2`.
There is no silent default — a no-argument call errors (`MATLAB:minrhs`). The constructor sets
**only** the input properties (wing, HT, VT, fuselage, engine/duct); every derived quantity is
produced live by its Dependent getter.

## INPUT vs DERIVED pattern
- **Inputs** — a plain, mutable `properties` block holding the genuine design-variable spec data
  (reference areas, aspect ratios, taper, LE sweep, t/c, fuselage envelope, duct length, engine
  thrust). An optimizer may mutate these between/within iterations.
- **Derived** — a `properties (Dependent)` block whose `get.<name>` methods recompute live from
  the inputs on every read via `GeometryBase`/`GeomL2` statics. There is no stored or cached
  copy, so a derived value can never go stale: the instant an input changes, every dependent
  read reflects it. Derived properties are read-only (no set-methods). Recompute-on-read is used
  rather than a set-invalidated cache because the formulas are cheap closed-form algebra.

## Inputs (set from JSON)
- Wing: `S_ref`, `AR_wing`, `lambda_wing`, `LE_sweep_wing`, `tc_wing`.
- HT: `S_ht`, `AR_ht`, `lambda_ht`, `LE_sweep_ht`, `tc_ht`, `tc_r_ht`, `tc_t_ht` (root/tip t/c
  from T.O. Sec I; Brandt uses one uniform t/c per surface).
- VT: `S_vt`, `AR_vt`, `lambda_vt`, `LE_sweep_vt`, `tc_vt`, `tc_r_vt`, `tc_t_vt` (T.O. Sec I).
- Fuselage: `L_fus`, `W_max_fuselage`, `H_max_fuselage`.
- Engine/duct: `L_duct`, `T_AB_SLS_lb` (AB thrust, used only to size the nacelle diameter).
- Constants (unused): `mainwheel_S_front`, `nosewheel_S_front`.

Most inputs cite Brandt Main-tab cells; the root/tip t/c splits cite T.O. Sec I.

## Derived (recomputed on read)
- Wing: `b_wing`, `c_root_wing`, `c_tip_wing`, `cbar_wing`, `QC_sweep_wing` (~32.2 deg),
  `TE_sweep_wing`, `tc_r_wing`/`tc_t_wing` (mirror `tc_wing`), `S_exposed_wing`, `S_wet_wing`.
- HT: `b_ht`, `c_root_ht`, `c_tip_ht`, `QC_sweep_ht`, `TE_sweep_ht`, `S_exposed_ht`, `S_wet_ht`.
- VT: `b_vt` (full single-panel span), `c_root_vt`, `c_tip_vt`, `QC_sweep_vt`, `TE_sweep_vt`,
  `S_exposed_vt`, `S_wet_vt`.
- Fuselage: `L_fuselage` (mirrors `L_fus`, name required by the abstract contract),
  `D_fus = (W_max_fuselage + H_max_fuselage)/2`.
- Duct: `D_inlet = sqrt(T_AB_SLS_lb / 1900)` (Brandt nacelle sizing), `D_exit = D_inlet`
  (constant-diameter cylinder nacelle).
- Total: `S_wet`.

Chords use Raymer 7th ed. Eq. 7.6/7.7/7.8 via `GeometryBase`; sweep-station values use
`GeometryBase.convert_sweep`. `QC_sweep_wing` is computed (~32.2 deg), not a hardcoded literal.
`D_fus` uses Brandt's low-fi equivalent-diameter convention because the JSON gives only
width/height, feeding the Roskam Eq. 12.3 fuselage formula.

## Methods (delegate to GeomL2)
`get_S_ref`, `get_S_wet`, `get_S_wet_wing`, `get_S_wet_HT`, `get_S_wet_VT`,
`get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing`.

`get_S_wet` takes no `W_TO` argument. Total wetted area = wing + HT + VT + fuselage + duct, using
Roskam Eq. 12.1 (surfaces) + Roskam Eq. 12.3 (fuselage) + Raymer Sec. 7.3 (duct); see `GeomL2.m`
for citations.
