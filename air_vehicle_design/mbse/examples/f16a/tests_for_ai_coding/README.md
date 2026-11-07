# tests_for_ai_coding

Guard rails for whoever edits the models (a person or an AI agent). They are not
part of the lesson.

```matlab
openProject("f16a.prj")
run_ai_tests          % must be green after any model edit
```

`F16ABaselineTest` asks one question: **have the numbers moved?** It re-runs,
without writing to any model:

| Analysis | Baseline |
|---|---|
| Engine / Airframe / FlightControls trade studies | every candidate's score and the ranking; the winner is the active choice in P, its kind the active choice in L |
| Mass roll-up | OEW |
| Materials roll-up | airframe composite fraction |
| Fuel roll-up | available fuel |
| Mission analysis | mission fuel and time |
| Cost model | unit, O&M (annual and life) and life-cycle cost |
| Stored Measures of Merit | the values on `F16A_Physical/Aircraft` match the above |

If a change is meant to move a number, update its baseline in
`F16ABaselineTest.m` in the same commit.

## This is not `verification/`

|  | `tests_for_ai_coding/` | `verification/` |
|---|---|---|
| Asks | did a number change? | does the design meet this requirement? |
| Expected state | all green | one red, by design |
| Traceability | none | a Verify link per test |
| Audience | whoever is changing the model | students |
