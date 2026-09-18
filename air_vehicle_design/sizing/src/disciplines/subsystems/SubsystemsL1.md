# SubsystemsL1

Level-1 subsystems static toolbox.
Called as `SubsystemsL1.method(...)`.

L1 is a pure tabulation tier: no geometry. Everything here is the Raymer avionics content.

---

## 1. Constant

| Name | Value | Citation |
|---|---|---|
| `AVIONICS_DENSITY` | `mean([30, 45])` = 37.5 lb/ft^3 | Raymer 6th ed. Ch.11 p.375, the paragraph before Table 11.6 |

## 2. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_avionics_weight` | `avi_WF`, `W_empty` [lbf] | avionics weight [lbf] | Raymer 6th ed. Table 11.6, p.375 |
| `compute_avionics_volume` | `W_avionics` [lbf], `density_lb_per_ft3` | avionics volume [ft^3] | Raymer 6th ed. Ch.11, p.375 |
| `lookup_avionics_weight_fraction_range` | `aircraft_category` | `[low, high]` fraction of `W_empty` | Raymer 6th ed. Table 11.6, p.375 |

## 3. Coefficients

From Table 11.6, Raymer 6th edition.

| Row | Fraction of `W_empty` |
|---|---|
| General aviation-single engine | 0.01 - 0.03 |
| Light twin | 0.02 - 0.04 |
| Turboprop transport | 0.02 - 0.04 |
| Business jet | 0.04 - 0.05 |
| Jet transport | 0.01 - 0.02 |
| Fighters | 0.03 - 0.08 |
| Bombers | 0.06 - 0.08 |
| Jet trainers | 0.03 - 0.04 |

Row names are Raymer's printed plurals.

The lookup returns the range. Taking the mean is the caller's decision, not the table's.
