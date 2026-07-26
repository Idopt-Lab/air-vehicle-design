# F16GeomL3

**STATUS: AS-BUILT (2026-07-25, after sub-step 2h).** `F16GeomL3.m`, `GeometryModelL3.m`,
`GeomL3.m`, `TestGeomL3.m` and the `f16a_L3.json` `.geometry` block are built, green and **wired**:
`F16GeomL3` is the **full L3 geometry tier**, consumed by L3 geometry and L3 aero today and by L3
weights in Phase 4. The Phase-2 promotion, the §B rename, the §C aero contract, the §F citation fix
and sub-step 2h's area-ruled `Amax` have all landed. Sections originally written as a
*specification* are marked `DONE` in place and kept as the decision record; **§D was rewritten
outright**, because sub-step 2h replaced the quantity it described.

Locked decisions this tier encodes (user, 2026-07-25 — `~/.claude/plans/serene-conjuring-kitten.md` Phase 2):
1. GeomL3 is the **full** L3 geometry tier. Reverses CLAUDE.md's "2026-07-22 exception —
   Geometry has no L3" and the weights-only GeomL3 scope of `~/.claude/plans/jiggly-tickling-bonbon.md`.
2. **No L3 propulsion tier.** `F16PropL2` stays at the L3 rung and must be labelled as such wherever
   L3 is reported.
3. Full-planform HT/VT at L3 = **Brandt's** `S_ht=108` / `S_vt=60` / `AR_vt=1.6` /
   `taper=0.2275`/`0.5`, carried *alongside* the physical/T.O. LE sweeps (VT 47.5°) and the
   physical/USAF HT span. Mixed provenance — standing item in `VnV/BrandtF16A/todo.md`
   (2026-07-25 Phase 2 §3). NB HT `AR` is **not** carried — it is DERIVED (Decision 1, §A.4).
4. **`Amax` is computed in geometry, and the two tiers use different definitions on purpose.**
   L2 = the fuselage-envelope ellipse `(π/4)·W_max·H_max` = **27.488936** *(live)*; **L3 = Brandt's
   whole-aircraft AREA-RULED buildup** = **24.703652** *(live)* (sub-step 2h). See §D.
5. Overall aircraft length = `47.65 ft`, a direct `.geometry` INPUT at both L2 and L3.
6. HT/VT `tc_ratio` dropped; `tc_root`/`tc_tip` split is the single basis. **Wing untouched.**
7. Engine SLS thrust leaves `.geometry`; injected from the propulsion object.
   `F16GeomL3(json_path, prop)` — both arguments required — with `T_AB_SLS_lb` Dependent on
   `prop.T_SL`. `F16GeomL2(json_path, prop)` took the same change.

Inheritance (unchanged): `GeometryBase → GeometryModelL3 → F16GeomL3`, with the `GeomL3` static
toolbox alongside (not in the chain). Every wetted-area / planform equation is a **reused**
`GeometryBase`/`GeomL2` static; the only formulas that **originate** in `GeomL3` are sub-step 2h's
area-ruling block (`denormalize_frames`, `compute_frame_cs_area`(`_exact`),
`compute_surface_cs_area`, `compute_nacelle_cs_area`, `compute_Amax_area_ruled`) plus
`compute_c_root_exposed` and `compute_engine_length` (§D). `GeometryBase` gained two
fidelity-independent identities in Phase 2 — `compute_Amax_elliptical` (still **L2's** answer, no
longer L3's) and `compute_nacelle_diameter`.

All numbers in this doc marked *(live)* were computed via `mcp__matlab__evaluate_matlab_code`
against the **as-built** classes, and all Brandt cells read directly from
`VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` over Excel COM (`actxserver`, read-only, closed
without saving). Everything below re-verified 2026-07-25 after sub-step 2h.

---

## A. INPUT vs DERIVED classification (as built)

Pattern per CLAUDE.md → "Optimization-ready property design"; reference implementation
`examples/F16A/F16GeomL2.m` header. **Inputs** = a plain mutable `properties` block of genuine
design-variable spec data, set once by the constructor from `f16a_L3.json .geometry`. **Derived** =
`properties (Dependent)` with a `get.<name>` recomputing live on every read; no stored/cached copy,
so nothing can go stale when an optimizer mutates an input. Derived properties have no set-method —
assigning errors, which is correct: they are outputs.

**Counts, AS BUILT — recounted from `F16GeomL3.m`'s two property blocks, 2026-07-25:
38 numeric INPUTS + one 20×3 NORMALIZED frame table (60 numbers) + 1 injected object;
45 DERIVED.**

Cross-checked against the input JSON: decoding `f16a_L3.json` `.geometry` yields exactly **38
numeric scalars** (wing 7, horizontal tail 10, vertical tail 12, fuselage 3, `overall_length_ft` 1,
engine 3, `tail_arm_ft` 1, `total_control_surface_area_ft2` 1) plus the 20-row
`fuselage.frames_normalized` array. Every scalar maps 1:1 to an input property; nothing derived is
stored in the JSON.

The 45 derived split as: wing 10, HT 9, VT 8, fuselage/whole-aircraft 3, inlet/duct 5, area-rule
intermediates 9, total `S_wet` 1.

**Count history — kept because it is the decision trail.** As-was before Phase 2: 25 inputs /
7 derived. The Phase-2 spec targeted **33 inputs / 34 derived** (+9 inputs −1 for `AR_ht` moving to
DERIVED; +27 derived; 4 renames; 5 quantities INPUT→DERIVED per §A.3; 1 moving to the injected
`prop`). **Sub-step 2h then added six inputs (§A.1b) and eleven derived (§A.2b)**, giving
33 + 5 new *scalars* = **38 numeric scalars** — the sixth new input is the frame table, counted
separately — and 34 + 11 = **45 derived**.

> **§A.1's rows keep their original 1–34 numbering** so the decision trail stays readable. Row 8 is a
> `MOVED TO DERIVED` marker, not an input — so §A.1 lists 33 inputs across 34 numbered rows, and
> **§A.1b** carries the 5 remaining scalars + the frame table.

> **Known stale in-code banners (docs-only pass, not fixed here):** `F16GeomL3.m`'s property-block
> banner comments still read "33 numeric … spec values" (`:168`) and "34 quantities" (`:251`), while
> the same file's class header correctly says 38 and 45 (`:35-40`). The file disagrees with itself
> on the counts; only the header is right. Flagged for the coordinator — see §H item 14.

### A.1 INPUTS (34 numbered rows = 33 inputs) — mutable design-variable spec data

> **`ADD` / `RENAME` markers in §A.1 and §A.2 are HISTORICAL — every one has landed.** They are kept
> so the delta from the pre-Phase-2 class stays legible. Values in the "Value" columns are the
> as-built ones unless a row says otherwise.

| # | Input | Value | Citation | Why an input (not derivable) |
|---|---|---|---|---|
| **Wing** ||||
| 1 | `S_ref` | 300 ft² | `[Brandt Main!B18]` *(live: 300)* | Reference area; primary design variable |
| 2 | `AR_wing` | 3.0 | `[Brandt Main!B19]` *(live: 3)* | Primary design variable |
| 3 | `lambda_wing` | 0.2275 | `[Brandt Main!B20]` *(live: 0.2275 — **cell corrected**, see §F.1)* | Primary design variable |
| 4 | `LE_sweep_wing` | 40° | `[Brandt Main!B21]` *(live: 40 — **cell corrected**, see §F.1)* | Primary design variable |
| 5 | `tc_wing` | 0.04 | `[Brandt Main!B22 "NACA 4-digit" = 1404 → last two digits = 4 % t/c]` *(live: 1404 — **cell corrected**, see §F.2)*; corroborated `[T.O. 1F-16A-1 Fig. 1-2, NACA 64A204]` | Airfoil spec. Wing is genuinely uniform-tc — no root/tip split exists, so `tc_ratio` STAYS here (locked decision 6) |
| 6 | `S_csw` | 68.03 ft² | `[T.O. 1F-16A-1 Fig. 1-2: flaperon 31.32 + LEF 36.71]` | No control-surface geometry anywhere in `GeomL2`/`GeometryBase`. NB does not match `Brandt Main!F18` LE-flap S = 21.314 (todo 2026-07-21 Finding 5) |
| **Horizontal tail — FULL planform** ||||
| 7 | `S_ht` | 108 ft² | `[Brandt Main!C18]` *(live: 108)* | Reference area; design variable. **Meaning = FULL planform at both L2 and L3** (§A.3) |
| 8 | ~~`AR_ht`~~ | *(was 3.0)* | ~~`[Brandt Main!C19]`~~ | **MOVED TO DERIVED — Decision 1 (user, 2026-07-25).** `AR_ht` = `B_h²/S_ht` = **3.1690**. It must NOT remain a stored input: with `S_ht`=108 and `B_h`=18.5 both inputs, a stored `AR_ht`=3.0 would make the JSON self-contradictory. See §A.2 #11 and §A.4. `Brandt Main!C19` = 3 becomes a **comparison reference**, not an input |
| 9 | `lambda_ht` | 0.2275 | `[Brandt Main!C20]` *(live: 0.2275 — cell corrected)* | Design variable; FULL planform |
| 10 | `LE_sweep_ht` | 40° | `[Brandt Main!C21]` *(live: 40 — cell corrected)* | Design variable. **ADD** — absent today; L3 aero needs it (§B) |
| 11 | `tc_r_ht` | 0.060 | `[T.O. 1F-16A-1 Sec. I, biconvex root ≈6 %]` | Airfoil spec. **ADD**; replaces `tc_ht` (locked decision 6) |
| 12 | `tc_t_ht` | 0.035 | `[T.O. 1F-16A-1 Sec. I, biconvex tip ≈3.5 %]` | Airfoil spec. **ADD** |
| 13 | `AR_exposed_ht` | 2.114 | `[physical construction value; T.O./USAF — NOT reconcilable with Brandt exposed geometry, todo 2026-07-24 GeomL3 §1]` | Weights (Raymer Eq. 15.2) consumer input. Clean-derived value is 2.4274 *(live)*, +14.8 % away — carried as an input per the locked physical-tier decision |
| 14 | `lambda_exposed_ht` | 0.390 | same as #13 | Clean-derived 0.3252 *(live)*, −16.6 % away |
| 15 | `B_h` | 18.5 ft | `[USAF 3-view; 18 ft 6 in]` | Physical HT span — **PRIMARY** per Decision 1. With `S_ht`, it defines the whole HT planform: `AR_ht`, `b_ht`, chords, exposed area and MAC are all derived from the pair. Rationale: this is how a tail is measured off a 3-view — **area and span are measured, AR is definitional** — and it matches GeomL3's charter (physical value wins over Brandt) |
| 16 | `F_w` | 7.0 ft | `[Brandt Main!C32, max-width upper-bound proxy]` *(live: 7)* | Fuselage width at HT intersection; weights Eq. 15.2. `[estimate]` — real empennage width is narrower |
| **Vertical tail — FULL planform** ||||
| 17 | `S_vt` | 60 ft² | `[Brandt Main!H18]` *(live: 60)* | Reference area; design variable; FULL planform |
| 18 | `AR_vt` | 1.6 | `[Brandt Main!H19]` *(live: 1.6)* | Design variable; FULL planform (single panel) |
| 19 | `lambda_vt` | 0.5 | `[Brandt Main!H20]` *(live: 0.5 — cell corrected)* | Design variable; FULL planform |
| 20 | `LE_sweep_vt` | **47.5°** | `[T.O. 1F-16A-1]` | Physical value. **INTENTIONAL divergence** from `Brandt Main!H21` = 40 *(live)* — locked decision, todo 2026-07-24 GeomL3 §2 |
| 21 | `tc_r_vt` | 0.053 | `[T.O. 1F-16A-1 Sec. I, biconvex root ≈5.3 %]` | **ADD**; replaces `tc_vt` |
| 22 | `tc_t_vt` | 0.030 | `[T.O. 1F-16A-1 Sec. I, biconvex tip ≈3.0 %]` | **ADD** |
| 23 | `AR_exposed_vt` | 1.294 | `[physical; T.O./USAF]` | Weights Eq. 15.3. Clean-derived 1.3025 *(live)*, +0.7 % — the only one of the four that reconciles |
| 24 | `lambda_exposed_vt` | 0.437 | `[physical; T.O./USAF]` | Clean-derived 0.5731 *(live)*, +31.1 % away |
| 25 | `S_r` | 11.65 ft² | `[T.O. 1F-16A-1 Fig. 1-2]` | No rudder chord-fraction anywhere in the repo |
| 26 | `H_t` | 0 ft | `[Raymer 6th ed. §15.3 — F-16 conventional (non-T) tail]` | Config constant; `H_t/H_v = 0` |
| 27 | `H_v` | 1 ft | `[Raymer 6th ed. §15.3]` | Config constant; any nonzero denominator |
| **Fuselage** ||||
| 28 | `L_fus` | **47.5 ft** | `[T.O. 1F-16A-1]` | Physical. **INTENTIONAL divergence** from `Brandt Main!B32` = 46.5 *(live)* — todo 2026-07-24 GeomL3 §3 |
| 29 | `W_max_fuselage` | 7.0 ft | `[Brandt Main!C32]` *(live: 7)* | Envelope design variable |
| 30 | `H_max_fuselage` | 5.0 ft | `[Brandt Main!D32]` *(live: 5)*; `[T.O. 1F-16A-1 cross-section]` | Envelope design variable. This — **not** `D_fus` — is the Raymer Eq. 15.4 structural depth the weights DI reads (§A.3) |
| 31 | `L_aircraft` (`overall_length_ft`) | **47.65 ft** | `[published F-16A airframe length, 47 ft 7.75 in = 47.6458 ft — NOT sourced to any document in this repo; see §E and todo §6, still OPEN]` | Whole-aircraft length for wave drag. Not derivable: the geometry model has no nose/tailcone x-stations. **ADD at both L2 and L3** |
| **Inlet / duct** ||||
| 32 | `L_duct` | 14.0 ft | `[Brandt Main!F32, label Main!E32 = 'Compr Face'; readme_geom.md §3]` *(live: 14)* | Genuine airframe input (inlet lip → compressor face). **ADD** — L3 aero reads `L_duct` and `get_S_wet_duct()`; since 2h it also sets `x_nacelle_aft`. ★ Not to be confused with the mislabelled `inlet_x_ft` = 14.0 key in the read-only ground-truth JSON — same number, different quantity (§A.1b #38, todo §18) |
| — | `prop` (injected object) | `F16PropL2` | **BUILT** — `F16GeomL3(json_path, prop)`, both arguments required | Not numeric. Supplies `prop.T_SL` so `T_AB_SLS_lb` is DERIVED (§A.2 #31) — removes the third copy of 23,770 lbf and unpins duct wetted area (and, since 2h, `L_engine`/`x_nacelle_aft`/the `Amax` nacelle term) from a stale engine. At the L3 rung this is an `F16PropL2`: **no L3 propulsion tier exists** |
| **Configuration** ||||
| 33 | `L_t` | 22.0 ft | `[estimate; verify T.O. 1F-16A-1]` | Tail arm, wing ¼-MAC → HT ¼-MAC. **Still not derivable** even after 2h: the `Main` row-23 apex-x stations are now inputs (§A.1b #35–37), but the ¼-MAC station also needs the MAC *y*-station, which the model does not carry. Remains an unpinned estimate (todo 2026-07-24 GeomL3 §6) |
| 34 | `S_cs` | 190 ft² | `[estimate: flaperon + HT + rudder + LEF]` | Unpinned; no control-surface geometry in the repo |

### A.1b INPUTS added by sub-step 2h (5 scalars + 1 table) — the area-ruled `Amax`

Every one of these exists **only** because `Amax` became the whole-aircraft area-ruled buildup (§D).
`VnV/BrandtF16A/todo.md` 2026-07-25 Phase 2 §16.1 verified, item by item, that nothing else the
buildup needs is a new input — the exposed root chords, exposed spans, `Xexp` stations, `L_engine`
and the nacelle aft limit are all derivable and are therefore DERIVED (§A.2b), never stored.

| # | Input | Value | Citation | Why an input (not derivable) |
|---|---|---|---|---|
| 35 | `x_apex_wing` | 17.786 ft | `[Brandt Main!B23 'X Location']` *(live cell: 17.785833, formula `=(213.43)/12`)* | Wing root-LE x-station. Not derivable in-framework: Brandt pre-computes it as `x_MAC_qc − y_MAC·tan Λ_LE` (`readme_geom.md` §2) and no MAC x/y stations exist here. **PRECISION NOTE:** the scoped value 17.786 is 0.0011 % above the live cell; do not "correct" it without a decision |
| 36 | `x_le_ht` | 36.0 ft | `[Brandt Main!C23 'X Location']` *(live: 36)* | HT root-LE x-station; fixes `Xexp_ht` |
| 37 | `x_le_vt` | 36.0 ft | `[Brandt Main!H23 'X Location']` *(live: 36, formula `=C23`)* | VT root-LE x-station; fixes `Xexp_vt` |
| 38 | `x_inlet` | **15.0 ft** | `[Brandt Main!F31, label Main!E31 = 'Inlet(s):']` *(live: 15)* | Inlet-lip x-station. ★ **TRAP:** the read-only `GroundTruth/f16a_geometry.json` key `inlet_x_ft` = **14.0 is MISLABELLED** — 14.0 is `Main!F32`, the duct length (row 32 above). Do not "correct" this to 14.0. todo §18 |
| 39 | `n_engines` | 1 | `[Brandt Main!B28]` *(live: 1; confirmed inside the `Geom!H47` and `Geom!AE31` formulas)* | Needed by the `Amax` flow-through deduction. **Lives in `.geometry` only because no propulsion class exposes an engine count** — `F16PropL2` exposes `engine_type, T_SL, T_SL_wet, T_SL_mil, T_t4_max_F, TSFC_install_factor, TR` and no count. Should migrate to `.propulsion` + DI: todo 2026-07-25 Phase 2 §22 (new) |
| 40 | `frames_normalized` | 20×3 table (**60 numbers**) | `[Brandt Main!A34:F53; readme_geom.md §2]`, divided through by his own envelope (`L` 46.5 `Main!B32`, `W` 7.0 `Main!C32`, `H` 5.0 `Main!D32`) | The fuselage cross-sectional-area distribution. **Unavoidable as an input:** `A_fuse` supplies 52.7 % of the governing station's total in the round-trip case, and the only zero-new-input alternative (constant section from the 3 envelope scalars) makes `Amax` *worse* than the ellipse it replaces, +20 % to +41 % (todo §16.1 variants B/B′). Stored **NORMALIZED** (variant D) so `L_fus`/`W_max_fuselage`/`H_max_fuselage` rescale it. Columns `x_over_L`, `w_over_Wmax`, `h_over_Hmax`; Brandt's `z_chine`/`z_center` columns are dropped because they cancel **exactly** out of the area (`readme_geom.md` §4.2). ★ The affine-rescaling assumption is **UNCITED** — §D, todo §4 |

### A.2 DERIVED (45) — `properties (Dependent)`, recomputed live

| # | Derived | Formula / reused static | Value *(live)* | Citation |
|---|---|---|---|---|
| **Wing** |||||
| 1 | `b_wing` | `GeometryBase.compute_span(AR_wing, S_ref)` | 30.0000 ft | Definitional (AR ≡ b²/S) |
| 2 | `c_root_wing` | `GeometryBase.compute_root_chord(S_ref, b_wing, lambda_wing)` | 16.2933 ft | Raymer 7th ed. Eq. 7.6 |
| 3 | `c_tip_wing` | `GeometryBase.compute_tip_chord(c_root_wing, lambda_wing)` | 3.7067 ft | Raymer 7th ed. Eq. 7.7 |
| 4 | `cbar_wing` | `GeometryBase.compute_mac(c_root_wing, lambda_wing)` | 11.3202 ft | Raymer 7th ed. Eq. 7.8. **ADD** (§B) |
| 5 | `QC_sweep_wing` | `GeometryBase.convert_sweep(…, 0.25)` | 32.1832° | Standard swept-wing planform identity (uncited edition — `GeometryBase.md`) . **ADD** (§B) |
| 6 | `TE_sweep_wing` | `GeometryBase.convert_sweep(…, 1.0)` | −0.0002° | same identity. Matches `Brandt Main!B27` = −0.00024343 *(live)* — an independent positive control |
| 7 | `tc_r_wing` | mirrors `tc_wing` | 0.04 | Wing uniform-tc; no split available |
| 8 | `tc_t_wing` | mirrors `tc_wing` | 0.04 | as #7. **ADD** (L3 aero's `tc_comp` uses `tc_wing` directly, but `GeometryModelL2` parity wants both) |
| 9 | `S_exposed_wing` | `GeomL2.compute_S_exposed_horizontal(c_root_wing, c_tip_wing, b_wing/2, W_max_fuselage/2)` | 196.2261 ft² | Brandt; readme_geom.md §4.3. Matches Brandt GT `Geom!7` exactly |
| 10 | `S_wet_wing` | Roskam Eq. 12.1 (official, §A.5) | **396.3767 ft²** (alternate, Brandt uniform-tc: 392.0205) | Roskam Vol. II Eq. 12.1 / `Brandt Geom!B13`. **ADD as a property** (only the method exists today) |
| **Horizontal tail** — all derived from the `S_ht` + `B_h` input pair (Decision 1) |||||
| 11 | **`AR_ht`** | `B_h² / S_ht` = 18.5²/108 | **3.1690** | Definitional (AR ≡ b²/S, `GeometryBase.compute_span`'s inverse). **INPUT → DERIVED** (Decision 1). Brandt `Main!C19` = 3.0 is now a comparison reference (+5.63 %) |
| 12 | `b_ht` | mirrors `B_h` | 18.5000 ft | Definitional. `sqrt(AR_ht·S_ht)` returns the identical value, so there is no circularity — the mirror is exact and cheaper |
| 13 | `c_root_ht` | `GeometryBase.compute_root_chord(S_ht, b_ht, lambda_ht)` | **9.5118 ft** | Raymer 7th ed. Eq. 7.6. **ADD** (§B). Option A would have given 9.7760 |
| 14 | `c_tip_ht` | `GeometryBase.compute_tip_chord(c_root_ht, lambda_ht)` | **2.1639 ft** | Raymer 7th ed. Eq. 7.7. **ADD**. Option A: 2.2240 |
| 15 | `QC_sweep_ht` | `GeometryBase.convert_sweep(LE_sweep_ht, AR_ht, lambda_ht, 0.25)` | **32.6400°** | standard identity. **ADD**. Option A / L2: 32.1832° |
| 16 | `TE_sweep_ht` | `GeometryBase.convert_sweep(…, 1.0)` | **2.5617°** | standard identity. **ADD**. Option A / L2 gave −0.0002°, matching `Brandt Main!C27` = −0.00024343 *(live)*; the higher derived AR makes the L3 HT trailing edge slightly aft-swept — a **BY DESIGN** consequence of Decision 1, report row §G.1 #29b |
| 17 | `tc_ht` | `(tc_r_ht + tc_t_ht)/2` | 0.0475 | Root/tip mean, needed only where a uniform t/c is required (locked decision 6). **INPUT → DERIVED** |
| 18 | `S_exposed_ht` | `GeomL2.compute_S_exposed_horizontal(c_root_ht, c_tip_ht, b_ht/2, W_max_fuselage/2)` | **51.1486 ft²** | Brandt; readme_geom.md §4.3. **stored INPUT 49.85 → DERIVED** (§A.4). **+2.605 % vs the stored value, +2.611 % vs Brandt GT `Geom!8` — INTENTIONAL divergence** |
| 19 | `S_wet_ht` | Roskam Eq. 12.1 (official, §A.5) | **104.0349 ft²** (alternate, Brandt uniform-tc: 102.3842) | Roskam Vol. II Eq. 12.1 / `Brandt Geom!B13`. **ADD as a property** |
| **Vertical tail** — unchanged from L2 except the LE sweep |||||
| 20 | `b_vt` | `sqrt(S_vt·AR_vt)` — full single-panel span, **not** halved | 9.7980 ft | readme_geom.md §4.3 |
| 21 | `c_root_vt` | `GeometryBase.compute_root_chord(S_vt, b_vt, lambda_vt)` | 8.1650 ft | Raymer 7th ed. Eq. 7.6. **ADD** (§B) |
| 22 | `c_tip_vt` | `GeometryBase.compute_tip_chord(c_root_vt, lambda_vt)` | 4.0825 ft | Raymer 7th ed. Eq. 7.7. **ADD** |
| 23 | `QC_sweep_vt` | `GeometryBase.convert_sweep_panel(47.5, 1.6, 0.5, 0.25)` — **SINGLE-PANEL 2/AR** | 44.6293° | standard identity, single-panel specialization. **ADD**. With the wrong mirrored `convert_sweep` it would read 41.4437° |
| 24 | `TE_sweep_vt` | `GeometryBase.convert_sweep_panel(…, 1.0)` | 34.0052° | as #23. Mirrored form would give 14.4655° |
| 25 | `tc_vt` | `(tc_r_vt + tc_t_vt)/2` | 0.0415 | root/tip mean. **INPUT → DERIVED** |
| 26 | `S_exposed_vt` | `GeomL2.compute_S_exposed_vertical(S_vt, AR_vt, c_root_vt, c_tip_vt, H_max_fuselage/2)` | 40.8897 ft² | Brandt; readme_geom.md §4.3. **stored INPUT 40.89 → DERIVED** (§A.4). Bit-identical to L2 and to Brandt GT `Geom!10` — no divergence is possible (§A.4) |
| 27 | `S_wet_vt` | Roskam Eq. 12.1 (official, §A.5) | **83.1399 ft²** (alternate, Brandt uniform-tc: 81.7213) | Roskam Vol. II Eq. 12.1 / `Brandt Geom!B13`. **ADD as a property** |
| **Fuselage** |||||
| 28 | `D_fus` | `(W_max_fuselage + H_max_fuselage)/2` | 6.0000 ft | Brandt low-fi `D_avg` convention fed to Roskam Eq. 12.3. **Equivalent diameter — NOT the weights depth** (§A.3) |
| 29 | `L_fuselage` | mirrors `L_fus` | 47.5 ft | Duplicate name kept for `GeometryModelL2` contract parity |
| 30 | `Amax` | **AREA-RULED buildup**, `GeomL3.get_Amax(obj)` — `MAX` over the 20 rescaled frame stations of (`A_fuse` + `A_wing` + `A_HT` + `A_VT` + `A_nacelle`) less `n_engines·π·D_engine²/5` | **24.703652 ft²** *(live)* | `[Brandt Geom!H26:H45 → H47 → B20; readme_geom.md §§4.2/4.5]`. **NOT** the envelope ellipse — that is L2's answer and stays there (27.488936). Two UNCITED elements, stated not glossed: the affine frame rescaling (todo §4) and the bare `/5` (todo §5). Full writeup: §D |
| **Inlet / duct** |||||
| 31 | `T_AB_SLS_lb` | `prop.T_SL` (injected) | 23,770 lbf | `[Brandt Engn(s)!T_AB_SLS = Main!D29]`. **INPUT → DERIVED** — built |
| 32 | `D_inlet` | `GeometryBase.compute_nacelle_diameter(T_AB_SLS_lb)` = `sqrt(T/1900)` | 3.537022 ft *(live)* | `[Brandt Geom!C475; Engn(s)!L22 = 1900]`; `readme_geom.md` §3. The shared cited static now **exists** (reuse gap closed) and both tiers call it. ★ 1900 is hardcoded unconditionally, which assumes an **AB** engine — Brandt uses `L10` = 2000 when `T_dry = T_AB` (todo §18) |
| 33 | `D_exit` | `= D_inlet` | 3.5370 ft | Brandt models the nacelle as a constant-diameter cylinder. **ADD** |
| **Total** |||||
| 34 | `S_wet` | wing + HT + VT + fuselage + duct (§A.5) | **1488.2515 ft²** *(live: 1488.2514)* (official Roskam set, incl. duct; Brandt-form alternate 1480.8261) | Component citations above |

### A.2b DERIVED added by sub-step 2h (11) — area-ruled `Amax` intermediates

All eleven were verified derivable from inputs L3 already carried (todo §16.1), so **none may ever
be stored**. Formulas and citations live on the `GeomL3` statics; values *(live)* below.

| # | Derived | Formula / static | Value *(live)* | Citation / note |
|---|---|---|---|---|
| 35 | `L_engine` | `GeomL3.compute_engine_length(D_inlet)` = `4.5·D` | 15.916600 ft | `[Brandt Geom!D475 = C475 · 'Engn(s) Old'!Q22, Q22 = ='Engn(s)'!R22 = 4.5]`. A slenderness ratio, **not** a textbook equation — no Raymer/Roskam/Mattingly number is claimed. NB the source cell reads the **`Engn(s) Old`** sheet while `readme_geom.md` §3 cites `Engn(s)` (todo §18) |
| 36 | `x_nacelle_aft` | `x_inlet + L_duct + L_engine` | 44.916600 ft | `[Brandt Geom!C480 → C482 → C484]`, the live chain inlet lip → compressor face → nozzle. **Not** `BrandtGeometry.m`'s 43.9166 (todo §18) |
| 37 | `c_exp_root_wing` | `GeomL3.compute_c_root_exposed(c_root, c_tip, b/2, W_max/2)` | 13.356415 ft | `[Brandt Geom!F7 = 13.35642]` — **exact** |
| 38 | `c_exp_root_ht` | same, HT chords + `b_ht/2` | 6.731493 ft | cf. `[Brandt Geom!F8 = 6.83910]`, −1.57 %: purely Decision 1's 18.5 ft span. **BY DESIGN** |
| 39 | `c_exp_root_vt` | same, VT chords over the **full** panel span, clipped by `H_max/2` | 7.123299 ft | `[Brandt Geom!F10 = 7.12330]` — **exact**. Takes no sweep, so the 47.5-vs-40° divergence cannot reach it: a genuine positive control |
| 40 | `G_hs_exp_wing` | `b_wing/2 − W_max/2` | 11.500000 ft | `[Brandt Geom!G7 = 11.5]` |
| 41 | `G_hs_exp_ht` | `b_ht/2 − W_max/2` | 5.750000 ft | cf. `[Brandt Geom!G8 = 5.5]` — the 18.5 span again. **BY DESIGN** |
| 42 | `G_hs_exp_vt` | `b_vt − H_max/2` (full single panel, half-**depth** clip) | 7.297959 ft | `[Brandt Geom!G10 = 7.29797]` `[readme_geom.md §4.3]` |
| 43 | `Xexp_wing` | `x_apex_wing + (W_max/2)·tan Λ_LE` | 20.722849 ft | `[Brandt Geom!B7 = 20.72268]`; the +0.0008 % gap is entirely the 17.786-vs-17.785833 apex (§A.1b #35) |
| 44 | `Xexp_ht` | `x_le_ht + (W_max/2)·tan Λ_LE,ht` | 38.936849 ft | `[Brandt Geom!B8 = 38.93685]` — exact |
| 45 | `Xexp_vt` | `x_le_vt + (H_max/2)·tan Λ_LE,vt` (vertical → half-**depth**) | 38.728271 ft | cf. `[Brandt Geom!B10 = 38.09775]` at his 40°; L3 is at the physical 47.5°. **BY DESIGN**, the same divergence already logged — not a new error |

Methods on the concrete class: `get_S_ref`, `get_S_wet`, `get_S_wet_wing`, `get_S_wet_HT`,
`get_S_wet_VT`, `get_S_wet_fuselage`, `get_S_wet_duct`, `get_S_exposed_wing` — all eight present and
each a single delegation into `GeomL3`.

### A.3 Nothing derivable may stay frozen — the frozen-constant findings — **DONE**

**All six rows below are fixed as built.** Five quantities moved INPUT → DERIVED on `F16GeomL3`
(`AR_ht`, `S_exposed_ht`, `S_exposed_vt`, `tc_ht`, `tc_vt`) and a sixth (`T_AB_SLS_lb`) left geometry
for the injected `prop`. `TestGeomL3.testFormerlyFrozenPropertiesAreReadOnly` and
`testDerivedLiveRecomputeOnMutation` guard them. The "As-built today" column is retained as the
**historical** record of what was wrong.

| As-built BEFORE Phase 2 | Problem | Fixed to |
|---|---|---|
| `S_exposed_ht = 49.85` stored input (`F16GeomL3.m:57`) | Frozen derivable value: goes stale the instant an optimizer touches `S_ht`/`B_h`/`lambda_ht`/`W_max_fuselage`. Only tolerated today because the L3 JSON deliberately carried no full-planform HT | **Dependent** (§A.2 #18) = **51.1486 ft²**. Full-planform inputs now exist |
| `S_exposed_vt = 40.89` stored input (`F16GeomL3.m:65`) | Same | **Dependent** (§A.2 #26) = 40.8897 ft² |
| **`AR_ht = 2.114` stored input** (`F16GeomL3.m:58`; means FULL 3.0 after the §B rename) | Under Decision 1 the HT planform is fixed by `S_ht` + `B_h`, so a stored `AR_ht` is both derivable **and** contradictable — an optimizer changing `B_h` would leave `AR_ht` stale, and a JSON carrying both would be self-inconsistent | **Dependent** (§A.2 #11) = `B_h²/S_ht` = **3.1690** |
| `tc_ht = 0.04` / `tc_vt = 0.04` stored inputs | Become derivable once the T.O. root/tip splits are the basis | **Dependent** root/tip mean (#17, #25) |
| `T_AB_SLS_lb = 23770` (on `F16GeomL2.m:130`; would be copied to L3) | Propulsion data frozen into geometry — verified live that `p2.T_SL = 30000` leaves `geom.D_inlet` and `a2.get_CD0()` unchanged, so 155.57 ft² of duct wetted area stays pinned to the old engine | **Dependent** on `prop.T_SL` (#30) |
| `F16AeroL3.Amax_ft2 = 25.110556`, `L_aircraft_ft = 48.304` (`F16AeroL3.m:148-149`) | Brandt geometry **outputs** frozen as aero inputs, while `geometry_brandt_comparison.m:142` reports `Amax` as "NOT MODELED" — the framework consumes as input the very number it reports as unmodelled | `Amax` **Dependent** on geom (#29); `L_aircraft` a geometry INPUT (#31); both read live by aero |

No other stored-but-derivable value was found on `F16GeomL3` — `L_t` (§A.1 #33) and
`S_cs`/`S_csw`/`S_r` (#34/#6/#25) are genuinely non-derivable from anything the repo exposes and
correctly remain inputs.

**Sub-step 2h froze nothing new.** Of the twelve quantities the area-rule buildup needs, eleven are
DERIVED (§A.2b) and only the frame *table* is stored — and it is stored **normalized**, precisely so
that the three fuselage envelope inputs still drive it. The alternative (storing Brandt's raw
dimensional table) would have re-introduced exactly the stale-under-mutation defect this design
removes: with a frozen raw table, `W_max_fuselage` moves `Amax` the **wrong way** (−0.561 % for
+10 %) and `H_max_fuselage` not at all (todo §16.5). §D has the as-built liveness table.
`L_t` = 22.0 is now *in principle* derivable, since the wing/HT apex x-stations became inputs in
§A.1b — but it also needs the MAC y-station, which the model still does not carry, so it correctly
remains an `[estimate]` (todo 2026-07-24 GeomL3 §6).

### A.4 `S_exposed_ht`/`S_exposed_vt` → Dependent — **DECISION 1: OPTION B** (user, 2026-07-25)

**Decided: option B, physical span primary.** `S_ht = 108.0` and `B_h = 18.5` `[USAF 3-view]` are the
INPUTS; `AR_ht` is DERIVED = `B_h²/S_ht` = **3.1690** and must not remain stored. Rationale to carry
forward: this matches GeomL3's own charter (where a physical/T.O. value differs from Brandt, GeomL3
uses the physical one) and how a tail is actually measured off a 3-view — **area and span are
measured; aspect ratio is definitional.** Brandt's `Main!C19` = 3.0 becomes a comparison reference.

Resulting HT planform *(all live, re-verified against the as-built class 2026-07-25)*:
`AR_ht` = **3.168981**, `c_root_ht` = **9.511752 ft**, `c_tip_ht` = **2.163924 ft**,
`S_exposed_ht` = **51.1486 ft²** — **+2.605 %** vs the previously stored 49.85 and **+2.611 %** vs
Brandt GT `Geom!H8` = 49.84725. That divergence is **INTENTIONAL** and is annotated `BY DESIGN` in
the comparison report (§G), never as an error.

Knock-on live values: `mac_ht` 6.7921 → **6.608537 ft** (−2.703 %), `QC_sweep_ht` 32.1832 →
**32.639955°**, `TE_sweep_ht` −0.0002 → **2.561693°**, HT `Lambda_m_comp` at `x_c_max` = 0.35
28.6086 → **29.2956°**.

**The wetted-area consequence, which is the one a reader is most likely to trip over:**
`S_wet_ht` = **104.0349 ft²** *(live: 104.0348)* vs Brandt `Geom!B16` = 99.58484, i.e. **+4.47 %**.
That single number is the **sum of two independent deliberate choices** and must always be reported
decomposed, never as one large error:

| Contribution | Δ | Source |
|---|---|---|
| Formula family — Roskam Vol. II Eq. 12.1 with the T.O. root/tip t/c split, vs Brandt's uniform-t/c `Geom!B13` form | **+1.8 %** | Decision 2 (§A.5) |
| Exposed area — option B's `S_exposed_ht` 51.1486 vs Brandt's 49.84725 | **+2.6 %** | Decision 1 (this section) |
| **Total** | **+4.47 %** | — |

Sub-step 2h added two more option-B knock-ons, both `BY DESIGN` and both harmless to `Amax`
(the HT contributes 0.000 % of it — §D): `c_exp_root_ht` 6.731493 vs `Geom!F8` = 6.83910 (−1.57 %)
and `G_hs_exp_ht` 5.75 vs `Geom!G8` = 5.5 (§A.2b #38/#41).

The A/B/C table below is retained as the **rationale record** for why B was chosen, and to keep
option C explicitly marked never-implement.

Computed live 2026-07-25 from the §A.1 inputs through the existing `GeomL2` statics.

**VT — no divergence is possible.** `GeomL2.compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)`
takes **no sweep argument** (`src/disciplines/geometry/GeomL2.m:304`). Its inputs at L3 are
`S_vt=60`, `AR_vt=1.6`, `lambda_vt=0.5`, `H_max_fuselage=5.0` — identical to L2. So:

| Quantity | Computed *(live)* | vs stored 40.89 | vs Brandt GT `Geom!10` 40.8897 | vs L2 |
|---|---|---|---|---|
| `S_exposed_vt` | **40.8897 ft²** | −0.0008 % | −0.0001 % | identical |

The plan's premise that "L3 VT sweep 47.5" makes `S_exposed_vt` diverge from L2 was **incorrect for
the existing static** (confirmed by the coordinator, 2026-07-25): sweep never enters the exposed-area
clip. Do **not** "fix" this by inventing a sweep-dependent exposed-area formula.

**HT — the planform is over-determined; option B resolves it by making `B_h` primary.**
`S_ht=108`, a stored `AR_ht=3.0` and `B_h=18.5` cannot all hold: `sqrt(AR_ht·S_ht)` = **18.0**
*(live)*. Three candidate getters, all computed live:

| Option | Basis | `c_root_ht` | `c_tip_ht` | `hs` | `S_exposed_ht` | vs stored 49.85 | Status |
|---|---|---|---|---|---|---|---|
| A | full-planform self-consistent: span = `sqrt(AR_ht·S_ht)` = 18.0; `B_h` a weights-only input | 9.7760 | 2.2240 | 9.00 | 49.8473 ft² | −0.006 % | **not chosen** |
| **B** | **physical span primary: chords from `B_h`=18.5 and `S_ht`=108; `AR_ht` DERIVED = 3.1690** | **9.5118** | **2.1639** | **9.25** | **51.1486 ft²** | **+2.605 %** | ★ **CHOSEN** (user, 2026-07-25) |
| C | mixed: chords from `AR_ht·S_ht` but `hs = B_h/2` | 9.7760 | 2.2240 | 9.25 | 52.5694 ft² | +5.455 % | **NEVER IMPLEMENT** — geometrically inconsistent: clips a trapezoid outside its own span |

Why A was rejected: it produces no divergence at all, i.e. L3 would silently reproduce Brandt's
derived 18.0 ft span while the JSON carried the physical 18.5 ft as an unused weights-only number —
two spans for one surface, with the *less* physical one driving the geometry. Option B carries one
span for one surface.

### A.5 Which `S_wet` formula family L3 uses — **DECISION 2: Roskam Eq. 12.1 is official** (user, 2026-07-25)

**Decided.** At L3 the official lifting-surface wetted-area formula is **Roskam Vol. II Eq. 12.1**
(`GeomL2.compute_roskam_planform`), fed the new T.O. root/tip t/c splits — the same "official" choice
L2 already makes. Brandt's uniform-t/c `Geom!B13` formula (`GeomL2.compute_wet_planform`) is retained
as an **alternate comparison-report row only**, exactly as L2 does — not as the computed value.

Recomputed live 2026-07-25 **with the option-B HT chords** (the HT row moved because `S_exposed_ht` is
now 51.1486, not 49.8473):

| Surface | **Official: Roskam Eq. 12.1** | Alternate: Brandt uniform-t/c (root/tip mean) | Brandt GT | Roskam vs GT | Brandt-form vs GT |
|---|---|---|---|---|---|
| Wing | **396.3767** | 392.0205 | 392.0204 `Geom!B14` | **+1.11 %** | +0.00 % |
| HT | **104.0349** | 102.3842 | 99.5848 `Geom!B16` | **+4.47 %** | +2.81 % |
| VT | **83.1399** | 81.7213 | 81.6894 `Geom!B17` | **+1.78 %** | +0.04 % |

**This moves L3 *further* from Brandt's ground truth (+1.1 … +4.5 %), and that is correct, not a
regression.** Brandt's GT numbers are the output of *his own* uniform-t/c formula fed his own inputs,
so the Brandt-form column matches them almost exactly **by construction** — matching them would mean
adopting his coarser single-t/c model rather than the better variable-t/c one. The HT's larger gap
(+4.47 %) is the sum of two deliberate choices: Roskam Eq. 12.1 (+1.8 % of it) and the option-B
exposed area (+2.6 %).

Fuselage / duct / totals at L3 *(all live)*: Roskam Eq. 12.3 with `D_fus`=6.0, `L_fus`=47.5 →
**749.1337 ft²** (L2's `L_fus`=46.5 gives 730.3023); duct frustum → **155.5664 ft²**; **official
total 1488.2515 ft²** (+11.80 % vs Brandt's corrected whole-aircraft 1331.134), Brandt-form alternate
total 1480.8261 (+11.25 %). The whole-aircraft `%Diff` is **not** a like-for-like comparison: Brandt's
corrected total also carries a strake (39.956) and nacelle (41.515) term this framework has no
component for, partially offset by our larger 47.5 ft fuselage. Do not report it as an agreement
check.

---

## B. Rename mapping — exposed vs full planform — **DONE (applied)**

**As built:** `AR_ht`/`lambda_ht`/`S_ht`/`S_vt` mean **FULL** planform on both tiers; the exposed
values are `AR_exposed_ht`/`lambda_exposed_ht`/`AR_exposed_vt`/`lambda_exposed_vt`; `AR_ht` is
DERIVED. The injection guard was narrowed at the same time —
`F16AeroL2.m:101` and `F16AeroL3.m:144` now both read
`geom (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}` instead of the old
`GeometryBase`, so only the two tiers that share this contract can be injected. The section below is
kept as the **rationale record** for why the rename was necessary.

`GeometryModelL2` uses `AR_ht`/`lambda_ht`/`S_ht`/`S_vt` for **FULL** planform. `GeometryModelL3`
today uses the *same four names* for **EXPOSED** planform. Both are `GeometryBase` subclasses, and
`F16AeroL2`/`F16AeroL3` accept `geom (1,1) GeometryBase` — so injecting the wrong tier compiles,
runs, and silently resolves the same property name to a different physical quantity.

| Today on `GeometryModelL3`/`GeomL3`/`F16GeomL3` | Value | Rename to | Then the old name means | JSON key it aligns with |
|---|---|---|---|---|
| `AR_ht` (exposed) | 2.114 | **`AR_exposed_ht`** | `AR_ht` = FULL, and **DERIVED** = `B_h²/S_ht` = 3.1690 (Decision 1) — no longer a stored input at all | `.horizontal_tail.AR_exposed` (already) |
| `lambda_ht` (exposed) | 0.390 | **`lambda_exposed_ht`** | `lambda_ht` = FULL 0.2275 `[Brandt Main!C20]` | `.horizontal_tail.taper_exposed` (already) |
| `AR_vt` (exposed) | 1.294 | **`AR_exposed_vt`** | `AR_vt` = FULL 1.6 `[Brandt Main!H19]` | `.vertical_tail.AR_exposed` (already) |
| `lambda_vt` (exposed) | 0.437 | **`lambda_exposed_vt`** | `lambda_vt` = FULL 0.5 `[Brandt Main!H20]` | `.vertical_tail.taper_exposed` (already) |
| `S_exposed_ht` (stored input) | 49.85 | keeps its name, becomes **Dependent** | — | `.horizontal_tail.S_exposed_ft2` **DROPPED** |
| `S_exposed_vt` (stored input) | 40.89 | keeps its name, becomes **Dependent** | — | `.vertical_tail.S_exposed_ft2` **DROPPED** |
| *(absent)* | — | **`S_ht` ADDED** = 108 | FULL area, same meaning as L2. NB at L3 the HT AR is **not** a JSON key — `S_ht` + `B_h` fix the planform (Decision 1) | `.horizontal_tail.S_ft2` **ADD**; **no `AR` key** |
| *(absent)* | — | **`S_vt` ADDED** = 60 | FULL area, same meaning as L2 | `.vertical_tail.S_ft2` **ADD** |

**Concrete hazard being removed** (not hypothetical — this is live code today):
`F16AeroL3.get.l_ref_comp` (`F16AeroL3.m:173-174`) computes the HT/VT reference lengths as

```matlab
mac_ht = GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht);
mac_vt = GeometryBase.compute_mac(g.c_root_vt, g.lambda_vt);
```

`GeometryBase.compute_mac` (Raymer 7th ed. Eq. 7.8) requires the **full-planform** taper that goes
with the chord it is handed. Injecting today's `F16GeomL3` would feed `lambda_ht = 0.390` (exposed)
into an equation expecting 0.2275 — a wrong MAC, hence a wrong component Reynolds number, hence a
wrong Raymer Eq. 12.30 form factor, in a code path with **no error and no warning**.
`get.Lambda_m_comp` (`:197-199`) has the identical exposure via `convert_sweep`/`convert_sweep_panel`.
The weights side has the mirror-image trap already logged (todo 2026-07-24 GeomL3 §5): `geom.S_ht`
would feed 108 into Raymer Eq. 15.2 where 49.85 is intended, and `geom.D_fus` would feed 6.0 into
Eq. 15.4 where 5.0 (`H_max_fuselage`) is intended.

After the rename: `AR_ht`/`lambda_ht`/`S_ht`/`S_vt` mean FULL planform on **both** tiers,
`S_exposed_*` means exposed on both, `H_max_fuselage` is the structural depth on both, and
`AR_exposed_*`/`lambda_exposed_*` are unambiguous by name. Phase 2d's narrowed injection guard then
has a coherent shared contract to type against.

Files to update with the rename: `GeometryModelL3.m`, `GeomL3.m`, `F16GeomL3.m`,
`f16a_L3.json .geometry`, `tests/disciplines/TestGeomL3.m` (`testExposedTailARTaperPhysical`,
`testExposedTailAreasArePhysicalInputs` — the latter must become a *derived*-value test, and per the
anti-self-referential rule its expected value must be the hand-computed clip, not a re-read of the
property), this doc, and `docs/geometry_parameter_usage.md`.

---

## C. The complete L3-aero contract — every `obj.geom.*` read — **DONE (all 28 rows satisfied)**

**As built:** every `ADD` in the table below exists on `F16GeomL3`, every `RENAME` is applied, and
`F16AeroL3` reads `Amax`/`L_aircraft` live off the injected geometry object (`get.Amax_ft2` /
`get.L_aircraft_ft`, `F16AeroL3.m:226-249`) instead of the frozen Brandt outputs. Both "reuse gaps"
noted at the end of this section were closed by extracting cited `GeometryBase` statics —
`compute_Amax_elliptical` (L2 only now) and `compute_nacelle_diameter`. The `Amax` row (#27) is the
one whose *value* moved after this table was written: see §D.

Derived by reading `examples/F16A/F16AeroL3.m` line by line (not guessed). `AeroL2`/`AeroL3`
statics never touch `obj.geom` themselves (verified by grep — zero matches in
`src/disciplines/aerodynamics/`); every geometry read is a `Dependent` getter on `F16AeroL3`, so
this list is complete for L3 aero.

| # | Member read | Read at (`F16AeroL3.m`) | Feeds | On `F16GeomL3` today | Action | Formula + citation if added | Reuse |
|---|---|---|---|---|---|---|---|
| 1 | `S_ref` | :156 | `get.S_ref` → CD0 normalization, `CD0_misc` | ✅ input | — | — | — |
| 2 | `AR_wing` | :157 | `get.AR` → Oswald e, K1, CL_α | ✅ input | — | — | — |
| 3 | `LE_sweep_wing` | :158 | `get.Lambda_LE_deg` → Eq. 12.49/12.51, wave drag | ✅ input | — | — | — |
| 4 | `QC_sweep_wing` | :159 | `get.Lambda_c4_deg` → Eq. 12.6 CL_α, Eq. 12.15 CLmax, Eq. 12.62 | ❌ | **ADD (Dependent)** | `convert_sweep(LE_sweep_wing, AR_wing, lambda_wing, 0.25)` = 32.1832° *(live)*; standard swept-wing identity (uncited edition, `GeometryBase.md`) | `GeometryBase.convert_sweep` |
| 5 | `lambda_wing` | :160 | `get.taper` → Roskam Part II Eq. 7.10 flapped-area | ✅ input | — | — | — |
| 6 | `S_wet_wing` | :165 | `S_wet_comp(1)` → Eq. 12.24 | ⚠️ method only | **ADD (Dependent property)** | Roskam Eq. 12.1 (Decision 2) = 396.3767 | `GeomL2.compute_roskam_planform` |
| 7 | `S_wet_ht` | :165 | `S_wet_comp(2)` | ⚠️ method only | **ADD (Dependent property)** | Roskam Eq. 12.1 = **104.0349** (option-B chords) | same |
| 8 | `S_wet_vt` | :165 | `S_wet_comp(3)` | ⚠️ method only | **ADD (Dependent property)** | Roskam Eq. 12.1 = 83.1399 | same |
| 9 | `get_S_wet_fuselage()` | :165 | `S_wet_comp(4)` | ✅ method | — | Roskam Vol. II Eq. 12.3 | `GeomL2.compute_s_wet_fus_cyl` |
| 10 | `get_S_wet_duct()` | :165 | `S_wet_comp(5)` | ❌ | **ADD (method)** | frustum lateral area `π(r₁+r₂)√((r₂−r₁)²+L²)` = 155.5664 ft² *(live)*; Raymer 6th/7th ed. §7.3 | `GeomL2.compute_s_wet_duct` |
| 11 | `cbar_wing` | :175 | `l_ref_comp(1)` → Re, Eq. 12.25 | ❌ | **ADD (Dependent)** | `compute_mac(c_root_wing, lambda_wing)` = 11.3202 ft *(live)*; Raymer 7th ed. Eq. 7.8 | `GeometryBase.compute_mac` |
| 12 | `c_root_ht` | :173 | HT MAC → `l_ref_comp(2)` | ❌ | **ADD (Dependent)** | `compute_root_chord(S_ht, b_ht, lambda_ht)` with `b_ht = B_h = 18.5` (Decision 1) = **9.5118 ft** *(live)*; Raymer 7th ed. Eq. 7.6. → `mac_ht` = **6.6085 ft** (was 6.7921 on the 18.0 basis) | `GeometryBase.compute_root_chord` |
| 13 | `lambda_ht` | :173, :198 | HT MAC (Eq. 7.8), `Lambda_m_comp(2)` | ⚠️ **wrong meaning** (0.390 exposed) | **RENAME** → `AR/lambda_exposed_ht`; `lambda_ht` becomes FULL 0.2275 | `[Brandt Main!C20]` *(live)* | — |
| 14 | `c_root_vt` | :174 | VT MAC → `l_ref_comp(3)` | ❌ | **ADD (Dependent)** | `compute_root_chord(S_vt, b_vt, lambda_vt)` = 8.1650 ft *(live)*, with `b_vt = sqrt(S_vt·AR_vt)` (single panel, readme_geom.md §4.3); Raymer 7th ed. Eq. 7.6 | `GeometryBase.compute_root_chord` |
| 15 | `lambda_vt` | :174, :199 | VT MAC, `Lambda_m_comp(3)` | ⚠️ **wrong meaning** (0.437 exposed) | **RENAME**; `lambda_vt` becomes FULL 0.5 | `[Brandt Main!H20]` *(live)* | — |
| 16 | `L_fus` | :175 | `l_ref_comp(4)` → fuselage Re / Eq. 12.31 | ✅ input (47.5) | — | — | — |
| 17 | `L_duct` | :175 | `l_ref_comp(5)` | ❌ | **ADD (input)** | 14.0 ft `[Brandt engine.duct_length_ft]` | — |
| 18 | `D_fus` | :179 | `D_comp(4)` → Eq. 12.31 body form factor | ✅ Dependent (6.0) | — | `(W+H)/2` | — |
| 19 | `D_inlet` | :179 | `D_comp(5)` | ❌ | **ADD (Dependent)** | `sqrt(T_AB_SLS_lb/1900)` = 3.5370 ft *(live)*; `[Brandt Engn(s) D_nac; readme_geom.md §3]`. **No shared static exists** — see note below | ⚠️ none |
| 20 | `tc_wing` | :185 | `tc_comp(1)` → Eq. 12.30 | ✅ input | — | — | — |
| 21 | `tc_r_ht`, `tc_t_ht` | :185 | `tc_comp(2)` = mean | ❌ | **ADD (inputs)** | 0.060 / 0.035 `[T.O. 1F-16A-1 Sec. I]` | — |
| 22 | `tc_r_vt`, `tc_t_vt` | :185 | `tc_comp(3)` = mean | ❌ | **ADD (inputs)** | 0.053 / 0.030 `[T.O. 1F-16A-1 Sec. I]` | — |
| 23 | `LE_sweep_ht` | :198 | `Lambda_m_comp(2)`, Eq. 12.30 | ❌ | **ADD (input)** | 40° `[Brandt Main!C21]` *(live)* | — |
| 24 | `AR_ht` | :198 | `Lambda_m_comp(2)` | ⚠️ **wrong meaning** (2.114 exposed) | **RENAME** the exposed one → `AR_exposed_ht`, **and make `AR_ht` DERIVED** | `B_h²/S_ht` = **3.1690** (Decision 1); definitional. → HT `Lambda_m_comp` = **29.2956°** at `x_c_max`=0.35 (was 28.6086 on AR 3.0). `Brandt Main!C19` = 3.0 is a comparison reference only | `GeometryBase.compute_span` inverse |
| 25 | `LE_sweep_vt` | :199 | `Lambda_m_comp(3)` | ✅ input (47.5) | — | — | — |
| 26 | `AR_vt` | :199 | `Lambda_m_comp(3)` | ⚠️ **wrong meaning** (1.294 exposed) | **RENAME**; `AR_vt` = FULL 1.6 | `[Brandt Main!H19]` *(live)* | — |
| 27 | `Amax` | *(new)* — replaces `F16AeroL3.Amax_ft2` :148 | Eq. 12.44 Sears-Haack | ❌ | **ADD (Dependent)** | §4 | ⚠️ none |
| 28 | `L_aircraft` | *(new)* — replaces `L_aircraft_ft` :149 | Eq. 12.44 | ❌ | **ADD (input)** | §4 | — |

**Summary: 15 members to ADD** (4 QC/TE + MAC/chord derivations, 3 `S_wet_*` properties,
`get_S_wet_duct`, `D_inlet`/`D_exit`, `L_duct`, 4 t/c splits, `LE_sweep_ht`, `Amax`,
`L_aircraft`), **4 to RENAME**, 9 already present — **plus `AR_ht` converting INPUT → DERIVED**
(Decision 1), which is both a rename and a kind change.

**Two reuse gaps — no existing L2/Base static to call:**
1. **`Amax`.** No static anywhere computes a max cross-section. A new one is required
   (e.g. `GeomL2.compute_Amax_elliptical(W, H)`), and it has no pinnable citation (§4).
2. **Nacelle diameter.** `sqrt(T_AB/1900)` exists only as an inline expression in
   `F16GeomL2.get.D_inlet` (`F16GeomL2.m:378`), not as a named cited static. Copying the literal
   into `F16GeomL3` would duplicate an uncited magic number across two tiers. Recommend extracting
   `GeomL2.compute_nacelle_diameter(T_AB_SLS_lb)` with the `[Brandt Engn(s) D_nac]` citation on it
   once, and having both tiers call it. Flagged, not decided.

Everything else reuses a validated, already-cited static — **no new equation where an L2 one exists.**

---

## D. `Amax` — the area-ruled buildup (sub-step 2h, REWRITTEN 2026-07-25)

> **This section supersedes everything the pre-2h version of this document said about `Amax`.** The
> earlier text specified the fuselage-envelope ellipse at L3 and predicted a **+23.15 %** wave-drag
> shift with an `E_WD` retune to **1.7864**. That story belonged to the ellipse and is **now wrong**
> for L3. Neither number should be carried forward for this tier. The ellipse itself is not gone —
> it is L2's answer and is correct there (§D.3).

### D.1 What L3 computes

```
Amax = MAX over the 20 rescaled frame stations of
           ( A_fuse + A_wing + A_HT + A_VT + A_nacelle )
       - n_engines * pi * D_engine^2 / 5
```

`[Brandt Geom!H26:H45 → H47 → B20; VnV/BrandtF16A/readme_geom.md §§4.2 / 4.5]`. Live COM read
2026-07-25, verbatim:

| Cell | Live value | Live formula |
|---|---|---|
| `Geom!A20` | `Total Aircraft Amax:` (label) | — |
| `Geom!B20` | 25.110556 | `=H47` |
| `Geom!H47` | 25.110556 | `=MAX(H26:H45)-Main!B28*3.141579*C475^2/5` |
| `Geom!AE31` | (nacelle column) | `=IF(C31>=C$480, IF(C31<=C$484, Main!B$28*3.1416/4*C$475^2, 0), 0)` |
| `Main!B28` (`N_eng`) | 1 | `1` (literal) |
| `Geom!C475` (`D_engine`) | 3.537022 | `=IF(Main!C29=Main!D29, (Main!D29/'Engn(s)'!L10)^0.5, (Main!D29/'Engn(s)'!L22)^0.5)` |

Feeds **Raymer 6th ed. Eq. 12.44** (Sears-Haack) as `(Amax/L_aircraft)²`, corrected by Eq. 12.45.

Component-by-component, with the static that owns each equation:

| Term | Static (`GeomL3`) | Formula | Citation |
|---|---|---|---|
| stations | `denormalize_frames` | `x = (x/L)·L_fus`, `w = (w/W_max)·W_max`, `h = (h/H_max)·H_max` | table from `[Brandt Main!A34:F53; readme_geom.md §2]`; ★ **the affine-rescaling assumption itself is UNCITED** — §D.6 |
| `A_fuse` | `compute_frame_cs_area` | `A = w·h·I_cos`, `I_cos = trapz(t, cos(π/2·t))` on Brandt's 6 points `t = [0 .2 .4 .6 .8 1]` → `I_cos` = **0.63137515** *(live)* | `[readme_geom.md §4.2]`. The chine/centre `z` offsets cancel **exactly** out of the area, which is why only `(w,h)` are needed |
| `A_wing`, `A_HT`, `A_VT` | `compute_surface_cs_area` | `A(x) = tc·(c_exp_root + c_tip)·y_span·(1 − cos 2πξ)/2` on `Xexp < x < Xexp + X_max_range` | `[readme_geom.md §4.5; Brandt Geom!Y26:Y45 / AA / AC]`. ★ Brandt's own construction — **no textbook equation number**, §D.6 |
| `A_nacelle` | `compute_nacelle_cs_area` | `n_eng·π·D²/4` = **9.825744 ft²** *(live)* on `x_inlet ≤ x ≤ x_nacelle_aft` = `[15.0, 44.9166]` | `[Brandt Geom!AE31; C480→C482→C484]`. The live chain, **not** the replica's `[14.0, 43.9166]` (todo §18) |
| deduction | `compute_Amax_area_ruled` | `− n_eng·π·D²/5` = **−7.860596 ft²** *(live)* | `[Brandt Geom!H47]`. ★ **bare literal `5`, unjustified anywhere in the workbook** — §D.6 |

#### D.1a The stored frame table — normalization receipts

`f16a_L3.json` `.geometry.fuselage.frames_normalized` stores **20 × 3 = 60** numbers, normalized by
**Brandt's own** envelope (`L_fus` = 46.5 `[Main!B32]`, `W_max` = 7.0 `[Main!C32]`, `H_max` = 5.0
`[Main!D32]`) — note the length denominator is *Brandt's* 46.5, **not** L3's own 47.5, so
denormalizing at L3 is a deliberate 2.15 % affine stretch, not a restoration (§D.2/§D.6).

Three verification receipts, recorded here rather than in the input JSON (all live, 2026-07-25):

1. **Columns dropped — `z_chine_ft`, `z_ft`.** They cancel *exactly* out of the cross-sectional area
   (`readme_geom.md` §4.2: `dz = z_up − z_dn = h·cos(π/2·t)`, containing neither `z` term). Verified
   numerically: perturbing `z_chine` by **+3.7 ft** and `z_center` by **−1.9 ft** at all 20 frames
   changed the 20 frame **areas** by max **7.1 × 10⁻¹⁵ ft²** (pure round-off) while changing the
   **perimeters** by up to **16.97 ft**. The `z` columns matter only to the perimeter, which feeds
   Brandt's high-fidelity fuselage `S_wet` (`Geom!D23`) — a different quantity L3 does not compute
   this way. (`z_chine_ft` is identically 0.0 at all 20 frames in the ground truth anyway.)
2. **Denormalization positive control.** Denormalizing the stored table with `L_fus` = 46.5,
   `W_max` = 7.0, `H_max` = 5.0 reproduces the read-only `GroundTruth/f16a_geometry.json` frame
   values to max `|Δ|` = **3.6 × 10⁻¹⁵ ft** (`x`), **4.4 × 10⁻¹⁶ ft** (`w`), **0** (`h`) — i.e.
   exactly, to floating-point round-off. Hence the `Amax` round-trip in §D.2.
3. **Storage precision convention.** Values are stored at the shortest decimal string that
   round-trips to the identical IEEE-754 double, because `Amax` is a `MAX` over closely-spaced
   stations where rounding could change *which* station governs.

The same algebra (`A = w·h·I_cos`) makes the frame area exactly **bilinear in `w` and `h`**, which is
why `max_width_ft` and `max_depth_ft` move `Amax` by identical percentages (todo §16.5: both
+9.164 % for a +10 % input).

### D.2 Round-trip control — proves the method rather than fitting it

| Case | `L_fus` | `Amax` *(live)* | vs `Geom!B20` = 25.110556 |
|---|---|---|---|
| **ROUND-TRIP CONTROL** | 46.5 (Brandt's own) | **25.110534** | **−0.0001 %** |
| **AS BUILT** | 47.5 `[T.O. 1F-16A-1]` | **24.703652** | **−1.62 %** |

The round-trip is a genuine control, not a calibration: normalizing by an envelope and
de-normalizing by the *same* envelope is an identity, so setting `L_fus` back to 46.5 must reproduce
Brandt's own stations bit-for-bit — and it does. The residual **−0.0001 %** is **Brandt's**, not the
framework's: the workbook hardcodes **two different π values in the same calculation** — `3.1416` in
the nacelle cross-section `Geom!B475`/`AE` column and `3.141579` in the `H47` deduction and in every
cosine surface column — where the framework uses MATLAB `pi` throughout (todo §5).

The as-built **−1.62 %** is a **physical fidelity divergence**, not an error: it is entirely L3's
47.5 ft fuselage vs Brandt's 46.5 (locked decision, todo 2026-07-24 GeomL3 §3). Guarded by
`TestGeomL3.testAmaxRoundTripsToBrandtAtBrandtsOwnFuselageLength` and
`testAmaxIsAreaRuledNotTheEnvelopeEllipse`.

### D.3 Why L2 keeps the envelope ellipse — and why that is not an inconsistency

`F16GeomL2.Amax` = `GeometryBase.compute_Amax_elliptical(W_max, H_max)` = `(π/4)(7.0)(5.0)` =
**27.488936 ft²** *(live, undisturbed by sub-step 2h)*. **This is correct for L2 and must not be
"upgraded".** `readme_geom.md` §7's own fidelity table classifies the envelope form as the
**low-fidelity** `Amax` ("Cylindrical fuselage only") and the whole-aircraft buildup as the
**high-fidelity** one ("Full component buildup — wing + tail + nacelle added"). L2 *is* the
low-fidelity tier. The defect sub-step 2h removed was not the ellipse itself but the ellipse
**sitting in the finest tier**, where Eq. 12.44 wants the area-ruled maximum.

Two caveats a reader should carry, both logged:
- `readme_geom.md` §7's low-fidelity row has **no cell backing at all** — a live read of
  `Geom!A1:D25` finds exactly one `Amax` in the workbook (`B20`, the area-ruled one). §7's low-fi
  entry is a conceptual fidelity statement, not a Brandt quantity (todo §19).
- §7 says "**cylindrical**", which reads as `π·(D_fus/2)²` = 28.2743; what L2 computes is the
  **elliptical** `(π/4)·W·H` = 27.4889 (−2.78 % apart). Neither has an equation number (todo §4/§19).

### D.4 Numeric consequence — `E_WD` = 2.2 needs **no** retune

Sears-Haack scales as `(Amax/l)²` `[Raymer 6th ed. Eq. 12.44]`, corrected by
`[Eq. 12.45]`; `CD0_wave` evaluated at M = 1.6, Λ_LE = 40°, `E_WD` = 2.2, `S_ref` = 300 *(all live)*:

| Basis | `Amax` | `l` | `Amax/l` | `(Amax/l)²` | `CD0_wave` | vs Brandt-referenced |
|---|---|---|---|---|---|---|
| Brandt-referenced (`Geom!B20` / `B21`) | 25.110556 | 48.303947 | 0.519845 | 0.270239 | 0.025052 | — |
| **L3 AS BUILT** (area-ruled / `L_aircraft`) | **24.703652** | **47.65** | **0.518440** | **0.268780** | **0.024917** | **−0.54 %** |
| *(superseded)* envelope ellipse at L3 | 27.488936 | 47.65 | 0.576893 | 0.332805 | 0.030853 | +23.15 % |

**`E_WD` = 2.2 is UNCHANGED and no retune was applied or is needed** — the as-built wave term lands
within −0.54 % of the Brandt-referenced one. For the record only: the `E_WD` that would *exactly*
preserve the reference from the as-built `Amax` is **2.2119**, a 0.54 % move, i.e. inside any
sensible tolerance on a factor that is itself flagged `_TODO_wave_drag_factor_E_WD`. The old
"`E_WD` would need 1.7864" figure applied to the **superseded ellipse** and must not be quoted for
L3.

> **Still stale in `.m` (not fixed in this docs-only pass):** `F16AeroL3.m:293-300` and `:226-237`
> still describe `Amax_ft2` as "`(pi/4)*W_max*H_max` … 27.4889" and still print the +23.15 % /
> `E_WD` = 1.7864 story. Both comments predate sub-step 2h and are wrong for an injected
> `F16GeomL3`. §H item 13.

**Downstream:** the L3 constraint optimum moved to **W/S = 62.0000 psf, T/W = 0.998975** *(live)* —
inside even the original 1.0 bound. That clears the deferred red test (todo §17, now RESOLVED; §H
item 1).

### D.5 Liveness — and the two things about it that are counter-intuitive

Measured live, +10 % on each input, as-built baseline `Amax` = 24.703652:

| Design variable | +10 % → Δ`Amax` | Reading |
|---|---|---|
| `L_fus` | **+12.478 %** | live |
| `W_max_fuselage` | **+9.164 %** | live |
| `H_max_fuselage` | **+9.164 %** | live — identical to `W_max` by construction (the frame area is exactly bilinear in `w·h`) |
| `LE_sweep_wing` | **+7.289 %** | live |
| `S_ref` | **+4.184 %** | live |
| `prop.T_SL` (→ `D_inlet`) | **+0.795 %** | live *(would be 0.000 % under a `/4` deduction — §D.6)* |
| `S_ht`, `B_h`, `S_vt`, `tc_ht` | **0.000 %** each | **a geometric fact, not a dead input** — see below |

This is live **in the right direction everywhere it should be**, which the alternatives were not:
with Brandt's raw dimensional frame table frozen, `W_max_fuselage` moves `Amax` the **wrong way**
(−0.561 %) and `H_max_fuselage` not at all (todo §16.5). Normalizing the table is what fixed both.

**(a) The tails read 0.000 % and that is correct.** The HT and VT cross-sections only begin at
`Xexp_ht` = 38.9368 ft and `Xexp_vt` = 38.7283 ft, far aft of the governing station — so they are
genuinely absent from the maximum for *this* configuration. It is **not** a modelling defect and not
a reason to drop the inputs: under mutation the governing station can migrate aft, at which point
they start to matter (todo §16.5). `TestGeomL3.testAmaxIsInsensitiveToTailPlanform` pins the
behaviour deliberately.

**(b) `Amax` is deliberately NOT linear in `W_max_fuselage` any more.** Live, stepping
`W_max_fuselage` 7 → 8 ft: `Amax` 24.703652 → **27.941727**, a ratio of **1.131077**, *not*
8/7 = 1.142857. The envelope ellipse was exactly linear; the buildup is not, because a wider
fuselage does two opposing things at once — it enlarges **every** frame cross-section *and* eats
more exposed wing root (`fw = W/2` shrinks `c_exp_root_wing` and `G_hs_exp_wing`, so `A_wing`
falls). The old `8/7` exactness was a property of the ellipse and is gone by design.

**(c) Governing-station subtlety — do not quote the two cases together.** The station that sets
`Amax` is **not** the same in the round-trip case and the as-built case, because the affine stretch
moves it:

| Case | Governing frame | `x` | raw `MAX` | `A_fuse` there | `A_fuse` share | `A_wing` there |
|---|---|---|---|---|---|---|
| ROUND-TRIP (`L_fus` = 46.5) | frame **12** | **29.1000 ft** | 32.971129 | 17.3628 | **52.7 %** | 5.7826 |
| **AS BUILT** (`L_fus` = 47.5) | frame **9** | **22.2944 ft** | 32.564247 | 22.5717 | **69.3 %** | 0.1668 |

All live. `todo.md` §16.1's much-quoted "`A_fuse` = 17.3628 of 32.9711 at x = 29.1, i.e. 52.7 %"
describes the **round-trip / Brandt-length** case **only**. Quoting it alongside the as-built 47.5 ft
configuration is a category error (recorded in todo §21). `Amax` itself is unaffected — 24.703652 is
confirmed either way; only the *where* changes.

### D.6 The two UNCITED elements — kept explicit, not papered over

Both are isolated in the code behind ★ blocks naming their todo item, and both are **OPEN user
decisions**. No equation number was invented for either.

**(i) The affine frame-table rescaling — `GeomL3.denormalize_frames` → todo 2026-07-25 Phase 2 §4.**
The assumption that a fixed *normalized* cross-section shape distribution can be rescaled by the
fuselage envelope has **no textbook source**: no Raymer, Roskam, Mattingly or metabook equation
number exists for it anywhere in this repo. The one lead on record is that the repo's own Roskam
Vol. II extract (`roskam_vol2_data.md:22`) names **Roskam Part VI** as the authority for
cross-sectional area-ruling — and Roskam Part VI is not in this repo. The same §4 also covers the
underlying **cosine section model** and Brandt's `(1 − cos 2πξ)` surface area-distribution, which
`readme_geom.md` §4.5 documents in full but which traces to no textbook found in this repo. §4 was
**split in this pass**: its elliptical-identity half now applies to L2 only, its affine-rescaling
half to L3. Both halves stay OPEN.
*Modelling consequence, real and not a data error:* `max(h/H_max)` = **1.50** at frame 6 — the canopy
bulge — so "max fuselage depth" is not the maximum frame height of the table it scales, and a 10 %
deeper fuselage gets a 10 % taller canopy. Explicitly: the actual max frame height is **`h` = 7.5 ft
at frame 6, `x` = 15.0 ft** `[GroundTruth/f16a_geometry.json fuselage.frames; Brandt Main!A34:F53]`,
against a `max_depth_ft` **input** of 5.0 `[Main!D32]` — hence 7.5/5.0 = 1.50, which is **not a
typo** in `frames_normalized`. Accept the model or replace it; do not "correct" the 1.50.
(`w_over_Wmax` and `x_over_L` both peak at exactly 1.0, so only the depth axis has this property.)

**(ii) The bare `/5` flow-through divisor — `GeomL3.compute_Amax_area_ruled` → todo §5.** A live
2026-07-25 search of the entire Brandt nacelle block `Geom!A470:E490` found **no inlet capture area,
no throat diameter, and nothing else in the workbook dividing by 5** — a verified absence, not an
unsearched gap — while `readme_geom.md` §4.5 uses `π·D²/4` = 9.826 ft² for the *same* nacelle's own
cross-section. So the deduction removes 80 % of what the `AE` column added, for no documented
reason. Cost of the alternative at the **as-built** configuration *(live)*: raw `MAX` 32.564247,
`/5` → **24.703652**, `/4` → **22.738503** (**−7.95 %**); under `/4` the flow-through nacelle nets
exactly zero (the textbook area-rule treatment of a fully-ducted body) and `Amax` becomes
**completely insensitive to engine thrust**. Still a user decision; **not resolved here**.
*(todo §16.4 quotes `/4` → 23.145385 — that is the **Brandt-length / variant-A** case, not this one.)*

### D.7 Three further scoping decisions this buildup encodes

1. **Discretization — Brandt's 6-point cosine sampling was taken, and it is an OPEN item (todo §20).**
   `I_cos` = **0.63137515** on 6 points vs the exact `∫₀¹cos(π/2·t)dt` = 2/π = **0.63661977**: the
   6-point rule is uniformly **0.824 % low** at every frame (a pure constant factor, not a shape
   difference). Kept for consistency with the `/5` and coarse-20-station conventions and because
   every sub-step-2h expected value is built on it. The exact form is implemented and reachable as
   the **labelled alternate** `GeomL3.compute_frame_cs_area_exact`; live cost of switching:
   `Amax` 24.703652 → **24.891147** (+0.759 %) as built, 25.110534 → **25.254761** (+0.574 %) at
   round-trip. Switching is a one-line change. **Confirm the 6-point choice or switch — user decision.**
2. **The `MAX` is over the 20 frame stations only**, exactly as `Geom!H26:H45` does — deliberately
   *not* a refined grid. A 0.02-ft interpolated grid gives +1.89 % (todo §16.1 variant A′).
3. **Strake DEFERRED, and Brandt's two documented strake bugs DECLINED — both numerically free.**
   The strake is active only over `12.000 < x < 21.551` ft and its cross-section is **exactly zero**
   at the governing station, so strake-out / strake-bugged / strake-corrected give an **identical**
   `Amax` — worth **0.000 %** (todo §16.2/§16.3). Brandt's VT copy-paste bug (`Geom!AC31` mixing the
   wing tip chord `D$7` into the VT range test) is likewise **not** replicated, also free — the VT
   section starts ~38.73 ft, far aft of the governing station. What a strake component *would* buy is
   unrelated to `Amax`: it closes the report's two remaining "NOT MODELED" rows, strake `S_wet`
   = 39.956 `[Brandt Geom!B15]` and strake exposed area = 20.0 `[Brandt Geom!H9]` (todo §23, new).

## E. `L_aircraft` (overall aircraft length)

**INPUT, both L2 and L3**: `overall_length_ft = 47.65`.

- Claimed provenance: published F-16A airframe length, 47 ft 7.75 in. Exactly that is
  **47.6458 ft**; 47.65 is a +0.009 % rounding.
- **Citation status:** neither "47.65", "47 ft 7.75 in", nor any overall-length figure appears
  anywhere in `air_vehicle_design/sizing/` (grepped 2026-07-25 — the only hits for `7.75` are in
  read-only `temp_Casey/` and are unrelated flap geometry). So this value currently has **no
  in-repo source document.** Logged as todo §6.
- Brandt reference (comparison only): `Geom!B21` = **48.303947** *(live)*, label `Geom!A21` =
  `Total Aircraft Length:`, formula `=MAX(L38:L44,L46:L121,L123:L141,L152,…,L169)` — a max over his
  x-station columns, i.e. the aft-most modelled station of his component layout, not a published
  airframe dimension. 47.65 vs 48.304 = **−1.35 %**.
- **The two are not comparable quantities.** 47.65 is a *published airframe length* — a
  specification dimension. Brandt's 48.304 is a **`MAX()` over his x-station columns**, i.e. the
  aft-most extent of his own component layout — an *extent*, not a spec length. The −1.35 % gap is
  therefore a definitional difference, not an error in either number, and the report row carries the
  `Divergence` annotation (as shipped: `BY DESIGN` — see §G.1 on the two-state vocabulary).
- Not derivable in-model: the geometry object has no nose-boom / tailcone x-stations, so this cannot
  be a Dependent quantity today. It is a genuine input.
- Distinct from `L_fus` (47.5 ft) — do not conflate the two length scales. `L_fus` feeds the
  fuselage-component Reynolds number and Roskam Eq. 12.3; `L_aircraft` feeds only Eq. 12.44.
- **`47.65` stands as the user's decision (2026-07-25), but todo §6 stays OPEN** as a standing item
  to pin it to a primary source. Until then the JSON `_src` must say plainly that the figure is a
  published airframe length not traceable to any document in this repo.

---

## F. Brandt cell-citation corrections — **DECISION 3: APPLIED (verified 2026-07-25)**

**Status: the fix has landed.** Spot-verified in this pass: `F16GeomL2.m:139-157,252-270` and
`F16GeomL3.m:178-202,344-370` now cite `Main!{B,C,H}20` = taper, `Main!{B,C,H}21` = sweep,
`Main!{B,C,H}22` = NACA 4-digit → t/c, each with a "citation corrected 2026-07-25 from …" note.
Zero computed values changed, exactly as predicted.

**This section remains the single authoritative reference for the fix**, kept as the evidence record;
`VnV/BrandtF16A/todo.md` §1–§2 are marked RESOLVED-by-user and point here. Cell values and formulas
below were read live over Excel COM on 2026-07-25 and re-confirmed this pass.

**Zero computed values change.** Every *number* in the repo is already correct — only the cell
reference text moves. No comparison report, no test expectation, and no computed quantity shifts as a
result of this fix. Do not expect a report diff from it.

Live `Main` tab row labels (column A) with the wing/HT/VT columns:

| Row | Label (live) | B (wing) | C (pitch ctrl) | H (vert surf) |
|---|---|---|---|---|
| 18 | `S, sq ft` | 300 | 108 | 60 |
| 19 | `Aspect Ratio` | 3 | 3 | 1.6 |
| 20 | **`Taper Ratio`** | **0.2275** | **0.2275** | **0.5** |
| 21 | **`Sweep, deg`** | **40** | **40** | **40** |
| 22 | `NACA 4-digit` | 1404 | 0004 | 0004 |
| 24 | `Y Location` | *(empty)* | *(empty)* | 0 |
| 27 | `TE Sweep` | −0.00024343 (`=Geom!N45`) | −0.00024343 (`=Geom!N122`) | 0 (literal) |

### F.1 The three corrections — exact scope

| Quantity | Current (wrong) citation | Correct citation | Live evidence |
|---|---|---|---|
| **taper** | `[Brandt Main!{B,C,H}21]` | **`[Brandt Main!{B,C,H}20]`** | row 20 label = `Taper Ratio`; B20/C20 = 0.2275, H20 = 0.5 |
| **LE sweep** | `[Brandt Main!{B,C,H}20]` | **`[Brandt Main!{B,C,H}21]`** | row 21 label = `Sweep, deg`; B21/C21/H21 = 40 |
| **t/c** | `[Brandt Main!{B,C,H}24]` | **`[Brandt Main!{B,C,H}22]`** — NACA 4-digit designation → t/c: `1404` → 0.04 (wing), `0004` → 0.04 (HT, VT) | row 22 label = `NACA 4-digit`. Row 24 label = `Y Location`; B24/C24 **empty**, H24 = 0 |

Nothing else on rows 18–27 is miscited: `S` (`{B,C,H}18`) and `Aspect Ratio` (`{B,C,H}19`) are
correct everywhere they appear, as are the fuselage cells `B32`/`C32`/`D32`.

### F.2 Informational, not part of the fix

Brandt's own `Main!H27` VT TE sweep is a hardcoded **0**, while the wing/HT TE
sweep cells are live formulas (`=Geom!N45`/`=Geom!N122`) that our `convert_sweep` reproduces to
−0.0002° *(live)*. Brandt's own VT planform (S=60, AR=1.6, λ=0.5, Λ_LE=40) implies TE sweep
**22.9008°**, exactly what Phase 1b's `convert_sweep_panel` now returns. So the Phase-1b fix is
corroborated by Brandt's geometry and contradicted only by his unused-looking literal 0 — recorded
so nobody later "corrects" 22.90 back to 0. **No edit required.**

### F.3 Files that needed the edit — complete file:line list (**APPLIED**; line numbers are pre-edit)

Grepped repo-wide 2026-07-25 (`Main!?\s*[BCH](18|19|20|21|22|24)` and `\b[BCH](18|19|20|21|22|24)\b`,
excluding `temp_Casey/` and `temp_AI/`). Every hit is listed; nothing is left implicit.

**`examples/F16A/F16GeomL2.m`** — 12 sites
| Line | Current | → |
|---|---|---|
| :100 | `tc_wing = 0.04 % [Brandt Main!B24]` | `Main!B22` |
| :101 | `lambda_wing = 0.2275 % [Brandt Main!B21]` | `Main!B20` |
| :103 | `LE_sweep_wing = 40 % [Brandt Main!B20]` | `Main!B21` |
| :107 | `tc_ht = 0.04 % [Brandt Main!C24]` | `Main!C22` |
| :108 | `lambda_ht = 0.2275 % [Brandt Main!C21]` | `Main!C20` |
| :110 | `LE_sweep_ht = 40 % [Brandt Main!C20]` | `Main!C21` |
| :116 | `tc_vt = 0.04 % [Brandt Main!H24]` | `Main!H22` |
| :117 | `lambda_vt = 0.5 % [Brandt Main!H21]` | `Main!H20` |
| :119 | `LE_sweep_vt = 40 % [Brandt Main!H20]` | `Main!H21` |
| :196 | `obj.lambda_wing = J.wing.taper; % [Brandt Main!B21]` | `Main!B20` |
| :197 | `obj.LE_sweep_wing = …; % [Brandt Main!B20]` | `Main!B21` |
| :198 | `obj.tc_wing = …; % [Brandt Main!B24]` | `Main!B22` |

**`examples/F16A/F16GeomL3.m`** — 5 sites
| Line | Current | → |
|---|---|---|
| :51 | `lambda_wing = 0.2275 % [Brandt Main!B21]` | `Main!B20` |
| :52 | `LE_sweep_wing = 40 % [Brandt Main!B20]` | `Main!B21` |
| :53 | `tc_wing = 0.04 % [Brandt Main!B24]` | `Main!B22` |
| :60 | `tc_ht = 0.04 % [Brandt Main!C24]` | `Main!C22` (this property becomes DERIVED — carry the corrected citation onto the `tc_r_ht`/`tc_t_ht` T.O. inputs' sibling comment) |
| :68 | `tc_vt = 0.04 % [Brandt Main!H24]` | `Main!H22` (same note) |

**`examples/F16A/f16a_L2.json`** — 1 site
| Line | Current | → |
|---|---|---|
| :5 | `.geometry._src`: `"Main tab (wing B18:B24, pitch_ctrl C18:C24, vert_tail H18:H24, fuselage B32/C32/D32, engine Engn(s))"` | `wing B18:B22, pitch_ctrl C18:C22, vert_tail H18:H22` — row 24 is `Y Location` (empty for wing/HT) and is not an input source; add "t/c from the row-22 NACA 4-digit designation" |

**`examples/F16A/f16a_L3.json`** — 3 sites (all inside `_src` prose)
| Line | Current | → |
|---|---|---|
| :9 | `.geometry.wing._src`: `taper=0.2275 [Brandt Main!B21 / TO Fig. 1-2]`; `sweep_LE_deg=40 [Brandt Main!B20 / TO Fig. 1-2]`; `tc_ratio=0.04 (NACA 64A204) [Brandt Main!B24]` | `B20` / `B21` / `B22` respectively |
| :19 | `.geometry.horizontal_tail._src`: `tc_ratio=0.04 = HT uniform t/c [Brandt Main!C24; biconvex ~4%]` | `Main!C22` |
| :29 | `.geometry.vertical_tail._src`: `intentionally diverges from GeomL2's 40 [Brandt Main!H20]`; `tc_ratio=0.04 = VT uniform t/c [Brandt Main!H24; biconvex ~4%]` | `Main!H21` / `Main!H22` |

**`VnV/BrandtF16A/todo.md`** — 1 site
| Line | Current | → |
|---|---|---|
| :592 | 2026-07-24 GeomL3 §2: ``` `F16GeomL2.m:119` `LE_sweep_vt = 40` `[Brandt Main!H20]` ``` | `[Brandt Main!H21]` |

**Already corrected in this documentation pass — do not re-edit:**
`docs/geometry_parameter_usage.md` (the cross-tier table now cites `Main!B20` = taper,
`Main!B21` = sweep, `Main!B22` = NACA/t-c, each flagged "citation corrected") and this file.

**Checked and CLEAN — no row-20/21/24 citation exists, do not touch:**
`VnV/BrandtF16A/readme_geom.md`; `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` (cites only
`Main!C18`/`H18` for areas, both correct); `VnV/BrandtF16A/GroundTruth/f16a_geometry.json:24,37,98`
(cites *ranges* `Main!B18:B27`/`C18:C27`/`H18:H27`, correct as ranges);
`VnV/BrandtF16A/GroundTruth/cell-map.md`; `src/disciplines/geometry/GeomL2.md`;
`examples/F16A/F16GeomL2.md`; `tests/disciplines/TestGeomL2.m:236` (cites `Main!B18`, correct);
`tests/disciplines/TestGeomL3.m`; all `*_brandt_comparison.{m,md,json}` (their `Geom!B19`/`B20`/`B21`
references are **Geom**-tab cells, unrelated to the **Main**-tab rows in question — verified live:
`Geom!B20` = Amax 25.110556, `Geom!B21` = length 48.303947).

Also correct and unchanged everywhere: `{B,C,H}18` (S), `{B,C,H}19` (AR), `B32`/`C32`/`D32`
(fuselage), and the HT/VT `tc_root`/`tc_tip` `[T.O. 1F-16A-1 Sec. I]` citations.

---

## G. Comparison-report specification

**This section is the comparison-report spec** (I chose to keep it here rather than a standalone
doc: every row's expected value and every divergence annotation is already defined above, and a
separate file would duplicate §A/§D/§E).

**Standing constraint, per CLAUDE.md's two-tier rule:** all three reports below are
**informational, never pass/fail**. No assertions, not part of `run_all_tests`, and **no value in
any of them may ever be copied back into a unit test's expected value.** A large `%Diff` is often
the correct answer and is annotated as such.

### G.1 `geometry_brandt_comparison.m` — **AS SHIPPED (2026-07-25)**

**As-shipped helper signature** (`geometry_brandt_comparison.m:280`), with the last two arguments
optional:

```
grow(name, fidelity, computed, expected, src, numfmt, notes, to_value, divergence)
  -> {'Fidelity','Computed','Brandt','PctDiff','TO','Divergence','Source','Notes'}
```

- `fidelity` — `'L1'`/`'L2'`/`'L3'`, or `'N/A'` for a quantity nothing models (`Computed` is `NaN`).
- `to_value` — optional second source (T.O. 1F-16A-1 / USAF 3-view); `NaN` or omitted → `'N/A'`.
- `divergence` — optional annotation.

**The `Divergence` column shipped as a TWO-state field, not the four-value vocabulary this section
originally specified.** As built there is only `BY DESIGN` (blank = genuine agreement check), and the
helper's own docstring defines `BY DESIGN` to cover all three of "a physical/T.O. value, or a
different formula family, or a definitionally different quantity". So the originally-specified
`agreement` / `definitional` / `n/a` labels **do not exist in the shipped report** — a
definitionally-different row and a T.O.-divergence row both read `BY DESIGN` and are told apart by
the `Notes` string. That is self-consistent, but it means "the `Amax` row is `definitional`" cannot
be expressed in the shipped schema; both `Amax` rows currently read `BY DESIGN`. **Flagged for the
coordinator** — either the vocabulary is widened or the wording is settled; not decided here.

**Objects as shipped** (`:44-47`): `prop = F16PropL2(f16a_spec_path(2))`;
`g1 = F16GeomL1(f16a_spec_path(1))`; `g2 = F16GeomL2(f16a_spec_path(2), prop)`;
`g3 = F16GeomL3(f16a_spec_path(3), prop)` — geometry now takes the injected propulsion object at
both tiers. `W_TO` = 31,377 lbf is read from `GroundTruth/f16a_geometry.json` `mission.W_TO_lb`,
deliberately **not** from `F16Baseline.m`.

**Sections as shipped:** `[WING / HT / VT WETTED AREA]` · `[FUSELAGE WETTED AREA]` ·
`[DUCT / NACELLE]` · `[EXPOSED LIFTING-SURFACE AREAS]` · `[SWEEP-ANGLE CONVERSION]` · `[TOTALS]` ·
`[OTHER GEOMETRY OUTPUTS]` · `[L3 PHYSICAL / T.O. TIER — DIVERGENCES FROM BRANDT ARE INTENTIONAL]`.

**Headline changes vs the original spec below:**

| Item | Original spec | As shipped |
|---|---|---|
| `Amax` | one row, "L2 + L3", 27.4889, +9.47 % | **two rows**: `Max cross-section Amax, L2 envelope ellipse` = **27.488936** (+9.47 % vs `Geom!B20`) and `Max cross-section Amax, L3 AREA-RULED` = **24.703652** (**−1.62 %**). The L3 row's Notes carry the round-trip control |
| aircraft length | one row "L2 + L3" | **one L3 row**, 47.65 vs `Geom!B21` = 48.303947, with `to_value` = 47.65. `L_aircraft_l2` is computed at `:135` but **never used** — an unused variable in the shipped script |
| `(Amax/l)` / `(Amax/l)²` row | specified (#42) | **not shipped**. The wave-drag consequence lives in §D.4 and in `aerodynamics_brandt_comparison.m` |
| `Divergence` vocabulary | 4 values | 2 states (see above) |
| strake rows | 2 rows "NOT MODELED" | **unchanged, still `NaN`/NOT MODELED** — strake `S_wet` vs `Geom!B15` = 39.956 and strake exposed area vs `Geom!H9` = 20.0. Notes now record that 2h *proved* the strake is worth 0.000 % of `Amax`, i.e. deferred rather than overlooked (todo §23) |
| exposed-area cell citations | `Geom!7`/`8`/`9`/`10` | unchanged shorthand. Precisely, the values live in **column H** of the `Geom!A5:I10` exposed table: `H7` 196.22607 (wing), `H8` 49.84725 (HT), `H9` 20.0 (strake), `H10` 40.88967 (VT) — all re-read live this pass |

**Live computed values for the shipped L3 rows** *(for diffing a regenerated report; never to be
copied into a unit test)*: wing `S_wet` **396.3767**, HT `S_wet` **104.0349**, VT `S_wet`
**83.1399**, fuselage `S_wet` **749.1337**, duct `S_wet` **155.5664**, total `S_wet` **1488.2514**,
HT exposed **51.1486**, VT exposed **40.8897**, `AR_ht` **3.168981**, VT QC sweep **44.629262**,
`Amax` **24.703652**, `L_aircraft` **47.65**.

---

**Original row-by-row spec, retained as the decision record.** Where it differs from the table
above, the table above is what shipped. "Expected" values are Brandt cells read from
`VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` `.geometry` (never re-derived here).

| # | Row | Fid | Computed *(live)* | Brandt | T.O. | Divergence | Note |
|---|---|---|---|---|---|---|---|
| **§ Wing / HT / VT wetted area** ||||||||
| 1–6 | existing wing/HT/VT S_wet, Roskam + Brandt-tc | L2 | 396.3767 / 392.0205, 101.3880 / 99.7793, 83.1399 / 81.7213 | B14/B16/B17 | — | `definitional` | unchanged |
| 7 | **NEW** wing S_wet at L3, Roskam Eq. 12.1 `[OFFICIAL]` | **L3** | **396.3767** | B14 = 392.0204 | — | `definitional` | +1.11 %. Roskam Eq. 12.1 vs Brandt's own uniform-t/c formula — a formula-family difference, not an error (Decision 2) |
| 8 | **NEW** HT S_wet at L3, Roskam Eq. 12.1 `[OFFICIAL]` | **L3** | **104.0349** | B16 = 99.5848 | — | **`BY DESIGN`** | +4.47 %, decomposing as +1.8 % formula family (Decision 2) and +2.6 % option-B exposed area (Decision 1). State the decomposition in the Notes |
| 9 | **NEW** VT S_wet at L3, Roskam Eq. 12.1 `[OFFICIAL]` | **L3** | **83.1399** | B17 = 81.6894 | — | `definitional` | +1.78 %, formula family only |
| 7b–9b | **NEW** wing/HT/VT S_wet at L3, Brandt uniform-t/c `[alt]` | **L3** | **392.0205 / 102.3842 / 81.7213** | B14/B16/B17 | — | `definitional` | Alternate rows kept exactly as L2 does. Wing/VT match GT to +0.00 %/+0.04 % **by construction** (Brandt's formula on Brandt's inputs) — that is not evidence of a better model; the HT's +2.81 % is the option-B exposed-area divergence showing through |
| 10 | Strake S_wet — NOT MODELED | N/A | NaN | B15 = 39.956 | — | `n/a` | unchanged |
| **§ Fuselage wetted area** ||||||||
| 11–13 | existing Roskam / Brandt low-fi / high-fi at L2 | L2 | 730.3023 / — / 676.33 | B3 / D23 | — | `definitional` | unchanged |
| 14 | **NEW** fuselage S_wet, Roskam Eq. 12.3, **L3** (`L_fus`=47.5) | **L3** | **749.1337** | D23 = 676.3289 | 47.5 ft length | **`BY DESIGN`** | +2.15 % of the gap is the L_fus 47.5-vs-46.5 choice alone |
| 15 | **NEW** fuselage S_wet, Brandt low-fi at L3 | **L3** | **746.1283** | B3 = 730.422 | — | **`BY DESIGN`** | +2.15 % vs B3 — isolates the length divergence exactly |
| **§ Duct / nacelle** ||||||||
| 16–17 | existing duct S_wet / nacelle diameter | L2 | 155.5664 / 3.5370 | B4 / Engn(s) | — | `definitional` / `agreement` | unchanged |
| 18 | **NEW** duct S_wet at L3 | **L3** | **155.5664** | B4 = 41.515 | — | `definitional` | same `L_duct`/`D_inlet`; identical to L2 |
| 19 | **NEW** nacelle diameter at L3, from **injected `prop.T_SL`** | **L3** | **3.5370** | 3.537 | — | `agreement` | positive control that Phase-3a DI reproduces the frozen value |
| **§ Exposed lifting-surface areas** ||||||||
| 20–22 | existing wing/HT/VT exposed at L2 | L2 | 196.2261 / 49.8473 / 40.8897 | Geom!7/8/10 | — | `agreement` | unchanged; all three match GT |
| 23 | **NEW** wing exposed, L3 | **L3** | **196.2261** | 196.2261 | — | `agreement` | identical inputs |
| 24 | **NEW** HT exposed, L3 (now Dependent, option B) | **L3** | **51.1486** | `Geom!8` = 49.8473 | `B_h` = 18.5 ft | **`BY DESIGN`** | **+2.611 %.** Decision 1: `B_h`=18.5 is the primary span, so `AR_ht` is derived 3.1690 and the chords are 9.5118/2.1639. Not an error — Brandt's 49.8473 rests on his derived 18.0 ft span |
| 25 | **NEW** VT exposed, L3 (now Dependent) | **L3** | **40.8897** | `Geom!10` = 40.8897 | — | `agreement` | Sweep does not enter this formula, so L3 = L2 = GT exactly (§A.4). A genuine positive control |
| 25b | **NEW** HT derived `AR_ht` | **L3** | **3.1690** | `Main!C19` = 3.0 | `B_h` = 18.5 ft | **`BY DESIGN`** | +5.63 %. `B_h²/S_ht`, definitional. Brandt's 3.0 is now a reference, not an input (Decision 1) |
| 25c | **NEW** HT span | **L3** | **18.5** | `sqrt(AR·S)` = 18.0 | 18 ft 6 in `[USAF 3-view]` | **`BY DESIGN`** | +2.78 %. The physical measurement, now primary |
| **§ Sweep conversions** ||||||||
| 26 | existing wing QC sweep | L2 | 32.1832 | 28.153 | — | `definitional` | unchanged (full-planform vs Brandt's exposed-panel definition) |
| 27 | **NEW** wing QC sweep, L3 | **L3** | **32.1832** | 28.153 | — | `definitional` | identical wing inputs |
| 28 | **NEW** VT QC sweep (single-panel form), L2 | L2 | **36.3134** | — | — | `agreement` | Phase-1b headline: was 32.24 under the mirrored form |
| 29 | **NEW** VT TE sweep (single-panel form), L2 | L2 | **22.9008** | `Main!H27` = 0 (literal) | — | `definitional` | see §F.3 — Brandt's own literal 0 contradicts his own VT planform |
| 29b | **NEW** HT QC / TE sweep, L3 (option B) | **L3** | **32.6400 / 2.5617** | `Main!C27` TE = −0.00024343 | — | **`BY DESIGN`** | L2 gives 32.1832 / −0.0002, the latter matching Brandt's HT TE cell exactly. Decision 1's derived `AR_ht`=3.1690 makes the L3 HT trailing edge slightly aft-swept. Consequence of the span choice, not an error |
| 30 | **NEW** VT QC sweep, L3 (Λ_LE = 47.5) | **L3** | **44.6293** | — | 47.5° LE | **`BY DESIGN`** | +18.75 % LE sweep divergence propagating |
| 31 | **NEW** VT TE sweep, L3 | **L3** | **34.0052** | — | — | **`BY DESIGN`** | as #30 |
| **§ Totals** ||||||||
| 32–35 | existing L1 / L2-official / L2-vs-raw-buggy / Brandt-style totals | L1, L2 | 1466.7731 (official) | 1331.134 corrected, 1371.0946 raw | — | `definitional` | unchanged. NB the L1 row now needs `g1.W_TO` set explicitly |
| 36 | **NEW** total S_wet, L3, Roskam set incl. duct `[OFFICIAL]` | **L3** | **1488.2515** | 1331.134 corrected | — | `definitional` | **+11.80 %.** NOT like-for-like: Brandt's total also carries strake 39.956 + nacelle 41.515 terms this framework has no component for, partly offset by our 47.5 ft fuselage. Must not be reported as an agreement check |
| 36b | **NEW** total S_wet, L3, Brandt-form set `[alt]` | **L3** | **1480.8261** | 1331.134 corrected | — | `definitional` | +11.25 %; same caveat as #36 |
| **§ Other geometry outputs** ||||||||
| 37 | existing `L_fus` passthrough | L2 | 46.5 | — | — | `n/a` | unchanged |
| 38 | **NEW** `L_fus` at L3 | **L3** | **47.5** | `Main!B32` = 46.5 | 47.5 `[T.O. 1F-16A-1]` | **`BY DESIGN`** | +2.15 %; the headline intentional divergence |
| 39 | existing L1 `L_fus` regression | L1 | (Raymer Table 6.3, needs `W_TO`) | — | — | `definitional` | unchanged |
| 40a | **`Amax`, L2 envelope ellipse** — was "NOT MODELED", now computed | **L2** | **27.488936** | `Geom!B20`/`H47` = **25.110556** | — | `BY DESIGN` *(shipped)* | **+9.47 %.** Different quantities: Brandt's is a whole-aircraft area-ruled max net of engine flow-through; L2's is the elliptical fuselage envelope, correctly the low-fidelity form (§D.3). Uncited identity, todo §4 |
| 40b | **`Amax`, L3 AREA-RULED** *(sub-step 2h)* | **L3** | **24.703652** | `Geom!B20`/`H47` = **25.110556** | — | `BY DESIGN` *(shipped)* | **−1.62 %.** Same quantity, same formula family now — the gap is entirely L3's 47.5 ft fuselage. ROUND-TRIP CONTROL in the Notes: at `L_fus` = 46.5 this returns 25.110534, −0.0001 %. §D |
| 41 | **Overall aircraft length — was "NOT MODELED", now an input** | **L3** | **47.65** | `Geom!B21` = **48.303947** | 47 ft 7.75 in = 47.6458 `[published airframe length; unsourced in repo — todo §6 OPEN]` | `BY DESIGN` *(shipped)* | **−1.35 %.** **Not comparable quantities:** ours is a spec dimension, Brandt's is a `MAX()` over his x-station columns — an *extent*. Said so in the Notes. (`L_aircraft_l2` is computed but unused in the shipped script) |
| 42 | `Amax/l` and `(Amax/l)²` | — | — | — | — | — | **NOT SHIPPED.** Superseded numerically anyway: as built the term is **−0.54 %**, not +23.15 %, and `E_WD` = 2.2 needs no retune (§D.4) |

Rows **8, 24, 25b, 25c, 29b, 30, 31, 38, 40a, 40b, 41** are the **intentional divergences**, and all
carry `BY DESIGN` in the shipped report — they trace to Decision 1 (`B_h` primary), to the locked
physical/T.O. values (VT Λ_LE 47.5, `L_fus` 47.5), to the Decision-2 formula family, or to a
definitionally different quantity. Rows **19, 23, 25, 28** are the **genuine agreement checks**
(blank `Divergence`) and double as positive controls that the L3 rewrite did not disturb validated
geometry — in particular row 25 (VT exposed area) is bit-identical to L2 and to `Geom!H10` because
the exposed-area clip has no sweep term. The strake rows stay `N/A` / `NaN`.

### G.2 `aerodynamics_brandt_comparison.m` — **DONE (repointed)**

- **As shipped** (`:59-68`): `prop = F16PropL2(…)`, `g2 = F16GeomL2(f16a_spec_path(2), prop)`,
  **`g3 = F16GeomL3(f16a_spec_path(3), prop)`** — the L3 aero rows now receive L3 geometry, so
  `f16a_L3.json`'s `.geometry` block is no longer dead input. The old "geometry has no separate L3
  tier" header comment is gone.
- Every L3 row shifts, driven by: VT Λ_LE 47.5 (Eq. 12.30 VT form factor), `L_fus` 47.5 (fuselage Re
  + `S_wet` 749.1337 vs 730.3023), the HT/VT root-tip t/c means (0.0475/0.0415 — unchanged in value
  from L2, so no shift from that term), and — under Decisions 1 and 2 — the HT column of every
  component array: `S_wet_comp(2)` 101.39 → **104.0349**, `l_ref_comp(2)` (HT MAC) 6.7921 →
  **6.608537**, `Lambda_m_comp(2)` 28.6086 → **29.2956°**.
- **The wave-drag footnote this section originally demanded is now the wrong footnote.** With the
  area-ruled `Amax`, the Eq. 12.44 term is **−0.54 %** against the Brandt-referenced pair, not
  +23.15 %, and **`E_WD` = 2.2 is unchanged and needs no retune** (§D.4). Any note should say that,
  and should *not* print 1.7864 as if it applied to L3. `E_WD` is still flagged
  `_TODO_wave_drag_factor_E_WD` on its own merits.
- The multi-source column set (`Brandt` / `AFManual` / `Internet`) already exists here — no schema
  change needed.

### G.3 `propulsion_brandt_comparison.m` — add L3-condition rows, labelled

- Add the L3 flight conditions as new rows, each with `Fidelity = 'L3'` **and** a `Notes` string
  that says verbatim: *"computed by `F16PropL2` — there is no L3 propulsion tier (locked decision
  2026-07-25); L2 propulsion is the L3 rung."*
- The existing schema `{'Fidelity','Computed','Brandt','PctDiff','OtherSource','Source','Notes'}`
  already carries a second-source column; no change needed.
- `F16ConstraintSet.buildDisciplines` keeps `prop = F16PropL2(f16a_spec_path(2))` at the L3 rung;
  its comment must say that plainly instead of "no `F16PropL3` exists yet".

### G.4 Regeneration mechanics

Run all reports via `matlab -batch`, **not** the MATLAB MCP tools — the wide-table `disp` in these
scripts hangs the MCP session (recorded in memory). Diff the regenerated `.md` against the committed
version so every shifted number is accounted for.

---

## H. Deviations, limitations, open items

Every item is logged in `VnV/BrandtF16A/todo.md` (2026-07-25 Phase 2). **RESOLVED** items carry a
user decision and are settled for implementation; **OPEN** items remain user-review items the
implementation gate must not resolve on its own.

**RESOLVED / DONE:**

1. ✅ **The deferred red test HAS CLEARED.**
   `TestF16ConstraintSet/testOptimalPointWithinPhysicsBounds(L3)` now passes: the L3 optimum is
   **W/S = 62.0000 psf, T/W = 0.998975** *(live)*, inside not only the widened 1.1 bound but the
   **original 1.0** one — which makes the earlier 1.0 → 1.1 widening retrospectively unnecessary.
   **Whether to narrow the bound back to 1.0 is an OPEN user decision; it was NOT narrowed, and no
   test file was touched.** (todo §17, re-statused RESOLVED this pass.)
2. ✅ **HT exposed-area basis → option B** (`B_h` primary, `AR_ht` derived 3.168981,
   `S_exposed_ht` = 51.1486). §A.4 / todo §7. `S_exposed_vt` confirmed unable to diverge.
3. ✅ **L3 `S_wet` family → Roskam Vol. II Eq. 12.1 official**, Brandt uniform-t/c as an alternate
   report row. §A.5 / todo §8.
4. ✅ **Brandt cell citations — APPLIED**; §F is the authoritative reference. Zero computed values
   changed, as predicted. todo §1, §2.
5. ✅ **Reuse gaps closed** (todo §12): `GeometryBase.compute_Amax_elliptical` and
   `GeometryBase.compute_nacelle_diameter` are now cited statics on the fidelity-independent base,
   called by both tiers — no duplicated magic number. Sub-step 2h added
   `GeomL3.compute_c_root_exposed`, which `GeomL3.m:425-434` itself flags as *belonging* in `GeomL2`
   beside the two exposed-area statics it was extracted from (out of that sub-step's editable scope).
6. ✅ **Ground-truth workbook integrity — CONFIRMED STILL RECORDED AS VERIFIED INTACT.** todo §14
   documents the coordinator's `readmatrix` diff of the working-tree `Brandt-F16-A.xls` against
   `git show HEAD:` across all seven cited tabs (Main, Geom, Aero, Wt, Engn(s), Consts, Miss):
   **every numeric cell identical**, binary differs only in Excel metadata. Re-checked this pass and
   the entry is unchanged. The file still shows as `M` in `git status`; the **hygiene** decision
   (restore or commit) remains the user's — do not restore it unilaterally.

**OPEN — user review required:**

7. ⬜ **Mixed provenance of the full-planform tails.** L3 carries Brandt's `S_ht`/`S_vt`/`lambda`
   next to T.O. LE sweeps (VT 47.5°) and a T.O./USAF `B_h`. Decision 1 reduces but does not remove
   this: `AR_ht` is now derived from the physical span, yet `S_ht`=108 is still Brandt's and
   `AR_vt`/`lambda_vt` are still Brandt's. Standing item: obtain T.O. full-planform tail values.
   (todo §3)
8. ⬜ **The `Amax` citation gap — now SPLIT in two, both still open** (todo §4, split this pass):
   (a) the **L2** envelope-ellipse identity `(π/4)·W·H`, documented as a standard identity per the
   `convert_sweep` precedent; (b) the **L3** affine frame-rescaling assumption *and* Brandt's cosine
   area-distribution model, neither of which traces to any reference extract in this repo. The one
   lead is Roskam **Part VI**, named by the repo's own Roskam Vol. II extract as the area-ruling
   authority and **not present in this repo**. §D.6.
9. ⬜ **The `/5` flow-through divisor** — a bare literal, with a live-verified *absence* of any
   justification anywhere in the workbook, while `readme_geom.md` §4.5 uses `π·D²/4` for the same
   nacelle's own cross-section. As built, `/4` would give `Amax` = 22.738503 (−7.95 %) and make
   `Amax` thrust-insensitive. (todo §5) §D.6.
10. ⬜ **Frame-area discretization: 6-point vs exact.** Brandt's 6-point cosine sampling was taken
    (`I_cos` = 0.63137515 vs 2/π = 0.63661977, uniformly 0.824 % low). Switching to
    `compute_frame_cs_area_exact` is a one-line change worth +0.759 % on the as-built `Amax`.
    **Confirm or switch.** (todo §20 — index row added this pass) §D.7.
11. ⬜ **`engine.n_engines` sits in `.geometry`** only because nothing on the propulsion side exposes
    an engine count. It is engine data and should migrate to `.propulsion` + DI, exactly as
    `T_AB_SLS_lb` already did. (todo §22, new this pass) §A.1b #39.
12. ⬜ **Strake DEFERRED**, with two report rows still "NOT MODELED": strake `S_wet` = 39.956
    `[Brandt Geom!B15]` and strake exposed area = 20.0 `[Brandt Geom!H9]`. Justified by those two
    rows and by removing configuration-dependence — **not** by any `Amax` benefit, which is provably
    nil. Cost: 7 new inputs `[Main!D18:D24]` plus the "root fully outside the fuselage" special case.
    (todo §23, new this pass) §D.7.
13. ⬜ **Stale in-code comments on `F16AeroL3.m`.** `:226-237` still describes `Amax_ft2` as
    "`(pi/4)*W_max*H_max` … 27.4889 … envelope ellipse", and `:293-300` still prints the
    "+23.15 % / `E_WD` would need 1.7864" story. Both predate sub-step 2h and are wrong for an
    injected `F16GeomL3` (§D.4). Docs-only pass — not edited.
14. ⬜ **`F16GeomL3.m` disagrees with itself on its own property counts.** The property-block banners
    say "33 numeric … spec values" (`:168`) and "34 quantities" (`:251`); the class header correctly
    says 38 and 45 (`:35-40`). Only the header is right (§A). Docs-only pass — not edited.
15. ⬜ **The comparison report's `Divergence` column shipped as a two-state field**
    (`BY DESIGN` / blank), not the four-value vocabulary §G.1 originally specified — so
    "`definitional`" cannot be expressed and both `Amax` rows read `BY DESIGN`. Coordinator item.
    Also `L_aircraft_l2` is computed but unused (`geometry_brandt_comparison.m:135`).
16. ⬜ **`L_aircraft` = 47.65 is unsourced in-repo.** The *value* stands as the user's decision; the
    *provenance* is a standing item. Brandt's 48.304 is an extent, not a comparable spec length.
    (todo §6, deliberately kept open; guarded by `TestGeomL3.testTODO_OverallLengthCitationNotPinned`)
17. ⬜ **Nacelle x-range, `Geom!H3` semantics and the `1900` magic number.** The live chain
    `[15.0, 44.9166]` was implemented; `BrandtGeometry.m` / `readme_geom.md` §4.5 use
    `[14.0, 43.9166]` (both endpoints 1.0 ft low via the mislabelled `inlet_x_ft` key).
    `GeometryBase.compute_nacelle_diameter` hardcodes 1900 unconditionally, which silently assumes an
    afterburning engine (`Engn(s)!L22` = 1900 AB vs `L10` = 2000 dry). (todo §18)
18. ⬜ **`GeometryBase.md` is missing `convert_sweep_panel`** — Phase 1b added the static but not its
    doc row, and the `.m` points at a nonexistent "Sweep-angle conversion" section. (todo §13)
19. ⬜ **`f16a_ground_truth.json` `.geometry._comment` is stale**: it cites deleted
    `geometry_L*.json` files and asserts "Geometry's L3 tier was eliminated 2026-07-22". (todo §10)
20. ⬜ **The same fuselage depth is keyed `max_height_ft` at L2 but `max_depth_ft` at L3.** Same
    value, same citation, same target property — a live trap for shared JSON-reading code. (todo §15)
21. ⬜ **`readme_geom.md` §7's low-fidelity `Amax` row has no cell backing**, and says "cylindrical"
    (`π·(D_fus/2)²` = 28.2743) where L2 computes the *elliptical* 27.4889. (todo §19) §D.3.
22. ⬜ **`L_t = 22.0`, `S_cs = 190`, `S_csw = 68.03`, `S_r = 11.65`, `H_t`/`H_v`** remain `[estimate]`
    inputs. `L_t` is still not derivable — the wing/HT apex x-stations are now inputs (§A.1b) but the
    MAC y-station is not. (todo 2026-07-24 GeomL3 §6, unchanged)
23. ⬜ **Informational, no action:** Brandt `Main!H27` VT TE sweep = literal 0, inconsistent with his
    own VT planform — recorded so nobody reverts the 22.90° fix. (todo §9)

## I. Citations used in this document

- Span `b = sqrt(AR·S)` — definitional (`GeometryBase.compute_span`).
- Root chord / tip chord / MAC — Raymer 7th ed. Eq. 7.6 / 7.7 / 7.8 (`GeometryBase`).
- Sweep-station conversion, mirrored `4/AR` and single-panel `2/AR` — standard swept-wing planform
  identity, **uncited to an edition/equation number** (`src/base/GeometryBase.md`, RESOLVED
  2026-07-21 user decision).
- Exposed lifting-surface clip — Brandt F-16A workbook; `VnV/BrandtF16A/readme_geom.md` §4.3.
- Lifting-surface `S_wet` — Roskam Vol. II Eq. 12.1 (variable root/tip t/c) and Brandt `Geom!B13`
  (uniform t/c).
- Fuselage `S_wet` — Roskam Vol. II Eq. 12.3; Brandt low-fi `Geom!B3` / high-fi `Geom!D23`.
- Duct `S_wet` (frustum) — Raymer §7.3.
- Exposed root chord (linear-taper interpolation) — Brandt `Geom!F7`/`F8`/`F10`; `readme_geom.md`
  §4.3 (`GeomL3.compute_c_root_exposed`).
- Nacelle diameter `sqrt(T_AB/1900)` — Brandt `Geom!C475`; `Engn(s)!L22` = 1900 (AB) / `L10` = 2000
  (dry); `readme_geom.md` §3.
- Engine length `4.5·D` — Brandt `Geom!D475 = C475 · 'Engn(s) Old'!Q22`, `Q22 = ='Engn(s)'!R22` =
  4.5. A slenderness ratio, **no textbook equation number claimed** (todo §18).
- **`Amax`, L2** — `(π/4)·W·H`: **no equation number known**; standard elliptical-cross-section
  identity (todo §4a).
- **`Amax`, L3 (area-ruled)** — Brandt `Geom!H26:H45 → H47 → B20`; `readme_geom.md` §§4.2/4.5.
  Component pieces: fuselage cosine frame section §4.2; lifting-surface `(1 − cos 2πξ)` distribution
  §4.5 (`Geom!Y`/`AA`/`AC` columns); nacelle `Geom!AE31`; deduction `Geom!H47`. **Brandt's own
  construction — no textbook equation number exists for the area-distribution model, the affine
  frame rescaling, or the `/5` divisor** (todo §4b, §5). Lead only: Roskam **Part VI**, named by
  `roskam_vol2_data.md:22` as the area-ruling authority and not in this repo.
- Wave drag — Raymer 6th ed. Eq. 12.44 (Sears-Haack) + Eq. 12.45 (E_WD / sweep / Mach correction).
- Component drag buildup / form factors / Re — Raymer Eq. 12.24 / 12.30 / 12.31 / 12.25.
- Weights consumers — Raymer 6th ed. §15.3.1 Eqs. 15.1–15.4 (see `F16WeightsL3.md`).
- Brandt cells `Main!B18-B23`, `C18-C23`, `H18-H23`, `B27`/`C27`/`H27`, `B28`, `B32`/`C32`/`D32`,
  `F31`/`F32`, `A34:F53`, `Geom!A20`/`B20`/`A21`/`B21`/`H47`, `Geom!A5:I10` (exposed table,
  values in column **H**), `Geom!B14`–`B17`, `Geom!AE31`, `Geom!C475`/`D475`, `Geom!C480`–`C484` —
  **read live over Excel COM 2026-07-25** (values and formulas quoted verbatim in §D/§F).
