# Chapter 10 — Propulsion and Fuel System Integration

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 10 "Propulsion and Fuel System Integration," printed pp. 275–336.

Covers propulsion-type selection, jet-engine sizing/scaling and the parametric statistical engine
models (§10.3.2, of direct interest to this repo's `PropL2`), inlet/nozzle/cooling integration,
propeller-engine and piston-engine integration, fuel-system/fuel-type reference data, and a survey of
alternative ("green") propulsion. All numbered equations, tables, and data-bearing figures captured;
this re-extraction of §10.3.2 is cross-checked directly against a page-image OCR pass (not just text
layer) and against the older, partly-garbled `reference_extracts/raymer_data.md` — see the flagged
comparison at the end of §10.3.2 below.

---

## §10.1 Introduction

Propulsion integration drives configuration layout as much as almost anything else: the engine is
one of the largest single weight/size items, and getting its geometry, mounting, inlet/nozzle, and
fuel-tank integration wrong on the first layout means the calculated thrust/drag are wrong and
aircraft weight will likely grow. Installed-performance calculation itself is deferred to Chapter 13;
electric propulsion to Chapter 20.

## §10.2 Propulsion Overview and Selection

Nearly all aircraft propulsion works by momentum transfer — accelerating a captured air massflow
rearward (propellers: rotating-wing blades with downwash; jets: pressure rise + nozzle acceleration).
Rockets are the exception (carry their own reaction mass, not an oncoming airflow — analytically
distinct, deferred to Ch. 21).

### Fig 10.1 — Propulsion system options
*[Raymer, Fig. 10.1, p. 276]* — Schematic gallery: piston-prop, turboprop, centrifugal turbojet,
axial-flow turbojet, turbofan (with bypass-air split shown), and an afterburner add-on (fuel spray +
flameholder bars downstream of the turbine) common to turbojet/turbofan. No plotted data.

### §10.2.1 Piston-Prop

Cheapest, best low-speed fuel economy, but heavy, noisy, and prop thrust inherently falls with
increasing speed. Propeller efficiency `ηp` = thrust power / engine (shaft) power, typically ≈80% for
a good design (the Wright Brothers' own propeller, ≈60% efficient via their own original strip-theory
design, was about double the efficiency of contemporary marine-derived designs). Physically: shaft
power is roughly constant with speed, so thrust power (= thrust × velocity) is roughly constant, so
thrust itself must fall as velocity rises — true even for a perfectly efficient propeller, and the
core reason piston-props lost favor for anything but the slowest aircraft once jets appeared.

### §10.2.2 Turbojet

Compressor + burner + turbine perform the three piston-engine functions continuously rather than
intermittently. **Centrifugal compressors** use centrifugal force to narrow the flow channel (more
tolerant of inlet distortion, but larger frontal area/drag and lower achievable pressure ratio);
**axial compressors** use blade aerodynamics (6–10 rotor/stator stage pairs typical; higher pressure
ratio, but distortion-intolerant — swirl/pressure variation can stall blades and flame out the
engine). Some smaller engines combine a centrifugal stage behind axial stages for a blended
compromise.

### §10.2.3 Turboprops and Turbofans

A pure turbojet is inefficient at lower speed (too small/fast an exhaust) because propulsive
efficiency favors accelerating a large air cross-section by a small amount (the same principle that
gives helicopters their large rotors — derived formally in Ch. 13). Adding a second turbine to extract
mechanical power from the exhaust, then applying that power to accelerate more outside air, improves
efficiency: a **turboprop** applies it to a conventional propeller (still common for commuter/business
aviation; the "prop-fan"/"unducted fan" and newer "open rotor" variants push propeller aerodynamics
toward near-sonic tip speed for better cruise speed — open rotor is projected at 10–30% better SFC
than a turbofan but ~10 dB noisier). A **turbofan** instead applies it to a ducted fan; the fan air is
split into a **bypass** stream (exits unburned, "supercharging" the core) and core-inlet flow. The
**bypass ratio** (mass-flow ratio of bypassed-to-core air) typically ranges 0.25 ("leaky turbojet") up
to 12 for current engines, with "ultra-high-bypass" studies reaching 20 (open rotor's effective bypass
ratio is 30+). Turbofans also cut noise (duct suppresses fan noise; lower fan-exit velocity weakens
noise-generating shear layers) and beat turbojet efficiency subsonically, but lose their advantage as
fan drag rises above about Mach 2 — pure turbojets remain the choice for efficient flight above
Mach 2.

### §10.2.4 Afterburner (Reheat)

Stoichiometric combustion (~15:1 air/fuel) would exceed turbine-blade material limits, so engines run
fuel-lean (~60:1 air/fuel, limited to ≈2000–2500°F {1100–1400°C} turbine-inlet temperature) — leaving
the exhaust ~75% unburned hot air. Injecting extra fuel into that excess air downstream of the turbine
("afterburning"/"reheat") can roughly double thrust, at roughly double the fuel flow per pound of
thrust (afterburning combusts at lower pressure with partially depleted oxygen — inherently fuel-
inefficient). Afterburner addition roughly doubles engine length but only adds 20–40% to weight
(mostly hollow duct); compressor bleed air is typically needed to cool the afterburner/nozzle walls.

### §10.2.5 Ramjets and Scramjets

A **ramjet** relies on inlet-duct compression alone (no rotating compressor) — technically operable
down to Mach 0.5 or below, but not competitive with turbojets until roughly Mach 3. First ramjet
aircraft: the French Leduc 0.10 (Breguet, 1949, air-launched, reached Mach 0.85, pilot seated inside
the inlet's center spike); the Nord 1500 Griffon (turbojet for takeoff, ramjet cruise, Mach 2.19 in
1958). A **scramjet** keeps the internal flow supersonic (avoids the drag of slowing it, but requires
supersonic fuel mixing/combustion) and is only practical above roughly Mach 5–6 (X-43, X-51 — longest
powered scramjet flight to date just over two minutes). Both ramjets and scramjets need a separate
takeoff/boost propulsion system (turbojet or rocket booster — the X-43/X-51 both used boosters much
larger than the research vehicle itself).

### Fig 10.2 — Propulsion system speed limits (typical applications)
*[Raymer, Fig. 10.2, p. 281]* — Categorical chart: applicable Mach range bands for piston-prop,
propfan, high-bypass turbofan, low-bypass turbofan, afterburning low-bypass turbofan, afterburning
turbojet, ramjet, scramjet, and rocket, spanning Mach 0 to 6+. A region-selection chart, not a
continuous data curve — not digitized to a point table; use the categorical ordering: piston-prop
(lowest speed) → propfan → high-bypass turbofan → low-bypass turbofan → afterburning low-bypass
turbofan → afterburning turbojet → ramjet → scramjet → rocket (highest speed), each typically
overlapping its neighbors' ranges. In most cases, pick the lowest-speed-capable type on the chart that
still meets the design Mach number.

### §10.2.6 Propulsion System Selection

The needed type is usually obvious from the max-speed requirement (Fig. 10.2); fuel-consumption
trends are in Fig. 3.3 (this repo's other extracts). Piston-prop vs. turboprop: turboprop burns more
fuel per unit power but is much lighter, more reliable, and quieter — turbines have displaced pistons
for helicopters, business twins, and short-range commuters regardless of design speed, while pistons
remain cheaper and likely to stay standard for light aircraft. Electric propulsion (Ch. 20) remains
weight-limited by the power supply, currently applied mostly to propellers (higher thrust per unit
power) though electric fans are also seeing use.

## §10.3 Jet-Engine Integration

Integration requires: required thrust level (to pick/scale the engine), inlet-duct sizing, and a
layout depicting the engine with realistic clearance for cooling airflow and engine access/removal,
plus engine controls, fuel lines, and driven accessories. Motor-mount structure locations come from
the engine manufacturer's installation drawing (commercial engines: typically top-front + top-rear;
military engines: typically top-front + one on each side mid-engine, or vice versa).

### Fig 10.3 — SAAB Draken RM6 engine installation
*[Raymer, Fig. 10.3, p. 282]* — Photo/diagram showing inlet ducts, a remotely mounted nozzle (for
balance), control/fuel lines, and engine-driven accessories (hydraulic pump, generator) with clearance
for cooling airflow, on a ring-frame wing-carrythrough structure. No plotted data.

### §10.3.1 Engine Dimensions

For an existing off-the-shelf engine, dimensions come from the manufacturer. For a "rubber" engine,
dimensions are scaled from a nominal engine — obtained from engine-company hypothetical-engine data
(Appendix E has several), a full parametric cycle deck (beyond this book's scope), or by treating an
existing engine (e.g. P&W F-100) as the nominal, optionally adjusted for assumed future-technology
improvement (e.g. a crude 10–20% SFC/weight reduction).

### Fig 10.4 — Engine scaling
*[Raymer, Fig. 10.4, p. 283]* — Diagram defining engine length `L`, and the scale factor
`SF = T_required / T_actual`. No plotted data beyond the definition.

**Eq (10.1)** *[Raymer, Eq. (10.1), p. 283]*: `L = L_actual · SF^0.4`

**Eq (10.2)** *[Raymer, Eq. (10.2), p. 283]*: `D = D_actual · SF^0.5`

**Eq (10.3)** *[Raymer, Eq. (10.3), p. 283]*: `W = W_actual · SF^1.1`

(Statistically derived, but intuitive: thrust ∝ captured mass flow ∝ engine cross-sectional area ∝
`D²`, so `D ∝ √SF`.) The engine-accessories package (fuel/oil pumps, power-takeoff gearbox, control
boxes) is, absent a manufacturer drawing, assumed to extend below the engine to a radius **20–40%
greater** than the engine radius (some engines instead locate accessories in the compressor spinner).

### §10.3.2 Parametric Statistical Jet-Engine Models

If no cycle deck and no suitable existing engine is available to rubberize, Eqs. (10.4)–(10.15)
(from Ref. [6]) give two first-order statistical jet-engine models: nonafterburning (subsonic,
bypass ratio 0–6, e.g. commercial transports) and afterburning (supersonic fighter/bomber, `M < 2.5`,
bypass ratio 0 to just under 1). **This re-extraction was cross-checked against a direct 300-dpi
page-image render of book p. 284 (PDF index 313)**, not just the OCR text layer — all sixteen
coefficients below are confirmed exactly as printed, high confidence, no `[verify]` flags needed.

**Nonafterburning engines:**

```
W        = 0.084 · T^1.1 · e^(-0.045·BPR)          [lb]  = 14.7·T^1.1·e^(-0.045·BPR)  {kg}   (10.4)
L        = 0.185 · T^0.4 · M^0.2                    [ft]  = 0.49·T^0.4·M^0.2           {m}    (10.5)
D        = 0.033 · T^0.5 · e^(0.04·BPR)             [ft]  = 0.15·T^0.5·e^(0.04·BPR)    {m}    (10.6)
SFC_maxT = 0.67  · e^(-0.12·BPR)                    [1/hr] = 19·e^(-0.12·BPR)          {mg/Ns} (10.7)
T_cruise = 0.60  · T^0.9 · e^(0.02·BPR)             [lb]  = 0.35·T^0.9·e^(0.02·BPR)    {kN}   (10.8)
SFC_cr   = 0.88  · e^(-0.05·BPR)                    [1/hr] = 25·e^(-0.05·BPR)          {mg/Ns} (10.9)
```

**Afterburning engines:**

```
W        = 0.063 · T^1.1 · M^0.25 · e^(-0.81·BPR)   [lb]  = 11.1·T^1.1·M^0.25·e^(-0.81·BPR) {kg}   (10.10)
L        = 0.255 · T^0.4 · M^0.2                    [ft]  = 0.68·T^0.4·M^0.2                {m}    (10.11)
D        = 0.024 · T^0.5 · e^(0.04·BPR)             [ft]  = 0.11·T^0.5·e^(0.04·BPR)         {m}    (10.12)
SFC_maxT = 2.1   · e^(-0.12·BPR)                    [1/hr] = 60·e^(-0.12·BPR)              {mg/Ns} (10.13)
T_cruise = 2.4   · T^0.74 · e^(0.023·BPR)           [lb]  = 0.59·T^0.74·e^(0.023·BPR)      {kN}   (10.14)
SFC_cr   = 1.04  · e^(-0.186·BPR)                   [1/hr] = 30·e^(-0.186·BPR)             {mg/Ns} (10.15)
```

where `W`=weight (lb/{kg}), `T`=takeoff (SLS) thrust (lb/{kN}), `BPR`=bypass ratio, `M`=max Mach
number; cruise reference ≈36,000 ft {11,000 m} at 0.9 Mach. Not valid outside the stated BPR/Mach
ranges; represent current (book-era) state of the art — Raymer suggests a crude 20% reduction in SFC,
weight, and length (for a given max thrust) as a next-generation-engine approximation. Ref. [42] is
recommended for full jet-engine-design theory/practice.

**Cross-check against the older `reference_extracts/raymer_data.md` extract**, which OCR'd this same
section previously with lower confidence:

| Eq. | Old `raymer_data.md` reading | This re-extraction (page-image confirmed) | Agreement |
|---|---|---|---|
| 10.4 (W, nonAB) | `0.0847·T^1.1·e^(-0.045BPR)` | `0.084·T^1.1·e^(-0.045BPR)` | Essentially identical — trivial rounding difference (0.0847 vs 0.084), not a real discrepancy; the printed page clearly shows **0.084**. |
| 10.5 (L, nonAB) | `0.185·T^0.4·M^0.2` | same | Exact match. |
| 10.6 (D, nonAB) | `0.033·...`, flagged `[verify]` suggesting ~0.034 | `0.033·T^0.5·e^(0.04·BPR)` | **Resolved**: the page image clearly prints **0.033**. The old extract's own printed value (0.033) was correct; its "metric cross-check suggests ~0.034" annotation was an unnecessary/incorrect second-guess — no change needed. |
| 10.7–10.9 (nonAB) | matches | matches | Exact match. |
| 10.10 (W, AB) | `0.0637·T^1.1·M^0.25·e^(-0.81BPR)` | `0.063·T^1.1·M^0.25·e^(-0.81·BPR)` | Essentially identical — trivial rounding difference, page clearly shows **0.063**. |
| 10.11 (L, AB) | `0.255·T^0.4·M^0.2` | same | Exact match. |
| 10.12 (D, AB) | `0.024·...`, flagged `[verify]` suggesting ~0.0256 | `0.024·T^0.5·e^(0.04·BPR)` | **Resolved**: the page image clearly prints **0.024**. As with Eq. 10.6, the old extract's printed value was already correct; the "verify" flag and suggested correction were unwarranted. |
| 10.13–10.15 (AB) | matches | matches | Exact match. |

**Net conclusion**: no actual coefficient errors existed in either extract. The two apparent
"discrepancies" the old `raymer_data.md` flagged for Eqs. 10.6/10.12 (D coefficients) were false
alarms — its own OCR'd values (0.033, 0.024) were correct all along; only its self-doubting
"metric cross-check" annotations were wrong. This re-extraction confirms the project's existing
`PropL2` static methods (if implemented from the old extract's printed coefficients) are already
using the correct constants.

### §10.3.3 Inlet Geometry

Turbojets/turbofans need air slowed to about **Mach 0.4–0.5** at the compressor face (keeps blade tip
speed subsonic) while *preserving total pressure* (a 10% inlet pressure-recovery loss costs roughly a
**13%** thrust loss) — best done by expanding duct cross-section (raises static pressure, holds total
pressure) rather than by skin-friction-dominated slowing (wastes total pressure).

### Fig 10.5 — Inlet types
*[Raymer, Fig. 10.5, p. 286]* — Four basic types: (a) NACA flush inlet; (b) conical/spike/round inlet
(full cone as on SR-71, or partial/quarter-cone as on FB-111); (c) pitot/normal-shock inlet; (d) 2-D
ramp inlet. No plotted data (type gallery).

**NACA flush inlet**: poor pressure recovery (~90% vs. a pitot inlet's ~100% at the same subsonic
condition) but reduces wetted area/weight for a fuselage-buried engine; mainly used where recovery
matters less (cooling-air scoops, APU intakes).

### Fig 10.6 — Flush inlet geometry / Table 10.1 — Flush Inlet Wall Geometry
*[Raymer, Fig. 10.6 / Table 10.1, pp. 286–287]* — Ramp geometry diagram (rounded cowl lip, 7°
ramp-floor angle, capture area) plus a normalized wall-contour table (fractional station `x/L`
1.0→0.0 vs. a normalized wall-height ratio):

| x/L | wall ratio | x/L | wall ratio |
|---|---|---|---|
| 1.0 | 0.083 | 0.5 | 0.466 |
| 0.9 | 0.160 | 0.4 | 0.614 |
| 0.8 | 0.236 | 0.3 | 0.766 |
| 0.7 | 0.313 | 0.2 | 0.916 |
| 0.6 | 0.389 | 0.1 | 0.996 |
| | | 0.0 | 1.000 |

A well-designed NACA inlet gives up to **92%** pressure recovery at a 0.5 mass-flow ratio (inlet
massflow ÷ freestream massflow through the same area).

### Fig 10.7 — Pitot (normal-shock) inlet layout
*[Raymer, Fig. 10.7, p. 287]* — Diagram: forward-facing-hole inlet, capture area labeled. No plotted
data beyond the geometry definition. Works well subsonically and at low supersonic speed (a normal
shock forms automatically ahead of it) — but total-pressure loss through the shock grows fast with
Mach: negligible at Mach 1.1, **28%** at Mach 2 (≈35%+ thrust loss) — impractical for sustained
operation above ≈Mach 1.4.

**Cowl lip radius**: subsonic jets 6–10% of inlet radius (larger radius reduces AoA/sideslip
distortion and eases takeoff mass-flow demand, at a drag cost); supersonic jets need a near-sharp lip,
typically 3–5% of inlet-front-face radius — subsonic inlets often split inner (~8%)/outer (~4%) radii,
and some give the lower lip up to 50% more radius than the upper lip to help at high-AoA takeoff/
landing.

**Supersonic inlets — oblique + normal shock strategy**: a single normal shock at Mach 2 gives only
72% pressure recovery; adding an oblique shock first (created by a wedge or cone turning the flow)
reduces the Mach number reaching the final normal shock, cutting total loss. Worked example from the
text (NACA TR 1135 shock tables): a 10° wedge in Mach 2 flow creates an oblique shock at 39°, slowing
flow to Mach 1.66 at 98.6% recovery; the subsequent normal shock (Mach 1.66→0.65) recovers 87.2%; net
recovery 0.986×0.872 ≈ **86%** (vs. 72% for a single normal shock) — and a well-designed single-
oblique-shock Mach-2 inlet can approach 95%.

### Fig 10.8 — Supersonic inlets, external compression (2/3/4-shock systems)
*[Raymer, Fig. 10.8, p. 290]* — Diagram progression: normal shock only → 2-shock → 3-shock → 4-shock
external-compression systems, converging toward the isentropic-ramp ideal (infinitely many oblique
shocks, 100% recovery ignoring friction — realized only on fixed single-design-Mach vehicles like the
Lockheed D-21 drone, or blended with flat wedges as on Concorde). More oblique shocks = better
recovery, especially at higher Mach, at the cost of a ramp/cone angle that's only optimal at one
design Mach. Ramps are mechanically easy to vary (pivot + actuator); cone angles are practically
impossible to vary (no aircraft has succeeded at it, though SR-71 varies cone *position*, not angle)
— so conical inlets (lighter, ~1.5% better recovery) are mainly used on single-Mach-optimized
high-speed aircraft.

### Fig 10.9 — Variable inlet geometry (typical 3-shock external-compression inlet)
*[Raymer, Fig. 10.9, p. 291]* — Diagram: variable second ramp (collapses for a larger subsonic-flight
duct opening), throat bleed slots (boundary-layer bleed dumped overboard through a rearward-facing
hole above the duct), not-shown suck-in/blow-in and bypass doors. No plotted data.

**Initial-layout rule of thumb**: assume a 10–20° initial ramp angle, find the shock angle at the
design Mach via shock charts (NACA TR 1135), place the cowl lip just aft of the shock; throat area
≈70–80% of engine front-face area. External-compression inlets hit a fundamental speed limit near
Mach 3 (oblique shocks introduce ~40° total flow turning — the "spilled" outer flow must re-attach to
the cowl lip, which may not be possible, causing separation and a large drag rise).

### Fig 10.10 — Supersonic inlets, internal and mixed compression
*[Raymer, Fig. 10.10, p. 292]* — **Internal-compression** inlet: paired inward-facing ramps create
crossing oblique shocks ahead of the normal shock, with zero external flow turning — efficient at
design Mach but must be actively "started" (normal shock sucked down to the throat via downstream
doors) and prone to "unstart" (any disturbance in temperature/pressure/AoA can pop the normal shock
back out, potentially stalling the engine). **Mixed-compression** inlets combine external + internal
compression for a wide efficient Mach range with acceptable external turning — used on most Mach-2.5+
aircraft (B-70: 2-D mixed compression, Fig. 10.11; SR-71: axisymmetric) — unstart remains a real risk
(implicated in at least one fatal SR-71 crash), controlled with automatic doors. Detailed
mixed-compression design is beyond this book's scope (Ref. [44] recommended); the external-compression
rules of thumb above give a reasonable first approximation.

### Fig 10.11 — B-70 inlet shock system
*[Raymer, Fig. 10.11, p. 292]* — Photo/diagram of the B-70's 2-D mixed-compression inlet. No plotted
data.

**Diffuser** (subsonic-flow interior section, increasing cross-section rear-ward): subsonic aircraft
want it as short as possible without exceeding ~10° internal half-angle (typically giving a pitot
inlet about as long as its front-face diameter is wide). Supersonic diffusers want ≈8× diameter for
theoretical peak efficiency (longer costs friction/weight; shorter than ~4× diameter risks internal
separation, sometimes still an acceptable weight/performance trade — spike inlets have used diffusers
as short as 2× diameter). Long diffusers should have their cross-sectional area checked for smooth
increase via a volume-distribution plot (same method as Fig. 7.38 in the prior chapter).

### Fig 10.12 — Typical fighter inlet diffuser
*[Raymer, Fig. 10.12, p. 294]* — Example smooth long diffuser (North American F-X proposal), station
callouts. No plotted data. Note (direct quote paraphrase): the inlet duct's "empty air" volume is
perpetually coveted by other subsystem groups during a tight layout — the configuration designer must
defend it.

A diffuser oversized by ~5%, "pinched" down to the engine-face diameter just before the engine, can
reduce flow distortion.

### Fig 10.13 — Inlet applicability by design Mach number
*[Raymer, Fig. 10.13, p. 294]* — Categorical rule-of-thumb chart: NACA flush → pitot (normal shock) →
2-shock → 3-shock → 4-shock external compression → mixed compression, as design Mach number
increases from 0 to 3+. A region-selection chart (like Fig. 10.2), not digitized as point data —
estimated pressure-recovery values for each inlet type are given in Ch. 13.

### §10.3.4 Inlet Location

Poor placement (ingesting a fuselage vortex or wing wake) can stall the engine via flow distortion
(cited real problems: F-111 wing/fuselage-junction inlets; A-10 required a fixed inboard-wing LE slot
to cure wake ingestion).

### Fig 10.14 — Inlet locations, buried engines
*[Raymer, Fig. 10.14, p. 295]* — Gallery: nose, chin, side, armpit, over-fuselage, over-wing,
over-fuselage (tail root), wing-root, wing-leading-edge. No plotted data. Trade-offs by location:

- **Nose** — cleanest air (used on early fighters, F-86/MiG-21) but longest, heaviest, highest-loss
  duct, large fuselage-volume cost.
- **Chin** (F-16) — most nose-inlet benefits with a shorter duct; good at high AoA (forebody helps
  turn flow in); nose-gear placement is awkward (ahead of the inlet risks flow blockage/debris
  ingestion, so gear usually sits just behind, deepening the cowl and adding gear-load-carrying
  structure). Twin chin inlets with the nosewheel between them: NAA F-15 proposal, Su-27. Rule of
  thumb: inlet height above the runway ≥ 80% of inlet height (low-bypass engine) or ≥ 50% (high-bypass
  engine), to limit foreign-object ingestion.
- **Side** — short duct, relatively clean air; common for twin-engine fuselage installations; vortex
  shedding off the lower forebody corner can cause high-AoA problems (worse for a square forebody). A
  single engine with side inlets needs a split duct — prone to pressure instability that can stall the
  engine; best practice keeps the two duct halves separate all the way to the engine face (though some
  aircraft rejoin them further forward).
- **Armpit** (side inlet at a high-wing/fuselage junction) — risky: combined forebody+wing boundary
  layers can build an unremovable thick corner boundary layer, prone to distortion at AoA/sideslip,
  though duct length is very short.
- **Over-fuselage** (inverted chin, e.g. F-107) — short duct, no nosewheel conflict, but poor at high
  AoA (forebody blanks the flow) and raises pilot bail-out safety concerns (suck-down risk).
  **Over-wing** — similar issues to an inverted armpit inlet.
- **Over-fuselage at tail root** (L-1011, B-727) — needs an S-duct (careful design to avoid internal
  separation) and should sit well above the fuselage to avoid the thick boundary layer there; benefit
  is aft-fuselage exhaust placement reducing fuselage separation/drag.
- **Wing leading edge / wing root** — cuts total wetted area (no separate cowl) but can disturb wing
  flow, add wing weight, and (wing root) ingest disturbed fuselage air.

### Fig 10.15 — Inlet locations, podded engines
*[Raymer, Fig. 10.15, p. 297]* — Gallery: under-wing, over-wing, over-fuselage, aft-fuselage,
wingtip, tail. No plotted data. Podded engines cost wetted area but win on undisturbed short-duct
inlet air, cabin noise, and maintenance access — standard for commercial/business jets:

- **Under-wing podded** (most common jet-transport arrangement) — ground-accessible, cabin-remote,
  span-loading benefit (reduces wing weight), exhaust can be flap-deflected for powered lift on
  takeoff. Downsides: nacelle/pylon can disturb wing flow (classical rule of thumb: inlet ≈2 diameters
  forward, ≈1 diameter below the wing LE — modern CFD allows much closer/conformal placement without
  the historical drag penalty, per Ch. 12); nacelle angled ≈2–4° nose-down and ≈2° nose-inward to align
  with local under-wing flow; high-bypass-engine inlet should sit ≈half a diameter above the ground
  (raises required gear height).
- **Over-wing podded** — shorter gear, less ground noise, harder maintenance access; a conformal
  over-wing nacelle can direct exhaust over flaps for Coanda-effect powered lift.
- **Aft-fuselage podded** (with T-tail) — removes wing interference, shortens gear, but raises cabin
  noise and (moving c.g. aft) forces the fuselage forward relative to the wing — shortening tail arm
  and growing both tails; nacelle angled ≈2–4° nose-up, ≈2° nose-outward. Il-76 uses two twin-engine
  aft pods; 727/Trident combine aft podded engines with a buried tail-inlet engine; DC-10 combines
  wing pods with a tail-podded engine (vs. L-1011's tail-inlet buried engine — Raymer judges the two
  "probably equivalent," DC-10's avoiding an S-duct but costing more tail weight and no fuselage-drag
  benefit). Tu-22 (Blinder) used twin tail-podded engines, not repeated on later Soviet supersonic
  designs.
- **Over-fuselage podded** (rare, e.g. OV-10 add-on jet) — poor access/cabin noise.
- **Wingtip-mounted** (Myasishchev M-52) — obvious engine-out controllability problem.

### §10.3.5 Capture-Area Calculation

"The engine is the boss" — it takes exactly the massflow it needs; the inlet spills excess or, if
short, starves the engine (thrust can fall toward zero). **Capture area** = inlet front-face
cross-section (pure geometry, measured to the foremost lip point) — not the same as the freestream
tube of air actually captured, since subsonic flow spreads/contracts approaching the inlet
(Fig. 10.16, diagram of streamline spreading between the freestream capture-area tube and engine
front face, no plotted data). Sizing capture area wrong is a big deal — oversizing can understate
computed supersonic wave drag by ~20%, a classic late-discovered "propulsion group fixed the capture
area and now the airplane doesn't meet performance" failure mode.

### Fig 10.17 — Preliminary capture-area sizing — **DATA GRAPH**
*[Raymer, Fig. 10.17, p. 300]* (confirmed via direct page-image OCR) — Capture area/mass flow
(sq ft per lb/s, left axis; sq m per kg/s, right axis) vs. Design Mach number (0–3.0) *(read from
plot)*:

| Design Mach | Capture area/mass flow (ft²/(lb/s)) |
|---|---|
| 0.0 | 0.0250 |
| 0.5 | 0.0250 |
| 0.8 | 0.0251 |
| 1.0 | 0.0253 |
| 1.2 | 0.0257 |
| 1.5 | 0.0265 |
| 1.8 | 0.0278 |
| 2.0 | 0.0290 |
| 2.2 | 0.0305 |
| 2.5 | 0.0320 |
| 2.8 | 0.0345 |
| 3.0 | 0.0357 |

Required capture area = engine mass flow × value read from this chart (includes appropriate bleed +
secondary-flow allowances). If mass flow unknown: estimate as **26 × (engine front-face diameter in
ft)²** {127 × (diameter in m)²}; if front-face diameter unknown, estimate as **80%** of max engine
diameter. Largest capture area is usually needed at the highest design Mach — but takeoff can be worse
(consider auxiliary suck-in/blow-in doors if so).

**Better subsonic-inlet method** (Fig. 10.16 geometry): pick a target Mach at the inlet front face
(commonly halfway between freestream and the engine-face target, e.g. ≈0.6 for a Mach-0.8 cruise/
Mach-0.4 engine-face case), then apply the isentropic compressible-flow area-Mach relation twice
(once at the engine face, once at the inlet throat) and take the ratio:

**Eq (10.16)** *[Raymer, Eq. (10.16), p. 301]*: `A_throat/A_engine = (A/A*)_throat / (A/A*)_engine`

**Eq (10.17)** *[Raymer, Eq. (10.17), p. 301]*: `A/A* = (1/M)·[(1/1.2)·(1 + 0.2·M²)]³`

(`A*` = area at sonic flow for the same conditions; this is the standard `γ=1.4` isentropic area-Mach
function.) Worked example: engine face at Mach 0.4, cruise Mach 0.8, inlet-face target Mach 0.6 →
`A_throat/A_engine ≈ 1.188/1.59 ≈ 0.75`, diameter ratio ≈0.88. Subsonic inlets generally need no bleed
(secondary air instead comes from small NACA flush inlets elsewhere). The same equations, applied with
the post-normal-shock subsonic Mach (from shock tables, e.g. NACA TR 1135), size a supersonic **pitot**
inlet's capture area (excluding bleed/secondary flow, handled separately below).

### Fig 10.18 — Supersonic inlet capture area, on-design ("shock-on-cowl")
*[Raymer, Fig. 10.18, p. 301]* — Diagram: at the design condition, the oblique shock just touches the
cowl lip and, with auxiliary doors shut, geometric capture area exactly supplies engine + bleed +
secondary flow. Design Mach is usually chosen ≈0.1–0.2 above the aircraft's actual max speed (safety
margin for overshoot/massflow fluctuation). No plotted data beyond the definition.

**Eq (10.18)** *[Raymer, Eq. (10.18), p. 302]*: `ṁ = ρ·V·A` (mass-flow relation; caution — fps-unit
users sometimes wrongly multiply by `g` to get lbm/ft² instead of the correct slug/ft²)

Engine mass-flow demand comes from the manufacturer (function of Mach, altitude, throttle setting;
add ~3% margin for manufacturing tolerance). Secondary-airflow demand (environmental control, cooling)
is more accurately assessed per-subsystem, but for initial sizing:

### Table 10.2 — Secondary Airflow (Typical) [Ref. 45]
*[Raymer, Table 10.2, p. 303]* — confirmed via direct page-image OCR.

| System | ṁs/ṁe |
|---|---|
| Engine — Nacelle cooling | 0–0.04 |
| Engine — Oil cooling | 0–0.01 |
| Engine — Ejector nozzle air | 0.04–0.20 |
| Hydraulic system cooling | 0–0.01 |
| Environmental control system cooling air (if taken from inlet) | 0.02–0.05 |
| **Typical total — Fighter** | **0.20** |
| **Typical total — Transport** | **0.03** |

### Fig 10.19 — Typical boundary-layer bleed area — **DATA GRAPH**
*[Raymer, Fig. 10.19, p. 303]* (data from Ref. [46], confirmed via direct page-image OCR) —
`AB/AC` (extra capture area needed for bleed, as a fraction of the engine+secondary capture area) vs.
Mach number (1.0–4.0), three curves *(read from plot)*:

| Mach | External-compression, porous bleed | External-compression, slot bleed | Mixed-compression (porous bleed) |
|---|---|---|---|
| 1.0 | 0.005 | 0.012 | 0.012 |
| 1.5 | 0.025 | 0.030 | 0.032 |
| 2.0 | 0.045 | 0.050 | 0.055 |
| 2.5 | 0.065 | 0.075 | 0.080 |
| 2.8 | 0.075 (curve ends) | 0.090 (curve ends) | 0.095 |
| 3.0 | — | — | 0.100 |
| 3.5 | — | — | 0.115 |
| 4.0 | — | — | 0.125 |

(External-compression porous/slot-bleed curves are only plotted up to ≈Mach 2.8–3; the mixed-
compression curve continues to Mach 4, rising roughly linearly beyond that point.)

**Eq (10.19)** *[Raymer, Eq. (10.19), p. 303]*:
`A_capture = [ṁe·(1 + ṁs/ṁe) / (g·ρ∞·V∞)] · (1 + AB/AC)`

### Fig 10.20 — Off-design inlet operation
*[Raymer, Fig. 10.20, p. 304]* — Four-panel diagram: (a) matched-critical operation (`M < M_design`,
normal shock exactly at the cowl lip, some compression-ramp spillage but no waste); (b) subcritical
operation with no bypass (engine demand drops further, excess air simply rejected — normal shock pushed
forward of the inlet, large spillage drag); (c) critical operation restored via a diffuser-section
bypass door (excess air taken in then dumped before reaching the engine — inlet bypass air, distinct
from *engine* bypass air, is *not* a thrust contributor); (d) critical operation restored via a movable
cowl lip (reduces capture area directly — seen on the Eurofighter Typhoon; complex/heavy, and
essentially impossible on an axisymmetric inlet). No plotted numeric data.

**Capture-area ratio** ("inlet mass flow ratio") = actual ingested massflow (engine + secondary +
bleed + any inlet bypass) ÷ massflow through the full freestream capture-area tube:

**Eq (10.20)** *[Raymer, Eq. (10.20), p. 304]*:
`A∞/Ac = (ṁe + ṁs + ṁbl + ṁbypass) / (g·ρ∞·V∞·Ac)`

Subsonically this ratio can be greater than, equal to, or less than 1; supersonically it can only be
≤1.

### §10.3.6 Boundary-Layer Diverter

The aircraft forebody's own boundary layer, if ingested, degrades engine performance and (supersonically)
can prevent proper inlet shock structure — unless the inlet sits very close to the nose (within
2–4 inlet diameters), some boundary-layer removal ahead of the inlet is needed.

### Fig 10.21 — Boundary-layer removal types
*[Raymer, Fig. 10.21, p. 306]* — **Step diverter** (subsonic only; an airfoil-shaped step, faired to
the nacelle, extending ≈1 inlet diameter forward with depth ≈2–4% of the forebody length ahead of the
inlet, forces boundary-layer air to follow the step rather than climb over high-energy air).
**Boundary-layer bypass duct** (separate duct admits the BL air to an aft-facing exit, expanding
≈30% intake-to-exit to offset internal friction losses). **Suction diverter** (BL air pulled through
holes/slots via suction — no ram-impact benefit, so less effective). No plotted data.

### Fig 10.22 — Channel-type boundary-layer diverter
*[Raymer, Fig. 10.22, p. 307]* — The most common supersonic-aircraft diverter: inlet front face held
off the fuselage by a splitter plate; BL air is trapped between plate and fuselage and pushed out
through the resulting channel by diverter ramps (ramp angle ≤ ≈30°). No plotted data beyond the
definition. Required diverter depth can't be cleanly calculated (flat-plate BL theory doesn't match a
real 3-D forebody, which builds a thinner BL than the flat-plate case) — rule of thumb: **1–3% of
fuselage length ahead of the inlet** (larger fraction for fighters that fly to high AoA). Diverter drag
depends on frontal area (Ch. 12) — minimize this area in layout.

### §10.3.7 Nozzle Integration

Core problem: desired nozzle exit area varies hugely with speed/altitude/throttle — for afterburning
engines, the supersonic-afterburning exit area can be **3×** the subsonic part-thrust exit area.
Convergent nozzles accelerate to high subsonic exit speed; supersonic exit speed needs a
converging-diverging nozzle.

### Fig 10.23 — Types of nozzles
*[Raymer, Fig. 10.23, p. 308]* — Gallery: fixed convergent; variable convergent (converging iris, or
translating plug); ejector; converging-diverging ejector; 2-D vectoring; single expansion ramp nozzle
(SERN), the latter two shown with circle-to-square adapters. No plotted data.

**Fixed convergent** — near-universal for subsonic commercial turbojets/turbofans (area picked for
cruise efficiency, small low-speed performance loss, but simplicity/weight savings dominate).
**Variable-area convergent** (needed for occasional high-subsonic/low-supersonic flight) historically
used a fixed-outer-surface design (creates unwanted base area when closed, common on early transonic
fighters, now rare) — superseded by the **convergent-iris** nozzle (varies area without a base area)
or a **translating plug** (used on the Me-262's engine — slides aft to shrink exit area). The
**ejector** nozzle reuses afterburner-cooling bypass air to also cool the nozzle. The **variable-
geometry convergent-divergent ejector** nozzle is standard for supersonic aircraft (varies exit area
across the flight envelope; the most advanced versions also independently vary throat area).

If no engine data package specifies nozzle areas, approximate from capture area: subsonic
convergent or closed-position convergent-divergent nozzle exit area ≈ **0.5–0.7×** capture area;
maximum supersonic afterburning exit area ≈ **1.2–1.6×** capture area. Boat-tail drag (separation on
the outside of the nozzle/aft fuselage) is minimized by keeping aft-fuselage closure angles below
**15°** and nozzle-closed external angles below **20°**. Adjacent engines interfere (reducing net
thrust) unless nozzles are separated by roughly **1–2×** their max exit diameter with a tapered
airfoil-like fill between them — though many fighters accept the interference penalty to mount twin
engines close together (weight/wetted-area tradeoff).

### §10.3.8 Engine Cooling Provisions

Aft-fuselage/engine-bay heat commonly forces titanium construction (e.g. F-22) where aluminum/
composite can't survive. The B-70 (Fig. 10.24, diagram — no plotted data) used an elaborate cooling
scheme around its six engines: at low speed, inlet-duct bypass air, boundary-layer bleed air, and
ground-cooling-door air all combine under a cooling shroud around each engine; up to Mach 3 operation,
cooling air is drawn from just upstream of the engine plus boundary-layer bleed, partly ejected
through the nozzle and partly exhausted rearward around the engines. General layout guidance: always
allow explicit clearance/volume for cooling and a possible engine shroud — don't "shrink-wrap" the
skin around the engine.

## §10.4 Propeller-Engine Integration

### §10.4.1 Propeller Sizing

Detailed blade shape/twist come later; conceptual layout needs propeller diameter, engine dimensions,
and cooling-air intake/exit sizing. Bigger diameter generally means better efficiency ("keep it as
long as possible"), but weight, motor-mount loads, and landing-gear length push back. The hard
diameter limit is propeller **tip speed** (must stay well below sonic):

**Eq (10.21)** *[Raymer, Eq. (10.21), p. 311]*: `(V_tip)_static = π·n·D` (`n` = rotation rate, rev/s —
convert from rpm by dividing by 60; `D` = diameter)

**Eq (10.22)** *[Raymer, Eq. (10.22), p. 311]* — actual (helical) tip speed = vector sum of the
static (rotational) tip speed and the aircraft's forward speed. (Raymer states the vector-sum
relationship in prose rather than a separate closed numeric form on this page.)

Rule-of-thumb sea-level helical-tip-speed limits to avoid shock formation: **metal propeller ≤950 fps
{290 m/s}**; **wooden propeller ≤850 fps {260 m/s}** (thicker section); if noise matters, both should
stay ≤**700 fps {213 m/s}** during takeoff. Apply the speed limit through Eqs. (10.22)/(10.21) to back
out the allowable diameter.

**Eq (10.23)** *[Raymer, Eq. (10.23), p. 311]* — statistical diameter-vs-power estimate:
`D = K_prop · (Power)^(exponent)`, coefficients by blade count (method modified from Ref. [47]):

| Number of blades | Exponent | K (fps: hp→ft) | K (mks: kW→m) |
|---|---|---|---|
| 2 | (exponent not isolated in this OCR pass — see coefficient table below) | 1.7 | 0.56 |
| 3 | " | 1.6 | 0.52 |
| 4+ | " | 1.5 | 0.49 |

`[verify p. 312]` — the printed table gives a single shared exponent per row alongside these `K`
values, but the OCR scan of this specific cell did not cleanly separate the exponent from the `K`
column; use the printed table directly (p. 312) before implementing Eq. (10.23) in code. The smaller
of the tip-speed-limited diameter and the Eq. (10.23) statistical diameter should be used for initial
layout.

Fixed-pitch propellers lose effective AoA (and thus thrust) as speed rises (a "cruise prop" or "climb
prop," depending which regime is favored); variable-pitch designs (controllable-pitch: pilot-set via a
lever; constant-speed: automatically holds optimal engine rpm) broaden the usable speed range.
**Spinners** should ideally cover the propeller out to ≈25% of radius (most spinners are smaller in
practice) — the inner blade radius contributes little thrust anyway; a spinner also streamlines the
nacelle. A **prop extension** (short shaft, 2–4 in {5–10 cm}) can relocate the disk fore/aft of the
engine for nacelle streamlining without the complexity of a full driveshaft installation (driveshafts
— e.g. P-39, BD-5, and the F-35B's lift-fan drive shaft — are prone to vibration/torsional problems and
tend to be heavier than expected).

Blade count doesn't need fixing at the conceptual-layout stage (needed before Ch. 13's detailed
thrust calcs). Fewer blades at equal diameter = better efficiency (each blade otherwise loses energy
to the preceding blade's downwash/tip vortices, analogous to biplane-wing inefficiency); a single-
bladed propeller is in fact optimal and used on record-setting model aircraft, but vibration
(even counterweighted) precludes it on full-size aircraft. More blades are chosen when more total
blade area is needed to absorb engine power without further increasing diameter (which would raise
tip speed, weight, and ground-clearance problems); slowing the prop via a gearbox (as in a cited
7-blade MT-Propellers/PT6A design) both lowers tip speed and reduces blade-to-blade interference,
improving takeoff performance and noise.

### §10.4.2 Propeller Location

### Fig 10.25 — Propeller location matrix
*[Raymer, Fig. 10.25, p. 314]* — Grid of fuselage/wing/pod × tractor/pusher combinations. No plotted
data.

**Tractor** (propeller forward) is the historical standard: puts the heavy engine up front (shortens
the forebody, allowing smaller tail area/improved stability), provides ready cooling airflow, keeps
the prop in undisturbed air, and clears a path through obstacles (e.g. trees) ahead of the
occupants in a crash. **Pusher** (rear-mounted, e.g. Wright Flyer, early Curtiss/Santos-Dumont
designs) lets the fuselage/wing fly in undisturbed air (less skin-friction drag from prop-wash
turbulence), reduces cabin noise, improves outside vision, and reduces fire/smoke/CO₂ risk to the
cabin — offset by reduced propeller efficiency (disturbed inflow off the fuselage/wing/tails), an
aft-shifted c.g. (needing larger tails), tighter ground clearance during rotation (≥9 in {23 cm}
clearance required in all attitudes), greater FOD risk from wheel-thrown debris, and (for turboprops)
possible exhaust impingement on the propeller. Fuselage-mounted pusher configurations can also shorten
the fuselage (steeper aft-closure angle tolerable thanks to the propeller's inflow, per Ch. 8) —
especially favorable paired with a canard (shorter tail arm than an aft tail).

Push-pull combinations (Cessna Skymaster, Rutan Defiant) cancel engine-out yaw at some cost (fuselage
flies in prop-wash from the front engine; the aft engine flies in disturbed fuselage wake; cabin
noise from both ends). Most multi-engine designs mount engines on the wings (span-loading benefit,
removes the fuselage from prop-wash — at the cost of engine-out rudder/vertical-tail sizing and pilot
training requirements); crew/passenger compartments must stay outside a **±5°** arc of the propeller
disk in case of blade separation, and gear must be long enough for ground clearance (sometimes
mitigated by mounting the prop above the wing plane, at an interference-drag cost). Wing-mounted
*pusher* propellers (rare — Beech Starship, Convair B-36) lengthen the forebody, need very long gear,
and sit half in over-wing/half in under-wing wake (efficiency loss/vibration, mitigated by locating
the prop as far aft of the wing as practical, worsening the gear problem further). Upper-fuselage and
tail-mounted pods are mostly a seaplane/amphibian solution (need ≥18 in {46 cm}, ideally ≥1 prop
diameter, of water clearance; a high thrust line can create a nose-down pitching moment on power
application, a real go-around/takeoff-rotation hazard if not carefully analyzed). Oddball locations
(wingtip: V-22, Vought V-173; articulated pylon/quadcopter conversion: Advanced Tactics Barracuda;
wing-buried pivoting rings for VTOL) are special-purpose and need detailed dedicated study.

### §10.4.3 Ducted Fans

Rare outside model aircraft/niche applications — despite being more efficient than an equal-diameter
propeller (more effective disk area from inflow contraction, pressure thrust at the inlet lip,
endplate-like tip-loss/vortex suppression from the duct wall, and inlet-velocity control), a ducted
fan of truly equal diameter to an equivalent propeller would add enough duct weight/high-speed drag to
erase the benefit — so in practice a ducted fan installation is never actually built at the "equal
diameter" comparison point. Example efficiency chain: an 80%-efficient bare propeller might reach 90%
enclosed in a well-designed duct, but forward-flight duct drag can pull net efficiency down to 60–70%.
Fan-to-duct gap must be minute (else pressure "leaks" forward past the fan) — demanding tight
dimensional control and stiff duct/blade structure; ducted fans also suffer, like jet inlets, from
inlet-flow distortion or a thick ingested boundary layer (avoid ducts that swallow air that's
traveled the full fuselage length or wing-root flow).

Ducted fans get their biggest relative benefit at **zero forward speed** — well suited to VTOL
applications (smaller diameter than an equivalent open rotor, easier thrust vectoring; ≈30% more
static thrust at equal diameter, though equal diameter is rarely realized in practice). Empirical
static-lift approximation:

**Eq (10.24)** *[Raymer, Eq. (10.24), p. 317]*: `W/P = K·(P/A)^(-0.35)`

where `W`=weight (lb or kg), `P`=power (hp or kW), `A`=duct total internal cross-sectional area at the
fan (ft² or m²), `K = 15.4` (fps units) or `19.4` (mks units). This static-thrust benefit drops
rapidly with forward speed (needs detailed analysis to quantify). Practical advantages beyond raw
efficiency: quieter (at low tip speed) and safer (fewer propeller-strike accidents) than an open
prop — worthwhile even at a small net efficiency penalty for some GA applications. Ducted fans can
also spin faster than an equivalent open propeller (smaller diameter, lower internal velocity than
freestream), potentially avoiding heavy reduction gearing — particularly attractive for high-rpm
sources (two-stroke, Wankel, electric motors). A recurring but rarely successful idea: use a large aft
ducted fan to double as the tail group (insufficient inherent stability from the duct ring alone;
NASA's "Taillon" concept, Fig. 10.26, augments it with additional tail surfaces). Ducted-fan design/
power-matching theory: Küchemann & Weber (classical, Ref. [49]); Hollman (modern, Ref. [50]).

### Fig 10.26 — NASA "Taillon" ducted-fan GA concept
*[Raymer, Fig. 10.26, p. 318]* — Illustration, NASA Langley concept (Ref. [48]). No plotted data.

## §10.5 Engine Type and Size (Piston/Turboprop)

Brief history: Wright Brothers' own 4-cylinder in-line engine (crude — no carburetor, non-circulating
cooling water — but with an innovative aluminum crankcase); radial engines (better cooling, shorter)
common through WWI to the 1950s (still produced in former Soviet-bloc countries for agricultural/
utility/aerobatic use); horizontally-opposed engines now dominate GA (low frontal area, good cooling,
very high reliability with proper maintenance, convertible from aviation-grade to cheaper automotive
gasoline in many cases). Piston engines often carry two power ratings — maximum and maximum
continuous (typically ≈5–8% lower) — the latter matters most for cruise calculations. Turboprops
suit aircraft below ≈400 kt (propeller thrust loss at higher speed limits them); common for commuter/
business aircraft despite market preference for "real jets."

Propeller-aircraft design more often targets a known fixed-size (production) engine rather than a
rubber engine, since few new piston/turboprop engines are certified (high dev/cert cost, small
market — many current production piston engines trace to ~50-year-old designs); rubber-engine trade
studies remain useful even then, both to select the best existing engine and to avoid biasing
technology-comparison studies (e.g. composite vs. aluminum structure) by an arbitrarily fixed engine
size.

### Table 10.3 — Scaling Laws for Piston and Turboprop Engines
*[Raymer, Table 10.3, p. 320]* — form: `X_scaled = X_actual · SF^(exponent)`, `SF = power_scaled /
power_actual` (developed by the author from Ref. [1] data):

| Parameter | Piston exponent | Turboprop exponent |
|---|---|---|
| Weight | 0.78 | 0.809 |
| Length | 0.424 | 0.310 |
| Diameter | (width/height vary insignificantly within ±50% power) | 0.130 |

`[verify p. 320]` — this OCR pass could not fully disambiguate every cell of the printed table
(specifically whether a "Diameter" row exists distinctly for piston engines, or whether that row is
turboprop-only with piston width/height simply noted as roughly power-invariant); use the printed
table directly if implementing this scaling law.

### Table 10.4 — Piston and Turboprop Statistical Models
*[Raymer, Table 10.4, p. 321]* — form: `X = a·(power)^b` (fps: hp→ft/lb; mks: kW→m/kg), by engine
class:

| Parameter | Piston (fps a, b) | Turboprop (fps a, b) |
|---|---|---|
| Weight | 5.47, 0.780 | 4.90, 0.809 |
| Length | 0.32, 0.424 | 0.52, 0.310 |
| Diameter | — | 0.35, 0.373 |
| Width | 2.6–2.8 ft (range, not a power law) | 1.7, 0.130 |
| Height | 1.8–2.1 ft (range) | 0.8, 0.120 |
| Typical propeller rpm | 2770 | 2300 |
| Applicable bhp range | 60–500 | 200–2000 |

(Metric coefficients are also given in the source table alongside these fps values but omitted here
per this project's English-units convention; see p. 321 directly if metric coefficients are needed.)
`[verify p. 321]` — table cell alignment in this OCR pass is only moderately confident for the
Width/Height rows; cross-check the printed table before hard-coding.

### §10.5.1 Piston-Engine Installation

### Fig 10.27 — Piston-engine installation
*[Raymer, Fig. 10.27, p. 322]* — Diagrams: downdraft cooling (tractor, standard — air enters ahead of
the cylinders, directed by baffles down and around them, exits below the fuselage into a
high-pressure region — a comparatively poor exit location); updraft cooling (exits into the
low-pressure region above the fuselage via suction effect — more efficient, but heats the cabin/
windscreen area and can coat the windscreen with oil leaks, and is heated by the exhaust pipes en
route to the cylinders since those sit below); pusher-engine updraft cooling with a scoop (needed
because a pusher gets no forward-propeller-driven cooling inflow on the ground, and its intake sits in
the thick, slow aft-fuselage boundary layer — sometimes needs internal fans). No plotted data.

Cooling costs up to **10%** of engine power (drag of intake/passage/exit airflow) — minimize by
keeping cooling massflow as small as efficiently possible. Typical need: ≈1 lb/s cooling-air massflow
per 100 hp {≈0.6 kg/s per 100 kW}. Optimization studies favor slowing intake air to **30–70%** of
flight speed (climb speed is usually the worst/sizing case):

**Eq (10.25)** *[Raymer, Eq. (10.25), p. 322]*: `A_cooling = bhp / (2.2·V_climb)` {ft²} (`bhp` in hp,
`V_climb` in ft/s)

**Eq (10.26)** *[Raymer, Eq. (10.26), p. 322]*: `A_cooling = bhp / (55·V_climb)` {m²} (`bhp` in kW,
`V_climb` in m/s)

`[verify p. 322]` — the "55" mks coefficient in this OCR pass is a low-confidence read (garbled
digits); cross-check directly against the printed page before implementing Eq. (10.26) — the fps
form, Eq. (10.25), read cleanly.

An older rule of thumb (exit area 30% larger than intake) has reportedly been superseded — a slightly
*smaller* exit than intake (ratio `A_exit/A_inlet ≈ 0.8`) plus adjustable cowl flaps opening to a
ratio of 2+ is recommended, letting exit area (and thus cooling flow) be tuned in flight; a simpler
fixed 30%-larger exit can instead be flight-tested down while monitoring cylinder-head temperature if
variable flaps aren't wanted.

Motor mount (usually welded steel tubing) transfers engine loads to the fuselage corners/longerons,
typically extending the engine forward of the firewall by about half the engine's own length (that
space commonly holds the battery and nosewheel-steering linkage). The **firewall** (typically 0.015-in
{0.4-mm} stainless or galvanized steel sheet at the first structural bulkhead) prevents an engine-bay
fire reaching the rest of the structure — should not be broken with cutouts, and every control/hose/
wire penetration needs a fireproof fitting. Detailed piston installation: Ref. [51].

## §10.6 Fuel System

Fuel tanks are usually the only fuel-system component (vs. lines/pumps/vents/management controls)
that affects overall layout — for some aircraft (B-70, Fig. 10.28) tanks define most of the internal
volume. Normal aircraft use a "wet" wing box plus some fuselage tankage.

**Three tank types**: **discrete** (separately fabricated, bolted/strapped in — small GA/homebuilt
only, e.g. airfoil-shaped inboard-LE tanks or fuselage tanks behind the engine); **bladder** (a rubber
bag stuffed into a structural cavity — loses ≈10% of available volume to bag thickness, but can be
made self-sealing against small-arms damage, a major survivability win — roughly a third of historical
combat losses trace to fuel-tank hits); **integral** (sealed structural cavities, e.g. wing box —
maximizes volume but is prone to leaks even after "years of research," per the B-1B's introduction
experience; modern tighter-tolerance manufacturing and molded/bonded composite structure reduce this).
Integral tanks should avoid proximity to crew compartments, inlet ducts, gun bays, or engines (fire
risk); filling with porous foam reduces fire risk at a fuel-volume cost (≈2.5% displaced by the foam
itself, another ≈2.5% lost to fuel absorbed into the foam; foam itself weighs ≈1.3 lb/ft³
{21 kg/m³}).

High-performance/most military aircraft slightly pressurize tanks (engine bleed air or small ram
scoops) to aid pump feed during maneuvers and suppress fuel foaming (also a safety benefit — higher
pressure fuel is less prone to ignite); some (C-5, Dassault Falcon) use nitrogen instead of air to
suppress fire/explosion risk entirely. Smaller aircraft use simpler unpressurized, vented tanks
(vented on the side opposite the fuel line). (Aside: the Rutan Voyager's winglets existed solely to
keep fuel vents above the wing tanks when the tips flexed down to the runway on its heavy round-the-
world takeoff — their aerodynamic contribution was negligible, proven when they broke off shortly
after takeoff without incident.)

### Fig 10.28 — B-70 fuel system
*[Raymer, Fig. 10.28, p. 323]* — Diagram of the B-70's extensive internal tankage. No plotted data.

**Fuel types**: piston engines use **AvGas** (color-coded by grade — blue/purple/red/green — a
processed gasoline, similar to but not identical to automotive "MoGas," which is ≈7% denser and often
cheaper; auto-gas conversion needs an FAA Supplemental Type Certificate, and ethanol-blended auto gas
can be problematic). Turbine engines use kerosene-derived **Jet Fuel/ATF/"AvTur"** — civil "Jet A"
(US) or "Jet A-1" (rest of world, lower freezing point + anti-static additive); **Jet B** (a
≈30/70 gasoline/kerosene blend) for extreme cold, more fire-prone. Military "JP" designations: **JP-8**
(~Jet A, current US standard), **JP-4** (obsolete, ~Jet B, 50/50 blend), **JP-5** (carrier-safe, high
flash point, no civilian equivalent), **JP-6/JP-7** (developed for the B-70/SR-71 respectively),
**JP-10** (dense exotic gas-turbine fuel for missiles). Diesel piston fuel is itself a kerosene, and
some newer diesel aircraft engines run directly on jet fuel (more available at airports than diesel).
Water contamination (denser than fuel, sinks to tank drains — checked via a clear-tube preflight fuel
sample) and dissolved-water freezing at altitude (can block fuel lines — addressed with fuel heaters)
are both operational hazards worth layout awareness (drain placement).

### Table 10.5 — Average Fuel Densities [Ref. 172 — printed as such in the source]
*[Raymer, Table 10.5, p. 326]* — lb/gal {kg/L} at −18°C / 15°C / 38°C (approximate, per OCR — column
temperature headers partially garbled, `[verify p. 326]` for exact header values), by fuel type:

| Fuel | lb/gal (approx., mid-range) | lb/ft³ (approx.) |
|---|---|---|
| AvGas | ≈6.0–6.1 | ≈44.9–45.8 |
| Jet A-1 | ≈6.6–6.9 | ≈49–51.6 |
| JP-4/Jet B | ≈6.2–6.5 | ≈46–48.8 |
| JP-5 | ≈6.65–7.0 | ≈49.8–52.2 |
| JP-8/Jet A | ≈6.6–6.9 | ≈49.4–51.9 |
| JP-10 | ≈7.7–8.0 | ≈57.7–60.1 |

`[verify p. 326]` — this table's temperature-column structure (three temperatures × lb/gal and
lb/ft³ sub-columns) OCR'd with significant row/column scrambling; the values above are collapsed to
an approximate range spanning the printed −18°C/15°C/38°C variation rather than resolved per-exact-
temperature. **For actual implementation, re-derive this table from a direct page-image render of
p. 326** rather than relying on the ranges given here — density varies meaningfully with temperature
(the book recommends design to the 15°C column with a 3–5% volume margin for thermal expansion/
contraction) and getting the wrong column would bias fuel-volume sizing. Conversion note used to build
the ft³ figures: 7.48 gal = 1 ft³.

Fuel-volume determination: compute required tank volume from mission-sizing fuel weight ÷ selected
fuel density (15°C reference, +3–5% volume margin for thermal effects — cold underground-storage fuel
that later warms/expands can overflow "full" tanks; some aircraft, e.g. F-18 and several airliners,
add dedicated vertical-tail expansion tanks). For simple-geometry tanks (e.g. a tapered wing box),
volume follows directly; for complex integral/bladder tanks, build a fuel-volume plot (Fig. 10.29 —
cross-sectional tank area vs. fuselage station, volume = area under the curve, same method as the
Ch. 7 aircraft volume plot; tank c.g. = plotted-area centroid, and total fuel c.g. — the area-weighted
average of all tank centroids — should sit near the aircraft c.g.).

### Fig 10.29 — Fuel-tank volume plotting
*[Raymer, Fig. 10.29, p. 328]* — Diagram: cross-sectional tank area vs. station; tank volume = area
under curve; tank c.g. = area centroid. No further numeric data beyond the method description.

Usable-volume rules of thumb (external-skin-measured volume → usable fuel volume, accounting for wall
thickness/internal structure/bladder thickness): **integral wing tank 85%**, **integral fuselage tank
92%**, **bladder wing tank 77%**, **bladder fuselage tank 83%**.

Fuel can also be pumped aft in cruise to reduce trim drag (tail-down trim load grows as c.g. moves
forward, worse supersonically as the wing center of lift moves aft — Concorde and B-70 both pump fuel
rearward at cruise; some airliners, e.g. MD-11, use a horizontal-tail trim tank for the same purpose
even subsonically).

**In-flight refueling**: US Air Force **boom** system (tanker-mounted, boom-operator-flown rigid boom
into a receiver receptacle — mounted near centerline, forward, but not directly ahead of the pilot due
to disconnect fuel spillage) vs. the rest-of-world **probe-and-drogue** system (tanker trails a
parachute-stabilized basket; receiver aircraft flies a retractable probe — usually right side, just
forward of the canopy, for pilot visibility — into the basket). Boom systems give higher flow rates
and are more tolerant of pilot fatigue/error but need dedicated expensive tanker aircraft; probe-and-
drogue is cheaper to retrofit (including podded, bolt-on kits enabling aircraft-to-aircraft "buddy"
tanking, e.g. two F-18s where one gives most of its remaining fuel to the other partway through a
mission to extend its effective strike radius).

## §10.7 Green Propulsion

### §10.7.1 Why Green?

Petroleum-derived fuels are energy-dense, room-temperature-stable, and long-shelf-life, but burn
"dirty" (commercial aviation ≈2% of man-made CO₂, though dwarfed by natural CO₂), are fire/explosion-
prone, and depend on geopolitically uncertain supply chains.

### §10.7.2 F-T, GTL, and Biofuels

**Fischer-Tropsch (F-T)** (1920s German process, coal→fuel, supplied ~10% of WWII German fuel) now
also converts natural gas ("gas-to-liquids," GTL) to diesel/jet fuel with lower NOx/SOx/hydrocarbon
emissions (USAF has flown a B-52 on a 50-50 kerosene/F-T blend; an unmodified A380 flew in 2008 on a
60-40 kerosene/GTL blend; a 100%-synthetic-fuel passenger flight has occurred in South Africa).
**Biofuels** (organic-matter-derived) could plausibly cut aviation GHG emissions 60–80% per some
estimates, though skeptics note the fuel itself still releases carbon by burning regardless of
feedstock. Sources include fermented sugar/starch crops (ethanol — raises food-vs-fuel concerns),
animal/vegetable fats, jatropha, algae, fungus, and (emerging) non-food cellulose (waste wood, fast-
growing grasses). Certain biofuels were approved for commercial airliner use in 2011 (revenue flights
since, mostly cooking-oil/jatropha-derived; USAF has flown an F-22 supersonically on biofuel) —
currently roughly double the cost of conventional fuel. More exotic feedstocks (steel/coal-processing
waste gases, refinery burn-off gases, even seawater-derived hydrogen + dissolved CO₂) are being
explored, though the seawater route needs a large external (nuclear or hydroelectric) energy input to
be viable, raising its own environmental questions. Bottom line per the text: conventional petroleum-
based fuels will likely remain dominant for the foreseeable future on cost/availability/refining-
flexibility grounds, though further refining improvements (removing aromatics/sulfur/trace
hydrocarbon-emission contributors) remain possible.

### §10.7.3 Hydrogen and Methane

Unlike GTL/biofuels (still kerosenes, transparent to aircraft design/sizing/performance analysis),
hydrogen and methane are fundamentally different fuels with major design impact — usable in turbojet/
turbofan/turboprop or piston powerplants (hydrogen fuel cells for electric motors are covered in
Ch. 20 territory, not here).

**Hydrogen**: combusts to H₂O with air alone (though NOx still forms from atmospheric nitrogen, unlike
pure-oxygen rocket combustion); higher energy density *per unit mass* than kerosene, but far lower
*per unit volume* — liquid hydrogen (LH2) mass density is only **0.59 lb/gal {0.071 kg/L}**, ≈11× as
bulky as kerosene by raw volume, still ≈4× as bulky even after adjusting for equivalent energy
content (though it weighs only ⅓ as much for the same energy — a potential net weight win if it can be
realized). LH2 must be stored either highly pressurized or cryogenically — both make tanks heavy and
force ball or capped-cylinder tank geometry (awkward to install, and hazardous under crash pressure).
Hydrogen also isn't "mined" — production (electrolysis, acid-metal reactions, or — most commonly —
natural-gas cracking) is energy-intensive, and LH2 has poor shelf life / requires continuous cooling
energy even in storage, making refueling essentially a last-minute, rocket-like operation.

Flight history: a B-57 Canberra briefly flew one engine on LH2 in 1956; a Tu-154 flew extensively with
one of three engines LH2-converted in 1988 (large tank occupying the rear half of the cabin); ongoing
airliner studies (Tupolev, and more recent Airbus/Boeing work) show feasible designs but with bulbous,
higher-drag/weight fuselages and crash-survivability concerns (super-cold, flammable, explosive fuel,
sometimes positioned directly above the cabin). For **hypersonic airbreathing** propulsion, LH2 is
considered an excellent fuel (high energy/mass, low atomic weight, strong mixing/combustion
properties) — the X-43 flew LH2-powered at Mach 10 (vs. the kerosene-fueled X-51's Mach 7). The
author's own Rockwell-era hydrogen-fueled strategic-bomber study (Fig. 10.30) found reasonable engine
SFC gains but a tank volume "as much as the entire fuselage" — eventually housed in giant capped
cylindrical tanks suspended canard-tip to mid-wing, ultimately dropped due to the tanks' added wetted-
area drag.

### Fig 10.30 — Hydrogen-fueled strategic bomber study (D. Raymer, 1978)
*[Raymer, Fig. 10.30, p. 333]* — Concept illustration. No plotted data.

Piston engines can also run on hydrogen (benefiting from large-propeller low-speed efficiency) — the
Boeing Phantom Eye ISR UAV (two hydrogen-converted automotive engines, 150-ft {46-m} span) is designed
for 4-day endurance at 65,000 ft {20,000 m}.

**Methane**: mostly natural-gas/coal-seam-derived; lower hydrocarbon emissions and higher specific
energy than kerosene; already used as compressed/liquefied natural gas (LNG) for road vehicles;
liquefies at a higher (easier-to-hold) temperature than hydrogen, with density ≈**3.53 lb/gal
{0.423 kg/L}** — better than hydrogen but still nearly 2× as bulky as kerosene. The same Tu-154
hydrogen-research airframe also flew one engine on LNG (1989 international demonstration flights);
Tupolev continues both LNG and hydrogen airliner development work, claiming significant operating-cost
savings. Overall caution: actual biofuel/hydrogen/methane emissions benefits remain more "potential"
than proven once full production-chain energy/emissions are counted (e.g. some studies suggest
corn-ethanol production uses nearly as much petroleum as the substitute fuel it yields).

### §10.7.4 Nuclear

Arguably the "greenest" technology per unit power output (excepting waste disposal/catastrophe risk;
even including historical disasters, cumulative nuclear-power death toll is well below coal/oil).
Application to aircraft is technically straightforward (reactor heat → mechanical power via turbine,
or direct air-heating for thrust, analogous to a nuclear-fueled turbojet) but politically and
practically fraught (radiation shielding is the central problem — even passenger-adequate shielding
can leave flight crew exceeding recommended cumulative dose over a career). Heating approaches: direct
(air passed through the core — simpler, but radioactive exhaust) vs. indirect (heat-exchanger fluid,
e.g. sodium/liquid metal/pressurized water — radiation-free exhaust, but complex plumbing).

Historical programs: a 15-year, ~$10-billion (today's dollars) US effort from 1946 ground-tested
direct-heating nuclear turbojets (modified GE J47s) and flew a modified B-36 with an operating 3-MW
reactor (for shielding/operations research only, not powering the aircraft — required ≈25,000 lb
{11,300 kg} of cockpit shielding alone). A follow-on program to actually fly nuclear turbojets on a
B-60 derivative (300,000-lb {136,000-kg} MTOW) was cancelled; its projected propulsion-system weight
(165,000 lb {75,000 kg} — including 10,000 lb {4,500 kg} reactor, 60,000 lb {27,000 kg} reactor
shielding, 37,000 lb {16,800 kg} crew shielding, 18,000 lb {8,100 kg} nuclear turbojets, 40,000 lb
{18,100 kg} inlet ducts/equipment) was ≈50% of MTOW (vs. ≈65% for an equivalent B-52's total
propulsion+fuel weight — though the 50% figure reflects an unoptimized first-of-a-kind design). For
context, current commercial airliners run a ≈35–45% total propulsion weight fraction; a nuclear
airliner would likely need considerably more shielding/safety margin than a military design (and,
plausibly, crash-survivability comparable to a ground reactor's direct-strike design standard).

The author's own Rockwell future-bomber nuclear study (Fig. 10.31, based on the "Delta Spanloader"
stealth-bomber concept, 50,000-lb payload) — intended to enable extended "flush and loiter" survivable
alert postures — achieved a 65% propulsion weight fraction while holding crew dose to the US-NRC
5 rem/year occupational limit (assuming ~10 flight-hours/month, offset by simulator/conventional-
variant flying); relaxing to a 20×-higher dose limit for "flush-only" operation reduced that fraction
to 55%. The study was judged "interesting" but not pursued given its political controversy.

### Fig 10.31 — Nuclear-powered stealth flying-wing bomber study (D. Raymer, 1978)
*[Raymer, Fig. 10.31, p. 336]* — Concept illustration, crew shield called out. No plotted data.

(Note: this edition's electric-aircraft material has moved to its own Chapter 20.)

---

*Chapter 10 complete (Eqs 10.1–10.26, Tables 10.1–10.5, Figs 10.1–10.31). Two data-bearing design
charts digitized directly from page-image OCR (Fig. 10.17 capture-area sizing; Fig. 10.19 boundary-
layer bleed area); categorical (non-curve) charts Fig. 10.2 and Fig. 10.13 described qualitatively
rather than digitized, since they show applicability regions, not continuous trend data. OCR garbling
flagged: Table 10.1's exact exponent/K-value cell split for Eq. (10.23)'s propeller-diameter table
(p. 312); Table 10.3's piston-engine diameter row (p. 320); Table 10.4's Width/Height row alignment
(p. 321); Eq. (10.26)'s mks cooling-area coefficient (p. 322); Table 10.5's exact temperature-column
structure (p. 326) — all flagged inline with `[verify p. NNN]` rather than guessed. The §10.3.2
parametric engine-sizing equations (Eqs. 10.4–10.15) were re-extracted from a direct 300-dpi page-
image render and found to fully agree with the existing `reference_extracts/raymer_data.md` extract's
printed coefficients; that older file's own `[verify]`-flagged self-doubt about the D-coefficients in
Eqs. 10.6/10.12 was unfounded — both 0.033 and 0.024 are confirmed correct as originally read. Next:
Chapter 11 — Landing Gear and Subsystems (already present in this directory as
`11_landing_gear_and_subsystems.md`).*
