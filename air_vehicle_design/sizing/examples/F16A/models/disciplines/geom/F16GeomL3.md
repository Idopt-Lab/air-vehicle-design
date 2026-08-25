# F16GeomL3
F-16A Block 10/15 Level-3 geometry, the **physical / T.O. 1F-16A-1 tier**. `classdef F16GeomL3 <
GeometryModelL3`. L3 geometry, aerodynamics and weights all read it.

Where a physical or T.O. value differs from Brandt's, L3 uses the physical one. Those L2 to L3
divergences are **intentional fidelity differences, not errors**. See §4.

Every planform equation is a reused `GeometryBase` or `GeomL2` static. The formulas that originate in
`GeomL3` are the area-rule block (`denormalize_frames`, `compute_frame_cs_area`,
`compute_lifting_surface_cs_area`, `compute_nacelle_cs_area`, `compute_Amax_area_ruled`) and the
control-station wetted-area pair (`compute_frame_perimeter`, `compute_s_wet_from_perimeter_curve`).
`compute_c_root_exposed` is Raymer's [Eqs. 14.9-14.10, p. 502].

**There is no L3 propulsion tier.** `F16PropL2` serves the L3 rung. Label any L3 propulsion number as
such.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));
g3   = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
```

`F16GeomL3(json_path, prop, req_path)`. All three arguments are necessary. There is no default.

| Argument | Supplies |
|---|---|
| `json_path` | `f16a_L3.json` `.geometry` block |
| `prop` | `prop (1,1) PropulsionBase`. Only `prop.T_SL` is read, to size the nacelle |
| `req_path` | `f16a_requirements.json`. Gives `design_mach`, which becomes `M_max` |

`M_max` is a design **requirement**, not spec data, so it comes from a separate file, as in
`F16GeomL1`. It feeds the Raymer Eq. 10.11 engine length.

The constructor also reads a **fourth file with no argument**: `f16a_stations_path()` supplies
`fuselage_stations` and `fuselage_station_ref`.

Nothing is rescaled here. The frame table stays normalized, and `get_Amax` denormalizes it live, so
an optimizer that moves `L_fus`, `W_max_fuselage` or `H_max_fuselage` moves `Amax`.

---

## 2. Inputs

**54 plain mutable properties**: 47 numeric scalars, 3 tables, 1 injected object, 3 `NaN` slots.

| Group | Properties | Values and notes |
|---|---|---|
| Wing (7) | `S_ref`, `AR_wing`, `lambda_wing`, `LE_sweep_wing`, `tc_wing`, `S_csw`, `x_apex_wing` | 300 ft², 3.0, 0.2275, 40°, 0.04, 68.03 ft², 17.786 ft. `S_csw` is an `[estimate]` |
| HT (10) | `S_ht`, `B_h`, `lambda_ht`, `LE_sweep_ht`, `tc_r_ht`, `tc_t_ht`, `F_w`, `AR_exposed_ht`, `lambda_exposed_ht`, `x_le_ht` | 108 ft² (**full**), 18.5 ft (**primary span**), 0.2275, 40°, 0.060 / 0.035, `F_w`, 2.114, 0.390, 36.0 ft. **`AR_ht` is NOT an input**; `S_ht` + `B_h` fix the planform |
| VT (12) | `S_vt`, `AR_vt`, `lambda_vt`, `LE_sweep_vt`, `tc_r_vt`, `tc_t_vt`, `S_r`, `H_t`, `H_v`, `AR_exposed_vt`, `lambda_exposed_vt`, `x_le_vt` | 60 ft² (**full**), 1.6, 0.5, **47.5°**, 0.053 / 0.030, 11.65 ft², `H_t`, `H_v`, 1.294, 0.437, 36.0 ft. The LE sweep is the T.O. value, not Brandt's 40° |
| Strake, LERX (8) | `S_strake`, `AR_strake`, `lambda_strake`, `LE_sweep_strake`, `tc_r_strake`, `tc_t_strake`, `x_le_strake`, `y_strake` | `[Brandt Main!D18:D24]`. `lambda_strake` gives a sharp tip. The section is a constant 4 % NACA 0004 |
| Fuselage (3) | `L_fus`, `W_max_fuselage`, `H_max_fuselage` | **47.5 ft**, 7.0, 5.0 |
| Tables (3) | `frames_normalized` (20x3), `fuselage_stations` (21x1), `fuselage_station_ref` | frames are `[Brandt Main!A34:F53]` over his own 46.5 / 7.0 / 5.0 envelope. Stations come from `F16_geom_stations.json` |
| Whole aircraft (1) | `L_aircraft` | 47.65 ft. Feeds only the Eq. 12.44 `(Amax/l)²` term. It is **not** `L_fus`. The citation is not pinned. See §6 |
| Duct (3) | `L_duct`, `x_inlet`, `n_engines` | 14.0 ft, **15.0 ft**, 1. `x_inlet` is 15.0, not 14.0; 14.0 is the duct length |
| Requirement (1) | `M_max` | 2.0, from `.design_mach` |
| Configuration (2) | `L_t`, `S_cs` | 22.0 ft, 190 ft². Both `[estimate]` |
| Injected (1) | `prop` | not numeric spec data |
| Control areas (3) | `S_ail`, `S_elev`, `S_rud` | all `NaN`. Not `Dependent`: this object's inputs give no closed form. `ControlSurfaceSizer` writes them after the sizing loop converges |

There is **no `T_AB_SLS_lb` input**. It is `Dependent` on `prop.T_SL`, because engine thrust is engine
data.

The exposed-planform members carry an explicit `_exposed_` infix, so `AR_ht`, `lambda_ht`, `S_ht` and
`S_vt` mean **full planform at both tiers**. An earlier revision gave the same names two meanings,
which fed exposed values into full-planform equations.

`AR_exposed_strake` and `lambda_exposed_strake` are **derived, not inputs**. A strake is a body
surface, and the fuselage does not clip it, so the exposed planform equals the full planform.

---

## 3. Derived (`Dependent`): 54

| Group | Properties |
|---|---|
| Wing (10) | `b_wing`, `c_root_wing`, `c_tip_wing`, `cbar_wing`, `QC_sweep_wing`, `TE_sweep_wing`, `tc_r_wing`, `tc_t_wing`, `S_exposed_wing`, `S_wet_wing` |
| HT (9) | **`AR_ht`**, `b_ht`, `c_root_ht`, `c_tip_ht`, `QC_sweep_ht`, `TE_sweep_ht`, `tc_ht`, `S_exposed_ht`, `S_wet_ht` |
| VT (8) | `b_vt`, `c_root_vt`, `c_tip_vt`, `QC_sweep_vt`, `TE_sweep_vt`, `tc_vt`, `S_exposed_vt`, `S_wet_vt` |
| Strake (7) | `b_strake`, `c_root_strake`, `c_tip_strake`, `S_exposed_strake`, `S_wet_strake`, `AR_exposed_strake`, `lambda_exposed_strake` |
| Fuselage (4) | `L_fuselage`, `D_fus`, `Amax`, `S_wet_fuselage` |
| Duct (6) | `T_AB_SLS_lb`, `D_inlet`, `D_exit`, `S_wet_duct`, `L_engine`, `x_nacelle_aft` |
| Area-rule (9) | `c_exp_root_{wing,ht,vt}`, `G_hs_exp_{wing,ht,vt}`, `Xexp_{wing,ht,vt}` |
| Total (1) | `S_wet` |

**The whole HT planform derives from the `S_ht` + `B_h` pair.** `AR_ht` = `B_h²/S_ht` = 3.1689815. It
must never be stored at L3.

VT sweeps use `convert_sweep_panel` (2/AR), the single-panel form. Wing, HT and strake use the
mirrored `convert_sweep` (4/AR).

Lifting-surface `S_wet` uses Roskam Vol. II Eq. 12.1, fed the T.O. root/tip t/c splits. This is the
same official formula as L2. Brandt's uniform-t/c form stays a comparison-report alternate.

**The fuselage is the one place where L3 leaves L2's formula family.** `S_wet_fuselage` comes from
`get_S_wet_fuselage_stations`, the control-station integration, not from Roskam Eq. 12.3.

---

## 4. As-built values, and the by-design divergences

Verified 2026-08-25. `BY DESIGN` = an intentional L2 to L3 fidelity divergence. `definitional` = a
different quantity, not an agreement check.

| Quantity | L2 | L3 | Brandt | |
|---|---|---|---|---|
| `S_exposed_wing` | 196.2260692 | 196.2260692 | `Geom!H7` 196.22607 | agreement |
| `S_exposed_ht` | 49.8472505 | **51.1486434** | `Geom!H8` 49.84725 | **BY DESIGN** (+2.61 %) |
| `S_exposed_vt` | 40.8896688 | 40.8896688 | `Geom!H10` 40.88967 | agreement. It cannot diverge, because the exposed-area formula has no sweep term. A genuine positive control |
| HT span | `b_ht` 18.0 derived | **`B_h` 18.5 input** | 18.0 | **BY DESIGN** (+2.78 %) |
| `AR_ht` | 3.0 input | **3.1689815 derived** | `Main!C19` 3.0 | **BY DESIGN** (+5.63 %) |
| `c_root_ht` / `c_tip_ht` | 9.7759674 / 2.2240326 | **9.5117521 / 2.1639236** | — | **BY DESIGN** |
| `QC_sweep_ht` / `TE_sweep_ht` | 32.183178 / −0.0002429 | **32.6399548 / 2.5616932** | `Main!C27` TE ≈ 0 | **BY DESIGN**. The derived AR aft-sweeps the L3 trailing edge |
| `LE_sweep_vt` | 40° | **47.5°** | `Main!H21` 40 | **BY DESIGN**, the T.O. value |
| `QC_sweep_vt` / `TE_sweep_vt` | 36.313393 / 22.900799 | **44.6292623 / 34.0052497** | `Main!H27` TE = 0 literal | **BY DESIGN** |
| `S_wet_wing` | 396.3766599 | 396.3766599 | `Geom!B14` 392.02044 | definitional, formula family |
| `S_wet_ht` | 101.3878862 | **104.0348823** | `Geom!B16` 99.58484 | **BY DESIGN** |
| `S_wet_vt` | 83.1398278 | 83.1398278 | `Geom!B17` 81.68938 | definitional |
| `S_wet_strake` | not modelled at L2 | **40.4000000** | `Geom!B15` 39.95600 | +1.11 % |
| `S_exposed_strake` | not modelled at L2 | **20.0000000** | `Geom!H9` 20.00000 | exact |
| `b_strake` / `c_root_strake` / `c_tip_strake` | not modelled at L2 | 5.4772256 / 7.3029674 / 0.0000000 | 5.4772 / 7.3030 / 0.0000 | exact |
| fuselage `S_wet` | 730.3023197 | **692.5050311** | `Geom!B3` 730.422 | **BY DESIGN**, the station integration. was 749.1336818, −7.56 %, 2026-08-24 |
| duct `S_wet` | 155.5663631 | 155.5663631 | `Geom!B4` 41.515 nacelle | definitional |
| **total `S_wet`** | 1466.7730567 | **1472.0227642** | 1331.134 corrected | definitional. Brandt's total carries terms with no framework analogue. was 1528.6514149, −3.70 %, 2026-08-24 |
| `D_inlet` | 3.5370222 | 3.5370222 | `Geom!C475` | agreement, a positive control on the propulsion injection |
| `L_engine` | — | **16.4876156** | `Geom!D475` 15.9166 | **BY DESIGN**, Raymer Eq. 10.11. was 15.9166, +3.59 %, 2026-08-19 |
| `x_nacelle_aft` | — | 45.4876156 | 44.9166 | follows `L_engine`. was 44.9166, +1.27 %, 2026-08-19 |
| `D_fus` / `L_fuselage` | 6.0 / 46.5 | 6.0 / **47.5** | `Main!B32` 46.5 | **BY DESIGN** (+2.15 %) |
| **`Amax`** | **27.4889357** envelope ellipse | **24.7036517** area-ruled | `Geom!B20` 25.110556 | L2 definitional; L3 **BY DESIGN** (−1.62 %) |
| `L_aircraft` | 47.65 | 47.65 | `Geom!B21` 48.303947 | definitional. A spec dimension against a `MAX()` extent |

### `Amax`, the area-ruled buildup

L3 computes the **whole-aircraft** maximum cross-section that Raymer Eq. 12.44's Sears-Haack term
wants: the `MAX` over the 20 rescaled frame stations of fuselage + wing + HT + VT + nacelle sections,
less `n_engines·π·D²/5` `[Brandt Geom!H26:H45 -> H47 -> B20]`.

L2 keeps the fuselage-envelope ellipse `(π/4)·W·H`, which `readme_geom.md` §7 calls the low-fidelity
form. **Do not unify these.** The envelope form at L3 is a fidelity inversion, and it was a real bug:
it puts a fuselage-only quantity where a whole-aircraft one belongs, and inflates `CD0_wave` by about
23 %.

**Round-trip control.** Set `L_fus` back to 46.5 and L3 gives 25.110534, which reproduces Brandt's
`Geom!B20` to −0.0001 %. This proves the method instead of fitting it, so the −1.62 % gap belongs to
the 47.5 ft fuselage, not to the model. With the area-ruled value, `CD0_wave` sits −0.54 % from the
Brandt-referenced term, and `E_WD` = 2.2 needs no retune.

`Amax` is deliberately **non-linear** in `W_max_fuselage`: 7 to 8 ft gives a ratio of 1.131077, not
8/7, because a wider fuselage grows every frame section and also eats more exposed wing root.
`S_ht`, `B_h`, `S_vt` and `tc_ht` move it 0.000 %. That is a true geometric fact, because the tail
sections start aft of the governing station. It is not a dead input.

---

## 5. Methods

Four, and no more. Every other member is a `Dependent` getter.

| Method | Does |
|---|---|
| `get_S_ref(obj)` | returns `obj.S_ref` |
| `get_Amax(obj)` | the area-rule assembly. Calls five `GeomL3` statics |
| `get_design_S_wet_components(obj)` | sums six components and returns the total |
| `get_S_wet_fuselage_stations(obj)` | fuselage wetted area from the station table [Raymer 6th ed. Fig. 7.37, p. 206] |

`get_Amax` takes a design object and reads about 20 fields. That is allowed, because a design class
may read its own properties. It broke the rule only while it lived in the toolbox.

`get_design_S_wet_components` returns one scalar, so its name is wider than its output. It reads
`get_S_wet_fuselage_stations` directly, not through `get.S_wet_fuselage`, to keep the path plain for
a human reader.

**`GeometryModelL3` declares NO abstract methods.** The whole block is commented out. It holds two
concrete bridges:

| Bridge | Forwards to | State |
|---|---|---|
| `get_S_wet(obj)` | `get_design_S_wet_components()` | works |
| `get_control_surfaces(obj)` | `get_design_control_mechanisms()` | **errors.** No concrete class defines that method |

So `get_design_S_wet_components` is necessary but not enforced. A class that omits it constructs, then
fails at the call.

---

## 6. To-dos

| Item | Status |
|---|---|
| `L_aircraft` 47.65 ft has no in-repo source. The **value** is approved; the **provenance** is open. Brandt's 48.304 is a `MAX()` extent, not a comparable spec length | `TestGeomL3.testTODO_OverallLengthCitationNotPinned` |
| The affine frame-rescaling assumption and Brandt's cosine area-distribution model trace to no reference extract here. The one lead, Roskam Part VI, is not in this repo | `GeomL3.md` §5 |
| The `/5` flow-through divisor is a bare literal. The **deduction** is cited (Nicolai and Carichner p. 219 say cross-sectional area leaves out engine airflow area), but not the magnitude. `readme_geom.md` §4.5 uses `π·D²/4` for the same nacelle, which would give `Amax` = 22.738503 (−7.95 %) and make `Amax` thrust-insensitive | `GeomL3.md` §5 |
| Frame-area discretization: Brandt's 6-point cosine sampling was kept. `I_cos` = 0.63137515 against the exact `2/π` = 0.63661977, so 0.824 % low. `compute_frame_cs_area_exact` is a one-line switch worth +0.759 % on `Amax`. **Confirm or switch** | `GeomL3.md` §5 |
| Mixed provenance in the full-planform tails: `S_ht` = 108 and `AR_vt` / `lambda_vt` are Brandt's, sitting next to T.O. LE sweeps and a T.O. `B_h`. Get T.O. full-planform values | this doc |
| `n_engines` sits in `.geometry` only because nothing on the propulsion side exposes an engine count. It should move to `.propulsion` and arrive by injection, as `T_AB_SLS_lb` did | this doc |
| `L_t` 22.0, `S_cs` 190, `S_csw` 68.03, `S_r` 11.65, `H_t` and `H_v` are still `[estimate]`. `L_t` is not derivable: the apex x-stations are inputs, but the MAC y-station is not | `GeomL3.md` §5 |
| The nacelle x-range is `[15.0, 45.4876]`, while `readme_geom.md` §4.5 uses `[14.0, 43.9166]`. The §4.5 inlet station is mislabelled | this doc |
| `compute_nacelle_diameter` hardcodes 1900, which assumes an afterburning engine. Approved as an exception on 2026-08-19, because Raymer, Nicolai and Roskam give no substitute. **A reference scan is owed** | `F16GeomL2.md` §5 |
| The same fuselage depth is keyed `max_height_ft` at L2 and `max_depth_ft` at L3. Same value, same citation, a live trap for shared JSON-reading code | this doc |
| `readme_geom.md` §7's low-fidelity `Amax` row has no cell backing, and it says "cylindrical" 28.2743 where L2 computes the elliptical 27.4889 | this doc |
| `S_ail`, `S_elev` and `S_rud` stay `NaN` until `ControlSurfaceSizer` writes them. Nothing enforces that order. `S_elev` is 0 for the F-16 anyway: it has an all-moving stabilator | this doc |
| `get_control_surfaces` on `GeometryModelL3` calls a method no class defines. The enforcers were ruled off-limits on 2026-08-18, so it is reported, not fixed | §5 |
| Informational, no action: Brandt `Main!H27` VT TE sweep is a literal 0, which disagrees with his own VT planform. Recorded so nobody reverts the 22.90° fix | this doc |
ction: Brandt `Main!H27` VT TE sweep is a literal 0, inconsistent with his own VT planform — recorded so nobody reverts the 22.90° fix | todo §9 |
