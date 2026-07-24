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

## 2026-07-24 — BrandtMission cross-check (Mission Analysis deep-dive, scribe pass)

**Context:** tasked with cross-checking `VnV/BrandtF16A/BrandtMission.m` and `readme_mission.md`
against each other and against the live `Brandt-F16-A.xls` Miss tab, the same way the 2026-07-21
Geometry-deep-dive entries above did (via MATLAB COM/`actxserver` automation, per
`baseline/extract_brandt.m`'s approach).

**Tooling limitation — could not complete the live-Excel half of this check.** This scribe session's
available tools were `Read`/`Grep`/`Glob`/`Write`/`Edit`/`WebFetch` only — no `Bash` and no MATLAB
execution/MCP tool. `Read` errors on binary `.xls`/`.xlsx` files ("This tool cannot read binary
files"), and there is no way to run `actxserver`/`readcell` against `GroundTruth/Brandt-F16-A.xls`
or `temp_Casey/inputs/Mission_Profile.xlsx` from this session. **The live-workbook cross-check this
entry's task briefing called for was not performed** — flagging this plainly rather than silently
skipping it or asserting a check that didn't happen. A follow-up pass with actual MATLAB/Bash
execution access should open `Brandt-F16-A.xls`'s `Miss` tab directly and re-run the comparison
this entry's task description asked for.

**What WAS checked (code-vs-docs self-consistency, no Excel access needed):** read
`BrandtMission.m` in full (all public/private methods) against `readme_mission.md` in full,
line-by-line, looking for the kind of doc-vs-doc or doc-vs-code mismatch the 2026-07-21 entries
above found. Specific things checked and found **consistent** (not new discrepancies):
- The "Old" TSFC model formula and its `install=1.08`/`θ=T_ISA(h)/518.69` (readme) vs.
  `θ=T_ISA(h)/288.15` (code header comment) description — these are the same dimensionless ratio
  described in Rankine vs. Kelvin, not a numeric conflict (288.15 K × 1.8 ≈ 518.67 R ≈ Roskam/
  Mattingly's standard 518.69 R, rounding only).
- The Ps/time-from-Ps formulas, the `is_ps_climb` TSFC-averaging detection rule, and the Combat/
  Landing formulas all match between the class header docstring, the `readme_mission.md` prose,
  and the actual private-method code.
- The Landing-distance docstring gives two forms of the same formula (a compact `V_stall_land`-based
  form and the expanded `W_ref`-based form actually coded) that look structurally different at a
  glance; algebraic substitution of `V_stall_land² = 2·W_ref/(ρ_SL·S·CLmax_land)` into the compact
  form reduces exactly to the expanded/coded form — confirmed equivalent, not a discrepancy.
- The already-existing "Known Discrepancies from Excel Ground Truth" section in
  `readme_mission.md` (S_wet/CDmin ~2.8% low, traced to the already-logged `Geom!B19` double-count
  finding from 2026-07-21 above) is self-consistent and is a downstream consequence of an
  already-logged, already-user-resolved item — not re-logging it as new.

**Net result: no new `VnV/BrandtF16A`-internal discrepancy found in this pass**, but this is a
weaker result than the 2026-07-21 entries above because the live-workbook half of the check could
not be run. Do not treat this entry as confirmation that `BrandtMission.m` matches the live `Miss`
tab beyond what `readme_mission.md`'s own already-documented 43-test/1%-tolerance validation
claims — that claim was not independently re-verified here.

Separately (not a `VnV/BrandtF16A`-internal issue, but the same "couldn't access the live workbook"
limitation applies): `temp_Casey/inputs/Mission_Profile.xlsx`'s CAP sheet — the actual F-16 CAP
mission profile table in the rewritten `docs/subplans/07_mission_analysis.md` — was likewise **not**
independently re-verified against the live file for the same tooling reason; the subplan's CAP
table is carried forward from the prior draft with an explicit caveat, not re-confirmed. See that
document's "F-16 CAP Mission Profile" section header.

---

## 2026-07-24 — io pass: Mission JSON authoring (tooling gap persists; two new findings)

**Context:** tasked with authoring `examples/F16A/mission_profile.json` and
`examples/F16A/mission_brandt_comparison.json` for the Mission Analysis deep-dive (subplan 07), and
explicitly asked to (1) open `temp_Casey/inputs/Mission_Profile.xlsx`'s `CAP` sheet live via MATLAB
to verify the subplan's carried-forward CAP table before encoding it, and (2) reconcile
`GroundTruth/f16a_geometry.json`'s `mission` section against the live `Brandt-F16-A.xls` Miss tab,
closing the loop the entry above left open.

**Tooling limitation — the gap is NOT closed, contrary to what this task hoped.** This io session's
actual available tools were `Read`/`Grep`/`Glob`/`Write`/`Edit` only — no `Bash`, no MATLAB/MCP
execution tool, despite the task briefing assuming that access. `Read` errors identically to the
prior entry ("This tool cannot read binary files") on both `Mission_Profile.xlsx` and
`Brandt-F16-A.xls`; `Grep` against the raw `.xlsx` bytes finds no matches (compressed zip container,
no recoverable plaintext). **Neither live workbook was opened by this pass either.** Concretely,
this means:
- `examples/F16A/Mission_Profile.xlsx` was **NOT created** — this pass cannot read the source
  `.xlsx`'s raw bytes, so it cannot produce a faithful binary copy via a text-only `Write` tool
  (writing a fabricated placeholder would be worse than not copying it at all). Still needs doing
  by a pass with real file-copy/Bash access, same as `Constraints.xlsx` was copied for Step 6.
- `examples/F16A/mission_profile.json`'s CAP segment table was written **as carried forward from
  `docs/subplans/07_mission_analysis.md`'s table, unverified against the live sheet** — the same
  caveat the subplan itself already carries, not resolved by this pass. See that JSON's own
  `_verification_status` field for the full account.
- The `f16a_geometry.json:mission` (Brandt Miss-tab, 14-segment) section was **not independently
  read from the live workbook** either. What this pass COULD do: (a) re-confirm the same
  code-vs-docs self-consistency check the prior entry already performed (no new mismatch found
  between `f16a_geometry.json:mission`'s arrays, `BrandtMission.m`'s header-comment segment table,
  and `readme_mission.md`'s "Mission Segment Sequence" table — all three agree element-for-element,
  segment by segment); (b) additionally lean on `tests/test_BrandtMission.m`'s 43 already-passing
  checks (1%/2% `RelTol` against literal `Miss!B8:N8`/`B9:N9`/`B12:N12`/`O6`/`O8`/`O9`/`O12` cell
  values) as strong *indirect* evidence that `f16a_geometry.json:mission`'s segment inputs are a
  faithful transcription of the live Miss tab — if the altitude/Mach/pct_AB/CDx inputs were wrong,
  the resulting 14-segment fuel/time/weight-fraction totals would be very unlikely to land within
  1-2% of Excel's own summary cells purely by chance. This is real supporting evidence, but it is
  **not** the literal direct live-Excel cell read this entry's task (and the one above) called for
  — do not treat this as "closing the loop"; the direct-read gap remains genuinely open. A future
  pass with actual MATLAB/Bash execution access should still perform the literal
  `readcell`/`actxserver` read against `Brandt-F16-A.xls`'s Miss tab and `Mission_Profile.xlsx`'s
  CAP sheet that both this entry and the one above were asked to do.

**Finding A — CLmax_TO/CLmax_land value mismatch between two independent extractions of the same
cells.** While sourcing `mission_profile.json`'s scalar spec constants, found that
`baseline/F16Baseline.m` (`b.brandt.CLmax_TO = 1.2785`, `b.brandt.CLmax_land = 1.4288`, populated by
`baseline/extract_brandt.m`'s `get("Main","L9")`/`get("Main","L10")`) disagrees slightly with
`GroundTruth/f16a_geometry.json`'s `mission.CLmax_TO = 1.2757` / `mission.CLmax_land = 1.4259` —
both sources cite the **same** cells (`Main!L9`/`Main!L10`) but give numbers that differ by
~0.2%. Neither this pass nor the source material available to it can determine which (if either)
is the live cell value — flagging for user review, not resolving. `mission_profile.json` uses the
`f16a_geometry.json` figures for internal consistency with the rest of that file's already-approved
`mission` block.

**Finding B — CAP profile's Takeoff `mach_end` = 0.87 looks suspicious, unconfirmed.** The
subplan-07 CAP table (carried forward unverified into `mission_profile.json`) lists Takeoff's Mach
as 0.87 — the same value as every subsequent cruise-altitude segment. Every other mission profile
documented in this repo (Brandt's Miss tab: Takeoff `mach_end = 0.282`, the liftoff Mach, both in
`f16a_geometry.json:mission.mach_end(1)` and `BrandtMission.m`'s header table) uses a low
liftoff-speed Mach for Takeoff's end condition instead. This may be a transcription artifact in the
CAP table (Takeoff's Mach cell possibly duplicated from the Climb/Cruise row next to it) rather than
a genuine CAP-profile value, but cannot be confirmed without a live read of `Mission_Profile.xlsx`.
Flagging, not correcting — see `mission_profile.json`'s `_note_mach_end` field.

---

## 2026-07-24 — Coordinator pass: closes the live-Excel gap left open by the two entries above

**Context:** both the 2026-07-24 scribe entry and the 2026-07-24 io entry above flagged the same
tooling gap — their sessions had no MATLAB/Bash execution access, so neither could open
`Mission_Profile.xlsx`'s CAP sheet or `Brandt-F16-A.xls`'s Miss tab live. This pass had Bash access
and used Python (`openpyxl` for the modern `.xlsx`, `xlrd==1.2.0` for the legacy binary `.xls` —
installed for this purpose) to perform the literal cell reads both prior entries called for.

**CAP sheet (`Mission_Profile.xlsx`, sheet `CAP`) — read directly, all rows confirmed.**
`segment_names`/`alt_ft`/`mach_end`/`dist_nm_given` (raw ft)/`time_min_given`/`drop_lb`/fixed-payload
values in `docs/subplans/07_mission_analysis.md` and `examples/F16A/mission_profile.json` all match
the live sheet exactly — no corrections needed. `examples/F16A/Mission_Profile.xlsx` has now been
created (binary copy). One field the live sheet carries that the JSON didn't yet — a `Dry or Wet`
row per segment (Dash and Combat are `Wet`/AB, all others `Dry`) — has been added to
`mission_profile.json` as `dry_or_wet` (needed by `F16MissionL2/L3` to pick `prop.get_TSFC` vs.
`prop.compute_TSFC_AB` per segment). A `Turns` row (Combat=2, blank elsewhere) also exists in the
live sheet but isn't needed by the currently-planned Roskam Eq. 2.12 Combat equation — noted in the
JSON as available-but-unused.

**Finding B — RESOLVED, not a transcription artifact.** Live read of the CAP sheet's `Mach number`
row confirms Takeoff's cell genuinely contains `0.87`, identical to the following segments. This is
real source data in Casey's own spreadsheet, not a bug introduced by any doc/JSON transcription. It
remains a physically odd input (every other profile in this repo uses a low liftoff Mach for
Takeoff's end condition) worth the user's awareness, but nothing in the framework's docs/JSON needs
correcting — the value is preserved as-is per the live sheet.

**Brandt Miss tab (`Brandt-F16-A.xls`, sheet `Miss`) — read directly, all values confirmed.** Read
`Miss!B3:O13` (altitude, end Mach, %AB, distance, time, fuel, drop payload, weight fraction rows) in
full. Every value in `examples/F16A/mission_brandt_comparison.json` (all 4 summary targets: total
fuel 6000.432 lb, total time 94.058 min, landing dist 2884.95 ft, final W/W_TO 0.66853; all 13
per-segment fuel/time/weight-fraction rows) matches the live cells to the precision shown. This
independently confirms `BrandtMission.m`/`test_BrandtMission.m`'s existing 43-check validation
against the actual live workbook, not just internal code-vs-docs self-consistency — the gap both
prior entries flagged as "real supporting evidence but not the literal read" is now closed with the
literal read, and it checks out.

**Finding A — RESOLVED.** Live read of `Main!L9` = 1.2756651310132752, `Main!L10` =
1.4259087778177055. This matches `GroundTruth/f16a_geometry.json`'s `mission.CLmax_TO = 1.2757` /
`mission.CLmax_land = 1.4259` exactly. `baseline/F16Baseline.m`'s `CLmax_TO = 1.2785` /
`CLmax_land = 1.4288` (via `baseline/extract_brandt.m`'s `get("Main","L9")`/`get("Main","L10")`) is
the stale/incorrect one — **`baseline/F16Baseline.m` needs correcting**, though that file is out of
scope for the Mission Analysis deep-dive and was not touched by this pass. Flagging for whoever next
touches `baseline/F16Baseline.m` or `baseline/extract_brandt.m`.

---

## 2026-07-24 — User correction to Mission_Profile.xlsx (Finding B superseded)

**Context:** the "Coordinator pass" entry above resolved Finding B as "genuine live-sheet data, not
a transcription artifact, preserved as-is." The user has since edited
`temp_Casey/inputs/Mission_Profile.xlsx`'s CAP sheet directly: Takeoff Mach 0.87→0.282 (now matches
Brandt's Miss-tab liftoff Mach), Loiter 0.30→0.31, Landing 0→0.3.

Re-verified against the live sheet after the edit (same `openpyxl` method as the entries above) —
all three new values confirmed present. `examples/F16A/Mission_Profile.xlsx` re-copied from the
updated source; `examples/F16A/mission_profile.json`'s `mach_end` array and
`docs/subplans/07_mission_analysis.md`'s CAP table both updated to
`[0, 0, 0.282, 0.87, 0.87, 1.60, 0.80, 0.87, 0.31, 0.3]`. This is a source-data correction, not a new
discrepancy — noted here per the log's own convention of not editing prior entries, so a future
reader sees Finding B's original text plus this follow-up rather than a silently rewritten history.

---

*No entries resolved except where explicitly marked RESOLVED with a user decision above. Add new
dated sections above this line for future discrepancies; do not edit or remove prior entries.*
