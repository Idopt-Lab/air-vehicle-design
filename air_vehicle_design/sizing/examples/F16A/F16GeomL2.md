# F16GeomL2

F-16A Block 10/15 Level-2 geometry — the Brandt-reference tier. `classdef F16GeomL2 <
GeometryModelL2`; every abstract method is a one-line delegation into the `GeomL2` / `GeometryBase`
statics, and no equation is duplicated here.

This is the **reference implementation of the INPUT vs DERIVED pattern** every Tier-3 class follows:
inputs are a plain mutable block of genuine design-variable spec data; derived quantities are
`Dependent` getters that recompute live on every read. There is no stored or cached copy, so a
derived value can never go stale — the instant an optimizer changes an input, every dependent read
reflects it. Derived properties are read-only; assigning to one errors, which is correct.

---

## 1. Constructor

```matlab
g2 = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
```

`F16GeomL2(json_path, prop)` — both arguments required, no silent default (a short call errors
`MATLAB:minrhs`).

| Argument | Supplies |
|---|---|
| `json_path` | `f16a_L2.json` `.geometry` block (the same file's `.aerodynamics` block feeds `F16AeroL2`) |
| `prop` | `prop (1,1) PropulsionBase` — only `prop.T_SL` is read |

**Geometry takes a propulsion object** because the nacelle diameter — and hence duct wetted area and
CD0 — is sized from engine SLS thrust, which is engine data, not airframe data. A defaulted
injection would silently re-freeze that thrust, which is the defect this removes: `D_inlet` used to
stay pinned to a stored copy, so a thrust-growing sizing loop under-predicted duct drag.

---

## 2. Inputs

Plain mutable `properties`, set once from the JSON. Most cite Brandt `Main`-tab cells; the root/tip
t/c splits cite T.O. 1F-16A-1 §I.

| Group | Properties | Values |
|---|---|---|
| Wing | `S_ref`, `AR_wing`, `lambda_wing`, `LE_sweep_wing`, `tc_wing` | 300 ft², 3.0, 0.2275, 40°, 0.04 |
| HT | `S_ht`, `AR_ht`, `lambda_ht`, `LE_sweep_ht`, `tc_r_ht`, `tc_t_ht` | 108 ft² (**full** planform), 3.0, 0.2275, 40°, 0.060 / 0.035 |
| VT | `S_vt`, `AR_vt`, `lambda_vt`, `LE_sweep_vt`, `tc_r_vt`, `tc_t_vt` | 60 ft² (**full**), 1.6, 0.5, 40°, 0.053 / 0.030 |
| Fuselage | `L_fus`, `W_max_fuselage`, `H_max_fuselage` | 46.5, 7.0, 5.0 ft |
| Whole aircraft | `L_aircraft` | 47.65 ft — **overall** length, feeds only the Eq. 12.44 `(Amax/l)²` term. Distinct from `L_fus`; do not conflate |
| Duct | `L_duct` | 14.0 ft — a genuine airframe input, unlike engine thrust |
| Injected | `prop` | not numeric spec data |

There is **no `tc_ht` / `tc_vt` input**: the root/tip split is the single t/c basis and the uniform
value is derived from it. There is **no `T_AB_SLS_lb` input**: it is `Dependent` on `prop.T_SL`.

`properties (Constant)`: `mainwheel_S_front`, `nosewheel_S_front` — declared, unused.

## 3. Derived (`Dependent`)

| Group | Properties | Source |
|---|---|---|
| Wing | `b_wing`, `c_root_wing`, `c_tip_wing`, `cbar_wing`, `QC_sweep_wing`, `TE_sweep_wing`, `tc_r_wing`, `tc_t_wing`, `S_exposed_wing`, `S_wet_wing` | Raymer 7th ed. Eq. 7.6/7.7/7.8; `convert_sweep`; Roskam Eq. 12.1. `tc_r/t_wing` mirror `tc_wing` (uniform — no Brandt split available) |
| HT | `b_ht`, `c_root_ht`, `c_tip_ht`, `QC_sweep_ht`, `TE_sweep_ht`, `tc_ht`, `S_exposed_ht`, `S_wet_ht` | as wing; `tc_ht` = mean of the root/tip pair = 0.0475 |
| VT | `b_vt`, `c_root_vt`, `c_tip_vt`, `QC_sweep_vt`, `TE_sweep_vt`, `tc_vt`, `S_exposed_vt`, `S_wet_vt` | `b_vt` is the **full single-panel** span, not halved; sweeps use `convert_sweep_panel` (2/AR), **not** the mirrored wing/HT form; `tc_vt` = 0.0415 |
| Fuselage | `L_fuselage`, `D_fus`, `Amax` | `L_fuselage` mirrors `L_fus` (duplicate name required by the abstract contract); `D_fus` = `(W_max+H_max)/2`; `Amax` = `(π/4)·W·H` |
| Duct | `T_AB_SLS_lb`, `D_inlet`, `D_exit` | `T_AB_SLS_lb` = `prop.T_SL`; `D_inlet` = `sqrt(T/1900)`; `D_exit` = `D_inlet` (constant-diameter cylinder) |
| Total | `S_wet` | wing + HT + VT + fuselage + duct |

Chords use Raymer 7th ed. Eq. 7.6/7.7/7.8 via `GeometryBase`. `QC_sweep_wing` is computed
(32.183178°), not the hardcoded 37° it once was. `D_fus` is a judgment call — Brandt's low-fidelity
equivalent-diameter convention, fed to the official Roskam Eq. 12.3 fuselage formula, because the
JSON supplies only width and height.

---

## 4. Methods

`get_S_ref`, `get_S_wet`, `get_S_wet_wing`, `get_S_wet_HT`, `get_S_wet_VT`, `get_S_wet_fuselage`,
`get_S_wet_duct`, `get_S_exposed_wing` — all one-line delegations into `GeomL2`.

`get_S_wet` takes no `W_TO` argument (contrast L1). Total wetted area = wing + HT + VT + fuselage +
duct, using Roskam Vol. II Eq. 12.1 (surfaces) + Eq. 12.3 (fuselage) + Raymer 6th ed. §7.3 (duct).

### As-built values

| Quantity | Value | | Quantity | Value |
|---|---|---|---|---|
| `cbar_wing` | 11.320179 ft | | `S_exposed_wing` | 196.22607 ft² |
| `QC_sweep_wing` | 32.183178° | | `S_exposed_ht` | 49.847251 ft² |
| `b_ht` | 18.0 ft | | `S_exposed_vt` | 40.889669 ft² |
| `QC_sweep_vt` / `TE_sweep_vt` | 36.313393° / 22.900799° | | `D_fus` | 6.0 ft |
| `S_wet_wing` / `_ht` / `_vt` | 396.37666 / 101.38789 / 83.139828 ft² | | `Amax` | 27.488936 ft² |
| fuselage `S_wet` | 730.30232 ft² | | `D_inlet` | 3.5370222 ft |
| duct `S_wet` | 155.56636 ft² | | **`S_wet`** | **1466.7731 ft²** |

---

## 5. To-dos

| Item | Guard |
|---|---|
| `L_aircraft` = 47.65 ft is user-approved as the published airframe length (47 ft 7.75 in) but the **citation is not pinned** — no overall-length figure appears anywhere in `sizing/`. Brandt `Geom!B21` = 48.303947 does not pin it: that is a `MAX()` over his x-stations, an extent rather than a spec length | todo §6 |
| `Amax` = `(π/4)·W·H` is a standard elliptical identity with no equation number | todo §4 |
| `D_fus` as `(W+H)/2` is a convention choice, not a cited formula | in-code note |
| `GeometryBase.compute_nacelle_diameter` hardcodes 1900, silently assuming an afterburning engine (Brandt uses 2000 when `T_dry = T_AB`) | todo §18 |
| `mainwheel_S_front` / `nosewheel_S_front` are declared and unused | — |
