# Mattingly "Aircraft Engine Design" 2nd Ed. — Extracted Equations
## Mattingly, Heiser, Pratt — AIAA Education Series, 2002
## Extracted: TSFC, Thrust Lapse, theta_0, delta_0, TR, and Related Equations

---

## PART 1: DIMENSIONLESS ATMOSPHERIC PARAMETERS (Section 2.3.2, Eq. 2.52)

### Temperature and Pressure Ratios

**Static ratios** (Eq. 2.52a, 2.52b):
```
theta  = T / T_std
delta  = P / P_std
```

**Total (stagnation) ratios** — primary variables used in engine models:
```
theta_0 = T_t / T_std = theta * (1 + (gamma-1)/2 * M0^2)   [Eq. 2.52a]
delta_0 = P_t / P_std = delta * (1 + (gamma-1)/2 * M0^2)^(gamma/(gamma-1))   [Eq. 2.52b]
```

For gamma = 1.4:
```
theta_0 = theta * (1 + 0.2 * M0^2)
delta_0 = delta * (1 + 0.2 * M0^2)^3.5
```

**Standard sea-level values:**
```
T_std = 518.67 R (US), 288.15 K (SI)
P_std = 2116.22 lbf/ft^2 (US), 101325 Pa (SI)
```

---

## PART 2: INSTALLED THRUST LAPSE EQUATIONS (Section 2.3.2)

### Definition of thrust lapse alpha (Eq. 2.3):
```
T = alpha * T_SL
```
Where:
- T      = installed thrust at altitude/Mach condition
- T_SL   = installed sea-level static thrust (reference)
- alpha  = installed full-throttle thrust lapse (function of altitude, Mach, and AB status)
- alpha refers ONLY to maximum thrust (full throttle, mil or max power)

### Note on installed vs uninstalled thrust:
- T and T_SL are INSTALLED thrust (includes inlet and nozzle installation losses)
- Installed thrust < uninstalled thrust (F)
- Installation dealt with in detail in Chapter 6 and Appendix E

---

### 2A. HIGH BYPASS RATIO TURBOFAN (M0 < 0.9) — Eq. (2.53)

**Maximum power only (subsonic only):**
```
theta_0 <= TR:   alpha = delta_0 * {1 - 0.49 * sqrt(M0)}
theta_0 >  TR:   alpha = delta_0 * {1 - 0.49*sqrt(M0) - 3*(theta_0 - TR)/(1.5 + M0)}
```

---

### 2B. LOW BYPASS RATIO MIXED FLOW TURBOFAN — Eq. (2.54)

**Maximum power (afterburner ON):**
```
theta_0 <= TR:   alpha = delta_0
theta_0 >  TR:   alpha = delta_0 * {1 - 3.5*(theta_0 - TR)/theta_0}
```
[Eq. 2.54a]

**Military power (afterburner OFF):**
```
theta_0 <= TR:   alpha = 0.6 * delta_0
theta_0 >  TR:   alpha = 0.6 * delta_0 * {1 - 3.8*(theta_0 - TR)/theta_0}
```
[Eq. 2.54b]

**Note:** For mil power, alpha = 0.6 * (max power alpha) at theta_0 <= TR.
The ratio alpha_mil/alpha_max = 0.6 at sea level (below TR), meaning mil power thrust is 60% of max.

---

### 2C. TURBOJET — Eq. (2.55)

**Maximum power (afterburner ON):**
```
theta_0 <= TR:   alpha = delta_0 * {1 - 0.3*(theta_0-1) - 0.1*sqrt(M0)}
theta_0 >  TR:   alpha = delta_0 * {1 - 0.3*(theta_0-1) - 0.1*sqrt(M0) - 1.5*(theta_0-TR)/theta_0}
```
[Eq. 2.55a]

**Military power (afterburner OFF):**
```
theta_0 <= TR:   alpha = 0.8 * delta_0 * {1 - 0.16*sqrt(M0)}
theta_0 >  TR:   alpha = 0.8 * delta_0 * {1 - 0.16*sqrt(M0) - 24*(theta_0-TR)/((9+M0)*theta_0)}
```
[Eq. 2.55b]

---

### 2D. TURBOPROP — Eq. (2.56)

```
M0 <= 0.1:       alpha = delta_0
theta_0 <= TR:   alpha = delta_0 * {1 - 0.96*(M0-0.1)^(1/4)}
theta_0 >  TR:   alpha = delta_0 * {1 - 0.96*(M0-0.1)^(1/4) - 3*(theta_0-TR)/(8.13*(M0-0.1))}
```
[Eq. 2.56]

---

## PART 3: TSFC MODELS (Section 3.3.2, Eq. 3.12, 3.54-3.57)

### General TSFC Form (Eq. 3.12):
```
TSFC = (C1 + C2*M) * sqrt(theta)
```
Units: TSFC in 1/hour (h^-1)

Where:
- C1, C2 = engine-type specific constants (see below)
- M       = flight Mach number
- theta   = T/T_std = static temperature ratio (NOT total)
- sqrt(theta) accounts for altitude effect on TSFC

**This is the installed TSFC**, i.e., it includes installation effects.
Used in ALL mission analysis (Breguet-type range, loiter, etc.)

---

### Specific TSFC Values by Engine Type (Section 3.3.2)

These are for **advanced engines expected in 2010 era and beyond**.

#### 3A. HIGH BYPASS RATIO TURBOFAN (M0 < 0.9) — Eq. (3.54):
```
TSFC = (0.45 + 0.54 * M0) * sqrt(theta)
```
C1 = 0.45, C2 = 0.54

#### 3B. LOW BYPASS RATIO MIXED FLOW TURBOFAN:

**Military power (no afterburner)** — Eq. (3.55a):
```
TSFC = (0.9 + 0.30 * M0) * sqrt(theta)
```
C1 = 0.9, C2 = 0.30

**Maximum power (with afterburner)** — Eq. (3.55b):
```
TSFC = (1.6 + 0.27 * M0) * sqrt(theta)
```
C1 = 1.6, C2 = 0.27

#### 3C. TURBOJET:

**Military power (no afterburner)** — Eq. (3.56a):
```
TSFC = (1.1 + 0.30 * M0) * sqrt(theta)
```
C1 = 1.1, C2 = 0.30

**Maximum power (with afterburner)** — Eq. (3.56b):
```
TSFC = (1.5 + 0.23 * M0) * sqrt(theta)
```
C1 = 1.5, C2 = 0.23

#### 3D. TURBOPROP — Eq. (3.57):
```
TSFC = (0.18 + 0.8 * M0) * sqrt(theta)
```
C1 = 0.18, C2 = 0.80

---

## PART 4: THROTTLE RATIO TR (Appendix D — to be filled from reading)

### Definition:
TR = Throttle Ratio = theta_0_break / theta_0_SLS

Where theta_0_break is the value of theta_0 at which the engine control system
simultaneously reaches maximum T_t4 (turbine inlet temperature) AND maximum
pi_c (compressor pressure ratio).

**Physical significance:**
- Below theta_0_break (theta_0 <= TR): engine is at full power, thrust lapse is "cold day" behavior
- Above theta_0_break (theta_0 > TR): engine control limits one of T_t4 or pi_c, causing additional thrust lapse

**Relation to standard day SLS conditions:**
At sea level, M0 = 0, standard day:
```
theta_0 = theta = 1.0 (standard day, SLS)
```
So at SLS standard day, theta_0 = 1.0.

If TR = 1.0, the engine hits its break EXACTLY at SLS standard day.
If TR > 1.0, the break occurs above SLS standard day (allows more thrust on hot days).

**For the AAF example (fighter):** TR = 1.07 was selected.

**Typical TR values:**
- TR = 1.0: engine optimized for standard day (no margin)
- TR = 1.05-1.08: typical for military fighters (allows hot-day takeoff at full power)
- TR correlates with hot-day takeoff conditions and supercruise theta_0 requirements

**theta_0_break vs theta_0 at condition:**
The engine is described as:
- "Below break" when theta_0 <= TR  → full performance available
- "Above break" when theta_0 > TR   → performance degrades (additional lapse terms apply)

---

## PART 5: FUEL CONSUMPTION INTEGRATION (Mission Analysis)

### Basic fuel flow equation (Eq. 3.2):
```
dW/dt = -dW_F/dt = -TSFC * T
```

### Rewritten (Eq. 3.3):
```
dW/W = -TSFC * (T/W) * dt
```

### Type B legs (Ps = 0, T = D+R, constant altitude/speed): (Eq. 3.10):
```
dW/W = -TSFC * ((D+R)/W) * dt
```

Integrated (Eq. 3.11):
```
W_f/W_i = exp{-TSFC * ((D+R)/W) * Delta_t}
```

### General weight fraction with TSFC model (Eq. 3.15, 3.16):
For type B (Ps=0):
```
dW/W = -(C1+C2*M)*sqrt(theta) * ((D+R)/W) * dt        [Eq. 3.15]

W_f/W_i = exp{-(C1+C2*M)*sqrt(theta) * ((D+R)/W) * Delta_t}   [Eq. 3.16]
```

For type A (Ps > 0, T = alpha*T_SL):
```
dW/W = -(C1/M + C2)/(a_std*(1-u)) * d(h + V^2/(2*g0))   [Eq. 3.13]

W_f/W_i = exp{-(C1/M+C2)/(a_std*(1-u)) * Delta(h + V^2/(2g0))}   [Eq. 3.14]
```
where u = (D+R)/T = (D+R)/(T)

### Range factor RF (Eq. 3.31):
```
RF = (L/(D+R)) * V/TSFC = (C_L/(C_D+C_DR)) * a_std/(C1/M+C2)
```

### Endurance factor EF (Eq. 3.36):
```
EF = (L/(D+R)) * 1/TSFC = C_L/(C_D+C_DR) * 1/((C1+C2*M)*sqrt(theta))
```

---

## PART 6: WEIGHT FRACTION EQUATIONS BY MISSION TYPE

### Case 1: Constant Speed Climb (Ps = dh/dt) — Eq. (3.17):
```
W_f/W_i = exp{-(C1/M+C2)/a_std * [Delta_h / (1 - [(C_D+C_DR)/C_L]*[beta/alpha]*(W_TO/T_SL))]}
```

### Case 5: Constant Altitude/Speed Cruise (Ps = 0) — Eq. (3.23):
```
W_f/W_i = exp{-(C1/M+C2) * (C_D+C_DR)/C_L * Delta_s / a_std}
```
This is the generalized Breguet range equation.

### Case 7: Best Subsonic Cruise (BCM/BCA) — Eq. (3.29):
```
W_f/W_i = exp{-(C1/M_CRIT+C2) * (sqrt(4*C_D0*K1) + K2) * Delta_s/a_std}
```

### Case 8: Subsonic Loiter — Eq. (3.37):
```
W_f/W_i = exp{-Delta_t/EF}
```
where EF = endurance factor from Eq. (3.36)

### Case 9: Warm-up — Eq. (3.42):
```
W_f/W_i = 1 - C1*sqrt(theta) * (alpha/beta) * (T_SL/W_TO) * Delta_t
```

### Case 10: Takeoff Rotation — Eq. (3.44):
```
W_f/W_i = 1 - (C1+C2*M_TO)*sqrt(theta) * (alpha/beta) * (T_SL/W_TO) * t_R
```

### Case 6: Constant Altitude/Speed Turn — Eq. (3.25):
```
W_f/W_i = exp{-(C1+C2*M)*sqrt(theta) * (C_D+C_DR)/(C_L/n) * (2*pi*N*V)/(g0*sqrt(n^2-1))}
```

### Case 3: Climb and Acceleration (Ps = dh/dt + VdV/g0 dt) — Eq. (3.20):
```
W_f/W_i = exp{-(C1/M+C2)/a_std * [Delta(h+V^2/(2g0)) / (1 - [(C_D+C_DR)/C_L]*(beta/alpha)*(W_TO/T_SL))]}
```

---

## PART 7: MASTER EQUATIONS FOR CONSTRAINT ANALYSIS

### Basic Thrust-Weight-Loading master equation (Eq. 2.11):
```
T_SL/W_TO = (beta/alpha) * {q*S/(beta*W_TO) * [K1*(n*beta*W_TO/(q*S))^2 + K2*(n*beta*W_TO/(q*S)) + C_D0 + C_DR] + P_s/V}
```

Where:
- alpha = thrust lapse (from Eqs. 2.53-2.56)
- beta = W/W_TO = instantaneous weight fraction
- q = (1/2)*rho*V^2 = dynamic pressure
- K1, K2, C_D0 = lift-drag polar coefficients [Eq. 2.9]: C_D = K1*C_L^2 + K2*C_L + C_D0
- n = load factor
- P_s = specific excess power (0 for sustained flight)
- C_DR = additional drag coefficient (external stores, etc.)

### Constraint Analysis instantaneous weight fraction definition (Eq. 2.4):
```
W = beta * W_TO
```

---

## PART 8: EMPTY WEIGHT FRACTIONS (Section 3.3.1)

Gamma = W_E/W_TO = f(W_TO):

```
Cargo aircraft:         Gamma = 1.26  * W_TO^(-0.08)   [Eq. 3.50]
Passenger aircraft:     Gamma = 1.02  * W_TO^(-0.06)   [Eq. 3.51]
Fighter aircraft:       Gamma = 2.34  * W_TO^(-0.13)   [Eq. 3.52]
Twin turboprop aircraft: Gamma = 0.96 * W_TO^(-0.05)   [Eq. 3.53]
```
(W_TO in lbf, Gamma dimensionless)

---

## PART 9: AERODYNAMIC DATA (Preliminary Estimates, Chapter 2)

### Lift-drag polar (Eq. 2.9):
```
C_D = K1 * C_L^2 + K2 * C_L + C_D0
```
Where:
- K1 = K' + K'' (induced + viscous drag due to lift)
- K2 = -2*K''*C_L_min
- C_D0 = C_D_min + K''*C_L_min^2

For high-performance fighter (uncambered, K2 = 0, K2 ≈ 0):
```
C_D = K1 * C_L^2 + C_D0
```

### Typical values for fighter aircraft (from Figs. 2.10, 2.11 — current technology):

**Subsonic (M < ~0.9):**
- C_D0 ≈ 0.014-0.020
- K1 ≈ 0.15-0.20

**Transonic (M ≈ 0.9-1.2):**
- C_D0 rises to ~0.025-0.040 (wave drag onset)
- K1 rises to ~0.20-0.40

**Supersonic (M > 1.2):**
- C_D0 ≈ 0.025-0.040
- K1 ≈ 0.20-0.50

**AAF Example values (from Fig. 2.E1a / Table 2.E1):**
- C_L_max = 2.0 (assumed, K2 = 0)
- Subsonic: K1 = 0.18, C_D0 = 0.014-0.016
- M = 0.9: K1 = 0.18, C_D0 = 0.016
- M = 1.5: K1 = 0.27, C_D0 = 0.028
- M = 1.6: K1 = 0.288, C_D0 = 0.028
- M = 1.8: K1 = 0.324, C_D0 = 0.028

---

## PART 10: AAF EXAMPLE DESIGN POINT (from Chapter 2 and 3 Examples)

**Selected preliminary design point:**
```
T_SL/W_TO = 1.25
W_TO/S    = 64 lbf/ft^2
TR        = 1.07
```

**Resulting aircraft sizing (W_TO = 24,000 lbf):**
```
W_TO = 24,000 lbf
T_SL = 30,000 lbf
S    = 375 ft^2
W_P  = 2,660 lbf
W_E  = 14,650 lbf  (W_E/W_TO = 0.6104)
W_F  = 6,690 lbf   (W_F/W_TO = 0.2787)
```

**Engine type selected:** Low bypass ratio mixed flow turbofan (with afterburner)

---

## PART 11: STANDARD ATMOSPHERE (from Chapter 2 examples)

At key altitudes (from Appendix B, standard day):

| Alt (ft) | theta  | delta  | theta_0 at M1.5 | delta_0 at M1.5 |
|----------|--------|--------|-----------------|-----------------|
| SL       | 1.0000 | 1.0000 | (see M below)   | (see M below)   |
| 2000     | 1.0796 (100F hot day) | 0.9298 | (M0.1) 1.0818 | 0.9363 |
| 30,000   | 0.7940 | 0.2975 | (M1.5) 1.1513  | 1.0921         |
| 40,000   | 0.7519 | 0.1858 | (M1.8) 1.2391  | 1.0676         |

**Standard day at SL, M=0:** theta=1.0, delta=1.0, theta_0=1.0, delta_0=1.0

**Standard day formulas:**
```
theta  = T/518.67 R  (US units)
delta  = P/2116.22 lbf/ft^2  (US units)
```

---

## PART 12: NUMERICAL EXAMPLE — TSFC AND ALPHA USAGE

### From Chapter 3 AAF example, segment warm-up (Case 9):
```
h = 2000 ft, M = 0, T_SL/W_TO = 1.25
theta = 1.0796, delta = 0.9298
theta_0 = 1.0796, delta_0 = 0.9298 (at M=0)
alpha_dry = 0.5390 (mil power, from Eq. 2.54b with TR=1.07)
C1 = 0.9 (mil power TSFC constant for low-BPR turbofan)
Delta_t = 60 s

Pi_A = 1 - C1*sqrt(theta) * (alpha/beta) * (T_SL/W_TO) * Delta_t
     = 1 - 0.9*(1/3600)*sqrt(1.0796)*(0.5390/1.0)*1.25*60
     = 0.9895
```

### From Chapter 2 supercruise example (M1.5, 30kft, mil power, TR=1.07):
```
theta = 0.7940, delta = 0.2975
theta_0 = 1.1513, delta_0 = 1.0921
theta_0 > TR=1.07, so use above-break formula
alpha_dry = delta_0 * {1 - 3.8*(theta_0-TR)/theta_0}
          = 1.0921 * {1 - 3.8*(1.1513-1.07)/1.1513}
          = 1.0921 * {1 - 3.8*0.0700}
          = 1.0921 * {1 - 0.2680}
          = 1.0921 * 0.7320 = ~0.4794
```
(Book gives alpha_dry = 0.4792 at M1.5/30kft, TR=1.07 — confirmed)

---

## PART 13: APPENDIX D — ENGINE PERFORMANCE: THETA BREAK AND THROTTLE RATIO

### D.1 — Definition of theta_0 (dimensionless freestream total temperature) — Eq. (D.1):
```
theta_0 = T_t0 / T_std = T_0 * (1 + (gamma_c - 1)/2 * M0^2) / T_std = theta * tau_r
```
Where:
- T_t0  = freestream total (stagnation) temperature
- T_std = standard sea-level static temperature (518.67 R or 288.15 K)
- tau_r  = isentropic total temperature ratio (= 1 + (gamma-1)/2 * M^2)
- theta  = T/T_std = static temperature ratio
- At SLS standard day: theta_0 = 1.0 (since theta=1, M=0)
- Typical range for flight envelope: 0.8 < theta_0 < 1.4

### D.2 — Compressor power balance (Eq. D.2):
```
tau_c - 1 = eta_m * (1-beta) * (1+f) * (1-tau_t) * (1/T_std) * (c_pt/c_pc) * (T_t4/theta_0)
```
Shows: compressor temperature ratio depends on throttle setting T_t4 and flight condition theta_0.

### D.3 — Compressor pressure ratio as function of T_t4/theta_0 (Eq. D.3, D.4):
```
pi_c = [1 + eta_c * (tau_c - 1)]^(gamma_c/(gamma_c-1)) = (1 + C1 * T_t4/theta_0)^(gamma_c/(gamma_c-1))

C1 = eta_c * eta_m * (1-beta) * (1+f) * (1-tau_t) * (1/T_std) * (c_pt/c_pc)   [Eq. D.4]
```
Key result: pi_c varies only with ratio T_t4/theta_0.

### D.5 — Definition of Theta Break (theta_0_break):
The theta break is the unique value of theta_0 at which the control system must
simultaneously switch from limiting pi_c (to pi_c_max) to limiting T_t4 (to T_t4_max).

- For theta_0 < theta_0_break: pi_c = pi_c_max (T_t4 < T_t4_max)
- For theta_0 > theta_0_break: T_t4 = T_t4_max (pi_c < pi_c_max)
- At theta_0 = theta_0_break: BOTH pi_c = pi_c_max AND T_t4 = T_t4_max simultaneously

### D.6 — THE THROTTLE RATIO (TR) — **CENTRAL EQUATION** — Eq. (D.5, D.6):
At SLS standard day, theta_0 = theta_0_SLS = 1.0. The ratio T_t4/theta_0 is constant
along the operating line. Therefore:
```
T_t4_max / theta_0_break = T_t4 / theta_0 = T_t4_SLS   [Eq. D.5]
```
(because theta_0_SLS = 1.0)

The THROTTLE RATIO TR is defined as:
```
TR = T_t4_max / T_t4_SLS = theta_0_break                [Eq. D.6]
```

**Key interpretation:**
- TR = theta_0_break (they are IDENTICAL, used interchangeably)
- TR numerically equals the value of theta_0 at which both limits are reached simultaneously
- Setting TR > 1 means the engine operates below pi_c_max at SLS standard day
- The engine achieves maximum simultaneous performance only at theta_0 = TR

**Example:** TR = 1.1 means theta_0_break = 1.1. At SLS (theta_0 = 1.0), only T_t4 is at
its maximum; pi_c is below pi_c_max. At M0 = 0.707 SLS, theta_0 = 1.1*(M0^2*0.2+1) = 1.1
→ this is exactly where both limits are simultaneously reached.

### D.7 — Sea-level Mach number at theta break (Eq. D.7):
```
M0_break = sqrt(2/(gamma_c-1) * (theta_0_break - 1))
```
For gamma_c = 1.4: M0_break = sqrt(5*(TR - 1))
Example: TR = 1.1 → M0_break = sqrt(5*0.1) = 0.707

### D.8 — Altitude at theta break (Eq. D.8):
For M0 = 0, the altitude h_break where theta = theta_0_break:
```
theta(h_break) = theta_0_break = TR
```

### D.9-D.11 — Compressor operating line (Eq. D.9, D.10, D.11):
```
m_dot_c2 = (pi_c * pi_b * P_std * A4 * MFP(M4)) / ((1-beta)*(1+f)) * sqrt(theta_0/T_t4)
          = C2_const * pi_c * sqrt(theta_0/T_t4)    [Eq. D.9]

C2_const = pi_b * P_std * A4 * MFP(M4) / ((1-beta)*(1+f))    [Eq. D.10]

m_dot_c2 = C2_const * pi_c * sqrt(C1 / (pi_c^((gamma_c-1)/gamma_c) - 1))    [Eq. D.11]
```
The operating line shape is characteristic of Fig. 5.5 and 7.E11 in the textbook.

### D.12-D.16 — Uninstalled specific thrust (theta_0 <= theta_0_break, constant T_t4/theta_0):
```
F / m_dot_0 = a_0/g_c * (M0*V9/V0 - M0)                              [Eq. D.12]

M0*V9/V0 = sqrt(2*tau_t*tau_r/(gamma_c-1) * [1 - (1/(pi_r*pi_d*pi_c*pi_b*pi_t*pi_n))^((gamma_t-1)/gamma_t)])
                                                                        [Eq. D.13]

F/(m_dot_0*sqrt(theta)) = a_std/g_c * f1{M0}                          [Eq. D.14]

f1{M0} = sqrt(C3*tau_r * [1 - (1/(pi_d*pi_c*pi_b*pi_t*pi_n*pi_r))^((gamma_t-1)/gamma_t)]) - M0
                                                                        [Eq. D.15]

C3 = 2*tau_t/(gamma_c-1) * (1/T_std) * (c_pt/c_pc) * (T_t4/theta_0) [Eq. D.16]
```
**Critical result:** F/(m_dot_0*sqrt(theta)) is a function ONLY of M0 for theta_0 <= TR.
This means specific thrust collapses to a single line (Fig. D.4) — independent of altitude
for a given Mach number when below the break.

### D.17 — Corrected-flow form of specific thrust (Eq. D.17):
```
F = a_std * delta_0^2 * m_dot_c2 / g_c * f1{M0}
```

### D.18-D.21 — Uninstalled TSFC (theta_0 <= theta_0_break) (Eq. D.18-D.21):
```
S = m_dot_f / F = f / (F/m_dot_0) = g_c/(a_std * eta_b * h_PR) * c_pc*T_0/sqrt(theta) * (tau_lambda - tau_r*tau_c)/(f1{M0})
                                                                        [Eq. D.18]

S/sqrt(theta) = C4 * tau_r / f1{M0}                                    [Eq. D.19]

C4 = g_c*a_std/(eta_b*h_PR*(gamma_c-1)) * (c_pt/c_pc * (1/T_std) * (T_t4/theta_0) - tau_c)
                                                                        [Eq. D.20]
```
Linear fit of S/sqrt(theta) for turbojet (Fig. D.5):
```
S/sqrt(theta) = 1.08 + 0.26*M0    [lbm/(lbf-h)]                       [Eq. D.21]
```
Compares favorably with Eq. (3.56a): turbojet mil power C1=1.1, C2=0.30 (slightly offset
because Eq. D.21 is for a specific example engine).

### D.22-D.26 — Uninstalled specific thrust (theta_0 > theta_0_break, T_t4 = T_t4_max fixed):
```
F/(m_dot_0*sqrt(theta)) = a_std/g_c * f2{M0, theta}                    [Eq. D.22]

f2{M0, theta} = sqrt(C5/theta * [1 - (1/(pi_d*pi_b*pi_t*pi_n))^((gamma_t-1)/gamma_t)
                     * (1/(tau_r + C6/theta))^((gamma_c/(gamma_t*(gamma_c-1)))]) - M0
                                                                        [Eq. D.23]

tau_lambda_star = c_pt*T_t4_max / (c_pc*T_std)                         [Eq. D.24]

C5 = 2*tau_t*tau_lambda_star / (gamma_c-1)                             [Eq. D.25]

C6 = eta_c*(1-tau_t)*tau_lambda_star                                   [Eq. D.26]
```
For theta_0 > TR: F/(m_dot_0*sqrt(theta)) now depends on BOTH M0 and theta (altitude matters).
This leads to multiple curves in Fig. D.6 (one per altitude/theta value).

### D.27-D.29 — Uninstalled TSFC (theta_0 > theta_0_break) (Eq. D.27-D.29):
```
S = m_dot_f/F = c_pc*T_0/(eta_b*h_PR * F/m_dot_0) * (tau_lambda_star/theta - tau_r*tau_c) [Eq. D.27]

S/sqrt(theta) = C7 * {tau_t*tau_lambda_star/theta - tau_r} / (F/(m_dot_0*sqrt(theta)))   [Eq. D.28]

C7 = c_pc*T_std / (eta_b*h_PR)                                         [Eq. D.29]
```

### D.30-D.31 — Compressor discharge temperature (Eq. D.30, D.31):
```
T_t3/T_std = theta_3 = theta_0 * tau_c_max          for theta_0 <= theta_0_break  [Eq. D.30]
T_t3/T_std = theta_3 = theta_0 + theta_0_break*(tau_c_max - 1)  for theta_0 > theta_0_break  [Eq. D.31]
```

### HOT DAY FLAT RATING (from Appendix D text, p. 531):
- Aircraft engines retain standard day static thrust on "hot days" (up to 90-110°F / 32-43°C)
- Setting theta_0_break at or above the hot day SLS ratio guarantees constant static thrust
- This is equivalent to picking TR >= theta_hot_day_SLS
- For example: if T_t4_max first occurs at 1.1*T_std → theta_0_break = 1.1 at M0 = 0

### APPENDIX D — NUMERICAL EXAMPLE (for reference turbojet, Fig. D.3-D.8):
```
Reference point: pi_c_max = 20, T_t4 = T_t4_max = 3300 R (1833 K), theta_0_break = 1.1
m_dot_c2 = 100 lbm/s
C1 = 0.0004512 1/R (0.0008122 1/K)
C2 = 273.9 lbm*sqrt(R)/s  (92.60 kg*sqrt(K)/s)
C3 = 25.57,  pi_d*pi_c*pi_b*pi_t*pi_n = 5.451,  gamma_t = 1.33
C4 = 3.012 lbm/(lbf-h)*sqrt(R)  [85.31 mg/(N-s)]
C5 = 28.15,  C6 = 1.489,  pi_d*pi_b*pi_t*pi_n = 0.2725,  gamma_t = 1.33
C7 = 0.006998,  tau_lambda_star = 7.378
```

---

## PART 14: APPENDIX E — ENGINE EFFICIENCY AND THRUST MEASURES

### Overall Efficiency (Eq. E.3):
```
eta_O = Thrust power / Chemical energy rate = F*V0 / (m_dot_fc * h_PR)
```

### Thermal and Propulsive Efficiency decomposition (Eq. E.4):
```
eta_O = eta_TH * eta_P

eta_TH = Engine mechanical power / Chemical energy rate
eta_P  = Thrust power / Engine mechanical power
```

### Propulsive efficiency — exact (Eq. E.6):
```
eta_P = 2*{(1+f_o)*V9/V0 - 1} / {(1+f_o)*(V9/V0)^2 - 1}
```

### Propulsive efficiency — approximate (Eq. E.7):
```
eta_P ≈ 2 / (V9/V0 + 1)
```
This is the most transparent form. eta_P < 1 always, increases as V9/V0 → 1.
This drives high-BPR engines (lower V9/V0 → higher eta_P).

### Performance Measure Interrelationships (Table E.1):
```
F/m_dot_0 = F/m_dot_0                        [specific thrust]
F/m_dot_0 = f_o/S                            [F/m_dot from S]
F/m_dot_0 = f_o*h_PR*eta_O/V0               [F/m_dot from eta_O]

S          = f_o/(F/m_dot_0)                 [TSFC from specific thrust]
S          = S                               [TSFC]
S          = V0/(h_PR*eta_O)                 [TSFC from eta_O]

eta_O      = V0*F/(f_o*h_PR*m_dot_0)        [from F/m_dot]
eta_O      = V0/(h_PR*S)                    [from TSFC]
```
Where: f_o = m_dot_fc/m_dot_a = overall fuel/air ratio

### Uninstalled Thrust F (Eq. E.5, E.13):
The uninstalled thrust is the net axial force for inviscid external flow:
```
F = 1/g_c * {(m_dot_0 + m_dot_fc)*V9 - m_dot_0*V0} = m_dot_0/g_c * {(1+f_o)*V9 - V0}   [Eq. E.5]

F = I9 - I0 - P0*(A9-A0) = 1/g_c*(m_dot_9*V9 - m_dot_0*V0) + A9*(P9-P0)                 [Eq. E.13]
```
- F is an INHERENT property of the engine cycle, independent of installation
- F depends only on flow quantities governed by cycle parameters

### Internal Thrust F_i (Eq. E.8):
```
F_i = I9 - I1
```
(Difference of impulse functions at exit and engine face)

### Installed Thrust T vs Uninstalled Thrust F (Eq. E.14-E.17):
```
D_total = D_inlet + D_nozzle = integral(P - P0)*dA over inner boundary   [Eq. E.14]

D_inlet  = integral_0^m (P-P0)*dA >= 0     [forward/inlet installation drag]  [Eq. E.15]
D_nozzle = integral_m^9 (P-P0)*dA >= 0     [aft/nozzle installation drag]     [Eq. E.16]

T = F - (D_inlet + D_nozzle) <= F                                              [Eq. E.17]
```
**Key result:** Installed thrust T is always LESS THAN uninstalled thrust F.
The difference is the installation drag — primarily from:
- Boundary layer on engine nacelle (frictional, goes to vehicle drag account)
- Pressure drag from boundary layer separation (engine designers' responsibility)

### Ground Test: Uninstalled Thrust from Scale Force (Eq. E.18, E.19):
```
I9 = I2 + F_s + P0*(A9 - A2)    [Eq. E.18]

F = F_s + (I2 - I0) - P0*(A2 - A0)    [Eq. E.19]
```
Where F_s = thrust stand scale force.
Ground test uncertainty: +/- 0.5 to 1.0% of F.

---

## PART 15: APPENDIX B — ALTITUDE TABLES (Key Reference Values)

### Standard Atmosphere Reference Values:
**British Engineering (BE) units:**
```
P_std = 2116.21 lbf/ft^2
T_std = 518.69 R
rho_std = 0.07647 lbm/ft^3
a_std = 1116 ft/s
```

**SI units:**
```
P_std = 101,325 N/m^2
T_std = 288.15 K
rho_std = 1.225 kg/m^3
a_std = 340.3 m/s
```

### Key Altitude Table Values (Standard Day, BE units):

| h (kft) | delta (P/P_std) | theta (T/T_std) |
|---------|-----------------|-----------------|
| 0       | 1.0000          | 1.0000          |
| 5       | 0.8321          | 0.9656          |
| 10      | 0.6878          | 0.9313          |
| 15      | 0.5646          | 0.8969          |
| 20      | 0.4599          | 0.8626          |
| 25      | 0.3716          | 0.8283          |
| 30      | 0.2975          | 0.7940          |
| 35      | 0.2360          | 0.7598          |
| 36      | 0.2250          | 0.7529          |
| 40      | 0.1858          | 0.7519          |
| 50      | 0.1151          | 0.7519          |
| 60      | 0.07137         | 0.7519          |
| 100     | 0.01100         | 0.7877          |

Note: theta becomes constant = 0.7519 at tropopause (~36.1 kft = 11 km) until ~66 kft.

### Density, Speed of Sound formulas (from Appendix B footer):
```
rho = rho_std * sigma = rho_std * (delta/theta)
a = a_std * sqrt(theta)
```

### Cold/Hot/Tropic Day Temperature Profiles (Appendix B, p. 516):
Cold day SLS: T0 = 222.10 K
Hot day SLS:  T0 = 312.60 K
Tropic day SLS: T0 = 305.27 K

---

## PART 16: APPENDIX C — GAS TURBINE ENGINE DATA

### Table C.1 — Military Turbojets and Turboprops (selected):
| Model     | Type | Thrust (lbf) | SFC (max) | Notes          |
|-----------|------|--------------|-----------|----------------|
| J57-P-23  | TF   | 16,000       | 2.10      | AB, F-102A     |
| J75-P-17  | TJ   | 24,500       | 2.15      | AB, F-106A/B   |
| J79-GE-17 | TJ   | 17,820       | 1.965     | AB, F-4E/G     |
| J85-GE-21 | TJ   | 5,000        | 2.13      | AB, F-5E/F     |
| J58-P-4   | TJ   | 32,500       | 0.775     | AB, YF-12A (non-AB SFC) |

### Table C.2 — Military Turbofan Engines (selected, CRITICAL DATA):
| Model        | Type | Thrust (lbf) | TSFC (1/h) | BPR  | FPR  | Notes           |
|--------------|------|--------------|------------|------|------|-----------------|
| F100-PW-229  | TF   | 29,000       | 2.05       | 0.4  | 3.8  | F-15, F-16      |
| F101-GE-102  | TF   | 17,800       | 1.74       | 1.91 | 2.31 | B-1B            |
| F103-GE-101  | TF   | 30,780       | 2.460      | 4.31 | —    | KC-10A          |
| F107-WR-101  | TF   | 635          | 0.685      | 1.0  | 2.1  | Cruise Missile  |
| F108-CF-100  | TF   | 21,634       | 0.363      | 6.0  | 1.5  | KC-135R         |
| F110-GE-100  | TF   | 28,620       | 2.08       | 0.80 | 2.98 | F-16            |
| F117-PW-100  | TF   | 41,700       | 0.33       | 5.8  | —    | (PW2040) C-17A  |
| F118-GE-100  | TF   | 19,000       | 0.535      | —    | —    | B-2             |
| F404-GE-FID  | TF   | 10,000       | —          | —    | —    | F-117A          |
| F404-GE-400  | TF   | 16,000       | 0.585      | —    | —    | F-18, F-5G      |
| JT8D-7B      | TF   | 14,500       | —          | 1.74 | —    | (TF33-102) C-22 |
| TF30-P-111   | TF   | 25,100       | 2.450      | 0.73 | 2.43 | A-111B          |
| TF33-P-3     | TF   | 14,560       | 0.686      | 1.55 | 1.7  | B-52H, C-141    |
| TF34-GE-100  | TF   | 9,065        | 0.37       | 6.42 | 1.5  | A-10            |
| TF39-GE-1    | TF   | 40,805       | 0.315      | 8.0  | 1.56 | C-5A            |
| TF41-A-1B    | TF   | 14,500       | 0.647      | 0.76 | 2.45 | A-7D, K         |
| TFE731-2     | TF   | 3,500        | 0.504      | 2.67 | 1.54 | C-21A           |

**TSFC here is at sea level static MAXIMUM thrust. Units: lbm fuel/(lbf-h)**

### Table C.3 — Civil Turbofan Engines (selected cruise TSFC):
| Model          | Thrust (kN) | BPR  | Cruise TSFC (1/h) | Alt (kft) | M    | Notes   |
|----------------|-------------|------|-------------------|-----------|------|---------|
| CF6-50-C2      | 52,500 lbf  | 4.31 | 0.630             | 35        | 0.80 | DC-10   |
| CF6-80-C2      | 52,500 lbf  | 5.31 | 0.576             | 35        | 0.80 | 747-200 |
| GE90-B4        | 87,400 lbf  | 8.40 | 0.579             | 35        | 0.80 | 777     |
| JT8D-15A       | 15,500 lbf  | 1.04 | 0.779             | 30        | 0.80 | 727,737 |
| JT9D-59A       | 53,000 lbf  | 4.90 | 0.646             | 35        | 0.85 | DC10-40 |
| PW2037         | 38,250 lbf  | 6.00 | 0.582             | 35        | 0.80 | 757-200 |
| PW4084         | 87,900 lbf  | 6.41 | —                 | 35        | 0.83 | 777     |
| CFM56-3        | 23,500 lbf  | 5.00 | 0.667             | 35        | 0.80 | 737-300 |
| CFM56-5C       | 31,200 lbf  | 6.60 | 0.545             | 35        | 0.80 | A340    |
| RB211-524B     | 50,000 lbf  | 4.50 | 0.607             | 35        | 0.80 | L1011   |
| RB211-882      | 84,700 lbf  | 6.01 | 0.557             | 35        | 0.83 | 777     |
| V2528-D5       | 28,000 lbf  | 4.70 | 0.574             | 35        | 0.80 | MD-90   |
| ALF502R-5      | 6,970 lbf   | 5.70 | 0.720             | 25        | 0.70 | BAe146  |
| TFE731-5       | 4,500 lbf   | 3.34 | 0.771             | 40        | 0.80 | BAe125  |
| FJ44           | 1,900 lbf   | 3.28 | 0.675             | 30        | 0.70 | BAe1000 |
| Olympus 593    | 38,000 lbf  | 0    | 1.190             | 53        | 2.00 | Concorde|

### Table C.4 — Temperature/Pressure Data for Representative Engines (selected):
| Parameter      | J57 (turbojet) | JT3D (turbofan, sep exhaust) | JT8D (turbofan, mixed) | F100-PW-100 (low-BPR, mixed) |
|---------------|----------------|------------------------------|------------------------|-------------------------------|
| P_t2 (psia)  | 14.7           | 14.7                         | 14.7                   | 13.1                          |
| T_t2 (F)     | 59             | 59                           | 59                     | 59                            |
| T_t4 (F)     | 1,570 (max)    | 1,600 (max)                  | 1,720 (max)            | 2,566 (max)                   |
| Thrust (lbf) | 16,000 (max)   | 18,000 (max)                 | 14,000 (max)           | 23,700 (max)                  |
| BPR          | 0              | 1.36                         | 1.1                    | 0.69                          |

---

## SUMMARY TABLE: TSFC CONSTANTS C1 AND C2

| Engine Type                    | Power Setting | C1   | C2   | Eq.     |
|-------------------------------|---------------|------|------|---------|
| High bypass turbofan (M<0.9)  | Any (subsonic)| 0.45 | 0.54 | (3.54)  |
| Low bypass mixed turbofan     | Military (dry)| 0.90 | 0.30 | (3.55a) |
| Low bypass mixed turbofan     | Maximum (wet) | 1.60 | 0.27 | (3.55b) |
| Turbojet                      | Military (dry)| 1.10 | 0.30 | (3.56a) |
| Turbojet                      | Maximum (wet) | 1.50 | 0.23 | (3.56b) |
| Turboprop                     | Any           | 0.18 | 0.80 | (3.57)  |

**Formula:** TSFC = (C1 + C2*M) * sqrt(theta)   [h^-1]

---

## SUMMARY TABLE: THRUST LAPSE ALPHA EQUATIONS

All equations in form: alpha = f(delta_0, theta_0, M0, TR)

| Engine Type              | Power   | theta_0 condition | Formula |
|--------------------------|---------|-------------------|---------|
| High-BPR turbofan (M<0.9)| Max     | <= TR             | delta_0*(1 - 0.49*sqrt(M0)) |
| High-BPR turbofan (M<0.9)| Max     | > TR              | delta_0*(1 - 0.49*sqrt(M0) - 3*(theta_0-TR)/(1.5+M0)) |
| Low-BPR mixed turbofan  | Max (wet)| <= TR             | delta_0 |
| Low-BPR mixed turbofan  | Max (wet)| > TR              | delta_0*(1 - 3.5*(theta_0-TR)/theta_0) |
| Low-BPR mixed turbofan  | Mil (dry)| <= TR             | 0.6*delta_0 |
| Low-BPR mixed turbofan  | Mil (dry)| > TR              | 0.6*delta_0*(1 - 3.8*(theta_0-TR)/theta_0) |
| Turbojet                | Max (wet)| <= TR             | delta_0*(1 - 0.3*(theta_0-1) - 0.1*sqrt(M0)) |
| Turbojet                | Max (wet)| > TR              | delta_0*(1 - 0.3*(theta_0-1) - 0.1*sqrt(M0) - 1.5*(theta_0-TR)/theta_0) |
| Turbojet                | Mil (dry)| <= TR             | 0.8*delta_0*(1 - 0.16*sqrt(M0)) |
| Turbojet                | Mil (dry)| > TR              | 0.8*delta_0*(1 - 0.16*sqrt(M0) - 24*(theta_0-TR)/((9+M0)*theta_0)) |
| Turboprop               | Any     | M<=0.1            | delta_0 |
| Turboprop               | Any     | <= TR (M>0.1)     | delta_0*(1 - 0.96*(M0-0.1)^0.25) |
| Turboprop               | Any     | > TR (M>0.1)      | delta_0*(1 - 0.96*(M0-0.1)^0.25 - 3*(theta_0-TR)/(8.13*(M0-0.1))) |

---

## KEY REFERENCES WITHIN BOOK
- Eq. (2.3): T = alpha*T_SL (thrust lapse definition)
- Eq. (2.4): W = beta*W_TO (weight fraction definition)
- Eq. (2.52a/b): theta_0, delta_0 definitions
- Eq. (2.53): High-BPR turbofan thrust lapse
- Eq. (2.54a/b): Low-BPR turbofan thrust lapse (max and mil)
- Eq. (2.55a/b): Turbojet thrust lapse (max and mil)
- Eq. (2.56): Turboprop thrust lapse
- Eq. (3.2): Basic fuel flow equation
- Eq. (3.12): TSFC = (C1+C2*M)*sqrt(theta) — general form
- Eq. (3.54): High-BPR turbofan TSFC
- Eq. (3.55a/b): Low-BPR turbofan TSFC (mil and max)
- Eq. (3.56a/b): Turbojet TSFC (mil and max)
- Eq. (3.57): Turboprop TSFC
- Appendix D: Throttle ratio TR derivation and theta_0_break
- Appendix E: Installed vs uninstalled efficiency and thrust
- Chapter 6: Installation losses

---

*[Extraction continues — Appendix D (TR/theta_break), Appendix E (installed vs uninstalled), and Chapter 6 content to be added below]*
