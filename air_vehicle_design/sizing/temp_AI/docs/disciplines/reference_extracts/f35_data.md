# F-35 Lightning II — Extracted Reference Data

**Source:** F-35 Lightning II Aircraft User Manual (Microsoft Flight Simulator add-on). Based on publicly available information; not officially endorsed by Lockheed Martin. Use as reference data only — treat with appropriate uncertainty for design work.

---

## Geometry & Weights by Variant

| Parameter | F-35A (CTOL) | F-35B (STOVL) | F-35C (CATOBAR) |
|---|---|---|---|
| Length | 50.5 ft (15.4 m) | 50.5 ft (15.4 m) | 50.8 ft (15.5 m) |
| Wingspan | 35 ft (10.7 m) | 35 ft (10.7 m) | 43 ft (13.1 m) |
| Wing Area | 460 ft² (42.7 m²) | 460 ft² (42.7 m²) | 668 ft² (62.1 m²) |
| Empty Weight | 29,098 lb | 32,300 lb | 34,800 lb |
| Internal Fuel | 18,498 lb | 13,326 lb | 19,624 lb |
| Max Takeoff | ~70,000 lb | ~60,000 lb | ~70,000 lb |
| Range | 1,200 nmi | 900 nmi | 1,400 nmi |
| Combat Radius | 613 nmi | 469 nmi | 610 nmi |
| T/W (full fuel) | 0.87 | 0.90 | 0.75 |
| T/W (50% fuel) | 1.07 | 1.04 | 0.91 |
| G-limit | 9g | 7g | — |

Note: Diagram in manual gives slightly different values — F-35A: W_empty=29,036 lb, fuel=18,460 lb; F-35B: W_empty=32,161 lb, fuel=14,003 lb; F-35C: W_empty=32,072 lb, fuel=20,035 lb. Use the table values as primary reference.

F-35C folded wingspan: 31.1 ft

---

## Engine Data

### F135-PW-100 (F-35A and F-35C)
- Type: Afterburning turbofan
- Length: 220 in (559 cm)
- Diameter: 46 in max, 43 in fan inlet
- Dry weight: 3,750 lb (1,700 kg)
- Compressor: 3-stage fan + 6-stage HP
- Turbine: 1-stage HP + 1-stage LP
- Combustor: annular
- Max thrust: 43,000 lbf (AB) / 28,000 lbf (dry intermediate)
- OPR: 28:1
- TSFC (dry): 0.886 lb/hr·lbf (25.0 g/kN·s)
- T/W (dry): 7.47:1
- T/W (wet/AB): 11.467:1

### F135-PW-600 (F-35B only — includes lift fan)
- Type: Afterburning turbofan + shaft-driven lift fan
- Length: 369 in (937.3 cm)
- Diameter: 46 in max, 43 in fan inlet, 53 in lift fan inlet
- Compressor: 3-stage fan + 6-stage HP + 2-stage contra-rotating lift fan
- Turbine: 1-stage HP + 2-stage LP
- Max thrust: 41,000 lbf (AB) / 27,000 lbf (dry intermediate)
- OPR: 28:1 (conventional), 29:1 (powered lift)
- TSFC: ~0.886 lb/(hr·lbf) w/o afterburner

---

## External Payload Weights
- AIM-9X Sidewinder: 200 lb
- AIM-120 AMRAAM: 350 lb
- Centerline gunpod: 550 lb
- GBU-12 laser-guided bomb: 550 lb
- GBU-31 GPS-guided bomb (JDAM): 2,000 lb

---

## Key Variant Differences
- F-35A: only variant with internal gun (GAU-22/A); uses refuel receptacle; lightest/fastest
- F-35B: VTOL capable below 40,600 lb gross weight; smaller internal weapons bay; refuel probe
- F-35C: largest wing for low approach speed; wing folds; catapult launch bar; tail hook; longest range

---

## Derived sizing parameters (useful for framework validation)

F-35A:
- W/S = 29,098 / 460 ≈ 63.3 lb/ft² (empty weight basis; MTOW/S ≈ 152 lb/ft²)
- Fuel fraction ≈ 18,498 / 70,000 ≈ 0.264

F-35C:
- W/S = 34,800 / 668 ≈ 52.1 lb/ft² (empty); MTOW/S ≈ 104.8 lb/ft²
- Larger wing → lower wing loading → better range/lower approach speed
