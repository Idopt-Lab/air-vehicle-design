# Aero & Wing Design lesson: source catalogue (Gate 1)

This file is for the instructor. The build does not ship it to students.

Status: **approved at Gate 1** (2026-10-17). Steps 2-5 are built: helpers, tests, Live Scripts, lab, package. The plan is
`~/.claude/plans/find-the-current-plan-modular-snowflake.md`.

Abbreviations:
- **R** = Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed., AIAA, 2018.
- **N** = Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design*, Vol. I, AIAA, 2010.
- **Ro** = Roskam, *Airplane Design* Part II, DARcorporation.
- **ACAP** = Boeing D6-38A004, *737 MAX Airplane Characteristics for Airport Planning*, Rev K, July 2025.
- **JSR** = Jenkinson, Simpkin & Rhodes, *Civil Jet Aircraft Design*, 1999, companion "Data A: Aircraft Data File, Table 2: Boeing Aircraft" (Butterworth-Heinemann, © 2001), https://booksite.elsevier.com/9780340741528/appendices/data%2Da/table-2/table.htm

"Checked" tells how each item was checked:
- **PDF** means checked against a page image of the book.
- **extract** means checked against `docs/reference_extracts/` only, because no PDF of that chapter is on this computer.

---

## 1. Decisions for you at this gate

User review 2026-10-17: **all decisions are approved**: 1–9, 11 and 12 first (decision 5: M 0.785 at 35,000 ft), then 10 (combination rule) and 13 (C_DLE × S_e/S_ref).

1. **Wing area: correction of my earlier statement.** I told you "Boeing publishes 127 m²", and you chose that baseline. That statement was wrong:
   - No Boeing, FAA or EASA document gives a wing area for the 737 MAX, and I cannot trace the value 127 m² to any source.
   - **Proposal:** use the 737-800 reference planform from JSR: S = 124.60 m², b = 34.30 m (without winglets), AR = 9.44, λ = 0.278, Λc/4 = 25°.
   - b737.org.uk gives 124.58 m², AR 9.45 and 25.02° for the same wing.
   - **Assumption:** the MAX wing planform is the NG planform, plus the MAX winglet.
   - The trapezoid MAC is 4.02 m. EASA TCDS IM.A.120 gives 3.96 m, which is 1.5 % less. The lesson shows this difference as a check.
   - The notebook trapezoid (root 7.88 m, tip 1.25 m) gives 156.7 m² over the 34.32 m span, which is +26 %. That example stays: "less geometry gives a wrong area".
2. **Winglet:** R Eq 12.11, A_eff = A(1 + h/b)², with h = 2.92 m (ACAP §2.2.2). This gives A_eff ≈ 11.1, which the lesson uses for CLα and K.
3. **MTOW:** 82,644 kg (182,200 lb). This is the highest 737-8 option in ACAP §2.1.2. Your notebook used 82,190 kg, which is the 737-8-200 MTOW (ACAP §2.1.3).
4. **No OEW in the lab.** No official source gives a MAX OEW.
   - **Proposal:** use the ACAP MZFW (65,952 kg, same weight option). Then fuel = MTOW − ZFW, with ZFW(AR) = MZFW + ΔW_wing(AR).
   - JSR gives a 737-800 OEW of 41,480 kg. The lesson only mentions it.
5. **Cruise condition:** M 0.785 at 35,000 ft.
   - Source: Boeing 737-800 technical-characteristics page (archived, Wayback 2008-12-17).
   - Alternatives: JSR long-range cruise 452 kt at 39,000 ft (about M 0.79); EUROCONTROL APD B38M M 0.79 (the APD says it is "indicative").
   - Cruise weight at the start of cruise = MTOW × 0.970 × 0.985 (R Table 3.2, p.34). This gives CL ≈ 0.60.
6. **Low speed (L04):**
   - Use the official approach speed: 141 kt at MLW 69,308 kg (Boeing, *Aerodrome Reference Code and Approach Speeds*, Rev A, Aug 2026, p.3).
   - With 14 CFR 25.125, V_REF ≥ 1.23 V_SR0. This gives the landing CLmax that the 737 needs, ≈ 2.56.
   - The takeoff check is at V2 = 1.13 V_SR (14 CFR 25.107), with one LEAP-1B28B1 at 29,317 lbf takeoff thrust (EASA TCDS E.115, Issue 09, §III.6).
   - This replaces the notebook's assumed 140 kt.
7. **Tails and nacelle:** JSR 737-800 values for HT 32.40 m², VT 23.13 m² and nacelle 4.70 m × 2.06 m.
   - The nacelle in JSR is the CFM56-7. No source publishes the LEAP-1B nacelle. The lesson states this.
   - b737.org.uk gives HT 32.78 m² and VT 26.44 m²; your notebook used these.
8. **Airfoil:** NACA 4412 surrogate (N Table F.1), t/c = 0.12. Boeing does not publish MAX airfoils, so the lesson states this.
9. **F-16 LE radius:** no source gives the NACA 64A204 LE radius.
   - **Proxy:** R App D prints 0.256 % c for NACA 64-006. Scaled by (t/c)², this gives 0.114 % c.
   - The (t/c)² scaling agrees with R App D: NACA 0006 has 0.40 % c and NACA 0009 has 0.89 % c.
10. **Nicolai Fig 2.10:**
    - The "Zero Taper" panel is an untapered rectangle, so it means **λ = 1**, not λ = 0. The combine rule changes to δ(λ, AR) = δ_AR6(λ) · δ_λ1(AR) / δ_λ1(6), and the same for τ.
    - The two panels disagree at AR 6, λ 1 (δ 0.066 against 0.047). The rule uses each panel's own value at AR 6, so the AR 6 curve is unchanged.
11. **Sweep conversion.** R p.74 refers to "the equation at the bottom of Fig. 4.16", but the 6th-ed. print has no equation there. **Resolved (user review 2026-10-17, TODO in L01):** Gudmundsson, *General Aviation Aircraft Design* (2014), Eq. 9-11, p. 305 (from USAF DATCOM) prints exactly this formula. Cross-checked against the framework `GeometryBase.convert_sweep` and against direct chord coordinates (6 digits).
    - The lesson derives tan Λ_n = tan Λ_m − (4/A)(n − m)(1 − λ)/(1 + λ) from R Eqs 7.5–7.7 and shows the steps.
12. **Turbulent Cf:** cite N Eqs 2.22 + 2.25 (p.64, checked on the PDF), not R Eq 12.27. The equation is the same, but the Raymer scan has a blank where Eq 12.27 is.

---

## 2. Input data

### 2.1 B737 MAX 8 (SI)

| Input | Value | Source (checked) |
|---|---|---|
| Span with winglets | 35.92 m | ACAP §2.2.2, p.2-10 |
| Winglet height h | 2.92 m | ACAP §2.2.2 |
| Reference span (no winglets) | 34.30 m | JSR, 737-800 |
| S_ref | 124.60 m² | JSR, 737-800 |
| AR (geometric) | 9.44 | JSR, 737-800 (= b²/S) |
| Taper λ | 0.278 | JSR, 737-800 |
| Λc/4 | 25.0° | JSR, 737-800 |
| MAC (check value) | 3.96 m | EASA TCDS IM.A.120, Issue 29, §8.III.16, p.69 |
| Fuselage length, width, depth | 39.12, 3.76, 4.01 m | ACAP §2.2.2 |
| HT area / span | 32.40 m² / 13.40 m | JSR, 737-800. ACAP gives HT span 14.35 m: see note 1. |
| VT area / height | 23.13 m² / 6.00 m | JSR, 737-800 |
| Nacelle length / max width | 4.70 / 2.06 m | JSR, 737-800 (CFM56-7). The LEAP-1B nacelle is not published. |
| MTOW | 82,644 kg | ACAP §2.1.2, p.2-3 (highest option) |
| MZFW | 65,952 kg | ACAP §2.1.2 (same option) |
| MLW | 69,308 kg | ACAP §2.1.2 (same option) |
| Usable fuel | 25,816 L (wing tanks 2 × 4,819 L + centre 16,179 L) | ACAP §2.1.2; split from EASA IM.A.120 §8.III.9 |
| Engine thrust (takeoff) | 29,317 lbf = 130.41 kN (LEAP-1B28B1) | EASA TCDS E.115, Issue 09, §III.6, p.7 |
| Approach speed | 141 kt at MLW | Boeing, *Aerodrome Reference Code and Approach Speeds*, Rev A, Aug 2026, p.3 |
| ICAO aerodrome code | 4C (span < 36 m) | ACAP §3.3.33, p.3-41 |
| Cruise | M 0.785, 35,000 ft | Boeing 737-800 tech page (archived), decision 5 |
| Airfoil (surrogate) | NACA 4412: cl_max 1.67, α_0L −3.8°, cl_α 0.105/deg, Re 9e6 | N Table F.1 (old-HW image; checked) |
| Section drag (surrogate) | NACA 4412: cd_min ≈ 0.0060; cl at cd_min ≈ 0.6; cd 0.010 at cl 1.2 | Abbott & von Doenhoff, *Theory of Wing Sections*, App IV, pp.488–489 (old-HW image; checked) |
| Control-surface area S_csw | 0.30 S (flap area / wing area) | b737.org.uk (secondary). Used only to the power 0.1 in R15.25. |

Note 1: JSR's HT span (13.40 m) is not the ACAP HT span (14.35 m). The lesson uses the JSR area only.

### 2.2 F-16A (section B: CD0 supersonic)

| Input | Value | Source |
|---|---|---|
| S_ref, b, AR, λ, Λ_LE | 27.87 m², 9.144 m, 3.0, 0.2275, 40° | T.O. 1F-16A-1, Fig 1-2 sheet 2, p.1-9 (repo `VnV/BrandtF16A/GroundTruth/USAF-F16.pdf`) |
| Airfoil, t/c | NACA 64A204, 0.04 | T.O. 1F-16A-1, Fig 1-2 |
| S_exposed | 18.23 m² (196.23 ft²) | Brandt F-16A workbook, Geom tab (repo `f16a_ground_truth.json`) |
| r_LE | 0.114 % c (proxy) | decision 9 |
| Dash condition | M 1.60, 40,000 ft | Brandt F-16A mission "Dash" (repo `f16a_requirements.json`) |
| LE regime | M·cos Λ_LE = 1.23 > 1, β·cot Λ_LE = 1.49 ≥ 1 → supersonic LE | N Eq 13.20 validity |

---

## 3. Equation catalogue

| ID | Equation (printed form) | Source, page | Checked | Notes |
|---|---|---|---|---|
| G1 | b = √(AS); c_r = 2S/[b(1+λ)]; c_t = λc_r | R Eqs 7.5–7.7, p.191 | PDF | |
| G2 | MAC = (2/3)c_r(1+λ+λ²)/(1+λ); ȳ = (b/6)(1+2λ)/(1+λ) | R Eqs 7.8–7.9, p.192 | PDF | |
| G3 | tan Λ_n = tan Λ_m − (4/A)(n−m)(1−λ)/(1+λ) | Gudmundsson (2014), Eq. 9-11, p. 305 | PDF (Canfield references, Ch. 9) | decision 11; also follows from R Eqs 7.5–7.7 |
| G4 | S_wet = S_exp[1.977 + 0.52(t/c)] (t/c > 0.05) | R Eq 7.12, p.204 | PDF | S_exp = true exposed planform |
| G5 | S_wet,fus = πD l(1 − 2/λ_f)^(2/3)(1 + 1/λ_f²) | Ro Eq 12.3, p.284 | extract | D = √(width·depth): assumption |
| G6 | A_eff = A(1 + h/b)² | R Eq 12.11, p.400 | PDF | |
| A1 | CLα = 2πA/{2+√[4+(A²β²/η²)(1+tan²Λ_max,t/β²)]}·(S_exp/S_ref)F | R Eq 12.6, p.400 | PDF | cap (S_exp/S_ref)F at 0.98 (p.400, text); Λ_max,t |
| A2 | β² = 1 − M²; η = C_lα/(2π/β); F = 1.07(1 + d/b)² | R Eqs 12.7–12.9, p.400 | PDF | the extract inverts η: see §6 |
| A3 | m = m₀/{1 + m₀(1+τ)/(πAR)} | N Eq 2.9, p.43 | PDF | taper row |
| A4 | C_DLi = C_L²(1+δ)/(πAR) | N Eq 2.10, p.43 | PDF | taper row |
| A5 | τ, δ vs λ (AR 6) and vs AR (λ 1) | N Fig 2.10, p.45 | PDF (digitized, §4) | decision 10 |
| A6 | C_Lmax = 0.9 c_lmax cos Λc/4 | R Eq 12.15, p.405 | PDF | |
| A7 | Δy = 26 t/c (NACA 4-digit); 21.3 t/c (64-series) | R Table 12.1, p.405 | PDF | |
| A8 | C_Lmax = c_lmax(C_Lmax/c_lmax) + ΔC_Lmax | R Eq 12.16 + Fig 12.9, p.406 | PDF (digitized, §4) | Λ_LE |
| A9 | ΔC_Lmax = 0.9 Δc_lmax (S_flapped/S_ref) cos Λ_HL | R Eq 12.21 + Table 12.2, p.415 | PDF | table values are landing values; takeoff 60–80 % |
| A10 | C_D0 = Σ C_f FF Q S_wet / S_ref + C_D,misc + C_D,L&P | R Eq 12.24, p.417 | PDF | |
| A11 | C_f,lam = 1.328/√Re | R Eq 12.26, p.420 | PDF | |
| A12 | C_Fi = 0.455/(log₁₀ Re)^2.58; C_F = C_Fi/(1 + 0.144M²)^0.65 | N Eqs 2.22, 2.25, p.64 | PDF | decision 12 |
| A13 | Re_cutoff = 38.21(ℓ/k)^1.053; k = 0.634e-5 m (smooth paint) | R Eq 12.28 + Table 12.5, p.421 | PDF | |
| A14 | FF_wing = [1 + 0.6/(x/c)_m · t/c + 100(t/c)⁴][1.34 M^0.18 (cos Λ_m)^0.28] | R Eq 12.30, p.422 | PDF | Λ_m = max-thickness sweep |
| A15 | FF_fus = 0.9 + 5/f^1.5 + f/400 | R Eq 12.31, p.422 | PDF | **6th-ed. form**; the extract has the old form |
| A16 | Q: nacelle on wing ≤ 1 D 1.3; low wing filleted ≈ 1.0; tail 1.04–1.05 | R p.425 | PDF | |
| A17 | (C_D0)_W = C_f[1 + L(t/c) + 100(t/c)⁴] R (S_wet/S_ref) | N Eq 13.13, p.336 | extract | L3 alternative (fidelity contrast) |
| A18 | e = 1.78(1 − 0.045A^0.68) − 0.64; e = 4.61(1 − 0.045A^0.68)(cos Λ_LE)^0.15 − 3.1; interpolate 0–30° | R Eqs 12.48–12.49, p.444 | PDF | fails for the 737 (e ≈ 0.40) |
| A19 | K = S K100 + (1−S) K0; K0 = 1/CLα; K100 = 1/(πA) | R Eqs 12.56–12.57, p.447 | PDF | S = 0.93 (airliner, p.450) |
| A20 | e = 1/[(πA/CLα)(1 − S) + S] | R Eq 12.58, p.451 | PDF | |
| A21 | C_D = C_Dmin + K″(C_L − C_ℓmin)² + K′C_L² | N Eq 2.17, p.50 | PDF | camber row |
| A22 | C_Dw = C_DLE + (16/3β)(t/c)²(S_e/S_ref), β cot Λ_LE ≥ 1 | N Eq 13.20, p.342 | extract | F-16 section |
| A23 | C_DLE = (2.56/b) r_LE AR cos²Δ / [1 + 1/(M³ cos³Δ)] | N Eq 7.2, p.177 | extract | r_LE at MAC; reference area: decision 13 |
| A24 | C_d0 = C_DF + 4/√(M²−1)[⟨α_c²⟩ + ⟨(dh/dx)²⟩] + … | N Eqs 2.28–2.31, pp.64–65 | PDF | ⟨α_c²⟩ = (16/3)(h/c)² derived (parabolic mean line) |
| A25 | ΔC_D0,flap = F_flap(C_f/C)(S_flapped/S_ref)(δ_flap − 10) | R Eq 12.61, p.452 | PDF | δ in degrees |
| A26 | ΔC_Di,flap = k_f²(ΔC_L,flap)² cos Λc/4 | R Eq 12.62, p.452 | PDF | |
| A27 | ΔC_D0 gear down (L1 estimate) | Ro Part I Table 3.6 | extract (framework `AeroL1.Delta_CD0`) | |
| A28 | e = 1/[1/(u s) + K C_D0 π A]; s = 1 − 2(d_F/b)²; u = 0.99; K = 0.38 | Nita & Scholz, "Estimating the Oswald Factor from Basic Aircraft Geometrical Parameters", DLRK 2012, Doc. ID 281424, Eqs. 6–8, p. 2 (method of Kroo; K from DC-8/DC-9 flight tests, Shevell) | PDF (AVD References) | Level 2 e (user review 2026-10-17). The notebook variant (1.9316, u = 1, K = 0.375, sweep factor 1 − 0.02A^0.7Λ^2.2) has no source found and is not used. |
| P1 | R = (V/C)(L/D) ln(W_{i−1}/W_i) | R Eq 3.5, p.34 | PDF | C in 1/s for SI |
| P2 | Weight fractions: warmup + takeoff 0.970, climb 0.985 | R Table 3.2, p.34 | PDF | |
| P3 | C = 0.5 1/hr {14.1 mg/(N·s)}, high-bypass cruise | R Table 3.3, p.36 | PDF | |
| P4 | A_wet = A/(S_wet/S_ref); L/D_max = K_LD √A_wet, K_LD = 15.5 | R Eqs 3.11–3.12, pp.39–40 | PDF | L1 rung |
| P5 | (L/D)max vs b/√S_wet | N Fig G.8, p.739 | PDF (digitized) | |
| W1 | W = 0.0051(W_dg N_z)^0.557 S_w^0.649 A^0.5 (t/c)_root^−0.4 (1+λ)^0.1 (cos Λ)^−1 S_csw^0.1 | R Eq 15.25, p.574 | PDF | lb, ft²; Λ at 25 % MAC; S_w trapezoidal |
| W2 | N_z = 1.5 × n_limit; n_limit = 2.5 | R p.576 (N_z definition); 14 CFR 25.303, 25.337 | PDF / eCFR | |
| W3 | Wing areal weight 10 lb/ft² × S_exposed (L2 rung) | R Table 15.2, p.568 | PDF | |
| V1 | V_wf = 0.54(S²/b)(t/c)_r[1 + λτ^½ + λ²τ]/(1+λ)², τ = (t/c)_tip/(t/c)_root | Ro Eqs 6.2–6.3, p.153 | extract | no packaging factor ("dry bays" text) |
| V2 | Jet A-1 0.803 kg/L at 15 °C | R Table 10.5, p.327 | PDF | |
| X1 | T = T_b + L(H − H_b); P = P_b[T_b/T]^(g0 M0/(R* L)); P = P_b exp(−g0 M0 (H − H_b)/(R* T_b)); ρ = P M0/(R* T); a = (γ R* T/M0)^½; μ = βT^1.5/(T + S); ν = μ/ρ | U.S. Standard Atmosphere, 1976: Eqs 23 (p.10), 33a, 33b (p.12), 42 (p.15), 50 (p.18), 51, 52 (p.19); constants pp.3, 4, 9, Table 4 | PDF (NTRS 19770009539) | own helper `isa_si`, no toolbox; agrees with `atmosisa` to 5 digits |
| X2 | V_REF ≥ 1.23 V_SR0; V2MIN ≥ 1.13 V_SR; OEI climb gradient ≥ 2.4 % (twin, at V2, gear up) | 14 CFR 25.125(b)(2)(i)(A), 25.107(b)(1)(ii), 25.121(b)(1) | text (Cornell LII) | L04 |
| X3 | Re = ρVℓ/μ; ℓ = MAC (wing, tail) or length (body) | R Eq 12.25, p.418 | extract | |
| X4 | FF_nacelle = 1 + 0.35/f; f = ℓ/√((4/π)A_max) | R Eqs 12.32, 12.33, p.423 | PDF | |
| X5 | C_fe = 0.0026, civil transport (L2 rung) | R Table 12.3, p.417 | extract | |
| X6 | Leakage and protuberance 2–5 % of CD0, jet transports (3.5 % used) | R Table 12.8, p.431 | extract | |
| X7 | c_d = c_dmin + k″(c_l − c_lmin)² (section polar) | N Eq 2.6a, p.41 | PDF | L02 |
| X8 | C_Dw = C_DLE + (16/3) cot Λ_LE (t/c)² (S_e/S_ref), subsonic LE | N Eq 13.21, p.342 | extract | F-16 sweep row above 51° |
| X9 | ΔC_D0: takeoff flaps 0.010–0.020 (e 0.75–0.80); landing flaps 0.055–0.075; gear 0.015–0.025 | Ro Part I Table 3.6, p.126 | extract | L04, midpoints |
| X10 | α_0L (deg) ≈ −(% camber); c_lα ≈ 2π/rad for all low-speed sections; 6 % camber → Δc_lmax ≈ +0.4 | R p.397; N §7.5, p.178 | PDF / extract | L02, camber row |
| X11 | S = 0.85–0.95 for moderate sweep and a large LE radius | R p.447 | PDF | LE-radius proxy |
| X12 | 1 lb = 0.45359237 kg, 1 ft = 0.3048 m (exact) | NIST SP 811, App. B | — | R Eq 15.25 conversion |

Decision 13: N p.342 puts C_DLE outside the S_e/S_ref factor in Eq 13.20. The N Eq 7.2 note says C_DLE is "referenced to exposed planform area". **Proposal:** multiply C_DLE by S_e/S_ref, and label this as an assumption.

---

## 4. Digitized figure data (from PDF page images)

**N Fig 2.10, p.45, top panel (AR = 6):**

| λ | 0 | .05 | .1 | .15 | .2 | .25 | .3 | .35 | .4 | .5 | .6 | .7 | .8 | .9 | 1.0 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| τ | .147 | .093 | .054 | .029 | .013 | .002 | .001 | .006 | .012 | .032 | .054 | .079 | .105 | .134 | .163 |
| δ | .111 | .078 | .054 | .036 | .024 | .016 | .011 | .006 | .0045 | .007 | .014 | .025 | .037 | .050 | .066 |

**N Fig 2.10, p.45, bottom panel (λ = 1):**

| AR | 2.1 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|
| τ | .077 | .099 | .122 | .144 | .166 | .183 | .198 | .212 | .224 |
| δ | .007 | .017 | .028 | .038 | .047 | .055 | .063 | .071 | .078 |

AR 11.1 is outside the curve, so the lesson holds the AR 10 value and states this.

**R Fig 12.9, p.406 (C_Lmax/c_lmax at M ≈ 0.2, untwisted wings):**

| Λ_LE | Δy ≤1.4 | 1.6 | 1.8 | 2.0 | 2.2 | 2.4 | ≥2.5 |
|---|---|---|---|---|---|---|---|
| 0 | .90 | .90 | .90 | .90 | .90 | .90 | .90 |
| 10 | .93 | .92 | .92 | .90 | .89 | .87 | .87 |
| 20 | .97 | .96 | .93 | .90 | .87 | .85 | .84 |
| 30 | 1.03 | 1.00 | .95 | .89 | .85 | .81 | .79 |
| 40 | 1.10 | 1.05 | .97 | .88 | .82 | .76 | .73 |
| 50 | 1.19 | 1.11 | 1.00 | .87 | .78 | .69 | .65 |
| 60 | 1.30 | 1.19 | 1.02 | .86 | .73 | .59 | .52 |

**R Fig 4.11, p.69 (NACA 24XX, section c_d):**

| t/c % | 6.3 | 8 | 10 | 12 | 14 | 16 | 18 |
|---|---|---|---|---|---|---|---|
| c_l = 0 | .0047 | .0054 | .0060 | .0065 | .0068 | .0070 | .0072 |
| c_l = 1.0 | .0068 (at 6 %) | .0079 | .0086 | .0090 | .0093 | .0095 | .0096 |

**R Fig 4.13, p.70 (c_lmax):**

| t/c % | 6 | 8 | 10 | 12 | 14 | 16 | 18 |
|---|---|---|---|---|---|---|---|
| 24XX | 1.32 | 1.50 | 1.61 | 1.66 | 1.66 | 1.62 | 1.55 |
| 14XX | – | 1.31 | 1.48 | 1.61 | – | – | – |
| 00XX | 0.82 | 1.08 | 1.33 | 1.54 | – | – | – |

The camber row uses the values at t/c 12 %: 0 % → 1.54, 1 % → 1.61, 2 % → 1.66, and 4 % → 1.67 (N Table F.1, NACA 4412).

**R App D (pp.981–982, R 9e6, smooth):**

| | cl_max | cl_α /deg | α_0L | LE radius % c |
|---|---|---|---|---|
| NACA 2415 | ≈1.64 | ≈0.101 | ≈−2.0° | 2.48 |
| NACA 4415 | ≈1.63 | ≈0.105 | ≈−4.1° | 2.48 |

The LE radii printed for the other App D sections (% c) are: 0006 0.40, 0009 0.89, 64-006 0.256.

**N Fig G.8, p.739 ((L/D)max against x = b/√S_wet):**

| x | 1.0 | 1.2 | 1.4 |
|---|---|---|---|
| upper line (e/C_f = 318) | 16.0 | 19.2 | 22.4 |
| centre line | 14.6 | 17.5 | 20.5 |
| lower line (e/C_f = 206) | 12.3 | 14.9 | 17.5 |

---

## 5. Final trend matrix (method per cell)

"NO EFFECT" means |Δ| < 3 % of the aircraft value over the range.
- **(✗)** means the model result is expected to disagree with Nicolai Table 7.1 (N p.193).
- **proxy** means no source relates the variable to the metric directly, so the lesson uses a labelled stand-in.

### A. B737 MAX 8, cruise M 0.785 at 35,000 ft

| Increase | CD0 sub | K | CLα | CLmax | Wing wt | Wing vol |
|---|---|---|---|---|---|---|
| AR 6–14 | A10 with G4 S_exp + Re (✗ ↑) | A19 (L3) ↓; A18 (L2) fails | A1 ↑ | A6 no AR (✗); N Fig 2.9 data ↑ | W1 ↑ | V1 ↓ |
| Sweep, aft 0–40° and fwd −20–0° | A14 FF (≈ −3 %, at the limit) | A19 via A1 ↑; A18 uses abs(Λ) (assumption) | A1 ↓ | A6 aft ↓; fwd ↓ (✗) | W1 ↑ | V1, no Λ term: no effect |
| Taper 0–1 | A10 via S_exp + MAC (✗) | A4 + A5 δ ↓↑ | A3 + A5 τ ↑↓ | A6, no λ term: no effect | W1 ↑ | V1 ↓ |
| t/c 0.08–0.16 | A14 + G4 + R Fig 4.11 (✗ ↑) | A19, no t/c term: no effect | A1, no t/c term: no effect | R Fig 4.13 24XX + A6 (peak at 13 %) | W1 ↓ | V1 ↑ |
| LE radius | no term; N p.176 says "not influenced by nose shape" | A19 with S as proxy | no term | proxy: NACA 00XX family, r_LE ∝ (t/c)² (R App D), R Fig 4.13 00XX + A8 Δy | no term | not modelled (stated) |
| Camber 0–4 % | A21 at C_L = 0 (assumption CL_min ≈ 0.1 × camber %, anchored on the R App D drag buckets) ↑ | A21 effective K at cruise CL ↓ | R App D 2415 vs 4415 ≈ +4 % section → < 3 % wing: no effect | R Fig 4.13 + N Table F.1 ↑ (1.54 → 1.67) | no term | no term |

K″ for the camber row (as built): K″ = (1 − S)(K0 − K100), the part of K that leading-edge suction does not recover (assumption, ≈ 0.009). The N Eq 2.17 C-141A example value (0.02, p.50) was not used: with it the effective-K change at cruise was implausibly large.

Camber row, CLα (as built): the section lift slope is held, per N §7.5 ("C_lα ≈ 2π/rad" for all low-speed sections). The R App D difference (0.101 against 0.105 per deg) is not used, because 0 % camber has no data.

**Result as built (L05 scorecard): 35 of 43 cells agree.** The 8 that do not: AR → CD0 sub (↑ 5 %), AR → CD0 sup (no effect, F-16), AR → CLmax (no AR term), taper → CD0 sub (↑ 6 %), t/c → CD0 sub (↑ 7 %), t/c → CLmax (↓↑, effects cancel), LE radius → wing volume (not modelled), forward sweep → CLmax (↓, symmetric equations).

### B. F-16A, CD0 supersonic, M 1.60 at 40,000 ft — REMOVED (user review 2026-10-18)

| Increase | Method |
|---|---|
| AR | A23 with r_LE ∝ MAC: AR cancels → no effect (✗). Nicolai's source (Fig H.6) is not available. |
| Sweep | A23 cos²Δ + A22 ↓ |
| Taper | A23 via MAC/c̄ and Λ_LE |
| t/c | A22 ↑ |
| LE radius 0–0.25 % c | A23 ↑ |
| Camber 0–4 % | A24, derived ⟨α_c²⟩ ↑ |

---

## 6. Errors found in `docs/reference_extracts/` (not edited, for your decision)

These files are outside `teaching/`, so I did not change them.

| File | Error | Correct (page image) |
|---|---|---|
| Raymer 12_aerodynamics.md | Eq 12.8 inverted | η = C_lα/(2π/β), p.400 |
| Raymer 12_aerodynamics.md | Eq 12.31 = 1 + 60/f³ + f/400 | 6th ed.: 0.9 + 5/f^1.5 + f/400, p.422 (the old form is from prior editions) |
| Raymer 12_aerodynamics.md | Eq 12.61 with (cf/c)^1.38, no −10 | F_flap(C_f/C)(S_flapped/S_ref)(δ − 10), p.452 |
| Raymer 12_aerodynamics.md | Eq 12.62 without k_f² and cos Λ | k_f²(ΔC_L)² cos Λc/4, p.452 |
| Raymer 12_aerodynamics.md | Fig 12.9 one curve, 1.0 → 0.55 | Δy family, all curves start at 0.90 (§4) |
| Raymer 04_*.md | Figs 4.11, 4.13 single curves | two and four curves (§4) |
| Raymer D_airfoil_data.md | chart pages 978–979 | pp.981–982 |
| Raymer 12_aerodynamics.md | section numbers | book §12.4.1 = extract §12.3.1, and so on |
| Nicolai 02_*.md | Fig 2.10 tables; "zero taper" read as λ = 0 | §4; the bottom panel is λ = 1 |
| Nicolai 02_*.md | Fig 2.9 table has C_L = 0 at α = 0 | α_0L ≈ −2.3°; CLmax 1.51 / 1.27 / 1.08 / 0.85 at AR ∞ / 10 / 5 / 1 |
| Nicolai 02_*.md | Eq 2.27 corrected silently | the print has a typo "4α" (use 4/√(M²−1), as Eq 2.31) |
| Nicolai 13_*.md | Eq 13.22 d_equiv from S_S (likely) | probably S_B. Not checked: no PDF. |

---

## 7. HW notebook errors (the lesson does not copy them)

1. c35 `np.cos(Lambda)` with degrees. Eqs 12.48/12.49 want Λ_LE, but the notebook uses Λc/4. The interpolation itself gives e ≈ 0.40 at the 737 AR.
2. c38 Shevell `df/b**2` must be `(df/b)**2`. `k` overwrites the section-polar `k` from c23.
3. c13 `S_nacelle = π·d` is a length, but c63 uses it as an area.
4. c63 tail CD0 = `CD0_wing·(S_ht+S_vt)/Sref`. CD0_wing is already referenced to Sref, so this scales twice. It also uses the planform area, not the wetted area.
5. c30/31 units:
   - 0.0293 is kgf·s²/m⁴, but the label says kg/m³.
   - W is in kgf.
   - Re is in English units.
   - "759.515 knots" is in ft/s.
6. Planform:
   - c6: the trapezoid with root 7.88 m and tip 1.25 m gives 163.9 m² at b = 35.90 m. The JSR reference area is 124.6 m².
   - c8: ×1.2 for winglets on a span that already includes the winglets.
7. c31: cruise at 41,000 ft with W = MTOW makes CL too high.
8. c57: Fig 13.8 R is read at M 0.8 but used at takeoff (M ≈ 0.21).
9. c55 and c39:
   - c55: a Cf cut-off Re of 5e7 has no source. R Eq 12.28 gives a roughness-based cut-off.
   - c39: averages three e values, and two of them are wrong.
10. Input data:
    - "VT span 12.42 m" is the overall aircraft height (b737.org.uk).
    - The nacelle 2.06 m is the CFM56-7 value, not the LEAP-1B.
    - 82,190 kg is the 737-8-200 MTOW.
11. c21 says "Maximum cl/cd occurs at the minimum drag". For the polar of N Eq 2.6a the maximum is at c_l = √(c_dmin/k″ + c_lmin²) ≈ 0.95, with c_l/c_d ≈ 129, not 100 at c_l = 0.6. (Found while writing L02; not fixed in the corrected notebook, which fixes items 1–10 only.)

---

## 8. Review changes (2026-10-17)

- L01: old-homework references removed (user). Sweep conversion cited to Gudmundsson Eq. 9-11, p. 305. Half-wing plot added.
- L02 (user request): Nicolai Table F.1 and the annotated Abbott & von Doenhoff NACA 4412 chart (App. IV, pp. 488-489) are embedded as images. Files: `mlx_src/images/` (`images.json` manifest); the build embeds them (`make_student_package>with_images`). Copyright: both are scans of book pages; the repo is on GitHub.
- L02 now derives the section polar from the chart readings (`book_data().avd4412`, Re = 9e6 curve): c_d,min = 0.0060 at c_l = 0.6; c_d = 0.010 at c_l = 1.2; c_d = 0.0062 at c_l = 0. Results: k'' = 0.0111; c_l/c_d = 100 at minimum drag; maximum c_l/c_d = 129 at c_l = 0.95; c_d = 0.0187 at c_l,max = 1.67; the parabola gives c_d = 0.0100 at c_l = 0 (chart 0.0062).
- Three handwritten slips on the annotated chart, stated in L02: "c_lmin = 0.04" and "c_l = 0.06" should read 0.6; "(c_l/c_d)_max = 100" is the value at minimum drag (the maximum is about 129).
- `book_data.m` header: TODO (Casey) to cross-check every digitized block, with pages.
- Rendering fixes in all scripts: LaTeX backslashes are written as `\\` (a single `\r` or `\n` became a line break); no blank lines except before `%[appendix]` (they rendered as empty code boxes); no `°` inside math (use `\\degree`); every list ends with ` \`.
- L03 (user review): Level 2 has two e methods, A = Raymer Eqs. 12.48/12.49 (fails, e ≈ 0.40), B = Kroo/Shevell (A28, e ≈ 0.80, used by Level 2 everywhere). (L/D)max: L1 18.8, L2-A 14.6, L2-B 20.4, L3 18.3. L05 "In class 2" plots K against AR for A, B and Level 3.
- More rendering rules (build check rules 5–7): every `_` inside math written `\_` (two bare underscores read as emphasis: (L/D)_max lost its subscripts); `[` `]` inside math escaped; a final ` \` only on the last item of a list.
- L05 (user review 2026-10-18): Nicolai Table 7.1 image (replaces the arrow table) and Fig. 2.9 image added; the F-16 removed completely (supersonic section, helpers f16_wing_baseline / trend_f16 / plot_f16_trends / cd0_supersonic_wing, and their test); the forward-sweep part removed; trend_table returns only the 6 x 6 subsonic grid (no long table, no agreement count); 30 of 36 cells agree. "S" (leading-edge suction) defined in L03 and L05. Math moved out of bold text (it does not render inside **...**; build check rule 8).
- LAB01 (user review 2026-10-18): every term defined (MTOW, ZFW, MZFW, fuel mass, m_start, m_end, C, A_eff, S_LE, N_z, S_csw) and every step has its equation rendered; in-class / at-home split removed (TODO 1-5). LAB01_SOLUTION has a 7-question Canvas quiz (5 numerical, answers and tolerances computed live; 2 multiple choice).
- LAB01 quiz (user review 2026-10-18): "Questions and Answers" and "Canvas quiz" merged into one 10-question quiz in LAB01_SOLUTION (Q1-Q6 numerical, Q7-Q10 multiple choice, correct letters mixed). The quiz is on Canvas only, so the stub has no quiz section.
- A01 removed from the student package (user 2026-10-18). The cross-check is now an instructor task for Casey: `crosscheck_framework.m` (lesson root, not shipped) runs the same 11 rows against the repository `src/`. The build has no `framework` step, and `student_package/framework/` is gone. No toolbox is necessary for the student package. See the TODO (Casey) section in `FRAMEWORK_FINDINGS.md`.
