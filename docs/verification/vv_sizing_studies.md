# V&V: Sizing Studies (End-to-End)

## Test File

`examples/F-16A B Block 10 and 15/tests/test_F16SizingStudies.m`

Run with:
```matlab
runtests('test_F16SizingStudies')
```

## Brandt Ground-Truth Targets

These are the top-level sizing outputs; meeting them means the framework has closed correctly.

| Parameter | Brandt | Source |
|---|---|---|
| W_TO (converged) | 31,377 lb | Wt!B3 |
| S_ref (wing area) | 300 ft² | JSON input (fixed) |
| T_SL (afterburner) | 23,770 lb | engine.T_AB_SLS_lb |
| W/S (wing loading) | 104.59 psf | Consts tab |
| T/W (thrust loading) | 0.7575 | Consts tab |
| OEW | 19,980 lb | Wt!B12 |
| W_fuel | 6,000 lb | Miss!O9 |
| S_HT (stabilator) | ~108 ft² | Back-calc from vol. coeff. |
| S_VT (vert. tail) | ~60 ft² | Back-calc from vol. coeff. |

## Test Matrix

### Design Study 01 (L1 disciplines, SizingLoopL1)

| Test | Quantity | Pass criterion |
|---|---|---|
| `testStudy01_converges` | Loop converges | `iter < max_iter` |
| `testStudy01_WTO_range` | W_TO ∈ [20,000, 50,000] lb | Physical range |
| `testStudy01_WTO_vs_Brandt` | W_TO within 30% of 31,377 | [22,000, 41,000] lb |
| `testStudy01_Sref_positive` | S_ref > 0 | Sanity |
| `testStudy01_Sref_range` | S_ref ∈ [200, 600] ft² | Physical range |
| `testStudy01_TSL_vs_Brandt` | T_SL within 30% of 23,770 | [16,600, 30,900] lb |
| `testStudy01_WS_range` | W/S ∈ [60, 160] psf | Physical range |
| `testStudy01_TW_range` | T/W ∈ [0.4, 1.5] | Physical range |

### Design Study 02 (L2 disciplines, SizingLoopL2)

| Test | Quantity | Pass criterion |
|---|---|---|
| `testStudy02_converges` | Loop converges | `iter < max_iter` |
| `testStudy02_WTO_range` | W_TO ∈ [20,000, 50,000] lb | Physical range |
| `testStudy02_WTO_vs_Brandt` | W_TO within 20% of 31,377 | [25,100, 37,650] lb |
| `testStudy02_TSL_positive` | T_SL > 0 | Sanity |
| `testStudy02_TSL_vs_Brandt` | T_SL within 20% of 23,770 | [19,000, 28,500] lb |
| `testStudy02_SHT_positive` | S_HT > 0 (tail was sized) | Sanity |
| `testStudy02_SVT_positive` | S_VT > 0 | Sanity |
| `testStudy02_SHT_range` | S_HT ∈ [50, 200] ft² | Physical range |

### Design Study 03 (L3 aero/prop/mission, SizingLoopL2)

| Test | Quantity | Pass criterion |
|---|---|---|
| `testStudy03_converges` | Loop converges | `iter < max_iter` |
| `testStudy03_WTO_range` | W_TO ∈ [20,000, 50,000] lb | Physical range |
| `testStudy03_WTO_closer_to_Brandt` | |W_TO - 31,377| ≤ |W_TO_L2 - 31,377| | L3 ≥ L2 accuracy |

## Expected Accuracy by Design Study

| Study | Fidelity | Expected W_TO | W_TO accuracy | T_SL accuracy |
|---|---|---|---|---|
| Study 01 | L1 all | 26,000–38,000 lb | ±20–30% | ±20–30% |
| Study 02 | L2 all | 28,000–36,000 lb | ±10–20% | ±10–20% |
| Study 03 | L3 aero/prop/mission + L2 weights | 29,000–35,000 lb | ±8–15% | ±8–15% |

### Why L1 Has Wide Tolerance

At L1, every discipline uses regression tables. The combined uncertainty is approximately:
- Weight regression: ±10%
- S_wet regression: ±15%
- TSFC table: ±15%
- Thrust lapse approximation: ±20%

These errors compound multiplicatively through the sizing loop. A converged W_TO ±30% of Brandt is acceptable at L1.

### Why Studies 01 and 02 Are Different Loops

**Study 01 (SizingLoopL1):** S_ref is an *output* — it is computed from the constraint-optimal W/S. If the constraint analysis determines W/S = 100 psf and W_TO converges to 30,000 lb, then S_ref = 300 ft².

**Study 02/03 (SizingLoopL2):** S_ref is a *fixed input* from `req.S_ref` (set to 300 ft² from the JSON). The loop iterates on W_TO and T_SL simultaneously. Fixing S_ref introduces an additional loop variable (T_SL) because the constraint diagram is now evaluated at a fixed W/S = W_TO / 300, and T_W (and therefore T_SL) changes as W_TO iterates.

## Fidelity Monotonicity Test

The test `testStudy03_WTO_closer_to_Brandt` checks that increasing fidelity from L2 to L3 brings W_TO closer to Brandt's 31,377 lb. This is a fundamental property the framework should satisfy: higher fidelity disciplines should produce more accurate sizing results.

**Note:** This test may not always pass if L3's drag buildup gives a CD0 that is significantly different from L2 (e.g., if L3 computes CDmin = 0.0170 while L2 uses the mission-effective 0.0270). See the aerodynamics V&V for the two-CD0 discussion.

## Sizing Loop Convergence Notes

Both sizing loops use under-relaxation (factor 0.5):

```matlab
W_TO = 0.5 * W_TO + 0.5 * W_TO_new
```

This prevents oscillation around the fixed point. Without under-relaxation, the loop sometimes overshoots by 20–30% per iteration and can fail to converge. With damping 0.5, convergence typically requires 20–50 iterations from a W_TO = 30,000 lb initial guess.

If the loop fails to converge (returns `iter == max_iter`), the most common causes are:
1. Fuel burn is non-physical (e.g., TSFC or LD very wrong) — check propulsion and aerodynamics discipline outputs
2. OEW is non-physical — check the weight model
3. Initial W_TO guess is far from the converged value — increase `max_iter` or try a different initial guess
