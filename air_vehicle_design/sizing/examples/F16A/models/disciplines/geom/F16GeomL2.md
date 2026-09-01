# F16GeomL2

F-16A Block 10/15 Level-2 geometry, the Brandt-reference tier. `classdef F16GeomL2 <
GeometryModelL2`. The class assembles the aircraft. It calls `GeomL2` statics for each equation, and
it holds no equation twice.

This is the **reference implementation of the INPUT vs DERIVED pattern**. Inputs are a plain mutable
block of design-variable spec data; derived quantities are `Dependent` getters, recomputed on every
read and never cached, so they cannot go stale under an optimizer. Assigning to one errors.

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

**Geometry takes a propulsion object.** Engine SLS thrust sizes the nacelle diameter, which sets the
duct wetted area and CD0. Thrust is engine data, not airframe data. The defect this removes: a stored
`D_inlet` meant a sizing loop that raised thrust gave too little duct drag.

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

No `tc_ht` or `tc_vt` input: the root/tip pair is the one t/c basis. No `T_AB_SLS_lb` input either;
it is `Dependent` on `prop.T_SL`.

`S_ail`, `S_elev` and `S_rud` are a second plain block, each `NaN`. Not `Dependent`, because this
object's inputs give no closed form. `ControlSurfaceSizer` writes them after the loop converges.

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

Each per-surface `S_wet` getter calls the toolbox with explicit arguments, so the toolbox still takes
no design object. A consumer may read `g2.S_wet_wing` or call the static directly; both agree.

Chords use Raymer 7th ed. Eq. 7.6/7.7/7.8 through `GeometryBase`. `D_fus` is a judgment call:
Brandt's equivalent-diameter convention, feeding Roskam Eq. 12.3, because the JSON gives only width
and height.

---

## 4. Methods

| Method | Does |
|---|---|
| `get_S_ref(obj)` | returns `obj.S_ref` |
| `get_design_S_wet_components(obj)` | assembles the total wetted area from five `GeomL2` calls |
| `get_S_exposed_wing(obj)` | `GeomL2.compute_S_exposed_horizontal`. The enforcer contract needs it |

`get_design_S_wet_components` takes no `W_TO`, unlike L1. Three `compute_S_wet_planform_roskam` calls
plus `compute_s_wet_fus_cyl` and `compute_s_wet_duct`, summed. `GeometryModelL2.get_S_wet` forwards to
it, so `g2.S_wet` and `g2.get_S_wet()` agree. Citations: Roskam Vol. II Eq. 12.1 / 12.3, Raymer §7.3.

Two `methods (Static)` live here rather than in `GeometryBase`, because the F-16 is the only caller:

| Static | Equation |
|---|---|
| `compute_nacelle_diameter(T_AB_SLS_lb)` | `sqrt(T/1900)` [Brandt `Engn(s)`] |
| `compute_Amax_elliptical(W, H)` | `(π/4)·W·H`, the plain ellipse identity |

### As-built values

At the live F-16A L2 inputs:

| Quantity | Value | | Quantity | Value |
|---|---|---|---|---|
| `cbar_wing` | 11.320179 ft | | `S_exposed_wing` | 196.22607 ft² |
| `QC_sweep_wing` | 32.183178° | | `S_exposed_ht` | 49.847251 ft² |
| `b_ht` | 18.0 ft | | `S_exposed_vt` | 40.889669 ft² |
| `QC_sweep_vt` / `TE_sweep_vt` | 36.313393° / 22.900799° | | `D_fus` | 6.0 ft |
| `S_wet` wing / HT / VT | 396.37666 / 101.38789 / 83.139828 ft² | | `Amax` | 27.488936 ft² |
| `S_wet_fuselage` | 730.30232 ft² | | `D_inlet` | 3.5370222 ft |
| duct `S_wet` | 155.56636 ft² | | **`S_wet`** | **1466.7731 ft²** |



---

## 5. To-dos

| Item | Guard |
|---|---|
| **Nothing sizes the control effectors at L2.** `get_control_effectors_size` is commented out on this class and on `GeometryModelL2`, so nothing demands or calls it. The block is finding a suitable L2 method: no statistical one exists in Raymer, Nicolai or Roskam. `ControlSurfaceSizer` handles it with chord fractions, and the Nicolai Ch. 23 criteria method waits for L3 | this doc |
| `get_S_ref` returns `obj.S_ref` and does not mutate its argument. Casey's idea for it: repurpose it into a wrapper that recomputes the main wing's geometry | this doc |
| `get.L_fuselage` mirrors `L_fus` only because the abstract contract needs the name. It does not mutate the input | this doc |
| `get_design_S_wet_components` names its five locals after properties of the same name, so `checkcode` gives three "Did you mean to reference it?" warnings. The code is correct, because every local is assigned before it is read | `checkcode` |
| `L_aircraft` 47.65 ft is approved but its **citation is not pinned**. Brandt `Geom!B21` 48.303947 is a `MAX()` over x-stations, an extent, not a spec length | todo §6 |
| `compute_Amax_elliptical` is a standard elliptical identity with no equation number. Pin a citation, or accept the standard-identity status in writing | this doc |
| `D_fus` as `(W+H)/2` is a convention choice, not a cited formula | in-code note |
| `compute_nacelle_diameter` hardcodes 1900, which assumes an afterburning engine. Approved as an exception; Raymer, Nicolai and Roskam give no substitute. **A reference scan is owed** | this doc |
| `mainwheel_S_front` and `nosewheel_S_front` are declared and unused | — |
| `S_ail`, `S_elev` and `S_rud` stay `NaN` until `ControlSurfaceSizer` writes them. Nothing enforces that order | — |
