# Chapter 13 — Estimating Wing–Body Aerodynamics

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 13 "Estimating Wing–Body Aerodynamics," printed pp. 323–355 (PDF pp. 333–366).

Text-layer inventory (to confirm completeness): Figs 13.1–13.24 (incl. 13.3a/13.3b), Tables 13.1–13.3,
Eqs (13.1)–(13.31) (incl. 13.29a/13.29b).

Sections covered per chapter opener: Three-Dimensional Lift Curve Slope; Inviscid Drag-Due-to-Lift
(Induced); Viscous Drag-Due-to-Lift; Skin Friction Drag; Wing Sweep Effects; Drag Divergence Mach
Number; Canopy & Boattail Drag; Vehicle Aerodynamics.

---

## Chapter 13 — Estimating Wing–Body Aerodynamics
*[Nicolai & Carichner, p. 323]*

> **Chapter-opening sidebar (p. 323).** After 25 years of service with the U.S. Air Force, the F-117
> (lower) was retired to the Tonapah Nevada test range. With its second-generation stealth, 64 F-117s
> were produced from 1982 to 1991. The F-22 (upper), with its third-generation stealth, replaced the
> F-117. The F-117 received the Collier trophy in 1989, as did the F-22 in 2006.

> **Pull-quote (p. 323):** "If the aerodynamic estimates appear 'too good to be true,' they probably
> are. Always check estimates with real data."

At this point the design has matured to an aircraft wing–body–tail configuration. Next an
aerodynamic analysis is performed to get a refined estimate of the lift and drag (and later the
stability derivatives) to determine baseline takeoff and fuel weights. If the design does not close
(i.e., the sum of the payload fraction plus the fuel fraction plus the empty-weight fraction does not
equal 1.0), then go back to Chapter 5 and start over.

If this were an industry study, the design would be handed to the aerodynamics group and they would
start modeling to input to computational fluid dynamics (CFD) codes. However, because this is more of
a nonindustry–academic study, we employ well-respected rapid methods developed in the 1970s by the
Air Force Flight Dynamics Laboratory [1], the National Advisory Committee for Aeronautics (NACA; now
the National Aeronautics and Space Administration [NASA]), and others. The aerodynamic derivatives
covered in this chapter are $C_{L_\alpha}$, $K$, $K'$, $K''$, and $C_{D_0}$.

> **Sidebar — Aircraft Big and Small (p. 324).** It is worth mentioning that the aero analysis and
> performance methods for a 6-ft wing span, 8-lb radio-controlled (R/C) model airplane are identical
> to those for a full-scale airplane such as a Cessna 172 (36-ft wing span, 2300 lb). Thus, the
> methods discussed in this text are applicable to aircraft big and small. The only differences
> between the R/C model and the full-scale airplane are the wing loading, the Reynolds number, and
> the moments of inertia.
>
> The R/C model wing loading is one to two orders of magnitude less than a full-scale airplane
> (because of the "square–cube law"; see Appendix I). R/C models typically have wing loadings of
> 1–3 lb/ft² whereas full-scale airplanes have greater than 10 (Cessna 172 has 12.6 lb/ft²). The
> impact is lower stall speeds and shorter takeoff and landing distances.
>
> The R/C model will typically have Reynolds numbers less than 500,000, which gives the wing a
> predominately laminar boundary layer. Full-scale airplanes have Reynolds number greater than one
> million and have turbulent boundary layer wings. The impact is that the full-scale airplanes have
> higher maximum lift coefficients due to the turbulent boundary layer delaying flow separation over
> the wing better than the laminar boundary layer. The R/C models and the full-scale airplanes are in
> a Reynolds number region where the drag coefficients are about the same.
>
> The R/C model will have much smaller moments of inertia than the full-scale airplane. The impact is
> that the time-to-double-amplitude ($t_2$) from a disturbance will be much shorter for the R/C model
> because $t_2 = f(1/(\text{moment of inertia})^{1/2})$. R/C pilots will have their hands full with a
> neutral or unstable model.

## §13.1 Linear Lift Curve Slope
*[Nicolai & Carichner, p. 325]*

The subsonic $C_L$ vs $\alpha$ curve for low aspect ratio wings (AR < 4) has a linear and a nonlinear
region as shown in Fig. 13.1 (see the $C_{L_\alpha}$ for AR = 2 in Figs. H.2 and H.3).

The wing lift coefficient is given by the expression

**Eq (13.1)** *[Nicolai & Carichner, Eq. (13.1), p. 325]*:
```
C_L = (C_L_alpha)(alpha - alpha_0L) + C_1 * alpha^2
```
where $C_{L_\alpha}$ is the linear lift curve slope and $C_1$ is the nonlinear lift factor. The value
of $C_1$ is determined from Fig. 2.13. The value of $C_1$ can be assumed zero for $M_\infty > 1$
flight. Performance calculations of cruise range, climb-out, and acceleration to cruise Mach seldom
require angles-of-attack in the nonlinear range. However, the nonlinear lift may be important for
landing and takeoff.

**Fig. 13.1** — *Wing $C_L$-vs-$\alpha$ curve showing nonlinear behavior for low-AR wings*
*[Nicolai & Carichner, Fig. 13.1, p. 325]*. $C_L$ vs. Angle-of-Attack $\alpha$, showing a straight
dashed reference line "SLOPE = $(dC_L/d\alpha)_{\alpha=0} = (C_{L_\alpha})_{\alpha=0}$" and the actual
curved solid line departing from linear near $\alpha \approx 12$ deg and peaking at $\alpha_{stall}$
(labeled "AR < 4"), then falling off past stall. X-axis marks $\alpha_{0L}$ (zero-lift AoA), 0, ~12
deg, $\alpha_{stall}$.

### §13.1.1 Subsonic
*[Nicolai & Carichner, p. 325]*

The subsonic linear lift curve slope $C_{L_\alpha}$ per radian is given by Eq. (2.13) of Chapter 2:

**Eq (13.2)** *[Nicolai & Carichner, Eq. (13.2), p. 325]*:
```
dC_L/d_alpha = C_L_alpha = (2*pi*AR) / (2 + sqrt(4 + AR^2*beta^2*(1 + [(tan^2(Delta_t/c))/beta^2])))
```
where
```
beta = sqrt(1 - M_inf^2)
Delta_t/c = sweep of maximum thickness line
```

Equation (13.2) is the $C_{L_\alpha}$ of the wing only and is therefore based upon the exposed wing
planform area $S_e$.

### §13.1.2 Supersonic
*[Nicolai & Carichner, p. 326]*

The method for estimating the wing supersonic lift curve slope is developed using supersonic linear
theory corrected for three-dimensional flow effects. The wing $C_{L_\alpha}$ is determined using the
charts in Fig. 13.2, where $C_N$ is the normal force coefficient slope and is equal to $C_L$ for small
to moderate angles-of-attack. In Fig. 13.2, $\beta=\sqrt{M_\infty^2-1}$, AR is the wing aspect ratio,
and lambda ($\lambda$) is the taper ratio.

Here again $C_{L_\alpha}$ is based upon exposed wing planform area.

**Fig. 13.2** — *Theoretical wing lift curve slope (data from [2,3])* *[Nicolai & Carichner, Fig.
13.2, pp. 326–327]*. Four-panel chart set, one panel per taper ratio $\lambda$ = 0, 0.25, 0.5, 1.0
(panels a–d). Each panel plots $\tan\Lambda_{LE}(C_{N\alpha})_{theory}$ (left axis, per radian) vs.
$\beta/\tan\Lambda_{LE}$ (subsonic-leading-edge region, left half) and
$\beta(C_{N\alpha})_{theory}$ (right axis, per radian) vs. $\tan\Lambda_{LE}/\beta$
(supersonic-leading-edge region, right half), with a family of curves parametrized by
$\text{AR}\tan\Lambda_{LE}$ = 0.25, 0.5, 1, 2, 3, 4, 5, 6, plus dashed "Unswept Trailing Edge" and
"Sonic Trailing Edge" boundary curves. All four panels converge to the flat-plate supersonic value of
4 per radian at $\tan\Lambda_{LE}/\beta \to 0$.

### §13.1.3 Transonic
*[Nicolai & Carichner, p. 327]*

There is no well-defined method for estimating transonic $C_{L_\alpha}$. Reference [1] reports an
empirical method that works reasonably well. The method is too complicated and cumbersome to present
here, so an alternate method is suggested.

The $C_{L_\alpha}$ vs Mach number behavior will be as shown in Fig. 13.3a. Use the subsonic method up
to about Mach 0.9 and extend the supersonic method down to about Mach 1.3. Then fair in a curve
between Mach = 0.9 and 1.3 similar to the curves shown in Fig. 13.3a.

### §13.1.4 Wing–Body $C_{L_\alpha}$
*[Nicolai & Carichner, p. 328]*

The lift characteristics of a wing and a body do not add directly to give the wing–body lift.
Rather, there are interference effects of one component on the other that make the wing–body lift
greater than the sum of the individual components [4]. A method that gives good results for the
wing–body linear lift curve slope is

**Eq (13.3)** *[Nicolai & Carichner, Eq. (13.3), p. 329]*:
```
(C_L_alpha)_WB = F * (C_L_alpha)_W
```
where $(C_{L_\alpha})_W$ is the linear lift curve slope (based upon the exposed wing area) of the
wing and $F$ is the wing–body lift interference factor shown in Fig. 13.4. The $(C_{L_\alpha})_{WB}$
is the wing–body lift curve slope and is referenced to the exposed wing planform area $S_e$.

The final curve of wing–body $C_{L_\alpha}$ vs Mach number can be compared with the experimental data
shown in Fig. 13.3a. Notice that the $(C_{L_\alpha})_{WB}$ presented in Fig. 13.3a are referenced to
the total wing planform area $S_W$. The aircraft aerodynamic derivatives can be referenced to either
$S_e$ or $S_W$ (see Fig. 7.1), but they must all be referenced to the same reference area. The total
wing planform area $S_W$ is more conventional and is recommended.

**Fig. 13.3a** — *Linear lift curve slope for various wing–body combinations ($C_{L_\alpha}$ based on
total planform area)* *[Nicolai & Carichner, Fig. 13.3a, p. 328]*. $dC_L/d\alpha$ at $\alpha=0$
(log scale, 0.001–0.10, per degree, referenced to wing planform area $S$) vs. Mach Number (log scale,
0.1–10). Family of curves for AR = 0.5, 1, 2, 3, 4, each rising to a peak near Mach ~1.0–1.2 then
decaying toward the "Supersonic Linear Theory" asymptote at high Mach. Overlaid: SR-71 flight-test
data points (AR = 1.72, c.g. @ 28% c̄) tracking closely with the AR=2 theoretical curve. References
noted on plot: (1) NACA RM A53A30, 1958; (2) USAFA Wind Tunnel; (3) SR-71 flight test.

**Fig. 13.3b** — *Drag-due-to-lift factor (based on total planform area) for uncambered wing–body
combinations with delta planforms and LE radius of 0.045% chord* *[Nicolai & Carichner, Fig. 13.3b,
p. 329]*. $K = dC_D/dC_L^2$ (log scale, 0.1–10) vs. Mach Number (log scale, 0.1–10). Family of curves
for AR = 0.5, 1, 2, 3, 4, 5, each roughly flat subsonically, dipping slightly transonically, then
rising toward the "Supersonic Linear Theory" asymptote $K=\sqrt{M^2-1}/4$ at high Mach. Overlaid:
SR-71 flight-test data points (AR = 1.72, c.g. @ 28% c̄) tracking the AR=2 theoretical curve.

**Fig. 13.4** — *Wing–body interference factor (data from [5–7])* *[Nicolai & Carichner, Fig. 13.4,
p. 330]*. $F$ (1.0–7.0) vs. Body Diameter/Wing Span ($d/b$, 0–0.6), per the formula
$(C_{L_\alpha})_{WB} = F\cdot(C_{L_\alpha})_W$ where $C_{L_\alpha}$ is based upon exposed wing area
$S_e$ (cross-hatched region in the inset planform sketch showing body diameter $d$ and wing span $b$).
Four data/curve sets, all rising from $F=1.0$ at $d/b=0$ to $F\approx4$–6.5 at $d/b\approx0.55$:
AR=4.0 (Mach=3.50), AR=3.0 (Mach=2.50), AR=2.0 (Mach=1.44), AR=1.0 (Mach=0.15).

## §13.2 Drag-Due-to-Lift
*[Nicolai & Carichner, p. 331]*

The total drag coefficient for a wing–body combination is expressed as

**Eq (13.4)** *[Nicolai & Carichner, Eq. (13.4), p. 331]*:
```
C_D = (C_D0)_wing + (C_D0)_body + Delta_C_D0 + C_DL
```
where $\Delta C_{D0}$ is the zero-lift drag coefficient due to miscellaneous protuberances (canopy,
pitot tube, etc.) and $C_{DL}$ is the drag coefficient due to lift. Estimating the wing–body $C_{DL}$
is difficult as discussed below; [3] calls it more of an art than a science. The wing–body $C_{DL}$
is primarily due to the wing so that it is safe to assume

```
wing-body C_DL ~= wing C_DL
```

The methods for $C_{DL}$ that follow use wing geometry primarily but represent the entire wing–body
$C_{DL}$ referenced to $S_W$.

### §13.2.1 Subsonic
*[Nicolai & Carichner, p. 331]*

In subsonic flow the total drag coefficient for the wing is expressed as

**Eq (13.5)** *[Nicolai & Carichner, Eq. (13.5), p. 331]*:
```
C_D = C_Dmin + K'*C_L^2 + K''*(C_L - C_lmin)^2
```

The terms containing $K'$ and $K''$ are collectively called the *drag-due-to-lift*. This parabolic
behavior of $C_D$ with $C_L$ is shown in Figs. 2.16 and 2.17.

The $K'$ term in Eq. (13.5) is the *inviscid* drag-due-to-lift called the *induced drag*. This drag
results from the vortices trailing off a finite wing inducing a downwash at the wing aerodynamic
center. The $K''$ term is the *viscous* drag-due-to-lift caused by flow separation and increased skin
friction. This drag results from the viscous nature of the fluid causing the separation point on the
upper surface to move forward from the trailing edge as the wing rotates to higher angles-of-attack
and the region of adverse pressure gradient spreads. There is also an increase in skin friction
occurring in the leading edge region due to the local supervelocities associated with increasing
lift. The $C_{l_{min}}$ is the lift coefficient for minimum drag coefficient $C_d$. For cambered
airfoils, $C_{l_{min}} \neq 0$ and is approximately equal to the $C_l$ for $\alpha=0$. For symmetric
airfoils, $C_{l_{min}}=0$ and Eq. (13.5) is expressed as

**Eq (13.6)** *[Nicolai & Carichner, Eq. (13.6), p. 331]*:
```
C_D = C_D0 + K*C_L^2
```
where $K=K'+K''=dC_D/dC_L^2$ and is called the drag-due-to-lift factor. The variation of $K$ with Mach
number is shown in Fig. 13.3b for low-AR wing–bodies. The SR-71 is certainly a low AR aircraft
(AR = 1.72) and its $K$ from flight test data agrees well with Fig. 13.3b. Figure G.9 shows the
subsonic $K = 1/(\pi \cdot \text{AR} \cdot e)$ for many real aircraft (symmetric and cambered).
Figure G.9 is empirical and discussed in Appendix G. The $C_{D0}$ is called the zero-lift drag
coefficient. It should be pointed out that $C_{D0} \approx C_{D_{min}}$ for wings with cambered
airfoils, and the terms $C_{D0}$ and $C_{D_{min}}$ are often used interchangeably. This text will use
the term $C_{D0}$ to mean both $C_{D0}$ (for wings with symmetric airfoils) and $C_{D_{min}}$ (for
wings with cambered airfoils). This is not done to confuse the reader but rather in keeping with
convention.

Equations (13.5) and (13.6), which display the parabolic behavior of $C_D$ with $C_L$, are valid only
up through moderate values of $C_L$. At a $C_L$ called the *break $C_L$*, $C_{LB}$, the drag
coefficient ceases to be parabolic with $C_L$ as shown in Fig. 2.17. As the $C_L$ increases past
$C_{LB}$ the drag-due-to-lift increases sharply from that expected from a parabolic behavior. The
flow phenomenon involved here is not too well understood. However, it is connected with the onset of
trailing edge separation spreading rapidly over the upper surface and/or the onset of leading edge
separation spreading rapidly over the upper surface with no reattachment [8]. For $C_L$s above
$C_{LB}$ the expression for total drag coefficient is expressed as

**Eq (13.7)** *[Nicolai & Carichner, Eq. (13.7), p. 332]*:
```
C_D = C_D0 + K'*C_L^2 + K''*(C_L - C_lmin)^2 + Delta_C_DB
```
where $\Delta C_{DB}$ is the drag deviation from a parabolic behavior (see Fig. 2.17).

The prediction method for $\Delta C_{DB}$ is complicated and will not be presented here. The method is
presented in [8].

The viscous drag-due-to-lift factor $K''$ is dependant primarily on LE radius, camber, and $Re$, and
secondarily on taper ratio for sharp-edged airfoils. Determining $K''$ is difficult as it is
viscous-dominated. Reference [9] offers a method shown on Fig. 13.6. Fig. 13.6 is independent of
camber and $Re$, and it tends to overestimate $K''$; however, for symmetric or low camber airfoils, it
offers a rapid estimate of $K''$.

A better method (and the one recommended) is to determine

*(unnumbered equation)* *[Nicolai & Carichner, p. 332]*:
```
K'' = Delta(C_d - C_dmin) / Delta(C_l - C_lmin)^2
```
directly from airfoil polar data by plotting $\Delta(C_d-C_{d_{min}})$ vs $\Delta(C_l-C_{l_{min}})^2$
and determining the slope (see Section F.4).

The induced drag-due-to-lift factor $K'$ is given as

**Eq (13.8)** *[Nicolai & Carichner, Eq. (13.8), p. 332]*:
```
K' = 1 / (pi * AR * e)
```
Where $e$ is called the wing efficiency factor and corrects the finite wing theory result (see
Chapter 2) for taper ratio, sweep and body effects on the span loading. The $e$ factor is best
determined from CFD using a vortex lattice method.

**Fig. 13.5** — *Weissinger wing planform efficiency factor (data from [1])* *[Nicolai & Carichner,
Fig. 13.5, p. 333]*. Four stacked panels, one per taper ratio $\lambda$ = 0, 0.25, 0.50, 1.0, each
plotting Wing Planform Efficiency Factor $e'$ (0.9–1.0) vs. Wing Aspect Ratio Factor (0–6), with
curves for quarter-chord sweep $\Delta_{c/4}$ = 0, 15, 30, 45, 60 deg (and an extra 30 deg curve on
the $\lambda=0$ panel). All curves start at $e'=1.0$ at AR factor = 0 and decrease with increasing
sweep and aspect ratio factor, most steeply for $\lambda=0$ (unswept-TE delta-like planforms) at high
sweep.

The $e$ factor can also be determined from

**Eq (13.9)** *[Nicolai & Carichner, Eq. (13.9), p. 333]*:
```
e = e' * [1 - (d/b)^2]
```
where $d/b$ is the ratio of body diameter to wing span (see Fig. 13.4). The $e'$ factor has been
formulated by Weissinger in [10] and is presented in Fig 13.5. Figure 13.5 was developed for fighter
type aircraft and tends to overestimate the $e$ for large aspect ratio configurations.

**Fig. 13.6** — *Viscous drag-due-to-lift factor $K''$ (data from [9]); LE radius for NACA airfoils
shown on Fig. F.2* *[Nicolai & Carichner, Fig. 13.6, p. 334]*. $K''$ (0–0.16) vs. Leading Edge Radius
(%chord, 0–0.6), family of curves for taper ratio $\lambda$ = 0, 0.25, 0.50, 0.75, 1.0, all decreasing
monotonically from a peak near $r_{LE}=0$ (highest for $\lambda=0$) toward a common low asymptote near
$r_{LE}/c=0.6$.

An alternate method (and the one recommended) is to estimate $K$ from Fig. G.9 and determine $K'$
from $K'=K-K''$ as discussed in Section G.2.

### §13.2.2 Supersonic
*[Nicolai & Carichner, p. 334]*

The supersonic drag-due-to-lift is developed from supersonic linear theory (Chapter 2). For wings
with supersonic leading edges the drag-due-to-lift factor $K$ is given by

**Eq (13.10)** *[Nicolai & Carichner, Eq. (13.10), p. 334]*:
```
K = 1 / C_L_alpha
```
where $C_{L_\alpha}$ is the wing–body lift curve slope (per radian) referenced to $S_{ref}$. Using the
$C_{L_\alpha}=1.6$ per radian value for the SR-71 at Mach = 3.0 from Fig. 13.3a gives $K=0.62$, which
agrees well with the flight test data of Fig. 13.3b.

For wings with subsonic leading edges, the drag-due-to-lift is less than that given by Eq. (13.10)
because of the suction of the leading edge. Thus, the general expression for supersonic drag-due-to-
lift factor $K$ is

**Eq (13.11)** *[Nicolai & Carichner, Eq. (13.11), p. 334]*:
```
K = 1/C_L_alpha - Delta_N
```
where $\Delta N$ is the leading edge suction parameter. The $\Delta N$ parameter is determined from
[8] as

**Eq (13.12)** *[Nicolai & Carichner, Eq. (13.12), p. 335]*:
```
Delta_N = (Delta_N / Delta_N_(M=1.0)) * (Delta_N_(M=1.0))
```
where $(\Delta N/\Delta N_{M=1.0})$ is obtained from Fig. 13.7 and

*(unnumbered equation)* *[Nicolai & Carichner, p. 335]*:
```
Delta_N_(M=1.0) = 1/(C_L_alpha)_(M=1.0) - (K' + K'')
```

The $K'$ and $K''$ are the subsonic inviscid and viscous drag-due-to-lift factors already determined.
The term $(C_{L_\alpha})_{M=1.0}$ is the wing–body lift curve slope at Mach = 1.0 (from Fig. 13.3a).

### §13.2.3 Transonic
*[Nicolai & Carichner, p. 335]*

There is no reliable method for estimating the transonic drag-due-to-lift factor. It is suggested
that a curve be faired between the subsonic and supersonic K curves similar to the experimental data
curves presented in Fig. 13.3b.

**Fig. 13.7** — *Values of LE suction parameter at supersonic speeds (data from [8])*
*[Nicolai & Carichner, Fig. 13.7, p. 335]*. $\Delta N/\Delta N_{M=1.0}$ (0–1.4) vs. $\beta\cot\Delta_{LE}$
(0–1.0), three curves all starting at 1.0 at $\beta\cot\Delta_{LE}=0$ and converging to 0 at
$\beta\cot\Delta_{LE}=1.0$: a dash-dot curve peaking above 1.0 (~1.15) labeled "$\lambda=0$,
$r_{LE}/c<0.1\%$"; a dashed curve staying below 1.0 labeled "$\lambda=0$, $r_{LE}/c<0.1\%$" (second
curve, same label per plot); and a solid curve monotonically decreasing labeled "$\lambda>0.33$, all
$r_{LE}$ or $r_{LE}/c>0.18\%$, all $\lambda$".

## §13.3 Zero-Lift Drag Coefficient
*[Nicolai & Carichner, p. 336]*

The total drag coefficient for a wing–body combination is given by Eq. (13.4) as

**Eq (13.4)** (restated) *[Nicolai & Carichner, Eq. (13.4), p. 336]*:
```
C_D = (C_D0)_wing + (C_D0)_body + Delta_C_D0 + C_DL
```
where the $C_{D0}$s for the wing and the body are determined separately and then added together.
Equation (13.4) implies that the individual drag coefficient terms are all referenced to the same
reference area $S_{ref}$. This $S_{ref}$ can be $S_e$ or $S_{ref}$ but must be the same for all.

The methods for predicting the fuselage and wing $C_{D0}$ will be discussed separately. The wing
methods are limited to wings with straight leading edges. For nonstraight wings, such as a double
delta (Swedish SAAB-35, Draken) or an ogee (Anglo-French Concorde SST), the methods presented in [1]
or [9] should be used.

### §13.3.1 Wing: Subsonic
*[Nicolai & Carichner, p. 336]*

The subsonic wing $C_{D0}$ is primarily skin friction. The expression for $(C_{D0})_W$ based upon the
reference area $S_{ref}$ is given by

**Eq (13.13)** *[Nicolai & Carichner, Eq. (13.13), p. 336]*:
```
(C_D0)_W = C_f * [1 + L*(t/c) + 100*(t/c)^4] * R * (S_wet / S_ref)
```
where
- $L$ = airfoil thickness location parameter
  - $L = 1.2$ for maximum $t/c$ located at $x \geq 0.3c$
  - $L = 2.0$ for maximum $t/c$ located at $x < 0.3c$
- $t/c$ = maximum thickness ratio of the airfoil
- $S_{wet}$ = wetted area of the wing ($2S_e$)
- $R$ = lifting surface correlation factor obtained from Fig. 13.8
- $C_f$ = turbulent flat plate skin friction coefficient

The effect of surface roughness on the skin friction values is determined using a cutoff Reynolds
number. The type of surface is selected and the roughness height is determined from Table 13.1. The
ratio $\ell/k$ is computed and the cutoff Reynolds number, $Re_\ell$, determined from Fig. 13.9. The
$\ell$ is the mean aerodynamic chord $\bar c$ of the wing (see Fig. 7.1). The wing flight Reynolds
number, $Re_e = \rho\bar c V/\mu$, based upon $\bar c$ is determined along a typical subsonic
trajectory (see Chapter 4). Then the smaller of the two Reynolds numbers, $Re_e$ or $Re_\ell$, is used
to determine the $C_f$ from Fig. 2.6.

**Fig. 13.8** — *Lifting surface correlation factor for wing subsonic $C_{D0}$*
*[Nicolai & Carichner, Fig. 13.8, p. 337]*. $R$ (0.8–1.4) vs. $\cos\Delta_{t/c}$ (0.4–0.9), four
curves for $M_\infty \leq 0.25$, 0.6, 0.8, 0.9, all increasing with $\cos\Delta_{t/c}$ and with Mach
number.

**Table 13.1** — *Roughness Height Values (in Equivalent Sand Roughness)* *[Nicolai & Carichner,
Table 13.1, p. 337]*:

| Type of Surface | $k$ (in.) |
|---|---|
| Aerodynamically smooth | 0 |
| Polished metal or wood | 0.02–0.08 × 10⁻³ |
| Natural sheet metal | 0.16 × 10⁻³ |
| Smooth matte paint, carefully applied | 0.25 × 10⁻³ |
| Standard camouflage paint, average application | 0.40 × 10⁻³ |
| Camouflage paint, mass-production spray | 1.20 × 10⁻³ |
| Dip-galvanized metal surface | 6 × 10⁻³ |
| Natural surface of cast iron | 10 × 10⁻³ |

### §13.3.2 Wing: Transonic
*[Nicolai & Carichner, p. 337]*

The transonic regime for the wing begins at $M_{CR}$ but the drag rise is delayed slightly until the
divergence Mach number, $M_D$. The divergence Mach number is defined as that Mach number where
$(\partial C_{D0}/\partial M) = 0.1$. The transonic wing $C_{D0}$ is expressed as

*(unnumbered equation)* *[Nicolai & Carichner, p. 337]*:
```
(C_D0)_W = C_Df + C_DW = C_f*[1 + L*(t/c)]*(S_wet/S_ref) + C_DW
```

**Fig. 13.9** — *Cutoff Reynolds number (data from [1])* *[Nicolai & Carichner, Fig. 13.9, p. 338]*.
Admissible Roughness $\ell/k$ (log scale, $10^2$–$10^7$) vs. Cutoff Reynolds Number $Re_\ell$ (log
scale, $10^5$–$10^9$), four parallel lines for Mach = 0, 1, 2, 3.

The skin friction drag $C_{Df}$ is assumed to be a constant value throughout the transonic region.
The value for $C_{Df}$ is the value at Mach = 0.6.

The task of constructing the wing transonic $C_{DW}$ curve is one of correcting experimental data for
sweep, aspect ratio, and $t/c$ using the von Kármán similarity laws for transonic flow. The transonic
$C_{DW}$ curve for unswept wings is shown in Fig. 13.10. Table 13.2 presents useful values for $t/c$.

The Mach number for drag divergence, $M_D$, of the unswept wing is obtained by locating the point on
the $C_{DW}$ vs Mach curve where the slope is 0.1. The values of peak $C_{DW}$, Mach number for peak
$C_{DW}$, and $M_D$ are corrected for sweep as follows:

**Fig. 13.10** — *Transonic zero-lift wing wave drag for unswept wings* *[Nicolai & Carichner,
Fig. 13.10, p. 339]*. $C_{DW}/(t/c)^{5/3}$ (0–4) vs. $\sqrt{|M^2-1|}/(t/c)^{1/3}$ (1.6 Subsonic to
1.2 Supersonic), family of curves parametrized by $\text{AR}(t/c)^{1/3}$ = 0.5, 1.0, 1.5, 2.0, 3.0,
4.0, each rising steeply from 0 near the sonic condition and leveling off asymptotically at higher
$|M^2-1|^{0.5}/(t/c)^{1/3}$. Data from Rand RM 604 and NACA TR 1253.

**Table 13.2** — *Unswept Wings (Values for $t/c$: Wave Drag)* *[Nicolai & Carichner, Table 13.2,
p. 339]*:

| $t/c$ | $(t/c)^{1/3}$ | $(t/c)^{5/3}$ |
|---|---|---|
| 0.12 | 0.493 | 0.0293 |
| 0.11 | 0.479 | 0.0254 |
| 0.10 | 0.464 | 0.0217 |
| 0.09 | 0.448 | 0.0181 |
| 0.08 | 0.431 | 0.0148 |
| 0.07 | 0.412 | 0.0118 |
| 0.06 | 0.392 | 0.0092 |
| 0.05 | 0.368 | 0.0068 |
| 0.04 | 0.342 | 0.00468 |
| 0.03 | 0.311 | 0.00292 |
| 0.02 | 0.271 | 0.00147 |

**Eq (13.14)** *[Nicolai & Carichner, Eq. (13.14), p. 340]*:
```
Swept M_D = [Unswept M_D] / (cos(Lambda_c/4))^0.5
```

**Eq (13.15)** *[Nicolai & Carichner, Eq. (13.15), p. 340]*:
```
Swept C_DWpeak = [Unswept C_DWpeak] / (cos(Lambda_c/4))^2.5
```

**Eq (13.16)** *[Nicolai & Carichner, Eq. (13.16), p. 340]*:
```
Swept M_CDWpeak = [Unswept M_CDWpeak] / (cos(Lambda_c/4))^0.5
```
where $\Lambda_{c/4}$ = angle of wing quarter-chord.

#### Example 13.1 — Construction of the Transonic $C_{D0}$ Curve
*[Nicolai & Carichner, p. 340]*

Determine the construction of the transonic $C_{D0}$ curve with sweep $c/4 = 45$ deg:

| Parameter | Value |
|---|---|
| Delta wing with AR | 3 |
| $t/c$ | 0.03 |
| $C_{Df}$ | 0.006 at Mach 0.6 |
| $(t/c)^{1/3}$ | 0.311 |
| $(t/c)^{5/3}$ | 0.00292 (Table 13.2) |
| AR$(t/c)^{1/3}$ | 0.933 |
| Unswept $C_{DW_{peak}}$ | 0.0082 (from Fig. 13.10) |
| Unswept $M_{CDW_{peak}}$ | 1.09 (from Fig. 13.10) |
| Swept $C_{DW_{peak}}$ | $(0.0082)(0.42)=0.00344$ |
| Swept $M_{CD_{peak}}$ | $1.09/0.841=1.3$ |

The construction of the wing transonic $C_{D0}$ curve is shown on Fig. 13.11. The unswept $M_D$ is
located by finding the point where the slope is 0.1. The swept wing $M_D$ is determined by Eq.
(13.14). The swept wing $C_D$ curve is then faired in as shown in Fig. 13.11.

**Fig. 13.11** — *Construction of transonic wing $C_{D0}$ for AR = 3 delta wing with $t/c=0.03$*
*[Nicolai & Carichner, Fig. 13.11, p. 341]*. $C_{D0}$ (0–0.016) vs. Mach Number (0.6–1.6). Two
curves: "Unswept" (from Fig. 13.10, dashed slope=0.10 construction line locating Unswept $M_D$ ≈
0.95) rising steeply to a plateau ~0.014; "Swept" curve rising later and more gradually to a plateau
~0.0095, with the "Skin Friction" baseline level and the slope=0.10 tangent construction lines shown
for both curves.

### §13.3.3 Wing: Supersonic
*[Nicolai & Carichner, p. 340]*

The supersonic wing $C_{D0}$ based upon $S_{ref}$ is given by

*(unnumbered equation)* *[Nicolai & Carichner, p. 340]*:
```
(C_D0)_W = C_Df + C_DW
```
The wing supersonic skin friction is expressed as

**Eq (13.17)** *[Nicolai & Carichner, Eq. (13.17), p. 340]*:
```
C_Df = C_f * (S_wet / S_ref)
```
where $C_f = (C_{f_c}/C_{f_i})C_{f_i}$. The ratio $C_{f_c}/C_{f_i}$ is obtained from Fig. 13.12 and
$C_{f_i}$ is determined the same way as for subsonic flow using cutoff and flight Reynolds number
comparison.

**Fig. 13.12** — *Compressibility effect on turbulent skin friction* *[Nicolai & Carichner, Fig.
13.12, p. 341]*. $C_{f_c}/C_{f_i}$ (0.3–1.0) vs. Mach Number (1–6), single curve labeled "Eq. (2.25)"
decreasing monotonically from ~0.92 at Mach 1 to ~0.33 at Mach 6; dashed extension above Mach 1 marked
"No Correction Assumed Below M = 1.0".

The method for predicting the wing supersonic wave drag coefficient is developed from supersonic
linear theory. Wings with round leading edges will exhibit a detached bow wave, accompanied by an
additional wave drag term due to leading edge bluntness.

For wings with sharp-nosed airfoil sections and the following:

1. Supersonic leading edge ($\beta\cot\Lambda_{LE}\geq1$), use

**Eq (13.18)** *[Nicolai & Carichner, Eq. (13.18), p. 342]*:
```
C_DW = (B/beta) * (t/c)^2 * (S_e/S_ref)
```

2. Subsonic leading edge ($\beta\cot\Lambda_{LE}<1$), use

**Eq (13.19)** *[Nicolai & Carichner, Eq. (13.19), p. 342]*:
```
C_DW = B*cot(Delta_LE) * (t/c)^2 * (S_e/S_ref)
```
where $B$ is a constant factor for a given sharp-nosed airfoil. $B$ factors for sharp-nosed airfoils
are presented in Table 13.3.

For wings with round-nosed airfoil sections and the following:

1. Supersonic leading edge ($\beta\cot\Lambda_{LE}\geq1$), use

**Eq (13.20)** *[Nicolai & Carichner, Eq. (13.20), p. 342]*:
```
C_DW = C_DLE + (16/(3*beta)) * (t/c)^2 * (S_e/S_ref)
```

2. Subsonic leading edge ($\beta\cot\Lambda_{LE}<1$), use

**Eq (13.21)** *[Nicolai & Carichner, Eq. (13.21), p. 342]*:
```
C_DW = C_DLE + (16/3)*cot(Delta_LE) * (t/c)^2 * (S_e/S_ref)
```

**Table 13.3** — *B Factor for Sharp-Nosed Airfoils* *[Nicolai & Carichner, Table 13.3, p. 342]*:

| Basic Wing Airfoil Section | B | Section (description) |
|---|---|---|
| Biconvex | $16/3$ | Symmetric lens/biconvex cross-section |
| Double wedge | $(c/x_t)/(1-x_t/c)$ | Diamond section, max thickness at chord station $x_t$ |
| Hexagonal | $c(c-x_2)/(x_1 x_3)$ | Hexagonal section with flat-sided regions $x_1$, $x_2$, $x_3$ (with $x_1+x_2+x_3=c$) |

where the leading edge bluntness term $C_{D_{LE}}$ is determined from Fig. 13.13. In Fig. 13.13 $b$
is the wing span in feet and $r_{LE}$ is the radius of the leading edge at the mean aerodynamic chord
in feet.

Sometimes the $C_{D0}$ values determined in the transonic and supersonic regimes do not match so that
it is difficult to fair a smooth curve through all the points. This is usually because the transonic
method does not account for leading edge radius. In this event, average the data point values until a
smooth curve can be drawn. The peak $C_{D0}$ should occur at the Mach number given by Eq. (13.16).

**Fig. 13.13** — *Supersonic round LE bluntness drag coefficient (data from [12])*
*[Nicolai & Carichner, Fig. 13.13, p. 343]*. $b\,C_{D_{LE}}/(\text{AR}\, r_{LE})$ (log scale,
0.01–10) vs. Mach Number (0–6), family of curves for LE sweep $\Delta_{LE}$ = 0, 20, 30, 40, 45, 50,
55, 60, 70 deg, all rising from a low value near Mach 1 to an asymptotic plateau at higher Mach,
decreasing in level as sweep increases (0 deg curve highest ~2.7, 70 deg curve lowest ~0.27).

### §13.3.4 Body: Subsonic
*[Nicolai & Carichner, p. 344]*

At subsonic speeds the body $C_{D0}$ of smooth slender bodies is primarily skin friction (Fig. 8.11).
Figure 13.14 shows the body shapes considered. The body $C_{D0}$ referenced to the maximum
cross-sectional area $S_B$ is given as

*(unnumbered equation)* *[Nicolai & Carichner, p. 344]*:
```
(C_D0)_B = (C_Df)_B + C_Db
```
where $C_{Df}$ is the skin friction coefficient and $C_{Db}$ is the base pressure coefficient. The
body $C_{Df}$ is expressed as [13]

**Eq (13.22)** *[Nicolai & Carichner, Eq. (13.22), p. 344]*:
```
(C_Df)_B = C_f * [1 + 60/(l_B/d)^3 + 0.0025*(l_B/d)] * (S_S/S_B)
```
where $S_s$ is the wetted area of the body surface and $\ell_B/d$ is the body fineness ratio (see
Fig. 13.14).

For noncircular bodies, the equivalent diameter should be used:

*(unnumbered equation)* *[Nicolai & Carichner, p. 344]*:
```
d_equiv = sqrt(S_S / 0.7854)
```

The $C_f$ is the turbulent skin friction coefficient and is determined in the same manner as the wing
subsonic skin friction. The reference length is the body length $\ell_B$.

The base pressure coefficient is expressed in [14] as

**Eq (13.23)** *[Nicolai & Carichner, Eq. (13.23), p. 344]*:
```
C_Db = 0.029*(d_b/d)^3 / sqrt((C_Df)_B)
```

The designer should avoid blunt-base bodies if at all possible because the $C_{Db}$ term can become
quite large. If a jet engine exhaust completely fills the base region, then the base drag is zero.

**Fig. 13.14** — *Body shapes and geometry* *[Nicolai & Carichner, Fig. 13.14, p. 344]*. Three body
silhouettes: "Closed Body" (smooth pointed nose and tail, diameter $d$, length $\ell_B$); "Body
Having a Blunt Base" (pointed nose, blunt base of diameter $d_b$, max diameter $d$, length $\ell_B$);
"Forebody" (pointed nose flowing into a flat/blunt aft face of diameter $d$, length $\ell_B$).

### §13.3.5 Body: Transonic
*[Nicolai & Carichner, p. 345]*

The transonic body $C_{D0}$ is given as

**Eq (13.24)** *[Nicolai & Carichner, Eq. (13.24), p. 345]*:
```
(C_D0)_B = C_Df + C_Dp + C_Db + C_DW
```
The $C_{Df}=C_f S_s/S_B$ is the skin friction drag coefficient, where $C_f$ is the turbulent skin
friction coefficient at Mach = 0.6. This value is assumed to be constant throughout the transonic
region.

The pressure drag coefficient $C_{Dp}$ is evaluated at Mach = 0.6 by

**Eq (13.25)** *[Nicolai & Carichner, Eq. (13.25), p. 345]*:
```
C_Dp = (C_f)_(M=0.6) * [60/(l_B/d)^3 + 0.0025*(l_B/d)] * (S_S/S_B)
```

The base drag term $C_{Db}$ is evaluated using

**Eq (13.26)** *[Nicolai & Carichner, Eq. (13.26), p. 345]*:
```
C_Db = -C_pb * (d_b/d)^2
```
where the base pressure coefficient $C_{pb}$ is obtained from the three-dimensional curve in Fig.
2.27.

The wave drag coefficient $C_{DW}$ is obtained from Fig. 13.15 (data from [15]).

The body transonic $C_{D0}$ curve is constructed by adding the four drag terms of Eq. (13.24). The
divergence Mach number for bodies having fineness ratios of 4 and greater is about 0.95.

### §13.3.6 Body: Supersonic
*[Nicolai & Carichner, p. 345]*

The supersonic body $C_{D0}$ method presented in this section is taken from [11], which contains an
excellent summary of the various supersonic theories compared with experimental data. The method
presented here is restricted to nonblunt closed-nosed bodies of revolution. If the body is open nosed
(such as the fuselage of the F-100 or MIG-21) or has significant nose bluntness, the method of [1]
should be used.

The body supersonic $C_{D0}$ referenced to the maximum cross-sectional area $S_B$ is expressed as

**Eq (13.27)** *[Nicolai & Carichner, Eq. (13.27), p. 345]*:
```
(C_D0)_B = C_f*(S_S/S_B) + C_DN2 + C_DA + C_DA(NC) + C_Db
```

where the terms are defined as:
- $C_f$ = compressible turbulent skin friction determined in the same fashion as the supersonic wing
  skin friction
- $S_s$ = body wetted area
- $C_{D_{A_{N2}}}$ = interference drag coefficient acting on the afterbody due to the center body
  (cylindrical section) and the nose, obtained from Figs. 13.16 and 13.17
- $C_{D_{N2}}$ = nose wave drag obtained from Figs. 13.18, 13.19, and 13.20, where $f_N$ is nose
  fineness ratio $\ell_N/d$ (see Fig. 13.16)
- $C_{D_A}$ = body afterbody wave drag obtained from Figs. 13.21 and 13.22, where $f_A$ is the
  afterbody fineness ratio $\ell_A/d$ (see Fig. 13.16)
- $C_{Db}$ = base drag term given by Eq. (13.26); $C_{pb}$ is obtained from Fig. 2.27

**Fig. 13.15** — *Wave drag for parabolic-type fuselage (data from [15])* *[Nicolai & Carichner, Fig.
13.15, p. 346]*. Wave Drag Coefficient $C_{DW}$ (0–0.24) vs. Fineness Ratio $\ell_B/d$ (0–24), family
of curves for Mach Number = 1.0, 1.025, 1.05, 1.1, 1.2, all decreasing monotonically with increasing
fineness ratio, highest curve (Mach 1.2) starting near 0.20 at $\ell_B/d=6$.

### §13.3.7 Miscellaneous Drag Items
*[Nicolai & Carichner, p. 346]*

The designer should not neglect the drag of miscellaneous items such as external stores, the canopy,
and other protuberances. The drag for these items is best obtained from experiment. Figure 13.23
shows the approximate $C_{D0}$ for a one-man canopy, typical protuberances (such as the pitot tube,
antenna mounts, gun ports), and nozzle boattail. The nozzle-boattail approximate $C_{D0}$ shown in
Fig. 13.23 is for a fuselage-mounted jet engine with a gentle afterbody taper down to the exhaust
nozzle. This approximate $C_{D0}$ of the nozzle boattail would replace the afterbody and base drag
terms mentioned earlier.

**Fig. 13.16** — *Interference drag for pointed bodies with parallel center section*
*[Nicolai & Carichner, Fig. 13.16, p. 347]*. $C_{D_{A(NC)}}(2\ell_A/d)^2$ (0–2.4) vs. $\ell_C/\ell_A$
(0–1.4), three curves for $\ell_N/\ell_A$ = 0.5, 1.0, 2.0, all decreasing monotonically. Inset diagram
shows body with nose length $\ell_N$, parallel center section $\ell_C$, afterbody $\ell_A$, diameter
$d$, freestream velocity $V$.

**Fig. 13.17** — *Interference drag of truncated afterbodies behind pointed forebodies with no
parallel center section* *[Nicolai & Carichner, Fig. 13.17, p. 347]*.
$C_{D_{A(NC)}}(2\ell_A/d)^2$ (0–2.4) vs. $(d_b/d)^2$ (0–1.0), three straight-ish lines for
$\ell_N/\ell_A$ = 0.5, 1.0, 2.0, all converging to 0 at $(d_b/d)^2=1.0$. Inset diagram shows body with
nose length $\ell_N$, truncated afterbody $\ell_A$ ending in base diameter $d_b$, max diameter $d$,
freestream velocity $V$.

**Fig. 13.18** — *Supersonic pressure drag of ogive noses* *[Nicolai & Carichner, Fig. 13.18,
p. 348]*. $C_{D_{N2}}[f_N^2+1/4]K_N$ (0–1.2) vs. $\beta/f_N$ (0→1.0, left half, subsonic-nose-Mach
regime) and $f_N/\beta$ (1.0→0, right half, supersonic-nose-Mach regime), family of curves
parametrized by nose fineness ratio $f_N$ = 0.5, 1.0, 1.5, 2.0, 2.5, 3, 4, 5, 6, 8, 10, each rising
from a low value at $\beta/f_N=0$ to a peak (higher $f_N$ peaking earlier and higher) then following a
common dashed envelope back down toward $f_N/\beta \to 0$.

Figure 13.24 presents the approximate $C_D$ for external stores.

The data in Figs. 13.23 and 13.24 is from [16] and is referenced to a wing area of 280 ft². Thus, the
data must be corrected for the appropriate $S_{ref}$. For example, the canopy drag coefficient at
Mach = 1.0 would be

*(unnumbered example calculation)* *[Nicolai & Carichner, p. 346]*:
```
Canopy Delta_C_D0 = (0.004) * (280 / S_ref)
```

The $\Delta C_{D0}$ for a landing gear can be seen in Fig. 10.4.

### §13.3.8 Wing–Body $C_{D0}$
*[Nicolai & Carichner, p. 349]*

The problem of estimating the wing–body combination $C_{D0}$ is one of properly accounting for the
mutual interference effects of one component on the other. The problem is extremely complicated and
requires a fairly accurate picture of the flow field interactions. This information is not available
at this point in the design game.

**Fig. 13.19** — *Supersonic pressure drag of conical noses* *[Nicolai & Carichner, Fig. 13.19,
p. 349]*. $C_{D_{N2}}[f_N^2+1/4]$ (0–1.6) vs. $\beta/f_N$ (left half) and $f_N/\beta$ (right half),
family of curves parametrized by cone Semivertex Angle $\theta$ = 5, 10, 15, 20, 25, 30, 35, 40, 45
deg, each peaking at progressively lower height and later abscissa as $\theta$ increases, converging
together at high $f_N/\beta$.

**Fig. 13.20** — *Correlation factor for pressure drag of ogive noses* *[Nicolai & Carichner, Fig.
13.20, p. 350]*. $K_N$ (1.0–1.5) vs. Semivertex Angle $\theta_N$ (deg, 0–100), single monotonically
increasing curve, per the formula
$K_N = \dfrac{C_{D_{N2}}[f_N^2+1/4]_0}{C_{D_{N2}}[f_N^2+1/4]_\theta}$ as $M\to\infty$.

**Fig. 13.21** — *Supersonic pressure drag of ogive boattails (data from [11])*
*[Nicolai & Carichner, Fig. 13.21, p. 350]*. $C_{DA}(f_A^2)$ (0–1.2) vs. $\beta/f_A$ (left half) and
$f_A/\beta$ (right half), family of curves for boattail diameter ratio $d_b/d$ = 0, 0.2, 0.4, 0.6,
0.8, each decreasing monotonically, with a dashed "Slender Nose" bounding curve and a dashed "Vacuum"
limit curve on the supersonic-boattail side. Inset diagram: "Ogive Aftbody" with max diameter $d$ and
base diameter $d_b$.

**Fig. 13.22** — *Supersonic pressure drag of conical boattails (data from [11])*
*[Nicolai & Carichner, Fig. 13.22, p. 351]*. $C_{DA}(f_A^2)$ (0–1.6) vs. $\beta/f_A$ (left half) and
$f_A/\beta$ (right half), family of curves for boattail diameter ratio $d_b/d$ = 0, 0.2, 0.4, 0.6,
0.8, each decreasing monotonically, with dashed "Slender Nose" and "Vacuum" bounding curves. Inset
diagram: "Conical Aftbody" with max diameter $d$ and base diameter $d_b$.

Correction studies have been conducted on wing–body interference. The results [9] indicate that the
wing–body interference effects amount to about ±5% for subsonic flow with the generous use of
fillets. It is hard to argue at this point that the $C_{D0}$ of the components is accurate to within
5%. Thus, the wing–body subsonic $C_{D0}$ will be assumed to be simply the sum of the components,

**Eq (13.27)** (restated) *[Nicolai & Carichner, Eq. (13.27), p. 351]*:
```
(C_D0)_B = C_f*(S_S/S_B) + C_DN2 + C_DA + C_DA(NC) + C_Db
```

**Fig. 13.23** — *Incremental drag for miscellaneous items (data from [16])* *[Nicolai & Carichner,
Fig. 13.23, p. 352]*. $\Delta C_{D0}$ (0–0.005) vs. Mach Number (0.2–1.6), $S_{ref}=280\,\text{ft}^2$.
Three curves: "Canopy" (rising sharply from ~0.0006 to a transonic peak ~0.0046 near Mach 1.1, then
decaying to ~0.0034 by Mach 1.6); "Protuberance" (rising from ~0.0006 to a plateau ~0.0017); "Nozzle
Boattail" (dotted, starting ~0.0013, peaking ~0.0022 near Mach 0.95, then decaying to ~0.001 by Mach
1.6).

Based upon the maximum cross-sectional area $S_B$. Then the wing-body $C_{D0}$ referenced to $S_{ref}$
is

**Eq (13.28)** *[Nicolai & Carichner, Eq. (13.28), p. 352]*:
```
(C_D0)_WB = (C_D0)_B * (S_B/S_Ref) + (C_D0)_W + Delta_C_D0
```
where $\Delta C_{D0}$ is any miscellaneous drag items referenced to $S_{ref}$.

**Fig. 13.24** — *Incremental drag for external stores (data from [16])* *[Nicolai & Carichner, Fig.
13.24, p. 352]*. $\Delta C_{D0}$ (0–0.010) vs. Mach Number (0.2–1.4), $S_{ref}=280\,\text{ft}^2$. Four
curves, each roughly flat subsonically then rising transonically: "(2) 600-gal Tanks & Pylons"
(highest, from ~0.0048 to ~0.0093 at Mach 1.0); "(2) 300-gal Tanks & Pylons" (from ~0.0038 to ~0.0053);
"(1) 150-gal Tank & Pylon" (from ~0.0010 to ~0.0022); "(2) AIM-9 Missiles + Pylons" (lowest, roughly
flat ~0.0008–0.0015).

For transonic and supersonic flow the interference effects can be significant. The interference drag
is usually positive for configurations not specifically contoured to reduce this drag component.
However, for area-ruled configurations, this interference drag can be negative. It is recommended
that aircraft designed for transonic and supersonic flight be area-ruled. Area-ruling is discussed in
Chapter 8.

## §13.4 Combined Vehicle Aerodynamics
*[Nicolai & Carichner, p. 353]*

The complete aircraft aerodynamics can now be estimated. First tail surfaces ($t/c$, planform,
symmetrical section) are designed based upon the preliminary estimates for tail size (from Chapter
11), then their individual aerodynamics are estimated and then combined with the wing–body
aerodynamics. A popular trick at this point is to assume the tail surfaces to be miniature wings and
nacelles to be miniature fuselages so that their aerodynamics are similar. This might appear as
cheating, but it is appropriate for the first design loop. Our complete aircraft aerodynamics can be
estimated as follows:

**Eq (13.29a)** *[Nicolai & Carichner, Eq. (13.29a), p. 353]*:
```
(C_L_alpha)_a/c = (C_L_alpha)_W/B
```

**Eq (13.29b)** *[Nicolai & Carichner, Eq. (13.29b), p. 353]*:
```
(C_l_alpha)_a/c = (C_l_alpha)_W/B
```

**Eq (13.30)** *[Nicolai & Carichner, Eq. (13.30), p. 353]*:
```
K_a/c = K_W/B
```

**Eq (13.31)** *[Nicolai & Carichner, Eq. (13.31), p. 353]*:
```
(C_D0)_a/c = (C_D0)_W/B + (C_D0)_wing * (S_VT + S_HT)/S_ref + (C_D0)_fuse * S_nacelle/S_ref
```

Remember to do a "sanity check" on your aerodynamic estimates. Compare your results with real
aircraft data such as those found in Appendix G.

### References
*[Nicolai & Carichner, Chapter 13, pp. 353–354]*

1. Ellison, D. E., "USAF Stability and Control Handbook (DATCOM)," U.S. Air Force Flight Dynamics
   Laboratory, AFFDL/FDCC, Wright–Patterson AFB, OH, Aug. 1968.
2. Jones, R. T., "Properties of Low-Aspect-Ratio Pointed Wings at Speeds Below and Above the Speed of
   Sound," NACA TR-835, 1946.
3. Mirels, H., "Aerodynamics of Slender Wings and Wing–Body Combinations Having Swept Trailing
   Edges," NACA TN-3105, 1954.
4. Pitts, W. C., Nielsen, J. N., and Kaattari, P. J., "Lift and Center of Pressure of Wing–Body–Tail
   Combinations at Subsonic, Transonic and Supersonic Speeds," NACA Rept. 1307, 1959.
5. Maher, R. J., and Bores, J. H., "Low Aspect Ratio Wing–Body Combination Lift Curve Slope
   Determination at Subsonic Speeds," Aero 350 Rept., U.S. Air Force Academy, CO, May 1970,
   pp. 13–36.
6. Sanchez, F., "Lift Curve Slope Interference Factor for Low Aspect Ratio Wing–Body Combinations,"
   Aero 499 Rept., U.S. Air Force Academy, CO, May 1971.
7. Nicolai, L. M., and Sanchez, F., "Correlation of Wing–Body Combination Lift Data," *Journal of
   Aircraft*, Vol. 10, No. 2, Oct. 1973, pp. 126–128.
8. Simon, W. E., Ely, W. L., Niedling, L. G., and Voda, J. J., "Prediction of Aircraft Drag Due to
   Lift," U.S. Air Force Flight Dynamics Laboratory, AFFDL-TR-71-84, Wright–Patterson AFB, OH, June
   1971.
9. Benepe, D. B., Kouri, B. G., Webb, J. B., "Aerodynamic Characteristics of Non-Straight Taper
   Wings," U.S. Air Force Flight Dynamics Laboratory, AFFDL-TR-66-73, Wright–Patterson AFB, OH, 1966.
10. Furlong, G. C., and McHugh, J. G., "A Summary and Analysis of the Low-Speed Longitudinal
    Characteristics of Swept Wings at High Reynolds Number," NACA RM L52D16, Aug. 1952.
11. Morris, D. N., "A Summary of the Supersonic Pressure Drag of Bodies of Revolution," *Journal of
    the Aeronautical Sciences*, Vol. 28, No. 7, July 1961, pp. 516–521.
12. Crosthwait, E. L., "Drag of Two-Dimensional Cylindrical Leading Edges," General Dynamics, F/W
    Rept. AIM No. 50, 1966.
13. Blakeslee, D. J., Johnson, R. P., and Skavdahl, H., "A General Representation of the Subsonic
    Lift–Drag Relation for an Arbitrary Airplane Configuration," RAND RM 1593, 1955.
14. Hoerner, S. F., *Fluid-Dynamic Drag*, published by the author, 1958.
15. Gollos, W. W., "Transonic and Supersonic Pressure Drag for a Family of Parabolic Type Fuselages
    at Zero Angle of Attack," RAND Rept. RM 982, 1952.
16. Smith, C. W., "Aerospace Handbook," General Dynamics, Fort Worth, TX, FZA-381, March 1976.

---
**Chapter 13 extraction complete.** All Figs 13.1–13.24 (incl. 13.3a/13.3b), Tables 13.1–13.3, Eqs
(13.1)–(13.31) (incl. 13.29a/13.29b), and References [1]–[16] captured.
<!-- APPEND-HERE -->
