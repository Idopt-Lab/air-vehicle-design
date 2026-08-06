# Chapter 21 — Static Stability and Control

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, AIAA Education
Series, 2010. Chapter 21, printed pp. 575–600 (PDF pp. 584–609).

Text-layer inventory (regex scan, PDF pp. 584–609): Figs 21.1–21.15 (with sub-parts 21.2a-c, 21.4a-b,
21.15a-b), no tables, Eqs (21.1)–(21.26) (with sub-parts 21.17a-b).

## Chapter Opener (p. 575)

Photo: a WWI Sopwith Camel biplane banking in flight, RAF roundel visible on the upper wing. Section-list
sidebar: Static & Dynamic Stability Modes; Federal Regulations; Static S&C Considerations; Static
Longitudinal S&C; Static Lateral S&C; Static Directional S&C. Sidebar note: "The Sopwith Camel was
statically unstable (as was the Wright Flyer), giving it a quickness in maneuvering. It was a wonderful
machine in combat (it had more aerial victories than any other allied WWI airplane), but it killed many a
pilot who was not paying close attention to its deadly lack of stability." Epigraph: "Take your hand off
the stick and it would rear right up with a terrific jerk and stand on its tail. — Pilot report on the
Sopwith Camel." Copyright notice: © 2010 American Institute of Aeronautics and Astronautics.

## §21.1 Introduction (p. 576)

The discussion in the next three chapters assumes some familiarity with aircraft static *stability and
control* (S&C). If not, review this subject in outside texts such as [1-4] for a fundamental understanding
of static stability and control. Reference [3] is especially recommended as a companion to this text as it
has a very complete discussion of aircraft stability and control.

The axis system for the S&C discussion is shown in Fig. 21.1. An aircraft is in equilibrium if the
summation of moments about the three axes is zero. The aircraft is said to be *stable* if it returns to
equilibrium about the pitch, roll, and yaw axes when disturbed. The aircraft has *static stability* if it
"tends" to return to equilibrium by itself. In other words, the resulting forces and moments from the
disturbance push the aircraft toward its original equilibrium state. This static stability will fight the
disturbance, making it difficult to move away from the equilibrium condition. Thus, a high degree of static
stability will make it hard to maneuver the aircraft. The aircraft has *dynamic stability* if the actual
motion of the unsteady forces and moments returns the aircraft (eventually) to its original equilibrium
condition.

Figure 21.2 shows an aircraft system disturbed in pitch. In Fig. 21.2a the aircraft has neutral stability
and remains at whatever $\alpha$ the disturbance produces. Figure 21.2b shows an unstable system because
the tendency of the system is to diverge. In Fig. 21.2c the aircraft has static stability with very high
damping, giving it dynamic stability as well. The aircraft slowly returns to its original $\alpha$ without
any overshoot. Figure 21.2d shows a more

**Fig. 21.1** — *Major nondimensional aerodynamic parameters and sign convention* *[Nicolai & Carichner,
Fig. 21.1, p. 576]*. Fighter-aircraft 3-view-style wireframe with body axes drawn: Longitudinal Axis (x,
through nose-tail, with roll moment $\mathcal{L}$), Lateral Axis (through wingtips, with pitching moment
$M$), Vertical Axis (z, with yawing moment $N$), all positive per the right-hand rule; Center of Gravity,
Wing aerodynamic center (a.c.), and Aircraft neutral point (n.p.) marked along the mac line. Force axes
(Lift $L$, Drag $D$, Sideforce $Y$) shown at the aircraft's velocity vector. Side callout lists:

*Forces*: $C_L=L/qS_{ref}$; $C_D=D/qS_{ref}$; $C_Y=Y/qS_{ref}$
*Moments*: $C_M=M/qS_{ref}\bar{c}$; $C_\ell=\mathcal{L}/qS_{ref}b$; $C_n=N/qS_{ref}b$
*Derivatives*: $C_{L_\alpha}=\Delta C_L/\Delta\alpha$; $C_{M_\alpha}=\Delta C_M/\Delta\alpha$;
$C_{n_\beta}=\Delta C_n/\Delta\beta$; $C_{\ell_\beta}=\Delta C_\ell/\Delta\beta$;
$C_{Y_\beta}=\Delta C_Y/\Delta\beta$
*Effectiveness*: $C_{M_{\delta e}}=\Delta C_M/\Delta_{elev}$; $C_{\ell_{\delta a}}=\Delta C_\ell/
\Delta_{aileron}$; $C_{n_{\delta r}}=\Delta C_n/\Delta_{rudder}$

Footnotes: $q$ = Dynamic Pressure = $\frac{1}{2}\rho V^2$; "Reference Areas and Lengths Are Just
That — *References*"; "Positive moments are based on the 'right-hand-rule'."

**Fig. 21.2** — *Static and dynamic stability about the pitch axis* *[Nicolai & Carichner, Fig. 21.2,
p. 577]*. Five $\alpha$-vs-Time response sketches, each showing a "dynamic" oscillatory curve superimposed
on a "static" trend arrow:
- **(a) Neutrally Stable**: constant-amplitude oscillation about a flat (horizontal) static trend.
- **(b) Unstable**: oscillation about a static trend diverging upward.
- **(c) Stable, Highly Damped**: oscillation amplitude decaying quickly, static trend decaying smoothly to
  a steady value with no overshoot.
- **(d) Stable, Lightly Damped**: oscillation amplitude decaying slowly, static trend gradually settling.
- **(e) Statically Stable, Dynamically Unstable**: oscillation amplitude growing over time even though the
  static trend is flat/restoring.

typical aircraft response. The aircraft returns to its original state, but experiences overshoot with a
converging oscillation. This is acceptable behavior, provided the time to converge is reasonable. In
Fig. 21.2e the restoring forces and moments are in the right direction so the aircraft is statically
stable. However, the restoring forces and moments are high and the damping is low, so the aircraft
overshoots the original equilibrium condition. These restoring forces and moments then push the nose back
up, overshooting again, but with increasing amplitude. The pitch oscillations continue to increase in
amplitude until the system diverges into an uncontrollable flight mode. It should be obvious that static
stability is a necessary but not sufficient condition for dynamic stability.

The degree of dynamic instability is the "time to double amplitude ($t_2$)" for the system. If the $t_2$ is
large compared with the reaction of the control system, then the aircraft would have acceptable flying
qualities. The 1903 Wright Flyer had a $t_2$ of about 30 seconds for the pitch axis, which permitted Wilbur
and Orville to arrest the divergent motion with a pitch control input and fly the aircraft safely. Most
aircraft have an unstable lateral mode, the *spiral divergence*. This divergence mode is so slow that the
pilot has ample time to make the minor roll correction needed to prevent it.

The strategy of modern flight control systems is to design for low static stability (in fact near neutral
stability) and then augment the stability of the aircraft by electronic systems. The *stability
augmentation system* (SAS) consists of sensors (rate gyros and accelerometers to sense the movement away
from equilibrium), computers (to analyze the aircraft motion and determine the correct control input to
counter the aircraft motion), and servos (to input the control deflection to the control surface). These
active
controls control the aircraft's rapid perturbations from an equilibrium position and make possible the
practicality of the unstable aircraft.

A dynamically unstable aircraft would be a very maneuverable aircraft. This was indeed the case for the
WWI-era Sopwith Camel (a 1917 British biplane, pictured on the first page of this chapter), as described by
V. M. Yeates in his novel *Winged Victory*.

**Block quote (paraphrased), p. 578**: Yeates describes the Camel's instability as the source of its
quickness in maneuver — a stable aircraft resists being moved out of trimmed flight, while the Camel (nose
light due to its low-weight rotary engine, and rigged tail-heavy) had to be actively held in level flight at
all times, rearing up sharply the instant the stick was released. Its bottom-wing-only dihedral gave it a
distinctive silhouette recognizable from miles away. These same unorthodox traits that made it a formidable
dogfighter also meant it could neither pursue nor flee effectively, since it lacked the speed to do either.

## §21.2 Federal Regulations (p. 578)

Aircraft operating in the United States must conform to regulations. Commercial aircraft must follow the
following federally mandated regulations:

1. **FAR 23.** Airworthiness standards for small airplanes in the normal, utility, and acrobatic categories
   that have passenger seating of nine seats or fewer. Paragraph 23.171—The airplane must be
   longitudinally, directionally, and laterally stable. In addition, the airplane must show suitable
   stability and control "feel" (static stability) in any condition normally encountered in service.

2. **FAR 25.** Airworthiness standards for transport category airplanes. Paragraph 25.171—The airplane must
   be longitudinally, directionally, and laterally stable. In addition, the airplane must show suitable
   stability and control "feel" (static stability) in any condition normally encountered in service.

Military aircraft must follow the following specifications and standards:

1. **MIL-F-8785C (1980).** Flying Qualities of Piloted Airplanes. (Inactive 1996 for new design and no
   longer used) Although inactive the document contains much good design data, theories, and information on
   aircraft handling and flying qualities [5].

2. **MIL-HDBK-1797 (1997).** Flying Qualities of Piloted Aircraft. This document replaced MIL-F-8785C and
   MIL-STD-1797. It contains requirements for qualitative and quantitative flying qualities for all military
   aircraft, latest theories, and information relating to pilot opinion. In addition to requirements for
   handling qualities, it also specifies other requirements that an aircraft must meet, such as operational
   missions, external stores, configurations, and flight envelopes. This handbook also applies to piloted
   transatmospheric flight when flight depends upon aerodynamic lift and/or air-breathing propulsion
   systems.
3. **MIL-F-9490.** Flight Control Systems—Design, Installation and Test for Piloted Aircraft
4. **MIL-F-1873.** Flight Control Systems—Design, Installation and Test for Aircraft
5. **MIL-C-18244.** Control and Stabilization Systems, Automatic for Piloted Aircraft
6. **MIL-F-83300.** Flying Qualities of Piloted V/STOL Aircraft
7. **MIL-H-850.** Flying Qualities of Military Rotorcraft

All of these documents require dynamically stable aircraft—either inherently stable (passive) or augmented
with an SAS.

## §21.3 Static Stability and Control Considerations (p. 579)

The purpose of the next three chapters is to size and design the aircraft control surfaces and to determine
the trim drags. The criteria and methodology presented will be based upon static considerations only.
Dynamic stability and control analysis is usually reserved for the preliminary design phase because it
requires information about the design that is not available during the conceptual design phase. For
example, the moments of inertia introduced in Chapter 20 require knowledge of the aircraft mass
distribution on all three axes. These are design details that are not generally known at this point.

Static stability and control considerations will permit the designer to assess the configuration layout and
balance of his design and size the surfaces for adequate stability and control margins. The dynamic
analysis in the preliminary design phase will fine tune the configuration.

The discussions of longitudinal, directional, and lateral motion will center about the body axes shown in
Fig. 21.1.

The mean aerodynamic chord of a wing, denoted by $\bar{c}$ or mac, represents an average chord that, when
multiplied by the average section moment coefficient, dynamic pressure, and reference wing area, gives the
moment for the entire wing. The mac for wings of constant taper and sweep is given by

$$\bar{c} = \frac{2}{3}c_r\left[\frac{1+\lambda+\lambda^2}{1+\lambda}\right]$$
*(unnumbered equation, p. 580)*

where $c_r$ is the root chord and $\lambda$ is the wing taper ratio.

The aerodynamic center (a.c.) is that point on an aircraft, wing, or airfoil section about which the
pitching moment is independent of angle-of-attack. The aerodynamic center is the most convenient place to
locate the lift, drag, and moment of an aircraft wing or airfoil section. This is obvious from stability
considerations because $dC_{m_{a.c.}}/d\alpha=0$ and it is one less term to worry about.

For most aircraft, the body contributes a small amount of lift compared with the wing, resulting in the
total aircraft a.c. location being very close to the wing a.c. This is not the case for missiles (where the
body is large relative to the wing) and contribution of the body pressure distribution must be considered
in locating the missile a.c.

The theoretical position of the aerodynamic center on the mean aerodynamic chord is presented in Fig. 21.3.
Notice that at low speed the a.c. is approximately at the quarter-chord and moves aft for supersonic
flight. Figures H.8 and H.9 of Appendix H present experimental data on the a.c. location as a function of
Mach number for many different low aspect ratio (AR) wing-body combinations.

## §21.4 Static Longitudinal Stability and Control (p. 580)

The forces and moments acting on an aircraft are shown in Fig. 21.4. The lift and drag are by definition
always perpendicular and parallel to $V_\infty$, respectively. It is, therefore, inconvenient to use these
forces to obtain moments because their moment arms relative to the center of gravity vary with
angle-of-attack $\alpha$. For this reason, all forces are resolved into normal, $N$, and chordwise, $C$,
forces whose axes remain fixed with the aircraft and whose arms are, therefore, constant:

$$N = L\cos\alpha + D\sin\alpha$$
$$C = D\cos\alpha - L\sin\alpha$$
*(unnumbered equations, p. 580)*

For small $\alpha$, $N\approx L$ and $C\approx D$. For this discussion consider $\alpha$ to be small and use
$L$ and $D$ in the development of stability and trim equations.

The moments are summed about the center of gravity for each aircraft. The horizontal tail or canard is
usually a symmetric section so that $M_{a.c._c}=0$ and $M_{a.c._T}=0$ for $\delta_e=0$. In Fig. 21.4a, b,
and c moments have been neglected due to the fuselage and engine nacelles.

**Fig. 21.3** — *Theoretical chordwise position of the aerodynamic center (data from [6])*
*[Nicolai & Carichner, Fig. 21.3, p. 581]*. Three panels, each plotting nondimensional a.c. location
$h_{nW}\bar{c}$ (fraction of mac, vertical axis) vs. $\text{AR}\sqrt{1-M^2}$ (subsonic, left half of
horizontal axis, 7 to 0) and $\text{AR}\sqrt{M^2-1}$ (supersonic, right half, 0 to 7), for a family of
curves parameterized by $\text{AR}\tan\Lambda_{1/2}$ (values 0 through 6), each panel for a different wing
taper ratio $\lambda$:

- **$\lambda=0.25$ panel** (top-left, vertical axis 0.1-0.6): curves for $\text{AR}\tan\Lambda_{1/2}=0$
  through 6 start at various subsonic values (~0.15-0.4 at $\text{AR}\sqrt{1-M^2}=7$), most converge/dip
  toward a common region near $M=1$ (the origin), then rise together through the transonic/supersonic
  region, leveling off around 0.5-0.6 by $\text{AR}\sqrt{M^2-1}=5$-7 (curve 0 lowest, curve 6 highest at
  large supersonic parameter).
- **$\lambda=0.50$ panel** (top-right, vertical axis 0.1-0.6): similar family of curves for
  $\text{AR}\tan\Lambda_{1/2}=0$ through 6, with curve 0 dipping sharply to a minimum near 0.1 close to
  $M=1$, all curves converging and rising together through the transonic region to level off near 0.5 in
  the supersonic region.
- **$\lambda=1.0$ panel** (bottom-left, vertical axis 0.1-0.5): curves for $\text{AR}\tan\Lambda_{1/2}=0$
  through 4, with curve 0 (and nearby curves) dipping steeply to a sharp minimum near 0.05-0.1 right at
  $M=1$, then rising very steeply through the transonic region to level off near 0.45-0.5 in the supersonic
  region; higher-$\text{AR}\tan\Lambda_{1/2}$ curves dip less sharply.

Each panel's inset sketch shows a swept trapezoidal wing planform with sweep angle $\Lambda_{1/2}$ (half-
chord sweep) and the a.c. height $h_{nW}\bar{c}$ marked relative to the mac $\bar{c}$.

**Fig. 21.4** — *Forces and moments acting on a) an aircraft with a canard tail, b) an aircraft with an aft
tail, and c) a tailless aircraft* *[Nicolai & Carichner, Fig. 21.4, p. 582]*.

**(a) Canard configuration**: Canard airfoil section at left with $V_\infty$ incoming at angle $\alpha_c$,
showing normal force $N_C$, chord force $C_C$, and moment $M_{ac_C}$ about the canard a.c.; wing-body
airfoil section at right with incidence $\alpha_i$ and wing angle $\alpha_w$, showing $N_{WB}$, $C_{WB}$,
$M_{ac_{WB}}$ about the wing-body a.c.; center-of-gravity symbol with moment $M_{cg}$, weight $W$ acting
down, and engine thrust $T$ at angle $\alpha$ producing normal force $N_E$; distances $\ell_c$ (canard a.c.
to c.g.), $x_w$ (c.g. to wing-body a.c.), $z_T$ (engine thrust line offset), $\ell_i$ (engine to c.g.).
Sign convention inset (+ z down, + moment nose-up/counterclockwise as drawn). Notes: "All distances are
positive as shown"; for small $\alpha$, $N=L=C_L q S_{ref}$, $C=D=C_D q S_{ref}$; Canard Volume Coefficient
$\bar{V}_C = \ell_c S_c/(\bar{c}S_{ref})$.

**(b) Aft-tail configuration**: Wing-body airfoil section at left with $V_\infty$ at angle $\alpha$, showing
$L_W$, $D_W$, resolved into $N_W$, $C_W$, and moment $M_{a.c._W}$; downwash geometry at tail showing
$V_{\infty_T}$ at angle $\alpha_T$ offset from $V_\infty$ by downwash angle $\epsilon_T \approx
\tan^{-1}(w_T/V_\infty)$; tail airfoil section at right with elevator deflection $-\delta_e$ shown, giving
$N_T$, $C_T$, $M_{a.c._T}$; c.g. with moment $M_{c.g.}$, weight $W$, engine thrust $T$ and $N_E$; distances
$x_w$, $z_T$, $\ell_T$ (tail a.c. to c.g.). Tail Volume Coefficient $\bar{V}_H = \ell_T S_T/
(\bar{c}S_{ref})$. Note: "Wing and tail chord lines are parallel to fuselage reference line."

**(c) Tailless configuration**: A single swept/tapered wing-body planform with $V_\infty$ at angle
$\alpha_{WB}$, showing $N_{WB}$, $C_{WB}$, $M_{a.c._{WB}}$ about the wing-body a.c., trailing-edge elevon
deflection $-\delta_e$ at the tip; c.g. with moment $M_{c.g.}$, weight $W$, engine $T$/$N_E$; distances
$x_w$, $z_T$, $\ell_i$. Tail Volume Coefficient $\bar{V}$ = 0 (no separate tail surface). Notes: "All
distances are positive as shown"; $\epsilon_T$ = tail downwash angle due to wing downwash $w_T$ at the tail
a.c.; for small $\alpha$, $N=L=C_L q S_{ref}$, $C=D=C_D q S_{ref}$.

The moment or trim equations are usually placed in coefficient form by dividing through by
$(q_\infty S_{ref}\bar{c})$, where $q_\infty$ is the dynamic pressure ($\frac{1}{2}\rho V^2$), $S_{ref}$ is
the wing reference area, and $\bar{c}$ is the mac of the wing. Now, replace the wing by its mac and locate
the lift, drag, and moment of the wing at the aerodynamic center a.c.

Trim equations for the three aircraft types shown in Fig. 21.4a-c are as follows:

Aft Tail:

$$C_{M_{c.g.}} = C_L\frac{x_w}{\bar{c}} + C_D\frac{z}{\bar{c}} + C_{M_{a.c._w}} +
\frac{Tz_T}{q_\infty S_{ref}\bar{c}} - c_{LT}\bar{V}_H\eta_T - C_{M_{c.g.\cdot inlet}} \tag{21.1}$$
*[Nicolai & Carichner, Eq. (21.1), p. 583]*

Canard:

$$C_{M_{c.g.}} = -C_L\frac{x_w}{\bar{c}} + C_D\frac{z}{\bar{c}} + C_{M_{a.c._w}} +
\frac{Tz_T}{q_\infty S_{ref}\bar{c}} + c_{LC}\bar{V}_C - C_{M_{c.g.\cdot inlet}} \tag{21.2}$$
*[Nicolai & Carichner, Eq. (21.2), p. 583]*

Tailless:

$$C_{M_{c.g.}} = -C_L\frac{x_w}{\bar{c}} + C_D\frac{z}{\bar{c}} + C_{M_{a.c._w}} +
\frac{Tz_T}{q_\infty S_{ref}\bar{c}} - C_{M_{c.g.\cdot inlet}} \tag{21.3}$$
*[Nicolai & Carichner, Eq. (21.3), p. 583]*

In these equations the moment due to the aft tail or canard drag is much smaller than the wing counterpart
and was neglected. The term $q_{\infty T}/q_\infty$ is called the *tail efficiency factor* $\eta_T$ and
comes about because of the influence of the wing on the freestream velocity striking the tail. The wing
induces a downwash $w_T$ (due to trailing vortices) at the a.c. of the aft tail (see Fig. 21.4b). Notice
that $\eta_T = 1.0$ for the canard. The term $(C_{M_{c.g.}})$ inlet comes about because of the momentum
change in turning the air into the inlet. At small $\alpha$, this term can be neglected.

Often, $z \ll c$ so that the wing-body drag moment can be neglected. Also, if $z_T$ is small, the thrust
term is negligible.

The aircraft must be able to set the trim equation equal to zero for any attitude or flight condition and
all thrust levels. The wing primarily establishes the load factor for the aircraft and the aft tail or
canard balances the aircraft. If the aircraft is tailless, the moments about the aircraft c.g. are balanced
by changing the wing camber (flap deflection), which changes the moment about the wing a.c. The horizontal
tail (aft tail and canard) is movable, either all movable (all flying aft tail or canard) or a portion
(called the *elevator* on an aft tail) is movable, so that $L_T$ or $L_c$ can be changed independently of
the aircraft angle-of-attack. In this way, the horizontal tail can
cause the aircraft to rotate from one equilibrium (trimmed) condition to another (i.e., change
angle-of-attack $\alpha$).

If the horizontal aft tail is an all-flying-tail (such as the B-52, 727, and L1011), then the expression for
$C_{LT}$ is

$$C_{LT} = m_T(\alpha_T+\alpha_{cs}) = m_T\left[(1-d\varepsilon/d\alpha)\alpha+\alpha_{cs}\right]$$
*(unnumbered equation, p. 584)*

where $\alpha_{cs}$ is the deflection angle that the pilot initiates by moving the control stick, and
$d\varepsilon/d\alpha$ is the change in downwash angle $\varepsilon$ for a change in $\alpha$. The $m_T$ is
the horizontal tail lift curve slope, $(C_{L\alpha})_T$.

If the horizontal tail is a stationary stabilizer-movable elevator arrangement, then the expression for
$C_{LT}$ is

$$C_{LT} = m_T\left[(1-d\varepsilon/d\alpha)\alpha - \alpha_{0L_T}\right]$$
*(unnumbered equation, p. 584)*

where $\alpha_{0L_T}$ is the tail angle for zero lift (see Fig. 2.1a or Table F.1) and is dependent upon the
elevator deflection $\delta_e$ (note, same as for a flapped airfoil).

If the trim equations (21.1), (21.2), and (21.3) are differentiated with respect to $\alpha$, the results
are as follows:

Aft Tail:

$$\frac{dC_{M_{c.g.}}}{d\alpha} = C_{M\alpha} = m_w\frac{x_w}{\bar{c}} -
m_T\left(1-\frac{d\varepsilon}{d\alpha}\right)\bar{V}_H\eta_T + C_{M\alpha I} \tag{21.4}$$
*[Nicolai & Carichner, Eq. (21.4), p. 584]*

Canard:

$$C_{M\alpha} = \bar{V}_c m_c - \frac{x_w}{\bar{c}}m_w + C_{M\alpha I} \tag{21.5}$$
*[Nicolai & Carichner, Eq. (21.5), p. 584]*

Tailless:

$$C_{M\alpha} = -\frac{x_w}{\bar{c}}m_w + C_{M\alpha I} \tag{21.6}$$
*[Nicolai & Carichner, Eq. (21.6), p. 584]*

where $m_w=(C_{L\alpha})_w$ is the wing-body lift curve slope, $m_c=(C_{L\alpha})_c$ is the canard lift
curve slope (based upon canard surface area, $S_c$), $m_T=(C_{L\alpha})_T$ is the aft tail lift curve slope
(based upon aft tail area, $S_T$) and $(C_{M\alpha})_I$ is the change in inlet moment due to $\alpha$. In
Eqs. (21.4), (21.5), and (21.6) the term
due to the wing-body has been neglected. The thrust term disappears because the thrust is not (at least to
a first-order approximation) a function of $\alpha$.

The criterion for static stability in an aircraft is that its value of $C_{M\alpha}$ be negative. This
means that if an aircraft with $C_{M\alpha}<0$ is in equilibrium (trimmed) at a positive $\alpha$ and
suddenly $\alpha$ is increased (e.g., wind gust), the aircraft will generate a negative moment to push the
nose down toward the original equilibrium $\alpha$.

The inlet term in the trim and stability equation comes about because of the moment generated about the
center of gravity when the freestream air is turned at the inlet lip into the engine. The force diagram is
shown schematically in Fig. 21.5.

The inlet force $N_E$ can be expressed as

$$N_E = \dot{m}_0\Delta V = \dot{m}_0 V_\infty\tan\beta \approx \dot{m}_0 V_\infty\beta$$
*(unnumbered equation, p. 585)*

where $\dot{m}_0$ is the mass flow of air into the inlet in slugs per second and $\beta$ is the flow turning
angle in radians shown in Fig. 21.5. The moment about the center of gravity is $\ell_i N_E$ and is positive
for the aircraft in Fig. 21.5. The moment and stability contribution from the inlet is finally expressed as

$$C_{M_{c.g.\cdot inlet}} = \frac{N_E\ell_i}{q_\infty S_{ref}\bar{c}} \approx
\frac{2\dot{m}_0\beta\ell_i}{\rho V_\infty S_{ref}\bar{c}} \tag{21.7}$$
*[Nicolai & Carichner, Eq. (21.7), p. 585]*

$$\left(\frac{dC_M}{d\alpha}\right)_I = C_{M\alpha_{inlet}} \approx
\frac{2\dot{m}_0\beta\ell_i}{\rho V_\infty S_{ref}\bar{c}}\frac{d\beta}{d\alpha} \quad(\text{per radian})
\tag{21.8}$$
*[Nicolai & Carichner, Eq. (21.8), p. 585]*

Subsonically, $d\beta/d\alpha \geq 1$ (for inlet ahead of wing). Supersonically, $d\beta/d\alpha = 1$.

**Fig. 21.5** — *Schematic of inlet force on aircraft* *[Nicolai & Carichner, Fig. 21.5, p. 585]*.
Fighter-aircraft side-view wireframe with $V_\infty$ approaching at angle $\alpha$, a "Subsonic Streamline"
curving up into the inlet, flow-turning angle $\beta$ marked between the streamline and the inlet-normal
direction, inlet normal force $N_E$ acting upward at the inlet face, c.g. marked $M_{c.g.}$, and distance
$\ell_i$ from inlet to c.g. Sign convention inset (+ per right-hand rule).

where $\dot{m}_0$ = mass flow rate of air accepted by the inlet (slug/s); $\bar{c}$ = mean aerodynamic
chord (ft); $\rho$ = air density (slug/ft³); $V_\infty$ = freestream velocity (ft/s); $S_{ref}$ = wing area
(ft²); $\ell_i$ = distance of the inlet face ahead of the aircraft c.g. (ft); $d\beta/d\alpha$ = change in
flow direction into the inlet due to upwash of the wing.

Note the following:

1. If the inlet is under the wing as for the F-18, the wing turns the airflow into the inlet and there is
   no inlet moment. For this inlet location use $\beta=0$ and $d\beta/d\alpha=0$.

**Fig. 21.6** — *Lockheed Jetstar with inlet behind the wing* *[Nicolai & Carichner, Fig. 21.6, p. 586]*.
Photo of a Lockheed JetStar II business jet in flight, registration N711Z, showing its four aft-fuselage
podded engines mounted behind and below the wing trailing edge.

2. For inlets behind the wing trailing edge (such as the JetStar in Fig. 21.6) $d\beta/d\alpha$, may be
   analyzed as

$$\left(1-\frac{d\varepsilon}{d\alpha}\right)\frac{x_i}{\ell_h}$$
*(unnumbered equation, p. 586)*

   where $x_i$ is the distance from the wing trailing edge to the inlet and $\ell_h$ is the length from the
   wing trailing edge to the horizontal tail mean aerodynamic chord.

3. For inlets ahead of the wing leading edge $d\beta/d\alpha=1$ for supersonic flight and may be determined
   from Fig. 21.7 for subsonic speeds.

The tail downwash term for an aft-tail aircraft, $(1-d\varepsilon/d\alpha)$, depends largely on the location
of the tail with respect to the wing and the position of the horizontal tail with respect to the wing wake.
If the horizontal tail is positioned so that it lies either close to or inside the wing wake, large changes
in downwash occur, as well as reduced tail efficiency and unpleas-
ant tail buffeting. In the usual design the horizontal tail is kept high enough (or low enough) to avoid
the wing wake at all lift coefficients. If this is done, a simplified empirical method, developed from [8],
is available to estimate the change of downwash with $\alpha$ at the aft horizontal tail. The method is
shown in Fig. 21.8. If increased accuracy is desired, the methods in [9] should be used.

**Fig. 21.7** — *Change in flow direction into the inlet due to upwash of the wing (data from [7])*
*[Nicolai & Carichner, Fig. 21.7, p. 587]*. Plot of $d\beta/d\alpha$ (vertical axis, 1-4) vs. Distance from
Inlet to Wing Leading Edge$/\bar{c}_{wing}$ (horizontal axis, 0-2.4). A single curve starts near 4 at zero
distance and decays steeply (hyperbola-like) toward an asymptote near 1.1-1.2 by a distance ratio of about
1.6-2.4.

## §21.5 Static Lateral Stability and Control (p. 587)

The lateral motion for an aircraft is the rolling motion about the fuselage centerline. This lateral motion
is shown in Fig. 21.9 with the rolling moment $\mathcal{L}$ being defined as positive for the right wing
down. The rolling moment coefficient is $C_\ell$ (forgive the confusion with section lift coefficient) and
is defined as

$$C_\ell = \frac{\mathcal{L}}{qS_{ref}b} \tag{21.9}$$
*[Nicolai & Carichner, Eq. (21.9), p. 587]*

where $b$ is the aircraft wing span. The static lateral stability derivative is

$$\frac{dC_\ell}{d\beta} = C_{\ell\beta}$$
*(unnumbered equation, p. 587)*

which gives the change of rolling moment coefficient with respect to sideslip angle $\beta$. A negative
$C_{\ell\beta}$ will cause the right wing to come up for a positive sideslip and is the requirement for
lateral static stability. Static lateral stability by itself does not guarantee dynamic lateral stability,
but it is a necessary condition. The stability derivative $C_{\ell\beta}$ is influenced by the wing, the
vertical stabilizer, and the wing-fuselage interaction. $C_{\ell\beta}$ can be expressed as

**Fig. 21.8** — *Downwash charts for various taper ratios (TR) (data from [8])* *[Nicolai & Carichner,
Fig. 21.8, p. 588]*. Geometry inset: an airfoil "Zero lift line" at angle $\alpha_{0L}$ to the root-chord
reference line, with $\bar{c}/4$ marked at the wing quarter-chord; a horizontal tail shown aft and above,
offset by vertical height $\hat{z}\,b/2$ and horizontal distance $\hat{\ell}\,b/2$ from the wing.

Nine sub-plots (3 taper-ratio rows × 3 aspect-ratio columns), each plotting $d\varepsilon/d\alpha$
(vertical axis, 0.1-0.7) vs. $\hat{\ell}$ (horizontal axis, 0.50-1.25), with three curves per plot for
$\hat{z}=0$, 0.1, 0.2 (top to bottom) and a small wing-planform icon (taper shape) in the corner indicating
the row's taper ratio:

- **Row TR=$c_T/c_R$=1.0** (rectangular-wing icon): columns AR=6, AR=9, AR=12. All three curves decrease
  mildly from about 0.4-0.5 at $\hat{\ell}=0.5$ to about 0.15-0.3 at $\hat{\ell}=1.25$, with higher AR
  giving lower $d\varepsilon/d\alpha$ overall.
- **Row TR=$c_T/c_R$=0.33** (tapered-wing icon): columns AR=6, AR=9, AR=12. Curves start higher (up to 0.7
  at $\hat{\ell}=0.5$, $\hat{z}=0$) and decrease more steeply than the TR=1.0 row, again with higher AR
  giving lower values.
- **Row TR=$c_T/c_R$=0.20** (highly-tapered-wing icon): columns AR=6, AR=9, AR=12. Similar shape to the
  TR=0.33 row, curves again starting near 0.7 at $\hat{\ell}=0.5$ and decreasing to roughly 0.2-0.35 by
  $\hat{\ell}=1.25$.

In every sub-plot, larger $\hat{z}$ (tail further above the wing chord plane) gives lower $d\varepsilon/
d\alpha$, and larger $\hat{\ell}$ (tail further aft) also gives lower $d\varepsilon/d\alpha$.

**Fig. 21.9** — *Lateral motion of an aircraft and notation for lateral analysis* *[Nicolai & Carichner,
Fig. 21.9, p. 589]*. Front view of an F-35-like fighter with rolling moment $+\mathcal{L}$ shown as a
curved arrow about the longitudinal (x) axis, $z_v$ marked as the height of the vertical tail mac above the
$y$-axis, "mac of Vertical Tail" labeled. Photo of an F-35 in flight below. Plan view of the same aircraft
with incoming $V_\infty$ at sideslip angle $+\beta$ from the $x$-axis, "Wing mac," "mac of Vertical Tail,"
and "mac of Horizontal Tail" all called out with dashed reference lines, and wing semispan $b/2$ dimensioned
at the trailing edge.

$$C_{\ell\beta} = C_{\ell\beta_{wing}} + C_{\ell\beta_{vertical\ stabilizer}} +
C_{\ell\beta_{wing\text{-}fuselage}} \tag{21.10}$$
*[Nicolai & Carichner, Eq. (21.10), p. 589]*

Now consider the contribution of each component separately.

First, the wing contribution $C_{\ell\beta_{wing}}$ has three components: the basic wing planform, the
sweepback, and the dihedral,

$$C_{\ell\beta_{wing}} = C_{\ell\beta_{basic}} + C_{\ell\beta\Delta} + C_{\ell\beta\Gamma} \tag{21.11}$$
*[Nicolai & Carichner, Eq. (21.11), p. 589]*

The wing contribution due to the basic wing and sweepback is presented on Fig. 21.10. Notice that the
contribution is negative (i.e., stabilizing) and dependent upon the flight $C_L$. Extrapolate the data on
Fig. 21.10 for a delta wing (i.e., $\lambda=0$).

The wing contribution due to dihedral is stabilizing for positive dihedral and its use is the most common
way of controlling lateral stability. The expression for the dihedral contribution is given as (from [9])

$$(C_{\ell\beta})_\Gamma = -0.25C_{L\alpha}\Gamma\left[\frac{2(1+2\lambda)}{3(1+\lambda)}\right]
\tag{21.12}$$
*[Nicolai & Carichner, Eq. (21.12), p. 589]*

where the lift curve slope $C_{L\alpha}$ is per radian and $\Gamma$ is in radians.

**Fig. 21.10** — *The $C_{\ell\beta}$ of straight tapered wings with zero dihedral* *[Nicolai & Carichner,
Fig. 21.10, p. 590]*. Two stacked charts of $-(C_{\ell\beta})_w/C_L$ (per radian) vs Wing Aspect Ratio
(0-8), each a family of curves by quarter-chord sweep $\Lambda_{1/4}$, with a wing-planform inset defining
$c_r$, $c_t$, $b$, $\Lambda_{1/4}$:
- Top chart, $\lambda=1.0$: curves for $\Lambda_{1/4}=$ 0, 10, 20, 30, 40, 45 (dashed), 50, 55 (dashed), 60
  deg. All curves start near AR=1 at values from ~0.7 (0 deg) to ~0.86 (60 deg), fall steeply through
  AR=2-4, then flatten by AR=6-7 to asymptotic values *(read from plot)*: 60 deg -> ~0.60, 55 deg -> ~0.44,
  50 deg -> ~0.36, 45 deg -> ~0.30, 40 deg -> ~0.25, 30 deg -> ~0.15, 20 deg -> ~0.09, 10 deg -> ~0.05,
  0 deg -> ~0.03.
- Bottom chart, $\lambda=0.5$: curves for $\Lambda_{1/4}=$ 0, 10, 20, 30, 40, 45 (dashed) deg, same general
  shape, asymptotic values by AR=7 *(read from plot)*: 45 deg -> ~0.28, 40 deg -> ~0.23, 30 deg -> ~0.15,
  20 deg -> ~0.09, 10 deg -> ~0.05, 0 deg -> ~0.03.

In actual practice, the dihedral angle is usually not set from analytical considerations, because of the
large errors involved. Most designers set the wing dihedral only after careful analysis of wind tunnel test
data, in which the effects of angle-of-attack, power, and flap settings are carefully analyzed.

Consideration might also be given to using [9, Section 5.1.2.1-1] in determining $C_{\ell\beta_{wing}}$.
This reference combines both the dihedral and sweepback effects to provide an empirical method for
obtaining the desired stability derivative.

Second, $C_{\ell\beta_{wing-fus}}$ is obtained empirically from [2] and is found to be a function of wing
vertical placement on the fuselage:

$$\text{High wing } C_{\ell\beta_{wing\text{-}fus}} \approx -0.0344/\text{rad}$$
$$\text{Middle wing } C_{\ell\beta_{wing\text{-}fus}} \approx 0$$
$$\text{Low wing } C_{\ell\beta_{wing\text{-}fus}} \approx +0.0458/\text{rad} \tag{21.13}$$
*[Nicolai & Carichner, Eq. (21.13), p. 591]*

Third, $(C_{\ell\beta})_{\text{vertical stabilizer}}$: the force on a conventional vertical stabilizer,
which is generated as an aircraft sideslips, provides a restoring moment by acting through a moment arm to
the aircraft c.g. projection. The opposite is of course true for the ventral fin because it is
destabilizing. One may estimate this contribution as

$$\left(C_{\ell\beta}\right)_{VT} = -C_{L\alpha_{VT}}\left(1+\frac{d\sigma}{d\beta}\right)
\frac{q_{VT}}{q}\frac{S_{VT}}{S_{ref}}\frac{z_V}{b} \tag{21.14}$$
*[Nicolai & Carichner, Eq. (21.14), p. 591]*

Terms in Eq. (21.14) are defined as follows: $(C_{L\alpha})_{VT}$ = lift curve slope of vertical
stabilizer, which is based on an effective aspect ratio that is 1.55 times the actual ratio and is based on
the vertical stabilizer area; $S_{VT}$ = planform area of the vertical stabilizer; $S_{ref}$ = wing
planform area; $z_v$ = distance from mean aerodynamic chord of vertical stabilizer to aircraft vertical
c.g. projection (see Fig. 21.9).

The quantity

$$\left(1+\frac{d\sigma}{d\beta}\right)\frac{q_{VT}}{q}$$

is a difficult parameter to determine. Reference [9, Section 5.4] presents what appears to be the best
analytical method for finding this term:

$$\left(1+\frac{d\sigma}{d\beta}\right)\frac{q_{VT}}{q} = 0.724 + \frac{3.06\left(S'_{VT}/S_{ref}\right)}
{1+\cos\Lambda_{c/4}} + 0.4\frac{z_w}{d} + 0.009\,\text{AR} \tag{21.15}$$
*[Nicolai & Carichner, Eq. (21.15), p. 591]*

where $S'_{VT}$ = vertical stabilizer area with this area extended to fuselage centerline; $z_w$ =
distance along aircraft z axis from the wing root chord to the fuselage centerline; $d$ = maximum fuselage
depth; AR = wing aspect ratio.

The maximum effect of the vertical stabilizer is greatest as Mach number approaches unity because
$(C_{L\alpha})_{VT}$ increases toward that speed condition.

Too large a lateral stability aggravates the condition of Dutch roll (a dynamic lateral response) and does
not lend itself to a desirable flight condition. A first approximation to determining the desired amount of
lateral stability is suggested as

$$C_{\ell\beta} = -C_{n\beta} \text{ at Mach} = 1.0 \tag{21.16}$$
*[Nicolai & Carichner, Eq. (21.16), p. 592]*

Too large a value of $C_{\ell\beta}$ will also result in slow reaction from ailerons and/or spoilers in
trying to roll the aircraft.

The lateral control of the aircraft is achieved using ailerons and/or spoilers. As the ailerons deflect,
the aircraft begins to roll about the fuselage centerline. If the ailerons remain deflected, the roll rate
will increase until the rolling moment due to aileron deflection is balanced by the damping in roll moment.
This steady state roll rate condition is given by

$$C_\ell = 0 = C_{\ell_p}\left(\frac{Pb}{2V}\right) + C_{\ell_{\delta_a}}\delta_a \tag{21.17a}$$
*[Nicolai & Carichner, Eq. (21.17a), p. 592]*

where $C_{\ell_p} = dC_\ell/d(Pb/2V)$ is the damping in roll coefficient (determined from Fig. 21.11);
$C_{\ell_{\delta_a}} = dC_\ell/d\delta_a$ is the aileron control power derivative; $P$ = roll rate in radians
per second; $\delta_a$ = aileron deflection.

Rearranging Eq. (21.17a) to solve for the roll rate yields

$$P = -\frac{2V}{b}\frac{C_{\ell_{\delta_a}}}{C_{\ell_p}}\delta_a \tag{21.17b}$$
*[Nicolai & Carichner, Eq. (21.17b), p. 592]*

The flying qualities in military specification MIL-HDBK-1797 suggest a 90-deg roll in one second for
fighter aircraft (discussed further in Section 23.5).

**Fig. 21.11** — *$C_{\ell_p}$ for straight wings (data from [6])* *[Nicolai & Carichner, Fig. 21.11,
p. 593]*. Four charts of $-\beta C_{\ell_p}/K$ vs effective sweep $\Lambda_e$ (deg, -20 to 70), each a
family of curves parameterized by $\beta\,\text{AR}/K$ (1.5, 2, 3, 4, 5, 6, 7, 8, 9, 10), for taper ratios
$\lambda=$ 0, 0.25, 0.50, 1.0. A wing-planform inset defines $\Lambda_{1/4}$, $c_r$, $c_t$, $b$. Defining
relations given on the figure: $\lambda = c_t/c_r$; $\beta=\sqrt{1-M^2}$; $K=1.0$;
$\Lambda_e = \tan^{-1}\left(\frac{1}{\beta}\tan\Lambda_{1/4}\right)$. All four charts show curves peaking
near $\Lambda_e=0$-20 deg (values *(read from plot)* rising with $\beta\text{AR}/K$, e.g. at
$\lambda=1.0$, $\beta\text{AR}/K=10$ peaks near 0.55) and falling off toward $\Lambda_e=60$-70 deg (down to
roughly 0.15-0.30 depending on $\beta\text{AR}/K$ and $\lambda$); the $\beta\text{AR}/K=1.5$ curve (dashed)
is comparatively flat across the whole sweep range at low magnitude (~0.1-0.15).

The $C_{\ell_{\delta_a}}$ depends upon the amount of aileron area or spoiler area and their locations.
Reference [9, Section 6.2.1] or [3] is recommended for determining $C_{\ell_{\delta_a}}$.

## §21.6 Static Directional (Weathercock) Stability and Control (p. 594)

The *directional motion* of an aircraft is a rotation about the vertical axis of the aircraft. Figure 21.12
shows a schematic of the forces on an aircraft for directional motion. The directional moment is denoted by
$N$ and is positive for the right wing back (clockwise motion). The moment $N$ about the c.g. is (from
Fig. 21.12)

$$N = \ell_f L_f + \ell_{VT}L_{VT} + N_{power} + N_{wing} \tag{21.18}$$
*[Nicolai & Carichner, Eq. (21.18), p. 594]*

where $L_f$ is the side force on the fuselage, $N_{power}$ is the moment due to asymmetric power effects
(Fig. 21.12 shows this as a one-engine-out condition), and $N_{wing}$ is the moment due to the wing. If
ailerons are deflected, there is a differential lift and drag on each wing and hence an additional moment.

**Fig. 21.12** — *Forces on aircraft for directional motion (photograph courtesy of The Boeing Company)*
*[Nicolai & Carichner, Fig. 21.12, p. 594]*. Photo of a Boeing 787 on the ramp at left. Plan-view schematic
at right of a swept-wing twin-engine transport at sideslip angle $+\beta$ from freestream $V_\infty$,
showing: side force $L_f$ on the fuselage acting at arm $\ell_f$ forward of the c.g.; engine-out drag $D_e$
and opposite-engine thrust $T$ each acting at arm $\ell_e$ from the c.g. (with a.c./x offset marked near the
wing root), giving $N_{power}=-(D_e+T)\ell_e$ (negative moment as shown, "Engine Out" labeled at the left
engine); positive moment $+N$ shown as a clockwise curved arrow about the c.g.; vertical-tail side force
$L_{VT}$ acting at arm $\ell_{VT}$ aft of the c.g., with local sideslip $\beta_{VT}$ at the tail.

The *directional moment coefficient* is

$$C_n = \frac{N}{q_\infty S_{ref}b}$$

$$C_n = -\frac{\ell_f L_f}{q_\infty S_{ref}b} + \frac{\ell_{VT}S_{VT}}{bS_{ref}}\frac{q_{VT}}{q_\infty}
C_{L\alpha_{VT}}\beta_{VT} + \frac{N_{power}}{q_\infty S_{ref}b} + \frac{N_{wing}}{q_\infty S_{ref}b}
\tag{21.19}$$
*[Nicolai & Carichner, Eq. (21.19), p. 595]*

where $\beta_{VT} = (1+d\sigma/d\beta)\beta$ and accounts for the fuselage sidewash on the vertical tail.

The directional stability derivative is expressed as

$$\frac{dC_n}{d\beta} = C_{n\beta} = C_{n\beta_{fus}} + C_{n\beta_{wing}} + \bar{V}_{VT}C_{L\alpha_{VT}}
\left(1+\frac{d\sigma}{d\beta}\right)\frac{q_{VT}}{q_\infty} \tag{21.20}$$
*[Nicolai & Carichner, Eq. (21.20), p. 595]*

where $\bar{V}_{VT} = (\ell_{VT}S_{VT}/bS_{ref})$ is the vertical tail volume coefficient. Power effects
are usually not dependent on sideslip angle $\beta$ so that $C_{n\beta_{power}}$ is neglected.

The directional stability derivative $C_{n\beta}$ must be positive for static directional stability. A
$C_{n\beta} > 0$ will insure that moments will be generated, for a positive sideslip to rotate the aircraft
so that $\beta$ is reduced.

The vertical tail contribution is stabilizing for vertical tails (or ventral fins) aft of the center of
gravity:

$$C_{n\beta_{VT}} = \bar{V}_{VT}C_{L\alpha_{VT}}\left(1+d\sigma/d\beta\right)\left(q_{VT}/q\right)
\tag{21.21}$$
*[Nicolai & Carichner, Eq. (21.21), p. 595]*

where $C_{L\alpha_{VT}}$ is the lift curve slope of the vertical tail based upon the vertical tail
planform area and an effective aspect ratio 1.55 times that of the geometric aspect ratio (the fuselage
acts as a large tip plate). The term

$$\left(1+\frac{d\sigma}{d\beta}\right)\frac{q_{VT}}{q}$$

is determined from Eq. (21.15).

The $C_{n\beta}$ wing is due to the asymmetrical drag and lift distributions on the different wing panels
undergoing sideslip. Wing sweep adds to the weathercock stability of the aircraft. An expression for the
wing subsonic contribution is (from [9])

$$C_{n\beta_{wing}} = C_L^2\left[\frac{1}{4\pi\,\text{AR}} - \frac{\tan\Lambda_{c/4}}
{\pi\,\text{AR}(\text{AR}+4\cos\Lambda_{c/4})}\left(\cos\Lambda_{c/4} - \frac{\text{AR}}{2} -
\frac{\text{AR}^2}{8\cos\Lambda_{c/4}} + \frac{6x}{\bar{c}}\frac{\sin\Lambda_{c/4}}{\text{AR}}\right)\right]
\tag{21.22}$$
*[Nicolai & Carichner, Eq. (21.22), p. 595]*

per radian, where $x$ is the distance (positive rearward) from the aircraft c.g. to the wing aerodynamic
center.

The fuselage at a sideslip angle $\beta$ behaves like a lifting body. The sideslip derivative of the
fuselage is usually destabilizing because the fuselage n.p. is usually ahead of the vehicle c.g. and the
effect is very significant. The fuselage yawing moment is easier to calculate than the pitching moment due
to $\Delta\beta$. The reason is that longitudinally the lift on the fuselage is very much affected by the
wing (upwash and downwash) but directionally it can be assumed that the wing has very little effect. The
several references used to find a general formula providing a first-order estimate of this contribution
have led to the following form:

$$C_{n\beta_{fuselage}} = -1.3\frac{\text{Vol}}{S_{ref}b}\frac{h}{w} \tag{21.23}$$
*[Nicolai & Carichner, Eq. (21.23), p. 596]*

per radian, where Vol = fuselage volume; $(h/w)$ = ratio of mean fuselage depth to mean fuselage width;
$b$ = wing span; $S_{ref}$ = wing planform area.

The desirable level of directional stability in terms of $C_{n\beta}$ is very difficult to express in
general terms. Chapter 23 lists some desired values for $C_{n\beta}$ that have been shown to give pleasant
flying qualities. The vertical tail area is sized such that Eq. (21.20) gives desired values for $C_{n\beta}$.
The rudder is sized to meet certain low-speed directional control criteria.

The contributions of the wing and fuselage are essentially independent of Mach number. However, the tail
$C_{n\beta}$ increases then decreases with increasing Mach number due to the variation in $C_{L\alpha_{VT}}$.
Because the wing contributes little stability, the vertical tail is the main component offsetting the
destabilizing contribution of the fuselage. Because $C_{L\alpha_{VT}}$ can decrease by a factor of 3 from
subsonic to Mach = 3, the static directional stability decreases at high Mach. Some vehicles need extra
vertical surfaces at high Mach numbers to give adequate directional stability. The XB-70 did this by
folding its wingtips downward (see Fig. 21.13).

The requirements for adequate directional control (discussed in Chapter 23) are that the rudder be
powerful enough to hold $\beta=0$ for a one-engine-out (asymmetric power) flight condition at $1.2V_{TO}$,
hold a straight ground path landing and takeoff in a crosswind up to $0.2V_{TO}$ and overcome the adverse
yaw associated with abrupt aileron rolls at $V_{TO}$.

The asymmetric power condition would be (from Fig. 21.12)

$$C_n = 0 = -\frac{(T+D_e)}{q_\infty S_{ref}b} + C_{n_{\delta_r}}\delta_r \tag{21.24}$$
*[Nicolai & Carichner, Eq. (21.24), p. 596]*

**Fig. 21.13** — *Typical $C_{n\beta}$ variation with Mach number* *[Nicolai & Carichner, Fig. 21.13,
p. 597]*. Chart of $C_{n\beta}$ (qualitative, unitless axis) vs Mach Number (0-3.5+), two curves: a solid
"w/o folding tips" curve rising from Mach 0 to a peak around Mach 1.2-1.5, then falling off steeply through
Mach 2-3.5; a dashed "with folding tips" curve that follows the same rise/peak but falls off less steeply
after the peak, staying above the solid curve at high Mach — illustrating how the XB-70's folding wingtips
recover directional stability lost at high Mach.

where $C_{n_{\delta_r}} = dC_n/d\delta_r$ is the rudder control power and $\delta_r$ is the rudder
deflection angle.

The crosswind condition is

$$C_n = 0 = C_{n\beta}\beta + C_{n_{\delta_r}}\delta r \tag{21.25}$$
*[Nicolai & Carichner, Eq. (21.25), p. 597]*

where $\beta = 11.5$ deg for a $0.2V_{TO}$ crosswind. In both cases maximum rudder deflection is $\pm20$ deg.

The rudder control power can be estimated from

$$C_{n_{\delta_r}} \approx 0.9C_{L\alpha_{VT}}\bar{V}_{VT}\tau \tag{21.26}$$
*[Nicolai & Carichner, Eq. (21.26), p. 597]*

where $\tau = d\alpha_{0L}/d\delta_r$ and is shown in Fig. 21.14.

The required rudder area $S_R$ for adequate directional control is determined by solving Eqs. (21.24),
(21.25), and (21.26) for the maximum value of $\tau$ and then going to Fig. 21.14.

## §21.7 Aft Tail Location for Reduced Pitch-Up (p. 597)

Pitch-up is the longitudinal instability at high lift that results in an aircraft having a positive
pitching moment as the wing begins to stall. It is due to the forward shift of the wing center of pressure
as the wingtip region stalls and/or the blanking of the aft horizontal tail by the separated wing wake. It
is a very undesirable phenomenon as the aircraft tends to pitch up violently with disastrous results at
high subsonic speeds. Many of the fighter aircraft (such as the McDonnell F-101 Voodoo) had horns, buzzers,

**Fig. 21.14** — *Rudder effectiveness chart (from data in Fig. 9.10)* *[Nicolai & Carichner, Fig. 21.14,
p. 598]*. Chart of rudder effectiveness parameter $\tau$ (0-0.8) vs $S_R/S_{VT}$ (0-0.8), a single
monotonically-increasing concave-down curve from the origin, rising steeply at first (e.g. $\tau\approx0.4$
by $S_R/S_{VT}\approx0.2$ *(read from plot)*) and flattening toward $\tau\approx0.78$ at $S_R/S_{VT}=0.8$.

or stick shakers that would warn the pilot about entry into the wing-stall region.

Sometimes the aircraft will pitch up gradually to a high angle-of-attack and the horizontal tail will lose
the control power to push the nose down. This situation is termed *pitch hang-up*. If the wing is stalled,
it can lead to an unrecoverable deep stall. One design solution is to locate the horizontal tail outside of
the wing wake by mounting it on top of the vertical tail in a "T-tail" arrangement. In 1963 the aviation
transport world was troubled by several accidents of the newly produced "T-tail" aircraft, including the
BAC-111 and the Trident.

These accidents were the result of an unrecoverable deep stall, which is a condition marked by softening
of the horizontal tail control power at poststall angles-of-attack. Transport aircraft do not normally get
to these high angles-of-attack so it is not a problem. However, STOL transports need special features such
as stick shakers, stall limiters, and T-tails to stay out of trouble. The Lockheed C-5 had all three
features and flew trouble free for over three decades.

In 2005 the C-5 was re-engined with the more powerful CF6-80C2 turbofans. Because the engine thrust line
was below the c.g. (giving a pitch-up moment) the nose-down pitch authority was reduced, giving the
possibility of an unrecoverable deep stall. The solution was to bias the stall limiter to lower
angles-of-attack and train the crews in aggressive stall recovery techniques. The C-17 has similar features
to those of the C-5. The initial F-16As had a pitch hang-up problem above 35-deg angle-of-attack, and the
horizontal tail area was increased on subsequent aircraft.

Reference [10] presents some design guidelines for aircraft planforms and aft tail location for
minimizing the possibility of pitch-up at high subsonic speeds. Figure 21.15a presents a boundary for
AR-sweep combinations for tailless aircraft. Aspect ratio and sweep combinations in region I (to the right
of the boundary) display a tendency to pitch-up at high $C_L$. Notice that the more modern air-to-air
fighters all have region II wings and the high subsonic transports all have region I wings.

**Fig. 21.15** — *Guidelines for wing design and aft tail location for minimal pitch-up at high-subsonic
speeds (data from [10])* *[Nicolai & Carichner, Fig. 21.15, p. 599]*. Two-part figure:

**21.15a** *"Boundary Related to Wing Planform"* — a scatter/boundary chart of Wing Aspect Ratio, AR (0-8)
vs quarter-chord sweep $\Lambda_{1/4}$ (deg, 0-80), with a wide diagonal shaded boundary band running from
upper-left (AR~8 at $\Lambda_{1/4}$~5 deg) down to lower-right (AR~0.5 at $\Lambda_{1/4}$~80 deg),
separating "Region I: Reduced Stability at High Lift" (above/right of the band) from "Region II: Increased
Stability at High Lift" (below/left). Plotted real-aircraft data points *(read from plot)*: C-5 and C-141
at AR~7.7-8/$\Lambda_{1/4}$~25 deg, C-17 at AR~7.7/$\Lambda_{1/4}$~27 deg (all Region II, transports);
F-86 at AR~5/$\Lambda_{1/4}$~35 deg; F-101 at AR~4/$\Lambda_{1/4}$~38 deg; F-100 at AR~3.5/$\Lambda_{1/4}$~46
deg; F-105 at AR~3.2/$\Lambda_{1/4}$~48 deg; F-102 at AR~2.2/$\Lambda_{1/4}$~52 deg (F-86 through F-102 all
in/near Region I); F-5 at AR~3.9/$\Lambda_{1/4}$~24 deg; F-18 at AR~3.5/$\Lambda_{1/4}$~20 deg; F-16 at
AR~3/$\Lambda_{1/4}$~30 deg; F-4 at AR~2.8/$\Lambda_{1/4}$~43 deg; F-15 at AR~2.5/$\Lambda_{1/4}$~34 deg;
F-35 at AR~2.3/$\Lambda_{1/4}$~24 deg; F-22 at AR~2.3/$\Lambda_{1/4}$~29 deg (F-5 through F-22 all in
Region II, modern fighters).

**21.15b** *"Boundary Related to Horizontal Tail Position"* — chart of nondimensional tail height
$z/\bar{c}_{1/4}$ (-1 to 2) vs nondimensional tail length $\ell/\bar{c}$ (0-5), with a wing-planform-side
inset defining $\bar{c}_{1/4}$, and three shaded boundary curves (labeled ①②③ at their right ends)
dividing the plane into four labeled regions: **A** "Pitch-up at high lift generally preceded by stall
warning (Region II planform recommended)" (uppermost band); **B** "Pitch-up without warning, avoid" (next
band down); **C** "Generally no pitch-up at subcritical speeds (Region I wing planforms OK)" (next band
down); **D** "Generally no pitch-up" (lowest band, most negative $z/\bar{c}_{1/4}$). The three boundary
curves all trend from lower-left to upper-right (increasing with $\ell/\bar{c}$), consistent with tails
mounted higher and farther aft carrying greater pitch-up risk.

Figure 21.15b presents design information on aft tail location for reducing pitch-up tendencies at
high-subsonic speeds. The point is to locate the tail out of the high-$C_L$ wing wake so that the tail
continues to be effective in providing longitudinal control. Figure 21.8 can be used to locate the wing
downwash (wake) behind the wing. Region B of Fig. 21.15b is to be avoided. Region A, although not
recommended for aircraft, is permissible provided a region II planform (from Fig. 21.15a) is used.

Most of the aircraft with region I wings have horns and stick shakers, and many have T-tails. The F-4 with
a clear region I wing has dihedral on the wing tips and anhedral on the horizontal tail to locate the tail
outside of the wing wake.

## References (p. 600)

[1] McCormick, B., *Aerodynamics, Aeronautics and Flight Mechanics*, Wiley, New York, 1995.
[2] Etkin, B., *Dynamics of Atmospheric Flight*, Wiley, New York, 1972.
[3] Roskam, J., *Flight Dynamics of Rigid and Elastic Airplanes*, Univ. of Kansas, Lawrence, KS, 1972.
[Available via www.darcorp.com (accessed 31 Oct. 2009).]
[4] Roskam, J., *Airplane Design, Part VII: Determination of Stability, Control and Performance
Characteristics: FAR and Military Requirements*, Univ. of Kansas, Lawrence, KS, 1988. [Available via
www.darcorp.com (accessed 31 Oct. 2009).]
[5] Chalk, C. R., "Background Information and User Guide for MIL-F-8785, Military
Specification—Flying Qualities of Piloted Airplanes," U.S. Air Force Flight Dynamics Laboratory,
AFFDL-TR-69-72, Wright-Patterson AFB, Dayton, OH, Aug. 1969.
[6] Data sheets, Royal Aeronautical Society, London, UK.
[7] Multhopp, R., "Aerodynamics of the Fuselage," NACA TM-1036, 1942.
[8] Silverstein, A., and Katzoff, S., "Design Charts for Predicting Downwash Angles and Wake
Characteristics Behind Plain and Flapped Wings," NACA TR-648, 1939.
[9] Ellison, D. E., "USAF Stability and Control Handbook (DATCOM)," U.S. Air Force Flight Dynamics
Laboratory, AFFDL/FDCC, Wright-Patterson AFB, Dayton, OH, Aug. 1968.
[10] Spreemann, K. P., "Design Guide for Pitch-up Evaluation and Investigation at High Subsonic Speeds
of Possible Limitations Due to Wing-Aspect-Ratio Variations," NASA TM-X-26, NASA Langley Research
Center, Langley, VA, Aug. 1959.

Chapter 21 extraction complete.

