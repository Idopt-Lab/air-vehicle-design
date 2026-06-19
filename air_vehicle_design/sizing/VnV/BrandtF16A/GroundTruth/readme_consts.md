# BrandtConstraintAnalysis – Design Decisions, Calculations, and Validation

> Single source of truth: `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`  
> Every value, formula, and fidelity choice described here traces back to a specific cell in that workbook.

---

## 1. File Organisation

| File | Role |
|------|------|
| `src/level_brandt/BrandtConstraintAnalysis.m` | MATLAB handle class replicating the **Consts** tab |
| `examples/.../f16a_geometry.json` (`"constraints"` section) | Constraint condition inputs |
| `src/level_brandt/tests/test_BrandtConstraintAnalysis.m` | Validation test suite |

`BrandtConstraintAnalysis` receives pre-built `BrandtAerodynamics` and `BrandtEngine` handles.
Key Excel ranges cited below include `Consts!B23`, `Consts!AM:AU`, `Consts!E32:E33`, `Consts!K32:K33`, `Aero!H27:H29`, and `Main!B5`.

---

## 2. Architecture — Three-Tier Pattern

```
BrandtGeometry (analyzed first)
       │
       ▼
BrandtAerodynamics(geom) ──────────┐
       │  aero.analyze()           │
       │                           ├─→ BrandtConstraintAnalysis(aero, eng)
BrandtEngine() ────────────────────┘          │
       │  eng.analyze()                        │
                                       constr.analyze()  ← extract CLmax, β, μ
                                               │
                                       constr.run(WS_psf) ← evaluate all constraints
                                               │
                                       results struct  ← returned AND stored
```

**Why three tiers?**  
`analyze()` extracts fixed aircraft parameters — CLmax, β_perf, μ — that never change during sizing.  
`run(WS_psf)` is called once per sizing iteration to map the constraint envelope.

**Per-constraint methods** (`max_mach(WS)`, `cruise(WS)`, etc.) can also be called individually without calling `run()` first, for targeted evaluations.

---

## 3. Input Schema (JSON `"constraints"` section)

```
constraints/
├── beta_perf          = 0.89966696    Consts!B23:B30
├── conditions/
│   ├── max_mach        alt_ft, mach, n, pct_AB, Ps_fps, CDx
│   ├── cruise          "
│   ├── max_alt         "
│   ├── combat_turn_sub "
│   ├── combat_turn_sup "
│   └── ps_500          "
├── takeoff/
│   └── alt_ft, mach_liftoff, pct_AB, CDx, S_TO_ft
└── landing/
    └── CDx, S_land_ft
```

Additional parameters reused from the `"mission"` JSON section:
| Parameter | Value | Source |
|-----------|-------|--------|
| `CLmax_TO` | 1.2757 | `aero.CLmax_takeoff` ← `BrandtAerodynamics.analyze()` |
| `CLmax_land` | 1.4259 | `aero.CLmax_landing` ← `BrandtAerodynamics.analyze()` |
| `mu_rolling` | 0.03 | `mission.mu_rolling` ← Main!V12 |
| `mu_braking` | 0.50 | `mission.mu_braking` ← Main!V13 |
| `liftoff_factor` | 1.2 | `mission.liftoff_factor` ← Main!U12 (k_TO = V_TO/V_stall) |
| `approach_factor` | 1.3 | `mission.approach_factor` ← Main!U13 (k_app = V_app/V_stall) |

---

## 4. Cross-Tab Dependencies

| Excel source | Value used | MATLAB equivalent |
|---|---|---|
| Consts!B23 | β = 0.89966696 | `inp.constraints.beta_perf` |
| Consts!AM column | CD0 + CDx | `aero.run(mach).CD0 + cond.CDx` |
| Consts!AN column | K1 | `aero.run(mach).K1` |
| Consts!AQ column | V_fps = M × a | computed via `atmosisa` |
| Consts!AR column | q = ½ρV² | computed via `atmosisa` |
| Consts!AU column | α = thrust lapse | `eng.run(alt, mach, pct_AB/100).alpha_AB_ref` |
| Consts!D32 | k_TO = 1.2 | `inp.mission.liftoff_factor` |
| Consts!E32 | S_TO = 4000 ft | `inp.constraints.takeoff.S_TO_ft` |
| Consts!E33 | S_land = 4000 ft | `inp.constraints.landing.S_land_ft` |
| Consts!E33 (μ col) | μ_brake = 0.5 | `inp.mission.mu_braking` |
| Aero!H27 | CLmax_TO | `aero.CLmax_takeoff` |
| Aero!H29 | CLmax_land | `aero.CLmax_landing` |
| Main!B5 | S_ref = 300 ft² | `inp.wing.S_ref_ft2` |

---

## 5. Equations

### 5.1 Mattingly's Master Equation (Consts!K23–K30)

The general constraint equation from Mattingly *Elements of Gas Turbine Propulsion* (1996), Ch. 3, and Brandt *Introduction to Aeronautics* (2004), pp. 198–203:

```
T/W = (β/α) × [ q·CD0/(β·W/S) + K1·n²·β·(W/S)/q + Ps/V ]
```

| Symbol | Meaning | Unit | Source |
|--------|---------|------|--------|
| β | W/W_TO at constraint | — | Consts!B column |
| α | T/T_sl_AB = thrust lapse | — | `eng.run(alt, mach, AB_p).alpha_AB_ref` |
| q | dynamic pressure = ½ρV² | psf | `atmosisa` |
| CD0 | zero-lift drag + CDx | — | `aero.run(mach).CD0 + CDx` |
| K1 | induced drag factor | — | `aero.run(mach).K1` |
| n | load factor | — | Consts!C column |
| Ps | specific excess power | ft/s | Consts!F column |
| V | true airspeed = M·a | ft/s | `atmosisa` |
| W/S | wing loading | psf | independent variable |

**Why no K2 term?** The Consts tab uses the simplified symmetric parabolic polar `CD = CD0 + K1·CL²`. K2 (a camber/lift-offset term) is non-zero for the F-16A but is omitted in Brandt's constraint sizing chapter. This is consistent with standard Mattingly practice for performance constraint analysis.

**CD0 basis** (critical): The Consts tab sources CD0 from `Aero!C7 = Main!O4 = CDmin_sub ≈ 0.017 subsonic`. This is the **Cfe_tab basis**, NOT the `Cfe_eff` basis used in the Miss tab (CD0 ≈ 0.027). In MATLAB, `aero.run(mach).CD0` returns the CDmin_sub-based value (from `aero_at_mach()`), which matches. The Miss-tab `aero.CD0` (0.027) must **not** be used for constraints.

### 5.2 Constraint Conditions (Consts rows 22–30)

| Name | h [ft] | M | n | %AB | Ps [ft/s] | CDx | Row |
|------|--------|---|---|-----|-----------|-----|-----|
| max_mach | 36000 | 1.60 | 1.0 | 100 | 0 | 0.0 | 23 |
| cruise | 36000 | 0.87 | 1.0 | 0 | 0 | 0.0 | 24 |
| max_alt | 50000 | 0.87 | 1.0 | 100 | 0 | 0.0 | 25 |
| combat_turn_sub | 20000 | 0.87 | 4.5 | 100 | 0 | 0.0 | 26 |
| combat_turn_sup | 36000 | 1.40 | 1.4 | 100 | 0 | 0.0 | 27 |
| ps_500 | 10000 | 0.87 | 1.0 | 100 | 500 | 0.0 | 28 |

**Note:** Rows 28, 29, 30 in the Excel are identical (ps_500 condition, copy/paste artifact). Only one instance is implemented.

### 5.3 Takeoff Ground-Roll Constraint (Consts!K32)

```
T/W = k_TO²·β²·(W/S) / (α_AB·ρ_SL·CLmax_TO·g·S_TO)
    + 0.7·CD0_TO / (β·CLmax_TO)
    + μ_rolling
```

| Symbol | Value | Source |
|--------|-------|--------|
| k_TO = V_liftoff/V_stall | 1.2 | Main!U12 |
| β | 1.0 | takeoff at TOGW |
| α_AB | eng.run(0, 0.2, 1.0).alpha_AB_ref | Consts!AT32: Mach = 0.2 at liftoff |
| ρ_SL | 0.002377 slug/ft³ | atmosisa(0) |
| CLmax_TO | 1.2757 | Aero!H27 |
| g | 32.174 ft/s² | |
| S_TO | 4000 ft | Consts!E32 |
| CD0_TO | aero.run(0.2).CD0 + 0.035 | Consts!AM32: CDx = 0.035 (gear + flaps) |
| μ_rolling | 0.03 | Main!V12 |

The 0.7 factor is Brandt's approximation for the mean CD/CL ratio over the takeoff roll (Brandt eq. 6.16).

### 5.4 Landing Ground-Roll Constraint (Consts!K33) — Returns W/S, not T/W

```
(W/S)_max = S_land·ρ_SL·g·(μ_brake·CLmax_land + 0.83·CD0_land) / k_app²
```

| Symbol | Value | Source |
|--------|-------|--------|
| k_app = V_approach/V_stall | 1.3 | Main!U13 |
| S_land | 4000 ft | Consts!E33 |
| μ_brake | 0.5 | Main!V13 |
| CLmax_land | 1.4259 | Aero!H29 |
| CD0_land | aero.run(0.1).CD0 + 0.045 | CDx = 0.045 (gear + full flaps) |
| 0.83 | Brandt mean-speed correction for drag during rollout | Brandt eq. 6.27 |

This formula returns a **maximum allowable W/S** (vertical line on constraint diagram). The F-16A result of ≈138 psf is non-governing — the design point is driven by aerodynamic performance constraints.

---

## 6. Calculation Flowchart

```
JSON inputs (constraints section)
    beta_perf, conditions{}, takeoff{}, landing{}
           │
    BrandtConstraintAnalysis.analyze()
           │
    ┌──────────────────────────────────────────────┐
    │  For each performance constraint:             │
    │    atmosisa(alt_m) → ρ, a                     │
    │    V = M × a                                  │
    │    q = ½ρV²                                   │
    │    aero.run(M) → CD0 (CDmin basis), K1        │
    │    eng.run(alt, M, pct_AB/100) → α_AB_ref     │
    │    masterConstraint_(WS, cond) → TW           │
    │      = (β/α)×[q·CD0/(β·WS) + K1·n²·β·WS/q + Ps/V] │
    └──────────────────────────────────────────────┘
           │
    ┌──────────────────────────────────────────────┐
    │  Takeoff:                                     │
    │    atmosisa(0) → ρ_SL                        │
    │    eng.run(0, 0.2, 1.0) → α_TO               │
    │    aero.run(0.2) → CD0_TO                    │
    │    TW = k_TO²·β²·WS/(α·ρ·CLmax·g·S_TO)      │
    │       + 0.7·CD0_TO/(β·CLmax_TO) + μ          │
    └──────────────────────────────────────────────┘
           │
    ┌──────────────────────────────────────────────┐
    │  Landing:                                     │
    │    atmosisa(0) → ρ_SL                        │
    │    aero.run(0.1) → CD0_land                  │
    │    WS_max = S_land·ρ·g·(μ·CLmax + 0.83·CD0)/k² │
    └──────────────────────────────────────────────┘
           │
    TW_envelope = max(all constraints at each WS)
           │
    WS_opt = argmin(TW_envelope) subject to WS <= WS_land_max
```

---

## 7. Discrepancies and Known Deviations

### 7.1 Atmosphere Model
**Excel** uses Brandt's polynomial atmosphere (same as in `BrandtEngine`). **MATLAB** uses `atmosisa`. The resulting deviation in ρ and a is ≤2% across the altitude range used. This propagates to ≤2% on q, and therefore ≤2% on T/W — within the documented 2% audit ceiling for the affected supersonic cases.

### 7.2 Aerodynamics
`aero.run(mach).CD0` is computed analytically in `BrandtAerodynamics.aero_at_mach()`. Excel reads tabulated values from Aero!C6:C10 interpolated at condition Mach numbers. The deviation is <1% for subsonic and <2% for supersonic conditions.

### 7.3 Beta Value
β = 0.89966696 is sourced from Consts!B23, which in the Excel links back to Miss-tab weight fractions at the start of the combat phase. MATLAB uses this as a constant from JSON. This is an appropriate simplification; the user can override it by editing the JSON.

### 7.4 CD0 Basis (CRITICAL)
The Consts tab uses the Aero-tab CDmin_sub basis (≈0.017 subsonic), NOT the Miss-tab Cfe_eff basis (≈0.027). Using `aero.run(mach).CD0` is correct for both (it returns the CDmin_sub basis via `aero_at_mach()`). Do NOT use `aero.CD0` (the Mission-tab value) for constraint analysis.

### 7.5 K2 Omission
The Consts tab does not use K2 in the master equation. K2 is non-zero for the F-16A (camber term) but Brandt follows Mattingly in omitting it at the constraint sizing level. The simplified polar `CD = CD0 + K1·CL²` is used.

---

## 8. Validation Targets

### 8.1 T/W Ground Truth at Selected W/S Values (Consts tab)

| W/S [psf] | max_mach | cruise | max_alt | cbt_sub | ps_500 | takeoff |
|-----------|----------|--------|---------|---------|--------|---------|
| 20 | 2.9012 | 1.2912 | 0.7274 | 0.7500 | 1.3323 | 0.1357 |
| 27 | 2.1533 | 0.9831 | 0.5911 | 0.6216 | 1.1344 | 0.1628 |
| 34 | 1.7144 | 0.8081 | 0.5233 | 0.5617 | 1.0184 | 0.1898 |
| 41 | 1.4262 | 0.6981 | 0.4888 | 0.5352 | 0.9424 | 0.2168 |
| 48 | 1.2228 | 0.6247 | 0.4732 | 0.5274 | 0.8888 | 0.2438 |
| 55 | 1.0718 | 0.5738 | 0.4692 | 0.5314 | 0.8491 | 0.2709 |
| 62 | 0.9555 | 0.5379 | 0.4729 | 0.5430 | 0.8186 | 0.2979 |
| 69 | 0.8632 | 0.5124 | 0.4819 | 0.5599 | 0.7945 | 0.3249 |

- Landing W/S_max = **138.4794 psf** (Consts!K33)
- Optimal design point (Size&Opt sheet): **W/S = 104.59 psf, T/W = 0.7576**

### 8.2 Test Tolerances

| Constraint type | Tolerance | Reason |
|---|---|---|
| Subsonic constraints (cruise, max_alt, combat_turn_sub, ps_500) | ±1% RelTol | atmosisa vs Brandt poly |
| Supersonic constraints (max_mach, combat_turn_sup) | ±2% RelTol | documented compressibility/model exception |
| Takeoff T/W | ±1% RelTol | atmosisa only (SL) |
| Landing W/S_max | ±1% RelTol | atmosisa only (SL) |

---

## 9. State-Vector / Control-Vector Convention

As documented in `level-brandt.md` and the class header:

```matlab
% State vector convention (12×1 rigid-body flight dynamics):
%   state_vector = [x, y, z, u, v, w, φ, θ, ψ, p, q, r]ᵀ
%
% For BrandtConstraintAnalysis at level_brandt fidelity:
%   state = [altitude_ft, mach]  (reduced representation)
%   control = [pct_AB]           (afterburner percentage 0–100)
```

In `BrandtConstraintAnalysis`, the state and control do not form explicit vectors — the constraint conditions are read directly from the JSON `conditions` struct, which encodes state and control per constraint.
