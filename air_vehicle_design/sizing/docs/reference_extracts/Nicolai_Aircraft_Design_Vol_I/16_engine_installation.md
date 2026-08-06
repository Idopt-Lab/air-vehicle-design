# Chapter 16 — Corrections for Turbine Engine Installation

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, Chapter 16,
printed pp. 413–434 (PDF pp. 423–444).

Text-layer inventory (built before extraction, for completeness checking): Figs 16.1–16.14 (with
sub-labels to be confirmed during extraction); Table 16.1; Eqs (16.1)–(16.21) (including sub-letters
16.11a, 16.11b).

## Chapter opener

Section list: Total Pressure Recovery; Additive or Spillage Drag; Boundary Layer Diverter Drag; Boundary
Layer Bleed Drag; Exit Flap Drag; Bypass Drag; Boattail Drag; Nozzle Types. *[Nicolai & Carichner, p.
413]*

Photo/graph caption: cutaway nacelle graphic overlaid with a plot of Zero Lift Drag $C_{D_0}$ vs. Mach
Number (0–3.2), showing "Measured Drag" and "Predicted Drag" curves with a marked "Drag Increase" region
near Mach 0.9–1.1, and labeled drag-component bands: Skin Friction, Wave Drag (Wind Tunnel), Nacelle
Leakage Drag, Ejector Dimple Drag, Ejector Induced Losses, Aft Fuselage Drag, Nacelle Leakage (Flight
Test). *[Nicolai & Carichner, p. 413]*

Sidebar: *Flight test of the SR-71 revealed a higher transonic $C_{D_0}$ than predicted. Further testing
showed this to be due to nacelle leakage, ejector-induced losses, ejector dimple drag, and aft fuselage
drag. As a result the SR-71 routinely went into a dive maneuver to accelerate past Mach = 1.0.* *[Nicolai
& Carichner, p. 413]*

Chapter epigraph: *"Those who ignore the mistakes of the past are destined to repeat them."* *[Nicolai &
Carichner, p. 413]*

## §16.1 Introduction (p. 414)

Engine thrust data provided by the engine manufacturer is termed *uninstalled* thrust. This uninstalled
thrust data must be corrected by the designer for airframe–engine integration effects. These corrections
to the propulsion system data are of three types *[Nicolai & Carichner, p. 414]*:

1. **Installed engine thrust corrections.** Effects of inlet recovery and distortion, internal nozzle
   performance, engine bleed, and power extraction.
2. **Inlet drag.** Effects of additive drag, cowl drag, boundary layer bleed drag, bypass drag, and
   boundary layer diverter drag.
3. **Nozzle–afterbody drag.** Effects of nozzle–afterbody interference drag.

## §16.2 Total Pressure Recovery (p. 414)

The inlet supplies air to the engine at a certain total pressure recovery schedule, very dependent on the
airframe–inlet design and flight condition. The engine manufacturer determines engine thrust based on a
reference recovery schedule $(P_{0_c}/P_{0_\infty})_{Ref}$. There will be a percentage difference in net
thrust if the designer's inlet does not provide the same ram recovery schedule as that used by the
manufacturer. The correction is *[Nicolai & Carichner, Eq. (16.1), p. 414]*:

$$\text{Percent reduction in thrust} = C_R\left[\left(\frac{P_{0_c}}{P_{0_\infty}}\right)_{Ref} -
\left(\frac{P_{0_c}}{P_{0_\infty}}\right)_{Design}\right] \tag{16.1}$$

where $C_R$ is the *ram recovery correction factor*, a function of engine type, power setting, Mach
number, altitude, and temperature conditions (cold, standard, or hot day). Fig. 16.1 shows typical data
for standard-day, maximum-power operation at 45,000 ft [1] and is recommended for values of $C_R$ at this
point in the design. The engine manufacturer's *reference ram recovery* $(P_{0_c}/P_{0_\infty})_{Ref}$
should be reported in the engine data; sometimes the manufacturer uses a constant recovery schedule of
1.0. Engine data supplied for military application is usually based on a standard military specification
total pressure recovery schedule (MIL-E-5008B Ram Recovery, shown in Fig. 16.2). *[Nicolai & Carichner, p.
414]*

**Fig. 16.1** — *Ram correction factor for net thrust (data from [1])* *[Nicolai & Carichner, Fig. 16.1, p.
415]*. Plot of Ram Correction Factor $C_R$ (0–1.6) vs. Flight Mach Number (0–2.2), with curves for
"Turbojets" (J-79, GE-1, J-85, generally 1.25–1.6, dipping to ~1.23 near Mach 1.6–1.8 then rising again
near Mach 2.0) and "Low-BPR Turbofans" (TF-30 and an unlabeled solid curve, generally 1.15–1.42, declining
more steadily with Mach number).

**Fig. 16.2** — *Mil-Spec total pressure recovery schedule* *[Nicolai & Carichner, Fig. 16.2, p. 415]*.
Plot of $\eta_R$ (0.6–1.0) vs. Flight Mach Number (0–3.0): flat at $\eta_R = 1.0$ from Mach 0 to 1.0, then
declining per the inset formula to $\eta_R \approx 0.80$ at Mach 3.0. Inset formula (unnumbered, MIL-E-5008B):

$$\eta_R = 1 - 0.75(1 - M_\infty)^{1.35}$$

*(unnumbered equation, inset on Fig. 16.2; MIL-E-5008B specification)*

## §16.3 Engine Bleed Requirements (p. 416)

*Airbleed* requirements (environmental control system, anti-icing, boundary layer control, etc.) from the
engine compressor reduce engine thrust. This thrust reduction is estimated from *[Nicolai & Carichner, Eq.
(16.2), p. 416]*:

$$\text{Percent reduction in thrust} = C_B\left(\frac{\dot{m}_B}{\dot{m}_E}\right) \tag{16.2}$$

where $\dot{m}_B$ is the bleed mass flow from the engine and $\dot{m}_E$ is the engine demand mass flow.
The bleed correction factor $C_B$ may be assumed equal to 2.0 for design purposes. This bleed requirement
is not to be confused with the secondary airflow requirement $\dot{m}_S$ discussed in §15.7 (Table 15.1).
The engine bleed $\dot{m}_B$ seldom exceeds 5% as it has a significant effect on thrust. *[Nicolai &
Carichner, p. 416]*

## §16.4 Inlet Flow Distortion (p. 416)

Inlet flow distortion is actually a velocity distortion, but has typically been expressed in terms of
total pressure variations for simplicity. The most apparent effect of flow distortion on a turbine engine
is a downward shift of the engine surge line [2], due primarily to many compressor blades operating
closer to stall in the distorted flow. If the distortion is sufficient to alter the blades' effective
angles-of-attack, operating-line efficiency changes so the distortion results in a shift along the engine
operation line to a lower operating pressure. If surge-margin loss due to flow distortion is greater than
anticipated, the engine may need to be derated to allow sufficient margin for engine transients. The
primary effect of inlet turbulence is to drop the surge line even closer to the operating line [1,2].
*[Nicolai & Carichner, p. 416]*

## §16.5 Inlet Drag (p. 416)

Inlet drag is usually defined as all drag associated with the captured streamtube of air and its
variations with engine demand and/or aircraft operating conditions. Inlet drag is the responsibility of
the propulsion group; the Chief Designer must check drag bookkeeping to ensure the airframe and propulsion
groups together account for all aircraft drag without double-bookkeeping. The elements of inlet drag are
shown in Fig. 16.3. *Additive drag* is the momentum loss of the streamtube of air defined by the capture
area $A_c$ that is diverted around the inlet; some of this lost momentum may be recovered in lip suction as
the diverted flow accelerates over the cowl, creating a low-pressure region that acts in the thrust
direction — so cowl drag is not really a drag but a thrust force instead. Skin friction drag over the
remainder of the inlet external surface, nacelle, or fuselage section is not charged as inlet drag but
rather airframe drag, accounted for by the airframe group. *[Nicolai & Carichner, pp. 416–417]*

**Fig. 16.3** — *Elements of inlet drag* *[Nicolai & Carichner, Fig. 16.3, p. 417]*. Side-view schematic of
a 2D external-compression inlet showing: freestream capture area $A_\infty$ and Mach $M_\infty$ approaching
an oblique-shock compression surface; *Additive Drag* labeled ahead of the cowl lip; cowl capture area
$A_C$ and throat area $A_T$; *Cowl Drag* labeled on the external cowl surface; a *Boundary Layer Diverter*
below the compression ramp with diverter length $L_{BLD}$, diverter height $\delta_T$, and offset
$Y_{BLD}$; internal *Boundary Layer Bleed* ducting from the ramp to a *Bleed* exit at angle $\theta_{BLB}$;
a *Bypass* exit at angle $\theta_{BP}$ near the engine face.

Boundary layer bleed (BLB) drag and bypass drag are defined as (1) the combination of momentum lost by
these flows from the time they are taken into the inlet until they exit the aircraft, and (2) the exit
door pressure drags. Boundary layer diverter drag (usually included in inlet drag, but someone must
account for it) is the momentum lost in the boundary layer that is turned away by the boundary layer
diverter. These drag elements are discussed in the sections that follow, with methodology for estimating
each; in all cases the drag coefficients are referenced to the cowl area $A_c$. *[Nicolai & Carichner, p.
417]*

## §16.6 Additive (or Spillage) Drag (p. 417)

Additive drag is the momentum loss of the streamtube of air diverted around the inlet. Not all air
captured by the cowl (represented by $A_c$) can enter the inlet, for several reasons — the presence of a
compression surface, and the engine airflow demand being less than the inlet supply — and the extra air is
diverted over the cowl lip. This diverted air can be thought of as being "spilled," so additive drag is
often called *spillage drag*. Additive drag occurs any time $A_\infty/A_c < 1.0$. *[Nicolai & Carichner,
p. 417]*

Additive or spillage drag is made up of two parts, as shown in Fig. 15.16. The first part is called
*compression surface spill* or *critical spill* and is due to the physical turning (deflection) of the
flow streamlines by a compression surface [Fig. 15.7b]; the spilled air involved is the difference in
airflow between $A_c$ and $A_{\infty I}$. This first part of additive drag is always accompanied by
critical or supercritical inlet operation at supersonic Mach numbers.

The second part is called *subcritical spill* and is due to excess air in the inlet (difference between
inlet supply and engine demand) backing up and spilling around the lip, as shown in Fig. 15.7a. If all of
this excess air in the inlet is bypassed, the subcritical spillage drag is zero — so the designer can
choose to trade off bypass drag for subcritical spillage drag. Subcritical spill is also accompanied by a
decrease in pressure recovery, as shown in Fig. 15.8. *[Nicolai & Carichner, p. 418]*

For capture area ratios $A_\infty/A_c$ much less than 1, additive/spillage drag can be appreciable, easily
amounting to 20% of the airplane drag; fortunately in practice this entire penalty is seldom experienced.
Proper contouring of the external cowl lip can produce appreciable lip suction effects from increased
velocities and decreasing pressures on the forward cowl-lip portions, with lip suction able to cancel up
to 80% of the additive drag for subsonic inlets (at subsonic/transonic speeds) and up to 50% for
supersonic inlets [1]. *[Nicolai & Carichner, p. 418]*

Several methods correct additive drag for cowl lip suction. Ref. [3] expresses the corrected additive drag
$C_{D_A}$ as (unnumbered equation, p. 418):

$$C_{D_A} = C_{D_{Add}} - C_{D_{LS}}$$

where $C_{D_{Add}}$ is the theoretical additive drag and $C_{D_{LS}}$ is the lip-suction term. The method
used in this chapter expresses the corrected additive drag as *[Nicolai & Carichner, Eq. (16.3), p. 418]*:

$$C_{D_A} = C_{D_{Add}} K_{Add} \tag{16.3}$$

where $K_{Add}$ (< 1) accounts for cowl effects, from experimental data shown in Fig. 16.4 (data from
[1,3,4]) — a first-order correction recommended for conceptual design; Ref. [3] presents a more refined
method accounting for more inlet lip geometry detail, recommended for preliminary design. Fig. 16.5 shows
the control volume for the theoretical additive drag analysis, where station infinity ($\infty$) is
freestream and station 1 is the entrance to the inlet; the angle $\lambda$ is the flow-velocity angle
through station 1. The same schematic holds for subsonic flow, and the pitot-inlet schematic is similar.
*[Nicolai & Carichner, p. 418]*

**Fig. 16.4** — *Additive drag correction factor for cowl lip suction effects* *[Nicolai & Carichner, Fig.
16.4, p. 419]*. Plot of $K_{Add}$ (0–1.0) vs. $A_\infty/A_C$ (0–1.0), with two curve families: solid
"External compression inlet" curves labeled by $M_\infty$ = 0.6, 0.7, 0.8, 0.9–1.1, 1.2, 1.3, and a
flat-topped $M_\infty > 1.4$ curve (constant near 1.0 dropping off past $A_\infty/A_C \approx 0.65$); dashed
"Pitot inlet with rounded cowl lips" curves labeled $M_\infty$ = 0.6, 0.8, 0.9, 1.1, 1.3 — all curves
generally decrease from left (low $A_\infty/A_C$) toward zero as $A_\infty/A_C \to 1.0$, with higher
$M_\infty$ curves sitting higher (closer to $K_{Add}=1$) across the range.

$A_\infty$ (the capture area of the flow streamtube entering the inlet) is expressed as *[Nicolai &
Carichner, Eq. (16.4), p. 419]*:

$$A_\infty = \frac{\dot{m}_E + \dot{m}_{BP} + \dot{m}_{BLB} + \dot{m}_S}{32.17\,\rho_\infty V_\infty}
\tag{16.4}$$

where the mass flows in the numerator (slugs/s) are engine demand, bypass, boundary layer bleed, and
secondary air, respectively; all other airflow is diverted over the inlet lip, creating additive drag.
*[Nicolai & Carichner, p. 419]*

The additive drag is the summation of pressure forces in the drag direction acting on control-volume
surface $BC$ in Fig. 16.5; this drag force, shown as $D_A$ in Fig. 16.5, is expressed as (using gage
pressures) *[Nicolai & Carichner, p. 419]*.

**Fig. 16.5** — *Schematic of control volume for additive drag analysis* *[Nicolai & Carichner, Fig. 16.5,
p. 419]*. Side-view schematic: freestream station with area $A_\infty$, velocity $V_\infty$, pressure
$P_\infty$; a streamtube boundary $B$–$C$ curving down to the cowl lip at point $C$ (cowl lip angle
$\theta_{CL}$); a compression ramp/wedge below with average surface pressure $\bar{P}_S$; station 1 at the
cowl lip with area $A_1$, velocity $V_1$ (at angle $\lambda$ to the centerline), and pressure $P_1$; the
additive drag force $D_A$ shown acting along the freestream direction from $B$ to $C$.

$$D_A = -\dot{m}_\infty V_\infty - (P_1 - P_\infty)A_\infty + \dot{m}_\infty V_1\cos\lambda +
(P_1 - P_\infty)A_1\cos\lambda + (\bar{P}_S - P_\infty)A_S \tag{16.5}$$

*[Nicolai & Carichner, Eq. (16.5), p. 420]* where $\bar{P}_S$ is the average surface pressure on the ramp
or conical centerbody and $A_S$ is the projected area in the drag direction of the ramp or centerbody
(zero for a pitot inlet). If there is an angle $\alpha$ between the inlet centerline and the freestream,
$D_A$ is multiplied by $\cos\alpha$. *[Nicolai & Carichner, p. 420]*

The additive drag coefficient is *[Nicolai & Carichner, Eq. (16.6), p. 420]*:

$$C_{D_{Add}} = \frac{D_A}{q_\infty A_c} = \left(\frac{P_\infty}{q_\infty}\right)\left(\frac{A_1}{A_c}\right)
\cos\lambda\left[\left(\frac{P_1}{P_\infty}\right)(1+\gamma M_1^2) - 1\right] -
2\left(\frac{A_\infty}{A_c}\right) + \bar{C}_{PS}\left(\frac{A_S}{A_c}\right) \tag{16.6}$$

where *[Nicolai & Carichner, Eq. (16.7), p. 420]*:

$$\bar{C}_{PS} = \frac{\bar{P}_S - P_\infty}{q_\infty} = \frac{2}{\gamma M_\infty^2}\left(\frac{\bar{P}_S}
{P_\infty} - 1\right) \tag{16.7}$$

Everything in Eq. (16.6) is known or can be determined at this point. If the flow is supersonic and the
inlet is operating critically or supercritically (normal shock at or downstream of the throat), then
$M_1 > 1$. $M_1$ and $P_1/P_\infty$ for two-dimensional ramp inlets are determined straightforwardly from
the external shock structure using Fig. E.2. For an axisymmetric inlet with a centerbody, $M_1$ is not
straightforward due to the nonuniform flow region behind a conical shock: obtain the cone surface Mach
number $M_S$ from Fig. E.5 and the cone shock wave angle $\beta$ from Fig. E.3, then determine the Mach
number behind an oblique shock having the same shock wave angle $\beta$ as the conical shock (using Figs.
E.1 and E.2); $M_1$ behind the conical shock is estimated as the average of these two Mach numbers.
*[Nicolai & Carichner, p. 420]*

$$(M_1)_{cone} = 0.5(M_s + M_{1wedge})$$

*(unnumbered equation, p. 420)*

The pressure ratio $P_1/P_\infty$ for an axisymmetric inlet is determined as follows *[Nicolai &
Carichner, Eq. (16.8), p. 420]*:

$$\frac{P_1}{P_\infty} = \left(\frac{P_1}{P_{0_1}}\right)\left(\frac{P_{0_1}}{P_{0_\infty}}\right)
\left(\frac{P_{0_\infty}}{P_\infty}\right) \tag{16.8}$$

where the static-to-total pressure ratios are functions of $M_1$ and $M_\infty$ (from Appendix C) and
$P_{0_1}/P_{0_\infty}$ is determined from *[Nicolai & Carichner, Eq. (16.9), p. 421]*:

$$\left(\frac{P_{0_1}}{P_{0_\infty}}\right) = \left(\frac{P_{0_{th}}}{P_{0_\infty}}\right)
\left(\frac{P_{0_1}}{P_{0_{th}}}\right) \tag{16.9}$$

$P_{0_{th}}$ is from Figs. E.6 and E.7, and $P_{0_1}/P_{0_{th}}$ is the total pressure ratio across a
normal shock (from Appendix D) with upstream Mach number $M_1$. *[Nicolai & Carichner, p. 421]*

If $M_\infty > 1$ but the shock is detached or the inlet is operating subcritically, then $M_1 < 1$; $M_1$
is found as follows *[Nicolai & Carichner, Eq. (16.10), p. 421]*:

$$(A/A^*)_{M_1} = (A/A^*)_{M_\infty}(A_1/A_c)(P_{0_1}/P_{0_\infty})(A_c/A_\infty) \tag{16.10}$$

and $M_1$ is the Mach number for $(A/A^*)_{M_1}$ as found from Appendix C. The pressure ratio $P_1/P_\infty$
is found using Eq. (16.8), where $(P_{0_1}/P_{0_\infty}) = (P_{0_{th}}/P_{0_\infty})$ (unnumbered relation,
p. 421). *[Nicolai & Carichner, p. 421]*

For $M_\infty < 1$, $M_1$ is found as follows *[Nicolai & Carichner, Eq. (16.11a)/(16.11b), p. 421]*:

$$\left(\frac{A_\infty}{A_1}\right) = \frac{(A/A^*)_{M_\infty}}{(A/A^*)_{M_1}} \tag{16.11a}$$

or

$$\left(\frac{A}{A^*}\right)_{M_1} = \frac{(A/A^*)_{M_\infty}}{(A_\infty/A_1)} \tag{16.11b}$$

where $(A/A^*)_{M_\infty}$ is determined for $M_\infty$ from Appendix C and $A_\infty/A_1$ is known from
geometry. $M_1$ is then found as a function of $(A/A^*)_{M_1}$ from Appendix C. The pressure ratio is
*[Nicolai & Carichner, Eq. (16.12), p. 421]*:

$$P_1/P_\infty = (P_1/P_{0_1})/(P_\infty/P_{0_\infty}) \tag{16.12}$$

since $P_{0_1} = P_{0_\infty}$. *[Nicolai & Carichner, p. 421]*

The surface pressure coefficient (averaged for multiple compression surfaces) $\bar{C}_{PS}$ is determined
from Figs. E.2 and E.10 for a ramp surface, and from Figs. E.4 and E.11 for a conical surface. The
theoretical additive drag coefficient is now determined from Eq. (16.6) and corrected for cowl lip effects
using Eq. (16.3) and Fig. 16.4; Ref. [3] is recommended for more refined estimates of $K_{Add}$. The
$C_D$ is referenced to the cowl area $A_c$. *[Nicolai & Carichner, p. 422]*

## §16.7 Boundary Layer Bleed Drag (p. 422)

The methodology presented here (from [4]) estimates the drag produced by the removal and disposal of
boundary layer air from the inlet. This air is normally removed to ensure satisfactory stability and
uniformity of flow at the diffuser exit for good pressure recovery. Fig. 15.11 shows recommended boundary
layer bleed levels; the designer should choose the bleed mass flow after examining the tradeoff between
inlet pressure recovery and boundary layer bleed drag. The *bleed drag* is composed of two parts: (1) the
change of momentum of the bleed air between the bleed system entrance and the exit to the freestream (FS),
and (2) the pressure drag on the exit flap door. *[Nicolai & Carichner, p. 422]*

Symbols and definitions for the methodology *[Nicolai & Carichner, p. 422]*:

| Symbol | Definition |
|---|---|
| $M_\infty$ | freestream Mach number |
| $M_E$ | Mach number at bleed exit |
| $P_{0_E}/P_{0_\infty}$ | total pressure recovery of bleed airflow FS to bleed exit (use Fig. 16.6) |
| $\theta_{BLB}$ | exit angle of bleed air relative to freestream (15 deg or less is desirable) |
| $A_{BLB}/A_c$ | boundary layer bleed mass flow ratio (Fig. 15.11) |
| $A_E$ | bleed nozzle exit area |
| $A_T$ | bleed duct throat area |

A bleed exit discharging at a low $\theta_{BLB}$ into a region of low base pressure is desired — this
provides the highest exit momentum and reduces base drag at the same time. A convergent discharge nozzle
is satisfactory for nozzle pressure ratios up to about 4; at higher pressure ratios a convergent–divergent
nozzle is desired [3]. The methodology presented here is for a convergent nozzle (see [4] for a
convergent–divergent nozzle). The freestream Mach number that gives choked flow in the bleed duct is
determined from *[Nicolai & Carichner, Eq. (16.13), p. 423]*:

$$(M_\infty)_{Ch} = \left[\frac{6}{(P_{0_E}/P_{0_\infty})^{0.286}} - 5\right]^{1/2} \tag{16.13}$$

where $P_{0_E}/P_{0_\infty}$ is determined from Fig. 16.6. Eq. (16.13) is plotted in Fig. 16.7. *[Nicolai &
Carichner, p. 423]*

**Fig. 16.6** — *Total pressure recovery of bleed airflow (data from [4])* *[Nicolai & Carichner, Fig.
16.6, p. 423]*. Plot of $P_{0_E}/P_{0_\infty}$ (0–0.7) vs. Flight Mach Number (0.8–4.4), with three curves:
"Throat Slot Bleed" (dotted, ~0.55 at Mach 1.4 declining to meet the solid curve near Mach 2.2),
"High-Pressure Bleed (porous throat)" (solid, from ~0.64 at Mach 0.8 declining to ~0.24 by Mach 4.4), and
"Low-Pressure Bleed (porous fwd ramp)" (dashed, from ~0.64 at Mach 0.8 declining more steeply to ~0.05 by
Mach 4.4).

### §16.7.1 Choked Flow (p. 423)

If $M_\infty > (M_\infty)_{Ch}$, the nozzle throat is choked, $M_E = M_T = 1.0$, and $P_E = P_\infty$. The
bleed duct throat area is calculated from *[Nicolai & Carichner, Eq. (16.14), p. 423]*:

$$A_T = \frac{(A_{BLB}/A_c)A_c}{(A/A^*)_{M_\infty}(P_{0_E}/P_{0_\infty})} \tag{16.14}$$

where $(A/A^*)_{M_\infty}$ is determined from Appendix C for $M_\infty$. The boundary layer bleed drag
coefficient, $C_{D_{BLB}}$ (referenced to $A_c$), is given by *[Nicolai & Carichner, Eq. (16.15), p. 424]*:

$$C_{D_{BLB}} = 2\left(\frac{A_{BLB}}{A_c}\right)\left(1 - \frac{\cos\theta_{BLB}}{M_\infty}
\sqrt{0.833+0.167M_\infty^2} \times \left\{1.715 - \left[\frac{0.715}{(P_{0_E}/P_{0_\infty})
(0.833+0.167M_\infty^2)^{3.5}}\right]\right\}\right) \tag{16.15}$$

**Fig. 16.7** — *Freestream Mach number for choked flow in bleed and bypass ducts* *[Nicolai & Carichner,
Fig. 16.7, p. 424]*. Plot of Choked Mach No. $(M_\infty)_{ch}$ (1.0–2.2) vs. $P_{0_E}/P_{0_\infty}$
(0–1.0), a single monotonically decreasing curve labeled "Equation 16.13," from $(M_\infty)_{ch} \approx
2.2$ at $P_{0_E}/P_{0_\infty} \approx 0.18$ down to $(M_\infty)_{ch} = 1.0$ at $P_{0_E}/P_{0_\infty} = 1.0$.

### §16.7.2 Unchoked Flow (p. 424)

If $M_\infty < (M_\infty)_{Ch}$, the static-to-total pressure ratio at the duct exit is *[Nicolai &
Carichner, Eq. (16.16), p. 424]*:

$$P_E/P_{0_E} = (P_\infty/P_{0_\infty})/(P_{0_E}/P_{0_\infty}) \tag{16.16}$$

where $P_\infty/P_{0_\infty}$ is determined from Appendix C for $M_\infty$. The Mach number at the exit,
$M_E$, is determined from Appendix C corresponding to $P_E/P_{0_E}$. The duct throat area is given by
*[Nicolai & Carichner, Eq. (16.17), p. 424]*:

$$A_T = \frac{(A_{BLB}/A_c)A_c(A/A^*)_{M_E}}{(A/A^*)_{M_\infty}(P_{0_E}/P_{0_\infty})} \tag{16.17}$$

where the area ratios $A/A^*$ are determined from Appendix C for Mach numbers $M_E$ and $M_\infty$. The
bleed drag coefficient $C_{D_{BLB}}$ (referenced to $A_c$) is determined from *[Nicolai & Carichner, Eq.
(16.18), p. 425]*:

$$C_{D_{BLB}} = 2\left(\frac{A_{BLB}}{A_c}\right)\left(1-\cos\theta_{BLB}\left[\frac{5}{M_\infty^2}+1
\right]^{1/2} \times \left[1 - \frac{1}{(1+0.2M_\infty^2)(P_{0_E}/P_{0_\infty})^{0.286}}\right]\right)
\tag{16.18}$$

### §16.7.3 Exit Flap Drag (p. 425)

If there is a flap-type door over the exit of the boundary layer bleed duct, there will be a pressure drag
on the flap. This *exit flap drag* can be omitted at this point but should be included later as the design
is refined and fine-tuned; the method of [4] is recommended. If the exit is a flush type, there is no flap
drag. *[Nicolai & Carichner, p. 425]*

## §16.8 Bypass Drag (p. 425)

The methodology presented here (from [4]) estimates the drag of airflow that enters the inlet but bypasses
the engine for airflow matching, reduction of additive drag, or internal shock control. The *bypass drag*
is composed of two parts: (1) the change in momentum of the bypass air between the bypass exit and the
freestream, and (2) the pressure drag on the bypass exit flap door. The methodology for a bypass system
with a convergent nozzle is identical to that presented in §16.7 for boundary layer bleed drag, with
values for the bypass system substituted for the bleed values. The total pressure recovery for the bypass
airflow from freestream to bypass exit is approximated by $0.85(P_{0_c}/P_{0_\infty})$. *[Nicolai &
Carichner, p. 425]*

## §16.9 Boundary Layer Diverter Drag (p. 425)

The *boundary layer diverter* is a splitter-plate arrangement that diverts the boundary layer, built up
ahead of the inlet, away from the inlet — reasons for the boundary layer diverter are discussed in §15.5.
A boundary layer diverter is shown in Fig. 16.3 and locates the inlet out of the upstream boundary layer.
The boundary layer diverter height $Y_{BLD}$ should be at least twice the local turbulent boundary layer
thickness, given by *[Nicolai & Carichner, Eq. (16.19), p. 426]*:

$$\delta_T = \frac{0.37x}{Re_x^{0.2}} \tag{16.19}$$

where $x$ = distance from fuselage nose or wing leading edge to the boundary layer diverter, and the
local Reynolds number is *[Nicolai & Carichner, Eq. (16.20), p. 426]*:

$$Re_x = \frac{\rho_\infty V_\infty x}{\mu_\infty} \tag{16.20}$$

The boundary layer diverter is usually a compression ramp surface of flow deflection angle
$\theta_{BLD}$. The drag of the boundary layer diverter is due primarily to the surface pressure on the
compression ramp influenced by the presence of right-angle surfaces. The expression for the boundary
layer drag coefficient (referenced to cowl area $A_c$) is expressed as (from [3]) *[Nicolai & Carichner,
Eq. (16.21), p. 426]*:

$$C_{D_{BLD}} = (C_{D_{BLD}}/2\theta_{BLD})(2.6\theta_{BLD})(A_{BLD}/A_c) \tag{16.21}$$

where the ratio $C_{D_{BLD}}/2\theta_{BLD}$ is obtained from Fig. 16.8, and the distance $L$ in Fig. 16.8
is defined in Fig. 16.3 as $L_{BLD}$. $\theta_{BLD}$ is the diverter compression ramp angle in degrees and
$A_{BLD}$ is the projected surface area of the boundary layer diverter in the flow direction. *[Nicolai &
Carichner, p. 426]*

**Fig. 16.8** — *Boundary layer diverter drag variation with freestream Mach number* *[Nicolai &
Carichner, Fig. 16.8, p. 426]*. Plot of $C_{D_{BLD}}/2\theta_{BLD}$ (0–0.006) vs. $M_\infty$ (0–5), with
three curves for $L/\delta_T = 2, 1, 0$, each rising from 0 at Mach 0 to a peak (~0.0052–0.0062) near
Mach 2, then declining to ~0.0018 by Mach 5; higher $L/\delta_T$ gives a higher peak.

## §16.10 Nozzle–Airframe Interference Effects (p. 427)

A jet exhausting from a nozzle has two effects on the surrounding flow field and hence the aircraft: first,
the jet acts like a solid body (whose size and shape varies with power setting, nozzle setting, Mach
number, and altitude) displacing the external flow; second, it normally entrains mass flow from the
external stream. The jet contour affects the pressure distribution on the afterbody and nearby surfaces,
which, in subsonic flow, transmits a strong upstream influence. In supersonic flight there is limited
upstream influence because any disturbance can only be propagated upstream through the subsonic part of
the boundary layer. The shock system within the jet continues through the jet boundary and may impinge on
nearby surfaces; for aircraft configurations with two or more jet engines, mutual interference becomes
even more complex. The influence of elevated jet-exhaust temperatures is another interference that must be
considered but is not discussed here. *[Nicolai & Carichner, p. 427]*

Computation methods available today are either not sufficiently accurate or fail completely to predict the
complex afterbody flow field [5], particularly in subsonic flow incorporating boundary layer separation
and strong upstream influences; therefore aircraft development relies heavily on wind tunnel tests with
simulated jets. The aim of such jet-effects testing is to obtain information on critical areas of
nozzle–airframe interference; as mentioned in Chapter 1, this configuration fine-tuning in the wind tunnel
is done during the latter part of the preliminary design phase. At this point in the conceptual design
phase only the gross features of the nozzle–airframe configuration are considered. The primary parameters
influencing nozzle–airframe interference are the nozzle type, the boattail angle, the base area, the
nozzle spacing for multiengine aircraft, and the interfairing length between nozzles. *[Nicolai &
Carichner, p. 427]*

### §16.10.1 Nozzle Types (p. 427)

Fig. 16.9 shows typical jet pressure ratios for turbojet and turbofan engines versus flight Mach number
(the turbojet is the upper limit of the band). Two extreme engine operating conditions are shown: for
cruise in the subsonic flight regime the nozzle pressure ratio is low, requiring little or no divergence;
for maximum acceleration (full afterburning) the throat area is increased by a factor of about 2 (depending
on bypass ratio). Required nozzle divergence increases gradually with increasing flight speed, reaching
$A_e/A_t \sim 2.6$ at nozzle pressure ratios of 14. Besides cruise and maximum acceleration, all
intermediate operating conditions are possible (military, partial afterburner), requiring in the ideal
case a fully variable nozzle with independent variation of throat size and divergence; in many practical
cases simpler systems with either purely convergent nozzles or a fixed relation in throat-to-divergence
are chosen as a compromise. *[Nicolai & Carichner, pp. 427–428]*

**Fig. 16.9** — *Required variation of nozzle geometry (data from [5])* *[Nicolai & Carichner, Fig. 16.9,
p. 428]*. Plot of $P_{0jet}/P_\infty$ (0–18) vs. Mach Number (0–2.4), with a shaded band bounded by
"Sea Level" (lower) and "Altitude = 36,000 ft" (upper) trajectories, plus a "Cruise" trough near Mach 0.4–0.6
($A_e/A_t = 1.0$), a "Military" point near Mach 1.0 ($A_e/A_t = 1.3$), and a "Maximum A/B" point near
Mach 2.2 ($A_e/A_t = 1.3$, at the top of the band $A_e/A_t = 2.6$ near the plot's upper right).

Fig. 16.10 shows typical nozzle concepts for afterburning engines. These nozzle types are discussed next
(from [5]) *[Nicolai & Carichner, p. 428]*:

- **Short convergent nozzle.** A mechanically simple, lightweight nozzle; the major aerodynamic
  disadvantage is the larger base in the closed position.
- **Iris-nozzle.** Mechanically more complex; annular bases are avoided in all positions. As with the
  short convergent nozzle, large thrust losses occur at high pressure ratios because no divergence is
  provided.
- **Plug-nozzle.** The necessary variation in throat area is accomplished by variation of the plug
  position or geometry, so a fixed lightweight shroud can be used; large cooling airflows, however, are
  necessary for reheat operation.
- **C–D iris nozzle.** Provides some divergence in the reheat position; variation in throat size and in
  divergence is coupled, making the C–D iris a compromise between the simple iris and a fully variable
  C–D nozzle.
- **Simple ejector.** A frequently chosen nozzle concept; primary and secondary flaps are mechanically
  linked. Relatively large secondary airflows are required, associated with drag penalties.
- **Fully variable ejector.** Near-optimum aerodynamic performance: throat area and divergence are
  independently variable, and required secondary mass flows can be kept low. High weight and complex
  design are associated with this concept.
- **Isentropic ramp.** Difficult to adapt to varying operating conditions, normally resulting in
  undesirable changes in pitching moment.
- **Blow-in-door ejector.** Provides similarly good performance as the ordinary ejector in the reheat
  position. In the closed position, large quantities of tertiary air are taken aboard through
  spring-loaded flaps to fill the large annular base of the short primary nozzle; large air quantities
  require careful handling to avoid losses in the sharp turnings of the secondary/tertiary flow passages.
  This nozzle is a highly integrated concept with respect to merging internal and external flows;
  peripheral nonuniformities (blockage) of the external flow may cause unfavorable interferences,
  particularly with closely spaced twin-jet installations.

**Fig. 16.10** — *Typical nozzle concepts for afterburning engines (upper half of each sketch denotes dry
power; lower half is maximum afterburning) [5]* *[Nicolai & Carichner, Fig. 16.10, p. 429]*. Eight
side-view cutaway schematics, each showing dry-power (upper half) vs. maximum-afterburning (lower half)
flow paths: Short Convergent, Iris, Convergent–Divergent Iris, Simple Ejector, Fully Variable Ejector,
Blow-in-Door Ejector, Plug, Isentropic Ramp.

Table 16.1 gives some incremental afterbody drag data for the nozzle concepts of Fig. 16.10; the drag data
were taken from several sources and thus there is some scatter in the data. *[Nicolai & Carichner, p.
430]*

### §16.10.2 Boattail Drag (p. 430)

The pressure and skin friction on the afterbody section surrounding the nozzle is called *boattail drag*.
The boattail drag coefficient is shown in Fig. 16.11 as a function of Mach number and boattail angle
$\beta$. For freestream Mach numbers greater than 1.0, the expression for $C_D$ presented in Fig. 16.11
should be used; this $C_{D_\beta}$ is referenced to the maximum cross-sectional area. *[Nicolai &
Carichner, p. 430]*

**Table 16.1** — *Incremental Afterbody Drag* *[Nicolai & Carichner, Table 16.1, p. 430]*:

| Nozzle Type | $\Delta C_D$ |
|---|---|
| Short convergent | 0.036–0.042 |
| Blow-in-door ejector | 0.025–0.035 |
| Plug | 0.015–0.02 |
| Fully variable ejector | 0.01–0.02 |
| Iris | 0.01–0.02 |
| Ramp | 0.01 |

Conditions: $M_\infty$ = 0.8–0.9; nozzle pressure ratios = 2.5–3.0; $\Delta C_D$ referenced to fuselage
maximum cross-sectional area.

**Fig. 16.11** — *Nozzle boattail drag coefficients (data from [4])* *[Nicolai & Carichner, Fig. 16.11, p.
431]*. Plot of Drag Coefficient $C_{D_\beta}$ (0–0.14) vs. Boattail Chord Angle $\beta$ (0–20 deg), with
curves for $M_\infty$ = 0.95, 0.925, 0.90, 0.85, and 0.40–0.80 (lowest), each rising from 0 at $\beta=0$ to
a maximum near $\beta=20$ deg (from ~0.05 for the lowest-Mach band up to ~0.14 for $M_\infty=0.95$).
Inset schematic defines boattail geometry: chord angle $\beta$, boattail length $L$, maximum diameter
$D_{max}$, nozzle exit (gross) diameter $D_g$, and $P_T/P_\infty = 2.5$. Inset note (unnumbered equation,
valid $1.0 \le M_\infty < 3.0$):

$$C_{D_\beta} = \frac{1.4\tan\beta}{M_\infty^{1.53}}\left[1-\left(\frac{D_g}{D_{max}}\right)^2\right]$$

*(unnumbered equation, inset on Fig. 16.11, p. 431; $D_g$ = nozzle exit diameter, $D_{max}$ = maximum
diameter, $\beta$ = chord angle, $L$ = boattail length)*

### §16.10.3 Base Area and Multiengine Installation (p. 431)

The designer should avoid any blunt-based areas, as these regions result in large drag increases (Figs.
16.12 and 16.13). Fig. 16.13 shows this behavior for blunt and tapered interfairings. Also, blunt-based
areas upstream of the nozzle exit plane are worse than those downstream, as shown in Figs. 16.12 and 16.13
by comparing $\Delta C_D$ for configurations FG-1 and FG-2. The drag due to a blunt base can be estimated
using Fig. 2.27. *[Nicolai & Carichner, pp. 431, 433]*

**Fig. 16.12** — *Effect of interfairing length on drag for constant-base areas (data from [5])* *[Nicolai
& Carichner, Fig. 16.12, p. 431]*. Plot of $C_{D_{AB}}$ (0–0.12) vs. $l_F/l_{AB}$ (0–1.4) at $M_\infty=0.8$,
$P_{0jet}/P_\infty = 2.75\,s/d_e$, with three curves for base-area ratio $A_b/A_{max}$ = 0.134, 0.037, and
0 — all decreasing with increasing $l_F/l_{AB}$, with higher $A_b/A_{max}$ giving higher drag throughout.
Inset schematic defines $A_{max}$, $A_b$, $l_{AB}$, and $l_F$ on a twin-boattail afterbody.

Fuselage-mounted multiengine installations should have a tapered interfairing between the engine nozzles.
Figs. 16.12 and 16.13 show the effect of interfairing location and length. *[Nicolai & Carichner, p. 433]*

**Fig. 16.13** — *Effect of interfairing length on drag for two engine spacings, $M_\infty = 0.9$ and
$P_{0jet}/P_\infty = 2.5$ (data from [5])* *[Nicolai & Carichner, Fig. 16.13, p. 432]*. Top: schematic
catalog of "Fairing Types" FG-1 through FG-4 (base upstream of nozzle exit, base at nozzle exit, long
fairing, extra-long fairing) shown both in profile and as twin-nacelle cross-sections; and "Iris Nozzles"
schematic showing boattail chord angle $\beta$ = 20/15/12.5/10 deg and geometry definitions $l_F$,
$l_{AB}$, $s$ (engine spacing), $d_e$ (nozzle exit diameter). Bottom: two plots of $\Delta C_D$ vs.
$l_F/l_{AB}$ (0.6–1.2) — left panel at $s/d_e = 2.12$ (curves for $\beta = 20$ deg and 15 deg), right panel
at $s/d_e = 2.69$ (curves for $\beta = 20, 15, 12.5, 10$ deg) — each curve rising to a peak then declining
as $l_F/l_{AB}$ increases, with $\beta = 20$ deg giving the highest peak drag in both panels.

Engine nozzle spacing is a design parameter that needs to be negotiated between the configuration (layout)
group and the propulsion group. Fig. 16.14 shows the effect of engine spacing on $\Delta C_D$ and
indicates an optimum $s/d_e$ of about 2.5 at high-subsonic speeds. However, this optimum $s/d_e$ might
aggravate some other feature of the design to the extent that a different $s/d_e$ is warranted — another
example of the compromise necessary between the design groups discussed in Chapter 1. *[Nicolai &
Carichner, pp. 433–434]*

**Fig. 16.14** — *Optimization of engine spacing from two different investigations (data from [5])*
*[Nicolai & Carichner, Fig. 16.14, p. 433]*. Two stacked plots vs. $s/d_e$ (0–5.0): top panel, "Grumman
Test" ($M_\infty = 0.85$, $P_{0jet}/P_\infty = 2.75$, $A_{max}/A_e = 9$–11) — $\Delta C_{D_{AB}} +$ Constant
(0–0.07) for four nozzle types (BIDE, Plug, C–D, Iris), each with a minimum near $s/d_e \approx 1.5$–2.5
and rising steeply at larger spacing (BIDE highest, Iris lowest at large $s/d_e$); bottom panel, "MBB Test"
— $\Delta C_D$ (0–0.03) for Iris nozzles at $\beta = 10$ deg and $M_\infty = 0.85, 0.90, 0.95$, showing a
local peak near $s/d_e \approx 1.5$, a minimum near $s/d_e \approx 2.5$–3.0, then rising again at larger
spacing, with higher $M_\infty$ giving higher $\Delta C_D$ throughout.

### References (p. 434)

[1] Antonatos, P. P., Surber, L. E., and Stava, D. J., "Inlet/Airplane Interference and Integration,"
AGARD Rept. LS-53, NASA, Report Distribution and Storage Unit, Langley Field, VA, May 1972.
[2] Zonars, D., "Dynamic Characteristics of Engine Inlets," AGARD Rept. LS-53, May 1972.
[3] Crosthwait, E. L., Kennon, I. G., and Roland, H. L., "Preliminary Design Methodology for
Air-Induction Systems," Technical Rept. SEG-TR-67-1, Wright–Patterson AFB, OH, Jan. 1967.
[4] Ball, W. H., "Propulsion System Installation Corrections," U.S. Air Force Flight Dynamics
Laboratory, Technical Rept. AFFDL-TR-72-147, Wright–Patterson AFB, OH, Dec. 1972.
[5] Aulehla, F. and Lotter, K., "Nozzle/Airframe Interference and Integration," AGARD Rept. LS-53, May
1972.

Chapter 16 extraction complete.
