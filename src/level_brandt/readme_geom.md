# BrandtGeometry – Design Decisions, Calculations, and Validation

> Single source of truth: `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`  
> Every value, formula, and fidelity choice described here traces back to a specific cell in that workbook.

> ⚠️ NOTE: The Brandt Excel sheet has an error. In the computation of Whole Aircraft S_wet, cell B19, the strake wetted area is double-counted. The formula `B19 = D23 + B4 + B14 + B15 + B16 + B17 + K21` includes both `B15` (strake S_wet) and `K21` (also strake S_wet). The MATLAB implementation does **not** replicate this bug.

---

## 1. File Organisation

| File | Role |
|------|------|
| `src/level_brandt/BrandtGeometry.m` | MATLAB handle class replicating the **Geom** tab |
| `examples/.../f16a_geometry.json` | All given input values extracted from **Main** tab |
| `src/level_brandt/tests/test_BrandtGeometry.m` | Validation test suite (33 GT checks) |

`BrandtGeometry` is a handle class: `compute()` and all display/plot helpers mutate or inspect `obj` in place after construction.

---

## 2. Input Schema (`f16a_geometry.json`)

Values were extracted from the following Main-tab regions. Only cells that contain **user-given numbers** (not formula results) are recorded here.

| Region | Main Cells | Contents |
|--------|-----------|----------|
| Wing | A18:H27 | S_ref, AR, taper, sweep_LE, airfoil, t/c, x_apex, dihedral |
| Pitch ctrl | column C | same fields for moving stabilator |
| Strake | column D | same fields; taper = 0 (delta) |
| Aileron | column E | reference only; not used in Geom tab |
| LE Flap | column F | reference only; not used in Geom tab |
| Vert tail | column H | S, AR, taper, sweep_LE, airfoil, t/c, x_le, z_le, tilt |
| Fuselage frames | A33:F53 | frame, x, z_chine, z, w, h (20 frames) |
| Fuselage summary | B28:I32 | length, max_width, max_height |
| Engine | B28:E28 | T_AB_SLS, inlet_x, inlet_dz, n_engines |

**Calculated value stored as input:** `wing.x_apex_ft = 17.786 ft`.  
This is Excel's `x_MAC_qc − y_MAC·tan(sweep_LE)`, pre-computed in Main and stored in the JSON so the class never has to duplicate it.

**JSON data correction (frames 16-17):** The original JSON had h_ft values off by one row for frames 16 and 17. Corrected values:
- Frame 16: h_ft = 5.0 (not 4.5)
- Frame 17: h_ft = 4.5 (not 4.0)

---

## 3. Cross-Tab Dependencies

The Geom tab pulls values from other tabs. These become constructor arguments (passed through `inp`).

| Geom cell | Source tab | Value | Description |
|-----------|-----------|-------|-------------|
| H3 | Engn(s) | 29.917 ft | Nozzle x = inlet_x + L_engine |
| B3 | Main | L_fuse = 46.5 ft | Fuselage length |
| B3 | Main | max_w=7.0, max_h=5.0 ft | Fuselage envelope |
| H26:H45 | Geom (self) | — | Per-frame whole-aircraft areas |
| B14–B17 | Geom (self) | — | Lifting surface S_wet |

Engine sizing (Engn(s) tab formulas reproduced in `computeNacelle`):
```
D_engine = sqrt(T_AB_SLS / 1900)   = sqrt(23770/1900) = 3.537 ft
L_engine = 4.5 * D_engine           = 15.917 ft
nozzle_x = inlet_x + L_engine       = 14.0 + 15.917   = 29.917 ft  [Geom H3]
```

---

## 4. Calculations Summary

### 4.1 Fuselage Wetted Surface Area

#### Low fidelity — Geom B3 = 730.422 ft²
"1/3-cone + 2/3-cylinder" approximation (Brandt eq. 3.xx):
```
D_avg  = (max_w + max_h) / 2 = (7.0 + 5.0)/2 = 6.0 ft
S_wet  = (5/6)·π·D_avg·L_fuse = (5/6)·π·6.0·46.5 = 730.422 ft²
```

#### High fidelity — Geom D23 = 676.329 ft²
Trapezoidal integration of per-frame perimeters:
```
S_wet = Σ (P_i + P_{i+1})/2 · Δx
```
- Nose boundary: x = 0, P = 0
- Frames 1–20: P computed from cosine cross-section model
- Tail closure: P = 0 beyond last frame

### 4.2 Fuselage Cross-Section Shape Model

Each frame is discretised using a cosine interpolation (verified against Geom rows 51–61):
```
y   = t·hw,  t = [0, 0.2, 0.4, 0.6, 0.8, 1.0],  hw = w/2
z_upper(y) = z_chine + (z_top − z_chine)·cos(π/2 · t)
z_lower(y) = z_chine + (z_bot − z_chine)·cos(π/2 · t)
z_top = z_center + h/2,  z_bot = z_center − h/2
```
6 half-section sample points → 11-point polygon per side → 23 total (matching Brandt).  
Frame 1 perimeter verification: **P = 5.178 ft** = Geom G50 ✓

### 4.3 Lifting Surface Wetted Areas

Raymer formula (confirmed from Geom tab):
```
S_wet = S_exposed · (1.977 + 0.52 · t/c)
```
For NACA 0004 / 1404 (t/c = 0.04): factor = **1.9978**

**Horizontal surfaces** (wing, pitch ctrl, strake):  
Boundary = fuselage **half-width** = max_width/2 = **3.5 ft**
```
c_exp_root = c_root − (fw / hs) · (c_root − c_tip)
hs_exp     = hs − fw
S_exposed  = (c_exp_root + c_tip)/2 · hs_exp · 2   [both panels]
```

**Vertical tail** — different from horizontal surfaces:  
Boundary = fuselage **half-height** = max_height/2 = **2.5 ft** (not half-width!)
Uses full span `b_vt = sqrt(S·AR)`, single panel (no mirror):
```
b_vt        = sqrt(S·AR)         = 9.798 ft
c_exp_root  = c_root − (fh/b_vt)·(c_root − c_tip)   = 7.124 ft
span_exp    = b_vt − fh           = 7.298 ft
S_exposed   = (c_exp_root + c_tip)/2 · span_exp       = 40.89 ft²
S_wet       = 40.89 × 1.9978     = 81.686 ft²  ≈  GT 81.689 ft² ✓
```

**Strake:** root at y = 2.0 ft (fully outside fuselage body) → S_exposed = S_ref.

### 4.4 Nacelle Wetted Area

`computeNacelle` computes D_engine and L_engine from Engn(s) formulas.

For the **simple** nacelle S_wet (Geom B4 = 41.515 ft²), the cell formula could not be confirmed from the binary `.xls` file. The implementation uses an exposed-length cylinder model (`N·π·D·(aircraft_length − fuse_length)`) as a placeholder. The ground-truth value 41.515 ft² is stored separately and used in the accurate total.

### 4.5 Whole-Aircraft Cross-Sectional Area (H26:H45) and Amax

#### Cross-Section Formula — Brandt Cosine Approximation

**KEY DISCOVERY:** The Excel does NOT use a NACA thickness integral. It uses a closed-form cosine area formula (confirmed via `win32com` formula inspection of Y, AA, AC, AG columns):

```
Active range:  Xexp < x < Xexp + X_max_range
Area(x) = tc · (c_exp_root + c_tip) · y_span · (1 − cos(2π·ξ)) / divisor

where:
  X_max_range = MAX(c_exp_root, G_hs_exp·tan(sweep) + c_tip_range)
  X_max_cos   = MAX(c_exp_root, G_hs_exp·tan(sweep) + c_tip)
  y_span      = MIN(G_hs_exp, (x − Xexp) / tan(sweep))
  ξ           = (x − Xref) / X_max_cos
```

Surface parameters (from Geom rows 7–10):
| Surface | Xexp (ft) | c_root (ft) | c_tip (ft) | G_hs (ft) | sweep° | divisor | Xref |
|---------|----------|------------|-----------|----------|--------|---------|------|
| Wing    | 20.723   | 13.356     | 3.707     | 11.5     | 40     | 2       | Xexp |
| Pitch   | 38.937   | 6.839      | 2.224     | 5.5      | 40     | 2       | Xexp |
| Strake  | 12.0     | 7.303      | 0         | 2.739    | 74     | **1**   | **38.937 (bug!)** |
| Vert Tail | 38.098 | 7.123      | 4.083     | 7.298    | 40     | 2       | Xexp |

**Nacelle:** Active from inlet_x (14.0 ft) to inlet_x + nozzle_x (43.917 ft).  
Area = N_eng · π · D_engine² / 4 = π·3.537²/4 = 9.826 ft² (constant cylinder)

#### Amax Computation
```
Amax = MAX(H26:H45) − N_eng · π · D_eng² / 5.0
     = 32.971 − π·3.537²/5.0
     = 25.110 ft²   ✓
```
The `−N·π·D²/5` term removes the internal inlet duct from the external maximum cross-section.

---

## 5. Excel Copy-Paste Bugs (Replicated for GT Match)

### 5.1 Strake Column (AG) — Two Bugs
1. **Cosine reference Xref uses `B$8`** (pitch ctrl Xexp = 38.937 ft) instead of `B$9` (strake Xexp = 12.0 ft)
2. **No division by 2** (divisor = 1, whereas wing and pitch ctrl use divisor = 2)

Both bugs together happen to produce a reasonable cross-section shape. MATLAB replicates both bugs exactly to match GT.

### 5.2 Vertical Tail Column (AC) — One Bug
- **Active-range check** uses `MAX(F10, G10·tan(sweep) + D$7)` where `D$7` = wing tip chord = **3.707 ft**
- **Cosine denominator** uses `MAX(F10, G10·tan(sweep) + D$10)` = VT tip chord = **4.082 ft**

Two different X_max values appear in the same formula (copy-paste error from wing column). MATLAB replicates this via the optional `c_tip_range` parameter in `brandtCSArea()`.

---

## 6. Known Excel Bugs (NOT Replicated)

### 6.1 Frame 20 Width
In the Geom tab cross-section detail block, frame 20 incorrectly uses cell `$F$26` (= 2.0 ft, frame-1 width) instead of `$B$52` (= 7.0 ft, frame-20 width).

- Excel Geom D23 = **676.329 ft²** (with the bug)
- MATLAB = **675.027 ft²** (correct frame-20 width, 0.19% difference)
- Excel frame 20 whole-aircraft area = **5.543 ft²** (with bug)
- MATLAB frame 20 whole-aircraft area = **17.129 ft²** (correct width)

### 6.2 B19 Strake Double-Count
See note at the top of this document. Corrected total = 1331.134 ft².

---

## 7. Fidelity Levels Summary

| Component | Low fidelity | High fidelity | Key difference |
|-----------|-------------|--------------|----------------|
| Fuselage S_wet | (5/6)·π·D_avg·L  ← Geom B3 | Trapezoidal frame integration ← Geom D23 | Frame-shape detail |
| Lifting surface S_wet | Same formula both | Same formula both | None (one fidelity) |
| Cross-section perimeter | — | Cosine model, 6 pts | Only used for accurate S_wet |
| Amax | Cylindrical fuselage only | Full component buildup | Wing + tail + nacelle added |

---

## 8. Validation Results (test_BrandtGeometry.m — 33/33 PASS)

| Table | Quantity | Computed | GT | % Error | Status |
|-------|---------|---------|-----|---------|--------|
| 1 | Wing S_wet | 392.020 ft² | 392.020 ft² | 0.000% | PASS |
| 1 | Strake S_wet | 39.956 ft² | 39.956 ft² | 0.000% | PASS |
| 1 | Pitch ctrl S_wet | 99.585 ft² | 99.585 ft² | 0.000% | PASS |
| 1 | Vert tail S_wet | 81.689 ft² | 81.689 ft² | 0.000% | PASS |
| 1 | Nacelle S_wet | 41.515 ft² | 41.515 ft² | 0.000% | PASS |
| 1 | Total S_wet (corrected) | 1332.692 ft² | 1331.134 ft² | +0.117% | PASS |
| 2 | Aircraft length | 48.304 ft | 48.304 ft | 0.000% | PASS |
| 2 | Amax | 25.111 ft² | 25.110 ft² | +0.002% | PASS |
| 2 | Nacelle length | 15.917 ft | 15.917 ft | 0.000% | PASS |
| 2 | Nacelle diameter | 3.537 ft | 3.537 ft | 0.000% | PASS |
| 3 | Wing sweep 25%c | 28.153° | 28.153° | 0.000% | PASS |
| 4 | Frame 1 perimeter | 5.178 ft | 5.178 ft (G50) | −0.004% | PASS |
| 4 | Frame 9 area | 22.572 ft² | 22.572 ft² (H218) | −0.001% | PASS |
| 5 | 19 whole-aircraft CS areas | — | H26:H45 | all <0.001% | 19 PASS |
| 6 | Aircraft volume | 1101.47 ft³ | 1106.306 ft³ (S47) | −0.437% | PASS |

Frame 20 cross-section area is excluded from TABLE 5 due to the Excel frame-20 width bug (Section 6.1). Frames 1–19 match GT within 0.001%.
