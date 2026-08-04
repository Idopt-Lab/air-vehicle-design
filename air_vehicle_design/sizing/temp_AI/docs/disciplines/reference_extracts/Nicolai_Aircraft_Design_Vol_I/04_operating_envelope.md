# Chapter 4 — Aircraft Operating Envelope

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 4 "Aircraft Operating Envelope," printed pp. 101–121.

---

## §4.1 Flight Envelope

### Fig 4.1 — Aircraft flight envelope (altitude vs Mach)
*[Nicolai & Carichner, Fig. 4.1, p. 102]* — The altitude–Mach envelope is bounded by:
stall/buffet (left), maximum engine thrust (top and upper-right → absolute ceiling), maximum
dynamic pressure `q` (lower-right structural limit), and aerodynamic-heating/propulsion limits.
Diagram (see Figs 4.2, 4.3 for the quantitative boundaries).

---

## §4.2 Minimum Dynamic Pressure (stall/buffet — left boundary)

Left boundary set by stall (sudden flow separation, loss of lift) and buffet (turbulence
shaking the airframe; precedes stall, worse at higher speed). Lower wing loading, maneuver
flaps, and careful tail location move the boundary to lower speed.

### Fig 4.2 — Typical variation of maximum usable C_L with Mach — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.2, p. 103]* — LE sweep = 0–26°, LE flap deflection = 0°.
Max usable C_L ≈ C_Lmax at low speed, dropping to ½–⅓ in the transonic region *(read from plot)*:

| Mach | Max usable C_L |
|---|---|
| 0.0 | ~1.27 |
| 0.2 | ~1.22 |
| 0.4 | ~1.15 |
| 0.6 | ~1.05 |
| 0.7 | ~0.95 |
| 0.8 | ~0.70 |
| 0.9 | ~0.52 |
| 1.0 | ~0.45 |
| 1.1 | ~0.52 |

---

## §4.3 Maximum Thrust Limit (top / upper-right boundary)

Boundary where thrust available = thrust required. **Absolute ceiling** = max altitude reachable
(depends on weight & external stores). **Operational ceiling** = altitude where rate of climb = 100 ft/min.

---

## §4.4 Maximum Dynamic Pressure (structural — right boundary)

Structural limit (flutter, inlet static pressure). Current aircraft designed for `q_max ≈ 1800 psf`.
- **Eq (4.1)** — dynamic pressure: `q = ½·ρ∞·V∞² = (γ/2)·P∞·M∞²` (γ = 1.4 for air)  *[Nicolai & Carichner, Eq. (4.1), p. 104]*
- **Eq (4.2)** — isentropic total (stagnation) pressure: `P0∞ = P∞·[ 1 + ((γ−1)/2)·M∞² ]^(γ/(γ−1))`  *[Nicolai & Carichner, Eq. (4.2), p. 105]*
  (Inlet decelerates flow to M ≈ 0.4 at compressor face; static pressure there can be many × ambient.)

### Fig 4.3 — Trajectory limits of dynamic pressure and aerodynamic heating — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.3, p. 105]* — Altitude (1000 ft) vs Mach (0–4). Solid = constant-q
lines (1000, 1500, 3000, 5000 psf); dashed = constant equilibrium-wall-temperature lines
(θw = 250, 500, 750°F; laminar, α=0, X=1 ft, ε=0.8). Constant-q altitude increases with Mach
*(read from plot)*:

| Mach | q=1000 psf | q=1500 psf | q=3000 psf | q=5000 psf |
|---|---|---|---|---|
| 2.0 | ~38k ft | ~32k ft | ~25k ft | ~18k ft |
| 3.0 | ~54k ft | ~48k ft | ~43k ft | ~37k ft |
| 4.0 | ~64k ft | ~60k ft | ~52k ft | ~48k ft |

### Table 4.1 — Inlet Static Pressures for Different Dynamic Pressure Conditions
*[Nicolai & Carichner, Table 4.1, p. 106]* (P∞ from Appendix A; `Pc` = static pressure at the
compressor face, where M = 0.4)

| q (psf) | Altitude (ft) | Mach | P∞ (psf) | P0∞ (psf) | Pc (psf) |
|---|---|---|---|---|---|
| 1700 | 25,000 | 1.75 | 786.3 | 4,180 | 3,360 |
| 5000 | 25,000 | 3.0 | 786.3 | 28,900 | 19,300 |

An inlet designed for the q=1700 psf Pc would be blown apart by the q=5000 psf static pressure.

---

## §4.5 Aerodynamic Heating

Significant at M ≥ 2 (KE → thermal energy, convected to the aircraft). Aluminum alloys degrade
above ~250°F; critical regions are stagnation points and lower surfaces. Temperature limits for
other materials are given in Table 4.2.

### Table 4.2 — Properties of Metals at Room Temperature
*[Nicolai & Carichner, Table 4.2, p. 107]* (Ref. [3]; condition codes: SR = stress relieved,
A = annealed, DA = duplex annealed, TA = triplex annealed, STA = solution treated and aged,
CR = cold-rolled)

| Material | Condition | Ult. Tensile Str. (ksi) | Yield Tensile Str. (ksi) | Compression Modulus (10⁶ psi) | Density (lb/in³) | Temp. Limit Primary (°F) | Temp. Limit Secondary (°F) |
|---|---|---|---|---|---|---|---|
| Beryllium | SR | 78 | 57 | 42.0 | 0.066 | 1000 | 1350 |
| Ti-6Al-5Zr-4Mo-1Cu-0.2Si | STA | 200 | 177 | 16.5 | 0.164 | 800 | 800 |
| Ti-6Al-6V-2Sn | STA | 170 | 160 | 16.5 | 0.164 | 800 | 800 |
| Ti-8Mo-8V-2Fe-3Al | STA | 180 | 165 | 16.6 | 0.175 | 600 | 600 |
| Ti-6Al-2Sn-4Zr-6Mo | TA | 170 | 160 | 16.5 | 0.169 | 1000 | 1000 |
| Ti-6Al-4V | STA | 157 | 143 | 16.4 | 0.160 | 800 | 900 |
| Ti-6Al-6V-2Sn | A | 155 | 145 | 15.0 | 0.164 | 800 | 800 |
| PH 14-8Mo | STA | 240 | 225 | 28.0 | 0.278 | 1000 | 1000 |
| Ti-8Al-1Mo | STA | 133 | 121 | 18.0 | 0.156 | 1000 | 1100 |
| Ti-6Al-4V | A | 134 | 126 | 16.4 | 0.160 | 1000 | 1000 |
| Inco's "1000°F Alloy" | STA | 228 | 19.1 | 29.0 | 0.267 | 1000 | 1000 |
| Ti-5Al-2.5Sn | A | 120 | 113 | 15.5 | 0.161 | 900 | 1100 |
| Inconel 718 | STA | 210 | 185 | 29.0 | 0.297 | 1300 | 1800 |
| Rene' 41 | STA | 184 | 145 | 31.9 | 0.298 | 1550 | 1800 |
| 2219-T81 (Aluminum) | STA | 60 | 45 | 10.8 | 0.102 | 400 | 500 |
| L-605 (Cobalt) | CR | 185 | 145 | 32.6 | 0.330 | 1800 | 2000 |
| TD NiC | SR | 138 | 94 | 21.9 | 0.306 | 2200 | 2400 |
| Haynes Alloy No. 188 | A | 130 | 67 | 34.5 | 0.333 | 2000 | 2000 |
| Hastelloy X | A | 114 | 55 | 28.6 | 0.297 | 2000 | 2100 |
| TZM (Molybdenum) | SR | 140 | 117 | 40.0 | 0.369 | 3200 | 3400 |
| B66 (Columbium) | A | 106 | 81 | 14.6 | 0.305 | 2600 | 2800 |
| TDNi | SR | 85 | 68 | 22.0 | 0.322 | 2000 | 2200 |
| Cb-752 (Columbium) | A | 81 | 70 | 17.0 | 0.326 | 2400 | 2800 |
| T-222 | A | 120 | 110 | 29.0 | 0.605 | 3000 | 3400 |

### §4.5.1 Stagnation-point heating (nose / swept wing LE)
- **Eq (4.3)** — convective heating rate (Btu/ft²·s):
  `q̇_conv = 15·(ρ∞/R0)^0.5·(V∞/1000)³·(cos Δ)^1.5`  *[Nicolai & Carichner, Eq. (4.3), p. 106]*
  - ρ∞ = density (slug/ft³), V∞ = velocity (ft/s), R0 = nose/LE radius (ft), Δ = LE sweep (0 for body nose).
- Heat balance: `q̇_conv = q̇_radiated`, giving
- **Eq (4.4a)** — equilibrium wall temperature (°R): `θw = [ q̇_conv/(ε·v_SB) ]^(1/4)`  *[Nicolai & Carichner, Eq. (4.4a), p. 106]*
  - ε = emissivity (~0.8); v_SB = Stefan–Boltzmann constant = 0.481×10⁻¹² Btu/(ft²·s·°R⁴).

### §4.5.2 Lower-surface heating
- **Eq (4.5)** — local surface heat transfer: `q̇_surf = 3.21×10⁻⁴·C_f·ρ·V∞³`  *[Nicolai & Carichner, Eq. (4.5), p. 108]*
  - C_f = local laminar skin-friction coefficient at x ft from the LE (normally x = 1.0 ft).
- **Eq (4.4b):** `θw = [ q̇_surf/(ε·v_SB) ]^(1/4)`  *[Nicolai & Carichner, Eq. (4.4b), p. 108]*

Fig 4.3 (§4.4 above) also shows lines of constant lower-surface equilibrium temperature (ε=0.8, x=1 ft).

---

## §4.6 Sonic Boom

Supersonic flight creates ground pressure waves ("overpressure") from the shock system;
significant discomfort/damage risk when altitude is low and/or M > 2.5. A minimum supersonic
operating altitude is fixed to bound ground overpressure. (Concorde and Tu-144 SSTs were never
able to negotiate overland supersonic operating rights with overflown countries.)

---

## §4.7 Noise and Pollution Limits

FAR-36 (established by the FAA in 1969) limits engine/aircraft noise — effective perceived
noise level (EPNdB) — at three reference locations.

### Fig 4.4 — Noise measuring locations for FAR Part 36
*[Nicolai & Carichner, Fig. 4.4, p. 109]* — Approach measuring point: 1 n mile before threshold
(370 ft altitude on a 3° glide slope). Takeoff measuring point: 3.5 n mile from brake release.
Sideline measuring point: 0.25 n mile from centerline (four-engine) / 0.35 n mile (per text,
though figure/labels show 0.25 n mile plotted) where post-liftoff noise is greatest. Diagram.

### §4.7.1 Regulations (FAR Part 36 Stage 3)
- **Takeoff noise:** measured 21,325 ft (6500 m) from start of takeoff roll, under the aircraft.
- **Sideline noise:** measured 1476 ft (450 m) from runway centerline, at point of greatest post-liftoff noise.
- **Approach noise:** measured under the aircraft at 6562 ft (2000 m) from runway threshold.
- All three limits are functions of max takeoff gross weight; takeoff limit also depends on engine count.
- **Stage 4** (new designs after 1 Jan 2006, "Chapter 4" in ICAO Annex 16, relative to Stage 3/Chapter 3):
  cumulative margin of 10 dB; minimum sum of 2 dB at any two conditions; no trades allowed.

### Fig 4.5a — Maximum noise limits, Approach — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.5a, p. 109]* — EPNL (dB) vs Takeoff Weight (1000 lb, log scale).
Stage 3 floor = 98 dB (≤ ~63,000 lb), rising linearly (log W) to 105 dB at ~617,000 lb+ *(read from plot)*:

| Takeoff Weight (1000 lb) | EPNL (dB) |
|---|---|
| 1–63 | 98 (floor) |
| 100 | ~100 |
| 300 | ~103 |
| 617+ | 105 |

### Fig 4.5b — Maximum noise limits, Sideline — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.5b, p. 110]* — Stage 3 floor = 94 dB (≤ ~63,000 lb), rising to 103 dB
at 1,000,000 lb *(read from plot)*:

| Takeoff Weight (1000 lb) | EPNL (dB) |
|---|---|
| 1–63 | 94 (floor) |
| 100 | ~96 |
| 300 | ~99 |
| 1000 | 103 |

### Fig 4.5c — Maximum noise limits, Takeoff — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.5c, p. 110]* — Stage 3 floor = 89 dB, rising to 101–106 dB depending
on engine count; cutback thrust = one-engine-out level flight or 4% climb gradient, whichever
greater. Cutback altitude decreases with engine count *(read from plot)*:

| Engines | Floor weight (1000 lb) | Cutback Altitude (ft) | EPNL at 1000 (1000 lb) |
|---|---|---|---|
| 2 | ~100 | 984 | 101 |
| 3 | ~75 | 853 | 104 |
| 4 | ~50 | 689 | 106 |

### §4.7.2 Estimating Aircraft Noise for Advanced Design
- Reference point: a 25,000-lb SLS-thrust turbofan (bypass ratio 6, ~5 EPNdB suppression)
  produces ≈ **101 EPNdB at 1000 ft**.
- Internal noise ("turbomachinery" noise) from high-speed rotating blades; external noise from
  shear/eddy mixing of high-velocity jet with ambient air. Fan noise is suppressible with nacelle
  acoustic treatment; jet noise is not — driving toward **larger bypass ratio** turbofans.
  Optimum bypass ratio (noise vs efficiency vs nacelle drag tradeoff) ≈ **5.5**.
- Takeoff/sideline noise set by the engine; approach noise set by the airframe (flaps, gear,
  wheel wells generate more noise than the low-power engines during landing).
- Pollution: no aircraft regulations exist yet (as of writing) but airport-area NOx/CO/HC limits
  are anticipated; SST fleets operating in the stratosphere could deplete ozone via NOx.

---

## §4.8 Propulsion Limits

Nine propulsion device choices (seven shown in Fig 4.6; scramjet and pulse-detonation engine
(PDE) not shown). Each has a preferred operating regime; measures of merit are **thrust/engine
weight (T/W)** and **thrust specific fuel consumption (TSFC)**.

### Fig 4.6 — Level-flight propulsion options — **DATA GRAPH (regime map)**
*[Nicolai & Carichner, Fig. 4.6, p. 113]* — Altitude (1000 ft) vs True Airspeed (kt, 0–2800), with
Mach lines 1.0–4.0 overlaid. Each propulsion type's usable envelope *(read from plot)*:

| Propulsion type | Speed range (kt) | Altitude range (1000 ft) |
|---|---|---|
| Piston-Prop | 0–300 | 0–25 (peak ~25 at 150 kt) |
| Turboprop | 0–550 | 0–73 (peak ~73 at 300 kt) |
| Turbofan | 400–1300 | 0–87 (peak ~87 at M≈1.9) |
| Turbojet | 700–1700 | 0–97 |
| Turbojet + Afterburning | 1000–2000 | 0–100 |
| TurboRamjet | 1400–2300 | 0–100 |
| Ramjet | 1700–2800 | 20–103 |
| Rocket | (essentially unbounded — arrow off-chart) | — |

Reciprocating-prop best at M ≤ 0.5; turboprop best at higher subsonic (limited by propeller-tip
M < 1.0); turbofan best at high subsonic; turbojet takes over at low supersonic (fan drag);
turbojet+A/B needed around M ≈ 2; ramjet very efficient above M ≈ 3; a coupled "turbo-ramjet"
(turbojet inlet closed above M≈3, ramjet inlet closed below M≈2, both operate M 2–3) could get
the best of both.

### Fig 4.7 — Comparison of design characteristics of propulsion engines vs Mach — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.7, p. 114]* — three panels, each point = an engine design point
structurally critical at that Mach for pressure loads.

(a) Net Thrust/Weight (lb/lb) vs Mach *(read from plot)*:

| Mach | Reciprocating | Turbojet | Turbojet+A/B | Ramjet | Rocket |
|---|---|---|---|---|---|
| 0.5 | ~0.7 | ~2.5 | ~3 | ~0 | 40 (const) |
| 1.0 | — | ~3 | ~9.5 | ~10 | 40 |
| 2.0 | — | ~3 (to M~1.8) | ~7 (dip) | ~24 | 40 |
| 3.0 | — | — | ~10 | ~30 (peak) | 40 |
| 4.0 | — | — | — | ~27 | 40 |

(b) Net Power/Weight (hp/lb, log) vs Mach — reciprocating flat ~0.7; turbojet rises ~1.5→8;
turbojet+A/B ~2→90; ramjet ~50→130; rocket (dashed, off top) ~50→200+.

(c) Net TSFC (lb/h·lb) vs Mach — reciprocating & turbojet stay low (~0.5–2); ramjet starts high
(~14 at M=0.5) and **decreases** to ~3 by M=4; turbojet+A/B starts ~2 and **increases** to ~5.3 by
M=3.4; rocket ≈ 16 (constant, dashed at top).

- Rocket TSFC ≈ **16** (typical solid-fuel motor); liquid-fuel (LH2/LOX, e.g. Space Shuttle boost)
  TSFC ≈ **9** (see §18.12).

---

## §4.9 Optimal Trajectories

Optimal trajectory (min time or min fuel) found via calculus of variations or gradient methods
(complex, computer-intensive) — the energy-state approximation (§3.8) gives rapid results that
agree well with exact methods.

- Specific power (from Eq 3.40): `P_S = dh_e/dt = V·(T·cos α − D)/W`  *[= Eq (3.40), p. 115]*
- Specific energy (from Eq 3.36): `h_e = h + V²/(2g)`  *[= Eq (3.36), p. 115]*
- **Eq (4.6)** — energy change per unit fuel weight (ft/lb):
  `f_S = dh_e/dW_f = (dh_e/dt)/(T·C)`  *[Nicolai & Carichner, Eq. (4.6), p. 115]*
  (T = thrust, C = specific fuel consumption.)
- **Eq (4.7)** — time to move between energy states along trajectory A:
  `Δt = ∫[he1→he2] (1/P_S) dh_e`  *[Nicolai & Carichner, Eq. (4.7), p. 115]*
- **Eq (4.8)** — fuel burned along trajectory A:
  `ΔW_f = ∫[he1→he2] (1/f_S) dh_e`  *[Nicolai & Carichner, Eq. (4.8), p. 115]*
  - During climb-accel n varies, but per Ref [14] the average n ≈ 1 g is adequate for Eqs (4.7)–(4.8).
  - **Minimum-time trajectory** (max energy change per unit time): at each h_e, follow the point of
    tangency between the constant-h_e line and the highest-P_S contour (max power/afterburner).
  - **Minimum-fuel trajectory**: tangency between constant-h_e lines and constant-f_S contours,
    typically at a lower (non-max) power setting than min-time.

### Fig 4.8a — Excess specific power P_S = dh_e/dt for the F-104G (n=1, max power) — **DATA GRAPH + trajectory**
*[Nicolai & Carichner, Fig. 4.8a, p. 116]* — Aircraft: W_TO = 26,000 lb, (W/S)_TO = 133 psf, one
J79-GE-11A at T_SLS = 15,800 lb, (T/W)_TO = 0.61, max Mach = 2.2. Altitude (1000 ft) vs Mach
(0.5–2.5); P_S contours (2,3,4,5,6,100,200,...,600 fps) and constant-h_e lines (he=7×10⁴ ft
labeled; unlabeled family 8–12 ×10⁴ ft) overlaid, plus the `dh_e/dt = 0` line and aircraft
operational limits box. **Thrust pinch** near Mach 1.0 makes the P_S contours closed loops /
discontinuous. The minimum-time trajectory (dashed) climbs from Mach≈0.6/SL, peaks near
32,000 ft/M≈0.95, dives through the thrust pinch to ~19,000 ft/M≈1.25, then climbs again through
~38,000 ft/M≈1.6 to ~51,000 ft/M≈2.15 (following P_S contour tangent points).

### Fig 4.9 — LWF energy-maneuverability contours — **DATA GRAPH + trajectory**
*[Nicolai & Carichner, Fig. 4.9, p. 118]* — Composite lightweight fighter (LWF; became the F-16):
W_TO = 15,000 lb, (W/S)_TO = 43 psf, F-100 engine, T_SLS = 18,000 lb installed, max Mach = 2.2,
combat weight = 13,300 lb.

(a) P_S = dh_e/dt at n=1, max power (afterburner), W/S = 38.1 psf. Altitude (1000 ft) vs Mach
(0.4–1.8); P_S contours 500→1300 fps (no thrust pinch — smooth nested contours, unlike F-104G);
`q = 1800 psf` structural limit line; **minimum-time trajectory to Mach 1.6** (dashed) climbs
smoothly from SL/M≈0.5 to ~31,000 ft/M≈1.6 without the F-104G's dip.

(b) Contours of constant f_S = dh_e/dW_f at n=1, **military power** (non-A/B), W/S = 48.1 psf.
Altitude (1000 ft) vs Mach (0–1.4); f_S contours 90→172 (ft/lb, ×10³ implied); **minimum-fuel
trajectory** (dashed) climbs from SL/M≈0.2 to a cruise point at ~46,000 ft/M≈0.9.

### Table 4.3 — Altitudes for Constant Energy Contours (1976 U.S. Standard Atmosphere)
*[Nicolai & Carichner, Table 4.3, p. 119]* — Altitude (ft) as a function of Mach number for
constant specific energy h_e = 10,000 to 120,000 ft (used to plot the constant-h_e lines in
Figs 4.8–4.9). Selected rows:

| Mach | he=10,000 | 20,000 | 30,000 | 40,000 | 50,000 | 60,000 | 70,000 | 80,000 | 90,000 | 100,000 | 110,000 | 120,000 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0.0 | 10,000 | 20,000 | 30,000 | 40,000 | 50,000 | 60,000 | 70,000 | 80,000 | 90,000 | 100,000 | 110,000 | 120,000 |
| 0.5 | 5,335 | 15,679 | 26,024 | 36,359 | 46,359 | 56,359 | 66,355 | 76,304 | 86,253 | 96,202 | 106,141 | 115,999 |
| 1.0 | — | 726 | 12,263 | 23,799 | 35,336 | 45,436 | 55,436 | 65,436 | 75,239 | 85,038 | 94,837 | 104,636 |
| 1.5 | — | — | — | 9,162 | 23,440 | 37,231 | 47,231 | 57,231 | 67,160 | 76,719 | 86,278 | — |
| 2.0 | — | — | — | — | — | — | — | 5,388 | 26,789 | 41,744 | 51,744 | 61,744 |
| 2.4 | — | — | — | — | — | — | — | — | — | — | — | 36,111 |

(Full table in the source has every 0.1 Mach increment from 0 to 2.4 — the above is a representative
subsample; consult the PDF directly for intermediate rows if exact values are needed.)

### Fig 4.10 — Plot of 1/f_S vs h_e for composite LWF along minimum-fuel trajectory (M 0.2→0.9) — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.10, p. 120]* — One F-100 engine, military power (non-A/B), n = 1.0.
`1/f_S` (10⁻³ lb/ft) vs h_e (1000 ft, 0–60). Starts at Mach 0.2/sea level (~15.7×10⁻³ lb/ft), drops
sharply, flattens ~5.8×10⁻³ lb/ft through mid-range, rises again to Mach 0.9/44,000 ft (~7.3×10⁻³
lb/ft). **Area under curve = 368 lb** = fuel burned over the trajectory, per Eq (4.8).

### Fig 4.11 — F-16 with fuel tanks, sensors, and missiles
*[Nicolai & Carichner, Fig. 4.11, p. 121]* — Photograph; the LWF program (Fig 4.9 data) became
the production F-16. No plotted data.

- **Eq (4.9)** — discretized fuel-burned summation (small intervals, Δh_e ≤ 1000 ft, compares well
  with computer results):
  `ΔW_f ≈ Σ[j=1→h] [ (1/(dh_e/dW_f))·(h_ei − h_ef) ]_j`  *[Nicolai & Carichner, Eq. (4.9), p. 121]*
  - Method invalid along constant-h_e contours (Eqs 4.7–4.8 would give zero time/fuel).

---

*Chapter 4 complete (Eqs 4.1–4.9, Tables 4.1–4.3, Figs 4.1–4.11). Next: Chapter 5 — Preliminary Estimate of Takeoff Weight.*