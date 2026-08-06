# Subplan 05 — Weights

**Status:** Implemented, as-built (L1, L2, L3). Phase-4 redesign landed 2026-07-25.
**Depends on:** Step 1 (`AircraftState`), Step 2 (Geometry L2 **and L3**), Step 4 (Propulsion L2).
**Blocks:** Steps 7, 8 (mission analysis, sizing).

> **This document was rewritten 2026-07-25 (step 2d) from a target spec to AS-BUILT.** The previous
> revision was the most stale file in the repo on this topic. What it said that was wrong, and where
> the correction now lives, is tabulated in §9 — read that before trusting any older quotation of this
> file. The one claim deliberately **kept** from the old revision is its `Raymer Table 6.1` citation
> (§9 item 1): it is the sole in-repo source of that claim and it is guarded by a deliberately-failing
> test, so deleting it would silently erase a standing TO-DO.

Live numbers below were computed 2026-07-25 against the as-built classes. Brandt cells were read
directly from `VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` over Excel COM.

---

## 1. Objective, as delivered

Three fidelity levels of empty-weight estimation, each a textbook method with a pinned citation:

| Level | Method | Primary citation |
|---|---|---|
| L1 | statistical empty-weight regressions on `W_TO` only | `[Raymer 6th ed. Table 3.1]` (central) + `[Roskam Part I Eq. 2.16 + Table 2.15]` (minimum bound) |
| L2 | surface-density (psf × area) structural groups + fraction-based engine/all-else | `[Raymer 6th ed. Table 15.2]` + `[AE481 metabook Sec. 7, "Fraction-Based Weight Estimates"]` |
| L3 | Fighter/Attack statistical component build-up, 24 equations | `[Raymer 6th ed. §15.3.1, Eqs. 15.1–15.24]` + `[Raymer 7th ed. Eq. 10.10]` (engine dry weight) |

Single abstract output contract at every level: `OEW(W_TO) → scalar [lbf]`.

Brandt's OEW is a **validation target only**, never a calibration input:
`Wt!B12` = **19980.700578** lbf (`=SUM(B10:B11)`, live-read 2026-07-25). The separate figure
**19148.08** is `corrections.xls Wt!B12` (Casey's revised-weight workbook, `docs/weights_parameter_usage.md §4`) — a
**different workbook**, ~4.3 % apart. Never conflate them; the pre-Phase-4 unit tests did, which is
review finding #14.

---

## 2. Files as built

Three-tier pattern per level `N`: `WeightsBase` (abstract) ← `WeightsModelLN` (abstract enforcer,
inherits the Base directly) ← `F16WeightsLN` (concrete), plus a standalone static toolbox `WeightsLN`
that is **not** in the inheritance chain and holds the equations.

### Layer 1 — generic (`src/`)

| File | Purpose |
|---|---|
| `src/base/WeightsBase.m` | Abstract base: `OEW(W_TO) → lbf` contract + the closure state (`W_TO`, `W_energy`, `W_payload_fixed`, `W_payload_expendable`) |
| `src/disciplines/weights/WeightsModelL1.m` | L1 enforcer — declares `compute_We_fraction`, `compute_We_roskam`. **No abstract properties** |
| `src/disciplines/weights/WeightsModelL2.m` | L2 enforcer — declares `weight_wing/tail/fuselage/landing_gear` + the six group properties |
| `src/disciplines/weights/WeightsModelL3.m` | L3 enforcer — declares `weight_wing/tail/fuselage/landing_gear/engine_section/systems` + the five group properties. `weight_landing_gear(obj, W_TO)` **takes `W_TO`** (Phase 4, §P4-17) |
| `src/disciplines/weights/WeightsL1.m` | Toolbox — Raymer Table 3.1 power law + Roskam Eq. 2.16 bound |
| `src/disciplines/weights/WeightsL2.m` | Toolbox — Raymer Table 15.2 psf lookups + metabook Sec. 7 fractions + `engine_weight_brandt` alternate |
| `src/disciplines/weights/WeightsL3.m` | Toolbox — Raymer §15.3.1 Eqs. 15.1–15.24 + `landing_weight` |

### Layer 2 — F-16 specific (`examples/F16A/`, flat)

| File | What it provides |
|---|---|
| `examples/F16A/F16WeightsL1.m` | `aircraft_category` + payload from `f16a_L1.json`; delegates to `WeightsL1` |
| `examples/F16A/F16WeightsL2.m` | Spec/mission inputs from `f16a_L2.json`, `design_mach` from `f16a_requirements.json`, **injected** `F16GeomL2` + `F16PropL2`; delegates to `WeightsL2` |
| `examples/F16A/F16WeightsL3.m` | 42 numeric inputs from `f16a_L3.json .weights` + `f16a_requirements.json`, **injected `F16GeomL3`** + `F16PropL2`; delegates to `WeightsL3` |
| `examples/F16A/f16a_requirements.json` | **NEW (Phase 4)** — fidelity-independent requirements: `cruise.altitude_ft`, `cruise.mach`, `design_mach` |
| `examples/F16A/f16a_requirements_path.m` | Resolver, no `level` argument (that absence is the documentation that requirements are fidelity-independent) |
| `examples/F16A/F16Weights{L1,L2,L3}.md` | Per-class companion docs (input/derived tables, per-method citations, deviations) |

### Tests and report

| File | Tier |
|---|---|
| `tests/disciplines/TestWeightsL1.m` | unit — **25** cases, 24 green + 1 labelled deliberate red (`testTODO_RaymerTable61CoefficientsNotInRepo`) |
| `tests/disciplines/TestWeightsL2.m` | unit — **38** cases, all green |
| `tests/disciplines/TestWeightsL3.m` | unit — **44** cases, 43 green + 1 labelled deliberate red (`testTODO_Raymer1531ExponentsNotBookVerified`) |
| `examples/F16A/weights_brandt_comparison.{m,json,md}` | **comparison report — informational, NOT a test**, not in `run_all_tests` |
| `docs/weights_parameter_usage.md` | parameter → (level, function, citation) tables + the two DI maps |

---

## 3. Constructors and dependency injection — as built

```matlab
w1 = F16WeightsL1(f16a_spec_path(1));
w2 = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);   % g2 = F16GeomL2
w3 = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);   % g3 = F16GeomL3
```

- **Every argument is required.** No silent default anywhere — a defaulted injection would re-freeze
  engine or geometry data, which is the whole defect class Phase 4 removed.
- `geom` is guarded at the **enforcer** tier, not at `GeometryBase`: `geom (1,1) GeometryModelL2` at
  L2 and `geom (1,1) GeometryModelL3` at L3. A wrong tier therefore fails at **construction** rather
  than silently resolving property names to different physical quantities mid-run (the finding-#10
  lesson from the aero pass).
- `prop (1,1) PropulsionBase`. ★ At the **L3 rung this is an `F16PropL2`** — there is no L3
  propulsion tier, and anything reporting an "L3 propulsion" number must say so.
- `AircraftState` is **not** injected. `F16WeightsL3` reads `cruise.altitude_ft`/`cruise.mach` from the
  requirements file and builds the state itself inside `get.SFC_mission`.
- L1 injects nothing: both regressions take only `W_TO` and `aircraft_category`.

`F16GeomL1(json_path, req_path)` also reads `design_mach` from the requirements file (its `M_max`
drives `[Raymer 6th ed. Table 4.1]` `AR_eq`), so the requirements file has a geometry consumer too.

---

## 4. Input vs derived — the optimization-ready split (CLAUDE.md; reference `examples/F16A/F16GeomL2.m`)

Counted live 2026-07-25 from the metaclass `PropertyList`:

| Level | Plain properties | of which inputs | of which injected objects | `Dependent` (derived) |
|---|---|---|---|---|
| L1 | **5** | 5 (4 numeric + `aircraft_category`) | 0 | **0** |
| L2 | **9** | 7 (6 numeric + `aircraft_category`) | 2 (`geom`, `prop`) | **12** |
| L3 | **45** | 43 (42 numeric + `aircraft_category`) | 2 (`geom`, `prop`) | **31** |

- **L1's zero derived is correct, not an oversight.** `WeightsModelL1` declares no abstract
  properties, so there is no "computed total" to expose, and nothing on the class is a frozen derived
  value. `OEW(W_TO)` / `compute_We_fraction` / `compute_We_roskam` stay **methods**: they take `W_TO`
  as an argument, so they recompute per call and cannot go stale. The inputs-vs-`Dependent` rule
  governs *stored* derived state.
- **L2's 12 derived:** 4 geometry-by-DI (`S_w`, `S_ht`, `S_vt`, `S_wet_fus`), 2 engine weights
  (`W_en` official, `W_en_brandt` alternate), 6 component/group totals.
- **L3's 31 derived:** 21 geometry-by-DI, `T_max`, `W_en`, `W_en_brandt`, `W_l`, `SFC_mission`, and 5
  group totals.
- Derived properties are read-only (no set-methods); assigning to one errors, which is correct — they
  are outputs.

**Four defects this split removed** — three were the reviewed findings, the fourth (§P4-17) was found
while quantifying the fix for the third. All are the same failure class: a derived quantity frozen as a
stored input, in three cases a **Brandt output** frozen as an input, which CLAUDE.md forbids outright.

| # | Defect | Where | Consequence before the fix |
|---|---|---|---|
| #5 | `W_all_else_empty` frozen at `WeightsL2.weight_all_else_empty(obj, 31377)` in the constructor — and 31,377 is `Brandt Wt!B3`, a sizing **output** | `F16WeightsL2` | `OEW(45000)` carried `0.17·31377` where `0.17·45000` was required. Now `OEW` moves with its argument: `OEW(45000) − OEW(31377)` = `(0.17+0.033)·13623` = **2765.4690** exactly |
| #11 | Constructor body was a comment only — no argument, no JSON read; ~22 geometry constants frozen inside a weights class | `F16WeightsL3` | The `.weights` block of `f16a_L3.json` was dead. Replaced by geometry DI |
| #12 | Group-total properties satisfied with `= NaN` and never assigned (4 at L2, 5 at L3) | both | A consumer reading the documented contract got `NaN`. All are now `Dependent`; `numel` non-finite = **0** |
| §P4-17 | `W_l = 20681` frozen (`Brandt Wt!B41`, itself `=SUM(B16:B32)`) **and** `weight_landing_gear` took no `W_TO` | `F16WeightsL3` | The whole gear group was **bit-identical at 31,377 / 45,000 / 60,000**. Now `W_l = 0.95·W_TO` and the gear reads 1160.9336 / 1273.1680 / 1370.4685 |

**Where `requireWTO` is applied — and the principle.** A guard must encode a **real** dependency, not
a house style. As built: L2 guards exactly `W_landing_gear` (`0.033·W_TO`) and `W_all_else_empty`
(`0.17·W_TO`); L3 guards exactly the five getters that genuinely carry `W_dg`/`W_l`. The pure
area × density groups (`W_wings`, `W_tail`, `W_fuselage` — their toolbox methods declare the `W_TO`
argument as `~`) and the thrust-correlation engine group are **not** guarded. An earlier Phase-4
revision over-guarded them "for uniformity"; see the todo entry for why that was withdrawn.

---

## 5. Equations and references — as built

### 5.1 `WeightsL1`

| Quantity | Formula | Citation | Constants (jet fighter) |
|---|---|---|---|
| `We/Wto` | `K_vs · A · W_TO^C` | `[Raymer 6th ed. Table 3.1]` | A = 2.34, C = −0.13, `K_vs` = 1.00 (1.04 variable sweep). Transcribed from `metabook_data.md:20-26` |
| `OEW` | `(We/Wto) · W_TO` | definition | — |
| `W_E` minimum bound | `W_E = 10^((log10 W_TO − A)/B)` | `[Roskam Part I Eq. 2.16 + Table 2.15]` | A = 0.5091, B = 0.9505. Transcribed from `roskam_vol1_data.md:47` (equation) + `:53-63` (table) |

`WeightsL1.OEW` — the `WeightsBase` contract method — delegates to the **Raymer** power law. The
Roskam value is a **lower bound** by construction and is never summed into `OEW`.

### 5.2 `WeightsL2`

| Quantity | Formula | Coefficient | Citation |
|---|---|---|---|
| Wing | `9.0 · S_w` (EXPOSED planform) | 9 psf | `[Raymer 6th ed. Table 15.2]`, `metabook_data.md:321` |
| HT | `4.0 · S_ht` (EXPOSED) | 4 psf | `[Raymer 6th ed. Table 15.2]`, `:322` |
| VT | `5.3 · S_vt` (EXPOSED) | 5.3 psf | `[Raymer 6th ed. Table 15.2]`, `:323` |
| Fuselage | `4.8 · S_wet_fus` (**WETTED**) | 4.8 psf | `[Raymer 6th ed. Table 15.2]`, `:324` |
| Landing gear | `0.033 · W_TO` | 0.033 | `[AE481 metabook Sec. 7, "Fraction-Based Weight Estimates"]`, `:330` — ★ **NOT Raymer Table 15.2** |
| Installed engine | `1.3 · N_en · W_en` | 1.3 | `[AE481 metabook Sec. 7]`, `:333`. **L2-only** — see §5.3 |
| All-else-empty | `0.17 · W_TO` | 0.17 | `[AE481 metabook Sec. 7]`, `:334` |
| `W_en` (official) | `0.0637 · T^1.1 · M^0.25 · e^(−0.81·BPR)`, uninstalled | 0.0637 | `[Raymer 7th ed. Eq. 10.10]`, coefficient at `raymer_data.md:38`; implemented once as `PropL2.engine_weight_AB` |
| `W_en_brandt` (alternate) | `0.199 · T_AB` | 0.199 | `[Brandt Wt!B11 = 4730.230000; the 0.199 literal is 'Engn(s)'!D22]`. Already **installed** (`readme_wt.md:230`), so it gets **no ×1.3**. Report only, never summed |

★ **Table 15.2 is the psf table only.** In the repo extract the landing-gear / installed-engine /
all-else fractions are a *separate, unnumbered* metabook table (`metabook_data.md:326-334`) with no
Raymer table number attached. Citing 0.033 / 1.3 / 0.17 to "Table 15.2" is wrong (§P4-7).

### 5.3 `WeightsL3` — Raymer §15.3.1, Eqs. 15.1–15.24

One consistent citation for the whole file: `[Raymer 6th ed. §15.3.1]`, **section only** — the former
mix of "p.572" (header) and "p.602" (methods) pointed at the same content via book-page vs PDF-page
numbering (`raymer_data.md:115`, PDF = book + 30) and is unified.

| Eq. | Component | Static | Eq. | Component | Static |
|---|---|---|---|---|---|
| 15.1 | wing | `WeightsL3.wing` | 15.13 | oil cooling | `oil_cooling` |
| 15.2 | horizontal tail | `horizontal_tail` | 15.14 | engine controls | `engine_controls` |
| 15.3 | vertical tail | `vertical_tail` | 15.15 | starter | `starter` |
| 15.4 | fuselage | `fuselage` | 15.16 | fuel system | `fuel_system` |
| 15.5 | main gear (`L_m` in **inches**) | `main_gear` | 15.17 | flight controls | `flight_controls` |
| 15.6 | nose gear (`L_n` in **inches**) | `nose_gear` | 15.18 | instruments | `instruments` |
| 15.7 | engine mounts | `engine_mounts` | 15.19 | hydraulics | `hydraulics` |
| 15.8 | firewall (0 for a jet, `S_fw`=0) | `firewall` | 15.20 | electrical | `electrical` |
| 15.9 | engine section | `engine_section` | 15.21 | avionics | `avionics` |
| 15.10 | air induction | `air_induction` | 15.22 | furnishings | `furnishings` |
| 15.11 | tailpipe | `tailpipe` | 15.23 | AC / anti-ice | `ac_antiice` |
| 15.12 | engine cooling | `engine_cooling` | 15.24 | handling gear | `handling_gear` |

Plus two non-§15.3.1 items:
- **Dry engine weight** = `[Raymer 7th ed. Eq. 10.10]`, **UNINSTALLED** at L3 (2775.0210 lbf). No
  ×1.3: §15.3.1 adds mounts/firewall/section/induction/tailpipe/cooling/oil/controls/starter
  individually, and the metabook's 1.3 is a lumped stand-in for exactly those items — applying both
  double-counts. Recorded consequence: this moves L3 **further** from Brandt (−21.40 % vs the
  rejected ×1.3 variant's −17.19 %). The variant's better agreement is the evidence **against** it.
- **`W_l = 0.95 · W_TO`** feeding Eqs. 15.5/15.6. ★ **The 0.95 factor has no citation anywhere in this
  repo** — user-supplied, logged **OPEN** at todo §P4-16. Brandt's own implied ratio is
  `20680.70/31377` = 0.6591, and the two are definitionally different quantities.

`OEW` = wing + HT + VT + fuselage + LG.main + LG.nose + engine-group.total + systems-group.total.
The systems group contains **no** landing-gear term (`WeightsModelL3`'s old "Includes landing gear"
comment was false and is corrected).

---

## 6. As-built values at `W_TO` = 31,377 lbf

| Level | Quantity | Value | vs `Brandt Wt!B12` = 19980.700578 | vs `corrections.xls` 19148.08 |
|---|---|---|---|---|
| L1 | `OEW` (Raymer Tbl 3.1) | **19110.3126** | −4.36 % | −0.20 % |
| L1 | `compute_We_roskam` (MIN bound) | **15673.7334** | −21.56 % | — |
| L2 | `OEW` | **15664.6483** | −21.60 % | −18.19 % |
| L2 | fuselage | 3505.4511 | — | — |
| L2 | installed engine (`1.3 × 2775.0210`) | 3607.5273 | — | — |
| L2 | `OEW(45000)` | **18430.1173** | — | — |
| L3 | `OEW` | **15705.3313** | −21.40 % | −17.98 % |
| L3 | HT (Eq. 15.2) | 200.5412 | — | — |
| L3 | engine group total | 3381.6984 | — | — |
| L3 | systems group total | 4578.1340 | — | — |
| L3 | landing-gear total | 1160.9336 | — | — |
| L3 | `SFC_mission` | 1.007116 1/hr | +43.87 % vs `Brandt Main!C30` = 0.70, **accepted by decision** | — |

Sensitivities worth knowing (each applied alone on the settled L3 base):
`K_d = 0` → air induction 0.0000, `OEW` **15477.7874**; Brandt's `0.199·T` engine alternate =
**4730.2300**; landing gear at 45,000 / 60,000 = 1273.1680 / 1370.4685.

Per-component and per-group agreement with Brandt is **not** expected: Brandt's structural line items
are his own psf model (`Wt!C7:H7` = wing 6.75 / fus 5.0 / pitch 6.0 / VT 6.0 psf) on **FULL** planform
areas, while the framework uses Raymer Table 15.2 psf on **EXPOSED** areas at L2 and the §15.3.1
build-up at L3. Those rows are marked `DEFINITIONAL` in the report, not chased.

---

## 7. Verification — two tiers, never blended

**Tier 1 — unit/correctness (gates `run_all_tests`).**

```matlab
cd('air_vehicle_design/sizing/tests'); run_all_tests
% or, per file:
runtests('air_vehicle_design/sizing/tests/disciplines/TestWeightsL2.m')
```

Contents: physical invariants (`OEW > 0`, `OEW < W_TO`, sanity floor `OEW > 0.30·W_TO`), per-equation
**hand-computed** expected values (evaluated in the comment block from the named repo extract, never
by calling the code under test and never from a ground-truth file), table-constant checks against
`metabook_data.md` / `roskam_vol1_data.md` line numbers, the DI name-trap locks, read-only checks on
every `Dependent`, live-recompute-on-mutation checks, unset-`W_TO` error contracts, and the two
frozen-derived regression guards (`testOEWScalesWithItsArgumentNotAFrozenWTO` at L2,
`testLandingGearScalesWithWTO` at L3).

Deliberate labelled reds, which are the **only** expected weights failures:
`TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` and
`TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified`. Each keys off its **source file's own
TO-DO sentence** (`WeightsL1.m` / `WeightsL3.m` header text) — there is no JSON marker key to read for
either, unlike the `_TODO_*` keys the geometry/aero TO-DO tests use.

★ There was briefly a **third** `testTODO_`-named case,
`TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO`, written to fail while the `requireWTO`
over-guard existed. The over-guard was removed in the same phase, so the test went green while its
docstring still said "EXPECTED RED" and still gave a resolve-recipe for landed work. It has since
been **deleted** — a `testTODO_` marker whose condition is satisfied has nothing left to guard, and
leaving it would have invited a future reader to "fix" a passing test by re-adding the over-guard.
The principle it encoded survives in `WeightsL2`/`WeightsL3`'s `requireWTO` docstrings and in
`TestWeightsL3.testWTODependentPropertiesErrorWhenWTOUnset`: **a guard must encode a real
dependency, not a house style** (todo §P4-18). So the suite has **two** `testTODO_` cases in weights,
both red by design.

**Tier 2 — Brandt comparison report (informational, NOT pass/fail, not in `run_all_tests`).**

`examples/F16A/weights_brandt_comparison.m` → `.json` + `.md`. **45 data rows in 7 sections**
(1 OEW / 2 structural / 3 engine+systems / 4 engine weight / 4b the two DI'd scalars / 5 NOT-MODELED
gap tally / 6 open-item sensitivities). Columns: `Parameter | Fidelity | Computed | Brandt | PctDiff |
Alt | Divergence | Source | Notes`.

- `Divergence` is three-state, as in the geometry report: `BY DESIGN` (same kind of quantity,
  divergence expected — sanity-check the magnitude), `DEFINITIONAL` (different kind of quantity
  altogether — the `%Diff` is not an error measure), blank (a genuine agreement check).
- ★ The second-source column is named **`Alt`**, not `TO` as the geometry report calls it, because
  here the second source is a **workbook** (`corrections.xls Wt!B12` = 19148.08, Casey's
  revised-weight workbook) rather than the T.O. Same column position, different content and label.
- Expected values come from `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json .weights`, never from
  a `TestWeights*.m` hardcoded expected. **Nothing in this report may
  ever backfill a unit test's expected value.**
- Run it via `matlab -batch`, not the MATLAB MCP tool: the wide-table `disp` hang is on record.

---

## 8. Standing TO-DOs and open items (do not treat any of these as closed)

| Item | Status | Where |
|---|---|---|
| Every §15.3.1 exponent unverified against the physical book — 62-row checklist; 2 CONFLICT (Eq. 15.13 `N_en^1.023`, Eq. 15.3 `cos(Λ_vt)^−0.323`, code values **KEPT** by decision) / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY (corrected 2026-07-30 by a direct recount of the recovered 62-row table -- the previous "9/24/27/5" breakdown summed to 67, not 62, and did not match the table; the table itself has always had exactly 62 rows) | **STANDING**, guarded red | todo §3a; `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` |
| Raymer **Table 6.1** coefficients are not present anywhere in this repo; user to supply. Code uses Table 3.1 | **STANDING**, guarded red | todo §P4-8; `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` |
| `K_d = 0` is a documented, legal straight-duct value and `0^0.182 = 0`, so it **silently zeroes the entire 227.54 lbf air-induction component** — no error, no warning, not even a `NaN` (`OEW` reads 15477.7874). **No guard is added, by explicit user decision 6.** `H_v = 0`, `L_s = 0`, `V_t = 0` likewise unguarded | **OPEN** | todo §P4-11 |
| The `0.95` in `W_l = 0.95·W_TO` has **no citation in the repo** | **OPEN** | todo §P4-16 |
| The `6.7 lb/gal` fuel density behind `V_t` = 940 gal is cited **nowhere** in the repo. `V_t` is deliberately kept an **input** rather than derived, precisely so the uncited constant does not enter an equation | **OPEN (provenance)** | todo §P4-5b |
| `L_d` = 7.5 ft `[estimate]` vs `geom.L_duct` = 14.0 (+201.47 lbf on `OEW`); `D_e` = 3.33 `[estimate]` vs `geom.D_exit` = 3.537022 (+24.94) — both deliberately **not** wired | **OPEN** | todo §P4-4 |
| `design_mach` = 2.0 must be cited to **Brandt** (`Main! aircraft.Mmax`), **not** to the T.O. Mach limit, which is a different number, **2.05** | **OPEN (citation)** | todo §P4-13 |
| `f16a_L1.json .geometry.M_max` was the third copy of the design Mach; geometry now reads the requirements file, but a full requirements consolidation is still pending | **OPEN** | todo §P4-14 |
| `WeightsL2.LG_fraction('general_aviation') = 0.057` is uncited; the extract's `navy_fighter` 0.045 row is absent from the code | **OPEN** (neither affects the F-16) | todo §P4-7 |
| 18 of L3's 42 numeric inputs are unpinned `[estimate]`s (`L_m`, `L_n`, `N_l`, `D_e`, `L_tp`, `L_sh`, `L_ec`, `L_d`, `L_s`, `V_i`, `V_p`, `N_t`, `N_s`, `N_ci`, `N_u`, `R_kva`, `L_a`, `W_uav`), plus the DI'd-but-unpinned `F_w`, `L_t`, `S_cs` on the geometry object | **OPEN** (spec-data gaps, not equation-citation issues) | `F16WeightsL3.md` §5 |

Items **resolved** in the Phase-4 implementation, so a reader does not chase them: review findings #5,
#11, #12 and §P4-17 (all four frozen-derived defects, §4); §P4-0 / finding #14 (the 19,148-cited-as-
`Wt!B12` mis-attribution); §P4-1a/b (`×1.3` placement); §P4-2 (`prop.bypass_ratio`); §P4-3 (no Mach at
L2); §P4-5a (`W_l`); §P4-5c (`SFC_mission`); §P4-6 (dead `AR_ht`/`lambda_ht`); §P4-9 (the false
category-lookup note); §P4-10 (`W_subsystems`' false contract); §P4-12 (the stale payload note);
2026-07-24 §3c items 1, 3, 4, 5, 6. The full as-built re-status, plus four items the implementation
itself surfaced (§P4-18 the `requireWTO` over-guard, §P4-19 a false verification claim removed from
`WeightsL3.m`, §P4-20 / §P4-21 two already-stale JSON comments, §P4-22 a Phase-2 tier-injection miss in
`fidelity_comparison.m`), is `VnV/BrandtF16A/todo.md` → **2026-07-25 Phase 4 AS-BUILT re-status**.

The **three geometry-DI name traps** are permanent hazards, not TO-DOs — each would produce a
plausible wrong number with no error if rewired by name:
`S_ht`/`S_vt` ← `geom.S_exposed_*` (51.1486 / 40.8897), **not** `geom.S_ht`/`S_vt` (108 / 60 = FULL);
`AR_vt`/`lambda_vt` ← `geom.AR_exposed_vt`/`lambda_exposed_vt` (1.294 / 0.437), **not** the FULL
1.6 / 0.5; and `D_fus` ← `geom.H_max_fuselage` (5.0, Eq. 15.4 structural **depth**), **not**
`geom.D_fus` (6.0, the Roskam Eq. 12.3 **equivalent diameter**) — Eq. 15.4 carries `D_fus^0.849`, so
that substitution inflates the fuselage by +17.9 %. Locked by
`TestWeightsL3.testNameTrap*` / `TestWeightsL2.testGeometryDINameTraps`.

---

## 9. Corrections to the previous revision of this subplan

Recorded because the old text was quoted elsewhere and its errors propagated.

| # | Old claim | Correction |
|---|---|---|
| 1 | `OEW/W_TO = A·W_TO^C` cited to **"Raymer 6th ed, Table 6.1"** (old `:81`, `:88`) | Code cites **`[Raymer 6th ed. Table 3.1]`**, and its four coefficient rows match `metabook_data.md:20-26` exactly. **Table 6.1's coefficients are not in this repo at all.** This subplan's own Table 6.1 line was the *sole* source of that claim; it is kept here as a **standing TO-DO** (§8) rather than deleted, and is guarded by `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` |
| 2 | L2 = "Raymer eq 6.1 multi-parameter regression", `OEW = W_TO·(a + b·W_TO^c1·AR^c2·(T/W)^c3·(W/S)^c4·M_max^c5)·K_vs` with a 7-coefficient jet-fighter row | **No such method exists and none was ever built.** L2 is Raymer **Table 15.2** surface density (psf × area) plus the metabook Sec. 7 fractions (§5.2). No `AR`, no `T/W`, no `W/S` enters L2 weights |
| 3 | Fuselage = "Raymer eq **15.5**" | Fuselage is **Eq. 15.4**. Eq. 15.5 is the **main landing gear** |
| 4 | Installed engine = "Raymer **eqs 7.13–7.17**, `W_dry + W_oil + W_starter`" | The engine group is **Eqs. 15.7–15.15** on top of a dry weight from **Eq. 10.10** |
| 5 | Landing gear = "`0.034 × W_TO` (Roskam fraction), Roskam Airplane Design Part I" | Framework uses **0.033** `[AE481 metabook Sec. 7]` (`metabook_data.md:330`). **0.034 is Brandt's** figure (`Wt!F23` = 0.034 literal, `Wt!B23` = 1066.818000) — a different model, reported side by side, never as an error. The Roskam attribution was wrong |
| 6 | Wing = "Raymer/Nicolai plate-area — exact eq TBD at implementation" | As built: **Eq. 15.1**, with `cos(Λ_LE)` and `tc_root^(−0.4)`, both inside the standing exponent TO-DO |
| 7 | "The concrete `F16WeightsLN` classes set their F-16 spec values in a **no-arg constructor** … they do **not** read `f16a_L*.json`" | All three read the unified per-level JSON; L2/L3 additionally read `f16a_requirements.json` and take two injected objects (§3) |
| 8 | "`F16WeightsL3` currently carries the required exposed-area / component-geometry inputs … as its own frozen properties and takes no geometry object. **This is a known defect scheduled for Phase 4**" | **Done.** 21 geometry quantities now arrive by DI from `F16GeomL3` as `Dependent` getters; the 2 dead ones (`AR_ht`, `lambda_ht`) were deleted, not rewired (§P4-6) |
| 9 | L1/L2/L3 test tables listing `F16 OEW at W_TO=31,377` bounds "±15 % / ±10 % / ±40 % of Brandt" as unit tests, against **19,148** cited as `Brandt Wt!B12` | **Removed from the unit tier entirely** (review finding #14): `Wt!B12` is live-verified **19980.700578**, and 19,148.08 is `corrections.xls`. An external-agreement check is not a unit test and its expected value must never be backfilled from ground truth. It is now a report row with 19,980.70 as `Brandt` and 19,148.08 in the labelled `Alt` column (§7) |
| 10 | "Do NOT hardcode Brandt's OEW=19,980 lb as a calibration target input … it may differ from Brandt by 5–15 %" | The rule stands, and the actual spread is wider than 5–15 %: L1 −4.36 %, L2 −21.60 %, L3 −21.40 %. **2733.68 lbf (13.68 % of `Wt!B12`)** of the L2/L3 gap is Brandt components with **no framework analog** at any level — nacelles 186.82 + strakes 90.00 + other structure 2016.86 + armament support 440.00 — reported as `NOT MODELED`, never as error |
| 11 | An earlier partial patch to this file that said "Geometry has no L3" | Obsolete. Geometry's L3 tier was eliminated 2026-07-22, reinstated 2026-07-24 and **promoted 2026-07-25** to the full L3 geometry tier; `F16WeightsL3` injects `F16GeomL3` |
