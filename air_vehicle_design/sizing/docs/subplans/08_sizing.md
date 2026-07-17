# Subplan 08 — Sizing

**Status:** Placeholder — not started
**Depends on:** Steps 0–7 (all prior steps complete and tested)
**Blocks:** Nothing — final integration step

---

## Objectives

Implement `SizingLoopL1` and `SizingLoopL2`. Generate XDSM diagrams before any MATLAB code is written. Validate against F-16 Brandt ground truth using F-16 discipline subclasses. `SizingLoopL2` adds tail sizing (L1 volume coefficients) and a quick control surface sizing pass.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/sizing/SizingLoopL1.m` | Single-variable iteration (W_TO only) |
| `src/sizing/SizingLoopL2.m` | Two-variable iteration (W_TO and T_SL); calls tail + control surface sizing each iteration |

### Layer 2 — F-16 specific (`examples/F16A/`)

The sizing loops are fully generic. F-16-specific work is in the design study scripts:

| File | Purpose |
|------|---------|
| `examples/F16A/design_study_01_L1.m` | F16L1 disciplines → SizingLoopL1 |
| `examples/F16A/design_study_02_L2.m` | F16L2 disciplines → SizingLoopL2 |
| `examples/F16A/design_study_03_L3.m` | F16L3 disciplines → SizingLoopL2 |

### Tests

| File | Tests |
|------|-------|
| `tests/sizing/TestSizingLoops.m` | Generic: convergence with mock discipline objects |
| `tests/examples/F16A/TestF16SizingStudies.m` | F-16: W_TO, T_SL, S_ref in physically reasonable range |

---

## Pre-Implementation: XDSM Diagrams

**Before writing any MATLAB:** run the XDSM Python scripts in `temp_AI/xdsm/`:
```
python temp_AI/xdsm/sizing_L1_xdsm.py
python temp_AI/xdsm/sizing_L2_xdsm.py
```
Review diagrams with professor before implementing. The data flow in the XDSM must match the call sequence below.

---

## Design Notes

- `SizingLoopL1` and `SizingLoopL2` are plain handle classes (no abstract base). Constructor: `SizingLoopL1(aero, prop, wts, geom, miss, con)`.
- Under-relaxation factor = 0.5 (default); configurable via `opts` struct.
- Convergence tolerance: 1.0 lbf. Max iterations: 200.
- `run(req)` returns struct: `result.W_TO`, `result.S_ref`, `result.T_SL`, `result.n_iter`, `result.converged`, `result.history`.
- All discipline objects are mutated in-place (handle semantics). Always create fresh objects at the start of each design study.

---

## SizingLoopL1 — Call Sequence (per iteration)

From `temp_AI/docs/00_framework_overview.md` Section 5:
```matlab
opt        = con.optimal_point(aero, prop)   % → {W_S, T_W}
S_ref      = W_TO / opt.W_S
geom.S_ref = S_ref
req.S_ref  = S_ref
prop.T0    = opt.T_W * W_TO
W_fuel     = miss.compute_fuel(aero, prop, W_TO, req)
W_OEW      = wts.OEW(W_TO)
W_TO_new   = W_OEW + req.W_payload + W_fuel
W_TO       = 0.5*W_TO + 0.5*W_TO_new        % under-relaxation
```

---

## SizingLoopL2 — Call Sequence (per iteration)

From `temp_AI/docs/00_framework_overview.md` Section 5 + resolved decisions:
```matlab
opt       = con.optimal_point(aero, prop)    % → {T_W} (S_ref fixed)
T_SL_new  = opt.T_W * W_TO
prop.T0   = T_SL_new

% Tail sizing (L1 volume coefficient method)
tail_result   = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus)
geom.S_HT     = tail_result.S_HT
geom.S_VT     = tail_result.S_VT

% Control surface sizing (Raymer Fig 6.3, Table 6.5)
cs_result     = ctrl.size(geom)
geom.S_ail    = cs_result.S_ail    % aileron
geom.S_elev   = cs_result.S_elev   % elevator
geom.S_rud    = cs_result.S_rud    % rudder

W_fuel    = miss.compute_fuel(aero, prop, W_TO, req)
W_OEW     = wts.OEW(W_TO)
W_TO_new  = W_OEW + req.W_payload + W_fuel
W_TO      = 0.5*W_TO + 0.5*W_TO_new
T_SL      = 0.5*T_SL + 0.5*T_SL_new
```
Convergence: `|W_TO_new − W_TO| < tol` AND `|T_SL_new − T_SL| < tol`.

---

## Control Surface Sizing

Added to `SizingLoopL2` per resolved decisions. Implemented in a new class:

**File:** `src/sizing/ControlSurfaceSizer.m` (plain class, not abstract)

**Method:** `size(geom)→struct(S_ail, S_elev, S_rud)`

| Surface | Equation | Reference |
|---------|----------|-----------|
| Aileron | S_ail = f_ail × S_ref; f_ail from historical fraction | Raymer 6th ed, Table 6.5 |
| Elevator | S_elev = f_elev × S_HT; f_elev from historical fraction | Raymer 6th ed, Table 6.5 |
| Rudder | S_rud = f_rud × S_VT; f_rud from historical fraction | Raymer 6th ed, Table 6.5 |
| Configuration | Conventional / delta / canard selection | Raymer 6th ed, Figure 6.3 |

For the F-16 (delta wing + conventional tail + no canard): the fractions from Table 6.5 for fighter category are used. Exact fractions TBD at implementation when Raymer Table 6.5 is read.

---

## Tail Sizing (L1 only — L2 is future work)

**File:** `src/disciplines/tail_sizing/TailSizingLevel1.m` (also `examples/F16A/disciplines/tail_sizing/F16TailSizingLevel1.m` wires in c_HT=0.40, c_VT=0.07 from F-16A Block 50.xlsx)

| Surface | Equation | Reference |
|---------|----------|-----------|
| S_HT | c_HT × cbar × S_ref / L_HT; L_HT = 0.5 × L_fus | Raymer 6th ed, eq 6.28 |
| S_VT | c_VT × b × S_ref / L_VT; L_VT = 0.5 × L_fus | Raymer 6th ed, eq 6.29 |
| c_HT (fighter) | 0.40 | Raymer 6th ed, historical table |
| c_VT (fighter) | 0.07 | Raymer 6th ed, historical table |

**L2 tail sizing:** Raymer Chapter 16 — deferred to future work.

---

## F-16 Design Studies

| Study | Aero | Prop | Weights | Mission | Constraints | Loop |
|-------|------|------|---------|---------|-------------|------|
| design_study_01_L1 | F16AeroL1 | F16PropL1 | F16WeightsL1 | MissionAnalysisL1 | F16ConstraintSet | SizingLoopL1 |
| design_study_02_L2 | F16AeroL2 | F16PropL2 | F16WeightsL2 | MissionAnalysisL2 | F16ConstraintSet | SizingLoopL2 |
| design_study_03_L3 | F16AeroL3 | F16PropL3 | F16WeightsL3 | MissionAnalysisL3 | F16ConstraintSet | SizingLoopL2 |

---

## Tests

### Generic (`tests/sizing/TestSizingLoops.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| SizingLoopL1 converges with mock disciplines | `result.converged == true` | exact |
| SizingLoopL2 converges with mock disciplines | `result.converged == true` | exact |
| History has n_iter rows | correct size | exact |
| Control surface areas positive (L2) | S_ail, S_elev, S_rud > 0 | exact |
| S_HT, S_VT positive after tail sizing (L2) | > 0 | exact |

### F-16 specific (`tests/examples/F16A/TestF16SizingStudies.m`)
| Test | Study | Expected | Tolerance |
|------|-------|----------|-----------|
| W_TO | design_study_01 (L1) | 25,000–40,000 lb (±20% of Brandt 31,377) | textbook accuracy |
| W_TO | design_study_02 (L2) | 27,000–37,000 lb (±15% of Brandt) | better |
| T_SL | design_study_02 (L2) | 18,000–30,000 lbf (±20% of Brandt 23,770) | textbook accuracy |
| S_ref (L1 output) | design_study_01 | 250–360 ft² (±20% of Brandt 300) | textbook accuracy |
| All three studies converge | all | `converged == true` | exact |

---

## Verification

```matlab
runtests('tests/sizing/TestSizingLoops.m')
runtests('tests/examples/F16A/TestF16SizingStudies.m')
runtests('tests/')   % full suite — all prior tests still pass
```
All tests must pass. This is the final STOP — professor reviews all three design study outputs.
