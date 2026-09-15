# F16SubsystemsL3

F-16A Block 10/15 Level-3 subsystems class (`classdef F16SubsystemsL3 < SubsystemsModelL3`).
Equations live in `SubsystemsL3`; see `src/disciplines/subsystems/SubsystemsL3.md`.

The class is concrete. Every `Dependent` property has a getter and reads. The two members in §5
still error.

---

## 1. Inputs

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L3.json` `.subsystems.fuel.fuel_type` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L3.json` `.subsystems.fuel.packaging_factor_category`. **Read, never used.** |
| `fuselage_packaging_factor_category` | `'Integral tank — shallow fuselage'` | class default. Drives `get_fuselage_fuel_volume_available`. |
| `wing_packaging_factor_category` | `'Integral tank — wing'` | class default. **Unused.** |
| `avionics_table_row` | `'Fighters'` | `f16a_L3.json` `.subsystems.avionics.aircraft_category_table_row` |
| `avionics_components` | 17 entries | `f16a_L3.json` `.subsystems.unclassified_avionics_equipment.components` |
| `geom` | injected `(1,1) GeometryModelL3` | fuselage station table, wing planform |
| `fuel_weight_source` | injected `(1,1) WeightsBase` | `W_energy`, `W_TO`/`OEW` |

Constructor `F16SubsystemsL3(json_path, geom, fuel_weight_source)`. No default.

`geom` typed to `GeometryModelL3` is the one substantive difference from `F16SubsystemsL2`: the
fuselage volume comes from `GeomL3`'s station table.

**The JSON packaging factor is ignored.** `packaging_factor_category` is loaded from the JSON and
read by nothing. The fuselage term uses the class-default `fuselage_packaging_factor_category`.

## 2. Derived properties

Nine `Dependent` getters, recomputed on read.

| Property | Value | Reads |
|---|---|---|
| `avionics_weight_fraction` | 0.0550 | `avionics_table_row` |
| `avionics_density` | 54.3676 lb/ft^3 | `avionics_weight / total_avionics_volume_occupied` |
| `avionics_weight` | 1081.0925 lbf | the component buildup |
| `total_avionics_volume_occupied` | 19.8849 ft^3 | the component buildup |
| `fuel_density` | 50.0 lb/ft^3 | `fuel_type` |
| `fuselage_usable_fuel_volume` | 611.2656 ft^3 | `geom` station table, packaging factor |
| `wing_fuel_volume` | 55.0161 ft^3 | `geom` wing planform |
| `total_fuel_volume_occupied` | `W_energy / fuel_density` | `fuel_weight_source.W_energy` |
| `total_design_volume` | 819.0981 ft^3 | `wing_fuel_volume` + raw fuselage volume |

`total_fuel_volume_occupied` reads `NaN` on a freshly built `F16WeightsL3`, because `W_energy` is
`NaN` until a sizing run sets it. Setting `W_energy` to 7000 gives exactly 140.0000 ft^3.

**`avionics_density` is derived.** L3 weighs real boxes, so weight and volume both
come from the buildup and their ratio is the density. `SubsystemsL1` and `SubsystemsL2` hold a
37.5 lb/ft^3 constant; reading that at L3 would be a fidelity inversion.

## 3. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_avionics_weight_component_buildup` | none | net weight [lbf], 1081.0925; per-box table `Component`, `Weight_lbf`, `Volume_ft3`, `Power_W` |
| `get_total_avionics_volume_component_buildup` | none | net volume [ft^3], 19.8849; the same per-box table |
| `get_fuselage_volume` | none | raw fuselage internal volume [ft^3], 764.0820 |
| `get_fuselage_fuel_volume_available` | none | raw x packaging factor [ft^3], 611.2656 |
| `get_wing_fuel_volume_available` | none | wing fuel volume [ft^3], 55.0161 |
| `get_total_fuel_volume_available` | none | wing + fuselage usable [ft^3], 666.2817 |
| `get_total_fuel_volume_occupied` | `fuel_weight_lb` | fuel volume [ft^3] |
| `get_design_total_volume` | none | wing fuel + raw fuselage [ft^3], 819.0981 |
| `fuel_volume_from_weight` | `fuel_weight_lb` | errors, §5 |
| `fuel_volume_check` | none | errors, §5 |

`get_fuselage_volume` denormalizes `geom.frames_normalized` by `geom.L_fus`,
`geom.W_max_fuselage`, `geom.H_max_fuselage`, then calls
`SubsystemsL3.compute_volume_from_control_stations`. It is the fuselage volume only; it does not add
avionics or gear-bay volume.

`get_wing_fuel_volume_available` reads `S_ref`, `b_wing`, `tc_r_wing`, `tc_t_wing` and
`lambda_wing` off `geom` and calls `SubsystemsL2.compute_wing_fuel_volume_roskam`.

## 4. Avionics component buildup

One JSON entry per box, each carrying a Table 8.8 `category` plus whatever weight, volume or power
has been sourced.

**Any ONE sourced figure resolves a box**, because Table 8.8 inverts in every direction. A sourced
figure is never overwritten by an estimate. A box with no `category` keeps only what the JSON gives
it. A `"a + b"` category is one box holding both functions, so its known quantity splits evenly
between the two rows.

A box with nothing sourced reads `NaN` and drops out of the net.

| Net | Boxes resolved | Value |
|---|---|---|
| Weight | 11 of 17 | 1081.0925 lbf |
| Volume | 10 of 17 | 19.8849 ft^3 |

Six boxes have no sourced figure at all: HF radio, TACAN, radar altimeter, FLCC, SMS and threat
warning system. The chaff/flare programmer makes the volume net one box shorter still: it has a
sourced weight but no `category`, so Table 8.8 cannot give it a volume.

Over the resolved set the implied density is 54.37 lb/ft^3, above Nicolai's flat 45 and above
Raymer's 30 to 45 range. The fire control radar drives it, at 79.9 lb/ft^3 from two sourced
figures.

`avionics_parts` builds the table both methods read. Two private statics support it: `box` resolves
one component; `attempt` returns `NaN` where a fit has no valid inverse.

## 5. Broken members

Two methods delegate to `SubsystemsL3` entry points the toolbox does not provide.

| Member | Error |
|---|---|
| `fuel_volume_from_weight` | `SubsystemsL3` has no static of that name |
| `fuel_volume_check` | the static takes two scalars; the design object is passed |

Neither is in the abstract contract, so neither blocks instantiation. `get_total_fuel_volume_occupied`
already does what `fuel_volume_from_weight` was for, and `SubsystemsL3.fuel_volume_check` works when
it is given `(required, available)`.

## 6. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| 9/11/2026 | DONE 9/15/2026. Add `get_avionics_volume_component_buildup` | landed as `get_total_avionics_volume_component_buildup`, the name `SubsystemsModelL3` declares |
| 9/11/2026 | Add `get_total_power_load` | `F16SubsystemsL3.m:120`, methods block |
| 9/11/2026 | DONE 9/15/2026. Rename to `get_avionics_volume_component_buildup` | same target as the entry above |
| 9/11/2026 | Rename to `get_total_internal_volume` | now `get_fuselage_volume`; the name says fuselage, so the rename may be moot |
| 9/15/2026 | `get_design_total_volume` adds a wing FUEL volume to a raw fuselage volume | no wing internal-volume equation is cited in this repository; `F16SubsystemsL2` mixes the same two |
| 9/15/2026 | The JSON `packaging_factor_category` is loaded and never read | `F16SubsystemsL3.m:83` sets it; `:118` uses `fuselage_packaging_factor_category` instead |

