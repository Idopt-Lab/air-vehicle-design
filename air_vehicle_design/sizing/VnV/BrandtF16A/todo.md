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
the wrong breakdown was quoted (`WeightsL3.m`, `TestWeightsL3.m`, `docs/subplans/05_weights.md`,
`F16WeightsL3.md`). The full 62-row table itself is still not restored into this file.

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

## 2026-07-31 — Subsystems deep-dive, Phase A (documentation): `gear` block provenance and implied gear-load-split

**Context:** scribe documentation pass for the brand-new Subsystems discipline
(`docs/subplans/09_subsystems.md`), researching a citable source for the new `F16LandingGearL2`/`L3`
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
source already in this repo: `temp_AI/docs/disciplines/reference_extracts/08_fuselage_sizing.md` §8.1.7
(Nicolai & Carichner, p.202): *"Nose gear rule of thumb: 20% of TOGW on the nose wheel for good
steering."* It also contradicts Raymer's stated typical split (Ch. 11 p.344 prose, *"the main tires
carry about 90% of the total aircraft weight... Nose tires carry only about 10%"* — see
`docs/subplans/09_subsystems.md` Equations & Citations §8). A real F-16 nose gear carrying 73% of
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
takes as its argument. `docs/subplans/09_subsystems.md` recommends defaulting to Raymer's own stated
90%/10% (needs no geometry, matches the discipline's "statistical method" framing) and explicitly
**not** wiring in the Brandt-derived 26.7%/73.3% split until this is resolved. **Flagging for user
review — not resolved here**, per the standing scribe rule. Needs: (a) a live-`Brandt-F16-A.xls` COM
read of the actual "Gear" tab cells (correcting `baseline/extract_brandt.m`'s stale hardcoded path
first, per the standard todo.md convention used elsewhere in this file) to get real cell references for
`x_nose_ft`/`x_main_ft`/`d_nose_ft`/`d_main_ft`, and (b) a decision on whether `xcg_TO_ft` or the gear
station values are the more likely source of the discrepancy, or whether it is not a discrepancy at all
(e.g. a coordinate-convention misunderstanding on this reviewer's part).

---

*No entries resolved. Add new dated sections above this line for future discrepancies; do not
edit or remove prior entries.*
