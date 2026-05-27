# Feature Specification: Level-Brandt — F-16A Brandt Excel Reimplementation

**Feature Branch:** `level-brandt`

**Created:** 2026-05-24

**Status:** Draft

**Owner (spec):** Dallas  
**Owner (implementation):** Vasquez  
**Gate:** Hicks  
**Architecture review:** Bishop

---

## Purpose

Implement `src/level_brandt/` as a direct, faithful MATLAB reimplementation of the Brandt F-16A Excel workbook (`examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`). This is **not** an approximation — it is a reference implementation that must reproduce each Excel cell value to within ±1%. It serves as the absolute ground truth against which all fidelity levels (I–III) are calibrated.

Level-Brandt is architecturally standalone: it does not inherit from `Disciplines/` or `ComputationModels/`, and has no external dependencies beyond MATLAB's `atmosisa`.

---

## User Scenarios & Testing

### User Story 1 — Reproduce Brandt sizing outputs (P1)

A user runs `LevelBrandt.runF16A()` and receives TOGW, OEW, W/S, T/W, S_ref, and fuel all within ±1% of their respective Brandt XLS values. The outputs are printed in a formatted table alongside the Brandt reference values and % differences.

**Why this priority:** This is the core purpose of Level-Brandt. Without this, there is no reference to calibrate against.

**Independent Test:** Run `LevelBrandt.runF16A()` and check the returned struct against ground truth values.

**Acceptance Scenarios:**

1. **Given** all F-16A input parameters are loaded from `Operator/` xlsx files, **When** `LevelBrandt.runF16A()` is called, **Then** TOGW is within ±1% of 29,657 lb (`Size&Opt` sheet).
2. **Given** the sizing loop runs, **When** convergence is reached, **Then** OEW is within ±1% of 19,981 lb (`Wt` sheet).
3. **Given** the sizing loop runs, **When** convergence is reached, **Then** fuel burn is within ±1% of 5,671 lb (`Size&Opt` sheet).

---

### User Story 2 — Accurate aerodynamics (P1)

A user creates `BrandtAerodynamics`, calls `analyze(design_vars)` to precompute design-variable-dependent quantities, then calls `run(state_vector, control_vector)` to evaluate aerodynamics at flight conditions. This enables accurate drag polar construction and sizing constraint evaluation.

**Acceptance Scenarios:**

1. **Given** `BrandtAerodynamics.analyze(design_vars)` has run, **When** properties are queried, **Then** CDmin = 0.01691 (Aero!G3) and k1 = 0.1160 (Aero!G10), each within ±5%.
2. **Given** the subsonic mission polar (Miss tab basis), **When** `run(state_vector, control_vector)` is called, **Then** returns struct with fields CD0, K1, K2, CLmax_clean, CLmax_TO, CLmax_land, LD_max; values within ±5% of `Miss!` sheet.
3. **Given** the subsonic polar, **When** L/D_max is computed, **Then** L/D_max = 8.93 ± 0.45 (5%) and CL_opt = 0.482 ± 5%.
4. **Given** `BrandtAerodynamics.analyze()` has completed, **When** CLmax values are read from properties, **Then** CLmax_clean = 0.984 (Aero!H25), CLmax_takeoff = 1.276 (Aero!H27), CLmax_landing = 1.426 (Aero!H29), each within ±5%.
5. **Given** a supersonic condition in state_vector, **When** `run(state_vector, control_vector)` is called, **Then** CDmin > CDmin_sub (wave drag present) and k2 ≤ 0 per Aero tab methodology.

---

### User Story 3 — Accurate propulsion (P2)

A user creates `BrandtEngine`, calls `analyze(design_vars)` to precompute design-variable quantities, then calls `run(altitude_ft, mach, AB_flag, options)` to query thrust and TSFC at flight conditions. This supports mission fuel burn and sizing T/W evaluations.

**Acceptance Scenarios:**

1. **Given** `BrandtEngine.analyze(design_vars)` has run, **When** `run(0, 0, false)` is called (SLS, dry), **Then** returns struct with fields {alpha, T, TSFC} where T = 15,000 lbf and TSFC = 0.70 hr⁻¹, each within ±5% of `Engn(s)` sheet.
2. **Given** `BrandtEngine.analyze(design_vars)` has run, **When** `run(0, 0, true)` is called (SLS, afterburner), **Then** returns struct with T = 23,770 lbf and TSFC = 2.20 hr⁻¹, each within ±5%.
3. **Given** altitude=40,000 ft, Mach=0.87, dry throttle, **When** `run(40000, 0.87, false)` is called, **Then** T and TSFC match the `Engn(s)` tab throttle-ratio branching formula within ±5%.
4. **Given** altitude=40,000 ft, Mach=0.87, afterburner, **When** `run(40000, 0.87, true)` is called, **Then** T and TSFC match the `Engn(s)` tab AB branch formula within ±5%.
5. **Given** a range of altitudes (0–60,000 ft) and Mach numbers (0–2.0) with dry and AB settings, **When** `run()` is queried across the grid, **Then** the resulting engine map is monotonically decreasing with altitude (at fixed Mach) and thrust increases with Mach at low altitude (ram recovery), consistent with the Brandt model.

---

### User Story 4 — Reproduce Brandt geometry (P2)

A user calls `BrandtGeometry.analyze(design_vars)` to precompute geometry, then queries wing geometry, wetted areas, and cross-sectional areas via `run()` within ±1% of the Brandt `Geom` sheet.

**Acceptance Scenarios:**

1. **Given** standard F-16A geometry inputs, **When** `BrandtGeometry.analyze(design_vars)` is called, **Then** S_wet = 1,371 ft² ± 14 ft² (1%).
2. **Given** Amax computation, **When** whole-aircraft cross-sections are used (H26:H45), **Then** Amax matches `Geom!H47` to within ±1%.

---

### User Story 5 — Reproduce Brandt weight model (P3)

A user calls `BrandtWeights.analyze(design_vars)` and receives OEW broken down by structural component, each within ±1% of the Brandt `Wt` sheet.

**Acceptance Scenarios:**

1. **Given** Brandt plate-area weights (wing=6.75 lb/ft², fuse=5.0 lb/ft², pitch ctrl=6.0 lb/ft², vert surf=6.0 lb/ft²), **When** `BrandtWeights.analyze(design_vars)` is called, **Then** each component weight matches `Wt` sheet to within ±1%.

---

### Edge Cases

- What happens when `atmosisa` returns slightly different values than Brandt's atmosphere table? → Document the expected < 0.1% deviation as a known acceptable discrepancy.
- What happens if the sizing loop does not converge within 50 iterations? → Error out with a MATLAB error ID `LevelBrandt:convergenceFailed`.
- What if geometry inputs are outside physically valid ranges (negative area, AR < 0)? → Validate inputs and throw `LevelBrandt:invalidInput`.

---

## Requirements

### Functional Requirements

- **FR-001:** `LevelBrandt` and all `BrandtXxx` classes MUST be implemented as true OOP MATLAB classdefs using `handle` inheritance. Classes MUST use instance methods and properties for computed state (e.g., `compute()` populates `obj.geom`, `obj.weights`). Pure math helpers with no object state MAY be `Static`. No inheritance from `Disciplines/` or `ComputationModels/`.
- **FR-002:** Every computed value MUST be traceable to a specific Excel cell in `Brandt-F16-A.xls`, documented in `examples/.../Ground-Truth/cell-map.md`.
- **FR-003:** All outputs MUST be within ±1% (target) of their corresponding Brandt XLS cell values; deviations up to ±5% are acceptable where formula approximations or atmosphere model differences account for the gap.
- **FR-004:** The drag polar MUST use the Brandt quadratic form: `CD = CD0 + k1·CL² + k2·CL` (not the standard parabolic `CD0 + K·CL²`).
- **FR-005:** TSFC MUST apply the 1.08× installed correction factor (`Engn(s)` sheet).
- **FR-006:** Mission analysis MUST implement all 7 Brandt segments: Takeoff → Accel → Climb → Cruise (190.8 nm) → Patrol → Dash (50 nm) → Patrol.
- **FR-007:** Each mission leg MUST apply Brandt's CDx correction: 0.035 for takeoff, 0.010 for all others.
- **FR-008:** Weight estimation MUST use Brandt structural plate-area weights, not Raymer Chapter 15 regressions.
- **FR-009:** Geometry Amax MUST be computed from whole-aircraft cross-sections H26:H45 (W+Y+AA+AC+AE+AG), not fuselage-only frame areas.
- **FR-010:** The sizing loop MUST converge the TOGW fixed-point iteration with a tolerance of 0.01% and a maximum of 100 iterations.
- **FR-011:** All units MUST be English: lbf, ft², ft, ft/s, slug/ft³. No SI anywhere in `level_brandt/`.
- **FR-012:** Every equation MUST be cited in a code comment with the source (Brandt XLS cell reference or textbook citation).
- **FR-013:** `LevelBrandt.runF16A()` MUST print a validation table: parameter | Brandt value | computed value | % difference.
- **FR-014:** All tests in `src/level_brandt/tests/` must pass before any code change is considered final. Tests must use MATLAB's `matlab.unittest.TestCase` framework.
- **FR-015:** All discipline classes MUST implement the three-tier interface: (1) Constructor loads fixed external inputs and initializes all properties to NaN; (2) `analyze(design_vars)` computes design-variable-dependent quantities; (3) `run(state, control, options)` evaluates discipline outputs for flight conditions and MUST return AND store results (dual-return contract), always ending with `validate_run_()` call. The term `compute()` is FORBIDDEN as a method name (reserved by OpenMDAO).
- **FR-016:** If an implementation requires a value that is computed inside another discipline's class (e.g., a differently-normalised thrust lapse), the correct action is to **extend that discipline's `run()` output struct** to expose the needed value — NOT to re-implement the computation locally. Document the added field in the discipline's readme and add a corresponding test assertion. Re-implementing cross-discipline logic in a consuming class is a code-review failure.

### Key Entities

- **`LevelBrandt`**: Orchestrator class. Calls all sub-classes in dependency order. Exposes `runF16A()` entry point.
- **`BrandtGeometry`**: Wing, fuselage, tail geometry; wetted areas; Amax. Corresponds to `Geom` sheet.
- **`BrandtAerodynamics`**: Mach-dependent drag polar (CD0, k1, k2), CLmax at clean/takeoff/landing, L/D max, lift curve slopes. Corresponds to `Aero` sheet.
- **`BrandtEngine`**: Installed thrust and TSFC at given altitude, Mach, and throttle setting (dry/AB); engine map generation. Corresponds to `Engn(s)` sheet.
- **`BrandtWeight`**: Structural plate-area weight model → OEW. Corresponds to `Wt` sheet.
- **`BrandtMission`**: 7-segment mission, quadratic drag polar, CDx corrections, fuel burn per segment. Corresponds to `Miss` sheet.
- **`BrandtSizing`**: TOGW convergence loop, W/S and T/W outputs.
- **`BrandtPerformance`**: Specific excess power, maneuver envelope, V-n envelope, performance calculations. Corresponds to `Ps`, `Maneuv`, `Struct`, and `Perf` tabs.
- **`BrandtLandingGear`**: Landing gear geometry and weight estimation. Corresponds to the `Gear` tab.
- **`BrandtStabilityControl`**: Stability and control derivatives and margin estimation. Corresponds to the `S&C (2)` tab.
- **`BrandtCost`**: Life-cycle cost estimation. Corresponds to `Cost` tab.

---

## Success Criteria

- **SC-001:** All 13 key outputs in Dallas's ground truth table are within ±1% of their Brandt XLS values.
- **SC-002:** `LevelBrandt.runF16A()` runs to completion without error from a clean MATLAB session.
- **SC-003:** The cell-map.md file fully covers all key output cells in the XLS.
- **SC-004:** All `BrandtXxx` classes compile with zero errors and zero warnings in MATLAB R2023b or later.
- **SC-005:** One MATLAB unittest file (inheriting from `matlab.unittest.TestCase`) exists per `BrandtXxx` class, covering: physical bounds, F-16A spot check, error handling.
- **SC-006:** Level-Brandt discipline interface pattern: Constructor (loads fixed external inputs, initializes to NaN) → `analyze(design_vars)` (design-variable pass) → `run(state, control, options)` (state/control evaluation with dual-return contract). At Level-Brandt fidelity, named scalar arguments replace full state/control vectors.
- **SC-006:** An integration test runs `LevelBrandt.runF16A()` end-to-end and asserts all SC-001 tolerances programmatically.

---

## Testing Policy

### Test Gate (Mandatory)

Before finalizing any code change to `src/level_brandt/`, ALL tests in `src/level_brandt/tests/` MUST be run and ALL must pass. This ensures that previously cross-checked and vetted implementations remain correct.

**How to run all tests:**
```matlab
% From MATLAB, with repo root on path:
results = runtests('src/level_brandt/tests');
assert(all([results.Passed]), 'Not all tests passed — see results table above');
```

If a test fails and the failure is NOT caused by the change being made, it must be investigated and resolved before proceeding.

### Test Format (Mandatory)

All tests in `src/level_brandt/tests/` MUST be MATLAB unittest classes inheriting from `matlab.unittest.TestCase`. Script-based tests are not acceptable.

**Required pattern:**
```matlab
classdef test_BrandtXxx < matlab.unittest.TestCase
    properties (Access = private)
        obj  % shared fixture
    end
    methods (TestClassSetup)
        function buildFixture(tc)
            % Build and compute shared objects here
        end
    end
    methods (Test)
        function testSomeProperty(tc)
            tc.verifyEqual(actual, expected, 'RelTol', 0.01);
        end
    end
end
```

**Three-Tier Interface Contract Example:**
```matlab
% 1. Constructor: loads fixed inputs only
geom = BrandtGeometry(jsonPath);  % obj properties initialized to NaN

% 2. analyze(): design-variable pass
geom.analyze(wing_area, fuselage_length);  % populates all computed geometry properties

% 3. run(): state/control pass with dual-return
results = geom.run(altitude_ft, mach);     % returns AND stores on obj
% or equivalently:
geom.run(altitude_ft, mach);               % results stored as obj.run_* properties
```

### Known Acceptable Deviations

Some tests for `BrandtMission` use 2% tolerance (instead of 1%) for segments where the code intentionally differs from the Brandt Excel:
- **Climb, Egress, Cruise2 fuel burns**: deviation traces to the known S_wet discrepancy (Excel double-counts strakes — documented in `readme_geom.md`). Code uses 1332.69 ft² (correct); Excel uses 1371.09 ft². This is intentional and acceptable per FR-003.

---

## Assumptions

- Input parameters are read from `examples/F-16A B Block 10 and 15/Operator/` xlsx files (same files used by the main framework).
- MATLAB's `atmosisa` is available and produces standard-atmosphere results consistent with Brandt's atmosphere table to within < 0.1%.
- The Brandt XLS is the reference — where the XLS uses a non-standard approximation, the MATLAB code replicates the approximation, not the physics.
- Level-Brandt is for the F-16A only. Generalizing to other aircraft is out of scope for this feature.
