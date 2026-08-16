# Chapter 19 — Sizing and Trade Studies

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 19
"Sizing and Trade Studies," printed pp. 709–734 (PDF index 740–765).

Refines the Chapter 6 quick-sizing method using the as-drawn design's real aerodynamics/propulsion/
weights, then covers classical carpet-plot optimization and modern multivariable/MDO methods. Figures
19.1–19.6 are a fully worked numeric fighter sizing-matrix/carpet-plot example — the actual design
numbers are digitized below since they are load-bearing for understanding the method.

---

## §19.1 Introduction

Having gone from rough conceptual sketch → quick-and-dirty sizing (T/W, W/S, takeoff/fuel weight) →
full design layout → detailed aero/weights/propulsion/structures/stability/performance/cost analysis,
the as-drawn aircraft's refined numbers differ from the early crude estimates — so the previously
selected T/W, W/S, aspect ratio, sweep, taper, etc. are probably not optimal. This chapter revisits
sizing with the design's now-much-better-known characteristics, to produce the "Dash-Two" drawing.

## §19.2 Detailed Sizing Methods

Repeats the Chapter 17 equations of motion as the basis for high-fidelity industry sizing/performance
codes [Raymer, Eq. (19.1)–(19.5), p. 710] — identical in form to Ch. 17 Eqs. (17.1)–(17.5):

```
ΣFx = T cos(α+φT) − D − W sinγ                                          (19.1)
ΣFz = T sin(α+φT) + L − W cosγ                                          (19.2)
Ẇ = −C T                                                                (19.3)
C = Cpower(V/550ηp) = Cbhp(V/ηp)          [piston equivalent SFC]        (19.4)
T = Pηp/V = 550 bhp ηp/V                                                (19.5)
```

Industry sizing programs fly the actual mission in very short segments (<1 min), computing real drag
→ required thrust → actual fuel flow at each step; iterate assumed takeoff weight until the resulting
empty-weight fraction matches a detailed weight estimate (sophisticated versions auto-recompute
allowable empty weight for each trade variation of takeoff weight, wing area, thrust, AR, etc.). Such
programs are beyond this book's scope, but are the tools of professional sizing/performance
specialists — accurate enough for certification/flight-manual work, if unwieldy for conceptual design.

## §19.3 Improved Conceptual Sizing Methods

### §19.3.1 Review of Sizing Method

Recaps the Chapter 6 iterative method: assume takeoff weight → statistical empty-weight fraction →
mission broken into segments 1…x, each reducing aircraft weight by either a mission-segment weight
fraction `Wi/Wi-1` (fuel burn) or a discrete weight drop (payload release) → total fuel summed +6%
reserve/trapped-fuel allowance → calculated takeoff weight (payload+crew+fuel+empty) compared against
the assumed value → iterate. The refinements below replace the *statistical* fuel/empty-weight
estimates with values computed from the as-drawn design.

Fuel burned over a segment of duration `d` at thrust `T`, SFC `C`; mission-segment weight fraction
[Raymer, Eq. (19.6)–(19.7), p. 712]:

```
Wfi = C T d                                                             (19.6)
Wi/Wi-1 = 1 − C d (T/W)i                                                (19.7)
```
(`C`, `(T/W)i` = average actual values during segment `i`.) For **rubber-engine** sizing, `(T/W)i`
stays essentially constant across takeoff-weight iterations, so Eq. (19.7)'s result carries over
unchanged; for **fixed-engine** sizing, `T/W` changes with weight each iteration, so either recompute
Eq. (19.7) each time, or use Eq. (19.6) directly (fixed thrust → fixed fuel burned) and treat that fuel
as a discrete weight drop.

**Caution**: segment weight fractions should be ~0.9–1.0 — below 0.9, split the segment further; a
computed fraction above 1.0 signals a unit or sign error.

### §19.3.2 Engine Start, Warmup, and Taxi

Previously lumped with takeoff at an assumed 0.97–0.99 fraction. Better: use actual engine data for
fuel burned over an assumed duration (typically 15 min at idle power) via Eq. (19.7).

### §19.3.3 Takeoff

Segment durations from the Chapter 17 takeoff-distance breakdown (segment distance / average
velocity) feed Eq. (19.7) with appropriate average takeoff thrust/SFC. Sometimes design requirements
lump start+warmup+taxi+takeoff into one time-at-thrust spec: military combat aircraft — 5 min at
max dry power; transports/commercial — 14 min at ground idle + 1 min at takeoff thrust (common
historical spec values).

### §19.3.4 Climb and Acceleration

Reuses the Chapter 17 energy-method mission-segment weight fraction [Raymer, Eq. (19.8)–(19.9),
p. 713] (= Ch.17 Eq. 17.97):

```
Wi/Wi-1 = exp[ −C Δhe / (V(1 − D/T)) ]                                   (19.8)
Δhe = Δ(h + V²/(2g))                                                     (19.9)
```
(average `C`, `V`, `D`, `T` over the segment; break long climbs/large ΔV into pieces so
`C/[V(1−D/T)]` stays roughly constant.) Climb horizontal distance is normally "credited" to the
following cruise leg (subtracted from required cruise range); distance = average velocity × time to
climb = `Δhe/Ps`.

### §19.3.5 Cruise and Loiter

Breguet-based mission-segment weight fractions [Raymer, Eq. (19.10)–(19.11), p. 713]:

```
Cruise:  Wi/Wi-1 = exp[ −R C / (V(L/D)) ]                                (19.10)
Loiter:  Wi/Wi-1 = exp[ −E C / (L/D) ]                                   (19.11)
```
Eq. (19.10) is for a cruise-climb; constant-altitude/airspeed cruise instead needs shorter segments
with `L/D` revised as weight drops. Headwind: inflate required cruise range `R` by
`Vairspeed/Vgroundspeed` in Eq. (19.10) while still using actual airspeed for `V` (Ch. 17); loiter is
wind-independent.

### §19.3.6 Combat and Maneuver

Fighters sized to an air-combat-time requirement (explicit, e.g. "5 min at max thrust, 30,000 ft,
Mach 0.9," or stated as a number of turns at combat conditions, whose time is computed via Chapter 17
performance methods) — then Eq. (19.7) applies directly.

### §19.3.7 Descent

Previously a pure statistical fraction with no range credit. Refined: descent is "negative climb"
(thrust < drag); the Chapter 17 climb-rate equation, repeated as [Raymer, Eq. (19.12), p. 714]:

```
Vv = V[(T/W) − ρV²CD0/(2(W/S)) − 2K(W/S)/(ρV²)]                          (19.12)
```
usually flown at cruise velocity, idle power (unless that gives an excessive descent angle
`arcsin(Vv/V)`). Time-to-descend from `Vv`; mission-segment weight fraction via Eq. (19.7). Long
descents should be segmented; range credit should be taken unless requirements exclude it. Raymer
notes the detailed method is "probably more trouble than it's worth" for quick/student studies — the
earlier historical statistical method [Eq. (6.22)] is usually good enough.

### §19.3.8 Landing

Previously approximated as `Wi/Wi-1` = 0.992–0.997 — "probably good enough even for more refined
sizing" (obstacle-clearance-to-full-stop takes <1 min, mostly idle power; thrust reversers run only
~10 s, negligible fuel impact). If more accuracy wanted: time from the Chapter 17 landing-distance
segments (average velocity per segment) into Eq. (19.7).

### §19.3.9 Empty-Weight Estimation and Refined Sizing

With a design layout in hand, Chapter 15's detailed component-buildup weight methods replace the
purely-statistical (takeoff-weight-only) empty-weight estimate. First refined iteration: assumed
takeoff weight = as-drawn takeoff weight, empty weight = as-drawn empty weight, fuel from the refined
methods above (+6% reserve/trapped allowance). The resulting calculated takeoff weight generally
won't equal the as-drawn value (which came from crude initial sizing) — iterate with a new assumed
takeoff weight.

Recomputing empty weight from full Chapter 15 component buildup at every iteration step is
prohibitively slow without a computer. Approximate manual method: adjust the as-drawn empty-weight
*ratio* along the Chapter 3 historical trend slope (`We/Wo` decreasing with increasing `Wo`, Fig. 3.1)
[Raymer, Eq. (19.13), p. 715]:

```
We = We,as-drawn · [ Wo / Wo,as-drawn ]^(1+c)                            (19.13)
```
`c` = the empty-weight-ratio trend-line slope from Table 3.1 (Chapter 3), typically ≈ −0.1, so
`(1+c)` ≈ 0.9 (empty-weight fraction falls as assumed takeoff weight rises). `c` can instead be
derived from your own concept: perturb `Wo` (e.g. +10%), fully recompute `We` (wing/tail area, fuselage
size, gear, engine — all scaled), then solve Eq. (19.13) for `c`.

Then re-run the Chapter 6 sizing method with these improved fuel/empty-weight estimates. If the
resulting sized weight differs substantially from the as-drawn weight (Raymer: gets "nervous" beyond
~30% difference), redraw/reanalyze/resize the aircraft rather than trust the extrapolation.

### §19.3.10 Photo-Scale Problem

Sizing scales the whole aircraft up/down; this can silently invalidate the aero/weights values taken
from the original drawing. **Propulsion**: fixed engine → propulsion literally unchanged; rubber
engine → scaled to preserve T/W, SFC unchanged either way — propulsion isn't really a problem.
**Aerodynamics**: coefficients are non-dimensionalized on wing area, which scales with the design —
wetted area and max cross-section area (the key drag drivers) scale proportionally under true
photographic scaling, so aero coefficients from the drawing remain valid to a good approximation *as
long as the sizing result stays within ~10–20% of the as-drawn TOGW*.

Beyond that range, **true photo-scaling breaks down (square-cube law)**: halving TOGW should halve
wing area (same W/S) — a length scale of √(1/2) — but internal volume scales as length³ =
(1/2)^1.5 ≈ 0.354, i.e. volume drops faster than weight, so something (usually the fuselage) must be
made relatively larger than pure photo-scaling would give. In extreme cases the fuselage floor can't
shrink at all (passengers/crew/cargo/galleys/lavatories are fixed-size) — a real parametric future-
airliner study [12] found TOGW sizing down to 50% of baseline while the cabin literally couldn't
shrink, so drag coefficient (referenced to the now-smaller wing) actually *increased* as TOGW fell.

Proper fix: redraw the aircraft at each sizing "guess" (what sophisticated in-house programs do
internally). Practical approximation for parasitic drag, adjusting for the wetted-area fraction `X`
that will *not* photo-scale (typically the fuselage) [Raymer, Eq. (19.14), p. 717]:

```
CD0 = (1−X) CD0 + X CD0 / (Wo/Wo,as-drawn)^0.666                          (19.14)
```
Example given: sizing to 50% of TOGW with X=35% non-scaling wetted area takes a 100-count `CD0` to
120 counts.

The same effect distorts the empty-weight scaling slope: the future-transport study's typical-
transport exponent `c = −0.06` (Table 3.1) became `c = −0.31` once the fixed-fuselage-size constraint
was properly modeled — a "huge difference." For most design work (certainly student projects) the
photo-scale problem can be ignored; it matters mainly in extreme trade studies or when initial sizing
was so far off a fresh start is warranted anyway.

## §19.4 Classic Optimization — Sizing Matrix and Carpet Plots

### §19.4.1 Improving the Dash-One

Sizing (§19.3) only ensures the properly-rescaled as-drawn aircraft meets its *range* requirement —
not that it meets performance requirements, nor that its design parameters (T/W, W/S, AR, sweep,
fineness ratio, etc., originally picked from quick calculations/trend lines) are optimal. Rather than
hit-or-miss manual adjustment, formal optimization is used.

The **Kuhn–Tucker theorem** (1950) underlies most analytical-optimization proofs: at the optimum, the
only directions that improve the objective function are ones that violate a constraint — i.e., the
designer is always chasing minimum weight but blocked by performance-constraint lines. Classic
aircraft optimization is parametric: vary a few parameters, compute the sizing/performance/cost
effect of each combination, then graphically extract the optimum (modern methods do this
numerically, same underlying idea).

### §19.4.2 Sizing Matrix Plot

The classic two-variable method is the **"carpet plot"** (two graphical formats, same underlying
data) — usually on **T/W** and **W/S**. Procedure: vary T/W and W/S parametrically from the as-drawn
baseline (typically ±20%), independently size + performance-analyze each combination (a "sizing
matrix").

**Fig. 19.1 — Sizing matrix (worked example, small fighter)** *[Raymer, Fig. 19.1, p. 719]* — 3×3
matrix of T/W (0.9, 1.0, 1.1) × W/S (50, 60, 70 psf / 244, 293, 342 kg/m²), each cell giving sized
`Wo`, specific excess power `Ps` (at Mach 0.9, 30 kft, 5g), takeoff distance `sTO`, and acceleration
time `a` (Mach 0.9→1.5). Requirements: `Ps ≥ 0` at Mach 0.9/30 kft/5g; `sTO ≤ 500 ft`;
acceleration ≤50 s. *(full data table reproduced from the figure)*:

| Cell (T/W, W/S) | Wo (lb) | Ps (fps) | sTO (ft) | accel (s) |
|---|---|---|---|---|
| 1 (1.1, 50) | 56,000 | 700 | 340 | 46 |
| 2 (1.1, 60) | 49,000 | 330 | 430 | 39 |
| 3 (1.1, 70) | 46,000 | 30 | 660 | 42 |
| 4 (1.0, 50) | 48,500 | 430 | 450 | 50.5 |
| 5 (1.0, 60) ["resized baseline"] | 43,700 | 30 | 595 | 45 |
| 6 (1.0, 70) | 42,000 | −190 | 800 | 47 |
| 7 (0.9, 50) | 44,000 | 140 | 670 | 56 |
| 8 (0.9, 60) | 39,000 | −230 | 810 | 53 |
| 9 (0.9, 70) | 36,000 | −320 | 1010 | 51 |

(Note: OCR cell/label alignment reconstructed from the figure's printed layout — `[verify p.719,
Fig. 19.1]` for exact number-to-cell mapping if used quantitatively; values are internally consistent
with the trends discussed in the prose, e.g. cell 5 = "resized baseline," cell 3 heaviest but meets
everything, cells 4/7/8/9 lighter but deficient in some requirement.)

As-drawn baseline (cell 5) meets everything except takeoff distance; cell 3 exceeds all requirements
but is heaviest; cells 4, 7, 8, 9 are lighter but each misses some requirement. Question: what
T/W–W/S combination meets *all* requirements at *minimum* weight?

**Fig. 19.2 — Sizing matrix crossplots** *[Raymer, Fig. 19.2, p. 720]* — for each T/W, sized `Wo`,
`Ps`, and `sTO` plotted vs W/S, with the 9 matrix points overlaid; regularly-spaced (5000-lb
increment) `Wo` values are read off each curve to get corresponding W/S values (circled points), and
separately the exact-W/S-for-each-requirement points are read off the `Ps`/`sTO`/acceleration curves.
No further numeric table — this is a graphical-interpolation step, not new data.

**Fig. 19.3 — Sizing matrix plot (continued)** *[Raymer, Fig. 19.3, p. 721]* — the W/S–T/W points for
constant-`Wo` increments (from Fig. 19.2) transferred to a T/W-vs-W/S graph and connected into
constant-takeoff-weight contour lines (T/W axis 0.9–1.10, W/S axis 45–75, contours labeled 40K/45K
lb). *(read from plot, approximate contour shape)*:

| W/S | T/W on 40K-lb contour | T/W on 45K-lb contour |
|---|---|---|
| 50 | ~0.93 | ~1.02 |
| 60 | ~0.97 | ~1.05 |
| 70 | ~1.02 | ~1.09 |

(Illustrative digitization of the worked example's constant-weight contours; the qualitative
takeaway — weight contours slope upward with W/S — matters more than the exact numbers.)

**Fig. 19.4 — Sizing matrix plot (concluded)** *[Raymer, Fig. 19.4, p. 722]* — the same T/W-vs-W/S
axes now overlaid with the **constraint lines** (W/S, T/W combinations exactly meeting each
performance requirement — takeoff distance, `Ps`, acceleration), each shaded on the infeasible side.
The optimum (lightest feasible combination) is found by inspection, typically at a two-constraint
intersection. No separate numeric table (constraint-line intersection is read graphically off the
constructed figure).

For better accuracy, industry practice uses 5×5 or larger sizing matrices (more work, finer
resolution) instead of this 3×3 teaching example.

### §19.4.3 Carpet Plot

Alternative, equivalent-data graphical format: superimpose the `Wo`-vs-`W/S` curves for each T/W,
horizontally offsetting each successive curve's axis by an arbitrary shift (Fig. 19.5) so the
resulting family of curves visually resembles a woven carpet; regularly-spaced W/S points (e.g.
50/60/70 psf) on each curve are then connected across curves, letting W/S be read by interpolation
without needing the shifted axis labels at all.

**Fig. 19.5 — Carpet plot format (same results!)** *[Raymer, Fig. 19.5, p. 723]* — three-panel
build-up: (top) `Wo` vs `W/S` for T/W=1.1, points 1/2/3 at W/S=50/60/70 (Wo ≈ 56K/49K/46K lb, matching
Fig. 19.1 cells 1/2/3); (middle) T/W=1.0 curve added with a shifted axis, points 4/5/6 at
W/S=50/60/70 (Wo ≈ 48.5K/43.7K/42K lb, matching cells 4/5/6); (bottom) T/W=0.9 curve added with
another shift, points 7/8/9 at W/S=50/60/70 (Wo ≈ 44K/39K/36K lb, matching cells 7/8/9) — connecting
same-W/S points across the three curves produces the "carpet" mesh.

**Fig. 19.6 — Completed carpet plot** *[Raymer, Fig. 19.6, p. 723]* — the carpet mesh with
performance-constraint curves (from Fig. 19.2's exact-requirement points) overlaid; optimum = lowest
point on the carpet that satisfies all constraints, usually at a constraint intersection. No
additional numeric table (same underlying data as Figs. 19.1–19.4, different graphical presentation).

Cost can replace weight as the plotted measure of merit using the identical procedure (cost values
instead of weight values) — but for most aircraft types, minimizing weight also minimizes cost for a
given design concept, so a separate cost-carpet is often unnecessary.

## §19.5 Trade Studies

### §19.5.1 Trade Study Categories

Trade studies answer "what if...?" design questions; proper selection/execution is as important as a
good layout or correct sizing. The T/W–W/S carpet plot is the foundational trade study (so
fundamental it's often not even labeled as one).

**Table 19.1 — Typical Trade Studies** *[Raymer, Table 19.1, p. 724]*

| Design trades | Requirements trades | Growth Sensitivities |
|---|---|---|
| T/W and W/S | Range/payload/passengers | Dead weight |
| AR, Λ (aspect ratio, sweep) | Loiter time | CD0 |
| t/c, Λ | Speed | K |
| Airfoil shape and camber | Turn-rate, Ps, nmax | CD,wave |
| High-lift devices | Runway length | CLmax |
| Fuselage fineness ratio | Time-to-climb | Thrust |
| BPR, OPR, TIT, etc. | Signature level | SFC |
| Propeller diameter | Design-to-cost | Fuel price |
| Materials | | |
| Configuration | | |
| Tail type | | |
| Variable sweep | | |
| Number and type of engines | | |
| Maintainability features | | |
| Observables | | |
| Passenger arrangement | | |
| Advanced technologies | | |

**Design trades** reduce weight/cost for a given mission/performance requirement set (wing geometry,
propulsion, configuration arrangement variations). **Requirements trades** find the sensitivity of the
design to requirement changes — if one requirement forces a disproportionate weight/cost penalty, the
customer may relax it. **Growth-sensitivity trades** show how much takeoff weight grows if a parameter
(drag, SFC, etc.) turns out worse than assumed — usually plotted as %-change-in-parameter (x-axis) vs
%-change-in-Wo (y-axis) on one combined chart.

**"Dead weight"** is a catch-all growth-sensitivity trade for unplanned empty-weight growth (heavier
structure, larger tires, more avionics, a new technology that turned out heavier in practice than in
the lab, ballast for balance problems). It quantifies design sensitivity to such later-discovered
weight growth — hopefully caught (and shown to be small) before it happens, since a finished aircraft
on scales has, by definition, zero "dead weight" left to allocate.

**Realism factor** — a critical caveat: designers may under-model the true impact of a trade (e.g.,
"stuff in" two more missiles without changing the external lines) — if the baseline had that much
spare internal volume, the *baseline* was poorly designed; if the baseline was tight, the revised
layout claiming no size change is not credible. Discipline: require all trade-study layouts to
preserve the same **internal (volumetric) density** — takeoff weight / internal volume — as the
baseline (historically enforced informally by customer organizations like NAVAIR via undisclosed
trend charts). Raymer's own more rigorous "**Net Design Volume**" method [137] formalizes this check
for computerized optimization with minimal extra required inputs.

Crucially, **every** other trade-study variable (Table 19.1) should be evaluated via a *complete*
T/W–W/S carpet plot at each data point — otherwise the answer may just reflect a non-optimal starting
T/W/W/S rather than the true effect of the variable under study. E.g. to optimize aspect ratio: vary
AR ±20% from baseline (say 3 values), run a full carpet-plot optimization at each AR, then plot the
resulting minimum weights vs AR. For two variables (AR and sweep): a 3×3 matrix of AR/sweep values,
each requiring its own 3×3 (or finer) T/W–W/S carpet-plot optimization — 9×9 = 81 full aircraft
analyses (aero+propulsion+weights+sizing+performance) for just these 4 variables.

### §19.5.2 Multivariable/Multidisciplinary Design Optimization

Manual carpet-plotting doesn't scale: optimizing the basic 6-parameter set (T/W, W/S, AR, taper,
sweep, t/c) needs at least 3⁶=729 data points (5⁶=15,625 would be better) — plus a method to
interpolate the optimum across that many points (no way to draw a 6-D carpet plot by hand). Extending
to fineness ratio, BPR, propeller diameter, etc., or even allowing the optimizer to reshape the
geometry itself (planform breaks, nacelle/tail placement, airfoils, APU install) is possible in
principle but not generally worthwhile — time spent building/running/interpreting an "everything
optimizer" is time taken from other design tasks.

Deeper caveats: (1) optimization needs a defined measure of merit, which implicitly assumes we know
exactly how the aircraft will be flown — but essentially no aircraft ever flies its exact "design
mission" (weather, engine variability, and mid-development compromises all intervene), and many
aircraft end up flying missions never anticipated at design time (F-4: designed for supersonic
deck-launched interception, became a multirole fighter-bomber; F-16: designed as a "not a pound for
air-to-ground" lightweight dogfighter, became the USAF's main ground-attack fighter). (2) Automated
shape optimization risks losing track of real packaging constraints (landing gear, radar, passengers,
fuel volume, over-nose vision angle) unless painstakingly modeled — Net Design Volume approximates
this but isn't perfect. (3) A large sunk-cost optimization model creates a human bias against
considering design approaches the model can't represent ("probably won't work anyway").

Used carefully — always with an experienced designer in the loop, as one input among many feeding the
next design iteration (Chapter 2) — optimization remains very powerful.

Multivariable optimization techniques beyond repeated manual carpet plots:
- **Response surface**: fit multivariable parametric data to an approximating multi-dimensional
  surface equation, then solve mathematically/numerically for the optimum — the classic carpet plot
  is itself a graphically-fit 3-D (2-variable) response surface. Must use ≥3rd-degree (preferably
  4th/5th) fit terms or real surface reflexes get smoothed away and the "optimum" is wrong; higher
  degree costs more compute time. A further benefit: design points can be selected and analyzed
  *offline*, e.g. by real designers laying out dozens of full concepts spanning the parameter range,
  then fit to a response surface for the optimum search.
- **Latin squares** ("Design of Experiments" family, used at Boeing and others): a mathematical
  scheme for choosing which data points to *skip* and approximating what they would have shown —
  analogous to drawing a family of curves from just five data points.
- **Finite-difference / gradient search**: perturb each variable ±(step size) one at a time, use the
  measure-of-merit change to build a first-derivative "system response" slope per variable, use those
  derivatives to predict/iterate toward the optimum, tightening the step size as convergence
  approaches. Raymer reports good results with a simultaneous exhaustive-gradient search over the 6
  basic parameters [138]: vary each ± a step, keep the best feasible variant as the new baseline,
  repeat until no improvement, then shrink the step and repeat.
- **Multidisciplinary design optimization (MDO)**: per Sobieski (NASA Langley), "a methodology for
  design of complex engineering systems... governed by mutually interacting physical phenomena and
  made up of distinct interacting subsystems," suited to systems where "everything influences
  everything else" [138] — arguably a fair description of aircraft conceptual design itself, with even
  the basic sizing carpet plot qualifying as a (simple) MDO instance across aero/weights/propulsion/
  sizing/performance.
  - **Implicit Function Theorem method**: differentiate the governing equations to get sensitivity
    equations, assemble simultaneous linear algebraic equations, solve for the optimum.
  - **Decomposition**: partition the problem into coupled submodules (e.g. an aerodynamics module
    computing drag/airloads from wing shape, feeding a structures module computing weight/deflection
    from those airloads, iterating between them) managed by a top-level coordinating routine.
  - **Genetic algorithm**: code design variables as binary-string "genes"; start from a random
    population of designs, evaluate "fitness" (measure of merit), let the fittest "reproduce"
    (recombine gene fragments), iterate generations until the population converges (presumed, not
    guaranteed, to be an optimum — a subject of ongoing research) [139, 140].

A detailed overview of MDO/genetic-algorithm methods for conceptual design, including variable/
constraint selection and automatic geometry-realism revision, is given in Raymer [141].

### §19.5.3 Cost as the Measure of Merit

Sized takeoff weight is usually a good cost proxy for a *given* design approach (weight, especially
empty weight, strongly drives DAPCA-style cost), but is a poor proxy across *different* technologies/
engines/avionics/manufacturing methods, and life-cycle cost is heavily fuel-cost-driven — e.g. a
higher-AR wing is heavier (raising acquisition cost estimate) but saves fuel (lowering LCC); airlines
ultimately care about ROI/NPV (Chapter 18), not raw weight.

Substituting cost for weight on a carpet plot (or in multivariable/MDO optimizers) is straightforward
using DAPCA (empty weight → cost) plus separately-estimated avionics cost and fuel-usage ratioing from
sized fuel weight. Using the detailed WBS costing method (Chapter 18) instead is impractical for
optimization — the weight-to-hours relationship is unclear and the input/assumption burden is too
large; most companies use DAPCA (or an in-house equivalent) for conceptual-design trades/optimization
and reserve detailed WBS costing for final contract pricing.

Requirements-design co-development (Chapters 2–3) sometimes has a hard cost ceiling from the start.
**"Design-to-cost"**: a cost target that cannot be exceeded. **"Cost as an independent variable"
(CAIV)**, a stronger/more recent framing: the price is fixed — "now tell me what capability that
buys." A simple CAIV study parametrically varies mission range, computes sized takeoff weight (hence
acquisition cost) for each, and reads off the affordable range for the customer's cost ceiling.

**Fig. 19.7 — Cost-driven range trade** *[Raymer, Fig. 19.7, p. 731]* — purchase price ($26,000–
$32,000, thousands, i.e. $26M–$32M) vs range (300–700, presumably nmi), roughly-linear rising curve.
*(read from plot)*:

| Range | Purchase price ($M) |
|---|---|
| 300 | ~27.0 |
| 400 | ~28.0 |
| 500 | ~29.3 |
| 600 | ~30.5 |
| 700 | ~31.7 |

CAIV extends this logic through the entire design/development cycle: every change (fix or new
capability) is cost-assessed against the ceiling; management, engineering, and the customer all
commit to holding (and continuously driving down) cost, ideally cooperatively rather than
adversarially — as opposed to a customer who sets firm design-to performance requirements *and* an
uncompromising cost ceiling simultaneously (a red flag scenario Raymer notes wryly).

*Photo: NASA X-Wing hybrid helicopter (NASA photo), p. 732 — no plotted data.*

## What We've Learned

Optimization is a crucial part of aircraft design, showing how to improve the Dash-Two. Classical
carpet plots remain a useful tool; modern MDO methods, applied with real-world constraints, are even
more powerful.

*Photo: Gordon E. Raymer (test pilot, Cdr USN ret.) celebrating his 80th birthday flying an N2S
Stearman biplane like the one he trained in during 1945 (photo credit: D. Raymer), pp. 733–734 — no
plotted data.*

---

*Chapter 19 complete (§§19.1–19.5, Table 19.1, Figs 19.1–19.7, Eqs 19.1–19.14). The Fig. 19.1 sizing-
matrix cell/label alignment and the Fig. 19.3/19.7 curve readings were reconstructed from a
significantly OCR-degraded scan — flagged inline with `[verify p.NNN]` where precision is uncertain;
the underlying method and qualitative trends are unambiguous from the surrounding prose. This
completes the four-chapter Raymer extraction batch (Chapters 16–19).*
