# F16AeroL3

Tier-3 concrete class (`classdef F16AeroL3 < AeroModelL3`) for the F-16A: Raymer component drag
build-up plus the F-16's supersonic wave-drag term. Most methods delegate to the `AeroL3` toolbox;
`get_CD0_buildup`/`drag_polar` add the wave-drag term on top, and the class carries a full HLD
suite (TE flaperon + LE slat + landing gear). Component order everywhere: **wing, HT, VT, fuselage,
duct**.

## Construction (dependency injection)

`F16AeroL3(geom, json_path)` — **both arguments are required** (no silent defaults). The canonical
pairing is now
`F16AeroL3(F16GeomL3(f16a_spec_path(3), prop), f16a_spec_path(3))`, with
`prop = F16PropL2(f16a_spec_path(2))`: geometry has a full L3 tier again (reinstated 2026-07-24,
promoted 2026-07-25 — the earlier "Geometry has no L3 tier" note is obsolete), and geometry itself
takes an injected propulsion object because the nacelle diameter is sized from engine thrust. Aero
constants still come from the `.aerodynamics` block of `f16a_L3.json`.

The `geom` argument is guarded by `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`, not by the
old `GeometryBase` — that base declares only four members while this class reads ~20, so a wrong tier
used to construct cleanly and then fail mid-run, or worse resolve members whose *meaning* differed.
Both tiers satisfy the contract, but they are **not interchangeable here**: `Amax` is tier-specific by
design (L3 area-ruled, L2 fuselage-envelope), so injecting an `F16GeomL2` silently substitutes a
fuselage-only cross-section into the Raymer Eq. 12.44 wave-drag term and inflates `CD0_wave` ~23%.

## Properties — inputs vs. derived

**Inputs** (from JSON `.aerodynamics`): `geom`; airfoil `alpha_L0`, `cl_max_2D`; per-component
`x_c_max_comp`, `Q_comp`, `f_lam_comp`, `is_body_comp`; surface roughness `k`; wave-drag factor
`E_WD` and the whole-aircraft wave-drag geometry `Amax_ft2` / `L_aircraft_ft`; `CD0_LandP`; misc
drag areas `Dq_gun_port`, `Dq_hook_USAF`. Additional `Constant` flaperon / LE-slat / landing-gear
control-surface estimates are declared inline.

**Derived** (`properties (Dependent)`, read live from `obj.geom` — no stored copy):

| Derived | Source |
|---|---|
| `S_ref`, `AR`, `Lambda_LE_deg`, `Lambda_c4_deg`, `taper` | scalar geometry from `geom` (`Lambda_c4_deg` = `geom.QC_sweep_wing`) |
| `S_wet_comp` | per-component wetted area from `geom` (wing/HT/VT + fuselage + duct) |
| `l_ref_comp` | per-component MAC / length (`geom.cbar_wing`, HT/VT MAC via `GeometryBase.compute_mac`, `L_fus`, `L_duct`) |
| `D_comp` | body diameters (`0` for surfaces; `geom.D_fus`, `geom.D_inlet`) |
| `tc_comp` | per-component thickness ratio (mean root/tip for HT/VT; `0` for bodies) |
| `Lambda_m_comp` | max-thickness-line sweep at `x_c_max` — `GeometryBase.convert_sweep` (4/AR) for the mirrored wing and HT, `convert_sweep_panel` (2/AR) for the single-panel VT |
| `CD0_misc` | `(Dq_gun_port + Dq_hook_USAF)/S_ref` (Raymer Table 12.7) |

## Methods

- **Contract:** `drag_polar` (`AeroL3.drag_polar`), `get_CLmax` (Raymer Eq. 12.15, via
  `AeroL2.CLmax_clean`).
- **Build-up + wave drag:** `get_CD0_buildup` overrides the generic Eq. 12.24 sum to add
  `compute_CD0_wave` for `M ≥ 1.2` (Raymer Eqs. 12.44/12.45, Sears-Haack).
- **Deltas:** TE-flap (`Delta_CD0_flap`, `Delta_CDi_flap`, `Delta_CLmax_flap`), LE-slat
  (`Delta_CD0_slat`, `Delta_CDi_slat`, `Delta_CLmax_slat`; Eq. 12.61/62 *form*, no separate LE
  citation in Raymer), landing gear (`compute_Delta_CD0_geardown`, Raymer Table 12.6), assembled by
  `get_Delta_*_{TO,L}` / `get_CLmax_{TO,L}`. Plus `get_CL_alpha`, `compute_Re`.

## Current limitation

The Sears-Haack wave drag needs a whole-aircraft max cross-sectional area, which the geometry object
does not expose (Brandt's value is area-ruled, net of engine flow-through). So `Amax_ft2`
(25.110556 ft²) and `L_aircraft_ft` (48.304 ft) are carried as L3 aero inputs [Brandt Geom!B20/H47,
B21] rather than read live from `obj.geom` — a documented departure from the otherwise-pure
dependency injection, to be replaced if a geometry `Amax` getter is added.
