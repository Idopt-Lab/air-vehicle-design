# F16GeomL2

F-16A Block 10/15 Level-2 geometry, the Brandt-reference tier. `classdef F16GeomL2 <
GeometryModelL2`. The class assembles the aircraft. It calls `GeomL2` statics for each equation, and
it holds no equation twice.

This is the **reference implementation of the INPUT vs DERIVED pattern** every Tier-3 class follows.
Inputs are a plain mutable block of design-variable spec data. Derived quantities are `Dependent`
getters. They recompute on every read. No value is stored or cached, so a derived value cannot go
stale. When an optimizer changes an input, the next dependent read shows the change. Derived
properties are read-only. An assignment to one gives an error, which is correct.

---

## 1. Constructor

```matlab
g2 = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
```

`F16GeomL2(json_path, prop)`. Both arguments are necessary. There is no default. A short call gives
`MATLAB:minrhs`.

| Argument | Supplies |
|---|---|
| `json_path` | `f16a_L2.json` `.geometry` block. The `.aerodynamics` block of the same file feeds `F16AeroL2` |
| `prop` | `prop (1,1) PropulsionBase`. The class reads only `prop.T_SL` |

**Geometry takes a propulsion object.** Engine SLS thrust sizes the nacelle diameter, and the
nacelle diameter sets the duct wetted area and the duct CD0. Thrust is engine data, not airframe
data. A default injection would freeze that thrust again. That is the defect this removes: `D_inlet`
was pinned to a stored copy, so a sizing loop that increased thrust gave too little duct drag.

**L2 does not read the requirements file.** Only `F16GeomL1` and `F16GeomL3` take a `req_path`.

---

## 2. Inputs

Plain mutable `properties`, set once from the JSON. Most cite Brandt `Main`-tab cells. The root and
tip t/c values cite T.O. 1F-16A-1 §I.

| Group | Properties | Values |
|---|---|---|
| Wing | `S_ref`, `AR_wing`, `lambda_wing`, `LE_sweep_wing`, `tc_wing` | 300 ft², 3.0, 0.2275, 40°, 0.04 |
| HT | `S_ht`, `AR_ht`, `lambda_ht`, `LE_sweep_ht`, `tc_r_ht`, `tc_t_ht` | 108 ft² (**full** planform), 3.0, 0.2275, 40°, 0.060 / 0.035 |
| VT | `S_vt`, `AR_vt`, `lambda_vt`, `LE_sweep_vt`, `tc_r_vt`, `tc_t_vt` | 60 ft² (**full**), 1.6, 0.5, 40°, 0.053 / 0.030 |
| Fuselage | `L_fus`, `W_max_fuselage`, `H_max_fuselage` | 46.5, 7.0, 5.0 ft |
| Whole aircraft | `L_aircraft` | 47.65 ft, the **overall** length. It feeds only the Eq. 12.44 `(Amax/l)²` term. It is not `L_fus`. Do not confuse the two |
| Duct | `L_duct` | 14.0 ft, a true airframe input, unlike engine thrust |
| Engine count | `n_engines` | 1. No L2 geometry equation uses it. It is exposed so that mission analysis can read `geom.n_engines` at every tier |
| Injected | `prop` | not numeric spec data |

There is **no `tc_ht` or `tc_vt` input**. The root and tip pair is the one t/c basis, and the uniform
value comes from it. There is **no `T_AB_SLS_lb` input**. It is `Dependent` on `prop.T_SL`.

**Control-surface areas are a second plain block**: `S_ail`, `S_elev` and `S_rud`, each `NaN`. They
are not `Dependent`, because this object's own inputs give no closed form. `ControlSurfaceSizer`
writes them after the sizing loop converges.

`properties (Constant)`: `mainwheel_S_front`, `nosewheel_S_front`. Declared, unused.

---

## 3. Derived (`Dependent`)

| Group | Properties | Source |
|---|---|---|
| Wing | `b_wing`, `c_root_wing`, `c_tip_wing`, `cbar_wing`, `QC_sweep_wing`, `TE_sweep_wing`, `tc_r_wing`, `tc_t_wing`, `S_exposed_wing` | Raymer 7th ed. Eq. 7.6/7.7/7.8; `convert_sweep`. `tc_r_wing` and `tc_t_wing` mirror `tc_wing`, because Brandt gives one uniform value |
| HT | `b_ht`, `c_root_ht`, `c_tip_ht`, `QC_sweep_ht`, `TE_sweep_ht`, `tc_ht`, `S_exposed_ht` | as the wing. `tc_ht` is the mean of the root and tip pair, 0.0475 |
| VT | `b_vt`, `c_root_vt`, `c_tip_vt`, `QC_sweep_vt`, `TE_sweep_vt`, `tc_vt`, `S_exposed_vt` | `b_vt` is the **full single-panel** span. It is not halved. The sweeps use `convert_sweep_panel` (2/AR), **not** the mirrored wing and HT form. `tc_vt` is 0.0415 |
| Fuselage | `L_fuselage`, `D_fus`, `Amax`, `S_wet_fuselage` | `L_fuselage` mirrors `L_fus`, a duplicate name the abstract contract needs. `D_fus` is `(W_max+H_max)/2`. `Amax` is `(π/4)·W·H`, from the class's own `compute_Amax_elliptical`. `S_wet_fuselage` is Roskam Vol. II Eq. 12.3 |
| Duct | `T_AB_SLS_lb`, `D_inlet`, `D_exit`, `S_wet_duct` | `T_AB_SLS_lb` is `prop.T_SL`. `D_inlet` is `sqrt(T/1900)`, from the class's own `compute_nacelle_diameter`. `D_exit` equals `D_inlet`, a constant-diameter cylinder |
| Per surface | `S_wet_wing`, `S_wet_ht`, `S_wet_vt` | `GeomL2.compute_S_wet_planform_roskam`, one call each, on that surface's exposed area, root/tip t/c and taper |
| Total | `S_wet` | the sum of five components. See §4 |

**The per-surface wetted areas are properties again**, reversed 2026-08-24. `S_wet_wing`,
`S_wet_ht`, `S_wet_vt` and `S_wet_duct` were deleted in the gate-2 pass; Casey put them back. Each
getter calls the toolbox with explicit arguments, so the toolbox still takes no design object:

```matlab
function v = get.S_wet_wing(obj)
    v = GeomL2.compute_S_wet_planform_roskam(obj.S_exposed_wing, ...
            obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
end
```

A consumer may read `g2.S_wet_wing` again, or call the static directly. Both give the same number.

Chords use Raymer 7th ed. Eq. 7.6/7.7/7.8 through `GeometryBase`. `QC_sweep_wing` is computed,
32.183178°, not the hardcoded 37° of an earlier version. `D_fus` is a judgment call. It is Brandt's
low-fidelity equivalent-diameter convention, and it feeds the Roskam Eq. 12.3 fuselage formula,
because the JSON gives only width and height.

---

## 4. Methods

| Method | Does |
|---|---|
| `get_S_ref(obj)` | returns `obj.S_ref` |
| `get_design_S_wet_components(obj)` | assembles the total wetted area from five `GeomL2` calls |
| `get_S_exposed_wing(obj)` | `GeomL2.compute_S_exposed_horizontal`. The enforcer contract needs it |

`get_design_S_wet_components` takes no `W_TO` argument, unlike L1. It calls
`compute_S_wet_planform_roskam` three times, once per surface, then `compute_s_wet_fus_cyl` and
`compute_s_wet_duct`, and returns the sum. `GeometryModelL2.get_S_wet` forwards to it, so
`g2.S_wet` and `g2.get_S_wet()` give the same number.

Citations: Roskam Vol. II Eq. 12.1 for the surfaces, Eq. 12.3 for the fuselage, Raymer 6th ed. §7.3
for the duct.

Two `methods (Static)` moved into this class from `GeometryBase` on 2026-08-19, because the F-16
example is the only caller:

| Static | Equation |
|---|---|
| `compute_nacelle_diameter(T_AB_SLS_lb)` | `sqrt(T/1900)` [Brandt `Engn(s)`] |
| `compute_Amax_elliptical(W, H)` | `(π/4)·W·H`, the plain ellipse identity |

### As-built values

Verified 2026-08-21. **No value has changed.**

| Quantity | Value | | Quantity | Value |
|---|---|---|---|---|
| `cbar_wing` | 11.320179 ft | | `S_exposed_wing` | 196.22607 ft² |
| `QC_sweep_wing` | 32.183178° | | `S_exposed_ht` | 49.847251 ft² |
| `b_ht` | 18.0 ft | | `S_exposed_vt` | 40.889669 ft² |
| `QC_sweep_vt` / `TE_sweep_vt` | 36.313393° / 22.900799° | | `D_fus` | 6.0 ft |
| `S_wet` wing / HT / VT | 396.37666 / 101.38789 / 83.139828 ft² | | `Amax` | 27.488936 ft² |
| `S_wet_fuselage` | 730.30232 ft² | | `D_inlet` | 3.5370222 ft |
| duct `S_wet` | 155.56636 ft² | | **`S_wet`** | **1466.7731 ft²** |

The three per-surface areas are readable as properties or as direct
`GeomL2.compute_S_wet_planform_roskam` calls. Both paths give the numbers above.

---

## 5. To-dos

| Item | Guard |
|---|---|
| **Nothing sizes the control effectors at L2.** `get_control_effectors_size` is commented out on this class AND on `GeometryModelL2`, so the contract no longer demands it and no code calls it. The block is finding a suitable L2 method: no statistical one exists in Raymer, Nicolai or Roskam. `ControlSurfaceSizer` handles it with chord fractions, and the Nicolai Ch. 23 criteria method waits for L3 | this doc |
| `get_S_ref` returns `obj.S_ref` and does not mutate its argument. Casey's idea for it: repurpose it into a wrapper that recomputes the main wing's geometry | this doc |
| `get.L_fuselage` mirrors `L_fus` only because the abstract contract needs the name. It does not mutate the input | this doc |
| `get_design_S_wet_components` names its five locals after properties of the same name, so `checkcode` gives three "Did you mean to reference it?" warnings. The code is correct, because every local is assigned before it is read | `checkcode` |
| `L_aircraft` = 47.65 ft is approved as the published airframe length (47 ft 7.75 in), but the **citation is not pinned**. No overall-length figure appears anywhere in `sizing/`. Brandt `Geom!B21` = 48.303947 does not pin it, because that is a `MAX()` over his x-stations, an extent and not a spec length | todo §6 |
| `compute_Amax_elliptical` is a standard elliptical identity with no equation number. Pin a citation, or accept the standard-identity status in writing | this doc |
| `D_fus` as `(W+H)/2` is a convention choice, not a cited formula | in-code note |
| `compute_nacelle_diameter` hardcodes 1900. That value assumes an afterburning engine (Brandt uses 2000 when `T_dry = T_AB`). Approved as an exception on 2026-08-19, because Raymer, Nicolai and Roskam give no substitute. **A reference scan is owed** | this doc |
| `mainwheel_S_front` and `nosewheel_S_front` are declared and unused | — |
| `S_ail`, `S_elev` and `S_rud` stay `NaN` until `ControlSurfaceSizer` writes them. Nothing enforces that order | — |
