# Subplan 04 — Propulsion

**Status:** Placeholder — not started
**Depends on:** Steps 1–2 (AircraftState, Geometry)
**Blocks:** Steps 6, 7, 8 (constraint analysis, mission, sizing)

---

## Objectives

Implement `PropulsionBase` and three generic fidelity levels using textbook equations (Raymer, Mattingly). Then implement F-16-specific subclasses that wire in the F100-PW-200 engine type identifier so the general Mattingly correlations are evaluated for the correct engine class. Abstract methods `thrust_lapse(state)` and `TSFC(state)` plus the `T0` property are the only things the sizing loop and mission analysis use.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/PropulsionBase.m` | Abstract base: `thrust_lapse(state)`, `TSFC(state)`, abstract property `T0` |
| `src/disciplines/propulsion/PropulsionLevel1.m` | Tabulated TSFC (Raymer type table), density-ratio thrust lapse |
| `src/disciplines/propulsion/PropulsionLevel2.m` | Mattingly TSFC correlations, Mattingly thrust lapse |
| `src/disciplines/propulsion/PropulsionLevel3.m` | Separate mil/AB lapse rates with temperature ratio correction |

### Layer 2 — F-16 specific (`examples/F16A/`)

| File | What it provides |
|------|-----------------|
| `examples/F16A/disciplines/propulsion/F16PropulsionLevel1.m` | Wires in `engine_type='low_bypass_mixed_turbofan'` for the Raymer TSFC table |
| `examples/F16A/disciplines/propulsion/F16PropulsionLevel2.m` | Wires in low-BPR turbofan class for Mattingly correlations |
| `examples/F16A/disciplines/propulsion/F16PropulsionLevel3.m` | Wires in mil/AB power flag; T0 starts as free variable set by sizing loop |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestPropLevels.m` | Generic: formula correctness, physical bounds |
| `tests/examples/F16A/TestF16PropLevels.m` | F-16: outputs in physically reasonable range for a low-BPR mixed turbofan |

---

## Design Notes

- `T0` starts at 0 after construction. The sizing loop sets it before any `thrust_lapse` or `TSFC` call is used for sizing. This is by design — document it, do not defensively guard it.
- Inheritance: `F16PropulsionLevelN < PropulsionLevelN < PropulsionBase < handle`.
- F-16 subclasses call `super()` with engine-type inputs. No equations are overridden.
- L1 does not distinguish mil power from afterburner — L3 does.
- Do NOT hardcode specific F100 TSFC numbers from Brandt or flight test data. Use the Mattingly correlation evaluated at the F100's BPR.

**What generic vs. F-16 subclass provides:**

| | PropulsionLevel1 (generic) | F16PropulsionLevel1 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_type` arg → Raymer table | wires in `'low_bypass_mixed_turbofan'` |
| thrust_lapse | density-ratio formula | same formula — no override |

| | PropulsionLevel2 (generic) | F16PropulsionLevel2 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_class` arg → Mattingly formula | wires in low-BPR mixed turbofan class |
| thrust_lapse | Mattingly dry/wet formula | same formula |

| | PropulsionLevel3 (generic) | F16PropulsionLevel3 (F-16 spec) |
|-|---------------------------|--------------------------------|
| mil/AB distinction | `has_afterburner` flag arg | wires in `has_afterburner=true` |

---

## Equations & References

### PropulsionLevel1 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (cruise) | type table; low-BPR mixed turbofan: 0.8/hr → /3600 → 1/s | Raymer 6th ed, Ch 3 (historical TSFC table) |
| TSFC (loiter) | type table; low-BPR: 0.7/hr → /3600 | Raymer 6th ed |
| α (thrust lapse) | (ρ / ρ_SL)^0.6 | Raymer 6th ed, Ch 3 |

### PropulsionLevel2 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (mil, low-BPR) | (0.9 + 0.30 × M) × sqrt(θ) [1/hr → /3600] | Mattingly, Aircraft Engine Design, Ch 2 |
| TSFC (AB, low-BPR) | (1.6 + 0.27 × M) × sqrt(θ) [1/hr → /3600] | Mattingly, Aircraft Engine Design, Ch 2 |
| θ | T_ambient / T_SL_std | standard atmosphere ratio |
| α (thrust lapse) | Mattingly installed thrust correlation | Mattingly, Aircraft Engine Design, Ch 2 |

### PropulsionLevel3 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| T_dry at altitude | T_SL × f(δ_0, M, dry lapse params) | Raymer 6th ed, eqs 10.1–10.3 |
| T_wet (AB) at altitude | T_SL × g(δ_0, M, θ_0, wet lapse params) | Raymer 6th ed / Mattingly Ch 2 |

---

## Tests

### Generic (`tests/disciplines/TestPropLevels.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| TSFC > 0 at any valid condition | positive | exact |
| thrust_lapse = 1.0 at sea level, M=0 | 1.0 | ±0.1% |
| thrust_lapse ∈ (0, 1] at altitude | bounded | exact |
| T0 property settable and readable | round-trips | exact |
| TSFC increases with Mach (Mattingly) | monotonic in M at fixed alt | qualitative |

### F-16 specific (`tests/examples/F16A/TestF16PropLevels.m`)
| Test | Level | Expected | Tolerance |
|------|-------|----------|-----------|
| TSFC at sea level M=0 (cruise table) | F16L1 | 0.8/hr ± 5% | table value |
| thrust_lapse at 36k ft, M=0.87 | F16L2/L3 | 0.25–0.45 (plausible AB lapse range) | physics bounds |
| T_AB = alpha × T0 for given T0 | F16L3 | consistent with lapse formula | ±1% |

Note: We do not test against Brandt's specific lapse value of ~0.34 as an exact target. The Mattingly correlation gives the expected range for a low-BPR turbofan; exact agreement with Brandt is not required.

---

## Verification

```matlab
runtests('tests/disciplines/TestPropLevels.m')
runtests('tests/examples/F16A/TestF16PropLevels.m')
```
All tests must pass before Step 5 begins.
