# Ferro — History

## Learnings

### 2026-05-24 to 2026-06-XX — S_wet total bug fix (K21 strake chine term)

#### Root Bug: Missing K21 Term in S_wet_total_accurate
- `Geom!B19 = D23 + B4 + B14 + B15 + B16 + B17 + K21`
- `K21 = Geom!K12 × 2 = Main!D18 × 2 = strake.S_ft2 × 2 = 20 × 2 = 40 ft²`
- `K21` represents the strake/chine planform wetted area (both sides), separate from the exposed-strake Raymer formula B15.
- The code was missing K21, giving S_wet = 1332.69 ft² instead of 1371.09 ft².
- Fix: `S_wet_total_accurate_ft2 += obj.inp.strake.S_ft2 * 2` in `computeSwetAccurate()`.
- Impact: CDmin_sub increased from 0.01644 to 0.01693 (+2.9%), fixing Climb/Egress/Cruise2 fuel errors.

#### S_wet Component Breakdown (Geom B19 = 1371.09 ft²)
| Component | Excel Cell | Value | Formula |
|-----------|-----------|-------|---------|
| Fuselage (accurate) | D23 | 676.33 ft² | SUM(D20:D22) per-frame integration |
| Nacelle (2×, GT) | B4 | 41.52 ft² | hardcoded ground truth |
| Exposed wing | B14 | 392.02 ft² | H7 × (1.977 + 0.52×tc) |
| Exposed strake | B15 | 39.96 ft² | H9 × (1.977 + 0.52×tc) |
| Pitch ctrl (horiz stab) | B16 | 99.58 ft² | H8 × (1.977 + 0.52×tc) |
| Vert tail | B17 | 81.69 ft² | H10 × (1.977 + 0.52×tc) |
| Strake chine (K21) | K21 | 40.00 ft² | Main!D18 × 2 |

#### S_wet Raymer Formula
- Applied to all exposed lifting surfaces: `S_wet = S_exposed × (1.977 + 0.52 × t/c)`
- t/c is the section thickness ratio (e.g., 0.04 for NACA 0004).
- Nacelle uses ground-truth value (41.515 ft²) instead of computed value.

#### Fuselage S_wet (Accurate Path = D23)
- Per-frame trapezoidal integration: sum of (perimeter_avg × dx) over 20 frames.
- Computed in `computeFuselage_()` using the frame cross-section geometry from Geom tab C:H rows 25-449.
- Frame-20 width uses F26 = 2.0 ft (NOT Main row 53 = 7.0 ft) — this was a previous fix.

#### Amax Computation
- `Geom!H47 = MAX(H26:H45)` — max cross-sectional area over 20 frames.
- H26:H45 are WHOLE-AIRCRAFT cross-sections (fuselage + wing + strake + vert tail + pitch ctrl at each station).
- NOT fuselage-only frame areas. This was an earlier fix confirmed in session history.

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
