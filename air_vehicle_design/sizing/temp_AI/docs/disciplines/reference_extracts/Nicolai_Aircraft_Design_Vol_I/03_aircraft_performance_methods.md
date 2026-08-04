# Chapter 3 — Aircraft Performance Methods

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 3 "Aircraft Performance Methods," printed pp. 71–100.

Organized by book section. Notation: `q = ½ρV∞²` (dynamic pressure), `S` = reference
(wing) area, `K = 1/(π·AR·e)`, `i_T` = thrust incidence angle, `γ` = flight-path angle.

---

## §3.1 Introduction

### Fig 3.1 — Forces acting on aircraft
*[Nicolai & Carichner, Fig. 3.1, p. 72]* — Free-body diagram: lift `L` ⟂ and drag `D` ∥ to
`V∞`; thrust `T` at incidence `i_T` to the wing chord line (WCL); weight `W`; flight-path angle
`γ` to the horizontal reference line (HRL). Diagram, no plotted data.

---

## §3.2 Level Unaccelerated Flight

Force balance ⟂ and ∥ to `V∞`:
- **Eq (3.1):** `L + T·sin(α + i_T) = W·cos γ`  *[Nicolai & Carichner, Eq. (3.1), p. 72]*
- **Eq (3.2):** `T·cos(α + i_T) = W·sin γ + D`  *[Nicolai & Carichner, Eq. (3.2), p. 72]*

For `γ = 0`, small `(α + i_T)`, symmetric (C_Lmin = 0) aircraft:
- **Eq (3.3):** `W ≈ L = C_L·q·S`  *[Nicolai & Carichner, Eq. (3.3), p. 73]*
- **Eq (3.4):** `T ≈ D = (C_D0 + K·C_L²)·q·S`  *[Nicolai & Carichner, Eq. (3.4), p. 73]*
- Required lift coefficient: `C_L = W/(q·S)` *(unnumbered, p. 73)*
- **Eq (3.5)** — thrust required: `T_R = D = C_D0·q·S + K·W²/(q·S)`  *[Nicolai & Carichner, Eq. (3.5), p. 73]*
  (1st term = zero-lift drag; 2nd term = drag-due-to-lift.)
- **Eq (3.6)** — power required (propeller aircraft):
  `P_R = D·V = T_R·V = (C_D0 + K·C_L²)·(W/C_L)·√(2W/(ρ·C_L·S))`  *[Nicolai & Carichner, Eq. (3.6), p. 73]*

Notes: minimum-velocity point on the T_R curve = stall or min control speed; intersection of
thrust-available with T_R = max speed `V_max`; minimum-drag point = velocity for max loiter/
endurance (turbine) and corresponds to `(L/D)_max`.

### Fig 3.3 — Power required for typical reciprocating-engine aircraft (constant altitude) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.3, p. 75]* — Power Required (hp) vs Velocity (fps). Components:
zero-lift P_R, P_R due-to-lift, total P_R, and max power available; markers for stall/buffet
limit, V for minimum P_R, V for (L/D)_max, and max speed. Total-P_R curve *(read from plot)*:

| V (fps) | Total P_R (hp) |
|---|---|
| 100 | ~1500 (near stall) |
| 150 | ~1050 |
| 200 | ~950 (≈ minimum) |
| 250 | ~1050 |
| 300 | ~1400 |
| 400 | ~2200 |
| 450 | ~2800 |

Max power available ≈ 2400 hp (horizontal); max speed ≈ 380 fps at the intersection.

---

## §3.3 Minimum Drag and Maximum L/D

Uncambered aircraft: `C_D = C_D0 + K·C_L²`, `D = (C_D0 + K·C_L²)·q·S`.
- **Eq (3.7):** minimize drag → `∂D/∂C_L = 0` (with `q = (W/S)·(1/C_L)`)  *[Nicolai & Carichner, Eq. (3.7), p. 75]*
- Result: `C_D0 = K·C_L²` (zero-lift drag = drag-due-to-lift at min drag) *(unnumbered, p. 75)*
- **Eq (3.8a):** optimum lift coefficient: `C_Lopt = √(C_D0/K)`  *[Nicolai & Carichner, Eq. (3.8a), p. 75]*
- **Eq (3.9):** maximize L/D → `∂(C_L/C_D)/∂C_L = 0`  *[Nicolai & Carichner, Eq. (3.9), p. 76]*
- **Eq (3.10a):** `(L/D)_max = 1/(2·√(C_D0·K))`  *[Nicolai & Carichner, Eq. (3.10a), p. 76]*
  (depends only on aerodynamics.)
- **Eq (3.11):** velocity for max L/D: `V_(L/D)max = √(2W/(ρ·C_Lopt·S)) = √(2W/(ρ·S))·√(K/C_D0)`  *[Nicolai & Carichner, Eq. (3.11), p. 76]*

Cambered aircraft (`C_lmin ≠ 0`), using `C_D = C_Dmin + K′·C_L² + K″·(C_L − C_lmin)²` [Eq (2.17)]:
- **Eq (3.8b):** `C_Lopt = √[(C_Dmin + K″·C_lmin²)/(K′ + K″)]`  *[Nicolai & Carichner, Eq. (3.8b), p. 76]*
- **Eq (3.10b):** `(L/D)_max = 1 / { √[4·(C_Dmin + K″·C_lmin²)·(K′ + K″)] − 2·K″·C_lmin }`  *[Nicolai & Carichner, Eq. (3.10b), p. 76]*

### Minimum power required (propeller aircraft)
- Minimize P_R → `∂P_R/∂C_L = 0` → `3·C_D0 = K·C_L²`; so `C_Lmin,PR = √(3·C_D0/K)` *(unnumbered, p. 77)*.
- **Eq (3.12):** `V_minPR = √(2W/(ρ·S))·√(K/(3·C_D0))` — 24% less than the speed for max L/D.  *[Nicolai & Carichner, Eq. (3.12), p. 77]*

### Fig 3.2 — Thrust-required & thrust-available curves (jet aircraft) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.2, p. 74]*

(a) Subsonic, constant altitude — Thrust (lb) vs Velocity (fps) *(read from plot)*:

| V (fps) | Total T_R (lb) |
|---|---|
| 100 | ~2000 (near stall) |
| 200 | ~1200 (≈ min drag / (L/D)max) |
| 300 | ~1900 |
| 400 | ~3200 |

Military thrust ≈ 2900 lb → max speed (military) ≈ 350 fps; max A/B thrust ≈ 3800 lb → max
speed (A/B) ≈ 400 fps.

(b) Supersonic, min-time trajectory — Thrust (lb) vs Mach *(read from plot)*:

| Mach | Total T_R (lb) |
|---|---|
| 0.6 | ~9,000 (min) |
| 0.9 | ~13,000 |
| 1.0–1.1 | ~22,000 (**thrust pinch** region) |
| 1.5 | ~35,000 |
| 2.0 | ~40,000 |

Max speed ≈ M 2.1 where max A/B thrust meets total thrust required.

---

## §3.4 Variation of T_R with Weight, Configuration, and Altitude

- **Eq (3.13)** — load factor: `n = L/W` (level flight: n = 1)  *[Nicolai & Carichner, Eq. (3.13), p. 77]*

#### Fig 3.4 — Effect of aircraft weight on T_R — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.4, p. 78]* — T_R (lb) vs V (fps), W = 15,000 & 22,500 lb *(read from plot)*:

| V (fps) | T_R, W=15,000 lb | T_R, W=22,500 lb |
|---|---|---|
| 150 | ~1300 (min) | ~2200 |
| 200 | ~1400 | ~1900 (min) |
| 300 | ~2500 | ~2600 |

Min drag rises from ~1250 lb (V≈160) to ~1900 lb (V≈195) as weight increases. (Increasing W
from 15,000 to 22,500 lb is equivalent to increasing load factor from n = 1 to n = 1.5.)

#### Fig 3.5 — Effect of configuration (gear up/down) on T_R — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.5, p. 78]* — gear down raises C_D0 and thus T_R *(read from plot)*:

| V (fps) | T_R Gear Up | T_R Gear Down |
|---|---|---|
| 150 | ~1500 (min) | ~1900 |
| 200 | ~1300 | ~1700 (min) |
| 300 | ~2200 | ~2900 |

#### Fig 3.6 — Effect of altitude on T_R — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.6, p. 79]* — σ = ρ/ρ_SL; sea level (σ=1.0) vs 22,000 ft (σ=0.498)
*(read from plot)*. Minimum T_R is **unchanged** with altitude; the velocity for (L/D)max increases:

| V (fps) | T_R Sea Level | T_R 22,000 ft |
|---|---|---|
| 150 | ~1350 | ~2000 |
| 200 | ~1300 (min) | ~1450 |
| 250 | ~1600 | ~1280 (min) |
| 400 | ~3600 | ~1900 |

---

## §3.5 Endurance or Loiter

- **Eq (3.14)** — endurance definition: `E = ∫[t_i→t_f] dt = ∫[W_i→W_f] (1/(dW/dt)) dW`  *[Nicolai & Carichner, Eq. (3.14), p. 78]*
- **Eq (3.15)** — jet fuel-burn rate: `dW/dt = −T(lb)·C`, with C = thrust specific fuel consumption
  [lb fuel/(lb thrust·hour)]  *[Nicolai & Carichner, Eq. (3.15), p. 79]*
- **Eq (3.16)** — jet endurance integral (L = W, T = D at loiter):
  `E = ∫[W_f→W_i] (L/D)·(1/C)·(1/W) dW`  *[Nicolai & Carichner, Eq. (3.16), p. 79]*
- **Eq (3.17)** — jet endurance (constant L/D and C):
  `E = (L/D)·(1/C)·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.17), p. 80]*
  - Endurance parameter `(L/D)·(1/C)` = "Range Factor"; maximized near `(L/D)max` in the
    tropopause (where C is minimum).
- **Eq (3.18)** — specific impulse: `I_sp = 3600/C` (seconds)  *[Nicolai & Carichner, Eq. (3.18), p. 80]*

### Table 3.1 — Composite Lightweight Fighter Aerodynamic Data (for Fig 3.7)
*[Nicolai & Carichner, Table 3.1, p. 80]* (from the Composite LWF example, Section 5.6)

Aircraft: W_TO = 15,000 lb; S_ref = 349 ft²; W/S_TO = 43 psf; engine = one F-100-PW-100;
T/W_TO = 1.2 installed; wing AR = 3.0, Δ_LE = 40°, λ = 0.

Cruise and loiter at 36,000 ft and W/S = 40:

| Mach | C_D0 | K | C_D | C [lb fuel/(lb thrust·h)] |
|---|---|---|---|---|
| 0.5 | 0.0167 | 0.17 | 0.056 | 0.80 |
| 0.6 | 0.0167 | 0.17 | 0.035 | 0.85 |
| 0.7 | 0.0167 | 0.17 | 0.027 | 0.888 |
| 0.8 | 0.0167 | 0.17 | 0.023 | 0.92 |
| 0.9 | 0.0180 | 0.17 | 0.022 | 0.933 |
| 1.0 | 0.0243 | 0.18 | 0.027 | 1.025 |

### Fig 3.7 — Cruise & loiter performance of composite LWF (36,000 ft, W/S = 40 psf) — **DATA GRAPH (multi-scale nomograph)**
*[Nicolai & Carichner, Fig. 3.7, p. 81]* — quantities vs Mach (0.4–1.0), with separate left scales
for Drag (lb), L/D, range parameter `(V/C)(L/D)` (n mile), and endurance parameter `(1/C)(L/D)` (h).
Key features *(read from plot)*:

| Quantity | Peak / feature | at Mach ≈ |
|---|---|---|
| L/D | (L/D)max ≈ 9.3 | 0.62 |
| Endurance param (1/C)(L/D) | ≈ 11 h (best loiter) | 0.57 |
| Range param (V/C)(L/D) | maximum (best cruise) | 0.76 |
| L/D at Eq (3.29) point | ≈ read on curve | 0.85 |
| Drag | minimum | ~0.60 |

Note: best loiter speed (M ≈ 0.57) and best cruise speed (M ≈ 0.76) are both close to, but not
exactly at, the speed for (L/D)max (M ≈ 0.62).

### §3.5 (cont.) — jet & propeller endurance

- **Eq (3.19)** — jet endurance (seconds): `E = I_sp·(L/D)·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.19), p. 82]*
- Required horsepower (propeller): `hp_R = P_R/η = D·V/η` *(unnumbered, p. 82)*, η = propulsive efficiency.
- **Eq (3.20)** — propeller fuel-flow rate:
  `−dW/dt = (lb fuel)/hour = C·hp_R = C·P_R/η = D·V·C/η`, with C = brake specific fuel
  consumption (BSFC) [lb/(hp·h)]  *[Nicolai & Carichner, Eq. (3.20), p. 82]*
- **Eq (3.21)** — propeller endurance integral:
  `E = ∫[W_f→W_i] (η/C)·(C_L^{3/2}/C_D)·√(ρ·S/(2·W_i))·(dW/W^{3/2})`  *[Nicolai & Carichner, Eq. (3.21), p. 82]*
- **Eq (3.22)** — propeller endurance (hours), constant η, C, C_L, C_D:
  `E = 26.8·(η/C)·(C_L^{3/2}/C_D)·√(2·σ·S/W_i)·[ (W_i/W_f)^{0.5} − 1 ]`  *[Nicolai & Carichner, Eq. (3.22), p. 82]*
  (σ = ρ/ρ_SL; C = BSFC. Max propeller endurance occurs at minimum P_R, velocity from Eq 3.12.)

---

## §3.6 Range

- **Specific range** (distance per lb fuel): `R_S = dR/dW_fuel = V/(dW/dt)` *(unnumbered, p. 83)*.
- **Eq (3.23)** — total range: `R = ∫[W_f→W_i] V/(dW/dt) dW`  *[Nicolai & Carichner, Eq. (3.23), p. 83]*
- **Eq (3.24)** — jet range (using Eq 3.15): `R = ∫[W_f→W_i] V/(T·C) dW = ∫[W_f→W_i] (V/C)·(W/T)·(dW/W)`  *[Nicolai & Carichner, Eq. (3.24), p. 83]*
- **Eq (3.24a)** — same, with `V = a·M`: `R = ∫[W_f→W_i] (a/C)·M·(L/D)·(dW/W)`  *[Nicolai & Carichner, Eq. (3.24a), p. 85]*
- **Eq (3.25)** — cruise (T = D, L = W): `R = (V/C)·(L/D)·∫[W_f→W_i] dW/W`  *[Nicolai & Carichner, Eq. (3.25), p. 83]*
- **Eq (3.26a)** — **Breguet range equation** (jet, constant V, C_L): `R = (V/C)·(L/D)·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.26a), p. 84]*
- **Eq (3.26b):** `R = V·I_sp·(L/D)·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.26b), p. 84]*
  - Range parameter `(V/C)·(L/D)` = "range factor" — maximize (fly at altitude/velocity that maximizes it).
- **Eq (3.27)** — cruise-climb range (constant thrust & α; using `a=(γR′θ)^0.5`, `T=D=C_D(γ/2)PM²S`, `T≈T_SL(P/P_SL)(θ_SL/θ)`):
  `R ≈ √(2·R′·θ_SL/(S·P_SL))·(√T_SL/C)·(C_L/C_D^{3/2})·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.27), p. 85]*
  (θ = temp ratio, R′ = gas constant, P = static pressure, γ = 1.44 for air, SL = sea level.)
  → efficient cruise = cruise-climb at constant thrust, α for maximum `C_L/C_D^{3/2}`.
- **Eq (3.28a):** condition for max `C_L/C_D^{3/2}`: `C_D0 = 2·K·C_L²`  *[Nicolai & Carichner, Eq. (3.28a), p. 85]*
- **Eq (3.28b):** `C_L = √(C_D0/(2·K))`  *[Nicolai & Carichner, Eq. (3.28b), p. 85]*
- **Eq (3.29):** L/D at max `C_L/C_D^{3/2}`: `L/D = 0.943·(L/D)max`  *[Nicolai & Carichner, Eq. (3.29), p. 85]*

### Fig 3.8 — Range factor vs Mach for composite LWF (W/S = 40 psf) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.8, p. 84]* — Range parameter `(V/C)(L/D)` (n mile) vs Mach, for
several cruise altitudes. Velocity for max range **increases with altitude** *(read from plot)*:

| Mach | 30,000 ft | 36,000 ft | 45,000 ft | 55,000 ft |
|---|---|---|---|---|
| 0.6 | ~3600 | ~4050 | ~4300 | — |
| 0.7 | ~3700 (pk) | ~4250 (pk) | ~4550 | ~4400 |
| 0.8 | ~3500 | ~4100 | ~4550 (pk) | ~4650 |
| 0.9 | ~2900 | ~3600 | ~4200 | ~4650 (pk) |
| 1.0 | — | ~2600 | ~3700 | ~3800 |

Optimum-cruise altitude increases as wing loading decreases (range-dominated aircraft ≈ 120 psf,
optimum ≈ 36,000 ft); as fuel burns the aircraft should climb ("cruise-climb") to hold optimum C_L.

### Fig 3.9 — Cruise C_L region (C-141 & F-111A drag polars)
*[Nicolai & Carichner, Fig. 3.9, p. 87]* — Drag polars for the C-141 and F-111A; the marked
cruise-C_L region corresponds to Eq (3.28a) (`C_D0 = 2·K·C_L²`), demonstrating the rule
`L/D = 0.943·(L/D)max` for efficient cruise.

**Example 3.1 (worked):** max range at 37,000 ft for the composite LWF (Table 3.1): with
C_D = 0.0167, K = 0.17, W/S = 40 → cruise L/D = 0.943·(L/D)max = 8.87, C_L = 0.222,
`V = √((W/S)·2/(ρ·C_L)) = 714 fps` → cruise Mach ≈ 0.74.

- **Eq (3.30)** — reciprocating-engine range (n mile): `R = 326·(η/C)·(L/D)·ln(W_i/W_f)`  *[Nicolai & Carichner, Eq. (3.30), p. 88]*
  (max propeller range at V for max L/D, Eq 3.11 — tangent from origin to the P_R curve.)

### Fig 3.10 — Range parameter for Lockheed L-1011 TriStar (RR RB211-22B) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 3.10, p. 88]* — `V/(T·C)` (n mile) at 37,000 ft.
V_MD = min-drag velocity; LRC = long-range-cruise velocity.

(a) vs Mach for various gross weights — peak `V/TC` shifts to higher Mach as weight drops
*(read from plot)*:

| Gross Weight (1000 lb) | Peak V/TC (n mile) | at Mach ≈ |
|---|---|---|
| 240 | ~0.0424 | 0.62 |
| 280 | ~0.0405 | 0.68 |
| 320 | ~0.038 | 0.72 |
| 360 | ~0.033 | 0.77 |
| 380 | ~0.030 | 0.80 |

(b) vs Weight at Mach 0.825 — area under the curve (240→360k lb) = **Range = 4520 n mile**
*(read from plot)*:

| Weight (1000 lb) | V/TC (n mile) |
|---|---|
| 240 | ~0.0424 |
| 280 | ~0.0385 |
| 320 | ~0.0345 |
| 360 | ~0.0305 |

---

## §3.7 Level Constant Velocity Turn

Level turn: `W = n·W·cos φ`, load factor `n = L/W`.
- **Eq (3.31a)** — bank angle: `φ = arccos(1/n)`  *[Nicolai & Carichner, Eq. (3.31a), p. 89]*
- **Eq (3.31b)** — turn radius: `Radius = V²/(n·g·sin φ) = V²/(g·√(n²−1))`  *[Nicolai & Carichner, Eq. (3.31b), p. 89]*
- **Eq (3.31c)** — time to turn Ψ degrees: `t_ψ = Radius·(Ψ/57.3)/V`  *[Nicolai & Carichner, Eq. (3.31c), p. 89]*

### Fig 3.11 — Forces acting on an aircraft in banked flight
*[Nicolai & Carichner, Fig. 3.11, p. 89]* — Diagram: L = nW, vertical component nW·cos φ balances
W, horizontal component nW·sin φ turns the aircraft; bank angle φ; n = load factor = L/W. Diagram.

- **Eq (3.32)** — turn rate (deg/sec): `ψ̇ = g·√(n²−1)/V`  *[Nicolai & Carichner, Eq. (3.32), p. 90]*
- **Eq (3.33)** — thrust required to sustain an n-g turn at constant V:
  `T_req = q·S·[C_D0 + K·(n·W/(q·S))²] + D_trim ≤ T_max`  *[Nicolai & Carichner, Eq. (3.33), p. 90]*
  (`D_trim` = trim drag at load factor n, Ch. 22.)
- **Eq (3.34)** — maximum sustained load factor (neglecting trim drag):
  `n_MS = (q/(W/S))·√[ (1/K)·(T_max/(q·S) − C_D0) ]`  *[Nicolai & Carichner, Eq. (3.34), p. 90]*
  (substitute into Eq 3.32 for the maximum sustained turn rate ψ̇_MS.)

---

## §3.8 Energy-State Approximation (Energy Maneuverability)

Recasts the accelerating (non-steady) problem into a steady-state energy balance among
potential + kinetic energy change, energy dissipated against drag, and energy from fuel.

- **Eq (3.35)** — total energy (PE + KE): `E = W·h + (1/2)·(W/g)·V²`  *[Nicolai & Carichner, Eq. (3.35), p. 91]*
- **Eq (3.36)** — specific energy / energy height (ft): `h_e = E/W = h + (1/2)·(V²/g)`  *[Nicolai & Carichner, Eq. (3.36), p. 91]*
  (e.g. Mach 2.2 at 70,000 ft → h_e ≈ 140,000 ft.)
- **Eq (3.37)** — rate of change of specific energy: `dh_e/dt = dh/dt + (V/g)·(dV/dt)`  *[Nicolai & Carichner, Eq. (3.37), p. 91]*
- **Eq (3.38)** — accelerating force: `m·(dV/dt) = T·cos(α+i_T) − D − W·sin γ`, `m = W/g`  *[Nicolai & Carichner, Eq. (3.38), p. 91]*
- **Eq (3.39):** `(V/g)·(dV/dt) + dh/dt = V·[T·cos(α+i_T) − D]/W`  *[Nicolai & Carichner, Eq. (3.39), p. 92]*
- **Eq (3.40)** — **specific excess power** `P_S` (fps): `P_S = dh_e/dt = V·[T·cos(α+i_T) − D]/W`  *[Nicolai & Carichner, Eq. (3.40), p. 92]*
  (P_S = 0 → T = D steady flight; P_S < 0 → decelerating/descending.)
- **Eq (3.41)** — drag with load factor (C_L = nW/qS): `D = q·S·(C_D0 + K·C_L²) = C_D0·q·S + (K/q)·n²·(W²/S)`  *[Nicolai & Carichner, Eq. (3.41), p. 92]*
- **Eq (3.42)** — P_S expanded (cos(α+i_T) ≈ 1):
  `P_S = dh_e/dt = V·[ T/W − q·C_D0/(W/S) − (K/q)·n²·(W/S) ]`  *[Nicolai & Carichner, Eq. (3.42), p. 92]*
  (Example: F-104G at n=1, M=0.8 (829 fps), 20,000 ft, T_max=10,000 lb, D=2086 lb, W=18,000 lb →
  P_S = (10,000−2086)·829/18,000 = **364 fps**.)
- **Eq (3.43)** — max sustained load factor (solve Eq 3.42 with P_S = 0):
  `n_S = (q/(W/S))·√[ (1/K)·(T/(q·S) − C_D0) ]`  *[Nicolai & Carichner, Eq. (3.43), p. 94]*
- Max **instantaneous** load factor: `n_max = q·C_Lmax/(W/S)` *(unnumbered, p. 94)*.
- Turn rate (rad/sec): `ψ̇ = g·√(n²−1)/V` [Eq (3.32)].
- Level-acceleration example (F-104F, dh/dt = 0): `dV/dt = g·P_S/V = (32.2)(364)/829 = 14.1 ft/s²`.

---

## §3.9 Energy Maneuverability for Air Combat Assessment

Plot `P_S` contours for constant load factor over the flight envelope; overlay two aircraft's
`P_S` (n=5) plots to reveal regions of advantage. Turn-rate performance is the primary air-combat
measure; a desired turn-rate margin over a threat is ≈ 2 deg/sec.

#### Fig 3.12 — P_S contours for aircraft A and B at n = 5 g — **DATA GRAPH (contour)**
*[Nicolai & Carichner, Fig. 3.12, p. 93]* — Altitude (1000 ft) vs Mach (0.4–1.6). Aircraft A
(lightweight fighter, solid) vs aircraft B (advanced Soviet fighter, dashed); P_S contours
labeled −200, 0, +100, +300 fps. Shaded regions = Soviet-fighter advantage (high-subsonic,
above 25,000 ft). At n = 5 the P_S = +300 contour peaks near M ≈ 0.9.

#### Figs 3.13 & 3.14 — P_S comparison (F-5E vs F-5A)
*[Nicolai & Carichner, Figs. 3.13–3.14, pp. 95–96]* — Fig 3.13 plots P_S vs turn rate with three
reference points: (1) n = 1 energy rate (P_S at ψ̇ = 0) = accel/climb capability; (2) P_S = 0 =
max sustained turn rate; (3) max instantaneous turn rate = usable-lift/structural limit (high
energy-loss). Fig 3.14 gives the F-5E/F-5A P_S contours. The F-5E (J85-GE-21 engines, +22% thrust
over the F-5A's J85-GE-13) has a turn-rate margin throughout the M = 0.7–0.9 combat arena.

---

## §3.10 Rate of Climb and Descent

Rate of climb `dh/dt = V·sin γ`; `P_S = dh/dt + (V/g)(dV/dh)(dh/dt)`.
- **Eq (3.44)** — rate of climb (with acceleration): `dh/dt = V·sin γ = P_S / [ 1 + (V/g)·(dV/dh) ]`  *[Nicolai & Carichner, Eq. (3.44), p. 97]*
- **Eq (3.45)** — constant-speed climb (dV/dh = 0): `dh/dt = V·sin γ = V·[T·cos(α+i_T) − D]/W`  *[Nicolai & Carichner, Eq. (3.45), p. 97]*
- **Eq (3.46)** — glide flight-path angle: `γ = arcsin(−D/W)`  *[Nicolai & Carichner, Eq. (3.46), p. 97]*

#### Fig 3.15 — Force diagram on aircraft in gliding flight
*[Nicolai & Carichner, Fig. 3.15, p. 98]* — Diagram: L, D, W, V∞, glide angle γ, α, HRL (thrust = 0).

- **Eq (3.47)** — glide angle: `γ = arctan(−D/L)`  *[Nicolai & Carichner, Eq. (3.47), p. 98]*
  - Max gliding range at minimum γ → fly at `(L/D)max`; velocity from Eq (3.11).
- **Eq (3.48)** — rate of descent: `ROD = V·tan γ = −D·V/L = −(C_D/C_L)·√(2W/(ρ·C_L·S))`  *[Nicolai & Carichner, Eq. (3.48), p. 98]*
- **Eq (3.49)** — C_L for minimum ROD: `C_L = √(3·C_D0/K)`  *[Nicolai & Carichner, Eq. (3.49), p. 98]*
- **Eq (3.50)** — velocity for minimum ROD: `V_RODmin = √(2W/(ρ·S))·√(K/(3·C_D0))`  *[Nicolai & Carichner, Eq. (3.50), p. 98]*
  - 23% less than V for max gliding range; equals V for minimum P_R (Eq 3.12).

---

## §3.11 Summary for Maximum Range and Endurance

Aircraft C_L is the parameter varied (via trim/α) to achieve max range or endurance. For an
uncambered jet: constant-altitude max range → `L/D = 0.866·(L/D)max`; constant-throttle
(cruise-climb) → `L/D = 0.943·(L/D)max`.

### Table 3.2 — Values of C_L for Maximum Range and Endurance
*[Nicolai & Carichner, Table 3.2, p. 99]*

**Uncambered wing** (use `C_D = C_D0 + K·C_L²`; `(L/D)max = 1/(2·√(C_D0/K))`):

| Mission | Condition | Maximize | C_L |
|---|---|---|---|
| Range—jet | Constant altitude | C_L^{1/2}/C_D | `√(C_D0/(3K))` |
| Range—jet | Constant throttle | C_L/C_D^{3/2} | `√(C_D0/(2K))` |
| Range—propeller | Constant altitude | C_L/C_D | `√(C_D0/K)` |
| Range—sailplane | Minimum glide angle | C_L/C_D | `√(C_D0/K)` |
| Endurance—sailplane | Minimum rate of sink | C_L^{3/2}/C_D | `√(3·C_D0/K)` |
| Endurance—propeller | Minimum power required | C_L^{3/2}/C_D | `√(3·C_D0/K)` |
| Endurance—jet | Minimum thrust required | C_L/C_D | `√(C_D0/K)` |

- Max jet range, constant throttle: `L/D = √(8/9)·(L/D)max = 0.943·(L/D)max`
- Max jet range, constant altitude: `L/D = √(3/4)·(L/D)max = 0.866·(L/D)max`
- Max propeller endurance: `L/D = √(3/4)·(L/D)max = 0.866·(L/D)max`

**Cambered wing** (use `C_D = C_D0 + K′·C_L² + K″·(C_L − C_lmin)²`; with
`A = C_Dmin + K″·C_lmin²`, `B = K″·C_lmin`, `K = K′ + K″`):

| Mission | Condition | C_L |
|---|---|---|
| Range—Jet | Constant Altitude | `√(A/(3K)) − B/(3K)` |
| Range—Jet | Constant Throttle | `√(A/(2K)) − B/(2K)` |
| Range—Prop | Constant Altitude | `√(A/K)` |
| Range—Sailplane | Minimum Glide Angle | `√(A/K)` |
| Endurance—Sailplane | Minimum Rate of Sink | `√(3A/K) − B/K` |
| Endurance—Prop | Minimum Power Required | `√(3A/K) − B/K` |
| Endurance—Jet | Minimum Thrust Required | `√(A/K)` |

Note (a): fly at the prescribed C_L for max range/endurance, and use that C_L to size the wing
for the range or endurance phase of the mission.

---

*Chapter 3 complete (Eqs 3.1–3.50, Tables 3.1–3.2, Figs 3.1–3.15). Next: Chapter 4 — Aircraft Operating Envelope.*