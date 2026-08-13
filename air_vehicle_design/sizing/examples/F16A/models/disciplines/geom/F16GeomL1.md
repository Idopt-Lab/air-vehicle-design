# F16GeomL1

F-16A Block 10/15 Level-1 geometry. `classdef F16GeomL1 < GeometryModelL1`; every abstract method is
a one-line delegation into the `GeomL1` static toolbox.

**L1 is a statistical / regression tier.** There are no planform dimensions at all — wetted area and
fuselage length are regressions on takeoff gross weight, so the only JSON inputs are classification
scalars.

---

## 1. Constructor

```matlab
g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
```

`F16GeomL1(json_path, req_path)` — both paths required, no silent default (a short call errors
`MATLAB:minrhs`).

| Argument | Supplies |
|---|---|
| `json_path` | `f16a_L1.json` → the one canonical top-level `aircraft_category` |
| `req_path` | `f16a_requirements.json` → `design_mach`, which becomes `M_max` |

`M_max` is a design **requirement**, not airframe spec data. It previously existed in three places;
`f16a_L1.json .geometry.M_max` was deleted and the requirements file is now its single source — a
consolidation, not a removal, since `M_max` still drives `get_AR_eq`.

`S_ref` is not a JSON input; it stays a hardcoded literal.

---

## 2. Inputs

| Property | Value | Meaning / citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | drives the `GeomL1` table lookups |
| `S_ref` | 300 ft² | [T.O. 1F-16A-1, Fig. 1-2]; not a JSON input |
| `M_max` | 2.0 | design max Mach → `get_AR_eq`; from `f16a_requirements.json .design_mach` |
| `W_TO` | `NaN` lbf | A genuine L1 input: both regressions below are functions of TOGW, which geometry cannot know at this tier. The sizing loop mutates it between iterations |

## 3. Derived (`Dependent`)

| Property | Computes | Citation |
|---|---|---|
| `S_wet` | total wetted area from `W_TO` | Roskam Vol. I, Table 3.5 |
| `L_fuselage` | fuselage length from `W_TO` | Raymer 6th ed., Table 6.3 |

Both **error** (via the private `requireWTO`) while `W_TO` is unset, rather than returning a
placeholder. They were plain properties frozen at `0` and commented "populated by
`get_S_wet(obj, W_TO)`" — but `get_S_wet` only ever *returned* a value, never assigned, so both sat
at `0` for the object's whole life. Injecting an `F16GeomL1` into `F16AeroL2`/`L3` then produced
`CD0 = Cfe·0/S_ref = 0` — silent zero parasite drag and infinite L/D, with no warning.

---

## 4. Methods

| Method | Delegates to | Source |
|---|---|---|
| `get_S_ref(obj)` | property accessor | — |
| `get_S_wet(obj, W_TO)` / `get_S_wet_statistical(obj, W_TO)` | `GeomL1.get_S_wet_statistical` | Roskam Vol. I, Table 3.5 |
| `get_L_fus(obj, W_TO)` | `GeomL1.get_L_fus` | Raymer 6th ed., Table 6.3 |
| `get_AR_eq(obj)` | `GeomL1.get_AR_eq` | Raymer 7th ed., Table 4.1, dogfighter row |

### As-built values

At `W_TO` = 31,377 lbf:

| Quantity | Value |
|---|---|
| `S_wet` | 1763.0171 ft² |
| `L_fuselage` | 52.742584 ft |
| `get_AR_eq` | 3.518664 |

---

## 5. To-dos

| Item | Guard |
|---|---|
| `S_ref` cannot be estimated from geometry alone at L1 — it is a hardcoded literal. Find a better L1 estimation workflow, or a student-facing way to derive it | in-code TODO |
| L1 aileron-area fraction is not available | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
