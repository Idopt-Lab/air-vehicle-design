# V&V: Aerodynamics

## Test File

`examples/F-16A B Block 10 and 15/tests/test_F16Aerodynamics.m`

Run with:
```matlab
runtests('test_F16Aerodynamics')
```

## Brandt Reference Values

From `f16a_geometry.json` and Brandt-F16-A.xls (Aero and Miss tabs):

| Quantity | Value | Source tab | Notes |
|---|---|---|---|
| CD0 (mission drag polar) | 0.0270 | Miss tab | Effective; includes CDx, gear, non-ideal CL effects |
| CD0 (Aero tab, CDmin subsonic) | 0.0170 | Aero tab | Clean CDmin only |
| K2 (induced drag factor) | 0.1160 | Aero tab (back-calculated) | K2 ≈ 1/(π e AR) |
| K1 (linear CL term) | −0.00630 | Aero tab | From camber/twist |
| CLmax clean | 0.984 | Aero tab | No flap deflection |
| CLmax takeoff (conf) | 1.276 | Aero tab | With leading-edge flap |
| CLmax landing (conf) | 1.426 | Aero tab | Full flap |
| L/D_max | ~8.9 | Derived | 1/(2√(CD0·K2)) with Miss CD0 |

## Test Matrix

| Test name | Fidelity | Quantity checked | Expected result | Pass criterion |
|---|---|---|---|---|
| `testL1_drag_polar_fields` | L1 | Output struct has CD0, K1, K2 fields | Yes | Fields present |
| `testL1_CD0_positive` | L1 | CD0 > 0 | Yes | Positive scalar |
| `testL1_K2_positive` | L1 | K2 > 0 | Yes | Positive scalar |
| `testL1_K1_zero` | L1 | K1 = 0 | Yes | K1 ≡ 0 at L1 |
| `testL1_CD0_vs_Brandt` | L1 | CD0 ± 40% of 0.0270 | [0.016, 0.038] | In range |
| `testL1_K2_vs_Brandt` | L1 | K2 ± 40% of 0.1160 | [0.070, 0.162] | In range |
| `testL1_CLmax_clean_range` | L1 | CLmax ∈ [0.8, 1.8] | Roskam range | In range |
| `testL2_drag_polar_fields` | L2 | CD0, K1, K2 present | Yes | Fields present |
| `testL2_CD0_vs_Brandt` | L2 | CD0 within 30% of 0.0270 | [0.019, 0.035] | In range |
| `testL2_K2_vs_Brandt` | L2 | K2 within 20% of 0.1160 | [0.093, 0.139] | In range |
| `testL2_K1_zero` | L2 | K1 = 0 | Yes | K1 ≡ 0 at L2 |
| `testL3_K1_nonzero` | L3 | K1 ≠ 0 | Yes | Cambered airfoil |
| `testL3_CD0_range` | L3 | CD0 ∈ [0.013, 0.025] | Near CDmin 0.0170 | In range |
| `testL3_K2_range` | L3 | K2 ∈ [0.08, 0.16] | Similar to L1/L2 | In range |
| `testLDmax_reasonable` | L2 | L/D_max ∈ [6, 14] | ~8.9 Brandt | In range |

## Two CD0 Values Explained

The framework uses **two distinct CD0 values**, and students often confuse them:

1. **CD0 = 0.0170** (Brandt `Aero` tab, `CDmin` subsonic): This is the parasite drag coefficient at zero lift — the clean zero-lift drag at subsonic cruise. It is the physically meaningful quantity for aerodynamic comparison and is what L3 should reproduce via component buildup.

2. **CD0 = 0.0270** (Brandt `Miss` tab): This is the *effective* drag coefficient used in the mission analysis and constraint analysis. It is higher because it includes:
   - `CDx` = additional drag from protuberances, excrescences, weapons (≈ 0.003–0.006)
   - Gear-down drag during takeoff and landing (modeled as ΔCD0)
   - The fact that the mission is flown at a non-optimal CL (the quadratic polar over-predicts CD at off-design CL)

The framework uses 0.0270 for sizing (mission fuel, constraint T/W). L3's component buildup gives CDmin ≈ 0.0170; `CDx` is added per-segment in the mission analysis to reach the effective 0.0270.

## Cfe Calibration Decision

`F16AeroLevel2` uses `Cfe = 0.005908` (skin friction coefficient, back-calculated from Brandt CD0 = 0.0270):

```
CD0 = Cfe * S_wet / S_ref = 0.005908 * 1331.09 / 300 = 0.0262 ≈ 0.0270
```

Raymer's generic table gives `Cfe ≈ 0.0035–0.0040` for fighter aircraft (subsonic, clean). The difference (0.005908 vs 0.004) accounts for the CDx contribution and the difference between the clean Aero-tab polar and the mission-effective polar used by Brandt.

**Decision:** `F16AeroLevel2` explicitly uses 0.005908 so that L2 CD0 matches Brandt's 0.0270. This is a calibration choice for the F-16 ground-truth comparison; a new aircraft design would use the Raymer table value and accept a lower-fidelity CD0 estimate.

## Expected Accuracy by Level

| Level | CD0 accuracy vs. Brandt 0.0270 | K2 accuracy vs. Brandt 0.1160 |
|---|---|---|
| L1 | ±30–40% | ±30–40% |
| L2 (calibrated Cfe) | ±5–10% | ±10–15% |
| L2 (Raymer table Cfe) | ±20–30% | ±10–15% |
| L3 (component buildup) | ±10% (CDmin ≈ 0.017; CDx adds remainder) | ±10% |
