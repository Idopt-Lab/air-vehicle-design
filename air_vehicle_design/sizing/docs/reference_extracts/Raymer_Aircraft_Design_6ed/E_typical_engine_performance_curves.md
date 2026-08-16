# Appendix E — Typical Engine Performance Curves

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Appendix E
"Typical Engine Performance Curves," printed pp. 987–994.

Performance curves for three representative (not-identical-to-production) engines: an
afterburning turbofan (E.1), a high-bypass-ratio turbofan (E.2), and a turboprop (E.3). Generated
with Mattingly/Heiser/Daley's ONX/OFFX engine-cycle programs (companions to the AIAA Education
Series text *Aircraft Engine Design*). Engines may be scaled with the scaling laws of Raymer Ch.
10. All altitudes in feet; all charts plot uninstalled performance. Every figure below was rendered
to an image and read by eye — all numeric curve values are marked "(read from plot)" and are
approximate; the printed axis labels and table values are exact.

Common installation assumptions across all three engines: Mil. Spec. MIL-E-5008B-style inlet
total-pressure recovery ratio ≈ 0.97; a shaft-power extraction to drive generators/accessories at
all conditions; and a fixed high-pressure bleed-air flow rate. Each engine's specific values are
given in its table below.

---

## E.1 Afterburning Turbofan

### Table E.1 — Afterburning Turbofan Characteristics

*[Raymer, Table E.1, p. 987]*

| Parameter | Value |
|---|---|
| Sea-level static thrust | 30,000 lb {133 kN} |
| Sea-level static TSFC | 1.64 1/hr {46 mg/N·s} |
| Sea-level static airflow | 246 lbm/s {112 kg/s} |
| Bare-engine weight | 3,000 lb {1361 kg} |
| Engine length (incl. axisymmetric nozzle) | 160 in. {407 cm} |
| Maximum diameter | 44 in. {112 cm} |
| Fan-face diameter | 40 in. {102 cm} |
| Overall pressure ratio | 22 |
| Fan pressure ratio | 4.3 |
| Bypass ratio | 0.41 |

Installation assumptions: MIL-E-5008B inlet pressure recovery, inlet duct total pressure ratio
0.97; power extraction 320 kW; high-pressure bleed airflow 1.7 lb/s.

### Max Power Thrust vs. Mach Number

*[Raymer, Fig. E.1 (Max power thrust), p. 988]* — uninstalled thrust (lb), (read from plot):

| Mach | SL | 20k ft | 40k ft | 50k ft |
|---|---|---|---|---|
| 0.0 | 30,000 | 16,000 | 8,000 | 4,000 |
| 0.5 | 29,000 | 16,500 | 8,500 | 4,200 |
| 1.0 | 33,000 | 20,000 | 10,500 | 5,500 |
| 1.5 | 39,000 | 26,000 | 13,500 | 7,000 |
| 2.0 | 45,000 | 32,000 | 17,000 | 8,500 |
| 2.5 | 47,500 | 35,000 | 19,000 | 9,500 |
| 3.0 | 48,000 | 34,000 | 18,500 | 9,500 |

### Military Power Thrust vs. Mach Number

*[Raymer, Fig. E.1 (Military power thrust), p. 988]* — uninstalled thrust (lb), (read from plot):

| Mach | SL | 20k ft | 40k ft | 50k ft |
|---|---|---|---|---|
| 0.0 | 20,500 | 9,500 | 3,000 | 2,500 |
| 0.5 | 19,500 | 10,000 | 4,000 | 3,000 |
| 1.0 | 20,000 | 12,500 | 6,000 | 3,800 |
| 1.5 | 21,500 | 14,000 | 7,500 | 4,800 |
| 2.0 | 19,000 | 11,500 | 6,500 | 4,000 |
| 2.5 | 12,500 | 7,500 | 4,000 | 2,500 |
| 2.8 | 8,500 | 5,000 | 2,500 | 1,800 |

Military-power thrust peaks near M ≈ 1.4–1.6 at each altitude, then falls off sharply above M ≈ 2
(engine "thrust pinch" region).

### Max Power TSFC vs. Mach Number

*[Raymer, Fig. E.1 (Max power TSFC), p. 988]* — TSFC (1/hr), (read from plot):

| Mach | SL | 20k ft | 40k–50k ft |
|---|---|---|---|
| 0.0 | 1.65 | 1.70 | 1.72 |
| 0.5 | 1.82 | 1.80 | 1.78 |
| 1.0 | 1.80 | 1.75 | 1.73 |
| 1.5 | 2.00 | 1.85 | 1.80 |
| 2.0 | 2.20 | 2.00 | 1.92 |
| 2.5 | 2.35 | 2.10 | 2.00 |

### Military Power TSFC vs. Mach Number

*[Raymer, Fig. E.1 (Military power TSFC), p. 988]* — TSFC (1/hr), (read from plot), curves for
SL–50k collapse to a fairly narrow band:

| Mach | All altitudes (band) |
|---|---|
| 0.0 | 0.82–0.85 |
| 0.5 | 0.90–0.95 |
| 1.0 | 1.05–1.10 |
| 1.5 | 1.20–1.30 |
| 2.0 | 1.35–1.45 |
| 2.5 | 1.45–1.55 |
| 2.8 | 1.50–1.80 (curves fan out at high Mach, SL/10k highest) |

### Engine Required Airflow vs. Mach Number

*[Raymer, Fig. E.1 (Engine required airflow), p. 988]* — airflow (lbm/s), (read from plot):

| Mach | SL | 20k ft | 40k ft | 50k ft |
|---|---|---|---|---|
| 0.0 | 250 | 130 | 60 | 40 |
| 1.0 | 330 | 190 | 90 | 55 |
| 2.0 | 470 | 280 | 150 | 90 |
| 3.0 | 590 | 380 | 220 | 130 |

### Partial-Throttle TSFC at Sea Level

*[Raymer, Fig. E.1 (Partial throttle – sea level), p. 988]* — TSFC (1/hr) vs. uninstalled thrust
(lb), families of curves at fixed Mach (0, 0.2, 0.4, 0.6, 0.8, 0.9, 1.0); each curve falls steeply
at low thrust then flattens toward an asymptote as thrust approaches the full-throttle value at
that Mach, (read from plot):

| Uninstalled thrust (lb) | Mach 0 | Mach 0.6 | Mach 1.0 |
|---|---|---|---|
| 3,000 | 1.00 | 1.35 | 1.75 |
| 5,000 | 0.90 | 1.15 | 1.45 |
| 10,000 | 0.85 | 1.05 | 1.25 |
| 15,000 | — | 1.00 | 1.15 |
| 20,000 | — | 0.98 | 1.05 |

Additional per-altitude partial-throttle-thrust-ratio panels appear at 10k, 20k, 30k, and 40k ft
[Raymer, Fig. E.1, pp. 989–990] with the same qualitative shape (installed/uninstalled thrust
ratio rising with Mach, falling with increasing partial-throttle setting); not further digitized
beyond the sea-level panel above, as they repeat the same family shape at each altitude.

---

## E.2 High-Bypass Turbofan

### Table E.2 — High-Bypass Turbofan Characteristics

*[Raymer, Table E.2, p. 991]*

| Parameter | Value |
|---|---|
| Sea-level static thrust | 50,000 lb {222 kN} |
| Sea-level static TSFC | 0.40 1/hr {11.3 mg/N·s} |
| Sea-level static airflow | 1,680 lb/s {762 kg/s} |
| Bare-engine weight | 7,700 lb {3493 kg} |
| Engine length | 150 in. {381 cm} |
| Maximum engine diameter | 100 in. {254 cm} |
| Overall pressure ratio | 30 |
| Fan pressure ratio | 1.6 |
| Bypass ratio | 8.0 [verify p. 991 — table cell renders as "80"; a bypass ratio of 8.0 is consistent with a high-bypass turbofan and with typical published values for this Raymer example engine, so 80 is read here as a lost decimal point] |

Installation assumptions: inlet total pressure ratio 0.97; power extraction 650 kW; high-pressure
bleed airflow 2.0 lb/s; maximum-rated performance plotted with dashed lines (vs. solid for
continuous rating).

### Full-Throttle Thrust vs. Mach Number

*[Raymer, Fig. E.2 (Full throttle thrust), p. 991]* — uninstalled thrust (lb), continuous rating,
(read from plot):

| Mach | SL | 10k ft | 20k ft | 36k ft | 45k ft |
|---|---|---|---|---|---|
| 0.0 | 41,000 | 34,000 | 23,000 | 14,500 | 7,500 |
| 0.2 | 33,000 | 27,500 | 19,500 | 12,500 | 6,800 |
| 0.4 | 28,000 | 24,000 | 17,500 | 11,500 | 6,300 |
| 0.6 | 25,000 | 21,500 | 16,000 | 10,800 | 6,000 |
| 0.8 | 23,000 | 20,000 | 15,000 | 10,200 | 5,700 |
| 1.0 | 26,000 | 21,000 | 15,500 | 10,500 | 5,800 |

### Full-Throttle TSFC vs. Mach Number

*[Raymer, Fig. E.2 (Full throttle TSFC), p. 991]* — TSFC (1/hr), (read from plot, curves for
SL–45k are tightly clustered):

| Mach | All altitudes (band) |
|---|---|
| 0.0 | 0.35–0.40 |
| 0.2 | 0.42–0.46 |
| 0.4 | 0.50–0.55 |
| 0.6 | 0.60–0.65 |
| 0.8 | 0.72–0.78 |
| 1.0 | 0.85–0.92 |

### Engine Required Airflow vs. Mach Number

*[Raymer, Fig. E.2 (Engine required airflow), p. 991]* — airflow (lbm/s), (read from plot):

| Mach | SL | 10k ft | 30k ft | 45k ft |
|---|---|---|---|---|
| 0.0 | 1,700 | 1,250 | 550 | 280 |
| 0.5 | 1,450 | 1,150 | 600 | 320 |
| 1.0 | 2,200 | 1,650 | 850 | 480 |

### Partial-Throttle TSFC at Sea Level

*[Raymer, Fig. E.2 (Partial throttle at SL), p. 991]* — TSFC (1/hr) vs. uninstalled thrust (lb) at
fixed Mach (0 to 0.7), (read from plot):

| Uninstalled thrust (lb) | Mach 0 | Mach 0.4 | Mach 0.7 |
|---|---|---|---|
| 10,000 | 0.45 | 0.55 | 0.70 |
| 20,000 | 0.40 | 0.48 | 0.62 |
| 40,000 | — | 0.42 | 0.55 |
| 50,000 | — | 0.40 | 0.50 |

Additional partial-throttle panels at 5k, 10k, 20k, 30k, 36k, and 45k ft [Raymer, Fig. E.2, pp.
992] show the same qualitative shape; not further digitized beyond the sea-level panel above.

---

## E.3 Turboprop

### Table E.3 — Turboprop Characteristics

*[Raymer, Table E.3, p. 993]*

| Parameter | Value |
|---|---|
| Sea-level static thrust | 32,000 lb {142 kN} |
| Sea-level static power | 6,500 hp {4847 kW} |
| Sea-level static TSFC | 0.14 1/hr {4.0 mg/N·s} |
| Sea-level static airflow | 42.3 lbm/s {19.2 kg/s} |
| Bare-engine weight (incl. gearbox and propeller) | 2,600 lb {1179 kg} |
| Diameter, four-bladed two-row propeller | 20.5 ft {6.2 m} |
| Engine length (propeller to exhaust) | 200 in. {508 cm} |
| Engine diameter | 46 in. {117 cm} |
| Overall pressure ratio | 30 |

Installation assumptions: inlet total pressure ratio 0.97; power extraction 54 kW; high-pressure
bleed airflow 0.8 lb/s; maximum-rated performance plotted with dashed lines.

### Full-Throttle Thrust vs. Mach Number

*[Raymer, Fig. E.3 (Full throttle thrust), p. 993]* — uninstalled thrust (lb), continuous rating,
(read from plot):

| Mach | SL | 10k ft | 20k ft | 30k ft |
|---|---|---|---|---|
| 0.0 | 32,000 | 20,000 | 12,500 | 7,000 |
| 0.1 | 22,000 | 14,500 | 9,000 | 5,000 |
| 0.3 | 12,000 | 8,500 | 5,500 | 3,200 |
| 0.5 | 8,500 | 6,200 | 4,200 | 2,500 |
| 0.7 | 6,500 | 4,900 | 3,400 | 2,000 |
| 0.9 | 5,300 | 4,100 | 2,900 | 1,700 |

Thrust falls off very steeply from M = 0 to about M = 0.2 (typical propeller static-to-cruise
thrust rolloff), then declines more gradually.

### Full-Throttle TSFC vs. Mach Number

*[Raymer, Fig. E.3 (Full throttle TSFC), p. 993]* — TSFC (1/hr), (read from plot, SL–30k curves
tightly clustered):

| Mach | All altitudes (band) |
|---|---|
| 0.0–0.1 | 0.13 |
| 0.3 | 0.30 |
| 0.5 | 0.45 |
| 0.7 | 0.62 |
| 0.9 | 0.80–0.90 |

### Engine Required Airflow vs. Mach Number

*[Raymer, Fig. E.3 (Engine required airflow), p. 993]* — airflow (lbm/s), continuous rating, (read
from plot):

| Mach | SL | 10k ft | 20k ft | 30k ft |
|---|---|---|---|---|
| 0.0 | 41 | 35 | 20 | 12 |
| 0.5 | 44 | 37 | 24 | 15 |
| 1.0 | 50 | 43 | 30 | 20 |

### Partial-Throttle TSFC at Sea Level

*[Raymer, Fig. E.3 (Partial throttle at SL), p. 993]* — TSFC (1/hr) vs. uninstalled thrust (lb),
families of curves at fixed Mach (0–0.1 through 0.6), (read from plot):

| Uninstalled thrust (lb) | Mach 0–0.1 | Mach 0.4 | Mach 0.6 |
|---|---|---|---|
| 2,000 | 0.20 | 0.45 | 0.70 |
| 5,000 | 0.18 | 0.35 | 0.55 |
| 10,000 | 0.17 | 0.28 | 0.42 |
| 20,000 | 0.16 | 0.22 | 0.30 |
| 30,000 | 0.15 | — | — |

Additional partial-throttle-ratio panels at 5k, 10k, 20k, and 30k ft [Raymer, Fig. E.3, p. 994]
show the same qualitative shape; not further digitized beyond the sea-level panel above.

---

*Appendix E complete (Tables E.1–E.3, primary full/military/max-power thrust, TSFC, and required-
airflow curves digitized for all three engines; secondary per-altitude partial-throttle panels
noted but not fully digitized beyond one representative sea-level panel each, since they repeat
the same family shape). Next: Appendix F — Design Requirements and Specifications.*
