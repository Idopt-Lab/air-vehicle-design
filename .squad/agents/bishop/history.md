# History

## Learnings

### 2026-05-24 — OOP-first directive
- Darshan directed: all MATLAB classes must be instantiable. Static-only classes are banned.
- BrandtGeometry was the first violation — refactored to instance-based OOP.
- Pattern: constructor loads inputs, compute() stores results, display/plot methods read from obj.
- Updated bishop, ferro, dallas charters accordingly.
- ADR written: bishop-oop-first-no-static-bags.md

### 2026-05-26 — Test gate policy
- Test gate policy added to level-brandt.md spec and all relevant charters
- FR-014 added to spec: run all tests before finalizing any code
- SC-005 updated to require `matlab.unittest.TestCase` framework
- All three discipline agents (Bishop, Dietrich, Dallas) now have explicit test gate and unittest format rules
- Decision record written: bishop-test-gate-policy.md

### 2026-05-27 — BrandtWeight Full Implementation

- `BrandtWeight.m` fully implemented: three-tier pattern (constructor → analyze() → run(W_TO_lb))
- Constructor accepts a `BrandtGeometry` handle (same pattern as `BrandtAerodynamics`)
- `analyze()` computes all geometry-dependent structural weights: W_wing, W_fuse, W_pitch, W_vert, W_nacelles, W_strakes, W_structure, W_engine, W_inlet_duct
- `run(W_TO_lb)` computes W_TO-dependent weights (gear, ctrl, elec, hyd, ECS, other, avionics, armament), OEW, and W_fuel
- Key formula decoded: nacelle effective area (Geom!B4) — `n × D_nac × L_nac × π × E_aft / 2` (half-buried centerline engine)
- Controls weight uses two-term formula: `0.012 × W_TO + (S_LE_flap/S_wing) × 6.75 × 200`
- W_engine is NOT included in W_airframe — added separately for OEW (Wt B10 ≠ B12 − engine)
- 28 MATLAB unittest tests in `test_BrandtWeight.m`; all 144 tests in test suite pass
- `readme_wt.md` created in Ground-Truth folder; `cell-map.md` Wt section fully populated
- `level-brandt.md` spec User Story 5 updated with accurate acceptance scenarios
- Known deviation: π vs 3.1516 in nacelle area → ~0.37% error in W_nacelles (within 1% tolerance)
- JSON `weight` section added: perm_payload_lb=700, exp_payload_lb=4400, n_design_load=9, weight_scale_pct=100, n_vert_tails=1
- BrandtGeometry updated: `S_wet_nacelle_gt_ft2` now computed from formula (was hardcoded 41.515)

- Standardized three-tier interface replaces ad-hoc `compute()` pattern
- `compute()` is now FORBIDDEN (OpenMDAO collision)
- New naming: `analyze()` = design-variable pass (outer loop), `run()` = state/control pass (inner loop)
- Dual-return contract: `run()` returns AND stores results (supports both optimizer and debugger patterns)
- All Level-Brandt discipline classes follow: Constructor → analyze(design_vars) → run(state, control, options)
- Specs updated: FR-015, SC-006, acceptance scenarios for Aerodynamics, Propulsion, Geometry, Weights
- Charters updated: Bishop, Dietrich, Dallas all now enforce this pattern
- Decision record written: bishop-analyze-run-interface.md

