# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

MATLAB coursework repo for AOE 4065 (Air Vehicle Design). Three independent areas under `air_vehicle_design/`:

- **`sizing/`** — an aircraft conceptual-design sizing framework, being rewritten from scratch. This is where nearly all active work happens.
- **`mbse/examples/`** — Simulink/System Composer/requirements-toolbox examples (`.slx`, `.slreqx`), unrelated to `sizing/`.
- **`optimization/examples/`** — standalone MATLAB optimization demos (e.g. `ex1_rosenbrock/`, a 4-script fmincon + surrogate-modeling walkthrough — see its own README).

There is no package manager, build step, or linter — this is plain MATLAB source (`.m` classdef/script files) run inside the MATLAB IDE or `matlab -batch`.

## Working in `air_vehicle_design/sizing/` — read this first

`sizing/` is a from-scratch rewrite of a legacy Excel/MATLAB sizing tool, validated throughout against the F-16A Block 10/15 (Brandt spreadsheet) as ground truth. **Before doing any implementation work here, read `sizing/docs/PLAN.md` in full** — it is the living plan and source of truth for architecture decisions, not this file. Also check the relevant `sizing/docs/subplans/0N_*.md` for the step being worked on.

Non-negotiable rules from PLAN.md:
1. Every equation must cite a source (Raymer ch/eq, Roskam part/eq, Mattingly ch, Brandt section, etc.). Zero uncited equations.
2. Run MATLAB tests (`runtests`) after every change; a step isn't done until all tests pass.
3. `temp_Casey/` is read-only reference — cross-check equations against it, never modify or reuse its code directly.
4. No feature added beyond what the current step requires.
5. **After finishing a step (baseline/state → geometry → aerodynamics → propulsion → weights → constraints → mission → sizing), STOP and wait for review** — do not chain multiple steps together autonomously, even if the next step seems obvious.
6. Claude's responses and writing are to adhere to ASD-STE100 Simplified Technical English, located in \sizing\docs\ASD-STE100_ISSUE9.pdf.

Two folders are tracked in git but must stay untouched:
- `temp_Casey/` — Casey's original (buggy) sizing implementation. Reference only; several documented bugs (e.g. calls to non-existent methods) mean its code must never be copied, only used to cross-check equations.
- `temp_AI/` — AI-authored design material: `ai-workflows/` (original framing prompts), `docs/` (architecture + per-discipline + V&V specs, including `docs/00_framework_overview.md`), `xdsm/` (pyxdsm diagram scripts).

`sizing/docs/PLAN.md`'s step-status table is known to go stale — it can read "Not started" for steps that are actually implemented, tested, and committed. Check `git log` and the actual `src/`/`examples/`/`tests/` trees, not the table, to determine real progress.

When committing a large batch of new files spanning multiple disciplines, split commits by discipline (baseline, geometry, propulsion, aerodynamics, weights each separately; `fidelity_comparison` and `run_all_tests` each their own commit too), and never commit `.asv`, `__MACOSX`, `temp_AI`, `temp_Casey`, or `docs`.

### Discipline deep-dive process — use the project's custom subagents

For substantial discipline work (the Geometry deep-dive was first; the same process applies to future Aerodynamics/Propulsion/Weights deep-dives), use the project-scoped custom subagents in `.claude/agents/` rather than doing everything inline: `scribe`, `io`, `geometry-equations-expert`, `matlab-oop-expert`, `test-writer`, `test-verifier`. You (the main session) act as Coordinator — hold the approval gates, spawn the others via the `Agent` tool.

Process, with two hard human-approval gates before autonomous looping starts:
1. **`scribe`** documents the equations/citations/comparison values (per-file companion `.md` docs, parameter-usage tables) and logs any internal discrepancy it finds within `VnV/BrandtF16A` (the ground-truth source) to `VnV/BrandtF16A/todo.md` — never resolves such a discrepancy unilaterally. **STOP for user approval**, including sign-off on anything in `todo.md`.
2. **`io`** turns the approved documentation into the actual JSON input files and Brandt ground-truth comparison JSON. **STOP for user approval.**
3. Loop to green (no further gate): `geometry-equations-expert` + `matlab-oop-expert` implement/modify the `.m` files together (one owns equation/citation correctness, the other owns MATLAB OOP/coding practice); `test-writer` writes both test tiers (see below); `test-verifier` runs everything and reports factually; `scribe` logs any new discrepancies. Repeat until `run_all_tests` is green.

**Two test tiers, never blended**: unit/correctness tests (`tests/disciplines/Test*.m`, gate `run_all_tests`, must be green — deliberately-failing TODO tests for missing citations are the only expected exception, and must be clearly labeled as such) vs. a separate Brandt comparison report (e.g. `examples/F16A/*_brandt_comparison.m`, exports console/JSON/`.md`) that checks agreement with ground truth — informational, not pass/fail, and never used to backfill a unit test's "expected" value.

See `.claude/agents/*.md` for each role's full brief.

## Running tests

From MATLAB, with the working directory anywhere in the repo:

```matlab
cd('air_vehicle_design/sizing/tests')
run_all_tests   % adds src/, baseline/, examples/ to path, runs the whole suite, errors on any failure
```

To run a single test file or a single test method during development:

```matlab
addpath(genpath('air_vehicle_design/sizing/src'))
addpath(genpath('air_vehicle_design/sizing/baseline'))
addpath(genpath('air_vehicle_design/sizing/examples'))
runtests('air_vehicle_design/sizing/tests/disciplines/TestAeroL1.m')
runtests('air_vehicle_design/sizing/tests/disciplines/TestAeroL1.m', 'testCD0Formula')
```

Non-interactively (e.g. from a shell): `matlab -batch "cd('air_vehicle_design/sizing/tests'); run_all_tests"`.

Target MATLAB version is R2022b+ — use `arguments` blocks and `mustBe*` validators (as `AircraftState.m` does), and modern `matlab.unittest` patterns for tests.

## Architecture of `sizing/`

### Core
- `src/core/AircraftState.m` — immutable **value** class (not `handle`) representing ISA atmosphere at a given altitude/Mach. Built via MATLAB's `atmosisa`, converted to English units (lbf, ft, slug, ft/s, deg R). Carries `theta`/`delta`/`theta_0`/`delta_0` per Mattingly Eq. 2.52. Passed into most discipline methods as the flight-condition argument.
- `baseline/F16Baseline.m` — a struct of cited Brandt/Raymer/Mattingly/T.O. values (geometry, weights, engine, sizing targets). **Deprecated**, kept only because the weights and constraint tests still compare against `F16Baseline()` fields; geometry and aerodynamics now validate against `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`. Tests use `RelTol` tolerances (looser at L1, tighter at L3), not exact equality — exact agreement with Brandt is explicitly not the goal.

  Discipline inputs come from the unified per-level JSON `examples/F16A/f16a_L{1,2,3}.json` — one file per fidelity level, with `.geometry`/`.aerodynamics`/`.propulsion`/`.weights` blocks read by the matching `F16Geom*`/`F16Aero*`/`F16Prop*`/`F16Weights*` classes (resolved via `f16a_spec_path(level)`; constructors require the path — no silent default). **All four disciplines now read this unified JSON** — the older per-discipline input style is gone.

  **Requirements are a SEPARATE file** (added 2026-07-25): `examples/F16A/f16a_requirements.json`, resolved via `f16a_requirements_path()` — no `level` argument, because requirements do not vary with fidelity. This partly revives PLAN.md's Step-0 two-file model: the `requirements.json` half is real, the `aircraft_spec.json` half was not revived (per-level spec files serve that role). The distinction to keep: a **spec** file says what the aircraft *is* (areas, sweeps, thrust, airfoil); the **requirements** file says what it must *do*. Currently minimal — cruise altitude/Mach and design Mach — and expected to grow into the full requirement set with constraint and mission analysis. Consumers today: `F16WeightsL2/L3` (cruise condition for the SFC dependency injection, design Mach for the Raymer Eq. 10.10 engine weight) and `F16GeomL1` (design Mach → `AR_eq`).

  One canonical `aircraft_category` sits at the top level of each spec file, not inside a discipline block. It selects rows in six different textbook tables, and those tables name their categories differently (Roskam's CLmax table prints `fighter`, the others `jet_fighter`), so each lookup translates the canonical value to its own table's row name — see `AeroL1.to_CLmax_table_row`. **Do not rename a table row to match the key**: the row name is what the textbook prints, and the citation depends on it.

### The three-tier discipline pattern

Each discipline (`aerodynamics`, `geometry`, `propulsion`, `weights`, ...) is implemented across three files per fidelity level `N`, split across two directories. This is **not** the two-tier pattern PLAN.md's prose describes — it's an evolution introduced during implementation; treat the code as authoritative over the prose here:

```
src/base/<Discipline>Base.m            Tier 1 — abstract, declares the methods
                                        orchestrators call (e.g. drag_polar,
                                        get_CLmax) as abstract; provides
                                        concrete utility methods shared by
                                        every fidelity level unchanged.
        ^
src/disciplines/<discipline>/<Disc>ModelLN.m   Tier 2 — abstract "enforcer" for
                                        fidelity level N. Inherits the Base
                                        directly (NOT from ModelL(N-1)) and
                                        declares the additional abstract
                                        methods/properties that level needs.
        ^
examples/<Aircraft>/<Disc>LN.m         Tier 3 — concrete per-aircraft class.
                                        Every abstract method is a single
                                        delegation line into the matching
                                        static toolbox.
```

Alongside Tier 2/3 sits a **static toolbox**, `src/disciplines/<discipline>/<Disc>LN.m` (e.g. `AeroL1.m`) — a `classdef` of `methods (Static)` only, called as `AeroL1.method(...)`, never instantiated, and **not** part of the inheritance chain. It holds the actual textbook equations (with inline citations) at two tiers of its own: high-level statics that take the aircraft object and return a result (what the Tier 3 concrete class delegates to), and low-level statics that take only scalars/arrays (shared across fidelity levels, e.g. `AeroL1.oswald_eff` is also called by L2/L3 drag-polar paths).

Concretely, for F-16 aerodynamics at L1: `AerodynamicsBase` (abstract) ← `AeroModelL1` (abstract) ← `F16AeroL1` (concrete, in `examples/F16A/`), with equations living in the standalone `AeroL1` toolbox that `F16AeroL1` calls.

This pattern repeats identically for propulsion (`PropL*`/`PropulsionModelL*`), weights (`WeightsL*`/`WeightsModelL*`), and geometry (`GeomL*`/`GeometryModelL*`).

**Geometry HAS an L3 tier (reinstated 2026-07-24, promoted 2026-07-25).** `GeomL3`/`GeometryModelL3`/`F16GeomL3` exist and are the full L3 geometry tier, consumed by L3 geometry, aerodynamics **and** weights. This reverses the 2026-07-22 "Geometry has no L3" decision recorded in earlier versions of this file and still echoed in some `sizing/docs/` prose — the code is authoritative.

L3 geometry is the **physical / T.O.** tier: where a physical or T.O. 1F-16A-1 value differs from Brandt's, GeomL3 uses the physical one. Those divergences are intentional fidelity differences, **not errors**, and comparison reports annotate them `BY DESIGN`: VT LE sweep 47.5° vs L2's 40°, fuselage length 47.5 ft vs 46.5, and HT span 18.5 ft taken as the PRIMARY span (so `AR_ht` = `B_h²/S_ht` = 3.169 is *derived*, not Brandt's 3.0). Naming: the exposed-planform members carry an explicit `_exposed_` infix (`AR_exposed_ht`, `lambda_exposed_vt`, …) so that `AR_ht`/`lambda_ht`/`S_ht`/`S_vt` mean FULL planform at **both** tiers — an earlier version had the same names meaning different things on the two tiers, which silently fed exposed values into full-planform equations.

Two consequences worth knowing before touching geometry:
- **Geometry takes an injected propulsion object**: `F16GeomL2(json_path, prop)` / `F16GeomL3(json_path, prop)`. The nacelle diameter — and hence duct wetted area and CD0 — is sized from engine SLS thrust, which is engine data, not airframe data. `T_AB_SLS_lb` is `Dependent` on `prop.T_SL`; it is no longer a geometry input at either level.
- **`Amax` is tier-specific, deliberately.** L2 uses the fuselage-envelope ellipse `(pi/4)·W·H` (the low-fidelity form, per `VnV/BrandtF16A/readme_geom.md` §7). L3 uses the whole-aircraft **area-ruled buildup** that Raymer Eq. 12.44's Sears-Haack term actually wants. Do not "unify" these — using the envelope form at L3 is a fidelity inversion, and was a real bug.

There is still **no L3 propulsion tier** (no `PropL3`/`PropulsionModelL3`/`F16PropL3`), and none is planned: the L3 rung pairs `F16AeroL3` with `F16PropL2`, and anything reporting L3 propulsion numbers must label them "computed by `F16PropL2`". See `sizing/examples/F16A/F16GeomL3.md` for the full L3 geometry writeup and `sizing/src/disciplines/geometry/GeomL2.md` for the historical L2-merge note.

### Layer split (generic vs. aircraft-specific)

Independent of the tier split above, PLAN.md frames disciplines as two *layers*:
- **Layer 1** (`src/disciplines/`) — generic, parameterized textbook equations any aircraft can use by supplying inputs directly.
- **Layer 2** (`examples/<aircraft>/`) — an aircraft's subclass wiring in its spec data (AR, sweep, engine type, etc.) as constructor defaults. The subclass never changes the equations, only supplies the numbers a real aircraft's spec sheet would give you.

Critically: **do not hardcode Brandt's back-calculated calibration values** (e.g. `Cfe=0.005908`, `e_osw=0.9086`) into an F-16 subclass — those are sizing *outputs* Brandt derived by calibrating to his own model, not inputs from the F-16 spec sheet. Only genuine spec data (AR=3.0, sweep=40°, airfoil, engine model, etc.) belongs in a Tier-3 class. Brandt's outputs (W_TO=31,377 lb, OEW=19,980 lb, etc., listed in full in PLAN.md) exist only as validation targets to compare framework output against after a sizing run.

### Optimization-ready property design — inputs vs. derived (Dependent)

Everything downstream (constraint analysis, mission, the sizing loop) is an **optimization loop that mutates design variables on a discipline object in place** and expects updated outputs on the next read. So concrete Tier-3 classes (`F16GeomL2`, and every future `F16AeroL*`/`F16WeightsL*`/…) must split their properties into two kinds:

- **Inputs** — a plain, mutable `properties` block: the genuine design-variable spec data an optimizer varies (reference areas, aspect ratios, taper, sweep, t/c, fuselage envelope, engine thrust, …). The constructor sets these once from the JSON.
- **Derived** — a `properties (Dependent)` block: every quantity computed from the inputs (span, root/tip chords, MAC, sweep-station conversions, exposed/wetted areas, diameters, totals). Each has a `get.<name>` method that recomputes live from the inputs on every read, via the Base / `<Disc>L*N*` toolbox statics. There is **no stored/cached copy** — a derived value can never go stale, so the instant an optimizer changes an input (`obj.AR_wing = …`), every dependent read reflects it.

Do **not** compute a derived quantity once in the constructor and freeze it into a plain property — that silently goes stale under mutation (exactly the bug this pattern removes). Derived properties are read-only (no set-method); assigning to one errors, which is correct — they're outputs. The formulas are cheap closed-form algebra, so recompute-on-read costs nothing measurable and buys correctness-by-construction with zero cache bookkeeping. `examples/F16A/F16GeomL2.m` is the reference implementation — see its header block for the full rationale. This also dovetails with the JSON split: only true inputs live in the input JSON; derived quantities are never stored there, they're computed by the Dependent getters.

### Tests

`tests/` mirrors `src/`'s layout (`tests/core/`, `tests/disciplines/`, `tests/constraints/`). Test classes subclass `matlab.unittest.TestCase`; each documents the hand-computed expected value inline in a comment block above the `properties (Constant)` block, then asserts `verifyEqual(received, expected, 'RelTol', tol, message)` against either the hand-computed formula result or an `F16Baseline()` field. Generic-class tests and F-16-specific tests are not yet split into separate `tests/disciplines/` vs `tests/examples/F16A/` folders as PLAN.md's target layout describes — currently they live together in `tests/disciplines/`.

`.asv` files (MATLAB autosave) appear throughout `src/` — they're gitignored; ignore them when reading the tree.
