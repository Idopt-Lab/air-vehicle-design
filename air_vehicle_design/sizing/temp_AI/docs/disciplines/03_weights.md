# Weights Discipline

## 1. Abstract Interface

**File:** `src/base/WeightsBase.m`

```matlab
classdef WeightsBase < handle
    methods (Abstract)
        W_OEW = OEW(obj, W_TO)   % Operational Empty Weight (lbf)
    end
end
```

`W_TO` is the current takeoff gross weight estimate (lbf). The sizing loop calls this method at every iteration after computing fuel and before closing the weight equation.

### Why a Single Method

At conceptual design, the entire empty weight is what the loop needs to close the weight statement:

```
W_TO = OEW + W_payload + W_fuel
```

A single `OEW(W_TO)` method is the correct abstraction because every concrete implementation, from the L1 regression to the L4 component build-up, ultimately answers the same question: "given a gross weight, what is the empty weight?" All intermediate sub-components (structure, systems, propulsion group) are discipline-internal details.

The sizing loop does not need to know *how* OEW is decomposed; it only needs the total. If the loop needed individual components, that would violate the encapsulation principle and break the ability to swap fidelity levels freely.

---

## 2. Level I Weights

**File:** `src/Disciplines/Weight/WeightLevel1.m`

**Physics:** Historical regression on aircraft type.

### Method

Raymer Table 6.1 and Roskam Vol. I Table 3.5 provide statistical correlations of the form:

```
W_OEW / W_TO = A * W_TO^C
```

where `A` and `C` are constants fitted to a fleet of aircraft in the same category (fighter, transport, bomber, etc.). The regression reflects average historical design practice; it says nothing about the specific aircraft configuration.

| Type | A | C | Source |
|---|---|---|---|
| Fighter (jet) | 2.34 | -0.13 | Raymer T6.1 |
| Transport (jet) | 1.02 | -0.06 | Raymer T6.1 |
| General aviation | 2.36 | -0.18 | Roskam I |

The constructor takes `aircraft_type` as a string and looks up the corresponding constants.

### What Is Not Captured

- Configuration-specific structural efficiency (delta-wing vs straight wing)
- Material choice (composite vs aluminum)
- Specific engine installation mass fraction
- Mission equipment (EW pods, gun, radar mass)

L1 weights assume the new design will be "average" for its category. Deviations from the historical mean (e.g., extensive composites → lighter structure) cannot be captured.

---

## 3. Level II Weights

**File:** `src/Disciplines/Weight/WeightLevel2.m`

**Physics:** Gross empty weight fraction from Raymer Eq. 6.1.

### Method

Raymer's "gross" fraction method refines the L1 regression by treating W_OEW as a function of several technology factors:

```
W_OEW / W_TO = f(W_TO, T_SL/W_TO, W_TO/S_ref, V_max, AR, S_wet/S_ref, ...)
```

The full form is a nonlinear regression calibrated against a broader aircraft database. This gives sensitivity to design variables (wing loading, thrust loading) that are absent from the pure type regression at L1.

### Key difference from L1

At L1, OEW is a function of `W_TO` and aircraft type only. At L2, OEW also responds to thrust loading (because heavier engines are heavier empty weight) and to aspect ratio (because high AR wings are structurally heavier). This coupling is important: the sizing loop's constraint analysis determines T/W, and at L2 that T/W feeds back into the OEW estimate, creating a second loop within the sizing iteration.

In practice this does not require a nested inner loop. The under-relaxed outer iteration converges the mutually dependent quantities simultaneously.

---

## 4. Level III Weights

**File:** `src/Disciplines/Weight/WeightLevel3.m`

**Physics:** Component build-up using Roskam Vol. I empirical equations.

Components estimated separately:

| Component | Method |
|---|---|
| Wing | Roskam plate-area formula; function of `S_ref`, `AR`, `t/c`, `lambda`, `Lambda_LE`, `n_ult` |
| Fuselage | Roskam wetted-area formula; function of `S_wet_fus`, `L/D`, `V_div` |
| Horizontal tail | Raymer equation; function of `S_HT`, `AR_HT`, `lambda_HT`, design dive speed |
| Vertical tail | Raymer equation; function of `S_VT`, `AR_VT` |
| Landing gear | 0.034 × W_TO (Raymer statistical) |
| Engine installed | Engine bare weight + installation fraction × W_engine_bare |
| Systems / furnishings | Roskam fractions per component |

The sum of all components gives W_OEW. This approach is more sensitive to configuration changes but requires substantially more geometry input.

---

## 5. Level IV Weights

**File:** `src/Disciplines/Weight/WeightLevel4.m`

**Physics:** Full Raymer Chapter 15 detailed component equations.

L4 adds higher-order correction factors not in L3:
- Material correction (composites reduce structure weight by 15–25%)
- Fighter wing torsional stiffness requirement (increases wing weight ~10% for supersonic flutter)
- Fuselage pressurization weight penalty (relevant for transport aircraft)
- Avionics weight estimation from RF aperture area

At AOE 4065, L4 is provided for completeness. Students are not required to implement or use it.

---

## 6. Brandt Ground-Truth Comparison

At W_TO = 31,377 lb (Brandt F-16A/B Block 10/15):

| Quantity | Brandt | L1 | L2 | L3 |
|---|---|---|---|---|
| OEW | 19,980 lb | Regression (~19,500–21,000 lb) | Raymer Eq 6.1 | Component sum |
| OEW/W_TO | 0.637 | ~0.62–0.67 | Similar | Explicit |
| W_structure | 6,723 lb | Not resolved | Not resolved | Summed |
| W_wing | 1,786 lb | Not resolved | Not resolved | Roskam |
| W_fuselage | 3,652 lb | Not resolved | Not resolved | Roskam |
| W_engine installed | 4,730 lb | Fraction of W_TO | Raymer fraction | Raymer/Roskam |

### Note on Level I Calibration

Raymer's fighter regression (Table 6.1) gives OEW/W_TO ≈ 0.63–0.65 for W_TO ≈ 31,000 lb, which is within 2% of Brandt's 0.637. This good agreement is expected — Raymer calibrated the regression against aircraft including the F-16. At L1, the weight estimate will always be close to historically similar designs. The real test of weight-model accuracy is at L3, where the geometry must be correct.

---

## 7. Key Design Decisions

**Why only one abstract method:** A multi-method interface (e.g., `wing_weight`, `fuselage_weight`) would force L1 to implement methods that have no meaning for a regression-based model. The single `OEW` method is the smallest possible interface that supports the sizing loop.

**Why `n_ult` is a property not an argument:** Ultimate load factor is a requirement, not an operating condition. It is set in the constructor and does not vary per call site. Making it a property simplifies the `OEW(W_TO)` signature.
