# Chapter 2 — Review of Practical Aerodynamics

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 2 "Review of Practical Aerodynamics," printed pp. 33–70.

Organized by book section. Every numbered equation `(2.x)`, unnumbered displayed
equation, table, and figure is captured. Data graphs are tabulated (values *read
from plot* unless an explicit formula is printed on the chart, in which case values
are *computed from that formula*).

---

## §2.1 Introduction

### Fig 2.1 — Wing geometry and nomenclature *(definitions figure)*
*[Nicolai & Carichner, Fig. 2.1, p. 34]*

- `S_ref` = wing area (ft²); `b` = span (ft); `c` = average chord (ft)
- Aspect ratio: `AR = b/c = b² / S_ref`
- `C_R` = root chord (ft); `C_T` = tip chord (ft); taper ratio `λ = C_T / C_R`
- `Λ` = sweep angle (deg)  *(the figure labels the sweep symbol "Δ")*
- Mean aerodynamic chord: `mac = c̄` and
  **`mac = (2/3) · C_R · (1 + λ + λ²) / (1 + λ)`**
- Airfoil nomenclature (labeled on the figure): leading-edge radius, leading edge,
  location of max thickness, maximum thickness, mean camber line, chord line,
  upper/lower surface, location of maximum camber, maximum camber, chord, trailing edge.

### Fig 2.2 — Langley 30 × 60-ft wind tunnel with the X-48B in the test section
*[Nicolai & Carichner, Fig. 2.2, p. 35]* — Photograph, no plotted data.

---

## §2.2 Drag

### Fig 2.3 — Major nondimensional aerodynamic parameters and sign convention *(definitions figure)*
*[Nicolai & Carichner, Fig. 2.3, p. 35]*

Force coefficients:
- `C_L = L / (q·S_ref)`  (lift)
- `C_D = D / (q·S_ref)`  (drag)
- `C_Y = Y / (q·S_ref)`  (sideforce)

Moment coefficients:
- `C_m = m / (q·S_ref·c̄)`  (pitching)
- `C_l = 𝓛 / (q·S_ref·b)`  (rolling)
- `C_n = n / (q·S_ref·b)`  (yawing)

Stability derivatives:
- `C_Lα = ΔC_L/Δα`, `C_mα = ΔC_m/Δα`, `C_nβ = ΔC_n/Δβ`, `C_lβ = ΔC_l/Δβ`, `C_Yβ = ΔC_Y/Δβ`

Control effectiveness:
- `C_mδe = ΔC_m/Δelev`, `C_lδa = ΔC_l/Δaileron`, `C_nδr = ΔC_n/Δrudder`

Dynamic pressure: `q = ½·ρ·V²`. Positive moments follow the right-hand rule.

**Drag taxonomy (text, §2.2):** parasite drag is composed of skin-friction drag,
pressure (form) drag, base drag, wave drag (supersonic only), excrescence/protuberance
drag, cooling drag, and ram drag. *(Conceptual definitions — no equations.)*

### Aerodynamic coefficient definitions
- **Eq (2.1):** `C_L = L / (q·S_ref)`  *[Nicolai & Carichner, Eq. (2.1), p. 36]*
- **Eq (2.2):** `C_D = D / (q·S_ref)`  *[Nicolai & Carichner, Eq. (2.2), p. 36]*
- **Eq (2.3):** `C_MA = M_A / (q·S_ref·c̄)`  *[Nicolai & Carichner, Eq. (2.3), p. 36]*

### Fig 2.4 — Wing surface pressure distributions for airfoil designed for long endurance — **DATA GRAPH + data tables**
*[Nicolai & Carichner, Fig. 2.4, p. 36]*

Plots `C_p` vs `x/c` (0–1) for upper/lower surfaces at several α, with the pressure
coefficient defined as `C_p = (P − P∞)/q∞`, `q∞ = ½·ρ∞·V∞²`.

Embedded table — **ISES Results for JW 1416** (Mach = 0.6, Re = 9 million):

| α (deg) | C_l | C_d | C_m |
|---|---|---|---|
| 0.0 | 0.0698 | 0.00617 | 0.008 |
| 4.0 | 0.6780 | 0.00717 | 0.011 |
| 6.0 | 0.9382 | 0.02165 | 0.017 |

Embedded table — **Measured Results for LRN 1015** (Mach = 0.6, C_l = 0.912):

| Source | α (deg) | C_d | C_m |
|---|---|---|---|
| LBAUER | 1.77 | 0.0099 | −0.1072 |
| ISES   | 1.43 | 0.0091 | −0.1221 |
| EXP    | 1.11 | 0.0072 | −0.1137 |

---

## §2.3 Boundary Layers and Skin Friction Drag

- **Reynolds number (local):** `Re_x = ρ·V·x/μ`; boundary layer transitions
  laminar→turbulent at `Re_x ≈ 5 × 10⁵`. *(unnumbered)*
- **Surface friction force** ≈ `μ · (dv/dz) · (area)`, with `dv/dz` evaluated at the
  surface (z = 0). *(unnumbered)*
- **Laminar BL thickness:** `δ_L = 5.2·x / Re_x^0.5` *(unnumbered, p. 39)*
- **Turbulent BL thickness:** `δ_T = 0.37·x / Re_x^0.2` *(unnumbered, p. 39)*
- Flow separates when `dv/dz = 0` at the surface.

### Fig 2.5 — Boundary layer profile: three flow conditions
*[Nicolai & Carichner, Fig. 2.5, p. 39]* — Diagram of velocity profiles v(z) for
laminar, turbulent, and separated boundary layers (annotations reproduce the
δ_L, δ_T, and transition relations above). No plotted data curve.

- **Skin-friction drag force:** `= C_F · (surface area) · (dynamic pressure)` *(unnumbered)*

### Fig 2.6 — Skin friction coefficient over a flat plate — **DATA GRAPH (formulas printed)**
*[Nicolai & Carichner, Fig. 2.6, p. 40]*

Log–log plot of `C_F` (10⁻⁴ … 0.1) vs `Re_L` (10⁴ … 10⁹), with curves for M∞ = 0, 4, 8.
Characteristic length `Re_L = ρ∞·V∞·L/μ`. Printed formulas:

- Laminar: `C_F = 1.328 / √(Re_L)`
- Turbulent: `C_F = 0.074 / Re_L^0.2`
- Turbulent (alt., Schlichting): `C_F = 0.455 / [log₁₀ Re_L]^2.58`
- Transitional: `C_F = 0.455/[log₁₀ Re_L]^2.58 − 1700/Re_L`

Tabulated **(computed from the printed formulas, M∞ = 0)**:

| Re_L | Laminar `1.328/√Re` | Turbulent `0.455/(log₁₀Re)^2.58` |
|---|---|---|
| 1e4 | 0.01328 | — |
| 1e5 | 0.00420 | 0.00715 |
| 1e6 | 0.00133 | 0.00447 |
| 1e7 | 0.00042 | 0.00300 |
| 1e8 | —       | 0.00213 |
| 1e9 | —       | 0.00157 |

---

## §2.4 Incompressible Airfoil Section Theory

- **Section lift-curve slope (thin-airfoil theory):**
  `dC_l/dα = m₀ = 2π per radian` *(unnumbered, p. 40; Refs [1] p.73, [2] p.34)*
- **Aerodynamic center** location = quarter chord = `¼·c̄`. *(unnumbered)*
- **Eq (2.4):** `α_ol = −(1/π) · ∫₀^π (dz/dx)(cos θ − 1) dθ`  *[Nicolai & Carichner, Eq. (2.4), p. 40]*
- **Eq (2.5):** `C_m,a.c. = −(1/2) · ∫₀^π (dz/dx)(cos 2θ − cos θ) dθ`  *[Nicolai & Carichner, Eq. (2.5), p. 40]*

  where `dz/dx` is the local slope of the camber line, the change of variable is
  `x = (c/2)(1 − cos θ)`, and `c` is the airfoil chord. `C_m,a.c.` is constant with
  changing `C_l` or α by definition of the aerodynamic center.

### §2.4 (continued) — Section lift and drag behavior

- **Linear section lift:** `C_l = m₀·(α − α_ol)` *(unnumbered, p. 41)*.
  `α_ol` = 0 for symmetric/uncambered sections (dz/dx = 0), e.g. NACA 0012.
- **Eq (2.6a):** `C_d = C_dmin + k″·(C_l − C_l,min)²`  *[Nicolai & Carichner, Eq. (2.6a), p. 41]*
  - `k″ = Δ(C_d − C_dmin) / Δ(C_l − C_l,min)²` = viscous drag-due-to-lift factor *(unnumbered def., p. 42)*.
- **Eq (2.6b):** `C_d = C_do + k″·C_l²` (symmetric sections, C_l,min = 0)  *[Nicolai & Carichner, Eq. (2.6b), p. 42]*
  - `C_do` = zero-lift drag coefficient (separation + skin friction at C_l = 0).
  - NACA 24XX family: `k″ ≈ 0.0047` at Re = 3×10⁶ (per Appendix F).

#### Fig 2.7 — Section lift data (NACA 0012 & 2415) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.7, p. 41]* — `C_l` vs α (deg), Re = 9×10⁶, smooth surface.
Theoretical (thin-airfoil) linear lines, slope `m₀ = 2π/rad = 0.1097/deg`:

| α (deg) | C_l NACA 0012 (α_ol = 0) | C_l NACA 2415 (α_ol ≈ −2°) |
|---|---|---|
| −2 | −0.22 | 0.00 |
| 0  | 0.00 | 0.22 |
| 4  | 0.44 | 0.66 |
| 8  | 0.88 | 1.10 |
| 12 | 1.32 | 1.54 |

Experimental (dashed): C_l,max ≈ 1.6 near α ≈ 16–17° for both, then stall *(read from plot)*.

#### Fig 2.8 — Section C_d and C_m,a.c. data (NACA 0012 & 2415) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.8, p. 42]* — Re = 9×10⁶, smooth surface.

Drag polar (NACA 2415, experimental), `C_d` vs `C_l` *(read from plot)*:

| C_l | C_d (2415) |
|---|---|
| 0.0 | ~0.0065 (= C_do) |
| 0.2 | ~0.0060 (= C_dmin, at C_l,min) |
| 0.4 | ~0.0065 |
| 0.8 | ~0.0080 |
| 1.2 | ~0.0110 |
| 1.5 | ~0.0140 |

Moment (C_m,a.c. vs C_l): NACA 0012 → `C_m,a.c. ≈ 0.0` (constant); NACA 2415 → `C_m,a.c. ≈ −0.05` (constant).

---

## §2.5 Subsonic Compressibility Corrections

- **Eq (2.7)** — Prandtl–Glauert lift-curve-slope correction:
  `(m₀)_{M≠0} = (m₀)_{M=0} / √(1 − M²)`  *[Nicolai & Carichner, Eq. (2.7), p. 43]*
  - Compressibility increases the section lift-curve slope; theory/experiment agree for
    `0 < M < 0.8`, breaking down beyond M = 0.8.

---

## §2.6 Finite Wing Corrections

- **Eq (2.8)** — induced angle-of-attack: `α_i = (C_L/(π·AR))·(1 + τ)`  *[Nicolai & Carichner, Eq. (2.8), p. 43]*
- **Eq (2.9)** — finite-wing lift-curve slope: `m = dC_L/dα = m₀ / {1 + [m₀(1 + τ)/(π·AR)]}`  *[Nicolai & Carichner, Eq. (2.9), p. 43]*
- **Eq (2.10)** — induced (drag-due-to-lift): `C_D_Li = C_L²(1 + δ)/(π·AR) = K′·C_L²`  *[Nicolai & Carichner, Eq. (2.10), p. 43]*
  - `τ`, `δ` = corrections for deviation from elliptical lift distribution (functions of AR
    and taper ratio, given in Fig 2.10). `K′` = inviscid drag-due-to-lift factor.

#### Fig 2.9 — Effect of finite span on lift (NACA 65-410) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.9, p. 44]* — `C_L` vs α (deg), curves for AR = ∞, 10, 5, 1.
Approximate linear-region values *(read from plot)*:

| α (deg) | AR = ∞ | AR = 10 | AR = 5 | AR = 1 |
|---|---|---|---|---|
| 0  | 0.00 | 0.00 | 0.00 | 0.00 |
| 4  | 0.44 | 0.40 | 0.34 | 0.10 |
| 8  | 0.88 | 0.78 | 0.64 | 0.20 |
| 12 | ~1.30 | 1.10 | 0.92 | 0.32 |
| 16 | ~1.45 (max ≈15°) | 1.28 | 1.08 | 0.45 |
| 20 | (stalled) | ~1.30 (max) | 1.15 | ~0.60 + nonlinear lift |

Higher AR → steeper lift-curve slope and higher C_L,max; low AR (=1) shows a strong
nonlinear-lift contribution at high α.

---

## §2.7 Sweep Correction

- **Eq (2.11):** `m = (m)_{Δ=0}·cos Δ`, for AR > 6  *[Nicolai & Carichner, Eq. (2.11), p. 44]*
- **Eq (2.12):** `m = (m)_{Δ=0}·√(cos Δ)`, for AR < 6  *[Nicolai & Carichner, Eq. (2.12), p. 44]*
  - `Δ` = sweep angle of the quarter-chord (or maximum-thickness) line. Sweep reduces
    the lift-curve slope. (Only the velocity component ⟂ to the ¼-chord sets the pressure
    distribution; the tangential component flows spanwise — see Fig 2.11.)

#### Fig 2.10 — Correction factors (τ, δ) for nonelliptic lift distribution — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.10, p. 45]* (data from Ref. [4])

Top plot — τ, δ vs taper ratio `λ = C_t/C_r` at AR = 6 *(read from plot)*:

| λ | τ | δ |
|---|---|---|
| 0.0  | ~0.16 | ~0.11 |
| 0.2  | ~0.05 | ~0.03 |
| 0.35 | ~0.02 (min) | ~0.01 (min) |
| 0.6  | ~0.06 | ~0.03 |
| 0.8  | ~0.11 | ~0.06 |
| 1.0  | ~0.17 | ~0.09 |

Bottom plot — τ, δ vs Aspect Ratio (zero taper) *(read from plot)*:

| AR | τ | δ |
|---|---|---|
| 2  | ~0.08 | ~0.01 |
| 4  | ~0.14 | ~0.03 |
| 6  | ~0.18 | ~0.04 |
| 8  | ~0.21 | ~0.05 |
| 10 | ~0.22 | ~0.06 |

#### Fig 2.11 — Normal component of V∞ establishes pressure distribution over wing station
*[Nicolai & Carichner, Fig. 2.11, p. 45]* — Diagram: unswept vs swept wing showing
velocity components `V∞·cos Δ` (⟂ to ¼-chord) and `V∞·sin Δ` (spanwise). No plotted data.

---

## §2.8 Combined Effects

- **Eq (2.13)** — subsonic lift-curve slope combining sweep, finite span, compressibility:

  `dC_L/dα = C_Lα = 2π·AR / { 2 + √[ 4 + AR²·β²·(1 + tan²Δ/β²) ] }`  *[Nicolai & Carichner, Eq. (2.13), p. 46]*

  where `AR = (span)²/(wing area)`, `β = √(1 − M²)`, `Δ` = sweep of the maximum-thickness line.

---

## §2.9 Nonlinear Wing Lift and Moment

- Linear approximation (high-AR only): `C_L = (dC_L/dα)·α` *(unnumbered, p. 46)*
- **Eq (2.14)** — nonlinear wing lift (α in radians):
  `C_L = (dC_L/dα)_{α=0}·α + C₁·α²`  *[Nicolai & Carichner, Eq. (2.14), p. 46]*
- **Eq (2.15)** — nonlinear moment about wing apex (α in radians):
  `C_M = (dC_M/dα)_{α=0}·α + C₂·α²`  *[Nicolai & Carichner, Eq. (2.15), p. 47]*
  - `(dC_L/dα)_{α=0}` from Eq (2.13); `C₁` = nonlinear lift factor, `C₂` = nonlinear moment factor.
  - Values of C₁, C₂ from Fig 2.13 for **sharp-edged** wings; use `0.5·C₁` and `0.45·C₂` for
    **round leading edges**. Nonlinearity is significant for AR ≲ 3 (comparable to the linear
    part at AR = 1).

#### Fig 2.12 — Vortex configurations past slender bodies
*[Nicolai & Carichner, Fig. 2.12, p. 47]* — Diagram (rectangular wing, delta wing, body of
revolution) showing free-vortex rollup. No plotted data.

#### Fig 2.13 — Values of C₁ and C₂ for various planform shapes and aspect ratios — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.13, p. 48]* — curves for rectangular, delta, and swept planforms.

`C₁` vs Aspect Ratio *(read from plot)*:

| AR | Rectangular | Delta | Swept |
|---|---|---|---|
| 0.5 | ~12 | ~11 | ~4 |
| 1   | ~11 | ~9  | ~3.5 |
| 2   | ~7  | ~4  | ~2.5 |
| 3   | ~4.5 | ~1.5 | ~2 |
| 4   | ~3  | ~0.7 | ~1.5 |
| 6   | ~2  | ~0.3 | ~1 |

`−C₂` vs Aspect Ratio *(read from plot)*:

| AR | Swept | Rectangular | Delta |
|---|---|---|---|
| 0.5 | ~5   | ~4.7 | ~2 |
| 1   | ~4.5 | ~4   | ~1.5 |
| 2   | ~3.5 | ~3   | ~1 |
| 3   | ~3   | ~2.3 | ~0.8 |
| 4   | ~2.6 | ~1.9 | ~0.7 |
| 6   | ~2.2 | ~1.5 | ~0.5 |

#### Fig 2.14 — Vortex rollup photos (F-18 / F-22)
*[Nicolai & Carichner, Fig. 2.14, p. 48]* — (a) F-18 in high-g maneuver; (b) F-22 vortex
shedding from LEX and swept wing. Photographs, no plotted data.

---

## §2.10 Total Aircraft Subsonic Aerodynamics

- **Eq (2.16)** — total wing drag coefficient: `C_D = C_D0 + C_DLv + C_DLi`  *[Nicolai & Carichner, Eq. (2.16), p. 48]*
  - `C_DLv` = viscous drag-due-to-lift; `C_DLi` = induced (inviscid) drag-due-to-lift.

- **Eq (2.17)** — cambered-wing drag polar:
  `C_D = C_Dmin + K″·(C_L − C_Lmin)² + K′·C_L²`  *[Nicolai & Carichner, Eq. (2.17), p. 50]*
  - `C_Lmin` = the C_L at C_dmin from the airfoil drag polar (Fig 2.8).
- **Eq (2.18)** — uncambered simplification (C_Lmin = 0):
  `C_D = C_D0 + K″·C_L² + K′·C_L² = C_D0 + K·C_L²`  *[Nicolai & Carichner, Eq. (2.18), p. 50]*
- **Drag-due-to-lift factor** (early design): `K = 1/(π·AR·e)` *(unnumbered, p. 51)*, where
  `e` = wing planform efficiency factor (Fig G.9).

#### Fig 2.16 — Low-speed drag polar (M ≤ 0.4) for C-141A, clean configuration — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.16, p. 50]* — `C_L` vs `C_D`, with L/D on the top axis.
Worked example parameters (text): AR = 7.9, sweep = 25°, λ = 0.374, `C_Lα = 0.084/deg`,
`C_Lmin = 0.27`, `C_Dmin = 0.016`, `K″ = 0.02`, `K′ = 0.0407`.
Polar **computed from Eq (2.17)** `C_D = 0.016 + 0.02(C_L−0.27)² + 0.0407·C_L²`:

| C_L | C_D | L/D |
|---|---|---|
| 0.00 | 0.0175 | 0 |
| 0.27 | 0.0190 | 14.2 |
| 0.50 | 0.0252 | 19.8 |
| 0.70 | 0.0396 | 17.7 |
| 0.80 | 0.0477 | 16.8 |
| 1.00 | 0.0674 | 14.8 |

(Text confirms C_D = 0.0252 at C_L = 0.5, matching experiment.)

#### Fig 2.17 — F-4C aerodynamics, Mach 0.8 — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.17, p. 51]* — `C_L` vs `C_D`; AR = 2.82, λ = 0.236, t/c = 5%,
Series 64A, Δ = 45°, effectively uncambered, `K = 0.169`. Shows parabolic region up to the
**break lift coefficient** `C_LB`, above which C_D departs from parabolic by `ΔC_DB`.
Approximate polar *(read from plot; parabolic part `C_D ≈ 0.02 + 0.169·C_L²`)*:

| C_L | C_D |
|---|---|
| 0.0 | ~0.020 |
| 0.2 | ~0.027 |
| 0.4 | ~0.047 |
| 0.5 | ~0.062 (≈ C_LB) |
| 0.6 | ~0.085 (departs parabolic) |
| 0.8 | ~0.14 |

- **Eq (2.19a)** — drag polar with break (low-AR, high-α): `C_D = C_D0 + K·C_L² + K_B·(C_L − C_LB)²`  *[Nicolai & Carichner, Eq. (2.19a), p. 51]*
- **Eq (2.19b)** — break drag-due-to-lift factor: `K_B = 0` for `C_L ≤ C_LB`; `K_B > 0` for `C_L > C_LB`  *[Nicolai & Carichner, Eq. (2.19b), p. 51]*

#### Zero-lift drag build-up

- **Eq (2.20):** `C_D0 = C_DPmin + C_DF`  *[Nicolai & Carichner, Eq. (2.20), p. 52]*
  - `C_DPmin` = pressure drag due to viscous separation (experimental, small vs C_DF).
- **Skin-friction drag coefficient:** `C_DF = C_F·(S_wet/S_ref)` *(unnumbered, p. 52)*, `S_wet` = wetted area.
- **Eq (2.21):** laminar (Re_l < 5×10⁵): `C_F = 1.328/√(Re_l)`, `Re_l = ρ·V∞·c̄/μ`  *[Nicolai & Carichner, Eq. (2.21), p. 52]*
- **Eq (2.22):** turbulent (Re_l > 5×10⁵): `C_F = 0.455/[log₁₀ Re_l]^2.58`  *[Nicolai & Carichner, Eq. (2.22), p. 52]*
  (Eqs 2.21–2.22 are plotted in Fig 2.6.)
- **Rule of thumb (subsonic):** `C_D0 ≈ 1.2·C_DF` (thin wings/streamlined bodies are 70–80% skin friction). *(unnumbered, p. 52)*
- **Cone nose correction:** `C_Fcone = (2/√3)·C_F,flat plate` *(unnumbered, p. 53)*.
- **Eq (2.23)** — total aircraft skin-friction coefficient:
  `(C_DF)_a/c = C_Ffuse·(S_F/S_ref) + C_Fnose·(S_N/S_ref) + C_Fwing·(S_W/S_ref) + C_Ftail·(S_T/S_ref)`  *[Nicolai & Carichner, Eq. (2.23), p. 53]*
- **Eq (2.24)** — total aircraft zero-lift drag (with 5% mutual interference):
  `(C_D0)_a/c = 1.25·(C_DF)_a/c`  *[Nicolai & Carichner, Eq. (2.24), p. 53]*

#### Fig 2.18 — Aircraft components for skin friction estimation
*[Nicolai & Carichner, Fig. 2.18, p. 53]* — Diagram labeling wetted-area components
`S_N` (nose), `S_F` (fuselage), `S_W` (wing), `S_T` (tail). No plotted data.

---

## §2.11 Transonic Flow and Its Effects

- Transonic regime: local sonic flow first appears (M > 1 somewhere on surface); lower
  limit at some `M∞ < 1` (depends on thickness), upper limit `M∞ ≈ 1.3` (all-supersonic).
- **Critical Mach number `M_CR`:** highest flight Mach with no supersonic flow anywhere.
- **Force-divergence (drag-divergence / drag-rise) Mach** exceeds `M_CR` by ≈ **5–10%** *(p. 56)*.
- Ways to increase `M_CR`: (1) decrease wing thickness ratio, (2) increase leading-edge
  sweep, (3) decrease aspect ratio, (4) use a supercritical airfoil *(p. 56)*.

#### Fig 2.19 — Flow patterns around an airfoil in transonic flow
*[Nicolai & Carichner, Fig. 2.19, p. 55]* — Flow-visualization diagram at M = 0.50 (max local
velocity < sonic), 0.72 (critical, max local velocity = sonic), 0.77, 0.82, 0.95 (upper & lower
normal shocks, separation), and 1.05 (detached bow wave). Qualitative — no plotted data.

#### Fig 2.20 — F-14 at M ≈ 0.95 with condensation at trailing-edge normal shock
*[Nicolai & Carichner, Fig. 2.20, p. 56]* — Photograph, no plotted data.

## §2.12 Wing Thickness Ratio

- Smaller t/c → higher `M_CR`. Supersonic aircraft: t/c ≈ **5% or less**; subsonic aircraft up
  to ≈ **18%**; structural minimum ≈ **3%** *(p. 57)*.

## §2.13 Wing Sweep

- Sweep increases `M_CR`: `M_CR = (M_CR)_{Δ=0} / cos Δ` *(unnumbered, p. 57)*.
- Only `V∞·cos Δ` (⟂ to leading edge) sets the pressure distribution.
- **Sweep penalty on lift-curve slope:** `(dC_L/dα)_Δ = (dC_L/dα)_{Δ=0} · cos Δ` *(unnumbered, p. 58)*.
- Straight wing: drag rise begins ≈ M = 0.90, peaks near M = 1.1. Use **≥ 35–45° sweep** to
  matter; sweep also reduces C_Lmax and promotes tip stall.

#### Fig 2.21 — General effects of wing sweepback
*[Nicolai & Carichner, Fig. 2.21, p. 58]* — Three qualitative plots (y-axes unlabeled):
(top) `C_D0` vs M∞ for Δ = 0°, 30°, 45°, 60° — the drag-rise peak lowers and shifts to higher
Mach with sweep (peak M ≈ 1.05, 1.15, 1.3, 1.5 respectively, *read from plot*); (bottom-left)
`C_D0` vs M∞ straight vs swept showing "delay" and "decrease"; (bottom-right) `C_Lα` vs M∞ for
Δ = 0°, 30°, 60° (swept has lower slope). Qualitative — no numeric values.

## §2.14 Supercritical Wing

- Supercritical section: flatter upper surface (weaker/smaller normal shock, less drag) with
  added aft camber to recover lift. For a given t/c, `M_CR` unchanged but **divergence Mach is
  delayed**. Alternatively, keep divergence Mach and increase thickness (→ lighter wing).

#### Fig 2.22 — Supercritical airfoil flow phenomena
*[Nicolai & Carichner, Fig. 2.22, p. 59]* — Diagram comparing NACA 64A-series (M = 0.72,
strong shock, separated BL) vs supercritical airfoil (M = 0.80, weak shock) at C_L = 0.5, with
schematic C_p vs chord (upper/lower surface, C_p sonic line). Qualitative.

#### Fig 2.23 — Supercritical section: geometry, drag, weight — **DATA GRAPHS**
*[Nicolai & Carichner, Fig. 2.23, p. 60]* (707-320B example)

(a) Geometry comparison (airfoil overlays) — qualitative.

(b) Drag coefficient `C_D` vs Mach (C_L = 0.4); low-Mach floor `C_D ≈ 0.0195–0.021`.
**Drag-divergence Mach** *(read from plot)*:

| Section | t/c | Drag-divergence Mach |
|---|---|---|
| 707-320B wing        | 8.6% | ~0.82 |
| Outboard wing        | 14%  | ~0.79 |
| Supercritical        | 12%  | ~0.85 |
| Supercritical        | 10%  | ~0.87 |
| Supercritical        | 8.6% | ~0.89 |

(c) Δ Wing Weight (lb) vs outboard t/c *(read from plot)*:

| Outboard t/c | Δ Wing Weight (lb) |
|---|---|
| 0.086 | 0 (707-320B baseline) |
| 0.10  | ~−1000 |
| 0.12  | ~−2700 |
| 0.14  | ~−4000 |

## §2.15 Wing–Body Combinations for Transonic Flight

- Fuselage `C_D0` peaks about M = 1.2. Wing and body `C_D0` (both referenced to wing area)
  add directly for comparison (interference not included).

#### Fig 2.24 — Wing, body, and wing–body C_D0 vs Mach — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.24, p. 61]* *(read from plot)*

Fuselage alone (Sears–Haack, ref. to wing area):

| M | C_D0 |
|---|---|
| 0.5 | ~0.0040 |
| 1.0 | ~0.0042 |
| 1.2 | ~0.0055 (peak) |
| 1.5 | ~0.0048 |
| 2.0 | ~0.0038 |

Wing alone (4% thick) and wing–body combination:

| M | Wing Unswept | Wing Swept 45° | Body+Unswept Wing | Body+Swept Wing |
|---|---|---|---|---|
| 0.5  | ~0.005 | ~0.005 | ~0.008 | ~0.008 |
| 1.0  | ~0.011 | ~0.006 | ~0.014 | ~0.010 |
| 1.1–1.15 | ~0.013 (peak) | ~0.007 | ~0.016 (peak) | ~0.012 |
| 1.5  | ~0.009 | ~0.009 | ~0.011 | ~0.013 (peak) |
| 2.0  | ~0.006 | ~0.007 | ~0.007 | ~0.009 |

---

## §2.16 Mach Wave

- Speed of sound: `a = √(γ·R·T)` *(unnumbered, p. 62)*.
- **Mach angle:** `sin μ = 1/M∞`, i.e. `μ = arcsin(1/M∞)` *(unnumbered, p. 62)*.

#### Fig 2.25 — Mach cone from an infinitesimal pressure disturbance
*[Nicolai & Carichner, Fig. 2.25, p. 62]* — Diagram: zone of silence / zone of activity split by
the Mach cone of half-angle μ. Qualitative.

## §2.17 Subsonic and Supersonic Leading Edge

- **Leading-edge criterion:** subsonic LE if `Δ > (90° − μ)`; supersonic LE if `Δ < (90° − μ)` *(unnumbered, p. 63)*.
- Wave-drag coefficient peaks at the M∞ where the **normal Mach ≈ 1.2**.
- Rule of thumb: sweep a subsonic-LE wing **5° behind the Mach line**.

#### Fig 2.26 — Straight and swept wing aircraft in Mach-2 flight
*[Nicolai & Carichner, Fig. 2.26, p. 63]* — Diagram: at M∞ = 2.0, μ = 30°, Δ = 65°; straight wing
has normal Mach `M_N = 2.0` (supersonic LE), swept wing `M_N = 0.85` (subsonic LE). Qualitative.

## §2.18 Supersonic Skin Friction

Supersonic flow is essentially always turbulent (Re_l > 5×10⁵). Using the incompressible
flat-plate value (one side) `C_Fi = 0.455/[log₁₀ Re_l]^2.58` [Eq (2.22)]:
- **Eq (2.25)** — compressibility correction: `C_F = C_Fi / (1 + 0.144·M∞²)^0.65`  *[Nicolai & Carichner, Eq. (2.25), p. 64]* (Ref. [11]).

## §2.19 Supersonic Lift and Wave Drag

- **Linear-theory pressure coefficient:**
  `C_p = (P−P∞)/(½ρV∞²) = (P−P∞)/(½γP∞M∞²) = 2θ/√(M∞²−1)` *(unnumbered, p. 64)*,
  where θ (rad) is + for compression, − for expansion.
- **Eq (2.26)** — supersonic thin-airfoil lift: `C_l = 4α/√(M∞²−1)`  *[Nicolai & Carichner, Eq. (2.26), p. 64]*
- **Eq (2.27)** — wave drag: `C_dw = [4/√(M∞²−1)]·[ α² + ⟨α_c(x)²⟩ + ⟨(dh/dx)²⟩ ]`  *[Nicolai & Carichner, Eq. (2.27), p. 64]*
  - α = angle of attack (rad); ⟨α_c(x)²⟩ = mean square of camber line; ⟨(dh/dx)²⟩ = mean square of thickness slope.
- **Eq (2.28):** `⟨α_c(x)²⟩ = (1/c)·∫₀^c α_c(x)² dx`  *[Nicolai & Carichner, Eq. (2.28), p. 64]*
- **Eq (2.29):** `⟨(dh/dx)²⟩ = (1/c)·∫₀^c (dh/dx)² dx`  *[Nicolai & Carichner, Eq. (2.29), p. 65]*

### Table 2.1 — Section Parameters for Wave Drag
*[Nicolai & Carichner, Table 2.1, p. 65]* (`t/c` = max thickness ratio of section)

| Shape | ⟨α_c²⟩ | ⟨(dh/dx)²⟩ |
|---|---|---|
| Flat plate    | 0 | 0 |
| Double wedge  | 0 | `t/c` |
| Biconvex      | 0 | `(4/3)·(t/c)` |

- **Eq (2.30)** — supersonic drag polar: `C_d = C_d0 + K·C_l²`  *[Nicolai & Carichner, Eq. (2.30), p. 65]*
- **Eq (2.31)** — supersonic zero-lift drag:
  `C_d0 = C_DF + [4/√(M∞²−1)]·[ ⟨α_c²⟩ + ⟨(dh/dx)²⟩ ] + C_dB·(S_B/S_ref)`  *[Nicolai & Carichner, Eq. (2.31), p. 65]*
- **Eq (2.32)** — supersonic drag-due-to-lift factor: `K = √(M∞²−1)/4`  *[Nicolai & Carichner, Eq. (2.32), p. 65]*
  - `C_dB` = base drag due to flow separation over a blunt base (`= −C_PB`, referenced to base area `S_B`).
  - For a detached (normal) shock, add a nose-bluntness term `C_dLE = f[M∞, r_LE, cos Δ_LE]` to Eq (2.31).

#### Fig 2.27 — Experimental base pressure coefficient — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.27, p. 66]* — `C_PB` vs Mach (0–5); `C_PB = (P_B−P∞)/(½ρV∞²) = −C_DB`.
Open symbols = two-dimensional, closed = three-dimensional (WADD TN 57-23, NACA TN 4201,
USAFA Trisonic data). *(read from plot)*:

| M | C_PB (2-D) | C_PB (3-D) |
|---|---|---|
| 0.5 | −0.55 | −0.16 |
| 1.0 | −0.70 (peak) | −0.22 (peak) |
| 1.5 | −0.48 | −0.15 |
| 2.0 | −0.35 | −0.13 |
| 3.0 | −0.18 | −0.10 |
| 4.0 | −0.10 | −0.07 |
| 5.0 | −0.07 | −0.05 |

## §2.20 Correction for Three-Dimensional Effects

- Fuselage ≈ cone-cylinder; cone supersonic wave drag from the conical-shock charts (Appendix E);
  cone-surface C_p = wave-drag coefficient referenced to cone cross-section area.
- For low wave drag at a given M∞: **small t/c, small LE radius, low AR, and lots of sweep**.

#### Fig 2.28 — Finite span wing in supersonic flow
*[Nicolai & Carichner, Fig. 2.28, p. 67]* — Diagram: Mach cones (μ) at the apex, with
two-dimensional flow regions outboard; ΔLE labeled. Qualitative.

#### Fig 2.29 — Effect of wing sweep on C_D0 — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 2.29, p. 68]* — `C_D0` vs Mach (0.8–2.0) for a double-wedge wing
(t/c = 0.06, λ = 0.5, AR = 4.0); data vs conical-flow theory; assumed skin-friction floor ≈ 0.007.
Curves for 50%-chord sweep `Δ½` = 0°, 27°, 45°, 50°. Peak values *(read from plot)*:

| Δ½ (deg) | Peak C_D0 | at Mach ≈ |
|---|---|---|
| 0  | ~0.041 | 1.05 |
| 27 | ~0.037 | 1.15 |
| 45 | ~0.026 | 1.4 |
| 50 | ~0.021 | 1.7 (broad) |

## §2.21 Sanity Check

- **Maximum L/D (uncambered wing):** `(L/D)_max = 1/√(4·C_D0·K)` *(unnumbered, p. 68; = Ch. 3 Eq. 3.10a)*,
  with `K = 1/(π·AR·e)`, `AR = b²/S_ref`.
- `C_D0 ≈ 1.25·C_DF = 1.25·C_F·(S_wet/S_ref)` [see Eq (2.24)].
- **Eq (2.33)** — max-L/D correlation: `(L/D)_max ~ b/√(S_wet)`  *[Nicolai & Carichner, Eq. (2.33), p. 69]*
  - `S_wet` = total aircraft wetted area. Correlated against `b/(S_wet)^{1/2}` in Fig G.8, where data
    fall between lines of constant `e/C_f` (wing efficiency / skin friction).

---

*Chapter 2 complete (Eqs 2.1–2.33, Table 2.1, Figs 2.1–2.29). Next: Chapter 3 — Aircraft Performance Methods.*
