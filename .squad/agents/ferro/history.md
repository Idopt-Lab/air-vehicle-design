# Ferro — History

Geometry Specialist — owns S_ref, S_wet, planform, fuselage, tail geometry. Brandt Amax uses whole-aircraft cross-sections H26:H45. Frame-20 width=2.0 ft (not 7.0 ft).

## Project Context

**Project:** AOE 4065 Air Vehicle Design (Idopt-Lab/air-vehicle-design)
**User:** Darshan Sarojini
**Language:** MATLAB (all source code)
**Ground truth:** `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`
**Key docs:** `ai-workflows/claude/CLAUDE.md`, `ai-workflows/Fidelity-Levels.md`, `ai-workflows/discipline-interfaces.md`
**Joined:** 2026-05-24

## Learnings

### 2026-05-24 — BrandtGeometry OOP refactor
- Refactored BrandtGeometry.m from static-only class to instance-based OOP.
- Constructor: BrandtGeometry(source) where source = filepath or struct.
- Instance properties: obj.inp (raw inputs) and obj.geom (computed results).
- compute() is an instance method — populates obj.geom from obj.inp.
- All display/plot methods are instance methods — read from obj.inp and obj.geom.
- Static methods retained only for pure stateless computation helpers.
- New API: geom = BrandtGeometry(); geom.compute(); geom.compareFidelities();

### 2026-05-24 — BrandtGeometry handle class + typed schema
- Switched classdef from value class to handle class (< handle)
- Pre-declared full obj.geom schema in initGeomSchema() static private method
- 6 compute helpers converted from static to private instance methods
- Added computed_ private flag + requireComputed() guard
- Fixed aileron.dihedral_deg missing from JSON
- displayLiftingSurfaces() works pre-compute; frame/geom/fidelity methods require compute
