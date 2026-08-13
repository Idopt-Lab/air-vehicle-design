# Chapter 13 — Propulsion

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 13
"Propulsion," printed pp. 463-490.

Covers installed-thrust estimation for jets (thrust corrections for inlet recovery, bleed, power
extraction, nozzle/inlet drag) and propeller-driven aircraft (propeller charts, blockage/tip-Mach/
scrubbing corrections, piston and turboprop performance). All equations, tables, and figures
preserved; narrative condensed.

---

## §13.0 Aircraft Thrust — the Big Picture

A generic propulsion system (propeller or short jet) is modeled as a "magic disk" of area `S`
accelerating freestream air from `V0` to `V` (Fig. 13.1):

### Fig 13.1 — Simplified thrust analysis model
*[Raymer, Fig. 13.1, p. 464]* — Streamtube sketch: freestream velocity `V0` entering a disk of area
`S`, exiting at velocity `V`. No plotted data (conceptual diagram supporting Eqs. 13.1-13.4).

```
F = ṁ·ΔV = (ρ·V·S)·(V − V0) = ρ·S·V·(V − V0)                            (13.1)
Pt = F·V0 = ρ·S·V·(V − V0)·V0                                           (13.2)
Pt,expended = (1/2)·ṁ·V² − (1/2)·ṁ·V0² = (ρ·S/2)·V·(V² − V0²)           (13.3)
ηPE = Pt / Pt,expended = 2 / (V/V0 + 1)                                 (13.4)
```
*[Raymer, Eqs. (13.1)-(13.4), pp. 464-465]* — efficiency is maximized (→1) as `V→V0`, but thrust (Eq.
13.1) then →0: an unavoidable thrust/efficiency tradeoff set by the exhaust/freestream velocity ratio.
Maximum efficiency wants a small `ΔV` over a large `S` (why helicopter rotors are large, and why
propellers beat jets at low speed): typical turbojet exhaust/freestream velocity ratio > 3.0; typical
propeller aircraft ratio ≈1.5. This model is a simplification — real exhaust keeps accelerating past
the nozzle exit (pressure driven), real propeller acceleration splits roughly half before/half after
the disk, and propulsion airflow interacts with the whole aircraft flowfield (pusher-prop base-drag
reduction, propwash drag increase, jet-exhaust-induced dynamic-pressure changes on nearby surfaces).

For a propeller aircraft most propulsive force reaches the airframe through the shaft/engine mounts;
for a jet, engine-mount force can be under half of total thrust — the rest comes through internal
inlet-duct pressure. Example breakdown for a Mach 2.2 nacelle (Fig. 13.2, North American A-5): engine
itself ≈8% of net thrust, nozzle ≈29%, inlet drag ≈−12%, remaining ≈75% from internal inlet-duct
pressure forces on the duct walls (net thrust normalized to 100%).

### Fig 13.2 — Turbojet thrust contributors (North American Aviation A-5)
*[Raymer, Fig. 13.2, p. 466]* — Waterfall-style breakdown of net thrust (100%) into engine (+8%),
nozzle (+29%), inlet drag (−12%), and inlet internal pressure (+75%), for a Mach 2.2 nacelle. No
further numeric data beyond these percentages (case-study figure).

The rest of the chapter presents rapid, conceptual-design-suitable installed-thrust estimation
methods for both jets and propellers; Ref. [42] covers detailed jet-engine design/installation.

## §13.1 Jet-Engine Thrust Considerations

A jet engine compresses inlet air, burns fuel in it, and expands the hot gas through a nozzle,
extracting some energy via a turbine to drive the compressor (Fig. 13.3); an afterburner (downstream
of the turbine) burns additional fuel in leftover oxygen for a short-duration thrust boost, needing a
variable converging-diverging nozzle for supersonic exhaust (afterburning aircraft) vs a simple fixed
converging nozzle (subsonic jets).

### Fig 13.3 — Turbojet engine
*[Raymer, Fig. 13.3, p. 467]* — Cutaway schematic: compressor, combustor, turbine, afterburner
section labeled. No plotted data (reference diagram).

"Gross thrust" = total exhaust-stream momentum; "net thrust" = gross thrust − "ram drag" (inlet-stream
momentum) — ram drag is already included in the engine manufacturer's cycle-analysis net-thrust
number, so airframe designers don't recompute it. Net thrust is roughly proportional to engine mass
airflow — unlike a piston-prop (whose power, hence thrust, falls with speed), a jet's thrust can
*increase* with speed (more ram air → more fuel → more power) until inlet drag/shock losses dominate.
Typical specific net thrust (lbf per lb/s airflow): afterburning turbojet ≈100-130 {1-1.3 kN per
kg/s}; turbofan ≈10-30 {0.1-0.3} (sea-level static max).

Thrust scales with inlet air density: hot/high-altitude takeoffs (e.g. Denver) lose thrust from
reduced density (compounding reduced wing lift in thin air). Approximate density correction: sea
-level thrust at a given speed × (pressure ratio to SL) ÷ (absolute-temperature ratio to SL) (see
Appendix B for altitude tables); simpler hot-day correction: thrust reduces ≈0.42%/°R {0.75%/K}.
Increasing aircraft velocity increases mass flow (ram effect) but a typical subsonic jet's exhaust is
choked (exit velocity ≈ speed of sound regardless of aircraft speed), so net thrust stays roughly flat
with speed, falling off transonically; supersonic engines (variable C-D nozzle) keep gaining thrust
with speed until excessive inlet total-pressure loss (Mach-number-dependent, per the number of
shocks/variable geometry, per Chapter 10) causes degradation.

Overall pressure ratio (OPR, exhaust-to-inlet-face pressure ratio) typically 15:1 to 30:1, governing
achievable thrust/efficiency. Turbine inlet temperature (TIT) is similarly critical: stoichiometric
(~15:1 air-fuel) combustion would exceed material limits, so ~60:1 lean mixtures are used instead
(less thrust/efficiency, but survivable metal temperatures); historical TIT growth ≈320°F {180°C} per
decade (~1500°F {800°C} in early jets to 2000-2500°F {~1100-1400°C} typical today, 2900°F {1600°C} in
the newest designs).

### Fig 13.4 — Turbofan engine
*[Raymer, Fig. 13.4, p. 469]* — Cutaway schematic showing the oversized bypass fan and core, per
§13.1's bypass-ratio discussion. No plotted data (reference diagram).

Turbofans raise propulsive efficiency by bypassing fan air around the core (bigger `S`, smaller `ΔV`
per Eq. 13.4); higher bypass ratio → better subsonic efficiency but rising ram drag (∝V²) and reduced
benefit as the fan struggles to reach transonic/supersonic exit speed — hence high-BPR turbofans
dominate subsonic cruise, low-BPR turbofans dominate low supersonic, and pure turbojets dominate above
~Mach 2 (Chapter 10 Fig. 10.2). Geared turbofans (fan/turbine gearing lets each spin at its own
preferred rpm) enable still-higher bypass ratios, up to the point where fan/duct/cowling drag and
weight offset the gain — motivating open-rotor/prop-fan concepts (§13.5).

## §13.2 Jet-Engine Installed Thrust

Airframe designers use the engine company's own performance ("cycle") analysis rather than deriving
it themselves (Ref. [42] covers cycle analysis); the engine company's assumptions (inlet efficiency,
bleed, power extraction, nozzle performance) tend to be optimistic and must be corrected
("installation analysis") to reflect actual installed behavior. Early-design "fudge-factor" scaling
(e.g., assume a 10-years-hence engine of similar BPR has 25% lower SFC, 30% less length/weight than an
existing analog) is also common practice.

## §13.3 Thrust-Drag Bookkeeping

Because thrust/drag interactions are complex, aircraft companies maintain a formal bookkeeping
convention (generally: does the force change with throttle setting?) to ensure every force is counted
exactly once, whether assigned to the "drag" or "thrust" side of the ledger — e.g., an afterburning
nozzle's aerodynamic drag can either sit entirely in the drag tables, or be split into a fixed
(full-open) drag term in the drag tables plus a throttle-dependent increment subtracted from thrust.
Either convention works if both the aero and propulsion departments understand it; this book's own
organization assumes a specific bookkeeping scheme (items here are treated as thrust reductions,
though another scheme could equally treat them as drag). Ref. [67] reviews the topic in depth.
Wind-tunnel testing compounds the bookkeeping challenge (separate powered/unpowered models).

## §13.4 Installed Thrust Procedure

The "installed net propulsive force" (used in performance calculations) = manufacturer's uninstalled
thrust, corrected for real installation effects (installed engine thrust), minus the propulsion
-assigned drag increments (inlet, nozzle/scrubbing, throttle-dependent trim drag) — see Fig. 13.5.

### Fig 13.5 — Installed thrust methodology
*[Raymer, Fig. 13.5, p. 472]* — Three-stage flow diagram: (1) "Manufacturer's uninstalled engine
thrust" (assumed inlet recovery, assumed bleed/power extraction, no distortion, manufacturer's nozzle
— caution: quoted SFC applies to *this* thrust figure) → less installation losses → (2) "Installed
engine thrust" (actual pressure recovery, actual bleed/power extraction, distortion effects, actual
nozzle performance) → less inlet/nozzle/scrubbing/throttle-trim drag → (3) "Installed net propulsive
force." No further numeric data (procedural flow diagram).

SFC is quoted against the manufacturer's *uninstalled* thrust — to get fuel usage, convert uninstalled
SFC to fuel mass flow first, compute installed net propulsive force, then divide to get installed SFC.

### §13.4.1 Thrust Installation Corrections

Inlet pressure recovery = total pressure at engine face ÷ freestream total pressure; subsonic engine
data usually assumes perfect recovery (`p1/p0 = 1.0`). Supersonic military engines use `p1/p0 = 1.0`
subsonically and the MIL-E-5008B reference schedule supersonically:

```
(p1/p0)ref = 1 − 0.075·(M∞ − 1)^1.35                                    (13.5)
```
*[Raymer, Eq. (13.5), p. 473]* — this reference schedule does not represent any actual inlet shock
system; Fig. 13.6 compares it to normal-shock and 1/2/3-ramp external-compression inlet recovery.

### Fig 13.6 — Reference and available inlet pressure recovery
*[Raymer, Fig. 13.6, p. 473]* — Pressure recovery (0.5-0.9+) vs Mach (0-3.0): MIL-E-5008B reference
curve plus normal-shock, external-compression (isentropic-spike cone, 3-shock cone/ramp, 4-shock
cone/ramp), and mixed-compression curves — recovery falls with Mach, more steeply for simpler
(normal-shock) inlets, least steeply for multi-shock/mixed-compression designs. *(read from plot,
approximate, MIL-E-5008B curve)*: M1.0→1.0; M1.5→~0.93; M2.0→~0.87; M2.5→~0.80; M3.0→~0.72.

### Fig 13.7 — Actual inlet pressure recoveries
*[Raymer, Fig. 13.7, p. 474]* — Recovery (0.75-0.95) vs Mach (0-3.5) for the MIL-E-5008B schedule vs
"ideal mixed-compression isentropic spike inlet" and real-aircraft data points labeled F-16, F-104,
F-15. *(read from plot, approximate)*: F-15 near M2.0-2.5 ≈0.90-0.88; F-104 near M2.0 ≈0.85; F-16
(normal-shock-type inlet, lower supersonic Mach range) ≈0.90 near M1.0-1.2. Useful as a rough
pressure-recovery estimate absent better data.

Internal duct losses depend on duct length/diameter, bends, and internal Mach; rough initial values:
straight duct ≈0.96, S-duct ≈0.94, short subsonic podded-nacelle duct ≈0.98+ (detailed estimation
needs Mach-by-Mach experimental data, Ref. [46]). Pressure-recovery shortfall has a greater-than
-proportional thrust effect:

```
% thrust loss = Cram · [ (p1/p0)ref − (p1/p0)actual ] · 100              (13.6)
Cram (supersonic) ≈ 1.35 − 0.15·(M∞ − 1)                                (13.7)
```
*[Raymer, Eqs. (13.6)-(13.7), p. 474]* — `Cram` (manufacturer-supplied when available) typically
1.2-1.5; use ≈1.35 subsonic if unavailable. Recovery also varies with inlet mass-flow demand (low
speed/high throttle "sucks" harder → lower recovery than high-speed/lower-demand cases — e.g. static
F-16 at max thrust: recovery ≈0.86 at full demanded mass flow vs >0.96 at half; the gap narrows to
~2% by M0.6 and less at higher Mach) — a detail ignorable in conceptual design. Inlet momentum
("ram") drag is already inside the manufacturer's uninstalled cycle-analysis number and is not
separately re-estimated; inlet distortion, engine bleed, and power extraction are separate corrections
against the manufacturer's (often zero) assumptions.

Engine bleed air (cabin air, anti-icing, etc. — distinct from inlet boundary-layer bleed) costs more
than proportionally in thrust:

```
% thrust loss = Cbleed · (bleed mass flow / engine mass flow) · 100     (13.8)
```
*[Raymer, Eq. (13.8), p. 475]* — `Cbleed` ≈2.0 if unavailable from the manufacturer; bleed mass flow
typically 1-5% of engine mass flow. Horsepower extraction (generators, hydraulic pumps via the engine
shaft) is typically <200 hp {150 kW} on a 30,000-lbf {133-kN} engine and has only a small effect;
thrust loss/SFC increase are both slightly less than the extracted power fraction [Ref. 89] — usually
ignorable for initial analysis, as is moderate inlet distortion (mainly an operating-envelope, not
performance, concern — good inlet/forebody-shaping practice avoids problems). Nozzle efficiency
directly affects thrust but a non-manufacturer nozzle (vectoring, stealth) can usually be designed to
match the original nozzle's efficiency (drag effects handled separately, §13.4.2).

### §13.4.2 Installed Net Propulsive Force

Three propulsion-related drags subtract from installed engine thrust: inlet drag (from an air-supply/
demand mismatch — mass-flow ratio <1.0 requires spilling excess air before the inlet ["additive"/
spillage drag] or bypassing/dumping it overboard, Fig. 13.8), nozzle drag, and throttle-dependent trim
drag.

### Fig 13.8 — Additive drag, cowl-lip suction, and bypass subcritical operation
*[Raymer, Fig. 13.8, p. 477]* — Side-view inlet-flow sketch showing capture area `Ac`, spilled
streamlines diverging ahead of the cowl lip, and the bypass duct routing excess air overboard. No
plotted data (schematic supporting the additive/bypass-drag discussion).

Cowl-lip suction (the spilled air's turning creates a forward-acting suction on the cowl lip) can cut
additive drag 30-40% in low supersonic flight, and can nearly eliminate it for a well-rounded subsonic
podded-nacelle inlet; even so, uncontrolled additive drag can exceed 20% of total aircraft drag, which
is why designers use inlet-air bypass whenever additive drag would otherwise be excessive (bypass drag
is smaller than the additive drag it replaces). A separate momentum loss comes from inlet
boundary-layer bleed (holes/slots preventing shock-induced separation/thick turbulent BL inside the
duct, discharged aft a few feet behind the inlet) — distinct from the inlet boundary-layer *diverter*
(prevents fuselage BL from entering the inlet; diverter drag is already counted in Chapter 12's
aerodynamic drag buildup, Eqs. 12.34-12.35).

Full bleed/bypass/additive-drag calculation (with cowl-lip suction) is a complex analytical+empirical
procedure (Refs. [16,44-46]) usually done by propulsion specialists with dedicated software. For rapid
conceptual-design trade studies, use the "ballpark" chart Fig. 13.9 (max dry/afterburning power,
corresponding mass-flow ratio — does not reflect the drag increase from reduced throttle setting).

### Fig 13.9 — Inlet drag trends
*[Raymer, Fig. 13.9, p. 478]* — Rough D/q ÷ Amax_fuselage (0-0.3) vs Mach (0.5-2.5) for 2-D inlet
(35,000 ft {10,668 m}) and axisymmetric inlet (10,000 ft {3048 m}) trend lines, both rising with
Mach. *(read from plot, approximate)*: 2-D inlet at M1.0 ≈0.03, M1.5 ≈0.10, M2.0 ≈0.18, M2.5 ≈0.27;
axisymmetric inlet at M1.0 ≈0.02, M1.5 ≈0.06, M2.0 ≈0.10, M2.5 ≈0.15. Explicitly cautioned by the
author as "typical," not representative of any specific inlet design — use with care.

Nozzle drag varies with position/flight condition; a full treatment needs actual nozzle geometry vs
throttle and overall-aircraft flowfield. For initial work, ignore nozzle-position effects and use
subsonic typical values (Table 13.1) for the nozzle types of Fig. 10.23 — drag rises transonically
then falls off supersonically, but the subsonic value can conservatively stand in at all speeds;
negligible for a subsonic podded nacelle.

### Table 13.1 — Nozzle Incremental Drag
*[Raymer, Table 13.1, p. 479]* — Subsonic `D/q ÷ Amax_fuselage`, cited to Ref. [16]:

| Nozzle Type | Subsonic D/q ÷ A_fuselage |
|---|---|
| Convergent | 0.036-0.042 |
| Convergent iris | 0.001-0.020 |
| Ejector | 0.025-0.035 |
| Variable ejector | 0.010-0.020 |
| Translating plug | 0.015-0.020 |
| 2-D nozzle | 0.005-0.015 |

Throttle-dependent trim drag (from a thrust-line offset from the c.g. causing a pitching-moment change
with throttle) is usually charged to propulsion in most bookkeeping schemes; ignorable in initial
analysis unless the thrust line is substantially off the aircraft centerline.

## §13.5 Part Power Operation

Turbojets/turbofans throttled below ~90% power see a more-than-proportional thrust drop relative to
fuel-flow reduction (rising SFC); engine companies provide "part-power tables" (laborious to
fully install-correct). A semi-empirical Mattingly approximation for part-power SFC:

```
C/Cmax_dry = 0.1 + 0.24·(T/Tmax_dry) + 0.66/(T/Tmax_dry)^0.8
             + 0.1·M·[1 − (T/Tmax_dry)]                                 (13.9)
```
*[Raymer, Eq. (13.9), p. 479]* — cited to Mattingly (coauthor of Ref. [42]). At idle, thrust/fuel flow
do not reach zero; if residual idle thrust/weight `T/W` equals `1/(L/D)`, the aircraft cannot descend
(relevant to descent-performance planning). Absent manufacturer idle data, approximate idle SFC as
1.5× max-dry SFC as a cap on the Eq. (13.9) result.

## §13.6 Piston-Engine Overview

Piston aircraft engines run the four-stroke Otto cycle (theory in Refs. [47,91,92]); power ∝ intake
-manifold air mass flow, approximately `hp ≈ 620 × (air mass flow, lb/s)` {`power(kW) ≈ 1019 ×
(mass flow, kg/s)`}. Air density (altitude/temperature/humidity) and manifold pressure both set mass
flow; the classic Gagg & Ferrar (Wright Aeronautical, 1934) altitude-power correction:

```
power = power_SL · [ (ρ/ρ0 − (1 − ρ/ρ0)) / 7.55 ]                        (13.10, form as printed)
```
*[Raymer, Eq. (13.10), p. 480]* — `ρ0` = sea-level standard density; indicates roughly half of SL
power remains at 20,000 ft {6100 m}. *[verify p. 480]* — the printed OCR of this equation's exact
bracketed form is somewhat garbled (`power = powerSL · [ (P − P/Po) / Po ]^7.55`-style fragments
appear in different orders across the scanned text); the commonly cited Gagg-Ferrar form is
`power/power_SL = 1.132·σ − 0.132` (σ = ρ/ρ0) — confirm the exact printed form against the page image
before hard-coding a MATLAB implementation.

Manifold pressure is normally atmospheric (forward-facing scoop can add a little at speed); larger
boosts need a mechanically-driven **supercharger** (compression ∝ engine rpm) or exhaust-turbine
-driven **turbosupercharger/turbocharger** (compression decoupled from rpm, recovering otherwise
-wasted exhaust energy). Supercharging/turbocharging typically maintains sea-level manifold pressure
up to ~15,000-20,000 ft {4500-6100 m}, above which power still falls (Fig. 13.10); can also be used to
boost manifold pressure above sea-level value for extra power, at a structural weight penalty (higher
internal pressures). Manufacturer performance charts give power vs manifold pressure/altitude/rpm.

### Fig 13.10 — Effects of supercharging
*[Raymer, Fig. 13.10, p. 481]* — Altitude (0-50,000 ft {0-10,668 m}) vs engine power (0-1000 bhp
{0-600+ kW}) for a typical 1000-bhp engine, three curves (non-supercharged, supercharged,
turbocharged): non-supercharged power falls roughly linearly with altitude from sea level;
supercharged/turbocharged hold full rated power up to a critical altitude then fall off similarly
above it. *(read from plot, approximate, turbocharged curve)*: full 1000 bhp maintained to ~20,000 ft,
falling to ~600 bhp by 40,000 ft.

Electric motors (Chapter 20) use the same downstream thrust methods as piston-props once motor power
is known.

## §13.7 Propeller Analysis

A propeller converts power into *thrust power* (thrust × velocity), not directly into thrust (units
aren't compatible). With ~20% typical loss, propeller efficiency `ηp` = thrust power ÷ engine power
(normally ~80%). Even a perfect propeller sees thrust fall with speed at fixed engine power (thrust
power = thrust × velocity = constant engine power, so thrust ∝ 1/velocity) — a basic-physics effect
independent of `ηp`, compounded by `ηp` itself often degrading at higher speed.

A propeller is a rotating lifting airfoil, like a wing, designed to a chosen design CL (usually ≈0.5)
with blade twist decreasing pitch angle from root to tip (tangential velocity rises with radius);
overall propeller "pitch" is conventionally quoted at 75% radius (70% in some texts). Key propeller
parameters/coefficients (aircraft designers use manufacturer propeller charts built on these, per
Refs. [92,93]):

```
Advance ratio:            J = V/(n·D)                                    (13.11)
Power coefficient:        Cp = P/(ρ·n³·D⁵) = 550·bhp/(ρ·n³·D⁵)          (13.12)
Thrust coefficient:       CT = T/(ρ·n²·D⁴)   [form implied by Eq. 13.17-13.18 usage]
Speed-power coefficient:  Cs = ⁵√(V⁵·ρ/(P·n²))                          (13.13)
Activity factor per blade: AF = (10⁵/16)·∫[root..R] c·r³ dr / D⁵          (13.14)
  AF (straight-taper blade) = 10⁵·c_root/(16·D) · [0.25 − (1−λ)·0.2]     (13.15)
Propeller efficiency:     ηp = (T·V)/P = (T·V)/(550·bhp)                (13.16)
Thrust (forward flight):  T = P·ηp/V = 550·bhp·ηp/V                     (13.17)
Thrust (static):          T = Cp·(CT/Cp)·550·bhp/(n·D)                  (13.18, form as printed)
```
*[Raymer, Eqs. (13.11)-(13.18), pp. 482-483]* — `T` lb/{kN}, `V` ft/s/{m/s}, `P` ft-lb/s/{kW}, `bhp` =
brake horsepower, `n` = rev/s, `D` = prop diameter ft/{m}, `c` = blade airfoil chord ft/{m}. Advance
ratio ∝ forward speed ÷ rotational tip speed ("slip function"/"progression factor"); power/thrust
coefficients are nondimensional analogs of CL; speed-power coefficient `Cs` is diameter-independent
(useful cross-propeller-size comparison); activity factor measures blade-width power-absorption
capacity, typically 90-200 (light aircraft ≈100, large turboprop ≈140). Eq. (13.16)'s `CT/Cp` ratio
(via `J`) is used in Eq. (13.17)-(13.18) to get static thrust (V=0, where the efficiency-based Eq.
13.17 form is invalid).

### Fig 13.11 — Static propeller thrust (after [93])
*[Raymer, Fig. 13.11, p. 484]* — `CT` (0-4.0) vs `Cp` (0-0.35) for a typical 3-bladed propeller
(activity factor 100, design CL 0.5). *(read from plot, approximate)*: Cp=0.05→CT≈2.5; Cp=0.10→CT≈2.0;
Cp=0.20→CT≈1.3; Cp=0.30→CT≈0.6.

### Fig 13.12 — Forward-flight thrust and efficiency (after [93])
*[Raymer, Fig. 13.12, p. 485]* — `ηp` (0-0.5+ scale shown 0-0.5 but text implies up to ~0.85 typical
peak) vs advance ratio `J` (0-2.8) for blade-pitch (`β3/4`) lines 15-40 deg, same propeller as Fig.
13.11 (3-blade, AF=100, design CL=0.5). *(read from plot, approximate, envelope of best efficiency
across pitch settings)*: J=0.4→ηp≈0.70; J=0.8→ηp≈0.83; J=1.2→ηp≈0.85; J=1.6→ηp≈0.82; J=2.0→ηp≈0.72.
Two-bladed props run ~3% more efficient in forward flight than shown (but ~5% less static thrust than
Fig. 13.11); four-bladed props show the reverse trends; wooden props run ~10% less efficient (greater
thickness). Variable-pitch props read `ηp` directly off this chart at any (J, Cp) combination in
flight, with blade angle a fallout parameter.

Propeller thrust ∝ 1/V implies (nonsensically) infinite static thrust — instead use Fig. 13.11's
test-based static value directly, and fair a smooth curve between the static value and the calculated
forward-flight value over 0-50 kt (e.g. during takeoff).

For a **fixed-pitch** propeller (blade angle cannot track engine rpm across flight conditions,
so efficiency/thrust degrade off the design point — stall-prone at low speed, insufficient local α at
high speed), use the simpler Fig. 13.13 method relating off-design to on-design (Fig. 13.12-derived)
efficiency, rather than tracking torque/rpm coupling directly via Fig. 13.12's blade-angle lines.

### Fig 13.13 — Fixed-pitch propeller adjustment
*[Raymer, Fig. 13.13, p. 486]* — `ηp/ηp,design` (0.4-0.90) vs `J/J_design` (0.5-1.3). *(read from
plot, approximate)*: J/Jdesign=0.7→ratio≈0.60; 0.9→≈0.85; 1.0→≈1.0 (by definition); 1.1→≈0.88;
1.3→≈0.55.

Fixed-pitch static thrust is lower than Fig. 13.11 estimates (high blade local α at low speed/high
rpm); rough approximation: static thrust ≈1.6× the thrust at 100 kt.

## §13.8 Piston-Prop Thrust Corrections

Three corrections to propeller efficiency: blockage, tip Mach, and scrubbing drag.

**Blockage** (nacelle behind the propeller slows the local inflow — usually *increases* thrust, since
slower inflow typically raises propeller thrust): correct the advance ratio before reading efficiency
charts:

```
J_corrected = J·(1 − 0.329·Sc/D²)                                        (13.19)
```
*[Raymer, Eq. (13.19), p. 486]* — `Sc` = max cross-section area of the cowling immediately behind the
propeller, `D` = propeller diameter; cited to Ref. [40].

**Tip Mach** (shock formation on the propeller tips increases drag/reduces thrust, raises torque):

```
ηp,corrected = ηp − (Mtip − 0.89) · [0.16/(0.48 − 3·t/c)]     for Mtip > 0.89     (13.20)
Mtip = sqrt(V² + (π·D·n)²) / a
```
*[Raymer, Eq. (13.20), p. 487]* — cited to Ref. [13]; `a` = speed of sound; `t/c` = propeller airfoil
thickness ratio.

**Scrubbing drag** (higher dynamic pressure/turbulence in the propwash raising drag on aircraft parts
within it) — SBAC (Society of British Aircraft Constructors) method:

```
ηp,effective = ηp · [ 1 − 1.558·(Sprop_washed/D²)·(ρ/ρ0)·Σ(Cfe·Swet)_washed ]     (13.21)
```
*[Raymer, Eq. (13.21), p. 487]* — `Cfe` = equivalent skin-friction (parasite) coefficient referenced
to wetted area; use ≈0.004 if unknown for the washed parts. Pusher-prop configurations have zero
scrubbing drag but instead lose ~2-5% efficiency from operating in the fuselage/wing wake (strongly
configuration-dependent).

Cooling drag (momentum loss of cowling-intake air passed over the engine) and miscellaneous engine
drag (oil cooler, air intake, exhaust pipes, etc.):

```
(D/q)cooling = 4.9×10⁻⁷ · bhp·T / (σ·V)     {ft²}   [= 6×10⁻⁸·ρ·V²/(σ·V) {m²}, as printed]     (13.22)
(D/q)misc = 2×10⁻⁴ · bhp     {ft²}   [= 2.5×10⁻⁸·ρ {m²}, as printed]                              (13.23)
```
*[Raymer, Eqs. (13.22)-(13.23), p. 487]* — cited to Ref. [40]; `T` = air temperature (°R/{K}), `V` =
velocity (ft/s/{m/s}), `σ` = ρ/ρ0. Real light-aircraft installations often run 2-3× these values;
simpler practical rule: expertly-designed cooling ≈6% thrust reduction, mediocre design ≈8-10%.

## §13.9 Turboprop Performance

A turboprop drives a propeller via an exhaust turbine, retaining some residual jet thrust (up to ~20%
of total). Engine power rating includes this residual thrust's power-equivalent: statically, residual
thrust ÷ 2.5; in forward flight, via Eq. (13.17) assuming `ηp = 0.80`. Mechanical + thrust-residual
power together = **equivalent shaft horsepower (ESHP)**. Turboprop analysis hybridizes jet analysis
(engine + inlet, residual thrust as a manufacturer-supplied hp equivalent) with propeller analysis
(including scrubbing drag). Like piston-props, conventional turboprops are tip-Mach-limited to
~Mach 0.7; they beat piston-props above ~Mach 0.5 (residual jet thrust) but lose to turbofans at
higher subsonic speed.

**Propfans/unducted fans (UDF)** (developed late 1970s, Fig. 13.14) — smaller-diameter, many wide/
thin/highly-swept blades — retain propeller efficiency >0.8 up to ~Mach 0.85. **Open rotor** engines
are turbofans whose fan diameter is so large the cowling ring costs more drag than it's worth, so it's
omitted (visually similar to a propfan but with more blades/rows); promising but unresolved
weight/complexity/noise issues.

### Fig 13.14 — Propfan
*[Raymer, Fig. 13.14, p. 489]* — Photo/illustration of a propfan installation (swept, multi-bladed,
small-diameter open rotor). No plotted data (reference image).

## What We've Learned

*[Raymer, p. 489]* Methods to calculate installed propulsive thrust and fuel consumption — jet or
propeller — have been presented, including the necessary thrust adjustments for propulsion-related
drags.

---

*Chapter 13 complete (§§13.0-13.9 [Big-Picture Thrust Model, Jet-Engine Thrust Considerations,
Installed Thrust, Thrust-Drag Bookkeeping, Installed Thrust Procedure, Part Power Operation,
Piston-Engine Overview, Propeller Analysis, Piston-Prop Corrections, Turboprop Performance], Table
13.1, Figs 13.1-13.14, Eqs. 13.1-13.23, "What We've Learned" summary). PDF index span used: 492-518
(printed pp. 463-489; p. 490 at index 519 is blank/chapter-closing whitespace). One item flagged
`[verify p. 480]`: Eq. (13.10)'s exact printed bracketed form for the Gagg-Ferrar altitude-power
correction is ambiguous in the OCR pass — the commonly cited form `power/power_SL = 1.132·σ − 0.132`
is noted as a cross-check pending confirmation against the page image. No other equations required
`[verify]` flags; figures with genuine plotted numeric trends (inlet pressure recovery, inlet drag
trend, propeller thrust/efficiency charts, supercharging effects) were digitized with representative
read-from-plot points; pure photo/schematic/diagram figures were noted as such without digitization.
Next: Chapter 14 — Structures and Loads.*
