# F-16A MBSE class: instructor run-sheet (60 min)

Students follow along in [`F16A_MBSE_Class.mlx`](F16A_MBSE_Class.mlx), which drives the model in
[`../examples/f16a`](../examples/f16a). This sheet is for you: timings, what to say, where to click.
The quiz questions, options, answers and feedback are in
[`F16A_MBSE_Class_Quiz.md`](F16A_MBSE_Class_Quiz.md). The live script only reads the models;
nothing it runs changes a file.

## Before class

**You**
- [ ] **Publish the example.** It exists only on branch `f16_rflp`, and your local copy is ahead of
      `origin`. Push it, or merge it to `main`, and tell students which branch to pull.
- [ ] **Build the quiz** in Microsoft Forms (in class) and Canvas (formative) from the quiz file.
      Keep the numbering Q1–Q18, and start each question with its section (for example *§1.1*).
      The live script does not show the questions, so the section tells students when to answer.
- [ ] Dry-run the `.mlx` top to bottom on the projector machine. It takes under a minute of compute;
      the first `openProject` on a fresh clone takes longer. While you do, note the clicks you will
      show. None of these were checked against the R2026b UI when this sheet was written:
  - where the Requirements Editor puts the **Implementation Status** and **Verification Status**
    columns and its **Run Tests** command;
  - what its **Links** section shows for `REQ_F16A_011` in §1.1, before `F16A_Functional` is open
    (probably IDs such as `F16A_Functional:3`) and after §1.2 (`GenerateLift`, `ProduceThrust`);
  - how `PropulsionSystem` shows its two kinds when you open it in `F16A_Logical` (§1.3);
  - in the Profile Editor (§1.5), the clicks from `F16A_PhysicalProps` to `EngineCandidate`'s
    property list.
- [ ] Optionally, try `slreq.generateTraceabilityDiagram("REQ_F16A_011")`, the built-in alternative
      to section 6. It follows links only, so it stops at the functions: allocations are not links.

**Students** (send the day before)
- MATLAB **R2026b** with Simulink, System Composer and Requirements Toolbox.
- Pull the repo, open `air_vehicle_design/mbse/lectures/F16A_MBSE_Class.mlx`, and run sections
  0–4 once as a smoke test. Section 3 should print `none: 26` and section 4 `implemented: 26`.

## Learning objectives

1. Name the file that holds each RFLP layer, and open it.
2. Explain what a profile, a stereotype and a property are, and that this model's are custom-built.
3. Link a requirement to the element that implements it and to the test that verifies it, and say
   which file each link is stored in.
4. Tell the three relationships apart: **Implement**, **Allocate**, **Verify**.
5. Read a trade study that decides at P and writes its decision back to L and R, and judge how
   fragile its weights are.
6. Run the analyses behind the numbers (mission fuel, mass roll-up), and say what each one reads
   from the model and which requirement uses its result.

## Running the quiz

Students open the Forms quiz at the start and answer each question when they reach its section in
the live script; the script itself shows no questions. Stop the room and show the response summary only on the **core** questions (Q1, Q2,
Q4, Q5, Q8, Q10, Q11, Q13, Q15, Q17, Q18). The rest are answered at each student's own pace, and you can
review them later in Canvas. Allow about a minute per pause, including the reveal.

## Timeline

| Min | Live script | Block | Quiz | The one idea |
|---|---|---|---|---|
| 0–3 | §0 | Hook and setup | | A document can't answer "where is this satisfied?"; a model can |
| 3–14 | §1, 1.1–1.6 | Tour and terminology | Q1–Q3 | Each layer is a file you can open; the data on a component is custom-built |
| 14–17 | §2 | RFLP map | Q4 | Three kinds of link; a link lives with the artifact it starts from |
| 17–22 | §3–4 | R → F | Q5, Q6 | 0 of 26 implemented → 26 of 26, by loading the models |
| 22–27 | §5 | F → L | Q7, Q8 | Allocation; L presents options but does not choose |
| 27–30 | §6 | Trace | Q9 | The model answers "why does the F100 exist?" |
| 30–40 | §7–10 | Trade at P | Q10–Q13 | The twin has 35% more thrust and still loses; the weights decide |
| 40–47 | §11, 11.1–11.3 | The code behind the numbers | Q14, Q15 | The model holds the data; ordinary MATLAB does the engineering |
| 47–55 | §12–13 | Verification | Q16, Q17 | Met, violated, not evaluated; red is an honest answer |
| 55–60 | §14 | Wrap-up and exit ticket | Q18 | The same pattern applies to their RFP |

### 0–3 · Hook and setup (§0)

- **Say:** "Last week you wrote requirements in a document. Two questions: *where is REQ_F16A_011
  (Mach 1.6 at 36,000 ft) satisfied?* and *why does the F100 engine exist?* With a document you go
  searching. With a model you ask it."
- **Do:** everyone opens the `.mlx` and the Forms quiz, then runs §0.
- **Warn first:** §0 closes any open project and unloads every requirement set, so students should
  save their own work before running it. If the `assert` fires, their current folder isn't
  `lectures/`: `cd` there, or accept the Live Editor's *Change Folder* prompt.

### 3–14 · Tour and terminology (§1 to §1.6)

Seven short sections. From §1.1 on, each one opens a window, so tell students to come back to the
live script after each.

- **§1 (1 min):** why the F-16A: the answer is known (one F100), so the class can check whether the
  method reaches it. The requirements come from Brandt's F-16A sizing spreadsheet, the same kind of
  sizing model they use. Opening the project takes 5–30 s on a fresh clone. Walk the folder table,
  then point at the **Words you will meet** table: students will come back to it. Plant one seed
  without explaining it: the `~mdl.slmx` and `~m.slmx` files beside the models and tests (§4).
- **§1.1 R (3 min):** the table lists the 26 requirements in eight categories. Read
  `REQ_F16A_011` and `REQ_F16A_022` aloud from the printed text. **Pause on Q1.** The answer is
  printed at the top of §1.2. The **Links** section already lists two links for 011, although only
  the requirement set was opened: the open project loads its link sets. Park that; §3 is built on
  it.
- **§1.2 F (1 min):** the nine-function tree. `GenerateLift` and `ProduceThrust` sit under
  `ProvideAircraftFunctions/Aviate`. **Naming rule:** a function is a verb; a role or a part is a
  noun.
- **§1.3 L (1 min):** nine roles, three of them variants with two kinds each. Point at
  `PropulsionSystem` → `SingleEngine` / `TwinEngine`.
- **§1.4 P (1 min):** three engine candidates with numbers. Only the F100 is `Reference` data.
  "The twin has 32,000 lb of thrust against 23,770." Hold that thought for Q10.
- **§1.5 Stereotypes (3 min):** the terminology students lack. Say it plainly: **System Composer
  gives you components; you add the data.** You built both profiles: `F16A_PhysicalProps` (eight
  stereotypes) and `F16A_LogicalOptions` (one, `SolutionOption`). Three words:
  - *profile*: the file of definitions a model imports (`.xml`);
  - *stereotype*: a custom component type (`EngineCandidate`);
  - *property*: a field the stereotype declares (`Thrust_SL_lb`), filled in per component.

  The MATLAB-class analogy helps: stereotype = class definition, property = class property,
  stereotyped component = object. Show the Profile Editor, then the Property Inspector on
  `F100_PW_200` (one group per stereotype). Then **parameters**: a built-in System Composer feature
  that this model doesn't use, so when students meet the word in the documentation it means
  something else. Worth saying: the properties carry no units (they are in the names, `_lb`), and
  `DataProvenance` is a MATLAB enumeration you wrote (`physical/F16ADataProvenance.m`).
  **Pause on Q2**; Q3 is self-paced.
- **§1.6 Tests (1 min):** `verifyLessThanOrEqual(cf, 0.20, ...)` is `REQ_F16A_022` written as code.
  The test names the requirement only in comments and messages; the link itself is stored in
  `F16AMaterialsVerificationTest~m.slmx`.
- **Watch for:** students who move blocks while exploring. That is harmless: closing the project in
  §3 leaves an edited model open, and §3 and §4 still give 0 and 26. Tell them not to save, and to
  close the model without saving after class.

### 14–17 · The RFLP map (§2)

- Students have now seen every artifact the table names, so this goes quickly.
- Walk the figure: allocation runs F → L → P, every layer *implements* requirements in R, and tests
  *verify* R.
- **Key sentence:** "A link lives with the artifact it starts from." **Pause on Q4.**

### 17–22 · R → F (§3–4)

- **§3:** first closes the project and unloads everything, then loads only the requirement set.
  **Pause on Q5** before revealing why it reports `none: 26`.
  - Aside if asked ("but in the tour the editor showed links"): in R2026b, opening the project
    auto-loads its link sets. That is why §3 closes the project first. The example's README claim
    ("open `f16a.slreqx` on its own and every requirement looks unimplemented") holds only with the
    project closed.
- **§4:** loading takes 5–30 s. `after` shows `implemented: 26`.
- **In the Requirements Editor:** turn on the **Implementation Status** column. Select
  `REQ_F16A_009` → **Links** on the right → *Implemented by* `Loiter` → click it, and the mission
  activity opens on that action. Q6 (self-paced) uses the same clicks.
- **Derived requirements:** D01–D09 came from decomposing the functions (maneuver, fuel management,
  navigation, the targeting steps). Functional analysis feeds back into R, and their `TBD` criteria
  are homework.
- *Optional, 1 min:* the mission activity's 10 phases each run `F16AMissionSegment('<phase>')`, and
  Combat holds the F2T2EA kill chain as a child activity. §11.1 comes back to these calls, so skip
  this if you are short of time.

### 22–27 · F → L (§5)

- **Allocation Editor:** `F16A_FunctionToLogical` (7 edges) and `F16A_KillChainToLogical` (7).
  Q7 is self-paced.
- **Implement vs Allocate:** Implement answers "which requirement does this satisfy?"; Allocate
  answers "which element realizes this?"
- `LandingGear` and `MissionSystemsBay` receive no allocation. They exist to satisfy constraints
  (023/024, 020), not to perform a function.
- **Pause on Q8**, the name test. Expect an argument about `FlyByWire`, and welcome it: an L kind is
  free of technology, vendor and numbers, but it is not free of *solution*.

### 27–30 · Trace (§6)

- Read the figure backwards from the F100: `F100_PW_200` ← `SingleEngine` (selected) ←
  `PropulsionSystem` ← `ProduceThrust` ← `REQ_F16A_011`. *That* is why the F100 exists.
- Q9 (self-paced) has students set `reqId` to `REQ_F16A_022` and re-run. Constraints (020, 022–026)
  trace to L or P, not F.

### 30–40 · The trade study (§7–10)

- **§7: pause on Q10 before anyone runs the section.** Most of the room will pick the twin; they saw
  its thrust in §1.4. Then run it and point at the printed steps 1–4 and the warning (thrust value
  1.35 > 1).
- **§8:** the F100 beats the twin by +0.075 = thrust −0.104, mass +0.091, TRL +0.088. Mass decides.
- **§9: pause on Q11** after a minute of weight-hunting. Q12 is self-paced; if time allows, ask for
  the reason aloud ("dominated").
- **Caveats** (`examples/f16a/docs/06_methodology.md`): additivity is an assumption; the author
  chose the weights, they were not swing-weighted; `(TRL−1)/8` is linear; the ratio values are
  unbounded; and the answer was known in advance, so this demonstrates the method, not a finding.
- **§10, one picture instead of three models.** The decision is stored in two models and a
  requirement set, and no built-in view spans all three, so `plotDecision` reads them and draws
  them together: R (`REQ_F16A_L01` and its Implement link), L (the kinds, with `Selected` and
  `DecisionRef`), and P (the candidates, with the score and "lost most on" from each `Rationale`).
  **Pause on Q13**, then walk the four numbered steps right to left.
  - The section then opens the built-in **Traceability Matrix** (`f16a_logical_derived` ×
    `F16A_Logical`): one marked cell per trade, L01 → `SingleEngine`, L02 → `FlyByWire`,
    L03 → `BlendedCrankedDelta`. It shows the R side of all three trades at once. (It also lists a
    few *1) Add Subsystem or Model* columns; those are empty variant slots, so ignore them.)
  - If someone asks to see it in the tools: Property Inspector on `TwinEngine_Surrogate`
    (`Rationale`), and on `SingleEngine` (`SolutionOption`).
- **Don't run with `Record=true` in class.** It rewrites the model files and doesn't change the
  answer.

### 40–47 · The code behind the numbers (§11)

- **Why it is here:** it answers the "is MBSE just boxes and vocabulary?" reaction. **Say:** "The
  model holds the data. The engineering is ordinary MATLAB that reads it, and you could write every
  line of it." The table at the top lists each analysis, what it reads from the model, and what uses
  its result.
- **§11 (1 min):** the printed body of `F16ARunAnalyses` has four steps in a fixed order: trades,
  roll-ups, mission, cost. The roll-ups measure the configuration that the trades chose, and the
  cost model reads OEW and mission fuel, so the order matters. It writes and saves the models, so
  the class never runs it.
- **§11.1 (3 min):** `F16AMissionAnalysis` prints five steps. Point at step 3 (the four segments
  that the model leaves out are *checked* to burn nothing, not assumed) and step 5 (5959.8 lb
  against 6000.43 lb in Brandt's spreadsheet, inside ±1%). The `phases` table shows that each action
  stores a call, not a number. The printed lines of `BrandtMission.m` are the sizing method students
  already use: Part 1 is TSFC × drag × time. Expect "why does takeoff burn 1540 lb in 13 s?". It is
  mostly Brandt's fixed allowance of 1000 lb per engine, plus a 1-minute warm-up
  (`segment_takeoff_`). Q14 is self-paced.
- **§11.2 (2 min):** `instantiate` is the key line, because the instance keeps only the active
  choices. `rollUpMass` is ten lines long and gives 19,981 lb, the same as the recorded OEW. With
  the losers, the total would be 39,481 lb. **Pause on Q15**, then say: "This is why the roll-ups
  run after the trades."
- **§11.3 (1 min):** the fuel roll-up finds the tanks by their stereotype (3 × 2100 = 6300 lb). The
  mission burns 5960 lb, which leaves 340 lb. The figure is `REQ_F16A_P01` drawn as a picture, and
  the test in §12 makes the same comparison.
- The section prints source code instead of opening it in the Editor, so a stray keystroke cannot
  change a sizing file.

### 47–55 · Verification (§12–13)

- **§12:** Q16 (self-paced) comes before the run. Running the tests *from the requirement sets*
  (~5–10 s) records each result on its requirement: 022 met, P01 met, 025 **violated**.
- **In the Requirements Editor:** turn on the **Verification Status** column. 022 is green, P01 (in
  `f16a_physical_derived`) is green, 025 is red. Select `REQ_F16A_025` → *Verified by* shows two
  test methods, and clicking one opens the test at those lines.
- **§13, read the diagnostic:** takeoff SM = −0.26 %MAC (met). Landing SM = **+0.21 %MAC**, which is
  stable and so violates `SM < 0`. Burning fuel and dropping stores moves the CG forward, from
  26.198 to 26.145 ft, across the neutral point at 26.168 ft. The passing
  `testAnalysisProducedUsableMargins` proves the analysis ran, so the red is a verdict. The cause is
  Brandt's simplified neutral point, not the real F-16A.
- **Pause on Q17.** The answer is printed at the top of §14.

### 55–60 · Wrap-up (§14)

- Map it onto their project: RFP → R; their concept choices (single or twin, tube-and-wing or
  blended body, tail type) → kinds at L; real candidates with numbers → P; analyses that read the
  model; one test per hard constraint. If they want data on their components, they write a
  profile, as you did.
- Homework is listed in §14.
- **Q18, exit ticket:** students answer it as they leave.

## If time runs short

Cut in this order:
1. The mission-activity tour (§4).
2. Pauses on self-paced questions: never stop the room for Q3, Q6, Q7, Q9, Q12, Q14 or Q16.
3. Run §1.3–1.4 yourself on the projector.
4. The weight hunt in §9: show the plot and give 0.42.
5. The Traceability Matrix in §10: the decision figure covers the engine trade.
6. In §11, the printed walk-throughs: show only the `phases`, `missionFuel` and `oew` tables, and
   run §11.3 without comment (§12 makes the same fuel comparison).

## Fallbacks

- **Laptop can't load** (wrong release, missing toolbox): pair up.
- **Slow first load:** start §0–1 running while you give the hook.
- **Anything confused:** re-run §0 (it resets everything), then §3–4.

## Answer key

The full options and feedback are in the quiz file.

| Q | Answer |
|---|---|
| 1 | `REQ_F16A_011` (performance; functions implement it). 022 is a constraint, implemented by P `Airframe` |
| 2 | A property, declared by the `EngineCandidate` stereotype |
| 3 | `EngineCandidate`, `PhysicalItem`, `Thrust_SL_lb` |
| 4 | `functions/F16A_Functional~mdl.slmx` |
| 5 | The links live in the models' link sets, and none is loaded |
| 6 | `MaintainStructuralIntegrity` |
| 7 | `Target` (→ `AvionicsSuite` and `WeaponSystem`) |
| 8 | `F100_PW_200`, `CarbonFibreWing_Hexcel` |
| 9 | P `Airframe`; `F16AMaterialsVerificationTest` |
| 10 | `F100_PW_200` (0.956 against the twin's 0.881) |
| 11 | 0.40–0.45 (0.4246) |
| 12 | No: the F100 dominates it on all three criteria |
| 13 | P active choice and `Rationale`; L active kind with `Selected = true`; R Implement link to L01 |
| 14 | In the sizing mission analysis, `BrandtMission.m`; the action stores only the call |
| 15 | The analysis instance keeps only the active choice of each variant (19,981 lb; 39,481 lb with the losers) |
| 16 | The test checks it; the link alone says nothing about pass or fail |
| 17 | Change the design; change the requirement with a recorded justification; fix a wrong analysis |
| 18 | e.g. `GenerateLift` → 011 in `F16A_Functional~mdl.slmx`; `ProduceThrust` → `PropulsionSystem` in `F16A_FunctionToLogical.mldatx`; materials test → 022 in `F16AMaterialsVerificationTest~m.slmx` |
