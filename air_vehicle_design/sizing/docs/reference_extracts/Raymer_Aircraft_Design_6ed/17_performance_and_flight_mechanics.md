# Chapter 17 — Performance and Flight Mechanics

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 17
"Performance and Flight Mechanics," printed pp. 637–686 (PDF index 668–717).

Equations of motion (Newton's laws applied to the flight-path axes) for level flight, climb, turn,
glide, energy-maneuverability, operating envelope, takeoff, and landing. Very equation-dense;
several figures are graphical-optimization illustrations of results already derived analytically
(kept as schematics) and a few are genuine plotted design/comparison data (digitized below).

---

## §17.1 Introduction and Equations of Motion

Chapter 16 covered rotational motion (stability/control); this chapter covers translational motion —
assuming the aircraft is already stabilized/controlled to some α, bank, and sideslip, what does it
*do*? Geometry in wind axes (X along velocity, Z up); climb angle `γ` is the angle between X and the
horizon; climb gradient `G = tanγ` = vertical velocity / horizontal velocity.
*[Raymer, Fig. 17.1, p. 638]* — force triangle: `Vv = V sinγ`, `VH = V cosγ`, `G = tanγ = Vv/VH`. No
plotted data (definition sketch).

Summing forces along X/Z (wind axes) [Raymer, Eq. (17.1)–(17.2), p. 637]:

```
ΣFx = T cos(α+φT) − D − W sinγ                                          (17.1)
ΣFz = T sin(α+φT) + L − W cosγ                                          (17.2)
```

Fuel-flow / propeller-thrust relations [Raymer, Eq. (17.3)–(17.5), p. 638]:

```
Ẇ = −C T                                                                (17.3)
C = Cbhp (bhp/T)             [piston-prop equivalent SFC, Chapter 5 def.]  (17.4)
T = P ηp / V = 550 bhp ηp / V                                           (17.5)
```

These simple equations underlie even the most detailed industry sizing/performance codes: α and
thrust are varied to give the required lift (incl. load factor) and longitudinal acceleration for
whatever maneuver is being flown, subject to `CLmax` and installed-thrust-vs-altitude/Mach limits.
The hard part is not the force balance itself but determining *what* α/thrust achieve a given
maneuver objective (e.g., the velocity/thrust-setting combination that climbs to cruise altitude with
least fuel).

For most aircraft the thrust axis is nearly aligned with the wind axis by design (engines push, wings
lift), simplifying to [Raymer, Eq. (17.6)–(17.7), p. 639]:

```
ΣFx = T − D − W sinγ                                                    (17.6)
ΣFz = L − W cosγ                                                        (17.7)
```

**Units caution**: whenever "550" appears, other units must be ft/lb/s (1 bhp = 550 ft·lb/s); SFC `C`
is usually given in hr⁻¹ and must be divided by 3600 for s⁻¹.

## §17.2 Steady Level Flight

Level flight (`γ=0`, ΣF=0): thrust=drag, lift=weight [Raymer, Eq. (17.8)–(17.10), p. 639]:

```
T = D = q S (CD0 + K CL²)                                               (17.8)
L = W = q S CL                                                          (17.9)
V = sqrt( 2(W/S) / (ρ CL) )                                             (17.10)
```

### §17.2.1 Minimum Thrust Required for Level Flight

`T/W = 1/(L/D)` in level flight [Raymer, Eq. (17.11), p. 640]:

```
T/W = (L/D)⁻¹ = q CD0/(W/S) + K(W/S)/q                                  (17.11)
```

Minimizing thrust (= maximizing L/D): set `∂(T/W)/∂V = 0` [Raymer, Eq. (17.12)–(17.14), p. 640]:

```
Vmin-thrust = sqrt( (2/ρ)(W/S) sqrt(K/CD0) )                            (17.13)
CL,min-thrust = sqrt(CD0/K)                                             (17.14)
```

At this `CL`, induced drag = zero-lift drag, so total drag = 2× zero-lift drag [Raymer, Eq. (17.15),
p. 640]:

```
Dmin = qS(CD0 + CD0) = qS·2·CD0                                         (17.15)
```

### §17.2.2 Minimum Power Required for Level Flight

Power = drag × velocity [Raymer, Eq. (17.16)–(17.17), p. 641]:

```
P = D V = (1/2)ρV³S(CD0 + K CL²) = (1/2)ρV³S CD0 + K W² / ((1/2)ρVS)    (17.16)–(17.17)
```

`∂P/∂V=0` [Raymer, Eq. (17.18)–(17.21), p. 641]:

```
Vmin-power = sqrt( (2/ρ)(W/S) sqrt(K/(3CD0)) ) = 0.76·Vmin-thrust        (17.19)
CL,min-power = sqrt(3 CD0/K) = 1.73·CL,min-thrust                       (17.20)
Dmin-power = qS(CD0 + 3CD0) = 4·qS·CD0                                  (17.21)
```

At min-power the induced drag is 3× the zero-lift drag (total 4×), twice the min-drag `CD` — but the
lower dynamic pressure at that (slower) speed means the *actual* drag is only 15.5% higher than at
min-drag (2.0 × dynamic-pressure ratio 0.76² ≈ 1.155); so `L/D` at min-power speed = 1/1.155 = 0.866
of max `L/D`.

### §17.2.3 Graphical Analysis for Thrust and Power Required

The closed-form results above assume constant `CD0`/parabolic-drag `K` with velocity — good only for
high-AR wings at low Mach (Chapter 12 caveat). Real analysis plots thrust (jets) or power (props)
required vs velocity/Mach against installed engine data (Fig. 17.2); sizing/performance codes search
numerically rather than using the closed forms.

*[Raymer, Fig. 17.2, p. 642]* — **Thrust and power** — top panel: Thrust (lb) vs velocity (0–700,
units unlabeled but implicitly kt), drag/thrust-required curve (U-shaped, min near velocity ~250–300)
and jet-thrust-available (roughly flat ~4500 lb) line, intersecting at max speed; bottom panel: Power
(HP) vs velocity, power-required curve (U-shaped, min at a lower velocity than min-thrust) plus
piston-prop 2000-HP available line (flat) and jet-thrust-power-available curve (rising with V).
*(read from plot, qualitative — the figure is a schematic sample, not aircraft-specific data)*:

| Feature | Approx. value |
|---|---|
| Min-thrust-required velocity | ~300 (chart units) |
| Min-power-required velocity | ~260 (≈0.87× the thrust-min velocity, consistent with the 0.866 rule) |
| Stall velocity marker | leftmost vertical dashed line |
| Max speed (piston-prop) | where power-available crosses power-required |

(No absolute units given in the source scan; figure is illustrative, not a numeric design chart —
treat as a schematic, not digitized further.)

### §17.2.4 Range

Instantaneous range and Breguet range equation [Raymer, Eq. (17.22)–(17.23), p. 643]:

```
dR/dW = −V/(C T) = −V/(C D) = V(L/D)/(C W)                              (17.22)
R = ∫ (V/C)(L/D) dW/W    [integrated assuming V, C, L/D ≈ constant]      (17.23)
```

Constant-`CL` cruise as the aircraft lightens requires reducing dynamic pressure at constant velocity
→ climbing → the **cruise-climb** profile (max range), approximated in practice by ATC-compatible
"stair-step" climbs, broken into shorter constant-altitude mission segments each analyzed via Breguet.

### §17.2.5 Range Optimization — Jet

"Range parameter" `(V/C)(L/D)`; for subsonic jets `C` ≈ independent of velocity, so [Raymer,
Eq. (17.24)–(17.27), p. 644]:

```
(V/C)(L/D) = (V/C)·CL/(CD0 + K CL²)
           = (2W/(ρVS)) / [ C·CD0 + 4KW²C/(ρ²V⁴S²) ]                     (17.24)
Vbest-range  = sqrt( (2W/(ρS)) · sqrt(3K/CD0) )                          (17.25)
CLbest-range = sqrt( CD0/(3K) )                                         (17.26)
Dbest-range  = qS · ( CD0 + CD0/3 )      [ = 1.33 · qS·CD0 ]              (17.27)
```
(**Corrected 2026-08-18** against a 300-dpi render of book p. 645. Eq. 17.25's inner radical is
`sqrt(3K/CD0)`, **not** `sqrt(K/(3CD0))` — the previous version had the ratio inverted, which is why
it looked identical to the min-power form Eq. 17.19. The printed form is self-consistent with the
text: Eq. 17.25 / Eq. 17.13 = 3^(1/4) = 1.316, which is the 31.6% the book states. Eq. 17.26 was
missing entirely, and Eq. 17.27 is a **drag**, `D = qS(CD0 + CD0/3)`, not a drag coefficient.)

Best-range `CD` (1.33×`CD0`) is lower than best-`L/D` `CD` (2×`CD0`), but best-range flies 31.6%
faster (higher q) so actual drag at best-range speed is ~1.154× the min-drag value, giving
`L/D`(best-range) = 0.866 × `(L/D)max` (matches the Chapter 5 result cited without proof there).

### §17.2.6 Range Optimization — Prop

Substituting the propeller thrust relation into Eq. (17.23) removes the velocity dependence, so prop
range is maximized simply at the velocity/`CL` for max `L/D` (Eqs. 17.13–17.14) [Raymer, Eq. (17.28),
p. 645].

### §17.2.7 Loiter Endurance

Instantaneous and integrated endurance [Raymer, Eq. (17.29)–(17.30), p. 646]:

```
dE/dW = −1/(C T) = −(L/D)/(C W)                                         (17.29)
E = ∫ (1/C)(L/D) dW/W   ≈ (1/C)(L/D) ln(Wi/Wf)   [approx if C,L/D const]  (17.30)
```

### §17.2.8 Loiter Optimization — Jet
Only `L/D` varies with velocity ⇒ jet loiter is maximized at max `L/D` (Eqs. 17.13–17.14).

### §17.2.9 Loiter Optimization — Prop
Substituting the prop relation introduces a velocity term [Raymer, Eq. (17.31)–(17.33), p. 647]:

```
E = (L/D)(ηp/(Cpower V)) ln(Wi/Wf) = (L/D)(550ηp/(Cbhp V)) ln(Wi/Wf)     (17.31)
```

Maximizing w.r.t. V leads back to the **same** velocity as minimum power required (Eq. 17.19) — so
best-prop-loiter `CL`/drag are identical to the min-power values (Eqs. 17.20–17.21): fly at 76% of
best-`L/D` velocity, `L/D` = 86.6% of max.

### §17.2.10 Relationship Between Loiter and Cruise

Empirical shortcut for estimating equivalent loiter time from known range/cruise speed [125]
[Raymer, Eq. (17.34), p. 647]:

```
Eloiter = 1.14 (Rcruise / Vcruise)                                       (17.34)
```

### §17.2.11 Effects of Wind on Cruise and Loiter

A 10%-lower groundspeed headwind ⇒ 10% less range for the same fuel; for range *requirements*, scale
the required cruise range in the mission-segment weight-fraction equation by
`Vairspeed/Vgroundspeed`, using actual airspeed for `V` elsewhere. Crosswind groundspeed via the Law
of Sines / wind-vector triangle [Raymer, Eq. (17.35), p. 648]:

```
Vgroundspeed = Vairspeed sin{π − Δtailwind − sin⁻¹[Vwind sinΔtailwind / Vairspeed]} / sinΔtailwind
```
(`Δtailwind` = relative wind angle, 0 = tailwind, π = headwind.)
*[Raymer, Fig. 17.3, p. 648]* — wind-triangle vector diagram (airspeed vector, ground-track vector,
tailwind-angle callout). No plotted data (geometry construction, not a data curve).

Fly faster into a headwind, slower with a tailwind, for best range — typically only a 5–10% airspeed
adjustment, gaining a few percent range vs the no-wind optimum. Wind has no effect on loiter
optimum airspeed (barring being blown backward).

## §17.3 Steady Climbing and Descending Flight

### §17.3.1 Climb Equations of Motion

Setting Eqs. (17.6)–(17.7) with `γ≠0` to zero gives steady climb [Raymer, Eq. (17.36)–(17.39), p. 649]:

```
T = D + W sinγ                                                          (17.36)
L = W cosγ                                                              (17.37)
γ = sin⁻¹[(T−D)/W] = sin⁻¹[(T/W) − cosγ/(L/D)] ≈ sin⁻¹[(T/W) − 1/(L/D)]   (17.38)
Vv = V sinγ = V[(T−D)/W] ≈ V[(T/W) − 1/(L/D)]                            (17.39)
```

Climb velocity and required T/W [Raymer, Eq. (17.40)–(17.41), p. 649]:

```
V = sqrt( 2(W/S)cosγ / (ρ CL) )                                          (17.40)
T/W = cosγ/(L/D) + sinγ ≈ 1/(L/D) + Vv/V                                (17.41)
```

### §17.3.2 Graphical Method for Best Angle/Rate of Climb

Best rate of climb = peak of the `Vv`-vs-`V` curve; best angle of climb = point of tangency from the
origin (max `Vv/VH`) — see Fig. 17.4 for graphical construction.
*[Raymer, Fig. 17.4, p. 650]* — `Vv` vs `VH=V` curve with the tangent-line construction marked "Best
rate of climb" at the peak. No numeric data (generic sketch).

### §17.3.3 Best Angle and Rate of Climb — Jet

Thrust ≈ constant with V ⇒ best climb *angle* velocity = best-`L/D` velocity (Eq. 17.13). Best climb
*rate*: maximize Eq. (17.39) [Raymer, Eq. (17.42)–(17.43), p. 651]:

```
Vbest-rate = sqrt{ (W/S)/(3ρCD0) · [T/W + sqrt((T/W)² + 12CD0K)] }        (17.43)
```

At `T=0` this collapses to the min-power velocity (Eq. 17.19), a lower bound. Nonzero thrust
significantly raises the best-climb-rate velocity — can be ~2× the min-power velocity; 300–500 kt
typical for jets (B-70: 583 kt / 1080 km/h). This gives only the best rate at a *given* altitude, not
the full minimum-time-to-climb profile (needs the specific-excess-power method, §17.6).

### §17.3.4 Best Angle and Rate of Climb — Prop

[Raymer, Eq. (17.44), p. 651]:

```
γ = sin⁻¹[ (550 bhp ηp)/(WV) − 1/(L/D) ]                                 (17.44)
```

Theoretical optimum from this equation tends to be unrealistically low-speed (parabolic drag breaks
down at high α; thrust model implies infinite thrust at V=0). Practical rule: best-angle speed ≈
85–90% of best-rate speed. Best rate of climb (substituting the prop thrust relation into Eq. 17.39)
[Raymer, Eq. (17.45), p. 652]:

```
Vv = (550 bhp ηp)/W − DV/W                                              (17.45)
```
= (power available − power required)/weight ⇒ occurs at the min-power-required velocity (Eq. 17.19).

### §17.3.5 Time to Climb and Fuel to Climb

[Raymer, Eq. (17.46)–(17.47), p. 652]:

```
dt = dh/Vv                                                              (17.46)
dWf = −C T dt                                                            (17.47)
```

Linear approximation of `Vv` vs altitude over a segment [Raymer, Eq. (17.48)–(17.49), p. 652]:

```
Vv = Vv1 + a(h − h1)                                                    (17.48)
a = (Vv2 − Vv1)/(h2 − h1)                                                (17.49)
```

Integrated time and fuel for a short segment (<5000 ft / 1500 m, so weight change is negligible)
[Raymer, Eq. (17.50)–(17.51), p. 653]:

```
Δt(i→i+1) = (1/a) ln(Vv,i+1 / Vv,i)                                      (17.50)
ΔWf = C·T·Δt                                                             (17.51)
```
(Can be iterated: recompute `Vv` at reduced weight after subtracting `ΔWf`.)

## §17.4 Level Turning Flight

Turn geometry: total wing lift = `nW`; horizontal lift component = `W√(n²−1)` (Fig. 17.5 — schematic,
no plotted data) *[Raymer, Fig. 17.5, p. 654]*. Turn rate [Raymer, Eq. (17.52), p. 653]:

```
ψ̇ = (radial accel)/V = [W√(n²−1)/(W/g)] / V = g√(n²−1)/V   [rad/s; ×57.3 for deg/s]  (17.52)
```

### §17.4.1 Instantaneous Turn Rate

If velocity may bleed off, `n` is limited only by `CLmax` or structure — **Fig. 17.6 — Turn rate and
corner speed** *[Raymer, Fig. 17.6, p. 654]*, turn rate (deg/s) vs velocity (100–700 kt), stall-limit
curve (rising then peaking) intersecting a roughly-flat structural-limit line at the **corner
speed** (~300–350 kt for a typical fighter — max instantaneous turn rate). *(read from plot, sample
one-altitude data)*:

| V (kt) | Turn rate, stall-limited (deg/s) | Turn rate, structure-limited (deg/s) |
|---|---|---|
| 150 | ~14 | — |
| 200 | ~20 | — |
| 250 | ~25 | ~26 |
| 300 (≈corner) | ~26 (peak, corner speed) | ~26 |
| 400 | — | ~20 |
| 500 | — | ~15 |
| 600 | — | ~11 |

(Sample-data chart per the source caption; treat as illustrative order-of-magnitude, not aircraft-
specific.) In a turning dogfight, both pilots try to reach their own corner speed fastest.

### §17.4.2 Sustained Turn Rate

No altitude/speed loss ⇒ T=D, L=nW [Raymer, Eq. (17.53)–(17.54), p. 655]:

```
n = (T/W)(L/D)                                                          (17.53)
n = (q/(K(W/S))) [ T/W − qCD0/(W/S) ]                                    (17.54)
```
(`K` itself varies with `CL` per Chapter 12, so Eq. (17.54) needs iteration.) Optimized at the
max-`L/D` `CL` [Raymer, Eq. (17.55), p. 655]:

```
L = nW = qS·CL sqrt(CD0/K)   [at CL for max L/D]                         (17.55)
```

Fig. 17.6 also shows the sustained-turn-rate envelope, derived by applying Eq. (17.52) to the
sustained load factors available at each flight condition (same figure as above; no separate
digitization).

### §17.4.3 Turn Rate with Vectored Thrust

Harrier-style vectoring adds thrust-component-driven load factor. Level turn with vectored thrust
[Raymer, Eq. (17.56)–(17.58), p. 655]:

```
nW = L + T sin(α+φT)                                                    (17.56)
∂n/∂φT = 0  ⇒  φT = 90° − α          [instantaneous turn: vector ⟂ flight path]  (17.58)
```

Sustained turn with vectored thrust [Raymer, Eq. (17.59)–(17.61), p. 656]:

```
n = (T/W) cos(α+φT) · (L/D)     [drag = T cos(total angle)]              (17.59)
∂n/∂φT = 0  ⇒  φT = −α           [sustained turn: vector aligned with flight path]  (17.61)
```

Instantaneous turn wants thrust perpendicular to the flight path (max load factor, at the cost of
rapid deceleration — the Harrier's 90°-vectoring "trick" to force an overshoot); sustained turn wants
thrust *aligned* with the flight path (i.e. effectively along the freestream, not vectored down) —
though this ignores a possible jet-flap drag benefit from slight downward deflection near the wing
T.E. Vectoring for turn augmentation requires nozzles near the c.g. (Harrier) — aft nozzles (F-22)
create an unbalanceable pitching moment unless paired with a large canard (F-15 STOL/Maneuver
demonstrator, an early Lockheed JSF concept) to provide the opposing nose-up moment.

## §17.5 Gliding Flight

### §17.5.1 Straight Gliding Flight

Zero-thrust climb equations [Raymer, Eq. (17.62)–(17.64), p. 657]:

```
D = W sinγ                                                              (17.62)
L = W cosγ                                                              (17.63)
L/D = 1/tanγ                                                            (17.64)
```

"Glide ratio" = horizontal distance / altitude lost = `L/D` (a glide-ratio-40 sailplane travels >7
statute miles per 1000 ft lost). Max-range glide flies at max-`L/D` velocity/`CL` (Eqs. 17.13–17.14,
17.15→17.67) [Raymer, Eq. (17.65)–(17.67), p. 657]:

```
(L/D)max = 1/(2√(CD0 K)) = (1/2)√(1/(CD0 K))                            (17.67)
```

Sink rate [Raymer, Eq. (17.68)–(17.70), p. 658]:

```
Vv = V sinγ = V(CD/CL) cosγ                                             (17.68)
sinγ = (CD/CL) cosγ                                                     (17.69)
Vv = sqrt[ (W/S)(2cos³γ/ρ) · CD²/CL³ ]                                   (17.70)
```

Min-sink `CL` [Raymer, Eq. (17.71)–(17.74), p. 658]:

```
CL,min-sink = sqrt(3CD0/K)                                              (17.72)
Vmin-sink = sqrt( (2/ρ)(W/S) sqrt(K/(3CD0)) )   [= 0.76× Vbest-glide]     (17.73)
```

(same `CL`/velocity form as min-power required, §17.2.2). Sailplane pilots fly min-sink speed while
climbing in lift, then accelerate to best-glide-ratio speed between thermals (guided by a
"variometer" instrument).

**Fig. 17.7 — Sailplane sink rate ("speed polar"/"hodograph")** *[Raymer, Fig. 17.7, p. 659]* — sink
rate vs velocity (0–100, units implied kt), curve marked with the min-sink-rate point (near the
knee) and the best-glide-ratio point (tangent line from origin, farther out on the velocity axis).
*(read from plot, generic/illustrative sailplane polar — no axis units printed in the scanned
figure)*:

| Feature | Approx. location on curve |
|---|---|
| Minimum sink rate | ~40% along velocity axis, near the curve's minimum |
| Best glide ratio (max L/D) | ~55–60% along velocity axis, tangent-from-origin point |

(Schematic teaching figure, not aircraft-specific — not usable as quantitative sizing input.)

### §17.5.2 Turning Gliding Flight

Banked glide [Raymer, Eq. (17.75), p. 658]:

```
L cosφ = W cosγ ≈ W                                                     (17.75)
```

Turn-rate/radius relations [Raymer, Eq. (17.76)–(17.79), p. 659]:

```
ψ̇ = a/V = V/R                                                           (17.76)
L sinφ = WV²/(gR) = W√(n²−1)                                            (17.78)
R = V²/(g tanφ) = V²/(g√(n²−1))                                          (17.79)
```

Sink rate and radius in a banked glide [Raymer, Eq. (17.80)–(17.81), p. 660]:

```
Vv,banked = Vv,straight / cos^(3/2)φ                                     (17.80)
R = 2W / (ρ S CL g sinφ)                                                 (17.81)
```
(Bank angle doesn't affect the optimum velocities for best-glide/min-sink since it's a
velocity-independent multiplier on Eq. 17.70.)

Wing-tip velocity variation in a slow turn — inner tip can stall first [Raymer, Eq. (17.82)–(17.83),
p. 660]:

```
Vouter = Vcg[1 + (b/2R)cosφ]                                            (17.82)
Vinner = Vcg[1 − (b/2R)cosφ]                                            (17.83)
```
*[Raymer, Fig. 17.8, p. 660]* — plan-view geometry of turn radius vs wing-tip velocity (inner/outer
radius, bank-shortened span `(b/2)cosφ`). No plotted data (geometry diagram). Normally corrected with
aileron, but near stall at even moderate bank this can trigger a one-wing stall → spin.

## §17.6 Energy-Maneuverability Methods

### §17.6.1 Energy Equations

Fighter combat exploits potential/kinetic energy exchange (e.g. the "high-speed yo-yo": pull up,
trade KE for PE and slow for a tighter turn, then roll/dive to trade PE back for speed). First
formalized analytically in [127]. Total energy, specific energy ("energy height" `he`), and specific
power [Raymer, Eq. (17.84)–(17.86), p. 661]:

```
E = W h + (1/2)(W/g) V²                                                 (17.84)
he = E/W = h + V²/(2g)                                                  (17.85)
(Ps)used = dhe/dt = dh/dt + (V/g)(dV/dt)                                 (17.86)
```

Excess-power source: excess thrust × velocity [Raymer, Eq. (17.87)–(17.88), p. 662]:

```
P = V(T−D)                                                              (17.87)
Ps = V(T−D)/W = dh/dt + (V/g)(dV/dt)                                    (17.88)
```

Expanded in load factor and aero coefficients [Raymer, Eq. (17.89), p. 662]:

```
Ps = V[ T/W − q CD0/(W/S) − n² K (W/S)/q ]                              (17.89)
```
(`T/W`, `W/S` at the *current* flight condition, not takeoff values.) `Ps` has climb-rate units; at
`n=1`, `Ps` = the rate of climb available if all excess power were used to climb at constant V.
`Ps=0` ⇒ T=D exactly (level, or trading climb for deceleration, or descent for acceleration). With
thrust axis not aligned to the flight path [Raymer, Eq. (17.90), p. 662]:

```
Ps = V{ T cos(α+φT)/W − qCD0/(W/S) − n²K[W − T sin(α+φT)]/(W q S) }      (17.90)
```

### §17.6.2 Ps Plots

Fighter design specs are commonly expressed as "must-meet" `Ps` points (e.g. `Ps=0` at n=5, Mach 0.9,
30,000 ft). **Fig. 17.9 — Ps vs Mach number and load factor** *[Raymer, Fig. 17.9, p. 663]* — `Ps`
(ft/s) vs Mach (0–2.2) for load factors n=1…7 (typical values, one altitude). *(read from plot, n=1
and n=5 curves)*:

| Mach | Ps, n=1 (ft/s) | Ps, n=5 (ft/s) |
|---|---|---|
| 0.4 | ~350 | ~ −100 |
| 0.8 | ~420 | ~50 |
| 0.9 | ~380 | ~0 |
| 1.0 | ~200 | ~ −150 |
| 1.2 | ~300 | ~ −50 |
| 1.6 | ~250 | ~ −150 |
| 2.0 | ~100 | ~ −300 |

(Illustrative "typical values" chart per caption, not a specific real aircraft.)

**Fig. 17.10 — Turn rate vs Ps** *[Raymer, Fig. 17.10, p. 663]*, at 30,000 ft / Mach 0.9, comparing an
"advanced dogfighter" curve and a "threat aircraft" curve, turn rate (0–25 deg/s) vs `Ps` (−1400 to
+600 ft/s). *(read from plot)*:

| Turn rate (deg/s) | Ps, advanced dogfighter (ft/s) | Ps, threat aircraft (ft/s) |
|---|---|---|
| 5 | ~500 | ~200 |
| 10 | ~200 | ~ −300 |
| 15 | ~ −200 | ~ −700 |
| 20 | ~ −600 | ~ −1100 |
| 25 | ~ −1100 | ~ −1400 |

A ≥2 deg/s turn-rate advantage at equal `Ps` is considered significant. **Fig. 17.11 — Ps=0
contours** *[Raymer, Fig. 17.11, p. 664]* — altitude (0–50 kft) vs Mach (0–2.0), families of curves
for n=1 (outermost/largest envelope) narrowing for higher n; winning aircraft should envelop the
opponent's contours (qualitative envelope comparison chart, values aircraft-specific — not digitized
beyond the trend). **Fig. 17.12 — Ps contours, constant load factor** *[Raymer, Fig. 17.12, p. 665]*
— altitude vs Mach, `Ps` iso-lines for n=5 (typical); the n=1 version is used for climb-rate/ceiling
and minimum-time-to-climb (below). No universal numeric table (aircraft-specific design chart).

### §17.6.3 Minimum Time-to-Climb Trajectory

`he` is purely geometric (Eq. 17.85), independent of any specific aircraft — e.g. Mach 0.9 at
30,000 ft ⇒ `he` = 42,447 ft for any aircraft. **Fig. 17.13 — Lines of constant energy height**
*[Raymer, Fig. 17.13, p. 665]* — altitude vs Mach (0–2.8), `he` contours labeled 10 through 160
(kft-equivalent). No aircraft-specific data (pure kinematic chart) — reproducible directly from
Eq. (17.85), not separately digitized.

Time-to-climb relation [Raymer, Eq. (17.91)–(17.92), p. 666]:

```
dt = dhe/Ps                                                             (17.91)
t = ∫ dhe/Ps                                                            (17.92)
```

Minimized when `Ps` is maximized at each `he` ⇒ optimal trajectory passes through points where the
1-g `Ps` contours (Fig. 17.12) are tangent to `he` contours (Fig. 17.13) — equivalently, for each `he`
contour, find the altitude giving max `Ps` along it. **Fig. 17.14 — Minimum time-to-climb trajectory,
high-thrust fighter** *[Raymer, Fig. 17.14, p. 666]* — superimposed `Ps`(n=1) and `he` contour
families, with the optimal-trajectory dots connecting tangent points; for a high-thrust fighter, the
optimum stays low and accelerates through transonic, then pitches up into a steep near-constant-q
climb (matches the historical F-15 Streak Eagle zoom-climb strategy). No further data extraction
(the trajectory is the qualitative takeaway, not a numeric table).

**Fig. 17.15 — Minimum time-to-climb, SST or low-thrust fighter** *[Raymer, Fig. 17.15, p. 667]* —
same construction for a lower-thrust design suffering a transonic "thrust pinch," producing separate
`Ps` "bubbles"; optimal trajectory must dive through Mach 1 along a constant-`he` line tangent to
equal-numerical-value `Ps` lines in both bubbles (matches the Concorde's historical practice of
diving through Mach 1 for efficiency, not capability reasons). No numeric table (qualitative
trajectory-construction figure); objective example shown: Mach 2.0 at 45,000 ft.

Actual climb time via numerical integration [Raymer, Eq. (17.93), p. 667]:

```
Δt(1→2) ≈ Δhe / (Ps)average                                             (17.93)
```
(time along constant-`he` legs is usually negligible for first-order analysis.)

### §17.6.4 Minimum Fuel-to-Climb Trajectory

Fuel-specific energy `fs` [Raymer, Eq. (17.94)–(17.96), p. 668]:

```
fs = dhe/dWf = (dhe/dt)/(dWf/dt) = Ps/(C T)                             (17.94)
Wf(1→2) = ∫ dhe / fs                                                    (17.95)
Wf(1→2) ≈ Δhe / (fs)average                                             (17.96)
```

Minimized fuel-to-climb passes through points where `fs` contours are tangent to `he` contours
(analogous construction to §17.6.3). **Fig. 17.16 — Minimum fuel to climb** *[Raymer, Fig. 17.16,
p. 668]* — altitude vs Mach, `fs` contour family plus a line of constant `dhe/dWf`; example objectives
Mach 0.9 at 45,000 ft (cruise) and Mach 2.0 at 45,000 ft (supersonic). No numeric table (same
qualitative-construction character as Fig. 17.15).

### §17.6.5 Energy Method for Mission-Segment Weight Fraction

Mission-segment weight fraction for a climb/acceleration (energy-height increase) [Raymer,
Eq. (17.97), p. 669]:

```
Wi/Wi-1 = exp[ −C Δhe / (V(1 − D/T)) ] = exp[ −C Δhe / (V{1 − 1/[(T/W)(L/D)]}) ]   (17.97)
```
(A *decrease* in `he` cannot literally refund fuel — a negative `Δhe` should not be plugged in.)

## §17.7 Operating Envelope

"Operating/flight envelope" = altitude-velocity combinations the aircraft is designed to attain and
withstand; "level-flight operating envelope" additionally requires steady level flight capability.

**Fig. 17.17 — Operating envelope (typical fighter)** *[Raymer, Fig. 17.17, p. 670]* — altitude
(0–60 kft) vs Mach (0–2.2), bounded by: `Ps=0` line (max thrust) defining the **absolute ceiling**
(highest `Ps=0` altitude); a slightly-lower `Ps=0` military-thrust line; the **service ceiling**
(some small positive `Ps` required — FAR: 100 fpm prop / 500 fpm jet; military spec: 100 fpm, 300 fpm
Navy); a **pilot ejection altitude limit** (~50,000 ft / 15,240 m, beyond which ejection survival
odds drop sharply without a pressure suit/capsule); an **engine relight limit** (low-q boundary where
air is too thin to restart/light the afterburner, from the engine manufacturer); and structural
limits — a max-`q` line (typical fighter limit 1800–2200 psf / 86–105 kN/m², transonic-at-sea-level)
and an inlet-duct max-pressure line (different slope than the `q` line) and a skin-temperature limit
(Chapter 14 chart). *(read from plot, qualitative envelope boundaries)*:

| Boundary | Approx. location |
|---|---|
| Absolute ceiling | ~55 kft, Ps=0 (max thrust), near Mach 1.6–2.0 |
| Service ceiling | ~52 kft |
| Pilot ejection limit | flat line at 50 kft |
| Engine relight limit | low-Mach, high-altitude corner cutoff |
| Max-q boundary | steep curve near sea level, Mach ~0.9–1.0 |
| Max speed | ~Mach 2.0–2.2 at mid altitude |

(A generic representative-fighter chart per the caption — not a specific type's numbers.) Dynamic
pressure and duct total-pressure relations [Raymer, Eq. (17.98)–(17.99), p. 670]:

```
q = (1/2) ρ∞ V∞² = 0.7 · Pstatic · M²                                     (17.98)
P_T0 = Pstatic · [1 + 0.2 M²]^3.5                                        (17.99)
```
(**Confirmed / corrected 2026-08-18** against a 300-dpi render of book p. 670. The exponent 3.5 in
Eq. 17.99 is correct as printed. The `0.7 Pstatic M²` form was misattached to Eq. 17.99; it is the
second equality of Eq. 17.98. Typical fighter `q` limit as printed: 1800–2200 psf {86–105 kN/m²}.)
(Duct total pressure = freestream total pressure × pressure recovery (Chapter 13); solved again for
static pressure at the duct-face Mach (~0.4–0.5) — can reach ~3× the outside dynamic pressure as
wall pressure.)

## §17.8 Takeoff Analysis

Chapter 5 gave the empirical takeoff-distance chart; this section breaks takeoff into segments for
more detailed analysis. **Fig. 17.18 — Takeoff analysis** *[Raymer, Fig. 17.18, p. 671]* — ground
roll (`SG`), rotation (`SR`), transition/circular-arc climb-in (`STR`), and climb-to-obstacle (`SC`)
segments; no plotted data (definition sketch).

### §17.8.1 Ground Roll

Acceleration [Raymer, Eq. (17.100), p. 672]:

```
a = (g/W)[T − D − μ(W−L)]
  = g{ (T/W − μ) + (ρ/(2W/S))[−CD0 − K CL² + μ CL] V² }                  (17.100)
```

**Table 17.1 — Ground Rolling Resistance** *[Raymer, Table 17.1, p. 672]*

(Column heading in the book: "μ — Typical Values", split into "Rolling (Brakes Off)" and "Brakes On".)

| Surface | μ Rolling (brakes off) | μ Brakes on |
|---|---|---|
| Dry concrete/asphalt | 0.03–0.05 | 0.3–0.5 |
| Wet concrete/asphalt | 0.05 | 0.15–0.3 |
| Icy concrete/asphalt | 0.02 | 0.06–0.10 |
| Hard turf | 0.05 | 0.4 |
| Firm dirt | 0.04 | 0.3 |
| Soft turf | 0.07 | 0.2 |
| Wet grass | 0.08 | 0.2 |

(Prose value on the same page: a typical μ for rolling resistance on a hard runway is 0.03.)

(**Corrected 2026-08-18** against a 300-dpi render of book p. 672. The printed table is fully legible.
Five of the seven rolling-resistance values were wrong — the previous version repeated 0.02 for all
three concrete/asphalt rows and swapped hard turf with firm dirt — and the four turf/dirt braking
values were left blank when the book prints 0.4, 0.3, 0.2, 0.2.)

Ground-roll integration trick (integrate w.r.t. `V²`) [Raymer, Eq. (17.101), p. 672]:

```
SG = ∫(V/a) dV = ∫(1/(2a)) d(V²)                                        (17.101)
```

Takeoff speed ≥ 1.1× stall speed (flaps in takeoff position; landing-gear geometry can cap usable
α/`CL`). Closed-form ground-roll integral [Raymer, Eq. (17.102)–(17.104), p. 673]:

```
SG = (1/(2g)) ∫_Vi^Vf d(V²)/(KT + KA V²)
   = (1/(2gKA)) · ln[ (KT + KA Vf²) / (KT + KA Vi²) ]                    (17.102)
KT = (T/W) − μ                                                          (17.103)
KA = (ρ/(2(W/S)))(μ CL − CD0 − K CL²)                                    (17.104)
```

Average thrust used = thrust at ~70% (1/√2) of `VTO` (since integration is w.r.t. `V²`); for accuracy,
break into shorter segments each with its own 70%-point average thrust; `K` can be reduced for ground
effect (Chapter 12). Rotation time ≈ 3 s for large aircraft (`SR ≈ 3·VTO`) or ≈1 s for small aircraft
(`SR ≈ VTO`), acceleration assumed negligible over that interval.

### §17.8.2 Transition

Approximated as a circular arc; average velocity ≈1.15 `Vstall` (from 1.1→1.2 `Vstall`); average `CL`
≈ 0.9 `CLmax`(takeoff flaps). Load factor during transition [Raymer, Eq. (17.105)–(17.107), p. 674]:

```
n = [(1/2)ρS(0.9 CLmax)(1.15 Vstall)²] / [(1/2)ρS CLmax Vstall²] = 1.2   (17.105)
n = 1.0 + V_TR²/(Rg) = 1.2                                              (17.106)
R = V_TR² / (g(n−1)) = V_TR²/(0.2g)                                     (17.107)
```

Climb angle, horizontal transition distance, altitude gained [Raymer, Eq. (17.108)–(17.110), p. 674]:

```
sinγclimb = (T−D)/W ≈ (T/W) − 1/(L/D)                                   (17.108)
STR = R sinγclimb ≈ R[(T/W) − 1/(L/D)]                                  (17.109)
hTR = R(1 − cosγclimb)                                                  (17.110)
```

If the obstacle is cleared before transition ends [Raymer, Eq. (17.111), p. 674] (uses obstacle
height directly in an `R`-based geometric relation rather than Eq. 17.110).

### §17.8.3 Climb

Horizontal distance during the climb-to-obstacle segment [Raymer, Eq. (17.112), p. 674]:

```
SC = (hobstacle − hTR) / tanγclimb                                      (17.112)
```
(35 ft / 10.7 m obstacle for commercial, 50 ft / 15.24 m for military/small civil; `SC=0` if the
obstacle was cleared during transition.)

### §17.8.4 Balanced Field Length

Total takeoff distance (with obstacle clearance) assuming an engine failure at decision speed `V1`
(brake-vs-continue distances equal). Detailed method [40] [Raymer, Eq. (17.113)–(17.115), p. 675]:

```
BFL = 0.863/(1+2.3G) · [ (W/S)/(ρ g CLclimb) + hobstacle ]
      · [ 1/(Tav/W − U) + 2.7 ] + ( 655 / √(ρ/ρSL) )                     (17.113)

Jet:   Tav = 0.75 Ttakeoff,static · [(5+BPR)/(4+BPR)]                    (17.114)
Prop:  Tav = 5.75 · bhp · [ (ρ/ρSL) Ne Dp² / bhp ]^(1/3)                 (17.115)
```
(**Corrected 2026-08-18** against a 300-dpi render of book p. 675. Eq. 17.115's coefficient is
**5.75, not 375**; it has no propeller-efficiency factor `ηp`, and the density ratio `ρ/ρSL` sits
inside the cube-root bracket. In Eq. 17.113 the thrust-to-weight in the second bracket is `Tav/W`,
not `T/W`, and the first bracket's denominator is `ρ g CLclimb` (ρ, not σ).)
where `BFL` = balanced field length (ft); `G = γclimb − γmin` (`γmin` = 0.024/0.027/0.030 for
2/3/4-engine, one engine out); `γclimb = sin⁻¹[(T−D)/W]` at climb speed (1.2`Vstall`), one engine
out; `CLclimb` = `CL` at climb speed; `hobstacle` = 35/50 ft; `U = 0.01 CLmax + 0.02` (takeoff-flap
position); `BPR` = bypass ratio; `bhp`, `Ne`, `Dp` = engine brake HP, engine count, prop diameter.

More accurate: integrate takeoff roll with engine failure assumed at a trial `V1`, compare with a
braking-distance analysis at that `V1` (§17.9), iterating `V1` until continue-distance
(+35 ft obstacle) = brake-to-stop distance. Assume 1 s pilot recognition delay before braking; no
reverse thrust credit allowed for BFL. Takeoff speed for BFL minimization may run 20–40% above
minimum takeoff speed (to keep positive one-engine-out climb capability, avoiding the high
drag-due-to-lift near minimum speed). FAR 25 aircraft must also meet the worse of BFL or 115% of the
all-engines-operating obstacle-clearance distance ("FAR takeoff field length"); FAR 23 aircraft are
exempt from this double check.

## §17.9 Landing Analysis

**Fig. 17.19 — Landing analysis** *[Raymer, Fig. 17.19, p. 676]* — approach (`Sa`), flare (`SF`),
free-roll, and braking-roll segments, mirroring the takeoff breakdown; no plotted data. Landing
weight (design-specified, ranges from takeoff weight to ~85% of it — not end-of-mission weight, since
an emergency-return landing can't require fuel-dumping first).

### §17.9.1 Approach

Obstacle clearance over 50 ft (15.24 m); approach speed `Va` = 1.3`Vstall` (1.2`Vstall` military).
Steepest approach angle from Eq. (17.108) with idle thrust, full flaps. Commercial approach angle
≤3° (0.052 rad, may need more than idle thrust). Approach distance via Eq. (17.112) using flare
height `hf`.

### §17.9.2 Flare

Reverse of takeoff transition (circular arc); touchdown speed `VTD` = 1.15`Vstall` (1.1`Vstall`
military); average flare velocity = 1.23`Vstall` (1.15`Vstall` military); flare-arc radius via
Eq. (17.107) with this average velocity and `n=1.2`; flare height/horizontal distance via
Eqs. (17.110)/(17.109). Deceleration energy during flare is neglected (pilot typically pulls all
remaining approach power at flare initiation).

### §17.9.3 Ground Roll

Free-roll distance = `VTD` × assumed delay (1–3 s) before braking. Braking distance uses the same
Eq. (17.102) form, `Vi=VTD`, `Vf=0`, thrust term = idle thrust (or reverse thrust if equipped — jets:
≈ −40 to −50% of max forward thrust above the reverser "cutoff speed" ≈ 50 kt / 85 ft/s / 93 km/h,
requiring the roll to be split into two Eq.-(17.102) segments at the cutoff-speed boundary; not
creditable toward FAA certification distances, though used operationally; props: reversible-prop
reverse thrust ≈40% static forward thrust (60% for turboprops), usable throughout). Drag term can
include spoilers/speed-brakes/drogue chute (chute `CD` ≈ 1.4 × inflated frontal area / `Sref`).
Braking `μ` ≈ 0.5 (civil) / 0.3 (military) on hard runway (Table 17.1 for other surfaces). FAA
requires ×1.666 on the total (approach+flare+ground-roll) distance for commercial "FAR field length"
(pilot-technique margin).

### §17.9.4 Effect of Wind on Takeoff & Landing

Rough approximation: for each segment, compute the square-root-averaged velocity (0.29×initial +
0.71×final), then scale that segment's distance by `V̄/(V̄ + Vwind)`. A full time-domain 3-DOF sim is
recommended for accuracy. (Downwind takeoff/landing dramatically increases all distances — avoid.)

### §17.9.5 Unpowered Landings

Airliner-type approach uses moderate power to hold ≤3° approach angle; zero-thrust/high-drag descent
(engine flameout, sailplane, reentry-vehicle-like configurations) can force a very steep approach —
risking running out of airspeed before touchdown during the flare (must hold a safe sink rate for
5–15 s while the gear "finds the ground," decelerating all the while with no thrust and high drag).
Fix requires improving `L/D` (bigger wing, higher AR, longer fuselage fineness) — diving to build
speed first doesn't help, since it only steepens the approach angle further.

## §17.10 Other Fighter Performance Measures of Merit

Standard metrics (turn rate, corner speed, load factor, `Ps`) miss important discriminators: (1) they
address steady-state ability, not the continuous-state-change character of real dogfights (yo-yo:
pitch up, roll+turn near corner speed, roll near-inverted, pitch, roll out, dive — often pitching and
rolling simultaneously, "yank and bank"); (2) they're oriented around the classical tail-chase gun
attack, whereas modern missiles reward whoever points its nose first (or, with off-boresight seekers,
maybe not even that) — though missiles are few/expensive, so classical dogfight ability still
matters, traded off in the F-35 against sensor/missile capability; (3) they miss **decoupled energy
management** (independently changing KE/PE, e.g. rapid deceleration via speed brakes/reverse thrust
without gaining altitude, vs. the "coupled" yo-yo style that trades one for the other predictably).

**Fig. 17.20 — Energy management envelope** *[Raymer, Fig. 17.20, p. 680]* — max and min (most
negative) attainable `Ps` plotted vs turn rate, with labeled extremes "maximum drag" and "in-flight
reverse thrust" at high negative-`Ps` and a "`CLmax` at stall" boundary; illustrates that a
poststall-controllable aircraft can generate large drag to force an opponent's overshoot. No
numeric data (concept-envelope schematic, aircraft-nonspecific).

**Fig. 17.21 — Loaded roll comparison** *[Raymer, Fig. 17.21, p. 681]* — roll rate vs α (or load
factor), four qualitative curves: "ideal" (no roll-rate loss), "aircraft A – good," "aircraft B –
poor," "aircraft C – bad (roll reversal, goes negative)." No plotted numeric data (illustrates
aeroelastic/adverse-yaw/aileron-separation roll-rate loss at high α — see Chapter 16 §16.6 aileron
reversal). [129] catalogs further alternative fighter metrics.

### §17.10.1 Supermaneuver and Poststall Maneuver

Poststall maneuver (PSM) / "supermaneuver" (proven on the X-31, and the YF-22's 60°-α demo) lets a
fighter point its nose faster via thrust-induced + dynamic turning at high α. A rocket in vacuum
turns only by thrusting perpendicular to the flight path; turn rate = `gn/V` with `n` = perpendicular
thrust component / weight — formally goes to infinity as `V→0` (limited practically by pitch-rate
capability). *[Raymer, Fig. 17.22, p. 682]* — "no-gravity" turn-rate-vs-velocity curve from pure
thrust-induced turning; schematic, no numeric data.

Three ways to get thrust ⟂ flight path for an aircraft:
1. **Thrust-vectoring near the c.g.** (Harrier; proposed RIVET VSTOL concept [130]) — turn-rate
   contributions from wing lift and vectored thrust simply add; wing held at `CLmax` α while nozzles
   point ~⟂ flight path (per Eq. 17.58). *[Raymer, Fig. 17.23, p. 682]* — turn-rate-vs-velocity with
   the wing-stall boundary now extending to zero velocity (ignoring gravity, momentary 90°-bank
   maneuver) — schematic, no numeric data.
2. **Aft-nozzle vectoring + canard** (F-22-style aft nozzles alone create an unbalanceable nose-down
   moment; adding a large canard, as on the F-15 STOL/Maneuver demonstrator and an early Lockheed JSF
   concept, balances it) — retains full wing-lift turning plus vectored-thrust turning down to
   canard-stall speed. *[Raymer, Fig. 17.24, p. 683]* — schematic, no numeric data.
3. **Fuselage pointing / poststall** (X-31): α well past stall; wing lift is only a fraction of max,
   but low-speed jet thrust alone still gives high turn rate. Piloting is disorienting (flight
   direction is "through the floorboards," roll about the velocity vector looks like yaw) and drag is
   very high (rapid deceleration risk, toward zero velocity if mismanaged). *[Raymer, Fig. 17.25,
   p. 684]* — schematic, no numeric data.

**Fig. 17.26 — X-31 Supermaneuver** *[Raymer, Fig. 17.26, p. 684]* — combined maneuver: pitch up and
bleed speed while initiating the turn, then at the top use engine thrust to rapidly rotate the
velocity vector ~90° relative to the target while rolling the aircraft ~90° about the velocity vector
(perceived by the pilot as a 90° yaw, due to high α) — nose ends up pointed at the target even before
the velocity vector is, enabling an early shot before accelerating back out of the high-α condition.
No plotted numeric data (maneuver-sequence schematic).

The **"dynamic turn"** metric: at corner speed the aircraft is already at stall α; a controllable-
poststall aircraft (X-31-like) can briefly pull the nose *past* stall α for a shot opportunity, then
recover — [131] gives the detailed turn-rate-plot relationship.

*Photo: F-14 arrested landing (U.S. Navy photo), p. 685 — no plotted data.*

## What We've Learned

Level flight, climb, glide, turn, takeoff, and landing calculations verify the aircraft meets customer
performance requirements, and later serve as constraints for aircraft optimization.

---

*Chapter 17 complete (§§17.1–17.10, Table 17.1, Figs 17.1–17.26, Eqs 17.1–17.115). Several figures
(17.2, 17.6, 17.7, 17.9–17.17, 17.20–17.26) are schematic/illustrative "typical values" or pure
kinematic-construction charts rather than aircraft-specific numeric design data; these were digitized
only where the source explicitly labeled sample data, and flagged qualitative otherwise.*

*Correctness sweep, 2026-08-18: book pages 644, 645, 670, 672, 673 and 675 were re-rendered at 300 dpi
and read as images, and the chapter's true section structure was taken from the printed table of
contents (book pp. xiv–xv). All `[verify]` markers in this chapter are now resolved. Corrections
applied: Eq. 17.25 (inner radical was inverted — it is `sqrt(3K/CD0)`), Eq. 17.26 (was missing),
Eq. 17.27 (is a drag, not a drag coefficient), Eq. 17.98/17.99 (the `0.7·Pstatic·M²` form belongs to
17.98, and the 3.5 exponent in 17.99 is confirmed), Eq. 17.102 (general Vi→Vf form), Eq. 17.113
(`Tav/W`, and `ρ` not `σ`), Eq. 17.115 (coefficient is **5.75, not 375**; no `ηp`; density ratio inside
the bracket), and Table 17.1 (five of seven rolling values wrong; four braking values were blank).*

***Section-numbering correction (systematic).** The extract originally used its own outline, which
promoted "Range" and "Loiter Endurance" to top-level sections §17.3 and §17.4 and thereby shifted
every later section by +2 (e.g. Takeoff Analysis was cited as §17.10). The book's contents pages give
§17.1 Introduction and Equations of Motion (637), §17.2 Steady Level Flight (639), §17.3 Steady
Climbing and Descending Flight (649), §17.4 Level Turning Flight (653), §17.5 Gliding Flight (657),
§17.6 Energy-Maneuverability Methods (661), §17.7 Operating Envelope (669), §17.8 Takeoff Analysis
(671), §17.9 Landing Analysis (676), §17.10 Other Fighter Performance Measures of Merit (679). Range
and Loiter are subsections §17.2.4–§17.2.11, confirmed against the printed headings on book pp. 643–
648 ("17.2.5 Range Optimization—Jet" is printed on p. 644, "17.8.1 Ground Roll" on p. 672). All
headings and cross-references in this file were renumbered to the book's scheme.*

*Next: Chapter 18 — Cost Analysis.*
