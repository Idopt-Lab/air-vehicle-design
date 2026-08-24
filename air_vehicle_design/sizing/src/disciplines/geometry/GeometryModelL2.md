# GeometryModelL2

Tier-2 abstract enforcer for Level-2 geometry. `classdef (Abstract) GeometryModelL2 <
GeometryBase`. It holds no equation. It states the contract that every L2 geometry must meet.

**The contract is aircraft-agnostic**, slimmed on 2026-08-15. It names only the L2 geometry that
every aircraft supplies and that cross-discipline consumers read. Detailed drag-build-up geometry
(per-surface t/c, sweeps, duct, `Amax`, `L_aircraft`) is not agnostic, so it stays concrete on
`F16GeomL2`.

**This is an enforcer, so it has no constructor, no input properties and no derived properties.** A
concrete class supplies the inputs as plain properties and the derived quantities as `Dependent`
getters. See `F16GeomL2.md` for the reference implementation.

Implementers: `F16GeomL2`, `B777GeomL2`.

---

## 1. Abstract properties

MATLAB does not accept validation attributes on an abstract property. The first concrete class
enforces size and type.

| Property | Meaning | Read by |
|---|---|---|
| `b_wing` | wing span [ft] | tail-volume and tail-sizing |
| `S_exposed_wing` | exposed wing planform [ft²] | L2 weights build-up |

Five more are declared and commented out, because not every design has them: `L_fuselage`, `S_ht`,
`S_vt`, `S_exposed_ht`, `S_exposed_vt`. `S_ht` and `S_vt` were the write-back slots that the
tail-sizing object sets inside the sizing loop.

## 2. Abstract methods

| Method | Meaning |
|---|---|
| `get_S_exposed_wing(obj)` | wing exposed area [ft²] |

`get_control_effectors_size(obj)` is declared and commented out. See §5.

## 3. Concrete methods

| Method | Does |
|---|---|
| `get_S_wet(obj)` | forwards to `obj.get_design_S_wet_components()` |

The bridge gives one home for the total. `GeometryBase` declares `get_S_wet` abstract, so this
method satisfies it, and a new L2 geometry writes `get_design_S_wet_components` only.

## 4. As-built values

Verified 2026-08-24 on `F16GeomL2`. The enforcer holds no equation, so every value comes from the
concrete class.

| Read through the enforcer | Value |
|---|---|
| `get_S_wet()` | 1466.7730567 ft² |
| `get_S_exposed_wing()` | 196.2260692 ft² |
| `b_wing` | 30.0 ft |

## 5. To-dos

| Item | Guard |
|---|---|
| **No abstract method sizes the control effectors.** `get_control_effectors_size` is commented out here and on `F16GeomL2`, so nothing demands it and nothing calls it. Control-effector sizing sits at L1 and L2, and `ControlSurfaceSizer` does the work with chord fractions. The block is that no statistical L2 method exists in Raymer, Nicolai or Roskam; the Nicolai Ch. 23 criteria method waits for L3 | this doc |
| **`get_design_S_wet_components` is not declared abstract**, but the concrete `get_S_wet` above calls it. A class that omits it fails at the call, not at construction | this doc |
| The name `get_design_S_wet_components` says components, and it returns one total | this doc |
| `L_fuselage` is commented out of the abstract set, so the tail arm has no enforced source at L2. `F16GeomL2` still supplies it | this doc |
