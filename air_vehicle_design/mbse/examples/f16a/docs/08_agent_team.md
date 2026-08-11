# The agent team

> Agent definitions: `.claude/agents/f16a-*.md` (repo root) · Decisions:
> [`07_decision_log.md`](07_decision_log.md) · Method: [`06_methodology.md`](06_methodology.md)

Specialist agents, one per concern, coordinated by an orchestrator that stops for human approval at
the end of every stage — layer owners who build, a data authority who owns ground truth, an
independent V&V owner, a methodologist, and a scribe. This file is the single source of truth for
house rules.

## Roles

| Agent | Owns |
|---|---|
| **Orchestrator** (main session) | staging, gates, git |
| **f16a-requirements** | `requirements/` — the R layer and link semantics (Implement vs Verify) |
| **f16a-functions** | `functions/` — the F layer and the F→L allocation |
| **f16a-logical** | `logical/` — technology-neutral *kinds*; no numbers, no decisions |
| **f16a-physical** | `physical/` — candidates, stereotypes, roll-ups, the trade study |
| **f16a-vnv** | all tests; writes assertions independently of whoever wrote the code |
| **f16a-data** | the numbers, wherever they live. **Veto at every gate** |
| **f16a-scribe** | `docs/`, the decision log, help blocks |
| **f16a-mbse-method** | `06_methodology.md`; referee when L and P disagree about *where* something belongs |

Load the MathWorks skills for the layer you are touching, and confirm R2026a API signatures with
`matlab-core:matlab-read-doc` rather than recalling them.

## House rules

1. **No agent invents a number.** Every value is traceable to `sizing/VnV/BrandtF16A/`
   (`Reference`), a datasheet (`Datasheet`), an analysis (`Simulation`), or is an explicit
   `Estimate` — labelled in the model *and* listed in D-030. `f16a-data` can veto any number.
2. **Write scope.** Only `air_vehicle_design/mbse/`. `sizing/` is read-only reference. The one
   exception is `.claude/agents/` at the repo root.
3. **Generators are idempotent.** Never hand-edit a `.slx`, `.sldd`, `.xml` profile or `.mldatx` —
   change the generator and re-run.
4. **Layer independence.** Read any layer, write only your own. Cross-layer writes (the P trade
   setting the L active kind) are explicit and touch only the link set they belong to.
5. **One home per fact.** A fact is stated in exactly one file; everywhere else links to it. Two
   copies of a sentence are two things that can drift.
6. **Prose is capped.** A MATLAB help block is ≤20 lines, ≤35 for a generator: what the file does,
   its inputs and outputs, one line on the teaching point. Comments explain the code beneath them,
   not the history above them. Cite a `D-0xx` only where the code looks wrong without it.
7. **The decision log is rewritable.** Compress it when it grows; a decision needs what was decided
   and one line of why, not the argument that got there. Ids are stable — a superseded entry leaves
   a redirect rather than disappearing.
8. **Log a decision only if a future reader would otherwise reverse-engineer it.** Not one per stage.
9. **Gates.** Work is staged; the orchestrator presents the diff and the test results and asks the
   human to approve. One commit per stage.

## R2026a API findings

Measured on this machine, not recalled from documentation. Each drives a real design choice.

| Question | Finding |
|---|---|
| Can a stereotype property be an **enumeration**? | **Yes** — `addProperty(…, Type="MyEnumClass")` accepts a plain MATLAB `enumeration` class on the path. Write the value fully qualified and unquoted (`"F16ASourceKind.TradeWinner"`) or as a quoted bare member (`"'TradeWinner'"`); other forms error. Reads back as char *with* quotes. This is why `SourceKind` and `DataProvenance` are real enumerations rather than free strings |
| Does an analysis instance hold **inactive** variant choices? | **No** — it holds only the active choice, and it is **flattened**: the choice node is elided and its children lift under the variant node. So a walk over the instance is an active-configuration roll-up for free, and instance paths differ from architecture paths |
| Does `instantiate` need a `Function=`? | **No.** Measured in R2026a: `instantiate(arch, profile, name, Strict=true, NormalizeUnits=false)` populates every property value, and `setValue` on an instance node works without it. Passing the analysis function to *both* `instantiate` and `iterate(…, Recurse=true)` runs it twice over, once per node — which is what D-058 removed |
| How do you reach a variant's choices? | **`getChoices` only.** `vc.Architecture.Components` returned the 2 choices on a freshly built in-memory model but **0** on the same model saved and reloaded. Any architecture-side walk must special-case a `VariantComponent` — a recursion over `.Architecture.Components` silently skips every candidate on a loaded model |
| String stereotype properties | Stored as a MATLAB **expression**: write `"'TBD'"`, and `getProperty` returns `'TBD'` with the quotes. Write quoted, read with `erase(…, "'")` |

Pre-existing gotchas that still hold: connect ports with the two-argument `connect(src,dst)`; unload
allocation sets and profiles *before* closing models/dictionaries in a generator's cleanup;
`string(NaN)` is `<missing>` and `setProperty` rejects it — use `string(num2str(NaN))`.

## Activity diagram API (R2026a)

Measured before the mission activity was written, because `setBehaviorType` shipped in this release and
the package is p-coded with empty help. Two of these decided whether D-059 was buildable at all.

| Question | Finding |
|---|---|
| `systemcomposer.createActivity` returns what? | A `systemcomposer.activity.Model`; the root is `am.Activity`. It saves as a plain **`.slx`** |
| `addNode` argument order | **`addNode(name, type)` — name FIRST.** Type is lowercase from `initial`, `activityfinal`, `flowfinal`, `joinfork`, `mergedecision`, `action`. Passing the type first gives a `mustBeMember` error that looks like a bad type name and is really a bad *order* |
| Where does `connect` live? | On the **nodes**, never on the `Activity` — `act.connect(a,b)` errors "Unrecognized method". `a.connect(b)` joins actions; `pinOut.connect(pinIn)` joins pins. Returns an `activity.Flow` |
| Typed object flow | `addPin(name, "in"\|"out")`, then `pin.ObjectType = <DataInterface>`. The activity model links an existing dictionary with `am.linkDictionary(file)` and reads interfaces off `am.TypesDictionary` — so the mission reuses `F16A_Functional.sldd` rather than minting a second one |
| Binding an action to MATLAB | `setBehaviorType(a,"MATLAB")` sets `ActionBehavior`; `BehaviorDefinition` is then a free-form string that **accepts a call expression with arguments** (`F16AMissionSegment('Takeoff')`). One function serves all ten phases — ten near-identical wrappers are not needed |
| Nesting an activity | `setBehaviorType(a,"Activity")` creates `a.ChildActivity`, named after the action and carrying a `ParentAction` back-pointer. This is how Combat holds F2T2EA |
| **Can a requirement link to an action?** | **Yes, via the handle.** `slreq.createLink(action, req)` **fails** (`APIFailedToCreateLink`); `slreq.createLink(action.SimulinkHandle, req)` succeeds, as does the SID (`model:2`). The link lands in domain `linktype_rmi_simulink` |
| **Can an action be an allocation source?** | **Yes, via the object.** `createAllocationSet(name, activityModelName, targetModelName)` then `scenario.allocate(actionObject, component)`. Note the asymmetry with the line above: **slreq wants the handle, allocation wants the object** |
| Can a component's behaviour BE an activity? | **No.** `systemcomposer.ArchitectureType` is `{Architecture, SoftwareArchitecture, SimulinkModel, SimulinkSubsystem, Stateflow}` — there is no `Activity` member, and `createBehavior` accepts nothing else. This is why `ExecuteMissionProfile` was deleted rather than kept as a component owning the mission (D-059) |
