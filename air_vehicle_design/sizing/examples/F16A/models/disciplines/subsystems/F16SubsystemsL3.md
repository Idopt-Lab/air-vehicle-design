# F16SubsystemsL3

F-16A Block 10/15 Level-3 subsystems class (`classdef F16SubsystemsL3 < SubsystemsModelL3`).
Equations live in `SubsystemsL3`; see `src/disciplines/subsystems/SubsystemsL3.md`.

Working today: the avionics component buildup and the fuselage internal volume. The members in §5
error.

---

## 1. Inputs

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L3.json` `.subsystems.fuel.fuel_type` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L3.json` `.subsystems.fuel.packaging_factor_category` |
| `avionics_table_row` | `'Fighters'` | `f16a_L3.json` `.subsystems.avionics.aircraft_category_table_row` |
| `avionics_components` | 17 entries | `f16a_L3.json` `.subsystems.unclassified_avionics_equipment.components` |
| `geom` | injected `(1,1) GeometryModelL3` | fuselage station table, wing planform |
| `fuel_weight_source` | injected `(1,1) WeightsBase` | `W_energy`, `W_TO`/`OEW` |

Constructor `F16SubsystemsL3(json_path, geom, fuel_weight_source)`, all three required, no default.

`geom` typed to `GeometryModelL3` is the one substantive difference from `F16SubsystemsL2`: the
fuselage volume comes from `GeomL3`'s station table, not `GeomL2`'s envelope ellipse.

## 2. Derived properties

Eight `Dependent` properties are declared: `avionics_weight_fraction`, `avionics_density`,
`avionics_weight`, `avionics_volume`, `fuel_density`, `fuselage_usable_fuel_volume`,
`wing_fuel_volume`, `fuel_volume`. **None has a getter**, so every one errors on read. They stay
declared because `SubsystemsBase` (first five) and `SubsystemsModelL3` (last three) require them.

## 3. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_avionics_weight_component_buildup` | none | net weight [lbf]; per-box table `Component`, `Weight_lbf`, `Volume_ft3`, `Power_W` |
| `get_internal_volume` | none | fuselage internal volume [ft^3], 764.0820 |
| `battery_volume` | `E_required_kWh` | errors, §5 |
| `fuel_volume_from_weight` | `fuel_weight_lb` | errors, §5 |
| `fuel_volume_check` | none | errors, §5 |

`get_internal_volume` denormalizes `geom.frames_normalized` by `geom.L_fus`,
`geom.W_max_fuselage`, `geom.H_max_fuselage`, then calls
`SubsystemsL3.compute_volume_from_control_stations`. It is the fuselage volume only; it does not add
avionics or gear-bay volume.

## 4. Avionics component buildup

One JSON entry per box, each carrying a Table 8.8 `category` plus whatever weight, volume or power
has been sourced.

**Any ONE sourced figure resolves a box**, because Table 8.8 inverts in every direction. A sourced
figure is never overwritten by an estimate. A box with no `category` keeps only what the JSON gives
it. A `"a + b"` category is one box holding both functions, so its known quantity splits evenly
between the two rows.

A box with nothing sourced reads `NaN` and drops out of the net, so the net is a floor. Currently
**11 of 17 boxes resolve, netting 1081.09 lbf**. The six without a figure are the HF radio, TACAN,
radar altimeter, FLCC, SMS and threat warning system.

Two private statics support it: `box` resolves one component; `attempt` returns `NaN` where a fit
has no valid inverse instead of propagating the error.

## 5. Broken members

Three methods delegate to `SubsystemsL3` entry points the toolbox does not provide.

| Member | Error |
|---|---|
| `battery_volume` | no static named `battery_volume` |
| `fuel_volume_from_weight` | no static named `fuel_volume_from_weight` |
| `fuel_volume_check` | the static takes two scalars; the design object is passed |

Plus the eight getter-less `Dependent` properties in §2.

The class still constructs, because a `Dependent` getter runs only on read and nothing inside the
class reads those eight. That is why the L3 sizing report runs.

## 6. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| 9/11/2026 | Add `get_avionics_volume_component_buildup` | `F16SubsystemsL3.m:118`, after `get_avionics_weight_component_buildup` |
| 9/11/2026 | Add `get_total_power_load` | `F16SubsystemsL3.m:120`, methods block |
| 9/11/2026 | Rename to `get_avionics_volume_component_buildup` | `F16SubsystemsL3.m:122`, free-floating; attached to no function, and names the same target as the entry above |
| 9/11/2026 | Rename to `get_total_internal_volume` | `F16SubsystemsL3.m:125`, above `get_internal_volume` |

