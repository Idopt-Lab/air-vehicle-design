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
`GroundTruth/cell-map.md`, `baseline/extract_brandt.m` (removed 2026-08-04), and `BrandtGeometry.m`
all already, consistently, cite** (`extract_brandt.m:76,83`: `get("Geom","B3")` → `fus_simple`,
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

## 2026-07-24 — Propulsion deep-dive, Phase A (documentation)

**Recovery note (2026-07-30):** this section, and the sibling 2026-07-24/25 Weights and GeomL3
sections, existed in this file and were lost during merge commit `47520d2` (its two parents had 307
and 2421 lines; the merge result kept only 128). Several files across Propulsion and Weights still
cite this exact section by name ("2026-07-24 entry 1/4", "P4-1" through "P4-22") — those citations
were correct all along; the record they pointed to was just missing from the live file. Recovered
verbatim from commit `8a2661c53a9b69d8184483c82a7a00d6902be3d3` (a parent of the merge). The Weights
Phase-4 sections (§P4-1 through §P4-22, the 62-row exponent checklist) are not restored here — this
recovery is scoped to Propulsion, since that is the discipline under review; the same recovery
technique resolves the Weights side too, whenever that is prioritized.

**Addendum (2026-07-30):** the 62-row exponent checklist's row COUNT (62) was always correct — it
matches the recovered table's actual row count exactly. Its CATEGORY breakdown, quoted everywhere as
"2 CONFLICT / 9 FROM-CODE / 24 VERIFY / 27 IMAGE-ONLY / 5 extract-clean" (summing to 67), was wrong
in the original, lost content itself, not introduced by the merge loss. A direct recount of the
recovered table gives the correct breakdown: **2 CONFLICT / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY**,
which sums to exactly 62 with no separate fifth category. This correction has been applied everywhere
the wrong breakdown was quoted (`WeightsL3.m`, `TestWeightsL3.m`, the original weights design plan,
`F16WeightsL3.md`). The full 62-row table itself is still not restored into this file.

**Context:** Phase-A documentation pass for the Propulsion deep-dive (mirrors the Geometry and
Aerodynamics deep-dives). Cross-checked the live propulsion code (`src/base/PropulsionBase.m`, the
`PropL{1,2}` / `PropulsionModelL{1,2}` toolboxes/enforcers, `examples/F16A/F16Prop{L1,L2}.m`), the
existing tests (`tests/disciplines/TestProp{L1,L2}.m` — read for citations only, NOT for expected
values, per the anti-self-referential rule), the ground truth (`readme_prop.md`, `BrandtEngine.m`,
`GroundTruth/cell-map.md` Engn(s)/Consts rows, `readme_consts.md`, `readme_mission.md`, `README.md`),
the reference extracts (`docs/reference_extracts/{mattingly,metabook,raymer}_data.md`),
and `baseline/F16Baseline.m` (removed 2026-08-04). I did **not** open the live `Brandt-F16-A.xls` (documentation-only
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
- the original propulsion design plan: *"α (thrust lapse) | (ρ / ρ_SL)^0.6 | Raymer 6th ed, Ch 3"*
The repo Martins extract (`metabook_data.md`) confirms Eq. 10.7 (turbojet, m=1.0) and Eq. 10.9
(turbofan, general m; the specific m=0.6 is the Ch. 4 approximation, `metabook_data.md` line 226). No
Raymer §5.4 extract exists in the repo (`raymer_data.md` covers Ch. 10/12/15 only) → the "Raymer §5.4"
/ "Raymer Ch 3" citation is unverifiable AND conflicts with the verified Martins citation.
**RESOLVED (user, 2026-07-24):** use **Martins metabook Eq. 10.9** as the source for α = σ^m. The
`PropulsionModelL1.m` / `TestPropL1.m` "Raymer §5.4" and the original propulsion design plan's
"Raymer Ch 3" citations are to be corrected to Martins in the implementation step (Step 1c). No `.m`/`.json` files were edited in this
documentation pass.

### Entry 2 — Design-plan TSFC units drift (/3600 → 1/s) vs. code (1/hr throughout) — RESOLVED (user, 2026-07-24)
The original propulsion design plan states TSFC is converted to 1/s:
- `:72-73`: *"low-BPR mixed turbofan: 0.8/hr → /3600 → 1/s"*, *"0.7/hr → /3600"*
- `:79-80`: *"(0.9 + 0.30 × M) × sqrt(θ) [1/hr → /3600]"*, *"(1.6 + 0.27 × M) × sqrt(θ) [1/hr → /3600]"*
The code keeps TSFC in **1/hr** everywhere, with no /3600: `PropL1.lookup_TSFC_table`/`get_TSFC`
(0.80/0.70), `PropL2.TSFC_mil`/`TSFC_AB`, and `PropulsionBase.m:11` (*"TSFC in
lbf_fuel/(hr·lbf_thrust) [1/hr]"*). The original design plan misstates the as-built unit.
**RESOLVED (user, 2026-07-24):** use **1/hr** for TSFC throughout — the code's 1/hr is correct; the
design plan's `/3600 → 1/s` statements are wrong and will be corrected to 1/hr in the docs-cleanup step
(1d, in the original propulsion design plan). No `.m` change needed (code is already 1/hr).

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
**2026-07-30 update:** Sarojini, also on this project, has the Raymer 7th edition and will confirm
this citation when he next runs Claude Code on his own workstation — this repo currently has no 7th
edition source, so this recovered entry's "Raymer 7th ed." attribution stays a TODO pending his check
(see `PropL2.m`'s `engine_diam_nonAB`/`engine_diam_AB`/`engine_weight_AB` for the marker).

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
`baseline/F16Baseline.m` (removed 2026-08-04) treat `Consts!AT{23-28}` = α_AB and `Consts!AU{23-28}` = α_mil renormalized
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

### Entry B — Brandt Engn AB-thrust-equation cell ROW: readme_prop row 6 vs. F16Baseline (removed 2026-08-04) row 15 — flagged/deferred → RESOLVED (live-xls read, 2026-07-24)
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

## 2026-07-28 — Tail Sizing deep-dive (scribe phase)

**Context:** promoting the standalone `TailSizingLevel1`/`F16TailSizingLevel1` volume-coefficient
helper into a full three-tier discipline (`TailSizingBase`/`TailSizingModelL{1,2,3}`/`TailL{1,2,3}`/
`F16TailL{1,2,3}`), per coordinator instruction. Full writeup, tables, and equation-level detail for
all three findings below live in `src/disciplines/tail_sizing/TailSizing_scribe_plan.md` (§§2, 5.1,
6, 7). Per the standing scribe rule, none of the three were resolved unilaterally at write-time —
logged for user review. **UPDATE (2026-07-28, same day):** the user has since reviewed and decided
Findings 2 and 3; status lines added to each below. Finding 1 remains open (out of scope for this
deep-dive to fix). See `TailSizing_scribe_plan.md` §§2, 5.1, 6, 7, 8 for the full decision record.

### Finding 1 — Nicolai & Carichner F-16 tail-volume-coefficient value: propagation error across three reference-extract files
`docs/reference_extracts/nicolai_data.md`,
`docs/reference_extracts/roskam_vol2_data.md`, and
`docs/reference_extracts/usaf_f16_data.md` all state the F-16's row in Nicolai &
Carichner's Table 11.6 ("Tail Volume Coefficients for Fighter Aircraft") as `C_HT=0.68, C_VT=0.041`
(`roskam_vol2_data.md` and `usaf_f16_data.md` both cite `nicolai_data.md` as their source for this
pair, so the error appears to originate in that one file and propagate outward).

The properly page-cited, "done"-status chapter extract itself —
`docs/reference_extracts/11_tail_sizing.md` §"Table 11.6 — Tail Volume
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
- `docs/reference_extracts/` is entirely **Nicolai & Carichner**, not Raymer (see
  that folder's own `00_README.md`). Its Chapter 11 (`11_tail_sizing.md`, "done") covers only the
  volume-coefficient method and explicitly defers criteria-based tail sizing to *its own* Chapter 21
  ("Static Stability and Control") and Chapter 23 ("Control Surface Sizing Criteria") — both listed
  **"pending"** (not yet extracted) in the same README's progress table.
- `docs/reference_extracts/raymer_data.md` (the actual Raymer OCR extract) covers
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

## 2026-07-31 — Subsystems deep-dive, Phase A (documentation): `gear` block provenance and implied gear-load-split

**Context:** scribe documentation pass for the brand-new Subsystems discipline
(the original subsystems design plan), researching a citable source for the new `F16LandingGearL2`/`L3`
classes' "gear-load-split" input (what fraction of `W_TO` each gear carries, needed to get the
per-wheel load `W_w` that Raymer's statistical tire-sizing formula, Table 11.1, takes as its argument).
Did **not** open the live `Brandt-F16-A.xls` in this pass (documentation-only; no MATLAB MCP/COM tool
was available in this session) — both findings below are from the repo's existing JSON/`.m`/`.md`
files and need a live-workbook check before either is trusted or corrected.

### Finding 1 — `f16a_geometry.json`'s `gear` block has no cell citation and no corroboration elsewhere in `VnV/BrandtF16A`
`GroundTruth/f16a_geometry.json`'s top-level `"gear"` object (`x_nose_ft=22.0`, `x_main_ft=37.7`,
`y_main_ft=6.0`, `h_nose_ft=5.3`, `h_main_ft=5.3`, `d_nose_ft=1.5`, `d_main_ft=2.0`) carries only
`"_source": "Gear tab — landing gear geometry"` — no cell letter/number, unlike every other block in
that file. Grepped `readme_geom.md` (its own §2 "Input Schema" table, which is supposed to be the
complete list of `f16a_geometry.json` input regions) and `GroundTruth/cell-map.md` for any mention of
"gear"/"tire"/"Gear" — **zero matches in either file.** The block IS consumed live, by
`BrandtBalanceStabControl.m:211-221` (`obj.inp.gear.x_nose_ft` etc., feeding `gear_main_pct`,
`gear_nose_pct`, `tipback_deg`, `rollover_deg`), and `readme_bsc.md:39` does note *"`gear` JSON section
→ longitudinal / lateral gear geometry"* as a cross-tab dependency — but with no cell reference either,
and it never mentions `d_nose_ft`/`d_main_ft` (the tire diameters) at all, which `BrandtBalanceStabControl.m`
also never reads (only `x_nose`, `x_main`, `y_main`, `h_main` are used by that class — the two tire
diameters exist only in the raw JSON, unused and uncross-checked by any `.m` file in this repo).

**Why it matters now:** the Subsystems deep-dive wants to use `d_nose_ft=1.5`/`d_main_ft=2.0` (18 in /
24 in) as an independent comparison-report data point for the new Raymer-statistical tire-sizing
formula. Doing so on data with no cell address and no cross-check anywhere else in `VnV/BrandtF16A`
would be citing a number this project cannot itself currently trace back to the workbook.

### Finding 2 — `BrandtBalanceStabControl`'s computed gear-load-split (26.7 % main / 73.3 % nose) contradicts the typical/textbook fighter split
`readme_bsc.md`'s own "Gear load split" equation, `%W_main = 100·(x_cg−x_nose)/(x_main−x_nose)`, applied
to the stored values above plus the documented validation target `xcg_TO ≈ 26.193 ft`
(`readme_bsc.md:66`), gives: `%W_main = 100·(26.193−22.0)/(37.7−22.0) = 26.7%`, `%W_nose = 73.3%` —
exactly matching `readme_bsc.md:68`'s own stated validation target ("Gear split about 26.7% main /
73.3% nose"), so this is not an arithmetic slip in the code; the formula and the stored numbers are
**self-consistent** with each other.

The problem is that this result contradicts well-established fighter landing-gear practice, including a
source already in this repo: `docs/reference_extracts/08_fuselage_sizing.md` §8.1.7
(Nicolai & Carichner, p.202): *"Nose gear rule of thumb: 20% of TOGW on the nose wheel for good
steering."* It also contradicts Raymer's stated typical split (Ch. 11 p.344 prose, *"the main tires
carry about 90% of the total aircraft weight... Nose tires carry only about 10%"* — see
the original subsystems design plan's Equations & Citations §8). A real F-16 nose gear carrying 73% of
`W_TO` (vs. main gear's 27%) would be a radically unconventional, almost certainly incorrect,
weight-and-balance configuration for a tricycle-gear fighter. The likely candidates are: `x_nose_ft`/
`x_main_ft` in the uncross-checked `gear` block (Finding 1) being wrong, mislabeled, or measured in a
different sense than "gear station from the aircraft's coordinate origin"; or `xcg_TO_ft` itself being
off; or the two aircraft-type-agnostic textbook rules of thumb simply not applying well to this specific
airframe/coordinate convention. **Not adjudicating between these** — logging for the next person to
check against the live `Brandt-F16-A.xls` "Gear" tab and, ideally, the BSC tab's own `gear_main_pct`
cell if the Excel model itself computes one.

**Why it matters now:** the new `F16LandingGearL2`/`F16LandingGearL3` classes need a gear-load-split
input to convert `W_TO` into the per-wheel load `W_w` that Raymer's Table 11.1 tire-sizing formula
takes as its argument. The original subsystems design plan recommends defaulting to Raymer's own stated
90%/10% (needs no geometry, matches the discipline's "statistical method" framing) and explicitly
**not** wiring in the Brandt-derived 26.7%/73.3% split until this is resolved. **Flagging for user
review — not resolved here**, per the standing scribe rule. Needs: (a) a live-`Brandt-F16-A.xls` COM
read of the actual "Gear" tab cells to get real cell references for
`x_nose_ft`/`x_main_ft`/`d_nose_ft`/`d_main_ft`, and (b) a decision on whether `xcg_TO_ft` or the gear
station values are the more likely source of the discrepancy, or whether it is not a discrepancy at all
(e.g. a coordinate-convention misunderstanding on this reviewer's part).

---

## 2026-08-03 — Stability & Control deep-dive, Phase A (documentation): BSC-sheet cell-map gap + blocked live-workbook checks → RESOLVED (live-xls read, 2026-08-03)

**Context:** scribe documentation pass for the original Stability & Control design plan (longitudinal
static stability in steady level flight only). No MATLAB COM/`actxserver`-
capable tool was available in this session (only `Read`/`Grep`/`Glob`/`Write`/`Edit`/`WebFetch`) — `Read`
on any `.xlsx` fails outright ("cannot read binary files"). Two items are logged here as gaps discovered
while trying to cross-check against live workbooks, per this file's stated scope ("or gaps discovered
while cross-checking against the live workbook") — neither is a resolved disagreement.

### Gap 1 — `GroundTruth/cell-map.md` has zero cells for the BSC (balance/stability/control) sheet
Grepped `cell-map.md` for "BSC", "balance", "neutral point," and the sheet-name patterns used for every
other discipline — no matches; the file documents `Main`/`Geom`/`Aero`/`Wt`/`Engn(s)`/`Consts`/`Miss`/
`Size&Opt` sheets only. `readme_bsc.md:6` states *"Key Excel anchors are the `BSC` / balance-control
cells for MAC, CG, gear split, tipback, and rollover"* but itself gives no cell letters/numbers anywhere
in the file — `BrandtBalanceStabControl.m` computes everything from `geom`/`wt`/`aero` object outputs
plus the `gear` JSON block (itself already flagged as under-cited in the 2026-07-31 entry above), never
reading a `BSC!`-prefixed cell directly anywhere in the `.m` file. So it is unclear whether a literal
"BSC" sheet even exists in the live workbook to cite, or whether this project's ground-truth code
reimplements the balance/S&C logic from first principles instead of reading such a sheet. **Could not
check which, this pass** — no live-xls access. Needs a live `Brandt-F16-A.xls` read to either (a) find
and cell-map an actual "BSC" (or similarly-named) sheet, confirming `readme_bsc.md`'s "Key Excel anchors"
claim with real cell references, or (b) confirm no such sheet exists and correct `readme_bsc.md`'s
wording, which currently implies one does.

**RESOLVED (live-xls read, 2026-08-03):** opened `Brandt-F16-A.xls` via MATLAB `readcell` (read-only).
The workbook has no sheet literally named "BSC" — the sheet is named **`S&C (2)`** (118 rows × 23 cols),
exactly the sheet the original S&C design plan's "Ground Truth" section had speculated about. Its longitudinal-static-
stability rows (`xnp`, `xcg_Lndg`, `xcgTakeoff`, `SM`) match `readme_bsc.md`'s recorded ground-truth
values essentially exactly (`x_np=26.1677 ft`, `x_cg_land=26.1369 ft`, `x_cg_TO=26.1925 ft`), confirming
`readme_bsc.md`/`BrandtBalanceStabControl.m` already reads this sheet's numbers — `readme_bsc.md:6`'s
"BSC" wording should be read as an informal nickname, not a literal sheet name; `cell-map.md` should gain
an `S&C (2)` entry. Full cell layout (which rows hold which quantity, and their in-sheet citations —
several rows cite **Roskam Eqns 3.17/3.19/3.24/3.38**, not Raymer Ch. 16) is now written up in
the original S&C design plan's "Ground Truth" section, "Live-workbook read (2026-08-03,
coordinator session)" subsection. Most of the sheet (lateral-directional derivatives, short-period
dynamics) is out of the original design plan's scope and was not cell-mapped in detail.

### Gap 2 — `temp_Casey/inputs/F-16A Block 50.xlsx`'s `Stability&Control` sheet: existence corroborated in code; cell layout and any overlap with `BrandtBalanceStabControl` unchecked
A different workbook from Gap 1 — `temp_Casey`'s legacy input file, not Brandt's ground-truth file.
`temp_Casey/src/ComputationModels/StabAndCont/SandCUtils.m:10` hardcodes
`readtable(file_name, 'Sheet', "Stability&Control", 'ReadRowName', true)` against a workbook resolved
from `designName = "F-16A Block 50"` (`temp_Casey/examples/F-16A B Block 10 and 15/
F16A_Level{1,3}_Sizing_ClassBased_Example.m:24`/`:31`) — strong code-side corroboration that this sheet
exists and holds a component-name-keyed table (consumed by `SandCLevel3.get_cg` as
`component_weight_list`/`component_weight_x_locations`). Could not open the binary `.xlsx` this pass
(`Read` tool rejects binaries; no COM/`actxserver` tool available) to confirm the exact cell layout, or to
check whether its component x-locations/weights duplicate or conflict with
`BrandtBalanceStabControl.m`'s own computed `xcg_*_ft` properties (wing, fuse, pitch, vert, nacelle,
strake, engine, gear, inlet, ctrl, elec, hyd, ECS, other, avionics, armament, fuel1/2/3) — two
independently-sourced component-station tables that may describe the same physical aircraft. **Why it
matters now:** the original S&C design plan's "Component-x-location buildup" section plans a
brand-new S&C-owned input table built fresh from `WeightsL3`/`GeomL3`; this legacy sheet is a candidate
pre-existing alternative (or cross-check) that has not been evaluated. Needs a live-workbook read (both
files) before `io` builds the new table, and before deciding whether the legacy sheet's numbers should
inform it. Full detail in the original S&C design plan's "Ground Truth" section, "Scribe
follow-up (2026-08-03)" subsection.

**RESOLVED (live-xls read, 2026-08-03):** opened `temp_Casey/inputs/F-16A Block 50.xlsx`'s
`Stability&Control` sheet via MATLAB `readcell` (read-only; confirmed real per Casey directly). 24 rows
× 5 columns: `[component name] | Weight (lbf) | CG X-Location (ft) | X-MAC | Y-MAC` (the last two columns
unpopulated). 22 component rows: Wing, Fuselage, HT, VT, Nacelles, Strakes, Engine, Gear, Inlet duct,
Controls, Electrical, Hydraulics, ECS, Other, Avionics, Armaments, Fixed Payload, Exp Payload 1/2, Fuel
1/2/3 — matching `BrandtBalanceStabControl.m`'s own `xcg_*_ft` property list almost 1:1. **Not checked
line-by-line against `BrandtBalanceStabControl.m`'s computed values** (that comparison is still future
work, deferred to the `io` pass per the original S&C design plan's "Ground Truth" section) —
this resolution closes only the "does the sheet exist, and what is its cell layout" question, not the
"do the two sources agree" question.

---

## 2026-08-04 — Stability & Control deep-dive, Phase B: primary-source (Raymer 6th ed. physical PDF) read corrects the 2026-08-03 web-cross-check → RESOLVED (Casey's Fig. 16.14 chart read, 2026-08-04)

**Context:** Casey supplied the actual Raymer 6th ed. PDF (`AircraftDesignAConceptualApproach_Raymer_6ed.pdf`,
Ch. 16 starts book p.585 / PDF p.615) directly, ahead of the implementation loop. The coordinator read
Ch. 16 in full (book pp.585–619, covering all of §16.3 "Longitudinal Static Stability and Control" plus
the start of §16.4 "Lateral-Directional," which is out of scope and not read further) via extracted PDF
pages (PyMuPDF page extraction to a scratch file, since the source PDF is too large for direct text
extraction). This supersedes the 2026-08-03 web-cross-check entries in the original S&C design plan
("Equations & Citations" §1/§2) with a primary-source read. Three corrections and one new gap found:

### Correction 1 — Eq. 16.8 is `Cm_α` (the pitching-moment DERIVATIVE), not a "full itemized Cm_cg buildup"
The 2026-08-03 web cross-check guessed Row 3 ("Cm_cg buildup (full itemized)") was Eq. 16.8, itemizing
`Cm_fus` as an explicit additive term alongside `Cm_cg`. **This was wrong.** Raymer's actual Eq. (16.8)
(p.592) is:
```
Cm_α = CL_α(X̄cg − X̄acw) + Cm_α,fus − η_h(S_h/S_w)CL_αh(∂α_h/∂α)(X̄ach − X̄cg) + (F_pα/(qS_w))(∂α_p/∂α)(X̄cg − X̄p)
```
— the pitching-moment-derivative-with-respect-to-α equation, immediately followed by Eq. (16.9) (neutral
point, solving `Cm_α=0`) and Eq. (16.10)/(16.11) (Cm_α restated in terms of `X_np`; static margin). There
is no separately-numbered "full itemized Cm_cg" equation beyond Eq. (16.7) (coefficient form, Row 2) —
`Cm_fus` is already inside Eq. (16.7)'s `Cm_fus` term (the web source's buildup wasn't wrong on content,
just on which equation number it belongs to). Row 3 in the original design plan should be re-labeled as `Cm_α`
(Eq. 16.8), a genuinely distinct quantity from Row 2, not a variant of it.

### Correction 2 — Eq. 16.9 DOES have a thrust term; Raymer's own text sanctions dropping it ("power-off")
The 2026-08-03 web cross-check's source claimed "no `/57.3` conversion appears... no thrust term." The
primary source (p.592) shows Eq. (16.9) DOES include `(F_pα/(qS_w))(∂α_p/∂α)` in both numerator and
denominator. However, Raymer's own text immediately after (p.593) states: *"It is common to neglect the
inlet or propeller force term `F_p` in Eq. (16.9) to determine 'power-off' stability... Power effects are
then accounted for using a static-margin allowance based upon test data for a similar aircraft.
Typically, these allowances for power-on will reduce the static margin by about 1–3% for jets."* This is
now a **citable, Raymer-sanctioned simplification** (not an invented one) for implementing Eq. 16.9
without a thrust-location input — matches Casey's own earlier, independently-recalled note about "a 2%
reduction per unit prop-to-CG distance, normalized by MAC," which this primary-source passage appears to
be the actual origin of.

### Correction 3 — Eq. 16.25's `Cm_α,fus` formula: "per deg" units CONFIRMED exactly, resolving the `/57.3` legacy-bug question with full confidence
Eq. (16.25) (p.603): `Cm_α,fuselage = (K_fus·W_f²·L_f)/(c·S_w)`, **explicitly labeled "per deg"** in the
book, cited to NACA TR 711, with `K_fus` read off Fig. 16.14 (empirical chart vs. "position of root
quarter-chord as percent of fuselage length"). This is an EXACT match, including the missing-factor bug:
`temp_Casey/src/Disciplines/StabAndCont/SandCLevel3.m`'s `compute_cm_alpha_fuselage` (lines 455–458)
computes exactly `(K_fus*W_f^2*L_f)/(c*S_w)` with a code comment "% per deg" and cites "Raymer 6th ed, eq
16.25" directly — confirming the legacy code's formula is correct AS A PER-DEG QUANTITY, but every
downstream consumer (Eqs. 16.8/16.9, which are per-RADIAN throughout) must multiply this term by
`180/π` (≈57.3) to convert before use — exactly the missing factor flagged in the original design plan's
Legacy Bugs table 2026-08-03 entry, now upgraded from "likely, web-sourced, not independently confirmed" to
**CONFIRMED, primary source, Raymer 6th ed. p.603, verbatim "per deg" label**.

### New gap — Fig. 16.14's `K_fus` chart has no digitized/citable numeric value anywhere in this repo
Legacy code reads `K_fus = design.geom.wings.Main.Kfus` (line 121) — a property with NO numeric
definition found anywhere searchable in `temp_Casey` (grepped the whole `sizing/` tree for
`Kfus`/`K_fus`: only the two `SandCLevel3.m` read-site hits and the original design plan's own prose exist; no config,
input file, or `.mat` sets a value). Fig. 16.14 is a chart (K_fus, y-axis 0–0.05, vs. x-axis "position of
root quarter-chord as % of fuselage length," 10–60%; NACA TR 711) with no in-repo digitization. **Not
resolved here** — flagged for the implementation phase to either (a) digitize a handful of points
directly off the chart image with an explicit "approximate, read from Fig. 16.14, pending Casey's
physical-book spot-check" caveat (matching this repo's existing convention for chart-sourced values, e.g.
`AeroL1.CLmax_table`), or (b) treat as a GAP-stubbed sub-term the same way `x_p`/`i_w`/`i_h` are being
handled elsewhere in this discipline, pending Casey's decision.

### Confirmed exactly, no correction needed
Eq. 16.4 (Row 1), Eq. 16.5/16.7 (Row 2), Eq. 16.11 (Row 5, `SM=(X̄np−X̄cg)`, no `/100`), Eq. 16.12 (Row 6 —
**all 5 coefficients now confirmed** including the `0.4`/`1.1` breakpoints and the `2.5` exponent, not
just the 3 Casey spot-checked on 2026-08-03), Eq. 16.13/16.14 (Rows 7/8), and Eqs. 16.15–16.18 (Row 9) all
match the original design plan's existing formulas exactly. One scope clarification on Row 9: Eqs. 16.15–16.18 are the
GENERAL plain-flap/control-surface-deflection family (the book explicitly applies it to "elevator,
aileron, and rudder" alike, p.596) — not a separately-numbered "elevator-specific" equation as the
2026-08-03 entry's phrasing implied. Casey's choice to use this family (Eq. 16.16 combined with Eq.
16.18's empirical upper-bound cubic-in-`c_e/c` form) for elevator trim, instead of the Ch. 12 high-lift
`ΔCL_max` treatment, is confirmed correct and now fully primary-source-backed, not just web-sourced.

**RESOLVED (Casey's own Fig. 16.14 chart read, 2026-08-04):** Casey read the chart directly for the F-16's
actual root-quarter-chord position — main-wing x-location `4.0725 ft`, root-quarter-chord x-position
`21.8625 ft` (both measured positive downstream from the nose), giving root-quarter-chord as a fraction of
fuselage length = `21.8625/L_f` = **44.17%**. Reading Fig. 16.14 at that position gives **K_fus ≈ 0.025**.
This is now a citable, single-scalar F-16 input (Raymer Fig. 16.14, Casey's physical-book read,
2026-08-04) — no chart digitization/lookup table needed; `K_fus=0.025` goes into
`examples/F16A/jsons/f16a_L3.json`'s `.stability_control` block as a new input, cited exactly this way.

---

## 2026-08-04 — Roskam-book search, take 2: checked the actual PDFs in Casey's Documents/Readings folder, not just extract filenames

**Context:** the earlier 2026-08-04 entry's "Roskam book not in this repo" finding was based on grepping the
in-repo `roskam_vol{1,2,3}_data.md` extracts by filename/section-number pattern, not on opening a source
PDF directly. Casey pointed at `C:\Users\John Freeman\...\Documents\Readings\` (the same folder the Raymer
6th-ed. PDF came from) and asked to skim any Roskam text there for the Ch. 3 "Static Longitudinal
Stability and Control" material (Eqns 3.17/3.19/3.24/3.38) Brandt's own `S&C (2)` sheet cites.

**Files present, opened directly (title page read via PyMuPDF, `AircraftDesign_vol1/2/3_Roskam.pdf` bodies
also full-text-searched for "static longitudinal stability"/"neutral point"/"3.17"+"stability" — zero
hits in vol1/vol2; vol3 has no OCR text layer at all, confirmed by sampling text extraction across its
462 pages, but its title page — Part III, "Layout Design of Cockpit, Fuselage, Wing, and Empennage" — is
a physical-layout topic, not a stability-derivative one, so it is not a plausible match regardless):**
- `AircraftDesign_vol1_Roskam.pdf` = **Airplane Design, Part I: Preliminary Sizing of Airplanes** (2018)
- `AircraftDesign_vol2_Roskam.pdf` = **Airplane Design, Part II: Preliminary Configuration Design and
  Integration of the Propulsion System** (2018)
- `AircraftDesign_vol3_Roskam.pdf` = **Airplane Design, Part III: Layout Design of Cockpit, Fuselage,
  Wing and Empennage** (2002)
- `airplane-design-part-1_compress.pdf` = a second copy of Part I (same title page as vol1)

**CONFIRMED (direct file check, supersedes the earlier filename-based inference): none of these is
Roskam's separate title, "Airplane Flight Dynamics and Automatic Flight Controls, Part I," the book
Brandt's `S&C (2)` sheet's Ch. 3 numbering (3.17–3.38) actually belongs to.** That title is not present in
this Readings folder under any filename. The "Major new lead" callout in
the original S&C design plan and the earlier todo.md entry both stand as written — this is
independent confirmation, not a reversal.

**Bonus finding, not what was asked but relevant:** `aircraft_design_metabook.pdf` (Martins, "The
Metabook of Aircraft Design") has its own Ch. 8 "Stability and Control" section (pp.85–91) with an
equivalent `Cm_cg`/neutral-point/static-margin formulation, and gives its own fuselage-moment term
(Eq. 8.17, its own numbering) citing the SAME NACA TR 711 source as Raymer's Eq. 16.25/Fig. 16.14, with a
digitized table (Table 8.1, `Kf` vs. wing-quarter-chord position as a fraction of fuselage length, sourced
to Jacobs & Ward 1936 / Schlichting & Truckenbrodt 1979) instead of a chart. After reconciling the two
formulas' different presentation (Martins divides through by `CL_αw`; Raymer's Eq. 16.25 does not — the
two are algebraically the same `Cm_α,fus = K·W_f²·L_f/(c̄·S_w)` once Martins' extra `CL_αw` divisor is
cancelled back out), Martins' table is a genuinely independent digitization of the same empirical curve,
and gives K-factor magnitudes in the same rough neighborhood as Casey's own Fig. 16.14 chart-read (both
land in a similar order of magnitude at a comparable root-quarter-chord-%-fuselage-length position, though
not an exact match — expected, since eyeballing a chart and reading a table are both approximate, and the
two sources digitize slightly different curve versions). This is a nice-to-have secondary cross-check for
the already-implemented `Cm_α,fus`/`K_fus=0.025` term, not a citation gap or a reason to change the
implemented value — flagging here for the record in case a future pass wants a second data point.

---

## 2026-08-04 — Roskam Flight Dynamics book supplied by Casey, opened directly: right book, equation numbers don't match Brandt's citations

**Context:** immediately after the previous 2026-08-04 entry (confirming the actual "Airplane Flight
Dynamics and Automatic Flight Controls, Part I" title was NOT in Casey's Documents/Readings folder),
Casey added the real file there:
`airplane-flight-dynamics-and-automatic-flight-controls-part-1_Roskam.pdf` (Jan Roskam, 1979 first
printing, "PART I: CHAPTERS 1 THROUGH 6, Rigid Airplane Flight Dynamics (Open Loop)"). This is
unambiguously the correct title — title page confirmed by direct render (no OCR text layer exists
anywhere in this PDF; it is fully scanned images, so everything below was read by rendering pages and
viewing them directly, plus a Tesseract OCR pass over ~90 pages purely to locate candidate equation
numbers before visually confirming each one).

**What was checked, page by page, against Brandt's four cited numbers (`a`/`a0L` → Eqn 3.17; `aHS` →
Eqn 3.19; `CLa` (aircraft) → Eqn 3.24; `xbarnp`/`xnp` → Eqn 3.38 — per the 2026-08-03 live-workbook read
recorded above):**

| Brandt's citation | What this book's SAME-NUMBERED equation actually is (verified by direct page render) |
|---|---|
| Eqn 3.17 | `C_n = N/q̄Sb` — the YAWING MOMENT COEFFICIENT definition (Ch. 3, p.70, "Planform Span b" subsection). Not a lift-curve-slope formula. |
| Eqn 3.19 | `Cm_α = CL_α(X_Ref − X_ac)/c̄` — pitching-moment-slope AT AN ARBITRARY REFERENCE POINT (Ch. 3, §3.4.2.1 "Aerodynamic Center," p.76). Structurally *related* to the stability problem, but not "aHS" (a lift-curve slope). |
| Eqn 3.24 | `Cm_ac` — the WING pitching-moment coefficient about its own aerodynamic center, a span-integral formula (Ch. 3, §3.4.4, p.84). Not "CLa (aircraft)." |
| Eqn 3.38 | Does not exist as an equation at all at this location — page 101 has **Figure 3.38** ("Section Lift Characteristics of the NACA 64A010 Airfoil," an elevator-deflection chart, §3.5 "Angle of Attack and Lift Effectiveness of Control Surfaces"), not a numbered equation, and not neutral-point content. |

**Also found, for context:** Chapter 3 here ("Basic Aerodynamic Concepts") only covers airfoil/planform
lift-curve-slope, aerodynamic-center, downwash, fuselage-AC-contribution, and control-surface
lift-effectiveness topics (§3.1–3.7, equations run 3.1 through roughly 3.40) — it never reaches an
aircraft-level `CLa` or a neutral-point formula at all. The actual neutral-point/static-longitudinal-
stability material in THIS book lives in **Chapter 5, §5.1.2.2 "Static Longitudinal Stability"** (p.255,
criterion `C_mα + C_mTα < 0`, Eqs. 5.18–5.21) — topically the right place, but under Chapter 5's own
independent numbering, not Chapter 3's.

**Conclusion: this is genuinely the right book (confirmed physically present, correct title, correct
general subject matter for every one of Brandt's four citations), but the SPECIFIC equation numbers in
THIS copy (1979 first printing) do not match what Brandt's `S&C (2)` sheet cites.** The most likely
explanation is an edition/printing mismatch — Roskam revised and re-typeset this text multiple times over
several decades, and equation numbering is known to shift between printings; Brandt's sheet may have been
built against a later printing with different pagination/numbering than this 1979 first printing. This is
**not resolved here** — a later printing of the same title, if one becomes available, would be the next
thing to check; this entry documents that a direct, honest attempt was made against the copy at hand and
did not confirm a numbering match. **No implementation changes result from this entry** — the S&C
discipline's already-implemented citations remain Raymer 6th ed. Ch. 16 (primary-source-confirmed,
2026-08-04 entry above), independent of this Roskam cross-check.

---

## 2026-08-04 — Closing x_p/i_w/i_h (Casey's request): T.O. 1F-16A-1 gives i_w for real; i_h reframed; x_p/z_t/F_p resolved; Cm_acw discovered as a new, narrower blocker

**Context:** Casey asked to close the three remaining S&C citation gaps (`x_p`, `i_w`, `i_h`) flagged
during the implementation pass earlier the same day. Found `Documents/References/DIMENSIONS F-16A_B
Fighting Falcon Flight Manual pp6.pdf` — a 6-page excerpt of the actual **T.O. 1F-16A-1** USAF flight
manual, General Data section — already present in Casey's project tree (not something added for this
search), with a text layer (unlike the scanned Roskam PDF), read directly via PyMuPDF text extraction.

**`i_w` — CLOSED for real.** The manual's "WINGS" data block states directly: *"Incidence ... 0°"* — a
genuine, aircraft-specific, primary-source value. The legacy `temp_Casey` code never had this either
(`temp_Casey/examples/F-16A B Block 10 and 15/F16A_Level3_Sizing_ClassBased_Example.m:818`: `i_w = 0;` with
zero citation, and `SandCLevel3.m` line 142 has a commented-out `% i_w = 0; % Assume 0 for now`) — this is
the first time this repo has a REAL source for this number, not just a repeated convenient assumption.
Wired into `F16SandCL3.i_w_deg` (new constructor input, `f16a_L3.json .stability_control.i_w_deg`); `CL_w`
no longer errors.

**`i_h` — CLOSED, but by reframing, not by finding a spec value.** The F-16 tail is an all-moving
stabilator (`F16GeomL3.c_elev_frac=0`, Raymer Table 6.5) — there is no fixed "installation incidence" for
it the way there is for the wing; `i_h` IS the pilot/trim control input. `F16SandCL3.CL_h` now takes
`i_h_deg` as a required caller-supplied argument (same standing as `alpha_deg`), not a spec lookup.
`alpha_0Lh` (needed by the same equation) is closed too: the manual's "HORIZONTAL TAILS" data block gives
the airfoil as "6% Biconvex" (root) / "3.5% Biconvex" (tip) — a symmetric (uncambered) section, whose
zero-lift angle of attack is 0° by definition, not an assumption.

**`x_p`/`z_t`/`F_p` — CLOSED.** Re-reading Raymer 6th ed. p.604 (already read once, 2026-08-04 earlier
entry, but not connected to this specific gap until now) shows Eqs. 16.26–16.28 define `F_p` as
*specifically* the inlet-front-face normal force — meaning `F16GeomL3.x_inlet` (15.0 ft) genuinely IS "the
thrust application point" this term needs, closing the earlier objection ("no source in this repo labels
it that"). Separately, Raymer's own text sanctions two further simplifications explicitly: p.604 ("if the
thrust axis passes through or near the c.g., this term can be ignored" → `z_t=0`) and p.609 ("it is common
in early conceptual design to calculate the trim condition without including the thrust effects unless the
thrust axis is well above or below the c.g." → `F_p=0`). Both apply to the F-16 (engine on the fuselage
centerline, near the CG).

**New gap discovered while assembling the full trim equation: `Cm_acw`.** Closing `x_p`/`z_t`/`F_p` was
not, on its own, enough to fully compute `Cm_cg_trim` (Raymer Eq. 16.5/16.7) — that equation also needs
`Cm_acw`, the wing's own zero-lift pitching-moment coefficient about its aerodynamic center. Grepped
`F16AeroL3.m` and every `src/disciplines/aerodynamics/*.m` file directly for any `Cm`/`Cm0`/`Cm_ac`/
`pitching_moment` property: **none exists anywhere in this repo's Aerodynamics discipline, at any fidelity
level.** This is a genuinely new finding, not something previously flagged in the original design plan's
GAP list — logged here rather than invented. `F16SandCL3.Cm_cg_trim` still errors, but now with a much
narrower, more specific reason (`F16SandCL3:wingZeroLiftMomentNotAvailable`, was
`F16SandCL3:thrustLocationNotAvailable`). Two candidate future paths, neither pursued yet: (a) Roskam's
own Eqn 3.24 (a span-integral `Cm_ac` formula, found during the same-day Roskam-book cross-check above) —
would need NACA 64A204 section `cm_ac` data plus the wing's twist distribution, which the same T.O.
1F-16A-1 excerpt happens to give directly ("Twist: At BL 54.0 ... 0°, At BL 180.0 ... 3°"); (b) a simpler
table/chart lookup for a comparable airfoil, if one turns up. **Not resolved here.**

**Not changed by this entry:** every other already-implemented S&C quantity (`x_cg`, `x_acw`, `x_ach`,
`Cm_alpha_fus`, `x_np`, `SM`, `Cm_alpha`, `Delta_alpha_L0`) — unaffected by this closure pass.

---

## 2026-08-04 — Closing Cm_acw (Casey's request): Raymer Eq. 16.19 found, closes the equation; the
## airfoil-table value itself becomes a documented USER/STUDENT-SUPPLIED input → RESOLVED

**Context:** immediately after the `x_p`/`i_w`/`i_h` closure entry above, Casey asked directly:
"Where did the `Cm_acw` term come from?" then, once shown it is Raymer Eq. 16.5/16.7's `Cm_w` term
(the wing's own zero-lift pitching moment about its AC, with no citable value anywhere in this
repo's Aerodynamics discipline), instructed: "Search Raymer's text for an equation for it. If you
cannot find it, then the users/students must be able to supply their own value."

**Search performed:** full-text keyword search of the Raymer 6th ed. PDF
(`Documents/Readings/AircraftDesignAConceptualApproach_Raymer_6ed.pdf`) for `Cm_ac`/`zero-lift
pitching moment`/`moment about the aerodynamic center`/`airfoil...moment` (PyMuPDF, all 1097
pages). Found a direct hit at PDF page index 629 (printed p.598), Sec. "Wing Pitching Moment":

> The wing pitching moment about the aerodynamic center is largely determined by the airfoil
> pitching moment. Equation (16.19) provides an adjustment for wing aspect ratio and sweep for a
> straight wing or an untwisted swept wing at low subsonic speeds.
>
> `Cm_w = Cm_0,airfoil · (A·cos²Λ)/(A + 2·cosΛ)`                                        (16.19)
>
> The wing twist adds an increment of approximately (−0.01) times the twist (in degrees) for a
> typical swept wing... Transonic effects increase the magnitude of the wing pitching moment by
> about 30% at Mach 0.8.

**Outcome:** a real, citable Raymer equation DOES exist for `Cm_acw` (Eq. 16.19, p.598) — implemented
as `SandCL3.Cm_acw_wing(Cm0_airfoil, AR, sweep_deg)`. It genuinely closes the *architecture* gap: the
equation from AR/sweep to the 3D wing value is real and complete. But it bottoms out at
`Cm_0,airfoil` — the wing section's OWN 2D zero-lift pitching-moment coefficient about its
aerodynamic center — which is airfoil-table data (NACA report / Abbott & von Doenhoff), not
something Ch. 16 derives, and no citable NACA 64A204 number was found anywhere in this repo or
across this entire session's reading. Per Casey's own instruction, this is exactly the case where
"the users/students must be able to supply their own value": `F16SandCL3.Cm0_airfoil_wing` is now a
plain mutable input property, defaulting to `NaN` (`f16a_L3.json
.stability_control.Cm0_airfoil_wing = null`). `F16SandCL3.Cm_acw`/`Cm_cg_trim` compute and return
`NaN` gracefully — not an error — until a value is filled in; `Cm_cg_trim`'s signature also gained a
required `i_h_deg` argument (same reframing as `CL_h`, needed to assemble the tail-lift term the
full trim buildup requires). Wing-twist and transonic increments the same Eq. 16.19 page documents
are deliberately NOT implemented this pass (flagged, not silently dropped) — T.O. 1F-16A-1 does give
real twist data (BL 54.0=0°, BL 180.0=3°) for a future pass that wants that refinement.

`run_all_tests` after this change: exactly the pre-existing 12-failure baseline, zero S&C failures —
new real tests added for `SandCL3.Cm_acw_wing` (hand-computed) and for the NaN-until-supplied /
finite-once-supplied `F16SandCL3.Cm_acw`/`Cm_cg_trim` contract (`tests/disciplines/TestSandCL3.m`).

**Not changed by this entry:** `x_p`/`z_t`/`F_p`/`i_w` (resolved in the prior entry) and every other
already-implemented S&C quantity are unaffected.

---

## 2026-08-10 — Control-surface sizing in SizingLoopL2 (flaperon / LE flap / stabilator / rudder)

**Context:** the L2/L3 sizing loop already re-sized the tail and the control surfaces every
iteration, but it sized an *aileron* and an *elevator* — the two surfaces the F-16 does not have —
while neither of its real wing surfaces was sized at all, and its all-moving tail's control area was
carried nowhere. Widened to six surfaces (`S_ail`/`S_elev`/`S_rud`/`S_flaperon`/`S_lef`/`S_stab`), and
the three weights-facing areas on `F16GeomL3` (`S_csw`/`S_r`/`S_cs`) were converted from frozen inputs
into Dependent buildups on them. Per the standing scribe rule, the findings below are **flagged, not
resolved**: every computed value stays a cited Raymer/Roskam estimate and none was fitted backwards to
close a gap against the measured areas.

**Standing rule recorded for this and future work (user, 2026-08-10):** the USAF / T.O. 1F-16A-1
values are the aircraft's *actual* geometry and serve as **ground truth to measure the equations
against**; Raymer/Roskam fractions are **estimates the code computes with**. The two directions must
not be mixed. Generating the F-16's geometry from scratch with the code is explicitly out of scope for
this session, so L3 keeps the measured areas as its *seeded* inputs (it is the physical/T.O. tier) and
the loop's computed estimates are reported beside them.

### Finding 1 — rudder area: Raymer estimate is +39.1 % above the measured value, and it now has weight consequences

`f16a_control_surfaces()` uses Raymer 6th ed. Table 6.5's Fighter/attack `Cr/C = 0.30` and p.161's
"about 90 % of the tail span". At the JSON baseline (`S_vt` = 60 ft²) that gives
`0.30 × 0.90 × 60 = 16.20 ft²` against T.O. 1F-16A-1 Fig. 1-2's measured **11.65 ft²**: **+39.06 %**,
the framework's largest control-surface error.

This mattered less before 2026-08-10 because the loop's rudder area fed nothing. It matters now:
`F16GeomL3.S_r` aliases it into Raymer Eq. 15.3's `(1 + S_r/S_vt)^0.348` vertical-tail weight term.
**Not calibrated to 11.65** — back-solving the fractions from a measured area is the
back-calculated-value-as-input pattern `docs/PLAN.md` forbids, and it would turn
`tail_sizing_brandt_comparison.m`'s accuracy row into a tautology. **For Casey's sign-off:** is
Raymer's printed fraction the right thing for a conceptual-design tool to carry here, or should the
T.O. drawing's *fractions* (not its area) be read off and wired in as genuine F-16 spec data?

### Finding 2 — two editions of Raymer Table 6.5 give different rudder chord fractions

`GeomL1.lookup_control_surface_fraction('jet_fighter', 'rudder')` returns **0.33**, cited to Raymer
**7th** ed. Table 6.5. `f16a_control_surfaces()` uses **0.30**, cited to Raymer **6th** ed. Table 6.5.
Both citations appear correct for their own edition; nothing keeps them in sync, and the two values
are used by different parts of the framework. Note the 6th-ed. extract
(`docs/reference_extracts/Raymer_Aircraft_Design_6ed/06_initial_sizing.md`) also carries an explicit
"column headers scrambled by OCR, `[verify p. 162]`" caveat on that table. **For Casey:** which edition
is canonical for this framework?

### Finding 3 — the aero classes' flaperon span band was far too generous, and correcting it moved the design point

`F16AeroL2`/`F16AeroL3` carried `eta_flap_in/out = 0.10/0.90` with `c_flap_over_c = 0.25` as
hardcoded, in-code-flagged-as-unverified estimates. Those imply a flaperon of
`0.25 × ratio(0.90, 0.10, 0.2275) × 300 = 60 ft²` — **nearly double** the measured 31.32 ft². Making
`ControlSurfaceSizer` the single source of truth replaced them with `0.35/0.75` (0.40 extent from
Raymer Fig. 6.3's band, placed outboard of the strake), giving 28.11 ft², **−10.24 %**.

**This changed the converged design point at both levels**, and the chain is worth recording because
it is not obvious that sizing a control surface should move the wing: a narrower flap band lowers
Roskam Eq. 7.10's flapped-area ratio → lowers `Delta_CLmax_flap` and `Delta_CD0_flap` → tightens the
takeoff and landing constraints → moves `WS_opt` → moves `S_ref = W_TO/WS_opt`.

| | before 2026-08-10 | after |
|---|---|---|
| L2 | `W_TO` 23,075.65 lbf, `S_ref` 174.82 ft², `T_SL` 20,086.32 lbf, 19 iter, `WS_opt` 132 psf | `W_TO` 23,120.65, `S_ref` 222.31, `T_SL` 20,253.01, 17 iter, `WS_opt` 104 psf |
| L3 | `W_TO` 23,972.46 lbf, `S_ref` 181.61 ft², `T_SL` 17,220.66 lbf, 12 iter, `WS_opt` 132 psf | `W_TO` 23,338.62, `S_ref` 210.26, `T_SL` 17,245.01, 12 iter, `WS_opt` 111 psf |

Both new `WS_opt` values remain interior points — and exact grid points (20+7k) — of
`PointPerformanceBase.WS_RANGE_BRANDT`, so neither is a sweep-limit artifact. **For Casey:** the
0.35/0.75 stations are a judgement call within Fig. 6.3's band (the figure fixes only the *extent*);
confirm that band placement, or supply T.O. stations.

### Finding 4 — the leading-edge flap reads +21.6 % high, driven by `eta_lef_in = 0`

`c_lef_frac = 0.15`, `eta = 0.00–0.98`, carried over unchanged from `F16AeroL3`'s existing
`c_slat_over_c`/`eta_slat_*` estimates, give 44.66 ft² against the measured **36.71 ft²** (**+21.64 %**).
`eta_lef_in = 0` is the main cause and is known to be physically wrong — the real LEF begins *outboard*
of the strake, not at the centreline. Deliberately left alone rather than adjusted to close the gap
(same reasoning as Finding 1). Note also that the aero classes call this device a "slat" while the
F-16 has leading-edge **flaps**; `hld_LE = "slat"` is retained only because that is the literal Raymer
Table 12.2 row name the lookup uses.

**Partly-cancelling errors, worth knowing:** the flaperon reads 10 % low and the LEF 22 % high, so
their sum `S_csw` = 72.77 vs 68.03 is only **+6.96 %**. `S_csw` is what Raymer Eq. 15.1 consumes, so
the wing-weight term looks better than either component justifies. Do not read the sum's agreement as
evidence that both parts are right.

### Finding 5 — `S_cs` = 190 ft² retired in favour of a 187.68 ft² buildup

`f16a_L3.json`'s `total_control_surface_area_ft2 = 190` was self-described as an "estimate, unpinned"
annotated *"flaperon + HT + rudder + LEF"*. Those four terms now exist as real properties, so
`F16GeomL3.S_cs` is the Dependent buildup `S_csw + S_stab + S_rud`, which at the JSON baseline is
`68.03 + 108 + 11.65 = ` **187.68 ft²** — 1.22 % below the retired estimate. The JSON key is removed
(replaced by a `_REMOVED_…` provenance note). Consequence, via Raymer Eq. 15.17
(`S_cs^0.489`): flight-controls weight 925.283 → **919.748 lbf** (−0.60 %), systems group
4578.039 → **4572.504**, `OEW(31,377)` 15,795.156 → **15,789.621 lbf** (−0.035 %).

Note the buildup only reconciles with the retired 190 if the all-moving stabilator contributes its
**full** `S_ht`, which is an independent check on `S_stab = S_ht` [Raymer 6th ed. Table 6.5 footnote,
"Supersonic usually all-moving tail without separate elevator"]. `S_csw` (68.03) and `S_r` (11.65) both
still reproduce their former frozen values *exactly*, because the constructor seeds their components
from the same T.O. figures — so Eqs. 15.1 and 15.3 are unchanged at the baseline. This closes the
`S_cs` half of todo 2026-07-24 GeomL3 §6 / 2026-07-25 §12; the `L_t` half stays open (see Finding 7).

### Finding 5b — the leading-edge flap is NOT a control effector

**Clarification from the user, 2026-08-10.** The F-16's LEF is functionally a **slat**: a
flight-control-system-scheduled, automatic stall-prevention / manoeuvre device that keeps the flow over
the wing attached. It **does not respond to pitch, roll or yaw commands**. The airframe's three actual
effectors are the all-moving stabilator, the flaperons and the rudder.

This is worth recording because the framework's own structure invites the wrong reading: the LEF comes
out of `ControlSurfaceSizer.size()` next to the real effectors, and `geom.S_csw`/`S_cs` include it. That
is **correct for weight and area purposes** — it is an actuated surface with real planform area that
Raymer Eqs. 15.1 and 15.17 must see, and the retired `S_cs` = 190 annotation counted it too — but it is
not a control effector. Guarded now by `TestAeroL3.testLEFIsNotAControlEffector`. It also vindicates
`hld_LE = "slat"`: Raymer Table 12.2's "slat" row is the right aerodynamic analogue, not a leftover.

**Its dynamic AoA/Mach schedule is explicitly out of scope for this session** (user decision,
2026-08-10): the real device follows a continuous flight-control law, but this framework has no time
domain, and the mission segments already use fixed per-segment slat deflections
(`delta_slat_TO/L_deg`). A NASA-sourced schedule and a corresponding `AeroL3` static were drafted and
then explicitly withdrawn by the user ("We're not doing the schedule reporting. Get that out of here.")
— nothing in the repo references either any more. `TestAeroL3.testTODO_LEFScheduleNotPinned` is
unchanged and stays red for the original reason: `delta_slat_TO/L_deg = 17` remains an unpinned
stand-in against a primary source.

### Finding 6 — `F16AeroL2.delta_flap_TO_deg = 15` is uncited and disagrees with L3's 20 for the same aircraft

`F16AeroL3` records web-sourced evidence (2026-07-30) that the F-16 uses the **same** 20° trailing-edge
flap setting for takeoff and landing, and sets both to 20. `F16AeroL2` still carries an uncited 15° for
takeoff. A configuration summary the user supplied 2026-08-10 (F-16.net / StackExchange /
ryanporto.com — secondary web sources) **corroborates the 20° down** figure and adds **23° up**, which
has no consumer in the high-lift path. Left at 15 rather than silently changed: it moves L2 takeoff
`CLmax` and belongs in a deliberate aero decision, not a control-surface change. **For Casey:** should
L2 adopt 20° to match L3 and the sources?

The same secondary reference gives a **20° maximum LEF deflection**, an upper bound consistent with — but
not pinning — `delta_slat_TO/L_deg = 17`, which stands for the LEF position near the high-AoA
rotation/touchdown condition. `TestAeroL3.testTODO_LEFScheduleNotPinned` therefore stays RED: the real
device is scheduled on AoA and Mach, and a single maximum is not a schedule (see Finding 5b — that
schedule is explicitly out of scope for this session, not merely unpinned).

### Finding 7 — two independent definitions of the tail arm, only one of which tracks the loop

Adjacent to this work and **not** addressed by it. `F16GeomL3.L_t = 22.0 ft` is a frozen
"estimate, unpinned" input read *only* by `F16WeightsL3` (Raymer Eq. 15.3), while the tail sizer
independently uses `TailL1.compute_tail_arm(L_fus) = 0.475 × L_fus ≈ 22.56 ft` at the L3 fuselage
length. One physical quantity, two values, and only the sizer's follows the sizing loop. Recorded here
so it is not rediscovered later.

---

## 2026-08-10 (later) — CLOSED: F16AeroL2 had no leading-edge-device model at all

**Closes the divergence this file's own history traces above.** Running both sizing studies at the
commit just before this entry's parent (`a429076`) gives `W/S` optima of L1=111, L2=132, L3=132 psf —
L2 and L3 agreeing. After the flaperon-band correction earlier in this file's 2026-08-10 section, they
diverged to L2=104, L3=111. Tracing why (see this file's Finding-adjacent investigation, same day)
found the real cause: **`F16AeroL2` modeled only the trailing-edge flaperon's contribution to
`CLmax_TO`/`CLmax_L` — it had no leading-edge-flap (LEF) term at all** — while `F16AeroL3` modeled
both. `LandingConstraint.WS_max()` reads `CLmax_L` straight from the injected aero object, so L2's
landing wall was permanently ~5.3 psf tighter than L3's for a reason having nothing to do with either
fidelity level's *intended* differences — a modeling omission, not a deliberate simplification. The
apparent L2/L3 agreement pre-flaperon-fix was coincidental grid quantization (both walls, 133.02 and
138.57 psf, happened to floor to the same 7-psf grid point); the coincidence broke once the whole
baseline shifted down ~24 psf and the ~5.3 psf gap between them crossed a grid line.

**Fix:** ported `F16AeroL3`'s `Delta_CD0_slat`/`Delta_CDi_slat`/`Delta_CLmax_slat` methods and
`hld_LE`/`F_slat`/`k_slat`/`delta_slat_TO_deg`/`delta_slat_L_deg` properties into `F16AeroL2`
verbatim — same equations, same citations, same values, no L2-specific evidence exists for a
different number. `c_slat_over_c`/`eta_slat_in`/`eta_slat_out` are Dependent getters onto the SAME
injected `ControlSurfaceSizer` (`f16a_control_surfaces()`) `F16AeroL3` already reads, so L2 and L3
now share one description of the LEF instead of L2 omitting it. `get_Delta_CLmax_{TO,L}`,
`get_Delta_CD0_{TO,L}`, and `get_Delta_CDi_{TO,L}` now sum the flaperon and LEF contributions
independently (never combining one device's `ΔCLmax` into the other's induced-drag coefficient,
since `k_f_flap` ≠ `k_slat`) -- exactly mirroring `F16AeroL3`'s existing assembly.

**Result, confirmed by re-running both studies:** `L2.CLmax_L` now equals `L3.CLmax_L` exactly
(1.1525 = 0.9163 clean + 0.2056 flap + 0.0328 slat, identical decomposition at both levels), L2's
landing wall moves from 109.13 to 114.48 psf (matching L3's 114.40 to within 0.08 psf, the small
remainder from other genuine L2-vs-L3 CD0/weight fidelity differences), and **`W/S` optimum moves
from 104 back to 111 psf — now agreeing with both L3 and L1.** `S_ref` 222.31 → 207.55 ft²; `W_TO`
23,120.65 → 23,037.50 lbf; `T_SL` 20,253.01 → 20,174.15 lbf; 17 iterations, converged.

**Ported, not re-litigated:** `delta_slat_TO/L_deg = 17` carries the SAME "unpinned against a primary
schedule" citation gap `F16AeroL3` already had (`TestAeroL3.testTODO_LEFScheduleNotPinned`) — a
mirrored guard, `TestAeroL2.testTODO_LEFScheduleNotPinned`, keeps L2's copy red until that closes,
which it must do for BOTH classes together since they now cite the same open item. Total red-test
count: 12 → 13.

---

*No entries resolved. Add new dated sections above this line for future discrepancies; do not
edit or remove prior entries.*
