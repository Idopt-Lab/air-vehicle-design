# Subplan 09 — Subsystems

**Status:** Target spec, Casey-approved. Scribe documentation pass complete (2026-07-31); all citation
gaps scribe flagged (Table 11.6 avionics fractions, Table 11.1 tire width, Eq. 7.14, Roskam Eq. 6.2)
are now CONFIRMED directly against the physical books (see "Equations & Citations" below) and the
gear-load-split decision is made (Raymer's 90/10, item 8). `io` pass complete (2026-07-31): `.subsystems`
blocks added to `examples/F16A/inputs/f16a_L1/L2/L3.json`, new
`VnV/BrandtF16A/GroundTruth/f16a_subsystems_ground_truth.json` created. All six `io`-flagged judgment
calls DECIDED (Casey, 2026-08-03): avionics fraction = midpoint 0.055; fuel-tank packaging-factor row =
"integral tank — shallow fuselage" 0.80 (corrected from an initial mismatched "wing" pick — this factor
multiplies the *fuselage* volume, item 1); nose-tire fraction = midpoint 0.80; ground truth stays its
own file; full lookup tables stay in future toolbox code, not JSON; universal equation constants (0.54,
3.4) stay in future toolbox code, not JSON. Fuel type changed from JP-4 to **JP-8** (Casey, 2026-08-03) —
T.O. 1F-16A-1's own stated nominal internal-fuel load. **Not yet implemented.** Two genuine gaps remain
with no textbook source found anywhere in-repo, re-confirmed 2026-08-03 against the now-complete Nicolai
extract set — item 7 (battery volumetric energy density) and item 11 (gear bay-volume packaging) —
planned to ship as documented-TODO / deliberately-failing tests, matching the established convention
(`TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`), not as a blocker to starting the
implementation loop on everything else.
**Depends on:** Step 2 (Geometry L2/L3 — fuselage envelope, wing chord/t-c, station data), Step 5
(Weights — component weight values; mission fuel weight for the sufficiency check).
**Blocks:** none yet (an informational/optional discipline — no other discipline currently reads a
Subsystems output).

---

## Objectives

Estimate internal volume available for fuel, avionics, and landing gear, at three fidelity levels, and
check it against what the aircraft actually needs to carry:

1. **Fuel-volume sufficiency check** — sum of fuselage-internal + wing-internal volume vs. required fuel
   volume (or, for an electric design, required battery volume). Must never silently check only one of
   fuselage/wing.
2. **Avionics volume** — estimated from a weight fraction, converted through a density assumption; must
   actually be summed into the internal-volume total (the legacy code computed this and then dropped it
   — see "Legacy bugs to avoid" below).
3. **Landing-gear tire/strut sizing and bay volume** — a statistical estimate of tire and gear size from
   Raymer's landing-gear chapter, producing a bay volume that also feeds the internal-volume total.

Fidelity split:
- **L1** — tabulation only, no geometry: Nicolai Ch. 8 §8.1.10/8.1.11-style density/packaging-factor
  lookups for fuel and avionics; no landing-gear volume at L1. **Scribe correction (2026-07-31):** the
  original rationale ("tire sizing needs `W_TO` at minimum") does not actually hold — `W_TO` is already
  a plain `properties` STATE field on `F16WeightsL1` (`examples/F16A/models/disciplines/weights/F16WeightsL1.m:74`, "candidate
  gross takeoff weight... mutated in place by the sizing loop"), so it is available from L1 onward, and
  Raymer's own default tire-sizing gear-load-split (90 % main / 10 % nose, Ch. 11 p. 344 prose — see
  Equations & Citations §9 below) needs no geometry at all. The L2+-only split is still CONFIRMED, but
  for a different reason: the subplan's own "producing a bay volume that also feeds the internal-volume
  total" (Objectives §3) requires a fuselage envelope to place the tire/strut bay into, and no fuselage
  geometry exists before `GeomL2`; architecturally, `F16LandingGearL2`/`L3` are also the only landing-
  gear classes in the Files-to-Create table (no L1 counterpart planned). So: **L2+-only is correct,
  rationale corrected, not overturned.**
- **L2** — geometry-derived: fuselage volume via Raymer eq. 7.14 off `GeomL2`'s envelope ellipse, wing
  volume via a chord/t-c-based formula off `GeomL2`, landing-gear tire/bay sizing via Raymer Ch. 11.
- **L3** — the same geometry-derived equations, refined by `GeomL3`'s station data instead of `GeomL2`'s
  envelope approximation.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|---|---|
| `src/base/SubsystemsBase.m` | Abstract base — declares the `internal_volume`/`fuel_volume_check` contract, any utility methods shared unchanged across levels |
| `src/disciplines/subsystems/SubsystemsModelL1.m` | L1 enforcer — declares the tabulation-only abstract methods/properties |
| `src/disciplines/subsystems/SubsystemsModelL2.m` | L2 enforcer — declares the geometry-DI'd abstract methods/properties (injected `geom`) |
| `src/disciplines/subsystems/SubsystemsModelL3.m` | L3 enforcer — same shape as L2, injected `GeomL3` |
| `src/disciplines/subsystems/SubsystemsL1.m` | Toolbox — Nicolai Ch. 8 tabulation statics (fuel packaging factor, avionics density/weight-fraction) |
| `src/disciplines/subsystems/SubsystemsL2.m` | Toolbox — Raymer eq. 7.14 fuselage volume, wing volume formula, multi-fuel-type density table, battery energy-density path |
| `src/disciplines/subsystems/SubsystemsL3.m` | Toolbox — same statics as L2, called with `GeomL3` station-derived areas |

### Layer 2 — F-16 specific (`examples/F16A/`, flat)

| File | Purpose |
|---|---|
| `examples/F16A/models/disciplines/subsystems/F16SubsystemsL1.m` | Tabulation inputs from `f16a_L1.json`; delegates to `SubsystemsL1` |
| `examples/F16A/models/disciplines/subsystems/F16SubsystemsL2.m` | Injected `F16GeomL2` + fuel-weight source (mission or `F16WeightsL2`); delegates to `SubsystemsL2` |
| `examples/F16A/models/disciplines/subsystems/F16SubsystemsL3.m` | Injected `F16GeomL3` + fuel-weight source; delegates to `SubsystemsL3` |
| `examples/F16A/models/disciplines/landing_gear/F16LandingGearL2.m`, `F16LandingGearL3.m` | **F-16-only, no abstract `Base` tier** — Raymer 6th ed. Ch. 11 (p. 337) statistical tire sizing (Table 11.1, p. 344) off `W_TO`/gear-load-split, producing tire/strut size + a bay-volume estimate. Not every airframe has conventional landing gear (e.g. seaplanes), so this does not get a generic `src/disciplines/` home — it stays F-16-example-only, but still follows the toolbox-static-equations pattern where that makes sense. |
| `examples/F16A/models/disciplines/subsystems/F16Subsystems{L1,L2,L3}.md`, `F16LandingGear{L2,L3}.md` | Per-class companion docs (input/derived tables, per-method citations) |

### Tests and report

| File | Tier |
|---|---|
| `tests/disciplines/TestSubsystemsL1.m`, `TestSubsystemsL2.m`, `TestSubsystemsL3.m` | unit — physical invariants (volumes > 0, avionics volume actually appears in the total), hand-computed per-equation checks |
| `tests/disciplines/TestF16LandingGear*.m` | unit — tire-sizing formula checks |
| `examples/F16A/subsystems_brandt_comparison.{m,json,md}` | comparison report — informational, **not** in `run_all_tests`; expect several `NOT MODELED` rows (see Ground Truth below) |

---

## Design Notes / Dependency Injection

- `F16SubsystemsL2(json_path, geom, fuel_weight_source)` / `F16SubsystemsL3(json_path, geom, fuel_weight_source)`
  — `geom` is guarded at the enforcer tier (`GeometryModelL2`/`L3`), matching the existing Weights pattern
  (`F16WeightsL2/L3`) rather than `GeometryBase`, so a wrong-tier geometry object fails at construction.
- Landing gear is **not** injected into core Subsystems as a discipline object dependency in the
  three-tier sense — it's a separate F-16-only class whose bay-volume output is summed alongside fuel/
  avionics volume by whatever assembles the final internal-volume total (Tier-3 `F16SubsystemsL2/L3`, or
  a small aggregator method — scribe/implementation to decide the cleanest DI shape once the equations
  are pinned down).
- **Fuel-volume check, precisely** (per Casey): sum fuselage-internal + wing-internal volume, never just
  one. Support **multiple jet-fuel types** (JP-4 and others), each with its own cited density — no single
  hardcoded density constant. Support a **battery-electric** alternative: an energy-density-based volume
  check as a parallel path alongside the liquid-fuel density check, not a special case bolted onto it
  after the fact.
- **Avionics volume must be summed into the total.** The legacy code computed it and then never added it
  in — this subplan exists partly to make sure that doesn't happen again.

---

## Legacy Bugs to Avoid (from `temp_Casey/src/Disciplines/Subsystems/`)

| Bug | Where | Fix in the new framework |
|---|---|---|
| `compute_avionics_volume` computed but never summed into the internal-volume total | `SubsystemsLevel3.m` | Avionics volume is a real term in the total from the start — write a test that asserts it's non-zero and present in the sum |
| Abstract base declares `get_internal_volume(subsys_obj, geometry_obj)`; concrete override takes a third `design` arg | `SubsystemsModelLevel3.m` vs. `SubsystemsLevel3.m` | Enforcer and concrete signatures must match exactly — this is exactly the class of bug `matlab-oop-expert` checks for |
| Dead orphaned `fuelcheck` function using old `containers.Map`-style access, never invoked | `SubsystemsLevel3.m:116-146` | Don't carry over dead code; if a sufficiency check is needed, it's a live method on the new class |
| Fuel density hardcoded to JP-4 only; any other fuel type throws | `SubsystemsLevel3.m` | Fuel-type → density lookup table, cited per type, plus the battery-electric path (see Design Notes) |

---

## Equations & Citations

Per-equation detail; formulas as they will be implemented, with exact citation and confidence/gap notes.
"CONFIRMED" = value/location independently cross-checked against an in-repo extract or the live Brandt
workbook. "UNVERIFIED" = the only source is a legacy-code comment or a single un-cross-checked extract.
"GAP" = no in-repo source found at all.

### §1–4 — `SubsystemsL1` (tabulation only, no geometry)

| # | Quantity | Formula | Citation | Status |
|---|---|---|---|---|
| 1 | Tank usable-volume packaging factor | `usable_vol = raw_vol × packaging_factor` | `[Nicolai & Carichner p.210, unnumbered "Fuel Tank Packaging Factors" table]` — 0.80 integral/shallow-fuselage, 0.85 integral/deep-fuselage, 0.75 integral/wing, 0.75 bladder/fuselage, 0.65 bladder/wing | CONFIRMED (full table reproduced `08_fuselage_sizing.md:250-259`). **Not usable at L1** (no geometric raw volume exists yet) — applies starting at L2 (see §5). Which row applies to the F-16 is a judgment call (no in-repo source states its tank construction type) — **DECIDED (2026-08-03): "integral tank — shallow fuselage" (0.80)**, matched to the row that multiplies the *fuselage* raw volume per §5b (an earlier draft of this pick used the "wing" row by mistake, caught and corrected 2026-08-03 — see `examples/F16A/inputs/f16a_L2.json` `.subsystems.fuel._cite_packaging_factor` for the full correction note). "Shallow" vs. "deep" itself still has no numerical threshold in Nicolai — flagged as a residual judgment call. |
| 2 | Fuel density by type | `fuel_vol_gal = fuel_weight_lb / density(fuel_type)` | `[Nicolai & Carichner, Table 8.6, p.210]` — JP-4 6.5 lb/gal (48.6 lb/ft³), JP-5 6.8 lb/gal (51.1 lb/ft³), JP-8 6.7 lb/gal (50 lb/ft³), Aviation gas 6.0 lb/gal (44.9 lb/ft³) | CONFIRMED. **Replaces** the legacy code's single hardcoded, uncited `6.47` (JP-4-only, throws on any other type — Legacy Bug 4). Note the legacy `6.47` does not exactly match Table 8.6's `6.5`; adopt the cited `6.7` (JP-8), not the legacy figure. **DECIDED (Casey, 2026-08-03): the F-16 example uses JP-8, not JP-4** — `T.O. 1F-16A-1` (`usaf_f16_data.md:86`) states the F-16's own nominal internal fuel load is JP-8 ("Total internal fuel ≈ 6,950 lb (JP-8)... JP-4 ≈ 5,650–5,930 lb"), an aircraft-specific citation stronger than an arbitrary pick off Nicolai's generic table. This also resolves a cross-discipline density mismatch the `io` agent flagged: `f16a_L3.json`'s pre-existing `weights.systems.V_t` already implied a JP-8-like density. |
| 3 | Avionics weight fraction of `W_empty`, by aircraft category | `W_avionics = frac(category) × W_empty` | `[Raymer 6th ed., Ch. 11 "Landing Gear and Subsystems," Table 11.6 "Avionics Weights," p.375]` | **CONFIRMED (Casey, 2026-07-31, read directly from the physical book).** Full table: General aviation-single engine 0.01-0.03; Light twin 0.02-0.04; Turboprop transport 0.02-0.04; Business jet 0.04-0.05; Jet transport 0.01-0.02; **Fighters 0.03-0.08**; Bombers 0.06-0.08; Jet trainers 0.03-0.04. The legacy code's hardcoded `Fighter = 0.03` is the **low end** of the correct range, not a wrong value. **DECIDED (Casey, 2026-08-03): use the midpoint, 0.055** (not the legacy 0.03). |
| 4 | Avionics weight → volume density | `Vol_avionics = W_avionics / density` | Two candidate, non-conflicting citations found: **(a)** `[Raymer 6th ed., Ch. 11, p.375, prose immediately after Table 11.6]`: *"volume can be estimated assuming that avionics has an average density of about 30-45 lb/ft³"* — a range, not a point value. **(b)** `[Nicolai & Carichner, §8.1.11, p.210]`: flat **45 lb/ft³** (the top of Raymer's range). | CONFIRMED (both). **DECIDED (Casey, 2026-07-31): split by fidelity level, not blended.** **L1** uses Raymer's own Table 11.6 fraction and following-paragraph density range together (average ≈37.5 lb/ft³) — both come from the same page, no geometry needed, matches L1's tabulation-only character. **L2 (and L3)** switches to Nicolai's flat 45 lb/ft³ (`§8.1.11`) — this is the more refined, geometry-tier figure, consistent with L2+ already pulling its fuel-packaging factors from the same Nicolai Ch. 8 section (item 1). This resolves the earlier "keep L1 on one book" open question by extending the same logic across levels: each fidelity level's avionics-volume density now comes from the same source family as that level's other subsystems equations (Raymer stats at L1, Nicolai geometry-adjacent factors at L2+). |

### §5–7 — `SubsystemsL2`/`SubsystemsL3` (geometry-derived)

| # | Quantity | Formula | Citation | Status |
|---|---|---|---|---|
| 5 | Fuselage internal volume | `V_fuselage_raw = 3.4 × (A_top × A_side) / (4 × L)` [ft³] | `[Raymer 6th ed., Ch. 7, Eq. 7.14]` | **CONFIRMED (Casey, 2026-07-31, verified directly against the physical book — formula and coefficient correct as stated).** `A_top`/`A_side` are `GeomL2`'s envelope-ellipse projections at L2, `GeomL3`'s frame-integrated projections at L3 (per the subplan's stated L2→L3 refinement). |
| 5b | Usable fuel volume from raw geometric volume | `usable_vol = V_fuselage_raw × packaging_factor` | `[Nicolai & Carichner p.210]` (item 1) | Packaging factor **must** be applied before comparing geometric volume to required fuel volume — the legacy code (`SubsystemsLevel3.fuelcheck`, dead code, and `get_internal_volume`, live code) never applies one anywhere, comparing raw geometric volume directly against required fuel volume. That is an optimistic bug this framework must not repeat (not previously flagged in the subplan's "Legacy Bugs" table — adding it here). |
| 6 | Wing internal (fuel) volume | `V_WF = 0.54·(S²/b)·(t/c)_r·{(1 + λ_w·τ_w^(1/2) + λ_w²·τ_w) / (1+λ_w)²}`, with `τ_w = (t/c)_t/(t/c)_r` (Eq. 6.3) | `[Roskam, Airplane Design Part II, Ch. 6, p.153, Eq. 6.2/6.3 — attributed by Roskam to Torenbeek, Ref. 17, Eqn. B-12]` | **CONFIRMED (Casey, 2026-07-31, verified directly against the physical book, including the τ_w = tip/root definition in Eq. 6.3).** The formula and coefficient exactly match what was already drafted here. **Caution for implementation**: this is the *opposite* convention from the already-resolved Geometry audit finding for Roskam Vol. II Eq. 12.1, where `τ = (t/c)_root/(t/c)_tip` (root over tip). Here, Eq. 6.3 defines `τ_w = (t/c)_tip/(t/c)_root` (tip over root) — Roskam does **not** use one consistent `τ` convention across his own equations; each equation's `τ` must be implemented per its own stated definition, not assumed from another equation in the same book. **This formula REPLACES the legacy uncited "MFV" formula** (`SubsystemsLevel3.compute_wing_vol`: `t_avg=0.7·(...)`, `MFV=0.3·S_ref·t_avg`) per the subplan's own instruction — no source for the `0.7`/`0.3` coefficients was found anywhere in this repo, so it is **dropped**, not carried forward in any form. |
| 7 | Battery-electric volume path | `Vol_battery = E_required / (specific_energy × pack_density)` | Gravimetric specific energy: `[Nicolai & Carichner, Table 14.2, p.363]` — batteries 0.27 kWh/lb (Li-S projected 0.336 kWh/lb by 2015); also a `fast_data.md` digest Table 11 (Mokotoff et al.), 0.35-1.55 kWh/kg generic design-space bound, since removed from the repo | **GAP — CONFIRMED still open (Casey, 2026-08-03).** Re-scanned all `docs/reference_extracts/*.md` files (including the Nicolai Ch. 12/18-24 extracts completed just before this check) specifically for Nicolai volumetric-density material; found nothing beyond the same Table 14.2 gravimetric figure already on record. Both found sources are *gravimetric* (energy per unit **weight**); no in-repo source (Nicolai or otherwise) gives a *volumetric* energy density (kWh/ft³ or kWh/L) or a citable battery-pack density (lb/ft³) to convert a battery weight into a volume, unlike avionics (item 4) which has two independent lb/ft³ citations. Casey confirmed no estimation method for battery volume from energy density could be found. **DECIDED: ships as a documented-TODO / deliberately-failing test**, matching `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`'s established convention (CLAUDE.md's explicitly allowed citation-gap exception) — not a blocker to implementing everything else. |

### §8–11 — `F16LandingGearL2`/`F16LandingGearL3` (F-16-only, no `Base` tier)

| # | Quantity | Formula | Citation | Status |
|---|---|---|---|---|
| 8 | Gear load split | Main gear ≈ 90 % of `W_TO`, nose gear ≈ 10 % | `[Raymer 6th ed. Ch. 11, p.344, prose]`: *"the main tires carry about 90% of the total aircraft weight... Nose tires carry only about 10% of the static load"* | CONFIRMED. **DECIDED (Casey, 2026-07-31): use Raymer's 90/10 as the `F16LandingGearL2`/`L3` default.** The Brandt-derived alternate (26.7 % main / 73.3 % nose, `BrandtBalanceStabControl.m`) is not wired in — logged as a separate, non-blocking `todo.md` discrepancy (see Ground Truth below) rather than investigated further before implementation. |
| 9 | Static tire diameter, statistical method | `D_main [in] = A · W_w^B`, `W_w` = weight on one main wheel [lb] | `[Raymer 6th ed., Ch. 11, Table 11.1 "Statistical Tire Sizing," p.344]` | **CONFIRMED, full table (Casey, 2026-07-31, read directly from the physical book).** General aviation `A=1.51, B=0.349`; Business twin `A=2.69, B=0.251`; Transport/bomber `A=1.63, B=0.315`; **Jet fighter/trainer `A=1.59, B=0.302`**. Matches the extract's legible fragment exactly. |
| 9b | Static tire width, statistical method | `Width_main [in] = A' · W_w^B'` | Same `[Table 11.1, p.344]` | **CONFIRMED, full table (Casey, 2026-07-31).** General aviation `A'=0.7150, B'=0.312`; Business twin `A'=1.170, B'=0.216`; Transport/bomber `A'=0.1043, B'=0.480`; **Jet fighter/trainer `A'=0.0980, B'=0.467`**. The previous OCR-scrambled fragments (`0.0980`/`0.216` misattributed, `2.3`/`0.39` unexplained) are now resolved — the correct pairing keeps `A'` and `B'` from the *same* row together (e.g. jet fighter's `0.0980` pairs with `0.467`, not the `0.216` that had drifted up from the business-twin row in the OCR text). **Diameter and width are both usable now; landing-gear tire sizing and the resulting bay-volume estimate are unblocked.** |
| 9c | Rough-field / nose-tire adjustments | Diameter/width ×1.30 for unpaved fields (not applicable — F-16 is paved-field only); nose tire assumed 60-100 % of main-tire size, no F-16-specific point value given | Same `[Table 11.1 page, prose]` | CONFIRMED as prose guidance; the nose-tire fraction is a designer's choice within a stated range, not a citable point value. **DECIDED (Casey, 2026-08-03): use the range midpoint, 0.80.** |
| 10 | Static/dynamic wheel loads (secondary refinement) | Eqs. 11.1-11.4, moment-arm-over-wheelbase static loads + a 10 ft/s² braking dynamic term on the nose gear | `[Raymer 6th ed. Ch. 11, pp.344-345]` | **GAP — OCR-garbled**, fragments only (e.g. `"...= W·Na/B"`, `"10·H·W/(g·B)"`); general form (moment balance about the opposite gear, braking coefficient μ=0.3 → 10 ft/s² deceleration) is legible in the surrounding prose, but exact subscript/variable assignment across the four equations is not confidently reconstructable. **Recommend using item 8's flat 90/10 default rather than reconstructing Eqs. 11.1-11.4 from this extract**; revisit only if a clean page image becomes available. |
| 11 | Gear bay volume (tire + strut stowage) | — | — | **GAP — no textbook formula found anywhere in this repo.** Raymer's landing-gear chapter covers tire/strut/shock-absorber sizing, not a "bay volume" packaging estimate the way Nicolai's fuel/avionics sections give one. A simple geometric-envelope assumption (tire footprint × a strut/retraction-clearance multiplier) would need either a citation or an explicit "engineering judgment, uncited" label — not resolved here. |

---

## Open Items for Scribe — Resolutions (2026-07-31)

- **Avionics-volume material across all reference-extract files:** checked all 31
  reference-extract files then under review (21 numbered Nicolai chapter extracts,
  8 book/report digest files, `00_README.md`). Only `08_fuselage_sizing.md` (§8.1.10 fuel,
  §8.1.11 avionics, Tables 8.6-8.8) has direct fuel/avionics-volume content; other files mention
  "avionics"/"volume" only in unrelated contexts (tail-volume coefficients, weight-fraction totals,
  battery specific-energy tables — see Equations & Citations §7). No additional Nicolai avionics-volume
  material beyond Ch. 8 exists in-repo.
- **Wing-fuel-volume "MFV" citation:** resolved per the subplan's own instruction — replaced with the
  cited Roskam Eq. 6.2 formula (Equations & Citations §6). The eq. NUMBER itself remains unverified
  in-repo (Roskam Part II Ch. 6 was never deep-extracted), but this is the best available citation and
  the uncited "MFV" form is dropped entirely, not carried forward.
- **Raymer Table 11.6 as the L1 avionics citation:** FULLY CONFIRMED (Equations & Citations §3) — Casey
  read the full table directly from the physical book. Fighters: 0.03-0.08 (the legacy code's `0.03` is
  the low end of the real range, not a wrong value). The weight→volume density conversion is also
  resolved (§4): Raymer's own 30-45 lb/ft³ range, average ≈37.5.
- **F-16 tire/gear dimension to validate against:** **YES, found** — `VnV/BrandtF16A/GroundTruth/f16a_geometry.json`'s `gear` block
  gives `d_nose_ft=1.5` (18 in) and `d_main_ft=2.0` (24 in) for the F-16, attributed to a Brandt "Gear
  tab." **However, this is itself a new VnV/BrandtF16A discrepancy** (undocumented provenance, no cell
  reference, and its consuming code produces a load-split that contradicts textbook expectations) —
  logged as a new `todo.md` entry below. Use these tire-diameter numbers as a comparison-report data
  point only with that caveat attached, not as a silently-trusted validation target.
- **L1/L2/L3 split for landing-gear sizing:** subplan's L2+-only assumption is CONFIRMED, with the
  rationale corrected (see the Fidelity-split bullet above) — `W_TO` is available from L1, but the
  bay-volume output needs `GeomL2`'s fuselage envelope, and the architecture (Files to Create) only
  plans `F16LandingGearL2`/`L3`, no L1 counterpart.

---

## Ground Truth

No Brandt fuel-volume or avionics-volume ground truth was found in `VnV/BrandtF16A/GroundTruth/*.json`
during this subplan's research (confirmed 2026-07-31: `landing_gear`/`avionics`/`fuel` in
`f16a_ground_truth.json` are all component **weights**, not volumes) — the comparison report
(`subsystems_brandt_comparison.md`) will carry `NOT MODELED` gap rows for fuel/avionics volume, rather
than a full agreement check, consistent with how other reports handle Brandt components with no
framework analog.

Landing-gear tire/strut size **does** have an independent Brandt data point: `f16a_geometry.json`'s
`gear` block (`x_nose_ft=22.0`, `x_main_ft=37.7`, `y_main_ft=6.0`, `h_nose_ft=5.3`, `h_main_ft=5.3`,
`d_nose_ft=1.5`, `d_main_ft=2.0`). **This block has two problems, both newly logged to
`VnV/BrandtF16A/todo.md` (2026-07-31 entry) rather than resolved here:**
1. It is undocumented anywhere else in `VnV/BrandtF16A` — `readme_geom.md`'s own Input Schema (§2) and
   `GroundTruth/cell-map.md` both omit it entirely; its only citation is the JSON's own
   `"_source": "Gear tab — landing gear geometry"`, with no cell letter/number at all.
2. Its consuming code, `BrandtBalanceStabControl.m`'s `gear_main_pct`/`gear_nose_pct` (documented in
   `readme_bsc.md`'s "Gear load split" equation), computes **26.7 % main / 73.3 % nose** for the F-16 —
   a near-complete reversal of both Raymer's stated typical fighter split (90 %/10 %, Equations &
   Citations §8) and Nicolai's own repo-documented "nose gear ~20 % of TOGW" rule of thumb.

No T.O. 1F-16A-1 data was found anywhere in this repo (`temp_Casey` or elsewhere) giving an
independent tire/gear dimension — the Brandt `gear` block above is the only in-repo candidate, and it
carries the two caveats just described.
