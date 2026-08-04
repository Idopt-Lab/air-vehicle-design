# Traceability — Requirements ↔ Functions

> Links live in `architecture/F16A_Functional~mdl.slmx` and are created by
> `architecture/generate_f16a_functional.m`.

Traceability is what turns a diagram into a *systems* model. Every function is connected to
the requirement it satisfies with an **Implement link** (source = function, destination =
requirement). This lets you ask, from either end:

- *Coverage*: is every requirement implemented by some function?
- *Justification*: does every function exist to satisfy some requirement?

**39 Implement links** connect the two layers.

## Link matrix

### Mission phases (1:1)

| Requirement | Function |
|-------------|----------|
| REQ_F16A_001 – 010 | Takeoff, Accel, Climb, Cruise, Dash, Combat, Egress, Cruise2, Loiter, Landing |

### Point performance → both lift and thrust

Every point-performance requirement depends on **both** generating lift and producing
thrust, so each links to two functions. The two field-length requirements additionally link
to their specific phase.

| Requirement | Functions | # links |
|-------------|-----------|:-------:|
| REQ_F16A_011 – 016 | GenerateLift **and** ProduceThrust | 2 each |
| REQ_F16A_017 (takeoff field length) | GenerateLift, ProduceThrust, **Takeoff** | 3 |
| REQ_F16A_018 (landing field length) | GenerateLift, ProduceThrust, **Landing** | 3 |

### Structural & payload

| Requirement | Function |
|-------------|----------|
| REQ_F16A_019 (9 g ultimate load) | MaintainStructuralIntegrity |
| REQ_F16A_021 (expendable payload release) | Engage |

## Derived requirements (D01–D09)

> Artifact: `requirements/f16a_functional_derived.slreqx` · Generator:
> `requirements/generate_f16a_derived_requirements.m`

Here is the RFLP story in miniature. When we decomposed the functions, several turned out
to be **necessary to fly the mission but absent from the sizing-derived requirements** —
the spreadsheet simply never spoke about navigation, communication, fuel management, or the
targeting steps of combat.

Rather than leave those functions orphaned (a function with no requirement is a red flag),
or pollute the pristine `f16a.slreqx`, we captured the newly-surfaced needs as **derived
requirements** in a *separate* set and linked them back:

| Derived req | Function | Capability |
|-------------|----------|------------|
| REQ_F16A_D01 | Maneuver | Aviate |
| REQ_F16A_D02 | ManageFuel | Aviate |
| REQ_F16A_D03 | Navigate | Navigate |
| REQ_F16A_D04 | Communicate | Communicate |
| REQ_F16A_D05 | Find | F2T2EA |
| REQ_F16A_D06 | Fix | F2T2EA |
| REQ_F16A_D07 | Track | F2T2EA |
| REQ_F16A_D08 | Target | F2T2EA |
| REQ_F16A_D09 | Assess | F2T2EA |

These are **placeholders**: each states the need in words but leaves the quantitative
acceptance criteria as `TBD` (keyword `todo`). They give students a concrete example of
how functional analysis feeds *back* into the requirements — and a to-do list to make the
requirements complete.

### The blanks are the assignment, not an omission

Read that to-do list as **yours**. `D01`–`D09` are **standing student exercises** and stay `TBD`
permanently (**D-045**) — nobody on this project is going to fill them in. No external specification
says what "navigate", "communicate" or "fix a target" must achieve for this aircraft, so any criterion
we wrote would be a requirement we invented; and writing one would take the exercise away. A reader
hunting for the missing numbers is hunting for something removed on purpose.

**Two more requirements join them, for a different reason** (**D-046**). `REQ_F16A_023` (tipback
angle) and `REQ_F16A_024` (rollover angle) also keep their `TBD` text and their `todo` keyword. Here
candidate values *do* exist — but the conventions `sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m`
measures its angles in do not obviously match the USAF/USN specifications those angles would be
checked against, and **the same number supports opposite verdicts** depending on which convention is
meant. Establishing what the criterion actually is, and where it is written down, **is** the
exercise. Writing a limit in before that is settled would put a false claim about a real aircraft
into a teaching model.

That is also why `REQ_F16A_024` is still called the **rollover** angle when *overturn* (or turnover)
is the standard term. The rename is **deferred with the criteria, deliberately**: calling Brandt's
quantity "the overturn angle" would assert the very identification that is in doubt. Naming it
correctly is part of the assignment, not a prerequisite to it.

**Eleven requirements carry the `todo` keyword, and they are exactly this set** — the nine above plus
`023` and `024`. `F16ARequirementsTest` asserts that set *as a whole*, so a twelfth exercise cannot
appear, and one of the eleven cannot be quietly answered, without a test going red. Two red
requirements are pointedly **not** in it: `REQ_F16A_025` has a real criterion that was evaluated and
came out *no* (**D-051**), and `REQ_F16A_P01`'s verification is pending by design (**D-042**).
Neither is outstanding work, and neither is an exercise.

> `Engage` is not in this table because it already traces to REQ_F16A_021 (payload release).

## Coverage summary

Every **leaf function** (all 23) now traces to at least one requirement. The three
composites — `ExecuteMissionProfile`, `ProvideAircraftFunctions`, `Aviate` — are
organizational containers; their children carry the traceability.

### Requirements intentionally *not* linked at the F layer

Six requirements are non-functional — they constrain the physical solution, not what the
aircraft *does* — so they are deliberately left for the **Logical / Physical** layers:

| Requirement | Concern | Traces to |
|-------------|---------|-----------|
| REQ_F16A_020 | Permanent payload capacity | **L** — `MissionSystemsBay` |
| REQ_F16A_022 | Materials (composite fraction) | **P** — `Airframe`, **verified by** materials roll-up (≤ 20%) |
| REQ_F16A_023 | Balance — tipback angle | **L** — `LandingGear`; criterion deliberately blank, a student exercise (D-046) |
| REQ_F16A_024 | Balance — rollover angle | **L** — `LandingGear`; criterion deliberately blank, a student exercise (D-046) |
| REQ_F16A_025 | Stability & control — static margin | **L** — `Airframe`, **verified by** the static-margin test (negative margin, ≥ −6 %MAC) — **violated at landing** (D-051) |
| REQ_F16A_026 | Unit flyaway cost (MoM) | **P** — cost Measure of Merit on `Aircraft` |

This is not a gap to fix now — it is the correct RFLP behavior. A requirement about
*materials* or *cost* has no meaningful home in a layer that only describes *behavior*; it
belongs where physical components exist.

The [Logical layer](04_logical.md) picks up the four that a **solution role or its geometry**
can satisfy (020, 023, 024, 025). The [Physical layer](05_physical.md) then takes the last two:
cost (026) becomes a **Measure of Merit** to minimize, homed on the `Aircraft`; materials (022) — a
genuine ≤ 20% design *constraint* — is implemented by the `Airframe` variant role and **verified by**
a test that rolls up the airframe composite fraction (the project's first requirement-to-test
*verify* link). The Physical layer also adds `REQ_F16A_P01` (fuel-volume sufficiency), likewise
verified by a test.

## Downstream: the other two relationships

R→F is `Implement`. The layers below add two more relationship *kinds*, each with its own artifact
— which is the point worth taking away: traceability is not one link type, and it does not all live
in one file.

| Relationship | From → to | Stored in | Count |
|---|---|---|:-:|
| **Implement** | function → requirement | `architecture/F16A_Functional~mdl.slmx` | 39 |
| **Allocation** | function → logical role | `logical/F16A_FunctionToLogical.mldatx` | 14 edges |
| **Realization** | logical role → physical part | `physical/F16A_LogicalToPhysical.mldatx` | 14 edges |

**Realization targets candidates, not variant wrappers.** Three logical roles are realized by the
competing *candidates* that could fill them — `Airframe` by 2, `PropulsionSystem` by 3 engine
candidates plus the shared `InletDuct`, `FlightControlSystem` by 2 — and the other six roles one each,
for **14** edges. The 1→many teaching moment therefore moved: it used to be `Airframe` fanning out to
its six structural parts (now one level down, inside a candidate), and it is now `PropulsionSystem`
fanning out to four (D-024). Details in [`05_physical.md`](05_physical.md).

### The decision requirements (L01–L03)

> Artifact: `requirements/f16a_logical_derived.slreqx` · Generator:
> `requirements/generate_f16a_logical_derived_requirements.m`

Three requirements pose the *decisions* the design had to make. They are **not** implemented by a
function or by a part — what implements *"which of these kinds shall realize this role?"* is the
**selected option**, the kind that answers it. So their Implement links are created by
`physical/F16APhysicalTradeStudy.m`, from the **winning logical kind** in `F16A_Logical.slx`, once
the trade over the physical candidates has run (D-001, D-010):

| Decision req | Role decided | Implement-linked from the winning kind |
|---|---|---|
| REQ_F16A_L01 | PropulsionSystem | `SingleEngine` |
| REQ_F16A_L02 | FlightControlSystem | `FlyByWire` |
| REQ_F16A_L03 | Airframe | `BlendedCrankedDelta` |

Between the L build and the physical trade these three show as **un-implemented** in the Requirements
Editor. That is the expected state, not a gap: the requirement is where the decision is **posed and
anchored**, and the trade study is what answers it. The verdict itself lives at P — in the winning
candidate's `Rationale.Justification` — and arrives here as the Implement link above (**D-040**).
This does not hand authority back to the variant flag: the flag stays **derived**, written by the
trade rather than authored (**D-027**), so reading the active choice is still not reading the
decision.

## Checking traceability yourself

```matlab
openProject("f16a.prj")
rs = slreq.load("f16a.slreqx");
slreq.editor            % opens the Requirements Editor; the Implemented column
                        % shows the links, with the model as the source
```

Or run the automated check:

```matlab
runtests("F16AFunctionalArchitectureTest")   % includes the link-count assertions
```

To see the L01–L03 decision links you must load the **L model** as well —
`F16AOpenForReview` does it, and the README explains why an Implement link lives in the implementing
model's link set rather than in the requirement set.

## Next

The [Logical layer](04_logical.md) picks up the allocation relationship; the
[Physical layer](05_physical.md) adds realization, the trade study that writes L01–L03, and the
project's first *verified by* links.
