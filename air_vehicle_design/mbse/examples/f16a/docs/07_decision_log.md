# Decision log

> Append-only. One entry per decision, including decisions *not* to do something.
> Owner: `f16a-scribe`. Audited by `f16a-data` (every invented number must appear here).
> See [`08_agent_team.md`](08_agent_team.md) for who is who, [`06_methodology.md`](06_methodology.md)
> for the literature grounding.

---

### D-001 · The Logical layer presents options; the Physical layer decides
**Stage** 0 · **Decided by** user + f16a-mbse-method · **Date** 2026-07-28
**Decision** L presents technology-neutral architectural *kinds* with no numbers and no winner. P
holds concrete parameterized candidates, runs the trade study, decides, and calls back to set the
active kind at L.
**Alternatives considered** Keep the trade at L (the previous design). Rejected: it forces
technology-specific numbers onto the logical architecture, which the method literature requires to
be solution-independent — the L model was answering a question it cannot legitimately answer yet.
**Consequences** `logical/F16ALogicalTradeStudy.m` retires; a new `physical/F16APhysicalTradeStudy.m`
owns scoring, selection and the cross-layer callback; L ships *unresolved* until P has run.
**Traces to** `docs/06_methodology.md` · `REQ_F16A_L01`–`L03`

### D-002 · Candidates are modelled as in-model variant choices
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** Each physical candidate is a stereotyped variant choice inside the Physical model,
rather than an external table of options.
**Alternatives considered** A candidate table in a `.m`/`.xlsx` scored outside the model. Rejected:
the losing alternatives would leave no trace in the architecture, and the point of the exercise is
that the options remain visible and auditable in the model.
**Consequences** The trade study is a pure model query; alternatives stay in the model as the
options that were traded.

### D-003 · Variant depth: wrap the role, detail only the winner
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** `Airframe`, `Propulsion/Engine` and `FlightControls` become variant components. The
winning candidate carries the existing Brandt decomposition; losing candidates are single lumped
blocks with `Estimate`-tagged masses.
**Alternatives considered** (a) Propulsion-only showcase — too little of the lesson; (b) full
symmetry, both airframe candidates fully decomposed — would require inventing six part masses and
six composite fractions for an aircraft that was never built.
**Consequences** 23 → 30 components. Architecture paths gain a choice level
(`…/Airframe/BlendedCrankedDelta/Wing`). Active-configuration OEW is unchanged at 19,980.73 lb.
Asymmetric detail is itself honest: you only decompose what you selected.

### D-004 · The trade is flat across all candidates of a role
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** All candidates for a role are scored in one pass; the global best wins and its
`RealizesKind` becomes the selected logical option.
**Alternatives considered** Two-stage (pick a kind, then pick within the kind). Rejected as
premature hierarchy — it would let a kind win before its candidates were compared.

### D-005 · Cost stays NaN and is excluded from scoring
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** `UnitCost_USD` exists on candidates and on the aircraft Measure of Merit, is `NaN`, and
is dropped from the weighted score with the remaining weights renormalized.
**Alternatives considered** Implement a DAPCA-IV cost model now; or use illustrative cost numbers.
Rejected: inventing cost figures would teach the wrong lesson, and a real cost model is a separate
piece of work. A visible `NaN` is an honest "pending Measure of Merit".
**Consequences** Weights become `Benefit 0.50 · TRL 0.25 · Mass_lb 0.25`. The trade study logs that
cost was dropped. `physical/F16APhysicalCostModel.m` stays a stub.
**Traces to** `REQ_F16A_026`

### D-006 · Every physical part carries a queryable Rationale
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** A `Rationale` stereotype (`SourceKind`, `Justification`, `TraceRef`) is applied to every
physical component, including the four that realize no logical role.
**Alternatives considered** Leave the justification in code comments (today's state). Rejected:
a comment is not queryable, and "why does this part exist?" is exactly the question MBSE traceability
is supposed to answer.
**Consequences** Vocabulary: `RealizesFunction | SatisfiesRequirement | TradeWinner |
TradeAlternative | ConstraintDriven | SupportingInfrastructure`. `TradeAlternative` was added to the
original five so a losing candidate can state what it is.

### D-007 · Every candidate parameter set carries a DataProvenance tag
**Stage** 0 · **Decided by** user + f16a-data · **Date** 2026-07-28
**Decision** `DataProvenance ∈ {Datasheet, Reference, Estimate, Simulation}` on every candidate.
Illustrative teaching numbers are allowed only as `Estimate`, and every `Estimate` is listed in this
log.
**Consequences** `f16a-data` holds a veto at every gate. Every `Estimate` is recorded in the
decision-log entry for the stage that introduced it.

### D-008 · The logical profile is renamed to reflect that L no longer trades
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** `logical/F16A_LogicalTrades.xml` → `logical/F16A_LogicalOptions.xml`, stereotype
`TradeCandidate` → `SolutionOption { Selected, DecisionRef }`.
**Alternatives considered** Keep the filename to avoid churn. Rejected: a profile called *Trades* in
a layer that must not trade is exactly the confusion this restructure is removing.

### D-009 · The inlet duct is common to all engine candidates
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** `InletDuct` stays a plain part beside the `Engine` variant, shared by all engine
candidates; the twin-engine surrogate's estimated mass is **not** adjusted to absorb an inlet delta.
**Alternatives considered** Duplicate the inlet inside each candidate (triples a part for no lesson);
or price the delta into the surrogate (invents a number we cannot defend).
**Consequences** A real twin-engine installation would change the inlet. This simplification is
stated in `docs/05_physical.md` rather than hidden in a mass number.

### D-010 · The L01–L03 link assertion moves from the L test to the P test
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** `F16ALogicalArchitectureTest` no longer asserts that the decision requirements are
linked; `F16APhysicalArchitectureTest` does.
**Rationale** The links are now created by the physical trade study. Asserting them at L would make
the L suite depend on whether P has been run, breaking layer independence.
**Consequences** The L suite asserts only: kinds exist, are vendor-free, carry no trade numerics, and
exactly one choice is active per role.

### D-011 · Stereotype properties use real MATLAB enumerations
**Stage** 0 · **Decided by** f16a-physical (probe) · **Date** 2026-07-28
**Decision** `DataProvenance` and `SourceKind` are enumeration-typed properties, not free strings.
**Evidence** Stage-0 probe: `addProperty(…, Type="<enum class>")` accepted both an `int32`-derived
and a plain MATLAB `enumeration` class in R2026a.
**Consequences** Two small `classdef` files must sit on the project path; the payoff is a validated
vocabulary and a dropdown in the Property Inspector instead of typo-prone strings.

### D-012 · The native roll-up needs no "active" filter; hand recursions do
**Stage** 0 · **Decided by** f16a-physical (probe) · **Date** 2026-07-28
**Decision** Leave the native `instantiate`/`iterate` mass roll-up as a plain postorder sum. Fix the
*architecture-side* recursions (the roll-up's fallback path, the materials roll-up) to descend into
`getActiveChoice(vc)` when they meet a variant component.
**Evidence** Stage-0 probe: the analysis instance contains only the active choice — an inactive
choice's path is unresolvable in the instance — while an architecture-side walk sees every choice
and would double-count.
**Consequences** Avoids importing the `ex2` `Active`-flag pattern that the plan had assumed would be
necessary. Also: the instance **flattens** the variant (the choice node is elided), so instance paths
keep their pre-restructure shape while architecture paths gain the choice level.

### D-013 · Variant role wrappers are exempt from part stereotypes
**Stage** 0 · **Decided by** f16a-physical (probe) · **Date** 2026-07-28
**Decision** `PhysicalItem` and `Rationale` are applied to variant *choices* and plain components,
not to the variant component itself; "every part has a rationale" means every part that can carry
one.
**Evidence** Stage-0 probe: `applyStereotype` errors on `systemcomposer.arch.VariantComponent`.
**Consequences** The variant node still reports a rolled-up mass in the analysis instance, so the
roll-up is unaffected. The role wrapper's justification lives in its candidates.

### D-014 · The example is maintained by a specialist agent team with approval gates
**Stage** 0 · **Decided by** user · **Date** 2026-07-28
**Decision** Nine roles (orchestrator, R/F/L/P owners, V&V, data, scribe, methodologist), defined in
`.claude/agents/f16a-*.md`, working in staged increments with a human approval gate at the end of
every stage and one commit per stage.
**Consequences** V&V is separated from implementation so a generator and its test cannot be wrong the
same way; the data agent can veto any number; see [`08_agent_team.md`](08_agent_team.md).

### D-015 · Scoring uses declared value functions, not min–max normalization
**Stage** 0 · **Decided by** f16a-mbse-method (referee finding) + orchestrator · **Date** 2026-07-28
**Problem found** Min–max normalization across the candidates of a role is **degenerate at n = 2**:
every criterion normalizes to {0, 1}, so a score is just the sum of the weights a candidate wins.
That is why every winner in the old `04_logical.md` scores exactly 0.60 and every loser 0.40 — the
margin carries no information. It is also **set-dependent**: adding a candidate silently rescores
the others (rank reversal).
**Decision** Each criterion gets a **declared value function**, independent of which candidates are
in the set:

| Criterion | Value function | Scale it declares |
|---|---|---|
| `Benefit` | `v = B / 10` | benefit stated on a 0–10 scale |
| `TRL` | `v = (TRL − 1) / 8` | TRL 1–9 |
| `Mass_lb` | `v = M_baseline / M` | ratio to the role's Brandt baseline mass; `v > 1` means lighter than the as-built F-16A |
| `UnitCost_USD` | — | `NaN`, dropped (D-005) |

Weights `Benefit 0.50 · TRL 0.25 · Mass 0.25`. Baselines are `Reference`-tagged Brandt figures:
Propulsion 4730.23 lb, Airframe 6722.88 lb, FlightControls 472.44 lb.
**Expected scores** Propulsion `F100 0.879 > F110 0.756 > Twin 0.731`; Airframe `BCD 0.913 > CTW
0.774`; FCS `FBW 0.856 > Hydro 0.719`. The production F-16A wins each, and the engine trade is won
on maturity and installed mass **despite** a mid-pack benefit — the intended lesson.
**Consequences** `docs/06_methodology.md`'s "the scoring is deliberately coarse" bullet describes the
old min–max scheme and **must be rewritten at Stage 6**. `docs/04_logical.md`'s 0.60/0.40 tables go
away with the L-layer trade.

### D-016 · Variation points are decided independently (acknowledged simplification)
**Stage** 0 · **Decided by** f16a-mbse-method · **Date** 2026-07-28
**Decision** Three binary kinds form a 2×2×2 morphological box, but the example evaluates three
independent pairs (6 candidate evaluations), not 8 combinations.
**Why it is a simplification** The choices demonstrably interact — relaxed static stability only pays
off *with* fly-by-wire, which is the actual F-16 story. A real morphological study searches
combinations.
**Consequences** Stated plainly in `06_methodology.md` rather than glossed over. A future exercise
can extend the same machinery to combinations.

### D-017 · "Technology-neutral", not "solution-agnostic"
**Stage** 0 · **Decided by** f16a-mbse-method (referee finding) · **Date** 2026-07-28
**Decision** Describe L options as **technology- and vendor-independent**, not "solution-agnostic" or
"solution-free".
**Why** `SingleEngine` vs `TwinEngine` *is* an architectural commitment. ARCADIA's wording is
"technology neutral"; SEBoK's stricter "solution-independent" would push these boxes out of L
altogether. Strict solution-independence is the **F** layer (`ProduceThrust`).
**Consequences** Wording corrected in the agent charter, the L and methodologist agent definitions,
and D-001; the docs must follow the same discipline.

### D-018 · The word "MDAO" stays out of the code
**Stage** 0 · **Decided by** f16a-mbse-method · **Date** 2026-07-28
**Decision** File names, function names and comments call this a **trade study**. The extended-RFLP +
MDAO literature is cited in `06_methodology.md` as the *pattern being followed*, never as a
description of what the script does.
**Why** A weighted sum over a handful of pre-enumerated discrete candidates is not MDAO — no
optimizer, no design-variable continuum, no coupled analysis. Calling it MDAO would teach the wrong
thing.

### D-019 · The L generator no longer requires the decision-requirement set
**Stage** 1 · **Decided by** f16a-logical · **Date** 2026-07-28
**Decision** `generate_f16a_logical.m` drops its prerequisite check on
`requirements/f16a_logical_derived.slreqx`.
**Why** L no longer reads or links the decision requirements — P does. Erroring on their absence
would re-couple L to whether the physical layer has run, which is the coupling D-010 removes.
**Consequences** L's prerequisites are now just `f16a.slreqx` and the F model. `REQ_F16A_L01`–`L03`
have **no incoming Implement links** between Stage 1 and Stage 4 — expected, and visible in the
Requirements Editor as un-implemented until the physical trade study exists.

### D-020 · Kinds are named for topology, and the test enforces it
**Stage** 1 · **Decided by** f16a-logical + f16a-vnv · **Date** 2026-07-28
**Decision** `SingleEngine_F100` → `SingleEngine`, `TwinEngine_LWF` → `TwinEngine`,
`AnalogFBW` → `FlyByWire`. `testKindsAreTechnologyNeutral` reads the six names out of the model and
fails on any digit or any of `F100 F110 PW GE LWF Analog`.
**Why** A vendor or program name in a logical option is the exact confusion this restructure removes;
an executable assertion stops it coming back.
**Note** The token check is deliberately **case-sensitive**: `ConventionalTrapWing` contains `pW`, so
a case-insensitive test would reject a perfectly good kind name.
**Consequences** `REQ_F16A_L02`'s frozen text still says "*analog* fly-by-wire" and `L01`'s still
frames the pick as the YF-16/YF-17 flyoff. Both are historical framing in a decision record rather
than model vocabulary — left alone deliberately, flagged for `f16a-scribe` at Stage 6.

### D-021 · Unset trade parameters must fail safe, not fail cheap
**Stage** 2 audit · **Decided by** f16a-data (finding) + orchestrator · **Date** 2026-07-28
**Problem found** `TradeCandidate.UnitCost_USD` was declared with `DefaultValue="0"`. Stage 3 applies
this stereotype to candidates; any candidate that forgets to set cost would silently carry **$0** —
and under a ratio value function `$0` is not neutral, it is either a divide-by-zero or an infinitely
good score. The same shape of bug applies to `TRL`, which defaulted to an invented `5`.
**Decision** `UnitCost_USD` defaults to `NaN` (confirmed by probe: `DefaultValue="NaN"` is accepted
on a double property and reads back `NaN`). `TRL` cannot hold `NaN` — `int32` rejects it — so it
defaults to `0`, which is outside the valid TRL 1–9 scale, and the trade study **errors** on a
candidate whose TRL is still 0 rather than scoring it.
**Why** A default that silently produces a *plausible* number is worse than one that stops the run.
Cost is `NaN` everywhere by D-005, and a default of 0 is a hole in that rule.

### D-022 · `04_logical.md`'s trade section is rewritten in Stage 3, not Stage 6
**Stage** 2 audit · **Decided by** f16a-data (finding) + orchestrator · **Date** 2026-07-28
**Problem found** `docs/04_logical.md` still documents `F16ALogicalTradeStudy.m` — deleted in Stage 1
— together with six invented `UnitCost_USD` figures ($4.5M/$6.8M/$1.5M/$1.0M/$7.0M/$6.2M), six
invented masses, the retired min–max scoring, superseded weights, the degenerate 0.60/0.40 scores,
and the pre-D-020 vendor kind names.
**Decision** Pull the rewrite of that section forward from Stage 6 into Stage 3.
**Why** Those invented cost figures are a live D-005 violation sitting in a published teaching doc.
They must not still be there when Stage 3 introduces the *real* candidate parameters one file away —
a student comparing the two would be reading two contradictory trades.

### D-023 · The fuel split is an Estimate and will be tagged as one
**Stage** 2 audit · **Decided by** f16a-data (finding) + orchestrator · **Date** 2026-07-28
**Problem found** The three tanks carry 2100 lb each (6300 total) described as "matching the Brandt
internal-fuel weight". Brandt's actual mission fuel is **6296.30 lb** (`Wt!B6`); 3 × 2100 is an even
split of a rounded figure — an `Estimate` in substance, carrying no provenance tag because the
`FuelTank` stereotype has no `DataProvenance` property. Pre-existing since before this restructure.
**Decision** Stage 3 adds `DataProvenance` to `FuelTank` and tags the three capacities `Estimate`,
with the Brandt figure named in the generator comment.
**Why** Now that D-007's vocabulary exists, this is the most conspicuous untagged number left in the
model, and "no agent invents a number" has to apply to the numbers that were already there.

### D-024 · Realization retargets at candidates: 15 edges become 14
**Stage** 3 · **Decided by** f16a-physical (correction) + orchestrator · **Date** 2026-07-28
**Decision** `F16A_LogicalToPhysical` now allocates `Airframe → {BlendedCrankedDelta,
ConventionalTrapWing}` (2), `PropulsionSystem → {Engine/F100_PW_200, Engine/F110_GE_100,
Engine/TwinEngine_Surrogate, InletDuct}` (4), `FlightControlSystem → {FlyByWire, HydroMechanical}`
(2), and the other six roles one each (6) = **14 edges**.
**Correction** The orchestrator's brief said "still 15 edges", which does not add up against its own
list — the old 15 counted Airframe's six *decomposition* edges, which are now internal to a
candidate. The generator prints `size(edges,1)` and self-reported 14.
**Consequences** The 1→many teaching moment moves from `Airframe` (6 structural parts) to
`PropulsionSystem` (4 candidates + the shared inlet). Any test or doc asserting 15 must say 14.

### D-025 · `DataProvenance` qualifies the mass, not the judgement
**Stage** 3 · **Decided by** f16a-physical · **Date** 2026-07-28
**Decision** A candidate carries one `DataProvenance` tag, and it qualifies its **`Mass_lb`**.
`Benefit` and `TRL` are judgement on a declared scale even on a `Reference`-tagged candidate, and the
generator comment says so.
**Why** Without that note, `DataProvenance = Reference` on `F100_PW_200` would imply its Benefit of
8.2 is sourced from Brandt, which it is not — it is our judgement. Overclaiming provenance is the
failure mode D-007 exists to prevent, so the tag has to state precisely what it covers.

### D-026 · Dropping a criterion is a general rule, not a cost special case
**Stage** 4 · **Decided by** orchestrator + f16a-physical · **Date** 2026-07-29
**Decision** `F16APhysicalTradeStudy` drops **any** criterion for which no candidate of a role
carries a value, and renormalizes the remaining weights. Cost falls out of that rule because it is
`NaN`; it is not named as a special case in the scoring code.
**Consequences** The printed table shows `UnitCost_USD DROPPED` and the declared weights
`0.40/0.20/0.20/0.20` renormalizing to `0.50/0.25/0.25` — so the weights in D-015 are *derived at run
time*, not typed in. The day `F16APhysicalCostModel` returns real numbers, cost re-enters the trade
with **no code change**. That property is the reason for the general rule.

### D-027 · The callback keys on the kind, and `DecisionRef` is written on every kind
**Stage** 4 · **Decided by** f16a-physical · **Date** 2026-07-29
**Decision** The cross-layer write-back resolves the L kind from the winner's `RealizesKind`, never
from the candidate name — the mapping is many-to-one (`F100_PW_200` and `F110_GE_100` both realize
`SingleEngine`). And `DecisionRef` is set on **every kind of the role**, not only the winner.
**Why** Keying on the candidate name would work today by coincidence and break the moment a
different single-engine candidate won. Writing `DecisionRef` on the losers too means a reader who
clicks the rejected `TwinEngine` lands on the requirement that explains *why it lost*, instead of on
`TBD` — the rejection is part of the decision record.

### D-028 · Decision links are rebuilt, not created-if-absent
**Stage** 4 · **Decided by** f16a-physical · **Date** 2026-07-29
**Decision** Before linking a winning kind to its decision requirement, the trade study removes any
existing inbound link whose source artifact is the L model, then creates one fresh link.
**Why** A create-if-absent guard cannot fix the case that matters: re-running after the winner
changes would leave the *previous* winner's link in place, so two kinds would claim to implement the
same decision. Scoping the removal to L-model sources leaves a hand-made Verify link from a test
file untouched.

### D-029 · Roll-ups do not write during tests
**Stage** 4 · **Decided by** user + f16a-physical · **Date** 2026-07-29
**Decision** `F16APhysicalMassRollup` takes `Persist` (default `true`); with `Persist=false` it skips
writing the OEW Measure of Merit and skips `save_system`. The test suite always calls it read-only.
**Why** The suite was writing to the very model it was testing — which can mask a generator defect
(the tests would "repair" a model the generator built wrong) and leaves a dirty working tree after
every run. The materials and fuel roll-ups were already read-only and needed no change.
**Not done** The suite still computes the roll-up three times (~10 s). Measured and accepted: the
warm suite is ~17 s, and the earlier "15 minutes" was a cold-start artifact, not a property of the
tests.
