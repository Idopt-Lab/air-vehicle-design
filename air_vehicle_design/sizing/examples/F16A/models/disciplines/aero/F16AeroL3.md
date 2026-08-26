# F16AeroL3

F-16A Block 10/15 Level-3 aerodynamics: the Raymer Eq. 12.24 component drag build-up plus the F-16's
own supersonic wave-drag term. `classdef F16AeroL3 < AeroModelL3`; most methods delegate to the
`AeroL3` static toolbox, while `get_CD0_component_buildup`/`drag_polar` add wave drag on top. The
class also carries a full high-lift suite (TE flaperon + LE flap + landing gear).

**Component order everywhere: wing, HT, VT, strake, fuselage, duct.**

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));   % no L3 propulsion tier exists
a3   = F16AeroL3(F16GeomL3(f16a_spec_path(3), prop), f16a_spec_path(3));
```

`F16AeroL3(geom, json_path)` — both arguments required, no silent default. `json_path` supplies the
`.aerodynamics` block of `f16a_L3.json`.

`geom` is guarded by `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`. `GeometryBase` would
be too loose: it declares four members while this class reads about 20 off `obj.geom`. Both tiers
satisfy the guard, but they are **not interchangeable here**:
`Amax` is tier-specific by design, so injecting an `F16GeomL2` substitutes a fuselage-only
cross-section into Eq. 12.44 and inflates `CD0_wave` ~23 % with no error.

---

## 2. Inputs

Plain mutable `properties` — aero constants only, from the JSON. **No geometry is stored.**

| Property | Value | Meaning / citation |
|---|---|---|
| `geom` | `F16GeomL3` | injected geometry object |
| `alpha_L0` | deg | zero-lift AOA → `CL_minD` → `K2` [NACA 64A204] |
| `cl_max_2D` | 1.20 | feeds Eq. 12.15; matches L2 |
| `cl_alpha_2D` | 1/rad | 2-D lift slope → the Eq. 12.8 `η` term. `AeroL2.CL_alpha` falls back to `η = 0.95` without it |
| `x_c_max_comp` | `[0.4 0.35 0.35 0 0]` | chordwise max-thickness station (0 for bodies) [Raymer Table 12.6] |
| `Q_comp` | `[1 1.05 1.05 1 1]` | interference factor [Raymer Table 12.6] |
| `f_lam_comp` | per component | laminar-flow fraction |
| `is_body_comp` | logical | selects the body form factor (Eq. 12.31) |
| `k` | ft | equivalent surface roughness, smooth paint [Raymer Table 12.4/12.5] |
| `E_WD` | 2.2 | wave-drag efficiency factor — a **tuned calibration input** [Raymer Eq. 12.45] |
| `CD0_LandP` | 0.0010 | leakage & protuberance allowance [Raymer §12.5] |
| `Dq_gun_port` / `Dq_hook_USAF` | 0.20 / 0.10 ft² | misc drag areas [Raymer Table 12.7] |

`properties (Constant)` additionally hold the flaperon estimates (as `F16AeroL2`), the LE-flap
estimates (`hld_LE`, `c_lef_over_c`, `eta_lef_in/out`, `F_lef`, `delta_lef_*`, `k_lef`) and the
landing-gear buildup inputs (`Dq_wheels`, `Dq_strut_*`, `strut_ref_length`, wheel/leg counts)
[Raymer Table 12.6].

## 3. Derived (`Dependent`)

Read live from `obj.geom` on every read — no stored copy, read-only.

| Property | Source |
|---|---|
| `S_ref`, `AR_wing`, `LE_sweep_wing`, `QC_sweep_wing`, `lambda_wing` | scalar wing geometry, each read straight off `obj.geom` |
| `S_wet_wing`, `S_wet_ht`, `S_wet_vt`, `S_wet_strake`, `S_wet_fuselage`, `S_wet_duct` | the six component wetted areas, each read live |
| `S_wet_comp` | the six gathered in component order (Roskam Eq. 12.1 surfaces / station integration for the fuselage / frustum duct) |
| `l_ref_comp` | per-component MAC or length (`cbar_wing`, HT/VT MAC via `compute_mac`, `L_fus`, `L_duct`) |
| `D_comp` | body diameters (0 for surfaces; `D_fus`, `D_inlet`) |
| `tc_comp` | thickness ratio (mean root/tip for HT/VT; 0 for bodies) |
| `Lambda_m_comp` | max-thickness-line sweep at `x_c_max` — `convert_sweep` (4/AR) for the mirrored wing and HT, `convert_sweep_panel` (2/AR) for the single-panel VT |
| `Amax_ft2` | `geom.Amax` — **tier-specific**: area-ruled buildup 24.7037 at L3, envelope ellipse 27.4889 at L2 |
| `L_aircraft_ft` | `geom.L_aircraft` = 47.65 ft. Distinct from the fuselage `L_fus` used for the component Re and `FF_body` — do not conflate the two length scales |
| `CD0_misc` | `(Dq_gun_port + Dq_hook_USAF)/S_ref` [Raymer Table 12.7] |

---

## 4. Methods

| Group | Methods | Source |
|---|---|---|
| Contract | `drag_polar(state)`, `get_CLmax(state)` | `AeroL3.drag_polar`; Raymer Eq. 12.15 via `AeroL2.CLmax_clean` |
| Build-up + wave drag | `CD0_buildup` (the Eq. 12.24 sum plus `CD0_misc` and `CD0_LandP`), `get_CD0_component_buildup` (adds `compute_CD0_wave` for M ≥ 1.2), `compute_CD0_wave` | Raymer Eq. 12.24, 12.44/12.45 |
| Misc / leakage | `get_CD0_misc`, `get_CD0_LandP` | declared abstract by `AeroModelL3`; both are empty stubs, so either returns an unassigned output if called |
| Accessors | `get_K1`, `get_K2`, `get_CL_alpha`, `get_CL_minD`, `get_e_osw`, `compute_Re` | Raymer Eq. 12.50/12.51, 12.6, 12.48/12.49, 12.25 |
| Config | `get_config_polar(config)` | six config strings routed through the TO/landing deltas |
| TE flap | `Delta_CD0_flap`, `Delta_CDi_flap`, `Delta_CLmax_flap`, `compute_S_flapped_ratio` | Raymer Eq. 12.61/12.62, Table 12.2 + Eq. 12.21 |
| LE flap | `Delta_CD0_lef`, `Delta_CDi_lef`, `Delta_CLmax_lef` | Eq. 12.61/12.62 *form* — Raymer gives no separate LE citation |
| Landing gear | `compute_Delta_CD0_geardown` | Raymer Table 12.6 |
| Assembled | `get_Delta_{e_osw,CD0,CLmax,CDi}_{TO,L}`, `get_CLmax_{TO,L}` | — |

`get_CL_alpha` delegates to `AeroL2.CL_alpha`, so L2 and L3 return the same slope for identical
injected geometry. `roskam_e_osw` is private.

### As-built values

At 36,000 ft with `F16GeomL3` injected:

| Quantity | M 0.87 | M 1.6 |
|---|---|---|
| `CD0` | 0.016119 | 0.038808 |
| `CLmax` | 0.914058 | — |
| `CL_alpha` @ M 0 | 3.0364651 | — |

Wave drag applies only for M ≥ 1.2 (Eq. 12.41's own domain); there is **no transonic fairing** for
1.0 < M < 1.2. `CD0_buildup` errors when `state.mach <= 0` rather than returning NaN. On the
area-ruled `Amax`, `CD0_wave` is 0.0253630 at M 1.5, −0.54 % from the Brandt-referenced term at
`E_WD` = 2.2.

---

## 5. To-dos

| Item | Guard |
|---|---|
| `E_WD` = 2.2 is a tuned calibration knob back-checked to Brandt, not a measured F-16 datum | `TestAeroL3.testTODO_EWDCalibrationInput` |
| Surface-roughness table is Raymer 12.4/12.5, not 12.2 (citation drift) | `TestAeroL3.testTODO_RoughnessTableCitation` |
| `alpha_L0`, `cl_max_2D`, `cl_alpha_2D` unverified (shared with L2) | `TestAeroL2.testTODO_{AlphaL0,ClMax2D,ClAlpha2D}Unverified` |
| `strut_ref_length` = 0.3 ft is an estimate | in-code TODO |
| Flaperon and LEF estimates unverified against T.O. 1F-16A-1 | in-code TODO |
| `L_aircraft` = 47.65 ft is traceable to no in-repo document | `TestGeomL3.testTODO_OverallLengthCitationNotPinned`; todo §6 |
| `Amax`'s frame-rescaling assumption and its `π·D²/5` deduction are uncited | todo §4b, §5 |
