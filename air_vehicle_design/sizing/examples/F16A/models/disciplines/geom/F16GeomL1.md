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

`M_max` is a design **requirement**, not airframe spec data. It drives `get_AR_eq`.

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
| `AR_eq` | equivalent aspect ratio from `M_max` | Raymer 7th ed. Table 4.1 |
| `c_e` | elevator chord ratio | Raymer 7th ed. Table 6.5 |
| `c_r` | rudder chord ratio | Raymer 7th ed. Table 6.5 |

`S_wet` and `L_fuselage` **error** (via the private `requireWTO`) while `W_TO` is unset, rather than 
returning a placeholder. 

---

## 4. Methods

| Method | Delegates to | Source |
|---|---|---|
| `get_S_ref(obj)` -- property getter |  |  |
| `get_whole_aircraft_S_wet_statistical(obj, W_TO)` | `GeomL1.compute_s_wet_regression` | Roskam Vol. I, Table 3.5 |
| `get_L_fus_statistical(obj, W_TO)` | `GeomL1.compute_l_fus_regression` | Raymer 6th ed., Table 6.3 |
| `get_AR_eq(obj)` | `GeomL1.compute_AR_eq` | Raymer 7th ed., Table 4.1, dogfighter row |
| `get_c_e(obj)` | `GeomL1.lookup_control_surface_fraction` | Raymer 7th ed., Table 6.5 |
| `get_c_r(obj)` | `GeomL1.lookup_control_surface_fraction` | Raymer 7th ed., Table 6.5 |

### As-built values

At `W_TO` = 31,377 lbf:

| Quantity | Value |
|---|---|
| `S_wet` | 1763.0171 ft² |
| `L_fuselage` | 52.742584 ft |
| `get_AR_eq` | 3.518664 |
| `c_e` | 0.3 |
| `c_r` | 0.33 |

---

## 5. To-dos

| Item | Guard |
|---|---|
| `S_ref` cannot be estimated from geometry alone at L1 — it is a hardcoded literal. Find a better L1 estimation workflow, or a student-facing way to derive it | in-code TODO |
| L1 aileron-area fraction is not available | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
