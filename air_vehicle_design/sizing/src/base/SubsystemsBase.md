# SubsystemsBase

Tier-1 abstract enforcer (`classdef (Abstract) SubsystemsBase < handle`) for every subsystems
discipline class. It declares the energy medium, the two volume properties and the methods that
produce them, and holds the fuel and battery density tables.

---

## 1. Inheritance

```
SubsystemsBase -> SubsystemsModelLN (abstract) -> F16SubsystemsLN (concrete)
```

Each `SubsystemsModelLN` inherits `SubsystemsBase` directly. The static toolboxes are not in this
chain; concrete classes delegate to them.

Landing gear is outside this chain: not every airframe has conventional gear, so no abstract tier
exists for it.

## 2. Abstract properties

| Property | Meaning |
|---|---|
| `fuel_type` | Energy medium: `'hydrocarbon'` or `'battery'` |
| `fuel_name` | Fuel name, or battery chemistry |
| `total_fuel_volume_occupied` | Volume the energy medium takes up [ft^3], internal + external stores |
| `total_avionics_volume_occupied` | Volume the avionics take up [ft^3] |

The type/name split is what lets one design object describe either a combustion or an electric
aircraft. The lookups switch on `fuel_type` and select a row with `fuel_name`.

## 3. Abstract methods

| Method | Arguments | Outputs |
|---|---|---|
| `get_total_avionics_volume_occupied` | `obj` | avionics volume [ft^3] |
| `get_total_fuel_volume_occupied` | `fuel_density`, `energy_medium_weight` | energy-medium volume [ft^3] |

`get_total_fuel_volume_occupied` is declared with no `obj`, so an implementation must be `Static` or
the object lands in the `fuel_density` slot. It takes a density rather than a fuel type so that a
battery design can pass its own energy density through the same method.

## 4. Statics

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `lookup_fuel_density_lb_per_ft_3` | `fuel_type`, `fuel_name` | lb/ft^3 or Wh/ft^3 | Nicolai & Carichner Table 8.6 p.210; Raymer 6th ed. Table 20.1 p.748 |
| `lookup_fuel_density_lb_per_gal` | `fuel_type`, `fuel_name` | lb/gal or Wh/gal | same two tables |

**The two branches return different dimensions.** `hydrocarbon` gives a mass density;
`battery` gives a volumetric energy density. The function names say `lb_per_`, which is accurate for
the hydrocarbon branch only.

### 4.1 Hydrocarbon

[Nicolai & Carichner Table 8.6, p.210]

| Fuel | lb/ft^3 | lb/gal |
|---|---|---|
| JP-4 | 48.6 | 6.5 |
| JP-5 | 51.1 | 6.8 |
| JP-8 | 50.0 | 6.7 |
| Aviation gas | 44.9 | 6.0 |

### 4.2 Battery

[Raymer 6th ed. Table 20.1, p.748], "Energy Density" column. Stored as printed in Wh/L, converted at
28.316846592 L/ft^3 and 3.785411784 L/gal.

| Chemistry | Wh/L | kWh/ft^3 | kWh/gal |
|---|---|---|---|
| Lead-acid | 100 | 2.832 | 0.379 |
| Alkaline | 300 | 8.495 | 1.136 |
| NiFe | 30 | 0.850 | 0.114 |
| NiCd | 150 | 4.248 | 0.568 |
| NiH | 60 | 1.699 | 0.227 |
| NiMH | 300 | 8.495 | 1.136 |
| NiZn | 280 | 7.929 | 1.060 |
| Li-ion | 250-700 | 13.451 | 1.798 |
| Li-ion Polymer | 250-730 | 13.875 | 1.855 |
| LiFePO4 | 170 | 4.814 | 0.644 |
| LiNiMnCoO2 (NMC) | 500 | 14.158 | 1.893 |
| Li-S | 250 | 7.079 | 0.946 |
| Licerion (US) | 1000 | 28.317 | 3.785 |
| Li-titanate | 170 | 4.814 | 0.644 |
| Li-air | 200 | 5.663 | 0.757 |
| Na-ion | 50 | 1.416 | 0.189 |
| Molten salt | 290 | 8.212 | 1.098 |
| Silver Zinc | 700 | 19.822 | 2.650 |

Chemistry names are Table 20.1's printed spellings. Li-ion and Li-ion Polymer print ranges, so they
use the midpoint, as `AVIONICS_DENSITY` does with Raymer's 30 to 45 range.

**`LiCoO2` and `LiMn2O4` error.** Table 20.1 prints a dash in their energy-density column. They give
a specific energy only, so no volume can be derived without fabricating a coefficient.

Raymer's comparison rows (wood, coal, jet fuel, gasoline, LH2, uranium, antimatter) are not
implemented. They are scale context, not selectable power supplies.

## 5. Errors

| Identifier | Raised when |
|---|---|
| `SubsystemsL1:unknownFuelName` | `fuel_type` is `hydrocarbon` and the name matches no Table 8.6 row |
| `SubsystemsBase:unknownBatteryChemistry` | `fuel_type` is `battery` and the name matches no Table 20.1 row |
| `SubsystemsBase:batteryEnergyDensityNotPrinted` | the chemistry is `LiCoO2` or `LiMn2O4` |
| `SubsystemsBase:unknownFuelType` | `fuel_type` is neither `hydrocarbon` nor `battery` |

`SubsystemsL1:unknownFuelName` keeps the `SubsystemsL1` prefix from before the method moved here.

## 6. Known issues

**Table 20.1 is approximate and cell-level.** Raymer dates it to 2018, calls the values "on the high
side of reported technology," and says they should be confirmed against current sources. A real pack
adds BMS, casing, cooling and cell spacing, and no pack factor is cited. The table's own jet-fuel
comparison row implies 56.8 lb/ft^3 against Nicolai's measured 50.0 for JP-8.

**The JSON key is `fuel_type` but holds a fuel name.** Every `f16a_L*.json` writes
`.subsystems.fuel.fuel_type = "JP-8"`, which the constructors read into `fuel_name`. The medium
comes from the class default.

## 7. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| 9/15/2026 | Rename the JSON key `.subsystems.fuel.fuel_type` to `fuel_name`, add an energy-medium key | `f16a_L1/L2/L3.json`, and the three constructors that read it |
| 9/15/2026 | The two lookups return mass density or energy density depending on the branch | function names say `lb_per_`; split the functions or rename them |
| 9/15/2026 | `SubsystemsL1:unknownFuelName` carries a stale class prefix | `SubsystemsBase.m` hydrocarbon branch |
