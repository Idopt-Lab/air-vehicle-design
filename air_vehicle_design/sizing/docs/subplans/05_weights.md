# Subplan 05 — Weights

**Status:** Implemented (L1, L2, L3)
**Depends on:** Steps 1–2 (AircraftState, Geometry)
**Blocks:** Steps 7, 8 (mission analysis, sizing)

---

## Objectives

Implement `WeightsBase` and three generic fidelity levels using Raymer and Roskam textbook equations. Then implement F-16-specific subclasses that wire in F-16 specification parameters (aircraft type, design load factor, max Mach) so the general regressions and component equations are evaluated at the correct inputs. Single abstract method: `OEW(W_TO)`.

---

## Files to Create

Three-tier pattern per level `N`: `WeightsBase` (abstract) ← `WeightsModelLN` (abstract enforcer) ← `F16WeightsLN` (concrete), plus a standalone static toolbox `WeightsLN` holding the equations.

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/WeightsBase.m` | Abstract base: `OEW(W_TO)→scalar(lbf)` contract |
| `src/disciplines/weights/WeightsModelL1.m` | Abstract L1 enforcer |
| `src/disciplines/weights/WeightsModelL2.m` | Abstract L2 enforcer |
| `src/disciplines/weights/WeightsModelL3.m` | Abstract L3 enforcer |
| `src/disciplines/weights/WeightsL1.m` | Static toolbox — Raymer Table 6.1 power-law regression |
| `src/disciplines/weights/WeightsL2.m` | Static toolbox — Raymer eq 6.1 multi-parameter regression |
| `src/disciplines/weights/WeightsL3.m` | Static toolbox — component buildup (wing, fuselage, tail, LG, engine, systems) |

### Layer 2 — F-16 specific (`examples/F16A/`, flat directory)

| File | What it provides |
|------|-----------------|
| `examples/F16A/F16WeightsL1.m` | Wires in `aircraft_type='jet fighter'` → Raymer Table 6.1 A=2.34, C=−0.13; delegates to `WeightsL1` statics |
| `examples/F16A/F16WeightsL2.m` | Wires in AR=3.0, M_max, N_z=9.0 from F-16 MIL-SPEC (+ T/W, W/S); delegates to `WeightsL2` statics |
| `examples/F16A/F16WeightsL3.m` | Wires in N_z=9.0 and the F-16 exposed-area / component geometry inputs as its own properties; delegates to `WeightsL3` statics |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestWeightsL1.m` | L1: physical constraints, monotonicity, F-16 OEW range |
| `tests/disciplines/TestWeightsL2.m` | L2: regression correctness, F-16 OEW range |
| `tests/disciplines/TestWeightsL3.m` | L3: component buildup positivity + sum, F-16 OEW range |

---

## Design Notes

- Inheritance: `F16WeightsLN < WeightsModelLN < WeightsBase < handle` (each `WeightsModelLN` enforcer inherits `WeightsBase` directly).
- Physical constraints enforced with MATLAB errors: OEW must be positive and strictly less than W_TO.
- The concrete `F16WeightsLN` classes set their F-16 spec values in a no-arg constructor (older per-discipline input style — they do **not** read `f16a_L*.json`) and satisfy every abstract method with a one-line delegation to the `WeightsLN` static toolbox. The generic equations live in the toolboxes.
- `F16WeightsL3` currently carries the required exposed-area / component-geometry inputs (S_w, S_ht, S_vt, fuselage envelope, …) as its own frozen properties and takes no geometry object. **This is a known defect scheduled for Phase 4, not the target design.** `GeomL3` now exists and is the full L3 geometry tier (reinstated 2026-07-24, promoted 2026-07-25 — the earlier "geometry has no L3" claim is obsolete), and `F16WeightsL3` is to dependency-inject it, replacing ~22 hardcoded geometry constants that go stale the moment an optimizer moves the planform. Note three DI name-traps when that lands: L3 exposed tail geometry is `AR_exposed_ht`/`lambda_exposed_ht` (plain `AR_ht` means FULL planform at both tiers); the weights `D_fus` is geometry's `H_max_fuselage` (5.0), NOT geometry's equivalent diameter `D_fus` (6.0); and `S_exposed_ht` is now 51.1486, not 49.85, because L3 takes the T.O. 18.5 ft span as primary.
- Do NOT hardcode Brandt's OEW=19,980 lb as a calibration target input. The Raymer regressions will give an estimate; it may differ from Brandt by 5–15%.

**What generic toolbox vs. F-16 subclass provides:**

| | WeightsL1 (generic toolbox) | F16WeightsL1 (F-16 spec) |
|-|-------------------------|------------------------------|
| aircraft_type | table key | hardcodes `'jet fighter'` |
| regression coefficients | Raymer Table 6.1 lookup | same lookup, same coefficients |

| | WeightsL2 (generic toolbox) | F16WeightsL2 (F-16 spec) |
|-|-------------------------|------------------------------|
| AR, M_max, N_z | formula inputs | hardcodes F-16 spec values |
| T/W, W/S | formula inputs | from constraint analysis output |

| | WeightsL3 (generic toolbox) | F16WeightsL3 (F-16 spec) |
|-|-------------------------|------------------------------|
| N_z | formula input | hardcodes 9.0 (MIL-SPEC) |
| geometry inputs | formula inputs | F-16 exposed areas / envelope as own properties |

---

## Equations & References

### WeightsL1 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| OEW/W_TO | A × W_TO^C; jet fighter: A=2.34, C=−0.13 | Raymer 6th ed, Table 6.1 |
| OEW | (OEW/W_TO) × W_TO | definition |

### WeightsL2 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| OEW | W_TO × (a + b × W_TO^c1 × AR^c2 × (T/W)^c3 × (W/S)^c4 × M_max^c5) × K_vs | Raymer 6th ed, eq 6.1 |
| Coefficients (jet fighter) | a=−0.02, b=2.16, c1=−0.10, c2=0.20, c3=0.04, c4=−0.10, c5=0.08 | Raymer 6th ed, Table 6.1 |

### WeightsL3 (generic toolbox — component buildup)
| Component | Equation | Reference |
|-----------|----------|-----------|
| Wing | Raymer/Nicolai plate-area — exact eq TBD at implementation | Raymer 6th ed, eq 15.1 |
| Fuselage | 0.499 × K_dwf × W_dg^0.35 × N_z^0.25 × L^0.5 × D^0.849 × W^0.685 | Raymer 6th ed, eq 15.5 |
| HT | 3.316 × (1 + F_w/B_h)^−2 × (W_dg × N_z/1000)^0.260 × S_ht^0.806 | Raymer 6th ed, eq 15.2 |
| VT | 0.452 × K_rht × (1 + H_t/H_v)^0.5 × (W_dg × N_z)^0.488 × S_vt^0.718 × ... | Raymer 6th ed, eq 15.3 |
| Landing gear | 0.034 × W_TO (Roskam fraction, pending L3 detail) | Roskam Airplane Design Part I |
| Engine installed | W_dry + W_oil + W_starter — series | Raymer 6th ed, eqs 7.13–7.17 |

---

## Tests

### L1 (`tests/disciplines/TestWeightsL1.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| OEW > 0 | positive | exact |
| OEW < W_TO | enforced with error | exact |
| OEW increases monotonically with W_TO | monotonic | exact |
| F16 OEW at W_TO=31,377 lb | 17,000–23,000 lb (±15% of Brandt) | regression bounds |
| F16 OEW/W_TO ratio | 0.54–0.72 (plausible fighter range) | Raymer table range |

### L2 (`tests/disciplines/TestWeightsL2.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| F16 OEW at W_TO=31,377 lb | 18,000–22,000 lb (±10% of Brandt) | better bounds |

### L3 (`tests/disciplines/TestWeightsL3.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| Each L3 component positive | all > 0 | exact |
| L3 component sum = OEW | ±1e-6 lbf | analytical |

Note: We compare against Brandt's OEW=19,980 lb (from `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`; `baseline/F16Baseline.m` is deprecated) as a sanity check on the right order of magnitude, not as an exact target. The textbook regressions are expected to differ from Brandt's calibrated values.

---

## Verification

```matlab
runtests('tests/disciplines/TestWeightsL1.m')
runtests('tests/disciplines/TestWeightsL2.m')
runtests('tests/disciplines/TestWeightsL3.m')
```
All tests must pass before Step 6 begins.
