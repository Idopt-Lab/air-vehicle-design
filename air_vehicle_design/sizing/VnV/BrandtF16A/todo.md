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

*No entries resolved. Add new dated sections above this line for future discrepancies; do not
edit or remove prior entries.*
