# Subplan 02 — Geometry

**Status:** Placeholder — not started
**Depends on:** Step 1 (AircraftState), Step 0 (requirements.json / aircraft_spec.json)
**Blocks:** Steps 3, 4, 5 (all disciplines read geometry)

---

## Objectives

Implement `GeometryBase` and three generic fidelity levels. Then implement F-16-specific geometry subclasses that wire in F-16 **specification** parameters (AR, taper, sweep, fuselage dimensions) so the general regression and planform equations are evaluated at the correct F-16 inputs. Geometry is a **data carrier** — it provides dimensional data (S_ref, S_wet, b, cbar, L_fus, …) to aerodynamics, weights, and the sizing loop.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/GeometryBase.m` | Abstract base — declares S_ref, S_wet as abstract properties |
| `src/disciplines/geometry/GeometryLevel1.m` | Regression-based S_wet and L_fus (Roskam/Raymer); requires aircraft_type string |
| `src/disciplines/geometry/GeometryLevel2.m` | Adds explicit AR, λ, Λ_LE, tc; computes b, c_root, cbar |
| `src/disciplines/geometry/GeometryLevel3.m` | Adds component-level wetted areas (wing, fuselage, HT, VT) |

### Layer 2 — F-16 specific (`examples/F16A/`)

| File | What it provides |
|------|-----------------|
| `examples/F16A/disciplines/geometry/F16GeometryLevel1.m` | Hardcodes `aircraft_type = 'fighter'` for Roskam regression; inherits all equations |
| `examples/F16A/disciplines/geometry/F16GeometryLevel2.m` | Hardcodes AR=3.0, λ=0.2, Λ_LE=40° from F-16 public spec; equations unchanged |
| `examples/F16A/disciplines/geometry/F16GeometryLevel3.m` | Hardcodes F-16 component dimensions from public spec (fuselage diameter, exposed wing span, etc.) |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestGeomLevels.m` | Generic classes with representative parameters |
| `tests/examples/F16A/TestF16GeomLevels.m` | F-16 classes: outputs within physically reasonable range; b consistent with AR and S_ref |

---

## Design Notes

- `GeometryBase` has **no abstract methods** — only abstract properties (`S_ref`, `S_wet`). Consistent with `temp_AI/docs/00_framework_overview.md` Section 2.
- `S_ref` is set externally by the sizing loop (L1) or provided as a fixed input (L2+).
- All levels: `GeometryLevelN < GeometryBase < handle`. F-16: `F16GeometryLevelN < GeometryLevelN`.
- F-16 subclasses call `super()` with F-16-spec inputs. They do not override equations.
- `S_HT` and `S_VT` are properties set by `TailSizingLevel1` during the L2 sizing loop.

**Why two layers for geometry:**  
The generic `GeometryLevel2` constructor requires the user to supply AR, λ, Λ_LE, tc. For an F-16 design study, these are always the same values. `F16GeometryLevel2` is just a convenient constructor that pre-fills them from the F-16 spec, so the design study script stays clean.

---

## Equations & References

### GeometryLevel1 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| S_wet | 10^c × W_TO^d; fighter: c=−0.1289, d=0.7506 | Roskam Airplane Design Vol I, eq 3.22 |
| L_fus | a × W_TO^c; fighter: a=0.93, c=0.39 | Raymer 6th ed, Table 6.3 |
| b | sqrt(AR × S_ref) | definition |

### GeometryLevel2 (generic, additions)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| c_root | 2 × S_ref / (b × (1 + λ)) | planform geometry |
| cbar | (2/3) × c_root × (1 + λ + λ²) / (1 + λ) | mean aerodynamic chord definition |

### GeometryLevel3 (generic, additions)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| S_wet_wing | 2 × S_exp × (1 + 0.25 × tc_r × (1 + (tc_r/tc_t) × λ)/(1 + λ)) | Roskam Part II, eq 12.1 |
| S_wet_fus (cylinder) | π × D × L × (1 − 2/λ_f)^(2/3) × (1 + 1/λ_f²) | Roskam Part II, eq 12.3 |

### F16GeometryLevel1 — spec inputs used
| Parameter | Value | Source |
|-----------|-------|--------|
| aircraft_type | 'fighter' | selects Roskam regression row |

### F16GeometryLevel2 — spec inputs used
| Parameter | Value | Source |
|-----------|-------|--------|
| AR | 3.0 | F-16 public specification |
| λ (taper) | 0.2 | F-16 public specification |
| Λ_LE | 40° | F-16 public specification |
| tc_root | 0.04 (NACA 64A-204) | F-16 public specification |

---

## Tests

### Generic (`tests/disciplines/TestGeomLevels.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| S_wet > 0 for any valid W_TO | positive | exact |
| S_wet ≥ S_ref (physical) | S_wet/S_ref > 1 | exact |
| cbar consistent with planform formula | ±0.1% | analytical |
| L_fus increases monotonically with W_TO | monotonic | exact |
| b = sqrt(AR × S_ref) | ±0.01% | analytical |

### F-16 specific (`tests/examples/F16A/TestF16GeomLevels.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| F16GeomL1 S_wet at W_TO=31,377 lb | physically reasonable range (1,000–1,600 ft²) | regression bounds |
| F16GeomL2 b from AR=3.0, S_ref=300 | 30.0 ft | ±0.1% |
| F16GeomL2 cbar | consistent with AR=3, S_ref=300, λ=0.2 | ±0.5% |
| All outputs positive | > 0 | exact |

Note: We do not test against Brandt's S_wet=1,331.09 ft² as an exact target — the regression will give a range, not Brandt's calibrated value.

---

## Verification

```matlab
runtests('tests/disciplines/TestGeomLevels.m')
runtests('tests/examples/F16A/TestF16GeomLevels.m')
```
All tests must pass before Step 3 begins.
