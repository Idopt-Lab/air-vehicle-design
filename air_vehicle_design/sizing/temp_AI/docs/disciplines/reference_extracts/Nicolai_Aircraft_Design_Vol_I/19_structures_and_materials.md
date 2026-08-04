# Chapter 19 — Structures and Materials

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, Chapter 19,
printed pp. 491–550 (PDF pp. 501–560). Chapter authored by Walter Franklin, Lockheed Martin Fellow.

Text-layer inventory (built before extraction, for completeness checking): Figs 19.1–19.30 (with
sub-labels to be confirmed during extraction); Tables 19.1–19.7; Eqs (19.1)–(19.4).

## Chapter opener

By-line: *by Walter Franklin, Lockheed Martin Fellow in Structures and Materials.* *[Nicolai & Carichner,
p. 491]*

Section list: Structural Design Criteria; Strength vs Buckling Stability; Finite Element Modeling; Loads;
Stress Analysis; Joints; Material Selection; Example. *[Nicolai & Carichner, p. 491]*

Photo caption: aerial photo of an F-117 fuselage/wing structure under assembly on a factory floor with
workers present. Sidebar: *This F-117 was one of 64 built in total secrecy by Lockheed in Burbank,
California. Completed aircraft were disassembled, put into a C-5A, flown to a secret base at Tonopah,
Nevada, and reassembled. At base, they were kept in shelters during the day and flown for training only at
night.* *[Nicolai & Carichner, p. 491]*

Chapter epigraph: *"One simple test can be worth a whole lot of analysis."* *[Nicolai & Carichner, p. 491]*

Copyright note: *Copyright 2010 by Walter Franklin. Published by the American Institute of Aeronautics and
Astronautics, Inc., with permission.* *[Nicolai & Carichner, p. 491]*

## §19.1 Introduction (p. 492)

Aircraft structural design and analysis embodies a philosophy that is significantly different from the
approach used for many civil engineering structures, such as bridges and buildings. Structural efficiency
and minimum weight are of paramount importance for aircraft structure; and taking advantage of the
inherent capability of thin-sheet structures to carry substantial load, even in a postbuckled state, is one
of the key differences that separates aircraft structural design from other types of structural
engineering. Since the Wright brothers' flight in 1903, the aircraft industry has developed a
comprehensive body of design and analytical methods, based on extensive structural development testing
combined with a wealth of lessons-learned from flight hardware, that make possible airframe structure that
is safe, robust, and lightweight. *[Nicolai & Carichner, p. 492]*

Aircraft structural engineering combines aspects of design, analysis, and manufacturing; and a basic
knowledge in each of these areas is essential to the aircraft structural design process. The engineering
disciplines that make up the Structures Group include the following *[Nicolai & Carichner, p. 492]*:

1. External loads
2. Stress
3. Flutter and Dynamics
4. Mass properties
5. Materials and Processes
6. Structural testing

Sidebar — *Factor of Safety for Aircraft Structural Design*: *The ultimate factor-of-safety of 1.5 for
aircraft structural design was first introduced in the early 1930s. Prior to this time, aircraft were
designed to withstand, without failure, a certain load factor which was typically on the order of 6.0 g's.
The concept of limit load and ultimate load had not been developed at this time. Since aircraft structure
designed in this manner did not show any widespread evidence of permanent yielding or structural failure,
it was felt the existing load factor requirements must have included an inherent factor-of-safety. As
aircraft speed and performance increased during this time period, it was felt necessary to define this
factor-of-safety for future design efforts. The selection of 1.5, although somewhat arbitrary, was based
in part on the ratio of ultimate strength to yield strength of the aluminum alloys that were being used at
that time. Although a higher factor-of-safety could have been selected, there was also a desire to keep
the resulting "limit load" as high as possible to not unduly penalize future aircraft designs.* — Professor
F. R. Shanley, 1961 *[Nicolai & Carichner, p. 492]*

The functions and responsibilities of each of these disciplines, and many of the technical challenges that
each discipline encounters during the aircraft design and development process, are discussed in the
following sections. *[Nicolai & Carichner, p. 493]*

## §19.2 Structural Design Criteria and External Loads (p. 493)

The starting point for the design of airframe structure involves definition of the structural design
criteria. The *structural design criteria* are the key parameters, such as design load factors, vehicle
weights, speeds and altitudes, design life, factors-of-safety, and other operational considerations, that
drive the design of the airframe. Although there are similarities in the structural design criteria among
the various types of aircraft, many detailed requirements can vary greatly from one aircraft to another
depending on a number of factors, including the agency that will grant flight certification (for example,
commercial vs military certification), the particular class of aircraft (for example, fighter vs
transport), and other requirements as dictated by the intended operator of the aircraft (for example, U.S.
Air Force vs U.S. Navy requirements). *[Nicolai & Carichner, p. 493]*

For military aircraft, the MIL-A-8860 series of documents provides a good starting point for defining
structural design criteria. The various documents contained in the MIL-A-8860 series are summarized as
follows *[Nicolai & Carichner, p. 493]*:

1. MIL-A-8860, Aircraft Strength and Rigidity—General Specification
2. MIL-A-8861, Flight Loads
3. MIL-A-8862, Landplane Landing and Flight Handling Loads
4. MIL-A-8863, Ground Loads for Navy Procured Airplanes
5. MIL-A-8864, Water and Handling Loads for Seaplanes
6. MIL-A-8865, Miscellaneous Loads
7. MIL-A-8866, Reliability Requirements, Repeated Loads, and Fatigue
8. MIL-A-8867, Ground Tests
9. MIL-A-8868, Data and Reports

Similar design criteria for commercial and private aircraft are covered under the Federal Aviation
Administration (FAA) guidelines contained in the Federal Aviation Regulation (FAR) documents. *[Nicolai &
Carichner, p. 493]*

Although the MIL-A-8860 documents are a valuable source of commonly used structural design requirements,
new military aircraft development programs commonly employ "tailored" design criteria that are unique to
the particular aircraft being developed. The "Joint Service Specification Guide—Aircraft Structures"
(JSSG-2006) [1] provides a framework for developing such tailored design criteria. JSSG-2006 is one of
eight Joint Service Specification Guides that were developed as part of acquisition reform by the U.S.
government. These specification guides were developed

to provide the aerospace industry with a single, consistent approach for defining design requirements
that would be common among the different military services [2]. JSSG-2006 is a comprehensive
"fill-in-the-blank" type of template that covers a wide range of structural design requirements such as
vehicle weight and center-of-gravity requirements, loading conditions, airframe construction parameters,
aeroelastic requirements, material properties, and structural durability requirements. As such, it is an
excellent resource to guide the development of a tailored set of design criteria to insure that all
pertinent structural requirements are being addressed. *[Nicolai & Carichner, p. 494]*

Sidebar: *The Bell X-1, which in 1947 became the first aircraft to break the sound barrier, was designed
to a vertical load factor ($n_z$) of +/− 18 g, which was about 50% higher than the known g capability of
any other aircraft being flown at that time.* *[Nicolai & Carichner, p. 494]*

A key design parameter contained in the structural design criteria is the flight envelope for the
aircraft, commonly represented as a $V$–$n$ diagram plotting aircraft speed in KEAS vs vertical load factor
$n_Z$, commonly expressed in g's. Fig. 19.1 shows a typical $V$–$n$ diagram. Here, KEAS translates to
*knots-equivalent airspeed*, which is the true airspeed corrected for the difference in density of the air
at altitude compared with sea level (SL), as shown in the following expression (unnumbered equation, p.
494):

$$V_e = \sqrt{\sigma}V_t$$

where $V_e$ = equivalent airspeed (this is always written in knots as KEAS), $\sigma = \rho_{alt}/\rho_{SL}$
(air density ratio), $V_t$ = true airspeed. *[Nicolai & Carichner, p. 494]*

**Fig. 19.1** — *Typical V–n diagram used for airplane design* *[Nicolai & Carichner, Fig. 19.1, p. 494]*.
Plot of Vertical Load Factor $n_z$ (gs) vs. Speed (KEAS): a closed flight-envelope boundary starting at
the origin, following a "Stall Line" curve down to $-n_z$ at low speed, running flat at $-n_z$ ("Maximum
Design") out to near max speed then angling back up toward the axis; on the positive side, a "Stall Line"
curve rises from the origin through $n_z=1.0$ up to $+n_z$ ("Maximum Design"), runs flat to "Maximum Dive
Speed ($V_D$)," then drops back to the axis. Dashed "Gust Lines" radiate from the $n_z=1.0$ point on the
vertical axis through the upper and lower boundary corners.

Equivalent airspeed is often the measure of aircraft speed preferred by the Loads Engineer because it
represents a speed with a constant dynamic pressure ($q$), regardless of the aircraft's altitude.
*[Nicolai & Carichner, p. 495]*

The *vertical load factor $n_Z$* is of particular interest because it is a key indicator of the critical
flight loads that drive the design of the airframe structure, especially the wing structure. MIL-A-8861
provides guidance on the appropriate vertical load factors for different classes of aircraft. Maximum
positive vertical load factors, as would be experienced during a pull-up maneuver, typically range from
+3.0 g for many transport-type aircraft to +7.5 g, or more, for fighter-type aircraft. Maximum negative
vertical load factors, as might occur during a push-over maneuver, commonly range from −1.0 g for
transport-type aircraft to −3.0 g for fighter-type aircraft [3]. *[Nicolai & Carichner, p. 495]*

*Gust load factors*, which result from the aircraft flying through turbulent air, are also typically
included on the $V$–$n$ diagram in the form of "gust lines." When an aircraft experiences a gust, the
effect is an increase or decrease in the angle-of-attack, resulting in a change in lift and, consequently,
a change in load factor. The load factor resulting from a gust can be estimated using the following
*discrete gust relationship* *[Nicolai & Carichner, Eq. (19.1), p. 495]*:

$$n = 1 \pm \frac{K_g C_{L\alpha}U_e V_e}{498\,W/S} \tag{19.1}$$

where:

- $C_{L\alpha}$ = lift curve slope (per radian) for the complete airplane
- $U_e$ = equivalent gust velocity (ft/s)
- $V_e$ = equivalent airspeed (KEAS)
- $W/S$ = wing loading (lb/ft²)
- $K_g$ = gust alleviation factor = $0.88\mu/(5.3+\mu)$ (subsonic aircraft)

where:

- $\mu = (2\,W/S)/(\rho\bar{c}C_{L\alpha}g)$
- $\rho$ = air density (slug/ft³)
- $\bar{c}$ = mean aerodynamic chord (ft)
- $C_{L\alpha}$ = lift curve slope (per radian)
- $g$ = acceleration due to gravity (ft/s²)

*[Nicolai & Carichner, p. 495]*

The *equivalent gust velocity $U_e$*, input into Eq. (19.1), is defined as a function of both aircraft
speed and altitude. Consequently, there is a range of equivalent gust velocities used for aircraft design,
as shown in Fig. 19.2. There is an inverse relationship between gust velocity and aircraft speed — as
aircraft speed increases the gust velocity used for design decreases. This relationship is representative
of customary aircraft operation in which a pilot will reduce speed consistent with the level of turbulence
that is encountered [4]. *[Nicolai & Carichner, p. 495]*

**Fig. 19.2** — *Equivalent gust velocity as a function of speed and altitude* *[Nicolai & Carichner, Fig.
19.2, p. 496]*. Plot of Altitude (1000 ft, 0–50) vs. Equivalent Gust Velocity $U_e$ (ft/s, 0–70), with
three near-vertical lines: "Dive Speed, $V_D$" (from 25 ft/s at 0–20,000 ft, angling to 12.5 ft/s at
50,000 ft), "Cruise Speed, $V_C$" (from 50 ft/s at 0–20,000 ft, angling to 25 ft/s at 50,000 ft), "Rough
Air Speed, $V_B$" (from 66 ft/s at 0–20,000 ft, angling to 38 ft/s at 50,000 ft) — each line flat below
20,000 ft then linearly decreasing above.

Load factors generated by gust conditions can be more critical than maneuver load factors depending on the
speed, altitude, and wing loading ($W/S$) of the aircraft. In general, aircraft with low wing loading are
more susceptible to being designed by gust loads, and gust velocities are typically higher at altitudes
less than 20,000 feet. Therefore, an aircraft with a lightly loaded wing that generally flies at lower
altitudes is likely to be designed by gust conditions, not flight maneuver conditions. MIL-A-8861 and FAA
FAR Part 25 provide additional guidance on defining gust loads for military and commercial aircraft.
*[Nicolai & Carichner, p. 496]*

The key task of the Loads Engineer is to develop a set of aerodynamic and inertia design loads based on
the flight envelope and intended usage of the aircraft. Aerodynamic and inertia loads that are applied to
the aircraft are referred to as *external loads* to differentiate them from the *internal loads* that are
distributed within the airframe and carried internally by the various structural members. As illustrated
in Fig. 19.3, there are a number of tools available to predict the external design loads, ranging from
computational fluid dynamics (CFD) and other computational methods such as VORLAX (vortex lattice method),
to wind tunnel testing in which the overall forces and moments applied to the vehicle, as well as surface
pressure distributions, can be measured. A set of external load conditions must be defined that cover the
range of flight weights and center-of-gravity locations for the vehicle, as well as all altitudes, speeds,
and possible configurations of flight control surfaces such as ailerons, rudder, flaps, and spoilers. It is
common to utilize all types of loads analysis tools in generating a full

**Fig. 19.3** — *External loads definition process* *[Nicolai & Carichner, Fig. 19.3, p. 497]*. Flowchart:
"Structural Design Criteria" (stack of documents: Customer Requirements, Company Guidelines, FAR Part 25
Airworthiness, MIL-A-8860 through MIL-A-8868) → arrow → "Design Envelope" ($V$–$n$ diagram, Load Factor gs
vs. Speed KEAS) → arrow down → "Analytical Tools" (Wind Tunnel Testing, Potential Flow Codes,
Navier–Stokes Codes — illustrated with an F-22-like CFD surface model and a wind-tunnel schlieren photo of
a supersonic aircraft model) → arrow left → "Airload Distributions" (two spanwise lift-distribution
schematics: "wing–body" with a fuselage circle superimposed on a bell-shaped loading curve, and "wing
alone" with a triangular/tapered loading curve).

This process defines a comprehensive set of external design loads. Wind tunnel testing is commonly used to
define and verify key design points within the flight envelope, and it is often complemented by other
analytical methods, such as CFD and VORLAX, to populate intermediate design points and off-design
conditions.

In addition to the flight and gust loads discussed above, a number of other load types must be defined:
landing and taxi loads, cabin and fuel pressures, crash loads, propulsion system loads, control surface
loads, loads generated by cargo or stores, and loads associated with ground handling activities such as
jacking, hoisting, or towing — see **Fig. 19.4**.

**Fig. 19.4** — *Example of design loads contained in Structural Design Criteria Document*
*[Nicolai & Carichner, Fig. 19.4, p. 499]*. Diagram combining two boxes with a "+" between them, feeding
an arrow down into a third box: (1) "Aerodynamic & Inertia Loads" — a small V-n-style plot (Load Factor
$g$s, $+n_Z$/$-n_Z$, vs. Speed KEAS) with the same flight envelope shape as Fig. 19.1; (2) "Other Design
Loads" — itemized list: Landing & Taxi Loads; Crash Loads; Propulsion-System Loads (sub-items:
Thrust-Reversing Loads, Seizure/Blade-out Loads, Inlet & Exhaust Pressures); Cabin & Fuel Pressures;
Control-Surface Loads (sub-items: Design Hinge Moments, Actuator Stall Loads); Miscellaneous Loads
(sub-items: Jacking & Towing Loads, Seat/Floor/Cargo Loads, Door Loads, Ground Tie-down Loads); combining
to (3) "Structural Design Criteria and Loads Document."

All of these individual load sources are compiled into a single "Structural Design Criteria Document" that
serves as the master source of structural design requirements for the program, ensuring that every load
case considered by every analysis group traces back to one controlled, common set of criteria rather than
each group working from its own interpretation.

While analytical tools (CFD, finite element models, wind tunnel data) are indispensable for defining and
verifying the external loads, sound engineering judgment remains essential — an experienced structures
engineer must recognize when a computed result is physically implausible or when an untested combination
of conditions may drive an unanticipated critical load case.

Low-observable (LO) aircraft impose an additional structural design driver: the allowable surface step,
gap, and waviness tolerances needed to preserve the radar signature are extremely tight, and those
tolerances must be maintained even as the airframe deflects elastically under maneuver and gust loads.
Meeting tight smoothness criteria across the *entire* flight envelope (including high-g maneuver and gust
conditions) can drive substantial structural weight growth (added stiffness to limit deflection). A
common design compromise is to specify the smoothness/signature criteria as applicable only over a reduced
subset of the flight envelope — the conditions most relevant to survivability — rather than the full V-n
envelope, limiting the weight penalty while still meeting the aircraft's low-observable requirements where
it matters most; see **Fig. 19.5**.

**Fig. 19.5** — *V-n diagram showing notional LO design envelope as a subset* *[Nicolai & Carichner,
Fig. 19.5, p. 500]*. V-n diagram: vertical axis "Vertical Load Factor ($g$s)" with marks $+n_Z$, $1.0$, $0$,
$-n_Z$; horizontal axis "Speed (KEAS)". The outer, larger hexagonal envelope is labeled "'Safety-of-Flight'
Structural Design Envelope" (the full flight envelope, same shape as Fig. 19.1). A smaller rectangular
region nested inside it — centered near $n_Z=1.0$ and a mid-range speed band, not extending to the envelope's
speed or load-factor extremes — is labeled "Notional Structural Design Envelope for LO Surface Smoothness,"
illustrating that the tight signature/smoothness criteria are imposed only over this reduced subset of the
full structural envelope.

The airframe must still provide safe operation throughout the full flight envelope, but the airframe weight
does not need to be unduly penalized to meet surface smoothness requirements for relatively short-duration
excursions at the corners of the flight envelope where high-$g$ maneuvers are being performed, or for the
low-speed portions of the flight envelope where deployment of flaps or wing leading-edge (LE) devices might
preclude meeting signature requirements regardless of the smoothness of the outer surface of the aircraft.

Although this example is specific to LO vehicles and the issue of surface smoothness, the same basic
philosophy can be extended to other types of design requirements for all classes of aircraft. Structural
design criteria dictated by safety-of-flight requirements, versus those driven by non-flight-critical
considerations, should be evaluated carefully in this manner to avoid a "worst case on worst case" approach
that can burden the vehicle with overly conservative design requirements resulting in unnecessary
structural weight.

### §19.3 Stress Analysis (p. 500)

The primary objective of stress analysis is to insure that each structural member of the airframe is
properly designed and sized to meet structural requirements with the lowest possible weight. These
structural requirements typically include strength and buckling stability, but they can also include
stiffness and deflection requirements, as well as durability and damage-tolerance analysis (DaDTA)
considerations related to fatigue and crack growth.

*Stress* is simply force (load) per unit area, and it can result from four basic types of loading: tension,
bending, shear, and compression. Fig. 19.6 illustrates these four basic types of loading and provides the
expressions used to compute stress for each.

**Fig. 19.6** — *Basic types of applied loads and stresses* *[Nicolai & Carichner, Fig. 19.6, p. 501]*.
Four-quadrant diagram:
- **Tension** (top-left): a rod loaded axially by force $P$ at each end. Stress = Force/Area,
  $f_{tension} = P/A$ (unnumbered equation, inset on Fig. 19.6). Failure Mode: Strength.
- **Bending** (top-right): a curved beam segment loaded by moments $M$ at each end, tension on the outer
  (convex) fiber and compression on the inner (concave) fiber, with $c$ = distance to neutral axis.
  Stress = $f_{bending} = Mc/I$ (unnumbered equation, inset on Fig. 19.6), where $M$ = applied moment,
  $c$ = distance to neutral axis, $I$ = moment of inertia; inset rectangular cross-section of width $b$ and
  height $h$ gives $I = bh^3/12$. Failure Mode: Strength (tension side); Local Buckling Stability
  (compression side).
- **Shear (in-plane)** (bottom-left): a square element loaded by shear flows $N_{xy}$ ($=q$) on all four
  edges, reducing to two resultant diagonal loads. $f_{shear} = N_{xy}/\text{thickness}$ (unnumbered
  equation, inset on Fig. 19.6). Failure Mode: Buckling Stability (for thin sheet).
- **Compression** (bottom-right): a rod loaded axially in compression by $P$ ($f_{compression} = P/A$,
  unnumbered equation, inset on Fig. 19.6), and a flat sheet/panel loaded in-plane by distributed
  compressive load $N_x$. Failure Mode: Buckling Stability (for thin sheet structure and slender columns).

Any single structural member in an airframe will likely be subjected to some combination of these four
types of loads for any single design condition. Therefore, the challenge of stress analysis is to
understand the interaction of the different types of load, anticipate the potential failure modes of the
structural member, design the structural member so that failure does not occur within a specified design
envelope, and minimize the structural weight of the component.

The failure mode for tension loading is typically material strength, either tension ultimate strength or
tension yield strength. For compression loading the failure mode is usually buckling instability, either
global or local buckling instability. Bending results in both tension and compression stress, as shown in
Fig. 19.6. Depending on the configuration of the structural member to which the bending moment is applied,
the failure mode can be either strength (at the tension side) or local buckling instability (compression
side). An in-plane shear load can also be resolved into tension and compression loads as shown in
Fig. 19.6. Therefore, for a thin-sheet structure such as a wing or fuselage skin, the failure mode for
in-plane shear loading is usually buckling instability caused by the resultant compression loads. The key
point is that buckling instability, and not necessarily material strength, can be the governing failure
mode for a significant amount of an airframe, especially if constructed of lightweight, thin-sheet
structure. As an example, Fig. 19.7 lists the various failure modes, and the percentage of airframe
structural weight driven by that failure mode, for the Lockheed Martin S-3A Viking aircraft [5]. This data
illustrate that only 30% of the airframe structural weight for this particular aircraft is driven by
tension strength, but over 40% of the weight is driven by buckling stability. These characteristics are
typical of many other airframe designs.

The concept of limit load vs ultimate load is fundamental to understanding aircraft stress-and-loads
analysis. *Limit load* is defined as the maximum load that an airframe will experience anytime during its
service life. *Ultimate load* is simply limit load multiplied by a factor-of-safety. The *ultimate
factor-of-safety* is typically 1.5 for manned aircraft and 1.25 for unmanned aircraft. However, there are
many other factors that may be required depending on the type of structure and type of loading. For
example, compartments subjected to internal pressure, such as pressurized passenger cabins or crew
compartments, are usually required to be designed to withstand a *proof pressure* that is 1.33 times the
maximum attainable pressure and a *burst pressure* that is 2.0 times the maximum attainable pressure. The
MIL-8860 series of documents provides guidance on many of these other factors required for structural
design.

For strength-critical components, stresses resulting from limit load and ultimate load are compared with
the yield and ultimate strength of the particular material from which the component is constructed.

**Fig. 19.7** — *Airframe structural weight per failure mode for S-3A aircraft* *[Nicolai & Carichner,
Fig. 19.7, p. 503]*. Photo of a Lockheed Martin S-3A Viking taking off from a carrier deck, with an inset
table:

| Failure Mode | % Airframe Weight |
|---|---|
| Tensile Strength | 30.1% |
| Compressive Strength | 0% |
| Buckling Stability | 42.1% |
| Aeroelastic Stiffness | 14.1% |
| Durability & Damage Tolerance | 13.7% |

*[Nicolai & Carichner, Table (untitled, inset on Fig. 19.7), p. 503]*

Figure 19.8 shows a stress-strain curve for a typical ductile material. The *yield stress* is defined as
the point on the stress-strain curve at which permanent deformation starts to occur (also called *plastic
deformation*). Structural design criteria for most aircraft state that no detrimental permanent deformation

**Fig. 19.8** — *Engineering stress-strain curve for a ductile material* *[Nicolai & Carichner, Fig. 19.8,
p. 503]*. Stress (vertical axis) vs. Strain (horizontal axis) curve for a ductile material: a straight line
from the origin through the "Linear Elastic Range" up to the "Yield Point" (dashed lines to "Yield
Strength" on the stress axis), continuing as a curved "Plastic Range" that rises to a peak at "Ultimate
Strength" (dashed line to the stress axis) then descends to a point marked "Failure."

is allowed at, or below, limit load and no failure at, or below, ultimate load [6]. This implies that
yielding of the material may be allowed above limit load. However, some yielding may be allowed below limit
load provided that the permanent deformation does not interfere with safe operation of the aircraft.

*Margin-of-safety* is a measure of how much capability a structural component possesses in excess of design
requirements. For structural components, margin-of-safety is usually expressed in terms of a material
*allowable* (for example, a material strength allowable such as ultimate strength or yield strength)
compared against an applied stress:

$$\text{Margin-of-Safety (M.S.)} = \frac{\text{Allowable Stress}}{\text{Applied Stress}} - 1.0$$
*(unnumbered equation, p. 504)*

Margin-of-safety should not be confused with factor-of-safety; the two quantities serve two distinctly
different purposes.

#### Example 19.1 — Margin-of-Safety (p. 504)

Consider a rod with a 1.0-in.² cross section, loaded in tension with 40,000 lb, as shown in Fig. 19.9.

Limit load for this example is 40,000 lb and ultimate load is $1.5 \times 40{,}000\text{ lb} = 60{,}000$ lb.
Based on these applied loads, the tension stress at limit load is calculated to be
$40{,}000\text{ lb}/1.0\text{ in.}^2 = 40{,}000$ psi, and the stress at ultimate load is
$60{,}000\text{ lb}/1.0\text{ in.}^2 = 60{,}000$ psi. The Structural Design Criteria state that permanent
deformation is not allowed below limit load and failure is not allowed below ultimate load. Therefore, the
two margins-of-safety are

$$\text{M.S. (Yield Strength)} = \frac{48{,}000\text{ psi}}{40{,}000\text{ psi}} - 1.0 = +0.20$$
*(unnumbered equation, p. 504)*

$$\text{M.S. (Ultimate Strength)} = \frac{63{,}000\text{ psi}}{60{,}000\text{ psi}} - 1.0 = +0.05$$
*(unnumbered equation, p. 504)*

Yield strength is compared against applied limit stress, and ultimate strength is compared against applied
ultimate stress, resulting in margins-of-safety of +20% and +5%. Unless specified otherwise in the Design
Criteria, it is permissible to drive all margins as close to zero as possible for minimum weight. Therefore,
the cross-sectional area of the rod could be reduced slightly from 1.0 in.² to 0.96 in.², resulting in a
margin of 0% at ultimate and +15% at limit. Additional reduction in cross-sectional area to bring the yield
margin closer to zero would result in a negative margin at ultimate load, which is unacceptable in

**Fig. 19.9** — *Example of design criteria and allowables* *[Nicolai & Carichner, Fig. 19.9, p. 505]*.
Rod of Cross-Sectional Area $A = 1.0$ in.², loaded axially in tension by $P = 40{,}000$ lb at each end,
$f_{tension}=P/A$. Alongside: "Design Criteria" — Ultimate Factor-of-Safety = 1.5; No Yielding at or Below
Limit Load; No Failure at or Below Ultimate Load. "Material Design Allowables" — Tension Ultimate Strength
$= F_{tu} = 63$ ksi; Tension Yield Strength $= F_{ty} = 48$ ksi.

this example. In all cases, however, the ultimate factor-of-safety is unchanged at 1.5.

Example 19.1 illustrates several key points related to stress analysis and sizing of airframe structure:
(1) There are usually multiple failure modes, and therefore multiple margins-of-safety, for every
structural member. (2) It is desirable to drive the margins-of-safety to zero for minimum weight. (3) It
is virtually impossible to drive all margins for all failure modes of a particular structural member to
zero at the same time. Therefore, it is important to determine which margins drive the weight of the
component and, therefore, warrant the highest priority for being minimized.

Material strength allowables for metallic materials commonly used in the aerospace industry can be found
in the government handbook "Metallic Materials Properties Development and Standardization" or MMPDS [7].
Prior to 2004, the MMPDS was known as MIL-HDBK-5 "Metallic Materials and Elements for Aerospace Vehicle
Structures." The MMPDS is a source of metallic material and fastener allowables for aluminum, titanium,
steel, and high-temperature alloys and is accepted by the Federal Aviation Administration (FAA), all
departments and agencies of the Department of Defense (DoD), and the National Aeronautics and Space
Administration (NASA).

An example of a typical material allowable data sheet found in the MMPDS is shown in Table 19.1. The
headings "A" and "B" near the top of the MMPDS data sheet refer to the statistical basis used in generating
the material design allowable. *A-basis allowables* are defined as those for which 99% of the material
population is expected to equal or exceed the stated allowable with a 95% confidence level; *B-basis
allowables* are defined as those for which 90% of the material population is expected to equal or exceed
the allowable with 95% confidence. For most airframe primary and secondary structure, B-Basis allowables
are used for design. However, A-basis allowables may be required for a single-load path, safety-of-flight
structure, depending on customer requirements and company design policy.

Compared with strength analysis, determination of the buckling stability of a structure can entail a
more-involved analysis. There are several forms of buckling instability, such as shear and compression
buckling of thin skins or webs, local "crippling" buckling of beam flanges, torsional buckling of
open-section columns, and Euler buckling of slender columns loaded in compression, and there are numerous
analytical and empirical methods available for addressing each of these types of buckling instability.
Unlike yield or ultimate strength, which is an inherent property of a material, the allowable buckling
load is dependent on material properties (such as compression modulus $E_c$ or shear modulus $G$), the
geometry of the structural member, and the boundary conditions of the member (usually defined as fixed,
simply supported, or free). Also, unlike strength analysis, where there is often a clear "not-to-exceed"
strength allowable, it is possible for a structure to experience certain types of buckling and still carry
100% of the required load. Therefore, provided the buckling does not initiate a global instability leading
to catastrophic structural failure, it may be permissible to allow buckling below ultimate or limit load.
Understanding and taking advantage of this "postbuckled" capability to achieve minimum weight are key
features that separate aircraft structural design philosophy from other forms of structural design.

*(Table 19.1, "example of a typical material allowable data sheet found in the MMPDS," is referenced here
in the text on p. 506 but its tabular content appears later in the chapter — see below.)*

### §19.4 Finite Element Modeling (p. 507)

Finite element modeling is arguably the most powerful analytical tool available to the stress engineer. The
theory of finite element modeling is based on the fundamental mechanics-of-materials relationship:

$$\text{Force} = \text{Stiffness} \times \text{Displacement}$$
*(unnumbered equation, p. 507)*

which can be expressed in matrix notation as

$$\{\mathbf{F}\} = [\mathbf{K}] \times \{\mathbf{d}\}$$
*(unnumbered equation, p. 507)*

A *finite element model* (FEM) is a mathematical representation of the airframe structure in terms of a
stiffness matrix $[\mathbf{K}]$. Once this stiffness matrix is defined, forces $\{\mathbf{F}\}$ can be
applied to the FEM (commonly in the form of external loads supplied by the Loads Group), and displacements
$\{\mathbf{d}\}$ can be solved. From displacements the stresses and loads in each individual structural
member in the FEM can then be determined.

As with any analytical tool, the results of a FEM are only as accurate as the input data and the fidelity
of the model itself. FEM results can be greatly affected by the types of elements used in the model, mesh
density, and model boundary conditions. Therefore, it is always good practice to perform a first-order hand
analysis of the problem being modeled to provide a sanity check of the FEM results.

Finite element models can range from a detailed model of a fitting to a complete airframe, as shown in
Fig. 19.10. A full-vehicle FEM is typically used to determine the load distribution within the airframe and
is commonly called an *internal loads model*. An internal loads FEM will include a set of external-loads
cases (represented by the $\{\mathbf{F}\}$ matrices) that cover all the critical conditions to which the
airframe must be designed. These load conditions typically include symmetric and unsymmetric flight
maneuvers, internal pressures (such as cabin pressures), propulsion system loads, landing loads, ground
handling loads, and any other loading condition that

**Table 19.1** — *Design Mechanical and Physical Properties of Clad 2024 Aluminum Alloy Sheet and Plate*
*[Nicolai & Carichner, Table 19.1, p. 508]*. MMPDS-style data sheet, Specification QQ-A-250/5, Form: Flat
sheet and plate. Two temper groups: **T3** (thickness 0.008–0.062 in., in two thickness bins) and **T351**
(thickness 0.063–4.000 in., in seven thickness bins); each thickness bin gives an A-basis and B-basis
allowable.

*Mechanical Properties* (all values ksi; columns are thickness bins 0.008–0.009 / 0.010–0.062 / 0.063–0.128
/ 0.129–0.249 / 0.250–0.499 / 0.500–1.000 / 1.001–1.500 / 1.501–2.000 / 2.001–3.000 / 3.001–4.000, each as
A/B):

- $F_{tu}$ (ultimate tensile strength):
  - L: 59/60, 60/61, 62/63, 63/64, 62/64, 61/63, 60/62, 60/62, 58/60, 55/57
  - LT: 58/59, 59/60, 61/62, 62/63, 62/64, 61/63, 60/62, 60/62, 58/60, 55/57
  - ST: —, —, —, —, —, —, —, —, 52/54, 49/51
- $F_{ty}$ (tensile yield strength):
  - L: 44/45, 44/45, 45/47, 45/47, 46/48, 45/48, 45/48, 45/47, 44/46, 39/41
  - LT: 39/40, 39/40, 40/42, 40/42, 40/42, 40/42, 40/42, 40/42, 40/42, 39/41
  - ST: —, —, —, —, —, —, —, —, 38/40, 38/39
- $F_{cy}$ (compressive yield strength):
  - L: 36/37, 36/37, 37/39, 37/39, 37/39, 37/39, 37/39, 36/38, 35/37, 33/35
  - LT: 42/43, 42/43, 43/45, 43/45, 43/45, 42/45, 42/44, 42/44, 41/43, 39/41
  - ST: —, —, —, —, —, —, —, —, 46/48, 44/47
- $F_{su}$ (ultimate shear strength): 37/37, 37/38, 38/39, 39/40, 37/38, 36/37, 35/37, 35/37, 34/35, 32/34
- $F_{bru}$ (ultimate bearing strength):
  - $(e/D=1.5)$: 96/97, 97/99, 101/102, 102/104, 94/97, 92/95, 91/94, 91/94, 88/91, 83/86
  - $(e/D=2.0)$: 119/121, 121/123, 125/127, 127/129, 115/19 *(sic — "19" as printed; likely a typo for 119)*,
    113/117, 111/115, 111/115, 107/111, 102/106

L = longitudinal (rolling) direction; LT = long-transverse; ST = short-transverse. Dashes indicate the
allowable is not published for that thickness/direction combination.

**Table 19.1 (continued, p. 509)** — remaining rows of the same data sheet:

- $F_{bry}$ (bearing yield strength):
  - $(e/D=1.5)$: 68/70, 68/70, 70/73, 70/73, 69/72, 69/72, 69/72, 69/72, 69/72, 67/70
  - $(e/D=2.0)$: 82/84, 82/84, 84/88, 84/88, 82/86, 82/86, 82/86, 82/86, 82/86, 80/84
- $e$, percent (S-basis), LT direction only (A-basis; B dashed throughout): 10, —, 15, 15, 12, 8, 7, 6, 4, 4
  (across the ten thickness bins in order; B-basis column dashed in every bin)
- $E$ (tensile modulus), $10^3$ ksi: Primary = 10.5 for the T3 bins (0.008–0.062 in.), 10.7 for the T351
  bins (0.063–4.000 in.); Secondary = 9.5 (0.008–0.009), 10.0 (0.010–0.128 combined range as printed),
  10.2 for the remaining T351 bins (0.500–4.000 in.)
- $E_c$ (compressive modulus), $10^3$ ksi: Primary = 10.7 (T3 bins), 10.9 (T351 bins); Secondary = 9.7
  (0.008–0.009), 10.2 (0.010–0.128), 10.4 (0.500–4.000)
- $G$ (shear modulus), $10^3$ ksi: value cell present but blank/not printed in this excerpt
- $\mu$ (Poisson's ratio): 0.33 (single value spanning all thickness bins)

*Physical Properties*:
- $\omega$ (density): 0.101 lb/in.³ (single value spanning all thickness bins)
- $C$, $K$, and $\alpha$ (thermal properties): — (not published on this data sheet)

**Fig. 19.10** — *Types of structural finite element models* *[Nicolai & Carichner, Fig. 19.10, p. 510]*.
Three silhouettes side by side: "Full Vehicle FEM" (a complete aircraft outline), "Structural Component
FEM" (a fuselage-section-like solid shape), "Structural Element FEM" (a single detail-fitting-like solid
shape) — all feeding down into a common "FEM Output" band listing: Internal Load Distribution, Mode Shapes
& Frequencies, Strains & Displacements, Stress Distribution, Buckling Eigenvalues.

...might drive the structural design of the airframe. The possible range of gross weights and c.g.
locations for the aircraft are also commonly included in these FEM runs. Once the internal loads are
defined, the stress engineer will use this information to calculate stresses and perform detailed stress
analysis and sizing of structure.

### §19.5 Structural Joints (p. 510)

Sizing of major structural members such as skins, frames, bulkheads, and spars is a major focus of stress
analysis, but proper design and analysis of structural joints is also of critical importance to the
structural integrity of an airframe. A structure is only as good as its weakest link, and joints can be a
common cause of structural failure if not addressed correctly. The majority of airframe structural joints
fall into three primary categories: *mechanically fastened* joints, *adhesively bonded* joints, and *welded
or brazed* joints. Although it is not uncommon for all three types of joints to be found in any particular
aircraft, mechanically fastened and adhesively bonded are usually more prevalent in airframe primary
structure.

Potential failure modes for mechanically fastened joints are illustrated in Fig. 19.11. Fastener shear
failures can be precluded by selecting a

**Fig. 19.11** — *Failure modes of mechanically fastened joints* *[Nicolai & Carichner, Fig. 19.11,
p. 511]*. Six illustrated joint failure modes: **Shear-out Failure** (fastener hole tears out toward the
sheet edge under load); **Tension Failure** (sheet fractures across its net section through the fastener
hole); **Bearing Failure** (fastener hole elongates/deforms under bearing load, hole shown deformed);
**Cleavage-Tension Failure** (a crack propagates from the fastener hole to the sheet edge); **Bolt
Pull-Through Failure** (side view: bolt head pulls through/deforms the top sheet under tension load); **Bolt
Shear Failure** (side view: the bolt shank itself shears off between the two joined sheets).

fastener of appropriate diameter and shear strength to carry the required loads. Bearing failures can be
precluded by selecting a fastener of appropriate diameter and by maintaining sufficient thickness in the
parts being joined together. Design guidelines regarding fastener minimum spacing,
minimum edge distance, fastener type (e.g., tension head vs shear head), and minimum sheet thickness for
countersunk fasteners help guard against many of the other failure modes shown in Fig. 19.11, but it is the
responsibility of the stress engineer to insure the joint is analyzed and sized properly to preclude all
possible failure modes.

*Bearing stress* results from the fastener shank compressing ("bearing") against the side of the hole as
load transfers between plates. A *bearing failure* is a local compression-like failure of the plate/skin.
Good practice is to design a fastened joint to be *bearing-critical* — sized so a bearing failure occurs
before the other failure modes in Fig. 19.11, giving a degree of fail-safety since a bearing-critical joint
stays intact and can still transfer load even if overloaded, until repair.

**Fig. 19.12** — *Bearing stress equation for a single lap shear joint* *[Nicolai & Carichner, Fig. 19.12,
p. 512]*. Single-lap-shear joint sketch: two overlapping sheets of thickness $t$ joined by one fastener,
loaded in tension by $P$ at each end.

$$\text{Bearing Stress} = f_{br} = \frac{P}{Dt}$$
*(unnumbered equation, inset on Fig. 19.12, p. 512)*

where $P$ = axial load, $D$ = fastener diameter, $t$ = skin thickness. For a given applied load, the two
parameters that can be adjusted to determine bearing stress are the fastener diameter and the thickness of
the joined parts.

Bonded joints are usually preferred over fastened joints for laminated composite materials (e.g.,
graphite-epoxy), due to their relatively poor bearing strength — poor bearing strength can necessitate
localized thickness increases and more/larger fasteners, adding weight. However, bonded joints in primary
structure demand strict adherence to proven manufacturing process specs and NDI (nondestructive inspection)
to confirm bond reliability.

Stress analysis of bonded joints focuses on the shear stress distribution in the adhesive layer, discussed
next with Fig. 19.13.

**Fig. 19.13** — *Bonded-joint shear stress distribution* *[Nicolai & Carichner, Fig. 19.13, p. 513]*.
Single-lap bonded joint: two overlapping sheets joined by an "Adhesive Layer," loaded in tension by $P$ at
each end, with "Load Transfer by Shear" annotated at the bond. Above the joint, a plotted "Adhesive Shear
Stress" curve is roughly U-shaped/basin-shaped across the bond overlap length — low/near-uniform in the
middle, rising sharply to peaks at each end — annotated "Adhesive shear stress peaks occur at edges of
bond."

This shear stress may not be uniform and can peak near each end of the bonded joint. Simply increasing bond
area via overlap length may not sufficiently reduce peak shear stresses below the adhesive shear strength
allowable. Tailoring the stiffness of the bonded components (e.g., tapering each end of the joint, or
optimizing the composite layup) is often used to reduce this peaking and minimize out-of-plane "peel"
stresses that can cause premature bondline failure.

Detailed design and analysis of structural joints is usually not performed in the Conceptual Design phase,
but it is important to identify the basic joining methods early. Both bonded and fastened joints represent
a source of structural inefficiency, so minimizing the number of joints is desirable for weight; however,
manufacturing constraints on part size, material billet-size limits, and maintainability (ease of replacing
damaged components) may increase joint count/influence joint location — appropriate topics for structural
and manufacturing trade studies during Conceptual Design. Joint concepts critical to structural viability
are likely candidates for component-level development testing in Preliminary Design, and planning for such
tests (long-lead materials, specimen design) may need to start during Conceptual Design to meet downstream
schedule milestones.

### §19.6 Durability and Damage Tolerance (p. 513)

*Durability and damage tolerance analysis* (DaDTA) addresses issues such as fatigue and other types of
structural damage that may be incurred during operation of the aircraft. For a demonstrator aircraft with a design
life of ~100 flight hours, fatigue's influence on airframe design is likely minimal. For an operational
aircraft with tens of thousands of flight hours, fatigue considerations can drive structural concept and
material selection and significantly affect structural weight.

Two terms matter for satisfying DaDTA requirements: *fail safe* and *safe life*. Fail-safe design aims for
a structure that, even if damaged to a limited extent, can still carry a reasonable percentage of design
load to allow emergency landing/return to base — complete failure of any single member is made safe by
alternate load paths. Redundant load paths carry a weight penalty, which can be mitigated by applying
fail-safe philosophy only to selected areas rather than the whole airframe.

*Safe life* relies heavily on fatigue/crack-growth analysis to show the airframe meets design-life
requirements, plus inspection intervals to catch premature fatigue damage before it becomes critical.
Components may need replacement once predicted fatigue life is expended, even absent visible damage. Safe
life is often lighter than fail-safe (no redundant load paths needed), but is analysis-intensive and
requires detailed definition of planned operational usage to build the repeated-loads spectrum needed for
crack-growth analysis.

### §19.7 Mass Properties (p. 514)

The universal challenge for all aircraft development programs is achieving vehicle weight and performance
while staying within program cost and schedule constraints. Achieving minimum weight structure is always a
top priority for the Aircraft Structures engineer, and every decision made during the design process should
be balanced against its potential impact on weight.

Several weight-prediction methods are used as a vehicle progresses through the design cycle, as illustrated
in Fig. 19.14. During Conceptual Design, the predominant method for predicting weight is based on
parametric equations — Chapter 20, "Refined Weight Estimate," contains a detailed discussion of parametric
weight-estimating methods for both air-
frame structure and subsystems, and provides parametric weight equations for wing, fuselage, and empennage
structure as well as propulsion system components, surface controls and hydraulics, avionics, electrical
system, and various furnishings such as seats, windows, and cargo-handling provisions.

**Fig. 19.14** — *Weight-estimating methods utilized throughout the design cycle* *[Nicolai & Carichner,
Fig. 19.14, p. 515]*. A stepped bar chart across three design phases — Conceptual Design, Preliminary
Design, Detail Design & Fab — each phase a progressively shorter/lower bar, annotated below with the
corresponding weight-estimating method: "Parametric Weight" (Conceptual), "'Bottom-up' Weight"
(Preliminary), "Actual Weight" (Detail Design & Fab). A shaded band under the bars transitions
gray-to-black left to right, labeled at the left "Opportunity to Reduce Weight with Minimal Program Impact"
(large during Conceptual Design, shrinking sharply thereafter). Below, a three-column legend:

| Parametric Weight | "Bottom-up" Weight | Actual Weight |
|---|---|---|
| Empirical equations based on historical databases | Calculated weight based on design definition of individual components | Weighing of "as built" flight hardware |

Because parametric weight equations are based on actual weights of previously developed aircraft, there is
a risk they may not accurately predict the weight of a new, unconventional configuration falling well
outside the existing database of aircraft. In these cases, it is advisable to validate the parametrically
estimated weight with a "bottom-up" weight analysis.

A *structural bottom-up weight* is composed of calculated weights for each structural member (frames,
spars, keelsons, ribs, longerons, skins, etc.) based on sufficient design definition for each member,
supported by stress sizing. The weight of each component is then summed to a total weight built from the
bottom up.

Fig. 19.14 also highlights that the opportunity for reducing weight without major impact to program cost
and schedule decreases drastically as the design matures. Design decisions made early in a program often
"lock in" the final product's weight. A useful philosophy for controlling structural weight in these early
phases is to approach the airframe design from the "light side" — initiate with the minimum structural
sizing (skin thickness, cap area, stiffener count, etc.) deemed necessary to satisfy requirements, so that
any additional structure or sizing increase later must "earn its way" onto the vehicle as the configuration
matures. This philosophy contrasts with
the approach of starting with an overdesigned structure and presupposing weight will be reduced as the
design matures — in effect, approaching weight from the "heavy side," which rarely leads to a true minimum
weight design. Once a superfluous capability or design feature finds its way into a design, it can be very
difficult to isolate and remove during later design stages with stakeholder consensus.

### §19.8 Flutter and Dynamics (p. 516)

*Aeroelasticity* refers to the structural response of a flexible airframe when subjected to aerodynamic
forces. As illustrated in Fig. 19.15, several types of aeroelastic phenomena can occur: flutter, divergence,
control reversal, and aero-propulsion-servo-elasticity (APSE).

*Flutter* is a dynamic instability of an elastic structure in an airstream; it occurs when the phasing
between motion and aerodynamic loading extracts an amount of energy from the airstream equal to the energy
dissipated by damping within the structure. *Divergence* occurs when a wing/aerosurface's torsional
stiffness is insufficient to maintain a statically stable position as aircraft speed increases.

*Control reversal* is also related to insufficient torsional stiffness, characterized by movement opposite
to the desired direction based on control input. *APSE* is the coupling of the airframe aeroelastic
response with the dynamic characteristics of the flight control and propulsion systems.

**Fig. 19.15** — *Types of aeroelastic behavior* *[Nicolai & Carichner, Fig. 19.15, p. 516]*. Three boxed
panels plus a circular emblem:
- **Flutter**: sequence of an airfoil section along a flight-direction arrow, shown pitching/plunging with
  oscillating vertical displacement/velocity ($z$, $\dot z$) arrows at two stations, illustrating a growing
  oscillatory divergent motion.
- **Divergence**: an airfoil section under an upward "Airload" arrow near the leading edge, twisting
  progressively nose-up (increasing angle of attack) through successive depictions, feeding back into more
  airload.
- **Control Reversal**: an airfoil with a trailing-edge control surface deflected, shown twisting the main
  surface in a sense that reverses the intended control effect.
- **Aero-Propulsion-Servo-Elasticity** emblem: a circular seal with "APSE" at the center, ringed by the text
  "Structural Mode Control - Aeroelastic Tailoring - Flight Controls - Ride Quality - Load Control - Engine
  Control - Control-Handling Qualities."

Detailed evaluation of any of these aeroelastic phenomena requires considerable structural design
definition, particularly the vehicle's mass and stiffness distribution. Consequently the Conceptual Design
phase, where such detail is often unavailable, has historically contained minimal aeroelastic analysis.
Skipping detailed aeroelastic analysis at Conceptual Design probably introduces minimal program risk if the
configuration resembles previous flight-proven designs.

However, for new aircraft with very unconventional features — extremely thin wings, extremely slender
fuselages, nontraditional control surfaces, or unconventional placement of large mass items (e.g., engines)
— it is imperative to perform at least a first-order aeroelastic analysis, to build confidence in design
feasibility and capture weight penalties for added structural stiffness. This first-order analysis
typically evaluates the $EI$ (bending stiffness) and $GJ$ (torsional stiffness) of the wing, fuselage, and
tail structure, and may use a simple "stick model" FEM representing wing/fuselage/tail with beam elements.

*Structural dynamics* is concerned with the vibration, shock, and vibroacoustic environment of the vehicle
structure and subsystems. As with aeroelastic analysis, little dynamics analysis is usually needed at
Conceptual Design if configuration and flight environment are fairly conventional. The vibration/shock
environment is usually more of a driver for subsystem component design/mounting (avionics, electrical).

Although primary structure is rarely sized by vibration or shock environment, high vibroacoustic levels can
drive skin thickness and stiffener spacing (e.g., structure near the exhaust system). For unconventional
configurations/operating environments — such as higher-than-normal acoustic levels from a new propulsion
concept — a preliminary structural dynamics evaluation may be needed to insure vehicle feasibility and
capture all associated weight penalties.

### §19.9 Structural Layout (p. 517)

Major load paths of an airframe are defined by a *structural layout drawing*, sometimes called a
structural "bones" drawing. As the basic vehicle configuration develops, it is important to define these
load paths to insure adequate volume is reserved within the vehicle for primary structure (frames,
bulkheads, keelsons, spars, ribs), and that major design features/subsystems (engine, landing gear,
inlet-and-exhaust structure) are successfully integrated into the design.

The structural layout philosophy used for different aircraft varies, but several recurring themes can be
discerned for wing and fuselage structure across many aircraft. Lessons-learned and optimization of
airframe structure over many years have generated basic structural layout approaches demonstrated to
achieve minimum weight with superior strength and stiffness.

#### §19.9.1 Wing Structure (p. 518)

Wing structure can account for as much as half of the total structural weight of an aircraft, so selecting
the most weight-efficient structural layout for the wing is always a high priority. For most conventional
aircraft, two basic wing structural layouts are most prevalent: the multi-rib wing and the multi-spar wing,
shown in Fig. 19.16.

The *multi-rib wing* typically features two spars (forward and rear, with a third intermediate spar
sometimes present), upper and lower stiffened wing covers (skins), and numerous ribs generally oriented
chordwise. Taken together, this system of spars, ribs, and skins is called the *wing box*. The spars'
primary function is to carry vertical shear ($P_z$, carried in the spar webs) and a percentage of wing
spanwise bending ($M_x$, carried in the spar caps).

The wing upper and lower covers react most of the spanwise bending loads via tension and compression — e.g.,
a wing upbending moment is reacted by compression in the upper skin and tension in the lower skin. The wing
cover features a thin skin with discrete spanwise stiffeners for buckling stability. The ribs' primary
function is to support the wing skins against global buckling when loaded in compression. Torsional
stiffness of the wing is provided by the wing box acting as a torque box, carrying torsional ($M_y$) loads
as shear distributed around the box periphery.

Multi-rib wings are commonly found in transport-type aircraft with relatively high aspect ratio, generous
thickness-to-chord wings, typically subjected to moderate spanwise bending loads (design vertical load
factor $n_z$ less than 6.0 $g$).

*Multi-spar wings*, by contrast, are common in high-speed/fighter aircraft with relatively thin, highly
loaded wings. Upper/lower skins tend to be thicker than a multi-rib design's covers and in many cases need
no discrete stiffening beyond the multiple spars themselves. The tight spar spacing plus thicker skins
precludes the need for tightly spaced ribs to resist column buckling of the skins; however, some ribs may
be present in

**Fig. 19.16** — *Wing structural configurations* *[Nicolai & Carichner, Fig. 19.16, p. 519]*. Two-panel
comparison:

**Multi-Rib-Wing** (top): a wing planform cutaway showing closely spaced chordwise **Rib**s, and a wing-box
cross-section labeled Fwd Spar, Aft Spar, Upper Cover, Lower Cover, Stiffener, Wing Box. Callouts: "Upper &
Lower Covers" carry spanwise bending ($M_x$) loads (reacted as tension/compression) and wing torsional
($M_y$) loads (reacted as shear around the wing box periphery); "Ribs" support upper/lower covers for
increased buckling stability and maintain airfoil shape.

**Multi-Spar-Wing** (bottom): a wing planform cutaway showing multiple closely spaced spars running
spanwise (a "Section A-A" cut called out near the root), and a spar-bay cross-section labeled Spar Cap,
Spar Web, Upper Cover, Lower Cover. Callouts: "Spars" — spar webs carry vertical ($P_z$) loads from lift;
spar caps work with wing covers to carry spanwise bending ($M_x$). "Other Design Considerations" (listed
alongside the multi-rib panel, applicable generally): wing attachment concept (tension joint vs shear
joint); fuel pressures; landing gear installation; leading & trailing edge surfaces & actuation; access
panels.

The multi-spar design's ribs may also serve as attachment points for external stores, or as back-up
structure for leading/trailing-edge control surfaces and actuation.

Cutaway drawings of many aircraft illustrate these two popular wing structural layouts, but notable
exceptions exist. Some aircraft combine both concepts — multi-spar for thin outboard sections, multi-rib
for thicker inboard sections. Extremely lightweight aircraft such as sailplanes typically use neither,
instead a single spar supporting sandwich wing covers requiring few, if any, ribs for buckling stability.

Figure 19.17 shows a single-spar wing typical of many sailplane designs. Extremely low wing structural
weights have been achieved on high-altitude long-endurance (HALE) vehicles using the tubular-spar concept
also shown in Fig. 19.17. Although somewhat similar in appearance to a multi-rib design, the wing skins in
this concept act only as an aerodynamic covering, with all wing bending and torsional loads carried by the
single tubular spar.

This wing structural approach is especially attractive for span-loader vehicle configurations such as the
AeroVironment Centurion and Helios vehicles (see Chapter 20, Fig. 20.1) that distribute vehicle mass across
the entire wing span, reducing wing spanwise bending ($M_x$) moments.

**Fig. 19.17** — *Ultralightweight wing structure concepts* *[Nicolai & Carichner, Fig. 19.17, p. 520]*.
Two panels:

**Single-Spar Design**: a wing cutaway with a single vertical spar just aft of the leading edge, a
"'D' Section Torque Box" formed by the leading-edge skin around the spar, and "Sandwich Skin" covering the
rest of the wing surface.

**Tubular-Spar Design**: a wing cutaway with a single circular "Tubular Spar" near the leading edge,
triangulated "Truss Rib" webs connecting it to a thin "Membrane Skin" covering, and a "Sandwich Leading
Edge" section ahead of the spar.

Although the various wing structural concepts presented here offer a good starting point, the final choice
of wing structural layout for a particular aircraft should be supported by trade studies and weight
optimization given the specific wing geometry and loads. Other design issues — integration of landing gear,
propulsion, fuel system into the wing — can also drive the preferred wing structural concept.

#### §19.9.2 Fuselage Structure (p. 521)

Fuselage structure also accounts for a significant percentage of airframe structural weight and can be
subject to more demanding subsystem integration challenges than wing structure — especially true for
densely packed fighter-type aircraft, where integration of inlet, cockpit, engine, internal stores, landing
gear, and other subsystems can greatly affect available structural layout options.

As with wing structure, there are several recurring themes for fuselage structural layouts across many
aircraft types. Three design approaches — skin-stringer, frame-longeron, and sandwich-skin fuselage — are
shown in Fig. 19.18.

The *skin-stringer approach* is typical of many commercial airliners. Longitudinal stringers, together with
the skin, react fuselage bending ($M_y$ and $M_z$) loads. The frames' primary function is to reduce
stringer column length for improved buckling resistance and to maintain overall fuselage shape. Fuselage
torsional ($M_x$) loads are reacted in the skin as shear, and internal cabin pressure loads are primarily
carried in the skins in hoop tension (for circular-cross-section fuselages).

The *frame-longeron approach* is very similar to skin-stringer except the axial-load-carrying function of
the numerous stringers is consolidated into discrete longerons. This may be preferred if fuselage
longitudinal bending loads are relatively low (weight-efficient stringers become hard to design/manufacture
due to material minimum-gage limits), or if the fuselage has numerous door/window cutouts (longerons can be
positioned above/below cutouts for an uninterrupted axial load path). Optimum frame spacing for
frame-longeron is typically less than for skin-stringer, since skin between frames is less supported,
requiring closer frame spacing for equal buckling capability.

**Fig. 19.18** — *Fuselage structural configurations* *[Nicolai & Carichner, Fig. 19.18, p. 522]*.
Three fuselage-section cutaways:

**Skin-Stringer Approach**: thin sheet skin with closely spaced longitudinal **Stringer**s and **Frame**s
(frames shown as circumferential rings, stringers as longitudinal lines).

**Frame-Longeron Approach**: thin sheet skin with fewer, discrete **Longeron**s replacing the stringers,
and frames spaced more closely than in the skin-stringer panel — annotated "Reduced frame spacing compared
with skin-stringer."

**Sandwich Skin Approach**: a sandwich-skin panel with frames spaced much further apart — annotated
"Increased frame spacing compared with skin-stringer."

Side callouts (applicable across the three panels): "Fuselage Skin" carries torsion ($M_x$), vertical
($P_z$), and lateral ($P_y$) loads by shear, and reacts fuselage bending ($M_y$ & $M_z$) by tension &
compression. "Stringers & Longerons" work with the skin to carry longitudinal tension & compression loads,
and support the skin for increased buckling stability. "Frames" provide support for increased buckling
capability of stringers & longerons, maintain fuselage shape, and provide attachment points for other
structures (wing, landing gear, etc.). "Other Design Considerations": pressurized (circular cross section
preferred) vs unpressurized; number and location of doors, windows, & cutouts.

The *sandwich-skin approach* effectively eliminates the need for either stringers or longerons by utilizing
the inherent compression buckling resistance of sandwich skins. As expected, optimum frame spacing for this
configuration is usually increased compared with the other two concepts.

Selection of the optimum fuselage structural configuration for a particular aircraft depends on: fuselage
geometry; number and location of design features (doors, cutouts); magnitude of fuselage bending, torsional,
and shear loads; and material minimum-gage limitations. As with wing structure, the fuselage concepts
presented provide a good starting point for analysis and trade studies.

#### §19.9.3 Structural Design Rules-of-Thumb (p. 523)

Regardless of the specific structural approach selected for wing or fuselage, several basic
rules-of-thumb should always be considered:

1. **Keep load paths simple and direct.** Simple load paths give several benefits: a structural layout with
   easily understood load paths is easier to design and analyze, often yielding a lighter-weight solution;
   a simple design is also often easier to fabricate/assemble, decreasing manufacturing schedule and cost.

2. **All six components of structural loading must be considered.** All structural members can be
   subjected to six components of loading: axial loads in the three principal axes ($P_x$, $P_y$, $P_z$)
   and moments about the three axes ($M_x$, $M_y$, $M_z$), as shown in Fig. 19.19. Although one or two of
   these may dominate the design of a given member, all six must be considered. For example, a wing root
   attachment joint's design may be dominated by vertical shear ($P_z$, from lift) and spanwise ($M_x$)
   bending moment, but the joint must also react drag ($P_x$), inboard-outboard loads ($P_y$), wing torsion
   ($M_y$), and fore-aft wing bending ($M_z$).

3. **A statically determinate structure is usually preferred for minimum weight.** A *statically
   determinate structure* is one where reaction forces can be solved directly from the equations of
   equilibrium (sum of forces = zero, sum of moments = zero); for a given set of applied loads, there is
   only one set of reaction forces. Conversely, an *indeter-

**Fig. 19.19** — *Six components of structural loading* *[Nicolai & Carichner, Fig. 19.19, p. 524]*.
Transport-aircraft silhouette with the six load/moment components annotated at different structural
stations: $P_z$ (vertical, up-arrow near wing root/fuselage centerline) and $M_z$ (yaw moment, curved arrow
about the vertical axis) at the fuselage; $P_y$ (lateral, outboard arrow) and $M_y$ (pitch moment, curved
arrow) near the left engine/wing; $P_x$ (axial/drag-direction, aft arrow) and $M_x$ (roll moment, curved
arrow) near the right wing/tail.

*minate structure* can have multiple solutions for reaction forces depending on the relative stiffness of
redundant load paths within the structure. A determinate structure, having no redundant structure, usually
represents the minimum material required to carry a specific load and is often lighter — also typically
easier to analyze and build. However, other design requirements, such as the fail-safe requirements
discussed in §19.6, might dictate that a statically indeterminate design is required.

4. **Each structural component should serve multiple functions.** A key philosophy for minimum-weight
   structure is requiring every major structural member to serve multiple functions. For example, a wing
   spar's primary function is to carry wing spanwise bending ($M_x$) and vertical shear ($P_z$) loads;
   however, with a well-thought-out layout, a main spar can also support the main landing gear, serve as a
   fuel tank wall, and provide attachment points for the engine and external stores.

5. **Subsystems integration requirements must be considered early.** Subsystems integration and
   accessibility should be considered at the earliest stages of a structural layout, especially for
   tightly packed vehicles such as fighter aircraft. Location of doors, windows, and nonstructural access
   panels, as well as integration of major subsystems such as landing gear, engines, inlet and exhaust
   structure, flight crew stations, and
weapons bays can have a major impact on airframe weight and structural performance if not integrated in an
intelligent and synergistic manner.

### §19.10 Material Selection (p. 525)

From a structures standpoint, one of the most important decisions made during Conceptual Design is
selecting the materials from which to build the airframe. Material selection can have far-reaching
influence on vehicle weight and performance, manufacturing cost and schedule, and reliability/
maintainability in operational service. Key parameters to consider in selecting airframe materials:

- Specific strength
- Specific stiffness
- Usage environment
- Fracture toughness
- Manufacturability
- Minimum gage limitations
- Availability

*Specific strength* and *specific stiffness* are measures of a material's structural performance per unit
weight; specific strength is usually expressed as ultimate tension strength ($F_{tu}$) divided by material
density, and specific stiffness as Young's modulus ($E$) divided by density. Table 19.2 compares
room-temperature specific values for common airframe materials — laminated composites (e.g.,
graphite-epoxy) show a wide range of specific strength/stiffness depending on ply orientation. Table 19.2
also shows many metallic materials, despite wide density variation, have very similar specific stiffness
at room temperature.

In conjunction with specific strength and stiffness, a key discriminator for material selection is the
usage environment — specifically, the operational temperatures the structure will experience. Table 19.2
also lists approximate maximum usage temperature; interestingly, for the materials listed, density
increases as temperature capability increases. Specific strength and stiffness change at different rates as
usage temperature increases, so a material with a clear room-temperature advantage may not be best at
elevated temperature — candidate materials must be evaluated across the full range of expected operational
temperatures.

**Table 19.2** — *Comparison of Material Specific Properties and Maximum Use Temperatures*
*[Nicolai & Carichner, Table 19.2, p. 526]*.

| Material | Density (lb/in.³) | Specific Ultimate Tension Strength at 70°F (ksi/lb/in.³) | Specific Stiffness at 70°F (msi/lb/in.³) | Maximum Usage Temperature (°F) |
|---|---|---|---|---|
| Composite | 0.057 | 368 (quasi-iso layup) / 1105 (all 0° layup) | 61 (quasi-iso layup) / 368 (all 0° layup) | ~275 |
| Aluminum (2024) | 0.100 | 630 | 105 | ~300 |
| Aluminum (7050) | 0.102 | 745 | 101 | ~300 |
| Titanium (6Al-4V) | 0.160 | 812 | 100 | ~700 |
| Carbon steel (4130) | 0.283 | 336 | 102 | ~800 |
| Stainless steel (301 Full Hard) | 0.286 | 646 | 91 | ~1000 |
| Inconel (718 STA) | 0.297 | 606 | 99 | ~1200 |

*Fracture toughness*, denoted $K_{IC}$, measures a material's inherent capability to resist crack growth,
and can be a very important selection parameter for high-usage, long-life aircraft (commercial airliners,
military transports). Very brittle materials (ceramics, glass) typically have very low fracture toughness;
more ductile materials have higher fracture toughness. Material strength properties are often compromised
to achieve increased fracture toughness — an improvement in fracture toughness may correspond with a slight
reduction in ultimate tension strength. For a fatigue-critical airframe with a design life of tens of
thousands of hours, high fracture toughness can be more important than high specific strength.

*Manufacturability* addresses the ability to fabricate an end product from a particular material, and
should not be overlooked in the initial stages of material selection. Commonly used metallic materials
(aluminum, titanium, steel alloys) have a variety of manufacturing processes (forming, machining) usable
from initial sheet/plate/billet stock. Composite materials (e.g., graphite-epoxy) have a variety of
material placement and curing methods. However, not all manufacturing methods apply equally to all
materials — e.g., aluminum alloys are easily cold-formed but many titanium alloys require hot-forming,
which usually involves more complex tooling and can impact program manufacturing cost
and schedule. Similarly for composites, out-of-autoclave processing using vacuum bag pressure and an oven
cure may be perfectly acceptable for some airframe applications; however, if optimum material properties
are required, an autoclave cure may be necessary. Increased pressure/temperature of an autoclave cure can
drive tooling costs, and autoclave size limitations can restrict overall part dimensions, potentially
adding assembly joints and structural weight.

*Minimum gage* refers to the minimum thickness to which a material can be produced — for metallics, either
minimum sheet-stock thickness or minimum machined thickness; for laminated composites, the minimum
thickness available per individual ply. Minimum-thickness limits can affect structural design approach and
weight: e.g., if stress analysis indicates 0.020-in. is needed for a metallic skin region, but the material
is only available in 0.030-in. minimum sheet thickness, there is an inherent weight inefficiency from
material/design-concept incompatibility. Possible solutions range from revising the structural layout so
0.030-in. is a more optimum thickness, to chemical milling to reduce sheet-stock thickness.

Material availability can be a significant factor, especially for a demonstrator aircraft with a very
aggressive development schedule. Many materials (composite and metallic) can require several months to
well over a year for delivery of quantities sufficient for a full airframe. Large billets of less-commonly
used metallics (titanium, Inconel, other high-temperature alloys) can have especially long lead times.
Although ordering materials is rarely done during Conceptual Design, early understanding of procurement
lead times is important for the overall program schedule (Conceptual Design → Preliminary Design → Detail
Design → Vehicle Assembly → First Flight).

### §19.11 Composite Materials (p. 527)

Usage of composite materials in military aircraft has seen a steady increase over the past several decades.
The benefits offered by composites are many, including reduced weight (see Chapter 20, §20.2.3), excel-
lent fatigue performance, low coefficient of thermal expansion, corrosion resistance, and the ability to
tailor the strength and stiffness properties of the material. Composite materials are composed of a
reinforcement material and a matrix, with many combinations available, as shown in Fig. 19.20. The
reinforcement material provides strength and stiffness and can be fibers, whiskers, or particles; the
matrix's primary function is to hold the reinforcement in place and distribute loads among the
fibers/whiskers/particles.

**Fig. 19.20** — *Common composite reinforcement and matrix materials* *[Nicolai & Carichner, Fig. 19.20,
p. 528]*. Left column, two boxed lists: "Typical Reinforcement Materials" — carbon (graphite) fibers, glass
fibers, Boron fibers, Kevlar fibers, SiC fibers/whiskers/particles, Aluminum oxide (Al2O3)
fibers/whiskers/particles; "Typical Matrix Materials" — Epoxy resins, Bismaleimide (BMI) resins, Polyimide
(PI) resins, Thermoplastic resins, Metals (Metal Matrix Composites), Ceramics (Ceramic Matrix Composites),
Carbon (Carbon-Carbon Composites). Right column, three photos: "Tape" (unidirectional fiber tape sheet),
"Fabric" (woven fiber fabric sheet), "Woven Preform" (photo of a 3-D woven fiber preform on a loom).

Fully realizing the benefits offered by composite materials requires a completely different mind-set for
design, analysis, and manufacturing compared with metallic structures. This different way of thinking
should be applied early in the design process to avoid the "black aluminum" mentality of designing with
composites as if they were simply a different kind of metallic material.

As an example, most laminated composites (e.g., graphite-epoxy tape and fabric laminates) have excellent
in-plane strength properties but relatively poor out-of-plane (through-the-thickness) properties — in
contrast to metallic materials, which are basically isotropic
and have comparable properties in all three directions. Therefore, a good composite design should take
these fundamental characteristics into consideration and enhance the material's advantages, not accentuate
its weaknesses.

**Sidebar** — *Vought XF5U-1/XF6U-1 Metalite sandwich construction* (p. 529): The Vought XF5U-1 and XF6U-1
aircraft of the mid-1940s featured a sandwich construction called Metalite, a balsa wood core with bonded
aluminum face sheets. The Metalite panels were formed in molds and cured in a large autoclave, similar to
present-day composite structures. The Metalite panels minimized the number of ribs or stiffeners required
for a lightweight, efficient structure and provided an aerodynamically smooth exterior surface.

Unlike the metallic material design allowables contained in the MMPDS, there is no comprehensive,
industry-wide source for composite design allowables. Several reasons: composite mechanical properties
depend heavily on cure-cycle specifics (curing time, temperature, pressure), and most manufacturers use
unique, often proprietary process specifications; also, new/improved fiber and matrix materials are
constantly being developed, and the number of possible fiber/resin combinations is almost limitless.

Therefore, a decision to utilize the "latest & greatest" composite material system may entail an extensive
coupon testing program to develop design allowables. Vendor-supplied data may be suitable for early
Conceptual Design trade studies, but this data commonly represents "best case" properties and does not
include any statistical basis (A- or B-basis) or material property knockdowns for environmental exposure
and damage tolerance effects. Therefore, vendor data are not normally used for Detail Design unless
substantiated by independent tests.

### §19.12 Sandwich Structure (p. 529)

There are many structural design concepts available for integration into airframe structure, but sandwich
structure deserves special mention because it can be an extremely weight-efficient and cost-effective
method for stiffening a skin or web to achieve increased buckling load capability. *Sandwich structure* is
composed of a core material placed between two outer face sheets, as shown in Fig. 19.21.

Sandwich core is typically honeycomb, although foam cores (various polymeric materials) and corrugated and
truss cores (metallic and nonmetallic materials) are also used. Honeycomb core can be fabricated from
metallics (aluminum, titanium, steel) as well as nonmetallics (Nomex, Fiberglass, graphite). Similarly,
face sheets can be metallic or nonmetallic, with aluminum, titanium, steel, graphite, and Fiberglass being
commonly used.

**Fig. 19.21** — *Construction of a honeycomb sandwich panel* *[Nicolai & Carichner, Fig. 19.21, p. 530]*.
Exploded-view diagram of a honeycomb sandwich panel: a top **Facesheet**, an **Adhesive** layer, a
**Honeycomb Core** layer, another **Adhesive** layer, and a bottom **Facesheet**, shown exploded above an
"Assembled Sandwich Panel" (the same layers shown bonded together as a single panel).

The function of the core material is to carry transverse (out-of-plane) shear loads, separate the face
sheets for increased moment-of-inertia in reacting bending loads, support the face sheets against buckling,
and provide shear continuity between the two face sheets so the sandwich panel acts as a single structural
entity. The face sheets' primary function is to carry in-plane tension, compression, and shear loads; panel
bending is reacted as tension on one face sheet and compression on the other.

The connection between face sheets and core is critical to a sandwich panel's structural performance. For
composite or aluminum sandwich panels, this connection is usually an adhesive bond using a film adhesive.
For titanium and steel sandwich panels, the connection is usually formed by brazing or welding. When
performing trade studies of sandwich panels against other stiffened-skin designs, it is important to
include the weight of the adhesive or braze material for each face sheet — although these weights may seem
insignificant on
a weight-per-unit-area basis, the total adhesive or braze weight can be significant over a large acreage.
In addition, the joint concept for attaching the sandwich panel to surrounding structure should be
considered in any weight trades — core ramp-downs, doublers, or core inserts may be required in joint
areas, each with an associated weight penalty that can be significant.

Sandwich construction has excellent stiffness-to-weight characteristics and is therefore very attractive
for achieving lightweight airframe structure. However, it has potential drawbacks that must be understood
and addressed: sandwich panels can be subject to moisture entrapment, where moisture passes through small
pores/microcracks in the face sheets or panel perimeter and accumulates in the honeycomb core cells. Over
time this moisture accumulation increases panel weight and can cause significant structural damage if the
moisture freezes and expands at altitude, causing the face-sheet-to-core bond to fail.

In addition, the face sheets and core of a sandwich panel can be prone to impact damage, especially for
lightly loaded sandwich structure where the face sheets can be extremely thin. However, these risks can be
mitigated with proper design practices, and the weight-reduction advantages often outweigh these potential
drawbacks.

### §19.13 Structural Testing (p. 531)

Although tremendous advances in structural analysis tools (e.g., finite element modeling) have been made
over the last several decades, structural testing is still a very important part of the aircraft design and
development process. There are two basic categories of structural testing: *development testing*, focused
on generating data required to support detail design and drawing release; and *verification testing*,
focused on demonstrating that the as-designed airframe meets structural requirements prior to flight.

The bulk of these testing efforts normally occur in the Preliminary and Detail Design phases; however, it
may be appropriate to perform "proof-of-concept" testing of new and unproven structural technologies (e.g.,
a new material or innovative design concept) during Conceptual Design, especially if overall vehicle
design success hinges on the viability of that new technology. The structural testing philosophy and scope
envisioned for supporting vehicle development from Conceptual Design to First Flight can influence the
airframe structural design approach, minimum margins-of-safety, material selection, and structural weight,
as well as overall program cost and schedule. Therefore, it is important to have basic definition of the
intended structural test plan and philosophy early in the design process.

Most structural test programs are composed of a series of tests that start at the coupon level, transition
to subcomponent- and component-level specimens, and culminate in full-scale structural test articles, as
depicted in Fig. 19.22. This progression in scope/complexity is called a *building block* testing approach
[8]. Coupon-level testing is commonly focused on material characterization and generating design
allowables — not required if allowables already exist in the MMPDS, but a new material lacking an existing
allowables database may require extensive coupon testing (hundreds of specimens) to generate a full
A-basis or B-basis database.

**Fig. 19.22** — *Building-block structural testing approach* *[Nicolai & Carichner, Fig. 19.22, p. 532]*.
Four progressively larger/more complex test-article silhouettes, left to right: "Coupon Testing" (a small
dogbone/lap-joint fastener specimen); "Subcomponent Testing" (a small stiffened-panel section); "Component
Testing" (a larger stiffened-panel section); "Full-Scale Testing" (a complete aircraft silhouette).

Subcomponent- and component-level testing typically includes critical structural joints and other key
design details; component-level testing might include a fuselage or wing structure section. With unlimited
schedule/budget these tests would run sequentially, each phase's knowledge feeding the next (e.g., coupon
testing completed before subcomponent testing, with the coupon-derived material data used to design the
subcomponent test articles). However, programs rarely have schedule/budget for this sequential approach;
compressed development testing schedules often result in significant overlap/parallel testing across
levels, placing added emphasis on a flexible test program that can accommodate results (good and bad) as
they arrive.

Verification testing usually involves static or fatigue testing of a full-scale, flightlike airframe.
Figure 19.23 shows a full-scale static test of the Airbus A380 wing. The test article for a full-scale
static test can be either an actual flight vehicle or an airframe of identical design to the flight vehicle

**Fig. 19.23** — *Airbus A380 full-scale static test (courtesy of Airbus Industrie)* *[Nicolai & Carichner,
Fig. 19.23, p. 533]*. Photo of the Airbus A380 airframe structural test rig in a large test hall, showing
extensive scaffolding/reaction-structure and load-application fixtures around the test article.

but dedicated for ground testing only. Depending on aircraft size and scope of testing required, these
full-scale tests can represent a substantial cost and schedule investment. Therefore, the verification
testing approach should be defined as early as possible in the design cycle, especially if test facilities
must be modified or built. For prototype or demonstrator aircraft programs, where perhaps only one or two
aircraft are being designed and built, it may not be desirable from a cost standpoint to perform extensive
full-scale testing.

In these cases, restriction of the flight test envelope or an increased minimum margin-of-safety imposed
during Detail Design is sometimes used in lieu of extensive full-scale static testing. Increased minimum
margins can range from +0.20 to +0.50 instead of the 0.00 margin that is the normal goal for minimum weight
structure. Different minimum margins can be required for different parts of the airframe, with specific
values depending on factors such as the expected failure mode (e.g., strength vs stability failure) and the
consequence of failure of the component. Any increased margin-of-safety requirement will impact vehicle
weight and performance, and so must be defined early in the design cycle. Most important, the overall
structural flight certification approach,

**Sidebar** — *Republic XF-91 Thunderceptor inverse-taper wing* (p. 533): The Republic XF-91 Thunderceptor,
which first flew in 1949, featured a structurally challenging inverse taper wing in which the chord and
thickness of the wing were greater at the tip than at the root. In addition, the entire wing could be
tilted to vary the angle of incidence for improved takeoff and landing performance.

whether it includes increased minimum margins-of-safety or extensive structural testing, must be discussed
with and agreed to by the customer and the flight certification agency, be consistent with company design
policy, and provide a clear path for ensuring a flightworthy and safe design.

#### Example 19.2 — HAARP Wing Structural Analysis (p. 534)

**Vehicle Description**

Consider the HAARP vehicle shown in Fig. 5.13 and discussed in §§5.8, 6.6.1, and 18.10. Vehicle dimensions,
weights, and characteristics are as follows:

*[Nicolai & Carichner, table (untitled, Example 19.2 inputs), p. 534]*

| Parameter | Value |
|---|---|
| Wing span = $b$ | 269 ft |
| Wing area = $S$ | 2884 ft² |
| Wing aspect ratio = AR | 25 |
| Wing taper ratio = $\lambda$ | 0.35 |
| $t/c$ | 12.2% |
| Wing structural weight | 2708 lb [from Chapter 20, Eq. (20.2)] |
| Fuel weight in wing tanks | 4800 lb (total both tanks) |
| Fuel tank structural weight + pumps | 93 lb (total both tanks, scaled from U2-A, Table I.4) |
| Payload weight | 578 lb (total both sides — located in engine or payload pods) |
| Heat exchanger weight | 1147 lb (total both sides — located in wing LE, §14.2.1) |

System weights in engine or payload pod (total both sides, §18.10):

| Item | Value |
|---|---|
| Propellers | 400 lb (total weight of the two 8-ft and two 24-ft propellers) |
| Engine + turbocharger + accessories | 2803 lb (from §18.10 and Fig. J.2) |
| Pod structural weight | 290 lb (total for both sides) |
| Main landing gear | 276 lb (U2-A bicycle gear + pogo, Table I.4) |

| Parameter | Value |
|---|---|
| Wing station for engine or payload pod | 21.6 ft from centerline |
| Wing station for fuel tank | 23.75 ft to 44.25 ft from centerline |
| Wing station for heat exchangers | 7.6 ft to 28 ft from centerline |
| Vehicle takeoff gross weight (TOGW) | 16,000 lb |
| Maximum airspeed | 55 KEAS |

The example problem will determine the spar cap sizing for the wing encountering a gust at 20,000 ft.

**Analysis Approach**

Part 1. Calculate the gust positive vertical load factor, $+n_z$, for the HAARP vehicle at the vehicle
maximum airspeed and an altitude of
20,000 ft using the discrete gust formula. Assume an equivalent gust velocity of 66 ft/s, a lift curve
slope of 0.1 per deg, and a total of 300 lb of fuel burned in reaching altitude.

The discrete gust formula is

$$n = 1 \pm \frac{K_g C_{L\alpha} U_e V_e}{498\, W/S} \tag{19.1}$$
*[Nicolai & Carichner, Eq. (19.1), p. 535]*

The gust alleviation factor $K_g$ can be calculated for subsonic aircraft using the expression

$$K_g = \frac{0.88\mu}{5.3+\mu} \tag{19.2}$$
*[Nicolai & Carichner, Eq. (19.2), p. 535]*

where $\mu = 2(W/S)/\rho c a g$.

The vehicle gross weight at altitude is $W = 16{,}000\text{ lb} - 300\text{ lb} = 15{,}700$ lb. This gives a
wing loading $W/S = 15{,}700\text{ lb}/2884\text{ ft}^2 = 5.44$ lb/ft². The air density $\rho$ at 20,000 ft
is approximately $12.67\times10^{-4}$ slug/ft³ (from a standard atmospheric table). $g = 32.2$ ft/s².

The lift curve slope $a$ is given as 0.1 per degree, expressed as 5.730 per radian for Eq. (19.2). The mean
chord of the wing, $c$, is calculated from wing area $S$ and span $b$:

$$c = S/b = 2884\text{ ft}^2/269\text{ ft} = 10.72\text{ ft}$$
*(unnumbered equation, p. 535)*

Plugging these values into Eq. (19.2) for $\mu$ gives $\mu = 4.34$. The gust alleviation factor is then
$K_g = 0.40$.

The following values can then be input into the discrete gust formula:

- $K_g = 0.40$
- $a = 5.730$ per radian
- $V_e = 55$ KEAS
- $U_e = 66$ ft/s
- $W/S = 5.44$

This gives gust load factors of $-2.1\,g$ and $+4.1\,g$. Therefore, the gust positive load factor
(resulting in wing upbending) for this example is $+4.1\,g$.

Part 2. Using the positive vertical gust load factor calculated in Part 1, calculate the lift distribution
for the wing using Schrenk's approximation [9].

The first step in calculating the lift distribution is to divide the wing into a number of spanwise panels.
Although the number and
size of these panels is somewhat arbitrary, a sufficient number should be used to insure solution accuracy.
Subsequent parts of this example involve calculating inertia relief from the weight of wing structure,
fuel, and subsystems, so it is desirable to divide the wing into panels matching the location of various
distributed and concentrated mass items to simplify subsequent calculations. For the solution presented
here, the HAARP wing has been divided into 17 panels as shown in Fig. 19.24.

**Fig. 19.24** — *HAARP wing panel layout as used for analysis* *[Nicolai & Carichner, Fig. 19.24, p. 536]*.
Wing planform (half-span, tapered) divided into 17 numbered spanwise panels (1-17) with wing-station (WS)
tick marks: 0, 7.6, 13.525, 19.45, 23.75, 28.0, 36.125, 44.25, 53.275, 62.3, 71.325, 80.35, 89.375, 98.4,
107.425, 116.45, 125.475, 134.5 (ft). Callouts locate "Heat Exchanger" (spanning panels 2-4, up to WS 21.6),
"Payload/Engine Pod" (panel 4, at WS 21.6), and "Fuel" (panels 5-7, WS 23.75-44.25).

The lift distribution applied to the wing can be calculated using *Schrenk's approximation*. This method
assumes the spanwise lift distribution of an untwisted wing or tail is the average of the lift based on the
actual trapezoidal wing shape and the lift based on an elliptical wing.

For a trapezoidal wing, lift can be expressed as a function of wing station $y$ by:

$$L^{trap}(y) = \frac{2L}{b(1+\lambda)}\left[1 - \frac{2y}{b}(1-\lambda)\right] \tag{19.3}$$
*[Nicolai & Carichner, Eq. (19.3), p. 536]*

For an elliptical wing, the expression is

$$L^{ellip}(y) = \frac{4L}{\pi b}\sqrt{1-\left[\frac{2y}{b}\right]^2} \tag{19.4}$$
*[Nicolai & Carichner, Eq. (19.4), p. 536]*

For the trapezoidal wing equation, $\lambda$ is the wing taper ratio. In both equations, $L$ is the total
lift applied to the wing and $b$ is the wing span. For the HAARP wing example under the prescribed vertical
gust load,

$$L = (4.1\,g)(15{,}700\text{ lb}) = 64{,}370\text{ lb (total)}$$
$$b = 269\text{ ft}$$
$$\lambda = 0.35$$
*(unnumbered equations, p. 536)*

The calculations for trapezoidal and elliptical lift as a function of wing station $y$ are shown in the
spreadsheet in Table 19.3. Because the wing lift distribution is the same for each semi-span, calculations
are shown only from WS0 (vehicle centerline) to WS 134.5 ft (wingtip). The far-right column gives total
lift per panel (average of trapezoidal and elliptical distributions); summed at the bottom, it shows a
total wing lift of 32,215 lb per side, within 1% of the expected 32,185 lb per side ($64{,}370/2$). Figure
19.25 plots the trapezoidal, elliptical, and average lift distributions vs. wing station.

Part 3. Calculate the distribution of lift minus weight for the gust load calculated in Part 1 using the
lift distribution derived in Part 2 and the given wing weights.

Table 19.4 shows the spreadsheet for calculating weight for each of the 17 wing panels. Column F, the wing
unit structural weight (0.939 lb/ft²), is obtained by dividing the given total wing structural weight
(2708 lb) by the wing planform area (2884 ft²). Column G, structural weight per panel, is obtained by
multiplying this unit structural weight by each panel's planform area (column E). Column H, weight per span
for each panel, is obtained by dividing each panel's structural weight by the panel span.

The heat exchanger weight per span, column I, is obtained by dividing the total heat exchanger weight per
side (1147 lb/2 = 573.5 lb/side) by the spanwise length of each heat exchanger (28 ft − 7.6 ft = 20.4 ft),
giving 573.5 lb/20.4 ft = 28.113 lb/ft. The spanwise distributed weights for fuel (column J) and fuel tanks
and pumps (column K) are calculated similarly. Columns H, I, J, and K are added for each panel to give the
total distributed weight per panel shown in column L.

Each side of the HAARP wing also contains a number of significant concentrated mass items located at
WS 21.6 ft. Specifically, the weight of the payload, payload pod structure, propulsion system (propeller,
engine, turbocharger, and accessories), and main landing gear are shown in columns M and N and summed in
column O.

Column P multiplies the total $1\,g$ distributed weight per panel of column L by $4.1\,g$, and column Q
multiplies the total concentrated weight at WS 21.6 (column O) by $4.1\,g$. The total $4.1\,g$ distributed
and concentrated weights are then summed for each panel in column R; they are totaled at the bottom of the
column to serve as an interim check.

Table 19.5 shows the spreadsheet for calculating the (lift-minus-weight) for each of the 17 wing panels.
Column F is the average wing

**Table 19.3** — *HAARP Wing Lift Distribution* *[Nicolai & Carichner, Table 19.3, p. 538]* (panels 1-7 of
17; landscape spreadsheet, columns: Panel; Wing Station $y$ (ft) [panel start/mid/end]; Panel Span (ft);
Elliptical Lift Distribution $[(1-(2y/b)^2)]^{1/2}$; Elliptical Lift $(y)$ at Midpanel (lb/ft); Trapezoidal
Lift Distribution $1-(2y/b)(1-\lambda)$; Trapezoidal Lift $(y)$ at Midpanel (lb/ft); Avg. Lift
(Ellip.+Trap.)/2 (lb/ft); Lift per Panel (lb)):

| Panel | Wing Station y (ft) | Panel Span (ft) | Ellip. factor | Ellip. Lift (lb/ft) | Trap. factor | Trap. Lift (lb/ft) | Avg. Lift (lb/ft) | Lift per Panel (lb) |
|---|---|---|---|---|---|---|---|---|
| 1 | 0.00 / 3.80 / 7.60 | 7.6 | 0.9996 | 304.6 | 0.9816 | 348.0 | 326.3 | 2479.7 |
| 2 | 10.56 / 13.53 | 5.925 | 0.9969 | 303.7 | 0.9490 | 336.4 | 320.1 | 1896.5 |
| 3 | 16.49 / 19.45 | 5.925 | 0.9925 | 302.4 | 0.9203 | 326.3 | 314.3 | 1862.4 |
| 4 | 21.60 / 23.75 | 4.3 | 0.9870 | 300.7 | 0.8956 | 317.5 | 309.1 | 1329.2 |
| 5 | 25.88 / 28.00 | 4.25 | 0.9813 | 299.0 | 0.8750 | 310.2 | 304.6 | 1294.5 |
| 6 | 32.06 / 36.13 | 8.125 | 0.9712 | 295.9 | 0.8451 | 299.6 | 297.8 | 2419.2 |
| 7 | 40.19 / 44.25 | 8.125 | 0.9543 | 290.8 | 0.8058 | 285.7 | 288.2 | 2341.7 |

**Table 19.3 (continued, p. 539)** — panels 8-17 and total:

| Panel | Wing Station y (ft) | Panel Span (ft) | Ellip. factor | Ellip. Lift (lb/ft) | Trap. factor | Trap. Lift (lb/ft) | Avg. Lift (lb/ft) | Lift per Panel (lb) |
|---|---|---|---|---|---|---|---|---|
| 8 | 48.76 / 53.28 | 9.025 | 0.9320 | 284.0 | 0.7643 | 271.0 | 277.5 | 2504.0 |
| 9 | 57.79 / 62.30 | 9.025 | 0.9030 | 275.1 | 0.7207 | 255.5 | 265.3 | 2394.4 |
| 10 | 66.81 / 71.33 | 9.025 | 0.8679 | 264.4 | 0.6771 | 240.0 | 252.2 | 2276.4 |
| 11 | 75.84 / 80.35 | 9.025 | 0.8259 | 251.6 | 0.6335 | 224.6 | 238.1 | 2148.9 |
| 12 | 84.86 / 89.38 | 9.025 | 0.7758 | 236.4 | 0.5899 | 209.1 | 222.7 | 2010.3 |
| 13 | 93.89 / 98.40 | 9.025 | 0.7161 | 218.2 | 0.5463 | 193.7 | 205.9 | 1858.5 |
| 14 | 102.91 / 107.43 | 9.025 | 0.6439 | 196.2 | 0.5027 | 178.2 | 187.2 | 1689.5 |
| 15 | 111.94 / 116.45 | 9.025 | 0.5544 | 168.9 | 0.4590 | 162.7 | 165.8 | 1496.5 |
| 16 | 120.96 / 125.48 | 9.025 | 0.4372 | 133.2 | 0.4154 | 147.3 | 140.2 | 1265.6 |
| 17 | 129.99 / 134.50 | 9.025 | 0.2569 | 78.3 | 0.3718 | 131.8 | 105.0 | 948.0 |
| **TOTAL** | | | | | | | | **32,215.2** |

**Table 19.4** — *Wing Weight Distribution Spreadsheet* *[Nicolai & Carichner, Table 19.4, p. 540]*
(columns B-J of a wider spreadsheet; columns K onward continue on the next page). Columns: B Wing Station
$y$ (ft); C Panel Span (ft); D Panel Chord (ft); E Panel Planform Area (ft²); F Wing Unit Structural Weight
(lb/ft², constant 0.939); G Wing Structural Wt/Panel (lb); H Wing Structural Wt/Span (lb/ft); I Heat
Exchanger Wt/Span (lb/ft); J Fuel Wt/Span (lb/ft).

| Panel | y (ft) | Span (ft) | Chord (ft) | Area (ft²) | F (lb/ft²) | G (lb) | H (lb/ft) | I (lb/ft) | J (lb/ft) |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 3.80/7.60 | 7.60 | 15.6 | 118.5 | 0.939 | 111.3 | 14.64 | 0.00 | 0 |
| 2 | 10.56/13.53 | 5.93 | 15.1 | 89.3 | 0.939 | 83.9 | 14.15 | 28.11 | 0 |
| 3 | 16.49/19.45 | 5.93 | 14.6 | 86.6 | 0.939 | 81.3 | 13.73 | 28.11 | 0 |
| 4 | 21.60/23.75 | 4.30 | 14.2 | 61.2 | 0.939 | 57.4 | 13.36 | 28.11 | 0 |
| 5 | 25.88/28.00 | 4.25 | 13.9 | 59.1 | 0.939 | 55.5 | 13.05 | 28.11 | 109.8 |
| 6 | 32.06/36.13 | 8.13 | 13.4 | 109.1 | 0.939 | 102.4 | 12.60 | 0 | 109.8 |
| 7 | 40.19/44.25 | 8.13 | 12.8 | 104.0 | 0.939 | 97.6 | 12.02 | 0 | 109.8 |
| 8 | 48.76/53.28 | 9.03 | 12.1 | 109.6 | 0.939 | 102.9 | 11.40 | 0 | 0 |
| 9 | 57.79/62.30 | 9.03 | 11.4 | 103.3 | 0.939 | 97.0 | 10.75 | 0 | 0 |
| 10 | 66.81/71.33 | 9.03 | 10.8 | 97.1 | 0.939 | 91.1 | 10.10 | 0 | 0 |
| 11 | 75.84/80.35 | 9.03 | 10.1 | 90.8 | 0.939 | 85.3 | 9.45 | 0 | 0 |
| 12 | 84.86/89.38 | 9.03 | 9.4 | 84.6 | 0.939 | 79.4 | 8.80 | 0 | 0 |
| 13 | 93.89/98.40 | 9.03 | 8.7 | 78.3 | 0.939 | 73.3 | 8.12 | 0 | 0 |
| 14 | 102.91/107.43 | 9.03 | 8.0 | 72.1 | 0.939 | 67.7 | 7.50 | 0 | 0 |
| 15 | 111.94/116.45 | 9.03 | 7.3 | 65.8 | 0.939 | 61.8 | 6.85 | 0 | 0 |
| 16 | 120.96/125.48 | 9.03 | 6.6 | 59.5 | 0.939 | 55.9 | 6.20 | 0 | 0 |
| 17 | 129.99/134.50 | 9.03 | 5.9 | 53.3 | 0.939 | 50.0 | 5.55 | 0 | 0 |
| **TOTAL** | | | | **1442.0** | | **1353.8** | | | |

**Table 19.4 (continued, p. 541)** — columns K-R: K Fuel Tank and Pump Wt/Span (lb/ft); L Total Wing Dist.
Wt/Span (lb/ft, = H+I+J+K); M $1\,g$ POD Systems Weight (lb, concentrated at WS 21.6); N $1\,g$ POD Payload
Weight (lb); O $1\,g$ POD Payload Weight (lb, total concentrated, = M+N... as printed, third concentrated
column); P Total $4.1\,g$ Wing Dist. Wt/Span (lb/ft, = L$\times$4.1); Q $4.1\,g$ Concentrated Weight (lb, =
O$\times$4.1); R Total $4.1\,g$ Wing Wt/Panel (lb):

| Panel | K (lb/ft) | L (lb/ft) | M (lb) | N (lb) | O (lb) | P (lb/ft) | Q (lb) | R (lb) |
|---|---|---|---|---|---|---|---|---|
| 1 | 0 | 14.64 | 0 | 0 | 0 | 60.0 | 0 | 456 |
| 2 | 0 | 42.27 | 0 | 0 | 0 | 173.3 | 0 | 1027 |
| 3 | 0 | 41.84 | 0 | 0 | 0 | 171.5 | 0 | 1016 |
| 4 | 0 | 41.47 | 1885 | 289 | 2174 | 170.0 | 8911 | 9642 |
| 5 | 2.27 | 153.19 | 0 | 0 | 0 | 628.1 | 0 | 2669 |
| 6 | 2.27 | 124.63 | 0 | 0 | 0 | 511.0 | 0 | 4152 |
| 7 | 2.27 | 124.04 | 0 | 0 | 0 | 508.6 | 0 | 4132 |
| 8 | 0 | 11.40 | 0 | 0 | 0 | 46.7 | 0 | 422 |
| 9 | 0 | 10.75 | 0 | 0 | 0 | 44.1 | 0 | 398 |
| 10 | 0 | 10.10 | 0 | 0 | 0 | 41.4 | 0 | 374 |
| 11 | 0 | 9.45 | 0 | 0 | 0 | 38.7 | 0 | 350 |
| 12 | 0 | 8.80 | 0 | 0 | 0 | 36.1 | 0 | 326 |
| 13 | 0 | 8.12 | 0 | 0 | 0 | 33.3 | 0 | 300 |
| 14 | 0 | 7.50 | 0 | 0 | 0 | 30.7 | 0 | 277 |
| 15 | 0 | 6.85 | 0 | 0 | 0 | 28.1 | 0 | 253 |
| 16 | 0 | 6.20 | 0 | 0 | 0 | 25.4 | 0 | 229 |
| 17 | 0 | 5.55 | 0 | 0 | 0 | 22.7 | 0 | 205 |
| **TOTAL R** | | | | | | | | **26,229** |

**Table 19.5** — *HAARP Lift-Minus-Weight Distribution Spreadsheet* *[Nicolai & Carichner, Table 19.5,
p. 542]* (panels 1-7 of 17; columns: B Wing Station $y$ (ft); C Panel Span (ft); D Panel Chord (ft);
E Panel Planform Area (ft²); F 4.1$g$ Lift (Ellip.+Trap.)/2 (lb/ft); G Total 4.1$g$ Wing Distr.
Weight/Span (lb/ft); H 4.1$g$ Lift Distributed Weight (lb/ft, = F − G); I 4.1$g$ Concentrated Weight (lb)):

| Panel | y (ft) | Span (ft) | Chord (ft) | Area (ft²) | F (lb/ft) | G (lb/ft) | H (lb/ft) | I (lb) |
|---|---|---|---|---|---|---|---|---|
| 1 | 0/3.80/7.60 | 7.60 | 15.59 | 118.49 | 326.27 | 60.02 | 266.25 | 0 |
| 2 | 10.56/13.53 | 5.93 | 15.07 | 89.30 | 320.08 | 173.29 | 146.79 | 0 |
| 3 | 16.49/19.45 | 5.93 | 14.62 | 86.61 | 314.32 | 171.54 | 142.79 | 0 |
| 4 | 21.60/23.75 | 4.30 | 14.23 | 61.17 | 309.11 | 170.03 | 139.08 | −8911 |
| 5 | 25.88/28.00 | 4.25 | 13.90 | 59.06 | 304.59 | 628.06 | −323.48 | 0 |
| 6 | 32.06/36.13 | 8.13 | 13.42 | 109.05 | 297.75 | 510.97 | −213.22 | 0 |
| 7 | 40.19/44.25 | 8.13 | 12.80 | 103.98 | 288.21 | 508.57 | −220.36 | 0 |

**Table 19.5 (continued, p. 543)** — panels 8-17 and total:

| Panel | y (ft) | Span (ft) | Chord (ft) | Area (ft²) | F (lb/ft) | G (lb/ft) | H (lb/ft) | I (lb) |
|---|---|---|---|---|---|---|---|---|
| 8 | 48.76/53.28 | 9.03 | 12.14 | 109.56 | 277.46 | 46.74 | 230.72 | 0 |
| 9 | 57.79/62.30 | 9.03 | 11.45 | 103.31 | 265.31 | 44.07 | 221.24 | 0 |
| 10 | 66.81/71.33 | 9.03 | 10.76 | 97.06 | 252.23 | 41.41 | 210.83 | 0 |
| 11 | 75.84/80.35 | 9.03 | 10.06 | 90.81 | 238.11 | 38.74 | 199.37 | 0 |
| 12 | 84.86/89.38 | 9.03 | 9.37 | 84.56 | 222.75 | 36.07 | 186.68 | 0 |
| 13 | 93.89/98.40 | 9.03 | 8.68 | 78.30 | 205.92 | 33.30 | 172.63 | 0 |
| 14 | 102.91/107.43 | 9.03 | 7.98 | 72.06 | 187.20 | 30.74 | 156.46 | 0 |
| 15 | 111.94/116.45 | 9.03 | 7.29 | 65.80 | 165.82 | 28.07 | 137.75 | 0 |
| 16 | 120.96/125.48 | 9.03 | 6.60 | 59.55 | 140.23 | 25.40 | 114.83 | 0 |
| 17 | 129.99/134.50 | 9.03 | 5.91 | 53.29 | 105.04 | 22.73 | 82.31 | 0 |
| **TOTAL** (Area) | | | | **1442.0** | | | | |

**Fig. 19.25** — *Trapezoidal, elliptical, and average wing lift distributions ($n_z = +4.1\,g$)*
*[Nicolai & Carichner, Fig. 19.25, p. 544]*. Plot of Lift/Span (lb/ft, 0-400) vs. Wing Station (ft, 0-140):
three curves labeled "Elliptical," "Average," and "Trapezoidal," all starting near 300-355 lb/ft at the
root and decreasing toward the tip; the Trapezoidal curve starts highest (~355 lb/ft) and drops most
steeply near the tip to near zero at WS 134.5, while the Elliptical curve starts lowest (~305 lb/ft) among
the three at the root but stays highest near the tip (~65 lb/ft at WS~134); the Average curve tracks
between them throughout.

lift distribution at 4.1$g$ calculated in Part 2, and column G is the 4.1$g$ distributed weight previously
calculated. Column H is obtained by subtracting the lift from the weight for each panel, and column I
contains concentrated weight located at WS 21.6.

Figure 19.26 plots the 4.1$g$ (lift-minus-weight) distribution and 4.1$g$ concentrated weight located at
WS 21.6.

**Fig. 19.26** — *HAARP lift-minus-weight distribution* *[Nicolai & Carichner, Fig. 19.26, p. 544]*. Plot of
[Lift−Weight] (lb, −10,000 to 1000) vs. Wing Station (ft, 0-140): a step-like curve near/slightly above
zero from WS 0 to ~20 ft, then a sharp downward spike to about −8700 lb at WS 21.6 (the concentrated
podded-mass station), immediately returning to a small negative plateau (~−300 to −400 lb) from about
WS 24-44, then stepping up to a small positive plateau (~0 to +300 lb) for the remainder of the span out to
WS 134.5.

Part 4. Using the lift-minus-weight distribution calculated in Part 3, calculate the net vertical shear
load ($P_z$) distribution and spanwise bending moment ($M_x$) distribution for the HAARP wing for the gust
condition.

Table 19.6 summarizes the lift-minus-weight distribution and concentrated mass items calculated in Parts
1-3. Column F presents the net total load per panel (assumed to act at the panel midpoint), derived by
multiplying the lift-minus-weight (lb per ft of panel span) by the panel span. The concentrated mass items
at WS 21.6 are handled separately and not included in the column-F load-per-panel calculations.

The vertical shear load ($P_z$) applied to the wing (column G) is obtained by starting at the wingtip
(panel 17) and summing the net load from each panel progressing toward the wing root (panel 1). This shear
load is plotted against wing station in Fig. 19.27 and illustrates the reduction in vertical shear loading
from large mass items (fuel, heat exchanger, propulsion system, payload, etc.) located toward the inner
span. This reduction in wing shear and bending loads due to mass items (distributed and concentrated) is
referred to as *inertia relief*.

**Fig. 19.27** — *HAARP wing vertical shear ($n_z = +4.1\,g$)* *[Nicolai & Carichner, Fig. 19.27, p. 545]*.
Plot of Vertical Shear Load (1000 lb, 0-16) vs. Wing Station (ft, 0-140): starting at ~6000 lb near the
root, decreasing to ~2.3k lb by WS~21, then jumping sharply up to ~11k lb right at WS 21.6 (the concentrated
podded-mass station), rising further to a peak of ~15.4k lb around WS~50, then decreasing steadily and
roughly linearly to near 0 lb at the wingtip (WS 134.5).

The spanwise bending moment ($M_x$) is obtained by calculating the area under the shear curve. Starting at
the wingtip (panel 17), the area under the shear curve is calculated for each panel and summed

**Table 19.6** — *HAARP Wing Vertical Shear Spreadsheet ($n_z=+4.1\,g$)* *[Nicolai & Carichner, Table 19.6,
p. 546]*. Columns: B Wing Station $y$ (ft); C Panel Span (ft); D 4.1$g$ Lift Distr. Weight (lb/ft); E 4.1$g$
Concentrated Weight (lb); F Total 4.1$g$ Load per Panel (lb); G Shear Load (lb, cumulative from tip):

| Panel | y (ft) | Span (ft) | D (lb/ft) | E (lb) | F (lb) | G Shear (lb) |
|---|---|---|---|---|---|---|
| 1 | 0/3.80/7.60 | 7.6 | 266.2 | 0 | 2023.5 | 5,986.4 |
| 2 | 10.56/13.53 | 5.925 | 146.8 | 0 | 869.7 | 3,962.9 |
| 3 | 16.49/19.45 | 5.925 | 142.8 | 0 | 846.0 | 3,093.1 |
| 4 | 21.60/23.75 | 4.3 | 139.1 | −8911 | 598.0 | 2,247.1 |
| 5 | 25.88/28.00 | 4.25 | −323.5 | 0 | −1374.8 | 10,560.4 |
| 6 | 32.06/36.13 | 8.125 | −213.2 | 0 | −1732.4 | 11,935.2 |
| 7 | 40.19/44.25 | 8.125 | −220.4 | 0 | −1790.4 | 13,667.6 |
| 8 | 48.76/53.28 | 9.025 | 230.7 | 0 | 2082.2 | 15,458.0 |
| 9 | 57.79/62.30 | 9.025 | 221.2 | 0 | 1996.7 | 13,375.8 |
| 10 | 66.81/71.33 | 9.025 | 210.8 | 0 | 1902.7 | 11,379.1 |
| 11 | 75.84/80.35 | 9.025 | 199.4 | 0 | 1799.3 | 9,476.4 |
| 12 | 84.86/89.38 | 9.025 | 186.7 | 0 | 1684.8 | 7,677.1 |
| 13 | 93.89/98.40 | 9.025 | 172.6 | 0 | 1558.0 | 5,992.3 |
| 14 | 102.91/107.43 | 9.025 | 156.5 | 0 | 1412.0 | 4,434.4 |
| 15 | 111.94/116.45 | 9.025 | 137.7 | 0 | 1243.2 | 3,022.3 |
| 16 | 120.96/125.48 | 9.025 | 114.8 | 0 | 1036.3 | 1,779.1 |
| 17 | 129.99/134.50 | 9.025 | 82.3 | 0 | 742.8 | 742.8 |

progressively working toward the wing root (panel 1), as illustrated in Fig. 19.28. Table 19.7 summarizes
the calculation used to derive the spanwise bending moment based on the area under the shear curve, and
Fig. 19.29 is the plot of spanwise bending moment vs. wing station.

**Fig. 19.28** — *Example of method for calculating area under shear curve* *[Nicolai & Carichner,
Fig. 19.28, p. 547]*. Three stacked Shear (lb) vs. Wing Station (ft) mini-plots, each showing the shear
curve's outer tip points (4431, 3022, 1779, 743, 0 lb, at successively decreasing wing stations) with the
area under the curve between two adjacent points shaded and an arrow calling out the trapezoidal-area
moment calculation for that panel:
- **Moment at mid-span of Panel #17** = ½(743 lb)(134.5 ft − 129.9875 ft) = 1676 ft-lb
- **Moment at mid-span of Panel #16** = 1676 ft-lb + 743 lb(129.9875 − 120.9625 ft) + ½(1779−743 lb)(129.9875
  − 120.9625 ft) = 13,056 ft-lb
- **Moment at mid-span of Panel #15** = 13,056 ft-lb + 1779 lb(120.9625 − 111.9375 ft) + ½(3022−1779
  lb)(120.9625 − 111.9375 ft) = 34,723 ft-lb

Part 5. Using the wing moment distribution derived in Part 4, what is the spanwise bending moment at
WS 40.2? Assuming the HAARP wing uses a single "I-beam" spar located at maximum $t/c$ of the airfoil that
reacts all of the spanwise bending load (i.e., wing skin is ineffective at carrying any load), and assuming
the centroids of the upper and lower spar caps are coincident with the outer surface of the wing skins,
what are the spar cap loads at WS 40.2 resulting from the gust condition?

**Table 19.7** — *Spanwise Bending Moment Spreadsheet* *[Nicolai & Carichner, Table 19.7, p. 548]*. Columns:
Wing Station $y$ (ft); Panel Span (ft); Vertical Shear Load (lb); Delta Spanwise Bending Moment, $M_y$
(ft·lb); Spanwise Bending Moment, $M_y$ (ft·lb) — note the table header prints "$M_y$" though the
surrounding text calls this the spanwise bending moment $M_x$; transcribed as printed.

| Panel | y (ft) | Span (ft) | Shear (lb) | ΔMoment (ft·lb) | Moment (ft·lb) |
|---|---|---|---|---|---|
| 1 | 0/3.80/7.60 | 7.60 | 5,986/5,986 | 22,748/33,641 | 1,027,053/1,004,305 |
| 2 | 10.56/13.53 | 5.93 | 3,963 | 20,903 | 970,664 |
| 3 | 16.49/19.45 | 5.93 | 3,093 | 13,651 | 949,761 |
| 4 | 21.60/23.75 | 4.30 | 11,158 | 46,424 | 936,110 |
| 5 | 25.88/28.00 | 4.25 | 10,560 | 69,596 | 889,686 |
| 6 | 32.06/36.13 | 8.13 | 11,935 | 104,011 | 820,090 |
| 7 | 40.19/44.25 | 8.13 | 13,668 | 124,876 | 716,079 |
| 8 | 48.76/53.28 | 9.03 | 15,458 | 130,113 | 591,202 |
| 9 | 57.79/62.30 | 9.03 | 13,376 | 111,707 | 461,089 |
| 10 | 66.81/71.33 | 9.03 | 11,379 | 94,111 | 349,383 |
| 11 | 75.84/80.35 | 9.03 | 9,476 | 77,405 | 255,272 |
| 12 | 84.86/89.38 | 9.03 | 7,677 | 61,683 | 177,867 |
| 13 | 93.89/98.40 | 9.03 | 5,992 | 47,050 | 116,183 |
| 14 | 102.91/107.43 | 9.03 | 4,434 | 33,648 | 69,133 |
| 15 | 111.94/116.45 | 9.03 | 3,022 | 22,429 | 35,485 |
| 16 | 120.96/125.48 | 9.03 | 1,779 | 11,380 | 13,056 |
| 17 | 129.99/134.50 | 9.03 | 743/0 | 1,676/0 | 1,676/0 |

**Fig. 19.29** — *Wing bending moment* *[Nicolai & Carichner, Fig. 19.29, p. 549]*. Plot of Bending Moment
(1000 ft-lb, 0-1200) vs. Wing Station (ft, 0-140): starting at ~1027k ft-lb at the root, decreasing gently
to ~936k ft-lb by WS~22 (a slight inflection at the concentrated-mass station), then decreasing steeply and
smoothly (concave) to near 0 ft-lb by about WS~130.

The $M_x$ moment at WS 40.2 is 716,079 ft-lb. The wing chord at WS 40.2 is 12.798 ft. Therefore, using
$t/c = 12.2\%$, the spar depth at WS 40.2 $= (0.122)(12.798) = 1.56$ ft.

The wing bending moment is reacted by a couple load in the spar caps as shown in Fig. 19.30. These cap
loads are calculated by dividing the bending moment $M$ by the spar depth $d$, which at WS 40.2 is
$716{,}079\text{ ft-lb}/1.56\text{ ft} = \pm459{,}025$ lb (tension in the lower cap, compression in the
upper cap, for the $+4.1\,g$ wing upbending condition).

**Fig. 19.30** — *Wing spanwise bending moment reacted by couple load in the spar caps* *[Nicolai &
Carichner, Fig. 19.30, p. 549]*. Cutaway wing-section wedge showing a single I-beam-like spar of depth $d$
at maximum $t/c$, with $P_{compression}$ arrow acting on the upper cap and $P_{tension}$ arrow (opposite
direction) acting on the lower cap, forming the reacting couple.

Part 6. Assuming an ultimate factor-of-safety = 1.5, and assuming the wing spar is constructed of a
material with $F_{ty} = 60$ ksi and $F_{tu} = 75$ ksi, what cross-sectional area is required for the lower
spar cap at WS 40.2 when subjected to the gust condition?

The lower spar is loaded in tension due to this gust condition, with a limit load of 459,025 lb and an
ultimate load of $(1.5)(459{,}025\text{ lb}) = 688{,}538$ lb. The required lower cap area based on tension
yield strength is

$$A_{req\text{-}yield} = 459{,}025\text{ lb}/60{,}000\text{ psi} = 7.7\text{ in.}^2$$
*(unnumbered equation, p. 550)*

The required lower cap area based on tension ultimate strength is

$$A_{req\text{-}ult} = 688{,}538\text{ lb}/75{,}000\text{ psi} = 9.2\text{ in.}^2$$
*(unnumbered equation, p. 550)*

Because the spar cap sizing must satisfy both yield and ultimate strength criteria, the required
cross-sectional area for the HAARP wing lower cap at WS 40.2 due to an $n_z=+4.1\,g$ is 9.2 in.².

### §19.14 Summary (p. 550)

The world of aircraft structures involves many diverse technical disciplines related to design, analysis,
materials, manufacturing, and testing. There are many options available to the Structures Engineer
regarding design concepts, material selection, analysis approach, manufacturing methods, and test
verification philosophy; accordingly, it is important to have a rational and objective decision-making
process to determine which design options are optimal for satisfying a particular set of vehicle
requirements. Although it is sometimes obvious which structural design options are best, there are often
multiple paths to achieve the same end result, and most structural design decisions represent a complex
balance between weight, risk, cost, and schedule.

**References** *[Nicolai & Carichner, Ch. 19 References, p. 550]*

[1] "Joint Service Specification Guide—Aircraft Structures," JSSG-2006, U.S. Department of Defense, 1998.
[2] "Joint Service Specification Guide—Air Vehicle," JSSG-2001B, U.S. Department of Defense, 2004.
[3] "Aircraft Strength and Rigidity—Flight Loads," MIL-A-8861B, Naval Air Systems Command, 1986.
[4] Niu, M. C. Y., *Airframe Structural Design*, Technical Book Co., Los Angeles, CA, 1988.
[5] Ekvall, J. S., Rhoades, J. E., and Wald, G. G., "Methodology for Evaluating Weight Savings from Basic
    Material Properties," Design of Fatigue and Fracture Resistant Structures, American Society for Testing
    and Materials ASTM STP 761, 1982.
[6] "Aircraft Strength and Rigidity—General Specification," MIL-A-8860B, Naval Air Systems Command, 1987.
[7] "Metallic Materials Properties Development and Standardization," MMPDS-04, Federal Aviation
    Administration, 2008.
[8] "Aircraft Strength and Rigidity—Ground Tests," MIL-A-8867C, Naval Air Systems Command, 1987.
[9] Raymer, D. P., *Aircraft Design: A Conceptual Approach*, AIAA Education Series, AIAA, Washington, DC,
    1989.

Chapter 19 extraction complete.
