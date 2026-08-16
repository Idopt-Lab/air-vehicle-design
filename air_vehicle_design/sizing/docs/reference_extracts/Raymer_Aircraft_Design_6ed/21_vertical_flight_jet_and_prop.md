# Chapter 21 — Vertical Flight: Jet and Prop

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 21
"Vertical Flight—Jet and Prop," printed pp. 763-804.

Two sub-chapters: Jet VTOL (design problems and propulsion concepts, largely qualitative) and Prop
VTOL/Helicopter (includes the chapter's quantitative design content — momentum theory, forward-flight
power, and initial sizing, Eqs. 21.1-21.18, Tables 21.1-21.4). Footnote citations refer to the book's
consolidated bibliography, not reproduced here.

---

## §21.1 Introduction
*[Raymer, p. 763]*

Vertical takeoff/landing avoids dependence on long paved runways (commercial delay/inconvenience;
military airbase vulnerability and stand-off time penalty). The helicopter (conceived by da Vinci,
practical after WWII) was the first successful VTOL aircraft but is speed/range-limited. For
propeller aircraft the **tilt-rotor** (V-22 Osprey) is a good helicopter/wing-borne-cruise compromise.
For jet aircraft no single "best" VTOL solution has emerged; concept choice is mission- and
trade-study-dependent, and new VTOL ideas reliably weigh more than expected — "weight is death to
vertical takeoff airplanes."

## §21.2 Jet VTOL

### §21.2.1 Introduction
*[Raymer, p. 764]*

Only three operational jet VTOL designs to date: Harrier (UK), Yak-38 (Russia, both subsonic,
limited range), and the F-35B (supersonic). A **supersonic** VTOL is orders of magnitude harder: the
Mirage III-V (Mach 2, 1966) and Yak-141 (M1.7) both flew but were judged impractical/cancelled: VTOL
equipment adds empty weight (amplified by sizing leverage on TOGW), adds internal volume for
lift apparatus and vertical-flight fuel, and typically increases fuselage cross-section near the
wing, raising supersonic wave drag. The F-35B (supersonic + VTOL, IOC achieved) pays for its VTOL
capability with about a third less fuel volume than the non-VTOL F-35A, a lower structural load
factor (7 g vs 9 g), 1,000-lb (vs 2,000-lb) internal weapons capacity, and no internal gun (must
carry an external gun pod). It remains the only option where a long runway or large carrier is
unavailable. Commercial rooftop-capable jet VTOL airliners remain a distant, possibly unrealized,
prospect.

### §21.2.2 VTOL Terminology
*[Raymer, p. 765]*

- **VTOL** — vertical takeoff and landing, vs. **CTOL** (conventional takeoff and landing).
- **V/STOL** — flexible vertical- or short-takeoff-and-landing capability.
- **STOVL** — insufficient lift for vertical takeoff at takeoff weight, but can land vertically at
  (lighter) landing weight.
- **VATOL** ("tail-sitter") — cannot use vertical-lift capability to shorten a *conventional*
  takeoff/landing roll.
- **HATOL** — horizontal-attitude takeoff/land; can usually deflect part of its thrust downward in
  forward flight to enable a short takeoff/landing (STOL).

### §21.2.3 Fundamental Problems of VTOL Design
*[Raymer, p. 765]*

Two problems dominate VTOL propulsion-concept selection and aircraft sizing:

**Balance.** Traditional jet layout (engine aft, cockpit/avionics forward, payload/fuel near c.g.)
optimizes cooling separation and c.g. management but means simply vectoring the engine thrust
downward (Fig. 21.1b) leaves nothing to balance the resulting nose-down moment — a "magic finger"
would be needed to hold up the nose. Only two conceptual fixes exist: move the thrust to the c.g.
(Fig. 21.1c) or add a second thrust source near the nose (Fig. 21.1d); both compromise the
traditional, usually-optimal layout. (The author notes an early personal idea to balance the nose
with gyroscopic flywheels — the required flywheels proved far too heavy.)

**Thrust matching.** If vertical-flight thrust comes from the same engines sized for cruise, those
engines will be grossly oversized (and inefficient) for cruise. Worked numeric example (Raymer's
illustrative VTOL transport using four C-5 TF-39 engines, 40,000 lb SLS thrust each): required
T/W = 1.3 for vertical flight caps TOGW at 123,077 lb (55,827 kg) — far below the actual C-5's
764,000 lb. At cruise (L/D = 18, weight ≈ 95% of TOGW) required thrust is only 6,496 lb total, i.e.
1,624 lb/engine — about 18% of that engine's available thrust at 35,000 ft, likely below where the
engine would even run stably. At 35,000 ft/M0.9 the best SFC (~0.73) occurs near 9,000 lb/engine;
at 50% throttle SFC is ~1.2 (64% worse), and would be worse still at 18% throttle. Since range is
directly proportional to SFC, thrust mismatch directly penalizes cruise-dominated VTOL designs that
rely solely on vectored cruise-engine thrust — motivating separate **lift engines** (if 3 of the 4
example engines could shut off in cruise, the remaining one could run at 72% throttle, SFC ~0.8).
Other VTOL-specific problems (discussed in following sections): transition, control, suckdown,
hot-gas ingestion, FOD, inlet flow matching, ground erosion.

### Fig 21.1 — The balance problem
*[Raymer, Fig. 21.1, p. 766]* — Three side-view schematics: (a) forward flight, traditional
engine-aft layout; (b) "magic finger" vertical flight — thrust vectored down at the tail requires an
impossible balancing force at the nose; (c) thrust location moved to the c.g. No plotted data
(concept diagram).

### §21.2.4 VTOL Jet Propulsion Options
*[Raymer, p. 767]*

Broadly two families: (1) conventional engines (net takeoff T/W > 1.0, no separate lift engines),
and (2) engines with fan/core flow split, ducted/exhausted separately.

**Conventional engine, no lift engine, no flow diversion** (Fig. 21.2): tail-sitter (VATOL);
vectored thrust at c.g. (nozzles at c.g., engine forward — used on YAK-36, X-14 — poor pilot
visibility since cockpit must go aft for balance, plus exhaust scrubs the fuselage in forward
flight); tilt nacelle at c.g. (RIVET concept: rear-fuselage engine installed backward, nozzles at
c.g. — simple, light, easy transition, "vectoring in forward flight" (VIFF) benefit, but the 180-deg
inlet duct bend costs ≥5% duct loss; sizing studies found it viable for supersonic V/STOL despite
this). Tilt nacelles (heavy but a good compromise for some missions) were flight-tested subscale by
Grumman for naval applications.

**Conventional engine, no lift engines, flow diversion used** (Fig. 21.3): a retracting blocker
diverts flow forward through internal ducting instead of straight down. Diverted flow can be
exhausted directly or "augmented" via a gas-driven fan or an ejector, increasing thrust by raising
propulsive efficiency (per Eq. 13.4). A **gas-driven fan** is a ducted fan turned by turbine blades
spun by diverted exhaust/compressor air (blades can be internal or, as a "tip-driven fan," at the fan
blade tips). The Ryan XV-5A tip-driven fan achieved an augmentation ratio near 3 — the highest ever
for jet VTOL — but was abandoned after a test-rescue dummy was blown onto the wing and ingested by
the fan. An **ejector** uses viscous air entrainment along an exhaust-driven duct; theoretical
augmentation ratios >3 are rarely realized (practical range ~1.3-2.2; the Rockwell XFV-12A used
span-wide wing/canard ejectors, achieved only ~1.5, and never flew). Both fan and ejector approaches
are heavy, chop up structure, need bulky/hot internal ducting, but ease the thrust-matching problem
since engines need not lift the aircraft by jet thrust alone (potential cruise-fuel benefit that
"probably" doesn't offset the added weight).

**Conventional engine with lift engines** (Fig. 21.4): separate dedicated lift engines (brute force,
e.g. Mirage III-V) — adds weight/volume but solves thrust matching since the cruise engine is sized
purely for cruise. Lift engines, optimized for a single condition, reach uninstalled T/W ~15 (vs
6-8 for forward-flight engines; future lift engines projected ≥25); installation (doors, vectoring
nozzle) roughly doubles this weight. **"Lift plus lift/cruise" (L+L/C)**: the forward-flight engine
also vectors thrust downward for takeoff, reducing the number/size of lift engines needed (placed
forward, near the cockpit, for balance) — used on the YAK-38 and (supersonic, ultimately
unsuccessful) YAK-141; widely regarded (including by Naval Air Systems Command's George
Spangenberg) as possibly the best approach for supersonic VTOL, since it stays close to a "normal"
configuration. L+L/C risks: loss of a lift engine in vertical flight/transition causes an instant
nose-down pitch (Yakovlev designs use automatic ejection); during transition, vectoring the
lift/cruise engine rearward can cause an undesirable nose-up moment unless the lift engine also gets
rearward vectoring — which then also permits return-to-base thrust if the cruise engine fails
(unique to L+L/C). Main drawback: maintaining two different engine types (a serious factor in the
early JSF/F-35 downselect).

**Shaft-driven lift fan (SDLF)**: L+L/C variant replacing the front lift engine with a mechanically
shaft-driven fan (compressor-like, not a shrouded propeller), powered by an extra exhaust turbine
that declutches and free-spins in forward flight. Used on the F-35B (and an early Lockheed stealth
SDLF concept, Fig. 21.5). Avoids the heat/maintenance of a separate lift engine but adds shaft,
clutch, gearbox, extra turbine, and fan maintenance burden, and loses L+L/C's return-to-base
capability. F-35B data indicate a 1.4 augmentation factor — less total lift than an equivalent-size
dedicated lift engine would give. (Historical note: SDLF is loosely related to the unbuilt 1956
"Gyroptere" four-lift-fan design, whose four-post vectored-thrust concept helped inspire the
Harrier's Pegasus engine.)

**Split-flow engines — vectored fan air** (Fig. 21.6): fan air split from core air and vectored
downward for vertical flight. The AV-8 Harrier's Pegasus engine vectors both fan and core air
separately through "elbow" nozzles, giving near-instantaneous vectoring with no mode changes,
simplifying transition and enhancing maneuverability — but the engine must still lift the entire
aircraft (thrust-matching problem persists) and must straddle the c.g., increasing cross-section at
the wing (acceptable since the Harrier is subsonic; no viable supersonic split-flow design has been
found). Thrust can be augmented via **plenum-chamber burning (PCB)** — an "afterburner" for fan and
core flow — though hot exhaust near aircraft skin/landing surface is a concern; alternatively the
engine can revert to a conventional ducted/afterburning configuration for forward flight, at the
cost of sizing the engine for non-afterburning vertical flight (fuel efficiency/weight/cost
penalty). A related concept, the **tandem fan** (Fig. 21.6b), adds a second fan ahead of the main
one that "supercharges" the rear fan/core in forward flight; in vertical flight its flow is diverted
through a downward front nozzle while auxiliary doors feed the rear fan/core — heavier than a normal
engine but usefully moves the vertical lift center forward and effectively raises bypass ratio in
vertical mode. The **hybrid fan** (Fig. 21.6c) is a tandem-fan variant permitting high-bypass
operation in forward flight too.

**Split-flow engines — diverted fan air** (Fig. 21.7): fan air ducted away from (not just vectored
near) the core; core air exits a vectoring nozzle for vertical flight, fan air exits aft in forward
flight but is ducted forward for balance in vertical flight, usually augmented. The **remote
augmented lift system (RALS)** burns added fuel in the ducted fan air (afterburner-like) before it
exits a front nozzle; gas-driven fans/ejectors can also augment the fan-air thrust.

Combinations exist: a proposed advanced Harrier-like supersonic fighter combined a PCB Pegasus-type
engine with separate lift engines. The Dornier Do 31 (1967, 36-soldier capacity, the only VTOL jet
transport ever built) used two Pegasus engines plus eight Rolls-Royce lift engines and never crashed
in flight test.

### Fig 21.2 — Conventional engine, no lift engine, no flow diversion
*[Raymer, Fig. 21.2, p. 767]* — Three schematics: (a) tail sitter; (b) vectored thrust at c.g.;
(c) tilt nacelle at c.g. No plotted data.

### Fig 21.3 — Conventional engine, no lift engines, flow diversion used
*[Raymer, Fig. 21.3, p. 768]* — Two schematics: (a) unaugmented diverted flow; (b) tip-driven fan
augmentation. No plotted data.

### Fig 21.4 — Conventional engine with lift engines
*[Raymer, Fig. 21.4, p. 770]* — Three schematics: (a) separate lift engines; (b) L+L/C (vectored);
(c) L+L/C (tilt nacelle). No plotted data.

### Fig 21.5 — Early Lockheed shaft-driven lift fan STOVL fighter concept
*[Raymer, Fig. 21.5, p. 772]* — Stealth-shaped concept aircraft illustration with the SDLF
arrangement. No plotted data (reference concept art).

### Fig 21.6 — Split-flow engines (vectored fan air)
*[Raymer, Fig. 21.6, p. 773]* — Three schematics: (a) vectored thrust (Pegasus-type, core + fan air
each vectored); (b) tandem fan; (c) hybrid fan. No plotted data.

### Fig 21.7 — Split-flow engines (diverted fan air)
*[Raymer, Fig. 21.7, p. 774]* — Three schematics: (a) remote augmented lift system (RALS);
(b) tip-driven fan; (c) ejector. No plotted data.

### §21.2.5 Vectoring Nozzle Types
*[Raymer, p. 775]*

No ideal VTOL vectoring nozzle exists (weighs little more than a conventional nozzle, vectors
continuously 0-90+ deg, negligible thrust loss) — all real designs trade off. Types (Fig. 21.8):

- **Vectoring flaps** — deflect engine flow like wing flaps deflect external flow; ~3-6% thrust
  loss at 90 deg vectoring. Can be external to the nozzle as part of the wing flap system (used,
  non-VTOL, on the XC-15 STOL transport, turning flow >60 deg).
- **Bucket** — clamshell-thrust-reverser-like; turning forces carried through the hinge line (small
  actuator); smooth turning surface possible; ~2-3% thrust loss at 90 deg (best of the four types
  listed).
- **Rotating (axisymmetric)** — round tailpipe split into three slanted sections joined by rotating
  ring bearings (Yak-41, F-35B); lighter than other types since the tailpipe stays round; ~3-5%
  thrust loss at 90 deg.
- **Ventral** — a hole/blocked-nozzle arrangement in the tailpipe bottom; ~3-6% thrust loss at
  90 deg; can be placed upstream of the afterburner (afterburner not normally used for vertical
  lift, to limit hot-gas ingestion/runway damage), moving the vertical thrust substantially forward
  — helps the balance problem.
- **Elbow** (Harrier/Pegasus) — flow turned 90 deg outboard then, via a rotatable ring bearing,
  another 90 deg down; simple, lightweight, minimal actuator force, but the flow is *always* turned
  a total of 180 deg (even in forward flight), costing a constant ~6-8% thrust loss. "Part-time"
  elbow nozzles (used only for vertical flight, with a blocker door diverting flow from a
  conventional cruise nozzle) avoid the cruise-fuel penalty at the cost of extra nozzle weight.

### Fig 21.8 — Vectoring nozzles
*[Raymer, Fig. 21.8, p. 776]* — Five schematics (side/top views as applicable): (a) vectoring
flaps; (b) bucket; (c) rotating (axisymmetric, three-piece tailpipe); (d) ventral; (e) elbow. No
plotted data.

### §21.2.6 Suckdown and Fountain Lift
*[Raymer, p. 777]*

A hovering VTOL aircraft's exhaust entrains surrounding air (viscosity-driven), producing a downward
flowfield that exerts a "vertical drag" reducing effective lift by typically 2-6% (worse if nozzles
sit directly under the wing) — this is **suckdown**, and it worsens near the ground as the exhaust
spreads outward and increases entrainment (a single-jet VTOL can lose up to 30% effective lift near
the ground — an undesirable handling quality since it increases on approach to landing). With
**multiple, widely-separated nozzles**, ground-spread exhaust streams meet and merge upward into a
central **fountain**, pushing up on the aircraft and often canceling the suckdown; fountain strength
depends on nozzle arrangement and fuselage shape (square lower fuselage corners trap the fountain
better than round ones) and, like suckdown, increases near the ground (a favorable counteracting
handling characteristic). **Lift improvement devices (LIDS)** — longitudinal strakes along lower
fuselage corners that capture the fountain — added over 6% net vertical lift on the AV-8B.

### Fig 21.9 — Suckdown and fountain lift
*[Raymer, Fig. 21.9, p. 777]* — Four schematics: (a) free-air entrainment (single jet, no ground);
(b) single-jet ground effect (suckdown); (c) multiple-jet ground effect (fountain lift); (d) LIDS
fountain-capture geometry. No plotted data.

### §21.2.7 Recirculation and Hot-Gas Ingestion
*[Raymer, p. 778]*

A hovering VTOL aircraft can "drink its own bathwater": hot exhaust recirculates into the inlet,
cutting thrust, and can carry damaging dirt/erosion particles (sometimes obscuring the pilot's
vision entirely). Three contributors (Fig. 21.10): **buoyancy** (exhaust mixes with ambient air,
slows, and the resulting warm air rises and re-enters the inlet — takes ~30 s for Harrier
surrounding air to warm 5 degC, cutting thrust ~4%); **fountain** effect (adds hot-gas ingestion
(HGI) faster than buoyancy — the Harrier sees a 10 degC rise from the fountain effect, cutting
thrust ~8%); **relative wind** (atmospheric or forward-speed-induced wind pushes spreading exhaust
back up into recirculation at some combination of wind speed and exhaust velocity). HGI is generally
limited to speeds below ~50 kt (93 km/h); aircraft with rapid aft-to-down nozzle vectoring can use a
"rolling takeoff" (accelerate to ~50 kt with nozzles aft, then vector down) to minimize HGI — origin
of the Harrier's "Jump Jet" nickname.

### Fig 21.10 — Recirculation
*[Raymer, Fig. 21.10, p. 779]* — Three schematics: (a) buoyancy; (b) fountain; (c) relative wind.
No plotted data.

### §21.2.8 VTOL Footprint
*[Raymer, p. 779]*

"Footprint" = ground effect of exhaust dynamic pressure/temperature. No exact acceptability method
exists; rough guidance: turbojet exhaust is marginal for concrete, too hot/high-pressure for
asphalt; split-turbofan front-fan exhaust is acceptable for concrete, asphalt, dense sod (but the
core-flow exhaust may still be too hot/high-pressure for asphalt/sod); ejectors/gas-driven fans
substantially cool/depressurize exhaust, potentially permitting operation from regular sod or
hard-packed soil. Nozzles should be as high above the ground as possible — ground temperature from
a turbofan drops ~30% at 5 nozzle diameters height, favoring side-mounted elbow nozzles (higher,
smaller diameter for the same flow) over a single ventral nozzle, and disfavoring the axisymmetric
vectoring nozzle (geometrically close to the ground).

### §21.2.9 VTOL Control
*[Raymer, p. 780]*

Hover/transition control typically uses a **reaction control system (RCS)**: high-pressure
(usually engine-compressor-bleed) air ducted to wingtips and nose/tail, expelled through
valve-controlled nozzles for yaw/pitch/roll moments. Bleed costs the Harrier ~10% of its lift thrust,
though the RCS hardware itself is light (~200 lb / 91 kg total) — but occupies significant volume and
must be kept away from avionics (hot ducting). With three-or-more well-c.g.-separated lift nozzles,
differential thrust modulation can substitute for RCS. Beyond three-axis control, VTOL needs
**heave** (vertical velocity) control via lift-thrust variation — throttle-only for fixed
nozzle-exit-area engines (Harrier), or faster via variable nozzle-exit area; adequate heave control
typically adds ~5% to required hover T/W. Engine-out control is harder for VTOL than CTOL: a
two-engines-needed-to-hover design needs a third engine of equal thrust for engine-out hover, and all
engine combinations (all-running and any-one-failed) must keep combined thrust through the c.g.
(or rely on immediately stopping a symmetric opposite-side engine). Cross-shafting engine fans (so
any engine's core can drive all fans) minimizes asymmetric-thrust loss on one core's failure, at a
weight cost. Some multi-engine designs (e.g. Ryan XV-5A, two engines feeding three tip-driven fans)
let either engine drive all augmentation devices.

### §21.2.10 VTOL Propulsion Considerations
*[Raymer, p. 781]*

**Inlet matching** parallels thrust matching: efficient zero-airspeed operation wants a
bellmouth-like inlet (large area, generous lip radius) which is draggy at high speed — compromise:
size the inlet for cruise and add large auxiliary doors for VTOL operation. Minimum net T/W for
vertical flight must exceed 1.0; for acceptable heave response, T/W should be ≥1.05; accounting for
suckdown, HGI, and RCS bleed losses, most VTOL aircraft need an **installed T/W of about 1.2-1.5**
(typical value **1.3**).

### §21.2.11 Weight Effects of VTOL
*[Raymer, p. 781]*

VTOL weight impact is hard to assess statistically from CTOL data because VTOL designers are
pushed much harder on weight (customers tolerate compromises CTOL customers would reject — e.g. the
Harrier requires wing removal to remove the engine, an unthinkable CTOL flaw, but saves the weight
of large engine-removal doors). Consequently the Harrier's empty-weight fraction We/W0 is only
0.48 vs. a CTOL-statistical expectation of ~0.55 (cf. the similar-mission A-4M at 0.56); the F-35B is
similarly weight-optimized to 7 g rather than the F-35A's 9 g. If designed to the *same* ground
rules as CTOL, a VTOL aircraft is always heavier in propulsion and control systems: propulsion, per
Ref. [143] (CTOL vs. tilt-nacelle VTOL versions of an S-3-like carrier utility aircraft), is 8% of
TOGW (CTOL) vs. 20% of TOGW (VTOL); per Refs. [143-145], a typical supersonic CTOL fighter runs
16-18% propulsion weight fraction vs. 18-22% for an equivalent VTOL fighter (the smaller gap
reflects the fighter's engines already being large for supersonic flight). Control-system weight
rises ~50% for VTOL (RCS ducting/nozzles/valves) but stays a small overall fraction (~2% of TOGW for
a typical CTOL design, so the absolute impact is slight). Overall crude We/W0 increase estimates
(Refs. [143-145]): ~4% for a fighter, ~7% for a transport/utility aircraft designed to equivalent
CTOL ground rules — a detailed weight statement should replace these crude estimates for real work.

### §21.2.12 Sizing Effects of VTOL
*[Raymer, p. 783]*

Sized TOGW rises from both the empty-weight effects above and cruise-thrust mismatch (fuel penalty).
Offsetting factors can exist: a VTOL aircraft may be based closer to the fight, shrinking required
range; VTOL simplifies bad-weather landing (helicopter-like precision), potentially justifying
reduced loiter/diversion reserves; and removing the takeoff/landing wing-loading constraint can
permit a smaller, lighter wing (as on the Harrier) — though vertical landing itself burns
non-negligible fuel unlike a CTOL landing. Net: **jet VTOL fighters typically size 10-20% heavier**
than an equivalent CTOL design; **VTOL transport/utility aircraft typically size 30-60% heavier**.
The book's general sizing methods should be used for a firm number.

## §21.3 Prop VTOL and Helicopter

### §21.3.1 Introduction
*[Raymer, p. 783]*

Helicopters make vertical takeoff routine (jet VTOL still "puts on a show" each time) because they
better exploit Eq. 13.4: efficient thrust comes from applying power to a *large* air cross-section S
accelerated only slightly (V - V0), which a large rotor does "gently" versus a jet's small,
near-sonic exhaust — so a helicopter hovers on a much lower power-to-weight ratio than a jet does.
Sikorsky's 1940 VS-300 was the first truly controllable helicopter (predecessor concepts existed back
to da Vinci but lacked blade aerodynamics/power-to-weight/controllability); its successor, the R-4
"Eggbeater," saw combat within four years. Two fundamental differences from fixed-wing design: (1)
**no Breguet-equation equivalent** exists for helicopters (no simple fuel-burned-to-range relation),
greatly complicating range calculation/sizing; (2) rotor blade aerodynamics dominates even the
earliest design studies, so helicopter designers go to in-depth rotor analysis almost immediately
rather than doing extended top-level conceptual trades. Terminology: a rotor is a variable-pitch
propeller that can vary pitch all-at-once ("collective," like a propeller) *and* as it goes around
through 360 deg ("cyclic"). A helicopter is a "rotary-wing aircraft" — as opposed to "fixed-wing."

### §21.3.2 Helicopter Design Concepts
*[Raymer, p. 785]*

Configuration options (Fig. 21.11):

- **Single main rotor** ("conventional," and, as usual, generally best for most applications) —
  maximizes disk area per rotor-system weight, simplest control mechanism, but needs an antitorque
  device (below) and its large diameter can be a high-speed disadvantage (advancing-tip Mach
  effects).
- **Coaxial counter-rotating** (Kamov design bureau specialty) — avoids antitorque need; slight
  propeller-efficiency gain (second rotor "takes out the swirl" of the first); downsides: tall mast
  (~0.3 x rotor radius, to keep the two rotor planes from colliding) adds drag/weight, complex
  counter-rotating gearbox and control-linkage-through-the-lower-rotor-plane, added vulnerable area
  for military use.
- **Intermeshed rotor** (Kaman) — two outward-tilted counter-rotating rotors from a single gearbox,
  timed to just miss each other; avoids concentric-shaft/control-passthrough complexity; used
  mainly for USAF search-and-rescue.
- **Tandem** (Boeing CH-47, classic Vertol H-21 "Flying Banana") — wide c.g. range good for cargo
  (lift shiftable fore/aft via differential collective), reduced structural weight (lift at fuselage
  ends), yaw control via opposite roll angles between rotors ("flying" the rotors); suffers
  rotor-rotor interference reducing efficiency and needing control augmentation.
- **Side-by-side** (Russian Mil V-12, very large helicopters) — avoids tandem interference, may gain
  an apparent aspect-ratio doubling benefit in forward flight, but adds structural weight (fuselage
  suspended from wingtip-mounted rotors).
- **Quadcopter** — impractical for gas power (first man-lifting helicopter, the 1907 Breguet
  "Gyroplane No.1," had no control mechanism and needed a ground crew; a 1922 Oehmichen design added
  control) but well suited to electric power/modern computerized attitude control (see Chapter 20);
  four fixed-pitch props, no other control actuator — roll/pitch/heave from thrust changes, yaw from
  differential torque between the two counter-rotating diagonal pairs. Engine-out safety sometimes
  addressed by doubling motor/prop count ("double-quad" or distributed "multi-copter"); many small
  motors also improve controllability vs a few large ones (large props/motors have more rotational
  inertia and lag), at the cost of not scaling up well; variable-pitch props are an alternative but
  add complexity/weight/cost.

### Fig 21.11 — Helicopter concepts
*[Raymer, Fig. 21.11, p. 785]* — Schematic gallery: single main rotor, coaxial, intermeshed, tandem,
side-by-side, quadcopter. No plotted data.

Rotor mechanization: a **swashplate** (Fig. 21.12) links each blade's independent pitch pivot to
pilot collective (moves both swashplates up/down uniformly, changing total lift) and cyclic (tilts
the swashplates, cycling blade pitch high-to-low once per revolution to tip the rotor-disk plane;
because of gyroscopic lag, maximum blade pitch is mechanized to occur 90 deg *before* the desired
tilt direction). Blades are hinged to **flap** (Fig. 21.13), which (a) removes root bending moment,
letting blades be lighter (though tested "rigid-rotor" designs trade this for better
maneuverability), and (b) automatically balances lift side-to-side in forward flight — the advancing
blade sees higher relative velocity and would otherwise roll the helicopter over, but flaps upward
(losing lift) while the retreating blade flaps downward (gaining lift) until balanced, which tips the
blade-tip-defined rotor-disk plane aft relative to the true rotation plane. This flapping motion
also causes in-plane blade-tip acceleration/deceleration stresses, addressed by a further **lead-lag
hinge**. A full rotor blade thus has four pivots: shaft, pitch, flap, and lead-lag.

**Antitorque** for single-main-rotor designs (Fig. 21.14): the **tail rotor** (most common, ~15-20%
of main rotor diameter, pitch controlled by rudder pedals — pilots without an augmented control
system must continuously "dance" on the pedals) is efficient/responsive but noisy, vibration-prone,
and drag-adding in forward flight; canting it (typically 20 deg from vertical) recovers some "free"
lift — 34% of tail-rotor thrust converted to vertical lift at only a 6% horizontal-thrust cost (the
Sikorsky H-60 Blackhawk's canted tail rotor supplies ~3% of total hover lift). Shrouding the tail
rotor reduces the risk of ground personnel injury plus reduces noise/drag/RCS (used on the RAH-66
Comanche). A **lateral thruster** (ducted fan in the aft fuselage) is inefficient in hover but can
help high-speed drag. **NOTAR** ("no tail rotor," McDonnell/Hughes) blows air out of a slot in a
round aft-fuselage cross-section to force circulation and generate a sideways antitorque lift force —
quieter, lower-drag, and cannot injure ground personnel, but consumes more power and weighs more
than a conventional tail rotor.

### Fig 21.12 — Helicopter cyclic and collective controls
*[Raymer, Fig. 21.12, p. 787]* — Schematic of swashplate/pitch-rod mechanism. No plotted data.

### Fig 21.13 — Rotor-blade flapping
*[Raymer, Fig. 21.13, p. 787]* — Schematic of the flapping hinge and blade motion. No plotted data.

### Fig 21.14 — Antitorque devices
*[Raymer, Fig. 21.14, p. 788]* — Schematics: tail rotor, shrouded tail rotor, lateral thruster,
NOTAR downwash-slot arrangement. No plotted data.

**The helicopter speed limit.** The advancing blade's airspeed = helicopter speed + rotational tip
speed; the retreating blade's = rotational tip speed - helicopter speed, and (since its trailing edge
faces the wrong way) needs a substantially positive net airspeed to generate lift at all —
generally requiring the advancing tip to reach roughly triple the helicopter's forward speed, which
approaches sonic tip speed by about 200 kt (370 km/h) forward speed. Workarounds (Fig. 21.15), each
with penalties:

- **Compound helicopter** — adds a wing plus a separate forward-propulsion system (jet/prop/ducted
  fan); rotor blades unload to flat pitch at high speed. Eurocopter X3 (flight test) targets
  >220 kt (410 km/h).
- **Advancing blade concept** — counter-rotating rotors, unloading retreating blades and flying only
  on the two advancing-blade lift contributions; needs sophisticated cyclic control, usually an
  added high-speed thrust system, and stronger/heavier blades. Sikorsky X2 (advancing-blade,
  coaxial) reached 250 kt (460 km/h) in 2010, the fastest true helicopter ever flown; the derivative
  S-97 Raider (2 crew + 6 troops, ~300 nmi/560 km range) is in flight test.
- **Stopped rotor (X-wing)** — rotor stops in cruise and acts as a rigid (wing-strength) tandem-wing;
  the retreating-blade-side airfoil runs in reverse flow when stopped (a circular-arc, sharp-LE
  airfoil compromise handles both directions). A more advanced **circulation-control wing** variant
  uses spanwise blowing slots (round LE/TE) instead of blade-pitch changes for lift/control, with
  blowing location switchable between flight regimes — complex, never used on a production aircraft.
- **Tilt-rotor / tilt-wing** — effectively "turn the helicopter into an airplane." Tesla patented a
  propeller tail-sitter VTOL biplane in 1928; the Lockheed XFV-1 tail-sitter turboprop demonstrated
  vertical flight but was hard to land/service; the Focke-Achgelis Fa 269 (1941, unbuilt) proposed
  pivoting only the (pusher) propellers. The Bell XV-3 (first viable tilt-rotor) and XV-15 led to the
  operational V-22, the AW609, and the Bell V-280 Valor (14 troops, 2100 nmi/3900 km range, in
  flight test). Tilt-rotors exceed 300 kt (560 km/h) vs. <170 kt (320 km/h) for most conventional
  helicopters; nacelles/props pivot at the wingtips, needing separate synchronized pivots/actuators.
  The **tilt-wing** instead rotates the whole wing (nacelles fixed to it) — simpler (one hinge/actuator
  at the wing root), and, being aligned with propwash in hover, should give higher net lift — but the
  wing stalls at the extreme transition angle of attack, requiring near-full power and heavy propwash
  immersion throughout transition (hard to reconcile with wanting to slow down). First tested on the
  Boeing Vertol VZ-2 (rotors with cyclic control for pitch, differential collective for roll, tail
  rotor for yaw); flew well only with high-power transitions. Tilt-wing/nacelle can also use plain
  propellers or ducted fans (no cyclic) — differential pitch gives roll, but yaw/pitch need another
  mechanism, and smaller-diameter props/fans need more hover power. The Chance-Vought XC-142
  (tilt-wing, propellers, 41,500 lb/18,824 kg) flew 30 kt (56 km/h) backward to 350 kt (643 km/h)
  forward, 710 nmi (1320 km) range, but would have cost far more in production than an equivalent
  STOL aircraft.

### Fig 21.15 — High-speed helicopters and prop VTOLs
*[Raymer, Fig. 21.15, p. 789]* — Schematic gallery: tilt rotor, advancing blade, tilt wing, stopped
rotor (X-wing). No plotted data.

### §21.3.3 Helicopter Design Parameters and Blade Airfoil Selection
*[Raymer, p. 791]*

Two dominant design parameters, analogous to T/W and W/S for fixed-wing aircraft: **power loading**
(W/P, same definition/reverse-connotation as for propeller aircraft — higher value means relatively
smaller engine; typical helicopter values ~4-8 lb/hp / 2.4-4.9 kg/kW, similar to high-powered
propeller aircraft) and **disk loading** (W/S, S = rotor disk area, "the same S as in Eq. 13.4" —
lower disk loading means smaller engine needed per Eq. 13.4's efficiency argument, but implies a
larger, heavier, higher-forward-drag, more shock-prone rotor; higher disk loading is wanted for
speed but caps out because power-off autorotation sink speed scales with the square root of disk
loading). No reliable statistical speed-vs-power-loading correlation exists for helicopters (unlike
Table 5.4 for fixed-wing aircraft) — the author notes significant data scatter in both tables below.

### Table 21.1 — Helicopter Power Loadings
*[Raymer, Table 21.1, p. 791]*

| Aircraft Type | W/P (lb/hp) | W/P (kg/kW) |
|---|---|---|
| Scout/attack helicopter | 3-5 | 1.8-3.1 |
| Transport helicopter | 5-7 | 3.1-4.3 |
| Civil/utility helicopter | 3-8 | 1.8-4.9 |
| Tilt rotor | 4-5 | 2.4-3.1 |
| Tilt wing (propeller) | ~3.4 | ~2.1 |

### Table 21.2 — Helicopter Disk Loadings
*[Raymer, Table 21.2, p. 792]* (low speed = below 150 kt / 280 km/h)

| Aircraft Type | W/S (lb/ft²) | W/S (kg/m²) |
|---|---|---|
| Scout/attack helicopter | 8-10 | 39-49 |
| Transport helicopter | 6-15 | 29-73 |
| Civil/utility helicopter (low speed) | 4-6 | 20-29 |
| Civil/utility helicopter (high speed) | 6-10 | 29-49 |
| Tilt rotor | 15-25 | 73-122 |
| Tilt wing (propeller) | ~50 | ~245 |

**Solidity** (σ) = total blade area / total disk area — a rotor analog of activity factor (Eq.
13.15), measuring how much power the rotor can absorb; a high-disk-loading, high-power helicopter
needs high solidity or the blades stall before reaching full power. **Blade airfoil selection**
wants low drag at design CL, high drag-divergence Mach (delays advancing-blade shocks), and high
CLmax (avoids blade stall, which usually limits hover ceiling) — but airfoils good for wings on those
counts often have pitching moments too large for a rotor (rotor blades are torsionally very weak
given their extreme span/chord ratio), so **rotor airfoils are usually symmetric or nearly so**.
Blades must be mass-balanced along the span so the c.g. sits at the airfoil aerodynamic center
(avoiding torsional flutter) — an aft aerodynamic center minimizes the balance weight needed. A good
blade airfoil is also thick enough for structural depth and simple to manufacture.

### §21.3.4 Momentum Theory for Hover and Vertical Climb
*[Raymer, p. 793]*

The forward-flight propeller-efficiency method (Chapter 13) breaks down at zero airspeed, so hover
requires a dedicated momentum-theory treatment. In hover (Fig. 21.16), the rotor (disk area S)
induces a velocity: `V0` (far above the rotor) = 0, `Vi` (at the disk), `V2` (in the downwash below).
Equating the power inherent in induced velocity at the disk with the increase in downwash kinetic
energy:

**Eq (21.1)** *[Raymer, Eq. (21.1), p. 793]*:
```
T = m_dot * V = (rho*Vi*S)(Vi - V0) = rho*Vi*S*Vi
```

**Eq (21.2)** — Power at station 1 *[Raymer, Eq. (21.2), p. 794]*:
```
P = T*Vi = rho*Vi^2*S*Vi
```

**Eq (21.3)** — Power via downwash kinetic energy at station 2 *[Raymer, Eq. (21.3), p. 794]*:
```
P = d(KE)/dt = (1/2)*m_dot*V2^2 = (1/2)*rho*Vi*S*V2^2
```

Equating (21.2) and (21.3):

**Eq (21.4)-(21.7)** *[Raymer, Eqs. (21.4)-(21.7), p. 794]*:
```
rho*Vi^2*S = (1/2)*rho*Vi*S*V2^2   ->   Vi = V2/2
T = 2*rho*Vi^2*S
Vi = sqrt((T/S)/(2*rho))
```
i.e. induced velocity at the disk is half the downwash velocity, and thrust disk loading `T/S`
determines the induced velocity.

**Eq (21.8)** — Ideal (induced) power *[Raymer, Eq. (21.8), p. 794]*:
```
P = T*Vi = T*sqrt((T/S)/(2*rho))
```

**Eq (21.9)** — Ideal thrust from power and disk loading *[Raymer, Eq. (21.9), p. 794]*:
```
T_ideal = (550*hp) * sqrt(2*rho/(W/S))
```
(assumes thrust disk loading `T/S` = weight disk loading `W/S`; actually `T/S ≈ 1.03*(W/S)` to
account for ~3% downwash force on the fuselage.)

Momentum theory assumes uniform disk inflow and instantaneous "magical" energy transfer, ignoring
profile drag, tip losses, and residual rotational velocity. Real losses: ~6% nonuniform inflow, up to
30% airfoil profile drag, ~3% tip losses, <1% slipstream effects — net actual thrust is typically
**≤83% of theoretical ideal thrust**. An empirical **measure of merit** `M` (typically 0.6-0.8;
not to be confused with Mach number) corrects for this:

**Eq (21.10)** *[Raymer, Eq. (21.10), p. 795]*:
```
M = P_ideal / P_actual
```

**Eq (21.11)** — Actual hover power required (fps units, hp) *[Raymer, Eq. (21.11), p. 795]*:
```
hp_actual = (T / (550*M)) * sqrt((T/S)/(2*rho))
```

**Eq (21.12)/(21.13)** — Total power including tail rotor and mechanical losses
*[Raymer, Eqs. (21.12)-(21.13), p. 795]*:
```
P_total = (P_rotor + P_tail_rotor) / eta_mechanical
        = P_rotor * (1 + P_tail_rotor/P_rotor) / eta_mechanical
```
where `eta_mechanical ≈ 0.97` and `P_tail_rotor/P_rotor ≈ 0.14` to `0.22`.

**Ground effect** benefits helicopters as it does fixed-wing aircraft (Chapter 12): constraining the
downwash raises efficiency, cutting required hover power. At half the rotor diameter above ground,
thrust gains ~5%; at 20% of rotor diameter, ~18% — letting helicopters operate from
mountain-altitude sites above their free-air hover ceiling.

**Vertical climb.** Naive assumption (climb power = time-derivative of potential energy = W x Vc) is
pessimistic — repeating the Eqs. (21.1)-(21.8) derivation with `V0` = climb speed `Vc` shows the
*additional* power to climb is only **half** the potential-energy-rate, i.e. ≈ (1/2)*W*Vc, added to
the hover power.

**Eq (21.14)** — Hover or vertical climb power *[Raymer, Eq. (21.14), p. 796]*:
```
P_climb = [ sqrt(f*W*(W/S)/2) / M + W*Vclimb/2 ] * (1 + P_tail_rotor/P_rotor) / eta_mechanical
```
where `W` = helicopter weight, `S` = rotor disk area, `M` = measure of merit, `Vclimb` = climb speed
(0 for hover), `f` = downwash-on-fuselage adjustment (typically 1.03). In fps units, divide by 550
for horsepower.

**Autorotation**: on engine failure the rotor free-spins at reduced pitch rather than the aircraft
simply falling. By definition, autorotating power = 0, so (per Eq. 21.2) induced velocity through the
disk must also be 0 — the rotor acts as a parachute (drag coefficient ≈ 1.0). Setting vertical drag =
weight for an ideal parachute gives a descent velocity equal to twice the hover induced velocity
(`2*Vi` from Eq. 21.7) — a simply-derived approximation reported as reasonably accurate.

### Fig 21.16 — Helicopter in hover
*[Raymer, Fig. 21.16, p. 794]* — Schematic of the rotor disk (area S) with induced velocity `Vi` at
the disk and downwash velocity `V2` below, `V0` = 0 far above. Supports Eqs. (21.1)-(21.9). No
tabulated plot data (definitional diagram).

### §21.3.5 Power Required for Forward Flight
*[Raymer, p. 796]*

Proper forward-flight analysis needs blade-element or numerical methods (next section); an
approximate treatment models the rotor as a wing — in forward flight it does act like one (induces
downwash, forms trailing vortices, has induced drag, roughly elliptical lift distribution). As a
circular "wing" the rotor's aspect ratio is `4/pi` (from `d²/(pi*d²/4)`); empirical Oswald efficiency
`e` for a rotor acting as a wing is **0.5 to 0.8**, usable in the induced-drag equation (Eq. 12.48).
Parasitic drag uses Chapter-12 methods plus helicopter-specific drag-area (`D/q`) data (Table 21.3) —
helicopter fuselages are usually too irregularly shaped for form-factor/skin-friction estimation to
be reliable, so `D/q` data (or better, wind-tunnel data on a similar configuration, ratioed by
frontal area) are preferred. The rotor also supplies forward propulsion, analyzable as an aircraft
propeller with empirical efficiency `eta_p` = **0.6 to 0.85** applied to Eq. (13.17).

### Table 21.3 — Helicopter Drag Data
*[Raymer, Table 21.3, p. 797]*

| Component | D/q |
|---|---|
| Fuselage | 0.07-0.10 |
| Tubular landing skid | 1.01 |
| Streamlined landing skid | 0.40 |
| Unfaired rotor hub | 1.0-1.4 |
| Faired rotor hub | 0.5-0.8 |
| Downwash interference drag (per unit fuselage frontal area) | 0.02 |
| Leakage and protuberance drag (per unit frontal area) | 10-20% added to parasitic drag |

Setting rotor thrust (Eq. 13.17) equal to drag (Eq. 12.4) and solving for power:

**Eq (21.15)** — Level forward flight power *[Raymer, Eq. (21.15), p. 797]*:
```
P_level = (V/eta_p) * [ q*(D/q) + W^2/(4*e*q*S) ] * (1 + P_tail_rotor/P_rotor) / eta_mechanical
```
(`S` = rotor disk area; the rotor-disk aspect ratio `4/pi` is already folded into the induced-drag
term.)

**Eq (21.16)** — Climbing forward flight power *[Raymer, Eq. (21.16), p. 798]*:
```
P_climb = (V/eta_p) * [ q*(D/q) + W^2/(4*e*q*S) + W*sin(gamma) ] * (1 + P_tail_rotor/P_rotor) / eta_mechanical
```
(fps units, divide by 550 for horsepower). The `W*sin(gamma)` term is the climb-path weight
component in the drag direction (per Eq. 17.35); the slight lift reduction implied by Eq. (17.36) is
neglected. Because climbing at moderate forward speed needs substantially less power than a pure
vertical climb (Eq. 21.14), helicopter pilots typically lift off, accelerate forward in ground
effect, and begin climbing only once forward speed builds.

### §21.3.6 Blade Element Theory and Numerical Methods
*[Raymer, p. 798]*

Momentum-theory/measure-of-merit methods are used only for the earliest rough estimates; real
helicopter design organizations move quickly to computerized rotor analysis (optimizing W/S, W/P,
solidity, blade airfoil, planform, twist) via **blade-element theory** (the blade is divided into
chordwise strips; local angle of attack is a function of forward velocity, rotational velocity,
induced velocity, twist, cyclic input, radial/azimuth position, and flapping, further complicated by
advancing-blade compressibility, retreating-blade stall, and tip losses — mathematically complex but
implemented in existing "canned" software) or **numerical methods** (now largely supplanting blade
element theory once someone else has written the code — ranging from linearized panel codes to
Navier-Stokes CFD, adding unsteady flow, nonuniform induced velocity, reversed-flow regions, dynamic
stall, and dynamic blade bending/twisting; typically iterated around one full rotor revolution until
the blade's calculated end-of-revolution position matches its start position).

### Fig 21.17 — Helicopter CFD numerical methods (NASA Ames Research Center)
*[Raymer, Fig. 21.17, p. 799]* — Illustration of unstructured-grid Reynolds-averaged Navier-Stokes
gridding around a rotor, alongside calculated pressure contours on a Comanche helicopter (separate
analysis). Caption notes full-vehicle NS CFD including spinning blades and blade-vortex interaction
is currently possible but difficult/expensive; research ongoing. No plotted numeric data (CFD
visualization).

### §21.3.7 Helicopter Range Analysis
*[Raymer, p. 799]*

No Breguet-equation equivalent exists (no `L/D`-like single ratio, since the rotor supplies both lift
and thrust), so range/sizing must use a numerical-integration approach similar to the most
sophisticated fixed-wing range programs:

1. Assume a helicopter weight (between cruise start and end weight).
2. Calculate power required (via the equations above, or iterated with more sophisticated methods)
   for the desired velocity.
3. Look up/calculate fuel flow at that power setting.
4. Compute specific range = velocity / fuel flow.
5. Repeat for other assumed weights; plot specific range vs. weight; **graphically integrate** (area
   under the curve) for total range.

This mirrors the derivation of the Breguet equation itself (which integrates specific range against
weight change) — the reason no closed form exists for helicopters is precisely the missing `L/D`
term. Loiter uses the same method, integrating specific loiter (time per unit fuel) instead of
specific range.

### §21.3.8 Helicopter Initial Sizing
*[Raymer, p. 800]*

Uses the general aircraft sizing equation (Eq. 3.4), repeated as Eq. (21.17), but the "fuel
fraction" comes not from a Breguet mission-segment fraction but from the **known-time fuel-burn**
equation (Eq. 19.6), modified to use power specific fuel consumption and helicopter power loading:

**Eq (21.17)** *[Raymer, Eq. (21.17), p. 800]*:
```
W0 = (Wcrew + Wpayload) / (1 - (Wf/W0) - (We/W0))
```

**Eq (21.18)** *[Raymer, Eq. (21.18), p. 800]*:
```
Wi/Wi-1 = 1 - (Cpower * t) / (W/P)
```
Total mission duration is assumed from range/cruise speed plus a takeoff/climb allowance, treating
the helicopter as flying near-full-power throughout (ignoring weight reduction from fuel burn —
conservative) and neglecting descent/landing time. Helicopters typically carry a 5% margin on engine
fuel consumption plus a 10% fuel reserve, or a reserve equal to 20-30 min flight at best-loiter speed.

Empty-weight fraction (Table 21.4) is taken from historical data directly, **not** as a function of
takeoff weight (no such trend is statistically supported for helicopters, unlike fixed-wing aircraft)
— a notable simplification: **solving Eq. (21.17) requires no iteration**, unlike the fixed-wing
case.

### Table 21.4 — Helicopter Empty Weight Fractions
*[Raymer, Table 21.4, p. 801]*

| Aircraft Type | Typical We/W0 |
|---|---|
| Scout/attack helicopter — light armor and weapons | 0.5-0.6 |
| Scout/attack helicopter — heavy armor and weapons | 0.6-0.8 |
| Transport helicopter | 0.45-0.55 |
| Civil/utility helicopter | 0.45-0.6 |
| Tilt rotor | 0.55-0.7 |

### §21.3.9 Helicopter Design Process
*[Raymer, p. 801]*

Broadly parallels the fixed-wing design process (Intermission between Chapters 11-12) but with key
differences. Design requirements must additionally include allowable autorotation descent speed and
required hover ceiling (in- or out-of-ground effect). After configuration sketches (rotor
configuration, antitorque technique) and initial W/S and W/P selection/sizing (gross weight, fuel
weight), a helicopter designer — unlike a fixed-wing designer, who would move straight to a
configuration layout — will typically run a rotor-optimization program (solidity, blade shape,
airfoil, twist, disk loading, required power) *before* developing the actual design layout.

### What We've Learned
*[Raymer, p. 802]*

Vertical flight is difficult and imposes major design compromises, but is worth it for the right
missions. Helicopters are more efficient than jet VTOL for vertical flight but cannot match jet (or
tilt-rotor) forward speed.

---

*Chapter 21 complete (§§21.1-21.3.9, Tables 21.1-21.4, Figs 21.1-21.17, Eqs 21.1-21.18). No numbered
in-chapter reference list (footnote citations refer to the book's consolidated bibliography, not
reproduced here). No OCR-garbled equation coefficients encountered; a few OCR-mangled Greek/variable
glyphs in the source scan (`Ȼ`, `ʓ`, stray accented characters in Eqs. 21.9-21.16) were resolved by
cross-checking against the surrounding derivation logic and standard momentum-theory notation —
flagged here in case of residual transcription ambiguity `[verify pp. 794-798]`.*
