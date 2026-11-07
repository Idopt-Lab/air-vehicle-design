# L Layer — Logical

> `logical/F16A_Logical.slx` · profile `F16A_LogicalOptions.xml` · allocation sets
> `F16A_FunctionToLogical.mldatx`, `F16A_KillChainToLogical.mldatx`

F said **what** the aircraft must do. L says **how**, in **solution roles**, and adds two ideas:

1. **Allocation.** Each function is allocated to the role that realizes it. This is a different
   relationship from R→F's Implement links, and it lives in its own artifact.
2. **Options, presented but not decided.** A role can often be filled more than one way. L lays the
   competing **kinds** side by side and keeps all of them. It does not pick one.

## The solution roles

Nine roles, named as nouns: a role is a thing that fills a job. `▽` marks a variant role holding
competing kinds.

| Role | What it is |
|------|------------|
| `Airframe` ▽ | load-bearing structure, aeroshape, CG |
| `PropulsionSystem` ▽ | thrust: engine, inlet, afterburner |
| `FuelSystem` | fuel storage, transfer, CG management |
| `FlightControlSystem` ▽ | attitude and trajectory control: surfaces, actuation, control laws |
| `LandingGear` | ground support, rotation clearance, braking |
| `AvionicsSuite` | navigation, mission computing, sensors, IFF |
| `CommunicationSystem` | voice and data links |
| `WeaponSystem` | store carriage, fire control, payload release |
| `MissionSystemsBay` | permanent payload: gun, fixed equipment |

L carries no ports. The teaching focus is allocation and options, not data flow.

## F → L allocation

Open the matrix with `systemcomposer.allocation.editor`. There are **14 edges** in two sets, because a
set binds to one source model:

- **Capabilities (7):** `GenerateLift` and `MaintainStructuralIntegrity` → `Airframe` ·
  `ProduceThrust` → `PropulsionSystem` · `Maneuver` → `FlightControlSystem` · `ManageFuel` →
  `FuelSystem` · `Navigate` → `AvionicsSuite` · `Communicate` → `CommunicationSystem`.
- **Kill chain (7):** `Find`, `Fix`, `Track`, `Assess` → `AvionicsSuite` · `Engage` →
  `WeaponSystem` · **`Target` → `AvionicsSuite` *and* `WeaponSystem`**, the one fan-out (the sensors
  designate, the weapon system employs).

**Functions are allocated to the role, never to a kind.** Allocation says which role owns a
function, and that does not change whichever kind wins. The kinds connect *downward*: each P
candidate is allocated from the kind it realizes ([05](05_physical.md#l--p-allocation)).

**Mission phases are not allocated to roles.** A phase uses capabilities, and those are allocated.
`Cruise → Airframe` would only restate `GenerateLift → Airframe`, less precisely.

**Not every role comes from a function.** `LandingGear` and `MissionSystemsBay` receive no
allocation. They exist to satisfy constraints, not to realize a behaviour.

## Requirements L owns

| Requirement | Concern | Implemented by |
|---|---|---|
| `REQ_F16A_020` | permanent payload | `MissionSystemsBay` |
| `REQ_F16A_023` / `024` | tipback / rollover angle | `LandingGear` |
| `REQ_F16A_025` | static margin | `Airframe` |
| `REQ_F16A_L01` / `L02` / `L03` | the three design decisions | the **winning kind**, linked by the trade |

`023` and `024` are still blank, but the link records *where* they will be satisfied.
**Responsibility is allocated before anything is quantified.**

## Design options: presented, not decided

A **kind** is an architectural topology: a configuration commitment free of technology, vendor and
numbers.

| Variant role | Kinds | The question |
|---|---|---|
| `PropulsionSystem` | `SingleEngine` · `TwinEngine` | one thrust unit, or two? |
| `Airframe` | `BlendedCrankedDelta` · `ConventionalTrapWing` | blended wing-body, or a discrete wing on a fuselage? |
| `FlightControlSystem` | `FlyByWire` · `HydroMechanical` | an electrical command path, or mechanical linkages? |

**Name test.** Swap the technology underneath: does the name still make sense? `SingleEngine` outlives
the F100; `SingleEngine_F100` would not, so it does not belong at L ([06](06_methodology.md)).

**Why L cannot choose.** A role has no mass, cost or maturity, because only a *part* does. Scoring
kinds here would mean inventing those numbers for configurations nobody built. So L keeps every kind
until P can decide (D-001).

### What a kind carries

One stereotype, `SolutionOption`, applied to the six kinds:

| Property | Before any trade | After the trades |
|---|---|---|
| `Selected` | `false` | `true` on the winning kind of each role |
| `DecisionRef` | `'TBD'` | the decision requirement, on **every** kind of the role, winner and loser |

No mass, TRL or benefit appears anywhere at L.

### How the decision comes back

Each trade study scores the P candidates and writes the result **back into L**:

1. follows the winning candidate's allocation edge to its **kind**, and makes that kind active;
2. sets `Selected` on that kind and clears it on its sibling;
3. writes `DecisionRef` on every kind of the role (D-027);
4. Implement-links the winning kind to `REQ_F16A_L01`–`L03`.

The kind is found through the allocation, never from the candidate's name. Two engines realize
`SingleEngine`, so the name is not a key into L.

**The requirement poses the decision; the verdict lives where it was computed.** L01–L03 state the
question and contain no winner or score (D-037, D-040). The reasoning is in each P candidate's
`Rationale.Justification`. A reader who clicks a *rejected* kind follows `DecisionRef` to the
requirement, then on to the rejected candidate, whose justification says what it lost on (D-049).

The active flag and `Selected` are **derived**: the trade writes them. If they ever disagree with the
trade's output, re-run the trade. The losing kinds are kept as the options that were traded.

### Why these three pairs

Each pair is a real F-16 decision dominated by a different concern:

| Pair | Where the programme argued it | What dominates |
|---|---|---|
| single vs twin engine | the Lightweight Fighter flyoff (YF-16 vs YF-17) | maturity and installed weight vs engine-out survivability |
| fly-by-wire vs hydro-mechanical | the F-16 was the first production fighter with fly-by-wire | agility from relaxed stability vs a proven mechanical path |
| blended cranked delta vs trapezoidal wing | the F-16's blended planform with LERX | high-alpha and turn performance vs aero-development risk |

**History, not rationale.** The three winners are the production F-16A configuration, but nothing in
the model reads a name: rename every candidate and the same rows win. That independence is not
evidence about aeroplanes either. The judgement values were chosen by someone who knew the answer,
so the exercise demonstrates the method, not a finding ([06](06_methodology.md)).

Next: [Physical](05_physical.md), where the three questions are answered.
