# tests_for_ai_coding

These tests are safety checks for the person or AI agent that edits the models. They are not
part of the lesson.

```matlab
openProject("f16a.prj")
run_ai_tests          % must pass after each model edit
```

`F16ABaselineTest` asks one question: **did a number change?** It runs these analyses again, and
writes to no model:

| Analysis | Baseline |
|---|---|
| Engine / Airframe / FlightControls trade studies | the score of each candidate and the ranking. The winner is the active choice in P, and its kind is the active choice in L |
| Mass roll-up | OEW |
| Materials roll-up | airframe composite fraction |
| Fuel roll-up | available fuel |
| Mission analysis | mission fuel and time |
| Cost model | unit, O&M (annual and life) and life-cycle cost |
| Stored Measures of Merit | the values on `F16A_Physical/Aircraft` are the same as the values above |

If a change is intended to change a number, update its baseline in `F16ABaselineTest.m` in the same
commit.

## This is not `verification/`

|  | `tests_for_ai_coding/` | `verification/` |
|---|---|---|
| Asks | did a number change? | does the design meet this requirement? |
| Expected state | all green | one red, by design |
| Traceability | none | a Verify link for each test |
| Audience | the person who changes the model | students |
