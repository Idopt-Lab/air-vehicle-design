# F16GeomL3

F-16A Block 10/15 Level-3 geometry — the **physical / T.O. 1F-16A-1 tier**. `classdef F16GeomL3 <
GeometryModelL3`; consumed by L3 geometry, aerodynamics **and** weights.

Where a physical or T.O. value differs from Brandt's, L3 uses the physical one. Those L2↔L3
divergences are **intentional fidelity differences, not errors** (§4). Every planform and wetted-area
equation is a reused `GeometryBase`/`GeomL2` static; the only formulas originating in `GeomL3` are
the area-ruling block (`denormalize_frames`, `compute_frame_cs_area`, `compute_surface_cs_area`,
`compute_nacelle_cs_area`, `compute_Amax_area_ruled`), `compute_c_root_exposed` and
`compute_engine_length`.

**There is no L3 propulsion tier** — `F16PropL2` serves the L3 rung and must be labelled as such
wherever an L3 propulsion number is reported.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));
g3   = F16GeomL3(f16a_spec_path(3), prop);
```

`F16GeomL3(json_path, prop, req_path)` — every argument required, no silent default. `req_path` was
added 2026-08-19 and supplies `M_max` from `.design_mach`. `json_path` supplies the
`.geometry` block of `f16a_L3.json`; only `prop.T_SL` is read, and only to size the nacelle.

---

## 2. Inputs

**38 numeric + the 20×3 normalized frame table (60 numbers) + 1 injected object.** Plain mutable
`properties`, set once by the constructor.

| Group | Properties | Notes |
|---|---|---|
| Wing | `S_ref` 300, `AR_wing` 3.0, `lambda_wing` 0.2275, `LE_sweep_wing` 40°, `tc_wing` 0.04, `S_csw`, `x_apex_wing` 17.786 ft | `S_csw` is an `[estimate]`; `x_apex_wing` `[Brandt Main!B23]` |
| HT | `S_ht` 108 (**full**), `B_h` 18.5 ft (**primary**), `lambda_ht` 0.2275, `LE_sweep_ht` 40°, `tc_r_ht` 0.060 / `tc_t_ht` 0.035, `F_w`, `AR_exposed_ht` 2.114, `lambda_exposed_ht` 0.39, `x_le_ht` 36.0 ft | **`AR_ht` is NOT an input** — it is derived from the `S_ht` + `B_h` pair |
| VT | `S_vt` 60 (**full**), `AR_vt` 1.6, `lambda_vt` 0.5, `LE_sweep_vt` **47.5°**, `tc_r_vt` 0.053 / `tc_t_vt` 0.030, `S_r`, `H_t`, `H_v`, `AR_exposed_vt` 1.294, `lambda_exposed_vt` 0.437, `x_le_vt` 36.0 ft | LE sweep is the T.O. value, not Brandt's 40° |
| Fuselage | `L_fus` **47.5 ft**, `W_max_fuselage` 7.0, `H_max_fuselage` 5.0, `frames_normalized` (20×3) | frames are `[Brandt Main!A34:F53]` ÷ his own envelope (46.5 / 7.0 / 5.0) |
| Whole aircraft | `L_aircraft` 47.65 ft, `L_t` 22.0 | `L_t` is an `[estimate]`, still not derivable |
| Duct / engine | `L_duct` 14.0, `x_inlet` **15.0 ft**, `n_engines` 1 | `x_inlet` is `[Main!F31]`, **not** 14.0 — that is the duct length |
| Control surfaces | `S_cs` 190 | `[estimate]` |
| Injected | `prop` | not numeric spec data |

The exposed-planform members carry an explicit `_exposed_` infix so that `AR_ht` / `lambda_ht` /
`S_ht` / `S_vt` mean **full planform at both tiers**. An earlier revision had the same names meaning
different things on the two tiers, which silently fed exposed values into full-planform equations.

Frames are stored **normalized** so `Amax` responds to the fuselage envelope. Stored raw, `Amax`
responded to `W_max_fuselage` with the *wrong sign* and to `H_max_fuselage` not at all.

## 3. Derived (`Dependent`) — 45

| Group | Properties |
|---|---|
| Wing | `b_wing`, `c_root_wing`, `c_tip_wing`, `cbar_wing`, `QC_sweep_wing`, `TE_sweep_wing`, `tc_r_wing`, `tc_t_wing`, `S_exposed_wing`, `S_wet_wing` |
| HT | **`AR_ht`**, `b_ht`, `c_root_ht`, `c_tip_ht`, `QC_sweep_ht`, `TE_sweep_ht`, `tc_ht`, `S_exposed_ht`, `S_wet_ht` |
| VT | `b_vt`, `c_root_vt`, `c_tip_vt`, `QC_sweep_vt`, `TE_sweep_vt`, `tc_vt`, `S_exposed_vt`, `S_wet_vt` |
| Fuselage | `L_fuselage`, `D_fus`, `Amax` |
| Duct / engine | `T_AB_SLS_lb`, `D_inlet`, `D_exit`, `L_engine`, `x_nacelle_aft` |
| Area-rule intermediates | `c_exp_root_{wing,ht,vt}`, `G_hs_exp_{wing,ht,vt}`, `Xexp_{wing,ht,vt}` |
| Total | `S_wet` |

**The whole HT planform derives from the `S_ht` + `B_h` input pair.** `AR_ht` = `B_h²/S_ht` =
3.1689815 is derived and must never be stored at L3. VT sweeps use `convert_sweep_panel` (2/AR), the
single-panel form; wing and HT use the mirrored `convert_sweep` (4/AR).

Lifting-surface `S_wet` uses Roskam Vol. II Eq. 12.1 fed the T.O. root/tip t/c splits — the same
official formula as L2. Brandt's uniform-t/c form is kept only as a comparison-report alternate row.

---

## 4. As-built values, and the by-design divergences

`BY DESIGN` = intentional L2↔L3 fidelity divergence. `definitional` = a different quantity, not an
agreement check.

| Quantity | L2 | L3 | Brandt | |
|---|---|---|---|---|
| `S_exposed_wing` | 196.22607 | 196.22607 | `Geom!H7` 196.22607 | agreement |
| `S_exposed_ht` | 49.847251 | **51.148643** | `Geom!H8` 49.84725 | **BY DESIGN** (+2.61 %) |
| `S_exposed_vt` | 40.889669 | 40.889669 | `Geom!H10` 40.88967 | agreement — cannot diverge (the exposed-area formula has no sweep term), a genuine positive control |
| HT span | `b_ht` 18.0 derived | **`B_h` 18.5 input** | 18.0 | **BY DESIGN** (+2.78 %) |
| `AR_ht` | 3.0 input | **3.1689815 derived** | `Main!C19` 3.0 | **BY DESIGN** (+5.63 %) |
| `c_root_ht` / `c_tip_ht` | 9.7759674 / 2.2240326 | **9.5117521 / 2.1639236** | — | **BY DESIGN** |
| `QC_sweep_ht` / `TE_sweep_ht` | 32.183178 / −0.00024285 | **32.639955 / 2.5616932** | `Main!C27` TE ≈ 0 | **BY DESIGN** — the derived AR aft-sweeps the L3 trailing edge |
| `LE_sweep_vt` | 40° | **47.5°** | `Main!H21` 40 | **BY DESIGN** (T.O. value) |
| `QC_sweep_vt` / `TE_sweep_vt` | 36.313393 / 22.900799 | **44.629262 / 34.00525** | `Main!H27` TE = 0 literal | **BY DESIGN** |
| `S_wet_ht` | 101.38789 | **104.03488** | `Geom!B16` 99.58484 | **BY DESIGN** |
| `S_wet_wing` / `S_wet_vt` | 396.37666 / 83.139828 | same | `Geom!B14`/`B17` 392.02044 / 81.68938 | definitional (formula family) |
| `L_fus` | 46.5 | **47.5** | `Main!B32` 46.5 | **BY DESIGN** (+2.15 %) |
| fuselage `S_wet` | 730.30232 | **749.13368** | `Geom!B3` 730.422 | **BY DESIGN** |
| duct `S_wet` | 155.56636 | 155.56636 | `Geom!B4` 41.515 (nacelle) | definitional |
| total `S_wet` | 1466.7731 | **1488.2514** | 1331.134 corrected | definitional — Brandt's total carries strake/nacelle terms with no framework analog |
| `D_inlet` / `L_engine` | 3.5370222 / — | 3.5370222 / 15.9166 | `Geom!C475`/`D475` | agreement (positive control on the propulsion DI) |
| **`Amax`** | **27.488936** (envelope ellipse) | **24.703652** (area-ruled) | `Geom!B20` 25.110556 | L2 definitional; L3 **BY DESIGN** (−1.62 %) |
| `L_aircraft` | 47.65 | 47.65 | `Geom!B21` 48.303947 | definitional — spec dimension vs a `MAX()` extent |

### `Amax` — the area-ruled buildup

L3 computes the **whole-aircraft** maximum cross-section that Raymer Eq. 12.44's Sears-Haack term
actually wants: the `MAX` over the 20 rescaled frame stations of
(fuselage + wing + HT + VT + nacelle sections) less `n_engines·π·D²/5`
`[Brandt Geom!H26:H45 → H47 → B20]`.

L2 keeps the fuselage-envelope ellipse `(π/4)·W·H`, which `readme_geom.md` §7 classifies as the
low-fidelity form. **Do not unify these** — using the envelope form at L3 is a fidelity inversion and
was a real bug: it substitutes a fuselage-only quantity for a whole-aircraft one and inflates
`CD0_wave` ~23 %.

**Round-trip control:** set `L_fus` back to 46.5 and L3 returns 25.110534, reproducing Brandt's
`Geom!B20` to −0.0001 %. This proves the method rather than fitting it, and it is why the −1.62 % gap
is attributable to the 47.5 ft fuselage rather than to the model. With the area-ruled value
`CD0_wave` sits −0.54 % from the Brandt-referenced term and **`E_WD` = 2.2 needs no retune**.

`Amax` is deliberately **non-linear** in `W_max_fuselage`: stepping 7 → 8 ft gives a ratio of
1.131077, not 8/7, because a wider fuselage grows every frame section *and* eats more exposed wing
root. `S_ht` / `B_h` / `S_vt` / `tc_ht` move it 0.000 % — a true geometric fact (the tail sections
start aft of the governing station), not a dead input.

---

## 5. Methods

`get_S_ref`, `get_S_wet`, `get_S_wet_wing`, `get_S_wet_HT`, `get_S_wet_VT`, `get_S_wet_fuselage`,
`get_S_wet_duct`, `get_S_exposed_wing` — one-line delegations into `GeomL3`.

---

## 6. To-dos

| Item | Status |
|---|---|
| `L_aircraft` = 47.65 ft is unsourced in-repo. The *value* is user-approved; the *provenance* is open. Brandt's 48.304 is an extent, not a comparable spec length | `TestGeomL3.testTODO_OverallLengthCitationNotPinned`; todo §6 |
| The L3 `Amax` affine frame-rescaling assumption and Brandt's cosine area-distribution model trace to no reference extract here. The one lead, Roskam Part VI, is not in this repo | todo §4b |
| The `/5` flow-through divisor is a bare literal with no justification anywhere in the workbook, while `readme_geom.md` §4.5 uses `π·D²/4` for the same nacelle. `/4` would give `Amax` = 22.738503 (−7.95 %) and make `Amax` thrust-insensitive | todo §5 |
| Frame-area discretization: Brandt's 6-point cosine sampling was taken (`I_cos` = 0.63137515 vs 2/π = 0.63661977, 0.824 % low). `compute_frame_cs_area_exact` is a one-line switch worth +0.759 % — **confirm or switch** | todo §20 |
| Mixed provenance of the full-planform tails: `S_ht` = 108 and `AR_vt`/`lambda_vt` are Brandt's, carried next to T.O. LE sweeps and a T.O./USAF `B_h`. Obtain T.O. full-planform values | todo §3 |
| `n_engines` sits in `.geometry` only because nothing on the propulsion side exposes an engine count — should migrate to `.propulsion` + DI, as `T_AB_SLS_lb` did | todo §22 |
| Strake deferred: two comparison rows stay "NOT MODELED" (`S_wet` 39.956 `[Geom!B15]`, exposed area 20.0 `[Geom!H9]`). Cost is 7 new inputs plus a "root fully outside the fuselage" special case | todo §23 |
| `L_t` 22.0, `S_cs` 190, `S_csw` 68.03, `S_r` 11.65, `H_t`, `H_v` remain `[estimate]` inputs. `L_t` is not derivable — the apex x-stations are inputs now, but the MAC y-station is not | todo GeomL3 §6 |
| Nacelle x-range and the `1900` magic number: the live chain is `[15.0, 44.9166]` while `readme_geom.md` §4.5 uses `[14.0, 43.9166]`. `compute_nacelle_diameter` hardcodes 1900, silently assuming an afterburning engine | todo §18 |
| The same fuselage depth is keyed `max_height_ft` at L2 but `max_depth_ft` at L3 — same value, same citation, a live trap for shared JSON-reading code | todo §15 |
| `readme_geom.md` §7's low-fidelity `Amax` row has no cell backing and says "cylindrical" (28.2743) where L2 computes the elliptical 27.4889 | todo §19 |
| The comparison report's `Divergence` column shipped as two-state (`BY DESIGN` / blank), so "definitional" cannot be expressed and both `Amax` rows read `BY DESIGN`. `geometry_brandt_comparison.m` also computes `L_aircraft_l2` and never uses it | — |
| Informational, no action: Brandt `Main!H27` VT TE sweep is a literal 0, inconsistent with his own VT planform — recorded so nobody reverts the 22.90° fix | todo §9 |
