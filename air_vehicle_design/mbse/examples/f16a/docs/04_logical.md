# L Layer — Logical

> `logical/F16A_Logical.slx` · profile `F16A_LogicalOptions.xml` · allocation sets
> `F16A_FunctionToLogical.mldatx`, `F16A_KillChainToLogical.mldatx`

F told **what** the aircraft must do. L tells **how**, in **solution roles**. L adds two ideas:

1. **Allocation.** Each function is allocated to the role that realizes it. This relationship is
   different from the Implement links of R→F, and it is in a separate artifact.
2. **Options, given but not decided.** Frequently, there is more than one way to fill a role. L puts
   the competing **kinds** next to each other and keeps all of them. It does not select one.

## The solution roles

There are nine roles, with noun names: a role is a thing that does a job. `▽` marks a variant role
that holds competing kinds.

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

L has no ports. The teaching subject is allocation and options, not data flow.

## F → L allocation

Open the matrix with `systemcomposer.allocation.editor`. There are **14 edges** in two sets, because
a set binds to one source model:

- **Capabilities (7):** `GenerateLift` and `MaintainStructuralIntegrity` → `Airframe` ·
  `ProduceThrust` → `PropulsionSystem` · `Maneuver` → `FlightControlSystem` · `ManageFuel` →
  `FuelSystem` · `Navigate` → `AvionicsSuite` · `Communicate` → `CommunicationSystem`.
- **Kill chain (7):** `Find`, `Fix`, `Track`, `Assess` → `AvionicsSuite` · `Engage` →
  `WeaponSystem` · **`Target` → `AvionicsSuite` *and* `WeaponSystem`**. This is the only fan-out:
  the sensors designate, and the weapon system employs.

**Functions are allocated to the role, never to a kind.** Allocation tells which role owns a
function. This does not change when a different kind wins. The kinds connect *downward*: each P
candidate is allocated from the kind that it realizes ([05](05_physical.md#l--p-allocation)).

**Mission phases are not allocated to roles.** A phase uses capabilities, and the capabilities are
allocated. `Cruise → Airframe` would only repeat `GenerateLift → Airframe`, with less precision.

**Not all roles come from a function.** `LandingGear` and `MissionSystemsBay` get no allocation.
They exist to satisfy constraints, not to realize a behaviour.

## Requirements that L owns

| Requirement | Subject | Implemented by |
|---|---|---|
| `REQ_F16A_020` | permanent payload | `MissionSystemsBay` |
| `REQ_F16A_023` / `024` | tipback / rollover angle | `LandingGear` |
| `REQ_F16A_025` | static margin | `Airframe` |
| `REQ_F16A_L01` / `L02` / `L03` | the three design decisions | the **winning kind**, linked by the trade |

`023` and `024` are still blank, but the link records *where* they will be satisfied.
**Responsibility is allocated before there is a quantity.**

## Design options: given, not decided

A **kind** is an architectural topology. It is a configuration commitment with no technology, no
vendor and no numbers.

| Variant role | Kinds | The question |
|---|---|---|
| `PropulsionSystem` | `SingleEngine` · `TwinEngine` | one thrust unit, or two? |
| `Airframe` | `BlendedCrankedDelta` · `ConventionalTrapWing` | blended wing-body, or a discrete wing on a fuselage? |
| `FlightControlSystem` | `FlyByWire` · `HydroMechanical` | an electrical command path, or mechanical linkages? |

**Name test.** Replace the technology under the name. Is the name still correct? `SingleEngine`
stays correct after the F100. `SingleEngine_F100` does not, so it does not belong at L
([06](06_methodology.md)).

**Why L cannot select.** A role has no mass, cost or maturity. Only a *part* has these values. To
score kinds at L, you would have to invent these numbers for configurations that nobody built.
Thus L keeps all kinds until P can make the decision (D-001).

### What a kind carries

One stereotype, `SolutionOption`, is applied to the six kinds:

| Property | Before a trade | After the trades |
|---|---|---|
| `Selected` | `false` | `true` on the winning kind of each role |
| `DecisionRef` | `'TBD'` | the decision requirement, on **every** kind of the role, winner and loser |

No mass, TRL or benefit is at L.

### How the decision comes back

Each trade study scores the P candidates and writes the result **back into L**. The trade:

1. follows the allocation edge of the winning candidate to its **kind**, and makes that kind active.
2. sets `Selected` on that kind, and clears it on the other kind.
3. writes `DecisionRef` on each kind of the role (D-027).
4. makes an Implement link from the winning kind to `REQ_F16A_L01`–`L03`.

The trade finds the kind through the allocation, never from the candidate name. Two engines realize
`SingleEngine`, so the name is not a key into L.

**The requirement states the decision. The verdict is where it was computed.** L01–L03 state the
question and contain no winner or score (D-037, D-040). The reasoning is in
`Rationale.Justification` of each P candidate. A reader who clicks a *rejected* kind can follow
`DecisionRef` to the requirement, and then to the rejected candidate. The justification of that
candidate tells where it lost (D-049).

The active flag and `Selected` are **derived**: the trade writes them. If they do not agree with the
output of the trade, run the trade again. The losing kinds stay as the options that were traded.

### Why these three pairs

Each pair is a real F-16 decision, and a different subject controls each one:

| Pair | Where the programme argued it | What controls the decision |
|---|---|---|
| single vs twin engine | the Lightweight Fighter flyoff (YF-16 vs YF-17) | maturity and installed weight vs engine-out survivability |
| fly-by-wire vs hydro-mechanical | the F-16 was the first production fighter with fly-by-wire | agility from relaxed stability vs a proven mechanical path |
| blended cranked delta vs trapezoidal wing | the blended planform of the F-16, with LERX | high-alpha and turn performance vs aero-development risk |

**History, not rationale.** The three winners are the production F-16A configuration, but nothing
in the model reads a name. If you rename all candidates, the same rows win. This independence is
also not evidence about aeroplanes. Someone who knew the answer chose the judgement values. Thus
the exercise shows the method, not a finding ([06](06_methodology.md)).

Next: [Physical](05_physical.md), which answers the three questions.
