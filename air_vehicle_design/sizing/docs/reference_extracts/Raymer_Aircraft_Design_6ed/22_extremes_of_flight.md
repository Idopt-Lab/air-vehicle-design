# Chapter 22 — Extremes of Flight

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 22
"Extremes of Flight," printed pp. 805-832.

Three sub-chapters: Rockets/Launch Vehicles/Spacecraft (quantitative — the Rocket equation and
Delta-V, Eqs. 22.1-22.17, Tables 22.1-22.3), Hypersonic Vehicles (largely qualitative), and Lighter
Than Air / airships (quantitative near the end — hydrostatic lift, Eq. 22.18). Footnote citations
refer to the book's consolidated bibliography, not reproduced here.

---

## §22.1 Introduction
*[Raymer, p. 805]*

This chapter covers speed extremes outside the "normal" range (low subsonic to ~Mach 2.2) covered
elsewhere: much faster (rockets, hypersonic vehicles) and much slower (airships). Rockets and
airships share a surprising commonality: both are dominated by the volume of their "propellant" (an
airship's lifting gas, in effect, propels it upward), both are far more sensitive to empty weight
than a normal aircraft than, and — for different reasons — **neither can use the Breguet range
equation**. (Hydrogen is, not coincidentally, both the ideal rocket propellant and the ideal airship
lifting gas, practical considerations aside.)

## §22.2 Rockets, Launch Vehicles, and Spacecraft

### §22.2.1 Propulsion and Isp
*[Raymer, p. 806]*

Launch-vehicle/spacecraft design shares the aircraft design process (sizing, layout, analysis,
iteration) but propulsion dominates even more: acceleration requirements are so large that
**propellant is typically ~9/10 of vehicle mass** (vs. about 1/3 for a typical aircraft; the
GlobalFlyer's 83% fuel fraction is aircraft's current record, still "a rather poor rocket value").
Rocket propulsion is a **reaction drive** ("throwing rocks out of the back of a canoe" — more rocks,
thrown faster, means more delta-V). Two categories: (1) chemical rockets, where the propellant
itself supplies the energy (combustion heat/pressure); (2) rockets where the energy source (electric,
nuclear, solar) is separate from the expelled mass — in this case hydrogen (lowest atomic number)
makes the best "rock" to throw. ("Rocket" names both the engine and, informally, the whole vehicle;
"motor" = solid rocket engine, "engine" = liquid rocket engine.)

Thrust follows Newton's Third Law (propellant pushed out the back pushes the vehicle forward) and
Second Law (force = rate of momentum change):

**Eq (22.1)** — Newton's Second Law (general form, discrete + continuous mass) *[Raymer, Eq. (22.1),
p. 806]*:
```
F = m*a + m_dot*Vexhaust
```
(`Vexhaust` relative to the vehicle.) There is also a **pressure thrust** term (nozzle exit area x
(exhaust pressure - ambient pressure)), which is why rocket thrust varies with altitude; maximum
thrust occurs when pressure thrust is zero (all available energy goes to accelerating the exhaust).
Nozzle exit area is normally chosen to minimize pressure thrust averaged over the flight path, so it
is dropped from the following analysis.

**Eq (22.2)** — Total impulse (integrating Eq. 22.1 with pressure thrust neglected)
*[Raymer, Eq. (22.2), p. 807]*:
```
I_total = integral(F dt, 0 to t) = integral(m_dot*Vexhaust dt, 0 to t)
```

**Eq (22.3)** — Specific impulse *[Raymer, Eq. (22.3), p. 808]*:
```
Isp = I_total / (fuel burned) = integral(m_dot*Vexhaust dt) / (g0 * integral(m_dot dt)) = Vexhaust/g0
```
(the last equality assumes constant exhaust velocity over the burn). `g0` is the Earth-standard
gravitational constant, used even far from Earth purely to convert mass to an equivalent weight
force — adjusting it for altitude is flagged as a common student error. With `g0` used this way,
`Isp` comes out in seconds in both British and metric units (a genuine advantage over other unit
systems); using mass flow instead of weight flow of propellant would instead give `Isp` in velocity
units, numerically equal to the effective exhaust velocity (a convention sometimes used, especially
in Europe, but not unit-invariant). `Isp` relates to aircraft SFC: in British units they are
reciprocals of each other (`Isp = 3600/SFC`) — for SFC, "big is bad"; for `Isp`, "big is good."
In metric units the SFC-to-Isp conversion needs the gravitational constant explicitly. (Historical
aside: Tsiolkovsky derived the Rocket equation in 1895, before SFC or aircraft existed — the
author speculates rocket scientists may also have avoided the aircraft SFC convention partly out of
embarrassment: SFC=2 for a bad jet engine vs. SFC=10 for a good chemical rocket looks worse than
Isp=360 s, though it isn't the rocket's "fault" — it must carry its own oxidizer, unlike an
air-breathing jet, though that "free" oxygen costs the jet engine 5-10x more installed weight per
unit thrust.)

**Eq (22.4)** — Rocket propulsive efficiency *[Raymer, Eq. (22.4), p. 809]*:
```
eta_p = F*V / (F*V + (1/2)*m_dot*(Vexhaust - V)^2) = (2*V/Vexhaust) / (1 + (V/Vexhaust)^2)
```
where `F` = thrust, `V` = vehicle velocity, `Vexhaust` = effective exhaust velocity relative to the
vehicle = thrust/mass flow = `g0*Isp`. Maximized (eta_p = 1.0) when `Vexhaust = V` — the same
analytic result as for aircraft propellers (Chapter 13) but with a different physical implication:
for an aircraft, ideal efficiency implies zero net thrust (no acceleration of the oncoming flow); for
a rocket, thrust still exists because the propellant starts at rest relative to the vehicle and is
accelerated up to `Vexhaust`. `Vexhaust = V` also means the exhaust ends with zero velocity relative
to an outside observer (as if the vehicle "laid down" stationary rocks along its path) — optimal
because any residual exhaust velocity costs energy without helping propulsion. Note `Vexhaust = V`
maximizes *energy efficiency*, not *thrust per propellant expended*: if energy is cheap/available
(e.g., separate energy source such as nuclear-thermal), use the highest practical exhaust velocity;
otherwise trade a heavier/more-powerful energy source against additional propellant mass via a
dedicated trade study. (Notation aside: "real" rocket scientists use `C` for `Vexhaust`; the book
reserves `C` for SFC, as in the Breguet equation.)

### Table 22.1 — Typical Specific Impulse for Rockets
*[Raymer, Table 22.1, p. 810]*

| Rocket Type | Typical Isp (s) |
|---|---|
| Chemical, liquid — LOX-Hydrogen | 360-450 |
| Chemical, liquid — LOX-Methane | 270-350 |
| Chemical, liquid — LOX-RP (kerosene) | 250-330 |
| Chemical, solid propellant | 180-220 |
| Nuclear thermal | 800-2000 |
| Nuclear pulse (Orion) | 4000+ |
| Electrothermal | 400-2000 |
| Ion | 4000-25,000 |
| Solar heating | 400-700 |

`Isp` alone is not the whole story: propellant density affects vehicle size and empty weight.
Hydrogen (excellent Isp) has very low density, forcing large, heavy tanks/airframe — a problem noted
again for hydrogen-fueled aircraft (Fig. 22.7, referenced but not reproduced in this chapter's
extract). Solid propellants (worse Isp than hydrogen) are dense, giving smaller stages.
**Density impulse** = propellant specific gravity x Isp — a useful (but only a guide, not
sufficient alone) comparison metric; higher is better.

**Reactionless drives** (no "rock throwing") are largely impractical today: **solar sails** use
photon pressure for free thrust but need enormous, extremely light sail area, with unresolved
unfurling/control problems; other exotic candidates (tethers, space elevators, electrodynamic drives,
etc.) are surveyed in Robert L. Forward's *Indistinguishable from Magic* [Ref. 149]. Two practical
non-propulsive ways to change spacecraft velocity: **gravity assist** (planetary flyby, like a
bicyclist grabbing a passing car — changes the vehicle's speed/direction while minutely doing the
reverse to the planet) and **aeroassist** (atmospheric drag deceleration at a destination planet —
used by returning Apollo capsules to shed lunar-return velocity and save propellant).

### §22.2.2 Delta-V
*[Raymer, p. 810]*

The rocket-design analog of an aircraft's range requirement is **Delta-V** (a required velocity
change, independent of propulsion type, driven by the mission's orbital-mechanics objective — e.g.
Earth orbit to Mars orbit needs roughly 38,000 fps / 12,000 mps). Burn duration is normally short
compared to transit time and is ignored for initial design. Determining required Delta-V is an
orbital-mechanics exercise. For a circular orbit, "centrifugal force" (an engineering fiction, but
convenient: `m*v²/R`) balances weight:

**Eq (22.5)** — Centrifugal force = weight *[Raymer, Eq. (22.5), p. 811]*:
```
m*v_s^2/R = m*g
```

**Eq (22.6)** — Gravitational acceleration vs. altitude *[Raymer, Eq. (22.6), p. 812]*:
```
g = g0 * (R0/(R0+h))^2
```

**Eq (22.7)** — Required orbital velocity *[Raymer, Eq. (22.7), p. 812]*:
```
v_s = R0 * sqrt(g0/(R0+h))
```
where `h` = height above ground, `g0` = surface gravity (Earth: 32.1727 ft/s² / 9.8062 m/s²),
`R0` = planet radius (Earth: 20,925,646 ft / 6,378,137 m; other planets in Table 22.2). Delta-V to
enter orbit at a given altitude (once you're there) = required orbital velocity minus current
velocity. Launching due-East gets a "free" assist from Earth's rotational surface speed at the
equator (1,542 fps / 470 mps, scaled by cos(latitude)) — no assist for polar orbits, and a Delta-V
penalty launching West; lower-latitude launch sites are therefore preferred (why the USSR used
Kazakhstan rather than a Russian site). Fighting gravity and drag on the way up adds roughly
6,000 fps (1,830 mps) to the Earth-orbit Delta-V requirement (approximable via the energy-height
methods of Chapter 17; time-stepping simulation gives a better answer).

### Table 22.2 — Data for Heavenly Bodies (after [150])
*[Raymer, Table 22.2, p. 813]*

| Name | Orbit Radius (mil st. miles) | Period of Revolution About Sun | Mean Diameter (km) | Relative Mass (Earth = 1.0) | Specific Gravity (1 = water) | Acceleration of Gravity at Surface (m/s²) | Escape Velocity at Surface (m/s) |
|---|---|---|---|---|---|---|---|
| Sun | — | — | 1,393,000 | 332,000 | 1.41 | 273.4 | 616,000 |
| Moon | 0.238 | 27.3 days | 3475 | 0.012 | 3.34 | 1.58 | 2380 |
| Mercury | 35.96 | 87.97 days | 4990 | 0.053 | 5.30 | 3.60 | 4200 |
| Venus | 67.20 | 224.7 days | 12,200 | 0.815 | 4.95 | 8.50 | 10,300 |
| Earth | 92.90 | 365.256 days | 12,755 | 1.00 | 5.52 | 9.806 | 11,179 |
| Mars | 141.6 | 686.98 days | 6760 | 0.107 | 3.95 | 3.749 | 5000 |
| Jupiter | 483.3 | 11.86 yr | 14,000 | 318.4 | 1.33 | 26.0 | 61,000 |
| Saturn | 886.2 | 29.46 yr | 125,000 | 95.2 | 0.69 | 13.7 | 36,600 |
| Uranus | 1783 | 84.0 yr | 47,600 | 14.5 | 1.56 | 9.39 | 21,900 |
| Neptune | 2794 | 164.8 yr | 44,700 | 17.2 | 2.27 | 14.9 | 25,000 |
| Pluto | 3670 | 248.4 yr | 14,000 | 0.90 | 4.00 | 7.62 | 10,000 |

**Corrected 2026-08-18 against 300-dpi and 700-dpi renders of book p. 813.** The earlier extract of
this table was substantially wrong and is fully replaced above. What was wrong:

- **The second column was mislabelled and its values were invented.** The book's column is
  **"Orbit Radius, (mil st. miles)"** — millions of STATUTE MILES. The earlier extract relabelled it
  "Mean Distance from Sun (Mkm)" and filled it with modern astronomical values in millions of km
  (57.9, 108.2, 149.6, …). None of those numbers appear on the page. The book's own numbers are
  35.96, 67.20, 92.90, … , which are the same distances in millions of statute miles.
- **The row order was changed.** The book prints Sun, **Moon**, Mercury, Venus, Earth, Mars, Jupiter,
  Saturn, Uranus, Neptune, Pluto. The Moon is the second row, not the last.
- **Five outer-planet / Pluto cells were replaced with modern reference values.** The book prints
  Jupiter mean diameter 14,000; Saturn 125,000; Uranus 47,600; Neptune 44,700; and the whole Pluto
  row as 14,000 / 0.90 / 4.00 / 7.62 / 10,000. The earlier extract had 142,800 / 120,660 / 51,120 /
  49,530 and a Pluto row of ~2370 / 0.0022 / ~1.8 / ~0.66 / ~1200. Everything is now as printed.

**Book misprints in Table 22.2.** Two cells of the printed table are physically wrong and are kept
as printed above, with this note rather than a silent fix:
- **Jupiter mean diameter, 14,000 km.** Jupiter's diameter is about 142,800 km. The printed value is
  internally inconsistent with the same row's relative mass of 318.4 and specific gravity of 1.33,
  which together imply a diameter near 143,000 km. The digits appear to have been truncated.
- **The whole Pluto row.** A mean diameter of 14,000 km with a relative mass of 0.90 and a surface
  gravity of 7.62 m/s² describes a near-Earth-sized body, not Pluto (about 2370 km, 0.0022 Earth
  masses, 0.62 m/s²). The row also repeats Jupiter's misprinted 14,000. Treat the Pluto row as
  unusable.
Do not use this table as a source of planetary data; it is reproduced here only because Raymer's
Hohmann-transfer discussion (Table 22.3) refers back to it.

To travel between orbital radii (planet-to-planet, or Earth-orbit-to-Moon), the minimum-fuel
strategy is the **Hohmann transfer orbit** — an elliptical orbit exactly tangent to the starting and
ending radii (see Bate et al. [Ref. 151] for full analysis). Launch "windows" are the times when
Hohmann-transfer timing puts the target planet where the transfer orbit arrives; missing a window
requires more propellant via a less-optimal trajectory. On arrival, a second Delta-V burn
"circularizes" the orbit; for a landing, the target's gravity well helps but the vehicle must shed
velocity equal to the target's escape velocity (aeroassist can help if there's an atmosphere).

### Table 22.3 — Hohmann Transfer Orbit Results (from Earth orbit)
*[Raymer, Table 22.3, p. 814]*

| Target Planet | Minimum Launching Velocity (mps) | Transfer Time |
|---|---|---|
| Mercury | 13,411 | 110 days |
| Venus | 11,582 | 150 days |
| Mars | 11,582 | 260 days |
| Jupiter | 14,021 | 2.7 years |
| Saturn | 14,935 | 6 years |
| Uranus | 15,545 | 16 years |
| Neptune | 15,850 | 31 years |
| Pluto | 16,154 | 46 years |

### §22.2.3 Rocket Equation
*[Raymer, p. 815]*

Once required Delta-V is known, the propellant mass to achieve it comes from the **Rocket
equation** (Tsiolkovsky), the rocket analog of the Breguet range equation. Derived from conservation
of momentum for a discrete propellant "blob" pushed out (Fig. 22.1):

**Eq (22.8)/(22.9)** — Momentum before/after *[Raymer, Eqs. (22.8)-(22.9), p. 815]*:
```
Before: (m_final + m_propellant) * V0
After:  m_final*(V0 + Delta_V) + m_propellant*(V0 - Vexhaust)
```

**Eq (22.10)** — solving for Delta-V *[Raymer, Eq. (22.10), p. 815]*:
```
Delta_V = m_propellant * Vexhaust / m_final
```

Replacing the discrete blob with continuous mass flow and integrating gives the general Rocket
equation:

**Eq (22.11)** — Rocket equation using Vexhaust *[Raymer, Eq. (22.11), p. 815]*:
```
Delta_V = Vexhaust * ln(mi/mf)
```

**Eq (22.12)** — Rocket equation using Isp *[Raymer, Eq. (22.12), p. 815]*:
```
Delta_V = g0 * Isp * ln(mi/mf)
```

**Eq (22.13)** — Rocket equation, mass ratio form (most useful for sizing)
*[Raymer, Eq. (22.13), p. 816]*:
```
mi/mf = e^(Delta_V/(g0*Isp)) = e^(Delta_V/Vexhaust)
```
This is a mission-segment-weight-fraction form (cf. Chapter 3), directly giving the propellant mass
needed for a required Delta-V.

**Staging.** Stacking rockets to shed dead weight (tanks, engines) as they empty was proposed in
1650 and analyzed by Tsiolkovsky. Staging geometries (Fig. 22.2): sequential burn (most staged
rockets, vertically stacked — upper-stage engines, optimized for high-altitude-only operation,
start only after the lower stage drops, giving less drag/weight than alternatives); parallel burn
with strap-on boosters or extra engines (all engines fire at liftoff, maximizing GLOW — gross
liftoff weight — usually paired with a high-altitude-optimized third stage); the Space Shuttle
geometry (cheap expendable external tank + recovered orbiter with the expensive hardware, plus
parallel-burn strap-on boosters).

**Eq (22.14)-(22.17)** — Staged Rocket equation *[Raymer, Eqs. (22.14)-(22.17), p. 816]*:
```
Delta_V_total = sum(Delta_V_i, i=1..n) = Delta_V1 + Delta_V2 + Delta_V3 + ...
Delta_V_total = g0*Isp*ln(mi/mf)   (per stage, summed)
```
assuming (approximately) equal `Isp` across all stages (true if the same engine/propellant type is
used, altitude effects notwithstanding), and, as a further simplifying (if dubious) assumption,
ignoring the empty weight of all but the last stage — this illustrates why a staged rocket's
effective mass ratio looks far better than a single-stage vehicle's.

**Reusability.** Most launch vehicles are expendable (a new vehicle bought each flight — "imagine
doing that with airliners"); even the Space Shuttle discarded its external tank and required full
disassembly/remanufacture of its recovered solid boosters. Reusability should cut operating cost but
raises development cost and weight: the booster must survive reentry heating/loads, land (ideally at
a chosen site rather than an ocean recovery — possibly needing turbojet/rocket/towed/glide "flyback"
capability, complicated by the aft c.g. typical of an empty booster), operate well past main-engine
cutoff (more subsystems, weight, cost), and be sized to include all of this — launch-vehicle
boosters have extremely high sizing growth factors, amplifying any such weight addition. Whether
total reusable-system cost beats simple expendability remains an open question, but active efforts
include winged reentry boosters (Fig. 22.3) and the (as of writing) recently flight-proven
rocket-landed SpaceX Falcon Heavy first-stage boosters. An alternative is an aircraft "zeroth stage":
Orbital Sciences' Pegasus (carried by a converted L-1011); Scaled Composites' SpaceShipOne/Two
(launched from purpose-built White Knight One/Two); the enormous twin-fuselage Stratolaunch aircraft
(six 747 engines, largest wingspan ever built, intended to carry up to three upper-stage rockets or
eventually a reusable "Black Ice" orbiter); the unbuilt Pioneer Rocketplane (turbojet-powered manned
first stage meeting a tanker aircraft in flight to load LOX before boosting to space — no serious
technical obstacle identified except the undemonstrated aerial transfer of liquid oxygen).

### Fig 22.1 — Discrete and continuous propellants pushing a rocket
*[Raymer, Fig. 22.1, p. 807]* — Two schematic panels illustrating (top) a discrete propellant
"blob" ejection and (bottom) continuous mass-flow ejection, supporting the momentum-conservation
derivation of Eqs. (22.8)-(22.11). No plotted data (derivation diagram).

### Fig 22.2 — Staging geometries
*[Raymer, Fig. 22.2, p. 816]* — Four schematic launch-vehicle stacks: sequential burn (most
rockets, e.g. Soyuz-like); parallel-burn strap-on boosters (e.g. Atlas-like); parallel-burn engines;
Space-Shuttle-style dropped-tank arrangement. No plotted data (concept diagram).

### Fig 22.3 — Reusable first-stage launch vehicle (Raymer 2014)
*[Raymer, Fig. 22.3, p. 818]* — Concept illustration of a winged reentry booster design by the
author. No plotted data (concept art).

## §22.3 Hypersonic Vehicles

### §22.3.1 Hypersonic Flight
*[Raymer, p. 819]*

"Hypersonic" is loosely Mach 5+ (Mach 3 "seems stationary" by comparison), but is more precisely
defined by flow phenomena absent at lower speed:

1. Shock angles lie so close to the surface that they form a "shock layer" strongly interacting with
   the boundary layer, which becomes 1-2 orders of magnitude thicker than at lower speed — creating
   an "apparent body" that looks blunt to the freestream regardless of actual nose shape. This
   violates common CFD assumptions, requiring specialized hypersonic codes.
2. Extreme heating causes molecular excitation and dissociation/ionization — the air is "not really
   air anymore," a physics not captured even by full Navier-Stokes codes without modification.
3. At high altitude, low density + high speed breaks the usual CFD "no-slip" surface assumption
   (surface molecules retain tangential velocity rather than sticking to the surface).
4. Forces/moments vary strongly nonlinearly with angle of attack.

**Newtonian impact theory** (modeling flow as a stream of pellets hitting the surface, wrong at
subsonic speed but reasonably accurate at Mach 5+) gives a first-order pressure estimate: air
particles are assumed turned parallel to the surface, with the perpendicular momentum component
exerted as surface pressure. From this, a hypersonic vehicle's **center of lift** is roughly the
geometric centroid of total planform area (fuselage included) — the configuration must keep this
centroid near the c.g., which can conflict with subsonic stability requirements (pushing the wing aft
of where hypersonic balance wants it), often motivating a strake or double-delta layout.

**Thermal management** is a key hypersonic design driver. Supersonic aircraft like the SR-71 use
fuel as a heat sink (routed through heat exchangers absorbing nose/leading-edge/engine heat) plus
heat-radiating black paint; flight profiles are actually heat-absorption-limited (must slow down
once heat-sink capacity runs out). Problems worsen at hypersonic speed. The Space Shuttle reaches
surface temperatures over 3000°F (1650°C). Extreme thermal loads set a practical minimum nose radius
of ~1-2 ft (30-60 cm) for a hypersonic reentry vehicle (with the nose slope aft of the cap kept
≥15-20 deg from horizontal), and a minimum wing/tail leading-edge radius of ~1-2 in. (3-5 cm) absent
exotic materials/active cooling. The Shuttle and similar designs still use conventional aluminum
structure, protected by a **thermal protection system (TPS)**: thermal tiles/blankets, plus
carbon-carbon composite or ceramics at the highest-heating regions (nose, leading edges). TPS
thickness/weight must be considered from earliest design: a first approximation allows ~1-2 in.
(3-5 cm) on the bottom, <1 in. on top. Advanced TPS coverings weigh ~0.5-1.0 lb/ft² (2.4-5 kg/m²);
the Space Shuttle's tile TPS averages ~1.6 lb/ft² (7.8 kg/m²), plus ~0.25-1.0 lb/ft² for attachments
(bonding agent, strain-isolation pad). Skipping TPS in favor of exotic structural materials alone is
usually heavier overall per trade studies; final TPS choice depends on max Mach, high-speed-flight
duration, and available cooling fuel.

Some hypersonic vehicles (Shuttle, cruise missiles) use fairly conventional wing-fuselage layouts
(planform a landing-speed/high-speed-drag compromise; reentry g-loading often sets wing loading).
For efficient hypersonic cruise, the **Hypersonic Waverider** — a highly swept flying wing shaped
so its own shocks are defined/constrained by the leading edges, flying "on top of" the shocks it
creates — gives substantially better hypersonic L/D than a simple wing-fuselage arrangement. Early
waverider concepts were swept triangular wedges with negative dihedral; later viscosity-inclusive
analysis revised the optimal shape (thumbnail-like planform, downward-pointing-bow cross-section).
Integrating the ideal waverider shape with engines, gear, cockpit, and payload is left as a design
challenge.

### Fig 22.4 — Hypersonic Waverider (NASA Langley / University of Maryland)
*[Raymer, Fig. 22.4, p. 821]* — Two illustrations: (top) a viscous-optimized waverider shape
(thumbnail-like planform, bow-shaped cross-section); (bottom) a notional full vehicle design (Univ.
of Maryland) integrating a slightly different waverider geometry with practical vehicle systems. No
plotted numeric data (concept illustrations).

### §22.3.2 Hypersonic Propulsion
*[Raymer, p. 822]*

The Space Shuttle and ICBM reentry vehicles are unpowered hypersonic gliders. Positive net thrust
from an air-breathing engine is very hard above roughly Mach 8: net thrust = gross thrust minus
engine-related (including momentum) drag; slowing incoming air enough to mix/burn fuel easily makes
momentum drag prohibitive, while not slowing it enough makes mixing/combustion in the available
transit time very difficult — either way, net thrust is a small difference between two very large
numbers, easily driven negative by small errors. Regular turbojets need air slowed to ~Mach 0.4-0.5
(raising both temperature and pressure); above ~Mach 3 incoming air temperature alone nearly exceeds
turbine blade limits, and adding combustion would destroy the blades. The **air turbo rocket**
avoids this by never passing outside air through the turbine — a fuel-rich rocket motor (kept cool
by the rich mixture) drives the turbine/compressor, with leftover rocket fuel burned when the rocket
exhaust mixes with compressor air downstream of the turbine (still requires carrying some oxidizer
despite being nominally air-breathing). The **ramjet** avoids turbine heating entirely (no turbine —
inlet-only compression, fuel added/burned, exits through a nozzle) but produces no static thrust
(needs a separate takeoff device, e.g. rocket booster); it is more efficient than the air turbo
rocket at higher speed. The **air turbo ramjet** hybridizes the two, switching flowpaths to ramjet
mode at higher speed. The ramjet still slows air to subsonic internal speed, so momentum-drag losses
become excessive at hypersonic speed; the **scramjet** (supersonic combustion ramjet) mixes/burns
air at supersonic internal speeds — demonstrated in the lab but not yet in an operational engine.
NASA's Hyper-X (X-43) flight-tested a scramjet at Mach 9.6 in 2004 (boosted to test speed by a much
larger rocket stage; only a few seconds of test time); Boeing's X-51 demonstrated 2+ minutes of
scramjet burn in 2010, but only at Mach 6 (also rocket-boosted to the test condition). References
[155, 156] are recommended for hypersonic/reentry aerodynamics, propulsion, and flight mechanics.

### Fig 22.5 — Scramjet CFD analysis (NASA Langley Research Center)
*[Raymer, Fig. 22.5, p. 823]* — CFD visualization of an airframe-integrated scramjet's lower
surface; the vehicle forebody forms the inlet compression ramps, the afterbody forms the nozzle
expansion surface. No plotted numeric data (CFD visualization).

## §22.4 Lighter Than Air

### §22.4.1 LTA Applications
*[Raymer, p. 823]*

Historical framing: Alberto Santos-Dumont's 1898 gasoline-powered airship is credited (by the
author's definition of controlled, returnable flight) as arguably the true first flight — he reached
1,300 ft (400 m) over Paris; in 1901 he won the Deutsch Prize for a 7-mile (11-km) course flight
under 30 min including rounding the Eiffel Tower. Count von Zeppelin's rigid-structure LZ-1 (1900,
420 ft/128 m long, 399,000 ft³/11,300 m³ hydrogen capacity) led to Zeppelin's military and (postwar)
successful transatlantic passenger service (the 1928 Graf Zeppelin flew over a million
incident-free miles, including an aerial circumnavigation) — ended by the fragility/hydrogen-fire
risk culminating in the 1937 Hindenburg disaster, roughly coincident with airplanes becoming
practical for passenger service. Military LTA continued (WWII US Navy convoy-escort blimps,
retired 1962) and persists today mostly for advertising (Goodyear blimps, now actually Zeppelin
NT semirigid airships) plus renewed interest for sightseeing, bulky cargo, border patrol, logging,
missile defense, and high-altitude "poor man's satellite" applications (persistent hover for
communications/relay/sensing, exploiting airships' large size for radar apertures impractical on
airplanes) — including a proposed "orbital airship" that climbs to 200,000 ft (61,000 m) on
buoyancy before boosting to orbital speed via electric ion propulsion. Current programs: Lockheed's
P-791 hybrid airship; Northrop Grumman/Hybrid Air Vehicles' HAV 304, evolved into the Airlander 10.

### §22.4.2 Airship Types
*[Raymer, p. 825]*

Three main types ("dirigible" comes from French *dirigeable*, "steerable," not from "rigid"):

- **Nonrigid** ("blimps") — streamlined balloons needing a slight internal overpressure (~5 psf /
  0.24 kN/m²) to resist aerodynamic "dishing"; small enough that a puncture is only a slow leak
  (unless near the top).
- **Semirigid** — blimp-like (needs internal pressure for shape) but with added internal/external
  structure distributing loads to the fabric; most Santos-Dumont designs were of this type.
- **Rigid** ("zeppelins") — external structure holds shape without internal pressurization; usually
  fabric-covered (some metal-skinned), lifting gas held in separate cells for redundancy.

A **hybrid** airship variant gets part of its lift aerodynamically (lifting hull, wings, or even a
helicopter rotor) — not new (Santos-Dumont flew a winged airship in 1903), and criticized in a 1927
textbook as combining both types' disadvantages while losing both types' merits — true for
weight/drag, but the hybrid's key operational advantage is that it is **heavier than air**: a
conventional (fully buoyant) airship is hard to handle on the ground (needs a ground crew/mooring
mast, must weathervane freely, needs ballasting once payload/fuel is removed, and gets progressively
too light to land as fuel burns off, requiring gas venting or exhaust-water recovery). A hybrid, with
only partial hydrostatic lift, has a substantial ground download and can land/taxi like a normal
airplane, while the hydrostatic-lift contribution still gives a high effective L/D at low speed. Per
the author's own analytical studies, a roughly 50-50 aerodynamic/hydrostatic lift split gives the
best balance of cruise efficiency and ground handling, though the optimum is application-dependent;
hybrids cannot hover for cargo loading unless VTOL-powered or enough fuel has burned off to reach
100% buoyancy.

### Fig 22.6 — Ohio airship "Dynalifter" hybrid airship (D. Raymer, 2001)
*[Raymer, Fig. 22.6, p. 826]* — Illustration of a hybrid airship design combining lifting-hull
buoyancy with aerodynamic lift. No plotted data (concept art).

### §22.4.3 Hydrostatic Lift
*[Raymer, p. 827]*

Airship lift follows **Archimedes' Principle**: gross buoyancy = weight of displaced air, from which
the lifting-gas weight is subtracted for net lift. Sea-level standard-day air density = 0.0023769
slug/ft³ (1.225 kg/m³), weight-force equivalent 0.0765 lb/ft³ (12.01 N/m³) — this is the gross lift
per unit displaced volume. Air density varies with altitude (Appendix B tables), temperature
(**Charles' Law** — volume varies directly with absolute temperature at constant pressure), and
barometric pressure (**Boyle's Law** — volume varies inversely with pressure at constant
temperature). Humid air is less dense than dry air (fully saturated air at 32°F/0°C weighs only
~0.5% more than dry; at 90°F/32°C, saturated air weighs 5.2% more — density varies roughly linearly
with percent saturation; 50% saturation is a common design assumption).

Three main lifting gases: **hydrogen** (common, producible anywhere by electrolysis, best lift, but
flammable/explosive — now forbidden for passenger-carrying airships); **helium** (~10% less lift,
more expensive, inert, only naturally available blended with natural gas); **hot air** (used for
recreational balloons/some airships, heating limited to flight duration). Rule-of-thumb lift: per
1000 ft³ (28.3 m³), hydrogen lifts ~68 lb, helium ~60 lb (metric: per 1000 L/m³, hydrogen ~1.1 kg,
helium ~1.0 kg); hot air lifts ~20 lb per 1000 ft³ (0.300 kg/m³), temperature-dependent. Sea-level
standard-day weight-force densities: hydrogen 0.00532 lb/ft³ (0.836 N/m³), helium 0.01056 lb/ft³
(1.66 N/m³). Lift capacity is reduced by gas impurity (fresh fill ~98%+ pure; historic "Golden Age"
airships lost ~2-3% purity/year via leakage, modern designs about half that — impure-gas density is
the weighted average of lifting gas and air).

Since altitude/temperature affect lifting-gas density by the *same* proportion as the displaced air,
**net lift is unchanged** if the gas bag can freely expand/contract with altitude — a
counterintuitive but true result (extreme-altitude balloons are launched mostly empty, ballooning
to near-full/round shape only at design altitude). The maximum design altitude is the **pressure
height**; hull volume is sized to the gas volume at pressure height, larger than the sea-level gas
volume — a higher pressure height means a larger (heavier, draggier, costlier) gas bag; a lower one
limits flight routes/weather tolerance.

**Eq (22.18)** — Percent fullness at sea level (Charles'/Boyle's Laws) *[Raymer, Eq. (22.18),
p. 829]*:
```
%F = P_H/P_SL = (P_H * T_SL) / (P_SL * T_H)
```
where `P_H`, `T_H` = pressure and absolute temperature at the desired pressure height; `P_SL`,
`T_SL` = desired sea-level conditions (not necessarily standard). Total hull volume needed = required
sea-level lifting-gas volume / %F. Example: reaching 10,000 ft without venting gas needs sea-level
%F ≈ 0.74, so hull volume must be 1.35x the sea-level lifting-gas volume (26% of hull volume is air
at sea level, held in **ballonets** for non-rigid/semirigid designs). For rigid airships, the hull is
simply sized large enough for the fully-expanded gas bags; below pressure height, ambient air enters
the hull and presses the (floating) gas bags toward the top. For non-rigid/semirigid designs, venting
excess gas on ascent risks envelope collapse on descent — solved by the **ballonet** ("balloon within
a balloon"): it collapses (venting only air, not lifting gas) as the lifting gas expands on ascent,
and is reinflated by an air fan (or ram-air scoops behind the propellers) on descent, pressing the
lifting gas back up. (Historical near-miss: on Santos-Dumont's very first flight, an underpowered
ballonet air pump let the envelope collapse into a dangerous "V" shape on descent, high over Paris —
he survived and used stronger fans on later designs.) **Superpressure** balloons instead build the
envelope strong enough to tolerate internal pressure above ambient at altitude without venting,
relaxing the percent-fullness requirement (useful for long-duration flight where daytime heating
would otherwise force venting) — also being explored, with an obvious weight penalty, for
long-duration airships. Compressing excess helium into onboard fabric tanks during ascent (revived
from an early, previously-abandoned idea) is another alternative to venting, and additionally lets a
landed vehicle be pressurized/"planted" firmly for cargo loading. Hot-air balloon lift uses Charles'
Law directly on the heated-air volume/density (typical internal envelope temperature ~250°F/120°C).

### §22.4.4 Airship Design and Analysis
*[Raymer, p. 830]*

Key differences from aircraft aerodynamic analysis: no wing area exists for a reference area, so
airship designers use frontal area (common in drag tables) or, more commonly, **total hull volume
raised to the 2/3 power** (`V^(2/3)`) for area units. Tail sizing is similarly based on `V^0.66`,
often ~13% of that value. Most historic airships were actually yaw-unstable, but divergence was slow
enough for a competent helmsman to compensate; in pitch, the low c.g. relative to the hull's
hydrostatic lift center adds stability countering aerodynamic instability. **Standard displacement
D** = hull volume x sea-level standard-day air density (the weight of air displaced by the hull).
Optimal hull **fineness ratio** (per Chapter 6) is roughly 6-8 for best aerodynamics, but structural
weight favors lower fineness — recent studies suggest ~4 for non-rigid/semirigid, ~6 for rigid
airships. Chapter-12 parasitic-drag methods work reasonably well for airship hulls (apply a 0.85
factor to the body-drag equation for beneficial scale effects); any reference area convention may be
used as long as it's tracked consistently. Chapter-12 **lift** methods work poorly for airship hulls
(not simply an extreme-low-AR wing — highly 3-D flow, a complicated fore-aft/wraparound separation
line, hull-shape flexing under load defeats even high-end CFD). Rough approximation: lift-curve
slope `CL_alpha` ≈ 0.6 referenced to `V^(2/3)` (≈0.24 referenced to total planform area), strongly
nonlinear with ill-defined stall — but airship hulls normally contribute negligible lift (that's
what the gas is for).

**Breguet does not apply** to conventional airships: Breguet integrates specific range against a
changing lift-to-drag ratio as weight changes, but a conventional airship generates little/no
aerodynamic lift, so drag does not change with weight — range is simply engine run time x speed.
Because of their large size, airship engines must also accelerate the entrained **apparent mass**
of surrounding air dragged along by viscosity (an old NACA TR 117 rule of thumb: apparent mass ≈
2.5% of total hull volume x air density; usually ignored for airplanes but not negligible for
airships), plus the mass of the lifting gas itself (despite its "negative weight"). For a
**hybrid** airship generating substantial aerodynamic lift in cruise, standard aircraft performance
equations (including Breguet) can generally be reused after one key substitution: **reduce all
weight terms `W` by the hydrostatic lift** (reducing the load the wings must carry and hence
induced drag) — but this substitution does *not* apply to acceleration-driven calculations (e.g.
takeoff), which must still accelerate the vehicle's full mass plus apparent mass plus lifting-gas
mass.

Airship weights analysis parallels aircraft weights analysis but the available statistical methods
are old, closer to rules of thumb than rigorous regressions — e.g. one old approximation: fixed
weight excluding powerplant ≈ 30% of standard displacement `D`; crew/ballast/stores ≈ 5.5% of `D`.
Better estimates need structural analysis plus vendor data for subsystems, skin coverings, and gas
cell materials; some structural loads are unique to airships, and airship structure is deliberately
built as light (flimsy) as possible to save weight — in-flight breakup risk is real and must be
respected. Design criteria: FAA Document P-8110-2; type certification: FAA Document AC 21.17-1A.

### What We've Learned
*[Raymer, p. 832]*

The aircraft design process extends to spacecraft, launch vehicles, hypersonic aircraft, and
airships — the overall process is similar, but the specific layout and analysis methods must be
revised for each regime.

---

*Chapter 22 complete (§§22.1-22.4.4, Tables 22.1-22.3, Figs 22.1-22.6, Eqs 22.1-22.18). No numbered
in-chapter reference list (footnote citations refer to the book's consolidated bibliography, not
reproduced here). Table 22.2 was re-read cell-by-cell off a 300-dpi render of book p. 813 on
2026-08-18 and corrected; see the note under that table for what was wrong and for the two book
misprints (Jupiter mean diameter, and the whole Pluto row) that are kept as printed.*
