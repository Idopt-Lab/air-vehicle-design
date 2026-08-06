# Chapter 7 — Selecting the Planform and Airfoil Section

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 7 "Selecting the Planform and Airfoil Section," printed pp. 171–194.

Mostly qualitative/comparative content (design guidance, not closed-form equations) with a
handful of numbered equations. Figures are catalogued in full.

---

## §7.1 Introduction

*Planform* = collectively the LE sweep (Δ), aspect ratio (AR), taper ratio (λ), and general
top-view wing shape (params defined in Fig 2.1). *Airfoil* selection = series designation (e.g.
NACA 2415) or explicit t/c, location of max t/c, leading-edge radius r_LE, and camber (% chord).

### Fig 7.1 — Definition of wing reference area
*[Nicolai & Carichner, Fig. 7.1, p. 172]* — Diagram: two methods of computing S_ref for a
delta-wing + slender-body configuration — `S_e` (exposed planform area, excludes the body-blocked
portion) vs `S_w` (total/theoretical planform area, wing extended through the body to the
centerline). Diagram, no plotted data.

Design measures of merit for airfoil/planform selection: **high** C_Lα, C_Lmax, wing fuel volume;
**low** C_D0, K′, wing weight — inherently conflicting (e.g. low K′ wants high AR, but low wing
weight wants low AR), so airfoil/planform selection is a compromise driven by mission priorities.

---

## §7.2 Effect of Airfoil: Maximum Thickness Ratio

- Low speed: C_lmax **increases** with t/c (Fig 7.2). Subsonic C_D0 increases slightly with t/c (Fig H.6).
- `M_CR` **decreases** as t/c increases (supersonic flow appears earlier on the upper surface →
  normal shock + separation, Fig 2.19); shown in Figs 2.23b and 7.9.
- Supersonic wave drag increases ≈ as `(t/c)²` [Eq (2.31)] — illustrated in Fig H.6. For a
  supersonic-dominant mission, use small t/c (4–6%); 3% is attractive for wave drag but is a
  practical lower bound (heavy wing, little fuel volume). The B-58 Hustler (NACA 0003 airfoil, 3%
  t/c) needed a large external fuel pod (which also housed the nuclear weapon, dropped over
  target) due to insufficient wing fuel volume. Wing fuel volume vs t/c shown in Fig 7.10 (§7.7).
- Wing weight vs t/c: Figs 2.23c and 7.10. Ch. 20 wing-weight equations [Eqs (20.1), (20.2),
  (20.69)] all have t/c in the denominator — significant effect on wing weight.

### Fig 7.2 — Maximum lift coefficient vs airfoil thickness ratio — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.2, p. 173]* (data from Ref. [2]) — `C_lmax` vs Maximum Thickness
Ratio t/c (%, 4–22), several NACA airfoil families *(read from plot)*:

| t/c (%) | 64-2xx (60° 0.2c split flap) | 00xx | 63-0xx | 65-2xx | 54-2xx |
|---|---|---|---|---|---|
| 6  | ~1.78 | ~0.95 | ~0.90 | ~0.87 | ~0.88 |
| 10 | ~2.05 | ~1.42 | ~1.35 | ~1.30 | ~1.25 |
| 14 | ~2.32 | ~1.68 (curve ends) | ~1.52 | ~1.48 | ~1.43 |
| 18 | ~2.48 | — | ~1.53 | ~1.44 | ~1.38 |
| 22 | ~2.62 | — | ~1.53 | ~1.36 | ~1.30 |

(64-2xx with 60° split flap deployed dominates C_lmax across the whole t/c range; plain-section
families 00xx/63-0xx/65-2xx/54-2xx peak around t/c ≈ 16–18% then gently decline.)

---

## §7.3 Effect of Airfoil: Location of Maximum Thickness

Max-t/c location sets where the favorable (decreasing) pressure gradient ends and the adverse
gradient begins. A laminar BL cannot tolerate the adverse gradient and transitions to turbulent at
(or before, due to roughness) the max-thickness point — further aft max-t/c → longer laminar run →
lower skin friction. Illustrated in Fig F.3 (front-loaded NACA 63₂-015 vs aft-loaded laminar NACA
66₂-015). NACA 64/65/66 series = laminar-flow airfoil families.

Max-t/c location (with camber) also sets the sign of the section pitching moment: max-t/c forward
of the a.c. (~25% chord) → **front-loaded**, nose-up C_m; aft of the a.c. → **aft-loaded**,
nose-down C_m. Matters for trim: an aft-loaded (nose-down C_m) section on a tailless aircraft needs
a down-load at the TE to trim, reducing overall lift.

**Case study — two ISR airfoils (Fig 2.3):** JW 1416 (16% t/c) vs LRN 1015 (15% t/c), similar
thickness but very different max-t/c location. JW 1416 designed for low positive C_m at C_l≈0.9,
used on the high-AR swept-wing tailless **Polecat** (Lockheed Martin, 2004). LRN 1015 designed for
laminar BL back to ~55% chord at C_l≈0.9, used on the **RQ-4A Global Hawk** (Fig 7.3), which has
an aft horizontal tail (so the resulting negative C_m can be trimmed without losing overall lift).
Each airfoil suited to its aircraft's specific trim architecture.

### Fig 7.3 — Global Hawk
*[Nicolai & Carichner, Fig. 7.3, p. 175]* — Photograph (RQ-4A Global Hawk, high-AR straight wing,
V-tail... actually conventional aft tail per text). No plotted data.

---

## §7.4 Effect of Airfoil: Leading Edge Shape

LE shape ranges sharp (`r_LE=0`) to round. Sharp-LE airfoils (Fig 7.4) are designed primarily for
supersonic flight and have poor low-speed characteristics — but low-speed performance can be
improved via LE/TE flaps (Fig 7.5 data: basic double-wedge section C_lmax ≈ 0.83).

### Fig 7.4 — Sharp leading edge airfoils
*[Nicolai & Carichner, Fig. 7.4, p. 176]* — Three cross-section profiles: Double Wedge,
Flat-Bottom Wedge, Circular Arc. Diagram, no plotted data.

Round-nosed airfoils have much better low-speed characteristics than sharp-nosed; C_lmax generally
increases with larger r_LE. All Appendix F airfoils are round-nosed and (nearly) all beat the
double-wedge C_lmax; round-nosed sections can also take slots/slats/LE+TE flaps (Ch. 9).

Subsonic C_D0 is primarily skin friction, not influenced by nose shape. Subsonic viscous
drag-due-to-lift is influenced by r_LE: smaller r_LE → earlier LE flow separation at angle of
attack → slightly higher aircraft viscous drag-due-to-lift factor K″ (§13.2.1).

- **Eq (7.1)** — supersonic wave-drag coefficient: `C_DW = C_DLE + (B/β)·(t/c)²`  *[Nicolai & Carichner, Eq. (7.1), p. 176]*
  - `β = √(M²−1)`; `B` = constant depending on thickness distribution (Ch. 13); `C_DLE` = leading-edge
    bluntness term (Ch. 2).
- **Eq (7.2)** — LE bluntness drag (from Ref. [4]):
  `C_DLE = (2.56/b)·[ r_LE·AR·cos²Δ / (1 + 1/(M∞³·cos³Δ)) ]`  *[Nicolai & Carichner, Eq. (7.2), p. 177]*
  - `b` = wing span; C_DLE referenced to exposed planform area. If the LE is supersonic
    (`M∞·cosΔ > 1`), r_LE should be small — typical supersonic-LE radii range 0 to ~0.25% chord
    (e.g. F-104: Δ_LE=0, r_LE=0).

### Fig 7.5 — 4.5% double-wedge airfoil: (a) C_lmax vs nose/TE flap deflection; (b) cross-section — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.5, p. 177]* (data from Ref. [5])

(a) C_lmax (0.4–2.0) vs Nose Flap Deflection (deg, 0–40), families at TE flap deflection 0°, 10°,
20°, 40°, 50°, 60° *(read from plot)*:

| Nose Flap Defl (deg) | TE=0° | TE=10° | TE=20° | TE=40° | TE=50° | TE=60° |
|---|---|---|---|---|---|---|
| 0  | 0.83 | 1.10 | 1.28 | 1.60 | 1.65 | 1.75 |
| 10 | 0.98 | 1.25 | 1.42 | 1.72 | 1.78 | 1.83 |
| 20 | 1.13 | 1.37 | 1.48 | 1.82 | 1.85 | 1.93 |
| 25 | 1.22 | 1.44 | 1.57 | 1.87 | 1.90 | 1.95 (≈peak) |
| 30 | 1.28 (≈peak) | 1.46 (≈peak) | 1.62 (≈peak) | 1.88 (≈peak) | 1.82 | 1.87 |
| 35 | 1.17 (falling) | — | — | — | — | — |

(b) Cross-section: t/c=4.5%, LE flap = 15% chord, TE flap = 25% chord, hinges at 50% chord.

- **Eq (7.3)** — supersonic drag-due-to-lift factor (Ref. [6]): `K = 1/C_Lα − ΔN`  *[Nicolai & Carichner, Eq. (7.3), p. 178]*
  - ΔN = leading-edge suction parameter; ΔN=0 for supersonic LE, ΔN>0 (increasing with r_LE) for
    subsonic LE — so supersonic K decreases slightly as r_LE increases.
  - If M∞ > 2.5, aerodynamic heating (Ch. 4) dictates a larger r_LE than aerodynamics alone would
    choose, to handle LE stagnation-point heat input.

---

## §7.5 Effect of Airfoil: Camber

Camber = % chord that the line equidistant from upper/lower surfaces deviates from the chord line
(positive camber per Fig 2.1). A deflected TE flap ≡ added aft camber — aft camber strongly shifts
lift at a given α (positive camber shifts the C_lα curve left/up). LE camber (LE flap deflection)
has almost no effect on lift; its purpose is delaying forward separation to raise C_lmax.

- All subsonic low-speed sections share `C_lα ≈ 2π/rad`. Camber sets `α_0L` (zero-lift angle);
  symmetric (zero-camber) airfoil has `α_0L = 0`.
- Positive camber → negative `C_m,a.c.`; symmetric section → `C_m,a.c. = 0`. A tailless design
  needing positive `C_m,a.c.` (static longitudinal stability) needs **negative camber**. The B-58
  Hustler used a swooped-up TE ("inverse camber"/"reflexed TE") for negative camber + positive
  `C_m,a.c.`.
- Positive camber increases section C_lmax (e.g. 6% camber at 30% chord → ΔC_lmax ≈ +0.4 vs an
  equivalent symmetric section — a small flap deflection is equivalent to a positive camber increase).
- Increasing camber translates the drag polar to higher `C_Lmin` (the C_L at C_Dmin) — shown in
  Fig 7.6 (NACA 65₃-X18 laminar sections) and Fig 7.7 (complete aircraft).

### Fig 7.6 — Drag characteristics of NACA 65-series airfoil sections, 18% thickness, various camber — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.6, p. 179]* (data from Ref. [2], Re=6×10⁶) — Section C_d vs C_l,
6 airfoils NACA 65₃-018/218/418/618/818 (increasing camber) plus 65₃-616 (unlabeled tip variant).
Approximate design C_l (drag-bucket center) *(read from plot)*:

| Airfoil | Design C_l (drag-bucket center) | C_d,min |
|---|---|---|
| 65₃-018 | 0.0 | ~0.0043 |
| 65₃-218 | 0.2 | ~0.0044 |
| 65₃-418 | 0.4 | ~0.0043 |
| 65₃-618 | 0.6 | ~0.0043 |
| 65₃-818 | 0.9 | ~0.0045 |

(The "3" subscript denotes the C_l range in tenths above/below the design C_l for the drag bucket.)

### Fig 7.7 — Aircraft drag polar with variable-camber wing — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.7, p. 179]* — C_L vs C_D at M∞=0.9, variable camber (LE flap δ_lef,
TE flap δ_tef): 0°/0°, 15°/0°, 15°/10°, 15°/20°. Higher combined flap deflection shifts the polar
to higher C_L for a given C_D *(read from plot)*:

| C_D | C_L, δ=0°/0° | C_L, δ=15°/0° | C_L, δ=15°/10° | C_L, δ=15°/20° |
|---|---|---|---|---|
| 0.04 | ~0.35 | ~0.40 | ~0.45 | ~0.55 |
| 0.08 | ~0.55 | ~0.62 | ~0.68 | ~0.78 |
| 0.12 | ~0.68 | ~0.76 | ~0.82 | ~0.90 |
| 0.16 | ~0.78 | ~0.87 | ~0.93 | — |
| 0.20 | ~0.82 | ~0.93 | ~0.97 | — |

**Example — Antonov A-15 sailplane** (USSR): AR=26.4, W/S=6 psf, best glide ratio 40:1 at 54 kt.
At 5000 ft, required C_L=0.7. Uses NACA 65₃-618 airfoil at root, 65₃-616 at tip. From Fig 7.6, the
65₃-618 has design C_l=0.6 with a broad drag bucket around that design point.

Camber works well for high-subsonic cruise and transonic maneuvering. A range-dominated aircraft
cruising at Mach 0.8 typically needs cruise C_L=0.3–0.4 (Fig 3.9) — designer picks an airfoil with
design C_L in that range. A fighter maneuvering transonically at high C_L (~0.8) uses a **low-camber**
airfoil (F-16: 64-204) plus **maneuver flaps** (variable camber, deployed only during combat) to cut
drag-due-to-lift. Positive camber requires trimming a negative C_m,a.c. with a down aft-tail load
for statically stable designs. Camber is normally avoided supersonically (wave-drag penalty, Eqs
2.28/2.31).

High-altitude ISR aircraft use highly cambered airfoils since their optimum (max-endurance) C_L is
typically 0.7–1.0 (Fig G.4). Lockheed Tier 3-minus "Darkstar" cruised at C_L=0.53 (straight-wing
tailless, low pitch-control power, <50,000 ft); Boeing Condor started loiter at C_L=1.33.

---

## §7.6 Effect of Planform: Aspect Ratio

For a delta planform, AR relates to LE sweep by:
- **Eq (7.4):** `AR = 4·cot(Δ)`  *[Nicolai & Carichner, Eq. (7.4), p. 180]*

AR strongly influences the wing lift-curve slope [Eq (2.13)] and subsonic cruise efficiency via
the inviscid drag-due-to-lift factor:
- **Eq (2.18)** (repeated here): `K′ = 1/(π·AR·e)`  *[Nicolai & Carichner, Eq. (2.18), p. 180]*

### Fig 7.8 — Inviscid drag-due-to-lift factor (based on total planform area) for delta wing–body combinations, LE radius=0.45% — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.8, p. 181]* (Appendix H data) — K′ (log, 0.1–4.0) vs Mach (log,
0.1–10), families at AR = 0.5, 1, 2, 3, 4, 5, converging toward the supersonic linear-theory line
`K′ = √(M²−1)/4` at high Mach *(read from plot)*:

| Mach | AR=0.5 | AR=1 | AR=2 | AR=3 | AR=4 | AR=5 |
|---|---|---|---|---|---|---|
| 0.3 | 0.75 | 0.47 | 0.30 | 0.25 | 0.225 | 0.21 |
| 0.8 | 0.75 | 0.47 | 0.30 | 0.25 | 0.225 | 0.21 |
| 1.0 | 0.78 | 0.40 (min) | 0.25 (min) | 0.21 (min) | 0.19 (min) | 0.18 (min) |
| 2.0 | 1.3 | 0.60 | 0.42 | 0.40 | 0.38 | 0.36 |
| 4.0 | 2.0 | 1.5 | 1.15 | 1.05 | 1.0 | 0.95 |
| 8.0 | — | — | 2.0 (converged) | 2.0 | 2.0 | 2.0 |

K′ dips slightly transonically (higher C_Lα) then rises supersonically, converging on the linear
theory line by Mach ≈ 8–10 essentially independent of AR. AR's influence on K′ diminishes at
supersonic speeds.

Effect of AR on wing weight: quantitatively Eqs (20.1), (20.2), (20.69); qualitatively Fig 7.10
(§7.7), which also shows the effect on wing fuel volume. Low-speed C_D0 has little AR dependence
(skin-friction dominated, planform-shape-independent); supersonically C_D0 **increases** with AR
(Fig H.6), which limits practical supersonic AR to **< 5**.

---

## §7.7 Effect of Planform: Sweep

Sweep effects are mostly independent of forward vs aft direction. Forward sweep introduces
**aeroelastic divergence**: spanwise upward bending increases tip-section angle of attack, further
loading the tip — divergent unless structural elastic restoring forces halt the twist. Mitigation:
tailor LE stiffness for downward twist (e.g. via composite ply tailoring).

> **Sidebar — Designing to Counter the Aeroelastic Effect:** the X-29's forward-swept wing
> demonstrated excellent roll control to 60° AoA; countering aeroelastic divergence via tailored
> carbon-fiber composite stiffness (without a large weight penalty) was a program technology goal,
> successfully demonstrated on the X-29 and later applied to the forward-swept-wing Advanced
> Cruise Missile AGM-129 (Fig 12.22). X-29 first flew Dec. 1984; demonstrated subsonic/supersonic
> high-alpha maneuvering 1985–1991.

Forward sweep, despite weighing more than aft sweep, offers: improved area-rule distribution,
longer wing–tail mac lever arm, and **reduced tip stall** (decreases stall-spin departure
tendency, lowers landing speed).

Chordwise pressure distribution is a function of the Mach number *normal* to the LE (Fig 2.19):
normal Mach < 1 → subsonic LE at that freestream Mach (Fig 2.24); normal Mach > 1 → supersonic LE.
Sweep delays/softens transonic drag rise (wing alone: Fig 2.27; wing–body: Fig H.4, sweeps 0/45/60°)
— lets subsonic aircraft cruise at higher Mach before compressibility drag rise. Wing and fuselage
drag are roughly additive (+ interference); fuselage C_D0 peaks near Mach 1.2 (Fig 2.22).

M_CR is the desirable-to-maximize upper subsonic speed boundary; increasing sweep increases M_CR (Fig 7.9).

### Fig 7.9 — Effect of LE sweep, t/c, and AR on the critical Mach number — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.9, p. 183]* — Three stacked panels, each vs Critical Mach Number
M_CR (0.70–1.00): (top) Aspect Ratio (2–6); (middle) t/c % (4–16); (bottom) LE Sweep (deg, 0–60).
Each shows a trend curve plus representative-aircraft markers *(read from plot)*:

| Panel | Parameter | M_CR at low end | M_CR at high end |
|---|---|---|---|
| AR | AR=2 → AR=6 | M_CR≈0.81 (AR=2) | M_CR≈0.76 (AR=6) |
| t/c | t/c=6% → t/c=14% | M_CR≈0.81 (t/c=6%) | M_CR≈0.75 (t/c=14%) |
| LE Sweep | Δ=0° → Δ=50° | M_CR≈0.81 (Δ=0°) | M_CR≈0.92 (Δ=50°) |

(All three trends move the same direction: lower AR, thinner sections, and more sweep each raise
M_CR — sweep has by far the largest effect of the three.)

Peak wing C_D0 occurs transonically. Unswept wing: peak C_D0 near Mach 1.1.
- **Eq (7.5)** — swept-wing peak-C_D0 Mach: `M_CDpeak = 1.2/√(cos Δ_t/c)`  *[Nicolai & Carichner, Eq. (7.5), p. 184]*
  (Δ_t/c = sweep of the max-thickness line.)
- **Eq (7.6)** — peak C_D0 reduction with sweep:
  `C_Dpeak,Δt/c = (cos Δ_t/c)^2.5 · C_Dpeak,Δt/c=0`  *[Nicolai & Carichner, Eq. (7.6), p. 184]*

For supersonic flight, decide subsonic-vs-supersonic LE (drives r_LE selection). Eq (7.2): more
sweep + less AR → lower C_DLE, but poorer low-speed qualities. Rule: **"just enough sweep to do
the job."** For a subsonic LE, sweep should be ~5° behind the Mach line. Fig 2.29 shows sweep's
general influence on supersonic C_D0 (sharp double-wedge airfoil, Table 2.1 — no LE-bluntness drag).

**Disadvantages of sweep:**
- Decreased wing lift-curve slope [Eq (2.13), Fig 2.21] → swept-wing aircraft land/take off at
  higher angle of attack than straight-wing.
- Aft sweep: reduced C_Lmax and **tip stall** (spanwise flow thickens the tip BL, hastens
  separation) — troublesome since ailerons sit near the tips. Forward sweep: opposite — root
  stalls first, ailerons stay in high-energy attached flow. Both can be controlled via
  tip/root twist.
- Sweep×AR interaction drives **pitch-up**: as a high-AR aft-swept wing's tip stalls, center of
  pressure moves forward → nose-up pitching moment, potentially violent/divergent. Several fighters
  (e.g. F-101 Voodoo) added horns/buzzers/stick-shakers to warn of entry into the wing-stall
  region. NASA's pitch-up boundary (Fig 21.14a, developed from wind-tunnel + flight test) splits
  planforms into pitch-up-prone "Region I" (avoid for fighters, or provide an aft tail located
  outside the stalled wing's wake to arrest the divergence) vs safer regions.

Fig 21.14b gives four regions of horizontal-tail location with pitch-up recommendations; Fig 21.14
guides both fighter planform selection and horizontal-tail placement.

Effect of **aft** sweep on wing weight: quantitative in Eqs (20.1), (20.2), (20.69); qualitative in
Fig 7.10. **Forward** sweep's effect would be even greater (extra stiffening structure needed to
arrest aeroelastic divergence). Effect of sweep on wing volume: negligible (Fig 7.10).

### Fig 7.10 — Effect of LE sweep, t/c, and AR on wing weight and wing fuel volume — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 7.10, p. 185]* — Six panels: rows = Aspect Ratio (2–6), t/c% (4–16),
LE Sweep (0–60°); columns = Wing Weight `W_W` (0–1.0, nondimensional) and Wing Fuel Volume `W_f`
(0–2.0, nondimensional). Trends *(read from plot)*:

| Row parameter | Wing Weight trend | Wing Fuel Volume trend |
|---|---|---|
| AR 2→6 (straight vs delta markers) | increases ~0.35→0.6 (delta slightly higher than straight at same AR/t-c — "very little difference") | decreases ~1.85→0.35 |
| t/c 4%→16% | decreases slightly ~0.65→0.55 | increases linearly ~0→1.9 |
| LE Sweep 0°→60° | increases ~0.55→0.9 | **flat/negligible** (~1.0 constant) |

Wing weight ∝ structural span / root thickness (structural span ≈ 2× the length of the line
bisecting LE/TE angle). Increasing LE sweep increases structural span (projected span unchanged)
→ increases wing weight. Reducing AR via increased sweep also increases root max thickness,
largely offsetting — delta and straight wings of the same AR/t-c end up with very similar weight.
Wing volume: if AR and wing area are held constant, sweep doesn't change volume/fuel weight
(bottom-right panel ≈ flat); volume instead varies linearly with t/c, and fuel volume decreases as
AR increases (thinner/longer wing for the same area → less volume).

---

## §7.8 Effect of Planform: Taper Ratio

Taper ratio `λ = C_T/C_R` (tip/root chord) fine-tunes wing performance. As λ increases from 0
(delta) toward 1.0 (rectangular), it passes through a near-elliptical lift distribution at
**λ ≈ 0.35** — minimum finite-span downwash effects, minimum induced drag. For fixed wing area and
t/c, a delta planform has a larger root chord than a rectangular one → **≈40% more fuel volume**
in the delta (Fig 7.10). From the Ch. 20 wing-weight equations, decreasing λ from 1→0 **decreases**
wing weight (increased root depth, decreased tip loading).

---

## §7.9 Variable Geometry

Prior sections show good low-speed performance wants low sweep/high AR, while good supersonic
cruise wants high sweep/low AR — a real dilemma for a **fixed**-geometry wing, solvable only by
compromise. **Variable-geometry (variable-sweep) wings** pivot at the root to swing between
low-sweep and high-sweep conditions — not a new idea: Bell X-5 and Grumman XF10F (1951–1952) were
early research aircraft demonstrating the concept; current users include the F-111, Mirage IIIG,
Sukhoi SU-7B, Mikoyan Flogger (Fig 7.11c).

**Disadvantages:**
- **Weight** — the pivot structure/machinery makes a variable-sweep wing ≈**20% heavier** than an
  equivalent fixed wing. Significant: McDonnell F-4C wing weighs 4600 lb on a ≈50,000-lb aircraft
  — a 20% wing-weight increase would seriously cut performance.
- **Large aerodynamic-center shift** as wings sweep back → large stability/control problems. The
  wing glove (fixed wing root portion) mitigates but doesn't eliminate this shift.
- External stores on wing pylons need swiveling pylons to hold zero yaw angle at all sweep
  angles — added weight.

Variable geometry only "buys its way onto the airplane" when performance gains outweigh these
penalties — a good example is the U.S. Navy F-14 Tomcat (Fig 7.12/7.13): 120-kt carrier-approach
speed + supersonic accel to Mach 2.5 drove the F-14 to variable geometry. Protected Navy battle
groups for four decades; retired 2007.

### Fig 7.11a — Typical wing planform shapes for fixed-wing, conventional-tail aircraft
*[Nicolai & Carichner, Fig. 7.11a, p. 188]* — 9 top-view silhouettes: Mig-21, Lightning, A-5,
Mig-23, Yak-28, Jaguar, F-4, F-5, F-104. Comparison gallery, no plotted data.

### Fig 7.11b — Typical wing planform shapes for tailless delta aircraft
*[Nicolai & Carichner, Fig. 7.11b, p. 189]* — 7 top-view silhouettes color-coded USSR/Soviet,
European, USA: Mirage IV, TU-144, Concorde, B-58, YF-12A, Saab-35, F-106. Comparison gallery, no
plotted data.

### Fig 7.11c — Typical wing planform shapes for canard, subsonic-cruise, and variable-sweep aircraft
*[Nicolai & Carichner, Fig. 7.11c, p. 190]* — 8 top-view silhouettes: Saab-37, XB-70, B-47, 727,
F-111, Mirage IIIG, SU-7B, Mikoyan (last four shown with dashed swept-back overlay, illustrating
variable-sweep range). Comparison gallery, no plotted data.

Rockwell (North American) B-1 Lancer (Fig 7.14) is another aircraft forced into variable-sweep:
mission required extended Mach-0.8 cruise range (good (L/D)max → moderate sweep, high AR) *and*
low-altitude Mach-0.9 dash + Mach-2.2 altitude acceleration (→ low AR, high sweep). High sweep also
alleviates gust response during the low-altitude dash, giving a much smoother ride.

### Fig 7.12 — USN Grumman F-14 Tomcat
*[Nicolai & Carichner, Fig. 7.12, p. 191]* — Photograph, wings swept for high-speed flight, ordnance
loaded. No plotted data.

### Fig 7.13 — Three-view of U.S. Navy Grumman F-14 Tomcat
*[Nicolai & Carichner, Fig. 7.13, p. 191]* — Two-seat carrier-based swing-wing fighter. Key data:
`W_TO = 54,000 lb`, length = 62 ft, extended wing span = 64 ft, sweep = 20–68°. Three-view diagram
with dashed overlay showing swept vs unswept wing position.

### Fig 7.14 — USAF/Rockwell B-1 Lancer
*[Nicolai & Carichner, Fig. 7.14, p. 192]* — Photograph, in-flight, wings swept. No plotted data.

### Fig 7.15 — Rockwell B-1 strategic bomber
*[Nicolai & Carichner, Fig. 7.15, p. 192]* — Three-view diagram. Key data: `W_TO = 400,000 lb`,
length = 143 ft, extended wing span = 137 ft, sweep = 15–65°.

### Table 7.1 — Summary of Airfoil and Planform Effects
*[Nicolai & Carichner, Table 7.1, p. 193]* — Master qualitative summary: effect of **increasing**
each planform/airfoil parameter (rows) on each design metric (columns): C_D0 (split
subsonic/supersonic), K, C_Lα, C_Lmax, Wing Weight, Wing Volume. ↑ = increases, ↓ = decreases,
"NO EFFECT" = negligible; where a cell shows two arrows it means "varies / non-monotonic."

| Increase in → | C_D0 (Subsonic) | C_D0 (Supersonic) | K | C_Lα | C_Lmax | Wing Wt | Wing Vol |
|---|---|---|---|---|---|---|---|
| **Aspect Ratio** | NO EFFECT | ↑ | ↓ | ↑ | ↑ | ↑ | ↓ |
| **Wing Sweep** | NO EFFECT | ↓ | ↑ | ↓ | ↓ (Aft) / NO EFFECT (Fwd) | ↑ | NO EFFECT |
| **Taper Ratio** | NO EFFECT | NO EFFECT | ↓↑ (non-monotonic, min near λ=0.35) | ↑↓ (non-monotonic) | NO EFFECT | ↑ | ↓ |
| **Airfoil Thickness Ratio (t/c)** | NO EFFECT | ↑ | NO EFFECT | NO EFFECT | ↑ | ↓ | ↑ |
| **Leading Edge Radius** | NO EFFECT | ↑ | ↓ | NO EFFECT | ↑ | NO EFFECT | ↑ |
| **Camber** | ↑ | ↑ | ↓ | NO EFFECT | ↑ | NO EFFECT | NO EFFECT |

(Note: "K" column here is the drag-due-to-lift factor broadly — subsonic K′ decreases with AR per
Eq 2.18, while supersonic K per Eq 2.32/7.3 behaves differently; the table captures the net
directional trend as presented by the authors, not a single formula.)

---

## §7.10 Summary

Selecting the right airfoil and planform is difficult even for experienced designers — there is no
right answer, only a best answer at a point in time, and the best answer always involves
compromise across the measures of merit listed at the start of the chapter. Table 7.1 summarizes
all the airfoil/planform effects discussed: measures of merit along the top, airfoil/planform
features down the left, cell = effect on that metric if the feature is *increased*.

### References
[1] Abbott, I. H., and Von Doenhoff, A. E., *Theory of Wing Sections*, Dover, New York, 1959.
[2] Abbott, I. H., Von Doenhoff, A. E., and Stivers, L., Jr., "Summary of Airfoil Data," NACA TR-824, 1945.
[3] Riegels, F. W., *Aerofoil Sections*, Butterworth, London, 1961.
[4] *Evolution of Aircraft Wing Design Symposium*, AIAA, Reston, VA, 1980.
[5] McCullough, G. B., and Gault, D. E., "Examples of Three Representative Types of Airfoil-Section Stall at Low Speed," NACA TN-2502, 1951.
[6] Simon, W. E., Ely, W. L., Niedling, L. G., and Voda, J. J., "Prediction of Aircraft Drag Due to Lift," U.S. Air Force Flight Dynamics Laboratory AFFDL-TR-71-84, July 1971.

---

*Chapter 7 complete (Eqs 7.1–7.6, Table 7.1, Figs 7.1–7.15). Next: Chapter 8 — Preliminary Fuselage Sizing and Design.*