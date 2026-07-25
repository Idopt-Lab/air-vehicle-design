# Traceability — Requirements ↔ Functions

> Links live in `architecture/F16A_Functional~mdl.slmx` and are created by
> `generate_f16a_functional.m`.

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
| REQ_F16A_022 | Materials (composite fraction) | **P** — deferred (future materials roll-up) |
| REQ_F16A_023 | Balance — tipback angle | **L** — `LandingGear` |
| REQ_F16A_024 | Balance — rollover angle | **L** — `LandingGear` |
| REQ_F16A_025 | Stability & control — static margin | **L** — `Airframe` |
| REQ_F16A_026 | Unit flyaway cost (MoM) | **P** — cost Measure of Merit on `Aircraft` |

This is not a gap to fix now — it is the correct RFLP behavior. A requirement about
*materials* or *cost* has no meaningful home in a layer that only describes *behavior*; it
belongs where physical components exist.

The [Logical layer](04_logical.md) picks up the four that a **solution role or its geometry**
can satisfy (020, 023, 024, 025). The [Physical layer](05_physical.md) then takes the last two,
because only *materialized parts* can carry them: cost (026) becomes a **Measure of Merit** to
minimize, homed on the `Aircraft` component; materials (022) — a genuine ≤ 20% design *constraint*
— stays a deferred requirement, a natural next extension via a composite-fraction roll-up.

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
