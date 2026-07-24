# Subplan 04 — Propulsion

**Status:** Implemented (L1 + L2 only; **no L3**)
**Depends on:** Steps 1–2 (AircraftState, Geometry)
**Blocks:** Steps 6, 7, 8 (constraint analysis, mission, sizing)

---

## Objectives

Implement `PropulsionBase` and two generic fidelity levels (L1, L2 — propulsion has **no L3**) using textbook equations (Raymer, Mattingly). Then implement F-16-specific subclasses that wire in the F100-PW-200 engine type identifier so the general Mattingly correlations are evaluated for the correct engine class. The `thrust_lapse(state)` / `TSFC(state)` methods plus the sea-level thrust property are the only things the sizing loop and mission analysis use.

---

## Files to Create

Three-tier pattern per level `N`: `PropulsionBase` (abstract) ← `PropulsionModelLN` (abstract enforcer) ← `F16PropLN` (concrete), plus a standalone static toolbox `PropLN` holding the equations.

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/PropulsionBase.m` | Abstract base: `thrust_lapse(state)`, `get_TSFC(state)`, sea-level thrust contract |
| `src/disciplines/propulsion/PropulsionModelL1.m` | Abstract L1 enforcer (declares `engine_type`, L1 abstract methods) |
| `src/disciplines/propulsion/PropulsionModelL2.m` | Abstract L2 enforcer |
| `src/disciplines/propulsion/PropL1.m` | Static toolbox — tabulated TSFC (Raymer type table), density-ratio thrust lapse |
| `src/disciplines/propulsion/PropL2.m` | Static toolbox — Mattingly TSFC correlations, Mattingly thrust lapse |

### Layer 2 — F-16 specific (`examples/F16A/`, flat directory)

| File | What it provides |
|------|-----------------|
| `examples/F16A/F16PropL1.m` | Wires in `engine_type='low_bypass_turbofan_AB'` + sea-level thrust for the Raymer TSFC table; delegates to `PropL1` statics |
| `examples/F16A/F16PropL2.m` | Wires in low-BPR turbofan class for the Mattingly correlations; delegates to `PropL2` statics |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestPropL1.m` | L1: formula correctness, physical bounds, F-16 values |
| `tests/disciplines/TestPropL2.m` | L2: Mattingly correlation correctness, physical bounds, F-16 values |

---

## Design Notes

- Inheritance: `F16PropLN < PropulsionModelLN < PropulsionBase < handle` (each `PropulsionModelLN` enforcer inherits `PropulsionBase` directly, not the lower level).
- Sea-level thrust is a plain settable property on the concrete class (the F-16 default is `T_SL = 23,770 lbf`, wired in by the no-arg constructor). It is a genuine design variable the sizing loop can overwrite in place — do not defensively guard it.
- The concrete `F16PropLN` classes set their spec/engine-type defaults in a no-arg constructor (older per-discipline input style — they do **not** read `f16a_L*.json`) and satisfy every abstract method with a one-line delegation to the `PropLN` static toolbox. No equations are overridden.
- L1 does not distinguish mil power from afterburner; L2 uses the Mattingly dry/wet correlations.
- Do NOT hardcode specific F100 TSFC numbers from Brandt or flight test data. Use the Mattingly correlation evaluated at the F100's BPR.

**What generic toolbox vs. F-16 subclass provides:**

| | PropL1 (generic toolbox) | F16PropL1 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_type` key → Raymer table | wires in `'low_bypass_turbofan_AB'` |
| thrust_lapse | density-ratio formula | same formula — no override |

| | PropL2 (generic toolbox) | F16PropL2 (F-16 spec) |
|-|---------------------------|--------------------------------|
| TSFC | `engine_class` → Mattingly formula | wires in low-BPR mixed turbofan class |
| thrust_lapse | Mattingly dry/wet formula | same formula |

---

## Equations & References

### PropL1 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (cruise) | type table; low-BPR mixed turbofan: 0.8/hr → /3600 → 1/s | Raymer 6th ed, Ch 3 (historical TSFC table) |
| TSFC (loiter) | type table; low-BPR: 0.7/hr → /3600 | Raymer 6th ed |
| α (thrust lapse) | (ρ / ρ_SL)^0.6 | Raymer 6th ed, Ch 3 |

### PropL2 (generic toolbox)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| TSFC (mil, low-BPR) | (0.9 + 0.30 × M) × sqrt(θ) [1/hr → /3600] | Mattingly, Aircraft Engine Design, Ch 2 |
| TSFC (AB, low-BPR) | (1.6 + 0.27 × M) × sqrt(θ) [1/hr → /3600] | Mattingly, Aircraft Engine Design, Ch 2 |
| θ | T_ambient / T_SL_std | standard atmosphere ratio |
| α (thrust lapse) | Mattingly installed thrust correlation | Mattingly, Aircraft Engine Design, Ch 2 |

---

## Tests

### L1 (`tests/disciplines/TestPropL1.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| TSFC > 0 at any valid condition | positive | exact |
| thrust_lapse = 1.0 at sea level, M=0 | 1.0 | ±0.1% |
| thrust_lapse ∈ (0, 1] at altitude | bounded | exact |
| Sea-level thrust property settable and readable | round-trips | exact |
| TSFC at sea level M=0 (cruise table) | F16 L1: 0.8/hr ± 5% | table value |

### L2 (`tests/disciplines/TestPropL2.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| TSFC increases with Mach (Mattingly) | monotonic in M at fixed alt | qualitative |
| thrust_lapse at 36k ft, M=0.87 | F16 L2: 0.25–0.45 (plausible AB lapse range) | physics bounds |

Note: We do not test against Brandt's specific lapse value of ~0.34 as an exact target. The Mattingly correlation gives the expected range for a low-BPR turbofan; exact agreement with Brandt is not required.

---

## Verification

```matlab
runtests('tests/disciplines/TestPropL1.m')
runtests('tests/disciplines/TestPropL2.m')
```
All tests must pass before Step 5 begins.
