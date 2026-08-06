# Chapter 22 — Trim Drag and Maneuvering Flight

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, printed
pp. 601–612 (PDF pp. 610–621). Page offset: PDF page = printed page + 9 (consistent with Ch. 20-21).

Text-layer inventory: Figs 22.1-22.5 (no sub-parts detected by regex); no tables; Eqs 22.1-22.28, with
sub-parts 22.10a-b and 22.26a-c.

## Chapter Opener (p. 601)

Photo of an A-10A Thunderbolt II banking hard in a turn, weapons visible on the wing pylons, tail number
"SP 81" visible on the vertical stabilizer. Caption *(paraphrased)*: the photo shows the A-10A's
trailing-edge-up horizontal tail deflection during the turn, noting the type's survivability strategy of
low vulnerability — described informally as being able to "take a lickin' and keep on tickin'" — with a
cross-reference to Figs. 12.2 and 12.3.

Section-list sidebar: Neutral Point; Static Margin; Aft Trim $C_L$; Canard Trim $C_L$; Tailless Aircraft
Control; Pitch Damping Coefficient; Tail & Canard Control Power.

Epigraph: "Ofttimes the most successful test is the one that failed. Most learning comes from failure. Do
not fear failure but keep the cost of failure low."

Copyright notice: Copyright © 2010 American Institute of Aeronautics and Astronautics.

## §22.1 Neutral Point and Static Margin (p. 602)

The aircraft *stick fixed neutral point* is defined as that center of gravity position where
$C_{M\alpha}=0$. It is determined by setting Eq. (21.4), (21.5), or (21.6) of Chapter 21 equal to zero and
solving for $X_w$. The $X_w$ then gives the neutral point location relative to the wing-body aerodynamic
center (see Fig. 21.4a, b, and c). Notice that the neutral point for a tailless aircraft is at the
wing-body aerodynamic center location when the inlet stability term is zero. With the center of gravity at
the neutral point the aircraft is neutrally stable. The stick fixed neutral point is essentially the total
aircraft aerodynamic center.

A convenient way to remember the location of the *neutral point* (n.p.) relative to the wing-body
*aerodynamic center* (a.c.) is that the n.p. and a.c. are coincident for a tailless aircraft; then, as you
add an aft tail or canard, the n.p. moves in the direction of the horizontal control surface. Thus, the
n.p. is behind the a.c. for an aft tail and ahead of the a.c. for a canard.

**Sidebar (p. 602)** *(paraphrased)*: notes that "canard" is the French word for hoax — when French
airplane designers first saw pictures of the Wright brothers' airplane they thought it was a hoax, because
they knew a forward control surface makes the airplane unstable and unflyable; the Wrights knew it was
unstable but also knew the pilot could easily control it. Forward control surfaces have been called
canards ever since.

The *static margin* (SM) is defined as follows:

$$SM = \frac{X_{n.p.} - X_{c.g.}}{\bar{c}} \tag{22.1}$$
*[Nicolai & Carichner, Eq. (22.1), p. 602]*

where $X_{n.p.}$ and $X_{c.g.}$ are the locations of the neutral point and aircraft center of gravity,
respectively. When the neutral point is ahead of the center of gravity the SM is negative and the aircraft
is statically unstable.

The condition of negative SM is termed *relaxed static margin* and means that, if the aircraft is
perturbed from equilibrium, the moments generated will tend to rotate the aircraft further from
equilibrium. The aircraft would be extremely sensitive as it would have the tendency to maneuver away from
equilibrium. The pilot would have a very maneuverable aircraft and would have to be controlling it all the
time; he could not relax for a second. The Sopwith Camel of Chapter 21 was such an aircraft.

The static margin and the longitudinal stability derivative are related as follows:

$$C_{M\alpha} = -\text{SM}\,C_{L\alpha_{WB}} \tag{22.2}$$
*[Nicolai & Carichner, Eq. (22.2), p. 602]*

where $C_{L\alpha_{WB}}$ is the wing-body linear lift curve slope, $m_W$.

## §22.2 Aft Tail Deflection to Trim n = 1 Flight (p. 603)

For the aft tail aircraft set the trim equation [Eq. (21.1) of Chapter 21] equal to zero:

$$0 = C_L\frac{x_w}{\bar{c}} + C_D\frac{z}{\bar{c}} + C_{M_{a.c._w}} + \frac{Tz_T}{q_\infty S_{ref}\bar{c}}
- C_{LT}\bar{V}_H\eta_T - C_{M_{c.g.inlet}} \tag{22.3}$$
*[Nicolai & Carichner, Eq. (22.3), p. 603]*

where the $C_L$ is the required wing-body $C_L$ for $n=1$. Equation (22.3) is solved for the trim load
coefficient $C_{LT}$ of the tail, where $C_{LT}$ is referenced to tail area $S_T$.

For statically stable aircraft (positive SM), this $C_{LT}$ is usually negative, that is, the tail trim
load is downward. Recalling that

$$n = \frac{\text{Lift}}{\text{Weight}} = \frac{q\left(C_L S_{ref} + \eta_T C_{LT} S_T\right)}{W}
\tag{22.4}$$
*[Nicolai & Carichner, Eq. (22.4), p. 603]*

the $C_L$ of the wing-body will have to be increased to counter the down load on the tail in order to
cruise at $n=1$. Equation (22.3) may have to be iterated several times with different values of $C_L$ to
satisfy Eq. (22.4).

The *trim drag* for $n=1$ flight is expressed as

$$D_{trim} = \eta_T q_\infty S_T K_T C_{LT}^2 \tag{22.5}$$
*[Nicolai & Carichner, Eq. (22.5), p. 603]*

The trim drag is only the drag-due-to-lift of the tail because the zero-lift tail drag coefficient is
included in the total aircraft $C_{D_0}$. If the trim is too large, that is, greater than 10% of the
aircraft drag, the designer should take steps to reduce the value of $C_{LT}$. This can be accomplished by
the following:

1. Moving the c.g. aft (closer to the neutral point)
2. Increasing the tail volume coefficient $\bar{V}_H$ by increasing $S_T$ and/or $\ell_T$ (see Fig. 21.2),
   both of which will also move the c.g. aft
3. Increasing $C_{L\alpha_T}$ by increasing tail aspect ratio (AR)

Figure 22.1 shows a typical variation of $C_{LT}$ with wing-body $C_L$ for different c.g. locations. As
the c.g. moves aft and the aircraft becomes less stable and then unstable, the tail trim load reverses from
a down load to an up load. Figure 22.1 is for a composite Light Weight Fighter (LWF) at Mach = 0.9 and
30,000 ft. Figure 22.2 shows the behavior of the total aircraft cruise drag, wing-body $C_L$, and aft tail
trim coefficient $C_{LT}$ for different c.g. locations. The advantage of negative static margin is clearly
evident in Fig. 22.2 as the total aircraft drag decreases to a minimum at an SM of about -8%. As the SM is
decreased past -8% the aircraft drag starts to increase.

**Fig. 22.1** — *Variation of aft tail trim $C_{LT}$ with aircraft $C_L$ and c.g. (composite LWF)*
*[Nicolai & Carichner, Fig. 22.1, p. 604]*. Chart of $C_{LT}$ (y-axis, "Download" above zero from -0.6 to 0,
"Upload" below zero from 0 to 0.6, i.e. inverted-download-up convention) vs aircraft $C_L$ (0.2-1.0), for
six c.g. locations labeled at their curve ends by "C.G. %MAC / %SM": 31%/+12%, 37%/+7%, 43%/+1%, 47%/-3%,
52%/-8%, 57%/-13%. An arrow labeled "C.G. Moving Aft" points from the top curve toward the bottom. Flight
condition: Mach = 0.9 at 30,000 ft. As c.g. moves aft (%SM decreases, going negative), the trim curve
shifts from download (positive SM, stable) to upload (negative SM, unstable) and the curves grow steeper
with increasing $C_L$.

**Fig. 22.2** — *Variation of aircraft drag, $C_L$, and $C_{LT}$ for LWF at $n=1$ (cruise), Mach = 0.9, and
45,000 ft* *[Nicolai & Carichner, Fig. 22.2, p. 604]*. Combined chart with c.g. location (%MAC, 20-70) and
corresponding static margin (20 to -20) as twin x-axes, and three y-axes: $C_{LT}$ (upload/download, -0.1
to 0.1+), $C_L$ (0.20-0.26), and Total Drag (lb, 1500-1800). Three curves: $C_L$ decreases roughly linearly
from ~0.26 (c.g. ~27% MAC) down to ~0.205 (c.g. ~62% MAC); $C_{LT}$ rises from a downward (negative) value
near c.g.~27% MAC through zero around c.g.~43-47% MAC to a strongly positive (upload) value near c.g.~65%
MAC; Drag decreases from ~1690 lb at c.g.~27% MAC to a broad minimum of ~1545 lb spanning roughly c.g.
45-55% MAC, then rises slightly toward ~1560 lb by c.g.~68% MAC — confirming the text's minimum-drag SM of
about -8%.

because the trim drag is increasing faster than the wing-body drag-due-to-lift is decreasing, that is,

$$\text{Drag} = qS_{ref}\left(C_{D_o} + K\,C_L^2\right) + D_{trim} \tag{22.6}$$
*[Nicolai & Carichner, Eq. (22.6), p. 605]*

Normally, aircraft fly at an SM of about +3% to +10%. Figure 22.2 indicates a cruise drag reduction of
about 3% by relaxing the SM from +5% to -8%. The overall payoff depends upon the comparison of the
decreased aircraft weight due to reduced cruise fuel through relaxed SM with the cost and weight increase
of the stability augmentation system. In the case of the F-16 there was a payoff for the relaxed SM and it
flies at a -6% SM during its Mach = 0.9 cruise.

The tail deflection depends upon the type of aft tail being used. As discussed in Chapter 21 the aft tail
can be a stabilizer-elevator arrangement or an all flying tail. If the aft tail is an all flying tail, the
expression for $C_{LT}$ is

$$C_{LT} = \left(\frac{dC_L}{d\alpha}\right)_T(\alpha_T+\alpha_{cs}) =
\left(\frac{dC_L}{d\alpha}\right)_T\left[\left(1-\frac{d\varepsilon}{d\alpha}\right)\alpha+\alpha_{cs}\right]
\tag{22.7}$$
*[Nicolai & Carichner, Eq. (22.7), p. 605]*

where $\alpha$ is the aircraft angle-of-attack and $\alpha_{cs}$ is the deflection angle for the tail. The
term $(1-d\varepsilon/d\alpha)$ is the downwash term and can be determined from Fig. 21.8. The all flying
tail is a miniature wing, and the quantity $|\alpha_T+\alpha_{cs}|$ should not exceed the stall angle for
the section.

If the horizontal tail is a stabilizer-elevator arrangement, the expression for $C_{LT}$ is

$$C_{LT} = \left(\frac{dC_L}{d\alpha}\right)_T\left[\left(1-\frac{d\varepsilon}{d\alpha}\right)\alpha+
\alpha_{0L}\right] = \left(\frac{dC_L}{d\alpha}\right)_T\left[\left(1-\frac{d\varepsilon}{d\alpha}\right)
\alpha+\frac{d\alpha_{0L}}{d\delta_e}\delta_e\right] \tag{22.8}$$
*[Nicolai & Carichner, Eq. (22.8), p. 605]*

where $\alpha_{0L}$ is the zero-lift angle for the aft tail and is similar to a flapped wing. The term
$d\alpha_{0L}/d\delta_e$ is the same as the $\tau$ of Fig. 21.14, Chapter 21. When using Fig. 21.14 for
$d\alpha_{0L}/d\delta_e$, replace $S_R/S_{VT}$ by $S_e/S_T$, where $S_e$ is the elevator area and $S_T$ is
the total horizontal tail area.

Equation (21.1) can also be expressed as

$$C_M = C_{M_0} + C_{M\alpha}\alpha + C_{M\delta}\left(\delta_e,\alpha_{cs}\right) \tag{22.9}$$
*[Nicolai & Carichner, Eq. (22.9), p. 605]*

where $C_{M\delta}$ is called the *horizontal tail power* and, for an all flying tail,

$$C_{M\delta} = -\bar{V}_H\eta_T C_{L\alpha_T} \tag{22.10a}$$
*[Nicolai & Carichner, Eq. (22.10a), p. 605]*

and, for an elevator-stabilizer arrangement,

$$C_{M\delta} = -\bar{V}_H\eta_T C_{L\alpha_T}\frac{d\alpha_{0L}}{d\delta_e} \tag{22.10b}$$
*[Nicolai & Carichner, Eq. (22.10b), p. 606]*

and $C_{M_0}$, the moment coefficient at zero $\alpha$ and control deflection, is given by

$$C_{M_0} = C_{M_{a.c._w}} + C_{D_0}\frac{z}{\bar{c}}\frac{Tz_T}{q_\infty S_{ref}\bar{c}} \tag{22.11}$$
*[Nicolai & Carichner, Eq. (22.11), p. 606]*

Using Eqs. (22.9) and (22.2), the expression for the control deflection for trimming the aircraft is

$$\alpha_{cs}, \delta_e = \frac{-C_{M_0}+(\text{SM})C_L}{C_{M\delta}} \tag{22.12}$$
*[Nicolai & Carichner, Eq. (22.12), p. 606]*

Figure 22.3 shows a typical variation of the control surface deflection required to trim the aircraft.
Notice that the most forward c.g. location is fixed by the maximum control surface deflection (usually
$\pm20$ deg). Figure 21.4b shows the sign convention for elevator deflection.

The static longitudinal stability changes with increasing Mach number. The most pronounced Mach number
effect is the rearward shift of the wing-body aerodynamic center to about the 50% mac location for
supersonic flight. This results in an aftward shift of the neutral point and

**Fig. 22.3** — *Trim $C_L$ vs elevator deflection* *[Nicolai & Carichner, Fig. 22.3, p. 606]*. Chart of
Elevator Deflection $\delta_e$ (y-axis, "Up(-)" above zero, "Down(+)" below zero) vs $C_L$ (x-axis, up to
$C_{L_{max}}$), showing four straight lines all originating from a common point on the negative
(down-deflection) y-axis labeled "Stick Fixed Neutral Point (n.p.)" at $C_L=0$, fanning out with increasing
slope as c.g. moves forward: 40%/0% (flat, zero slope — the neutral point case), 30%/+6%, 20%/+12%, and
10%/+20% (steepest). A horizontal dashed line marks "Maximum Elevator Deflection," and the point where the
steepest usable line (interpolated at 12%/+19% c.g.) crosses that limit at $C_{L_{max}}$ is labeled "Forward
c.g. Limit" — i.e., c.g. cannot be moved further forward than this point without exceeding maximum elevator
throw at $C_{L_{max}}$.

a resulting increase in the SM and aircraft stability. The designer should check the trim drag at this
increased stability condition. Sometimes the c.g. is shifted aft by fuel transfer during supersonic flight
to reduce the trim drag (see Chapter 23). Another effect is the increase of $(C_{L\alpha})_T$ at transonic
speeds and then its decrease at supersonic speeds (see Fig. 13.3a). This changes the horizontal tail
effectiveness and will make the aircraft more stable in the transonic regime and less stable
supersonically. At supersonic speeds there is also a decrease in the downwash at the tail.

## §22.3 Canard Deflection for Trim at n = 1 (p. 607)

For the canard, set the trim equation [Eq. (21.4a)] equal to zero:

$$0 = C_{M_{a.c._w}} - \frac{x_w}{\bar{c}}C_L + \frac{z}{\bar{c}}C_D + C_{L_c}\bar{V}_c +
\frac{Tz_T}{q_\infty S_{ref}\bar{c}} - C_{M_{c.g.inlet}} \tag{22.13}$$
*[Nicolai & Carichner, Eq. (22.13), p. 607]*

Equation (22.13) is solved for the canard lift coefficient $C_{L_c}$ and the resulting trim drag is

$$D_{trim} = q_\infty S_c K_c C_{L_c}^2 \tag{22.14}$$
*[Nicolai & Carichner, Eq. (22.14), p. 607]*

Because the aircraft $\alpha$ for cruise is usually small assume that nonlinear lift is negligible and

$$C_{L_c} = \left(\frac{dC_L}{d\alpha}\right)_c(\alpha-\alpha_{0L}+\alpha_c) =
\left(\frac{dC_L}{d\alpha}\right)_c+(\alpha+\alpha_c) \tag{22.15}$$
*[Nicolai & Carichner, Eq. (22.15), p. 607]*

The canard is usually symmetric so that $\alpha_{0L}=0$.

The trim equation can be expressed in a form similar to Eq. (22.9) as

$$C_M = C_{M_0} + C_{M\alpha}\alpha + C_{M\alpha_c}\alpha_c \tag{22.16}$$
*[Nicolai & Carichner, Eq. (22.16), p. 607]*

where $C_{M\alpha_c}$ is the canard control power

$$C_{M\alpha_c} = \bar{V}_c C_{L\alpha_c} \tag{22.17}$$
*[Nicolai & Carichner, Eq. (22.17), p. 607]*

and

$$C_{M_0} = C_{M_{a.c._w}} + C_{D_0}\frac{z}{\bar{c}} + \frac{Tz_T}{q_\infty S_{ref}\bar{c}} \tag{22.18}$$
*[Nicolai & Carichner, Eq. (22.18), p. 607]*

The canard deflection for trimming the aircraft is expressed as [from Eqs. (22.18) and (22.2)]

**Fig. 22.4** — *Variation of canard angle-of-attack with wing-body $C_L$ and c.g. location* *[Nicolai &
Carichner, Fig. 22.4, p. 608]*. Chart of Canard Angle-of-Attack $\alpha_c$ (y-axis, "Up(-)" above zero,
"Down(+)" below zero) vs $C_L$ (x-axis, up to $C_{L_{max}}$), four lines from a common origin on the
negative (down) y-axis labeled "Stick Fixed Neutral Point (n.p.)" at $C_L=0$: 30%/0% (flat, zero slope),
20%/+8%, 10%/+15%, 0%/+20% (steepest). A horizontal dashed line marks $\alpha_{c_{max}}$, and the
intersection of the steepest usable line (interpolated at 6%/+17% c.g.) with that limit at $C_{L_{max}}$
is labeled "Forward c.g. Limit."

$$\alpha_c = \frac{-C_{M_0}+(\text{SM})C_L}{C_{M\alpha_c}} \tag{22.19}$$
*[Nicolai & Carichner, Eq. (22.19), p. 608]*

Equation (22.19) indicates that the canard trim load is up for positive SM and reverses to a down trim
load as the c.g. moves aft and the SM decreases to zero and then becomes negative. This behavior is shown
on Fig. 22.4. Thus, the canard acts opposite to an aft tail. A down trim load works against the wing-body
lift and is undesirable, so that relaxed static margin is not as attractive for a wing-canard arrangement
as it is for a wing-aft tail configuration.

## §22.4 Control of a Tailless Aircraft at n = 1 (p. 608)

As mentioned earlier, the neutral point for a tailless aircraft is located at the wing-body aerodynamic
center. Thus, the tailless aircraft must have the center of gravity ahead of the wing-body a.c. for static
stability. This is shown on Fig. 22.5. Because the tailless aircraft does not have any horizontal control
surfaces (aft tail or canard), the moment to trim the aircraft must come from the wing moment about the
a.c. $C_{M\alpha_c}$, $C_M$ about the a.c., is changed by deflecting the wing flaps (called *elevons*) up
and down, effecting a positive or negative camber change. Figure 22.5 illustrates this. The upsweep of
the trailing edge (called *reflex camber*) produces a positive $C_{M\alpha_c}$ and balances the aircraft at
positive $C_L$.

For the tailless aircraft set the trim equation (neglecting the moment due to wing drag and inlet) equal
to zero:

$$0 = C_{M_{a.c._w}} - \frac{x_w}{\bar{c}}C_L + \frac{Tz_T}{q_\infty S_{ref}\bar{c}} \tag{22.20}$$
*[Nicolai & Carichner, Eq. (22.20), p. 609]*

As the elevon is deflected the wing lift coefficient $C_L$ changes and $C_{M_{a.c.}}$ changes. Equation
(22.20) can be rewritten as

$$0 = \left(\frac{dC_{M_{a.c.}}}{d\delta_e}\right)\delta_e - \frac{x_w}{\bar{c}}\left[\left(\frac{dC_L}
{d\alpha}\right)_w\alpha + \left(\frac{dC_L}{d\delta_e}\right)\delta_e\right] + \frac{Tz_T}
{q_\infty S_{ref}\bar{c}}$$

and the elevon deflection is expressed as

$$\delta_e = \frac{(x_w/\bar{c})(dC_L/d\alpha)_w\alpha - (Tz_T/q_\infty S_{ref}\bar{c})}
{-(x_w/\bar{c})C_{L\delta} + C_{M\delta}} \tag{22.21}$$
*[Nicolai & Carichner, Eq. (22.21), p. 609]*

The denominator is referred to as the *elevon control power* and [1, Sections 6.1.1-6.1.5; 2], can be used
to estimate $C_{L\delta}$ and $C_{M\delta}$.

The trim drag for a tailless aircraft is much different than for an aft tail or canard aircraft. A
tailless aircraft trims itself by changing the camber of

**Fig. 22.5** — *Control of a tailless aircraft by camber change* *[Nicolai & Carichner, Fig. 22.5,
p. 609]*. Chart of $C_M$ (y-axis, "(+)" up, "(-)" down) vs $C_L$ (x-axis, "(-)" left, "(+)" right), with
three straight lines of differing slope all crossing the $C_L$ axis at distinct "Trim" points (one at
negative $C_L$, two clustered near/at positive $C_L$), illustrating three camber states, each shown with a
small airfoil-section inset marking the a.c. and center-of-gravity/reference symbol location relative to
the section: "Stable, Positive $C_{m_{a.c.}}$" (upper-left region, airfoil with reflex/upturned trailing
edge, a.c. aft of the c.g. symbol) — steepest downward-sloping line, trimming at negative $C_L$;
"Unstable, Negative $C_{m_{a.c.}}$" (upper-right region, airfoil with conventional downturned/cambered
trailing edge, a.c. ahead of the c.g. symbol) — a line that curves and trims near/at positive $C_L$, with
positive slope in $C_M$ vs $C_L$ (destabilizing); "Stable, Negative $C_{m_{a.c.}}$" (lower region, airfoil
with conventional cambered trailing edge, a.c. aft of c.g.) — a shallow downward-sloping line trimming near
positive $C_L$.

the wing. Subsonically, this results in a small change in the wing separation drag and can be determined
using the method of Section 9.5.

Supersonically the elevon deflection results in a change in the wave drag. From linear theory

$$C_{D_w} = \frac{4}{\sqrt{M^2-1}}\left[\alpha^2 + \left(\overline{\frac{dh}{dx}}\right)^2 +
\overline{\alpha_c^2}\right]$$
*(unnumbered equation, p. 610)*

and by deflecting the elevon $\alpha$ and $\alpha_c^2$ are also changed. The result is

$$\frac{(C_{D_{wave}})_{\delta_e}}{(C_{D_{wave}})_{\delta_e=0}} = \left[1-\frac{c_e}{c}\right] +
\frac{c_e}{c}\frac{(\alpha+\delta_e)^2}{\alpha^2} \tag{22.22}$$
*[Nicolai & Carichner, Eq. (22.22), p. 610]*

where $c_e$ is the elevon chord and $c$ is the wing chord (including elevon).

## §22.5 Aft Tail Deflection for Maneuvering Flight — Pull-Up Maneuver (p. 610)

In a pull-up or loop maneuver the weight of the aircraft always opposes the lift vector. The aft tail
deflection, $\delta_e$ or $\alpha_{cs}$, for a pull-up maneuver is greater than $n-1$ times the trim
deflection for $n=1$ flight because of the inertial loading and pitch damping of the aircraft.

The increase in $\delta_e$ or $\alpha_{cs}$ for a pull-up maneuver of $n$ g's is given by

$$\left(\Delta\alpha_{cs}, \Delta\delta_e\right)_{maneuver} = -\frac{\left[-\text{SM}+
(\rho S_{ref}\bar{c}/4m)C_{Mq}\right](n-1)C_{L_{n=1}}}{C_{M\delta}} \tag{22.23}$$
*[Nicolai & Carichner, Eq. (22.23), p. 610]*

where $m$ is the mass of the aircraft in slugs, $\rho$ is the density in slugs per cubic foot
(slug/ft$^3$), and $C_{L_{n=1}}$ is the $C_L$ required for $n=1$ flight. The $C_{Mq}$ is the pitch damping
derivative and is determined from

$$C_{Mq} = \frac{dC_M}{d(q\bar{c}/2V)} = -2.2\eta_T\bar{V}_H C_{L\alpha_T}\frac{\ell_T}{\bar{c}}
\tag{22.24}$$
*[Nicolai & Carichner, Eq. (22.24), p. 610]*

The $C_{M\delta}$ for Eq. (22.23) is determined from Eq. (22.10a) for an all flying tail and Eq. (22.10b)
for an elevator-stabilizer arrangement. The total aft tail deflection is determined by adding the value
from Eq. (22.23) to the value for $n=1$ from Eq. (22.12). The $C_{LT}$ is determined from Eq. (22.7) or
(22.8) and the trim from Eq. (22.5).

## §22.6 Canard Deflection for Maneuvering Flight — Pull-Up Maneuver (p. 611)

The additional canard deflection to pull $n$ g's may be found from

$$(\Delta\alpha_c)_{maneuver} = -\frac{\left[-\text{SM}+(\rho S_{ref}\bar{c}/4m)C_{Mq}\right](n-1)
C_{L_{n=1}}}{\bar{V}_c C_{L\alpha_c}} \tag{22.25}$$
*[Nicolai & Carichner, Eq. (22.25), p. 611]*

where the denominator is the canard control power $C_{M\delta_c}$ [Eq. (22.17)] and the pitch damping term

$$C_{Mq} = -2.2\bar{V}_c C_{L\alpha_c}\frac{\ell_c}{\bar{c}}$$
*(unnumbered equation, p. 611)*

## §22.7 Elevon Deflection for a Tailless Aircraft in Maneuvering Flight — Pull-Up Maneuver (p. 611)

For the tailless aircraft the damping in pitch is very small compared with an aircraft with an aft tail or
canard. As a first approximation set $C_{Mq}=0$. This makes the maneuver point coincide with the neutral
point, which coincides with the aerodynamic center.

Thus,

$$(\Delta\delta_e)_{maneuver} = -\frac{\text{SM}(n-1)C_{L_{n=1}}}{-(x_w/\bar{c})C_{L\delta}+C_{M\delta}}
\tag{22.26a}$$
*[Nicolai & Carichner, Eq. (22.26a), p. 611]*

$$\Delta\delta_{e(maneuver)} = (n-1)\delta_{e_{n=1}} \tag{22.26b}$$
*[Nicolai & Carichner, Eq. (22.26b), p. 611]*

or

$$\Delta\delta_{e(total)} = n\delta_{e_{n=1}} \tag{22.26c}$$
*[Nicolai & Carichner, Eq. (22.26c), p. 611]*

where $\delta_{e_{n=1}}$ is the elevon deflection for $n=1$ flight as given by Eq. (22.21).

## §22.8 Control Deflection for Level Turn Maneuvering Flight (p. 611)

The previous discussion of maneuvering flight (i.e., Sections 22.5, 22.6, and 22.7) was for a pull-up or
loop maneuver where the weight of the aircraft always opposed the lift vector. For a level turn only a
component of the lift is equal to the weight (see Section 3.7) and thus the control deflection equations
are slightly different from those for a loop.

The increased control deflection for a level turn is given by the following:

Aft Tail:

$$(\Delta\alpha_{cs}, \Delta\delta_e)_{levelturn} = -\frac{\left[-\text{SM}(n-1)+C_{Mq}(\rho S_{ref}
\bar{c}/4m)(n-(1/n))\right]C_{L_{n=1}}}{C_{M\delta}} \tag{22.27}$$
*[Nicolai & Carichner, Eq. (22.27), p. 612]*

where $n=1/\cos\varphi$ for a level turn, $\varphi$ is the bank angle (from Fig. 3.11), $C_{Mq}$ is given
by Eq. (22.24), and $C_{M\delta}$ is given by Eq. (22.10).

Canard:

$$(\Delta\alpha_c)_{levelturn} = -\frac{\left[-\text{SM}(n-1)+C_{Mq}(\rho S_{ref}\bar{c}/4m)(n-(1/n))\right]
C_{L_{n=1}}}{\bar{V}_c C_{L\alpha_c}} \tag{22.28}$$
*[Nicolai & Carichner, Eq. (22.28), p. 612]*

where

$$C_{Mq} = -2.2\bar{V}_c C_{L\alpha_c}\frac{\ell_c}{\bar{c}}$$
*(unnumbered equation, p. 612)*

Tailless: Because the damping in pitch is negligible, the control deflection for a tailless aircraft in a
level turn is the same as Eq. (22.26).

## References (p. 612)

[1] Ellison, D. E., "USAF Stability and Control Handbook (DATCOM)," U.S. Air Force Flight Dynamics
Laboratory, AFFDL/FDCC, Wright-Patterson AFB, OH, Aug. 1968.
[2] Roskam, J., *Flight Dynamics of Rigid and Elastic Airplanes*, Univ. of Kansas, Lawrence, KS, 1972.
[Available via www.darcorp.com (accessed 31 Oct. 2009).]

Chapter 22 extraction complete.

