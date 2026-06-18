# V&V: Mission Analysis

## Test File

`examples/F-16A B Block 10 and 15/tests/test_F16Mission.m`

Run with:
```matlab
runtests('test_F16Mission')
```

## Brandt Reference Values

From Brandt-F16-A.xls (`Miss` tab):

| Quantity | Brandt | Source | Notes |
|---|---|---|---|
| W_fuel total | 6,000 lb | Miss!O9 | 14-segment mission |
| W_TO | 31,377 lb | Wt!B3 | Includes fuel |
| Mission time | 94 min | Miss!P9 | |
| Cruise range (outbound) | 190.8 nmi | Miss segments | |
| Dash range | 50 nmi | Miss segments | |
| Cruise range (return) | 250 nmi | Miss segments | |
| Loiter | 20 min at 10k ft | Miss segments | |
| Combat | 2 min at 25k ft / M0.87 | Miss segments | |

## Mission Profile Discrepancy

Brandt's 14-segment mission includes patrol loiters and a second climb leg before the return cruise. The design study scripts use an 11-segment simplified profile:

| Included (11-seg) | Excluded (vs. Brandt 14-seg) |
|---|---|
| Startup, taxi, takeoff | Patrol loiter 1 (before combat) |
| Climb (outbound) | Patrol loiter 2 (after combat) |
| Cruise outbound (190.8 nmi) | Second climb leg (return) |
| Dash (50 nmi) | |
| Combat (2 min, -4,400 lb weapons) | |
| Cruise return (250 nmi) | |
| Loiter (20 min, 10k ft) | |
| Descent, landing | |

The excluded segments add approximately 1,000–1,500 lb of fuel. The 11-segment fuel estimate is therefore expected to be **3,500–5,000 lb** (vs. Brandt's 6,000 lb). Tests are written to check physical reasonableness, not exact match.

## Test Matrix

| Test name | Fidelity | Quantity | Pass criterion |
|---|---|---|---|
| `testL1_compute_fuel_positive` | L1 | W_fuel > 0 | Positive |
| `testL1_fuel_decreasesWithLowerWTO` | L1 | W_fuel(31,377) > W_fuel(25,000) | Monotone |
| `testL2_compute_fuel_positive` | L2 | W_fuel ∈ [500, 12,000] lb | Physical range |
| `testL3_compute_fuel_positive` | L3 | W_fuel ∈ [500, 12,000] lb | Physical range |
| `testL2_vs_L1_fuel_reasonableRange` | L1 vs L2 | ratio ∈ [0.4, 2.5] | Consistent across levels |
| `testL1_fuelFraction_fighters` | L1 | Roskam WF(climb) ∈ [0.85, 1.0] | Physical range |

## Expected Accuracy by Level

| Level | Basis | Expected W_fuel | Accuracy vs. Brandt 6,000 lb |
|---|---|---|---|
| L1 (11 seg) | Roskam fuel fractions | 3,500–5,000 lb | −17% to −42% (expected due to missing legs) |
| L2 (11 seg) | Single-point Breguet | 3,500–5,200 lb | Similar to L1 |
| L3 (11 seg) | Sub-segmented integration | 3,800–5,500 lb | Slightly higher (more accurate cruise improvement) |

The 11-segment total should not be expected to match Brandt's 6,000 lb. The correct check is that the **full 14-segment design study** (with patrol legs added back) converges to approximately 6,000 lb.

## Key Fuel Fraction Notes

### Startup / Taxi / Landing / Descent

Roskam Table 2.1 fuel fractions for fighters:

| Segment | W_i / W_{i-1} |
|---|---|
| Startup + warmup | 0.990 |
| Taxi | 0.990 |
| Takeoff | 0.990 |
| Climb | 0.980 |
| Descent | 0.995 |
| Landing + taxi back | 0.992 |

Together these segments consume approximately `1 - (0.990)^3 × 0.980 × 0.995 × 0.992 ≈ 6.4%` of W_TO ≈ 2,000 lb. This is consistent with Brandt's ground operations + climb fuel.

### Cruise Breguet

L1 cruise Breguet (single-point, using tabulated LD = 6.5 for fighter jet, corrected by 0.866):

```
LD_cruise = 0.866 × 6.5 = 5.63
V         = M × a_cruise = 0.87 × 968 ft/s ≈ 842 ft/s
TSFC      = 0.8/3600 = 2.22e-4 /s
Range = 190.8 × 6076 = 1,159,301 ft

W_f/W_i = 1 - exp(-R × TSFC / (V × LD))
        = 1 - exp(-1,159,301 × 2.22e-4 / (842 × 5.63))
        ≈ 0.055   → ~1,700 lb
```

Return cruise (250 nmi) ≈ 2,200 lb. Together: ~3,900 lb — consistent with the 11-segment estimate range.
