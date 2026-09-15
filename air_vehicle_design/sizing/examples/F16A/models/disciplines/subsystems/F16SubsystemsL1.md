# F16SubsystemsL1

F-16A Block 10/15 Level-1 subsystems class (`classdef F16SubsystemsL1 < SubsystemsModelL1`).
Equations live in `SubsystemsL1` and `SubsystemsBase`; see their companion docs.

Every member works. L1 is tabulation only, so there is no geometry and no available volume.

---

## 1. Inputs

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L1.json` `.subsystems.fuel.fuel_type` |
| `avionics_table_row` | `'Fighters'` | `f16a_L1.json` `.subsystems.avionics.aircraft_category_table_row` |
| `fuel_weight_source` | injected, **optional** | a `WeightsBase`; supplies `W_energy` and `get_OEW(W_TO)` |

Constructor `F16SubsystemsL1(json_path, fuel_weight_source)`. The path is required; the collaborator
is not.

**The optional collaborator is deliberate**, and it is the one place this class departs from the
L2/L3 "every argument required" rule. `subsystems_brandt_comparison` builds an L1 object and then
feeds it Brandt's weights as call arguments; a required collaborator would force it to inject
numbers it does not want. Without the collaborator the two volume getters read `NaN`, never a wrong
number.

## 2. Derived properties

Five `Dependent` getters, recomputed on read.

| Property | Value | Needs the collaborator? |
|---|---|---|
| `avionics_weight_fraction` | 0.0550 | no |
| `avionics_density` | 37.5 lb/ft^3 | no |
| `fuel_density` | 50.0 lb/ft^3 | no |
| `total_fuel_volume_occupied` | 100.4384 ft^3 | yes, `W_energy` |
| `total_avionics_volume_occupied` | 24.4056 ft^3 | yes, `get_OEW(W_TO)` |

## 3. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_avionics_weight_fraction` | none | fraction of `W_empty` |
| `get_avionics_weight_categorical` | `W_empty` [lbf] | avionics weight [lbf] |
| `get_avionics_volume_categorical` | `W_empty` [lbf] | avionics volume [ft^3] |
| `get_total_fuel_volume_occupied` | `fuel_weight_lb` | fuel volume [ft^3] |
| `fuel_volume_check` | `required_weight_lb` | struct: `available_vol_ft3`, `required_vol_ft3`, `sufficient` |

`SubsystemsModelL1` adds two concrete bridges, `get_avionics_weight(obj, W_empty)` and
`get_total_avionics_volume_occupied(obj, W_empty)`, which forward to the `_categorical` pair. Those
are what the sizing report calls.

## 4. Values at the converged L1 point

`W_TO` 26762.1 lbf, `OEW` 16640.2 lbf, `W_fuel` 5021.9 lbf.

| Quantity | Value |
|---|---|
| Avionics weight | 915.21 lbf, 0.0550 of OEW |
| Avionics volume | 24.41 ft^3 at 37.5 lb/ft^3 |
| Fuel volume occupied | 100.44 ft^3 at 50.0 lb/ft^3 |
| Fuel volume available | 0 |

## 5. Judgment calls

**`fuel_volume_check` reports zero available volume, honestly.** L1 has no fuel-bay geometry, so
`sufficient` is false whenever any fuel is required. Injecting the weights object does not change
this: it is a geometry limit, not a weights one.

**No packaging factor is applied.** A packaging factor scales a raw geometric volume, and L1 has
none. `get_total_fuel_volume_occupied` returns the volume the fuel itself occupies.

**`get_avionics_weight_categorical` repeats the lookup-and-mean** that
`get_avionics_weight_fraction` already does, rather than calling it. The two agree.

**`avionics_density` reads 37.5 and that is correct here.** See `SubsystemsL1.md` §4 for the
name collision with L2's 45.
