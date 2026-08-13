# Chapter 16 — Stability, Control, and Handling Qualities

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 16
"Stability, Control, and Handling Qualities," printed pp. 585–636 (PDF index 613–667).

Classical (NACA-era, "handbook") static-stability/control equations for conceptual design, plus
brief coverage of dynamic stability, flexibility effects, and handling-qualities criteria. Heavy on
numbered equations; several are read-from-curve empirical charts, digitized below where they feed
directly into a stability-derivative calculation.

---

## §16.1 Introduction

Wing placement and tail-volume-coefficient rules of thumb (Chapter 6) give a design that is
*probably* stable/controllable; this chapter gives the classical methods to check that quantitatively.
Full accuracy needs 6-DOF dynamics codes with CFD/wind-tunnel input, plus structural deflections —
usually not done until preliminary design. The handbook methods here (from NACA-era work,
1925–1945) are cruder but standard for conceptual design and student projects. Key sources:
[15, 69, 116, 117], especially [13, 118].

**Static stability**: restoring forces after a disturbance push the aircraft back toward the
original state. **Dynamic stability**: the resulting motion actually converges back to that state
(depends on restoring force, mass distribution, and damping). Fig. 16.1 illustrates five pitch-disturbance
response cases: (a) perfectly neutral (stays displaced); (b) statically unstable (diverges further,
e.g. pitch-up); (c) stable, heavily damped (returns with no overshoot); (d) stable, lightly damped
(converging oscillation — acceptable if it converges fast); (e) statically stable but dynamically
unstable (restoring forces high, damping low → growing oscillation → "divergence," e.g. into a spin).
*[Raymer, Fig. 16.1, p. 587]* — schematic α-vs-time traces, no numeric data.

Not all instability is bad if slow enough: most aircraft have an unstable **spiral-divergence** mode,
but it is slow enough that pilots correct for it unconsciously (indistinguishable from ordinary gust
corrections). Most of this chapter addresses *static* stability; conventional configurations satisfying
static-stability criteria usually get acceptable dynamic stability too. Rule-of-thumb methods are given
later for stall departure and spin recovery (the dynamic areas of greatest concern).

## §16.2 Coordinate Systems and Definitions

Three axis systems (Fig. 16.2): **body axis** (X along fuselage, Z up, origin arbitrary — usually
nose; natural but lift/drag direction varies with α since lift is by definition ⟂ to the wind);
**wind axis** (X into the relative wind, tracking α and sideslip β — but becomes asymmetric about
the X-Z plane when the aircraft yaws, over-complicating the coefficients); **stability axis**
(compromise: X aligned to α as in wind axis, but not offset to yaw angle — preserves symmetry). Right-hand
rule must hold: positive nose-up pitch ⇒ Y out the right wing ⇒ roll-right needs X forward, yaw-right
needs Z down.
*[Raymer, Fig. 16.2, p. 588]* — 3-view schematic of body axes with pitch/yaw/roll moment definitions:

```
Pitch: Cm = M/(q S c̄)      Yaw: Cn = N/(q S b)      Roll: Cl = L/(q S b)     (Cl ≠ lift!)
```

Wing/tail incidence `i` is relative to the body-fixed reference axis; aircraft α is also referenced to
it, so wing α = aircraft α + wing incidence; tail α = aircraft α + tail incidence − downwash angle ε
(discussed later). Stability α is conventionally measured from the *zero-lift* angle (Chapter 12) —
airfoil moment data tabulated about the geometric chord line may need adjustment to the zero-lift line.

Nondimensional moment coefficients [Raymer, Eq. (16.1)–(16.3), p. 589]:

```
Cm = M / (q Sw c̄)      (16.1)
Cn = N / (q Sw b)       (16.2)
Cl = L / (q Sw b)       (16.3)
```
(positive moment = nose up or to the right). Derivative subscript notation: `Cn_β` = yaw-moment
derivative w.r.t. sideslip; `Cm_δe` = pitch-moment response to elevator deflection. Convention for
the rest of the chapter: sweep angles are quarter-chord sweeps, chord `c` is the wing MAC, angles are
radians unless noted.

## §16.3 Longitudinal Static Stability and Control

### §16.3.1 Pitching-Moment Equation and Trim Calculation

Moderate-α changes barely couple into yaw/roll and vice versa, so longitudinal and lateral-directional
analyses are treated separately. Fig. 16.3 shows the pitching-moment contributors about the c.g.: wing
lift through its aerodynamic center + wing `Cm` about the a.c. + flap-deflection increment; fuselage/
nacelle moment (upwash/downwash-influenced, hard to estimate without wind-tunnel data); tail lift ×
long moment arm (the primary trim/control term — can be up or down; a canard has a *negative* moment
arm); and three engine contributions — direct thrust moment, inlet/propeller-disk normal force `Fp`
from turning the flow, and propwash/jet-induced flowfield effects on tail/wing/aft fuselage. Wing/tail
drag moments and tail `Cm` about its own a.c. are negligible.
*[Raymer, Fig. 16.3, p. 590]* — side-view force diagram: wing lift at `Xacw`, tail lift `Lh` at
`Xach`, thrust `T` at height `zt`, propulsion normal force `Fp` at `Xp`, with `αp = α + ip + εu`
(forward propulsion) or `αp = α + ip − ε` (aft propulsion). No plotted data (schematic).

Sum-of-moments about c.g. [Raymer, Eq. (16.4), p. 591]:

```
M_cg = L(x̄cg − x̄acw) + M_w + M_w,δf + M_fus
       − L_h(x̄ach − x̄cg) − T·zt + Fp(x̄cg − x̄p)                       (16.4)
```

Elevator effect is folded into the tail-lift term. In coefficient form, dividing by `q Sw c̄` and
introducing the tail dynamic-pressure ratio `η_h = q_h/q` (typically 0.85–0.95, ~0.90 nominal)
[Raymer, Eq. (16.6), p. 591] and fractional lengths (a bar denotes length/`c̄`, e.g. `x̄cg = Xcg/c̄`)
[Raymer, Eq. (16.5)–(16.7), p. 591]:

```
η_h = q_h / q                                                          (16.6)

Cm_cg = CL(x̄cg − x̄acw) + Cm_w + Cm_w,δf·δf + Cm_fus
        − η_h (Sh/Sw) CL_h (x̄ach − x̄cg)
        − (T/(q Sw)) z̄t + (Fp/(q Sw))(x̄cg − x̄p)                       (16.7)
```

Static **trim**: `Cm_cg = 0`, solved by varying tail area, tail `CL` (incidence/elevator), or
sometimes c.g. Governing trim conditions: takeoff/landing (flaps + gear down) and high transonic
speed; pull-up trim is a dynamic problem (below). Forward-most c.g. usually governs trim sizing;
aft-most c.g. governs stability (§16.3.2).

### §16.3.2 Static Pitch Stability

Static stability requires `dCm/dα < 0` [Raymer, Eq. (16.8), p. 592] (wing `Cm` and thrust terms drop
out since they're ~constant with α; a downwash-derivative term `∂ε_h/∂α` and an inlet/propeller
normal-force-derivative term `∂αp/∂α` appear):

```
Cm_α = CL_α(x̄cg − x̄acw) + Cm_α,fus
       − η_h (Sh/Sw) CL_αh (∂α_h/∂α)(x̄ach − x̄cg)
       + (Fp/(q Sw))(∂αp/∂α)(x̄cg − x̄p)                                (16.8)
```

A tailless ("flying wing") aircraft has no tail term, so it must be stabilized by keeping the wing
a.c. *aft* of the c.g. (making the first term negative). The c.g. location giving `Cm_α = 0` is the
**neutral point** `Xnp` (neutral stability, most-aft usable c.g.) [Raymer, Eq. (16.9), p. 592]. The
percent-MAC distance from the neutral point to the c.g. is the **static margin**
[Raymer, Eq. (16.10)–(16.11), p. 593]:

```
Xnp = [ CL_α x̄acw − Cm_α,fus + η_h(Sh/Sw)CL_αh(∂α_h/∂α)x̄ach + (Fp/(q Sw))(∂αp/∂α)x̄p ]
      / [ CL_α + η_h(Sh/Sw)CL_αh(∂α_h/∂α) + (Fp/(q Sw))(∂αp/∂α) ]        (16.9)

Cm_α = −CL_α,total (x̄np − x̄cg)                                        (16.10)

Static Margin (SM) = (x̄np − x̄cg) = −Cm_α / CL_α                       (16.11)
```

SM is *the* key longitudinal-stability sizing parameter. c.g. ahead of neutral point (positive SM) ⇒
`Cm_α < 0` ⇒ stable. Typical most-aft-c.g. SM: transports 5–10%, GA even higher (Cessna 172 ≈ 19%);
older fighters ≈5% positive; modern fighters (F-16/F-22/F-35) use **relaxed static stability (RSS)**,
0 to −15% SM with a computerized FCS providing artificial stability — substantially cuts trim drag.
`Fp` is often dropped to get "power-off" stability (removes a strong velocity dependence); a
static-margin allowance (typically −1 to −3% for jets; ≈ −2% per MAC of forward propeller offset
from c.g. for prop aircraft) accounts for power-on effects.

**Fig. 16.4 — Typical pitching-moment derivative values** *[Raymer, Fig. 16.4, p. 593]* — `Cm_α`
(per rad) vs Mach (0–3.0) bands for Transport (B-747, B-727), Business/GA, and Fighter-stable (F-4),
*(read from plot)*:

| Mach | Transport Cm_α | Business/GA Cm_α | Fighter (F-4) Cm_α |
|---|---|---|---|
| 0.3 | ~ −0.9 | ~ −0.5 | ~ −0.3 |
| 0.8 | ~ −1.0 | ~ −0.55 | ~ −0.35 |
| 1.0 | ~ −0.6 | ~ −0.35 | ~ −0.55 |
| 1.5 | ~ −0.7 | — | ~ −1.1 |
| 2.0 | ~ −0.8 | — | ~ −1.3 |
| 3.0 | ~ −0.9 | — | ~ −1.4 |

(Trends only — transport/GA curves fairly flat with a mild transonic dip; fighter curve shows a
sharp transonic destabilization then rises again supersonically. `[verify p.593]` — exact digit values
not fully legible in OCR scan; treat as order-of-magnitude targets only.)

### §16.3.3 Aerodynamic Center

`Xacw` (wing a.c.): for high-AR wings, subsonically ≈ airfoil a.c. (≈ quarter-chord, ±1%); shifts to
≈45% MAC supersonically. Figs. 16.5a–c give graphical a.c. estimation (poor at transonic speeds; also
used for tail a.c.). Quick Mach-shift approximation [Raymer, Eq. (16.12), p. 594]:

```
x̄ac = x̄c/4 + Δx̄ac
  Δx̄ac = 0.26(M − 0.4)^2.5          for 0.4 < M < 1.1
  Δx̄ac = 0.11 − 0.004M              for M > 1.1
```

**Fig. 16.5 — Wing aerodynamic center** *[Raymer, Fig. 16.5, p. 595]* — three-panel chart (a)
`(Xac/c̄r)` vs `β/tan(ΛLE)` for taper ratio families with unswept-T.E. asymptote at AR·tanΛLE curves
1–6, subsonic-to-supersonic sweep; (b) same for `λ = 0.5`; not independently digitized — this is a
Datcom-style multi-parameter nomograph (λ, AR·tanΛLE, β/tanΛLE all vary together); a handful of
points would not usefully represent it. **Not digitized** — genuinely multi-dimensional nomograph;
use only for direct graphical lookup against the actual figure.

### §16.3.4 Wing and Tail Lift, Flaps, and Elevators

Lift-curve slopes from Chapter 12 methods (reduce tail `CL_α` ~20% for unsealed elevator gap). Wing
and tail lift [Raymer, Eq. (16.13)–(16.14), p. 594]:

```
Wing:      CL_w = CL_αw (α + iw − α0Lw)                                (16.13)
Aft tail:  CL_h = CL_αh (α + ih − iw)(1 − ∂ε/∂α) ... − α0Lh             (16.14, combined w/ downwash, see §16.3.6)
```

(`α0L` negative for cambered/flap-deflected surfaces.) Flap/elevator deflection is modeled as a shift
in zero-lift angle [Raymer, Eq. (16.15), p. 596]:

```
Δα0L = −ΔCL / CL_α                                                     (16.15)
```

For plain flaps [Raymer, Eq. (16.16)–(16.17), p. 596]:

```
Δα0L = −(1/CL_α)(∂CL/∂δf) δf                                           (16.16)
∂CL/∂δf = 0.9 Kf (∂Cl/∂δf)_airfoil (Sflapped/S) cos ΛH.L.ref            (16.17)
```

`Kf` and the theoretical `∂Cl/∂δf` come from **Fig. 16.6** (theoretical lift increment for plain
flaps vs `δf`, families of `t/c` = 0.00, 0.04, 0.08, 0.12, 0.15) and **Fig. 16.7** (empirical
large-deflection correction, `ΔCl/Δcl,theory` vs flap deflection 0–80°, families of `cf/c` =
0.10–0.50) *[Raymer, Figs. 16.6–16.7, p. 597]*. *(read from plot, Fig. 16.7, cf/c = 0.20 curve)*:

| δf (deg) | ΔCl/Δcl,theory |
|---|---|
| 0 | 1.00 |
| 20 | ~0.80 |
| 40 | ~0.62 |
| 60 | ~0.50 |
| 80 | ~0.40 |

This empirical method can over-predict effectiveness; Raymer bounds the product of the first two
terms of Eq. (16.16) to ≤1 using an empirical cap [Raymer, Eq. (16.18), p. 598]:

```
(1/CL_α)(∂CL/∂δf) ≤ 1.576(Cf/C)^3 − 3.458(Cf/C)^2 + 2.882(Cf/C)         (16.18)
```

`H.L.` = flap hinge-line sweep; `Sflapped` = area of the flapped/control-surface portion;
`c'` = MAC of that flapped portion, found by treating it as a separate planform (Fig. 16.8 defines
this geometry) *[Raymer, Fig. 16.8, p. 598]* — planform sketch, no plotted data. Unsealed hinge gap
reduces effectiveness ~15%. At higher Mach, scale flap lift by `CL_α(M)/CL_α(M=0)` (Fig. 12.6 trend).

### §16.3.5 Wing Pitching Moment

For a straight/untwisted-swept wing at low subsonic speed [Raymer, Eq. (16.19), p. 598]:

```
Cm_w = Cm_airfoil,0 · [ (A cos²Λ) / (A + 2 cosΛ) ]                      (16.19)
```

Twist adds ≈ −0.01 × (twist, deg) for a typical swept wing (finer method in [69]). Transonic effects
increase `|Cm_w|` by ~30% at M=0.8. Flap-deflection moment increment [Raymer, Eq. (16.20), p. 599]:

```
Cm_w,δf = −(∂CL/∂δf) (x̄cp − x̄cg)                                      (16.20)
```

`x̄cp` (flap-lift-increment center of pressure, % of flapped MAC `c'`) from **Fig. 16.9 — Center of
pressure for lift increment due to flaps** *[Raymer, Fig. 16.9, p. 599]*, `Xcp/c'` vs flap-chord
ratio `cf/c` (0–0.8), slotted-flap curve. *(read from plot)*:

| cf/c | Xcp/c' |
|---|---|
| 0.0 | ~0.50 |
| 0.2 | ~0.42 |
| 0.4 | ~0.35 |
| 0.6 | ~0.30 |
| 0.8 | ~0.27 |

A highly swept wing can put this c.p. ahead of the c.g. (positive moment, reduces tail download
needed); a canard puts it well aft of the c.g. (large balancing force needed).

### §16.3.6 Downwash and Upwash

Ahead of the wing, subsonic flow is pulled upward (**upwash**, affects forebody and any
forward-mounted inlet/propeller). Behind the wing, flow is turned downward (**downwash**, ≈ wing α at
the wing, decaying to ≈ half that at a typical tail location; also decays toward the tips); reduces
tail α and adds nose-down fuselage moment; strongly modified by propwash.
*[Raymer, Fig. 16.10, p. 600]* — flowfield schematic, no plotted data.

`∂εu/∂α` from **Fig. 16.11 — Upwash estimation (subsonic only)** *[Raymer, Fig. 16.11, p. 601]*, vs
distance forward of the root quarter-chord point in root chords (families of height-above-chord-plane
curves). *(read from plot, on-chord-plane curve)*:

| Distance fwd (root chords) | ∂εu/∂α |
|---|---|
| 0.5 | ~1.7 |
| 1.0 | ~1.0 |
| 1.5 | ~0.6 |
| 2.0 | ~0.35 |
| 2.5 | ~0.2 |

`∂ε/∂α` from **Fig. 16.12 — Downwash estimation (M=0)** *[Raymer, Fig. 16.12, p. 602]*, vs tail
height/span-ish geometry parameter, families of AR = 6 and AR = 9. *(read from plot, mid-height
curve)*:

| Tail position param. | ∂ε/∂α (AR=6) | ∂ε/∂α (AR=9) |
|---|---|---|
| low | ~0.75 | ~0.68 |
| mid | ~0.55 | ~0.50 |
| high | ~0.30 | ~0.28 |

Spanwise-averaged downwash at the tail is ~5% less than the on-axis value. Additional downwash from
flap deflection: **Fig. 16.13 — Downwash increment due to flaps** *[Raymer, Fig. 16.13, p. 603]*,
`(ΔεΔCL)·A / [b/(b/2)]` vs `0.5(hh/(b/2))` (`hh` = horizontal-tail height above wing), roughly linear,
range −0.2 to 0.4 on the x-axis mapping to 0–15 on the y-axis *(read from plot)*: at `x=0` → ~2,
`x=0.2` → ~7, `x=0.4` → ~13 (steep near-linear rise).

Transonic (M≈0.9): `∂ε/∂α` derivative increases 30–40%, then reduces at higher speed. Rough high-
subsonic/supersonic approximations [Raymer, Eq. (16.21a)–(16.21b), p. 601]:

```
Subsonic (approaching M=1):    ∂ε/∂α ≈ (∂ε/∂α)_(M=0) · [tabulated/estimated increase factor]
Supersonic:                     ∂ε/∂α ≈ small residual value (downwash largely confined within Mach cone)
```
(exact closed forms garbled in OCR — `[verify p.601, Eq. 16.21a/b]`; use Fig. 16.12 base value with the
30–40% transonic bump as the practical rule.)

Effective tail/wing α [Raymer, Eq. (16.22)–(16.24), p. 602]:

```
Upwash:    ∂αu/∂α = 1 + ∂εu/∂α                                          (16.22)
Downwash:  ∂αh/∂α = 1 − ∂ε/∂α                                           (16.23)
           αh = α + ih − iw − ε                                        (16.24)
```

A canard sees no wing downwash but its own downwash affects the wing — estimated crudely by assuming
the canard downwash affects only the wing inboard of the canard tips uniformly (canard tip vortices);
outboard wing is unaffected.

### §16.3.7 Wing Vertical Position

High wing: rough approximation, static margin increases by 10% of (vertical distance of wing above
c.g.)/MAC — as the nose comes up, a high wing physically moves aft relative to the c.g., adding
nose-down moment.

### §16.3.8 Fuselage and Nacelle Pitching Moment

From NACA TR 711 [Raymer, Eq. (16.25), p. 603]:

```
Cm_α,fuselage = Kfus · Wf² · Lf / (c̄ Sw)     [per deg]                  (16.25)
```

`Wf` = max fuselage/nacelle width, `Lf` = length, `Kfus` from **Fig. 16.14 — Fuselage moment term**
*[Raymer, Fig. 16.14, p. 604]*, vs position of the wing root quarter-chord as % of fuselage length
(10–60%). *(read from plot)*:

| Root ¼-chord position (% fuselage length) | Kfus |
|---|---|
| 10 | ~0.040 |
| 20 | ~0.030 |
| 30 | ~0.023 |
| 40 | ~0.017 |
| 50 | ~0.012 |
| 60 | ~0.008 |

### §16.3.9 Thrust Effects

Three contributions: direct thrust moment (`T·zt`, negligible if thrust axis near c.g.); inlet/prop
normal force `Fp` from turning the flow; propwash/jet effects on tail/wing/fuselage. Normal force from
momentum [Raymer, Eq. (16.26)–(16.28), p. 604]:

```
Fp = ṁ V tan(αp) ≈ ṁ V αp                                              (16.26)
ṁ ≈ ρ V A_inlet          [capture-area ratio ≈ 1 assumption]            (16.27)
∂Fp/∂α = ṁ V · (∂αp/∂α)                                                 (16.28)
```
(`∂αp/∂α`= upwash deriv. Eq.(16.22) if inlet ahead of wing, downwash deriv. Eq.(16.23) if behind;
≈0 if under the wing since the wing pre-turns the flow.) For propellers, empirical normal force
[Raymer, Eq. (16.29), p. 605]:

```
Fp = q · NB · Ap · (∂CN,blade/∂α) · f(T)                                (16.29)
```

`NB`=blades/prop, `Ap`=disk area, `∂CN,blade/∂α` (at zero thrust) from **Fig. 16.15 — Propeller
normal-force coefficient** *[Raymer, Fig. 16.15, p. 605]* vs advance ratio `J=V/(nD)` (0–5)
*(read from plot)*:

| J | ∂CN,blade/∂α (per rad, thrust=0) |
|---|---|
| 0 | 0.125 |
| 1 | 0.095 |
| 2 | 0.065 |
| 3 | 0.040 |
| 4 | 0.020 |
| 5 | 0.008 |

`f(T)` (nonzero-thrust correction) from **Fig. 16.16 — Propeller normal-force factor**
*[Raymer, Fig. 16.16, p. 606]* vs `J` (−0.5 to 2.5), roughly linear rise. *(read from plot)*:

| J | f(T) |
|---|---|
| -0.5 | ~0.78 |
| 0 | ~0.90 |
| 0.5 | ~1.05 |
| 1.0 | ~1.25 |
| 1.5 | ~1.50 |
| 2.0 | ~1.75 |
| 2.5 | ~2.00 |

A propeller aft of the c.g. is stabilizing (pusher advantage). Propwash also affects tail downwash
[Raymer, Eq. (16.30), p. 606]:

```
∂ε_prop/∂α = K1 + K2 · NB · (∂CN,blade/∂α) · (1/2B) · (∂αp/∂α)          (16.30)
```
(`K1`, `K2` from **Fig. 16.17 — Propeller downwash factors** *[Raymer, Fig. 16.17, p. 607]*, vs `J`
(−0.5 to 2.5); OCR too degraded to reliably digitize curve values — `[verify p.607, Fig. 16.17]`, use
figure directly.) Increased dynamic pressure at a tail in the propwash [Raymer, Eq. (16.31), p. 606]:

```
q_h/q = η_h [ 1 + (thrust-dependent increment term) ]                   (16.31)
```
(`η_h ≈ 0.9` at zero thrust; reduce the added term proportionally if the tail is only partly immersed
in the propwash; also usable for wing dynamic-pressure increase affecting flap pitching moment.)

### §16.3.10 Trim Analysis

Solve `Cm_cg=0` [Eq.(16.7)] for elevator/tail-incidence at each α, respecting that tail-lift changes
shift total lift (hence α, since total lift = weight) — solved iteratively or graphically. Tail lift
and total lift [Raymer, Eq. (16.32)–(16.33), p. 607]:

```
CL_h = CL_αh [ (α + iw)(1 − ∂ε/∂α) + (ih − iw) − α0Lh ]                 (16.32)
CL_total = CL_α[α + iw] + η_h (Sh/Sw) CL_h                              (16.33)
```

**Fig. 16.18 — Graphical trim analysis** *[Raymer, Fig. 16.18, p. 608]*: calculation table of
`(α, δe) → (Cm_cg, CL_total)` triples, then a trim crossplot of `Cm_cg` vs `CL_total` for several
`δe` lines; trim point = intersection with `Cm_cg=0` at each target `CL_total`. Sample tabulated
points reproduced from the figure's calculation table *[Raymer, Fig. 16.18, p. 608]*:

| α (deg) | δe | Cm_cg | CL_total |
|---|---|---|---|
| 0 | 0° | 0.033 | −0.07 |
| 0 | −2° (approx, second col) | 0.018 | −0.05 |
| 5 | 0° | 0.012 | 0.53 |
| 5 | −2° (approx) | −0.004 | 0.54 |
| 10 | 0° | −0.005 | 1.03 |
| 10 | −2° (approx) | −0.021 | 1.04 |
| 12 (approx) | 2° | 0.002 | 1.06 |

(Table digitization approximate — OCR scrambled the column/row alignment; treat as illustrative of
method, not exact values. `[verify p.608, Fig. 16.18 table]`.)

Trimmed drag including trim-drag effects [Raymer, Eq. (16.34), p. 609]:

```
CD,trimmed = K [ CL_α(α+iw) ]² + η_h(Sh/Sw) Kh [ CL_αh ]²               (16.34)
```
(`Kh` = tail drag-due-to-lift factor, Chapter 12 methods treating the tail as a wing.) Downwash also
tilts the tail lift/drag vectors; a downward-lifting stable-aircraft tail gets a slight forward lift
component (reduces trim drag); an upward-lifting tail (as on an unstable/RSS aircraft minimizing trim
drag) gets a slight aft component (partially offsetting the savings). Elevator parasite drag from
Eq. (12.37) if deflected for trim — one motivation for all-moving (variable-incidence) tails.

### §16.3.11 Ground Effect on Trim Calculation

Within ~20% span of the ground, wing/tail lift-curve slopes rise ~10% and downwash drops to about
half normal — requires more elevator deflection to hold the nose up. Elevator must have enough
authority to trim in ground effect at full flaps + forward c.g., power on and off, with margin left
over for flare control.

### §16.3.12 Takeoff Rotation

Elevator sometimes sized by rotation requirement: tricycle gear — rotate nose at 80% of takeoff
speed, most-forward c.g.; taildragger — lift tail at half takeoff speed, most-aft c.g. [117].
Eq. (16.7) plus two landing-gear moment terms: vertical reaction (weight minus lift at that α, times
moment arm to main gear) and rolling friction (weight-on-wheels × friction coefficient ≈0.03, times
c.g. height above ground) — converted to coefficients by dividing by `q Sw c̄`. Ground-effect
lift-slope/downwash changes (§16.3.11) apply here too.

### §16.3.13 Velocity Stability

Beyond α-stability, the aircraft needs **velocity stability**: increased velocity should generate a
nose-up restoring force. A propeller mounted well above the c.g. loses thrust as velocity increases,
pitching the nose up (stabilizing, since the resulting climb bleeds velocity back down) — roughly
+0.25% apparent SM per 1% MAC the thrust axis sits above the c.g. (destabilizing if below). This
effect only appears after enough time for velocity to change — doesn't affect immediate pitch-disturbance
response, so it can't be used to relax the power-off static margin, but a low thrust line's velocity-
stability penalty should still be considered for long-term trim drift. High-mounted propellers also
need large trim forces to counter their own nose-down moment — mainly used on seaplanes for water
clearance. For jets, thrust barely varies with velocity, so engine vertical position barely affects
velocity stability.

## §16.4 Lateral-Directional Static Stability and Control

### §16.4.1 Yaw/Roll-Moment Equations and Trim

Lateral-directional analysis couples yaw (directional) and roll (lateral): both driven by sideslip
`β`; bank angle `φ` has no direct effect on the moment terms; rudder or aileron deflection produces
*both* yaw and roll moments. Sign convention: positive `Cn_β` is stabilizing (yaw); *negative*
`Cl_β` is stabilizing (dihedral effect) — opposite sign convention from the yaw case.

Fig. 16.19 geometry: vertical-tail lateral lift `Fv` (main yaw restoring force, counteracting negative
fuselage yaw moment; rudder deflection acts as a tail flap); propwash rotational component (from
propeller rotation, typically clockwise viewed from behind) shifts effective tail sideslip, yawing
the nose slightly left for a tail above the fuselage; **P-effect** (propeller disk at an angle to the
flow, e.g. climb) creates asymmetric blade thrust, also yawing left for a clockwise prop — many
single-engine aircraft build in 1–2° of vertical-tail incidence to counter this. Swept-wing yaw moment
from unequal drag on the two wing halves (stabilizing if swept aft); aileron deflection's differential
induced drag gives **adverse yaw** (yaw opposite the roll direction). Engine-out creates a large yaw
moment (asymmetric thrust + failed-engine drag); inlet/prop normal force is destabilizing in yaw if
ahead of c.g.; propwash/jet effects on yaw are generally negligible unless the vertical tail sits in
the wake. In roll: **dihedral effect** (wing rolls away from the sideslip direction — stabilizing,
Chapter 4); ailerons (differential lift, `δa` = average of left/right deflection, positive rolls
right); spoilers (alternative roll device, kill lift on one side, *proverse* yaw since drag rises on
the same side as the roll); vertical tail (above c.g. → positive roll-stability contribution, moment
arm to the wind-axis X-line so it varies with α); engine-out asymmetric propwash lift difference
(usually negligible vs. the yaw moment); thrust normal-force roll contribution if engines are well
above/below c.g. (usually negligible); propwash-modified dihedral effect at sideslip (worse for
single-engine, prop far ahead of the wing).
*[Raymer, Fig. 16.19, p. 592]* — 3-view lateral geometry schematic (engine-out case), no plotted data.

Static yaw/roll sums for a twin with one engine out [Raymer, Eq. (16.35)–(16.36), p. 594]:

```
N = N_wing + N_wing,δa·δa + N_fus + Fv(x̄acv − x̄cg) − T·Yp − D·Yp − Fp(x̄cg − x̄p)   (16.35)
L = L_wing + L_wing,δa·δa − Fv(z̄v)                                                (16.36)
```

Vertical-tail lateral lift [Raymer, Eq. (16.37), p. 594]:

```
Fv = q Sv CF_β β_v          (β_v = local sideslip at the tail, reduced from freestream by sidewash)
```

Coefficient forms, dividing by `q Sw b` [Raymer, Eq. (16.38)–(16.41), p. 594–615]:

```
Cn = Cn_β β + Cn_δa δa + Cn_β,wing β + Cn_β,fus β + Cn_β,v β             (16.38)
  where  Cn_β,v = η_v (Sv/Sw)(b̄v/b) CF_βv                                (16.39)
Cl = Cl_β β + Cl_δa δa − η_v (Sv/Sw)(z̄v) CF_βv                          (16.40)
  where  Cl_β,v = −η_v (Sv/Sw)(z̄v) CF_βv                                 (16.41)
```

### §16.4.2 Lateral-Trim Analysis

Main static condition: **engine-out at takeoff** — vertical tail + rudder must null yaw at 1.1×
stall speed, aft-most c.g., rudder deflection ≤ ~20° (margin left for control). Also
**crosswind landing**: sustain crosswind = 20% of takeoff speed (≈ 11.5° sideslip at takeoff speed),
again ≤20° rudder. If the tail can't null Eq. (16.38): options are a bigger vertical tail (weight/drag
penalty), larger rudder chord/span or a double-hinged rudder (DC-10), an all-moving vertical tail
(F-107, SR-71 — most yaw power per unit area, but heavy), or moving engines inboard (adds wing
structural weight). Engine-out rudder deflection + propwash also produce a rolling moment — usually
small, but can force excessive aileron on short-coupled/wide-engine-spacing aircraft, worsened by
adverse yaw. Aileron authority must also be checked at the 11.5° sideslip condition [Eq. (16.40)] —
high effective dihedral can leave insufficient aileron to prevent rolling away from the sideslip.

### §16.4.3 Static Lateral-Directional Stability

Yaw/roll moment derivatives w.r.t. sideslip [Raymer, Eq. (16.42)–(16.43), p. 596]:

```
Cn_β = Cn_β,wing + Cn_β,fus + Cn_β,v            (16.42)
Cl_β = Cl_β,wing + Cl_β,fus + Cl_β,v            (16.43)
```
`Cn_β` = sum of wing + fuselage + vertical-tail contributions. Lateral neutral point not usually
computed directly; instead the aft-c.g. is set from longitudinal considerations and the vertical tail
area is then varied for adequate `Cn_β`. **Fig. 16.20 — Typical yaw-moment derivative values**
*[Raymer, Fig. 16.20, p. 597]* — `Cn_β` (per rad) vs Mach (0.25–2.0), suggested-goal-value curve plus
data points for Grumman Mohawk, T-38, Hawk, F-4. *(read from plot, suggested-goal curve)*:

| Mach | Cn_β goal (per rad) |
|---|---|
| 0.25 | ~0.10 |
| 0.50 | ~0.11 |
| 0.75 | ~0.12 |
| 1.0 | ~0.14 |
| 1.5 | ~0.20 |
| 2.0 | ~0.30 |

`Cl_β` should be negative, magnitude ≈ half `Cn_β` subsonically, ≈ equal to it transonically. Final
values need dynamic (wind-tunnel) analysis — vertical-tail size or dihedral have been changed
post-first-flight (F-100, B-25).

### §16.4.4 Wing Lateral-Directional Derivatives

Wing yawing moment due to sideslip [Raymer, Eq. (16.44), p. 598], from [69]:

```
Cn_β,wing = CL² { (1/(4πA)) − [tanΛ/(πA(A+4cosΛ))]
                  × [ A cosΛ − 2cosΛ − A²/(2 A + 4cosΛ)... ]
                  + (6(x̄acw − x̄cg) sinΛ)/(A) }
```
(equation garbled in OCR scan — `[verify p.598, Eq. 16.44]`; structure per [69] combines induced-drag
asymmetry, sweep, and a.c.-to-c.g. offset terms.)

Dihedral effect (`Cl_β`): for a straight wing ≈ 0.0002/deg dihedral (0.0115/rad); "1° effective
dihedral" ≡ `Cl_β` of 0.0002/deg. Sweep contribution from **Fig. 16.21 — Dihedral effect of aspect
ratio, taper ratio, and sweep** *[Raymer, Fig. 16.21, p. 599]*, `Cl_β/CL` (per rad) vs AR (0–8/9) for
`Λ_c/4` = 0–55°, two taper-ratio panels (λ=0.5 and λ=0, interpolate/extrapolate for others).
*(read from plot, λ=0.5 panel)*:

| AR | Cl_β/CL (Λ=0°) | Cl_β/CL (Λ=30°) | Cl_β/CL (Λ=45°) |
|---|---|---|---|
| 2 | ~ −0.02 | ~ −0.08 | ~ −0.15 |
| 4 | ~ −0.03 | ~ −0.13 | ~ −0.25 |
| 6 | ~ −0.04 | ~ −0.20 | ~ −0.35 |
| 8 | ~ −0.05 | ~ −0.27 | ~ −0.45 |

Multiply by wing `CL` for the final value. Geometric dihedral increment [Raymer, Eq. (16.45), p. 600],
wing-vertical-placement increment [Raymer, Eq. (16.46), p. 600], summed [Raymer, Eq. (16.47), p. 600]:

```
(Cl_β)_Γ = −(CL_αwf/4)[2(1+2λ)/(3(1+λ))] Γ                              (16.45)
Cl_β,wf = −1.2 √A · z̄wf(Df+Wf) / b²                                     (16.46)
Cl_β = Cl_β(Fig.16.21)·CL + Cl_β,Γ + Cl_β,wf                            (16.47)
```
(`z̄wf` = wing height above fuselage centerline; `Df`,`Wf` = fuselage depth/width. All contributions
negative except wing-placement term, which is positive/destabilizing for a low wing.)

Aileron control power via strip method: break the aileron-covered span into strips (Fig. 16.22), treat
each as a flap [Eq. (16.17)], multiply by moment arm `Yi` from centerline [Raymer, Eq. (16.48), p. 601]:

```
Cl_δa = (2/(Sw b)) Σ [ (∂Cl/∂δf)_strip · c_i · Yi · Δy_i ]              (16.48)
```
*[Raymer, Fig. 16.22, p. 601]* — planform sketch of aileron strip breakdown, no plotted data. Unsealed
hinge gap: reduce ~15%. Yawing moment due to aileron deflection [Raymer, Eq. (16.49), p. 602]:

```
Cn_δa ≈ f(CL) · Cl_δa      [empirical simplification of the [69] method]
```

### §16.4.5 Fuselage and Nacelle Lateral-Directional Derivatives

[Raymer, Eq. (16.50), p. 602]:

```
Cn_β,fus = −1.3 (Volume/(Sw b)) (Df/Wf)                                 (16.50)
```
Fuselage roll contribution is usually negligible except via its effect on wing effective dihedral
(above).

### §16.4.6 Vertical-Tail Lateral-Directional Derivatives

`CF_βv` from Chapter 12 methods; increase vertical-tail AR ~55% for fuselage/horizontal-tail endplate
effect; reduce ~20% for unsealed rudder hinge gap. Local dynamic pressure ratio and sideslip
derivative [Raymer, Eq. (16.51), p. 602], from [69]:

```
η_v (∂β_v/∂β) = 0.724 + 3.06[(Sv'/Sw)/(1+cosΛwing)] − 0.4(z̄wf/Df) + 0.009·Awing   (16.51)
```
(`Sv'` = vertical tail area extended to the fuselage centerline.)

### §16.4.7 Thrust Effects on Lateral-Directional Trim and Stability

All-engines-running: direct thrust moments cancel, normal-force moments add. Engine failure:
remaining engine(s) produce a large yaw moment plus the failed-engine drag term (Chapter 13). Propwash
dynamic-pressure effect via Eq. (16.31); propwash sidewash effect via Eqs. (16.30) & (16.23), fed into
Eq. (16.51).

Lateral analysis (beyond engine-out rudder sizing) is often deferred in early conceptual design — good
lateral results generally need 6-DOF analysis with wind-tunnel data; tail-volume-coefficient rules of
thumb drive early tail/dihedral/aileron/rudder sizing.

## §16.5 Stick-Free Stability

Previous analysis assumed rigidly-held control surfaces ("stick-fixed," reasonable for powered FCS
aircraft). Manual/boosted controls "float" under airload, needing **stick-free** analysis. Worst case:
elevator floats fully free (contributes nothing to tail lift) — % reduction in tail lift-curve slope =
elevator area as % of total tail area. Typically a partially aerodynamically-balanced elevator instead
reduces the slope by ~50% of that area fraction (e.g., 40%-area elevator → ~20% slope reduction) [82].
An "overbalanced" elevator can float *into* the wind, adding stability but producing unusual control
forces — hard to predict even with wind-tunnel data. Detailed hinge-moment-based methods: [13, 118].
Typically stick-free neutral point sits 2–5% MAC ahead of stick-fixed. Stick-free directional
stability is reduced similarly by rudder float.

## §16.6 Effects of Flexibility

Fuselage/wing bending and wing torsion reduce control/stability effectiveness. Flexible-fuselage
bending reduces effective tail incidence with increasing α (less pitch-restoring effectiveness); same
for vertical-tail via lateral bending. A flexible swept wing twists to reduce tip α, cutting lift-curve
slope and moving the wing a.c. forward (destabilizing). Fig. 16.23 illustrates (schematic, no plotted
data) *[Raymer, Fig. 16.23, p. 611]*. Typical high-subsonic swept-wing transport effects: wing
`CL_α` down ~20%, tail pitching-moment contribution down ~30%, elevator effectiveness down ~50%, wing
a.c. forward ~10% MAC; aileron effectiveness can drop 50%–>100% (**aileron reversal**: wing twists
opposite the intended roll direction at high `q`) — many jet transports lock outboard ailerons at high
speed and rely on spoilers/inboard ailerons.

**Fig. 16.24 — Aileron reversal caused by flexibility (B-47)** *[Raymer, Fig. 16.24, p. 612]* — roll
rate (deg/s) vs velocity (150–500 kt). *(read from plot)*:

| V (kt) | Roll rate (deg/s) |
|---|---|
| 150 | ~28 |
| 250 | ~35 |
| 350 | ~15 |
| 470 | 0 (reversal onset) |
| 500 | ~ −8 (reversed) |

Above ~470 kt the B-47's ailerons work backward (up-aileron twists the wing enough to increase lift,
rolling the wrong way); pilots were trained to reverse stick input above that speed if spoilers
failed. A computerized FCS today can compensate for this transparently, saving substantial structural
weight otherwise needed to push the reversal speed out. Effects scale with dynamic pressure (worst at
low altitude/high speed); stiffer aircraft (low-AR wing, short fuselage — typical fighters) see less
impact.

## §16.7 Dynamic Stability

### §16.7.1 Mass Moments of Inertia

Rotational inertia resists rotational acceleration: `Ixx` (roll), `Iyy` (pitch), `Izz` (yaw). Estimated
from historical nondimensional radii of gyration `R` [18] [Raymer, Eq. (16.52)–(16.54), p. 614]:

```
Ixx = b² M Rx² / 4 = b² W Rx² / (4g)                                    (16.52)
Iyy = L² M Ry² / 4 = L² W Ry² / (4g)                                    (16.53)
Izz = (b+L)² M Rz² / 8 = (b+L)² W Rz² / (8g)                             (16.54)
```
(Results in slug-ft²; in metric, drop the `g` term for gram-m².)

**Table 16.1 — Nondimensional Radii of Gyration** *[Raymer, Table 16.1, p. 614]*

| Aircraft Class | Rx | Ry | Rz |
|---|---|---|---|
| Single-engine prop | 0.25 | 0.38 | 0.39 |
| Twin-engine prop | 0.34 | 0.29 | 0.44 |
| Business jet twin | 0.30 | 0.30 | 0.43 |
| Twin turboprop transport | 0.22 | 0.34 | 0.38 |
| Jet transport — fuselage-mounted engines | 0.24 | 0.36 | 0.44 |
| Jet transport — 2 wing-mounted engines | 0.25 | 0.38 | 0.46 |
| Jet transport — 4 wing-mounted engines | 0.31 | 0.33 | 0.45 |
| Military jet trainer | 0.22 | 0.14 | 0.25 |
| Jet fighter | 0.23 | 0.38 | 0.52 |
| Jet heavy bomber | 0.34 | 0.31 | 0.47 |
| Flying wing (B-49 type) | 0.32 | 0.32 | 0.51 |
| Flying boat | 0.25 | 0.32 | 0.41 |

Full 6-DOF analysis also needs **products of inertia** (cross terms between two of X/Y/Z per mass
element, summed) — zero for a symmetric aircraft about the X-Z plane, but tail mass tips the mass
principal axis down at the nose by a few degrees if the XY-plane product isn't zero; the aircraft then
"fights" rotation about the fuselage centerline and instead rotates about the principal axis. Hard to
estimate at conceptual level — ratio from similar aircraft by weight as a rough guess; usually ignored
until a full 6-DOF mass buildup is done.

### §16.7.2 Damping Derivatives

Rotational damping (∝ pitch rate `Q`, roll rate `P`, yaw rate `R`) arises from the rotation-induced
change in local effective α (Fig. 16.25: tail lift change in steady pitch-up; wing-strip lift change in
steady roll) *[Raymer, Fig. 16.25, p. 615]* — schematic, no plotted data. Damping moment ∝ rate ×
(moment arm)². Pitch/yaw damping [Raymer, Eq. (16.55)–(16.56), p. 615]:

```
Cm_Q ≈ −2 η_h (Sh/Sw)(x̄ach − x̄cg)² CL_αh          [η ≈ 0.9]            (16.55)
Cn_R ≈ −2 η_v (Sv/Sw)(x̄acv − x̄cg)² CF_βv − (wing-drag yaw-damping term)  (16.56)
```

Roll damping from **Fig. 16.26 — Roll damping parameter** *[Raymer, Fig. 16.26, p. 616]* (NACA 1098/868
data), `Cl_P` vs AR (2–16), sweep-factor family (0°→1.0, 30°→0.9, 45°→0.8, 60°→0.7/0.6).
*(read from plot, Λ=0° curve)*:

| AR | Cl_P (Λ=0°) |
|---|---|
| 2 | ~ −0.28 |
| 4 | ~ −0.38 |
| 6 | ~ −0.45 |
| 8 | ~ −0.48 |
| 10 | ~ −0.48 |
| 14 | ~ −0.46 |

Multiply by the sweep factor for swept wings. Cross-derivative approximations: `Cl_R ≈ CL/4`;
`Cn_P ≈ −CL/8`.

### §16.7.3 One-DOF Dynamic Equations

`(rotational accel)×(inertia) = ΣM` [Raymer, Eq. (16.57)–(16.59), p. 616]:

```
Pitch:  Iyy Q̇ = Σ M   (includes Cm_Q·Q damping term)                    (16.57)
Yaw:    Izz Ṡ = Σ N   (includes Cn_R·R damping term)                    (16.58)
Roll:   Ixx Ṭ = Σ L   (includes Cl_P·P damping term, no 1st-order φ term)  (16.59)
```
(second-order ODEs; roll has no restoring term in φ itself since roll angle doesn't affect roll moment
at zero sideslip.)

### §16.7.4 Aircraft Dynamics: Three-DOF and Six-DOF

One-DOF equations are approximate; real motion always couples ≥3 DOF. Longitudinal needs ≥3-DOF
(pitch, vertical velocity, forward velocity — +1 more for stick-free elevator). Lateral stick-fixed
needs ≥3-DOF (lateral velocity, sideslip, roll — +2 more for stick-free aileron/rudder). Full 6-DOF
(9-DOF stick-free) preferred, especially at high α where `CL` and the lateral derivatives interact.
Detailed 3-/6-DOF technique beyond scope; typical results:
- **Longitudinal**: short-period mode (heavily damped, gives the desired pitch-disturbance response)
  + **pitch phugoid** (long-period, lightly-damped slow oscillation trading vertical/forward velocity —
  usually small/unnoticeable, pilot-correctable; avoid excessive phugoid).
- **Lateral**: direct convergence (desired), spiral divergence (slow increasing bank — easily
  corrected), **Dutch roll** (short-period yaw/roll waddle, largely from dihedral effect; excessive
  Dutch roll is objectionable to occupants). Dutch roll damping is set mainly by vertical-tail size and
  usually drives tail sizing besides engine-out control — don't shrink the tail below the tail-volume-
  coefficient result without a 6-DOF check (preferably with wind-tunnel derivative data). Flexibility
  worsens Dutch roll at high speed; many large swept-wing aircraft use a yaw-damper-driven powered
  rudder to add effective damping.

### §16.7.5 Quasi-Steady-State Maneuvers

Setting rotational accelerations to zero in Eqs. (16.57)–(16.59) gives quasi-steady trim + damping
equations for:

**Pull-up** (load factor `n`, level flight `n=1`): trim equation Eq. (16.7) + pitch damping
(`Cm_Q·Q`), solved for total lift = `nW`; pitch rate [Raymer, Eq. (16.60), p. 617]:
```
Q = g(n−1)/V                                                            (16.60)
```

**Level turn** (sideslip stays zero — purely longitudinal): load factor and pitch rate from bank angle
`φ` [Raymer, Eq. (16.61)–(16.62), p. 617]:
```
n = 1/cosφ                                                              (16.61)
Q = (g/V)(n − 1/n)                                                       (16.62)
```

**Steady roll**: set Eq. (16.59) to zero; only surviving term at zero sideslip is aileron rolling
moment [Raymer, Eq. (16.63)–(16.64), p. 617]:
```
Ixx Ṭ = 0 = q Sw b Cl_δa δa + q Sw b Cl_P P                              (16.63)
P = −(Cl_δa/Cl_P) δa                                                     (16.64)
```

Historic roll-rate criterion: wing helix angle `Pb/(2V) ≥ 0.07` (0.09 for fighters) considered "good"
by pilots (NACA 715). Modern requirement: MIL-F-8785B / MIL-STD-1797 bank-angle-in-time targets.

**Table 16.2 — MIL-F-8785B Roll Requirements** *[Raymer, Table 16.2, p. 618]*

| Aircraft Type (Class) | Required Roll |
|---|---|
| III — Light utility, observation, primary trainer | 60° in 1.3 s |
| IV A — Medium bomber, cargo, transport, ASW, recce | 45° in 1.4 s |
| IV B — Heavy bomber, cargo, transport | 30° in 1.5 s |
| IV C — Fighter-attack, interceptor | 90° in 1.3 s |
| Air-to-air dogfighter | 90° in 1.0 s, or 360° in 2.8 s |
| Fighter with air-to-ground stores | 90° in 1.7 s |

(Assumes level flight at roll initiation; rotational acceleration matters formally, but quasi-steady
roll rate is an acceptable initial estimate since max roll rate is reached quickly.)

### §16.7.6 Inertia Coupling

The F-100 prototype (first level-supersonic fighter, thin swept wing + long heavy fuselage) diverged in
α and β during high-speed rolls — traced to **inertia coupling** (Fig. 16.27): the aircraft's actual
roll axis sits between its mass principal axis and the wind axis (ailerons roll about the wind axis;
mass "prefers" the principal axis); forebody/aft-fuselage masses above/below that actual roll axis feel
centrifugal force pulling them away from it, producing a nose-up pitching moment; simultaneously, a
90° body-axis roll would exchange α and yaw angle, and `Cn_β` from the vertical tail opposes that yaw
increase. *[Raymer, Fig. 16.27, p. 618]* — schematic of forebody/aft-fuselage "barbell" masses, wind
axis vs. principal axis vs. actual roll axis; no plotted data. Becomes a problem when inertia moments
exceed aerodynamic restoring moments — worst at high altitude (low density) and high Mach (tail loses
effectiveness). F-100 fix (and the standard fix since): a larger vertical tail — don't shrink the
tail below the statistical tail-volume result without a detailed coupling check.

## §16.8 Handling Qualities

### §16.8.1 Cooper–Harper Scale

Handling qualities = subjective pilot "feel." Early aircraft (Fokker Eindecker) had qualities so poor
pilots felt constant attention was needed to avoid the aircraft "turn[ing] itself inside out" [120].
Beyond quantitative goodness criteria (wing helix angle, etc.), designers want linear control response
and appropriately-sized, predictable control forces (including flap/power-application forces).
Test pilots rate deficiencies using the **Cooper–Harper Handling Qualities Rating Scale** [121] — a
decision-tree from aircraft characteristics + pilot workload to a 1–10 numerical rating.

**Fig. 16.28 — Cooper–Harper Handling Qualities Rating Scale** *[Raymer, Fig. 16.28, p. 621]* — decision
tree; three branches (adequate for task without/with improvement, or improvement mandatory) each
subdivided by aircraft-characteristics description (Excellent → Major deficiencies, controllability
lost) crossed with pilot-compensation-demand description, yielding Pilot Ratings 1 (excellent, minimal
compensation) through 10 (control lost). No plotted numeric data (categorical rating chart); detailed
handling-qualities discussion: [122].

### §16.8.2 Departure Criteria

High-α behavior: a "good" airplane buffets to warn the pilot, retains all-axis control, stalls straight
ahead, recovers immediately, and recovers from a forced spin immediately. A "bad" airplane loses
one/more axes of control as α rises — typically aileron roll control degrades and adverse yaw
increases, so any aileron-induced yaw near stall can stall one wing and trigger an uncommanded
departure into a spin. Key coefficients: `Cn_β`, `Cn_δa`, `Cl_β`, `Cl_δa`, combined into the **lateral
control departure parameter (LCDP)** [Raymer, Eq. (16.65), p. 622]:

```
LCDP = Cn_β − Cl_β (Cn_δa/Cl_δa)                                        (16.65)
```

and a dynamic directional-stability parameter including inertia effects [Raymer, Eq. (16.66), p. 622]:

```
Cn_β,dynamic = Cn_β cosα − (Izz/Ixx) Cl_β sinα                          (16.66)
```

Both should be positive; typical goal `Cn_β,dynamic > 0.004`. **Fig. 16.29 — Departure susceptibility**
*[Raymer, Fig. 16.29, p. 623]* — LCDP vs `Cn_β,dynamic` crossplot with region boundaries (no departures /
mild departures, low spin susceptibility / poor roll control [Weissman criteria]) from high-g simulator
tests [123]. *(read from plot, boundary lines)*:

| Cn_β,dynamic | LCDP boundary (no-departure region lower edge) |
|---|---|
| 0.000 | ~0.000 |
| 0.004 | ~0.001 |
| 0.008 | ~0.002 |
| 0.012 | ~0.003 |

(F-5 traces increasingly into the good region with rising α — cited as one of the best high-α
fighters; F-4 starts acceptable but crosses into "poor roll control" as α rises; HiMat, an advanced
canard configuration with cambered outboard L.E.s and large low-mounted twin tails, also stays good.)
Stability derivatives get strongly nonlinear near stall, so conceptual-design first-order estimates of
these parameters are unreliable — final numbers come from wind-tunnel data, with the configuration
designer expected to "fix it" once available.

Design rules usable at layout stage: elliptical nose cross-section (wider than tall) and a nose
strake/sharp edge on each side to force symmetric (rather than one-sided) vortex shedding, avoiding
strong asymmetric yaw at high α; prevent wingtip stall via twist/fences/notches/movable L.E. devices;
a substantial ventral-tail area helps departure prevention.

### §16.8.3 Spin Recovery

In a fully developed spin (Fig. 16.30, forces on fuselage/wing "barbell" masses) *[Raymer, Fig. 16.30,
p. 624]* — schematic, no plotted data — centrifugal force on the fuselage raises the nose (worsening
wing stall); the spin itself is driven by the lift difference between the outer (faster, less stalled)
and inner (slower, more stalled) wing, opposed by damping from the aft fuselage/vertical-tail area
below the horizontal tail (`SF`, Fig. 16.31 defines this geometry) *[Raymer, Fig. 16.31, p. 624]* —
schematic. Recovery: rudder deflected against the spin — only the unshielded rudder area (`SR1`,
`SR2`, not blanketed by stalled horizontal-tail wake) helps.

Empirical spin-recovery sizing [124]: minimum **tail-damping power factor (TDPF)**
[Raymer, Eq. (16.67)–(16.70), p. 625]:

```
TDPF = TDR × URVC                                                       (16.67)
TDR  = [tail-damping ratio, function of SF·(lengths), Iyy−Ixx, etc.]     (16.68)
URVC = [unshielded rudder volume coefficient, SR·(moment arm)/(Sw b)]    (16.69)
μ = (W/S) / (ρ g b)                                                      (16.70)
```

**Fig. 16.32 — Spin recovery criteria** *[Raymer, Fig. 16.32, p. 626]* — required TDPF (×10⁻⁴) vs
`(Ix−Iy)/(Ib²W/g)` (×10⁻⁴, range −240 to +160, wing-heavy to body-heavy), two curves ("rudder alone" and
"rudder and elevator" recovery credit). *(read from plot)*:

| (Ix−Iy)/(Ib²W/g) ×10⁻⁴ | TDPF required, rudder alone (×10⁻⁴) | TDPF required, rudder+elevator (×10⁻⁴) |
|---|---|---|
| −200 | ~22 | ~14 |
| −100 | ~14 | ~8 |
| 0 | ~8 | ~4 |
| 100 | ~16 | ~9 |
| 160 | ~24 | ~14 |

(Applicable to straight-winged aircraft; method is dominated by rudder/vertical-tail/aft-fuselage
ability to oppose spin rotation.) Spin entry can also be delayed / recovery enhanced by reshaping the
wing L.E. to reduce the inboard/outboard lift imbalance — typically a drooped L.E. near the tips, at
some cruise-drag cost.

## What We've Learned

Static-margin calculation shows whether the wing needs to move; trim/pull-up/turn calculations size
the elevator and horizontal tail; lateral-stability calculations show whether the vertical tail,
rudder, and ailerons need revision.

*Photo: Thunderbird F-16 showing vapor/smoke streaks (U.S. Air Force photo), p. 636 — no plotted data.*

---

*Chapter 16 complete (§§16.1–16.8, Tables 16.1–16.2, Figs 16.1–16.32, Eqs 16.1–16.70). Several plotted
figures (16.5, 16.17, 16.21 low-λ panel) were left as qualitative-only or partially digitized because
the source scan's OCR/typography was too degraded to trust a fine digitization — flagged inline with
`[verify p.NNN]`. Next: Chapter 17 — Performance and Flight Mechanics.*
