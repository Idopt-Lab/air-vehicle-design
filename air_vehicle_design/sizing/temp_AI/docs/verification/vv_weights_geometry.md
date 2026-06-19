# V&V: Weights and Geometry

## Test File

`examples/F-16A B Block 10 and 15/tests/test_F16WeightsAndGeometry.m`

Run with:
```matlab
runtests('test_F16WeightsAndGeometry')
```

## Brandt Reference Values

### Weights (Wt tab, W_TO = 31,377 lb)

| Quantity | Brandt | Source |
|---|---|---|
| OEW | 19,980 lb | Wt!B12 |
| OEW/W_TO | 0.637 | Derived |
| W_structure | 6,723 lb | Wt!B9 |
| W_wing | 1,786 lb | Wt!C9 |
| W_fuselage | 3,652 lb | Wt!D9 |
| W_engine installed | 4,730 lb | Wt!B22 |
| W_landing gear | 1,067 lb | Wt!B23 |
| W_fuel | 6,000 lb | Wt!B6 (Miss!O9) |
| W_payload | 5,100 lb | 4,400 lb weapons + 700 lb pilot |

### Geometry (Geom tab)

| Quantity | Brandt | Source | Notes |
|---|---|---|---|
| S_ref | 300 ft² | JSON input | Fixed, not a prediction |
| S_wet total | 1,331.09 ft² | Geom!B19 | Excel has double-count bug; corrected = 1,332.7 ft² |
| S_wet fuselage | 730.4 ft² | Geom!B3 | |
| S_wet wing | 392.0 ft² | — | Back-calculated |
| L_fus | 48.3 ft | JSON input | Fixed |
| AR | 3.0 | JSON input | Fixed |
| b (span) | 30 ft | `√(AR × S_ref)` | |

## Test Matrix

### Weights Tests

| Test name | Fidelity | Quantity | Pass criterion |
|---|---|---|---|
| `testL1_OEW_vs_Brandt` | L1 | OEW/W_TO_brandt ∈ [0.55, 0.75] | Historical range |
| `testL1_OEW_positive` | L1 | OEW > 0 | Sanity |
| `testL2_OEW_vs_Brandt` | L2 | OEW ∈ [17,000, 23,000] lb | ±15% of 19,980 |
| `testL2_OEW_positive` | L2 | OEW > 0 | Sanity |
| `testOEW_increases_withWTO` | L1/L2 | OEW(35,000) > OEW(25,000) | Monotone |
| `testOEW_fraction_range` | L1 | OEW/W_TO ∈ [0.50, 0.80] | Physical range |

### Geometry Tests

| Test name | Fidelity | Quantity | Pass criterion |
|---|---|---|---|
| `testL1_S_ref_set` | L1 | S_ref == 300 ft² | From JSON |
| `testL1_S_wet_positive` | L1 | S_wet > 0 | Sanity |
| `testL1_S_wet_range` | L1 | S_wet ∈ [900, 2,000] ft² | Physical range |
| `testL2_S_wet_range` | L2 | S_wet ∈ [900, 2,000] ft² | Physical range |
| `testL2_cbar_positive` | L2 | cbar > 0 | Sanity |
| `testL2_cbar_range` | L2 | cbar ∈ [5, 20] ft | Physical range |
| `testL2_b_from_AR` | L2 | b = √(AR × S_ref) | Derived property |
| `testL3_S_wet_vs_Brandt` | L3 | S_wet ∈ [1,100, 1,600] ft² | ±20% of 1,331 ft² |

## Weight Estimation Accuracy

### Why L1 Has Wide Tolerance

Raymer's fighter regression (Table 6.1) is calibrated to a broad aircraft fleet. Individual aircraft can deviate ±20% from the regression line. For the F-16, the regression gives approximately:

```
OEW/W_TO = 2.34 × W_TO^(-0.13)
         = 2.34 × 31,377^(-0.13)
         ≈ 0.62
```

vs. Brandt's 0.637. The 2.4% discrepancy is within regression scatter. The test passes if OEW/W_TO ∈ [0.55, 0.75].

### L2 Improvement

Raymer Equation 6.1 refines the regression with thrust loading and technology factors. Expected accuracy ±10–15% for the F-16. The test accepts OEW ∈ [17,000, 23,000] lb (±15% band around 19,980 lb).

## Geometry Accuracy

### S_wet at L1/L2

Roskam's regression for fighter S_wet:

```
S_wet = 4.183 × W_TO^0.4921
      = 4.183 × 31,377^0.4921
      ≈ 1,240 ft²
```

vs. Brandt's 1,331 ft². The 6.8% underestimate is typical of Roskam regressions for fighters with prominent vertical tail and strakes. The test accepts ±30% of Brandt.

### cbar Computation

For the F-16 with taper ratio λ = 0.258 (actual cranked wing, approximated as 0.3):

```
c_root = 2 × S_ref / (b × (1 + λ)) = 2 × 300 / (30 × 1.3) ≈ 15.4 ft
cbar   = (2/3) × 15.4 × (1 + 0.3 + 0.09) / 1.3 ≈ 11.4 ft
```

This is used by the tail volume coefficient method. The exact value is less important than it being in the physically correct range (~10–15 ft for the F-16).
