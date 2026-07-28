# VnV/BrandtF16A — todo / discrepancy log

Dated entries logging internal disagreements found within `VnV/BrandtF16A` (docs vs. docs, docs
vs. `.m` code, or docs/code vs. the live `Brandt-F16-A.xls`), or gaps discovered while cross-
checking against the live workbook. Per the project's scribe convention, these are **flagged for
user review, not resolved here** — no code or doc in `VnV/BrandtF16A` has been changed as part of
logging any of these entries.

---

## 2026-07-21 — Geom-tab cell-reference cross-check (Geometry deep-dive, Phase 1)

**Context:** the user supplied four Brandt `Geom`/`Main` sheet cell ranges from their own
reading of the spreadsheet, to be checked against what `VnV/BrandtF16A`'s existing docs
(`readme_geom.md`, `GroundTruth/cell-map.md`) already cite for the same quantities. I opened
`GroundTruth/Brandt-F16-A.xls` directly via MATLAB (`readcell` for values, then `actxserver`
COM automation reading `Range.Formula` for a few cells where the underlying formula mattered —
see the third entry below) and read the live cell contents at every range in question.

### Finding 1 — Lifting-surface S_exposed (`Geom!A5:I10`): user's citation CONFIRMED exact match
Live read of `Geom!A1:K25` shows rows 5–10, columns A–I are exactly the "Exposed Lifting Surf
Geometry" table: header rows 5–6 (`Xexposed`, `Root Chord`, `Tip Chord`, `Span`, `Root Chord`
(exposed), `Half Span`, `Exposed S`, units), data rows 7–10 for Wing / Pitch Control Surface /
Strake / Vertical Tail. This matches the user's `A5:I10` citation precisely. No existing
`VnV/BrandtF16A` doc contradicts this range (neither `readme_geom.md` nor `cell-map.md` cites a
conflicting range for this table).

### Finding 2 — Lifting-surface S_wet (`Geom!A11:C17`): user's citation CONFIRMED exact match
Live read shows: `A11`="Exposed Lifting Surface Swet" (section header), `A12`="Swet of lifting
surfaces:" (sub-header), `A13` blank/plot-related, then data rows 14–17 with component name in
column A, value in column B, unit ("sq ft") in column C: `A14`/`B14`="Exposed Wing Wetted
Area"/392.0204, `A15`/`B15`="Strake Wetted Area"/39.956, `A16`/`B16`="Exposed Pitch Trim Surface
Wetted Area"/99.5848, `A17`/`B17`="Exposed Vertical Tail Wetted Area"/81.6894. This matches the
user's `A11:C17` citation precisely (it is the full labeled table: names + values + units).

`readme_geom.md`'s cross-tab dependency table (line 58) separately cites just the value column,
`B14–B17`, for "Lifting surface S_wet" — a narrower slice of the same table the user's `A11:C17`
spans, not a conflicting range. `BrandtGeometry.m` (lines 20-23, 116, 960, 975, 982) and
`tests/test_BrandtGeometry.m` (lines 27-52) also cite `B14`/`B15`/`B16`/`B17` individually for
wing/strake/pitch/VT respectively — all consistent with the live values above.

**Correction to the task framing this check was run under:** I was told
`VnV/BrandtF16A/GroundTruth/cell-map.md` cites `Geom!B14-B17` for lifting-surface S_wet. I
grepped `cell-map.md` directly for "B14" through "B17" and found **no match** — `cell-map.md`
does not independently cite this range at all (it cites `B19` whole-aircraft total, `D23`
high-fi fuselage, `K21` strake-chine term, `H26:H45` per-frame areas, `H47` Amax, `F26`
frame-20 width — but leaves the individual `B14–B17` component breakdown undocumented). The
actual source of the `B14-B17` citation is `readme_geom.md` and the `.m`/test files, not
`cell-map.md`. Not a contradiction — just correcting which file actually contains the citation,
since `cell-map.md` has a documentation gap here (it doesn't cite the individual component S_wet
cells at all) rather than a wrong citation.

### Finding 3 — Fuselage S_wet: user's citation (`Geom!A3, A4`) does NOT match — flagging, not resolving
Live read of `Geom!A1:K25`:
```
A3 = "Fuselage"                        B3 = 730.422   C3 = "1/3 Cone and 2/3 Cylinder approximation"
A4 = "Exposed Engine Nacelles"         B4 = 41.515    C4 = "Full Cylinder approximation"
...
A23 = (blank)   B23 = "More Accurate Fuselage Swet"   D23 = 676.3289
```
So: `A3`/`A4` are **label cells** (column A holds descriptive text throughout this sheet,
values live in column B onward) — and critically, `A4`'s label is **"Exposed Engine
Nacelles,"** not a second fuselage-S_wet number. The two actual fuselage S_wet values are at
`B3` (low-fidelity, "1/3-cone + 2/3-cylinder" approximation, 730.422 ft²) and `D23`
(high-fidelity frame-integration, 676.3289 ft²) — **exactly what `readme_geom.md`,
`GroundTruth/cell-map.md`, `baseline/extract_brandt.m`, and `BrandtGeometry.m` all already,
consistently, cite** (`extract_brandt.m:76,83`: `get("Geom","B3")` → `fus_simple`,
`get("Geom","D23")` → `fus_accurate`; `cell-map.md:26`: `Geom!D23` = high-fidelity fuselage
S_wet; `readme_geom.md` §4.1: "Low fidelity — Geom B3", "High fidelity — Geom D23").

**Net result:** the four pre-existing `VnV/BrandtF16A` sources (`readme_geom.md`, `cell-map.md`,
`extract_brandt.m`, `BrandtGeometry.m`) agree with each other and with the live workbook on
where fuselage S_wet lives (`B3`/`D23`). The user's `A3, A4` pair does not correspond to two
fuselage-S_wet values in the live file — `A3` is the label immediately preceding the correct
low-fi value (`B3`), and `A4` is the label for a *different* quantity (nacelle S_wet, `B4`), not
a second fuselage number. **Flagging for the user to review and reconcile** — not picking a
side per the scribe rule. Possible explanations I am not adjudicating between: the user may
have been reading the label column rather than the value column when noting cell references, or
may have intended to flag a genuinely different concern this check didn't surface.

**RESOLVED (2026-07-21, user decision):** confirmed — use `Geom!B3` (low-fi, 730.422) /
`Geom!D23` (high-fi, 676.3289), matching all four pre-existing `VnV/BrandtF16A` sources. This is
the ground truth the Geometry deep-dive's comparison report and any new fuselage-S_wet toolbox
methods (`compute_s_wet_fus_brandt_lowfi`, etc.) should target.

### Finding 4 — Main-tab raw-input ranges: user's citations CONFIRMED exact match
Live read of `Main!A16:H32` confirms both ranges exactly as the user described:
- `A16:H27` — the lifting-surface geometry input block (Wing / Pitch Control Surface /
  Strakes-Chines / Ailerons-Elevons / Leading-Edge Flaps / Trailing-Edge Flaps / Vertical
  Surface columns; S, Aspect Ratio, Taper Ratio, Sweep, NACA 4-digit, X/Y/Z Location, Dihedral,
  TE Sweep rows).
- `A31:D32` — the fuselage summary block (`A31`="Fuselage:", `B31`="Length", `C31`="Max
  Width", `D31`="Max Height"; `B32`=46.5, `C32`=7, `D32`=5).

No existing `VnV/BrandtF16A` doc disagrees with either range.

### Finding 5 (secondary, found while chasing Main-tab `_calc` fields for the same task) — `BrandtGeometry.m` understates what's recoverable from the live workbook
While documenting the aileron/LE-flap/TE-flap "calculated, not given" fields flagged in
`GroundTruth/f16a_geometry.json` (`_calc` notes on the `le_flap` and `te_flap` blocks), I pulled
the live Excel cell **formulas** (not just values) via `actxserver`/`Range.Formula` for
`Main!E20/E21/E23` (aileron taper/sweep/x_le), `Main!F18/F19/F23` (LE-flap S/AR/x_le), and
`Main!G20/G21/G23` (TE-flap taper/sweep/x_le). Full formula chain documented in
`src/disciplines/geometry/GeomL2.md`'s Task-2 section. Headline finding:

- `BrandtGeometry.m:829`'s own comment states: *"Note: S and AR formulas are not visible in the
  binary .xls; GT values used"* (for `le_flap.S_ft2`/`le_flap.AR`, hardcoded as `21.314`/`12.410`).
- Live COM inspection shows these formulas **are** recoverable:
  `Main!F18 = Geom!D7/2*(Geom!E7/2-Main!F24)`, `Main!F19 = (Geom!E7-Main!C32)^2/Main!F18/2` —
  both evaluate exactly to the hardcoded GT values (21.3136, 12.4099).
- Similarly, `BrandtGeometry.m:794-799`'s aileron taper/sweep are documented as an
  *approximation* ("matches Excel to within ~5%"), when the live formula shows the aileron's
  computed fields are actually **defined as literally equal to** the TE-flap's
  (`Main!E20=G20`, `E21=G21`, `E23=G23`) — not independently derived at all in the live
  workbook, and `Main!G20` (TE-flap taper) is itself just a bare hardcoded ratio `1.25/2.33` in
  the live formula, not a geometric computation.

This is not a numeric disagreement (the hardcoded GT values `BrandtGeometry.m` uses do match the
live formula's output for `le_flap`), so it doesn't change any test result. Flagging because it
means `VnV/BrandtF16A`'s own documentation of what's "not visible in the binary .xls" is
inaccurate for at least the `le_flap` S/AR case, and because the aileron's true formula
(`=G20`/`=G21`/`=G23`, i.e. "same as TE-flap, no independent derivation") is a simpler and more
precise fact than the ~5%-accuracy approximation currently documented — worth using the exact
formula if a later phase re-derives these fields to match Excel bit-for-bit.

---

## 2026-07-28 — Tail Sizing deep-dive (scribe phase)

**Context:** promoting the standalone `TailSizingLevel1`/`F16TailSizingLevel1` volume-coefficient
helper into a full three-tier discipline (`TailSizingBase`/`TailSizingModelL{1,2,3}`/`TailL{1,2,3}`/
`F16TailL{1,2,3}`), per coordinator instruction. Full writeup, tables, and equation-level detail for
all three findings below live in `src/disciplines/tail_sizing/TailSizing_scribe_plan.md` (§§2, 5.1,
6, 7). Per the standing scribe rule, none of the three were resolved unilaterally at write-time —
logged for user review. **UPDATE (2026-07-28, same day):** the user has since reviewed and decided
Findings 2 and 3; status lines added to each below. Finding 1 remains open (out of scope for this
deep-dive to fix). See `TailSizing_scribe_plan.md` §§2, 5.1, 6, 7, 8 for the full decision record.

### Finding 1 — Nicolai & Carichner F-16 tail-volume-coefficient value: propagation error across three `temp_AI` reference-extract files
`temp_AI/docs/disciplines/reference_extracts/nicolai_data.md`,
`temp_AI/docs/disciplines/reference_extracts/roskam_vol2_data.md`, and
`temp_AI/docs/disciplines/reference_extracts/usaf_f16_data.md` all state the F-16's row in Nicolai &
Carichner's Table 11.6 ("Tail Volume Coefficients for Fighter Aircraft") as `C_HT=0.68, C_VT=0.041`
(`roskam_vol2_data.md` and `usaf_f16_data.md` both cite `nicolai_data.md` as their source for this
pair, so the error appears to originate in that one file and propagate outward).

The properly page-cited, "done"-status chapter extract itself —
`temp_AI/docs/disciplines/reference_extracts/11_tail_sizing.md` §"Table 11.6 — Tail Volume
Coefficients for Fighter Aircraft" (*[Nicolai & Carichner, Table 11.6, p. 289]*) — reproduces the
full table, and its "General Dynamics F-16" row reads `C_HT=0.3, C_VT=0.094`. **No row anywhere in
the fully reproduced Table 11.6 matches `0.68`/`0.041`** — I checked every row (Convair F-106,
Grumman A-6A/F-14A, North American F-86/F-100, Northrop F-5E, McDonnell Douglas F-4E/F-15, General
Dynamics F-111A/FB-111/**F-16**, Cessna A-37B, MIG-21/23/25, SU-7, Viggen) against both numbers; none
is `0.68`/`0.041`.

**Why it matters now:** the tail-sizing deep-dive's L2 tier plan (`TailSizing_scribe_plan.md` §5.1,
Option B) proposes using an F-16-*specific* Nicolai coefficient (rather than the generic Raymer
"jet fighter" category row) as one citable option for the L2 "historical sizing estimate" method.
Whichever of the two conflicting numbers gets used would silently determine that method's output —
`S_HT`/`S_VT` scale directly with `C_HT`/`C_VT` — so the discrepancy must be resolved by the user
before Option B (if chosen) is implemented, not guessed at.

**Not resolved here** — not picking a side per the scribe rule, though I note for the record that
`11_tail_sizing.md` is the page-cited, fully-reproduced primary extract and `nicolai_data.md` is a
secondary "data digest" restatement, which is at least suggestive of which is more likely to be
the transcription error.

**STATUS (2026-07-28, user decision): OPEN / unresolved elsewhere — out of scope for this
deep-dive.** The user confirmed use of the page-cited `11_tail_sizing.md` value (`C_HT=0.3,
C_VT=0.094`) for the tail-sizing L2 method (`TailSizing_scribe_plan.md` §5.1) and explicitly declined
to fix the transcription error in `nicolai_data.md`/`roskam_vol2_data.md`/`usaf_f16_data.md` as part
of this work — those three files still carry the incorrect `0.68`/`0.041` figure and remain a
standing (but now bounded and documented) trap for a future reader of those specific files.

### Finding 2 — Competing, disagreeing L1 tail-sizing implementations already exist within `src/`
`src/disciplines/tail_sizing/TailSizingLevel1.m` (the live class, actually wired into
`SizingLoopL2`/`design_study_02_L2.m`/`design_study_03_L3.m` and this deep-dive's migration target)
disagrees with a second, **orphaned** tail-volume-coefficient implementation already sitting in
`src/disciplines/geometry/GeomL1.m` (`compute_tail_volume_coeffs`, `compute_tail_arm`,
`compute_S_HT`, `compute_S_VT`, documented in `src/disciplines/geometry/GeomL1.md` §§2–4 and unit-
tested directly in `tests/disciplines/TestGeomL1.m`, added "Task 2 (2026-07-22)"). Grepped the whole
repo: `GeomL1`'s tail-volume methods are called by nothing except its own test file and doc — not by
`F16GeomL1.m`, not by `TailSizingLevel1`/`F16TailSizingLevel1`, not by `SizingLoopL2`. Dead code
relative to the actual call path, but real, cited, and tested.

Disagreements:
- **Raymer edition:** `TailSizingLevel1` cites 6th ed.; `GeomL1` cites 7th ed. (same Table 6.4,
  same base jet-fighter values 0.40/0.07).
- **Tail arm:** `TailSizingLevel1` uses `0.5*L_fus` ("the textbook value for THIS [aft-mounted-
  engine] configuration," from a stated 45–50% range); `GeomL1` uses `0.475*L_fus` ("midpoint of the
  stated 0.45–0.50% range" — the *same* stated range, different representative number picked from
  it).
- **RSS / all-moving-tail text corrections:** entirely absent from `TailSizingLevel1`; present in
  `GeomL1.compute_tail_volume_coeffs` (`c_HT,c_VT *= (1-0.10)` if relaxed static stability; `c_HT *=
  (1-0.125)` if all-moving stabilator). The F-16 has *both* properties, so `GeomL1`'s own worked
  example gives F-16 net values `c_HT=0.315, c_VT=0.063` — nowhere reflected in the class actually in
  use, which applies neither correction.
- A third data point, not part of `VnV/BrandtF16A` but corroborating that this citation is
  unsettled: `temp_Casey/src/Level_{II,III}_Fidelity/Weight_Estimation/Tail_Sizing.m` (same Eq.
  6.28/6.29 numbers) is commented "eq 6.28, **2nd edition**" and uses tail arm `0.8*L_fus` — a third
  edition claim and a third arm fraction.

**Why it matters now:** the coordinator must pick ONE canonical set of L1 tail-sizing constants
before `TailL1`/`TailSizingModelL1` are written (see `TailSizing_scribe_plan.md` §2's numbered
decision list), and decide what becomes of the orphaned `GeomL1` code (retire it, or fold it into
the new `TailL1` toolbox) — leaving a second, disagreeing, tested implementation sitting unused in
the geometry toolbox after this deep-dive ships would be a standing landmine for the next engineer
who greps for "tail volume."

**RESOLVED (2026-07-28, user decision):** adopt `GeomL1`'s corrected set as the canonical L1
tail-sizing content — `c_HT=0.315`, `c_VT=0.063` (Raymer 7th ed. Table 6.4 base 0.40/0.07 with RSS
×(1−10%) and all-moving-tail ×(1−12.5%) corrections applied, both properties true of the F-16), tail
arm `L_HT=L_VT=0.475*L_fus`, Raymer 7th ed. cited going forward (not 6th). `GeomL1.m`'s orphaned
`compute_tail_volume_coeffs`/`lookup_tail_volume_coeffs`/`compute_tail_arm`/`compute_S_HT`/
`compute_S_VT` are retired (deleted from `GeomL1.m`/`GeomL1.md`/`TestGeomL1.m`) and their logic is
ported into the new `TailL1` toolbox — exactly one implementation survives.
`TailSizingLevel1.m`/`F16TailSizingLevel1.m`'s live 0.40/0.07/`0.5*L_fus`/6th-ed. values are updated
to match during the migration into `TailL1`/`F16TailL1`. Full record and consequences (this widens,
not narrows, the existing gap vs. Brandt's `S_ht=108`/`S_vt=60` — an accepted, expected consequence,
not a new problem) in `TailSizing_scribe_plan.md` §2.

### Finding 3 — Raymer Ch. 16 (stability-and-control-based tail sizing, the planned L3 tier) has no verifiable equation numbers anywhere in this repository
Checked, per Rule 7, every in-repo source before flagging this as an internet-required gap:
- `temp_AI/docs/disciplines/reference_extracts/` is entirely **Nicolai & Carichner**, not Raymer (see
  that folder's own `00_README.md`). Its Chapter 11 (`11_tail_sizing.md`, "done") covers only the
  volume-coefficient method and explicitly defers criteria-based tail sizing to *its own* Chapter 21
  ("Static Stability and Control") and Chapter 23 ("Control Surface Sizing Criteria") — both listed
  **"pending"** (not yet extracted) in the same README's progress table.
- `temp_AI/docs/disciplines/reference_extracts/raymer_data.md` (the actual Raymer OCR extract) covers
  only Ch. 10, 12, and 15 — no Ch. 4, 6, or 16 content exists in it at all.
- `temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m` (read-only reference, documented bugs per
  CLAUDE.md) cites `"Raymer 6th ed, eq 16.25"` (a fuselage `C_mα` moment term) and `"fig 16.3"`/
  `"fig 16.16"` — unverified against the actual book by anything in this repo, and in any case a
  forward analysis (`C_mα`/neutral point *given* a fixed tail area), not the inverse "solve for
  `S_HT`" this task needs.
- `VnV/BrandtF16A/BrandtBalanceStabControl.m` — this project's own ground-truth balance/stability
  tool — is likewise a forward analysis only (neutral point, CG, static margin, gear metrics *given*
  Brandt's fixed `S_ht=108`/`S_vt=60`), not a tail-sizing tool, and is not wired to this framework's
  own `F16WeightsL2/L3`.

**Why it matters now:** the tail-sizing deep-dive's L3 tier is explicitly scoped as "Raymer Chapter
16 stability-and-control-based tail sizing." No equation in that chapter can currently be given a
citable number from anything in this repository. Full detail, the conceptual (uncited-per-number)
structure of what would be needed, and the new-input gaps this would create in
`f16a_requirements.json` are in `TailSizing_scribe_plan.md` §6.

**RESOLVED-DEFERRED (2026-07-28, user decision):** proceed now with the first of the three flagged
paths forward — ship `F16TailL3`/`TailL3`/`TailSizingModelL3` as a documented-TODO /
deliberately-failing-test structure (CLAUDE.md's explicitly allowed citation-gap exception, matching
the convention already used by `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`) — rather
than blocking on Raymer Ch. 16 page access or investing in a Nicolai Ch. 21/23 extraction effort. The
conceptual contract (HT sizing via static margin, VT sizing via a `C_nβ` target, VT sizing via
crosswind landing; one-engine-out explicitly skipped as inapplicable to the F-16's single engine) is
documented as design intent in `TailSizing_scribe_plan.md` §6, but the equation bodies themselves
remain TODO. New `f16a_requirements.json` fields (CG range, `SM_required`, `C_nβ,required`, crosswind
condition) and the new `TailL3`-injects-`aero` DI pattern these equations would eventually need are
**explicitly deferred, not added now** — `io` should not invent placeholder requirement values for a
citation that does not exist yet. Full record in `TailSizing_scribe_plan.md` §6.

---

*No entries resolved. Add new dated sections above this line for future discrepancies; do not
edit or remove prior entries.*
