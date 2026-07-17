# Subplan 07 — Mission Analysis

**Status:** Placeholder — not started
**Depends on:** Steps 1–5 (all disciplines), Step 6 (optional — constraint conditions inform β)
**Blocks:** Step 8 (sizing)

---

## Objectives

Implement `MissionBase` and three fidelity levels. The mission segments are generic (Breguet, fuel fractions from Roskam). The F-16 CAP mission profile is loaded from `requirements.json / aircraft_spec.json`. Key deliverable: `compute_fuel(aero, prop, W_TO, req)` returning total fuel weight in lbf.

Visualization: waterfall bar chart of fuel burn per segment.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/MissionBase.m` | Abstract base: `compute_fuel(aero, prop, W_TO, req)→scalar` |
| `src/mission/segments/MissionSegmentBase.m` | Abstract segment: `compute_weight_fraction(aero, prop, state, W_mid)→scalar` |
| `src/mission/segments/StartupSegment.m` | Fixed WF = 0.990 |
| `src/mission/segments/TaxiSegment.m` | Fixed WF = 0.990 |
| `src/mission/segments/TakeoffSegment.m` | Fixed WF = 0.995 |
| `src/mission/segments/ClimbSegment.m` | WF = 1.0065 − 0.0325×M |
| `src/mission/segments/CruiseSegment.m` | Breguet range |
| `src/mission/segments/DashSegment.m` | Breguet range (supersonic) |
| `src/mission/segments/CombatSegment.m` | WF = 1 − TSFC×T/W×t |
| `src/mission/segments/LoiterSegment.m` | Breguet endurance |
| `src/mission/segments/DescentSegment.m` | WF = 1.0 |
| `src/mission/segments/LandingSegment.m` | Fixed WF = 0.995 |
| `src/mission/MissionAnalysisL1.m` | Fixed fractions + tabulated LD/TSFC (ignores aero/prop args) |
| `src/mission/MissionAnalysisL2.m` | Single-point Breguet calling aero.drag_polar + prop.TSFC per segment |
| `src/mission/MissionAnalysisL3.m` | Sub-segmented cruise/climb (N=20 sub-intervals) |

### Layer 2 — F-16 specific (`examples/F16A/`)

No mission analysis subclassing needed — the generic classes are sufficient. The F-16 provides a **mission profile** struct loaded from `requirements.json / aircraft_spec.json`:

| File | Purpose |
|------|---------|
| `examples/F16A/F16MissionProfile.m` | Loads and returns the `req` struct for the F-16 CAP mission |

### Tests

| File | Tests |
|------|-------|
| `tests/mission/TestMissionAnalysis.m` | Generic: weight continuity, segment WF bounds, L1 isolation |
| `tests/examples/F16A/TestF16Mission.m` | F-16: total fuel physically reasonable; continuity across all segments |

---

## Design Notes

- L1 does NOT call `aero.drag_polar` or `prop.TSFC`. Arguments accepted but unused — test this with a mock that errors if called.
- L2 calls one `aero.drag_polar(state)` and one `prop.TSFC(state)` per segment.
- L3 sub-divides cruise and climb into N=20 sub-intervals; L/D recomputed at each sub-interval weight.
- Weight continuity: Wf of segment N = Wi of segment N+1 — enforced in `MissionSegmentBase`.
- Reserve fuel fraction (RFF): 0.05 added to total mission fuel (Roskam convention).
- `W_drop` from payload release (combat segment) reduces weight at end of that segment, NOT as fuel.

---

## Equations & References

| Segment | Equation | Reference |
|---------|----------|-----------|
| Startup | WF = 0.990 | Roskam Airplane Design Part I, Table 2.1 |
| Taxi | WF = 0.990 | Roskam Airplane Design Part I, Table 2.1 |
| Takeoff | WF = 0.995 | Roskam Airplane Design Part I, Table 2.1 |
| Climb | WF = 1.0065 − 0.0325 × M_end | Roskam Airplane Design Part I, eq 2.10 |
| Cruise | WF = exp(−R × TSFC / (V × L/D)) | Breguet range equation |
| Dash | WF = exp(−R × TSFC / (V × L/D)) | Breguet range equation (supersonic TSFC from prop) |
| Combat | WF = 1 − TSFC × T/W × t | Roskam Airplane Design Part I, eq 2.13 |
| Loiter | WF = exp(−t × TSFC / (L/D)) | Breguet endurance equation |
| Descent | WF = 1.0 | Roskam (conservative) |
| Landing | WF = 0.995 | Roskam Airplane Design Part I, Table 2.1 |

---

## F-16 CAP Mission Profile

Source: `temp_Casey/inputs/Mission_Profile.xlsx` (Sheet: CAP).

| # | Segment | Alt (ft) | Mach | Range / Time | Payload drop (lbf) |
|---|---------|----------|------|--------------|--------------------|
| 1 | Startup | 0 | 0 | — | 0 |
| 2 | Taxi | 0 | 0 | — | 0 |
| 3 | Takeoff | 0 | 0.87 | — | 0 |
| 4 | Climb | 40,000 | 0.87 | — | 0 |
| 5 | Cruise (outbound) | 40,000 | 0.87 | 1,154,463 ft (~189 nm) | 0 |
| 6 | Dash | 40,000 | 1.60 | 303,806 ft (~50 nm) | 0 |
| 7 | Combat | 25,000 | 0.80 | 2 min | 4,400 |
| 8 | Cruise (return) | 40,000 | 0.87 | 1,458,269 ft (~239 nm) | 0 |
| 9 | Loiter | 10,000 | 0.30 | 20 min | 0 |
| 10 | Landing | 0 | 0 | — | 0 |

Fixed payload throughout: 5,100 lbf. Total droppable payload: 4,400 lbf (released at end of combat).

---

## Plot Deliverables

1. Waterfall bar chart — fuel burn per segment stacked to total mission fuel.
2. Overlay: run F16L1, F16L2, F16L3 through the same CAP mission — show how fuel estimate changes across fidelities.

---

## Tests

### Generic (`tests/mission/TestMissionAnalysis.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| Weight continuity: Wf[N] = Wi[N+1] | ±1e-8 lbf | exact |
| Wf < Wi for each fuel-burning segment | fuel consumed | exact |
| Descent WF = 1.0 (no fuel burned) | exact | exact |
| Total fuel > 0 | positive | exact |
| L1 does not call aero.drag_polar or prop.TSFC | mock raises error if called | exact |

### F-16 specific (`tests/examples/F16A/TestF16Mission.m`)
| Test | Level | Expected | Tolerance |
|------|-------|----------|-----------|
| Total fuel | F16L1 | W_fuel / W_TO ∈ 0.15–0.35 (plausible fighter range) | physics bounds |
| Total fuel | F16L2 | same range, tighter | narrower bounds |
| Weight at end of mission | all | W_land / W_TO ∈ 0.50–0.75 | physics bounds |
| W_drop accounted | all | W after combat = W before − segment_fuel − 4,400 lbf | ±1e-6 lbf |

---

## Verification

```matlab
runtests('tests/mission/TestMissionAnalysis.m')
runtests('tests/examples/F16A/TestF16Mission.m')
```
All tests must pass before Step 8 begins.
