# F16GeomL1

F-16A Block 10 Level-1 geometry concrete class (`classdef F16GeomL1 < GeometryModelL1`). Every
abstract method is a single delegation line into the `GeomL1` static toolbox; no equations are
duplicated here. L1 is a statistical/regression tier, so the only JSON inputs are classification
scalars — no numeric planform dimensions exist at this tier.

## Constructor
`F16GeomL1(json_path)` requires a spec-file path (`f16a_spec_path(1)`) and reads the `.geometry`
block of `examples/F16A/f16a_L1.json`; the same file's `.aerodynamics` block feeds `F16AeroL1`.
There is no silent default — a no-argument call errors (`MATLAB:minrhs`). The constructor sets
`aircraft_category` and `M_max` from JSON; `S_ref` is set to the hardcoded 300 ft^2 literal.

## Properties

| Property | Value | Notes |
|----------|-------|-------|
| `aircraft_category` | `"jet_fighter"` | drives GeomL1 table lookups |
| `S_ref` | `300` ft^2 | T.O. 1F-16A-1, Fig. 1-2; not a JSON input |
| `S_wet` | `0` | populated on demand by `get_S_wet(obj, W_TO)` |
| `L_fuselage` | `0` | populated on demand by `get_L_fus(obj, W_TO)` |
| `M_max` | `2.0` | design max Mach; drives `get_AR_eq` |

## Methods

| Method | Delegates to | Source |
|--------|--------------|--------|
| `get_S_ref(obj)` | property accessor | — |
| `get_S_wet(obj, W_TO)` / `get_S_wet_statistical(obj, W_TO)` | `GeomL1.get_S_wet_statistical` | Roskam Vol. I, Table 3.5 |
| `get_L_fus(obj, W_TO)` | `GeomL1.get_L_fus` | Raymer 6th ed., Table 6.3 |
| `get_AR_eq(obj)` | `GeomL1.get_AR_eq` | Raymer 7th ed., Table 4.1 (dogfighter row) |

`S_ref` cannot be estimated from geometry alone at L1; the class carries a TODO to find a better
L1 estimation workflow for `S_ref`.
