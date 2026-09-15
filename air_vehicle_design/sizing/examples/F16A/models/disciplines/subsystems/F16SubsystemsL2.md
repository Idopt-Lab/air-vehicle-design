# F16SubsystemsL2

F-16A Block 10/15 Level-2 subsystems class (`classdef F16SubsystemsL2 < SubsystemsModelL2`).
Equations live in `SubsystemsL2`, `SubsystemsL1` and `SubsystemsBase`; see their companion docs.

Every member works. L2 is the first tier with real geometry, so available fuel volume exists here.

---

## 1. Inputs

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L2.json` `.subsystems.fuel.fuel_type` |
| `avionics_table_row` | `'Fighters'` | `f16a_L2.json` `.subsystems.avionics.aircraft_category_table_row` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L2.json` `.subsystems.fuel.packaging_factor_category` |
| `fuselage_packaging_factor_category` | `'Integral tank — shallow fuselage'` | class default. **Unused.** |
| `wing_packaging_factor_category` | `'Integral tank — wing'` | class default. **Unused.** |
| `geom` | injected `(1,1) GeometryModelL2` | wing planform and fuselage envelope |
| `fuel_weight_source` | injected `(1,1) WeightsBase` | `W_energy` and `get_OEW(W_TO)` |

Constructor `F16SubsystemsL2(json_path, geom, fuel_weight_source)`, all three required, no default.

Both injections are required here, unlike L1, because no L2 quantity is computable without geometry.

## 2. Derived properties

Nine `Dependent` getters, recomputed on read.

| Property | Value | Reads |
|---|---|---|
| `avionics_weight_fraction` | 0.0550 | `avionics_table_row` |
| `avionics_density` | 37.5 lb/ft^3 | `SubsystemsL2.AVIONICS_DENSITY` |
| `avionics_weight` | 781.0460 lbf | `get_OEW(W_TO)` |
| `total_avionics_volume_occupied` | 20.8279 ft^3 | `avionics_weight`, `avionics_density` |
| `fuel_density` | 50.0 lb/ft^3 | `fuel_type` |
| `fuselage_fuel_volume` | 682.6682 ft^3 | `geom`, packaging factor |
| `wing_fuel_volume` | 55.0161 ft^3 | `geom` |
| `total_design_volume` | 908.3513 ft^3 | `geom` |
| `total_fuel_volume_occupied` | 116.1840 ft^3 | `W_energy` |

At `W_TO` 23279.4 lbf, `OEW(W_TO)` 14200.84 lbf, `W_energy` 5809.2 lbf.

## 3. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_avionics_weight_fraction` | none | fraction of `W_empty` |
| `get_avionics_weight_categorical` | `W_empty` [lbf] | avionics weight [lbf] |
| `get_total_avionics_volume_categorical` | `W_empty` [lbf] | avionics volume [ft^3] |
| `get_wing_fuel_volume_available` | none | wing fuel volume [ft^3] |
| `get_fuselage_internal_volume` | none | raw fuselage volume [ft^3], 853.3352 |
| `get_fuselage_fuel_volume` | none | raw x packaging factor [ft^3] |
| `get_fuel_volume_available` | none | wing + fuselage usable [ft^3], 737.6843 |
| `get_total_fuel_volume_occupied` | `fuel_weight_lb` | fuel volume [ft^3] |
| `get_total_design_volume` | none | wing fuel + raw fuselage [ft^3] |
| `get_fuel_density` | none | fuel density [lb/ft^3] |
| `fuel_volume_check` | `fuel_weight_lb` | struct: `available_vol_ft3`, `required_vol_ft3`, `sufficient` |

`fuel_volume_check(5809.2)` gives required 116.18, available 737.68, sufficient.

## 4. A getter cannot take an argument

A getter's one argument IS the object: MATLAB fills that slot with the instance whatever the
parameter is named. So any quantity needing a weight reads it off an injected collaborator instead.
`get.total_fuel_volume_occupied` reads `fuel_weight_source.W_energy`; `get.avionics_weight` reads
`ws.get_OEW(ws.W_TO)`.

Verified live rather than cached: mutating `W_energy` from 5809.2 to 7000 moves
`total_fuel_volume_occupied` to exactly 140.0000 ft^3, which is 7000 / 50.

## 5. Judgment calls

**Four quantities have two working routes.** `avionics_weight` and
`total_avionics_volume_occupied` exist as getters reading the injected weights object and as
`_categorical` methods taking `W_empty`. Both give the same answer.
`avionics_weight_fraction` and `wing_fuel_volume` likewise duplicate a method body rather than
calling it.

**`total_design_volume` sums two different quantities.** It adds
`get_wing_fuel_volume_available`, a FUEL volume, to `get_fuselage_internal_volume`, a RAW structural
volume: 55.02 + 853.34 = 908.35 ft^3. Its property comment describes a third thing again.

**Landing-gear bay volume is not summed into any volume here.** `F16LandingGearL2.bay_volume`
errors on a citation gap, so a caller wanting the gear contribution adds it.

**`avionics_density` is 37.5, not Nicolai's 45.** `SubsystemsL2.AVIONICS_DENSITY` duplicates
`SubsystemsL1`'s Raymer range average. Nothing in the repository reaches Nicolai's flat 45.

## 6. The SubsystemsModelL2 bridges are unreached

`SubsystemsModelL2` supplies two concrete bridges, `get_avionics_weight` and
`get_total_avionics_volume_occupied`. Both are broken: the first calls
`get_total_avionics_weight_categorical`, a name that exists nowhere, and the second calls a
one-argument method with no argument.

Neither has a caller. The three call sites using those names hold an `F16SubsystemsL1` object, which
inherits the working L1 versions. They are unreached dead code in the enforcer, not a defect in the
L2 path.
