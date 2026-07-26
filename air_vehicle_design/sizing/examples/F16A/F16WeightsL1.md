# F16WeightsL1

**STATUS: AS-BUILT (reconciled 2026-07-25, step 2d).** This doc previously described the Phase-4
*target*; it now describes what shipped. Historical AS-IS rows are kept only where the pre-Phase-4
behaviour explains a defect that was fixed — they are labelled `WAS`.

> **L1 does NOT read `examples/F16A/f16a_requirements.json`** and injects nothing. Both regressions take
> only `W_TO` and `aircraft_category`: no design Mach, no cruise condition, no geometry, no propulsion.
> `F16WeightsL1(json_path)` therefore has a **single** argument. L1 is the only weights level with no
> dependency injection at all.

F-16A Block 10/15 Level-1 weight concrete class (`classdef F16WeightsL1 < WeightsModelL1`). Every
abstract method is a single delegation line into the `WeightsL1` static toolbox (statistical
empty-weight regressions); no equations are duplicated here.

L1 is the level Phase 4 changed least: no geometry, no propulsion, no frozen derived value and no NaN
placeholder. The whole delta was (a) reading inputs from `f16a_L1.json` instead of hardcoded defaults,
(b) the payload values, (c) `W_energy` → `NaN`, (d) the standing Raymer Table 6.1 TO-DO, and (e) the
19,148 mis-citation leaving the unit tier.

Numbers marked *(live)* were computed 2026-07-25 via `mcp__matlab__evaluate_matlab_code`. Brandt cells
marked *(live)* were read directly from `VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` over Excel COM.

---

## A. Constructor / input mechanism — as built

```matlab
w1 = F16WeightsL1(f16a_spec_path(1));
```

| | As built | `WAS` (pre-Phase-4) |
|---|---|---|
| Signature | **`F16WeightsL1(json_path)`** — path required, no silent default, matching `F16PropL2(json_path)` | `F16WeightsL1()` — no-arg |
| Source of spec data | `jsondecode(fileread(json_path))` → top-level `aircraft_category` + `.weights` | hardcoded classdef defaults |
| Constructor body | sets **only** input properties; nothing is computed and frozen | re-assigned `aircraft_category = 'jet_fighter'`, which the property default already set (a no-op line) |
| JSON keys read | `aircraft_category`, `.weights.W_payload_fixed`, `.weights.W_payload_expendable` | none — the `.weights` block of `f16a_L1.json` was dead |

`W_TO` and `W_energy` are deliberately **not** read: both are sizing-loop / mission-analysis state and
stay `NaN` until set. `W_energy` in particular is `Brandt Wt!B6` = `=B3-B4-B5-B12` *(live formula)*, a
back-calculated **output**, forbidden as an input by CLAUDE.md.

---

## B. INPUT vs DERIVED classification — as built

Pattern per CLAUDE.md → "Optimization-ready property design"; reference implementation
`examples/F16A/F16GeomL2.m` header.

**COUNTS, verified live 2026-07-25 from the metaclass `PropertyList`: 5 plain / 0 `Dependent`.**

### B.1 INPUTS (5)

| # | Property | Value | Units | Kind | Citation | Why an input (not derived) |
|---|---|---|---|---|---|---|
| 1 | `aircraft_category` | `'jet_fighter'` | — | JSON | `[f16a_L1.json top-level aircraft_category]` — the single canonical class flag for every discipline | Classification, not a computable quantity. Selects the Raymer Table 3.1 row (`WeightsL1.lookup_coeffs`) and the Roskam Table 2.15 row (`lookup_roskam_coeffs`) |
| 2 | `W_payload_fixed` | **700** (`WAS` 220) | lbf | JSON | `[Brandt Wt!B4 = 700.000000 (live), formula =Main!O16]` | Mission spec: crew + fixed equipment. Same value at all levels |
| 3 | `W_payload_expendable` | **4400** (`WAS` 0) | lbf | JSON | `[Brandt Wt!B5 = 4400.000000 (live), formula =Main!O17]` | Mission spec: stores. Same value at all levels |
| 4 | `W_TO` | `NaN` | lbf | **state** | `WeightsBase` abstract contract | Candidate gross takeoff weight, mutated in place by the sizing loop. A mutable input by design — the optimizer's variable, not something the class computes |
| 5 | `W_energy` | `NaN` (`WAS` **6296.3**) | lbf | **state** | `WeightsBase` abstract contract | Internal fuel, set by mission analysis. The old 6296.3 was `Brandt Wt!B6` = `=B3-B4-B5-B12`, i.e. `W_TO − payload − OEW` — a back-calculated **output**. Deleted from the JSON in Phase 3 |

### B.2 DERIVED (0) — and why zero is the right answer

**L1 has no derived quantity to make `Dependent`.** Specifically:

- `WeightsModelL1` declares **no** abstract properties — only the two methods
  `compute_We_fraction(obj, W_TO, aircraft_category)` and `compute_We_roskam(obj, W_TO)`. So L1 carries
  none of the NaN "computed total" placeholders that review finding #12 flagged at L2/L3.
- Nothing on `F16WeightsL1` was ever a frozen derived value. There is no L1 analog of finding #5.
- `OEW(W_TO)`, `compute_We_fraction(W_TO[,cat])` and `compute_We_roskam(W_TO)` stay **methods**: they
  take `W_TO` as an argument (the `WeightsBase`/`WeightsModelL1` contract), so they recompute on every
  call and cannot go stale. The inputs-vs-`Dependent` rule targets *stored* derived state; a method is
  already correct-by-construction.

Adding `Dependent` mirrors such as `We_fraction` or `W_E_min_roskam` keyed off `obj.W_TO` would be a
feature beyond what the step required (CLAUDE.md rule 4) and was deliberately left **out of scope**.
Recorded so a later reader does not mistake the absence for an oversight.

---

## C. Methods — all delegate to `WeightsL1`

| Method | Delegation chain | Computes | Formula | Citation | Units |
|---|---|---|---|---|---|
| `OEW(W_TO)` | `WeightsL1.OEW` → `compute_We_fraction` → `We_fraction_power_law(K_vs,A,C,W_TO)` | central empty-weight estimate | `OEW = (K_vs·A·W_TO^C)·W_TO` | `[Raymer 7th ed. Table 3.1]` | lbf |
| `compute_We_fraction(W_TO[,category])` | `WeightsL1.compute_We_fraction` → `We_fraction_power_law` | empty-weight fraction | `We/Wto = K_vs·A·W_TO^C` | `[Raymer 7th ed. Table 3.1]` | — |
| `compute_We_roskam(W_TO)` | `WeightsL1.compute_We_roskam` → `We_roskam(A,B,W_TO)` | minimum historically achievable empty weight (**lower bound**, not a central estimate) | `W_E = 10^((log10 W_TO − A)/B)` | `[Roskam Part I Eq. 2.16 + Table 2.15, book p.47 / PDF p.59]` | lbf |

The optional third argument of `compute_We_fraction` overrides `obj.aircraft_category` — exercised only
by `TestWeightsL1.testComputeWeFractionWithExplicitCategory`.

### C.1 Lookup constants, transcribed from named repo extracts

**`WeightsL1.lookup_coeffs` — Raymer Table 3.1.** Transcribed from
`temp_AI/docs/disciplines/reference_extracts/metabook_data.md:20-26`:

| Code key | Extract row | A (US) | C | K_vs (fixed) | Match |
|---|---|---|---|---|---|
| `jet_fighter` | Jet fighter | 2.34 | −0.13 | 1.00 | exact |
| `jet_trainer` | Jet trainer | 1.59 | −0.10 | 1.00 | exact |
| `jet_transport` | Jet transport | 1.02 | −0.06 | 1.00 | exact |
| `military_cargo_bomber` | Military cargo/bomber | 0.93 | −0.07 | 1.00 | exact |

The extract also carries a **UAV-Tac Recce / UCAV** row (1.67 / −0.16) that the code does not — not a
defect, recorded for completeness. `K_vs` = 1.04 for variable sweep / 1.00 fixed
(`metabook_data.md:20-22`); the F-16 is fixed-sweep so 1.04 is never exercised.

**`WeightsL1.lookup_roskam_coeffs` — Roskam Table 2.15.** Transcribed from
`temp_AI/docs/disciplines/reference_extracts/roskam_vol1_data.md:53-63`:

| Code key | Extract row | A | B | Match |
|---|---|---|---|---|
| `jet_fighter` | Fighters — jets | 0.5091 | 0.9505 | exact |
| `fighter_piston` | Fighters — piston/props | 0.5647 | 0.8761 | exact |
| `single_engine_prop` | Single-engine prop driven | −0.1440 | 1.1162 | exact |
| `military_patrol_bomber` | Mil. patrol/bomb/transport — jets | −0.2009 | 1.1037 | exact |
| `supersonic_cruise` | Supersonic cruise — jets (cruise val.) | 0.0833 | 1.0335 | exact |

Eq. 2.16's form in the extract (`roskam_vol1_data.md:47`) is
`W_E = inv.log10{(log10(W_TO) − A)/B}` — matches `WeightsL1.We_roskam` exactly.

> **★ CORRECTION, accepted by the coordinator 2026-07-25.** An earlier version of this doc stated
> "Roskam citation not pinned in a repo extract … Not locatable in repo". **That was wrong — the
> extract exists** at `roskam_vol1_data.md:53-63`, and all five rows `lookup_roskam_coeffs` codes match
> it exactly (independently re-verified by the coordinator). The extract carries its own caveat
> (`:63`): the full 12-category table is image-only and these rows were OCR-recovered — *"Verify
> against the book before locking into code."* So the Roskam constants are **traceable but not
> book-verified**, the same status as the Raymer Table 3.1 rows and one tier better than "unpinned".
>
> **Consequence: `Roskam Table 2.15` is NOT a standing TO-DO. Only Raymer Table 6.1 is** (§D.1).
> todo 2026-07-25 Phase 4 §P4-8.

---

## D. Deviations, limitations, standing TO-DOs

**Exactly ONE standing TO-DO remains at L1** — Raymer Table 6.1 (item 1). The Roskam Table 2.15 item is
withdrawn; see the correction box in §C.1.

1. **★ Raymer Table 6.1 → STANDING TO-DO, OPEN (locked, user 2026-07-24).** `WeightsL1.m` cites
   **Table 3.1**; `docs/subplans/05_weights.md` (pre-2026-07-25 revision, `:81`/`:88`) cited **Table
   6.1** for the same power law. Locked decision: **keep Table 3.1 + the existing Roskam bound**; Table
   6.1's coefficients are **not present anywhere in this repo**, so the user must supply them.
   **Shipped guard: `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`** — a labelled,
   deliberately-failing test (verified red 2026-07-25) that keys off `WeightsL1.m`'s own standing-TO-DO
   sentence, since there is no JSON marker key for it. Do **not** silently adopt Table 6.1 numbers, and
   do not resolve the red by deleting the test. The rewritten subplan keeps the Table 6.1 citation
   visible for exactly this reason (`05_weights.md` §9 item 1).
2. **Secondary-source citation.** Both lookups cite a *secondary* source (the AE481 metabook / an OCR'd
   Roskam scan), not the primary book. The in-code "verify all rows against Raymer Table 3.1" markers
   are substantively correct and are retained through the 6th→7th ed. re-cite.
3. **Edition re-cite — DONE.** Code now says Raymer **7th ed.** throughout weights, with no value
   change. todo 2026-07-24 §3c item 4.
4. **Roskam Table 2.15 — no longer a TO-DO.** See §C.1's correction box. No `testTODO_` is warranted.
5. **`W_payload_fixed`/`W_payload_expendable` are inert.** No `WeightsL{1,2,3}` static reads either
   (grep, 2026-07-25 — zero matches in `src/disciplines/weights/`). They satisfy the `WeightsBase`
   closure contract and will be consumed by the future sizing loop. Setting them to 700/4400 changes no
   computed number at L1; it makes the closure identity
   `31377 − 19980.70 − 6296.30 = 5100 = 700 + 4400` correct for when the loop lands.
6. **The `0.033` / `1.3` / `0.17` metabook fractions are NOT Raymer Table 15.2** — an L2 concern, but
   the same secondary-source point as item 2. Corrected in `docs/weights_parameter_usage.md` §D.2 and
   `F16WeightsL2.md` §C.1. §P4-7.

---

## E. Values, as built (computed live 2026-07-25)

At `W_TO` = 31,377 lbf:

| Quantity | Value *(live)* | vs `Wt!B12` = 19980.700578 | vs `corrections.xls` 19148.08 |
|---|---|---|---|
| `compute_We_fraction(31377)` | 0.609055 | — | — |
| `OEW(31377)` — Raymer Table 3.1 | **19110.3126** lbf | **−4.36 %** | **−0.20 %** |
| `compute_We_roskam(31377)` — Roskam min bound | **15673.7334** lbf | −21.56 % | — |

The Roskam bound is correctly **below** the Raymer central estimate (the lower efficiency frontier), as
`TestWeightsL1.testWeRoskamLowerThanRaymerL1` asserts. **No L1 number changed in Phase 4** — the two
payload values and `W_energy` are inert.

★ The two Brandt figures are **distinct provenances**, ~4.3 % apart, and must never be conflated:
`Wt!B12` = 19980.700578 (`=SUM(B10:B11)`, live) is the original Brandt workbook; 19148.08 is
`corrections.xls Wt!B12` (Casey's revised-weight workbook, `F16Baseline.m:136`). The pre-Phase-4 class
header and unit tests asserted 19,148 while citing "Brandt F-16A.xls, B12" — wrong cell, wrong
workbook. That is review finding #14, and it is fixed in `F16WeightsL1.m`'s header and in the tests.

---

## F. Unit tier — as built

**The OEW-vs-Brandt agreement check LEFT the unit tier**, per CLAUDE.md's two-tier rule: an agreement
check against ground truth is not a unit test, and backfilling its expected value from ground truth is
the self-referential trap a prior review flagged.

`TestWeightsL1` as shipped: **25 cases, 24 green + 1 labelled deliberate red** (verified 2026-07-25).

| Test | Disposition | Note |
|---|---|---|
| `testOEWWithinBrandsValue` (`expected = 19148` cited "Brandt Wt!B12") | **REMOVED** → now a `weights_brandt_comparison` row against 19,980.70 with 19,148.08 in the `Alt` column | Review finding #14: wrong cell, wrong workbook |
| `testRoskamMinBoundBelowBrandt` (`expected_brandt = 19148`) | **REMOVED** | Same mis-citation; also an external-agreement assertion |
| `testOEWLessThanWTO`, `testOEWGreaterThanZero` | KEPT | Physical invariants |
| `testWeFractionMatchesOEW` | KEPT | Internal-consistency identity `frac·W_TO == OEW` |
| `testWeFractionIsLessThanOne`, `testWeFractionDecreasesWithWTO`, `testWeRoskamLowerThanRaymerL1` | KEPT | Hand-reasoned properties of the two formulas, no external expected |
| `testLookupJetFighterCoeffs`, `testLookupOtherCategoryCoeffs`, `testLookupRoskamJetFighterCoeffs`, both `…UnknownCategoryErrors` | KEPT | Table-constant checks, expecteds transcribed from the named extracts (§C.1) |
| `testIsa*` ×3, `testJetFighterCategorySetCorrectly` | KEPT | Contract/interface |
| `testWeFractionPowerLawHandComputed`, `testWeRoskamHandComputed`, `testOEWHandComputed`, `testRoskamBoundHandComputed` | **ADDED** | Hand-evaluated in the comment block from the §C.1 extract constants — **not** from a ground-truth file and **not** by calling the code under test. These replace the removed external checks as the correctness evidence |
| `testOEWIsPureFunctionOfItsArgument` | **ADDED** | `OEW(W)` must depend only on its argument, never on a stored `obj.W_TO` — the L1 analog of the finding-#5 guard |
| `testConstructorRequiresJSONPath` | **ADDED** | A no-argument call must error (no silent default) |
| `testPayloadInputsComeFromJSON`, `testStateVariablesAreNotReadFromJSON` | **ADDED** | Locks the §A input mechanism: payload read, `W_TO`/`W_energy` deliberately not |
| `testComputeWeFractionWithExplicitCategory` | KEPT | Category override path |
| `testTODO_RaymerTable61CoefficientsNotInRepo` | **ADDED — labelled deliberate RED** | §D.1 |

---

## G. Cross-references

- Comparison-report description: **`examples/F16A/F16WeightsL2.md` §G**; artefacts
  `examples/F16A/weights_brandt_comparison.{m,json,md}`.
- Full parameter → consumer → source tables and the DI maps: `docs/weights_parameter_usage.md`.
- Step-level as-built summary: `docs/subplans/05_weights.md`.
- Open provenance items and every discrepancy logged this phase:
  `VnV/BrandtF16A/todo.md` 2026-07-24 Weights §3a/§3b/§3c, 2026-07-25 Phase 4 §P4-0 … §P4-17, and the
  2026-07-25 **Phase 4 AS-BUILT re-status** (§P4-18 … §P4-22).
