# Subplan 05 — Weights

**Status:** Placeholder — not started
**Depends on:** Steps 0–2 (baseline, AircraftState, Geometry)
**Blocks:** Steps 7, 8 (mission analysis, sizing)

---

## Objectives

Implement `WeightsBase` and three generic fidelity levels using Raymer and Roskam textbook equations. Then implement F-16-specific subclasses that wire in F-16 specification parameters (aircraft type, design load factor, max Mach) so the general regressions and component equations are evaluated at the correct inputs. Single abstract method: `OEW(W_TO)`.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/WeightsBase.m` | Abstract base: `OEW(W_TO)→scalar(lbf)` |
| `src/disciplines/weights/WeightsLevel1.m` | Raymer Table 6.1 power-law regression; requires aircraft_type |
| `src/disciplines/weights/WeightsLevel2.m` | Raymer eq 6.1 multi-parameter regression; requires type + design params |
| `src/disciplines/weights/WeightsLevel3.m` | Component buildup (wing, fuselage, tail, LG, engine, systems) |

### Layer 2 — F-16 specific (`examples/F16A/`)

| File | What it provides |
|------|-----------------|
| `examples/F16A/disciplines/weights/F16WeightsLevel1.m` | Wires in `aircraft_type='jet fighter'` → Raymer Table 6.1 A=2.34, C=−0.13 |
| `examples/F16A/disciplines/weights/F16WeightsLevel2.m` | Wires in AR=3.0, M_max=2.05, N_z=9.0 from F-16 MIL-SPEC; T/W and W/S from constraint analysis (passed at construction) |
| `examples/F16A/disciplines/weights/F16WeightsLevel3.m` | Wires in N_z=9.0 and F16GeometryLevel3 object; equations unchanged |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestWeightsLevels.m` | Generic: physical constraints, monotonicity |
| `tests/examples/F16A/TestF16WeightsLevels.m` | F-16: OEW in physically plausible range for a ~31,000 lb fighter |

---

## Design Notes

- Inheritance: `F16WeightsLevelN < WeightsLevelN < WeightsBase < handle`.
- Physical constraints enforced with MATLAB errors: OEW must be positive and strictly less than W_TO.
- `WeightsLevel2` generic constructor: `WeightsLevel2(aircraft_type, TW, WS, AR, M_max, Kvs)` — all required so it works for any aircraft. F-16 subclass wires in the F-16-specific values; T/W and W/S are passed from constraint analysis at construction time.
- `WeightsLevel3` requires a geometry object at construction.
- Do NOT hardcode Brandt's OEW=19,980 lb as a calibration target input. The Raymer regressions will give an estimate; it may differ from Brandt by 5–15%.

**What generic vs. F-16 subclass provides:**

| | WeightsLevel1 (generic) | F16WeightsLevel1 (F-16 spec) |
|-|-------------------------|------------------------------|
| aircraft_type | arg to constructor | hardcodes `'jet fighter'` |
| regression coefficients | Raymer Table 6.1 lookup | same lookup, same coefficients |

| | WeightsLevel2 (generic) | F16WeightsLevel2 (F-16 spec) |
|-|-------------------------|------------------------------|
| AR, M_max, N_z | args to constructor | hardcodes 3.0, 2.05, 9.0 |
| T/W, W/S | args to constructor | passed from F16ConstraintSet output |

| | WeightsLevel3 (generic) | F16WeightsLevel3 (F-16 spec) |
|-|-------------------------|------------------------------|
| N_z | arg to constructor | hardcodes 9.0 (MIL-SPEC) |
| geometry | geometry object arg | uses F16GeometryLevel3 |

---

## Equations & References

### WeightsLevel1 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| OEW/W_TO | A × W_TO^C; jet fighter: A=2.34, C=−0.13 | Raymer 6th ed, Table 6.1 |
| OEW | (OEW/W_TO) × W_TO | definition |

### WeightsLevel2 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| OEW | W_TO × (a + b × W_TO^c1 × AR^c2 × (T/W)^c3 × (W/S)^c4 × M_max^c5) × K_vs | Raymer 6th ed, eq 6.1 |
| Coefficients (jet fighter) | a=−0.02, b=2.16, c1=−0.10, c2=0.20, c3=0.04, c4=−0.10, c5=0.08 | Raymer 6th ed, Table 6.1 |

### WeightsLevel3 (generic component buildup)
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

### Generic (`tests/disciplines/TestWeightsLevels.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| OEW > 0 | positive | exact |
| OEW < W_TO | enforced with error | exact |
| OEW increases monotonically with W_TO | monotonic | exact |
| Each L3 component positive | all > 0 | exact |
| L3 component sum = OEW | ±1e-6 lbf | analytical |

### F-16 specific (`tests/examples/F16A/TestF16WeightsLevels.m`)
| Test | Level | Expected | Tolerance |
|------|-------|----------|-----------|
| OEW at W_TO=31,377 lb | F16L1 | 17,000–23,000 lb (±15% of Brandt) | regression bounds |
| OEW at W_TO=31,377 lb | F16L2 | 18,000–22,000 lb (±10% of Brandt) | better bounds |
| OEW/W_TO ratio | F16L1 | 0.54–0.72 (plausible fighter range) | Raymer table range |

Note: We compare against Brandt's OEW=19,980 lb as a sanity check on the right order of magnitude, not as an exact target. The textbook regressions are expected to differ from Brandt's calibrated values.

---

## Verification

```matlab
runtests('tests/disciplines/TestWeightsLevels.m')
runtests('tests/examples/F16A/TestF16WeightsLevels.m')
```
All tests must pass before Step 6 begins.
