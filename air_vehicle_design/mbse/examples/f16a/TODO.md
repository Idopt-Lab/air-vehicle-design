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

### A4 · Ground truth is transcribed, not referenced — DECIDED (**"Right"**), not yet implemented

**Decision, 2026-08-01: take the "Right" option, sourced from the `.m` model.**
`F16APhysicalArchitectureTest` will read the 16 ground-truth masses by executing
`sizing/VnV/BrandtF16A/BrandtWeight.m` (read-only, `run(31377)`) and reading its properties —
**not** from `GroundTruth/Brandt-F16-A.xls` and not from `cell-map.md`. The generator stays the only
place the numbers are typed. Full entry, mapping table and constraints: **D-036** in
`docs/07_decision_log.md`.

Note before implementing: the `.m` model does **not** reproduce the spreadsheet exactly — the nacelle
area uses `π` where the spreadsheet uses `3.1516`, giving −0.37% on `W_nacelles` and `W_inlet_duct`
and ≈0.01% on OEW (`readme_wt.md` §10). So this **converts an exact-equality assertion into a
tolerance assertion** (adopt sizing's own 1% RelTol / 0.1% split). Internal MBSE self-consistency
stays exact. This also settles the OEW 19980.73-vs-19980.70 and airframe 6722.88-vs-6722.87
reconciliation: both are correct, and the drift becomes measured instead of hidden.

**Four traps closed in D-036 at the Stage-0 gate (2026-08-02) — read them before writing the test:**

| # | Trap | What to do |
|---|---|---|
| 1 | **`f16aRoot()` is THREE levels up from `air_vehicle_design`, not four.** D-036 said four. `f16aRoot()` returns `…/air_vehicle_design/mbse/examples/f16a`; three `fileparts` reach `…/air_vehicle_design`, where `sizing/` lives. | Copy `F16AStaticMarginVerificationTest.m:220`, which already does it correctly — and use a `PathFixture`, not a bare `addpath` (D-047). |
| 2 | **`BrandtAirframeMass_lb` is misleadingly named.** The constant (`F16APhysicalArchitectureTest.m:234`) holds 6722.88 = the airframe **structural subtotal**, but its name points at Brandt's `W_airframe_lb` = **15250.47** (`Wt!B10`, OEW − engine, structure *plus* systems). | Map `BrandtAirframeMass_lb` ← **`W_structure_lb`** and `ExpectedOEW_lb` ← `W_empty_lb`. **`W_airframe_lb` is deliberately NOT mapped** — no MBSE component equals it, because the model has no "everything but the engine" grouping. Wiring by name would swap in a figure more than twice the size and still read plausibly. |
| 3 | **`W_other_lb` belongs on the 1 % side, not the 0.1 % side.** It only *looks* algebraically exact: `BrandtWeight.m:244` derives it as `0.30 × W_structure_lb`, and `W_structure_lb` (`:186`) includes `W_nacelles`, so it inherits the π error. `test_BrandtWeight.m:167–168` asserts only the **relation** (`AbsTol 1e-6`), never the absolute 2016.86. | Assert it at 1 % RelTol. Nothing in `/sizing/` certifies its absolute value at 0.1 %, so the MBSE test must not be the first artifact that claims to. (The measured drift is < 0.01 %, so 0.1 % would pass today — this is a provenance call, not a numerical one.) |
| 4 | **D-036's delta-table figure `W_inlet_duct ≈ 726.87` is wrong — do not hard-code it.** Inherited from `readme_wt.md:415`. `BrandtWeight.m:194` makes it exactly `3.9 × W_nacelles`, so `3.9 × 186.12` = **725.87**. The `−0.37 %` column is right; the absolute figure is not. | Nothing to fix — the whole point of A4 is that the test **executes** `BrandtWeight` instead of transcribing. Do **not** "fix" `readme_wt.md`: `/sizing/` is read-only (house rule 4). |

<details><summary>Original write-up</summary>

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

</details>

### ~~A5 · `derived/artifacts.dmr` is untracked and unignored~~ — NOT A DEFECT (verified 2026-08-01)

Already ignored, by the **repo-root** `.gitignore` rather than the example's:

```
$ git check-ignore -v air_vehicle_design/mbse/examples/f16a/derived/artifacts.dmr
.gitignore:39:*.dmr    air_vehicle_design/mbse/examples/f16a/derived/artifacts.dmr
```

`git status --porcelain` is clean and `--ignored` lists `f16a/derived/` as ignored. The original item
looked only at `f16a/.gitignore`, which has `work/` but no `*.dmr` — the rule is one level up. No
change needed. (A non-`.dmr` file appearing in `derived/` would still show up; if that ever matters,
add `derived/` to the example `.gitignore` then.)

---

> **A6–A11 come from the deep-dive code review of 2026-08-01.** All six were verified against the
> repository. A6, A7 and A11 carry a recorded decision (**D-037**, **D-038**, **D-039**); the rest are
> straightforward corrections with no decision to make.

### A6 · The decision requirements state the trade's answer before the trade runs — DECIDED: fix (**D-037**)

`requirements/generate_f16a_logical_derived_requirements.m` is the one place in the example where the
central thesis — *L presents the options, P decides* — is contradicted by the artifacts themselves.
Line 55:

> `"The PropulsionSystem role shall be realized by a single afterburning turbofan (Pratt & Whitney`
> `F100 class), rather than a twin-engine installation."`

Per the README's build order this generator runs **before** `generate_f16a_physical`. So the model
records *"single engine was selected"* as a **premise**, in a file the trade study never rewrites — it
only adds an Implement link. Three distinct problems, in increasing order of how quietly they bite:

| # | Problem | Where |
|---|---|---|
| 1 | **A vendor name in the L-decision record.** D-020 stripped `F100`/`PW`/`GE` from the L *kinds* and made the ban executable (`testKindsAreTechnologyNeutral`). The requirement recording that decision still says "Pratt & Whitney F100 class". | L01 `Description`, l. 55 |
| 2 | **Run-time-derived weights are typed in.** All three `Rationale` fields say *"with weights 0.50 / 0.25 / 0.25"*. **D-026** is explicit that those are *derived at run time* by dropping cost from `0.40/0.20/0.20/0.20`. The day **B2** lands, three requirement texts become silently wrong, and nothing compares them to the trade's output. | ll. 56, 62, 68 |
| 3 | **A D-034-class overclaim, one file over.** L03 says the blended delta wins on *"a lighter structure relative to the role's baseline mass"* — but `BlendedCrankedDelta` **is** the baseline (`Reference`), so `v = M_baseline/M = 1.0` exactly. It is lighter than its *rival*, not than the baseline. | l. 68 |

`testProductionConfigurationWins` pins the winner *identities*, so the headline claim cannot drift.
Nothing pins the weights or the reasoning. This is **A4's problem — transcribed rather than
referenced — applied to the decision rationale instead of to the masses.**

**What needs to be done**

1. **Rewrite each `Description` to pose the decision rather than answer it.** L01 becomes something of
   the shape *"The PropulsionSystem role shall be realized by exactly one of the kinds presented at
   L — `SingleEngine` or `TwinEngine`. The selected kind, and the arithmetic that selected it, are
   recorded by the Physical-layer trade study."* No vendor, no programme, no winner.
2. **Strip the hand-typed verdict prose and the `0.50 / 0.25 / 0.25` weights from all three
   `Rationale` fields.** Whatever survives must be true *before* the trade has run.
3. **Fix the L03 baseline overclaim** (item 3 above) wherever the sentence ends up living.
4. **Add the missing tests** (`f16a-vnv`), mirroring D-020's precedent:
   - the three decision requirements' `Description`/`Rationale` contain no vendor/programme token
     (reuse `testKindsAreTechnologyNeutral`'s case-sensitive token list: `F100 F110 PW GE LWF Analog`);
   - they restate no weight and no score — the numbers live where they are computed.
5. **Note the knock-on for D-020.** Its closing note deferred L02's *"analog fly-by-wire"* and L01's
   YF-16/YF-17 framing to Stage 6 as "historical framing in a decision record". That framing is
   exactly what item 1 removes, so D-020's deferral is closed by this work rather than separately.

**Sub-question RESOLVED — option (a), see D-040.** The requirement stays a **pure question**. The
verdict lives in exactly one place: the winning candidate's `Rationale.Justification` at P, plus the
Implement link from the winning kind. No generator writes a verdict into a requirement set. (Option
(b) — the trade study writing the verdict into the requirement — was rejected: it would have meant a
P-layer script writing into an R-owned artifact, and a re-run of the R generator blanking it.)

That resolution adds **one more edit** to the list above: two doc sentences claim the requirement is
the record of the *verdict*, which under (a) it is not. Reword both to say the requirement is where the
decision is **posed and anchored**, while the verdict is the trade study's output:

- `requirements/generate_f16a_logical_derived_requirements.m`, header — *"This requirement — not the
  variant flag — is where the decision is authoritatively recorded"*
- `docs/03_traceability.md:144` — *"the requirement — not the variant flag — is the authoritative
  record of the decision"*

Note this does **not** hand authority back to the variant flag: the flag stays derived (D-027).

### A7 · `F16APhysicalFuelRollup` is the last non-variant-safe walk — DECIDED: fix (**D-038**)

`physical/F16APhysicalFuelRollup.m` is the only file in `physical/` containing no `getChoices`,
`getActiveChoice` or `VariantComponent` handling. Lines 23–31:

```matlab
fuelSys = lookup(m, Path="F16A_Physical/Aircraft/FuelSystem");
tanks = fuelSys.Architecture.Components;          % <- not variant-safe
for i = 1:numel(tanks)
    cap(i) = str2double(string(getProperty(tanks(i), char(capProp))));   % <- no stereotype check
end
```

Two independent defects in nine lines:

- **Not variant-safe.** If `FuelSystem` ever becomes a variant role, Stage-0 **finding 6** applies:
  `.Architecture.Components` returns the choices on a freshly built in-memory model but **ZERO** on the
  same model saved and reloaded. `sum([])` is `0`, nothing errors, and the roll-up reports
  **0 lb of available fuel**. Today that is masked because the required side is `NaN`; after **B1** it
  turns a green verification red for a reason nobody would find quickly.
- **No stereotype check.** `getProperty(..., FuelTank.FuelCapacity_lb)` is called on *every* child of
  `FuelSystem`. A child that does not carry `FuelTank` — a pump, a manifold, a battery — errors out.
  `F16APhysicalMaterialsRollup` already solved exactly this, structurally and correctly.

**Why this is not hypothetical (your rationale, recorded in D-038):** `FuelSystem` becomes a variant
role the moment the example admits a **hybrid-electric or fully-electric** aircraft — at which point
"the energy-storage role" has competing kinds (fuel tankage / battery / hybrid) in precisely the way
`Airframe`, `Engine` and `FlightControls` already do. The model's own philosophy invites it: *"a role
with more than one candidate is not a part, it is an open question, and it is modelled as one"*
(D-002).

Note that **no test currently covers this function.** `testFuelTankCapacities` walks the three tank
paths itself and never calls the roll-up; the only caller is `F16AFuelVerificationTest`, which fails
on purpose.

**What needs to be done — part 1: make the walk correct**

Mimic `F16APhysicalMaterialsRollup.materialLeaves` exactly — the rule is structural, not a name list:

1. Replace the flat `fuelSys.Architecture.Components` loop with a **recursive `fuelLeaves` helper** on
   the same shape as `materialLeaves`.
2. At a `VariantComponent`, recurse into **`getActiveChoice`** — never `getChoices` (the roll-up must
   report the *active* configuration, matching `F16APhysicalMassRollup`'s architecture-side fallback)
   and never `.Architecture.Components`.
3. The leaf rule is **"a component that carries `FuelTank` IS a fuel leaf"** — checked with
   `getStereotypes`, not descended into further. That is what makes a lumped candidate (one whole-block
   capacity) and a decomposed candidate (one capacity per tank) work through the same walk with no
   list of names anywhere.
4. Keep `error(...:noFuelTanks, ...)` if the walk finds nothing, mirroring
   `F16APhysicalMaterialsRollup:noMaterialParts`. **A silent 0 is the failure mode being removed;
   do not replace it with a different silent 0.**
5. `f16a-vnv`: add a test that calls `F16APhysicalFuelRollup` directly and asserts the total against
   the tanks, so the function has a caller that is expected to pass. Today it has none.

**~~Part 2: roll up available fuel volume~~ — DROPPED (D-041)**

**Decision, 2026-08-02: weight only. No volume roll-up, no fuel density, no new property.**
`F16APhysicalFuelRollup` rolls up **available fuel weight** from the tanks and nothing else.

The reason it was dropped is worth keeping: volume needed a fuel density, and **`/sizing/` has none** —
verified, there is no fuel density and no fuel volume anywhere in `sizing/VnV/BrandtF16A/`, which works
entirely in fuel weight. Volume would have added a number with no home in the reference model, needing
its own provenance argument, to support a quantity nothing else in the example consumes. Weight is also
the only figure the requirement actually turns on.

Two follow-ons: `REQ_F16A_P01`'s wording *"(volume, expressed as fuel-weight capacity)"* is now the
**settled** formulation — leave it alone, it is not a hedge awaiting improvement. And the
weight-vs-volume "two figures that mean different things" trap cannot arise, because there is only ever
one figure.

<details><summary>Original part 2 write-up (not being built)</summary>

`REQ_F16A_P01` reads *"sufficient internal fuel tankage (**volume**, expressed as fuel-weight
capacity)"* — volume is currently a **proxy**, stated in pounds. The decision is to make it a real
rolled-up quantity. Three things have to be settled before code:

1. **Where volume comes from.** Either a new `FuelTank.FuelVolume_gal` (or `_ft3`) property carrying
   volume directly, **or** a fuel density converting the existing `FuelCapacity_lb`. The density route
   adds one number; the direct route adds three (one per tank) and lets them disagree with the weights.
   **Recommend the density route** — one number, one provenance tag, and the weight/volume pair cannot
   drift apart.
2. **⚠ The density is a NEW number and `/sizing/` does not have one.** Verified: there is **no fuel
   density and no fuel volume anywhere in `sizing/VnV/BrandtF16A/`** — the Brandt model works entirely
   in fuel *weight*. So D-007 and house rule 1 apply in full: the density must carry a
   `DataProvenance` tag and be inventoried in **D-030**. It cannot be tagged `Reference`, because there
   is nothing in `/sizing/` to reference. The honest options are `Datasheet` if cited to a fuel
   specification (JP-4 per MIL-DTL-5624 is the F-16A-era USAF fuel, ≈ 6.5 lb/gal; JP-8 per
   MIL-DTL-83133 is later, ≈ 6.7 lb/gal) or `Estimate` if simply chosen. **Cite the spec and tag it
   `Datasheet`** — this is one of the few numbers in the example that *can* be sourced properly, and
   the F-16A-era fuel is a defensible, teachable choice.
3. **Do not let the two figures merge.** This is the same trap B1 already warns about, one layer over.
   After this change the roll-up returns **two** quantities meaning different things:
   - `AvailableFuel_lb` — the **weight** figure, and the *only* one comparable with `BrandtMission`'s
     `Miss!O9 = 6000.43 lb` in the B1 verification. The verify test must keep using this one.
   - `AvailableFuelVolume_gal` — the **volume** figure, which answers "does the tankage physically
     exist?" and has no counterpart in `/sizing/` to check against.

   Both should come from **one walk in one function** (extend `F16APhysicalFuelRollup` to return both
   fields, rather than adding a second file that duplicates the walk and can disagree with it).

4. **Consequence for the requirement text.** Once volume is first-class, `REQ_F16A_P01`'s hedge
   *"(volume, expressed as fuel-weight capacity)"* stops being necessary and should be reworded by
   `f16a-requirements`. Note that the volume figure inherits **D-023**: the 3 × 2100 lb split is an
   `Estimate`, so a volume derived from it is an estimate divided by a datasheet constant, and cannot
   be more trustworthy than the capacity it came from.

</details>

**Order:** part 1 was originally sequenced before **B1**, because B1 would have made this roll-up
load-bearing. **B1 is now decided as never (D-042)**, so that pressure is gone — but the fix stands on
its own: the hybrid-electric variant argument is independent, and the missing stereotype check is a
correctness defect regardless of who calls the function.

### A8 · Two documentation corrections found by the review

Both verified; no decision needed.

1. **`docs/06_methodology.md` contradicts D-033 on the `Benefit` scale.** Two places still say
   **0–10**, which D-033 retired in favour of **1–10 with 0 as the "unset" sentinel** and which
   `F16APhysicalTradeGuards.BenefitScale = [1 10]` enforces:
   - `06_methodology.md:137` — *"`Benefit → B/10` on a stated 0–10 scale"*
   - `06_methodology.md:222–223` — *"They are our 0–10 and 1–9 rankings"*

   `docs/05_physical.md` has it right in all three of its mentions. D-015 and D-030 saying "0–10" is
   **fine and must not be edited** — the decision log is append-only history, and D-033 supersedes them
   in place. Only the method note is current documentation, and D-033's own closing words are *"code,
   comment and guard now agree"* — the method note did not.
2. **Two broken relative links, both in `docs/05_physical.md`, both off by one level from `docs/`:**
   - `:137` — `[../ex2](../ex2)` resolves to `f16a/ex2`; should be `../../ex2`
   - `:457` — `[/sizing/](../../../sizing)` resolves to `mbse/sizing`; should be `../../../../sizing`

### A9 · `countComps` in the L generator is not variant-safe

`logical/generate_f16a_logical.m:404–410` recurses through `c.Architecture.Components`.
`generate_f16a_physical.m:1182–1202` fixes precisely this and explains at length why — *"this generator
would report 30 while a test reloading the model reported 23, the two disagreeing for a reason nobody
would find quickly"*. The L copy has the same trap: it prints **15** on a freshly built in-memory model
(9 roles + 6 kinds) and would print **9** on a reloaded one.

Cosmetic today — the value is only used in a `fprintf` and no doc or test asserts it. Fix by copying
the P generator's variant-safe `countComps` verbatim, and state in the printed line which number it is
(components including kinds, vs. roles). `generate_f16a_functional.m`'s copy needs no change: the F
model has no variants.

### A10 · Lint and housekeeping (no behaviour change)

Static analysis over all 13 `.m` files is otherwise clean. What it reports:

- **~25 "extra comma is unnecessary"** (info) across the generators and test suites — all on the
  `try, ...; catch, end` idiom. Harmless and consistent; leave them or fix them wholesale, but not
  half.
- **19 stale `%#ok<...>` suppressions** in `F16APhysicalArchitectureTest.m` (ll. 2626–2835) for
  messages the analyzer no longer generates. Safe to delete.
- **`containers.Map`** in `F16APhysicalTradeStudy.m:248` — `dictionary` is the R2022b+ replacement and
  this repo is R2026a. A contained change: `results` is returned to the generator and to tests, so
  `.keys` and `results(char(role))` call sites move with it.
- **Not a defect:** `generate_f16a_physical.m:993` "format might not agree with the argument count" is
  a false positive — 6 conversion specs, 6 arguments; the analyzer cannot resolve the `fmt` variable.
- **Coverage gap worth a decision some day:** F, L and P each have an architecture test suite.
  `generate_f16a_requirements.m` — 26 requirements, the provenance root of everything downstream — has
  **none**. Not urgent, but it is the one layer whose output nothing asserts.

### A11 · Rename `architecture/` → `functions/` — DECIDED (**D-039**)

The F layer's folder is called `architecture/` for a reason that stopped being true in July 2026, and
no decision was ever recorded for it.

**Why it is named that.** The folder was created in the first F-layer commit — `2b1bd5a`, *"Add F-16A
RFLP Functions layer (F) with Simulink project and docs"* — when `F16A_Functional.slx` was the **only**
System Composer architecture model in the example. The name was accurate then: it held *the*
architecture model. `logical/` arrived at `d61256c` and `physical/` at `9f82c3f`, each named for its
**layer**, establishing a convention that `architecture/` predates. The reorg (`ea1f14f`) then moved the
F generator and test *into* the folder that already existed rather than renaming it; the commit body
records only the move.

**Why it should change.** All three layers are System Composer architecture models, so `architecture/`
names the property the F layer *shares* with L and P — the least distinctive thing about it — while
every sibling folder (`requirements/`, `logical/`, `physical/`, `verification/`) is named for its
concern. Five other names in the example all say *functions*: the README status table (**F – Functions**),
`docs/02_functions.md`, the agent `f16a-functions`, `generate_f16a_functional.m` and
`F16A_Functional.slx`. The folder is the lone dissenter, in an example whose whole point is that each
RFLP letter's concern is visible in the filesystem.

**What needs to be done**

1. **`git mv architecture functions`** — as a rename git can see, so classification labels survive
   (the same property A1 relied on).
2. **Five literal path strings in code** — this is the whole of the code impact; everything else
   resolves by name off the project path:
   ```
   architecture/F16AFunctionalArchitectureTest.m:17   addpath(fullfile(thisDir, "architecture"))
   architecture/generate_f16a_functional.m:38         archDir = fullfile(thisDir, "architecture")
   logical/F16ALogicalArchitectureTest.m:116          addpath(fullfile(thisDir, "architecture"))
   logical/generate_f16a_logical.m:92                 archDir = fullfile(thisDir, "architecture")
   F16AOpenForReview.m:20                             fullfile(thisDir,"architecture")
   ```
3. **The MATLAB project — this is the real cost, and it is exactly the A1 failure mode.** The folder is
   on the project path and its files are registered members. A `git mv` that does not propagate leaves
   dangling entries, fails *"All project files and folders exist on the file system"*, and lets a later
   operation garbage-collect them into a spurious `resources/project/` diff. Update the **project path**
   entry and re-register the moved files, then **`runChecks(currentProject)` expecting 12/12** — the
   standing rule in "Note for future stages" below.
4. **~11 documentation references** — `docs/README.md` (status table, folder tree, regenerate block,
   the project-path paragraph), `docs/02_functions.md:3–4`, `docs/03_traceability.md:3–4, 115`,
   `docs/08_agent_team.md:21`.
5. **`.claude/agents/f16a-functions.md`** — the agent's ownership line and the two body references to
   `architecture/`. (Repo root, the one documented exception to the `mbse/`-only write scope.)
6. **Do not rename anything else.** `F16A_Functional.slx`, `generate_f16a_functional.m` and
   `F16AFunctionalArchitectureTest.m` keep their names — they are already correct, and the test's name
   ("FunctionalArchitectureTest") describes what it tests, not where it lives.

**Give this its own stage and its own gate.** It touches the project registry, which is the one thing in
this example that has drifted before. Do not bundle it with A2b/A3.

---

## B · ~~Real gaps that need a decision from you~~ — **ALL FOUR DECIDED, 2026-08-02**

> B1 (D-042) and B4 (D-045) are decisions **not** to do something and close outright. B2 (D-043) and
> B3 (D-044) become implementation work — B3 with a **blocking check** first.

### ~~B1 · Wire `F16APhysicalMissionFuel` to `/sizing/`~~ — DECIDED: **NO. The red test stays red.** (D-042)

**`F16APhysicalMissionFuel` keeps returning `NaN`, permanently and by design.** It is not wired to
`BrandtMission`, now or later. The red test *is* the teaching artifact: it demonstrates "verification
is set up, traceable, and not yet satisfied" — the state a real programme lives in for most of its
life, and one nothing else in this example shows. Wiring it to `Miss!O9 = 6000.43 lb` would turn it
green and teach the opposite lesson. One requirement can only teach one of the two.

**What needs to be done** — nothing to the analysis; four places currently promise a wiring that will
not happen, and one marker is reclassified:

1. **`physical/F16APhysicalMissionFuel.m`** — the help block says *"STATUS: STUB … It **will be
   connected** to the mission / sizing analysis in /sizing/"*, and line 17 carries a `TODO:` marker.
   Rewrite to *"returns `NaN` **by design** (D-042)"* and delete the `TODO:` — it is not one.
2. **`docs/README.md:103`** — *"fails until /sizing/"* → *"fails by design"*.
3. **`docs/README.md:173–174`** — *"FAILS on purpose (mission-fuel stub) **until /sizing/ is
   connected**"* → drop the "until" clause.
4. **`docs/05_physical.md:456`** — *"It goes green once mission fuel is real"* → it does not; state
   that the pending verification is the deliverable.
5. **`docs/05_physical.md:616`** — *"The immediate to-dos are to wire `F16APhysicalMissionFuel` …"* →
   remove B1 from the to-do list entirely (B2 stays, in its D-043 form).
6. **TODO `D6`** below (*"`F16AFuelVerificationTest` fails — becomes a real TODO only under B1"*) is
   now **permanent**: B1 will never happen, so D6 is settled, not conditional.

For the record, since the analysis was done and someone will re-ask: the two `/sizing/` fuel figures
are **not** interchangeable — `BrandtMission` `Miss!O9` = 6000.43 lb is fuel *burned* by the 14-segment
mission; `BrandtWeight` `Wt!B6` = 6296.30 lb is fuel *capacity* implied by W_TO − payload − OEW.
`Miss!O9` was the correct one. Nobody needs to re-derive that to re-open this.

### B2 · Implement `F16APhysicalCostModel` — DECIDED: **whole-aircraft MoM only, option (a)** (D-043)

**Cost demonstrates the top-level "minimize cost" objective (`REQ_F16A_026`) and never enters the trade
study.** `F16APhysicalCostModel` gets a real DAPCA-IV implementation sourced from
`sizing/VnV/BrandtF16A/BrandtCost.m` and populates `MeasureOfMerit.UnitCost_USD` on the `Aircraft` with
a real number. `TradeCandidate.UnitCost_USD` **stays `NaN` on all seven candidates.**

Option (b) — per-candidate `Estimate` cost deltas — is rejected. DAPCA IV is a whole-aircraft
weight-and-quantity regression with a defensible answer for "what does this aeroplane cost" and none
at all for "what does this wing candidate cost"; applying it per candidate would dress an invented
number in a real model's clothes (D-005, D-030).

**What needs to be done**

1. **Implement the cost model.** Read the rolled-up OEW and the material mix from the model, follow
   `BrandtCost.m`'s DAPCA IV formulation. `BrandtCost`'s own validation target (≈ $68.4M, already
   quoted in `REQ_F16A_026`) is the **cross-check**, not the value to write.
2. **Tag it `Simulation`, not `Reference`.** A DAPCA IV output computed from *this model's* rolled-up
   OEW is an analysis output of this repo — which is exactly what `F16ADataProvenance.Simulation`
   means. `Reference` would overclaim.
3. **⚠ Reword the "cost re-enters the trade" claim in five places — this decision makes it false.**
   The example repeatedly promises *"the day a cost model exists, cost re-enters the score with no
   change to the scoring code"*. Under (a) **a cost model will exist and cost will still not
   re-enter**, because `F16APhysicalTradeStudy` reads `TradeCandidate.UnitCost_USD` — not
   `MeasureOfMerit.UnitCost_USD` — and the candidates still carry none. D-026's drop-and-renormalize
   *mechanism* is unchanged and still correct; the stated **trigger** was wrong. It is not "a cost
   model exists", it is "**the candidates carry a cost**". Fix at:
   `docs/05_physical.md:198` · `docs/05_physical.md:618` · `docs/06_methodology.md:165` ·
   `physical/F16APhysicalTradeStudy.m:95` · this file, above.
4. **Two tests need revisiting.** `testCostIsNaNEverywhere` and `testCostMeasureOfMerit` currently
   treat "cost is NaN" as uniform. After this the aircraft MoM is a real number while the candidates
   stay `NaN`, and that distinction becomes load-bearing rather than incidental — assert it.
5. **`D4` below narrows.** *"`UnitCost_USD` is `NaN` everywhere"* becomes *"`NaN` on the candidates"*,
   where it stays true and stays the right fail-safe.

The applied trade weights therefore stay `0.50 / 0.25 / 0.25` **permanently**. (This also removes the
reason I gave for sequencing A6 before B2 — see *Suggested order*.)

### B3 · `REQ_F16A_023 / 024 / 025` — DECIDED (**D-046**): **only `025` gets criteria** · `025` **BUILT** (**D-047**)

The definition check flagged below was accepted. Rather than resolve the gear-angle conventions now,
**the ambiguity becomes the assignment.**

| Req | Outcome | `todo` keyword |
|---|---|---|
| `023` tipback angle | **No criteria.** Stays a placeholder — student exercise | stays |
| `024` rollover/overturn angle | **No criteria.** Stays a placeholder — student exercise | stays |
| `025` static margin | **Real, checkable requirement** — see below | **comes off** |

**`023` / `024` — nothing is written in.** The USAF 16–25° tipback band and the 63° / 54° USAF / USN
overturn limits do **not** go into the model. They join `REQ_F16A_D01`–`D09` (D-045) as standing
exercises, and stay covered by **D2** below.

**The `rollover` → `overturn` rename is deferred with them**, and deliberately: calling Brandt's
quantity "the overturn angle" would assert the very identification that is in doubt — whether
`atand(h_main/d_axis)` is an overturn angle at all, or the complement of one. **Naming it correctly is
part of the exercise.** The existing wording stands; the six-file sweep is not performed. (Easy to
reverse if you'd rather have the terminology fixed now.)

**`025` — relaxed static stability, with a two-sided band.** Reworded from "moderately negative" to:

> The static margin `SM = (x_np − x_cg)/MAC` shall lie between **−6 %MAC and +1 %MAC** across the
> operational CG range (takeoff through landing weight).

This **reverses the previous revision's construct**: `025` is no longer an objective in the
`REQ_F16A_026` (cost) mould — it is a **threshold requirement with a two-sided band**, and something
can assert it. The lower bound is the design intent: a deliberately relaxed, near-neutral-to-slightly-
unstable configuration that cuts trim drag and buys instantaneous turn rate, flyable only because the
FCS supplies artificial stability — the same fact `REQ_F16A_L02`'s fly-by-wire rationale turns on. The
`+1 %` upper bound caps how *stable* the aircraft may become; without it, "relaxed" would be satisfied
by a conventionally stable aeroplane.

**⚠ The band itself is an invented number, and is now tagged as one (D-048).** −6 %MAC carries no
source: `/sizing/` has no static-margin criterion, no specification is cited, and nothing computes it.
It has no stereotype and so no `DataProvenance` slot, so it is inventoried in **D-030**'s table
(row appended 2026-08-02) and tagged `Estimate`. The band is **unchanged** — −6 % to +1 % stands
exactly as D-046 set it — what changed is that it may no longer be quoted as F-16A data.

**It passes — and be precise about why.** `SM_TO` = **−0.260 %MAC** and `SM_land` = **+0.206 %MAC**
(measured). The −0.22 % / +0.27 % pair often quoted alongside these is **not** a workbook figure: it
is the expected value in `sizing/VnV/BrandtF16A/tests/test_BrandtBalanceStabControl.m:68,72`
(−0.00219 / +0.00272, `AbsTol` 0.001), and that test file is the only place in the repo it appears —
it is not in `GroundTruth/cell-map.md` (which has no BSC section) nor in `readme_bsc.md`'s validation
list. The computed values sit inside that `AbsTol`, so the sizing suite passes; the residual is **an
analogous `.m`-vs-`.xls` discrepancy** to the mass gap D-036 records, *analogous only* — the mass gap
has one documented cause (`π` vs 3.1516), this one has none, and `readme_bsc.md:44-46` lists three
different approximations that could contribute (exposed-span VT MAC correction, the −0.522 ft balance
datum shift, the width-scaled fuselage correction).

Both are inside [−6, +1], so the requirement is met at both ends of the CG range. But it is met
because the band is wide enough to admit a **near-neutral** result — *not* because the model
reproduces the strongly relaxed static stability the F-16A is generally described as having. The
−6 %MAC figure is an illustrative teaching value, not sourced data (D-030). Brandt's neutral point is
a simplified approximation (`readme_bsc.md`: *"a simplified neutral point"*, *"the fuselage
destabilizing correction is simplified to a width-scaled offset"*), and it lands near the **stable**
end of the band, not the relaxed end. The requirement's reference text must say that, instead of
quoting xnp/xcg in feet as it does today. A requirement a reference figure passes comfortably deserves
the same plain statement D-030 gives the composite fractions — so nobody reads the pass as evidence.

**~~Open — how `025` gets verified~~ — RESOLVED as (b) and BUILT (D-047). Source changes done; three
follow-up steps are not.**

`verification/F16AStaticMarginVerificationTest.m` exists and **passes 3/3**. It calls
`BrandtBalanceStabControl` read-only and checks both CG-range endpoints against the band.
`generate_f16a_requirements.m`'s `REQ_F16A_025` now carries the band and has lost its `todo` keyword.
Code Analyzer is clean on both files.

**No `verify` keyword, and that is deliberate** — an earlier revision of this item (and of D-047) said
`025` gains one. It does not. `generate_f16a_requirements.m:228-234` records why: `REQ_F16A_022` and
`REQ_F16A_P01` also have verification tests and are also not keyworded, because **the Verify link is
the authoritative record that a requirement has a test**. A generator-written keyword restating that
is a derived fact stored where it can drift out of step with the link — the failure mode D-027 and
D-040 exist to prevent. Nothing replaces the `todo` that came off.

**On "the file should be part of the .prj" — it cannot be, and does not need to be.** A MATLAB
project's files and path entries are **all relative to the project root** (`resources/project/**`
stores `location="…"` root-relative; the path entry is `<Info location="Root" type="ProjectPath"/>`).
`f16a.prj`'s root is this example folder, and `sizing/VnV/BrandtF16A` is **three levels above it**, a
sibling of `mbse/` — so it can be neither a project file nor a project path entry. There is also no
`.prj` under `sizing/`, so the referenced-project route is unavailable. And membership would buy
nothing anyway: **A1b measured exactly this** — 41 unregistered files ran fine, because resolution is
by the **MATLAB path**. The test adds the folder itself with a
`matlab.unittest.fixtures.PathFixture` — not a bare `addpath` — so it is **removed again when the
suite finishes** (verified). That matters here in a way it does not for the sibling layer folders the
other tests addpath: leaving `sizing/` on the path would let a later suite resolve a `Brandt*` name it
never asked for, making results depend on suite order.

**Still to do — the test is written but not yet wired into the tool:**

0. ~~**Apply the canonical −6 %MAC sentence**~~ — **DONE in source** (D-048 part 3). It reads: *"the
   strongly relaxed static stability the F-16A is generally described as having. The −6 %MAC figure is
   an illustrative teaching value, not sourced data (D-030)."* Verified verbatim in all four places:
   `generate_f16a_requirements.m:240` (`REQ_F16A_025`'s reference text),
   `verification/F16AStaticMarginVerificationTest.m:80`, `docs/07_decision_log.md` (D-044 and D-046),
   and this register. One wording, so they cannot drift into four different hedges. **Only the shipped
   `.slreqx` still has the old text** — which is step 1, and is why step 1 must not be skipped.
1. **Regenerate `requirements/f16a.slreqx`.** The shipped set still reads `TBD`; only the generator has
   the band. This is **not** a one-file re-run: `slreq.new` builds a fresh set, so the F/L/P models'
   Implement links resolve into the old one — the **whole documented chain** in README "Regenerate the
   artifacts" has to run. Heavy and artifact-writing, so left as a deliberate step.
2. **Add the Verify link by hand** — `REQ_F16A_025` → `F16AStaticMarginVerificationTest`, in the
   Requirements Editor (**D3** / README "Verification links are added manually"). That makes it the
   **third** row in that README table.
3. **Extend A2b to three link sets.** `F16AOpenForReview` must load
   `verification/F16AStaticMarginVerificationTest~m.slmx` alongside the two A2b already adds, or the
   new Verify link will be invisible for exactly the reason A2b documents. Register the new test file
   in `f16a.prj` (it *is* inside the project root) and confirm `runChecks` is 12/12.

<details><summary>The exercise brief — keep this, it is what makes 023/024 a good assignment</summary>

This arithmetic is why the values were withheld, and it is the material students should be handed.

`BrandtBalanceStabControl.m:221` computes `rollover_deg = atand(h_main_ft / d_axis)` — vertical over
horizontal, i.e. an angle measured **from the horizontal**. The standard overturn / turnover angle
(Raymer §11.4; Currey) is measured **from the vertical**. With the shipped inputs (`x_nose` 22.0,
`x_main` 37.7, `y_main` 6.0, `h_main` 5.3 ft, `xcg_TO` 26.193 ft): `d_axis` = 1.497 ft, so
`atand(5.3/1.497)` = **74.2°** (reproducing the validation target) and its complement
`atand(1.497/5.3)` = **15.8°**. They sum to exactly 90°. Read against the standard definition the F-16A
**passes the 63° limit with wide margin**; read against Brandt's convention it fails. **The same number
supports opposite verdicts, and only one of them is a fact about the aeroplane.**

Two further observations from the same inputs, which are why this is not settled by simply taking the
complement:

- **The gear load split is inverted for a tricycle aircraft** — `gear_main_pct` = 26.7 %,
  `gear_nose_pct` = 73.3 %, i.e. three-quarters of the weight on the nose gear. Normal is 85–95 % on
  the mains (**same sources as the overturn definition above: Raymer §11.4; Currey**). Everything
  geometric downstream inherits this.
- **The gear geometry does not match the aircraft** — Brandt's wheelbase is 15.7 ft and track 12.0 ft
  (`y_main` 6.0); the F-16A's are ≈ 13.3 ft and ≈ 7.75 ft — **uncited approximations, not data.**
  Neither is in `/sizing/`; the track is about right, but published F-16 wheelbase figures vary and
  13.3 ft is at the upper end of them. They are quoted only to show the two geometries differ by more
  than rounding, which is all the exercise needs. Do not cite either as an F-16A dimension.

`023` has a milder version of the same issue: Brandt's
`tipback_deg = atand((h_main + z_tail_bottom)/(L_fuse − x_main))` is a **tail-clearance / rotation**
angle, not Raymer's tipback-from-vertical, which on these same inputs gives
`atand((37.7 − 26.193)/5.3)` = **65°** — far outside the 16–25° band. The 21.5° that sits neatly inside
the USAF band is the tail-clearance figure. It agrees with the band under one definition only.

**The reference figures, for whoever sets the assignment:** USAF tipback 16–25°; overturn shall not
exceed 63° (USAF) or 54° (USN). Brandt computes ≈ 21.5° and ≈ 74.4°. **⚠ These four limits carry no
document number** — no specification, revision or paragraph was supplied with them, and none is in
`/sizing/`. D-046 kept them out of the model so nothing depends on them, but whoever sets the
assignment must supply the identifier, or make finding it the first half of the question. A student
cannot check an angle against "the USAF limit" without knowing which one.

**The question to put to students:** do these two quantities mean the same thing as the specification
they are being checked against — and if not, what is the correct comparison, and does the aircraft pass?
</details>

### ~~B4 · `REQ_F16A_D01`–`D09` have no acceptance criteria~~ — DECIDED: **leave as a student exercise** (D-045)

The nine derived functional requirements keep their `PLACEHOLDER: quantitative criteria TBD` text and
their `todo` keyword. Filling them in would take the exercise away, and unlike B3 no external
specification supplies values — writing any would be inventing requirements.

**What needs to be done** — one thing only: **say so explicitly in the docs**, so a reader stops looking
for missing numbers and understands the blanks are the assignment.
`docs/03_traceability.md`'s derived-requirements section (which already calls them *"a to-do list to
make the requirements complete"*) is where it belongs. The `TODO`/`TBD` strings in
`generate_f16a_derived_requirements.m` stay covered by **D2** below — a content decision, now a settled
one, not a code TODO.

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
| **D2** · `TODO`/`TBD` in requirement text | `generate_f16a_requirements.m` (`023`, `024`), `generate_f16a_derived_requirements.m` (`D01`–`D09`) | **Settled 2026-08-02, and it now covers more than it used to.** All eleven are permanent student exercises: `D01`–`D09` by **D-045**, and tipback/overturn by **D-046** — the latter withheld *because* the angle conventions do not obviously match the USAF/USN specs, which is the exercise. **`025` is the one exception and leaves this table**: D-046 gives it a real −6 %…+1 %MAC band, so its `TODO` text is genuine work under **B3**. |
| **D3** · "Verification links are added manually (known issue)" | `docs/README.md:210` | An R2026a Requirements Toolbox limitation, not our defect: a MATLAB test file cannot be a link *source*. The links themselves are made and correct — but see **A2b**, they are not being *loaded*, and the paragraph's explanation of why is wrong. |
| **D4** · `UnitCost_USD` is `NaN` ~~everywhere~~ **on the candidates** | trade study, both profiles | **Narrowed 2026-08-02 by D-043.** A visible `NaN` is the honest "pending Measure of Merit"; a `0` default would be an unbeatably good score under a ratio value function (D-021, D-032). Stays true and stays right **on the seven candidates, permanently** — cost never enters the trade. The *aircraft* `MeasureOfMerit.UnitCost_USD` stops being `NaN` under **B2**. |
| **D5** · D-030's inventory of invented numbers | `docs/07_decision_log.md:317` | A *record*, not a backlog. The numbers are meant to stay invented and tagged `Estimate`; the entry exists so they can never be cited as F-16 data. **The table is a living inventory** — D-030's decision text is committed history and is never rewritten, but new invented numbers get **appended** to it (D-038 requires a new number to "appear in D-030"). Grew from 19 to 20 on 2026-08-02 when the `REQ_F16A_025` **−6 %/+1 %MAC band** was tagged `Estimate` under **D-048** — the first *requirement threshold* in the table rather than a component property, and the reason house rule 1 now explicitly covers acceptance criteria. |
| **D6** · `F16AFuelVerificationTest` fails | `verification/` | Intentional and documented. **Permanent as of D-042** — B1 was decided as *never*, so this is settled rather than conditional. The `TODO:` marker in `F16APhysicalMissionFuel.m:17` belongs in this table too, and its help block should say "by design" (see B1). |

---

## Suggested order

- ~~**A1 / A1b / A2**~~ — done. Project is 12/12; 92/92 tests still pass.
  (**A5** needs nothing — verified not a defect.)
1. **A2b — now THREE link sets, not two** (D-047 adds a third verification test). It makes the model's
   "verified by" relationships actually visible; right now the headline feature of the P layer does not
   show up in the tool. Pair it with regenerating `f16a.slreqx` (B3 step 1) and hand-adding the two
   outstanding Verify links, so the requirement set and the link sets land consistent in one pass.
2. **A3 + A8 + A9 + A10** — one documentation-and-lint commit. A3 is the last pre-D-001 sentence, A8
   is two stale scale claims and two broken links, A9 is a copy-the-P-generator fix, A10 is
   suppressions and commas. Nothing here needs a decision.
3. **B1 + B4 + B3's `023`/`024` doc sweep** (**D-042**, **D-045**, **D-046**) — all three are
   decisions *not* to build; what is left is stopping the docs from promising work that will never
   happen, and saying out loud that D01–D09 **and the two gear angles** are the assignment. Cheap, and
   it retires most of section B outright.
4. **A6** — the decision-requirement rewrite (**D-037**, sub-question settled as (a) by **D-040**).
   No dependency on anything else now.
5. **A7 part 1** — the fuel roll-up's variant-safety and stereotype check (**D-038** part 1;
   part 2 dropped by **D-041**). Standalone.
6. **A4** — decided (**"Right"**, sourced from `BrandtWeight.m`; see **D-036**). What remains is
   implementation: the cross-model comparison, its tolerance, and the path teardown.
7. ~~**B3 — `025` only**~~ — **source work DONE** (**D-047**): the test passes 3/3 and the generator
   carries the band. What is left is items 1–3 of B3 above (regenerate the requirement set, hand-add
   the Verify link, extend `F16AOpenForReview` + register the file), which fold naturally into step 1.
   `023`/`024` need no code — they are in the item-3 doc sweep.
8. **B2** — the cost model as a whole-aircraft MoM (**D-043**). The five "cost re-enters the trade"
   rewordings are the part that is easy to forget and the part that would otherwise leave the docs
   claiming something the code will not do.
9. **A11** — the `architecture/` → `functions/` rename (**D-039**). **Its own stage, its own gate**:
   it touches the project registry, the one thing in this example that has drifted before.
10. **C1–C3** — only if you want to extend the example.

> **Correction to the previous ordering note.** It said A6 should precede B2 because B2 would change
> the applied weights and falsify the `0.50 / 0.25 / 0.25` typed into L01–L03. Under **D-043** that no
> longer holds: cost never enters the trade, so the applied weights stay `0.50 / 0.25 / 0.25`
> permanently and B2 cannot falsify those strings. A6 and B2 are now independent, and A6 is sequenced
> earlier only because it is cheaper.

### Note for future stages

The registry drifted because file *moves* and file *additions* never propagated to the project.
Both are cheap to catch: run `runChecks(currentProject)` at the end of any stage that adds or
moves a file, and expect 12/12.
