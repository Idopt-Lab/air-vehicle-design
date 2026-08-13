# F16SubsystemsL3

F-16A Block 10/15 Level-3 subsystems student class (`classdef F16SubsystemsL3 < SubsystemsModelL3`).
Every abstract method is a single delegation line into the `SubsystemsL3` static toolbox — no
equations are duplicated here. Identical shape and identical judgment calls to `F16SubsystemsL2`
(see that class's companion doc for the full `fuel_weight_source` and "gear bay volume not
auto-summed" rationale) — the only substantive difference is `geom` typed to `GeometryModelL3`
instead of `GeometryModelL2`, which changes `fuselage_raw_volume`'s `A_top`/`A_side` source from
`GeomL2`'s envelope ellipse to `GeomL3`'s frame-integrated station table.

---

## 1. Role

Same as `F16SubsystemsL2` — see that file. Every equation is level-agnostic and reused by
`SubsystemsL3` directly from `SubsystemsL2`, except the fuselage raw-volume term.

**Derived-property shape (2026-08-03 correction, see `F16SubsystemsL2.md` §4 for the full
rationale):** `avionics_weight_fraction`, `avionics_density`, `avionics_weight`, `avionics_volume`,
`fuel_density`, `fuselage_raw_volume`, `fuselage_usable_fuel_volume`, `wing_fuel_volume`, and
`fuel_volume` are `properties (Dependent)` on this class (not methods) — each reads only `obj`'s own
stored inputs/injected collaborators with zero extra arguments. `fuel_volume` sums THIS class's own
`fuselage_usable_fuel_volume`/`wing_fuel_volume` (frame-integrated fuselage term), deliberately not
delegated to `SubsystemsL2.fuel_volume`, which would silently substitute L2's envelope-ellipse term.
`battery_volume`, `fuel_volume_from_weight`, `internal_volume`, and `fuel_volume_check` remain methods
(external argument, or Tier-1 orchestrator contract).

## 2. Inputs (3) + 2 injected objects

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L3.json` `.subsystems.fuel.fuel_type` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L3.json` `.subsystems.fuel.packaging_factor_category` |
| `avionics_table_row` | `'Fighters'` | `f16a_L3.json` `.subsystems.avionics.aircraft_category_table_row` |
| `geom` | injected | `(1,1) GeometryModelL3` — supplies `frames_normalized`, `L_fuselage`, `W_max_fuselage`, `H_max_fuselage` (fuselage-volume term) and `S_ref`, `b_wing`, `tc_r_wing`, `tc_t_wing`, `lambda_wing` (wing-volume term, identical member names to `GeometryModelL2`) |
| `fuel_weight_source` | injected | `(1,1) WeightsBase` — see `F16SubsystemsL2.md` §3 for the full rationale (typically an `F16WeightsL3` instance in practice) |

## 3. Judgment calls

Identical to `F16SubsystemsL2.md` §3 (`fuel_weight_source` typing) and §5 (landing-gear bay volume
not auto-summed) — nothing new is introduced at this tier beyond the fuselage raw-volume source
swap, which the original step-9 design itself directs ("refined by GeomL3's station data instead of
GeomL2's envelope approximation").

## 4. Constructor

`F16SubsystemsL3(json_path, geom, fuel_weight_source)` — all three REQUIRED, no silent default.
