# F16WeightsL3

F-16A Block 10 Level-3 weight concrete class (`classdef F16WeightsL3 < WeightsModelL3`). Implements
the **Raymer §15.3.1 Fighter/Attack statistical component build-up (Eqs. 15.1–15.24)**. Every
abstract method is a single delegation line into the `WeightsL3` static toolbox. See the edition-
label caveat in `F16WeightsL1.md` (code cites Raymer 6th ed.; plan/CLAUDE.md say 7th ed. — unresolved).

> **★ HARD-STOP DEPENDENCY:** many §15.3.1 exponents in `WeightsL3.m` are OCR-`[verify]`, cited "from
> existing code", conflicting with the repo extract, or not present in the extract at all. The
> complete numbered checklist is in `VnV/BrandtF16A/todo.md` (2026-07-24 Weights §3a). The user must
> supply verified Raymer references for every listed exponent **before** any Step-2c code/JSON work.
> Do not treat the citations in this doc as verified — they are the as-built in-code citations.

## Constructor / input mechanism (NOT migrated)
`F16WeightsL3()` — **no-arg, empty-body constructor** (all ~60 spec values are hardcoded property
defaults; no `.weights` JSON, no `f16a_spec_path`). Not on the required-JSON-path + inputs-vs-
`Dependent` pattern. Migration + the inputs-vs-Dependent split (raw inputs plain; component/group
weights + OEW as live Dependent getters) is Step 2c.

## Property classification (input vs derived)
No `properties (Dependent)` block. The abstract-declared "computed component totals" (`W_wings`,
`W_tail`, `W_fuselage`, `W_installed_engine`, `W_subsystems`) are plain properties left at **NaN**
and never populated live — `OEW`/`weight_*` recompute locally and discard, so they are **vestigial
placeholders**, not live-derived outputs (same anti-pattern as L2). Every other property is a genuine
input. Under the target design, each component/group weight + OEW becomes a `get.<name>` recomputing
from the raw inputs on read.

**Sizing-loop / payload inputs** (`WeightsBase` contract):
| Property | Value | Units | Citation |
|---|---|---|---|
| `W_TO` | `NaN` | lbf | state variable, set by sizing loop |
| `W_energy` | 6296.3 | lbf | [Brandt Wt!B6] |
| `W_payload_expendable` | 0 | lbf | set by mission profile |
| `W_payload_fixed` | 220 | lbf | [estimate — not pinned] |

**Vestigial NaN placeholders** (abstract "computed totals" — never populated live): `W_wings`,
`W_tail`, `W_fuselage`, `W_installed_engine`, `W_subsystems`.

**Structural-group inputs** (Eqs. 15.1–15.4): `N_z`=13.5 (=1.5×9g ult. load factor) [TO §5; note
Brandt/Main!Q27 stores n_ult=9], `S_w`=196.23, `AR_w`=3.0, `tc_root`=0.04, `lambda_w`=0.2275,
`Lambda_LE_w`=40°, `S_csw`=68.03, `K_dw`=1.0, `K_vs`=1.0 (wing); `S_ht`=49.85, `AR_ht`=2.114,
`lambda_ht`=0.390, `F_w`=7.0 [estimate: reuses max fus width as proxy], `B_h`=18.5 (18 ft 6 in)
[USAF 3-view], `K_rht`=1.047 (all-moving tail) (HT); `S_vt`=40.89, `AR_vt`=1.294, `lambda_vt`=0.437,
`Lambda_LE_vt`=47.5°, `H_t`=0, `H_v`=1 (→H_t/H_v=0), `M_design`=2.0, `L_t`=22.0 [estimate], `S_r`=11.65,
`K_dwf`=1.0 (VT); `L_fus`=47.5, `D_fus`=5.0 [estimate], `W_fus`=7.0 (fuselage). Exposed areas cite
Brandt Geom "Exposed S"; several dims marked `[estimate; verify TO 1F-16A-1]`.

**Landing-gear inputs** (Eqs. 15.5–15.6): `W_l`=20681 [Brandt Wt!B41], `N_l`=2.67 [standard military;
verify], `L_m`=5.5 ft, `L_n`=3.5 ft [estimates — converted to inches in `weight_landing_gear`],
`K_cb`=1.0, `K_tpg`=1.0, `N_nw`=1.

**Engine-section inputs** (dry engine + Eqs. 15.7–15.15): `N_en`=1, `T_max`=23770 [Brandt D29],
`W_en`=3030 [estimate], `S_fw`=0 (no piston firewall), `D_e`=3.33 [estimate], `L_tp`=4.5, `L_sh`=8.0,
`L_ec`=5.0, `K_vg`=1.0, `L_d`=7.5, `K_d`=1.0, `L_s`=3.0 (mostly `[estimate]`).

**Systems inputs** (Eqs. 15.16–15.24): `V_t`=940 [derived 6296/6.7], `V_i`=500, `V_p`=0, `N_t`=3,
`SFC_mission`=0.70 [Brandt C30], `S_cs`=190, `N_s`=4, `N_c`=1, `N_ci`=3, `K_vsh`=1.0, `N_u`=5,
`K_mc`=1.0, `R_kva`=80, `L_a`=10.0, `N_gen`=1, `W_uav`=1500 (mostly `[estimate]`).

## Methods (delegate to `WeightsL3` → low-level statics)
`OEW` = Σ(wing + HT + VT + fuselage + LG.main + LG.nose + engine-group.total + systems-group.total).

| Method | Low-level static | Eq. | WeightsL3.m line | Citation (as-built) |
|---|---|---|---|---|
| `weight_wing` | `WeightsL3.wing` | 15.1 | :156–175 | [Raymer 6th ed. Eq. 15.1] — **exponents unverified, see §3a** |
| `weight_tail`.HT | `WeightsL3.horizontal_tail` | 15.2 | :177–186 | [Raymer 6th ed. Eq. 15.2] |
| `weight_tail`.VT | `WeightsL3.vertical_tail` | 15.3 | :188–210 | [Raymer 6th ed. Eq. 15.3] — **cos(Λ_vt) exp code −0.323 vs extract −1.0, see §3a** |
| `weight_fuselage` | `WeightsL3.fuselage` | 15.4 | :212–224 | [Raymer 6th ed. Eq. 15.4] |
| `weight_landing_gear`.main | `WeightsL3.main_gear` | 15.5 | :226–236 | [Raymer 6th ed. Eq. 15.5] — L_m in **inches** (obj.L_m·12) |
| `weight_landing_gear`.nose | `WeightsL3.nose_gear` | 15.6 | :238–247 | [Raymer 6th ed. Eq. 15.6] — L_n in **inches** (obj.L_n·12) |
| `weight_engine_section`.engine | vendor data (obj.W_en·N_en) | — | :117 | **not a §15.3.1 eq** — dry engine is vendor/spec data |
| `weight_engine_section`.mounts | `WeightsL3.engine_mounts` | 15.7 | :249–255 | [Raymer 6th ed. Eq. 15.7] |
| `weight_engine_section`.firewall | `WeightsL3.firewall` | 15.8 | :257–262 | [Raymer 6th ed. Eq. 15.8] — **VERIFIED clean in extract** (S_fw=0 for jet) |
| `weight_engine_section`.section | `WeightsL3.engine_section` | 15.9 | :264–270 | [Raymer 6th ed. Eq. 15.9] |
| `weight_engine_section`.induction | `WeightsL3.air_induction` | 15.10 | :272–281 | [Raymer 6th ed. Eq. 15.10] — **−0.373 / 1.498 "from existing code", see §3a** |
| `weight_engine_section`.tailpipe | `WeightsL3.tailpipe` | 15.11 | :283–287 | [Raymer 6th ed. Eq. 15.11] — **VERIFIED clean in extract** |
| `weight_engine_section`.cooling | `WeightsL3.engine_cooling` | 15.12 | :289–293 | [Raymer 6th ed. Eq. 15.12] — **VERIFIED clean in extract** |
| `weight_engine_section`.oil | `WeightsL3.oil_cooling` | 15.13 | :295–299 | [Raymer 6th ed. Eq. 15.13] — **code N_en^1.023 CONFLICTS with extract 1.078, see §3a** |
| `weight_engine_section`.controls | `WeightsL3.engine_controls` | 15.14 | :305–309 | [Raymer 6th ed. Eq. 15.14] — **exponents not in extract, see §3a** |
| `weight_engine_section`.starter | `WeightsL3.starter` | 15.15 | :311–316 | [Raymer 6th ed. Eq. 15.15] |
| `weight_systems`.fuel_sys | `WeightsL3.fuel_system` | 15.16 | :318–332 | [Raymer 6th ed. Eq. 15.16] |
| `weight_systems`.flight_ctrl | `WeightsL3.flight_controls` | 15.17 | :334–341 | [Raymer 6th ed. Eq. 15.17] — **N_c^0.127 "from existing code", see §3a** |
| `weight_systems`.instruments | `WeightsL3.instruments` | 15.18 | :343–349 | [Raymer 6th ed. Eq. 15.18] |
| `weight_systems`.hydraulics | `WeightsL3.hydraulics` | 15.19 | :351–357 | [Raymer 6th ed. Eq. 15.19] |
| `weight_systems`.electrical | `WeightsL3.electrical` | 15.20 | :359–366 | [Raymer 6th ed. Eq. 15.20] |
| `weight_systems`.avionics | `WeightsL3.avionics` | 15.21 | :368–373 | [Raymer 6th ed. Eq. 15.21] |
| `weight_systems`.furnishings | `WeightsL3.furnishings` | 15.22 | :375–379 | [Raymer 6th ed. Eq. 15.22] — **VERIFIED clean in extract** |
| `weight_systems`.ac_antiice | `WeightsL3.ac_antiice` | 15.23 | :381–386 | [Raymer 6th ed. Eq. 15.23] |
| `weight_systems`.handling | `WeightsL3.handling_gear` | 15.24 | :388–392 | [Raymer 6th ed. Eq. 15.24] — **VERIFIED clean in extract** |

All outputs in lbf. Units per equation: `W_dg`,`T`,`W_l`[lbf]; `S_*`[ft²]; `L_fus`,`D_fus`,`W_fus`,`D_e`,
`L_*`[ft]; `L_m`,`L_n`[**inches** at the equation, converted from ft in `weight_landing_gear`]; `V_*`[gal];
`SFC`[1/hr]; `M` dimensionless.

## Deviations / limitations / TODOs
- **★ Unverified §15.3.1 exponents (HARD STOP).** Full enumeration in `VnV/BrandtF16A/todo.md`
  2026-07-24 §3a. Summary of categories: **CONFLICT** (Eq. 15.13 oil-cooling code 1.023 vs extract
  1.078; Eq. 15.3 cos(Λ_vt) code −0.323 vs extract −1.0); **not-in-extract / "from existing code"**
  (Eq. 15.10 N_en^1.498 & (L_s/L_d)^−0.373 & D_e exponent; Eq. 15.14 N_en^1.008 & L_ec^0.222; Eq.
  15.17 N_c^0.127; Eq. 15.5 L_m^0.973; Eq. 15.6 N_nw^0.525); **extract-[verify] (OCR-suspect)** (Eqs.
  15.9, 15.15, 15.16, 15.18, 15.19, 15.20, 15.21, 15.23 exponents); **claimed-verified against an
  out-of-repo p.572 image but extract still [verify]** (Eqs. 15.1–15.7). VERIFIED-clean (no action):
  15.8, 15.11, 15.12, 15.22, 15.24.
- **Eq. 15.1 wing — two extra uncertainties beyond the [verify] tag.** (a) `tc_root^(−0.4)`: the
  low-level comment (`WeightsL3.m:160-164`) states the superscript "is not legible in the printed
  page's line-wrap" — −0.4 used per "widely-corroborated published form" + temp_Casey, not read off
  the page. (b) Sweep station: code uses **leading-edge** sweep `cos(Λ_LE)`; comment (`:60-61`,
  `:165-166`) flags that "some editions use quarter-chord sweep — verify." Both in §3a.
- **In-code contradiction on 15.1/15.4.** High-level `weight_wing` (`:59`) and `weight_fuselage`
  (`:81`) comments say "⚠ Exponents [verify from Raymer 6th ed. p.602]", while the low-level `wing`
  (`:160`) and `fuselage` (`:215`) comments say "all exponents confirmed." Same equations, opposite
  claims. Logged in §3a.
- **Page-citation inconsistency (book vs PDF page).** Header (`WeightsL3.m:17`) cites **p.572**; every
  method comment cites **p.602**. raymer_data.md maps §15.3.1 to book pp.572–573 = PDF pp.602–603
  (PDF = book + 30), so both refer to the same equations — but the file should use one consistent
  scheme. Logged in todo §3c.
- **`N_z` = 13.5 (=1.5×9) here vs Brandt/Main!Q27 n_ult = 9.** Raymer §15.3.1 `N_z` is the ultimate
  (1.5×limit) load factor, so 13.5 is dimensionally consistent with Raymer; Brandt's Wt tab uses
  n_ult=9 in its own (different) psf model. Not an error — noted so the two aren't conflated.
- **`WEIGHTSMODELG3` typo** in the property-block banner comment (`F16WeightsL3.m:33`, "WEIGHTSMODELG3
  ABSTRACT PROPERTIES") — should be `WEIGHTSMODELL3` (G→L). Cosmetic; flagged in todo §3c.
- **Many inputs are unpinned `[estimate]`s** (F_w, L_t, D_fus, W_en, D_e, L_tp, L_sh, L_ec, L_d, L_s,
  N_l, L_m, L_n, V_i, V_p, N_t, S_cs, N_s, N_ci, N_u, R_kva, L_a, W_uav, W_payload_fixed). These are
  spec-data estimates, not equation-citation issues, but the io/implementation step should pin or
  cite each. Not part of the §3a exponent hard-stop list.
- **Tests are sanity-bounds only, ±40% on OEW.** `TestWeightsL3.m` uses wide bounds precisely because
  the exponents/inputs are unverified; tightening is blocked on the §3a hard stop.

## Validation targets (informational)
Brandt component ground truth and OEW = **19,980.70 [Brandt Wt!B12]** are the comparison Expected;
**19,148.08 [corrections.xls Wt!B12]** is the other-source column. Component-by-component GT and the
framework→Brandt group mapping are in `docs/weights_parameter_usage.md` Part B. The unit test
currently keeps 19,148 mis-cited as "Brandt Wt!B12" — provenance decision in `VnV/BrandtF16A/todo.md`
2026-07-24 §3b.
