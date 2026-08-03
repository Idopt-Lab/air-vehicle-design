# Chapter 18 — Propulsion System Thrust Sizing

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, Chapter 18,
printed pp. 467–490 (PDF pp. 477–500).

Text-layer inventory (built before extraction, for completeness checking): Figs 18.1–18.10 (with
sub-labels 18.3a, 18.4b to be confirmed during extraction); Tables 18.1, 18.2; Eqs (18.1)–(18.8).

## Chapter opener

Section list: Turbine Engine Thrust Sizing; Turbine Engine Scaling; Piston Engine Sizing; Solar-Power
Sizing; Human-Power Sizing; Rocket Engine Sizing. *[Nicolai & Carichner, p. 467]*

Photo caption: *Formula One racing aircraft Nemesis rounding the pylon on its way to another win at the
Reno National Championship Air Races. (Photograph courtesy of Jon Sharp.)* *[Nicolai & Carichner, p. 467]*

Chapter epigraph: *"Small deeds done are better than great deeds planned."* — Peter Marshall *[Nicolai &
Carichner, p. 467]*

## §18.1 Introduction (p. 468)

Sidebar: *The Nemesis was built and piloted by Jon Sharp, a research engineer at the Lockheed Martin Skunk
Works. The 520-lb Nemesis with a stock 100-hp Continental piston engine won every Reno championship race
from 1991 to 1995, plus 20 out of 22 races entered during the period. In 1993 Nemesis set a new Formula
One A class (F1A) 3-km closed course speed record of 277.26 mph at Oshkosh, Wisconsin, and received the
Bleriot Award.* *[Nicolai & Carichner, p. 468]*

At this point in the design game, the size of the fuselage is known, the general configuration has been
established, and the first estimate of the aircraft aerodynamics is complete. Now the propulsion unit
needs to be sized, that is, select the $(T/W)_{TO}$ so that the aircraft performance can be determined and,
in the case of a jet aircraft, the inlet sized and designed. *[Nicolai & Carichner, p. 468]*

Sometimes the designer works with existing "off the shelf" engines, such as those reported in Appendix J;
the designer would vary the number and type, finding the combination that gives the required vehicle
performance at minimum weight, cost, and noise. Other times the designer might work with a nonexisting
conceptual engine — in this case the engine manufacturer would give the designer a "rubber" engine, that
is, a paper engine that can be scaled up or down according to scaling laws established by the engine
manufacturer. In the case of a jet engine, the designer would vary the engine thrust and perhaps the
number of engines to fit the parametric study; the appropriate engine weight, diameter, and length would
be determined from the engine scaling information. Occasionally, the designer might examine the influence
of engine turbine temperature, overall pressure ratio, fan pressure ratio, and bypass ratio on aircraft
design; however, this type of parametric study is usually performed by the engine manufacturer as part of
the paper engine design. *[Nicolai & Carichner, p. 468]*

The $(T/W)_{TO}$ is usually sized by one or more of the following items *[Nicolai & Carichner, p. 468]*:

1. Cruise/Loiter
2. Energy maneuverability (air combat)
3. Acceleration-time and fuel burned during acceleration
4. Takeoff
5. Maximum speed

These criteria are often in conflict with one another. The designer must consider the $(T/W)_{TO}$ for
these mission requirements, establish their priorities, and then decide upon an appropriate compromise,
after looking at the entire mission. Table 18.1 indicates trends in $(T/W)_{TO}$ based upon current
aircraft. *[Nicolai & Carichner, p. 468]*

## §18.2 Turbine Engine Scaling (p. 468)

Assume that the aircraft designer has selected the propulsion type, in terms of bypass ratio, turbine
inlet temperature, and pressure ratio, and now desires to scale it up or down to get the proper $T/W$. The
engine man-

**Table 18.1** — *T/W Range for Various Aircraft Types* *[Nicolai & Carichner, Table 18.1, p. 469]*:

| Dominant Mission Requirement | Range for $(T/W)_{TO}$ (uninstalled) |
|---|---|
| Long range | 0.2–0.35 |
| Short and intermediate range with moderate field length | 0.3–0.45 |
| STOL and utility transport | 0.4–0.6 |
| Fighter—close air support | 0.4–0.6 |
| Fighter—strike interdiction | 0.45–0.7 |
| Fighter—air-to-air | 0.8–1.3 |
| Fighter—interceptor | 0.55–0.8 |

ufacturer provides a reference engine (either a paper engine or an existing engine) and the appropriate
scaling information. The engine weight, diameter, and length scale according to the mass flow as follows
*[Nicolai & Carichner, Eq. (18.1), p. 469]*:

$$W_{eng} = \left(\frac{\dot{m}}{\dot{m}_{REF}}\right)^n (W_{eng})_{REF} \tag{18.1}$$

where $n = 0.8$–1.3 (usually about 1.0) and $\dot{m}$ is sea level static (SLS) airflow required for the
engine. From Chapter 14, *[Nicolai & Carichner, Eq. (14.1), p. 469 — restated from p. 356]*:

$$T = \dot{m}(V_e - V_a) + A_e(P_e - P_a) \tag{14.1}$$

and if constant nozzle velocity $V_e$ is assumed for any thrust size, then *[Nicolai & Carichner, Eq.
(18.2), p. 469]*:

$$\left(\frac{T}{T_{REF}}\right) = \left(\frac{\dot{m}}{\dot{m}_{REF}}\right) \tag{18.2}$$

Eq. (18.2) is usually a pretty good assumption and facilitates the engine scaling. The engine diameter $d$
and length $\ell$ scale as follows *[Nicolai & Carichner, Eqs. (18.3)–(18.4), p. 469]*:

$$d = \left(\frac{\dot{m}}{\dot{m}_{REF}}\right)^{1/2} d_{REF} \tag{18.3}$$

$$\ell = \left(\frac{\dot{m}}{\dot{m}_{REF}}\right)^{n-(1/2)} \ell_{REF} \tag{18.4}$$

## §18.3 Turbine Engines Sized for Cruise Efficiency (p. 469)

The turbine engine is sized by matching the thrust required (drag) during best cruise condition with the
thrust available at the power setting

for minimum thrust specific fuel consumption (TSFC). This power setting for minimum TSFC varies from
engine to engine — for example, the F-100 (Fig. 14.8d) at Mach = 0.8 and 36,089 ft has a minimum TSFC at
70% normal rated thrust (NRT), whereas the TF-39 (Fig. 14.9c) at Mach = 0.8 and 35,000 ft has a minimum at
100% NRT. The engine sizing should be checked at several points during the cruise, as the aircraft cruise
climbs, to find the best sizing compromise. *[Nicolai & Carichner, p. 470]*

### Example 18.1 — Sizing for Optimum Cruise Performance (p. 470)

Consider a four-engine long-range cruise transport using scaled TF-39 engines. Size the engines for
optimum cruise performance.

**Assume:**

| Parameter | Value |
|---|---|
| $W_{TO}$ | 500,000 lb |
| $(W/S)_{TO}$ | 120 psf |
| $W_{fuel}/W_{TO}$ | 0.40 |
| $S_{ref}$ | 4167 ft² |
| $W/S$ at start of cruise | 116 psf |
| Cruise at Mach | 0.8 |
| $C_{D_{min}}$ | 0.018, $d/b=0.1$ |
| Wing, AR | 8.0 |
| $\Lambda$ | 30 deg |
| $\lambda$ | 0.37 |
| Section | NACA 64₂-215 airfoil |

**Determine:**

| Item | Value |
|---|---|
| Cruise | from 31,000 ft to 41,000 ft |
| From Appendix F: $\alpha_{0L}$; $r_{LE}$ | 2.6 deg; 1.1% chord |
| From §13.1.1: $C_{L\alpha}$; $C_{L_{min}}$ | 0.1 per degree; 0.26 (see Fig. F.5) |
| From §13.2.1 and Fig. G.9 ($e=0.65$): $K$; $K'$; $K''$ | 0.0606; 0.0406; 0.02 |
| $(L/D)_{max}$ | 17.3 [from Eq. (3.10b), Chapter 3] |
| Drag and thrust required (start of cruise): $q$; $C_L=W/qS_{ref}$; $C_D=C_{D_{min}}+K'C_L^2+K''(C_L-C_{L_{min}})^2$ | 269.5 psf at Mach = 0.8 and 31,000 ft; 116/270 = 0.430; 0.018 + 0.0081 = 0.0261 |

*[Nicolai & Carichner, Example 18.1, p. 470, citing Appendix F, §13.1.1, §13.2.1, Fig. G.9, Eq. (3.10b)]*

| Item | Value |
|---|---|
| Cruise $L/D$ | 0.43/0.0261 = 16.48 [agrees well with result from Eq. (3.29)] |
| Drag | $C_D q S$ = (0.0261)(269.5)(4167) = 29,308 lb |
| Required thrust | 7327 lb (each engine) |

An examination of Fig. 14.9b for 31,000 ft indicates that the power setting for the TF-39 that gives the
lowest TSFC in continuous operation is 100% NRT. Thus, for 100% NRT: thrust available each engine =
9460 lb. Therefore, use four TF-39 engines that are scaled: scaling factor = 7327/9460 = 0.775. *[Nicolai
& Carichner, p. 471]*

The scaled engines will have 77.5% of the thrust and airflow (assume $V_e$ to be the same) of the TF-39
engines:

**Assume:**

| Parameter | Value |
|---|---|
| Engine weight | (0.775)(7026) = 5442 lb |
| Diameter | $\sqrt{(0.775)(100)} = 88$ inches |
| Bullet length | $\sqrt{(0.775)(271)} = 238.6$ inches for $n=1.0$ |
| $T_{SLS}$ | 0.775(41,100) = 31,853 lb |
| $(T/W)_{TO}$ | 0.255 |

**Check engine sizing for end of cruise:**

| Item | Value |
|---|---|
| At end of cruise | $W/S \sim 80$ psf |
| $q$ | 168 psf at Mach = 0.8 and 41,000 ft |
| $C_L$ | 0.477 |
| $C_D$ | 0.018 + 0.010 = 0.028 |
| Cruise $L/D$ | 16.93 |
| Drag | 19,568 lb |
| Thrust required each engine | 4892 lb |
| Thrust available each engine | (6400)(0.775) = 4960 lb at 100% NRT (from Fig. 14.9c) |

Thus, the 77.5% scaling of the TF-39 provides a good engine match at the beginning and end of cruise.
*[Nicolai & Carichner, p. 471]*

## §18.4 Energy Maneuverability (Air-to-Air Combat) (p. 471)

The performance of an aircraft in air combat at a point in velocity–altitude space is indicated by its
value of *maximum sustained turn rate* (from Chapter 3) *[Nicolai & Carichner, Eq. (3.32), p. 471 —
restated]*:

$$\dot{\psi}_{MS} = \frac{g\sqrt{n_{MS}^2-1}}{V} \tag{3.32}$$

**Fig. 18.1** — *F-100 TSFC for partial power setting at Mach = 0.9 and 30,000 ft (see Fig. 14.7)*
*[Nicolai & Carichner, Fig. 18.1, p. 472]*. Plot of TSFC (0.6–1.4) vs. Thrust (1000 lb, 0–5) at
Mach = 0.9/30,000 ft: a curve starting near TSFC = 1.4 at low thrust, declining steeply to a shallow
minimum ("bucket") of about TSFC = 0.91 around 3.5–4.5 (1000 lb) thrust, then rising slightly toward
Thrust = 5. Two shaded callout regions are annotated: "Might operate here if $(T/W)_{TO}$ is too large"
(upper-left, high-TSFC region) and "Would like to operate here during cruise" (lower-right, near the
TSFC minimum).

where $n_{MS}$ is the *maximum sustained load factor*. The $n_{MS}$ can be expressed by *[Nicolai &
Carichner, Eq. (18.5), p. 472]*:

$$n_{MS} = \frac{q}{\sqrt{W/S}}\sqrt{\frac{1}{K}\left[\frac{T}{W}\frac{1}{q} - \frac{C_{D_0}}{W/S}\right]}
\tag{18.5}$$

(from §3.9). Eq. (18.5) indicates that large $T/W$ gives improved combat maneuverability. However, as
$T/W$ increases the cruise situation worsens because the engine would have to be throttled back during
cruise, which moves away from the minimum TSFC bucket as shown in Fig. 18.1. *[Nicolai & Carichner, p.
472]*

Also, as $T/W$ increases so does the propulsion weight. Thus, for a large $T/W$ there would be a lot of
extra weight that is used for only a portion of the mission (admittedly the most important part of the
mission). Again it is emphasized to examine the entire mission fuel requirement before selecting the
$(T/W)_{TO}$. *[Nicolai & Carichner, p. 472]*

## §18.5 Engine Sizing for Acceleration (p. 472)

Acceleration can be examined very simply by looking at the ideal rocket equation *[Nicolai & Carichner,
Eq. (18.6), p. 472]*:

$$\Delta V = I_{sp}'g\ln\left(\frac{W_i}{W_f}\right) \tag{18.6}$$

where $I_{sp}'$ is the effective $I_{sp}$ available for accelerating the vehicle. The effective $I_{sp}$ is
defined as *[Nicolai & Carichner, Eq. (18.7), p. 473]*:

$$I_{sp}' = I_{sp}\left(1-\frac{D}{T}\right) \tag{18.7}$$

where $D$ is the drag, $T$ is the thrust available, and $I_{sp} = 3600/\text{TSFC}$ is the *engine specific
impulse*. It is clear from Eqs. (18.6) and (18.7) that the thrust must be much larger than the drag;
otherwise the $I_{sp}'$ will be small and considerable fuel will be expended during a $\Delta V$
acceleration. If $\Delta V$ is a very large increment, the $I_{sp}'$ must be an averaged value over the
acceleration interval. *[Nicolai & Carichner, p. 473]*

The acceleration performance of an aircraft improves as $D/T$ decreases or $(T/W)_{TO}$ is increased —
the excess thrust ($T-D$) increases, which decreases acceleration time and fuel burned. Absolute minimum
intercept or acceleration time would mean $(T/W)_{TO} \to \infty$. A typical plot of time vs. $(T/W)_{TO}$
is shown in Fig. 18.2, and it is observed that after a certain $(T/W)_{TO}$ the curve gets rather flat,
resulting in a small improvement for additional $(T/W)_{TO}$. Eqs. (18.6) and (18.7) indicate that the
fuel burned during an acceleration continues to decrease as $(T/W)_{TO}$ increases. It is misleading to
look solely at acceleration fuel burned because, as $(T/W)_{TO}$ increases, the weight of the propulsion
system increases; thus, a better quantity to examine is the sum of engine weight plus fuel weight. This is
shown plotted in Fig. 18.2 for a conceptual Advanced Manned Interceptor (AMI). Near-minimum acceleration
time is certainly important for an interceptor; however, the designer must trade off decreased acceleration
time with increasing engine-plus-fuel weight. Fig. 18.2 shows the point design for the AMI at a
$(T/W)_{TO} = 0.586$ (two reference turbo-ramjet engines), which is a compromise between acceleration time
and engine-plus-fuel weight. The AMI is also range dominated, and the designer is reminded to examine the
cruise efficiency also before making the final selection for $(T/W)_{TO}$. *[Nicolai & Carichner, p. 473]*

**Fig. 18.2** — *Acceleration performance of an Advanced Manned Interceptor (acceleration from 250 ft/s to
Mach 4.5 at 75,000 ft)* *[Nicolai & Carichner, Fig. 18.2, p. 474]*. Two side-by-side plots vs.
$(T/W)_{TO}$ (0.3–0.7). Left: Acceleration Time (seconds, 200–1200) — a steeply declining curve from
~1100 s at $(T/W)_{TO}=0.31$ down to ~300 s at $(T/W)_{TO}=0.7$, flattening noticeably above ~0.5; a
"Point Design" marker sits at $(T/W)_{TO}\approx0.586$, ~370 s. Right: Engine + Fuel Weight (1000 lb,
30–35) — a U-shaped curve with minimum ~31.1 (1000 lb) near $(T/W)_{TO}\approx0.48$, rising to ~34.1 at
$(T/W)_{TO}=0.33$ and ~32.6 at $(T/W)_{TO}=0.7$; the same "Point Design" marker sits at
$(T/W)_{TO}\approx0.586$, ~31.6 (1000 lb). Inset text (left panel): "Point Design: $W_{TO}=150{,}000$ lb,
$(W/S)_{TO}=125$ psf, Radius = 1500 n mile. Engine: TurboRamjet, $T_{SLS}=44{,}000$ lb, Engine Weight =
5754 lb."

## §18.6 Turbine Engine Sizing for Takeoff (p. 473)

If a short takeoff distance is a primary mission requirement, it should be considered in a fair amount of
detail at this point because it may size the engines. The takeoff analysis is discussed in Chapter 10. It
must be remembered that a short takeoff distance can be achieved using combinations of $(T/W)_{TO}$,
$(W/S)_{TO}$, and high-lift devices [see Fig. 6.3 and Eq. (6.3)]. Thus, a short takeoff distance need not
have a high $(T/W)_{TO}$. *[Nicolai & Carichner, p. 473]*

### Example 18.2 — Turbine Engine Sizing Dilemma (p. 473)

Fig. 18.3a shows the mission profile for the Advanced Tactical Fighter (ATF) that became the F-22. The
mission profile is very

**Fig. 18.3** — *Typical tactical fighter mission profile and its associated $(T/W)_{TO}$ variation*
*[Nicolai & Carichner, Fig. 18.3, p. 475]*. Two stacked panels. **(a)** Altitude (1000 ft, 0–50) vs. Range
(n mile, 0–1200): a mission profile line labeled sequentially — Climb & Accel to Cruise M & Alt (0 to
~42,000 ft) → Cruise Out (~42,000–44,000 ft, leveling then stepping down) → M>1 Dash (descending to
~26,000 ft) → Drop Weapons (marked point) → Combat (spiral loop symbol at ~11,000–26,000 ft) → Accel &
Climb to Cruise M & Alt (climbing to ~47,000 ft) → Cruise Back (~47,000–48,000 ft) → descent to 0 at
~1150–1200 n mile. **(b)** $W_{TO}$ (1000 lb, 20–60) vs. $(T/W)_{TO}$ (0.7–1.3), with three curves labeled
$(W/S)_{TO}$ = 64, 84, 104 (psf) — each U-shaped or rising, with the 64 psf curve highest and steepest at
large $(T/W)_{TO}$ (reaching ~55,000 lb at 1.25) and the 104 psf curve lowest (reaching ~44,000 lb at 1.15);
a dotted line labeled "From Fig. 18.4b" crosses near $(T/W)_{TO}\approx0.85$–1.0, intersecting the 64 psf
curve's minimum around $(T/W)_{TO}\approx1.0$, $W_{TO}\approx46{,}000$ lb.

demanding as it calls for a significant supersonic cruise phase, a supersonic dash, several acceleration
phases, and air combat. The Air Force was asking for supercruise, supermaneuver, and superstealth—all in
the same airplane. This example will bring out the dilemma facing the designer when selecting the
$(W/S)_{TO}$ and $(T/W)_{TO}$ for an aircraft that is driven by several conflicting requirements. *[Nicolai
& Carichner, p. 476]*

**Fig. 18.4** — *$(W/S)_{TO}$ variation for a typical tactical fighter on its basic mission* *[Nicolai &
Carichner, Fig. 18.4, p. 476]*. Two stacked panels vs. $(W/S)_{TO}$ (50–120). **(a)** $W_{TO}$ (1000 lb,
20–60): a single declining curve with three marked points labeled $(T/W)_{TO}$ = 1.0 (at $(W/S)_{TO}
\approx 64$, $W_{TO}\approx47{,}000$ lb), 0.93 (at $(W/S)_{TO}\approx84$, $W_{TO}\approx39{,}000$ lb), and
0.86 (at $(W/S)_{TO}\approx104$, $W_{TO}\approx35{,}500$ lb). **(b)** $\dot{\psi}_{MS}$ (deg/s, 7–11): two
curves, solid for $(T/W)_{TO}=0.93$/0.86 (labeled at points, from ~10.7 down to ~7.5) and dashed for
$(T/W)_{TO}=1.0$ (from ~11 down to ~8.2), with an "Increasing (T/W)" arrow pointing from the solid curve up
toward the dashed curve; marked points $(T/W)_{TO}=0.93$ at $\dot{\psi}_{MS}\approx9.1$ and
$(T/W)_{TO}=0.86$ at $\dot{\psi}_{MS}\approx7.9$.

Figs. 18.3b and 18.4a show that the $W_{TO}$ decreases for increasing $(W/S)_{TO}$ and decreasing
$(T/W)_{TO}$. The decreasing $(W/S)_{TO}$ is understandable from the discussion in Chapter 6 and the fact
that the level of air combat is not specified. The best $(T/W)_{TO}$ from Figures

18.3b and 18.4a would be a compromise between the supercruise, supersonic dash, and acceleration
requirements. When air combat is considered, Fig. 18.4b, the situation is reversed; the desire to have
high $\dot{\psi}_{MS}$ would drive the design to high $(T/W)_{TO}$ and low $(W/S)_{TO}$. The designer has
a dilemma and must compromise the design to give tolerable cruise performance, acceleration fuel, and air
combat levels. *[Nicolai & Carichner, p. 477]*

## §18.7 Solar Power (p. 477)

The sun is a source of unlimited energy during the day. Every day it bathes the outer edge of the earth's
atmosphere with 127 W/ft² of solar energy on average; the 127 W/ft² is termed the *solar constant*. The
amount of solar energy received anywhere on the earth at a point in time depends on the latitude $\Phi$ of
the surface, the tilt (inclination) of the earth's spin axis as it orbits around the sun, and its position
relative to the sun (time of day). *[Nicolai & Carichner, p. 477]*

This dependence is shown in Fig. 18.5. The inclination of the earth to the orbital plane varies between
+23.5 deg on 21 June and −23.5 deg on 21 December and is the reason the earth has its four seasons. On 21
June the northern hemisphere is getting more solar energy and is enjoying summer while the southern
hemisphere is getting less and is having winter; on 21 December the situation reverses. On 21 June the
northern hemisphere has its longest day of the year and on 21 December the shortest. *[Nicolai &
Carichner, p. 477]*

The solar energy received on earth is converted to useful electrical energy by the photovoltaic action of
solar cells. The electrical energy per unit area available from a horizontal solar cell of efficiency
$\eta_{SC}$ at an altitude $H$ and solar elevation angle $\theta$ is *[Nicolai & Carichner, Eq. (18.8), p.
477]*:

$$P_{Elect} = P_{Solar}\eta_{SC}\sin\theta \tag{18.8}$$

where $\theta$ is the elevation angle of the sun above the horizon and $\sin\theta$ accounts for the
presented area of the horizontal solar cell. The solar elevation angle is a complicated function of the
latitude, inclination angle (time of year), and orientation to the sun (time of day) [1,2]. The best way to
determine $\theta$ is to go to the National Oceanic and Atmospheric Administration (NOAA) Web site and use
their solar position indicator. *[Nicolai & Carichner, p. 477]*

The quantity $P_{Solar}$ is the average solar radiation at altitude $H$ and solar elevation angle $\theta$.
The earth's *atmospheric mass* (AM) has a significant effect on the value of $P_{Solar}$: the water and
ozone in the atmosphere absorb and scatter the solar radiation. $P_{Solar} = 127$ W/ft² in space (outside
the earth's atmosphere at an altitude of approximately 320,000 ft or 53 n mile), whereas $P_{Solar} = 96.5$
W/ft² on the earth's surface and $\theta=90$ deg, having suffered a 24% energy loss due to atmospheric
attenuation. The space condition is termed AM0 and the condition on the earth's surface and $\theta=90$
deg is AM1.0. Values for $P_{Solar}$ at altitude $H$ and solar elevation angle $\theta$ are given

**Fig. 18.5** — *Solar energy radiated to earth during the year* *[Nicolai & Carichner, Fig. 18.5, p.
478]*. Upper diagram: schematic of the earth's orbit around the sun showing four positions — Spring,
Summer (+23.5° tilt), Fall, Winter (−23.5° tilt) — each earth globe shown with its tilt axis relative to
the orbital plane; a table lists "Time of Year / Distance to Sun": 4 July / 82.74 M nm, 4 Jan / 80.13 M
nm. Caption note: *The solar energy incident on the earth changes due to its tilt (inclination) and
orientation as it revolves around the sun. The latitude (location), earth's tilt (time of year), and
position (time of day) relative to the sun results in different amounts of the sun's energy hitting the
earth.* Lower diagram: parallel wavy lines labeled "Average Radiant Energy from Sun, 127 Watts/ft²"
striking a globe with Miami and Moscow marked as reference latitude points.

in Fig. 18.6 (essentially, $H$ and $\theta$ define the *slant range* through the atmosphere). *[Nicolai &
Carichner, p. 479]*

**Fig. 18.6** — *Direct clear-sky $P_{solar}$ (W/ft²)* *[Nicolai & Carichner, Fig. 18.6, p. 479]*. Contour
plot of Apparent Solar Elevation Angle $\theta$ (0–90 deg) vs. Geometric Altitude (1000 ft, 0–70), with
$P_{solar}$ contour lines labeled 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 115, 116, 117, 118, 119,
120 W/ft², generally increasing with both altitude and elevation angle; four reference points marked on
the vertical axis at Altitude = 0: AM1 ($\theta=90$), AM1.5 ($\theta\approx42$), AM2 ($\theta\approx30$),
AM3 ($\theta\approx20$).

Even though the solar energy is limitless and free, it is small when compared with the energy available
from burning hydrocarbon fuels (i.e., gasoline or kerosene). Because the power required increases by the
cube of the speed and the available solar power is small, the speed of a solar aircraft will always be
less than 30 KEAS (knots equivalent airspeed). This can be shown by setting power required = power
available. *[Nicolai & Carichner, p. 479]*

$$\text{Power required} = (\text{Drag})(\text{Velocity})/(\text{Propulsive efficiency}) =
\left(\tfrac{1}{2}\rho C_D S_{Wing}V^2\right)(V)/\eta_{Prop} \tag{6.10}$$

*[Nicolai & Carichner, Eq. (6.10), p. 479 — restated]*

$$\text{Power available} = P_{Solar}\eta_{SC}S_{SC}\sin\theta \tag{18.8}$$

*[Nicolai & Carichner, Eq. (18.8), p. 479 — restated in power-balance form]*

Then assume typical values for the parameters and solve for $V$ as follows:

| Parameter | Value | Note |
|---|---|---|
| Altitude | 60,000 ft | |
| $\rho$ | 0.000224 slug/ft³ | |
| $\theta$ | 90° (optimistic) | |
| $P_{Solar}$ | 120 W/ft² (Fig. 18.6) | |
| $\eta_{SC}$ | 31% | 35% in lab, 31% installed on wing |
| $\eta_{Prop}$ | 0.81 | Motor, propeller and line losses |
| $S_{Wing} = S_{SC}$ | — | Reasonable and it makes the math simpler |
| $C_D$ | 0.0356 | Condor at best loiter condition (see Fig. G.11) |
| Payload and vehicle power | 0 | Not realistic but makes the point |

$V = 177$ ft/sec = 105 knots at 60,000 ft ~ 30 KEAS, and this is the best it can do. *[Nicolai &
Carichner, p. 480]*

The electrical energy available from a solar cell of efficiency 28.7% at Miami, Florida (latitude
$\Phi=+25°46'$), and Moscow ($\Phi=+55°45'$) is shown in Fig. 18.7 for 4 July and 5 January over a 24-hour
period [1,2]. The area under the curves is the total electrical energy per unit area [watt-hours per
square foot (W·h/ft²)] captured by horizontal solar cells during the daylight hours. Notice that Moscow
and Miami have about the same total energy on 4 July even though Moscow is at a much higher latitude —
the reason is that Moscow has more daylight hours than Miami (17 and 14 hours, respectively). This is not
the case on 4 January. *[Nicolai & Carichner, p. 480]*

**Fig. 18.7** — *Comparison of electrical energy available for Miami and Moscow at 60,000 ft* *[Nicolai &
Carichner, Fig. 18.7, p. 481]*. Plot of $P_{elect}$ (W/ft², 0–35) vs. Time (hours, 0–24), with four curves:
"Miami 4 July" (solid, tallest, peak ~33 W/ft² near hour 13, sunrise 6:34/7:08, sunset 20:16), "Moscow 4
July" (thin solid, peak ~26 W/ft², sunrise 4:53, sunset 22:15 — broader/longer daylight), "Miami 4 January"
(dashed, peak ~21 W/ft², sunrise 8:59-ish, sunset ~17:43), "Moscow 4 January" (dash-dot, shortest, peak
~6.5 W/ft², shaded gray fill, shortest daylight window). Inset formula: $P_{elect}=P_{solar}\eta_{SC}
\sin\theta$. Inset table "City / Latitude": Miami +25°46′, Moscow +55°45′; "Solar Cell Efficiency = 28.7%,
Altitude = 60,000 ft." Inset table "Total Energy (area under curve) (W·h/ft²)": Miami 4 July = 270, 4 Jan
= 142; Moscow 4 July = 265, 4 Jan = 28.7.

## §18.8 Sizing Solar-Powered Aircraft (p. 480)

It is time to return to the Solar Snooper, introduced in Chapter 6, and close the design shown in Fig. 6.8
by determining if the wing size $S_W = 2793$ ft² from §6.7 will provide enough solar-cell area to meet the
power required. Then the design can be closed by developing a weight buildup to meet the assumed 4800 lb
takeoff gross weight (TOGW). *[Nicolai & Carichner, p. 480]*

The requirement for the Solar Snooper is to provide 4 weeks of "24/7" intelligence, surveillance, and
reconnaissance (ISR) at 64,000 ft, in midlatitudes during the summer months. The payload is 500 lb, which
requires 1 kW of power. *[Nicolai & Carichner, p. 480]*

The goal is to design a solar-powered aircraft for operation over Miami and Moscow during the 4-week
period starting 7 June and ending 4 July. Trade studies reveal that 4 July is the critical day during the
4-week interval in terms of energy available from the sun (longest distance to sun). *[Nicolai &
Carichner, p. 480]*

The analysis of §6.7 concluded that the total power required to operate at 68 kt at 64,000 ft at
$C_L=1.33$ was a continuous 24 kW. Refer to the electric aircraft data base shown in Table 14.2 and assume
a solar-cell efficiency of 32% (note, these will be multijunction cells and will be expensive). Also,
assume that the energy for nighttime operation will be stored in batteries instead of fuel cells (this is
an important trade study that needs to be conducted and is left as an exercise for the reader). The
baseline round trip efficiency for the batteries is 0.9. However, there are line losses that need to be
considered: first there is a transmission efficiency $\eta_{Trans}=0.98$ going in and coming out of the
battery; then there is a power control switch/step efficiency $\eta_{Switch}=0.90$ going in and coming out
of the battery. Thus, the total round trip efficiency for the battery storage system is
$\eta_{RT} = (0.98)(0.98)(0.9)(0.9)(0.9) = 0.7$. The continuous power that needs to be provided to the
batteries is $24/0.7 = 34.28$ kW for operating at night. The continuous required power loading for the
batteries is $P_{Req} = (34.28)(1000)/(2793) = 12.3$ W/ft², where the solar cell area is assumed to be the
wing surface area. This $P_{Req}$ will be balanced with the available energy collected by the solar cells.
*[Nicolai & Carichner, p. 482]*

Solar cells are assumed to have a laboratory efficiency of 32%. As mentioned, these are multijunction
cells and will be expensive. Each solar cell generates 0.5 volt; the cells are connected together to form
a blanket (typically 36 individual cells are connected together, generating 18 volts DC with a blanket
packing efficiency of ~95%). The blankets are connected together to form a solar array with an array
electronics efficiency of 95%. The solar arrays are glued onto the vehicle surface. If the cells are going
to be in service for long periods, the environment will degrade the cell efficiency by about 1.5% per year
(called *end-of-life efficiency*). The Solar Snooper cells will be in service for only 4 weeks so that this
will not be a concern. Thus, the end-of-life efficiency for the solar cells will be
$(32)(0.95)(0.95) = 28.7\%$. *[Nicolai & Carichner, p. 482]*

The solar cells are put on the upper surface of the wing. However, the cells should not run right to the
leading edge as their heat and contour disturbance will trip the boundary layer to turbulent and limit the
laminar extent of the wing; the cells should start at about 15% chord, where the boundary layer thickness
is large compared with the thickness of the solar cells. Similarly, there is about 5% of the trailing edge
region that is not usable for the solar cells. Common practice initially sizes the horizontal tail to
recover the 20% of the wing area lost for the solar cell installation (note, this initial tail sizing can
be compared with the tail volume coefficient method of Chapter 11 later). Thus, the horizontal tail is
$S_{HT} = 558$ ft² and the solar cell area is assumed to be 2793 ft². This assumption lets us now balance
$P_{req} = 12.3$ W/ft² with the power available $P_{Elect}$ shown in Fig. 18.7. *[Nicolai & Carichner, p.
482]*

This power balance is shown in Fig. 18.8. The total electrical energy available on 4 July over Miami and
Moscow is 270 and 265 W·h/ft² respectively. The total power required by the Solar Snooper is 12.3 W/ft²
continuous over the nighttime period and 8.6 W/ft² continuous during the daytime (the difference is due
to the round trip efficiency of the batteries). *[Nicolai & Carichner, p. 482]*

During the daylight hours of 4 July the aircraft must collect an excess amount of power $A_1$ that equals
the storage power required $(R_1+R_2)$. From Fig. 18.8 the power sizing results are (shown for Moscow):

Over Miami:

$$A_1 - (R_1+R_2) = 167 - 154.6 = 12.4 \text{ W}\cdot\text{h/ft}^2 \ (8\% \text{ margin})$$

Over Moscow:

$$A_1 - (R_1+R_2) = 140 - 127.2 = 12.8 \text{ W}\cdot\text{h/ft}^2 \ (10\% \text{ margin})$$

**Fig. 18.8** — *Diurnal energy balance example for stationkeeping over Moscow* *[Nicolai & Carichner, Fig.
18.8, p. 483]*. Plot of $P_{elect}$ (W/ft², 0–35) vs. Time (hours, 0–24): a bold black "Moscow 4 January"
curve (peak ~27 W/ft² near hour 13, daylight roughly hours 5–21) with the region under it hatched and
labeled "A" (collected solar energy); faint background reference curves "Miami 4 July" and "Moscow 4 July"
(both higher/broader, shown for comparison) and a fainter dashed "Moscow 4 January" curve underneath.
Below a horizontal dashed "Requirement" line at $P_{elect}\approx12.3$ W/ft² (nighttime) stepping down to
~8.6 W/ft² (daytime) are two shaded rectangular regions labeled $R_1$ (left, hours 0–5ish) and $R_2$
(right, hours 21–24) representing the nighttime battery-storage power requirement; annotation "Requirement:
$A \ge R_1+R_2$." Inset text "For Moscow: $A = 265 -$ daytime operation $= 140$ Watt-hr/ft²; $R_1+R_2=127$;
Excess $=140-127=13$." Inset table "Total Energy (area under curve) (Watt-hr/ft²)": Miami 4 July=270, 4
Jan=142; Moscow 4 July=265, 4 Jan=29. Inset formula $P_{elect}=P_{solar}\eta_{SC}\sin\theta$; "Solar Cell
Efficiency = 28.7%, Altitude = 60,000 ft."

Because 4 July is the critical day (least total energy available) there will be excess energy collected
on all other days in the 4-week surveillance period. It is a good idea to carry at least a 10% margin
during the conceptual design phase. A power balance closure for Miami and Moscow has been obtained.
*[Nicolai & Carichner, p. 484]*

The horizontal tail area should be checked by using the tail volume coefficient method of Chapter 11 to
make sure there is adequate static pitch stability. From Table 11.8, $C_{HT} = \ell_{HT}S_{HT}/S_W\bar{c}
= 0.34$ for ISR aircraft. From Fig. 6.8, $\ell_{HT}=41$ ft and $\bar{c}=8$ ft so that $S_{HT}=185$ ft².
Observe that $S_{HT}$ is sized not by static pitch stability but by the required solar cell area by a
factor of 3; this results in a neutral point that is very far aft. Because the center of gravity should be
located slightly forward of the neutral point (a static margin of approximately +5% $\bar{c}$ as discussed
in Chapter 22) to minimize trim drag, the location of the center of gravity can be changed by sliding the
payload pod fore and aft. *[Nicolai & Carichner, p. 484]*

The vertical tail area is determined by static yaw stability using the method of Chapter 11. From Table
11.8, $C_{VT} = \ell_{VT}S_{VT}/S_W b = 0.014$ for ISR aircraft. From Fig. 6.8, $\ell_{VT}=55$ ft and
$b=317$ ft so that $S_{VT}=225$ ft² for the two verticals. *[Nicolai & Carichner, p. 484]*

Now it is time to re-examine the assumed TOGW = 4800 lb. Weight is estimated for electric motors, solar
cells, and batteries using the data from Table 14.2. Estimating the weights of the wing, tails, landing
gear, payload pod, and booms is a real challenge for a $W/S < 5$ lb/ft² aircraft because the historical
data base is almost nonexistent. The wing is the major structural component and its weight is estimated
using Fig. 20.1. Chapter 19 will discuss this dilemma but it will remain a design weakness. The Solar
Snooper weight summary is shown in Table 18.2. *[Nicolai & Carichner, p. 484]*

**Table 18.2** — *Solar Snooper Weight Summary* *[Nicolai & Carichner, Table 18.2, p. 484]*:

| Component | Weight (lb) | Reference |
|---|---|---|
| Wing | 838 | 0.30 lb/ft² (Fig. 20.1) for $W/S=1.72$ |
| Pod and booms | 341 | Sailplane data [3] |
| Motor, propellers, install | 188 | 0.2 kW/lb + 25% install factor (Table 14.2) |
| Solar cells | 279 | 0.1 lb/ft² (Table 14.2) |
| Landing gear | 96 | 2% of TOGW (sailplane data) |
| Tails | 235 | 0.30 lb/ft² (Fig. 20.1) |
| Payload | 575 | Requirement (500 lb) + 15% for installation |
| Batteries | 1524 | 34.3 kW for 12 hr at 3.7 lb/kW (Table 14.2) |
| Battery installation | 230 | 15% installation factor |
| Avionics, actuators | 100 | Double that for Helios |
| Margin | 393 | 8% (should carry at least a 6% margin) |
| **Total** | **4800** | |

An interesting question at this point is "Is there a Solar Snooper design that could operate over Moscow
on 4 January?" It is clear from Fig. 18.8 that the design shown in Fig. 6.8 will not work because the
total available electrical energy of 28.7 W·h/ft² is nowhere close to the required nighttime
$R_1+R_2 = 127.2$ W·h/ft². Thus, the design must change considerably. *[Nicolai & Carichner, p. 485]*

If it is assumed that the daytime continuous $P_{Req} = 1$ W/ft² over ~7 h (or 7 W·h/ft²), then the excess
electrical energy $A_1 = 28.7 - 7 = 21.7$ W·h/ft². The required nighttime energy
$R_1+R_2 = (1)(14)/0.7 = 20$ W·h/ft², which gives a positive power balance with an 8.5% margin — so the
design is "in the ballpark." *[Nicolai & Carichner, p. 485]*

However, the challenge is to decrease the daytime continuous $P_{Req}$ from 8.6 W/ft² for the current
design to 1.0 W/ft² for the new design. Some design changes to consider are the following *[Nicolai &
Carichner, p. 485]*:

- Decrease the payload and aircraft operation power required to 0.5 kW each.
- Decrease the $W/S$ from 1.72 to 1.0 lb/ft². This would increase the wing area (more area for solar
  cells) and decrease the speed to about 90 ft/s. The increase in wing area would increase the TOGW
  (heavier wing and more solar cells) and drag, but the overall impact would be a lower propulsion power
  required.
- Increase the vertical tail area and cover it with solar cells. This would provide more electrical energy
  especially at the low solar elevation angles over Moscow in the winter. The flight path would have to be
  tailored to take advantage of the vertical solar cells.
- Finally, the solar cell efficiency could be increased within reason.

It remains as an exercise for the reader to determine if there is a design that closes. It should be
obvious to the reader that the design of an aircraft powered by hydrocarbon fuels (i.e., gasoline, diesel,
JP-4, etc.) is a much easier challenge than the design of a solar-powered aircraft. This is because the
hydrocarbon-powered aircraft *[Nicolai & Carichner, p. 485]*:

- Is not expected to have an endurance of more than about 3 days (72 hours).
- The size of the required propulsion unit is independent of latitude, time of year, and time of day.
- The size of the wing is independent of latitude, time of year, and time of day.
- If there is a thrust shortfall, get a bigger engine (do not have to resize the whole aircraft).
- And the list goes on!

## §18.9 Piston Engine Sizing—HAARP (p. 486)

From the discussion in Chapter 5 (§5.8) HAARP is required to fly at 100,000 feet and Mach 0.6 (594.7
ft/s). The design information for sizing the piston engine is as follows:

| Parameter | Value |
|---|---|
| TOGW | 16,000 lb |
| Weight at start of cruise | 14,880 lb |
| $L/D$ at start of cruise | 27 |
| Drag at start of cruise | 14,880/27 = 551 lb |
| High-altitude propeller (designed using ISES code): Diameter; RPM; Efficiency $\eta_P$ | 24 ft; 528; 0.85 |
| Power required at start of cruise | (drag)(speed)/550 $\eta_P$ = 700 hp |

Teledyne Continental (TCM) had provided the engines and developed the two-stage turbochargers for the
Boeing Condor. Discussions with TCM centered around their family of geared, liquid-cooled piston engines
and their turbocharger experience. Their GTSIOL-550 piston engine was selected. The engine specifications
were as follows:

| Parameter | Value |
|---|---|
| Takeoff–climb power | 500 hp |
| Continuous cruise maximum power | 375 at BSFC = 0.42 |
| 94% maximum power | 350 at BSFC = 0.40 |
| Number of cylinders | 6 |
| Weights (total = 581 lb): Engine; Ignition and plugs; Exhaust manifold; Starter; Gearbox | 445 lb; 30 lb; 12 lb; 19 lb; 75 lb |

*[Nicolai & Carichner, §18.9, p. 486, citing §5.8, Fig. 5.11]*

Sidebar: *The Lockheed Skunk Works submitted a proposal to NASA Dryden Flight Research Center in 1991 to
build and operate two HAARP aircraft. NASA declined the offer and instead contracted with Aurora Flight
Systems to build the Perseus aircraft (Fig. 18.9). The Perseus B exceeded 60,000 ft in 1998 with a
three-stage turbocharged piston engine.* *[Nicolai & Carichner, p. 486]*

The HAARP configuration shown in Fig. 5.11 is a twin-engine pusher design. The engines are in wing pods.
The propeller arrangement consists of an 8 ft diameter, four-blade propeller for takeoff, landing, and
climb and a 24 ft diameter, two-blade propeller for high altitude. The small propeller would operate all
the time whereas the large propeller would be clutched in at 45,000 ft. The two engines would be operated
at maximum power (500 hp) for climb but throttled back to 94% (350 hp) for cruise at Mach = 0.6 at 100,000
ft.

**Fig. 18.9** — *The Aurora Flight Systems Perseus UAV developed for NASA high altitude ozone measurements*
*[Nicolai & Carichner, Fig. 18.9, p. 487]*. Photograph of the Perseus UAV in flight — a slender high-aspect-
ratio-wing pusher-propeller aircraft with a V-tail/inverted-V empennage, twin boom-mounted tail surfaces,
a slim fuselage pod, and fixed tricycle landing gear, shown banking against a plain sky background.

A structural analysis and design will be conducted for the HAARP wing in Chapter 19 (§19.14). *[Nicolai &
Carichner, p. 487]*

## §18.10 Human-Powered Aircraft—Daedalus (p. 487)

The design of a human-powered aircraft starts with the description and performance of the propulsion
system. The powerplant in this case is the human engine. Yale University investigated the limits of
endurance and the power level of the human powerplant; their research concluded that an endurance-trained
athlete using a specially built recumbent ergometer (essentially a reclined bicycle) could produce a
specific power of 3 W/kg (0.00183 hp/lb) for several hours [4,5]. For peak performance the athlete needed
preloading with glycogen, controlled temperature, and adequate water supply. *[Nicolai & Carichner, p.
487]*

Thus, the available power would be 0.2745 hp for a well-trained 150-lb athlete. *[Nicolai & Carichner, p.
487]*

Because the power available is small the design approach is very similar to that of a solar-powered
aircraft, such as the Perseus shown in Fig. 18.9 and the Solar Snooper discussed in Example 6.7. The
aircraft speed will be low (less than 20 kt) and the wing loading less than 1 lb/ft². *[Nicolai &
Carichner, p. 487]*

Previous human-powered projects have shown that the aircraft is about two-thirds the weight of the pilot.
For our 150-lb pilot the aircraft weight would be about 100 lb. For the human-powered aircraft the payload
is essentially the pilot so that the total aircraft weight would be approximately 250 lb. *[Nicolai &
Carichner, p. 487]*

If analysis methods from the early part of the book are used, then specifications can be estimated for the
human-powered aircraft. Start by assuming the speed to be 12 kt and the propeller efficiency to be 0.85.
The rationale is based upon observations with the Solar Snooper analysis. Then

the drag from the power required Eq. (6.10) is 6.25 lb. This means that the aircraft cruise $L/D$ needs to
be 40. From the Solar Snooper example the aspect ratio would be ~36. *[Nicolai & Carichner, p. 488]*

The altitude will be less than 500 ft above ground level (AGL) because the aircraft would like to take
advantage of ground effects. This gives us a Reynolds number per foot $\rho V/\nu = 127{,}300$ per ft. If
the $W/S = 1$ lb/ft², then $S=150$ ft² and the wing span = 73.5 ft. The average chord is 2.0 ft and the
$Re=260{,}000$. The cruise $C_L = W/qS = 1.0/0.48 = 2.1$ for the $W/S=1.0$ lb/ft²; this is much too high
for current low-$Re$ airfoils [6]. Because the aircraft cannot fly any faster than ~20 ft/s the $q$ is
fixed at 0.48 lb/ft². A cruise $C_L=1.0$ is more realistic. Thus, the wing loading needs to decrease to
about 0.5 lb/ft² and the wing area increase to 300 ft². Holding the aspect ratio constant gives a wing span
of 104 ft. This is a good trade as it gives us a slightly larger average chord of 2.9 ft and a wing
$Re=368{,}000$. *[Nicolai & Carichner, p. 488]*

The design specifications for our human-powered aircraft are as follows:

| Parameter | Value |
|---|---|
| Power available | 0.2745 hp |
| Pilot weight | 150 lb |
| Aircraft weight | 100 lb |
| Cruise speed | 12 kt |
| Propeller efficiency | 0.85 |
| Cruise $L/D$ | 40 |
| Wing aspect ratio | 36 |
| Wing span | 104 ft |
| Wing average chord | 2.9 ft |
| Wing area | 300 ft² |
| Wing Re | 368,000 |

Readers are now requested to read the Daedalus case study in Volume 2. They should recognize the Daedalus
specifications as being very similar to the preceding estimates; the case study will add substance and
realism to the design analysis in this section. *[Nicolai & Carichner, p. 488]*

Fig. 18.10 shows the human-powered Daedalus at sunrise, at the start of its 3 h 54 min historic flight
across the Sea of Crete on 23 April 1988 [7]. The Daedalus case study in Volume 2 was written by Harold
Youngren, the chief engineer on the MIT project. *[Nicolai & Carichner, p. 488]*

## §18.11 Rocket Engine Sizing (p. 488)

Rockets are sized for acceleration and burn-out speed. Acceleration is a function of the $T/W$ of the
rocket. A typical $T/W$ is 1.4–2.0 so that the rocket accelerates quickly through the atmosphere in about
140 seconds. *[Nicolai & Carichner, p. 488]*

The burn-out speed is determined by the amount of fuel carried by the rocket $W_i/W_f$ as given by Eq.
(18.6). The rocket sizing needs to account for the gravity and drag losses as the rocket exits the
atmosphere.

**Fig. 18.10** — *Human-powered Daedalus takes off on its historic flight across the Sea of Crete (courtesy
of Charles O'Rear)* *[Nicolai & Carichner, Fig. 18.10, p. 489]*. Photograph of the Daedalus human-powered
aircraft at sunrise/backlit takeoff: an extremely slender, very high-aspect-ratio wing, a small enclosed
fuselage pod with the pilot visible pedaling inside (illuminated from within), a pusher propeller at the
nose, and a T-tail empennage on a boom aft of the fuselage.

Sidebar: *The Daedalus was a project undertaken by the MIT Department of Aeronautics and Astronautics in
1985 to recreate the mythical escape of Daedalus from his tower cell on the island of Crete, across the
Sea of Crete to the island of Santorini—a distance of almost 65 n mile [7]. According to Greek mythology
Daedalus and his son Icarus escaped from their cell by gluing bird feathers onto their bodies with wax.
Icarus flew too close to the sun and the wax melted, causing Icarus to plummet to his death. The older
and wiser Daedalus stayed a safe distance from the sun and flew to freedom.* *[Nicolai & Carichner, p.
489]*

Gravity losses are insignificant for aircraft but significant for rockets as they usually are boosting
vertically until outside of the atmosphere. Similarly the drag losses are small for a rocket because they
accelerate through the atmosphere quickly. Instead of correcting the rocket $I_{sp}$ for these losses as
was done for jet aircraft in Eq. (18.7), the $\Delta V$ will be increased to account for drag and gravity
losses. *[Nicolai & Carichner, p. 489]*

A low earth orbit (LEO) is defined as an orbit outside of the earth's atmosphere where orbital decay of
the spacecraft due to drag is not a problem. The edge of the atmosphere is approximately 90 miles up from
the earth's surface. The outer limit for a LEO is below the inner Van Allen radiation belt (about 1088 n
mile). A geosynchronous orbit (GEO) is an orbit where a spacecraft would appear stationary over a point on
the surface of the earth (would have a period of 24 h). A GEO orbital altitude would be 19,468 n mile above
the earth's surface. *[Nicolai & Carichner, p. 489]*

### Example 18.3 — Rocket Sizing for a Low Earth Orbit (p. 489)

Size a rocket to put 1000 lb of payload into a 500,000 ft (82 n mile) LEO. The speed of the rocket at
500,000 ft needs to be 25,638 ft/s tangent to the curve of the earth, balancing the centrifugal and
gravitational forces. If the orbital direction is to the east at latitude $\Phi°$, the rocket will get a
$\Delta V$ boost of $1520\cos\Phi$ ft/s due to the earth's rotation. If launching to the west, the rocket
has to increase its $\Delta V$ by the amount $1520\cos\Phi$ ft/s. *[Nicolai & Carichner, p. 490]*

Assume the following launch conditions:

| Parameter | Value |
|---|---|
| Launch location | Cape Canaveral, Florida ($\Phi=26°$ latitude) |
| Launch direction | east |
| Earth rotation speed | 1366 ft/s ($1520\cos\Phi$) |
| Gravity losses during boost | 3100 ft/s |
| Drag losses during boost | 1200 ft/s |
| Rocket $I_{sp}$ | 330 s (kerosene/O₂) |

The $\Delta V$ required from the rocket is $\Delta V = 25{,}638 - 1366 + 3100 + 1200 = 28{,}572$ ft/s.
*[Nicolai & Carichner, p. 490]*

The rocket weight fraction using Eq. (18.6) is:

$$W_i/W_f = \exp\left[\Delta V/gI_{sp}\right] = 14.7$$

which means that the payload, structure, and motor comprise 7% of the rocket and the fuel the remaining
93%. For a launch weight of 200,000 lb and a payload of 1000 lb, the fuel weighs 186,000 lb, leaving
13,000 lb for structure and motor. Fortunately, the motors are light (liquid propellant rockets have
$T/W_{Motor} \sim 55$, and solid rockets are even better) and the structure is mostly a fuel tank. Using
the $T/W$ of 1.4–2.0 gives a rocket thrust of 280,000–400,000 lb. *[Nicolai & Carichner, p. 490]*

### References (p. 490)

[1] Youngblood, J. W., and Talay, T. A. "Solar Powered Airplane Design for Long Endurance, High Altitude
Flight," AIAA Paper AIAA-82-0811, 18 May 1982.
[2] Youngblood, J. W., Talay, T. A., and Pegg, R. J., "Design of Long Endurance Unmanned Airplanes
Incorporating Solar and Fuel Cell Propulsion," AIAA Paper AIAA-84–1430, 13 June 1984.
[3] Stender, W., "Sailplane Weight Estimation," OSTIV (International Scientific and Technical Gliding
Organization), Elstree-Wassenaar, The Netherlands, 1969.
[4] Wierwille, W. W., "Physiological Measures of Aircrew Workload," *Human Factors*, Vol. 21, No. 5, 1979,
pp. 575–593.
[5] Nadel, E. R., "Physiological Adaptations to Aerobic Training," *American Scientist*, Vol. 73,
July–Aug. 1985.
[6] Drela, M., "Low Reynolds Number Airfoil Design for the MIT Daedalus Prototype: A Case Study," *Journal
of Aircraft*, Vol. 25, No. 6, 1988, pp. 724–732.
[7] Lloyd, P., "Man's Greatest Flight," *Aeromodeller Magazine*, Aug. 1988 (Argus Specialist Publ.,
London).

Chapter 18 extraction complete.
