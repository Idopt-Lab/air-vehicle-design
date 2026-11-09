# Decision log

> The decisions that still have an effect on the model. Each entry tells what was decided and why.
> Ids do not change. The end of this file lists each retired id and where it went. Add an entry only
> if, without it, a future reader would have to reverse-engineer the decision. **D-030 lists every
> invented number.**

## Layers and options

**D-001 · L gives options. P decides.** L holds technology-neutral kinds with no numbers. P holds
parameterized candidates, runs the trade, and writes the winning kind back to L. *Why:* a role has
no mass, so to score at L you would have to invent numbers.

**D-002 · Candidates are variant choices in the model, and losers stay.** *Why:* the rejected
options must stay visible and auditable. The `Rationale` of a losing candidate is the only record
of why it lost.

**D-003 · Give details only of the winner.** The selected airframe carries the Brandt
decomposition. Losing candidates are lumped blocks. *Why:* symmetry would need invented masses for
aircraft that were never built.

**D-004 · A trade is flat across all candidates of a role.** All candidates are scored in one pass.
The kind of the winner becomes the selected option. *Why:* with selection in two stages, a kind
could win before its candidates were compared.

**D-009 · All engine candidates share `InletDuct`.** *Why:* to add an inlet difference to the cost
of the twin surrogate would invent a number. The simplification is stated, not hidden.

**D-016 · Each variation point is decided independently.** This is a stated simplification. The
choices do interact (relaxed stability gives a benefit only with fly-by-wire). A search of the
2×2×2 box is an exercise.

**D-017 · "Technology-neutral", not "solution-agnostic".** `SingleEngine` is an architectural
commitment. It has no technology and no vendor in it. Strict solution independence is the job of
the F layer.

**D-018 · The word "MDAO" is not used in the code.** A weighted sum over discrete candidates is a
trade study. `06_methodology.md` cites the MDO literature as the pattern that the example follows.

**D-020 · Kinds have topology names.** The name of a kind has no digits, vendors or products
(`SingleEngine`, not `SingleEngine_F100`).

**D-059 · The mission is an activity diagram.** Ten actions are on a typed `FlightState` flow.
Combat holds the F2T2EA kill chain as a child activity. The capabilities stay a component tree. The
behaviour of each phase is `F16AMissionSegment('<phase>')`, which reads `/sizing/` `BrandtMission`.
*Why:* a mission is behaviour, and as components, the phases could not be allocated. The kill-chain
edges need their own F→L allocation set, because a set binds to one source model.

**D-064 · L and P have no ports and no interface dictionaries.** *Why:* the example teaches
allocation and trades, not data flow. The interfaces of L and P never agreed, and no decision
explained them. F keeps `F16A_Functional.sldd` for the typed flows of the activity.

**D-065 · A candidate is allocated from the kind that it realizes.** The L→P set holds 7
kind→candidate edges plus 7 role→part edges (14). `F16AKindOf` reads the kind of a candidate from
that edge. *Supersedes D-024 (role→candidate edges) and the `RealizesKind` property of D-027.*
*Why:* the relationship becomes a model artifact that a student can see in the allocation editor,
not a string.

**D-066 · Mission phases are not allocated to capabilities.** The 59-edge phase→capability set is
deleted. *Amends D-059.* *Why:* almost every phase uses lift, thrust and fuel. Thus the matrix was
almost full and gave almost no information. This is the argument that D-059 itself gives against
phase→role edges.

## Trade studies

**D-015 · Scoring uses value functions declared before the trade.** `B/10`, `(TRL−1)/8`, `M_ref/M`,
`T/T_ref`. Each trade declares weights with a sum of 1 (table in `05_physical.md`). *Why:* min–max
normalization is degenerate with two candidates, and the arrival of one candidate can change the
order of the others.

**D-021 · Unset parameters fail safe.** `TRL` and benefit have the default value 0. Both values are
off the scale, so the trade stops. Cost Measures of Merit have the default value `NaN`, never `0`.
*Why:* a stop is better than a plausible default. `$0` could not be beaten.

**D-027 · `DecisionRef` is written on each kind, winner and loser.** *Why:* if not, a rejected kind
is a `'TBD'` dead end. (D-065 supersedes its `RealizesKind` half.)

**D-028 · Decision links are made again on each run.** The trade removes the old links from L into
the decision requirement, and then links the winner. *Why:* if the winner changes, the old winner
must not still claim the decision. Verify links come from tests, so the trade does not touch them.

**D-033 · A benefit has limits at both ends (1–10).** *Why:* a typing error of `65` for `6.5` is
finite, passes an `isfinite` check, and would silently change the decision.

**D-034 · "Decided by" is measured against the runner-up, and the text says so.** The same win has
a different deciding criterion against a different rival. A measure that is independent of the rival
is an exercise.

**D-035 · Ratio value functions have no upper limit. Give a warning, do not cap.**
`TwinEngine_Surrogate` has `v = 1.346` on thrust, so each engine run gives a warning. A cap
discards information. An error rejects a legitimate candidate. To put limits on the functions is an
exercise.

**D-037 · A decision requirement states the question and contains no answer.** `REQ_F16A_L01`–`L03`
contain no vendor, weight, score or winner. *Why:* a requirement that contains its answer is a
claim, not a record.

**D-040 · The verdict is where it is computed.** It is in `Rationale.Justification` of the winning
candidate at P, and in the Implement link from the winning kind. *Why:* a P script that writes into
an R artifact mixes ownership. The active flag stays derived.

**D-049 · A click on a rejected kind leads somewhere.** Rejected kind → `DecisionRef` → the decision
requirement → the rejected candidate. The `TradeAlternative` justification of that candidate states
its deficit. The last step is a name match, not a link.

**D-050 · Programme history is in the docs, labelled as history.** The Lightweight Fighter story is
in `04_logical.md`. It is never in a requirement, kind name or rationale. No criterion reads a name.

**D-053 · One engine is real. Two are declared hypothetical candidates.** `F100_PW_200` keeps its
name, because its mass and thrust are Brandt reference figures. `LowThrustSingle_Surrogate` and
`TwinEngine_Surrogate` have invented numbers, and their names say so. No thrust-to-weight ratio is
computed in the example.

**D-056 · One trade for each decision, each with its own candidate stereotype.** `EngineCandidate`,
`AirframeCandidate` and `FlightControlCandidate` each declare only the criteria that their trade
scores. No candidate carries a cost (D-043).

**D-067 · The trades share their bookkeeping.** *Amends D-056.* Each trade keeps its criteria table
and steps 1–4 in its own file. `F16ARecordTradeDecision` records the decision (steps 5–6), and
`F16AKindOf` finds the kind. *Why:* the three files were 87% identical. A student must read the
criteria and the scoring, not three copies of the bookkeeping.

## Physical data and analyses

**D-006 · Each part carries a `Rationale` that you can query.** `SourceKind`, `Justification`,
`TraceRef`. *Why:* the model, not the comments, must answer "why does this part exist?".

**D-007 · Each value-bearing stereotype carries `DataProvenance`.** `Reference`, `Datasheet`,
`Simulation` or `Estimate`. D-030 lists each `Estimate`. This applies to `Material` (D-031) and to
`PhysicalItem`. The default of `PhysicalItem` is `Simulation`, because interior nodes are computed
(D-052).

**D-011 · Stereotype vocabularies are real MATLAB enumerations.** `F16ASourceKind` and
`F16ADataProvenance`. *Why:* they are validated, and they show as a dropdown, not as a free string.

**D-012 · Roll-ups count only the active candidates.** The analysis instance holds only active
choices. A walk on the architecture must follow `getActiveChoice`. *Why:* if not, rejected
candidates add their mass.

**D-013 · Variant wrappers carry no part stereotypes.** A wrapper is the question "which of these?",
not a part. (Also, `applyStereotype` gives an error on a wrapper.)

**D-023 · The fuel split is an `Estimate`.** Three 2,100 lb tanks (6,300 lb), against 6,296.30 lb in
Brandt.

**D-025 · `DataProvenance` qualifies the mass, not the judgement.** Benefit and `TRL` are opinions
on a declared scale, also on a `Reference` candidate.

**D-029 · Analyses can run without writing.** `F16APhysicalMassRollup(Persist=false)` and
`<Trade>(Record=false)`. *Why:* a test that writes to the model that it checks can hide the defect
that it must find.

**D-041 · Fuel is rolled up by weight only.** `/sizing/` has no fuel density. Thus a volume would be
an invented number that nothing uses.

**D-043 · Cost is a Measure of Merit of the full aircraft.** `F16APhysicalCostModel` calls
`BrandtCost` with the OEW and mission of this model, tagged `Simulation`. The Brandt value of
≈ $68.4M is the cross-check. *Why:* DAPCA IV can calculate the price of an aircraft, not of a wing
candidate.

**D-047 · `REQ_F16A_025` is verified by a call to `/sizing/`.** `x_np`, `x_cg` and `MAC` are not
properties of a part. Thus the evidence is in the balance analysis. Path guards restore the path
after the call.

**D-054 · A `NaN` is never reported as a violation.** A value that is missing or cannot be read
stops the run, or is reported as *unevaluated*. It is never reported as *not met*.

**D-057 · Roll-ups read as printed steps.** Each roll-up is in its own file, with its own walk. It
prints each number that it reads and adds.

**D-058 · The mass roll-up adds one time,** over the analysis instance, with no second walk and no
`iterate`.

**D-061 · O&M and life-cycle cost are Measures of Merit.** The real mission drives them. The flyaway
cost does not depend on the mission, and it did not change. `REQ_F16A_P02` states life-cycle cost
with no upper limit, because no sourced target exists.

## Requirements and verification

**D-045 · `REQ_F16A_D01`–`D09` stay a student exercise.** No external source defines their
criteria. Thus to write a criterion would invent a requirement.

**D-046 · The gear angles `023`/`024` are a student exercise.** The angle conventions of Brandt
possibly do not agree with the conventions of the specifications, and the same number gives
opposite verdicts. The brief is in `01_requirements.md`.

**D-051 · The static margin must be negative, and the reference model fails at landing.**
−6 %MAC ≤ SM < 0 at both ends of the CG range. SM is −0.26 %MAC at takeoff and +0.21 %MAC at
landing. *Why:* the example needs a requirement that is evaluated and **not met**. The red comes
from the simplified neutral point of Brandt, not from the F-16A.

**D-060 · `REQ_F16A_P01` has an answer.** 6,300 lb of tankage against 5,959.80 lb of mission fuel.
*Cost:* the example no longer ships an *unevaluated* requirement. One red is now the expected state.

**D-062 · The models are the source of truth. The generators are retired.** Models, requirement
sets and allocation sets are edited directly. `F16ARunAnalyses` computes each derived number again.
*Why:* models can now be edited directly, and 2,500 lines of build scripts were between a student
and the model. Rule: never build a model again, because SIDs anchor the allocations and Verify
links.

**D-063 · Regression tests check numbers, not machinery.** `F16ABaselineTest` checks each trade
score, ranking and active choice, OEW, composite fraction, fuel, mission, costs, and the stored
Measures of Merit. *Replaces* the six structural suites. *Given up:* the leaf-mass cross-check
against `BrandtWeight`. That check found that the OEW of the model is 3.12 lb more than the Brandt
`.m` value (19,980.73 vs 19,977.61 lb). The cause: in the nacelle and inlet-duct weights, the `.m`
uses π, and the spreadsheet uses 3.1516. This difference is the reason that the cost is
approximately $7k different from the Brandt cost.

## D-030 · Inventory of every invented number

Each value below was **invented for teaching**. None of them is F-16 data. Do not cite any of them
as F-16 data.

| Value | Where | Property | Why this number |
|---|---|---|---|
| 7300 lb | `ConventionalTrapWing` | `Mass_lb` | no such aircraft was built. A discrete wing-body is assumed to be ~8.6% heavier |
| 5100 lb | `LowThrustSingle_Surrogate` | `Mass_lb` | a hypothetical engine, invented so that it loses |
| 6400 lb | `TwinEngine_Surrogate` | `Mass_lb` | represents a twin installation of the YF-17 class |
| 700 lb | `HydroMechanical` | `Mass_lb` | a mechanical control system, assumed to be heavier than fly-by-wire |
| 18,500 lb | `LowThrustSingle_Surrogate` | `Thrust_SL_lb` | chosen to be clearly less than a 31,377 lb aircraft needs |
| 32,000 lb | `TwinEngine_Surrogate` | `Thrust_SL_lb` | chosen to be clearly more. It is above the ceiling of D-035 (`v = 1.346`) |
| 0.12 | `ConventionalTrapWing` | `CompositeFraction` | mostly aluminium airframe |
| 0.15 / 0.10 / 0.55 / 0.70 / 0.05 / 0.50 | Wing / Fuselage / HorizontalTail / VerticalTail / Nacelles / Strakes | `CompositeFraction` | approximately based on real F-16 composite use, **adjusted to give a result below the 20% cap** |
| 9.5 / 6.5 | the two airframes | `AeroBenefit` | judgement on a 1–10 scale. Only the order has a meaning |
| 9.0 / 6.0 | the two flight-control systems | `HandlingBenefit` | judgement on a 1–10 scale |
| 7 / 8 · 6 / 9 · 8 / 4 / 6 | airframes · flight controls · engines | `TRL` | judgement on a 1–9 scale. The 4 of the surrogate makes the mature engine win |
| 3 × 2100 lb | the fuel tanks | `FuelCapacity_lb` | an equal split of a rounded figure (D-023) |
| −6 %MAC | `REQ_F16A_025` | requirement floor | frequently repeated for the F-16, but uncited. The strict 0 upper bound is a definition |

The 23,770 lbf thrust of the F100 and the Brandt masses are `Reference` values, so they are not in
this list. The judgement values trace to nothing, and for this reason they must be recorded. In the
airframe and flight-control trades, 0.75 of each score is judgement. In the engine trade, 0.35 is
judgement.

## Retired ids

| Ids | Where they went |
|---|---|
| D-005, D-026, D-032 | cost and criterion handling, now D-021, D-043, D-056 |
| D-008, D-022, D-039 | renames and moves of docs. History only |
| D-010, D-019, D-036, D-038, D-055 | rules for generators and machinery tests, retired by D-062 and D-063 |
| D-014 | the agent team, retired with the generators |
| D-024 | role→candidate realization, superseded by D-065 |
| D-031, D-052 | merged into D-007 |
| D-042 | superseded by D-060 |
| D-044, D-048 | superseded by D-046 and D-051 |
