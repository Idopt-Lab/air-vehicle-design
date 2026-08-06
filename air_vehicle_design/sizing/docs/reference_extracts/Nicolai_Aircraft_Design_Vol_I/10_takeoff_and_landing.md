# Chapter 10 — Takeoff and Landing Analysis

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 10 "Takeoff and Landing Analysis," printed pp. 255–284.

Text-layer inventory (to confirm completeness): Figs 10.1–10.15 (incl. 10.2a/10.2b), Tables
10.1–10.7, Eqs (10.1)–(10.13) (incl. 10.4a/10.4b).

---

## §10.1 Introduction
*[Nicolai & Carichner, p. 256]*

This chapter considers aircraft takeoff/landing performance in detail (Chapter 6 §6.3 and Chapter 9
addressed this in general terms with initial estimates only). Assumes the design is defined in fair
detail. Ground rules: MIL-C-5011A [1] for military aircraft, FAR Parts 23 and 25 [2] for civil/
commercial aircraft; U.S. Navy uses AS-5263 [3] instead of MIL-C-5011. Definitions for conventional
takeoff and landing (CTOL):

- `V_stall = V_S` = 1g stall speed out of ground effect (aka minimum flight speed or control speed,
  `V_min`) [Eq. (6.1)]
- `V_TO` = takeoff or liftoff speed
- `V_CL` = climb-out speed during takeoff
- `V_EF` = one-engine-failure speed
- `V_1` = decision speed (continue or brake)
- `V_R` = rotation speed (speed at which aircraft is rotated during ground run)
- `V_OBS` = speed over the obstacle (obstacle height = 50 ft military, 35 ft FAA commercial) for
  takeoff
- `V_50` = speed over 50-ft obstacle during landing
- `V_TD` = speed at touchdown during landing
- `V_app` = approach speed for carrier aircraft (120 kt from [3])

Summary of CTOL ground rules for military/civil aircraft: Tables 10.1 and 10.2 (all speeds are
minimum speeds). Takeoff/landing analyses (§10.3, §10.4) assume realistic speeds compatible with
these minimums. No satisfactory military/civilian ground rules for STOL aircraft exist at present
(MIL-F-83300 addresses STOL flying qualities but is under revision, only alluding to STOL
takeoff/landing ground rules); [4,5] recommend realistic STOL ground rules. §10.3/§10.4 analyses
are appropriate for STOL performance with consideration given to realistic speed ground rules and
STOL-peculiar features (e.g., dirt-strip operation giving rolling `μ = 0.04` and braking `μ = 0.30`).

### Table 10.1 — Summary of CTOL Takeoff Rules
*[Nicolai & Carichner, Table 10.1, p. 257]*

| Item | MIL-C-5011C (Military) | FAR Part 23 (Civil) | FAR Part 25 (Commercial) |
|---|---|---|---|
| Speeds | V_TO ≥ 1.1 V_S, V_CL ≥ 1.2 V_S | V_TO ≥ 1.1 V_S, V_CL ≥ 1.1 V_S | V_TO ≥ 1.1 V_S, V_CL ≥ 1.2 V_S |
| Climb gradient | Gear up: 500 fpm at SL (AEO), 100 fpm at SL (OEI) | Gear up: 300 fpm at SL (AEO) | Gear up: 3% at V_CL (OEI); Gear down: 0.5% at V_TO |
| Rolling coefficient | μ = 0.025 | Not specified | Not specified |
| Field-length definition | Takeoff distance over 50 ft | Takeoff distance over 50 ft | 115% of takeoff distance over 35 ft *or* critical field length (§10.6) |

*SL = sea level; AEO = all engines operating; OEI = one engine inoperative.*

## §10.2 Ground Effects
*[Nicolai & Carichner, p. 257]*

As the aircraft flies close to the ground, the ground interferes with the horseshoe vortex system
trailing behind the wing (§2.3, Fig. 10.1). Analyzed by placing an **image horseshoe vortex**
system of equal but opposite strength at the same distance `h` below the ground that the wing is
above. This image system cancels the wing's induced velocities normal to the ground surface (the
necessary boundary condition) and induces velocities at the wing aerodynamic center that decrease
downwash strength there, decreasing induced angle of attack `α_i`. Thus wing `C_L` increases (more
correctly, lift-curve slope increases, giving higher `C_L` at the same geometric `α`), and induced
drag decreases. This ground-effect influence is a function of aircraft height above ground and wing
size.

### Table 10.2 — Summary of CTOL Landing Rules
*[Nicolai & Carichner, Table 10.2, p. 257]*

| Item | MIL-C-5011C | FAR Part 23 | FAR Part 25 |
|---|---|---|---|
| Speeds | V_OBS ≥ 1.2 V_S, V_TD ≥ 1.1 V_S | V_OBS ≥ 1.3 V_S, V_TD ≥ 1.15 V_S | V_OBS ≥ 1.3 V_S, V_TD ≥ 1.15 V_S |
| Braking coefficient | 0.30 | Not specified | Not specified |
| Field-length definition | Landing distance over 50 ft | Landing distance over 50 ft | Landing distance over 50 ft divided by 0.6 |

### Fig 10.1 — B-767 generates a strong trailing vortex system during a landing approach
*[Nicolai & Carichner, Fig. 10.1, p. 258]* (courtesy of Ray Nicolai) — Photograph, B-767 on
approach, visible condensation trails showing wingtip trailing vortices interacting with humid air
over buildings below. No plotted data (photograph).

The ground's proximity effect can be thought of as increasing the wing's geometric aspect ratio
(AR) to an effective aspect ratio `AR_eff`. Fig. 10.2a shows `AR/AR_eff` vs nondimensional wing
height parameter `h/b` (`h` = wing height above ground, `b` = wing span); used to obtain `AR_eff`,
which feeds into Eq. (2.13) (Chapter 2) for the in-ground-effect wing lift-curve slope.

Fig. 10.2b shows ground-effect influence on an AR=4 wing, using `h/c̄` (c̄ = wing mean aerodynamic
chord); `h/c̄ = ∞` means out of ground effect (free air). Wing lift-curve slope increases as the
ground is approached, and `α_0L` becomes less negative. Approaching the ground decreases the effect
of camber: camber increases circulation about the airfoil, introducing upward-curving streamlines
ahead of the airfoil (upwash); ground proximity straightens these streamlines (image vortex system
decreases upwash), decreasing the magnitude of `α_0L`. `C_L` at `α=0` is approximately the same for
all `h/c̄` values — useful when constructing a curve like Fig. 10.2b to determine ground `C_L`
during takeoff/landing analysis.

### Fig 10.2 — Influence of ground effects on (a) effective aspect ratio and (b) an AR=4 wing
*[Nicolai & Carichner, Fig. 10.2, p. 259]* (data from [7])

**(a)** `AR/AR_eff` vs `2h/b` (0–2.0), single curve rising from ~0.22 at 0 to ~1.0 asymptotically by
`2h/b≈1.8`. Inset photo: fighter jet on ramp. *(read from plot)*:

| 2h/b | AR/AR_eff |
|---|---|
| 0 | 0.22 |
| 0.4 | 0.65 |
| 0.8 | 0.85 |
| 1.2 | 0.94 |
| 1.6 | 0.98 |
| 2.0 | 1.0 |

**(b)** `C_L` vs Angle of Attack `α` (deg, -8 to 16), five curves by `h/c̄` = 0.042, 0.083, 0.167,
1.00, ∞ — all converge near `α≈0, C_L≈0.72`, fanning out with steeper slope (higher lift-curve
slope) for smaller `h/c̄`. *(read from plot, endpoints)*:

| h/c̄ | α at C_L=0 (approx, deg) | Slope (relative) |
|---|---|---|
| 0.042 | -2.2 | steepest |
| 0.083 | -3.0 | steep |
| 0.167 | -4.0 | moderate |
| 1.00 | -5.5 | shallow |
| ∞ | -7.5 | shallowest (free air) |

As the wing approaches the ground, induced drag decreases but zero-lift drag is essentially
unchanged. Reduction in induced drag in ground effect (from [6], unlabeled equation, p. 259):
```
ΔC_Di = -σ·C_L² / (π·AR)
```
where `σ` = ground influence coefficient. At `h/b` between 0.033 and 0.25, `σ` can be estimated
from (unlabeled equation, p. 260):
```
σ = (1 - 1.32·h/b) / (1.05 + 7.4·h/b)
```

## §10.3 Takeoff Analysis
*[Nicolai & Carichner, p. 260]*

Takeoff = distance required to accelerate from `V=0` to takeoff speed and climb over a 35- or
50-ft obstacle (Fig. 10.3). Takeoff distance = sum of ground distance (`S_G`), rotation distance
(`S_R`), transition distance (`S_TR`), and climb distance (`S_CL`). Aircraft accelerates to
`V_TO = 1.2·V_stall`, rotates to an angle of attack such that `C_L = 0.8·C_Lmax`, leaves the ground,
and transitions from horizontal to climbing flight over `S_TR`.

### §10.3.1 Ground Distance S_G
*[Nicolai & Carichner, p. 260]*

**Eq (10.1)** *[Nicolai & Carichner, Eq. (10.1), p. 260]*:
```
S_G = ∫₀^(V_TO) (V dV/a) = (1/2)∫₀^(V_TO) (dV²/a)
```
where `a` = acceleration during `S_G`, and:

**Eq (10.2)** *[Nicolai & Carichner, Eq. (10.2), p. 260]*:
```
V_TO = 1.2·V_stall = 1.2·sqrt[(W_TO/S_ref)·(2/(ρ·C_Lmax))]
```

### Fig 10.3 — Schematic of an aircraft takeoff analysis
*[Nicolai & Carichner, Fig. 10.3, p. 260]* — Side-view schematic: ground run from `V=0` through
`V_R`, `V_TO`, rotation, transition arc (radius `R`) into climb at angle `θ_CL` to clear an obstacle
(height 35 ft commercial / 50 ft military), reaching `V_CL`. Segments labeled `S_G`, `S_R`, `S_TR`,
`S_CL` along the bottom. No plotted numeric data (schematic).

`C_Lmax` is for a particular flap setting, determined using Chapter 9 methods. From the force
diagram (Fig. 10.4):

**Eq (10.3)** *[Nicolai & Carichner, Eq. (10.3), p. 261]*:
```
a = (g/W)·[T - D - F_f] = (g/W)·[T - D - μ·(W_TO - L)]
```
where `μ` = coefficient of friction, brakes off (Table 10.3). Lift and drag during ground run
(unlabeled equations, p. 261):
```
D = 0.5·ρ·V²·S_ref·[C_D0 + ΔC_Dflap + ΔC_Dgear + K·C_LG²]
L = 0.5·ρ·V²·S_ref·C_LG
```
where `C_LG` = lift coefficient during ground run for a particular flap setting (Fig. 9.22, Chapter
9). There is a difference in the `C_L` vs `α` curve [continues next page].

### Fig 10.4 — Force diagram during ground run
*[Nicolai & Carichner, Fig. 10.4, p. 261]* — Side-view aircraft schematic (stealth-fighter-style
silhouette) with force vectors: Lift (up), Weight (down), Thrust (forward), Drag (aft), and
`F_friction` at each landing-gear contact point (forward-pointing, opposing motion). No plotted
data (free-body diagram).

### Table 10.3 — Coefficients of Friction for Various Takeoff and Landing Surfaces
*[Nicolai & Carichner, Table 10.3, p. 261]*

| Type of Surface | Brakes Off, Avg Ground Resistance Coeff. | Brakes Fully Applied, Avg Wheel-Braking Coeff. |
|---|---|---|
| Concrete or macadam | 0.015–0.04 | 0.3–0.6 |
| Hard turf | 0.05 | 0.4 |
| Firm and dry dirt | 0.04 | 0.30 |
| Soft turf | 0.07 | 0.5 |
| Wet concrete | 0.05 | 0.2 |
| Wet grass | 0.10 | 0.2 |
| Snow- or ice-covered field | 0.01 | 0.07–0.10 |

There's a difference in the `C_L` vs `α` curve for an aircraft in ground effect (IGE) vs out of
ground effect (OGE) — slight, ignored for now but discussed in §10.7 for the L-1011. `ΔC_Dflap`
determined from Fig. 9.25 data; `ΔC_Dgear` from Fig. 10.5.

The landing gear drag coefficient `ΔC_Dgear` is difficult to determine — depends on flap setting,
aircraft `C_L`, and sometimes spoilers; a nightmare in CFD, seldom attempted. Wind tunnel testing
usually underestimates `ΔC_Dgear` because full-scale gear detail often isn't known yet and is
expensive to model. Landing gear drag determination is usually delayed until flight testing, and
then it's low priority (gear already built, aircraft flying). Fig. 10.5 and Table 10.4 present
current-aircraft landing gear drag coefficients — use carefully given this discussion.

Landing gear is designed to be functional, reliable, and lightweight — **not low drag** (most gear
retracts for up-and-away flight; if not retracted, streamlined via strut shaping and wheel fairings/
"wheel pants"). During landing/takeoff the gear is extended and drag must be accounted for — during
takeoff, gear drag is a nuisance (reduces acceleration to `V_TO`); during landing, gear drag is
useful (shortens air distance, helps braking deceleration).

### Fig 10.5 — Drag of landing gear
*[Nicolai & Carichner, Fig. 10.5, p. 262]* — `ΔC_Dgear` vs Trailing Edge Flap Deflection (deg,
0–50), three shaded bands: "Large Transports" (highest, ~0.02–0.03), "Medium/Small Transports"
(middle, ~0.012–0.021, "without wheel fairings"), "General Aviation" (lowest, ~0.006–0.017, "with
wheel fairings"). Individual aircraft data points overlaid: B-747, C-5A, L-1011, B-52G, C-141A,
Gulfstream I, Cardinal RG, Cessna 172/177. *(read from plot, approximate values at δf=0°)*:

| Aircraft | ΔC_Dgear at δf=0° |
|---|---|
| L-1011 | 0.029 |
| B-747 | 0.028 |
| C-5A | 0.026 |
| B-52G | 0.021 |
| C-141A | 0.014 |
| Gulfstream I | 0.014 |
| Cardinal RG | 0.010 |
| Cessna 172/177 | 0.006 |

### Table 10.4 — Landing Gear Drag Coefficients
*[Nicolai & Carichner, Table 10.4, p. 263]*

**Fighters:**

| Aircraft | Ref. Area (ft²) | ΔC_Dgear | Landing Gear Configuration |
|---|---|---|---|
| A-7 | 375 | 0.028 | Two-wheel NLG, two one-wheel MLG |
| F-104 | 196 | 0.035 | One-wheel NLG, two one-wheel MLG |
| F-16A/B | 300 | 0.0325 | One-wheel NLG, two one-wheel MLG |
| F-22 | 840 | 0.014 | One-wheel NLG, two one-wheel MLG |
| U-2S | 1000 | 0.0045 | One dual-wheel MLG, large tail wheel, two wingtip pogos |

*Note: F-16A/B row (`ΔC_Dgear = 0.0325`, ref. area 300 ft²) is directly relevant to this repo's
F-16A Brandt baseline — useful as an independent cross-check for gear-drag assumptions against
`F16Baseline()`.*

**Large transports:**

| Aircraft | Ref. Area (ft²) | ΔC_Dgear | Landing Gear Configuration |
|---|---|---|---|
| L-1011 | 3456 | 0.028–0.0205 | Two-wheel NLG, two four-wheel trucks MLG |
| C-5A | 6200 | 0.0257–0.021 | Four-wheel NLG, four four-wheel trucks MLG |
| B-747 | 5500 | 0.028–0.014 | Two-wheel NLG, four four-wheel trucks MLG |
| B-52G | 4000 | 0.024–0.0155 | Quadricycle with wingtip gear, four dual-wheel MLG |

**Medium transports:**

| Aircraft | Ref. Area (ft²) | ΔC_Dgear | Landing Gear Configuration |
|---|---|---|---|
| P-3 | 1300 | 0.020 | Two-wheel NLG, two two-wheel MLG |
| L-1049 Connie | 1650 | 0.024 | Two-wheel NLG, two two-wheel MLG |
| B 727 | 1650 | 0.017 | Two-wheel NLG, two two-wheel MLG |
| DC-8 | 2771 | 0.012 | Two-wheel NLG, two four-wheel trucks MLG |
| C-141A | 3228 | 0.0165–0.012 | Two-wheel NLG, two four-wheel trucks MLG |

**Small transports:**

| Aircraft | Ref. Area (ft²) | ΔC_Dgear | Landing Gear Configuration |
|---|---|---|---|
| S-3A | 598 | 0.023 | Two-wheel NLG, two one-wheel MLG |
| Gulfstream I | 615 | 0.015 | Two-wheel NLG, two one-wheel MLG |
| Fokker F-27 | 754 | 0.024 | One-wheel NLG, two dual-wheel MLG |

**General aviation:**

| Aircraft | Ref. Area (ft²) | ΔC_Dgear | Landing Gear Configuration |
|---|---|---|---|
| Cessna 172 | 226 | 0.006 (fixed gear w/ fairings) | One-wheel NLG, two one-wheel MLG |
| Cessna 177 | 174 | 0.006 (fixed gear w/ fairings) | One-wheel NLG, two one-wheel MLG |
| Cardinal RG | 174 | 0.011 | One-wheel NLG, two one-wheel MLG |

*Abbreviations: NLG = nose landing gear; MLG = main landing gear.*

Data in Fig. 10.5 and Table 10.4 reveal several interesting things. First, the drag coefficient due
to the landing gear is huge: equal to or greater than the `C_Dmin` of the entire aircraft in most
cases. Second, `ΔC_Dgear` decreases as flaps are deflected — flap deflection increases circulation
about the wing, and the landing gear beneath the wing sits in a lower dynamic-pressure field than
the rest of the aircraft. More prevalent on transport aircraft (more sophisticated flap systems,
higher max `C_L`, Fig. 9.7). Fighters and GA aircraft have simpler flap systems, lower max `C_L`,
and fairly constant `ΔC_Dgear`. Fixed GA gear is a simple strut-and-wheel (with wheel pants)
arrangement referenced to a large wing area (low W/S), giving relatively low `ΔC_Dgear`. Fighters
have beefy retractable gear and small wing area (high W/S), giving relatively large `ΔC_Dgear`.

Designer should pick `ΔC_Dgear` from Fig. 10.5 or Table 10.4 for their aircraft class, for the
ground `C_D` build-up. Flaps usually retracted during the braking ground run (landing) and set to
takeoff position for the accelerating ground run (takeoff).

Several ways to calculate `S_G`:

1. Approximate the integral, Eq. (10.1).
2. Assume acceleration `a` is constant, equal to the value at `V = 0.707·V_TO`. Solve Eq. (10.3)
   for `a` at that speed, then:

**Eq (10.4a)** *[Nicolai & Carichner, Eq. (10.4a), p. 264]*:
```
S_G = (1/2)·V_TO² / a_(at 0.707·V_TO)
```

3. Stepwise integration of Eq. (10.1): calculate `a` for `V = 0, 20, 40, ..., V_TO`, plot `1/(2a)`
   vs `V²` (Fig. 10.6); `S_G` = area under the curve. Putting Eq. (10.2) into Eq. (10.4a) gives:

**Eq (10.4b)** *[Nicolai & Carichner, Eq. (10.4b), p. 265]*:
```
S_G = 1.44·(W/S_ref)_TO / {g·ρ·C_Lmax·[(T/W) - (D/W) - μ·(1 - L/W)]}
```
where lift, drag, and thrust terms are evaluated at `V = 0.707·V_TO`.

### Fig 10.6 — Stepwise integration for ground roll distance S_G
*[Nicolai & Carichner, Fig. 10.6, p. 264]* — `1/(2a)` vs `V²`, single monotonically increasing
curve from `V=0` to `V_TO²`, shaded area under the curve labeled "Area Under Curve Is S_G". No
plotted numeric data (construction schematic).

From Eq. (10.4b), several factors the designer can influence to vary takeoff ground run: takeoff
wing loading `(W/S)_TO`, takeoff thrust-to-weight ratio `(T/W)`, retardation force-to-weight ratio
`(D+F_f)/W`, and max wing lift coefficient.

Low `(W/S)_TO` shortens `S_G` but causes poor riding qualities (sensitive gust response), less
efficient cruise, poor acceleration — acceptable only when other performance requirements are lower
priority. High thrust-to-weight ratio shortens takeoff roll, but engines shouldn't be sized by
takeoff requirement alone (if thrust is installed solely to expedite takeoff, cruise efficiency
likely suffers) — `(T/W)_TO` must be selected considering all mission requirements (Chapter 15).

Increasing `C_Lmax` is the one method to influence just takeoff (or landing) performance — goal:
large `C_Lmax` increase for small drag increase (since `max(D+F_f)/W` decreases ground-run
acceleration). Both `C_Lmax` and aircraft `C_D` increase with flap deflection — so `δf` for minimum
ground run is a compromise between lowering `V_TO` (via higher `C_Lmax`) and lowering ground-run
acceleration (via higher `C_D`). High `C_Lmax` is the answer for STOL operation, receiving
considerable government/industry attention.

### §10.3.2 Rotation Distance, S_R
*[Nicolai & Carichner, p. 265]*

Rotation distance = distance over which the aircraft (still on the ground) rotates to the `α` such
that `C_L = 0.8·C_Lmax`. Military rotation takes two seconds; FAA-commercial rotation time is
established during flight testing:

**Eq (10.5)** *[Nicolai & Carichner, Eq. (10.5), p. 265]*:
```
S_R = 2·V_TO
```
(`V_TO` in ft/s). Check aircraft geometry to ensure the tail doesn't strike the ground during
rotation. For "geometry limited" airplanes during ground rotation, the FAA applies different
criteria for establishing the various takeoff speeds.

### §10.3.3 Transition Distance, S_TR
*[Nicolai & Carichner, p. 266]*

In the transition distance, the aircraft flies a constant-velocity arc of radius `R` (Fig. 10.3).
Load factor on the aircraft (unlabeled equation, p. 266):
```
n = 1 + V_TO²/(R·g) = L/W = (0.8)(1.2)²= 1.15
```
Solving for `R`:

**Eq (10.6)** *[Nicolai & Carichner, Eq. (10.6), p. 266]*:
```
R = V_TO² / (0.15·g)
```
(in feet). Aircraft assumed in unaccelerated climb such that (unlabeled, then restated as Eq.
10.7):

**Eq (10.7)** *[Nicolai & Carichner, Eq. (10.7), p. 266]*:
```
Rate of climb = V_TO·sin(θ_CL) = V_TO·(T-D)/W
```
Transition distance (Fig. 10.7):

**Eq (10.8)** *[Nicolai & Carichner, Eq. (10.8), p. 266]*:
```
S_TR = R·sin(θ_CL)
```

### Fig 10.7 — Schematic for transition and climb distance
*[Nicolai & Carichner, Fig. 10.7, p. 266]* — Side-view schematic: ground run at `V_TO`, transition
arc of radius `R` up to climb angle `θ_CL`, obstacle height labeled (35 ft commercial / 50 ft
military), `h_TR` = height at end of transition, segments `S_TR` and `S_CL` labeled along the
bottom. No plotted numeric data (schematic).

### §10.3.4 Climb Distance, S_CL
*[Nicolai & Carichner, p. 267]*

**Eq (10.9)** *[Nicolai & Carichner, Eq. (10.9), p. 267]*:
```
S_CL = (50 - h_TR) / tan(θ_CL)
```
where `h_TR` shown in Fig. 10.7. If `h_TR > 50 ft`, then `S_CL = 0`.

### §10.3.5 Time During Takeoff
*[Nicolai & Carichner, p. 267]*

Assume ground-run acceleration `a` constant, equal to value at `0.707·V_TO`. Then (unlabeled
equation, p. 267):
```
time(ground) = t_g = (1/a)·∫₀^(V_TO) dV = V_TO/a
```
Rotation time assumed two seconds. Time for transition and climb approximated by (unlabeled
equation, p. 267):
```
time(transition) = t_TR = [S_TR + (S_CL/cos θ_CL)] / V_TO
```

## §10.4 Landing Analysis
*[Nicolai & Carichner, p. 267]*

Landing distance = horizontal distance required to clear a 50-ft obstacle, free roll, then brake to
a complete stop (Fig. 10.8).

### Fig 10.8 — Schematic for landing analysis
*[Nicolai & Carichner, Fig. 10.8, p. 267]* — Side-view schematic: descent from 50-ft obstacle at
speed `V_50`, approach angle `θ_app`, touchdown at `V_TD`, free roll, braking to `V=0`. Segments
`S_A` (air distance), `S_FR` (free roll), `S_B` (braking) labeled along the bottom. No plotted
numeric data (schematic).

Assumed velocity over the 50-ft obstacle `V_50 = 1.3·V_S`; touchdown velocity `V_TD = 1.15·V_S`.
`V_S` is for the aircraft in landing configuration: `W_L` = aircraft weight with 1/2 fuel remaining;
`C_Lland = C_Lmax` for flaps in landing configuration. Landing distance = sum of air distance `S_A`,
free-roll distance `S_FR`, braking distance `S_B`.

### §10.4.1 Air Distance S_A
*[Nicolai & Carichner, p. 268]*

Change in KE + PE = (retarding force)·`S_A`. Assuming `θ_app` small (`cos θ_app ≈ 1`):
```
(W/g)·[V_50²/2 + 50g - V_TD²/2] = F·S_A
S_A = (W/F)·[(V_50² - V_TD²)/(2g) + 50]
```
Because `W ≈ L` and `F ≈ D`:

**Eq (10.10)** *[Nicolai & Carichner, Eq. (10.10), p. 268]*:
```
S_A = (L/D)·[(V_50² - V_TD²)/(2g) + 50]
```
or `S_A = 50/tan(θ_app)`, where `θ_app` = approach glide slope (3° typical CTOL, 7° STOL), and
`L = W_L`, `D = C_D·q·S_ref`:

**Eq (10.11)** *[Nicolai & Carichner, Eq. (10.11), p. 268]*:
```
C_D = C_D0 + K·C_Lmax² + ΔC_Dflaps + ΔC_Dgear
```

### §10.4.2 Free Roll Distance S_FR
*[Nicolai & Carichner, p. 268]*

Free-roll distance = distance covered while the pilot reduces power to idle, retracts flaps,
deploys spoilers, and applies brakes. Assumed to be three seconds:

**Eq (10.12)** *[Nicolai & Carichner, Eq. (10.12), p. 268]*:
```
S_FR = 3·V_TD
```

### §10.4.3 Braking Distance S_B
*[Nicolai & Carichner, p. 269]*

Let `a` = deceleration. Then (unlabeled equation, p. 269):
```
S_B = ∫ds = ∫_(V_TD)^0 (V dV/a) = (1/2)∫_(V_TD)^0 (d(V²)/a)
```
Using the force diagram (Fig. 10.4 analog, "Diagram 10.1"):
```
a = (1/m)·[T - D - F_f - R]
```
where `R` = reverse thrust during braking, `T = 0`; `F_f` = friction force = `μ·(W_L - L)`, `μ` from
Table 10.3. Also:
```
C_D = C_D0 + K·C_LG² + ΔC_Dflaps + ΔC_Dgear + ΔC_Dmisc + ΔC_Dspoilers
```
where `C_LG` = `C_L` at the `α` during braking (Fig. 9.22); `ΔC_Dflaps` from Fig. 9.25 (if flaps
retracted during braking, `ΔC_Dflaps = 0` and `C_LG ≈ 0`); `ΔC_Dspoilers` — use 0.006–0.007;
`ΔC_Dmisc` = drag due to miscellaneous items like a drag chute and high-energy-absorption brakes
(Fig. 10.9) — use `ΔC_Dmisc = 1.4` for drag chutes based on inflated frontal area [8].

Neglecting reverse thrust `R` and setting `T=0`:
```
-a = (g/W_L)·(F_f + D) = (g/W_L)·[μ·(W_L - L) + C_D·q·S_ref]
```

### Fig 10.9 — Brakes in action
*[Nicolai & Carichner, Fig. 10.9, p. 269]* — Two photographs: (left) SR-71 during braking ground
roll with drag chute deployed; (right) typical commercial transport main gear during heavy braking
(smoking tires visible). No plotted data (photographs).

Integrating (unlabeled equation, p. 270):
```
S_B = (W/(2g))·∫_(V_TD)^0 d(V²) / [μ·W_L + (ρ/2)·S_ref·V²·(C_D - μ·C_LG)]
```

**Eq (10.13)** *[Nicolai & Carichner, Eq. (10.13), p. 270]*:
```
S_B = W_L / {g·μ·ρ·S_ref·[(C_D/μ) - C_LG]} · ln{1 + (ρ/2)·(S_ref/W_L)·[(C_D/μ) - C_LG]·V_TD²}
```

Short landing distances require low `V_stall` and a large retardation force (unlike takeoff). Low
`V_stall` results from low wing loading at landing and high `C_L`. Fortunately, high `C_L` also
gives large drag. Thus, high `C_Lmax` is extremely important for short landing distances.

## §10.5 Aircraft Retardation Devices
*[Nicolai & Carichner, p. 270]*

Method selected to stop the aircraft on landing depends on weight and maintenance penalties (hence
cost). To dissipate touchdown kinetic energy: mechanical means (wheel brakes or arresting gear),
propulsive means (reverse thrust), aerodynamic means (drag chutes or speed brakes/spoilers), or
combinations — decision must consider the overall weapon/transportation system, not just the
airframe.

Wheel brakes are the traditional halting means; all aircraft need some wheel-braking capability for
taxi/ground maneuvering regardless of other devices selected. For a given brake life, brake
assembly weight is a function of energy that must be absorbed — calculated using predicted landing
weight and touchdown velocity `1.15·V_stall` for that weight; brake assembly weight then estimated
via Fig. 10.10 (from [9]). Brake lining life significantly affects brake weight — tradeoff between
airframe cost-performance and maintenance (total system) costs. Large aircraft requiring frequent
full-stop landings and low maintenance (e.g., airliners) can't depend on wheel brakes alone without
a payload-capacity penalty.

With trends to higher landing weights/speeds, energy dissipation requirements have grown so large
that an all-wheel-brake retardation system would be prohibitively heavy even with low-life linings.
Additional energy dissipation (aerodynamic and propulsive retardation devices) must supplement wheel
brakes. A secondary requirement for these devices: shorten landing distance by supplying stopping
force soon after touchdown, when velocities are high and wheel brakes are least effective — drag
chutes and thrust reversers meet this need. The B-2 (Fig. 10.11) instead dissipates energy using
split ailerons — it has no drag chute.

### Fig 10.10 — Weight of main gear wheel brakes based on maximum energy "rejected takeoff" (RTO)
*[Nicolai & Carichner, Fig. 10.10, p. 271]* — Total Brake Assembly Weight/Wheel (lb, 0–400) vs
Energy Absorption Requirement/Wheel/Stop (10⁶ ft-lb, 0–60), two bands: "Metal brakes" (steeper,
reaching ~400 lb by 10⁶ ft-lb≈38) and "Composite/carbon brakes" (shallower, reaching ~285 lb by
10⁶ ft-lb≈58). Vertical reference line labeled "Maximum KE/wheel (L-1011 FAA testing)" near
10⁶ ft-lb≈58. *(read from plot, band centerlines)*:

| Energy (10⁶ ft-lb) | Metal brakes (lb/wheel) | Composite/carbon brakes (lb/wheel) |
|---|---|---|
| 10 | 105 | 45 |
| 20 | 210 | 90 |
| 30 | 310 | 140 |
| 38 | 400 | 175 |
| 50 | — | 240 |
| 58 | — | 285 |

Thrust reversers on jet aircraft provide significant ground deceleration force with high
reliability and little added maintenance under repeated use. On some transports (DC-8, C-5), inboard
engine thrust reversers may be activated in flight as speed brakes. A jet/turbofan engine with
thrust reversers can provide up to approximately **40% of rated takeoff thrust** for braking.

### Fig 10.11 — B-2 taxiing
*[Nicolai & Carichner, Fig. 10.11, p. 271]* — Photograph, B-2 Spirit stealth bomber taxiing on
runway, rear three-quarter view. No plotted data (photograph).

However, the relatively high weight of aerodynamic/propulsive retardation devices has all but
prohibited their use on combat aircraft. Major exception: Swedish Viggen, a STOL fighter whose
thrust reverser activates automatically upon touchdown for rapid stopping. A thrust reverser may be
designed by the engine manufacturer or provided by the airframe designer. Thrust reverser
installation weight varies with engine rated thrust, estimated from Fig. 10.12 (compiled from both
airframe and engine manufacturers' data).

Reversible pitch on propeller aircraft is an inexpensive, lightweight retardation method for this
aircraft class. Turboprop engine-propeller combinations provide reverse force up to **60%** of
rated static thrust; reciprocating engines provide lower retardation force (~40% of static thrust)
and require a longer delay between touchdown and full reverse-thrust actuation. Reversible
propellers also let an aircraft taxi backward — extremely useful in combat airlift operations.

### Fig 10.12 — Turbojet and turbofan thrust reverser weight as a function of maximum engine thrust
*[Nicolai & Carichner, Fig. 10.12, p. 272]* — Thrust Reverser Weight (lb, log scale 200–6000) vs
Maximum Engine Thrust (log scale, 10⁴–9×10⁴), single log-log trend line through data points labeled
by engine: GE CJ805 (J79) [turbojet], GE CJ805-23B, GE CF6-6, GE CF6-50, GE CF6-80, P&W JT9D-7,
RB-211-22B, GE TF39 [turbofan with reverser on fan only], PW 4090. Legend distinguishes symbol by
engine type: Turbojet (circle), Turbofan (square), Turbofan with Reverser on Fan Only (filled
square). *(read from plot, approximate data points)*:

| Engine | Max Thrust | Reverser Weight (lb) |
|---|---|---|
| GE CJ805 (J79) | ~1.4×10⁴ | 260 |
| GE CJ805-23B | ~1.6×10⁴ | 400 |
| GE CF6-6 | ~4.0×10⁴ | 2050 |
| RB-211-22B | ~4.2×10⁴ | 1450 |
| GE TF39 | ~4.1×10⁴ | 980 |
| P&W JT9D-7 | ~4.5×10⁴ | 1650 |
| GE CF6-50 | ~4.9×10⁴ | 2100 |
| GE CF6-80 | ~5.9×10⁴ | 2350 |
| PW 4090 | ~9.0×10⁴ | 3950 |

Drag chutes have received almost universal acceptance as landing retardation devices on
high-performance combat aircraft (the F-117A used one). Lightweight, reliable, and (ignoring
repacking problems) relatively simple; most effective at higher velocities, nicely complementing
wheel brakes. Reference [8] gives average drag coefficient based on projected (inflated)
cross-sectional area of **1.4** for nylon or ribbon-type parachutes. Parachute weight (unlabeled
equation, p. 273):
```
W_P = 6.5×10⁻² · (d_chute)²
```
where `d_chute` = maximum chute diameter in feet (weight in pounds). Weight of the entire chute and
rigging is approximately 3–4 times this figure.

## §10.6 Critical Field Length (Balanced Field Length)
*[Nicolai & Carichner, p. 273]*

Critical field length (aka balanced field length) balances the distance to accelerate to `V_1` and
then either continue takeoff over 35 ft with one engine inoperative, or brake to a stop. Commercial
transport takeoff field length definition: 115% of the distance over 35 ft with all engines
operating, or the critical field length, whichever is greater.

Analysis: select a failure recognition speed `V_EF`, calculate two distances. **LAB** = distance to
accelerate to `V_EF`, free roll 3 seconds at `V_EF`, then brake to a full stop. **LAC** = distance
to accelerate to `V_EF` and continue takeoff over 35 ft with one engine out (thrust reduced
accordingly, drag increased for a windmilling engine). A unique `V_EF` exists such that
`LAB = LAC` — this `V_EF` is the **refusal speed**, and the distance `LAB = LAC` is the **critical
field length**/**balanced field length** (Fig. 10.13). If an engine fails below `V_EF`, pilot should
brake to a stop; if above the refusal speed, pilot should continue the takeoff with one engine out.
Fig. 10.14 illustrates several high-performance takeoffs.

## §10.7 Comparison of Analytical Estimates With L-1011 Flight Test
*[Nicolai & Carichner, p. 273]*

This section determines takeoff/landing distances for the L-1011 using this chapter's and Chapter
6's methods, and compares results with flight test data.

### Fig 10.13 — Schematic of balanced field length
*[Nicolai & Carichner, Fig. 10.13, p. 274]* — Speed vs Distance, parabola-like curve: "Accelerate —
all engines" rising segment through `V_EF` to `V_1*` (peak, ≈`V_R`≈`V_TO`), branching into
"Continue takeoff" (rising further to `V_OBS`) and "Brake to a full stop" (falling back to zero
speed at the same total distance). Definitions boxed: `V_1` = speed at which pilot decides to
continue or abort; `V_EF` = engine failure speed; `V_R` = rotation speed (cannot be less than `V_1`);
`V_TO` = speed at liftoff with one engine inoperative; `V_OBS` = speed over the obstacle (cannot be
less than `V_TO`). Caption note: "`V_1` is selected such that 'continue' and 'brake' distances are
identical, which is the definition of a balanced field length. However, `V_1` is not allowed to be
lower than `V_EF` or greater than `V_R`." Bottom bracket labeled "Balanced Field Length" spanning the
full plotted distance. No plotted numeric data (schematic).

The Lockheed L-1011 TriStar is a subsonic wide-body commercial transport designed for
transcontinental/short/medium-length airline routes, up to 260 passengers (15/85 mixed seating) or
345 (all-economy). FAA certified April 1972; Lockheed produced 250 aircraft 1968–1984. Powered by
three Rolls Royce RB.211-22 high-bypass turbofans — two in underwing pylons, one in the fuselage
aft body. Fig. 10.15 shows the L-1011 emphasizing the high-lift system; Table 10.5 gives dimensions
and geometry.

High-lift system: double-slotted Fowler TE flaps, full-span LE slats. Slat/flap extension manually
controlled via the flap handle. Fully extended: three inboard slat panels deflect 28°, four
outboard slat panels deflect 30°. TE flaps: four double-slotted Fowler-type flap surfaces per wing.
Discrete flap positions for takeoff/landing/cruise segments:

- Flaps up, cruise
- Flaps down 4°, transition
- Flaps down 10°, takeoff and alternate approach
- Flaps down 18°, takeoff
- Flaps down 27.5°, takeoff
- Flaps down 33°, alternate landing
- Flaps down 42°, landing

### Fig 10.14 — Mig 31, F-15, B-1B, and L1011 takeoffs
*[Nicolai & Carichner, Fig. 10.14, p. 275]* — Four photographs of aircraft during takeoff rotation:
MiG-31 (nose-high rotation, afterburner plume, spray from wet runway), F-15 (nose-high rotation),
B-1B (nose-high rotation, low altitude), Lockheed TriStar (L-1011, nose-high rotation with gear
still down). No plotted data (photographs).

### Fig 10.15 — L-1011 control surfaces arrangement
*[Nicolai & Carichner, Fig. 10.15, p. 276]* — Three-quarter view line drawing labeling: Rudder,
Geared Elevator, Stabilizer (on tail), Trailing Edge Flap (inboard and outboard), Inboard Aileron,
Spoilers #1 & #2 / #3 & #4 / #5 & #6, Outboard Aileron, Leading Edge Slats (on wing). No plotted
numeric data (labeled diagram).

### Table 10.5 — Summary of L-1011 Dimensions and Geometry
*[Nicolai & Carichner, Table 10.5, p. 277]*

| Geometry | Dimensions |
|---|---|
| Maximum takeoff weight (lb) | 430,000 |
| Maximum landing weight (lb) | 358,000 |
| Maximum fuel weight (lb) | 159,560 |
| Wing span (ft) | 155.3 |
| Wing area (ft²) | 3456 |
| Wing sweep (quarter-chord) | 35 deg |
| Aspect ratio | 6.95 |
| Mean aerodynamic chord (mac, ft) | 24.5 |
| Location of mac leading edge | FS 1143 |

Spoiler area/span (each side, ft²/ft): #1 = 27/10, #2 = 34/12, #3 = 12/5, #4 = 16/7, #5 = 7/3,
#6 = 11/5.

TE flap area/span/chord (each side, ft²/ft/ft): Inboard = 145/22/6.5; Outboard = 123/22/30% chord.

LE slat area/span (each side, ft²/ft): Inboard = 61.74/22; Outboard = 118/38.67.

Horizontal tail: Area = 1282 ft², AR = 4.0, taper ratio = 0.33, mac = 19.5 ft, mac LE location =
FS 1885.

Vertical tail: Area = 550 ft², AR = 1.6, taper ratio = 0.3, mac = 20.3 ft, mac LE location = FS 1924.

The TriStar also has six pairs of spoilers on each wing to dump the load during landing (reduce
lift, put more weight on wheels for greater braking). Spoilers manually deflected up to 60°.

### Example 10.1 — Takeoff Distance Comparison
*[Nicolai & Carichner, Example 10.1, p. 278]*

Calculating takeoff distance using this chapter's method, initial conditions:

| Parameter | Value |
|---|---|
| Weight | 358,000 lb |
| TE flap deflection | 27.5 deg |
| Maximum C_L | 2.0 (IGE at α=16°, limited by tail strike) |
| Rolling friction coefficient, μ | 0.015 (measured during flight test) |
| Ground C_L, C_LG | 0.32 (value at α=0°, δf=27.5°, from flight test) |
| Thrust, all three engines | 100,022 lb |
| ΔC_Dflap | 0.042 (from Fig. 9.25) |
| C_Dmin | 0.0175 (from Fig. G.1) |
| ΔC_Dgear | 0.024 (from Fig. 10.5) |
| Air density, ρ | 0.002378 slug/ft³ |
| Ground run drag-due-to-lift factor, K | 0.0468 (from flight test) |

`K = 0.0468` estimated considering drag-due-to-lift in ground effects. Using Fig. 10.2a, assuming
`2h/b = 0.12` during ground run, effective AR for the L-1011 ≈ 17. From Fig. G.9 the wing efficiency
factor for this class of aircraft ≈ 0.4, giving `K = 0.0468`.

Assuming `V_TO = 1.2·V_S` gives takeoff speed of **250 ft/s (148 kt)**, under the flap/slat placard
limit of 200 kt for the L-1011. Ground-run drag coefficient:
```
C_Dground = C_Dmin + K·C_LG² + ΔC_Dflap + ΔC_Dgear = 0.0883
```
Dynamic pressure at `0.7·V_TO` = 36.4 psf, giving `L = 40,270 lb`, `D = 11,107 lb`. Using Eq. (10.3):
acceleration at `0.7·V_TO` = **7.57 ft/s² (~1/4 g)**; from Eq. (10.4), ground run distance
`S_G = 4172 ft`.

At `V_TO` the aircraft rotates to `C_L = 0.8·C_Lmax`, assumed to take two seconds; aircraft geometry
checked so the tail doesn't strike the ground. `S_R = 500 ft`.

Transition distance analysis: L-1011 clears the 35-ft obstacle about midway through transition to a
steady-state climb rate of **61.6 ft/s**. Assumed the L-1011 spends ~1.5 s in transition, covering
another 375 ft. **Total takeoff distance for the L-1011 = 5047 ft.**

### Table 10.6 — Comparison of Takeoff Analysis
*[Nicolai & Carichner, Table 10.6, p. 279]*

| Phase | Eq. (10.4)/(10.5)/(10.8) | Eq. (6.3) | Flight Test (1972) |
|---|---|---|---|
| Ground run | 4172 | 3867 | 3632 |
| Rotate and transition | 875 | 500 | 1225 |
| Takeoff distance | 5047 | 4367 | 4857 |

Actual takeoff distance depends on winds, runway characteristics, aircraft aerodynamic performance,
and pilot technique. Eq. (6.3) should be used for early analysis/sizing the wing loading; this
chapter's analysis should refine the takeoff analysis as more design information is available.

### Example 10.2 — Landing Distance Comparison
*[Nicolai & Carichner, Example 10.2, p. 279]*

Calculating landing distance using this chapter's method, initial conditions:

| Parameter | Value |
|---|---|
| Weight | 345,100 lb |
| TE flap deflection | 42 deg |
| Maximum C_L | 2.63 (IGE from flight test) |
| Braking friction coefficient, μ | 0.32 (measured during flight test) |
| Ground C_L, C_LG | -0.18 (value at α=0°, δf=0°, spoilers deployed, from flight test) |
| ΔC_Dflap | 0.095 (from Fig. 9.25 during approach); 0 (flaps retracted during ground braking) |
| C_Dmin | 0.0175 (from Fig. G.1) |
| ΔC_Dgear | 0.021 (from Fig. 10.5 for δf=42°); 0.029 (from Fig. 10.5 for δf=0°) |
| ΔC_Dspoiler | 0.0065 (from [10]) |
| Air density, ρ | 0.002378 |
| Average approach L/D | 5.0 (IGE from flight test) |
| Drag-due-to-lift factor, K | 0.057 (IGE from flight test) |

Assuming `V_TD = 1.15·V_S` gives touchdown speed of **199 ft/s (124 kt)**, and `V_50 = 1.3·V_S`
gives speed over 50 ft of **225 fps (133 kt)** — both under the flap/slat placard limit of 164 kt
for the L-1011.

Average approach `K = 0.057` estimated assuming average `2h/b = 0.32`. From Fig. 10.2a, effective AR
during approach ≈ 10.7. Estimating wing efficiency via Fig. G.9 for this class/AR gives `e ~ 0.52`
and `K = 0.057`.

The air-distance phase is one of the few times drag is good — larger `D/L` means steeper glide
slope and shorter air distance over the 50-ft obstacle. Drag coefficient on approach:
```
C_DApproach = C_Dmin + K·C_Lmax² + ΔC_Dflap + ΔC_Dgear = 0.527
```
`L/D` for the L-1011 during landing approach = 5.0. Using Eq. (10.10): air distance = **1106 ft**.

During free-roll, the L-1011 pilot applies brakes, idles engines, retracts TE flaps, deploys
spoilers — assumed to take three seconds, so `S_FR = 597 ft`. During L-1011 flight test, test pilots
routinely took under two seconds for this phase.

Drag coefficient during ground braking:
```
C_Dground = C_Dmin + K·C_LG² + ΔC_Dflap + ΔC_Dgear + ΔC_Dspoiler = 0.0548
```
During ground braking, flaps retracted and spoilers deployed to dump lift and put maximum weight on
wheels (increase friction force) — spoilers actually produce a small downward force coefficient of
**-0.18**. Eq. (10.13) gives braking distance = **1778 ft**. **Total landing distance = 3481 ft.**

### Table 10.7 — Comparison of Landing Analysis
*[Nicolai & Carichner, Table 10.7, p. 281]*

| Phase | Eq. (10.10)/(10.12)/(10.13) | Eq. (6.5) | Flight Test (1972) |
|---|---|---|---|
| Air distance | 1106 | 954 | 953 |
| Free roll | 597 | Included below | 315 |
| Braking distance | 1778 | 3014 | 1898 |
| Landing distance | 3481 | 3968 | 3166 |

Discussion for Table 10.7 parallels Table 10.6. The dependence on pilot technique is even more
pronounced for landing because pilots (carrier pilots excluded) flare the aircraft just prior to
touchdown for a soft landing and to minimize tail strike — flare distance varies significantly
between pilots. This chapter's analysis does not assume a flare.

The L-1011 compared favorably with its competition (DC-10, Boeing 747), but a Rolls Royce
bankruptcy in 1971 caused the L-1011 to arrive late in the marketplace — only 250 built. Even so,
it's a significant design achievement: the L-1011 is the first airplane to certify Category 3C
landing capabilities using its spoilers to provide excellent lift control during landing approach.

## §10.8 Airport Operations
*[Nicolai & Carichner, p. 281]*

Airport personnel must remain vigilant about operational safety around airports. Birds and wake
turbulence pose real hazards. Aircraft are especially vulnerable during ATC (air traffic control)
portions of the mission — low and slow, high angle of attack, crew in a high-workload environment.

The vortex system generated during landing/takeoff (Fig. 10.1) is both beautiful (on a humid day)
and dangerous. Generated by a wing as it develops lift (§2.6) — not to be confused with prop wash
(rotating air mass behind a propeller) or jet wash (swirling hot gas from jet exhaust), both shorter
in duration/extent than the trailing vortex system. The trailing vortex (aka **wake turbulence**)
can flip a trailing aircraft in close proximity upside down. Airports use landing/departure time
intervals to let the vortex system dissipate — intervals depend on temperature, wind conditions, and
relative size of trailing vs lead aircraft. Typical departure time interval: **3 minutes** for a
smaller aircraft taking off behind a larger one. Landing time interval is in terms of separation
distance: **4 nm** for two same-size aircraft (e.g., two B-767s), increasing to **8 nm** for a small
aircraft landing behind a large one (e.g., Cessna Citation behind a B-747).

Birds around an airport are a problem — can be ingested into a jet inlet or impact a propeller and
shut down an engine. On January 15, 2009, an Airbus A320 struck a flock of Canadian Geese during
departure from LaGuardia Airport, New York, causing immediate loss of thrust from both turbine
engines. Due to masterful piloting, the aircraft was ditched in the Hudson River with no loss of
the 155 passengers and crew. Airports go to great lengths (scare crows, sound systems emanating
shrill/annoying noise, professional hunters) to discourage bird populations around airports.

## References
*[Nicolai & Carichner, Chapter 10 References, p. 282]*

1. "Charts; Standard Aircraft Characteristics and Performance," Military Specification
   MIL-C-5011A, 14 Feb. 2003.
2. "Airworthiness Standards: Part 23—Normal, Utility and Acrobatic Category Airplanes; Part
   25—Transport Category Airplanes," Federal Aviation Regulation, Vol. 3, U.S. Department of
   Transportation, U.S. Government Printing Office, Washington, DC, Dec. 1996.
3. "Guidelines for Preparation of Standard Aircraft Characteristics Charts and Performance Data of
   Piloted Aircraft (Fixed Wing)," AS-5263, Naval Air Systems Command, Patuxent River, MD, 23 Oct.
   1986 (for Navy use in lieu of MIL-C-25011).
4. Davenport, F. J., Rengstorff, A. E., and Van Heyningen, V. F., "Takeoff and Landing Performance
   Ground Rules for Powered Lift STOL Transport Aircraft," U.S. Air Force Flight Dynamics
   Laboratory AFFDL-TR-73-19, Vol. 3, Wright–Patterson AFB, OH, May 1973.
5. Hebert, J., Moorehouse, D., and Richie, S., "STOL Takeoff and Landing Ground Rules," U.S. Air
   Force Flight Dynamics Laboratory AFFDL-TR-73-21, Vol. 3, Wright–Patterson AFB, OH, May 1973.
6. Carter, W. E., "Effect of Ground Proximity on the Aerodynamic Characteristics of Aspect Ratio I
   Wings with and without End Plates, II," NASA TN D-970, Langley Research Center, Oct. 1961.
7. Fink, M. P., and Lastinger, J. L., "Aerodynamic Characteristics of Low Aspect Ratio Wings in
   Close Proximity to the Ground," NASA TN D-926, Langley Research Center, July 1961.
8. Brown, W. D., *Parachutes*, Pitman, London, 1951.
9. Schaezler, G. B., "Synthesis of Ground Flotation Requirements and Estimation of Aircraft Running
   Gear Weight," Proc. 3rd Weight Prediction Workshop, Aeronautical Systems Division,
   Wright–Patterson AFB, OH, Oct. 23–27, 1967.
10. "FAA Type Certification Report, Model L-1011-385-1 with Rolls-Royce RB.211-22 Engines,"
    Lockheed Rept. LR 25089, 14 July 1972.

---

*Chapter 10 complete (§§10.1–10.8, Tables 10.1–10.7, Figs 10.1–10.15 incl. 10.2a/10.2b, Eqs
10.1–10.13 incl. 10.4a/10.4b, References [1]–[10]). Next: Chapter 11 — Preliminary Sizing of the
Vertical and Horizontal Tails.*
