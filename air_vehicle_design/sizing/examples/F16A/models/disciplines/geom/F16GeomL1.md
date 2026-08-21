# F16GeomL1

F-16A Block 10/15 Level-1 geometry. `classdef F16GeomL1 < GeometryModelL1`. Each method makes one
call into the `GeomL1` static toolbox. The class holds no equation.

**L1 is a statistical and regression tier.** There are no planform dimensions. Wetted area and
fuselage length are regressions on takeoff gross weight, so the JSON inputs are classification
scalars only.

---

## 1. Constructor

```matlab
g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
```

`F16GeomL1(json_path, req_path)`. Both paths are necessary. There is no default. A short call gives
`MATLAB:minrhs`.

| Argument | Supplies |
|---|---|
| `json_path` | `f16a_L1.json`. Gives the one canonical top-level `aircraft_category`, and `n_engines` when the key is present |
| `req_path` | `f16a_requirements.json`. Gives `design_mach`, which becomes `M_max` |

`M_max` is a design **requirement**, not airframe spec data. It drives `get_AR_eq`. A requirement
does not change with fidelity, so it comes from a separate file.

`S_ref` is not a JSON input. The constructor sets the 300 ft² literal.

The constructor reads `n_engines` behind an `isfield` guard. When the key is absent, the property
keeps its single-engine default.

---

## 2. Inputs

| Property | Value | Meaning and citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | drives every `GeomL1` table lookup |
| `S_ref` | 300 ft² | [T.O. 1F-16A-1, Fig. 1-2]. Not a JSON input |
| `M_max` | 2.0 | design max Mach, feeds `get_AR_eq`. From `f16a_requirements.json` `.design_mach` |
| `n_engines` | 1 | engine count [Brandt `Main!B28`]. No L1 regression uses it. It is exposed so that mission analysis can read `geom.n_engines` at every tier |
| `W_TO` | `NaN` lbf | a true L1 input. Both regressions below are functions of TOGW, which geometry cannot know at this tier. The sizing loop writes it on each iteration |

`S_ref` and `M_max` also carry property defaults, and the constructor overwrites both. `SizingLoopL1`
then overwrites `S_ref` again on each iteration with `W0 / WS`, so at L1 `S_ref` is loop state.

---

## 3. Derived (`Dependent`)

| Property | Computes | Citation |
|---|---|---|
| `S_wet` | total wetted area from `W_TO` | Roskam Vol. I Table 3.5 |
| `L_fuselage` | fuselage length from `W_TO` | Raymer 6th ed. Table 6.3 |
| `AR_eq` | equivalent aspect ratio from `M_max` | Raymer 7th ed. Table 4.1 |
| `c_e` | elevator chord ratio | Raymer 7th ed. Table 6.5 |
| `c_r` | rudder chord ratio | Raymer 7th ed. Table 6.5 |

`S_wet` and `L_fuselage` **give an error** while `W_TO` is unset. The private `requireWTO` raises
`F16GeomL1:WTONotSet`. A named error is safer than a placeholder zero, which would travel into an
injected aero object as zero parasite drag.

`c_e` and `c_r` share one method. Each getter calls `get_control_effectors_size` and keeps one of
its two outputs, so each read also computes the other ratio and discards it. At L1 that costs one
table read.

---

## 4. Methods

| Method | Calls | Source |
|---|---|---|
| `get_design_S_wet_categorical(obj, W_TO)` | `GeomL1.compute_s_wet_regression` | Roskam Vol. I Table 3.5 |
| `get_L_fus_categorical(obj, W_TO)` | `GeomL1.compute_l_fus_regression` | Raymer 6th ed. Table 6.3 |
| `get_AR_eq(obj)` | `GeomL1.compute_AR_eq` | Raymer 7th ed. Table 4.1, dogfighter row |
| `get_control_effectors_size(obj)` | `GeomL1.lookup_control_surface_fraction`, twice | Raymer 7th ed. Table 6.5 |
| `get_S_ref(obj)` | returns `obj.S_ref` | — |
| `requireWTO(obj, whatFor)` | private guard on `obj.W_TO` | — |

**Each `compute_*` static now takes the category and does its own lookup.** The design class makes
one call, not two. An earlier version passed coefficients, so the class chose the table row. Both
shapes work. This one puts the row choice inside the toolbox.

`get_control_effectors_size` returns two values, `[elevator, rudder]`. `GeometryModelL1` declares it
abstract with one output. MATLAB does not check the count, so the class runs, but a caller who writes
`val = g1.get_control_effectors_size()` gets the elevator ratio alone.

`GeometryModelL1` holds a concrete `get_S_wet(obj, W_TO)` that forwards to
`get_design_S_wet_categorical`. So `g1.get_S_wet(W_TO)` and the direct call give the same number,
and a new L1 geometry writes one method, not two.

### As-built values

Verified 2026-08-21. **No value has changed.**

At `W_TO` = 31,377 lbf:

| Quantity | Value |
|---|---|
| `S_wet` | 1763.0171 ft² |
| `L_fuselage` | 52.742584 ft |
| `AR_eq` | 3.518664 |
| `c_e` | 0.30 |
| `c_r` | 0.33 |
| `get_S_ref` | 300.0 ft² |

With `W_TO` unset, `S_wet` raises `F16GeomL1:WTONotSet`, as designed.

---

## 5. To-dos

| Item | Guard |
|---|---|
| `S_ref` cannot come from geometry alone at L1. It is a literal. Find a better L1 workflow, or a student-facing way to derive it | in-code TODO |
| The L1 aileron chord fraction is not available. Raymer Table 6.5 has no aileron column. **Raymer Fig. 6.3 does**, and the extract holds its six digitized points, so this gap is closable | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
| `GeomL1.lookup_swet`: the `military_cargo` row holds the coefficients of Roskam's Regional Turboprops row. The `jet_bomber` pair matches no printed row and no reference extract. No current example uses either row | `GeomL1.md` §4a |
| Eight of the twelve rows of Roskam Table 3.5 are absent from `lookup_swet`. `lookup_AR_eq` and `lookup_control_surface_fraction` are also partial | out of scope for this pass |
| `get_control_effectors_size` declares one output on the enforcer and returns two on the class | — |
