# V&V: Propulsion

## Test File

`examples/F-16A B Block 10 and 15/tests/test_F16Propulsion.m`

Run with:
```matlab
runtests('test_F16Propulsion')
```

## Brandt Reference Values

From Brandt-F16-A.xls (`Engn` tab) and `f16a_geometry.json`:

| Quantity | Value | Source | Notes |
|---|---|---|---|
| T_AB_SLS (afterburner, SLS) | 23,770 lbf | `engine.T_AB_SLS_lb` JSON field | F100-PW-100 installed |
| T_mil_SLS (military, SLS) | 15,000 lbf | Brandt Engn tab | Non-afterburning |
| TSFC_mil at cruise | 0.70 /hr = 1.944e-4 /s | Brandt Engn tab | M 0.87, 36,000 ft |
| TSFC_AB at cruise | 2.20 /hr = 6.111e-4 /s | Brandt Engn tab | Afterburner cruise |
| α (thrust lapse), AB, 36k ft / M0.87 | ~0.34 | Brandt Consts tab | Back-calculated |

## Test Matrix

| Test name | Fidelity | Quantity checked | Pass criterion |
|---|---|---|---|
| `testL1_T0_setFromJSON` | L1 | `prop.T0 == 23,770 lbf` | AbsTol 1.0 lbf |
| `testL1_ThrustLapse_SL` | L1 | `alpha(0 ft, M=0)` = 1.0 | AbsTol 0.02 |
| `testL1_ThrustLapse_Altitude` | L1 | `alpha(36k ft, M=0.87)` ∈ [0.20, 0.60] | In range |
| `testL1_TSFC_ReturnsCruiseValue` | L1 | TSFC(36k, 0.87) ∈ [0.6, 1.6] /hr | In range |
| `testL2_T0_setFromJSON` | L2 | `prop.T0 == 23,770 lbf` | AbsTol 1.0 lbf |
| `testL2_ThrustLapse_SL` | L2 | `alpha(0 ft, M=0)` ≈ 1.0 | AbsTol 0.05 |
| `testL2_ThrustLapse_Altitude` | L2 | `alpha(36k ft, M=0.87)` ∈ [0.20, 0.65] | In range |
| `testL2_TSFC_Range` | L2 | TSFC(36k, 0.87) ∈ [0.4, 1.8] /hr | In range |
| `testL3_ThrustLapse_SL` | L3 | `alpha(0 ft, M=0)` ≈ 1.0 | AbsTol 0.10 |
| `testL3_TSFC_Range` | L3 | TSFC(36k, 0.87) ∈ [0.4, 2.0] /hr | In range |
| `testThrustLapseDecreases_WithAltitude` | L1 | α(0) > α(20k) > α(40k) | Monotone decreasing |

## Notes on Tolerances

Propulsion tolerances are wider than aerodynamics tolerances by design:

- **L1 TSFC:** The Raymer table value (≈0.80 /hr) differs from the Brandt F100-PW-100 value (0.70 /hr for military) because the table represents a generic low-BPR turbofan fleet average. The F-16's F100 is somewhat more efficient than the fleet average for its era.

- **Thrust lapse:** L1 uses a density-ratio approximation (`α ≈ (ρ/ρ_SL)^0.6`). The actual F100 lapse at M0.87 / 36,000 ft with afterburner is ≈0.34. The density ratio at 36,000 ft is `(0.000706/0.002377)^0.6 ≈ 0.397`. The difference (0.397 vs 0.34) comes from the Mach-number reduction in afterburner thrust not captured at L1.

## Military vs Afterburner Power

At L1, the framework does not distinguish military and afterburner settings. `T0` is set to `T_AB_SLS` by default so the constraint analysis (which uses afterburner for dash and turn constraints) gets the correct peak thrust. However, the TSFC returned is the military TSFC (the table does not have afterburner TSFC at L1).

At L2/L3, the `thrust_lapse` method can distinguish the two settings when the constructor is given both `T_AB_SLS` and `T_mil_SLS`. The `TSFC(state)` method returns the value appropriate for the current throttle setting.

## Expected Accuracy by Level

| Quantity | L1 accuracy | L2 accuracy | L3 accuracy |
|---|---|---|---|
| T0 (set from JSON) | Exact | Exact | Exact |
| Thrust lapse at altitude | ±20–30% | ±10–15% | ±10–15% |
| TSFC_mil | ±15–25% | ±10–20% | ±10–20% |
| TSFC_AB | Not captured | ±15–25% | ±15–25% |
