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

### 2026-05-27 — Discipline Interface Standardization (analyze()/run())
- Standardized three-tier interface replaces ad-hoc `compute()` pattern
- `compute()` is now FORBIDDEN (OpenMDAO collision)
- New naming: `analyze()` = design-variable pass (outer loop), `run()` = state/control pass (inner loop)
- Dual-return contract: `run()` returns AND stores results (supports both optimizer and debugger patterns)
- All Level-Brandt discipline classes follow: Constructor → analyze(design_vars) → run(state, control, options)
- Specs updated: FR-015, SC-006, acceptance scenarios for Aerodynamics, Propulsion, Geometry, Weights
- Charters updated: Bishop, Dietrich, Dallas all now enforce this pattern
- Decision record written: bishop-analyze-run-interface.md

