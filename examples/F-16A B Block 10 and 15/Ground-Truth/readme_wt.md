# BrandtWeight – Design Decisions, Calculations, and Validation

> Single source of truth: `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`  
> Every value, formula, and fidelity choice described here traces back to a specific cell in that workbook.

---

## 1. File Organisation

| File | Role |
|------|------|
| `src/level_brandt/BrandtWeight.m` | MATLAB handle class replicating the **Wt** tab, rows A14:B38 |
| `examples/.../f16a_geometry.json` | Weight inputs extracted from **Main** tab (weight section) |
| `src/level_brandt/tests/test_BrandtWeight.m` | Validation test suite (28 GT checks) |

`BrandtWeight` is a handle class that depends on `BrandtGeometry` (passed as constructor argument, same pattern as `BrandtAerodynamics`).
Key cross-referenced cells below include `Main!D18`, `Geom!B3`, `Geom!B4`, `Wt!B9`, `Wt!B12`, `Wt!B23`, and `Wt!G9`.

---

## 2. Architecture — Three-Tier Pattern

```
BrandtGeometry (must be analyzed first)
       │
       ▼
BrandtWeight(geom)          ← constructor: stores geom & inp, NaN all properties
       │
       ▼
wt.analyze()                ← geometry-dependent structural weights (call once)
       │
       ▼
wt.run(W_TO_lb)             ← W_TO-dependent weights, OEW, fuel  (call many times)
       │
       ▼
wt_results struct            ← all 21 weight properties returned AND stored
```

**Why three tiers?**  
`analyze()` outputs depend only on geometry — they never change during a sizing iteration.
`run(W_TO_lb)` is called repeatedly with successive W_TO guesses in the sizing loop.
The split avoids re-computing structural weights on every sizing iteration.

---

## 3. Input Schema (JSON `weight` section)

Added to `f16a_geometry.json` under key `"weight"`. All values come from the **Main** tab.

| JSON Field | Main Cell | Value | Description |
|------------|-----------|-------|-------------|
| `perm_payload_lb` | Main!O16 | 700 lb | Permanent (non-expended) payload |
| `exp_payload_lb` | Main!O17 | 4400 lb | Expendable payload (weapons, stores) |
| `n_design_load` | Main!Q27 | 9 | Ultimate design load factor (n_ult) |
| `weight_scale_pct` | Main!O27 | 100 | Global weight scale (%) — 100 = no scaling |
| `n_vert_tails` | Main!G31 (inferred) | 1 | Number of vertical tails (twin-VT penalty) |

**Cross-references used in weight calculations (not re-stored — read from `geom.inp` or `geom`):**

| Source | JSON path / `geom` property | Value | Used for |
|--------|----------------------------|-------|----------|
| Main!B5 → `wing.S_ref_ft2` | `inp.wing.S_ref_ft2` | 300 ft² | Wing weight, controls weight |
| Main!B6 → `wing.AR` | `inp.wing.AR` | 3.0 | Wing weight |
| Main!B7 → `wing.sweep_LE_deg` | `inp.wing.sweep_LE_deg` | 40° | Wing weight |
| Main!B8 → `wing.taper` | `inp.wing.taper` | 0.2275 | Wing weight |
| Main!B9 → `wing.tc_ratio` | `inp.wing.tc_ratio` | 0.04 | Wing weight |
| Main!C18 → `pitch_ctrl.S_ft2` | `inp.pitch_ctrl.S_ft2` | 108 ft² | Pitch control weight |
| Main!H18 → `vert_tail.S_ft2` | `inp.vert_tail.S_ft2` | 60 ft² | Vertical tail weight |
| Main!D18 → `strake.S_ft2` | `inp.strake.S_ft2` | 20 ft² | Strake weight |
| Main!B32 → `fuselage.length_ft` | `inp.fuselage.length_ft` | 46.5 ft | Fuselage weight (fineness check) |
| Main!C32 → `fuselage.max_width_ft` | `inp.fuselage.max_width_ft` | 7.0 ft | Fuselage weight (fineness check) |
| Main!D32 → `fuselage.max_height_ft` | `inp.fuselage.max_height_ft` | 5.0 ft | Fuselage weight (fineness check) |
| Main!E28 → `engine.T_AB_SLS_lb` | `inp.engine.T_AB_SLS_lb` | 23770 lb | Engine weight |
| Geom!B3 → computed | `geom.S_wet_fuse_simple_ft2` | 730.422 ft² | Fuselage weight |
| Geom!B4 → computed | `geom.S_wet_nacelle_gt_ft2` | ~41.37 ft² | Nacelle weight |
| Main!F18 → computed | `geom.le_flap.S_ft2` | 21.314 ft² | Controls weight (LE flap term) |

---

## 4. Cross-Tab Dependencies

The Wt tab pulls from Main and Geom. The table below maps every significant dependency.

| Wt Cell | Depends On | Tab | Notes |
|---------|-----------|-----|-------|
| B3 (W_TO) | External | — | Input to `run(W_TO_lb)` — NOT from JSON |
| B4 (perm_payload) | Main!O16 | Main | 700 lb |
| B5 (exp_payload) | Main!O17 | Main | 4400 lb |
| C9 (W_wing) | B5, AR, taper, sweep, t/c, Q27 | Main | Wing geometry + load factor |
| D9 (W_fuse) | B3, C32, D32 from Main; Geom!B3 | Main/Geom | Fuselage S_wet (simple model) |
| E9 (W_pitch) | C18 | Main | Stabilator reference area |
| F9 (W_vert) | H18 | Main | Vertical tail reference area |
| G9 (W_nac) | Geom!B4 | Geom | Nacelle effective area (see §5.6) |
| H9 (W_strake) | D18 | Main | Strake reference area |
| B11 (W_engine) | E28 | Main | AB SLS thrust → engine mass estimate |
| B25 (W_ctrl) | B3, F18, B5 | Main | Two-term: W_TO fraction + LE flap |
| O27 (scale) | Main!O27 | Main | Global weight scaling = 100% |
| Q27 (n_ult) | Main!Q27 | Main | Design limit load × 1.5 safety = 9 |

---

## 5. Calculations

### 5.1 Weight Factors (Wt row 7)

All structural components use a "wetted-area times density" model. The weight factors (lb/ft²) are:

| Component | Factor | Wt Cell | Notes |
|-----------|--------|---------|-------|
| Wing | k_wing = 6.75 lb/ft² | Wt!C7 | |
| Fuselage | k_fuse = 5.0 lb/ft² | Wt!D7 | |
| Pitch control | k_pitch = 6.0 lb/ft² | Wt!E7 | |
| Vertical tail | k_vert = 6.0 lb/ft² | Wt!F7 | |
| Nacelles | k_nac = 4.5 lb/ft² | Wt!G7 | |
| Strakes | k_strake = 4.5 lb/ft² | Wt!H7 | |

### 5.2 Wing Weight (Wt C9)

```
W_wing = S_ref × (k_wing/7) × 0.04 × n_ult^0.2 × AR^1.8 × √(1+λ) / (t_c^0.7 × cos(Λ_LE)) × scale
```

| Symbol | Value | Source |
|--------|-------|--------|
| S_ref | 300 ft² | Main!B5 |
| k_wing | 6.75 lb/ft² | Wt!C7 |
| n_ult | 9 | Main!Q27 |
| AR | 3.0 | Main!B6 |
| λ (taper) | 0.2275 | Main!B8 |
| t/c | 0.04 | Main!B9 |
| Λ_LE | 40° | Main!B7 |
| scale | 1.0 | Main!O27/100 |

Computed: **1785.95 lb** (GT) | MATLAB: ~1787 lb | Error: ~0.06%

**Assumption:** Wing loiter correction factor = MAX(1, (CL_max_clean − CL_cruise)/(CD0 × 8)) = 1 for a fighter aircraft (high aerodynamic efficiency). This factor is included in the formula but evaluates to 1, so it is omitted from the expression above.

### 5.3 Fuselage Weight (Wt D9)

```
W_fuse = k_fuse × S_wet_fuse × MAX(1, (L / √(w×h)) / 19) × scale
```

| Symbol | Value | Source |
|--------|-------|--------|
| k_fuse | 5.0 lb/ft² | Wt!D7 |
| S_wet_fuse | 730.422 ft² | Geom!B3 = `geom.S_wet_fuse_simple_ft2` |
| L | 46.5 ft | Main!B32 |
| w | 7.0 ft | Main!C32 |
| h | 5.0 ft | Main!D32 |

Fineness ratio: L/√(w×h) = 46.5/√(35) = 7.86 → 7.86/19 = 0.414 → MAX(1, 0.414) = **1**

The F-16A is not fineness-limited (fuselage is fat relative to its length), so the correction = 1 always.

Computed: **3652.11 lb** (GT) | MATLAB: exact match

### 5.4 Pitch Control (Stabilator) Weight (Wt E9)

```
W_pitch = k_pitch × S_pitch × scale = 6.0 × 108 = 648.00 lb
```

**Exact.** Stabilator reference area S_pitch = 108 ft² from Main!C18.

### 5.5 Vertical Tail Weight (Wt F9)

```
W_vert = k_vert × S_vert × scale × MAX(1 + I_twin, 1)
```

Where `I_twin = 1` for twin-VT configuration, `I_twin = 0` for single VT.

F-16A has a **single** vertical tail → I_twin = 0 → MAX(1, 1) = 1

```
W_vert = 6.0 × 60 = 360.00 lb   (exact)
```

### 5.6 Nacelle Weight (Wt G9)

```
W_nacelles = k_nac × S_nac_eff × scale
```

`S_nac_eff` is computed by **BrandtGeometry** as `S_wet_nacelle_gt_ft2` (Geom!B4).

**Geom!B4 formula (decoded via Excel COM):**
```
B4 = IF(n_eng × D_nac / 2 + nozzle_offset > half_fuse_w,
        n × D_nac × L_nac × 3.1516 × E_aft,          % exposed case
        n × D_nac × L_nac × 3.1516 × E_aft / 2)      % half-buried case
```

Where:
```
C475 = D_nac = sqrt(T_AB_SLS / 1900)                     = 3.537 ft
D475 = L_nac = 4.5 × D_nac                               = 15.917 ft
E475 = IF(n_eng = 1, inlet_x / (inlet_x + L_nac), 1)     = 14/(14+15.917) = 0.4680
     (E_aft = fraction of nacelle aft of inlet face)
```

The F-16A engine is centerline (G31 = 0 lateral offset) → always takes the `/2` (half-buried) branch.
Excel uses `3.1516` (not π = 3.14159); MATLAB uses `pi` → ~0.37% area difference → ~0.37% weight difference.

Computed: GT = 186.82 lb | MATLAB ≈ 186.12 lb | Error: ~0.37% (within 1% tolerance)

**Note:** `S_wet_nacelle_gt_ft2` is an **area (ft²)**, not a volume. The naming suffix `_gt` means "ground truth" (previously hardcoded; now computed from formula). The multiplication by `k_nac = 4.5 lb/ft²` gives weight.

### 5.7 Strake Weight (Wt H9)

```
W_strakes = k_strake × S_strakes × scale = 4.5 × 20 = 90.00 lb   (exact)
```

### 5.8 Structural Total (Wt B9)

```
W_structure = W_wing + W_fuse + W_pitch + W_vert + W_nacelles + W_strakes
```

GT: 1785.95 + 3652.11 + 648.00 + 360.00 + 186.82 + 90.00 = **6722.87 lb**

### 5.9 Engine Weight (Wt B11 / B22)

```
W_engine = 0.199 × T_sl_AB = 0.199 × 23770 = 4730.23 lb
```

This is the **installed engine weight** formula for afterburning turbofan/turbojet engines (Brandt 1997, Table 6.2). Factor 0.199 lb per lb-thrust is for AB engines.

### 5.10 Inlet Duct Weight (Wt B24)

```
W_inlet_duct = 3.9 × W_nacelles
```

Factor 3.9 comes from Wt!F24. This accounts for inlet ducting that routes air from the chin inlet to the engine — a significant structure for the F-16 with its long S-duct.

### 5.11 Landing Gear (Wt B23)

```
W_gear = 0.034 × W_TO
```

### 5.12 Flight Controls (Wt B25) — Two-Term Formula

```
W_ctrl = 0.012 × W_TO + (S_LE_flap / S_wing) × k_wing × 200
```

| Term | Value at W_TO=31377 | Notes |
|------|--------------------|-|
| 0.012 × 31377 | 376.52 lb | Base controls fraction |
| (21.314/300) × 6.75 × 200 | 95.92 lb | LE flap actuation structure |
| Total | 472.44 lb | Wt!B25 = 472.44 ✓ |

`S_LE_flap` = 21.314 ft² = `geom.le_flap.S_ft2` (computed by BrandtGeometry from Main!F18 geometry). The constant 200 (ft²/ft²) is an empirical scaling for LE flap structure weight relative to wing loading.

### 5.13 Electrical, Hydraulics, ECS (Wt B26–B28)

```
W_elec     = 0.017  × W_TO
W_hyd      = 0.0117 × W_TO
W_ECS      = 0.0115 × W_TO
```

All are fixed fractions of takeoff weight (Brandt 1997, Table 6.4).

### 5.14 Other Structure (Wt B29)

```
W_other = 0.30 × W_structure
```

Note: This is a fraction of **structural weight** (`W_structure`), not of `W_TO`. It covers miscellaneous structure items not individually sized.

### 5.15 Avionics (Wt B30)

```
W_avionics = 0.081 × W_TO
```

### 5.16 Armament Weight (Wt B31)

```
W_armament = 0.10 × W_exp_payload = 0.10 × 4400 = 440.00 lb
```

This represents the structural weight of weapons stations, pylons, and integration hardware (not the weapons themselves, which are part of `exp_payload`).

---

## 6. Summary Weight Chain

```
W_airframe = W_structure
           + W_gear + W_inlet_duct + W_ctrl + W_elec
           + W_hyd + W_ECS + W_other + W_avionics + W_armament
                                            (Wt B10 = B9 + SUM(B23:B31))

W_empty    = W_airframe + W_engine          (Wt B12 = B10 + B11)
                                            NOTE: engine is NOT in airframe

W_fuel     = W_TO − perm_payload − exp_payload − W_empty
                                            (Wt B6 = B3 − B4 − B5 − B12)
```

> **Critical note:** `W_engine` is **excluded** from `W_airframe` (Wt B10) and added separately to produce `W_empty` (Wt B12). This matches the Excel formula exactly. Mixing these would overstate airframe and understate OEW.

---

## 7. Informational Table: Structural Weight Factors (Wt I7:N17)

The following table is reproduced from the Excel workbook (Wt!I7:N17). It documents the design assumptions and weight factor ranges for structural components.

| Component | k (lb/ft²) | Notes |
|-----------|-----------|-------|
| Wing | 6.75 | Fighter/trainer nominal; scales with n_ult^0.2 × AR^1.8 |
| Fuselage | 5.0 | Uses wetted area (simple model); fineness correction for slender bodies |
| Pitch control | 6.0 | Moving surface (stabilator) — higher than fixed tail |
| Vertical tail | 6.0 | Single VT; twin penalty multiplies by 2 |
| Nacelles | 4.5 | Half-buried (centerline); exposed nacelle uses full area |
| Strakes | 4.5 | Low-AR delta surface |

---

## 8. Informational Table: Detailed Component Breakdown (Wt I21:N37)

This section reproduces the per-category factor table from the Excel (Wt!I21:N37) for reference.

| Category | Fraction / Factor | Base | W at GT (lb) | Wt Cell |
|----------|-------------------|------|-------------|---------|
| Wing structure | 6.75 lb/ft² × f(AR, n_ult, t/c, sweep) | S_ref | 1785.95 | C9 |
| Fuselage structure | 5.0 lb/ft² × fineness_factor | S_wet_fuse | 3652.11 | D9 |
| Pitch control | 6.0 lb/ft² | S_pitch | 648.00 | E9 |
| Vertical tail | 6.0 lb/ft² × twin_factor | S_vert | 360.00 | F9 |
| Nacelles | 4.5 lb/ft² | S_nac_eff | 186.82 | G9 |
| Strakes | 4.5 lb/ft² | S_strakes | 90.00 | H9 |
| **Structural subtotal** | | | **6722.87** | B9 |
| Engine | 0.199 × T_sl_AB | T_AB_SLS | 4730.23 | B11/B22 |
| Landing gear | 0.034 × W_TO | W_TO | 1066.82 | B23 |
| Inlet duct | 3.9 × W_nacelles | W_nac | 728.60 | B24 |
| Flight controls | 0.012 × W_TO + LE_flap_term | W_TO | 472.44 | B25 |
| Electrical | 0.017 × W_TO | W_TO | 533.41 | B26 |
| Hydraulics | 0.0117 × W_TO | W_TO | 367.11 | B27 |
| ECS | 0.0115 × W_TO | W_TO | 360.84 | B28 |
| Other structure | 0.30 × W_structure | W_structure | 2016.86 | B29 |
| Avionics | 0.081 × W_TO | W_TO | 2541.54 | B30 |
| Armament support | 0.10 × exp_payload | W_exp | 440.00 | B31 |
| **Airframe (W10)** | | | **15250.47** | B10 |
| **OEW = W_airframe + W_engine** | | | **19980.70** | B12 |
| Permanent payload | given | — | 700.00 | B4 |
| Expendable payload | given | — | 4400.00 | B5 |
| **Fuel** | W_TO − payload − OEW | | **6296.30** | B6 |
| **TOGW = W_TO** | | | **31377.00** | B3 |

---

## 9. Calculation Flowchart

```
JSON inputs (wing, fuse, strake, pitch_ctrl, vert_tail, engine, weight)
       │
       ▼
BrandtGeometry.analyze()
   ├─► S_wet_fuse_simple_ft2  (730.42 ft²)   ← fuselage weight
   ├─► S_wet_nacelle_gt_ft2   (~41.37 ft²)   ← nacelle weight
   └─► le_flap.S_ft2          (21.314 ft²)   ← controls weight
       │
       ▼
BrandtWeight.analyze()        [geometry-only, call once]
   ├─► W_wing_lb              (≈1787 lb)
   ├─► W_fuse_lb              (3652 lb)
   ├─► W_pitch_lb             (648 lb)
   ├─► W_vert_lb              (360 lb)
   ├─► W_nacelles_lb          (≈186 lb)
   ├─► W_strakes_lb           (90 lb)
   ├─► W_structure_lb         (≈6723 lb)   ← sum of above
   ├─► W_engine_lb            (4730 lb)
   └─► W_inlet_duct_lb        (≈726 lb)    ← 3.9 × W_nacelles
       │
       ▼
BrandtWeight.run(W_TO_lb)     [call per sizing iteration]
   ├─► W_gear_lb              (0.034 × W_TO)
   ├─► W_ctrl_lb              (0.012 × W_TO + LE_flap_term)
   ├─► W_elec_lb              (0.017 × W_TO)
   ├─► W_hyd_lb               (0.0117 × W_TO)
   ├─► W_ECS_lb               (0.0115 × W_TO)
   ├─► W_other_lb             (0.30 × W_structure)
   ├─► W_avionics_lb          (0.081 × W_TO)
   ├─► W_armament_lb          (0.10 × exp_payload)
   ├─► W_airframe_lb          ← structure + gear + inlet + systems
   ├─► W_empty_lb             ← W_airframe + W_engine   (OEW)
   └─► W_fuel_lb              ← W_TO − payload − OEW
       │
       ▼
Returns wt_results struct (21 fields)
Also stores all values as object properties (dual-return contract)
```

---

## 10. Discrepancies from Ground Truth

| Component | GT (lb) | MATLAB (lb) | Error | Root Cause |
|-----------|---------|-------------|-------|-----------|
| W_wing | 1785.95 | ~1787 | +0.06% | Intermediate rounding in formula |
| W_fuse | 3652.11 | 3652.11 | 0% | Exact |
| W_pitch | 648.00 | 648.00 | 0% | Exact |
| W_vert | 360.00 | 360.00 | 0% | Exact |
| W_nacelles | 186.82 | ~186.12 | −0.37% | MATLAB uses π; Excel uses 3.1516 |
| W_strakes | 90.00 | 90.00 | 0% | Exact |
| W_engine | 4730.23 | 4730.23 | 0% | Exact |
| W_inlet_duct | 728.60 | ~726.87 | −0.37% | Propagated from W_nacelles error |
| W_gear | 1066.82 | 1066.82 | 0% | Exact |
| W_ctrl | 472.44 | 472.43 | <0.01% | Floating-point |
| W_other | 2016.86 | ~2016.82 | <0.01% | Propagated from W_nacelles error |
| **W_airframe** | 15250.47 | ~15249 | ~0.01% | Accumulated from above |
| **OEW** | 19980.70 | ~19979 | ~0.01% | Accumulated from above |
| **W_fuel** | 6296.30 | ~6298 | ~0.03% | Inverse of OEW error |

All deviations are within the 1% test tolerance. The π vs 3.1516 discrepancy in nacelle area is the documented exception for `Geom!B4`/`Wt!G9`, and the resulting `Wt!B12` effect stays within the audit ceiling.

---

## 11. Validation

Run `runtests('test_BrandtWeight')` from the `src/level_brandt/tests/` folder.

**Test suite summary (28 tests, W_TO = 31377 lb):**

| Group | Tests | What's checked |
|-------|-------|---------------|
| Constructor / setup | 3 | no-arg constructor, analyze-before-run guard, result struct fields |
| Structural components | 10 | W_wing, W_fuse, W_pitch, W_vert, W_nacelles, W_strakes, W_structure, W_engine, W_inlet_duct, structural consistency |
| W_TO-dependent systems | 8 | W_gear, W_ctrl, W_elec, W_hyd, W_ECS, W_other, W_avionics, W_armament |
| Summary weights | 7 | W_airframe, OEW, W_fuel, airframe consistency, OEW consistency, fuel consistency, W_TO closure check |
| Iteration / properties | 3 | run() multiple times, fuel positive, properties match returned struct |

**Tolerance policy:**
- Physics-computed weights (W_wing, W_fuse, W_nacelles): 1% RelTol
- Algebraically exact values (W_pitch, W_vert, W_strakes, W_gear, W_armament): 0.1% RelTol
- Internal consistency checks (W_structure = sum, OEW = airframe + engine, etc.): 1e-6 AbsTol
- Documented nacelle-area exception (`Geom!B4`): up to 2% for area/weight closure

---

## 12. Assumptions Summary

| Assumption | Value | Justification |
|-----------|-------|--------------|
| Wing loiter factor | 1.0 | Fighter; MAX(1, (CL_max − CL_cr)/(8 × CD0)) ≤ 1 |
| Fuselage fineness correction | 1.0 | F-16 L/√(wh) = 7.86 < 19; MAX(1, 7.86/19) = 1 |
| Twin-VT penalty | ×1 (none) | Single vertical tail (n_vert_tails = 1) |
| Nacelle burial | Half-buried (÷2) | Centerline engine; G31 lateral offset = 0 |
| Engine weight model | 0.199 × T_sl_AB | Brandt Table 6.2 — afterburning turbofan/turbojet |
| Weight scale | 100% | Main!O27 = 100; no scaling applied |
| Inlet duct factor | 3.9 | Empirical; Wt!F24 = 3.9 |
| Controls LE-flap term | (S_LE/S_wing) × 6.75 × 200 | Wt!B25 — structural cost of LE flap actuation |
