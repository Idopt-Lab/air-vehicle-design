# F-16A RFLP example — open work

Working file, not teaching material. Open items only — what was decided and why lives in
[`docs/07_decision_log.md`](docs/07_decision_log.md), which this file does not restate.

## Open

| # | Item | Decision | Owner |
|---|---|---|---|
| 1 | **Brandt masses are transcribed twice** — `generate_f16a_physical.m` and `F16APhysicalArchitectureTest.m` each hold their own copy of the same 16 figures, so the test verifies a transcription. Have the test execute `BrandtWeight.m` instead. **Land `PhysicalItem.DataProvenance` in the same stage** (see below). | D-036 | `f16a-vnv` · `f16a-data` |
| 2 | **Only one engine candidate is real.** Give `TradeCandidate` a `T_SL_lb`; source the F-16's own engine from Brandt and make the other two declared hypotheticals with invented thrusts — one short of the T/W it needs, one with far more than it needs and heavier for it. Rename `F110_GE_100`, which wears a real designation over invented data. | new | `f16a-physical` · `f16a-data` |
| 3 | **`F16APhysicalCostModel` is a stub.** Real DAPCA-IV flyaway estimate populating `MeasureOfMerit.UnitCost_USD` on `Aircraft`; candidates keep `NaN` forever. Move the cost write after the generator's section 9 — OEW does not exist in section 8. | D-043 | `f16a-physical` · `f16a-data` |

**Item 1 carries a second half.** `PhysicalItem` declares `{ Mass_lb }` and no `DataProvenance`, so 14
of the 16 masses summing to OEW carry no provenance — and six of them carry
`Material.DataProvenance = Estimate`, which describes their *composite fraction* while their mass is
`Reference`. A reader inspecting `Fuselage` sees a **contradicting** tag, not a missing one. Give
`PhysicalItem` its **own** `DataProvenance` (do not overload `Material`'s) and have the gate check that
no leaf carries two provenance tags that disagree.

**Item 2 is scoped.** `T_SL_lb` is a declared property, **not a trade criterion and not a screen** —
scoring stays `Benefit`/`TRL`/`Mass_lb`/`UnitCost_USD` and the outcome must not move. **No T/W ratio is
computed anywhere**, in the model, a test or the docs: the three thrusts sit side by side and the
narrative says what they mean. The twin's extra cost stays qualitative, because
`TradeCandidate.UnitCost_USD` is `NaN` forever.

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
