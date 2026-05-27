## Learnings

### 2026-05-24 to 2026-06-XX — BrandtMission validation complete (43/43)

#### Mission Validation Targets (all ±1% confirmed)
| Output | MATLAB Result | Excel GT | Cell | Error |
|--------|--------------|----------|------|-------|
| Total fuel | 6002.93 lb | 6000.43 lb | Miss!O9 | 0.04% |
| Total time | 94.06 min | 94.06 min | Miss!O8 | 0.00% |
| Landing dist | 2884.90 ft | 2884.95 ft | Miss!O6 | 0.00% |

#### Per-Segment Ground Truth (Miss!B9:N9 fuel, B8:N8 time)
| Segment | Fuel (lb) | Time (min) |
|---------|----------|-----------|
| Takeoff | 1540.1 | 0.223 |
| Accel | 377.2 | 2.256 |
| Climb | 449.1 | 4.508 |
| Cruise | 1003.3 | 22.95 |
| Patrol | 0 | 0 |
| Dash | 484.1 | 6.017 |
| Patrol2 | 0 | 0 |
| Combat | 564.0 | 2.0 |
| Egress | 304.6 | 6.017 |
| Patrol3 | 0 | 0 |
| Climb2 | 0 | 0 |
| Cruise2 | 789.4 | 30.08 |
| Loiter | 488.6 | 20.0 |

#### Root Cause of Three Failures (Climb, Egress, Cruise2) — Now Fixed
- `BrandtGeometry.S_wet_total_accurate_ft2` was 1332.69 ft² instead of 1371.09 ft².
- Missing: `K21 = Geom!K21 = Main!D18 × 2 = strake.S_ft2 × 2 = 40 ft²` (strake chine wetted area).
- Excel Geom B19 formula: `D23 + B4 + B14 + B15 + B16 + B17 + K21`.
- Impact: CDmin_sub = 0.01644 instead of 0.01691 → CDo underestimated → fuel underestimated by ~1-1.5%.
- Fix applied to `BrandtGeometry.computeSwetAccurate()`.

#### Brandt Correction Factor #8 (New)
- **Strake chine term K21**: S_wet includes `strake.S_ft2 × 2` (both sides of strake/chine planform) SEPARATELY from the exposed-strake Raymer formula (B15). Not obvious from textbook; must read Geom!B19 formula directly from Excel.

#### Cell Map Additions (Miss tab)
- `Miss!B3:N3` — Mach per segment
- `Miss!B5:N5` — Altitude ft per segment
- `Miss!B6:N6` — distance (nm) per segment
- `Miss!B8:N8` — time (min) per segment
- `Miss!B9:N9` — fuel burn (lb) per segment
- `Miss!B11:N11` — dW/Wto per segment
- `Miss!B12:N12` — W/Wto at end of each segment
- `Miss!O6` — landing distance (ft)
- `Miss!O8` — total time (min)
- `Miss!O9` — total fuel (lb)
- `Miss!B26:N26` — CDo_base per segment (from aero_at_mach)
- `Miss!B27:N27` — k1 per segment
- `Miss!B28:N28` — k2 per segment
- `Miss!B33:N33` — TSFC per segment
- `Miss!B43:N43` — thrust lapse (alpha) per segment
