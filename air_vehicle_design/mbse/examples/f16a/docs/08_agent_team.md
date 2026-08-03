# The agent team

> Agent definitions: `.claude/agents/f16a-*.md` (repo root) · Decision log:
> [`07_decision_log.md`](07_decision_log.md) · Method grounding:
> [`06_methodology.md`](06_methodology.md)

This example is maintained by a **team of specialist AI agents**, one per concern, coordinated by an
orchestrator that stops for human approval at the end of every stage. The split is deliberate and is
itself part of the teaching material: it mirrors how a real systems-engineering team is organised —
layer owners who build, a data authority who owns ground truth, an independent V&V owner, a
methodologist who keeps the method honest, and a scribe who records *why*.

This file is the **single source of truth for house rules**. Every agent reads it before acting.

## Roles

| Agent | Mandate | Owns | Must load |
|---|---|---|---|
| **Orchestrator** (main session) | Splits work into stages, routes handoffs, runs the gates, commits | staging, git | `matlab-software-development:matlab-analyze-dependencies` |
| **f16a-requirements** | The R layer and link semantics (Implement vs Verify) | `requirements/` | `model-based-design-core:generate-requirement-drafts` |
| **f16a-functions** | The F layer; guardian that F and the F→L allocation survive changes below | `architecture/` | `model-based-system-engineering:building-architecture-models` |
| **f16a-logical** | The L layer: technology-neutral *kinds*, no numbers, no decisions | `logical/` | `model-based-system-engineering:building-architecture-models`, `model-based-design-core:building-simulink-models` |
| **f16a-physical** | The P layer: concrete candidates, stereotypes, roll-ups, the trade study | `physical/` | same as L, plus `matlab-core:matlab-debugging` |
| **f16a-vnv** | **All** tests. Writes assertions independently of whoever wrote the code | `*ArchitectureTest.m`, `verification/` | `matlab-core:matlab-testing`, `verification-validation-and-test:checking-model-compliance` |
| **f16a-data** | Ground truth + provenance. **Veto at every gate.** | the numbers, wherever they live | reads `sizing/VnV/BrandtF16A/` (read-only) |
| **f16a-scribe** | `docs/`, the decision log, and the MATLAB help block of every touched file | `docs/` | `matlab-software-development:matlab-write-help`, `matlab-core:matlab-review-code` |
| **f16a-mbse-method** | Literature grounding; referee when L and P disagree about *where* something belongs | `06_methodology.md` | web research |

## House rules

1. **No agent invents a number.** Every value is either traceable to
   `sizing/VnV/BrandtF16A/` (tag `Reference`), a real datasheet (`Datasheet`), an analysis
   (`Simulation`), or is an explicit `Estimate` — and an `Estimate` must be labelled as such in the
   model *and* listed in the decision log. `f16a-data` can veto any number at any gate.
2. **Use the MathWorks skills.** Load the skills listed above before touching MATLAB; do not
   improvise API usage.
3. **Confirm the API, don't recall it.** Check R2026a signatures with
   `matlab-core:matlab-read-doc` (or the findings below) before writing generator code.
4. **Write scope.** Only `air_vehicle_design/mbse/`. `sizing/` is read-only reference. The one
   exception is `.claude/agents/` at the repo root, where agent definitions must live to be
   discoverable.
5. **Generators are idempotent.** Every artifact is rebuilt from scratch by its `generate_*.m`;
   never hand-edit a `.slx`, `.sldd`, `.xml` profile or `.mldatx` — change the generator and re-run.
6. **Layer independence.** An agent may read any layer but writes only its own. Cross-layer writes
   (e.g. the P trade setting the L active kind) are explicit, documented, and touch only the link
   set of the model they belong to.
7. **Handoff report.** Every agent returns: files changed · decisions (id + one line) · assumptions
   · numbers introduced with provenance · tests run and results · open risks. Numbers go to
   `f16a-data`, decisions to `f16a-scribe`, method disputes to `f16a-mbse-method`.
8. **Gates.** Work is staged; at the end of a stage the orchestrator presents the diff, the new
   decision-log entries and the test results, and asks the human to approve. Nothing starts before
   its gate clears. One commit per stage.
9. **Cite by name, not by line number.** Point at a requirement id, function, class or heading, never
   `file.m:240` — line numbers rot on the next edit; Stage 1's comment trim invalidated five citations
   in one pass. The exception is `07_decision_log.md`, which is append-only: a dated entry citing
   lines as they were is not wrong, it is dated, and is left alone.

## R2026a API findings (Stage-0 probe)

Measured on this machine with a throwaway model, not recalled from documentation. These drive real
design choices, so they are recorded here rather than buried in a comment.

| # | Question | Finding | Consequence |
|---|---|---|---|
| 1 | Can a stereotype property be an **enumeration**? | **Yes** — `addProperty(…, Type="MyEnumClass")` accepts both an `int32`-derived enumeration and a plain MATLAB `enumeration` class, as long as the classdef is on the path. Write the value **fully qualified and unquoted** (`"F16ASourceKind.TradeWinner"`) or as the **quoted bare member** (`"'TradeWinner'"`); the two other forms error. It reads back as char `'TradeWinner'` — **with quotes**, like a string property (finding 7) | `DataProvenance` and `SourceKind` are real enumerations (Property Inspector dropdowns, validated vocabulary) instead of free strings. Plain `enumeration` classes are enough — no `int32` base needed |
| 2 | Does `instantiate`/`iterate` traverse **inactive** variant choices? | **No.** The analysis instance contains only the active choice; an inactive choice's path is unresolvable in the instance | The native mass roll-up is automatically an *active-configuration* roll-up — no `Selected` filter needed there |
| 3 | What does the instance look like around a variant? | It is **flattened**: the active choice node is elided and its children are lifted under the variant node. `…/Airframe/Wing` in the instance ≠ `…/Airframe/BlendedCrankedDelta/Wing` in the architecture | Two path spaces. Instance paths (roll-ups) keep working unchanged; architecture paths (generators, tests, `lookup` on the model) gain the choice level |
| 4 | Can a stereotype be applied to a **variant component**? | **No** — `applyStereotype` errors on `systemcomposer.arch.VariantComponent`. It works on the variant's *choices* | `PhysicalItem` / `Rationale` go on choices and plain components; the variant *role* wrapper is exempt. The instance node for the variant still carries the rolled-up value |
| 5 | Ordering | `getChoices` returns choices **alphabetically**, not in creation order | Never assume "first choice = production" — always `setActiveChoice` by name |
| 6 | Reaching a variant's choices (Stage 1) | `getChoices(vc)` is the **only** reliable accessor. `vc.Architecture.Components` returned the 2 choices on a freshly built in-memory model but **0** on the same model saved and reloaded | Any architecture-side walk — generator, roll-up fallback, test, component count — must special-case a `VariantComponent` and use `getChoices` (or `getActiveChoice` when it wants the active configuration only). A recursion over `.Architecture.Components` will silently skip every candidate on a loaded model |
| 7 | String properties (Stage 1) | A string stereotype property stores its default/value as a MATLAB **expression**: write `"'TBD'"`, and `getProperty` hands back `'TBD'` **with the quotes** | Write quoted, read with `erase(…, "'")` — the same convention the `MeasureOfMerit.Goal` property and its test already use |
| 8 | What the flattened variant node *holds* (Stage 3) | Finding 3 said the active choice node is elided; measured further: the variant's instance node then **carries the active choice's own property value**, including when that choice is a **leaf**. `Engine ▽ → F100_PW_200` reports 4730.23 lb at the `…/Propulsion/Engine` instance node | The mass roll-up needed **no change** to become an active-configuration roll-up across three new variation points — `rd(S+"Airframe")` and `rd(S+"Propulsion/Engine")` keep working verbatim. Had it gone the other way, both leaf candidates would have contributed 0 and OEW would have read 14,778.06 lb |

Pre-existing gotchas that still hold: connect ports with the **two-argument** `connect(src,dst)`;
unload allocation sets and profiles *before* closing models/dictionaries in a generator's cleanup;
`string(NaN)` is `<missing>` and `setProperty` rejects it — use `string(num2str(NaN))`.

## Stage history

See [`07_decision_log.md`](07_decision_log.md) for what was decided, by whom, and why.
