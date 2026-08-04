# F-16A RFLP example — open work

Working file, not teaching material. Open items only — what was decided and why lives in
[`docs/07_decision_log.md`](docs/07_decision_log.md), which this file does not restate.

## Open

| # | Item | Decision | Owner |
|---|---|---|---|
| 1 | **`F16APhysicalCostModel` is a stub.** Real DAPCA-IV flyaway estimate populating `MeasureOfMerit.UnitCost_USD` on `Aircraft`; candidates keep `NaN` forever. Move the cost write after the generator's section 9 — OEW does not exist in section 8. | D-043 | `f16a-physical` · `f16a-data` |

## Deferred method work

Argued in the log, none of them defects — they extend the example rather than fix it.
**C1** rival-independent decisiveness (D-034) · **C2** bounded value functions over declared ranges
(D-035) · **C3** search the 2×2×2 morphological box instead of three independent pairs (D-016).

## Dropped

- **A cross-artifact canonical-text checker.** A test asserting the wording of doc files is machinery a
  teaching repo should not carry. Keep canonical sentences unwrapped and in one home instead.
- **Test-local `containers.Map` → `dictionary`** in `F16APhysicalArchitectureTest` and
  `F16ALogicalArchitectureTest`. The maps never leave their class, so the migration buys nothing a
  caller can see. `F16APhysicalTradeStudy`'s was migrated because its map is a return value.

## Deliberately not defects

- **Two tests are red by design, for different reasons.** `F16AFuelVerificationTest` —
  `REQ_F16A_P01` is *unevaluated*, nothing is computed (D-042). `F16AStaticMarginVerificationTest`'s
  landing case — `REQ_F16A_025` is *violated*, something was computed and the design does not meet it
  (D-051). **Two reds are the expected state; a third is a regression.** Do not "fix" either, and do not
  let a sweep report them as the same thing.
- **Eleven requirements are deliberately blank** — `REQ_F16A_023`/`024` and `REQ_F16A_D01`–`D09` keep
  their `todo` keyword and their placeholder text. The blanks are the assignment (D-045, D-046); the
  gear-angle brief is in [`docs/01_requirements.md`](docs/01_requirements.md).
- **`'TBD'` stereotype defaults** on `DecisionRef`, `Justification`, `TraceRef`, `RealizesRole`,
  `RealizesKind` are sentinels. `assertRationaleComplete` aborts the build on a surviving `'TBD'`
  rationale, and an L model shipping `DecisionRef='TBD'` is the correct unresolved state (D-019).
- **`TradeCandidate.UnitCost_USD` is `NaN` on all seven candidates**, permanently. A `0` default would
  be an unbeatably good score under a ratio value function (D-021, D-032, D-043).

## Standing rule

Run `runChecks(currentProject)` at the end of any stage that adds, moves or renames a file, and expect
**12/12**. The registry has drifted before, and both times it was a move or an addition that never
propagated to the project.



## These are open ToDos written by user. AI should not read this section

### 1
- For 03_traceability
-- let's call it 05_traceability. 01 is requirements, 02 is functions, 03 is logical, 04 is physical. 
- In 04_logical, 
-- remove the previous decision and now the "kind names changed" portion. That is not useful anymore. Remove the "Why L cannot answer which one?" section; its also too much exposition. Little  
-- Little more info on the stereotype and the mechanisms in place for the model to recognize which option was chosen and why
--The implement link should exist between a requirement and this Logical layer, even if the specific option (variant) isn't decided yet. The selection happens at the Physical layer


### 2
The F16APhysicalTradeStudy.m is too complex for anyone to understand. 
I want you to break it into 3 separate files, one for each of the trade studies. Write extremely simple code and walk through
- How they will open a model
- How they will read relevant values
- How they will conduct a trade study
- How they will inform back the model the decision made
There should be lots of print statements when someone runs the script. 

Is there only one stereotype for all the 3 different trade studies?
That doesn't make sense. The Engine Trade has values and properties it uses. The other two use their own based on the type of trades they are making. So, I want there to be different stereotypes for each of the candidate.


### 3
You have defined a Execute Mission Profile. 
This is what the /sizing/mission_analysis does. It walks through each mission segment and computes various quantities. I want to connect the MBSE model to this analysis model. 


### 4
I want to see all the views:
R-> F mapping
F-> L matrix
Morphological matrix

### 5

You have a bunch of tests that are good for debugging and when you are making changes. But those tests are written in a manner that is hard to read and is not useful as part of the teaching. So, I want you to move them all to a new folder named "tests_for_ai_coding". In addition to moving them, try and simplify. 

### 6
The roll-up analysis are too complex for anyone to understand. This is a teaching repo. Walk them through how its happening. The code should be extremeley simple.
There should be lots of print statements when someone runs the script. 