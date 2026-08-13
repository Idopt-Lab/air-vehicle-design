# Subplan 02 — Geometry

**Status:** Implemented — **L1 + L2 + L3**. (The 2026-07-22 "no L3, former L3 merged into L2" decision was reversed on 2026-07-24 and the tier was promoted on 2026-07-25 to the full L3 geometry tier consumed by L3 geometry, aerodynamics and weights.)
**Depends on:** Step 1 (AircraftState), plus a propulsion object — geometry now takes one by injection
**Blocks:** Steps 3, 4, 5 (all disciplines read geometry)

---

## Objectives

Implement `GeometryBase` and three generic fidelity levels (L1, L2, L3). Then implement F-16-specific geometry subclasses that wire in F-16 **specification** parameters (AR, taper, sweep, fuselage dimensions) so the general regression and planform equations are evaluated at the correct F-16 inputs. Geometry is a **data carrier** — it provides dimensional data (S_ref, S_wet, b, cbar, L_fus, Amax, …) to aerodynamics, weights, and the sizing loop.

**L3 is the physical / T.O. tier**, not simply "L2 with more detail": where a physical or T.O. 1F-16A-1 value differs from Brandt's, `GeomL3` uses the physical one (VT LE sweep 47.5° vs 40°, `L_fus` 47.5 vs 46.5, HT span 18.5 ft taken as the primary span so `AR_ht` = 3.169 is derived). Those divergences are intentional and are annotated `BY DESIGN` in `geometry_brandt_comparison.md`.

Two structural points that post-date this subplan's original text — the authoritative write-up is `examples/F16A/models/disciplines/geom/F16GeomL3.md`:
- **Geometry receives an injected propulsion object** (`F16GeomL{2,3}(json_path, prop)`): the nacelle diameter, and hence duct wetted area and CD0, is sized from engine SLS thrust, which is engine data rather than airframe data.
- **`Amax` is tier-specific by design** — L2 uses the fuselage-envelope ellipse (the low-fidelity form per `readme_geom.md` §7), L3 the whole-aircraft area-ruled buildup that Raymer Eq. 12.44 requires. Do not unify them.

---

## Files to Create

Three-tier pattern per level `N`: `GeometryBase` (abstract) ← `GeometryModelLN` (abstract enforcer) ← `F16GeomLN` (concrete), plus a standalone static toolbox `GeomLN` holding the equations.

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/GeometryBase.m` | Abstract base — declares S_ref, S_wet as abstract; provides shared utility statics |
| `src/disciplines/geometry/GeometryModelL1.m` | Abstract L1 enforcer (declares the L1 abstract methods/properties) |
| `src/disciplines/geometry/GeometryModelL2.m` | Abstract L2 enforcer |
| `src/disciplines/geometry/GeomL1.m` | Static toolbox — regression-based S_wet and L_fus (Roskam/Raymer) |
| `src/disciplines/geometry/GeomL2.m` | Static toolbox — planform (b, c_root, cbar) + component-level wetted areas (wing, fuselage, HT, VT, duct); absorbs the former L3 |

### Layer 2 — F-16 specific (`examples/F16A/`, flat directory)

| File | What it provides |
|------|-----------------|
| `examples/F16A/models/disciplines/geom/F16GeomL1.m` | Wires in `aircraft_category = 'jet_fighter'` + S_ref for the Roskam/Raymer regressions; delegates to `GeomL1` statics |
| `examples/F16A/models/disciplines/geom/F16GeomL2.m` | Wires in AR=3.0, λ, Λ_LE=40°, t/c, fuselage/HT/VT envelope from F-16 spec; delegates to `GeomL2` statics. Reference implementation of the **input vs. derived (Dependent-getter)** optimization-ready pattern (see below) |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestGeomL1.m` | L1 correctness (regression outputs, physical bounds) |
| `tests/disciplines/TestGeomL2.m` | L2 correctness + F-16 planform values (b consistent with AR and S_ref, cbar, wetted areas) |

---

## Design Notes

- `GeometryBase` declares `S_ref`, `S_wet` as abstract and provides shared utility statics. Each level adds an abstract enforcer `GeometryModelLN`.
- `S_ref` is set externally by the sizing loop (L1) or provided as a fixed input (L2).
- Inheritance: `F16GeomLN < GeometryModelLN < GeometryBase < handle` (each enforcer inherits `GeometryBase` directly). Being handle classes lets the sizing/optimization loop mutate design variables in place.
- The concrete classes do **not** call `super()` with hardcoded spec values and do **not** freeze derived quantities. `F16GeomL2` splits its properties into **inputs** (plain mutable `properties` — the design-variable spec data set once from JSON) and **derived** (`properties (Dependent)` with `get.<name>` methods that recompute live from the inputs via the `GeomL2` statics, never cached). This makes it optimization-ready by construction: mutating an input (e.g. `obj.AR_wing`) is reflected on the next read of every dependent value. See the `F16GeomL2.m` header for the full rationale.
- HT/VT breakdown and the inlet/duct component (the former L3 content) now live in `F16GeomL2` / `GeomL2`.

**Why two layers for geometry:**  
The generic `GeomL2` toolbox holds the textbook planform/wetted-area equations, parameterized on AR, λ, Λ_LE, t/c, etc. `F16GeomL2` supplies the F-16 spec values for those inputs, so the design study script stays clean while the equations remain generic.

---

## Equations & References

### GeomL1 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| S_wet | 10^c × W_TO^d; fighter: c=−0.1289, d=0.7506 | Roskam Airplane Design Vol I, eq 3.22 |
| L_fus | a × W_TO^c; fighter: a=0.93, c=0.39 | Raymer 6th ed, Table 6.3 |
| b | sqrt(AR × S_ref) | definition |

### GeomL2 (generic toolbox — planform)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| c_root | 2 × S_ref / (b × (1 + λ)) | planform geometry |
| cbar | (2/3) × c_root × (1 + λ + λ²) / (1 + λ) | mean aerodynamic chord definition |

### GeomL2 (generic toolbox — component wetted areas, formerly L3)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| S_wet_wing | 2 × S_exp × (1 + 0.25 × tc_r × (1 + (tc_r/tc_t) × λ)/(1 + λ)) | Roskam Part II, eq 12.1 |
| S_wet_fus (cylinder) | π × D × L × (1 − 2/λ_f)^(2/3) × (1 + 1/λ_f²) | Roskam Part II, eq 12.3 |

### F16GeomL1 — spec inputs used
| Parameter | Value | Source |
|-----------|-------|--------|
| aircraft_category | 'jet_fighter' | selects Roskam/Raymer regression rows (`f16a_L1.json .geometry`) |

### F16GeomL2 — spec inputs used (`f16a_L2.json .geometry`)
| Parameter | Value | Source |
|-----------|-------|--------|
| AR | 3.0 | F-16 public specification |
| λ (taper) | 0.2 | F-16 public specification |
| Λ_LE | 40° | F-16 public specification |
| tc_root | 0.04 (NACA 64A-204) | F-16 public specification |

---

## Tests

### L1 (`tests/disciplines/TestGeomL1.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| S_wet > 0 for any valid W_TO | positive | exact |
| S_wet ≥ S_ref (physical) | S_wet/S_ref > 1 | exact |
| L_fus increases monotonically with W_TO | monotonic | exact |
| b = sqrt(AR × S_ref) | ±0.01% | analytical |

### L2 (`tests/disciplines/TestGeomL2.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| cbar consistent with planform formula | ±0.1% | analytical |
| F16GeomL2 b from AR=3.0, S_ref=300 | 30.0 ft | ±0.1% |
| F16GeomL2 cbar | consistent with AR=3, S_ref=300, λ=0.2 | ±0.5% |
| F16 S_wet (L1 regression) at W_TO=31,377 lb | physically reasonable range (1,000–1,600 ft²) | regression bounds |
| All outputs positive | > 0 | exact |

Note: We do not test against Brandt's S_wet=1,331.09 ft² as an exact target — the regression will give a range, not Brandt's calibrated value. Brandt agreement is reported separately by `examples/F16A/sanity_checks/geometry_brandt_comparison.m` against `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`, not by these unit tests.

---

## Verification

```matlab
runtests('tests/disciplines/TestGeomL1.m')
runtests('tests/disciplines/TestGeomL2.m')
```
All tests must pass before Step 3 begins.
