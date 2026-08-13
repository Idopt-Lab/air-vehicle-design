# Chapter 24 — Conceptual Design Examples

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 24
"Conceptual Design Examples," printed pp. 867-958.

Two full worked design examples applying the book's methods end to end: (1) the **DR-1**, a
single-seat aerobatic homebuilt (fixed-size, off-the-shelf piston engine; done entirely by hand with
a pocket calculator, plus a small sizing-iteration helper program, "AC-SIZE"), and (2) the **DR-3**,
a lightweight supercruise fighter (variable "rubber" engine sized during iteration; hand calculation
for pre-layout sizing, then the author's RDS-Student program for the detailed number-crunching,
carpet-plot optimization, and performance/cost analysis). The author explicitly grades both examples
as at-most-a-"B" — incomplete relative to a full professional design effort, intended to show the
*process*, not a finished, buildable aircraft ("Homebuilders: don't build this one either!").

**OCR note:** the DR-1 example is reproduced in the book from the author's original *hand-written*
design notes (deliberately, to show it is a fully by-hand process); the scan's OCR layer for this
handwritten material is extremely unreliable (single garbled characters/values throughout). Numeric
values below from the DR-1 example are given only where they could be read with reasonable
confidence from the scan or cross-checked against the surrounding typed context (e.g. the AC-SIZE
program printouts, which are typeset and OCR cleanly); uncertain values are flagged
`[verify p. NNN]` or omitted rather than guessed. The DR-3 example is mostly typeset (RDS-Student
program input/output listings) and OCR'd cleanly; its numbers are reproduced with higher confidence.

---

## §24.1 Introduction
*[Raymer, p. 867]*

Rather than scatter worked examples through every chapter, the book concentrates two full design
studies here, covering the extremes of the conceptual-design process: a fixed-engine, propeller-driven
homebuilt vs. a "rubber-engine" supersonic fighter. Design requirements for both were assumed from
data on similar existing aircraft, then treated as if customer-mandated. The DR-1 is analyzed
entirely by hand (bar the sizing-iteration loop, done with a simple free helper program, "AC-SIZE,"
available from the author's website, or easily rewritten); the DR-3 uses hand calculation only for
pre-layout sizing (initial `T/W`, `W/S`) and the author's RDS-Student software (bundled with the book
via AIAA) for everything after the initial layout. The author recommends students always do the
pre-layout sizing steps by hand, as shown here, before being allowed to use RDS-Student (or any other
"canned" design tool) for the laborious number-crunching.

## §24.2 Single-Seat Aerobatic Homebuilt (DR-1)
*[Raymer, p. 868]*

**Concept.** A weekend-aerobatics homebuilt intended to out-perform the Great Lakes biplane without
the Pitts Special's twitchy handling. Classical layout, built via moldless foam-fiberglass sandwich
construction for quick "garage" fabrication; the selected engine comes pre-configured for aerobatic
(inverted-fuel-system) operation to minimize installation effort. A notable optimization result: the
wing loading needed to meet the no-flaps stall-speed requirement strongly biases the aspect-ratio
optimum *downward* — the resulting wing has a normal span but an oversized (excess) chord to reach
the required area.

### DR-1 design requirements (from the design-sketch sheet)
*[Raymer, p. 869]*

- Single-seat aerobatic homebuilt; engine: Lycoming O-320-A2B, 150 hp {112 kW} at 2700 rpm, engine
  weight 272 lb.
- Design goal: performance between the Pitts S-1S and the Great Lakes biplane.
- Fabrication: foam and fiberglass (moldless sandwich construction).
- `Vmax` ≈ 150 kt; `Vstall` ≈ 50 kt; takeoff ground roll ≈ 1000 ft; roll rate ≥ 180 deg/s
  `[verify p. 869]`; ceiling ≥ 15,000 ft.
- Range ≈ 280 nm (with reserves), flown at `Vc` ≈ 115 kt.
- `Wcrew` = 220 lb (includes chute/survival gear).
- Handling qualities: slightly stable (like a light fighter); good spin recovery, upright and
  inverted.

### Fig 24.1 — DR-1 design-requirements sketch sheet
*[Raymer, Fig. 24.1 (unnumbered design sheet), p. 869]* — Hand-drawn three-view sketch with the
requirements above annotated around it (span ≈ 30 ft, length ≈ 32 ft, height ≈ 7 ft, per the
legible dimension callouts). No plotted numeric data beyond the requirement values listed above
(hand sketch, largely illegible via OCR beyond the callouts already captured)
`[verify p. 869, dimension callouts]`.

### Wing geometry, tail geometry, and airfoil selection
*[Raymer, pp. 872-873]*

Wing: AR and taper ratio selected from historical charts/tables (Chapter 4); quarter-chord sweep set
to 0 (no sweep needed at this speed); dihedral ~3 deg. Airfoil: NACA 632-015 (root, thick enough to
resist tip-first stall trends) transitioning to NACA 632-012 (tip); no washout (twist) used, to avoid
compromising inverted-flight stall behavior. Horizontal tail: AR = 4; vertical tail: AR ≈ 1.8,
taper ≈ 0.6 `[verify p. 872]`; both tail surfaces use a NACA 0012 section.

### Wing loading, stall, climb, and cruise sizing constraints
*[Raymer, pp. 873-874]*

Historical wing-loading comparables cited: Pitts `W/S` ≈ 11.7 psf, Great Lakes `W/S` ≈ 9.6 psf,
Stevens Akro `W/S` ≈ 13.0 psf. No-flap stall requirement (`CLmax` ≈ 1.2, `Vstall` ≈ 50 kt) drives the
wing-loading calculation via the standard stall equation (Eq. 5.6-family), giving `W/S` ≈ 10.2 psf.
Climb requirement (`Vy` ≈ 70 kt, desired rate of climb ≈ 1500 ft/min at sea level) and cruise
requirement (`Vc` ≈ 115 kt at 8000 ft) were each converted to a required `T/W` via the standard
climb/cruise `T/W` equations (Chapter 5), with cruise found to be the less restrictive of the two by
this point in the process.

### Initial sizing
*[Raymer, pp. 875-876]*

Empty-weight fraction estimated via the Chapter-3 statistical form (`We/W0 = A*W0^C`); crew+payload
weight `Wcrew+payload` = 220 lb. Mission-segment weight fractions computed for taxi/takeoff, climb,
cruise, and reserves/landing using the standard Breguet cruise-segment form (Eq. 3.13-family) with an
assumed `L/D` and propeller-aircraft SFC; combining these with the empty-weight-fraction relation and
iterating (per the standard Chapter-3 iteration scheme) gave a **first-pass sized takeoff weight
around `W0` ≈ 1200-1290 lb** depending on assumed constants — refined further below. The author's
"AC-SIZE" helper program (a small iterative sizing loop implementing exactly Chapter 3's method) was
used to converge this iteration rather than hand-iterating; sample program output (mission-segment
weight fractions ≈ 0.97, 0.985, 0.953, 0.995 for the four segments) is reproduced in the book,
converging toward `W0` ≈ 1290 lb for an *unconstrained* ("rubber," continuously variable) engine —
annotated in the book as **undesirable**: "this heavier `W0` would give reduced performance with a
fixed-size engine!"

### Fixed-engine sizing
*[Raymer, p. 877]*

Because the O-320-A2B is a fixed, off-the-shelf engine (not a scalable "rubber" engine), the sizing
iteration was re-run holding engine power fixed and instead **solving for the design range the fixed
engine/airframe combination can actually achieve** — the AC-SIZE program iterated to a converged
`W0` ≈ 1197-1198 lb (mission-segment weight fraction product ≈ 0.925 for this run), from which the
corresponding achievable range was back-calculated via the Breguet-equation approach, giving
**R ≈ 358 nm** for that configuration (used later to refine sizing and optimization techniques for
maximum performance and range).

### Layout, propulsion, and aerodynamics data
*[Raymer, pp. 878-882]*

Fuselage, wing, and tail dimensions were measured from the design layout drawing (fuselage width,
depth, and length; wing root/tip chords and MAC from Eqs. 7.6-7.9; tail chords/areas). Propeller
diameter was estimated from Eq. 10.3 (custom wood, 2-bladed, fixed-pitch propeller) as roughly
6 ft {1.8 m}, checked against tip-speed limits at 2700 rpm. Aerodynamics: maximum lift coefficient
built up from the wetted/exposed-area-weighted airfoil data (`CLmax` ≈ 1.2 clean, per Eq. 12.15-family);
parasitic drag built up component-by-component (fuselage, wing, tails) assuming fully turbulent flow,
each via the standard skin-friction-coefficient/form-factor/wetted-area method of Chapter 12
(Eqs. 12.24-12.30), summed with a landing-gear increment and a cockpit/canopy frontal-area increment,
plus leakage/protuberance and cooling-drag adjustments, to a **total zero-lift drag coefficient
`CD0` ≈ 0.0277** (clean cruise configuration) `[verify p. 881, exact buildup terms]`; induced drag via
Oswald efficiency `e` ≈ 0.87 and `K` ≈ 0.081 (Eq. 12.48-family). Propulsion: static/installed thrust
and propeller efficiency vs. velocity were built up from Chapter 13's propeller charts/equations
(`eta_p` ≈ 0.84 on-design, static thrust ≈ 750-790 lb range depending on assumed blade count/pitch
schedule), with a slipstream/propwash correction applied to the drag buildup (~5% thrust reduction
factor noted for the effective propwash-affected drag area) `[verify p. 884, exact correction value]`.

### Weights, stability and control, and spin recovery
*[Raymer, pp. 885-892]*

A component weight buildup (Cessna-method-style statistical equations, cross-checked against actual
comparable-aircraft data) produced an itemized weight/CG table for fuselage, wing, horizontal tail,
vertical tail, engine, landing gear, fuel system, flight controls, electrical, avionics, and
furnishings, summing to an empty weight in the roughly 880-940 lb range (consistent with the sizing
iterations above) with a most-aft empty-weight c.g. around 63-65 in. aft of the datum
`[verify pp. 886-887, exact per-component values — handwritten table heavily OCR-garbled]`. Stability
and control analysis (Chapter 16 methods) found a power-off neutral point well aft of the most-aft
c.g., giving a **static margin on the order of 12-18% MAC** (both stick-fixed and stick-free), judged
appropriately stable for a "weekend pilot" aircraft (possibly too stable/sluggish for serious
aerobatic competition, per the author's own note). A trim analysis (`Cm` vs. `CL` for a family of
elevator deflections, Eq. 16.11-family) produced a trim plot; at the cruise `CL` ≈ 0.27 the required
elevator deflection for trim was found to be a modest few degrees `[verify p. 891, exact trim-plot
values]`. A spin-recovery check (Eq. 16.31-family, comparing rudder/vertical-tail area against the
fuselage-length-based recovery criterion at both forward and most-aft c.g.) found no problem in either
upright or inverted spins, with margin to spare on rudder area.

### Rate of climb, maximum speed, and turn performance
*[Raymer, pp. 893-895]*

Rate of climb was computed across a speed sweep at sea level and at 8000 ft (Eq. 17.17-family, using
the thrust-minus-drag excess power at each speed), producing best-rate-of-climb speed/altitude curves;
maximum level speed was found graphically by intersecting the thrust-available and drag curves at a
given altitude (`Vmax` ≈ 130 kt at 8000 ft, per the plotted intersection) `[verify p. 902, exact
intersection value]`. Sustained-turn performance was evaluated via the standard turn-rate/load-factor
relations (Chapter 17) to determine an achievable sustained-`g` boundary at combat-representative
speed/altitude, and cross-plotted against the climb and cruise constraints already established to
confirm no unexpected lower bound was being placed on aspect ratio by maneuvering requirements at very
low AR (the book notes only that induced drag would become excessive in maneuvers at very low AR,
motivating the eventual aspect-ratio choice below) `[verify p. 903, exact turn-rate numbers]`.

### Sizing matrix, aspect-ratio/wing-loading optimization, and final result
*[Raymer, pp. 904-905]*

A sizing matrix was built by varying wing loading and aspect ratio around the initial-sizing point
and resizing the aircraft (via the Chapter-19 carpet-plot-style method) at each combination, cross-plotted
against the performance constraint curves (climb, cruise/range, stall) established above.

**Result: the optimal aircraft for the given requirements occurs at `W/S` ≈ 10.2 psf and `AR` ≈ 2.9,
with a sized takeoff weight `W0` ≈ 1150 lb** — lower than the ~1200 lb "as-drawn" baseline used
through the hand-calculation walkthrough above. The next step in the design process (not carried
further in this example) would be to redraw the aircraft at this optimized point and re-analyze it in
detail.

## §24.3 Lightweight Supercruise Fighter (DR-3)
*[Raymer, p. 905]*

**Concept.** A lightweight F-16-successor fighter concept — a cheap "low-end" complement to a
high-end fighter (as the F-16 complemented the F-15) — updated with newer technology and a sustained
supersonic-cruise ("supercruise") capability on dry (non-afterburning) power, plus a short
takeoff/landing requirement. Stealth shaping/treatments were deliberately *not* applied ("to avoid
unpleasant conversations with government personnel") but would likely be present on a real aircraft
for this mission. The design incorporates one deliberately speculative, unproven technology: a
**variable-dihedral vertical tail** (author-patented concept, Ref. [170]) that converts from a
V-tail arrangement subsonically to upright twin verticals supersonically, intended to control the
rearward shift of the aerodynamic center through the transonic region, reducing trim drag and
enhancing supersonic maneuverability (per prior Rockwell studies) — at an admitted weight penalty
that makes its net benefit marginal. It is included specifically to illustrate how a designer
evaluates a genuinely new technology with no prior fleet experience to draw on: estimate its impact
on aerodynamics/weights/propulsion as best as possible, size and optimize the resulting aircraft, and
compare against a non-technology baseline to judge whether the idea is worth pursuing.

### DR-3 design requirements
*[Raymer, p. 906]*

- Role: F-16 replacement, advanced-technology lightweight fighter, air-to-air emphasis, single-seat.
- Engine: one advanced-technology "rubber" (variably sized during iteration) engine, modeled as an
  advanced derivative of the Pratt & Whitney F110-class engine family with an assumed SFC reduction
  vs. current production engines.
- **Design mission** (air-to-air): warm-up/taxi/takeoff, accelerate, climb, cruise-out, dash out
  (Mach 1.6 supercruise segment) [descend], combat (2 min at Mach 1.6, plus sustained-turn combat
  segments), dash back, cruise back, loiter (20 min), descend, land, with standard fuel reserves.
  Combat radius ≈ 500 nm baseline (used as the trade-study reference point later).
- Weapons load: 2 advanced air-to-air missiles (200 lb each, 5 in. x 92 in.) plus an advanced gun with
  340 rounds of ammunition (440 lb); crew (pilot) weight 220 lb (later refined to 226 lb).
- **Performance requirements:**
  - Takeoff and landing ground roll: ≤1000 ft each.
  - Approach speed: ≤130 kt.
  - Maximum Mach: 1.8 (afterburner), 1.4 (dry/military power, i.e. true supercruise).
  - Acceleration: Mach 0.8 to 1.4 in ≤50 s at 35,000 ft.
  - Specific excess power `Ps` = 0 at Mach 0.9 and at Mach 1.4, both at 30,000 ft.
  - Sustained turn: `n` ≥ 5-6 g (approximate, per the sustained-turn sizing constraint derivation,
    combined with the `Ps` constraints above) at combat conditions.

### Fig 24.2 — DR-3 design-requirements/mission-profile sketch sheet
*[Raymer, Fig. 24.2 (unnumbered design sheet), p. 906]* — Hand-drawn mission-profile diagram (the
air-to-air design mission listed above) plus the performance-requirements callouts. No plotted
numeric data beyond the requirement values already listed (hand sketch).

### Concept sketches and initial layout
*[Raymer, pp. 907-909]*

Two initial concept sketches were considered: a conventional twin-tail layout and the variable-dihedral
("V-tail-to-upright") layout ultimately carried forward, using a 2-D vectoring/thrust-reversing nozzle
(shortening required landing distance and providing pitch-vectoring benefit at low speed) — the
thrust-reversing feature was adopted specifically to relax the otherwise-restrictive landing-distance
requirement.

Wing geometry cross-checked against the F-16 for reasonableness: initial aspect ratio `A` ≈ 3.8 (from
`A x (t/c) ≈ 1.11`, cross-checked against F-16 precedent); leading-edge sweep initially 40 deg
(transonic/pitch-up considerations, per Chapter 4's sweep-selection guidance for this class), taper
ratio `lambda` ≈ 0.25-0.30, dihedral ≈ 0 deg; initial airfoil ≈ 64A-005 (thin, for transonic/supersonic
performance). Initial wing loading from the stall requirement (`Vstall` from the 130-kt approach-speed
target with an assumed approach-speed margin) gave `W/S` ≈ 22.5-22.8 psf as the *stall-driven* floor,
flagged in the book as "much too low" for a supersonic fighter (a fighter will handle this constraint
initially and use thrust reversing to relax the landing-field requirement rather than sizing the wing
to it).

### T/W sizing from the constraint set
*[Raymer, pp. 909-911]*

Takeoff `T/W` derived from the required takeoff parameter (`TOP`) and ground-roll requirement
(Eq. 5.9-family): `T/W` ≈ 104 (in the TOP-based intermediate units), converted through the takeoff
wing-loading relation. Supersonic-cruise `T/W` at Mach 0.9/35,000 ft was derived from the drag polar
(`CD0` ≈ 0.011 estimated from wetted-area-ratio methods, Oswald `e` ≈ 0.86 via the supersonic-drag
form, Eq. 12.30-family) giving an optimum cruise wing loading `(W/S)_cruise` ≈ 69.6 psf. A sustained-turn
`T/W` was derived at Mach 0.9/30,000 ft (assumed `n` ≈ 5, `CL` reduced for the high-`n` turning
condition) giving `(T/W)_combat` ≈ 0.78-0.88 depending on assumed conditions, and a companion
wing-loading requirement from the same turning condition of `(W/S)_combat` ≈ 44-62 psf range, explored
as part of the eventual carpet-plot trade.

### Initial sizing (mission-segment weight fractions and SFC estimates)
*[Raymer, pp. 912-916]*

Cruise `L/D` ≈ 10.7 at Mach 0.9/35,000 ft (`W/S` ≈ 213 psf assumed for this segment's midpoint weight,
`CD0`/`CL` combination per the drag buildup). SFC was estimated by starting from a baseline
early-2000s-technology engine SFC at Mach 0.9/36,000 ft (`C` ≈ 1.01), adjusting +10% for afterburner
installation losses, then discounting -20% for assumed advanced-technology improvement, giving a design
dry-cruise `C` ≈ 0.94; a similar chain of adjustments (baseline, +10% installation, -20% advanced
technology) was applied at other flight conditions (e.g. dash at Mach 1.4/35,000 ft giving `C` ≈ 1.2 at
that condition, further adjusted to `C` ≈ 0.975 with the same technology factors applied for a specific
sub-segment). Mission-segment weight fractions were computed segment-by-segment (warm-up/takeoff
`W1/W0` ≈ 0.98 [Eq. 6.29-family reference value], acceleration segments via the energy-height method
(Eq. 17.something) giving fractions in the 0.977-0.994 range per accelerate/dash/combat/loiter segment,
loiter at 20 min via the standard endurance form giving a fraction ≈ 0.9x). The overall product of
mission-segment weight fractions was computed as **≈0.7586** (later refined to other values as the
design iterated), and a **total fuel fraction ≈ 0.256** (later ≈0.24, depending on iteration) was
derived from `1 - (product of fractions)`.

### Sizing iteration (AC-SIZE program)
*[Raymer, p. 916]*

Using the AC-SIZE helper program (same tool as the DR-1 example) with `W0`(drawn) = 20,000 lb,
`We`(drawn) = 12,841 lb, crew+payload weight = 1,460 lb, and a product-of-mission-segment-weight-fractions
of 0.7586, the sizing iteration **converged to a takeoff gross weight `W0` ≈ 16,464-16,480 lb**
(successive iterations shown converging from 19,419 lb down through the 16,400s). This converged value
(**W0 = 16,480 lb** is used as the "baseline" configuration carried into the detailed RDS-Student
analysis below).

### Layout data, fuel tankage, and geometry
*[Raymer, pp. 917-919]*

Layout dimensions were measured from the design drawing: wing reference area `S` ≈ 294 ft² (matching
the later RDS aerodynamic-input file), span `b` ≈ 32.4 ft, root chord `Croot` ≈ 14.7 ft, tip chord
`Ctip` ≈ 3.7 ft, MAC and spanwise MAC location computed via Eqs. 7.7-7.9. Fuel tankage: wing tanks (aft
and forward), fuselage tanks (forward and aft of the wing box) sized from the drawing at 85% (wing)
and 83% (fuselage) usable-volume fractions respectively, summing (with the required design fuel
weight ≈ 4780-4980 lb range across iterations) to a fuel-volume-driven internal-tank layout confirmed
to fit within the drawn envelope. Landing gear: main-gear tire diameter/width and nose-gear
sizing were estimated from the statistical tire-sizing equations of Chapter 11 based on the static
per-strut load fractions (main gear carrying the bulk of `W0`, nose gear ≈ a smaller design-load
fraction) `[verify p. 918-919, exact gear dimensions — heavily OCR-garbled]`.

### Wetted areas
*[Raymer, p. 921]*

Wing exposed reference area `Sexp` ≈ 215 ft² (per the later RDS aerodynamic-input listing);
wing/tail/fuselage/canopy wetted areas were each measured off the layout drawing and tabulated by
fuselage station for the area-ruling/wave-drag analysis (per the fuselage-station cross-sectional-area
perimeter measurements recorded in the book's layout-data table).

### Design analysis (RDS-Student computer analysis)
*[Raymer, p. 922]*

From this point, the DR-3's dimensions/areas from the layout were carried into the author's
RDS-Student program (bundled with the book via AIAA) for the detailed aerodynamics, weights,
propulsion, sizing, performance, and cost analysis, plus a `T/W`-`W/S` carpet-plot optimization — this
could equally have been done by hand as in the DR-1 example, but "life is too short" for the volume of
iteration involved; the author again recommends students demonstrate pocket-calculator competence
before being allowed to use RDS or any similarly "canned" tool.

### Aerodynamic lift and drag inputs/results
*[Raymer, pp. 922-925]*

Inputs to the RDS aerodynamics module (file `DR3.DAA`) included surface areas/geometry for wing,
horizontal tail, fuselage, canopy, and boundary-layer diverter. Skin-friction analysis assumed fully
turbulent flow over camouflage paint. Missile drag (`D/q`) was taken from AIM-9-type data (Fig. 12.25);
a constant cannon-port `D/q` = 0.2 was assumed from Mach 0 to 2; leakage/protuberance drag was taken as
6%. For wave drag: total max cross-section area ≈ 20.9 ft² {1.94 m²}, less 3.83 ft² {0.36 m²} inlet
capture area, giving a net `Amax` ≈ 17.07 ft² {1.58 m²}; supersonic wave-drag empirical factor
`Ewd` = 2.0 (typical of a design with some, but not extreme, attention to area ruling).

**Maximum lift**: base 64-series-airfoil `CLmax` ≈ 0.82, `delta-y` ≈ 1.28 (Table 12.1); trailing-edge
plain-flap lift adjustment ≈ 0.9 and leading-edge-flap adjustment ≈ 0.3 (Table 12.2), with hinge-line
angles of 10 deg (LE) and 39 deg (TE) giving, via Eq. (12.21), a `delta-CLmax` ≈ 0.82 — an adjusted
clean-wing `CLmax` ≈ 1.64 (with automatic maneuver flaps). For landing, `CLmax` ≈ 1.8 assumed based on
modern-fighter leading-edge-flap data.

### Table — DR-3 Aerodynamic Inputs (file DR3.DAA), selected values
*[Raymer, RDS aerodynamic-input listing, pp. 923-924]*

| Parameter | fps | mks |
|---|---|---|
| Max Mach | 2.0 | 2.0 |
| Max altitude | 50,000 ft | 15,240 m |
| k (roughness)/10^5 ft | 3.33 | 1.015 |
| % leakage & protuberance | 6.0 | 6.0 |
| Amax (aircraft, net) | 17.07 ft² | 1.586 m² |
| Effective length | 45.2 ft | 13.777 m |
| Ewd | 2.0 | 2.0 |
| Wing Sref | 294.0 ft² | 27.313 m² |
| Wing Sexp | 215.0 ft² | 19.974 m² |
| Wing AR true / effective | 3.5 / 3.5 | 3.5 / 3.5 |
| Wing taper (lambda) | 0.25 | 0.25 |
| Wing LE sweep | 38.0 deg | 38.0 deg |
| Wing t/c average | 0.06 | 0.06 |
| Wing CLmax (airfoil) | 1.64 | 1.64 |
| Horiz. tail S / Sexp | 92.0 / 92.0 ft² | 8.547 / 8.547 m² |
| Horiz. tail AR / taper / sweep | 4.0 / 0.34 / 30.0 deg | 4.0 / 0.34 / 30.0 deg |
| Horiz. tail dihedral | 28.4 deg | 28.4 deg |
| Fuselage Swet / length / eff. diam | 588.0 ft² / 45.2 ft / 5.5 ft | 54.627 m² / 13.777 m / 1.676 m |
| Canopy/fairing Swet / length / eff. diam | 39.0 ft² / 13.9 ft / 2.0 ft | 3.623 m² / 4.237 m / 0.610 m |
| BL diverter (2 wedges) l / d / thickness | 4.2 / 2.83 / 0.33 ft | 1.28 / 0.863 / 0.101 m |

Misc `D/q` vs. Mach (missile, fps units): 0.12 ft² at M0-0.98, rising to 0.27-0.30 ft² by M1.1-2.0
(read from the RDS input table). Cannon-port `D/q`: constant 0.2 ft² across M0-2.0.

Sample RDS aerodynamic *results* (file `DR3.DAA`) at two conditions: at 30,000 ft/Mach 0.40, component
Reynolds numbers ranged from ~5.9M (wing) to ~51.6M (fuselage), skin-friction coefficients ~0.0016-0.0032,
form factors ~1.13-1.67; at 40,000 ft/Mach 1.60, Reynolds numbers ranged ~12.9M-138.4M with all form
factors reduced to 1.000 (supersonic flow) `[verify pp. 924-925, exact per-component Cf values]`.

### DR-3 weight statement (baseline, `W0` = 16,480 lb)
*[Raymer, Fighter/Attack Group Weight Statement, pp. 934-935]*

| Group | Weight (lb) |
|---|---|
| **Structures Group** | **4526.2** |
| Wing | 1459.4 |
| Horizontal Tail | 280.4 |
| Vertical Tail | 0.0 (variable-dihedral tail folded into horiz. tail item) |
| Fuselage | 1574.0 |
| Main Landing Gear | 631.5 |
| Nose Landing Gear | 171.1 |
| Engine Mounts | 39.1 |
| Firewall | 58.8 |
| Engine Section | 21.0 |
| Air Induction | 291.1 |
| **Propulsion Group** | **2354.3** |
| Engine(s) | 1517.0 |
| Tailpipe | 0.0 |
| Engine Cooling | 172.0 |
| Oil Cooling | 37.8 |
| Engine Controls | 20.0 |
| Starter | 39.5 |
| Fuel System | 568.0 |
| **Equipment Group** | **3066.7** |
| Flight Controls | 655.7 |
| Instruments | 122.8 |
| Hydraulics | 171.7 |
| Electrical | 713.2 |
| Avionics | 989.8 |
| Furnishings | 217.6 |
| Air Conditioning | 190.7 |
| Handling Gear | 5.3 |
| **Misc Empty Weight** | **1000.0** |
| **Total Weight Empty** | **10,947.2** |
| **Useful Load Group** | **5532.8** |
| Crew | 220.0 |
| Fuel | 4422.8 |
| Oil | 50.0 |
| Payload | 840.0 |
| Passengers | 0.0 |
| Misc Useful Load | 0.0 |
| **Takeoff Gross Weight** | **16,480.0** |

C.g. travel: empty c.g. = 23.8% MAC; loaded-no-fuel c.g. = 23.4% MAC; gross-weight c.g. = 23.1% MAC.

### Takeoff and landing performance (baseline)
*[Raymer, pp. 949-950]*

At `W0` = 16,480 lb {7475.2 kg}: operating weight ratio `Wi/W0` = 1.000 at brake release; takeoff
`T/W` = 0.980; start-of-takeoff thrust ≈ 16,150 lb {71.8 kN}; takeoff wing loading `W/S` ≈ 56.05 psf
{273.68 kg/m²}; `Vstall` ≈ 99.8 kt {184.8 km/h}; `Vtakeoff` ≈ 109.8 kt {203.3 km/h}; climb `CD0` ≈ 0.0289,
climb `K` ≈ 0.2609, climb `L/D` ≈ 3.07 (reflecting high-drag takeoff configuration with gear/flaps
down), climb angle ≈ 44.97 deg [likely a mislabeled/garbled OCR value for a much shallower climb
angle — flagged `[verify p. 949]`], `CL` ≈ 1.49. For landing, aircraft operating weight, `T/W` at
rollout, landing `W/S`, `Vstall`/`Vtouchdown`, approach angle, and approach `CD0`/`CL`/`K`/`L/D` were
similarly tabulated, with total landing distance components (approach, flare, free roll, braking)
summed against the FAR Part 25-style landing-distance requirement `[verify p. 950, most performance
figures on this page are OCR-illegible column headers without adjoining values]`.

### Range/weight trade study and carpet-plot optimization
*[Raymer, pp. 948-957]*

A trade study varied design range around the 500-nm baseline combat radius (roughly 300-700 nm swept)
and plotted resulting `W0`/`We` — a second trade study varied the assumed empty-weight-fraction sizing
exponent `C` by percentage change, both plotted against `W0`/`We` in lb-mass and kg (Figs., pp. 948-949).

A `T/W`-`W/S` carpet plot (Chapter 19 methodology) was built from 25 parametric resizing runs, sweeping
`W/S` across roughly 44.8-67.3 psf and `T/W` across roughly 0.784-1.176, each resized to convergence;
sized `W0` across this matrix ranged from about 12,500 lb (highest `W/S`, lowest `T/W`) to about
26,800 lb (lowest `W/S`, highest `T/W`). Performance-constraint curves (takeoff distance, landing
distance, `Ps` at `n`=5 at two flight conditions, `Ps` at `n`=1 at two flight conditions, and
acceleration time) were cross-plotted on the same `W/S`-`T/W` axes to bound the feasible region and
identify the minimum-`W0` feasible point.

### Table — DR-3 Multivariable Optimization Summary (Baseline vs. Best)
*[Raymer, RDS multivariable optimization output, p. 957]*

| Parameter | Baseline | Best (carpet-plot optimum) |
|---|---|---|
| T/W | 0.980 | 0.919 |
| W/S (psf) | 56.1 | 52.6 |
| Aspect Ratio | 3.500 | 2.800 |
| Sweep (deg) | 38.0 | 34.7 |
| Taper Ratio | 0.250 | 0.200 |
| Wing t/c | 0.060 | 0.068 |
| Sized W0 (lb) | 17,060.2 | 15,242.2 |
| Sized We (lb) | 11,257.5 | 9,925.5 |
| Sized Wf (lb) | 4,692.7 | 4,206.7 |

| Performance Constraint | Required | Baseline (achieved) | Best (achieved) |
|---|---|---|---|
| Takeoff distance (ft) | 1000.0 | 723.6 | 720.0 |
| Landing distance (ft) | 1000.0 | 990.4 | 960.4 |
| Ps @ n=5, condition 1 | 0.0 | 64.2 | 1.7 |
| Ps @ n=5, condition 2 | 0.0 | 156.6 | 62.0 |
| Ps @ n=1, condition 1 | 0.0 | 684.6 | 515.7 |
| Ps @ n=1, condition 2 | 0.0 | 71.5 | 0.1 |
| Acceleration time (s) | 50.0 | 42.2 | 49.4 |

The "Best" (multivariable-optimized) point converges to a sized `W0` of **15,242 lb {6914 kg}**, about
**2% less** than the optimum located via the plain `T/W`-`W/S` carpet plot alone (which itself
converged near 17,060 lb baseline / ~15,470-15,720 lb range across the matrix depending on the exact
`W/S`/`T/W` cell selected) — indicating the wing planform initially chosen by hand for the DR-3 using
this book's methods was already fairly close to optimal, with the further ~2% saving coming "for free"
from small additional refinements to wing geometry (lower AR, slightly less sweep, lower taper ratio,
slightly thicker section) found by the full multivariable search.

### What We've Learned
*[Raymer, p. 958]*

The chapter demonstrates applying the book's methods to produce a credible initial design layout for
two very different classes of aircraft, then analyze, optimize, and prepare each for the next
iteration of detailed layout ("the much-better Dash-Two").

---

*Chapter 24 complete (§§24.1-24.3). No numbered equations, tables, or figures original to this
chapter (it consists of two extended worked examples referencing equations/tables/figures from
earlier chapters, plus the book's own numbered design-example figures, most of which are hand-drawn
design sheets, layout drawings, and RDS-Student software input/output listings rather than
citable textbook figures in the usual sense — captured above as sketch/listing descriptions rather
than formally numbered `Fig. 24.N` citations, since the source PDF's scan does not carry clean,
individually numbered figure captions for this chapter's design-sheet and computer-printout pages).
Substantial OCR difficulty was encountered in the DR-1 (hand-written) design-notes section
(pp. 869-905) — numerous individual characters, subscripts, and handwritten numeric values could not
be read reliably from the scan; values reproduced above from that section were retained only where
legible or cross-checked against adjoining typeset (AC-SIZE program) output, and uncertain figures are
flagged inline with `[verify p. NNN]`. The DR-3 section (pp. 905-958), being mostly typeset
RDS-Student program listings, OCR'd far more cleanly and is reproduced with higher confidence
throughout.*
