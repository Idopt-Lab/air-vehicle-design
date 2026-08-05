# Example 2 — linking requirements to a System Composer model

A small, hand-built System Composer example: one architecture model (`Aircraft.slx`), one requirement
set (`F16A.slreqx`), and the links between them. It is the warm-up for
[`../f16a`](../f16a), the full RFLP example.

Open `Updated_VT_Project.prj` first — it sets the path. Then work through `Example.mlx`.

## What is in here

| File | What it is |
|---|---|
| `Aircraft.slx` | The architecture: Fuselage → Threat → Detect (AESA, PESA), Wing → Wingbox → Load |
| `F16A.slreqx` | The requirement set, with `F - …` functions deriving `R - …` requirements |
| `DetectProfile.xml` | The stereotype profile: `Physical` with `Cost`, `Weight`, `Active` |
| `ActiveTest.m` | Verifies the active Detect variant has Range > 100 |
| `Test_structural_integrity.m` | Runs the `three_g` / `nine_g` load models and checks their output |
| `CostAndWeightRollupAnalysis.m` + `model_instance.m` | A postorder cost/weight roll-up over the instance |
| `Example.mlx` | The narrated walk-through |

Run the tests with `runtests("ActiveTest")` and `runtests("Test_structural_integrity")`.

## Coverage is deliberately partial

`Example.mlx` asks you to switch on the **Implementation Status** and **Verification Status** columns
in the Requirements Editor. Expect them to be mostly empty. Only two requirements are covered:

| Requirement | Implemented by | Verified by |
|---|---|---|
| `R - Detect` | `Aircraft.slx` | `ActiveTest.m` |
| `R - Structure` | `Aircraft.slx` | `Test_structural_integrity.m` |
| `R - Propulsion` | — | — |
| `R - Target`, `R - Engage`, `R - Verify` | — | — |

That is the point of the exercise, not an oversight: a requirement set records what the system *shall*
do from the start, and coverage arrives later, requirement by requirement. Reading those two columns
is how you tell which requirements have an answer and which are still just a statement of intent.

`../f16a` carries the same idea further — there, a requirement can also be *verified and failing*,
which is a third state again.
