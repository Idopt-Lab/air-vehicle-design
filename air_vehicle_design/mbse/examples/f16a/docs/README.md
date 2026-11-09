# F-16A RFLP MBSE Example

A teaching model of the **F-16A** built with the **RFLP** framework in System Composer and
Requirements Toolbox (MATLAB R2026b). It shows two things: **traceability** from a requirement down
to a part, and **trade studies** that choose between competing designs and record the decision in
the model.

```mermaid
graph LR
  R["<b>R</b><br/>Requirements<br/><i>what is needed</i>"]
  F["<b>F</b><br/>Functions<br/><i>what it must do</i>"]
  L["<b>L</b><br/>Logical<br/><i>roles and kinds</i>"]
  P["<b>P</b><br/>Physical<br/><i>parts and candidates</i>"]
  R -->|implemented by| F -->|allocated to| L -->|allocated to| P
  P -. "trade decides the kind" .-> L
```

Each layer is its own artifact. Links and allocation sets tie them together, so the model can always
answer *"why does this part exist?"* and *"where is this requirement satisfied?"*.

## Open it

```matlab
openProject("f16a.prj")
F16AOpenForReview      % loads every model, requirement set and link set; opens the Requirements Editor
```

## Walk through it

| Step | Look at | Open with | The idea |
|---|---|---|---|
| **1 · R** | 26 requirements from the Brandt F-16A sizing model, plus derived sets | `slreq.editor` | Only spreadsheet *inputs* become requirements ([01](01_requirements.md)) |
| **2 · F** | 9 capabilities and the 10-phase mission activity | `systemcomposer.openModel("F16A_Functional")`, `systemcomposer.openActivity("F16A_MissionActivity")` | Capabilities are structure; the mission is behaviour ([02](02_functions.md)) |
| **3 · L** | 9 solution roles; 3 hold two competing **kinds** | `systemcomposer.openModel("F16A_Logical")` | L presents options, it does not pick ([04](04_logical.md)) |
| **4 · Trade** | one script per decision | `F16AEngineTradeStudy` (also Airframe, FlightControls) | Score the P candidates, write the winner into P, L and R ([05](05_physical.md#trade-studies)) |
| **5 · P** | 30 parts, 7 candidates, and each candidate's kind | `systemcomposer.openModel("F16A_Physical")`, `systemcomposer.allocation.editor` | Roll-ups compute emergent totals ([05](05_physical.md)) |
| **6 · Verify** | three requirements with tests | `runtests("verification")` | Met, and not met, are both results ([below](#three-requirements-two-verification-states)) |

Every trade and roll-up prints its steps and every number it reads, so you can check the arithmetic
by hand. `F16AEngineTradeStudy(Record=false)` scores without writing anything.

## Traceability at a glance

| Relationship | From → to | Stored in | Count |
|---|---|---|:-:|
| Implement | capability / mission action → requirement | `functions/*~mdl.slmx` | 21 + 18 |
| Allocation | capability → role · kill-chain action → role | `logical/F16A_FunctionToLogical.mldatx` · `F16A_KillChainToLogical.mldatx` | 7 + 7 |
| Implement | role or kind → requirement | `logical/F16A_Logical~mdl.slmx` | 7 |
| Allocation | role → part · **kind → candidate** | `physical/F16A_LogicalToPhysical.mldatx` | 14 |
| Implement | part → requirement | `physical/F16A_Physical~mdl.slmx` | 4 |
| Verify | test → requirement | `verification/*~m.slmx` | 3 requirements |

**A link lives with the artifact it starts from, not with the requirement.** Open `f16a.slreqx` on
its own and every requirement looks unimplemented, because the links ship with the models and the
tests. Loading those is what `F16AOpenForReview` does.

**The kind → candidate edges are the bridge for the trade.** `SingleEngine` is allocated to both
`F100_PW_200` and `LowThrustSingle_Surrogate`, and `TwinEngine` to `TwinEngine_Surrogate`. When a
candidate wins, the trade follows its edge back to the kind and makes that kind active at L.

Six requirements have no function to trace to, because they constrain the solution rather than the
behaviour: 020, 023, 024 and 025 trace to L roles; 022 and 026 trace to P parts.

## Three requirements, two verification states

```matlab
runtests("F16AMaterialsVerificationTest")      % REQ_F16A_022 — green
runtests("F16AFuelVerificationTest")           % REQ_F16A_P01 — green
runtests("F16AStaticMarginVerificationTest")   % REQ_F16A_025 — 2 pass, 1 RED BY DESIGN
```

| Requirement | State | What it teaches |
|---|---|---|
| `REQ_F16A_022` composite ≤ 20% | 🟢 met | the evidence is a roll-up over the model itself |
| `REQ_F16A_P01` fuel volume | 🟢 met | 6,300 lb of tankage against 5,960 lb of mission fuel from the `/sizing/` analysis |
| `REQ_F16A_025` static margin | 🔴 **violated** | the requirement *was* evaluated, and the design does not meet it |

**One red is the expected state; a second is a regression.** `testAnalysisProducedUsableMargins`
passing is what proves the analysis ran, so the landing red is a verdict, not a broken tool. It is a
property of the simplified reference model, not of the real F-16A
([01](01_requirements.md#025--static-margin)).

A Verify link records that a requirement is checked, and by what, not that the check passed.

## Exercises

1. **Write the missing criteria.** `REQ_F16A_D01`–`D09` state a need with `TBD` acceptance criteria.
   Nothing external defines them, so the blanks are the assignment.
2. **Settle the gear angles.** `REQ_F16A_023`/`024` are blank because Brandt's angles may not use
   the convention the specifications use. The brief is in [01](01_requirements.md#023--024--the-gear-angle-exercise).
3. **Add a fourth engine.** Add a choice under `F16A_Physical/Aircraft/Propulsion/Engine`, apply
   `EngineCandidate`, fill in its properties and `DataProvenance`, allocate it from a kind in the
   L→P allocation set, and run `F16AEngineTradeStudy`. If you skip the allocation, the trade stops
   and tells you which candidate has no kind.
4. **Move a weight.** Change a weight in a trade's criteria table. How far can it move before the
   winner changes?
5. **Go further:**
   - Name the criterion that decides *regardless of rival* (D-034).
   - Bound the ratio value functions (D-035).
   - Search the 2×2×2 combinations instead of three separate pairs (D-016).
   - Draw the F2T2EA kill chain as a sequence diagram: `addInteraction` is available in R2026b.

## Folder layout

```
f16a/
├─ f16a.prj · f16aRoot.m · F16AOpenForReview.m
├─ F16ARunAnalyses.m          changed a number? re-run every trade and analysis
├─ requirements/              f16a (26) · functional_derived (D01–D09) · logical_derived (L01–L03)
│                             · physical_derived (P01, P02)
├─ functions/                 F16A_Functional.slx (+ .sldd for the activity's flows)
│                             · F16A_MissionActivity.slx · F16AMission{Analysis,Segment,Reference}.m
├─ logical/                   F16A_Logical.slx · F16A_LogicalOptions.xml · two F→L allocation sets
├─ physical/                  F16A_Physical.slx · F16A_PhysicalProps.xml · F16A_LogicalToPhysical.mldatx
│                             · F16A{Engine,Airframe,FlightControls}TradeStudy.m (steps 1–4)
│                             · F16ARecordTradeDecision.m (steps 5–6, shared) · F16AKindOf.m
│                             · F16APhysical{Mass,Materials,Fuel}Rollup.m · F16APhysicalCostModel.m
│                             · F16APhysicalMissionFuel.m · F16ASourceKind.m · F16ADataProvenance.m
├─ verification/              one test per verified requirement, with its Verify link set
├─ tests_for_ai_coding/       F16ABaselineTest: have any numbers moved? · F16AVerifyLinksTest:
│                             does every Verify link still sit on its test method? (not teaching material)
├─ resources/                 MATLAB project metadata (file registry, labels, path); edit through the project
└─ derived/                   cache MATLAB's project writes when tests or requirements run; git-ignored
```

| Document | Contents |
|---|---|
| [`01_requirements.md`](01_requirements.md) | R: provenance, structure, the derived sets, the gear-angle and static-margin cases |
| [`02_functions.md`](02_functions.md) | F: capabilities, the mission activity, F2T2EA, R→F links |
| [`04_logical.md`](04_logical.md) | L: roles, F→L allocation, the kinds and how the decision comes back |
| [`05_physical.md`](05_physical.md) | P: parts, kind→candidate allocation, trade studies, roll-ups, MoMs |
| [`06_methodology.md`](06_methodology.md) | Why the trade lives at P, its sources, and what weighted-sum scoring does not justify |
| [`07_decision_log.md`](07_decision_log.md) | Standing decisions (D-0xx); **D-030 lists every invented number** |

## Maintaining the model

The models, requirement sets and allocation sets are the source of truth. Edit them in the editors
or through the API, then:

```matlab
F16ARunAnalyses     % trades → roll-ups → mission → cost, written back into the models
run_ai_tests        % every number against its baseline, every Verify link on its method; must be green
```

- **Never rebuild a model from scratch.** Allocation sets and Verify links point at element SIDs, and
  a rebuilt model has new ones.
- **Add, move or delete files through the project** (`addFile`/`removeFile`), then expect
  `runChecks(currentProject)` to report 12/12. `removeFile` also stages the git deletion.
- **Keep `.m` files LF, on Windows too.** A Verify link stores a character offset into its test
  file, and CRLF adds one character per line, which moves the link off its method; `runTests` on a
  requirement set then reports false fails. `.gitattributes` forces `*.m text eol=lf`, and
  `F16AVerifyLinksTest` fails if a test file has CRLF or a link has drifted (after editing a test,
  for example). Re-point a link with `setLineRange` on `slreq.getTextRanges(file)`, then save the
  test's link set.
- `F16ASourceKind.m` and `F16ADataProvenance.m` type two stereotype properties, so they must be on
  the path whenever `F16A_PhysicalProps` loads. The project path takes care of this.

API behaviour measured on this model (R2026b):

| Topic | Behaviour |
|---|---|
| String and enum stereotype properties | stored as expressions: write `"'TBD'"`, read back `'TBD'` with quotes; strip with `erase(…, "'")` |
| Variant choices | reach them with `getChoices` only; they are not in the parent's `Architecture.Components` |
| Analysis instance | holds only the active choice, flattened under the variant node |
| Decision links | `slreq.load("F16A_Logical")` before linking, or links into L01–L03 duplicate |
| Requirement link from an activity action | `slreq.createLink(action.SimulinkHandle, req)`; allocation takes the action object |
| Activity nodes | `addNode(name, type)`, name first; `connect` lives on the nodes; an action whose behaviour is an activity has no settable `Duration` |
| Verify link from a test | `slreq.createLink(slreq.createTextRange(testFile, lines), req)`, then set `Type = "Verify"`. The shipped links were made by hand before this worked. The range is a character offset: LF only |
| `NaN` into a property | `string(NaN)` is `<missing>`, which `setProperty` rejects; use `string(num2str(NaN))` |

Prerequisites: MATLAB R2026b · Simulink · System Composer · Requirements Toolbox. The cost model, the
mission and the static-margin test also call `sizing/VnV/BrandtF16A/`, three folders up.
