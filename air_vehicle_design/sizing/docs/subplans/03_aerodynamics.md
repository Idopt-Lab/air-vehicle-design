# Subplan 03 — Aerodynamics

**Status:** Placeholder — not started
**Depends on:** Steps 1–2 (AircraftState, Geometry)
**Blocks:** Steps 6, 7, 8 (constraint analysis, mission, sizing)

---

## Objectives

Implement `AerodynamicsBase` and three generic fidelity levels using textbook equations. Then implement F-16-specific subclasses that wire in F-16 specification parameters (aircraft type identifier, airfoil name, sweep angle, etc.) so the general equations are evaluated at the correct F-16 inputs. Abstract methods `drag_polar(state)` and `CLmax(state)` are the only ones the sizing loop and constraint analysis ever call.

Produce overlaid drag polar plots (CD vs CL) for L1, L2, L3 to visually confirm increasing fidelity.

---

## Files to Create

### Layer 1 — Generic (`src/`)

| File | Purpose |
|------|---------|
| `src/base/AerodynamicsBase.m` | Abstract base: `drag_polar(state)→struct(CD0,K1,K2)`, `CLmax(state)→scalar` |
| `src/disciplines/aerodynamics/AeroLevel1.m` | Cf from Raymer type table, K_LD lookup, CLmax from Roskam table |
| `src/disciplines/aerodynamics/AeroLevel2.m` | Cfe method (Cf from Re calculation), e_osw from Raymer formula, K2 from induced drag |
| `src/disciplines/aerodynamics/AeroLevel3.m` | Component drag buildup (Schlichting Cf_turb, form factors, wetted areas) |

### Layer 2 — F-16 specific (`examples/F16A/`)

| File | What it provides |
|------|-----------------|
| `examples/F16A/disciplines/aerodynamics/F16AeroLevel1.m` | `aircraft_type='air force fighter'` → Raymer Table 12.3 Cf; `design_type='jet fighter'` → K_LD=14 |
| `examples/F16A/disciplines/aerodynamics/F16AeroLevel2.m` | AR=3.0, Λ_LE=40° → e_osw via Raymer eq 12.49; no Brandt Cfe used |
| `examples/F16A/disciplines/aerodynamics/F16AeroLevel3.m` | Airfoil=NACA 64A-204, tc=0.04, x/c_max=0.40; F-16 component geometry from spec |

### Tests

| File | Tests |
|------|-------|
| `tests/disciplines/TestAeroLevels.m` | Generic classes: physical sanity, formula correctness |
| `tests/examples/F16A/TestF16AeroLevels.m` | F-16 classes: outputs in physically reasonable range |

---

## Design Notes

- `drag_polar(state)` returns a struct: `polar.CD0`, `polar.K1`, `polar.K2`.
- Geometry object is passed at construction; aerodynamics does not own geometry data.
- F-16 subclasses call `super()` with F-16-spec inputs; no equations are overridden.
- Inheritance chain: `F16AeroLevelN < AeroLevelN < AerodynamicsBase < handle`.

**Known two-value CD0 issue** (from `temp_AI/docs/disciplines/01_aerodynamics.md`):
At L1, the generic Cf type table gives a "clean airframe" CD0. The mission CD0 is higher because it includes interference drag, store drag, and inlet pressure recovery losses. These CDx increments are not part of L1; they emerge naturally at L3 component buildup. Tests acknowledge the difference and do not expect L1 to match L3.

**Brandt's calibrated values must not be used as inputs:**
- Do NOT set Cfe=0.005908 in F16AeroLevel2. Compute Cfe from Raymer's equivalent skin friction method.
- Do NOT set e_osw=0.9086 in F16AeroLevel2. Compute e_osw from Raymer eq 12.48 or 12.49 using F-16 AR and Λ_LE.
- These may differ from Brandt's values by 5–15%; that is expected and acceptable.

**What generic vs. F-16 subclass provides:**

| | AeroLevel1 (generic) | F16AeroLevel1 (F-16 spec inputs) |
|-|----------------------|----------------------------------|
| Cf source | `aircraft_type` arg → Raymer Table 12.3 | wires in `'air force fighter'` |
| K_LD source | `design_type` arg → Raymer eq 3.12 table | wires in `'jet fighter'` → K_LD=14 |
| CLmax source | `aircraft_type` arg → Roskam Table 3.1 | wires in F-16 aircraft type |

| | AeroLevel2 (generic) | F16AeroLevel2 (F-16 spec inputs) |
|-|----------------------|----------------------------------|
| e_osw | Raymer eq 12.48/12.49 from AR, Λ_LE args | wires in AR=3.0, Λ_LE=40° |
| Cfe | computed from generic Re-based formula | same computation, F-16 geometry |

| | AeroLevel3 (generic) | F16AeroLevel3 (F-16 spec inputs) |
|-|----------------------|----------------------------------|
| Airfoil | `airfoil_type` arg | wires in `'NACA 64A-204'`, tc=0.04 |
| Component geometry | geometry object arg | uses F16GeometryLevel3 |

---

## Equations & References

### AeroLevel1 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| Cf | type table; air force fighter: 0.0035 | Raymer 6th ed, Table 12.3 |
| CD0 | Cf × S_wet / S_ref | Raymer 6th ed, eq 12.3 |
| AR_wet | b² / S_wet | Raymer 6th ed, eq 3.11 |
| LD_max | K_LD × sqrt(AR_wet); jet fighter K_LD=14 | Raymer 6th ed, eq 3.12 |
| K2 | 1 / (4 × LD_max² × CD0) | derived from LD_max definition |
| K1 | 0 | symmetric polar assumption at L1 |
| CLmax | type table mean; Roskam Part I, Table 3.1 | Roskam Airplane Design Part I, Table 3.1 |

### AeroLevel2 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| Cfe | computed from reference Cf approach (confirm exact method at implementation) | Raymer 6th ed, Ch 12 |
| CD0 | Cfe × S_wet / S_ref | Raymer 6th ed |
| e_osw (Λ < 30°) | 1.78 × (1 − 0.045 × AR^0.68) − 0.64 | Raymer 6th ed, eq 12.48 |
| e_osw (Λ ≥ 30°) | 4.61 × (1 − 0.045 × AR^0.68) × cos(Λ_LE)^0.15 − 3.1 | Raymer 6th ed, eq 12.49 |
| K2 | 1 / (π × AR × e_osw) | standard induced drag |
| K1 | 0 | still assumed at L2 |

### AeroLevel3 (generic)
| Quantity | Equation | Reference |
|----------|----------|-----------|
| Cf_turb | 0.455 / (log10(Re)^2.58 × (1 + 0.144×M²)^0.65) | Raymer 6th ed, eq 12.27 (Schlichting) |
| R_cutoff (sub) | 38.21 × (L/k)^1.053 | Raymer 6th ed, eq 12.28 |
| FF_wing | (1 + 0.6/(x/c)_m × tc + 100 × tc^4) × (1.34 × M^0.18 × cos(Λ_m)^0.28) | Raymer 6th ed, eq 12.30 |
| FF_fus | 1 + 60/f³ + f/400; f = l/sqrt(4A_max/π) | Raymer 6th ed, eq 12.31 |
| CD0 | Σ(Cf_i × FF_i × Q_i × S_wet_i) / S_ref | Raymer 6th ed, eq 12.24 |
| K1 | −2 × K2 × CL_minD | Raymer 6th ed, eq 12.5 |
| CLmax | 0.9 × cl_max_airfoil × cos(Λ_qc) | Raymer 6th ed, eq 12.15 |

---

## Plot Deliverables

1. Drag polar (CD vs CL) for F16L1, F16L2, F16L3 at F-16 cruise condition — overlaid.
2. L3 drag breakdown: component contributions as a stacked bar.

---

## Tests

### Generic (`tests/disciplines/TestAeroLevels.m`)
| Test | Expected | Tolerance |
|------|----------|-----------|
| `drag_polar` returns struct with CD0, K1, K2 | fields present | exact |
| CD0 > 0, K2 > 0 | positive | exact |
| `CLmax` returns scalar > 0 | positive | exact |
| K2 = 1/(π AR e) at L2 | ±0.1% | analytical |
| L3 K1 = −2×K2×CL_minD | ±0.1% | analytical |

### F-16 specific (`tests/examples/F16A/TestF16AeroLevels.m`)
| Test | Level | Expected | Tolerance |
|------|-------|----------|-----------|
| CD0 in plausible range | F16L1 | 0.010–0.025 | Raymer range for fighters |
| CD0 in plausible range | F16L2 | 0.015–0.035 | wider range at L2 |
| K2 from Raymer eq 12.49 (AR=3, Λ_LE=40°) | F16L2 | consistent with equation | ±1% |
| K1 ≠ 0 (NACA 64A-204 is cambered) | F16L3 | K1 < 0 | sign correct |
| CLmax (clean, from Roskam table) | F16L1 | 1.2–1.8 | Roskam fighter range |
| CD0_L1 ≠ CD0_L3 (different methods differ) | — | not equal | — |

Note: We do not test against Brandt's CD0=0.0270 or K2=0.1160 as exact targets. These are Brandt's calibrated values; our textbook methods will give different numbers.

---

## Verification

```matlab
runtests('tests/disciplines/TestAeroLevels.m')
runtests('tests/examples/F16A/TestF16AeroLevels.m')
```
All tests must pass before Step 4 begins.
