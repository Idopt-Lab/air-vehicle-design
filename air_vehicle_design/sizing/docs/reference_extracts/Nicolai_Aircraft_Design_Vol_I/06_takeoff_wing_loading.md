# Chapter 6 — Estimating the Takeoff Wing Loading

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 6 "Estimating the Takeoff Wing Loading," printed pp. 151–170.

---

## §6.1 Introduction

Takeoff wing loading `(W/S)_TO` sizes the wing and locks in dominant performance features.
Determined by considering: (1) range (cruise efficiency), (2) endurance (loiter efficiency),
(3) landing and takeoff, (4) air-to-air combat (maneuverability), (5) air intercept (min accel
time), (6) high altitude, (7) high altitude/long endurance, (8) low-altitude ride quality — these
requirements conflict (good cruise efficiency wants high (W/S)_TO, > 100 psf; good combat
maneuverability wants low (W/S)_TO). No right answer, only a best compromise for the dominant
mission phase while keeping the rest of the mission acceptable.

### Table 6.1 — Takeoff Wing Loading Trends
*[Nicolai & Carichner, Table 6.1, p. 153]*

| Dominant Mission Requirement | (W/S)_TO (psf) | Example |
|---|---|---|
| High-altitude, long-endurance solar-powered ISR | 0.5–3.0 | Helios |
| Competition sailplanes | 7–12 | ASW 17 |
| Light civil aircraft, short range/field length | 10–30 | C-172 |
| High-altitude, long-endurance hydrocarbon-powered ISR | 25–50 | RQ-4A |
| STOL and utility transports | 40–90 | C-130 |
| Short or intermediate range, moderate field length | 50–90 | Learjet 35 |
| Long-range transports and bombers (>3000 n mile) | 110–150 | B-747 |
| Fighter, high-altitude | 30–60 | F-106 |
| Fighter, air-to-air | 50–80 | F-15A |
| Fighter, close air support | 65–90 | A-10A |
| Fighter, strike interdiction | 90–130 | F-4E |
| Fighter, interceptor | 120–150 | F-104G |
| Low-altitude subsonic cruise missiles | 200–240 | AGM-109 |

---

## §6.2 Range-Dominated Vehicle (Cruise Efficiency)

Select (W/S)_TO so the aircraft flies at conditions for maximum range for a given fuel load (or
minimum weight/cost for a given range). Turbine aircraft at max cruise efficiency fly where
`(V/C)(L/D)` is max [Eq (3.26a)]; cruise L/D is close to but less than (L/D)max — 87% for
constant-altitude cruise, 94% for cruise-climb (Fig 3.2 — actually the 86.6%/94% figures derive
from Table 3.2). Propeller aircraft at max range fly where `(1/C)(L/D)` is max [Eq (3.30)], i.e.
at (L/D)max directly (Table 3.2).

For turbine aircraft, cruise altitude ≈ 35,000 ft (near-minimum TSFC, Ch. 14). Long-range
aircraft: fuel fraction ≈ 0.4 → wing loading changes (decreases) ~40% over the cruise. For a
constant-altitude profile, the aircraft slows to keep (W/S)/q constant so `C_L = (C_D0/3K)^0.5`
(Fig 3.2/Table 3.2).

### Example 6.1 — Air-Launched Cruise Missile (resolves the Chapter 5 cliffhanger)

**Question:** why did the Ch. 5 cruise-missile design close at 1800 lb launch weight vs the actual
Tomahawk's 2860 lb, given matching AR, C_D0, K, payload, engine, and empty-weight trends?

Flying at max range, constant altitude gives constant `C_L = (C_D0/3K)^0.5 = 0.44`, i.e. wing
loading at launch `W/S = q·C_L = (725)(0.44) = 319 psf` and a 5.64-ft² wing.
`(L/D)max = 11` at `C_L = 0.77` → cruise `L/D = 0.866·11 = 9.5` at launch (matches the Ch.5
assumption). **But** as fuel burns, C_L must decrease to hold L=W, so by mission's end
`C_L = 0.27` and `L/D = 6.9` (at Mach 0.7, 200 ft) — because the missile cannot slow down or climb
(required for survivability at very low altitude), unlike a normal aircraft.

### Fig 6.1 — Cruise missile L/D throughout the entire C_L range — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.1, p. 154]* — L/D vs C_L (0–0.8), for `C_D = 0.035 + 0.059·C_L²`
at Mach 0.7, 200 ft. Marked points: C_L at launch (W/S=319) → L/D≈9.5; C_L at end (W/S=195) →
L/D≈6.9 *(read from plot, consistent with text)*:

| C_L | L/D |
|---|---|
| 0.1 | ~2.8 |
| 0.2 | ~5.3 |
| 0.27 (end) | ~6.9 |
| 0.44 (launch) | ~9.5 |
| 0.6 | ~10.7 |
| 0.77 | ~11.0 (max) |
| 0.8 | ~11.0 |

**The Chapter 5 mistake:** Eq (5.10) assumed a *constant* L/D = 9.5 over the entire 1900 n mile,
when L/D actually decays from 9.5 to 6.9 as the missile can't slow/climb to hold optimum C_L.
Using the correct **average L/D = 8.2** instead would have sized the missile to near the actual
Tomahawk launch weight of 2860 lb. *(Key lesson: constant-L/D Breguet assumptions fail when the
mission profile can't adjust C_L to stay near (L/D)max.)*

### Example 6.2 — Long-Range Subsonic Transport

Determine best (W/S)_TO for a turbine-powered long-range subsonic transport, fuel fraction 0.4,
cruise-climb (constant throttle) profile:

| Parameter | Value |
|---|---|
| Start of cruise | Mach = 0.8, 30,000 ft |
| C_D0 | 0.018 (Fig G.1) |
| AR | 7.25, 25° sweep (Fig G.9, e=0.8) |
| K | 0.0549 |
| (L/D)max | 16 |
| Cruise L/D | 15 |
| Cruise C_L | `(C_D0/2K)^0.5 = 0.41` (Table 3.2) |
| q | 282 psf |
| Start-of-cruise W/S | `q·C_L = 116 psf` |
| **(W/S)_TO** | **≈ 120 psf** |

End-of-cruise check: W/S at end ≈ `120·(1−0.4) = 72 psf`; C_L unchanged (0.41, since C_D0/K
unchanged) → `q = (W/S)/C_L = 175 psf` → at Mach 0.8 this q occurs at **40,000 ft**, a reasonable
end-of-cruise altitude.
- Real airliners can't fly continuous cruise-climb (ATC restricts to discrete 1000-ft even/odd
  corridors) — actual profile approximates cruise-climb via **step-climbs** (constant-altitude
  segments + ~2000-ft climb segments).

**Two rules of aircraft design** (repeated, p. 155): (1) there are no right answers, only a best
answer; (2) there are no rules.

### Example 6.3 — Boeing B-47 and Avro Vulcan B-1 Comparison

Early-1950s USAF B-47 vs RAF Vulcan B-1: both designed for high cruise efficiency (high L/D) as
strategic nuclear bombers penetrating the USSR, but opposite wing-loading philosophy. B-47:
high-(W/S), high-AR wing/body/tail, high-subsonic at 30,000–40,000 ft. Vulcan B-1: low-(W/S),
low-AR blended wing/body tailless, high-subsonic at 50,000 ft (also required high-altitude
penetration to survive Soviet fighters); low W/S → [continued next page: presumably higher
attainable altitude at a given thrust].

### Table 6.2 — Takeoff Wing Loading and Fuel Fraction for Various Cruise-Dominant Aircraft
*[Nicolai & Carichner, Table 6.2, p. 155]*

| Aircraft | (W/S)_TO (psf) | W_fuel/W_TO |
|---|---|---|
| C-5A | 117 | 0.417 |
| KC-135 | 124 | — |
| B-747 | 141 | 0.428 |
| L-1011 | 124 | 0.352 |
| DC-10 | 153 | 0.42 |
| B-52G | 122 | 0.62 |
| C-17 | 152 | 0.34 |
| B-1B | 244 | 0.47 |
| Tomahawk | 213 | 0.47 |

### Fig 6.2 — Design characteristics comparison — Boeing B-47 vs Avro Vulcan B-1
*[Nicolai & Carichner, Fig. 6.2, p. 156]* — Three-view silhouettes plus comparison table:

| Parameter | Boeing B-47 | Avro Vulcan B-1 |
|---|---|---|
| Wing Area (ft²) | 1430 | 3446 |
| Total Wetted Area (ft²) | 11,300 | 9,500 |
| Span (ft) | 116 | 99 |
| Wing Loading (lb/ft²) | 140 | 43 |
| Span Loading (lb/ft) | 1750 | 1520 |
| Aspect Ratio | 9.43 | 2.84 |
| C_Dmin | 0.0198 | 0.0069 |
| K = 1/(π·AR·e) | 0.0425 | 0.125 |
| Value of e | 0.8 | 0.9 |
| Max L/D | 17.25 | 17.0 |
| C_Lopt | 0.682 | 0.235 |
| Max Cruise C_L | 0.48 | 0.167 |
| C_Dmin·S_ref | 28.3 | 23.8 |
| Wetted Area/S_ref | 7.9 | 2.8 |

Both aircraft achieve nearly identical (L/D)max ≈ 17 via opposite strategies: B-47 = traditional
high-AR wing/fuselage (higher C_D0, low K); Vulcan B-1 = blended low-AR wing/body tailless (low
wetted-area ratio → low C_D0 despite high K from low AR). Span loading (lb/ft), not wing loading,
is what actually governs induced drag/climb performance for a fixed span constraint — both
aircraft have similar span loading despite hugely different wing loading.

---

## §6.3 Endurance or Loiter

Turbine aircraft: max loiter efficiency at max L/D. Propeller aircraft: max loiter at max
(L/D)/V. C_L conditions given in Table 3.2.

### Example 6.4 — High-Altitude, Long-Endurance ISR (RQ-4A Global Hawk)

Find (W/S)_TO for the RQ-4A Global Hawk, loiter starting at Mach 0.6, 55,000 ft. Highly cambered
LRN 1015 airfoil (shown in Fig 2.2 pressure-distribution figure).

| Parameter | Value |
|---|---|
| Wing AR | 25, 8° sweep |
| C_Dmin | 0.019 (Fig G.2) |
| C_Lmin | 0.3 |
| K = K′ + K″ | 0.0165 (e=0.77 from Fig G.9) |
| K″ | 0.01 (Fig 13.6) |

Because the wing is highly cambered, use the cambered-aircraft C_Lopt/(L/D)max forms [Eqs (3.8b)
and (3.10b)]: `C_Lopt = 0.91`, `(L/D)max ≈ 36` (agrees with Fig G.4 data).

At Mach 0.6, 55,000 ft: `q = 48 psf` → start-of-loiter `W/S = 43.7 psf`. Global Hawk actual:
W_TO = 25,600 lb, wing area 540 ft² → **(W/S)_TO = 47 psf**. Aircraft continuously climbs during
loiter, reaching altitudes above 60,000 ft (as W/S/q must be held near-constant while weight drops).

---

## §6.4 Landing and Takeoff

(Reader should be familiar with Chs 9–10 for full detail.) Wing loading affects takeoff/landing
distance through stall speed:

- **Eq (6.1)** — stall speed: `V_stall = √[(W/S)·(2/(ρ·C_Lmax))]`  *[Nicolai & Carichner, Eq. (6.1), p. 157]*
- Takeoff: distance to accelerate V=0 → V=1.2·V_stall and clear a 50-ft obstacle.
- Landing: horizontal distance to clear a 50-ft obstacle at approach speed 1.3·V_stall, touch down
  at V_TD=1.15·V_stall, and brake to a stop.
- **Eq (6.2)** — takeoff parameter (TOP): `TOP = (W/S)·(1/C_Lmax)·(1/(T/W))·(1/σ)`  *[Nicolai & Carichner, Eq. (6.2), p. 157]*
  (σ = ρ/ρ_SL; TOP plotted in Fig 6.3.)
- **Eq (6.3)** — takeoff distance estimate (ft):
  `S_TO = 20.9·(W/S)/[σ·C_Lmax·(T/W)] + 69.6·√[(W/S)/(σ·C_Lmax)]`  *[Nicolai & Carichner, Eq. (6.3), p. 158]*
  - Short takeoff achievable at high W/S if C_Lmax and T/W are both large.
- **Eq (6.4)** — landing parameter (LP): `LP = (W/S)/(σ·C_Lmax)`  *[Nicolai & Carichner, Eq. (6.4), p. 158]*
- **Eq (6.5)** — landing distance estimate for CTOL aircraft (ft):
  `S_L = 79.4·(W/S)/(σ·C_Lmax) + 50/tan(θ_app)`  *[Nicolai & Carichner, Eq. (6.5), p. 158]*
  (θ_app = approach glide-slope angle.)

### Fig 6.3 — Takeoff distance vs the takeoff parameter (TOP) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.3, p. 158]* — Takeoff Distance (1000 ft) vs TOP
`(W/S)(1/C_Lmax)(1/(T/W))(1/σ)`, 0–400; obstacle height = 50 ft, takeoff friction μ=0.03.
Nearly linear relationship *(read from plot, matches Eq 6.3)*:

| TOP | Takeoff Distance (1000 ft) |
|---|---|
| 25  | ~0.85 |
| 100 | ~3.0 |
| 200 | ~5.5 |
| 300 | ~8.0 |
| 400 | ~9.7 |

Eq (6.5) assumes glide slope over 50 ft ≈ 3° (≈950 ft) and braking deceleration = −7 ft/s².

### Fig 6.4 — Landing distance for CTOL aircraft — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.4, p. 159]* — Landing Distance (1000 ft) vs Landing W/S (0–100 psf),
obstacle=50 ft, σ=1.0, glide slope ≈3°, braking decel=−7 ft/s². Family of curves at constant
C_Lmax = 1.0, 1.5, 2.0, 2.5, 3.0, 4.0 *(read from plot)*:

| Landing W/S | Dist, C_Lmax=1.0 | C_Lmax=1.5 | C_Lmax=2.0 | C_Lmax=3.0 | C_Lmax=4.0 |
|---|---|---|---|---|---|
| 20 | ~1.7 | ~1.4 | ~1.3 | ~1.2 | ~1.1 |
| 40 | ~3.1 | ~2.3 | ~1.9 | ~1.5 | ~1.4 |
| 60 | ~4.6 | ~3.2 | ~2.5 | ~1.9 | ~1.6 |
| 80 | ~6.1 | ~4.1 | ~3.1 | ~2.2 | ~1.9 |
| 100 | ~7.5 (extrap.) | ~5.0 | ~3.7 | ~2.6 | ~2.1 |

STOL aircraft use steeper approach angles (~7°) plus thrust reversers/ground braking devices to
shorten landing distance further (see Fig 6.5).

### Fig 6.5 — Effect of landing wing loading and approach C_L on STOL landing distances — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.5, p. 160]* — dual-axis: Approach Speed (kt, 0–120) & Approximate
Landing Distance (ft, 0–4000) vs Wing Loading (0–100 psf). Approach C_L = 0.8·C_Lmax, approach
speed = 1.3·V_stall. Constant-approach-C_L lines at 4, 8, 12 plus the "1.5–1.8" conventional band,
and the "approximate boundary for conventional control." Aircraft-category regions plotted
*(read from plot — envelope centers)*:

| Category | Wing Loading (psf) | Approach Speed (kt) |
|---|---|---|
| Light planes | ~10–20 | ~40–65 |
| Current propeller | ~25–35 | ~75–82 |
| STOL | ~40–75 | ~55–70 |
| Jet flap STOL | ~55–95 | ~65–95 |
| Conventional jet | ~45–85 | ~75–120 |

Mechanical high-lift devices: C_Lmax upper limit ≈ **4.0** (Fig 9.7); powered-lift devices extend
to ≈ **12.0** (§9.6). If STOL is a dominant requirement, W/S and C_Lmax must be selected together
(and with T/W) — choosing takeoff W/S without regard to achievable C_Lmax/T/W risks an infeasible
design.

---

## §6.5 Air-to-Air Combat and Acceleration

Fighter acceleration capability at a point in space = its P_S at n=1; maneuver capability = its
P_S at n>1. Fighter design parameters should be selected to maximize P_S for critical mission phases.

- **Eq (6.6)** — specific excess power, `cos(α+i_T)≈1` (from Ch. 3): `P_S = V·[T/W − D/W]`  *[Nicolai & Carichner, Eq. (6.6), p. 161]*
  For fixed T/W, maximizing P_S ⟺ minimizing D/W. The wing loading W/S that minimizes D/W is of interest.
- **Eq (6.7)** — drag: `D = q·S_ref·[C_D0 + K·C_L²]`  *[Nicolai & Carichner, Eq. (6.7), p. 161]*
- **Eq (6.8)** — required C_L: `C_L = (W/S)·(n/q)`  *[Nicolai & Carichner, Eq. (6.8), p. 161]*
  Setting `∂(D/W)/∂(W/S) = 0` gives the wing loading for max P_S at given T/W and load factor n:

  `W/S = (q/n)·√(C_D0/K)`  *(unnumbered result, p. 161 — note (C_D0/K)^0.5 is the C_L for min drag /
  (L/D)max from Ch. 3)*

  - Footnote: valid to assume `K_B` [break drag-due-to-lift factor, Eq (2.19)] = 0, verified after
    the fact by checking C_L stays below the break C_L (C_LB).
  - For a minimum-time trajectory (Ch. 4), load factor n ≈ 1 during acceleration, so this equation
    with **n=1** gives the best wing loading for **acceleration-dominated** aircraft.

### Example 6.5 — Acceleration-Dominated Aircraft

Best wing loading for a fighter interceptor at Mach 0.8, 25,000 ft, using F-4C aerodynamics
(Fig 2.15... i.e. Fig 2.17 supersonic-drag-polar data referenced earlier as F-4C):
q = 352 psf; `C_D0 = 0.022`, `K = 0.169`, `K_B = 0` (since C_L < 0.5, check satisfied later).

Using Eq (6.8) (unnumbered form) with n=1: `W/S = (352/1)·√(0.022/0.169) = 127 psf`.

A high wing loading is desirable for acceleration: at n=1, skin friction dominates drag at all
Mach numbers, so decreasing wing area (→ decreasing wetted area) decreases zero-lift drag.
Required `C_L = 0.378 < C_LB` (Fig 2.15/2.17 break C_L), confirming `K_B=0` was valid.

### Example 6.6 — Air-to-Air-Combat Aircraft

Best wing loading for an air-to-air fighter at Mach 0.8, 25,000 ft, **n=5**, same F-4C
aerodynamics (q=352 psf, C_D0=0.022, K=0.169, K_B=0 assumed).
Using Eq (6.8) (unnumbered form) with n=5: `W/S = (352/5)·√(0.022/0.169) = 27 psf`.

**Opposite result from Example 6.5:** air-to-air combat wants **low** wing loading — for n>1,
drag-due-to-lift (∝ required C_L², which itself ∝ 1/(W/S) at fixed n,q) dominates, so decreasing
W/S decreases required C_L and thus drag. Required C_L=0.378 again < C_LB, confirming K_B=0.

Prior research: more W_TO-efficient to improve P_S at n>1 (i.e. turn rate ψ̇) by **decreasing wing
loading** rather than increasing T/W. Air combat = repeated hard turns (low W/S) + accelerations
to regain lost energy (high T/W) — so air-combat fighters want low wing loading for turning +
high T/W for acceleration. Example 6.6's result is unconstrained (ignores wing weight penalty and
poor cruise performance of low W/S) — designers typically pick somewhat higher W/S than Eq (6.8)
indicates, after weighing the full mission profile.

Air-to-air combat typically occurs transonic, 10,000–35,000 ft, where max usable C_L is
buffet-limited (typically C_Lmax < 1 transonic, vs subsonic C_Lmax).

### Fig 6.6 — Maximum C_L due to buffet — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.6, p. 163]* — C_L (0.3–1.1) vs Mach (0.6–1.2), flight-test buffet-onset
data for several sweep/leading-edge-flap configurations *(read from plot)*:

| Config | C_L at M=0.7 | C_L at M=0.9 | C_L at M=1.1 |
|---|---|---|---|
| Δ=0–26°, δ_lef=10° | ~1.02 | ~1.01 | ~1.01 |
| Transonic airfoil, Δ=0–35°, δ_lef=0° | ~0.93 | ~0.90 | ~0.92 |
| Δ=0–26°, δ_lef=5° | ~0.84 | ~0.82 | — |
| Δ=55°, δ_lef=0° | ~0.75 (min region) | ~0.65 | ~0.76 |
| Δ=45°, δ_lef=0° | ~0.63 | ~0.57 | ~0.68 |
| Δ=35°, δ_lef=0° | ~0.59 | ~0.55 | ~0.60 |
| Δ=0–26°, δ_lef=0° | ~0.77 | ~0.53 (min) | — |

(δ_lef = leading-edge flap deflection.)

- **Eq (6.9)** — combat wing loading estimate: `W/S = q·C_Lmax/n`  *[Nicolai & Carichner, Eq. (6.9), p. 163]*
  (n = load factor for the desired turn rate; desired max sustained turn rate ψ̇_MS should be ~2°/s
  better than the threat aircraft.)

---

## §6.6 High Altitude

Wing loading for a high-altitude reconnaissance aircraft (unnumbered, p. 163): `W/S = C_L·q`.
Altitude/velocity usually specified (→ q fixed); realistic max usable C_L estimate gives required
W/S. High-altitude requirement drives (W/S)_TO to low values.

### §6.6.1 HAARP Wing Loading

Continuing the HAARP example (§5.7, Fig 5.11): wing loading driven by the 5000 n mile cruise at
100,000 ft, Mach 0.6. Aerodynamics in Fig 6.7: max L/D = 27 over C_L range 0.75–0.9. Wing sized
for start-of-cruise C_L=0.9 → `S_w = S_ref = 2884 ft²`, takeoff `W/S = 5.5 psf`. With 30% fuel
fraction, end-of-mission wing loading = 3.88 psf. During the 5000 n mile cruise at 100,000 ft, C_L
reduces to 0.75 and altitude increases to 102,000 ft to hold cruise L/D = 27 (cruise-climb).

AR=25 → span = 268 ft. Since span < 150 ft is desired for worldwide airport operability, HAARP
uses 67-ft detachable outer wing panels, reducing span to 134 ft when needed.

### Fig 6.7 — HAARP aircraft aerodynamics — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 6.7, p. 164]* — L/D vs C_L (0–1.2), altitude=100,000 ft, Mach=0.6.
Two curves: "Full Wing, AR=25" and "Tips Removed, AR=10", with printed drag-polar formulas:

- AR=25: `C_D = 0.014 + 0.0127·C_L² + 0.006·(C_L−0.4)²`
- AR=10: `C_D = 0.01 + 0.0328·C_L² + 0.006·(C_L−0.4)²`

Values *(computed from the printed formulas, L/D = C_L/C_D)*:

| C_L | L/D, AR=25 (full wing) | L/D, AR=10 (tips removed) |
|---|---|---|
| 0.2 | 12.2 | 15.6 |
| 0.4 | 20.5 | 21.7 (≈max) |
| 0.6 | 25.9 | 20.0 |
| 0.75 | 27.6 (≈max, "operating C_L" band starts) | — |
| 0.9 | 27.7 (≈max, "operating C_L" band ends) | — |
| 1.2 | 24.3 | — |

Marked "Operating C_L" band spans roughly C_L = 0.75–0.9 on the full-wing (AR=25) curve, matching
the text's max-L/D=27 range.

Removing the outer wing panels gives HAARP `S_w = 1789 ft²`, AR=10, max L/D=22.3 (short-wing
aerodynamics also shown on Fig 6.7's second curve). With 4800 lb fuel, the short-wing version can
fly 5500 n mile at 45,000 ft, Mach 0.6. **CONOPS:** outer wing panels are transported separately by
a cargo aircraft; the short-wing HAARP self-ferries to the deployment site, attaches the outer
panels, then conducts the 100,000-ft atmospheric collection over the South Pole. HAARP's
three-stage turbocharger design is detailed in §14.2.1.

---

## §6.7 High Altitude, Long Endurance

Especially challenging: requires *both* low wing loading (large wing) *and* large fuel fraction.
Global Hawk: 1.5-day endurance above 55,000 ft, fuel fraction 57%. Endurance of several weeks+
requires either resupply or a self-regenerating propulsion system — solar power is the practical
option (sunlight → electricity via photovoltaic cells, 28% efficient as of 2010; discussed in
Ch. 14); since the sun only shines by day, excess daytime energy must be stored (H2-O2 fuel cells
or rechargeable batteries, Ch. 14) to power the aircraft overnight.

### Example 6.7 — High-Altitude, Long-Endurance Solar-Powered ISR ("Solar Snooper")

Requirement: 4 weeks at 65,000 ft, mid-latitude summer, ISR payload 500 lb at 1 kW. The 4-week
endurance rules out hydrocarbon propulsion; candidates are solar-with-storage or nuclear — nuclear
ruled out (unacceptable political issues flying a nuclear-powered aircraft over other countries).
Assumed cruise: 68 kt (115 fps, Mach 0.12) at 64,000 ft, TOGW = 4800 lb (validated later in Ch. 18).

| Parameter | Value |
|---|---|
| Wing aspect ratio | 36, zero sweep (similar to Boeing Condor, Fig 6.9; see Appendix G.2) |
| C_Dmin | 0.0085 (assumed) |
| C_Lmin | 1.0 (assumed) |
| Wing efficiency e | 0.60 (Fig G.9) |
| K = 1/(π·AR·e) | 0.0147 |
| K″ | 0.002 (assumed) |
| K′ = K − K″ | 0.0127 |
| Maximum L/D | 48 [Eq (3.10b) @ C_L=0.845] |
| Best loiter L/D | 42 at C_L=1.33 (Table 3.2) |
| Propeller efficiency η_p | 0.85 (assumed, based on Helios report) |
| Electric motor efficiency η_EM | 0.97 (vendor data) |

### Fig 6.8 — Solar Snooper configuration
*[Nicolai & Carichner, Fig. 6.8, p. 166]* — Three-view diagram, wing-body-tail. Key data:

| Parameter | Value |
|---|---|
| Takeoff gross weight | 4800 lb |
| Wing area | 2793 ft² |
| Wing aspect ratio | 36 |
| Horizontal tail area | 558 ft² |
| Vertical tail area | 225 ft² |
| Speed | 68 kt at 61,000 ft |
| Loiter L/D | 42 |

Labeled: solar cells on wing and tail (checkerboard pattern), 15-kW motors (two, wing-mounted),
central payload pod at c.g., 317-ft span, 95-ft length, tricycle gear.

- **Eq (6.10)** — propulsion power required:
  `Power required = [drag(lb)]·[speed(ft/s)]·(0.745/550)/(η_p·η_EM)`  *[Nicolai & Carichner, Eq. (6.10), p. 167]*
  (550 converts ft·lb/s → hp; 0.745 converts hp → kW.)

Worked: `Drag = TOGW/(L/D) = 4800/42 = 114 lb` → **Power required = 21.6 kW during loiter**
(via Eq 6.10 with speed=115 fps, η_p=0.85, η_EM=0.97).

### Fig 6.9 — Condor (courtesy of The Boeing Company)
*[Nicolai & Carichner, Fig. 6.9, p. 167]* — Photograph of the Boeing Condor (high-AR, twin-engine
high-altitude research aircraft referenced as an AR=36 zero-sweep-wing analog for Solar Snooper).
No plotted data.

**Total power budget:** Propulsion (electric motors) 22 kW + Payload 1 kW + Aircraft operation
1 kW = **Total 24 kW**.

Wing sizing: need to fly at 115 fps. `q = 1.29 psf` (very low) → `W/S = q·C_L = (1.29)(1.33) = 1.72
psf` → wing area `S_w = 2793 ft²`. Electric motors derated 25% for reliability → **two 15-kW motors**.

Remaining design challenge: install solar cells on a very lightweight 2793-ft² wing, integrate
energy storage + payload into a lightweight fuselage, and install engines — all within 4800 lb;
also verify enough solar energy is collected by day to power the aircraft overnight. Solar Snooper
continues in Chs 14 (propulsion concepts) and 18 (engine sizing).

**Sanity check — AeroVironment Helios solar-powered UAV:** flying wing (span loader), span 247 ft,
AR=31, wing area 1976 ft², weight 2048 lb → wing loading 1.04 psf. At 90,000 ft, speed 148 kt
(Mach 0.25, q=1.58 psf), flies at C_L=0.5 (no tail to trim a higher C_L). Solar cells (19%
efficient) on upper wing surface; on a bright sunny day Helios collects ≈37 kW, needs <20 kW to
fly, stores the rest. In June 2003, during a "24/7" flight demonstration using fuel-cell storage,
Helios encountered turbulence at 3000 ft on its second flight and broke up in midair over Kauai,
Hawaii. Mishap investigation: turbulence caused the aircraft to morph into an unexpected,
persistent high-dihedral shape, going unstable in a divergent pitch mode (airspeed excursions
doubling every oscillation); design speed was exceeded, and the resulting high dynamic pressure
failed the wing leading-edge secondary structure, tearing off the solar cells/skin on the upper surface.

### Fig 6.10 — Helios crash sequence
*[Nicolai & Carichner, Fig. 6.10, p. 169]* — Four sequential photographs: (1) Normal 1-g flight;
(2) Maximum dihedral occurs; (3) Leading edge breaks apart; (4) Crash site (wreckage on water).
Photographs, no plotted data.

---

## §6.8 Low-Altitude Ride Quality

Low-altitude flight is bumpy from near-ground gusts; above 250 kt the ride can become
uncomfortable enough to make passengers sick — a real problem for special operations forces (SOF)
flying low/fast to evade detection ("the thing astronauts and SOF troops have in common is that
they both get sick going to work").

Government spec **MIL-F-9490D** defines a discomfort index `D_V` and specifies allowable time
duration at different D_V levels. Ride quality is strongly related to wing loading and lift-curve
slope `C_Lα`. Design features to satisfy this requirement: **high wing loading (above 100 psf)**
and **low AR and/or wing sweep** to reduce C_Lα.

---

*Chapter 6 complete (Eqs 6.1–6.10, Tables 6.1–6.2, Figs 6.1–6.10). Next: Chapter 7 — Selecting the Planform and Airfoil Section.*