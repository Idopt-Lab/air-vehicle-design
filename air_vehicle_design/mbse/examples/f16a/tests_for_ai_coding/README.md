# tests_for_ai_coding

Guard rails, not teaching material.

These four suites exist so that an agent (or a human) editing a generator cannot
silently break the model. They ask **"is the model built correctly?"** — never
"is this the right design?". They are the reason a refactor can be trusted, and
they are *not* part of the lesson.

```matlab
openProject("f16a.prj")
run_ai_tests          % all four suites; every one must be green
```

| Suite | Checks |
|---|---|
| `F16ARequirementsTest` | the four requirement sets: ids, counts, keywords, no vendor token or number in a decision requirement |
| `F16AFunctionalArchitectureTest` | the F model: 26 functions, no unconnected port, R→F Implement links |
| `F16ALogicalArchitectureTest` | the L model: 9 roles, 4 interfaces, 14 allocation edges, 6 technology-neutral kinds, and that **no number ever appears at L** |
| `F16APhysicalArchitectureTest` | the P model: 30 components, the three candidate stereotypes and their per-trade property sets, the 16 leaf masses against the `sizing/` ground truth, roll-up self-consistency, the L→P realization, provenance, each trade's recorded verdict |

`F16ATestCase` is the shared base class: the architecture walk, the stereotype
and profile readers, and `verifyNoOffenders` / `verifyNotVacuous`. It is abstract
and contributes no tests of its own.

There was a fifth suite, `F16APhysicalTradeGuardsTest`, driving a shared guard
class **negatively** — bad input had to produce a named error — and touching no
artifact, so it ran on a checkout with no models in it. D-056 split the trade
three ways and moved each trade's guards inline, leaving no single contract for
that class to hold; the suite went with it.

## This is not `verification/`

The distinction is the point, and it is why these were moved out of the layer
folders (D-055).

|  | `tests_for_ai_coding/` | `verification/` |
|---|---|---|
| Asks | is the model **built** correctly? | does the **design** meet this requirement? |
| Asserts | structure, links, self-consistency | one requirement's criterion |
| Expected state | **all green** | **two of three red, by design** |
| Traceability | none | a hand-made **Verify** link per test |
| Audience | whoever is changing the model | students |

The three tests in `verification/` are the teaching payload — they show a
requirement that is met, one that is *unevaluated*, and one that is *violated*.
Read [`../docs/README.md`](../docs/README.md), "Three requirements, three
verification states", before touching them. **Nothing here should ever be red;
two things there always are.**
