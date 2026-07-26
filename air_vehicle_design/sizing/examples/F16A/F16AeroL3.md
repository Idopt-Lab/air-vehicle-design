# F16AeroL3

F-16A Block 10/15 Level-3 aerodynamics: the Raymer Eq. 12.24 component drag build-up plus the F-16's
own supersonic wave-drag term. `classdef F16AeroL3 < AeroModelL3`; most methods delegate to the
`AeroL3` static toolbox, while `get_CD0_buildup`/`drag_polar` add wave drag on top. The class also
carries a full high-lift suite (TE flaperon + LE slat + landing gear).

**Component order everywhere: wing, HT, VT, fuselage, duct.**

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));   % no L3 propulsion tier exists
a3   = F16AeroL3(F16GeomL3(f16a_spec_path(3), prop), f16a_spec_path(3));
```

`F16AeroL3(geom, json_path)` — both arguments required, no silent default. `json_path` supplies the
`.aerodynamics` block of `f16a_L3.json`.

`geom` is guarded by `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`, not the old
`GeometryBase` — that declares four members while this class reads ~20 off `obj.geom`, so a wrong
tier used to construct cleanly and then die mid-run inside `get.S_wet_comp`, or worse resolve members
whose *meaning* differed. Both tiers satisfy the contract, but they are **not interchangeable here**:
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
| `cl_alpha_2D` | 1/rad | 2-D lift slope → the Eq. 12.8 `η` term. Without it `AeroL2.get_CL_alpha` fell back to `η = 0.95`, leaving L3 *less* informed than L2 on the same airfoil |
| `x_c_max_comp` | `[0.4 0.35 0.35 0 0]` | chordwise max-thickness station (0 for bodies) [Raymer Table 12.6] |
| `Q_comp` | `[1 1.05 1.05 1 1]` | interference factor [Raymer Table 12.6] |
| `f_lam_comp` | per component | laminar-flow fraction |
| `is_body_comp` | logical | selects the body form factor (Eq. 12.31) |
| `k` | ft | equivalent surface roughness, smooth paint [Raymer Table 12.4/12.5] |
| `E_WD` | 2.2 | wave-drag efficiency factor — a **tuned calibration input** [Raymer Eq. 12.45] |
| `CD0_LandP` | 0.0010 | leakage & protuberance allowance [Raymer §12.5] |
| `Dq_gun_port` / `Dq_hook_USAF` | 0.20 / 0.10 ft² | misc drag areas [Raymer Table 12.7] |

`properties (Constant)` additionally hold the flaperon estimates (as `F16AeroL2`), the LE-slat
estimates (`hld_LE`, `c_slat_over_c`, `eta_slat_in/out`, `F_slat`, `delta_slat_*`, `k_slat`) and the
landing-gear buildup inputs (`Dq_wheels`, `Dq_strut_*`, `strut_ref_length`, wheel/leg counts)
[Raymer Table 12.6].

## 3. Derived (`Dependent`)

Read live from `obj.geom` on every read — no stored copy, read-only.

| Property | Source |
|---|---|
| `S_ref`, `AR`, `Lambda_LE_deg`, `Lambda_c4_deg`, `taper` | scalar wing geometry (`Lambda_c4_deg` = `geom.QC_sweep_wing`) |
| `S_wet_comp` | per-component wetted area (Roskam Eq. 12.1 surfaces / 12.3 fuselage / frustum duct) |
| `l_ref_comp` | per-component MAC or length (`cbar_wing`, HT/VT MAC via `compute_mac`, `L_fus`, `L_duct`) |
| `D_comp` | body diameters (0 for surfaces; `D_fus`, `D_inlet`) |
| `tc_comp` | thickness ratio (mean root/tip for HT/VT; 0 for bodies) |
| `Lambda_m_comp` | max-thickness-line sweep at `x_c_max` — `convert_sweep` (4/AR) for the mirrored wing and HT, `convert_sweep_panel` (2/AR) for the single-panel VT |
| `Amax_ft2` | `geom.Amax` — **tier-specific**: area-ruled buildup 24.7037 at L3, envelope ellipse 27.4889 at L2 |
| `L_aircraft_ft` | `geom.L_aircraft` = 47.65 ft. Distinct from the fuselage `L_fus` used for the component Re and `FF_body` — do not conflate the two length scales |
| `CD0_misc` | `(Dq_gun_port + Dq_hook_USAF)/S_ref` [Raymer Table 12.7] |

`Amax_ft2` and `L_aircraft_ft` were plain inputs fed from a `.aerodynamics.wave_drag` JSON block
holding Brandt *geometry outputs* (25.110556 / 48.303947) — frozen numbers the Sears-Haack term could
not respond to. That block is deleted and both are `Dependent`.

---

## 4. Methods

| Group | Methods | Source |
|---|---|---|
| Contract | `drag_polar(state)`, `get_CLmax(state)` | `AeroL3.drag_polar`; Raymer Eq. 12.15 via `AeroL2.CLmax_clean` |
| Build-up + wave drag | `get_CD0_buildup` (overrides the generic Eq. 12.24 sum to add `compute_CD0_wave` for M ≥ 1.2) | Raymer Eq. 12.24, 12.44/12.45 |
| Accessors | `get_K1`, `get_K2`, `get_CL_alpha`, `get_e_osw`, `get_e_osw_brandt`, `compute_Re` | Raymer Eq. 12.50/12.51, 12.6, 12.48/12.49, 12.25 |
| TE flap | `Delta_CD0_flap`, `Delta_CDi_flap`, `Delta_CLmax_flap`, `compute_S_flapped_ratio` | Raymer Eq. 12.61/12.62, Table 12.2 + Eq. 12.21 |
| LE slat | `Delta_CD0_slat`, `Delta_CDi_slat`, `Delta_CLmax_slat` | Eq. 12.61/12.62 *form* — Raymer gives no separate LE citation |
| Landing gear | `compute_Delta_CD0_geardown` | Raymer Table 12.6 |
| Assembled | `get_Delta_{e_osw,CD0,CLmax,CDi}_{TO,L}`, `get_CLmax_{TO,L}` | — |

`get_CL_alpha` delegates to `AeroL2.get_CL_alpha(obj, M)`, so L2 and L3 return the same slope for
identical injected geometry.

### As-built values

At 36,000 ft with `F16GeomL3` injected:

| Quantity | M 0.87 | M 1.6 |
|---|---|---|
| `CD0` | 0.016169 | 0.038816 |
| `CLmax` | 0.914058 | — |
| `CL_alpha` @ M 0 | 3.0364651 | — |

Wave drag applies only for M ≥ 1.2 (Eq. 12.41's own domain); there is **no transonic fairing** for
1.0 < M < 1.2. `get_CD0_buildup` errors when `state.mach <= 0` rather than returning NaN. With the
area-ruled `Amax`, `CD0_wave` sits −0.54 % from the Brandt-referenced term with `E_WD` = 2.2
unchanged — no retune was applied.

---

## 5. To-dos

| Item | Guard |
|---|---|
| `E_WD` = 2.2 is a tuned calibration knob back-checked to Brandt, not a measured F-16 datum | `TestAeroL3.testTODO_EWDCalibrationInput` |
| Surface-roughness table is Raymer 12.4/12.5, not 12.2 (citation drift) | `TestAeroL3.testTODO_RoughnessTableCitation` |
| `alpha_L0`, `cl_max_2D`, `cl_alpha_2D` unverified (shared with L2) | `TestAeroL2.testTODO_{AlphaL0,ClMax2D,ClAlpha2D}Unverified` |
| `strut_ref_length` = 0.3 ft is an estimate | in-code TODO |
| Flaperon and slat estimates unverified against T.O. 1F-16A-1 | in-code TODO |
| `L_aircraft` = 47.65 ft is traceable to no in-repo document | `TestGeomL3.testTODO_OverallLengthCitationNotPinned`; todo §6 |
| `Amax`'s frame-rescaling assumption and its `π·D²/5` deduction are uncited | todo §4b, §5 |
