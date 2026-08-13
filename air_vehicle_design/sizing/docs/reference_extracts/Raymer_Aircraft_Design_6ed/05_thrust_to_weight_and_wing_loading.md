# Chapter 5 — Thrust-to-Weight Ratio and Wing Loading

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 5
"Thrust-to-Weight Ratio and Wing Loading," printed pp. 115–144 (PDF pp. 144–173).

This is the constraint-analysis chapter: statistical/thrust-matching methods for initial `T/W`
(or `P/W`), and closed-form wing-loading equations for stall, takeoff, landing, catapult/arrested
landing, cruise, loiter, turn, climb, glide, and ceiling. Every numbered equation, table, and figure
is captured below; design-chart figures are digitized where the plot carries numeric design data.

---

## Introduction
*[Raymer, p. 115]*

`T/W` and `W/S` are the two most important parameters affecting aircraft performance. Both are
needed before the first concept layout can be drawn — you can't draw the airplane if you don't know
how big to draw the engine and the wing. Initial values from this chapter are later revised by
post-layout carpet plots and other optimization (Chapter 19).

`T/W` and `W/S` are closely interconnected: a short takeoff distance can be met either with a large
wing (low `W/S`) and small engine (low `T/W`), or a small wing (high `W/S`) and large engine (high
`T/W`). A fully simultaneous solution is possible (computationally, or via carpet plots as in Chapter
19) but is often not worth the effort this early, since pre-layout aerodynamic/propulsion estimates
are not very accurate ("garbage-in-garbage-out"). The author's preferred approach: pick one parameter
via a quick approximation, then solve the performance-requirement equations for the other. This
chapter assumes `T/W` is estimated first, and `W/S` is calculated from it — except when a requirement
(most often stall speed) pins down `W/S` directly and independent of engine size, in which case solve
for `W/S` first and use it to back out `T/W`.

## §5.1 Thrust-to-Weight Ratio
*[Raymer, p. 116]*

A higher `T/W` gives faster acceleration, quicker climb, higher max speed, and higher sustained turn
rate — at the cost of heavier engines and higher fuel burn, which drives up TOGW. `T/W` conventionally
means sea-level static (zero-velocity), standard-day, design takeoff weight, maximum throttle
(afterburner on, if fitted).

### Table 5.1 — Thrust-to-Weight Ratio (T/W)*
*[Raymer, Table 5.1, p. 117]*

| Aircraft Type | Typical Installed T/W |
|---|---|
| Jet trainer | 0.4 |
| Jet fighter (dogfighter) | 0.9 |
| Jet fighter (other) | 0.6 |
| Military cargo/bomber | 0.25 |
| Jet transport (higher value for fewer engines) | 0.25–0.4 |

*In mks units, thrust force = (T/W) × mass × g (g = 9.807 m/s²).

Commercial-transport `T/W` varies widely: higher for twins, lower for quads, because a twin loses
half its thrust on an engine-out climbout and needs a lot of margin — all these transports converge
to about `T/W ≈ 0.2` with one engine out. Modern fighters approach `T/W = 1.0` at takeoff weight, and
can exceed 1.0 at combat weight (fuel burned off) — capable of accelerating supersonic while climbing
vertically. Takeoff `T/W` must not be confused with `T/W` at other flight conditions; conversions back
to takeoff conditions are covered in §5.1.3.

### §5.1.1 Props and Power Loading
*[Raymer, p. 116]*

Propeller engines are sold by power, not thrust, so the industry convention is **power loading**
`W/P` (weight ÷ engine power) rather than a `P/W` ratio — the inverse of `T/W`'s sense, so a *high*
power loading means a *small* engine. Typical power loadings run 10–15 lb/hp; aerobatic aircraft ~6;
as low as 3 for the one-off Pitts Sampson.

Propeller thrust equals power times propeller efficiency `η_p`, divided by velocity. Dividing by
weight:

**Eq (5.1)** *[Raymer, Eq. (5.1), p. 117]*:
```
T/W = (P/W)*(eta_p/V)   [general]
    = 550*eta_p*(P/W)/V  [fps units, P in hp, V in ft/s]
```
where 550 converts horsepower to ft·lb/s. This book generally refers to power-to-weight ratio `P/W`
(not power loading) so `T/W`-based language applies uniformly to jets and props; "thrust-to-weight
ratio" is understood to also mean the propeller-aircraft equivalent.

### Table 5.2 — Power-to-Weight Ratio (P/W)
*[Raymer, Table 5.2, pp. 118–119]* — max power settings, sea-level static. Metric column is
power/mass (W/g); divide by `g = 9.807` before use in equations.

| Aircraft Type | P/W (hp/lb) | {Watt/g} | Power loading (lb/hp) |
|---|---|---|---|
| Powered sailplane | 0.04 | {0.07} | 25 |
| Homebuilt | 0.08 | {0.13} | 12 |
| General aviation — single engine | 0.07 | {0.12} | 14 |
| General aviation — twin engine | 0.17 | {0.3} | 6 |
| Agricultural | 0.09 | {0.15} | 11 |
| Twin turboprop | 0.20 | {0.33} | 5 |
| Flying boat | 0.10 | {0.16} | 10 |

Power loading in lb/hp × 1.644 gives kg/kW.

### §5.1.2 Statistical Estimation of T/W and Power Loading
*[Raymer, p. 119]*

`T/W` (or `P/W`) is strongly correlated, within an aircraft class, with maximum speed — an
exponential-form fit (constant × speed^exponent), which plots as a straight line on log-log axes
(as many design parameters do — see Chapter 15).

### Table 5.3 — T/W₀ vs M_max
*[Raymer, Table 5.3, p. 119]*: `T/W_0 = a * M_max^C`

| Aircraft Type | a | C |
|---|---|---|
| Jet trainer | 0.488 | 0.728 |
| Jet fighter (dogfighter) | 0.648 | 0.594 |
| Jet fighter (other) | 0.514 | 0.141 |
| Military cargo/bomber | 0.244 | 0.341 |
| Jet transport | 0.267 | 0.363 |

### Table 5.4 — P/W₀ vs V_max (kt or {km/h})
*[Raymer, Table 5.4, p. 120]*: `P/W_0 = a * V_max^C`, in hp/lb {Watt/g}; divide Watt/g by 9.807 before
use.

| Aircraft Type | a | C |
|---|---|---|
| Sailplane — powered | 0.043 {0.071} | 0 |
| Homebuilt — metal/wood | 0.005 {0.006} | 0.57 |
| Homebuilt — composite | 0.004 {0.005} | 0.57 |
| General aviation — single engine | 0.025 {0.036} | 0.22 |
| General aviation — twin engine | 0.036 {0.048} | 0.32 |
| Agricultural aircraft | 0.009 {0.010} | 0.50 |
| Twin turboprop | 0.013 {0.016} | 0.50 |
| Flying boat | 0.030 {0.043} | 0.23 |

These curve fits (author's own, from data in Ref. [6]) are valid only within the normal speed range
of each class; good as a credible first estimate for most airplanes.

### §5.1.3 Thrust Matching
*[Raymer, p. 119]*

In level unaccelerated cruise, thrust equals drag and weight equals lift, so `T/W = 1/(L/D)`:

**Eq (5.2)** *[Raymer, Eq. (5.2), p. 120]*:
```
(T/W)_cruise = 1 / (L/D)_cruise
```
`L/D` can be estimated with the Chapter 3 method (selected aspect ratio + wetted-area-ratio estimate
from Fig. 3.6 → wetted aspect ratio → Fig. 3.5 → max `L/D`). For props, cruise `L/D` = max `L/D`; for
jets, cruise `L/D` = 86.6% of max `L/D`. This simple method assumes cruise at roughly the optimum
altitude for the (as-yet-unknown) wing loading — invalid if the mission forces cruise at a fixed
altitude such as sea level.

`T/W` for climb is often the true driver (rather than cruise), which can force cruise power settings
low enough to be inefficient (especially for jets). Per Chapter 17, climb `T/W` is level-flight `T/W`
plus the extra thrust for the climb gradient:

**Eq (5.3)** *[Raymer, Eq. (5.3), p. 121]*:
```
(T/W)_climb = 1/(L/D)_climb + V_vertical/V
```
`V_vertical` (climb rate) is usually specified by requirements or by military/civil spec (Appendix F,
Table F.2). Climb `L/D` may be lower than cruise `L/D`, especially with gear/flaps still extended.

Cruise `T/W` is still computed (even though climb `T/W` may look sufficient for cruise altitude too)
because most engines cannot sustain maximum power continuously — the pilot throttles back to maximum
continuous power for cruise, and that reduced-power condition must still be checked. Other criteria
(takeoff distance, turning performance — see §5.2 onward) can also set `T/W`.

Initial `T/W` = the higher of (a) the statistical value (Tables 5.3/5.4) or (b) the thrust-matching
value, both then adjusted to takeoff conditions (§5.1.4).

### §5.1.4 Ratio Results to Takeoff Conditions
*[Raymer, p. 121]*

Aircraft weight and available thrust both change through the flight, so a `T/W` computed at cruise
(say) must be ratioed back to takeoff conditions before comparison with other required `T/W` values.

The weight ratio: multiply together the mission-segment weight fractions up to the point of interest
(e.g., Chapter 3 example: takeoff × climb fractions 0.970 × 0.985 = 0.956 gives the weight fraction
at start of cruise).

The thrust ratio: actual thrust at the flight condition ÷ sea-level-static max thrust — use engine
data if available, else approximate. Typical cruise thrust as % of SLS takeoff thrust:
- high-bypass subsonic turbofan (transport): 20–25%
- low-bypass afterburning turbofan/turbojet: 40–70% (Fig. 5.1)

**Fig. 5.1 — Thrust lapse at cruise** *[Raymer, Fig. 5.1, p. 121]*. `T_max_dry_cruise / T_max_takeoff
(SLS)` (0–0.7) vs. altitude (0–40,000 ft {0–12,500 m}), at Mach = 0.8, two labeled bands: "High BPR
turbofan" (lower thrust-ratio band, consistent with the 20–25% figure quoted in text) and "Low BPR
afterburning turbofan" (higher band, consistent with 40–70%). *Not digitized point-by-point* — the
text already states the governing ranges (20–25% / 40–70%) directly, and the chart is a qualitative
band illustration of those same numbers rather than a precision design curve.

For a piston engine (unsupercharged), power falls off roughly with density ratio `σ`; e.g. at
10,000 ft {3,048 m} an unsupercharged engine has ~73% of SL power. A supercharger holds intake
density near sea-level up to its compression limit, beyond which power again falls off (Fig. 5.2).
Piston aircraft typically cruise at ~75% of takeoff power.

**Fig. 5.2 — Piston engine power variation with altitude** *[Raymer, Fig. 5.2, p. 122]*. Altitude
(0–20,000 ft {0–5,000 m}) vs. Power (0–250 hp {0–~185 kW}) for a turbocharged TIO-360. Shows power
held roughly constant up to the supercharger's critical altitude, then decreasing above it. *Not
digitized* — illustrative for one specific engine model; no general design coefficients to extract,
and the text's qualitative altitude/power description is the actionable content.

For a turboprop, available power rises somewhat with speed but net thrust still falls with velocity
(prop efficiency, Eq. 5.1); turbine-exhaust residual thrust is converted to an "equivalent shaft
horsepower" (eshp) and added to shaft power. Typical turboprop cruise eshp ≈ 60–80% of takeoff eshp.

The required `T/W` is adjusted cruise→takeoff via:

**Eq (5.4)** *[Raymer, Eq. (5.4), p. 122]*:
```
(T/W)_takeoff = (T/W)_cruise * (W_cruise/W_takeoff) * (T_takeoff/T_cruise)
```
Note the takeoff-thrust ratio is inverted relative to the weight ratio (numerator, not denominator).
After adjustment, take the higher of the statistical and thrust-matching `T/W` values for engine
sizing. For props, solve Eq. (5.1) for the equivalent `P/W`.

## §5.2 Wing Loading
*[Raymer, p. 123]*

### §5.2.1 Overview
*[Raymer, p. 123]*

`W/S` affects stall speed, climb rate, takeoff/landing distance, turn performance, design lift
coefficient, and (via wetted area and span) drag. Lower `W/S` → bigger wing → usually better
performance but more drag/weight → higher TOGW to fly the mission (leverage effect of the sizing
equation gives a more-than-proportional TOGW increase). `S_ref` for `W/S` is the simplified trapezoid
extended to the centerline (including the fuselage-covered portion) — not the "exposed" wing area
used for lift calculations in Chapter 12.

### Table 5.5 — Wing Loading*
*[Raymer, Table 5.5, p. 124]*

| Aircraft Type | Historical Trends (lb/ft²) | {kg/m²} |
|---|---|---|
| Sailplane | 6 | {30} |
| Homebuilt | 11 | {54} |
| General aviation — single engine | 17 | {83} |
| General aviation — twin engine | 26 | {127} |
| Twin turboprop | 40 | {195} |
| Jet trainer | 50 | {244} |
| Jet fighter | 70 | {342} |
| Jet transport/bomber | 120 | {586} |

*In mks units, multiply metric values by `g = 9.807` for use in equations.

Because performance weight varies through the flight, any `W/S` value calculated at a non-takeoff
weight must be ratioed to takeoff `W/S` (multiply by the product of the relevant mission weight
fractions) before comparison across requirements. Ultimately `W/S` and `T/W` are optimized together
post-layout (Chapter 19, carpet plots); the equations below give initial estimates for each
requirement — the designer should select the **lowest** resulting `W/S` (largest wing) unless one
outlier requirement suggests a design change (e.g. add flaps, or raise `T/W`) instead of shrinking
the wing to match it.

### §5.2.2 Stall Speed
*[Raymer, p. 125]*

Stall speed governs flight safety and (via the 1.2–1.3× margin) approach speed and landing distance.
FAR 23 caps stall speed at 61 kt {113 km/h} for singles under 12,500 lb {5,670 kg} TOGW (unless
multi-engine and meeting climb requirements — Appendix F). ~50 kt is an informal ceiling for
low-time-pilot trainers. Approach speed ≥ 1.3× stall (civil) or 1.2× stall (military).

At stall, lift = weight at `C_Lmax`:

**Eq (5.5)** *[Raymer, Eq. (5.5), p. 125]*:
```
W = 0.5 * rho * V_stall^2 * S * C_Lmax
```

**Eq (5.6)** *[Raymer, Eq. (5.6), p. 125]*:
```
W/S = 0.5 * rho * V_stall^2 * C_Lmax
```
`ρ` typically sea-level standard `0.00238 slug/ft³` {1.23 kg/m³}, or the 5,000-ft {1,524 m} hot-day
value `0.00189` {0.974} to guarantee summer operation at Denver-altitude airports.

`C_Lmax` is difficult to estimate precisely (depends on wing geometry, airfoil, flap/slat geometry,
Re, surface texture, fuselage/nacelle/pylon interference, horizontal-tail trim direction, and
prop/jet-wash impingement on power-on flaps) — better methods are in Chapter 12; here only quick
approximations. Typical ranges: 1.2–1.5 (plain wing, no flaps) up to 5.0 (large flaps immersed in
prop/jet wash). For AR > ~5, no-flap `C_Lmax` ≈ 90% of the airfoil's 2D `C_lmax` (Appendix D). Sweep
reduces `C_Lmax` by the cosine of sweep:

**Eq (5.7)** *[Raymer, Eq. (5.7), p. 125]*:
```
C_Lmax = 0.9 * C_lmax * cos(Lambda_LE at max t/c)
```

"Normal" inner-wing flaps: `C_Lmax` ≈ 1.6–2.0. Transport with flaps+slats: ≈ 2.4. STOL (heavy flaps,
slots): up to ≈ 3.0.

**Fig. 5.3 — Maximum lift coefficient** *[Raymer, Fig. 5.3, p. 127]*. `C_Lmax` (0–4.0) vs. quarter-
chord Sweep `Λ_c̄/4` (0–60°), for wings of moderate AR (4–8), one curve per flap type, all decreasing
gently with sweep *(read from plot, values at sweep = 0° / 60°)*:

| Flap type | C_Lmax at Λ=0° | C_Lmax at Λ=60° |
|---|---|---|
| Triple slotted flap and slat | 3.4 | 1.8 |
| Double slotted flap and slat | 3.0 | 1.55 |
| Double slotted flap | 2.7 | 1.4 |
| Fowler flap | 2.2 | 1.25 |
| Slotted flap | 1.8 | 1.05 |
| Plain flap | 1.5 | 0.85 |
| No flap | 1.45 | 0.7 |

Aircraft use a lower flap deflection for takeoff than landing; typical takeoff `C_Lmax` ≈ 80% of the
landing value. GA aircraft often take off flapless (clean-wing `C_Lmax`).

### §5.2.3 Takeoff Distance
*[Raymer, p. 128]*

Three distinct "takeoff distance" definitions: **ground roll** (brake release to liftoff); **obstacle
clearance distance** (brake release to a specified height — 50 ft {15.24 m} for military/most civil,
35 ft {10.7 m} for FAR 25 jet transports — the 50-ft figure traces to a tree at an old Army Air Corps
Texas base); **balanced field length (BFL)** — the multi-engine-safety distance defined by the
"decision speed" at which stop-distance-after-engine-failure equals continue-distance-after-failure
(reversed thrust not permitted in the BFL calc). FAR 25 "takeoff field length" = worse of BFL or
1.15× the all-engines-operating obstacle-clearance distance, with a 35-ft obstacle. FAR 23 aircraft
need not meet BFL. Military BFL retains the 50-ft obstacle. Liftoff speed ≈ 1.1× stall speed.

Fig. 5.4 (data from Refs. [13],[14]) gives ground roll, 50-ft obstacle distance, and FAR/balanced
field length (35-ft obstacle) directly from a normalized takeoff parameter. For military multi-engine
aircraft, BFL over a 50-ft obstacle ≈ 1.05× the FAR 35-ft BFL value. A twin has a larger BFL than a
tri/quad of equal total thrust (losing one engine costs the twin a larger fraction of total thrust) —
hence twins are usually designed to a higher total `T/W`.

**Takeoff parameter (TOP)**: `W/S` (takeoff) ÷ (density ratio `σ` × takeoff lift coefficient ×
takeoff `T/W` or `P/W`). For the jet/prop (ground-roll, 50-ft) lines, takeoff lift coefficient is the
*actual* CL at takeoff (≈ `C_Lmax`/1.21, since liftoff is at 1.1×`V_stall`) — though it may instead be
capped by max landing-gear tail-down angle (typically ≤15°). For the "FAR takeoff" lines,
takeoff-lift-coefficient = the actual `C_Lmax` at takeoff (stall-calc value).

**Fig. 5.4 — Takeoff distance estimation (fps units)** *[Raymer, Fig. 5.4, p. 130, data from Refs.
13–14]*. Takeoff distance (10³ ft, 0–12) vs. TOP = `(W/S)/(σ·C_Lto·T/W)` or `(W/S)/(σ·C_Lto·BHP/W)`
(0–650). Five lines: Jet "Ground roll," Jet "Over 50 ft," Prop "Ground roll," Prop "Over 50 ft," and
"FAR takeoff (~balanced) field length" (three closely-spaced sub-lines for 2/3/4 jet engines).
*(read from plot)*:

| TOP | Jet ground roll (10³ ft) | Jet over-50-ft (10³ ft) | FAR takeoff, 2-eng (10³ ft) | Prop ground roll (10³ ft) | Prop over-50-ft (10³ ft) |
|---|---|---|---|---|---|
| 100 | 0.8 | 1.4 | 2.1 | — | — |
| 200 | 1.7 | 2.9 | 5.0 | 1.0 | 1.7 |
| 300 | 2.6 | 4.4 | 7.9 | 1.6 | 2.6 |
| 400 | 3.4 | 5.9 | 10.7 | 2.2 | 3.5 |
| 500 | — | — | — | 2.9 | 4.4 |
| 600 | — | — | — | 3.5 | 5.3 |

(Jet lines' data terminates near TOP≈450–500; prop lines run to TOP≈650. 3- and 4-engine FAR-takeoff
lines sit just below the 2-engine line, converging with it at low TOP.)

Solve for the required `W/S`:

**Eq (5.8)**, Prop *[Raymer, Eq. (5.8), p. 130]*:
```
W/S = (TOP)*sigma*C_Lto*(hp/W)
```

**Eq (5.9)**, Jet *[Raymer, Eq. (5.9), p. 130]*:
```
W/S = (TOP)*sigma*C_Lto*(T/W)
```

### §5.2.4 Catapult Takeoff
*[Raymer, p. 130]*

Naval carrier aircraft: modern steam catapults give smooth, adjustable (by steam pressure)
acceleration; lighter aircraft reach higher end speed at the weight limit. Catapult-departure airspeed
must exceed stall speed by 10%; airspeed = catapult end speed `V_end` + carrier wind-over-deck
`V_wod` + thrust-added velocity (typically 3–10 kt / 5–18 km/h). Deck wind-over-deck is typically
20–40 kt during normal launch ops, but Navy specs often require launch capability at zero or even
negative wind-over-deck (at-anchor launch).

**Fig. 5.5 — Catapult end speeds** *[Raymer, Fig. 5.5, p. 131]*. Catapult end speed (kt, 0–150) vs.
maximum TOGW (10³ lb, 0–100), three catapult types C-11, C-7, C-13, each a smoothly-decreasing curve
that terminates abruptly (vertical drop to the axis) at its own max-TOGW limit *(read from plot)*:

| Max TOGW (10³ lb) | C-11 end speed (kt) | C-7 end speed (kt) | C-13 end speed (kt) |
|---|---|---|---|
| 0 | 148 | 140 | 132 |
| 20 | 132 | 128 | 122 |
| 40 | 118 | 118 | 113 |
| 60 | 105 | 108 | 105 |
| 80 | 92 (cutoff ~89) | 98 | 97 |
| 90 (cutoff) | — | 90 | 90 |
| 100 (cutoff) | — | — | 82 |

(C-11 max TOGW ≈ 89×10³ lb; C-7 ≈ 93×10³ lb; C-13 ≈ 100×10³ lb — read at each curve's vertical
dropoff.)

**Eq (5.10)** *[Raymer, Eq. (5.10), p. 131]*:
```
(W/S)_takeoff = 0.5*rho*(V_end + V_wod + DeltaV_thrust)^2 * (C_Lmax)_takeoff / 1.21
```
where `ρ = 0.00219 slug/ft³` {1.13 kg/m³}, tropical day. If the stall margin is instead defined as a
15% `C_L` margin (rather than 10% velocity margin), the 1.21 constant becomes 1.18.

*(EMALS — ElectroMagnetic Aircraft Launch System — discussion, p. 132: linear-induction-motor
catapult replacing steam on Ford-class carriers; lower system weight/maintenance, less fresh-water
draw, can be "dialed down" for small UAVs (steam cannot); stores energy in rotating-disk alternators,
~45 s charge time; can launch heavier aircraft than legacy steam catapults, so Fig. 5.5-style charts
set only an upper design bound. No numeric design equation associated with EMALS in this chapter.)*

### §5.2.5 Landing Distance
*[Raymer, p. 132]*

**Landing ground roll**: wheels-down to full stop. **FAR 23 landing field length**: 50-ft {15.24 m}
obstacle clearance at approach speed/glidepath (typically 3°), then slow to touchdown at ≈1.15×
`V_stall`; obstacle clearance roughly doubles the ground-roll-alone distance. **FAR 25 landing field
length**: same 50-ft clearance, plus an arbitrary +2/3 total-distance safety margin. Military
landing-distance definitions (per RFP) typically resemble FAR 23.

Landing distance scales with wing loading via approach speed (1.3× or 1.2× stall) → touchdown speed →
kinetic energy (∝ touchdown speed²) → stopping distance. A quick first-guess total landing distance
(with obstacle clearance) ≈ `0.3 × (approach speed in kt)²` [ft] [Ref. 14] — approximately valid for
FAR 23/military aircraft without thrust reversers, and for FAR 25 aircraft *with* thrust reversers
(the reversers' savings roughly offset the FAR 25 +2/3 margin).

**Eq (5.11)** *[Raymer, Eq. (5.11), p. 133]*:
```
S_landing = 80*(W/S)/(sigma*C_Lmax) + S_a     [ft]
          = 5*(W/S)/(sigma*C_Lmax) + S_a      [m]
```
where
```
sigma = density ratio = rho_landing / rho_sea-level-standard-day
   (sigma = 1.0 sea-level std day; sigma = 0.794 hot day at 5,000 ft)
S_a = 1000 ft {305 m}  airliner-type, 3-deg glideslope
    =  600 ft {183 m}  general-aviation-type power-off approach
    =  450 ft {137 m}  STOL, 7-deg glideslope
```
The first term is the kinetic-energy ground-roll; `S_a` is the fixed obstacle-clearance-distance
constant. With thrust reversers/reversible-pitch props, multiply the ground-roll term (first term
only) by 0.66 — though many requirements disallow crediting reversers (they might fail exactly when
needed). For commercial FAR 25 aircraft, multiply the *total* Eq. (5.11) result by 1.67 for the
required safety margin.

Landing `W/S` must be converted to takeoff `W/S` by dividing by (landing weight ÷ takeoff weight) —
usually an arbitrary specified landing weight, not the calculated end-of-mission weight. For most
props and jet trainers this ratio ≈ 1.0 (land near takeoff weight); for most jets, landing is
evaluated at ≈85% of takeoff weight; military specs often specify full payload + 50% fuel remaining
for landing.

### §5.2.6 Arrested Landing
*[Raymer, p. 134]*

Carrier landings use cable-and-drum "arresting gear" caught by a tailhook. Carrier approach speed
(1.2× stall) equals touchdown speed — no flare, pilots fly straight into the deck (allows a bolter/
go-around if the hook misses a cable).

**Fig. 5.6 — Arresting gear weight limits** *[Raymer, Fig. 5.6, p. 134]*. Engagement speed (kt,
0–150) vs. maximum landing weight (10³ lb, 0–100) for the Mark 7 arresting gear, Mods 1/2/3, each
roughly flat then decreasing, terminating at its own max-weight limit *(read from plot)*:

| Max landing weight (10³ lb) | Mod 3 (kt) | Mod 2 (kt) | Mod 1 (kt) |
|---|---|---|---|
| 0 | 133 | 122 | 122 |
| 20 | 133 | 122 | 122 |
| 40 (cutoff Mod 1) | 133 | 118 | 106 (cutoff) |
| 50 (cutoff Mod 3/2) | 118 (cutoff) | 112 (cutoff) | — |

(Mod 1 max landing weight ≈ 40×10³ lb; Mod 2 ≈ 47×10³ lb; Mod 3 ≈ 51×10³ lb — read at each curve's
terminal point/arrow.) Use this figure to find allowable approach speed for a first-guess landing
weight; divide by 1.2 for stall speed, then estimate `W/S` from Eq. (5.6).

### §5.2.7 Wing Loading for Cruise
*[Raymer, p. 134]*

The `W/S` that maximizes cruise range is usually far higher than stall/other constraints allow (too
small a wing to fly safely) — but computing it is informative and may motivate more sophisticated
flaps to permit a smaller, more cruise-optimal wing. Requires `C_D0` (zero-lift drag coefficient: ≈
0.015 jet, 0.02 clean prop, 0.03 dirty fixed-gear prop) and Oswald span efficiency `e` (≈ 0.6–0.8
fighter, 0.8 others, during cruise) — both detailed in Chapter 12; derivations of the range/loiter
equations below are in Chapter 17.

A propeller aircraft gets maximum range flying at best `L/D`, where parasite drag = induced drag:

**Eq (5.12)** *[Raymer, Eq. (5.12), p. 135]*:
```
q*S*C_D0 = q*S*C_L^2/(pi*AR*e)
```
Substituting `C_L = (W/S)/q` (cruise: lift = weight) gives the wing loading for max prop range:

**Eq (5.13)**, Maximum prop range *[Raymer, Eq. (5.13), p. 135]*:
```
W/S = q*sqrt(pi*AR*e*C_D0)
```
As fuel burns, weight (and hence optimal `W/S`) falls; maintaining optimal cruise means reducing
dynamic pressure `q` by the same percent — done via a **cruise-climb** (climbing to lower density
rather than slowing down).

A jet maximizes range at a higher speed than best-`L/D` speed (jet thrust isn't much affected by
speed and may improve), where parasite drag = 3× induced drag:

**Eq (5.14)**, Maximum jet range *[Raymer, Eq. (5.14), p. 135]*:
```
W/S = q*sqrt(pi*AR*e*C_D0/3)
```

### §5.2.8 Wing Loading for Loiter Endurance
*[Raymer, p. 136]*

Most missions include some loiter (typically ~20 min before landing); unless loiter is a substantial
fraction of the mission, it's better to optimize `W/S` for cruise instead — but the loiter-optimal
value is still worth computing. Jets loiter best at max `L/D` (same condition as best-range cruise):

**Eq (5.15)**, Maximum jet loiter *[Raymer, Eq. (5.15), p. 136]* (repeats Eq. 5.13):
```
W/S = q*sqrt(pi*AR*e*C_D0)
```
Props loiter best where induced drag = 3× parasite drag (also the min-power condition):

**Eq (5.16)**, Maximum prop loiter *[Raymer, Eq. (5.16), p. 136]*:
```
W/S = q*sqrt(3*pi*AR*e*C_D0)
```
If loiter altitude isn't specified, pick the altitude for best SFC at the loiter power setting —
typically 30,000–40,000 ft {~10,000 m} for jets, or the piston turbocharger's critical altitude (sea
level if unsupercharged). If loiter velocity isn't specified: assume ≈150–200 kt {~325 km/h} for
turboprops/jets, ≈80–120 kt {~180 km/h} for prop aircraft. The resulting average-loiter `W/S` must be
divided by (average loiter weight ÷ takeoff weight) — assume ≈0.85 absent better data — to get
takeoff `W/S`. Loiter-only optimization is rare; usually `W/S` is set by cruise or other requirements
and loiter is a secondary check.

### §5.2.9 Instantaneous Turn
*[Raymer, p. 137]*

Turn rate decides most air-to-air dogfights; a 2°/s turn-rate advantage is usually considered
significant. **Sustained** turn rate = the rate at which available thrust exactly balances drag
(maintains speed/altitude). **Instantaneous** turn rate = the max rate attainable (ignoring resulting
speed/altitude loss), limited by wing stall or structural load limit.

**Load factor** (g-loading) `n` = lift / weight; level unturning flight has `n = 1`. In a level turn,
1g of lift holds the aircraft up, leaving `g·sqrt(n²−1)` of radial acceleration available (Fig. 17.4).
Turn rate = radial acceleration ÷ velocity:

**Eq (5.17)** *[Raymer, Eq. (5.17), p. 137]*:
```
psi_dot = g*sqrt(n^2 - 1)/V     [rad/s; multiply by 57.3 for deg/s]
```

**Eq (5.18)** *[Raymer, Eq. (5.18), p. 137]* (radial-acceleration relation underlying Eq. 5.17):
```
V*psi_dot = g*sqrt(n^2 - 1)
```
Fighters were historically designed to limit load factor 7.33 g at combat weight; newer fighters use
8 g. **Corner speed**: the speed at which max available lift exactly equals the allowable load
factor — gives max turn rate for that aircraft/altitude; modern fighters: corner speed ≈300–350 kt
{550–650 km/h} indicated airspeed (i.e. fixed `q`), largely altitude-independent.

Solving Eq. (5.17) for load factor at a specified turn rate:

**Eq (5.19)** *[Raymer, Eq. (5.19), p. 138]*:
```
n = sqrt((psi_dot*V/g)^2 + 1)
```
(If this exceeds the design's ultimate load factor, the requirement is inconsistent with the
airframe.) Solving Eq. (5.18) for wing loading:

**Eq (5.20)** *[Raymer, Eq. (5.20), p. 138]*:
```
W/S = q*C_Lmax/n
```
The only unknown is combat `C_Lmax` (not the same as landing `C_Lmax` — full flaps unavailable in
combat, and Mach effects reduce max lift at speed; often limited by buffet/controllability). Initial
estimate: 0.6–0.8 for a simple-trailing-edge-flap fighter; 1.0–1.5 for a fighter with deployable
combat leading+trailing-edge flaps (better methods: Chapter 12).

Resulting `W/S` must be divided by (combat weight ÷ takeoff weight) to reach takeoff `W/S`. Absent
other data, combat weight ≈ 0.85× takeoff weight for most fighters (external tanks dropped, 50%
internal fuel burned).

### §5.2.10 Sustained Turn
*[Raymer, p. 139]*

Sustained turn rate also decides fights (e.g., two aircraft passing and turning back toward each other
over ~10 s — whichever slows below corner speed first is at a disadvantage). Usually specified as a
maximum sustainable load factor at a flight condition (e.g., sustain 4–5g at Mach 0.9, 30,000 ft
{9,144 m}).

At constant speed, thrust = drag, and lift = weight × n:

**Eq (5.21)** *[Raymer, Eq. (5.21), p. 139]*:
```
n = (T/W)*(L/D)
```
Sustained load factor is maximized by maximizing `T/W` and `L/D`; best `L/D` (Eq. 5.12) with `C_L =
n·(W/S)/q` gives:

**Eq (5.22)** *[Raymer, Eq. (5.22), p. 139]*:
```
W/S = (q/n)*sqrt(pi*AR*e*C_D0)
```
(reduces to Eq. 5.13 when `n = 1`). This is the `W/S` that maximizes sustained turn rate *regardless
of available thrust* — often unrealistically low (would meet the turn requirement using only a
fraction of available thrust).

The `W/S` that *exactly* meets a required sustained load factor using *all* available thrust: equate
thrust and drag with `C_L = n·(W/S)/q`:

**Eq (5.23)** *[Raymer, Eq. (5.23), p. 139]*:
```
T = q*S*C_D0 + q*S*(n^2*(W/S)^2)/(pi*AR*e)
```

**Eq (5.24)** *[Raymer, Eq. (5.24), p. 139]*:
```
T/W = (q*C_D0)/(W/S) + (n^2/(W/S)) * (W/S)^2/(q*pi*AR*e)
```
*(as printed: `T/W = q·C_D0/(W/S) + (W/S)·n²/(q·π·AR·e)`)*

Solved for `W/S` (quadratic):

**Eq (5.25)** *[Raymer, Eq. (5.25), p. 140]*:
```
W/S = [ (T/W) ± sqrt( (T/W)^2 - 4*n^2*C_D0/(pi*AR*e) ) ] / ( 2*n^2/(q*pi*AR*e) )
```
`T/W` here is at combat conditions — adjust takeoff `T/W` by dividing by (combat weight/takeoff
weight) and multiplying by (combat thrust/takeoff thrust). If the radicand goes negative, there is no
solution at any `W/S`, requiring:

**Eq (5.26)** *[Raymer, Eq. (5.26), p. 140]*:
```
T/W >= 2*n*sqrt(C_D0/(pi*AR*e))
```
Caution: `e` itself depends on `C_L` (separation effects can degrade effective `e` by 30%+ at high
angle of attack), so these turn equations are very sensitive to the assumed `e`; if results are far
from historical `W/S`, the assumed `e` is probably unrealistic and results should be discounted
(Chapter 12 accounts for separation better).

### §5.2.11 Climb and Glide
*[Raymer, p. 140]*

Appendix F lists climb requirements (rate of climb under various engine-out/gear/flap combinations)
for FAR/military aircraft. Climb gradient `G` = vertical/horizontal distance ratio; at normal climb
angles (Chapter 17):

**Eq (5.27)** *[Raymer, Eq. (5.27), p. 140]*:
```
G = (T - D)/W
```

**Eq (5.28)** *[Raymer, Eq. (5.28), p. 140]*:
```
D/W = T/W - G
```
Expanding `D/W` with `C_L = (W/S)/q`:

**Eq (5.29)** *[Raymer, Eq. (5.29), p. 141]*:
```
D/W = q*C_D0/(W/S) + (W/S)/(q*pi*AR*e)
```
Equating Eqs. (5.28)/(5.29) and solving for `W/S`:

**Eq (5.30)** *[Raymer, Eq. (5.30), p. 141]*:
```
W/S = [ ((T/W) - G) ± sqrt( ((T/W) - G)^2 - 4*C_D0/(pi*AR*e) ) ] / ( 2/(q*pi*AR*e) )
```
`T/W` must correspond to the flight condition/weight in question; result must be ratioed to takeoff
weight. The radicand cannot go negative, requiring:

**Eq (5.31)** *[Raymer, Eq. (5.31), p. 141]*:
```
T/W >= G + 2*sqrt(C_D0/(pi*AR*e))
```
i.e. no matter how clean the aircraft, `T/W` must exceed the climb gradient itself — a very clean,
high-speed, low-`T/W` design will climb poorly (e.g. a 200-mph/20-hp airplane cannot out-climb a
200-mph/200-hp one unless it is ~10× lighter).

`C_D0`/`e` for flapped/geared climb segments (per Appendix F) need flap/gear increments (better
methods: Chapter 12); rough approximations: takeoff flaps: `ΔC_D0 ≈ +0.02`, `e` down ≈5%; landing
flaps: `ΔC_D0 ≈ +0.07`, `e` down ≈10% (both relative to no-flap values); gear down: `ΔC_D0 ≈ +0.02`
[Ref. 15].

For an engine-out climb, reduce `T/W` accordingly (e.g. a 3-engine aircraft losing one engine has
2/3 of nominal `T/W`); the windmilling/stopped engine's added drag further reduces climb rate
(Chapter 12 methods; can be neglected for rough initial analysis).

Eq. (5.30) also gives the `W/S` for a specified **glide** angle: set `T/W = 0` and use a negative `G`
(glide = climb in the negative direction). For a specified sink rate, `G` = sink rate ÷ forward
velocity (consistent units).

### §5.2.12 Maximum Ceiling
*[Raymer, p. 142]*

Eq. (5.30) with `G = 0` gives `W/S` for level flight at a desired (service) ceiling, given `T/W` there.
If a small residual climb rate is required at ceiling (e.g. 100 ft/min {30.5 m/min}, the "service
ceiling" definition), first convert that climb rate to a gradient `G` (rate ÷ forward velocity) and
use it in Eq. (5.30).

For very-high-altitude aircraft (e.g. atmospheric research/recon), low dynamic pressure can itself set
a floor on `W/S` — e.g. at 100,000 ft {30,480 m}, Mach 0.8, `q ≈ 10 psf` {0.5 kN/m²}. Eq. (5.13)
repeated for minimum-power wing loading:

**Eq (5.32)** *[Raymer, Eq. (5.32), p. 142]* (restates Eq. 5.13):
```
W/S = q*sqrt(pi*AR*e*C_D0)
```
If this suggests an impractically low `W/S`, compare against the `W/S` implied by flying at a chosen
design lift coefficient:

**Eq (5.33)** *[Raymer, Eq. (5.33), p. 142]*:
```
W/S = q*C_L
```
For efficient high-altitude cruise, `C_L` should be near the airfoil's design `C_l` (~0.5 for a
typical airfoil; new high-lift high-altitude airfoils reach design `C_l` ≈ 0.95–1.0).

## Selection of Thrust to Weight and Wing Loading
*[Raymer, p. 142]*

Procedure: pick an initial `T/W` (or `P/W`), compute the required `W/S` for every applicable
performance requirement (§5.2.2–§5.2.12), convert all results to takeoff conditions, and select the
**lowest** `W/S` (ensures the wing is big enough for every requirement). A very low `W/S` driven by a
single outlier requirement may indicate that requirement should be reconsidered, or that the design
itself should change (e.g. add more sophisticated flaps to permit a higher `W/S`). The "optimal"
`W/S` values from Eqs. (5.13)–(5.16), (5.22), and (5.32) are aerodynamic optima, not hard
requirements — ignore them if they drive `W/S` to unreasonable values.

Once `W/S` is chosen, recheck `T/W` against every requirement that depends on it, using the selected
`W/S`. If one requirement (e.g. stall speed) forces an obviously low `W/S` on its own, compute that
first and use it to solve the `T/W`-dependent equations, in the same manner.

`W/S`/`T/W` can alternatively be selected via carpet plot or other pre-layout optimization (Chapter
19) using pre-layout coefficient/weight estimates — the author considers this often not worth the
effort: push to a first ("Dash-One") layout quickly, then optimize using coefficients taken from the
real design geometry. If a good pre-layout optimization tool exists for the aircraft class, it may be
used, but should be re-validated against the completed layout's actual parameters. These initial
`W/S`/`T/W` values are used only to start the first layout; a full post-layout optimization supersedes
them.

---
**Chapter 5 extraction complete.** §§5.1–5.2 (incl. all named subsections through Selection of T/W
and Wing Loading), Tables 5.1–5.5, Figs 5.1–5.6, Eqs (5.1)–(5.33). No chapter-end numbered reference
list appears in this chapter's own pages (in-text citations `[6]`, `[13]`–`[15]` refer to the book's
consolidated end-of-book bibliography, not reproduced here). Next: Chapter 6 — Initial Sizing.
