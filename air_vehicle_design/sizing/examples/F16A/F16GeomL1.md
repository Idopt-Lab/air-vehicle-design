# F16GeomL1

F-16A Block 10 Level-1 geometry concrete class (`classdef F16GeomL1 < GeometryModelL1`). Every
abstract method is a single delegation line into the `GeomL1` static toolbox; no equations are
duplicated here. L1 is a statistical/regression tier, so the only JSON inputs are classification
scalars — no numeric planform dimensions exist at this tier.

## Constructor
`F16GeomL1(json_path, req_path)` — **both paths required**, no silent default (a short call errors,
`MATLAB:minrhs`). Typically `F16GeomL1(f16a_spec_path(1), f16a_requirements_path())`.

- `json_path` → the spec file `examples/F16A/f16a_L1.json`. Supplies the one canonical top-level
  `aircraft_category`. (The same file's `.aerodynamics` block feeds `F16AeroL1`.)
- `req_path` → `examples/F16A/f16a_requirements.json`. Supplies `design_mach`, which becomes
  `M_max`. Added Phase 4 (2026-07-25): the design max Mach is a *requirement*, not airframe spec
  data, and it previously existed in three places. `f16a_L1.json .geometry.M_max` was deleted and
  this is now its single source — a consolidation, not a removal, since `M_max` still drives
  `get_AR_eq`.

`S_ref` is not a JSON input; it stays the hardcoded 300 ft² literal (see the table below).

## Properties

**Inputs** — plain, mutable; set once by the constructor:

| Property | Value | Notes |
|----------|-------|-------|
| `aircraft_category` | `"jet_fighter"` | drives GeomL1 table lookups; from the spec file's top-level key |
| `S_ref` | `300` ft^2 | T.O. 1F-16A-1, Fig. 1-2; not a JSON input |
| `M_max` | `2.0` | design max Mach; drives `get_AR_eq`. From `f16a_requirements.json .design_mach` |
| `W_TO` | `NaN` | lbf. A genuine L1 **input**: both regressions below are functions of TOGW, which geometry cannot know at this fidelity. The sizing loop mutates it between iterations |

**Derived** (`Dependent`) — recomputed live on every read, no stored copy:

| Property | Computes | Source |
|----------|----------|--------|
| `S_wet` | total wetted area from `W_TO` | Roskam Vol. I, Table 3.5 regression |
| `L_fuselage` | fuselage length from `W_TO` | Raymer 6th ed., Table 6.3 regression |

Both **error** (not return a placeholder) while `W_TO` is unset. They were plain properties frozen
at `0` and commented "populated by `get_S_wet(obj, W_TO)`" — but `get_S_wet` only ever *returned* a
value, it never assigned, so both sat at `0` for the object's whole life. Injecting an `F16GeomL1`
into `F16AeroL2`/`F16AeroL3` then produced `CD0 = Cfe·0/S_ref = 0` — silent zero parasite drag and
infinite L/D, with no warning. Converted to `Dependent` 2026-07-25.

## Methods

| Method | Delegates to | Source |
|--------|--------------|--------|
| `get_S_ref(obj)` | property accessor | — |
| `get_S_wet(obj, W_TO)` / `get_S_wet_statistical(obj, W_TO)` | `GeomL1.get_S_wet_statistical` | Roskam Vol. I, Table 3.5 |
| `get_L_fus(obj, W_TO)` | `GeomL1.get_L_fus` | Raymer 6th ed., Table 6.3 |
| `get_AR_eq(obj)` | `GeomL1.get_AR_eq` | Raymer 7th ed., Table 4.1 (dogfighter row) |

`S_ref` cannot be estimated from geometry alone at L1; the class carries a TODO to find a better
L1 estimation workflow for `S_ref`.
