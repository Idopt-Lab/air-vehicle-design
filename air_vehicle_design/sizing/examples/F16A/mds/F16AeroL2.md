# F16AeroL2

F-16A Block 10/15 Level-2 aerodynamics: the geometry-dependent clean drag polar plus finite-wing
lift. `classdef F16AeroL2 < AeroModelL2`; every contract method delegates to the `AeroL2` static
toolbox, and the class adds the F-16's flaperon (TE) and leading-edge-flap (LE) high-lift/drag
deltas plus the landing-gear increment.

**LEF ADDED 2026-08-10.** L2 previously modeled only the flaperon — no leading-edge device at all —
while L3 modeled both. That was a real fidelity gap, not a simplification: `LandingConstraint`/
`TakeoffConstraint` read `CLmax_TO`/`CLmax_L` straight from this class, so `SizingLoopL2`'s landing
wall was missing the LEF's lift contribution entirely. Closing it moved L2's converged `W/S` optimum
from 104 to 111 psf, now matching L3's (`VnV/BrandtF16A/todo.md` 2026-08-10).

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));
ctrl = f16a_control_surfaces();
a2   = F16AeroL2(F16GeomL2(f16a_spec_path(2), prop), f16a_spec_path(2), ctrl);
```

`F16AeroL2(geom, json_path, ctrl)` — all three arguments required, no silent default. `json_path`
supplies the top-level `aircraft_category` and the `.aerodynamics` block of `f16a_L2.json`. `ctrl`
(a `ControlSurfaceSizer`, added 2026-08-10) supplies the flaperon's and LEF's chord/span fractions —
the SAME object `F16AeroL3` and the sizing loop's `ControlSurfaceSizer.size()` read, so one
description of each device drives its sized area and its aerodynamic contribution alike.

`geom` is guarded by `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`, not the bare
`GeometryBase` it once accepted — that declares only `S_ref`/`S_wet`/`get_S_ref`/`get_S_wet`, so a
wrong-tier object (an `F16GeomL1`, whose `S_wet` is a TOGW regression rather than a planform) used to
construct fine and then produce wrong or zero drag at first use. The guard cannot catch an L2-vs-L3
mix-up, though: both tiers satisfy the contract by design, so passing `g2` where `g3` was meant
yields plausible numbers rather than an error (todo §P4-22).

---

## 2. Inputs

Plain mutable `properties` — aero-only spec data. **No geometry is stored on this class.**

| Property | Value | Meaning / citation |
|---|---|---|
| `geom` | `F16GeomL2` or `F16GeomL3` | injected geometry object |
| `aircraft_category` | `"jet_fighter"` | top-level key; selects the Raymer Table 12.3 `Cfe` row |
| `e_method` | `"official"` | Oswald-e selector → Raymer Eq. 12.48/12.49 |
| `airfoil_name` | `"NACA 64A204"` | — |
| `airfoiltype` | `"cambered"` | a nonzero `alpha_L0` → `K2 ≠ 0` |
| `design_CL` | 0.2 | airfoil design lift coefficient |
| `alpha_L0` | deg | zero-lift AOA; drives `CL_minD` → `K2` |
| `cl_max_2D` | — | 2-D section `cl_max`; feeds Eq. 12.15 |
| `cl_alpha_2D` | 1/rad | 2-D lift slope (JSON gives per-degree; converted in the constructor) |
| `hld_TE`, `delta_flap_TO/L_deg`, `k_f_flap` | `"plain"`, 15/20°, 0.28 | flaperon deflections + Eq. 12.62 coefficient — deflection schedule, not control-surface geometry, so stays here (not on `ctrl`). `delta_flap_TO_deg`=15 is uncited and disagrees with `F16AeroL3`'s 20 — logged, not silently changed |
| `hld_LE`, `delta_slat_TO/L_deg`, `F_slat`, `k_slat` | `"slat"`, 17/17°, 0.0144, 0.14 | LEF deflections + Eq. 12.61/12.62 coefficients, ADDED 2026-08-10, identical to `F16AeroL3`'s (same device, same airframe). `delta_slat_TO/L_deg`=17 remains an unpinned stand-in — `TestAeroL2.testTODO_LEFScheduleNotPinned` |
| `c_flap_over_c`, `eta_flap_in/out`, `c_slat_over_c`, `eta_slat_in/out` | — | **MOVED to Dependent, 2026-08-10** — see §3. Genuine control-surface geometry now lives on the injected `ctrl`, not here |

## 3. Derived (`Dependent`)

Read live on every read — no stored copy, so nothing goes stale when geometry is mutated. Read-only.

| Property | Source | Note |
|---|---|---|
| `Cfe` | `AeroL2.lookup_Cfe(aircraft_category)` | Raymer Table 12.3, 0.0035 for an Air Force fighter. **Not a JSON input** — a published table constant is not spec data, and holding it as one invited tuning it onto Brandt's mission polar |
| `S_ref`, `S_wet`, `AR`, `taper` | `geom.S_ref` / `S_wet` / `AR_wing` / `lambda_wing` | — |
| `Lambda_LE_deg` | `geom.LE_sweep_wing` | — |
| `Lambda_c4_deg` | `geom.QC_sweep_wing` | ≈32.18°, from the sweep conversion |
| `L_char` | `geom.L_fus` | characteristic length for the aircraft-level supersonic Reynolds number |
| `c_flap_over_c`, `eta_flap_in/out` | `ctrl.c_flaperon_frac` / `eta_flaperon_in/out` | ADDED 2026-08-10; flaperon chord/span, live from the injected sizer |
| `c_slat_over_c`, `eta_slat_in/out` | `ctrl.c_lef_frac` / `eta_lef_in/out` | ADDED 2026-08-10; LEF chord/span, live from the injected sizer |

---

## 4. Methods

| Group | Methods | Source |
|---|---|---|
| Contract | `drag_polar(state)`, `get_CLmax(state)` | Raymer Eq. 12.23 / 12.15 |
| Accessors | `get_CD0`, `get_K1`, `get_K2`, `get_CL_alpha`, `get_e_osw` | Raymer Eq. 12.23, 12.50/12.51, 12.6 |
| Brandt alternate | `get_e_osw_brandt` | Brandt `Aero!G12` — comparison report only; `get_e_osw` errors on any `e_method` ≠ `"official"` |
| Flaperon primitives | `Delta_CD0_flap`, `Delta_CDi_flap`, `Delta_CLmax_flap` | Raymer Eq. 12.61, 12.62, Table 12.2 + Eq. 12.21; taper ratio via `AeroL2.compute_S_flapped_ratio` (Roskam Part II Eq. 7.10) |
| LEF primitives (ADDED 2026-08-10) | `Delta_CD0_slat`, `Delta_CDi_slat`, `Delta_CLmax_slat` | same equations as the flaperon primitives, mirrored exactly from `F16AeroL3`; `Delta_CLmax_slat` uses `Lambda_LE_deg` (LE-hinged), not `Lambda_c4_deg` |
| Assembled deltas | `get_Delta_{CD0,CLmax,CDi}_{TO,L}` sum the flap AND slat contributions independently (never combine one device's `ΔCLmax` into the other's `ΔCDi`, since `k_f_flap ≠ k_slat`); `get_CLmax_{TO,L}` | gear increment from Roskam Table 3.6 via private `roskam_*` helpers |

### As-built values

At 36,000 ft / M 0.87 with a fresh `F16GeomL2`:

| Quantity | Value | Formula |
|---|---|---|
| `CD0` | 0.017112 | `Cfe·S_wet/S_ref` = 0.0035 × 1466.77 / 300 |
| `e_osw` | 0.90861922 | Raymer Eq. 12.49 (AR 3, Λ_LE 40°) |
| `K1` | 0.116774 | `1/(π·AR·e)` |
| `K2` | −0.005201 | `−2·K1·CL_minD` |
| `CLmax` | 0.914058 | `0.9·cl_max_2D·cos Λ_c4` |
| `CL_alpha` @ M 0 | 3.0364651 | Raymer Eq. 12.6 |

---

## 5. To-dos

| Item | Guard |
|---|---|
| `delta_flap_TO_deg`=15 is uncited and disagrees with `F16AeroL3`'s 20 for the same aircraft | logged, `VnV/BrandtF16A/todo.md` 2026-08-10 Finding 6 |
| `delta_slat_TO/L_deg`=17 (LEF, ADDED 2026-08-10) is an unpinned stand-in against a primary AoA/Mach schedule — ported verbatim from `F16AeroL3`'s identical open item | `TestAeroL2.testTODO_LEFScheduleNotPinned` |
| `cl_max_2D` unverified | `TestAeroL2.testTODO_ClMax2DUnverified` |
| `cl_alpha_2D` unverified | `TestAeroL2.testTODO_ClAlpha2DUnverified` |
| `E_WD`=2.2 is a tuned calibration input, not a measured F-16 datum | `TestAeroL2.testTODO_EWDCalibrationInput` |
| The HLD/gear deltas are consumed by `TakeoffConstraint`/`LandingConstraint` (via `get_CLmax_{TO,L}`/`get_Delta_CD0_{TO,L}`) and by `TakeoffSegment` (mission) | closed — no longer a to-do |
