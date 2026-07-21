# Roskam — *Airplane Design, Part II: Preliminary Configuration Design & Integration of the Propulsion System* — Extracted Data

**Source:** Jan Roskam, *Airplane Design, Part II*, Roskam Aviation & Engineering Corp. (DARcorporation).
**Purpose:** Reference for the MATLAB MDA package — **Class I drag polar (Ch.12)** and **empennage sizing (Ch.8)**. Scanned PDF; OCR-recovered. Method + equations paraphrased/cited; per-type coefficient tables (images) not reproduced.

> Citation: *Roskam, Airplane Design Part II, Eq/Step/Table*. PDF pages noted.

---

## Ch. 12 — Class I Method for Drag Polar Determination (L1/L2 CD0 method)

**Step-by-step method (§12.1, PDF pp.293–304):**
1. **Step 12.1 — Wetted area:** split the airplane into components (wings/lifting surfaces, fuselage, nacelles, pylons, etc.) and sum the wetted areas to get total `S_wet`.
   - Planform surfaces (wing, tail, fin, pylon): `S_wet` from planform area with a thickness correction.
   - Fuselages & nacelles: from side/top profiles (equivalent diameter method).
   - Compare total `S_wet` to the statistical correlation (Fig. 3.22, Part I); difference should be < 10%.
2. **Step 12.2 — Equivalent parasite area `f`:** from Fig. 3.21 of Part I (a log–log `f` vs `S_wet` correlation with skin-friction coefficient `c_f` as parameter). i.e. `f ≈ c_f · S_wet`.
3. **Step 12.3 — Clean zero-lift drag coefficient (low speed), Eq. (12.3):**
   ```
   CD0 = f / S          (S = wing reference area)            (12.3)
   ```
4. **Step 12.4 — Compressibility drag increment:** Fig. 12.7 (valid only for cruise M ≤ 0.90; above that, use cross-sectional area-ruling, Part VI).
5. **Step 12.5 — Flap drag increment(s):** Table 3.6, p.127, Part I → **ΔCD0_TO / ΔCD0_L**.
6. **Step 12.6 — Landing-gear drag increment:** Table 3.6, p.127, Part I → **ΔCD0_landinggear**.
7. **Step 12.7 — Construct cruise / takeoff / landing drag polars:**
   ```
   CD = CD0 + CL² / (π·A·e)
   ```
   (with the appropriate ΔCD0 and Oswald e per configuration).
8. **Step 12.8 — Critical L/D values** from the polars (feeds the Part I sizing, Ch.2 Step 14).

> This is exactly the project's **L1/L2** zero-lift drag approach: `CD0 = c_f · S_wet / S_ref` (here via `f = c_f·S_wet`, `CD0 = f/S`). Flap & gear ΔCD0 come from Roskam Table 3.6 (Part I).

---

## Ch. 8 — Class I Method for Empennage Sizing & Disposition (tail sizing)

**V-method (tail volume coefficients), §8.3 (PDF pp.199–206):**
```
Horizontal tail:  V_h = (x_h · S_h) / (S · c̄)               (8.1)
Vertical tail:    V_v = (x_v · S_v) / (S · b)                (8.2)
   x_h, x_v = empennage moment arms (c.g. → tail a.c.), Fig. 8.1
   S = wing area; c̄ = wing MAC; b = wing span
```
**Procedure:** (Step 8.1) choose empennage configuration → (Step 8.2) set moment arms x_h, x_v (keep large to minimize tail area) → (Step 8.3) pick V_h, V_v for the matching aircraft class from **Tables 8.1–8.12** (twelve airplane types) → solve Eqs 8.1/8.2 for S_h, S_v.
- Vertical-tail size is often set by the **engine-out (V_mc)** condition → see Part II §11.3 for the V_mc-based VT sizing procedure.

> Definitions match Nicolai Ch.11 (`nicolai_data.md`). For the F-16/jet-fighter volume-coefficient *values*, use the ones already captured there (F-16: C_HT=0.68, C_VT=0.041; jet-fighter typical 0.5/0.076). Roskam's per-type Tables 8.1–8.12 are scanned images and are not reproduced.

---

## Other Class I chapters in Part II (located, not deep-extracted)
- **Ch. 6** — Class I wing planform design & high-lift sizing (PDF p.153).
- **Ch. 7** — Class I verifying clean-airplane max lift & sizing high-lift devices (PDF p.179) → **CL_max clean/TO/L** verification (relevant to the project's CL_max tabulation; OCR pp.179–198 if exact charts needed).
- **Ch. 10** — Class I weight & balance analysis (PDF p.249).
- **Ch. 9** — Class I landing-gear sizing (PDF p.229).

---

## Notes for the project
- **L1/L2 CD0:** Roskam Eq 12.3 (`CD0 = f/S`, `f = c_f·S_wet`) — same approach the project uses; get ΔCD0_flap and ΔCD0_gear from Roskam Table 3.6 (Part I, p.127).
- **Tail sizing (L2):** Roskam Eqs 8.1/8.2 (volume-coefficient method) with the F-16 values from `nicolai_data.md`.
- **CL_max increments:** Ch.7 verifies clean/TO/landing CL_max — cross-check with Raymer §12.4 (`raymer_data.md`).
