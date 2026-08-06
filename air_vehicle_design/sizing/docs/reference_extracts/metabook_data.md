# The Metabook of Aircraft Design — Extracted Data
**Source:** AE481 Aircraft Design course notes, J.R.R.A. Martins, University of Michigan  
**Compiled:** October 17, 2021 (~123 pages)  
**Purpose:** Reference for MATLAB MDA package, F-16A multidisciplinary analysis

---

## Chapter 2 — First Estimate of Takeoff Weight

### Basic Weight Equation

```
W0 = Wcrew + Wpayload + Wf + We                             (2.1)
W0 = (Wcrew + Wpayload) / (1 - Wf/W0 - We/W0)             (2.2)
We/W0 = A * W0^C    [Raymer empty-weight regression]        (2.3)
```

### Raymer Empty Weight Regression Constants (Table 3.1)

| Aircraft Type               | A (US)  | A (SI) | C      | Kvs (variable sweep) | Kvs (fixed) |
|-----------------------------|---------|--------|--------|----------------------|-------------|
| Jet fighter                 | 2.34    | 2.11   | -0.13  | 1.04                 | 1.00        |
| Military cargo/bomber       | 0.93    | —      | -0.07  | —                    | —           |
| Jet transport               | 1.02    | —      | -0.06  | —                    | —           |
| UAV-Tac Recce / UCAV        | 1.67    | —      | -0.16  | —                    | —           |
| Jet trainer                 | 1.59    | —      | -0.10  | —                    | —           |

### Mission Segment Fuel Fractions (Raymer Table 3.4)

| Segment                          | Typical Wi/Wi-1 |
|----------------------------------|-----------------|
| Engine start and warm-up/takeoff | 0.970           |
| Climb                            | 0.985           |
| Descent                          | 0.990           |
| Landing and taxi                 | 0.995           |

### Breguet Range and Endurance Equations

```
Breguet range:    R = (V/c) * (L/D) * ln(W_start/W_end)         (2.6)
                  W_end/W_start = exp(-R*c / (V*(L/D)))          (2.7)

Breguet endurance: E = (L/D)/c * ln(W_start/W_end)
                   W_end/W_start = exp(-E*c / (L/D))             (2.8)
```
- V in ft/s (or m/s), R in ft (or m)
- c = TSFC in lb_fuel/(lbf*hr) = 1/hr (consistent units required)
- For cruise: L/D = 0.943 * (L/D)max for maximum range (Nicolai & Carichner)

### TSFC Typical Values

| Engine Type                           | Cruise c (lb/hr/lb) | Loiter c (lb/hr/lb) |
|---------------------------------------|---------------------|---------------------|
| High-BPR turbofan (civil)             | ~0.5                | ~0.4                |
| Low-BPR turbofan (military, dry)      | ~0.7–0.9            | —                   |
| Turbojet (uninstalled, sea-level)     | ~1.0–1.3 at Mach 1  | —                   |

### L/D and Drag Polar

```
Wetted AR:    b²/Swet = AR / (Swet/Sref)                        (2.9)
Drag polar:   CD = CD0 + k*CL²                                  (2.10)
              k = 1/(pi*AR*e)
L/D:          L/D = CL / (CD0 + k*CL²)                         (2.11)
At (L/D)max:  CL* = sqrt(CD0/k)                                 (2.14)
(L/D)max = (1/2)*sqrt(1/(CD0*k)) = (1/2)*sqrt(pi*e*AR/CD0)     (2.15)
```

### Fuel Fraction with Reserve

```
Wf/W0 = (1 - W_final/W0) * 1.06     [6% reserve + trapped fuel]   (2.17)
```

### TOGW Iteration Algorithm (Algorithm 1)

```
W0 = W_guess
while |W0_new - W0| / |W0_new| > 1e-6:
    We/W0 = A * W0^C
    Compute all segment fuel fractions → Wf/W0
    W0_new = (Wcrew + Wpayload) / (1 - Wf/W0 - We/W0)
    W0 = W0_new
```

---

## Chapter 4 — Preliminary Sizing (Constraint Analysis)

### Wing Loading and Dynamic Pressure

```
W/S = (1/2)*rho*V²*CL                                           (4.2)
V = sqrt(2*W/S / (rho*CL))                                      (4.4)
```

### Conversion Between Mission T/W and Takeoff T/W

```
(T/W)_TO = (T3/W3) * (W3/W0) * (T0/T3)                        (4.6)
```

### Drag Model

```
CD = CD0 + CL²/(pi*AR*e)                                        (4.7)
CD0 = Cf_e * Swet/S                                             (4.8)
```

### Roskam Wetted Area Regression

```
Swet = 10^c * W0^d                                              (4.9)
```
For transport jets: c = 0.0199, d = 0.7531  
(W0 in lbs, Swet in ft²)

### Equivalent Skin Friction Coefficient Cf_e (Raymer Table 12.3)

| Aircraft Type                        | Cf_e   |
|--------------------------------------|--------|
| Bomber                               | 0.0030 |
| Civil transport                      | 0.0026 |
| Military cargo (high fuselage upsweep) | 0.0035 |
| Air Force fighter                    | 0.0035 |
| Navy fighter                         | 0.0040 |
| Clean supersonic cruise aircraft     | 0.0025 |
| Light aircraft — single engine       | 0.0055 |
| Light aircraft — twin engine         | 0.0045 |
| Prop seaplane                        | 0.0065 |
| Jet seaplane                         | 0.0040 |

### CD0 as Function of Wing Area S

```
CD0 = Cf_e * (Swet_rest + 2*S) / S                             (4.58)
```
(Used when wing area S is a design variable; Swet_rest = wetted area of all non-wing components)

### Drag Increments by Configuration (Roskam Table 3.6)

| Configuration                  | Delta_CD0      | Oswald e    |
|-------------------------------|----------------|-------------|
| Clean (cruise)                 | 0              | 0.80–0.85   |
| Takeoff flaps                  | 0.010–0.020    | 0.75–0.80   |
| Landing flaps                  | 0.055–0.075    | 0.70–0.75   |
| Landing gear (add to above)    | 0.015–0.025    | no effect   |

### Stall Speed Constraint

```
W/S = (1/2) * rho * Vstall² * CLmax                            (4.13)
```

### Takeoff Field Length Constraint (FAR 25)

```
TOP25 = (W/S) / ((rho/rhoSL) * CLmax_TO * (T/W))              (4.14)
TOP25 = BFL / 37.5                                              (4.15)
T/W  = (W/S) / ((rho/rhoSL) * CLmax_TO * TOP25)               (4.16)
```

### Landing Field Length Constraint (FAR 25)

```
sland = 80 * (W/S) * (1/((rho/rhoSL)*CLmax)) + sa             (4.19)
sa = 1000 ft (airliner) or 600 ft (GA)
FAR 25 landing field = sland * 1.67
Rearranged: W/S = (rho/rhoSL)*CLmax/80 * (Sland_avail/1.67 - sa)  (4.45)
```

### Climb Constraint (Jet-Powered)

```
T/W = 1/(L/D) + G                                              (4.21)
T/W = (CD0 + CL²/(pi*AR*e)) / CL + G                          (4.22)
CL = CLmax / ks²   (ks = V/Vstall, speed ratio)               (4.23)
T/W = (ks²/CLmax)*CD0 + CLmax/(ks²*pi*AR*e) + G              (4.24)
```

Correction to takeoff T/W (OEI = one engine inoperative):
```
(T/W)_TO = (1/0.8) * (1/0.94) * (Neng/(Neng-1)) * (W/W_TO) * (T/W)_climb  (4.25)
```

### FAR 25 Climb Gradient Requirements

| Regulation    | Condition         | Gradient G (2/3/4 eng) | Config                     | ks   |
|---------------|-------------------|-----------------------|----------------------------|------|
| FAR 25.111    | OEI, takeoff      | 1.2%/1.5%/1.7%        | TO flaps, gear down        | 1.2  |
| FAR 25.121    | OEI, transition   | 0%/0.3%/0.5%          | TO flaps, gear down        | 1.1–1.2 |
| FAR 25.121    | OEI, 2nd segment  | 2.4%/2.7%/3.0%        | TO flaps, gear UP          | 1.2  |
| FAR 25.121    | OEI, enroute      | 1.2%/1.5%/1.7%        | Clean                      | 1.25 |
| FAR 25.119    | AEO, balked land  | 3.2%                  | Landing flaps, gear down   | 1.3  |
| FAR 25.121    | OEI, balked land  | 2.1%/2.4%/2.7%        | Approach flaps, gear down  | 1.5  |

### Ceiling Constraint

```
T/W = 2*sqrt(CD0 / (pi*AR*e)) + G                              (4.30)
```
- G = rate of climb / V (absolute ceiling: G=0)

### Sustained Maneuver/Turn Constraint

```
T/W = q*CD0/(W/S) + (W/S)*n² / (q*pi*AR*e)                   (4.33)
```
where n = load factor, q = dynamic pressure at maneuver condition

### Cruise Constraint

```
T/W = q*CD0/(W/S) + (W/S)*(1/(q*pi*AR*e))                    (4.34)
Best range W/S: W/S = q * sqrt(pi*AR*e*CD0/3)                  (4.35)
```

### Thrust Lapse with Altitude (General Form)

```
Turbofan (general):  T = T0 * (rho/rho0)^m                     (4.55) / (10.9)
Turbojet:            T = T_SLS * (rho/rho0)                     (10.7)
Turbofan (BPR~5):    T = T_SLS * A * M_inf^(-n)               (10.8)
  where A and n are functions of altitude
```
Previously stated approximation (Ch. 4): T ≈ (rho_c/rhoSL)^0.6 * T_SLS

### Typical Wing Loading Values (Table 4.1)

| Aircraft Type                          | W/S (lb/ft²) | Example           |
|----------------------------------------|-------------|-------------------|
| Competition sailplanes                 | 6–12        | Schleicher ASW 17 |
| Light aircraft                         | 1–30        | Cessna 172        |
| Air-to-air fighters                    | 50–80       | F-22              |
| Long-range transports                  | 110–150     | Boeing 777        |
| Interceptor fighters                   | 120–150     | F-104             |
| Low-altitude subsonic cruise missiles  | 200–240     | Kongsberg NSM     |

### CLmax Assumed Values (Roskam Table 3.1)

| Condition    | CLmax |
|--------------|-------|
| Cruise (clean) | 0.9 |
| Takeoff      | 2.0   |
| Landing      | 2.6   |

### Boeing 777-200LR Worked Example (Table 4.3)

| Parameter          | Value (SI)          | Value (US)         |
|--------------------|---------------------|--------------------|
| AR                 | 9.8                 | 9.8                |
| Span b             | 64.80 m             | 212 ft             |
| Wing area Sref     | 427.8 m²            | 4605 ft²           |
| MTOW W0            | 347,815 kg          | 766,800 lb         |
| W/S (TO)           | 695.5 kg/m²         | 142.45 lb/ft²      |
| Cruise Mach        | 0.84                | —                  |
| Cruise altitude    | 40,000 ft           | —                  |
| Dynamic pressure q | —                   | 228.8 lbf/ft²      |
| Service ceiling    | 42,000 ft           | —                  |
| rho_c/rhoSL        | 0.2331              | —                  |
| CD0 (clean)        | 0.01597             | —                  |
| Cf_e               | 0.0026              | —                  |
| e                  | 0.85                | —                  |

### 777-200LR Drag Polars

| Configuration             | CD polar                              |
|---------------------------|---------------------------------------|
| Clean                     | CD = 0.01597 + 0.03815*CL²           |
| TO flaps, gear up         | CD = 0.03597 + 0.04054*CL²           |
| TO flaps, gear down       | CD = 0.06097 + 0.04054*CL²           |
| Landing flaps, gear up    | CD = 0.09097 + 0.04324*CL²           |
| Landing flaps, gear down  | CD = 0.11597 + 0.04324*CL²           |

---

## Chapter 6 — Wing Design

### Wing Geometry Definitions

```
AR = b² / Sref                                                   (6.1)
lambda = ctip / croot   [taper ratio]                            (6.2)
```

### Korn Equation for Drag-Divergence Mach Number

```
MDD = kappa/cos(Lambda) - (t/c)/cos²(Lambda) - CL/(10*cos³(Lambda))   (6.4)
```
- kappa = 0.87 for NACA 6-series airfoils
- kappa = 0.95 for supercritical airfoils
- Lambda = sweep angle at quarter-chord

```
Mcrit = MDD - (0.1/80)^(1/3)                                   (6.5)
CD_wave = 20*(M - Mcrit)^4    [valid if M > Mcrit]              (6.6)
```

### NACA 4-Digit Thickness Distribution

```
±y/c = (t/c)/0.2 * (0.2969*sqrt(x/c) - 0.126*(x/c) - 0.3537*(x/c)² 
        + 0.2843*(x/c)³ - 0.1015*(x/c)⁴)                       (6.7)
```

### Sectional Lift Coefficient

```
Cl = integral_0^1 (Cp_lower - Cp_upper) d(x/c)                 (6.9)
```

---

## Chapter 7 — Weights

### Typical Component Weights per Unit Area (Raymer Table 15.2)

| Component    | Fighters       | Transport/Bomber | GA           |
|-------------|----------------|------------------|--------------|
| Wing        | 9 lb/ft² (44 kg/m²) | 10 lb/ft² (49 kg/m²) | 2.5 lb/ft² (12 kg/m²) |
| H-tail      | 4 lb/ft² (20 kg/m²) | 5.5 lb/ft² (27 kg/m²) | 2 lb/ft² (10 kg/m²) |
| V-tail      | 5.3 lb/ft² (26 kg/m²) | 5.5 lb/ft² (27 kg/m²) | 2 lb/ft² (10 kg/m²) |
| Fuselage    | 4.8 lb/ft² (23 kg/m²) | 5 lb/ft² (24 kg/m²) | 1.4 lb/ft² (7 kg/m²) |

### Fraction-Based Weight Estimates

| Component             | Fraction of W0      |
|-----------------------|---------------------|
| Landing gear (fighter) | 0.033 * W0         |
| Landing gear (Navy fighter) | 0.045 * W0   |
| Landing gear (transport) | 0.043 * W0      |
| Installed engine      | 1.3 × bare engine weight |
| All-else empty (systems, avionics, etc.) | 0.17 * W0 |

### CG Locations (approximate)

| Component  | CG location                          |
|------------|--------------------------------------|
| Wing       | 40% MAC                              |
| H-tail     | 40% MAC                              |
| V-tail     | 40% MAC                              |
| Fuselage   | 40–50% fuselage length               |
| Landing gear | centroid of contact points          |

### MAC and CG Equations

```
MAC (trapezoidal): c_bar = (2/3)*croot*(1 + lambda + lambda²)/(1+lambda)  (7.2)/(8.6)
Y_mac = (b/6)*(1 + 2*lambda)/(1+lambda)                                    (8.7)
xMAC = xRLE + (b/6)*(croot + 2*ctip)/(croot+ctip) * tan(Lambda_LE)       (7.3)
x_40%MAC = xMAC + 0.4*MAC                                                  (7.4)
CG: x_CG = sum(Wi * xCG_i) / sum(Wi)                                      (7.1)
```

### Wing Weight Regression (Raymer, Transport/Cargo)

```
Wwing = 0.0051 * (Wdg*Nz)^0.557 * Sw^0.649 * AR^0.5 
        * (t/c)_root^(-0.4) * (1+lambda)^0.1 * cos(Lambda)^(-1) 
        * Scsw^0.1                                                          (7.11)
```
- Wdg = design gross weight (lb)
- Nz = ultimate load factor = 1.5 * n_limit
- Scsw = control surface area (ft²)

### Wing Weight (Kroo)

```
Wwing = 4.22*Swing + 1.642e-6 * n*b³*sqrt(W0*WZF)*(1+2*lambda) 
        / (Swing*(t/c)*cos²(Lambda_EA)*(1+lambda))                         (7.12)
```
- WZF = zero-fuel weight
- Lambda_EA = sweep of elastic axis

### Engine Weight Regressions (Roskam)

```
Weng_dry     = 0.521 * T0^0.9                           (7.13)
Weng_oil     = 0.082 * T0^0.65                          (7.14)
Weng_rev     = 0.034 * T0          [thrust reverser]    (7.15)
Weng_control = 0.26  * T0^0.5                           (7.16)
Weng_start   = 9.33  * (Weng_dry/1000)^1.078           (7.18)
Wengine_total = sum of above components                  (7.19)

Turboprop: Weng = P^0.9306 * 10^(-0.1205)              (7.20)
```
- T0 = max SLS thrust in lbs
- P = rated shaft horsepower (for turboprop)

### Composite Material Fudge Factors (Raymer Table 15.4)

| Component        | Factor    |
|------------------|-----------|
| Wing             | 0.85–0.90 |
| Tails            | 0.83–0.88 |
| Fuselage/nacelle | 0.90–0.95 |

### Detailed Weight Iteration Algorithm (Algorithm 5)

```matlab
W0 = W_guess;
% Engine weights (from T0 via Roskam):
Weng_dry     = 0.521 * T0^0.9;
Weng_oil     = 0.082 * T0^0.65;
Weng_rev     = 0.034 * T0;
Weng_control = 0.26  * T0^0.5;
Weng_start   = 9.33  * (Weng_dry/1000)^1.078;
Wengine      = Weng_dry + Weng_oil + Weng_rev + Weng_control + Weng_start;

% Structural component weights (from geometry):
Wfuse = 5.0  * Sfuse;       % fuselage @ 5 lb/ft²
Wht   = 5.5  * Sht;         % h-tail @ 5.5 lb/ft²
Wwing = 10.0 * Swing;       % wing @ 10 lb/ft²
Wvt   = 5.5  * Svt;         % v-tail @ 5.5 lb/ft²

while not_converged:
    % Fuel fraction from mission analysis:
    Wf_over_W0 = compute_fuel_fraction(W0);
    Wf   = Wf_over_W0 * W0;
    Wlg  = 0.043 * W0;      % landing gear (transport)
    Wxtra= 0.17  * W0;      % all-else empty
    W0_new = n_engine*Wengine + Wwing + Wht + Wvt + Wfuse ...
             + Wxtra + Wlg + Wf + Wpayload + Wcrew;
    % Check convergence
    W0 = W0_new;
end
```

---

## Chapter 8 — Stability and Control

### Tail Volume Coefficients

```
cVT = LVT * SVT / (bW * SW)      [typical: cVT ≈ 0.09 jet transports]   (8.1)
cHT = LHT * SHT / (c_bar_W * SW) [typical: cHT ≈ 1.0 jet transports]   (8.2)
```

### Pitching Moment and Static Stability

```
Cm_cg = (xcg/c_bar)*CLw - (lh*Sh/(c_bar*Sw))*CLh + Cmw + Cm_fus       (8.8)
Static margin = (xnp - xcg) / c_bar                                      (8.12)
```

### DATCOM Lift Curve Slope Formula

```
CLalpha = 2*pi*AR / (2 + sqrt((AR/eta)²*(1 + tan²(Lambda_half) - M²) + 4))  (8.15)
```
- eta (kappa in Ch. 11 notation) ≈ 0.97 (correction for section lift curve slope)
- Lambda_half = sweep angle at half-chord

Equivalent form from Ch. 11 (Eq. 11.6):
```
CL_alpha = 2*pi*AR / (2 + sqrt(AR²*(beta/kappa)²*(1 + tan²(Lambda_c/2)/beta²) + 4))
beta = sqrt(1 - M²)    [Prandtl-Glauert factor]                         (11.7)
kappa ≈ 0.97
```

### Downwash

```
de/dalpha ≈ 2*CLalpha_w / (pi * AR_w)                                   (8.16)
CLalpha_h = CLalpha_h0 * (1 - de/dalpha) * eta_h                        (8.14)
```

### Fuselage Pitching Moment (Gilruth / NACA TR 711)

```
dCm_fus/dCL = Kf * wf² * Lf / (Sw * c_bar * CLalpha_w)                (8.17)
```
Kf values (Table 8.1):
- Wing 1/4-chord at 0.1 body length → Kf = 0.115
- Wing 1/4-chord at 0.3 body length → Kf = 0.344
- Wing 1/4-chord at 0.4 body length → Kf = 0.487
- Wing 1/4-chord at 0.5 body length → Kf = 0.688

---

## Chapter 9 — Landing Gear (brief)

- Nose gear placed 10–15% of wheelbase forward of CG
- Main gear placed 10–15% of wheelbase aft of CG
- Tire sizing via regression on aircraft weight

---

## Chapter 10 — Propulsion

### Thrust Equation (full)

```
T = (m_dot + m_dot_fuel)*Vj - m_dot*V_inf + (pe - p_inf)*Ae            (10.5)
```
- Simplified (ignoring fuel mass and pressure terms): T = m_dot*(Vj - V_inf)

### Propulsive Efficiency

```
eta_p = 2 / (1 + Vj/V_inf)                                              (10.4)
```

### Turbojet: Thrust vs Altitude and Velocity

```
T = T_SLS * (rho/rho_SL)         [turbojet thrust lapse]                (10.7)
```
- TSFC for turbojet increases linearly with Mach below M=1:
```
c = 1 + k*M_inf                                                          (10.6)
```
where k is function of altitude and throttle setting (engine rpm)

- TSFC of a turbojet is approximately CONSTANT with altitude (effect of altitude on TSFC is very small)
- Thrust of a turbojet is approximately INDEPENDENT of aircraft velocity (velocity difference decreases but mass flow rate increases; effects cancel)

### Turbofan: Thrust vs Altitude and Velocity

Bypass Ratio (BPR) = mass flow through fan bypass / mass flow through core (higher BPR → higher propulsive efficiency)

```
T = T_SLS * A * M_inf^(-n)     [turbofan thrust model]                  (10.8)
```
where A and n are functions of altitude. T decreases with increasing V_inf for high-BPR turbofan.

Thrust relatively constant for M = 0.7–0.85 (cruise range for civil transports).

### Turbofan: Altitude Lapse

```
T = T0 * (rho/rho0)^m                                                   (10.9)
```
where T0 is sea-level thrust at that velocity, m is an empirical exponent.

### Turbofan TSFC Models

General empirical:
```
c = B*(1 + k*M_inf)             [valid for 0.7 < M < 0.85]             (10.10)
```
B and k are empirical constants from data correlation; c in lb/(lbf·h)

Mattingly (1996, Eqn. 1.36a) for high-BPR turbofans:
```
c = (0.4 + 0.45*M) * sqrt(theta)                                        (10.11)
```
- theta = T_altitude / T_SL (dimensionless temperature ratio, in Kelvin)
- Equivalent to B=0.4, k=1.125*sqrt(theta) in (10.10)
- c in lb/(lbf·h)

### GE90 Turbofan Data (Boeing 777) — Table 10.1
(Nicolai & Carichner 2010, Table J.6)

**General Electric GE90 — Uninstalled**
- Application: Boeing 777
- SLS thrust: 76,000 lb (777-200) to 115,000 lb (777-300ER)
- SLS SFC: 0.29–0.31 lb/(lbf·h)
- Weight: 17,300 lb
- Length: 287 in
- Maximum diameter: 134 in
- Overall Pressure Ratio: 40

**Takeoff Thrust (Thrust/SFC, limited to 5 min):**

| Altitude | M=0   | M=0.1 | M=0.2 |
|----------|-------|-------|-------|
| SL       | 98,000/0.29 | 87,762/0.32 | 79,585/0.356 |
| 2,000 ft | 92,908/0.289 | 83,569/0.322 | 75,929/0.358 |
| 4,000 ft | 87,390/0.292 | 7877/0.325 | 71,741/0.361 |

**Climb Thrust (Thrust/SFC):**

| Altitude   | M=0.4 | M=0.5 | M=0.6 | M=0.7 |
|------------|-------|-------|-------|-------|
| 5,000 ft   | 53,071/0.417 | 49,185/0.459 | 45,899/0.502 | — |
| 10,000 ft  | — | 44,660/0.459 | 42,091/0.495 | — |
| 15,000 ft  | — | 39,268/0.461 | 37,509/0.497 | — |
| 20,000 ft  | — | 33,138/0.463 | 32,364/0.50 | 31,798/0.532 |
| 25,000 ft  | — | — | 26,886/0.50 | 26,971/0.534 |
| 30,000 ft  | — | — | 21,777/0.492 | 22,177/0.532 |
| 35,000 ft  | — | — | 17,282/0.482 | 17,581/0.52 |
| 40,000 ft  | — | — | 13,699/0.486 | 13,936/0.524 |

**Cruise Partial Power (Thrust/SFC at M=0.75):**

| Altitude   | Col 1 | Col 2 | Col 3 | Col 4 | Col 5 |
|------------|-------|-------|-------|-------|-------|
| 30,000 ft  | 22,568/0.551 | 20,275/0.523 | 18,300/0.51 | 16,514/0.51 | 14,904/0.51 |
| 35,000 ft  | 17,888/0.539 | 16,538/0.512 | 14,925/0.50 | 13,469/0.497 | 12,156/0.50 |
| 40,000 ft  | 14,170/0.542 | 13,077/0.513 | 11,801/0.50 | 10,651/0.497 | 9610/0.499 |
| 45,000 ft  | 11,238/0.55 | 10,199/0.515 | 9204/0.502 | 8307/0.5 | 7497/0.503 |
| 50,000 ft  | 8777/0.55 | 7948/0.518 | 7173/0.506 | 6474/0.504 | 5843/0.507 |
| 55,000 ft  | 6840/0.553 | 6172/0.521 | 5570/0.509 | 5027/0.509 | 4539/0.512 |

---

## Chapter 11 — Structures and Loads

### Equivalent Airspeed

```
V_EAS = V_TAS * sqrt(sigma)     where sigma = rho/rho_SL                (11.1)
```
EAS is the sea-level equivalent speed giving same dynamic pressure as TAS at altitude.

### Load Factor

```
n = L/W = rho_SL * V_EAS² * CL_max / (2*W/S)                          (11.2)
```
In level flight n=1; inverted n=-1; turns/pull-ups n>1.

### Design Airspeeds

- **VS**: Stall speed at normal level flight
- **VA**: Design maneuver speed (corner speed) = VS * sqrt(n_limit); lowest speed to reach max n
- **VB**: Design speed for maximum gust intensity
- **VC**: Design cruise EAS (max normal operating condition)
- **VMO**: Maximum operating EAS ≈ 1.06 * VC (Kroo)
- **VD**: Dive speed (must not be exceeded); VD ≈ 1.07 * VMO for transonic; VD = 1.25*VC for slower aircraft

### Load Factor Limits

**Limit loads** (FAR Part 25):
- Positive limit load: not less than 2.5 g (and not greater than 3.8 g) for FAR Part 25
- Negative limit load: not less than -1 g
- No permanent deformation may occur at limit load

**Ultimate loads:**
- Ultimate = limit × safety factor
- Safety factor = 1.5 (FAR Part 25)
- Safety factor = 1.20 (some research/military aircraft)
- Safety factor = 1.75 (composite sailplanes)
- Structure must withstand ultimate load for at least 3 seconds without failure

### V-n Diagram Construction

**Positive stall curve:**
```
n = rho_SL * V_EAS² * CL_max / (2*W/S)                                 (11.2)
```

**Limit load factor for civil transports (if W < 50,000 lb):**
```
n_limit = 2.1 + 24000/(W + 10000)    [n need not be greater than 3.8]  (11.3)
```
For W > 50,000 lb: n_limit = +2.5 g minimum.

**Corner speed:**
```
VA = VS * sqrt(n_limit)
```

**Gust load factor:**
```
n = 1 ± Kg * CL_alpha * Ue * V_EAS / (498 * W/S)                       (11.4)
```
where:
- Kg = gust alleviation factor
- Ue = equivalent gust velocity (ft/s)
- V_EAS = equivalent airspeed (knots)
- W/S = wing loading (lb/ft²)

```
Kg = 0.88*mu / (5.3 + mu)                                               (11.5)
mu = 2*(W/S) / (rho * c_bar * CL_alpha * g)
```
- c_bar = S/b (standard mean chord)
- Note: check units carefully — result must be dimensionless

### FAR-Specified Gust Velocities (Table 11.1)

| Speed       | At/below 20,000 ft | At/above 50,000 ft |
|-------------|-------------------|-------------------|
| VB (rough air) | 66 ft/s        | 38 ft/s           |
| VC (cruise) | 50 ft/s           | 25 ft/s           |
| VD (dive)   | 25 ft/s           | 12.5 ft/s         |

Between 20,000 and 50,000 ft: interpolate linearly.

### V-n Diagram Procedure Summary

1. Compute stall curve: n = f(V_EAS) using Eq. (11.2) with CL_max for positive and CL_min for negative
2. Draw horizontal line at n_limit (maneuver envelope top)
3. Right boundary: n goes from n_limit at VA to 0 at VD; negative side goes from 0 at VC to -1 at VD
4. Find VB from intersection of stall curve with gust line (Ue = 66 ft/s at ≤20,000 ft)
5. Compute gust load factors at VC (Ue=50) and VD (Ue=25)
6. Final envelope = outermost of maneuver envelope and gust envelope

### 777-200LR V-n Example (at 20,000 ft, max weight)

| Parameter       | Value             |
|-----------------|-------------------|
| W/S             | 136.3 lb/ft²      |
| c_bar           | 21.72 ft          |
| rho at 20,000 ft | 0.001267 slug/ft³|
| CL_alpha        | 5.64 /rad         |
| CL_max          | 1.4 (no HLD)      |
| CL_min          | -0.7              |

Design speeds computed: VS=169.6 kts, VA=268.1 kts, VC=273.0 kts, VMO=289.4 kts, VD=309.7 kts

Gust envelope at 20,000 ft: mu=54.61, Kg=0.802

---

## Chapter 12 — Sensitivity Studies

### Finite Difference Methods

**Forward difference** (first-order, O(h) error):
```
f'(x) = (f(x+h) - f(x)) / h + O(h)                                    (12.4)
```

**Central difference** (second-order, O(h²) error):
```
f'(x) = (f(x+h) - f(x-h)) / (2h) + O(h²)                             (12.6)
```

**Second derivative** (central, O(h) error):
```
f''(x) = (f(x+2h) - 2*f(x) + f(x-2h)) / (4h²) + O(h)                (12.8)
```

**Step-size dilemma:** Too small → subtractive cancellation; too large → truncation error.
- Forward difference degrades below h ~ 1e-8
- Central difference degrades below h ~ 1e-5

**Cost:** n+1 evaluations for n design variables (forward difference)

### Complex-Step Derivative Method

```
f(x+ih) = f(x) + ih*f'(x) - h²*f''(x)/2! - ih³*f'''(x)/3! + ...     (12.10)
```
Taking imaginary part:
```
f'(x) = Im[f(x+ih)] / h + O(h²)                                        (12.11)
```

**Key advantage:** No subtractive cancellation — can use arbitrarily small h (e.g., h=1e-20)
- Achieves machine precision accuracy (~1e-14 relative error)
- Requires implementation to support complex arithmetic throughout

**Relative error metric:**
```
epsilon = |f'_computed - f'_ref| / |f'_ref|                             (12.13)
```

### Other Sensitivity Methods

- **Symbolic differentiation**: Exact for explicit functions; cannot handle iterative computations
- **Automatic differentiation (AD)**: Tools process source code to generate sensitivity code; handles all programming constructs
- **Semi-analytic (adjoint) methods**: Differentiate governing equations; very efficient for large numbers of inputs; computationally intensive to implement. Used for coupled MDA sensitivity of multidisciplinary systems.

---

## F-16 Data Found in Metabook

**No dedicated F-16 design example or detailed parameter table appears in this text.**

F-16 references found:
- Figure 4.2 (Tennekes 2009 chart): F-16 plotted at approximately W ~ 10^5 N (22,000 lb), V_cruise ~ 100–200 m/s
- Figure 2.4 (Raymer Fig. 3.5): F-16 plotted at approximately L/D_max ≈ 10, wetted AR ≈ 0.9

---

## Standard Atmosphere Reference Values

- rho_SL = 0.002377 slug/ft³ = 1.225 kg/m³
- ISA sea level: T=288.15 K, p=101,325 Pa
- 1 slug = 14.594 kg
- 1 ft = 0.3048 m
- 1 lbf = 4.448 N
- 1 lb/ft² = 47.88 Pa

---

## Key References Cited

- Raymer, D.P. "Aircraft Design: A Conceptual Approach." AIAA, 5th/6th ed.
- Roskam, J. "Airplane Design" (multi-volume series)
- Nicolai, L.M. & Carichner, G.E. "Fundamentals of Aircraft and Airship Design, Vol I." AIAA, 2010.
- Anderson, J.D. "Aircraft Performance and Design." McGraw-Hill, 1999.
- Mattingly, J.D. "Elements of Gas Turbine Propulsion." McGraw-Hill, 1996.
- Torenbeek, E. & Wittenberg, H. "Flight Physics." Springer, 2009.
- Kroo, I. "Aircraft Design: Synthesis and Analysis." Stanford AA241 notes.
- Hill, P. & Peterson, C. "Mechanics and Thermodynamics of Propulsion." Prentice Hall, 1991.
- Howe, D. "Aircraft Loading and Structural Layout." AIAA, 2004.
- Martins, J.R.R.A. et al. (2003) — complex-step method paper
- Kenway & Martins (2014) — coupled MDA sensitivity (adjoint)
