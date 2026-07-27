# AeroL1

Level-1 aerodynamics static toolbox (`classdef AeroL1`, `methods (Static)` only). Called as
`AeroL1.method(...)`; never instantiated and not in the inheritance chain. `F16AeroL1` inherits
`AeroModelL1` and delegates here.

**L1 is geometry-free.** The drag polar is a Mattingly aircraft-type curve, not a skin-friction or
geometry buildup, so a concrete L1 class takes no geometry object.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `drag_polar`, `get_CLmax` |
| Low-level — scalars and arrays only | `mattingly_polar`, `interp_curve`, `mattingly_K2`, `roskam_CLmax_value`, `lookup_CLmax`, `to_CLmax_table_row` |
| Constant tables | `CLmax_table` (Roskam Table 3.1), `Delta_CD0` (Roskam Table 3.6) |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `drag_polar(obj, state)` | `{CD0, K1, K2}` | Mattingly 2nd ed. Eq. 2.9 |
| `get_CLmax(obj)` | clean CLmax | Roskam Vol. I Table 3.1 |
| `roskam_CLmax_value(cat, column)` | range mean of one CLmax column | Roskam Vol. I Table 3.1 |
| `lookup_CLmax(type)` | clean CLmax by type — **standalone, not wired** | Roskam Vol. I Table 3.3 |
| `interp_curve(mach, value, M)` | linear interpolation, clamped at the ends | — |

## 3. Equations

**Drag polar** [Mattingly 2nd ed. Eq. 2.9]:

$$C_D = C_{D_0}(M) + K_1(M)\,C_L^{2} + K_2\,C_L$$

$C_{D_0}(M)$ and $K_1(M)$ are interpolated by Mach from the fighter "Current" type-curves
[Mattingly 2nd ed. Fig. 2.10 and Fig. 2.11]. A tabulated figure has no transonic pole, so the curves
are evaluated across the whole Mach range — contrast `AeroL2`'s Eq. 12.51 supersonic path, which
does.

$K_2 = 0$ for an uncambered fighter [Mattingly 2nd ed. Sec. 2.3.1]. Any other `design_type` errors:
the cambered-type curve fit is not in this repo.

**CLmax**, as the range mean of the aircraft type's column [Roskam Vol. I Table 3.1]:

$$C_{L_{max}} = \operatorname{mean}\big(\text{Table 3.1 column for the type}\big)$$

## 4. One table throughout

`get_CLmax` reads **Table 3.1**, the same table the takeoff and landing increments are differenced
from:

$$\Delta C_{L_{max},TO} = \overline{C_{L_{max},TO}} - \overline{C_{L_{max},clean}} \qquad
  \Delta C_{L_{max},L} = \overline{C_{L_{max},L}} - \overline{C_{L_{max},clean}}$$

Fighter totals are therefore clean **1.50**, takeoff **1.70**, landing **2.10**, all from one table.
`lookup_CLmax` still implements Table 3.3 (fighter 0.90) and is unit-tested, but is deliberately not
wired into `get_CLmax` — mixing the two gave totals belonging to neither table.

The resulting L1→L2 step (1.50 against Raymer Eq. 12.15's 0.913) is the largest in the fidelity
ladder and is intentional: a type-only statistical mean against a geometry-based estimate.

**Category vocabulary.** The canonical key is `jet_fighter`; Roskam's CLmax table prints `fighter`.
`to_CLmax_table_row` translates. Do not rename the table row to match the key — the row name is what
the textbook prints and the citation depends on it.

## 5. To-dos

| Item | Guard |
|---|---|
| Mattingly Fig. 2.10/2.11 are **not in this repo**. The curve blocks in `f16a_L1.json` are seeded from 5 AAF worked-example points and marked `_placeholder` | `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` |
