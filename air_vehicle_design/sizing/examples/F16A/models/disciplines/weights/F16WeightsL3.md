# F16WeightsL3

F-16A Block 10/15 Level-3 weights. `classdef F16WeightsL3 < WeightsModelL3`; every group method is a
delegation into the `WeightsL3` static toolbox.

**L3 is the Raymer §15.3.1 fighter/attack component buildup** — Eqs. 15.1–15.24 plus three
Table 15.3 items, grouped into structural / landing gear / engine / systems / misc, with the strake
weighed by Eq. 15.1 on strake geometry.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));   % no L3 propulsion tier exists
g3   = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
```

`F16WeightsL3(json_path, req_path, geom, prop)` — all four required, no silent default.

| Argument | Guard | Supplies |
|---|---|---|
| `json_path` | text | `aircraft_category` + the `.weights` §15.3.1 coefficients and counts |
| `req_path` | text | `design_mach`, `cruise.altitude_ft`, `cruise.mach` |
| `geom` | `GeometryModelL2` or `GeometryModelL3` | 25 geometry quantities (§3) |
| `prop` | `PropulsionBase` | `T_max`, `W_en`, `SFC_mission` |

Every geometry number arrives by DI; none is stored here. L3 builds its own `AircraftState` from the
cruise inputs — no `AircraftState` is injected.

---

## 2. Inputs

43 numeric + `aircraft_category` + 2 injected objects.

| Group | Properties |
|---|---|
| State | `W_TO`, `W_energy` (both `NaN`; sizing-loop state) |
| Mission | `W_payload_fixed` 700, `W_payload_expendable` 4400, `W_landing` (`NaN` until the loop writes it) |
| Requirements | `design_mach` 2.0, `cruise_altitude_ft` 36000, `cruise_mach` 0.87 |
| Load / structure factors | `N_z` 13.5, `K_dw`, `K_vs`, `K_rht`, `K_dwf`, `K_vsh` |
| Landing gear | `N_l`, `L_m`, `L_n` (converted to **inches** at the call site per Raymer nomenclature), `K_cb`, `K_tpg`, `N_nw` |
| Engine / induction | `N_en` 1, `S_fw`, `D_e`, `L_tp`, `L_sh`, `L_ec`, `L_d`, `L_s`, `K_vg`, `K_d` |
| Fuel system | `V_t` 940 gal, `V_i`, `V_p`, `N_t` |
| Systems | `N_s`, `N_c`, `N_ci`, `N_u`, `R_kva`, `L_a`, `N_gen`, `W_uav`, `K_mc` |
| Strake | `S_strake` 20 ft², `k_strake` 4.5 lbf/ft² |
| Classification | `aircraft_category` — carried for interface parity and report labelling; **unread** by `WeightsL3` by construction (one buildup, one path) |
| Injected | `geom`, `prop` |

`N_z` = 13.5 (= 1.5 × 9 g limit, ultimate) is the §15.3.1 basis; Brandt's psf model uses `n_ult` = 9
(`Main!Q27`). Two different models — do not conflate.

`K_rht` = 1.047 is applied to **Eq. 15.3 (VT)**, not 15.2, exactly as the book defines it. The JSON
keys it under `.weights.horizontal_tail` because the *flag* describes the HT. Both facts need to stay
visible at the DI site — it reads like a bug otherwise.

`W_landing` is the one input the sizing loop writes rather than the JSON. `SizingLoopL2` reads the
mission breakdown's `W_landing` — the weight entering the `landing` segment — and pushes it here
before every `get_OEW` call.

## 3. Derived (`Dependent`) — 36

**Geometry via DI (25)** — `S_w`, `AR_w`, `tc_root`, `lambda_w`, `Lambda_LE_w`, `S_csw`,
`AR_strake`, `tc_root_strake`, `lambda_strake`, `Lambda_LE_deg_strake`, `S_ht`, `F_w`, `B_h`,
`S_vt`, `AR_vt`, `lambda_vt`, `Lambda_LE_vt`, `H_t`, `H_v`, `L_t`, `S_r`, `L_fus`, `D_fus`,
`W_fus`, `S_cs` — each reading `obj.geom.*`.

**Three DI name traps**, each producing a plausible wrong number rather than an error:

| Weights property | Reads | NOT |
|---|---|---|
| `D_fus` (Eq. 15.4 structural depth) | `geom.H_max_fuselage` = 5.0 | `geom.D_fus` = 6.0 (Roskam equivalent diameter) |
| `S_ht` (Eq. 15.2 exposed area) | `geom.S_exposed_ht` = 51.1486 | `geom.S_ht` = 108 (full planform) |
| `S_vt` (Eq. 15.3 exposed area) | `geom.S_exposed_vt` = 40.8897 | `geom.S_vt` = 60 (full planform) |

**Propulsion DI and weight groups (11)**

| Property | Source / formula | Value at `W_TO` = 31,377 |
|---|---|---|
| `T_max` | `prop.T_SL` | 23770 lbf |
| `W_en` | `PropL2.engine_weight_AB(...)` — **UNINSTALLED** [Raymer Eq. 10.10] | 2775.021 lbf |
| `W_en_brandt` | `0.199·prop.T_SL` — report-only, never summed | 4730.230 lbf |
| `W_l` | `W_landing` from the mission, else the `0.95·W_TO` seed | 29808.15 lbf (seed) |
| `SFC_mission` | `prop.get_TSFC(AircraftState(cruise), "mil")` | 1.087685 1/hr, installed |
| `W_wings` | Eq. 15.1 | 2396.767 lbf |
| `W_tail` | Eqs. 15.2 + 15.3, summed | 513.601 lbf |
| `W_fuselage` | Eq. 15.4 | 3674.197 lbf |
| `W_installed_engine` | dry engine (10.10) + Eqs. 15.7–15.15 | 3381.698 lbf |
| `W_subsystems` | Eqs. 15.16–15.21, 15.23 | 4358.687 lbf |
| `W_strake` | `k_strake·S_strake` [Brandt `Main!D18` / `Wt!H7`] — report-only, **never summed** | 90.00 lbf |

`requireWTO` guards the four that genuinely carry `W_dg` or `W_l`: `W_wings`, `W_tail`,
`W_fuselage`, `W_l`. `W_installed_engine` and `W_subsystems` are deliberately unguarded — their
equations are built from thrust, component geometry and equipment counts, and carry no `W_TO` term.
A guard must encode a real dependency, not a house style.

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_OEW_component_buildup` | `W_TO` | `oew` [lbf] — the ten-term sum |
| `get_weight_wing` | `W_TO` | Eq. 15.1 [lbf] |
| `get_weight_tail` | `W_TO` | Eqs. 15.2 + 15.3 [lbf] |
| `get_weight_HT` | `W_TO` | Eq. 15.2 [lbf] |
| `get_weight_VT` | `W_TO` | Eq. 15.3 [lbf] |
| `get_weight_fuselage` | `W_TO` | Eq. 15.4 [lbf] |
| `get_weight_landing_gear` | `W_l` | Eqs. 15.5 + 15.6 [lbf] |
| `get_weight_engine` | none | dry engine + Eqs. 15.7–15.15 [lbf] |
| `get_weight_subsystems` | none | Eqs. 15.16–15.21, 15.23 [lbf] |
| `get_weight_misc` | `W_TO` | Eqs. 15.22, 15.24 + Table 15.3 [lbf] |
| `get_weight_strake` | `W_TO` | Eq. 15.1 on strake geometry [lbf] |

`WeightsModelL3.get_OEW(obj, W_TO)` bridges `WeightsBase`'s generic name onto
`get_OEW_component_buildup`, threading the passed `W_TO` through. Nothing in the buildup reads
`obj.W_TO`, so `get_OEW` is a pure function of its argument. The Dependent group properties do read
`obj.W_TO`, through `requireWTO`.

`get_weight_HT` / `get_weight_VT` exist because the CG buildup in `F16SandCL3` weighs the two
surfaces at different stations; `get_weight_tail` is their sum.

### Landing gear — the argument is the landing weight, not the gross weight

`get_weight_landing_gear(W_l)` takes the **landing design gross weight** [Raymer 6th ed. p. 579].
`L_m` and `L_n` are stored in feet and Eqs. 15.5/15.6 take inches, so the call site multiplies by 12.
Omitting that made the gear about 8× too light.

Guards: `testLandingGearScalesWithWTO`, `testLandingGearIsNotTheFrozenValue`,
`testLandingGearArgumentWinsOverStaleObjectWTO`, `testStrutLengthsAreConvertedToInches`.

### Engine weight — uninstalled at L3, by design

L2 applies the `×1.3` installed factor; **L3 does not.** §15.3.1 builds the installation up item by
item — mounts, firewall, section, induction, tailpipe, cooling, oil, controls, starter — which is
exactly what `×1.3` lumps into one factor, and Raymer's nomenclature for Eq. 15.9's `W_en` is the dry
engine weight *each*.

The `×1.3` variant agrees **better** with Brandt. That was the reason to reject it: a number that
agrees because a factor is double-counted is not agreement.

### Strake — Eq. 15.1 on strake geometry

§15.3.1 has no strake equation, so the buildup borrows Eq. 15.1 and feeds it the strake's own
planform: `S_strake` 20 ft², `AR` 1.5, `tc_root` 0.04, `lambda` 0 (sharp tip), `Lambda_LE` 74°.

**Eq. 15.1's `S_csw` slot takes `obj.S_strake` as a stand-in.** The strake carries no control
surface, and `S_csw` enters as a bare area to the 0.04 power, so `S_csw = 0` zeroes the whole term.
There is no source for the substitution. Its effect is small: 0 → 780.94, 20 → 880.36,
68.03 (the wing's own `S_csw`) → 924.55, 190 → 963.32 lbf.

The result is 880.36 lbf, or 44.02 psf, against the wing's own 12.21 psf. Eq. 15.1's `S_w^0.622` is
sub-linear, so a 20 ft² surface comes out heavy per unit area. `W_strake` keeps Brandt's
`4.5 × 20 = 90.00` lbf for the comparison report and is never summed.

### As-built values at `W_TO` = 31,377 lbf

| Group | Value [lbf] |
|---|---|
| wing (15.1) | 2396.767 |
| HT (15.2) / VT (15.3) | 200.541 / 313.060 |
| fuselage (15.4) | 3674.197 |
| main gear (15.5) / nose gear (15.6) | 989.983 / 170.950 |
| engine group (10.10 + 15.7–15.15) | 3381.698 |
| systems group (15.16–15.21, 15.23) | 4358.687 |
| misc group (15.22, 15.24 + Table 15.3) | 818.395 |
| strake (15.1 on strake geometry) | 880.362 |
| **`get_OEW(31377)`** | **17184.640** |

Misc group breakdown: furnishings 217.600, handling gear 10.041, arresting gear 62.754, pylons and
launchers 528.000.

`SFC_mission` = 1.087685 sits +55.38 % above Brandt's `Main!C30` = 0.70 — accepted, because it is a
live DI read at the cruise condition rather than a stored constant. Both are installed values, so
the gap is the cruise point against Brandt's single stored SLS number. Its test asserts the
*identity against the injected object*, deliberately not the literal value.

The OEW-vs-Brandt agreement check lives in `weights_brandt_comparison`, not in the unit tier.

### In the sizing loop

`f16_sizing_L3` closes at `W_TO` 26082.4, `T_SL` 17843.3, `S_ref` 203.83 ft², `OEW` 14737.1,
`W_fuel` 6245.3 lbf, 28 iterations. `W_landing` converges to 15870.0 lbf, or 0.608 × `W_TO`, well
below the 0.95 seed, because the CAP mission burns its fuel and drops the payload before landing.
Brandt's own `Wt!B41` ratio is 20680.7 / 31377 = 0.659.

---

## 5. To-dos

| Item | Guard |
|---|---|
| **Darshan → Krish, HIGH PRIORITY: cross-check L3 weights** against Brandt `Wt!B12` = 19980.70. The unverified exponents below are the first place to look | open |
| **All 62 §15.3.1 exponents are unverified against the printed book** — tallied 2 CONFLICT / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY in `WeightsL3.m`'s header. The two CONFLICTs keep their **code** values: Eq. 15.13 `N_en^1.023` (extract says 1.078), Eq. 15.3 `cos(Λ_vt)^−0.323` (extract says −1.0). Do not change a value to make the guard green | `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` — deliberately red; todo §3a |
| Eq. 15.1's `S_csw` slot for the strake has **no source**. Sensitivity ±10 % across plausible values | flagged in `get_weight_strake`; no guard, since a guard would be a false green |
| `K_d = 0` silently zeroes the 227.54 lbf air-induction term (`0^0.182 = 0`) — no error, no warning, not even NaN. **Left unguarded by decision**, and no guard test was added | todo §P4-11 — visible only as a sensitivity row in the comparison report |
| The `0.95` in the `W_l` seed has **no citation**. It applies only until a mission runs | todo §P4-16 |
| The 6.7 lb/gal fuel density behind `V_t` = 940 is cited **nowhere** in `sizing/`. `V_t` stays a JSON input precisely so the uncited constant never enters an equation | todo §P4-5b |
| `L_d` and `D_e` have cited geometry analogs deliberately **not** wired. Sensitivities on `OEW`: `L_d` +201.47, `D_e` +24.94 | todo §P4-4 |
| `design_mach` 2.0 (Brandt) vs the T.O. operating limit 2.05 | todo §P4-13 |
| `L_t`, `S_cs`, `S_csw`, `S_r`, `H_t`, `H_v` reach this class by DI but remain `[estimate]` inputs on the geometry side | todo GeomL3 §6 |
| Brandt's `0.199·T_AB` engine alternate should be replaced with a Raymer form | `F16WeightsL3.m` TODO (9/4/2026) |
