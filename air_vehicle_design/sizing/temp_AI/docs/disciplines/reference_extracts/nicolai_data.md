# Nicolai & Carichner — *Fundamentals of Aircraft and Airship Design, Vol. I: Aircraft Design* — Extracted Data

**Source:** Leland M. Nicolai & Grant E. Carichner, *Fundamentals of Aircraft and Airship Design, Volume I — Aircraft Design*, AIAA Education Series, 2010.
**Purpose:** Reference for the MATLAB MDA package (F-16A). Equations + methods paraphrased with citation; large historical tables NOT reproduced (only project-relevant rows / typical values).

> Citation: *Nicolai & Carichner, Fundamentals of Aircraft and Airship Design Vol. I, <chapter/eq/table>*.

---

## Ch. 2 / Ch. 13 — Aerodynamics: CD0 component build-up (L2/L3 drag)

### Skin-friction-based CD0 build-up (§2.10, Eqs 2.20–2.24)
Each component is treated as a flat plate of equivalent wetted area:
```
CD0 = CD_Pmin + CDF                                                  (2.20)
   CD_Pmin = pressure (separation) drag, small vs CDF, experimentally found
   CDF = CF · (Swet / Sref)                                          (skin-friction term)

Flat-plate skin-friction coefficient CF:
   Laminar  (Re < 5×10^5):   CF = 1.328 / sqrt(Re)                   (2.21)
   Turbulent(Re > 5×10^5):   CF = 0.455 / (log10 Re)^2.58            (2.22)
   Nose cone:                CF_cone = (2/3) · CF_flatplate

Vehicle total skin-friction term (sum components, ref to wing area):
   (CDF)_a/c = [ CF_fuse·SF + CF_nose·SN + CF_wing·SW + CF_tail·ST ] / Sref   (2.23)

Total aircraft zero-lift drag (adds ~5% mutual interference):
   (CD0)_a/c = 1.25 · (CDF)_a/c                                      (2.24)
```
- Rule of thumb: for thin wings (t/c ≤ 20%) and streamlined bodies, CD0 is **70–80% skin friction** → `CD0 ≈ 1.2·CDF` per component (§2.10).
- **Ch. 13 (Estimating Wing-Body Aerodynamics)** gives the *more accurate* method for later design: §13.1 Linear lift-curve slope CLα, §13.2 Drag-due-to-lift, §13.3 Zero-lift drag coefficient, §13.4 Combined vehicle aero. Use Ch.13 for L3, Eqs 2.20–2.24 for early/L2 estimates.
- Drag polar form (§3.x): `CD = CD0 + K·CL²`, with the lift-to-drag relations summarized in `metabook_data.md`.

> *For the F-16 L2/L3 CD0, the project's Swet/Sref method (L2) and component buildup (L3) both align with Nicolai Eqs 2.23–2.24. Component form factors / interference are refined in Ch.13.*

---

## Ch. 11 — Tail sizing by Tail Volume Coefficient (L2 tail sizing)

### Defining equations (§11.1–11.4)
```
Horizontal tail:   C_HT = (l_HT · S_HT) / (c̄ · S_ref)               (11.2)
   l_HT = distance from c.g. to quarter-chord of HT mac; c̄ = wing MAC; S_ref = wing area
Vertical tail:     C_VT = (l_VT · S_VT) / (b · S_ref)               (11.1)
   l_VT = c.g.→VT mac quarter-chord distance; b = wing span
Canard:            C_C  = (l_C · S_C) / (c̄ · S_ref)                 (11.3),  C_C ≈ 0.10–0.11
```
**Procedure:** pick C_HT (and C_VT) for a similar aircraft class from historical data, then solve Eq. (11.2)/(11.1) for S_HT / S_VT.

### Values relevant to the project
**F-16 (Table 11.6, Fighter Aircraft):**  C_HT = **0.68**,  C_VT = **0.041**.

**Typical values for preliminary tail sizing (Table 11.8):**

| Class                         | C_HT | C_VT  |
|-------------------------------|------|-------|
| Jet fighter (all speeds)      | 0.5  | 0.076 |
| Military jet trainer          | 0.6  | 0.06  |
| Commercial jet transport      | 1.0  | 0.083 |

> Tailless (e.g. F-106, B-58): C_HT = 0; size VT with the usual C_VT. *(Full per-aircraft historical tables 11.1–11.7 not reproduced — use the F-16 row above or the class-typical values.)*

---

## Ch. 5 — Preliminary Takeoff Weight Estimate (overlaps Roskam/Raymer)
- §5.2 Fixed weight, §5.3 Empty weight, §5.4 Fuel weight, §5.5 Determining W_TO (iterative), §5.6 range- vs payload-dominated.
- Same structure as Roskam Part I and the metabook (see `roskam_vol1_data.md`, `metabook_data.md`): guess W_TO → empty-weight fraction + fuel fractions → iterate.

## Ch. 6 — Estimating the Takeoff Wing Loading (constraint analysis source)
Each requirement constrains (W/S)_TO and/or (T/W):
- §6.2 Range-dominated (cruise efficiency) · §6.3 Endurance/loiter · §6.4 Landing & takeoff · **§6.5 Air-to-air combat & acceleration** (the fighter-relevant sizing) · §6.6–6.8 high altitude / ride quality.
- This chapter + Ch.10 (Takeoff & Landing Analysis) provide the point-performance equations feeding the project's constraint diagram (combat ceiling, sustained turn, acceleration, takeoff/landing distance).

## Ch. 9 — High-Lift Devices (ΔCL_max, flap drag)
- §9.4 Methods for max subsonic CL of mechanical high-lift devices → **ΔCL_max_TO / ΔCL_max_L**.
- §9.5 Subsonic drag due to flap deflection → **ΔCD0_flap** increments for TO/landing configs.

## Ch. 3 / Ch. 4 — Performance & operating envelope
- §3.3 min drag & max L/D, §3.5 endurance/loiter, §3.6 range (Breguet), §3.7 level turn, §3.9 energy maneuverability (air-combat), §3.10 climb/descent — useful for L2/L3 mission-segment and constraint equations.

## Ch. 14 — Propulsion fundamentals
- Turbine/propeller/ramjet/rocket operation; complements Mattingly (`mattingly_data.md`) for TSFC & thrust lapse.

---

## Notes for the project
- **Tail sizing (L2):** use Eqs 11.1/11.2 with F-16 C_HT=0.68, C_VT=0.041 (or jet-fighter typicals 0.5 / 0.076).
- **Aero CD0 (L2/L3):** Nicolai Eqs 2.20–2.24 (flat-plate skin friction + 25% interference) match the project's Swet/Sref (L2) and component-buildup (L3) plans; refine with Ch.13 for L3.
- **Constraint analysis:** Ch.6 (esp. §6.5 combat/accel) + Ch.10 (takeoff/landing) are the F-16 point-performance equations.
- **High-lift increments:** Ch.9 for ΔCL_max and Δflap-drag.
