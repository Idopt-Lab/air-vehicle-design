# Chapter 15 — Turbine Engine Inlet Design

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, Chapter 15,
printed pp. 383–412 (PDF pp. 393–422).

Text-layer inventory (built before extraction, for completeness checking): Figs 15.1, 15.2a, 15.2b,
15.3a, 15.3b, 15.3c, 15.4, 15.5, 15.6a, 15.6b, 15.7a, 15.7b, 15.8, 15.9, 15.10, 15.11, 15.12, 15.13a,
15.13b, 15.14, 15.15, 15.16; Tables 15.1, 15.2, 15.3; Eqs (15.1), (15.2), (15.3).

## Chapter opener

Section list: Pitot or Normal Shock Inlet; External Compression Inlet; Mixed Compression Inlet; SR-71
Inlet Operation; Mass Flow Ratio; Total Pressure Recovery; Inlet Examples. *[Nicolai & Carichner, p.
383]*

Photo caption: *The SR-71 mixed compression inlet (left) and the F-22 external compression inlet
(right). The SR-71 inlet design and operation is discussed in detail in this chapter. See Example 15.1
for an external compression inlet design similar to the F-22.* *[Nicolai & Carichner, p. 383]*

Chapter epigraph: *"The inlet messes up an otherwise clean design!"* — An aerodynamicist *[Nicolai &
Carichner, p. 383]*

## §15.1 Introduction

The primary purpose of an inlet is to supply the correct quantity and quality of air to the compressor
of the engine. The correct mass flow of air must be delivered to the compressor face at a Mach number
of about 0.4. The mass flow must also be delivered with an acceptable velocity distribution across the
engine face and with minimum loss in the total energy content of the air. In addition, the inlet is
required to do this at all flight conditions and at least weight, cost, and drag. The installation of a
turbine engine on an aircraft is a most challenging task. *[Nicolai & Carichner, §15.1, p. 384]*

A typical subsonic turbine engine installation consists of a high-compression engine with a short fixed
inlet and probably a variable convergent nozzle. The supersonic installation, on the other hand,
requires a powerplant with a sophisticated variable geometry inlet having its own automatic control
system and a fully variable convergent–divergent (C–D) nozzle in order to extract the full performance
from the engine throughout the speed range. A typical subsonic and supersonic installation is shown in
Fig. 15.1. Notice that the supersonic inlet is more than two engine diameters in length as opposed to
one diameter for the subsonic installation. The complications of the supersonic inlet and its influence
on weight will be discussed in this chapter. *[Nicolai & Carichner, p. 384]*

**Fig. 15.1** — *Typical subsonic and supersonic powerplant installations* *[Nicolai & Carichner, Fig.
15.1, p. 384]*. Two cutaway schematics: **Subsonic Installation** — short "Fixed Inlet" (~1 engine
diameter) feeding the "Engine," discharging through a "Variable Convergent Nozzle." **Supersonic
Installation** — a "Moving Center Body" spike, "Bypass Doors," longer "Variable Inlet" (~2+ engine
diameters) feeding the "Engine," discharging through a "Variable Primary Nozzle," "Adjustable Ejector,"
and "Variable C-D Nozzle."

The performance of the inlet is related to the following four characteristics: *[Nicolai & Carichner, p.
385]*
- Total pressure recovery
- Quality of airflow — distortion and turbulence
- Drag
- Weight and cost

The overall value of an inlet must always be determined by simultaneously evaluating all four
characteristics because the gain in one is often achieved at the expense of another. It should be kept
in mind that the most serious aspect of the engine–inlet problem is concerned with off-design operation;
none of the first three characteristics should deteriorate rapidly under conditions of varying power
settings and angles-of-attack. As a result, in actual vehicles many compromises have to be made to
achieve an acceptable performance throughout the variations in flight Mach number, angles-of-attack, and
sideslip as well as variations in the properties of the atmosphere. *[Nicolai & Carichner, p. 385]*

## §15.2 Pressure Recovery and Inlet Types

A supersonic airflow entering an inlet is decelerated through a shock wave or series of shock waves to
a subsonic value. The flow is further decelerated in the subsonic diffuser (the diverging section of the
inlet between the throat and the compressor face) to a value of about Mach = 0.4 at the compressor face.
*[Nicolai & Carichner, §15.2, p. 385]*

The *total pressure recovery* of the inlet is defined as the ratio of the total pressure at the
compressor face to that of the freestream:

$$\eta_R = \text{total pressure recovery} = P_{0_c}/P_{0_\infty}$$
*(unnumbered equation)* *[Nicolai & Carichner, p. 385]*

The total pressure recovery of the inlet is an important measure of the inlet performance. It is desired
to recover as much of the total pressure at the compressor face as possible (high value of $\eta_R$)
because the total pressure of the freestream represents the available mechanical energy of the flow
that can be converted into a static pressure increase as the flow is decelerated. A large static
pressure is desirable at the compressor face because then the compressor section of the turbine engine
does not have to be as large in order to compress the flow to the required pressure for combustion.
Total pressure is lost due to the viscous dissipation (friction) in the shock waves, the boundary layer,
and separated flow regions. The gradual deceleration of a supersonic stream to subsonic through a series
of oblique (or conical) shocks prior to the final normal shock is less costly in terms of total pressure
loss than a rapid deceleration through a normal shock. The maximum total pressure recovery for different
numbers of shocks in an optimum shock wave system is shown in Fig. 15.2. The curve for the single shock
is from the normal shock data of Appendix D. *[Nicolai & Carichner, p. 385–386]*

Inlets are of three types, characterized by their shock wave system: pitot or normal shock; external
compression; and mixed compression. These three inlet types are shown in Fig. 15.3. The simplest type
is the pitot inlet, with the supersonic compression being achieved through a normal shock and further
compression carried out in the subsonic diffuser (Fig. 15.3a). The pitot inlet is simple, short,
lightweight, and low cost. It gives tolerable total pressure recoveries up to about Mach 1.6. For
aircraft having top speed requirements up to about Mach = 1.6, such as the F-16 and F-18 (and needless
to say all subsonic aircraft), the pitot inlet is the best arrangement. *[Nicolai & Carichner, p. 386]*

For speeds above Mach = 1.6, the flow needs to be decelerated gradually through one or more oblique
shocks before the final deceleration through the normal shock. The external compression inlet, Fig.
15.3b, accomplishes the flow compression external to the inlet throat. The external ramp (with flow
deflection angle $\theta_R$) can be variable to put the oblique shock on the cowl lip for a variety of
different Mach numbers. This "shock-on-lip" is called the *design condition* and will be discussed
later. The desired operation is with the normal shock located at the inlet throat. This inlet provides
tolerable pressure recoveries up to about Mach = 2.5. *[Nicolai & Carichner, p. 386]*

**Fig. 15.2a** — *Maximum inviscid total pressure recovery — optimum oblique shock system* *[Nicolai &
Carichner, Fig. 15.2a, p. 386]*. Total Inviscid Pressure Recovery ($\eta_R$), y-axis 0.5–1.0, vs.
$M_\infty$, x-axis 1–5. Family of curves labeled "1 Shock" through "4 Shocks" (all under "Oblique
Shocks"), each starting at $\eta_R$=1.0 near $M_\infty$=1 and falling off; more shocks maintain higher
recovery to higher Mach number — 1 Shock falls to 0.5 by $M_\infty$≈2.4; 2 Shocks by ≈3.2; 3 Shocks by
≈4.1; 4 Shocks extends to ≈5.0 at $\eta_R$=0.5 *(read from plot)*.

**Fig. 15.2b** — *Maximum inviscid total pressure recovery — optimum conical shock system* *[Nicolai &
Carichner, Fig. 15.2b, p. 387]*. Total Inviscid Pressure Recovery ($\eta_R$), y-axis 0.5–1.0, vs.
$M_\infty$, x-axis 1–5. Family of curves labeled "Normal Shock," "Single Cone," "Double Cone,"
"Isotropic Spike" (all under "Conical Shocks"), each starting at $\eta_R$=1.0 near $M_\infty$=1 and
falling off; Normal Shock falls to 0.5 by $M_\infty$≈2.4; Single Cone by ≈3.3; Double Cone by ≈4.0;
Isentropic Spike extends furthest, to ≈5.0 at $\eta_R$=0.5 *(read from plot)*.

At freestream Mach numbers above Mach = 2.5 the inlet must provide a multiple shock system and would be
a *mixed compression inlet* (Fig. 15.3c). Here again the external ramp can be a series of ramps (or
cones) providing a series of external oblique shocks. The shock system continues into the supersonic
diffuser, with the normal shock located in the subsonic diffuser. The location of the normal shock is
dependent upon the backpressure at the compressor face. The ideal location for the normal shock is just
slightly downstream of the throat to minimize the strength of the normal shock and the total pressure
loss across it. However, this position is very sensitive to the backpressure. Any perturbation
downstream can cause the normal shock to "pop out" of the diffuser and move to a position forward of
the inlet lip, "unstarting" the inlet. The mixed compression inlets usually have bypass doors (see Fig.
15.6, Section 15.2.1) in the subsonic diffuser to control the backpressure and thereby the location of
the normal shock. These vents can also be used to bypass the excess air in the inlet that cannot be
accommodated by the engine. If this excess air is not bypassed it must be spilled ahead of the inlet,
causing the mixed compression inlet to unstart. *[Nicolai & Carichner, p. 387]*

The mixed compression inlet, sometimes called an *internal contraction inlet*, must have a variable
geometry feature to obtain peak performance. The compression ramps must be able to collapse (fold
down), giving a ratio of throat area $A_T$ to cowl area $A_c$ of about 0.8 in order to "swallow" the
normal shock and locate it in the subsonic diffuser. Once the inlet is started, the throat area is
decreased to an $A_T/A_c$ of about 0.4 or less (dependent on Mach number, see [1]), which locates the
normal shock just downstream of the throat for minimum total pressure loss. *[Nicolai & Carichner, p.
387–388]*

Inlets can be *two-dimensional* with compression ramps as shown in Figs. 15.3b and 15.3c or
*axisymmetric* with conical centerbodies as shown in Fig. 15.6 (Section 15.2.1). Axisymmetric inlets
have a slight advantage over two-dimensional inlets in terms of weight and pressure recovery. Round
ducts can usually be made lighter than rectangular ducts to take the large internal pressures. Also,
the total pressure loss across a conical shock is less than across an oblique shock for the same
upstream Mach number and flow deflection angle. *[Nicolai & Carichner, p. 388–389]*

The determination of the total pressure recovery for an inlet is accomplished by examining the shock
wave system and subsonic diffuser separately. Each shock is considered independently, with its
characteristics determined by the flow deflection angle and upstream Mach number. The characteristics
for oblique and conical shocks are presented in Appendix E and for normal shocks in Appendix D. The
total pressure recovery for the shock wave system is the product of the individual total pressure
ratios across each shock. Appendix Figs. E.6 and E.7 present the pressure recovery for cone inlets and
Appendix Figs. E.8 and E.9 for ramp inlets. *[Nicolai & Carichner, p. 389]*

The total pressure loss in a subsonic diffuser is dependent upon the diffuser geometry, throat Mach
number, and the presence of a normal shock ahead of the diffuser entrance. Figure 15.4 shows an
empirically determined [2] diffuser loss coefficient, $\varepsilon$, as a function of throat Mach
number $M_T$ and the ratio of diffuser length to throat height, $L_D/H_T$. The presence of a normal
shock ahead of the diffuser entrance aggravates the boundary layer growth and tendency for the flow to
separate, resulting in an increased diffuser loss coefficient. Figure 15.4 indicates that the designer
should avoid short and long subsonic diffusers. Short diffusers, $L_D/H_T$ of 4 or less, tend to cause
flow separation, and long diffusers result in large friction losses. Long diffusers are heavy and should
be avoided for that reason also. The ratio of the total pressure at the compressor face to that at the
diffuser entrance, $P_{0_c}/P_{0_T}$ is determined from Fig. 15.5. *[Nicolai & Carichner, p. 389]*

**Fig. 15.3** — *Types of inlets operating at supersonic "design" Mach numbers* *[Nicolai & Carichner,
Fig. 15.3, p. 388]*. Three sub-schematics:
- **(a) Pitot or Normal Shock**: freestream $M_\infty$=1.6, $P_{0_\infty}$, $P_\infty$ approach a
  straight normal-shock front, decelerating to $M_T$=0.67 at the throat ($A_T$), then diffusing to
  $M_C$=0.4, $P_C$, $P_{0_c}$ at the compressor face.
- **(b) External Compression**: freestream $M_\infty$=2.3, $P_\infty$, $P_{0_\infty}$ over a
  $\theta_R$=10° external ramp producing a 34.5° oblique shock to $M_1$=1.9 ($P_{0_1}$), then a normal
  shock (total turn $2\theta_D$) to $M_T$=0.6 ($P_{0_T}$) at the throat, diffusing to $M_C$=0.4,
  $T_C$/$P_C$, $P_{0_c}$.
- **(c) Mixed Compression (Internal–External)**: freestream $M_\infty$=3.5 over a 10° then 20° ramp
  (24.5° first oblique shock to $M_1$=2.9), continuing to an internal $M$=1.6 station, normal shock to
  $M_T$=2.4 *(sic — figure shows $M_T$=2.4 which is the internal supersonic diffuser Mach, not the
  post-normal-shock value; final subsonic throat Mach $M_T$=0.68 downstream)*.

**Fig. 15.2 note**: Figs. 15.2a/15.2b appear as two panels under the single caption "Fig. 15.2" in the
book; split here as 15.2a/15.2b matching the text-layer labels.

## §15.2.1 SR-71 Mixed Compression Inlet Operation

The SR-71, shown on the Chapter 2 cover page, has two Pratt and Whitney J58 afterburning turbojet
engines (34,000 lb SLS thrust). At this point the reader would be well served to review the SR-71 Case
Study in Volume 2. The operating speed and altitude (Mach = 3.2 at 85,000 ft) of the SR-71 dictated a
variable-geometry, mixed compression inlet. Figure 15.6 shows the axisymmetric mixed compression inlet
on the SR-71. Figure 15.6b (from [3]) shows the position of the centerbody spike and bypass doors to
locate the shock structure at four Mach numbers. This inlet design achieved a total pressure recovery of
78% at maximum speed and altitude. *[Nicolai & Carichner, §15.2.1, p. 389]*

The inlet control system operates to supply a flow of air, at correct pressure and velocity, to the
engines throughout the flight envelope. The system includes the centerbody spikes, which are translated
fore and aft to capture and retain the normal shock, and forward bypass doors, which operate to assist
the spikes in positioning the normal shock. The system is normally operated in the automatic mode;
however, it can be manually controlled by the pilot. *[Nicolai & Carichner, p. 389–390]*

**Fig. 15.4** — *Effect of diffuser length on diffuser loss coefficient (data from [2])* *[Nicolai &
Carichner, Fig. 15.4, p. 390]*. Two side-by-side plots, both Diffuser Loss Coefficient $\varepsilon$
(y-axis 0–0.32) vs. Diffuser Length-to-Height Ratio $L_D/H_T$ (x-axis 0–24), families of curves
parameterized by throat Mach number $M_T$ = 0.4, 0.5, 0.6, 0.7, 0.8, 0.9:
- **Left, "Thin boundary layer / Subsonic entrance"**: all curves dip to a minimum near $L_D/H_T$≈9–10
  (e.g. $M_T$=0.9: ≈0.15→0.12 dip→0.15 at $L_D/H_T$=20; $M_T$=0.4: ≈0.08→0.06 dip→0.10), U-shaped.
- **Right, "Shock ahead of entrance"**: all curves flat/minimal from $L_D/H_T$≈6–14, then rise sharply
  beyond ≈14–20 (e.g. $M_T$=0.9: ≈0.30 at $L_D/H_T$=4, dips to ≈0.245 flat through 14, rises to ≈0.31 at
  20; $M_T$=0.4: flat ≈0.10 throughout).
*(read from plot)*

**Fig. 15.5** — *Total pressure recovery loss factors for subsonic diffuser* *[Nicolai & Carichner, Fig.
15.5, p. 391]*. $P_{0_c}/P_{0_T}$, y-axis 0.90–1.00, vs. Throat Mach Number $M_T$, x-axis 0–1.0. Family
of curves for $\varepsilon$ = 0.01 through 0.20 (step 0.01), all converging near $M_T$≈0 to
$P_{0_c}/P_{0_T}$≈1.0 and diverging as $M_T$ increases, with higher $\varepsilon$ giving lower recovery
(e.g. $\varepsilon$=0.20 falls to ≈0.906 at $M_T$=1.0; $\varepsilon$=0.01 stays ≈0.996). The governing
relation is inset on the plot:

$$\frac{P_{0_c}}{P_{0_T}} = 1 - \varepsilon\left(1 - \frac{1}{(1+0.2M_T^2)^{3.5}}\right)$$
*(unnumbered equation, inset on Fig. 15.5)* *[Nicolai & Carichner, p. 391]*

Operating (continued): the spikes are moved forward and aft in the inlet duct as a function of Mach
number, varying the size of the inlet throat area and position of the conical shockwaves and the single
normal shock. The forward bypass doors are modulated to control inlet duct static pressure and therefore
fine tune the location of the normal shock in the inlet throat. The doors operate to prevent excessive
duct air pressure. *[Nicolai & Carichner, p. 391]*

Operation of the spike and bypass doors, and the resulting airflow patterns, is shown in Fig. 15.6b. At
altitudes below 30,000 ft and speeds less

**Fig. 15.6a** — *Typical supersonic mixed compression axisymmetric inlet* *[Nicolai & Carichner, Fig.
15.6a, p. 392]*. Cutaway side-view schematic of an axisymmetric mixed-compression inlet (SR-71 style),
labeling (top half): Bleed Scoops, BLC Bleed Exit, Vortex Valves, Throat Door Open, Bypass Door Open,
Secondary Air Entrance; (centerline): Translating Centerbody (double-arrow indicating fore/aft travel);
(bottom half): Hinge Point Bleed, Medium Pressure Bleed, Flush Slot Bleed, Throat Bleed, Throat Door
Closed, Struts (4), Takeoff Door Open.

**Fig. 15.6b** — *SR-71 mixed compression axisymmetric inlet airflows* *[Nicolai & Carichner, Fig. 15.6b,
p. 393]*. Five stacked schematic cross-sections of the SR-71 inlet showing spike position and airflow
pattern at Mach = 0.0, 0.5, 1.5, 2.5, and 3.2: at low speed (Mach 0.0–0.5) the spike is fully forward with
suck-in doors open and the throat wide open (Spike Forward); at transonic/low-supersonic speed (Mach 1.5)
the spike begins retracting aft (Spike Retracting) as the shock system forms; at design cruise speed
(Mach 2.5–3.2) the spike is fully retracted (Spike Retracted), the throat area is closed down, and the
bypass/tertiary doors and ejector flaps modulate the aft-flowing bypass and secondary air to match engine
demand.

Below Mach = 1.4, the spike is locked fully forward, and the inlet operates essentially as a pitot-type
subsonic inlet with the suck-in doors open to supply extra mass flow to the engine at low forward speed.
Above Mach 1.6, the spike begins translating aft on a schedule with Mach number; by Mach 3.2 the spike has
moved aft a total of 26 in., increasing the captured stream-tube area 112% (from 8.7 to 18.5 ft²) while
the throat area has closed down 54% (from 7.7 to 4.16 ft²) to maintain the correct internal contraction
ratio and hold the terminal shock at the throat. *[Nicolai & Carichner, pp. 393–394]*

As the spike translates aft, air bled from the shock trap slots and the spike boundary layer is ducted
through internal passages to the bypass system, where it is dumped overboard through the forward bypass
doors — a set of concentric annular bands that translate axially to modulate the bypass flow area. This
bleed and bypass air handling is what allows the inlet to accommodate the large change in captured mass
flow and throat contraction between takeoff and Mach 3.2 cruise while keeping the terminal (normal) shock
positioned just downstream of the throat for maximum pressure recovery. *[Nicolai & Carichner, p. 394]*

*Inlet unstart* occurs when the terminal shock is expelled forward out of the inlet (typically by a
disturbance such as engine surge, a yaw/sideslip transient, or excessive bypass-door motion), collapsing
the supersonic diffusion process. The inlet instantaneously loses most of its pressure recovery and mass
flow capture on the affected side; because the two inlets on a twin-engine, twin-inlet aircraft such as
the SR-71 unstart independently, the result is a large asymmetric thrust and drag imbalance that produces
a violent, sudden yawing motion — severe enough that SR-71 pilots described being slammed against the
side of the cockpit. *[Nicolai & Carichner, p. 394]*

The automatic restart sequence drives the spike forward and opens the bypass/suck-in doors within about
3 seconds of an unstart to re-establish the shock system and restore stable supersonic flow, then over
roughly the next 10 seconds returns the spike and doors to their normally scheduled positions for the
current flight Mach number. A restart "crosstie" logic links the two inlets' bypass-door control above
Mach 2.3 (so that an unstart on one side commands a compensating, symmetric response on the other side to
limit the yaw transient), while below Mach 2.3 the two inlets are controlled independently. *[Nicolai &
Carichner, p. 394]*

> "The SR-71 mixed compression inlet is truly spectacular—and the fact that it was developed in 1961
> before the use of modern computers makes it even more so." *[Nicolai & Carichner, p. 394]*

### §15.3 Capture-Area Ratio or Mass-Flow Ratio (Supersonic Flow) (p. 395)

The capture-area ratio (also called mass-flow ratio) characterizes how much of the air approaching the
inlet in the freestream tube is actually captured and ingested versus spilled around the inlet. Define
$A_c$ as the cowl capture area (the physical inlet lip area) and $A_\infty$ as the freestream stream-tube
cross-sectional area of the air that is actually captured, so that $A_\infty / A_c$ is the mass-flow
ratio. Two freestream areas are of interest, illustrated in Fig. 15.7: $A_{\infty I}$, the stream-tube area
of the air the inlet is geometrically able to supply (inlet supply), and $A_{\infty E}$, the stream-tube
area of the air the engine actually demands (engine demand) — $\dot{m}_E$ vs. $\dot{m}_I$ are "matched"
when $A_{\infty E} = A_{\infty I}$, and "unmatched" (with excess air spilled or bypassed) otherwise.
*[Nicolai & Carichner, p. 395]*

**Fig. 15.7** — *Excess air spilled* *[Nicolai & Carichner, Fig. 15.7, p. 395]*. Two sub-panels showing a
two-dimensional external-compression inlet at $M_\infty = 1.8$ with a 15° ramp angle ($\theta_R$) producing
a 51° oblique shock: **(a) Subcritical Operation** — the captured stream tube $A_{\infty I}$ is larger than
the engine's demanded $A_{\infty E}$; excess air is spilled both around the compression-surface shock
(*Compression Surface Spillage*) and past the cowl lip (*Excess Air Spillage* / *Spilled Air*), so the
oblique shock stands off ahead of the cowl lip. **(b) Critical Operation** — the oblique shock is
positioned exactly at the cowl lip (no spillage past the lip), but the inlet still supplies more air than
the engine demands; the excess (*Bypassed Air*) is taken in through the inlet throat and dumped overboard
through bypass doors rather than spilled externally ahead of the shock.

Mass-flow relations accompanying Fig. 15.7 *[Nicolai & Carichner, p. 395]*:

- From continuity: $\dot{m} = \text{constant}$
- For the captured stream tube: $\rho_\infty V_\infty A_\infty = \rho_1 V_1 A_T = \rho_T V_T A_T$
- Engine demand: $\dot{m}_E = \rho_\infty V_\infty A_{\infty E} = \dot{m}_a$
- Inlet supply: $\dot{m}_I = \rho_\infty V_\infty A_{\infty I}$
- Excess air: $\dot{m}_X = \dot{m}_I - \dot{m}_E$

The mass flow ratio is *[Nicolai & Carichner, Eq. (15.1), p. 396]*:

$$\frac{\dot{m}_\infty}{\dot{m}_c} = \frac{\rho_\infty V_\infty A_\infty}{\rho_\infty V_\infty A_c} = \frac{A_\infty}{A_c} \tag{15.1}$$

which is the same as the capture area ratio $A_\infty/A_c$.

As the inlet mass flow ratio changes, the normal shock position and total pressure recovery ratio
change (Fig. 15.8). The inlet is designed to operate with the oblique shock crossing the lip of the
inlet at the required (design) mass flow of the engine (Figs. 15.3b, 15.3c, 15.8b) — the *critical
condition* (point B, Fig. 15.8): the normal shock sits at the throat, giving a maximum value of mass
flow and pressure recovery. If the engine demand for air becomes less (e.g., throttling back for
cruise) the normal shock is expelled forward to spill excess air over the outside of the lip (assuming
no bypass facility); air entering in this condition passes only through the single shock formed by the
intersection of the normal and oblique shocks, giving lower pressure recovery — *subcritical operation*
(point A, Fig. 15.8). If the inlet is operating critically and the engine suddenly demands more airflow,
the backpressure decreases and the normal shock moves back into the subsonic diffuser, becoming stronger;
mass flow cannot increase because the inlet is choked, so pressure recovery drops to bring engine airflow
demand down to inlet capacity — the engine is *starved* and operation is termed *supercritical* (point C,
Fig. 15.8). *[Nicolai & Carichner, pp. 396–397]*

**Fig. 15.8** — *Mass flow–pressure recovery characteristic (data from [4])* *[Nicolai & Carichner, Fig.
15.8, p. 396]*. Left: Pressure Recovery vs. Mass Flow curve with three marked points — A (Subcritical,
on the rising/nearly-flat portion of the curve), B (Critical, at the curve's peak/knee), and C
(Supercritical, on the steep vertical drop-off below B). Right: three schematic diagrams of intake flow
at a 2D external-compression inlet lip corresponding to each point — (A) Subcritical: shock stands off
ahead of the lip with visible *Spillage*; (B) Critical: shock sits exactly at the lip, no spillage; (C)
Supercritical: shock swallowed inside the throat (implied by the schematic showing the compression
surface with no external spillage and a different internal shock position).

### §15.4 Variable-Geometry Inlets (p. 397)

The *design Mach number* $M_D$ is the flight vehicle speed critical to mission performance (cruise
speed, weapon-delivery speed, or maximum speed). The inlet is designed for $M_D$ to give high $\eta_R$,
shock-on-lip operation, and $A_{\infty I}$ matched to engine demand so spillage/bypass drag are minimal.
A fixed-geometry inlet's performance deteriorates rapidly off $M_D$: above $M_D$ the engine is usually
starved (demand > supply); below $M_D$ the shock is off the cowl lip ($A_\infty < A_c$), causing
compression-surface spillage (Fig. 15.7) and additive drag, and the throat area may not be sized
properly for the incoming flow. Variable geometry can resolve some of these problems at the cost of
increased complexity, weight, and cost — a designer tradeoff. *[Nicolai & Carichner, pp. 397–398]*

A variable-geometry inlet may use a variable-angle compression ramp or centerbody to keep the
shock-on-the-lip at off-design Mach numbers; the ramp/centerbody can also translate to keep shock-on-lip
while providing a variable throat area. The inlet capture area $A_C$ may also be varied through a hinged
cowl lip to better match engine demand airflow with supply across flight speeds. Since an engine accepts
only a certain amount of air, excess air must be diverted to the freestream as efficiently as possible —
requiring still more geometry variation. One solution increases the compression ramp angle $\theta_R$,
moving the shock off the cowl lip and diverting excess air over the cowl lip (*compression surface
spillage* / *critical spillage drag*) — lower losses than leaving the shock on the lip and letting excess
air back up and spill around the lip (Fig. 15.7a). Another solution provides bypass vents/doors in the
subsonic diffuser to bypass excess air into the freestream (Fig. 15.7b), producing *bypass drag* from
pressure drag on the spill vents and momentum change of the bypassed air. Normally both facilities are
provided, with compromise settings chosen for minimum drag across flight Mach numbers. The mixed
compression inlet's variable throat area (§15.2.1) is necessary to swallow the normal shock on unstart
and reposition it for best pressure recovery; bypass doors are the main control over normal shock
location once the mixed-compression inlet has started. At low speed, most inlets lack enough cowl area
$A_C$ to provide required engine airflow, so auxiliary/suck-in doors are located in the subsonic diffuser
to provide additional air during takeoff (Fig. 15.6). *[Nicolai & Carichner, p. 398]*

**Fig. 15.9** — *Mach 2.2 variable-geometry mixed-compression inlet operating at different flight
conditions* *[Nicolai & Carichner, Fig. 15.9, p. 398]*. Four schematic cross-sections of a 2D
variable-geometry inlet designed for Mach = 2.2: **Takeoff** — Ramp Collapsed, Throat Collapsed,
Auxiliary Inlet Open; **Mach = 0.85** — Ramp 9 deg, Throat at 24 in., Cowl Drooped; **Mach = 1.2** —
Ramp Collapsed, Throat Collapsed, Bypass Activated (open), Cowl Normal; **Mach = 2.2** — Ramp 11 deg,
Throat at 16 in., Bypass Activated (closed), Cowl Normal.

### §15.5 Quality of the Airflow — Distortion and Turbulence (p. 399)

Inlet performance also depends on the quality of airflow delivered to the engine compressor: distortion
and turbulence at the compression face must be minimal or compressor stall and even engine flameout can
result. Distortion elements are swirl and uneven spatial distribution of total pressure, velocity, and
temperature; *turbulence* is a dynamic characteristic producing time variation of the distortion pattern.
A poor velocity distribution at the compressor face can cause blades to pass through alternating
high-/low-speed regions, causing vibration and possible blade failure; local velocity variations may be
interpreted as local angle-of-attack variations along the blade (radially), sufficient to stall the blade,
which can stall other blades and surge the engine. Flow quality/distortion is often measured by the
*distortion parameter* $K_D$. *[Nicolai & Carichner, p. 399]*

Main sources of distortion and turbulence *[Nicolai & Carichner, p. 399]*:
- Flow-field nonuniformity
- Ingestion of low-energy air
- Inlet shock system pressure gradients
- Shock/boundary layer interaction
- Cowl lip separation
- Duct pressure losses and flow separation
- Secondary duct flows

Inlet location on the vehicle is often driven by flow-quality considerations: the inlet should not sit in
separated/vortical (swirl) flow, and the vehicle boundary layer should not be permitted to interact with
the inlet, since ingesting it can aggravate the inlet boundary layer and cause early separation. The inlet
should be located out of the vehicle boundary layer by a boundary-layer diverter, as shown for the
Concorde, XB-70, and F-18 in Fig. 15.13b (§15.7) — note the F-35 uses a diverterless inlet instead. The
inlet's own boundary layer should be removed by boundary-layer bleed; the inlet shock-wave system
interacting with the boundary layer can cause flow separation, greatly reducing total pressure recovery
and degrading flow quality at the compressor face. The amount of boundary layer to remove is a function
of inlet type, shape, and shock-wave system; engine sensitivity to distortion/turbulence; and vehicle
performance sensitivity to pressure recovery and bleed drag. External-compression inlets normally need
less bleed than mixed-compression inlets (fewer shocks interacting with the boundary layer, shorter
compression surfaces). Two-dimensional inlets usually need more bleed than axisymmetric inlets (boundary
layer accumulates on sidewalls/corners, more surface area). A recommended bleed amount is given in
Fig. 15.11; bleed ports should sit in the throat area and at sharp bends in the subsonic diffuser (Figs.
15.6, 15.14); duct bend angles should not exceed 15 deg where the duct requires high Mach number
(e.g. 0.85) near the throat. *[Nicolai & Carichner, pp. 399–400, citing Ref. [5]]*

**Fig. 15.10** — *Comparison of average and instantaneous recovery maps with $K_D$. F-111 flight
conditions: Mach = 0.9 at 30,000 ft and off-design spike position* *[Nicolai & Carichner, Fig. 15.10, p.
400]*. Three panels: (left) compressor-face total-pressure-recovery contour map, time-averaged, contours
0.80–0.96; (middle) compressor-face total-pressure-recovery contour map, instantaneous at surge
initiation, contours 0.76–0.96 (broader spread than the time-averaged map); (right) time history of
distortion parameter $K_D$ (400–1400) vs. time (0–0.5 s), oscillating irregularly around 700–1000 before
a marked "Surge Initiation" threshold (~1200) is crossed near t≈0.48 s, followed by "Surge."

**Fig. 15.11** — *Recommended boundary layer bleed (data from [2])* *[Nicolai & Carichner, Fig. 15.11, p.
401]*. Plot of bleed-area ratio $A_{BLB}/A_C$ (0–0.20) vs. Mach number $M_\infty$ (0.8–4.8) with three
labeled curve families: "Porous" (lowest, external-compression inlets, porous bleed), "External
Compression Inlets" (dashed, slot bleed, labeled "Slot"), and "External-Internal Compression Inlets
(mixed)" (dotted, highest bleed-area ratio at a given Mach, rising to ~0.14 by Mach 4.6). Approximate
digitized values *(read from plot)*:

| $M_\infty$ | Porous | External-Compression (Slot) | Mixed (External-Internal) |
|---|---|---|---|
| 1.0 | ~0.010 | ~0.015 | ~0.020 |
| 1.6 | ~0.020 | ~0.030 | ~0.035 |
| 2.2 | ~0.035 | ~0.050 | ~0.060 |
| 2.8 | ~0.045 | ~0.070 | ~0.085 |
| 3.4 | — | ~0.085 | ~0.105 |
| 4.0 | — | — | ~0.120 |
| 4.6 | — | — | ~0.140 |

Podded engines (e.g. Boeing 747, Lockheed C-5) are good inlet designs from a flow-quality standpoint: the
inlet operates in undisturbed flow with minimal engine–airframe interaction, and podded engines offer good
maintainability (easy access). Low-slung inlets initiate strong inlet vortices normal to the ground plane
with enough energy to scatter debris and ingest foreign objects; where possible, the inlet lip should be
more than two inlet diameters from the ground *[Ref. [5]]*, and inlets should not be located in trail of
the landing gear (to avoid ingesting debris kicked up by the wheels). *[Nicolai & Carichner, p. 401]*

### §15.6 Weight and Cost (p. 401)

High inlet performance must be balanced against tolerable weight and cost. Example: an aircraft designed
for up to Mach = 1.6 could use a normal-shock inlet or a variable-ramp external-compression inlet — the
designer must trade the simple, low-weight, low-cost normal-shock inlet (shock $\eta_R = 0.9$ at Mach 1.6)
against the more complicated, heavier, costlier external-compression inlet (shock $\eta_R \sim 0.97$).
Whether the improved pressure recovery is worth the added weight/cost requires full tradeoff information.
A nacelle weight comparison study [6] showed a normal-shock inlet designed for low-subsonic flight weighed
13% of basic engine weight, whereas a mixed-compression inlet designed for Mach = 2.7 flight weighed 43%
of basic engine weight. Inlet weights are determined using the weight equations of Chapter 20. *[Nicolai
& Carichner, pp. 401–402]*

### §15.7 Inlet Sizing and Design (p. 402)

This section covers general inlet sizing/design, followed by a worked example of a Mach = 2.3 inlet for
the PW-F100 engine. Ref. [5] is recommended as an excellent report on inlet design, and many of its ideas
are incorporated in this chapter. *[Nicolai & Carichner, p. 402]*

The inlet should be sized to provide enough air to the engine at all flight conditions; since it is rare
that an inlet can provide exactly the right amount of air at all conditions, critical ("design") flight
conditions are selected — there may be one or more design Mach numbers $M_D$. The engine demand
cross-sectional area $A_{\infty E}$ is determined for different Mach–altitude conditions using *[Nicolai
& Carichner, Eq. (15.2), p. 402]*:

$$A_{\infty E} = \frac{\dot{m}_E + \dot{m}_S}{32.17\, \rho_\infty V_\infty} \tag{15.2}$$

where $\dot{m}_E$ is engine airflow in lbm/s (a function of Mach, altitude, and power setting — see Fig.
14.8g) and $\dot{m}_S$ is secondary airflow required for engine oil cooling, ejector nozzle cooling, etc.
Typical secondary-airflow values are given in Table 15.1. The maximum value of $A_{\infty E}$ is increased
by the amount recommended for boundary-layer bleed (Fig. 15.11), and the result set equal to the inlet
capture area $A_c$. If the maximum $A_{\infty E}$ occurs at takeoff, a lower value should be selected for
$A_c$ and the inlet provided with auxiliary takeoff doors — otherwise the inlet is oversized for other
parts of the mission, resulting in large amounts of excess air; usually the $A_{\infty E}$ for cruise or
maximum speed is selected for $A_c$. *[Nicolai & Carichner, pp. 402–403]*

**Table 15.1** — *Typical Secondary Airflows (data from [5])* *[Nicolai & Carichner, Table 15.1, p. 402]*:

| Secondary airflow use | $\dot{m}_S/\dot{m}_E$ |
|---|---|
| Engine oil cooling | 0–0.01 |
| Engine nacelle cooling | 0–0.04 |
| Ejector nozzle secondary air | 0.04–0.20 |
| Hydraulic system cooling | 0–0.01 |
| Vehicle environmental control | 0.02–0.05 |

Figure 15.16 (§15.8) shows a typical *engine demand capture area ratio*, $A_{\infty E}/A_c$, for a
supersonic aircraft; the inlet is designed to give a capture-area ratio of 1 at the flight condition of
the selected $A_c$ — this Mach number is termed the design Mach number $M_D$. The type of inlet selected
should be based on $M_D$; Fig. 15.12 offers rules of thumb for inlet selection based primarily on
tolerable total pressure recovery. The inlet is then designed to match the *inlet supply capture area
ratio*, $A_{\infty I}/A_c$, as closely as possible to the engine demand capture area ratio. *[Nicolai &
Carichner, p. 403]*

The inlet for subsonic and transonic aircraft will probably be a pitot inlet for its simplicity, low
weight, and low cost. Generally these inlets are sized for cruise altitude and Mach number and need very
little (or no) variable geometry, bypass, boundary-layer bleed, or control complexity for satisfactory
operation [6]. They are usually characterized by generously rounded cowl lips and are either podded or
blended into the fuselage so that no appreciable low-energy air or vortex flow is likely to be ingested.
Some designs incorporate blow-in doors for low-speed, low-altitude flight, but when flight safety is a
prime consideration the inlet cowl is usually sized [continues onto next page]. *[Nicolai & Carichner, p.
403]*

**Fig. 15.12** — *Effect of design Mach number on propulsion systems (data from [4])* *[Nicolai &
Carichner, Fig. 15.12, p. 403]*. Horizontal-bar chart vs. Design Mach Number (0–4), grouped in three rows:
**Optimum Fixed Engine Cycle for Cruise** — Propeller (~0.2–0.6), Turbofan Dry (~0.5–1.5), Turbojet
(~1.0–3.4), Turbofan Wet (~2.5–3.8), Ramjet (~3.4–4.0+); **Optimum Intake** — Pitot (~0.2–1.5), External
Compression (~1.3–2.7), Mixed Compression (~2.5–4.0+); **Optimum Nozzle** — Fixed Convergent (~0.2–1.5),
Fixed C–D (~1.3–1.9), Variable C–D or Ejector (~1.7–4.0+).

The inlet for subsonic/transonic aircraft (pitot inlet) is usually sized sufficiently large to avoid the
added complexity of variable geometry. The pitot inlet gives $A_{\infty I}/A_c = 1$ for Mach > 1.0 and
$A_{\infty I}/A_c > 1$ for all subsonic Mach numbers. At Mach numbers < 1.10, spillage is a better way of
getting rid of excess inlet airflow because it has a lower drag penalty than bypassing at these Mach
numbers; above Mach = 1.10 the designer should examine the tradeoff between spillage and bypass drag and
perhaps provide facilities for both. *[Nicolai & Carichner, p. 404]*

At supersonic Mach numbers above Mach = 1.6, inlets should be of the external-compression or
mixed-compression type. For these inlet types the designer has many decisions: although $A_C$ is fixed by
airflow demand at $M_D$, there remain questions of two-dimensional vs. axisymmetric, single vs. multiple
compression surfaces, compression surface angles, and fixed vs. variable geometry. Axisymmetric inlets
are slightly more efficient than two-dimensional inlets in total pressure recovery and weight; however, if
there is very much variable geometry (translating/variable-angle compression surfaces, variable cowl
area), the two-dimensional inlet could be less complicated and lighter. Multiple compression surfaces
complicate the design and always compound off-design operation, but high total pressure recovery at
speeds greater than Mach = 2.3 requires a multiple shock-wave system — Appendix Figs. E.6, E.7, E.8, and
E.9 can be used to select cone/ramp angles for a desired total pressure recovery schedule. The fixed vs.
variable geometry question depends heavily on matching supply to demand airflow; these inlets should have
boundary-layer bleed control per the schedule in Fig. 15.11, with the inlet supply accounting for it, and
should also have bypass provision — used not only for airflow matching but for reduction of spillage drag
and internal shock control. *[Nicolai & Carichner, p. 404]*

Once compression surfaces and angles are selected, the inlet supply capture area ratio $A_{\infty I}/A_c$
as a function of Mach number is determined and compared with the engine demand capture area ratio
$A_{\infty E}/A_c$ (Fig. 15.16, §15.8 — actually within this section, see Fig. 15.16 below). This
comparison readily illustrates spillage and bypass requirements; the designer might fine-tune the inlet at
this point to minimize the excess-air schedule. The throat area should be checked to ensure it is adequate
to pass supply air at all flight conditions — the *mass flow parameter* (MFP) of Appendix C is a useful
quick-check parameter. *[Nicolai & Carichner, p. 404]*

The subsonic diffuser must decelerate the flow to a Mach number ~0.4 at the compressor face with minimum
distortion and turbulence, meaning a diverging duct with gentle bends. The ratio of diffuser-exit area to
throat area is given by *[Nicolai & Carichner, Eq. (15.3), p. 405]*:

$$\frac{A_{exit}}{A_T} = \frac{(A/A^*)_{exit}}{(A/A^*)_T} \tag{15.3}$$

where both $A/A^*$ are functions of the Mach numbers at the diffuser exit and throat, determined from
Appendix C. Usually $A_T$ and $M_T$ are fixed and $A_{exit}$ is the area of the engine compressor face, so
Eq. (15.3) can be used to find the Mach number at the compressor face. *[Nicolai & Carichner, p. 405]*

The subsonic diffuser length $L_D$ is usually determined by constraints on acceptable locations for the
inlet and engine on the vehicle — the need to locate the inlet in a favorable flow field and the engine at
a good position for exhaust discharge or vehicle balance usually dictates duct length. Fig. 15.4 can help
select the subsonic diffuser length for good pressure recovery; a good rule of thumb is to keep the
diffuser overall included expansion angle $2\theta_D$ (Fig. 15.3b) less than 10 deg *[Ref. [5]]*. There
should be a short section of zero slope (one to three throat radii) leading into the compressor to let the
flow stabilize and even out the discharge velocity profile. *[Nicolai & Carichner, p. 405]*

Figure 15.13 shows a few of the many available inlet designs — each aircraft has its own operating
characteristics and the inlet is tailored to fit. For fixed-geometry subsonic operation, the axisymmetric
pitot inlet is hard to beat for weight and performance; most subsonic aircraft use some form of it. The
variable-geometry features of the two-dimensional inlet are less complicated than on an axisymmetric
inlet, leading to its selection on supersonic aircraft such as the Anglo-French Concorde, Soviet TU-144,
B-1, MiG-23, RA5C, and F-15. Underwing location on the Concorde (Fig. 15.13b), the B-1 (Fig. 7.15), and
the F-15 provides precompression and permits smaller capture areas than an inlet exposed to the
freestream; flow deflection by the wing also reduces inflow angles at angle-of-attack. Axisymmetric inlets
have the advantage of efficient structural shape for low duct weight and the lowest wetted area per unit
flow area, but require a cone-shaped spike, which presents problems: translating the spike fore/aft to
keep shock-on-lip, and collapsing the spike to provide variable throat area, are design nightmares. The
A-12 and SR-71 represent one successful circular-inlet solution; the SR-71 has its inlet canted inboard
and pointed down a few degrees to better align the spike with local flow at cruise angle-of-attack. The
F-16 is not required to operate much past Mach = 1.6 and thus uses the simple, lightweight normal-shock
inlet mounted in a chin fashion. *[Nicolai & Carichner, pp. 405–406]*

**Fig. 15.13a** — *Typical inlet designs* *[Nicolai & Carichner, Fig. 15.13a, p. 406]*. Twelve front-view
line drawings of aircraft inlet arrangements, arranged in a 3×4 grid: Concorde, B-757, B-747; B-1, C-5,
L-1011; F-18, F-4, F-15; F-16, F-117, F-35.

Half-round inlets fit nicely along the fuselage side and have been used on several Mach-2-class aircraft:
the F-104 uses this design with a fixed half-round spike; the Mirage 3G uses this configuration located
well forward on the fuselage and, with long generous ducts, has operated very well with early versions of
the TF-30 engine that were a problem for the F-111. Quarter-round inlets located in the wing–fuselage
armpit, as on the F-111 (Fig. 15.13b), have very low external surface area and low duct weight (short
distance to engine); the location also offers some precompression from the wing shock and allows a
smaller design capture area. On the F-111, a splitter plate removes boundary-layer air built up on the
long forward fuselage; a pie-shaped subinlet removes splitter-plate boundary layer, another pie inlet
removes boundary layer from the wing glove, and bleed holes are used on the cone surface. Variable
geometry includes both a variable second cone angle (diameter) and translation of the whole cone
(fore/aft); as with all cone-type inlets, the cone cannot collapse enough to provide large subsonic flow
area, which — combined with an initially small capture area — required the F-111 to employ large suck-in
doors at low speed. Downstream of the throat, the short subsonic diffuser makes an appreciable turn inboard
to the engine; due to its location, the inlet is sensitive to angle-of-attack as boundary layer builds up
between the fuselage and wing glove. The F-111 was plagued with engine–inlet problems during flight test
and motivated a great deal of inlet distortion/turbulence research during the mid-1960s. Many versions of
the "D" inlet have been used successfully on Mach-2-class aircraft; the J-79-powered F-4 uses a "D" inlet
with variable-geometry compression ramps, with a slight downward tilt providing better flow alignment at
angle-of-attack. *[Nicolai & Carichner, p. 408]*

**Fig. 15.13b** — *Inlet design examples* *[Nicolai & Carichner, Fig. 15.13b, p. 407]*. Four annotated
photographs: F-111 (boundary-layer diverter panel visible ahead of the intake), Concorde (underwing
diverter visible near the landing gear), F-18 (boundary-layer diverter panel below the leading-edge
extension), and F-35 (diverterless supersonic inlet — bump/caret-shaped forebody compression surface with
no diverter gap, labeled "Diverterless").

### Example 15.1 — External Compression Inlet for $M_D$ = 2.3 (p. 408)

Sizing and design of a two-dimensional external-compression inlet for the PW-F100 turbofan engine, design
Mach = 2.3 at 30,000 ft — representative of the F-15's inlet. Table 15.2 presents total pressure recovery
data for the Mach 2.3 external-compression inlet shown in Fig. 15.14. This two-dimensional inlet has a
detached normal shock from Mach 1.0 to 1.5; it also has a short subsonic diffuser ($L_D/H_T = 4.9$), and
the resulting diffuser losses are as large as the losses across the shock-wave system at most supersonic
Mach numbers — a design compromise for a lightweight (short), reasonably efficient inlet at the design
Mach number. *[Nicolai & Carichner, p. 408]*

**Table 15.2** — *Total Pressure Recovery Data for Inlet in Fig. 15.14* *[Nicolai & Carichner, Table
15.2, p. 409]*:

| $M_\infty$ | $M_T$ | $P_{0_I}/P_{0_\infty}$ (a) | $P_{0_T}/P_{0_I}$ (b) | $P_{0_C}/P_{0_T}$ (c) | $P_{0_C}/P_{0_\infty}$ |
|---|---|---|---|---|---|
| 0.4 | 0.4 | — | — | 0.99 | 0.99 |
| 0.6 | 0.6 | — | — | 0.977 | 0.977 |
| 0.8 | 0.8 | — | — | 0.955 | 0.955 |
| 1.0 | 1.0 | — | 1.0 | 0.925 | 0.925 |
| 1.2 | 0.84 | — | 0.993 | 0.905 | 0.90 |
| 1.4 | 0.74 | — | 0.958 | 0.927 | 0.89 |
| 1.6 | 0.91 | 0.972 | 0.999 | 0.875 | 0.85 |
| 1.8 | 0.81 | 0.958 | 0.986 | 0.91 | 0.86 |
| 2.0 | 0.72 | 0.953 | 0.942 | 0.933 | 0.84 |
| 2.3 | 0.63 | 0.942 | 0.84 | 0.957 | 0.76 |

(a) Across oblique shock. (b) Across normal shock. (c) Across subsonic diffuser.

**Fig. 15.14** — *Mach = 2.3 two-dimensional external compression inlet* *[Nicolai & Carichner, Fig. 15.14,
p. 409]*. Top view (left inlet) and side view of a 2D external-compression inlet: top view shows fuselage
centerline, a 24 in. offset with boundary-layer diverter, a ramp with included angle $2\theta_D = 8$ deg,
boundary-layer bleed slot, and the PW-100 engine face at the aft end. Side view shows cowl height
$H_C = 38$ in., ramp angles 10 deg/15 deg forward compression surface, throat height $H_T = 24$ in., duct
divergence angle $\theta_D = 4$ deg, bleed lip angle $\theta_{BLB} = 15$ deg, bypass vent angle
$\theta_{BP} = 10$ deg, overall duct height 40 in., subsonic diffuser length $L_D = 118$ in., overall inlet
length 170 in. Caption note: $A_C = 6.2$ ft², variable ramp (schedule in Fig. 15.16).

The assumed trajectory and required engine/secondary airflows (from Fig. 14.8g) are shown in Table 15.3.
Using Eq. (15.2), $A_{\infty E}$ is determined; the required engine capture area $A_{\infty E}$ at
$M_D = 2.3$ is 5.92 ft². The recommended bleed from Fig. 15.11 is 4%, making the design cowl area
$A_c = 6.2$ ft². The demand capture area ratio $A_\infty/A_c$ is plotted in Fig. 15.16. The inlet will have
auxiliary takeoff doors to augment inlet area at takeoff. *[Nicolai & Carichner, pp. 409–410]*

**Table 15.3** — *Demand Capture Area for PW-F100 Engine* *[Nicolai & Carichner, Table 15.3, p. 410]*:

| Mach | Altitude (1000 ft) | $\dot{m}_E + \dot{m}_S$ (lbm/s) (a) | $A_{\infty E}$ (ft²) | $A_{\infty E}/A_C$ (b) |
|---|---|---|---|---|
| 0.25 | 2 | 205 | 10.9 | 1.76 |
| 0.5 | 4 | 220 | 5.9 | 0.95 |
| 0.75 | 5 | 245 | 4.53 | 0.73 |
| 1.0 | 30 | 130 | 4.56 | 0.74 |
| 1.2 | 30 | 154 | 4.53 | 0.734 |
| 1.4 | 30 | 183 | 4.62 | 0.749 |
| 1.6 | 30 | 217 | 4.76 | 0.77 |
| 1.8 | 30 | 257 | 5.01 | 0.81 |
| 2.0 | 30 | 300 | 5.26 | 0.853 |
| 2.3 | 30 | 388 | 5.92 | 0.96 |

(a) $\dot{m}_E$ and $\dot{m}_S$ at maximum power from Fig. 14.8g and Table 15.1. (b) Selected
$A_C = 6.2$ ft².

The design philosophy behind Fig. 15.14's inlet is a lightweight, low-cost inlet giving reasonably good
efficiency at a maximum speed of Mach = 2.3. The primary mission (similar to the F-15 Eagle) is air
superiority, so the inlet and engine must be well matched in the transonic combat arena (Mach = 0.7–1.2,
10,000–30,000 ft); the aircraft is designed around two PW-F100 engines. The two-dimensional, single-ramp,
external-compression inlet of Fig. 15.14 was selected — the single ramp angle of 15 deg at Mach = 2.3 is a
little on the high side for good pressure recovery, but gives a short inlet for shock-on-lip operation at
this Mach number. Pressure recovery characteristics are shown in Table 15.2 and Fig. 15.15. The inlet
features a variable ramp per the schedule in Fig. 15.16, selected to keep excess air during maximum-power
operation to a minimum; for Mach > 1.1 excess air is bypassed. The Mach = 2.3 pressure recovery is 75%,
comparable to the 78% recovery for the SR-71 at Mach = 3.2. *[Nicolai & Carichner, p. 410]*

**Fig. 15.15** — *Total pressure recovery for inlet of Fig. 15.14* *[Nicolai & Carichner, Fig. 15.15, p.
411]*. Plot of total pressure recovery $P_{0_C}/P_{0_\infty}$ (0.6–1.0) vs. $M_\infty$ (0–3.0): recovery
starts near 1.0 at low Mach, declines gradually to ~0.85 by Mach 1.6 (with a small local bump/kink up to
~0.86 around Mach 1.7–1.8 reflecting the shock-detachment/oblique-shock transition), then declines more
steeply to ~0.65 by Mach 2.6.

The inlet supply capture area ratio is shown in Fig. 15.16 and provides a good match for engine demand
during maximum power operation. The maximum bypass requirement (for maximum power operation) above Mach =
1.1 is only 4%, and this sized the spill vents (see §16.8, "Section 16.8" per text — cross-reference to
Chapter 16). During cruise at Mach = 0.9, the required thrust is 70% of NRT (non-afterburning rated
thrust), meaning the airflow requirement is approximately 70% [see Eq. (18.2)]; this cruise demand point at
Mach = 0.9 is shown in Fig. 15.16 and indicates a spillage of about 27% of the supplied air. Fortunately
this is a subsonic spill and not too costly in terms of spillage drag (discussed in Chapter 16). This
mismatch could have been relieved somewhat by a hinged cowl lip decreasing capture area at this cruise
condition, but that feature would add weight and complexity (cost) and was not felt justified. *[Nicolai &
Carichner, pp. 410–412]*

**Fig. 15.16** — *Engine–inlet flow matching for inlet of Fig. 15.14 and PW-F-100 engine* *[Nicolai &
Carichner, Fig. 15.16, p. 411]*. Plot of $A_\infty/A_C$ (0.4–1.0) vs. Free Stream Mach $M_\infty$
(0.4–2.4): a shaded band bounded above by "Inlet Supply"/"BL Bleed" curve and below by "Subcritical Spill
or Bypass" curve, both converging toward 1.0 near Mach 2.3–2.4 and bottoming out near 0.75–0.8 around Mach
0.8–1.2; a double-headed vertical arrow labeled "Compression Surface Spill or Critical Spill" spans the
band at low Mach; ramp angle tick marks $\theta_R = 10°, 11°, 12°, 13°, 14°$ are shown between roughly
Mach 1.3–1.7 (labeled "Normal Detached Shock" transitioning to "Oblique Shock"), and $\theta_R = 15°$
spans from about Mach 1.8 to 2.4; an "Engine Demand (max power)" curve is overlaid; a separate point
labeled "Cruise @ 70% NRT" sits at roughly ($M_\infty \approx 0.9$, $A_\infty/A_C \approx 0.53$).

The subsonic diffuser was designed to be as short as possible (included diffuser angle $2\theta_D$ of 8
deg for both side and top views) but still give tolerable pressure recovery and distortion levels. The
subsonic diffuser total pressure recovery is lower than normal (Table 15.2) mainly due to the high throat
Mach numbers and the low diffuser length-to-height ratio, $L_D/H_T = 4.9$. *[Nicolai & Carichner, p. 412]*

### References (p. 412)

[1] Liepmann, H. W., and Roshko, A., *Elements of Gasdynamics*, Wiley, New York, 1957.
[2] Ball, W. H., "Propulsion System Installation Corrections," U.S. Air Force Flight Dynamics
Laboratory, AFFDL-TR-72-147, Wright–Patterson AFB, OH, Dec. 1972.
[3] Urie, D., "Lockheed SR-71, a Supersonic/Hypersonic Research Facility," Lockheed Rept. SR-71–949,
Lockheed Advanced Development Co., 1989.
[4] Henshaw, J. T., *Supersonic Engineering*, Wiley, New York, 1962.
[5] Crosthwait, E. L., Kennon, I. G., and Roland, H. L., "Preliminary Design Methodology for
Air-Induction Systems," Technical Rept. SEG-TR-67-1, Wright–Patterson AFB, OH, Jan. 1967.
[6] Antonatos, P. P., Surber, L. E., and Stava, D. J., "Inlet/Airplane Interference and Integration,"
AGARD Rept. LS-53, NASA, Report Distribution and Storage Unit, Langley Field, VA, May 1972.

Chapter 15 extraction complete.
