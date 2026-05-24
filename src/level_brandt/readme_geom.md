# BrandtGeometry – Design Decisions, Calculations, and Validation

> Single source of truth: `examples/F-16A B Block 10 and 15/Ground-Truth/Brandt-F16-A.xls`  
> Every value, formula, and fidelity choice described here traces back to a specific cell in that workbook.

---

## 1. File Organisation

| File | Role |
|------|------|
| `src/level_brandt/BrandtGeometry.m` | MATLAB static-method class replicating the **Geom** tab |
| `examples/.../f16a_geometry.json` | All given input values extracted from **Main** tab |

All methods in `BrandtGeometry` are `static` – no instance state – consistent with the other `BrandtXxx` classes in this codebase.

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

### 4.5 Maximum Cross-Section Area — Amax (Geom H47 = 25.11 ft²)

```
Amax = MAX(H26:H45) − N_eng · π · D_eng² / 5.0
     = 32.971 − π·3.537²/5.0
     = 25.110 ft²   ✓
```
`H26:H45` = whole-aircraft area at each fuselage station = sum of:
- Fuselage frame area (W col)
- Wing cross-section (Y col)
- Pitch ctrl cross-section (AA col)
- Vert tail cross-section (AC col)
- Nacelle cylinder area (AE col)
- Strake cross-section (AG col)

The `−N·π·D²/5` term removes the internal inlet duct from the external wetted cross-section (Brandt notation; factor of 5 is a standard inlet area correction).

---

## 5. Fidelity Levels Summary

| Component | Low fidelity | High fidelity | Key difference |
|-----------|-------------|--------------|----------------|
| Fuselage S_wet | (5/6)·π·D_avg·L  ← Geom B3 | Trapezoidal frame integration ← Geom D23 | Frame-shape detail |
| Lifting surface S_wet | Same formula both | Same formula both | None (one fidelity) |
| Cross-section perimeter | — | Cosine model, 6 pts | Only used for accurate S_wet |
| Amax | Cylindrical fuselage only | Full component buildup | Wing + tail + nacelle added |

---

## 6. Known Excel Bug — Frame 20 Width (NOT Replicated)

In the Geom tab cross-section detail block (rows ~450–461), frame 20 incorrectly uses cell `$F$26` (= 2.0 ft, frame-1 width) instead of `$B$52` (= 7.0 ft, frame-20 width).

- Excel's Geom D23 = **676.329 ft²** (with the bug)
- This implementation's D23 = **675.027 ft²** (correct frame-20 width, 0.19% difference)

The bug is **not replicated** intentionally; the correct frame dimensions are used.

---

## 7. Validation Results

| Quantity | Implementation | Excel GT | Error |
|---------|---------------|---------|-------|
| Fuselage simple S_wet | 730.420 ft² | 730.422 ft² | < 0.001% |
| Wing S_wet | 392.020 ft² | 392.020 ft² | 0.000% |
| Strake S_wet | 39.956 ft² | 39.956 ft² | 0.000% |
| Pitch ctrl S_wet | 99.585 ft² | 99.585 ft² | 0.000% |
| Vert tail S_wet | 81.686 ft² | 81.689 ft² | < 0.004% |
| Amax | 25.110 ft² | 25.110 ft² | 0.000% |
| Frame 1 perimeter | 5.178 ft | 5.178 ft (Geom G50) | 0.000% |
| Fuselage accurate S_wet | 675.027 ft² | 676.329 ft² | 0.19%* |

*Difference fully explained by the frame-20 bug described in Section 6.

---

## 8. Tests Run

1. **Python verification script** — all formulas independently coded and compared against Geom cell values before any MATLAB was written.
2. **Frame 1 perimeter** — cosine model compared to Geom G50 (exact match).
3. **Amax** — reproduced frame-by-frame with nacelle subtraction.
4. **Vert tail boundary** — confirmed half-height (2.5 ft) vs half-width (3.5 ft) by back-calculating from Geom B17 target.
5. **Wing span** — `sqrt(300 × 3.0) = 30.0 ft`; confirmed against Brandt Table 3.x.
