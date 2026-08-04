# Chapter 23 — Control Surface Sizing Criteria

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, printed
pp. 613–624 (PDF pp. 622–633). Page offset: PDF page = printed page + 9 (consistent with Ch. 20-22).

Text-layer inventory: Figs 23.1-23.6 (no sub-parts detected by regex); Tables 23.1-23.3; Eqs 23.1-23.3
(no sub-parts detected by regex — likely undercounts given prior chapters' dense unnumbered-equation
content; will confirm during transcription).

## Chapter Opener (p. 613)

Photo of two Canada geese coming in for a landing, wings flared, legs extended, in a high-angle-of-attack
low-speed configuration. Caption *(paraphrased)*: praises Mother Nature as "the ultimate designer" for
superbly sizing the geese's control surfaces for this high-AoA, low-speed, low-power approach condition,
adding wryly that it's too bad she didn't write a design text.

Section-list sidebar: Typical Values for S&C; Recommended $C_{M\alpha}$ Values; Lateral Control Spin
Parameter; Recommended $C_{n\beta}$ Values; $C_{n\beta}$ Dynamic; C.G. Travel; Aileron Sizing Criteria.

Epigraph: "If it looks good, it flies good." — Clarence "Kelly" Johnson.

Copyright notice: Copyright © 2010 American Institute of Aeronautics and Astronautics.

## §23.1 Government Regulations Require Static Stability (p. 614)

The Federal Aviation Regulations, Parts 23 and 25 [1] are more abbreviated and qualitative than
MIL-HDBK-1797 with regard to stability and control requirements and handling qualities. The FARs require
the aircraft to be stable in the longitudinal, directional, and lateral modes. The civilian regulations in
their current form do not contain guidelines that are sufficiently detailed for use in design.

Both MIL-HDBK-1797 and FAR Parts 23 and 25 require that the elevator fixed neutral point be aft of the
center of gravity for all loading conditions for aft tail configurations. This insures that

$$C_{M\alpha} < 0$$
*(unnumbered inequality, p. 614)*

for all c.g. positions. It is interesting to note that the British Civil Airworthiness Requirements
[2, Paragraph 2.1] specify a maximum allowable negative stick fixed static margin of -0.05.

Both MIL-HDBK-1797 and FAR Parts 23 and 25 require static directional stability, that is,

$$C_{n\beta} > 0$$
*(unnumbered inequality, p. 614)*

in terms of characteristics involving rudder position and rudder force.

*Roll damping* is an important handling-qualities parameter, particularly in roll maneuvers and in Dutch
roll. The government regulations do not specify minimum values for the roll damping derivative $C_{\ell_p}$
directly. However, to meet the roll-handling requirements of [3,4] it is necessary that

$$C_{\ell_p} < 0$$
*(unnumbered inequality, p. 614)*

Similarly, the government regulations do not give minimum values for the pitch-damping derivative
$C_{Mq}$. However, to meet the short-period damping requirement of [5] it is necessary that

$$C_{Mq} < 0$$
*(unnumbered inequality, p. 614)*

MIL-HDBK-1797 requires that left aileron force be generated for left sideslip. For conventional control
arrangements this can be shown to imply that the lateral stability parameter

$$C_{\ell\beta} < 0$$
*(unnumbered inequality, p. 614)*

This condition is also necessary to keep the spiral mode from being divergent.

Over the years, all of the aircraft companies have developed their own flying-qualities criteria to
supplement the government regulations. These criteria are reflected in the stability and control
characteristics of the current inventory of aircraft. Table 23.1 lists the static stability and control
characteristics of a representative small general aviation aircraft, FAR 23 business jet, FAR 25
transport, and a fighter-class aircraft.

**Table 23.1** — *Typical Aircraft Stability and Control Data* *[Nicolai & Carichner, Table 23.1, p. 615]*.
Columns: Learjet, B-727, T-38, Cherokee 180 Archer. Rows: Takeoff weight (lb) — 13,500 / 152,000 / 11,250 /
2450; Empty weight (lb) — 7,252 / 88,000 / 7,370 / 1390; Wing area (ft²) — 232 / 1,560 / 170 / 156; Span
(ft) — 34.2 / 106 / 25.25 / 30; Aspect ratio — 5.02 / 7.2 / 3.75 / 5.71; Wing sweep c/4 (deg) — 0 / 35 / 24
/ 0; mac (ft) — 7.04 / 15 / 7.73 / 5.25; Vertical tail area (ft²) — 37.4 / 15,356 / 7.73 / 11.4 (the B-727
value appears as printed, "15,356," in the source table — flagged as an apparent order-of-magnitude/typo
inconsistency relative to the other columns, transcribed verbatim); Horizontal tail area (ft²) — 54.0 / 376
/ 59.0 / 25; "Derivatives at Mach = 0.8" header row (Cherokee column instead reads "At Mach = 0.19");
C.G. location (% mac) — 32 / 25 / 19 / 19; $C_{M_0}$ — 0.06 / -0.042 / — / -0.07; $C_{L\delta_e}$ (per
radian) — 0.6 / 0.4 / — / —; $C_{M\alpha}$ (per radian) — -0.7 / -1.5 / -0.16 / -0.32; $C_{M\delta_e}$ (per
radian) — -1.6 / -1.3 / -0.13 / -1.1; $C_{L\delta_a}$ (per radian) — 0.015 / — / — / —; $C_{L\delta_r}$ at
$C_L=1.1$ (per radian) — 0.007 / 0.017 / — / (blank); $C_{n\beta}$ (per radian) — 0.12 / 0.08 / 0.28 /
0.092; $C_{n\delta_r}$ (per radian) — -0.074 / -0.098 / — / -0.06; $C_{Mq}$ (per radian) — -14 / -24 / -8.4
/ -12; $C_{\ell_p}$ (per radian) — -0.5 / -0.30 / -0.35 / -0.47; $C_{\ell\beta}$ (per radian) — -0.1 / -0.13
/ -0.075 / -0.107; $I_{xx}$ ($10^4$ slug·ft²) — 3 / 92 / 1.48 / 0.107; $I_{yy}$ ($10^4$ slug·ft²) — 1.9 /
300 / 2.82 / 0.1249; $I_{zz}$ ($10^4$ slug·ft²) — 5 / 380 / 2.9 / 0.2312.

## §23.2 Center of Gravity Location (p. 615)

The designer should not leave the c.g. location to chance, but rather force its location by judicious
placement of components, including the wing. The c.g. is the most important element in the stability and
control of an aircraft. It should be located so that the tail size (if it has a tail) is not unduly large
and the trim drags are acceptable.

Current regulations require a statically stable aircraft, $C_{M\alpha}<0$. Figure 23.1 shows some
recommended $C_{M\alpha}$ values for general aviation, FAR 23 business jet, FAR 25 transport, and fighter
aircraft. Transport aircraft should be more stable than fighters because of the comfort of the passengers.
Fighter aircraft on the other hand need lower values of $C_{M\alpha}$ because of their maneuverability
requirements. A good rule of thumb is an SM of +4% to +7% for transport aircraft and neutral to +3% for
fighter aircraft. Larger static margins lead to trim drags that become intolerable. The recommended curves
of $C_{M\alpha}$ on Fig. 23.1 are based on this range of SM and the expression

$$C_{M\alpha} = -(\text{SM})(C_{L\alpha})_{WB} \tag{23.1}$$
*[Nicolai & Carichner, Eq. (23.1), p. 616]*

At this point the designer has a wing-body configuration and thus the wing-body a.c. location can be
determined (Fig. 21.3). The usual aft tail or canard will move the n.p. about 5% mac behind or ahead of the
a.c., respectively (Table 23.2). If an SM of +5% mac is desired, c.g. locations can be determined using
Eq. (22.1).

$$\text{SM} = (x_{n.p.} - x_{c.g.})/\bar{c} \tag{22.1}$$
*[Nicolai & Carichner, Eq. (22.1), p. 616 — repeated from Chapter 22]*

**Fig. 23.1** — *$C_{M\alpha}$ values for current aircraft* *[Nicolai & Carichner, Fig. 23.1, p. 616]*.
Chart of $C_{M\alpha}$ (per radian, y-axis 0 to -2.0, inverted so more-negative is up) vs Mach Number
(0-3.0), with three "Recommended" boundary curves labeled "FAR 25 Aircraft" (topmost, most negative,
~-1.2 to -1.7 per radian, peaking near Mach 1), "FAR 23 Aircraft" (middle, ~-0.35 to -0.9 per radian,
peaking near Mach 1), and "Fighter, AR<4" (bottom, ~-0.15 to -0.3 per radian, peaking near Mach 1, then
decaying toward ~0 by Mach 3) — two arrows labeled "Recommended" point from a shared label to the FAR 25
and Fighter curves. Ten numbered data points scattered near Mach 0.25-0.85 corresponding to a legend table
of "Number / Aircraft / C.G. (%mac)": 1 Cessna 182 (26), 2 Cessna 172 (26), 3 B-727 (25), 4 Learjet (32),
5 T-38 (19), 6 B-707-320 (28), 7 C-141 (27), 8 C-5 (33), 9 F-4D (30), 10 B-747 (29). Points 1-2 near
$C_{M\alpha}\approx-0.7$ to $-0.85$ (below FAR 23 curve); points 3,6,8,10 near $-1.2$ to $-1.6$ (near/above
FAR 25 curve); point 4 near $-0.65$; point 7 near $-0.85$; points 5,9 near $-0.05$ to $-0.15$ (near Fighter
curve).

**Table 23.2** — *Approximate N.P. and C.G. Locations* *[Nicolai & Carichner, Table 23.2, p. 617]*.
Two sub-tables. "Subsonic: Assume A.C. at 35% mac" — Type / Approximate N.P. Location (% mac) / Approximate
C.G. Location (% mac): Aft tail 40 / 35; Tailless 35 / 30; Canard 30 / 25. "Supersonic: Assume A.C. at 50%
mac" — Aft tail 55 / 50; Tailless 50 / 45; Canard 45 / 40.

The c.g. moves around as fuel is burned, ordnance expended, cargo or passengers unloaded and loaded, and
so on. The c.g. travel must be watched very closely as it can be costly in terms of excessive trim drag and
aircraft safety-of-flight. The designer must allow for all possible c.g. locations, which may require
system events (such as fuel transfer) so that the c.g. shift is within tolerable limits. Usually a c.g.
shift of less than 10% mac for subsonic aircraft is tolerable; however, it varies from aircraft to
aircraft. If the aircraft is scheduled to spend much of its mission at supersonic speeds, there should be
some provision for shifting the c.g. aft (such as fuel sequencing) to follow the a.c. shift and keep the SM
at a desired level.

Fuel sequencing or transfer is imperative for most aircraft. Here the fuel is located in fuel tanks
distributed throughout the fuselage and wing. Fuel is then taken from these tanks in a definite schedule so
that fuel is transferred from tank to tank to keep the c.g. located properly. Fuel is also sequenced so
that when the weapons are dropped the c.g. shift is within limits. Figure 23.2 shows an example of this
scheduling for the Boeing/McDonnell F-4D. This part of the preliminary design is not easy but it is
essential to keep the c.g. shift within acceptable limits; otherwise performance benefits of the aircraft
can be negated by excessive trim drags.

Finally, the aircraft should be unloaded completely ahead of the c.g. to insure that the aircraft does not
fall back on its tail. Aircraft can, as a last resort, have a placard that dictates the load distribution
while it is parked.

The designer should try very hard to get the c.g. close to the predetermined location. Payload,
subsystems, and fuel can be shifted around, within fuselage constraints, to locate the c.g. at a desired
position. Shifting the wing back and forth has a large effect on c.g. location because the

**Fig. 23.2** — *Center of gravity travel due to fuel consumption, "potato curve" (F-4D)* *[Nicolai &
Carichner, Fig. 23.2, p. 618]*. Chart of Gross Weight (1000 lb, y-axis 28-56) vs C.G. (%mac, x-axis 24-36),
tracing the aircraft's fuel-burn/store-release sequence from takeoff down to landing weight as a connected
path of dots, annotated at each segment: starting at "Cell 1 feeding" (~31%mac, 34,000 lb) up through
"Fuselage cell 2 transferring and cell 1 feeding," "Fuselage cells 3&4 transferring," "Internal wing fuel
transferring," a branch point where the path splits into "Without tank 5&6 lockout" (solid, continuing up
through "Fire SUU-23," "Fire LAU-3/A," "Fire SUU-21," "Internal wing tanks and cells 5&6 transferring,"
"External wing fuel transferring during cruise," "External wing fuel transferring during climb," up to
"Engine Start" at "Full internal fuel / Full 370 gallon wing tanks" ~34%mac, 52,000 lb) and "With tank 5&6
lockout" (dashed, a alternate leftward branch through "External wing tanks transferring," "External wing
tanks and fuselage cells 5&6 transferring," rejoining near "1500 lb fuselage cells 3,4,5,6 transferring"
around 32%mac/50,000 lb). Configuration note box: (2) 370 gallon wing tanks (retained); (1) LAU-3/A rocket
pod (station 2); (1) SUU-21 loaded dispenser (station 8); (1) SUU-23 gun pod (station 5); no fuselage
missiles.

mac and a.c. move directly. Shifting the wing should be considered as a last resort because of its effect
on inlet location and area-ruling.

## §23.3 Sizing the Horizontal Surface (p. 618)

The horizontal surface (aft tail or canard) is used for longitudinal stability and control. The designer
should recognize at this point that stability and control are two independent functions. The horizontal
surface is sized separately for each and the larger of the areas selected.

The designer should locate the horizontal surface on the aircraft and estimate a general planform shape
(i.e., aspect ratio, taper ratio, and sweep).

#### §23.3.1 Static Longitudinal Stability (p. 619)

The desired level of stability, $C_{M\alpha}$, is determined from Fig. 23.1, and then Eq. (21.4) or
(21.5) is used to solve for $S_T$ or $S_C$. Several Mach numbers should be examined and the largest area
for all design conditions is then selected.

#### §23.3.2 Longitudinal Control (p. 619)

The horizontal surface is now sized for adequate longitudinal control. The horizontal control surface can
be an elevator (with deflection $\delta_e$), an all flying stabilizer (with control surface
angle-of-attack $\alpha_{cs}$), or an all flying canard (with canard angle-of-attack $\alpha_c$). The
$\delta_e$, $\alpha_{cs}$, or $\alpha_c$ is usually limited to about $\pm20$ deg.

There are several critical conditions for longitudinal control that should be examined:

1. **Trim drag.** The trim drag during cruise should be less than 10% of the total aircraft drag. Many
   designers reduce this limit to 5% for range-dominated vehicles.
2. **High-g maneuver.** If the aircraft is a fighter, the horizontal control surface should be checked to
   insure that there is sufficient control power to trim the high-g condition.
3. **Takeoff rotation.** The takeoff rotation to climb $C_L$ (see Chapter 10) should be checked. The
   horizontal control surface must have enough control power to rotate the aircraft about the main landing
   gear to the takeoff attitude. This problem is shown schematically in Fig. 23.3. Attention paid to the
   recommended angle between the center of

**Fig. 23.3** — *Takeoff control schematic* *[Nicolai & Carichner, Fig. 23.3, p. 619]*. Side-view schematic
of an F-35-like fighter on its landing gear at the start of takeoff roll, with force vectors: freestream
arrow at the nose pointing aft (relative wind); "Lift" arrow pointing up near the c.g.; "Tail Load" arrow
pointing down at the horizontal tail; "Weight" arrow pointing down through the c.g.; "Nose Gear Load" and
"Main Gear Load" arrows pointing up at the respective gear contact points; "Rolling Friction" arrow at the
main gear pointing aft.

gravity and the main gear wheel as shown in Table 8.5 will insure that the size of the horizontal tail
will be acceptable.

4. **High $\alpha$, low speed.** The condition of low-speed approach for landing with power at idle, flaps
   down, and high angle-of-attack is often a critical condition for sizing control surfaces. This condition
   often determines the most forward c.g. position as shown in Figs. 22.3 and 22.4. Ground effects must be
   considered as this condition increases the aircraft stability and compounds the control problem.

## §23.4 Sizing the Vertical Tail (p. 620)

#### §23.4.1 Static Directional Stability (p. 620)

The vertical tail is sized to give adequate static directional stability. Desired values of $C_{n\beta}$
are put into Eq. (21.20) and the vertical tail area, $S_{VT}$, is determined. Figure 23.4 gives some
recommended values for $C_{n\beta}$.

#### §23.4.2 Fighter Aircraft Spin Resistance (p. 620)

The degree of susceptibility to spin during hard turns with and without rolling inputs has a significant
impact on the dogfighting capability of air superiority aircraft. Reference [5] reports two simple
parameters that have been related to spin resistance margin and provide a good approximation of the
relative resistance of aircraft to spin departure.

**Fig. 23.4** — *Recommended $C_{n\beta}$ values* *[Nicolai & Carichner, Fig. 23.4, p. 620]*. Chart of
$C_{n\beta}$ (per radian, y-axis 0-0.4) vs Mach Number (x-axis 0-3.0), with a "Recommended (NASA TN D-423)"
boundary curve rising from ~0.10 at Mach 0 to a peak of ~0.29 near Mach 1.1, then falling off to ~0.05 by
Mach 3.0. Real-aircraft data points plotted below/near the curve *(read from plot)*: T-38 at
Mach~0.8/$C_{n\beta}\approx0.29$ (above the curve); F-4D at Mach~0.6/$\approx0.14$ and a second F-4D at
Mach~1.7/$\approx0.13$; B-747 at Mach~0.85/$\approx0.19$; Learjet at Mach~0.8/$\approx0.13$; B-727 at
Mach~0.8/$\approx0.08$ (below the curve).

**Fig. 23.5** — *Measure of spin resistance (turning without rolling)* *[Nicolai & Carichner, Fig. 23.5,
p. 621]*. Chart of Dynamic Directional Stability $C_{n\beta_{DYN}}$ ("(+)" above zero, "(-)" below zero,
y-axis) vs the ratio Angle-of-Attack / Max Trim Angle-of-Attack (x-axis, marked at 1.0), showing two curves
both starting from the same positive y-intercept: "High Resistance" — rises further to a broad peak past
x=1.0 before curving down steeply, staying positive across nearly the whole range shown; "Low Resistance"
— declines steadily, crossing zero (marked with an open circle) at roughly x=0.6-0.7 and continuing
negative beyond. A double-headed vertical arrow to the right labels the upper (positive) region "STABLE"
and the lower (negative) region "UNSTABLE SPIN PRONE."

The angle-of-attack region of spin susceptibility for nonrolling turning maneuvers without lateral or
directional inputs has been correlated with the dynamic directional stability parameter

$$C_{n\beta_{dyn}} = C_{n\beta} - C_{\ell\beta}\frac{I_{zz}}{I_{xx}}\tan\alpha \tag{23.2}$$
*[Nicolai & Carichner, Eq. (23.2), p. 621]*

Figure 20.2 can be used to estimate the moments of inertia $I_{xx}$ and $I_{zz}$. Unless the
$C_{n\beta_{dyn}}$ is positive throughout the possible operating angle-of-attack range as illustrated in
Fig. 23.5, the aircraft will be susceptible to spin in hard nonrolling turns.

For assessing the spin susceptibility in turning maneuvers where lateral control inputs are introduced,
it has been found that the angle-of-attack at which the roll reverses due to sideslip opposing the aileron
correlates very closely with the region of spin susceptibility of a number of current fighter aircraft.
The dominant parameters influencing roll reversal are the yaw due to aileron $C_{n\delta_a}$ and the
directional stability $C_{n\beta}$.

High adverse yaw and low directional stability are detrimental. A *lateral control spin parameter* (LCSP)
is defined by

$$\text{LCSP} = C_{n\beta} - C_{\ell\beta}\frac{C_{n\delta_a}}{C_{\ell\delta_a}} \tag{23.3}$$
*[Nicolai & Carichner, Eq. (23.3), p. 621]*

where $C_{\ell\beta}$ and $C_{\ell\delta_a}$ were introduced in Chapter 21 and $C_{n\delta_a}$ can be
estimated from [6] or [7]. Roll reversal occurs at the point where this parameter

**Fig. 23.6** — *Measure of spin resistance (combined turning and rolling maneuvers)* *[Nicolai &
Carichner, Fig. 23.6, p. 622]*. Chart of Lateral Control Spin Parameter ("(+)" above zero, "(-)" below
zero, y-axis) vs Angle-of-Attack / Max Trim Angle-of-Attack (x-axis, marked at 1.0), with the reversal
parameter formula displayed at top right: $\text{LCSP} = C_{n\beta} - C_{\ell\beta}(C_{n\delta_a}/
C_{\ell\delta_a})$. Two curves both starting from the same positive y-intercept: "High Resistance" — rises
to a peak past x=1.0, then falls steeply, crossing zero (marked "Reversal Points," open circle) just past
x=1.0 and continuing negative; "Low Resistance" — declines steadily, crossing zero (also marked with an
open circle, "Reversal Points") at roughly x=0.6-0.7 and continuing negative, more steeply than the High
Resistance curve. A double-headed vertical arrow at right labels the upper region "NORMAL" and the lower
region "REVERSAL SPIN PRONE."

equals zero. Figure 23.6 illustrates the variation of the LCSP vs angle-of-attack normalized to maximum
angle.

#### §23.4.3 Static Directional Control Requirements (p. 622)

The requirements on the rudder for adequate static directional control are as follows:

1. **Crosswind landing.** The rudder must be powerful enough to maintain a straight ground path during
   normal takeoff and landing in 90-deg crosswinds up to velocities of $0.2V_{TO}$. This means adequate
   rudder power to hold a sideslip of $\beta=11.5$ deg at approach speeds. The analysis was discussed in
   Section 21.6.
2. **Antisymmetric power.** The rudder must be powerful enough to hold zero sideslip ($\beta=0$) in
   straight flight at all speeds above $1.2V_{stall}$ with gear down, flaps in best setting, thrust on one
   outboard engine equal to zero (with associated drag), and all other engines developing full thrust.
   This condition was discussed in Section 21.6.
3. **Adverse yaw.** When an airplane is rolled into a turn, yawing moments are often produced that require
   rudder deflection to maintain zero sideslip, that is, coordinate the turn. For example, when initiating
   a roll to the right, aileron deflection may cause yaw to the left. This is termed *adverse yaw* and a
   rudder deflection is required to eliminate the sideslip. Because adverse yaw will be greatest at high
   $C_L$ and full deflection of the ailerons, steep turns at low speed may produce a critical requirement
   for rudder control power.

## §23.5 Sizing the Ailerons (p. 623)

The *lateral control surface* is the aileron. As discussed in Chapter 21, this lateral control surface
has no effect on the lateral stability of the aircraft. The lateral stability derivative is $C_{\ell\beta}$
and is influenced by the wing (independent of the ailerons), the vertical tail, and the wing-fuselage. The
regulations require $C_{\ell\beta}$ to be negative. Typical values are given in Table 23.1.

MIL-HDBK-1797 places all aircraft in one of the following classifications, Class I, Class II, Class III,
Class IVA, Class IVB, or Class IVC:

**Class I** — Small, light airplanes such as:
- Light utility
- Primary trainer
- Light observation

**Class II** — Medium-weight, low-to-medium maneuverability airplanes such as:
- Heavy utility or search and rescue
- Light or medium transport, cargo, or tanker
- Early warning, electronic countermeasures, or airborne command, control, or communications relay
- Antisubmarine
- Assault transport
- Reconnaissance
- Tactical bomber
- Heavy attack
- Trainer for Class II

**Class III** — Large, heavy, low-to-medium maneuverability airplanes such as:
- Heavy transport, cargo, or tanker
- Heavy bomber
- Patrol, early warning, electronic countermeasures, or airborne command, control, or communications relay
- Trainer for Class III

**Class IVA** — High-maneuverability airplanes such as:
- Fighter-interceptor
- Attack
- Tactical reconnaissance
- Observation
- Trainer for Class IV

**Class IVB** — Air-to-air fighter

**Class IVC** — Air-to-ground fighter with external stores

**Table 23.3** — *MIL-HDBK-1797 Roll Requirements* *[Nicolai & Carichner, Table 23.3, p. 624]*. Class /
Roll Performance: I — 600 in 1.3 s; II — 450 in 1.4 s; III — 300 in 1.5 s; IVA — 900 in 1.3 s; IVB — 900 in
1.0 s; IVB — 3600 in 2.8 s (a second IVB row, transcribed verbatim as printed); IVC — 900 in 1.7 s.

The ailerons should be sized to provide the roll performance listed in Table 23.3 for the appropriate
class of aircraft under consideration. The roll rate $P$ in radians per second is given by Eq. (21.17b):

$$P = -\frac{2V}{b}\frac{C_{\ell\delta_a}}{C_{\ell_p}}\delta_a \tag{21.17b}$$
*[Nicolai & Carichner, Eq. (21.17b), p. 624 — repeated from Chapter 21]*

where $V$ is speed in feet per second, $C_{\ell\delta_a}$ is the aileron control power, and $C_{\ell_p}$
is the roll-damping coefficient.

## References (p. 624)

[1] "Airworthiness Standards: Part 23—Normal, Utility and Acrobatic Category Airplanes; Part 25—Transport
Category Airplanes," *Federal Aviation Regulation*, Vol. 3, U.S. Department of Transportation, U.S.
Government Printing Office, Washington, DC, Dec. 1996.
[2] "British Civil Airworthiness Requirements," Sec. D, Air Registration England, 15 Nov. 1991.
[3] "Military Specification—Flying Qualities of Piloted Aircraft," MIL-F-8785C, Nov. 1980.
[4] "Flying Qualities of Piloted Aircraft," MIL-HDBK-1797, Dec. 1997.
[5] Chambers, J. R., and Anglin, E. L., "Analysis of Lateral-Directional Stability Characteristics of a
Twin-Jet Fighter Airplane at High Angles of Attack," NASA TN D-5361, 1969.
[6] Ellison, D. E., "USAF Stability and Control Handbook (DATCOM)," U.S. Air Force Flight Dynamics
Laboratory, Wright-Patterson AFB, OH, Aug. 1968.
[7] Roskam, J., *Flight Dynamics of Rigid and Elastic Airplanes*, Univ. of Kansas, Lawrence, KS, 1972.
[Available via www.darcorp.com (accessed 31 Oct. 2009).]

Chapter 23 extraction complete.

