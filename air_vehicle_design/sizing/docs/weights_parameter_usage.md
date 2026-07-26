# Weights parameter usage

**STATUS: AS-BUILT (reconciled 2026-07-25, step 2d).** This document previously described the state the
weights discipline had to *reach* in Phase 4; everything below now describes **what shipped**. Rows
still marked `AS-IS` describe the **pre-Phase-4** code and are kept only where the delta is worth
keeping traceable — read them as `WAS`. `run_all_tests` at the time of writing: **491/501, all 10 reds
labelled `testTODO_`, zero unlabelled reds.**

All **six settled user decisions of 2026-07-25** (Part A.2) are implemented — L3 engine weight
uninstalled, `SFC_mission` by DI at cruise, `V_t` restored as an input, `W_l = 0.95·W_TO`, the new
`f16a_requirements.json`, and `K_d` left unchanged and **unguarded**. The items still **OPEN** are
§P4-4, §P4-5b, §P4-7, §P4-11, §P4-13, §P4-14 and §P4-16; none of them has been quietly closed here.

Which weight quantity is produced at which fidelity level, by which function, under what citation;
the geometry→weights and propulsion→weights DI maps; and the Brandt ground-truth values the
`weights_brandt_comparison` report targets. Companion per-class docs:
`examples/F16A/F16Weights{L1,L2,L3}.md` (the comparison-report documentation lives in
`F16WeightsL2.md` §G; the artefacts are `examples/F16A/weights_brandt_comparison.{m,json,md}`).
Step-level as-built summary: `docs/subplans/05_weights.md`. Sibling docs:
`docs/geometry_parameter_usage.md`, `docs/propulsion_parameter_usage.md`. Open items and every
discrepancy logged: `VnV/BrandtF16A/todo.md` 2026-07-24 Weights §3a/§3b/§3c, 2026-07-25 Phase 4
§P4-0 … §P4-17, and the 2026-07-25 **Phase 4 AS-BUILT re-status** (§P4-18 … §P4-22).

All values marked *(live)* were computed 2026-07-25 via `mcp__matlab__evaluate_matlab_code` against
the as-built classes. All Brandt `Wt!` cells below were read **directly from
`VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls`** over Excel COM (`actxserver`, read-only, closed
without saving) on 2026-07-25 — not copied from a `.md`. Table values are transcribed from named repo
extracts with `file:line`.

> **Edition-label caveat.** Code and `temp_AI/docs/disciplines/reference_extracts/raymer_data.md`
> cite **Raymer 6th ed.** (§15.3.1 Eqs. 15.1–15.24, book pp.572–573 / PDF pp.602–603; Table 15.2 via
> the metabook; Table 3.1 via the metabook). CLAUDE.md's citation style and the propulsion pass use
> **Raymer 7th ed.** Locked decision: Phase 4 **re-cites §15.3.1 to Raymer 7th ed.** with no value
> change (todo 2026-07-24 §3a). Rows below are labelled with the *target* edition.

---

## Part A — Downstream consumers and the sizing-loop contract

`OEW(W_TO)` is the only weights output the constraint analysis / (future) mission + sizing loop read.
The per-component `weight_*` methods are used by the unit tests and the comparison report.

`WeightsBase` declares the closure identity
`W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable`.

| Quantity | Kind | Set by | Value | Citation |
|---|---|---|---|---|
| `W_TO` | mutable **input** (state) | sizing loop, on the object | `NaN` until set | `WeightsBase` contract |
| `W_energy` | mutable **input** (state) | mission analysis, on the object | `NaN` until set | `WeightsBase` contract. **Phase 3 deleted the 6296.3 default from the JSONs** — `Brandt Wt!B6` is `=B3-B4-B5-B12` *(live formula)*, i.e. a back-calculated **output**, forbidden as an input |
| `W_payload_fixed` | **input** | JSON `.weights` | **700** | `[Brandt Wt!B4 = 700.000000 (live), formula =Main!O16]` |
| `W_payload_expendable` | **input** | JSON `.weights` | **4400** | `[Brandt Wt!B5 = 4400.000000 (live), formula =Main!O17]` |

Closure sanity, computed live: `31377 − 19980.70 − 6296.30 = 5100.00 = 700 + 4400`. The payload split
closes Brandt exactly.

> **Still true as built (flag, not fix):** no `WeightsL{1,2,3}` static reads `W_energy`, `W_payload_fixed` or
> `W_payload_expendable` (verified by grep, 2026-07-25 — zero matches in `src/disciplines/weights/`).
> They exist only to satisfy the `WeightsBase` abstract block; the closure identity is not enforced
> anywhere yet. That is correct for now (the sizing loop does not exist), but it means the payload
> values are currently inert.

---

## Part A.1 — INPUT / DERIVED counts per level — AS BUILT

All counts below were taken live 2026-07-25 from the metaclass `PropertyList`
(`sum(~[pl.Dependent])` / `sum([pl.Dependent])`), not from `numel(properties(...))`, so injected
objects and read-only derived properties are counted correctly. Per-row detail:
`examples/F16A/F16Weights{L1,L2,L3}.md` §B.

| Level | **AS-BUILT plain / Dependent** | INPUTS | DERIVED | Injected objects | Reads requirements | Deleted | `WAS` plain / Dependent |
|---|---|---|---|---|---|---|---|
| L1 | **5 / 0** | **5** (4 numeric + `aircraft_category`) | **0** | none | **no** | 0 | 5 / 0 — no property changed kind. Nothing derivable is stored at L1 and `WeightsModelL1` declares no abstract properties, so 0 derived is correct: the two regressions stay methods on the contract. `WeightsL1` needs neither Mach nor a flight condition. `W_energy` 6296.3 → `NaN` and payload 220/0 → 700/4400 are value changes only |
| L2 | **9 / 12** | **7** (6 numeric + `aircraft_category`) | **12** | 2 (`geom` = `F16GeomL2`, `prop` = `F16PropL2`) | **`design_mach`** | 0 | 17 / 0 — 11 of the 17 moved: 4 geometry constants + `W_en` → DI-derived; 4 NaN placeholders + 2 constructor-frozen → `Dependent`. Added input: `design_mach`. Added derived: `W_en_brandt` alternate |
| L3 | **45 / 31** | **43** (42 numeric + `aircraft_category`) | **31** | 2 (`geom` = **`F16GeomL3`**, `prop` = `F16PropL2`) | **`design_mach`, `cruise.altitude_ft`, `cruise.mach`** | **2** (`AR_ht`, `lambda_ht` — dead, §B.4) | 72 / 0 — **32 of the 72 moved**: 23 geometry literals (21 → DI, 2 deleted) + 2 propulsion literals (`T_max`, `W_en`) + 5 NaN placeholders + `W_l` + `SFC_mission`. Added inputs: `cruise_altitude_ft`, `cruise_mach`, `aircraft_category`. Added derived: `W_en_brandt` |

Note the plain-property columns: **45 = 43 inputs + 2 injected objects** at L3, and
**9 = 7 inputs + 2 injected objects** at L2. The injected `geom`/`prop` are plain properties but are
**not numeric spec data**, so they are counted separately everywhere in these docs.

Derived breakdowns, as built:

- **L2 (12):** `S_w`, `S_ht`, `S_vt`, `S_wet_fus` (geometry DI); `W_en`, `W_en_brandt` (propulsion DI);
  `W_wings`, `W_tail`, `W_fuselage`, `W_landing_gear`, `W_installed_engine`, `W_all_else_empty`
  (group/component totals).
- **L3 (31):** 21 geometry-by-DI + `T_max` (propulsion DI) + `W_en` + `W_en_brandt` + **`W_l`** +
  **`SFC_mission`** + 5 group totals (`W_wings`, `W_tail`, `W_fuselage`, `W_installed_engine`,
  `W_subsystems`).

`OEW(W_TO)` stays a **method** at every level — the `WeightsBase` contract passes `W_TO` as an
argument, so it recomputes per call and cannot go stale. The inputs-vs-`Dependent` rule governs
*stored* derived state.

### Part A.1.1 — where `requireWTO` is applied, and the principle behind it

**A guard must encode a real dependency, not a house style.** As built:

| Level | Guarded (throws `…:WTONotSet` on unset `W_TO`) | NOT guarded, and why |
|---|---|---|
| L2 | `W_landing_gear` (`0.033·W_TO`), `W_all_else_empty` (`0.17·W_TO`) | `W_wings`, `W_tail`, `W_fuselage` — their toolbox methods declare the `W_TO` argument as `~`; pure area × density (Raymer Table 15.2 psf). `W_installed_engine` — a thrust correlation, `W_TO`-independent |
| L3 | the five that genuinely carry `W_dg`/`W_l`: `W_wings`, `W_tail`, `W_fuselage`, `W_subsystems`, `W_l` | `W_installed_engine` — `WeightsL3.weight_engine_section` declares its second argument as `~`; built from thrust and component geometry, never from gross weight |

An earlier Phase-4 revision over-guarded at both levels: at L2 it routed five of the six group getters
through `requireWTO` "for uniformity", with a `requireWTO` docstring claiming the guard applied
"UNIFORMLY to all six" — untrue twice over (it was five, since `W_installed_engine` was never guarded,
and three of the five have no `W_TO` dependence at all). L3 carried the same over-guard on
`W_installed_engine`. Both were withdrawn. Recorded so the reasoning is not re-invented:
todo 2026-07-25 Phase 4 §P4-18.

---

## Part A.2 — The six settled decisions (user, 2026-07-25) — all previously-open items closed

Recorded here as the single index; each is worked through in the section named.

| # | Item | Decision | Section | Numeric effect *(live)* |
|---|---|---|---|---|
| 1 | L3 engine weight | **UNINSTALLED** Eq. 10.10 = 2775.0210 lbf. `×1.3` stays at **L2 only**. Brandt's `0.199·T_AB` alternate gets **no** `×1.3` | D.4, F.3 | L3 engine group 3639.26 → **3381.70** (−257.57). Moves L3 **further** from Brandt (−21.40 % vs −17.19 % for the rejected `×1.3`) — the closer agreement was the reason to **distrust** `×1.3`, not to keep it |
| 2 | `SFC_mission` | **DERIVED by DI**: `prop.get_TSFC(cruise state)`, cruise from the requirements file. Divergence from Brandt accepted by decision | C.1, D.5 | **1.007116** 1/hr vs Brandt `Main!C30` 0.70 → **+43.87 %**. Fuel system 386.79 → **423.47** lbf (+36.67) |
| 3 | `V_t` | **RESTORED as a JSON input**, 940 gal. Provenance warning kept: the 6.7 lb/gal density behind it is cited **nowhere** in the repo | D.5 | none (940 retained) |
| 4 | `W_l` | **DERIVED**: `W_l = 0.95 · W_TO`. The 0.95 factor came from the user and has **no repo citation** — logged open | D.5, F.3 | LG total 1057.27 → **1160.93** (+103.66, +9.81 %). Also fixes a *newly found* frozen-under-mutation bug (F.5) |
| 5 | Cruise condition + design Mach | **NEW `examples/F16A/f16a_requirements.json`**, not per-fidelity. Revives PLAN.md's never-built Step-0 `requirements.json` (`PLAN.md:178`). **Do NOT inject an `AircraftState`** — weights reads the numbers and builds the state itself | A.3 | resolves Eq. 10.10's Mach (was §P4-3) |
| 6 | `K_d` | **NO CHANGE this phase.** `K_d = 0` remains a legal input that silently zeroes a 227.54 lbf component. §P4-11 stays **open** | G | none |

Also landed: `bypass_ratio` added to `F16PropL2` (§P4-2 **resolved**; `isprop` = 1, live-verified);
`AR_ht`/`lambda_ht` confirmed dead and **deleted** (§P4-6 **resolved**); `LG_fraction` 0.033's citation
corrected to the metabook §7 fraction table `metabook_data.md:330`, **not** Raymer Table 15.2 (§P4-7
**partly** — the uncited GA 0.057 row and the missing `navy_fighter` 0.045 row are still open); the
Roskam Table 2.15 correction folded into `F16WeightsL1.md` (§P4-8 **partly** — Raymer Table 6.1 remains
a standing guarded red); `WeightsModelL3.W_subsystems`' false "includes landing gear" comment corrected
(§P4-10 **resolved**); `f16a_L3.json .weights._note`'s false category-lookup claim corrected (§P4-9
**resolved**); `f16a_ground_truth.json`'s stale payload-divergence note corrected (§P4-12 **resolved**,
with one residual stale sentence — §P4-21).

---

## Part A.3 — `examples/F16A/f16a_requirements.json` — NEW input file, AS BUILT

**This partly revives PLAN.md's Step-0 `requirements.json`.** `docs/PLAN.md` used to record that
two-file model (`requirements.json` + `aircraft_spec.json`) as *never built*; that line is **corrected
as of 2026-07-25** — the requirements half now exists. The `aircraft_spec.json` half was **not**
revived: spec data stays in the unified per-level `f16a_L{1,2,3}.json`.
*(CLAUDE.md's `sizing/` section still carries the older "was never built" wording — a doc that this
step does not own; flagged for the coordinator.)*

Shipped as a **minimal** first version — only what weights needed. The full requirement set arrives
with constraint and mission analysis, at which point this becomes the most cross-cut input file in the
repo.

**Not per-fidelity-level**: requirements do not vary with fidelity, so there is one file, not three —
hence no `_L{1,2,3}` suffix and no `level` argument on the resolver.

Files as built:

| File | Content |
|---|---|
| `examples/F16A/f16a_requirements.json` | `cruise.altitude_ft` = 36000, `cruise.mach` = 0.87, `design_mach` = 2.0, plus `_comment`/`_cite`/`_src`/`_design_mach_src`/`_TODO_design_mach` comment keys following the `f16a_L*.json` convention |
| `examples/F16A/f16a_requirements_path.m` | Resolver, `fullfile` on `mfilename('fullpath')`, **no `level` argument** — mirrors `f16a_spec_path(level)` otherwise. **Recommendation 1 of the earlier revision: DONE** |

**Recommendation 2 of the earlier revision — the scope guard — DONE.** The shipped `_comment` opens
with an explicit `★ SCOPE GUARD` stating that the file holds **REQUIREMENTS ONLY, never SPEC DATA**
(reference areas, AR, taper, sweep, t/c, fuselage envelope, thrust, engine model stay in
`f16a_L{1,2,3}.json`), and says why: the file is fidelity-independent and will grow, so one spec value
migrating in would spread everywhere. `f16a_requirements_path.m`'s own docstring repeats the
requirements-vs-spec distinction.

### A.3.1 Reads

| Requirement key | Value | Read by | Feeds | Citation |
|---|---|---|---|---|
| `design_mach` | **2.0** | `F16WeightsL2`, `F16WeightsL3`, **`F16GeomL1`** | Raymer Eq. 10.10 `M^0.25` (`W_en`, both weights levels); Eq. 15.3 `M^0.341` (VT); Eq. 15.17 `M^0.003` (flight controls); **`[Raymer 7th ed. Table 4.1]` `AR_eq`** at `F16GeomL1` (its `M_max` property) | `[Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9]` — **see A.3.2** |
| `cruise.altitude_ft` | 36000 | `F16WeightsL3` | builds the `AircraftState` for `SFC_mission` | `[Brandt Consts! row 24; f16a_ground_truth.json .propulsion.thrust_lapse_at_constraint_conditions cruise row, live-verified 2026-07-24]`. Corroborated in-repo by `examples/F16A/Constraints.xlsx` sheet `Requirements`, column C: `C2` = 36000, `C3` = 0.87, `C5` = 0 %AB |
| `cruise.mach` | 0.87 | `F16WeightsL3` | same | same |

Constructor signatures as built: `F16WeightsL2(json_path, req_path, geom, prop)`,
`F16WeightsL3(json_path, req_path, geom, prop)` and **`F16GeomL1(json_path, req_path)`** — every
argument required, no silent default, per CLAUDE.md. `F16WeightsL1(json_path)` is single-argument: L1
needs no requirement.

★ **`F16GeomL1` is a consumer as built, not pending.** `F16GeomL1.m:64` takes `req_path` and `:90` sets
`obj.M_max = R.design_mach`, replacing the deleted `f16a_L1.json .geometry.M_max`. The shipped
`f16a_requirements.json` `_comment` still says *"★ F16GeomL1 IS PENDING … F16GeomL1.m:79 must be
repointed here"* — **that sentence is now stale**; it describes work that has landed. Flagged (a `.json`
edit, outside this documentation step): todo 2026-07-25 Phase 4 §P4-20.

### A.3.2 The `design_mach` citation — a mis-attribution to avoid, STILL OPEN

**Do not cite `design_mach` = 2.0 to the T.O.** An earlier decision message cited it as
*"[T.O. 1F-16A-1 Mach 2.05 limit]"*. The repo distinguishes the two:

| Quantity | Value | Repo location | Source |
|---|---|---|---|
| Brandt's design max Mach | **2.0** | `GroundTruth/f16a_geometry.json:9` (`"Mmax": 2.0`); as built the **only** framework copy is `f16a_requirements.json .design_mach` (the former `f16a_L1.json .geometry.M_max` and `f16a_L3.json .weights.vertical_tail.M_design` are both deleted) | Brandt `Main!` aircraft input |
| T.O. operating **Mach limit** | **2.05** | `GroundTruth/f16a_ground_truth.json:228` — `"Mach_limit": {"value": 2.05, "_source": "T.O. 1F-16A-1 operating limits."}` | T.O. 1F-16A-1 |

2.0 ≠ 2.05 (−2.44 %). Citing 2.0 to the T.O. would attribute a Brandt input to a primary document
that says something else. As built the value **is** cited to Brandt, with the T.O. limit named as a
*corroborating but different* figure and a `_TODO_design_mach` marker key carrying the whole argument.
Sensitivity, computed live: Eq. 10.10's `M^0.25` gives `W_en` = 2775.0210 at M = 2.0 vs **2792.2046** at
M = 2.05, i.e. **+0.62 %** (L3 `OEW` 15705.33 → 15725.41) — numerically minor, which is exactly why the
citation must not be allowed to drift. **todo 2026-07-25 Phase 4 §P4-13 stays OPEN**: the user must
confirm which figure is the design requirement, and the `_TODO_design_mach` key comes out then.

### A.3.3 Duplicates the requirements file resolved — and the one it did not

| Key | Location | As built |
|---|---|---|
| `M_design` | `f16a_L3.json .weights.vertical_tail.M_design = 2.0` | **DELETED.** `F16WeightsL3` reads `design_mach` from the requirements file, which also feeds Eqs. 15.17 and 10.10 — it was never a vertical-tail-only input. (Decision 5.) |
| `M_max` | `f16a_L1.json .geometry.M_max = 2.0` | **DELETED too, better than planned.** `F16GeomL1(json_path, req_path)` now reads `design_mach` from the requirements file for `[Raymer 7th ed. Table 4.1]` `AR_eq`. So the design Mach has **one** source as built, not three. **§P4-14 nonetheless stays OPEN** as the broader item: the full requirements consolidation (every requirement-like value across constraints and mission) has not been done, and the requirements JSON's own `_comment` still describes `F16GeomL1` as pending (§A.3.1, §P4-20) |

---

## Part B — Geometry → weights DI map — AS BUILT

`WAS`: **no DI at all.** `F16WeightsL2` carried 4 geometry constants and `F16WeightsL3` carried 22 as
its own hardcoded literals (review finding #11). **As built:** a geometry object is injected and every
row below is a `Dependent` getter reading `obj.geom.<member>`, recomputed live on every read.

### B.1 — L2 injects `F16GeomL2`

Constructor as built: `F16WeightsL2(json_path, req_path, geom, prop)` — all **four** required
(matching the `F16GeomL2(json_path, prop)` / `F16AeroL2(geom, path)` precedent: no silent default).

| Weights symbol | Consumer | `geom` member on `F16GeomL2` | Value *(live)* | `WAS` hardcoded | Δ |
|---|---|---|---|---|---|
| `S_w` | `WeightsL2.weight_wing` [Raymer 7th ed. Table 15.2] | `S_exposed_wing` | 196.2261 | 196.23 | −0.0020 % |
| `S_ht` | `WeightsL2.weight_tail`.HT | `S_exposed_ht` | 49.8473 | 49.85 | −0.0054 % |
| `S_vt` | `WeightsL2.weight_tail`.VT | `S_exposed_vt` | 40.8897 | 40.89 | −0.0007 % |
| `S_wet_fus` | `WeightsL2.weight_fuselage` | `get_S_wet_fuselage()` | **730.3023** | **750** (`[estimate; verify TO]`) | **−2.627 %** |

### B.2 — L3 injects `F16GeomL3`

Constructor as built: `F16WeightsL3(json_path, req_path, geom, prop)`, all four required, with
`geom (1,1) GeometryModelL3`. `F16GeomL3` is the **full L3 geometry tier**
(`examples/F16A/F16GeomL3.md`); `F16WeightsL3` is its Phase-4 consumer.

| # | Weights symbol | Raymer eq. | `geom` member on `F16GeomL3` | Value *(live)* | `WAS` literal | Δ |
|---|---|---|---|---|---|---|
| 1 | `S_w` | 15.1 | `S_exposed_wing` | 196.2261 | 196.23 | −0.002 % |
| 2 | `AR_w` | 15.1 | `AR_wing` | 3.0 | 3.0 | — |
| 3 | `tc_root` | 15.1 | `tc_r_wing` | 0.04 | 0.04 | — |
| 4 | `lambda_w` | 15.1 | `lambda_wing` | 0.2275 | 0.2275 | — |
| 5 | `Lambda_LE_w` | 15.1 | `LE_sweep_wing` | 40 | 40 | — |
| 6 | `S_csw` | 15.1 | `S_csw` | 68.03 | 68.03 | — |
| 7 | `S_ht` | 15.2 | ★ **`S_exposed_ht`** — **NOT** `geom.S_ht` = 108 | **51.1486** | **49.85** | **+2.605 %** |
| 8 | `F_w` | 15.2 | `F_w` | 7.0 | 7.0 | — |
| 9 | `B_h` | 15.2 | `B_h` | 18.5 | 18.5 | — |
| 10 | `S_vt` | 15.3 | ★ **`S_exposed_vt`** — **NOT** `geom.S_vt` = 60 | 40.8897 | 40.89 | −0.0007 % |
| 11 | `AR_vt` | 15.3 | ★ **`AR_exposed_vt`** — **NOT** `geom.AR_vt` = 1.6 | 1.294 | 1.294 | — |
| 12 | `lambda_vt` | 15.3 | ★ **`lambda_exposed_vt`** — **NOT** `geom.lambda_vt` = 0.5 | 0.437 | 0.437 | — |
| 13 | `Lambda_LE_vt` | 15.3 | `LE_sweep_vt` | 47.5 | 47.5 | — |
| 14 | `H_t` | 15.3 | `H_t` | 0 | 0 | — |
| 15 | `H_v` | 15.3 | `H_v` | 1 | 1 | — |
| 16 | `L_t` | 15.3 | `L_t` | 22.0 | 22.0 | — |
| 17 | `S_r` | 15.3 | `S_r` | 11.65 | 11.65 | — |
| 18 | `L_fus` | 15.4 | `L_fus` | 47.5 | 47.5 | — |
| 19 | `D_fus` | 15.4 | ★ **`H_max_fuselage`** — **NOT** `geom.D_fus` = 6.0 | 5.0 | 5.0 | — |
| 20 | `W_fus` | 15.4 | `W_max_fuselage` | 7.0 | 7.0 | — |
| 21 | `S_cs` | 15.17 | `S_cs` | 190 | 190 | — |

### B.3 — The three DI name-traps, spelled out

These will silently produce a wrong number with no error if wired naively by name.

| Trap | Naive wiring | Wrong value | Correct member | Correct value | Why |
|---|---|---|---|---|---|
| **Exposed vs FULL tail area** | `geom.S_ht`, `geom.S_vt` | 108, 60 | `geom.S_exposed_ht`, `geom.S_exposed_vt` | 51.1486, 40.8897 | `AR_ht`/`lambda_ht`/`S_ht`/`S_vt` mean **FULL planform at both L2 and L3** after the Phase-2 rename (`F16GeomL3.md` §B). Raymer Table 15.2 / Eqs. 15.2–15.3 want the **exposed** planform. |
| **Exposed vs FULL tail AR/taper** | `geom.AR_vt`, `geom.lambda_vt` | 1.6, 0.5 | `geom.AR_exposed_vt`, `geom.lambda_exposed_vt` | 1.294, 0.437 | Same rename. HT's are `AR_exposed_ht` / `lambda_exposed_ht` = 2.114 / 0.390 — **but see §B.4, both are dead at L3.** |
| **Fuselage depth vs equivalent diameter** | `geom.D_fus` | **6.0** | `geom.H_max_fuselage` | **5.0** | Weights' `D_fus` is the Raymer Eq. 15.4 **max structural depth**. `geom.D_fus` is `(W_max+H_max)/2`, the Roskam Vol. II Eq. 12.3 **equivalent diameter**, used only for the fuselage-wetted-area cylinder. Same name, different quantity. `Eq. 15.4` carries `D_fus^0.849`, so a 6.0-for-5.0 substitution inflates the fuselage weight by **+17.9 %** (`(6/5)^0.849`). |

Logged: todo 2026-07-24 GeomL3 §5.

### B.4 — Two dead L3 inputs — **DELETED**

`AR_ht` = 2.114 and `lambda_ht` = 0.390 on `F16WeightsL3` were **never read by any `WeightsL3`
equation** (verified by grep of `obj.AR_ht` / `obj.lambda_ht` in `src/disciplines/weights/`,
2026-07-25 — zero matches). Raymer Eq. 15.2 takes only `(W_dg, N_z, S_ht, F_w, B_h)`. **Both deleted,
neither rewired** to `geom.AR_exposed_ht` / `geom.lambda_exposed_ht`; `F16WeightsL3.m` carries an
explicit `NOTE:` at the HT getter block explaining why. Guard:
`TestWeightsL3.testDeadHTAspectRatioAndTaperAreDeleted`. todo §P4-6 — **RESOLVED**.

### B.5 — Candidate geometry DI that is **NOT** wired — STILL OPEN, user decision required

Three L3 engine/duct dimensions have a geometry analog with a **different value**. **Neither `L_d` nor
`D_e` was wired this phase** — deliberately, since the locked plan does not say whether to, and the
scribe convention forbids resolving it unilaterally. Both keep their `[estimate, unpinned]` tag plus an
in-code `⚠` pointing at the analog and its cost. **todo §P4-4 stays OPEN**; the comparison report's
section 6 carries a sensitivity row for each so the open choice is visible in the output.

| Weights symbol | AS-IS value | Geometry analog | Analog value *(live)* | Consumer | Effect if wired |
|---|---|---|---|---|---|
| `L_d` (inlet duct length) | 7.5 `[estimate]` | `geom.L_duct` | **14.0** `[Brandt Main!F32]` | Eq. 15.10 air induction | **227.54 → 429.01 lbf, +88.5 %** *(live)* |
| `D_e` (engine exit diameter) | 3.33 `[estimate, ≈40 in]` | `geom.D_exit` (= `D_inlet`) | **3.537022** | Eqs. 15.10 / 15.11 / 15.12 | induction 227.54→241.69; tailpipe 52.45→55.71; cooling 121.21→128.75 (**+24.9 lbf total**) *(live)* |
| `N_en` | 1 | `geom.n_engines` | 1 | Eqs. 15.7/15.9–15.15 | no value change — but `n_engines` is in `.geometry` only because no propulsion class exposes a count (todo 2026-07-25 Phase 2 §22). Keep `N_en` a `.weights` input until that migrates. |

Logged: todo 2026-07-25 Phase 4 §P4-4.

---

## Part C — Propulsion → weights DI map — AS BUILT

`WAS`: **no DI.** `F16WeightsL2` hardcoded `W_en = 3030` `[estimate]` and `F16WeightsL3` hardcoded
`T_max = 23770` `[Brandt D29]` + `W_en = 3030`. **As built:** `F16PropL2` is injected at both rungs —
there is **no L3 propulsion tier**, so `F16PropL2` sits at the L3 rung (locked decision 2026-07-25) and
any report quoting an "L3 propulsion" figure must say so.

| Weights symbol | `prop` member on `F16PropL2` | Value *(live)* | Consumer | Status |
|---|---|---|---|---|
| `T_max` (L3) | `prop.T_SL` | 23770 | Eqs. 15.7 mounts, 15.15 starter, 15.16 fuel system | **wired** (`testPropulsionDIReplacesFrozenThrust`) |
| Eq. 10.10 `T` | `prop.T_SL` (≡ `prop.T_SL_wet`, Dependent alias) | 23770 | `W_en` at L2 and L3 | **wired** |
| Eq. 10.10 `BPR` | `prop.bypass_ratio` | **0.71** | `W_en` | **wired** — `isprop(prop,'bypass_ratio')` = **1**, verified live 2026-07-25. `f16a_L2.json .propulsion.bypass_ratio = 0.71` was added in Phase 3 but `F16PropL2` neither declared nor read it (`isprop` = 0); the input property was added outside this phase. **§P4-2 RESOLVED.** Its `_TODO_bypass_ratio` marker (0.71 not traceable to any repo document) **stays open** |
| Eq. 10.10 `M` | *(not propulsion)* — `design_mach` from **`f16a_requirements.json`** (A.3) | **2.0** | `W_en` at L2 **and** L3 | **wired** (decision 5). `WAS`: no Mach existed at L2 at all. **§P4-3 RESOLVED** — but the *citation* question is §P4-13, still open |
| `SFC_mission` (L3, Eq. 15.16) | **`prop.get_TSFC(AircraftState(cruise_altitude_ft, cruise_mach))`** | **1.007116** | Eq. 15.16 fuel system | **wired** (decision 2) — see C.1. Weights builds the `AircraftState` itself; no state is injected |

### C.1 — `SFC_mission` is a DEPENDENCY INJECTION, evaluated at the cruise condition

**SETTLED (user, 2026-07-25, decision 2).** `SFC_mission` becomes a `Dependent` getter:

```
get.SFC_mission  ->  prop.get_TSFC( AircraftState(cruise_altitude_ft, cruise_mach) )
```

with the cruise condition from `f16a_requirements.json` (A.3): **36,000 ft / M 0.87**. Whatever
`get_TSFC` returns at that state is the value used — no correction, no calibration to Brandt.

| Quantity | Value *(live)* | Note |
|---|---|---|
| `prop.get_TSFC(AircraftState(36000, 0.87))` | **1.007116** 1/hr | The selected value. Identical to `prop.compute_TSFC_mil` at that state — `get_TSFC` resolves to the **mil (dry), UNINSTALLED** path |
| `prop.compute_TSFC_installed` at the same state | 1.087685 | = 1.007116 × 1.08, for reference only |
| Brandt `Main!C30` | 0.70 | Already **installed**, and a single SLS structural-sizing constant |
| **Divergence** | **+43.87 %** | **Accepted by decision.** Two independent causes, both deliberate: (a) *condition* — a real 36 kft/M0.87 cruise point vs Brandt's one stored SLS number; (b) *installation basis* — `get_TSFC` is uninstalled, Brandt's 0.70 is installed |

**One consistency point in the framework's favour:** Brandt's own cruise row (`Consts!` row 24) is
`pct_AB = 0`, i.e. **dry/mil**, and `get_TSFC` resolves to the mil path at that state. So the *power
setting* matches Brandt's cruise definition; only the condition and the installation basis differ.

Eq. 15.16's sensitivity is weak (`((T·SFC)/1000)^0.249`): at `V_t` = 940 the fuel system moves
386.794 → **423.465 lbf** (+9.48 %, **+36.67 lbf** on OEW) *(live)*. Logged as a deliberate consequence:
todo 2026-07-25 Phase 4 §P4-5c (re-statused RESOLVED-BY-DECISION).

> **★ The Phase-3 rationale for deleting this key was FALSE and is corrected on the record.**
> `f16a_L3.json .weights._not_inputs` states *"SFC_mission [Main!C30] duplicates what
> `PropL2.get_TSFC` computes"* — and the Phase-3 commit message says the same. It does not duplicate
> it: the two disagree by **+43.87 %**, and no reference condition was specified. The correction is now
> carried in `F16WeightsL3.m`'s `get.SFC_mission` comment. todo §P4-15 — **corrected on the record;
> verify the JSON note wording at review.**

---

## Part D — Quantity → (level, function, formula, citation)

### D.1 — L1 statistical empty-weight regressions

| Quantity | Function | Formula | Citation | Extract |
|---|---|---|---|---|
| OEW (central estimate) | `WeightsL1.OEW` → `compute_We_fraction` → `We_fraction_power_law(Kvs,A,C,W_TO)` | `OEW = (K_vs·A·W_TO^C)·W_TO` | `[Raymer Table 3.1]` | `metabook_data.md:20-26`; jet fighter A(US)=2.34, C=−0.13, K_vs fixed=1.00 / VS=1.04 |
| `W_E` (minimum bound) | `WeightsL1.compute_We_roskam` → `We_roskam(A,B,W_TO)` | `W_E = 10^((log10 W_TO − A)/B)` | `[Roskam Airplane Design Part I Eq. 2.16 + Table 2.15, book p.47 / PDF p.59]` | `roskam_vol1_data.md:47` (equation) + `:53-63` (table); jet fighter A=0.5091, B=0.9505 |

**Table 3.1 rows in `WeightsL1.lookup_coeffs` vs the extract (`metabook_data.md:20-26`):**

| Code key | Extract row | A | C | K_vs | Agreement |
|---|---|---|---|---|---|
| `jet_fighter` | Jet fighter | 2.34 | −0.13 | 1.00 | ✅ |
| `jet_trainer` | Jet trainer | 1.59 | −0.10 | 1.00 | ✅ |
| `jet_transport` | Jet transport | 1.02 | −0.06 | 1.00 | ✅ |
| `military_cargo_bomber` | Military cargo/bomber | 0.93 | −0.07 | 1.00 | ✅ |
| *(absent)* | UAV-Tac Recce / UCAV | 1.67 | −0.16 | — | extract has a 5th row the code does not carry — not a defect, just noted |

All four code rows match the extract exactly. The in-code `⚠ verify all rows against Raymer 6th ed.
Table 3.1` markers (`WeightsL1.m:30`, `:86`) remain correct in substance: the metabook is a
secondary source citing Raymer, not Raymer itself.

**Table 2.15 rows in `WeightsL1.lookup_roskam_coeffs` vs `roskam_vol1_data.md:53-63`:** all five
(`jet_fighter` 0.5091/0.9505; `fighter_piston` 0.5647/0.8761; `single_engine_prop` −0.1440/1.1162;
`military_patrol_bomber` −0.2009/1.1037; `supersonic_cruise` 0.0833/1.0335) match exactly.
**Correction to the previous version of this doc, which said "no repo extract — unpinned": the
extract exists.** It carries its own warning (`roskam_vol1_data.md:63`): the 12-category table is
image-only and these rows were OCR-recovered — "Verify against the book before locking into code."

**Raymer Table 6.1 → STANDING TO-DO (locked).** `docs/subplans/05_weights.md:81,88` cites **Table
6.1** for the same power law; code cites **Table 3.1**. Locked: keep Table 3.1 + the Roskam bound;
Table 6.1's coefficients are **not in the repo**, so it becomes a standing TO-DO for the user to
supply. Needs a labelled `testTODO_` guard. todo 2026-07-24 §3c item 4 / 2026-07-25 §P4-8.

### D.2 — L2 Raymer Table 15.2 surface density + metabook §7 fractions

All coefficients transcribed from `metabook_data.md` — **§7 Table (`:319-324`)** for the psf
densities and **§7 "Fraction-Based Weight Estimates" (`:328-334`)** for the fractions.

| Quantity | Function | Formula | Coefficient | Citation | Extract line |
|---|---|---|---|---|---|
| Wing | `WeightsL2.weight_wing` | `ρ_w·S_w` | 9 lb/ft² (fighter) | `[Raymer Table 15.2]` | `metabook_data.md:321` |
| HT | `WeightsL2.weight_tail`.HT | `ρ_ht·S_ht` | 4 lb/ft² | `[Raymer Table 15.2]` | `:322` |
| VT | `WeightsL2.weight_tail`.VT | `ρ_vt·S_vt` | 5.3 lb/ft² | `[Raymer Table 15.2]` | `:323` |
| Fuselage | `WeightsL2.weight_fuselage` | `ρ_fus·S_wet_fus` | 4.8 lb/ft² | `[Raymer Table 15.2]` | `:324` |
| Landing gear | `WeightsL2.weight_landing_gear` | `f_lg·W_TO` | **0.033** (non-Navy fighter) | `[AE481 metabook §7, "Fraction-Based Weight Estimates" table]` — ★ **NOT Raymer Table 15.2** (see below) | `:330` |
| Installed engine | `WeightsL2.weight_installed_engine` | `1.3·N_en·W_en` | 1.3 | `[AE481 metabook §7]` | `:333` |
| All-else-empty | `WeightsL2.weight_all_else_empty` | `0.17·W_TO` | 0.17 | `[AE481 metabook §7]` | `:334` |

`jet_transport` (10 / 5.5 / 5.5 / 5.0) and `general_aviation` (2.5 / 2 / 2 / 1.4) psf rows also match
`metabook_data.md:321-324` exactly. LG fractions `jet_fighter` 0.033 and `jet_transport` 0.043 match
`:330`/`:332`.

> **★ `WeightsL2.LG_fraction('general_aviation') = 0.057` is UNCITED.** The extract's fraction table
> (`metabook_data.md:328-334`) has **no GA landing-gear row** — only fighter 0.033, Navy fighter
> 0.045, transport 0.043. `WeightsL2.m:173` cites it "AE481 metabook §7", which the repo extract does
> not support. Also `LG_fraction` carries **no `navy_fighter` row** despite the extract having one
> (0.045). New item, todo 2026-07-25 Phase 4 §P4-7.

**LG 0.033 vs Brandt 0.034 — LOCKED, use 0.033.** Verified live: `Wt!F23 = 0.034000` (bare literal),
`Wt!B8 = =B3*F23`, `Wt!B23 = =B8` = 1066.818000 lbf. Brandt uses 0.034; the framework uses the
metabook's 0.033. Different models, reported side by side; not an error. todo 2026-07-24 §3c item 2.

> **★ Citation correction (settled 2026-07-25).** The locked plan phrases this as "landing-gear ratio
> **0.033** (Raymer **Table 15.2**, NOT Brandt's 0.034)". **Table 15.2 is not the source.** In the repo
> extract, Table 15.2 is the *psf surface-density* table (`metabook_data.md:319-324`, four rows: wing
> 9 / HT 4 / VT 5.3 / fus 4.8 for fighters); the landing-gear, installed-engine and all-else-empty
> *fractions* are a **separate, unnumbered** metabook table (`:326-334`) with no Raymer table number
> attached to it at all. So 0.033's only in-repo provenance is `[AE481 metabook §7,
> "Fraction-Based Weight Estimates" table]` — exactly what `WeightsL2.m:169` already says. **Nothing
> numeric changes** (0.033 is the coded value today); this corrects the citation only, and the same
> correction applies to the 1.3 installed-engine factor and the 0.17 all-else fraction. §P4-7.

### D.3 — L3 Raymer §15.3.1 fighter/attack component build-up

Target citation: **Raymer 7th ed. §15.3.1**, Eqs. 15.1–15.24 (locked re-cite; no value change).
**Every exponent is a standing verify-against-book TO-DO** — the complete 62-row checklist is
`VnV/BrandtF16A/todo.md` 2026-07-24 §3a, including the two code-vs-extract CONFLICTS that Phase 4
**keeps at their code values**: Eq. 15.13 `N_en^1.023` (extract says 1.078) and Eq. 15.3
`cos(Λ_vt)^−0.323` (extract says −1.0). Approach 2, locked. A labelled `testTODO_` must point at that
checklist; the values must **not** be declared book-verified.

| Group | Component (eq.) | Function | Inputs consumed | Exponent status (todo §3a) |
|---|---|---|---|---|
| Structural | Wing (15.1) | `WeightsL3.wing` | `W_TO, N_z, S_w, AR_w, tc_root, lambda_w, Lambda_LE_w, S_csw, K_dw, K_vs` | UNVERIFIED — IMAGE-ONLY ×6 + `tc_root^−0.4` illegible + LE-vs-c/4 sweep-station open (rows 37–44) |
| Structural | HT (15.2) | `WeightsL3.horizontal_tail` | `W_TO, N_z, S_ht, F_w, B_h` | UNVERIFIED — IMAGE-ONLY (rows 45–47) |
| Structural | VT (15.3) | `WeightsL3.vertical_tail` | `W_TO, N_z, S_vt, K_rht, H_t, H_v, `**`design_mach`**`, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt` | **CONFLICT** (row 2, −0.323 kept) + IMAGE-ONLY ×8 (rows 48–55) |
| Structural | Fuselage (15.4) | `WeightsL3.fuselage` | `W_TO, N_z, L_fus, D_fus, W_fus, K_dwf` | UNVERIFIED — IMAGE-ONLY ×5 (rows 56–60) |
| Landing gear | Main (15.5) | `WeightsL3.main_gear` | **`W_l`** (now DERIVED = 0.95·`W_TO`)`, N_l, L_m·12, K_cb, K_tpg` | UNVERIFIED — `L_m^0.973` FROM-CODE (rows 14–15). `L_m` in **inches** per Raymer nomenclature |
| Landing gear | Nose (15.6) | `WeightsL3.nose_gear` | **`W_l`** (DERIVED)`, N_l, L_n·12, N_nw` | UNVERIFIED — `N_nw^0.525` FROM-CODE (rows 16–18) |
| Engine | Engine, dry/uninstalled | `W_en·N_en` (not a §15.3.1 eq) | `W_en, N_en` | `W_en` is **computed** — `[Raymer 7th ed. Eq. 10.10]`, UNINSTALLED (D.4) |
| Engine | Mounts (15.7) | `WeightsL3.engine_mounts` | `N_en, T_max, N_z` | UNVERIFIED — IMAGE-ONLY (rows 61–62) |
| Engine | Firewall (15.8) | `WeightsL3.firewall` | `S_fw` (= 0 for a jet) | **extract-clean**; still in the standing all-equations TO-DO |
| Engine | Section (15.9) | `WeightsL3.engine_section` | `W_en, N_en, N_z` | UNVERIFIED — VERIFY (row 19) |
| Engine | Air induction (15.10) | `WeightsL3.air_induction` | `K_vg, L_d, K_d, N_en, L_s, D_e` | UNVERIFIED — FROM-CODE ×3 + VERIFY ×2 (rows 3–7) |
| Engine | Tailpipe (15.11) | `WeightsL3.tailpipe` | `D_e, L_tp, N_en` | **extract-clean** |
| Engine | Cooling (15.12) | `WeightsL3.engine_cooling` | `D_e, L_sh, N_en` | **extract-clean** |
| Engine | Oil cooling (15.13) | `WeightsL3.oil_cooling` | `N_en` | **CONFLICT** (row 1, 1.023 kept vs extract 1.078) |
| Engine | Controls (15.14) | `WeightsL3.engine_controls` | `N_en, L_ec` | UNVERIFIED — FROM-CODE ×2 (rows 8–9) |
| Engine | Starter (15.15) | `WeightsL3.starter` | `T_max, N_en` | UNVERIFIED — VERIFY ×2 (rows 20–21) |
| Systems | Fuel system (15.16) | `WeightsL3.fuel_system` | `V_t` (INPUT, 940), `V_i, V_p, N_t, N_en`, **`T_max`** (prop DI), **`SFC_mission`** (prop DI @ cruise) | UNVERIFIED — VERIFY ×5 (rows 22–26) |
| Systems | Flight controls (15.17) | `WeightsL3.flight_controls` | **`design_mach`** (from the requirements file)`, S_cs, N_s, N_c` | UNVERIFIED — `N_c^0.127` FROM-CODE + VERIFY ×3 (rows 10–13) |
| Systems | Instruments (15.18) | `WeightsL3.instruments` | `N_en, N_t, N_ci` | UNVERIFIED — VERIFY ×3 (rows 27–29) |
| Systems | Hydraulics (15.19) | `WeightsL3.hydraulics` | `K_vsh, N_u` | UNVERIFIED — VERIFY (row 30) |
| Systems | Electrical (15.20) | `WeightsL3.electrical` | `K_mc, R_kva, N_c, L_a, N_gen` | UNVERIFIED — VERIFY ×4 (rows 31–34) |
| Systems | Avionics (15.21) | `WeightsL3.avionics` | `W_uav` | UNVERIFIED — VERIFY (row 35) |
| Systems | Furnishings (15.22) | `WeightsL3.furnishings` | `N_c` | **extract-clean** |
| Systems | AC / anti-ice (15.23) | `WeightsL3.ac_antiice` | `W_uav, N_c` | UNVERIFIED — VERIFY (row 36) |
| Systems | Handling gear (15.24) | `WeightsL3.handling_gear` | `W_TO` | **extract-clean** |

### D.4 — `W_en` engine weight: Raymer official + Brandt alternate — AS BUILT

**Both** are computed; **Raymer is the official/default**; Brandt is a comparison-report alternate that
is **never summed into `OEW`** (`TestWeightsL2.testBrandtEngineAlternateIsNeverSummedIntoOEW`).

| Model | Formula | Citation | Value *(live)* |
|---|---|---|---|
| **Raymer (official), uninstalled** | `W = 0.0637·T^1.1·M^0.25·e^(−0.81·BPR)` | `[Raymer 7th ed. Eq. 10.10]`, coefficient confirmed at `raymer_data.md:38`; already implemented as `PropL2.engine_weight_AB` | **2775.0210** lbf at T=23770, M=2.0, BPR=0.71 |
| **Raymer × 1.3 installed** | `1.3 × 2775.0210` | 1.3 installed/bare factor `[AE481 metabook §7, metabook_data.md:333]` | **3607.5273** lbf |
| Brandt alternate | `0.199·T_AB_SLS` | `[Brandt Wt!B11 = 4730.230000 (live), formula =IF(Main!C29=Main!D29,'Engn(s) Old'!D11·Main!B28·Main!C29,'Engn(s) Old'!D22·Main!B28·Main!D29)]`; the 0.199 literal lives at **`'Engn(s)'!D22 = 0.199` *(live)***, routed through `'Engn(s) Old'!D22`; labelled `'Engn(s) Old'!C22` = `"Engine with AB:  Weng = "`. `readme_wt.md:230` attributes it to "Brandt 1997, Table 6.2" | **4730.2300** lbf |
| `WAS` hardcoded | `3030` `[estimate; verify TO/Jane's]` — not pinned to anything | — | 3030 (**gone**; `testEngineWeightIsNotTheFormerFrozenEstimate` locks it out) |

> **★ SETTLED (user, 2026-07-25, decision 1) — the level determines the basis.**
>
> **(a) The Brandt alternate gets NO ×1.3.** `readme_wt.md:230` states explicitly: *"This is the
> **installed engine weight** formula for afterburning turbofan/turbojet engines."* Applying `×1.3`
> would double-count the installation: 4730.23 → 6149.30, and L2 OEW would read 18206.42 instead of
> **16787.35** *(both live)*. **Brandt alternate = 4730.2300, as-is.** Closes §P4-1a.
>
> **(b) L3 uses the UNINSTALLED 2775.0210; `×1.3` is L2-only.**
> `WeightsL3.weight_engine_section` sums the dry engine **plus** mounts, firewall, section, induction,
> tailpipe, cooling, oil, controls and starter — §15.3.1 builds the installation up item by item, which
> is exactly what `×1.3` lumps into one factor, and Raymer's nomenclature for Eq. 15.9's `W_en` is the
> engine weight *each* (dry). L2 has no such buildup, so `×1.3` is correct there and only there.
>
> **This moves L3 FURTHER from Brandt, and that is the point.** L3 `OEW(31377)`: uninstalled
> **15705.33** (−21.40 % vs `Wt!B12`) vs the rejected `×1.3` variant **16546.06** (−17.19 %)
> *(both live)*. The `×1.3` variant's *better* agreement was the **reason to distrust it**, not a
> reason to keep it — a number that agrees because a factor is double-counted is not agreement.
> Closes §P4-1b.

### D.5 — The four quantities Phase 3 deleted — AS BUILT

Phase 3 deleted `W_energy`, `W_l`, `V_t`, `SFC_mission`, `W_en`, `T_max` from the JSONs. `W_en` (D.4)
and `T_max` (Part C) had clean replacements. The other three, plus `W_energy`, shipped as follows:

| Key | `WAS` | Consumer | **AS-BUILT disposition** | Effect *(live)* |
|---|---|---|---|---|
| `.weights.landing_gear.W_l` | 20681 `[Brandt Wt!B41]` | Eqs. 15.5 / 15.6 | **DERIVED: `W_l = 0.95 · W_TO`** (decision 4). Tracks the sizing loop | At `W_TO`=31377 → `W_l` = **29808.15**; LG total 1057.27 → **1160.93** (+103.66, **+9.81 %**). ★ The 0.95 factor has **no repo citation** — open, todo §P4-16 |
| `.weights.systems.V_t` | 940 gal | Eq. 15.16 | **RESTORED as a `.weights.systems` JSON input**, 940 (decision 3) | none. ★ Provenance warning **retained**: the 6.7 lb/gal density behind 940 is cited **nowhere** in the repo (grepped 2026-07-25; no JP-4/JP-5/JP-8 density anywhere in `sizing/`). Not derived, precisely because the derivation would rest on an uncited constant. todo §P4-5b stays open as a provenance item |
| `.weights.systems.SFC_mission` | 0.70 `[Brandt Main!C30]` | Eq. 15.16 | **DERIVED by DI: `prop.get_TSFC(cruise)`** (decision 2) — see C.1 | **1.007116** (+43.87 % vs Brandt), accepted. Fuel system 386.794 → **423.465** (+36.67) |
| `.weights.W_energy` (all levels) | 6296.3 | *(nothing reads it)* | stays a **`NaN` state input** on the object, set by mission analysis | none — `Wt!B6` = `=B3-B4-B5-B12` is a back-calculated Brandt **output** |

`W_l` = `0.95·W_TO` also fixes a **newly identified frozen-under-mutation bug** — see F.5.

For the record, the figures the rejected alternatives would have given *(live)*: `W_l` = `W_TO`
(31377) → LG 1176.27; `W_l` = `OEW + payload + ½·fuel` (23828.85) → LG 1096.30; `V_t` =
`W_energy/6.7` = 939.746 → fuel system 386.742. Brandt's own `Wt!B41` = **20680.700578** is now a
**comparison reference only**, and `0.95·31377` = 29808.15 sits **+44.14 %** above it (Brandt's B41 is
`=SUM(B16:B32)`, a back-calculated output of his own weight statement, not a landing-weight
requirement).

---

## Part E — Brandt ground truth (comparison-report Expected values)

**All values below read live from `VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` on 2026-07-25 via
Excel COM.** W_TO basis = `Wt!B3` = 31377.000000 (`=Main!O15`). Never copy an expected value from
`tests/disciplines/TestWeights*.m` — the 19,148 mis-citation is exactly why.

> **Method mismatch.** Brandt's structural line items are a **psf × area** model with coefficients
> `Wt!C7:H7` — verified live: wing **6.75**, fuselage **5.0**, pitch **6.0**, VT **6.0** (`=E7`),
> nacelle **4.5**, strake **4.5** lb/ft². The framework's L2 is also psf × area but with **Raymer
> Table 15.2** coefficients (9 / 4.8 / 4 / 5.3), and L3 is the §15.3.1 statistical build-up, which
> groups mass differently. Per-component agreement is **not** expected.

### E.1 Structural line items (`Wt!C9:H9`)

| Component | Framework analog | Brandt (lb) *(live)* | Cell | Live formula (abridged) | corrections.xls |
|---|---|---|---|---|---|
| Wing | L3 `weight_wing` (15.1) / L2 `weight_wing` | **1785.946837** | `Wt!C9` | `=Main!B18*C7/7*0.04*(Main!Q27^0.2)*(Main!B19^1.8)*((1+Main!B20)^0.5)/((Main!B22/100-INT(Main!B22/100))^0.7)/COS(Main!B21/57.29578)*Main!O27/100*MAX(1,(Main!L10-Main!L8)/Main!L7/8)` | 1852.09 |
| Fuselage | L3 `weight_fuselage` (15.4) / L2 `weight_fuselage` | **3652.110000** | `Wt!D9` | `=D7*Geom!B3*Main!O27/100*MAX(1,Main!B32/(Main!C32*Main!D32)^0.5/19)` | 3506.03 |
| Pitch control (HT) | L3 `weight_tail`.HT (15.2) / L2 `.HT` | **648.000000** | `Wt!E9` | `=E7*Main!C18*Main!O27/100` → 6.0 × **108** (FULL planform) | 199.39 |
| Vertical tail | L3 `weight_tail`.VT (15.3) / L2 `.VT` | **360.000000** | `Wt!F9` | `=F7*Main!H18*Main!O27/100*MAX(1+IF(Main!H24>0,1,0),1)` → 6.0 × **60** (FULL) | 245.34 |
| Nacelles | *(none)* | **186.817478** | `Wt!G9` | `=Geom!B4*Wt!G7*Main!O27/100` | 186.82 (unchanged) |
| Strakes | *(none)* | **90.000000** | `Wt!H9` | `=H7*Main!D18*Main!O27/100` | 90.00 (unchanged) |
| **Structural subtotal** | — | **6722.874315** | `Wt!B9` | `=SUM(C9:H9)` | — |

> ★ Brandt's `Wt!E9`/`Wt!F9` use the **FULL** planform areas (108 / 60), while the framework's L2/L3
> tail weights use the **EXPOSED** areas (51.1486 / 40.8897) per Raymer's own definition. The tail
> rows are therefore **not** like-for-like — mark them `DEFINITIONAL`, not `BY DESIGN`.

### E.2 Engine + systems (`Wt!B11`, `B22:B31`)

Fraction literals verified live: `F23`=0.034, `F24`=3.9, `F25`=0.012, `F26`=0.017, `F27`=0.0117,
`F28`=0.0115, `F29`=0.3, `F30`=0.081, `F31`=0.1.

| Component | Framework analog | Brandt (lb) *(live)* | Cell | Brandt model | Framework eq. |
|---|---|---|---|---|---|
| Engine | L3 engine group `.engine` | **4730.230000** | `Wt!B11`/`B22` | `0.199·T_AB` (already **installed**) | Raymer Eq. 10.10 (D.4) |
| Landing gear | L3 `weight_landing_gear` (main+nose) / L2 | **1066.818000** | `Wt!B23` (`=B8` = `B3*F23`) | `0.034·W_TO` | Eqs. 15.5+15.6 / `0.033·W_TO` |
| Inlet duct | L3 engine group `.induction` | **728.588163** | `Wt!B24` (`=B20*F24`) | `3.9·W_nacelles` | Eq. 15.10 |
| Flight controls | L3 systems `.flight_ctrl` | **472.435405** | `Wt!B25` | `0.012·W_TO + (Main!F18/Main!B18)·6.75·200` | Eq. 15.17 |
| Electrical | L3 systems `.electrical` | **533.409000** | `Wt!B26` | `0.017·W_TO` | Eq. 15.20 |
| Hydraulics | L3 systems `.hydraulics` | **367.110900** | `Wt!B27` | `0.0117·W_TO` | Eq. 15.19 |
| ECS / AC-anti-ice | L3 systems `.ac_antiice` | **360.835500** | `Wt!B28` | `0.0115·W_TO` | Eq. 15.23 |
| Other structure | *(distributed)* | **2016.862295** | `Wt!B29` (`=B9*F29`) | `0.30·W_structure` | — |
| Avionics | L3 systems `.avionics` | **2541.537000** | `Wt!B30` | `0.081·W_TO` | Eq. 15.21 |
| Armament support | *(none)* | **440.000000** | `Wt!B31` | `0.10·exp_payload` | — |

Brandt does not separately tabulate the L3 items `.mounts`, `.firewall`, `.section`, `.tailpipe`,
`.cooling`, `.oil`, `.controls`, `.starter`, `.fuel_sys`, `.instruments`, `.furnishings`,
`.handling` — those compare only at group/OEW level.

### E.3 Summary

| Quantity | Brandt (lb) *(live)* | Cell | Live formula | corrections.xls |
|---|---|---|---|---|
| Airframe (structure + systems, engine excluded) | **15250.470578** | `Wt!B10` | `=B9+SUM(B23:B31)` | — |
| **OEW** | **19980.700578** | **`Wt!B12`** | `=SUM(B10:B11)` | **19148.08** |
| Fuel (back-calculated) | **6296.299422** | `Wt!B6` | `=B3-B4-B5-B12` | — |
| TOGW | **31377.000000** | `Wt!B3` / `B38` | `=Main!O15` / `=SUM(B16:B37)` | — |
| Landing weight | **20680.700578** | `Wt!B41` | `=SUM(B16:B32)` | — |

### E.4 OEW provenance — the 19,148 vs 19,980.70 issue, RESOLVED to the comparison tier

- **Comparison-report Expected = 19,980.70 lb `[Brandt Wt!B12]`** — **live-verified 19980.700578**.
  Agreed by `readme_wt.md` §8, `GroundTruth/cell-map.md:142`, `BrandtWeight.m` (`W_empty=19980.70`),
  `F16Baseline.m:93`, and `f16a_ground_truth.json` `.weights.summary.OEW`.
- **Labelled alternate column = 19,148.08 lb `[corrections.xls Wt!B12]`** — Casey's revised-weight
  workbook, per `F16Baseline.m:136`. The file itself is not chased.
- **`WAS`: `TestWeightsL1.m:117`, `TestWeightsL2.m:79`, `TestWeightsL3.m:203` asserted
  `expected = 19148` citing "Brandt F-16A.xls sheet Wt B12"** (also headers `:11`, `:11`, `:7`). That
  cell is **19980.700578**, live-verified. A wrong-workbook attribution — review finding #14.
- **AS BUILT: the OEW-vs-Brandt agreement check LEFT the unit tier entirely** (this overrode the older
  "keep 19,148 in the unit tier, re-cite it" decision). Per CLAUDE.md's two-tier rule an agreement check
  is not a unit test. All three test files' 19,148 assertions and header reference blocks are gone; the
  check is a `weights_brandt_comparison` row with `Brandt` = 19,980.70 and `Alt` = 19,148.08. See
  `F16WeightsL2.md` §G for the report and §F of each companion doc for what the unit tier keeps.
  **§P4-0 / finding #14 — RESOLVED.**

---

## Part F — What CHANGED, `WAS` → AS BUILT (all computed live, 2026-07-25)

### F.1 L1 — nothing numeric changed

`W_payload_fixed` 220 → **700** and `W_payload_expendable` 0 → **4400** are inert (nothing reads them).
`W_energy` 6296.3 → `NaN`, likewise inert. OEW is unchanged: `We/Wto` = 0.609055, OEW =
**19110.3126** lbf at `W_TO` = 31377 (−4.36 % vs `Wt!B12`; −0.20 % vs `corrections.xls`). Roskam bound
**15673.7334** lbf (−21.56 % vs `Wt!B12`).

### F.2 L2 — component and total deltas

| Component | `WAS` | **AS BUILT** | Δ | Cause |
|---|---|---|---|---|
| Wing | 1766.07 | 1766.03 | −0.04 | `S_w` 196.23 → 196.2261 (geom DI) |
| HT | 199.40 | 199.39 | −0.01 | `S_ht` 49.85 → 49.8473 |
| VT | 216.72 | 216.72 | −0.0002 | `S_vt` 40.89 → 40.8897 |
| Fuselage | 3600.00 | **3505.4511** | **−94.55** | `S_wet_fus` **750 → 730.3023** (geom DI replaces the `[estimate]`) |
| Landing gear | 1035.44 | **1035.4410** | 0 | 0.033 already in code |
| Installed engine | 3939.00 | **3607.5273** | **−331.47** | `W_en` 3030 `[estimate]` → Raymer Eq. 10.10 × 1.3 |
| All-else-empty | 5334.09 (**frozen**) | `0.17·W_TO` (**live**), 5334.0900 at 31377 | 0 at 31377; **+2315.91 at 45000** | ★ finding #5 fixed |
| **OEW(31377)** | **16090.72** | **15664.6483** | **−426.07** | −21.60 % vs `Wt!B12`; −18.19 % vs `corrections.xls` |
| **OEW(45000)** | **16540.28** | **18430.1173** | **+1889.84** | the frozen-all-else bug was the bulk of it |

Brandt-`W_en` alternate at 31377: OEW = **16787.35** (−15.98 % vs `Wt!B12`).

> **★ Finding #5 — FIXED, and the fix is measurable.** The pre-Phase-4 `w2.OEW(45000)` carried an
> all-else group of `0.17·31377 = 5334.09` where `0.17·45000 = 7650.00` was required — **understated by
> 2315.91 lbf**. Every `TestWeightsL2` case called `OEW(31377)`, exactly the one argument at which the
> bug is invisible. The offending line was `F16WeightsL2.m:76`:
> `obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377);`
> — and 31,377 is `Brandt Wt!B3`, a Brandt **output**, forbidden as an input by CLAUDE.md.
> As built: `18430.1173 − 15664.6483 = 2765.4690` = `(0.17 + 0.033)·13623` **exactly**, which is what
> `testOEWScalesWithItsArgumentNotAFrozenWTO` and `testOEWDoesNotUnderstateByTheFrozenAllElseAmount`
> assert.

### F.3 L3 — component and total deltas

All figures are the **as-built** values (decisions 1–6 applied): `W_en` uninstalled 2775.0210,
`W_l` = 0.95·`W_TO`, `V_t` = 940 input, `SFC_mission` = 1.007116, `design_mach` = 2.0, `K_d` = 1.0.

| Component | `WAS` | **AS BUILT** | Δ | Cause |
|---|---|---|---|---|
| Wing (15.1) | 2396.80 | 2396.77 | −0.03 | `S_w` geom DI (196.23 → 196.2261) |
| HT (15.2) | 196.43 | **200.5412** | **+4.11 (+2.09 %)** | `S_ht` **49.85 → 51.1486** (geom DI, option-B 18.5 ft span) |
| VT (15.3) | 313.06 | 313.06 | −0.002 | `S_vt` geom DI |
| Fuselage (15.4) | 3674.20 | 3674.20 | 0 | `L_fus`/`D_fus`/`W_fus` values unchanged by DI (only provenance changes) |
| LG main (15.5) | 903.52 | **989.98** | **+86.46** | `W_l` 20681 (frozen) → **0.95·31377 = 29808.15** (decision 4) |
| LG nose (15.6) | 153.75 | **170.95** | **+17.20** | same |
| **LG total** | **1057.27** | **1160.9336** | **+103.66 (+9.81 %)** | decision 4 |
| Engine `.engine` + `.section` (15.9) | 3072.32 | **2814.75** | **−257.57** | `W_en` 3030 `[estimate]` → **2775.0210 UNINSTALLED** (decision 1) |
| **Engine group total** | **3639.26** | **3381.6984** | **−257.57** | decision 1 |
| Systems `.fuel_sys` (15.16) | 386.79 | **423.465** | **+36.67 (+9.48 %)** | `SFC_mission` 0.70 → **1.007116** (decision 2); `V_t` = 940 unchanged (decision 3) |
| **Systems group total** | **4541.46** | **4578.1340** | **+36.67** | decision 2 |
| **`OEW(31377)`** | **15818.48** | **15705.3313** | **−113.15** | **−21.40 %** vs `Wt!B12`; **−17.98 %** vs `corrections.xls` |
| **`OEW(45000)`** | **16870.15** | **16869.6310** | **−0.52** | −15.57 % vs `Wt!B12`. The near-zero net at 45,000 lbf is a **coincidence** — +215.90 from the now-live LG, −257.57 from `W_en`, +36.67 from SFC, +4.4 from `S_ht`. Do **not** read it as "nothing changed" |
| **`OEW(60000)`** | *(never quoted on the frozen-`W_l` code)* | **17930.7085** | — | recomputed live 2026-07-25 for the F.5 mutation table |

**Rejected variant, recorded so the decision stays auditable:** with `W_en` × 1.3 = 3607.5273 the L3
`OEW(31377)` would be **16546.06**, i.e. **−17.19 %** vs `Wt!B12` — *closer* than the settled
−21.40 %. Per decision 1 that closer agreement is the **evidence against** `×1.3`, since it comes from
double-counting the installation hardware Eqs. 15.7–15.15 already supply. A number that agrees because
a factor is counted twice is not agreement.

Remaining OPEN-item sensitivities *(live, each applied alone on the as-built 15705.3313)*. All four are
carried as rows in section 6 of the comparison report, so the open decisions are visible in the output
rather than only in a doc:

| Still-open item | Choice | `OEW` | Δ | Status |
|---|---|---|---|---|
| `L_d` ← `geom.L_duct` | 7.5 → 14.0 | 15906.80 | +201.47 | §P4-4, **OPEN** |
| `D_e` ← `geom.D_exit` | 3.33 → 3.537022 | 15730.27 | +24.94 | §P4-4, **OPEN** |
| `design_mach` ← T.O. 2.05 | 2.0 → 2.05 | 15725.41 | +20.08 | §P4-13, **OPEN** — a citation question, not a value one |
| `K_d` = 0 (legal straight duct) | induction 227.54 → **0.0000** | **15477.7874** | −227.54 | §P4-11, **OPEN — unguarded by decision 6** (Part G) |

### F.4 Unit-test outcome, as built

`run_all_tests`: **491/501, all 10 reds labelled `testTODO_`, zero unlabelled reds.**
Per weights file: `TestWeightsL1` 25 cases (24 green + `testTODO_RaymerTable61CoefficientsNotInRepo`),
`TestWeightsL2` 38 cases all green, `TestWeightsL3` 44 cases (43 green +
`testTODO_Raymer1531ExponentsNotBookVerified`) — all counted by running each file 2026-07-25.

The three ±-tolerance OEW-vs-Brandt gates (`TestWeightsL1.testOEWWithinBrandsValue` ±8 %,
`TestWeightsL2.testOEWWithinBrandtValue` ±20 %, `TestWeightsL3.testOEWWithinBroadBounds` ±40 %) were
**removed** rather than re-based (E.4). Worth recording why the L2 one in particular had to go: at the
as-built −18.19 % it sat a hair inside its ±20 % band, so the only ways to keep it green would have been
to widen the tolerance or to re-derive the expected from the answer — both the self-referential trap.

★ `TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO` is the eleventh `testTODO_`-named case in
the suite and the only one that **passes**: it was written to be red while the `requireWTO` over-guard
existed, and the over-guard was removed in the same phase. Its docstring still says "EXPECTED RED" and
still gives a resolve-recipe for work already done — a stale test docstring, flagged for review
(§P4-18).

### F.5 ★ §P4-17 — L3's landing gear was frozen under mutation too — **FIXED**

Not among the original 15 review findings; surfaced while quantifying decision 4. Pre-Phase-4 `W_l` =
20681 was a stored constant **and** `WeightsL3.weight_landing_gear` took no `W_TO` argument, so
**`WeightsL3`'s entire landing-gear group was completely insensitive to `W_TO`**. Both halves are
fixed. Verified live 2026-07-25:

| `W_TO` | `WAS` LG total | **AS-BUILT** LG total (`W_l` = 0.95·`W_TO`) |
|---|---|---|
| 31,377 | 1057.273 | **1160.9336** |
| 45,000 | **1057.273** | **1273.1680** |
| 60,000 | **1057.273** | **1370.4685** |

Same defect class as review finding #5 (`W_all_else_empty` frozen at `0.17·31377`), same signature — a
Brandt **output** (`Wt!B41` = 20680.700578, `=SUM(B16:B32)`) frozen as an input — one tier up. Guards:
`TestWeightsL3.testLandingGearScalesWithWTO`, `testLandingGearIsNotTheFrozenValue`,
`testLandingGearArgumentWinsOverStaleObjectWTO`, `testLandingWeightIsDerivedFromWTO`.
todo 2026-07-25 §P4-17 — **RESOLVED**. The uncited `0.95` (§P4-16) is a separate, **OPEN** item.

---

## Part G — Not consumed / structural gaps

- Brandt models **nacelles** (`Wt!G9` 186.817478), **strakes** (`Wt!H9` 90.0), **armament support**
  (`Wt!B31` 440.0) and a lumped **other structure** (`Wt!B29` 2016.862295) with **no framework
  analog** — 2733.68 lbf, 13.7 % of `Wt!B12`. Report as `NOT MODELED`, never as error.
- L3 produces per-item engine/systems weights Brandt does not tabulate — group-level comparison only.
- **`aircraft_category` at L3 — RESOLVED (§P4-9).** `F16WeightsL3` now carries the property (read from
  the JSON's top level), and no `WeightsL3` static reads it — correct **by construction**, since
  `WeightsL3` implements only the Fighter/Attack build-up, so there is one path and no category lookup.
  It exists for interface parity with L1/L2 and for report labelling.
  `f16a_L3.json .weights._note`'s claim that "Raymer §15.3.1 exponents/coefficients are
  aircraft_category-selected toolbox Constants" was **false** — every §15.3.1 coefficient is a bare
  literal inside a `WeightsL3` static — and the note is corrected, with the old wording recorded as wrong.
- **`W_subsystems` contract — RESOLVED (§P4-10).** `WeightsModelL3`'s comment used to say "Includes
  landing gear"; `WeightsL3.OEW` adds `W_lg.main + W_lg.nose` **separately** from `W_sys.total`, and
  `weight_systems` contains no LG term. The comment now states that, records the old wording as wrong,
  and points at `weight_landing_gear(obj, W_TO)`. Guard:
  `TestWeightsL3.testSystemsGroupContainsNoLandingGearTerm`.
- **`WEIGHTSMODELG3` typo — RESOLVED** (todo 2026-07-24 §3c item 5). The banner is gone; the property
  block now carries the input/derived banners instead.
- **★ A false verification claim was REMOVED from `WeightsL3.m`'s header (new this step).** It asserted
  the §15.3.1 exponents had been *"re-verified letter-for-letter against the Raymer 6th ed. p.572
  equation page image (not OCR)"* — unverifiable (no such image is anywhere in this repo) and in direct
  contradiction with the `[verify]` warnings on the same equations in the same file. Replaced by an
  honest tally — **2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY / 5 extract-clean** — with the
  IMAGE-ONLY entry stating plainly that the claim was not checkable. The same wording was stripped from
  the wing / HT / VT / fuselage / gear / mounts method comments. **Zero exponent values changed.**
  todo §P4-19.
- **★ `K_d` — NO CHANGE this phase (settled decision 6), and the silent zero stands.**
  `WeightsL3.air_induction` (Eq. 15.10) contains `K_d^0.182`, and `WeightsL3.m:276` documents
  **`K_d = 0` as the legitimate "straight duct" value**. `0^0.182 = 0`, so a legal, documented input
  **silently zeroes the entire 227.54 lbf air-induction component** — no error, no warning, not even a
  `NaN` to notice. This is the same silent-zero class as the Phase-1 `F16GeomL1` defect where
  `CD0 = Cfe·S_wet/S_ref` with a frozen `S_wet = 0` returned `CD0 = 0` and an infinite L/D. The user
  chose to leave it: **no guard is added, and this description is not softened.** Note the corollary —
  the code's `K_d` cannot be Raymer's `K_d` as a multiplicative base, because a straight duct does not
  weigh zero, so the term's exponent or placement is itself suspect. That is `todo §3a` checklist row 7
  (`K_d` exponent 0.182, `[VERIFY]`). **§P4-11 stays OPEN.**
- **Other weights-side domain guards deferred from Phase 1e**
  (`~/.claude/plans/serene-conjuring-kitten.md` §1e last bullet) — also **not added this phase**, to
  keep scope consistent with decision 6: `H_v = 0` → `1 + H_t/H_v` = `NaN` (at `H_t = 0`) or `Inf` in
  Eq. 15.3; `L_s = 0` → `(L_s/L_d)^−0.373` = `Inf` in Eq. 15.10; `V_t = 0` → `(1+V_i/V_t)` = `Inf` in
  Eq. 15.16 (reachable only via an explicit JSON `0` now that `V_t` stays a 940 input per decision 3).
  §P4-11.
