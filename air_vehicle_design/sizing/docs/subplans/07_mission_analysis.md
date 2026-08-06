# Subplan 07 — Mission Analysis

**Status:** Documentation rewritten 2026-07-24 (scribe pass) to match the 3-tier + static-toolbox
architecture established during the Geometry/Aerodynamics/Propulsion/Weights deep-dives. Equations
re-verified against real source material (Roskam *Airplane Design Part I* read directly from the
PDF — see citations below — plus Mattingly and the repo's existing reference extracts). **Not yet
implemented** — no `.m`/JSON files exist for this discipline. Next steps are the `io` role (JSON +
Brandt-comparison-JSON authoring) and then the implementation loop, both gated on user sign-off of
this document (including the "Known Issues" and "CAP-vs-Brandt" sections below).
**Depends on:** Steps 1–5 (all disciplines — Mission calls `aero`/`prop` at L2/L3), Step 6
(constraint analysis is independent of Mission; not a hard dependency, but both feed Step 8)
**Blocks:** Step 8 (sizing)

---

## Objectives

Implement `MissionBase` (Tier 1), `MissionModelL1/L2/L3` (Tier 2 abstract enforcers), and
`F16MissionL1/L2/L3` (Tier 3 concrete), following the identical pattern already used by
`propulsion`/`aerodynamics`/`weights` (see `src/base/PropulsionBase.m` +
`src/disciplines/propulsion/PropulsionModelL1.m` + `src/disciplines/propulsion/PropL1.m` +
`examples/F16A/F16PropL1.m` for a clean 4-file example of the pattern this discipline must follow).

Key deliverable: `compute_fuel(obj, aero, prop, W_TO)` → total mission fuel weight (lbf), computed
by looping over a mission profile's named segments and dispatching to per-segment fuel-fraction
equations (Roskam *Airplane Design, Part I* fuel-fraction/Breguet method at L1; the same equations
evaluated with real `aero.drag_polar`/`prop.TSFC` calls at L2; sub-segmented/energy-height at L3).

Visualization: waterfall bar chart of fuel burn per segment; L1/L2/L3 fidelity overlay.

---

## Architecture (matches the established 4-file discipline pattern)

```
src/base/MissionBase.m                              Tier 1 — abstract contract:
                                                     compute_fuel(obj, aero, prop, W_TO) -> scalar
        ^
src/disciplines/mission/MissionModelL1.m            Tier 2a — abstract enforcer, L1
src/disciplines/mission/MissionModelL2.m            Tier 2b — abstract enforcer, L2
src/disciplines/mission/MissionModelL3.m            Tier 2c — abstract enforcer, L3
        (each inherits MissionBase DIRECTLY, not chained L1->L2->L3)
        ^
examples/F16A/F16MissionL1.m                        Tier 3 — concrete, one delegation line/method
examples/F16A/F16MissionL2.m
examples/F16A/F16MissionL3.m
```

Alongside, three standalone static toolboxes (`methods (Static)` only, NOT in the inheritance
chain, called as `MissionL1.method(...)`):

```
src/disciplines/mission/MissionL1.m   — Roskam Table 2.1 fixed fractions + Table 2.2 Breguet
src/disciplines/mission/MissionL2.m   — single-point Breguet (aero.drag_polar/prop.TSFC) + discretized climb (N=20)
src/disciplines/mission/MissionL3.m   — sub-segmented Breguet (N=20) + discretized energy-height climb (N=40)
```

Plus one generic Layer-1 IO utility (mirrors `src/constraints/ConstraintSetImporter.m`'s role and
its "deliberately thin" philosophy — see Design Notes):

```
src/disciplines/mission/MissionProfileImporter.m
```

### The high-level static IS the generic segment-dispatch loop (preserve legacy structure — direct
### user instruction)

The legacy `F16MissionAnalysisLevel1/2/3.get_mission_fuel` loop-over-named-segments-and-dispatch-
to-`segment_<name>` pattern (`temp_Casey/examples/F-16A B Block 10 and 15/MissionAnalysis/`) is the
**preferred design to carry forward**, not merely an acceptable option. It becomes the high-level
static in each toolbox:

```matlab
[W_fuel, breakdown] = MissionL1.get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj)
```

where `missiondata` is the struct produced by `MissionProfileImporter` (segment-name-keyed, one
entry per CAP segment — same shape the legacy `MissionAnalysisModel.get_mission_data`/
`tableToNestedStruct` pipeline already produces). Internally this loops over
`missiondata.segment_names` and calls the matching low-level static
(`MissionL1.segment_takeoff(...)`, `MissionL1.segment_climb(...)`, etc.) — i.e. the legacy
dispatch loop's *shape* (string-matched segment name -> handler function) is preserved exactly;
only the per-segment *equations* are corrected where verification below found them wrong, and the
whole loop moves from a `classdef` instance method into a toolbox static so it fits the
established Tier pattern. `F16MissionL1.compute_fuel(obj, aero, prop, W_TO)` (Tier 3) is then a
single delegation line:

```matlab
function W_fuel = compute_fuel(obj, aero, prop, W_TO)
    W_fuel = MissionL1.get_mission_fuel(obj.missiondata, W_TO, aero, prop);
end
```

### File-I/O — reuse the legacy Excel-loading logic, translated into the new architecture

`MissionAnalysisModel.get_mission_data` (`temp_Casey/src/ComputationModels/MissionAnalysis/
MissionAnalysisModel.m`) — `readtable`/`readcell` the mission sheet (segments as **columns**,
quantities as **rows**, unlike `Constraints.xlsx`'s row-per-condition layout) → per-segment
atmosphere via `atmosisa` → `tableToNestedStruct` into a segment-name-keyed struct — is the
pattern `MissionProfileImporter.read(filepath, sheet)` carries forward, per direct user
instruction ("reuse this logic... rather than designing a new loader from scratch"). One
**deliberate refinement**, precedented elsewhere in this exact codebase: `ConstraintSetImporter.m`
(the already-implemented, already-reviewed analog for `Constraints.xlsx`) explicitly documents that
it does **not** recompute atmosphere columns (temperature, density, q, ...) itself, because
`AircraftState` already derives those from altitude+Mach with its own citations (Mattingly Eq.
2.52), and duplicating that would be redundant, uncited-a-second-time logic living in two places.
`MissionProfileImporter` should follow the same "deliberately thin" precedent: read the raw
per-segment columns only (altitude, Mach, given range/time, payload drop, CLmax_TO/CLmax_land if
present) and let the `MissionLN` toolboxes construct `AircraftState(alt_ft, mach)` themselves where
atmosphere is needed — i.e. drop the legacy loader's manual `atmosisa`-into-table step, keep
everything else (readtable orientation, segment-name struct keying, `Dry`/`Wet` flag column).

This is a structural/coding-practice refinement (avoiding duplicated, doubly-uncited atmosphere
math), not a physics correction — flagged here so the implementation loop doesn't mistake "drop the
atmosphere columns" for scope creep beyond "reuse the legacy logic."

**`Mission_Profile.xlsx` needs to be copied into `examples/F16A/`** before implementation (same as
`Constraints.xlsx` was copied there for Step 6) — `MissionProfileImporter`/`F16MissionL1` should
read `examples/F16A/Mission_Profile.xlsx`, not reach into `temp_Casey/inputs/` at runtime (rule:
`temp_Casey/` is read-only reference, never a runtime dependency of the framework).

### Files to Create

| File | Purpose |
|---|---|
| `src/base/MissionBase.m` | Abstract: `compute_fuel(obj, aero, prop, W_TO) -> scalar` |
| `src/disciplines/mission/MissionModelL1.m` | Abstract enforcer, L1 (declares `missiondata` property, tabulated-only contract) |
| `src/disciplines/mission/MissionModelL2.m` | Abstract enforcer, L2 |
| `src/disciplines/mission/MissionModelL3.m` | Abstract enforcer, L3 |
| `src/disciplines/mission/MissionL1.m` | Static toolbox — Roskam Table 2.1/2.2 fixed-fraction + tabulated-Breguet equations |
| `src/disciplines/mission/MissionL2.m` | Static toolbox — single-point Breguet, calls `aero.drag_polar`/`prop.get_TSFC`/`prop.compute_TSFC_AB`; Climb discretized N=20 |
| `src/disciplines/mission/MissionL3.m` | Static toolbox — sub-segmented Breguet (N=20) + discretized energy-height climb (N=40) |
| `src/disciplines/mission/MissionProfileImporter.m` | Generic Layer-1 IO: reads a `Mission_Profile.xlsx`-shaped workbook into a segment-keyed struct |
| `examples/F16A/F16MissionL1.m` | Concrete, F-16 CAP profile, L1 |
| `examples/F16A/F16MissionL2.m` | Concrete, F-16 CAP profile, L2 |
| `examples/F16A/F16MissionL3.m` | Concrete, F-16 CAP profile, L3 |
| `examples/F16A/Mission_Profile.xlsx` | Copied from `temp_Casey/inputs/` (not yet done — implementation prerequisite) |

### Tests (current repo convention — see CLAUDE.md's Tests section: generic + F-16-specific tests
### currently live together per fidelity level, e.g. `tests/disciplines/TestAeroL1.m`; `tests/mission/`
### mirrors the already-established `tests/constraints/` sibling folder, not PLAN.md's stale
### `tests/mission/` + `tests/examples/F16A/` split prose)

| File | Tests |
|---|---|
| `tests/mission/TestMissionL1.m` | Generic `MissionL1` statics + `F16MissionL1` concrete class |
| `tests/mission/TestMissionL2.m` | Generic `MissionL2` statics + `F16MissionL2` concrete class |
| `tests/mission/TestMissionL3.m` | Generic `MissionL3` statics + `F16MissionL3` concrete class |
| `tests/mission/TestMissionProfileImporter.m` | Generic importer against `examples/F16A/Mission_Profile.xlsx` |

Brandt comparison (informational, not pass/fail — separate from the tests above, same convention
as `examples/F16A/geometry_brandt_comparison.m`): `examples/F16A/mission_brandt_comparison.m`.

---

## Input vs. derived properties (Tier-3 `F16MissionL*` — optimization-ready property design)

Mission's Tier-3 classes differ from `F16GeomL2`'s reference pattern in one respect worth being
explicit about, so the implementation loop doesn't misapply the `Dependent`-property convention:

- **Inputs** (plain, mutable `properties`, set once from the imported mission-profile data): the
  CAP segment arrays — `segment_names`, `alt_ft`, `mach_end`, `dist_nm_given`, `time_min_given`,
  `drop_lb`, plus scalar spec constants the segments need (`CLmax_TO`, `CLmax_land`, `mu_rolling`,
  `liftoff_factor`, `warmup_fuel_per_engine_lb`, `RFF`). These come from
  `MissionProfileImporter.read(...)` in the constructor, same as `F16GeomL2`'s constructor sets its
  inputs from JSON.
- **Derived, zero-argument `Dependent` properties** (pure functions of the object's OWN stored
  inputs, no external args — these DO follow the `F16GeomL2` pattern exactly): e.g.
  `total_range_nm_given = sum(obj.dist_nm_given, 'omitnan')`, `n_segments =
  numel(obj.segment_names)`. Anything computable from the mission-profile arrays alone belongs
  here, recomputed on every read, never frozen.
- **NOT a bare `Dependent` property — a method, matching the `drag_polar(obj, state)` /
  `thrust_lapse(obj, state)` convention already used by every other discipline**:
  `compute_fuel(obj, aero, prop, W_TO)`. This is Mission's primary output, but it cannot be a
  zero-argument `Dependent` getter because it depends on external, per-call arguments (the
  aero/prop discipline objects and the sizing loop's current `W_TO` guess) that are not, and
  should not be, stored properties of the Mission object itself — exactly the same reason
  `AerodynamicsBase.drag_polar` and `PropulsionBase.thrust_lapse` are methods taking `state`, not
  properties. This is consistent with the established pattern, not a deviation from it — flagging
  explicitly so a reviewer doesn't mistake "why isn't `compute_fuel` `Dependent`" for a bug.
- **No violation found in the legacy code equivalent to Geometry's frozen-`S_exposed_wing`
  bug**: the legacy `F16MissionAnalysisLevel*.missiondata` is a genuine input (read once from
  Excel, not a computed-from-other-properties derived quantity), and `mission_fuel` is stored as a
  side effect of calling `get_mission_fuel` (matches the `VnV/BrandtF16A` "run() dual-return
  contract" convention: functional return + stored property, recomputed fresh every call — not a
  stale cache).

---

## CAP mission profile vs. Brandt's 14-segment Miss-tab profile — read this before touching either

**These are two different mission profiles serving two different purposes. Do not conflate them
and do not make the generic segment-dispatch loop match Brandt segment-for-segment.**

1. **CAP profile** (`temp_Casey/inputs/Mission_Profile.xlsx`, sheet `CAP`; 10 segments — see table
   below) is the actual mission the F-16 concrete framework classes (`F16MissionL1/L2/L3`) carry
   as their default profile. This is what ultimately feeds `examples/F16A/requirements.json`'s
   mission-profile section per PLAN.md Step 0's data model (`io` role's job next, not this pass's).
2. **Brandt's Miss-tab profile** (`VnV/BrandtF16A/BrandtMission.m`, `GroundTruth/
   f16a_geometry.json`'s `mission` section; 14 segments — Takeoff, Accel, Climb, Cruise, Patrol,
   Dash, Patrol2, Combat, Egress, Patrol3, Climb2, Cruise2, Loiter, Landing) is Brandt's own
   calibrated spreadsheet logic — a different TSFC model ("Old" `sqrt(theta)` lapse, not the
   generic Roskam/Mattingly forms below), Ps-based climb timing, and a different segment count/
   naming. It exists **solely** as the ground-truth target for the informational
   `examples/F16A/mission_brandt_comparison.m` report (never a unit-test "expected" value, per the
   project's two-test-tier rule) — it must **not** be hardcoded into `MissionL1/L2/L3`'s generic
   equations or into `F16MissionL*`'s CAP profile, for the same reason `Cfe`/`e_osw` must not be
   hardcoded into F-16 aerodynamics (see PLAN.md's Layer-2 rule).

   **Why the segment counts differ (user clarification, 2026-07-24):** four of Brandt's 14
   segments — `Patrol`, `Patrol2`, `Patrol3`, and `Climb2` — are 0-minute/0-distance bookkeeping
   waypoints in the Miss tab (Climb2 is explicitly "same conditions" as the segment before it, and
   the three Patrols carry `time_min_given = 0`), not distinct flight legs with their own fuel
   burn. The CAP profile deliberately excludes these zero-duration placeholder segments rather
   than omitting real flight legs, which is why it has 10 segments instead of 14 — `Accel` and
   `Egress` are the only Brandt segments genuinely absent from CAP's simplified 10, not a
   14-vs-10 mismatch across the board.
3. Expect the CAP-profile fuel total and Brandt's Miss-tab fuel total (6000.43 lb) to **disagree**
   — this is already documented precedent (the "F-16 Mission Profile Discrepancy" covered by this
   subplan: Brandt's 14-segment profile vs. a simplified profile
   gives 10–25% lower fuel estimates, "not an error — a deliberate simplification"). The
   `mission_brandt_comparison.m` report should state this plainly rather than try to force
   agreement.

---

## Design Notes

- L1 does NOT call `aero.drag_polar` or `prop.get_TSFC`/`prop.compute_TSFC_AB`. Arguments accepted
  but unused — test this with a mock that errors if called (same pattern the original draft
  specified).
- L2 calls one `aero.drag_polar(state)` per segment, and `prop.get_TSFC(state)` (mil power) or
  `prop.compute_TSFC_AB(state)` (AB power, e.g. Dash/Combat/Takeoff) as appropriate — **not** an
  ad hoc scalar multiplier on cruise TSFC (see Known Issues: `TSFC_dash = TSFC_cruise*10`).
  `compute_TSFC_AB` already exists on `F16PropL2`/`F16PropL3` (Mattingly Eq. 3.55b coefficients,
  `C1_AB=1.60, C2_AB=0.27` — confirmed by reading `examples/F16A/F16PropL2.m`), so this is calling
  an already-implemented method, not new propulsion work.
- L3 sub-divides cruise/dash into N=20 sub-intervals (cruise-climb effect: L/D improves as weight
  drops); climb uses an energy-height method, discretized at its own N=40 (user-directed
  2026-07-24) — L2 also discretizes climb the same way, at N=20. See "Known Issues" for the legacy
  L3 climb loop's two real bugs that need fixing (not replicating) when this is implemented.
- Weight continuity: `W` at the end of segment N is `W` at the start of segment N+1 — enforced by
  the dispatch loop itself (single running weight variable), same as `BrandtMission.run`'s
  `W_frac` accumulator pattern.
- **Reserve fuel fraction: `RFF = 0.06`. CONFIRMED (user decision, 2026-07-24).** The prior draft
  stated "RFF=0.05 (Roskam convention)," which was wrong on two counts: (a) Roskam's own text
  (`Airplane Design Part I`, §2.4, Eq. 2.6/2.14/2.15) does **not** give a fixed universal reserve
  percentage — it treats `W_Fres` as mission-specific (the book's own Fighter worked example,
  §2.6.3, explicitly states "No reserves." for that mission); (b) the legacy code
  (`F16MissionAnalysisLevel1/2.get_mission_fuel`) actually implements
  `fuel_fraction = total_fuel_used * 1.06 / W_TO` — a **6%** factor, not 5%. Use `RFF = 0.06`,
  cited as "generic 6% reserve+trapped-fuel allowance, `docs/reference_extracts/metabook_data.md` Eq. 2.17 (after
  Raymer-style practice) — not from Roskam Part I directly, whose own method treats reserves as
  mission-specific (§2.4)."
- `W_drop` from payload release (Combat segment, 4,400 lbf) reduces weight at the end of that
  segment directly (not routed through the fuel-fraction), matching both the legacy code's
  `W_out = W_in - fuel_used - payload` pattern and Brandt's `dW/W_TO = (fuel_burn + drop)/W_TO`.
- **TODO (high-lift configuration)** — unchanged from the prior draft, still open: the CAP profile
  has segments (takeoff, combat, landing) that each fly with a different slat/flap setting. Mason,
  "F-16 configuration" (archive.aoe.vt.edu/mason/Mason_f/F16S04.pdf, slide 10) gives sourced
  deflections for six named configs. If a `HighLiftConfig`-style value class gets built (per
  subplan 06's identical TODO), each mission segment should carry/reference the matching config so
  `aero.drag_polar`/`aero.CLmax` reflect the right configuration per segment rather than always
  using clean values.

---

## Known Issues in Legacy Reference

Per direct user instruction: the legacy **structure** (Excel-driven mission profile -> nested
struct keyed by segment name -> loop dispatching to `segment_<name>`) is preserved and is the
*preferred* design, independent of whether any individual equation below is right or wrong. Each
item below is classified as: **(A) keep as-is** (verified correct against a real citation),
**(B) fix — use the cited correct source instead**, or **(C) structural-only** (preserve the
plumbing; not a physics claim). All numeric fighter-category values below were confirmed by
reading Roskam *Airplane Design, Part I* (Table 2.1, p.12; Table 2.2, p.14; the worked Fighter
example, §2.6.3, pp.60–67) directly, page-by-page, in this pass — not re-derived, not taken on
faith from the legacy code or the prior draft.

### (A) Verified correct as-implemented — keep
- **`MissionAnalysisLevel1.tab_fuelfraction`'s Fighter row** (`0.990, 0.990, 0.990, [0.90 0.96],
  0.990, 0.995` for warmup/taxi/takeoff/climb/descent/landing) **exactly matches** Roskam Table
  2.1's Fighters row, confirmed reading the table image directly. Keep this Constant table as-is.
- **`segment_cruise`/`segment_dash`'s Breguet form** `WF = exp(-(R*TSFC)/(V*(L/D)))` matches
  Roskam Eq. 2.10 (jet range: `R_cr = (V/cj)_cr * (L/D)_cr * ln(W4/W5)`), algebraically rearranged.
  Keep, cite as **Roskam Airplane Design Part I, Eq. 2.10** (not a generic "Breguet range
  equation" — the prior draft's citation was vague where a precise Roskam eq. number is
  available and verified).
- **`segment_loiter`'s Breguet endurance form** `WF = exp(-(t*TSFC)/(L/D))` matches Roskam Eq.
  2.12 (jet endurance: `E_ltr = (1/cj_ltr)*(L/D)_ltr*ln(W5/W6)`). Keep, cite as **Roskam Airplane
  Design Part I, Eq. 2.12**.
- **`segment_landing`'s WF=0.995** matches Roskam Table 2.1 Fighters, Landing column exactly.
  Keep.
- **`Table 2.2`-derived `cruise_LD`/`cruise_cj`/etc. Constant tables**: spot-checked the Fighters
  row's cruise L/D (`[4 7]`) against the real Table 2.2 image — matches exactly. (Not every cell of
  every row was re-verified against the book in this pass; flagging this as a spot-check, not an
  exhaustive re-transcription.)

### (B) Fix — legacy value is wrong or uncited; use the correct source instead

1. **`segment_takeoff` hardcodes `WF=0.95` in all of `MissionAnalysisLevel1/2/3` and all three
   `F16MissionAnalysisLevel*` — this is a confirmed bug**, not a modeling choice. The correct
   fighter-category value, verified directly from Roskam Table 2.1, is **`WF=0.990`** — and the
   *same file* already has this correct number available and unused (`tab_fuelfraction("fighter",
   "takeoff")` would return 0.990) while `segment_takeoff` ignores it and hardcodes an unrelated,
   far more aggressive 5%-fuel-burn value. **Fix: use Roskam Table 2.1's fighter Takeoff value,
   0.990**, not 0.95, and not the prior subplan draft's stated 0.995 (also checked — 0.995 is
   Roskam's Landing value for fighters, not Takeoff; the draft's citation was imprecise).

2. **`F16MissionAnalysisLevel1.get_mission_fuel` skips Startup and Taxi entirely** (`% Skip these;
   W_array(i) = W_TO;` — no fuel burned), even though the very same class's `tab_fuelfraction`
   table has the correct values (0.990 each, verified). **`F16MissionAnalysisLevel2` does the
   opposite inconsistency**: it calls `segment_startup`/`segment_taxi`, but those hardcode generic
   `WF=0.99`/`WF=0.98` (not the fighter-specific Table 2.1 value for Taxi, which is 0.990, not
   0.98). **Fix: burn fuel for both segments at every fidelity level, using the verified Roskam
   Table 2.1 fighter values (Startup=0.990, Taxi=0.990)** — do not skip, and do not substitute an
   uncited generic 0.98.

3. **Combat's citation is wrong on both the equation number and, arguably, the formula shape.**
   The prior draft cited "Roskam Airplane Design Part I, eq 2.13" for `WF = 1 - TSFC*(T/W)*t`.
   Verified directly: **Roskam Eq. 2.13 is the overall mission fuel-fraction product formula**
   (`Mff = (W1/W_TO) * product(Wi+1/Wi)`), unrelated to combat. Roskam's generic 8-phase method
   (§2.1–2.4) has no named "combat" phase at all — but Roskam's own **Fighter worked example**
   (§2.6.3, Table 2.19's "Strafe" phase, pp. 63–64) is directly analogous to a CAP-mission Combat
   segment, and treats it using the **same Breguet *endurance* form as Loiter** (Eq. 2.12), with a
   directly-assumed poor L/D (4.5) and near-max-power `cj` (0.9) for the combat/strafe condition —
   **not** the `1 - TSFC*(T/W)*t` linear form. The legacy `MissionAnalysisLevel1.segment_combat`
   (`WF = exp(-(time*60*TSFC/LD_combat))`) actually already implements the *correct* Breguet
   endurance shape (matching Roskam's own precedent) — it's the **citation** in the subplan draft
   that was wrong, not this particular legacy formula. **Fix: keep the legacy `segment_combat`
   formula, correct the citation to "Roskam Airplane Design Part I, Eq. 2.12, applied to a
   combat/strafe segment per the method demonstrated in §2.6.3 Example 3: Fighter" — not Eq.
   2.13.**
   - **Secondary flag on the same segment — CONFIRMED (user decision, 2026-07-24): 0.866 applies
     to L1 Cruise/Dash only, not Combat.** `segment_cruise`/`segment_dash`/`segment_combat`'s
     shared `compute_LD_ratio` applies a `0.866` (`=√3/2`) best-range correction factor to L/D for
     all three segment types identically in the legacy code. That factor is the correct reduction
     from `(L/D)_max` to the best-*range*-cruise L/D for a parabolic drag polar at L1 (a standard
     result, not pinned to a citable Roskam equation number in the material available to this
     pass — uncited-but-standard) and is confirmed to be kept for L1 Cruise/Dash. Applying it to
     **Combat** is not appropriate: Roskam's own worked Strafe-phase example does not apply any
     such correction — it assumes a directly-given poor L/D for the maneuvering/high-drag combat
     condition (not a free-to-optimize best-range CL). **Combat gets its L/D supplied directly**
     (Table 2.2-style tabulated value at L1, or the aero object's maneuvering-condition L/D at
     L2/L3), with no 0.866 correction.
   - Separately, `docs/reference_extracts/metabook_data.md` cites a
     **different** correction factor for the same kind of best-range adjustment: "For cruise: L/D
     = 0.943 * (L/D)max for maximum range (Nicolai & Carichner)." This 0.943 vs. the legacy code's
     0.866 (`=√3/2`, the standard jet-aircraft best-range result) are two different numbers from
     two different sources for nominally the same correction — flagging as an open inconsistency
     between two of the repo's own reference extracts, not resolved here (Nicolai & Carichner may
     define "maximum range" under different assumptions than the standard √3/2 jet result; not
     investigated further in this pass).

4. **`F16MissionAnalysisLevel1.get_mission_fuel`'s `TSFC_dash = TSFC_cruise*10`** — confirmed ad
   hoc, uncited, and structurally wrong (an arbitrary ×10 scalar on the cruise TSFC value, not a
   flight-condition-dependent computation). **Fix:** at L1, use the Roskam Table 2.2 fighter
   cruise `cj` row as-is for Dash too (Roskam's own method does not distinguish a separate "dash"
   TSFC category — cruise/dash share the same tabulated `cj` at L1, differentiated only by speed
   `V` and range `R` in the Breguet formula); at L2/L3, call `prop.compute_TSFC_AB(state)` at the
   Dash flight condition (real AB TSFC, Mattingly Eq. 3.55b, already implemented on
   `F16PropL2`/`F16PropL3`) instead of any scalar multiplier.

5. **Descent is "Not implemented yet" in all three `F16MissionAnalysisLevel*` classes**, and the
   prior subplan draft filled this gap with `WF=1.0` ("Roskam (conservative)"). Verified: Roskam
   Table 2.1's actual Fighters, Descent column value is **`0.990`** (a real 1% fuel burn), not
   1.0. **Fix: implement Descent using the verified Table 2.1 value (0.990)**, not a
   zero-fuel-burn placeholder — this should be a trivial fixed-fraction segment like
   Startup/Taxi/Landing, not left unimplemented.

6. **`F16MissionAnalysisLevel3.get_mission_fuel`'s Loiter branch sets `e_osw = aero_obj.e_osw_TO`**
   (takeoff-configuration Oswald efficiency) for the Loiter segment, which flies clean, not in a
   takeoff configuration. This looks like a copy-paste bug (`Combat`'s branch a few lines below
   correctly uses `e_osw_clean`... actually, re-checked: `Combat`'s branch also uses
   `e_osw_clean` with an inline comment "YOU SHOULD ABSOLUTELY USE THE COMBAT SLAT CONFIGURATION
   FOR THIS" — i.e. the legacy author already flagged Combat's own e_osw as provisional too).
   **Fix: Loiter should use `e_osw_clean`** (or a loiter-specific value if one exists), not
   `e_osw_TO`. Combat's `e_osw_clean` placeholder is pre-existing legacy self-awareness of the
   same open issue (a real maneuvering/combat-configuration Oswald efficiency is not modeled) —
   folds into the same high-lift-configuration TODO already tracked in the Design Notes above and
   in subplan 06.

7. **`MissionAnalysisLevel3.segment_climb` has a confirmed unit-conversion bug**: the
   pre-loop altitude call correctly converts feet to meters before calling `atmosisa`
   (`atmosisa(current_h*0.3048)`, line 46), but the `for i=3:n` loop's altitude call **omits the
   conversion** (`atmosisa(current_h)`, line 75) — passing a value in feet where `atmosisa` expects
   meters. For a 40,000 ft climb this asks `atmosisa` for the atmosphere at "40,000 m," which is a
   real, silent, large error (should be ~12,192 m). **Fix this specific line when implementing
   L3's climb**; the surrounding energy-height method itself (`WF = exp(-(TSFC*Δhe)/(V*(1-D/T)))`)
   is a legitimate approach (structurally consistent with Mattingly's Case 1/3 energy-height climb
   forms, Eq. 3.17/3.20, though not an exact match to Mattingly's `(C1/M+C2)` TSFC form) — keep the
   method, fix the bug.
   - **Secondary, lower-priority flag, same function**: a gravity-varies-with-altitude array
     `gh(i) = g*(r_e/(r_e+h))^2` is computed once for `i=2` (line 61) but the `for i=3:n` loop
     (lines 82–83) uses flat `g` instead of `gh(i)` — an internal inconsistency (the array is set
     up then abandoned), though the physical impact is negligible (<0.5% over these altitudes).
     Flagging for completeness, not urgency.

8. **`segment_cruise` (Level 1) passes the string `"dash"` into `compute_LD_ratio`, not
   `"cruise"`** (`MissionAnalysisLevel1.compute_LD_ratio("dash", LD)` inside `segment_cruise`).
   Given `compute_LD_ratio`'s current branching (cruise/combat/dash all hit the identical
   `0.866`-factor branch; only `loiter` differs), this is a **zero-numeric-impact copy-paste
   artifact today**, but would silently break if that branching were ever specialized per segment
   type. Flag and fix the string, no functional change expected.

9. **The `1.0065 - 0.0325*Mach` climb fuel-fraction formula is uncited and not traceable to any
   accessible source.** It appears in `MissionAnalysisLevel1.segment_climb` (legacy) **and**
   independently in `NPTEL_Fighter_Aircraft_Sizing.ipynb`'s `AcceleratedClimb`/`UnacceleratedClimb`
   classes (both uncited there too) — so it's used by two sources in this repo, but neither cites
   where it came from, and it does not appear in Roskam Part I (which instead gives Table 2.1's
   range-based fixed fraction, 0.90–0.96 for fighters, or the Breguet-style Eq. 2.7/2.8 as the
   climb-fraction method). Per PLAN.md's "zero uncited equations" rule: **do not carry this formula
   forward as a cited equation.** Use instead, at L1, Roskam Table 2.1's fighter climb range
   (0.90–0.96 — Roskam's own note says "no substitute for common sense," i.e. pick a
   representative point value, e.g. the midpoint ~0.93, or make it a tunable input) or, if a
   Mach-dependent single-point estimate is wanted, Roskam Eq. 2.8 (`E_cl = (1/cj)_cl*(L/D)_cl*
   ln(W3/W4)`, jet climb Breguet form) with Table 2.2's climb L/D/cj guides. At L2/L3, compute
   climb fuel from a real energy-height or Breguet-style integration using `aero`/`prop`, as
   already planned.

### (C) Structural-only (preserve regardless of any equation correctness) — no physics claim
- The named-segment string-match dispatch loop (`switch`/`if-elseif` on `erase`d segment name ->
  `segment_<name>` call) — this is the pattern being generalized into each `MissionLN.
  get_mission_fuel` high-level static, per direct user instruction, independent of any bug fixes
  above.
- The `MissionAnalysisModel.get_mission_data` readtable/readcell -> nested-struct pipeline — the
  file-I/O mechanism `MissionProfileImporter` carries forward (minus the atmosphere-column
  duplication noted in Design Notes).
- Commented-out alternate/exploratory argument lists throughout the three `F16MissionAnalysisLevel*`
  files (e.g. the large commented block in `F16MissionAnalysisLevel1.m`) are dead code from
  unfinished exploration — treated as equation reference only, per the task framing; not
  structural guidance, not carried forward.

---

## Equations & References (corrected, per-fidelity)

### L1 — Roskam Table 2.1 fixed fractions + Table 2.2 tabulated Breguet

| Segment | Equation | Reference |
|---|---|---|
| Startup | WF = 0.990 | Roskam *Airplane Design Part I*, Table 2.1, Fighters row (verified against book p.12) |
| Taxi | WF = 0.990 | Roskam Table 2.1, Fighters row |
| Takeoff | WF = 0.990 | Roskam Table 2.1, Fighters row (corrects prior draft's 0.995 and legacy code's 0.95 bug — see Known Issues #1) |
| Climb | WF ∈ [0.90, 0.96] (fixed-fraction, pick representative point) **or** `E_cl = (1/cj)_cl (L/D)_cl ln(W3/W4)` (Breguet form) | Roskam Table 2.1, Fighters row (range) **or** Roskam Eq. 2.8 (jet climb Breguet), Table 2.2 for `cj`/`L/D` — replaces the uncited `1.0065-0.0325M` formula, see Known Issues #9 |
| Cruise | `R_cr = (V/cj)_cr (L/D)_cr ln(W4/W5)` → `WF = exp(-R·cj/(V·(L/D)))` | Roskam Eq. 2.10; `L/D`, `cj` from Table 2.2, Fighters row (`L/D=4–7` verified) |
| Dash | same form as Cruise, same tabulated `cj` (Roskam's method has no separate dash TSFC category at L1) | Roskam Eq. 2.10 |
| Combat | `E = (1/cj)(L/D) ln(W_start/W_end)` → `WF = exp(-t·cj/(L/D))`, with directly-assumed combat-condition `L/D` (no 0.866 correction) | Roskam Eq. 2.12, applied per the method demonstrated in §2.6.3 Example 3: Fighter, "Strafe" phase (corrects prior draft's "Eq. 2.13" mis-citation — see Known Issues #3) |
| Loiter | `E_ltr = (1/cj)_ltr (L/D)_ltr ln(W5/W6)` → `WF = exp(-t·cj/(L/D))` | Roskam Eq. 2.12; Table 2.2 Fighters loiter row |
| Descent | WF = 0.990 | Roskam Table 2.1, Fighters row (corrects prior draft's WF=1.0 placeholder — see Known Issues #5) |
| Landing | WF = 0.995 | Roskam Table 2.1, Fighters row |
| Mission fuel fraction | `Mff = (W1/W_TO) · Π(Wi+1/Wi)` | Roskam Eq. 2.13 |
| Mission fuel weight | `W_F = (1-Mff)·W_TO + W_Fres` | Roskam Eq. 2.14/2.15; reserve term per Design Notes' RFF correction |

### L2 — single-point Breguet with real discipline objects, discretized climb (N=20)

Cruise/Dash/Combat/Loiter: same equation *forms* as L1 (Roskam Eq. 2.10/2.12), but `CD0`/`K1`/`K2`
come from `aero.drag_polar(state)`, `L/D` is computed from the resulting drag polar at the segment's
mid-weight `CL`, and TSFC comes from `prop.get_TSFC(state)` (mil) or `prop.compute_TSFC_AB(state)`
(AB — Dash/Combat) instead of Table 2.2 lookups. This matches the intended L2 behavior described
elsewhere in this subplan, confirmed consistent with the corrected L1 citations above (same Roskam
equations, real inputs).

Climb (user-directed 2026-07-24 — supersedes the original "unchanged fixed-fraction" description
below): **discretized, N=20 sub-intervals**, energy-height integration (`dh_e/dt = (T-D)V/W`,
`dW_fuel/dt = TSFC·T`) — the same integrator L3 uses (`MissionL3.segment_climb`), evaluated at L2's
own N=20 rather than L3's N=40 (`MissionL2.segment_climb` delegates directly). Climb is therefore
**not** a fixed-fraction Roskam Table 2.1 phase at L2 — that description applied only through the
initial implementation pass and was corrected by direct user instruction once the discipline was
built out.

### L3 — sub-segmented Breguet (N=20) + discretized energy-height climb (N=40)

Cruise/Dash/Combat/Loiter: same Roskam Eq. 2.10/2.12 Breguet forms evaluated at N=20 sub-intervals
(`MissionL3.N_SUBSEGMENTS`), weight updated between sub-intervals (captures the cruise-climb L/D
improvement as fuel burns off). Climb: energy-height method (`dh_e/dt = (T-D)V/W`, `dW_fuel/dt =
TSFC·T`, integrated numerically) at its **own, separately-set N=40 sub-intervals**
(`MissionL3.N_SUBSEGMENTS_CLIMB` — user-directed 2026-07-24, double L2's N=20 climb resolution,
decoupled from the N=20 used for Cruise/Dash/Combat/Loiter above), structurally consistent with
Mattingly's Case 1/Case 3 energy-height climb forms (*Aircraft Engine Design*, 2nd ed.,
Eq. 3.17/3.20) — fixing the two legacy bugs identified in Known Issues #7 (altitude-unit conversion,
dropped gravity-variation update), not replacing the method. Climb is modeled at mil power ("Dry")
unconditionally at both L2 and L3 — a deliberate scope simplification (every Climb segment in this
repo's example missions is in fact Dry), not derived from the mission profile's own `dry_or_wet`
flag for Climb the way every other segment type is; flagged as a known limitation if a future
generic mission profile needs an afterburner climb.

### Mattingly-form alternative (available, not required) for L2/L3's per-segment weight fractions

`docs/reference_extracts/mattingly_data.md` (extracted directly from
*Aircraft Engine Design*, 2nd ed., already in `Documents/Readings/`) gives named "Case" formulas
matching each CAP segment type precisely, using the same `alpha`/`theta`/`delta` formalism already
used elsewhere in this framework (`PropulsionBase`, `ConstraintAnalysis`'s Master Equation):
Warm-up (Eq. 3.42), Takeoff rotation (Eq. 3.44), Constant-speed climb (Eq. 3.17), Climb+accel
(Eq. 3.20), Constant-alt/speed cruise (Eq. 3.23, generalized Breguet), Constant-alt/speed turn
(Eq. 3.25 — a more rigorous alternative to the Roskam-derived Combat equation above, if the CAP
Combat segment is ever given an explicit load factor `n`), Subsonic loiter (Eq. 3.37). These are
**not required for this rewrite** (the Roskam-based equations above are sufficient and already
verified), but are flagged here as a citable, already-available upgrade path for a future L2/L3
refinement, since the coefficients (`C1`/`C2` per engine type/power setting) are already
implemented on `F16PropL2`/`F16PropL3`.

---

## F-16 CAP Mission Profile

Source: `temp_Casey/inputs/Mission_Profile.xlsx`, sheet **CAP**.

**Verification status:** independently re-verified cell-by-cell against the live
`Mission_Profile.xlsx` CAP sheet (2026-07-24, coordinator pass, via Python `openpyxl` — see
`VnV/BrandtF16A/todo.md`'s 2026-07-24 "Coordinator pass" entry for the full account). All
segment/altitude/range/time/payload-drop values matched exactly on first read. Takeoff's Mach was
initially confirmed present as `0.87` in the live sheet (a genuine oddity, not a transcription
artifact — flagged as "Finding B" the same day) — **the user subsequently corrected the live source
spreadsheet** (Takeoff 0.87→0.282, Loiter 0.30→0.31, Landing 0→0.3), re-verified against the sheet
again after the edit. The table below reflects the corrected, current live values.

| # | Segment | Alt (ft) | Mach | Range / Time | Payload drop (lbf) |
|---|---------|----------|------|--------------|--------------------|
| 1 | Startup | 0 | 0 | — | 0 |
| 2 | Taxi | 0 | 0 | — | 0 |
| 3 | Takeoff | 0 | 0.282 | — | 0 |
| 4 | Climb | 40,000 | 0.87 | — | 0 |
| 5 | Cruise (outbound) | 40,000 | 0.87 | 1,154,463 ft (~189 nm) | 0 |
| 6 | Dash | 40,000 | 1.60 | 303,806 ft (~50 nm) | 0 |
| 7 | Combat | 25,000 | 0.80 | 2 min | 4,400 |
| 8 | Cruise (return) | 40,000 | 0.87 | 1,458,269 ft (~239 nm) | 0 |
| 9 | Loiter | 10,000 | 0.31 | 20 min | 0 |
| 10 | Landing | 0 | 0.3 | — | 0 |

Fixed payload throughout: 5,100 lbf. Total droppable payload: 4,400 lbf (released at end of
combat). Also confirmed against the live sheet's "Payload, fixed (lbf)"/"Payload, drop (lbf)" rows.

Also present on the live sheet but not part of this table: a `Dry or Wet` row per segment (Dash and
Combat are `Wet`/afterburner; all others `Dry`) — carried into `mission_profile.json` as
`dry_or_wet`, needed by L2/L3 to select `prop.get_TSFC` vs. `prop.compute_TSFC_AB` per segment — and
a `Turns` row (Combat=2, blank elsewhere), not currently used (see subplan's Mattingly-alternative
note above for a possible future use).

---

## Plot Deliverables

1. Waterfall bar chart — fuel burn per segment stacked to total mission fuel.
2. Overlay: run F16MissionL1, F16MissionL2, F16MissionL3 through the same CAP mission — show how
   fuel estimate changes across fidelities (mirrors `run_F16_constraint_diagram_overlay.m`'s
   fidelity-overlay pattern from Step 6).

---

## Tests

### Generic (`tests/mission/TestMissionL1.m`/`L2`/`L3`)
| Test | Expected | Tolerance |
|---|---|---|
| Weight continuity: W at end of segment N = W at start of N+1 | exact | exact |
| WF < 1 for each fuel-burning segment | fuel consumed | exact |
| Total fuel > 0 | positive | exact |
| L1: mock `aero`/`prop` raise an error if called | never called | exact |
| L2/L3: `aero.drag_polar`/`prop.get_TSFC` called once (or N times at L3) per segment | call count | exact |

### F-16 specific (same files, F16MissionL* concrete classes)
| Test | Level | Expected | Tolerance |
|---|---|---|---|
| Total fuel | F16MissionL1 | `W_fuel/W_TO` physically plausible for a fighter CAP mission | physics bounds, wide |
| Total fuel | F16MissionL2/L3 | same range, tighter | narrower bounds |
| `W` after Combat accounts for the 4,400 lbf drop | all | `W_after = W_before - segment_fuel - 4400` | ±1e-6 lbf |
| Fuel total vs. Brandt Miss-tab total (6000.43 lb) | all | **informational only** — see CAP-vs-Brandt section; large deviation expected and acceptable | not pass/fail |

---

## Verification

```matlab
runtests('tests/mission/TestMissionL1.m')
runtests('tests/mission/TestMissionL2.m')
runtests('tests/mission/TestMissionL3.m')
runtests('tests/mission/TestMissionProfileImporter.m')
```
All must pass (Brandt comparison is informational, run separately, never gates this) before Step 8
begins.
