# Subplan 06 — Constraint Analysis

**Status:** Placeholder — not started
**Depends on:** Steps 1–5 (all disciplines needed to run constraints at all fidelities)
**Blocks:** Steps 7, 8 (mission, sizing)

---

## Objectives

Implement the generic constraint analysis framework. The F-16-specific constraint set (8 point performance conditions) is defined in `examples/F16A/constraints/F16ConstraintSet.m` using values extracted from the input Excel files. Key deliverables:
1. `optimal_point(aero, prop)` — returns (W/S, T/W) design point.
2. `plot_diagram()` — constraint diagram with feasible region shaded.
3. Same API produces valid diagrams with L1, L2, L3 discipline objects.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/constraints/PointPerformanceBase.m` | Abstract base for all constraint types |
| `src/constraints/WingSizingConstraint.m` | Upper bound on W/S (landing, stall) |
| `src/constraints/ThrustConstraint.m` | Master equation (cruise, turn, dash, climb, takeoff) |
| `src/constraints/ConstraintAnalysis.m` | Aggregator — receives a list of constraints, computes optimal point + diagram |

### Layer 2 — F-16 specific (`examples/F16A/`)

| File | Purpose |
|------|---------|
| `examples/F16A/constraints/F16ConstraintSet.m` | Instantiates the 8 F-16 constraint points from `requirements.json / aircraft_spec.json`; returns a configured `ConstraintAnalysis` object |

### Tests

| File | Tests |
|------|-------|
| `tests/constraints/TestConstraintAnalysis.m` | Generic: test with toy constraints |
| `tests/examples/F16A/TestF16ConstraintSet.m` | F-16: optimal W/S and T/W within expected range |

---

## Design Notes

`ConstraintAnalysis` receives a list of `PointPerformanceBase` objects and the discipline objects via constructor (DI). It does not know it is running F-16 constraints. All condition-specific data (β, n, PS, alt, Mach, distances) lives in `F16ConstraintSet` and ultimately in `requirements.json / aircraft_spec.json`.

Inspired by NPTEL notebook (`NPTEL_Fighter_Aircraft_Sizing.ipynb`) class hierarchy, improved for MATLAB + English units.

---

## F-16 Constraint Conditions

Source: `examples/F16A/requirements.json` (populated from Requirements.xlsx as primary; β and μ from Constraints.xlsx). Data is written once — no duplication between the two Excel sources.

**CLmax is NOT a constraint input.** The constraint analysis calls `aero.CLmax(state)` at the relevant flight condition. The discipline computes it. Values from Constraints.xlsx (CLmax_TO=1.276, CLmax_land=1.426) are verification targets — see table below.

**Operational constraints** — all use β = 0.8997:

| # | Name | Alt (ft) | Mach | n | AB% | PS (ft/s) |
|---|------|----------|------|---|-----|-----------|
| 1 | Max Mach | 36,000 | 1.60 | 1.0 | 100 | 0 |
| 2 | Cruise | 36,000 | 0.87 | 1.0 | 0 | 0 |
| 3 | Max Alt (ceiling) | 50,000 | 0.87 | 1.0 | 100 | 0 |
| 4 | Combat Turn 1 (subsonic) | 20,000 | 0.87 | 4.5 | 100 | 0 |
| 5 | Combat Turn 2 (supersonic) | 36,000 | 1.40 | 1.4 | 100 | 0 |
| 6 | Excess Power | 10,000 | 0.87 | 1.0 | 100 | 500 |

**Field constraints** — β = 1.0:

| # | Name | Alt (ft) | k factor | S_ground_roll (ft) | μ |
|---|------|----------|----------|-------------------|---|
| 7 | Takeoff | 0 | k_TO = 1.2 | 4,000 | 0.03 |
| 8 | Landing | 0 | k_L = 1.3 | 4,000 | 0.50 |

**Note on distances:** Requirements.xlsx quotes a field length of 7,999 ft; Constraints.xlsx uses a ground roll of 4,000 ft. Both are stored in `requirements.json`; constraint equations use the ground roll value. The two values imply different runway models — flag this for professor confirmation during Step 0 (before JSON is written).

**CLmax verification targets** (from Constraints.xlsx — computed values to compare against, not inputs):

| Condition | Excel value | Aerodynamics call |
|-----------|------------|-------------------|
| Takeoff (flaps partial, sea level) | 1.276 | `aero.CLmax(AircraftState(0, 0.1))` |
| Landing (flaps full, sea level) | 1.426 | `aero.CLmax(AircraftState(0, 0.1))` |

---

## Equations & References

### ThrustConstraint — Mattingly Master Equation
| Quantity | Equation | Reference |
|----------|----------|-----------|
| T/W | (β/α) × [q × CD0/(β × W/S) + K2 × (n × β/q)^2 × W/S + K1 × n × β/α + PS/V] | Mattingly, Aircraft Engine Design; `temp_AI/docs/disciplines/07_constraints.md` |
| α | `prop.thrust_lapse(state)` — AB or mil depending on AB% flag | PropulsionBase |
| CD0, K1, K2 | `aero.drag_polar(state)` | AerodynamicsBase |
| q | `state.q` | AircraftState |

### WingSizingConstraint — Landing
| Quantity | Equation | Reference |
|----------|----------|-----------|
| W/S ≤ | μ × ρ × g × CLmax × S_ground_roll / (k_L²) × β⁻¹ | Raymer 6th ed (landing ground roll, confirm exact eq at implementation) |

### ThrustConstraint — Takeoff
| Quantity | Equation | Reference |
|----------|----------|-----------|
| T/W ≥ | (β² / α) × (k_TO² / (ρ × g × CLmax_TO)) × (W/S) / S_ground_roll | Raymer 6th ed (takeoff ground roll simplified) |

---

## Plot Deliverables

1. Constraint diagram for F-16 with all 8 constraints, design point marked, feasible region shaded.
2. Overlay: same diagram computed with F16L1, F16L2, F16L3 disciplines on one figure — shows fidelity sensitivity.

---

## Tests

### Generic (`tests/constraints/TestConstraintAnalysis.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| ThrustConstraint returns finite T/W over W/S sweep | no NaN, no Inf | exact |
| WingSizingConstraint returns positive W/S limit | > 0 | exact |
| optimal_point: W/S ≤ landing limit | physical | exact |
| Works with mock aero/prop objects | converges | — |

### F-16 specific (`tests/examples/F16A/TestF16ConstraintSet.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| Optimal W/S (any discipline level) | in range 80–130 psf | physics bounds |
| Optimal T/W (any discipline level) | in range 0.6–1.0 | physics bounds |
| Same optimal_point API with L1, L2, L3 disciplines | all converge | — |
| Landing constraint produces finite upper bound | > 0 | exact |
| `aero.CLmax` at takeoff state | ~1.276 (Excel verification target) | ±20% — textbook accuracy |
| `aero.CLmax` at landing state | ~1.426 (Excel verification target) | ±20% — textbook accuracy |

Note: We do not test against Brandt's exact W/S=104.59 psf or T/W=0.7575. The textbook equations will give their own estimates. CLmax comparison is a diagnostic check, not a pass/fail gate — the discipline computes what it computes.

---

## Verification

```matlab
runtests('tests/constraints/TestConstraintAnalysis.m')
runtests('tests/examples/F16A/TestF16ConstraintSet.m')
```
All tests must pass before Step 7 begins.
