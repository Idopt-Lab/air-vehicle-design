# F16SubsystemsL1

F-16A Block 10/15 Level-1 subsystems student class (`classdef F16SubsystemsL1 < SubsystemsModelL1`).
Every abstract method is a single delegation line into the `SubsystemsL1` static toolbox — no
equations are duplicated here. See `src/disciplines/subsystems/SubsystemsL1.md` for the full
equation/citation detail; this file covers only the F-16-specific wiring.

---

## 1. Role

Tabulation-only estimate of avionics volume and (weight-only) fuel volume, with **no geometry** and
**no injected collaborators** — the only Subsystems tier with neither.

## 2. Inputs (2)

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L1.json` `.subsystems.fuel.fuel_type` — T.O. 1F-16A-1's own stated nominal internal-fuel type |
| `avionics_table_row` | `'Fighters'` | `f16a_L1.json` `.subsystems.avionics.aircraft_category_table_row` — Raymer 6th ed. Table 11.6 |

Neither the JSON's echoed `density_lb_per_gal`/`weight_fraction`/`density_lb_per_ft3` numeric values
are read directly — only the SELECTOR strings are, matching the `AeroL1.to_CLmax_table_row`
JSON/code split (full lookup tables live in `SubsystemsL1`'s code, not the JSON). The echoed numbers
are a human-readable cross-check that the code's own lookup produces the same figure.

## 3. Derived (5 `Dependent` properties + 3 methods)

**CORRECTED (matlab-oop-expert review, 2026-08-03):** an earlier draft of this file claimed "0
DERIVED, mirrors F16WeightsL1" for every quantity on this class. That is only true of the three
quantities that take a genuine *external* weight argument (`avionics_weight`, `avionics_volume`,
`fuel_volume_from_weight` — these correctly stay methods, exactly like `F16WeightsL1.OEW(obj, W_TO)`,
since `W_empty`/`fuel_weight_lb` is not `obj`'s own stored state and there is nothing to cache).
`avionics_weight_fraction`, `avionics_density`, and `fuel_density` take **zero** extra arguments and
read only `obj`'s own stored `avionics_table_row`/`fuel_type` — the same "self-contained, no external
argument" shape as `F16GeomL2`'s Dependent getters, so they are now `properties (Dependent)`, and
`SubsystemsModelL1` declares them as abstract properties (not abstract methods).

| Member | Kind |
|---|---|
| `avionics_weight_fraction` | Dependent property |
| `avionics_density` | Dependent property |
| `fuel_density` | Dependent property |
| `fuselage_raw_volume` | Dependent property — honestly 0 (no fuselage geometry at L1) |
| `fuel_volume` | Dependent property — honestly 0 (no fuel-bay geometry at L1) |
| `avionics_weight(W_empty)` | Method (external argument) |
| `avionics_volume(W_empty)` | Method (external argument) |
| `fuel_volume_from_weight(fuel_weight_lb)` | Method (external argument) |
| `internal_volume(W_empty)` | Method (Tier-1 orchestrator contract) |
| `fuel_volume_check(required_weight_lb)` | Method (Tier-1 orchestrator contract) |

## 4. Constructor

`F16SubsystemsL1(json_path)` — reads `.subsystems.fuel.fuel_type` and
`.subsystems.avionics.aircraft_category_table_row` from a required unified L1 input JSON
(`f16a_spec_path(1)`). No silent default.

## 5. Judgment calls

None beyond what `SubsystemsL1.md` already documents (the L1/L2 avionics-density fidelity split, the
"shallow vs. deep fuselage" packaging-factor ambiguity, and the two hard citation gaps) are specific
to this F-16 wiring — this class's own contribution is limited to which JSON keys it reads.
