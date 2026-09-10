# F16SubsystemsL2

F-16A Block 10/15 Level-2 subsystems class (`classdef F16SubsystemsL2 < SubsystemsModelL2`).
Geometry-derived fuel and avionics volumes. Equations live in `SubsystemsL2`; see
`src/disciplines/subsystems/SubsystemsL2.md`.

---

## 1. Inputs

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L2.json` `.subsystems.fuel.fuel_type` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L2.json` `.subsystems.fuel.packaging_factor_category` |
| `avionics_table_row` | `'Fighters'` | `f16a_L2.json` `.subsystems.avionics.aircraft_category_table_row` |
| `fuselage_packaging_factor_category` | `'Integral tank — shallow fuselage'` | class default, not read from JSON |
| `wing_packaging_factor_category` | `'Integral tank — wing'` | class default, not read from JSON |
| `geom` | injected `(1,1) GeometryModelL2` | wing planform and fuselage envelope |
| `fuel_weight_source` | injected `(1,1) WeightsBase` | `W_energy` and `W_TO`/`OEW` |

Constructor `F16SubsystemsL2(json_path, geom, fuel_weight_source)`, all three required, no default.

`fuel_weight_source` is typed to the `WeightsBase` enforcer, not to `F16WeightsL2`, so one
collaborator supplies both the required fuel weight and `W_empty`.

## 2. Derived properties

Nine `Dependent` getters, recomputed on read: `avionics_weight_fraction`, `avionics_density`,
`avionics_weight`, `avionics_volume`, `fuel_density`, `fuselage_raw_volume`,
`fuselage_usable_fuel_volume`, `wing_fuel_volume`, `fuel_volume`. `SubsystemsModelL2` declares
`avionics_weight`, `avionics_volume` and `wing_fuel_volume` abstract.

## 3. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_total_avionics_weight_statistical` | `W_empty` [lbf] | avionics weight [lbf], Table 11.6 midpoint x `W_empty` |
| `get_total_avionics_volume_statistical` | `W_empty` [lbf] | avionics volume [ft^3] at 45 lb/ft^3 |
| `get_wing_fuel_volume_available` | none | wing fuel volume [ft^3] |
| `get_fuselage_internal_volume` | none | raw fuselage volume [ft^3], no packaging factor |
| `get_total_fuel_volume_available` | none | wing + packaged fuselage fuel volume [ft^3] |
| `get_internal_volume` | `W_empty` [lbf] | wing fuel + raw fuselage volume [ft^3] |
| `battery_volume` | `E_required_kWh` | always errors, citation gap |
| `fuel_volume_from_weight` | `fuel_weight_lb` [lbf] | volume [ft^3] at `fuel_density` |
| `internal_volume` | none | total internal volume [ft^3] |
| `fuel_volume_check` | none | struct: available, required, sufficient |

The avionics weight fraction is the Table 11.6 range midpoint, 0.055 for `Fighters`, not the low
end. Both avionics methods use `SubsystemsL1`'s fraction lookup and weight equation, since no L2
equivalent exists, but the density is L2's own 45 lb/ft^3.

## 4. Landing-gear bay volume is not summed

`F16LandingGearL2.bay_volume()` always errors: no textbook tire and strut stowage formula exists in
this repo. Summing it would make every internal-volume call fail. A caller who wants the term calls
that method directly and adds it.

## 5. Known breakage

The class constructs, but these members do not run yet.

| Member | Fault |
|---|---|
| `get_wing_fuel_volume_available` | reads `obj.S_ref_wing`, `obj.b_wing`, `obj.tc_r_wing`, `obj.tc_t_wing`, `obj.lambda_wing`; they belong to `obj.geom`, and the first is `S_ref` there |
| `get_fuselage_internal_volume` | reads `obj.L_fus`, `obj.W_max`, `obj.H_max`; they belong to `obj.geom`, and the last two are `W_max_fuselage` / `H_max_fuselage` |
| `get_internal_volume` | fails through `get_wing_fuel_volume_available`. Also omits the avionics term the `SubsystemsBase` contract requires, and mixes raw fuselage volume with usable wing volume |
| `get_total_fuel_volume_available` | calls `obj.get_wing_fuel_volume()`, which is now `get_wing_fuel_volume_available` |
| `get_total_avionics_weight_statistical`, `get_total_avionics_volume_statistical` | take `W_empty`, but the `SubsystemsModelL2` bridges call them with no argument |
| `fuel_volume_from_weight`, `internal_volume`, and all nine getters | delegate to `SubsystemsL2` statics that no longer exist |
| `fuel_volume_check` | passes `obj` to a static that now takes two scalars. Returns a struct with the object in `required_vol_ft3` rather than erroring |

`fuselage_packaging_factor_category` and `wing_packaging_factor_category` have no reader.
