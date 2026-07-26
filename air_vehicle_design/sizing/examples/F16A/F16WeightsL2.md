# F16WeightsL2

**STATUS: AS-BUILT (reconciled 2026-07-25, step 2d).** This doc previously described the Phase-4
*target*; everything below now describes what shipped. Rows still tagged `AS-IS` describe the
**pre-Phase-4** code and are kept only where they explain a defect that was fixed — read them as `WAS`.
All six settled decisions of 2026-07-25 are implemented (`docs/weights_parameter_usage.md` §3);
L2 is touched by two — `×1.3` is **L2-only** (decision 1) and `design_mach` arrives from the
requirements file (decision 5).

F-16A Block 10/15 Level-2 weight concrete class (`classdef F16WeightsL2 < WeightsModelL2`). Structural
groups use Raymer Table 15.2 surface-density (psf × area); engine + all-else use the AE481 metabook §7
fractions. Every abstract method is a single delegation line into the `WeightsL2` static toolbox.

**This doc also carries the `weights_brandt_comparison` report documentation — §G** (it began as the
spec and is now the as-built description). That location was a deliberate choice; `F16WeightsL1.md` and
`F16WeightsL3.md` cross-reference it rather than duplicating it.

Numbers marked *(live)* were computed 2026-07-25 via `mcp__matlab__evaluate_matlab_code`. Brandt cells
marked *(live)* were read directly from `VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` over Excel COM
(`actxserver`, read-only, closed without saving) the same day.

---

## A. Constructor / input mechanism — as built

```matlab
prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);
w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
```

| | As built | `WAS` (pre-Phase-4) |
|---|---|---|
| Signature | **`F16WeightsL2(json_path, req_path, geom, prop)`** — all four required, no silent default | `F16WeightsL2()` — no-arg |
| `geom` guard | `geom (1,1) GeometryModelL2` — the L2 **enforcer**, not `GeometryBase`. `GeometryModelL2.m` abstractly declares all four members L2 weights reads (`S_exposed_wing`, `S_exposed_ht`, `S_exposed_vt`, `get_S_wet_fuselage`), so the guard is tight enough, and a wrong tier fails at **construction** rather than mid-run (finding #10's lesson) | *(none — there was no `geom`)* |
| `prop` guard | `prop (1,1) PropulsionBase` | *(none)* |
| Spec data | `jsondecode(fileread(json_path))` → top-level `aircraft_category` + `.weights.{N_en, W_payload_fixed, W_payload_expendable}` | hardcoded classdef defaults |
| Requirements | `jsondecode(fileread(req_path))` → **`design_mach`** (decision 5; §B.3) | *(none)* |
| Constructor body | sets **only** input properties; every derived quantity is a `Dependent` getter | **computed two derived values and froze them** — see §D.1 |

`f16a_L2.json .weights` is Phase-3 minimal and unchanged: `N_en: 1`, `W_payload_fixed: 700`,
`W_payload_expendable: 4400`. The Mach that Eq. 10.10 needs comes from `f16a_requirements.json`, not
from `.weights` (§B.3).

---

## B. INPUT vs DERIVED classification — as built

Pattern per CLAUDE.md → "Optimization-ready property design"; reference implementation
`examples/F16A/F16GeomL2.m` header. **Inputs** = plain mutable `properties`, set once by the
constructor. **Derived** = `properties (Dependent)`, `get.<name>` recomputes live on every read, no
stored/cached copy, read-only (assigning errors — they are outputs).

**COUNTS, verified live 2026-07-25 from the metaclass `PropertyList`: 9 plain / 12 `Dependent`** —
the 9 plain being **7 INPUTS (6 numeric + `aircraft_category`) + 2 injected objects** (`geom`, `prop`).
The 7th input is `design_mach`, read from `f16a_requirements.json`.

`WAS`, pre-Phase-4: **17 plain properties, 0 `Dependent`** — 6 genuine inputs (`aircraft_category`,
`N_en`, `W_TO`, `W_energy`, both payloads), 4 frozen geometry constants (`S_w`, `S_ht`, `S_vt`,
`S_wet_fus`), 1 frozen engine constant (`W_en`), 4 NaN placeholders (`W_wings`, `W_landing_gear`,
`W_tail`, `W_fuselage`) and 2 constructor-frozen derived values (`W_installed_engine`,
`W_all_else_empty`). 11 of the 17 moved; `design_mach` was added; `geom`/`prop` are new.

### B.1 INPUTS (7 = 6 numeric + `aircraft_category`) + 2 injected objects

| # | Property | Value | Units | Source | Citation | Why an input (not derived) |
|---|---|---|---|---|---|---|
| 1 | `aircraft_category` | `'jet_fighter'` | — | JSON top-level | `[f16a_L2.json aircraft_category]` — one canonical flag per aircraft | Classification. Selects the Raymer Table 15.2 psf row and the metabook §7 LG fraction |
| 2 | `N_en` | 1 | — | `.weights.N_en` | `[T.O. 1F-16A-1 Sec. I]` | Engine count. Not derivable — no propulsion class exposes a count (`F16PropL2` has none; `geom.n_engines` exists only as a `.geometry` stopgap, todo 2026-07-25 Phase 2 §22) |
| 3 | `W_payload_fixed` | **700** (AS-IS 220) | lbf | `.weights` | `[Brandt Wt!B4 = 700.000000 (live), formula =Main!O16]` | Mission spec |
| 4 | `W_payload_expendable` | **4400** (AS-IS 0) | lbf | `.weights` | `[Brandt Wt!B5 = 4400.000000 (live), formula =Main!O17]` | Mission spec |
| 5 | `W_TO` | `NaN` | lbf | **state** | `WeightsBase` contract | The optimizer's variable, mutated in place by the sizing loop |
| 6 | `W_energy` | `NaN` (AS-IS **6296.3**) | lbf | **state** | `WeightsBase` contract | Set by mission analysis. **AS-IS 6296.3 is a Brandt OUTPUT** — `Wt!B6` = `=B3-B4-B5-B12` *(live formula)*. Deleted from the JSON in Phase 3 |
| 7 | `design_mach` | **2.0** | — | **`f16a_requirements.json`** | `[Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9]` — ★ **NOT** the T.O. Mach limit 2.05 (`f16a_ground_truth.json:228`); see `docs/weights_parameter_usage.md` §5 | Design max Mach: an aircraft **requirement**, not weights spec data, hence the separate file. Feeds Raymer Eq. 10.10's `M^0.25` for `W_en` |
| — | `geom` | `F16GeomL2` | — | **injected** | — | Not numeric. Supplies the four geometry quantities in §B.2 rows 1–4 |
| — | `prop` | `F16PropL2` | — | **injected** | — | Not numeric. Supplies `prop.T_SL` and `prop.bypass_ratio` for `W_en` |

### B.2 DERIVED (12) — `properties (Dependent)`, recomputed live

| # | Derived | Formula / delegation | Value at `W_TO`=31377 *(live)* | Citation | Kind change from `WAS` |
|---|---|---|---|---|---|
| 1 | `S_w` | `geom.S_exposed_wing` | 196.2261 ft² | `[Brandt Geom!7 exposed-S wing row; readme_geom.md §4.3]` via `GeomL2.compute_S_exposed_horizontal` | **stored input 196.23 → DERIVED** (geometry DI) |
| 2 | `S_ht` | `geom.S_exposed_ht` ★ **not** `geom.S_ht` = 108 | 49.8473 ft² | same static, HT chords | **stored input 49.85 → DERIVED** |
| 3 | `S_vt` | `geom.S_exposed_vt` ★ **not** `geom.S_vt` = 60 | 40.8897 ft² | `GeomL2.compute_S_exposed_vertical`; `[readme_geom.md §4.3]` | **stored input 40.89 → DERIVED** |
| 4 | `S_wet_fus` | `geom.get_S_wet_fuselage()` | **730.3023 ft²** | `[Roskam Vol. II Eq. 12.3]` via `GeomL2.compute_s_wet_fus_cyl` | **stored `[estimate]` 750 → DERIVED**; −2.627 % |
| 5 | `W_en` | `PropL2.engine_weight_AB(prop.T_SL, design_mach, prop.bypass_ratio)` — **uninstalled** | **2775.0210 lbf** | `[Raymer 7th ed. Eq. 10.10]`, coefficient 0.0637 confirmed at `raymer_data.md:38` | **stored `[estimate]` 3030 → DERIVED** (OFFICIAL) |
| 6 | `W_en_brandt` | `0.199 · prop.T_SL` | **4730.2300 lbf** | `[Brandt Wt!B11 = 4730.230000 (live)]`; the 0.199 literal is `'Engn(s)'!D22 = 0.199` *(live)*, label `'Engn(s) Old'!C22` = `"Engine with AB:  Weng = "`; `readme_wt.md:230` attributes it to Brandt 1997 Table 6.2 | **NEW** — comparison-report alternate only, **never summed into `OEW`** |
| 7 | `W_wings` | `WeightsL2.weight_wing(obj, obj.W_TO)` = `9.0·S_w` | **1766.03 lbf** | `[Raymer 7th ed. Table 15.2, fighter wing 9 lb/ft²]`, `metabook_data.md:321` | **NaN placeholder → DERIVED** (finding #12) |
| 8 | `W_tail` | `WeightsL2.weight_tail(obj, obj.W_TO)` → `struct('HT', 4.0·S_ht, 'VT', 5.3·S_vt)` | HT **199.39**, VT **216.72** lbf | `[Raymer 7th ed. Table 15.2]`, `metabook_data.md:322` (HT 4) / `:323` (VT 5.3) | **NaN placeholder → DERIVED** |
| 9 | `W_fuselage` | `WeightsL2.weight_fuselage(obj, obj.W_TO)` = `4.8·S_wet_fus` | **3505.45 lbf** | `[Raymer 7th ed. Table 15.2, fuselage 4.8 lb/ft²]`, `metabook_data.md:324` | **NaN placeholder → DERIVED** |
| 10 | `W_landing_gear` | `WeightsL2.weight_landing_gear(obj, obj.W_TO)` = `0.033·W_TO` | **1035.44 lbf** | `[AE481 metabook §7 fraction table, non-Navy fighter]`, `metabook_data.md:330` | **NaN placeholder → DERIVED**; genuinely `W_TO`-dependent, so freezing was never an option |
| 11 | `W_installed_engine` | `1.3 · N_en · W_en` | **3607.5273 lbf** | 1.3 installed/bare factor `[AE481 metabook §7]`, `metabook_data.md:333` | **constructor-frozen → DERIVED**; freeze was harmless (`W_TO`-independent) but it hid `W_en` behind a literal |
| 12 | `W_all_else_empty` | `0.17 · obj.W_TO` | **5334.09 lbf** at 31377; **7650.00** at 45000 | `[AE481 metabook §7]`, `metabook_data.md:334` | ★ **constructor-frozen at `0.17·31377` → DERIVED. This is review finding #5** — see §D.1 |

`OEW(W_TO)` stays a **method** (the `WeightsBase` contract takes `W_TO` as an argument, so it cannot
go stale). It sums rows 7–12: `W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear +
W_installed_engine + W_all_else_empty`.

**Unset-`W_TO` behaviour — as built, and NOT uniform on purpose.** Only the two getters with a **real**
`W_TO` dependence are guarded:

| Getter | Guarded by `requireWTO`? | Reading it with `W_TO = NaN` |
|---|---|---|
| `W_landing_gear` (`0.033·W_TO`) | **yes** | throws `F16WeightsL2:WTONotSet` *(verified live)* |
| `W_all_else_empty` (`0.17·W_TO`) | **yes** | throws `F16WeightsL2:WTONotSet` *(verified live)* |
| `W_wings`, `W_tail`, `W_fuselage` | **no** | returns the correct value — 1766.0346 / 199.3890 / 3505.4511 *(verified live)*. `WeightsL2.weight_wing/weight_tail/weight_fuselage` declare their second argument as `~`: pure area × density, no `W_TO` term at all |
| `W_installed_engine` (`1.3·N_en·W_en`) | **no** | returns 3607.5273 — a thrust correlation, `W_TO`-independent |

The guard follows the Phase-1f precedent (`F16GeomL1.requireWTO`): **error with an identified message,
never a silent `NaN`.** But it is applied **only where the dependency exists**. An earlier Phase-4
revision guarded five of the six "for uniformity" and its docstring claimed the guard applied
"UNIFORMLY to all six" — which was untrue twice over (it was five, and three of them have no `W_TO`
dependence). The principle now recorded in code: *a guard must encode a real dependency, not a house
style.* todo 2026-07-25 Phase 4 §P4-18.

### B.3 Where Eq. 10.10's two missing arguments come from — as built

Raymer Eq. 10.10 is `W = 0.0637·T^1.1·M^0.25·e^(−0.81·BPR)`. An earlier revision flagged that neither
`M` nor `BPR` was reachable. Both are resolved as built:

| Argument | Source, as built | Value | `WAS` |
|---|---|---|---|
| `T` | `prop.T_SL` | 23770 | already available |
| `M` | **`f16a_requirements.json` → `design_mach`** (decision 5) | **2.0** | **no Mach existed anywhere at L2** — `f16a_L2.json .geometry` has no `M_max`, `.aerodynamics` has none, `F16PropL2` exposed none. Only `f16a_L1.json .geometry.M_max` and `f16a_L3.json .weights.vertical_tail.M_design` had it. Closes §P4-3 |
| `BPR` | `prop.bypass_ratio` | **0.71** — `isprop(prop,'bypass_ratio')` = **1**, verified live 2026-07-25 | `f16a_L2.json .propulsion.bypass_ratio = 0.71` existed but `F16PropL2` neither declared nor read it (`isprop` = 0). The property was added outside this phase. Closes §P4-2. Its `_TODO_bypass_ratio` marker (0.71 untraceable in-repo) **stays open** |

**The requirements file is new** — `examples/F16A/f16a_requirements.json` + `f16a_requirements_path.m`,
not per-fidelity-level, partly reviving PLAN.md's Step-0 `requirements.json` that `docs/PLAN.md` used to
record as never built (that line is now corrected). Full shape and reads are in
`docs/weights_parameter_usage.md` §2. **One correction repeated here because it will otherwise be
copied into code:** `design_mach = 2.0` must be cited to **Brandt** (`GroundTruth/f16a_geometry.json:9`,
`"Mmax": 2.0`), **not** to the T.O. Mach limit, which is **2.05** (`f16a_ground_truth.json:228`).
2.0 ≠ 2.05, −2.44 %; live `W_en` sensitivity 2775.0210 → 2792.2046, +0.62 %. **todo §P4-13 stays open.**

---

## C. Methods — all delegate to `WeightsL2`

| Method | Delegates to | Formula | Value at 31377 *(live)* | Citation | Units |
|---|---|---|---|---|---|
| `OEW(W_TO)` | `WeightsL2.OEW` | Σ of §B.2 rows 7–12 | **15664.65** | `[Raymer 7th ed. Table 15.2 + AE481 metabook §7]` | lbf |
| `weight_wing(W_TO)` | `WeightsL2.weight_wing` | `ρ_w·S_w`, `ρ_w` = 9.0 | 1766.03 | `[Raymer 7th ed. Table 15.2]` | lbf |
| `weight_tail(W_TO)` | `WeightsL2.weight_tail` | `ρ_ht·S_ht`; `ρ_vt·S_vt`; `ρ_ht`=4.0, `ρ_vt`=5.3 | 199.39 / 216.72 | `[Raymer 7th ed. Table 15.2]` | lbf (struct) |
| `weight_fuselage(W_TO)` | `WeightsL2.weight_fuselage` | `ρ_fus·S_wet_fus`, `ρ_fus` = 4.8 | 3505.45 | `[Raymer 7th ed. Table 15.2]` | lbf |
| `weight_landing_gear(W_TO)` | `WeightsL2.weight_landing_gear` | `f_lg·W_TO`, `f_lg` = **0.033** | 1035.44 | `[AE481 metabook §7]`, `metabook_data.md:330` | lbf |

`weight_wing`/`weight_tail`/`weight_fuselage` ignore their `W_TO` argument (`~` in the static's
signature) — pure area × density. Only `weight_landing_gear` and `W_all_else_empty` scale with `W_TO`.

### C.1 Lookup constants, transcribed from a named repo extract

All from `temp_AI/docs/disciplines/reference_extracts/metabook_data.md` §7.

| Static | Row | Value | Extract line | Match |
|---|---|---|---|---|
| `wing_unit_weight` | fighter / transport / GA | 9.0 / 10.0 / 2.5 lb/ft² | `:321` | ✅ all three |
| `HT_unit_weight` | fighter / transport / GA | 4.0 / 5.5 / 2.0 | `:322` | ✅ all three |
| `VT_unit_weight` | fighter / transport / GA | 5.3 / 5.5 / 2.0 | `:323` | ✅ all three |
| `fus_unit_weight` | fighter / transport / GA | 4.8 / 5.0 / 1.4 | `:324` | ✅ all three |
| `LG_fraction` | `jet_fighter` 0.033 | | `:330` | ✅ |
| `LG_fraction` | `jet_transport` 0.043 | | `:332` | ✅ |
| `LG_fraction` | `general_aviation` **0.057** | | — | ❌ **UNCITED — see §D.3** |
| *(absent)* | Navy fighter 0.045 | | `:331` | extract has a row the code lacks |
| installed-engine factor | 1.3 × bare | | `:333` | ✅ |
| all-else-empty fraction | 0.17 × W0 | | `:334` | ✅ |

The extract states the fraction basis is `W0`, i.e. takeoff gross weight — consistent with
`0.17·W_TO` and `0.033·W_TO`.

> **★ Citation correction (settled 2026-07-25, §P4-7): the fractions are NOT Raymer Table 15.2.**
> The locked plan phrases this decision as "landing-gear ratio **0.033** (Raymer **Table 15.2**, NOT
> Brandt's 0.034)". In the repo extract, **Table 15.2 is the psf surface-density table only**
> (`metabook_data.md:317-324`, four rows). The landing-gear / installed-engine / all-else-empty
> *fractions* are a **separate, unnumbered** metabook table (`:326-334`) that carries **no Raymer table
> number at all**. So the correct citation for `0.033`, `1.3` and `0.17` is
> `[AE481 metabook §7, "Fraction-Based Weight Estimates" table]` — which is exactly what
> `WeightsL2.m:169,92,99` already say. **Nothing numeric changes** (0.033 is the coded value today);
> the plan's table attribution is what needs correcting, not the code.

---

## D. Deviations, limitations, standing TO-DOs

### D.1 ★ Review finding #5 — `W_all_else_empty` frozen at a Brandt output — **FIXED**

Quoted so the fix stays traceable. The pre-Phase-4 `F16WeightsL2.m:76` read:

```matlab
% Nominal F-16A Block 10/15 baseline TOGW [T.O. 1F-16A-1 / Brandt B38]
% used as the W_TO input to the 0.17xW_TO all-else-empty fraction.
obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377);
```

`WeightsL2.OEW` (`WeightsL2.m:49-50`) then reads that **frozen** property, so `OEW(W_TO)` never
recomputes the `0.17·W_TO` term at the passed `W_TO`. Two separate defects in one line:

1. **Stale under mutation.** Reproduced live 2026-07-25: `w2.OEW(45000)` carries an all-else group of
   `0.17·31377` = **5334.09** where `0.17·45000` = **7650.00** is required — **understated by
   2315.91 lbf**. Every `TestWeightsL2` case calls `OEW(31377)`, the single argument at which the bug
   is invisible, which is why no test caught it.
2. **A Brandt output used as a calibration input.** 31,377 is `Brandt Wt!B3` = **31377.000000**
   *(live)*, formula `=Main!O15` — a sizing **output**, explicitly forbidden as an input by CLAUDE.md
   ("do not hardcode Brandt's back-calculated calibration values"). The comment even labels it
   "Brandt B38" (`Wt!B38` = 31377.000000, `=SUM(B16:B37)`), i.e. openly a Brandt figure.

**FIX AS BUILT:** `W_all_else_empty` is `Dependent` = `0.17 · obj.W_TO` (§B.2 row 12) and
`WeightsL2.OEW` recomputes the term at its own `W_TO` argument. **Shipped guards:**
`TestWeightsL2.testOEWScalesWithItsArgumentNotAFrozenWTO` and
`testOEWDoesNotUnderstateByTheFrozenAllElseAmount` — the delta is exactly
`(0.17 + 0.033)·13623` = **2765.4690** lbf, and the live check matches to `AbsTol`:
`18430.1173 − 15664.6483 = 2765.4690`.
`W_installed_engine` is `W_TO`-independent so its freeze was numerically harmless, but it is
`Dependent` too — otherwise mutating `prop.T_SL` would leave it stale now that `W_en` is Eq. 10.10 on
the injected thrust (`testDerivedLiveRecomputeOnMutation` locks that).

Logged: todo 2026-07-24 §3c item 1 — **RESOLVED**.

### D.2 ★ Review finding #12 — four NaN "computed total" properties — **FIXED**

`WeightsModelL2` declares `W_wings`, `W_landing_gear`, `W_tail`, `W_fuselage` abstract with comments
saying "computed … weight" / "set by `weight_tail`". Pre-Phase-4 `F16WeightsL2.m:54-57` satisfied them
with `= NaN`, and **no code ever assigned them** — `WeightsL2.OEW` computed locally into
`W_w`/`W_t`/`W_f`/`W_lg` and discarded. A consumer reading the documented contract (`w2.W_wings`) got
`NaN`. **As built:** all four are `Dependent` (§B.2 rows 7–10);
`TestWeightsL2.testAllTwelveDependentPropertiesExist` and `testNoDependentPropertyIsNonFinite` lock it
(zero non-finite reads, with `W_TO` set). Logged: todo 2026-07-24 §3c item 6 — **RESOLVED**.

### D.3 `LG_fraction('general_aviation') = 0.057` is uncited

`WeightsL2.m:173` cites "AE481 metabook §7". The extract's fraction table
(`metabook_data.md:328-334`) has **no GA landing-gear row** — only fighter 0.033, **Navy fighter
0.045**, transport 0.043. So the GA value has no repo source, and the Navy-fighter row the extract
*does* carry is absent from the code. New item, todo 2026-07-25 Phase 4 §P4-7. Neither affects the
F-16 (`jet_fighter`), so this is a citation-integrity item, not a numeric one.

### D.4 LG fraction 0.033 (framework) vs 0.034 (Brandt) — LOCKED at 0.033

Verified live: `Wt!F23 = 0.034000` (bare literal), `Wt!B8 = =B3*F23`, `Wt!B23 = =B8` =
**1066.818000** lbf. `readme_wt.md:243` §5.11 and `:342` both give `0.034 × W_TO`. Locked decision
(user 2026-07-24): use Raymer/metabook **0.033**, *not* Brandt's 0.034. Two different models —
reported side by side in §G, never as an error. todo 2026-07-24 §3c item 2.

### D.5 ★ The `×1.3` installation factor — SETTLED: L2 only, and never on the Brandt alternate

**SETTLED (user, 2026-07-25, decision 1).**

**(a) `×1.3` applies at L2 and ONLY at L2.** L2's OEW has no separate installation components, so the
single 1.3 factor `[AE481 metabook §7, metabook_data.md:333]` is the right model here. **L3 uses the
UNINSTALLED 2775.0210** because §15.3.1 builds the installation up item by item — see
`F16WeightsL3.md` §D.2. Closes §P4-1b.

**(b) The Brandt alternate is ALREADY installed — it gets NO ×1.3.** `readme_wt.md:230` states
verbatim: *"This is the **installed engine weight** formula for afterburning turbofan/turbojet engines
(Brandt 1997, Table 6.2)."* Live consequence at `W_TO` = 31377:

| `W_installed_engine` | Value *(live)* | L2 `OEW` *(live)* | vs `Wt!B12` | Status |
|---|---|---|---|---|
| Raymer 2775.0210 × 1.3 | **3607.5273** | **15664.65** | −21.60 % | ★ **OFFICIAL** |
| Brandt 4730.23, **no** ×1.3 | 4730.2300 | **16787.35** | −15.98 % | ★ **the alternate, as-is** |
| Brandt 4730.23 × 1.3 | 6149.2990 | 18206.42 | −8.88 % | **REJECTED — double-installed** |

The rejected variant reads *closest* to Brandt, which is exactly why it is rejected: **agreement
produced by a double-counted factor is not agreement.** Closes §P4-1a.

The `0.199` literal's cell is now on record — `'Engn(s)'!D22 = 0.199` *(live)*, routed through
`'Engn(s) Old'!D22`, label `'Engn(s) Old'!C22` = `"Engine with AB:  Weng = "`. `readme_wt.md:230`
attributes it to Brandt 1997 Table 6.2 but names **no cell**; that gap is closed in todo §P4-0.

### D.6 Table 15.2 ρ coefficients differ from Brandt's own psf coefficients

Framework: wing 9.0, HT 4.0, VT 5.3, fus 4.8. Brandt `Wt!C7:H7`, verified live: wing **6.75**,
fuselage **5.0**, pitch **6.0**, VT **6.0** (`=E7`), nacelle 4.5, strake 4.5. Two different psf
models — comparison rows, not errors.

**And the areas differ in KIND.** Brandt's `Wt!E9` = `=E7*Main!C18*…` = 6.0 × **108** and `Wt!F9` =
`=F7*Main!H18*…` = 6.0 × **60** use the **FULL** planform areas; the framework uses the **EXPOSED**
areas per Raymer Table 15.2's own definition (49.8473 / 40.8897 at L2). The tail rows are therefore
`DEFINITIONAL`, not `BY DESIGN` — see §G.3.

### D.7 Other items

- **Edition re-cite — DONE.** 6th ed. → **7th ed.** throughout, no value change. todo §3c item 4.
- **`geom` type guard — DONE.** `geom (1,1) GeometryModelL2`, enforced at construction (§A), locked by
  `TestWeightsL2.testWrongGeomTierErrorsAtConstruction`. The Phase-2d lesson it answers:
  `F16AeroL2`/`F16AeroL3` accepted the too-loose `GeometryBase`, a wrong tier constructed fine, and
  property names then resolved to different physical quantities with no error (finding #10).
- **Domain guards (deferred from Phase 1e) — still not added at L2, and none is needed.** L2 has none
  of the div-by-zero paths (they are all in `WeightsL3`); the one silent-zero risk — `S_wet_fus`
  arriving `0` from a mis-injected `F16GeomL1`, giving `W_fuselage = 0` — is closed by the
  construction-time type guard above rather than by a value guard.

---

## E. Values — as built (computed live 2026-07-25)

| Component | `WAS` (pre-Phase-4) | **As built** | Δ |
|---|---|---|---|
| Wing | 1766.07 | **1766.0346** | −0.04 |
| HT | 199.40 | **199.3890** | −0.01 |
| VT | 216.72 | **216.7152** | −0.0002 |
| Fuselage | 3600.00 | **3505.4511** | **−94.55** |
| Landing gear | 1035.44 | **1035.4410** | 0 |
| Installed engine | 3939.00 | **3607.5273** | **−331.47** |
| All-else-empty | 5334.09 (**frozen**) | **5334.0900** (live) | 0 **at 31377 only** |
| **`OEW(31377)`** | **16090.72** | **15664.6483** | **−426.07** |
| **`OEW(45000)`** | **16540.28** | **18430.1173** | **+1889.84** |

`OEW(31377)` vs ground truth: **−21.60 %** of `Wt!B12` = 19980.700578; **−18.19 %** of
`corrections.xls` 19148.08. With the Brandt `W_en` alternate: 16787.35, i.e. −15.98 % / −12.33 %.

★ **The finding-#5 fix is visible in the `OEW(45000)` row**, and only there:
`18430.1173 − 15664.6483 = 2765.4690` = `(0.17 + 0.033) · 13623` exactly. At 31,377 the numbers are
identical either way, which is precisely why every pre-Phase-4 test — all of which called `OEW(31377)`
— missed the bug.

---

## F. Unit tier — as built

**The OEW-vs-Brandt agreement check LEFT the unit tier**, per CLAUDE.md's two-tier rule.
`TestWeightsL2` as shipped: **38 cases, all green** (verified 2026-07-25).

| Test | Disposition | Why |
|---|---|---|
| `testOEWWithinBrandtValue` (`expected = 19148` cited "[Brandt B12]") | **REMOVED** → now a report row against **19,980.70** with 19,148.08 in `Alt` | Finding #14: `Wt!B12` is live-verified **19980.700578**. Also −18.19 % against a ±20 % tolerance was a hair from red, and adjusting the tolerance to keep it green would have been exactly the self-referential trap |
| `testOEWLessThanWTO`, `testOEWGreaterThanZero`, `testOEWAboveSanityMinimum` (`OEW > 0.30·W_TO`; live 15664.6483/31377 = 0.499) | KEPT / ADDED | Physical invariants and an engineering sanity bound, no external expected |
| `testWingUnitWeightAllCategories`, `testTailUnitWeightsAllCategories`, `testFuselageUnitWeightAllCategories`, `testLGFractionCitedRows` | KEPT, widened to all categories | Table constants, expecteds transcribed from `metabook_data.md:321-324`/`:330`/`:332` with the line numbers in the comment block |
| `testLGFractionHasNoNavyFighterRow` | **ADDED** | Locks the §D.3 / §P4-7 gap as a *known* absence rather than an accident |
| `testLookupUnknownCategoryErrors`, `testUnknownCategoryPropagatesThroughTheBuildup` | KEPT / ADDED | Error contract, and that a bad category fails loudly through `OEW` rather than silently |
| `testIsa*` ×3, `testJetFighterCategorySetCorrectly` | KEPT | Contract/interface |
| `testWingWeightHandComputed`, `testTailWeightsHandComputed`, `testFuselageWeightHandComputed`, `testLandingGearWeightHandComputed`, `testAllElseEmptyHandComputed`, `testEngineWeightEq1010HandComputed`, `testInstalledEngineHandComputed`, `testOEWHandComputed` | **ADDED** | `9.0·196.2261`, `4.0·49.8473`, `5.3·40.8897`, `4.8·730.3023`, `0.033·31377`, `0.17·31377`, Eq. 10.10, `1.3·1·2775.0210` — each hand-evaluated in the comment block from the §C.1 extract constants and the §B.2 geometry values, **never** by calling the code under test and **never** from a ground-truth file |
| `testOEWEqualsSumOfItsComponents` | **ADDED** | Internal-consistency identity across the six group Dependents |
| ★ `testOEWScalesWithItsArgumentNotAFrozenWTO` + `testOEWDoesNotUnderstateByTheFrozenAllElseAmount` | **ADDED — the finding-#5 regression guards** | `OEW(45000) − OEW(31377)` must equal `(0.17+0.033)·13623` = **2765.4690** exactly. These are the tests whose absence hid the bug |
| `testOEWWorksWithWTOUnset` | **ADDED** | `OEW(W)` is a pure function of its argument: it must work with `obj.W_TO` still `NaN` |
| `testGenuinelyWTODependentPropertiesErrorWhenWTOUnset` | **ADDED** | `W_landing_gear` / `W_all_else_empty` must throw `F16WeightsL2:WTONotSet`, not return `NaN` (Phase 1e/1f precedent) — and **only** those two (§B.2) |
| `testAllTwelveDependentPropertiesExist`, `testNoDependentPropertyIsNonFinite` | **ADDED** | Finding-#12 guard: a property documented as computed can no longer read `NaN` |
| `testDerivedPropertiesAreReadOnly` | **ADDED** | Assigning to any of the 12 `Dependent` properties must error — mirrors `TestGeomL3.testFormerlyFrozenPropertiesAreReadOnly` |
| `testDerivedLiveRecomputeOnMutation` | **ADDED** | `geom` ↑ → `S_w`/`W_wings` move; `prop.T_SL` ↑ → `W_en`/`W_installed_engine`/`W_en_brandt` move; `design_mach` ↑ → `W_en` moves (Eq. 10.10 `M^0.25`) |
| `testGeometryDINameTraps` | **ADDED** | Asserts `S_ht == geom.S_exposed_ht` and `~= geom.S_ht`; same for VT |
| `testEngineWeightIsNotTheFormerFrozenEstimate` | **ADDED** | `W_en ~= 3030`, i.e. the unpinned `[estimate]` really was replaced by Eq. 10.10 |
| `testBrandtEngineAlternateIsNeverSummedIntoOEW` | **ADDED** | `W_en_brandt` is report-only; `OEW` must not move when it is read |
| `testConstructorRequiresAllFourArguments`, `testWrongGeomTierErrorsAtConstruction` | **ADDED** | No silent default; passing an `F16GeomL1` must throw at construction |
| `testDesignMachComesFromRequirementsFile` | **ADDED** | `design_mach` provenance is the requirements file, not `.weights` |
| ★ `testTODO_PureAreaDerivedShouldNotRequireWTO` | **DELETED** | Written to be red while the `requireWTO` over-guard existed; the over-guard was removed in the same phase, leaving a green `testTODO_` whose docstring said "EXPECTED RED" and gave a resolve-recipe for landed work. A marker whose condition is satisfied guards nothing, and keeping it would have invited a future reader to re-add the over-guard to make the docstring true. The principle it encoded — **a guard must encode a real dependency, not a house style** — now lives in `requireWTO`'s own docstring at both levels (todo §P4-18). todo §P4-18 |

The stale header reference block is fixed: `TestWeightsL2.m` no longer states
`[Brandt] OEW = 19,148 lbf [Brandt F-16A.xls, sheet "Wt", B12]`.

---

## G. `weights_brandt_comparison` — AS BUILT

**Artefacts: `examples/F16A/weights_brandt_comparison.{m,json,md}`.** Closes the "weights has no
comparison report" gap (geometry, aerodynamics and propulsion each have one). **45 data rows in 7
sections**, verified 2026-07-25 by counting the generated `.json` (52 rows − 7 section-label rows).

### G.1 Contract — non-negotiable, and as built

- **NOT A TEST.** No pass/fail assertions. Not in `run_all_tests`. Informational only.
- **Nothing in this report may ever backfill a unit test's expected value** (CLAUDE.md two-tier rule) —
  stated in the file header and in the rendered `.md` preamble, as `geometry_brandt_comparison.m` does.
- Expected values come from `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` `.weights` — the
  Brandt-direct ground truth — **not** from `F16Baseline.m` and **not** from `TestWeights*.m`.
- Where a quantity has multiple implementation options, **each option gets its own row**, including the
  rejected ones, so the decision trail is auditable rather than buried in a doc.
- Run it via `matlab -batch`, not the MATLAB MCP tool: the wide-table `disp` hang is on record.

### G.2 Shape — mirrors the shipped geometry report

Same local helpers in structure: `grow(...)`, `srow(...)`, `table_to_rows(...)`, `write_markdown(...)`.

| Column | Content |
|---|---|
| `Parameter` | row name |
| `Fidelity` | `'L1'` / `'L2'` / `'L3'` / `'L2/L3'`, `'--'` for a rejected variant, or `'N/A'` for a quantity nothing models (then `Computed` = `NaN` → prints `N/A`) |
| `Computed` | framework value |
| `Brandt` | ground-truth value from `f16a_ground_truth.json` `.weights` |
| `PctDiff` | `100·(Computed − Brandt)/Brandt`, `' - '` when either side is `NaN` |
| `Alt` | **second-source column** — the `corrections.xls` figure where one exists. `NaN` → `'N/A'` |
| `Divergence` | three-state, see §G.3 |
| `Source` | Brandt cell + formula, e.g. `'Brandt Wt!C9'` |
| `Notes` | why the two sides differ |

★ **Column-name difference from the geometry report, on purpose.** This report's second-source column
is named **`Alt`**; the geometry report calls the same column position **`TO`**. The reason is what the
column carries: here it is a **workbook** (`corrections.xls Wt!*`, Casey's revised-weight figures),
not the T.O. 1F-16A-1. The rendered `.md` carries a "Reading the `Alt` column" preamble paragraph
saying so, so the two reports are not mistaken for each other.

### G.3 The `Divergence` column — three states, same semantics as `geometry_brandt_comparison.m`'s `grow` docstring

| State | Meaning | Reader's action |
|---|---|---|
| `'BY DESIGN'` | Same **kind** of quantity as Brandt's, but the framework is *expected* to differ — a different formula family, or L3 following a physical/T.O. value where Brandt uses his own. The `%Diff` is meaningful and should be small-ish. | Sanity-check the magnitude |
| `'DEFINITIONAL'` | A **different kind of quantity altogether**. The `%Diff` is not a meaningful error measure at all. | Do not chase it |
| `''` (blank) | A genuine agreement check. | A large `%Diff` here **is** worth chasing |

The rendered `.md` carries the same explanatory preamble as the geometry report, including the sentence
*"A large %Diff on a `BY DESIGN` row is the correct answer, not a defect."*

### G.4 Rows as built — 45 data rows, 7 sections

`W_TO` basis = 31,377 lbf `[Brandt Wt!B3]`, read from the ground-truth JSON, not hardcoded.

| Section | Rows | Content |
|---|---|---|
| 1 | 7 | OEW — the headline, all six model variants plus the Roskam bound |
| 2 | 12 | structural line items, `Wt!C9:H9` — L2 and L3 rows side by side |
| 3 | 14 | engine + systems, `Wt!B22:B31` + the airframe subtotal |
| 4 | 5 | engine weight, Raymer vs Brandt (incl. both rejected variants) |
| 4b | 2 | the two dependency-injected scalars (`SFC_mission`, `W_l`) |
| 5 | 1 | `NOT MODELED` gap tally |
| 6 | 4 | sensitivity to the items still open after the 2026-07-25 decisions |

**Section 1 — OEW (the headline), 7 rows.**

| Row | Fidelity | Computed *(live)* | Brandt | Alt | Divergence | Source | Notes |
|---|---|---|---|---|---|---|---|
| `OEW (Raymer Tbl 3.1 regression)` | L1 | 19110.31 | **19980.70** | 19148.08 | *(blank)* | `Brandt Wt!B12` | −4.36 % / −0.20 % vs alt |
| `OEW (Roskam Eq. 2.16 MIN bound)` | L1 | 15673.73 | 19980.70 | 19148.08 | `DEFINITIONAL` | `Brandt Wt!B12` | A **lower bound**, not a central estimate — `%Diff` is not an error |
| `OEW (Tbl 15.2 psf buildup, Raymer W_en)` | L2 | 15664.65 | 19980.70 | 19148.08 | *(blank)* | `Brandt Wt!B12` | −21.60 %. Missing analogs account for 2733.68 lbf of the gap (§G.4 sec. 4) |
| `OEW (Tbl 15.2 psf buildup, Brandt W_en alt)` | L2 | 16787.35 | 19980.70 | 19148.08 | `BY DESIGN` | `Brandt Wt!B12` | Alternate engine model, Brandt's 0.199·T as-is (no ×1.3); −15.98 % |
| `OEW (Tbl 15.2 psf + Brandt W_en ×1.3 — REJECTED)` | `--` | 18206.42 | 19980.70 | 19148.08 | `DEFINITIONAL` | `Brandt Wt!B12` | **Rejected variant, reported so the decision is auditable.** −8.88 %: the *closest* row in the whole report, and rejected precisely because the agreement comes from double-applying an installation factor Brandt has already applied |
| `OEW (Raymer §15.3.1 buildup)` | L3 | **15705.33** | 19980.70 | 19148.08 | *(blank)* | `Brandt Wt!B12` | **−21.40 %** at the settled uninstalled `W_en` + `W_l` = 0.95·`W_TO` + `SFC_mission` = 1.007116 |
| `OEW (§15.3.1, REJECTED W_en ×1.3)` | L3 | 16546.06 | 19980.70 | 19148.08 | `DEFINITIONAL` | `Brandt Wt!B12` | **Rejected variant, reported so the decision is auditable.** −17.19 %: *closer* to Brandt than the settled answer, because it double-counts the installation hardware Eqs. 15.7–15.15 already supply. Not a candidate |

★ **The `Alt` column carries `corrections.xls Wt!B12 = 19148.08`, labelled
`"corrections.xls Wt!B12 (Casey's revised-weight workbook) — NOT the original Brandt Wt!B12"`.** This
is the row that closes review finding #14. `Wt!B12` was read live 2026-07-25 = **19980.700578**.

**Section 2 — structural line items, 12 rows** (`f16a_ground_truth.json
.weights.structural_components`; every `corrections_xls` field goes in `Alt`). Wing, fuselage, HT, VT
and the structural subtotal each get **two** rows (L2 psf and L3 §15.3.1), plus the two `N/A` rows:

| Quantity | Rows | Brandt | Cell | Divergence | Notes |
|---|---|---|---|---|---|
| Wing | L2 + L3 | 1785.95 | `Wt!C9` | *(blank)* | L2 psf 9.0×exposed vs Brandt 6.75×`S_ref` with AR/n_ult/tc/sweep factors; L3 Eq. 15.1 |
| Fuselage | L2 + L3 | 3652.11 | `Wt!D9` | *(blank)* | |
| Pitch control / HT | L2 + L3 | 648.00 | `Wt!E9` | **`DEFINITIONAL`** | Brandt uses **FULL** `S_ht` = 108 (`=E7*Main!C18`); framework uses **EXPOSED** 49.8473 (L2) / 51.1486 (L3). Different area convention → not an agreement check. `Alt` = 199.39, which *is* close only because corrections.xls happens to land near 4.0×exposed |
| Vertical tail | L2 + L3 | 360.00 | `Wt!F9` | **`DEFINITIONAL`** | Brandt uses **FULL** `S_vt` = 60; framework uses **EXPOSED** 40.8897. `Alt` = 245.34 |
| Nacelles | `N/A` | 186.82 | `Wt!G9` | `DEFINITIONAL` | **NOT MODELED** — no framework nacelle-weight component |
| Strakes | `N/A` | 90.00 | `Wt!H9` | `DEFINITIONAL` | **NOT MODELED** |
| Structural subtotal (wing+fus+HT+VT) | L2 + L3 | 6722.87 | `Wt!B9` | `DEFINITIONAL` | Brandt's subtotal includes the nacelles + strakes the framework has no analog for |

**Section 3 — engine + systems, 14 rows** (`.weights.engine_and_systems`): landing gear as **four**
rows (L2 `0.033·W_TO` vs `Wt!B23` = 1066.82 `BY DESIGN` — 0.033 vs Brandt's 0.034; plus L3 main-only,
nose-only and total), inlet duct (`Wt!B24`, 728.59 → L3 `.induction`), flight controls (`Wt!B25`,
472.44 → `.flight_ctrl`), electrical (`Wt!B26`, 533.41), hydraulics (`Wt!B27`, 367.11), ECS (`Wt!B28`,
360.84 → `.ac_antiice`), avionics (`Wt!B30`, 2541.54), the L3 fuel system (**no Brandt cell** — the
`SFC_mission` consumer), `N/A`/`DEFINITIONAL` rows for other structure (`Wt!B29`, 2016.86) and armament
support (`Wt!B31`, 440.00), and the airframe subtotal (`Wt!B10`, 15250.47).

★ The **L3 landing-gear total row is here, in section 3**, not in section 4b: it is a genuine
agreement check against `Wt!B23` (**1160.93** vs 1066.82, +8.82 %; it was 1057.27 and −0.9 % on the
frozen `W_l` = 20681), whereas 4b's two rows are `DEFINITIONAL` by decision.

**Section 4 — engine weight, Raymer vs Brandt, 5 rows** against `Brandt Wt!B11`/`B22` = 4730.23:

| Row | Fidelity | Computed *(live)* | Brandt | Divergence | Notes |
|---|---|---|---|---|---|
| `W_en uninstalled [Raymer Eq. 10.10]` — **OFFICIAL at L3** | L3 | **2775.0210** | 4730.23 | `DEFINITIONAL` | Brandt's 0.199·T is an **installed** figure — uninstalled-vs-installed is not like-for-like. −41.3 %. This is the value L3 consumes (decision 1): §15.3.1 adds mounts/firewall/section/induction/tailpipe/cooling/oil/controls/starter separately |
| `W_installed_engine [Raymer 10.10 × 1.3]` — **OFFICIAL at L2** | L2 | **3607.5273** | 4730.23 | *(blank)* | Like-for-like: both installed. **−23.7 %**. `×1.3` is L2-only |
| `W_en [Brandt 0.199·T_AB alternate, NO ×1.3]` | L2/L3 | **4730.2300** | 4730.23 | `BY DESIGN` | Exact by construction — it *is* Brandt's formula fed his own `T_SL`. A **positive control** that the prop DI delivers 23,770 lbf correctly |
| `W_en [Brandt 0.199·T × 1.3 — REJECTED]` | `--` | 6149.2990 | 4730.23 | `DEFINITIONAL` | +30.0 %. Reported once, labelled rejected: double-applies an installation factor Brandt has already applied (`readme_wt.md:230`) |
| `Engine group total (dry + Eqs. 15.7–15.15)` | L3 | **3381.6984** | 4730.23 | `BY DESIGN` | The whole installed propulsion group built item by item, against Brandt's single lumped `0.199·T` figure |

Source string for the four `W_en` rows: `"Brandt Wt!B11 (=IF(Main!C29=Main!D29,'Engn(s) Old'!D11*Main!B28*Main!C29,'Engn(s) Old'!D22*Main!B28*Main!D29)); 0.199 literal at 'Engn(s)'!D22"`.

**Section 4b — the two dependency-injected scalars, 2 rows** (settled decisions 2 and 4). Both are
`DEFINITIONAL`: the framework and Brandt define the quantities differently, and the divergence is
accepted by decision, not an error to chase.

| Row | Fidelity | Computed *(live)* | Brandt | Divergence | Notes |
|---|---|---|---|---|---|
| `SFC_mission [prop.get_TSFC @ cruise 36kft/M0.87]` | L3 | **1.007116** | 0.70 | `DEFINITIONAL` | **+43.87 %, accepted by decision.** Two deliberate causes: a real cruise point vs Brandt's single stored SLS constant, and uninstalled (`get_TSFC`) vs Brandt's already-installed 0.70. Consistency point in the framework's favour: Brandt's `Consts!` cruise row is `pct_AB = 0` (dry/mil) and `get_TSFC` resolves to the mil path. Source: `Brandt Main!C30` |
| `W_l landing design gross weight [0.95 · W_TO]` | L3 | **29808.15** | 20680.70 | `DEFINITIONAL` | **+44.14 %.** `Brandt Wt!B41` = `=SUM(B16:B32)` *(live)* is a back-calculated output of his own weight statement, not a landing-weight requirement. ★ The **0.95 factor has no repo citation — todo §P4-16 stays OPEN** |

**Section 5 — the `NOT MODELED` gap tally, 1 row.** `nacelles + strakes + other_structure +
armament_support = 186.82 + 90.00 + 2016.86 + 440.00 = 2733.68 lbf = 13.68 % of Wt!B12`. Marked
`DEFINITIONAL`, `Computed = NaN`. Mirrors the geometry report's strake-gap treatment (todo 2026-07-25
§23). It is the largest identified contributor to every negative OEW `%Diff` in section 1.

**Section 6 — sensitivity to the items STILL open after the 2026-07-25 decisions, 4 rows**, each
`DEFINITIONAL` with `Brandt = NaN`, so the remaining open decisions are visible in the report rather
than buried in a doc. All deltas live, each applied alone on the settled L3 `OEW` base of 15705.3313:

| Row | Choice | `OEW` | Δ | todo |
|---|---|---|---|---|
| `L_d` ← `geom.L_duct` | 7.5 → 14.0 ft (induction 227.54 → 429.01) | 15906.80 | +201.47 | §P4-4, **OPEN** |
| `D_e` ← `geom.D_exit` | 3.33 → 3.537022 ft | 15730.27 | +24.94 | §P4-4, **OPEN** |
| `design_mach` ← T.O. limit | 2.0 → 2.05 | 15725.41 | +20.08 | §P4-13, **OPEN** (citation, not value) |
| `K_d` = 0 (legal straight-duct input) | induction 227.54 → **0.0000** | **15477.7874** | −227.54 | §P4-11 — **left unguarded by decision 6.** The row exists so the silent zero is at least visible somewhere |

### G.5 Exports and console block — as built

`weights_brandt_comparison.json` (`data.generated / .aircraft / .W_TO_lbf / .source / .rows`) and
`weights_brandt_comparison.md`, both written next to the script, same structure as
`geometry_brandt_comparison.m`. Console header block naming the source file and the `W_TO` basis, then a
`NOTES` block stating: (a) Brandt's psf coefficients differ from Raymer Table 15.2's; (b) Brandt's tail
line items use FULL planform, the framework uses EXPOSED; (c) `Wt!B12` = 19,980.70 is the Expected and
19,148.08 is `corrections.xls`, **not** `Wt!B12`; (d) the 2733.68 lbf of unmodelled Brandt components.
The rendered `.md` additionally carries the "Reading the `Divergence` column" and "Reading the `Alt`
column" preambles (§G.2, §G.3).

---

## H. Cross-references

- `docs/weights_parameter_usage.md` — full parameter → consumer → source tables, both DI maps, and the
  live Brandt cell/formula reads.
- `examples/F16A/F16GeomL3.md` §A — what `F16GeomL3` exposes (the L3 weights injection target).
- `examples/F16A/F16WeightsL{1,3}.md` — the other two tiers.
- `VnV/BrandtF16A/todo.md` — 2026-07-24 Weights §3a/§3b/§3c, 2026-07-24 GeomL3 §5, 2026-07-25
  Phase 4 §P4-0 … §P4-17, and the 2026-07-25 **Phase 4 AS-BUILT re-status** (§P4-18 … §P4-22).
- Step-level as-built summary: `docs/subplans/05_weights.md`.
