# FAST (Mokotoff et al.) — *A Future Aircraft Sizing Tool* — Extracted Data

**Source:** Paul R. Mokotoff, Maxfield Arnson, Yi-Chih Wang, and Gokcin Cinar, "FAST: A Future Aircraft Sizing Tool for Conventional and Electrified Aircraft Design," *Journal of Aircraft*, 2025. University of Michigan, Ann Arbor. (Previously AIAA SciTech Forum 2025, paper no. 2025-2374.) Tool DOI: <https://dx.doi.org/10.7302/26047>.

**Purpose:** Complete scrape of every equation, table, and data graph in the FAST journal paper, for reference by the MATLAB sizing MDA package. FAST is an open-source, MATLAB-based, propulsion-system-agnostic, energy-based conceptual aircraft sizing tool. Of particular interest to this project: the point-performance airframe/propulsion sizing loop (Eqs. 1–5), the energy-based mission/segment analysis (Algorithm 1), and the off-design turbofan TSFC/fuel-flow model with its 32-engine coefficient table (Eqs. 19–21, Table 12).

> **Citation format used below:** *Mokotoff et al. (FAST, JoA 2025), Eq./Table/Fig. N, p. X*. Page numbers are the printed PDF page (paper is 42 pp.).
>
> **Method note:** Equations and tables were extracted from the PDF text layer and each equation-, table-, and graph-bearing page was additionally rendered to an image and read visually to correct garbled fractions/integrals/superscripts. For the two quantitative line graphs (Fig. 7), the fitting-curve values are **computed exactly** from Eq. 19 with the Table 12 coefficients; the overlaid ICAO data points and the TSFC curves are **read visually from the plot** and are marked *(approx.)*. For the contour plots (Figs. 12–14), the plotted quantity cannot be sampled point-by-point, so the axis ranges, contour/colorbar levels, and corner/marker values are tabulated instead. All values marked *(approx.)* are graph reads, not published numbers.

---

## Figure inventory (what each figure is)

| Fig. | Page | Type | Data-bearing? | Tabulated below |
|------|------|------|---------------|-----------------|
| 1 | 7 | Design Structure Matrix — overall computational procedure | Diagram | — |
| 2 | 9 | DSM — initialization module | Diagram | — |
| 3 | 10 | DSM — aircraft sizing module | Diagram | — |
| 4 | 14 | DSM — mission analysis module | Diagram | — |
| 5 | 16 | Diagram — gas turbine sizing module | Diagram | — |
| 6 | 16 | Diagram — 2-spool turbofan architecture examples (geared/ungeared × boosted/unboosted) | Diagram | — |
| **7** | **21** | **Line plots — (a) fuel flow, (b) TSFC vs thrust %** | **Yes** | **§Graphs** |
| 8 | 24 | Photo/drawing — LM100J freighter | Image | — |
| 9 | 24 | Diagram — electrified (independent parallel hybrid) propulsion architecture | Diagram | — |
| 10 | 27 | Diagram — retrofit computational procedure | Diagram | — |
| **11** | **28** | **Stacked bar chart — notional weight breakdown** | **Yes** | **§Graphs** |
| **12** | **29** | **Contour — block fuel change, 10% thrust split (a) equal MTOW, (b) equal payload** | **Yes** | **§Graphs** |
| **13** | **30** | **Contour — block fuel change, 20% thrust split (a) equal MTOW, (b) equal payload** | **Yes** | **§Graphs** |
| **14** | **31** | **Contour — block fuel change, 30% thrust split (a) equal MTOW, (b) equal payload** | **Yes** | **§Graphs** |
| 15 | 33 | Code listing — example Aircraft Specification File | Code | — |
| 16 | 34 | Code listing — example Mission Profile Specification File | Code | — |

---

## Equations

### §IV.A — Airframe and Propulsion System Sizing (p. 11)

Wing area from wing loading — *Eq. 1, p. 11*:
```
S = MTOW / (W/S)                                                    (1)
```
Sea-level-static thrust (turbofan) — *Eq. 2, p. 11*:
```
T_SLS = (T/W) · MTOW                                                (2)
```
Sea-level-static power (turboprop) — *Eq. 3, p. 11*:
```
P_SLS = (P/W) · MTOW                                                (3)
```
Electric-motor weight — *Eq. 4, p. 11*:
```
W_EM = P_EM / (P/W)_EM                                              (4)
```
MTOW update / fixed-point sizing loop — *Eq. 5, p. 11*:
```
MTOW = W_Airframe + W_PropulsionSystem + W_Crew + W_Payload + W_EnergySources   (5)
```
- Airframe weight is a regression: turbofan → GPM of (wing area, SLS thrust, EIS year, MTOW); turboprop → linear regression on MTOW.
- Turbofan/turboprop engine weight → GPM of max SLS thrust/power. Loop iterates to convergence on MTOW (fixed-point iteration, ref. [27]).

### §IV.B — Energy Source Sizing (pp. 11–13)

Fuel weight (energy-based only; neglects tank weight) — *Eq. 6, p. 12*:
```
W_fuel = E_fuel / e_fuel                                            (6)
```
Parallel cells to hold final SOC ≥ 20% (⌈·⌉ = ceiling) — *Eq. 7, p. 12*:
```
N_par,SOC = ceil[ ( Q_batt + (ΔSOC)·Q_max·N_par ) / Q_max ]         (7)
```
Battery C-rate definition — *Eq. 8, p. 13*:
```
C-rate = Power Required / Total Energy                              (8)
```
Parallel cells to respect max C-rate (FAST max C-rate = 5) — *Eq. 9, p. 13*:
```
N_par,C-rate = ceil[ ( Maximum C-rate / Maximum Allowable C-rate )·N_par ]   (9)
```
Choose the more demanding requirement — *Eq. 10, p. 13*:
```
N_par,new = max( N_par,SOC , N_par,C-rate )                         (10)
```
Battery weight from cell count — *Eq. 11, p. 13*:
```
W_batt,new = 3600 · V_max · Q_max · N_ser · N_par,new / e_batt      (11)
```
Battery weight, energy-only (cell counts omitted from spec file) — *Eq. 12, p. 13*:
```
W_batt,new = E_batt / e_batt                                       (12)
```
- Default Li-ion cell: `Q_max` = 2.6 Ah, `V_max` = 3.6 V. Initial SOC assumed 100%. 20% lower SOC bound (permanent-damage limit, ref. [18]).

### §V.B — Battery (Dis)charge Dynamics (p. 15) — adapted from Tremblay & Dessaint [29]

Discharge voltage — *Eq. 13, p. 15*:
```
V_discharge = E0 − R·i − K·( Q / (Q − it) )·(it + i*) + A·exp(−B·it)         (13)
```
Charge voltage — *Eq. 14, p. 15*:
```
V_charge = E0 − R·i − K·( Q / (it − 0.1·Q) )·i* − K·( Q / (Q − it) )·it + A·exp(−B·it)   (14)
```
Variable definitions (Table 3, p. 15) are listed in §Tables. Only discharge is currently used in FAST.

### §VI.B — Thermodynamic Cycle / Turbine Work (pp. 18–19)

Turbine with known work requirement (positive electrical load = power boost) — *Eq. 15, p. 18*:
```
W_Turbine = ( W_Compressor − W_Electrical^← ) / η_Turbine          (15)
```
Free turbine maximizing power output (note leading minus so hot→cold integral is positive) — *Eq. 16, p. 18*:
```
W_Turbine = ( −ṁ_inlet · ∫_{T_t,inlet}^{T_t,exit} C_p,air(T) dT − W_Electrical^← ) / η_Turbine   (16)
```
where (unnumbered, p. 19):
```
T_t,exit = T_t,inlet · ( P_t,0 / P_t,4.1 )^((γ−1)/γ)
```
- `W_Electrical^←` : left-arrow = work done *on* the turbine is positive. Positive electrical load ⇒ reduces turbine demand (e.g. battery-boosted takeoff); negative ⇒ increases it (e.g. turboelectric driving a generator).

Turbine stage loading ψ (stage limit = 2, per Walsh & Fletcher [35]; #stages = ⌈ψ/2⌉) — *Eq. 17, p. 19*:
```
ψ = W_Compressor / ( η_Compressor · (ω·R_p)^2 )                    (17)
```
- `ω` = turbine rotational velocity, `R_p` = pitch-line radius.

Turbofan net thrust (ideal expansion to ambient) — *Eq. 18, p. 19*:
```
T = ṁ_9·u_9 + ṁ_19·u_19 − ṁ_0·u_0                                 (18)
```
- Station numbers per Table 4: 9 = core nozzle exit, 19 = bypass nozzle exit, 0 = freestream.

### §VI.C — Off-Design Turbofan Fuel-Flow / TSFC Model (p. 20) — after Sun et al. [38], ICAO databank [30]

ICAO databank third-degree curve fit; `x = T/T0` (thrust fraction), ṁ in kg/s — *Eq. 19, p. 20*:
```
ṁ_f,ICAO(T) = C_ff3·(T/T0)^3 + C_ff2·(T/T0)^2 + C_ff1·(T/T0)       (19)
```
Simplified linear cruise/SLS correlation factor — *Eq. 20, p. 20*:
```
C_ff,ch = ( TSFC_Cr − TSFC_SLS ) / h_Cr
        = ( TSFC_Cr − ṁ_f,ICAO(T0)/T0 ) / h_Cr                     (20)
```
Final fuel-flow rate with altitude term — *Eq. 21, p. 20*:
```
ṁ_f(T, h) = C_ff3·(T/T0)^3 + C_ff2·(T/T0)^2 + C_ff1·(T/T0) + C_ff,ch·T·h   (21)
```
- `T` = required thrust (kN), `T0` = max static thrust (kN), `h_Cr` = cruise altitude, TSFC in kg/(s·kN).
- ICAO power settings: 100% (takeoff), 85% (climb-out), 30% (approach), 7% (idle).
- For engines lacking a published `C_ff,ch`, FAST assumes the average `C_ff,ch = 6.8 × 10⁻⁷`.

### §VIII — Case Study Thrust Split (p. 24)

Outboard-propeller thrust split — *Eq. 22, p. 24*:
```
λ ≡ (Total Thrust Provided by the Outboard Propellers) / (Total Thrust Required)   (22)
```

### Appendix X.B — Energy-Based Segment Analysis (Algorithm 1, p. 35)

Full point-mass energy-based segment solver (uses engine lapse from Anderson [37]). Equations as printed:
```
Energy height:                 H_e = h + V∞² / (2g)
Turbofan thrust power:         T·V∞,turbofan       = ( T_SLS · ρ/ρ_SLS ) · V∞          (lapse exponent m = 1)
Turboprop/piston thrust power: T·V∞,turboprop/piston = P_SLS · ( ρ/ρ_SLS )^m           (m = 0 default)
Lift:                          L = m·g·cos(α)
Drag (constant L/D assumption): D = L / (L/D)
Specific excess power:         P_s = ( T·V∞ − D·V∞ ) / W

IF rate of climb provided:
    Time to climb:             Δt = Δh / (dh/dt)
    Max realizable accel:      (dV/dt)_max = ( P_s − dh/dt )·g / V∞
    IF any dV∞/dt > (dV∞/dt)_max: clamp to max, then
        V∞^(i) = V∞^(i−1) + (dV∞/dt)^(i−1) · Δt^(i−1)
ELSE:
    Δt = | ΔH_e / P_s |
    IF any dh/dt > (dh/dt)_max: clamp to max, then recompute Δt = Δh / (dh/dt)

Rate of climb:                 dh/dt   = Δh / Δt
Acceleration:                  dV∞/dt  = ΔV∞ / Δt
Aircraft-level power required: P_req   = D·V∞ + W·(dh/dt) + (1/2)·m·V∞·(dV∞/dt)
Energy per energy source:      E_req,ES = Σ_{i=1}^{n−1} ( P_req,ES )^(i) · Δt^(i)
```
- Inputs per segment: `h(1), V∞(1), h(n), V∞(n)`; altitudes/airspeeds linearly interpolated across `n` control points.
- Engine-lapse assumption: total thrust/power available = `(SLS value)·(ρ/ρ_SLS)^m`, exponent user-modifiable (1 for turbofan, 0 for turboprop/shaft).

---

## Tables

### Table 1 — Features and capabilities of current aircraft design tools (p. 2)
*Mokotoff et al., Table 1, p. 2*

| Capability | SUAVE | LUCAS | Aviary | FAST-OAD | JPAD Modeller | E-PASS |
|------------|:-----:|:-----:|:------:|:--------:|:-------------:|:------:|
| Open-Source | ✓ | ✗ | ✓ | ✓ | ✗ | ✗ |
| Requires Component/Subsystem Definitions | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Interface with Optimization Tools | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Evaluate any Propulsion System | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Rapid (< 1-minute) Low-Fidelity Analysis | ✗ | ✗ | ✗ | ✓ | ✓ | ✗ |

### Table 2 — Assumptions made in FAST's segment analyses (p. 15)
*Mokotoff et al., Table 2, p. 15*

| Assumption | Takeoff | Climb | Cruise | Descent | Landing |
|------------|:-------:|:-----:|:------:|:-------:|:-------:|
| Fixed Time | ✓ | ✗ | ✗ | ✗ | ✓ |
| Constant Acceleration | ✓ | ✗ | ✗ | ✗ | ✓ |
| No ISA Temperature Deviation | ✓ | ✓ | ✓ | ✓ | ✓ |
| Constant L/D | ✗ | ✓ | ✓ | ✓ | ✗ |
| Linearly Spaced Altitudes and Airspeeds | ✓ | ✓ | ✓ | ✓ | ✓ |
| Maximum Power | ✓ | ✓/✗ | ✗ | ✗ | ✗ |
| Reverse Thrust | ✗ | ✗ | ✗ | ✗ | ✓ |

### Table 3 — Variables used in the battery (dis)charging model (p. 15)
*Mokotoff et al., Table 3, p. 15*

| Variable | Description |
|----------|-------------|
| V | Battery voltage as a function of time (V) |
| E0 | Battery constant voltage (V) |
| R | Battery internal resistance (Ω) |
| it | Battery capacity as a function of time (Ah) |
| K | Polarization constant (Ω) |
| Q | Maximum battery capacity (Ah) |
| i* | Filtered current (A) |
| A | Battery's exponential zone amplitude (V) |
| B | Battery's time constant (Ah⁻¹) |

### Table 4 — FAST's engine station numbering convention (p. 18)
*Mokotoff et al., Table 4, p. 18*

| Station Number | After | Before |
|----------------|-------|--------|
| 0 or a | Streamtube | Inlet |
| 1 | Inlet | Fan |
| 2 | Fan | Splitter |
| 2.1 | Splitter (Core) | LPC |
| 2.5 | LPC | IPC |
| 2.6 | IPC | HPC |
| 3 | HPC | Bleed Air Extraction |
| 3.1 | Bleed Air Extraction | Combustion Chamber Diffuser |
| 3.2 | Combustion Chamber Diffuser | Combustion |
| 3.9 | Combustion | Turbine Diffuser |
| 4 | Turbine Diffuser | Cooling Air |
| 4.1 | Cooling Air | HPT |
| 5 | HPT | IPT |
| 5.5 | IPT | LPT |
| 6 | LPT | Core Nozzle |
| 9 | Core Nozzle | Core Exhaust |
| 13 | Splitter (Bypass) | Bypass Nozzle |
| 19 | Bypass Nozzle | Bypass Exhaust |

### Table 5 — Validated aircraft models using FAST's off-design engine analysis (p. 22)
*Mokotoff et al., Table 5, p. 22*

| Parameter | ERJ175LR — FAST | ERJ175LR — Literature | Diff | A320neo (WV 054) — FAST | A320neo — Literature | Diff |
|-----------|----------------:|----------------------:|-----:|------------------------:|---------------------:|-----:|
| MTOW (kg) | 38,637 | 38,790 | −0.39% | 79,333 | 79,000 | +0.42% |
| OEW (kg) | 21,545 | 21,500 | +0.21% | 44,581 | 44,300 | +0.63% |
| Block Fuel (kg) | 9,397 | 9,428 | −0.33% | 18,856 | 18,729** | +0.68% |
| Cruise TSFC (lb/lbf/hr) | 0.692 | 0.680 | +1.76% | 0.514 | 0.51 | +0.78% |

** A320neo literature block fuel ranges 18,729–21,005 kg depending on # fuel tanks, pax capacity, weight variant, etc. FAST input here reflects an A320neo *without* the additional center fuel tank.

### Table 6 — Key performance and design parameters for validating FAST (p. 22)
*Mokotoff et al., Table 6, p. 22*

| Parameter | Airbus A320Neo | Embraer E175LR |
|-----------|---------------:|---------------:|
| Passengers | 160 | 78 |
| Class | Turbofan | Turbofan |
| Entry into Service | 2016 | 2005 |
| Design Range [nmi] | 2,600 | 2,150 |
| Cruise Speed [Mach] | 0.82 | 0.78 |
| Cruise Altitude [ft] | 35,000 | 35,000 |
| Takeoff Speed [kts] | 135 | 135 |
| Maximum Rate of Climb [ft/min] | 2,250 | 2,250 |
| Climb/Descent L/D | 16.00 | 10.98 |
| Cruise L/D | 18.23 | 15.20 |
| Wing Loading [lbm/ft²] | 127.9 | 109.3 |
| MTOW [lbm] | 174,170 | 85,517 |
| Block Fuel [lbm] | 41,890 | 20,785 |
| Operational Empty Weight [lbm] | 93,917 | 47,399 |
| Engine | LEAP 1A-26 | CF34-8E5 |
| Thrust-Weight Ratio | 0.3287 | 0.3393 |
| Cruise SFC [lbm/(lbf-hr)] | 0.510 | 0.680 |

### Table 7 — Conventional aircraft validation in FAST (p. 23)
*Mokotoff et al., Table 7, p. 23.* (% = error vs. Table 6 literature.)

| Weight | A320Neo Uncalibrated | A320Neo Calibrated | ERJ175LR Uncalibrated | ERJ175LR Calibrated |
|--------|---------------------:|-------------------:|----------------------:|--------------------:|
| MTOW [lbm] | 165,028 (−5.25%) | 170,927 (−1.86%) | 79,455 (−7.09%) | 85,179 (−0.40%) |
| Block Fuel [lbm] | 38,112 (−9.02%) | 41,896 (+0.01%) | 19,580 (−5.80%) | 20,717 (−0.33%) |
| OEW [lbm] | 91,872 (−2.18%) | 93,988 (+0.08%) | 42,912 (−9.47%) | 47,499 (+0.21%) |
| Cruise SFC [lbm/(lbf-hr)] | 0.514 (+0.78%) | 0.551 (+8.04%) | 0.697 (+2.50%) | 0.670 (−1.47%) |
| Cruise Thrust [kN] | 20.02 | 20.51 | 11.29 | 11.99 |

### Table 8 — LM100J aircraft specification and performance parameter estimates (p. 25)
*Mokotoff et al., Table 8, p. 25*

| Parameter | Units | Value |
|-----------|-------|------:|
| Design Range | nmi | 2,390 |
| Payload | lbm | 40,000 |
| Power-Weight Ratio | W/kg | 183.4 |
| Wing Loading | lbm/ft² | 123.7 |
| MTOW | lbm | 164,000 |
| OEW | lbm | 80,350 |
| Block Fuel | lbm | 38,000 |
| Cruise Speed | Mach | 0.59 |

Reserve mission: 45-min loiter at 10,000 ft and 300 KTAS. Design cruise 25,000 ft, Mach 0.59.

### Table 9 — Parameters tuned to calibrate the conventional freighter model (p. 26)
*Mokotoff et al., Table 9, p. 26.* (All non-engine calibration factors constrained within 10% of unity.)

| Parameter | Value |
|-----------|------:|
| Airframe Weight Scale Factor | 0.991 |
| Engine Fuel Flow Scale Factor | 1.037 |
| Cruise L/D | 14.850 |
| Climb/Descent L/D | 12.850 |
| Total Burner Temperature (K) | 1,200 |
| Inlet Polytropic Efficiency | 0.990 |
| Diffuser Polytropic Efficiency | 0.990 |
| Compressor Polytropic Efficiency | 0.860 |
| Combustor Polytropic Efficiency | 0.980 |
| Turbine Polytropic Efficiency | 0.860 |
| Nozzle Polytropic Efficiency | 0.985 |

### Table 10 — Comparison between the notional LM100J and the literature (p. 26)
*Mokotoff et al., Table 10, p. 26*

| Weight | Notional LM100J | Literature | Percent Error |
|--------|----------------:|-----------:|--------------:|
| MTOW (lbm) | 159,953 | 164,000 | −2.470% |
| OEW (lbm) | 80,333 | 80,350 | −0.021% |
| Block Fuel (lbm) | 38,001 | 38,000 | +0.003% |

### Table 11 — Design space for retrofit study (p. 27)
*Mokotoff et al., Table 11, p. 27.* (Payload removed and battery specific energy continuous; thrust split discrete in 10% increments.)

| Parameter | Units | Lower Bound | Upper Bound |
|-----------|-------|------------:|------------:|
| Payload Removed | % | 0 | 100 |
| Thrust Split | % | 10 | 30 |
| Battery Specific Energy | kWh/kg | 0.35 | 1.55 |

### Table 12 — Off-design turbofan engine modeling coefficients and cruise TSFC (p. 36)
*Mokotoff et al., Table 12, p. 36.* Coefficients feed Eqs. 19–21. Units: `C_ff3`, `C_ff2`, `C_ff1` in kg/s; `C_ff,ch` in kg/(kN·s·m). TSFC_cr printed with the same unit bracket kg/(kN·s·m) — conventionally TSFC is kg/(kN·s); the "·m" appears carried over from the adjacent column, so treat TSFC_cr values as kg/(kN·s). All 32 engines:

| Engine | C_ff3 (kg/s) | C_ff2 (kg/s) | C_ff1 (kg/s) | C_ff,ch (kg/(kN·s·m)) | TSFC_cr (kg/(kN·s)) |
|--------|-------------:|-------------:|-------------:|----------------------:|--------------------:|
| CF34-8E5 | 0.2992 | −0.3464 | 0.7012 | 7.8175 × 10⁻⁷ | 1.93 × 10⁻² |
| LEAP1A26 | 0.3940 | −0.4938 | 0.9638 | 6.8249 × 10⁻⁷ | 1.44 × 10⁻² |
| LEAP1B25 | 0.4033 | −0.4374 | 0.9833 | 6.6083 × 10⁻⁷ | 1.50 × 10⁻² |
| Trent 772 | 1.5189 | −1.5650 | 3.2532 | 5.5180 × 10⁻⁷ | 1.60 × 10⁻² |
| CFM56-7B20 | 0.4248 | −0.6031 | 1.0944 | 7.4318 × 10⁻⁷ | 1.79 × 10⁻² |
| CFM56-7B24 | 0.4708 | −0.5909 | 1.2262 | 7.0206 × 10⁻⁷ | 1.78 × 10⁻² |
| CFM56-5C4 | 0.3928 | −0.3230 | 1.3895 | 5.4289 × 10⁻⁷ | 1.54 × 10⁻² |
| CFM56-5C3 | 0.3720 | −0.3372 | 1.3415 | 5.5485 × 10⁻⁷ | 1.54 × 10⁻² |
| CFM56-5C2 | 0.4172 | −0.4225 | 1.3165 | 5.6145 × 10⁻⁷ | 1.54 × 10⁻² |
| CFM56-5B4 | 0.4107 | −0.4658 | 1.2238 | 5.1770 × 10⁻⁷ | 1.54 × 10⁻² |
| CFM56-5B2 | 0.5168 | −0.4719 | 1.3839 | 4.7575 × 10⁻⁷ | 1.54 × 10⁻² |
| CFM56-5B1 | 0.4273 | −0.3966 | 1.3314 | 6.2608 × 10⁻⁷ | 1.69 × 10⁻² |
| CFM56-5A1 | 0.4370 | −0.5006 | 1.1176 | 6.9397 × 10⁻⁷ | 1.69 × 10⁻² |
| CFM56-3B2 | 0.5239 | −0.7323 | 1.2685 | 7.6016 × 10⁻⁷ | 1.89 × 10⁻² |
| CFM56-3B1 | 0.4970 | −0.7408 | 1.1938 | 7.7482 × 10⁻⁷ | 1.89 × 10⁻² |
| TFE731-2-2B | 0.1099 | −0.1797 | 0.2755 | 8.1211 × 10⁻⁷ | 2.31 × 10⁻² |
| TFE731-3 | 0.1594 | −0.2396 | 0.3059 | 7.8088 × 10⁻⁷ | 2.32 × 10⁻² |
| CF6-6D | 0.6881 | −0.8084 | 1.8619 | 7.8130 × 10⁻⁷ | 1.83 × 10⁻² |
| CF6-50A | 0.6427 | −0.7307 | 2.2570 | 7.9211 × 10⁻⁷ | 1.85 × 10⁻² |
| CF6-50C | 0.5913 | −0.5759 | 2.2664 | 7.9039 × 10⁻⁷ | 1.86 × 10⁻² |
| CF6-50E | 0.5826 | −0.5468 | 2.3256 | 7.8372 × 10⁻⁷ | 1.86 × 10⁻² |
| CF6-80A | 0.1966 | −0.1296 | 2.0786 | 6.9091 × 10⁻⁷ | 1.76 × 10⁻² |
| CF6-80C2A1 | 0.8280 | −0.7522 | 2.3288 | 6.5360 × 10⁻⁷ | 1.63 × 10⁻² |
| GE90-85B | 1.3008 | −1.3348 | 3.2336 | 6.2196 × 10⁻⁷ | 1.47 × 10⁻² |
| JT8D-7 | 0.7009 | −0.9494 | 1.2431 | 7.1991 × 10⁻⁷ | 2.25 × 10⁻² |
| JT8D-9 | 0.7856 | −1.0425 | 1.3023 | 7.0552 × 10⁻⁷ | 2.27 × 10⁻² |
| JT8D-17 | 1.0575 | −1.3668 | 1.5596 | 5.5773 × 10⁻⁷ | 2.27 × 10⁻² |
| JT9D-7 | 0.4007 | −0.5522 | 2.2412 | 6.7839 × 10⁻⁷ | 1.76 × 10⁻² |
| JT9D-20 | 0.2833 | −0.4244 | 2.2468 | 6.8476 × 10⁻⁷ | 1.77 × 10⁻² |
| PW2037 | 0.3800 | −0.2765 | 1.4395 | 7.8166 × 10⁻⁷ | 1.65 × 10⁻² |
| RB211-22B | 1.4623 | −2.0834 | 2.5004 | 7.0212 × 10⁻⁷ | 1.78 × 10⁻² |
| Tay 611-8C | 0.6785 | −1.0341 | 1.1006 | 6.1175 × 10⁻⁷ | 2.01 × 10⁻² |

### Table 13 — Notional A320Neo design mission profile (p. 37)
*Mokotoff et al., Table 13, p. 37*

| Mission Target | Segment | Init Alt (ft) | Final Alt (ft) | Init Airspeed | Final Airspeed |
|----------------|---------|--------------:|---------------:|---------------|----------------|
| First Cruise – 1,133 nmi | Takeoff | 0 | 0 | 0 KTAS | Mach 0.30 |
| | Initial Climb | 0 | 10,000 | Mach 0.30 | 250 KTAS |
| | Main Climb | 10,000 | 35,000 | 250 KTAS | Mach 0.78 |
| | Cruise | 35,000 | 35,000 | Mach 0.78 | Mach 0.78 |
| Second Cruise – 1,133 nmi | Climb | 35,000 | 37,000 | Mach 0.78 | Mach 0.78 |
| | Cruise | 37,000 | 37,000 | Mach 0.78 | Mach 0.78 |
| Third Cruise – 1,133 nmi | Climb | 37,000 | 39,000 | Mach 0.78 | Mach 0.78 |
| | Cruise | 39,000 | 39,000 | Mach 0.78 | Mach 0.78 |
| | Descent | 39,000 | 1,500 | Mach 0.78 | Mach 0.30 |
| Divert – 200 nmi | Climb | 1,500 | 15,000 | Mach 0.30 | Mach 0.30 |
| | Cruise | 15,000 | 15,000 | Mach 0.30 | Mach 0.30 |
| | Descent | 15,000 | 1,500 | Mach 0.30 | Mach 0.30 |
| Loiter – 30 minutes | Cruise | 1,500 | 1,500 | Mach 0.30 | Mach 0.30 |
| | Descent | 1,500 | 0 | Mach 0.30 | Mach 0.30 |
| | Landing | 0 | 0 | Mach 0.30 | 0 KTAS |

### Table 14 — Notional ERJ175LR design mission profile (p. 38)
*Mokotoff et al., Table 14, p. 38*

| Mission Target | Segment | Init Alt (ft) | Final Alt (ft) | Init Airspeed | Final Airspeed |
|----------------|---------|--------------:|---------------:|---------------|----------------|
| Design Mission – 2,150 nmi | Takeoff | 0 | 0 | 0 KTAS | 135 KTAS |
| | Initial Climb | 0 | 3,000 | 135 KTAS | 200 KEAS |
| | Main Climb | 3,000 | 35,000 | 200 KEAS | 200 KEAS |
| | Accelerate | 35,000 | 35,000 | 200 KEAS | Mach 0.78 |
| | Cruise | 35,000 | 35,000 | Mach 0.78 | Mach 0.78 |
| | Decelerate | 35,000 | 35,000 | Mach 0.78 | 210 KEAS |
| | Main Descent | 35,000 | 3,000 | 210 KEAS | 210 KEAS |
| | Final Descent | 3,000 | 1,500 | 210 KEAS | 162 KTAS |
| Divert – 100 nmi | Initial Climb | 1,500 | 3,000 | 162 KTAS | 200 KEAS |
| | Main Climb | 3,000 | 9,000 | 200 KEAS | 200 KEAS |
| | Final Climb | 9,000 | 10,000 | 200 KEAS | 250 KTAS |
| | Divert | 10,000 | 10,000 | 250 KTAS | 250 KTAS |
| Loiter – 45 min | Loiter | 10,000 | 10,000 | 250 KTAS | 250 KTAS |
| | Initial Descent | 10,000 | 9,000 | 250 KTAS | 200 KEAS |
| | Main Descent | 9,000 | 3,000 | 200 KEAS | 200 KEAS |
| | Final Descent | 3,000 | 0 | 200 KEAS | 162 KTAS |
| | Landing | 0 | 0 | 162 KTAS | 0 KTAS |

### Table 15 — Calibration factors for notional aircraft models (p. 38)
*Mokotoff et al., Table 15, p. 38*

| Calibration Factor | Notional A320Neo | Notional ERJ175LR |
|--------------------|-----------------:|------------------:|
| Airframe Weight Factor | 0.993 | 1.018 |
| Fuel Flow Factor | 1.092 | 1.029 |
| Climb Lift-to-Drag Ratio | 1.000 | 1.002 |
| Cruise Lift-to-Drag Ratio | 1.000 | 1.000 |

---

## Graphs (tabulated)

### Fig. 7 — Curve fit validation against the ICAO databank (p. 21)
*Mokotoff et al., Fig. 7, p. 21.* Two panels vs. x-axis "Thrust/Max Thrust at SLS (%)" at the four ICAO settings (7, 30, 85, 100%). Engines: CF34-8E5 (ERJ175LR), LEAP1A26 (A320neo), LEAP1B25 (737 MAX 8), Trent 772 (A330).

**Fig. 7(a) — Fuel flow (kg/s).** *Fitting* values below are computed **exactly** from Eq. 19 with Table 12 coefficients (`ṁ = C_ff3·x³ + C_ff2·x² + C_ff1·x`, `x = %/100`). ICAO markers overlie the fit closely at 30/85/100% and lie **above** the fit at 7% idle (the paper's noted idle discrepancy).

| Thrust setting | CF34-8E5 fit | LEAP1A26 fit | LEAP1B25 fit | Trent 772 fit |
|---------------:|-------------:|-------------:|-------------:|--------------:|
| 7% (idle) | 0.0475 | 0.0652 | 0.0668 | 0.2206 |
| 30% (approach) | 0.1873 | 0.2553 | 0.2665 | 0.8761 |
| 85% (climb-out) | 0.5295 | 0.7044 | 0.7675 | 2.5673 |
| 100% (takeoff) | 0.6540 | 0.8640 | 0.9492 | 3.2071 |

ICAO data points *(approx., read from plot)* — deviate from the fit mainly at idle:

| Thrust setting | CF34-8E5 | LEAP1A26 | LEAP1B25 | Trent 772 |
|---------------:|---------:|---------:|---------:|----------:|
| 7% (idle) | ~0.09 | ~0.10 | ~0.10 | ~0.27 |
| 30% | ~0.19 | ~0.26 | ~0.27 | ~0.87 |
| 85% | ~0.53 | ~0.70 | ~0.77 | ~2.57 |
| 100% | ~0.65 | ~0.86 | ~0.95 | ~3.21 |

**Fig. 7(b) — TSFC (kg/(s·kN))** *(all values approx., read from plot).* Each fitting curve is U-shaped (min near 45–60% thrust); ICAO idle (7%) points sit well above the fit.

| Thrust setting | CF34-8E5 | LEAP1A26 | LEAP1B25 | Trent 772 |
|---------------:|---------:|---------:|---------:|----------:|
| 7% ICAO (idle) | ~0.0153 | ~0.0108 | ~0.0113 | ~0.0126 |
| ~0% fit intercept | ~0.0117 | ~0.0080 | ~0.0083 | ~0.0103 |
| curve minimum | ~0.0100 @ ~55% | ~0.0069 @ ~55% | ~0.0073 @ ~55% | ~0.0090 @ ~45% |
| 100% (takeoff) | ~0.0110 | ~0.0072 | ~0.0080 | ~0.0101 |

- y-axis range 0.006–0.016; ordering high→low across most of the range: CF34-8E5 > Trent 772 > LEAP1B25 > LEAP1A26.

### Fig. 11 — Notional weight breakdown of aircraft compared in the retrofit study (p. 28)
*Mokotoff et al., Fig. 11, p. 28.* Stacked bars, % of gross weight; segments bottom→top: OEW, Fuel, Payload, Battery+EM.

| Component | Sized Conventional | Conventional, Reduced Payload | Electrified Retrofit |
|-----------|-------------------:|------------------------------:|---------------------:|
| OEW | 40% | 40% | 40% |
| Fuel | 30% | 15% | 25% |
| Payload | 30% | 20% | 20% |
| Battery + EM | — | — | 15% |
| **Column total** | **100%** | **75%** | **100%** |

- "Equal MTOW" comparison = left bar (Sized Conventional, 100%) vs. right bar (Electrified Retrofit, 100%).
- "Equal Payload" comparison = center bar (Conventional, Reduced Payload — flies at smaller TOGW, 75%) vs. right bar (Electrified Retrofit).

### Figs. 12–14 — Block fuel change contours, conventional vs. electrified freighter (pp. 29–31)
*Mokotoff et al., Figs. 12–14, pp. 29–31.* Filled contour plots. Common axes: **x = Battery Specific Energy, 0.35–1.55 kWh/kg**; **y = Payload Decrease, ~5–100%** (axis bounds = Table 11 bounds). Plotted quantity = **% change in block fuel** of the electrified retrofit relative to the conventional baseline (negative = fuel *saved*). Panel (a) "Equal MTOW", panel (b) "Equal payload". Contour/colorbar levels and gradient directions below (contour surfaces are not point-sampleable).

| Figure | Thrust split | Panel | Colorbar range | Contour interval | Where most negative (max saving) | Where least favorable | Special marker |
|--------|:-----------:|-------|---------------:|-----------------:|----------------------------------|-----------------------|----------------|
| 12(a) | 10% | Equal MTOW | 0 → −8 | 1 | upper-right (high batt. spec. energy + high payload removed) → ≈ −8 | lower-left corner ≈ 0 (dark red) | — |
| 12(b) | 10% | Equal payload | 0 → 25 | 5 | lower-right (high batt. spec. energy) small values | top (high payload removed) ≈ 20–25 | white dashed line = boundary where contours turn horizontal |
| 13(a) | 20% | Equal MTOW | 0 → −16 | 2 | upper-right ≈ −16 | lower-left ≈ 0 | — |
| 13(b) | 20% | Equal payload | −5 → 25 | 5 | lower-right small/negative | top ≈ 20–25 | white **dot** ≈ (1.25 kWh/kg, ~49% payload decrease) = critical point (slope sign change) |
| 14(a) | 30% | Equal MTOW | 0 → −25 | 5 | upper-right ≈ −25 | lower-left ≈ 0 | — |
| 14(b) | 30% | Equal payload | −5 → 25 | 5 | lower-right / mid-right negative pocket | upper-left ≈ 20–25 | white **dot** ≈ (1.40 kWh/kg, ~65% payload decrease) = critical point |

Qualitative reads (from paper text + plots):
- **Equal MTOW (a-panels): electrifying always saves fuel.** For small payload removed, ~1–5% saving regardless of battery spec. energy; larger payload removed gives ~5–9% (10% split), up to ~16% (20% split), ~25% (30% split). Contours are steeper at low battery spec. energy → improving battery tech saves more fuel than removing payload there; contours flatten once battery matures (~1.0–1.5 kWh/kg).
- **Equal payload (b-panels): usually *more* fuel burned** (electrification weight penalty raises TOGW). Horizontal contours at high battery spec. energy ⇒ battery is partly "dead weight" (not fully depleted → thrust split too low). Critical battery spec. energy (white dots) at ≈ 1.25 kWh/kg (20% split) and ≈ 1.40 kWh/kg (30% split): beyond it, payload can be added back while holding block-fuel change constant.

---

## Notes for the project

- **Point-performance sizing (Eqs. 1–5)** mirror this repo's constraint→sizing flow: `S = MTOW/(W/S)`, `T_SLS = (T/W)·MTOW`. FAST holds `(T/W, W/S)` **fixed** during sizing — it does *not* draw a constraint diagram (the repo's `src/constraints/` work is FAST's acknowledged missing piece; see p. 10). Cross-check against Mattingly/Raymer constraint forms already extracted in `mattingly_data.md` / `raymer_data.md`.
- **Energy-based segment analysis (Algorithm 1)** is a clean, propulsion-agnostic alternative to Breguet-style mission legs: works in energy height `H_e = h + V∞²/2g`, specific excess power `P_s`, and `Δt = |ΔH_e/P_s|`. Note the **constant-L/D** assumption per segment (Table 2) — climb/descent accuracy is the documented weak spot (Table 7 underestimates MTOW/block fuel).
- **Off-design turbofan fuel flow (Eqs. 19–21 + Table 12)** is directly reusable: a 3rd-order polynomial in thrust fraction `T/T0` plus a linear altitude correction. 32 engines tabulated (incl. CF34-8E5, LEAP-1A26/1B25, CFM56 family, CF6 family, JT8D/JT9D, GE90, Trent 772). Default `C_ff,ch = 6.8×10⁻⁷` when unknown. **Unit caveat:** TSFC_cr column prints kg/(kN·s·m) but is physically kg/(kN·s).
- **Not F-16 relevant:** validation aircraft are transport turbofans/turboprops (A320neo, ERJ175LR, LM100J). Useful as a *methodology* reference (energy-based mission, regression-based weights, matrix propulsion framework of Cinar et al. [24]), not as F-16 ground-truth data.
- **Calibration philosophy (Tables 7, 9, 15):** FAST tunes exactly four factors — airframe-weight scale, fuel-flow scale, cruise L/D, climb/descent L/D — kept within 10% of unity, to match MTOW/block-fuel/OEW. Same spirit as this repo's calibration-vs-spec-input distinction in PLAN.md.
