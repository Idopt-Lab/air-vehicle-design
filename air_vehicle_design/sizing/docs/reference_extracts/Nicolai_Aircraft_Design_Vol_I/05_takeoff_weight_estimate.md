# Chapter 5 — Preliminary Estimate of Takeoff Weight

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 5 "Preliminary Estimate of Takeoff Weight," printed pp. 123–149.

---

## §5.1 Introduction

- **Eq (5.1)** — takeoff gross weight (TOGW):
  `W_TO = W_fuel + W_fixed + W_empty`  *[Nicolai & Carichner, Eq. (5.1), p. 124]*
- Rule of thumb for starting the iterative conceptual design loop: "assume something even if
  it's wrong" — the process cannot begin until a first W_TO estimate exists.

---

## §5.2 Fixed Weight

`W_fixed` (= payload):
1. **Nonexpendable:** crew + equipment; sensors.
2. **Expendable:** bombs; missiles; cannon + ammunition; passengers; baggage/cargo; food & drink.

---

## §5.3 Empty Weight

`W_empty` = structure + propulsion + subsystems + avionics + instruments, etc. Estimated at this
stage via historical data/trends (Appendix I), refined later via component weight-estimating
relationships (Chapter 20).

### Table 5.1 — Summary of Empty-Weight Trend Line Equations
*[Nicolai & Carichner, Table 5.1, p. 125]* — trend form `W_empty = (constant)·(W_TO)^XX`, from
Appendix I historical data.

| Aircraft Type | Constant | XX |
|---|---|---|
| Fighter — Air-to-air or developmental | 1.2 | 0.947 |
| Fighter — Multipurpose | 0.911 | 0.947 |
| Fighter — Air-to-ground | 0.774 | 0.947 |
| Bomber and transport | 0.911 | 0.947 |
| Light general aviation | 0.911 | 0.947 |
| Composite sailplane | 0.911 | 0.947 |
| Military jet trainer | 0.747 | 0.993 |
| High-altitude ISR | 0.75 | 0.947 |
| UAV — Propeller, endurance > 12 h | 1.66 | 0.815 |
| UAV — Propeller, endurance < 12 h | 2.18 | 0.815 |
| UAV — Turbine ISR | 2.78 | 0.815 |
| UAV — Turbine maneuver UCAV | 3.53 | 0.815 |
| Air-launch cruise missiles and targets | 1.78 | 0.815 |

Note: the empty-weight estimate is "the weakest part of the conceptual design analysis" but has
tremendous leverage on W_TO — press on regardless, refine on later iterations.

---

## §5.4 Fuel Weight

Mission divided into up to **8 phases** (Fig 5.1); compute the fuel fraction `W_{n+1}/W_n < 1` per
phase and multiply all phases together for the mission fuel fraction. Missing phases get
fuel fraction = 1; phases may be reordered/repeated to fit the actual mission profile.

### Fig 5.1 — Typical military mission profile
*[Nicolai & Carichner, Fig. 5.1, p. 126]* — Altitude vs Distance, showing the 8 phases:

| Phase | Description |
|---|---|
| 1 | Engine start and takeoff |
| 2 | Accelerate and climb to cruise speed/altitude |
| 3 | Cruise to destination |
| 4 | Accelerate to high-speed dash |
| 5 | Combat |
| 6 | Cruise back to origin |
| 7 | Loiter |
| 8 | Land, taxi, engine shutdown |

### Phase 1 — Engine Start and Takeoff
- Fuel fraction (unnumbered, p. 126): `W2/W1 = 0.97 – 0.975` (assume 2.5–3% of W_TO burned).

### Phase 2 — Climb and Accelerate to Cruise Conditions
- Not significant (first iteration) if cruise M < 0.4; significant above M 0.4 and/or 10,000 ft.

### Fig 5.2 — Weight fractions for climb–acceleration phase — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.2, p. 127]* — `Wf/Wi` vs Mach (log, 0.1–10), single collapsed curve
across aircraft types (`W_fuel/Wi = 1 − Wf/Wi`). Data points: Composite LWF (Fig 4.10), Lockheed
L-1011, F-18C, F-15C, Concorde, Lockheed SR-71 *(read from plot)*:

| Mach | Wf/Wi |
|---|---|
| 0.3 | ~0.995 |
| 1.0 | ~0.97 |
| 2.0 | ~0.93 |
| 3.0 | ~0.85 (Concorde, SR-71 region) |
| 4.5 | ~0.71 |

Use Fig 5.2 for the first design iteration; refine later with the energy-state approximation (Ch. 4).

### Phase 3 — Cruise Out
Needs: cruise speed & altitude, configuration AR & sweep, cruise fuel consumption.
Fuel fraction from the Breguet range equations (Chapter 3).

### Fig 5.3 — (L/D)max vs Mach number for typical cruise aircraft — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.3, p. 128]* — Two families of curves: (L/D)max vs Mach for constant
Aspect Ratio (2,3,4,6,8,10 — nearly flat, slowly decreasing with Mach), and "Existing"
(solid)/"Optimistic" (dashed) envelope curves through real-aircraft data points (U-2S, L-1011,
F-16C, Concorde, SR-71). *(read from plot)*

By constant-AR curves (representative values at M=1, nearly flat across shown Mach range):

| AR | (L/D)max |
|---|---|
| 2  | ~9.3 |
| 3  | ~10.8 |
| 4  | ~12.6 |
| 6  | ~15.8 |
| 8  | ~18.7 |
| 10 | ~22.5 |

By existing-aircraft envelope curve *(read from plot)*:

| Mach | (L/D)max "Existing" | (L/D)max "Optimistic" |
|---|---|---|
| 1.3 | ~10 | ~13 |
| 1.7 | ~8.2 | ~11 |
| 2.3 | ~7 | ~9.7 |
| 3.0 | ~6.7 (SR-71 pt ~6.5) | ~8.7 |
| 4.5 | ~5.3 | ~6.8 |

Named aircraft data points *(read from plot)*: U-2S (L/D)max ≈ 23 @ M≈0.5; L-1011 ≈ 17 @ M≈0.85;
F-16C ≈ 11 @ M≈0.9; Concorde ≈ 7.2 @ M≈2.0; SR-71 ≈ 6.5 @ M≈3.0.

- **Eq (5.2)** — turbojet/turbofan range (Breguet): `R = (V/C)·(L/D)·ln(W3/W4)`  *[Nicolai & Carichner, Eq. (5.2), p. 128]*
- **Eq (5.3)** — propeller (piston or turboshaft) range: `R = (η/C)·(L/D)·ln(W3/W4)`  *[Nicolai & Carichner, Eq. (5.3), p. 128]*
  - Solve Eq (5.2)/(5.3) for `W3/W4`. For max range, cruise L/D approaches (but stays below)
    (L/D)max: constant-altitude cruise → L/D = 86.6% of (L/D)max; cruise-climb → L/D = 94% of
    (L/D)max (from Ch. 3, Table 3.2). TSFC from engine data (Ch. 14 or Appendix J). Subsonic
    turbojet/turbofan cruises most efficiently above 30,000 ft at ~75% partial power.

### Table 5.2 — Representative Values for Subsonic C_D0
*[Nicolai & Carichner, Table 5.2, p. 129]*

| Aircraft Type | Subsonic C_D0 |
|---|---|
| High-subsonic jet transport | 0.014–0.02 |
| Supersonic fighter aircraft | 0.014–0.022 |
| Blended wing–body (tailless) jet aircraft | 0.008–0.014 |
| Large turboprop aircraft | 0.018–0.024 |
| Low-altitude subsonic cruise missile (high W/S) | 0.03–0.04 |
| Small single-engine propeller — retractable gear | 0.022–0.030 |
| Small single-engine propeller — fixed gear | 0.026–0.04 |
| Agricultural aircraft — with spray system | 0.07–0.08 |
| Agricultural aircraft — without spray system | 0.06 |
| High-performance sailplane | 0.006–0.01 |

- **Eq (5.4)** — max L/D for a symmetric aircraft: `(L/D)max = 1/(2·√(C_D0·K))`  *[Nicolai & Carichner, Eq. (5.4), p. 129]*
  (Same relation as Eq 3.10a; C_D0 from Table 5.2 or Appendix G, or select AR and read
  (L/D)max off Fig 5.3 directly.)
- **Eq (5.5)** — drag-due-to-lift factor: `K = 1/(π·AR·e)`  *[Nicolai & Carichner, Eq. (5.5), p. 130]*
  (e = wing efficiency factor, Fig G.9.)
  - Range can be refined in later iterations by subtracting the phase-2 climb distance from
    the cruise range, and/or by breaking cruise into smaller segments (Ch. 3).

### Phase 4 — Acceleration to High Speed
- Weight fraction from Fig 5.2. **Worked sub-example:** accelerate cruise (M=0.9) → dash (M=2.5):
  `Wf/Wi(M=0.1–0.9) = 0.975`, `Wf/Wi(M=0.1–2.5) = 0.91` → `W5/W4 = 0.91/0.975 = 0.933`.

### Phase 5 — Combat
Mission specifies either (1) minutes at max power at a given Mach/altitude, or (2) a number of
turns at max power at a given load factor/Mach/altitude — both reduce to a loiter-time condition
at max power. Turn rate from Ch. 3 Eq (3.32): `ψ̇ = g·√(n²−1)/V` (rad/s), g = 32.174 ft/s²;
time = (number of turns)·360°/turn rate.
- **Combat fuel** (unnumbered, p. 131): `Combat fuel = (TSFC)·(maximum thrust)·(time)`
  - Sizes only the fuel that must be available for combat; the aircraft's actual combat
    performance with that fuel is determined later in the design cycle.
  - Note on notation: `C` generically denotes TSFC (turbine engines) or BSFC (propeller engines)
    — context determines which.

### Phase 6 — Cruise Back
Treated like Phase 3 (cruise out); return altitude is typically higher (lighter aircraft) and
return L/D slightly higher if external stores/weapons were dropped.

### Phase 7 — Loiter
- **Eq (5.6)** — jet endurance (loiter fuel fraction), from Ch. 3 Eq (3.17):
  `E = (1/C)·(L/D)·ln(W7/W8)`  *[Nicolai & Carichner, Eq. (5.6), p. 131]*
  (E in hours; C = TSFC in lb fuel/(lb thrust·h). Max endurance at max (L/D)/C, close to but not
  exactly at (L/D)max — use loiter L/D ≈ (L/D)max as a conservative estimate.)
- **Eq (5.7)** — propeller endurance (simplified form of Ch. 3 Eq 3.22, preferred when detail is
  lacking on the first iteration): `E = (η/C)·(L/D)·(1/V)·ln(W3/W4)`  *[Nicolai & Carichner, Eq. (5.7), p. 131]*

### Phase 8 — Reserve and Trapped Fuel
- **Reserve fuel:** typically **5%** of mission fuel; strictly unusable reserve.
- **Trapped fuel/oil:** typically **1%** of mission fuel (unusable, trapped in lines/pumps).

---

## §5.5 Determining W_TO

- **Eq (5.8)** — overall mission fuel fraction (product of phase fractions):
  `[W_final/W_TO] = [W8/W1] = [W2/W1]·[W3/W2]···[W8/W7]`  *[Nicolai & Carichner, Eq. (5.8), p. 132]*
- **Eq (5.9)** — fuel weight required:
  `W_fuel = (1 + reserve + trapped)·(1 − W8/W1)·W_TO`  *[Nicolai & Carichner, Eq. (5.9), p. 132]*
  - If weight discontinuities exist (bombs dropped, missiles fired) and/or a fuel phase can't be
    expressed as a simple fraction (e.g. combat fuel), solve Eq (5.9) in segments (see Example 5.1).
- Available empty weight (unnumbered, p. 132): `(W_empty)_A = W_TO − W_fuel − W_fixed`
- Required empty weight `(W_empty)_R`: from Appendix I empty-weight trend data, adjusted for
  advanced materials/concepts. Iterate W_TO until:
  `|(W_empty)_A − (W_empty)_R| ≤ 0.01·(W_empty)_R` *(unnumbered convergence criterion, p. 132)*

### Fig 5.4 — Empty-weight fraction for current aircraft (fighters, bombers, light aircraft) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.4, p. 133]* — Weight Fraction (log, 0.1–1.0) vs Takeoff Weight
(log, 10³–10⁶ lb). Data for Bomber/Transport, Light Civil, and Fighter aircraft collapse onto:

`Empty Weight (metal a/c) / Takeoff Weight = 0.911 / TOGW^0.053`

Also plotted: three "Fixed Weight = const" diagonal lines (1000 lb, 10,000 lb, 102,000 lb) and a
horizontal "Fuel Weight/Takeoff Weight = 0.425" line (worked-example value). At W_TO = 790,000 lb
with fixed weight 102,000 lb: empty-weight fraction ≈ 0.444, fixed-weight fraction ≈ 0.131,
fuel fraction ≈ 0.425 (sums to 1.0 — the graphical W_TO solution method).

- W_TO iteration: plot empty-weight fraction and fixed-weight fraction (both monotonic in W_TO)
  against the (W_TO-independent) fuel-weight fraction line; solution is where all three fractions
  sum to 1.0.
- First-iteration W_TO estimate should be as close as possible to the converged value since
  substantial subsequent design work depends on it.

### Example 5.1 — Advanced Composite Lightweight Fighter (LWF)

Historical note: the USAF's 1972 LWF program (pushed by John Boyd's "Fighter Mafia") sought a
low-cost F-15-class day fighter (~20,000 lb class), optimized for air combat at Mach 0.6–1.6 and
30,000–40,000 ft. Finalists: General Dynamics YF-16 (one F100-PW-100, 23,000 lb TSLS) and
Northrop YF-17 (two YJ101-GE-100, 14,400 lb TSLS each). YF-16 selected (better maneuverability,
lower LCC as a single-engine design) → became the F-16 (4500+ built); YF-17 became the basis for
the F-18 Hornet (1500+ built).

**USAF LWF Mission Requirements** *(this is the same "Composite LWF" example used throughout
Chs 3–5, and the historical basis for the F-16)*:

| Requirement | Value |
|---|---|
| Purpose | Lightweight, low-cost, air-superiority, day fighter |
| Radius (internal fuel only) | 250 n mile |
| Maximum speed | Above Mach 1.6 |
| Cruise condition | Not specified |
| Combat fuel sizing | One acceleration M 0.9→1.6 at 30,000 ft; 4 min max A/B at M 0.9, 30,000 ft |
| Loiter | Sea level at Mach 0.35 for 20 min |
| Reserve | 5% of fuel |
| Crew | One |
| Weapons | Two AIM-9 missiles; one 20-mm M-61 cannon |
| Engine | One F100 or two YJ-101 afterburning turbofans |
| Structures | Limit load factor 7.33 @ 80% internal fuel + missiles + full ammo; placard/flutter limit Mach 1.1 at SL; advanced composites throughout |

**LWF Fixed Weights** *[Nicolai & Carichner, p. 135]*:

| Item | Weight |
|---|---|
| Pilot plus gear | 200 lb |
| 2 AIM-9 missiles plus racks | 472 lb |
| M-61 cannon plus accessories | 485 lb |
| 560 rounds of 20-mm shells | 320 lb |
| **Total** | **1477 lb** |
| **W_fixed (rounded)** | **1500 lb** |

**Phase-by-phase fuel fractions** (mission profile per Fig 5.1):
- Phase 1 (takeoff/climb-out, 2.5% of W_TO): `W2/W1 = 0.975`
- Phase 2 (climb-accel to cruise, M=0.9 near tropopause, Fig 5.2): `W3/W2 = 0.975`
- Phase 3 (cruise out 250 n mile): AR=3 assumed → (L/D)max ≈ 10 from Fig 5.3, conservative cruise
  L/D = 9 (checked via Eqs 5.4–5.5: C_D0=0.016, e=0.8 → K=0.1326 → (L/D)max=10.8, matches F-16
  in Fig G.3). TSFC = 0.93 (F100 data, Fig 14.7d/e). Breguet:
  `Wi/Wf = W3/W4 = exp[Radius·C/(V·L/D)] = exp[(250)(0.93)/((516.24)(9))] = 1.05`
- Phase 4 (combat accel M0.9→1.6 at 30,000 ft, via Fig 5.2): `(Wf/Wi)to M=0.9 = 0.975`,
  `(Wf/Wi)to M=1.6 = 0.952` → `W5/W4 = 0.952/0.975 = 0.976`
- Phase 5 (combat turns, max power, 4 min at M=0.9/30,000 ft): F100 data (Fig 14.7b) give
  Thrust = 12,000 lb, TSFC = 2.17 → **Combat W_fuel = Thrust·TSFC·Time = 1740 lb** (absolute,
  not a fraction — handled as a segment subtraction).
- Phase 6 (cruise back 250 n mile, same assumptions as Phase 3): `W6/W7 = 1.05`
  (climb-to-cruise fuel/distance neglected — approximation within the noise of this initial estimate)
- Phase 7 (loiter, sea level, M=0.35, 20 min): F100 partial-power TSFC = 0.84, loiter L/D = 8.7:
  `Wf/Wi = exp[Endurance·C/(L/D)] = exp[(20)(60)(0.84)/((8.7)(3600))] = 1.033`

**Iteration for W_TO:** required empty weight from Appendix I Fig I.1 (upper trend line).
Assume `W_TO = W1 = 13,000 lb`. Weight at start of combat:
`W5 = (W2/W1·W3/W2·W4/W3·W5/W4)·W1 = (0.8839)(13,000) = 11,491 lb`.
Subtract expended/dropped items to get W6 (start of cruise-back): missiles 348 lb + 20-mm ammo
320 lb + 4-min combat fuel 1740 lb = **total 2408 lb** subtracted from W5 to obtain W6.

`W6 = 9083 lb`. Weight at landing: `W8 = (W7/W6·W8/W7)·W6 = 8379 lb`.

Fuel weight required for the mission: `(W_fuel)_mission = W_TO − W8 − missiles − ammo = 3953 lb`.
Total fuel (adding 5% reserve + 1% trapped): `W_fuel = 1.06·(W_fuel)_mission = 4190 lb`.

Available empty weight: `(W_empty)_A = W_TO − W_fuel − W_fixed = 13,000 − 4190 − 1500 = 7309 lb`.

Required empty weight: because advanced composites are used, conventional-metal empty weights
from Appendix I are **reduced by 16%** (documented assumption). Using the Appendix I Fig I.1
trend line for high-(T/W)_TO, low-(W/S)_TO fighters — `W_empty = 1.2·(W_TO)^0.947` — reduced 16%:
`(W_empty)_R = 7932 lb`.

**Conclusion:** W_TO = 13,000 lb cannot fly the mission — available empty weight is 623 lb less
than required. Iterate (increase W_TO) until `|(W_empty)_A − (W_empty)_R| ≤ 0.01·(W_empty)_R`.

### Fig 5.5 — Determination of required W_TO for composite LWF — **DATA GRAPH (solution)**
*[Nicolai & Carichner, Fig. 5.5, p. 139]* — W_empty (1000 lb) vs W_TO (1000 lb, 10–18), Radius=250
n mile, W_fixed=1500 lb. Two lines: `(W_empty)_A` (available, steeper) and `(W_empty)_R` (required,
Appendix I trend −16%), intersecting at **W_TO ≈ 15.4 (1000 lb) → Required W_TO = 15,400 lb**.
(Text notes further refinement dropped this to **15,000 lb**, the value used in Table 3.1.)

### Mission Trades — Influence of Payload and Radius on W_TO

Mission trades (payload/radius sensitivity) are one of three key conceptual-design trade
studies, alongside design trades and technology trades (Fig 1.15).

### Fig 5.6 — Influence of W_fixed on W_TO for composite LWF — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.6, p. 140]* — Takeoff Weight (1000 lb) vs W_fixed (1000–3000 lb) /
ΔW_pay (0–1500 lb), radius = 250 n mile. Base point: W_fixed=1500 lb, W_TO≈15,400 lb. Two nearly
coincident lines: "Carries ΔW_pay out and back" (solid) vs "Drops ΔW_pay during combat" (dashed).

**Weight sensitivity ratio (= aircraft growth factor):** `ΔW_TO/ΔW_pay = 3.8` *(read from plot,
stated in text)* — a 500-lb fixed-weight increase costs **1900 lb** of W_TO. Growth factor
`= Δ(TOGW)/Δ(payload weight)`, depends on mission character and payload fraction (larger payload
fraction → larger growth factor):
- Fighter aircraft (payload fraction 10–15%): growth factor ≈ 3.5–4.0.
- Air-launched cruise missile (payload fraction ≥15%): growth factor ≈ 4.
- Long-endurance ISR aircraft, e.g. RQ-4A Global Hawk (payload fraction < 10%): growth factor ≈ 2.5.
- Changing mission radius: recompute W3/W4 and W6/W7 and re-iterate (Fig 5.7). For the LWF,
  **+50 n mile radius costs an extra 1000 lb of W_TO**.

---

## §5.6 Range- or Payload-Dominated Vehicles

Long range/endurance (e.g. > 3000 n mile) or large payload (e.g. > 50,000 lb) requirements drive
large fuel fraction or large fixed-weight fraction respectively → large W_TO. As W_TO increases,
empty-weight fraction *decreases* (Fig 5.4) — fortunate, since otherwise long-range/high-payload
missions would have no solution. Two reasons empty-weight fraction improves with size: (1) better
structural efficiency (lower structural-weight fraction) at larger scale; (2) many systems/
components (avionics, hydraulics, actuators, etc.) scale sub-linearly with aircraft size.
Empty-weight fraction (Fig 5.4) falls from ~0.63 average at W=1000 lb to ~0.44 at 10⁶ lb for
conventional metal structure; advanced materials/concepts decrease it further.

### Fig 5.7 — Influence of mission radius on W_TO for composite LWF — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.7, p. 141]* — Takeoff Weight (1000 lb) vs Radius (200–400 n mile),
W_fixed=1500 lb, roughly linear *(read from plot)*:

| Radius (n mile) | W_TO (1000 lb) |
|---|---|
| 230 | ~14.9 |
| 250 | ~15.4 (base point) |
| 300 | ~16.7 |
| 350 | ~17.9 |
| 400 | ~19.2 |

Confirms: +50 n mile radius ≈ +1000 lb W_TO for this design.

### Example 5.2 — Extended Range or Payload Aircraft (Long-Range Transport)

| Mission Requirement | Value |
|---|---|
| Purpose | Long-range transport aircraft |
| Range (unrefueled) | 6000 n mile |
| Payload | 100,000 lb |
| Crew | Nine |
| Cruise / Max speed | Subsonic |
| Field length / Service ceiling | Not specified |
| Reserve | 5% of mission fuel |
| Crew + equipment (assumed 2000 lb) | → W_fixed = 102,000 lb |
| High-bypass turbofan (assumed) | → cruise TSFC = 0.6 at Mach 0.8, 36,000 ft (Tables 5.3, 14.8, J.1) |
| AR = 7 (assumed) | → (L/D)max ≈ 18 from Fig 5.3, cruise L/D = 17 |

Phase fractions: `W2/W1 = 0.97`; `W3/W2 = 0.978` (Fig 5.2, climb-accel to M=0.8); Phases 4–7 not
applicable (=1.0); cruise (Breguet): `W3/W4 = exp[(6000)(0.6)/((459)(17))] = 1.583`.
Landing/takeoff ratio: `W8/W1 = (0.97)(0.978)/1.583 = 0.599`.
Fuel fraction: `W_fuel/W_TO = 1.06·[1 − W8/W1] = 0.425` (this is the Fig 5.4 example value).

**Iteration:** assume `W_TO = 790,000 lb`. From Fig 5.4, empty-weight fraction ≈ 0.444:
`(W_empty)_A = 790,000·(1−0.425) − 102,000 = 352,250 lb`;
`(W_empty)_R = 0.444·790,000 = 350,760 lb` — difference within 1%, so **W_TO = 790,000 lb** is a
good solution for 6000 n mile range / 102,000 lb payload (100,000 lb payload + 2000 lb crew).

### Table 5.3 — Information on 747 and C-5 Aircraft
*[Nicolai & Carichner, Table 5.3, p. 142]*

| Aircraft | W_TO (lb) | Range (n mile) | Payload (lb) | Engine Type | Cruise TSFC (Table J.1) |
|---|---|---|---|---|---|
| 747-200 | 775,000 | 3744 | 200,000 | JT9D-7 | 0.62 |
| C-5A | 728,000 | 3050 | 220,000 | TF39-GE-1 | 0.582 |
| C-5A | 728,000 | 5500 | 112,600 | TF39-GE-1 | 0.582 |

### Fig 5.8 — Variation of payload with range for large transport aircraft — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.8, p. 143]* — Payload (1000 lb) vs Range (1000 n mile, 0–9). Example
5.2 result (solid) vs C-5A Ops Planning Report data (dashed, circles). Payload limited to 250,000
lb up to ~2.4k n mile, then trades off with range *(read from plot)*:

| Range (1000 n mile) | Payload, Example 5.2 (1000 lb) | Payload, C-5A data (1000 lb) |
|---|---|---|
| 0–2.4 | 250 (limit) | 260 (limit) |
| 4.0 | ~180 | ~180 |
| 5.6 | ~120 | ~120 |
| 7.2–8.3 | 0 (zero-payload ferry range) | ~0 (at ~7.2) |

Good agreement between the Example 5.2 model and actual C-5A operational data validates the method.

### Example 5.3 — Low-Altitude, Subsonic Cruise Missile

Driving requirements: long range + high penetration survivability (stealth, low-altitude
terrain-following to exploit horizon range/terrain masking/clutter) — despite low altitude being
aerodynamically/propulsively inefficient (turbofans want > 30,000 ft for low TSFC).

| Cruise Missile Mission Requirement | Value |
|---|---|
| Range | 1900 n mile |
| Payload | W-80 nuclear warhead, 300 lb |
| Speed | Mach 0.7 at 200 ft AGL |
| Engine | Williams F107 turbofan |
| Profile | Terrain-follow M0.7/200 ft AGL, limit load factor n=+1.8,−0.5g |
| TSFC | 1.15 (average installed, cruise-to-max-thrust, Fig 5.9) |
| C_D0 | 0.035 (Table 5.2) |
| Wing AR | 6, zero sweep |
| K | 0.059 for e=0.9 (Fig G.9) |
| (L/D)max | `1/(4·C_D0·K)^0.5 = 11` |

### Fig 5.9 — F-107 turbofan engine at sea level — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 5.9, p. 144]* — TSFC vs Thrust/Max Thrust (0.2–1.0), Installed
(dashed) vs Uninstalled (solid), at Mach 0.5, 0.7 *(read from plot)*:

| Thrust/Max Thrust | TSFC, M=0.7 Installed | TSFC, M=0.7 Uninstalled | TSFC, M=0.5 Uninstalled |
|---|---|---|---|
| 0.4 | ~1.30 | ~1.19 | ~1.04 |
| 0.6 | ~1.20 | ~1.10 | ~0.96 |
| 0.8 | ~1.14 | ~1.06 | ~0.93 (≈min) |
| 1.0 | ~1.11 | ~1.04 | ~0.94 |

From Table 3.2 (constant-altitude max range): `C_L = (C_D0/3K)^0.5 = 0.44`;
Cruise `L/D = 0.866·(L/D)max = 9.5`.

- **Eq (5.10)** — cruise fuel fraction (Breguet, Eq 5.2 form):
  `W3/W4 = exp[(1900)(1.15)/((463)(9.5))] = exp(0.497) = 1.644`  *[Nicolai & Carichner, Eq. (5.10), p. 145]*

Assume launch weight `W_L = W3 = 1800 lb`: `W_fuel = W3 − (W4/W3)·W3 = 1800 − 1095 = 705 lb`;
`(W_empty)_A = W3 − W_payload − W_fuel = 795 lb`; from Fig I.7, `(W_empty)_R = 801 lb` → **an
1800-lb cruise missile can accomplish the mission** (initial estimate).

**Sanity check vs Convair/Raytheon AGM-109A Tomahawk** (same range/engine/payload):

| Tomahawk Parameter | Value |
|---|---|
| Range | 1900 n mile |
| Engine | Williams F107 turbofan |
| Payload | W-80 warhead, 300 lb |
| Launch weight | 2860 lb |
| Fuel weight | 1200 lb |
| Empty weight | 1350 lb |
| Wing AR | 6, zero sweep |
| Wing area | 12 ft² |
| C_D0 | 0.035 |
| K | 0.059 |

The 1800-lb estimate undershoots the actual 2860-lb Tomahawk — flagged in the text as revealing
**a fundamental flaw in the design analysis, to be resolved in Chapter 6** (i.e., not enough
volume/fuel-tankage was checked against the assumed launch weight — a reminder that the W_TO
iteration alone doesn't guarantee a *physically packageable* aircraft).

---

## §5.7 High Altitude Atmospheric Research Platform (HAARP)

Historical context: late-1980s concern over South Pole ozone depletion required in-situ
atmospheric measurement up to 120,000 ft — beyond the U-2S (70,000 ft) and Condor (66,000 ft). In
1990 NASA commissioned the Lockheed Skunk Works to develop a manned aircraft for measurements at
100,000 ft worldwide; the program was named HAARP (Ref. [1]). Used here as an **unmanned aircraft**
sizing example, carried forward into Chapters 6, 14, 18, and 19.

### Example 5.4 — HAARP Requirements

| Requirement | Value |
|---|---|
| Range | 6000 n mile total (5000 n mile at 100,000 ft, Mach 0.6) |
| Payload | 2500 lb at 500 watts |
| Propulsion | Turbocharged piston engine(s) |
| Aerodynamics | Efficient wing design at flight Re < 1.0×10⁶ |
| Structure | Metal — size via `W_empty = 0.911·(TOGW)^0.947` |
| BSFC | 0.42 lb fuel/(hour·hp) |
| Propeller efficiency @100,000 ft/M=0.6 | 0.90 |
| Engine start/takeoff/climb/accel weight fraction | W3/W1 = 0.93 |
| Aspect ratio | 25 |
| Span | < 150 ft (worldwide airport operability) |

BSFC=0.42 is realistic for sea-level (14.7 psia) piston engines; at 100,000 ft static pressure is
only 0.158 psia, requiring a turbocharger boost factor of **93** — with substantial resulting air
heating, assumed cooled via wing-mounted ram-air heat exchangers that **decrease aircraft L/D by 22%**.

### Table (unnumbered) — HAARP airfoil and cruise-out sizing
*[Nicolai & Carichner, p. 147]* (airfoil generated with MIT's ISES design code)

| Parameter | Value |
|---|---|
| Maximum t/c | 12.2%, at 50% chord |
| C_lmin | 0.4 |
| Camber | 4% |
| K″ | 0.006 |
| K′ | `1/(AR·e·π) = 0.013` for e=0.97 (Fig 13.5) |
| C_Dmin | 0.014 |
| Maximum L/D | 27 [from Eq (3.10b), with 22% heat-exchanger penalty already applied] |
| Cruise C_L | 0.89 [C_Lopt from Eq (3.8b)] |

Cruise-out weight fraction: `W3/W4 = exp[(5000)(0.42)/((326)(0.9)(27))] = 1.3`.
`W8/W1 = (0.93)(1/1.3) = 0.72`; `W_fuel/W_TO = 1.06·(1.0 − 0.72) = 0.30`.
Iteration: assume `TOGW = 16,000 lb` → `(W_empty)_A = 16,000 − 4800 − 2500 = 8700 lb`;
`(W_empty)_R = 0.911·(TOGW)^0.947 = 8726 lb` — difference < 1%, converged.

### Fig 5.10 — HAARP mission profile
*[Nicolai & Carichner, Fig. 5.10, p. 147]* — Map diagram: base at Southern Chile (53°S, 71°W),
outbound leg 700 n mile, 2500-n-mile-radius loiter/research orbit around the South Pole
(90.00°S), 300 n mile leg, cruising at 100,000 ft. Total range = 6000 n mile, payload = 2500 lb.

### Fig 5.11 — HAARP configuration
*[Nicolai & Carichner, Fig. 5.11, p. 148]* — Three-view diagram. Key data:

| Parameter | Value |
|---|---|
| Takeoff weight | 16,000 lb |
| Span | 269 ft |
| Aspect ratio | 25 |
| Payload | 2500 lb |
| Fuel weight | 4800 lb |
| Takeoff W/S | 5.5 psf |
| Range at 100,000 ft/Mach=0.6 | 5000 n mile |
| Total range | 6000 n mile |

Labeled features: removable wingtip (length 67 ft), 24-ft-diameter high-altitude propeller, 8-ft
low-altitude propeller, 500-hp three-stage turbocharged liquid-cooled IC engine, ailerons,
spoilers, aviation gasoline (417 gal), payload distributed in forward fuselage bay (1629 lb) and
engine pods (289 lb + 294 lb each), ram-air heat exchangers (wing leading-edge installation).

The HAARP example continues in: Ch. 6 §6.6.1 (wing loading), Ch. 14 §14.2.1 (turbocharger
design), Ch. 18 §18.10 (piston engine sizing), Ch. 19 §19.14 (wing structural design).

---

*Chapter 5 complete (Eqs 5.1–5.10, Tables 5.1–5.3, Figs 5.1–5.11). Next: Chapter 6 — Estimating the Takeoff Wing Loading.*