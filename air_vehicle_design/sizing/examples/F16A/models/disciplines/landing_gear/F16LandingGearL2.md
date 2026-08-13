# F16LandingGearL2

F-16A Block 10/15 Level-2 landing-gear student class (`classdef F16LandingGearL2 < handle`,
**F-16-only, no abstract Base/Model tier** — docs/subplans/09_subsystems.md Files to Create). Not
every airframe has conventional landing gear, so this discipline does not get a generic
`src/disciplines/` home the way Geometry/Aerodynamics/Propulsion/Weights/Subsystems do.

**CORRECTED (matlab-oop-expert review, 2026-08-03): `< handle` added.** This class was originally a
plain MATLAB value class — every other stateful discipline class in `examples/F16A/` gets `handle`
semantics transitively via its Base/Model tier, but this class has none, so the omission was silent.
Without `handle`, mutating `main_pct`/`nose_pct`/etc. on an instance passed into a function would not
propagate back to the caller, breaking the "optimizer mutates the object in place" doctrine
(CLAUDE.md "Optimization-ready property design") this whole framework depends on.

---

## 1. Role

Raymer 6th ed. Ch.11 statistical tire sizing (Table 11.1, p.344) off the per-wheel static load,
itself derived from the 90%/10% gear load split (p.344 prose) applied to the injected weights
object's `W_TO`.

| Layer | Members |
|---|---|
| High-level — `Dependent` property getters reading `obj` + injected `weights`, zero extra arguments | `W_main_total`, `W_nose_total`, `W_w_main`, `W_w_nose`, `tire_diameter_main`, `tire_width_main`, `tire_diameter_nose`, `tire_width_nose` |
| High-level — plain method (deliberately errors; a `Dependent` getter must never throw) | `bay_volume()` |
| Low-level (`Static`) — scalars/strings only | `tire_diameter`, `tire_width`, `lookup_tire_sizing_coeffs` |

**CORRECTED (matlab-oop-expert review, 2026-08-03):** the eight tire/load quantities above were
originally plain methods. Since each takes zero extra arguments and reads only `obj`'s own stored
inputs plus the injected `weights` collaborator, they are now `properties (Dependent)` getters,
matching `F16GeomL2`/`F16WeightsL2`'s "Optimization-ready property design" convention (CLAUDE.md).
`bay_volume` stays a plain method: it deliberately errors, and MATLAB's object-display machinery
evaluates every `Dependent` getter eagerly (e.g. `disp(obj)`), so an always-erroring member must not
be `Dependent`.

## 2. Inputs (4) + 1 injected object

| Property | Value | Source |
|---|---|---|
| `aircraft_category_table_row` | `'Jet fighter/trainer'` | `f16a_L2.json` `.subsystems.landing_gear.tire_sizing.aircraft_category_table_row` — Raymer Table 11.1 |
| `main_pct` | 90 | `.gear_load_split.main_pct` — Raymer Ch.11 p.344 prose |
| `nose_pct` | 10 | `.gear_load_split.nose_pct` |
| `nose_tire_fraction_of_main` | 0.80 | `.nose_tire_fraction_of_main` — decided midpoint of Raymer's stated 60–100% range |
| `weights` | injected | `(1,1) WeightsBase` — supplies `W_TO` |

As with `SubsystemsL2`'s fuel/avionics tables, the tire-sizing diameter/width coefficients
(`A_d`/`B_d`/`A_w`/`B_w`) are NOT read from the JSON's echoed numeric values — they are looked up via
`lookup_tire_sizing_coeffs(aircraft_category_table_row)`, which reproduces Raymer Table 11.1's full
4-row table in code.

## 3. Judgment calls

- **Two main wheels.** The F-16 uses a standard tricycle arrangement — one nose wheel, two main
  wheels — so Table 11.1's per-wheel load `W_w` is `main_pct·W_TO / 2`, not the full main-gear load.
  This is ordinary tricycle-gear configuration knowledge, not a subplan-pinned citation; documented
  as `N_MAIN_WHEELS = 2` / `N_NOSE_WHEELS = 1` class constants rather than left as a silent literal.
- **No geometry injection.** A future gear-bay-volume formula would need a fuselage envelope to place
  the bay into, but `bay_volume()` errors unconditionally regardless of any geometry access — wiring
  an unused `geom` collaborator now would violate CLAUDE.md's "no feature beyond what the current
  step requires." Add it when item 11 is resolved, not before.

## 4. Gear bay volume — NOT IMPLEMENTED (documented citation gap, item 11)

`bay_volume()` always errors with `F16LandingGearL2:bayVolumeNotAvailable`. No textbook formula for
tire+strut bay-volume packaging was found anywhere in this repo — Raymer's Ch.11 covers tire/strut/
shock-absorber SIZE, not a bay-VOLUME packaging estimate the way Nicolai's Ch.8 fuel/avionics
sections give one. Tire/strut SIZE (`tire_diameter_main`/`tire_width_main`/etc.) is fully implemented
and unaffected.

## 5. Comparison data (informational, not a validation target)

`VnV/BrandtF16A/GroundTruth/f16a_subsystems_ground_truth.json`'s `landing_gear_tire_diameter` block
gives `d_nose_ft=1.5` (18 in) / `d_main_ft=2.0` (24 in) from a Brandt "Gear tab" cell with two
carried-forward provenance caveats (undocumented cell reference; its consuming code implies a
26.7%/73.3% load split that contradicts both Raymer's 90/10 and Nicolai's own "20% nose" rule of
thumb). Usable as a comparison-report data point only, never as a silently-trusted target — see that
JSON file's own caveats for the full record.

## 6. Constructor

`F16LandingGearL2(json_path, weights)` — both REQUIRED, no silent default.
