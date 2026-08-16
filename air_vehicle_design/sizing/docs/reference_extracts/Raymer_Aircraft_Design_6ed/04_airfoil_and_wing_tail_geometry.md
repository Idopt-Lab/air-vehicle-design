# Chapter 4 — Airfoil and Wing/Tail Geometry Selection

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA Education
Series, 2018), Chapter 4 "Airfoil and Wing/Tail Geometry Selection," printed pp. 55–114.

Covers airfoil geometry/lift/drag/stall fundamentals, initial airfoil selection guidance, wing
reference-geometry definitions (area, aspect ratio, taper, sweep, MAC), historical-trend design
tables for aspect ratio/sweep/taper/dihedral, wing vertical location and tip-shaping tradeoffs,
biplanes, and tail function/arrangement/geometry selection. Few numbered equations (Eqs. 4.1–4.5);
most quantitative content is captured in historical-trend figures and tables, several digitized
below.

---

## §4.1 Airfoil Geometry

An airfoil's shape is defined relative to its **chord line** (leading edge to trailing edge, length
`c`): a **leading-edge radius** (tangent to upper/lower surfaces, greatly affects lift/drag/stall —
larger LE radius delays stall to a higher angle of attack and gives more lift for takeoff/landing,
at a drag cost; supersonic airfoils often use sharp/near-sharp LE instead to avoid a drag-producing
bow shock, or rely on wing sweep instead); a **mean camber line** (equidistant between upper/lower
surfaces — total camber is that line's max distance from the chord line, in %chord); and a
**thickness distribution** `t = f(x)` measured perpendicular to the camber line, with **thickness
ratio** `t/c` = max thickness / chord [Raymer, p. 55–56].

Camber gives lift at zero angle of attack and increases max lift, at a drag/pitching-moment cost
(rule of thumb: **1% camber increase ≈ +0.03 Cl_max**). For tailless/flying-wing designs, an
"S"-shaped reflexed camber line (upward trailing-edge reflex) gives natural pitch stability at an
L/D penalty; an active flight-control system removes the need for reflex [Raymer, p. 56].

Classical airfoil-design practice split the airfoil into thickness distribution (drives profile
drag) and a zero-thickness camber line (drives lift, drag-due-to-lift, pitching moment) and
optimized each separately; modern methods model the actual upper/lower surfaces together. When
rescaling a cambered airfoil's thickness, the camber line must be held fixed (extract the thickness
distribution, scale it vertically, re-add to the unchanged camber line) — naive vertical stretching
changes both thickness and camber together [Raymer, p. 56–57].

### Fig. 4.1 — Airfoil geometry
*[Raymer, Fig. 4.1, p. 55]* — Labeled cross-section diagram: chord line, chord length `c`,
angle-of-attack reference, actual airfoil shape (upper/lower surfaces), leading-edge radius,
leading-edge camber line, mean camber line `= f(x)`, thickness distribution `t`, trailing-edge
thickness. Note: LE radius and TE thickness exaggerated for illustration. Diagram only, no plotted
numeric data.

## §4.2 Airfoil Lift and Drag

Lift arises from the pressure difference between upper/lower surfaces (Bernoulli: higher local
velocity over the top → lower pressure, pulling the upper surface up; higher pressure below pushes
the lower surface up). **The upper surface contributes about two-thirds of total lift** — design
rule of thumb: put unavoidable flow-disturbing items (wheel-well bumps, struts) on the *bottom* of
the wing [Raymer, p. 57]. (Footnote: an equally valid momentum-based view — lift equals the total
downwash momentum imparted to the air — is offered as complementary, not competing, with the
pressure-integral view [Raymer, p. 57].)

### Fig. 4.2 — Typical airfoil pressure distribution
*[Raymer, Fig. 4.2, p. 58]* — Two panels: (a) actual flowfield pressure-above/below-atmospheric
regions around a lifting airfoil; (b) freestream pressure components resolved in the lift
direction. Illustrative, no plotted numeric data.

### Fig. 4.3 — Airfoil flowfield and circulation
*[Raymer, Fig. 4.3, p. 58]* — Three panels: (a) velocity-vector field around a lifting airfoil
(arrow length = local speed); (b) same field with the freestream vector subtracted, revealing a
net clockwise perturbation ("circulation"); (c) circulation represented as a circular flow pattern
Γ. Greater circulation → greater lift. Diagram only, no plotted numeric data.

A flat plate at incidence produces lift but the flow separates off the top, disturbing the flow and
cutting lift while sharply raising drag; camber keeps the flow attached, raising lift and cutting
drag by increasing circulation (Fig. 4.4). A cambered airfoil lifts even at zero angle of attack; the
angle at which it produces zero lift ("angle of zero lift") is, rule of thumb, approximately
`−(percent camber)` degrees [Raymer, p. 59].

### Fig. 4.4 — Effect of camber on separation
*[Raymer, Fig. 4.4, p. 59]* — Comparison sketch: flat-plate airfoil showing upper-surface
separation vs. a cambered airfoil keeping flow attached. Diagram only, no plotted data.

A 2-D inviscid airfoil produces **no drag due to lift** — 2-D drag is entirely skin friction plus
separation/shock pressure effects; drag due to lift is a 3-D phenomenon (discussed under aspect
ratio below) [Raymer, p. 59].

### Airfoil section coefficients

**Eq. (4.1)** *[Raymer, Eq. (4.1), p. 59]* — section lift coefficient:
```
Cl = (Section lift) / (q c)
```
**Eq. (4.2)** *[Raymer, Eq. (4.2), p. 59]* — section drag coefficient:
```
Cd = (Section drag) / (q c)
```
**Eq. (4.3)** *[Raymer, Eq. (4.3), p. 60]* — section moment coefficient:
```
Cm = (Section moment) / (q c^2)
```
where `c` = chord length, `q` = dynamic pressure = `ρV²/2`, and (per the surrounding text)
`α` = angle of attack, `Cl_α` = lift-curve slope = `2π` per radian (theoretical thin-airfoil value).
Lowercase subscripts (`Cl`, `Cd`, `Cm`) denote 2-D airfoil-section coefficients; uppercase subscripts
(`CL`, `CD`, `CM`) denote 3-D wing coefficients [Raymer, p. 59–60].

Pitching moment is referenced to the **aerodynamic center** (a.c.) — the point (subsonically, ≈25%
chord, the "quarter-chord") about which pitching moment is nearly independent of angle of attack.
Because `dCm/dα ≈ 0` there, stability-derivative equations simplify (constant-moment terms drop out
of the derivative) — the reason quarter-chord is the conventional moment reference. The a.c. is
**not** the same as the **center of pressure** (where net vertical force acts) — c.p. sits aft of
the a.c. and migrates with angle of attack, making it a poor reference choice; c.p. is sometimes
(obsoletely) called "center of lift," not to be confused with a.c. Only symmetric airfoils (or ones
specially designed for it) have *both* `Cm` and `dCm/dα` equal to zero about the quarter-chord — for
a general cambered airfoil only the derivative vanishes there, not `Cm` itself. This near-constancy
holds only in slower subsonic flight; at transonic/supersonic speeds the true a.c. migrates rearward
from ~25% chord to ~35–40% chord, and the resulting rearward c.p. shift causes a nose-down pitching
moment that must be corrected for (discussed later in the book) [Raymer, p. 59–61].

### Fig. 4.5 — Airfoil lift, pitching moment, and drag
*[Raymer, Fig. 4.5, p. 61]* — Three-panel classic airfoil-polar figure: (left) lift curve, `Cl` vs.
`α`, linear until near stall; (middle) pitching moment `Cm` about the quarter-chord vs. `α`, nearly
flat until it "breaks" up (unstable break) or down (stable break) near stall; (right) drag polar,
`Cl` vs. `Cd` (parabola-like shape, hence "drag polar"), showing a dotted **laminar bucket** region
of lower drag near the design `Cl`, for a laminar-flow airfoil vs. a conventional-airfoil polar.
Note: the 3-D wing drag-polar parabola comes from a real induced-drag theory; the 2-D airfoil
drag-polar "parabola" shape is purely a separation-drag artifact — there is no 2-D drag due to lift
[Raymer, p. 61–62].

Airfoil characteristics are strongly Reynolds-number dependent (`Re = Vlρ/μ`; a typical wing operates
at `Re ≈ 1–10 million`); data taken at one `Re` cannot be validly applied at a very different `Re` —
at widely different `Re` an airfoil effectively behaves like two different airfoils [Raymer, p.
61–62]. Laminar flow (and the laminar-bucket drag benefit) is very sensitive to surface smoothness —
dirt/rain/insect debris on the LE can trip the flow turbulent, erasing the bucket and materially
changing lift and pitching moment too (cited case: early laminar-flow canard homebuilts pitching
down in light rain when canard flow tripped turbulent) [Raymer, p. 62].

## §4.3 Airfoil Selection — Families, Reynolds Number, Design Practice

Historically airfoils were picked from a catalog (notably Abbott & von Doenhoff [Ref. 7]), weighing
cruise drag, stall behavior, pitching moment, available structural/fuel thickness, and manufacturing
ease. NACA's 1930s **four-digit** family (digit 1 = %camber, digit 2 = camber-location tenths, last
two = `t/c` %) is now mostly used for subsonic tail surfaces rather than wings. **Five-digit**
airfoils shift max-camber location forward for higher max lift. **Six-series** airfoils (e.g.
64-series) were designed for increased laminar flow/reduced drag and remain a common supersonic
wing-design starting point (the Mach-2 F-15 uses a modified 64A section). Other families: laminar-
flow airfoils (Wortmann, Eppler, Liebeck), NASA supercritical sections (Whitcomb et al.), NASA
Natural-Laminar-Flow sections. Modern practice increasingly designs bespoke airfoils per aircraft
(inverse pressure-distribution design methods, or whole-aircraft CFD optimization — Chapter 12)
[Raymer, p. 62–64].

### Fig. 4.6 — Typical airfoils
*[Raymer, Fig. 4.6, p. 63]* — Two-column comparison of airfoil-section silhouettes: **Early**
(Wright 1908, Bleriot, RAF-6, Göttingen 398, Clark Y, Munk M-6) vs. **NACA** (0012, 2412, 4412
four-digit; 23012 five-digit; 64A010, 65A008 six-digit) vs. **Modern** (Lissaman 7769, Ga(W)-1,
Ga-0413, Liebeck L1003, C-5A "peaky" supercritical). Illustrative silhouettes, no plotted data.

### Fig. 4.7 — Laminar airfoil
*[Raymer, Fig. 4.7, p. 64]* — Liebeck LR1022M14 section silhouette with its "rooftop" pressure
(`Cp`) distribution beneath: pressure held roughly flat/favorable from LE back to near the TE
(promoting laminar flow) before recovering. Illustrative, no plotted numeric data.

### Transonic effects and supercritical airfoils

Flying near the speed of sound, the accelerated flow over the upper (lifting) surface can go locally
supersonic, forming a shock — the Mach number at which this first happens is the **critical Mach
number** `M_crit`. Beyond `M_crit` the shock strengthens, and the associated rapid pressure rise can
thicken or separate the boundary layer, raising drag sharply — commercial airliners generally cruise
right around `M_crit` rather than faster. The upper-surface shock also cuts lift and shifts pitching
moment; for a highly swept wing the resulting lift loss (starting at the root, ahead of the c.g.) can
cause a nose-down **"Mach tuck."** A **supercritical airfoil** minimizes/eliminates the upper-surface
shock by spreading lift chordwise (reducing peak upper-surface velocity for a given total lift),
raising `M_crit` [Raymer, p. 64–65].

### Fig. 4.8 — Transonic effects
*[Raymer, Fig. 4.8, p. 65]* — Two-panel comparison at `M > M_crit`: "classic airfoil" showing a
supersonic-flow "bubble" over the upper surface with shock-induced boundary-layer thickening and
separation, vs. a shaped airfoil with a smaller supersonic bubble and less BL thickening/separation.
Diagram only, no plotted data.

## §4.4 Design Lift Coefficient

Because an as-yet-undesigned aircraft's airfoil can't be custom-optimized this early, conceptual
design instead selects from existing airfoils by proximity to a desired **design lift coefficient**
— the `Cl` at which the airfoil's L/D is best (Fig. 4.9: the point of tangency between the drag polar
and a line from the origin, closest to the vertical axis). Camber correlates directly with design
`Cl` — for NACA 6-digit airfoils, **required camber (%) ≈ 5.5 × design Cl** [Raymer, p. 65].

### Fig. 4.9 — Design lift coefficient
*[Raymer, Fig. 4.9, p. 66]* — Drag-polar plot (`Cl` vs. `Cd`) comparing a conventional airfoil polar
to a laminar airfoil polar, with the design-lift-coefficient tangent-line construction marked on
each. Diagram only, no plotted numeric data.

Approximating the wing `CL ≈` airfoil `Cl`, and using level-flight equilibrium:

**Eq. (4.4)** *[Raymer, Eq. (4.4), p. 66]*:
```
W = L = q S CL
```
**Eq. (4.5)** *[Raymer, Eq. (4.5), p. 66]*:
```
CL ≈ Cl
```
Given an assumed wing loading `W/S`, the design `Cl` follows for the velocity/altitude of key
mission points. Because `W/S` falls through the mission as fuel burns, holding the design `Cl`
requires either slowing down (undesirable) or climbing — explaining the **cruise-climb** profile
used to maximize range. For initial-layout airfoil selection, design `Cl` can be computed for key
mission points, or simply assumed from experience (**0.3–0.5** for most airplanes); later
optimization (Chapter 19) refines it for the aerodynamics staff's custom airfoil design
[Raymer, p. 66–67].

## §4.5 Stall

Three distinct 2-D stall types, driven mainly by leading-edge radius/thickness [Raymer, p. 67]:

- **Trailing-edge stall** — "fat" airfoils (round LE, `t/c` > ~14%). Turbulent BL separation begins
  at the TE near α ≈ 10°, and moves forward gradually as α increases further. **Gradual** lift loss,
  small pitching-moment change.
- **Leading-edge stall** — moderate thickness (~6–14%). Flow separates near the nose at small α but
  immediately reattaches; at some higher α it fails to reattach and the whole airfoil stalls almost
  at once. **Abrupt** lift and pitching-moment change.
- **Thin-airfoil stall** — very thin sections. A small separation bubble forms near the nose at small
  α and *stretches* toward the TE as α increases; max lift occurs when the bubble reaches the TE,
  beyond which the whole airfoil is separated. Lift loss is **smooth**, but pitching moment changes
  **greatly**.

### Fig. 4.10 — Types of stall
*[Raymer, Fig. 4.10, p. 68]* — Three-airfoil-type comparison showing separation-bubble/turbulent-
flow growth patterns (trailing-edge stall, leading-edge stall, thin-airfoil separation-bubble
stretching) alongside associated pitching-moment-vs-α trend sketches (moments about the airfoil
quarter-chord). Diagram only, no plotted numeric data.

Wing-level stall management: **washout** (tip airfoils at reduced/negative incidence vs. root) makes
the wing stall at the root first, giving gradual stall and buffet warning at the tail; using a
higher-stalling-angle airfoil at the tip than the root similarly preserves aileron authority past
root stall (requires interpolated intermediate-station airfoils between root/tip — this
interpolation approach does **not** work for supercritical/laminar-flow airfoils, which need
computational estimation instead). Wing stall characteristics track airfoil stall only for
high-aspect-ratio, low-sweep wings — for low-AR/high-sweep wings, 3-D effects dominate and airfoil
stall behavior is largely irrelevant to selection. Pitching moment also matters for airfoil
selection since it sizes the tail/canard needed to balance it — some supercritical "rear-loaded"
airfoils give excellent L/D but a large nose-down moment that can require enough tail area to erase
the drag benefit [Raymer, p. 67–68].

## §4.6 Airfoil Thickness Ratio

Thickness ratio `t/c` affects drag, max lift, stall behavior, and structural weight. Subsonic drag
rises with `t/c` (more separation); `t/c` also sets critical Mach number (thicker → lower `M_crit`,
supercritical sections can be ~10% thicker than the historical trend for the same drag). For
high-AR, moderate-sweep wings, larger nose radius (→ higher `t/c`) raises stall angle/max lift; the
reverse holds for low-AR swept/delta wings, where a sharper LE promotes stall-delaying leading-edge
vortices (a 3-D effect, discussed in the aerodynamics chapter). Wing structural weight varies
roughly as `1/sqrt(t/c)` — **halving `t/c` increases wing weight ~41%**, and since wing weight is
typically ~15% of empty weight, that's roughly a 6% empty-weight increase, which the sizing equation
can leverage into a large TOGW impact [Raymer, p. 68–69].

### Fig. 4.11 — Effect of t/c on drag
*[Raymer, Fig. 4.11, p. 69]* — `C_D_min` (0–0.0100) vs. `t/c` (%, 5–25), single monotonically rising
curve. *(read from plot)*: t/c=5%→~0.0035; 10%→~0.0050; 15%→~0.0062; 20%→~0.0080; 25%→~0.0098.

### Fig. 4.12 — Effect of t/c on critical Mach number
*[Raymer, Fig. 4.12, p. 70]* — `M_crit` (zero lift) (0.7–1.0) vs. `t/c` (%, 5–25), two curves: NACA
and Supercritical (64-1XXX). *(read from plot)*: NACA — t/c=5%→~0.90, 10%→~0.83, 15%→~0.77,
20%→~0.72, 25%→~0.68; Supercritical — t/c=5%→~0.93, 10%→~0.90, 15%→~0.86, 20%→~0.81, 25%→~0.76.

### Fig. 4.13 — Effect of t/c on maximum lift
*[Raymer, Fig. 4.13, p. 70]* — `Cl_max` (0.5–2.0) vs. `t/c` (%, 5–25), single curve rising from
`t/c`≈5% to a peak near `t/c`≈13–15% then declining. *(read from plot)*: 5%→~1.0, 10%→~1.45,
14%→~1.55 (peak region), 20%→~1.35, 25%→~1.05.

### Fig. 4.14 — Thickness ratio historical trend
*[Raymer, Fig. 4.14, p. 71]* — `t/c` (0–0.18) vs. design (maximum) Mach number (1–4), scattered
historical data with a fitted declining trend curve. *(read from plot)*: M=1→~0.11–0.12, M=1.5→~
0.07, M=2→~0.05, M=3→~0.035, M=4→~0.03. A supercritical airfoil may use ~1.1× this trend's `t/c`
at the same drag level.

Root airfoils are frequently thicker than tip airfoils (subsonic aircraft: root up to 20–60%
thicker without much drag penalty, extending to ≤~30% span) — reduces structural weight, adds
fuel/gear volume. The opposite (thicker at the tip) is sometimes used deliberately (e.g. aerobatic
aircraft) to force root-first stall, since twist-based fixes fail when flying inverted
[Raymer, p. 71].

## §4.7 Other Airfoil Considerations

Airfoils are Reynolds-number-specific; using one far outside its design `Re` (half an order of
magnitude or more) can badly change section characteristics — most acute for laminar-flow airfoils
and lower-`Re` aircraft (historically a homebuilt/sailplane problem, now addressed by purpose-
designed low-`Re` airfoils). Laminar sections need very smooth, precisely-manufactured skins
(cost driver); rough camouflage paint finishes complicate laminar-airfoil use on military aircraft.
Raymer's advice: don't over-invest time in "the perfect airfoil" in early conceptual design — later
trade studies and analytical tools drive the final choice; early on the airfoil mainly matters for
available structural/gear/fuel thickness. Appendix D supplies a small set of conceptual-design
starting airfoils (NACA 64A/65A for swept supersonic wings, a supercritical section, a modern NASA
GA section, a few specialized ones) — not claimed as "best," just reasonable starting points
[Raymer, p. 71–72].

## §4.8 Wing Geometry — The Reference (Trapezoidal) Wing

The **reference wing** is the idealized trapezoidal planform used to start the layout and to
nondimensionalize aerodynamic coefficients (hence "reference area" `S`). It is partly fictitious: it
extends through the fuselage to the centerline (even if the built wing doesn't), and has squared-off
tips even if the real tips are rounded; `S` includes both the fuselage-covered portion and the
notionally "missing" rounded-tip corners. The reference-wing root airfoil sits at the aircraft
centerline, not at the real wing-fuselage junction — it's a nondimensionalizing convenience, not a
buildable part [Raymer, p. 72].

### Fig. 4.15 — Wing geometry
*[Raymer, Fig. 4.15, p. 73]* — Trapezoidal reference-wing planform labeled with span `b`, root
chord `C_root`, tip chord `C_tip`, half-span station. Definitions given:
- `S` = reference wing area
- `c` = chord (LE to TE distance)
- `A` = aspect ratio = `b²/S`
- `t/c` = airfoil thickness ratio (max thickness/chord)
- `λ` = taper ratio = `C_tip / C_root`
- `b` = span

Given `W/S`, `A`, `λ` [Raymer, p. 73]:
```
S = W / (W/S)
b = sqrt(A · S)
C_root = 2·S / [b(1+λ)]
C_tip = λ · C_root
```

### Fig. 4.16 — Wing sweep (Λ)
*[Raymer, Fig. 4.16, p. 73]* — Planform sketch defining leading-edge sweep `Λ_LE` and quarter-chord
sweep, both measured from a line perpendicular to the aircraft centerline. Sweep is usually denoted
Δ or Λ; the two sweep angles matter for different regimes — **LE sweep** governs supersonic drag
(commonly swept behind the Mach cone), **quarter-chord sweep** is the one most tied to subsonic
behavior (per a footnote, the sweep of the *max-thickness line* is technically more correct
subsonically, but the difference from quarter-chord sweep is trivial and quarter-chord is
traditional) [Raymer, p. 74]. An equation converting between sweep angles measured at different
chord fractions is given at the figure's foot (not independently numbered in-text; for a vertical
tail, first double the aspect ratio before applying it) [Raymer, Fig. 4.16, p. 74].

### Fig. 4.17 — Mean aerodynamic chord
*[Raymer, Fig. 4.17, p. 74]* — Trapezoidal planform with the MAC `c̄` and its spanwise station
`Ȳ` from centerline marked. Equations (unnumbered, at figure foot) [Raymer, Fig. 4.17, p. 74]:
```
c̄ = (2/3)·C_root·(1 + λ + λ²)/(1 + λ)
Ȳ = (b/6)·[(1 + 2λ)/(1 + λ)]     (assumes lift ∝ chord)
```
`Ȳ` must be **doubled for a vertical tail** (its total planform area is half of an equivalent
horizontal surface of the same trapezoidal shape); all other MAC calculations are unchanged
[Raymer, p. 75].

The whole trapezoidal wing has an aerodynamic center at approximately the same %-chord location on
the MAC as the airfoil's own a.c. — subsonically, the quarter-chord of the MAC. Locating the wing so
this point gives the desired stability margin is a critical initial-design step, and the MAC
quarter-chord X-location is customarily called out on the layout drawing. Supersonically, like the
airfoil a.c., the wing a.c. migrates aft to ~35–40% MAC (addressed in Chapter 16) [Raymer, p. 75].

## §4.9 Aspect Ratio

First systematically studied by the Wright Brothers (their own wind tunnel): a long, skinny (high-AR)
wing has less drag for given lift than a short, fat (low-AR) one. Aspect ratio is `b²/S` for a
tapered wing (reduces to span/chord for an untapered rectangular wing). Physically: lift creates a
pressure difference the air "wants" to escape around the tip (Fig. 4.18), which locally cuts lift and
spins up trailing tip vortices that represent an induced-drag energy cost. A high-AR wing has its
tips farther apart relative to area, so proportionally less of the span is affected by the tip vortex
and the vortex itself is weaker — hence less drag-due-to-lift loss than an equal-area low-AR wing.
**It is actually wing span, not aspect ratio per se, that sets drag due to lift** (induced drag ∝
`1/b²`); but since wing area is usually held fixed when comparing planform options, `b ∝ sqrt(A)`,
making induced drag ∝ `1/A` in that constrained comparison [Raymer, p. 75–76].

### Fig. 4.18 — "Escape" of air around the wing tip
*[Raymer, Fig. 4.18, p. 76]* — Front/plan-view sketch: lower (higher-pressure) surface air flowing
around the tip to the upper (lower-pressure) surface, plus the resulting outward flow beneath and
inward flow above the wing (relevant to nacelle/store orientation). Diagram only, no plotted data.

Per Fig. 3.5 (Chapter 3), max subsonic L/D increases roughly as `sqrt(A)` (at fixed wing area and
`S_wet/S_ref`) — but wing weight rises by about the same factor, so higher AR is a tradeoff, not a
free lunch. Lower-AR wings stall at a higher angle of attack (Fig. 4.19) — one reason tails
(needing to stall well after the wing) tend toward lower AR, while a canard can be made to stall
*before* the wing via deliberately high AR [Raymer, p. 77].

### Fig. 4.19 — Effect of aspect ratio on lift
*[Raymer, Fig. 4.19, p. 77]* — `CL` vs. `α` comparison sketch: high-AR wing (steeper slope, stalls
at lower α) vs. low-AR wing (shallower slope, stalls at higher α). Diagram only, no plotted data.

### Table 4.1 — Aspect Ratio (historical/statistical trends)
*[Raymer, Table 4.1, p. 78]*. "Equivalent aspect ratio" = span² / (wing + canard area), from
statistical analysis of a fleet of aircraft [Ref. 6]:

| Category | Equivalent AR |
|---|---|
| Sailplane | `0.19 · (best L/D)^1.3` |
| **Propeller aircraft** | |
| Homebuilt | 6.0 |
| General aviation — single engine | 7.6 |
| General aviation — twin engine | 7.8 |
| Agricultural aircraft | 7.5 |
| Twin turboprop | 9.2 |
| Flying boat | 8.0 |
| **Jet aircraft** (`Equivalent AR = a·M_max^b`) | a, b |
| Jet trainer | a=4.737, b=−0.979 |
| Jet fighter (dogfighter) | a=5.416, b=−0.622 |
| Jet fighter (other) | a=4.110, b=−0.622 |
| Military cargo/bomber | a=5.570, b=−1.075 |
| Jet transport | 7.50 to 10 (no Mach-trend fit given) |

Sailplane AR statistically ties to desired glide ratio (=L/D); propeller aircraft show no clear
trend (average values shown); jet aircraft AR statistically **decreases** with max Mach number
(drag-due-to-lift matters relatively less at higher speed, so designers save weight with lower AR)
[Raymer, p. 77–78]. For a lifting-canard aircraft, this equivalent AR uses combined wing+canard
area; since canards typically carry ~10–25% of total lifting area, actual wing AR = equivalent
AR / (0.75–0.9) [Raymer, p. 78].

Aspect ratio is often ultimately set by an engine-out climb-rate requirement for multi-engine
aircraft (cited case: DC-10-20 needed a 10-ft/3-m span increase to restore FAA-required engine-out
climb after a weight increase over earlier models) [Raymer, p. 78].

## §4.10 Wing Sweep

Sweep nominally looks disadvantageous — raises wing weight, cuts lift by `cos(sweep)`, degrades
aileron/flap effectiveness, and raises wingtip ground-strike risk on a bad landing (best sweep for a
low-speed, especially prop, airplane is usually zero) — but most high-speed aircraft sweep the wing
anyway because sweep delays shock formation: the relevant velocity for shock onset is roughly the
component perpendicular to the leading edge, which is lower than the true airstream velocity on a
swept wing, raising `M_crit`. Supersonically, sweeping the LE aft of the Mach cone angle
(`arcsin(1/M)`) reduces supersonic lift loss/drag rise and improves supersonic drag-due-to-lift
(Chapter 12) [Raymer, p. 79].

### Fig. 4.20 — Wing sweep historical trend
*[Raymer, Fig. 4.20, p. 79]* — Wing LE sweep (deg, 0–90) vs. maximum Mach number (0–4): a
theoretical curve `90° − arcsin(1/M)` (the sweep placing the LE exactly on the Mach cone) plus a
fitted historical-trend line through scattered real-aircraft data points (outlier near M=2,
~30° sweep = F-104, whose LE was sharp enough to need protective edge guards on the ground).
*(read from plot)*: theoretical curve — M=1→0° (undefined/asymptotic), M=1.5→~48°, M=2→~60°,
M=2.5→~66°, M=3→~70°; historical trend line sits below theory at high Mach (practical sweep
limits: ~60° at M=2.5 vs 66° theoretical, since past some point the LE stays supersonic and
sharp/near-sharp airfoils are used instead to control the drag penalty) [Raymer, p. 79–80].

Reasons the trend departs from theory: at high `M` it becomes structurally impractical to sweep
past the Mach cone (e.g. 66° needed at M=2.5), so practical designs accept a supersonic leading edge
(using sharp/near-sharp airfoils to control drag; blunt LE + high drag is sometimes forced anyway by
thermal considerations, e.g. Space Shuttle). Near/below M=1, the theoretical answer (zero sweep) is
overridden because high-subsonic upper-surface acceleration still creates local supersonic flow and
shocks — so sweep is still chosen to keep the perpendicular-to-LE flow subsonic, with the exact
value depending on airfoil/thickness/taper and target Mach. Airliners are typically designed so
cruise Mach = `M_crit` [Raymer, p. 80].

Other sweep motivations: no theoretical aft-vs-forward difference (aft historically preferred to
avoid forward-sweep structural divergence — composites now allow forward sweep at a small weight
penalty, Chapter 22); an **oblique wing** (one side swept aft, other forward) gives unusual but
computer-manageable control response and lower wave drag via better volume distribution (Chapters
8, 22); sweep can relocate the wing carry-through structure for balance (e.g. canard pushers, often
tail-heavy, use sweep to move the a.c. aft) [Raymer, p. 80–81]. Sweep also gives a natural dihedral
effect (often requiring reduced/negative geometric dihedral to avoid excess stability), and — with
some washout — extra pitch stability from the forward c.g. shift it requires; sweeping tip-mounted
vertical tails aft increases their moment arm/effectiveness [Raymer, p. 81].

Sweep + aspect ratio together drive wing-alone **pitch-up** risk (uncontrolled AoA increase near
stall — the F-16 needs a computerized AoA limiter for this at ~25° AoA) [Raymer, p. 81].

### Fig. 4.21 — Tail-off pitch-up boundaries
*[Raymer, Fig. 4.21, p. 82]* — Aspect ratio (0–10) vs. quarter-chord sweep (deg, 0–80), data from
NASA TN 1093, with a boundary curve separating "increased stability at high AoA" (lower-left) from
"increased pitch-up risk at high AoA" (upper-right). *(read from plot)*: boundary passes roughly
through (sweep=0°, AR≈8.5), (sweep=20°, AR≈7), (sweep=35°, AR≈5), (sweep=45°, AR≈3.5), (sweep=60°,
AR≈2.2), (sweep=80°, AR≈1). Wing-alone data; a well-designed horizontal tail (or a large all-moving
canard, e.g. X-29) can allow a higher AR than the wing-alone boundary suggests [Raymer, p. 81–82].

Variable-sweep wings (F-111, F-14, B-1B, Tornado, Tu-22M; considered/rejected for the Boeing SST)
give the best of both regimes but at a real cost: the aerodynamic center moves substantially with
sweep angle while the c.g. moves much less, requiring fuel-transfer c.g. management and/or heavy tail
download to balance, plus a pivot-mechanism weight penalty — **~4% total empty-weight increase**
per Table 3.1, or **~19%** wing-weight-alone increase per Chapter 15's detailed statistical weight
equations [Raymer, p. 82].

## §4.11 Taper Ratio

`λ` = tip chord / root chord. Low-sweep wings: `λ ≈ 0.4–0.5`; swept wings: `λ ≈ 0.2–0.3`. Per Prandtl
wing theory, minimum induced drag occurs for an **elliptical** spanwise lift distribution, achieved
(for an untwisted, unswept wing) by an elliptical planform (Fig. 4.22 — basis of the Spitfire's wing)
— but an elliptical planform is expensive to build. A **taper ratio of 0.45** on an untwisted,
unswept **straight-tapered** wing very closely approximates the elliptical lift distribution (<1%
higher induced drag than the true ellipse — Fig. 4.23); accounting for the weight savings of more
taper, **λ ≈ 0.4** is judged ideal for most unswept wings (an untapered `λ=1.0` rectangular wing has
~7% more induced drag than an elliptical wing of the same AR) [Raymer, p. 82–83].

### Fig. 4.22 — Elliptical wing
*[Raymer, Fig. 4.22, p. 83]* — Planform silhouette of a pure elliptical wing (Spitfire-like).
Illustrative, no plotted data.

### Fig. 4.23 — Effect of taper on lift distribution
*[Raymer, Fig. 4.23, p. 84]* — Section lift-coefficient ratio (0–1.6) vs. normalized span location
(root=0 to tip=1.0), four curves: λ=0 (triangular), λ=0.5, λ=1.0 (rectangular), and the ideal
elliptic loading. *(read from plot)*: at midspan (x/(b/2)=0.5) — elliptic≈1.0 (reference), λ=0.5
tracks very close to elliptic (~0.98–1.0), λ=1.0 (rectangular) sits above elliptic near midspan
(~1.15) and drops off sharply near the tip, λ=0 (pure taper to a point) sits below elliptic through
midspan (~0.75) and rises sharply approaching the tip.

Sweeping a wing aft diverts spanwise flow outboard, "loading up" the tips relative to an equivalent
unswept wing — countered by using *more* taper (lower `λ`) as sweep increases.

### Fig. 4.24 — Effect of sweep on desired taper ratio
*[Raymer, Fig. 4.24, p. 84]* — Desired taper ratio (0–1.0) vs. quarter-chord sweep (deg, −40 to
+80), a fitted curve through real-aircraft data points (labeled examples: Tomahawk, X-29, Starship,
YC-14, S3A, A-4, F-5, F-16), after NASA 921, for untwisted planforms approximating elliptical
loading. *(read from plot)*: sweep=−22°→λ≈1.0 (rectangular; this is the unusual forward-swept
untapered planform discussed as the book's own Fig. 2.6 example — chosen for its constructability,
but incurred a root-thickness-driven weight penalty that made it size to a *higher* TOGW than a
conventional design); sweep=0°→λ≈0.45; sweep=20°→λ≈0.35; sweep=40°→λ≈0.25; sweep=60°→λ≈0.15;
sweep=80°→λ≈0.05 (delta-like). Taper ratios below ~0.2 should generally be avoided (except deltas)
since very low `λ` promotes tip stall [Raymer, p. 84–85].

The unusual Republic XF-91 used **reverse taper** (`λ>1`, tip chord bigger than root) to fight tip
stall/interference — "worked poorly, looked really strange, added weight, hasn't been attempted
since" [Raymer, p. 85].

## §4.12 Twist

Wing twist ("washout" when the tip is at reduced/negative incidence vs. the root, typically 0 to
−5°) prevents tip stall and reshapes the lift distribution toward elliptical. **Geometric twist** =
actual incidence-angle change from root to tip (usually "linear," i.e. proportional to span
distance — nonlinear twist can be more optimal but needs computational design). **Aerodynamic
twist** = difference in zero-lift angle between a given station's airfoil and the root airfoil
(equals geometric twist if the same airfoil is used root-to-tip; total wing aerodynamic twist =
geometric twist + root zero-lift angle − tip zero-lift angle). Because a given twist distribution
only truly optimizes the lift distribution at *one* `CL`, large twist angles (much beyond 5°) are
avoided since they penalize off-design `CL`s. Rule of thumb: **−3° twist** gives adequate stall
characteristics for initial design. If washout is layered onto the Fig. 4.24 taper-ratio result, the
tip-lift reduction from washout means the ideal taper ratio should be increased slightly (shown as
the dotted-line correction in Fig. 4.24) — the opposite direction from what's best structurally
(lower `λ` is lighter), one more design tradeoff [Raymer, p. 85–86].

**Wing incidence** (pitch angle vs. fuselage reference) is chosen to minimize drag at a reference
condition (usually cruise) — putting the fuselage near its own minimum-drag AoA when the wing sits
at its design AoA. Typical initial values: **~2° for GA/homebuilt, ~1° for transports, ~0° for
military aircraft** (untwisted-wing values; a twisted wing should average to these) [Raymer, p.
86–87].

## §4.13 Dihedral

**Dihedral** = wing angle above horizontal, viewed from the front. Positive dihedral (tips up) rolls
the aircraft back level after a bank — the true mechanism is the sideslip induced by bank angle
(the aircraft "slides downhill" toward the low wing, and that sideways/yaw-like velocity increases
lift on the low wing — Fig. 4.25), *not* the commonly-cited-but-incorrect "greater projected area of
the lowered wing" explanation. Sweep independently creates a rolling moment due to sideslip,
proportional to `sin(2·sweep)` — for aft sweep this behaves like added positive dihedral (**rule of
thumb: 10° of sweep ≈ 1° of effective dihedral**); forward sweep needs *more* geometric dihedral to
compensate its negative effective-dihedral contribution [Raymer, p. 87–88].

### Fig. 4.25 — Increased angle of attack and lift
*[Raymer, Fig. 4.25, p. 88]* — Front-view sketch of a banked aircraft, showing the sideslip-induced
local flow vector on the lowered wing giving it an increased effective AoA. Diagram only, no plotted
data.

Wing vertical position on the fuselage also contributes an effective-dihedral term (largest for a
high wing) via the fuselage's own sideslip-induced flow deflection (not, as often claimed, a
"pendulum effect"). Because sweep + high-wing position both add positive effective dihedral,
high-wing swept transports (e.g. Lockheed C-5) often need **negative geometric dihedral** to avoid
excess total effective dihedral, which otherwise causes **Dutch roll** (needing a larger, heavier
vertical tail to damp) [Raymer, p. 88].

### Table 4.2 — Dihedral Guidelines
*[Raymer, Table 4.2, p. 89, developed by the author from Ref. 6 data]*

| Configuration | Low wing | Mid wing | High wing |
|---|---|---|---|
| Unswept (civil) | 5 to 7 | 3 to 7 | −2 to 2 |
| Subsonic swept wing | 0 to 5 | −5 to 0 | 0 to 2 |
| Supersonic swept wing | −5 to −2 | −5 to 0 | (not given) |

(Table reconstructed from the OCR'd column layout — values are in degrees. `[verify p. 89 — column/
row alignment inferred from surrounding prose; original table columns may be ordered differently]`.)

## §4.14 Wing Vertical Location

Vertical-location choice (high/mid/low) is driven heavily by mission/operating environment. **High
wing**: lets the fuselage sit closer to the ground (Fig. 4.26) — military transports (C-17, C-5,
C-141) exploit this for truck-bed-height (~4–5 ft/1.5 m) cargo-floor loading without ground support
equipment; gives engine/prop ground clearance without long gear legs, and swept high-wing tips are
less likely to strike the ground in a nose-high/rolled attitude — hence generally lighter landing
gear. STOL designs favor high wing for large-flap clearance, reduced ground-effect "floating," and
keeping engines/props away from unimproved-field debris. Disadvantages: heavier fuselage (must carry
gear loads, plus flattening for cargo-floor height, plus usually an external gear blister and a
wing-root fairing), reduced pilot visibility in turns/climbs (mitigated with roof windows in light
aircraft) [Raymer, p. 89–90].

### Fig. 4.26 — High wing
*[Raymer, Fig. 4.26, p. 89]* — Front-view sketch of a high-wing aircraft showing the wing-fuselage
fairing at the junction. Diagram only, no plotted data.

**Mid wing**: lowest-drag option for a circular fuselage without fairings; popular on fighters (belly
clearance for stores, and avoids blocking rearward visibility the way a high wing would); probably
best for aerobatics (low/high-wing dihedral effects work the wrong way inverted). Major drawback:
structural carry-through (bending-moment transfer across the fuselage) — a carry-through box is
lighter but can't be used where the midwing box would cross a cargo/passenger compartment (exception:
the Hansa executive jet uses mild forward sweep to place the carry-through box behind the cabin)
[Raymer, p. 90–91].

### Fig. 4.27 — Midwing
*[Raymer, Fig. 4.27, p. 91]* — Front-view sketch of a midwing arrangement with "6 in. (15 cm)
clearance" ground-clearance callout. Diagram only, no plotted data.

**Low wing**: best for landing-gear stowage (trunnion attaches directly to the already-strong wing
box, retracting into wing/wing-fairing/nacelle with no external blister); needs the fuselage held
farther off the ground for engine/prop clearance, which — usefully — also reduces the aft-fuselage
upsweep needed for takeoff rotation AoA (less upsweep = less drag). Large transports' ~20-ft (6-m)
fuselage diameter comfortably clears an above-passenger-floor carry-through box, splitting the lower
cargo bay in two — near-universal for commercial transports. A dihedral-free low-wing center section
permits a single continuous under-fuselage flap (simpler, avoids asymmetric-flap-failure risk, more
lift/drag than a fuselage-split flap). Drawbacks: worse ground clearance (dihedral sometimes set by
tip-strike avoidance rather than aerodynamics, which can then force a larger vertical tail to counter
Dutch roll), and low-wing propellers are often mounted well above the wing plane to preserve gear
length, worsening wing-prop interference/cruise fuel consumption [Raymer, p. 91–92].

### Fig. 4.28 — Low wing
*[Raymer, Fig. 4.28, p. 92]* — Front-view sketch of a low-wing arrangement with "6 in. (15 cm)
clearance" and a "5 deg" ground-clearance/tip-strike callout. Diagram only, no plotted data.

## §4.15 Wing-Tip Shaping

Since tip-vortex-driven induced drag comes from lower-surface air escaping around the tip to the
upper surface, tip shaping is a lever on both lift retention and drag. A smoothly rounded tip looks
streamlined but actually eases the escape flow (worse aerodynamically); sharp-edged tips (even a
simple cutoff) resist it better, hence most modern low-drag tips use some sharp-edge form
[Raymer, p. 92–93].

### Fig. 4.29 — Wing tips
*[Raymer, Fig. 4.29, p. 93]* — Gallery of tip cross-sections/planforms: Rounded, Sharp, Cut-off,
Hoerner, Droop, Upswept, Aft-swept cut-off, Winglet, Forward-swept. Illustrative silhouettes, no
plotted numeric data.

Specific tip types [Raymer, p. 93–95]:
- **Hoerner tip** [Ref. 9] — sharp-edged, all reshaping done on the *lower* surface (undercut,
  canted ~30° to horizontal, sometimes undercambered/concave), leaving the (lift-dominant) upper
  surface's airfoil shape unbroken to the tip.
- **Drooped/upswept tips** — "trap" air by curving the tip up or down, working similarly to
  endplates/winglets (increase *effective* span without increasing actual span) but add wetted area
  (parasite drag), weight, torsional load, and flutter risk if poorly designed.
- **Aft-swept tip** — since the tip vortex forms roughly at the tip trailing edge, an aft-swept tip
  (longer TE span) tends to lower drag, at a wing-torsional-load cost.
- **Cutoff forward-swept tip** — used on some supersonic aircraft (F-15 wings and horizontal
  tails), cut at the Mach-cone angle since wing area inside the tip shock cone contributes little
  lift anyway; also eases torsional load and flutter.
- **Endplate** — a vertical plate at the tip blocking the escape flow directly; adds its own wetted-
  area drag, and only recovers ~80% of the span-increase benefit an equal-height span extension
  would give — usually better to just increase span, unless span itself is constrained.
- **Winglet** (Whitcomb) — an angled/cambered "little wing" rising from the tip, exploiting the tip
  vortex's locally inward-angled flow to generate a forward-pointing lift component (effectively
  negative drag); can raise L/D by up to 20%, and — viewed as an effective-span increase — can be
  worth up to *double* the span-equivalent of its own added height. Biggest benefit on wings with a
  strong tip vortex (lower-than-optimal AR, or an aircraft now heavier than originally sized for);
  little/no benefit on an already-efficient high-AR wing. Downsides: adds weight aft of the elastic
  axis (flutter risk), and is optimized for one design speed only (can increase drag off-design) —
  so winglets are mostly retrofits to existing wings rather than a first choice on a clean-sheet
  wing, where increased AR is usually preferred (a trade study should still be run).

## §4.16 Biplane Wings

Once dominant (first ~30 years of aviation — Chanute's bridge-truss-inspired lightweight biplane
gliders influenced the Wright Brothers), biplanes today are mainly used where structural-weight
efficiency matters more than aerodynamic efficiency, or where low speed is wanted without complex
high-lift devices or long span — chiefly modern aerobatic aircraft (shorter span → higher roll
rate) [Raymer, p. 95].

Theoretically a biplane with the same total span as a monoplane should have **half** the induced
drag (each half-loaded wing carries 1/4 the drag of the full wing, ×2 wings = 1/2 total) — but
mutual interference erodes this: good design gets **~30%** induced-drag reduction vs. an
equal-span monoplane in practice. Full theoretical benefit also requires each biplane wing to have
*double* the monoplane's AR at equal total area/span — rarely done, given the weight penalty, so
biplanes rarely realize the full theoretical benefit [Raymer, p. 95–96].

Key biplane-specific parameters [Raymer, p. 96]:
- **Gap** — vertical separation between wings; larger gap → closer to the ideal half-drag result,
  but structural weight/strut drag typically caps gap at about one average chord length.
- **Span ratio** — shorter wing span / longer wing span (=1 if equal); minimum induced drag (for a
  span-limited design, the only real technical reason to pick a biplane) comes from equal-length
  wings, though a shorter lower wing has historically been used for ground clearance.
- **Stagger** — longitudinal offset between the wings (positive = upper wing forward); little drag
  effect, mainly used to improve cockpit visibility (e.g. negative stagger on the Beech D-17
  Staggerwing, also easing lower-wing-flap pitching moment).
- **Decalage** — relative incidence angle between wings (positive = upper wing at larger incidence);
  historically tuned to minimize induced drag while making the front wing stall first for natural
  recovery; most post-WWI biplanes use zero decalage (exception: Pitts Special, +1.5°).

Most biplane wing-geometry guidance (AR 6–8 typical, taper as for a monoplane though many biplanes
are untapered for manufacturing ease, ~2° dihedral, sweep for stability/visibility/gear clearance)
follows the monoplane discussion above. The biplane's combined MAC is the area-weighted average of
the two wings' MACs; its **aerodynamic center sits at ~23% MAC** (vs. 25% for a monoplane) due to
wing-wing interference [Raymer, p. 96–97].

## §4.17 Tail Functions

Tails are "little wings," but unlike a wing (routinely near its lift limit), a tail normally operates
well below its max-lift potential — any time a tail nears stall, something has gone wrong. Tails
provide **trim** (a moment-arm lift force about the c.g. balancing another aircraft moment),
**stability** (restoring moments after a pitch/yaw upset), and **control** [Raymer, p. 97].

**Horizontal tail trim**: mainly balances wing pitching moment; a typical aft tail runs ~2–3°
negative incidence, adjustable ~±3° since the wing moment varies with flight condition
[Raymer, p. 97].

**Vertical tail trim**: most aircraft are left-right symmetric so no steady yaw trim is normally
needed, but propeller aircraft see **P-effect** (asymmetric blade AoA/velocity when the prop disk is
inclined, e.g. in climb) producing a yaw moment — countered on many single-engine aircraft by
offsetting the vertical tail a few degrees. Multi-engine vertical tails must also trim engine-out
yaw (lost thrust + extra drag from the dead/windmilling engine); some designs use counter-rotating
props to cut this (the P-38's counter-rotation direction was chosen for gun-aiming reasons instead,
worsening engine-out rollover risk — pilots had to cut power on the live engine immediately after a
failure) [Raymer, p. 97–98].

**Control**: horizontal tail/canard critical sizing cases — nosewheel liftoff, low-speed flaps-down
flight, transonic maneuvering. Vertical tail critical cases — low-speed engine-out flight, max roll
rate, spin recovery. Control power depends on both movable-surface size/type and total tail area
(e.g. double-hinged rudders add engine-out control power without a bigger vertical tail; some
fighters, e.g. YF-12/F-107, use all-moving verticals instead of separate rudders) [Raymer, p. 98].

## §4.18 Tail Arrangement

### Fig. 4.30 — Aft tail variations
*[Raymer, Fig. 4.30, p. 99]* — Comparison sketches of conventional, T-tail, cruciform, and H-tail
aft-tail arrangements. Illustrative silhouettes, no plotted data.

- **Conventional** — the majority (~70%+) arrangement; adequate stability/control at lowest weight,
  smooth local airflow, easy structural attachment and control-linkage routing.
- **T-tail** — heavier (vertical tail must support the horizontal tail structurally) but gets an
  endplate effect (smaller required vertical tail), lifts the horizontal tail clear of wing
  wake/propwash (more efficient, less buffet/fatigue), and (e.g. DC-9, 727) frees the aft fuselage
  for pod-mounted engines; also "considered stylish" [Raymer, p. 98–99].
- **Cruciform** — a T-tail/conventional compromise, raising the horizontal tail just enough to
  clear a jet exhaust (B-1B) or expose the lower rudder at high AoA/spins, at less weight penalty
  than a full T-tail (but without the T-tail's endplate area-reduction benefit) [Raymer, p. 99].
- **H-tail** — twin verticals positioned in undisturbed high-AoA flow (T-46) or in prop wash for
  engine-out control on multi-engine aircraft; heavier than conventional but gets endplate benefit
  (smaller horizontal tail). On the A-10 it also shields hot nozzles from heat-seeking missiles;
  H-tails/triple-tails have also been used to fit height-limited hangars (Lockheed Constellation)
  [Raymer, p. 99].

### Fig. 4.31 — Notional V-tail gullwing homebuilt
*[Raymer, Fig. 4.31, p. 100, D. Raymer 2005]* — Illustrative homebuilt concept sketch showing a
V-tail arrangement. No plotted data.

**V-tail**: theoretically less wetted area for given effective horizontal+vertical tail area
(Pythagorean-theorem sizing, dihedral angle = arctan of the vertical/horizontal area ratio), but NACA
research [Ref. 10] found V-surfaces must actually be upsized to about the combined area of separate
horizontal+vertical tails for adequate stability/control (extreme dihedral interacts badly with AoA
changes) — so the wetted-area savings mostly evaporate, though interference drag is still reduced.
Control complexity: rudder + elevator inputs must be blended ("mixed") into ruddervator deflections;
a rudder-pedal input causes **adverse roll-yaw coupling** (opposing the desired turn direction)
[Raymer, p. 99–100].

### Fig. 4.32 — Notional inverted-V pusher
*[Raymer, Fig. 4.32, p. 101, D. Raymer 2005]* — Illustrative pusher-prop concept with an inverted
V-tail. No plotted data.

**Inverted V-tail** avoids the adverse coupling (gives desirable *proverse* roll-yaw coupling, and
reduced spiral tendency) but complicates ground clearance. **Y-tail** — reduced-dihedral V plus a
separate lower vertical fin carrying the rudder (V surfaces do pitch only) — avoids ruddervator
mixing complexity while still cutting interference drag vs. conventional; useful on pusher designs
as the lower fin doubles as a tail skid/prop-strike guard. An **inverted Y-tail** (F-4) keeps the
horizontal surfaces out of the wing wake at high AoA [Raymer, p. 100–101].

**Twin tails** (fuselage-mounted) move rudders off centerline, away from wing/fuselage blanketing at
high AoA, or simply to reduce single-tail height; heavier than an equal-area single tail but often
more effective (seen on F-14/F-15/F-18/MiG-25). **Boom-mounted tails** enable pusher props or
mid-c.g. jet-engine placement, at a tail-boom weight penalty; can carry mid- or high-mounted
horizontals (Cessna Skymaster), inverted-V arrangements (Aerosonde UAV), or verticals with no
connecting horizontal at all (NASA HiMat, pitch handled by a canard instead). The **ring-tail**
(airfoil-section ring around the aft fuselage, often doubling as a prop shroud) has proven
inadequate in practice (the ring-tail JM-2 raceplane was eventually converted to a T-tail)
[Raymer, p. 101–102].

### Fig. 4.33 — Aft tail positioning
*[Raymer, Fig. 4.33, p. 102, data: NACA TMX-26]* — Vertical tail-position parameter (roughly
tail-height above/below the wing quarter-chord extended line, in wing-chord units, −2 to +2) vs.
tail-arm/`c̄_wing` ratio (0–5), with regions marked "Okay subsonic only" and "Best location for
tail." *(read from plot)*: the "best location" band sits roughly between −1 and 0 (i.e. at or
somewhat below the wing chord-extended line) across tail-arm ratios of about 1.5–4; the
"subsonic-only-okay" band sits roughly in line with the wing (near 0) — acceptable subsonically but
risking wing-wake interaction supersonically. Low tails are generally best for stall recovery
(avoiding wing-wake blanketing); a tail in line with the wing works subsonically but risks trouble
supersonically due to the wing wake [Raymer, p. 102].

A T-tail needs the wing itself to avoid pitch-up without any horizontal-tail help (Fig. 4.21 — the
tail may be wake-blanketed at high AoA, so recovery must come from the wing alone); several T-tail
aircraft have suffered unrecoverable **deep stall** (one T-tail trainer measured 3–7× more likely to
have a stall/spin accident than peers), though some GA designs deliberately exploit the tail-buffet-
onset as a stall warning cue [Raymer, p. 102].

### Fig. 4.34 — Other tail configurations
*[Raymer, Fig. 4.34, p. 103]* — Gallery of non-aft-tail arrangements: canard (tail-forward),
multiple-wing, multiple-tail, and tailless configurations. Illustrative silhouettes, no plotted
data.

### Canards

Used by the Wright Brothers, canards fell out of favor over stability difficulties (the early Wright
canards required continuous, rapid manual correction) but offer real advantages: undisturbed
(hence predictable) local flow at the pitch surface; can be designed to stall before the wing for
inherent stall safety (seen on Rutan homebuilts like the VariEze — achieved via higher canard AR
plus wing sweep/LE cuffs); can actively fight pitch-up via large downward-deflecting (45°+)
all-moving canard authority (X-31, flown to 70° AoA, needs a computerized FCS); and, for highly-swept
wing+canard pairs, can beneficially couple canard and wing leading-edge vortices to augment wing
lift (SAAB Viggen, Rockwell HiMat) [Raymer, p. 103–104].

The popular claim that canards inherently beat aft-tail designs on lift/drag (since an aft tail's
stabilizing download costs drag and forces a bigger wing) is misleading unless comparing like-for-
like: making a canard aircraft naturally stable requires a far-forward c.g. so the canard (not the
wing) carries a disproportionate share of weight — meaning the wing must be *larger* to hit stall-
speed requirements, adding weight/drag of its own. A computer-stabilized canard can move the c.g.
aft and let the wing "do its share," but a modern computer-stabilized *aft-tail* design (the F-16
being the first production example, 40+ years ago) similarly flies with tail *upload* rather than
download — so comparing an old download-on-tail conventional design against a modern computer-
controlled canard is an apples-to-oranges comparison [Raymer, p. 104–105].

Two canard classes [Raymer, p. 105]:
- **Control-canard** — sized like an aft tail (low AR, low camber — Gripen, Typhoon, X-29, X-31),
  carries little lift itself, mainly modulates wing AoA; laid out to be near-neutrally-stable with
  the canard notionally removed, and flight-control-computer-held near zero local AoA except when
  deflected for control; usually an all-moving pivoting surface. If it locks in place the aircraft
  becomes severely unstable — a frozen air-data sensor caused exactly this loss of control on the
  X-31 (pilot ejected safely).
- **Lifting-canard** — sized like a real wing (higher AR, cambered), carries lift continuously; its
  relative size is set more by balance considerations than control. In the extreme this becomes a
  **tandem wing** (canard as big as the main wing) — Samuel Langley's unmanned "Aerodrome" (tandem
  wing + aft tail) flew almost a mile seven years before the Wright Brothers.

### Fig. 4.35 — Downwash effect on back wing's lift
*[Raymer, Fig. 4.35, p. 106]* — Side-view sketch: freestream flow direction turned downward by the
front wing's downwash, so the aft wing sees a reduced effective AoA increase for a given fuselage
AoA increase, plus a rearward-tilted lift vector (a new drag term) on the aft wing. Diagram only,
no plotted data.

The often-claimed **tandem-wing 50%-induced-drag reduction** (splitting the load between two wings,
each then paying only 1/4 the single-wing induced drag, ×2 = 1/2 total) fails in practice for two
reasons: (1) it only holds if each half-wing keeps the *original* full span (i.e. doubled AR each),
which real tandem designs rarely do because of the resulting weight penalty; (2) more fundamentally,
the aft wing flies in the front wing's downwash, so when the nose pitches up the front wing gets the
*full* AoA increase (and its extra lift) while the aft wing — its local flow direction already
turned by the front wing — gets *less* extra lift. Full-extra-lift-front / less-extra-lift-aft
creates a **destabilizing nose-up moment** — the front wing's downwash literally makes the aircraft
unstable. Natural pitch stability then requires the c.g. well forward of an even weight split, making
the aft wing "lazy" (under-loaded), which — to meet stall-speed requirements — forces *larger* total
lifting area, erasing the drag benefit. The problem worsens with flaps: front-wing flaps (near the
c.g.) barely pitch the aircraft, but aft-wing flaps (far from the c.g.) create a huge nose-down
moment that can't be balanced — so tandem-wing designs normally can't flap the back wing at all,
forcing even larger unflapped area to meet stall-speed requirements [Raymer, p. 106–107].

Despite the drawbacks, tandem-wing configurations are sometimes chosen anyway: front-wing-first
stall gives inherent stall safety (Mignet's "Flying Flea" homebuilt), or the arrangement suits
carrying a large bulky load "like a log" between the wings (Scaled Composites White Knight /
SpaceShipOne) [Raymer, p. 107].

A **lifting-canard** aircraft is essentially a small-front-wing tandem, inheriting the same
downwash-driven balance/flap problems (some designs use slotted canard flaps or a canard that sweeps
forward for takeoff/landing, e.g. Beech Starship, to get at least some flap benefit). Moving the c.g.
further aft improves lifting-canard efficiency but erodes stability, eventually requiring a
computerized FCS — and pushing the c.g. back enough eventually turns a lifting-canard into a
control-canard [Raymer, p. 107].

A **three-surface** aircraft (both aft tail and lifting canard) lets the canard trim/control
efficiently without the flap difficulties of a canard-only design, and can theoretically minimize
trim drag (canard and tail generating opposite trim forces cancel their net effect on total lift
distribution) — though this is a theoretical far-field result not necessarily fully realized, and
the extra surfaces cost weight/complexity/interference drag [Raymer, p. 107–108].

The **"back-porch"/"aft-strake"** — a horizontal control surface faired into a wing/fuselage
extension (X-29) — mainly guards against pitch-up but can double as a primary pitch-control surface
[Raymer, p. 108].

### Tailless configurations

Lowest weight/drag *if* it can be made to work. A **stable** tailless wing needs reflex/twist for
natural stability (an efficiency cost); an **unstable**, computer-controlled tailless wing can skip
this and even be made "self-trimming" (flap angles needed for balance across speeds happen to
coincide with near-optimal lift flap angles) — but this is difficult and very c.g.-sensitive; all
tailless designs are sensitive to c.g. location and work best when expendable fuel/payload sit close
to the empty c.g. [Raymer, p. 108].

Eliminating the vertical tail too (full flying wing) is the hardest stabilization case; absent
thrust vectoring, rudder control must come from wingtip drag devices (B-2's split trailing-edge
tips). Thrust-vector directional stabilization was demonstrated on the X-31 (rudder/ailerons
deliberately cancelled the vertical tail's stabilizing effect, nozzle vectoring held yaw — reached
~70% "effective tail removal" before running out of control authority) [Ref. 11] and validated more
fully by the unmanned X-36 (no vertical tail at all, naturally yaw-unstable, thrust-vectored, 31
flights, still had a pitch canard) [Raymer, p. 108].

### Fig. 4.36 — Tailless future airliner
*[Raymer, Fig. 4.36, p. 109, D. Raymer N+3 study for NASA-GRC]* — Concept sketch of a tube-fuselage
tailless airliner with a pop-out canard and small all-moving chin rudder, from a NASA Glenn N+3
study targeting 70% fuel-burn reduction vs. a Boeing 737-800 baseline. Removing both tails saved 10%
cruise wetted area with no frontal-area/structure penalty; combined with other advanced technologies
the study found a 60% fuel-consumption reduction [Ref. 12]. Illustrative concept, no plotted
numeric data beyond the cited percentages [Raymer, p. 109–110].

Drooped outer-wing panels on some tailless designs act like an inverted V-tail, giving proverse
roll-yaw coupling; winglets/endplates can substitute for a vertical tail if positioned far enough aft
(needs extreme sweep and/or a canard) [Raymer, p. 109].

## §4.19 Tail Arrangement for Spin Recovery

Spin recovery requires un-stalling the wing, which first requires stopping rotation/reducing
sideslip — needing effective rudder control even at high AoA, where the stalled horizontal tail
sheds a turbulent wake extending upward at roughly 45°.

### Fig. 4.37 — Tail geometry for spin recovery
*[Raymer, Fig. 4.37, p. 110]* — Sequence of tail-arrangement sketches showing progressively less
rudder blanketing by the horizontal-tail wake: (1) rudder fully inside the wake (poor control);
(2) horizontal tail moved forward relative to vertical tail, uncovering part of the rudder;
(3) horizontal tail moved aft relative to vertical tail, same effect; (4)-(5) horizontal tail moved
upward, culminating in a T-tail that fully uncovers the rudder (but risks pitch-up/elevator
blanketing instead); (6) dorsal + ventral fin addition. Rule of thumb: **at least 1/3 of the rudder
area should be unblanketed**. Diagram only, no plotted numeric data beyond that rule of thumb
[Raymer, p. 110–111].

The dorsal fin improves high-sideslip tail effectiveness via an attached vortex on the vertical tail
(reduces spin sideslip angle, aids rudder control in a spin); the ventral fin similarly limits high
sideslip and, being below the fuselage, is immune to wing-wake blanketing — ventral tails are also
used to avoid high-speed lateral instability [Raymer, p. 111].

## §4.20 Tail Geometry

Tail areas scale with wing area, so cannot be finalized before an initial TOGW estimate — initial
tail sizing uses the **tail volume coefficient** method (Chapter 6). Other tail geometric parameters
can be set now [Raymer, p. 111]:

### Table 4.3 — Tail Aspect Ratio and Taper Ratio
*[Raymer, Table 4.3, p. 111]*

| Category | Horizontal-tail AR | Horizontal-tail λ | Vertical-tail AR | Vertical-tail λ |
|---|---|---|---|---|
| Fighter | 3–4 | 0.2–0.4 | 0.6–1.4 | 0.2–0.4 |
| Sailplane | 6–10 | 0.3–0.5 | 1.5–2.0 | 0.4–0.6 |
| Others | 3–5 | 0.3–0.6 | 1.3–2.0 | 0.3–0.6 |
| T-tail (vertical only) | — | — | 0.7–1.2 | 0.6–1.0 |

(T-tail aircraft use a lower vertical-tail AR to reduce the weight penalty of carrying the
horizontal tail on top; some GA horizontal tails use `λ=1.0` — untapered — to cut manufacturing
cost.) `[verify p. 111 — column groupings reconstructed from OCR'd table; cross-check row/column
alignment against the printed table before use]`

Horizontal-tail LE sweep is usually set **~5° more than wing sweep** (makes the tail stall after the
wing, and gives it a higher `M_crit` than the wing, avoiding elevator-effectiveness loss from tail
shock formation); low-speed aircraft often instead set horizontal-tail sweep for a straight elevator
hinge line (commonly with left/right elevators interconnected against flutter). Vertical-tail sweep
runs **~35–55°** for high-speed aircraft (again mainly to keep the tail's `M_crit` above the wing's);
for low-speed aircraft there's little functional reason to sweep the vertical tail past ~20°
(aesthetics only). Exact tail planform shape isn't critical this early — conceptual layouts typically
just draw tails that "look right" provided total area is correct; refinement comes later via
analysis/wind-tunnel work. Tail thickness ratio typically follows the same historical-trend guidance
as the wing (§4.6), though a high-speed horizontal tail is often **~10% thinner** than the wing to
keep its `M_crit` higher. A lifting canard or tandem-wing surface should use the *wing*-geometry
guidelines (§§4.8–4.13), not the tail guidelines, since it is functionally a wing
[Raymer, p. 111–112].

## What We've Learned (chapter close, p. 113)

Reasonable initial values for wing and tail geometric parameters — suitable for the first layout but
expected to be revised later — have been established, along with how tail-arrangement choice
(conventional, canard, etc.) shapes the rest of the design.

---

*Chapter 4 extraction complete (§§4.1–4.20, Figs. 4.1–4.37, Tables 4.1–4.3, Eqs. (4.1)–(4.5) plus
the unnumbered wing-geometry/MAC construction equations of Figs. 4.15–4.17, References [6], [7],
[9]–[12] as cited in text — no OCR-garbled numeric coefficients requiring `[verify]` beyond the two
table-layout flags noted inline above, since this chapter is predominantly qualitative/design-
guidance prose with historical-trend charts rather than derived numeric formulas).*
