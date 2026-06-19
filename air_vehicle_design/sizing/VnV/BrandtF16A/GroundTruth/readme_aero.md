# Brandt F-16A Aerodynamics — Aero Tab Reference

Source: `Brandt-F16-A.xls`, sheet **Aero**

---

## Cfe Lookup Table (Aero!J16:K26)

| Aircraft Type            | Cfe    |
|--------------------------|--------|
| Jet trainer              | 0.0035 |
| Jet fighter (smooth)     | 0.0035 |
| Jet fighter (production) | 0.0045 |
| Clean supersonic         | 0.0025 |
| Military cargo/bomber    | 0.0030 |
| Swept-wing transport     | 0.0026 |
| T-tail transport         | 0.0026 |
| Prop trainer             | 0.0035 |
| GA – single              | 0.0055 |
| GA – twin                | 0.0045 |
| GA – composite           | 0.0035 |

F-16A uses the "jet fighter (production)" row → **Cfe_tab = 0.0037** (Aero!J3, interpolated).
This tabulated value produces the Brandt-method CDmin prediction: CDmin_sub = 0.01691 (Aero!G3).

However, matching the actual F-16A cruise drag (CD0_cruise = 0.0270, Miss tab) against the corrected
S_wet = 1371.09 ft² back-calculates to an **effective Cfe = 0.005908**. This higher value folds in
form factors, interference drag, wave drag near Mcrit = 0.873, and miscellaneous items not captured
by the skin-friction table alone.

### S_wet double-count note

The S_wet value shown in the Excel Aero tab (Geom!B19 = 1371.09 ft²) double-counts the strake wetted
area: the strake appears once as an exposed surface and once inside the fuselage integration region.
See **readme_geom.md** for the full accounting.

The MATLAB code (`BrandtAerodynamics.analyze()`) pulls S_wet from the `BrandtGeometry` object property
`S_wet_total_accurate_ft2`, which replicates the same Excel formula and therefore carries the same
double-count. Both the Excel and the code are internally consistent — the double-count is already
embedded in the back-calculated Cfe_eff = 0.005908 stored in `f16a_geometry.json`.

---

## F-16A Specific Values (Aero!M4:Q10)

These are the actual F-16A aerodynamic reference values tabulated in the Aero sheet, columns M–Q,
for five Mach points. They represent measured or authoritative reference data (not Brandt-predicted).

| Mach  | CDmin   | CDo     | k1    | k2      |
|-------|---------|---------|-------|---------|
| 0.02  | 0.0197  | 0.0197  | 0.122 | −0.0070 |
| 0.875 | 0.0205  | 0.0205  | 0.128 | −0.0070 |
| 1.05  | 0.0444  | 0.0444  | 0.210 | −0.0030 |
| 1.60  | 0.0461  | 0.0461  | 0.340 |  0.0000 |
| 2.00  | 0.0458  | 0.0458  | 0.380 |  0.0000 |

> CDmin ≈ CDo at all Mach points because the F-16A wing has very low camber (NACA 1404 → CL0 ≈ 0.027),
> making the CL of minimum drag essentially zero and CDmin ≈ CDo in practice.

---

## Computed Aerodynamic Parameters

### Mach Thresholds

| Parameter   | Formula                                   | Value  | Cell  |
|-------------|-------------------------------------------|--------|-------|
| Mcrit       | `1 − 0.065 × (cos(ΛLE) × tc_pct)^0.6`   | 0.8727 | A12   |
| M_wave      | `sec(ΛLE)^0.2 = (1/cos(ΛLE))^0.2`        | 1.0547 | G8    |
| M_LE_super  | `sec(ΛLE) = 1/cos(ΛLE)`                  | 1.3054 | F9    |

- `tc_pct` = last two digits of the NACA code (= 4 for NACA 1404)
- ΛLE = 40° → cos(40°) = 0.7660
- Above M_LE_super the leading edge is supersonic; different k1 formula applies (Aero!D10)

### Span Efficiency (Aero!A19, A28)

```
e = MAX(0.6,  2 / (2 − AR + sqrt(4 + AR² × (1 + tan²(Λ_avg)))))
```

where `Λ_avg = (Λ_LE + Λ_TE) / 2`.

| Surface    | e_computed | Cell | GT    |
|------------|------------|------|-------|
| Wing       | 0.7227     | A19  | 0.7227|
| Stabilator | 0.7227     | A28  | 0.7227|

### Oswald Efficiency e0 (Aero!G12)

This is the Brandt formula — note it differs from the Raymer textbook formula in both the
constants and exponents:

```
e0 = MAX(0.4,  4.6 × (1 − 0.033 × AR^0.53) × cos(ΛLE)^0.1 − 3.3)
   = MAX(0.4,  4.6 × (1 − 0.033 × 3^0.53) × cos(40°)^0.1 − 3.3)
   = 0.9144                                                      [Aero!G12]
```

e0 is used to compute k1 via `k1 = 1/(π × e0 × AR)`.

### Lift Curve Slopes (Aero!A15, A23, A32)

Helmbold-like formula for low-AR swept wings (per degree, incompressible):

```
CLα = 0.1 / (1 + 5.73 / (π × e × AR))
```

| Surface      | CLα (per deg) | Cell |
|--------------|---------------|------|
| Wing         | 0.05431       | A15  |
| Stabilator   | 0.05431       | A23  |
| Total (A32)  | 0.06150       | A32  |

Total includes strake correction and tail contribution:
```
CLα_total = CLα_wing × (S_ref + S_strake)/S_ref
          + CLα_pitch × (1 − ε) × S_pitch/S_ref
```

where ε = downwash gradient (Aero!A40 = 0.8175).

### CL0 and k2 (Aero!G20, G17)

```
CL0 = CLα_wing [/deg] × floor(sqrt(NACA_code / 1000)) / 2
    = 0.05431 × floor(sqrt(1404/1000)) / 2
    = 0.05431 × 1 / 2 = 0.02716                          [Aero!G20]

k2  = −2 × k1 × CL0
    = −2 × 0.1160 × 0.02716 = −0.00630                   [Aero!G17]
```

Both k2 and e_oswald are **computed** — they are not read from the JSON.

### Drag Polar (Subsonic, Two Bases)

| Basis         | CDmin / CD0  | Source        | Usage                            |
|---------------|--------------|---------------|----------------------------------|
| Aero tab      | CDmin = 0.01691 | Cfe_tab × S_wet/S_ref | aero_at_mach() method |
| Mission tab   | CD0 = 0.0270    | Cfe_eff × S_wet/S_ref | drag_polar() method   |

The two bases exist because the Aero tab shows Brandt's pure skin-friction prediction while
the Mission tab uses the effective Cfe that matches real F-16A cruise drag.

### Mach-Dependent Drag Polar — run(mach) public API / aero_at_mach(M) internal (Aero!A5:E10)

The public API is `run(mach)`, which returns an `aero_results` struct with fields:
`CD0`, `K1`, `K2`, `CLmax_clean`, `CLmax_TO`, `CLmax_land`, `LD_max`.
It also stores these as `run_CD0`, `run_K1`, etc. on the object (dual-return contract).
Internally, `run(mach)` calls the private `aero_at_mach(M)` helper, which returns
`[CDo, k1_m, k2_m, CDmin]` following the Aero-tab methodology:

**Subsonic (M ≤ Mcrit):**
```
CDmin = CDmin_sub = 0.01691
k1_m  = k1_sub    = 0.1160
k2_m  = k2_sub    = −0.00630
```

**Transition (Mcrit < M < M_wave):**
```
CDmin = CDmin_sub + frac × wave_factor    (linear interpolation)
k1_m  = k1_sub  + frac × (k1_Mwave − k1_sub)
k2_m  = k2_sub × (1.5 − M) / (1.5 − Mcrit)    (linear decay toward zero at M=1.5)
```

**Supersonic (M_wave ≤ M ≤ M_LE_super):**
```
CDwave = wave_factor × (1 − 0.3 × (M − M_wave)^0.5)
CDmin  = CDmin_sub + CDwave
k1_m   = MAX(k1_super(M), (k1_Mwave + k1_M2)/2)    (floor mechanism)
k2_m   = MAX(0, k2_sub × (1.5 − M)/(1.5 − Mcrit))
```

**Beyond M_LE_super (M > M_LE_super):**
```
CDwave frozen at M_LE_super (wave drag saturates after LE goes supersonic)
k1_m = k1_super(M) = AR×(M²−1) / (4×AR×sqrt(M²−1)−2) × cos(ΛLE)    [Aero!D10]
k2_m = 0
```

Wave drag factor (Sears-Haack reference):
```
wave_factor = (4.5π / S_ref) × (Amax/L_ac)² × Ewd × (0.74 + 0.37×cos(ΛLE))
```

k1 floor mechanism (Excel recursive MAX pattern):
```
k1_M2    = k1_super(2.0)                     = 0.3670  (seed, no recursion)
k1_Mwave = MAX(k1_super(M_wave), (k1_sub+k1_M2)/2)   = 0.2415
floor    = (k1_Mwave + k1_M2)/2              = 0.3043  (used for M_wave < M ≤ 2.0)
```

---

## Quadratic Drag Polar (Subsonic, Miss Tab Basis)

```
CD = CD0 + k1 × CL² + k2 × CL
   = 0.0270 + 0.1160 × CL² − 0.00630 × CL      [Miss tab]
```

Takeoff:
```
CD_TO = 0.0520 + 0.1160 × CL² − 0.00630 × CL   [Miss!CD0_TO]
```

L/D maximum (Brandt simplified, ignoring k2):
```
LD_max = 0.5 / sqrt(CD0 × k1) = 8.93            [Miss!LD_max]
CL_opt = sqrt(CD0 / k1)       = 0.482            [Miss!CL_opt]
```

---

## CLmax (Aero!H25, H27, H29 — from Aero!L11:L25 methodology)

Brandt's CLmax method derives maximum lift coefficients for three configurations.
The derivation in Aero!L11:L25 proceeds as follows:

### Step 1: Stall angle and CLmax_clean (Aero!L12–L14, H25)

The stall angle of attack is estimated from the airfoil camber digit:

```
alpha_stall = floor(NACA_camber_digit + 15)  [degrees]
```

For NACA 1404: `NACA_camber_digit = floor(NACA_code/1000) = 1` → `alpha_stall = 16°`

```
CLmax_clean = CLα_total [/deg] × alpha_stall
            = 0.06150 × 16 = 0.984               [Aero!H25]
```

Assumption: CLmax scales linearly with CLα_total and is limited by the airfoil stall angle,
which Brandt estimates conservatively from the camber digit.

### Step 2: Flapped wing area (Aero!L13, L31)

The leading-edge flap and trailing-edge flap only cover a portion of the wing. Inboard
fuselage-blended area and outboard aileron bay are excluded:

```
S_flapped = MAX(0, S_ref − outboard_strip − inboard_strip)

outboard_strip = 2 × (b/2 − y_ail_tip) × c(y_ail_tip)
inboard_strip  = 2 × y_ail_root × [c_root + c(y_ail_root)] / 2
               = y_ail_root × (c_root + c_at_ail_root)   [bilateral trapezoid]
```

where `c(y) = c_root − (c_root − c_tip) × y / (b/2)` is the local chord.

```
S_flapped = 300.0 − 51.49 − 103.77 = 144.745 ft²        [Aero!L31]
```

Assumptions:
- Aileron spans from y_ail_root = 3.5 ft to y_ail_tip ≈ 11.25 ft (from BrandtGeometry)
- The `outboard_strip` approximates the chord at `y_ail_tip`, not an exact integration

### Step 3: Additional lift from flaps (Aero!L15–L16)

The flap system produces an effective increase in angle of attack:

```
ΔαLanding = 15° × (S_flapped / S_ref) × cos(Λ_TE)
           = 15 × (144.745 / 300) × cos(≈0°)
           = 7.185°

ΔCLmax = CLα_total × ΔαLanding
       = 0.06150 × 7.185 = 0.4419

CLmax_from_flaps = CLmax_clean + ΔCLmax = 0.984 + 0.4419 = 1.426
```

Assumption: The flap effectiveness is modeled as adding an equivalent angle-of-attack
increment proportional to the flapped-wing fraction and TE sweep factor.

### Step 4: Pitch-trim limit on CLmax (Aero!L17–L21, L29)

High CL requires pitching moment balance from the moving stabilator. The trim-limited CLmax
is the clean CLmax plus the maximum CL increment the stabilator can trim:

```
l_t = |x_le_pitch + 0.25×c_root_pitch − x_apex_wing − 0.5×c_root_wing|

CLmax_trim = CLmax_clean
           + (CLα_pitch / CLα_wing) × (S_pitch / S_ref) × (l_t / c_root_wing) / 0.5
```

For F-16A:
```
l_t ≈ 9.46 ft   (stabilator moment arm)
CLmax_trim ≈ 1.537
```

Assumption: The factor 0.5 in the denominator represents a 50% margin on stabilator authority —
Brandt assumes the stabilator must be only half-deflected at CLmax to allow recovery.

### Step 5: Landing and takeoff CLmax (Aero!H29, H27)

CLmax_landing is the lower of trim-limited and flap-limited:

```
CLmax_landing = MIN(CLmax_trim, CLmax_from_flaps)
              = MIN(1.537, 1.426) = 1.426               [Aero!H29]
```

CLmax_takeoff uses 66% of the clean-to-landing increment (partial flap setting):

```
CLmax_takeoff = CLmax_clean + 0.66 × (CLmax_landing − CLmax_clean)
              = 0.984 + 0.66 × (1.426 − 0.984) = 1.276  [Aero!H27]
```

### Summary of CLmax values

| Configuration | CLmax | Cell  | Formula basis                              |
|---------------|-------|-------|--------------------------------------------|
| Clean         | 0.984 | H25   | CLα_total × (camber_digit + 15)            |
| Takeoff       | 1.276 | H27   | Clean + 66% of (Landing − Clean) increment |
| Landing       | 1.426 | H29   | MIN(trim_limited, from_flaps)              |

---

## Discipline Interface (BrandtAerodynamics)

`BrandtAerodynamics` follows the three-tier Level-Brandt interface:

| Method | Purpose | Key outputs |
|--------|---------|-------------|
| `BrandtAerodynamics(geom)` | Constructor — stores `BrandtGeometry` handle; all properties = NaN | — |
| `analyze()` | Design-variable pass — Mach-independent quantities | CDmin_sub, k1, k2, CLmax_*, e0, Mach thresholds |
| `run(mach)` | State/control pass — Mach-dependent polar | struct `{CD0, K1, K2, CLmax_clean, CLmax_TO, CLmax_land, LD_max}` |

```matlab
geom = BrandtGeometry();   geom.analyze();
aero = BrandtAerodynamics(geom);
aero.analyze();                         % CDmin_sub, k1, k2, CLmax_* computed and stored

% Mach-dependent evaluation (dual-return contract):
r = aero.run(0.85);                     % returns struct AND stores to aero.run_CD0, etc.
r.CD0   % CDo at M=0.85
r.LD_max

% Inspection style:
aero.run(0.85);
cd0 = aero.run_CD0;   % same value
```

The `state_vector` conceptual mapping: `[mach]`.  
The `control_vector` is empty at this fidelity level.  
`run()` always calls `validate_run_()` before returning — asserts no NaN in key outputs.

---

## Ground-Truth Cross-Check Values

| Quantity        | Value    | Source Cell      | Tolerance |
|-----------------|----------|------------------|-----------|
| CD0_cruise      | 0.0270   | Miss!CD0_cruise  | ±1%       |
| CD0_takeoff     | 0.0520   | Miss!CD0_TO      | ±1%       |
| k1              | 0.1160   | Miss!k1          | ±1%       |
| k2              | −0.00630 | Miss!k2 (comp.)  | ±1%       |
| LD_max          | 8.93     | Miss!LD_max      | ±1%       |
| CL_opt          | 0.482    | Miss!CL_opt      | ±1%       |
| e0              | 0.9144   | Aero!G12         | ±1%       |
| e_wing          | 0.7227   | Aero!A19         | ±1%       |
| e_pitch         | 0.7227   | Aero!A28         | ±1%       |
| CDmin_sub       | 0.01691  | Aero!G3          | ±1%       |
| Mcrit           | 0.8727   | Aero!A12         | ±1%       |
| M_wave          | 1.0547   | Aero!G8          | ±1%       |
| M_LE_super      | 1.3054   | Aero!F9          | ±1%       |
| S_flapped       | 144.745  | Aero!L31         | ±1%       |
| CLmax_clean     | 0.984    | Aero!H25         | ±1%       |
| CLmax_takeoff   | 1.276    | Aero!H27         | ±1%       |
| CLmax_landing   | 1.426    | Aero!H29         | ±1%       |

---

## Notes

- `k2` and `e0` are **computed**, not read from the JSON. See Aero!G17, G12.
- All values marked "Miss tab" are for the clean subsonic configuration; takeoff uses `CD0_TO`.
- The drag polar is valid for M ≤ Mcrit in the `drag_polar()` method. The `aero_at_mach()` method
  extends to M = 2.0 using the Brandt wave-drag model.
- S_wet in both the Excel and MATLAB replicates the same formula (Geom!B19), which double-counts
  the strake. This is intentional: the effective Cfe absorbed the calibration against real F-16A
  data with that same S_wet, so the method is self-consistent.
