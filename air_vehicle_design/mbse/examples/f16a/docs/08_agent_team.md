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
10. **Leave the comma after `catch`.** Stage 3's lint sweep took the comma off `try` at 28 sites
    (`try, x; catch, end` → `try x; catch, end`), so the two now look inconsistent. They are not:
    `catch` takes an identifier, so `catch, x = 1;` and `catch x = 1;` mean different things — the
    second binds `x` as the exception object. `mlint` flags the `try` comma and never the `catch`
    one, which is the whole distinction. Do not "fix" the asymmetry. (Verified Stage 3: **four** parties
    spelled the sweep identically without coordinating — `f16a-logical`, `f16a-vnv` and
    `f16a-physical` on their own layers, and the orchestrator on `F16AOpenForReview.m`, which no
    agent owns, and on `generate_f16a_functional.m`, which `f16a-functions` owns but was not
    dispatched for. So the example is uniform: `try,` now appears in no `.m` file — checked with a
    **word boundary**, since a bare `try,` also matches "geome*try,*"; see A14 trap 4 in `TODO.md`.)
11. **A finding is a measurement and its evidence, not a mechanism.** Rule 1 forbids inventing a
    number; the same discipline applies to claims about the *tooling*. In Stage 3 one false-positive
    `CTPCT` warning collected **three confident explanations from three different authors, in one
    stage**, each generalised honestly from too few cases — and a six-case probe refuted all three
    (**A10** in `TODO.md`). Record what you ran and what it returned; let the cause read "unknown"
    when it is. All three were caught only because each was stated precisely enough to be probed.
    That is the standard, not a lucky escape.

## R2026a API findings (Stage-0 probe)

Measured on this machine — the Stage-0 rows on a throwaway model, the later ones on the example's own
artifacts — not recalled from documentation. These drive real design choices, so they are recorded
here rather than buried in a comment.

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
| 9 | Does regenerating a requirement set orphan a **hand-made Verify link**? (Stage 2) | **No.** All four sets were rebuilt through `slreq.new`, and `REQ_F16A_022` and `REQ_F16A_P01` still reported `Implement, Verify` afterwards: with requirement ids and their order unchanged, the links held in `verification/*~m.slmx` still resolve. Confirmed by a second route: **every SID was preserved**, sid↔customId identical old-vs-new in all four sets — which is why the links held, and the boundary of the guarantee. Measured alongside it — nothing *loads* those sets automatically: not opening the models, and not the project's Digital Thread artifact tracking. Only an explicit `slreq.load` does | A hand-made Verify link may be made **before** the next rebuild; re-linking need not be paired with regeneration, which is how TODO A2b/B3 had been sequenced. And a Verify link that looks missing is almost always one whose link set is unloaded — the job `F16AOpenForReview` exists to do |
| 10 | What does `%#ok<CTCH>` actually suppress? (Stage 3) | **Nothing — `CTCH` does not fire at all.** `checkcode` was probed on four forms — bare `catch` + empty body, bare + body, bare + multiline body, and `catch err` — and reported it in none: the check is not enabled in R2026a's default configuration. Two agents had predicted opposite triggers (an *empty* catch vs. a *bare* one) from the message text; **both were wrong**, and under the "bare" reading the example would have had ~25 unsuppressed messages | A10's *"static analysis is otherwise clean"* stands — no messages are hidden behind these. The existing suppressions are **inert**, and `MSNU` does not report them as stale, so there is nothing to delete and nothing to add: **do not put `%#ok<CTCH>` on new `try`/`catch` code, and do not strip the existing ones.** Removing them is churn that changes no output |
| 11 | `dictionary` vs `containers.Map` — key order, and non-scalar values (Stage 3) | **`dictionary` returns keys in INSERTION order; `containers.Map` returned them SORTED** — probed on the same three role names, so the two disagree on a model this example actually builds. Separately, **`configureDictionary("string","cell")` works** — the cell-valued route is available, not unverifiable as had been assumed | Migration is not order-neutral: any consumer that silently relied on `containers.Map` sorting its keys changes behaviour. `F16APhysicalTradeStudy`'s migration therefore documents the new order in its own help block, and the three remaining test-local maps are deferred as one job (**A15** in `TODO.md`). The `configureDictionary` result does **not** un-defer `allocTargetsByRole` — the route exists, but a string array per key still means brace indexing, which is a rewrite of the helper rather than a type substitution |

Pre-existing gotchas that still hold: connect ports with the **two-argument** `connect(src,dst)`;
unload allocation sets and profiles *before* closing models/dictionaries in a generator's cleanup;
`string(NaN)` is `<missing>` and `setProperty` rejects it — use `string(num2str(NaN))`.

## Stage history

See [`07_decision_log.md`](07_decision_log.md) for what was decided, by whom, and why.
