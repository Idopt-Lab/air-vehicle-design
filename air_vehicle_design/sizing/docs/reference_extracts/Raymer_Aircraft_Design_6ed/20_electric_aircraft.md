# Chapter 20 — Electric Aircraft

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 20
"Electric Aircraft," printed pp. 735-762.

Mostly design guidance, history, and technology survey (motors, batteries, fuel cells, hybrid
architectures, solar and beamed power), with one data table (battery specific energy/density) and
a closed-form sizing method at the end (Eqs. 20.1-20.11). Chapter-internal footnote citations
(e.g. `[173]`, `[55]`) refer to the book's global reference list, not reproduced here.

---

## §20.1 Introduction
*[Raymer, p. 735]*

Electric aircraft have flown since the 1970s (Brditschka HB-3 motor glider, 1973; "Solar Riser,"
1979; McCready's "Solar Challenger," first solar-electric crossing of the English Channel; "Solar
Impulse 2," first solar-electric round-the-world flight, 23 flight-days spread over 16 months). The
NASA Green Flight Challenge (2011) required 200 mi in under 2 hr on the electrical equivalent of
one gallon of fuel per occupant; both winners were electric (best: 404 mpg-equivalent per
passenger). Historically electric aircraft were slow gliders sized for minimal power; that is
changing (e.g. Chip Yates' modified Rutan Long-EZ, "Long-ESA," 258 hp/193 kW motor, 191 kts, world's
fastest electric aircraft as of 2012, but only ~15 min endurance at max power). Current
production/near-production electric aircraft: Airbus E-Fan (two-seat, ducted fan, Li-ion, 1 hr
endurance); Siemens 350-hp/110-lb motor in a modified Extra EA-300; Pipistrel Alpha Electro
(two-seat trainer, 80 hp/60 kW, ~1 hr endurance, production aircraft). Electric helicopters and
quadcopters are advancing rapidly (quadcopters need no control system beyond differential motor
power). First operational military electric aircraft: AeroVironment FQM-151 "Pointer" UAV (1986).
**Battery technology, not motor technology, is the limiting factor** on electric aircraft
performance/range.

## §20.2 Review of Physics and Units
*[Raymer, p. 738]*

Work = force x distance (ft-lb or joules); power = work/time (ft-lb/s or watts, 1 hp = 550 ft-lb/s
= 745.7 W). Electrical power = current (A) x voltage. Energy = power x time, conventionally in
watt-hours (1 Wh = 3600 J). Batteries/power supplies are compared by **specific energy** (Wh/kg)
and **energy density** (Wh/L). This chapter, following universal industry practice, uses **metric
units only** for electric-propulsion quantities even though the rest of the book leads with English
units.

## §20.3 Why Spark? (Advantages and Disadvantages)
*[Raymer, p. 739]*

**Advantages:** no emissions from the airframe; motor + controller efficiency >90% vs ~20% for
gasoline engines; up to 10x the time-between-overhaul; immune to carburetor icing and fuel-tank
icing; simple starting; safer (no fuel fire risk, though battery fires occur); can be overpowered
briefly (up to 3x rated power, 25% boost typical) for takeoff/emergency; power does not fall off
with altitude (unlike fuel cells); flat torque-vs-rpm curve simplifies flight control; motors are
small and relocatable (distributed propulsion, remote fans, multi-motor differential-thrust yaw
control as used by quadcopters); motors are lighter than equivalent IC engines and improving
(weight per unit power halved in the last decade); may permit a lighter propeller (no flywheel
duty) and smaller/more streamlined cowling.

**Disadvantages:** total system weight (motor + power supply) is heavier than an equivalent-power,
equivalent-runtime IC engine; slower "refueling" (recharge time); currently higher system cost
(offset somewhat by lower per-flight-hour "fuel" cost); often needs a reduction drive (added
weight/cost/noise); **no Breguet-equation range benefit from weight loss during cruise** — the
aircraft does not get lighter as "fuel" (battery charge) is consumed, so drag stays constant through
the mission (may cost 10-20% range vs. an equivalent fuel-burning design); battery-specific issues:
temperature sensitivity, resistive losses at high discharge rate, fire/explosion risk, power fade
near end of charge, finite cycle life and calendar life (possible full battery replacement every
5-8 years); stray electromagnetic interference from motors; net "greenness" depends on the
electricity generation source and on battery-material environmental cost (lithium extraction,
toxic/carcinogenic cobalt in NMC cells). **Bottom line: today's electric propulsion cannot yet match
gasoline engines for a normal aircraft on a normal mission**, but is well suited to small UAVs,
trainers, and short-endurance/novelty missions, and the technology is improving quickly.

## §20.4 Electric Motor Basics
*[Raymer, p. 742]*

A motor pulls a rotating magnetic **rotor** around a stationary magnetic **stator** (Fig. 20.1) by
alternating polarity so opposite poles keep attracting through the rotation. Internally, all motors
run on alternating current: something has to keep reversing the pull. In **DC motors**, a
**commutator** (historically mechanical brushes, now electronic in "brushless" motors) switches
current direction based on rotor angle; brushless motors avoid the spark risk and reliability
penalty of brushes. In **AC motors**, the current itself already alternates, so rotor rpm is tied to
the AC cycle rate (or a submultiple). A simple two-phase motor sticks at the point where rotor and
stator poles align (zero moment arm); the **three-phase motor** (invented 1890) fixes this using
three superimposed sinusoidal phases so a pulling moment is always available. Design implications
for aircraft: permanent-magnet motors are more efficient than electromagnet ("coil") motors; AC
motors need an inverter since batteries/solar cells are DC; brushed motors are less efficient and
spark-prone (a concern near hydrogen fuel cells); **brushless DC permanent-magnet motors (BLDC-PM)**
are generally the best aircraft choice (efficiency, weight, no sparking, good torque) and are used
on the Pipistrel Taurus G4 (Green Flight Challenge winner), electric helicopters, and the Segway.
Every electric motor needs a **controller** (on-off switch up to a full computer-driven inverter);
DC supplies need a DC-AC inverter in the controller. Sophisticated controllers also allow reversal
and regeneration (motor acts as a generator while descending, recharging the battery — "putting
gasoline back in the tank going downhill"). Controllers add 15-35% to motor weight and lose ~2% of
electrical power as heat; an ongoing NASA program targets inverter/controller performance of
12 kW/kg at 99% efficiency.

### Fig 20.1 — Electric motor schematic
*[Raymer, Fig. 20.1, p. 742]* — Simple schematic of a stator/rotor pair with `+`/`-` polarity
callouts illustrating the magnetic-pull concept described above. No plotted data (concept diagram).

## §20.5 Power Supply: Batteries
*[Raymer, p. 745]*

All non-gasoline power supplies (batteries, fuel cells, solar cells, beamed energy, flywheels,
generator-coupled engines) have much lower effective energy density than a tank of gasoline; "a
fivefold breakthrough in stored energy density would change the world." A **cell** produces
electricity via a chemical reaction between two dissimilar-metal electrodes separated by an
electrolyte (liquid or paste); a "battery" is one or more cells, terms used interchangeably in
practice. History: Franklin's Leyden-jar experiments (~1750, also the origin of the term "battery"
and of the terms positive/negative charge); Volta's "Voltaic Pile" (1800), the first
steady-current, non-instantaneous battery. Modern rechargeable ("secondary") battery chemistries in
increasing order of relevance to aircraft: NiCd (obsolete, toxic cadmium); NiMH (better energy
density, replaced NiCd); **Li-ion** (a catch-all family using lithium plus cobalt/manganese/nickel,
currently the only really practical chemistry for aircraft/EVs — good energy density, long charge
retention, but fire risk if shorted or fast-charged); **LiPO** (Li-ion in a solid polymer
electrolyte — lighter, moldable, best readily-available specific energy at ~11 lb/kWh ≈ 5 kg/kWh,
widely used in model aircraft); **NMC** (Li-ion + Ni/Mn/Co, widely used in EVs, used on Solar
Impulse 2, though prone to overheating — grounded that aircraft after its Japan-Hawaii leg);
**Li-S** (lithium-sulfur, higher energy density than typical Li-ion, used on Boeing's "Solar Eagle"
UAV); silver-zinc (high energy density, used in torpedoes/launch vehicles, expensive, poor cycle
life); zinc-air and aluminum-air (non-rechargeable "primary" batteries but very high theoretical
specific energy — up to 8000 Wh/kg for Al-air theoretically, ~1300 Wh/kg practical — refurbished by
physically replacing the spent electrode, so they behave somewhat like fuel cells). Startup
Eviation's "Alice" combines Li-ion (high power) with Al-air (cruise/endurance) targeting 400 Wh/kg;
its initial production version uses conventional 220 Wh/kg Li-ion for a targeted 540 nm range.
Note the general caution given: even the best batteries are only about **1/20th the effective energy
density of gasoline** once electric-motor efficiency gains are included.

### Table 20.1 — Battery Specific Energy and Density, Typical Values
*[Raymer, Table 20.1, p. 748]* — as of 2018; author cautions these are on the high side of reported
technology and should be confirmed against current sources.

| Chemistry | Name | Specific Energy (Wh/kg) | Energy Density (Wh/L) | Notes |
|---|---|---|---|---|
| Lead-acid | Lead acid | 45 | 100 | old, automotive |
| Alkaline | Alkaline | 100 | 300 | flashlights |
| NiFe | Nickel Iron | 25 | 30 | locomotives, mining |
| NiCd | Nickel Cadmium | 60 | 150 | classic "NiCad" |
| NiH | Nickel Hydrogen | 75 | 60 | space probes |
| NiMH | Nickel Metal Hydride | 90 | 300 | replaced NiCad |
| NiZn | Nickel Zinc | 100 | 280 | automobile, electronics |
| Li-ion | Lithium ion | 100-265 | 250-700 | generic term |
| Li-ion Polymer | Lithium Polymer | 100-265 | 250-730 | polymer electrolyte |
| LiCoO2 | Lithium Cobalt Oxide | 200 | - | handheld electronics |
| LiFePO4 | Lithium Iron Phosphate | 120 | 170 | tools, vehicles |
| LiMn2O4 | Lithium Manganese Oxide | 150 | - | laptops, medical equip. |
| LiNiMnCoO2 (NMC) | Lithium Nickel Manganese Cobalt Oxide | 260 | 500 | aircraft, road vehicles |
| Li-S | Lithium Sulfur | 400 | 250 | aircraft, road vehicles (US, upcoming) |
| Licerion (US) | proprietary Li-S trade name (Sion Power, ~2020) | 500 | 1000 | aircraft, road vehicles |
| Li-titanate | Lithium Titanate | 90 | 170 | high power/low energy |
| Li-air | Lithium-Air | 600 | 200 | experimental |
| Na-ion | Sodium Ion | 150 | 50 | laptops, bikes |
| Molten salt | Molten salt | 220 | 290 | misc |
| Silver Zinc | Silver Zinc | 200 | 700 | laptops, hearing aids |
| Wood (comparison) | Wood | 4500 | 3600 | "it floats" |
| Coal (comparison) | Coal | 8000 | 10000 | "it smells" |
| Jet Fuel (comparison) | Jet Fuel | 11000 | 10000 | "love that smell" |
| Gasoline (comparison) | Gasoline | 12000 | 9000 | "too expensive" |
| LH2 (comparison) | Liquid Hydrogen | 39406 | 2790 | "too cold" |
| Uranium (comparison) | Uranium | 2.2e10 | 4.3e11 | "too scary" |
| Antimatter (comparison, c²) | Antimatter | 9.0e10 | - | "beam me up" |

These approximate values should not be used alone to select a battery type — recharge-cycle life,
recharge rate (often 2-3x slower than discharge), temperature sensitivity, fire hazard, cost, and
end-of-life disposal all matter. Battery safety requires a sophisticated **battery management system
(BMS)** monitoring temperature in flight and while charging (charge only in roughly 5-35 degC),
quality-controlled cells from credible vendors, and physical/electrical design that prevents
terminal shorting.

## §20.6 Power Supply: Fuel Cells
*[Raymer, p. 749]*

Fuel cells react a fuel (usually hydrogen) with an oxidizer (usually atmospheric oxygen) to produce
electricity plus water exhaust, and can be "recharged" quickly by replacing fuel rather than waiting
out a multi-hour battery recharge. Hydrogen fuel cells exceed the energy density of the best
batteries and are roughly twice as efficient as an internal combustion engine; proven on the Space
Shuttle and in several manned/unmanned aircraft. Drawbacks: hydrogen is bulky unless stored at
extreme pressure (heavy tanks), is not available at most airports, produces significant waste heat
(cooling-air intakes comparable to an equivalent piston engine), and is explosive/flammable (though
it rises rather than pooling like liquid fuel spills). Types: hydrogen PEM (proton exchange
membrane), SOFC (solid oxide), and the older alkaline fuel cell.

### Fig 20.2 — Fuel-cell electric airplane powerplant
*[Raymer, Fig. 20.2, p. 750]* — Photo of a fuel-cell powerplant installation seen at EAA
AirVenture: fuel cells mounted low to the right, hydrogen tank aft of the cabin, surge battery banks
in the wing leading edge, and a motor controller roughly the size of the motor itself (left, attached
to the propeller). No plotted data (reference photo).

## §20.7 Power Supply: Hybrid-Electric
*[Raymer, p. 750]*

Hybrid-electric propulsion dates to 1930s diesel-electric trains and submarines. Automotive hybrids
benefit because the fueled engine can be sized only for continuous cruise power, with battery power
covering surge demand and the fueled engine able to shut off entirely at low load. Four aircraft
hybrid architectures:

- **Series hybrid** ("extended-range electric vehicle," EREV) — propeller/fan driven solely by the
  electric motor; a fueled engine + generator (and optionally batteries) supply the electricity.
  Allows the propeller/fan to be located away from the fueled engine and permits electric-only
  takeoff/flight if batteries are large enough, at a 10-15% conversion-efficiency penalty
  (shaft-to-electric-to-shaft) and added weight/volume.
- **"Booster" hybrid** (a parallel-hybrid variant) — propeller directly driven by the fueled engine
  as normal, with an electric motor/generator geared or wrapped around the output shaft, storing
  energy at low power demand and adding horsepower for takeoff/climb. Allows a smaller, lighter,
  better cruise-matched fueled engine, but cannot fly electric-only.
- **Parallel hybrid** — fueled engine and electric motor can each drive the propeller separately or
  together (used in several hybrid cars); an aircraft version needs a clutch to disconnect the
  propeller from the fueled engine during electric-only flight.
- **"Through-the-road" analog** ("through-the-air" hybrid) — a fueled engine with its own propeller
  plus a fully separate electric motor with its own propeller (e.g. wingtip-mounted pushers exploiting
  wingtip-vortex energy, at some cost in vibration/noise/efficiency from cutting through the wing
  wake); flexible but risks stopped-prop drag penalties.

Active hybrid-electric commercial projects (as of writing): Boeing-backed Zunum Aero's 12-seat
hybrid-electric regional aircraft (~670 hp/500 kW buried turboshaft for range extension plus
ground-charged, quickly-replaceable wing batteries for takeoff/short missions; ~12,500 lb/5670 kg,
>600 nmi/1126 km range, 300 kt/550 kph cruise, projected 8 cents/seat-mile vs ~25 for current
commuters); Airbus/Rolls-Royce/Siemens flight-testing a modified BAe 146 with one of four turbofans
replaced by a 2700 hp/2000 kW electric-motor-driven ducted fan; the EU HYPSTAIR project's
Siemens 270 hp/200 kW hybrid system (Rotax 914-based, >95% efficient generator at ~7 kW/kg) tested in
a modified Pipistrel Panthera.

## §20.8 Power Supply: Solar Cells
*[Raymer, p. 753]*

Solar (photovoltaic) cells, discovered 1839, first working cell 1883, modern crystalline-silicon
cells since 1954; now around $1/W plus similar integration/control cost. First solar-only flight:
"Sunrise I" model aircraft, 1974 (DARPA-funded, ~20 mi). Solar Impulse 2 (span 236 ft/71.9 m) flew
around the world using solar cells by day and lithium-polymer batteries charged from excess daytime
solar power for night flight (23 days/nights of flight time over many months). Ideal solar-cell
power output is ~0.1 kW/ft² (1.1 kW/m²); current practical efficiency gives only ~0.02 kW/ft²
(0.21 kW/m²) — about 40 ft² (~5 m²) of cells per equivalent horsepower (1 kW). Typical areal weight
~0.06 psf (0.3 kg/m²). Cell efficiency degrades over 1%/year in service. Installation (mounting,
wiring) roughly doubles the bare-cell weight, and cells not conformed to the ideal airfoil contour
disturb the airflow (hurting laminar flow); flexible printed cells are in development to address
both issues. Power output follows a sinusoidal daily cycle peaking at solar noon, zero at night, and
depends on latitude, season, and atmospheric moisture. **Pointing matters**: available power scales
with the projected cell area normal to the sun, so wing-top-mounted cells are a poor location near
dawn/dusk or at high latitude; some designs use non-lifting sun-tracking panels or sawtooth-buckling
wings. Altitude helps (~30% more available power above the atmosphere than at sea level, due to less
attenuating air/moisture/clouds). Reference [60] (Noth, Siegwart, and Engel lecture notes) is cited
for detailed solar-aircraft sizing methodology (irradiance estimation, statistical design
parameters).

### Fig 20.3 — Solar Impulse
*[Raymer, Fig. 20.3, p. 753]* — Photograph of the Solar Impulse solar-electric aircraft (single-seat
predecessor, Solar Impulse 1, pictured) in flight, illustrating the very large wingspan characteristic
of solar-powered aircraft. No plotted data (reference photo).

## §20.9 Power Supply: Beamed Power
*[Raymer, p. 754]*

Nikola Tesla first proposed powering aircraft by beaming energy from the ground. Potentially ideal
for a perpetual-endurance unmanned aircraft loitering over a city (cell relay, TV transmission,
surveillance). Power can be beamed as visible light (collected by solar cells) or, more efficiently,
as microwaves. Raytheon demonstrated ground-to-hovering-helicopter microwave power beaming in 1964;
a 1987 Communications Research Centre of Canada project flew a 15-ft (4.5-m) unmanned aircraft for
over an hour on beamed microwave power after a battery-powered takeoff. Concerns: automatic shutoff
needed if birds/aircraft cross the beam; reception is limited to line-of-sight of the ground
transmitter. Beamed power is judged more practical than solar alone for missions where the payload
(e.g. communications relay equipment) also needs continuous power, especially at night, since solar
cells can barely power flight alone.

## §20.10 Electric Aircraft Run-Time, Range, Loiter, and Climb
*[Raymer, p. 754]*

Analysis starts from battery specific energy (Wh/kg, Table 20.1) times battery mass, giving total
energy in watt-hours; losses occur in the controller, motor, and (if used) gearbox.

**Run-time endurance:**

**Eq (20.1)** *[Raymer, Eq. (20.1), p. 755]*:
```
E = (m_b * Esb * eta_b2s) / (1000 * P_used)
```
where `m_b` = battery mass {kg}, `Esb` = battery specific energy {Wh/kg}, `eta_b2s` = total system
efficiency from battery to motor output shaft, `P_used` = average power used {kW}. This is generic
(depends only on current power setting, not flight condition or weight). Typical component
efficiencies: motor controller ~98% (2% loss), motor ~95% (5% loss) → total battery-to-shaft
efficiency ~93%; a gearbox (if used) costs another ~2%, giving ~90% total (propeller losses not yet
included). Typical Li-ion cell voltage 3.6 V; complete battery-pack voltages run from 20-40 V (small
UAVs) to 133 V (Yuneec e430) to 300-600 V (modern designs, similar to electric cars).

For a propeller aircraft in level flight, setting thrust = drag (per Eq. 3.9):

**Eq (20.2)** *[Raymer, Eq. (20.2), p. 755]*:
```
P_used * eta_p = T*V = D*V = (W/(L/D)) * V
```
The propeller efficiency `eta_p` acts as a knockdown factor on power (a 25% power increase for a
typical 80%-efficient propeller). Combining with Eq. (20.1):

**Eq (20.3)** — Level Flight Endurance / Loiter time (hr) *[Raymer, Eq. (20.3), p. 755]*:
```
E = 3.6 * (m_b/m) * Esb * eta_b2s * eta_p * (L/D) / V
```
where `V` = velocity {km/h}. This parallels Eq. 17.31 (fuel-burning endurance): the `L/D`, `V`, and
`eta_p` terms match, but the weight ratio here is battery-to-total mass rather than initial-to-final
mass, and there is no logarithmic term because total aircraft weight `W0` does not change during an
electric flight. The same loiter-speed optimization from Chapter 17 applies (endurance is maximized
below best-L/D speed, per Eq. 17.33).

**Eq (20.4)** — Level Flight Range (km) *[Raymer, Eq. (20.4), p. 756]*:
```
R = 3.6 * (m_b/m) * Esb * eta_b2s * eta_p * (L/D)
```
(range = endurance x velocity; the explicit `V` cancels but remains implicit inside `L/D`, which is
itself a function of velocity). Parallels Eq. 17.28; range is maximized at best-`L/D` speed
(Eq. 17.13), same as the fuel-burning case.

For climb (winged aircraft, not vertical climb), equating Eqs. 5.1 and 5.3 and solving for vertical
velocity:

**Eq (20.5)** — Rate of Climb (m/s) *[Raymer, Eq. (20.5), p. 756]*:
```
Vv = (1000 * eta_p * P_used/m) - (V / (3.6 * (L/D)))
```
where `V` = velocity {km/h}, `P_used/m` = power-to-mass ratio {W/g or kW/kg}.

## §20.11 Electric Aircraft Initial Sizing
*[Raymer, p. 756]*

Fuel-burning aircraft sizing (Chapter 3/6) uses Breguet-derived mission-segment weight fractions
(`Wi/Wi-1`), since the aircraft gets lighter as fuel burns. **This does not apply to battery-electric
aircraft** — there is no weight change to integrate. Instead, define the **Battery Mass Fraction
(EMF)** — the ratio of battery mass to total aircraft mass required for a mission segment — playing
a role loosely analogous to `(1 - Wi/Wi-1)`, but methods for fuel-burning aircraft must not be
reused directly since their derivations assume a shrinking aircraft weight. EMF is described as
having a "talking resemblance" to the Propellant Mass Fraction used in rocket analysis (Chapter 22):
high EMF is required for good range/performance, achievable only with low empty weight.

**Eq (20.6)** — Battery Mass Fraction, Known Run-Time *[Raymer, Eq. (20.6), p. 756]*:
```
EMF = m_b/m = W_b/W0 = (1000 * E * P_used) / (Esb * eta_b2s * m)
```
where `E` = known run-time {hr}. Propeller efficiency does not enter — the calculation is agnostic
to what the motor drives (a butter churn would need the same battery mass fraction for the same
time and power). This equation plays the role of the "known-time fuel burn" segment weight fraction
of Chapter 6 (Eq. 6.16) and applies equally to takeoff, descent, turns, and (with an assumed power
setting/time) VTOL segments.

**Eq (20.7)** — Battery Mass Fraction, Loiter (Level Flight) *[Raymer, Eq. (20.7), p. 757]*:
```
EMF = m_b/m = W_b/W0 = (E*V) / (3.6 * Esb * eta_b2s * eta_p * (L/D))
```

**Eq (20.8)** — Battery Mass Fraction, Cruise (Level Flight) *[Raymer, Eq. (20.8), p. 757]*:
```
EMF = m_b/m = W_b/W0 = R / (3.6 * Esb * eta_b2s * eta_p * (L/D))
```
where `V` = velocity {km/h}, `E` = loiter time {hr}, `R` = range {km}.

For a climb segment, divide the required climb altitude `h` by the rate-of-climb result to get
segment time, then substitute into the known-run-time equation:

**Eq (20.9)** *[Raymer, Eq. (20.9), p. 757]*:
```
EMF = m_b/m = W_b/W0 = (h * P_used) / (3.6 * Vv * Esb * eta_b2s * m)
```
`P_used` should be the climb power (probably maximum continuous power for the chosen motor); `L/D`
should be the climb value, about 0.866 times max `L/D` at the climb-optimal speed (~76% of
best-L/D speed, roughly 60-80 kt for most GA aircraft). Note `eta_p` is not needed here (it was
already used inside the rate-of-climb calculation). For vertical climb (electric VTOL/helicopter),
use the Chapter 21 vertical-climb equations to get `Vv`, or (a less-preferred approach per the
author) convert the potential-energy gain directly to battery energy with an empirical fudge factor
— purely vertical climb is inefficient, so its use should be minimized anyway.

Total required EMF is the **sum** (not product) of the mission-segment EMF values. Available EMF
(mass fraction available for batteries) is:

**Eq (20.10)** *[Raymer, Eq. (20.10), p. 757]*:
```
EMF_available = (m0 - me - m_payload) / m0 = (W0 - We - W_payload) / W0
```

Equating available and required EMF and solving for `W0`:

**Eq (20.11)** — Electric Aircraft Sizing Equation *[Raymer, Eq. (20.11), p. 758]*:
```
W0 = W_payload / (1 - EMF - We/W0)
```
(For a manned aircraft, `W_payload` includes `W_crew`.) This closely parallels the preliminary
sizing equation of Chapter 3 (Eq. 3.4), with EMF playing the role of fuel fraction. `We/W0` is best
estimated from the statistical logarithmic empty-weight relationship of Chapter 3 (originally fit to
fuel-burning aircraft — the author recommends adjusting constants using recent electric-aircraft
data), solved iteratively: guess `W0`, compute `We/W0`, recompute `W0` from EMF, repeat to
convergence. `We` here includes propulsion, structure, avionics, and everything else that is not
payload or usable battery mass — batteries take the conceptual place of fuel. As an alternative,
propulsion/avionics weight can instead be treated as fixed "payload," removed from the `We`
statistical estimate, or split between the two treatments.

For small/simple electric aircraft, this full sizing process is sometimes skipped: pick an
"about right" motor for the aircraft class, size the airframe from a performance-driven `P/W`
(Eq. 6.24), and iterate motor size/gross weight upward if the resulting mission range falls short.

### What We've Learned
*[Raymer, p. 761]*

Electric aircraft still cannot compete with hydrocarbon-powered aircraft for most missions, but the
technology is improving rapidly. This chapter covered motor types, power-supply options (batteries,
fuel cells, hybrid-electric, solar, beamed power), and range/endurance/climb/initial-sizing analysis
methods specific to battery-electric aircraft.

---

*Chapter 20 complete (§§20.1-20.11, Table 20.1, Figs 20.1-20.3, Eqs 20.1-20.11). No numbered
in-chapter reference list (footnote citations refer to the book's consolidated bibliography, not
reproduced here). No OCR-garbled equation coefficients encountered.*
