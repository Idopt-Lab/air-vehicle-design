# Chapter 17 — Propeller Propulsion Systems

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, Chapter 17,
printed pp. 435–465 (PDF pp. 445–475).

Text-layer inventory (built before extraction, for completeness checking): Figs 17.1–17.20 (with
sub-labels to be confirmed during extraction); Table 17.1; Eqs (17.1)–(17.35).

## Chapter opener

Section list: Why Propellers?; Theories; Power Coefficient; Thrust Coefficient; Advance Ratio; Activity
Factor; Propulsive Efficiency; Vendor Propeller Charts. *[Nicolai & Carichner, p. 435]*

Photo caption: *Backdrop for the propeller used on a Wright Brothers 1908 aircraft. A propeller is best
described as a rotating wing with all the complexity of aerodynamics, structures, materials, and control.
Design pioneers confronted a situation aptly titled "Propellers and Mystery Are Synonymous" in a 1919
aircraft design textbook.* *[Nicolai & Carichner, p. 435]*

Chapter epigraph: *"Propellers and mystery are synonymous."* *[Nicolai & Carichner, p. 435]*

## §17.1 Introduction (p. 436)

Despite the great deal of attention and fanfare attached to turbojet/turbofan aircraft design since World
War II, a large performance regime still exists that can be adequately filled only by propeller-driven
aircraft: certain STOL transport and long-endurance maritime reconnaissance missions lend themselves
perfectly to turboprop power schemes, and the high cost of turbine powerplants guarantees the reciprocating
engine will play a major role in general aviation for decades to come — propellers are also the only thing
that makes sense on slow airships and solar-powered aircraft. This chapter *[Nicolai & Carichner, p. 436]*:

- Discusses the theories of propeller performance
- Presents a methodology for designing custom propellers
- Discusses the practical use of vendor-supplied propeller charts

## §17.2 Why Propellers? (p. 436)

The *open propeller*, or *airscrew*, offers an efficient means of propulsion in the low- to
medium-subsonic speed range. Just as the turbofan engine is generally more efficient than a turbojet of
the same thrust, a propeller–turbine engine combination is more efficient than either of them. The reason
can be found from a brief look at Newton's second law in the form a propulsion engineer would use
*[Nicolai & Carichner, Eq. (14.2), p. 436 — restated from p. 356]*:

$$T_n = \dot{m}_{air}(V_e - V_a) \tag{14.2}$$

where, for this analysis, the pressure term is ignored and the resultant force is the thrust of the
powerplant. A propeller achieves a specified level of thrust by giving a relatively small acceleration to
a relatively large mass of air, whereas the turbofan and turbojet each give a correspondingly higher
acceleration to a correspondingly smaller mass of air. From energy considerations, the powerplant
producing the smallest change in kinetic energy requires the smallest expenditure of fuel; thus the
propeller–shaft-engine powerplant provides the highest efficiency of the methods considered. As will be
shown, this argument breaks down at higher flight speeds, where compressibility effects cause additional
and unacceptable blade losses. *[Nicolai & Carichner, pp. 436–437]*

Sidebar: *In 1908 the Wright brothers were conducting flight trials of their latest Wright Flyer design
for the Army. The goal of the next flight was to demonstrate one hour at 40 mph with a passenger on board.
Orville was the pilot and Lt. Selfridge was the passenger. Well into the flight one of the wooden
propellers broke, sending it into the rigging and causing the aircraft to crash. Orville was badly injured
but Lt. Selfridge died on the operating table, making him the first crash victim in a powered aircraft.
Selfridge AFB in Michigan is named after him.* *[Nicolai & Carichner, p. 436]*

The propeller offers an additional advantage to the designer of a multiengine STOL aircraft by bathing
large segments of the wing in its high-dynamic-pressure slipstream; this slipstream produces a significant
amount of wing lift independently of any freestream dynamic pressure effects and provides an equivalent
increase in wing lift coefficient. High values of takeoff acceleration can be obtained by optimizing
propeller design for static thrust conditions; however, this effort to improve STOL capability can only be
made by compromising the aircraft's cruise performance. As mentioned in Chapter 10, the utilization of
reversible-pitch propellers provides the designer with a high deceleration capability at little or no
increase in weight or cost. *[Nicolai & Carichner, p. 437]*

## §17.3 Theory (p. 437)

The analysis of propeller performance can be accomplished using one or more of the following theories:
momentum theory, blade element theory, and vortex theory. Each method has its own distinct advantages as
well as shortcomings, yet all play an important role in providing an understanding of airscrew
performance. The following discussion conveys a general working knowledge of the pertinent theory; for
deeper insight the reader is directed to [1–6]. *[Nicolai & Carichner, p. 437]*

### §17.3.1 Momentum Theory (p. 437)

Any aerodynamic propulsive device produces thrust by imparting a change in momentum flux to a specified
mass of air (Newton's second law). The basic momentum theory analyzes the effects of this change in
momentum, the work done on the air, and the energy imparted to the air. Certain simplifying assumptions
are made about the propeller and its surroundings in developing this theory that divorce them from the
real world, and yet the method remains a useful tool in calculating the maximum theoretical efficiency a
propeller can obtain. *[Nicolai & Carichner, p. 437]*

The first assumption made by momentum theory is that the propeller is replaced by an infinitesimally thin
actuator disk consisting of an infinite number of blades. The disk is held to be uniformly loaded and is
thus experiencing uniform flow and imparting a uniform acceleration to the air passing through it. The
actuator disk is further assumed to be surrounded by a sharply delineated streamtube that divides the flow
passing through the propeller and the surrounding air. Far upstream and downstream from the disk the
walls of the streamtube are parallel, and the static pressure inside the streamtube at these points is
equal to the freestream static pressure. *[Nicolai & Carichner, p. 438]*

Momentum theory deals with a working fluid (air) that is inviscid and incompressible; as a consequence,
the propeller does not impart any rotation to the air, and any profile losses from the blades are
ignored. To an observer moving with the actuator, the air far upstream moves with freestream velocity $V$
(Fig. 17.1). This air is gradually accelerated until, at station 1, the actuator disk $V_1 = V + \nu$,
where $\nu$ is the induced velocity imparted to the air by the actuator; at station 2, far downstream, it
can be shown that $V_2 = V + 2\nu$. The net change in velocity through the control volume defined by the
streamtube and planes perpendicular to the flow far upstream and far downstream is *[Nicolai & Carichner,
Eq. (17.1), p. 438]*:

$$(V+2\nu) - V = 2\nu \tag{17.1}$$

and, from continuity considerations for an incompressible fluid, *[Nicolai & Carichner, Eq. (17.2), p.
438]*:

$$A_1 = A = 2A_2 \tag{17.2}$$

For steady flow the mass flux is constant across every plane of the streamtube perpendicular to the flow.
Using the actuator disk as a reference plane, *[Nicolai & Carichner, Eq. (17.3), p. 438]*:

$$\dot{m} = \rho A(V+\nu) \tag{17.3}$$

The thrust $T$ produced by the actuator disk is $T = \Delta$Momentum flux (unnumbered relation, p. 438),
which gives *[Nicolai & Carichner, Eq. (17.4), p. 439]*:

$$T = \rho A(V+\nu)2\nu \tag{17.4}$$

**Fig. 17.1** — *Propeller analysis by momentum theory* *[Nicolai & Carichner, Fig. 17.1, p. 438]*.
Side-view schematic of a streamtube through a control volume: station 0 (far upstream, pressure
$P_\infty$, velocity $V$), station 1 (actuator disk of area $A$, velocity $V+\nu$, pressure jump
$P_1 \to P_1+\Delta P$), station 2 (far downstream, pressure $P_2 = P_\infty$, velocity $V+2\nu$);
streamtube boundary shown expanding from station 0 to a narrower waist at the disk then widening
downstream; "Control Volume" bounding box labeled.

To produce this level of thrust, the actuator (propeller) must supply energy to the slipstream. Because
the theory ignores profile and rotational losses, this energy goes only to increasing the kinetic energy
of the flow. The power required for this purpose, the induced power $P_i$, equals the change in kinetic
energy flux through the control volume and may be shown to be simply the product of the resultant thrust
and the velocity at which the thrust is applied, or *[Nicolai & Carichner, Eq. (17.5), p. 439]*:

$$P_i = T(V+\nu) \tag{17.5}$$

Eq. (17.5) indicates that, to minimize induced power requirements at a given thrust level and freestream
velocity, the induced velocity must be kept as small as possible. Solving Eq. (17.4) for $\nu$ (and
remembering that $\nu > 0$ for a propeller) yields *[Nicolai & Carichner, Eq. (17.6), p. 439]*:

$$V = -\frac{V}{2} + \left(\frac{V^2}{4}+\frac{T}{2\rho A}\right)^{1/2} \tag{17.6}$$

Two important conclusions may be gleaned from this expression. To minimize $V$ (hence $P_i$) at given
values of $V$ and $T$, the quantity $T/A$, the *disk loading*, must be minimized — within the limits of
the assumptions made, the larger the propeller used to produce a given thrust, the smaller the power and
energy requirements. The second result is that, for a given thrust, as freestream velocity increases the
induced velocity decreases; this does not imply the induced power requirement will decrease — for a given
level of thrust, $V$ increases faster than $\nu$ decreases, so the required $P_i$ increases as freestream
velocity increases. In practice, however, the thrust of a propeller will not remain constant with changing
velocity, but the power of the engine turning it will, over moderate speed ranges, remain fixed. Because
profile and rotational losses are neglected, $P_{avail}$ remains constant and thrust decreases with
increasing velocity. This condition may be illustrated by combining Eqs. (17.5) and (17.6) to form an
expression for $P_i$ as a function of $T$ and $V$; solving for the static condition ($V=0$, subscript 0)
and for $V \neq 0$, and assuming $P_i$ is constant for all $V$, gives *[Nicolai & Carichner, Eq. (17.7), p.
439]*:

$$\frac{T}{T_0} = \frac{2}{(V/\nu_0)+\left[(V/\nu_0)^2+4(T/T_0)\right]^{1/2}} \tag{17.7}$$

Although a general solution of this function $T/T_0 = f(V/V_0)$ is not possible, the approximation
*[Nicolai & Carichner, Eq. (17.8), p. 440]*:

$$\frac{T}{T_0} \approx 1 - 0.32\frac{V}{\nu_0} \tag{17.8}$$

will hold for $V/\nu_0 \ll 1$. *[Nicolai & Carichner, p. 440]*

The theoretical power required by the propeller has been defined as the product $T(V+\nu)$. By defining
the useful power output of the propeller as $TV$, it is possible to form an ideal efficiency (unnumbered
relation, p. 440):

$$\eta_i = \frac{\text{Power Output (Useful Power)}}{\text{Power Input}}$$

*[Nicolai & Carichner, Eq. (17.9), p. 440]*:

$$\eta_i = \frac{TV}{T(V+\nu)} = \frac{V}{(V+\nu)} \tag{17.9}$$

Notice that the static ideal efficiency will be zero, but that $\eta_i$ will increase with $V$. This
concept of ideal efficiency is misleading for cases where $V/\nu < 1$; the use of the word "ideal" must
again be emphasized as no real-world losses are included in its calculation. The momentum theory does not
provide a means to predict propeller losses due to blade skin friction, rotational motion, or mutual blade
interference, nor does it account for any geometry parameters other than disk area. Although simple to
apply, this theory must be combined with some other analytical tool to be of use to the designer.
*[Nicolai & Carichner, p. 440]*

### §17.3.2 Blade Element Theory (p. 440)

An aircraft propeller is nothing more than an airfoil rotating about a translating axis, dividing a
propeller blade into a number of chordwise strips. It is possible to analyze the performance of the entire
propeller by summing the contributions of all segments on all blades of the airscrew — this is essentially
what is done by the *blade element theory* (sometimes called *strip theory*). In Fig. 17.2 a small element
of the propeller blade is marked for consideration: this infinitesimal element is $dr$ wide, has chord $c$,
and is located a distance $r$ from the axis of rotation; the entire blade has a radius of $R$. A cross
section of the blade element is shown in Fig. 17.3; the airfoil shape can be clearly seen, and many of the
angular and velocity notations are analogous to those used in wing theory. *[Nicolai & Carichner, p. 440]*

**Fig. 17.2** — *Propeller blade element* *[Nicolai & Carichner, Fig. 17.2, p. 441]*. Isometric view of a
propeller blade with rotation axis and rotation rate $\Omega$ marked; a chordwise strip of width $dr$,
chord $c$, located at radius $r$ from the axis, is highlighted; blade tip radius $R$ is dimensioned from
the axis to the blade tip.

**Fig. 17.3** — *Forces, velocities, and angles for a blade element* *[Nicolai & Carichner, Fig. 17.3, p.
441]*. Cross-sectional airfoil view of a blade element referenced to the "Plane of Rotation" (horizontal
dashed line) and "Zero Lift Line" (ZLL, dashed line through the airfoil): velocity triangle showing
rotational velocity $\Omega r$, translational velocity $V$, resultant velocity $V_R$, effective resultant
velocity $V_e$, and elemental induced velocity $v_r$; angles effective pitch angle $\Phi$, geometric pitch
angle $\beta$, elemental induced angle of attack $\alpha_i$, elemental angle of attack $\alpha_r$; force
vectors elemental lift $dL$, elemental thrust $dT$, and elemental profile drag $dD_0$ shown acting on the
airfoil, with dL perpendicular to $V_e$.

Symbol definitions for Fig. 17.3 *[Nicolai & Carichner, p. 441]*:

| Symbol | Definition |
|---|---|
| $\Omega r$ | Rotational velocity |
| $V$ | Translational velocity (true airspeed) |
| $V_R$ | Resultant velocity |
| $V_e$ | Effective resultant velocity |
| $v_r$ | Elemental induced velocity |
| $\Phi$ | Effective pitch angle |
| $\beta$ | Geometric pitch angle |
| $\alpha_i$ | Elemental induced angle of attack |
| $\alpha_r$ | Elemental angle of attack |

To simplify the development of the blade element theory, it is assumed that each element is subjected to
two-dimensional flow only and that each element is independent of its neighbors. The aerodynamic lift
force produced by the elemental lift $dL$ is perpendicular to the effective velocity $V_e$ and is inclined
from the axis of rotation by the angle (unnumbered relation, p. 442):

$$\varphi + \alpha_i \approx \tan^{-1}\left(\frac{V+\nu r}{\Omega r}\right)$$

For freestream velocities up to the mid-subsonic range, it may be assumed that this angle is small, and
(unnumbered relations, p. 442):

$$\sin(\varphi+\alpha_i) \approx \varphi+\alpha_i \ \text{(in radians)}$$
$$\tan(\varphi+\alpha_i) \approx \varphi+\alpha_i \ \text{(in radians)}$$
$$\cos(\varphi+\alpha_i) \approx 1$$

Thus, the elemental thrust is *[Nicolai & Carichner, Eq. (17.10), p. 442]*:

$$|dT| = |dL|\cos(\varphi+\alpha_i) \approx |dL| \tag{17.10}$$

Similarly, the drag force opposing rotation of the propeller element consists of a drag component
$dD_0$ and a component due to the inclination of the lift force, the induced drag $dD_i$:

$$|dD| = |dD_0|\cos(\varphi+\alpha_i) + |dL|\sin(\varphi+\alpha_i)$$

$$|dD| \approx |dD_0| + |dL|(\varphi+\alpha_i) \tag{17.11}$$

*[Nicolai & Carichner, Eq. (17.11), p. 442]*

It is now possible to express the thrust produced by a single element as (unnumbered relation, p. 442):

$$dT \approx dL = \text{dynamic pressure} \times \text{area} \times \text{lift coefficient}$$

$$= \left(\frac{1}{2}\rho V_e^2\right)(c\,dr)c_\ell \tag{17.12}$$

*[Nicolai & Carichner, Eq. (17.12), p. 442]* where $c_\ell$ is the two-dimensional lift coefficient of the
element. To determine the thrust of the propeller one must integrate this expression across the span of
the blade and multiply by the number of blades $b$: *[Nicolai & Carichner, Eq. (17.13), p. 442]*

$$T = b\int_0^R 0.5\rho V_e^2 c c_\ell \, dr \tag{17.13}$$

Practical propeller blades do not run to the axis of rotation because some allowance must be made for a
mounting hub and, possibly, a pitch-changing mechanism; for this reason the inner limit of integration,
$r_i$, is usually taken as $0.1R$. Similarly, some accounting must be made for losses caused by a decrease
in effectiveness of outboard blade elements resulting from the formation of a blade tip vortex; the outer
integration limit is usually taken to $BR$, where the empirically determined tip-loss factor
$B \approx 0.96$. By ignoring compressibility effects, Eq. (17.13) becomes *[Nicolai & Carichner, Eq.
(17.14), p. 443]*:

$$T = 0.5\rho b\int_{r_i}^{BR} V_e^2 c c_\ell \, dr \tag{17.14}$$

where $V_e$ varies with $r$, and $c$ and $c_\ell$ may or may not be functions of radial position. Generally
$c = c(r)$ is specified, but to calculate the propulsive thrust one must know $V_e = V_e(r)$ and
$c_\ell = c_\ell(r)$. From Fig. 17.3 it is obvious that *[Nicolai & Carichner, Eq. (17.15), p. 443]*:

$$V_e \approx \left[(V_r+V)^2+(\Omega r)^2\right]^{1/2} \tag{17.15}$$

and the two-dimensional lift coefficient may be expressed as *[Nicolai & Carichner, Eq. (17.16), p. 443]*:

$$c_\ell = a\alpha_r = a\left[\beta - (\varphi+\alpha_i)\right] \approx a\left[\beta -
\frac{V+\nu r}{\Omega r}\right] \tag{17.16}$$

where $a = dc_\ell/d\alpha$. Due to variations in local Mach number across the blade span, $a$ will vary
with $r$; however, with little loss of accuracy, it may be assumed constant with a value appropriate for
the conditions at $r = 0.75R$. *[Nicolai & Carichner, p. 443]*

Eqs. (17.15) and (17.16) still cannot produce the key to solving for the thrust of the propeller until the
local induced velocity, $\nu_r$, is known at every blade location. An expression for $\nu_r$ can be
obtained by employing simple momentum theory in an elemental approach. Fig. 17.4 shows an actuator disk
upon which an annulus $dr$ wide and located a distance $r$ from the center has been considered; using the
same logic as was used to develop Eq. (17.4), the differential thrust produced by this annulus is
*[Nicolai & Carichner, Eq. (17.17), p. 443]*:

$$dT = \rho(2\pi r\,dr)(V+\nu_r)2\nu_r \tag{17.17}$$

From blade element considerations, the thrust generated by this same annulus is the product of the thrust
produced by a single element located a distance $r$ from the axis of rotation [Eq. (17.12)] and the number
of blades $b$. With Eqs. (17.15) and (17.16), this becomes *[Nicolai & Carichner, Eq. (17.18), p. 444]*:

$$dT = \frac{b}{2}\rho\left[(\nu_r+V)^2+(\Omega r)^2\right]ca\left[\beta - \frac{V+\nu_r}{\Omega r}\right]
\tag{17.18}$$

**Fig. 17.4** — *Annulus of an actuator disk* *[Nicolai & Carichner, Fig. 17.4, p. 444]*. Front view of a
circular actuator disk of radius $R$, with a thin annular ring of width $dr$ shown at radius $r$ from the
center, shaded to indicate the differential-thrust annulus under consideration.

By Eqs. (17.17) and (17.18) and solving for $\nu_r$: *[Nicolai & Carichner, Eq. (17.19), p. 444]*

$$\nu_r = \left(\frac{V}{2}+\frac{bca\Omega}{16\pi}\right)-1+\left[1+\frac{2\Omega r\left(\beta-
\frac{V}{\Omega r}\right)}{\frac{4\pi V^2}{bca\Omega}+V+\frac{bca\Omega}{16\pi}}\right]^{1/2} \tag{17.19}$$

which, within the limitations of the theory, predicts the induced velocity at a radial distance $r$ of a
propeller of known physical characteristics that is axially translating at velocity $V$. Theoretically it
would be possible to introduce Eq. (17.19) into (17.18) and integrate the latter expression between
appropriate limits to calculate the thrust of a propeller of arbitrary twist distribution; in practice,
however, the resulting expression would prove extremely difficult to handle. Satisfactory results can be
obtained by dividing the blade into a finite number of stations, calculating $\nu_r$ and $dT$ at each
station, and finally computing total thrust via graphical integration or a numerical technique such as
Simpson's rule. The calculation of propeller thrust can be greatly simplified by recognizing that, as
expressed by Eq. (17.19), the local induced velocity will be constant across the blade if the quantity
$2\Omega r[\beta - (V/\Omega r)]$ is also a constant. *[Nicolai & Carichner, p. 444]*

(It can be shown [5] that constant $\nu_r$ across the blade requires the minimum induced power for a given
thrust, and is thus desirable for reasons other than convenience of computation.) This may be accomplished
by providing the blade with ideal twist such that, for any element located at $r$, the geometric pitch
angle is defined by *[Nicolai & Carichner, Eq. (17.20), p. 445]*:

$$\beta = \frac{\beta_t R}{r} \tag{17.20}$$

where $\beta_t$ is the pitch of the tip section. This expression becomes unmanageable for $r \to 0$ as a
result of the small-angle assumption (unnumbered relation, p. 445):

$$(\varphi+\alpha_i)\tan^{-1}\left[(V+\nu_r)/\Omega r\right]$$

Practically, as $r \to 0$, $\beta \to \pi/2$. A unique twist distribution will be ideal only for a limited
number of thrust and airspeed combinations: because $T = f(\beta_t)$ for a given $V$, varying thrust
levels will require variable $\beta_t$; however, because $\beta = \pi/2$ at $r=0$ for all cases, the ideal
twist distribution must be optimized for a single thrust–airspeed combination. *[Nicolai & Carichner, p.
445]*

The blade element theory furnishes a method for approximating the total power requirements of the
propeller by providing insight into the profile losses of the blade. From Fig. 17.3 it can be seen that
the power required to rotate the propeller (and thus generate thrust) is the power needed to overcome the
forces in the plane of rotation. For a single infinitesimal element this is *[Nicolai & Carichner, Eq.
(17.21), p. 445]*:

$$dP = \Omega r\,dD_0\cos(\varphi+\alpha_i) + \Omega r\,dL\cos(\varphi+\alpha_i) \tag{17.21}$$

The term $dD_0 = (1/2)\rho V_e^2 c c_{d_0}\,dr$ is the profile drag acting on the element, and thus the
first series of terms in Eq. (17.21) may be thought of as the *elemental profile power*, whereas the
second group is the *elemental induced power*. Then *[Nicolai & Carichner, Eq. (17.22), p. 445]*:

$$dP = dP_0 + dP_i \tag{17.22}$$

It must be noted that the induced power requirements are directly associated with the production of
propeller thrust, and when the expression for $dP_i$ is integrated across the blade radius, provisions
must be made for the loss of thrust at the tips. Profile losses, however, are present across the entire
exposed radius of the blade. Thus, each of the terms in Eq. (17.22) must be integrated between separate
limits: *[Nicolai & Carichner, Eq. (17.23), p. 446]*

$$P = 0.5\rho b\left[\int_{r_i}^R (\Omega r)^2 V_e c c_{d_0}\,dr + \int_{r_i}^{BR} V_e c(\beta\Omega r - V
- \nu_r)(V+\nu_r)\,dr\right] \tag{17.23}$$

This general equation is for modern high-speed propellers that employ ideal twist. Also, because most
propellers are designed so that each section operates at a low angle-of-attack, each element also
functions in the angle-of-attack region where the two-dimensional, incompressible profile drag coefficient
$c_{d_0}$ is approximately constant, and for low-speed application $c_{d_0}$ may be removed from the
integral — certainly not true for high-speed propellers, however. As shown in Fig. 17.5, the resultant tip
speed of a rotating blade is a function of rotational velocity and true airspeed; at high flight speed and
high propeller rpm (necessary for high thrust) the tip Mach number may approach or surpass the critical
Mach number (~0.9) of the tip sections, and $c_{d_0}$ will experience a drastic increase as $r \to R$.
(For simplicity, skin friction, pressure, and wave drag effects are lumped together in $c_{d_0}$.)
*[Nicolai & Carichner, p. 446]*

Eq. (17.23) provides a key to understanding the rationale behind the selection of a certain propeller
geometry to fulfill given design requirements. For low-to-moderate airspeeds where $c_{d_0}$ is constant,
power requirements may be reduced by minimizing the blade chord toward the tip where dynamic pressure is
greatest. However, this high dynamic pressure in the blade tip region is also responsible for the lion's
share of the

**Fig. 17.5** — *Resultant velocity at a propeller tip* *[Nicolai & Carichner, Fig. 17.5, p. 446]*. Vector
diagram at a propeller tip: rotational velocity $\Omega R$ (vertical), translational velocity $V$
(horizontal, in the direction of flight), and resultant velocity $V_R$ (hypotenuse) forming a right
triangle; "Axis of Rotation" and "Plane of Rotation" reference lines shown, with "Direction of Flight"
arrow pointing left.

resulting thrust, and larger tip chords would be desirable from this standpoint. Some compromise must be
reached, and the results are planforms of the type shown in Fig. 17.6. *[Nicolai & Carichner, p. 447]*

**Fig. 17.6** — *Typical propeller blade planforms* *[Nicolai & Carichner, Fig. 17.6, p. 447]*. Four blade
planform silhouettes (A, B, C, D), each shown with its root hub circle: **A** — narrow elliptical blade
with a small root hub, tapering smoothly to a rounded tip (low-speed general-aviation type); **B** —
wide-chord blade near the root tapering sharply to a narrow tip (high-subsonic type); **C** — nearly
rectangular "paddle blade" with a wide, blunt tip (middle-subsonic type, as used on the original C-130 and
Electra); **D** — inverse-tapered blade, narrower at the root and wider at the tip than C.

Blade A is a type used on low-speed general aviation craft. It features a circular or elliptical root
section developing into an 8%–12% thick section at the outer radii. Operating at rotational tip Mach
numbers approaching 0.8, a propeller utilizing this blade can fly at airspeeds up to approximately Mach =
0.4 before compressibility effects begin to be felt. Blade B exhibits a planform designed for use at
high-subsonic Mach numbers and features thin sections and reduced chord at the tip, minimizing the drag
effects of transonic tip conditions; this class of propeller blade has not found widespread application
because the speed range for which it is designed (Mach = 0.6–0.8) can be more efficiently handled by
turbofan engines. *[Nicolai & Carichner, p. 447]*

A practical blade planform for the middle subsonic range is the "paddle blade" design, blade C, used on
the original C-130 and Electra aircraft. The wide tip chord of this blade would seem to produce higher
compressibility losses, but, as demonstrated in [7], the opposite is true: the blade with a large chord at
the tip will be more efficient than a tapered blade producing the same thrust at the same operating
conditions because the tip sections of the wider, untapered blade operate at a lower $c_\ell$ and have a
higher critical Mach number. This argument would indicate that an even more efficient design would employ
inverse taper as shown by blade D. Although promising from an aerodynamic viewpoint, this approach has not
been accorded wide acceptance because of structural difficulties. *[Nicolai & Carichner, p. 447]*

### §17.3.3 Vortex Theory (p. 448)

Although providing a rapid method for the preliminary calculation of propeller performance, blade element
theory does not provide the accuracy needed for detailed design work — factors such as tip losses,
three-dimensional effects, and mutual blade interference cannot be predicted by this method. For example,
blade element theory indicates that a linear increase in thrust with no change in efficiency will result
from adding blades to a propeller, whereas, in fact, the most efficient propeller consists of a single
blade, with efficiency decreasing as the number of blades increases. *[Nicolai & Carichner, p. 448]*

The third major branch of propeller theory, vortex theory, overcomes many of the limitations of the
previous two methods and offers the capability for great accuracy. The equations required to implement
this theory satisfactorily, however, necessitate the use of large-capacity, high-speed computers. The
details of the vortex theory are beyond the scope of this text and are more the tool of the propeller
designer rather than the aircraft designer; the interested reader is referred to [1,3,4,8]. *[Nicolai &
Carichner, p. 448]*

## §17.4 Preliminary Design (p. 448)

Although the previously discussed theoretical methods for propeller analysis provide convenient and
relatively accurate schemes for predicting the performance of airscrews of known design, they would prove
too cumbersome for preliminary design applications. To establish the propeller design parameters required
by the preliminary design process, various semiempirical methods may be employed. Ref. [9], for example,
provides rapid performance calculations for light aircraft propellers driven by engines of up to 300
horsepower and at flight speeds ranging up to 200 kt. Propellers for larger and faster aircraft may be
accurately analyzed through the methods and charts of [10]. The method developed here is based on [11] and
is applicable for engine ratings over 300 horsepower and for flight Mach numbers up to 0.8. *[Nicolai &
Carichner, p. 448]*

The task of identifying the characteristics of a propeller to meet a given set of performance
specifications is essentially a two-part problem attempting to relate the horsepower available to the
thrust provided by the propeller in the takeoff mode and in the cruise mode. Each of these segments
requires independent methodology, and the results must be faired together to provide a continuous picture
of thrust output for a selected propeller from brake release up through the limits of the aircraft
performance. *[Nicolai & Carichner, p. 448]*

At this stage of the design loop the drag characteristics of the airframe should be well established and
should include a rough approximation of nacelle drag for the selected number of engines. The major design
parameters to be determined at a given flight condition are the propeller diameter and the engine shaft
horsepower required for that condition; all other parameters are defined by technology within rather
narrow limits. If the propeller diameter is fixed by some structural consideration (wing location, landing
gear limitations) or by some aerodynamic consideration such as the ratio of propeller diameter to wing
chord [12,13], the resulting efficiency will be less than optimum, but the design process is simplified
since the required shaft horsepower can be calculated without iteration. *[Nicolai & Carichner, pp.
448–449]*

Certain definitions must be made at this point. As with most aerodynamic quantities, the thrust developed
and power required by a propeller are conveniently expressed as nondimensional coefficients in the
following forms *[Nicolai & Carichner, p. 449]*:

Power Coefficient *[Nicolai & Carichner, Eq. (17.24), p. 449]*:

$$C_P = \frac{P}{\rho n^3 D^5} \tag{17.24}$$

Thrust Coefficient *[Nicolai & Carichner, Eq. (17.25), p. 449]*:

$$C_T = \frac{T}{\rho n^2 D^4} \tag{17.25}$$

where $n$ is the *propeller rotational velocity* in revolutions per second (rps) and $D$ is the diameter of
the airscrew in feet. For generality, a third coefficient is defined to cover the torque $Q$ generated by
the propeller — Torque Coefficient *[Nicolai & Carichner, Eq. (17.26), p. 449]*:

$$C_Q = \frac{Q}{n^2 D^5} = \frac{C_P}{2\pi} \tag{17.26}$$

The ideal efficiency $\eta_i$ has been defined by Eq. (17.9) and should not be confused with another
measure of effectiveness, the *propulsive* (or *propeller*) *efficiency* *[Nicolai & Carichner, Eq.
(17.27), p. 449]*:

$$\eta = \frac{\text{Thrust Power Output}}{\text{Shaft Power Input}} = \frac{TV}{P} \tag{17.27}$$

This expression accounts for profile losses as well as induced losses and may be written as the product
of an induced (or ideal) efficiency $\eta_i$ and a *profile efficiency* $\eta_0$. Thus *[Nicolai &
Carichner, Eq. (17.28), p. 449]*:

$$\eta = \eta_i\eta_0 \tag{17.28}$$

As with the ideal efficiency, the propeller efficiency will be zero under static conditions. *[Nicolai &
Carichner, p. 450]*

Another useful parameter is the *rotational tip speed* of the propeller, $V_{tip}$, defined as *[Nicolai
& Carichner, Eq. (17.29), p. 450]*:

$$V_{tip} = \Omega R = \pi n D \tag{17.29}$$

The rotational tip speed has been given close consideration as a design point in recent years because of
its importance in determining the operating noise level of the aircraft. Producing an aircraft with
acceptable sideline noise levels is a major challenge to designers of both civil and military STOL
aircraft; the reader is encouraged to consult [10,14–16] for further background. Suffice it to say that
700–800 ft/s is an upper limit on $V_{tip}$; in light of the high sound levels created by the C-130 and
Electra with their 720 ft/s tip speeds, even lower values might prove to be more realistic starting
points. *[Nicolai & Carichner, p. 450]*

The ratio of true airspeed $V$ to tip speed has proven to be a powerful design variable, related both to
efficiency and to the aerodynamic coefficients — most often expressed as the *proportional advance ratio*
*[Nicolai & Carichner, Eq. (17.30), p. 450]*:

$$J = V/nD \tag{17.30}$$

Two more parameters are needed to completely define the propeller and its operational conditions: the
blade planform, and the sectional lift characteristics. The latter was defined in the blade element theory
section as a two-dimensional lift coefficient $c_\ell$, which could vary across the blade span. In
practical propeller designs, sectional camber is defined by the *design lift coefficient* $c_{\ell d}$,
and the camber for the entire blade is designated by specifying $c_{\ell d}$ at $r = 0.7R$; generally
$c_{\ell d}$ at $r=0.7R$ varies from 0.4 to 0.6, and minor excursions from the specified value at sections
on either side of $r=0.7R$ have a negligible effect on propeller performance. *[Nicolai & Carichner, p.
450]*

The blade planform is expressed by the *activity factor* (AF), which represents the rated power absorption
capability of all blade elements. Eq. (17.23) indicates that the power absorbed by a blade element is
proportional to the area of the element times the cube of the velocity. By assuming $V_e \sim \Omega r$,
the power may be expressed as *[Nicolai & Carichner, Eq. (17.31), p. 450]*:

$$dP\,\alpha\,c(\Omega r)^3\,dr \tag{17.31}$$

because at flight velocities $dP_0 \gg dP_i$. This expression has been nondimensionalized with $V_{tip}$
and $D$ to form a function of purely geometric properties and yet one that reflects the relative ability
of the blade to absorb power. The activity factor is conventionally defined as *[Nicolai & Carichner, Eq.
(17.32), p. 451]*:

$$AF = \frac{100{,}000}{16}\int_{0.15}^{1.0}\left(\frac{c}{D}\right)\left(\frac{r}{R}\right)^3
d\left(\frac{r}{R}\right) \tag{17.32}$$

for a single blade. The propeller AF is simply the blade AF times the number of blades $b$. Values for
blade AF are usually constrained by structural considerations to values between 80 and 180; for example,
the blade AF for the C-130 is 162. *[Nicolai & Carichner, p. 451]*

The design process may be initiated with either the takeoff condition or the cruise condition, depending
on the mission specifications. The designer must realize that the requirements for the two regimes may
not be compatible and that a compromise solution most probably will be required. The following discussion
assumes that takeoff performance is not a driving consideration and that the aircraft design is being
optimized for cruise. *[Nicolai & Carichner, p. 451]*

The general methodology for designing a propeller for cruise flight ($J > 1.4$) is outlined in Fig. 17.7.
Again, it is emphasized that only the drag characteristics of the airframe and the approximate specific
fuel consumption (SFC) vs. power setting and flight condition (speed and altitude) of the class of engine
to be used need be known to begin the design procedure; all other parameters may be selected within the
limitations previously discussed or calculated from the accompanying charts. *[Nicolai & Carichner, p.
451]*

Fig. 17.8 permits the computation of the propeller AF and a *basic induced efficiency* $\eta_i'$. Because
this chart is based on a six-blade propeller and a $C_\ell$ at $r=0.7R$ of 0.5, a correction must be made
to $\eta_i'$ to produce the induced efficiency $\eta_i$. The value specified for the representative lift
coefficient is a reasonable value and may be used with good success for preliminary design purposes;
however, changes to $c_\ell$ at $r=0.7R$ within the acceptable 0.4–0.6 range produce a negligible change
in $\eta$ and produce thrust and power figures still well within the accuracy limitations required in
initial aircraft design iterations. The basic induced efficiency should be corrected for number of blades
and total activity factor using Fig. 17.9. With a value for $\Delta\eta_i$, the actual induced efficiency
becomes *[Nicolai & Carichner, Eq. (17.33), p. 451]*:

$$\eta_i = \eta_i' + \Delta\eta_i \tag{17.33}$$

The profile efficiency is obtained from Fig. 17.10 as a function of advance ratio $J$ and flight Mach
number. The total efficiency is then calculated using Eq. (17.28); this value of $\eta$ may be corrected
for compressibility effects with the addition of a term $\Delta\eta_c$ from Fig. 17.11 [17]. *[Nicolai &
Carichner, p. 451]*

A word of explanation should be given: the term *shaft horsepower* (SHP) used in this procedure is the
engine output that is actually available to turn

**Fig. 17.7** — *Propeller analysis procedure for cruise* *[Nicolai & Carichner, Fig. 17.7, p. 452]*.
Flowchart headed "KNOWN: Aircraft Drag, SFC=f(SHP)": Select $V_{tip}$ → branches to (1) Specify $V,h$ →
(2) Estimate Drag → (3) Estimate SHP → Compute $J,\eta$ → Calculate $\eta_0$ (Fig. 17.10); parallel branch
Calculate $\eta_i'$ & $AF_{TOT}$ (Fig. 17.8) → Compute $b$ based on blade AF limits → Calculate
$\Delta\eta_i$ (Fig. 17.9) → Compute $\eta_i = \eta_i'+\Delta\eta_i$ → Calculate $\Delta\eta_c$ (Fig.
17.11); both branches merge at Compute $\eta = \eta_i\eta_0+\Delta\eta_c$ → Compute $T=\eta V(SHP)$;
Compare with Drag → (4) Return to (3), re-estimate SHP, compute new $\eta$ → Compute new $T$ and compare
with Drag; continue between (3) and (4) until $T$ = Drag → Return to (2) to compute as many Drag, $\eta$,
SHP combinations as desired → Select $D$, SHP combination that maximizes $\eta$/SFC in range equation [Eq.
(17.11) — note: cross-reference to the *range equation*, distinct from this chapter's Eq. (17.11)] →
Return to (1) and select other $V,h$ combinations → Select Drag, cruise SHP, $V$, & $h$ combination that
best fulfills mission specs → RESULTS: Drag, AF, $b$, $n$, $D$ specified; $V$, $h$, SHP optimized for
cruise.

the propeller; it consists of the engine power at the given flight condition corrected for any bleed and
auxiliary equipment losses and accounting for the inefficiency of the reduction gear. *[Nicolai &
Carichner, p. 452]*

This method applies to single-rotation propellers and does account for energy lost in the rotational
motion of the slipstream. Approximately 60% of this lost rotational energy may be recovered through the
use of dual counter-rotating propellers. The *rotational power expended* ($P_R$) may be obtained from Fig.
17.12 in the ratio of $P_R/P$. The induced efficiency of a dual-rotation propeller may then be found using
the expression

**Fig. 17.8** — *Propeller basic induced efficiency for cruise ($b=6$, $c_{\ell d}=0.5$) (data from [11])*
*[Nicolai & Carichner, Fig. 17.8, p. 453]*. Two linked nomograph panels with a worked dashed-line example
("Start"): left panel plots Shaft Horsepower (1000s, 1–10, log-like scale) vs. a family of curves labeled
by diameter $D$ = 10, 12, 14, 16, 18, 20 ft, cross-referenced by Altitude (ft) = 10,000/20,000/30,000/
40,000/50,000 curves at the top; right panel plots basic induced efficiency $\eta_i$ (80–98) vs. two curve
families — solid curves labeled by total activity factor $c_{\ell d}=0.5$ (300–1000) and dashed/solid
curves labeled by $V/\eta D$ = 14–60 and $\pi\eta D$ = 500–1000 at the top. The dashed example path
traces: Shaft Horsepower ≈ 3800 at $D$ ≈ 15 ft/Altitude ≈ 30,000 ft → across to the right panel →
down to $\eta_i \approx 90.5$.

**Fig. 17.9** — *Blade number correction to basic induced efficiency* *[Nicolai & Carichner, Fig. 17.9, p.
454]*. Plot of $\Delta\eta_i$ (−0.06 to +0.02) vs. Advance Ratio $J$ (1–6). A horizontal reference line at
$\Delta\eta_i = 0$ for $b=6$. Above it, three closely spaced curves for $b=8$ (labeled $AF_{TOT}$ = 800,
900, 1000), rising from ~0 at $J=1$ to ~0.02–0.025 at $J=6$. Below the reference line, two groups of
curves: $b=4$ ($AF_{TOT}$ = 400, 500, 600), declining from about −0.008 to −0.03; and $b=3$ ($AF_{TOT}$ =
300, 400, 500), declining more steeply from about −0.02 to −0.055 at $J=6$.

**Fig. 17.10** — *Estimated profile efficiency* *[Nicolai & Carichner, Fig. 17.10, p. 454]*. Plot of
Profile Efficiency $\Delta\eta_0$ (0.4–1.0) vs. Flight Mach Number $M$ (0.4–0.9), with four curves labeled
$J$ = 6, 4, 3, 2. All curves start near 0.92–0.94 at $M=0.4$–0.5 and remain roughly flat until a Mach
number that depends on $J$ (higher $J$ curves hold up to higher Mach before dropping), then decline
steeply — the $J=2$ curve drops earliest (starting ~M=0.5) to ~0.5 by $M=0.83$; the $J=6$ curve holds
until ~M=0.75 before dropping to ~0.68 by $M=0.85$.

**Fig. 17.11** — *Compressibility correction to propeller efficiency* *[Nicolai & Carichner, Fig. 17.11, p.
455]*. Plot of $\Delta\eta_c$ (0 to −0.16) vs. Resultant Tip Mach Number (0.7–1.1). Two curves, flat at 0
until Mach ≈ 0.9, then dropping: "Thin Section (t/c) = 0.06" declines more gently, reaching about −0.115
at Mach 1.1; "Thick Section (t/c) = 0.10" declines more steeply, reaching about −0.155 at Mach ≈ 1.07.

**Fig. 17.12** — *Efficiency correction for dual-rotation propellers* *[Nicolai & Carichner, Fig. 17.12, p.
455]*. Plot of $P_R/P$ (0.02–0.20) vs. Advance Ratio $J$ (0–7), with curve pairs for $b=6$ (heavy lines)
and $b=8$ (light lines) at total activity factors $AF_{TOT}$ = 600, 700, 800, 900, 1000 — all curves rise
roughly linearly from ~0.03–0.05 at low $J$ to 0.12–0.18 at $J=6$, with higher $AF_{TOT}$ and $b=8$ giving
higher $P_R/P$ at a given $J$.

$$\eta_i = \eta_i' + \Delta\eta_i + 0.6\frac{P_R}{P} \tag{17.34}$$

*[Nicolai & Carichner, Eq. (17.34), p. 456]*

Counter-rotating propellers offer a significant increase in efficiency, particularly for cases of high
propeller activity factor and large numbers of blades (≥6); however, they do require an increase in weight
due to the associated gearing. Only the Soviet Union made extensive use of this feature, on the An-22,
Tu-95, and Tu-114. *[Nicolai & Carichner, p. 456]*

The process of selecting or evaluating a propeller for takeoff conditions is generally simpler than a
similar task for cruise flight because more information is known. For the case where the propeller has
been optimized for cruise, AF, $D$, and $n$ have already been determined; specification of SFC vs. SHP in
cruise will, for a given class of engines, establish the takeoff SHP, and the designer need only analyze
the thrust produced by the propeller–engine combination for use in calculating the takeoff distance. If the
propeller is to be optimized to meet a takeoff specification, a more complex iterative procedure must be
utilized to pick the combination of propeller characteristics that will require the least power and, thus,
the lowest engine weight. *[Nicolai & Carichner, p. 456]*

The methodology for both of the preceding procedures is outlined in Fig. 17.13. In each case the takeoff
velocity of the aircraft must be known (Chapter 10). Because the concept of propeller efficiency becomes
meaningless for low airspeeds, the takeoff problem is one of finding the relationship between thrust
produced and power required (or between $C_T$ and $C_P$). Fig. 17.14 provides this relationship but it is
expressed in terms of an *intermediate power coefficient* $C_{P_x}$, which is not corrected for variable
activity factors. The correction to $C_P$ may be obtained from Fig. 17.15, and the actual power
coefficient may be computed from *[Nicolai & Carichner, Eq. (17.35), p. 456]*:

$$C_P = X(C_{P_x}) \tag{17.35}$$

As with the calculation of cruise performance, the propeller tip speed is an important parameter for
propeller analysis at takeoff. Noise criteria are especially critical during airfield operations, and the
designer must make a difficult tradeoff between performance and sideline noise levels. Depending on the
type of engine utilized, the tip speed in takeoff need not be the same as that in cruise, but generally
(unnumbered relation, p. 456):

$$(V_{tip})_{TO} \ge (V_{tip})_{cruise}$$

Once more it must be emphasized that the designer may have to accept a propeller that is optimized for
neither takeoff nor cruise to produce an

**Fig. 17.13** — *Propeller analysis procedure for cruise compared with takeoff* *[Nicolai & Carichner,
Fig. 17.13, p. 457]*. Two side-by-side flowcharts. **Left, "Propeller Optimized for Cruise"** (KNOWN:
Propeller Characteristics, $SHP_{TO}$): Select $V_{tip}=\pi nD$ → Compute $J$ for $V=0.7V_{TO}$ → Compute
$C_P$, $J/C_P^{1/3}$ → Calculate $X$; Compute $C_{P_x}$ (Fig. 17.15) → Calculate $C_T/C_P^{2/3}$ (Fig.
17.14) → Compute $C_T$ and/or $T = (C_T/C_P^{2/3})(P/nDC_P^{1/3})$. **Right, "Propeller Optimized for
Takeoff"** (KNOWN: $T_{REQ}$ at $V=0.7V_{TO}$): Select $V_{tip}=\pi nD$ → (1) Select $D$ → Compute $n,J,C_T$
→ (2) Select $b$ & Compute $AF_{TOT}$ → Calculate $X$ (Fig. 17.15) → (3) Estimate $SHP_{TO}$ or $C_P$ →
Compute $C_{P_x}$, $J/C_P^{1/3}$ → Calculate quantity $C_T/C_P^{2/3}$; compare resulting value of $C_P$
with estimated value (Fig. 17.14) → Return to (3), re-estimate $SHP_{TO}$ until estimated & calculated
values of $C_P$ are approximately equal → Return to (1), generate values of $SHP_{TO}$ for other $(D-b)$
combinations → Pick $(D-b)$ combination requiring lowest $SHP_{TO}$.

acceptable performance level for both regimes. A propeller with high cruise efficiency would have blades
with low-cambered sections, whereas the optimum blade for takeoff would have a highly cambered section.
The solution to this dilemma is to design a propeller with variable-camber blades; although such a
propeller would increase weight and cost somewhat, it does permit very low tip speeds at takeoff to
produce desirable noise signatures. *[Nicolai & Carichner, p. 457]*

**Fig. 17.14** — *Propeller performance chart for takeoff (data from [11])* *[Nicolai & Carichner, Fig.
17.14, p. 458]*. Dual-axis plot of $C_T/C_P^{2/3}$ (0–1.2) vs. $J/C_P^{1/3}$ (bottom axis 0–3.2, top axis
0–2.0), split into two regions: left, "$C_{P_x}$ above 0.2" with curves labeled $C_{P_x}$ = 0.2, 0.3, 0.4,
0.6, 0.8, 1.0, 1.2, 1.4 (each roughly flat/declining slightly then converging near $J/C_P^{1/3}\approx3.2$);
right, "$C_{P_x}$ below 0.2" with curves labeled $C_{P_x}$ = 0.06, 0.08, 0.10, 0.15, 0.20 (declining more
steeply with increasing $J/C_P^{1/3}$); a dashed "Theoretical Maximum" envelope curve runs across both
regions from about 1.15 at the origin down to about 0.32 at the right edge.

**Fig. 17.15** — *Power coefficient adjustment factor* *[Nicolai & Carichner, Fig. 17.15, p. 459]*. Plot of
Power Coefficient Correction $X$ (0–2.4) vs. Total Activity Factor $AF_{TOT}$ (0–1200), with two nearly
linear curves: "Dual Rotation" (steeper, starting near $AF_{TOT}\approx70$ and reaching $X=2.4$ by
$AF_{TOT}\approx1100$) and "Single Rotation" (shallower, starting near $AF_{TOT}\approx150$ and reaching
$X\approx1.6$ by $AF_{TOT}=1100$); the two curves cross near $AF_{TOT}\approx250$, $X\approx0.3$.

## §17.5 Shaft Engine Characteristics (p. 459)

In designing a propeller-driven aircraft, the designer must consider the propeller and its engine
together; no discussion of propeller propulsion systems would be complete without some mention of the
engine that will turn the airscrew. Fig. 14.2 shows the SHP-to-weight relationships for a spectrum of
reciprocating and turboshaft engines. In most cases, the turbine engines include the weight of the
reduction gearing required for their application as turboprop engines; the output of these engines is
listed in terms of the shaft horsepower produced to turn the propeller. This is not a complete picture of
the capability of the turboprop powerplant because a certain amount of residual jet thrust $T_J$ is also
being generated (discussed in §14.2.2). *[Nicolai & Carichner, p. 459]*

The propeller tip speed is a function of both propeller diameter and shaft speed $n$; thus, the designer
is concerned with the gear ratio between the power turbine and the output shaft. The Allison T56-A-15
(engine data in Appendix J, Fig. J.3) is designed to operate at a constant turbine speed of 13,820 rpm
while the propeller shaft turns at a more reasonable 1021 rpm. Powerplant thrust changes are accomplished
via simultaneous changes in fuel flow and propeller blade pitch. This same turbine engine could be
designed to operate at a different output rpm with the attachment of a reworked gearbox. Each turboprop
engine is evolved with a specific pro-

peller in mind, and thus the performance is based on the use of a standard reduction gear. *[Nicolai &
Carichner, p. 460]*

The performance of a turboprop is similar to a turbojet in that a performance gain is realized with
increased velocity due to ram recovery up to about 400 kt, where propeller losses start to dominate. For a
reciprocating engine there is no power increase due to ram recovery; as velocity increases, propeller
efficiency decreases due to compressibility effects, and the drag due to cooling causes the thrust of the
propeller–reciprocating-engine combination to drop off rapidly above 200 kt. *[Nicolai & Carichner, p.
460]*

### Example 17.1 — Use of Vendor Propeller Charts (p. 460)

The designer will normally have available both engine and propeller operating charts supplied by the
propeller and engine suppliers. This example uses the Piper PA-28–180 Cherokee Archer with a fixed-pitch
propeller and the PA-28–200 Cherokee Arrow with a constant-speed, variable-pitch propeller. These two
aircraft have the characteristics given in Table 17.1. *[Nicolai & Carichner, p. 460]*

The Cherokee Archer at 7000 ft and 2450 rpm has 135 hp available (from Table 14.1). Using Eq. (17.31), the
advance ratio at the 122-kt cruise speed is:

$$J = V/nD = 206/(40.8)(6.2) = 0.814$$

**Table 17.1** — *Comparison between the Cherokee Archer and Arrow* *[Nicolai & Carichner, Table 17.1, p.
460]*:

| Aircraft | Cherokee Archer | Cherokee Arrow |
|---|---|---|
| Span (ft) | 32 | 32 |
| Wing area (ft²) | 170 | 170 |
| Aspect ratio | 6.02 | 6.02 |
| TOGW (lb) | 2450 | 2650 |
| W/S (lb/ft²) | 14.4 | 15.6 |
| Landing gear | Fixed | Retractable |
| Engine | Lycoming O-360-A | Lycoming IO-360-C1C |
| Maximum rated hp | 185 | 200 |
| Propeller | Sensenich fixed pitch | Hartzell variable pitch |
| Propeller diameter (ft) | 6.2 | 6.2 |
| Maximum speed (kt) | 129 | 152 |
| Cruise speed (kt) | 122 at 7000 ft, 2450 rpm | 143 at 7000 ft, 2450 rpm |
| Stall speed (kt) | 53 | 57 |

**Fig. 17.16** — *Estimated propeller efficiency for the Piper Cherokee Archer PA-28 (courtesy of Sensenich
Propeller Manufacturing Co., Inc.)* *[Nicolai & Carichner, Fig. 17.16, p. 461]*. Plot of Propeller
Efficiency $\eta$ (0–1.0) vs. Advance Ratio $J=V/nD$ (0.2–1.0) for a "Fixed Pitch, diameter = 6.2 ft"
propeller: a single curve rising from ~0.44 at $J=0.24$ to a peak of ~0.81 around $J=0.75$–0.8, then
declining to ~0.57 by $J=1.0$.

From Fig. 17.16 the fixed propeller efficiency $\eta = 0.8$. Using Eq. (17.27) the propeller thrust
$T = \eta P/V = (0.8)(135)(550)/206 = 288$ lb. If the weight fraction for engine start and climb to 7000 ft
is assumed to be 0.97, the aircraft weight is 2376 lb and the $L/D = 8.26$; the aircraft $C_D = 0.0435$ at
the cruise condition. *[Nicolai & Carichner, p. 461]*

Using the published brake specific fuel consumption (BSFC) for the Lycoming O-360-A (from Table 14.1) of
0.47 lb/bhp·h, the fuel flow is 63.5 lb/h. For a trip of 400 n mile the Archer would burn about 208 lb of
fuel. *[Nicolai & Carichner, p. 461]*

For the Cherokee Arrow (Figs. 17.17 and 17.18) at 7000 ft and 2450 rpm, the available power from its
IO-360-C1C is 150 hp. At its cruise speed of 143 kt the propeller advance ratio is $J = 0.95$. Because the
aircraft is equipped with a constant-speed propeller, use the blade-pitch data as shown in Fig. 17.18.
Calculating the power coefficient using Eq. (17.24) gives:

$$C_P = P(\text{ft}\cdot\text{lb})/\rho n^3 D^5 = (150)(550)/(0.001927)(67917)(99161) = 0.069$$

Entering Fig. 17.18 with $J=0.95$ and $C_P=0.069$ gives a blade-pitch angle $b \sim 27$ deg. *[Nicolai &
Carichner, p. 461]*

Fig. 17.17 shows the estimated propeller efficiency for a variable-pitch propeller. The advantage of a
variable-pitch propeller is

**Fig. 17.17** — *Estimated propeller efficiency for the Piper Cherokee Arrow PA-28R (data courtesy of
Hartzell Propeller Inc.)* *[Nicolai & Carichner, Fig. 17.17, p. 462]*. Plot of Propeller Efficiency $\eta$
(0.2–0.9) vs. Advance Ratio $J=V/nD$ (0–2.2), for a "Constant Speed Variable Pitch, diameter = 6.2 ft"
propeller, with a family of curves labeled by Blade Pitch Angle = 15, 20, 25, 30, 35, 40 deg — each rising
steeply from ~0.3 at low $J$ to a broad peak around 0.83–0.87, then dropping off sharply; higher pitch
angles shift the peak to higher $J$.

that the blade angle can be adjusted to give a maximum propeller efficiency for different advance ratios
and power loadings (horsepower per propeller area). Entering Fig. 17.17 with $J=0.95$ and $b=27$ deg gives
a propeller efficiency $\eta = 0.85$. The propeller thrust is:

$$T = \eta P/V = (0.85)(150)(550)/(241.5) = 290 \text{ lb}$$

Notice that the drag of the Arrow is only 2 lb more than the Archer but it is flying 21 kt faster. The
lower drag for the Arrow is due to the retractable gear. The $L/D = 8.85$ for the Arrow and its
$C_D = 0.0319$. The Arrow for the same 400-n-mile trip would burn 197 lb of gas, or 11 lb less than the
Archer, and take almost 30 minutes less time. *[Nicolai & Carichner, p. 462]*

At zero forward speed, the efficiency of a propeller is zero by definition, even though its thrust is not
zero. In fact, for the same shaft power a variable-pitch propeller will produce the most thrust in zero
forward velocity (i.e., its static thrust is greater than the thrust produced in forward flight). Figs.
17.19 and 17.20 can be used to esti-

**Fig. 17.18** — *Estimated propeller power coefficients for the Piper Cherokee Arrow PA-28R (data
courtesy of Hartzell Propeller Inc.)* *[Nicolai & Carichner, Fig. 17.18, p. 463]*. Plot of Power
Coefficient $C=P/\rho n^3D^5$ (0–0.26) vs. Advance Ratio $J=V/nD$ (0–2.4), with a family of curves labeled
by Blade Pitch Angle = 15, 20, 25, 30, 35, 40 deg — each starting at a distinct value on the vertical axis
(higher pitch angle → higher starting $C_P$) and declining toward zero as $J$ increases, with higher pitch
angles extending to higher $J$ before reaching zero.

**Fig. 17.19** — *Decrease of thrust with velocity for different power loadings (data from [18])*
*[Nicolai & Carichner, Fig. 17.19, p. 463]*. Plot of $T/T_0$ (0.5–1.0) vs. Velocity (0–120 ft/s), with a
family of closely spaced curves labeled by power loading $hp/A$ (hp/ft²) = 4, 5, 6, 7, 8 — all starting at
$T/T_0=1.0$ at $V=0$ and declining roughly linearly to between ~0.51 and ~0.61 at $V=120$ ft/s (lower
$hp/A$ giving a steeper decline).

**Fig. 17.20** — *Static thrust and power performance of propellers or rotors (data from [18])* *[Nicolai &
Carichner, Fig. 17.20, p. 464]*. Log–log plot of lb/hp (2–12) vs. $T_0/A$ (1–10, lb/ft² or hp/ft²), with
two curves: "thrust (lb)/ft²" (upper curve, from ~11.3 lb/hp at $T_0/A\approx3.5$ down to ~3 lb/hp at
$T_0/A=8$) and "horsepower/ft²" (lower curve, from ~7.7 lb/hp at $T_0/A\approx1.3$ down to ~2.4 lb/hp at
$T_0/A\approx5.5$).

mate the thrust available from a variable-pitch propeller at low forward speeds. The static thrust is
first obtained from Fig. 17.20 and then reduced by a factor from Fig. 17.19. These charts apply only to a
constant-speed propeller, which allows the engine to develop its rated power regardless of the forward
speed. These charts are used to estimate the static thrust for the Cherokee Arrow. *[Nicolai & Carichner,
p. 464]*

The Arrow at takeoff has 200 hp at 2700 rpm. This gives it a power loading (horsepower per propeller area)
of 6.62 hp/ft². From Fig. 17.20 the static thrust-level per horsepower (lb/hp) is 4.9, giving a static
thrust of 980 lb. The takeoff analysis presented in Chapter 10 calculates the ground run acceleration for
the thrust available at $0.7V_{TO}$, where $V_{TO} = 1.2V_{Stall}$. The stall speed for the Arrow is 57 kt,
or 96 ft/s; so use the thrust at 80 ft/s in the ground run analysis. From Fig. 17.19 the thrust at 80 ft/s
is about 67.5% of the static thrust, or 662 lb. This is a respectable acceleration $T/W$ of 0.25, giving a
takeoff distance of about 1000 ft. *[Nicolai & Carichner, p. 464]*

### References (p. 464–465)

[1] McCormick, B. W., Jr., *Aerodynamics of V/STOL Flight*, Academic Press, New York, 1967.
[2] Theodorsen, T., *Theory of Propellers*, McGraw-Hill, New York, 1948.
[3] Dommasch, D. O., *Elements of Propeller and Helicopter Aerodynamics*, Pitman, New York, 1953.
[4] Glauert, H., "Airplane Propellers," *Aerodynamic Theory*, Vol. 4, edited by William F. Durand, Dover,
New York, 1963.
[5] Gessow, A. and Myers, G. C., Jr., *Aerodynamics of the Helicopter*, Ungar, New York, 1952.
[6] Stepniewski, W. Z., *Introduction to Helicopter Aerodynamics*, Rotorcraft Publishing Committee,
Morton, PA, 1950.
[7] Stack, J., Draley, E. C., Delano, J. B., and Feldman, L., "Investigation of the NACA 4-(3)(08)-045
Two-Blade Propellers at Forward Mach Numbers to 0.725 to Determine the Effects of Compressibility and
Solidity on Performance," NACA TR-999, 1950.
[8] Goldstein, S., "On the Vortex Theory of Screw Propellers," *Proceedings of the Royal Society, Series
A: Mathematical and Physical Sciences*, Vol. 123, 1929.
[9] Crigler, J. L., and Jaquis, R. E., "Propeller-Efficiency Charts for Light Airplanes," NACA TN 1338,
1947.
[10] "Generalized Method of Propeller Performance Estimation," Hamilton Standard Div., Hamilton Standard
Publ. PDB 6101A, United Aircraft Corp., 1963.
[11] Gilman, J., Jr., "Propeller-Performance Charts for Transport Airplanes," NACA TN 2966, 1953.
[12] Kuhn, R. E., and Draper, J. W., "Some Effects of Propeller Operation and Location on the Ability of a
Wing with Plain Flaps to Deflect Propeller Slipstreams Downward for Vertical Takeoff," NACA TN 3360, 1955.
[13] Spreeman, K. P., "Investigation of a Semi-Span Tilting-Propeller Configuration and Effects of Wing
Chord to Propeller Diameter on Several Small-Chord Tilting-Wing Configurations," NASA TN D-1815, 1963.
[14] Stepniewski, W. Z., and Schmitz, F. H., "Noise Implications for VTOL Development," Society of
Automotive Engineers Paper 70–286, 1970.
[15] Hubbard, H. H., "Propeller Noise Charts for Transport Airplanes," NACA TN 2968, 1953.
[16] Rosen, G., and Rohrbach, C., "The Quiet Propeller—A New Potential," AIAA Paper No. 69–1038, 1969.
[17] Perkins, C. D., and Hage, R. E., *Airplane Performance, Stability and Control*, Wiley, New York, 1949.
[18] McCormick, B. W., *Aerodynamics, Aeronautics and Flight Mechanics*, Wiley, New York, 1995.

Chapter 17 extraction complete.
