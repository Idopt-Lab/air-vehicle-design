# SubsystemsBase

Tier-1 abstract enforcer (`classdef (Abstract) SubsystemsBase < handle`) for every subsystems
discipline class. It declares two volume properties and the two methods that produce them, and
holds the two fuel-density tables.

---

## 1. Inheritance

```
SubsystemsBase -> SubsystemsModelLN (abstract) -> F16SubsystemsLN (concrete)
```

Each `SubsystemsModelLN` inherits `SubsystemsBase` directly, not `SubsystemsModelL(N-1)`. The static
toolboxes are not in this chain; concrete classes delegate to them.

Landing gear is outside this chain entirely: not every airframe has conventional gear, so no
abstract tier exists for it.

## 2. Abstract properties

| Property | Meaning |
|---|---|
| `total_fuel_volume_occupied` | Volume the fuel takes up [ft^3], internal + external stores |
| `total_avionics_volume_occupied` | Volume the avionics take up [ft^3] |

## 3. Abstract methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_total_avionics_volume_occupied` | `obj` | avionics volume [ft^3] |
| `get_total_fuel_volume_occupied` | `fuel_density`, `energy_medium_weight` | fuel volume [ft^3] |

`get_total_fuel_volume_occupied` is declared with no `obj`, so an implementation must be `Static` or
the object lands in the `fuel_density` slot. It takes a density rather than a fuel type so that a
battery design can pass its own energy density through the same method.

## 4. Statics

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `lookup_fuel_density_lb_per_ft_3` | `fuel_type` | density [lb/ft^3] | Nicolai & Carichner Table 8.6, p.210 |
| `lookup_fuel_density_lb_per_gal` | `fuel_type` | density [lb/gal] | Nicolai & Carichner Table 8.6, p.210 |

| Fuel | lb/ft^3 | lb/gal |
|---|---|---|
| JP-4 | 48.6 | 6.5 |
| JP-5 | 51.1 | 6.8 |
| JP-8 | 50.0 | 6.7 |
| Aviation gas | 44.9 | 6.0 |

Both live here rather than in a toolbox because fuel density is level-agnostic: every tier reads the
same JP-8 number. The avionics equations are not, so they sit in `SubsystemsL1`.

An unknown fuel type errors with `SubsystemsL1:unknownFuelType`. The identifier still carries the
`SubsystemsL1` prefix even though the methods now live here.

## 5. Known issues

**`'BATTERY'` is an incomplete case in both lookups.** It is a placeholder for a future entry for electric aircraft. The intention is to be able to differentiate between electric and combustion-engine designs.
