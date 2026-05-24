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

Level-Brandt is architecturally standalone: it does not inherit from `Disciplines/` or `ComputationModels/`, uses only static methods, and has no external dependencies beyond MATLAB's `atmosisa`.

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

### User Story 2 — Reproduce Brandt drag polar (P1)

A user calls `BrandtMission.dragPolar(CL)` and receives CD values matching the Brandt quadratic polar to within ±1% across the operating CL range (0.1 to 1.0).

**Acceptance Scenarios:**

1. **Given** `CD0=0.0270`, `k1=0.1160`, `k2=-0.00630`, **When** `CL=0.482`, **Then** CD matches `Miss!` sheet to within ±1%.
2. **Given** the Brandt quadratic polar, **When** L/D is maximized, **Then** L/D_max = 8.93 ± 0.09 (1%).

---

### User Story 3 — Reproduce Brandt engine model (P2)

A user calls `BrandtEngine.thrustLapse(altitude_ft, mach)` and receives α within ±1% of the Brandt `Engn(s)` sheet values at the specified conditions.

**Acceptance Scenarios:**

1. **Given** altitude=40,000 ft, Mach=0.87, **When** `thrustLapse` is called for mil power, **Then** α = 0.1417 ± 0.001.
2. **Given** installed TSFC correction factor = 1.08×, **When** TSFC_mil is computed at SLS, **Then** TSFC = 0.70 hr⁻¹ ± 1%.

---

### User Story 4 — Reproduce Brandt geometry (P2)

A user calls `BrandtGeometry.compute()` and receives wing geometry, wetted areas, and cross-sectional areas within ±1% of the Brandt `Geom` sheet.

**Acceptance Scenarios:**

1. **Given** standard F-16A geometry inputs, **When** `BrandtGeometry.compute()` is called, **Then** S_wet = 1,371 ft² ± 14 ft² (1%).
2. **Given** Amax computation, **When** whole-aircraft cross-sections are used (H26:H45), **Then** Amax matches `Geom!H47` to within ±1%.

---

### User Story 5 — Reproduce Brandt weight model (P3)

A user calls `BrandtWeights.compute()` and receives OEW broken down by structural component, each within ±1% of the Brandt `Wt` sheet.

**Acceptance Scenarios:**

1. **Given** Brandt plate-area weights (wing=6.75 lb/ft², fuse=5.0 lb/ft², pitch ctrl=6.0 lb/ft², vert surf=6.0 lb/ft²), **When** `BrandtWeights.compute()` is called, **Then** each component weight matches `Wt` sheet to within ±1%.

---

### Edge Cases

- What happens when `atmosisa` returns slightly different values than Brandt's atmosphere table? → Document the expected < 0.1% deviation as a known acceptable discrepancy.
- What happens if the sizing loop does not converge within 50 iterations? → Error out with a MATLAB error ID `LevelBrandt:convergenceFailed`.
- What if geometry inputs are outside physically valid ranges (negative area, AR < 0)? → Validate inputs and throw `LevelBrandt:invalidInput`.

---

## Requirements

### Functional Requirements

- **FR-001:** `LevelBrandt` MUST be implemented as a MATLAB classdef with only `methods (Static)` — no instance state, no inheritance from `Disciplines/` or `ComputationModels/`.
- **FR-002:** Every computed value MUST be traceable to a specific Excel cell in `Brandt-F16-A.xls`, documented in `examples/.../Ground-Truth/cell-map.md`.
- **FR-003:** All outputs MUST be within ±1% of their corresponding Brandt XLS cell values.
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

### Key Entities

- **`LevelBrandt`**: Orchestrator class. Calls all sub-classes in dependency order. Exposes `runF16A()` entry point.
- **`BrandtMain`**: F-16A master parameters (S_ref, AR, sweep, taper, Mcrit, fixed weights). Corresponds to `Main` sheet.
- **`BrandtGeometry`**: Wing, fuselage, tail geometry; wetted areas; Amax. Corresponds to `Geom` sheet.
- **`BrandtWeights`**: Structural plate-area weight model → OEW. Corresponds to `Wt` sheet.
- **`BrandtEngine`**: Thrust lapse, TSFC (mil and AB), installed correction. Corresponds to `Engn(s)` sheet.
- **`BrandtMission`**: 7-segment mission, quadratic drag polar, CDx corrections, fuel burn per segment. Corresponds to `Miss` sheet.
- **`BrandtSizing`**: TOGW convergence loop, W/S and T/W outputs. Corresponds to `Size&Opt` sheet.

---

## Success Criteria

- **SC-001:** All 13 key outputs in Dallas's ground truth table are within ±1% of their Brandt XLS values.
- **SC-002:** `LevelBrandt.runF16A()` runs to completion without error from a clean MATLAB session.
- **SC-003:** The cell-map.md file fully covers all key output cells in the XLS.
- **SC-004:** All `BrandtXxx` classes compile with zero errors and zero warnings in MATLAB R2023b or later.
- **SC-005:** One MATLAB unit test file exists per `BrandtXxx` class, covering: physical bounds, F-16A spot check, error handling.
- **SC-006:** An integration test runs `LevelBrandt.runF16A()` end-to-end and asserts all SC-001 tolerances programmatically.

---

## Assumptions

- Input parameters are read from `examples/F-16A B Block 10 and 15/Operator/` xlsx files (same files used by the main framework).
- MATLAB's `atmosisa` is available and produces standard-atmosphere results consistent with Brandt's atmosphere table to within < 0.1%.
- The Brandt XLS is the reference — where the XLS uses a non-standard approximation, the MATLAB code replicates the approximation, not the physics.
- Level-Brandt is for the F-16A only. Generalizing to other aircraft is out of scope for this feature.
