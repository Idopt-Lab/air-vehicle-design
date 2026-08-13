# F16SubsystemsL2

F-16A Block 10/15 Level-2 subsystems student class (`classdef F16SubsystemsL2 < SubsystemsModelL2`).
Every abstract method is a single delegation line into the `SubsystemsL2` static toolbox — no
equations are duplicated here. See `src/disciplines/subsystems/SubsystemsL2.md` for the full
equation/citation detail; this file covers the F-16-specific wiring and the design decisions the
original step-9 subsystems design left open.

---

## 1. Role

Geometry-derived fuel/avionics volume estimate: fuselage-internal raw volume off the injected L2
geometry's envelope ellipse, wing-internal volume off the wing planform, avionics volume off a
weight fraction of `W_empty`.

## 2. Inputs (3) + 2 injected objects

| Property | Value | Source |
|---|---|---|
| `fuel_type` | `'JP-8'` | `f16a_L2.json` `.subsystems.fuel.fuel_type` |
| `packaging_factor_category` | `'Integral tank — shallow fuselage'` | `f16a_L2.json` `.subsystems.fuel.packaging_factor_category` |
| `avionics_table_row` | `'Fighters'` | `f16a_L2.json` `.subsystems.avionics.aircraft_category_table_row` |
| `geom` | injected | `(1,1) GeometryModelL2` — supplies `S_ref`, `b_wing`, `tc_r_wing`, `tc_t_wing`, `lambda_wing` (wing-volume term) and `L_fuselage`, `W_max_fuselage`, `H_max_fuselage` (fuselage-volume term) |
| `fuel_weight_source` | injected | `(1,1) WeightsBase` — see §3 below |

## 3. Judgment call: `fuel_weight_source`

The original step-9 subsystems design names this constructor argument
`fuel_weight_source` and says it may be "mission analysis or `F16WeightsL2` — pick whichever exposes
it most directly," without pinning down which. **No mission-analysis discipline exists in this repo
yet.** `F16WeightsL2`/`F16WeightsL3` already expose BOTH quantities this class needs:

- `W_energy` (STATE — the required internal-fuel weight, set by mission analysis once it lands),
  used by `fuel_volume_check`.
- `OEW(W_TO)` (via `W_TO`, also STATE), used as `W_empty` for the avionics-weight term.

**Decision**: type the injected argument as `(1,1) WeightsBase` (the abstract Tier-1 enforcer, not
`F16WeightsL2` concretely) so one collaborator serves both roles, matching the DI-guard convention
used elsewhere (guard at the tier that declares the members actually read — here, `WeightsBase`
declares both `W_energy` and `W_TO`/`OEW`). This avoids injecting two separate weights-shaped objects
into one discipline for what is really one underlying "the current candidate weights state" concept.

## 4. Derived

**CORRECTED (matlab-oop-expert review, 2026-08-03):** an earlier draft of this file implemented every
derived quantity as a plain method and documented that as deliberate, reasoning by analogy to
`F16WeightsL1`'s "OEW stays a METHOD" precedent. That analogy does not hold here: OEW stays a method
because it takes an *externally-varying* argument (`W_TO`, a candidate the sizing loop iterates over,
not `obj`'s own stored state) — the exact same reason `battery_volume(E_required_kWh)` below stays a
method. The other eight quantities take **zero extra arguments** and read **only** `obj`'s own stored
inputs / injected collaborators (`fuel_type`, `avionics_table_row`, `geom`, `fuel_weight_source`) —
structurally identical to `F16WeightsL2`'s `W_wings`/`W_tail`/`W_fuselage`/... split, which *is*
implemented as `properties (Dependent)` there. Per CLAUDE.md's "Optimization-ready property design"
doctrine, these eight are now `properties (Dependent)` getters on `F16SubsystemsL2`, and
`SubsystemsModelL2` now declares them as abstract **properties** rather than abstract methods (mirroring
`WeightsModelL2`'s `W_wings` abstract-property / `weight_wing(obj, W_TO)` abstract-method split).
`battery_volume`, `internal_volume`, and `fuel_volume_check` remain methods — the first two reasons
below, the last two because they are the Tier-1 orchestrator contract declared on `SubsystemsBase`.

| Member | Kind | Formula |
|---|---|---|
| `avionics_weight_fraction` | Dependent property | Raymer Table 11.6 midpoint, 0.055 |
| `avionics_density` | Dependent property | 45 lb/ft³ [Nicolai Sec.8.1.11] |
| `avionics_weight` | Dependent property | fraction × `fuel_weight_source.OEW(fuel_weight_source.W_TO)` |
| `avionics_volume` | Dependent property | weight / density |
| `fuel_density` | Dependent property | 50.0 lb/ft³ [Nicolai Table 8.6, JP-8] |
| `fuselage_raw_volume` | Dependent property | Raymer Eq. 7.14 |
| `fuselage_usable_fuel_volume` | Dependent property | raw × 0.80 packaging factor |
| `wing_fuel_volume` | Dependent property | Roskam Eq. 6.2/6.3 |
| `fuel_volume` | Dependent property (added 2026-08-03, `SubsystemsBase`) | `fuselage_usable_fuel_volume + wing_fuel_volume` — `fuel_volume_check`'s own `available_vol_ft3` figure, exposed as a named property |
| `fuel_volume_from_weight(fuel_weight_lb)` | Method (added 2026-08-03, `SubsystemsBase`) | `fuel_weight_lb / fuel_density` — the definitional conversion `fuel_volume_check` uses for `required_vol_ft3`; same signature at every level, no packaging factor |
| `battery_volume(E_required_kWh)` | Method | **ALWAYS ERRORS** — citation GAP; stays a method both because it takes a genuine external argument and because a Dependent getter must never be allowed to throw (MATLAB's object-display machinery evaluates every Dependent getter eagerly) |
| `internal_volume()` | Method (Tier-1 contract) | `fuel_volume() + avionics_volume()` (gear bay NOT summed, see §5) |
| `fuel_volume_check()` | Method (Tier-1 contract) | `fuel_volume()` vs. `fuel_volume_from_weight(fuel_weight_source.W_energy)` |

## 5. Judgment call: landing-gear bay volume is NOT auto-summed into `internal_volume()`

The original step-9 design's goal ("producing a bay volume that also feeds the internal-volume total") is
aspirational and blocked on item 11's citation gap — `F16LandingGearL2.bay_volume()` always errors
(no textbook tire+strut stowage-volume formula exists anywhere in this repo). Auto-summing an
always-erroring term into `internal_volume()` would make every call to `internal_volume()` fail hard,
defeating the purpose of shipping the fuel/avionics volume estimate now. **Decision**: `internal_volume()`
sums only the two modeled terms (fuel + avionics); a caller wanting the gear-bay contribution once
item 11 is resolved should call `F16LandingGearL2.bay_volume()` directly and add it in.

## 6. Constructor

`F16SubsystemsL2(json_path, geom, fuel_weight_source)` — all three REQUIRED, no silent default
(mirrors `F16WeightsL2`/`F16GeomL2`'s DI convention — a defaulted injection would silently re-freeze
geometry or weights data).
