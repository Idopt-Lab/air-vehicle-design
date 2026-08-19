# Chapter 12 — Aerodynamics

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 12
"Aerodynamics," printed pp. 389-462.

The highest-priority chapter of this extraction batch: lift-curve slope, maximum lift, parasite
(zero-lift) drag, drag-due-to-lift, and supersonic wave-drag methods used directly by the sizing
framework's aerodynamics discipline. All numbered equations and tables preserved; design charts with
usable numeric trends digitized; narrative/CFD-background material condensed.

---

## §12.0 Introduction

This chapter begins the book's analysis phase: given an as-drawn "Dash-One" layout (from initial
statistical sizing), compute its actual aerodynamics, check it against mission/performance
requirements, and iterate toward a "Dash-Two." The methods here are preliminary/statistical —
adequate for trade studies and conceptual design, superseded later by CFD and, ultimately, flight
test.

## §12.1 Aerodynamic Forces

All aerodynamic forces reduce to two physical mechanisms (Fig. 12.1): tangential shear (friction, from
viscosity acting through the boundary layer) and normal pressure (from local velocity changes, via
Bernoulli's relation subsonically, plus shock-wave pressure jumps transonically/supersonically). Every
named "drag" or "lift" term in the literature is just an accounting split of these two effects.

### Fig 12.1 — Origin of aerodynamic forces
*[Raymer, Fig. 12.1, p. 391]* — Cross-section sketch of a body in a freestream: shear arrows tangent
to the "stuck" no-slip boundary-layer molecules, pressure arrows normal to the surface (outward =
below-ambient pressure). No plotted data (conceptual diagram).

Boundary-layer flow is **laminar** (orderly shear) or **turbulent** (disorderly, thicker layer, more
skin friction); transition on a smooth flat plate occurs near local Reynolds number ≈0.5×10^6 (sooner
with roughness; surface curvature can promote or delay it). Viscous (**form/profile**) separation
drag arises because a real (viscous) boundary layer cannot fully recover the front-body suction as
pressure "coasts" over the rear of a body — the classical resolution of **d'Alembert's paradox**
(1752; resolved by Prandtl's boundary-layer concept). Separation moves forward (more drag) on blunt
shapes/at low Reynolds number; turbulent boundary layers, having more energy, delay separation (hence
dimpled golf balls, and why small slow bodies sometimes have lower drag when roughened to force
transition). Long bodies (e.g. an airliner fuselage) can see thick aft boundary layers cause tail
separation ("boattail drag"), countered with vortex generators that re-energize the boundary layer
with outer, higher-energy air.

### Fig 12.2 — Drag terminology matrix
*[Raymer, Fig. 12.2, p. 392]* — Matrix classifying every named drag type by origin (shear vs
pressure) and by lift-dependence (parasite/zero-lift vs drag-due-to-lift), referenced to either
wetted area or max cross-section/volume distribution: parasite drag = skin friction + viscous
separation + wave drag (pressure, not lift-dependent, incl. interference, scrubbing, base/boattail,
trim drag from landing gear etc.); drag-due-to-lift = induced drag (circulation) + supervelocity
effects on skin friction/profile drag + wave drag due to lift. No further plotted data (organizing
diagram).

### Fig 12.3 — Airflow separation
*[Raymer, Fig. 12.3, p. 394]* — Side-view sketches of separation points on an ellipsoid vs an
airfoil. No plotted data (schematic).

Base drag results when geometry (not viscosity) forces separation at a sharp rearward-facing corner
(e.g. a cut-off fuselage or a square landing-gear leg). "Scrubbing drag" is extra skin friction where
prop wash/jet exhaust runs over the skin (avoided with pusher props or non-conformal jet nacelles).
"Wave drag" is the pressure drag from shock formation at transonic/supersonic speed (subsonically,
shocks form first on the wing's upper surface where flow accelerates).

Drag that scales strongly with lift ("drag due to lift") includes **induced drag** (the vortex-energy
cost of generating lift via circulation, ∝ CL²) plus lift-dependent viscous-separation changes and
(supersonically) "wave drag due to lift" (usually small, often ignored in early conceptual design).
2-D airfoil ("profile") drag has no true induced-drag component in inviscid theory, but viscous
profile drag still rises with angle of attack — this effect gets colloquially lumped into "induced
drag" though it isn't the vortex mechanism. **Trim drag** is the tail's induced drag (plus the extra
wing lift needed to counter tail download) required to zero the pitching moment; using the varying
trim deflection at each CL gives the "trimmed" drag polar used for performance work.

## §12.2 Aerodynamic Coefficients

```
L = q·S·CL                                                              (12.1)
D = q·S·CD                                                              (12.2)
q = (1/2)·ρ·V²                                                          (12.3)
```
*[Raymer, Eqs. (12.1)-(12.3), p. 396]* — `S` = wing reference (trapezoidal, to centerline) area, `q`
= freestream dynamic pressure. Lowercase subscripts (`Cl`) denote 2-D airfoil values; uppercase (`CL`)
denote 3-D wing/aircraft values. Drag is often quoted in "counts" (10^-4 of CD, e.g. 38 counts =
0.0038).

### Fig 12.4 — Drag polar
*[Raymer, Fig. 12.4, p. 397]* — CL vs CD parabolic polar with angle-of-attack tick marks; illustrates
the tangent-line construction locating max L/D (not the same point as minimum drag).

```
Uncambered:  CD = CD0 + K·CL²                                           (12.4)
Cambered:    CD = CDmin + K·(CL − CLmindrag)²                           (12.5)
```
*[Raymer, Eqs. (12.4)-(12.5), p. 396]* — for an uncambered wing minimum drag `CD0` occurs at zero
lift; for cambered wings the parabola is shifted to a positive `CL_mindrag`, usually with `CDmin ≈
CD0` for moderate camber so Eq. (12.4) remains a good approximation. `K` (drag-due-to-lift factor) is
developed in §12.6.

## §12.3 Lift

### Fig 12.5 — Wing lift curve
*[Raymer, Fig. 12.5, p. 400]* — CL vs α: cambered vs uncambered curves (cambered has positive CL at
α=0, needs negative α for zero lift — rule of thumb: zero-lift α in degrees ≈ airfoil % camber); a
second panel shows lift-curve slope decreasing with decreasing aspect ratio (and going nonlinear at
very low AR from tip-vortex suction lift), plus the nonlinear stall region where actual CLmax occurs
at an angle greater than the linear extrapolation would predict (by an increment shown in the figure).

For an infinite-AR (2-D) wing, theoretical low-speed lift-curve slope = `2π` per radian; real airfoils
achieve ~90-100% of this ("airfoil efficiency η"). Reducing aspect ratio or increasing sweep (roughly
by `cos(sweep)`) both reduce lift-curve slope, and the two effects are additive — highly swept,
low-AR wings get much less lift than an unswept wing of the same area.

### Fig 12.6 — Lift-curve slope vs Mach number
*[Raymer, Fig. 12.6, p. 399]* — Cl_α (per radian, 0-10) vs Mach (0-3): 2-D theoretical curves rise
subsonically per the Prandtl-Glauert correction (`Cl_α = 2π/√(1−M²)`) and fall supersonically per
`Cl_α = 4/√(M²−1)`; these are upper bounds. Real (3-D, finite-AR, swept) wings fall below: "typical
unswept high aspect ratio wings" (thin/thick airfoil pair) sit close to the 2-D subsonic curve;
"typical swept wings" (high AR / low AR pair) sit substantially lower. Real wings also do not diverge
to infinity at M=1 as the linear theory implies — they instead follow a smooth transonic transition
curve; thick unswept wings lose extra lift transonically from shocks, thin swept wings do not.
*(read from plot, approximate)*:

| Mach | 2-D subsonic theoretical Cl_α | 2-D supersonic theoretical Cl_α | Typical high-AR unswept (thin) | Typical low-AR swept |
|---|---|---|---|---|
| 0.5 | ~7.3 | — | ~6.0 | ~3.0 |
| 0.8 | ~10.5 | — | ~6.8 | ~3.3 |
| 0.95 | ~20 (asymptotic) | — | ~7.0 | ~3.5 |
| 1.2 | — | ~6.0 | ~5.5 | ~3.3 |
| 2.0 | — | ~2.3 | ~3.0 | ~2.5 |
| 3.0 | — | ~1.4 | ~1.8 | ~1.8 |

Lift-curve slope matters for: (1) setting wing incidence (level cruise floor, aft-fuselage upsweep/
gear length via takeoff/landing fuselage attitude); (2) high-performance drag-due-to-lift calculation
(§12.6); (3) longitudinal stability analysis (Chapter 16).

### §12.3.1 Subsonic Lift-Curve Slope

Semi-empirical whole-wing lift-curve slope (per radian), accurate up to drag-divergent Mach and
reasonably good nearly to M=1 for swept wings, from Ref. [68]:

```
CLα = 2πA / ( 2 + sqrt( 4 + (A²β²/η²)·(1 + tan²Λmax_t/β²) ) )           (12.6)
β² = 1 − M²                                                             (12.7)
η = 2π / (Cla/β)                    [airfoil efficiency; ≈0.95 if unknown]   (12.8)
```
*[Raymer, Eqs. (12.6)-(12.8), pp. 399-400]* — `Λmax_t` = sweep at the chord location of maximum
airfoil thickness; `A` = geometric aspect ratio of the full reference planform. Eq. (12.6) is scaled
by `(S_exposed/S_ref)·F` where `S_exposed` = wing area outside the fuselage and `F` is the fuselage
lift factor (spillover lift from the fuselage sitting under the wing):

```
F = 1.07 · (1 + d/b)²                                                   (12.9)
```
*[Raymer, Eq. (12.9), p. 400]* — `d` = fuselage diameter, `b` = wing span. **Confirmed** against a
clean OCR read of the printed page: the exponent is 2, exactly as flagged for verification in the
older `raymer_data.md` extract — no correction needed. If `(S_exposed/S_ref)·F` exceeds 1.0 (implying
the fuselage lifts more than the wing area it covers, unlikely), cap it at ~0.98.

Wing endplates/winglets increase effective aspect ratio (used in the induced-drag calculations of
§12.6, not in Eq. 12.6 itself):

```
Endplate:  A_effective = A · (1 + 1.9·h/b)                              (12.10)
Winglet:   A_effective = A · (1 + h/b)²                                 (12.11)
```
*[Raymer, Eqs. (12.10)-(12.11), p. 400]* — `h` = endplate/winglet height, `b` = wing span. **Resolved
against `raymer_data.md`'s flags**: Eq. (12.10) endplate coefficient **confirmed** as 1.9 (linear
form, no exponent). Eq. (12.11) winglet form is **corrected**: the older extract's tentative form
`A(1 + h/b)·k` is wrong — the actual printed equation has **no separate k-factor**; it is simply
`A·(1 + h/b)²` (squared, matching the endplate equation's structural pattern but without the 1.9
coefficient). A well-designed winglet may realize an effective `h/b` up to 25% higher than actual
geometric `h/b`; a poorly designed one (bare fin stuck on the tip) may realize none of this benefit.
Benefit also depends on velocity, CL, airfoil/twist/relative-geometry choices, and wingtip vortex
strength (weaker for higher-AR or lower span-loading wings, hence less winglet benefit there).

### §12.3.2 Supersonic Lift-Curve Slope

For a wing with a fully supersonic leading edge (Mach cone angle exceeds LE sweep):

```
Clα = 4/β                                                               (12.12)
β = sqrt(M² − 1)                                                        (12.13)
when M > 1/cos(ΛLE)                                                     (12.14)
```
*[Raymer, Eqs. (12.12)-(12.14), p. 401]*. For the general (subsonic-leading-edge) supersonic case,
use the Ref. [69] normal-force-slope charts (Fig. 12.7, six panels by taper ratio λ = 0, 0.25(×2),
1/3, 1/2, 1(?) — approximating `Cn_α` ≈ `Cl_α` at low α): enter with `β/tan(ΛLE)` (inverted, using the
chart's right side, if >1) on the horizontal axis, read off `A·tan(ΛLE)` (or its inverse) on the
vertical axis, then divide by `tan(ΛLE)` (left side) or `β` (right side) to recover the lift-curve
slope; multiply by `(S_exposed/S_ref)·F` as in Eq. (12.6). Valid for trapezoidal planforms without
kinks/strakes; Ref. [69] provides handling for nontrapezoidal shapes but is now rarely used given
modern CFD.

### Fig 12.7 — Wing supersonic normal-force-curve slope
*[Raymer, Fig. 12.7 (a-f), pp. 401-403]* — Six-panel chart family (β/tanΛLE vs A·tanΛLE·(normal-force
-slope parameter)) for taper ratios λ = 0, 0.25, 0.25, 1/3, 1/2, and a sixth (unlabeled in extracted
text, likely λ=1). Reference-only nomographs; not digitized as discrete points (six 2-parameter
charts are impractical to tabulate meaningfully here) — use the source chart directly, or a modern
CFD/panel-code substitute per the chapter's own recommendation.

### §12.3.3 Transonic Lift-Curve Slope

No good quick estimate exists in the transonic range (~M 0.85-1.2 for a swept wing); fair a smooth
curve between the calculated subsonic and supersonic values vs Mach (as sketched in Fig. 12.6). Good
enough for early "Dash-One" work; supplanted by CFD as soon as practical.

### §12.3.4 Nonlinear Lift Effects

Very low-AR (<~2-3) or highly swept wings develop leading-edge/tip vortices giving extra lift roughly
∝ α² — hard to estimate and conservatively ignorable for the lift-curve slope in early design, though
its contribution to CLmax (next section) can matter.

## §12.4 Maximum Lift (Clean)

CLmax strongly drives wing area, hence cruise drag, hence takeoff weight — yet it is among the least
reliable of all conceptual-design calculations (even wind-tunnel data struggles; flight test often
forces late design changes).

### Fig 12.8 — Airfoil leading-edge sharpness parameter
*[Raymer, Fig. 12.8, p. 405]* — Leading-edge cross-section sketch defining `Δy` as the vertical
separation between the upper-surface points at 0.15% and 6% chord aft of the LE.

For high-AR, moderately-swept wings with generous LE radius, clean-wing CLmax ≈ 90% of the airfoil's
2-D max lift at similar Reynolds number, reduced further by quarter-chord sweep:

```
CLmax = 0.9 · Clmax · cos(Λ0.25c)                                       (12.15)
```
*[Raymer, Eq. (12.15), p. 405]* — reasonably valid for subsonic aircraft of moderate sweep.

### Table 12.1 — Δy for Common Airfoils
*[Raymer, Table 12.1, p. 405]*

| Airfoil Type | Δy |
|---|---|
| NACA 4-digit | 26·(t/c) |
| NACA 5-digit | 26·(t/c) |
| NACA 64-series | 21.3·(t/c) |
| NACA 65-series | 19.3·(t/c) |
| Biconvex | 11.8·(t/c) |

For low-AR or highly-swept, sharp-LE wings, leading-edge vortex formation increases CLmax; the
high-AR construction (using `Cl_max` at M=0.2 plus a Mach correction) is:

```
CLmax = Clmax·(CLmax/Clmax)_ratio + ΔCLmax                              (12.16)
```
*[Raymer, Eq. (12.16), p. 405]* — first term = max lift at M=0.2, second term = Mach correction (Figs
12.9-12.10); adjust the resulting trapezoidal-planform value for exposed planform/fuselage lift as in
Eq. (12.6).

### Fig 12.9 — Subsonic maximum lift of high-aspect-ratio wings
*[Raymer, Fig. 12.9, p. 406]* — `(CLmax/Clmax)` at M≈0.2 vs `ΛLE` (0-60 deg), family of curves.
*(read from plot, approximate, mid-family)*: ΛLE=0°→~1.0, 20°→~0.95, 40°→~0.75, 60°→~0.55.

### Fig 12.10 — Mach-number correction for subsonic maximum lift of high-aspect-ratio wings
*[Raymer, Fig. 12.10, p. 407]* — `ΔCLmax` vs Mach (0.2-0.6+) for several `ΛLE` (0/20/40 deg) and `Δy`
families; all curves negative and decreasing (more negative) with Mach. Nomograph family; not
usefully reducible to a short table — consult source chart directly.

```
CLmax = CLmax(M=0.2) + ΔCLmax                                           [restated form of Eq. (12.16)]
αCLmax = αOL + ΔαCL(linear) + ΔαCLmax(nonlinear)                        (12.17)
```
*[Raymer, Eq. (12.17), p. 407]* — first two terms give the angle for max lift assuming a linear lift
curve (second term ≈ airfoil zero-lift angle, negative for cambered airfoils, evaluated at the mean
chord if twisted); third term corrects for nonlinear vortex-flow effects (Fig. 12.11).

### Fig 12.11 — Angle-of-attack increment for subsonic maximum lift of high-aspect-ratio wings
*[Raymer, Fig. 12.11, p. 408]* — `ΔαCLmax` vs `ΛLE` (0-60 deg) for M 0.2-0.6, values ~0-12 deg rising
with sweep. *(read from plot, approximate)*: ΛLE=0°→~1°, 20°→~3°, 40°→~7°, 60°→~11°.

Low-AR wings (vortex-dominated) use a separate chart family. Low-AR criterion:

```
A < 3 / [ (C1 + 1)·cos(ΛLE) ]                                           (12.18)
```
*[Raymer, Eq. (12.18), p. 408]* — `C1` from Fig. 12.12 (taper-ratio correction factor).

### Fig 12.12 — Taper-ratio correction factors for low-aspect-ratio wings
*[Raymer, Fig. 12.12, p. 408]* — `C1`/`C2` vs taper ratio λ (0-1.0). *(read from plot, approximate)*:
λ=0→C1≈1.5, C2≈0.55; λ=0.5→C1≈0.9, C2≈0.75; λ=1.0→C1≈0.55, C2≈0.9.

```
CLmax = (CLmax)base + ΔCLmax                                            (12.19)
αCLmax = (αCLmax)base + ΔαCLmax                                          (12.20)
```
*[Raymer, Eqs. (12.19)-(12.20), p. 409]* — using Figs. 12.13-12.14 (max lift) and 12.15-12.16 (angle
of attack), each parameterized by `A·tan(ΛLE)` or `(C1+1)·β·cos(ΛLE)` combinations.

### Figs 12.13-12.16 — Low-aspect-ratio maximum-lift and angle-of-attack charts
*[Raymer, Figs. 12.13-12.16, pp. 409-410]* — Four related nomographs (max-lift base value and
increment; angle-of-attack base value and increment) vs the combined parameters above, each showing a
"low aspect ratio" / "borderline" / "upper limit of low-AR range" banding. Multi-parameter nomographs
not meaningfully reducible to a short table; use source charts directly for a low-AR design.

### Fig 12.17 — Maximum lift adjustment at higher Mach numbers
*[Raymer, Fig. 12.17, p. 410]* — Ratio (CLmax at Mach) / (CLmax at M=0.5) vs Mach (0.5-3.0), author's
empirical fairing, monotonically decreasing. *(read from plot)*:

| Mach | CLmax ratio to M=0.5 value |
|---|---|
| 0.5 | 1.00 |
| 0.8 | 0.72 |
| 1.0 | 0.55 |
| 1.5 | 0.30 |
| 2.0 | 0.18 |
| 2.5 | 0.10 |
| 3.0 | 0.05 |

At transonic/supersonic speed, achievable max lift is usually structurally, buffet-, controllability-,
or flexibility-limited rather than aerodynamically limited — Fig. 12.17 gives a first-order estimate
of usable lift beyond the applicability of the methods above, applied to the M=0.5 CLmax result.

## §12.5 Maximum Lift with High-Lift Devices

Cruise wants low camber/high wing loading; takeoff/landing wants high camber/low wing loading — hence
flaps and leading-edge devices.

### Fig 12.18 — Flap types
*[Raymer, Fig. 12.18, p. 411]* — Six cross-sections: **plain** (hinged aft portion, cf≈0.3c,
increases camber, ~40-45 deg deflection for max lift; ailerons/control surfaces are plain flaps used
for control); **split** (only lower surface hinges — similar lift to plain, more drag, less pitching
-moment change, common in WWII, rare now); **slotted** (adds a slot letting high-pressure lower-
surface air re-energize the upper surface, delaying separation — more lift, less drag than plain);
**slotted Fowler** (slides aft while deflecting, increasing area+camber, via a simple hinge or
internal track); **double-** and **triple-slotted** (further slotting for more lift at higher cost/
complexity, seen on airliners).

### Fig 12.19 — Leading-edge devices
*[Raymer, Fig. 12.19, p. 412]* — **Leading-edge slot** (fixed hole letting lower-surface air blow
over the upper surface, delays stall, may have closing doors); **leading-edge flap** (hinged, droops
to add camber — key for transonic-maneuvering high-speed fighters with thin wings); **slotted
leading-edge flap ("slat")** (camber + slot + area increase — most widely used LE device, also cuts
transonic buffet; slats raised F-4 usable lift >50% at M=0.9); **Kruger flap** (air-dam type, common
on large airliners, lighter than slats but higher low-α drag, and — lacking a slat's upper-surface
crack — friendlier to laminar flow); **wing strake/leading-edge extension (LEX)** (like a tail dorsal
fin; generates a vortex delaying stall at high α, but can promote pitch-up).

### Fig 12.20 — Effects of high-lift devices
*[Raymer, Fig. 12.20, p. 414]* — CL-vs-α sketches for each device type: non-extending flaps shift
zero-lift angle left and raise CLmax at unchanged lift-curve slope (slightly reduced stall angle);
extending (Fowler-type) flaps do the same but also increase effective lift-curve slope (referenced to
the *original*, un-extended wing area) because planform area grows as the flap deflects; double-/
triple-slotted flaps behave like Fowler flaps with higher CLmax; a leading-edge slot only delays
stall; a LE flap/slat delays stall *and* shifts the curve right (droop reduces effective local α) while
also raising lift-curve slope (slat) via its added area; a wing strake/LEX delays stall at high α
(>20 deg) and raises lift-curve slope via its added area, but does little at typical takeoff/landing α
and does not prevent flap-driven premature stall.

Increment equations for combined-device maximum lift (deployed at the optimum landing angle):

```
ΔCLmax = 0.9·ΔClmax·cos(ΛHL) · (Sflapped/Sref)                          (12.21)
ΔαOL = (ΔαOL)airfoil·cos(ΛHL) · (Sflapped/Sref)                         (12.22)
```
*[Raymer, Eqs. (12.21)-(12.22), p. 415]* — `ΛHL` = hinge-line sweep of the high-lift surface;
`S_flapped` = area of wing carrying the flap, not flap area alone (Fig. 12.21). `ΔClmax` from test
data or Table 12.2; use 60-80% of the landing-setting values for takeoff-flap settings. 2-D zero-lift
-angle change ≈ −15 deg at landing setting, −10 deg at takeoff setting. LEX lift increment ≈0.4 at
high α (crude estimate).

### Table 12.2 — Approximate Lift Contributions of High-Lift Devices
*[Raymer, Table 12.2, p. 415]*

| High-Lift Device | ΔClmax |
|---|---|
| Plain and split flaps | 0.9 |
| Slotted flaps | 1.3 |
| Fowler flaps | 1.3·(c'/c) |
| Double-slotted flaps | 1.6·(c'/c) |
| Triple-slotted flaps | 1.9·(c'/c) |
| Fixed slot (LE) | 0.2 |
| Leading-edge flap | 0.3 |
| Kruger flap | 0.3 |
| Slat | 0.4·(c'/c) |

### Fig 12.21 — "Flapped" wing area
*[Raymer, Fig. 12.21, p. 416]* — Top-view wing sketch shading `S_flapped` = span-wise wing area over
the flap/slat/LE-device span, distinct from the (smaller) flap-surface area itself.

Other high-lift approaches: **active flow control** via suction (mechanically removes the thickening
boundary layer, raising stall α similar to a LE flap) or blowing (compressor-bleed or pumped air
through rearward slots over flaps/LE flaps, preventing separation and increasing turning).

## §12.6 Parasite (Zero-Lift) Drag

### §12.6.1 Equivalent Skin-Friction Method

For a well-designed subsonic-cruise aircraft, parasite drag ≈ skin friction + a roughly consistent
fraction of separation pressure drag, captured in a single "equivalent skin-friction coefficient" Cfe:

```
CD0 = Cfe · (Swet/Sref)                                                 (12.23)
```
*[Raymer, Eq. (12.23), p. 416]* — suitable for an initial subsonic estimate and as a sanity check on
the more detailed component buildup method.

### Table 12.3 — Equivalent Skin-Friction Coefficients
*[Raymer, Table 12.3, p. 417]*

| Aircraft Type | Cfe |
|---|---|
| Bomber | 0.0030 |
| Civil transport | 0.0026 |
| Military cargo (high-upsweep fuselage) | 0.0035 |
| Air Force fighter | 0.0035 |
| Navy fighter | 0.0040 |
| Clean supersonic cruise aircraft | 0.0025 |
| Light aircraft, single engine | 0.0055 |
| Light aircraft, twin engine | 0.0045 |
| Prop seaplane | 0.0065 |
| Jet seaplane | 0.0040 |

### §12.6.2 Component Buildup Method

Per-component subsonic parasite drag = flat-plate skin-friction coefficient `Cf` × form factor `FF`
(viscous-separation pressure drag) × interference factor `Q`, summed over components, plus
miscellaneous items and leakage/protuberance drag:

```
CD0 = [ Σc (Cf,c · FFc · Qc · Swet,c) ] / Sref  +  CDmisc + CDL&P        (12.24)
```
*[Raymer, Eq. (12.24), p. 417]* — supersonically the pressure-drag contributions move into a separate
wave-drag term (skin friction alone uses flat-plate Cf × wetted area); transonically, interpolate
graphically between subsonic and supersonic values.

### §12.6.3 Flat-Plate Skin-Friction Coefficient

Laminar-flow extent is the single largest lever on skin-friction drag (can roughly double it if
turbulent instead of laminar) — but is difficult to predict analytically even with modern CFD, so
conceptual design uses an assumed attainable-percent-laminar (Table 12.4) and a weighted average of
laminar/turbulent Cf.

```
R = ρ·V·ℓ/µ                                                             (12.25)
```
*[Raymer, Eq. (12.25), p. 418]* — Reynolds number; `ℓ` = fuselage length, or wing/tail mean
aerodynamic chord.

### Table 12.4 — Laminar Flow Estimation Guidelines
*[Raymer, Table 12.4, p. 419]* — Attainable laminar flow, % of wetted area:

| Aircraft Type | Fuselage | Wing and Tails |
|---|---|---|
| General aviation, smooth metal (no rivets/cracks) | 10 | 35 |
| General aviation, smooth molded composite | 25 | 50 |
| Sailplane, smooth molded composite | 35 | 70 |
| Helicopter, traditional design | 0 | 0 |
| Helicopter, smooth design | 20 | 20 |
| Civil jet, classic production metal | 5 | 10 |
| Civil jet, research goal (passive) | 25 | 50 |
| Civil jet, research goal (active suction) | 50 | 80 |
| Military aircraft with camouflage | 0 | 0 |
| Supersonic, current | 0 | 0 |
| Supersonic, research goal (active suction) | 20 | 40 |

Notes: laminar flow is unlikely downstream of a spanwise crack (e.g. LE flap/slat hinge — favors
Kruger flaps for laminar wings) or near wing-mounted engines (~1 diameter each side); more difficult
with more sweep; reduced behind a propeller (multiply by 0.8-0.9 for propwash-affected area).

```
Laminar:    Cf = 1.328 / sqrt(R)                                        (12.26)
Turbulent:  Cf = 0.455 / [ (log10 R)^2.58 · (1 + 0.144·M²)^0.65 ]       (12.27)
```
*[Raymer, Eqs. (12.26)-(12.27), pp. 419-420]* — Eq. (12.27)'s Mach term is a compressibility
correction, negligible at low speed.

### Fig 12.22 — Flat-plate skin-friction coefficient vs Reynolds number
*[Raymer, Fig. 12.22, p. 420]* — Cf vs R (0-2×10^6, essentially the laminar-branch region);
Cf falls from ~0.006 near R=1×10^5 to ~0.001 near R=2×10^6 (illustrative of Eq. 12.26's 1/√R form —
plot spans only the low-R/laminar region printed).

Surface roughness raises Cf beyond Eq. (12.27); handled via a fictitious "cutoff Reynolds number"
(using it in place of the true R in Eq. 12.27 whenever it is lower):

```
Subsonic:              R_cutoff = 38.21·(ℓ/k)^1.053                     (12.28)
Transonic/supersonic:  R_cutoff = 44.62·(ℓ/k)^1.053 · M^1.16            (12.29)
```
*[Raymer, Eqs. (12.28)-(12.29), pp. 420-421]* — `k` = skin-roughness value (Table 12.5).

### Table 12.5 — Skin Roughness Value k
*[Raymer, Table 12.5, p. 421]*

| Surface | k (ft) | k (m) |
|---|---|---|
| Camouflage paint on aluminum | 3.33×10⁻⁵ | 1.015×10⁻⁵ |
| Smooth paint | 2.08×10⁻⁵ | 0.634×10⁻⁵ |
| Production sheet metal | 1.33×10⁻⁵ | 0.405×10⁻⁵ |
| Polished sheet metal | 0.50×10⁻⁵ | 0.152×10⁻⁵ |
| Smooth molded composite | **0.17×10⁻⁵** (see note) | 0.052×10⁻⁵ |

> **Note — "Smooth molded composite" `k, ft` is misprinted in the 6th edition.** A 500-dpi render
> of book p. 421 shows the ft column printing **`0.7 × 10⁻⁵`**. That value contradicts its own
> metric column: 0.7×10⁻⁵ ft is 0.213×10⁻⁵ m, not the printed 0.052×10⁻⁵ m. Every other row in
> the table converts correctly at 1 ft = 0.3048 m, and inverting the metric value gives
> 0.052×10⁻⁵ / 0.3048 = **0.171×10⁻⁵ ft**. The printed `0.7` is a dropped-digit misprint of
> `0.17`. This table records **0.17×10⁻⁵**, which is also the value consistent with composite
> being the smoothest surface listed. (Earlier flagged `[verify p. 420]`; resolved, and the page
> citation corrected from 420 to 421.)

### §12.6.4 Component Form Factors and Adjustments

Form factors correct Cf upward for separation-driven pressure drag (subsonic only; supersonic
pressure drag is folded into wave drag instead):

```
Wing, tail, strut, pylon:
FF = [ 1 + 0.6/(x/c)m · (t/c) + 100·(t/c)^4 ] · [ 1.34·M^0.18 · (cos Λm)^0.28 ]     (12.30)

Fuselage and smooth canopy:
FF = 1 + 60/f³ + f/400                                                  (12.31)

Nacelle and smooth external store:
FF = 1 + 0.35/f                                                         (12.32)
f = ℓ / d = ℓ / sqrt( (4/π)·Amax )                                      (12.33)
```
*[Raymer, Eqs. (12.30)-(12.33), pp. 421-422]* — `(x/c)m` = chordwise location of max airfoil
thickness (≈0.3 low-speed airfoils, ≈0.5 high-speed); `Λm` = sweep of the max-thickness line; `f` =
fineness ratio. Eq. (12.31) is the author's *revised* fuselage form factor (this 6th-edition text
explicitly departs from the classic RAND/DATCOM form `FF = 1 + 60/f + f/400` used in earlier editions
and in [69] — that classic form correlates well for `f` > 6 but overestimates drag for `f` < 5; the
revised Eq. (12.31) above is a compromise giving conservative, i.e. larger, values for short/fat
fuselages while asymptoting to 1.0 at high fineness ratio like all these forms).

Adjustments (applied only to the form factor's increment above 1.0, e.g. a 30% bump on FF=1.2 gives
1.26, not 1.56): tail surface with hinged rudder/elevator, +~10% (gap drag); fuselage ahead of a
spinning pusher propeller, separation drag reduced (author's estimate: halve the increment while
spinning, double it if stopped); square-sided fuselage, +30-40% (reducible by rounding corners);
flying-boat hull, +~50%; float, +~200% (three times the smooth estimate). Eq. (12.31) also applies to
smoothly lofted blisters/fairings (e.g. gear-stowage pods) and one-piece fighter canopies (F-16
style); a two-piece canopy with fixed streamlined windscreen (F-15) adds ~40%; a flat-sided
windscreen (A-10, Me-109) adds ~300% (better: scale actual similar-canopy test data by frontal area).

### Fig 12.23 — Inlet boundary-layer diverter
*[Raymer, Fig. 12.23, p. 424]* — Side-view sketches of double-wedge and single-wedge diverter ramps
ahead of a fuselage-mounted inlet, dimension `d` (ramp height) and `ℓ` (ramp length) labeled.

```
Double wedge:  FF = 1 + (d/ℓ)                                           (12.34)
Single wedge:  FF = 1 + (2d/ℓ)                                          (12.35)
```
*[Raymer, Eqs. (12.34)-(12.35), pp. 423-424]* — local R uses `ℓ`; double the drag for two inlets.
These form factors assume reasonable streamlining (don't apply to bluff, non-airplane shapes); a
CFD-optimized "tadpole" aft-body shape (Stratford-criterion-informed, e.g. MD-80) can justify a
10-20%+ reduction in the form-factor increment (author's estimate) — verify against CFD/test data.

### §12.6.5 Component Interference Drag

Interference factor `Q` in Eq. (12.24) captures boundary-layer "filling in" at component junctions
(thicker BL → more separation risk, mitigated with fillets) and "supervelocity" (locally accelerated
flow around a body raising dynamic pressure, hence drag, for anything immersed in it).

Typical `Q` values: nacelle/external store on fuselage or wing, ~1.5 (mounted <~1 diameter away,
~1.3; beyond ~1 diameter, →1.0); wingtip-mounted missile, ~1.25; high-wing/midwing/well-filleted low
wing, ~1.0; un-filleted low wing, 1.1-1.4; fuselage itself and boundary-layer diverter, ~1.0; tail
surfaces, ~1.03 (clean V-tail) to ~1.08 (H-tail), ~1.04-1.05 typical conventional tail. Favorable
(drag-reducing) interference is possible for components tucked behind another (reduced local dynamic
pressure — "drafting") or under the wing (locally reduced velocity at higher CL) — usually ignored in
preliminary analysis except for detailed landing-gear drag work.

### §12.6.6 Miscellaneous Drags

For non-streamlined protruding items, rely on test data (Figs. 12.24-12.26) presented as `D/q` ("drag
area," ft²/m²; ×q = drag force, or ÷Sref = a parasite CD contribution).

### Fig 12.24 — External stores (fuel tanks) drag
*[Raymer, Fig. 12.24, p. 426]* — D/q vs Mach (0.4-1.0) for 300-gal and 150-gal tanks, wing- or
fuselage-mounted. *(read from plot, approximate, subsonic plateau values)*: 300-gal wing tank D/q ≈
2.3 ft²; 300-gal fuselage tank ≈1.7 ft²; 150-gal wing tank ≈1.1 ft²; 150-gal fuselage tank ≈0.8 ft²;
all rise moderately above M≈0.85 toward M=1.0.

### Fig 12.25 — Bomb and missile drag
*[Raymer, Fig. 12.25, p. 427]* — D/q vs Mach (0.4-1.2) for 6×500-lb and 6×250-lb bomb clusters (rack
drag excluded), 2000-lb bomb (fuselage or wing mount), and AIM-9 missile+pylon. *(read from plot,
approximate, subsonic plateau)*: 6×500-lb cluster ≈2.2 ft²; 6×250-lb cluster ≈1.6 ft²; 2000-lb bomb
(fuselage) ≈1.1 ft²; 2000-lb bomb (wing) ≈0.9 ft²; AIM-9+pylon ≈0.15 ft²; all rise through the
transonic range.

### Fig 12.26 — Pylon and bomb rack drag
*[Raymer, Fig. 12.26, p. 427]* — D/q vs Mach (0.5-1.1) for multiple-bomb-cluster rack, fuselage stores
pylon, wing stores pylon. *(read from plot, approximate subsonic plateau)*: multiple-bomb-cluster
rack ≈0.9 ft²; fuselage stores pylon ≈0.35 ft²; wing stores pylon ≈0.2 ft².

### Fig 12.27 — Fuselage upsweep
*[Raymer, Fig. 12.27, p. 428]* — Side-view sketch defining upsweep angle `u` (radians) of the
fuselage centerline (not belly angle) for a typical cargo-aircraft aft fuselage.

```
D/q_upsweep = 3.83 · u^2.5 · Amax                                       (12.36)
```
*[Raymer, Eq. (12.36), p. 428]* — `u` in radians, `Amax` = max fuselage cross-sectional area.

```
Subsonic:    D/q_base = [ 0.139 + 0.419·(M − 0.161)² ] · Abase          (12.37)
Supersonic:  D/q_base = [ 0.064 + 0.042·(M − 3.84)² ] · Abase           (12.38)
```
*[Raymer, Eqs. (12.37)-(12.38), p. 428]* — cited to Ref. [73]; `Abase` = actual aft-facing flat area
plus aft-projected area of steeply angled regions (aft angle to freestream > ~20 deg is a rough
separation trigger, though a spinning pusher prop can suppress separation up to ~30 deg+).

### Table 12.6 — Miscellaneous and Landing-Gear Component Drags
*[Raymer, Table 12.6, pp. 428-429]* — `CDπ` = D/q ÷ frontal area (i.e. drag coefficient referenced to
the component's own frontal area):

| Component | CDπ |
|---|---|
| Flat plate perpendicular to flow | 1.28 |
| Sphere alone, high Re | 0.10 |
| Sphere alone, low Re | 0.3-0.5 |
| Hollow sphere, open end forward | 1.40 |
| Hollow sphere, open end to rear | 0.40 |
| Bullet shape, blunt back | 0.30 |
| Exposed water-cooled radiator | 1.00 |
| Cowled water-cooled radiator | 0.3-0.5 |
| Air scoops | 1.2-2.0 |
| Control horn | 0.3-0.8 |
| Speed brake, fuselage mounted | 1.00 |
| Speed brake, wing mounted | 1.60 |
| Windshield smoothly faired into fuselage | 0.07 |
| Windshield, sharp-edged, poorly faired | 0.15 |
| Open cockpit (ref. windscreen frontal area) | 0.50 |
| Parachute or drogue chute | 1.40 |
| Regular wheel and tire | 0.25 |
| Second wheel and tire in tandem | 0.15 |
| Streamlined wheel and tire | 0.18 |
| Wheel and tire with fairing | 0.13 |
| Streamlined strut (1/6 < t/c < 1/3) | 0.05 |
| Round strut or wire (Re > 3×10⁵) | 0.30 |
| Round strut or wire (Re < 3×10⁵) | 1.17 |
| Flat spring gear leg | 1.40 |
| Fork, bogey, irregular fitting | 1.0-1.4 |

Speed brakes/spoilers (fuselage or wing) slow the aircraft, aid descent, and (wing-mounted, dumping
lift onto the gear) shorten landing roll. Strut optimum t/c ≈0.19 (tension) or ≈0.23 (compression).
Landing-gear drag: best from test data on a similar recent design (Refs. [9,15,47]); alternatively sum
individual component `D/q` (Table 12.6) × 1.2 (mutual interference), +~7% if retracted-gear doors are
left open with gear down. Gear drag also falls somewhat at higher CL (reduced local velocity under
the wing) — usually ignored in preliminary analysis.

### Table 12.7 — Component Miscellaneous Drags
*[Raymer, Table 12.7, p. 430]* — actual `D/q` and `CD` values (not ratioed to frontal area):

| Component | D/q (ft²) | CD |
|---|---|---|
| Arresting hook, USN | 0.15 | 0.014 |
| Arresting hook, USAF | 0.10 | 0.009 |
| Machine gun ports | 0.02 | 0.002 |
| Cannon port | 0.20 | 0.019 |
| Exposed pilot, prone | 1.20 | 0.111 |
| Exposed pilot, seated | 6.00 | 0.557 |
| Exposed pilot, spread eagle | 9.00 | 0.836 |

Flap drag is covered in §12.6.10; helicopter component drag data is in Chapter 20.

### §12.6.7 Leakage and Protuberance Drag

Leakage drag comes from air "inhaled" through gaps into high-pressure zones and "exhaled" into
low-pressure zones (both drag-producing); protuberances (antennas, lights, door edges, vents, hinges,
rivets, panel misalignment) aren't defined until detail design, so both are estimated as a percentage
add-on to total parasite drag (Table 12.8). Variable-sweep wings add ~3% more (pivot-area gaps/steps).

### Table 12.8 — Leakage and Protuberance Drag
*[Raymer, Table 12.8, p. 431]*

| Aircraft Type | % of CD0 |
|---|---|
| Propeller aircraft | 5-10 |
| Jet transports or bombers | 2-5 |
| Non-stealth fighters | 10-15 |
| Stealth fighters | 3-5 |

Careful design/manufacturing can push these toward zero at significant cost (race planes; stealth
designs get an aerodynamic side-benefit from the same protuberance cleanup needed for RCS).

### §12.6.8 Stopped-Propeller and Windmilling Engine Drags

Engine-out takeoff/climb requirements must include stopped-prop or windmilling-engine drag.
Feathered-propeller subsonic CD ≈0.1 (based on total blade area); fixed-pitch (unfeatherable) stopped
prop ≈0.8 [Ref. 9]. Blade solidity σ = total blade area / disk area = (blade count)/(blade AR·π); for
a typical blade AR of 8, σ ≈ 0.04 × blade count (2-blade small piston, 3-blade fast piston/small
turboprop, 4-blade large turboprop).

```
(D/q)_feathered_prop = 0.1·σ·A_propeller_disk           [0.8 in place of 0.1 if unfeathered]  (12.39)
(D/q)_windmilling_jet = 0.3·A_engine_front_face                          (12.40)
```
*[Raymer, Eqs. (12.39)-(12.40), pp. 431-432]* — Eq. (12.40) cited to Ref. [74], subsonic windmilling
turbojet, referenced to engine inlet-face flow area.

### §12.6.9 Supersonic Parasite Drag

Supersonic skin friction gets no form-factor or interference adjustment (both fold into wave drag):

```
CD0,supersonic = Σc(Cf,c·Swet,c)/Sref + CDmisc + CDL&P + CDwave          (12.41)
```
*[Raymer, Eq. (12.41), p. 432]* — turbulent Cf from Eq. (12.27) using the cutoff-R form Eq. (12.29).
Miscellaneous/leak-protuberance percentages carry over roughly unchanged from subsonic; items like
floats, open cockpits, and wing struts typically don't exist on supersonic designs.

Supersonic **wave drag** often dominates total drag; it depends on the aircraft's longitudinal volume
distribution. The **Sears-Haack body** gives the theoretical minimum wave drag for a given
length/volume/closed-end circular-cross-section body:

```
r(x) = (something) for -ℓ/2 ≤ x ≤ ℓ/2                                    (12.42, symbolic — see Ch.8 Eq. 8.2 form)
(D/q)wave = (9π/2)·(Amax/ℓ)²                                             (12.44)
```
*[Raymer, Eqs. (12.42), (12.44), pp. 432-433]* — `Amax` = max cross-sectional area (Eq. 12.43 restates
the `-ℓ/2 ≤ x ≤ ℓ/2` domain and is not itself a separate formula). Linear area-rule theory: at Mach
1.0, wave drag depends only on the cross-sectional-area distribution vs longitudinal station — not
component shape at that station — so a wing-body's Mach-1 wave drag equals an equivalent body of
revolution with the same area distribution (Fig. 8.13/8.28 concept, Chapter 8). Minimizing wave drag
means shaping the volume distribution to resemble a Sears-Haack body (smooth, bell-shaped, minimal
second-derivative curvature) — the "coke-bottle" pinched fuselage is this applied around the wing's
volume "bump." Real aircraft achieve roughly 2× the Sears-Haack ideal wave drag typically.

### Fig 12.28 — Mach-plane cut volume distribution (two roll angles)
*[Raymer, Fig. 12.28, p. 434]* — Cross-sectional-area-vs-fuselage-station plots for two different
Mach-plane roll angles (φ), illustrating that above M=1 the area-ruling cut plane is inclined at the
Mach angle and can be rolled to any φ, each giving a different area distribution; true supersonic wave
drag averages over all φ (basis of the classic Harris wave-drag code, Ref. [76]). No further plotted
numeric data (conceptual schematic).

For hand/no-computer preliminary wave-drag estimation, correlate to the Sears-Haack value via an
empirical wave-drag efficiency factor `EwD` (ratio of actual to Sears-Haack wave drag; EwD=1.0 for a
perfect Sears-Haack body):

```
(D/q)wave = EwD · [1 − 0.386·(M−1.2)] · [1 − (A_LEsweep,deg/100)^0.77] · (D/q)_Sears-Haack   (12.45)
```
*[Raymer, Eq. (12.45), pp. 434-435]* — `Amax` should have inlet capture area subtracted; `ℓ` excludes
constant-cross-section portions of the fuselage (or, if Amax sits well aft of the fuselage midpoint,
assume `ℓ` = 2× the nose-to-Amax distance, at the cost of extra base drag from the resulting wedge
shape). Typical `EwD`: very clean blended designs ~1.2; typical supersonic fighter/bomber/SST ~1.8-2.2;
poor bumpy designs 2.5-3.0; the F-15 (optimized for dogfighting, not supersonic cruise) ~2.9. The
`(Amax/ℓ)²` fineness-ratio term matters more than `EwD` — area-ruling that actually reduces `Amax` beats
merely smoothing the distribution without lowering it. The author notes Eq. (12.45)'s `0.386` Mach
-dropoff coefficient seems overly optimistic in practice and recommends `0.2` instead for better
results.

### §12.6.10 Transonic Parasite Drag

Transonic regime ≈ M 0.8-1.2 (mixed sub/supersonic local flow). "Drag rise" begins at the **critical
Mach number** `Mcr` (first shock formation) and becomes significant at the **drag-divergent Mach
number** `MDD` (definition varies: Boeing = 20-count drag rise, ≈0.08 above `Mcr`; Douglas/USAF [69] =
`dCD0/dM` first reaches 0.10, ≈0.06 above Boeing's `MDD`, ≈80-100 counts of rise — jets typically cruise
near Boeing `MDD` and max out near Douglas `MDD`). `MDD` falls with increasing CL (e.g. 727: M0.86 at
CL=0.1, M0.82 at CL=0.3).

```
MDD(wing, CL=CLdesign=0, uncambered) ≈ f(t/c, ΛLE)   [Eq. (12.46), via Figs 12.29-12.30]
```
*[Raymer, Eq. (12.46), p. 436]* — Fig. 12.29 gives zero-lift `MDD` vs sweep for a family of t/c
values; Fig. 12.30 adjusts for actual CL; the final Eq. (12.46) term corrects for wing design CL
(camber/twist), initially assumable = cruise CL. For supercritical airfoils, multiply actual t/c by
0.6 before entering the charts (approximates the shock-delaying benefit).

### Fig 12.29 — Wing drag-divergence Mach number
*[Raymer, Fig. 12.29, p. 437]* — `MDD` (0.75-1.0) vs sweep (10-70 deg) for t/c = 0.04, 0.06, 0.08,
0.10, 0.12 (conventional airfoil, CL=CLdesign=0). *(read from plot, approximate, t/c=0.06 curve)*:
sweep 0°→MDD≈0.79; 20°→~0.83; 40°→~0.90; 60°→~0.97.

### Fig 12.30 — Lift adjustment for MDD
*[Raymer, Fig. 12.30, p. 437]* — `ΔMDD` (negative) vs CL (0-0.3+) for t/c families 0.04-0.14; MDD
drops as CL rises. Nomograph; consult source chart for a specific t/c/CL combination.

### Fig 12.31 — Body drag-divergent Mach number
*[Raymer, Fig. 12.31, p. 438]* — Body `MDD` (0.6-1.0, two families: subsonic-design and
"supersonic-design" nose) vs a fineness-type parameter `(2·Ln/d)` (0-20). If the fuselage forebody is
blunt, its `MDD` (this chart) can govern instead of the wing's; take the lower of the two. `Ln` = nose
-to-constant-cross-section length; `d` = equivalent diameter there.

Linear wave-drag theory is invalid in the transonic regime (it drops the very velocity-variation
terms responsible for transonic drag rise); nonlinear CFD or Euler/NS codes are needed for rigor.
Absent that, use the graphical rule-of-thumb construction:

### Fig 12.32 — Transonic drag rise estimation
*[Raymer, Fig. 12.32, p. 439]* — Construction diagram (not a numeric data plot): CD0 vs Mach with
five labeled construction points — **A** (M≈1.2+, from Eq. 12.45 ÷ Sref), **B** (M=1.05, ≈ same value
as A), **C** (M=1.0, ≈ half of B), **D** (drag rise at MDD = 0.002 by definition), **E** (Mcr, ≈0.08
Mach below MDD). Build the curve by: straight line through B-C extended toward the axis; a smooth arc
from `Mcr` (E) through `MDD` (D) fairing into that line; a smooth curve from B to A. Usable even for
subsonic transports (compute the notional supersonic wave drag at B via Eq. 12.45 even though the
type never flies there; use `EwD ≈ 4.0` for transport-type drag rise). This is a *construction
method*, not itself a numeric chart to digitize — the "F-16-style transonic CD0 vs Mach" numeric data
some earlier project notes associated with "Fig 12.32" actually corresponds to the **multi-aircraft
comparison in Fig. 12.34** (digitized below), not this construction figure.

### Fig 12.33 — Complete parasite drag vs Mach number
*[Raymer, Fig. 12.33, p. 440]* — Stacked-buildup schematic (skin friction; + form/interference; +
miscellaneous; + leaks/protuberances) vs Mach through `MDD`, 1.0, 1.2 — illustrating that in the
transonic region the "form + interference" bookkeeping term is simply interpolated linearly between
its subsonic value at `MDD` and zero at M1.2 (where those pressure effects instead appear inside the
wave-drag term). No further numeric data (conceptual buildup diagram).

### Fig 12.34 — Parasite drag and drag rise
*[Raymer, Fig. 12.34, p. 441]* — CD0 (or CDmin) vs Mach (0.5-2.5) for eleven real aircraft: S-3, B-727,
F-86, F/A-18, F-15, F-16, F-104, F-14, F-4, F-105, RA-5C, F-106, Rockwell ATF (author's unbuilt
supercruise ATF proposal), B-70. **Digitized F-16 curve** *(read from plot)* — this is the numeric
data an earlier project note mislabeled as "Fig 12.32":

| Mach | F-16 CD0 |
|---|---|
| 0.5 | ~0.020 |
| 0.8 | ~0.021 |
| 0.9 | ~0.022 |
| 0.95 | ~0.026 |
| 1.0 | ~0.035 |
| 1.05 | ~0.044 |
| 1.1 | ~0.048 |
| 1.2 | ~0.049 |
| 1.5 | ~0.049 |
| 2.0 | ~0.048 |
| 2.2 | ~0.048 |

For comparison, approximate plateau (M≈1.5-2.0+) CD0 for other types read off the same figure: F/A-18
≈0.058; F-15 ≈0.055; F-104 ≈0.043; F-14 ≈0.040 (peaks near M1.05 then eases); F-4 ≈0.040; F-105
≈0.033; RA-5C ≈0.027; F-106 ≈0.023; Rockwell ATF ≈0.018; B-70 ≈0.007 (referenced to its very large wing
area — Raymer's own caution: cross-aircraft CD0 comparison is distorted by differing Sref; comparing
via `Amax`-normalized drag or `EwD` is fairer). All curves show the same qualitative shape: a flat
subsonic plateau, a steep rise through M≈0.95-1.1, then either a plateau or a mild supersonic decline.

### §12.6.11 Drag Map

A "Drag Map" (Fig. 12.35) extends Fig. 12.33 by plotting several CL-specific drag-vs-Mach curves
(rather than one CD0-only curve), also capturing CL's effect on `MDD` — useful for cruise-Mach/altitude
trade studies (higher altitude → higher required CL → possible earlier drag rise) and for computing
L/D or M·L/D at various Mach. See Ref. [175] for a detailed treatment.

### Fig 12.35 — Drag Map for Typical Commercial Airliner (after Hays)
*[Raymer, Fig. 12.35, p. 442]* — CD (0.010-0.050) vs Mach (0.5-0.9) for CL = 0.0, 0.1, 0.2, 0.3, 0.4,
0.5, each curve flat subsonically then rising into drag divergence at successively lower Mach for
higher CL. *(read from plot, approximate, onset-of-rise Mach by CL)*: CL=0.1→rise begins ~M0.83;
CL=0.3→~M0.79; CL=0.5→~M0.72; baseline (low-CL) CD plateau ≈0.014-0.016.

## §12.7 Drag Due to Lift (Including Induced Drag)

Induced drag ∝ CL² is the vortex-energy cost of lift (tip-vortex circulation); "drag due to lift" is
the broader bucket also including viscous-separation changes with α and (small) parasite-drag shifts
from velocity redistribution over the wing as α varies — these track CL² closely enough to be lumped
with the induced-drag calculation. A laminar-flow-wing-specific effect: the laminar-turbulent
transition point moves sharply forward with even small CL increases (NASA Cessna P-210 data: 44%-chord
laminar run at CL=0.26 fell to 29% at CL=0.28 and 5% at CL=0.35), producing the "laminar bucket" seen
in laminar-airfoil drag polars.

### §12.7.1 Oswald Span Efficiency Method

```
K = 1/(π·A·e)                                                           (12.47)
```
*[Raymer, Eq. (12.47), p. 443]* — classical elliptical-lift-distribution induced drag has `e=1`
(`K=1/(πA)`); real wings' non-elliptical distribution + separation drag are folded into Oswald
efficiency `e` (typically 0.7-0.85). More realistic (than Glauert/Weissinger) empirical fits from
actual aircraft data [Ref. 80]:

```
Straight-wing:  e = 1.78·(1 − 0.045·A^0.68) − 0.64                      (12.48)
Swept-wing (ΛLE > 30°):  e = 4.61·(1 − 0.045·A^0.68)·(cos ΛLE)^0.15 − 3.1   (12.49)
```
*[Raymer, Eqs. (12.48)-(12.49), p. 444]* — linearly interpolate between the two for sweep 0-30 deg;
not valid for very-high-AR (sailplane) designs; use the effective AR (Eqs. 12.10/12.11) in Eq. (12.47)
if endplates/winglets are fitted. The chapter recommends the superior leading-edge-suction method
(§12.7.2) over this simpler e-method where feasible.

### Fig 12.36 — Prandtl's biplane interference factor
*[Raymer, Fig. 12.36, p. 445]* — Interference factor `σ` vs (gap/average span) (0-0.4) for span ratio
`µ` = b_shorter/b_longer = 0.4-1.0 family. *(read from plot, µ=1.0 curve)*: gap/span=0.10→σ≈0.62;
0.15→σ≈0.69; 0.20→σ≈0.74; 0.30→σ≈0.80.

```
Biplane:  e = µ²·(1+r)² / (µ² + 2·σ·µ·r + r²)                            (12.50)
```
*[Raymer, Eq. (12.50), p. 444]* — `µ` = shorter/longer span; `r` ≈ lift ratio ≈ area ratio between
the two wings; `σ` from Fig. 12.36. For equal wings, simplifies to `2/(1+σ)`; typical gap/avg-span
≈0.15 (span ≈7× gap) gives `e ≈1.3` (>1, but note biplane AR uses *total* area of both wings, so
individual-panel AR is about double the biplane AR used here). Real-aircraft correlation runs a bit
lower than this classical Prandtl estimate — multiply the resulting `e` by 0.8 before use in Eq.
(12.47).

```
Supersonic:  K = A·(M²−1)·cos(ΛLE) / [ (4·A·sqrt(M²−1)) − 2 ]            (12.51)
```
*[Raymer, Eq. (12.51), p. 445]* — cited to Ref. [81]; quick supersonic K estimate (Oswald `e` falls to
~0.3-0.5 near M=1.2), though the leading-edge-suction method (next) is preferred.

### §12.7.2 Leading-Edge-Suction Method

### Fig 12.37 — Leading-edge suction definition
*[Raymer, Fig. 12.37, p. 446]* — Two airfoil cross-sections: thick airfoil (leading-edge suction
force `S` balances the rearward component of normal force `N` for zero net drag at zero separation/
downwash — "100% leading-edge suction," d'Alembert's-paradox-ideal, equivalent to Oswald `e=1.0`) vs a
zero-thickness flat plate (`S=0`, all pressure acts normal to the plate as `N`).

```
L = N·cos(α)                                                            (12.52)
Di = N·sin(α) = L·tan(α)                                                (12.53)
K = Di/CL² [as α/CL, small-angle] = α/CL                                (12.54-12.55, combined)
K0 = 1/CLα                                                              (12.56)
```
*[Raymer, Eqs. (12.52)-(12.56), p. 447]* — worst case (0% leading-edge suction), K is simply the
inverse lift-curve slope (per radian). Real wings sit between 0% and 100% suction, parameterized by
suction fraction `S` (not the force `S` above):

```
K = S·K100 + (1 − S)·K0                                                 (12.57)
```
*[Raymer, Eq. (12.57), p. 447]* — `K0` = Eq. (12.56); `K100` (subsonic) = `1/(π·A)` (using effective AR
if winglets/endplates fitted). Typical subsonic-cruise `S` ≈0.85-0.95 for moderate sweep/large LE
radius; a supersonic fighter in a hard turn may approach `S≈0`.

Transonically, shock formation degrades leading-edge suction starting at `MDD`; above the Mach where
the Mach angle (`arcsin(1/M)`) equals the LE sweep, the LE is fully supersonic and `S→0` (K=K0 always).

### Fig 12.38 — Zero and 100% K vs Mach number
*[Raymer, Fig. 12.38, p. 448]* — `K0` (rising) and `K100 = 1/(πA)` (roughly flat then rising past the
LE-sweep-matches-Mach-angle point) vs Mach (0.2-1.6), bounding the region containing all actual K
values. Reference envelope; specific numeric values depend on the wing's `A`/sweep/CLα and are not
usefully tabulated generically.

The remaining unknown, `S` at the flight condition of interest, depends on LE radius, sweep, and
(strongly) on CL relative to the wing's own **design CL** — the CL at which the wing/airfoil/twist
were optimized (chosen from cruise/loiter conditions or via multidisciplinary optimization). At its
own design CL, a well-designed wing achieves `S ≈ 0.9`.

### Fig 12.39 — Typical design goal values for supersonic aircraft — leading-edge suction vs CL
*[Raymer, Fig. 12.39, p. 449]* — `S` vs CL (0-1.0) for design-CL families 0.1-0.8 (each curve peaking
≈0.8-0.9 at its own design CL and falling off both above and below, more steeply for thin swept
supersonic-type wings than for large-LE-radius subsonic wings). Nomograph family; for a large-
LE-radius subsonic wing, the chapter recommends replacing the "below design CL" branch with a flat
line at `S≈0.93` (typical airliner practice) rather than reading the supersonic-wing-shaped curve.

### Fig 12.40 — Sample results, K vs Mach and CL
*[Raymer, Fig. 12.40, p. 450]* — Example K-vs-Mach curve family (CL = 0.35-0.45, 0.5, 1.4) built by
combining Figs. 12.38-12.39; illustrates the method's output shape, not generic numeric data.

For high-AR wings lacking direct suction test data, construct an equivalent `S` schedule by assuming
`e=0.8` at the design CL and solving Eq. (12.58) for the equivalent `S` (apply flat from CL=0 up to
~0.1 above design CL, then drop to ~80% of that value at stall CL):

```
e = 1 / [ (πA/CLα)·(1 − S) + S ]                                        (12.58)
ΔN = S · (1/CLα − 1/(πA))                                                (12.59)
```
*[Raymer, Eqs. (12.58)-(12.59), p. 451]* — Eq. (12.59)'s `ΔN` parameter is used in some other
textbooks' equivalent notation; provided here for cross-reference.

### §12.7.3 Trim Drag

Performance drag polars should include trim drag — the tail download (usually) needed to zero
pitching moment produces extra wing induced drag (more lift needed to counter the download) plus the
tail's own induced and deflected-surface parasite drag; the tail's operation in the wing's downwash
tilts its download slightly forward, somewhat reducing trim drag. Trim calculation itself is Chapter
16's subject; trim drag uses the induced-drag methods above once the required tail lift is known.

### §12.7.4 Ground Effect

```
K_effective/K = 33·(h/b)^1.5 / [1 + 33·(h/b)^1.5]                       (12.60)
```
*[Raymer, Eq. (12.60), p. 451]* — cited to Ref. [82]; `h` = wing height above ground; K reduces
substantially within about half a span of the ground (reduced induced downwash / "air cushion").

### §12.7.5 Flap Drag

Flap parasitic-drag increment (referenced to wing area, not flap area):

```
ΔCDflap = Fflap · (cf/c)^1.38 · (Sflapped/Sref) · δflap                  (12.61)
```
*[Raymer, Eq. (12.61), p. 452]* — `Fflap` = 0.0144 (plain flaps) or 0.0074 (slotted flaps); `δflap` in
degrees; typical deflections ≈60-70 deg landing, ≈20-40 deg takeoff (light aircraft often use no
flaps for takeoff). Flap deflection also increases induced drag (non-elliptical lift distribution
from the flapped span, potentially doubling drag due to lift); a first-approximation increment based
on the flap lift increase:

```
ΔK_flap-induced ≈ kf · (ΔCLflap)²  [added to the clean-wing K·CL² term]  (12.62)
```
*[Raymer, Eq. (12.62), p. 452]* — `kf` = 0.14 (full-span flaps) or 0.28 (half-span flaps); best done
with CFD-predicted lift-distribution changes in practice; Refs. [9,18,69] provide alternative methods.

## §12.8 Computational Fluid Dynamics

Condensed (background/context, not equation-bearing): classic pre-CFD industry practice combined
linearized codes (Harris wave-drag code, Sommer-and-Short skin-friction code, panel codes like
USSAERO/PANAIR/QUADPAN for induced effects) with empirical corrections, giving lift/drag typically
within 2-10% of flight-measured values for cruise conditions, but offering no insight into *why* a
design underperformed or how to fix it — high-α, transonic, and separated-flow behavior needed
empirical correlation to similar existing designs instead.

CFD solves for the whole flowfield (not just surface values), based on the 1822 Navier-Stokes (NS)
equations (continuity, momentum, energy conservation) — analytically unsolvable for useful cases, so
practical codes form a hierarchy of simplifications: **Large Eddy Simulation (LES)** (small-scale
turbulence modeled statistically, large eddies resolved directly — current high end for complex
configurations); **Reynolds-Averaged Navier-Stokes (RANS)** (turbulence fully modeled statistically,
~60 PDEs — the more affordable complex-configuration workhorse, handles vortex formation, separation,
transonic and unsteady effects); **Parabolized Navier-Stokes (PNS)** (drops streamwise viscous terms,
hence streamwise separation — supersonic-design workhorse); **Euler** (drops all viscosity, assumes
steady flow — cheap, handles vortex formation, pairs with a boundary-layer code for viscous/separation
estimates); **potential flow** (further drops rotational terms, so no vortex-flow capability, but
handles transonic shocks — useful, widely used, not usually called "true CFD"); **linearized**
(drops higher-order terms entirely — the basis of Harris/USSAERO-era codes and lifting-line theory;
invalid transonically because the dropped terms are exactly what drives transonic drag rise). Only
LES/RANS/PNS are "true" Navier-Stokes codes; Euler/potential-flow/linearized are successive further
simplifications.

### Fig 12.41 — CFD example, Boeing 737 nacelle
*[Raymer, Fig. 12.41 (a,b), p. 456]* — Two schematics: (a) "rule-of-thumb" CFM-56 nacelle placement
(2 diameters forward, 1 diameter below the wing) shown to be a ground-clearance problem on the 737;
(b) the CFD-redesigned, much more closely-spaced nacelle Boeing actually used, contoured (via a 1970s
-era nonlinear potential-flow panel code) to preserve the wing's spanwise lift distribution and avoid
the induced-drag penalty that 20 years of wind-tunnel testing had failed to correctly attribute. No
plotted numeric data (illustrative geometry comparison); case study on CFD's diagnostic value.

### Fig 12.42 — Correlation of computed and measured surface pressure contours
*[Raymer, Fig. 12.42, p. 457]* — Cp contour maps (TEAM Euler code vs wind-tunnel measurement) for a
75-deg/62-deg double-delta wing-body at M=0.3, α=20 deg, showing close computed/measured agreement
including the vortex-driven diagonal pressure contours [Ref. 83]. No further numeric data
(qualitative CFD-validation figure).

### Fig 12.43 — CFD streamlines, Dynalifter hybrid airship
*[Raymer, Fig. 12.43, p. 458]* — Streamline visualization around the Ohio Airships Dynalifter (hybrid
wing/lifting-body airship), used to predict drag and optimize shaping [Ref. 84]. No plotted data
(illustrative full-flowfield CFD visualization).

CFD's most valuable emerging application is the *inverse* problem (desired aerodynamic property →
required geometry), via control-theory-based iterative shape optimization (e.g. Jameson et al. [85]:
15-count / 8% drag reduction on a sample transport by eliminating wing shocks at M=0.83). More
routinely, CFD identifies problems (shocks, unwanted vortices, interference, separation) for a
designer to fix by informed intuition.

### Fig 12.44 — Flowfield gridding
*[Raymer, Fig. 12.44, p. 459]* — Structured hexahedral-cell grid around an aircraft, illustrating
gridding complexity at surface junctions (canopy/fuselage) and open regions (wing/canard gap) [Ref.
82]. No plotted data (illustrative meshing figure).

Grid generation (breaking the flowfield into small cells/"cells" for discretized NS solution) remains
a bottleneck (months→weeks→days over time, still slow); results are highly sensitive to grid
shape/topology — reportedly *more* sensitive than the choice of NS vs Euler modeling [Ref. 86].
**Unstructured grids** (tetrahedral, vertex-connected, arbitrary placement — Fig. 12.45) generate much
faster than structured grids, ease adaptive local refinement (e.g. near shocks/leading edges) and
parallelization, at the cost of harder viscous-term handling and distorted-cell risk [Ref. 87].

### Fig 12.45 — Unstructured grid
*[Raymer, Fig. 12.45, p. 460]* — Tetrahedral unstructured mesh around an airfoil, refined
(clustered small cells) at the leading edge and through shocks where pressure gradients are largest
[Ref. 88]. No plotted data (illustrative meshing figure).

Most working aerodynamicists use commercial CFD codes rather than write their own; a complete CFD
analysis spans grid generation, flow/boundary-condition definition, turbulence-model calibration,
execution, post-processing, and translating results into actionable design guidance. CFD does not
eliminate wind-tunnel testing but computes the full flowfield at true (full-scale) Reynolds number,
which the tunnel cannot always match.

## What We've Learned

*[Raymer, p. 461]* Classical methods for computing conceptual-design aerodynamics — maximum lift,
parasite drag, drag due to lift, supersonic wave drag — have been presented; CFD supersedes them with
better fidelity later in the design process.

---

*Chapter 12 complete (Introduction, §§12.1-12.8 [Aerodynamic Forces, Coefficients, Lift, Maximum Lift
(Clean), Maximum Lift with High-Lift Devices, Parasite Drag, Drag Due to Lift, CFD], Tables
12.1-12.8, Figs 12.1-12.45, Eqs. 12.1-12.62, "What We've Learned" summary). PDF index span used:
418-490 (printed pp. 389-462), confirmed by running-header check at both boundaries. Fig. 12.34 (p.
441) was digitized in detail for the F-16 transonic CD0 curve — this is the figure an earlier project
note ("Fig 12.32") actually meant; the true Fig. 12.32 (p. 439) is a rule-based construction diagram,
not a numeric data chart. Three prior `[verify]` flags from `raymer_data.md` are resolved above: Eq.
(12.9) fuselage lift-factor exponent CONFIRMED (=2); Eq. (12.10) endplate coefficient CONFIRMED
(=1.9); Eq. (12.11) winglet form CORRECTED (no separate k-factor — it is `A(1+h/b)^2`, squared, not
`A(1+h/b)·k`). The "smooth molded composite" roughness-`k` value in Table 12.5, previously flagged
`[verify p. 420]`, is now **RESOLVED** (2026-08-17): the page is p. 421, not 420, and the printed
ft value `0.7×10⁻⁵` is a dropped-digit misprint of `0.17×10⁻⁵` — proved by its own metric column,
since every other row converts at 1 ft = 0.3048 m. See the note under Table 12.5.
Several supersonic normal-force-slope (Fig. 12.7) and low-AR max-lift (Figs.
12.12-12.16) nomograph families were not digitized to numeric tables — they are genuinely
multi-parameter charts meant for direct graphical use, not simple curves; cite and consult the source
figure directly when a low-AR or supersonic-leading-edge case is being implemented. Next: Chapter
13 — Propulsion.*
