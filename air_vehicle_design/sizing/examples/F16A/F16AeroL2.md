# F16AeroL2

Tier-3 concrete class (`classdef F16AeroL2 < AeroModelL2`) for the F-16A: geometry-dependent clean
drag polar + finite-wing lift. Every contract method delegates to the `AeroL2` toolbox; the class
adds the F-16 flaperon (TE-flap) high-lift/gear delta methods.

## Construction (dependency injection)

`F16AeroL2(geom, json_path)` — **both arguments are required** (no silent defaults; a no-arg call
errors). Typically:

```matlab
prop = F16PropL2(f16a_spec_path(2));
a2   = F16AeroL2(F16GeomL2(f16a_spec_path(2), prop), f16a_spec_path(2));
```

`json_path` supplies the `.aerodynamics` block of `f16a_L2.json`. `geom` is guarded by
`mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])` — **not** the bare `GeometryBase` it used to
accept. `GeometryBase` declares only `S_ref`/`S_wet`/`get_S_ref`/`get_S_wet`, so a wrong-tier object
(e.g. an `F16GeomL1`) used to construct fine and then die mid-run inside a Dependent getter, or
worse resolve with changed meaning. The narrowed guard fails at **construction** instead.

Caveat worth knowing: this guard cannot catch an L2-vs-L3 mix-up, because both tiers satisfy the
contract by design — passing `g2` where `g3` was meant yields plausible numbers, not an error. Only
reading the call site catches that (see `VnV/BrandtF16A/todo.md` §P4-22).

## Properties — inputs vs. derived

**Inputs** (plain, mutable; set once from the JSON `.aerodynamics` block):
`geom` (the injected geometry object), `Cfe`, `e_method`, airfoil data (`airfoil_name`,
`airfoiltype`, `design_CL`, `alpha_L0`, `cl_max_2D`, `cl_alpha_2D`), and the flaperon
control-surface estimates (`hld_TE`, `c_flap_over_c`, `eta_flap_in/out`, `delta_flap_TO/L_deg`,
`k_f_flap` — genuine control-surface spec, flagged TODO vs T.O. 1F-16A-1).

**Derived** (`properties (Dependent)`, read live from `obj.geom` on every read — no stored copy, so
they never go stale when the geometry is mutated):

| Derived | Source |
|---|---|
| `S_ref`, `S_wet`, `AR`, `Lambda_LE_deg`, `taper` | `geom.S_ref` / `S_wet` / `AR_wing` / `LE_sweep_wing` / `lambda_wing` |
| `Lambda_c4_deg` | `geom.QC_sweep_wing` (quarter-chord sweep conversion, ≈32.2°) |
| `L_char` | `geom.L_fus` (characteristic length for the supersonic Reynolds number) |

## Methods

- **Contract:** `drag_polar`, `get_CLmax` (Raymer Eq. 12.15).
- **Accessors:** `get_e_osw` (official, Raymer Eq. 12.48/12.49), `get_e_osw_brandt` (Brandt Aero!G12
  alternate — comparison report only), `get_K1`, `get_K2`, `get_CD0`, `get_CL_alpha`.
- **Flaperon high-lift/gear deltas:** `compute_S_flapped_ratio` (Roskam Part II Eq. 7.10),
  `Delta_CD0_flap` (Raymer Eq. 12.61), `Delta_CDi_flap` (Eq. 12.62), `Delta_CLmax_flap`
  (Table 12.2 + Eq. 12.21), and the assembled `get_Delta_{e_osw,CD0,CLmax,CDi}_{TO,L}` /
  `get_CLmax_{TO,L}`. Gear increments come from the Roskam Table 3.6 tabulation via private
  `roskam_*` helpers; wing geometry (taper, sweep, S_ref) is read live via the Dependent getters.
