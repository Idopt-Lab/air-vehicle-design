# F-16A RFLP example — open work

Working file, not teaching material. Every item below was verified against the repository on
2026-08-01. Items are grouped by *what kind of thing they are*, because the biggest problem with
the TODO markers currently in the code is that four different kinds are all spelled `TODO`.

- **A** — real defects, fix these
- **B** — real gaps that need *your* decision, not code
- **C** — deferred method work, already argued in the decision log
- **D** — markers that look like TODOs but are not; close them

---

## A · Real defects

### ~~A1 · Two dangling project entries point at files that no longer exist~~ — DONE

The project registered `generate_f16a_functional.m` and `F16AFunctionalArchitectureTest.m` at the
example **root**, where they lived until commit `ea1f14f` ("Reorg step 2") moved them into
`architecture/`. The entries dangled from then on, failing the check "All project files and
folders exist on the file system", and certain operations made MATLAB garbage-collect them —
rewriting `resources/project/` and producing a spurious git diff.

Both entries were dropped and re-added at their real paths. Git recorded them as **renames**, so
their classification labels survived (`test` on the test file, `design` on the generator).
Opening the project is now idempotent: open + `runChecks` leaves no unstaged change.

### ~~A1b · project membership~~ — DECIDED: register everything

Decision: register everything. Rationale — membership has no runtime, load or maintenance cost,
so a smaller set saves nothing, while a *partial* set leaves "All files under source control are
in the project" permanently red and turns the one health signal into noise.

Applied: **16 → 61** project files (45 new entries, including the 3 layer-folder entries MATLAB
adds automatically). `runChecks` is **12/12**.

For the record, since it was measured rather than assumed: **nothing functional depended on
this.** Generators, tests, all three System Composer models, the Requirements Editor and every
Implement link worked with 41 files unregistered, because they resolve off the project **path**
(all five layer folders were already on it). Membership buys the Project browser view, dependency
analysis, `runChecks` and packaging — not the ability to run anything.

Regression check after the change: 92/92 machinery tests pass (39 physical + 15 logical + 6
functional + 32 guards).

### ~~A2 · `docs/02_functions.md` claims a project-health result that is now false~~ — RESOLVED BY A1

Line 118: *"Project health is confirmed by `runChecks(currentProject)` (12/12 passing)."* The
shipped state measured **10/12**; after A1/A1b it is genuinely **12/12**, so the line is true
again. No edit needed — but re-verify if the project file set is ever trimmed.

### A2b · The "Verified by" links do not appear, and the project is not why

`F16AOpenForReview` loads the three models and four requirement sets, but never loads the two
`~m.slmx` link sets in `verification/`. So `REQ_F16A_022` and `REQ_F16A_P01` show **Implement
only** in the Requirements Editor — the manual Verify links the README tells you to make are
present and correct on disk, but invisible.

Tested cold (index deleted) with the verification files in the project and out of it: membership
makes **no** difference. The fix is two lines in `F16AOpenForReview.m`:

```matlab
slreq.load(fullfile(thisDir,"verification","F16AMaterialsVerificationTest~m.slmx"));
slreq.load(fullfile(thisDir,"verification","F16AFuelVerificationTest~m.slmx"));
```

Verified: with these, both requirements report `Implement, Verify`.

This also means `docs/README.md:210–216` is misleading where it attributes the working Verify
link to "the project's Digital Thread artifact tracking (a manual project setting)". Artifact
tracking is enabled in the project, and the links still do not load without the explicit
`slreq.load`.

### A3 · `docs/02_functions.md` still says the trade study lives at L

Lines 126–128, the "Next" section: *"three roles carry competing **options** … and a **trade
study** selects among them"*, describing the Logical layer. D-001 moved the trade to P and
`logical/F16ALogicalTradeStudy.m` was deleted in Stage 1. This is the last surviving sentence of
the pre-D-001 design in the docs. Reword to "…and the Physical layer decides between them".

### A4 · Ground truth is transcribed, not referenced

`physical/generate_f16a_physical.m` (lines ~507–522) and
`physical/F16APhysicalArchitectureTest.m` (`MassRows`, lines ~219–235) each contain their own
hand-typed copy of the same 16 Brandt masses. The test therefore verifies *"the generator wrote
what the test author also typed"*, not *"the model agrees with the Brandt sizing model"*. A
transcription error in both places is invisible; a change in `/sizing/` is invisible.

Two symptoms already visible:

| Quantity | MBSE model | `/sizing/` ground truth | Source |
|---|---|---|---|
| OEW | 19980.73 | **19980.70** | `Wt!B12`, `BrandtWeight.m:64` |
| Airframe structural subtotal | 6722.88 | **6722.87** | `Wt!B9`, `cell-map.md:121` |

Both are sum-of-rounded-parts vs. the spreadsheet's own subtotal cell. Harmless numerically,
but they are the exact drift a real reference would have caught, and the test comments call
these figures "the Brandt ground truth" while asserting the transcription.

Fix (either is defensible, pick one):
- **Cheap** — keep the literals, but cite the cell for each (`Wt!C9`, `Wt!D9`, …) as
  `sizing/VnV/BrandtF16A/GroundTruth/cell-map.md` already does, and reconcile the two figures above.
- **Right** — have the test read the masses from `sizing/VnV/BrandtF16A/` (read-only) so the
  comparison is against the source, and the generator stays the only place they are typed.

### A5 · `derived/artifacts.dmr` is untracked and unignored

The Digital Thread artifact cache sits in `derived/`, which is in neither `.gitignore` nor the
repo. It shows as an untracked file forever. Add `derived/` to `.gitignore` (`work/` is already
there).

---

## B · Real gaps that need a decision from you

### B1 · Wire `F16APhysicalMissionFuel` to `/sizing/` — this one is *ready*

`physical/F16APhysicalMissionFuel.m:17` returns `NaN`, so `F16AFuelVerificationTest` fails on
purpose and `REQ_F16A_P01` reads "verification pending".

The analysis it needs already exists: `sizing/VnV/BrandtF16A/BrandtMission.m`, whose validation
target is **Miss!O9 = 6000.43 lb** total mission fuel. Against the model's 6300 lb available, the
requirement would be **met**, and the test would go green.

Decide first: is a green fuel verification better teaching than a red one? The current red test is
a genuinely good demonstration of "verification set up but not satisfied". Turning it green
demonstrates the opposite — a closed loop from sizing analysis into requirement verification.
Both are worth teaching; you cannot have both from this one requirement.

Note the two fuel figures in `/sizing/` are **not** the same number and mean different things:
`BrandtMission` Miss!O9 = 6000.43 lb (fuel actually burned by the 14-segment mission) vs.
`BrandtWeight` Wt!B6 = 6296.30 lb (fuel *capacity* implied by W_TO − payload − OEW). The
requirement says "available ≥ required", so Miss!O9 is the correct one. Getting this wrong would
compare capacity against capacity and prove nothing.

### B2 · Implement `F16APhysicalCostModel` — also ready

`physical/F16APhysicalCostModel.m:25` (`TODO: implement a DAPCA-IV-style unit flyaway cost
model`) returns `NaN`. `sizing/VnV/BrandtF16A/BrandtCost.m` is already a full DAPCA IV
implementation.

This is the more interesting of the two hooks: by **D-026** the trade study drops any criterion
no candidate carries a value for, so the day this returns a number, `UnitCost_USD` re-enters the
weighted score with **no change to the scoring code**, and the applied weights shift from
`0.50/0.25/0.25` back toward the declared `0.40/0.20/0.20/0.20`.

Decide first: DAPCA IV gives a *whole-aircraft* cost, but the trade needs a *per-candidate* cost.
Costing `F110_GE_100` or `ConventionalTrapWing` means costing aircraft that were never built —
which is exactly the invented-number problem D-005 refused to solve. Options: (a) leave cost as a
whole-aircraft Measure of Merit only and never let it into the trade; (b) let it into the trade
with `Estimate`-tagged per-candidate deltas, inventoried in D-030. **(a) is the honest one** and
costs you the "cost re-enters with no code change" demonstration.

### B3 · `REQ_F16A_023 / 024 / 025` have no requirement values

`requirements/generate_f16a_requirements.m:188, 193, 206` — tipback angle, rollover angle, static
margin. All three are `TODO: … at least TBD deg`. This is deliberate and correct: the Brandt model
computes these as *outputs* and no program minimum was ever specified, so stating one would invent
a requirement. The descriptions already carry the reference-aircraft values (21.5°, 74.4°,
xnp ≈ 26.168 ft) explicitly labelled "analysis output, not a design requirement value".

Decide: leave as the standing student exercise, or set program minima yourself. If left, they are
**not** TODOs — see D2.

### B4 · `REQ_F16A_D01`–`D09` have no acceptance criteria

`requirements/generate_f16a_derived_requirements.m` — all nine derived functional requirements say
`PLACEHOLDER: quantitative criteria TBD`, keyword `todo`. Same situation as B3 and same decision,
except these nine are described in `docs/03_traceability.md` as *"a to-do list to make the
requirements complete"* — i.e. they are already framed as the exercise. Recommend leaving them and
saying so explicitly, so a reader stops looking for the missing numbers.

---

## C · Deferred method work

All three are argued in `docs/07_decision_log.md` and none is a defect. Listed so they are not
rediscovered as bugs.

| # | Item | Decision | Why deferred |
|---|---|---|---|
| C1 | Rival-independent decisiveness — which criterion, if removed, changes the winner | **D-034** | A real sensitivity calculation. The current "decided by" is measured against the runner-up only, and the printed output and stored justification now say so. |
| C2 | Bounded value function per criterion over a declared range | **D-035** | `M_baseline/M` is unbounded above while `B/10` and `(TRL−1)/8` cap at 1.0, so the declared weights stop describing influence if a candidate beats its baseline. Currently *warns* at run time. No candidate arms it today. |
| C3 | Search the 2×2×2 morphological box instead of three independent pairs | **D-016** | The three variation points demonstrably interact — relaxed static stability only pays off *with* fly-by-wire. Evaluating 8 combinations instead of 3 pairs is a genuine extension, not a fix. |

---

## D · Not TODOs — close these

Each of these matches a `TODO`/`TBD`/`stub`/`placeholder` grep but is working-as-designed. They
are listed so a future sweep does not "fix" them.

| Marker | Where | Why it stays |
|---|---|---|
| **D1** · `DefaultValue="'TBD'"` on `DecisionRef`, `Justification`, `TraceRef`, `RealizesRole`, `RealizesKind` | `F16A_LogicalOptions.xml`, `F16A_PhysicalProps.xml`, both generators | Deliberate sentinels. `assertRationaleComplete` *aborts the build* on any surviving `'TBD'` rationale, and an L model shipping `DecisionRef='TBD'` is the correct unresolved state (D-019). |
| **D2** · `TODO`/`TBD` in requirement text | `generate_f16a_requirements.m`, `generate_f16a_derived_requirements.m` | The requirement genuinely has no value. Writing one would invent it. See B3/B4 — these are a *content* decision, not a code TODO. |
| **D3** · "Verification links are added manually (known issue)" | `docs/README.md:210` | An R2026a Requirements Toolbox limitation, not our defect: a MATLAB test file cannot be a link *source*. The links themselves are made and correct — but see **A2b**, they are not being *loaded*, and the paragraph's explanation of why is wrong. |
| **D4** · `UnitCost_USD` is `NaN` everywhere | trade study, both profiles, cost MoM | D-005. A visible `NaN` is the honest "pending Measure of Merit"; a `0` default would be an unbeatably good score under a ratio value function (D-021, D-032). Resolved by B2, not before. |
| **D5** · D-030's inventory of 19 invented numbers | `docs/07_decision_log.md:317` | A *record*, not a backlog. The numbers are meant to stay invented and tagged `Estimate`; the entry exists so they can never be cited as F-16 data. |
| **D6** · `F16AFuelVerificationTest` fails | `verification/` | Intentional and documented. Becomes a real TODO only under B1. |

---

## Suggested order

- ~~**A1 / A1b / A2**~~ — done. Project is 12/12; 92/92 tests still pass.
1. **A2b** — two lines, and it makes the model's first "verified by" relationship actually visible.
   Right now the headline feature of the P layer does not show up in the tool.
2. **A3**, **A5** — trivial; one currently-false doc statement and one `.gitignore` line.
3. **A4** — decide cheap vs. right; the two-figure reconciliation is worth doing either way.
4. **B1** — highest teaching value per hour, and the analysis is already written.
5. **B2** — decide (a) vs. (b) *before* writing code; the decision is the interesting part.
6. **C1–C3** — only if you want to extend the example.

### Note for future stages

The registry drifted because file *moves* and file *additions* never propagated to the project.
Both are cheap to catch: run `runChecks(currentProject)` at the end of any stage that adds or
moves a file, and expect 12/12.
