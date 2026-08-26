# F16AeroL1

F-16A Block 10/15 Level-1 aerodynamics. `classdef F16AeroL1 < AeroModelL1`.

**No injected geometry object**, unlike `F16AeroL2` and `L3`. `CD0(M)` is the Mattingly Fig. 2.10
fighter "Current" type-curve. **`K1(M)` is equation-based**: `AeroL1.k1_from_geometry` evaluates
Raymer Eq. 12.48-12.51 on the wing `AR` and `Lambda_LE_deg`, two spec scalars read from JSON.

---

## 1. Constructor

```matlab
a1 = F16AeroL1(f16a_spec_path(1));
```

`F16AeroL1(json_path)`. Required, no default; a no-arg call gives `MATLAB:minrhs`. Reads the top-level
`aircraft_category` and the `.aerodynamics` block of `f16a_L1.json`.

## 2. Inputs

| Property | Value | Meaning and citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | canonical class flag. Selects the Roskam Table 3.1 row, via `to_CLmax_table_row`, and the Mattingly fighter curve |
| `design_type` | `"uncambered"` | gives `K2` = 0 [Mattingly §2.3.1] |
| `curve` | `"Current"` | Mattingly CD0 technology curve |
| `cd0_curve_mach` / `_value` | 8 breakpoints each | Mattingly Fig. 2.10, CD0 against Mach |
| `AR` | 3.0 | wing aspect ratio, same value as `f16a_L2.json` `.geometry.wing.AR` |
| `Lambda_LE_deg` | 40.0 | wing LE sweep, same value as `.geometry.wing.sweep_LE_deg` |

## 3. Derived

None. This class owns no geometry, so it has no `Dependent` getters.

## 4. Methods

| Method | Does | Source |
|---|---|---|
| `drag_polar(state)` | assembles `struct(CD0, K1, K2)` | Mattingly 2nd ed. Eq. 2.9 |
| `get_CD0_rough(state)` | `AeroL1.interp_curve` on the CD0 curve | Mattingly Fig. 2.10 |
| `get_CLmax(obj, ~)` | `AeroL1.roskam_CLmax_value(category, "CL_max_clean")` | Roskam Vol. I Table 3.1 |
| `get_Delta_CLmax_{TO,L}` | Table 3.1 column difference against clean | Roskam Table 3.1 |
| `get_CLmax_{TO,L}` | clean plus the matching increment | Roskam Table 3.1 |
| `get_Delta_e_osw_{TO,L}` | `e(flaps) - e(clean)` | Roskam Table 3.6 |
| `get_Delta_CD0_{TO,L}` | `dCD0(flaps) + dCD0(gear)` | Roskam Table 3.6 |
| `get_config_polar(config)` | 6 config strings, 3 distinct results | — |
| private `roskam_CLmax`, `roskam_e_osw`, `roskam_Delta_CD0` | read the `AeroL1` constant tables | — |

`get_CLmax` keeps an ignored `state` slot to match the `AerodynamicsBase` contract. Dropping it once
broke 59 tests.

`roskam_CLmax` delegates to the same `AeroL1.roskam_CLmax_value` that `get_CLmax` uses, so the clean
base and the increments come from one table.

`get_config_polar` has no gear-up against gear-down split: both `takeoff_*` map to the takeoff
deltas, and both `landing_*` plus `approach` to the landing deltas.

### As-built values

| Quantity | Value |
|---|---|
| `CD0` @ SL, M 0.2 | 0.0160000000 |
| `K1` @ M 0.2 | 0.1167742146 |
| `K2` | 0 |
| `get_CLmax` | 1.5000000000 |
| `get_CLmax_TO` / `_L` | 1.7000000000 / 2.1000000000 |
| `dCLmax_TO` / `_L` | 0.2000000000 / 0.6000000000 |
| `dCD0_TO` / `_L` | 0.0350000000 / 0.0850000000 |
| `de_osw_TO` / `_L` | −0.0500000000 / −0.1000000000 |

The CD0 curve is flat at 0.016 from M 0 to 0.9 and flat at 0.028 from M 1.2 up, so M 0.2 and M 0.6
give the same drag.

Clean CLmax and both increments come from Table 3.1, so the totals are that table's fighter means.
No categorical clean-CLmax lookup exists, because no book in `docs/reference_extracts/` prints one.
The L1 to L2 step, 1.50 against Raymer Eq. 12.15's 0.914058, is intentional.

## 5. To-dos

| Item | Guard |
|---|---|
| The `f16a_L1.json` CD0 curve is placeholder data: 5 AAF worked points, not the digitized Fig. 2.10 | `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` |
