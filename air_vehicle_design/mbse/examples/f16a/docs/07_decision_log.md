# Decision log

> One entry per decision, including decisions *not* to do something. What was decided and one line of
> why — not the argument that got there. Ids are stable: a superseded entry leaves a redirect.
> Owner: `f16a-scribe`. Audited by `f16a-data` — every invented number appears in **D-030**.
> Who is who: [`08_agent_team.md`](08_agent_team.md) · method grounding:
> [`06_methodology.md`](06_methodology.md).
>
> **OPEN** marks a decision that has been made but not yet built.

---

### D-001 · The Logical layer presents options; the Physical layer decides
L presents technology-neutral architectural *kinds* — no numbers, no winner. P holds concrete
parameterized candidates, runs the trade, decides, and calls back to set the active kind at L.
**Why** Trading at L forces technology-specific numbers onto an architecture the method literature
requires to be solution-independent. `F16ALogicalTradeStudy.m` retired; L ships unresolved until P runs.

### D-002 · Candidates are modelled as in-model variant choices
Each candidate is a stereotyped variant choice inside the P model, not an external table.
**Why** The losing alternatives must stay visible and auditable in the architecture. A role with more
than one candidate is not a part — it is an open question, and it is modelled as one.

### D-003 · Variant depth: wrap the role, detail only the winner
`Airframe`, `Propulsion/Engine` and `FlightControls` are variant components. The winning candidate
carries the Brandt decomposition; losers are single lumped blocks with `Estimate` masses.
**Why** Full symmetry would mean inventing six part masses and six composite fractions for an aircraft
that was never built. You only decompose what you selected. 23 → 30 components.

### D-004 · The trade is flat across all candidates of a role
All candidates for a role are scored in one pass; the global best wins and its `RealizesKind` becomes
the selected logical option. **Why** Two-stage selection would let a kind win before its candidates
were compared.

### D-005 · Cost stays NaN and is excluded from scoring
`UnitCost_USD` is `NaN` on candidates and on the aircraft MoM, and drops out of the weighted score.
**Why** Inventing cost figures teaches the wrong lesson; a visible `NaN` is an honest "pending".
*Partly superseded by **D-043** — the aircraft MoM gets a real cost; the candidates never do.*

### D-006 · Every physical part carries a queryable Rationale
`Rationale { SourceKind, Justification, TraceRef }` on every component that can carry a stereotype.
**Why** A code comment is not queryable, and "why does this part exist?" is the question MBSE
traceability exists to answer. Vocabulary: `RealizesFunction | SatisfiesRequirement | TradeWinner |
TradeAlternative | ConstraintDriven | SupportingInfrastructure`.

### D-007 · Every candidate parameter set carries a DataProvenance tag
`DataProvenance ∈ {Datasheet, Reference, Estimate, Simulation}`. Illustrative teaching numbers are
allowed only as `Estimate`, and every `Estimate` is listed in **D-030**. `f16a-data` holds a veto.

### D-008 · The logical profile is renamed to reflect that L no longer trades
`F16A_LogicalTrades.xml` → `F16A_LogicalOptions.xml`; stereotype `TradeCandidate` →
`SolutionOption { Selected, DecisionRef }`. **Why** A profile called *Trades* in a layer that must not
trade is the confusion D-001 removes.

### D-009 · The inlet duct is common to all engine candidates
`InletDuct` is a plain part beside the `Engine` variant, shared by all candidates; the twin-engine
surrogate's mass is not adjusted to absorb an inlet delta. **Why** Duplicating it triples a part for no
lesson, and pricing the delta invents a number. The simplification is stated in `05_physical.md`.

### D-010 · The L01–L03 link assertion lives in the P test, not the L test
**Why** The links are created by the physical trade study; asserting them at L would make the L suite
depend on whether P has run.

### D-011 · Stereotype properties use real MATLAB enumerations
`DataProvenance` and `SourceKind` are enumeration-typed, not free strings. **Why** A validated
vocabulary and a Property Inspector dropdown instead of typo-prone strings. Costs two `classdef` files
on the project path.

### D-012 · The native roll-up needs no "active" filter; hand recursions do
The `instantiate`/`iterate` mass roll-up stays a plain postorder sum; architecture-side recursions
descend into `getActiveChoice` at a variant. **Why** The analysis instance contains only the active
choice, while an architecture-side walk sees every choice and would double-count.

### D-013 · Variant role wrappers are exempt from part stereotypes
`PhysicalItem` and `Rationale` go on variant *choices* and plain components. **Why**
`applyStereotype` errors on a `VariantComponent`. The variant node still reports a rolled-up mass.

### D-014 · The example is maintained by a specialist agent team with approval gates
Nine roles, staged increments, a human gate at the end of every stage, one commit per stage.
**Why** V&V separated from implementation means a generator and its test cannot be wrong the same way.
See [`08_agent_team.md`](08_agent_team.md).

### D-015 · Scoring uses declared value functions, not min–max normalization
**Why** Min–max is degenerate at n = 2 (every criterion normalizes to {0,1}, so a score is just the sum
of the weights won) and set-dependent — adding a candidate silently rescores the others.

| Criterion | Value function | Declared scale |
|---|---|---|
| `Benefit` | `v = B / 10` | 1–10 (0 = unset, D-033) |
| `TRL` | `v = (TRL − 1) / 8` | 1–9 |
| `Mass_lb` | `v = M_baseline / M` | ratio to the role's Brandt baseline |
| `UnitCost_USD` | — | `NaN`, dropped (D-005, D-026) |

Baselines are `Reference` Brandt figures: Propulsion 4730.23 lb, Airframe 6722.88 lb, FlightControls
472.44 lb. Applied weights `0.50 / 0.25 / 0.25`, derived at run time by D-026.

### D-016 · Variation points are decided independently (acknowledged simplification)
Three binary kinds form a 2×2×2 box; the example evaluates three independent pairs, not 8 combinations.
**Why it is a simplification** The choices interact — relaxed static stability only pays off *with*
fly-by-wire. Stated plainly in `06_methodology.md` rather than glossed over. Extending it is **C3**.

### D-017 · "Technology-neutral", not "solution-agnostic"
L options are technology- and vendor-independent. **Why** `SingleEngine` vs `TwinEngine` *is* an
architectural commitment; ARCADIA's wording is "technology neutral". Strict solution-independence is
the F layer (`ProduceThrust`).

### D-018 · The word "MDAO" stays out of the code
Files, functions and comments say **trade study**. **Why** A weighted sum over a handful of discrete
candidates is not MDAO — no optimizer, no design-variable continuum, no coupled analysis. The
literature is cited in `06_methodology.md` as the pattern being followed.

### D-019 · The L generator does not require the decision-requirement set
**Why** L no longer reads or links `REQ_F16A_L01`–`L03` — P does. Erroring on their absence would
re-couple L to whether P has run.

### D-020 · Kinds are named for topology, and the test enforces it
`SingleEngine_F100` → `SingleEngine`, `TwinEngine_LWF` → `TwinEngine`, `AnalogFBW` → `FlyByWire`.
`testKindsAreTechnologyNeutral` fails on any digit or any of `F100 F110 PW GE LWF Analog`.
**Note** The token check is deliberately **case-sensitive**: `ConventionalTrapWing` contains `pW`.

### D-021 · Unset trade parameters must fail safe, not fail cheap
`UnitCost_USD` defaults to `NaN`; `TRL` cannot hold `NaN` (`int32`), so it defaults to `0` — outside the
1–9 scale — and the trade **errors** rather than scoring it. **Why** A default that silently produces a
*plausible* number is worse than one that stops the run. A `$0` cost under a ratio value function is not
neutral, it is unbeatable.

### D-022 · `04_logical.md`'s trade section was rewritten in Stage 3, not Stage 6
**Why** It documented the deleted L trade study together with six invented `UnitCost_USD` figures — a
live D-005 violation in a published teaching doc, one file away from the real candidate parameters.

### D-023 · The fuel split is an Estimate and is tagged as one
The three tanks carry 2100 lb each (6300 total); Brandt's figure is **6296.30 lb** (`Wt!B6`), so an
even split of a rounded number is an `Estimate` in substance. `FuelTank` gained `DataProvenance`.

### D-024 · Realization retargets at candidates: 15 edges become 14
A role is realized by the candidates that could fill it, not by the variant wrapper. The 1→many
teaching moment moves from `Airframe` to `PropulsionSystem` (3 engine candidates + the shared inlet).

### D-025 · `DataProvenance` qualifies the mass, not the judgement
A candidate carries one tag and it qualifies its **`Mass_lb`**. `Benefit` and `TRL` are judgement on a
declared scale even on a `Reference` candidate. **Why** Otherwise `Reference` on `F100_PW_200` would
imply its Benefit of 8.2 came from Brandt. Overclaiming provenance is what D-007 exists to prevent.

### D-026 · Dropping a criterion is a general rule, not a cost special case
The trade drops **any** criterion no candidate of a role carries a value for, and renormalizes.
`0.40/0.20/0.20/0.20` → `0.50/0.25/0.25`. Cost falls out of that rule; it is not named as a special
case. **The trigger for cost re-entering is that the candidates carry a cost — not that a cost model
exists** (D-043).

### D-027 · The callback keys on the kind, and `DecisionRef` is written on every kind
The write-back resolves the L kind from the winner's `RealizesKind`, never the candidate name — the
mapping is many-to-one. `DecisionRef` is set on losers too, so a rejected kind is not a dead end
(see D-049 for where that trail actually leads).

### D-028 · Decision links are rebuilt, not created-if-absent
The trade removes any existing inbound link whose source is the L model, then creates one fresh.
**Why** Create-if-absent leaves the *previous* winner's link in place when the winner changes, so two
kinds would claim to implement the same decision. Scoping to L sources leaves hand-made Verify links alone.

### D-029 · Roll-ups do not write during tests
`F16APhysicalMassRollup` takes `Persist` (default `true`); the suite always calls it read-only.
**Why** A suite writing to the model it tests can repair a generator defect it should be catching, and
leaves a dirty working tree.

### D-030 · Inventory of every invented number

Every number below is **invented for teaching**. None is F-16 data. Do not cite any of them. This entry
is what D-007 and house rule 1 point at; a new invented number is added here.

| Value | Component | Property | Tag | Why this number |
|---|---|---|---|---|
| 7300 lb | `ConventionalTrapWing` | `Mass_lb` | Estimate | No such aircraft was built. Assumed ~8.6% heavier than the blended delta — a discrete wing-body is structurally less efficient |
| 5100 lb | `F110_GE_100` | `Mass_lb` | Estimate | The F110 is real but post-dates the F-16A; installed mass scaled off the F100 figure |
| 6400 lb | `TwinEngine_Surrogate` | `Mass_lb` | Estimate | Stands in for a twin installation of the YF-17 class. Not a specific engine pair |
| 700 lb | `HydroMechanical` | `Mass_lb` | Estimate | A conventional control system for this class, assumed heavier than the fly-by-wire group |
| 0.12 | `ConventionalTrapWing` | `CompositeFraction` | Estimate | Aluminium-dominant conventional airframe |
| 0.15 / 0.10 / 0.55 / 0.70 / 0.05 / 0.50 | Wing / Fuselage / HorizTail / VertTail / Nacelles / Strakes | `CompositeFraction` | Estimate | Grounded in real F-16 composite usage — **and tuned so the mass-weighted fraction lands just inside `REQ_F16A_022`'s 20% cap.** Numbers chosen to make a requirement pass must not look sourced |
| 9.5 / 6.5 · 9.0 / 6.0 · 8.2 / 8.6 / 7.8 | the 7 candidates | `Benefit` | judgement (D-025) | Declared 1–10 scale. The relative ordering carries the teaching; the absolute values carry nothing |
| 7 / 8 · 6 / 9 · 8 / 4 / 6 | the 7 candidates | `TRL` | judgement (D-025) | Declared 1–9 scale. F110's 4 encodes "not available in the F-16A timeframe" — the fact that decides the engine trade |
| 3 × 2100 lb | the fuel tanks | `FuelCapacity_lb` | Estimate | D-023: Brandt's figure is 6296.30 lb (`Wt!B6`) |
| −6 %MAC | `REQ_F16A_025` | requirement floor — no stereotype, so no `DataProvenance` slot; tagged here instead | Estimate | Commonly repeated for the F-16's subsonic relaxed static stability, but **no source is cited** and `/sizing/` has no static-margin criterion. The band's upper end is a strict zero, which is a *definition* and is not inventoried (D-051) |

`Benefit` and `TRL` supply **0.75 of every trade score** and are unauditable in principle — they trace
to nothing. That is exactly why they must be *recorded*, since they can never be *checked*.

### D-031 · `Material` carries provenance too
All seven composite fractions were invented numbers with no tag. `Material` gained `DataProvenance`.
**Why** The provenance vocabulary is worth nothing if applied only where someone remembered.

### D-032 · The aircraft cost MoM defaults to NaN as well
`MeasureOfMerit.UnitCost_USD` defaulted to `0` — the latent hole D-021 closed on `TradeCandidate`.
A future path applying the stereotype without writing the property would ship `$0` as flyaway cost.

### D-033 · `Benefit` is bounded at both ends, and its scale is 1–10
Guards enforce `1 ≤ Benefit ≤ 10`; `0` is the "not set" sentinel, outside the scale, exactly as TRL's is.
**Why** `7.8` mistyped as `78` gives `v = 7.8` against a legitimate maximum of 1.0 — finite, so it slips
past `isfinite`, and `TwinEngine_Surrogate` wins, flipping the L active kind and Implement-linking
`REQ_F16A_L01` from the wrong kind. A dropped decimal point could propagate a wrong decision into
requirements traceability, silently.

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

### D-036 · The Brandt masses are referenced from the `.m` model, not transcribed twice
`F16APhysicalArchitectureTest` shall obtain the ground-truth masses by executing
`sizing/VnV/BrandtF16A/BrandtWeight.m` read-only at `run(31377)` (W_TO = 31,377 lb, `Wt!B3`) and reading
its properties. The **generator stays the only place the numbers are typed**; the test becomes a genuine
cross-check between two independently authored models.

**Source is the `.m`, not the spreadsheet** — it is the executable, version-controlled artifact this
repo maintains; reading the `.xls` would add an Excel dependency and still be a transcription.

**Mapping** (leaf → `BrandtWeight` property): `Wing`→`W_wing_lb` · `Fuselage`→`W_fuse_lb` ·
`HorizontalTail`→`W_pitch_lb` · `VerticalTail`→`W_vert_lb` · `Nacelles`→`W_nacelles_lb` ·
`Strakes`→`W_strakes_lb` · `F100_PW_200`→`W_engine_lb` · `InletDuct`→`W_inlet_duct_lb` ·
`LandingGear`→`W_gear_lb` · `FlyByWire`→`W_ctrl_lb` · `Avionics`→`W_avionics_lb` ·
`Electrical`→`W_elec_lb` · `Hydraulics`→`W_hyd_lb` · `ECS`→`W_ECS_lb` ·
`ArmamentSupport`→`W_armament_lb` · `SecondaryStructure`→`W_other_lb`; plus
`BrandtAirframeMass_lb` ← **`W_structure_lb`** and `ExpectedOEW_lb` ← `W_empty_lb`.

**Two traps.** `BrandtAirframeMass_lb` holds 6722.88, the airframe *structural subtotal*, but its name
points at Brandt's `W_airframe_lb` = 15250.47 (OEW − engine) — wiring by name would swap in a figure
twice the size and still read plausibly. `W_airframe_lb` is **deliberately unmapped**: no MBSE component
equals it. And `W_other_lb` goes on the 1 % side, not the 0.1 % — it is derived as `0.30 × W_structure`,
which includes `W_nacelles`, so it inherits the nacelle-`π` error.

**This converts exact equality into a tolerance assertion**, knowingly: the `.m` uses `π` where the
spreadsheet uses 3.1516, giving −0.37 % on `W_nacelles`/`W_inlet_duct` and ≈0.01 % on OEW. Adopt
`sizing/.../tests/test_BrandtWeight.m`'s own house figures — **1 % RelTol** physics-computed, 0.1 %
algebraically exact. Everything internal to the MBSE model stays exact. This settles the
19980.73-vs-19980.70 and 6722.88-vs-6722.87 pairs: both correct, the drift now measured.

**As built.** The 16-leaf mapping above was taken as written, including both traps. Two entries were
**not**: `ExpectedOEW_lb` and `BrandtAirframeMass_lb` stay literals, per the Stage-6 planning
decision that only the leaf comparison crosses into `/sizing/`. They are now redundant pins rather
than the primary check — every leaf is verified against `BrandtWeight`, and OEW is verified to be the
sum of the model's own leaves.

**The drift is 100× what this entry predicted, and against a third number.** Executing
`BrandtWeight.run(31377)` returns `W_empty_lb` = **19,977.61** and `W_structure_lb` = **6,722.27** —
neither the MBSE model's 19,980.73 / 6,722.88 nor the spreadsheet figures 19,980.70 / 6,722.87 this
entry paired them against. 19,980.70 is what `test_BrandtWeight` *asserts* at 1 % RelTol, not what
the `.m` *computes*; the two were conflated when this entry was written. Real OEW drift is therefore
3.12 lb (1.6e-4 relative), not the ≈0.01 % estimated. Nothing here fails — every leaf is inside its
class — but the tolerance is doing real work rather than absorbing rounding: `Nacelles` compares
186.82 against 186.22 and `InletDuct` 728.60 against 726.27, both 3.2e-3, which is why the 1 %
classification is load-bearing and not decorative.

**The internal and cross-model checks were separated**, which the entry did not anticipate. The old
`sum(MassRows)` served as both "the sum of the model's leaves" and "the Brandt total"; those are now
different numbers, so conflating them would let a cross-model difference read as an internal
inconsistency. `sumOfLeafMasses` reads the model, `MassLeafRows` reads Brandt.

**Constraints** Reach `sizing/` with a `PathFixture` (**three** levels up from `f16aRoot()`), restore
the path on teardown; if `/sizing/` is missing, **fail loudly naming the dependency** — no skip, no
fallback to literals. `ExpectedOEW_lb` and the three candidate mass baselines stay generator literals.

### D-037 · A decision requirement poses the decision; it does not contain the answer
`REQ_F16A_L01`–`L03` were writing the trade's *outcome* — vendor name, run-time-derived weights, a
baseline overclaim — into requirements that are generated **before** the trade runs. Rewritten to pose
the decision over the kinds L presents and name where the answer is recorded. **Why** A requirement
that contains its answer is not a decision record, it is an unfalsifiable claim. Guarded by
`F16ARequirementsTest` (no vendor token, no weight, no score). Closes D-020's deferred note.

### D-038 · The fuel roll-up becomes variant-safe
`F16APhysicalFuelRollup` reads `fuelSys.Architecture.Components` flat and calls `getProperty` on every
child without a stereotype check. Replace with a recursive `fuelLeaves` helper mirroring
`F16APhysicalMaterialsRollup.materialLeaves`: descend into **`getActiveChoice`** at a variant (never
`getChoices`, never `.Architecture.Components` — that returns 0 on a reloaded model), and apply the
structural rule *a component carrying `FuelTank` IS a fuel leaf*. Error on an empty walk
(`:noFuelTanks`) — **a silent 0 is the failure being removed; do not replace it with a different one.**
**Why it is not hypothetical** `FuelSystem` becomes a variant role the moment the example admits a
hybrid-electric aircraft. *Part 2 (volume) superseded by **D-041**.*
**As built** Total unchanged at 6,300 lb over the same three tanks — the point was the rule, not the
number. `testFuelRollupDiscoversTanksByStereotype` is the first test to call the function at all
(P suite 39 → 40 cases; sweep 106 → 107); it asserts the *discovery rule* against a set found
independently from the model, because asserting the total would pass just as well against the walk
being replaced. The error path (`:noFuelTanks`) is stated and unit-untested — proving it fires needs a
model with no tanks, and building one was judged out of scope here.

### D-039 · The F layer's folder is renamed `architecture/` → `functions/`
**Why** All three layers are System Composer architecture models, so `architecture/` names what F
*shares* with L and P, while every sibling folder is named for its concern. Five other names in the
example say *functions*. **Scope** `git mv` (so labels survive); five literal path strings in code;
~11 doc references; `.claude/agents/f16a-functions.md`. File names do not change. **The real cost is
the project registry** — a `git mv` that does not propagate leaves dangling entries. Own stage, own
gate, finish at `runChecks` 12/12.
**As built** Six code sites, not five — `f16aRoot.m`'s help block lists its sibling folders and was
missed at planning. Two agent files, not one: `f16a-vnv.md` names the F test by path as well. The
local `archDir` in both generators became `fcnDir`; nothing else was renamed.
**Measured, and the reason this needed its own stage:** MATLAB's Git integration makes
`removeFile`/`removePath` *stage a git deletion*, so the registry cleanup silently emptied the folder
as far as git was concerned and `git mv` then failed with "source directory is empty". The deletions
must be restored to the index (`git restore --staged`) before the move, or the rename records as
delete-plus-add and the history stops following the files. Labels do **not** ride along on their own:
the four `Classification` values were captured before removal and re-applied after `addPath` +
`addFolderIncludingChildFiles`.

### D-040 · The verdict lives where it is computed, not in the requirement
D-037 resolved as: the requirement stays a pure question; the verdict lives in the winning candidate's
`Rationale.Justification` at P plus the Implement link from the winning kind. **Rejected** Having the
trade write the verdict into the requirement — a P-layer script writing into an R-owned artifact, which
a re-run of the R generator would blank. The variant flag stays derived (D-027).

### D-041 · Fuel is rolled up by WEIGHT only; the volume roll-up is dropped
*Supersedes D-038 part 2.* No fuel density, no volume property, no new number. **Why** `/sizing/` has
no fuel density and no fuel volume — it works entirely in fuel weight — so volume would add a number
with no home in the reference model to support a quantity nothing else consumes. `REQ_F16A_P01`'s
*"(volume, expressed as fuel-weight capacity)"* is the settled formulation, not a hedge.

### D-042 · The fuel verification stays RED, permanently and by design
`F16APhysicalMissionFuel` keeps returning `NaN`; `F16AFuelVerificationTest` keeps failing;
`REQ_F16A_P01` stays **unevaluated**. It is not wired to `BrandtMission`, now or later.
**Why** The red test *is* the teaching artifact — "verification set up, traceable, not yet satisfied"
is the state a real programme lives in, and nothing else here shows it. Wiring it to
`Miss!O9 = 6000.43 lb` would teach the opposite lesson, and one requirement can only teach one.

### D-043 · Cost is a whole-aircraft Measure of Merit only; it never enters the trade · **OPEN**
`F16APhysicalCostModel` gets a real DAPCA-IV implementation following
`sizing/VnV/BrandtF16A/BrandtCost.m` and populates `MeasureOfMerit.UnitCost_USD` on `Aircraft`.
`TradeCandidate.UnitCost_USD` stays `NaN` on all seven candidates, permanently.
**Rejected** Per-candidate cost deltas — DAPCA IV has a defensible answer for "what does this aeroplane
cost" and none for "what does this wing candidate cost".
**Tag it `Simulation`, not `Reference`** — it is computed from *this* model's rolled-up OEW.
`BrandtCost`'s ≈ $68.4M (quoted in `REQ_F16A_026`) is the cross-check, not the value.
**Ordering** The generator computes cost in section 8 but the roll-ups run in section 9, so OEW does
not exist yet — move the cost write after section 9. Applied trade weights stay `0.50/0.25/0.25`
permanently.

### D-044 → superseded by **D-046** and **D-051**
Proposed criteria for `REQ_F16A_023`/`024`/`025` from USAF/USN figures. Withdrawn: its own blocking
check found the gear-angle conventions ambiguous. Its arithmetic survives as the student exercise brief
in [`01_requirements.md`](01_requirements.md).

### D-045 · `REQ_F16A_D01`–`D09` stay as a student exercise
The nine derived functional requirements keep their `PLACEHOLDER: quantitative criteria TBD` text and
their `todo` keyword. **Why** They are already framed as the exercise, and unlike the gear angles no
external specification supplies values — writing any would be inventing requirements. The docs must say
so explicitly, so a reader stops looking for missing numbers.

### D-046 · The gear angles become a student exercise; only static margin gets criteria
`REQ_F16A_023` (tipback) and `REQ_F16A_024` (overturn) get **no criteria** and keep their `todo`
keyword, joining D-045's list. The `rollover` → `overturn` rename is deferred with them — calling
Brandt's quantity "the overturn angle" would assert the very identification that is in doubt, and
naming it correctly is part of the exercise.
**Why** Brandt's `atand(h_main/d_axis)` is measured from the horizontal; the standard overturn angle
(Raymer §11.4; Currey) is measured from the vertical. **The same number supports opposite verdicts, and
only one is a fact about the aeroplane.** The exercise brief is in
[`01_requirements.md`](01_requirements.md). *`025`'s criterion here is superseded by **D-051**.*

### D-047 · `REQ_F16A_025` is verified by delegating to `/sizing/`
`verification/F16AStaticMarginVerificationTest.m` calls `BrandtBalanceStabControl` read-only.
**Why** This is the first verification that leaves the MBSE model, and that is the point rather than a
workaround: static margin is a whole-aircraft aerodynamic-and-balance result, and **none of `x_np`,
`x_cg` or `MAC` is a property of a part**. A requirement's evidence belongs where the evidence lives;
what MBSE contributes is the traceability.
**The sizing code cannot be a project member and does not need to be** — a project's files and paths are
all relative to its root and `sizing/` is three levels above it; everything resolves off the MATLAB
**path**. The test uses a `PathFixture`, not a bare `addpath`, so `sizing/` is off the path again on
teardown — otherwise a later suite could resolve a `Brandt*` name it never asked for, making results
depend on suite order.
**No `verify` keyword** — the Verify link is the authoritative record that a requirement has a test, and
a generator-written keyword restating it is a derived fact stored where it can drift (D-027, D-040).

### D-048 → merged into **D-051**
Tagged the static-margin band `Estimate` and inventoried it in D-030 after an `f16a-data` veto. The tag
and the D-030 row stand; the band itself was reshaped by D-051.

### D-049 · Where a reader who clicks a *rejected* kind lands
D-027's mechanism is unchanged — every kind carries `DecisionRef` — but its stated purpose is restated
as a **two-hop trail**: rejected kind → the decision requirement, which poses the choice and names where
the answer is → the rejected candidate at P, whose `Rationale.SourceKind` is `TradeAlternative` and
whose `Justification` states the deficit. **Why** After D-040 no requirement says why anything lost.
**Rejected** Dropping `DecisionRef` from losers — it is the only outbound reference a rejected kind
carries, and removing it restores the `'TBD'` dead end. **Honest caveat, stated in the docs:** the
second hop is a property match, not a link the tool can follow.

### D-050 · The programme history moves to the docs, labelled history and not rationale
The Lightweight Fighter competition, the YF-16/YF-17 flyoff and "this is the production configuration"
live in prose in `04_logical.md` under *History, not rationale* — never in a requirement `Description`,
a kind name or a `Rationale`. **Why** D-037 rightly removed them from the model, but they are why the
F-16A is a good case study. The section states that **no criterion, value function or weight reads a
name**, so renaming all seven candidates changes nothing — and that this independence is not evidence
about aeroplanes, because the exercise is retrodictive.

### D-051 · The static margin must be NEGATIVE, and the reference model fails it at landing
*Supersedes D-046 part 3 and D-044; absorbs D-048.* `REQ_F16A_025` reads:

> **−6 %MAC ≤ `SM` < 0**, where `SM = (x_np − x_cg)/MAC` — floor inclusive, ceiling strict — at **both
> ends** of the operational CG range, takeoff *and* landing.

`SM_TO` = **−0.2602 %MAC** meets it; `SM_land` = **+0.2065 %MAC** violates it. The test is **2 pass /
1 fail, by design and permanently.**

**Why** A requirement can be met, unevaluated, or **evaluated and not met**. The example shipped the
first two (`REQ_F16A_022` green, `REQ_F16A_P01` red-unevaluated) and had no artifact for the third —
the state a real programme spends most of its life in. D-046 had widened the band until the reference
figure fitted inside it; this takes that back. `025` is the right carrier because a sign test on a
computed margin has no convention to argue about — which is exactly what disqualified `024`.

**Provenance: one invented number instead of two.** The ceiling is a strict **zero**, which is a
definition — relaxed static stability *is* a negative margin — so it is not inventoried. The floor is
unchanged: still `−6 %MAC`, still uncited, still `Estimate`, still in D-030. It is not free and is not
presented as free: a bare *"negative"* would rest on no invented number at all, which
`f16a-requirements` argued for and argued well — but a requirement satisfied by an aeroplane no FCS
could fly is not a useful requirement. The floor buys a meaningful unstable end, costs one `Estimate`,
and carries `REQ_F16A_L02`'s implicit premise that the instability is *bounded*.

**The landing failure is a property of the reference model, not of the F-16A** — Brandt's neutral point
is a simplified approximation, so this model drifts *stable* at light weight where the real aeroplane
does not. The numbers, the CG-travel explanation and the three verification states are in
[`01_requirements.md`](01_requirements.md) and [`README.md`](README.md); they are not repeated here.

### D-052 · `PhysicalItem` gets its own `DataProvenance`; the default is `Simulation`
A mass is an engineering value like any other, so the stereotype that holds it declares where it came
from. `PhysicalItem` was on `ProvenanceExemptStereotypes` — the exemption is what let 14 of the 16
masses summing to OEW ship untagged.

**Why it was worse than a gap.** The six airframe structural leaves already carried
`Material.DataProvenance = Estimate`, which qualifies their *composite fraction*. Beside a mass that
is Brandt ground truth, a reader inspecting `Fuselage` saw a tag that **contradicted** the number
next to it. Two tags on one part are only honest while each names a different property, which is why
the fix is a second tag rather than reusing `Material`'s.

**The default is `Simulation`, not `Estimate`.** `PhysicalItem` applies to every component, so the
ones left at the default are the interior nodes. They store no mass — `F16APhysicalMassRollup`
persists only the aircraft's OEW Measure of Merit, never a subtotal back onto a node — so the answer
to "what does `Airframe` weigh" is computed on demand, which is what `Simulation` means. `Estimate`
would tag every subtotal an invented teaching value and pull all of them into D-030.

**The two zeros are `Reference`, not the default.** `FuelSystem` and the three tanks carry a dry mass
of 0 because Brandt's breakdown has no tankage line — its 16 mass rows sum to `W_empty` exactly, with
no room for a 17th. That zero is what the reference states; nothing computed it, so leaving it at
`Simulation` would have claimed a roll-up produced it. The tanks therefore carry `FuelTank` =
`Estimate` (their capacity, D-023) beside `PhysicalItem` = `Reference` (their dry mass) — the same
two-tags-two-subjects shape as the airframe leaves, inverted.

**No number changed.** OEW 19,980.73, airframe 6,722.88, composite 0.1928, fuel 6,300 lb.
