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

### D-030 · Inventory of every invented number
**Stage** 5 audit · **Raised by** f16a-data (**VETO**) · **Date** 2026-07-31
**Problem found** D-007 requires every `Estimate` to be listed in this log. None of the 19 values
introduced by Stages 3–4 were. Worse, three comments in `generate_f16a_physical.m` asserted that they
*were* "listed in docs/07_decision_log.md, as D-007 requires" — a provenance system whose code lies
about where its provenance lives is worse than one that makes no claim. The rule the team wrote for
itself was being broken by the team's own record.
**Decision** This entry is the inventory, and it is the thing D-007 points at. Every number below is
**invented for teaching**. None is F-16 data. Do not cite any of them.

| Value | Component | Property | Tag | Why this number |
|---|---|---|---|---|
| 7300 lb | `ConventionalTrapWing` | `Mass_lb` | Estimate | No such aircraft was built. Assumed ~8.6% heavier than the blended delta, on the argument that a discrete wing-body is structurally less efficient |
| 5100 lb | `F110_GE_100` | `Mass_lb` | Estimate | The F110 is real but post-dates the F-16A; installed mass scaled off the F100 figure |
| 6400 lb | `TwinEngine_Surrogate` | `Mass_lb` | Estimate | Stands in for a twin installation of the YF-17 class. Not a specific engine pair |
| 700 lb | `HydroMechanical` | `Mass_lb` | Estimate | A conventional control system for this class, assumed heavier than the fly-by-wire group |
| 0.12 | `ConventionalTrapWing` | `CompositeFraction` | Estimate | Aluminium-dominant conventional airframe |
| 0.15 / 0.10 / 0.55 / 0.70 / 0.05 / 0.50 | Wing / Fuselage / HorizTail / VertTail / Nacelles / Strakes | `CompositeFraction` | Estimate | Educated guess grounded in real F-16 composite usage (graphite/epoxy tail skins, carbon-fibre wing leading edge, fibreglass strakes) — **and tuned so the mass-weighted fraction lands just inside `REQ_F16A_022`'s 20% cap.** Pre-existing, Stage-0 era. Stated plainly because numbers chosen to make a requirement pass are exactly the kind that must not look sourced |
| 9.5 / 6.5 · 9.0 / 6.0 · 8.2 / 8.6 / 7.8 | the 7 candidates | `Benefit` | judgement (D-025) | Declared 0–10 scale. Relative ordering carries the teaching, the absolute values carry nothing |
| 7 / 8 · 6 / 9 · 8 / 4 / 6 | the 7 candidates | `TRL` | judgement (D-025) | Declared 1–9 scale. F110's 4 encodes "not available in the F-16A timeframe" — the fact that decides the engine trade |
| 3 × 2100 lb | the fuel tanks | `FuelCapacity_lb` | Estimate | See D-023: Brandt's figure is 6296.30 lb (`Wt!B6`) |
| −6 %MAC / ~~+1 %MAC~~ | `REQ_F16A_025` | requirement band — no stereotype, so no `DataProvenance` slot; tagged here instead | Estimate | **Narrowed 2026-08-03 by D-051: the `+1 %MAC` end is gone, the `−6 %MAC` end is live — see the note below.** −6 % is a figure commonly repeated for the F-16's subsonic relaxed static stability, but no source is cited and `/sizing/` contains none (verified: no static-margin criterion anywhere in `VnV/BrandtF16A/`). +1 % is pure design intent, invented to exclude a conventionally stable aeroplane. Do not cite either |

> *Static-margin row appended **2026-08-02**, at the Stage-0 gate, under **D-046** — the decision that
> introduced the band. D-030 is committed history and is not rewritten; its table is the project's
> **living inventory** (D-038 requires a new invented number to "appear in D-030"), so adding a row
> extends the inventory rather than altering the decision. Raised by `f16a-data` (**VETO**): the band
> shipped untagged, and it is not `Reference` (no criterion in `/sizing/`), not `Datasheet` (no source
> cited) and not `Simulation` (nothing computes it).*
>
> *Static-margin row **narrowed 2026-08-03** under **D-051**, which reshapes the criterion to
> **−6 %MAC ≤ `SM` < 0**. The `+1 %MAC` upper bound is **gone** — replaced by a strict zero, which is
> the definition of relaxed static stability rather than a chosen figure, and so is not inventoried.
> The `−6 %MAC` lower bound is **unchanged and still live**: still uncited, still `Estimate`, still
> here. The row now inventories **one** invented number instead of two. **The inventory stays at 20
> rows.***
>
> ***How a row changes, since this is the first one that has.*** *It is **annotated and dated, never
> rewritten and never deleted.** The log is append-only, so deleting a value would erase the record
> that it was ever in the model — and this table is also the answer to "was that figure ever cited as
> data?", which a deleted row cannot give. Leaving it unmarked is the opposite failure: an inventory
> listing a number the model no longer contains misleads as surely as one omitting a number it does.
> So the original text stays verbatim, the departed value gains a strikethrough, and the cell names
> **the date and the entry that changed it**. Read struck values as history; count live ones.*

`Benefit` and `TRL` supply **0.75 of every trade score** and are unauditable in principle — they trace
to nothing. That is precisely why they must be *recorded*, since they can never be *checked*.
**Consequences** The three false generator comments are corrected to point here. `Material` gains a
`DataProvenance` property so the composite fractions can be tagged in the model rather than only in
prose (D-031).

### D-031 · `Material` carries provenance too
**Stage** 5 audit · **Raised by** f16a-data (**VETO**) · **Date** 2026-07-31
**Problem found** `Material` declared only `CompositeFraction`, so all seven composite fractions were
invented numbers with **no tag at all** — the exact gap D-023 closed for `FuelTank`, left open one
stereotype over.
**Decision** Add `DataProvenance` to `Material` and tag all seven fractions `Estimate`.
**Why** An untagged invented number is a veto by the data agent's charter. The provenance vocabulary
is worth nothing if it is applied only where someone happened to remember.

### D-032 · The aircraft cost MoM defaults to NaN as well
**Stage** 5 audit · **Raised by** f16a-data · **Date** 2026-07-31
**Problem found** `MeasureOfMerit.UnitCost_USD` still defaulted to `0`. No live violation — the
generator writes `NaN` explicitly from the cost stub — but it is the same latent hole D-021 closed on
`TradeCandidate`: a future path that applies the stereotype without writing the property would ship
`$0` as the aircraft's flyaway cost.
**Decision** Default it to `NaN` too.

### D-033 · `Benefit` is bounded at both ends, and its scale is 1–10
**Stage** 5 audit · **Raised by** f16a-mbse-method · **Date** 2026-07-31
**Problem found** The trade study's guards were asymmetric: `TRL` was boxed both ends (1–9, integer),
but `Benefit` was only checked `> 0` despite declaring a 0–10 scale. `7.8` mistyped as `78` gives
`v = B/10 = 7.8`, contributing **3.90** where the legitimate maximum contribution of any criterion is
0.50 — `TwinEngine_Surrogate` would score ≈4.24 against F100's 0.87875 and win. Being finite, it
would slip past the `isfinite` check, flip `RealizesKind` to `TwinEngine`, change the L model's
active kind and Implement-link `REQ_F16A_L01` from the wrong kind. **A dropped decimal point could
propagate a wrong decision into requirements traceability, silently.**
**Decision** Enforce `1 ≤ Benefit ≤ 10`. The scale is stated as **1–10 with 0 meaning "not set"** —
`Benefit`'s stereotype default is `0`, so zero was already doing sentinel duty exactly as TRL's does
under D-021; the declared "0–10" contradicted the guard that rejected it. Code, comment and guard now
agree.
**Why it matters** This is the file's own philosophy applied consistently: an out-of-range parameter
must stop the trade, not be scored.

### D-034 · "Decided by" is decisive against the runner-up, and now says so
**Stage** 5 audit · **Raised by** f16a-mbse-method · **Date** 2026-07-31
**Problem found** `decisiveCriterion` computes the winner's largest weighted advantage over the
**rank-2** candidate, but the printed table and the stored `Rationale.Justification` stated it as a
property of the decision overall. Propulsion reports "decided by TRL" (+0.125 over `F110_GE_100`);
measured against `TwinEngine_Surrogate` the same winner's largest advantage is Mass (+0.0652) ahead
of TRL (+0.0625). Same victory, different "deciding" criterion depending on the rival.
**Decision** Fix by wording — say *against the runner-up* in both the printed output and the stored
justification. Scores, ranks and winners were never affected; what was overclaimed is the **audit
trail**, which is the thing this script exists to produce.
**Deferred** Rival-independent decisiveness — which criterion, if removed, would change the winner —
is a real sensitivity calculation and is left as future work rather than faked.

### D-035 · The mass value function is unbounded above (known limit)
**Stage** 5 audit · **Raised by** f16a-mbse-method · **Date** 2026-07-31
**Problem found** `v = M_baseline / M` has no ceiling, while `B/10` and `(TRL−1)/8` are capped at 1.0
by their declared scales. A candidate lighter than its baseline — a 3500 lb engine gives `v = 1.351`,
contributing 0.338 against the 0.25 the other criteria are capped at — makes the declared weights
`0.50/0.25/0.25` stop describing actual influence.
**Decision** Record it as a known limit and **warn** at run time when any value function exceeds 1.0,
naming the candidate and criterion. Do not cap (that discards real information about a genuinely
better candidate) and do not error (that rejects a legitimate one). The check is written generically,
because `UnitCost_USD` inherits the identical `C_baseline/C` shape the day a cost model lands.
**Why it is not merely theoretical** No current candidate is lighter than its baseline, so nothing
is wrong today — but the trade study's headline feature is that candidates are *discovered, not
declared*, and its own header invites adding a fourth engine. That is precisely the action that arms
this.
**Proper fix, deferred** A bounded value function over a declared range per criterion.

### D-036 · The Brandt masses are *referenced from the `.m` model*, not transcribed twice
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-01 · **Status** DECIDED, NOT YET IMPLEMENTED
**Problem** (TODO item A4) The same 16 Brandt component masses are hand-typed in **two** places:
`physical/generate_f16a_physical.m` (`massRows`, ~ll. 506–528) and
`physical/F16APhysicalArchitectureTest.m` (`MassRows`, ~ll. 218–235). The test therefore asserts
*"the generator wrote what the test author also typed"*, not *"the model agrees with the F-16A sizing
model"*. A transcription error made in both places is invisible, and a change in `/sizing/` is
invisible. Two symptoms are already visible: the model carries OEW `19980.73` against Brandt's
`19980.70`, and airframe structural subtotal `6722.88` against `6722.87` — sum-of-rounded-parts
versus the spreadsheet's own subtotal cell.

**Decision — the "Right" option, with the source named explicitly.**
`F16APhysicalArchitectureTest` shall obtain the ground-truth masses by **executing
`sizing/VnV/BrandtF16A/BrandtWeight.m`** (read-only) and reading its properties, rather than from a
literal table. The generator remains the **only** place the numbers are typed; the test becomes a
genuine cross-check between two independently-authored models.

**The source is the `.m` file, not the spreadsheet.** `GroundTruth/Brandt-F16-A.xls` and
`GroundTruth/cell-map.md` are *not* the reference. Rationale: the `.m` class is the executable,
version-controlled, testable artifact this repository maintains; the `.xls` is the historical origin
it was validated against and is not machine-read anywhere in the repo. Referencing the spreadsheet
would add an Excel dependency and would still be a transcription — just one made by a different tool.

**Declared mapping** (16 leaves + 2 subtotals). `BrandtWeight` is constructed on an analyzed
`BrandtGeometry`, `analyze()`d, and `run(31377)` — W_TO = 31,377 lb, `Wt!B3`, which must be stated as
the design point rather than assumed:

| MBSE component (under `Aircraft/`) | `BrandtWeight` property |
|---|---|
| `Airframe/BlendedCrankedDelta/Wing` | `W_wing_lb` |
| `Airframe/BlendedCrankedDelta/Fuselage` | `W_fuse_lb` |
| `Airframe/BlendedCrankedDelta/HorizontalTail` | `W_pitch_lb` |
| `Airframe/BlendedCrankedDelta/VerticalTail` | `W_vert_lb` |
| `Airframe/BlendedCrankedDelta/Nacelles` | `W_nacelles_lb` |
| `Airframe/BlendedCrankedDelta/Strakes` | `W_strakes_lb` |
| `Propulsion/Engine/F100_PW_200` | `W_engine_lb` |
| `Propulsion/InletDuct` | `W_inlet_duct_lb` |
| `LandingGear` | `W_gear_lb` |
| `FlightControls/FlyByWire` | `W_ctrl_lb` |
| `Avionics` | `W_avionics_lb` |
| `Electrical` | `W_elec_lb` |
| `Hydraulics` | `W_hyd_lb` |
| `ECS` | `W_ECS_lb` |
| `ArmamentSupport` | `W_armament_lb` |
| `SecondaryStructure` | `W_other_lb` |
| *(airframe structural subtotal)* → test constant **`BrandtAirframeMass_lb`** (6722.88) | **`W_structure_lb`** |
| *(OEW Measure of Merit)* → test constant **`ExpectedOEW_lb`** (19980.73) | `W_empty_lb` |

**The two subtotal rows name their receiving constant on purpose, because one of them is
misleadingly named.** `F16APhysicalArchitectureTest.BrandtAirframeMass_lb` (`:234`) carries 6722.88 —
the **airframe structural subtotal**, `W_structure_lb` (`Wt!B9`). Its name points instead at Brandt's
`W_airframe_lb` (**15250.47**, `Wt!B10` = OEW − engine, i.e. structure *plus* systems), which is a
different quantity entirely. Wiring the test to the property its constant is *named* after would swap
one figure for another more than twice its size, and the assertion would still read plausibly.
**`W_airframe_lb` is deliberately NOT mapped: no MBSE component equals it.** The MBSE model has no
"everything but the engine" grouping — `Airframe` is structure only, and the systems sit beside it —
so there is nothing for it to be compared against. (`readme_wt.md:309` flags the same trap on the
`/sizing/` side: *"Mixing these would overstate airframe and understate OEW."*)

**Consequence that must not be glossed over: the `.m` model does not reproduce the spreadsheet
exactly, so the assertion has to gain a tolerance.** `BrandtWeight`'s own help block and
`readme_wt.md` §10 record the deltas — the nacelle area uses `π` where the spreadsheet uses `3.1516`:

| Quantity | `.xls` (today's literal) | `BrandtWeight.m` computes | Δ |
|---|---|---|---|
| `W_nacelles` | 186.82 | ≈ 186.12 | −0.37 % |
| `W_inlet_duct` | 728.60 | ≈ 726.87 | −0.37 % |
| `W_wing` | 1785.95 | ≈ 1787 | +0.06 % |
| `W_other` | 2016.86 | ≈ 2016.82 | < 0.01 % |
| **OEW** | 19980.70 | ≈ 19979 | ≈ 0.01 % |

⚠ **`W_inlet_duct ≈ 726.87` in that table is wrong, and Stage 5 must not hard-code it.** The figure is
inherited from `readme_wt.md:415`; `BrandtWeight.m:194` makes the inlet duct **exactly** `3.9 ×
W_nacelles`, so the computed value is `3.9 × 186.12` = **725.87**, not 726.87. The `−0.37 %` column is
right (it is the nacelle error propagated unchanged, `3.9` being exact); only the absolute figure is
not. Noted here rather than corrected in `/sizing/`, which is read-only (house rule 4) — the point of
D-036 is that the test **executes** `BrandtWeight` instead of transcribing any of these numbers, and
this is a small live demonstration of why: a digit that drifted in a README propagated into a decision
log without anybody recomputing it.

So this decision **converts an exact-equality assertion into a tolerance assertion**, and that is a
real loss that is being accepted knowingly. `sizing/VnV/BrandtF16A/tests/test_BrandtWeight.m` already
declares the house tolerance for exactly this comparison — **1 % RelTol** for physics-computed
weights, 0.1 % for algebraically exact ones — and the MBSE test should adopt the same figures rather
than invent its own. What stays *exact* is everything internal to the MBSE model: each subtotal is
still the exact sum of its parts, and OEW is still the exact sum of the 16 active leaves. The
cross-model comparison is the only place a tolerance appears.

**`W_other_lb` goes on the 1 % side, not the 0.1 % side — it only looks algebraically exact.**
`BrandtWeight.m:244` **derives** it as `0.30 × W_structure_lb`, and `W_structure_lb`
(`BrandtWeight.m:186`) includes `W_nacelles`, so `W_other` inherits the nacelle-`π` error
proportionally. `test_BrandtWeight.m:167–168` asserts only the **relation** (`AbsTol 1e-6` against
`0.30 × W_structure`), never the absolute 2016.86 — so nothing in `/sizing/` certifies its absolute
value to 0.1 %, and the MBSE test must not be the first artifact to claim it does. *(For the record,
the inherited drift is small — the table above measures it at < 0.01 %, so a 0.1 % assertion would
pass today. The placement is a provenance judgement, not a numerical necessity: a figure whose only
guarantee is a ratio does not belong in the "algebraically exact" bucket, and the day the nacelle
formula moves it would be the assertion that broke for the wrong reason.)*

**This also settles the two-figure reconciliation.** Under this decision the MBSE `19980.73` /
`6722.88` are correctly described as *sums of the rounded part masses*, compared against Brandt's own
`W_empty_lb` / `W_structure_lb` within tolerance. Neither figure is "wrong"; the drift becomes
explained and measured rather than hidden behind two agreeing transcriptions.

**Alternatives considered**
- *Cheap (rejected)* — keep the literals and cite the originating cell for each (`Wt!C9`, `Wt!D9`, …).
  Cheaper, and it makes the provenance readable, but it leaves both copies in place and the test still
  asserts a transcription. It fixes the documentation of the problem, not the problem.
- *Move the numbers out of the generator too* (rejected for now) — have the **generator** read
  `/sizing/` as well. That would make the MBSE model a downstream artifact of the sizing code and
  couple model *generation* to a folder under active rewrite. The generator stays the single place the
  numbers are typed; only the test crosses the boundary. Revisit if the sizing rewrite stabilizes.

**Constraints on the implementation** (write scope is `mbse/` only — `sizing/` stays read-only)
1. `BrandtGeometry`/`BrandtWeight` compute in memory and write nothing; the only file touched is
   `GroundTruth/f16a_geometry.json`, read. Nothing in `sizing/` may be modified.
2. The MBSE test must add `sizing/VnV/BrandtF16A` to the path itself, derived from `f16aRoot()`
   (**three** levels up), and must **restore the path on teardown** — the example's tests currently
   `addpath` without cleanup, and reaching outside the project makes that no longer free.
   *(Corrected 2026-08-02: this entry said "four". `f16aRoot()` returns
   `…/air_vehicle_design/mbse/examples/f16a`, and three `fileparts` reach `…/air_vehicle_design`,
   where `sizing/` lives — which is what `F16AStaticMarginVerificationTest.m:220` actually does. The
   code was right; the log was wrong.)*
3. If `/sizing/` is missing or `BrandtWeight` errors, the test must **fail loudly with a message that
   names the missing dependency** — not skip, and not silently fall back to the literals. A quiet
   fallback would restore exactly the blindness this entry removes.
4. `F16ADataProvenance.Reference` is currently documented as "traceable to the Brandt F-16A ground
   truth carried in `sizing/VnV/BrandtF16A/`". After this change that sentence becomes literally true
   for the three `Reference`-tagged candidate masses, and `docs/05_physical.md` and
   `docs/08_agent_team.md` should say so.

**Open** Whether `F16APhysicalMassRollup`'s `ExpectedOEW_lb` and the candidate `TradeCandidate.Mass_lb`
baselines (4730.23 / 6722.88 / 472.44) are re-sourced the same way, or stay literals in the generator
with the test doing the cross-check. The decision above covers the **test**; the generator's own
literals are untouched by it.
**Traces to** TODO A4 · `physical/F16APhysicalArchitectureTest.m` · `sizing/VnV/BrandtF16A/BrandtWeight.m` · D-007 · D-030

### D-037 · A decision requirement poses the decision; it does not contain the answer
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-01 · **Status** DECIDED, NOT YET IMPLEMENTED
**Problem found** (code review, TODO A6) `requirements/generate_f16a_logical_derived_requirements.m`
writes the trade's *outcome* into `REQ_F16A_L01`–`L03` — and it runs **before**
`generate_f16a_physical`. L01's `Description` reads *"shall be realized by a single afterburning
turbofan (Pratt & Whitney F100 class), rather than a twin-engine installation"*, so the model records
"single engine was selected" as a **premise**, in a file the trade study never rewrites (it only adds
the Implement link). In the one example whose thesis is *L presents the options, P decides*, the
answer is written down before anything scores it.

Three consequences, in increasing order of how quietly they bite:
1. **A vendor name in the L-decision record.** D-020 removed `F100`/`PW`/`GE` from the L *kinds* and
   made the ban executable; the requirement that records that very decision kept it.
2. **Run-time-derived weights are typed in.** All three `Rationale` fields say *"weights
   0.50 / 0.25 / 0.25"*. D-026 makes those *derived at run time* from `0.40/0.20/0.20/0.20` by dropping
   cost. The day B2 lands, three requirement texts are silently wrong and nothing compares them to the
   trade's output.
3. **A D-034 overclaim one file over.** L03 credits the blended delta with *"a lighter structure
   relative to the role's baseline mass"* — but it **is** the baseline (`Reference`), so `v = 1.0`
   exactly. It is lighter than its rival, not than the baseline.

`testProductionConfigurationWins` pins the winner *identities*, so the headline claim cannot drift.
Nothing pins the weights or the reasoning. This is **D-036's problem — transcribed rather than
referenced — applied to the decision rationale instead of to the masses.**

**Decision** Rewrite `REQ_F16A_L01`–`L03` so each **poses** its decision over the kinds L presents and
names where the answer is recorded, carrying no winner, no vendor, no weight and no score. Add the
tests that keep it that way (a vendor-token check mirroring `testKindsAreTechnologyNeutral`, and an
assertion that no weight or score is restated). Fix the L03 baseline sentence.
**Why** A requirement that already contains its answer is not a decision record, it is a decision
*claim* — and an unfalsifiable one, because no artifact is derived from it. The audit trail is the
thing this part of the example exists to produce, which is exactly the reasoning of D-034.
**Consequences** D-020's deferred note — L02's "analog fly-by-wire" wording and L01's YF-16/YF-17
framing, left for Stage 6 as "historical framing in a decision record" — is **closed by this work**
rather than handled separately.
**Open sub-question, deliberately not settled here** Where the verdict then lives. The generator's own
header claims *"This requirement — not the variant flag — is where the decision is authoritatively
recorded"*, which cuts two ways: **(a)** the requirement stays a pure question and the verdict lives
only where it is computed (candidate `Rationale.Justification` + the Implement link) — simplest, one
source of truth, but that header sentence must change; or **(b)** `F16APhysicalTradeStudy` writes the
verdict into the requirement as a fourth write alongside the P model, the L model and the link set —
keeps the claim true and makes consequence 2 structurally impossible, at the price of a P-layer script
writing into an R-owned requirement set, and of a re-run of the R generator blanking it until the trade
runs again. **(b) is the more consistent with what the example already claims.** Decide before writing
code — the decision is the interesting part, exactly as in B2.
**Traces to** TODO A6 · `requirements/generate_f16a_logical_derived_requirements.m` · D-020 · D-026 · D-034 · D-036

### D-038 · The fuel roll-up becomes variant-safe, and rolls up volume as well as weight
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-01 · **Status** PART 1 STANDS · **PART 2 SUPERSEDED BY D-041** (2026-08-02)
**Problem found** (code review, TODO A7) `physical/F16APhysicalFuelRollup.m` is the only file in
`physical/` with no variant handling at all — no `getChoices`, no `getActiveChoice`, no
`VariantComponent` branch. It reads `fuelSys.Architecture.Components` flat, and calls `getProperty(…,
FuelTank.FuelCapacity_lb)` on every child without checking the stereotype. Two failure modes:
if `FuelSystem` becomes a variant role, Stage-0 **finding 6** makes that walk return **zero** on a
saved-and-reloaded model, `sum([])` is `0`, nothing errors, and the roll-up reports **0 lb of available
fuel**; and any non-tank child (pump, manifold, battery) errors the run out. `F16APhysicalMaterials-
Rollup` already solved both, structurally, one file over. No test calls this function today —
`testFuelTankCapacities` walks the tank paths itself, and the only caller is the verification test that
fails on purpose.

**Why it is not hypothetical** `FuelSystem` becomes a variant role the moment the example admits a
**hybrid-electric or fully-electric** aircraft: "the energy-storage role" then has competing kinds
(fuel tankage / battery / hybrid) exactly as `Airframe`, `Engine` and `FlightControls` do, and D-002's
rule applies unchanged — *a role with more than one candidate is not a part, it is an open question*.
The defect is dormant, not absent, and **B1 is what makes it load-bearing**.

**Decision, part 1 — mimic `F16APhysicalMaterialsRollup`.** Replace the flat loop with a recursive
`fuelLeaves` helper on the same shape as `materialLeaves`: descend into `getActiveChoice` at a variant
component (never `getChoices` — a roll-up reports the *active* configuration; never
`.Architecture.Components`), and apply the structural leaf rule **"a component that carries `FuelTank`
IS a fuel leaf"**, checked with `getStereotypes` and not descended into further. That is what lets a
lumped candidate stating one whole-block capacity and a decomposed candidate stating one per tank go
through the same walk with no list of names anywhere. Error (`:noFuelTanks`) when the walk finds
nothing, mirroring `:noMaterialParts` — **a silent 0 is the failure mode being removed and must not be
replaced with a different silent 0.**

**Decision, part 2 — roll up available fuel VOLUME.** `REQ_F16A_P01` says *"tankage (volume, expressed
as fuel-weight capacity)"*; volume is a proxy today and becomes a real rolled-up quantity. Sourced from
**one fuel density** converting the existing `FuelCapacity_lb`, rather than three per-tank volume
properties — one number, one provenance tag, and the weight/volume pair cannot drift apart.

⚠ **The density is a NEW number and `/sizing/` does not contain one.** Verified: there is no fuel
density and no fuel volume anywhere in `sizing/VnV/BrandtF16A/` — the Brandt model works entirely in
fuel weight. So house rule 1 and D-007 apply in full: it must carry a `DataProvenance` tag and appear
in **D-030**. It **cannot** be tagged `Reference`, because there is nothing to reference. Cite a fuel
specification and tag it `Datasheet` — JP-4 (MIL-DTL-5624, ≈ 6.5 lb/gal) is the F-16A-era USAF fuel and
the defensible choice; JP-8 (MIL-DTL-83133, ≈ 6.7 lb/gal) post-dates the aircraft. This is one of the
few numbers in this example that *can* be properly sourced, and it should be.

**The two figures must not merge** — the same trap B1 warns about, one layer over. The roll-up returns
`AvailableFuel_lb`, the **weight**, and the only figure comparable with `BrandtMission`'s
`Miss!O9 = 6000.43 lb` in the B1 verification; and `AvailableFuelVolume_gal`, the **volume**, which
answers "does the tankage physically exist?" and has no counterpart in `/sizing/`. Both come from **one
walk in one function** — extend `F16APhysicalFuelRollup` rather than adding a second file that
duplicates the walk and can disagree with it.
**Consequences** `REQ_F16A_P01`'s hedge *"(volume, expressed as fuel-weight capacity)"* can be reworded
once volume is first-class. The volume figure inherits **D-023**: the 3 × 2100 lb split is an
`Estimate`, so a volume derived from it is an estimate divided by a datasheet constant and is no more
trustworthy than the capacity it came from. `f16a-vnv` adds the first test that actually calls this
roll-up.
**Order** Part 1 is a prerequisite for **B1**. Part 2 may follow independently.
**Traces to** TODO A7 · `physical/F16APhysicalFuelRollup.m` · `REQ_F16A_P01` · D-002 · D-007 · D-012 · D-023 · D-030

### D-039 · The F layer's folder is renamed `architecture/` → `functions/`
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-01 · **Status** DECIDED, NOT YET IMPLEMENTED
**Problem found** (code review, TODO A11) The F layer lives in `architecture/` for a reason that
stopped being true in July 2026, and no decision was ever recorded for it. The folder was created in
the first F-layer commit (`2b1bd5a`) when `F16A_Functional.slx` was the **only** System Composer
architecture model in the example — accurate then. `logical/` (`d61256c`) and `physical/` (`9f82c3f`)
arrived later, each named for its **layer**, establishing a convention `architecture/` predates. The
reorg (`ea1f14f`) moved the F generator and test *into* the existing folder rather than renaming it;
its commit body records only the move.
**Decision** Rename it to `functions/`.
**Why** All three layers are System Composer architecture models, so `architecture/` names the property
the F layer *shares* with L and P — the least distinctive thing about it — while every sibling folder
(`requirements/`, `logical/`, `physical/`, `verification/`) is named for its concern. Five other names
in the example say *functions*: the README status table (**F – Functions**), `docs/02_functions.md`,
the agent `f16a-functions`, `generate_f16a_functional.m` and `F16A_Functional.slx`. In an example whose
point is that each RFLP letter's concern is visible in the filesystem, the folder is the lone dissenter.
**Scope** `git mv` (so git records a rename and classification labels survive); **five** literal path
strings in code — `architecture/{F16AFunctionalArchitectureTest.m:17, generate_f16a_functional.m:38}`,
`logical/{F16ALogicalArchitectureTest.m:116, generate_f16a_logical.m:92}`, `F16AOpenForReview.m:20` —
everything else resolving by name off the project path; ~11 doc references; and
`.claude/agents/f16a-functions.md`. **The file names do not change**: `F16A_Functional.slx`,
`generate_f16a_functional.m` and `F16AFunctionalArchitectureTest.m` are already correct.
**The real cost is the project registry, and it is exactly the A1 failure mode.** The folder is on the
project path and its files are registered members; a `git mv` that does not propagate leaves dangling
entries, fails *"All project files and folders exist on the file system"*, and lets a later operation
garbage-collect them into a spurious `resources/project/` diff. Update the project path entry,
re-register the moved files, and finish with **`runChecks(currentProject)` at 12/12** — the standing
rule from A1's "Note for future stages". **This gets its own stage and its own gate**; it must not be
bundled with unrelated fixes.
**Traces to** TODO A11 · commits `2b1bd5a`, `ea1f14f` · TODO A1

### D-040 · The decision requirement stays a pure question; the verdict lives where it is computed
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED, NOT YET IMPLEMENTED
**Decision** D-037's open sub-question is resolved as **option (a)**. `REQ_F16A_L01`–`L03` pose their
decision and name where the answer is recorded; they never contain the answer. The verdict lives in
exactly one place — the winning candidate's `Rationale.Justification` at P, plus the Implement link
from the winning kind — and no generator writes a verdict into a requirement set.
**Rejected** Option (b), the trade study writing the verdict into the requirement as a fourth write.
It would have kept the "the requirement is the authoritative record" sentence literally true, but at
the price of a P-layer script writing into an R-owned artifact, and of a re-run of the R generator
blanking the verdict until the trade ran again.
**Consequence — two sentences in the docs become false and must be rewritten**, because under (a) the
requirement is *not* the record of the verdict:
- `requirements/generate_f16a_logical_derived_requirements.m`, header: *"This requirement — not the
  variant flag — is where the decision is authoritatively recorded"*.
- `docs/03_traceability.md:144`: *"the requirement — not the variant flag — is the authoritative record
  of the decision"*.

The correct statement in both places is that the requirement is **where the decision is posed and
where its record is anchored**; the verdict itself is the trade study's output, carried by the
candidate's `Rationale` and by the Implement link. Note this does *not* restore the variant flag to
authority — the flag remains derived (D-027), and it is still true that reading the active choice is
not reading the decision.
**Why (a) is enough** The link and the justification are both generated, both idempotent, and both
already asserted by `testDecisionRequirementsImplemented` and `testWinnersCarryTradeWinnerRationale`.
The requirement having no verdict text is what makes the D-037 defect *structurally* impossible rather
than fixed once — there is no verdict text left to drift.
**Traces to** TODO A6 · D-037 · D-027

### D-041 · Fuel is rolled up by WEIGHT only; the volume roll-up is dropped
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED, NOT YET IMPLEMENTED · **Supersedes D-038 part 2**
**Decision** `F16APhysicalFuelRollup` rolls up **available fuel weight** from the tanks, and nothing
else. The `AvailableFuelVolume_gal` roll-up decided in D-038 part 2 is **not built**. No fuel-density
property, no `FuelVolume` property, no new number.
**D-038 part 1 is unaffected and still stands**: the walk becomes variant-safe (descend through
`getActiveChoice`) and stereotype-checked (`getStereotypes`, the structural "a component carrying
`FuelTank` IS a fuel leaf" rule), mirroring `F16APhysicalMaterialsRollup`, and errors rather than
returning a silent 0. That fix was never about volume.
**Why** The volume route required a fuel density, and **`/sizing/` has none** — verified: there is no
fuel density and no fuel volume anywhere in `sizing/VnV/BrandtF16A/`, which works entirely in fuel
weight. So volume would have added the one thing this example works hardest to avoid: a number with no
home in the reference model, needing its own provenance argument, to support a quantity nothing else
in the example consumes. Weight is also the *only* figure comparable with the mission analysis, so it
is the figure the requirement actually turns on.
**Consequence** `REQ_F16A_P01`'s wording — *"internal fuel tankage (volume, expressed as fuel-weight
capacity)"* — is now the settled formulation rather than a hedge awaiting improvement, and should be
left alone. The volume/weight two-figures trap flagged in D-038 cannot arise, because there is only
ever one figure.
**Traces to** TODO A7 · D-038 · D-023 · D-007

### D-042 · The fuel verification stays RED, permanently and by design
**Stage** 7 · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED — this is a decision NOT to do something
**Decision** `physical/F16APhysicalMissionFuel.m` keeps returning `NaN`. `F16AFuelVerificationTest`
keeps failing. `REQ_F16A_P01` keeps reading "verification pending". **It is not wired to
`BrandtMission`, now or later.**
**Why** The red test is the teaching artifact. It demonstrates *"verification is set up, traceable and
not yet satisfied"* — a state every real programme lives in for most of its life, and one that no
other artifact in this example shows. Wiring it to `Miss!O9 = 6000.43 lb` would turn it green and
demonstrate the opposite lesson (a closed loop from sizing analysis into requirement verification).
Both are worth teaching; one requirement can only teach one of them, and the pending state is the one
this example is otherwise missing.
**Consequences**
1. **TODO B1 is closed, not deferred.** It must stop appearing as an "immediate to-do".
2. **The `TODO:` marker in `F16APhysicalMissionFuel.m:17` is no longer a TODO** — it becomes a
   permanent design note in the TODO's own **D** ("not TODOs — close these") taxonomy, alongside D6.
   Its help block must say *"returns `NaN` by design (D-042)"*, not *"until the /sizing/ analysis is
   connected"*.
3. **Four doc statements promise a wiring that will not happen** and need rewording from *"until
   /sizing/ is connected"* to *"by design"*: `docs/README.md:103`, `docs/README.md:173–174`,
   `docs/05_physical.md:456`, `docs/05_physical.md:616`.
4. **A7 part 1 loses its urgency but not its justification.** It was sequenced before B1 because B1
   would make the fuel roll-up load-bearing. B1 is now never, so that pressure is gone — but the
   hybrid-electric variant argument in D-038 stands entirely on its own, and the stereotype check is a
   correctness fix regardless.
**Traces to** TODO B1 · TODO D6 · `REQ_F16A_P01` · D-038

### D-043 · Cost is a whole-aircraft Measure of Merit only; it never enters the trade study
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED, NOT YET IMPLEMENTED · **Supersedes part of D-005**
**Decision** `physical/F16APhysicalCostModel.m` gets a real DAPCA-IV implementation, sourced from
`sizing/VnV/BrandtF16A/BrandtCost.m`, and populates `MeasureOfMerit.UnitCost_USD` on the `Aircraft`
with a real number. `TradeCandidate.UnitCost_USD` stays `NaN` on all seven candidates. **Cost is
therefore demonstrated as the top-level "minimize cost" objective (`REQ_F16A_026`) and never as a trade
criterion.** This is option (a) of TODO B2.
**Rejected** Option (b), per-candidate `Estimate`-tagged cost deltas. Costing `F110_GE_100` or
`ConventionalTrapWing` means costing aircraft that were never built — the invented-number problem
D-005 refused to solve, and D-030 exists to prevent.
**Why it is the honest one** DAPCA IV is a whole-aircraft weight-and-quantity regression. It has a
defensible answer for "what does this aeroplane cost" and none at all for "what does this wing
candidate cost". Applying it per candidate would dress an invented number in a real model's clothes.
**⚠ Consequence that falsifies a claim made in five places.** The example repeatedly promises that
*"the day a cost model exists, cost re-enters the score with no change to the scoring code"*. Under
this decision **a cost model will exist and cost will still not re-enter**, because
`F16APhysicalTradeStudy` reads `TradeCandidate.UnitCost_USD` — not `MeasureOfMerit.UnitCost_USD` — and
the candidates still carry none. The *mechanism* (D-026's general drop-and-renormalize rule) is
unchanged and still correct; what was wrong is the stated **trigger**. It is not "a cost model
exists", it is "**the candidates carry a cost**". Reword at:
`docs/05_physical.md:198`, `docs/05_physical.md:618`, `docs/06_methodology.md:165`,
`physical/F16APhysicalTradeStudy.m:95`, and TODO B2. (D-005 and D-026 are append-only history and are
superseded in place by this entry, not edited.)
**Consequences**
- The applied trade weights stay `0.50 / 0.25 / 0.25` **permanently**; `UnitCost_USD` is dropped by
  D-026's rule on every future run. TODO **D4** ("`UnitCost_USD` is `NaN` everywhere") narrows to *"NaN
  on the candidates"* and stays true there.
- `MeasureOfMerit.UnitCost_USD`'s `NaN` default (D-032) stays — the generator will write the computed
  value explicitly, and the fail-safe default still guards the path that does not.
- `testCostIsNaNEverywhere` and `testCostMeasureOfMerit` both need revisiting: the aircraft MoM stops
  being `NaN` while the candidates stay `NaN`, and the distinction is now load-bearing rather than
  incidental.
- The cost figure lands with a provenance obligation: a DAPCA IV output computed from this model's own
  rolled-up OEW is `Simulation`, not `Reference`. `BrandtCost`'s own validation target (≈ $68.4M,
  already quoted in `REQ_F16A_026`) is the cross-check, not the value.
**Traces to** TODO B2 · `REQ_F16A_026` · `sizing/VnV/BrandtF16A/BrandtCost.m` · D-005 · D-026 · D-030 · D-032

### D-044 · `REQ_F16A_023`/`024`/`025` get requirement values; `024` is renamed *overturn angle*
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-02 · **Status** ⚠ **SUPERSEDED BY D-046** (2026-08-02, same day) — the definition check below was accepted and acted on. Retained for the arithmetic, which is the exercise brief.

> ⚠ **Read the table below as a brief, not as results.** Two things in this entry do not survive:
> (1) the `SM_TO` = −0.22 %MAC / `SM_land` = +0.27 %MAC pair is a pair of **validation targets** —
> they live in `sizing/VnV/BrandtF16A/tests/test_BrandtBalanceStabControl.m:68,72`, as −0.00219 and
> +0.00272 with `AbsTol` 0.001 — **not** values `BrandtBalanceStabControl` computes. Running it gives
> −0.260 % and +0.206 %; **D-047** measures and corrects this. (2) The real-aircraft figures in the
> exercise brief below carry **no citation** and are flagged inline where they appear.

**Decision** The three balance / stability-and-control requirements stop being `TODO`/`TBD`
placeholders. The user supplies the criteria:

| Req | Now reads | Source | Brandt reference output |
|---|---|---|---|
| `REQ_F16A_023` tipback angle | shall fall between **16° and 25°** | USAF requirement | ≈ 21.5° |
| `REQ_F16A_024` **overturn** angle | shall **not exceed 63°** (USAF); 54° is the USN spec, stated for contrast | USAF / USN spec | ≈ 74.4° |
| `REQ_F16A_025` static margin | **objective**: a *moderately negative* static margin across the operational CG range | design intent (relaxed static stability) | `SM_TO` = −0.22 %MAC, `SM_land` = +0.27 %MAC |

**⚠ The "Source" column says *USAF* / *USN* and cites no document.** The 16–25° tipback band and the
63° / 54° overturn limits arrived as bare figures with no specification number, revision or paragraph.
D-046 kept them out of the model, so nothing downstream depends on them and this is history rather
than a live defect — but a student asked to check Brandt's angles against "the USAF limit" needs to
know **which** limit, and this entry cannot tell them. **The missing identifier is itself part of the
exercise**: establishing what a criterion actually is, and where it is written down, is the step the
definition check below shows cannot be skipped. Do not quote these numbers as sourced.

`REQ_F16A_024` is **renamed** from *rollover angle* to **overturn angle** (a.k.a. turnover angle)
throughout. `025` is an **objective, not a threshold** — the same construct as `REQ_F16A_026` (cost),
so nothing asserts it against a limit. Their `todo` keywords are dropped and TODO **B3** closes.
**Intended teaching point** `024` is expected to **FAIL**, and that is the point: it would be the
example's first requirement the reference aircraft does not meet — a genuinely different lesson from
`REQ_F16A_P01`'s "verification pending" (D-042). One requirement is unsatisfied; the other is
unevaluated.

**⚠ BLOCKING CHECK BEFORE IMPLEMENTATION — the failure may be a definition mismatch, not a design
finding.** `BrandtBalanceStabControl.m:220–221` computes
`rollover_deg = atand(h_main_ft / d_axis)` — a vertical-over-horizontal ratio, i.e. an angle measured
**from the horizontal**. The standard overturn/turnover angle (Raymer §11.4; Currey) is measured
**from the vertical**. With the shipped inputs (`x_nose` 22.0, `x_main` 37.7, `y_main` 6.0,
`h_main` 5.3 ft, `xcg_TO` 26.193 ft): `d_axis` = 1.497 ft, and
`atand(5.3 / 1.497)` = **74.2°** (reproducing the validation target), whose complement is
`atand(1.497 / 5.3)` = **15.8°**. The two sum to exactly 90°. Read against the standard definition the
F-16A **passes the 63° limit with wide margin**; read against Brandt's convention it fails. **The same
number supports opposite verdicts, and only one of them is a fact about the aeroplane.**

Two further observations from the same inputs, which are why this should not simply be resolved by
taking the complement:
- **The gear load split is inverted for a tricycle aircraft.** `gear_main_pct` = 26.7 %,
  `gear_nose_pct` = 73.3 % — i.e. three-quarters of the weight on the nose gear. Normal is 85–95 % on
  the mains (**same sources as the overturn definition above: Raymer §11.4; Currey**). Everything
  geometric downstream (tipback, overturn, CG-relative-to-gear) inherits this.
- **The gear geometry does not match the aircraft.** Brandt's wheelbase is 15.7 ft and track 12.0 ft
  (`y_main` 6.0); the F-16A's are ≈ 13.3 ft and ≈ 7.75 ft — **uncited approximations, not data**.
  Neither appears anywhere in `/sizing/`; the track is about right, but published F-16 wheelbase
  figures vary and 13.3 ft sits at the upper end of them. They are quoted here only to establish that
  the two geometries differ by more than rounding, which is all the exercise needs. **Do not cite
  either as an F-16A dimension** — pinning them down is part of the assignment.

`REQ_F16A_023` has the same class of issue in a milder form: Brandt's
`tipback_deg = atand((h_main + z_tail_bottom) / (L_fuse − x_main))` is a **tail-clearance / rotation**
angle, not Raymer's tipback-from-vertical, which on these same inputs would be
`atand((37.7 − 26.193)/5.3)` = **65°**, far outside the 16–25° band. The 21.5° that sits neatly inside
the USAF band is the tail-clearance figure. The numbers agree with the band under one definition only.

**Required before any of this is written into `generate_f16a_requirements.m`** — `f16a-data` to
confirm, against `readme_bsc.md` and the workbook's own BSC cells, (1) the sign/reference convention of
each Brandt angle, (2) whether the USAF figures the user supplied use the same convention, and (3)
whether the gear JSON block is right. Until then `REQ_F16A_024`'s expected failure is **not
established**, and writing it in as one would put a false claim about a real aircraft into a teaching
model — precisely the failure mode D-007 and the `f16a-data` veto exist to prevent.
**Note on `025`** The Brandt model lands at essentially *neutral* stability (the −0.22 % / +0.27 %MAC
quoted above are the **validation targets**, not computed values — see the head of this entry and
D-047), not the strongly relaxed static stability the F-16A is generally described as having. The
−6 %MAC figure is an illustrative teaching value, not sourced data (D-030). The gap is because
Brandt's neutral point is a simplified approximation (`readme_bsc.md`: *"a simplified neutral point"*,
*"the fuselage destabilizing correction is simplified to a width-scaled offset"*). The **objective** is
right and is the F-16A story the example turns on — it is what `REQ_F16A_L02`'s fly-by-wire rationale
already rests on — but the reference model cannot demonstrate it, and the requirement's "for reference
only" text must say so rather than quote xnp/xcg in feet as it does today.
**Traces to** TODO B3 · TODO D2 · `sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m` · `readme_bsc.md` · D-007

### D-045 · `REQ_F16A_D01`–`D09` stay as a student exercise, and the docs say so
**Stage** 7 · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED — this is a decision NOT to do something
**Decision** The nine derived functional requirements keep their `PLACEHOLDER: quantitative criteria
TBD` text and their `todo` keyword. No acceptance criteria are written for them, by us.
**Why** They are already framed as the exercise — `docs/03_traceability.md:71` calls them *"a to-do
list to make the requirements complete"* — and filling them in would take the exercise away. Unlike
`REQ_F16A_023`/`024`/`025` (D-044), no external specification supplies values, so writing any would be
inventing requirements.
**Consequence** TODO **B4** closes. The one thing that must change is that the docs state this
**explicitly**, so a reader stops looking for missing numbers and understands the blanks are the
assignment. `docs/03_traceability.md`'s derived-requirements section is where to say it. The `TODO`/
`TBD` strings in `generate_f16a_derived_requirements.m` remain covered by TODO **D2** — they are a
content decision, now a settled one, not a code TODO.
**Traces to** TODO B4 · TODO D2 · `requirements/generate_f16a_derived_requirements.m`

### D-046 · The gear angles become a student exercise; only static margin gets criteria
**Stage** 7 (planned) · **Decided by** user · **Date** 2026-08-02 · **Status** DECIDED, NOT YET IMPLEMENTED · **Supersedes D-044**
**Trigger** D-044's blocking check was accepted: the tipback and overturn conventions in
`BrandtBalanceStabControl` do not obviously line up with the USAF/USN figures, and the same number
supports opposite verdicts depending on which convention is meant. Rather than resolve it now, the
ambiguity is turned into the assignment.

**Decision, in three parts.**

**1 · `REQ_F16A_023` (tipback) and `REQ_F16A_024` (overturn) get NO criteria.** They stay
`TODO`/`TBD` placeholders with the `todo` keyword, joining `REQ_F16A_D01`–`D09` as standing student
exercises (D-045). The USAF 16–25° tipback band and the 63°/54° USAF/USN overturn limits are **not**
written into the model.

**2 · The rename `rollover` → `overturn` is deferred with them.** D-044 was going to rename `024` on
the grounds that *overturn/turnover* is the standard term. Held back, because calling Brandt's
quantity "the overturn angle" would **assert the very identification that is in doubt** — whether
`atand(h_main/d_axis)` is an overturn angle at all, or the complement of one. Naming it correctly is
part of the exercise, not a prerequisite to it. The existing wording stands unchanged.

**3 · `REQ_F16A_025` becomes a real, checkable requirement.** Reworded from D-044's qualitative
*"moderately negative"* objective to **relaxed static stability with a two-sided numeric band**:

> The static margin `SM = (x_np − x_cg)/MAC` shall lie between **−6 %MAC and +1 %MAC** across the
> operational CG range (takeoff through landing weight).

This **reverses D-044 on `025`'s construct**: it is no longer an objective-to-minimize in the
`REQ_F16A_026` mould, it is a **threshold requirement with a two-sided band**, and something can
assert it. Its `todo` keyword comes off; `023` and `024` keep theirs.

**Why the band is shaped this way** The lower bound is the design intent — a deliberately relaxed,
near-neutral-to-slightly-unstable configuration that cuts trim drag and buys instantaneous turn rate,
and which is only flyable because the flight control system supplies artificial stability. That is the
same fact `REQ_F16A_L02`'s fly-by-wire rationale already turns on. **−6 %MAC is a figure commonly
repeated for the F-16's subsonic relaxed static stability, and this example cites no source for it**;
`/sizing/` contains no static-margin criterion to check it against, so it is tagged **`Estimate`** and
inventoried in **D-030** like every other invented number here. The +1 % upper bound caps how *stable*
the aircraft is allowed to become — without it, "relaxed" would be satisfied by a conventionally stable
aeroplane; it is pure design intent and equally an `Estimate`.

**The band is a teaching criterion, not a specification.** Nothing about `025` turns on −6 % being the
*right* number — the requirement's job is to be a two-sided threshold something can actually assert
against, and it does that at any plausible lower bound. What would be dishonest is letting a reader
take −6 % away as an F-16A fact, which is why it is tagged rather than quietly used.

**The reference model passes, and it is worth being precise about why.** `BrandtBalanceStabControl`
**computes** `SM_TO` = −0.26 %MAC and `SM_land` = +0.21 %MAC (measured 2026-08-02). Those computed
values sit inside the `AbsTol` 0.001 that
`sizing/VnV/BrandtF16A/tests/test_BrandtBalanceStabControl.m:68,72` allows against its expected values
of **−0.00219 and +0.00272** (−0.219 % / +0.272 %MAC) — which is where that pair of figures lives, and
the only place it lives. It is **not** in `GroundTruth/cell-map.md`, which has no balance / stab-and-control
section at all, and not in `readme_bsc.md`'s own validation list; calling them "the workbook's
validation targets" would name a source that does not carry them. The residual is **an analogous
`.m`-vs-`.xls` discrepancy** to the one D-036 records for the masses — analogous only: the mass gap has
**one** documented cause (`π` versus the spreadsheet's 3.1516), whereas nothing documents a cause for
this one, and `readme_bsc.md:44-46` lists **three** separate approximations any of which could
contribute (the exposed-span vertical-tail MAC correction, the −0.522 ft balance-datum shift, and the
width-scaled fuselage destabilizing correction).

Both figures lie inside [−6, +1], so the requirement is **met at both ends of the CG range**. But it is
met because the band is wide enough to admit a *near-neutral* result — **not** because the model
reproduces the strongly relaxed static stability the F-16A is generally described as having. The
−6 %MAC figure is an illustrative teaching value, not sourced data (D-030). Brandt's neutral point is a
simplified approximation (`readme_bsc.md`: *"a simplified neutral point"*, *"the fuselage destabilizing
correction is simplified to a width-scaled offset"*), and it lands near the *stable* end of the band
rather than the relaxed end. The requirement's reference text must say that, rather than implying the
model demonstrates relaxed static stability. This is a near neighbour of the D-030 composite-fraction
problem — a criterion that a reference figure passes comfortably is worth stating plainly, so nobody
reads the pass as evidence.

**~~Open~~ — RESOLVED as option (b) and IMPLEMENTED; see D-047.** The band is checkable, but **the MBSE model carries no `x_np`, no
`x_cg` and no `MAC`**: the P layer holds mass, composite fraction and fuel capacity, and nothing
aerodynamic. So there are two routes, and the choice has not been made:
- **(a) State the criteria, do not mechanise the check.** `025` keeps its Implement link from
  `Airframe` at L and gains no Verify link. Honest, zero new dependency, and consistent with how the
  example already treats requirements it cannot yet evaluate.
- **(b) Add a third verification test** reading `SM_TO`/`SM_land` from
  `sizing/VnV/BrandtBalanceStabControl.m` read-only, exactly the pattern **D-036** establishes for the
  Brandt masses. It would be **green**, and would make `025` the example's first quantitative
  stability-and-control verification.

**(b) is the better teaching artifact** and reuses machinery D-036 is introducing anyway — but it is a
second `/sizing/` dependency and inherits every constraint D-036 lists (path teardown, loud failure if
`/sizing/` is absent, tolerance). Decide before writing code.
**Consequences**
- TODO **B3** narrows to `025` alone. `023`/`024` move to the exercise list and stay covered by TODO
  **D2**, whose narrowing in the previous revision is reverted to include them.
- The `rollover` → `overturn` sweep across six files (D-044) is **not** performed.
- D-044's arithmetic — the exact complement relationship, the inverted gear load split, the gear
  geometry mismatch — is **retained deliberately** as the brief for the exercise. It is the most
  valuable part of that entry and must not be deleted along with the decision it supported.
**Traces to** TODO B3 · TODO D2 · D-044 · D-045 · D-036 · `REQ_F16A_L02` · `readme_bsc.md`

### D-047 · `REQ_F16A_025` is verified by delegating to `/sizing/`; the sizing code is reached by PATH, not by project membership
**Stage** 7 · **Decided by** user · **Date** 2026-08-02 · **Status** **IMPLEMENTED** — 3/3 passing
**Decision** D-046's open question is resolved as **option (b)**. A third verification test,
`verification/F16AStaticMarginVerificationTest.m`, calls
`sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m` read-only and checks `SM_TO` and `SM_land` against
the −6 %…+1 %MAC band. `REQ_F16A_025` is reworded in `generate_f16a_requirements.m` to carry that band
and its `todo` keyword comes off.

*(Corrected 2026-08-02, Stage-0 gate: this entry originally said `025` "gains the `verify` keyword in
place of `todo`". It does not, and deliberately —* `generate_f16a_requirements.m:228-234` *records
`f16a-requirements`' reasoning: `REQ_F16A_022` and `REQ_F16A_P01` have verification tests and are not
keyworded either, and **the Verify link is the authoritative record that a requirement has a test**. A
generator-written keyword restating that is a derived fact stored where it can drift out of step with
the link — the same failure D-027 and D-040 forbid. The `todo` keyword coming off is real; nothing
replaces it.)*

**This is the first verification in the example that leaves the model, and that is the point rather
than a workaround.** The other two evaluate their requirement *from* the MBSE model —
`F16AMaterialsVerificationTest` rolls up `CompositeFraction`, `F16AFuelVerificationTest` rolls up
`FuelCapacity_lb`. This one cannot: P carries mass, composite fraction and fuel capacity and carries no
neutral point, no CG and no MAC, because **none of those is a property of a part**. Static margin is a
whole-aircraft aerodynamic-and-balance result, so verification is delegated to the analysis that owns
it. What the MBSE model contributes is the traceability — the requirement, the Implement link from the
`Airframe` role, and the Verify link. A requirement's evidence belongs where the evidence lives.

**⚠ The sizing code CANNOT be added to `f16a.prj`, and does not need to be.** The user's instruction
was to make `BrandtBalanceStabControl` part of the project. It cannot be:
- A MATLAB project's files and path entries are **all relative to the project root**
  (`resources/project/**` stores `location="…"` as root-relative; the path entry is
  `<Info location="Root" type="ProjectPath"/>`). `f16a.prj`'s root is the example folder.
  `sizing/VnV/BrandtF16A` is **three levels above it** and a sibling of `mbse/`, so it can be neither a
  project file nor a project path entry.
- There is **no `.prj` under `sizing/`**, so the referenced-project route is unavailable too.
- And membership would buy nothing: TODO **A1b** measured this directly — 41 unregistered files ran
  fine, because everything resolves off the **MATLAB path**. Membership buys the Project browser,
  dependency analysis, `runChecks` and packaging, **not the ability to run anything**.

The test therefore adds the folder itself, via a **`matlab.unittest.fixtures.PathFixture`** rather than
a bare `addpath`. That choice is deliberate and is the one thing here that differs from the rest of the
example's tests: they `addpath` sibling *layer* folders without cleanup, which is harmless because
those folders are the project's own. Reaching three levels out is not harmless — leaving `sizing/` on
the path would let a later suite resolve a `Brandt*` name it never asked for, making results depend on
which suites ran first. The fixture unwinds it, and this was verified (the folder is absent from
`path` after the run).

**Guarantees the test makes**, all of them D-036's constraints applied here:
1. **Read-only.** The Brandt classes compute in memory; the only file touched is
   `GroundTruth/f16a_geometry.json`, read. Nothing in `/sizing/` is written (house rule 4).
2. **Loud failure if `/sizing/` is absent** — an `assertTrue` naming the missing folder and the reason.
   It does **not** skip and does **not** fall back to a transcribed number: a verification test that
   quietly stops verifying reports success it did not earn.
3. **A dependency check separate from the requirement check.** `testAnalysisProducedUsableMargins`
   fails first if the fields are missing or non-finite, so *"the aircraft violates `REQ_F16A_025`"* and
   *"the analysis that evaluates it is broken"* cannot arrive looking identical.
4. **Both ends of the CG range asserted.** The requirement says "across the operational CG range", so
   takeoff and landing are separate test methods — checking only takeoff would verify half a
   requirement and report it as all of one.
5. **The band appears once**, as class constants, and both checks build their constraint from it, so it
   cannot be widened in one test and left alone in another.
6. **W_TO = 31,377 lb is declared, not assumed** — a static margin is meaningless without a stated
   weight.

**Result — 3/3 passing.** Measured: `SM_TO` = **−0.260 %MAC**, `SM_land` = **+0.206 %MAC**, both inside
[−6, +1]. Also verified that the constraint rejects −0.09 and +0.05 in the two directions, so the band
is doing work rather than accepting everything.
**Correction to D-046 arising from actually running it** D-046 quoted −0.22 % / +0.27 % as if the
analysis produced them. It does not: `BrandtBalanceStabControl` computes **−0.260 % / +0.206 %**. The
−0.22 / +0.27 pair is the **expected value in the sizing suite's own test** —
`sizing/VnV/BrandtF16A/tests/test_BrandtBalanceStabControl.m:68,72`, as −0.00219 and +0.00272 with
`AbsTol` 0.001 — and that file is the **only** place in the repository it appears. It is not in
`GroundTruth/cell-map.md` (no balance / stab-and-control section) and not in `readme_bsc.md`'s
validation list, so "the workbook's validation targets" was the wrong attribution as well as the wrong
category. The computed values sit inside that `AbsTol`, so the sizing suite passes — this is **an
analogous `.m`-vs-`.xls` discrepancy** to D-036's mass gap, but only analogous: D-036's has a single
named cause, this one has none, and `readme_bsc.md:44-46` offers three candidate approximations
without attributing the residual to any of them. D-046 and the requirement text are corrected; the
conclusion is unchanged — near-neutral, comfortably in band, passing from the *stable* end.
**NOT DONE, and required before this is real in the tool**
- `requirements/f16a.slreqx` has **not** been regenerated, so the shipped requirement still reads
  `TBD`. Regenerating it means re-running the **whole documented chain** (README "Regenerate the
  artifacts"), because `slreq.new` builds a fresh set and the F/L/P models' Implement links resolve
  into the old one. That is a heavy, artifact-writing operation and is left as an explicit step.
- The **Verify link** `REQ_F16A_025 → F16AStaticMarginVerificationTest` must be added **by hand** in
  the Requirements Editor (D3 / README "Verification links are added manually"), and
  `F16AOpenForReview` must then load the third `~m.slmx` alongside the two **A2b** adds.
- `f16a.prj` should register the new test file (it is inside the project root, unlike the sizing code),
  and `runChecks(currentProject)` should be 12/12 afterwards.
**Traces to** TODO B3 · TODO A2b · D-046 · D-036 · TODO A1b · `REQ_F16A_025` · `REQ_F16A_L02`

### D-048 · The −6 %MAC band keeps its numbers and loses its authority
**Stage** 0 gate · **Raised by** f16a-data (**VETO**) · **Decided by** orchestrator + f16a-scribe ·
**Date** 2026-08-02
**Problem found** D-046 introduced a two-sided static-margin band and D-047 built a passing test
against it, but **−6 %MAC entered the model with no tag and no source**. `f16a-data` established that
it can be none of the three sourced provenance kinds: not `Reference` (there is no static-margin
criterion anywhere in `sizing/VnV/BrandtF16A/`), not `Datasheet` (no specification is cited), not
`Simulation` (nothing computes it). Meanwhile two entries stated it as a **fact about the real
aeroplane** — *"the ≈ −6 %MAC relaxed static stability the F-16A is actually known for"* and *"…the
real aircraft had"* — which is the D-025 overclaim shape exactly: a defensible teaching value dressed
in the language of sourced data. This is the same class of failure as D-030 itself, one requirement
over.

**Decision — three parts, and the first one is what makes the other two honest.**
1. **The band is unchanged.** −6 %MAC to +1 %MAC stands exactly as D-046 set it, and D-047's test
   stands as built. Nothing about the criterion was wrong; what was wrong was its *standing*.
2. **It is tagged `Estimate` and inventoried in D-030.** The band has no stereotype and therefore no
   `DataProvenance` slot to carry a tag, so D-030's table carries it instead — the same fallback the
   fuel split needed before `FuelTank` gained the property (D-023). This is the first entry in that
   inventory that is a **requirement threshold** rather than a component property.
3. **One canonical sentence, used verbatim everywhere.** Every artifact that mentions the figure says:
   *"the strongly relaxed static stability the F-16A is generally described as having. The −6 %MAC
   figure is an illustrative teaching value, not sourced data (D-030)."* Agreed with `f16a-vnv` and
   `f16a-requirements` so the log, the test and the requirement text cannot drift into three different
   hedges.

**Alternatives considered**
- *Drop the lower bound and make `025` one-sided* (`SM ≤ +1 %MAC`). Rejected: it would remove the
  untagged number by removing the requirement's teaching content. The two-sided band is the point —
  it is what makes "relaxed" falsifiable in both directions.
- *Find a source and tag it `Datasheet`.* Rejected for now, not on principle: no citation was to hand
  at the gate, and inventing a plausible-looking one is worse than an honest `Estimate`. If a
  specification for the F-16A's design static margin is ever located, this row can be re-tagged and
  the canonical sentence retired.
- *Say nothing and let the band stand untagged.* Rejected — it is a house-rule-1 violation and
  `f16a-data` holds a veto.

**Consequences**
- Four further corrections fell out of the same audit and are made in place in the uncommitted
  entries: the −0.22 % / +0.27 % pair is re-attributed to
  `sizing/VnV/BrandtF16A/tests/test_BrandtBalanceStabControl.m:68,72` (it is in no workbook artifact);
  the *"same `.m`-vs-`.xls` gap as D-036"* claim is softened to *analogous*, because the mass gap has
  one documented cause and this one has none (`readme_bsc.md:44-46` lists three candidates); D-036's
  *"four levels up"* becomes **three**; and D-036 gains the two mapping-table trap closures
  (`BrandtAirframeMass_lb` ← `W_structure_lb`, `W_airframe_lb` deliberately unmapped) plus the
  `W_other_lb` tolerance note and the `726.87` → `725.87` flag.
- **A fifth correction, found while checking the canonical wording landed.** D-047 and TODO B3 both
  claimed `REQ_F16A_025` "gains the `verify` keyword in place of `todo`". The generator does not add
  one, deliberately — `generate_f16a_requirements.m:228-234` argues that the **Verify link** is the
  authoritative record that a requirement has a test, and that a generator-written keyword restating
  it is a derived fact stored where it can drift out of step with the link, which D-027 and D-040
  forbid. `REQ_F16A_022` and `REQ_F16A_P01` are consistent with this: both have verification tests and
  neither is keyworded. The `todo` coming off is real; nothing replaces it. Both claims are corrected.
  Worth noting how it was caught: the docs and the code disagreed, and the code was right — which is
  the direction this log is supposed to catch, since a doc claiming a keyword the model does not carry
  is the same defect class as a comment claiming a provenance entry that does not exist (D-030).
- **A precedent worth naming:** a *requirement's own acceptance criterion* is a number, and house
  rule 1 applies to it. Until now the provenance discipline had only ever been exercised on component
  properties, and the band slipped through because it lives somewhere no stereotype reaches. Any
  future numeric threshold written into a requirement gets a D-030 row.
**Traces to** D-030 · D-046 · D-047 · D-007 · D-023 · `REQ_F16A_025` ·
`verification/F16AStaticMarginVerificationTest.m` · `requirements/generate_f16a_requirements.m`

### D-049 · Where a reader who clicks a *rejected* kind lands, now that the requirement holds no verdict
**Stage** 1 · **Decided by** orchestrator + f16a-scribe · **Date** 2026-08-02
**Problem found** D-040 makes the decision requirement a pure question, which falsifies the *stated
purpose* of D-027 in four documentation sites. `DecisionRef` is written on every kind so that "a
reader who clicks the rejected kind should land on the document that says why it lost" — and after
D-040, no requirement says why anything lost. Two of the four sites were not on the work list
(`docs/05_physical.md:239` and `docs/04_logical.md:273`, line numbers as at the Stage-0 commit); both
repeat the same sentence, which is how a claim that is wrong once becomes wrong in four places.
**Decision** D-027's **mechanism is unchanged** — every kind of a role still carries `DecisionRef`.
Its stated purpose is restated as a **two-hop trail**: rejected kind → the decision requirement,
which poses the choice and names where the answer is → the rejected **candidate** at P that realizes
that kind, whose `Rationale.SourceKind` is `TradeAlternative` and whose `Justification` states the
deficit, the criterion it lost most on and by how much. The docs now say the loser "reaches the
requirement rather than a `'TBD'`", never "lands on the record of why it lost".
**Alternatives considered**
- *Drop `DecisionRef` from the losers*, since the requirement no longer explains the loss. Rejected:
  it is the **only outbound reference a rejected kind carries** — `SolutionOption` holds nothing else,
  the Implement link is made only from the winner, and the realization allocation runs role → candidate
  and never touches a kind. Removing it returns the loser to the `'TBD'` dead end D-027 closed.
- *Have the trade study write the loss reason onto the losing kind at L.* Rejected for the reason
  D-040 rejected its own option (b), one layer over: a second copy of the verdict, in a place it can
  drift from the copy at P. L is also the layer forbidden to hold trade numerics
  (`testKindsCarryNoTradeNumerics`).
**Consequences** D-027's *purpose* is narrower than it was written to be, and the docs say the
narrower thing. Its *value* is arguably higher: it is now the single edge keeping a rejected kind
attached to the audit trail at all. The honest caveat, which the docs state: the trail's second hop is
a **property match** (`TradeCandidate.RealizesKind` = the kind's name), not a link the tool can
follow — `F16APhysicalArchitectureTest` asserts that `RealizesKind` names a kind that exists under its
role in the L model, but a human reader makes that hop by hand.
**Traces to** D-027 · D-040 · D-037 · D-002 · `docs/03_traceability.md` · `docs/04_logical.md` ·
`docs/05_physical.md` · `docs/06_methodology.md` · `physical/F16APhysicalTradeStudy.m` (`loserSentence`)

### D-050 · The programme history moves to the docs, labelled history and not rationale
**Stage** 1 · **Decided by** orchestrator + f16a-scribe · **Date** 2026-08-02
**Problem found** A6 rewrote `REQ_F16A_L01`–`L03` into pure questions (D-037, D-040) and in doing so
deleted real teaching content from the example: the Lightweight Fighter competition and the
YF-16/YF-17 flyoff, *"the first production fighter to fly a fly-by-wire flight control system"*, and
the statement that the winning combination **is** the production F-16A configuration. Two of the three
already had a second home in `docs/04_logical.md`'s "Why these are the credible options" table; the
production-configuration claim did not, surviving only in `testProductionConfigurationWins`'s comment
and in `06_methodology.md`'s retrodictive-honesty bullet. Losing it silently would have made A6 a net
cost.
**Decision** The historical framing lives in **prose, in `docs/04_logical.md`**, in a new
`#### History, not rationale` subsection under the existing options table — never in a requirement
`Description`, a kind name or a `Rationale`. It is written to three rules:
1. **Labelled as history.** The three facts are stated as facts about an aircraft that exists, with
   `testProductionConfigurationWins` named as where the model pins them (identities only, not scores).
2. **Explicitly not the model's reason.** The section states that no criterion, value function or
   weight in the trade reads a name — even the ratio baselines key on the role's
   `DataProvenance = Reference` candidate — so renaming all seven candidates changes nothing, and a
   reader who treats "that is what really happened" as the reason has put back the premise A6 removed.
3. **The converse trap named too.** That independence is not evidence about aeroplanes: the parameters
   were chosen by someone who knew the answer, the exercise is retrodictive, and the reader is sent to
   `06_methodology.md` for the accounting that 0.75 of every score is declared opinion.
**Alternatives considered**
- *Let it go.* Rejected: the programme history is why the F-16A is a good case study, and D-020 never
  banned it — `testKindsAreTechnologyNeutral` is executable against **model artifacts**, not prose.
- *Keep it in the requirement `Rationale`, which is not the `Description`.* Rejected: it is the same
  defect one field over. A rationale that recites the real outcome still lets a reader read the answer
  out of the requirement, which is exactly what D-040 exists to make impossible.
- *Home it in `05_physical.md`, next to the trade.* Rejected on placement: a reader meets the options
  at L and forms the "why did this win" question there, so the caveat has to arrive with the options
  rather than one layer later. `06_methodology.md` keeps the deeper retrodictive argument and is
  linked, not duplicated.
**Consequences** D-020's deferred note (L02's "analog fly-by-wire" wording, L01's YF-16/YF-17 framing)
is now closed on both sides: removed from the model by A6, preserved in the docs by this entry. The
two historical claims carry **no `DataProvenance` tag** and need none — neither is a number entering
the model — but the section says so out loud, because after the D-048 veto an untagged assertion that
reads like design justification is the failure mode being guarded against.
**Traces to** D-037 · D-040 · D-020 · D-015 · D-030 · `docs/04_logical.md` ·
`physical/F16APhysicalArchitectureTest.m` (`testProductionConfigurationWins`) · `docs/06_methodology.md`

### D-051 · The static margin must be NEGATIVE, and the reference model fails it at landing
**Stage** 2 · **Decided by** user · **Date** 2026-08-03 · **Supersedes part 3 of D-046** · **Narrows
D-030's static-margin row**
**Decision** `REQ_F16A_025`'s two-sided **−6 … +1 %MAC** band is replaced by a **negative-margin**
criterion with the same floor:

> **−6 %MAC ≤ `SM` < 0**, where `SM = (x_np − x_cg)/MAC` — lower bound **inclusive**, upper bound
> **strict** — at **both ends** of the operational CG range, takeoff *and* landing.

The requirement's own wording lives in `generate_f16a_requirements.m`; this entry states the criterion,
not the prose. What changed is the **upper bound**: `+1 %MAC` becomes a strict zero, so a positive
static margin is now a violation rather than a small allowance. `SM_TO` = **−0.2602 %MAC** meets it;
`SM_land` = **+0.2065 %MAC** violates it, so `F16AStaticMarginVerificationTest` goes **3/3 → 2 pass,
1 fail** — deliberately, and permanently.

**Why: the example teaches two verification outcomes and needs the third.** A requirement can be met,
or not evaluated at all, or **evaluated and not met**. Until now this example shipped the first two
and called them by their colour:

| Requirement | Test | State | What it teaches |
|---|---|---|---|
| `REQ_F16A_022` | `F16AMaterialsVerificationTest` | green | requirement met, evidence in the model |
| `REQ_F16A_P01` | `F16AFuelVerificationTest` | red — **unevaluated** | verification set up and traceable, nothing computed yet (`NaN`, D-042) |
| `REQ_F16A_025` | `F16AStaticMarginVerificationTest` | red — **violated** | evaluated, and the design does not meet it |

The middle state is the one a real programme spends most of its life in, and no artifact here showed
it. **The two reds are not the same red**, and telling them apart is the lesson: a reader who counts
"two tests fail" and stops has missed the whole of it.

**D-044 saw this and D-046 lost it — that is the honest way to record this entry.** D-044 wanted
`REQ_F16A_024` to fail on purpose: *"it would be the example's first requirement the reference
aircraft does not meet … One requirement is unsatisfied; the other is unevaluated."* D-046 then
withdrew `023`/`024` to the exercise list — correctly, because D-044's own blocking check showed the
gear-angle conventions are ambiguous and *"the same number supports opposite verdicts"* — and gave
`025` a band wide enough that the reference figure fitted inside it. The lesson went out with the
requirement that was carrying it, and nothing recorded the loss. Stated plainly: **the previous
decision chose a criterion the model passes; this one chooses the criterion the physics implies and
accepts the red.** `025` is the right carrier for it precisely where `024` was the wrong one — a sign
test on a computed margin has no convention to argue about.

**Provenance: one invented number instead of two — a real improvement, and a modest one.** D-046's
band had two invented ends. The upper one is now gone on principle rather than by preference: **zero
is a definition, not a figure.** Relaxed static stability *is* a negative static margin, so the strict
`< 0` is where the sign changes and nothing about it was chosen. The lower bound is a different case
and must not be described as if it were the same one:

| End | Now | Provenance |
|---|---|---|
| Upper, `< 0` | strict zero | **definition** — not a figure, nothing to tag, not inventoried |
| Lower, `−6 %MAC` | unchanged | **`Estimate`, still uncited, still in D-030** — the row is narrowed, not retired |

So `f16a-data`'s Stage-0 veto and **D-048** stand almost entirely: the `−6 %MAC` figure keeps its tag,
keeps its D-030 row, and keeps D-048 part 3's canonical sentence, which still has a subject to hedge.
What D-048 loses is only its part-1 claim that the band is *unchanged*, at the upper end alone.

**The floor's `Estimate` tag is the price of the requirement being meaningful at the unstable end, and
this entry pays it knowingly.** `f16a-requirements` argued the other way, and argued it well: **any**
floor is an uncited claim about how much instability the flight control system can stabilize, so a
bare *"negative"* would leave `REQ_F16A_025` resting on no invented number at all — a provenance
property nothing else in this example can claim. That reasoning is correct. It was **reversed within
the stage** because a requirement satisfied by an aeroplane no FCS could fly is not a useful
requirement: without a floor, an arbitrarily unstable design passes. The floor is therefore not free
and is not presented as free — it buys a meaningful lower end and costs one `Estimate`, and the trade
is recorded here so nobody has to re-derive it.

**Second-order, and the reason the floor earns its keep:** `REQ_F16A_L02`'s fly-by-wire justification
implicitly assumes **bounded** instability — artificial stability is what makes a relaxed-stability
aeroplane flyable, and no control system supplies it without limit. With no floor, that premise is
carried by prose and by nothing assertable. With `−6 %MAC`, the requirement carries it.

**Why the model fails at landing — and what the failure is a property of.** Burning fuel and releasing
stores moves the CG **forward**, so landing is the forward, *most stable* end of the operational range
and is where the requirement bites. Measured 2026-08-03 by running `BrandtBalanceStabControl` at
`W_TO` = 31,377 lb:

| Condition | `x_cg` (ft) | End of CG range | `SM` (%MAC) | Verdict |
|---|---|---|---|---|
| Takeoff | 26.1979 | aft | **−0.2602** | meets |
| Landing | 26.1451 | forward | **+0.2065** | **violates** |

`x_np` = 26.1684 ft falls between the two, which is why the margins straddle zero at all — the CG
crosses the neutral point during the mission, and 0.0528 ft of travel is all it takes.
**The failure is a property of the reference model, not of the F-16A.** Brandt's neutral point is a
simplified approximation (`readme_bsc.md`: *"a simplified neutral point"*, *"the fuselage
destabilizing correction is simplified to a width-scaled offset"*), which is why this model drifts
*stable* at light weight where the real aeroplane does not. Do not quote the landing violation as a
finding about the aircraft; quote it as what a requirement doing its job looks like against an
approximate analysis.

**Alternatives considered**
- *Keep D-046's `+1 %MAC` allowance.* Rejected — that is the decision being corrected. A criterion
  widened until the reference figure fits inside it is not a criterion, and D-046 said so itself:
  *"it is met because the band is wide enough to admit a near-neutral result."*
- *A bare "negative" with no floor.* `f16a-requirements`' proposal, argued on provenance and rejected
  on meaning — see the paragraph above. It is the strongest alternative here and the reasoning is
  worth keeping, not the outcome.
- *Wait for a **sourced** floor before requiring one.* Rejected: there is nothing to wait on. No
  specification for the F-16A's design static margin has been located, and the requirement would sit
  unbounded below in the meantime. The honest move is the one D-048 already made — keep the figure,
  tag it `Estimate`, inventory it, and never quote it as F-16A data.
- *Make `REQ_F16A_024` the failing requirement instead*, as D-044 intended. Rejected by D-046 and still
  rejected: until the overturn-angle convention is settled the failure is **not established**, and
  writing in a failure that might be a definition mismatch would put a false claim about a real
  aircraft into a teaching model. `025` fails on arithmetic nobody disputes.
- *Add a fourth, deliberately-failing requirement and leave `025` green.* Rejected: a requirement
  invented to fail teaches less than a real one that does, and the example already carries `025`.

**Consequences**
1. **`F16AStaticMarginVerificationTest` is 2 pass / 1 fail, by design.** The suite sweep stays at
   **106 cases** and goes from **1 by-design red to 2**. Anything that says "one intentional failure"
   is now wrong.
2. **`testAnalysisProducedUsableMargins` still passes, and that is the point.** D-047 guarantee 3 built
   a dependency check so that *"the aircraft violates `REQ_F16A_025`"* and *"the analysis that
   evaluates it is broken"* could never arrive looking identical. That distinction was described but
   never exercised; it is now **demonstrated**. A green dependency check beside a red requirement check
   is what proves the landing failure is a real violation and not a broken reader.
3. **D-047's headline result is superseded**, not corrected: *"Result — 3/3 passing"* was true of the
   band it was testing. The test's machinery, its `PathFixture`, its six guarantees and its read-only
   contract are all unchanged.
4. **D-030's static-margin row is narrowed, not retired** — two invented figures become one. The
   inventory stays at **20 rows**, and the convention for annotating a row that changes is set in the
   note under that table (the first time one has).
5. **Docs.** The three-state distinction is stated where a reader meets the tests
   (`docs/README.md` run block and verification discussion) and where they meet the requirement
   (`docs/01_requirements.md`, `025`). TODO **B3**'s account of `025`, **D2**, **D5** and **D6** are
   all updated.
6. **The Implement link and `REQ_F16A_L02` are untouched.** A negative static margin is still what the
   fly-by-wire decision rests on; the requirement now states that premise instead of a band around it.
7. **D-048 part 3's canonical `−6 %MAC` sentence must survive the rewrite.** The floor is still an
   `Estimate`, so the sentence still has a job, and it must still read identically in the requirement
   `Description`, `F16AStaticMarginVerificationTest`'s help block, `docs/01_requirements.md` and this
   log. A rewrite that drops it on the way past would reopen D-048 without deciding anything.
   *Measured during this stage: it was independently **paraphrased twice** — by `f16a-requirements` in
   the requirement text and by `f16a-vnv` in the test help block, neither seeing the other's copy, both
   versions an improvement in isolation. Both reverted. Only the requirement-artifact copy is guarded
   by a test, and it is the one that held. (A third paraphrase was reported and disproved — that copy
   was verbatim but line-wrapped, so the grep looking for it returned nothing.) The finding, the three
   ways a text check gets this wrong, and the open question of where a cross-artifact guard should
   live are TODO **A14**.*
8. **The Verify link `REQ_F16A_025 → F16AStaticMarginVerificationTest` was hand-made on 2026-08-03**
   and is unaffected by the reword (ids and their order are unchanged, so it resolves — the Stage-2
   measurement). All three verified requirements are now linked, and two of the three links point at
   a red test. That is the correct state: a Verify link records that a requirement is checked, not
   that it passed.
**Traces to** `REQ_F16A_025` · `REQ_F16A_L02` · `verification/F16AStaticMarginVerificationTest.m` ·
`requirements/generate_f16a_requirements.m` · D-044 · D-046 · D-047 · D-048 · D-030 · D-042 · TODO B3
