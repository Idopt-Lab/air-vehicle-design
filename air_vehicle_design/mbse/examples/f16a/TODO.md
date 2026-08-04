# F-16A RFLP example — open work

Working file, not teaching material. Open items only — what was decided and why lives in
[`docs/07_decision_log.md`](docs/07_decision_log.md), which this file does not restate.

## Open

| # | Item | Decision | Owner |
|---|---|---|---|
| 1 | **Fuel roll-up is not variant-safe** and calls `getProperty` on every child of `FuelSystem` without a stereotype check — a real defect in `physical/F16APhysicalFuelRollup.m`. Mirror `F16APhysicalMaterialsRollup.materialLeaves`. No test calls this function today; add one. | D-038 | `f16a-physical` · `f16a-vnv` |
| 2 | **Brandt masses are transcribed twice** — `generate_f16a_physical.m` and `F16APhysicalArchitectureTest.m` each hold their own copy of the same 16 figures, so the test verifies a transcription. Have the test execute `BrandtWeight.m` instead. **Land `PhysicalItem.DataProvenance` in the same stage** (see below). | D-036 | `f16a-vnv` · `f16a-data` |
| 3 | **`architecture/` → `functions/`.** Own stage, own gate — it touches the project registry, the one thing here that has drifted before. Finish at `runChecks` 12/12 with no unstaged `resources/project/` diff. | D-039 | `f16a-functions` |
| 4 | **`F16APhysicalCostModel` is a stub.** Real DAPCA-IV flyaway estimate populating `MeasureOfMerit.UnitCost_USD` on `Aircraft`; candidates keep `NaN` forever. Move the cost write after the generator's section 9 — OEW does not exist in section 8. Reword the "cost re-enters the trade" claim wherever it appears: the trigger is *the candidates carry a cost*, not *a cost model exists*. | D-043 | `f16a-physical` · `f16a-data` |

**Item 2 carries a second half.** `PhysicalItem` declares `{ Mass_lb }` and no `DataProvenance`, so 14
of the 16 masses summing to OEW carry no provenance — and six of them carry
`Material.DataProvenance = Estimate`, which describes their *composite fraction* while their mass is
`Reference`. A reader inspecting `Fuselage` sees a **contradicting** tag, not a missing one. Give
`PhysicalItem` its **own** `DataProvenance` (do not overload `Material`'s) and have the gate check that
no leaf carries two provenance tags that disagree.

**Item 4 carries a second half.** Two of the seven candidate `Rationale.Justification` narratives make
unsourced claims about real hardware — `F100_PW_200` on thrust-to-weight and production maturity,
`F110_GE_100` on higher thrust and stall margin. **There is no thrust property anywhere at P**, so
those trace to nothing, and the maturity claims restate the model's own `TRL` as fact about the real
engines. Citation or hedge, either way a log entry.

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
