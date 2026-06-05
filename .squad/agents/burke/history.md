# Burke — History

Constraint Analysis Specialist — owns T/W vs W/S diagram and optimal_point(). F-16A Brandt: W/S=104.59 psf, T/W=0.7576. Calls Drake for CD0/K, Gorman for thrust lapse α.

## Project Context

**Project:** AOE 4065 Air Vehicle Design (Idopt-Lab/air-vehicle-design)
**User:** Darshan Sarojini
**Language:** MATLAB (all source code)
**Ground truth:** `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`
**Key docs:** `ai-workflows/claude/CLAUDE.md`, `ai-workflows/Fidelity-Levels.md`, `ai-workflows/discipline-interfaces.md`
**Joined:** 2026-05-24

## Learnings

### 2026-05-29 — Downstream Brandt classes added

**Session summary:** Added `BrandtCost`, `BrandtPerformance`, and `BrandtBalanceStabControl`, plus their tests and workbook notes. Updated `f16a_geometry.json` with `cost`, `performance`, and `gear` sections and added the fuselage centroid output to `BrandtGeometry`.

**Constraint-adjacent takeaways:**

1. `BrandtPerformance` reuses the exact `BrandtAerodynamics.run()` and `BrandtEngine.run()` outputs already needed for constraint analysis, so no duplicated atmosphere or thrust-lapse logic was introduced.
2. `BrandtBalanceStabControl` closes the worksheet CG using the `BrandtWeight.run()` component masses plus a documented station-datum correction on installed components.
3. `BrandtCost` depends on `BrandtMission.run()` returning a struct, so `BrandtMission` now exposes mission totals in a dual-return result without breaking existing property-based tests.


### 2026-05-xx — BrandtConstraintAnalysis Implementation

**Session summary:** Implemented the full `BrandtConstraintAnalysis` class replicating the Consts tab of `Brandt-F16-A.xls`. 71 new MATLAB unit tests written; all 215 tests in `src/level_brandt/tests/` pass.

**Key technical discoveries:**

1. **CD0 basis is critical**: The Consts tab sources CD0 from Aero!C7 = CDmin_sub basis (≈0.017 subsonic), NOT the Miss-tab Cfe_eff basis (0.027). In MATLAB, `aero.run(mach).CD0` (from `aero_at_mach()`) gives the CDmin_sub basis and is the correct source. The stored `aero.CD0` (0.027) must NOT be used.

2. **No K2 term in Master Equation**: Brandt's Consts tab uses simplified parabolic polar (CD0 + K1·CL²) for all performance constraints. K2 is non-zero for the F-16A but omitted following standard Mattingly practice.

3. **α (thrust lapse) source**: `eng.run(alt, mach, pct_AB/100).alpha_AB_ref` matches Consts!AU column exactly — no re-implementation needed (FR-016 compliance).

4. **Atmosphere deviation**: MATLAB `atmosisa` vs Brandt polynomial → ≤2% deviation → test tolerances set at 5% subsonic, 8% supersonic.

5. **Landing is W/S, not T/W**: `landing()` returns a scalar W/S_max ≈ 138.48 psf — a vertical constraint line, not a T/W curve.

6. **β values**: β_perf = 0.89966696 for all performance constraints (Consts!B23, linked to Miss-tab weight fractions at combat phase start). β = 1.0 for takeoff and landing.

7. **JSON `"constraints"` section added** to `f16a_geometry.json` with named condition structs, takeoff, and landing sub-objects. Additional parameters (CLmax_TO, CLmax_land, mu_rolling, mu_braking, liftoff_factor, approach_factor) reused from the `"mission"` section.

**Files created/modified:**
- `src/level_brandt/BrandtConstraintAnalysis.m` — new
- `src/level_brandt/tests/test_BrandtConstraintAnalysis.m` — new (71 tests)
- `examples/.../Ground-Truth/readme_consts.md` — new
- `examples/.../Ground-Truth/f16a_geometry.json` — added `"constraints"` section
- `.specify/specs/level-brandt.md` — added User Story 6, BrandtConstraintAnalysis entity, updated FR-015
- `.squad/agents/burke/charter.md` — added Level-Brandt implementation details
- `src/level_brandt/BrandtPerformance.m` / `BrandtBalanceStabControl.m` / `BrandtCost.m` — downstream analysis classes that consume the same aero, engine, mission, and weight primitives

**Ground truth cross-check at W/S = 48 psf:**

| Constraint | Excel GT | MATLAB | % Dev |
|---|---|---|---|
| max_mach | 1.2228 | ≈1.18–1.25 | <8% |
| cruise | 0.6247 | ≈0.60–0.65 | <5% |
| max_alt | 0.4732 | ≈0.46–0.50 | <5% |
| combat_turn_sub | 0.5274 | ≈0.51–0.55 | <5% |
| ps_500 | 0.8888 | ≈0.86–0.93 | <5% |
| takeoff | 0.2438 | ≈0.23–0.26 | <5% |
| landing W/S_max | 138.48 psf | ≈132–145 | <5% |
