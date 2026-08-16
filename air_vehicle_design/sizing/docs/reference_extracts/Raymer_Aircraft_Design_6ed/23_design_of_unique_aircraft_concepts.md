# Chapter 23 — Design of Unique Aircraft Concepts

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 23
"Design of Unique Aircraft Concepts," printed pp. 833-866.

A qualitative survey chapter (no numbered equations of its own; a small number of prior-chapter
equations are cross-referenced) covering nonstandard configurations — flying wings, deltas,
forward-swept wings, canard-pushers, multi-fuselage and asymmetric layouts, joined/box/C-wings,
tandem wings, oblique wings, active aeroelastic wings, wing-in-ground-effect, UAVs, and derivative
aircraft design. Footnote citations refer to the book's consolidated bibliography, not reproduced
here.

---

## §23.1 Introduction
*[Raymer, p. 833]*

Unique/"wacky" aircraft ideas are sometimes vindicated (sweptback wings, canard pushers,
helicopters, composites all started as oddities) but usually remain wacky. Three main problems sink
most novel concepts: (1) **wetted area** — directly drives parasitic drag and strongly affects
empty weight; a novel feature that increases wetted area rarely pays for itself; (2) **trimmed
maximum lift coefficient** — many novel layouts put a lifting surface further aft than a normal
wing, which is fine in cruise but cannot be trimmed with large flaps deployed for landing; without
matching flap capability on every lifting surface, those surfaces must be enlarged, adding weight
and wetted area and typically erasing the intended benefit; (3) **weight-estimation optimism** —
designers evaluating their own novel hardware underestimate real-world implementation problems and
resist conservative weight estimates that would make the idea look bad; actual as-built weight
routinely runs double (or more) the conceptual-design estimate.

## §23.2 Flying Wing, Lifting Fuselage, and Blended Wing Body
*[Raymer, p. 834]*

The pure flying wing (no fuselage, no tails) appeals because only lift and thrust are structurally
essential — fuselage, tails, and nacelles are "just" weight and drag — but practical problems often
outweigh the theoretical benefit. Early pioneers: Reimar and Walter Horten (Germany) — first
powered all-wing flight 1935 (H IIm D-Habicht); the Ho IX (1945), the first turbojet-powered flying
wing (52.5 ft/16 m span, 470 kt/870 km/h), used stealth shaping and RAM (per Chapter 8); its unbuilt
successor Ho 229 sits in pieces at the Smithsonian. Horten design philosophy: taper the spanwise lift
distribution to near-zero at the tips (most lift generated inboard), letting the c.g. move forward
and giving natural pitch, yaw, and roll stability with proper sweep — no vertical tails or
negative-dihedral wingtip "crank" needed (conceptually, the aft tail is relocated onto the wingtips).
Jack Northrop's first flying wing flew 1940 (near-pure except canopy/prop shaft; the N-1M's initial
wingtip crank was removed after testing); this led to the huge XB-35 (1946, later jet-converted
YB-49, 1948: 172 ft/52.4 m span, 196,193 lb/88,990 kg, 430 kt/800 km/h). Northrop avoided excess
twist and needed some vertical tail area (propeller-version directional stability came from the
prop-shaft fairing and pusher-propeller effect; the jet-converted YB-49 needed small vertical tails to
replace that lost contribution). Debate continues whether YB-49 crashes were pitch-instability-driven
or more mundane (structural/hydraulic) failures; its "hunting" in yaw (a poor bombing-platform trait)
could have been fixed by an active yaw damper (as later developed for the B-47). Northrop's flying-wing
concept was later vindicated by the B-2 stealth bomber, moving flying wings from "oddity" to "viable
option."

### Fig 23.1 — Horten Jet flying wing
*[Raymer, Fig. 23.1, p. 835]* — Photo/illustration of the Horten Ho IX/229 flying wing. No plotted
data (reference photo).

**Design differences from normal aircraft:** planform, twist, and airfoil shaping need especially
early/careful analysis, and detailed stability/control analysis should start early; c.g. location is
critical. Pitch stability comes from sweep+twist (as above) or a "reflexed" airfoil (trailing edge
lifted slightly for natural stability, though less aerodynamically efficient and typically limited to
slower aircraft). Relaxed-stability active flight control (as pioneered for fighters) lets modern
flying wings (B-2) optimize more fully for aerodynamics, and lets the aircraft use trailing-edge
surfaces deflected *down* like flaps for takeoff/landing (rather than up, as pure-stability designs
would need — see Chapter 16). **Yaw control** needs special attention: Northrop's wings (including
the B-2) use wingtip split-drag-rudders (highly nonlinear — no effect until they "catch" the air,
then a large yaw moment; the B-2 uses a "pilot comfort" mode cracking both rudders open just to the
catch point so the flight-control system can fine-tune yaw damping). Other options: mid-airfoil
extending plates, leading-edge clamshell devices, or (on less "pure" flying wings) wingtip vertical
tails with conventional rudders (which can also be mechanized to increase drag as they open, for
extra yaw authority). Roll/pitch control normally uses combined trailing-edge **elevons**
(elevator+aileron) — nose-up (trailing-edge-up) deflection should delay tip stall and reinforce
(not reverse) wing twist effects; several early Horten designs with separate outboard ailerons/inboard
elevators were nearly unflyable.

Properly executed, a flying wing should have both reduced wetted area (fewer components) and lower
structural weight (partly the "spanloading" effect of Chapter 8) than a conventional design — the
"spanloaded flying wing" has even been proposed as a massive cargo aircraft with a root-to-tip cargo
bay sized for USAF outsized cargo within the airfoil contour (landing-field availability for such a
vehicle being an open question). The Chapter-15 statistical weight equations apply, including the
0.768 wing-weight adjustment typical of delta wings for a well-designed, reasonably spanloaded flying
wing — but the vehicle's center section (despite looking like wing from outside) is structurally more
like a fuselage (cutouts for cockpit, gear, engine access, weapons bays/doors) and should instead use
the fuselage statistical equations, with a 0.774 weight adjustment (as for delta-wing fuselages).
Ref. [162] is recommended for further flying-wing/tailless-aircraft detail.

The **lifting fuselage** (Burnelli and others) shapes the fuselage itself as an airfoil (untapered,
AR ≤ 0.4-ish) to contribute lift — likely too structurally heavy to net a benefit in Burnelli's pure
form, but nearly all airliners use the principle in a mild form: flying the fuselage at a small
positive angle of attack in cruise gives some free lift, avoids a dip in the spanwise lift
distribution, and the resulting under-fuselage positive pressure helps turn the flow aft, reducing
separation drag (the Lockheed L-1011 reportedly overdid this — flight attendants still complain about
pushing carts "uphill").

### Fig 23.2 — Blended-wing-body airplane concept (courtesy of The Boeing Company)
*[Raymer, Fig. 23.2, p. 838]* — Illustration of the Boeing BWB concept. No plotted data (concept
art).

The **blended wing body (BWB)** is a flying wing with a delta-shaped wing/fuselage center section
large enough for a passenger cabin — related to Burnelli's concept but with the center section
blended smoothly into the wing panels, reducing total wetted area and (with a deep center section)
improving structural efficiency (about half the root bending stress of a conventional layout);
wingtip-mounted vertical tails double as winglets. Needs relaxed static stability and automated
flight control to fly efficiently, optimize span loading, and dispense with a tail. Optimizes near
100 psf (488 kg/m²) wing loading (vs. ~160 psf/781 kg/m² for most airliners) — low enough to permit
eliminating high-lift flaps (only an outboard leading-edge slat plus trailing-edge controls needed).
Boeing studies (per Ref. [163]) predict, vs. an equivalent conventional design: 15% lower sized
takeoff weight, 20% better L/D, 27% less fuel burn. Open problems: achieving a pressurized cabin
vessel without a large weight penalty (the cabin isn't a simple capped cylinder as in a conventional
fuselage), and BWB packaging seemingly favoring very large aircraft (~800 passengers), with possible
passenger claustrophobia from the resulting scarcity of windows.

## §23.3 Delta and Double-Delta Wing
*[Raymer, p. 839]*

Delta (straight trailing edge) or near-delta planforms, per research led by Alexander Lippisch, offer
wing structural-weight, internal-volume, and transonic/supersonic-drag benefits. Lippisch himself
favored adding vertical tails (as on his Me-163 Comet) — "without these vertical surfaces it is
impossible to obtain a degree of directional stability comparable to the normal aircraft" [Ref. 164].
The A-12 pure tailless flying-wing delta relied on modern computerized flight control for the
stability Lippisch couldn't achieve without a tail, but was cancelled largely from weight growth
(exacerbated by carrier launch/recovery requirements, Appendix F). Delta wings usually save structural
weight vs. a conventional swept wing because the internal spar structure need not itself be swept
(spars run perpendicular to the fuselage, tip-to-tip load path is a straight line) — Chapter 15's
statistical weight equations suggest a 0.768 wing-weight adjustment and a 0.774 fuselage adjustment
for deltas. The delta's low AR/near-zero taper gives a very large, deep wing root — reducing bending
loads and providing volume for fuel/gear/structure, but sometimes leaving no room for a horizontal
tail (forcing a cantilevered structure, a canard, or a tailless approach) and often requiring lower
wing loading given the high sweep/low AR. The author's own 1977 Rockwell North American "Delta
Spanloader" (Fig. 23.3) combined delta shaping, spanloading, and stealth shaping, achieving good RCS
results and a substantial structural-weight saving; like the B-2 it used relaxed static stability
(minimizing trim drag, allowing flap use for takeoff/landing) and sized 30% lower TOGW than a
conventional bomber design of equivalent technology/mission.

### Fig 23.3 — Delta Spanloader stealth flying wing (D. Raymer, 1977)
*[Raymer, Fig. 23.3, p. 840]* — Illustration of the author's Delta Spanloader concept. No plotted
data (concept art).

As with hypersonic vehicles (Chapter 22), a high-speed vehicle's center of lift is roughly the
planform-area centroid; the wing position wanted for subsonic stability is usually further aft than
ideal for supersonic stability. Adding a highly swept forward lifting surface (contributing little
lift at low speed, more at high speed, ahead of the main wing) solves this — one implementation is
the **double-delta**: a delta wing with a leading-edge kink, more highly swept inboard of the kink;
first seen on the Swedish Draken (1955, Fig. 7.19 cross-ref). The Mach-3 SR-71's extensive fuselage
chines technically make it a double-delta too (a fact classified at the time; when the "non-black"
Lockheed side was designing a civilian SST, Skunk Works engineers reportedly handed over a
double-delta sketch with "use it — it works — but don't ask how we know!").

## §23.4 Forward-Swept Wing
*[Raymer, p. 841]*

The forward-swept wing (FSW) gets the same transonic/supersonic drag reduction as an aft-swept wing,
plus a stall benefit: aft-sweep-induced spanwise flow thickens/separates the boundary layer at the
tips (early tip stall); FSW moves this effect to the roots instead, leaving the tips with clean flow
to high angle of attack — better max lift and retained aileron control. The fundamental FSW problem
is **aeroelastic divergence**: under lift, a forward-swept wing bending upward about its structural
"hinge" line increases tip angle of attack (more lift, more bending — a positive feedback loop),
diverging (and breaking) above some speed; the structure must be strong enough to push this speed
above the aircraft's placard speed, usually at a substantial weight penalty (Fig. 23.4, top). Composite
construction offers two mitigations: composites are stiffer than aluminum (raising divergence speed
outright — used for modest forward sweep on aircraft like Rutan's Boomerang, improving stall
characteristics/design freedom), and can be **aeroelastically tailored** ("bend-twist coupling,"
Fig. 23.4 bottom): orienting enough composite plies along a specific direction forces the wing to
bend only about that direction, so bending under load does *not* increase tip angle of attack,
eliminating (with little weight penalty, properly done) the divergence problem. Tradeoffs remain:
forward sweep's higher CLmax occurs only at high angle of attack (not necessarily useful for
takeoff/landing); early claims of lower supersonic drag often assumed a shrinkable wing (not valid if
landing speed sizes the wing) — for a same-sized wing, the author's design-study experience is that
forward sweep usually gives *higher* supersonic drag; forward sweep also moves the trailing edge aft,
causing balance problems with flaps deployed, and the resulting highly swept flap hinge lines reduce
flap lift effectiveness (per Chapter 12) — together potentially requiring a *larger* wing to meet
takeoff/landing; and forward sweep raises RCS concern (radar energy bounces off the wings onto the
fuselage). One practical FSW niche: small business jets, where the wing box would otherwise create a
draggy/unsightly belly bump under the cabin (Fig. 23.5) — FSW can relocate the wing box behind the
cabin. The German Hansa Executive jet used FSW for this reason but its aluminum structure was heavy
and the aircraft ultimately unsuccessful; the all-composite Scaled Composites VisionAire Vantage used
the same approach successfully (though it didn't reach production for other reasons).

### Fig 23.4 — Forward-swept wing: effect of aeroelastic tailoring
*[Raymer, Fig. 23.4, p. 842]* — Two schematic wing-box cross-sections: (top) conventional structure,
divergence-prone (bending hinge line perpendicular to the wing box causes tip AoA increase under
load); (bottom) aeroelastically tailored structure (bend-twist coupling ply orientation), no
divergence. No plotted data (structural concept diagram).

### Fig 23.5 — Wing-box placement using FSW reduces frontal area (DPR notional design)
*[Raymer, Fig. 23.5, p. 843]* — Two side-view schematics: (top left) aft-swept wing, wing box under
cabin (draggy belly bump); (right) forward-swept wing, wing box behind cabin (no bump). No plotted
data (concept diagram).

## §23.5 Canard-Pusher
*[Raymer, p. 843]*

Best design practice combines components serving multiple interconnected purposes — exemplified by
the pusher-propeller + canard + winglet combination. Burt Rutan's homebuilt VariEze (Fig. 23.6)
combined these three with then-novel foam-and-fiberglass construction into a fast, safe, buildable
design that revitalized the homebuilding community. Canard advantages/disadvantages were covered in
Chapter 4: a properly shaped canard stalls before the main wing (stall-proof aircraft), and produces
an upload (vs. a normal tail's typical download) — but achieving high lift for takeoff/landing on the
canard itself is hard, often forcing an oversized main wing; canards suit pusher-propeller layouts
well since there may be no room for a conventional aft tail. Pusher-propellers (Chapter 10) trade the
aerodynamic benefit of the airframe not flying in the prop wake against the propeller itself
operating in the airframe's wake; benefits include better visibility, less cabin noise/vibration
(though more propeller noise, from operating in the aircraft wake), and a shorter fuselage (less
wetted area) — if a place can be found for a horizontal tail. Moving the c.g. aft (pusher engine)
requires substantial wing sweep for balance; with the wing swept that much, the tips sit far enough
aft of the c.g. for wingtip-mounted vertical tails, which as winglets (Chapter 4) also cut induced
drag. Combined cleverly, the three features together give a design nearly impossible to stall or
spin, even though any one or two alone would likely not be optimal. Caveats: pusher cooling-power
loss is often higher, and much of the VariEze's efficiency actually comes from its small frontal
area (vs. other two-seaters) plus laminar-flow-friendly smooth composite skins — those same
features, applied to a conventional layout (e.g. Lancair models, Cirrus SR20), also yield strong
aerodynamic efficiency, so whether canard-pusher is the right choice for a given design is a trade
study question.

### Fig 23.6 — VariEze canard-pusher homebuilt (courtesy of E. Rutan)
*[Raymer, Fig. 23.6, p. 844]* — Photo of the Rutan VariEze. No plotted data (reference photo).

## §23.6 Multi-fuselage
*[Raymer, p. 845]*

Sometimes requirements or component-reuse favor two or more distinct fuselages. Classic example:
North American F-82 Twin Mustang (a pair of P-51-like fuselages joined, despite little actual P-51
part commonality; built for long-range bomber escort with a two-man crew to reduce fatigue; flew the
longest-ever nonstop distance by a propeller fighter, Hawaii to New York). A multi-fuselage C-5
derivative (Fig. 23.7) was seriously proposed (suitable landing fields would have been hard to find).
The approach succeeded on Rutan's around-the-world Voyager (72% fuel fraction): "outrigger" fuel-tank
bodies were found more efficient than one huge fuselage, exploiting the spanloading concept
(Chapter 8) to cut structural weight enough to overcome the wetted-area penalty; joining the three
bodies via a canard also added torsional stiffness, saving further weight. Scaled Composites has built
three multi-fuselage aircraft carrying air-launched space vehicles (White Knight One/Two carrying
SpaceShipOne/Two; the giant Stratolaunch, payload undisclosed at time of writing) — the twin-fuselage
layout lets the heavy payload hang midway between the fuselages from a wing carry point, high enough
for ground clearance. A multi-fuselage, also asymmetric, SST concept (Fig. 23.8) spreads total volume
across two smaller offset fuselages seeking supersonic drag reduction — aerodynamic benefit and
spanloading weight savings both still needing further study.

### Fig 23.7 — Multi-fuselage C-5 derivative
*[Raymer, Fig. 23.7, p. 846]* — Illustration of a proposed twin-fuselage C-5 derivative transport.
No plotted data (concept art).

### Fig 23.8 — Twin-fuselage SST study (D. Raymer and G. Rosenthal, rendering by A. Ramirez P.)
*[Raymer, Fig. 23.8, p. 846]* — Rendering of a twin-fuselage, longitudinally-offset SST concept. No
plotted data (concept art).

## §23.7 Asymmetric Airplanes
*[Raymer, p. 847]*

Most aircraft are designed assuming a symmetry plane (design one half, mirror the other), which
simplifies both design work and lateral-directional stability/handling (zero roll/yaw moment at
zero sideslip regardless of angle of attack, symmetric response to left/right sideslip) — generally
true for gliders and jets (aside from potential asymmetric nose-vortex formation, Chapter 8), but
often untrue/irrelevant for propeller aircraft: a tractor-propeller aircraft flies in its own
rotating propwash, so a physically symmetric single-tractor-prop design still flies in an
asymmetric flowfield (true propwash symmetry needs counter-rotating propellers on opposite sides);
the "P-effect" (Chapter 16) also shifts the propeller's effective thrust center laterally whenever
the disk is at an angle of attack (e.g. climb), producing a yawing moment even on symmetric
airframes. Rather than fight this with trim tricks (angled vertical tail, angled thrust axis) as
most designers do, some designers instead deliberately exploit asymmetric geometry to fly *more*
symmetrically. Early example: the German Blohm-Voss Bv-141 (flown 1938, Fig. 23.9) — offsetting the
pilot/gunner pod from the engine/tail fuselage gave the gunner a clear firing field and the pilot
excellent downward visibility, while the P-effect shifted the effective thrust axis toward the
centerline, making the flight characteristics more symmetric than the airframe's appearance suggests.

### Fig 23.9 — Single-engine asymmetric design: Blohm-Voss Bv-141
*[Raymer, Fig. 23.9, p. 848]* — Photo/illustration of the Bv-141's offset crew pod configuration. No
plotted data (reference photo).

Burt Rutan's twin-engine Boomerang (Fig. 23.10) is a much more extreme case, with a clear engineering
rationale throughout. Twin-engine safety statistics are no better than single-engine (extra-engine
insurance against one loss is offset by doubled engine-failure probability); losing an engine on
takeoff/go-around in a conventional twin demands expert piloting (minimum engine-out control speed
often exceeds stall speed — falling below it lets the running engine roll the aircraft inverted or
into a spin), and P-effect worsens this if the running engine's downward-traveling blade is away from
the fuselage (typical right-hand-engine case), pushing the effective thrust axis further out and
increasing yaw moment. The fix is to bring the two propellers as close together (and to the
centerline) as possible — impossible with a normal fuselage-plus-two-nacelle layout (minimum
separation = fuselage width + prop clearance). Boomerang instead starts from a single-fuselage,
single-engine layout and adds a second engine in a much smaller nacelle alongside (asymmetric, but
propeller tips only 1 ft/30 cm apart laterally, lateral c.g. between the two bodies) — with the
engines this close, the aircraft flies with almost no rudder input regardless of which engine fails
[Ref. 165]. The second nacelle is moved as far aft as possible (without its prop disk crossing the
cabin, reducing noise/blade-strike risk), far enough back to attach to the horizontal tail for
torsional stiffening and structural weight savings (the same trick used on Voyager); wings are swept
forward to place the wing root as far from the left propeller as feasible.

### Fig 23.10 — Twin-engine asymmetric design: Rutan Boomerang original design layout (courtesy of
E. Rutan)
*[Raymer, Fig. 23.10, p. 849]* — Illustration of the Boomerang's asymmetric layout. No plotted data
(concept illustration).

Rutan's own description [Ref. 166]: P-effect makes the aircraft fly symmetrically at low speed as
thrust lines shift right; combined with half the lateral arm for engine-out and roughly double the
directional stability of conventional twins (long tail arms, both tails in prop wash), the aircraft
can be flown at full aft stick, one engine feathered and full power on the other, hands off the
rudder pedals — only about 1 lb (1.5 deg) of aileron needed to hold heading, and aggressive turning
maneuvers are possible at full aft stick using only the stick. The asymmetry extends to the cabin:
staggered (front-to-rear) rather than side-by-side seating narrows the fuselage (less frontal area)
while preserving shoulder room.

### Fig 23.11 — Asymmetric "safety" twin
*[Raymer, Fig. 23.11, p. 850]* — Layout from the author's *Simplified Aircraft Design for
Homebuilders*: a normal single-engine GA layout with a second engine added as a wing-mounted pusher,
exploiting the P-effect thrust-line shift (toward the downward-moving blade at angle of attack) to
bring both engines' thrust axes even closer together during climb-out. No plotted data (concept
diagram).

## §23.8 Joined Wing
*[Raymer, p. 851]*

Various biplane-like "joined" wing-tip arrangements exist, often via non-structural endplates.
Julian Wolkovitch's more sophisticated **joined wing** concept [Ref. 167] uses true triangulation for
structural strength: a rearward-swept front wing and a forward-swept back wing (mounted atop the
vertical tail, extending down at substantial anhedral) meet and attach to the front wing — triangular
from the front, diamond-shaped from above (Fig. 23.12; the lower variant, joined partway along the
front wing's span, seems preferred per most studies). Main benefit: roughly 30% wing structural
weight reduction from the triangulation (the back wing struts the front wing); because a wing's net
force vector is up-and-aft (lift and drag), this arrangement is even better triangulated than it
looks, aligning better with the wing-panel plane than if the front wing were above the back wing (as
in other joined concepts). In-plane loads go through the triangulated structure; out-of-plane loads
get an added benefit from the perpendicular separation between the two wing panels' spars, which
effectively increases the wing-box structural depth (Fig. 23.13). Downside: hard to match a normal
wing-tail's trimmed CLmax (can't balance large flaps on the back wing without excess wetted area),
and potential extra interference drag from the many tight component intersections. Applications:
Boeing has proposed a joined-wing carrier-based surveillance aircraft (antennas on all four wing
panels for all-around coverage); the author did an unpublished Rockwell VTOL study exploiting the
joined wing's lack of a large wing root at the c.g. to potentially reduce suckdown.

### Fig 23.12 — Joined-wing concepts
*[Raymer, Fig. 23.12, p. 851]* — Two notional joined-wing layouts (differing in where the wings
meet along the front wing's span). No plotted data (concept diagram).

### Fig 23.13 — Joined-wing structural benefits
*[Raymer, Fig. 23.13, p. 852]* — Schematic illustrating the increased effective wing-box depth from
the front/rear spar vertical separation. No plotted data (structural concept diagram).

## §23.9 Some More Innovative Wings
*[Raymer, p. 852]*

### §23.9.1 Tandem Wing
*[Raymer, p. 852]*

Discussed in Chapter 4: theoretical promise of 50% induced-drag savings, but only if total span
matches the single wing being replaced (each tandem panel needing twice the AR of the equivalent
single wing) — rarely drawn this way in practice (Fig. 23.14) since such long, skinny wings would be
heavier with little fuel/gear volume; "normal"-looking tandem wings, with reduced total span, actually
*increase* induced drag. As with other rear-lifting-surface concepts, large flaps can't be trimmed on
the back wing, forcing extra total wing area (more wetted area/weight) [Ref. 12]. Uses: efficient
carriage of a large payload between the wings — the author used this for a never-built Rockwell
air-launched-ICBM carrier [Ref. 2]; Scaled Composites' White Knight suspends SpaceShipOne between
tandem wings; Scaled's Proteus has a removable fuselage section between its wings for interchangeable
payload geometries. Design challenges: main-gear placement is awkward (neither wing is near the
c.g.); the square-cube law (Chapter 19) means a half-size wing has only 35% of the internal volume,
so two half-wings have only 70% combined volume vs. one full-size wing (affecting fuel/gear
packaging). To minimize aerodynamic penalty, separate the two wings as much as possible both
horizontally and vertically, ideally front-low/back-high (maximizing vertical separation of the front
wing's downwash from the back wing) — but a stalling front wing's disturbed air must not wash over
the rear wing (or vice versa): the original Flying Flea was banned in some countries after repeated
crashes traced to front-wing airflow blowing over the back wing, increasing its lift and pitching the
nose down.

### Fig 23.14 — Tandem-wing subsonic transport
*[Raymer, Fig. 23.14, p. 853]* — Illustration of a "normal-looking" (reduced-span) tandem-wing
transport concept, illustrating why the theoretical induced-drag benefit is rarely realized in
practice. No plotted data (concept diagram).

### §23.9.2 Box Wing
*[Raymer, p. 854]*

Studied at Lockheed in the 1960s: essentially a tandem wing with vertical endplates joining the tips
(Fig. 23.15) — promises lower induced drag for a given span and a favorable transonic area
distribution (raising critical Mach number), but likely no significant structural saving (unlike
Wolkovitch's joined wing, this geometry provides no triangulation). Drawbacks: wing and endplate
weight/wetted area, landing-gear packaging difficulty, inability to fit large flaps on the back wing,
and studies finding unusual flutter modes whose mitigation would add further weight.

### Fig 23.15 — Box wing
*[Raymer, Fig. 23.15, p. 854]* — Schematic of a box-wing configuration (tandem wings joined by
vertical endplates). No plotted data (concept diagram).

### §23.9.3 C-Wing
*[Raymer, p. 854]*

An extension of the winglet concept — literally a winglet on a winglet (Fig. 23.16), giving the
outer winglet the same drag-reduction benefit the inner winglet gives the wing. The final (innermost,
horizontal) surface, if all three surfaces are swept, sits far enough aft to double as the horizontal
tail — carrying a download so the C-wing potentially gets its stabilizing trim force "for free." Main
problem is structural: the tip-mounted surfaces (especially if used as control surfaces) induce
substantial wing twisting, with a resulting weight penalty and flutter risk. Boeing and Stanford
University have studied C-wing concepts (including applying it to the BWB), with promising wind-tunnel
results; see Stanford professor Ilan Kroo's lecture notes [Ref. 168] for an overview of C-wings and
other nonplanar wing concepts. A notional C-wing design for a B-737-class transport (not analyzed in
detail) [Ref. 12] illustrates the idea.

### Fig 23.16 — C-wing
*[Raymer, Fig. 23.16, p. 855]* — Schematic of a wing/winglet/winglet-on-winglet ("C") arrangement.
No plotted data (concept diagram).

### §23.9.4 Oblique Wing
*[Raymer, p. 855]*

A variant asymmetric design offering (theoretically) minimum-drag, maximum-efficiency supersonic
flight: a single straight wing skewed relative to the fuselage (one side swept forward, the other
aft), typically pivoted at the center for variable sweep (easy to mechanize with little weight
penalty for this specific geometry). Because the structural box is straight, the oblique wing is
lighter than other swept-wing structures, gets the same transonic/supersonic sweep benefits, and is
no worse than an aft-swept wing for stall angle (though, since the aft-swept side will likely stall
first, a stall limiter is desirable). Main advantage: supersonic wave drag — because the left and
right wing panels sit at different fuselage stations, their volumes don't stack at the same
cross-section, spreading the wing's volume along the flight direction and reducing maximum
cross-sectional area (wave drag scales with the square of max cross-section, per Eq. 12.45). Best
suited to a supersonic transport; was seriously considered for a Navy attack fighter but is
problematic for stealth. The author's own NASA study applied the oblique wing to a subsonic
transport (Fig. 23.17): benefits included higher critical Mach number, reduced wing weight
(structurally unswept box), and — with the wing unswept and large flaps deployed — higher max lift
allowing a smaller wing; problems included the pivot/mechanism weight and landing-gear packaging.
That concept mounted the wing on a short pedestal to limit interference and keep the wing wake out of
the inlet duct.

### Fig 23.17 — Oblique-wing subsonic transport
*[Raymer, Fig. 23.17, p. 856]* — Illustration of the author's NASA oblique-wing subsonic transport
study, showing the wing mounted on a pedestal above the fuselage. No plotted data (concept
illustration).

### §23.9.5 Active Aeroelastic Wing
*[Raymer, p. 856]*

The active aeroelastic wing (AAW), developed at Rockwell International to address excessive
flexibility in Rockwell's Advanced Tactical Fighter design (Fig. 7.2 cross-ref), offers ~10% wing
weight savings, gust alleviation, drag modulation, and improved three-axis control, and has been
proven in supersonic flight test — yet has seen little follow-on adoption. AAW was conceived as a
computerized generalization of the B-47 pilot technique for aileron roll-reversal: the B-47's swept,
high-AR wing had such bad roll reversal (Chapter 16) that flight above 455 kt (840 km/h) was normally
restricted; above that speed B-47 pilots learned to fly "backwards" (stick right to roll left). AAW
mechanizes and extends this: the wing box is deliberately built with reduced torsional stiffness
(saving weight, since torsional-stiffness requirements often govern the outer-wing structure) while
retaining normal strength in other directions; high-speed leading- and trailing-edge control-surface
actuators (able to deflect both up and down) are computer-controlled to exploit this flexibility. For
roll control at low speed, trailing-edge surfaces act like normal ailerons (lift on the deflected
side, Fig. 23.18a); at higher speed the same deflection twists the wing enough that the *net* force
reverses to a download, rolling the aircraft the *other* way (Fig. 23.18b); downward leading-edge-flap
deflection produces a download at the front of the wing box, twisting the leading edge down even
further (Fig. 23.18c). Deflecting leading- and trailing-edge surfaces to "fight" each other (each
twisting the wing oppositely) creates extra wingtip drag usable for yaw control or as a speedbrake
(Fig. 23.18e). AAW is compared to Wright Flyer wing-warping (there done mechanically via control
wires) and to servotab flight-control systems (e.g. Boeing 707 ailerons, moved indirectly via a small
tab) — AAW is, in effect, wing warping mechanized via servotabs. (The original name, "active flexible
adaptive wing," got dropped once people started pronouncing the acronym "awful.") The same
wing-twisting ability, applied to both wings simultaneously (leading edges down), reduces tip lift for
gust alleviation or spanwise-lift-distribution optimization (minimizing induced drag) at different
flight conditions; on a sufficiently swept wing, simultaneous twisting of both tips can give
pitch control like a flying wing's elevons — so AAW can in principle provide roll, pitch, yaw, and
drag control simultaneously. In-depth design studies found total sized-TOGW reductions near 20% for a
supersonic fighter-class design and 10% for a transonic transport-class design when the wing-weight
saving is used to justify a higher-AR wing. AAW was flight-tested (Air Force Research Laboratory,
Boeing, NASA Dryden) on a modified F-18 redesignated X-53, making 50+ flights (half supersonic) — Ed
Pendleton (USAF X-53 program manager) noted the wing remained strong enough to "walk all the way out
on the wing tip, and stand there and jump up and down on it," despite the "awful" name. Application to
transports/other high-AR designs remains un-flight-tested. AAW was assumed for the advanced transport
concept of Fig. 4.36 (also shown in Fig. 23.18), providing roll/pitch/yaw control at high speed for a
tailless design that saved 10% wetted area and achieved a 60% fuel-consumption reduction; the author
expects AAW-like technology to become common in some form, possibly without retaining the "AAW" name.

### Fig 23.18 — Active aeroelastic wing
*[Raymer, Fig. 23.18, p. 858]* — Five schematic panels (a-e) on a notional advanced transport's left
wing: (a) low-speed trailing-edge deflection acting as a conventional aileron; (b) high-speed
trailing-edge deflection reversing net force via wing twist; (c) leading-edge-flap deflection adding
further leading-edge-down twist; (e) leading- and trailing-edge surfaces deflected in opposition for
combined yaw/drag control. No plotted numeric data (control-surface concept diagrams).

## §23.10 Wing-in-Ground-Effect
*[Raymer, p. 859]*

Per Eq. (12.60) (cross-ref, not reproduced here), flying at a height of 1/20 of the wingspan gives
induced drag only 27% of the out-of-ground-effect value, plus an increased usable lift coefficient
(allowing a smaller wing) — tempting design territory if the vehicle can stay at such low heights.
Impractical over land (imagine flying LA-to-Chicago at 5 ft/1.5 m) but conceivable over open water
(LA-to-Tokyo). **Wing-in-ground-effect (WIG)** vehicles — flying-boat-like designs deliberately
staying within ground effect for very high L/D — were built by Lippisch and, most notably, by the
Soviets/Russians ("Ekranoplanes," both propeller- and jet-powered, some enormous). The Cold-War-era
"Caspian Sea Monster" (Bartini-Beriev VVA-14/KM, Fig. 23.19, first flown 1966, Central Hydrofoil
Design Bureau) weighed 1.1 million lb (500,000 kg), used eight turbojets on a forward stub pylon whose
exhaust could deflect down ahead of the wing for **power-augmented ram (PAR)** lift, plus two more
turbojets on the vertical tail for extra takeoff thrust, and reportedly cruised at 230 kt (430 km/h);
the only example built crashed on takeoff in 1980. More recently, Boeing's proposed Pelican giant
turboprop WIG military transport would take off from a runway then descend to <50 ft (15 m) over
water (also capable of normal out-of-ground-effect flight, at much reduced range); at ~400 ft (122 m)
length with an even greater span and a projected 2.8 million lb (1.3 million kg) useful load, it
appears to have remained a study rather than an active program. WIG suits very large vehicles best
(wave-clearance height is a smaller fraction of span for a bigger vehicle); it is, almost by
definition, a flying boat and needs a seaplane hull (Sec. 11.7 cross-ref), with attendant weight/drag
penalty; a small wing (to cut drag) then makes getting out of the water hard (PAR/extra engines help
at the cost of more weight/complexity). Operational questions (docking, loading, maintenance,
infrastructure) must be resolved early to assess economic feasibility.

### Fig 23.19 — Russian "Caspian Sea Monster" WIG
*[Raymer, Fig. 23.19, p. 859]* — Photo/illustration of the Bartini-Beriev VVA-14/KM ekranoplan. No
plotted data (reference photo).

## §23.11 Unmanned/Uninhabited Aircraft
*[Raymer, p. 860]*

Unmanned flight predates the Wright Brothers (though without their crucial control innovations).
Terminology has evolved from "drone"/"RPV" (remotely piloted vehicle, 1930s-1980s, implying real-time
stick-and-rudder remote flying) to today's more common **UAV** (unmanned air vehicle) or FAA-preferred
**UA** (unmanned aircraft) — modern systems mostly fly themselves via onboard computer/GPS/satellite
link, with the ground operator giving mission-level direction rather than moment-to-moment control;
"uninhabited," "aerial," "unpiloted," and (recently, for small quadcopters) "drone" are all also in
use. Representative types: target drones (Mach-4 AQM-37); surveillance/multipurpose (Israel Aircraft
Industries Hunter); small "model-airplane"-class UAVs (Fig. 23.20) up to uninhabited GA-class
aircraft, plus a few larger/more sophisticated designs. The General Atomics Predator (~1900 lb/862 kg,
~110 kt/204 km/h, 40+ hr endurance) is a pusher-prop, composite-homebuilt-like, continuously
operator-controlled low-speed surveillance UAV (visual/IR cameras, optional ground radar). The
larger, jet-powered Northrop Grumman (Ryan) Global Hawk (cruise 65,000 ft/19,812 m, 16,566 nmi/
30,680 km range, 25,600 lb/11,612 kg TOGW) is broadly similar in role to an unmanned U-2, carrying
electro-optical/IR/synthetic-aperture-radar sensors with moving-target indication. Kratos Unmanned
Systems (formerly Composite Engineering Inc.) has delivered hundreds of BQM-167 transonic target
drones and produces the BQM-177A ("Dos Equis"), supersonic without afterburner via sleek shaping and
aggressive area ruling (>40,000 ft altitude, sustained 6-g turns, Mach 0.95 at sea level, programmed
to simulate sea-skimming anti-ship-missile trajectories) (Fig. 23.21; the author was conceptual
design consultant for both BQM-167 and BQM-177 [Ref. 2]).

### Fig 23.20 — Boeing Educational Project UAV (D. Raymer and R. Dellacamera, Instructor/Design
Consultants, 2005)
*[Raymer, Fig. 23.20, p. 861]* — Photo of a small, model-airplane-class educational UAV project. No
plotted data (reference photo).

### Fig 23.21 — Composite Engineering BQM-167X, prototype for BQM-177A now entering production
*[Raymer, Fig. 23.21, p. 862]* — Photo of the flight-test BQM-167X; the caption notes the
production BQM-177A has a W-shaped wing trailing edge and other minor changes. No plotted data
(reference photo).

UAV design resembles normal aircraft design but with special attention to takeoff/landing options
(wheeled, launch rail, air/car launch, boosted vertical launch, etc. for takeoff; wheels, skids,
parachutes, airbags, or simply "let it crash" for landing — trade studies should compare these) and
to the avionics/systems needed for uninhabited flight. Removing the aircrew saves less weight/cost
than intuition suggests: cooling requirements are often avionics-driven (not crew-driven), and a UAV
may need *more* avionics for a given mission than a manned equivalent; removing structural
margin/redundancy/reliability is tempting but must still respect the safety of people on the ground —
a UAV barred from flying over land has little operational value. A careful weights/sizing analysis
should still show a sized-TOGW reduction of roughly 10-30% vs. an equivalent "inhabited" design
(benefiting from the absent cockpit/canopy, and further volume/weight savings depending on the
chosen gear/landing approach); structural weight can also be trimmed by reducing the required
ultimate load factor if extreme-weather operation is excluded (or tolerable to lose an aircraft to).
In the Chapter-15 weight equations, using **0.5-0.7** for the number-of-crew-members term
approximates the residual systems present even with no crew aboard. Modern computing/guidance makes
UAVs viable for tactical strike (including "smart" GPS-coordinate bombs) and even conceivable for
air-to-air combat (with g-limits potentially double human tolerance or more); development continues
worldwide. Fig. 23.22 shows a notional tactical UAV concept (Conceptual Research Corporation) built
to investigate alternative inlet/nozzle concepts, nominally for smart-bomb delivery but adaptable to
surveillance/reconnaissance/comms-relay missions.

### Fig 23.22 — Tactical UAV concept (courtesy of Conceptual Research Corporation)
*[Raymer, Fig. 23.22, p. 863]* — Illustration of a notional tactical UAV concept used to study inlet
and nozzle alternatives. No plotted data (concept illustration).

## §23.12 Derivative Aircraft Design
*[Raymer, p. 863]*

Derivative design (modifying an existing airplane) is arguably the least "innovative" design task,
yet often the hardest, because every change is constrained by the physical reality of the existing
airframe rather than a blank sheet: e.g., extending wing span raises real questions — can the wing
center section take the added load (if not, an expensive strengthening redesign is needed)? Does
the longer tip risk a hard-landing ground strike (gear-leg lengthening is nearly impossible on most
existing designs)? Can gear/tires handle any weight increase? Is the rudder big enough for the
resulting yaw moments? Ignoring any such real-world constraint can sink the project. Conceptual
design of a derivative therefore cannot be finalized without detail-design-level checks (e.g. wing
center-section stress) that would normally wait until later — there is a **cost step function**:
extending span is cheap until the load exceeds what the existing center section can take, at which
point cost jumps sharply; finding that threshold requires real calculations, not rules of thumb.
Fortunately, most aircraft carry some built-in growth margin: landing gear is typically designed for
a 25% gross-weight growth allowance; underused volume (e.g. near wingtips) can sometimes become extra
fuel tankage; some designs leave extra ground clearance for a future larger prop/turbofan. Some
programs deliberately plan a full **pre-planned product improvement (P3I)** roadmap (fuselage
stretch, winglets, re-engining, etc. built into the initial configuration); "spiral development" (a
software-industry term) implies a similar continuous-improvement process with somewhat less
up-front planning (the author notes pilots' natural discomfort with the word "spiral" near
aircraft).

Certain changes are especially hard for a derivative: increasing total allowable weight once
built-in landing-gear growth margin is used up (larger-diameter shock struts, stronger — expensive,
long-lead-time — forgings; tire pressure can't simply be raised, without damaging runways; larger
tires may not fit the wheel well; brakes need more size/mass); ground clearance limits on
propeller/podded-engine diameter; and, for an internal jet engine, inlet duct diameter is nearly
impossible to enlarge without a full redesign (as was required for the F-86H and British Nimrod).
**Fleet interoperability** also constrains derivatives: shared materials/fabrication (production and
maintenance), and ideally minimal cockpit/handling/emergency-procedure changes so existing pilots can
fly the derivative without a new type rating — all nominally "detail design" issues that must
actually be resolved before the derivative configuration can be finalized. Typical derivative
changes: increased TOGW, avionics, payload weight, payload types, external fuel/payload, fuel,
current-engine thrust increase, re-engining, wingtip/root extension, winglets, new wing, fuselage
stretch (watch tail-down ground angle), and scab-on pods/pallets.

A conceptual-design-tool problem specific to derivative studies: the analysis tools must be
"tweaked"/fudge-factored until they closely match the *known* performance of the original aircraft
(otherwise nobody will believe the modified-aircraft numbers) before geometry changes and revised
aerodynamics (increased wetted area, revised planform, possible new component interference) can be
layered on. Empty-weight impact estimation is similarly tricky — a modified part typically weighs
more than the same part designed fresh, and a simple pounds-per-square-foot method is often more
reliable than a sophisticated statistical equation; a detailed weight buildup of the added parts is
the best answer. Propulsion changes require fresh thrust/SFC estimates before recomputing range and
performance. Cost estimation for a derivative is likewise difficult and **cannot** be done by
separately costing the "as new" modified design and the original design (with the same methods) and
subtracting — this does not work, even with the proven DAPCA-family methods of Chapter 18. The best
approach is a detailed work-breakdown-structure (WBS) buildup using actual data for the aircraft being
modified (though such data can be hard to obtain); a simpler RAND Corporation method (source of the
DAPCA method, Chapter 18) statistically fits derivative-program labor hours to straight lines on
log-log paper (based on only 11 military fighter/bomber/transport derivative projects, per Ref.
[169], but reasonable pending better data) — crediting no labor-hour savings for discarded ("thrown
away") original parts.

### What We've Learned
*[Raymer, p. 866]*

Innovative aircraft concepts are worth exploring and sometimes pay off, but must be evaluated with a
"show-me" mentality centered on wetted area, weight, and trimmed maximum lift coefficient.

---

*Chapter 23 complete (§§23.1-23.12, Figs 23.1-23.22). No numbered equations original to this chapter
(Eqs. 12.45 and 12.60 are cross-referenced from Chapter 12, not reproduced here); no numbered tables;
no in-chapter reference list (footnote citations refer to the book's consolidated bibliography, not
reproduced here). No OCR-garbled numeric coefficients encountered — this chapter is almost entirely
qualitative design guidance.*
