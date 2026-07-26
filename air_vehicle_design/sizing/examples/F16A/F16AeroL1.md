# F16AeroL1

F-16A Block 10/15 Level-1 aerodynamics. `classdef F16AeroL1 < AeroModelL1`; every contract method is
a one-line delegation into the `AeroL1` static toolbox.

**L1 is geometry-free.** The drag polar is the Mattingly Fig. 2.10/2.11 fighter "Current" type-curve,
which consumes no geometry, so this class takes **no** geometry object — contrast `F16AeroL2`/`L3`,
whose constructors require one.

---

## 1. Constructor

```matlab
a1 = F16AeroL1(f16a_spec_path(1));
```

`F16AeroL1(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the top-level `aircraft_category` and the `.aerodynamics` block of `f16a_L1.json`.

---

## 2. Inputs

Plain mutable `properties`, set once by the constructor.

| Property | Value | Meaning / citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | The one canonical top-level class flag. Selects the Roskam CLmax row (translated to that table's own `fighter` row name by `AeroL1.to_CLmax_table_row`) and the Mattingly fighter curves |
| `design_type` | `"uncambered"` | → `K2 = 0` [Mattingly §2.3.1] |
| `curve` | `"Current"` | Selects the Mattingly technology curve ("Current"/"Future") |
| `cd0_curve_mach` / `cd0_curve_value` | breakpoint vectors | Mattingly Fig. 2.10 CD0-vs-Mach |
| `k1_curve_mach` / `k1_curve_value` | breakpoint vectors | Mattingly Fig. 2.11 K1-vs-Mach |

## 3. Derived

None. L1 owns no geometry, so there are no `Dependent` getters on this class.

---

## 4. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `drag_polar(state)` | `AeroL1.drag_polar` → `{CD0(M), K1(M), K2 = 0}` | Mattingly AED 2nd ed. Eq. 2.9, Fig. 2.10/2.11 |
| `get_CLmax(~)` | `AeroL1.get_CLmax` → `roskam_CLmax_value(category, "CL_max_clean")` | Roskam Vol. I Table 3.1 |
| `get_Delta_CLmax_{TO,L}` | Table 3.1 column difference vs the clean column | Roskam Table 3.1 |
| `get_CLmax_{TO,L}` | clean + the matching increment | Roskam Table 3.1 |
| `get_Delta_e_osw_{TO,L}` | `e(flaps) − e(clean)` from `AeroL1.Delta_CD0` | Roskam Table 3.6 |
| `get_Delta_CD0_{TO,L}` | `ΔCD0(flaps) + ΔCD0(gear)` | Roskam Table 3.6 |

Private helpers `roskam_CLmax` / `roskam_e_osw` / `roskam_Delta_CD0` read the `AeroL1` constant
tables. `roskam_CLmax` delegates to the same `AeroL1.roskam_CLmax_value` static that `get_CLmax`
uses, so the clean base and the increments are guaranteed to come from one table.

### As-built values

| Quantity | Value |
|---|---|
| `drag_polar(36 kft, M 0.87)` | `CD0` 0.016000, `K1` 0.180000, `K2` 0 |
| `get_CLmax` | **1.50** (fighter clean mean) |
| `get_CLmax_TO` / `_L` | 1.70 / 2.10 |

**One table throughout.** Clean CLmax and the TO/landing increments all come from Table 3.1, so the
totals equal that table's own fighter means. `AeroL1.lookup_CLmax` still implements Table 3.3
(fighter 0.90) as a standalone tested utility, but is deliberately not wired here. The resulting
L1→L2 step (1.50 vs 0.913 from Raymer Eq. 12.15) is large and intentional — see
`docs/aerodynamics_parameter_usage.md` §4.

---

## 5. To-dos

| Item | Guard |
|---|---|
| The Mattingly Fig. 2.10/2.11 curves in `f16a_L1.json` are placeholder data (5 AAF worked points, not the digitized figures) | `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` — red until replaced |
