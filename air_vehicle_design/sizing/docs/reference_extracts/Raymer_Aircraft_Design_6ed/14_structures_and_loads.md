# Chapter 14 — Structures and Loads

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 14
"Structures and Loads," printed pp. 491-558.

Covers load categories (V-n diagrams, maneuver/gust airloads, control-deflection, inertial,
powerplant, landing-gear loads), materials (metals, composites, sandwich), classical structural
analysis (section properties, tension/compression/buckling, truss analysis, beam shear/bending,
torsion), and an introduction to finite element analysis. All equations and tables preserved;
narrative condensed.

---

## §14.0 Introduction

Conceptual designers rarely perform detailed structural analysis themselves (a large company's
structures group does that) but do set the overall structural arrangement (wing box, major frames,
etc.) and must understand loads/structures well enough for weight estimation and for novel designs
(e.g. Rutan Voyager, needing a 0.20 empty-weight fraction and AR > 30 — verifying structural
feasibility was essential before freezing the concept). Loads estimation combines aerodynamics,
structures, and weights; modern CFD/panel codes and computerized wind-tunnel data reduction have
shrunk the classical "Loads Group," but errors here still directly cause overweight or failure.
Classical (largely superseded by FEM, §14.11) methods are presented for vocabulary and as a sanity
check on FEM results.

## §14.1 Loads Categories

### Table 14.1 — Aircraft Loads
*[Raymer, Table 14.1, p. 493]* — Four categories, each with example load types:

| Airloads | Landing | Inertia Loads | Other |
|---|---|---|---|
| Maneuver (vertical load factor, control deflection) | Vertical load factor, spin-up, spring-back, one wheel, crabbed, braking, arrested | Acceleration, rotation, taxi bumps, turning, powerplant thrust/torque/gyroscopic, prop/blade loss | Towing, jacking, pressurization, bird strike, buffet, hailstones (3/4 in.), fuel pressure, duct pressure, hammershock, seizure |
| Gust | | Dynamic (vibration, flutter) | Component interaction |
| | | | Catapult, aborted takeoff |

For each structural member, one load category dominates (Figs. 14.1-14.2: fighter and transport
critical-load maps — lifting surfaces are almost always critical under high-g maneuver). The **limit
(applied) load** is the largest load actually expected in service; the **design (ultimate) load** is
the highest the structure must survive without breaking. The **factor of safety** (limit → ultimate)
has been 1.5 since the 1930s (an Air Corps spec based on 24ST aluminum's ultimate/yield ratio, found
broadly suitable across materials since).

### Fig 14.1 — Typical fighter limit loads
*[Raymer, Fig. 14.1, p. 493]* — Labeled fighter side/plan view: nz=8g at M=0.9 called out at nose
boom, forward fuselage, canard, wing, tail; canopy birdstrike; inlet hammershock/waviness criteria;
intermediate fuselage/inboard wing buckling and fuel-pressure notes. No plotted numeric data
(reference load-map diagram).

### Fig 14.2 — L-1011 critical loads
*[Raymer, Fig. 14.2, p. 494]* — Transport side/plan view labeled with the dominant load case per
zone: positive/negative maneuver, positive/negative dynamic gust, landing and braking, taxi/jacking/
towing, yaw maneuver and lateral gust. No plotted numeric data (reference load-map diagram).

## §14.2 Air Loads

### §14.2.1 Maneuver Loads

Load factor `n` = maneuvering acceleration as a multiple of `g` (32.2 ft/s² = 9.8 m/s²). (Historical
note: the Wright Flyer was designed to Wilbur's stated "sustain about five times my weight," ≈5-g
ultimate ≈3.33-g limit — comparable to modern GA practice.) At low speed, max load factor is limited
by CLmax; at high speed, by an arbitrary design value (Table 14.2).

### Table 14.2 — Typical Limit Load Factors
*[Raymer, Table 14.2, p. 495]*

| Aircraft Type | n_positive | n_negative |
|---|---|---|
| General aviation, normal | 2.5 to 3.8 | −1 to −1.5 |
| General aviation, utility | 4.4 | −1.8 |
| General aviation, aerobatic | 6 | −3 |
| Homebuilt | 5 | −2 |
| Transport | 3 to 4 | −1 to −2 |
| Strategic bomber | 3 | −1 |
| Tactical bomber | 4 | −2 |
| Fighter | 6.5 to 9 | −3 to −6 |

### Fig 14.3 — V-n diagram (maneuver)
*[Raymer, Fig. 14.3, p. 496]* — Load factor `n` vs equivalent airspeed `Ve`: positive/negative stall
lines (calculated) meeting `n=1` at `Vstall`, "high AOA" point (slowest speed reaching max n without
stalling), flat lines at max positive/negative `n` extending to `Vcruise`/dive speed, `Vmax q`
labeled. The designer *selects* max n, min n, and dive speed; only the stall lines are calculated.

At high AOA the wing load vector can tilt forward of the body-vertical axis (Fig. 14.4), producing a
forward load component (a WWI-era wing-shedding failure mode); velocity-conversion methods are in
Appendix C. Subsonic dive speed is typically 40-50% above cruise; supersonic dive speed is typically
≈Mach 0.2 above max level speed (though many fighters can out-thrust their structural Mach limit).

### Fig 14.4 — Wing load direction at angle of attack
*[Raymer, Fig. 14.4, p. 496]* — Body-axis force decomposition: `N = L·cosα + D·sinα` (vertical),
`C = D·cosα − L·sinα` (chordwise), shown for low-α (near-vertical body-axis load) and high-α (load
tilted well forward of body-vertical) cases.

Loads are calculated in **equivalent airspeed** `Ve` (dynamic-pressure-based, constant with altitude
for a given q — convenient for structural work, though pilots must convert to true airspeed, and
compressibility corrections apply at high Mach to convert indicated → equivalent airspeed):

```
Ve = V_actual · sqrt(ρ/ρ0)                                              (14.1)
```
*[Raymer, Eq. (14.1), p. 497]*.

### §14.2.2 Gust Loads

Gust loads can exceed worst-case maneuver loads (transport near thunderstorms/clear-air turbulence:
−1.5 to +3.5g or more). An upward gust of velocity `U` (Fig. 14.5) changes angle of attack, lift, and
load factor:

```
Δα ≈ U/V                                                                (14.2)
ΔL = (1/2)·ρ·V·S·(CLα·U)                                                (14.3)
Δn = ΔL/W = ρ·U·V·CLα / (2·W/S)                                         (14.4)
```
*[Raymer, Eqs. (14.2)-(14.4), pp. 497-498]* — assumes instant, whole-aircraft gust encounter
(unrealistic). Real gusts ramp in cosine-like, reducing acceleration up to ~40%; a statistical gust
alleviation factor `K` is applied to the derived design gust velocity `Ude`:

```
Subsonic:    K = 0.88·µ / (5.3 + µ)                                     (14.5)
Supersonic:  K = µ^1.03 / (6.95 + µ^1.03)                               (14.6)
Mass ratio:  µ = 2·(W/S) / (ρ·g·c̄·CLα)                                  (14.7-14.8, combined)
```
*[Raymer, Eqs. (14.5)-(14.8), p. 498]* — cited to Ref. [94]; smaller/lighter aircraft encounter a gust
"more rapidly," hence the mass-ratio dependence. `Ude` is itself back-derived from flight-test
acceleration data (hence "derived equivalent gust velocity"). Historical standard vertical `Ude` = 30
ft/s {9.1 m/s} (± , giving ≈3g positive for most aircraft) up to cruise speed, dropping linearly to 15
ft/s {4.6 m/s} at dive speed, for normal/utility/aerobatic civil types; transport-category `Ude` is
altitude-dependent (Fig. 14.6).

### Fig 14.6 — Derived equivalent gust velocities (transport)
*[Raymer, Fig. 14.6, p. 499]* — `Ude` (0-60 ft/s {0-20 m/s}) vs altitude (0-50,000 ft {0-15,000 m}),
data from Ref. [95]; gust velocity requirement decreases with altitude. *(read from plot,
approximate)*: sea level → ~50 ft/s {~15 m/s}; 20,000 ft → ~38 ft/s {~12 m/s}; 40,000 ft → ~25 ft/s
{~8 m/s}; 50,000 ft → ~20 ft/s {~6 m/s}.

Counterintuitively, gust load factor (Eq. 14.4) *increases* for a lighter aircraft (the lift increment
ΔL is weight-independent, so a lighter aircraft sees more acceleration for the same ΔL/stress). Wing
aeroelastic bending (aft-swept wings twist nose-down under load, reducing outboard α and moving the
lift distribution inboard) cuts gust load factor roughly 15% versus an unswept wing.

### Fig 14.7 — V-n diagram (gust)
*[Raymer, Fig. 14.7, p. 500]* — Gust-derived `n` vs `V`, straight-line construction between `Vdive`,
`Vcruise`, and `Vg` (gust reference speed), assuming 1-g level flight at gust encounter.

### Fig 14.8 — Combined V-n diagram
*[Raymer, Fig. 14.8, p. 500]* — Overlay of Figs. 14.3 and 14.7, taking the more critical (larger) `n`
at each speed; a dashed line shows raising the assumed maneuver limit load where gust loads exceed it.
Remember: structural design load is 1.5× this combined limit envelope. This simplified method is less
complete than large-company power-spectral-density gust methods (Ref. [96]) but is a solid
introduction/initial-analysis tool.

### §14.2.3 Air Loads on Lifting Surfaces

Compute actual load distributions only at the V-n diagram's critical speeds (high-AOA, max-q, and any
gust-critical speed). First find trimmed tail lift (Chapter 16 methods, or a simplified moment
summation about the c.g.) at the given load factor, then the wing/tail spanwise and chordwise load
distributions (Fig. 14.9, from wind-tunnel/panel-code data if available, else classical approximation
for initial/light-aircraft design).

### Fig 14.9 — Wing lift distribution
*[Raymer, Fig. 14.9, p. 501]* — 3-D sketch: spanwise lift distribution (bell-shaped along span) and
chordwise lift distribution (along chord) shown together. No plotted numeric data (conceptual
diagram).

**Schrenk's approximation** (Ref. [97]): spanwise load on an untwisted wing/tail ≈ average of the
actual planform's chord distribution and an elliptical distribution of the same span/area (Fig.
14.10); total area under the curve must sum to required total lift.

```
Trapezoidal chord:  c(y) = croot · [1 − (1−λ)·2y/b]                     (14.9-14.10, combined form)
Elliptical chord:   c(y) = (4S/(π·b)) · sqrt(1 − (2y/b)²)                (14.11)
```
*[Raymer, Eqs. (14.9)-(14.11), p. 502]* — load assumed to continue to the aircraft centerline (good
subsonic assumption); divide lift by cos(dihedral) for perpendicular structural load if dihedral is
substantial.

### Fig 14.10 — Schrenk's approximation
*[Raymer, Fig. 14.10, p. 502]* — Spanwise lift-load sketch showing the actual (trapezoidal) planform
load, an elliptical-planform load of equal span/area, and the Schrenk approximation as their average.
No further numeric data (illustrative construction).

For a twisted wing, split into the "basic load" (spanwise distribution at zero net lift — inboard
upload/outboard download typically, from section lift-curve-slope × local twist angle relative to the
wing's no-lift angle, found by trial and error [Ref. 98]) plus the "additional load" (Schrenk-type
distribution for the net-lift portion). Schrenk's method does not apply to highly swept, vortex-flow
planforms (need CFD/wind tunnel instead).

Drag-load spanwise distribution (relevant for fabric-covered aircraft with internal "drag wires"):
rough approximation — 95% of average drag loading from root to 80% span, 120% of average from 80%
span to tip (best obtained from wind-tunnel/panel data). Component aerodynamic interaction can add
loads too — e.g. canard downwash reduces inboard wing α, shifting the wing's lift distribution
outboard (more bending stress); LEX/strake vortices can cause vibrational fatigue on downstream
surfaces (the F-18's vertical-tail fatigue problem is a cited example), similar to propwash effects.

Once spanwise load is known, bending stress follows (§14.6 below); torsional stress uses the airfoil
moment coefficient applied strip-wise and summed tip-to-root (or from wind-tunnel chordwise pressure
data directly, Fig. 14.11).

### Fig 14.11 — Airfoil chordwise pressures
*[Raymer, Fig. 14.11, p. 504]* — Chordwise pressure-distribution sketches for a NACA 4412 airfoil at
several angles of attack (including α = −7 deg). No further plotted numeric data (illustrative
pressure-distribution figure).

### §14.2.4 Airloads Due to Control Deflection

Elevator deflection changes α/load factor; rudder deflection can impose large yaw loads; any control
deflection adds direct load on its surface (and the adjacent fixed structure). **Maneuver speed
(pull-up speed) `Vp`** is the max speed for full control deflection without airframe/control damage
(usually below max level cruise speed `VH`):

```
Vp = Vs · sqrt(Kp · n_limit)                                             (14.12, form as printed)
Kp = 0.15 + 5400/(W + 3300)                                             (14.13)
```
*[Raymer, Eqs. (14.12)-(14.13), p. 504]* — `W` in lb (convert kg × 2.2 first if using SI); `Vs` = stall
speed with high-lift devices deployed; clamp `Kp` to [0.5, 1.0] (GA aircraft typically ≤0.9). Note:
Eq. (14.12) as printed in the OCR pass shows only `Kp` isolated with a following expression that did
not fully resolve — the standard form (also used elsewhere in the literature) is `Vp = Vs·sqrt(n_limit
· Kp)`; `[verify p. 504]` the exact bracketed relationship between `Vp`, `Vs`, `n`, and `Kp` against
the printed page if implementing directly.

At `Vp`, a Chapter-16 control analysis gives the α/sideslip from max control deflection, hence the
resulting airload. Maximum-aileron-deflection-at-max-load-factor ("rolling pull-up") is frequently
wing-structure-critical. Flap speed `Vf` (max speed with flaps down) ≈ 2× flaps-down stall speed.
Control deflection typically changes section CL by ≈0.8-1.1 at 25-deg deflection (Chapter 16 methods);
absent better data, airfoil moment-coefficient change ≈ −0.01 per degree of deflection, concentrated
at the hinge line (loads the fixed surface too).

Pilot-strength control-force limits (manual systems): stick-controlled — elevator 167 lb {0.7 kN},
aileron 67 lb {0.3 kN}; wheel-controlled — elevator 200 lb {0.9 kN}, aileron 53×(wheel diameter) in-lb
{0.1×diameter N·m}; rudder 200 lb {0.9 kN} (both types). Tail groups also carry arbitrary design loads
at maneuver speed based on normal-force coefficients `Cn` (spanwise load ∝ chord): horizontal tail
`Cn` = −0.55 (down) / +0.35 (up); vertical tail `Cn` = 0.45.

## §14.3 Inertial Loads

`F = m·a` (Newton) applied to every mass item at the aircraft's load factor `n` (weight × n) —
including the wing structure's own weight, which adds torsional load beyond the aerodynamic torsion.
Rotational inertial loads: centrifugal (e.g. wing-tip-tank outward load factor = distance-from-c.g. ×
rotation-rate² / g, in a high roll-rate maneuver) and tangential (distance-from-c.g. × angular
acceleration / g, from a gust/elevator snap/nose-wheel impact). Vibration/flutter loads are a special
acceleration case beyond this book's scope — proper design should avoid flutter and minimize
vibration.

## §14.4 Powerplant Loads

Engine mounts must withstand thrust, stopped/windmilling drag, vertical weight×load-factor, a lateral
load ≈1/3 of the vertical design load, and gyroscopic loads from rotating machinery/propeller at max
pitch/yaw rate. Propeller engine mounts must also withstand engine torque × a cylinder-count-based
safety factor (fewer cylinders → jerkier single-cylinder-malfunction torque spike): 2 cylinders → 4.0;
3 → 3.0; 4 → 2.0; 5+ → 1.33 (multiply by max normal-operation torque for design torque). Jet engines
must consider inlet-duct air loads (B-70 at M3/65,000 ft {20,000 m}: 4,320 psf {207 kN/m²}, 30× ambient
pressure); "hammershock" (forward-propagating pressure surge from a compressor stall) and "duct buzz"
(oscillating shock bounce) are especially severe transient cases that can overstress structure/cause
thrust loss.

## §14.5 Landing-Gear Loads

Vertical gear load factor is a *design choice* (e.g. `Ngear = 3`, Chapter 11 Table 11.5) used with the
worst-case sink rate to size shock-strut stroke; structural analysis then assumes the gear limits
vertical load to that chosen factor. Certification drop tests: drop height 9.2-18.7 in. {23-48 cm},
typically ≈3.6×√(wing loading). Other landing scenarios to check: extreme tail-down, one-wheel, and
crabbed landings. Non-rotating tires touching down generate a rearward friction ("spin-up") force
(up to ~half the vertical touchdown force) as they spin up, followed by an overshooting forward
"spring-back" deflection load (≥ the spin-up load) as the strut relaxes. Braking load: assume braking
coefficient ≈0.8 rearward at the tire contact patch; aircraft deceleration (from mass and braked-tire
weight fraction) is applied as an inertial reaction throughout the airframe. Gear-retraction load is
usually based on airloads plus an assumed 2-g turn; taxi/turning loads matter mainly for detail design
of the gear/supporting structure.

## §14.6 Structures Fundamentals

Timoshenko's *Strength of Materials* (1930) [Ref. 99]: external load displaces a body's molecules
until internal ("stress") forces balance the external load — the resulting deformation is "strain."

### Fig 14.12 — Three basic structural loadings
*[Raymer, Fig. 14.12, p. 508]* — Tension, compression, and shear (illustrated via a riveted-joint
shear example) sketches with load arrows and cross-section area `A` labeled.

### Fig 14.13 — Other structural loadings
*[Raymer, Fig. 14.13, p. 509]* — Bending (combination of tension on one face, compression on the
other, from an end load on a beam), torsion (twisting moment resisted by tangential shear), and
thermal stress (constrained thermal expansion/contraction producing compression/tension). No further
plotted data (illustrative diagrams).

```
σ = P/A                                                                 (14.14)
ε = Δl/L                                                                (14.15)
E = σ/ε                                    [Young's modulus, Hooke's law region]   (14.16)
```
*[Raymer, Eqs. (14.14)-(14.16), p. 509]*.

### Fig 14.14 — Stress-strain diagram
*[Raymer, Fig. 14.14, p. 510]* — Typical aluminum-alloy σ-ε curve: linear "elastic range" up to the
"proportional limit," then "inelastic range" up to "yield stress" (arbitrarily defined at 0.002 in/in
{m/m} permanent set) and further to "ultimate stress" then fracture; a dashed line shows the permanent
set remaining after unloading past yield.

Above yield, Hooke's law fails; the "tangent modulus" `Et` (local σ-ε slope, from material-property
tables e.g. Ref. [100]) substitutes where needed but is not usable in Eq. (14.16) directly. Ultimate
stress for aluminum alloys ≈1.5× yield stress — hence a limit-load design that just reaches yield
stress reaches ultimate stress exactly at the 1.5× (design/ultimate) load factor; exceeding limit load
still permanently deforms some elements (requiring repair) even below ultimate. **Specific strength**
= ultimate stress ÷ density; **specific stiffness** = `E` ÷ density (both used for material comparison).

### Fig 14.15 — Composite material stress-strain
*[Raymer, Fig. 14.15, p. 511]* — σ (0-140 ksi) vs strain (0-0.12 in/in) for graphite/epoxy,
E-glass/epoxy, and aluminum 2024-T3: graphite/epoxy is stiffest (steepest slope) but fractures
abruptly near ~0.01-0.015 strain at high stress (~130+ ksi); E-glass/epoxy is more compliant but
strains further (~0.03-0.04) before fracture at lower stress (~60-70 ksi); aluminum shows the
classic yield-then-plastic-flow curve to ~55-60 ksi over a much larger strain range (~0.10+). *(read
from plot, approximate fracture points)*: graphite/epoxy ≈(0.012, 130 ksi); E-glass/epoxy ≈(0.035, 65
ksi); aluminum 2024-T3 fractures well beyond the plotted range shown, plateauing near 55-60 ksi.

Composites (fiberglass, graphite-epoxy) fracture abruptly near the proportional limit with no
built-in 1.5 safety margin, so a safety factor must be explicitly assumed for design: typically size
to a strain = 2/3 (1/1.5) of ultimate-stress strain (or to the proportional-limit stress if lower).

### Fig 14.16 — Poisson's ratio
*[Raymer, Fig. 14.16, p. 512]* — Exaggerated sketch of a tension bar necking laterally as it
elongates, illustrating the lateral/axial strain ratio (Poisson's ratio `µ`/`ν`, ≈0.3 steel, ≈0.33
aluminum/nonferrous).

### Fig 14.17 — Shear deformation
*[Raymer, Fig. 14.17, p. 512]* — Rivet-like bar under offset up/down loads, showing the resulting
angular ("kinked") shear deformation `γ` and the balancing horizontal shear forces needed for moment
equilibrium on a square element within the kinked region.

```
τ = P_shear/A                                                           (14.17)
G = τ/γ                                    [shear modulus / modulus of rigidity]   (14.18)
G = E / (2·(1+µ))                                                       (14.19)
```
*[Raymer, Eqs. (14.17)-(14.19), pp. 512-513]* — Eq. (14.19) relates `G` to `E` via Poisson's ratio
[Ref. 99].

## §14.7 Material Selection

Selection criteria beyond strength/stiffness/density: fracture toughness (energy to fracture, ≈area
under σ-ε curve — ductile materials absorb more), fatigue (cyclic-load failure well below ultimate
stress, from crack formation/propagation — probably the single most common aircraft material failure
mode; drivers include gust loads, landing impact, engine/prop vibration), creep (slow permanent
deformation under sustained stress, mainly a high-temperature issue but relevant at room temperature
for some titaniums/plastics/composites), corrosion (moisture, salt spray, fuel, oils, hydraulic fluid,
battery acid, exhaust, missile plumes, gun gases — galvanic corrosion between dissimilar materials
like aluminum and graphite-epoxy is a specific hazard; tension stress cracks the protective corrosion
layer, causing "stress corrosion" that can fracture at ~1/10 normal ultimate stress — avoid residual
tension stresses from manufacturing), operating temperature (firewalls/high-speed skins need
high-temperature materials; Figs. 14.18-14.19 give supersonic skin temperatures), producibility/
repairability/cost/availability (better material properties generally mean harder fabrication —
e.g. SR-71 titanium forming, composite fabrication/repair difficulty; titanium/composites cost more
than wood/steel/standard aluminum; titanium and high-temp alloy source materials can carry geopolitical
supply risk, as can aircraft-quality wood today).

### Fig 14.18 — Supersonic skin temperatures (°F)
*[Raymer, Fig. 14.18, p. 514]* — Labeled temperature callouts on B-70 (Mach 3) and Concorde (Mach 2.2)
silhouettes: B-70 ≈600°F nose/leading edges tapering to ≈240-250°F aft; Concorde ≈250°F nose/leading
edges, cooler elsewhere (≈240-250°F regions labeled). Specific callout values: 675°F (B-70, hottest
point noted in text), 600°F, 540°F, 240-250°F (various stations); Concorde 250°F.

```
Tstagnation = T_ambient · (1 + 0.2·M²)          [T in °R or K]           (14.20)
```
*[Raymer, Eq. (14.20), p. 515]* — theoretical maximum aerodynamic-heating temperature; actual skin
temperature depends on airflow/surface finish/atmosphere and is estimated via Fig. 14.19.

### Fig 14.19 — Skin-temperature estimate (average values, not leading edge)
*[Raymer, Fig. 14.19, p. 515]* — Average skin temperature rise (0-100°F) vs Mach (0.5-5.0), roughly
parabolic. *(read from plot, approximate)*: M1.0→~15°F; M2.0→~55°F; M3.0→~90°F (near stagnation-temp
scale); continues rising toward M5.

### Figs 14.20-14.22 — X-29 (Rockwell proposal) material selection
*[Raymer, Figs. 14.20-14.22, pp. 516-517]* — Three labeled structural cutaways (forebody, aft
fuselage, wing) showing aluminum bulkheads/honeycomb access doors/steel tube, an aft-fuselage heat
shield and skin stack (0.050 Al external skin, 0.020 CRES heat shield, 0.070 Al skin, 0.030 stainless,
inner skin), and wing skins (graphite composite, Al/fiberglass leading edge). No plotted numeric data
(illustrative material-callout diagrams); noted as typical of modern fighter design practice, with the
caveat that composite (rather than metallic) honeycomb panels might now be preferred.

### §14.7.1 Wood

Early primary structural material (Wright Brothers used spruce); good strength/weight, easy to
fabricate/repair, directionally anisotropic like a composite (good natural bending-beam spar
material). Hughes H-4 Hercules used molded plywood-like composite-style construction (multi-ply, resin
glue, cure under pressure, varied ply orientation). Disadvantages: moisture sensitivity, rot/insect
susceptibility, requires climate control and craftsman-level skill (natural material variability).
Today mainly homebuilt/low-volume niche use, increasingly displaced there too by composites.

### §14.7.2 Aluminum

Still the dominant aircraft material: excellent strength/weight, formable, moderate cost, corrosion
-resistant. Most common alloy: **2024** ("duralumin," 93.5% Al, 4.4% Cu, 1.5% Mn, 0.6% Mg). High
-strength: **7075** (Zn/Mg/Cu alloy, often clad with pure Al for corrosion resistance; newer 7050/7010
improve corrosion resistance/strength). Stronger tempers are generally more brittle. **Aluminum
-lithium** alloys approach composite weight savings with standard aluminum fabrication techniques
(Eurofighter Typhoon wing/tail leading edges).

### §14.7.3 Steel

Early advance: welded mild-steel-tube fuselages (Fokker) replaced maintenance-heavy wire-braced wood
(Sopwith Camel). Today used where high strength/fatigue resistance or high temperature is needed
(wing-attachment fittings, firewalls, engine mounts); XB-70 used largely brazed steel honeycomb
(strong at high temperature, very hard to fabricate). Steel = iron + carbon (~1% typical; more carbon
→ more strength/brittleness) plus alloying elements (Cr, Mo, Ni, Co) for specific properties;
stainless variants add corrosion resistance. Heat treatment (raise to 1400-1600°F {760-870°C}, then
control cooling rate) sets grain structure/strength/ductility: slow furnace cooling ("annealing") →
coarse grain, ductile, weak (eases machining); air cooling ("normalizing") → stronger, still ductile
(standard post-weld treatment for tube structures); water/oil quench → "martensitic," very strong,
very brittle, needs tempering (reheat ≈1000°F {538°C}, 1+ hour) to regain ductility. Steel costs
roughly 1/6 of aluminum and is easy to fabricate.

### §14.7.4 Titanium

Better strength/weight and stiffness than aluminum, near-steel temperature capability, corrosion
resistant — but hard to form (>1000°F {538°C}, high forming stress) and embrittled by impurities
(hydrogen worst, then oxygen/nitrogen — needs post-form pickling or controlled heat treatment). Modern
military aircraft: 10-30% titanium by structural weight (fuselage-around-engine, complex fittings).
Costs 5-10× aluminum per pound (fabrication-cost premium has shrunk with modern technique).
SR-71 ≈93% titanium (Mach 3+ aero heating); XB-70 substantial forebody titanium; F-22 largely titanium
midbody (engine heat); also used for landing-gear beams, all-moving-tail spindles, and (being
galvanically compatible) substructure under graphite-epoxy skins. **Superplastic forming/diffusion
bonding (SPF/DB)**: titanium "flows" into a mold shape under heat/pressure while simultaneously
diffusion-bonding separate pieces into seamless joints — cost and complex-part-forming benefits
(Eurofighter canards use SPF/DB titanium instead of originally-planned composites, for producibility).

### §14.7.5 Magnesium

Good strength/weight, high-temperature tolerant, easily cast/forged/machined (engine mounts, wheels,
hinges, brackets, fuel tanks, even wings historically) — but corrosion-prone (needs protective finish)
and **flammable**. Mil-Specs discourage use except for significant weight savings; avoid in
hard-to-inspect areas or where the finish erodes (leading edges, engine exhaust exposure).

### §14.7.6 High-Temperature Nickel Alloys

Inconel, Rene 41, Hastelloy: hypersonic/reentry-suitable (Inconel: X-15; Rene 41: intended for X-20
Dynasoar; nickel-alloy honeycomb: F-117 stealth nozzles; Hastelloy: mainly engine parts). Substantially
heavier than aluminum/titanium and hard to form — the Space Shuttle instead used an aluminum structure
with heat-protective tiles (lighter, but with well-known tile-maintenance issues).

### §14.7.7 Composites

The biggest structural revolution since all-aluminum construction: direct graphite-epoxy substitution
for aluminum typically saves ~25% weight. F-22/F-18E-F ≈25% composite by structural weight; F-35
≈30%; Boeing 787 ≈50%.

### Fig 14.23 — Composite material types
*[Raymer, Fig. 14.23, p. 522]* — Two sketches: "whisker"/short-strand-reinforced (randomly oriented,
e.g. chopped fiberglass — isotropic like a metal) vs filament/fiber-reinforced (long continuous
fibers in a matrix — anisotropic, strongest along fiber direction, most common for aircraft primary
structure due to strength/weight and tailorability).

### Fig 14.24 — Composite ply tailoring
*[Raymer, Fig. 14.24, p. 522]* — Four fiber-orientation schemes: (a) 0° (all fibers along the
principal load axis — max strength that direction only); (b) 0°/90° (adds transverse strength); (c)
±45° (strength at 45° plus good shear strength along the principal axis — common for wing-box shear
webs and torque-carrying structure); (d) 0°/±45°/90° (combines b and c for tailored tension/
compression/shear strength in any direction via ply-count mix). An odd ply count reduces warpage
(as in plywood).

### Fig 14.25 — Composite production forms
*[Raymer, Fig. 14.25, p. 523]* — Loose/chopped batting (sprayed/pressed into a mold), unidirectional
tape (rolled, hand- or robot-laid, usually prepreg), unidirectional and bidirectional fabric
("broadgoods," prepreg-capable). Prepreg tape/fabric ≈0.005-0.01 in. {0.01-0.03 cm} per ply.
Filament-wound construction (filaments wound around a mandrel/plug) is used for shapes like missile
bodies/golf-club shafts.

Fiber/matrix material notes: fiberglass-epoxy — cheap, easy to form, used for nonstructural parts
(radomes, fairings) and homebuilders, but too flexible (low tensile E) for highly loaded structure.
Graphite-epoxy ("carbon fiber," British term) — the most common advanced composite, excellent
strength/weight, moldable, ~20× aluminum cost but low material waste in fabrication. Boron-epoxy —
4×+ graphite-epoxy cost, historically used for complete parts (F-111 horizontal tail, F-4 rudder), now
mainly a stiffening addition to graphite-epoxy (especially compression). Aramid (Kevlar) — low
compression strength but more gradual (less brittle) failure; graphite-aramid-epoxy hybrids add
ductility (Boeing 757 fairings/gear doors). Epoxy matrices are limited to ≈350°F {177°C} max (normally
<260°F {127°C}); higher-temperature polyimide resins (bismaleimide/BMI good to 350°F {177°C};
"polymide" to 600°F {315°C} but hard to process) extend this. Thermoset matrices cure irreversibly;
thermoplastic matrices (polyester, acrylic, polycarbonate, phenoxy, polyethersulfone) can be reheated/
reformed and resist damage better (F-117 graphite-thermoplastic vertical-tail retrofit near hot
nozzles; thermoplastics favored for doors/access panels/underside areas exposed to gear-kicked rocks).
Metal-matrix composites (Al or Ti matrix with boron/silicon-carbide/aramid fiber) are in development
for higher-temperature/strength needs. "Spread tow" (thin flat unidirectional untwisted fiber tow
aligned with load) is a newer technique improving mechanical properties/weight.

Composite drawbacks: poor tolerance of concentrated loads (needs load-spreading joints/fittings —
can erase the weight savings if a part has many cutouts/doors; wing-root attachment is a classic case,
e.g. Eurofighter's ~70%-composite structure still uses three large titanium root joints per wing box);
delamination (ply separation, worsened by voids/defects/impact — mitigated by out-of-plane stitching
or carbon-nanotube infusion, at extra cost); strength sensitivity to moisture, cure cycle, temperature/
UV exposure, fiber/matrix ratio (hard to control — every part differs slightly; manufacturing voids
are hard to detect, scrap rates can be high); damage susceptibility (internal damage can be invisible
externally, so composites must be designed to carry full limit load after such damage); and repair
difficulty (patch stiffness/strength mismatch risks either weak-patch failure or overly-stiff-patch
-induced fracture in adjoining structure — proper repair needs computer verification against the
original design). Composite ply-stack properties require tensor calculus (Ref. [104]) plus extensive
coupon testing (Refs. [105,106] give composite introductions). **"Ten-percent rule"** [Ref. 107] — a
quick strength approximation for 0°/90°/±45° ply layups: sum (plies × per-ply strength), but multiply
non-load-direction plies by 0.10; crude, initial-sizing only, never for final design.

### §14.7.8 Sandwich Construction

Two face sheets bonded to and separated by a core (Fig. 14.26) — not strictly a "material" but
structurally important. Face sheets: aluminum, fiberglass-epoxy, or graphite-epoxy typically; core:
aluminum or phenolic honeycomb (commercial/military), rigid foam (many homebuilts, foam-core +
fiberglass skins). 70% of the B-70 airframe was stainless-steel honeycomb sandwich, typically 2 in.
{5 cm} thick. Face sheets carry most bending tension/compression; core carries shear and
through-thickness compression. Joints/fittings are a problem here too (as with composites). Analysis
detail in Ref. [108].

### Fig 14.26 — Sandwich construction
*[Raymer, Fig. 14.26, p. 526]* — Cutaway sketch of two face sheets bonded to a honeycomb/foam core.
No plotted data (schematic).

### §14.7.9 Material Property Tables

### Table 14.3 — Typical Metal Properties (Room Temperature)
*[Raymer, Table 14.3, pp. 528-529]* — Density (lb/in³), temperature limit (°F), `Ftu` (ksi), `Fty`
(ksi, where given), `E` (10⁶ psi), `G` (10⁶ psi), comments, for: aircraft steel (5Cr-Mo-V), low-carbon
steel (AISI 1025), low-alloy steel (D6AC wrought), chrom-moly steel (AISI 4130, sheet/plate/tubing and
wrought forms), stainless steel (AM-350), stainless (PH15-7 Mo sheet/plate), aluminum 2017, clad 2024
(sheet/plate and extrusions), 6061-T6, clad 7178-T6 (sheet/plate and extrusions), clad 7075-T6 (sheet,
forgings, extrusions), magnesium (HK31A, HM21A), titanium (Ti-6Al-4V, Ti-13V-11Cr-3Al), and
high-temperature nickel alloys (Inconel X-750, Rene 41, Hastelloy B). Representative rows:

| Material | Density (lb/in³) | Temp limit (°F) | Ftu (ksi) | E (10⁶ psi) | G (10⁶ psi) | Comment |
|---|---|---|---|---|---|---|
| Aircraft steel (5Cr-Mo-V) | 0.281 | 1000 | 260 | 30 | 11 | Heat treat to 1850°F |
| Low carbon steel (AISI 1025) | 0.284 | 900 | 55 | 29 | 11 | Shop use only today |
| Chrom-moly steel (AISI 4130), wrought | 0.283 | 900 | 180 | 29 | 11 | Widely used, weldable |
| Stainless (AM-350) | 0.282 | 600 | 190 | 29 | 11 | B-70 honeycomb material |
| Clad 2024 (sheet/plate) | 0.100 | 250 | 61 | 10.7 | 4.0 | Widely used |
| 6061-T6 | 0.098 | 250 | 42 | 10.0 | 3.8 | Affordable (homebuilts) |
| Clad 7075-T6 (sheet) | 0.101 | 250 | 74-81 | 10.4 | 3.9 | High strength, not weldable, common in high-speed aircraft |
| Magnesium HK31A | 0.0674 | 700 | 34 | 6.5 | 2.4 | — |
| Titanium Ti-6Al-4V | 0.160 | 750 | 160 | 16.0 | 6.2 | SR-71 titanium |
| Titanium Ti-13V-11Cr-3Al | 0.174 | 600-1000 | 170 | 15.5 | — | X-20, very difficult to form |
| Inconel X-750 | 0.300 | 1200-1800 | 100-190 | 31.0 | 11.0 | Engine parts / X-15 |

*[verify pp. 528-529]* — this table's original OCR is heavily column-scrambled (values print in a
single reflowed run disconnected from row labels); the entries above were reconstructed by matching
plausible property clusters to named alloys and cross-checked against commonly published values for
the same alloys, but should be re-verified against the printed page or a materials handbook (e.g. Ref.
[100]) before use in load-critical MATLAB calculations. Not transcribed row-complete.

### Table 14.4 — Wood Properties (ANC-5)
*[Raymer, Table 14.4, p. 530]* — Density (lb/in³) and allowable stress values (ksi range) for ash,
birch, African mahogany, Douglas fir, western pine, and spruce. Representative:

| Wood | Density (lb/in³) | Approx. allowable range (ksi) |
|---|---|---|
| Ash | 0.024 | 2.3-14.8 |
| Birch | 0.026 | 1.6-15.5 |
| African mahogany | 0.019 | 1.4-10.8 |
| Douglas fir | 0.020 | 1.3-11.5 |
| Western pine | 0.016 | 0.8-9.3 |
| Spruce | 0.016 | 0.7-9.4 |

`[verify p. 530]` — table column headers (bending/compression-parallel/compression-perpendicular/
shear allowable stresses, specific gravity) did not survive OCR cleanly; values above are density plus
the printed numeric range per species, not attributed to specific named columns — consult ANC-5 or
the printed page directly for the full breakdown.

### Table 14.5 — Typical Composite Material Properties (Room Temperature)
*[Raymer, Table 14.5, p. 531]* — For high-strength graphite-epoxy, high-modulus graphite-epoxy,
boron-epoxy, graphite-polyimide, S-fiberglass-epoxy, E-fiberglass-epoxy, and aramid-epoxy: ultimate
tensile/compressive strength (longitudinal/transverse, ksi), interlaminar shear strength `Fsu`(LT), `E`
(10⁶ psi, longitudinal/transverse), `G` (10⁶ psi), density (lb/in³), max temperature (°F), and moisture
absorption (%). Representative (longitudinal tension ultimate, `E_L`):

| Material | Ftu-L (ksi) | E_L (10⁶ psi) | Density (lb/in³) | Max temp (°F) |
|---|---|---|---|---|
| High-strength graphite-epoxy | ~200 | ~21.0 | 0.056 | 350 |
| High-modulus graphite-epoxy | ~110 | ~25.0 | 0.056 | 350 |
| Boron-epoxy | ~195 | ~30 | 0.073 | 350 |
| Graphite-polyimide | ~204 | ~30 | 0.058 | 350 |
| S-fiberglass-epoxy | ~219 | ~7.7 | 0.071 | 350 |
| E-fiberglass-epoxy | ~105 | ~4.23 | 0.074 | 350 |
| Aramid-epoxy | ~200 | ~11 | 0.052 | 350 |

`[verify p. 531]` — like Table 14.3, this table's OCR is heavily scrambled by column reflow; values
above are a best-effort reconstruction of representative longitudinal tensile strength/modulus per
material and should be confirmed against the printed page or manufacturer datasheets before
load-critical use.

## §14.8 Structural-Analysis Fundamentals

### §14.8.1 Properties of Sections

```
xc = (∫ x·dA) / A                                                       (14.21)
yc = (∫ y·dA) / A                                                       (14.22)
```
*[Raymer, Eqs. (14.21)-(14.22), p. 532]* — centroid coordinates (Fig. 14.27); a symmetric section's
centroid lies on its symmetry axis/axes. Any axis through the centroid is a "centroidal axis"; a
symmetry axis is always centroidal.

### Fig 14.27 — Section property definitions
*[Raymer, Fig. 14.27, p. 532]* — Arbitrary-shape and bisymmetric-shape sketches showing centroid
location and `xc`/`yc`. No further plotted data (definitional diagram).

### Table 14.6 — Properties of Simple Sections
*[Raymer, Table 14.6, p. 533]* — Area, centroid, `Ix`, `Iy`, `ρx`, `ρy` for rectangle, hollow
rectangle, circle, hollow circle (annulus), and right triangle:

| Shape | Area | Ix (own centroid) | ρx |
|---|---|---|---|
| Rectangle (B×H) | B·H | B·H³/12 | H/√12 |
| Hollow rectangle | B·H − b·h | (B·H³ − b·h³)/12 | sqrt[(BH³−bh³)/(12(BH−bh))] |
| Circle (radius R) | π·R² | π·R⁴/4 | R/2 |
| Hollow circle (R,r) | π·(R²−r²) | π·(R⁴−r⁴)/4 | sqrt[(R²+r²)/2]/√2 [as printed: sqrt(R²+r²)/2] |
| Right triangle (base B, height H) | B·H/2 | B·H³/36 | H/√18 |

`Iy`/`ρy` mirror `Ix`/`ρx` with B/H (or b/h) swapped, per the table's symmetric column pairs.

```
Ix = Σ (y²·dAi)                                                         (14.23)
Iy = Σ (x²·dAi)                                                         (14.24)
Ip = J = Σ(r²·dAi) = Ix + Iy                                            (14.25)
```
*[Raymer, Eqs. (14.23)-(14.25), p. 534]* — polar moment of inertia `J`, used in torsion. This is the
*area* moment of inertia (units length⁴), distinct from the *mass* moment of inertia used in Chapter
16 dynamic-stability work (units mass·length²).

```
Ix = Ixc + A·e_y²                                                       (14.26)
Iy = Iyc + A·e_x²                                                       (14.27)
```
*[Raymer, Eqs. (14.26)-(14.27), p. 534]* — parallel-axis theorem, transferring simple-shape moments of
inertia to a combined centroidal axis (`ex`,`ey` = offset distances) before summing for a built-up
section.

```
ρ = sqrt(I/A)                                                           (14.28)
```
*[Raymer, Eq. (14.28), p. 534]* — radius of gyration, used in column-buckling analysis (§14.9); also
usable to back out `I` from Table 14.6's `ρ` values.

### §14.8.2 Tension

```
σ = P/A                                                                 (14.29)
```
*[Raymer, Eq. (14.29), p. 535]* — same as Eq. (14.14); use the *smallest* cross-section (e.g. at
rivet/bolt holes, or along a diagonal "zipper" line of holes if that net area is smaller than the
perpendicular section). Limit-load stress should not exceed yield stress (metals) or the
ultimate-strain-based allowable divided by the safety factor (composites, typically 1.5 as well).

### §14.9 Compression

Same Eq. (14.29) form, but only valid as a *limit* criterion for short/laterally-constrained parts
(fittings, spar caps, sandwich face sheets) — long unconstrained members ("columns"/"struts") are
governed by buckling instead. Ultimate compressive strength ≈ tensile value for ductile metals
(conservative — they "squish" rather than truly fail); rivet/bolt holes *are* included in compression
cross-section area (fasteners carry compression).

**Slenderness ratio** (governs buckling mode):

```
Slenderness ratio = Le/ρ                                                (14.30)
```
*[Raymer, Eq. (14.30), p. 535]* — `Le` = effective length, from end-constraint type (Fig. 14.28):
perfectly rigid `Le=0.5L`; welded ends `Le=0.71L`; riveted/bolted `Le=0.82L`.

### Fig 14.28 — Column effective length
*[Raymer, Fig. 14.28, p. 536]* — Four end-condition sketches (pin-pin, fixed-free, fixed-fixed,
fixed-pin combinations) with associated `Le` multipliers as listed above.

**Euler (elastic) buckling** — critical load/stress independent of material ultimate strength, only
`Le`, `I`, `E`:

```
Pc = π²·E·I / Le²                                                       (14.31)
Fc = Pc/A = π²·E / (Le/ρ)²                                              (14.32)
```
*[Raymer, Eqs. (14.31)-(14.32), p. 536]* — Eq. (14.32) is an ultimate (no-margin) failure stress; use
~2/3 of it for design limit loads. Irregular/open cross-sections may fail earlier via twisting/
cross-section deformation (see Refs. [106,108]). The **critical slenderness ratio** (below which
buckling is *inelastic*, i.e. exceeds the proportional limit and Euler's equation no longer applies
directly) is material-dependent: ≈77 (2024 aluminum), ≈51 (7075 aluminum), ≈91.5 (4130 steel), 59-76
(alloy steel, heat-treatment-dependent) — most aircraft columns fall below these values, so inelastic
buckling (using the tangent modulus `Et` in place of `E` in Eq. 14.32, requiring iteration or handbook
charts like Fig. 14.29) is the norm, not the elastic Euler case.

### Fig 14.29 — Column buckling loads (round tubing)
*[Raymer, Fig. 14.29, p. 538]* — `Fc` (0-160 ksi) vs slenderness ratio (0-140) for alloy steel at
`Ftu` = 125, 150, 180 ksi, plus heat-treatment family curves. *(read from plot, approximate, Ftu=180
ksi curve)*: slenderness=20→Fc≈150 ksi; 40→~120 ksi; 60→~85 ksi; 80→~55 ksi; 100→~38 ksi; 140→~20 ksi.

Very short columns (slenderness ratio ≲12) are in pure "block compression" (no buckling risk); the
compression yield value is the limit-load cutoff there. Very short, thin-walled columns instead fail
in "crippling" (local wall collapse, e.g. crushing a soda can), with load capacity dropping toward
zero:

```
Fcrippling ≈ 0.3·(E·t/R)                                                (14.33)
```
*[Raweb, Eq. (14.33), p. 537]* — thin-wall cylindrical tube estimate, `t` = wall thickness, `R` =
radius (see Ref. [108] for general thin-wall crippling methods).

Flat sheet/panel compression buckling:

```
Fbuckling = K·E·(t/b)²                                                  (14.34)
```
*[Raymer, Eq. (14.34), p. 538]* — `K` from Fig. 14.30 (panel length/width ratio `a/b` and edge
constraint: clamped, simply supported, or free — clamped sides give the highest `K`/strength, free
sides the lowest); most aircraft panels are clamped with some rotational flexibility, so an
intermediate `K` is often appropriate.

### Fig 14.30 — Panel buckling coefficient (NACA TN3781)
*[Raymer, Fig. 14.30, p. 539]* — `K` (0-12) vs `a/b` (0-4+) for three edge-constraint cases: clamped
sides and ends (highest, asymptoting ≈4+ at large a/b, with a local minimum ≈3.5-4 around a/b≈1-2);
one side clamped/one free with simply-supported ends (mid); one side free, one side and ends simply
supported (lowest, asymptoting to 0.385 at large a/b per the figure's own callout). *(read from plot,
approximate, clamped-sides-and-ends curve)*: a/b=1→K≈6.5; a/b=2→K≈4.2; a/b=3→K≈4.5; a/b=4→K≈4.0.

### §14.10 Truss Analysis

An ideal truss: weightless struts, frictionless pin joints, loads only at pins, no applied moments —
members carry pure tension/compression ("primary truss loads"); mid-strut attachment loads must be
added separately. Historically used for welded steel-tube fuselages; today mainly piston-engine motor
mounts, large-aircraft ribs, and landing gear.

### Fig 14.31 — Typical truss structure
*[Raymer, Fig. 14.31, p. 540]* — A light-aircraft engine-mount truss (3 struts analyzed in 2-D for
illustration), plus an equivalent truss showing force lines to the engine c.g. and reaction forces
from the rigid fuselage/engine attachment.

**Method of joints**: at each joint, ΣFvertical = ΣFhorizontal = 0; solve starting from a joint with
only 2 unknown struts (usually the externally-loaded joint) and proceed to joints with progressively
fewer unknowns.

### Fig 14.32 — Method of joints
*[Raymer, Fig. 14.32, p. 541]* — Worked example (4000-lb engine load, 27-deg strut angles): Joint 1
(engine c.g.) gives `Fa=4400 lb (T)`, `Fb=−4400 lb (C)`; Joint 2 gives `Fc=−3919 lb (T)` [sign as
printed] and `Fd=−2000 lb (C)`; Joint 3 (remaining unknowns) gives `Fe=5775 lb (T)`, `Ff=−9463 lb (C)`.
Equations shown: `ΣFH=0=Fa·cos27+Fb·cos27`, `ΣFv=0=Fa·sin27−Fb·sin27−4000`; `ΣFH=0=Fc−Fa·cos27`,
`ΣFv=0=−Fd−Fa·sin27`.

Faster alternatives for specific struts: **method of moments** (cap struts — replace the structure by
two rigid bodies pinned at a point, sum moments about the pin) and **method of shears** (inner
diagonal strut — cut a plane through 3 members, sum forces on the severed free body; solving via both
vertical and horizontal sums gives a built-in check).

### Fig 14.33 — Method of moments/method of shears
*[Raymer, Fig. 14.33, p. 542]* — Three worked-example free-body cuts for the same motor-mount truss:
top strut via moments (`ΣM=0=−69.9(4000)−30·Ff·cos11`, giving `Ff=−9463`); a similar cut for the lower
strut; and a shear-method cut for the inner strut giving `Fe=5775` (checked both ways, `ΣFH` and
`ΣFv`).

These direct methods only work for **statically determinate** trusses (every strut cuttable by a
plane crossing only 2 other struts — guarantees a solvable 2-unknown joint always exists);
indeterminate trusses need deflection-based methods (Refs. [98,108]) or FEM (§14.11). Once strut loads
are known, analyze each as tension/compression members (§14.8.2/§14.9) using the appropriate effective
length (Fig. 14.28) — conservatively treat welded steel-tube motor mounts as pinned-end (`Le=L`).
3-D "space" trusses: square-section cases (e.g. welded-tube fuselages) can sometimes be solved as
separate 2-D side/top-view trusses and summed (valid only within the elastic range); general 3-D
trusses need the 3-equation/3-unknown method-of-joints form (simultaneous equations, e.g. via
computer) or selected-point moment summation (Ref. [95] covers space structures in detail).

### §14.11 Beam Shear and Bending

Two-step: (1) find shear/bending-moment distributions, (2) find the resulting stresses.

### Fig 14.34 — Shear and moment in beams
*[Raymer, Fig. 14.34, p. 543]* — Cut-beam free body under distributed vertical load, showing the
internal shear-force reaction (balances applied vertical loads outboard of the cut) and the internal
moment reaction (compression above / tension below the neutral axis, balancing the moment of those
same outboard loads).

Shear at any span station = sum (or integral) of loads outboard of that station; bending moment = sum
(or integral) of those loads × their distance from the station. Wing loads (Fig. 14.35: rolling
pull-up with full aileron deflection is the critical case) combine distributed lift/wing-weight loads
(both × load factor) with concentrated nacelle weight; replace distributed loads with concentrated
equivalents (via Schrenk's approximation for lift, chord-proportional for wing weight) using ~10-20
spanwise stations, via the trapezoidal-segment construction of Fig. 14.36:

```
F = s·(a+b)/2                                                           [total force]
X = s·(2a+b) / (3a+3b)                                                  [centroid location]
```
*[Raymer, Fig. 14.36 formulas, p. 545]* — `s` = station spacing, `a`,`b` = load intensities at the two
ends of the trapezoidal segment.

### Fig 14.35 — Wing loads, shear, and bending moment
*[Raymer, Fig. 14.35, p. 544]* — Distributed airload (with aileron-deflection increment), distributed
wing-weight load, and concentrated nacelle weight along the span, with resulting shear and bending
-moment diagrams below. No further plotted numeric data (illustrative construction).

### Fig 14.36 — Trapezoidal approximation for distributed loads
*[Raymer, Fig. 14.36, p. 545]* — Trapezoid of intensities `a` (root end) and `b` (tip end) over
station spacing `s`, replaced by a single concentrated force `F` at centroid location `x` from the
`b`-end, per the formulas above.

Compute shear tip-to-root (running sum of outboard loads); compute bending moment tip-to-root as the
running integral (area under the shear curve). Bending stress (linear across the section, from the
neutral axis at the centroid):

```
σx = M·z / Iy                                                          (14.35)
```
*[Raymer, Eq. (14.35), p. 545]* — max at top/bottom surfaces; `z` = vertical distance from neutral
axis (derivation in Ref. [99]).

Vertical shear stress is *not* uniform through the section depth (tied to the matching horizontal
shear per Fig. 14.17's shear-pairing argument):

```
τ = (V / (I·b)) · ∫[z1..h/2] z·dA                                        (14.36)
```
*[Raymer, Eq. (14.36), p. 546]* — the integral is the first moment of area above the cut at `z=z1`;
max at the neutral axis, zero at the surfaces. For a rectangular section, max shear (at neutral axis)
= 1.5× the average (V/A); for a solid circular section, 1.33× average.

### Fig 14.37 — Relationship between shear and bending
*[Raymer, Fig. 14.37, p. 546]* — Beam-bending sketch with the linear bending-stress distribution
(compression top, tension bottom) and the resulting parabolic-ish vertical shear-stress distribution
(peaking at the neutral axis, zero at top/bottom surfaces), illustrating Eq. (14.36)'s derivation.

### Fig 14.38 — Typical aircraft spar in bending and shear
*[Raymer, Fig. 14.38, p. 547]* — Spar cross-section (thick "spar caps" separated by a thin "shear
web") with bending-stress and shear-stress-magnitude diagrams: caps carry essentially all bending
(their area dominates); the thin web carries essentially all shear, and (with the simplifying
assumption of a full-depth web) shear is taken as roughly uniform across the web (max ≈ average =
shear/web-area).

Shear webs buckle well before reaching material max shear stress:

```
Fshear_buckle = K·E·(t/b)²                                              (14.37)
```
*[Raymer, Eq. (14.37), p. 547]* — `K` from Fig. 14.39.

### Fig 14.39 — Shear web buckling (NACA TN3781)
*[Raymer, Fig. 14.39, p. 547]* — `K` (0-16) vs `a/b` (0-10) for simply-supported edges. *(read from
plot, approximate)*: a/b=1→K≈10; a/b=2→K≈6.5; a/b=4→K≈5.5; a/b=6→K≈5.3; a/b=10→K≈5.2 (asymptoting).

### §14.12 Braced-Wing Analysis

A strut-braced wing greatly reduces bending moment vs a cantilevered wing, but the strut's spanwise
compression component `P` can increase bending moment up to ~33% if properly accounted for (vs
ignoring the compression effect). `P` = horizontal component of strut force `S`; `S`'s vertical
component comes from a moment balance about the root pin using the equivalent concentrated lift loads
(Fig. 14.40).

### Fig 14.40 — Brace wing analysis
*[Raymer, Fig. 14.40, p. 549]* — Braced-wing side view: strut `S` at some angle, root pin, uniform
inboard load `w`, bending-moment stations `M1` (root) and `M2` (strut location) labeled.

```
M(x) = C1·sin(x/j) + C2·cos(x/j) + w·j²                                 (14.38)
Mmax = D1/cos(xm/j) + w·j²                                              (14.39)
tan(xm/j) = (D2 − D1·cos(L/j)) / (D1·sin(L/j))                          (14.40)
j = sqrt(E·I/P)                                                         (14.41)
C1 = (D2 − D1·cos(L/j)) / sin(L/j)                                      (14.42)
C2 = D1 = M1 − w·j²                                                     (14.43)
D2 = M2 − w·j²                                                          (14.44)
```
*[Raymer, Eqs. (14.38)-(14.44), p. 549]* — cited to Ref. [108]; `M1` (root moment) is usually zero
unless the hinge is offset from the neutral axis (creating a moment from `P`); `w` approximates the
inboard-of-strut lift distribution as uniform (reasonable there). Practical design note: wing struts
are typically set ≈40 deg up from horizontal (front view) — too flat increases strut tension/fuselage
pull-off loads and inboard wing compression (buckling risk); too steep leaves more wing cantilevered
(heavier); too horizontal makes for a very long, high-drag strut close to the wing.

## §14.13 Torsion

### Fig 14.41 — Solid circular shaft in torsion
*[Raymer, Fig. 14.41, p. 550]* — Shaft under applied torque `T`, twisting through angle `φ` over
length `L`, with linearly-increasing internal shear stress (max at radius `R`, elastic range assumed).

```
τ = T·r/Ip                                                              (14.45)
φ = T·L / (G·Ip)                                                        (14.46)
```
*[Raymer, Eqs. (14.45)-(14.46), p. 550]* — max stress at `r=R`; also applies to circular tubing (using
the appropriate `Ip`). For a thin-walled *closed* section (constant wall thickness `t`, enclosed area
`A`, perimeter `s`):

```
τ = T / (2·A·t)                                                         (14.47)
φ = T·s / (4·A²·G·t)                                                    (14.48)
```
*[Raymer, Eqs. (14.47)-(14.48), p. 550]*.

### Table 14.7 — Torsion Constants
*[Raymer, Table 14.7, p. 551]* — `α` and `β` coefficients (for Eqs. 14.49-14.50) vs aspect ratio b/t:

| b/t | α | β |
|---|---|---|
| 1.00 | 0.208 | 0.141 |
| 1.50 | 0.231 | 0.196 |
| 1.75 | 0.239 | 0.214 |
| 2.00 | 0.246 | 0.229 |
| 2.50 | 0.258 | 0.249 |
| 3.00 | 0.267 | 0.263 |
| 4 | 0.282 | 0.281 |
| 6 | 0.299 | 0.299 |
| 8 | 0.307 | 0.307 |
| 10 | 0.313 | 0.313 |
| ∞ | 0.333 | 0.333 |

For solid rectangular sections (thickness `t`, width `b`):

```
τ = T / (α·b·t²)                                                        (14.49)
φ = T·L / (β·b·t³·G)                                                    (14.50)
```
*[Raymer, Eqs. (14.49)-(14.50), p. 551]* — also usable for sheet-metal-formed members by "unwrapping"
to an effective total width. Multi-celled wing-box torsion analysis is beyond this book's scope (see
Ref. [108]).

## §14.14 Finite Element Structural Analysis

Classical handbook/nomogram structural analysis (as above) is now largely superseded by finite element
method (FEM/FEA) software, ubiquitous even to homebuilders. FEM breaks the structure into small
"elements" (Fig. 14.42: bar/beam, triangle, rectangular plate, solid tetrahedron, solid ring are common
types), each with an approximate stiffness relation, assembled via matrix algebra into a whole-structure
response model; solving requires computers except for trivial cases. Element-type/size selection is
judgment-based (finer mesh where stress gradients are steep, e.g. near corners).

### Fig 14.42 — Typical finite elements
*[Raymer, Fig. 14.42, p. 552]* — Five element-shape sketches: bar/beam, triangle, rectangular plate,
solid tetrahedron, solid ring. No plotted data (reference diagram).

### Fig 14.43 — Typical finite element model
*[Raymer, Fig. 14.43, p. 553]* — A propfan research aircraft's major structural members modeled with
rectangular-plate elements (forward fuselage, nacelle, aft fuselage labeled), courtesy Lockheed Martin.
No plotted data (illustrative FEM mesh).

Worked 1-D bar-element example (Ref. [111]): for a bar with end loads `P1,P2` and end deflections
`u1,u2`, cross-section `A`, length `L` (Fig. 14.44):

```
ε = (u1 − u2)/L                                                         (14.51)
E = σ/ε = (P/A) / ((u1−u2)/L)                                           (14.52)
P = (E·A/L)·(u1 − u2)                                                   (14.53)
P1 = (E·A/L)·(u1 − u2)                                                  (14.54)
P2 = (E·A/L)·(−u1 + u2)                                                 (14.55)
{P} = [k]{u},  k = (EA/L)·[[1,−1],[−1,1]]                               (14.56)-(14.57)
```
*[Raymer, Eqs. (14.51)-(14.57), pp. 553-554]* — `[k]` = element stiffness matrix, `{u}` = displacement
vector, `{P}` = force vector; invert `[k]` to solve deflections for any loading.

### Fig 14.44 — Simple one-dimensional bar element
*[Raymer, Fig. 14.44, p. 553]* — Bar of length `L`, cross-section `A`, end loads `P1`/`P2` and end
deflections `u1`/`u2` (deflected shape drawn offset for clarity). No further plotted data (definitional
diagram for the worked FEM example).

Assembling two bar elements at a shared "node" (Fig. 14.45 — where connected elements' displacements
are equal, e.g. `u2` shared between element 1's right end and element 2's left end):

```
{P1a; P2a} = k1·{u1;u2}                                                 (14.58)
{P2b; P3b} = k2·{u2;u3}                                                 (14.59)
[K_assembled] with overlapping (summed) node terms at u2                (14.60)
```
*[Raymer, Eqs. (14.58)-(14.60), p. 554]*.

### Fig 14.45 — One-dimensional bar FEM assembly
*[Raymer, Fig. 14.45, p. 555]* — Two bar elements of lengths `L1`,`L2` joined at a shared node,
loads `P1,P2,P3` at the three nodes. No further plotted data (definitional diagram).

Numeric example (Fig. 14.46: two-bar structure, right end fixed to a wall, `L1=12 in.`, `L2=14 in.`,
`A1=28 in²`, `A2=12 in²`, `P1=400,000 lb`, `P2=300,000 lb`, aluminum `E=10.7×10⁶ psi`):

```
[3×3 stiffness matrix system, Eq. (14.61)] → reduce to 2×2 (u3=0 at the wall), Eq. (14.62):
{P1;P2} = [[2.5e7, −2.5e7],[−2.5e7, 3.5e7]] · {u1;u2}
inverse gives {u1;u2} = {0.093; 0.077} in.                              (14.63)-(14.64)
ε1 = (0.093−0.077)/12 = 0.0013;  ε2 = (0.077−0)/14 = 0.0055               (14.65)-(14.66)
σ1 = 14,267 psi;  σ2 = 58,850 psi                                        (14.67)-(14.68)
```
*[Raymer, Eqs. (14.61)-(14.68), pp. 555-556]*.

### Fig 14.46 — FEM example
*[Raymer, Fig. 14.46, p. 556]* — Dimensioned two-bar structure (as described above): `L1=12 in.`,
`L2=14 in.`, `A1=28 in²`, `A2=12 in²`, wall on the right, `P1=400,000 lb`, `P2=300,000 lb`, aluminum
`E=10.7×10⁶ psi` — the source geometry for Eqs. (14.61)-(14.68).

3-D geometry requires direction-cosine terms (angled members give different length changes for
identical nodal deflections). Most real FEM analyses use surface elements (e.g. the triangle of Fig.
14.42) rather than simple bars, assembled the same conceptual way; dynamic analysis adds mass/damping
matrix terms, greatly increasing input complexity. NASTRAN (NASA Structural Analysis) has long been
the industry-standard FEM program, now integrated into many CAD/analysis suites; using it well still
requires substantial engineering judgment/experience.

## What We've Learned

*[Raymer, p. 557]* The chapter covered the overall structural arrangement task on the Dash-One layout,
loads definition, and classical structural-analysis methods; finite element methods give better
answers later in the design process.

---

*Chapter 14 complete (Introduction, §§14.1-14.14 [Loads Categories, Air Loads, Inertial Loads,
Powerplant Loads, Landing-Gear Loads, Structures Fundamentals, Material Selection, Material
Properties, Structural-Analysis Fundamentals, Compression, Truss Analysis, Beam Shear and Bending,
Braced-Wing Analysis, Torsion, Finite Element Structural Analysis], Tables 14.1-14.7, Figs
14.1-14.46, Eqs. 14.1-14.68, "What We've Learned" summary). PDF index span used: 520-586 (printed
pp. 491-557; p. 558 at index 587 is blank/chapter-closing whitespace). Two items flagged
`[verify]`: Eq. (14.12)'s exact bracketed relationship between `Vp`, `Vs`, `n`, and `Kp` (p. 504,
OCR ambiguous — standard form `Vp = Vs·sqrt(n_limit·Kp)` proposed pending page-image confirmation);
Tables 14.3 and 14.5's material-property values (pp. 528-529, 531) were heavily column-scrambled in
the OCR pass and are reconstructed representative entries, not verified row-complete transcriptions —
flag for re-verification against a materials handbook before load-critical use. Table 14.4 (p. 530)
similarly could not be cleanly attributed to named property columns. Figures with genuine numeric
plot content (V-n diagrams' construction logic, gust-velocity-vs-altitude, buckling-coefficient
charts, skin-temperature-vs-Mach) were digitized with representative read-from-plot points; pure
material-callout/schematic/photo figures were noted without digitization. Next: Chapter 15 —
Weights.*
