# F16AeroL2

F-16A Block 10/15 Level-2 aerodynamics: the geometry-dependent clean drag polar plus finite-wing
lift. `classdef F16AeroL2 < AeroModelL2`. Adds the F-16 flaperon high-lift and gear deltas, and one
deliberate override: `drag_polar`'s supersonic branch does not use the generic `AeroL2` CD0. See §4.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));
a2   = F16AeroL2(F16GeomL2(f16a_spec_path(2), prop), f16a_spec_path(2));
```

`F16AeroL2(geom, json_path)`. Both arguments are necessary. There is no default.

| Argument | Supplies |
|---|---|
| `geom` | the injected geometry object. All geometry is read live from it |
| `json_path` | `f16a_L2.json`: the top-level `aircraft_category` and the `.aerodynamics` block |

`geom` is guarded by `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])`. `GeometryBase` would
be too loose: it declares only `S_ref` and `S_wet`, so an `F16GeomL1`, whose `S_wet` is a TOGW
regression, would satisfy it and produce wrong drag.

The guard cannot separate L2 from L3. Both satisfy the contract, so a tier mix-up gives plausible
numbers. `Amax` is where it shows: 27.4889357 ft² against 24.7036517.

`e_osw` is `Dependent`, so a mutated `AR_wing` or `LE_sweep_wing` moves it.

---

## 2. Inputs

Aero-only spec data. **No geometry number is stored here.**

| Property | Value | Meaning and citation |
|---|---|---|
| `geom` | `F16GeomL2` or `F16GeomL3` | the injected geometry object |
| `aircraft_category` | `"jet_fighter"` | top-level key. Selects the Raymer Table 12.3 `Cfe` row |
| `airfoil_name` | `"NACA 64A204"` | — |
| `airfoiltype` | `"cambered"` | a nonzero `alpha_L0` gives `K2` not equal to 0 |
| `design_CL` | 0.200 | airfoil design lift coefficient |
| `alpha_L0` | −1.3300 deg | zero-lift AOA. Drives `CL_minD`, and so `K2` |
| `cl_max_2D` | 1.200 | 2-D section `cl_max`. Feeds Raymer Eq. 12.15 |
| `cl_alpha_2D` | 6.016057 1/rad | 2-D lift slope. The JSON gives per-degree; the constructor converts |
| `E_WD` | 2.2000 | wave-drag factor [Brandt `Aero!B8`]. A tuned calibration input |
| Flaperon set | `hld_TE` `"plain"`, `c_flap_over_c` 0.25, `eta_flap_in/out` 0.10/0.90, `delta_flap_TO/L_deg` 15/20, `k_f_flap` 0.28 | **hardcoded, not JSON.** `k_f_flap` is Raymer Eq. 12.62 |

## 3. Derived (`Dependent`)

Recomputed on every read, never cached. Read-only.

| Property | Source | Note |
|---|---|---|
| `Cfe` | `AeroL2.lookup_Cfe(aircraft_category)` | Raymer Table 12.3, 0.003500. **Not a JSON input**: a published constant is not spec data |
| `e_osw` | `get_e_osw()` | 0.90861922. Raymer Eq. 12.48/12.49 on `AR_wing` and `LE_sweep_wing` |
| `S_ref` | `geom.S_ref` | 300 ft² |
| `S_wet` | `geom.S_wet` | 1466.7730567 ft² at L2 |
| `AR_wing` | `geom.AR_wing` | 3.0 |
| `LE_sweep_wing` | `geom.LE_sweep_wing` | 40 deg |
| `QC_sweep_wing` | `geom.QC_sweep_wing` | 32.183178 deg, from the sweep conversion |
| `lambda_wing` | `geom.lambda_wing` | 0.2275 |
| `L_char` | `geom.L_fus` | 46.5000 ft, for the aircraft-level supersonic Reynolds number |
| `Amax_ft2` | `geom.Amax` | 27.4889357 ft², the fuselage-envelope ellipse. **Tier-specific**; do not unify with L3's area-ruled value |
| `L_aircraft_ft` | `geom.L_aircraft` | 47.6500 ft. Not `L_fus` |

Property names mirror the geometry class, so no translation is needed between them.

---

## 4. Methods

| Group | Methods | Source |
|---|---|---|
| Contract | `drag_polar(state)`, `get_CLmax(state)`, `get_config_polar(config)` | Raymer Eq. 12.23 / 12.15 |
| Accessors | `get_CD0_rough`, `get_K1(M)`, `get_K2(K1, M)`, `get_CL_alpha(M)`, `get_e_osw` | Raymer Eq. 12.23, 12.50/12.51, 12.8 |
| F-16 override | `compute_CD0_wave(state)` | Brandt `Aero!B8/G8` |
| Flaperon primitives | `compute_S_flapped_ratio`, `Delta_CD0_flap`, `Delta_CDi_flap`, `Delta_CLmax_flap` | Roskam Part II Eq. 7.10; Raymer Eq. 12.61, 12.62, Table 12.2 + Eq. 12.21 |
| Assembled deltas | `get_Delta_{e_osw,CD0,CLmax,CDi}_{TO,L}`, `get_CLmax_{TO,L}` | gear increments from Roskam Table 3.6 |
| Private | `roskam_e_osw`, `roskam_Delta_CD0` | read `AeroL1.Delta_CD0`, Roskam Table 3.6 |

### `drag_polar` has three branches, not two

`AeroL2.flight_regime(state.mach)` selects:

| Regime | `CD0` | `K1` | `K2` |
|---|---|---|---|
| subsonic | `get_CD0_rough()` | Raymer Eq. 12.50 | Eq. 12.6 chain |
| supersonic | `get_CD0_rough() + compute_CD0_wave(state)` | Raymer Eq. 12.51 | 0 |
| transonic | `NaN` | `NaN` | `NaN`, with warning `AeroL2:transonicNotModeled` |

**Why the override exists.** The generic `AeroL2` supersonic CD0 is skin friction only, so it reads
*below* the subsonic CD0 at M 1.6. This class adds Brandt's wave-drag increment to the **subsonic**
CD0, matching his own split. It is Brandt's tuned formula with `E_WD` = 2.2, so it stays on the F-16
class.

    CD0_wave = (4.5*pi/S_ref) * (Amax/L_aircraft)^2 * E_WD
               * (0.74 + 0.37*cos(Lambda_LE)) * (1 - 0.3*sqrt(M - M_CD0max))
    M_CD0max = (1/cos(Lambda_LE))^0.2

`M_CD0max` is 1.0547 at 40 deg sweep against `MACH_SUPERSONIC_MIN` 1.05, so `max(0, ...)` clamps the
sqrt real in that sliver. It shares Raymer Eq. 12.44's `4.5*pi` coefficient but not its correction
terms; the two tiers are deliberately different formulas.

**Transonic behaviour differs by entry point.** `drag_polar` warns and returns `NaN`; `get_K1` called
directly errors with the same identifier. A polar consumer wants something `isnan` can test.

### As-built values

With a fresh `F16GeomL2`:

| Quantity | Value | Formula |
|---|---|---|
| `CD0` @ 36 kft, M 0.87 | 0.01711235 | `Cfe*S_wet/S_ref` = 0.0035 x 1466.7730567 / 300 |
| `K1` @ M 0.87 | 0.11677421 | `1/(pi*AR*e)` |
| `K2` @ M 0.87 | −0.00684927 | `−2*K1*CL_minD` |
| `CD0` @ 36 kft, M 1.60 | 0.04460144 | subsonic 0.01711235 + wave 0.02748909 |
| `K1` @ M 1.60 | 0.27603090 | Raymer Eq. 12.51 |
| `K2` @ M 1.60 | 0 | zero above M 1 |
| `e_osw` | 0.90861922 | Raymer Eq. 12.49, AR 3, Lambda_LE 40 deg |
| `CLmax` | 0.91405754 | `0.9*cl_max_2D*cos(QC_sweep)` |
| `CL_alpha` @ M 0 | 3.0364651 | Raymer Eq. 12.8 |

High-lift and gear deltas:

| Quantity | TO | Landing |
|---|---|---|
| `Delta_CLmax` | 0.32906072 | 0.43874762 |
| `Delta_CD0` | 0.03440000 | 0.04880000 |
| `Delta_CDi` | 0.02566019 | 0.04561812 |
| `Delta_e_osw` | −0.050000 | −0.100000 |
| `CLmax` total | 1.24311826 | 1.35280517 |

`compute_S_flapped_ratio(0.90, 0.10, 0.2275)` = 0.80000000. `get_config_polar("landing_flaps_gear_down")`
gives `CD0` 0.06591235 and `CLmax` 1.35280517.

`get_config_polar` takes six config strings and gives three distinct results: no gear-up against
gear-down split, so both `takeoff_*` map to the takeoff deltas and both `landing_*` plus `approach`
to the landing deltas.

---

## 5. To-dos

| Item | Guard |
|---|---|
| **The flaperon estimates are hardcoded, not JSON inputs**, and unverified against T.O. 1F-16A-1 | in-code TODO |
| `alpha_L0` = −1.3300 deg is unverified | `TestAeroL2.testTODO_AlphaL0Unverified` |
| `cl_max_2D` = 1.200 is unverified | `TestAeroL2.testTODO_ClMax2DUnverified` |
| `cl_alpha_2D` = 6.016057 1/rad is unverified | `TestAeroL2.testTODO_ClAlpha2DUnverified` |
| `E_WD` = 2.2 is a tuned Brandt calibration input, not a derived or cited value | `TestAeroL2.testTODO_EWDCalibrationInput` |
| `get_CD0_supersonic` is unused: the supersonic branch uses `get_CD0_rough` plus `compute_CD0_wave` | `% Note (8/21/2026)(Casey)` |
| The `mustBeA` guard cannot separate an L2 from an L3 geometry | this doc |
| The high-lift and gear deltas are implemented and unit-tested, but no constraint consumes them yet | mission and sizing not wired |
