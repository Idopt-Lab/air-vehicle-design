# Chapter 7 — Configuration Layout and Loft

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 7
"Configuration Layout and Loft," printed pp. 165–212.

Covers the design-layout process itself (sketch to CAD layout to inboard profile), classical conic
lofting of fuselage/wing/tail surfaces, reference-wing geometry equations, wing positioning for
stability, wetted-area/volume estimating equations, and a discussion of CAD pitfalls in conceptual
design. All numbered equations, tables, and figures captured.

---

> ✓ Section numbers corrected 2026-08-18 against the book's own table of contents (front matter,
> p. xii) plus page renders of pp. 175, 182, 191, 192, 201, 206, 207. The earlier extract used a
> made-up §7.3.1/§7.3.2/§7.3.3/§7.4.x/§7.5/§7.6/§7.7 tree. The printed chapter is:
> 7.1 Introduction (165), 7.2 End Products of Configuration Layout (167), 7.3 Conic Lofting (175),
> 7.4 Conic Fuselage Development (179), 7.5 Flat-Wrap Fuselage Lofting (185),
> 7.6 Circle-to-Square Adapter (188), 7.7 Loft Verification via Buttock-Plane Cuts (189),
> 7.8 Wing/Tail Layout and Loft (191), 7.9 Wetted-Area Determination (204),
> 7.10 Volume Determination (206), 7.11 Use of CAD in Conceptual Design (207).
> §7.8 subsections: 7.8.1 Reference Wing/Tail Layout, 7.8.2 Wing Location with Respect to the
> Fuselage, 7.8.3 Wing/Tail Lofting, 7.8.4 Airfoil Linear Interpolation, 7.8.5 Airfoil Flat-Wrap
> Interpolation, 7.8.6 Wing/Tail Cross-Section Layout, 7.8.7 Wing Fillets, 7.8.8 Winglet Design.
> Note that the book's §7.6 (Circle-to-Square Adapter) has no separate heading in this extract — its
> content sits inside the flat-wrap material below.

## §7.1 Introduction

The design layout — drawing or CAD-file geometry — is the actual deliverable of conceptual design;
every other discipline (aero, structures, weights, propulsion, S&C) exists to inform and improve that
layout, and only the layout geometry is ever built. A poor initial layout costs enormously more to fix
later (design changes after wind-tunnel/trade studies need real time to integrate, not "a few days of
CAD work"). Configuration layout has historically been done by designers with ~10 years of prior
experience (typically aero or structures) plus an apprenticeship, because the layout must reflect many
downstream "good practice" considerations (pilot vision, airport compatibility, maintenance access —
Chapters 8-11) while the designer's hands are drawing it.

## §7.2 End Products of Configuration Layout

Layout work starts from rough conceptual sketches (Fig. 7.1) showing overall arrangement (fuselage,
wing, tails) and major internal component locations (gear, crew/payload compartment, propulsion,
fuel, unique equipment); sketches are internal-only, used to organize thinking and estimate sizing
inputs per Chapter 3.

### Fig 7.1 — Design sketch
*[Raymer, Fig. 7.1, p. 166]* — Reproduction of the actual hand sketch that started Rockwell/North
American's ATF (Advanced Tactical Fighter) competition entry. No plotted data (historical artifact).

### Fig 7.2 — Design layout on a CAD system
*[Raymer, Fig. 7.2, p. 167]* — The Fig. 7.1 sketch developed into a full CAD layout on Rockwell's
conceptual-design software, dimensioned in fuselage-station inches (station callouts to ~492), with
engine (a bypass-ratio-0.505 STF686-derivative turbofan, per the annotation) and all-moving vertical
tail details labeled. No further numeric trend data beyond the station dimensions shown on the
drawing itself.

### Fig 7.3 — (drafting-table layout)
*[Raymer, Fig. 7.3, p. 168, referenced]* — Rockwell's X-29 Forward Sweep Demonstrator competition
entry, a classic drafting-table layout (same design technique whether hand-drafted or CAD). No
plotted data (photo/diagram of a historical layout).

A design layout is the required input to the Chapter 12-19 analysis/optimization tasks, which need
measured trapezoidal wing/tail geometry plus lengths, areas, and volumes — best measured by the
designer directly rather than handed off as a raw CAD file. Three additional designer-prepared inputs:
the wetted-area plot, the volume-distribution plot (both discussed later in this chapter), and
fuel-volume plots (Chapter 10).

### Fig 7.4 — Wetted area plot (example)
*[Raymer, Fig. 7.4, p. 171]* — Example output: cross-section perimeter (y-axis, 0–750+) vs. fuselage
station (x-axis, 0–600), area under the curve = wetted area. Component surface totals given alongside
for this example aircraft: Fuselage 70,344.8, Vert tail 26,165.3, Wing 102,636.7, Circular arc canopy
9071.4, Nacelle 25,462.9, Total 233,681.0. Illustrative example values, not general design data.

✓ Corrected 2026-08-18 against a 320-dpi render: the figure is on book **p. 171**, not p. 170
(p. 170 carries Fig. 7.3, the FSW design layout). All six numbers confirmed digit-for-digit. The book
prints no unit on the "Surface" column or on either axis; the companion layout drawing (Fig. 7.3)
uses fuselage stations in inches over the same 0–600 range, so the values are consistent with in².
That inference is the extractor's, not the book's.

### Fig 7.5 — Volume distribution plot (example)
*[Raymer, Fig. 7.5, p. 171]* — Companion plot: cross-section area (y-axis, 0–4000+) vs. fuselage
station (x-axis, 0–600), area under curve = internal volume. Same example aircraft's component
volumes: Fuselage 847,124.4, Vert tail 42,903.5, Wing 287,005.5, Circular arc canopy 46,014.0,
Nacelle 95,149.8, Total 1,318,196.8.

✓ Corrected 2026-08-18: page is **p. 171**, not p. 170. All six numbers confirmed. Units again
unprinted in the book; consistent with in³ by the same station-axis argument.

After iterative analysis/optimization/redraw, a far more detailed **inboard profile** drawing is
prepared during preliminary design, showing actual "black box" locations, wire bundles, and cooling
ducts (vs. the initial layout's merely statistical avionics-bay volume). This is a team effort taking
many weeks, and often forces initial-layout rework if room runs short — hence the emphasis on getting
the initial layout right.

### Fig 7.6 / 7.7 — Inboard profile drawings
*[Raymer, Figs. 7.6-7.7, p. 168-169, referenced]* — Fig. 7.6: inboard profile for the Fig. 7.3 design.
Fig. 7.7: a 1942 P-51 variant side-view inboard profile showing bellcranks, radio boxes, fuel lines in
full detail. No plotted numeric data (detailed engineering drawings, beyond this book's scope to
reproduce).

A companion "lines control" drawing refines external geometry alongside the inboard profile; modern
practice does both in 3D CAD.

### Fig 7.8 — Inboard isometric drawing
*[Raymer, Fig. 7.8, p. 175, referenced]* — Illustration-only isometric (art-group product for
briefings/proposals), often published (and sometimes done better) by aviation magazines than by the
manufacturer itself. No plotted data.

## §7.3 Conic Lofting

"Lofting" = defining the aircraft's external geometry (term from shipyard "loft" drawing rooms).
Production lofting gives an exact mathematical surface definition accurate to a few hundredths of an
inch, letting parts built at different plants assemble correctly; modern CAD systems now do this
directly. For initial layout, less rigor suffices, but the fuselage/wing/tail/nacelle lofting must be
defined well enough to show proper enclosure of internal components/fuel with a smooth aerodynamic
contour.

Ship-hull lofting historically used flexible "splines" (thin wood/plastic rulers) held by lead weights
("ducks") to fair a longitudinal contour by trial and error — slow, and not a unique mathematical
surface definition.

### Fig 7.9 — Spline lofting
*[Raymer, Fig. 7.9, p. 176]* — Diagram of a flexible spline held down by lead "ducks" to fair a
longitudinal line. No plotted data.

**Conic lofting** (introduced on the P-51 Mustang) instead defines curves via a mathematically exact
second-degree "conic" (circle, ellipse, parabola, hyperbola — the family produced by slicing a right
circular cone at varying angle: perpendicular → circle, slanted → ellipse, parallel to the opposite
side → parabola, steeper → hyperbola). Widely used through ~1980s; still a useful conceptual
foundation even though modern CAD uses more sophisticated curve math.

### Fig 7.10 — Conic geometry definition
*[Raymer, Fig. 7.10, p. 177]* — Cone-slice diagram showing the ellipse/parabola/hyperbola family and
labeling special shoulder points "E." No plotted data (geometry definition figure).

A conic is constructed on the drafting table from endpoints A, B and their tangent directions
(intersecting at point C), plus a shoulder point S controlling the curve's shape between A and B.

### Fig 7.11 — Conic layout (construction procedure)
*[Raymer, Fig. 7.11, p. 178]* — Step-by-step graphical construction: draw A-S and B-S; draw an
arbitrary line from C, find its intersections with A-S/B-S; draw lines from A and B through those
intersections; their intersection is a point P on the conic. Repeating with different arbitrary lines
from C generates enough points to fair with a French curve. No plotted numeric data (procedure
diagram).

### Fig 7.12 — Conic layout example
*[Raymer, Fig. 7.12, p. 178, referenced]* — Worked example applying the Fig. 7.11 procedure. No
plotted data.

**Conic fuselage development**: at several "control cross sections" (control stations) along the
fuselage, the A/B/C/S points are connected longitudinally by smooth "longitudinal control lines";
intermediate cross sections are then generated by reading A/B/C/S off those control lines at the
desired station and re-running the Fig. 7.11 conic construction.

### Fig 7.13 — Longitudinal control lines
*[Raymer, Fig. 7.13, p. 179]* — Upper half of a simple fuselage showing A/B/C/S points at three
cross-sections connected by smooth longitudinal lines. No plotted data.

### Fig 7.14 — Cross-section development from longitudinal control lines
*[Raymer, Fig. 7.14, p. 180]* — Side/top views of the longitudinal control lines, showing how a new
intermediate cross-section's A/B/C/S points are measured off them (from both side and top view) and
then run through the conic construction. Typically 5-10 control stations suffice to develop a full
fuselage. No plotted data.

### Fig 7.15 — Typical fuselage lofting (worked fighter example)
*[Raymer, Fig. 7.15, p. 181]* — Five control stations (0, 120, 240, 370, 500) for a fighter fuselage,
plus an interpolated station 290: Station 0 = nose (a single point, origin of all longitudinal control
lines); Station 120 = circular-ish cockpit-driven cross-section (two conics, upper+lower, sharing a
common A/B point); Station 240 = flat-sided cross-section for a side inlet (e.g. F-4, MiG-23, Gripen);
Station 370 = squarish cross-section (room for gear or a low-wing attachment); Station 500 = circular,
matching a round exhaust nozzle. No plotted numeric-trend data (worked construction example; station
numbers are example inches along the fuselage, not general design data).

## §7.4.3 Conic Shape Parameter

Controlling shoulder-point location directly (rather than via a longitudinal control line) uses a
shape parameter `p`. Point D is the midpoint of A-B; a special shoulder point E lies on line D-C:

**Eq (7.2)** *[Raymer, Eq. (7.2), p. 182]*: `p = |DE| / |DC|`

**Eq (7.3)** *[Raymer, Eq. (7.3), p. 182]*: `|AD| = |BD|`

**Eq (7.4)** *[Raymer, Eq. (7.4), p. 182]* — conic type by `p`:
- Hyperbola: `p > 0.5`
- Parabola: `p = 0.5`
- Ellipse: `p < 0.5`
- Circle (special ellipse case): `p = 0.4142`, with `|AC| = |BC|`

Larger `p` (→1.0) gives a nearly square conic (shoulder point near C); smaller `p` (→0.0) approaches
the straight line A-B. To lay out a conic given `p` (rather than a known S): bisect A-B to find D,
then measure `p·|DC|` along D-C from D to locate S, and proceed as in Fig. 7.11.

### Fig 7.16 — Conic layout using p
*[Raymer, Fig. 7.16, p. 183]* — Diagram: given A, B, C and `p`, construct D (midpoint of A-B) and
locate S along D-C at distance `p·|DC|` from D. No plotted data (construction diagram; the equation is
Eq. 7.2 above).

Using constant `p = 0.4142` at both fuselage ends gives circular end cross-sections; `p` can vary
smoothly along the fuselage (e.g. Fig. 7.15's example: 0.4142 at nose/tail, ~0.7 at midbody) via an
"auxiliary control line" for `p` itself.

### Fig 7.17 — Conic fuselage development using p
*[Raymer, Fig. 7.17, p. 184]* — Example: upper conic held at constant `p = 0.4142`; lower conic's `p`
varies from 0.4142 (nose/tail) to ~0.6 (midbody), "squaring" the lower fuselage for landing-gear room.
*(read from plot, p-vs-station control curve)*:

| Fuselage station (fraction of length) | Lower-conic p |
|---|---|
| 0 (nose) | 0.4142 |
| ~0.25 | ~0.5 |
| ~0.5 (midbody) | ~0.6 |
| ~0.75 | ~0.5 |
| 1.0 (tail) | 0.4142 |

(Approximate values read off the auxiliary p-control-line sketch in Fig. 7.17; the figure is a
qualitative worked-example curve, not general design data — treat these five points as illustrative
only.)

### Fig 7.18 — Cross-section development using p
*[Raymer, Fig. 7.18, p. 185]* — Two example cross-sections (Section A: upper `p=0.4142`, lower
`p=0.595`; Section B: upper `p=0.4142`, lower `p=0.610`) built by the Fig. 7.16 method. No further
plotted data (worked construction example).

### Fig 7.19 — Isometric of SAAB Draken major loft lines
*[Raymer, Fig. 7.19, p. 185, referenced]* — Photo/diagram of the conic-developed loft scheme for the
supersonic SAAB J-35 Draken (fuselage, nacelle, canopy, inlet duct, wing/tail lines definition). No
plotted data.

## §7.5 Flat-Wrap Fuselage Lofting

"Compound curvature" = surface curvature in every direction at a point (e.g. a ball); a surface curved
in only one direction is "flat-wrapped" (e.g. a cylinder) and can be built by wrapping a flat sheet —
much cheaper to fabricate (bend vs. stretch/stamp). Real cost impact example: on the X-31, changing
the last 30 in {76 cm} of aft titanium fuselage to flat-wrap eliminated a hot-die-forming step that
would have cost ≈$400,000 (1999 dollars) in tooling and paced the schedule.

Simplest flat-wrap technique: hold the cross-section shape constant along the length (e.g. most of a
commercial airliner's circular fuselage), or linearly scale a constant cross-section shape (e.g. a
cone, or a linearly-scaled non-circular tailcone). With conics, flat-wrap is achieved (or closely
approximated for a smoothly-varying cross section) if (1) longitudinal control lines are straight
(including the shoulder-point line, or `p` held constant/linear) and (2) conic tangent angles do not
change longitudinally (easily met if tangents stay horizontal/vertical, as in Figs. 7.15/7.17).

### Fig 7.20 — Complex flat-wrapped surface
*[Raymer, Fig. 7.20, p. 187]* — A fuselage built from 5 conics plus a straight flat underside, with a
shrinking "bump" (canopy-like) on top toward the rear, conic endpoints sharing tangent angles
throughout. No plotted data.

Flat-wrap is a fabrication-cost/aerodynamic-drag tradeoff: a smooth teardrop shape has less drag than
a flat-wrapped cylinder-plus-cones.

### Fig 7.21 — Circle-to-square adapter
*[Raymer, Fig. 7.21, p. 188]* — A duct transition (e.g. square inlet to circular engine face, or 2-D
nozzle) built flat-wrap using interlocking V-shaped segments (flat square-section sides taper to
points touching the circle; conical circular-section sides taper to points touching the square's
corners), connecting surfaces straight longitudinally. No plotted data.

## §7.7 Loft Verification via Buttock-Plane Cuts

Borrowed from shipbuilding: hull "waterlines" (horizontal cuts) check longitudinal smoothness. For
aircraft, vertical "buttock-plane" ("butt-plane") cuts — the intersection of the aircraft with planes
parallel to and offset from the centerline — are used instead, because an airfoil is itself a
butt-plane cut of the wing.

### Fig 7.22 — Buttock-plane cut
*[Raymer, Fig. 7.22, p. 189]* — Diagram defining a butt-plane cut (e.g. "butt-plane 30" = the contour
30 in from centerline) and noting the wing-airfoil correspondence. No plotted data.

### Fig 7.23 — Buttock-plane cut layout
*[Raymer, Fig. 7.23, p. 190]* — Procedure: mark chosen butt-plane locations on each cross-section
(top view), transfer the intersection points to the side view, connect longitudinally — smooth
longitudinal lines confirm a smooth fuselage surface; the same construction can generate new cross
sections. Most useful for highly irregular shapes (e.g. blended-wing-body forebodies like the B-1B).
No plotted data.

## §7.8 Wing/Tail Layout and Loft

### §7.8.1 Reference Wing/Tail Layout

Chapter 4 sets aspect ratio `A`, taper ratio `λ`, sweep, dihedral, thickness, airfoil; Chapter 6 sets
actual wing/tail/fuselage sizes from an initial `W0` estimate. From these, the reference (trapezoidal)
planform follows:

**Eq (7.5)** *[Raymer, Eq. (7.5), p. 191]*: `b = √(A·S)`

**Eq (7.6)** *[Raymer, Eq. (7.6), p. 191]*: `Croot = 2S / (b·(1+λ))`

**Eq (7.7)** *[Raymer, Eq. (7.7), p. 191]*: `Ctip = λ·Croot`

### Fig 7.24 — Reference (trapezoidal) wing/tail
*[Raymer, Fig. 7.24, p. 191]* — Planform diagram defining span `b`, root/tip chord, and the mean
aerodynamic chord (MAC, `c̄`) location. No plotted data beyond the geometry definitions used in
Eqs. 7.5-7.9.

**Eq (7.8)** *[Raymer, Eq. (7.8), p. 192]* (MAC): `c̄ = (2/3)·Croot·(1+λ+λ²)/(1+λ)`

**Eq (7.9)** *[Raymer, Eq. (7.9), p. 192]* (spanwise MAC location): `ȳ = (b/6)·(1+2λ)/(1+λ)`

✓ Eqs. (7.5)–(7.9) confirmed 2026-08-18 against 320-dpi renders of book pp. 191–192. One change:
Eq. (7.9) is printed as `(b/6)·((1+2λ)/(1+λ))`; the earlier extract wrote the algebraically
identical `(b/2)·(1+2λ)/(3(1+λ))`, which is not the printed form. Eqs. (7.5)–(7.8) print exactly
as given above.

`c̄` is the chord at which subsonic pitching moment is invariant with angle of attack when measured
about the point 25% aft of its leading edge. For a **vertical tail**, double the `ȳ` from Eq. (7.9)
(the vertical tail's true full-span-equivalent area is twice its actual — half of a hypothetical
laid-flat symmetric wing); all other vertical-tail calculations are unchanged. A quick graphical
`c̄`/`ȳ` construction: `ȳ` is the intersection of the 50%-chord line with a line from (tip-chord length
behind the root chord) to (root-chord length ahead of the tip chord); `c̄` is then drawn at that
station.

For an **elliptical** wing (Chapter 4: lower drag than trapezoidal, and modern composite construction
may remove its historical cost penalty): span from Eq. (7.5) as usual, then

**Eq (7.10a)** *[Raymer, Eq. (7.10a), p. 192]*: `Croot = 4S / (π·b)`

**Eq (7.10b)** *[Raymer, Eq. (7.10b), p. 192]*: chord as a function of spanwise distance `y` from
centerline (elliptical chord distribution):
```
C(y) = Croot * sqrt(1 - (y/(b/2))^2)
```
✓ Resolved 2026-08-18 against a 320-dpi render of book p. 192. The earlier extract left this
equation blank because the OCR text layer dropped the radical; the printed form is the one above.

For an elliptical wing, MAC = 84.9% of `Croot`, and `ȳ` = 52.9% of the semispan; total area =
`(π/4)·b·Croot`. Elliptical-wing chords are commonly "slid" chordwise so the 25%-chord line is
straight/unswept — doesn't affect these formulas, but shifts the 25%-MAC location slightly forward.

### §7.8.2 Wing Location with Respect to the Fuselage

The wing is positioned so a chosen %MAC aligns with the aircraft c.g., as a first estimate toward the
required stability. A pure flying wing is neutrally stable with c.g. at 25% MAC (pitching moment
invariant there, by definition of MAC). With an aft tail: **stable** aircraft ≈30% MAC; **unstable**
aft-tail aircraft (e.g. F-22) needs the wing farther forward, c.g. ≈40% MAC as a first approximation.
Canard aircraft: less reliable rules of thumb (canard downwash affects the wing). Control-canard,
computer-stabilized (unstable) aircraft: c.g. ≈15-20% wing MAC. Lifting-canard aircraft: find each
surface's ≈15% MAC point (≈20-25% if unstable), then area-weight-average the wing and canard MAC
locations for a combined (crude) estimate. Wing position and tail sizing are expected to be revised
after Chapters 12-19 analysis.

### §7.8.3 Wing/Tail Lofting

The actual exposed wing/tail (vs. the trapezoidal *reference* wing used for aerodynamic coefficients)
begins at the fuselage side and reflects true dihedral-corrected area (dividing by `cos(dihedral)`)
and non-trapezoidal planform features.

### Fig 7.25 — Nontrapezoidal wings
*[Raymer, Fig. 7.25, p. 194]* — Four variants: (a) rounded wingtip; (b) trailing-edge "kick"/"bat"
(increases flap chord and wing thickness for gear stowage); (c) leading-edge extension/LEX (extra
combat-maneuver lift, Chapter 12); (d) highly blended wing/body (reduces transonic/supersonic shocks,
but classical analysis using the reference-wing parameters becomes less accurate the more the actual
shape departs from it — computational aero methods are unaffected). No plotted numeric data.

For an untwisted wing/tail with constant airfoil section and t/c, surface cross-sections are drawn by
scaling airfoil coordinates to the local chord at each span station.

### Fig 7.26 — Airfoil layout on wing planform
*[Raymer, Fig. 7.26, p. 195]* — Airfoils drawn lightly on the wing top view along their chord lines,
to ease later cross-section generation. No plotted data.

With twist, incidence at each station rotates the chord line first, and the local chord length (in
top view) must be increased by `1/cos(incidence)`.

### Fig 7.27 — Airfoil layout with twist
*[Raymer, Fig. 7.27, p. 196]* — Example twist schedule (angles exaggerated for illustration): root
+1.0 deg, mid ~0 deg, tip about -1.0 to -2.0 deg (illustrative washout example, not general design
data — `(read from plot)` approximate stations only, since the figure is schematic).

### Fig 7.28 — Wing airfoil layout: nonlinear variations
*[Raymer, Fig. 7.28, p. 196]* — Separate auxiliary control lines for twist, camber, and t/c allow
independent spanwise variation of each (airfoil decomposed into camber line + thickness distribution,
each scaled per its own control line, then recombined). No plotted numeric data (schematic method
figure).

### Fig 7.29 — Wing airfoil rigging
*[Raymer, Fig. 7.29, p. 197]* — "Rigging" = vertically shifting airfoil sections (root-to-tip) until a
desired spanwise line (e.g. an aileron/flap hinge line) becomes straight — hinge lines cannot be
curved, so a wing whose complex lofted surface would otherwise produce a curved hinge line needs this
correction (illustrated: unrigged vs. rigged, with the mid-span airfoil section moved down to
straighten section B-B). No plotted data.

### §7.8.4 Airfoil Linear Interpolation and §7.8.5 Airfoil Flat-Wrap Interpolation

Wings are often defined by distinct root/tip airfoils (root for performance, tip for gentle stall, so
the tip stalls after the root) plus incidence/twist, with intermediate sections interpolated.

**Linear interpolation** ("ruled surface," Fig. 7.30): superimpose root/tip airfoils on the planform;
draw a constant-%-chord spanwise line; swing each airfoil point down to its chord line; connect the
root/tip swung-down points; at the desired intermediate span station, find where its chord line
crosses that connecting line, then swing the point back up to thickness — repeat for enough points to
draw the new airfoil (an experienced designer: ~15 min by hand; instant in CAD). Interpolated section
properties are approximately the (also linearly interpolated) root/tip section properties — not
necessarily valid for modern laminar airfoils.

### Fig 7.30 — Wing airfoil layout: linear interpolation
*[Raymer, Fig. 7.30, p. 198]* — 6-step graphical procedure as described above. No plotted data
(construction diagram).

**Flat-wrap interpolation** (Fig. 7.31) is needed if a true flat-wrap (no compound curvature) surface
matters — same procedure, but the spanwise connecting line in step 2 must join points of *equal
surface slope* (tangent angle) between root and tip, not equal %-chord. Practical consequence: hot-wire
foam-cutting of composite wings using root/tip templates with equal-%-chord tic-marks produces a
linearly-interpolated (not flat-wrap) surface if the airfoils differ or the wing is twisted; this is
harmless under a flexible fiberglass skin but can leave a metal/plywood skin standing proud of a
depressed foam core, weakening the bond — a real potential in-flight-failure mechanism.

### Fig 7.31 — Wing airfoil layout: flat-wrap
*[Raymer, Fig. 7.31, p. 200]* — Same 6-step method as Fig. 7.30 but step 2 connects equal-slope points
rather than equal-%-chord points. No plotted data.

### §7.8.6 Wing/Tail Cross-Section Layout

Once airfoils are drawn on the wing top view, a cross-section perpendicular to the aircraft centerline
(needed to verify fuel tank/gear/spar fit) is built by drawing verticals at each airfoil's span
station, showing the wing reference plane at the dihedral angle, and transferring upper/lower airfoil
points relative to that plane; French curves fair the result. The same method works for oblique
(non-perpendicular) cuts, e.g. Fig. 7.29's A-A/B-B sections.

### Fig 7.32 — Wing/tail cross-section layout
*[Raymer, Fig. 7.32, p. 200]* — Diagram of the construction just described. No plotted data.

### §7.8.7 Wing Fillets

A wing fillet smooths the wing-fuselage juncture aerodynamically, usually a circular arc (radius
≈10% of root chord as a starting point, often increasing toward the rear to control separation;
sometimes present only aft of max-thickness) tangent to both surfaces; the arc lies in a vertical
plane at max thickness and rotates to a horizontal (top-view) plane at the leading edge. Often
"eyeballed" for initial layout since it appears on only a few of the many drawn cross-sections. Some
aircraft instead use a simple straight near-vertical fillet line, less elegant but functionally
adequate.

### Fig 7.33 — Wing fillet layout
*[Raymer, Fig. 7.33, p. 201]* — Diagram: fillet arc radius, leading-edge fillet, and an auxiliary
fillet-radius control line for a longitudinally-varying radius. No plotted data.

### §7.8.8 Winglet Design

Winglets (Chapter 4: reduce induced drag, especially for high-span-loading wings, e.g. when a design
is recertified to higher `W0` without extending span) work by generating an inward side force with a
small forward (thrust-like) component, from the wingtip vortex rotation — this requires the winglet
to be wing-like (cambered, at local angle of attack). Equivalently: the winglet's "outwash" pushes the
wingtip vortices farther outward, increasing effective span and reducing lift-induced drag in the far
field; it also acts as an endplate, resisting tip flow-around and allowing more near-tip lift.

### Fig 7.34 — Winglet design guidelines (Whitcomb "classic" winglet)
*[Raymer, Fig. 7.34, p. 203]* — Design-guideline diagram, after NASA N76-26163 (R. Whitcomb, original
winglet developer):

| Parameter | Guideline value |
|---|---|
| Upper-winglet start station | at wing-tip airfoil's max-thickness point |
| Upper-winglet sweep | approximately equal to wing sweep |
| Upper-winglet height | ≥ wing tip chord (taller is better; drag reduction ≈ proportional to height) |
| Upper-winglet camber | greater than the wing's |
| Upper-winglet incidence | 4 deg leading-edge-out |
| Upper-winglet t/c | ≈8% (typical) |
| Lower-winglet root incidence | 7 deg (if included) |
| Lower-winglet tip incidence | 11 deg (if included) |
| Winglet dihedral (upper panel, per figure) | ≈15 deg from vertical, per the figure's callout |

The lower winglet panel contributes less drag reduction and risks ground-scrape on roll, so many
designs omit it. Further drag reduction: smoothly curve the wingtip up into the winglet (no separate
attached piece). Caution: winglet mass sits aft/outboard of the wing elastic axis, raising flutter
risk — needs aeroelastic analysis and possibly structural stiffening (a weight penalty that can offset
the drag benefit).

## §7.9 Wetted-Area Determination

Wetted area `Swet` (total exposed surface — what would get wet if dipped in water) drives friction drag
estimation.

### Fig 7.35 — Wing/tail wetted-area estimate
*[Raymer, Fig. 7.35, p. 204]* — Diagram defining true-view exposed planform area `Sexposed` (projected
top-view area divided by `cos(dihedral)`). No plotted data beyond the geometry definition used in
Eqs. 7.11-7.12.

**Eq (7.11)** *[Raymer, Eq. (7.11), p. 204]*, if `t/c < 0.05`: `Swet = 2.003·Sexposed`

**Eq (7.12)** *[Raymer, Eq. (7.12), p. 204]*, if `t/c > 0.05`: `Swet = Sexposed·[1.977 + 0.52·(t/c)]`

(A paper-thin surface would give exactly `2·Sexposed`; finite thickness increases it per these
formulas.) `Sexposed` is traditionally measured off the drawing with a planimeter or by counting graph
squares.

### Fig 7.36 — Quick fuselage wetted-area estimate
*[Raymer, Fig. 7.36, p. 205]* — Diagram defining fuselage top-view projected area `Atop` and side-view
projected area `Aside`. No plotted data beyond the geometry definitions used in Eq. 7.13.

**Eq (7.13)** *[Raymer, Eq. (7.13), p. 205]*: `Swet ≈ 3.4·(Atop + Aside)/2`

(For a long thin circular-cross-section body, `π×`(average projected area) gives wetted area exactly;
for a rectangular cross-section, `4×`; Eq. 7.13's coefficient 3.4 is a general-purpose compromise
between those two extremes.)

### Fig 7.37 — Fuselage wetted-area plot (graphical-integration method)
*[Raymer, Fig. 7.37, p. 206]* — Cross-section perimeter (measured by "map-measure" or a tic-marked
scrap-paper trace) plotted vs. longitudinal station; area under the curve = wetted area (more accurate
than Eq. 7.13). Perimeter measurements exclude joined-component intersections (e.g. wing-fuselage
junction — not wetted). No further plotted numeric data (method figure; example values are in Fig. 7.4
above).

## §7.10 Volume Determination

Internal volume is a sanity check against statistical volume-vs-`W0` data for the aircraft class — a
design with less-than-typical volume for its weight risks development/maintainability problems (often
used by customer engineering groups to catch an over-optimistic layout). A more refined "net design
volume" density check is in Chapter 19.

**Eq (7.14)** *[Raymer, Eq. (7.14), p. 207]*: `Vol ≈ 3.4·(Atop·Aside) / (4·L)`
(page citation corrected 2026-08-18 from p. 206 to p. 207; §7.10 *starts* on p. 206 but the equation
prints at the top of p. 207. Form confirmed against the page image.)

(`L` = fuselage length; the 3.4 factor assumes a cross-section shape intermediate between square and
circular — same coefficient family as Eq. 7.13.)

### Fig 7.38 — Aircraft volume plot (graphical-integration method)
*[Raymer, Fig. 7.38, p. 207]* — Cross-section area plotted vs. longitudinal station; area under curve
= volume (more accurate than Eq. 7.14). This "volume distribution plot" is also the basis of
supersonic wave-drag / transonic-drag-rise prediction (its shape directly sets supersonic drag —
Chapter 12). No further plotted numeric data (method figure; example values in Fig. 7.5 above).

## §7.11 Use of Computer-Aided Design (CAD) in Conceptual Design

Modern CAD gives powerful surfacing, rendering, and data management (some systems auto-generate
hydraulic tubing/access-door geometry from a designer-specified path). Full digital product definition
enables virtual mockups (catching interference/fabrication/maintenance problems earlier) and clean
handoff to CAM.

Cautions specific to conceptual design use:
- CAD tends to steer designers toward the "easy" geometric choice (e.g. simple straight-inward gear
  retraction, or a simple square fuel tank) even when a harder-to-model shape would be a better design.
- Automated area/volume/wetted-area calculations can silently be wrong at component intersections
  (e.g. failing to subtract the wing-root "wetted area" cut out of the fuselage, or failing to exclude
  an inlet/exhaust/propeller-disk opening from a solid model) — Raymer strongly recommends validating
  any CAD tool first on a trivial tube-plus-cone-fuselage-and-simple-wing case with hand-calculable
  wetted area/volume before trusting it on a real design.
- A design course can become a "which button does what" CAD-tool course at the expense of teaching
  actual conceptual-design philosophy/method — time spent on the former is time not spent on the
  latter.
- With CAD, every design *looks* professionally finished regardless of underlying quality — unlike
  hand-drafting, where technique itself signaled a beginner's work and prompted extra review.

Conceptual-design CAD tools should instead be tailored to conceptual design's actual fluid, iterative
workflow — e.g. automatically re-deriving the *non*-trapezoidal wing shape (and all parts built from
it: tanks, flaps, ailerons, spars, ribs, gear attachments) whenever a designer edits a trapezoidal
parameter like aspect ratio, rather than requiring manual rework each iteration.

### Fig 7.39 — Automated revision of wing geometry
*[Raymer, Fig. 7.39, p. 210]* — RDS-Professional example: trapezoidal wing parameters (upper left) plus
the resulting non-trapezoidal wing (with swept-back tip, LE strake, TE kick) at upper right; after
changing aspect ratio/taper/sweep (lower left), the wing automatically regenerates with the same
non-trapezoidal features (lower right). No plotted numeric data (software-capability illustration).

### (uncaptioned photo, p. 210-211)
*[Raymer, p. 210-211]* — "Notional Design Layout: Advanced Technology Commuter/Cargo Jet" (D. Raymer,
Conceptual Research Corp.) and a C-17 Globemaster photo (NASA/Jim Ross) — illustrative photos, no
plotted data.

---

*Chapter 7 complete (Eqs 7.2–7.14, Figs 7.1–7.39; Eq. (7.1), the generalized conic form, is stated in
the book but never used directly — omitted here per the book's own guidance to use the specialized
forms instead). Next: Chapter 8 — Special Considerations in Configuration Layout.*
