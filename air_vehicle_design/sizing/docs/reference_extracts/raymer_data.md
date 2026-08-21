# Raymer — *Aircraft Design: A Conceptual Approach*, 6th ed. — Extracted Data

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th edition, AIAA Education Series, 2018.
**Purpose:** Reference for the MATLAB MDA package — **Ch.10 parametric engine sizing**, **Ch.12 aerodynamics (L3 drag buildup)**, and **Ch.15 weights (L3 fighter)**. The PDF is a 1097-page scan (no text layer); content below was OCR-recovered.

> ⚠️ **OCR caveat:** equation coefficients/exponents below were read from scanned pages by OCR and some are garbled. Equation numbers and **PDF page locations** are given so each can be verified directly in the book before coding. Do **not** hard-code an exponent flagged `[verify]` without checking the page.
> Citation format: *Raymer, Aircraft Design 6th ed., Eq/Table/Fig, §section*.

---

## Chapter 10 — Propulsion and Fuel System Integration, §10.3.2 (book p. 284, PDF p. 314)

Parametric statistical jet-engine sizing models — Eqs. (10.4–10.15).
Defined in §10.3.2 and implemented in `PropL2` as static low-level methods.

**Variable definitions** (book p. 285):
- `T` = takeoff thrust at SLS [lbf]
- `BPR` = bypass ratio
- `M` = design (max) Mach number
- Cruise reference: ~36,000 ft, M = 0.9

### Nonafterburning engines (BPR 0 to ~6, subsonic)

```
W        = 0.084  · T^1.1 · exp(-0.045·BPR)   [lb]         (10.4)  [6th ed.; see note]
L        = 0.185  · T^0.4 · M^0.2              [ft]         (10.5)
D        = 0.033  · T^0.5 · exp( 0.04·BPR)    [ft]         (10.6)  [CONFIRMED]
SFC_max  = 0.67   · exp(-0.12·BPR)             [1/hr]       (10.7)
T_cruise = 0.60   · T^0.9 · exp(+0.02·BPR)    [lb]         (10.8)  [SIGN CORRECTED]
SFC_cr   = 0.88   · exp(-0.05·BPR)             [1/hr]       (10.9)
```

> ✅ **Corrected 2026-08-17** against a 320-dpi render of book p. 284 (this part of the PDF is
> cleanly typeset, not scanned, so the reading is unambiguous):
> - **Eq. 10.8 exponent sign was wrong here** — it is `exp(+0.02·BPR)`, not `exp(-0.02·BPR)`.
>   No project code reads Eq. 10.8 (`PropL2` implements only the afterburning set), so this is a
>   documentation-only fix.
> - **Eq. 10.6 `[verify]` flag cleared** — the page prints **0.033**. The "metric cross-check
>   suggests ~0.034" note was itself wrong and has been removed.
> - **Eq. 10.4 coefficient**: the 6th ed. prints **0.084**, not 0.0847. See the edition note under
>   the afterburning block below.

### Afterburning engines (BPR 0 to <1, M_max < 2.5)

```
W        = 0.063  · T^1.1 · M^0.25 · exp(-0.81·BPR)  [lb]         (10.10) [6th ed.; see note]
L        = 0.255  · T^0.4 · M^0.2                     [ft]         (10.11)
D        = 0.024  · T^0.5 · exp( 0.04·BPR)            [ft]         (10.12) [CONFIRMED]
SFC_maxAB= 2.1    · exp(-0.12·BPR)                    [1/hr]       (10.13)
T_cruise = 2.4    · T^0.74· exp( 0.023·BPR)           [lb]         (10.14)
SFC_cr   = 1.04   · exp(-0.186·BPR)                   [1/hr]       (10.15)
```

> ✅ **Eq. 10.12 `[verify]` flag cleared 2026-08-17** — the page prints **0.024**. The "metric
> cross-check suggests ~0.0256" note was itself wrong and has been removed.

> ⚠️ **EDITION NOTE — Eqs. 10.4 and 10.10 weight coefficients.** The **6th edition** (the edition
> this file is titled for, and the PDF the project holds) prints `0.084` and `0.063`. This file
> previously listed `0.0847` and `0.0637`, which are **7th edition** values, not OCR noise.
> `src/disciplines/propulsion/PropL2.m` intentionally uses the 7th-ed. `0.0637` for Eq. 10.10 and
> cites it as such; its header records that a person holding the 7th edition confirmed that value
> on 2026-07-30. **Both are right for their own edition — do not "correct" `PropL2` to 0.063.**
> When citing either equation, state which edition you mean.

Metric equivalents on book p. 284 (`14.7`, `0.49`, `0.15`, `19`, `0.35`, `25` nonAB; `11.1`,
`0.68`, `0.11`, `60`, `0.59`, `30` AB) were read off the same page image and are consistent with
the fps coefficients above.

---

## Chapter 12 — Aerodynamics (book pp. ≈393–415; PDF = book + 30)

### §12.4 Lift
**Subsonic wing lift-curve slope (per radian), Eq. (12.6)** (PDF p.430, book 400):
```
CLα = [ 2πA / ( 2 + sqrt( 4 + (A²β²/η²)(1 + tan²Λ_maxt/β²) ) ) ] · (S_exposed/S_ref) · F
   β² = 1 − M²                                                   (12.7)
   η  = CLα_airfoil / (2π/β)  ≈ 0.95 if unknown                  (12.8)
   F  = 1.07 (1 + d/b)²  fuselage lift factor                    (12.9)   [verify exponent]
   Λ_maxt = sweep at the chordwise location of max airfoil thickness
   S_exposed = wing planform minus fuselage-covered part; cap (S_exposed/S_ref)·F ≤ ~0.98
```
Endplate/winglet effective AR: `A_eff = A(1 + 1.9 h/b)` (12.10, endplate); `A_eff = A(1 + h/b)·k` (12.11, winglet). [verify]

**Max lift (clean):**
```
Swept wing:  CL_max = 0.9 · Cl_max · cos Λ_0.25c                 (12.15)   (PDF p.435, book 405)
High-AR:     CL_max = Cl_max·(CL_max/Cl_max) + ΔCL_max          (12.16)  (Figs 12.9, 12.10)
α_CLmax (high-AR) = CL_max/CLα + α0L + Δα_CLmax                 (12.17)
```
- Leading-edge sharpness parameter Δy (Table 12.1): NACA 4-digit 26·(t/c); 5-digit 26·(t/c); **64-series 21.3·(t/c)**; 65-series 19.3·(t/c); biconvex 11.8·(t/c).
- Clean wing CL_max ≈ 90% of airfoil max lift (2-D data, similar Re).
- Flap types (Fig 12.18) & LE devices (Fig 12.19) discussed for ΔCL_max_TO/L.

### §12.5 Parasite (zero-lift) drag — TWO methods

**(a) Equivalent skin-friction method, Eq. (12.23)** (PDF p.446, book 416):
```
CD0 = Cfe · (S_wet / S_ref)
```
**Table 12.3 — Equivalent skin-friction coefficients Cfe** (PDF p.447, book 417):

| Aircraft type | Cfe |
|---------------|------|
| Bomber | 0.0030 |
| Civil transport | 0.0026 |
| Military cargo (high-upsweep fuselage) | 0.0035 |
| **Air Force fighter** | **0.0035** |
| **Navy fighter** | **0.0040** |
| Clean supersonic cruise | 0.0025 |
| Light a/c — single engine | 0.0055 |
| Light a/c — twin engine | 0.0045 |
| Prop seaplane | 0.0065 |
| Jet seaplane | 0.0040 |

**(b) Component buildup method, Eq. (12.24)** (PDF p.447, book 417) — the **L3 method**:
```
(CD0)_subsonic = [ Σ_c (Cf_c · FF_c · Q_c · S_wet_c) ] / S_ref  +  CD_misc  +  CD_L&P
```
- `Cf_c` = flat-plate skin-friction coeff of component c (laminar vs turbulent, Re-based).
- `FF_c` = component **form factor** (pressure drag from viscous separation).
- `Q_c`  = component **interference factor** (NOT dynamic pressure).
- `CD_misc` = flaps, un-retracted gear, upswept aft fuselage, base area.
- `CD_L&P` = leakage & protuberance drag.
- Supersonic: skin-friction term = flat-plate Cf · S_wet; pressure drag → wave-drag term (from volume distribution). Transonic: graphical fairing between subsonic & supersonic.
> Flat-plate Cf, form-factor FF, and interference-Q sub-equations are on the following pages (book ~418–424, PDF ~448–454) — OCR them there if exact FF formula needed.

### §12.6 Drag due to lift / transonic CD0
- Transonic zero-lift drag for the **F-16** (project already cites this): **Fig 12.32** gives CD0 ≈ [0.020, 0.035, 0.047] at M = [0.5, 1.0, 1.5] — use for the L3 Mach-varying CD0 (per project spec).
- Drag-due-to-lift uses either Oswald span efficiency (`CDi = CL²/(πAe)`) or the leading-edge-suction method (`K = ...`), book ~425–430 (PDF ~455–460) — OCR if the e / K formula is needed.

---

## Chapter 15 — Weights, §15.3.1 Fighter/Attack statistical weights (PDF pp.602–603, book 572–573)

**These are the equations the project's L3 weight model uses** (British units, results in pounds). Coefficients legible from OCR; **exponents marked `[verify]` were partly garbled — confirm on PDF pp.602–603.**

```
Wing            W = 0.0103·K_dw·K_vs·(W_dg·N_z)^0.5·S_w^0.622·A^0.785·(t/c)_root^(-0.4)
                       ·(1+λ)^0.05·(cosΛ)^(-1.0)·S_csw^0.04                 (15.1) [verify exps]
Horizontal tail W = 3.316·(1 + F_w/B_h)^(-2.0)·((W_dg·N_z)/1000)^0.260·S_ht^0.806   (15.2) [verify]
Vertical tail   W = 0.452·K_rht·(1 + H_t/H_v)^0.5·(W_dg·N_z)^0.488·S_vt^0.718
                       ·M^0.341·L_t^(-1.0)·... ·(1+λ)^... ·(cosΛ_vt)^(-1.0)·A^... (15.3) [verify]
Fuselage        W = 0.499·K_dwf·W_dg^0.35·N_z^0.25·L^0.5·D^0.849·W^0.685       (15.4) [verify]
Main landing gear  W = K_cb·K_tpg·(W_l·N_l)^0.25·L_m^... ·...                  (15.5) [verify]
Nose landing gear  W = (W_l·N_l)^0.290·L_n^0.5·N_nw^...                        (15.6) [verify]
Engine mounts   W = 0.013·N_en^0.795·T^0.579·N_z                              (15.7) [verify]
Firewall        W = 1.13·S_fw                                                 (15.8)
Engine section  W = 0.01·W_en^0.717·N_en·N_z                                  (15.9) [verify]
Air induction   W = 13.29·K_vg·L_d^0.643·K_d^0.182·N_en^... ·(L_s/L_d)^... ·D^...  (15.10) [verify]
Tailpipe        W = 3.5·D_e·L_tp·N_en                                         (15.11)
Engine cooling  W = 4.55·D_e·L_sh·N_en                                        (15.12)
Oil cooling     W = 37.82·N_en^1.078                                          (15.13) [verify]
Engine controls W = 10.5·N_en^... ·L_ec^...                                   (15.14) [verify]
Starter (pneum.)W = 0.025·T^0.760·N_en^0.72                                   (15.15) [verify]
Fuel system     W = 7.45·V_t^0.47·(1 + V_i/V_t)^(-0.095)·(1 + V_p/V_t)
                       ·N_t^0.066·N_en^0.052·((T·SFC)/1000)^0.249             (15.16) [verify]
Flight controls W = 36.28·M^0.003·S_cs^0.489·N_s^0.484·N_c^...                (15.17) [verify]
Instruments     W = 8.0 + 36.37·N_en^0.676·N_t^0.237 + 26.4·(1+N_ci)^1.356    (15.18) [verify]
Hydraulics      W = 37.23·K_vsh·N_u^0.664                                     (15.19) [verify]
Electrical      W = 172.2·K_mc·R_kva^0.152·N_c^0.10·L_a^0.10·N_gen^0.091      (15.20) [verify]
Avionics        W = 2.117·W_uav^0.933                                         (15.21) [verify]
Furnishings     W = 217.6·N_c           (includes ejection seats)            (15.22)
Air cond/anti-ice W = 201.6·[(W_uav + 200·N_c)/1000]^0.735                    (15.23) [verify]
Handling gear   W = 3.2e-4·W_dg                                              (15.24)
```

**Key variable definitions** (standard Raymer notation):
- `W_dg` = design gross weight (lb); `N_z` = ultimate load factor = 1.5 × limit load factor.
- `S_w, S_ht, S_vt` = trapezoidal (theoretical) areas; `A` = aspect ratio; `λ` = taper; `Λ` = sweep; `(t/c)_root`.
- `K_dw` = 0.768 if delta wing else 1.0; `K_dwf` = 0.774 if delta wing else 1.0; `K_vs` = 1.19 if variable sweep else 1.0; `K_rht` = 1.047 for rolling (all-moving) tail else 1.0.
- `F_w` = fuselage width at HT intersection; `B_h` = HT span; `H_t/H_v` = tail height ratio; `L_t` = tail length (wing ¼-MAC → tail ¼-MAC); `T` = total engine thrust; `N_en` = number of engines.
- `S_csw` = control-surface (wing-mounted, e.g. flap/aileron) area; `S_cs` = total control-surface area.

> This matches the project's existing `F16WeightLevel3` / `WeightLevel3` use of Raymer §15.3.1. **§15.3.2 Cargo/Transport** equations (15.25+, PDF p.604) exist but are not the fighter case — not transcribed here.

---

## Notes for the project
- **L3 CD0 (component buildup):** Eq 12.24 — implement `Σ Cf·FF·Q·Swet/Sref + CD_misc + CD_L&P`. Cross-check with Nicolai Eqs 2.20–2.24 (`nicolai_data.md`). Use Fig 12.32 F-16 transonic CD0 [0.02, 0.035, 0.047] @ M[0.5,1.0,1.5].
- **L3 CD0 (quick check):** Eq 12.23 with Cfe = 0.0035 (Air Force fighter).
- **L3 weights:** Eqs 15.1–15.24 (fighter/attack). The earlier-noted L3 TOGW shortfall (≈26k vs 31k target) likely traces to one of these component equations or its K-factors — **verify exponents on PDF pp.602–603** and the K_dw/K_dwf/K_vs/K_rht flags, since the project's L3 weight diff was actively editing `Fw`, `Kdw`, `Kdwf`, `Sr` for the fuselage/VT equations.
- **L2/L3 CLα & CL_max:** Eqs 12.6 and 12.15–12.17.
