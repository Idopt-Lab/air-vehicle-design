# Decision log

> The decisions that still shape the model, each with what was decided and why. Ids are stable; a
> retired id is listed at the end with where it went. Add an entry only when a future reader would
> otherwise have to reverse-engineer the decision. **D-030 lists every invented number.**

## Layers and options

**D-001 · L presents options; P decides.** L holds technology-neutral kinds with no numbers; P holds
parameterized candidates, runs the trade, and writes the winning kind back to L. *Why:* a role has no
mass, so scoring at L means inventing numbers.

**D-002 · Candidates are in-model variant choices, and losers stay.** *Why:* the rejected options must
remain visible and auditable; a losing candidate's `Rationale` is the only record of why it lost.

**D-003 · Detail only the winner.** The selected airframe carries the Brandt decomposition; losing
candidates are lumped blocks. *Why:* symmetry would mean inventing masses for aircraft never built.

**D-004 · A trade is flat across all candidates of a role.** All are scored in one pass; the winner's
kind becomes the selected option. *Why:* two-stage selection would let a kind win before its
candidates were compared.

**D-009 · `InletDuct` is shared by every engine candidate.** *Why:* pricing an inlet difference into
the twin surrogate would invent a number. The simplification is stated, not hidden.

**D-016 · Each variation point is decided independently** — a stated simplification. The choices do
interact (relaxed stability pays off only with fly-by-wire); searching the 2×2×2 box is an exercise.

**D-017 · "Technology-neutral", not "solution-agnostic".** `SingleEngine` is an architectural
commitment; it is free of technology and vendor. Strict solution independence is the F layer's job.

**D-018 · The word "MDAO" stays out of the code.** A weighted sum over discrete candidates is a trade
study. The MDO literature is cited as the pattern followed, in `06_methodology.md`.

**D-020 · Kinds are named for topology.** No digits, vendors or products in a kind's name
(`SingleEngine`, not `SingleEngine_F100`).

**D-059 · The mission is an activity diagram.** Ten actions on a typed `FlightState` flow, Combat
holding the F2T2EA kill chain as a child activity; capabilities stay a component tree. Each phase's
behaviour is `F16AMissionSegment('<phase>')`, which reads `/sizing/` `BrandtMission`. *Why:* a
mission is behaviour, and as components the phases could not be allocated. The kill-chain edges
need their own F→L allocation set, because a set binds to one source model.

**D-064 · L and P carry no ports and no interface dictionaries.** *Why:* the example teaches
allocation and trades, not data flow. L and P's interfaces were never aligned, and no decision
explained them. F keeps `F16A_Functional.sldd` for the activity's typed flows.

**D-065 · A candidate is allocated from the kind it realizes.** The L→P set holds 7 kind→candidate
edges plus 7 role→part edges (14). `F16AKindOf` reads a candidate's kind from that edge.
*Supersedes D-024 (role→candidate edges) and the `RealizesKind` property of D-027.* *Why:* the
relationship becomes a model artifact a student can see in the allocation editor, instead of a
string.

**D-066 · Mission phases are not allocated to capabilities.** The 59-edge phase→capability set is
deleted. *Amends D-059.* *Why:* nearly every phase uses lift, thrust and fuel, so the matrix was
nearly full and said almost nothing, which is D-059's own argument against phase→role edges.

## Trade studies

**D-015 · Scoring uses value functions declared in advance.** `B/10`, `(TRL−1)/8`, `M_ref/M`,
`T/T_ref`; each trade declares weights that sum to 1 (table in `05_physical.md`). *Why:* min–max
normalization is degenerate at two candidates, and lets one candidate's arrival reorder the others.

**D-021 · Unset parameters fail safe.** `TRL` defaults to 0 and benefit to 0, both off-scale, so the
trade stops. Cost Measures of Merit default to `NaN`, never `0`. *Why:* a plausible default is worse
than a stop; `$0` would be unbeatable.

**D-027 · `DecisionRef` is written on every kind, winner and loser.** *Why:* otherwise a rejected kind
is a `'TBD'` dead end. (Its `RealizesKind` half is superseded by D-065.)

**D-028 · Decision links are rebuilt on every run.** The trade removes L's old links into the decision
requirement, then links the winner. *Why:* if the winner changes, the old one must not still claim
the decision. Verify links come from tests, so they are untouched.

**D-033 · A benefit is bounded at both ends (1–10).** *Why:* `65` typed for `6.5` is finite, passes an
`isfinite` check, and would flip the decision silently.

**D-034 · "Decided by" is measured against the runner-up, and says so.** The same victory has a
different deciding criterion against a different rival. A rival-independent measure is an exercise.

**D-035 · Ratio value functions are unbounded; warn, do not cap.** `TwinEngine_Surrogate` scores
`v = 1.346` on thrust, so every engine run warns. Capping discards information; erroring rejects a
legitimate candidate. Bounding the functions is an exercise.

**D-037 · A decision requirement poses the question and contains no answer.** No vendor, weight,
score or winner in `REQ_F16A_L01`–`L03`. *Why:* a requirement that contains its answer is a claim, not
a record.

**D-040 · The verdict lives where it is computed.** In the winning candidate's
`Rationale.Justification` at P, plus the Implement link from the winning kind. *Why:* a P script
writing into an R artifact mixes ownership; the active flag stays derived.

**D-049 · Clicking a rejected kind leads somewhere.** Rejected kind → `DecisionRef` → the decision
requirement → the rejected candidate, whose `TradeAlternative` justification states its deficit. The
last hop is a name match, not a link.

**D-050 · Programme history lives in the docs, labelled history.** The Lightweight Fighter story is
in `04_logical.md`, never in a requirement, kind name or rationale. No criterion reads a name.

**D-053 · One engine is real; two are declared hypotheticals.** `F100_PW_200` keeps its name because
its mass and thrust are Brandt reference figures. `LowThrustSingle_Surrogate` and
`TwinEngine_Surrogate` have invented numbers and names that say so. No thrust-to-weight ratio is
computed anywhere.

**D-056 · One trade per decision, each with its own candidate stereotype.** `EngineCandidate`,
`AirframeCandidate` and `FlightControlCandidate` each declare only the criteria their trade scores.
No candidate carries a cost (D-043).

**D-067 · The trades share their bookkeeping.** *Amends D-056.* Each trade keeps its criteria table
and steps 1–4 inline; recording the decision (steps 5–6) is `F16ARecordTradeDecision`, and the
kind lookup is `F16AKindOf`. *Why:* the three files were 87% identical. A student needs to read the
criteria and the scoring, not three copies of the bookkeeping.

## Physical data and analyses

**D-006 · Every part carries a queryable `Rationale`.** `SourceKind`, `Justification`, `TraceRef`.
*Why:* "why does this part exist?" should be answerable from the model, not from comments.

**D-007 · Every value-bearing stereotype carries `DataProvenance`.** `Reference`, `Datasheet`,
`Simulation` or `Estimate`; every `Estimate` is listed in D-030. This applies to `Material` (D-031)
and to `PhysicalItem`, whose default is `Simulation` because interior nodes are computed (D-052).

**D-011 · Stereotype vocabularies are real MATLAB enumerations.** `F16ASourceKind` and
`F16ADataProvenance`. *Why:* they are validated, and appear as a dropdown instead of a free string.

**D-012 · Roll-ups count only the active candidates.** The analysis instance holds only active
choices; an architecture-side walk must follow `getActiveChoice`. *Why:* otherwise rejected
candidates add their mass.

**D-013 · Variant wrappers carry no part stereotypes.** A wrapper is the question "which of these?",
not a part. (`applyStereotype` errors on one anyway.)

**D-023 · The fuel split is an `Estimate`.** Three 2,100 lb tanks (6,300 lb) against Brandt's
6,296.30 lb.

**D-025 · `DataProvenance` qualifies the mass, not the judgement.** Benefit and `TRL` are opinion on a
declared scale, even on a `Reference` candidate.

**D-029 · Analyses can run without writing.** `F16APhysicalMassRollup(Persist=false)` and
`<Trade>(Record=false)`. *Why:* a test that writes to the model it checks can mask the defect it
should catch.

**D-041 · Fuel is rolled up by weight only.** `/sizing/` has no fuel density, so a volume would be an
invented number that nothing consumes.

**D-043 · Cost is a whole-aircraft Measure of Merit.** `F16APhysicalCostModel` calls `BrandtCost`
with this model's OEW and mission, tagged `Simulation`. Brandt's ≈ $68.4M is the cross-check. *Why:*
DAPCA IV can price an aircraft, not a wing candidate.

**D-047 · `REQ_F16A_025` is verified by calling `/sizing/`.** None of `x_np`, `x_cg` or `MAC` is a
property of a part, so the evidence lives in the balance analysis. Path guards put the path back
afterwards.

**D-054 · A `NaN` is never reported as a violation.** An unreadable or missing value stops the run
or reports *unevaluated*, never *not met*.

**D-057 · Roll-ups read as printed steps,** each in its own file with its own walk, printing every
number it reads and adds.

**D-058 · The mass roll-up sums once,** over the analysis instance, with no second walk and no
`iterate`.

**D-061 · O&M and life-cycle cost are Measures of Merit.** Driven by the real mission; the flyaway
cost does not depend on the mission and did not move. `REQ_F16A_P02` poses life-cycle cost with no
ceiling, because no sourced target exists.

## Requirements and verification

**D-045 · `REQ_F16A_D01`–`D09` stay a student exercise.** No external source defines their criteria,
so writing one would invent a requirement.

**D-046 · The gear angles `023`/`024` are a student exercise.** Brandt's angle conventions may not
match the specifications', and the same number gives opposite verdicts. The brief is in
`01_requirements.md`.

**D-051 · The static margin must be negative, and the reference model fails it at landing.**
−6 %MAC ≤ SM < 0 at both ends of the CG range; SM is −0.26 %MAC at takeoff and +0.21 %MAC at
landing. *Why:* the example needs a requirement that is evaluated and **not met**. The red is a
property of Brandt's simplified neutral point, not of the F-16A.

**D-060 · `REQ_F16A_P01` is answered.** 6,300 lb of tankage against 5,959.80 lb of mission fuel.
*Cost:* the example no longer ships an *unevaluated* requirement; one red is now the expected state.

**D-062 · The models are the source of truth; the generators are retired.** Models, requirement sets
and allocation sets are edited directly, and `F16ARunAnalyses` recomputes every derived number.
*Why:* models can now be edited directly, and 2,500 lines of build scripts stood between a student
and the model. Rule: never rebuild a model, because SIDs anchor the allocations and Verify links.

**D-063 · Regression tests pin numbers, not machinery.** `F16ABaselineTest` checks every trade
score, ranking and active choice, OEW, composite fraction, fuel, mission, costs, and the stored
Measures of Merit. *Replaces* the six structural suites. *Given up:* the leaf-mass cross-check
against `BrandtWeight`, which found the model's OEW 3.12 lb above Brandt's `.m` (19,980.73 vs
19,977.61 lb: the `.m` uses π where the spreadsheet uses 3.1516 in the nacelle and inlet-duct
weights). That gap is why the cost differs from Brandt's by about $7k.

## D-030 · Inventory of every invented number

Every value below was **invented for teaching**. None is F-16 data, and none should be cited as such.

| Value | Where | Property | Why this number |
|---|---|---|---|
| 7300 lb | `ConventionalTrapWing` | `Mass_lb` | no such aircraft built; a discrete wing-body assumed ~8.6% heavier |
| 5100 lb | `LowThrustSingle_Surrogate` | `Mass_lb` | a hypothetical engine, invented so it loses |
| 6400 lb | `TwinEngine_Surrogate` | `Mass_lb` | stands in for a twin installation of the YF-17 class |
| 700 lb | `HydroMechanical` | `Mass_lb` | a mechanical control system, assumed heavier than fly-by-wire |
| 18,500 lb | `LowThrustSingle_Surrogate` | `Thrust_SL_lb` | chosen visibly below what a 31,377 lb aircraft needs |
| 32,000 lb | `TwinEngine_Surrogate` | `Thrust_SL_lb` | chosen visibly above; breaches D-035's ceiling (`v = 1.346`) |
| 0.12 | `ConventionalTrapWing` | `CompositeFraction` | aluminium-dominant airframe |
| 0.15 / 0.10 / 0.55 / 0.70 / 0.05 / 0.50 | Wing / Fuselage / HorizontalTail / VerticalTail / Nacelles / Strakes | `CompositeFraction` | loosely based on real F-16 composite use, **tuned to land under the 20% cap** |
| 9.5 / 6.5 | the two airframes | `AeroBenefit` | judgement on a 1–10 scale; only the ordering means anything |
| 9.0 / 6.0 | the two flight-control systems | `HandlingBenefit` | judgement on a 1–10 scale |
| 7 / 8 · 6 / 9 · 8 / 4 / 6 | airframes · flight controls · engines | `TRL` | judgement on a 1–9 scale; the surrogate's 4 makes the mature engine win |
| 3 × 2100 lb | the fuel tanks | `FuelCapacity_lb` | an even split of a rounded figure (D-023) |
| −6 %MAC | `REQ_F16A_025` | requirement floor | commonly repeated for the F-16 but uncited; the strict 0 upper bound is a definition |

The F100's 23,770 lbf thrust and the Brandt masses are `Reference` and are not listed. The
judgement values trace to nothing, which is why they must be recorded. Of each score, 0.75 is
judgement in the airframe and flight-control trades, and 0.35 in the engine trade.

## Retired ids

| Ids | Where they went |
|---|---|
| D-005, D-026, D-032 | cost and criterion handling, now D-021, D-043, D-056 |
| D-008, D-022, D-039 | renames and doc moves; history only |
| D-010, D-019, D-036, D-038, D-055 | generator and machinery-test rules, retired by D-062 and D-063 |
| D-014 | the agent team, retired with the generators |
| D-024 | role→candidate realization, superseded by D-065 |
| D-031, D-052 | merged into D-007 |
| D-042 | superseded by D-060 |
| D-044, D-048 | superseded by D-046 and D-051 |
