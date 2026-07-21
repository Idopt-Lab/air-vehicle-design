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

Two folders are tracked in git but must stay untouched:
- `temp_Casey/` — Casey's original (buggy) sizing implementation. Reference only; several documented bugs (e.g. calls to non-existent methods) mean its code must never be copied, only used to cross-check equations.
- `temp_AI/` — AI-authored design material: `ai-workflows/` (original framing prompts), `docs/` (architecture + per-discipline + V&V specs, including `docs/00_framework_overview.md`), `xdsm/` (pyxdsm diagram scripts).

`sizing/docs/PLAN.md`'s step-status table is known to go stale — it can read "Not started" for steps that are actually implemented, tested, and committed. Check `git log` and the actual `src/`/`examples/`/`tests/` trees, not the table, to determine real progress.

When committing a large batch of new files spanning multiple disciplines, split commits by discipline (baseline, geometry, propulsion, aerodynamics, weights each separately; `fidelity_comparison` and `run_all_tests` each their own commit too), and never commit `.asv`, `__MACOSX`, `temp_AI`, `temp_Casey`, or `docs`.

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
- `baseline/F16Baseline.m` — the actual ground-truth data source used by tests: a struct of cited Brandt/Raymer/Mattingly/T.O. values (geometry, weights, engine, sizing targets), extracted via `baseline/extract_brandt.m`. Tests compare computed results against `F16Baseline()` fields with `RelTol` tolerances (looser at L1, tighter at L3) rather than exact equality — exact agreement with Brandt is explicitly not the goal.

  Note: PLAN.md's Step 0 describes a JSON-based data model (`examples/F16A/requirements.json` + `aircraft_spec.json`). That JSON layer does not exist in the tree yet — `F16Baseline.m` is the mechanism actually in use. Don't assume the JSON files exist without checking.

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

### Layer split (generic vs. aircraft-specific)

Independent of the tier split above, PLAN.md frames disciplines as two *layers*:
- **Layer 1** (`src/disciplines/`) — generic, parameterized textbook equations any aircraft can use by supplying inputs directly.
- **Layer 2** (`examples/<aircraft>/`) — an aircraft's subclass wiring in its spec data (AR, sweep, engine type, etc.) as constructor defaults. The subclass never changes the equations, only supplies the numbers a real aircraft's spec sheet would give you.

Critically: **do not hardcode Brandt's back-calculated calibration values** (e.g. `Cfe=0.005908`, `e_osw=0.9086`) into an F-16 subclass — those are sizing *outputs* Brandt derived by calibrating to his own model, not inputs from the F-16 spec sheet. Only genuine spec data (AR=3.0, sweep=40°, airfoil, engine model, etc.) belongs in a Tier-3 class. Brandt's outputs (W_TO=31,377 lb, OEW=19,980 lb, etc., listed in full in PLAN.md) exist only as validation targets to compare framework output against after a sizing run.

### Tests

`tests/` mirrors `src/`'s layout (`tests/core/`, `tests/disciplines/`). Test classes subclass `matlab.unittest.TestCase`; each documents the hand-computed expected value inline in a comment block above the `properties (Constant)` block, then asserts `verifyEqual(received, expected, 'RelTol', tol, message)` against either the hand-computed formula result or an `F16Baseline()` field. Generic-class tests and F-16-specific tests are not yet split into separate `tests/disciplines/` vs `tests/examples/F16A/` folders as PLAN.md's target layout describes — currently they live together in `tests/disciplines/`.

`.asv` files (MATLAB autosave) appear throughout `src/` — they're gitignored; ignore them when reading the tree.
