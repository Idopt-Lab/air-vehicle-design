# Dietrich — History

Mission Analysis Specialist — owns compute_fuel and Breguet segments. Brandt uses 7-segment profile with CDx corrections per leg. Calls Drake and Gorman at each segment.

## Project Context

**Project:** AOE 4065 Air Vehicle Design (Idopt-Lab/air-vehicle-design)
**User:** Darshan Sarojini
**Language:** MATLAB (all source code)
**Ground truth:** `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`
**Key docs:** `ai-workflows/claude/CLAUDE.md`, `ai-workflows/Fidelity-Levels.md`, `ai-workflows/discipline-interfaces.md`
**Joined:** 2026-05-24

## Learnings

### 2026-05-24 to 2026-06-XX — BrandtMission implementation and validation (43/43 passing)

#### What BrandtMission Does
- Implements the Brandt Miss tab: 14-segment F-16A mission analysis producing fuel burn, time, distance per segment.
- Key validation targets (all passing ±1%): Miss!O9 = 6000.43 lb total fuel, Miss!O8 = 94.06 min total time, Miss!O6 = 2884.95 ft landing distance.
- Constructor: `BrandtMission(aero, eng, geom)` — takes three handle objects in that order. Engine is `BrandtEngine()` (no args; hardcoded JSON path internally).

#### Mission Segment Architecture
- 13 active segments + 1 Landing (hardcoded).
- Segment types by how they compute fuel:
  1. **Takeoff**: Full-power (AB) with CDx penalty; fuel = TSFC_AB × T_AB × t_takeoff.
  2. **Ps-based Climb**: Segment is classified as climb if `isnan(given_time) && isnan(given_dist)`. Uses specific excess power integral. TSFC is AVERAGED between start and end conditions (only for this segment type).
  3. **Altitude-change / Generic cruise-type**: Breguet range or endurance equation. Uses END-conditions TSFC only (not averaged), even for altitude-changing legs like Egress.
  4. **Combat**: Fixed time with weapons drop; fuel = TSFC × T × t + W_drop.
  5. **Loiter**: Endurance equation.
  6. **Patrol/Patrol2/Patrol3**: Zero-fuel segments (no time, no distance specified — pass-through).
- Segment fuel consumption formula (generic): `dW_Wto = (TSFC/60) × (CDo/WS + k1×WS×(W_frac/q)² + k2×W_frac/q) × dist_or_time`.
- The code averages CDo/k1/k2 between the PREVIOUS segment's end conditions and the CURRENT segment's end conditions (matches Excel's pattern of averaging L and M column aero).

#### TSFC Averaging Rule (Critical)
- Excel ONLY averages TSFC between start and end for Ps-based "Climb" segments (columns D and L in Miss tab).
- ALL OTHER segments (including altitude-changing legs like Egress at column I) use END-conditions TSFC only.
- Code fix: `is_ps_climb = isnan(given_time) && isnan(given_dist)` flag controls TSFC averaging.

#### Fuel Formula Structure (from Miss tab images A51:P104)
- Row 13 (dW_Wto): For cruise-type, `(TSFC/60) × (CDo_avg/WS + k1_avg×WS×(W_start/q_avg)² + k2_avg×W_start/q_avg) × dist`
  - Uses W_frac at START of segment (NOT midpoint), matches Excel confirmed for Cruise2 (M13 uses L12).
  - Averages CDo/k1/k2 between previous column end and current column end.
- Row 12 (W_frac at end): `previous_W_frac − dW_Wto`
- Row 8 (time, min): derived from distance ÷ velocity for cruise; for climb, from Ps integral.
- Row 6 (landing distance): Brandt empirical formula using CLmax_landing, W/S, σ at sea level.

#### Segment Input Data (f16a_geometry.json, mission object)
- `altitude_ft: [0, 10000, 40000, 40000, 40000, 40000, 40000, 25000, 40000, 40000, 40000, 40000, 10000, 0]`
- `CDx: [0.035, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0, 0, 0, 0, 0, 0]` (segments 1-8 have CDx, 9-14 = 0)
- Mach fixed at 0.87 for all segments except Loiter (M=0.3) and Landing (M=0).
- Combat segment: AB=50%, 4400 lb weapons drop, 2 min fixed.

#### Inter-class Dependencies
- `BrandtMission` calls `aero.aero_at_mach(mach)` → returns `[CDo, k1_m, k2_m, CDmin]` for drag polar.
- `BrandtMission` calls `eng.thrust_at(alt, mach, pct_AB)` and `eng.tsfc_at(alt, mach, pct_AB)`.
- `BrandtMission` calls `geom.CLmax_landing` for landing distance.
- `aero.CDmin_sub` (= Cfe_tab × S_wet_total_accurate / S_ref) drives ALL subsonic CDo values at M=0.87.

#### Test Runner
- `run('src/level_brandt/tests/test_BrandtMission.m')` from repo root after `addpath('src/level_brandt')`.
- ~~Do NOT use `runtests()` — these are plain scripts, not `matlab.unittest` based.~~
- **test_BrandtMission is now a `matlab.unittest.TestCase` class** — use `runtests('src/level_brandt/tests/test_BrandtMission.m')`.
- 43 checks total: 3 primary targets + 1 final W_frac + 13 fuel + 13 time + 13 weight fraction.

### 2026-05-26 — BrandtMission compute() interface change and test migration

- `BrandtMission.compute()` now takes `W_TO_lb` as a required parameter (supports sizing loop pattern).
  - Old: `miss.compute()` read `W_TO` from `obj.inp.W_TO_lb` internally.
  - New: `miss.compute(31377.0)` — W_TO_lb passed explicitly each call.
  - Private methods updated: `segment_takeoff_`, `segment_generic_`, `segment_combat_` all take `W_TO_lb` as explicit parameter.
  - `obj.inp.W_TO_lb` retained in JSON struct for reference but no longer read in `compute()`.
- `test_BrandtMission.m` converted from plain script to `matlab.unittest.TestCase` class.
  - Fixture pattern: `TestClassSetup` runs once, builds full dependency chain, stores `miss` handle.
  - 3 segments (Climb, Egress, Cruise2) use 2% tolerance due to known S_wet discrepancy.
  - Zero-fuel segments use `AbsTol = 5.0` lb; zero-time segments use `AbsTol = 0.01` min.
- `readme_mission.md` created at `src/level_brandt/readme_mission.md`.
  - Documents all formulas, TSFC models, thrust lapse, known discrepancies, validation table.

### 2026-05-27 — analyze()/run() interface refactor across Level-Brandt

- Standardized the Brandt discipline API to a three-tier pattern: constructor loads JSON and initializes NaNs, `analyze()` performs design-point setup, and `run(...)` evaluates state/control-dependent outputs.
- Refactored `BrandtGeometry`, `BrandtAerodynamics`, `BrandtEngine`, `BrandtWeight`, and `BrandtMission` to use `analyze()` instead of `compute()`. Geometry remains analyze-only at this fidelity; aero, engine, weight, and mission now expose `run()` interfaces aligned with Level-Brandt scalar state/control mappings.
- Added dual-return `run()` behavior for aerodynamics and propulsion: each call both returns a struct and stores the same values on `run_*` properties, followed by lightweight `validate_run_()` NaN/validity guards.
- Converted `test_BrandtEngine.m` from a script to a `matlab.unittest.TestCase` class and added new `run()` coverage for `BrandtAerodynamics` and `BrandtEngine`.
- Updated `readme_geom.md` and `readme_mission.md` to document the new interface pattern, including mission `run(W_TO_lb)` usage and the shared analyze/run contract.
