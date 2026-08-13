# Chapter 6 — Initial Sizing

**Source:** Daniel P. Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 6 "Initial Sizing," printed pp. 145–164.

Refines the Chapter-3 quick-sizing method into a mission-"stepping" method that supports weight
drops, fixed vs. rubber engines, and gives statistical methods for fuselage length, tail volume
coefficients, and control-surface sizing. All numbered equations, tables, and figures captured.

---

## §6.1 Introduction

Sizing determines takeoff gross weight `W0` and fuel weight needed to fly the design mission — the
single most important calculation in aircraft design: the designer knows the required range/payload
and must find how big the airplane must be, not the reverse. Chapter 3's quick method is
minimal-information; this chapter's refined method is more laborious (unsuitable for hand
calculation, intended for coding) but handles weight drops and both "rubber" and "fixed-size"
engines. A free BASIC source-code implementation is offered on the author's website
(www.aircraftdesign.com).

## §6.2 "Rubber" vs. "Fixed-Size" Engines

An existing engine is **fixed-size** (fixed thrust/geometry). An all-new, to-be-designed engine is a
**"rubber engine"** — scalable to whatever thrust the sizing iteration requires, holding a desired
`T/W` as aircraft weight varies. Rubber-engine sizing lets the designer solve for `W0` while meeting
*both* range and performance goals simultaneously; this is standard for major new fighter/bomber
programs (and sometimes SSTs), where the engine company later fixes the design once picked.

Fixed-engine sizing cannot generally satisfy both range and performance: sizing `W0` up to meet
range may leave insufficient `T/W` for a performance requirement (e.g., takeoff distance,
engine-out climb) — the designer must let one of {range, performance} become a "fallout" result
(§6.4), or change the design (bigger/more engines) or the requirements.

## §6.3 Rubber-Engine Sizing

### §6.3.1–6.3.2 Review / Refined Sizing Equation

Chapter 3's method used a configuration sketch plus assumed aspect ratio to graphically estimate
`(L/D)max`, approximated segment weight fractions `Wi/Wi-1` for cruise/loiter from SFC, and used the
historical takeoff/climb/landing fractions of Table 3.2 to get the total mission fraction `Wx/W0`.
Combined with a statistical empty-weight fraction (Table 3.1), takeoff weight followed from Eq.
(3.4), repeated here:

**Eq (6.1)** *[Raymer, Eq. (6.1), p. 147]*: `W0 = (Wcrew + Wpayload) / (1 − Wf/W0 − We/W0)`

**Eq (6.2)** *[Raymer, Eq. (6.2), p. 147]*: `Wf/W0 = 1.06·(1 − Wx/W0)`

Eq. (6.2) assumes the only mid-mission weight change is fuel burn (no payload drop) and implicitly
holds `T/W` constant — not accurate for fixed-engine sizing.

The refined method instead expresses `W0` directly, allowing both fixed and dropped payload, and
computes fuel weight by stepping through the mission rather than via a single mission fraction:

**Eq (6.3)** *[Raymer, Eq. (6.3), p. 148]*:
`W0 = Wcrew + Wfixed_payload + Wdropped_payload + Wfuel + Wempty`

**Eq (6.4)** *[Raymer, Eq. (6.4), p. 148]*:
`W0 = Wcrew + Wfixed_payload + Wdropped_payload + Wfuel + (We/W0)·W0`

As before, `W0` is guessed, `We/W0` and `Wfuel` computed from it, and the result iterated to
convergence (§6.3.3–6.3.4 give the refined `We/W0` and `Wfuel` methods).

### §6.3.3 Empty-Weight Fraction

Table 3.1's simple `We/W0 = f(W0)` equations remain usable, but Tables 6.1–6.2 (data from Ref. [6])
add aspect ratio, thrust- or power-to-weight ratio, wing loading, and max speed as extra regressors,
roughly halving the standard deviation vs. Table 3.1. Both are pre-layout statistical estimates only
— after the actual layout is drawn, use the Chapter 15 component weight-buildup method instead.

**Eq (no number, general form of Table 6.1)** *[Raymer, Table 6.1, p. 148]*:
`We/W0 = [a + b·W0^C1·A^C2·(T/W0)^C3·(W0/S)^C4·Mmax^C5]·Kvs`

### Table 6.1 — Empty Weight Fraction vs W0, A, T/W0, W0/S, and Mmax (fps units)
*[Raymer, Table 6.1, p. 148]*

| Aircraft type | a | b | C1 | C2 | C3 | C4 | C5 |
|---|---|---|---|---|---|---|---|
| Jet trainer | 0 | 4.28 | −0.10 | 0.10 | 0.20 | −0.24 | 0.11 |
| Jet fighter | −0.02 | 2.16 | −0.10 | 0.20 | 0.04 | −0.10 | 0.08 |
| Military cargo/bomber | 0.07 | 1.71 | −0.10 | 0.10 | 0.06 | −0.10 | 0.05 |
| Jet transport | 0.32 | 0.66 | −0.13 | 0.30 | 0.06 | −0.05 | 0.05 |

`Kvs` = variable-sweep constant = 1.04 if variable sweep, 1.00 if fixed sweep.

### Table 6.2 — Empty Weight Fraction vs W0, A, hp/W0, W0/S, and Vmax (kt) (fps units)
*[Raymer, Table 6.2, p. 149]* — form: `We/W0 = a + b·W0^C1·A^C2·(hp/W0)^C3·(W0/S)^C4·Vmax^C5`

| Aircraft type | a | b | C1 | C2 | C3 | C4 | C5 |
|---|---|---|---|---|---|---|---|
| Sailplane — unpowered | 0 | 0.76 | −0.05 | 0.14 | 0 | −0.30 | 0.06 |
| Sailplane — powered | 0 | 1.21 | −0.04 | 0.14 | 0.19 | −0.20 | 0.05 |
| Homebuilt — metal/wood | 0 | 0.71 | −0.10 | 0.05 | 0.10 | −0.05 | 0.17 |
| Homebuilt — composite | 0 | 0.69 | −0.10 | 0.05 | 0.10 | −0.05 | 0.17 |
| General aviation — single engine | −0.25 | 1.18 | −0.20 | 0.08 | 0.05 | −0.05 | 0.27 |
| General aviation — twin engine | −0.90 | 1.36 | −0.10 | 0.08 | 0.05 | −0.05 | 0.20 |
| Agricultural aircraft | 0 | 1.67 | −0.14 | 0.07 | 0.10 | −0.10 | 0.11 |
| Twin turboprop | 0.37 | 0.09 | −0.06 | 0.08 | 0.08 | −0.05 | 0.30 |
| Flying boat | 0 | 0.42 | −0.01 | 0.10 | 0.05 | −0.12 | 0.18 |

(Both tables' values confirmed from direct page-image OCR of pp. 148–149, high confidence — not
flagged `[verify]`.)

### §6.3.4 Fuel Weight

Rather than one mission fuel-fraction `(1 − Wx/W0)`, the refined method sums fuel burned leg by leg
(supports weight drops). For each non-drop segment:

**Eq (6.5)** *[Raymer, Eq. (6.5), p. 149]*: `Wf_i = (1 − Wi/Wi-1)·Wi-1`

**Eq (6.6)** *[Raymer, Eq. (6.6), p. 150]*: `Wfm = Σ Wf_i` (total mission fuel, sum over all legs)

Procedure: start with guessed `W0` as `Wi`; apply each leg's `Wi/Wi-1` fraction (or subtract a
payload-drop amount) sequentially, accumulating fuel burned, through to the end of the mission.

Total aircraft fuel adds reserve (5%, nominal engine-SFC margin) and trapped/unusable fuel (1%):

**Eq (6.7)** *[Raymer, Eq. (6.7), p. 150]*: `Wfuel = 1.06·Wfm`

### §6.3.5 Engine Start, Taxi, and Takeoff

Historical estimate: **Eq (6.8)** *[Raymer, Eq. (6.8), p. 150]*: `Wi/Wi-1 = 0.97 to 0.99`

### §6.3.6 Climb

From Ref. [16] data, climb+accelerate-to-cruise (starting at Mach 0.1):

**Eq (6.9)** (subsonic) *[Raymer, Eq. (6.9), p. 150]*: `Wi/Wi-1 = 1.0065 − 0.0325·M`

**Eq (6.10)** (supersonic) *[Raymer, Eq. (6.10), p. 150]*: `Wi/Wi-1 = 0.991 − 0.007·M − 0.01·M²`

For acceleration beginning at a Mach other than 0.1, divide the fraction for the ending Mach by the
fraction for the beginning Mach (both from Eqs. 6.9/6.10). Example: accel 0.1→0.8 gives ≈0.9805;
0.1→2.0 gives ≈0.937; so 0.8→2.0 requires 0.937/0.9805 ≈ 0.956. A more rigorous method is in Ch. 17.

### §6.3.7 Cruise

Breguet range equation (derived in Ch. 17), repeating Eq. (3.6):

**Eq (6.11)** (jet) *[Raymer, Eq. (6.11), p. 151]*: `Wi/Wi-1 = exp(−R·C / (V·(L/D)))`

**Eq (6.12)** (prop) *[Raymer, Eq. (6.12), p. 151]*:
`Wi/Wi-1 = exp(−R·Cpower / (ηp·(L/D))) = exp(−R·Cbhp / (550·ηp·(L/D)))` {fps}

where `R`=range, `C`=SFC, `V`=velocity, `L/D`=lift-to-drag ratio, `ηp`=propeller efficiency.

During cruise/loiter, lift = weight, so:

**Eq (6.13)** *[Raymer, Eq. (6.13), p. 151]*: `L/D = 1 / (q·CD0/(W/S) + (W/S)/(q·π·A·e))`

Note: `W/S` here is the *actual* (instantaneous) wing loading at the flight condition evaluated, not
takeoff wing loading.

### §6.3.8 Loiter

Repeating Eq. (3.8):

**Eq (6.14)** (jet) *[Raymer, Eq. (6.14), p. 152]*: `Wi/Wi-1 = exp(−E·C / (L/D))` (`E`=endurance/loiter
time; watch units)

**Eq (6.15)** (prop) *[Raymer, Eq. (6.15), p. 152]*:
`Wi/Wi-1 = exp(−E·V·Cpower / (ηp·(L/D))) = exp(−E·V·Cbhp / (550·ηp·(L/D)))` {fps}

### §6.3.9 Known-Time Fuel Burn and Combat

A "known-time fuel burn" segment (combat, warm-up, taxi, sometimes descent) models the engine
running a fixed duration `d`. For a rubber engine holding `T/W` constant:

**Eq (6.16)** *[Raymer, Eq. (6.16), p. 152]*: `Wi/Wi-1 = 1 − C·(T/W)·d`

(`T/W` evaluated at segment conditions, not takeoff; time units must match the SFC time unit.)
Combat is typically specified as a fixed duration at max thrust (often `d = 3 min`) or as a number of
sustained combat turns, in which case the duration must be computed:

**Eq (6.17)** *[Raymer, Eq. (6.17), p. 152]*: `d = 2π·x/ω = 2π·V·x / (g·√(n²−1))`

(`x`=number of turns, `ω`=turn rate — combines with Eq. 5.17.) The sustained turn load factor `n`
(thrust ≈ drag, lift = weight×n):

**Eq (6.18)** *[Raymer, Eq. (6.18), p. 153]*: `n = (T/W)·(L/D)`

subject to:

**Eq (6.19)** *[Raymer, Eq. (6.19), p. 153]*: `n ≤ n_max` (structural limit)

**Eq (6.20)** *[Raymer, Eq. (6.20), p. 153]*: `n ≤ q·CLmax / (W/S)` (max-lift limit)

`L/D` including the load-factor term in Eq. (6.13):

**Eq (6.21)** *[Raymer, Eq. (6.21), p. 153]*:
`L/D = 1 / ( q·CD0/(n·(W/S)) + n·(W/S)/(q·π·A·e) )`

(use the combat-condition Oswald efficiency `e` per Ch. 5's discussion of `e` changes at high-lift
combat conditions).

### §6.3.10 Descent for Landing

Historical: **Eq (6.22)** *[Raymer, Eq. (6.22), p. 153]*: `Wi/Wi-1 = 0.990 to 0.995`

### §6.3.11 Landing and Taxi Back

Historical: **Eq (6.23)** *[Raymer, Eq. (6.23), p. 153]*: `Wi/Wi-1 = 0.992 to 0.997`

### §6.3.12 Summary of Refined Sizing Method

### Fig 6.1 — Refined sizing method (flow diagram)
*[Raymer, Fig. 6.1, p. 154]* — Flowchart: Design objectives + Sizing mission → wing geometry
selection & `e` estimate; sketch/initial layout → `Swet/Sref` and CD0 estimate; engine SFCs → segment
weight fractions `Wi/Wi-1`; combined with `T/W` and `W/S` and a `W0` guess, iterate each mission
segment (subtracting fuel burn / payload drop) to a calculated `W0`; compare to the guess and repeat.
No plotted numeric data (process diagram).

Convergence heuristic: pick the next `W0` guess about three-fourths of the way from the initial
guess toward the calculated value. Worked examples appear in Chapter 23.

## §6.4 Fixed-Engine Sizing

Same basic iteration as rubber-engine sizing, using the adjusted mission-fraction equations above,
but a fixed-size engine often cannot meet both range and performance simultaneously — increasing
`W0` to add fuel for range may drop `T/W` below what's needed for a performance requirement (takeoff
distance, engine-out climb, etc.).

### §6.4.1 Mission Range Must Be Met

`W0` is solved by iterating Eq. (6.4) as in the rubber-engine case, except `T/W` now *varies* during
iteration (thrust is fixed, weight varies) rather than being held constant. Eq. (6.16) (which
assumes a fixed `T/W` during the burn) is therefore invalid for known-time segments; instead fuel
burn is computed directly from a fixed thrust:

**Eq (6.24)** *[Raymer, Eq. (6.24), p. 155]*: `Wf = T·C·d`

used the same way as Eq. (6.16)'s result — subtracted from the running weight and added to total
fuel burned. Once `W0` converges, the resulting (now-known) `T/W` is used to check actual performance.

### §6.4.2 Performance Must Be Met

If performance (takeoff distance, climb rate, turn rate, …) is the hard constraint, range becomes
the free variable — the required `T/W` is found by Chapter-5 methods using the known selected
engine's characteristics, and `W0` follows trivially:

**Eq (6.25)** *[Raymer, Eq. (6.25), p. 155]*: `W0 = N·Tper_engine / (T/W)` (`N`=number of engines)

With `W0` known, achievable range is then found by iterating Eq. (6.4), holding `W0` fixed at its
known value and varying the cruise-leg range(s) until the calculated `W0` matches. The same
technique generalizes to solving for any single mission parameter (e.g., loiter/test-time duration
for a fixed-radius research mission) rather than range specifically.

If neither approach meets both range and performance, the design itself must change (different or
more engines, or other substantial changes) or requirements must be relaxed — reducing payload is
one lever, but payload is often the whole point of the design.

A common practical shortcut: pick an existing engine (cost/availability driven, roughly right size
for the class), estimate required `T/W` or `P/W` for performance, get `W0` from Eq. (6.25), then lay
out the design and check range after the fact — modifying the design/requirements/engine choice if
range falls short. This approach is also common for battery-electric aircraft (Ch. 10).

## §6.5 Geometry Sizing

Once `W0` is known, fuselage/wing/tail geometry follows. For payload-driven fuselages (e.g., a
passenger aircraft, whose length is set largely by cabin seating), length/diameter follow almost
directly from passenger count and seats-across. For other types, final length emerges from
packaging, aerodynamic sleekness, and manufacturing considerations (later chapters); Table 6.3 gives
an initial statistical starting point from `W0` alone (data from Ref. [6]) — a good correlation to
existing aircraft, but only a starting point, not the final layout driver.

### Table 6.3 — Fuselage Length vs W0 (lb) [fps units]
*[Raymer, Table 6.3, p. 157]* — form: `Length = a·W0^C1` (ft)

| Aircraft type | a | C1 |
|---|---|---|
| Sailplane — unpowered | 0.86 | 0.48 |
| Sailplane — powered | 0.71 | 0.48 |
| Homebuilt — metal/wood | 3.68 | 0.23 |
| Homebuilt — composite | 3.50 | 0.23 |
| General aviation — single engine | 4.37 | 0.23 |
| General aviation — twin engine | 0.86 | 0.42 |
| Agricultural aircraft | 4.04 | 0.23 |
| Twin turboprop | 0.37 | 0.51 |
| Flying boat | 1.05 | 0.40 |
| Jet trainer | 0.79 | 0.41 |
| Jet fighter | 0.93 | 0.39 |
| Military cargo/bomber | 0.23 | 0.50 |
| Jet transport | 0.67 | 0.43 |

(Metric-unit coefficients `{a}` also given in the book alongside the fps values but omitted here —
project uses English units throughout per CLAUDE.md.) Reconstructed from OCR text; category order
and both coefficient lists matched 1:1 (13 rows each) with high confidence, not flagged `[verify]`.

If the cross-section isn't circular, use an equivalent diameter from cross-sectional area.

### §6.5.1 Fineness Ratio

Classic references (e.g., Hoerner, Ref. [9]) suggest minimum drag near fineness ratio ≈3, but this
holds only if a minimum-diameter constraint is fixed (e.g., forced by side-by-side 2-place seating);
ratio-3 fuselages often need oversized tails or a tailboom ("tadpole" shape, common on sailplanes) to
get adequate tail moment arm. If internal packaging doesn't force a fixed diameter, a recent
optimization study (Ref. [17]) found the volume-constant optimum fineness ratio for **subsonic**
aircraft is **6–8** (matching successful airship fineness ratios). **Supersonic** drag is typically
minimized near fineness ratio **≈14** (design-dependent, range 10–15+). In practice, real packaging
constraints (cockpit, payload shape) usually dominate over the fineness-ratio ideal.

Wing area follows trivially as `W0 / (W0/S)_takeoff` (reference/trapezoidal area, includes the
centerline-extended portion); Chapter 4 equations lay out the trapezoidal planform; Chapter 7 covers
positioning it on the aircraft.

### §6.5.2 Tail Volume Coefficient

Tail effectiveness (moment about the c.g.) is proportional to tail lift force × tail moment arm —
a volume-dimensioned quantity, made nondimensional by dividing by a length: wing span `bw` for
yawing/vertical-tail sizing, wing mean chord `c̄w` for pitching/horizontal-tail or canard sizing.

**Eq (6.26)** (vertical) *[Raymer, Eq. (6.26), p. 158]*: `cVT = LVT·SVT / (bw·Sw)`

**Eq (6.27)** (horizontal) *[Raymer, Eq. (6.27), p. 158]*: `cHT = LHT·SHT / (c̄w·Sw)`

Moment arm `L` is approximated as tail-quarter-chord to wing-quarter-chord distance. Horizontal-tail
area is conventionally measured to the aircraft centerline; canard area is exposed area only; twin
vertical tails sum both panels' areas.

### Fig 6.2 — Initial tail sizing (tail volume coefficient method definitions)
*[Raymer, Fig. 6.2, p. 159]* — Diagram defining `Sw` (wing area), `bw` (wing span), `c̄w` (wing mean
chord), and tail moment arm on a generic conventional-tail layout. No plotted data.

Given Table 6.4's typical coefficient values, tail areas follow:

**Eq (6.28)** *[Raymer, Eq. (6.28), p. 159]*: `SVT = cVT·bw·Sw / LVT`

**Eq (6.29)** *[Raymer, Eq. (6.29), p. 159]*: `SHT = cHT·c̄w·Sw / LHT`

Moment arm is approximated at this stage as a percent of fuselage length (below).

### Table 6.4 — Tail Volume Coefficient Typical Values
*[Raymer, Table 6.4, p. 160]* — confirmed via direct page-image OCR, high confidence.

| Aircraft type | Horizontal cHT | Vertical cVT |
|---|---|---|
| Sailplane | 0.50 | 0.02 |
| Homebuilt | 0.50 | 0.04 |
| General aviation — single engine | 0.70 | 0.04 |
| General aviation — twin engine | 0.80 | 0.07 |
| Agricultural | 0.50 | 0.04 |
| Twin turboprop | 0.90 | 0.08 |
| Flying boat | 0.70 | 0.06 |
| Jet trainer | 0.70 | 0.06 |
| Jet fighter | 0.40 | 0.07–0.12* |
| Military cargo/bomber | 1.00 | 0.08 |
| Jet transport | 1.00 | 0.09 |

*Long fuselage with high wing loading needs the larger value.

Tail-arm rules of thumb (as % of fuselage length): front-mounted prop engine ≈60%; wing-mounted
engines ≈50–55%; aft-mounted engines ≈45–50%; sailplane ≈65%. Configuration-specific volume-
coefficient adjustments: all-moving tail −10–15%; T-tail: vertical −5% (end-plate effect), horizontal
−5% (clean air); H-tail horizontal −5%; active (computer-controlled) flight-control system: statistical
tail area may be reduced ≈10% (if trim/engine-out/nosewheel-liftoff requirements are still met,
Ch. 16).

**V-tail**: size horizontal and vertical as usual, then size the V-surfaces to match the *same total
area* as the conventional tails combined (Ref. [10]); dihedral angle ≈ `arctan(√(SVT_req/SHT_req))`,
typically near 45°.

**Canard**: control-type canard `cHT ≈ 0.1` (from limited flown examples); moment arm typically
30–50% of fuselage length. For a *lifting* canard, the volume-coefficient method doesn't apply —
instead the designer picks an area split (typically ≈25% canard / 75% wing, though wide variation
exists; 50-50 gives a tandem-wing configuration) and allocates the required total area accordingly.

## §6.6 Control-Surface Sizing

Primary controls: ailerons (roll), elevator (pitch), rudder (yaw). Final sizing needs dynamic
control-effectiveness analysis (incl. structural bending, control-system effects); the following are
initial-design guidelines only.

### Fig 6.3 — Aileron guidelines
*[Raymer, Fig. 6.3, p. 161]* — Aileron span (fraction of wing semispan, 0.2–1.0, y-axis) vs. aileron
chord/wing chord (0.10–0.35, x-axis), a design-guideline curve (updated from Ref. [19]) *(read from
plot)*:

| Aileron chord/wing chord | Aileron span (fraction of semispan) |
|---|---|
| 0.10 | ~0.35 |
| 0.15 | ~0.45 |
| 0.20 | ~0.55 |
| 0.25 | ~0.62 |
| 0.30 | ~0.68 |
| 0.35 | ~0.72 |

(Larger aileron chord permits a shorter span for equivalent effectiveness — designer's choice
along this guideline curve, not a hard rule.) Ailerons typically span ≈50–90% of the semispan (some
extend to the tip, trading control effectiveness there for aileron mass-balance placement); flaps
occupy the inboard span not used by ailerons. Spoilers (plates aft of max-thickness, forward of
flaps, deployed into the slipstream) can substitute for/augment ailerons, letting flaps use the full
span — common on jet transports for low-speed roll augmentation and lift dump/drag during landing
rollout, but nonlinear response makes them hard to use for manual-system roll control.

**Aileron reversal**: at high speed/dynamic pressure, aileron airloads can twist the wing enough that
the twist-induced rolling moment exceeds (and reverses) the intended aileron rolling moment.
Mitigations: auxiliary inboard ailerons for high-speed roll control, spoilers, or "rolling tails"
(asymmetrically deflectable all-moving horizontal tails) on some fighters.

Elevators/rudders typically run from the fuselage side to ≈90% of tail span; high-speed aircraft
sometimes use large-chord rudders limited to ≈50% span to avoid a reversal-like effectiveness
problem.

### Table 6.5 — Control Surface Sizing Guidelines
*[Raymer, Table 6.5, p. 162]*

| Aircraft | Elevator/Aileron `Cs/C` | Rudder `Cr/C` |
|---|---|---|
| Fighter/attack | 0.30* | 0.30 |
| Jet transport | 0.25† | 0.32 |
| Jet trainer | 0.35 | 0.35 |
| Biz jet | 0.32† | 0.30 |
| GA single | 0.45 | 0.40 |
| GA twin | 0.36 | 0.46 |
| Sailplane | 0.43 | 0.40 |

*Supersonic aircraft usually use an all-moving tail without a separate elevator.
†Often an all-moving tail plus a separate elevator.

(Column header reconstructed from context: Raymer's Table 6.5 gives elevator/aileron and rudder
chord fractions of the tail/wing chord — the OCR text-layer scrambled the column labeling; values
themselves read cleanly and are given here in the row order the OCR preserved.
`[verify p. 162]` if precise column semantics matter — cross-check column headers directly against
the printed table before hard-coding.)

Control surfaces are typically tapered at the same taper ratio as their parent wing/tail surface, to
hold constant %-chord and permit straight-tapered (not curved) spars (Fig. 6.4). Ailerons/flaps are
typically ≈15–25% of wing chord; rudders/elevators ≈25–50% of tail chord.

### Fig 6.4 — Constant-percent-chord control surface
*[Raymer, Fig. 6.4, p. 163]* — Diagram: tapered wing/tail planform with a control surface whose
hinge line follows a constant %-chord line back from the LE, apex point labeled. No plotted data.

**Flutter**: rapid airload-driven oscillation that can shed the control surface or the whole wing;
mitigated by mass balancing (weight forward of the hinge line, offsetting the aft control-surface
weight — as far forward as practical to minimize weight penalty; sometimes on a boom at the wing
tip, sometimes buried in the wing on a boom attached to the surface) and aerodynamic balancing
(a portion of the control surface ahead of the hinge line, reducing control force and flutter
tendency). Discussed further in Ch. 8.

### Fig 6.5 — Aerodynamic balance
*[Raymer, Fig. 6.5, p. 164]* — Two cross-section diagrams: (a) notched/"horn" aerodynamic balance,
(b) overhung aerodynamic balance, hinge line labeled on both. No plotted data.

A notched balance is unsuitable for ailerons or any high-speed surface. Hinge axis should be no
farther aft than ≈20% of the control surface's average chord. A naval-architects' rule of thumb for
locating a balanced-rudder hinge line: break the surface into spanwise strips; for a movable surface
trailing a fixed surface assume its center of pressure at 0.33 of the movable chord; for a movable
surface directly in the freestream (e.g. the exposed top of a rudder) assume 0.20 of chord; area-
weight and sum the strip centers of pressure to get an overall c.p., and keep the hinge line well
ahead of it — then verify with a more rigorous method before finalizing.

Manually controlled horizontal tails usually have the elevator hinge line perpendicular to the
centerline, permitting a torque-tube linking left/right elevators (reduces flutter tendency). Some
aircraft instead use a fully spindle-mounted all-moving horizontal tail (variable incidence, no
separate elevator) — heavier, but very effective, and common on supersonic aircraft where it trims
the rearward aerodynamic-center shift at supersonic speed. A few aircraft (F-23, SR-71, North
American F-107) also used all-moving vertical tails for extra control authority.

---

*Chapter 6 complete (Eqs 6.1–6.29, Tables 6.1–6.5, Figs 6.1–6.5). Next: Chapter 7 — Configuration
Layout and Loft.*
