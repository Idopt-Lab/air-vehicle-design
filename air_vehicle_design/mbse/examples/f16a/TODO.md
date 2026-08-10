# F-16A RFLP example — open work

Working file, not teaching material. Open items only — what was decided and why lives in
[`docs/07_decision_log.md`](docs/07_decision_log.md), which this file does not restate.

## Open

*Nothing.* D-036, D-038, D-039, D-043 and the engine-provenance item all landed; the four §Deferred
items below are extensions, not defects.

## Deferred method work

Argued in the log, none of them defects — they extend the example rather than fix it.
**C1** rival-independent decisiveness (D-034) · **C2** bounded value functions over declared ranges
(D-035) · **C3** search the 2×2×2 morphological box instead of three independent pairs (D-016).

## Dropped

- **A cross-artifact canonical-text checker.** A test asserting the wording of doc files is machinery a
  teaching repo should not carry. Keep canonical sentences unwrapped and in one home instead.
- **Test-local `containers.Map` → `dictionary`** in `tests_for_ai_coding/`
  (`F16APhysicalArchitectureTest`, `F16ALogicalArchitectureTest`). The maps never leave their class,
  so the migration buys nothing a caller can see. `F16APhysicalTradeStudy`'s was migrated because
  its map is a return value, and is still a `dictionary` now that the file is only a runner.

## Deliberately not defects

- **Two tests are red by design, for different reasons**, and both are in `verification/`.
  `F16AFuelVerificationTest` — `REQ_F16A_P01` is *unevaluated*, nothing is computed (D-042).
  `F16AStaticMarginVerificationTest`'s landing case — `REQ_F16A_025` is *violated*, something was
  computed and the design does not meet it (D-051). **Two reds are the expected state; a third is a
  regression.** Do not "fix" either, and do not let a sweep report them as the same thing.
  Everything in `tests_for_ai_coding/` must be green (D-055).
- **Eleven requirements are deliberately blank** — `REQ_F16A_023`/`024` and `REQ_F16A_D01`–`D09` keep
  their `todo` keyword and their placeholder text. The blanks are the assignment (D-045, D-046); the
  gear-angle brief is in [`docs/01_requirements.md`](docs/01_requirements.md).
- **`'TBD'` stereotype defaults** on `DecisionRef`, `Justification`, `TraceRef` and `RealizesKind`
  are sentinels. `assertRationaleComplete` aborts the build on a surviving `'TBD'` rationale, and an
  L model shipping `DecisionRef='TBD'` is the correct unresolved state (D-019).
- **No candidate carries a cost at all** — only the **aircraft** does, a real DAPCA IV figure
  (D-043). DAPCA prices an airframe, not a part; the candidates' column was `NaN` permanently, so
  D-056 stopped declaring it. `MeasureOfMerit.UnitCost_USD` still defaults to `NaN`, never `0`, which
  would be an unbeatably good score under a ratio value function (D-021, D-032).
- **`Thrust_SL_lb` is the engine trade's own criterion** (D-056, superseding that half of D-053).
  Scored as `v = T/T_baseline`, weight 0.30 — but **no T/W ratio is computed anywhere**, in the
  model, a test or the docs. Two of the three engines are declared hypotheticals whose thrusts are
  invented, and only the engine stereotype declares a thrust.
- **The engine ceiling warning fires on every run**, and is meant to. `TwinEngine_Surrogate` scores
  `v(Thrust_SL_lb) = 1.346`, above the 1.0 the bounded criteria cap at. D-035 decided to warn rather
  than cap or error; D-056 gave that decision a live case, and a test asserts it stays live. Do not
  silence it — the deferred fix is **C2**.

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


### 2 ongoing; started 9 Aug 2026
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
Later, the fuel burn value will be used by the cost model. 


### 4
I want to see all the views:
R-> F mapping
F-> L matrix
Morphological matrix

### 6
The roll-up analysis are too complex for anyone to understand. This is a teaching repo. Walk them through how its happening. The code should be extremeley simple.
There should be lots of print statements when someone runs the script. 

### D-034 · "Decided by" is decisive against the runner-up, and says so
`decisiveCriterion` measures the winner's largest weighted advantage over the **rank-2** candidate;
the printed table and stored justification now say *against the runner-up*. **Why** The same victory
gives a different "deciding" criterion depending on the rival. Scores and winners were never affected —
what was overclaimed is the audit trail. Rival-independent decisiveness is **C1**.

### D-035 · The mass value function is unbounded above (known limit)
`v = M_baseline / M` has no ceiling while `B/10` and `(TRL−1)/8` cap at 1.0, so a candidate lighter than
its baseline makes the declared weights stop describing influence. **Decision** Warn at run time; do
not cap (discards real information) and do not error (rejects a legitimate candidate). Bounded value
functions over declared ranges are **C2**.

### D-016 · Variation points are decided independently (acknowledged simplification)
Three binary kinds form a 2×2×2 box; the example evaluates three independent pairs, not 8 combinations.
**Why it is a simplification** The choices interact — relaxed static stability only pays off *with*
fly-by-wire. Stated plainly in `06_methodology.md` rather than glossed over. Extending it is **C3**.

### 7
Right now, I like that there are stereotypes and parameters. The trade studies are resolved by reading the values stored. But those are just hardcoded values. 
I want to demonstrate a workflow where that is actually calculated by running scripts. 
The /sizing/ folder has such scripts. 

### 8
The /sizing/ folder F16WeightsL3 scripts give a breakdown of all the aircraft subcomponents. This kind of information can help guide the physical decomposition. It is also the way you can run scripts and then use that to populate the values stored in the stereotypes and parameters, and then eventually the roll-up analysis gives the total weight.

### 9
This is starting to feel messy. I need a single source of truth for inputs and outputs. The MBSE model is supposed to be that single of truth. So there needs to be consistency between the MBSE model, the JSON input files, the outputs of the sizing scripts. 

### 10
When it comes to avionics, there needs to be SWAP-C analysis.