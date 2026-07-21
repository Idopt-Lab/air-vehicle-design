# USAF F-16A/B Flight Manual — Extracted Reference Data (Validation Target)

**Source:** *T.O. 1F-16A-1, Flight Manual, USAF/EPAF Series Aircraft F-16A/B Blocks 10 and 15*, Lockheed Martin Corporation. (U.S. Government Technical Order — factual reference data.)
**Purpose:** Ground-truth geometry / weights / engine data for the project's **F-16A/B Block 10 & 15** example (used for unit-test validation). This is the exact aircraft & block of the project example.

> Citation: *T.O. 1F-16A-1, Section I (General Description), Figure 1-2 dimensions / A/C Gross Weight*.

---

## Principal geometry (Figure 1-2, Sheets 1–2)

### Overall
| Item | Value |
|------|-------|
| Overall length | 47.50 ft (≈ 49.81 ft incl. probe per dwg) |
| Overall height | 16 ft 8.5 in |
| Overall span w/o missiles | 31 ft |
| Overall span w/ wingtip missiles | 32 ft 10 in |

### Wing (main reference surface)
| Property | Value |
|----------|-------|
| **Area (S_ref)** | **300 sq ft** |
| **Span (b)** | **30 ft** |
| **Aspect ratio** | **3.0** |
| **Taper ratio (λ)** | **0.2275** |
| **LE sweep** | **40°** |
| Dihedral | 0° |
| Incidence | 0° |
| Airfoil | NACA 64A204 |
| Twist | 0° at BL 54.0; 3° at BL 180.0 |
| Flaperon area | 31.32 sq ft |
| Leading-edge flap (LEF) area | 36.71 sq ft |

### Horizontal tail (all-moving)
| Property | Value |
|----------|-------|
| Area | 63.70 sq ft (Block 10/early); **49.0 sq ft** appears as an alt value in the later sheet — verify per block |
| Aspect ratio | 2.114 (alt 2.598) |
| Taper ratio | 0.390 (Theo) (alt 0.3) |
| LE sweep | 40° |
| Dihedral | −10° (anhedral) |
| Airfoil | 6% biconvex (root) → 3.5% biconvex (tip) |

### Vertical tail
| Property | Value |
|----------|-------|
| Area | 54.75 sq ft |
| Aspect ratio | 1.294 |
| Taper ratio | 0.437 |
| LE sweep | 47.5° |
| Airfoil | 5.3% biconvex (root) → 3.0% biconvex (tip) |
| Rudder area | 11.65 sq ft |

### Ventral fins (each) & speedbrakes
- Ventral fin (each): area 8.03 sq ft, LE sweep 30°, cant 15° outboard.
- Speedbrakes: 4-element clamshell, total 14.26 sq ft (3.565 sq ft each).

---

## Engine
| Property | Value |
|----------|-------|
| Engine | Pratt & Whitney **F100-PW-200 / -220 / -220E** |
| Thrust | **25,000 lb class** (sea-level static, afterburning) |
| Compressor face diameter | 34.8 in |
| Engine length | 191.16 in |

> *(For TSFC / thrust-lapse modeling see `mattingly_data.md`.)*

---

## Weights (Section I — Aircraft Gross Weight)
Configuration = pilot, oil, two wingtip AIM-9 missiles, full 20 mm ammunition.

| Block / variant | GW (no internal fuel) | GW (full internal JP-8) |
|-----------------|-----------------------|--------------------------|
| Block 10, single-seat (F-16A) | ≈ 17,500 lb | ≈ 24,800 lb |
| Block 10, two-seat (F-16B) | ≈ 18,300 lb | ≈ 24,400 lb |
| Block 15, single-seat (F-16A) | ≈ 17,900 lb | ≈ 25,200 lb |
| Block 15, two-seat (F-16B) | ≈ 18,700 lb | ≈ 24,800 lb |

- F100-PW-220 ("PW220"): aircraft ≈ 100 lb heavier than the PW200 figures above.

## Fuel
- **Total internal fuel ≈ 6,950 lb (JP-8)** (knob/pointer table, §1; ≈ 7,290 lb at the "**" alternate calibration). JP-4 ≈ 5,650–5,930 lb.
- Fuels: JP-4 / JP-5 / JP-8; NATO F-34/F-35/F-40/F-43.

---

## Notes for the project (validation context)
- **S_ref = 300 ft², b = 30 ft, AR = 3.0, λ = 0.2275, Λ_LE = 40°, NACA 64A204** — use these as the authoritative L2/L3 wing geometry inputs for the F-16A example.
- HT/VT areas & sweeps above feed the L2/L3 tail geometry (cross-check the tail-volume-coefficient sizing in `nicolai_data.md`: F-16 C_HT=0.68, C_VT=0.041).
- **Empty-ish combat GW ≈ 17.5k lb; clean + full internal fuel + 2 AIM-9 ≈ 24.8k lb.** The project's **TOGW target of 31,000 lbf** corresponds to a heavier combat takeoff configuration (external stores / fuel beyond the clean air-defense load), not the clean number here — keep this in mind when validating L1/L2/L3 sizing.
- Internal fuel ≈ 6,950 lb (JP-8) bounds the internal fuel-fraction for mission analysis.
- ⚠️ Two slightly different HT area/AR/taper values appear across the two dimension sheets (likely Block 10 vs 15 / different printings) — confirm the per-block value before hard-coding.
