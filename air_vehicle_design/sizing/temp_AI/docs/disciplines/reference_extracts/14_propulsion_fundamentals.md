# Chapter 14 — Propulsion System Fundamentals

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 14 "Propulsion System Fundamentals," printed pp. 355–383 (PDF pp. 365–394).

Text-layer inventory (to confirm completeness): Figs 14.1–14.11 (incl. 14.4a/14.4b, 14.7a/14.7b/14.7c,
14.8a/14.8b/14.8c, 14.9a/14.9b/14.9c), Tables 14.1–14.4, Eqs (14.1)–(14.13) (incl. 14.4a/14.4b).

Sections covered per chapter opener: Propeller Systems (Reciprocal & Turbine); Turbine Engine
Fundamentals; Electric Aircraft System; Solar Aircraft System; Ramjet; Rocket Engines; Sir Frank
Whittle & Hans von Ohain.

---

## Chapter 14 — Propulsion System Fundamentals
*[Nicolai & Carichner, p. 355]*

> **Chapter-opening photo (p. 355).** Sir Frank Whittle (left) and Dr. Hans von Ohain (right) changed
> the propulsion world of aviation by inventing the jet turbine engine independently of each other.
> Their story is told at the end of this chapter.

> **Pull-quote (p. 355):** "For any isolated system not in equilibrium the entropy will increase until
> that system attains equilibrium." — Second law of thermodynamics

## §14.1 Introduction
*[Nicolai & Carichner, p. 356]*

The primary purpose of all aircraft propulsion devices is to impart a change in momentum to a mass of
fluid. The fluid may be air, air and combustion products, or combustion products only. In the case of
a watercraft the fluid would be water. Newton's second law states that the force or thrust produced on
a system is equal to the change in momentum of the system in unit time. This fundamental principle is
shown in Fig. 14.1 for a stream tube of air [1]. The entrance conditions are denoted by the freestream
symbol $a$ and the exit conditions denoted by $e$. The mass flow rate of air through the stream tube is
$\rho AV$ and has units of slugs per second (slug/s). The stream tube boundaries are the fluid
streamlines. The force or *net thrust* acting on the stream tube system is given by

**Eq (14.1)** *[Nicolai & Carichner, Eq. (14.1), p. 356]*:
```
T_n = (m_dot_air + m_dot_fuel)*V_e - m_dot_air*V_a + P_e*A_e - P_a*A_a
```

Notice that there may be a difference in the pressure and area at the entrance and exit such that a
small pressure force would act on the system. Because the mass flow rate of the fuel added to the
system is very small compared with the mass flow rate of the air, Eq. (14.1) is usually written

**Eq (14.2)** *[Nicolai & Carichner, Eq. (14.2), p. 356]*:
```
T_n = m_dot_air*(V_e - V_a) + P_e*A_e - P_a*A_a
```

The principal types of propulsion devices accelerating the flow inside the stream tube are listed
next and are shown qualitatively in Figs. 4.6 and 4.7:

> **Sidebar (p. 356).** The second law of thermodynamics traces its origin to the French physicist
> Sadi Carnot (1796–1832). In 1824, he published "Reflections on the Motive Power of Fire," which
> presented the view that motive power (work) is due to the fall of fire (caloric heat) from a hot to
> a cold body (working substance). Simply stated it is an expression of the universal law of
> increasing entropy.

**Fig. 14.1** — *Momentum change on a fluid system* *[Nicolai & Carichner, Fig. 14.1, p. 356]*.
Stream-tube schematic: entrance station $a$ with $V_a$, $P_a$, $\rho_a$, $A_a$, $\dot m_{air}=\rho_a
A_a V_a$; fuel $\dot m_{fuel}$ injected into the tube; exit station $e$ with $P_e$, $\rho_e$, $A_e$,
$V_e$, exit mass flow $\dot m_{air}+\dot m_{fuel}$.

- **Propellers.** Propellers are driven by reciprocating piston engines, gas turbines (turboprops),
  or electric motors. A propeller operates by producing a relatively small change in velocity of a
  relatively large mass of air. Propellers are limited to tip speeds less than sonic due to the
  formation of shocks and thus have a practical speed limit less than 500 kt (Mach = 0.75).
- **Gas turbines.** In the forms of simple jets (turbojets), afterburning turbojets, and turbofans,
  gas turbines accelerate a small mass of air to a large velocity change and can operate
  supersonically to about Mach 3.5.
- **Ramjets** (both subsonic and supersonic combustion)
- **Pulsejets**
- **Rockets.** Rockets carry their own oxidizer ($m_{air}=0$) and thus accelerate the very small
  (relative to turbines) combusted propellant products to very high velocities. The thrust equation
  for rockets becomes

**Eq (14.3)** *[Nicolai & Carichner, Eq. (14.3), p. 357]*:
```
T = m_dot_cp*V_e + A_e*(P_e - P_a)
```
where $\dot m_{cp}$ is the mass flow per unit time of combusted propellant products.

## §14.2 Operation of Propeller Systems
*[Nicolai & Carichner, p. 357]*

The analysis and design of propellers is discussed in Chapter 17. This subsection will discuss the
engines that drive the propeller. The engine provides a *thrust power available* equal to $TV$, which
may be taken as the propeller output. The power input to the propeller from the engine shaft is the
*engine brake horsepower*; thus, the *propeller efficiency* is

*(unnumbered equation)* *[Nicolai & Carichner, p. 357]*:
```
eta_p = (propeller thrust power) / (engine shaft brake horsepower)
```

In flight, the propeller accelerates a large mass of air rearward to a velocity only slightly greater
than the flight speed, exhibiting efficiencies at normal flight speeds of between 85% and 90%. The
lost horsepower appears mainly as unrecoverable kinetic energy of air in the slip stream.

The *horsepower required* for an aircraft to fly at a speed $V$ is

**Eq (14.4a)** *[Nicolai & Carichner, Eq. (14.4a), p. 357]*:
```
hp_Req = D*V / (550*eta_p)
```
where the 1/550 converts foot-pounds per second (ft·lb/s) to horsepower.

Using the equation for one-$g$ drag $D=W/(L/D)$ gives the useful equation

**Eq (14.4b)** *[Nicolai & Carichner, Eq. (14.4b), p. 357]*:
```
hp_Req = W*V / ((L/D)*550*eta_p)
```

### §14.2.1 Reciprocating Piston Engines
*[Nicolai & Carichner, p. 358]*

The aircraft *reciprocating piston engine* uses the well-known four-cycle Otto cycle [2]. An aircraft
piston engine is similar to an automobile engine with a few differences. First, engine weight [given
in horsepower per pound (hp/lb)] is a major performance parameter. Most aircraft engines are air
cooled for this very reason. Second, reliability is very important because a malfunction at any
altitude is a serious situation. The current piston engines are well developed to give high
performance (hp/lb), low *brake specific fuel consumption* (BSFC) in pounds of fuel per hour per brake
horsepower [(lb of fuel/h)/bhp], and high reliability.

Current piston and turboprop engines are shown in Fig. 14.2. The hp/lb for the current piston engines
varies from about 0.6 for the small engines (less than 600 hp) to almost 1.0 for the larger engines.
The BSFC for all the piston engines in Fig. 14.2 at sea level static (SLS) conditions varies from
approximately 0.5 for the smaller engines (less than 400 bhp) to 0.42 for the larger engines. Most
engines have a major overhaul recommended at 2000 hours. The engines have two spark plugs on each
cylinder fired independently from engine-driven magnetos.

The power output from a piston engine depends primarily on two parameters: the engine rpm and the
absolute pressure in the intake manifold. Maximum power is typically at 2800 rpm and SLS conditions of
59°F and 14.7 psia (30 in. of Hg).

Table 14.1 presents the specifications for the Lycoming O-360-A aircraft engine. The O-360-A (shown
in Fig. 14.3) is in the Piper Cherokee 180 and represents a very typical general aviation piston
engine. Notice that it is designed to cruise at 65%–75% of maximum power, which is a range of
2200–2450 rpm. The maximum throttle performance degradation with altitude is linear from 700 ft
(180 hp at 2700 rpm and 28 in. of Hg) to 21,000 ft (76 hp at 2700 rpm). Cruise power is linear with
altitude also.

A useful expression (from [1]) for the power loss (reduction in brake horsepower, Bhp) with altitude
is

**Eq (14.5)** *[Nicolai & Carichner, Eq. (14.5), p. 358]*:
```
Bhp = Bhp_SL * [ (rho/rho_SL) - (1 - rho/rho_SL)/7.75 ]
```

Piston engines are sometimes supercharged to increase sea-level power for air racing or to increase
the operating altitude. *Supercharging* involves compressing the air entering the intake manifold by
means of a compressor. In earlier piston engines, this compressor was driven by a gear train from the
engine crankshaft. The more modern supercharged engines employ a turbine-driven compressor powered by
the engine's exhaust and

**Fig. 14.2** — *Weight vs shaft horsepower (SHP), for turboprop and piston aircraft engines*
*[Nicolai & Carichner, Fig. 14.2, p. 359]*. Log-log plot of Engine Weight (lb, $10^2$–$10^4$) vs.
Shaft Horsepower (SHP) Takeoff Rating ($10^2$–$10^4$), two parallel trend lines (upper: Reciprocating;
lower: Turboprop) with 28 numbered/lettered data points keyed to a legend of engine models: (1)
Honeywell T53-701, (2) Honeywell T55 (LTC4RI), (3) Allison T56-A-7, (4) Allison T56-A-15, (5) Allison
250-B17 (T63), (6) GE T64-GE-10, (7) Honeywell T76-G-10, (8) RR Dart R Da.7, (9) RR Tyne R Ty.12, (10)
Ivchenko AI-20M, (11) Continental O-200A, (12) Continental IO-360, (13) Continental Tiara 6-285A, (14)
Continental IO-540-AIA, (15) Lycoming TIO-540-AIA, (16) P&W R-985 Wasp Jr, (17) P&W R-1340 Wasp, (18)
P&W R-2000 Twin Wasp, (19) P&W R-2800 Double Wasp, (20) P&W R-4360 Wasp Major, (21) Wright R-1300-I,
(22) Wright R-1820 Cyclone, (23) Wright R-3350-30WA, (24) RR Merlin 724, (25) RR Griffon 57, (26)
Lycoming O-360, (27) Honeywell TPE 331-11, (28) TCM GTSIOL-550. Symbol key: circle = Turboprop, square
= Reciprocating dry, tilted square = Reciprocating water injection.

**Table 14.1** — *Lycoming O-360-A Aircraft Engine Specifications and Description (data from [2])*
*[Nicolai & Carichner, Table 14.1, p. 360]*:

Type: Four-Cylinder, Direct Drive, Horizontally Opposed, Wet-Sump, Air-Cooled Engine

| Parameter | Value |
|---|---|
| Weight, pounds | 282 |
| Bore, inches | 5.125 |
| Stroke, inches | 4.375 |
| Displacement, cubic inches | 361 |
| Compression ratio | 8.5:1 |
| Cylinder head temperature, max. °F | 500 |
| Cylinder base temperature, max. °F | 325 |
| Fuel: aviation grade, octane | 100–130 |

Performance, hp:

| Condition | Value |
|---|---|
| Takeoff rating at SLS, hp | 185 at 2900 |
| Max. rated at 700 ft (28 in. of Hg), hp | 180 at 2700 |
| Max. rated at 7000 ft, hp | 143 at 2700 |
| Max. rated at 21,000 ft, hp | 76 at 2700 |
| Cruise rpm at 7000 ft, hp | 135 at 2450 |
| Cruise rpm at 21,000 ft, hp | 74 at 2450 |
| Cruise rpm at 7000 ft, hp | 126 at 2200 |
| Cruise rpm at 21,000 ft, hp | 70 at 2200 |
| Cruise BSFC, lb/bhp·h | 0.47 |

are called *turbochargers*. The advantage of the turbocharger over the gear-driven supercharger is
twofold. First, the compressor does not extract power from the engine, but uses exhaust energy that
would normally be wasted. Second, the turbocharger is able to provide sea level rated power up to
much higher altitudes than the gear-driven type.

**Fig. 14.3** — *Lycoming O-360A aircraft engine* *[Nicolai & Carichner, Fig. 14.3, p. 360]*. Photo of
the four-cylinder horizontally-opposed air-cooled engine showing cylinder heads, cooling fins,
induction/exhaust plumbing, and the belt-driven cooling fan/alternator pulley assembly.

An example of a turbocharger designed for high-altitude operation is the one on the Boeing/DARPA
Condor. The Condor was designed to fly at 65,000 ft, where the freestream air pressure is 1/18 that of
sea level. The Condor used two Continental GTSIOL-300 piston engines (175 hp, six cylinders,
reduction gearing, spark ignition, fuel injected, liquid cooled) each weighing 289 lb. There were two
stages of turbocharging, each boosting the pressure 4.2:1 and cooling the air. Each turbocharger
weighed 560 lb. Each engine drove an 81-lb, three-bladed, 16-ft propeller geared down 3:1 from the
2700 rpm engine speed. The propeller efficiency was reported as 90%.

The HAARP aircraft (from Section 5.8) uses a three-stage turbocharger to boost the pressure of the air
going into its piston engines to 93:1 for operation at 100,000 ft. The HAARP turbocharger is designed
for 108:1, giving it a little margin to operate past 100,000 ft. The turbocharger was designed by
Teledyne Continental (TCM) and is shown schematically in Fig. J.1.

The practical limit for pressure boost across a turbocharger stage is about 5:1 for current
compressor design and materials. Thus, the Condor needed a two-stage and HAARP a three-stage
turbocharger. The temperature of the air is increased through each compressor stage and needs to be
cooled before going into the next stage. The cooling requirement for one HAARP engine and
turbocharger is as follows:
- Engine coolant, heat load 3380 Btu/min
- Engine oil, heat load 1450 Btu/min
- Turbocharger intercoolers, heat load 9900 Btu/min
- Generator and gearbox, heat load 600 Btu/min

The cooling system for these items comprises ram air-cooled heat exchangers located in the leading
edge of the wing that weigh 1147 lb total for the two sides. The ram drag for the cooling system is
estimated to be equal to 25% of the aircraft $C_{D_{min}}$. This greatly reduces the HAARP maximum
$L/D$ from 39 for a clean aircraft to the 27 reported in the example of Section 5.8.

Figure J.2 shows typical weights of the turbochargers, intercoolers, heat exchangers, and ducting as a
function of maximum horsepower and altitude.

The engine for HAARP will be sized and selected in Chapter 18 (Section 18.10).

### §14.2.2 Turboprop Engines
*[Nicolai & Carichner, p. 361]*

The thermodynamics of the turboprop engine will be discussed in detail in the next section. This
section discusses its characteristics as a propeller system.

The performance (hp/lb) of current turboprop engines is shown in Fig. 14.2. Turboprops are lighter
than an equivalent piston engine with hp/lb of approximately 2.2–2.4 for all engines. The shaft on a
turbine engine typically rotates at 10,000 rpm, a speed much too high for propeller operation. In most
cases, the weights shown in Fig. 14.2 for the turboprop includes the weight of the reduction gearing
required for a propeller speed of approximately 2000–2700 rpm. The BSFC is about 25% higher for
turboprops than for a piston engine.

In a turboprop engine most of the power is extracted as shaft power to drive the propeller. However,
there is a residual energy that is expanded through the nozzle as jet thrust $T_J$, which is not
included in the listed shaft horsepower (SHP).

To account for the power produced by this jet thrust an *equivalent shaft horsepower* (ESHP) has been
devised to account for the total power output of the engine. Using Eq. (14.4) the jet thrust is
converted to a *thrust horsepower* by

**Eq (14.6)** *[Nicolai & Carichner, Eq. (14.6), p. 362]*:
```
THP = T_J * V / (0.8 * 550)
```
where the 0.8 accounts for a conventionally assumed 80% propeller efficiency. With this expression the
ESHP may be written

**Eq (14.7)** *[Nicolai & Carichner, Eq. (14.7), p. 362]*:
```
ESHP = SHP + T_J*V / (0.8*550)
```

Notice that this relationship does not account for thrust horsepower under static conditions where
$V=0$. For such cases (and for $V<100$ kt) another convention has been adopted to equate a given
thrust level per horsepower. Some European turboprop companies use 2.6 lb of thrust per horsepower,
but the usual equivalence is 2.5 lb of thrust equals one horsepower. Thus, for $V<100$ kt,

**Eq (14.8)** *[Nicolai & Carichner, Eq. (14.8), p. 362]*:
```
ESHP = SHP + T_J / 2.5
```

For example, the Honeywell (formerly Garrett) TPE 331-11 is rated statically at 1000 SHP and 1045
ESHP. This engine therefore produces a static thrust from the turbine exhaust of approximately 113 lb.

### §14.2.3 Electric Motors
*[Nicolai & Carichner, p. 362]*

*Electric motors* are simple and reliable (design life of 30,000 h when operated at ~60% rated
power). They have a specific power of approx 0.27 hp/lb (0.2 kW/lb). Electric motors get their power
from onboard auxiliary power units (APU; either piston or turboshaft engines driving
electric generators), batteries, fuel cells, or solar cells (photovoltaic cells that convert incident
solar energy into electricity).

For missions having several day–night cycles the electric aircraft would need to be a solar-powered
vehicle. It would collect solar energy from the sun during the day and convert it to electricity
through the photovoltaic action of solar cells. It would need to store energy in batteries or fuel
cells to power the vehicle during the night. The solar cells would then recharge the batteries or
fuel cells for the next nighttime operation by collecting excess power during the day. Theoretically
this cycle could go on forever; however, the batteries and fuel cells have finite recharging limits
and their performance degrades over time [3]. Table 14.2 contains data on electric motors, solar
cells, batteries, and fuel cells.

**Table 14.2** — *Electric Aircraft System Data (2010)* *[Nicolai & Carichner, Table 14.2, p. 363]*:

| Characteristic | Electric Motor | Solar Cell | Fuel Cell | Batteries |
|---|---|---|---|---|
| Specific energy (kW·h/lb) | 0.2ᵃ | NA | 0.89ᵇ'ᶜ | 0.27ᶜ'ᵈ |
| Design life | 30,000 h | ᵉ | NA | 300ᶠ |
| Efficiency (%)ᵍ | 97 | 28 | 55 | 90 |
| Installed weight (lb/ft²) | NA | 0.1 | NA | NA |

ᵃWeight includes motor, controller, and propeller. Increase weight by 25% for installation.
ᵇH₂/O₂ regenerative fuel cell using proton exchange membrane technology.
ᶜSpecific power based on discharge time.
ᵈLi–S batteries are projected to increase to 0.336 kWh/lb by 2015.
ᵉSolar cells degrade about 1.5% of power output per year.
ᶠ300 full-depth discharges in 2010. Decreasing the discharge to 50% would increase number of recharges
to approximately 1000.
ᵍEfficiency is energy out per energy in. Solar cell efficiency is projected to increase to 32% and
fuel cell efficiency to 65% by 2015.

## §14.3 Operation of Turbine Systems
*[Nicolai & Carichner, p. 363]*

The *turbine engine* or *turbojet engine*, shown schematically in Fig. 14.4a, operates in a similar
fashion to the other aircraft propulsion devices. Air is brought in the inlet and slowed down to
approximately Mach = 0.4 at the face of the compressor. The air mass is compressed and pressure is
built up (increasing pressure energy of fluid) as the air goes through the compressors with little
change in velocity. The air is mixed with fuel in the combustor section, ignited, and burned,
increasing the thermal energy of the air–fuel fluid mixture. The heated fluid expands in the turbine
section, driving the turbines, which in turn powers the compressor section. The fluid is further
expanded through the nozzle section to a high velocity (conversion of pressure and thermal energy
into kinetic energy), thus increasing the momentum of the fluid and producing a thrust. Figure 14.4b
shows the internal pressure variations inside a typical turbojet engine.

The efficiency of the turbine engine as a propulsion device depends on many factors. One of the major
factors is the *compression ratio* of the air through the compressor [overall pressure ratio (OPR)],
which is a function of the number of compression stages and their stage efficiencies. The efficiency
of the compressor and turbine stages depends upon the blade geometry (number and shape), the ratio of
blade length to hub, and the ratio of blade length to tip clearance. The operating temperature of the
combustor and turbine determines the amount of thermal energy in the gas available for power
extraction and expansion to jet velocity.

**Fig. 14.4a** — *Schematic of typical turbojet with afterburner* *[Nicolai & Carichner, Fig. 14.4a,
p. 364]*. "Turbojet with Afterburner" cutaway schematic showing twin-spool compressor/turbine and
afterburner, with station numbering: $a$ Freestream conditions, 1 Entrance to inlet, 2 Entrance to
compressor, 3 Entrance to combustors, 4 Entrance to turbine section, 5 Entrance to afterburner, 6
Entrance to nozzle, $e$ Exit conditions.

The *net thrust* produced by a turbojet engine is given by [from Eq. (14.2) for $A_a=A_e$]

**Eq (14.9)** *[Nicolai & Carichner, Eq. (14.9), p. 365]*:
```
T_n = m_dot_air*(V_e - V_a) + (P_e - P_a)*A_a
```
where
- $\dot m$ = mass flow of air, in slugs per second
- $V$ = velocity of air, in feet per second
- $P$ = static pressure, in pounds per square foot

and the subscripts correspond to the station locations of Fig. 14.4a. Notice that the mass flow of the
fuel is not included in the $\dot m$ term of Eq. (14.9). This is because the fuel flow is small
compared to the air flow; also the weight of air leakage through the engine can be assumed to be
approximately equivalent to the weight of the fuel consumed.

The *gross thrust* is defined as the product of the mass flow rate in the jet exhaust and the velocity
attained by the jet after expanding to freestream static pressure

*(unnumbered equation)* *[Nicolai & Carichner, p. 365]*:
```
T_g = m_dot_air * V_e
```

And the term $\dot m_{air}V_a$ is called the *ram drag*. For static operation, $T_g$ and $T_n$ are
equal.

To enable an accurate comparison to be made between turbine engines, fuel consumption is reduced to a
common denominator, applicable to all types and sizes of turbine engines. The term used is *thrust
specific fuel consumption* (TSFC) and is expressed as

**Eq (14.10)** *[Nicolai & Carichner, Eq. (14.10), p. 365]*:
```
C = TSFC = W_f / T_n
```
where $W_f$ is the fuel weight flow in pounds per hour and $T_n$ is the net thrust in pounds.

Frequently, a turbojet engine is equipped with an afterburner for increased thrust. Roughly, about 25%
of the air entering the compressor and passing through the engine is used for combustion. Only this
amount of air is required to attain the maximum temperature that can be tolerated by the metal parts.
The balance of the air is needed primarily for cooling purposes. Essentially, an *afterburner* is
simply a huge stovepipe, attached to the rear of the engine, through which all of the exhaust gases
must pass.

**Fig. 14.4b** — *Typical turbojet engine, internal pressure variation* *[Nicolai & Carichner, Fig.
14.4b, p. 364]*. Internal Engine Total Pressure vs. engine station, aligned above a turbojet-with-
afterburner cutaway, showing pressure rising through the Compressor section, peaking through the
Burner Section, dropping sharply across the Turbine, then declining gradually through the Exhaust —
labeled start point $P_{amb}$ or $P_{t2}$ and end bracket "Engine Discharge Total Pressure / Pressure
for Generating Thrust".

Fuel is injected into the forward section of the afterburner and is ignited. Combustion is possible
because 75% of the air that originally entered the engine still remains unburned. The result is, in
effect, a tremendous blowtorch, which increases the total thrust produced by the engine by
approximately 50%, or more. Although the total fuel consumption increases almost two-and-a-half
times, the net result is profitable for short bursts of aircraft speed, climb, or acceleration. A
turbojet aircraft with an afterburner can reach a given altitude with the use of less fuel by climbing
rapidly in "afterburning" than by climbing much more slowly in "nonafterburning." The weight and
noise of an afterburner, which is used only occasionally on long flights, precludes the device being
employed in present-day, transport-type aircraft. *[Nicolai & Carichner, p. 366]*

The turbine engines shown in Fig. 14.5 are termed *two spool*. The shaft from the first stage of the
turbine is hollow and drives the high-pressure stage of the compressor (called the *high spool*). The
power shaft from the aft stages of the turbine runs through the hollow high spool shaft and drives the
low-pressure stage of the compressor (called the *low spool*). *[Nicolai & Carichner, p. 366]*

### §14.3.1 Turboprop

The *turboprop* (sometimes called a *turboshaft*) is essentially a turbojet designed to drive a
propeller. The turboprop is shown schematically in Fig. 14.5 and uses the basic gas generator section
of a turbine engine. The propeller operates from the same shaft as the low-spool compressor through
reduction gearing. The hot gases are nearly fully expanded in the turbine first stage, which develops
considerably more shaft power than required to drive the low-spool compressor and accessories. The
excess power is used to drive a conventional propeller equipped with a speed-regulated pitch control.
The remainder of the hot gases are expanded through the nozzle, providing a jet thrust as discussed in
Section 14.2.2. This engine retains the advantage of having a light weight and low frontal area,
together with the ease of installation that goes with turbojet engine design. In addition, it has a
high efficiency at relatively low speeds. However, present propeller design limits the use of this type
of powerplant to speeds below 500 kt (see Fig. 14.5 in Section 14.3.2; text cross-reference reads "Fig.
4.5" but is evidently a typo for Fig. 14.5). *[Nicolai & Carichner, §14.3.1, p. 366]*

### §14.3.2 Turbofan

The *turbofan* version of an aircraft gas turbine engine is shown in Fig. 14.5 and is the same as the
turboprop, the geared propeller being replaced by a duct-enclosed fan driven at engine speed. One
fundamental operational difference between the turbofan and the turboprop is that the airflow through
the fan of the turbofan is unaffected by airspeed of the aircraft. This eliminates the loss in
operational efficiency at high airspeeds, which limited the air-speed capability of a turboprop engine.
Also the total airflow through the turbofan engine is much less than that through the propeller of a
turboprop. In the turbofan engine, 30% to 60% of the propulsive force is produced by the fan. *[Nicolai
& Carichner, §14.3.2, p. 366–367]*

The *bypass ratio* (BPR) for a turbofan is defined as the ratio of the airflow through the fan to the
airflow through the gas turbine core. Some modern turbofan engines have bypass ratios as high as
BPR = 10 (see Table J.1). *[Nicolai & Carichner, p. 367]*

**Fig. 14.5** — *Schematic of typical turbojet, turboprop, and turbofan engines showing basic gas
generator core* *[Nicolai & Carichner, Fig. 14.5, p. 367]*. Three stacked cutaway schematics (Turbojet /
Turboprop / Turbofan) sharing a common "Gas Generator" core section (compressor–burner–turbine,
bracketed between two vertical dashed reference lines); Turboprop adds a forward reduction-geared
propeller, Turbofan adds a forward duct-enclosed fan in place of the propeller.

The turbofan engine offers several advantages over a turbojet, such as better takeoff thrust for the
same-weight engine and lower TSFCs at high-subsonic speeds (see Fig. 14.6). This advantage comes about
because the turbofan can accelerate a higher airflow $\dot{m}_a$ to a lower jet velocity, giving a
higher propulsive efficiency (see [1]) than a turbojet of equivalent weight and fuel flow. Figure 14.6
shows the influence of bypass ratio on the sea level static TSFC for current turbine engine technology.
The turbofan's advantage decreases at high-subsonic and all supersonic speeds due to the higher drag
associated with the larger frontal area. *[Nicolai & Carichner, p. 368]*

**Fig. 14.6** — *Sea level static (SLS) specific fuel consumption for turbojet and turbofan engines*
*[Nicolai & Carichner, Fig. 14.6, p. 368]*. TSFC (lb/h/lb), y-axis 0–2.4, vs. Net Thrust (1000 lb),
x-axis 0–50. Five data/curve families, each with a fitted trend curve (read from plot):

| Family | Approx. Net Thrust range (1000 lb) | Approx. TSFC range (lb/h/lb) |
|---|---|---|
| Turbojets with Afterburner | 0–20 | 1.9–2.2 |
| Turbojets | 0–22 | 0.8–1.25 |
| Turbofans with Centrifugal Compressors | 0–10 | 0.35–0.7 |
| Turbofans, BPR ≈ 1:1 | 5–23 | 0.5–0.75 |
| Turbofans, BPR ≈ 5:1 | 40–50 | 0.35–0.4 |

Three labeled reference points cross-reference specific engines/figures elsewhere in the chapter:

| Marker | Engine | Figure |
|---|---|---|
| 1 | F-100 dry | 14.8d |
| 2 | F-100 A/B (afterburning) | 14.8a,b |
| 3 | TF-39 | 14.9 |

### §14.3.3 Factors Affecting Thrust and TSFC

**Fig. 14.7** — *Variation of turbine engine thrust with airspeed, temperature, pressure, and altitude*
*[Nicolai & Carichner, Fig. 14.7, p. 369]*. Four sub-plots, all Thrust on the y-axis (qualitative, no
numeric scale):
- **(a)** vs. Airspeed $V_a$: curve (A) "Ram Effect" rising from near zero, curve (B) "$V_a$ Effect"
  falling from an initial value, curve (C, dashed) "Resultant" — dips slightly then rises steeply,
  the sum of (A) and (B).
- **(b)** vs. Temperature $\theta_a$: single curve, monotonically decreasing.
- **(c)** vs. Pressure $P_a$: single curve, monotonically increasing (shallow slope).
- **(d)** vs. Altitude: two curves labeled "Turbofan" and "Turbojet" ("Thrust Lapse Rate"), both
  decreasing, with a change in slope marked at "36K'" (36,000 ft) — turbofan lapses faster than
  turbojet.

As the aircraft increases its speed, the velocity of the air entering the engine, $V_a$, increases.
The nozzle is usually close to a choked condition ($V_e$ near the speed of sound, see [1]) such that
$V_e$ is relatively constant. Thus, the $(V_e - V_a)$ term in Eq. (14.9) decreases with increasing
airspeed and the result is a decrease in thrust as shown by curve (A) in Fig. 14.7a. However, as $V_a$
increases, the airflow into the engine, $\dot{m}_a = \text{density} \times \text{velocity} \times
\text{capture area}$, increases due to ram effect and the result is an increase in thrust as shown by
curve (B) in Fig. 14.7a. The overall result of increasing airspeed is a combination of these two
effects and is shown as curve (C) in Fig. 14.7a. *[Nicolai & Carichner, §14.3.3, p. 369]*

The ram effect is important, particularly in high-speed aircraft, because eventually, when airspeed
becomes high enough, the ram effect will produce a significant overall increase in engine thrust. At
Mach numbers greater than 3.0 the ram effect can replace the compressor sections of turbine engines,
resulting in a ramjet engine. At subsonic speeds the ram effect is not very large and does not greatly
affect engine thrust. At supersonic speeds, however, ram can be a major factor in determining how much
thrust an engine will produce. *[Nicolai & Carichner, p. 369–370]*

The most significant variable in the thrust equation is mass airflow, $\dot{m}_a$. Because

$$\dot{m}_a = \rho V A$$
*(unnumbered equation)* *[Nicolai & Carichner, p. 370]*

and

$$\rho = p / R'\theta$$
*(unnumbered equation, perfect gas relation, $R'$ = characteristic gas constant)* *[Nicolai & Carichner,
p. 370]*

it can be observed that an increase in temperature will result in a decrease in thrust as shown in Fig.
14.7b. Similarly, an increase in pressure $p$ will give an increase in thrust as shown on Fig. 14.7c.
*[Nicolai & Carichner, p. 370]*

As the aircraft climbs in altitude, the temperature decreases until at the tropopause (36,000 ft) it
remains constant (see Appendix B). The pressure decreases steadily with increasing altitude. The result
of climbing in altitude is an interplay between the pressure and temperature variations giving a
decreasing thrust (called the *thrust lapse rate*) as shown in Fig. 14.7d. The lapse rate is greater
for a turbofan than a turbojet. The variation of thrust with altitude can be approximated by *[Nicolai
& Carichner, p. 370]*

$$T_n = (T_n)_{SL}\,(p/p_{SL})(\theta_{SL}/\theta) \tag{14.11}$$
*[Nicolai & Carichner, Eq. (14.11), p. 370]*

The TSFC for a turbine engine is given by Eq. (14.10), where the fuel flow to the engine is dependent
on the throttle position. Thus, for a constant throttle setting (i.e., military continuous power) the
TSFC varies with thrust. *[Nicolai & Carichner, p. 370]*

The optimum altitude for subsonic cruise is that altitude where the TSFC is a minimum for a cruise
power setting. For a turbine-powered aircraft cruising near Mach 0.8 the cruise power setting is around
80%–100% of normal rated thrust. The best altitude for cruise under these conditions is around 36,000
ft [4]. *[Nicolai & Carichner, p. 370]*

### §14.3.4 Turbine Engine Data

Appendix J contains information on the current stable of turbojet, turboprop, and turbofan engines. The
engine characteristics in Table J.1 do not reflect thrust losses and weights associated with installing
the engines into aircraft. Turbine engine corrections for installation into aircraft are discussed in
Chapter 16. Reference [5] is an excellent source of turbine engine data. It is published annually and is
kept up to date. *[Nicolai & Carichner, §14.3.4, p. 371]*

Table 14.3 presents the characteristics for the Pratt and Whitney F-100-PW-100 afterburning turbofan.
Figure 14.8 presents the variation of thrust and TSFC with altitude, airspeed, and throttle setting for
the engine. The thrust shown in Fig. 14.8 is the installed thrust, which is the net thrust $T_n$ from
the basic engine corrected for inlet and nozzle losses, airflow bleed, and turbine power extraction.
Figure 14.8g presents the mass airflow $\dot{m}_a$ required for the F-100 in afterburner and military
power. *[Nicolai & Carichner, p. 371]*

Table 14.4 presents the characteristics for the General Electric TF-39-GE-1 turbofan. The installed
engine data are shown in Figure 14.9 and are appropriate to a podded nacelle installation similar to
that of the C-5A [6]. Figure 14.10 shows the GE CF-6 engine, which is a popular commercial engine.
CF-6 engines were produced in many models providing power from DC-10s during the 1980s to today's
Boeing 747/767/777. *[Nicolai & Carichner, p. 371]*

**Table 14.3** — *Pratt and Whitney F-100-PW-100 Afterburning* *[Nicolai & Carichner, Table 14.3, p.
371]*

| Turbofan Characteristics | Value |
|---|---|
| Sea level static thrust | 23,000 lb (uninstalled) |
| Sea level static TSFC | 2.248 |
| Bare engine weight | 2737 lb |
| Sea level static airflow, $\dot{m}_a$ | 217 lbm/s |
| Engine length (including nozzle) | 190 in. |
| Maximum diameter | 44 in. |
| Compressor face diameter | 40 in. |
| Bypass ratio | 0.71 |

| Miscellaneous: Accessory Equipment Weight | Value |
|---|---|
| Fuel system | 433 lb |
| Engine controls | 22 lb |
| Starting system | 28 lb |

The installed engine data of Fig. 14.8 reflects the following propulsion unit corrections:
1. Power extraction of 70 hp to drive electric generators and auxiliary equipment. This 70 hp is at
   all power settings and flight conditions.
2. Normal shock inlet pressure recovery.
3. Nozzle corrections at moderate pressure ratios.
4. High-pressure bleed air extracted from compressor for operating environmental control system.
The bleed airflow rate is 0.4 lb/s.

**Fig. 14.8a** — *F-100 installed thrust, maximum afterburning* *[Nicolai & Carichner, Fig. 14.8a, p.
372]*. Thrust (1000 lb), y-axis 0–36, vs. Mach Number, x-axis 0–2.4. Family of curves parameterized by
Altitude (1000 ft) = 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65 — each rising from a Mach≈0.2
start value, peaking near Mach 1.6–2.0, then falling slightly (peak/start values read from plot,
approximate):

| Altitude (kft) | Thrust @ Mach 0.2 (1000 lb) | Peak thrust (1000 lb), approx. Mach |
|---|---|---|
| 0 | 18 | 34 @ M≈1.5 |
| 5 | 14 | 30 @ M≈1.6 |
| 10 | 12 | 28 @ M≈1.7 |
| 15 | 8 | 24 @ M≈1.8 |
| 20 | 6 | 20 @ M≈1.9 |
| 25 | 4.5 | 15 @ M≈1.7 |
| 30 | 3.5 | 12.5 @ M≈1.7 |
| 35 | 3 | 10 @ M≈1.7 |
| 40 | 2.5 | 8 @ M≈1.8 |
| 45 | 2 | 6.5 @ M≈1.9 |
| 50 | — | 5 @ M≈1.9 |
| 55–65 | — | 2–3 @ M≈2.0 |

*(read from plot)*

**Table 14.4** — *General Electric TF-39-GE-1 Turbofan Characteristics* *[Nicolai & Carichner, Table
14.4, p. 372]*

| Characteristic | Value |
|---|---|
| Sea level static thrust (uninstalled) | 41,100 lb |
| Sea level static TSFC | 0.315 |
| Sea level static airflow, $\dot{m}_a$ | 1541 lb/s |
| Bare engine weight | 7026 lb *(table prints "in."; unit is evidently a typo — bare engine weight is in lb)* |
| Engine length | 271 in. |
| Engine diameter (maximum) | 100 in. |
| Bypass ratio | 8 |
| Overall pressure ratio | 26 |

**Fig. 14.8b** — *F-100 TSFC for maximum afterburning (low altitudes)* *[Nicolai & Carichner, Fig. 14.8b,
p. 373]*. TSFC (lb/lb·h), y-axis 2.0–3.4, vs. Mach Number, x-axis 0–2.4. Family of curves for Altitude
(1000 ft) = 0, 5, 10, 15, 20, 25, 30, 35 — each showing a minimum TSFC around Mach 0.8–1.4 (roughly
2.1–2.3), rising toward both low and high Mach, with higher-altitude curves shifted to higher Mach for
their minimum and rising more steeply at high Mach (read from plot).

## §14.4 Ramjet Engine Operation

The *ramjet* operates on essentially the same gas cycle as the turbine. The ramjet is a very simple
device and is shown schematically in Fig. 4.6. However, all the compression portion of the cycle occurs
at the inlet and in the diffuser where the incoming air velocity is decreased producing a rise in
static pressure. Fuel is burned and the mixture expanded to ambient through a nozzle. The ramjet is
compared with other propulsion devices in Fig. 4.7. *[Nicolai & Carichner, §14.4, p. 373]*

At forward speeds of Mach ≤1.0 the ramjet is prohibitively expensive to operate because its low
combustion efficiency results in a TSFC greater than 6.0 (see Fig. 4.7c). At supersonic speeds a normal
shock is located just ahead of the inlet. A normal shock compression, although not ideal is a practical
substitute for a compressor. At Mach = 2.0 the shock compression ratio is about 4.5 and the ramjet TSFC
is competitive with an afterburning turbojet. Above Mach = 2 the ramjet starts rivaling the dry turbojet.
Thus, at Mach ≥2 the normal shock compression is an acceptable substitute for a mechanical compressor
making the ramjet a very light and simple machine. Because no turbine is present the usable temperature
limits are considerably higher than for a turbojet. *[Nicolai & Carichner, p. 373–374]*

One of the major problems connected with the ramjet is the issue of flame stability. The high speed of
the air through the duct tends to blow out the combustion. The art of the ramjet is in the design of a
flame

**Fig. 14.8c** — *F-100 TSFC for maximum afterburning (high altitudes)* *[Nicolai & Carichner, Fig.
14.8c, p. 374]*. TSFC (lb/lb·h), y-axis 2.0–3.4, vs. Mach Number, x-axis 0–2.4. Family of curves for
Altitude (1000 ft) = 35, 40, 45, 50, 55, 60, 65 — clustered together at low-to-moderate Mach (minimum
TSFC ≈2.1–2.2 around Mach 1.2–1.4), then diverging sharply at high Mach with higher altitudes rising to
much higher TSFC (up to ≈3.4 for 65 kft near Mach 2.2) (read from plot).

holder that will stabilize the combustion but produce minimum resistance to the flow. *[Nicolai &
Carichner, p. 375]*

## §14.5 Rocket Operation

All of the propulsion devices considered thus far depend upon atmospheric air and, to some extent,
forward speed for their operation. Rockets, however, are independent of atmospheric air or forward
speed. The atmospheric independence provides an advantage in that the rocket offers the only method of
developing thrust outside of the earth's atmosphere. However, this independence is also a disadvantage
in that all the mass creating the thrust must be carried in the rocket. Note that all of the propulsion
devices discussed earlier carried only their fuel and that most of the mass accelerated rearward for
thrust consisted of the ambient air. *[Nicolai & Carichner, §14.5, p. 375, 377]*

**Fig. 14.8d** — *F-100 TSFC for partial power settings (nonafterburning)* *[Nicolai & Carichner, Fig.
14.8d, p. 375]*. Two stacked plots, both TSFC (y-axis 0.6–1.4) vs. Installed Thrust (lb) (x-axis
0–6000), each a family of curves parameterized by $M_\infty$ = 0.4, 0.6, 0.8, 0.9, 1.0:
- Top: Altitude = 36,089 ft.
- Bottom: Altitude = 30,000 ft.
Each curve decreases steeply at low thrust then flattens to a shallow minimum before rising slightly at
the high-thrust end; higher $M_\infty$ curves sit at higher TSFC and extend to higher thrust.

**Fig. 14.8e** — *F-100 TSFC for partial power settings (nonafterburning)* *[Nicolai & Carichner, Fig.
14.8e, p. 376]*. Two stacked plots, both TSFC (y-axis 0.6–1.4) vs. Installed Thrust (lb) (x-axis
0–3000), each a family of curves parameterized by $M_\infty$ = 0.6, 0.8, 0.9, 1.0:
- Top: Altitude = 55,000 ft.
- Bottom: Altitude = 45,000 ft.
Same qualitative shape as Fig. 14.8d, shifted to lower thrust values at these higher altitudes.

**Fig. 14.8f** — *F-100 TSFC for partial afterburning* *[Nicolai & Carichner, Fig. 14.8f, p. 377]*.
TSFC, y-axis 0.8–2.4, vs. Installed Thrust (1000 lb), x-axis 0–16, Altitude = 36,089 ft. Family of
curves for $M_\infty$ = 0.4, 0.6, 0.8, 0.9, 1.0, 1.2, 1.4, 1.6, 1.8 fanning outward from a common
low-thrust region (~TSFC 0.9–1.0 at thrust ≈3500–4000 lb) to higher thrust and TSFC as Mach increases,
converging again at the high-thrust/high-TSFC corner (TSFC≈2.2–2.4 at thrust≈14,000–16,000 lb for
$M_\infty$=1.6–1.8).

The thrust of a rocket is expressed as

$$T = \dot{m}_{CP}V_e + A_e(P_e - P_a) \tag{14.3}$$
*[Nicolai & Carichner, Eq. (14.3), p. 377 — restated from p. 357]*

**Fig. 14.8g** — *Required mass flow for PW F-100 turbofan engine at maximum power* *[Nicolai &
Carichner, Fig. 14.8g, p. 377]*. Engine Required Airflow $\dot{m}_a$ (lbm/sec), y-axis 0–350, vs. Mach
Number, x-axis 0–2.0, for the F-100-PW-100 at Maximum Power and Normal Rated Thrust, $T_{SLS}$=24,300
lb. Family of curves labeled Sea Level, 15,000 ft, 25,000, 30,000, 36,000, 45,000 — each increasing with
Mach number, with airflow decreasing at a given Mach as altitude increases (e.g., Sea Level: ~215
lbm/s at Mach 0 rising to ~345 at Mach≈1.0; 45,000 ft: ~45 lbm/s at Mach≈0.7 rising to ~150 at
Mach≈1.9). Figure note: "sometimes $\dot{m}_a$ is referred to as $\dot{m}_E$, the engine demand
airflow...$\dot{m}_a$ and $\dot{m}_E$ are the same." *(read from plot)*

**Fig. 14.9a** — *Installed thrust and TSFC for TF-39 turbofan engine (see Table 14.4)* *[Nicolai &
Carichner, Fig. 14.9a, p. 378]*. Sea Level, dual y-axis: Thrust (1000 lb) 0–50 (left) and TSFC 0–2.0
(right), vs. Mach Number, x-axis 0–1.0. Four power settings per the legend (Curve 1 = Military Rated
Thrust, 2 = Normal Rating (continuous), 3 = 80% Normal Rating, 4 = 50% Normal Rating): Thrust curves (1
solid dashed "Military Thrust", labeled "Normal Thrust"/"80% Normal Thrust"/"50% Normal Thrust") all
decrease with Mach number from ~40/30/17/7 (1000 lb) at Mach 0; TSFC curves (1–4) all increase with
Mach number, converging near Mach 0.8–0.9 at TSFC≈1.2–1.9 *(read from plot)*.

The exhaust velocity depends on the composition of the propellant, the design of the exhaust nozzle,
and the ambient conditions. The thrust specific fuel consumption of a rocket is TSFC = propellant
weight flow (lb) per hour per thrust. Rockets are very fuel inefficient compared to all other
propulsion devices, as shown in Fig. 4.7c. The World of Rockets likes to use specific impulse $I_{SP}$
as a measure of fuel consumption. Specific impulse is the reciprocal of TSFC, expressed in seconds and
written as *[Nicolai & Carichner, p. 378]*

$$I_{SP} = T / g\dot{m}_{CP} = 3600/\text{TSFC} \tag{14.12}$$
*[Nicolai & Carichner, Eq. (14.12), p. 378]*

In space (vacuum) for a perfectly designed nozzle (full expansion to zero pressure) the expression for
specific impulse is

$$I_{SP} = V_e/g = V_e/32.17 \tag{14.13}$$
*[Nicolai & Carichner, Eq. (14.13), p. 378]*

The highest specific impulse values are obtained by using hydrogen as a fuel and burning it with either
oxygen or fluorine. At sea level with a combustion chamber operating at 500 psia the specific values are
*[Nicolai & Carichner, p. 378]*

$$\text{Hydrogen} + \text{Fluorine} \rightarrow I_{SP} = 375\ \text{seconds}$$
$$\text{Hydrogen} + \text{Oxygen} \rightarrow I_{SP} = 362\ \text{seconds}$$
*(unnumbered values)* *[Nicolai & Carichner, p. 378]*

**Fig. 14.9b** — *Installed thrust and TSFC for TF-39 turbofan engine (see Table 14.4)* *[Nicolai &
Carichner, Fig. 14.9b, p. 379]*. Two stacked plots, each dual y-axis Thrust (1000 lb) / TSFC vs. Mach
Number (0–1.0), same four power-setting curves (1–4) as Fig. 14.9a:
- Top: 31,000 ft, Thrust 0–20 (left), TSFC 0–1.0 (right).
- Bottom: 15,000 ft, Thrust 0–40 (left), TSFC 0–1.6 (right).
Same qualitative shape as Fig. 14.9a (thrust curves decreasing with Mach, TSFC curves increasing,
crossing near Mach 0.5–0.6) *(read from plot)*.

The combinations of hydrogen and oxygen or fluorine are difficult to handle so that modern rockets use
more modest fuel–oxidizer combinations, including solid propellants. The current space rockets have
specific impulses at sea level of 200–300 seconds. *[Nicolai & Carichner, p. 379]*

**Fig. 14.9c** — *Installed thrust and TSFC for TF-39 turbofan engine (see Table 14.4)* *[Nicolai &
Carichner, Fig. 14.9c, p. 380]*. Two stacked plots, each dual y-axis Thrust (1000 lb) / TSFC vs. Mach
Number (0–1.0), same four power-setting curves (1–4):
- Top: 41,000 ft, Thrust 0–10 (left), TSFC 0–1.0 (right).
- Bottom: 35,000 ft, Thrust 0–20 (left), TSFC 0–1.0 (right).
Same qualitative shape as Figs. 14.9a/b *(read from plot)*.

**Sidebar: Whittle and von Ohain Change Aviation** *[Nicolai & Carichner, p. 380]*

Hans von Ohain and Frank Whittle developed the jet turbine engine about the same time in the 1930s but
completely independent of one another — Ohain in Germany and Whittle in England. Whittle did his
graduate work at

**Fig. 14.10** — *CF-6 engine based on the TF-39 design* *[Nicolai & Carichner, Fig. 14.10, p. 381]*.
Photograph of a General Electric CF-6 turbofan engine, cutaway/uncowled, mounted on a hoist stand,
showing the large single-stage fan, core compressor casing, and external tubing/harnesses.

Cranwell College as an RAF Flight Officer. His field of study was a new type of gas turbine and he was
granted a patent in 1930. His RAF duties and lack of money prevented any serious development of the jet
engine until 1937. The British Air Ministry was slow in recognizing the potential of the jet turbine but
finally contracted with Whittle for an engine and with Gloster Aircraft for a jet engine powered
aircraft in 1939. The Gloster E.28/39 flew on 15 May 1941 with Whittle's jet engine.

Hans von Ohain did his graduate work at the University of Göttingen and received a doctorate in physics
and a patent for his jet engine concept in November 1935. Unlike Whittle, Hans was a man of means and
hired a mechanic to build a working model of his concept. Ernst Heinkel (Heinkel Aircraft Co.) was
impressed with the model and hired Hans in March 1936 to develop a jet turbine engine. A prototype jet
engine was developed and ran successfully on hydrogen gas in March 1937. Heinkel was pleased with von
Ohain's success and commissioned him to develop a flightworthy, kerosene-fueled engine to power the
Heinkel He-178 aircraft shown in Fig. 14.11. Hans developed a jet engine with 992 lb of thrust; it flew
in the He-178 on 27 August 1939 and changed the world forever.

After World War II Whittle's engine was produced by several companies in England and the United States.
Frank Whittle was knighted by King George VI of England in August 1948. He eventually immigrated to the
United States, where he became a research professor at the U.S. Naval Academy in Annapolis, Maryland.
He died on 9 August 1996.

After World War II Hans came to the United States as part of Operation Paper Clip. He was assigned to
Wright–Patterson AFB, Dayton, Ohio, as a propulsion consultant, then as Chief Scientist to the Propulsion
Laboratory, and finally to the Aeronautical Research Laboratory. He retired from government service in
1979 and continued as a consultant to the University of Dayton Research Institute. He and his family
settled in nicely in midwestern suburbia, living in Centerville (south of Dayton).

I met Hans in 1972 while on active duty at Wright–Patterson AFB, and our friendship flourished until his
death in 1998. He was very gracious with his advice and was an annual visitor to my aircraft design short
course in Dayton from 1975 to the mid-1990s. Hans and Sir Frank changed the aviation world with their
invention of the jet engine. Hans was a technical giant, a true gentleman, and very humble.

— *Leland Nicolai* *[Nicolai & Carichner, sidebar "Whittle and von Ohain Change Aviation", pp. 380–382]*

**Fig. 14.11** — *Heinkel He-178 aircraft designed for the first jet engine* *[Nicolai & Carichner, Fig.
14.11, p. 382]*. Photograph (period, black-and-white) of the Heinkel He-178 low-wing monoplane on the
ground, straight wing, tricycle-esque main gear, ventral engine intake, small vertical tail.

## References

[1] Hill, P. G., and Peterson, C. R., *Mechanics and Thermodynamics of Propulsion*, Addison Wesley,
    Reading, MA, 1965.
[2] McCormick, B., *Aerodynamic, Aeronautics and Flight Mechanics*, Wiley, New York, 1995.
[3] Mitlisky, F., Weisberg, A., and Myers, B., "Regenerative Fuel Cells," Lawrence Livermore National
    Laboratory, UCRL-JC-134540, June 1999, paper prepared for the U.S. Department of Energy Hydrogen
    Program 1999 Annual Review Meeting, Lakewood, CO, 4–6 May 1999.
[4] "The Aircraft Gas Turbine Engine and Its Operation, Pratt and Whitney Operating Instruction 200,"
    United Aircraft Corp., East Hartford, CT, Nov. 1960.
[5] *Aviation Week and Space Technology, Annual Aerospace Source Book*, McGraw-Hill, New York
    (published annually in January).
[6] Smith, P. R., "C-5A Aerodynamic Substantiating Data Based on Flight Test," Rept. LGIC22-1-1,
    Lockheed-Georgia Co., Lockheed Aircraft Co., Marietta, GA, 16 Aug. 1971.
*[Nicolai & Carichner, References [1]–[6], p. 382]*

Chapter 14 extraction complete.
