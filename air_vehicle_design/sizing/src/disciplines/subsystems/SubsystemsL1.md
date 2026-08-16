# SubsystemsL1

Level-1 subsystems static toolbox (`classdef SubsystemsL1`, `methods (Static)` only). Called as
`SubsystemsL1.method(...)`; never instantiated and not in the inheritance chain. `F16SubsystemsL1`
inherits `SubsystemsModelL1` and delegates here.

**L1 is a pure tabulation tier**: no geometry, no injected collaborators. Methods that need an
external weight (avionics `W_empty`, a required fuel weight) take it as an explicit argument,
exactly as `F16WeightsL1.OEW(obj, W_TO)` takes `W_TO` rather than injecting a weights object.

`avionics_weight_fraction`, `avionics_density`, `fuel_density`, `fuselage_raw_volume` and
`fuel_volume` are the shared abstract contract on `src/base/SubsystemsBase.m`, not declared per
fidelity level. `fuselage_raw_volume`/`fuel_volume` are honestly 0 here: L1 has no fuselage or
fuel-bay geometry to compute them from.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object (+ an explicit weight) | `avionics_weight_fraction`, `avionics_density`, `avionics_weight`, `avionics_volume`, `fuel_density`, `fuselage_raw_volume`, `fuel_volume`, `fuel_volume_from_weight`, `internal_volume`, `fuel_volume_check` |
| Low-level — scalars/strings only | `lookup_fuel_density`, `lookup_fuel_density_lb_per_gal`, `lookup_avionics_weight_fraction_range`, `lookup_avionics_weight_fraction` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `avionics_weight_fraction(obj)` | fraction of `W_empty` | Raymer 6th ed. Table 11.6, p.375 |
| `avionics_density(obj)` | lb/ft³ (~37.5, Raymer range average) | Raymer 6th ed. Ch.11 p.375 prose |
| `avionics_weight(obj, W_empty)` | lbf | fraction × `W_empty` |
| `avionics_volume(obj, W_empty)` | ft³ | `weight_to_volume` |
| `fuel_density(obj)` | lb/ft³ | Nicolai & Carichner Table 8.6, p.210 |
| `fuel_volume_from_weight(obj, fuel_weight_lb)` | ft³ | `fuel_weight_lb / fuel_density` — NO packaging factor at L1 |
| `fuselage_raw_volume(obj)` | ft³ | **honestly 0** — no fuselage geometry exists at L1 |
| `fuel_volume(obj)` | ft³ | **honestly 0** — no fuel-bay geometry exists at L1, same rationale as `fuselage_raw_volume` |
| `internal_volume(obj, W_empty)` | ft³ | = `avionics_volume` only (no fuel/gear-bay geometry exists yet) |
| `fuel_volume_check(obj, required_weight_lb)` | struct | `available_vol_ft3` honestly reported as 0 (no bay geometry); `required_vol_ft3` computed via density; `sufficient` true only when `required_vol_ft3 <= 0` |

## 3. Equations

**Avionics weight and volume** — Raymer 6th ed. Table 11.6 + following-paragraph prose:

$$W_{avionics} = f_{avionics}(cat) \cdot W_{empty} \qquad
  V_{avionics} = \frac{W_{avionics}}{\rho_{avionics,L1}}$$

$f_{avionics}$ is the Table 11.6 row's range midpoint. $\rho_{avionics,L1} = 37.5$ lb/ft³ is the
average of Raymer's stated 30–45 lb/ft³ range — L1's figure, distinct from L2/L3's flat Nicolai
45 lb/ft³.

**Fuel volume from weight** — Nicolai & Carichner Table 8.6:

$$V_{fuel} = \frac{W_{fuel}}{\rho_{fuel}(type)}$$

No packaging factor: item 1's status is "not usable at L1 — no geometric raw volume exists yet."

## 4. Coefficients

`lookup_fuel_density` / `lookup_fuel_density_lb_per_gal` — Nicolai & Carichner Table 8.6, p.210:

| Fuel type | lb/gal | lb/ft³ |
|---|---|---|
| JP-4 | 6.5 | 48.6 |
| JP-5 | 6.8 | 51.1 |
| JP-8 | 6.7 | 50.0 |
| Aviation gas | 6.0 | 44.9 |

F-16 example uses **JP-8** — T.O. 1F-16A-1's stated nominal internal-fuel type
(`usaf_f16_data.md:86`).

`lookup_avionics_weight_fraction_range` — Raymer 6th ed. Table 11.6, p.375, full 8-row table:

| Category | Range |
|---|---|
| General aviation-single engine | 0.01–0.03 |
| Light twin | 0.02–0.04 |
| Turboprop transport | 0.02–0.04 |
| Business jet | 0.04–0.05 |
| Jet transport | 0.01–0.02 |
| Fighters | 0.03–0.08 |
| Bombers | 0.06–0.08 |
| Jet trainers | 0.03–0.04 |

F-16 example uses the **Fighters** row, midpoint **0.055**.

Every lookup errors (`SubsystemsL1:unknownFuelType` / `SubsystemsL1:unknownAvionicsCategory`) for an
unlisted category rather than guessing.

## 5. To-dos

None at L1. The two genuine citation gaps (battery volumetric density, gear bay-volume packaging)
live at L2/L3 (`SubsystemsL2.md` §5) — neither is reachable through this toolbox.
