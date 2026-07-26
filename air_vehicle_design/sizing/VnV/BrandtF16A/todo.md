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

## 2026-07-24 — Propulsion deep-dive, Phase A (documentation)

**Context:** Phase-A documentation pass for the Propulsion deep-dive (mirrors the Geometry and
Aerodynamics deep-dives). Cross-checked the live propulsion code (`src/base/PropulsionBase.m`, the
`PropL{1,2}` / `PropulsionModelL{1,2}` toolboxes/enforcers, `examples/F16A/F16Prop{L1,L2}.m`), the
existing tests (`tests/disciplines/TestProp{L1,L2}.m` — read for citations only, NOT for expected
values, per the anti-self-referential rule), the ground truth (`readme_prop.md`, `BrandtEngine.m`,
`GroundTruth/cell-map.md` Engn(s)/Consts rows, `readme_consts.md`, `readme_mission.md`, `README.md`),
the reference extracts (`temp_AI/docs/disciplines/reference_extracts/{mattingly,metabook,raymer}_data.md`),
and `baseline/F16Baseline.m`. I did **not** open the live `Brandt-F16-A.xls` (documentation-only
pass). Three items carry a **user decision dated 2026-07-24**; the rest are flagged/deferred.

### Entry 1 — L1 density-lapse α = σ^m: 3-way citation split — RESOLVED (user, 2026-07-24)
The single formula α = σ^m (σ = ρ/ρ_SL) is cited three inconsistent ways:
- `src/disciplines/propulsion/PropL1.m:21` (also :40, :64-65, :73-74):
  *"Source: J.R.R.A. Martins, AE481 course notes (metabook), Eqs. 10.7 / 10.9"*
- `examples/F16A/F16PropL1.m:8-9`: *"[Martins AE481 course notes (metabook), Eq. 10.9]"*
- `src/disciplines/propulsion/PropulsionModelL1.m:8-9` (also :20-22): *"thrust_lapse — density-ratio
  power law: α = σ^0.6   [Raymer 6th §5.4]"*
- `tests/disciplines/TestPropL1.m:201`: *"expected_SL = 1.0; % σ=1 at SLS regardless of Mach
  [Raymer §5.4]"*
- `docs/subplans/04_propulsion.md:74`: *"α (thrust lapse) | (ρ / ρ_SL)^0.6 | Raymer 6th ed, Ch 3"*
The repo Martins extract (`metabook_data.md`) confirms Eq. 10.7 (turbojet, m=1.0) and Eq. 10.9
(turbofan, general m; the specific m=0.6 is the Ch. 4 approximation, `metabook_data.md` line 226). No
Raymer §5.4 extract exists in the repo (`raymer_data.md` covers Ch. 10/12/15 only) → the "Raymer §5.4"
/ "Raymer Ch 3" citation is unverifiable AND conflicts with the verified Martins citation.
**RESOLVED (user, 2026-07-24):** use **Martins metabook Eq. 10.9** as the source for α = σ^m. The
`PropulsionModelL1.m` / `TestPropL1.m` "Raymer §5.4" and subplan "Raymer Ch 3" citations are to be
corrected to Martins in the implementation step (Step 1c). No `.m`/`.json` files were edited in this
documentation pass.

### Entry 2 — Subplan TSFC units drift (/3600 → 1/s) vs. code (1/hr throughout) — RESOLVED (user, 2026-07-24)
`docs/subplans/04_propulsion.md` states TSFC is converted to 1/s:
- `:72-73`: *"low-BPR mixed turbofan: 0.8/hr → /3600 → 1/s"*, *"0.7/hr → /3600"*
- `:79-80`: *"(0.9 + 0.30 × M) × sqrt(θ) [1/hr → /3600]"*, *"(1.6 + 0.27 × M) × sqrt(θ) [1/hr → /3600]"*
The code keeps TSFC in **1/hr** everywhere, with no /3600: `PropL1.lookup_TSFC_table`/`get_TSFC`
(0.80/0.70), `PropL2.TSFC_mil`/`TSFC_AB`, and `PropulsionBase.m:11` (*"TSFC in
lbf_fuel/(hr·lbf_thrust) [1/hr]"*). The subplan misstates the as-built unit.
**RESOLVED (user, 2026-07-24):** use **1/hr** for TSFC throughout — the code's 1/hr is correct; the
subplan's `/3600 → 1/s` statements are wrong and will be corrected to 1/hr in the docs-cleanup step
(1d, `docs/subplans/04_propulsion.md`). No `.m` change needed (code is already 1/hr).

### Entry 3 — Raymer engine-diameter coeffs 0.033 (Eq. 10.6) / 0.024 (Eq. 10.12): OCR-vs-book — RESOLVED (user, 2026-07-24)
`src/disciplines/propulsion/PropL2.m:182-183` (`engine_diam_nonAB`) uses 0.033 and `:224-225`
(`engine_diam_AB`) uses 0.024, each with an in-code comment *"[OCR coefficient verify: book p. 284;
metric check suggests ~0.034 / ~0.0256]"*. The repo Raymer extract (`raymer_data.md:27,33,40,46`)
carries the identical OCR values (0.033/0.024) and the identical caveat ("metric cross-check suggests
~0.034 / ~0.0256; verify on book p.284"). So the code faithfully matches the extract's OCR value —
the unresolved conflict is **OCR-value vs. metric-cross-check within the extract itself**, and the
physical Raymer 6th ed. p.284 is not in the repo. If the metric value is correct, the diameters are
off by ~3% (nonAB) / ~6% (AB).
**RESOLVED (user, 2026-07-24):** the coefficients **0.033 (Eq. 10.6, nonafterburning) and 0.024
(Eq. 10.12, afterburning) are CORRECT for imperial units** and give the diameter in **ft** — the
"metric check suggests ~0.034 / ~0.0256" note is wrong and is to be REMOVED from `PropL2.m`
(`engine_diam_nonAB` :182-183, `engine_diam_AB` :224-225) in the implementation step (1c). User cites
**Raymer 7th ed.** for these equation numbers; the surrounding §10.3.2 sizing block is currently
labeled "Raymer 6th ed." in code/docs, so the edition label will be unified (6th→7th where the user's
7th-ed numbering applies) as part of the 1c/1d citation cleanup.

### Entry 4 — Installed TSFC 1.08 factor: doc-vs-doc conflict on double-application — RESOLVED (user, 2026-07-24)
The 1.08 factor lives at **Miss!C25 = Main!C25** (NOT an Engn! cell — a prior task framing assumed
Engn!); stored in `GroundTruth/f16a_geometry.json:152` as `engine.TSFC_install_factor = 1.08`.
Whether the stored SLS TSFCs 0.70 (mil) / 2.20 (AB) already include it is documented two contradictory
ways:
- **Already-installed camp:** `GroundTruth/cell-map.md:190` (*"the stored values (0.70, 2.20 hr⁻¹)
  already include the 1.08× correction factor"*); `BrandtEngine.m:24-25` (0.70/2.20 marked
  *"installed, calibrated at M=0 / M=0.4"*, and `thrust_dry`/`thrust_AB` apply NO further ×1.08);
  `readme_prop.md:99-113` (SLS recovers 0.70/2.20 exactly, no 1.08 in the formula).
- **Multiply-on-top camp:** `README.md:40` (*"Installed TSFC: uninstalled × 1.08"*), `README.md:25`;
  `readme_mission.md:174-178,188`; `BrandtMission.m:366,372-375` (`tsfc_old_` = 1.08 · TSFC_sl_dry ·
  (1+0.35|M|) · √θ → 0.756 at SLS). Both cannot hold.
**RESOLVED (user, 2026-07-24):** trust cell-map / `BrandtEngine.m` / `readme_prop.md` — the stored
0.70/2.20 **are installed** (already include 1.08); **do not double-apply.** The Brandt "expected"
TSFC comparison column uses installed 0.70/2.20. `PropL2`'s Mattingly TSFC is uninstalled, so the
planned wiring is `TSFC_installed = TSFC_uninstalled × 1.08` (factor from Miss!C25) — not yet applied
in `F16PropL2` (implementation step). No files edited in this pass.

### Entry 5 — Mattingly TSFC coefficients: VERIFIED AGREEMENT (logged for record, no conflict)
`examples/F16A/F16PropL2.m:29-32` `C1_mil=0.90, C2_mil=0.30, C1_AB=1.60, C2_AB=0.27` match
`mattingly_data.md` Eq. 3.55a (0.9/0.30) and Eq. 3.55b (1.6/0.27), low-BPR mixed turbofan, exactly.
Thrust-lapse Eq. 2.54a/b, TR Eq. D.6, and `T_t4_max = 2566 °F` (Table C.4, F100-PW-100) also match the
extract. No discrepancy — recorded so a future reader need not re-verify.

### Entry A — Consts α column semantics (AT vs AU) — DEFERRED (user, 2026-07-24) → RESOLVED (live-xls read, 2026-07-24)
`cell-map.md:208` maps `Consts!AU23 = α = thrust lapse = eng.run(alt, M, %AB/100).alpha_AB_ref`
(max_mach = 100% AB → AB lapse on the T_SL_AB basis). But `tests/disciplines/TestPropL2.m` and
`baseline/F16Baseline.m` treat `Consts!AT{23-28}` = α_AB and `Consts!AU{23-28}` = α_mil renormalized
to the AB basis (e.g. dash: AT23 = 0.5770 = α_AB, AU23 = 0.1882 = α_mil_T_AB). So cell-map places the
AB-lapse value at AU, whereas the test/baseline place α_AB at AT and a *different* (dry) value at AU.
Cross-references the existing 2026-07-22 Aero Finding E (F16Baseline Consts column letters "not
confirmed from the source screenshot"). **DEFERRED (user, 2026-07-24):** pin the per-condition α
numbers and the correct AT/AU column semantics via a live `Brandt-F16-A.xls` COM read next pass — not
resolved here, and no unverified per-condition α "expected" values were placed in
`docs/propulsion_parameter_usage.md` (those rows are marked "pending live-xls read").

**RESOLVED (live-xls read, 2026-07-24):** opened `GroundTruth/Brandt-F16-A.xls` via Excel COM
(`actxserver`, read-only) and read the Consts sheet headers + rows 23–28 `.Value` and `.Formula`.
Verified semantics from the live formulas:
- **Consts!AS{23-28} = α_dry** (dry/mil lapse, δ₀ basis, → T_SL_dry). Live formula:
  `=IF(AJ<='Engn(s)'!$S$1, AL·(1−'Engn(s)'!$D$4·D^'Engn(s)'!$F$4), AL·(1−'Engn(s)'!$L$4·D^'Engn(s)'!$O$4−'Engn(s)'!$R$4·(AJ−$S$1)/AJ))`
  — uses the **dry** coefficients on Engn(s) **row 4** (AL=δ₀, AJ=θ₀, D=Mach).
- **Consts!AT{23-28} = α_AB** (AB lapse, δ₀ basis, → T_SL_AB). Same IF form referencing Engn(s)
  **row 15** (D15/F15/L15/O15/R15) — the AB coefficients.
- **Consts!AU{23-28} = effective lapse on the T_SL_AB axis** (= `alpha_AB_ref`). Live formula:
  `=(AS·Main!C$29 + F/100·(AT·Main!D$29 − AS·Main!C$29))/Main!D$29`, Main!C29=T_dry=15000,
  Main!D29=T_AB=23770, F=%AB. For 100%-AB rows AU = AT; for the 0%-AB cruise row AU = AS·(T_dry/T_AB).

So `cell-map.md:208` (AU = α thrust lapse = `alpha_AB_ref`) is **CORRECT**. `F16Baseline.m` /
`TestPropL2.m` are correct that **AT = α_AB**, but their **"Consts AU{23-28} = alpha_mil_T_AB" cell
citation is WRONG**: the value they use (e.g. dash 0.1882) is AS·(T_dry/T_AB) = α_dry renormalized to
the AB basis — a **derived** quantity NOT stored in cell AU (live AU23 = 0.57698 = AT23, since row 23
is 100% AB). The equations-expert should correct that `.m` cell citation in the implementation step.

Row→condition map confirmed exactly. Live α values (Consts sheet, cells AS/AT/AU):

| Consts row | Condition | alt (ft) | M | %AB | n | AS = α_dry | AT = α_AB | AU = α_eff(T_AB) |
|---|---|---|---|---|---|---|---|---|
| 23 | MxMach / dash | 36000 | 1.60 | 100 | 1.0 | 0.29829 | 0.57698 | 0.57698 |
| 24 | Cruise | 36000 | 0.87 | 0 | 1.0 | 0.27111 | 0.33264 | 0.17108 |
| 25 | Max Alt | 50000 | 0.87 | 100 | 1.0 | 0.13879 | 0.17029 | 0.17029 |
| 26 | Cmbt Trn (sub) | 20000 | 0.87 | 100 | 4.5 | 0.55566 | 0.68178 | 0.68178 |
| 27 | Cmbt Trn (sup) | 36000 | 1.40 | 100 | 1.4 | 0.35786 | 0.55656 | 0.55656 |
| 28 | Ps | 10000 | 0.87 | 100 | 1.0 | 0.70273 | 0.85355 | 0.85355 |

Probe check: live AT23 = 0.57698 ≈ test's 0.5770 (α_AB) ✓; live AU23 = 0.57698 ≠ test's claimed
0.1882 (that 0.1882 = AS23·15000/23770 = α_dry-on-AB, not the content of cell AU) — confirms the AU
mislabel. `docs/propulsion_parameter_usage.md` updated with the verified table + semantics.

### Entry B — Brandt Engn AB-thrust-equation cell ROW: readme_prop row 6 vs. F16Baseline row 15 — flagged/deferred → RESOLVED (live-xls read, 2026-07-24)
`readme_prop.md:78-83` places the AB thrust equation at **Engn row 6** (cells A6:G6 / H6:S6);
`baseline/F16Baseline.m:340-342` cites the same AB coefficients (`C_M_AB=0.1`, `e_M_AB=0.5`,
`C_TR_AB=2.2`) at **Engn(s) D15/F15/R15 (row 15)**. The dry equation agrees on row 4 both sides. The
coefficient *values* match `readme_prop.md`'s AB formula (α_AB = δ₀(1 − 0.1√M − 2.2(θ₀−TR)/θ₀)); only
the cited *row* differs (6 vs 15). Lower priority (values agree); reconcile the row reference via the
same live-cell read as Entry A. Flagged, not resolved.

**RESOLVED (live-xls read, 2026-07-24):** on the live `Engn(s)` sheet (workbook sheet 9; there is also
a separate `Engn(s) Old` sheet 8) the **AB thrust equation is row 15** — `A15` = "ThrustAB = TslAB",
section header `A14` = "AB:  θo ≤ TR" — with coefficients `D15 = 0.1` (Mach coeff), `F15 = 0.5` (Mach
exponent → √M), `L15 = 0.1` / `O15 = 0.5` (above-TR Mach term), `R15 = 2.2` (θ correction); `S1 = 1.0`
(TR). **Row 6 is the dry-TSFC section header** ("Engine Thrust-Specific Fuel Consumption") with EMPTY
coefficient cells (D6/F6/L6/O6/R6 all blank). So `readme_prop.md`'s "Engn!row 6" for the AB thrust
equation is **WRONG**; `F16Baseline.m`'s Engn(s) row-15 citation (D15/F15/R15) is **CORRECT** (full
set D15/F15/L15/O15/R15). The dry thrust equation is row 4 (`D4=0.3`, `F4=1.0`, `L4=0.3`, `O4=1.0`,
`R4=1.7`); dry TSFC row 7; AB TSFC row 19 (`A19`="TSFCAB = TSFCslAB"). `readme_prop.md`'s compact row
scheme (dry-thrust 4 / dry-TSFC 5 / AB-thrust 6 / AB-TSFC 7) does NOT match the live sheet (dry-thrust
4 / dry-TSFC 7 / AB-thrust 15 / AB-TSFC 19); the FORMULAS it lists are correct — only the AB (and
dry-TSFC / AB-TSFC) row numbers are wrong. `docs/propulsion_parameter_usage.md` updated to the
verified rows.

---

## 2026-07-24 — Weights deep-dive, Phase A (documentation)

**Context:** Phase-A documentation pass for the Weights deep-dive (Step 2a; mirrors Geometry /
Aerodynamics / Propulsion). Cross-checked the live weights code (`src/base/WeightsBase.m`, the
`WeightsL{1,2,3}` / `WeightsModelL{1,2,3}` toolboxes/enforcers, `examples/F16A/F16WeightsL{1,2,3}.m`),
the existing tests (`tests/disciplines/TestWeightsL{1,2,3}.m` — read for citations only, NOT expected
values), the ground truth (`readme_wt.md`, `BrandtWeight.m`, `GroundTruth/cell-map.md` Wt sheet), the
reference extract (`temp_AI/docs/disciplines/reference_extracts/raymer_data.md` §15.3.1), the weights
subplan (`docs/subplans/05_weights.md`), and `baseline/F16Baseline.m`. I did **not** open the live
`Brandt-F16-A.xls` (the ground-truth docs already agree internally on every Wt cell used here — no
doc-vs-xls read was needed). §3a is the **HARD-STOP** list: the user must supply verified Raymer
references for every enumerated exponent before Step-2b/2c proceeds. §3b carries a locked user
decision. §3c items are flagged for the Step-2c equations-expert, **not** resolved here.

### §3a — ★ Raymer §15.3.1 L3 exponents/coefficients — HARD STOP RESOLVED (user decision 2026-07-24) ★

**DECISION (user, 2026-07-24):** Step 2c uses **approach 2** — **keep the current code values as-is**
for every row below (the two [CONFLICT] rows retain their code values **1.023** (Eq 15.13) and
**−0.323** (Eq 15.3), NOT the extract values), **re-cite them to a consistent Raymer 7th ed. §15.3.1
reference**, and **do NOT clear the unverified status**. This entire checklist becomes a **STANDING
TO-DO: every L3 equation (Eqs 15.1–15.24, INCLUDING the 5 "verified-clean" rows) must still be checked
against the physical Raymer book** — the extract is `[verify]`-flagged and the two [CONFLICT] rows
prove it is not fully reliable. Step 2c must PRESERVE this obligation (a clearly-labeled `testTODO_*`
marker pointing at this checklist), not declare the values book-verified. No exponent VALUE changes in
2c; only citations are unified and the standing to-do is wired in.

Method-by-method audit of `src/disciplines/weights/WeightsL3.m` low-level statics against the repo
extract `raymer_data.md` §15.3.1 (book pp.572–573 / PDF pp.602–603). Categories:
- **[CONFLICT]** — code value disagrees with the extract value.
- **[FROM-CODE]** — exponent is absent from the extract ("…") and cited "from existing code"
  (`WeightLevel3.m`), i.e. no book source in-repo.
- **[VERIFY]** — present in the extract but OCR-flagged `[verify]`; code matches the OCR value, but the
  OCR value itself is unconfirmed against the physical book.
- **[IMAGE-ONLY]** — Eqs. 15.1–15.7; in-code comment claims re-verification against an out-of-repo
  "Raymer 6th ed. p.572 equation image," but that image is not in the repo and the extract still marks
  these `[verify]`. Cannot be confirmed from repo contents.

**VERIFIED-clean (extract gives a non-[verify] value; code matches — NO user action needed):**
Eq. 15.8 firewall `1.13·S_fw`; Eq. 15.11 tailpipe `3.5·D_e·L_tp·N_en`; Eq. 15.12 cooling
`4.55·D_e·L_sh·N_en`; Eq. 15.22 furnishings `217.6·N_c`; Eq. 15.24 handling `3.2e-4·W_dg`.

**Checklist — one row per unverified exponent/coefficient** (file:line = `WeightsL3.m`):

| # | Eq | Term | Code value | In-code citation | File:line | Cat | What is uncertain |
|---|----|------|-----------|------------------|-----------|-----|-------------------|
| 1 | 15.13 | `N_en` exponent (oil cooling) | **1.023** | none in-code (bare literal, no cite) | :298 | CONFLICT | Extract 15.13 (`raymer_data.md:134`) gives **1.078** `[verify]`. Code silently uses 1.023 — direct code-vs-extract conflict; neither confirmed against the book. |
| 2 | 15.3 | `cos(Λ_vt)` exponent (VT) | **−0.323** | "all exponents confirmed" p.572 image | :209 | CONFLICT | Extract 15.3 (`raymer_data.md:124`) shows `(cosΛ_vt)^(-1.0)`. Code −0.323 matches the widely-published fighter-VT form but **disagrees with the extract's −1.0**. |
| 3 | 15.10 | `N_en` exponent (air induction) | **1.498** | "from WeightLevel3.m" | :280 | FROM-CODE | Absent from extract 15.10 (`raymer_data.md:131` shows `N_en^…`). No book source in-repo. |
| 4 | 15.10 | `(L_s/L_d)` exponent | **−0.373** | "from WeightLevel3.m" | :280 | FROM-CODE | Absent from extract (`…`). No book source in-repo. |
| 5 | 15.10 | `D_e` exponent | **1.0** (linear) | none in-code | :280 | FROM-CODE | Extract shows `D^…` (exponent not given); code uses linear D_e. Unconfirmed. |
| 6 | 15.10 | `L_d` exponent | 0.643 | Eq. 15.10 | :279 | VERIFY | In extract but `[verify]` (OCR). |
| 7 | 15.10 | `K_d` exponent | 0.182 | Eq. 15.10 | :279 | VERIFY | In extract but `[verify]` (OCR). |
| 8 | 15.14 | `N_en` exponent (engine controls) | **1.008** | "Raymer 6th ed, eq 15.14" | :308 | FROM-CODE | Extract 15.14 (`raymer_data.md:135`) gives `N_en^…` (not legible); value not in repo. |
| 9 | 15.14 | `L_ec` exponent | **0.222** | "Raymer 6th ed, eq 15.14" | :308 | FROM-CODE | Extract gives `L_ec^…` (not legible); value not in repo. |
| 10 | 15.17 | `N_c` exponent (flight controls) | **0.127** | "from WeightLevel3.m" | :340 | FROM-CODE | Absent from extract 15.17 (`raymer_data.md:139` shows `N_c^…`). No book source in-repo. |
| 11 | 15.17 | `M` exponent | 0.003 | Eq. 15.17 | :340 | VERIFY | In extract but `[verify]`. |
| 12 | 15.17 | `S_cs` exponent | 0.489 | Eq. 15.17 | :340 | VERIFY | In extract but `[verify]`. |
| 13 | 15.17 | `N_s` exponent | 0.484 | Eq. 15.17 | :340 | VERIFY | In extract but `[verify]`. |
| 14 | 15.5 | `L_m` exponent (main gear) | **0.973** | "verified vs p.572 image" | :235 | FROM-CODE | Extract 15.5 (`raymer_data.md:126`) shows `L_m^…` (OCR "dropped Eq. 15.5 entirely" per code). Not in repo extract. |
| 15 | 15.5 | `(W_l·N_l)` exponent | 0.25 | p.572 image | :235 | VERIFY | In extract but `[verify]`. |
| 16 | 15.6 | `N_nw` exponent (nose gear) | **0.525** | "verified vs p.572 image" | :246 | FROM-CODE | Extract 15.6 (`raymer_data.md:127`) shows `N_nw^…`. Not in repo extract. |
| 17 | 15.6 | `(W_l·N_l)` exponent | 0.290 | p.572 image | :246 | VERIFY | In extract but `[verify]`. |
| 18 | 15.6 | `L_n` exponent | 0.5 | p.572 image | :246 | VERIFY | In extract but `[verify]`. |
| 19 | 15.9 | `W_en` exponent (engine section) | 0.717 | Eq. 15.9 `[verify]` | :269 | VERIFY | In extract but `[verify]`. |
| 20 | 15.15 | `T` exponent (starter) | 0.760 | Eq. 15.15 | :315 | VERIFY | In extract but `[verify]`. |
| 21 | 15.15 | `N_en` exponent (starter) | 0.72 | Eq. 15.15 | :315 | VERIFY | In extract but `[verify]`. |
| 22 | 15.16 | `V_t` exponent (fuel system) | 0.47 | Eq. 15.16 `[verify]` | :326 | VERIFY | In extract but `[verify]`. |
| 23 | 15.16 | `(1+V_i/V_t)` exponent | −0.095 | Eq. 15.16 | :327 | VERIFY | In extract but `[verify]`. |
| 24 | 15.16 | `N_t` exponent | 0.066 | Eq. 15.16 | :329 | VERIFY | In extract but `[verify]`. |
| 25 | 15.16 | `N_en` exponent | 0.052 | Eq. 15.16 | :330 | VERIFY | In extract but `[verify]`. |
| 26 | 15.16 | `((T·SFC)/1000)` exponent | 0.249 | Eq. 15.16 | :331 | VERIFY | In extract but `[verify]`. |
| 27 | 15.18 | `N_en` exponent (instruments) | 0.676 | Eq. 15.18 `[verify]` | :348 | VERIFY | In extract but `[verify]`. |
| 28 | 15.18 | `N_t` exponent | 0.237 | Eq. 15.18 | :348 | VERIFY | In extract but `[verify]`. |
| 29 | 15.18 | `(1+N_ci)` exponent | 1.356 | Eq. 15.18 | :348 | VERIFY | In extract but `[verify]`. |
| 30 | 15.19 | `N_u` exponent (hydraulics) | 0.664 | Eq. 15.19 `[verify]` | :356 | VERIFY | In extract but `[verify]`. |
| 31 | 15.20 | `R_kva` exponent (electrical) | 0.152 | Eq. 15.20 `[verify]` | :365 | VERIFY | In extract but `[verify]`. |
| 32 | 15.20 | `N_c` exponent | 0.10 | Eq. 15.20 | :365 | VERIFY | In extract but `[verify]`. |
| 33 | 15.20 | `L_a` exponent | 0.10 | Eq. 15.20 | :365 | VERIFY | In extract but `[verify]`. |
| 34 | 15.20 | `N_gen` exponent | 0.091 | Eq. 15.20 | :365 | VERIFY | In extract but `[verify]`. |
| 35 | 15.21 | `W_uav` exponent (avionics) | 0.933 | Eq. 15.21 `[verify]` | :372 | VERIFY | In extract but `[verify]`. |
| 36 | 15.23 | `(…/1000)` exponent (AC/anti-ice) | 0.735 | Eq. 15.23 `[verify]` | :385 | VERIFY | In extract but `[verify]`. |
| 37 | 15.1 | `tc_root` exponent (wing) | **−0.4** | "superscript not legible in page image; −0.4 per published form + temp_Casey" | :171 | IMAGE-ONLY + legibility | Explicitly **not read off the page** (`WeightsL3.m:160-164`); −0.4 assumed. Extract 15.1 `[verify exps]`. |
| 38 | 15.1 | `cos(Λ)` sweep **station** (wing) | LE sweep (`Λ_LE`) | "plain Λ in book = LE-sweep symbol" | :173, :60-61, :165-166 | IMAGE-ONLY + convention | Code uses **leading-edge** sweep; comment flags "some editions use quarter-chord — verify sweep definition." Extract var-def (`raymer_data.md:151`) just says "Λ = sweep" (does not specify LE vs c/4). |
| 39 | 15.1 | `(W_dg·N_z)` exponent | 0.5 | p.602 / p.572 image | :168 | IMAGE-ONLY | Extract 15.1 `[verify exps]`; image not in repo. |
| 40 | 15.1 | `S_w` exponent | 0.622 | image | :169 | IMAGE-ONLY | Extract `[verify exps]`. |
| 41 | 15.1 | `AR` exponent | 0.785 | image | :170 | IMAGE-ONLY | Extract `[verify exps]`. |
| 42 | 15.1 | `(1+λ)` exponent | 0.05 | image | :172 | IMAGE-ONLY | Extract `[verify exps]`. |
| 43 | 15.1 | `cos(Λ_LE)` exponent | −1.0 | image | :173 | IMAGE-ONLY | Extract `[verify exps]`. |
| 44 | 15.1 | `S_csw` exponent | 0.04 | image | :174 | IMAGE-ONLY | Extract `[verify exps]`. |
| 45 | 15.2 | `(1+F_w/B_h)` exponent (HT) | −2.0 | "all exponents confirmed" image | :183 | IMAGE-ONLY | Extract 15.2 `[verify]`; image not in repo. |
| 46 | 15.2 | `((W_dg·N_z)/1000)` exponent | 0.260 | image | :184 | IMAGE-ONLY | Extract `[verify]`. |
| 47 | 15.2 | `S_ht` exponent | 0.806 | image | :185 | IMAGE-ONLY | Extract `[verify]`. |
| 48 | 15.3 | `(1+H_t/H_v)` exponent (VT) | 0.5 | image | :201 | IMAGE-ONLY | Extract 15.3 `[verify]`. |
| 49 | 15.3 | `(W_dg·N_z)` exponent | 0.488 | image | :202 | IMAGE-ONLY | Extract `[verify]`. |
| 50 | 15.3 | `S_vt` exponent | 0.718 | image | :203 | IMAGE-ONLY | Extract `[verify]`. |
| 51 | 15.3 | `M` exponent | 0.341 | image | :204 | IMAGE-ONLY | Extract `[verify]`. |
| 52 | 15.3 | `L_t` exponent | −1.0 | image | :205 | IMAGE-ONLY | Extract `[verify]`. |
| 53 | 15.3 | `(1+S_r/S_vt)` exponent | 0.348 | image | :206 | IMAGE-ONLY + not-in-extract | Extract shows `…` for this term (exponent not given). |
| 54 | 15.3 | `AR_vt` exponent | 0.223 | image | :207 | IMAGE-ONLY + not-in-extract | Extract shows `A^…` (exponent not given). |
| 55 | 15.3 | `(1+λ_vt)` exponent | 0.25 | image | :208 | IMAGE-ONLY + not-in-extract | Extract shows `(1+λ)^…` (exponent not given). |
| 56 | 15.4 | `W_dg` exponent (fuselage) | 0.35 | image ("all confirmed") | :219 | IMAGE-ONLY | Extract 15.4 `[verify]`; image not in repo. |
| 57 | 15.4 | `N_z` exponent | 0.25 | image | :220 | IMAGE-ONLY | Extract `[verify]`. |
| 58 | 15.4 | `L_fus` exponent | 0.5 | image | :221 | IMAGE-ONLY | Extract `[verify]`. |
| 59 | 15.4 | `D_fus` exponent | 0.849 | image | :222 | IMAGE-ONLY | Extract `[verify]`. |
| 60 | 15.4 | `W_fus` exponent | 0.685 | image | :223 | IMAGE-ONLY | Extract `[verify]`. |
| 61 | 15.7 | `N_en` exponent (engine mounts) | 0.795 | image ("all confirmed") | :254 | IMAGE-ONLY | Extract 15.7 `[verify]`; image not in repo. |
| 62 | 15.7 | `T` exponent | 0.579 | image | :254 | IMAGE-ONLY | Extract `[verify]`. |

**Leading coefficients:** `raymer_data.md` states §15.3.1 coefficients are "legible from OCR"
(only exponents were garbled), so the constants (0.0103, 3.316, 0.452, 0.499, 0.013, 0.01, 13.29,
37.82, 10.5, 0.025, 7.45, 36.28, 172.2, 2.117, 201.6, …) are treated as lower-concern — but note the
two CONFLICT rows (#1, #2) show the extract is not fully reliable, so the user may wish to confirm
coefficients too. **Also flagged separately (not exponents, but citation-integrity issues on the same
equations):** in-code contradiction on Eqs. 15.1 & 15.4 — high-level `weight_wing`/`weight_fuselage`
comments (`WeightsL3.m:59`, `:81`) say "`[verify]`" while the low-level `wing`/`fuselage` comments
(`:160`, `:215`) say "all exponents confirmed"; and the p.572-vs-p.602 page-citation inconsistency
(header `:17` vs methods) — see §3c.

### §3b — OEW provenance (19,148 vs 19,980.70) — RESOLVED per locked user decision

**What disagrees:** the L1/L2/L3 unit tests assert `expected = 19148` and cite it as "Brandt F-16A.xls
sheet Wt B12", but Wt!B12 in the original workbook is **19,980.70**, not 19,148.
- `tests/disciplines/TestWeightsL1.m:117` — `expected = 19148; % [Brandt F-16A.xls, sheet "Wt", B12]`
  (also header `:11`).
- `tests/disciplines/TestWeightsL2.m:79` — `expected = 19148; % [Brandt B12]` (also header `:11`).
- `tests/disciplines/TestWeightsL3.m:203` — `expected = 19148; % [Brandt F-16A.xls, B12]` (also `:7`).
- vs `readme_wt.md:352` (§8 table) OEW `= 19980.70` at Wt!B12; `GroundTruth/cell-map.md:142`
  `Wt!B12 | OEW = airframe + engine | 19980.70`; `BrandtWeight.m:64/104/300` `W_empty_lb = 19980.70`.
- `baseline/F16Baseline.m:93` `b.brandt.OEW = 19980.70058; % [Brandt F-16A.xls Wt!B12]`; corrected
  variant `:136` `b.brandt.OEW = 19148.07828; % [corrections.xls Wt!B12]`.

**Why it matters:** 19,148 is the `corrections.xls` OEW (Casey's revised-weight workbook), not the
original Brandt Wt!B12. Citing it as "Brandt Wt!B12" is a wrong cell/workbook attribution and would
mislead anyone verifying the number.

**RESOLVED (locked user decision, per Step-2a plan decisions 4–5):** KEEP 19,148 as the unit-test
expected but **re-cite it to `corrections.xls`** (per `F16Baseline.m` corrected variant); do NOT chase
the `corrections.xls` file itself. The comparison report uses the official Brandt OEW **19,980.70
(Wt!B12)** as the Expected column and **19,148 (corrections.xls Wt!B12)** as a labeled other-source
column. The re-citation is a Step-2c code edit — no test file was edited in this documentation pass.

### §3c — Other discrepancies (FLAGGED for the Step-2c equations-expert — not resolved here)

1. **★ `W_all_else_empty` frozen-at-baseline sizing bug (CODE BUG).** `examples/F16A/F16WeightsL2.m:76`
   freezes `obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377)` = 0.17·31377 =
   **5334.09 lbf** in the constructor, using the baseline W_TO=31,377 rather than the W_TO passed to
   `OEW`. `WeightsL2.OEW` (`src/disciplines/weights/WeightsL2.m:49-50`) reads that frozen property, so
   `OEW(W_TO)` does **not** recompute the 0.17·W_TO all-else term at the passed W_TO — it is stale under
   sizing-loop mutation. The static `WeightsL2.weight_all_else_empty(obj, W_TO)` (`:97-101`) is correct
   but only ever called once (constructor). This is exactly the stale-under-mutation failure the
   inputs-vs-`Dependent` design removes. (`W_installed_engine`, also frozen in the constructor at
   `:73`, is W_TO-independent so its freeze is harmless.) Flag for the equations-expert; do NOT fix in
   this pass.

2. **LG fraction 0.033 (code) vs 0.034 (Brandt/subplan).** `WeightsL2.LG_fraction` jet_fighter =
   **0.033** (`src/disciplines/weights/WeightsL2.m:171`), cited "AE481 metabook §7". Brandt Wt!B23 =
   **0.034·W_TO** (`readme_wt.md:243` §5.11; `GroundTruth/cell-map.md:127`; `BrandtWeight.m:219`).
   `docs/subplans/05_weights.md:97` also cites 0.034 ("Roskam Airplane Design Part I"). So the framework
   uses 0.033 (AE481) while both Brandt and the subplan use 0.034 (Roskam). Conflicting value + source
   (AE481 §7 vs Roskam Part I). Flag.

3. **Page-citation inconsistency: p.572 vs p.602.** `WeightsL3.m:17` (header) cites the §15.3.1
   equations at "Raymer 6th ed. **p.572**"; every method-level comment cites "**p.602**". Per
   `raymer_data.md:115` these are the same equations (book pp.572–573 = PDF pp.602–603, PDF = book+30),
   so both point to the same content — but the file mixes book-page and PDF-page numbering for the same
   equations. Unify to one scheme in Step 2c.

4. **Edition + table drift (Raymer 6th vs 7th; Table 3.1 vs 6.1; §15.3.1 eq-number set).** Code and
   `raymer_data.md` cite **Raymer 6th ed.**; the Step-2a plan / CLAUDE.md citation style reference
   **Raymer 7th ed.** (as the propulsion pass adopted 7th ed. per user, todo 2026-07-24 entry 3). L1:
   code (`WeightsL1.m:29,89`) cites **Table 3.1** while `docs/subplans/05_weights.md:81,88` cites
   **Table 6.1** for the same power law. Additionally the subplan is stale vs the as-built code in
   several places (describes a nonexistent L2 "multi-parameter regression eq 6.1" — code uses Table
   15.2 surface-density; cites fuselage as "eq 15.5" — code uses Eq. 15.4; cites engine "eqs 7.13–7.17"
   — code uses Eqs. 15.7–15.15). The edition/table question is part of the §3a hard stop (the user
   should confirm which edition's equation numbering applies); the subplan staleness is slated for the
   Step-2d docs cleanup. Flag.

5. **`WEIGHTSMODELG3` typo.** `examples/F16A/F16WeightsL3.m:33` property-block banner reads
   "`WEIGHTSMODELG3 ABSTRACT PROPERTIES`" — should be `WEIGHTSMODELL3` (G→L). Cosmetic; fix in Step 2c.

6. **Vestigial NaN "computed" properties (design-smell, not a numeric bug).** The abstract-declared
   component-total properties (`W_wings`, `W_tail`, `W_fuselage`, `W_installed_engine`, `W_subsystems`
   in L3; `W_wings`, `W_landing_gear`, `W_tail`, `W_fuselage` in L2) are plain properties left at NaN
   and never populated live — `OEW`/`weight_*` recompute locally and discard. Under the target
   inputs-vs-`Dependent` design these should be live `get.<name>` getters. Noted so Step 2c migrates
   them rather than leaving stored placeholders. (Not a VnV-internal disagreement; recorded for the
   implementation step.)

---

## 2026-07-24 — GeomL3 (new tier) deep-dive, Phase A (documentation)

**Context:** Phase-A documentation pass for the new `GeomL3` detailed-geometry tier (user decision
2026-07-24, reversing the 2026-07-22 "Geometry has no L3"). GeomL3 = `GeomL2` + a delta of L3-detail
quantities the L3 weights class (`F16WeightsL3`, Raymer §15.3.1) will be dependency-injected. I
cross-checked the L3-weights consumer (`examples/F16A/F16WeightsL3.m` + `.md`), the GeomL2 geometry it
reuses (`examples/F16A/F16GeomL2.m`, `src/disciplines/geometry/GeomL2.m`), the tier pattern
(`src/base/GeometryBase.m`, `GeometryModelL1/L2.m`), and the ground truth
(`readme_geom.md`, `GroundTruth/cell-map.md`, `GroundTruth/f16a_ground_truth.json` geometry section).
Exposed AR/taper derivations verified 2026-07-24 via `mcp__matlab__evaluate_matlab_code` from the
GeomL2 inputs (exposed chords/spans reproduce Brandt GT exactly). I did **not** open the live
`Brandt-F16-A.xls` this pass. Entries below are **flagged for user review at the Phase-A gate, not
resolved** — no `.m`/`.json` was edited. New docs written: `examples/F16A/F16GeomL3.md`,
`docs/geometry_parameter_usage.md` (GeomL3 section).

**DECISION (user, 2026-07-24) — RESOLVES the value-divergence entries below:** GeomL3 is the **actual
physical / T.O.-geometry tier** (higher fidelity than GeomL2's Brandt-reference geometry). It uses the
physical/T.O. values as documented inputs — exposed HT AR 2.114 / HT taper 0.390 / VT taper 0.437,
VT LE sweep 47.5°, `L_fus` 47.5 ft, HT span `B_h` 18.5 ft. The divergences from GeomL2's Brandt values
are **EXPECTED fidelity differences, NOT errors** — GeomL3 does NOT adopt the Brandt-derived values.
Exposed AR/taper are carried as physical inputs (or derived from physical HT/VT chords, not GeomL2's
Brandt chords). The naming-clash entry (weights `D_fus`=depth, exposed `S_ht`/`S_vt`) stays a Step-2c
**DI-wiring** correctness item: map weights `D_fus`→`geom.H_max_fuselage`, exposed `S_ht`/`S_vt`→
`geom.S_exposed_*` — not a value dispute.

### §1 — Exposed-planform tail AR/taper: three of four weights values NOT reproducible from Brandt exposed geometry
`F16WeightsL3.m` hardcodes exposed-planform HT/VT AR and taper, cited `[Brandt / TO 1F-16A-1]`. GeomL2
already derives the exposed root/tip chords + exposed span for both surfaces (inside
`GeomL2.compute_S_exposed_horizontal/_vertical`), and those reproduce Brandt's own exposed-geometry
table (`f16a_ground_truth.json` `lifting_surface_exposed_areas`) **exactly** (HT `c_root_exposed`=6.8391,
`S_exp`=49.8473; VT `c_root_exposed`=7.1233, `S_exp`=40.8897). Deriving exposed AR (`≡b_exp²/S_exp`,
definitional) and exposed taper (`≡c_tip/c_root_exposed`, inverse Raymer 7th ed. Eq. 7.7) from that
geometry gives:

| Quantity | Weights hardcoded | GeomL3 clean-derived (from Brandt exposed geom) | Δ |
|---|---|---|---|
| HT exposed AR (`AR_ht`) | **2.114** | **2.4274** = 11.0²/49.8473 | **+14.8%** |
| HT exposed taper (`lambda_ht`) | **0.390** | **0.3252** = 2.2240/6.8391 | **−16.6%** |
| VT exposed AR (`AR_vt`) | 1.294 | 1.3025 = 7.2980²/40.8897 | +0.7% (matches) |
| VT exposed taper (`lambda_vt`) | **0.437** | **0.5731** = 4.0825/7.1233 | **+31.1%** |

**Why it matters:** only VT exposed AR is cleanly reproducible. The other three weights values cannot
be produced from Brandt's (GT-exact) exposed geometry — the `[Brandt / TO 1F-16A-1]` citation is not
reconcilable with Brandt's own numbers. `F16WeightsL3.m`'s own header concedes they are "actual
physical construction values, not the theoretical ones that Brandt suggests," and that `AR_ht`/`S_ht`
are "not reconciled" with `B_h`. The io/impl gate must choose per surface: (a) expose the clean
derived exposed AR/taper (2.43/0.325 HT, 1.30/0.573 VT) as NEW DERIVED, changing three weights inputs,
or (b) carry the weights physical values (2.114/0.390, 0.437) as NEW INPUTs with a pinned source.
**Do not silently pick a side.**

### §2 — VT LE sweep: 47.5° (T.O.) vs 40° (Brandt) — same quantity, two values
`F16WeightsL3.m:81` `Lambda_LE_vt = 47.5` `[TO 1F-16A-1]`; `F16GeomL2.m:119` `LE_sweep_vt = 40`
`[Brandt Main!H20]`. Same physical VT leading-edge sweep, +18.75% apart. GeomL3 must supply one value
to both the weights VT equation (Raymer Eq. 15.3) and the GeomL2 VT chord/exposed-area derivations.
**Flagged, not resolved.**

### §3 — Fuselage length: weights `L_fus`=47.5 ft (T.O.) vs GeomL2 `L_fus`=46.5 ft (Brandt)
`F16WeightsL3.m:90` `L_fus = 47.5` `[TO 1F-16A-1]`; `F16GeomL2.m:124` `L_fus = 46.5`
`[Brandt Main!B32]`. Same name, same quantity, +2.15% apart (T.O. incl./excl. probe vs Brandt
envelope). **Flagged, not resolved.**

### §4 — HT full span: weights `B_h`=18.5 ft (physical) vs GeomL2 derived `b_ht`=18.0 ft
`F16WeightsL3.m:69` `B_h = 18.5` (18 ft 6 in) `[USAF 3-view]`; GeomL2 `b_ht` = sqrt(`AR_ht`·`S_ht`) =
sqrt(3.0·108) = **18.0** ft (derived). +2.8% apart. The weights code explicitly chose the physical
18.5 over the sqrt(AR·S) derivation (its own comment flags the derivation "inconsistent with this
reported value"). GeomL3 decision: expose physical `B_h`=18.5 as a NEW INPUT distinct from the DERIVED
`b_ht`=18.0, or reconcile. **Flagged, not resolved.**

### §5 — Naming clashes: weights `D_fus`/`S_ht`/`S_vt` collide with GeomL2 properties of the same name but different meaning
- **`D_fus`:** weights `D_fus`=5.0 ft = *max fuselage depth* (Raymer Eq. 15.4), which maps to GeomL2
  `H_max_fuselage`=5.0 `[Brandt Main!D32]`. But GeomL2 ALSO has a Dependent property literally named
  `D_fus` = (W+H)/2 = **6.0** ft (equivalent diameter for Roskam Eq. 12.3). A DI wiring that naively
  reads `geom.D_fus` would feed **6.0** into Raymer Eq. 15.4 where **5.0** is intended.
- **`S_ht`/`S_vt`:** weights `S_ht`=49.85 / `S_vt`=40.89 are *exposed* areas (map to GeomL2
  `S_exposed_ht`/`S_exposed_vt`); GeomL2's identically-named `S_ht`=108 / `S_vt`=60 are *full
  reference* areas. A DI wiring that reads `geom.S_ht`/`geom.S_vt` would feed the full areas where the
  exposed areas are intended.

**Why it matters:** these are correctness traps for the Phase-B DI wiring — the intended GeomL2 source
property differs from the one the weights name would suggest. GeomL3's naming resolution is an io/impl
decision. **Flagged, not resolved.**

### §6 (context, not a divergence) — `L_t`, `S_r`, `S_csw`/`S_cs` are not derivable from current GeomL2
Not conflicting values, but recorded so the gate knows these must be NEW INPUTs (or need new inputs
added): `L_t`=22.0 (needs component apex-x locations GeomL2 does not expose — Brandt Main x-loc rows
have them); `S_r`=11.65 (no rudder chord-fraction in repo); `S_csw`=68.03 / `S_cs`=190 (no
control-surface geometry in GeomL2; `S_csw`'s T.O. breakdown 31.32+36.71 does not match Brandt
Main-tab LE-flap S=21.314 — cross-ref 2026-07-21 Finding 5). All are `[estimate]`/T.O. inputs in
`F16WeightsL3.m`; several carry `[verify]` tags the io/impl step should pin.

---

## 2026-07-25 — Phase 2 (GeomL3 → full L3 geometry tier), scribe documentation gate

**Context:** documentation gate for Phase 2 of the code-review remediation plan
(`~/.claude/plans/serene-conjuring-kitten.md`): promote `GeomL3` from a weights-only tier to the full
L3 geometry tier consumed by L3 geometry + aero + weights. I cross-checked
`src/disciplines/geometry/{GeomL3,GeometryModelL3,GeomL2}.m`, `src/base/GeometryBase.{m,md}`,
`examples/F16A/{F16GeomL1,F16GeomL2,F16GeomL3,F16AeroL3}.m`, `f16a_L{1,2,3}.json`, the three
`*_brandt_comparison.m` reports, `tests/disciplines/TestGeomL3.m` (citations only, never expected
values), `GroundTruth/f16a_ground_truth.json`, `readme_geom.md`, and — **this pass did open the live
workbook** — `GroundTruth/Brandt-F16-A.xls` over Excel COM (`actxserver`, read-only, closed without
saving), reading `.Value` and `.Formula` for the `Main` rows 16–28 and `Geom!A20/B20/A21/B21/H47`.
Numeric predictions were computed live via `mcp__matlab__evaluate_matlab_code` against the repo's own
statics. Docs written: `examples/F16A/F16GeomL3.md` (full rewrite), `docs/geometry_parameter_usage.md`
(as-built + Phase-2 target). **No `.m` or `.json` file was edited.**

**Status index (updated 2026-07-25 after the user's decisions):**

| § | Item | Status |
|---|---|---|
| §1 | `Main` taper/sweep citations swapped | ✅ **RESOLVED + APPLIED** — verified in `F16GeomL2.m`/`F16GeomL3.m` 2026-07-25; zero computed values changed |
| §2 | `Main!{B,C,H}24` t/c citation is the wrong row | ✅ **RESOLVED + APPLIED** — → row 22 (NACA 4-digit), verified 2026-07-25 |
| §3 | Mixed-provenance full-planform tails | ⬜ **OPEN** (standing: obtain T.O. values) |
| §4 | `Amax` citation gap — **SPLIT 2026-07-25**: **§4a** the L2 envelope-ellipse identity, **§4b** the L3 affine frame-rescaling assumption + Brandt's cosine area-distribution model | ⬜ **BOTH OPEN** |
| §5 | Brandt's `Amax` deducts `πD²/5` vs readme's `πD²/4` | ⬜ **OPEN** |
| §6 | `L_aircraft` = 47.65 provenance | ◐ value accepted; **provenance OPEN** |
| §7 | HT exposed-area basis / over-determined planform | ✅ **RESOLVED** — option B |
| §8 | L3 `S_wet` formula family | ✅ **RESOLVED** — Roskam Eq. 12.1 official |
| §9 | Brandt `Main!H27` VT TE sweep = literal 0 | ⬜ OPEN (informational; no action) |
| §10 | `f16a_ground_truth.json` `.geometry._comment` stale | ⬜ **OPEN** |
| §11 | `docs`/`CLAUDE.md` "Geometry has no L3" claims | ⬜ **OPEN** |
| §12 | Reuse gaps (`Amax`, nacelle diameter statics) | ✅ **CLOSED 2026-07-25** — `GeometryBase.compute_Amax_elliptical` + `compute_nacelle_diameter` now exist, cited, shared by both tiers. Residual: `GeomL3.compute_c_root_exposed` is flagged in-code as belonging in `GeomL2` |
| §13 | `GeometryBase.md` missing `convert_sweep_panel` | ⬜ **OPEN** |
| §14 | `Brandt-F16-A.xls` dirty in git | ◐ **data verified intact** (re-confirmed 2026-07-25, §24); hygiene OPEN |
| §15 | Fuselage depth keyed `max_height_ft` (L2) vs `max_depth_ft` (L3) | ⬜ **OPEN** (logged by the io agent, 2026-07-25) |
| §16 | ★ Sub-step 2h: area-ruled `Amax` scoping — strake in/out, bug replication, `/5` vs `/4`, fuselage variant | ✅ **DECISIONS TAKEN + SHIPPED 2026-07-25** — variant **D** (normalized frames), strake **OUT** (→ §23), Brandt's strake **and** VT bugs **DECLINED**, `/5` **kept**. The `/5` *justification* stays OPEN at **§5**; a fourth, previously unnamed choice was surfaced at **§20** |
| §17 | ★ DEFERRED RED TEST: `TestF16ConstraintSet/testOptimalPointWithinPhysicsBounds(L3)` | ✅ **RESOLVED 2026-07-25** — cleared by sub-step 2h; live T/W = **0.998975**. Spawns a NEW open user decision (narrow the bound back to 1.0?) — **do not narrow** |
| §18 | Nacelle x-range + `Geom!H3` semantics + the `1900` magic number: replica/`readme_geom.md` vs live `.xls` | ⬜ **OPEN** (new, live-verified 2026-07-25) |
| §19 | `readme_geom.md` §7's low-fidelity `Amax` row has NO cell backing in the workbook | ⬜ **OPEN** (new, live-verified 2026-07-25) |
| §20 | ★ Frame-area **discretization**: Brandt's 6-point cosine sampling vs the exact integral (6-point is uniformly 0.824 % low; +0.759 % on the as-built `Amax`) | ⬜ **OPEN** (logged by the equations-expert 2026-07-25; index row added by the scribe 2026-07-25) |
| §21 | Sub-step 2h **as-built verification record** — round-trip control, liveness, governing-station migration, what it did to §16/§17/§18 | ℹ️ **RECORD, no action** (logged by the equations-expert 2026-07-25; index row added by the scribe 2026-07-25) |
| §22 | `engine.n_engines` lives in `.geometry` because nothing exposes an engine count — should move to `.propulsion` + DI | ⬜ **OPEN** (new, 2026-07-25) |
| §23 | **Strake DEFERRED** — two comparison-report rows stay "NOT MODELED" (`S_wet` 39.956 `Geom!B15`, exposed 20.0 `Geom!H9`) | ⬜ **OPEN** (new, 2026-07-25) |
| §24 | §14 workbook-integrity re-confirmation | ℹ️ **RECORD** (2026-07-25) |

§4 and §5 each carry an appended **UPDATE 2026-07-25 (sub-step 2h)** paragraph narrowing the
question; **§4 was additionally SPLIT into §4a / §4b on 2026-07-25** (see its second update block).
Neither is resolved and no prior evidence was deleted.

**Index-bookkeeping note (scribe, 2026-07-25).** §20 and §21 were appended by the implementer
without index entries; the five rows above (§20–§24) close that gap. Re-statused this pass, **status
field only — no entry body was rewritten and nothing was deleted**: §1/§2 (fix now APPLIED and
verified in code), §12 (reuse gaps CLOSED), §14 (re-confirmed → §24), §16 (decisions taken and
shipped), §17 (**RESOLVED**, with its full evidence block intact below and the resolution prepended).
§4 was SPLIT. The two genuinely new items are §22 and §23; §24 is a record.

Resolved entries keep their full evidence — the decision text is prepended, nothing was deleted.

### §1 — ★ Brandt `Main`-tab TAPER and SWEEP cell citations are SWAPPED repo-wide ★ — RESOLVED (user, 2026-07-25)

**RESOLVED (user decision, 2026-07-25):** the finding is confirmed — the coordinator independently
re-read the workbook and verified row 20 = `Taper Ratio`, row 21 = `Sweep, deg`. **Fix repo-wide in
this phase.** `examples/F16A/F16GeomL3.md` §F is the authoritative reference for the fix, including
the complete file:line list (§F.3) and the exact scope (§F.1). **Zero computed values change** — only
citation text moves, so no report and no test expectation shifts. Evidence retained below.
Live `Main`-tab row labels (column A) and values:

| Row | Label (live) | B (wing) | C (pitch ctrl) | H (vert surf) |
|---|---|---|---|---|
| 18 | `S, sq ft` | 300 | 108 | 60 |
| 19 | `Aspect Ratio` | 3 | 3 | 1.6 |
| 20 | **`Taper Ratio`** | **0.2275** | **0.2275** | **0.5** |
| 21 | **`Sweep, deg`** | **40** | **40** | **40** |

The repo consistently cites the opposite: `Main!B20`/`C20`/`H20` for **LE sweep** and
`Main!B21`/`C21`/`H21` for **taper**. Occurrences found: `examples/F16A/F16GeomL2.m:101,103,108,110,117,119`
(and its `_src` header), `examples/F16A/F16GeomL3.m:51-52`, `examples/F16A/f16a_L2.json` `.geometry._src`
(cites the block `wing B18:B24, pitch_ctrl C18:C24, vert_tail H18:H24` — the range is right, the
per-quantity mapping in the consuming files is not), `examples/F16A/f16a_L3.json`
`.geometry.wing._src` / `.vertical_tail._src`, `docs/geometry_parameter_usage.md` (corrected in this
pass, with the correction called out), and **this todo file's own 2026-07-24 GeomL3 §2**, which cites
`F16GeomL2.m:119 LE_sweep_vt = 40 [Brandt Main!H20]` — live `H20` = 0.5, the taper.

**Why it matters:** every *value* is correct, so nothing computes wrong and no test moves. But the
cell citations are the audit trail: anyone opening `Main!B20` to verify a 40° sweep finds 0.2275, and
the 2026-07-24 GeomL3 §2 divergence entry (VT 47.5 vs 40) currently points at the wrong cell for the
Brandt side of the very comparison it is logging. Correct references are
`Main!{B,C,H}20` = taper, `Main!{B,C,H}21` = sweep. **Not applied** — a repo-wide citation edit for
the implementation gate.

### §2 — ★ `Main!B24`/`C24`/`H24` cited for t/c are the WRONG ROW; B24/C24 are EMPTY ★ — RESOLVED (user, 2026-07-25)

**RESOLVED (user decision, 2026-07-25):** confirmed independently by the coordinator (row 24 =
`Y Location`, B24/C24 empty; real source is row 22's NACA 4-digit designation). **Fix repo-wide in
this phase**: `[Brandt Main!{B,C,H}24]` → `[Brandt Main!{B,C,H}22]`, with the mapping stated as
"NACA 4-digit designation → t/c" (`1404` → 0.04 wing, `0004` → 0.04 HT/VT). Authoritative reference
and file:line list: `examples/F16A/F16GeomL3.md` §F. Zero computed values change. Evidence retained
below.
`F16GeomL2.m:100,107,116` and `F16GeomL3.m:53,60,68` cite `Main!B24`/`C24`/`H24` for
`tc_wing`/`tc_ht`/`tc_vt` = 0.04. Live:
- `Main!B24` — **empty** (no value, no formula). `Main!C24` — **empty**. `Main!H24` = **0**.
- Row 24's label is **`Y Location`**, not thickness. `H24 = 0` is the VT's Y-location, coincidentally
  numeric and unrelated to t/c.
- The actual source is **row 22, `NACA 4-digit`**: `B22` = 1404 (wing), `C22` = `0004` (HT),
  `H22` = `0004` (VT) — last two digits = thickness in percent chord → 0.04 for all three.

**Why it matters:** three t/c inputs at two fidelity levels currently cite a blank cell, and one
cites an unrelated coordinate. The value 0.04 is corroborated independently by
`[T.O. 1F-16A-1 Fig. 1-2, NACA 64A204]` for the wing, so no number changes — only the provenance.
**Flagged, not applied.**

### §3 — Mixed provenance of the L3 full-planform tail geometry (STANDING ITEM)
Per the locked user decision (2026-07-25, plan option a), L3 `.geometry` will carry Brandt's
**full-planform** tail values — `S_ht` = 108 `[Main!C18]`, `AR_ht` = 3.0 `[C19]`,
`lambda_ht` = 0.2275 `[C20]`, `S_vt` = 60 `[H18]`, `AR_vt` = 1.6 `[H19]`, `lambda_vt` = 0.5 `[H20]`
(all confirmed live) — **alongside** the physical/T.O. `LE_sweep_vt` = 47.5°, `L_fus` = 47.5 ft and
`B_h` = 18.5 ft, and alongside the physical exposed AR/taper (2.114/0.390, 1.294/0.437) that
2026-07-24 GeomL3 §1 already showed are not Brandt-derivable.

So a single L3 tail planform will be described by **three different sources at once**: Brandt for
area/AR/taper, T.O./USAF for sweep and span, and an unreconciled physical set for the exposed
AR/taper. That is internally inconsistent as a description of one physical surface (e.g. Brandt's
`AR_ht` = 3.0 with `S_ht` = 108 implies span 18.0, while the T.O./USAF span is 18.5 — see §7).

**Standing action requested: obtain T.O. 1F-16A-1 full-planform HT/VT reference area, aspect ratio
and taper**, so the L3 tier can be single-sourced. Until then the mixed provenance must be stated
explicitly in the JSON `_src` strings and in `F16GeomL3.md` (done in this pass, §A/§H).
**Not resolved.**

### §4 — `Amax` has NO pinnable citation
Phase 2c computes `Amax = (π/4)·W_max_fuselage·H_max_fuselage` = **27.488936 ft²** (computed live).
This is the area of an ellipse with semi-axes W/2 and H/2, consistent with the equivalent
elliptical-section fuselage the rest of the model already assumes (`D_fus = (W+H)/2` → Roskam
Eq. 12.3). **No Raymer, Roskam, Mattingly or Brandt equation number exists for it in this repo**, and
none is in `temp_AI/docs/disciplines/reference_extracts/`. Documented as a *standard identity* per
the precedent set for `GeometryBase.convert_sweep` (`src/base/GeometryBase.md`: "cited as a standard
swept-wing identity rather than a specific textbook equation number", RESOLVED 2026-07-21 user
decision). **Action requested: pin a citation, or explicitly accept the standard-identity status in
writing.** No equation number was invented.

Secondary: there is **no static** anywhere for this (nor for the nacelle diameter — see §12), so the
implementation must create one rather than reuse.

**UPDATE 2026-07-25 (sub-step 2h) — the citation question is now NARROWER, and splits in two.**
Still OPEN; nothing resolved. Two distinct un-pinned items now, not one:

1. **The envelope-ellipse identity `(π/4)·W·H`** (what `GeometryBase.compute_Amax_elliptical` does
   today) — unchanged from the above: a standard identity, no equation number anywhere in the repo.
   Note for the record that this repo has now carried **three different `Amax` definitions**, all
   fuselage-only and all mutually inconsistent: `π·(D_fus/2)²` = 19.6350 (the pre-Phase-2
   `F16AeroL3` bug), `π·(W_max/2)²` = 38.4845 (read-only `temp_Casey/examples/F-16A B Block 10 and
   15/F16A_Level3_Sizing_ClassBased_Example.m:79`), and `(π/4)·W·H` = 27.4889 (current). So "which
   `Amax`" has never had one answer in this codebase.
2. **Brandt's closed-form cosine area-distribution model** — `readme_geom.md` §4.5 fully documents
   the *formula* (`Area(x) = tc·(c_exp_root + c_tip)·y_span·(1 − cos 2πξ)/divisor`), so the
   remaining question is **not** what Brandt does but whether that model traces to any textbook or
   is Brandt's own construction. Searched this pass: **no `1 − cos` area-distribution formula, and
   no area-ruling method of any kind, appears anywhere in
   `temp_AI/docs/disciplines/reference_extracts/`** (Raymer/Roskam/Mattingly/metabook extracts) or
   in `temp_Casey` (which has no area-ruled buildup at all — it uses the bare circle above).
   **One concrete citation LEAD found:** `temp_AI/docs/disciplines/reference_extracts/roskam_vol2_data.md:22`
   states that above M ≈ 0.90 one must "use cross-sectional area-ruling, **Part VI**" — i.e. the
   repo's own Roskam Vol. II extract names **Roskam Part VI** as the authority for the
   cross-sectional-area-ruling method. **Roskam Part VI is not in this repo.** Recommended action
   request: obtain Roskam Part VI's area-ruling section, or accept Brandt's cosine model in writing
   as "Brandt's own construction, no textbook equation number." No equation number was invented.

**SPLIT 2026-07-25 (scribe, after sub-step 2h shipped) — this entry is now TWO items, BOTH OPEN.**
Nothing is resolved and nothing above was deleted. The split is necessary because the two halves no
longer live in the same tier, so a single "`Amax` has no citation" line can no longer be actioned as
one thing:

- **§4a — the ENVELOPE-ELLIPSE identity `(π/4)·W·H`. Applies to L2 ONLY.** It is what
  `GeometryBase.compute_Amax_elliptical` computes and what `F16GeomL2.Amax` = **27.488936** returns
  (verified live 2026-07-25, undisturbed by 2h). It is correct *for L2*, because `readme_geom.md`
  §7's own fidelity table classifies the fuselage-envelope form as the LOW-fidelity `Amax` and L2 is
  the low-fidelity tier. **It no longer appears at L3 at all.** Citation status unchanged: a
  standard identity, no equation number anywhere in this repo, documented per the `convert_sweep`
  precedent. Cross-reference §19 — §7's low-fi row has no cell backing either, and says
  "cylindrical" (`π·(D_fus/2)²` = 28.2743) where the code is elliptical (27.4889), −2.78 % apart.
  **Action requested (unchanged): pin a citation, or accept the standard-identity status in
  writing.**

- **§4b — the AREA-RULED model at L3.** Two distinct un-pinned elements, both now isolated in code
  behind ★ blocks that name this entry:
  1. **The AFFINE-RESCALING assumption** (`GeomL3.denormalize_frames`) — that a fixed *normalized*
     fuselage cross-section shape distribution can be rescaled by `L_fus` / `W_max_fuselage` /
     `H_max_fuselage`. This is **new with sub-step 2h** (variant D) and did not exist when §4 was
     first written. No Raymer / Roskam / Mattingly / metabook equation number exists for it anywhere
     in this repo, and none was invented. Recorded modelling consequence: `max(h/H_max)` = 1.50 at
     frame 6 (the canopy bulge), so a 10 % deeper fuselage gets a 10 % taller canopy.
  2. **Brandt's cosine area-distribution model** (`GeomL3.compute_surface_cs_area`, and the
     `A = w·h·I_cos` frame section in `compute_frame_cs_area`) — unchanged from the original entry
     above: `readme_geom.md` §§4.2/4.5 document the *formula* fully, so the open question is only
     whether it traces to any textbook. Lead unchanged and still unresolved:
     `roskam_vol2_data.md:22` names **Roskam Part VI** as the authority for cross-sectional
     area-ruling, and Part VI is not in this repo.

  **Action requested: obtain Roskam Part VI's area-ruling section, or accept BOTH in writing as
  "Brandt's own construction / an undocumented affine-scaling assumption, no textbook equation
  number."** No equation number was invented for either.

Documented as-built at `examples/F16A/F16GeomL3.md` §D.6 (which points back here) and in
`docs/geometry_parameter_usage.md`.

### §5 — Brandt's `Amax` deducts `π·D²/5`, while `readme_geom.md` uses `π·D²/4` for the same nacelle
Live formulas:
- `Geom!A20` = `Total Aircraft Amax:` (label); `Geom!B20` = 25.110556, formula `=H47`.
- `Geom!H47` = 25.110556, formula `=MAX(H26:H45)-Main!B28*3.141579*C475^2/5`.

So Brandt's raw whole-aircraft max cross-section is 32.971053 ft² and he subtracts
`N_eng·π·D²/5` = 7.8605 ft². But `readme_geom.md` §4.5 states the nacelle's **own** cross-section
contribution as `N_eng·π·D_engine²/4` = π·3.537²/4 = **9.826 ft²** (the actual circle area), and then
describes the Amax deduction as `−N·π·D²/5` with the bare comment "removes the internal inlet duct
from the external maximum cross-section" — no justification for why the removal is 80 % of the duct
area rather than 100 %. Also note the hardcoded `3.141579` (π to 6 s.f., low by 1.4e-5 relative).

**Why it matters:** 25.110556 is the comparison target for the new geometry `Amax`, and the framework
figure (27.4889, elliptical envelope) is **+9.47 %** against it and **−16.6 %** against Brandt's raw
32.9711. Whether the right comparison target is 25.11 or 32.97 depends on what the `/5` means.
**Flagged, not resolved.**

**UPDATE 2026-07-25 (sub-step 2h) — live-verified NEGATIVE result + the numeric cost of each
reading.** Still OPEN. Re-read the live workbook over Excel COM (read-only, `Close(false)`) and
searched the entire nacelle block `Geom!A470:E490` for anything that would justify the `/5`:

- `Geom!H47` formula confirmed verbatim: `=MAX(H26:H45)-Main!B28*3.141579*C475^2/5`. The **`/5` is a
  bare literal**; `Main!B28` = 1 (`N_eng`), `C475` = 3.537022 (`D_engine`).
- The nacelle block (`Geom!A472:E490`, labelled "More Accurate Nacelle Shape / Default: Cylinder
  Area Variation") contains **`B475` = 9.82577 "X Area" = `=3.1416/4*C475^2`, `C475` = 3.53702
  "Diameter, ft", `D475` = 15.9166 "Length, ft", `E475` = 0.46797 "Wetted Area Factor (2 inlets for
  one engine are smaller)", and a 5-station nacelle x-table `C480:C484`. There is NO inlet capture
  area, NO throat diameter, and nothing else in the workbook dividing by 5.** So the workbook
  itself offers **no justification for the `/5`** — this is now a verified absence, not an
  un-searched gap.
- Incidental: the workbook uses **two different hardcoded π values in the same calculation** —
  `3.1416` in the nacelle cross-section (`B475`, and the `AE` column) and `3.141579` in the `H47`
  deduction and in every cosine surface column. Accounts for the residual ~2e-5 between the live
  cell 25.110556 and `BrandtGeometry.m`'s 25.110534 (MATLAB `pi`).

**Numeric cost of each reading (computed live 2026-07-25 against Brandt's own 20-frame table):**

| Reading | Deduction | `Amax` | vs `/5` | `CD0_wave` (M=1.6, l=47.65) | L3 constraint optimum T/W |
|---|---|---|---|---|---|
| `/5` (as-built Brandt) — nacelle nets **+π·D²/20 = +1.9651 ft²** | 7.8606 | **25.110534** | — | 0.025745 | **1.019642** |
| `/4` (self-consistent) — nacelle nets **exactly 0** | 9.8257 | **23.145385** | **−7.82 %** | 0.021873 (**−15.04 %**) | **0.922951** |

**A self-consistency argument for `/4` that was not previously recorded:** because the governing
station (x ≈ 29.1 ft) lies *inside* the nacelle's active range, deducting the same `π·D²/4` that the
`AE` column added makes the flow-through nacelle contribute **exactly nothing** to `Amax` — the
textbook area-rule treatment of a fully-ducted flow-through body. Under `/5` the nacelle nets
+1.9651 ft² (20 % of its own section), which reads as "the cowl annulus is displaced volume, the
capture streamtube is not" — physically defensible for a pitot inlet whose capture area is smaller
than the nacelle max section, but with no supporting number in the workbook.
**Consequence for optimization liveness (see §16 item 5): under `/4`, `Amax` becomes COMPLETELY
insensitive to engine thrust** (verified live: `T_SL` +10 % → ΔAmax = +0.000 %), whereas under `/5`
it moves +0.783 %. That is a design-relevant side effect of this choice, not just a calibration one.
**Still a user decision. Not resolved.**

### §6 — Overall aircraft length: 47.65 is UNSOURCED in-repo, and Brandt's 48.304 matches nothing — VALUE ACCEPTED (user, 2026-07-25); PROVENANCE STILL OPEN

**PARTIAL (user, 2026-07-25):** the **value** `overall_length_ft = 47.65` stands as the user's
decision and is the L2/L3 input. **This entry stays OPEN as a standing item to pin the figure to a
primary source.** Also recorded (in `examples/F16A/F16GeomL3.md` §E): 47.65 is a *published airframe
length* (a specification dimension) while Brandt's `Geom!B21` = 48.303947 is a **`MAX()` over his
x-station columns** — an *extent*, not a spec length — so **the two are not comparable quantities** and
the report row must be annotated `definitional`, not treated as a 1.35 % error. Detail below.
The locked decision makes `overall_length_ft = 47.65` a direct `.geometry` INPUT at L2 and L3, cited
as the "published F-16A airframe length, 47 ft 7.75 in". Findings:
1. 47 ft 7.75 in is exactly **47.6458 ft**; 47.65 is a +0.009 % rounding (immaterial, but the JSON
   should state which of the two it is).
2. **Neither "47.65", "47 ft 7.75 in", nor any overall-length figure appears anywhere in
   `air_vehicle_design/sizing/`** (grepped 2026-07-25; the only `7.75` hits are unrelated flap
   geometry in read-only `temp_Casey/`). So the value has **no in-repo source document** — it is
   currently a bare assertion, exactly the situation the "every equation/value cites a source" rule
   forbids.
3. Brandt's `Geom!B21` = **48.303947** (live), label `Geom!A21` = `Total Aircraft Length:`, formula
   `=MAX(L38:L44,L46:L121,L123:L141,L152,L153,L154,L155,L156,L157,L158,L163,L164,L165,L166,L167,L168,L169)`
   — a maximum over his component x-station columns, i.e. the aft-most modelled station of his own
   layout, **not** a published airframe dimension. It matches neither 47.65 (−1.35 %) nor the
   commonly-quoted 49 ft 5 in ≈ 49.42 ft (−2.3 %) figure for the F-16 with pitot boom.

**Action requested:** confirm which published length is intended and name the document (T.O. 1F-16A-1
section? Jane's? USAF fact sheet?), and record what Brandt's 48.304 is being treated as — a
comparison reference (current plan) or a modelling target. **Not resolved.** The number materially
matters: `L_aircraft` enters Raymer Eq. 12.44 as `(Amax/l)²`.

### §7 — `S_exposed` L2-vs-L3: divergence partly impossible; HT planform over-determined — RESOLVED (user, 2026-07-25)

**RESOLVED (user decision, 2026-07-25) — OPTION B.** `S_ht = 108.0` and `B_h = 18.5`
`[USAF 3-view]` are the INPUTS; **`AR_ht` becomes DERIVED** = `B_h²/S_ht` = **3.1690** and must not
remain a stored input (a stored AR alongside both S and b makes the JSON self-contradictory and goes
stale when an optimizer moves the span). Resulting `c_root_ht` = 9.5118, `c_tip_ht` = 2.1639,
`S_exposed_ht` = **51.1486 ft²** — **+2.605 %** vs the stored 49.85 and **+2.611 %** vs Brandt GT
`Geom!8`, an **INTENTIONAL divergence** to be annotated `BY DESIGN` in the comparison report, never as
an error. Option C is marked NEVER-IMPLEMENT (geometrically inconsistent).

Rationale recorded: this matches GeomL3's charter (physical/T.O. value wins over Brandt) and how a
tail is actually measured off a 3-view — **area and span are measured; aspect ratio is definitional.**
Brandt's `Main!C19` = 3.0 becomes a comparison reference.

Part (a) of the finding — that `S_exposed_vt` **cannot** diverge, because
`GeomL2.compute_S_exposed_vertical` takes no sweep argument — was independently confirmed by the
coordinator; the plan's prediction of a VT divergence was withdrawn. Do not implement a
sweep-dependent exposed-area formula. Full detail: `examples/F16A/F16GeomL3.md` §A.4. Evidence
retained below.
Phase 2b makes `S_exposed_ht`/`S_exposed_vt` `Dependent` (removing the stored 49.85 / 40.89) and
expects "small divergence from 49.85/40.89 (L3 VT sweep 47.5, HT span 18.5) — intended fidelity
divergence". Checked against the existing statics (all values computed live 2026-07-25):

**(a) The VT cannot diverge.** `GeomL2.compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)`
(`src/disciplines/geometry/GeomL2.m:304`) takes **no sweep argument** — the exposed-area clip is a
pure trapezoid-area calculation in `S_vt`, `AR_vt`, `lambda_vt`, `H_max_fuselage`, all identical at
L2 and L3. So `S_exposed_vt` = **40.8897 ft²** at L3, bit-identical to L2 and to Brandt GT
`Geom!10` = 40.8897. The plan's stated cause (VT LE sweep 47.5) does not enter this formula at all.
**Do not "fix" this by inventing a sweep-dependent exposed-area formula.**

**(b) The HT planform is over-determined**, and the divergence depends on which span is primary:
`S_ht` = 108 and `AR_ht` = 3.0 imply span `sqrt(AR·S)` = **18.0 ft**, while `B_h` = 18.5 ft
`[USAF 3-view]` is carried as a physical input (2026-07-24 GeomL3 §4). The three candidate getters:

| Option | Basis | `S_exposed_ht` | vs stored 49.85 |
|---|---|---|---|
| A | full-planform self-consistent (span = 18.0); `B_h` stays a weights-only input | **49.8473 ft²** | −0.006 % |
| B | physical span primary (chords from `B_h` = 18.5 and `S_ht` = 108, implied AR 3.1690) | **51.1486 ft²** | +2.605 % |
| C | mixed (chords from `AR·S`, clip half-span = `B_h/2`) | 52.5694 ft² | +5.455 % |

Option C is geometrically inconsistent (clips a trapezoid outside its own span) and must not be
implemented. **Option A produces NO divergence at all** — L3 exposed areas equal L2's and Brandt's
exactly. Option B produces the +2.6 % the plan anticipates, but then `AR_ht` must become DERIVED
(`B_h²/S_ht` = 3.1690) or the JSON carries a self-contradiction.

**Action requested: choose A or B**, and if B, say what happens to `AR_ht`. **Not resolved — the
scribe is not picking.** Consequence either way: `TestGeomL3.testExposedTailAreasArePhysicalInputs`
must be rewritten as a *derived*-value test, and its expected value must be the hand-computed clip,
not a re-read of the property (anti-self-referential rule).

### §8 — L3 lifting-surface `S_wet` formula family unspecified by the plan — RESOLVED (user, 2026-07-25)

**RESOLVED (user decision, 2026-07-25): Roskam Vol. II Eq. 12.1 is OFFICIAL at L3**
(`GeomL2.compute_roskam_planform`), fed the new T.O. root/tip t/c splits — the same official choice L2
makes. Brandt's uniform-t/c `Geom!B13` form is retained **only as an alternate comparison-report
row**, exactly as L2 does.

Recomputed live 2026-07-25 **with the option-B HT chords** (§7): wing **396.3767** (+1.11 % vs GT),
HT **104.0349** (+4.47 %), VT **83.1399** (+1.78 %); Brandt-form alternates 392.0205 / 102.3842 /
81.7213. Official total incl. duct **1488.2515 ft²**; Brandt-form alternate total 1480.8261.

Recorded explicitly: **this moves L3 further from Brandt's GT, and that is correct, not a
regression.** Brandt's GT figures are the output of his own uniform-t/c formula on his own inputs, so
matching them would mean adopting his coarser single-t/c model instead of the better variable-t/c one.
The HT's larger +4.47 % decomposes as +1.8 % formula family and +2.6 % option-B exposed area. Full
detail: `examples/F16A/F16GeomL3.md` §A.5. Evidence retained below.
As-built `GeomL3.get_S_wet_{wing,HT,VT}` use Brandt's uniform-tc formula
(`GeomL2.compute_wet_planform`, `[Brandt Geom!B13]`) because the L3 tier had no root/tip t/c split.
Locked decision 6 **adds** the T.O. root/tip splits at L3, so Roskam Vol. II Eq. 12.1
(`compute_roskam_planform`) — L2's declared "official" formula — becomes available at the
higher-fidelity tier. The plan does not say which L3 uses. Computed live both ways:

| Surface | Roskam Eq. 12.1 | Brandt uniform-tc (root/tip mean) | Brandt GT | Roskam vs GT | Brandt-form vs GT |
|---|---|---|---|---|---|
| Wing | 396.3767 | 392.0205 | 392.0204 `Geom!B14` | +1.11 % | +0.00 % |
| HT | 101.3880 | 99.7793 | 99.5848 `Geom!B16` | +1.81 % | +0.20 % |
| VT | 83.1399 | 81.7213 | 81.6894 `Geom!B17` | +1.78 % | +0.04 % |

**Why it matters:** these feed L3 aero's `S_wet_comp` and hence the whole Raymer Eq. 12.24 buildup,
so the choice moves every L3 CD0 number in the aero comparison report. The Brandt-form matches GT
better *by construction* (it is Brandt's own formula on Brandt's own inputs) — that is not evidence
it is the better model. **Flagged for the gate; not decided.** Also note the L3 total `S_wet` excluding
the duct (1330.04) lands within −0.08 % of Brandt's corrected whole-aircraft 1331.134 — this is
**coincidence** (Brandt's total also carries strake 39.956 and nacelle 41.515 terms this framework has
no component for, offset by our larger 47.5 ft fuselage) and must not be reported as agreement.

### §9 — Brandt `Main!H27` VT trailing-edge sweep is a hardcoded 0, contradicting his own VT planform
Live: row 27 is labelled `TE Sweep`. `Main!B27` = −0.00024343 with formula `=Geom!N45`;
`Main!C27` = −0.00024343 with formula `=Geom!N122` — both live *formulas*, both reproduced by our
`GeometryBase.convert_sweep(40, 3, 0.2275, 1.0)` = **−0.0002°** (computed live), an independent
positive control for the mirrored sweep identity. But **`Main!H27` = 0 is a bare literal**, no
formula.

Brandt's own VT planform (`S_vt` = 60, `AR_vt` = 1.6, `lambda_vt` = 0.5, `Λ_LE` = 40) implies a TE
sweep of **22.9008°** — exactly what Phase 1b's new `convert_sweep_panel` returns, and independently
checkable from the VT chords in `readme_geom.md` §4.3 (c_root 8.165, c_tip 4.082, b_vt 9.798). So the
Phase-1b fix is **corroborated by Brandt's geometry** and contradicted only by this literal 0, which
looks like an unfilled input cell rather than a computed value.

**Logged so that nobody later "corrects" the framework's 22.90° back to Brandt's 0.** No action
needed unless someone wants the VT row to have a real formula like the wing/HT rows. **Flagged.**

### §10 — `f16a_ground_truth.json` `.geometry._comment` is stale
Line 7 states: *"for the Geometry deep-dive's later comparison-report script to check computed L1/L2
toolbox output against (Geometry's L3 tier was eliminated 2026-07-22 …)"* and *"These are NOT toolbox
inputs (see examples/F16A/geometry_L*.json for those)"*. Both clauses are wrong now: (a) the L3 tier
was reinstated 2026-07-24 and becomes the full tier in Phase 2, so the report gains an L3 column;
(b) `geometry_L*.json` **no longer exists** — inputs live in the unified `f16a_L{1,2,3}.json`.
The `.nacelle._note` (line 44) carries the same "L3-elimination" claim. Documentation-only;
**flagged for the Phase-2g stale-claim sweep.**

### §11 — `docs/` and `CLAUDE.md` still assert "Geometry has no L3"
Not a `VnV` internal disagreement, recorded here for completeness because it is the same
stale-claim sweep: `CLAUDE.md:107` (the "2026-07-22 exception"), `docs/PLAN.md:66,94,96,107`,
`docs/weights_parameter_usage.md:23`, and `aerodynamics_brandt_comparison.m:57-58`
("geometry has no separate L3 tier"). `docs/geometry_parameter_usage.md:5-8,93` said "being built /
NOT yet implemented" and **was corrected in this pass** (it is built and green). **Flagged.**

### §12 — Reuse gaps: no shared static for `Amax` or for the nacelle-diameter formula
Phase 2b's instruction is "reuse validated `GeomL2`/`GeometryBase` statics — no new equation where an
L2 one exists". Every member L3 aero needs has one **except two**:
1. **`Amax`** — nothing computes a max cross-section anywhere (see §4).
2. **Nacelle diameter** — `sqrt(T_AB_SLS_lb/1900)` exists **only as an inline expression** inside
   `F16GeomL2.get.D_inlet` (`examples/F16A/F16GeomL2.m:378`), not as a named static. Copying the
   literal `1900` into `F16GeomL3` would duplicate an uncited magic number across two tiers.
   Suggest extracting `GeomL2.compute_nacelle_diameter(T_AB_SLS_lb)` carrying the
   `[Brandt Engn(s) D_nac; readme_geom.md §3]` citation once. **Flagged; not decided.**

### §13 — `src/base/GeometryBase.md` was not updated for Phase 1b's `convert_sweep_panel`

**RESOLVED (2026-07-26, documentation-lag sweep — see the 2026-07-26 section, §D-1).** Both halves
are done: the "Concrete static utilities" table now carries `convert_sweep_panel` (2/AR) alongside
`convert_sweep` (4/AR), and the missing heading the code pointed at now exists — the new section is
titled **"Sweep-angle conversion — mirrored vs. single-panel"**, so `GeometryBase.m`'s citation notes
resolve. It records the derivation of both coefficients and the 0.33°→22.90° VT defect that motivated
the split. Original evidence below.

Phase 1b added `GeometryBase.convert_sweep_panel` (the single-panel `2/AR` form) and repointed the
three VT call sites. The companion doc's "Concrete static utilities" table (`GeometryBase.md:32-42`)
still lists **only** `convert_sweep`, so the doc now understates the API and does not record the
mirrored-vs-single-panel distinction that the VT sweep fix turns on. `GeometryBase.m:115-120` also
points readers at *"GeometryBase.md's 'Sweep-angle conversion' section"* — there is no section with
that heading in the file. Small Phase-1 documentation leftover, outside this pass's assigned
deliverables. **Flagged for assignment.**

### §14 — `GroundTruth/Brandt-F16-A.xls` shows as MODIFIED in git — DATA VERIFIED INTACT (2026-07-25); hygiene item still open
`git status` at the start of this session already reported
`M air_vehicle_design/sizing/VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls` — i.e. the ground-truth
workbook carries an uncommitted local change made **before** this pass. (`f16a_ground_truth.json` and
`todo.md` are also modified, which is expected; the `.xls` is not.) This pass opened the workbook
strictly read-only (`Workbooks.Open(path, [], true)`) and closed with `Close(false)`, so it did not
contribute.

**VERIFIED INTACT (coordinator, 2026-07-25):** the working-tree workbook was compared against
`git show HEAD:` on **all seven tabs this repo cites** — `Main`, `Geom`, `Aero`, `Wt`, `Engn(s)`,
`Consts`, `Miss` — using `readmatrix`. **Every numeric cell is identical.** The binary differs only in
Excel metadata (the file was touched 2026-07-21 and never committed). **Conclusion: every cell
citation in this file, and every live-read value in the 2026-07-25 Phase-2 documentation, is safe.**

**Still OPEN as a hygiene item for the user:** decide whether to `git restore` the binary or commit it,
so the ground-truth artifact stops showing as dirty. Do not restore it unilaterally — the data is
verified equivalent either way, so there is no urgency and no correctness risk.

### §15 — The same fuselage depth is keyed `max_height_ft` at L2 but `max_depth_ft` at L3
Logged by the `io` agent during the Phase-2 JSON pass (2026-07-25), at the coordinator's instruction;
**deliberately not fixed in this pass** — out of the assigned scope, and unifying it edits
`F16GeomL2`'s constructor.

One physical quantity, two key spellings across two input files:
- `examples/F16A/f16a_L2.json` `.geometry.fuselage.max_height_ft` = 5.0 → read at
  `examples/F16A/F16GeomL2.m:221` as `obj.H_max_fuselage`.
- `examples/F16A/f16a_L3.json` `.geometry.fuselage.max_depth_ft` = 5.0 → read at
  `examples/F16A/F16GeomL3.m:140` as `obj.H_max_fuselage`.

Both land on the **same property name** `H_max_fuselage`, with the same value and the same citation
(`[Brandt Main!D32]`; T.O. 1F-16A-1 cross-section). So the divergence is purely in the JSON key
spelling, and it is a live trap for anyone writing shared JSON-reading or schema-validation code
across the two levels, or hand-editing one file from the other as a template. Note also that
`VnV/BrandtF16A/BrandtGeometry.m` / `BrandtWeight.m` read `fuselage.max_height_ft` from the
read-only `GroundTruth/f16a_geometry.json`, so `max_height_ft` is the spelling with the wider
existing footprint — but `max_depth_ft` is the less ambiguous name, since `geom.D_fus` = `(W+H)/2`
= 6.0 is a *diameter* and this 5.0 is the Raymer Eq. 15.4 structural **depth** (the naming clash
already logged at 2026-07-24 GeomL3 §5).

**Action requested:** pick one spelling and unify in a later pass (it touches `F16GeomL2.m:221`,
`F16GeomL3.m:140`, both `f16a_L{2,3}.json`, and — if `max_height_ft` is dropped — the read-only
`VnV` replica readers would need checking, though `f16a_geometry.json` itself is a separate input
file and need not change). **Not resolved.**

### §16 — ★ Sub-step 2h: what an AREA-RULED `Amax` actually requires — three OPEN user decisions ★

**Context.** The interim `Amax = (π/4)·W_max·H_max` = 27.488936 ft² shipped into the L3 tier is,
per `readme_geom.md` §7's own fidelity table, the **LOW-fidelity** definition ("Cylindrical
fuselage only") placed in the finest tier, while Raymer Eq. 12.44's Sears-Haack term wants the
**high-fidelity** whole-aircraft area-ruled maximum ("Full component buildup — wing + tail +
nacelle added"). Locked user decision 2026-07-25: **area-ruled buildup at L3, envelope ellipse
retained at L2.** This entry scopes the buildup before anything is built. **Docs only — no `.m`,
no `.json` was edited.** All numbers below computed live 2026-07-25 via
`mcp__matlab__evaluate_matlab_code` against `BrandtGeometry.brandtCSArea` /
`BrandtGeometry.frameCrossSection` and a fresh `F16GeomL3(f16a_spec_path(3), F16PropL2(...))`;
Brandt cell formulas re-read live over Excel COM (read-only, closed without saving).

#### §16.1 — Minimal new-input list

**DERIVABLE from what L3 already carries — verified, NOT new inputs.** Checked rather than assumed:
- `c_exp_root` per surface = `c_root − (f/hs)·(c_root − c_tip)`. This is the exact expression already
  living as a *local variable* inside `GeomL2.compute_S_exposed_horizontal` (`:299`) and
  `_vertical` (`:323`) — it is computed but never returned. Live check from L3's own inputs:
  wing **13.3564** (Brandt `Geom!F7` = 13.3564, exact), VT **7.1233** (Brandt `Geom!F10` = 7.1233,
  exact), HT **6.7315** vs Brandt's 6.8391 (−1.57 %, purely L3's Decision-1 span 18.5 vs 18.0 —
  an intentional divergence, not an error). → needs a new **static** (`compute_c_root_exposed`,
  or refactor the two existing statics to return it) but **no new input**.
- `G_hs_exp` = `b/2 − W_max/2` (horizontal) / `b_vt − H_max/2` (vertical): live **11.5000 / 5.7500 /
  7.2980** vs Brandt 11.5 / 5.5 / 7.298.
- `c_tip`, `Λ_LE`, `t/c` — already inputs or Dependent (`tc_ht` = 0.0475, `tc_vt` = 0.0415 at L3 vs
  Brandt's uniform 0.04).
- `Xexp` = `x_apex + (W_max/2)·tan Λ_LE` (horizontal) / `x_le + (H_max/2)·tan Λ_LE` (vertical), once
  the x-station input below exists. Live: **20.7228 / 38.9368 / 38.7283** vs Brandt `Geom!B7/B8/B10`
  = 20.72268 / 38.93685 / 38.09775 (the VT differs only via L3's 47.5° sweep).
- `D_engine` = existing Dependent `D_inlet` = `GeometryBase.compute_nacelle_diameter(prop.T_SL)` =
  3.5370.
- `L_engine` = `4.5 · D_engine` = 15.9166 — new **derived**, no input. Now citable to a cell:
  `Geom!D475 = C475 * 'Engn(s) Old'!Q22`, `'Engn(s) Old'!Q22 = ='Engn(s)'!R22` = **4.5** (see §18).
- Nacelle aft limit = `x_inlet + L_duct + 4.5·D_engine` — and **`L_duct` = 14.0 is ALREADY an L3
  input** (`.geometry.engine.duct_length_ft`, = `Main!F32`). So the whole nacelle extent costs
  exactly one new input.

**REQUIRED NEW `.geometry` inputs — 4 x-stations (5 with a strake):**

| # | Proposed key | F-16A value | Citation | Today lives ONLY in |
|---|---|---|---|---|
| 1 | `wing.x_apex_ft` | 17.786 | `Main!B23` (X Location); pre-computed as `x_MAC_qc − y_MAC·tan Λ_LE` per `readme_geom.md` §2 | read-only `GroundTruth/f16a_geometry.json` `wing.x_apex_ft` |
| 2 | `horizontal_tail.x_le_ft` | 36.0 | `Main!C23` (live-read 2026-07-25, §3 of this section) | read-only `f16a_geometry.json` `pitch_ctrl.x_le_ft` |
| 3 | `vertical_tail.x_le_ft` | 36.0 | `Main!H23` | read-only `f16a_geometry.json` `vert_tail.x_le_ft` |
| 4 | `engine.x_inlet_ft` | **15.0, not 14.0** | `Main!F31` ("Inlet(s):"), live-verified — see §18 | read-only `f16a_geometry.json` as `inlet_entry_x_ft` = 15.0 (the `inlet_x_ft` = 14.0 key is MISLABELLED, §18) |
| 5 | `n_engines` | 1 | `Main!B28` | **nowhere** — `F16PropL2` exposes `engine_type, T_SL, T_SL_wet, T_SL_mil, T_t4_max_F, TSFC_install_factor, TR` and **no engine count**, so this is a new input or a new propulsion DI member |

**REQUIRED NEW INPUT — the fuselage cross-sectional-area distribution `A_fuse(x)`. This, not the
x-stations, is the real cost, and nothing in the framework has it.** L3 carries three fuselage
numbers (`L_fus` 47.5, `W_max` 7.0, `H_max` 5.0) and no distribution. Brandt's `Amax` is
`MAX` over 20 stations of `A_fuse + A_wing + A_pitch + A_vert + A_strake + A_nac`, and **`A_fuse`
supplies 52.7 % of the governing station's total** (17.3628 of 32.9711 at x = 29.1 ft). Options,
all computed live:

| Variant | `A_fuse(x)` source | new numbers | `Amax` (`/5`) | vs Brandt GT 25.110556 | L3 opt T/W |
|---|---|---|---|---|---|
| **A** | Brandt's 20-frame table, verbatim, MAX over the 20 stations | 20 × (x,w,h,z_chine,z) = **100** | **25.110534** | **−0.000 %** | 1.019642 |
| **A′** | same table, but MAX on a fine grid (0.02 ft) with linear interpolation | 100 | 25.585933 | +1.89 % | 1.044214 |
| **B** | constant `(π/4)·W·H` = 27.4889 over `L_fus` (the only thing derivable from the 3 existing inputs) | **0** | 35.367100 | **+40.85 %** | **1.652106 (worse)** |
| **B′** | constant `2·W·H/π` = 22.2817 (Brandt's cosine section shape at max W,H) | 0 | 30.159800 | +20.11 % | **1.304192 (worse)** |
| **D** | frame table stored **NORMALIZED** (`x/L_fus`, `w/W_max`, `h/H_max`, `z/H_max`) so the envelope inputs rescale it | 20 × 4 = **80** | **24.703652** | −1.62 % | **0.998975** |

**Variant B/B′ is the headline warning: a parametric constant-section fuselage — the only path that
adds zero inputs — makes `Amax` WORSE than the interim envelope ellipse (35.37 / 30.16 vs 27.49),
and pushes the L3 constraint optimum FURTHER out of bounds (1.65 / 1.30 vs today's 1.147).** There
is no cheap version of this. An area-ruled `Amax` requires a real fuselage area distribution.

**Variant D positive control:** with `L_fus` set back to Brandt's 46.5, variant D reproduces
**25.110534** — bit-identical to variant A and −0.000 % vs the live `Geom!B20`/`H47`. Normalising and
de-normalising by the same envelope is an identity, so this is a genuine round-trip check, not a fit.

#### §16.2 — The strake problem: quantified, and the framing premise is FALSIFIED

The task framing stated that omitting the strake "cannot reproduce ~25.11". **That is not what the
numbers show.** Computed live, both at Brandt's own 20 frame stations and on a 0.02-ft fine grid:

| Strake treatment | raw `MAX` | `Amax` (`/5`) | Δ vs strake OUT |
|---|---|---|---|
| strake **OUT** (no strake component at all) | 32.971129 | **25.110534** | — |
| strake **IN**, Brandt's two bugs replicated | 32.971129 | **25.110534** | **0.000000 ft² (0.000 %)** |
| strake **IN**, bugs corrected | 32.971129 | **25.110534** | **0.000000 ft² (0.000 %)** |

**Cause:** the strake's active range is `12.000 < x < 21.551` ft, and the governing station is
x = 29.1 ft (frame 12; fine-grid peak x ≈ 30.3 ft). The strake's cross-section is **exactly zero**
there. Its own peak contribution is 0.6097 ft² (bugged) / 0.4354 ft² (corrected) — a factor 1.40
apart — but it is never at the max. Peak whole-aircraft total *inside* the strake's range is
32.5552, **2.67 % below** the global peak 33.4465 (fine grid), or 1.25 % below at frame stations.

So: **the strake is worth 0.000 % of `Amax` for the F-16A, and omitting it still reproduces 25.11
exactly.** What a strake component WOULD buy is unrelated to `Amax`: it closes the two rows
`geometry_brandt_comparison.m:117,132` reports as "NOT MODELED" — strake `S_wet` = 39.956
[`Brandt Geom!B15`] and strake exposed area = 20.0 [`Brandt Geom!9`] — at a cost of **7 new inputs**
(`S_ft2` 20, `AR` 1.5, `taper` 0, `sweep_LE_deg` 74, `tc_ratio` 0.04, `x_le_ft` 12.0, `y_root_ft`
2.0, all `Main!D18:D24`) plus the "root is fully outside the fuselage → `S_exposed` = `S_ref`" special
case (`readme_geom.md` §4.3).

**Caveat that must not be lost:** the 2.67 % margin is *configuration-dependent*, not structural.
Under optimizer mutation (wing moved aft, wing shrunk, inlet moved) the max station could migrate
into the strake's range, at which point the strake matters and its absence becomes a silent error.
**Recommend, not resolve:** add the strake as a component — justified by the two NOT-MODELED rows
and by removing the configuration-dependence, **not** by any `Amax` benefit, which is nil.

#### §16.3 — Brandt's documented strake BUG: replication is numerically FREE to decline

`readme_geom.md` §5.1 records two bugs in the strake column. **Both confirmed verbatim against the
live workbook this pass** (`Geom!AG31`, formula read over COM):
`=IF(C31>B$9, IF(C31<B$9+MAX(F$9,G$9*TAN(Main!D$21/57.29578)+D$9), (Main!D$22/100-INT(Main!D$22/100))*((F$9+D$9)*MIN(G$9,(C31-B$9)/TAN(Main!D$21/57.29578))*(1-(COS((C31-B$8)/MAX(F$9,G$9*TAN(Main!D$21/57.29578)+Geom!D$9)*2*3.141579)))), 0), 0)`
— the active-range test correctly uses `B$9` (strake `Xexp` = 12.0) while the **cosine argument uses
`B$8`** (pitch-ctrl `Xexp` = 38.937) ✓ bug 1; and there is **no trailing `/2`**, unlike the wing
column `Geom!Y31` which ends `...)/2` ✓ bug 2. (`readme_geom.md` §5.2's VT bug is also confirmed:
`Geom!AC31`'s range test uses `Geom!D$7` = wing tip chord while its cosine denominator uses
`Geom!D$10` = VT tip chord. Note the VT column applies its `/2` to the chord sum, `(F$10+D$10)/2*…`,
rather than at the end — mathematically identical, not a third bug.)

**The trade-off the framing anticipated does not exist.** Per §16.2, replicating the bug and
correcting it give **the identical `Amax` = 25.110534**, so:
- Replicating: reproduces 25.11 **and** knowingly encodes a documented error into the framework's
  own from-scratch implementation — the exact thing CLAUDE.md forbids for `temp_Casey` bugs.
- Not replicating: **also** reproduces 25.11, to 0.000 %, and encodes no error.

**Recommend: do NOT replicate either strake bug.** There is no cost. This is still logged as a user
decision, not resolved here — but it is a decision with a free correct answer.
(If a strake component is added, the corrected column must be used and the comparison report should
carry the bugged value as a labelled alternate row, the same pattern L2 already uses for Brandt's
uniform-t/c `S_wet` form.)

#### §16.4 — `/5` vs `/4`

See the appended **UPDATE 2026-07-25 (sub-step 2h)** paragraph on **§5** above: live-verified that
the workbook contains no justification for `/5` anywhere; `/5` → 25.110534, `/4` → 23.145385
(−7.82 %), `CD0_wave` −15.04 %, L3 opt T/W 1.0196 → 0.9230; and under `/4` the nacelle nets exactly
zero, which makes `Amax` completely thrust-insensitive. **User decision. Not resolved.**

#### §16.5 — Optimization liveness: the honest answer is "barely, and one term has the WRONG SIGN"

Verified live by perturbing each input +10 % and recomputing the buildup (variant A, Brandt's frame
table frozen, `/5`, strake out; baseline `Amax` = 25.110534):

| Design variable | +10 % → Δ`Amax` | Verdict |
|---|---|---|
| `LE_sweep_wing` | **+8.682 %** | live |
| `S_ref` | +5.650 % | live |
| `tc_wing` | +2.303 % | live |
| `AR_wing` | +2.245 % | live |
| `lambda_wing` | +1.247 % | live |
| `prop.T_SL` (→ `D_inlet`) | +0.783 % | live under `/5`; **0.000 % under `/4`** |
| `W_max_fuselage` | **−0.561 %** | ★ **WRONG SIGN** |
| `H_max_fuselage` | **0.000 %** | ★ **DEAD** |
| `S_ht`, `B_h`, `S_vt`, `tc_ht` | **0.000 %** each | **DEAD** |

Read plainly: with a **frozen** frame table, an area-ruled `Amax` tracks the **wing planform only**.
The fuselage depth is inert. A wider fuselage *reduces* `Amax` — because `W_max` enters only through
the exposed-root-chord clip (`fw = W/2` eats more wing root → smaller `A_wing`), while the
physically dominant effect (a wider fuselage has a larger cross-section) is entirely absent, since
the frame table's own `w`/`h` columns are frozen constants. **Every tail variable is dead**, because
the HT/VT cross-sections only exist aft of x ≈ 38.7–38.9 ft and the governing station is x ≈ 29.1.
The x-stations themselves would be frozen inputs, not design variables, so max-station migration is
driven only by planform growth.

For contrast, the interim envelope ellipse is live in exactly the complementary set: `W_max` +10 % →
`Amax` +10 %, `H_max` +10 % → +10 %, everything else 0.000 %. **Neither candidate is fully live.**

**Variant D (normalized frame table) is the only option checked that is live in the right direction
everywhere it should be:** `W_max` +9.164 %, `H_max` +9.164 % (identical, correctly — the cosine
frame area is ∝ `w·h`), `L_fus` +12.478 %, `S_ref` +4.184 %, `LE_sweep` +7.289 %, `T_SL` +0.795 %;
tails still 0.000 % (a genuine geometric fact for this configuration, not a modelling defect).
Its un-cited element is the **affine-scaling assumption** (a fixed normalized cross-section shape
distribution scaled by the envelope), which has no textbook citation — the same class of gap as the
envelope-ellipse identity in §4, and it must be stated as such, not glossed. It also means the
frame table's canopy bulge (max `h/H_max` = **1.50**, frame 6) scales with fuselage depth.

#### §16.6 — Expected values: every combination, with its downstream consequence

`CD0_wave` per Raymer Eq. 12.44 + 12.45 at M = 1.6, Λ_LE = 40°, `E_WD` = 2.2, `S_ref` = 300,
`l` = `L_aircraft` = 47.65 (framework input). Reference column = Brandt's own pair
(`Amax` 25.110556, `l` 48.303947) → `CD0_wave` = 0.025052. L3 optimum from
`F16ConstraintSet.build("L3")` + `ConstraintAnalysis(…, WS_RANGE_BRANDT).optimal_point()`, with the
`Amax` change emulated **exactly** by the identity `CD0_wave ∝ E_WD·(Amax/l)²` (`W/S` optimum stays
62.00 psf in every case; the binding constraint is Max Mach). Test bound is T/W ≤ 1.1.

| Option combination | `Amax` [ft²] | vs Brandt GT | `CD0_wave` | vs ref | L3 opt T/W | ≤ 1.1 |
|---|---|---|---|---|---|---|
| **CURRENT interim** envelope ellipse `(π/4)·W·H` | 27.488936 | +9.47 % | 0.030853 | +23.15 % | **1.147199** | ✗ **FAIL** |
| A · strake OUT · `/5` | **25.110534** | −0.000 % | 0.025745 | +2.76 % | 1.019642 | ✓ |
| A · strake IN, bug replicated · `/5` | **25.110534** | −0.000 % | 0.025745 | +2.76 % | 1.019642 | ✓ |
| A · strake IN, bug corrected · `/5` | **25.110534** | −0.000 % | 0.025745 | +2.76 % | 1.019642 | ✓ |
| A · any strake option · `/4` | **23.145385** | −7.83 % | 0.021873 | −12.69 % | 0.922951 | ✓ |
| A′ fine grid · any strake · `/5` | 25.585933 | +1.89 % | 0.026729 | +6.69 % | 1.044214 | ✓ |
| A′ fine grid · any strake · `/4` | 23.620784 | −5.93 % | 0.022781 | −9.07 % | 0.945620 | ✓ |
| **D** normalized frames · strake OUT · `/5` | **24.703652** | −1.62 % | **0.024917** | **−0.54 %** | **0.998975** | ✓ |
| B constant-ellipse fuselage · `/5` | 35.367100 | +40.85 % | 0.051071 | +103.86 % | 1.652106 | ✗ FAIL |
| B′ constant-cosine fuselage · `/5` | 30.159800 | +20.11 % | 0.037139 | +48.25 % | 1.304192 | ✗ FAIL |

`E_WD` that would exactly preserve the Brandt-referenced wave term, **recorded and DELIBERATELY NOT
APPLIED** (do not silently retune `E_WD` to absorb an `Amax` definition change — the `f16a_L3.json`
`_amax_via_DI` note already says so): envelope ellipse **1.7864**; A/`5` 2.1408; A/`4` 2.5198;
A′/`5` 2.0620; A′/`4` 2.4194; B 1.0792; B′ 1.4840. **Variant D needs no retune at all** — `E_WD`
= 2.2 unchanged lands within −0.54 % of the Brandt-referenced wave term. That is the concrete sense
in which the locked decision's premise ("`E_WD` = 2.2 stays valid because the quantity it was tuned
against is restored") holds — for variants A and D, not for B/B′.

**Three OPEN user decisions in this sub-step, none resolved here:** (i) strake in or out;
(ii) replicate Brandt's strake bug or not; (iii) `/5` or `/4`. Plus the implicit fourth that this
scoping surfaced and that the plan never named: **(iv) which fuselage `A_fuse(x)` variant (A, A′, D,
or B/B′) — the choice with by far the largest numeric consequence of the four.**

### §17 — ★ DEFERRED RED TEST: `TestF16ConstraintSet/testOptimalPointWithinPhysicsBounds(L3)` ★ — ✅ RESOLVED (2026-07-25)

**✅ RESOLVED 2026-07-25 (scribe, verified live). The test is GREEN.** Recorded here exactly as the
final bullet of this entry instructed — "if a future pass sees this test green, that is a
consequence of the `Amax` fix and should be recorded here as such, not silently forgotten."

- **Live measurement, re-run this pass** against the as-built classes:
  `cs = F16ConstraintSet.build("L3")`, `ConstraintAnalysis(cs, PointPerformanceBase.WS_RANGE_BRANDT)`
  → **W/S = 62.0000 psf, T/W = 0.998975**. `tests/constraints/TestF16ConstraintSet.m` is 15/15.
- **Cause of the fix:** sub-step 2h's area-ruled `Amax` = 24.703652, which brings the Raymer
  Eq. 12.44 term to **−0.54 %** of the Brandt-referenced value instead of +23.15 %. Matches §16.6's
  variant-D prediction (0.998975) to six decimals — a prediction made *before* implementation, so
  this is a genuine confirmation, not a post-hoc fit.
- **The bound was NOT widened again**, and `E_WD` was NOT retuned. Nothing was changed to make this
  pass.
- ★ **NEW OPEN USER DECISION spawned by this resolution: the earlier 1.0 → 1.1 widening is now
  retrospectively unnecessary** — 0.998975 satisfies the **ORIGINAL 1.0** bound, exactly as the
  "Expected to clear itself" bullet below anticipated for variant D. Whether to narrow
  `TestF16ConstraintSet.m:188` back to 1.0 is a **user decision**. **It was NOT narrowed and no test
  file was touched.** Note the margin at 1.0 is only 0.1 %, so narrowing makes the test sensitive to
  any later `Amax`/`E_WD`/drag change — that trade-off is the substance of the decision.

**Original entry retained below in full — nothing deleted.**

**Logged at explicit user instruction (2026-07-25). This is a TRACKED DEFERRED item, not a bug to
be fixed and not a bound to be widened.**

- **Failing assertion:** `tests/constraints/TestF16ConstraintSet.m:188`,
  `verifyLessThanOrEqual(TW_opt, 1.1)`. Live-measured this pass: L3 optimum **W/S = 62.00 psf,
  T/W = 1.147199** → fails by +4.29 %.
- **Sole cause:** the **+23.15 %** wave-drag term produced by the interim envelope-ellipse `Amax`
  (`(Amax/l)²` moved from `(25.110556/48.303947)²` = 0.270239 to `(27.488936/47.65)²` = 0.332805).
  Verified by emulation: restoring the Brandt-referenced wave term drops the optimum to
  **T/W = 1.019643** with no other change. The binding constraint is Max Mach (M = 1.6 dash);
  every other constraint at W/S = 62 is ≤ 0.871.
- **The bound has ALREADY been widened once, 1.0 → 1.1** — see the in-test comment
  (`TestF16ConstraintSet.m:181-186`), which records the earlier justification ("at L3 the Max Mach
  … puts the optimum at T/W ~ 1.001 — physically plausible for a fighter … marginally over the
  round-number 1.0 ceiling"). **Widening it a second time was EXPLICITLY DECLINED by the user
  (2026-07-25).** Do not raise it to absorb this failure.
- **Rationale for deferral:** constraint analysis is de-scoped until geometry / aero / prop /
  weights are complete, so the user chose to leave the test red rather than move the physics bound
  to fit a known-wrong input.
- **Expected to clear itself when the area-ruled `Amax` lands** — computed live: variant A/`5` →
  1.019642 ✓, variant A/`4` → 0.922951 ✓, variant A′ → 1.044214 ✓, **variant D → 0.998975 ✓ (which
  would also satisfy the ORIGINAL 1.0 bound, making the earlier 1.0 → 1.1 widening retrospectively
  unnecessary)**. It will **NOT** clear under variants B/B′ (1.652 / 1.304 — worse than today).
- **It must stay logged either way.** If a future pass sees this test green, that is a consequence
  of the `Amax` fix and should be recorded here as such, not silently forgotten; if it is still red,
  it is still deferred, not new.

### §18 — Nacelle x-range, `Geom!H3` semantics, and the `1900` magic number: replica + `readme_geom.md` vs the LIVE workbook

**New discrepancy, live-verified 2026-07-25 over Excel COM.** Three linked items. Numerically
harmless *for the F-16A's 20 frame stations* (see below), which is exactly why it has gone unnoticed
— but the framework's area-ruled buildup would evaluate on its own grid, where it stops being
harmless.

**(a) The nacelle active x-range is `[15.0, 44.9166]` live, not `[14.0, 43.9166]`.**
Live formula chain:
```
Geom!AE31 = IF(C31>=C$480, IF(C31<=C$484, Main!B$28*3.1416/4*C$475^2, 0), 0)
Geom!C480 = =Main!F31                = 15.0      (Main!E31 label = "Inlet(s):")
Geom!C482 = =C480+Main!F32           = 29.0      (Main!E32 label = "Compr Face"; Main!F32 = 14.0)
Geom!C484 = =C482+D475               = 44.9166   (D475 = L_engine = 15.9166)
```
i.e. **nacelle start = inlet station; nacelle end = (inlet + duct length) + engine length** — a
coherent physical chain: inlet lip → compressor face → nozzle.
Against this, `BrandtGeometry.nacelleFrameArea` (`:1232-1236`) uses `x_in = engine.inlet_x_ft` =
**14.0** and `x_noz = inlet_x + nozzle_x` = **43.9166**, and `readme_geom.md` §4.5 states
"*Active from inlet_x (14.0 ft) to inlet_x + nozzle_x (43.917 ft)*". Both endpoints are **1.0 ft low**.
Further, `BrandtGeometry.m:1228-1230`'s explanatory comment — "*The nacelle cylinder end is NOT at
H3 = 29.917 ft, but at inlet_x + H3 = 43.917 ft. H3 is the nozzle x-position from the nose; the
nacelle cross-section extends another inlet_x beyond that*" — is a **misreading**: the live formula
is `C482 + D475`, not `inlet_x + H3`. There is no "double-counting of `inlet_x`"; the two happen to
land 1 ft apart only because `Main!F32` (duct length, 14.0) numerically equals the value the
replica's JSON calls `inlet_x_ft`.

**Root cause — a mislabelled key in the read-only ground-truth JSON.**
`GroundTruth/f16a_geometry.json` `engine` block carries `inlet_x_ft: 14.0`,
`inlet_entry_x_ft: 15.0`, `duct_length_ft: 14.0`. Live: `Main!F31` = **15.0** is the inlet
x-station and `Main!F32` = **14.0** is the duct length (inlet → compressor face). So
**`inlet_x_ft` = 14.0 is not an x-station at all — it is the duct length**, and the genuine inlet
station is the key currently named `inlet_entry_x_ft` = 15.0. `BrandtGeometry` then consumes
`inlet_x_ft` as though it were an x-station.

**Numeric impact for the F-16A: exactly zero.** Verified live — both ranges produce the *identical*
mask over Brandt's 20 frame stations (frame 5 at x = 13.5 is excluded by both; frame 6 at x = 15.0
is included by both, `>=` boundary; frame 18 at 43.65 included by both; frame 19 at 46.075 excluded
by both), so raw `MAX` = 32.971129 and `Amax` = 25.110534 either way, and on a 0.02-ft fine grid
also identical (33.446528). Pure luck of the frame spacing. **This is why it matters for sub-step
2h:** the framework must be told which chain to implement, and only the live one is defensible.

**(b) `readme_geom.md` §3's `nozzle_x` formula has the wrong semantics** (right number, wrong
derivation). §3 states `nozzle_x = inlet_x + L_engine = 14.0 + 15.917 = 29.917 ft [Geom H3]`.
Live: **`Geom!H3 = =D475+Main!F32`** = `L_engine + duct_length` = 15.9166 + 14.0 = 29.9166. Same
number only because the JSON's mislabelled "`inlet_x`" 14.0 *is* `Main!F32`. `Geom!G3`'s label is
"Length", consistent with `H3` being a length, not an x-station — which also means §3's
cross-tab table entry "*H3 | 29.917 ft | Nozzle x = inlet_x + L_engine*" mislabels `H3` as an
x-position.

**(c) The `1900` magic number is now citable to a cell — and the framework's unconditional use of
it silently assumes an afterburning engine.** Live:
```
Geom!C475 = =IF(Main!C29=Main!D29, (Main!D29/'Engn(s)'!L10)^0.5, (Main!D29/'Engn(s)'!L22)^0.5)
'Engn(s)'!L10 = 2000     ('Engn(s)'!K10 label = "  ( TslDry / ")
'Engn(s)'!L22 = 1900     ('Engn(s)'!K22 label = "  ( TslAB / ")
```
So `D_engine = sqrt(T_AB / 1900)` **only when `T_dry ≠ T_AB`** (an AB engine); for a
non-afterburning engine (`T_dry = T_AB`) Brandt divides by **2000**. `GeometryBase.compute_nacelle_diameter`
(`:211-226`) hardcodes 1900 unconditionally and cites only "`[Brandt … Engn(s) tab, D_engine;
readme_geom.md Section 3]`". Two improvements available: cite the actual cells
(`Geom!C475`; `Engn(s)!L22` = 1900 AB / `L10` = 2000 dry), and either add the dry branch or state in
the docstring that the static is AB-engine-only. Also note `Geom!D475 = C475 * 'Engn(s) Old'!Q22`
reads the **`Engn(s) Old`** sheet (`Q22 = ='Engn(s)'!R22` = 4.5), whereas `readme_geom.md` §3 cites
`Engn(s)` — a stale-sheet indirection worth recording, since `Engn(s) Old` is a *different sheet*
(workbook sheet 8 vs 9, per the 2026-07-24 propulsion Entry B live read).

**Positive controls found in the same read (recorded so nobody re-verifies):** the live cosine
column formulas independently corroborate two already-RESOLVED items — the surface columns read
sweep from `Main!B$21`/`C$21`/`D$21`/`H$21` (**row 21 = sweep** ✓ §1) and t/c from
`(Main!B$22/100 − INT(Main!B$22/100))`, i.e. the fractional part of the **row-22 NACA 4-digit**
designation (1404 → 0.04) ✓ §2. **Flagged, not resolved.**

### §19 — `readme_geom.md` §7's LOW-FIDELITY `Amax` row has no cell backing, and its wording differs from what was built

`readme_geom.md` §7's fidelity table asserts, for `Amax`: low fidelity = "**Cylindrical fuselage
only**", high fidelity = "**Full component buildup** — wing + tail + nacelle added". The
high-fidelity side is fully cell-backed (`Geom!H26:H45` → `H47` → `B20`). The low-fidelity side is
**not**: a live read of `Geom!A1:D25` shows **exactly one** `Amax` in the entire results block —
`A20` = "Total Aircraft Amax:", `B20` = 25.11056 with formula `=H47`. There is **no second,
low-fidelity `Amax` cell anywhere in the workbook**. So §7's low-fi entry is a *conceptual* fidelity
statement, not a documented Brandt quantity — unlike every other row of that table, each of which
names a real cell (`Geom!B3` / `D23`, etc.).

Secondary, and relevant to §4: §7 says "**cylindrical**", which reads as `π·(D_fus/2)²` = π·3.0² =
**28.2743**, whereas what was built is the **elliptical** `(π/4)·W·H` = **27.4889** (−2.78 %
apart). Neither has a cell or an equation number. So the interim `Amax` is not even the same
low-fidelity formula §7 describes. **Documentation-only; flagged for the stale-claim sweep and for
the §4 citation decision. Not resolved.**

---

## 2026-07-25 — Sub-step 2h implementation (area-ruled `Amax`), equations-expert

**Context:** logged by the equations-expert at the coordinator's explicit instruction while
implementing sub-step 2h (the area-ruled `Amax` scoped in §16 above). Only `.m` files in the
implementation's own scope were edited — `src/disciplines/geometry/{GeomL3,GeometryModelL3}.m` and
`examples/F16A/F16GeomL3.m`. **Nothing in `VnV/BrandtF16A` was changed** other than this appended
entry. Every number below computed live via `mcp__matlab__evaluate_matlab_code` against the
as-built classes.

### §20 — ★ NEW OPEN ITEM: the frame-area DISCRETIZATION is a modelling choice, and 6-point was taken ★

Brandt does not integrate his cosine fuselage cross-section analytically. `readme_geom.md` §4.2
samples it on **six points**, `t = [0, 0.2, 0.4, 0.6, 0.8, 1.0]`, and trapezoidally integrates the
resulting 11-point half-polygon (`BrandtGeometry.frameCrossSection`, `n_pts = 6`). Collapsing that
algebraically, the frame area is exactly

```
A = w * h * I_cos ,   I_cos = trapz(t, cos(pi/2 * t))
```

with **`I_cos` = 0.63137515 on 6 points** against the exact `int_0^1 cos(pi/2 t) dt` = **2/pi =
0.63661977**. The 6-point rule is therefore **0.824 % LOW at every frame**, uniformly — the two
differ by a pure constant factor, not a shape difference.

**DECISION TAKEN (equations-expert, per the coordinator's recommendation): replicate Brandt's
6-point discretization.** Reasons recorded:
1. Consistency with the two sibling decisions already locked in this sub-step, both of which follow
   Brandt's convention rather than the self-consistent alternative — the `/5` flow-through divisor
   (§5/§16.4) and the coarse 20-station `MAX` (§16.1, vs the finer grid of variant A′).
2. Every expected value in the sub-step 2h specification is built on it (governing-frame `A_fuse`
   17.3628, raw `MAX` 32.9711, `Amax` 25.110534 / 24.703652).
3. Neither form is "more correct" as physics — the cosine section is itself a shape model with no
   textbook source (§4), so the exact integral would be an exact answer to an approximate question.

**Numeric cost of the alternative, measured live:**

| Quantity | 6-point (as built) | exact 2/pi | Δ |
|---|---|---|---|
| `I_cos` | 0.63137515 | 0.63661977 | +0.831 % |
| `A_fuse` at the round-trip governing frame (x = 29.1, w = 5.5, h = 5.0) | 17.3628 | 17.5070 | +0.830 % |
| as-built L3 `Amax` (`L_fus` = 47.5) | 24.703652 | 24.891147 | **+0.759 %** |

(The `Amax` gap is smaller than the per-frame gap because the wing and nacelle terms are unaffected.)

**Why this is logged as OPEN rather than closed:** it is a fourth Brandt-convention-vs-self-
consistency choice of exactly the same kind as §5's `/5`-vs-`/4`, and it was never named in the §16
scoping, so it has not had a user decision. The exact form is implemented and reachable as the
**labelled alternate** `GeomL3.compute_frame_cs_area_exact`, so switching is a one-line change and
the gap stays measurable rather than asserted. **Action requested: confirm the 6-point choice, or
switch to the exact integral.** No equation number was invented for either form.

### §21 — Sub-step 2h as-built: verification record, and what it did to §16/§17/§18

Recorded so the next reader does not re-derive it. All live, 2026-07-25:

- **Round-trip control (proves the method, not a fit):** with `fuselage.length_ft` temporarily set
  to Brandt's own 46.5 (`W_max` 7.0, `H_max` 5.0), `F16GeomL3.Amax` = **25.110534** — `-0.0001 %`
  vs the live `Geom!B20`/`H47` = 25.110556, and bit-identical to §16.1's variant-A figure. The
  governing station is frame 12 at **x = 29.1000 ft**, raw `MAX` = **32.971129**, `A_fuse` there =
  **17.3628 = 52.7 %** of the total — every §16.1/§16.2 figure reproduced exactly.
- **As-built L3** (`length_ft` = 47.5): `Amax` = **24.703652**, −1.62 % vs Brandt. `CD0_wave` =
  **0.024917** vs the Brandt-referenced 0.025052 = **−0.54 %**, with **`E_WD` = 2.2 UNCHANGED** —
  §16.6's variant-D row exactly. No retune was applied, and none is needed.
- **Governing-station migration, worth recording:** at L3's own 47.5 ft length the governing station
  is **not** x = 29.1. The affine stretch moves it forward to **frame 9, x = 22.2944**, where
  `A_fuse` = 22.5717 = **69.3 %** of a raw `MAX` of 32.564247. §16.1's "17.3628 of 32.9711 at
  x = 29.1" is the **Brandt-length (variant A / round-trip)** case; it does not describe the
  as-built case, and the two should not be quoted together. `Amax` itself is unaffected — 24.703652
  is confirmed either way.
- **Liveness reproduced exactly** (+10 % on each input → ΔAmax): `W_max` +9.164 %, `H_max` +9.164 %,
  `L_fus` +12.478 %, `S_ref` +4.184 %, `LE_sweep_wing` +7.289 %, `prop.T_SL` +0.795 %; `S_ht`,
  `B_h`, `S_vt`, `tc_ht` 0.000 % each. Matches §16.5's variant-D row to three decimals.
- **§17 (DEFERRED RED TEST) HAS CLEARED — recorded here as §17 itself instructs, not silently
  forgotten.** `tests/constraints/TestF16ConstraintSet.m` is now **15/15**, and the L3 optimum is
  **W/S = 62.0000 psf, T/W = 0.998975** — matching §17's variant-D prediction to six decimals, and
  satisfying not only the widened 1.1 bound but the **ORIGINAL 1.0** bound, which makes the earlier
  1.0 → 1.1 widening retrospectively unnecessary exactly as §17 anticipated. Whether to narrow the
  bound back to 1.0 is a separate user decision; **no test file was touched.**
- **§18's live nacelle chain is what was implemented**, not the replica's: `x_inlet` = 15.0
  [`Main!F31`], aft limit = `x_inlet + L_duct + 4.5·D_engine` = **44.9166** [`Geom!C480`→`C482`→
  `C484`]. `L_engine` = 15.9166 and `D_inlet` = 3.537022 reproduce `Geom!D475`/`C475` exactly. The
  mislabelled read-only `inlet_x_ft` = 14.0 was **not** used and is flagged in-code so it is not
  "corrected" back.
- **§4 and §5 remain OPEN and are now flagged in code, not glossed.** The affine-rescaling
  assumption is isolated in `GeomL3.denormalize_frames` with a ★ UNCITED-ASSUMPTION block naming §4;
  the bare `/5` literal is isolated in `GeomL3.compute_Amax_area_ruled` with a ★ block naming §5 and
  stating the verified absence of any workbook justification. No rationale was invented for either.
- **Brandt's VT copy-paste bug (§5.2 of `readme_geom.md`) is NOT replicated**, on the same reasoning
  §16.3 gives for the strake bugs: `X_max_range` and `X_max_cos` are one expression evaluated from
  the surface's own tip chord. Numerically free — the VT section starts at x ≈ 38.73 ft, far aft of
  the governing station, so it contributes 0.000 % either way. The strake is absent entirely per the
  locked decision.
- **Test impact, for the test-writer (no test file was edited):** full suite **419/429**. The only
  non-`testTODO_*` failures are `TestGeomL3/testAmaxAndOverallLength` and
  `TestGeomL3/testAmaxTracksFuselageEnvelopeLive`, both of which assert the superseded envelope
  ellipse (`(pi/4)·W·H` and its exact `8/7` linearity in `W_max`). Both are correct-to-fail: `Amax`
  is now 24.703652, and it is deliberately **no longer linear** in `W_max` (measured 1.13108 for the
  7→8 ft step, not 8/7 = 1.14286), because widening the fuselage both grows the frame sections and
  eats more exposed wing root. `F16GeomL2.Amax` is **undisturbed at 27.488936** (verified).

---

## 2026-07-25 — Phase 2 documentation reconciliation (scribe)

**Context:** docs-only pass bringing `examples/F16A/F16GeomL3.md`, `docs/geometry_parameter_usage.md`
and `docs/weights_parameter_usage.md` to as-built after sub-step 2h, and reconciling this file's
bookkeeping. **No `.m` and no `.json` was edited.** Every number below was recomputed live via
`mcp__matlab__evaluate_matlab_code` against the as-built classes rather than copied forward, and the
Brandt cells were re-read over Excel COM (`actxserver`, read-only, `Close(false)`).

Bookkeeping applied to earlier entries, per the file's "prepend the decision, delete nothing"
convention: **§20 and §21 gained status-index rows** (the implementer appended them without index
entries); **§17 was re-statused ✅ RESOLVED** with its original evidence intact; **§4 was SPLIT into
§4a / §4b**, both still OPEN; **§14 re-confirmed** (see §24 below). Two genuinely new items follow.

### §22 — `engine.n_engines` sits in `.geometry` because nothing exposes an engine count

`examples/F16A/f16a_L3.json` `.geometry.engine.n_engines` = **1** `[Brandt Main!B28]`, read into
`F16GeomL3.n_engines` (`F16GeomL3.m:240,402`). It is **engine data in an airframe input block**, and
it is there only because no propulsion class exposes a count: `F16PropL2` exposes `engine_type`,
`T_SL`, `T_SL_wet`, `T_SL_mil`, `T_t4_max_F`, `TSFC_install_factor`, `TR` — and nothing else.
Sub-step 2h needed it for the `Amax` flow-through deduction (`Geom!H47`'s `Main!B28` factor) and for
the nacelle cross-section (`Geom!AE31`, same factor), so it was placed where it could be reached.

**Why it matters.** The Phase-2/3a work removed exactly this class of defect for engine *thrust*:
`T_AB_SLS_lb` used to be a frozen 23,770 lbf copy inside geometry and is now `Dependent` on the
injected `prop.T_SL`. `n_engines` is the same shape of problem one step behind — a twin-engine
variant would require editing the **geometry** JSON, and the geometry and propulsion objects could
silently disagree about how many engines the aircraft has, with no error and no warning.

**Action requested:** add `n_engines` to `.propulsion` / `PropulsionBase`, and have geometry read it
off the injected `prop` exactly as it now reads `T_SL`. Then delete the `.geometry.engine.n_engines`
key. **Not applied** — this edits propulsion, which is outside this pass's scope, and it is a design
decision about where the count belongs. Recorded at `examples/F16A/F16GeomL3.md` §A.1b #39 / §H
item 11 and in `docs/geometry_parameter_usage.md`. Cross-reference §16.1 row 5, which first flagged
it. **Not resolved.**

### §23 — Strake DEFERRED: two comparison-report rows stay "NOT MODELED"

Recorded as a standing item so the deferral does not decay into an oversight. `geometry_brandt_
comparison.m:151,166` still emit two `Computed = NaN`, `Fidelity = 'N/A'` rows:

| Report row | Brandt expected | Cell (re-read live 2026-07-25) |
|---|---|---|
| `Strake S_wet -- NOT MODELED` | **39.956** | `Geom!B15`, formula `=H9*(1.977+0.52*(Main!D22/100-INT(Main!D22/100)))` |
| `Strake exposed area -- NOT MODELED` | **20.0** | `Geom!H9` (the "Exposed S" column of the `Geom!A5:I10` table; the report cites it as `Geom!9`) |

Live row 9 of that table, for the record: `A9` = `Strake`, `B9` (`Xexposed`) = 12.00000,
`C9` (root chord) = 7.30297, `D9` (tip chord) = 0.00000, `E9` (span) = 5.47723,
`F9` (exposed root chord) = 7.30297, `G9` (half span) = 2.73861, `H9` (exposed S) = **20.00000**.

**The deferral is justified, and the justification is NOT an `Amax` argument.** §16.2 proved live
that the strake is worth **0.000 %** of `Amax` for this aircraft — strake-out, strake-with-Brandt's-
bugs, and strake-corrected all give an identical `Amax`, because the strake is active only over
`12.000 < x < 21.551` ft and its cross-section is exactly zero at the governing station. So no
`Amax` benefit exists. What a strake component *would* buy is (a) closing the two rows above and
(b) removing the **configuration-dependence** of that 0.000 %: the peak whole-aircraft total inside
the strake's range is only 1.25 % below the global peak at frame stations (2.67 % on a fine grid),
so under optimizer mutation the governing station could migrate into the strake's range and its
absence would become a silent error.

Cost, from §16.1/§16.2: **7 new inputs** (`S_ft2` 20, `AR` 1.5, `taper` 0, `sweep_LE_deg` 74,
`tc_ratio` 0.04, `x_le_ft` 12.0, `y_root_ft` 2.0, all `Main!D18:D24`) plus the "root is fully
outside the fuselage → `S_exposed` = `S_ref`" special case (`readme_geom.md` §4.3). If it is added,
**Brandt's two documented strake bugs (`readme_geom.md` §5.1, confirmed verbatim against the live
`Geom!AG31`) must NOT be replicated** — declining them is numerically free — and the bugged value
should appear only as a labelled alternate report row, the pattern already used for the uniform-t/c
`S_wet` alternates.

**Action requested: schedule a strake step, or accept in writing that these two rows stay
NOT MODELED.** **Not resolved.**

### §24 — §14 workbook integrity: RE-CONFIRMED (record, no action)

Checked this pass at the coordinator's instruction. **§14 still records the ground-truth data as
verified intact**, and that record is unchanged: the coordinator's `readmatrix` diff of the
working-tree `Brandt-F16-A.xls` against `git show HEAD:` across all seven cited tabs — `Main`,
`Geom`, `Aero`, `Wt`, `Engn(s)`, `Consts`, `Miss` — found **every numeric cell identical**, with the
binary differing only in Excel metadata.

Corroborating live re-read this pass (Excel COM, read-only, closed without saving), values and
formulas matching every prior citation exactly: `Geom!B20` 25.110556 `=H47`;
`Geom!H47` 25.110556 `=MAX(H26:H45)-Main!B28*3.141579*C475^2/5`;
`Geom!B21` 48.303947 `=MAX(L38:L44,…)`; `Geom!B14`/`B15`/`B16`/`B17` = 392.020441 / 39.956 /
99.584837 / 81.689380; `Geom!H7`/`H8`/`H9`/`H10` = 196.22607 / 49.84725 / 20.0 / 40.88967;
`Main!B23` 17.785833 `=(213.43)/12`, `C23` 36, `H23` 36 `=C23`; `Main!F31` 15, `F32` 14, `B28` 1;
`Main!B32`/`C32`/`D32` = 46.5 / 7 / 5; `Main!C18` 108, `H18` 60, `C19` 3 `=B19`.

**Every cell citation in this file and in `examples/F16A/F16GeomL3.md` remains safe.** The `.xls`
still shows as `M` in `git status`; the hygiene decision (restore or commit) is still the user's.
**Do not restore it unilaterally** — the data is verified equivalent either way.

---

## 2026-07-25 — Phase 4 (weights redesign), scribe documentation gate

**Context:** documentation gate for Phase 4 (`~/.claude/plans/serene-conjuring-kitten.md` Phase 4 =
`~/.claude/plans/jiggly-tickling-bonbon.md` steps 2b-wts-redo → 2c → 2d), which resumes the weights
redesign paused in July. Docs-only pass — **no `.m` or `.json` file was changed.** Deliverables:
`examples/F16A/F16Weights{L1,L2,L3}.md` rewritten to the Phase-4 target, `docs/weights_parameter_usage.md`
rewritten, and the `weights_brandt_comparison` report spec written into `F16WeightsL2.md` §G.

Sources cross-checked this pass: the live weights code (`src/base/WeightsBase.m`,
`src/disciplines/weights/Weights{L1,L2,L3,ModelL1,ModelL2,ModelL3}.m`,
`examples/F16A/F16Weights{L1,L2,L3}.m`), the three tests (read for citations only, never for expected
values), `examples/F16A/f16a_L{1,2,3}.json`, `examples/F16A/F16GeomL3.m`/`.md`,
`examples/F16A/F16PropL2.m`, `src/disciplines/propulsion/PropL2.m`,
`GroundTruth/f16a_ground_truth.json` `.weights`, `readme_wt.md`, `GroundTruth/cell-map.md`, and the
repo extracts `temp_AI/docs/disciplines/reference_extracts/{metabook_data.md, raymer_data.md,
roskam_vol1_data.md}`.

**Live workbook read performed this pass** (Excel COM `actxserver`, read-only, closed without saving,
`GroundTruth/Brandt-F16-A.xls`) — 34 `Wt`-tab cells plus `'Engn(s)'`/`'Engn(s) Old'` engine-factor
cells. §P4-0 records the verification; every ground-truth `Wt` value the comparison report will use is
now cell-verified, not doc-transcribed.

### §P4-0 — Wt-tab ground truth: LIVE-VERIFIED, no discrepancy (record, no action)

Every `.weights` value in `GroundTruth/f16a_ground_truth.json` matches the live workbook. Values and
formulas verbatim:

| Cell | Live value | Live formula | GT records |
|---|---|---|---|
| `Wt!B3` | 31377.000000 | `=Main!O15` | 31377.00 ✅ |
| `Wt!B4` | 700.000000 | `=Main!O16` | 700.0 ✅ |
| `Wt!B5` | 4400.000000 | `=Main!O17` | 4400.0 ✅ |
| `Wt!B6` | 6296.299422 | `=B3-B4-B5-B12` | 6296.30 ✅ |
| `Wt!B9` | 6722.874315 | `=SUM(C9:H9)` | 6722.87 ✅ |
| `Wt!C7:H7` | 6.75 / 5.0 / 6.0 / 6.0 (`=E7`) / 4.5 / 4.5 | literals | ✅ |
| `Wt!C9` | 1785.946837 | `=Main!B18*C7/7*0.04*(Main!Q27^0.2)*(Main!B19^1.8)*((1+Main!B20)^0.5)/((Main!B22/100-INT(Main!B22/100))^0.7)/COS(Main!B21/57.29578)*Main!O27/100*MAX(1,(Main!L10-Main!L8)/Main!L7/8)` | 1785.95 ✅ |
| `Wt!D9` | 3652.110000 | `=D7*Geom!B3*Main!O27/100*MAX(1,Main!B32/(Main!C32*Main!D32)^0.5/19)` | 3652.11 ✅ |
| `Wt!E9` | 648.000000 | `=E7*Main!C18*Main!O27/100` | 648.00 ✅ |
| `Wt!F9` | 360.000000 | `=F7*Main!H18*Main!O27/100*MAX(1+IF(Main!H24>0,1,0),1)` | 360.00 ✅ |
| `Wt!G9` | 186.817478 | `=Geom!B4*Wt!G7*Main!O27/100` | 186.82 ✅ |
| `Wt!H9` | 90.000000 | `=H7*Main!D18*Main!O27/100` | 90.00 ✅ |
| `Wt!B10` | 15250.470578 | `=B9+SUM(B23:B31)` | 15250.47 ✅ |
| `Wt!B11`/`B22` | 4730.230000 | `=IF(Main!C29=Main!D29,'Engn(s) Old'!D11*Main!B28*Main!C29,'Engn(s) Old'!D22*Main!B28*Main!D29)` / `=B11` | 4730.23 ✅ |
| **`Wt!B12`** | **19980.700578** | `=SUM(B10:B11)` | **19980.70 ✅** |
| `Wt!B23` | 1066.818000 | `=B8`, where `B8` = `=B3*F23` and `F23` = **0.034** | 1066.82 ✅ |
| `Wt!B24` | 728.588163 | `=B20*F24`, `F24` = 3.9, `B20` = `=G9` | 728.60 (rounds 728.59 → 728.60; 0.0016 % — noted, not an issue) |
| `Wt!B25` | 472.435405 | `=F25*Main!O$15+Main!F18/Main!B18*Wt!C7*200`, `F25` = 0.012 | 472.44 ✅ |
| `Wt!B26` | 533.409000 | `=F26*Main!O$15`, `F26` = 0.017 | 533.41 ✅ |
| `Wt!B27` | 367.110900 | `=F27*Main!O$15`, `F27` = 0.0117 | 367.11 ✅ |
| `Wt!B28` | 360.835500 | `=F28*Main!O$15`, `F28` = 0.0115 | 360.84 ✅ |
| `Wt!B29` | 2016.862295 | `=B9*F29`, `F29` = 0.3 | 2016.86 ✅ |
| `Wt!B30` | 2541.537000 | `=F30*Main!O$15`, `F30` = 0.081 | 2541.54 ✅ |
| `Wt!B31` | 440.000000 | `=Main!O17*Wt!F31`, `F31` = 0.1 | 440.00 ✅ |
| `Wt!B38` | 31377.000000 | `=SUM(B16:B37)` | 31377.00 ✅ |
| `Wt!B41` | **20680.700578** | `=SUM(B16:B32)` | see §P4-5a |

Engine-factor chain: `'Engn(s) Old'!D22` = 0.199000 = `='Engn(s)'!D22`, and **`'Engn(s)'!D22` = 0.199
is the bare literal**; label `'Engn(s) Old'!C22` = `"Engine with AB:  Weng = "`. `'Engn(s) Old'!D11` =
0.199 = `='Engn(s)'!D10`. `readme_wt.md:230` attributes 0.199 to "Brandt 1997, Table 6.2" but gives
**no cell** — the cell is now on record here. (Same `Engn(s)` vs `Engn(s) Old` split already flagged
for the `L_engine` 4.5 factor in §18.)

**No VnV-internal disagreement found on the Wt tab.** §P4-1 … §P4-12 below are the items that *do*
need a decision.

### §P4-1 — ★ The `×1.3` installed-engine factor: the locked `W_en` decision is ambiguous in two places

**(a) The Brandt alternate must NOT be multiplied by 1.3 — doc-vs-plan ambiguity.**
`readme_wt.md:230` states verbatim: *"This is the **installed engine weight** formula for afterburning
turbofan/turbojet engines (Brandt 1997, Table 6.2). Factor 0.199 lb per lb-thrust is for AB engines."*
So `Wt!B11` = 4730.23 is **already installed**. The locked bullet
(`jiggly-tickling-bonbon.md` Decisions → L2) reads: *"`W_en` via BOTH Brandt (`0.199·T_SL_AB`) +
Raymer (Eq 10.10 … × **1.3** installed)"* — grammatically the `×1.3` attaches to the Raymer branch,
but the sentence can be misread as applying to both.

Live L2 `OEW(31377)` consequence: Raymer×1.3 → **15664.65**; Brandt as-is → **16787.35**; Brandt×1.3
→ **18206.42**. The double-installed variant reads *closest* to `Wt!B12` = 19980.70 (−8.88 % vs
−15.98 % vs −21.60 %), so an implementer optimising for agreement would pick the wrong one.

**Documented in `F16WeightsL2.md` §D.5 as Raymer-only ×1.3.** **Confirm.**

**(b) At L3 the `×1.3` DOUBLE-COUNTS §15.3.1's own installation items — plan-vs-code conflict.**
The locked resolution says *"L3 engine weight → compute via Raymer (like L2 official): `W_en` = Eq
10.10 uninstalled × 1.3 installed"*. But `WeightsL3.weight_engine_section` (`WeightsL3.m:105-130`)
sums the dry engine **plus** mounts (15.7), firewall (15.8), section (15.9), induction (15.10),
tailpipe (15.11), cooling (15.12), oil (15.13), controls (15.14) and starter (15.15) — and its own
docstring (`:112-115`) says so: *"Raymer §15.3.1 gives the installation-hardware items … as ADDITIONS
on top of the engine's own dry weight."* Raymer's nomenclature for Eq. 15.9's `W_en` is likewise the
engine weight *each* (dry). Applying ×1.3 **and** adding Eqs. 15.7–15.15 counts the installation twice.

Live L3 `OEW(31377)` at the §B target: `W_en` uninstalled 2775.0210 → **15564.95**; installed
3607.5273 → **16405.68** (+840.73). Again the double-counted variant is closer to Brandt.

**Documented in `F16WeightsL3.md` §D.2 as uninstalled at L3, installed at L2.** **This contradicts the
literal text of the locked decision and must be confirmed or overridden by the user.** Not resolved.

### §P4-2 — `prop.bypass_ratio` does not exist, so Raymer Eq. 10.10 cannot be evaluated as specified

`f16a_L2.json .propulsion.bypass_ratio = 0.71` was added in Phase 3 explicitly *"for the Raymer Eq.
10.10 engine-weight term that Phase 4 wires"*. But `F16PropL2` neither declares nor reads it —
verified live 2026-07-25: `isprop(prop,'bypass_ratio')` = **0**. `F16PropL2.m:51-60`'s input block is
`engine_type, T_SL, T_SL_mil, T_t4_max_F, TSFC_install_factor`, and its constructor (`:90-97`) reads
exactly those five keys. `PropulsionBase` declares no BPR either.

So Phase 4 must add `bypass_ratio` as an `F16PropL2` **input** property and read it in the
constructor. That is a propulsion-file edit inside a weights phase — flagging it so it is not
discovered mid-implementation. The key's own `_TODO_bypass_ratio` marker already records that 0.71 is
not traceable to any repo document.

Also note `f16a_L3.json` has **no `.propulsion` block at all**, which is correct (no L3 propulsion
tier; `F16PropL2(f16a_spec_path(2))` serves the L3 rung) — so BPR reaches L3 weights via the L2 JSON
through the injected object. **Not resolved.**

### §P4-3 — Raymer Eq. 10.10 needs a design Mach, and L2 has none anywhere

Eq. 10.10 is `W = 0.0637·T^1.1·M^0.25·e^(−0.81·BPR)`. `T` ← `prop.T_SL` ✅, `BPR` ← §P4-2 ❌, and
**`M` has no source at L2**:

- `f16a_L2.json .geometry` has **no** `M_max` key (only `f16a_L1.json .geometry.M_max = 2.0` does).
- `f16a_L2.json .aerodynamics` has no Mach input.
- `F16PropL2` exposes no Mach.
- `f16a_L3.json` has it, buried at `.weights.vertical_tail.M_design = 2.0`.

Three placement options, all defensible: (a) add `.weights.M_design: 2.0` at L2, mirroring L3;
(b) promote it to a **top-level** JSON key alongside `aircraft_category`, since design max Mach is an
aircraft *requirement* consumed by geometry (Raymer Table 4.1 `AR_eq` at L1), weights (Eqs. 15.3,
15.17, 10.10) and potentially aero — this is the only option that removes a duplicate instead of
adding a third copy; (c) put it in `.propulsion` and reach it through `prop`.

**User decision. Not resolved.**

### §P4-4 — Two L3 `[estimate]` inputs have a CITED geometry analog with a different value

Both are cases where an unpinned weights estimate coexists with a cited `F16GeomL3` quantity of
arguably the same meaning. The locked DI decision ("geometry OUT of `.weights` → injected geometry
object") does not say whether these two count as geometry.

| Weights input | Value | Citation | `F16GeomL3` analog | Analog value *(live)* | Analog citation | Live effect if wired |
|---|---|---|---|---|---|---|
| `L_d` (Eq. 15.10 duct length) | 7.5 ft | `[estimate; F-16 ventral inlet to engine face]` | `L_duct` | **14.0 ft** | `[Brandt Main!F32, label Main!E32 = "Compr Face"; readme_geom.md §3]` | air induction **227.54 → 429.01 lbf, +88.5 %**; `OEW` +201.47 |
| `D_e` (Eqs. 15.10/15.11/15.12 engine exit dia.) | 3.33 ft | `[estimate, ≈40 in; verify T.O.]` | `D_exit` (= `D_inlet` = `sqrt(T_AB/1900)`) | **3.537022 ft** | `[Brandt Geom!C475; Engn(s)!L22 = 1900]` | induction +14.15, tailpipe +3.26, cooling +7.54; `OEW` +24.94 |

Note the semantic caveats: `geom.L_duct` is inlet **lip → compressor face**, whereas Raymer's `L_d` is
the inlet **duct** length — plausibly the same, not provably so. And `geom.D_exit` is the *nacelle*
diameter from the `sqrt(T/1900)` correlation, while Raymer's `D_e` is the engine **front-face /
nozzle-exit** diameter (`WeightsL3.m:284` says "nozzle exit diameter", `:277` says "engine face
diameter" — the code itself is inconsistent about which). Wiring them trades two unpinned estimates
for two cited-but-possibly-different quantities.

**User decision. Not resolved.**

### §P4-5 — Phase 3 deleted three L3 inputs whose consumers still read them, with NO replacement specified

Phase 3 removed `W_l`, `V_t`, `SFC_mission` from `f16a_L3.json` as "Brandt outputs / derived /
duplicates". `WeightsL3` still reads all three (`obj.W_l` at `:100,:102`; `obj.V_t` at `:135`;
`obj.SFC_mission` at `:137`). Each needs a decision before the class can drop the hardcoded literal.

**§P4-5a — `W_l` (landing weight, Eqs. 15.5/15.6).** AS-IS 20681 `[Brandt Wt!B41]`. Live
`Wt!B41` = **20680.700578**, formula `=SUM(B16:B32)` — so (i) the literal is Brandt's own figure
**rounded up by 0.2994 lbf** (+0.00145 %), and (ii) it is a Brandt *output*, the same class of value
CLAUDE.md forbids as an input. Raymer §15.3.1 does not define `W_l` as a function of `W_TO`, so there
is no in-framework derivation; the usual conceptual-design assumptions (`W_l = W_TO`, or
`W_l = OEW + payload + reserve fuel`) are both uncited here. Live sensitivity: LG total **1057.27** at
20681 vs **1176.27** at `W_l = W_TO = 31377` (+11.25 %), vs **1096.30** at
`OEW + 700 + 0.5·fuel = 23828.85`. **Documented as: keep 20681 as an explicit input with its
`[Brandt Wt!B41]` citation until the user picks a definition.** Not resolved.

**§P4-5b — `V_t` (total fuel volume, Eq. 15.16). ★ The proposed derivation rests on an UNCITED fuel
density.** AS-IS 940 gal, commented `F16WeightsL3.m:125` *"derived: 6296 lbf ÷ **6.7 lb/gal** ≈ 940
gal; Brandt B6"*. Grepped `air_vehicle_design/sizing/` 2026-07-25: **6.7 lb/gal appears nowhere else**,
and **no JP-4 / JP-5 / JP-8 fuel density is cited anywhere in the repo** — not in `metabook_data.md`,
not in `raymer_data.md`, not in `readme_wt.md`, not in `F16Baseline.m`. So `V_t = W_energy / 6.7`
would replace one cited input (Brandt-derived 940) with an **uncited constant**. The arithmetic also
gives **939.746**, not 940 (−0.027 %), so the AS-IS literal is itself rounded. Eq. 15.16 is weakly
sensitive (386.79 → 386.74 lbf), so this is a citation problem, not a numeric one. **The user must
supply a cited fuel density** (or accept `V_t` staying an input). Not resolved.

**§P4-5c — `SFC_mission` (Eq. 15.16). The Phase-3 rationale is factually wrong.**
`f16a_L3.json .weights._not_inputs` states: *"SFC_mission [Main!C30] duplicates what
`PropL2.get_TSFC` computes."* It does not duplicate it — the values disagree by 29–147 %, and no
reference condition is specified. Computed live from the injected `F16PropL2`:

| Path | Condition | 1/hr | vs Brandt 0.70 |
|---|---|---|---|
| `compute_TSFC_mil` | SLS, M = 0.01 | 0.9030 | +29.0 % |
| `compute_TSFC_installed` (mil) | SLS, M = 0.01 | 0.9752 | +39.3 % |
| `compute_TSFC_installed` (mil) | 36 kft, M = 0.9 | 1.0961 | +56.6 % |
| `compute_TSFC_AB_installed` | 36 kft, M = 0.9 | 1.7266 | +146.7 % |
| `PropL2.SFC_cruise_AB(0.71)` [Raymer Eq. 10.15] | 36 kft, M = 0.9 | 0.9113 | +30.2 % |

Brandt's own 0.70 is a **stored, already-installed** SLS mil TSFC (`Main!C30`; see 2026-07-24
propulsion entry 4 — do not double-apply the 1.08). Eq. 15.16's `((T·SFC)/1000)^0.249` moves the
fuel-system weight 386.74 → 420.03 lbf (+8.6 %) across the 0.70 → 0.9752 span, i.e. +33 lbf on `OEW`.
**The user must name the reference condition.** Not resolved.

### §P4-6 — Two `F16WeightsL3` inputs are DEAD: `AR_ht` = 2.114 and `lambda_ht` = 0.390

Neither is read by any equation. Verified by grep of `obj.AR_ht` / `obj.lambda_ht` across
`src/disciplines/weights/` 2026-07-25: **zero matches**. Raymer Eq. 15.2 as coded
(`WeightsL3.m:70-71`) takes only `(W_dg, N_z, S_ht, F_w, B_h)`.

They are the reason `F16WeightsL3.m:69-72`'s `B_h` comment ends *"supersedes the earlier
`sqrt(AR_ht*S_ht)` = 11.61 ft derivation, which is inconsistent with this reported value — AR_ht/S_ht
above not reconciled"* — an unreconciled inconsistency between two properties **neither of which is
used**. Phase 4 should **delete both**, not wire them to `geom.AR_exposed_ht` /
`geom.lambda_exposed_ht`. (Distinct from 2026-07-24 GeomL3 §1, which is about whether the *geometry*
tier's exposed AR/taper reconcile — that item stands on its own for the geometry side.)
**Flagged for confirmation.**

### §P4-7 — `WeightsL2.LG_fraction`: one uncited row, one missing row

`WeightsL2.m:167-178` cites all three rows to "AE481 metabook §7". Checked against the extract's
fraction table, `temp_AI/docs/disciplines/reference_extracts/metabook_data.md:328-334`:

| Code row | Code value | Extract row | Extract value | Status |
|---|---|---|---|---|
| `jet_fighter` | 0.033 | Landing gear (fighter), `:330` | 0.033 | ✅ |
| `jet_transport` | 0.043 | Landing gear (transport), `:332` | 0.043 | ✅ |
| `general_aviation` | **0.057** | *(no GA row exists)* | — | ❌ **UNCITED** |
| *(absent)* | — | Landing gear (Navy fighter), `:331` | 0.045 | ❌ **MISSING from code** |

The GA 0.057 has no source in this repo, despite carrying an AE481 §7 citation; and the Navy-fighter
0.045 that the extract *does* give is absent (`WeightsL2.m:14`'s header comment even mentions "0.045
for Navy fighters", so the value was known and simply not added to the lookup). Neither affects the
F-16. **Citation-integrity item. Not resolved.**

### §P4-8 — Raymer Table 6.1 (L1) — STANDING TO-DO, coefficients not in the repo

Restating for Phase 4 (originally 2026-07-24 §3c item 4). `WeightsL1.m:29,89` cites Raymer **Table
3.1**; `docs/subplans/05_weights.md:81,88` cites Raymer **Table 6.1** for the same power law. Locked:
keep Table 3.1 + the existing Roskam bound; **Table 6.1's coefficients are not present anywhere in
this repo** and the user is to supply them. Needs a labelled deliberately-failing
`TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`.

**New, positive finding this pass — a prior doc claim was wrong.** `docs/weights_parameter_usage.md`
(previous version, L1 table) and `F16WeightsL1.md` (previous version, Deviations) both stated the
Roskam Table 2.15 constants were "no repo extract — unpinned" / "Not locatable in repo". **They are in
the repo**: `temp_AI/docs/disciplines/reference_extracts/roskam_vol1_data.md:53-63` carries all five
code rows exactly (`jet_fighter` 0.5091/0.9505; `fighter_piston` 0.5647/0.8761; `single_engine_prop`
−0.1440/1.1162; `military_patrol_bomber` −0.2009/1.1037; `supersonic_cruise` 0.0833/1.0335), and
`:47` carries Eq. 2.16 in the same form the code implements. The extract carries its own warning
(`:63`): the 12-category table is image-only, these rows were OCR-recovered, *"Verify against the book
before locking into code."* Likewise `metabook_data.md:20-26` carries all four Raymer Table 3.1 rows
exactly, and `:319-334` carries every Table 15.2 psf value and every §7 fraction the code uses. So the
L1/L2 constants are **traceable to a secondary repo extract but not book-verified** — the same status
as the §15.3.1 exponents, one tier better than "unpinned". Both docs are corrected. **Record; no
action beyond the Table 6.1 item above.**

### §P4-9 — `f16a_L3.json .weights._note` describes a category-lookup design that does not exist

The note asserts: *"Raymer §15.3.1 exponents/coefficients are aircraft_category-selected toolbox
Constants and a standing verify-against-book item."* The second half is true; **the first half is
false.** Every §15.3.1 coefficient (0.0103, 3.316, 0.452, 0.499, 0.013, 0.01, 13.29, 3.5, 4.55,
37.82, 10.5, 0.025, 7.45, 36.28, 8.0/36.37/26.4, 37.23, 172.2, 2.117, 217.6, 201.6, 3.2e-4) is a bare
literal inside a `WeightsL3` static — no `switch`, no lookup, no category key. And `F16WeightsL3` has
**no `aircraft_category` property at all**, so nothing at L3 could select a row even if one existed
(grep of `obj.aircraft_category` in `src/disciplines/weights/`: matches only in `WeightsL1`/`WeightsL2`).

Two ways out: implement the one-row category lookup (consistent with `WeightsL1.lookup_coeffs` /
`WeightsL2.wing_unit_weight` / `PropL2.lookup_TSFC_coeffs`), or correct the note. **Doc-vs-code
mismatch inside the input file. Not resolved.**

### §P4-10 — `WeightsModelL3.W_subsystems`' documented contract is wrong

`WeightsModelL3.m:23` declares `W_subsystems  % Includes landing gear`. But `WeightsL3.OEW`
(`WeightsL3.m:47-48`) sums `W_lg.main + W_lg.nose` **separately** from `W_sys.total`, and
`WeightsL3.weight_systems` (`:132-150`) contains no landing-gear term at all. A consumer trusting the
comment would double-count or under-count the gear by 1057.27 lbf *(live)*.

Part of review finding #12 (the five NaN abstract totals), but a *distinct* defect: even once
`W_subsystems` becomes a live `Dependent`, its documented meaning would still be wrong. Either fix the
comment or add a sixth `W_landing_gear` Dependent to `WeightsModelL3`. **Flagged.**

### §P4-11 — ★ Weights-side domain guards (deferred from Phase 1e) — one path is reachable BY DESIGN

`~/.claude/plans/serene-conjuring-kitten.md` §1e: *"Weights-side guards (`H_v=0`, `L_s=0`, `K_d=0`)
deferred to Phase 4 with that rewrite."* All four paths, with the exact failure mode:

| Input | Value | Eq. | Term | Result | Reachability |
|---|---|---|---|---|---|
| `H_v` | 0 | 15.3 | `(1 + H_t/H_v)^0.5` | `H_t=0` → `0/0` = `NaN`; `H_t>0` → `Inf` | plausible mis-entry — the property is documented as "any nonzero denominator", i.e. its value is arbitrary and 0 looks harmless |
| `L_s` | 0 | 15.10 | `(L_s/L_d)^(−0.373)` | `Inf` | plausible mis-entry (no splitter) |
| **`K_d`** | **0** | **15.10** | **`K_d^0.182`** | **`0` — the ENTIRE 227.54 lbf air-induction term silently vanishes** | ★ **REACHABLE BY DESIGN.** `WeightsL3.m:276` documents `K_d = 0` as the legitimate **straight-duct** value ("`K_d = 0` (straight duct) or 1 (bifurcated)"). A legal input silently zeroes a whole component |
| `V_t` | 0 | 15.16 | `V_t^0.47` · `(1+V_i/V_t)^(−0.095)` · `(1+V_p/V_t)` | `0 × Inf` → `NaN` | becomes live once `V_t` derives from `W_energy`, which starts `NaN` |

The `K_d` case is not just a missing guard — **it means the code's `K_d` cannot be Raymer's `K_d` as a
multiplicative base**, since a straight duct does not weigh zero. Either the exponent/placement is
wrong, or `K_d`'s legal values are 1/1.x rather than 0/1. This sits inside the §3a "verify against the
book" obligation (`K_d` exponent 0.182 is checklist row 7, `[VERIFY]`). Guards alone would mask it.
**Needs a decision, not just an error message. Not resolved.**

### §P4-12 — `f16a_ground_truth.json` `.weights.inputs_on_Wt_tab._note` is STALE

It reads: *"NB the framework's payload split differs from Brandt's: Brandt perm=700 / exp=4400 lb, vs
the framework `.weights` `W_payload_fixed=220` / `W_payload_expendable=0`."* Phase 3 already set all
three `f16a_L{1,2,3}.json` `.weights` blocks to **700 / 4400**, so there is no longer any difference —
the note now describes a divergence that does not exist and would mislead anyone verifying the
closure. (The framework *classes* still default to 220/0 because they do not read the JSON yet, which
Phase 4 fixes.) Same class of staleness as §10. **Hygiene item in a read-only-by-convention ground-truth
file — flagging, not editing.**

---

## 2026-07-25 — Phase 4 decisions (user) + scribe re-status

**Context:** the user settled six decisions on the items §P4-1 … §P4-12 raised above; the coordinator
independently re-verified three of the scribe's claims (`isprop(F16PropL2,'bypass_ratio')` = 0;
`get_TSFC` at plausible states vs Brandt's 0.70; Roskam Table 2.15 present at
`roskam_vol1_data.md:53-63`) and accepted all three. This section records the dispositions and adds
five new items (§P4-13 … §P4-17) that the decisions themselves surfaced. Still docs-only — no `.m`,
`.json` or report script was changed.

### Re-status table for §P4-1 … §P4-12

| Item | Status now | Disposition |
|---|---|---|
| §P4-1a Brandt `0.199·T` and `×1.3` | **RESOLVED** | Brandt alternate gets **NO** `×1.3` — `readme_wt.md:230` says it is already installed. `W_en_brandt` = 4730.2300 as-is |
| §P4-1b L3 `×1.3` double-counts | **RESOLVED — scribe's recommendation ACCEPTED** | L3 uses the **UNINSTALLED** 2775.0210; `×1.3` is **L2-only**. This **overrides the literal text** of the 2026-07-24 locked resolution ("L3 engine weight → compute via Raymer (like L2 official): Eq 10.10 uninstalled × 1.3 installed"). Recorded consequence: L3 `OEW(31377)` = **15705.33** (−21.40 % vs `Wt!B12`) vs the rejected `×1.3` **16546.06** (−17.19 %). **The rejected variant agrees BETTER with Brandt, and that was the reason to distrust it** |
| §P4-2 `prop.bypass_ratio` missing | **RESOLVED (outside this phase)** | The coordinator is adding the `F16PropL2` input property. Its `_TODO_bypass_ratio` marker (0.71 untraceable in-repo) **stays open** |
| §P4-3 no Mach at L2 | **RESOLVED** | New `examples/F16A/f16a_requirements.json` → `design_mach` = 2.0, read by L2 and L3. See §P4-13 for the citation correction |
| §P4-4 `L_d` / `D_e` geometry analogs | **STILL OPEN** | Not addressed by the six decisions. Live sensitivities on the settled L3 base 15705.33: `L_d` 7.5→14.0 → 15906.80 (+201.47); `D_e` 3.33→3.537022 → 15730.27 (+24.94). Documented in `docs/weights_parameter_usage.md` §B.5 and `F16WeightsL3.md` §B.5 |
| §P4-5a `W_l` | **RESOLVED** | `W_l` = **0.95 · W_TO**, a `Dependent` tracking the sizing loop. See §P4-16 for the uncited 0.95 and §P4-17 for the frozen-mutation bug it fixes |
| §P4-5b `V_t` / uncited fuel density | **PARTLY RESOLVED, provenance STILL OPEN** | `V_t` **restored as a JSON input** = 940 gal, deliberately *not* derived, precisely so the uncited 6.7 lb/gal density does not enter an equation. The density remains cited **nowhere** in `air_vehicle_design/sizing/` (re-grepped 2026-07-25: only the `F16WeightsL3.m:125` comment; no JP-4/JP-5/JP-8 density anywhere). **User to supply a cited density if `V_t` is ever to be derived** |
| §P4-5c `SFC_mission` | **RESOLVED, with an accepted divergence** | **DERIVED by DI** = `prop.get_TSFC(AircraftState(cruise.altitude_ft, cruise.mach))` = `get_TSFC(36000, 0.87)` = **1.007116** 1/hr *(live)*, **+43.87 %** above Brandt `Main!C30` = 0.70. **Accepted by decision.** Fuel system 386.794 → **423.465** lbf (+36.67). See §P4-15 for the false rationale being corrected |
| §P4-6 dead `AR_ht` / `lambda_ht` | **RESOLVED** | Confirmed dead; **DELETE both**. Do not wire them to `geom.AR_exposed_ht` / `geom.lambda_exposed_ht` |
| §P4-7 `LG_fraction` citation + rows | **PARTLY RESOLVED** | The **0.033 value is unchanged** (already coded) and its citation is corrected to `[AE481 metabook §7, "Fraction-Based Weight Estimates" table]`, `metabook_data.md:330` — **NOT** Raymer Table 15.2, which is the psf table at `:319-324` and carries no fraction rows. The same correction applies to the 1.3 installed-engine and 0.17 all-else factors. **Still open:** the uncited `general_aviation` 0.057 row and the missing `navy_fighter` 0.045 row |
| §P4-8 Raymer Table 6.1 / Roskam Table 2.15 | **PARTLY RESOLVED** | The **Roskam Table 2.15 item is WITHDRAWN** — the extract exists at `roskam_vol1_data.md:53-63` with all five coded rows matching exactly (coordinator-verified). **Only Raymer Table 6.1 remains a standing TO-DO** (coefficients not in the repo; user to supply; needs `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo`) |
| §P4-9 L3 `_note` claims a category lookup that does not exist | **STILL OPEN** | Not addressed. Either implement the one-row lookup or correct the note |
| §P4-10 `W_subsystems` "includes landing gear" is false | **STILL OPEN** | Not addressed. Fix the comment or add a sixth `W_landing_gear` Dependent to `WeightsModelL3` |
| §P4-11 `K_d` = 0 silent zero + other guards | **★ EXPLICITLY LEFT OPEN by decision 6** | **No guard added, no softening.** `K_d = 0` is a documented, legal straight-duct value; `0^0.182 = 0` *(verified live)*, so the entire **227.5439 lbf** air-induction term evaluates to exactly **0.0000** with no error and no `NaN`. L3 `OEW` would read **15477.79** instead of 15705.33. Same silent-zero class as the Phase-1 `F16GeomL1` defect (`CD0 = Cfe·0/S_ref` → infinite L/D). `H_v = 0`, `L_s = 0`, `V_t = 0` likewise unguarded. **The corollary stands: if `K_d = 0` is legal, the code's `K_d` cannot be Raymer's multiplicative base — a straight duct does not weigh nothing — so the exponent/placement is suspect (§3a checklist row 7). A guard alone would mask that.** No guard *tests* are being added either, since adding tests for unguarded behaviour would create a false green |
| §P4-12 stale ground-truth payload note | **STILL OPEN** | Hygiene item in a read-only-by-convention file; flagged, not edited |

### §P4-13 — ★ NEW: the proposed `design_mach` citation is a MIS-ATTRIBUTION — do not use it

The decision message cites `design_mach: 2.0` as *"[T.O. 1F-16A-1 Mach 2.05 limit; the value L3
already carries under `.weights.vertical_tail.M_design`]"*. **The repo distinguishes these two
numbers, and they are not equal.**

| Quantity | Value | Repo location | Source as recorded |
|---|---|---|---|
| Brandt's design max Mach | **2.0** | `GroundTruth/f16a_geometry.json:9` — `"Mmax": 2.0`; also `f16a_L1.json .geometry.M_max`, `f16a_L3.json .weights.vertical_tail.M_design`, `F16WeightsL3.m:84` (`[Brandt polar_model]`) | Brandt `Main!` aircraft input |
| T.O. operating **Mach limit** | **2.05** | `GroundTruth/f16a_ground_truth.json:228` — `"Mach_limit": {"value": 2.05, "_source": "T.O. 1F-16A-1 operating limits."}` | T.O. 1F-16A-1 |

2.0 ≠ 2.05 (**−2.44 %**). Citing the value 2.0 to "the T.O. Mach 2.05 limit" attributes a Brandt input
to a primary document that states something different — the same class of wrong-source attribution as
the 19,148-cited-as-`Wt!B12` error (finding #14, §3b). **Correct citation:**
`[Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9]`, with the T.O. 2.05 noted as a
corroborating-but-different figure and a `_TODO_design_mach` marker key on the requirements file.

Sensitivity, computed live: Raymer Eq. 10.10's `M^0.25` gives `W_en` = **2775.0210** at M = 2.0 vs
**2792.2046** at M = 2.05 (+0.62 %); full L3 `OEW` 15705.33 → 15725.41 (+20.08). Numerically minor —
which is exactly why the citation must not be allowed to drift unnoticed. **Not resolved: user to
confirm which number the requirements file should carry, and cite it correctly either way.**

### §P4-14 — NEW: `f16a_requirements.json` creates a third copy of the design Mach

With `design_mach` in the requirements file, `f16a_L3.json .weights.vertical_tail.M_design` is a
duplicate and is being deleted (settled decision 5). But **`f16a_L1.json .geometry.M_max = 2.0` is the
same quantity again**, read by `F16GeomL1` for the Raymer 7th ed. Table 4.1 `AR_eq` regression
(`GeomL1.m:121-129`). Repointing geometry at the requirements file is outside Phase 4's scope, so the
duplicate persists. **Flagged for whoever builds the full requirements file with constraint/mission
analysis** — the same "one canonical value per quantity" argument that produced the single top-level
`aircraft_category` in Phase 3 applies here. Not resolved.

### §P4-15 — NEW (correction of the record): the Phase-3 `SFC_mission` deletion rationale was FALSE

`f16a_L3.json .weights._not_inputs` states: *"SFC_mission [Main!C30] duplicates what
`PropL2.get_TSFC` computes."* The Phase-3 commit message says the same. **Both are false**, and the
coordinator has accepted this on the record.

`get_TSFC` does not reproduce Brandt's 0.70 at any condition. Computed live 2026-07-25 from
`F16PropL2(f16a_spec_path(2))`:

| Path | Condition | 1/hr | vs 0.70 |
|---|---|---|---|
| `compute_TSFC_mil` = `get_TSFC` | SLS, M = 0.01 | 0.903000 | +29.0 % |
| `compute_TSFC_installed` (mil) | SLS, M = 0.01 | 0.975240 | +39.3 % |
| **`get_TSFC` (mil, uninstalled)** | **36 kft, M = 0.87** | **1.007116** | **+43.87 %** ← the selected value |
| `compute_TSFC_installed` (mil) | 36 kft, M = 0.87 | 1.087685 | +55.4 % |
| `compute_TSFC_AB` | 36 kft, M = 0.87 | 1.591694 | +127.4 % |
| `compute_TSFC_AB_installed` | 36 kft, M = 0.87 | 1.719029 | +145.6 % |
| `PropL2.SFC_cruise_AB(0.71)` [Raymer Eq. 10.15] | 36 kft, M = 0.9 (Raymer's own cruise reference) | 0.911340 | +30.2 % |

Two independent causes of the divergence, both deliberate: (a) **condition** — a real cruise point vs
Brandt's single stored SLS constant; (b) **installation basis** — `get_TSFC` returns the *uninstalled*
mil TSFC, while Brandt's 0.70 is *already installed* (2026-07-24 propulsion entry 4: "Brandt's stored
SLS TSFCs are ALREADY installed — do not double-apply").

One consistency point **in the framework's favour**, worth recording: Brandt's own cruise condition
(`Consts!` row 24, via `.propulsion.thrust_lapse_at_constraint_conditions`) is `pct_AB = 0`, i.e.
**dry/mil**, and `get_TSFC` resolves to the mil path at that state — so the *power setting* matches
Brandt's cruise definition exactly. Only the condition and the installation basis differ.

**io must correct the `.weights._not_inputs` note.** The +43.87 % is accepted by decision, not a
defect — but the stated reason for the original deletion must not remain on record as fact.
**Correction logged; the note fix is an io action.**

### §P4-16 — ★ NEW OPEN ITEM: the `0.95` in `W_l = 0.95 · W_TO` has NO citation

Settled decision 4 makes `W_l` a `Dependent` = `0.95 · W_TO`, where `W_dg` = TOGW = `W_TO`. The 0.95
factor was supplied by the user and, per the decision message itself, **"has no citation in the repo —
log that as an open item and do not invent one."** Recorded accordingly:

- Grepped `air_vehicle_design/sizing/` 2026-07-25 — no `0.95` landing-weight fraction appears in
  `metabook_data.md`, `raymer_data.md`, `roskam_vol1_data.md`, `readme_wt.md`, `F16Baseline.m`, or
  `temp_Casey/`. Raymer §15.3.1's nomenclature defines `W_l` as the landing design gross weight but
  gives no `W_l`/`W_dg` ratio.
- Brandt's own figure is `Wt!B41` = **20680.700578** *(live, formula `=SUM(B16:B32)`)* — itself a
  back-calculated output of his weight statement, i.e. `20680.70 / 31377` = **0.6591**, not 0.95.
- So the framework's `W_l` = 29808.15 sits **+44.14 %** above Brandt's, and the two are
  `DEFINITIONAL`-ly different quantities: a design landing-weight *rule of thumb* vs a computed
  weight-statement subtotal.
- Live sensitivity: LG total **1160.934** at 0.95·`W_TO` vs **1057.273** at `W_l` = 20681
  (**+9.81 %**), vs 1176.272 at `W_l` = `W_TO`.

**Needs a cited source (Raymer/Roskam/Nicolai landing-weight fraction, or a T.O. figure).
Not resolved.**

### §P4-17 — ★ NEW FINDING: L3's landing gear was ALSO frozen under mutation (a 16th defect)

Not among the 15 verified review findings; surfaced while quantifying decision 4. AS-IS
`F16WeightsL3.m:97` stores `W_l = 20681` as a plain constant, and `WeightsL3.weight_landing_gear(obj)`
takes **no `W_TO` argument at all** (`WeightsL3.m:86`) — so **the entire landing-gear group is
completely insensitive to `W_TO`.** Verified live:

| `W_TO` | AS-IS LG total | With `W_l` = 0.95·`W_TO` |
|---|---|---|
| 31,377 | 1057.273 | 1160.934 |
| 45,000 | **1057.273** | 1273.168 |
| 60,000 | **1057.273** | 1370.469 |

This is review finding #5's exact defect class (`W_all_else_empty` frozen at `0.17·31377` on
`F16WeightsL2`) reproduced in a different tier, with the same signature: **a Brandt OUTPUT frozen as
an input** (`Wt!B41`, a `=SUM()` over his own weight rows). Like #5, no test caught it because every
`TestWeightsL3` case calls `OEW(31377)`. Settled decision 4 fixes it; the guard test is named in
`F16WeightsL3.md` §F (`testLandingGearScalesWithWTO`). **Recorded for the review log — the review's
count of frozen-derived defects was one short.**

---

## 2026-07-25 — Phase 4 AS-BUILT re-status (step 2d, scribe)

**Context:** Phase 4 is implemented, tested and green — `run_all_tests` **491/501, all 10 reds labelled
`testTODO_`, zero unlabelled reds** (coordinator-verified). This section re-statuses §P4-0 … §P4-17
against **what actually shipped**, and adds four new items (§P4-18 … §P4-21) that the implementation
itself surfaced. Docs-only pass: the five deliverables were `docs/subplans/05_weights.md`,
`docs/PLAN.md`, `examples/F16A/F16Weights{L1,L2,L3}.md`, `docs/weights_parameter_usage.md` and this
entry. **No `.m`, `.json` or report script was changed in this pass.**

Verified live 2026-07-25 via `mcp__matlab__evaluate_matlab_code` for this re-status (not carried over
from the target spec): the three property counts (L1 5/0, L2 9/12, L3 45/31), `isprop(prop,
'bypass_ratio')` = 1, L2 `OEW(31377)`/`OEW(45000)` and the exact 2765.4690 delta, L3
`OEW` at 31,377 / 45,000 / 60,000 = 15705.3313 / 16869.6310 / 17930.7085, the L3 landing-gear totals
1160.9336 / 1273.1680 / 1370.4685, the unset-`W_TO` throw/no-throw split at L2, and the per-file test
counts (25/38/44) with their reds.

### Re-status table for §P4-0 … §P4-17 — as built

| Item | Status now | What shipped |
|---|---|---|
| §P4-0 Wt-tab ground truth + the 19,148-vs-19,980.70 mis-citation (review finding #14) | **RESOLVED** | The OEW-vs-Brandt agreement check **left the unit tier entirely** at all three levels; the 19,148 assertions and the "[Brandt F-16A.xls, sheet Wt, B12]" header blocks are gone. `weights_brandt_comparison` carries `Brandt` = 19,980.70 `[Wt!B12]` with 19,148.08 `[corrections.xls Wt!B12]` in a **separately labelled `Alt` column** |
| §P4-1a Brandt `0.199·T` gets no `×1.3` | **RESOLVED** | `W_en_brandt` = 4730.2300 as-is at both levels, report-only, never summed (`testBrandtEngineAlternateIsNeverSummedIntoOEW`) |
| §P4-1b L3 `×1.3` double-counts | **RESOLVED** | L3 consumes the **UNINSTALLED** 2775.0210; `×1.3` is L2-only. `testEngineDryWeightIsUninstalledEq1010` guards it. Both rejected variants are reported rows, so the decision stays auditable |
| §P4-2 `prop.bypass_ratio` missing | **RESOLVED** | `isprop(prop,'bypass_ratio')` = **1**, value 0.71, verified live. The key's own `_TODO_bypass_ratio` marker (0.71 untraceable in-repo) **stays open** |
| §P4-3 no Mach at L2 | **RESOLVED** | `examples/F16A/f16a_requirements.json` + `f16a_requirements_path.m` shipped; `design_mach` = 2.0 read by `F16WeightsL2`, `F16WeightsL3` **and `F16GeomL1`** |
| §P4-4 `L_d` / `D_e` geometry analogs | **STILL OPEN** | Neither wired, deliberately. Both keep `[estimate, unpinned]` plus an in-code `⚠` naming the analog and its cost, and both are sensitivity rows in report section 6 (`L_d` +201.47, `D_e` +24.94 on `OEW`) |
| §P4-5a `W_l` | **RESOLVED** | `W_l` = `0.95 · W_TO`, `Dependent`. Also fixed §P4-17 |
| §P4-5b `V_t` / uncited 6.7 lb/gal | **PARTLY RESOLVED, provenance STILL OPEN** | `V_t` restored as a JSON input = 940 gal, deliberately *not* derived, so the uncited density never enters an equation. The density remains cited **nowhere** in `air_vehicle_design/sizing/`. **User to supply a cited density if `V_t` is ever to be derived** |
| §P4-5c `SFC_mission` | **RESOLVED, divergence accepted** | `Dependent` = `prop.get_TSFC(AircraftState(36000, 0.87))` = **1.007116** 1/hr, **+43.87 %** vs `Brandt Main!C30` = 0.70. `testSFCMissionIsDIAtCruiseCondition` asserts the *identity against the injected object*, deliberately **not** the literal 1.007116 |
| §P4-6 dead `AR_ht` / `lambda_ht` | **RESOLVED** | Both **deleted**, neither rewired; `F16WeightsL3.m` carries a `NOTE:` at the HT getter block saying why. `testDeadHTAspectRatioAndTaperAreDeleted` |
| §P4-7 `LG_fraction` citation + rows | **PARTLY RESOLVED, STILL OPEN** | 0.033's citation corrected to `[AE481 metabook §7, "Fraction-Based Weight Estimates"]` (`metabook_data.md:330`), **not** Raymer Table 15.2; same correction applied to the 1.3 and 0.17 factors. **Still open:** the uncited `general_aviation` **0.057** row (now carrying an in-code `TODO (…§P4-7, OPEN)`) and the **missing `navy_fighter` 0.045** row — the latter now pinned by `testLGFractionHasNoNavyFighterRow`, i.e. recorded as a *known* absence, not fixed |
| §P4-8 Raymer Table 6.1 / Roskam Table 2.15 | **PARTLY RESOLVED; Table 6.1 STILL OPEN** | Roskam Table 2.15 item **withdrawn** (extract exists at `roskam_vol1_data.md:53-63`). **Raymer Table 6.1 remains a standing TO-DO**, guarded by `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` — verified RED. The rewritten `docs/subplans/05_weights.md` deliberately **keeps** its Table 6.1 citation (§9 item 1), since that file is the sole in-repo source of the claim and deleting it would erase the item the test guards |
| §P4-9 L3 `_note` claims a category lookup that does not exist | **RESOLVED (note corrected)** | `f16a_L3.json .weights._note` now states that the §15.3.1 coefficients are hardcoded literals and are **not** category-selected, and records that the earlier claim was wrong. `F16WeightsL3` does now carry an `aircraft_category` input, unread by `WeightsL3` **by construction** (one build-up, one path) and kept for interface parity + report labelling |
| §P4-10 `W_subsystems` "includes landing gear" is false | **RESOLVED (comment corrected)** | `WeightsModelL3`'s comment now says the group does **not** include the gear, records the old wording as wrong, and points at `weight_landing_gear(obj, W_TO)`. Guard: `testSystemsGroupContainsNoLandingGearTerm` |
| §P4-11 `K_d` = 0 silent zero + `H_v`/`L_s`/`V_t` guards | **★ STILL OPEN — unguarded by decision 6, and not softened** | **No guard was added and no guard test was added** (adding tests for unguarded behaviour would be a false green). `K_d = 0` remains a documented, legal straight-duct value; `0^0.182 = 0`, so the entire **227.5439 lbf** air-induction term evaluates to exactly **0.0000** with no error, no warning and not even a `NaN`; L3 `OEW` reads **15477.7874** instead of 15705.3313 *(verified live)*. Report section 6 carries the row so the silent zero is visible somewhere. **The corollary stands:** if `K_d = 0` is legal, the code's `K_d` cannot be Raymer's multiplicative base — a straight duct does not weigh nothing — so the exponent/placement is itself suspect (§3a checklist row 7), and a guard alone would mask it |
| §P4-12 stale ground-truth payload note | **RESOLVED (note corrected)**, one residual — see §P4-21 | `f16a_ground_truth.json .weights.inputs_on_Wt_tab._note` now states the payload split **agrees** (700/4400 both sides, closure exact) and records the old 220/0 divergence claim as stale |
| §P4-13 `design_mach` citation mis-attribution | **STILL OPEN** | The value **is** cited to Brandt (`Main! aircraft.Mmax = 2.0`) with the T.O. limit 2.05 named as corroborating-but-different, and a `_TODO_design_mach` key carries the full argument. **The user must still confirm which figure is the design requirement**; sensitivity `W_en` 2775.0210 → 2792.2046 (+0.62 %), `OEW` 15705.33 → 15725.41 |
| §P4-14 third copy of the design Mach | **STILL OPEN**, but better than planned | `f16a_L1.json .geometry.M_max` was **deleted too**: `F16GeomL1(json_path, req_path)` reads `design_mach` from the requirements file for `[Raymer 7th ed. Table 4.1]` `AR_eq`, so the design Mach has **one** source as built. The broader consolidation (every requirement-like value, once constraints + mission land) is **not** done, and see §P4-20 |
| §P4-15 the Phase-3 `SFC_mission` rationale was FALSE | **CORRECTED ON THE RECORD** | The correction is carried in `F16WeightsL3.m`'s `get.SFC_mission` comment and in both docs. **Verify the `f16a_L3.json .weights._not_inputs` wording at review** |
| §P4-16 the `0.95` in `W_l = 0.95·W_TO` has NO citation | **★ STILL OPEN** | Implemented as decided, with the missing citation stated plainly in `WeightsL3.landing_weight`, in `F16WeightsL3.get.W_l` and in both docs. Brandt's implied ratio is `20680.70/31377` = **0.6591**, and the two are definitionally different quantities. **Needs a cited source (Raymer/Roskam/Nicolai landing-weight fraction, or a T.O. figure).** Not invented |
| §P4-17 L3 landing gear frozen under mutation | **RESOLVED** | `W_l` is `Dependent` = 0.95·`W_TO` **and** `weight_landing_gear(obj, W_TO)` gained its argument. LG total now **1160.9336 / 1273.1680 / 1370.4685** at 31,377 / 45,000 / 60,000 *(verified live)* where it was bit-identical 1057.273 at all three. Four guards: `testLandingGearScalesWithWTO`, `testLandingGearIsNotTheFrozenValue`, `testLandingGearArgumentWinsOverStaleObjectWTO`, `testLandingWeightIsDerivedFromWTO` |

Also resolved en route, from the 2026-07-24 §3c list: item 1 (finding #5, `W_all_else_empty` frozen —
the fix is measurable, `OEW(45000) − OEW(31377)` = `(0.17+0.033)·13623` = **2765.4690** exactly), item 3
(the p.572-vs-p.602 page-scheme mix — `WeightsL3.m` now cites the **section only**), item 4 (edition
unified to **Raymer 7th ed.** across weights, zero value changes), item 5 (`WEIGHTSMODELG3` typo gone),
item 6 (the NaN "computed total" placeholders — 4 at L2, 5 at L3 — are all `Dependent`, with zero
non-finite reads).

### §P4-18 — ★ NEW: the `requireWTO` OVER-GUARD, now fixed — a guard must encode a real dependency

**LOOSE END RESOLVED (2026-07-26 — see §D-1).** The stale-docstring loose end recorded at the bottom
of this entry is closed: `TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO` was **deleted**,
not rewritten. A `testTODO_` marker whose condition is already satisfied guards nothing, and leaving
a green one whose docstring says "EXPECTED RED" invites a future reader to make the docstring true by
re-adding the over-guard. The principle survives where it belongs — in `requireWTO`'s own docstring
at both levels, and in `TestWeightsL3.testWTODependentPropertiesErrorWhenWTOUnset`'s comment (which
cross-referenced the deleted test by name until this sweep). Four docs described the test as still
present (`docs/subplans/05_weights.md`, `docs/weights_parameter_usage.md`,
`examples/F16A/F16WeightsL2.md`, and that test comment); all four now record the deletion. The
suite's `testTODO_` count is **ten, all red** — there is no longer a green one. Original evidence
below.

An earlier Phase-4 version routed **five** of `F16WeightsL2`'s six component/group getters through
`requireWTO` "for uniformity", and its `requireWTO` docstring justified this as applying **"UNIFORMLY to
all six"**. Two things were wrong at once:

1. **It was not uniform.** `W_installed_engine` was **never** guarded, so the stated rationale did not
   describe the code it was attached to.
2. **Three of the five have no `W_TO` dependence at all.** `WeightsL2.weight_wing`, `weight_tail` and
   `weight_fuselage` declare their second argument as **`~`** — they are pure area × density
   (`[Raymer 7th ed. Table 15.2]` psf). Guarding them asserted a dependency the formulas do not have,
   and taught a reader that `9.0 · S_exposed_wing` somehow needs a gross weight.

The **same over-guard existed at L3**, on `W_installed_engine` (`WeightsL3.weight_engine_section` also
declares its `W_TO` argument as `~` — the engine group is built from thrust and component geometry).

**As built, guarded only where the dependency is real:** L2 → `W_landing_gear` (`0.033·W_TO`) and
`W_all_else_empty` (`0.17·W_TO`); L3 → the five that genuinely carry `W_dg`/`W_l` (`W_wings`, `W_tail`,
`W_fuselage`, `W_subsystems`, `W_l`). Verified live at L2: `W_landing_gear` and `W_all_else_empty` throw
`F16WeightsL2:WTONotSet` with `W_TO` unset, while `W_wings`/`W_tail`/`W_fuselage`/`W_installed_engine`
return 1766.0346 / 199.3890 / 3505.4511 / 3607.5273.

**Principle to keep: a guard must encode a real dependency, not a house style.** If a formula later
gains a `W_TO` term, add the guard then. Both `requireWTO` docstrings now say so.

**One loose end, flagged not fixed (a `.m` edit, outside this documentation step):**
`TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO` was written to be **red** while the
over-guard existed. The over-guard was removed in the same phase, so the test now **passes** — it is the
only one of the suite's eleven `testTODO_`-named cases that is green, which is why the coordinator's
count is "10 reds, all labelled". Its docstring still opens *"THIS TEST IS EXPECTED TO BE RED until a
small `F16WeightsL2.m` change lands"* and still gives a `HOW TO RESOLVE` recipe for work already done.
**Stale test docstring — needs either a rewrite into a positive assertion (`…ReadWithoutWTO`) or
deletion by decision.** Recorded here so a future reader does not "fix" a passing test by re-adding the
over-guard.

### §P4-19 — ★ NEW: a FALSE verification claim removed from `WeightsL3.m`'s header

The pre-Phase-4 `WeightsL3.m` header asserted that the §15.3.1 exponents had been *"re-verified
letter-for-letter against the Raymer 6th ed. p.572 equation page image (not OCR)"*. That claim was:

- **not checkable** — no such page image exists anywhere in this repo; and
- **self-contradictory** — the same file's high-level `weight_wing` / `weight_fuselage` comments carried
  `⚠ Exponents [verify]` warnings on the very equations the low-level `wing` / `fuselage` comments said
  were "all exponents confirmed".

The claim is **removed** from the header and from the wing / HT / VT / fuselage / gear / mounts method
comments, and replaced by an honest tally: **2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY /
5 extract-clean** (62 rows total, matching §3a), with the IMAGE-ONLY entry stating in plain terms that
the earlier claim was not checkable. Every method comment now reads
`⚠ EXPONENTS NOT BOOK-VERIFIED (class header, … rows …)`.

**Zero exponent values changed** — including the two CONFLICT rows, which keep their code values
(Eq. 15.13 `N_en^1.023`, Eq. 15.3 `cos(Λ_vt)^−0.323`) per the locked 2026-07-24 "approach 2" decision.
**§3a stays OPEN**, guarded RED by `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified`.

**Two new standing citation TO-DOs, both shipped as labelled reds.** Recorded together because they
share an implementation quirk: **each keys off its source file's own TO-DO sentence**
(`WeightsL1.m` / `WeightsL3.m` header text), because there is **no JSON marker key** to read for either
— unlike the geometry/aero `testTODO_` tests, which key off a `_TODO_*` key in the input JSON.

| Test | Guards | Verified |
|---|---|---|
| `TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo` | §P4-8 — Raymer Table 6.1's coefficients are not in this repo; the user must supply them. Table 3.1 is what the code uses | RED 2026-07-25 |
| `TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified` | §3a — all 62 exponent rows unverified against the printed book | RED 2026-07-25 |

### §P4-20 — ★ NEW: the shipped `f16a_requirements.json` `_comment` is already stale about `F16GeomL1`

**RESOLVED (2026-07-26 — see §D-2).** Re-read live: the `_comment` now states *"★ F16GeomL1 READS
design_mach FROM HERE as of Phase 4 … §P4-14, resolved"*. Two further copies of the same stale claim
— `f16a_L1.json .geometry._note` ("will error until repointed") and
`docs/weights_parameter_usage.md` — were corrected by the 2026-07-26 sweep. **§P4-14's broader
requirements-consolidation item stays OPEN.** Original evidence below.

The new requirements file's `_comment` states:

> *"★ F16GeomL1 IS PENDING: f16a_L1.json .geometry.M_max was deleted as the third copy of this quantity,
> so F16GeomL1.m:79 (obj.M_max = J.geometry.M_max) must be repointed here (todo 2026-07-25 Phase 4
> §P4-14)"*

**That work has landed.** As built, `F16GeomL1.m:64` is `function obj = F16GeomL1(json_path, req_path)`,
`:89` reads `R = jsondecode(fileread(req_path))` and `:90` sets `obj.M_max = R.design_mach`. So the file
documents its own consumer as pending when the consumer exists — the same class of staleness as §10 and
§P4-12, in a brand-new file. Not a numeric issue; a provenance/documentation one, and the sentence
would mislead the next person wiring a requirements consumer.

**Flagged, not edited** (a `.json` change, outside this documentation step). Note also that §P4-14's
*broader* item is genuinely still open — the full requirements consolidation across constraints and
mission has not been done — so §P4-14 must **not** be closed on the strength of this one fix.

### §P4-21 — NEW (residual): §P4-12's corrected ground-truth note has one stale sentence left

**RESOLVED (2026-07-26 — see §D-2).** Re-read live: the "framework CLASSES still default to 220/0"
sentence is gone. The `_note` now records that all three `F16WeightsL{1,2,3}` read the payload split
from the JSON and that the old 220/0 defaults are gone. Original evidence below.

`f16a_ground_truth.json .weights.inputs_on_Wt_tab._note` was correctly rewritten to say the payload
split now **agrees** (700/4400 on both sides; closure `31377 − 19980.70 − 6296.30 = 5100 = 700 + 4400`
exact). But its final sentence still reads:

> *"The framework CLASSES still default to 220/0 only because they do not read the JSON yet, which
> Phase 4 fixes."*

Both halves are now false: all three `F16WeightsL{1,2,3}` classes default to **700 / 4400** *and* read
the JSON. Small, but it is a sentence in the ground-truth file asserting something about the framework
that stopped being true in the same phase. **Flagged, not edited** — `GroundTruth/` is read-only by
convention and this is a `.json` change regardless.

### §P4-22 — NEW (Phase-2 miss, found while wiring `fidelity_comparison`): the L3 aero column was computed on L2 geometry

Not a weights item, recorded here because this is where it was found and because the failure *mode* is
the one these logs exist for. `examples/F16A/fidelity_comparison.m` (line 135 pre-fix; the corrected
call is now `:157`, `a3 = F16AeroL3(g3, f16a_spec_path(3))`, with the explanatory comment at `:148-154`)
still read `F16AeroL3(g2, …)` — so **that report's entire L3 aerodynamics column was silently computed
on the L2 geometry object**. Phase 2 repointed `F16ConstraintSet` and `aerodynamics_brandt_comparison`
at `g3` but missed this third call site.

Consequence recorded in-file: the L3 aero numbers in that report **move**, because L3 geometry is the
physical/T.O. tier (VT LE sweep 47.5 vs 40, `L_fus` 47.5 vs 46.5) and its `Amax` is the area-ruled
buildup rather than L2's fuselage-envelope ellipse.

**Why nothing caught it:** a wrong-but-valid tier yields *plausible numbers* rather than an error. And
critically, **the narrowed `mustBeA` guard could not have caught it either** — `F16AeroL3`'s constructor
guard admits any `GeometryBase`/`GeometryModelL2`-satisfying object, and **both tiers satisfy the
contract**, so construction succeeds and every property name resolves. The type system cannot
distinguish "the L2 geometry" from "the L3 geometry" here; only a call-site read can.

**Fixed:** the line now passes `g3`, with an in-file comment at `:148` recording the miss so it is not
re-introduced. Recorded as a standing lesson: **after a tier renumbering, grep every construction site
of the affected class**, because a same-contract wrong tier is invisible to both the guards and the
tests.

---

## 2026-07-26 — Documentation-lag sweep (closing out the 15-finding remediation)

**Context:** the four-phase remediation is implemented, tested and committed (`8ede0a8` → `f7bf65b`).
`run_all_tests` re-verified at HEAD: **501 tests / 491 pass / 10 red, all 10 labelled `testTODO_`,
zero unlabelled reds.** A three-way audit of the plan against the tree found the *code* complete
everywhere and the trailing *documentation* of two items never written, plus one guard that landed in
only one of its two required places. This section records that sweep. No numeric output moved.

### §D-1 — What was stale, and why it matters more than it looks

Every item below was a file **asserting something about the code that had stopped being true in the
same phase that made it false**. That is the exact failure mode this log exists to catch, and it is
worse than an absent doc: an absent doc sends you to the source, a confidently wrong one does not.

| File | Claimed | Actually |
|---|---|---|
| `src/disciplines/aerodynamics/AeroL1.md` | `get_CLmax` = `lookup_CLmax(aircraft_type)`, "Table 3.1 / 3.3" | Table 3.1 only, via `roskam_CLmax_value` — since `8152059` |
| `examples/F16A/fidelity_comparison.m` | note printed `CLmax: L1 … (0.90)` | its own `.json` already reported `1.5000` |
| `tests/disciplines/TestAeroL1.m` header | `CLmax = 0.90 … Table 3.3` | 1.50 / Table 3.1 (the tests below it were already correct) |
| `examples/F16A/F16GeomL1.md` | `F16GeomL1(json_path)`; `S_wet = 0`, `L_fuselage = 0` "populated on demand" | `(json_path, req_path)`; both `Dependent` on an input `W_TO`, erroring when unset |
| `examples/F16A/F16GeomL2.md` | `F16GeomL2(json_path)` | `(json_path, prop)`; `T_AB_SLS_lb` Dependent on `prop.T_SL` |
| `examples/F16A/F16AeroL2.md` | "`geom` is any `GeometryBase`" | `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])` |
| `docs/subplans/04_propulsion.md` | `F16PropL1/L2` read `T_SL_wet` from JSON | `T_SL_wet` is `Dependent`; the key was deleted from every JSON |
| `src/base/GeometryBase.md` | only `convert_sweep` (4/AR) | `convert_sweep_panel` (2/AR) has existed since Phase 1b — **closes §13** |
| `examples/F16A/F16AeroL3.md` | `Lambda_m_comp` "via `convert_sweep`" | VT uses `convert_sweep_panel` |
| `tests/disciplines/TestWeightsL3.m:822` | cross-referenced `TestWeightsL2.testTODO_PureAreaDerivedShouldNotRequireWTO` | that test was **deleted**; the question it named is settled, not open (§P4-18) |

**Six more found by the verification grep, not by the audit** — same two classes, in files the audit
had not opened. Recording them because the *ratio* is the point: a targeted read found ten, a
four-line grep found six more, and the grep cost nothing.

| File | Claimed | Actually |
|---|---|---|
| `docs/subplans/04_propulsion.md` (3 rows: the two class rows and the constructor-contract row) | `F16PropL1/L2` read `T_SL_wet` from JSON | `Dependent`; key deleted. Only the prose bullet had been fixed, not the tables |
| `examples/F16A/F16PropL1.md` | reads `T_SL_wet`; lists it under **Inputs** | `Dependent`; the file also claimed L1 has "no derived quantities" |
| `examples/F16A/F16PropL2.md` | reads `T_SL_wet`; lists it under **Inputs**; no `bypass_ratio` row | `T_SL_wet` `Dependent`, `bypass_ratio` = 0.71 is an input |
| `docs/subplans/05_weights.md` | the deleted test is "a **third** `testTODO_` case, now GREEN" | deleted |
| `docs/weights_parameter_usage.md` | "the **eleventh** `testTODO_` case … the only one that passes" | deleted; the count is ten, all red |
| `examples/F16A/F16WeightsL2.md` | "**PRESENT**, and now GREEN … flagged for review" | deleted |

`docs/propulsion_parameter_usage.md`'s `T_SL_wet` row was checked and left alone: it is a
framework-vs-Brandt comparison table, `F16Prop{L1,L2}.T_SL_wet` still exists and still reads 23,770,
so the row is accurate.

All corrected. The `AeroL1.md` and `fidelity_comparison.m` entries also gained the **L1↔L2 CLmax
discontinuity** note (1.50 statistical vs 0.913 geometry-based) that `AeroL1.m:77` promises — that
pointer had been dangling since the fix landed.

### §D-2 — §P4-20 and §P4-21 → RESOLVED (both were already fixed when re-checked)

Both were logged "flagged, not edited" in the Phase-4 as-built re-status, because that was a
documentation-only pass. Both had in fact been corrected in the commits that closed the phase, and
live re-reads on 2026-07-26 confirm it:

- **§P4-20** — `f16a_requirements.json` `_comment` now reads *"★ F16GeomL1 READS design_mach FROM
  HERE as of Phase 4 … §P4-14, resolved"*. The residual copy of the same stale claim in
  `docs/weights_parameter_usage.md` and in `f16a_L1.json .geometry._note` ("★ IMPLEMENTER: …will
  error until repointed") is corrected by this sweep.
- **§P4-21** — `f16a_ground_truth.json .weights.inputs_on_Wt_tab._note` no longer contains the
  "classes still default to 220/0" sentence; it states the payload split agrees and closure is exact.

**§P4-14's broader item stays OPEN** — the full requirements consolidation across constraints and
mission has not been done. Do not close it on the strength of these.

### §D-3 — `ConstraintAnalysis` had no non-finite guard, and the right check is NaN-only

The 15-finding remediation specified the loud-failure guard for **both** `Both_WbyS_TbyW.required_TW`
and `ConstraintAnalysis`; only the former landed. Now added — but **not** as the `~isfinite` the
original wording implied, and the difference is the substance of this entry:

- **`Inf` is meaningful here and must keep working.** Wall-type constraints encode "infeasible above
  my W/S limit" as `Inf` (`LandingConstraint.m`; `ConstraintAnalysis.m` class header). An `~isfinite`
  check would have broken every wall constraint — a guard that breaks correct code.
- **`NaN` is the actual hazard, for a reason specific to MATLAB.** `max`/`min` **omit NaN by
  default**, so a NaN row silently drops out of `max(obj.TW_table, [], 1)`. The aggregate then reads
  as though that condition were never supplied, and `optimal_point()` returns a design point
  satisfying one fewer constraint — no warning, plausible-looking answer. Same "unevaluable reads as
  satisfied" family as the original finding, by a different mechanism.
- **Why a second layer at all**, given `Both_WbyS_TbyW` already checks: that check only protects
  constraints built on the Master Equation. A category computing `required_TW` some other way (a wall
  bound; any future tabulated or interpolated condition) never passes through it. The aggregator is
  the one place **every** constraint type funnels through.

As built: `ConstraintAnalysis.assertNoNaN` (private static), called per constraint at construction,
naming the offending constraint and the first W/S at which it went NaN. Tests in
`tests/constraints/TestConstraintAnalysis.m` cover the error, the error alongside valid constraints,
that `Inf` is still accepted, and — asserted directly against MATLAB rather than against our code —
that `max()` omits NaN, so the test stays meaningful if the guard ever moves. The NaN curve comes
from a new `tests/constraints/NaNCurveStub.m`, necessarily a stub: a real `ThrustConstraint` throws
`Both_WbyS_TbyW:nonFiniteTerm` first and the aggregator's guard is never reached.

### §D-4 — Standing lesson

**A signature or contract change must sweep the companion `.md` in the same commit.** This is the
sibling of §P4-22's "after a tier renumbering, grep every construction site". Both failures share a
shape: the change was correct, the tests stayed green, and the only casualty was a *description*
elsewhere in the tree that nothing executes and nothing checks. Neither the compiler nor the suite
can catch it. The cheap mitigation is a grep at commit time — `F16GeomL1(`, `F16GeomL2(`,
`T_SL_wet`, whatever the changed name is — across `*.md` as well as `*.m`.

---

*Add new dated sections above this line for future discrepancies; do not edit or remove prior
entries. Where an entry is resolved, PREPEND the decision and keep the original evidence intact —
several entries (§1, §2, §7, §8, §17, and the 2026-07-24 propulsion/weights entries) now carry
resolutions in that form.*
