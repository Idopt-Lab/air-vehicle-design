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

## 2026-07-22 — Aerodynamics deep-dive, Phase A (documentation)

**Context:** Phase-A documentation pass for the Aerodynamics deep-dive (mirrors the Geometry
deep-dive). Cross-checked the live aero code (`src/base/AerodynamicsBase.m`, the `AeroL{1,2,3}` /
`AeroModelL{1,2,3}` toolboxes/enforcers, `examples/F16A/F16AeroL{1,2,3}.m`), the ground truth
(`readme_aero.md`, `GroundTruth/cell-map.md`, `Brandt-F16-A.xls` Aero/Miss tabs), the reference
extracts, and `baseline/F16Baseline.m`. Entries below are **flagged for user review, not resolved**.

### Finding A — K1/K2 label convention: code+Mattingly+Brandt (Convention A) vs. stale docs (Convention B)
Two competing labelings of the quadratic drag polar exist across the repo:
- **Convention A (settled, live):** `CD = CD0 + K1·CL² + K2·CL`, K1 = quadratic/induced, K2 =
  linear/camber. Used by `AerodynamicsBase.compute_CD` (`CD0 + K1*CL^2 + K2*CL`), the `AeroL*`
  toolboxes (`K1 = 1/(πARe)`, `K2 = −2·K1·CL_minD`), `src/constraints/ThrustConstraint.m`,
  **Mattingly AED 2nd ed. Eq. 2.9**, and **Brandt** (`readme_aero.md`: `CD = CD0 + k1·CL² + k2·CL`;
  Aero!G17 `k2 = −2·k1·CL0`; Miss tab).
- **Convention B (stale, swapped):** K1 = linear/camber, K2 = induced. Appears in
  `temp_AI/docs/disciplines/01_aerodynamics.md` (`CD = CD0 + K1·CL + K2·CL²`) and (before this pass)
  `docs/subplans/03_aerodynamics.md` (`K2 = 1/(πARe)`, `K1 = −2·K2·CL_minD`).
`docs/subplans/03_aerodynamics.md` was corrected to Convention A in this pass;
`temp_AI/docs/disciplines/01_aerodynamics.md` is **read-only and left as-is** — flagged stale here so
no future reader treats it as authoritative. Not a VnV-internal disagreement (Brandt itself is
Convention A, consistent with the code); logged because the stale docs contradict the ground truth.

### Finding B — Mattingly Fig. 2.10 / Fig. 2.11 not in the repo → target-L1 uses a placeholder
The approved target **L1** (aircraft-type-only Mattingly drag polar) needs `CD0(M)` from Mattingly
Fig. 2.10 and `K1(M)` from Fig. 2.11, F-16 "Current" curve. **Neither figure is in the repo.** Only
`temp_AI/docs/disciplines/reference_extracts/mattingly_data.md` (PART 9) is available: Eq. 2.9, the
fighter-`K2=0` rule (§2.3.1), coarse ranges (subsonic CD0≈0.014–0.020 / K1≈0.15–0.20; supersonic
CD0≈0.025–0.040 / K1≈0.20–0.50), and 5 AAF worked-example points [M, K1, CD0]: (0.9, 0.18, 0.016),
(1.5, 0.27, 0.028), (1.6, 0.288, 0.028), (1.8, 0.324, 0.028). Target L1 must seed a **placeholder**
curve from these, marked TODO, until the actual Fig. 2.10/2.11 F-16 curves are transcribed. Flagging
the source gap for the user; not fabricating a curve.

### Finding C — cargo/passenger L1 type-curves (K2≠0) not available (TODO)
Target L1 sets `K2 = 0` for fighters (Mattingly §2.3.1, uncambered). Cargo/passenger types keep
`K2 ≠ 0` (`K2 = −2·K″·CL_min`, Eq. 2.9), but no Fig. 2.10/2.11 equivalents for those types are in
the repo either. Logged as a TODO scope boundary — the F-16 work does not need it, but a generic L1
does.

### Finding D — `F16Baseline.m` aero fields used as a "comparison column" are Brandt-model echoes, not independent T.O. data
The Aero deep-dive plans to keep an F16Baseline-derived comparison column. Several of its aero
fields are **Brandt's own model outputs**, not independent authoritative data, and should be
labeled as such so they are not mistaken for a second ground-truth source:
- `b.brandt.polar_model` (`[Brandt Aero A6:E10]`) — Brandt's *predicted* Mach-swept polar (his
  Cfe·Swet/Sref + linear-theory K1), i.e. the same method the framework is being compared against,
  not measured data. (Brandt's *actual/flight-measured* polar is the separate `b.brandt.polar_actual`,
  Aero!M6:Q10 — that one IS reference data.)
- `b.brandt.Mcrit = 0.8727` (`[Brandt L4]` / Aero!A12) — computed by Brandt's own
  `1−0.065·(cos Λ_LE·tc%)^0.6` formula, not a T.O. number.
- `b.brandt.CL_alpha = 0.0615` /deg (`[Brandt L7]` / Aero!A32) and `CL_alpha_wing = 0.054312·57.3`
  (Aero!A15) — Brandt's Helmbold-formula outputs (`CLα = 0.1/(1+5.73/(πeAR))`), used verbatim as the
  "expected" in `TestAeroL2.testCLalphaAtMachZero/06`. This is a **self-referential-test risk** (the
  exact failure mode the scribe convention warns against): the L2 test's expected value is a Brandt
  *model* output, not a hand-derivation or independent datum. Flagging for the user to decide whether
  these belong in a comparison column or should be labeled "Brandt-model, not independent."

### Finding E — `F16Baseline.m` Consts-sheet CD0/K1/K2 provenance caveat (column letters unconfirmed)
`baseline/F16Baseline.m` (lines ~305–313) states the per-condition `b.constraints.*.CD0/K1/K2`
values were read from "the CDo/k1/k2 columns immediately following theta/theta0/delta/delta0 —
**exact column letters not confirmed from the source screenshot**, unlike the AI–AL/AS/AT/AU columns
above." So these drag-polar coefficients (consumed by `TestAeroL1/L2/L3.testDragPolarAtConstraint
Conditions` as Brandt references) rest on an **unverified cell mapping** in the live `Brandt-F16-A.xls`
Consts sheet. `GroundTruth/cell-map.md` does document `Consts!AM23 = CD0+CDx = 0.016996` and
`Consts!AN23 = K1 = 0.1160` for the max_mach row, but does not map the CD0/K1/K2 columns for the
other condition rows (cruise/combat/max_alt/ps/combat_sup). Recommend confirming the Consts CD0/K1/K2
column letters directly against the live workbook (COM/`actxserver`, as in prior findings) before
relying on these as a comparison column. Flagged, not resolved.

---

*No entries resolved. Add new dated sections above this line for future discrepancies; do not
edit or remove prior entries.*
