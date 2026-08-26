# AeroL1

Level-1 aerodynamics static toolbox (`classdef AeroL1`, `methods (Static)` only). Called as
`AeroL1.method(...)`. It is never instantiated, and it is not in the inheritance chain. `F16AeroL1`
inherits `AeroModelL1` and calls these statics.

**Geometry-free for the drag-polar shape, but not for K1.** `CD0(M)` is a Mattingly type-curve read
from the input JSON. `k1_from_geometry` needs wing aspect ratio and leading-edge sweep, and nothing
else about the planform.

A toolbox has no constructor, no inputs and no derived properties.

---

## 1. Members

No static takes a design object. Each takes scalars, strings or arrays.

| Constant | Source | Coverage |
|---|---|---|
| `CLmax_table` | Roskam Vol. I Table 3.1, p. 91 | all 12 printed rows, verified: 36 ranges, zero mismatches |
| `Delta_CD0` | Roskam Vol. I Table 3.6, p. 126 | all 4 printed rows |

`drag_polar(obj, state)` and `get_CLmax(obj)` moved to `F16AeroL1`.

### Statics

| Static | Signature | Returns | Source |
|---|---|---|---|
| `k1_from_geometry` | `(AR, Lambda_LE_deg, M)` | induced-drag factor `K1` | Raymer 6th ed. Eq. 12.48-12.51 |
| `interp_curve` | `(mach_pts, val_pts, M)` | value at `M`, clamped at both ends | generic |
| `mattingly_K2` | `(design_type)` | `K2` | Mattingly 2nd ed. Sec. 2.3.1 |
| `to_CLmax_table_row` | `(aircraft_category)` | the printed table row name | Roskam Vol. I Table 3.1 |
| `roskam_CLmax_value` | `(aircraft_category, column)` | range mean of one CLmax column | Roskam Vol. I Table 3.1 |

`methods (Static, Access = private)` holds five helpers. Two build the `Constant` tables:
`build_CLmax_table` and `build_DeltaCD0_table`. Three normalize a caller's spelling:
`normalize_DeltaCD0_quantity`, `normalize_flapconfig` and `normalize_CL_condition`. See §5.

## 3. Equations

**Drag polar** [Mattingly 2nd ed. Eq. 2.9]:

$$C_D = C_{D_0}(M) + K_1(M)\,C_L^{2} + K_2\,C_L$$

`F16AeroL1.drag_polar` assembles that sum. `CD0(M)` is read with `interp_curve` from the tabulated
Fig. 2.10 curve, which has no transonic pole. `K1(M)` is an equation: `k1_from_geometry` dispatches on
`AeroL2.flight_regime(M)`:

| Regime | Path |
|---|---|
| subsonic | `e = AeroL2.oswald_eff(AR, Lambda_LE_deg)` [Raymer Eq. 12.48/12.49], then `K1 = AeroL2.K1_subsonic(e, AR)` [Eq. 12.50] |
| supersonic | `K1 = AeroL2.K1_supersonic(M, AR, Lambda_LE_deg)` [Eq. 12.51] |
| transonic | `NaN` |

**`K2` = 0** for an uncambered fighter [Mattingly Sec. 2.3.1]. Any other `design_type` gives
`AeroL1:unsupportedDesignType`: the cambered-type curve fit is not in this repo.

**CLmax** is the range mean of the type's column [Roskam Vol. I Table 3.1]:

$$C_{L_{max}} = \operatorname{mean}\big(\text{Table 3.1 column for the type}\big)$$

## 4. Formula choices and guards

- **One table throughout.** `roskam_CLmax_value` reads Table 3.1, the same table the increments are
  differenced from. Mixing in another table gives totals belonging to neither.
- **Category vocabulary.** `to_CLmax_table_row` translates a canonical key to the row name Roskam
  prints. **Do not rename a row to match a key**: the citation depends on the printed name. An
  unknown category passes through and `roskam_CLmax_value` raises `AeroL1:unknownAircraftType`.
  All 12 rows are reachable, and each printed name also maps to itself.

  | Table 3.1 row | Accepted keys |
  |---|---|
  | `fighter` | `jet_fighter`, `navy_fighter`, `fighter` |
  | `transport_jet` | `jet_transport`, `civil_transport`, `transport_jet` |
  | `mil_patrol_bomb_transport` | `military_cargo`, `jet_bomber`, `bomber`, `military_patrol`, `mil_patrol_bomb_transport` |
  | `single_engine_propeller` | `general_aviation_single`, `light_aircraft_single`, `single_engine_propeller` |
  | `twin_engine_propeller` | `general_aviation_twin`, `light_aircraft_twin`, `twin_engine_propeller` |
  | `regional_tbp` | `regional_turboprop`, `regional_tbp` |
  | `flying_boat_amphibious_float` | `jet_seaplane`, `prop_seaplane`, `flying_boat`, `amphibious`, `flying_boat_amphibious_float` |
  | `supersonic_cruise` | `supersonic_transport`, `supersonic_cruise` |
  | `homebuilt`, `agricultural`, `business_jet`, `military_trainer` | the printed name only |

  `jet_fighter` and `jet_transport` are the keys the input JSONs carry.
  `B777AeroL1.cfe_from_category` does the same translation for Raymer Table 12.3's `civil_transport`.

- **Roskam has NO sailplane row.** Its 12 categories are all powered, so `sailplane` errors. Correct:
  inventing a row would be worse.
- **The transonic band returns `NaN`, deliberately.** Eq. 12.51's pole near M = 1 makes
  `k1_from_geometry` `NaN` for `0.95 <= M < 1.05`. No F-16 requirement condition sits there, and
  `CD0(M)` has no gap, so only `K1` is affected.
- **`interp_curve` clamps** instead of extrapolating, and guards its input with
  `AeroL1:curveLengthMismatch`, `AeroL1:curveTooShort` and `AeroL1:curveNotAscending`. The ascending
  check matters: clamping to the end elements is wrong on an unsorted vector.
- **`Delta_CD0`'s `landing_gear` row has `NaN` for `e_osw`**, matching the "no effect" the book
  prints, because gear down does not change span efficiency. A caller must not average it in.
### As-built values

Verified 2026-08-25.

| Call | Value |
|---|---|
| `roskam_CLmax_value("jet_fighter", "CL_max_clean")` | 1.5000000000 |
| `roskam_CLmax_value("jet_fighter", "CL_max_TO")` | 1.7000000000 |
| `roskam_CLmax_value("jet_fighter", "CL_max_L")` | 2.1000000000 |
| `to_CLmax_table_row("jet_fighter")` | `"fighter"` |
| `mattingly_K2("uncambered")` | 0 |

The high-lift increments are therefore 0.20 and 0.60, both differences inside Table 3.1.

`k1_from_geometry` at the F-16 wing, AR 3.0 and LE sweep 40 deg:

| M | K1 | Regime |
|---|---|---|
| 0.20 | 0.1167742146 | subsonic |
| 0.87 | 0.1167742146 | subsonic, K1 is Mach-independent here |
| 0.95 | `NaN` | transonic |
| 1.00 | `NaN` | transonic |
| 1.05 | 0.1278907226 | supersonic |
| 1.60 | 0.2760308993 | supersonic |
| 2.00 | 0.3670238616 | supersonic |

### The three CLmax sources do not answer the same question

| Source | F-16 value | What it is |
|---|---|---|
| Roskam Table 3.1, fighters, clean | 1.2-1.8, mean **1.500** | statistical class range, `F16AeroL1` |
| Raymer Eq. 12.15 | **0.914058** | geometry: `0.9*Clmax_2D*cos(QC_sweep)`, `F16AeroL2` and `L3` |
| Nicolai Table 9.1, F-16C | **1.70** at AR 3.20 | one measured aircraft, devices DEPLOYED. Reference only; no code holds this table |

Verified live: L1 gives 1.500000, L2 and L3 both give 0.914058 at `QC_sweep_wing` 32.183178 deg.

The L1 to L2 step is the largest in the fidelity ladder, and it is intentional: a class mean against
a geometry estimate.

**Nicolai's F-16C 1.70 is a cross-check on the flapped value, not on the clean one.** Roskam Table
3.1's fighter TAKEOFF column is 1.4-2.0, mean 1.70, so two independent sources agree at the mean.
That also supports the note in `aerodynamics_brandt_comparison.m`, which records both L1 and Brandt's
0.984 as well under the whole-aircraft value because no LEX or strake vortex lift is modelled. The
F-16C differs from the Block 10/15 F-16A, so treat it as an approximate check.

## 5. To-dos

| Item | Guard |
|---|---|
| **Mattingly Fig. 2.10 is not in this repo.** The `CD0` curve block in `f16a_L1.json` is seeded from 5 AAF worked-example points and marked `_placeholder` | `TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` |
| **`k1_from_geometry` calls INTO `AeroL2`**, four times: `flight_regime`, `oswald_eff`, `K1_subsonic`, `K1_supersonic`. An L1 toolbox reaching up a tier is the wrong direction. The proposal on the table is to promote all four into `AerodynamicsBase`, the Tier-1 home for cross-level utilities | `% TODO (8/13/2026)` in the source |
| **The three `normalize_*` private helpers are unreachable.** `normalize_DeltaCD0_quantity`, `normalize_flapconfig` and `normalize_CL_condition` are `Access = private`, and nothing inside the class calls them, so no caller can reach them at all. They were written for a table-query interface that does not exist | this doc |
| **There is no categorical CLEAN CLmax lookup, and that is deliberate.** No book in `docs/reference_extracts/` prints one. Roskam Table 3.1's clean column is a class RANGE. Raymer gives an equation, Eq. 12.15, not a table. Nicolai Table 9.1 is per-aircraft and flapped. **Do not add one from unsourced numbers**: that is what was removed | this doc |
| `interp_curve` puts generic interpolation in a discipline toolbox. It is not aerodynamics, and any discipline could want it | this doc |
