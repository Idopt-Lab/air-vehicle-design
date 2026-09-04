# WeightsL3

Level-3 weights static toolbox (`classdef WeightsL3`, `methods (Static)` only). Called as
`WeightsL3.method(...)`; never instantiated. `F16WeightsL3` inherits `WeightsModelL3` and delegates
here.

**L3 is the [Raymer 6th ed. Sec. 15.3.1] fighter/attack component buildup** — Eqs. 15.1–15.24, one
equation per component, plus three [Table 15.3] miscellaneous items.

Every static takes explicit scalars. None takes a design object, so a design class is free to name
its own properties however it likes.

---

## 1. Statics

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_landing_weight` | `W_TO` | `W_l` [lbf] | none — the `0.95` is uncited |
| `compute_wing_weight` | `W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_LE_deg, S_csw, K_dw, K_vs` | `W` [lbf] | Eq. 15.1 |
| `compute_horizontal_tail_weight` | `W_dg, N_z, S_ht, F_w, B_h` | `W` [lbf] | Eq. 15.2 |
| `compute_vertical_tail_weight` | `W_dg, N_z, S_vt, K_rht, H_t, H_v, M, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt_deg` | `W` [lbf] | Eq. 15.3 |
| `compute_fuselage_weight` | `W_dg, N_z, L_fus, D_fus, W_fus, K_dwf` | `W` [lbf] | Eq. 15.4 |
| `compute_main_gear_weight` | `W_l, N_l, L_m, K_cb, K_tpg` | `W` [lbf] | Eq. 15.5 |
| `compute_nose_gear_weight` | `W_l, N_l, L_n, N_nw` | `W` [lbf] | Eq. 15.6 |
| `compute_engine_mounts_weight` | `N_en, T, N_z` | `W` [lbf] | Eq. 15.7 |
| `compute_firewall_weight` | `S_fw` | `W` [lbf] | Eq. 15.8 |
| `compute_engine_section_weight` | `W_en, N_en, N_z` | `W` [lbf] | Eq. 15.9 |
| `compute_air_induction_weight` | `K_vg, L_d, K_d, N_en, L_s, D_e` | `W` [lbf] | Eq. 15.10 |
| `compute_tailpipe_weight` | `D_e, L_tp, N_en` | `W` [lbf] | Eq. 15.11 |
| `compute_engine_cooling_weight` | `D_e, L_sh, N_en` | `W` [lbf] | Eq. 15.12 |
| `compute_oil_cooling_weight` | `N_en` | `W` [lbf] | Eq. 15.13 |
| `compute_engine_controls_weight` | `N_en, L_ec` | `W` [lbf] | Eq. 15.14 |
| `compute_starter_weight` | `T, N_en` | `W` [lbf] | Eq. 15.15 |
| `compute_fuel_system_weight` | `V_t, V_i, V_p, N_t, N_en, T, SFC` | `W` [lbf] | Eq. 15.16 |
| `compute_flight_controls_weight` | `M, S_cs, N_s, N_c` | `W` [lbf] | Eq. 15.17 |
| `compute_instruments_weight` | `N_en, N_t, N_ci` | `W` [lbf] | Eq. 15.18 |
| `compute_hydraulics_weight` | `K_vsh, N_u` | `W` [lbf] | Eq. 15.19 |
| `compute_electrical_weight` | `K_mc, R_kva, N_c, L_a, N_gen` | `W` [lbf] | Eq. 15.20 |
| `compute_avionics_weight` | `W_uav` | `W` [lbf] | Eq. 15.21 |
| `compute_furnishings_weight` | `N_c` | `W` [lbf] | Eq. 15.22 |
| `compute_ac_antiice_weight` | `W_uav, N_c` | `W` [lbf] | Eq. 15.23 |
| `compute_handling_gear_weight` | `W_TO` | `W` [lbf] | Eq. 15.24 |
| `compute_arresting_gear_weight` | `W_dg, isNavy` (default `false`) | `W` [lbf] | Table 15.3, p. 571 |
| `compute_pylon_and_launcher_weight` | `W_missile` | `W` [lbf] | Table 15.3, p. 571 |

Every citation above is Raymer 6th ed. except the dry engine, which is 7th ed. Eq. 10.10 and lives
in `PropL2`, not here.

## 2. Units

Raymer's nomenclature, English throughout. Weights and thrust in lbf, areas in ft², lengths in ft —
**except `L_m` and `L_n`, which enter Eqs. 15.5/15.6 in inches**; the caller converts. Volumes in
gallons, SFC in 1/hr, `R_kva` in kVA.

## 3. Equations with a trap attached

**Fuselage** [Eq. 15.4]:

$$W_{fus} = 0.499\,K_{dwf}\,W_{dg}^{0.35}\,N_z^{0.25}\,L_{fus}^{0.5}\,
  D_{fus}^{0.849}\,W_{fus,width}^{0.685}$$

`D_fus` here is the **structural depth**, not a geometry object's equivalent diameter. The exponent
is 0.849, so substituting 6.0 for 5.0 ft inflates this component by +17.9 %.

**Landing gear** [Eqs. 15.5, 15.6] take the design landing weight `W_l`, not `W_TO`.
`compute_landing_weight` gives the `0.95·W_TO` seed; Raymer 6th ed. p. 579 defines `W_l` as the
landing design gross weight, which a mission analysis supplies directly.

**Wing** [Eq. 15.1] ends in `S_csw^0.04` — a bare control-surface **area**, not a ratio. `S_csw = 0`
therefore zeroes the whole equation. Any surface with no control surface needs a caller decision.

**Air induction** [Eq. 15.10] carries `K_d^0.182`, and `K_d = 0` is the legitimate straight-duct
value, so a legal input silently zeroes the term. Left unguarded by decision.

**Miscellaneous** [Table 15.3, p. 571]: arresting gear is `0.002·W_dg` Air Force type and
`0.008·W_dg` Navy type; pylon and launcher is `0.12·W_missile`, printed inside the table's Missiles
block alongside Harpoon 1200 / Phoenix 1000 / Sparrow 500 / Sidewinder 200 lb.

## 4. Load factor and the tier's basis

`N_z` = 13.5 (= 1.5 × 9 g limit, ultimate) is the Sec. 15.3.1 basis. Brandt's psf model uses
`n_ult` = 9. Two different models — do not conflate.

`K_rht` is applied to **Eq. 15.3 (VT)**, not 15.2, exactly as the book defines it, even though the
flag describes the horizontal tail.

Sec. 15.3.1 has **no strake equation** and **no engine equation**. A design that carries a strake
must choose an existing equation and say so at the call site.

## 5. To-dos

| Item | Guard |
|---|---|
| **Every exponent and coefficient is unverified against the printed book** — 62 rows, tallied 2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY / 5 clean. The two CONFLICTs keep their code values: Eq. 15.13 `N_en^1.023` (extract says 1.078) and Eq. 15.3 `cos(Λ_vt)^−0.323` (extract says −1.0). **Do not change a value to make the guard green** | `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` — deliberately red, keyed off a literal sentence in `WeightsL3.m`'s header; checklist in `todo.md` §3a |
| `K_d = 0` is a legal straight-duct value that silently zeroes the whole air-induction term (`0^0.182 = 0`) — no error, no warning, not even NaN. Left **unguarded by decision**. Corollary: if `K_d = 0` is legal then `K_d` cannot be Raymer's multiplicative base, so the exponent and placement are themselves suspect | todo.md Phase 4 §P4-11 |
| The `0.95` in `compute_landing_weight` has **no citation** in this repo. It is now only a seed: the sizing loop reports the real landing-segment weight | todo.md Phase 4 §P4-16 |
| Sec. 15.3.2 and 15.3.3 (transport and general-aviation buildups) are not implemented | `WeightsL3.m` header TODO (9/4/2026) |
| `compute_landing_weight` is not a component weight and sits in the low-level block for want of a better home | `WeightsL3.m` TODO (9/4/2026) |
