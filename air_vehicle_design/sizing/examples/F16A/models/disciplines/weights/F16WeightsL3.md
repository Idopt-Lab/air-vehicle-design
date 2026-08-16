# F16WeightsL3

F-16A Block 10/15 Level-3 weights. `classdef F16WeightsL3 < WeightsModelL3`; every abstract method is
a one-line delegation into the `WeightsL3` static toolbox.

**L3 is the Raymer §15.3.1 fighter/attack component build-up** — Eqs. 15.1–15.24, one equation per
component, grouped into structural / landing gear / engine / systems.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));   % no L3 propulsion tier exists
g3   = F16GeomL3(f16a_spec_path(3), prop);
w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
```

`F16WeightsL3(json_path, req_path, geom, prop)` — all four required, no silent default.

| Argument | Guard | Supplies |
|---|---|---|
| `json_path` | text | `aircraft_category` + the `.weights` §15.3.1 coefficients and counts |
| `req_path` | text | `design_mach`, `cruise.altitude_ft`, `cruise.mach` |
| `geom` | `GeometryModelL3` | 21 geometry quantities (§3) |
| `prop` | `PropulsionBase` | `T_max`, `W_en`, `SFC_mission` |

The class formerly carried ~22 hardcoded geometry constants; all now arrive by DI. L3 builds its own
`AircraftState` from the cruise inputs — no `AircraftState` is injected.

---

## 2. Inputs

42 numeric + `aircraft_category` + 2 injected objects.

| Group | Properties |
|---|---|
| State | `W_TO`, `W_energy` (both `NaN`; sizing-loop state) |
| Mission | `W_payload_fixed` 700, `W_payload_expendable` 4400 |
| Requirements | `design_mach` 2.0, `cruise_altitude_ft` 36000, `cruise_mach` 0.87 |
| Load / structure factors | `N_z` 13.5, `K_dw`, `K_vs`, `K_rht`, `K_dwf`, `K_vsh` |
| Landing gear | `N_l`, `L_m`, `L_n` (converted to **inches** per Raymer nomenclature), `K_cb`, `K_tpg`, `N_nw` |
| Engine / induction | `N_en` 1, `S_fw`, `D_e`, `L_tp`, `L_sh`, `L_ec`, `L_d`, `L_s`, `K_vg`, `K_d` |
| Fuel system | `V_t` 940 gal, `V_i`, `V_p`, `N_t` |
| Systems | `N_s`, `N_c`, `N_ci`, `N_u`, `R_kva`, `L_a`, `N_gen`, `W_uav`, `K_mc` |
| Classification | `aircraft_category` — carried for interface parity and report labelling; **unread** by `WeightsL3` by construction (one build-up, one path) |
| Injected | `geom`, `prop` |

`N_z` = 13.5 (= 1.5 × 9 g limit, ultimate) is the §15.3.1 basis; Brandt's psf model uses `n_ult` = 9
(`Main!Q27`). Two different models — do not conflate.

`K_rht` = 1.047 is applied to **Eq. 15.3 (VT)**, not 15.2, exactly as the book defines it. The JSON
keys it under `.weights.horizontal_tail` because the *flag* describes the HT. Both facts need to stay
visible at the DI site — it reads like a bug otherwise.

## 3. Derived (`Dependent`) — 32

**Geometry via DI (21)** — `S_w`, `AR_w`, `tc_root`, `lambda_w`, `Lambda_LE_w`, `S_csw`, `S_ht`,
`F_w`, `B_h`, `S_vt`, `AR_vt`, `lambda_vt`, `Lambda_LE_vt`, `H_t`, `H_v`, `L_t`, `S_r`, `L_fus`,
`D_fus`, `W_fus`, `S_cs` — each reading `obj.geom.*`.

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
| `W_l` | `0.95·W_TO`, feeding Eqs. 15.5/15.6 | 29808.15 lbf |
| `SFC_mission` | `prop.get_TSFC(AircraftState(cruise))` | 1.007116 1/hr |
| `W_wings` | Eq. 15.1 | 2396.767 lbf |
| `W_tail` | Eqs. 15.2 / 15.3 (struct `.HT`, `.VT`) | 200.541 / 313.060 lbf |
| `W_fuselage` | Eq. 15.4 | 3674.197 lbf |
| `W_installed_engine` | Eqs. 15.7–15.15 group total | 3381.698 lbf |
| `W_subsystems` | Eqs. 15.16–15.24 group total | 4578.134 lbf |
| `W_strake` | `k_strake·S_strake` [Brandt `Main!D18` / `Wt!H7`] | 90.00 lbf |

**`W_subsystems` does NOT include the landing gear** — that is `weight_landing_gear(obj, W_TO)`.

`requireWTO` guards the five that genuinely carry `W_dg` or `W_l`: `W_wings`, `W_tail`,
`W_fuselage`, `W_subsystems`, `W_l`. `W_installed_engine` is deliberately unguarded — Eqs. 15.7–15.15
are built from thrust and component geometry and carry no `W_TO` term. A guard must encode a real
dependency, not a house style.

---

## 4. Methods

| Method | Returns | Equations |
|---|---|---|
| `OEW(W_TO)` | scalar | sum of the four groups |
| `weight_wing(W_TO)` | scalar | 15.1 |
| `weight_tail(W_TO)` | struct `.HT`, `.VT` | 15.2, 15.3 |
| `weight_fuselage(W_TO)` | scalar | 15.4 |
| `weight_landing_gear(W_TO)` | struct `.main`, `.nose` | 15.5, 15.6 |
| `weight_engine_section(W_TO)` | struct + `.total` | dry engine (10.10) + 15.7–15.15 |
| `weight_systems(W_TO)` | struct + `.total` | 15.16–15.24 |

`weight_landing_gear` takes `W_TO`; it once did not, and with `W_l` stored as Brandt's frozen
`Wt!B41` output the whole landing-gear group was bit-identical at 31,377 / 45,000 / 60,000 lbf.
Guards: `testLandingGearScalesWithWTO`, `testLandingGearIsNotTheFrozenValue`,
`testLandingGearArgumentWinsOverStaleObjectWTO`, `testLandingWeightIsDerivedFromWTO`.

### Engine weight — uninstalled at L3, by design

L2 applies the `×1.3` installed factor; **L3 does not.** §15.3.1 builds the installation up item by
item — mounts, firewall, section, induction, tailpipe, cooling, oil, controls, starter — which is
exactly what `×1.3` lumps into one factor, and Raymer's nomenclature for Eq. 15.9's `W_en` is the dry
engine weight *each*.

The `×1.3` variant agrees **better** with Brandt (16546.06 vs 15705.33 against 19980.70). That was
the reason to reject it: a number that agrees because a factor is double-counted is not agreement.

### As-built values

| Quantity | Value |
|---|---|
| `OEW(31377)` | **15795.33 lbf** (−20.95 % vs Brandt `Wt!B12` 19980.70) |
| landing-gear total | 1160.934 lbf |

`SFC_mission` = 1.007116 sits +43.87 % above Brandt's `Main!C30` = 0.70 — accepted, because it is a
live DI read at the cruise condition rather than a stored constant. Its test asserts the *identity
against the injected object*, deliberately not the literal value.

Brandt carries nacelle, strake, other-structure and armament-support line items with no framework
analog — about 2733.68 lbf, 13.68 % of `Wt!B12`. The OEW-vs-Brandt agreement check lives in
`weights_brandt_comparison`, not in the unit tier.

---

## 5. To-dos

| Item | Guard |
|---|---|
| **Darshan → Krish, HIGH PRIORITY: cross-check L3 weights.** `OEW` comes out significantly lower than Brandt (15705.33 vs 19980.70, −21.40 %). ~2733.68 lbf is Brandt line items with no framework analog; the rest is unexplained, and the unverified exponents below are the first place to look | open |
| **All 62 §15.3.1 exponents are unverified against the printed book** — tallied 2 CONFLICT / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY in `WeightsL3.m`'s header (corrected 2026-07-30 by a direct recount of the recovered `todo.md` checklist table; the previous 9/24/27/5 figures summed to 67, not the table's actual 62 rows). The two CONFLICTs keep their **code** values: Eq. 15.13 `N_en^1.023` (extract says 1.078), Eq. 15.3 `cos(Λ_vt)^−0.323` (extract says −1.0). Do not change a value to make the guard green | `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` — deliberately red; todo §3a |
| `K_d = 0` silently zeroes the 227.54 lbf air-induction term (`0^0.182 = 0`) — no error, no warning, not even NaN; `OEW` would read 15477.79. **Left unguarded by decision**, and no guard test was added (that would be a false green). Corollary: if `K_d = 0` is legal, `K_d` cannot be Raymer's multiplicative base, so the exponent/placement is itself suspect | todo §P4-11 — visible only as a sensitivity row in the comparison report |
| The `0.95` in `W_l = 0.95·W_TO` has **no citation**. Brandt's implied ratio is 20680.70/31377 = 0.6591, but the two are definitionally different quantities | todo §P4-16 |
| The 6.7 lb/gal fuel density behind `V_t` = 940 is cited **nowhere** in `sizing/`. `V_t` stays a JSON input precisely so the uncited constant never enters an equation | todo §P4-5b |
| `L_d` and `D_e` have cited geometry analogs deliberately **not** wired. Sensitivities on `OEW`: `L_d` +201.47, `D_e` +24.94 | todo §P4-4 |
| `design_mach` 2.0 (Brandt) vs the T.O. operating limit 2.05 | todo §P4-13 |
| `L_t`, `S_cs`, `S_csw`, `S_r`, `H_t`, `H_v` reach this class by DI but remain `[estimate]` inputs on the geometry side | todo GeomL3 §6 |
