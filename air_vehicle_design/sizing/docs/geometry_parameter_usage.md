# Geometry parameter usage

Which geometric quantity is produced at which fidelity level, by which member, under what citation,
and who consumes it. As-built from `src/base/GeometryBase.m`,
`src/disciplines/geometry/GeomL{1,2,3}.m` + `GeometryModelL{1,2,3}.m`, and
`examples/F16A/F16GeomL{1,2,3}.m`. Companions: `aerodynamics_parameter_usage.md`,
`propulsion_parameter_usage.md`, `weights_parameter_usage.md`.

Geometry is **L1 / L2 / L3**. L1 is a statistical tier (regressions on `W_TO`, no planform); L2 is
the Brandt-reference tier; L3 is the physical / T.O. 1F-16A-1 tier, so L2↔L3 differences are
intentional fidelity divergences, not errors.

---

## 1. Downstream consumers

| Consumer | Reads | Via |
|---|---|---|
| Aerodynamics L2 / L3 | `S_ref`, `S_wet`, `AR_wing`, sweeps, taper, t/c, per-component wetted areas / lengths / diameters, `Amax`, `L_aircraft` | constructor DI, live through `Dependent` getters |
| Weights L2 / L3 | exposed areas, tail planform, fuselage envelope, control-surface areas, duct/engine lengths | constructor DI, live through `Dependent` getters |
| Constraints | nothing directly — geometry reaches them through the geometry→aero chain (`drag_polar`, `get_CLmax`) | indirect |
| Propulsion | nothing. `PropL2` *produces* engine length/diameter as outputs nothing reads back | — |

Aerodynamics L1 and weights L1 are geometry-free.

---

## 2. Dependency injection

| Direction | Mechanism | What crosses |
|---|---|---|
| propulsion → geometry | `F16GeomL2(json_path, prop)` / `F16GeomL3(json_path, prop)`, both arguments required | exactly one number: `prop.T_SL` = 23,770 lbf. `T_AB_SLS_lb` is `Dependent` on it, so `D_inlet` → duct `S_wet` → `CD0` tracks a thrust change instead of a frozen copy |
| geometry → aerodynamics | `F16AeroL2(geom, json_path)` / `F16AeroL3(geom, json_path)`; guard `mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])` | every geometric quantity aero uses; nothing geometric is stored on an aero class |
| geometry → weights | `F16WeightsL2(json_path, req_path, geom, prop)` requires `GeometryModelL2`; `F16WeightsL3(…)` requires `GeometryModelL3` | 21 `Dependent` getters on `F16WeightsL3` read `obj.geom.*`; the former hardcoded geometry constants are gone |
| geometry → propulsion | none | — |

The guards cannot catch an L2-vs-L3 mix-up: both tiers satisfy the aero contract by design, so a
wrong-but-valid injection yields plausible numbers rather than an error. Only reading the call site
catches it.

**Three DI name traps** — each wrong-but-valid wiring produces a plausible number:

| Weights wants | Must read | NOT |
|---|---|---|
| Raymer Eq. 15.4 structural depth | `geom.H_max_fuselage` = 5.0 | `geom.D_fus` = 6.0 (Roskam Eq. 12.3 equivalent diameter) |
| Eq. 15.2 exposed HT area | `geom.S_exposed_ht` = 51.1486 | `geom.S_ht` = 108 (full reference) |
| Eq. 15.3 exposed VT area | `geom.S_exposed_vt` = 40.8897 | `geom.S_vt` = 60 (full reference) |

`AR_ht` / `lambda_ht` / `S_ht` / `S_vt` mean **full planform at both tiers**; the exposed values carry
an explicit `_exposed_` infix (`AR_exposed_ht`, `lambda_exposed_vt`, …). The weights-side `AR_ht` /
`lambda_ht` were dead and are deleted, not re-pointed.

---

## 3. Quantity → level, member, citation

### Planform (per surface: wing, HT, VT)

| Quantity | Member | Formula | Citation |
|---|---|---|---|
| span | `compute_span(AR, S_ref)` | `sqrt(AR·S)` | definitional |
| root / tip chord | `compute_root_chord` / `compute_tip_chord` | `2S/(b(1+λ))`; `λ·c_root` | Raymer 7th ed. Eq. 7.6 / 7.7 |
| MAC | `compute_mac(c_root, lambda)` | `(2/3)c_root(1+λ+λ²)/(1+λ)` | Raymer 7th ed. Eq. 7.8 |
| sweep at `x`, **mirrored** (wing, HT) | `convert_sweep(Λ_LE, AR, λ, x)` | `tan Λ_x = tan Λ_LE − (4/AR)x(1−λ)/(1+λ)` | standard planform identity (`GeometryBase.md`) |
| sweep at `x`, **single panel** (VT) | `convert_sweep_panel(…)` | same with `2/AR` | as above |
| exposed area | `S_exposed_*` | full planform clipped at `W_max_fuselage/2` (wing, HT) or `H_max_fuselage/2` (VT) | `readme_geom.md` §4.3 |

### Wetted areas

| Quantity | Member | Citation |
|---|---|---|
| lifting surfaces | `S_wet_wing` / `_ht` / `_vt` | Roskam Vol. II Eq. 12.1, fed the root/tip t/c splits |
| fuselage | `get_S_wet_fuselage()` | Roskam Vol. II Eq. 12.3 |
| duct | `get_S_wet_duct()` | Raymer 6th ed. §7.3 (frustum) |

### Fuselage / nacelle

| Quantity | Member | Formula | Citation |
|---|---|---|---|
| equivalent diameter | `D_fus` | `(W_max + H_max)/2` | `[Brandt F-16A.xls, Geom!B3]` (Roskam Vol. II Eq. 12.3 is the fuselage `S_wet` formula this feeds, not the averaging step itself) |
| nacelle diameter | `D_inlet` | `sqrt(T_AB_SLS/1900)` | `[Brandt Geom!C475; Engn(s)!L22 = 1900]` |
| engine length | `L_engine` | `4.5·D` | `[Brandt Geom!D475]` |
| max cross-section, **L2** | `compute_Amax_elliptical(W, H)` | `(π/4)·W·H` — fuselage envelope, low-fidelity form | `readme_geom.md` §7 |
| max cross-section, **L3** | `GeomL3.get_Amax` | `MAX` over 20 rescaled frame stations of (fuselage + wing + HT + VT + nacelle) less `n_engines·πD²/5` | `[Brandt Geom!H26:H45 → H47 → B20]` |

`Amax` is tier-split deliberately. Raymer Eq. 12.44's Sears-Haack term wants a whole-aircraft
area-ruled value; the envelope ellipse is fuselage-only. Injecting an L2 geometry into `F16AeroL3`
substitutes one for the other and inflates `CD0_wave` ~23 %.

### L1 (statistical, functions of `W_TO`)

| Quantity | Member | Citation |
|---|---|---|
| total wetted area | `S_wet` (`Dependent` on input `W_TO`) | Roskam Vol. I Table 3.5 |
| fuselage length | `L_fuselage` (`Dependent` on input `W_TO`) | Raymer 6th ed. Table 6.3 |
| equivalent AR | `get_AR_eq()` (from `M_max`) | Raymer 7th ed. Table 4.1, dogfighter row |

`W_TO` is a genuine L1 input; both getters **error** while it is unset rather than returning a
placeholder. `M_max` comes from `f16a_requirements.json .design_mach`, not the spec file.

---

## 4. As-built values

Computed live 2026-07-26. `BY DESIGN` = intentional L2↔L3 fidelity divergence; `definitional` =
different quantity, not an agreement check.

| Quantity | L1 | L2 | L3 | Brandt | Note |
|---|---|---|---|---|---|
| `S_ref` | 300 | 300 | 300 | `Main!B18` 300 | — |
| `AR_wing` | `get_AR_eq` 3.518664 | 3.0 | 3.0 | `Main!B19` 3 | L1 is a different estimator |
| `lambda_wing` | — | 0.2275 | 0.2275 | `Main!B20` 0.2275 | — |
| `LE_sweep_wing` | — | 40° | 40° | `Main!B21` 40 | — |
| `tc_wing` | — | 0.04 | 0.04 | `Main!B22` NACA 1404 | — |
| `cbar_wing` | — | 11.320179 | 11.320179 | — | — |
| `QC_sweep_wing` | — | 32.183178° | 32.183178° | 28.153° | definitional (exposed-panel basis) |
| `S_exposed_wing` | — | 196.22607 | 196.22607 | `Geom!H7` 196.22607 | agreement |
| `S_exposed_ht` | — | 49.847251 | **51.148643** | `Geom!H8` 49.84725 | **BY DESIGN** (+2.61 %) |
| `S_exposed_vt` | — | 40.889669 | 40.889669 | `Geom!H10` 40.88967 | agreement (no sweep term — cannot diverge) |
| `S_ht` / `S_vt` (full) | — | 108 / 60 | 108 / 60 | `Main!C18`/`H18` | — |
| HT span | — | `b_ht` 18.0 derived | **`B_h` 18.5 INPUT** (primary) | 18.0 | **BY DESIGN** (+2.78 %) |
| `AR_ht` | — | 3.0 INPUT | **3.1689815 DERIVED** = `B_h²/S_ht` | `Main!C19` 3.0 | **BY DESIGN**; must never be stored at L3 |
| `c_root_ht` / `c_tip_ht` | — | 9.7759674 / 2.2240326 | **9.5117521 / 2.1639236** | — | **BY DESIGN** |
| `QC_sweep_ht` / `TE_sweep_ht` | — | 32.183178 / −0.00024285 | **32.639955 / 2.5616932** | `Main!C27` TE ≈ 0 | **BY DESIGN** |
| `LE_sweep_vt` | — | 40° | **47.5°** | `Main!H21` 40 | **BY DESIGN** (T.O. value) |
| `QC_sweep_vt` / `TE_sweep_vt` | — | 36.313393 / 22.900799 | **44.629262 / 34.00525** | `Main!H27` TE = 0 literal | **BY DESIGN**; both tiers use the `2/AR` panel form |
| `tc_ht` / `tc_vt` | — | 0.0475 / 0.0415 | 0.0475 / 0.0415 | `Main!C22`/`H22` 0.04 uniform | definitional — root/tip split `[T.O. 1F-16A-1 §I]` |
| `S_wet_wing` | — | 396.37666 | 396.37666 | `Geom!B14` 392.02044 | definitional (formula family) |
| `S_wet_ht` | — | 101.38789 | **104.03488** | `Geom!B16` 99.58484 | **BY DESIGN** |
| `S_wet_vt` | — | 83.139828 | 83.139828 | `Geom!B17` 81.68938 | definitional |
| fuselage `S_wet` | — | 730.30232 | **749.13368** | `Geom!B3` 730.422 | **BY DESIGN** (`L_fus` 47.5) |
| duct `S_wet` | — | 155.56636 | 155.56636 | `Geom!B4` 41.515 (nacelle) | definitional (different quantity) |
| total `S_wet` | 1763.0171 @ `W_TO` 31,377 | 1466.7731 | 1488.2514 | 1331.134 corrected | definitional — Brandt's total carries strake/nacelle terms with no framework analog |
| `L_fus` | 52.742584 @ 31,377 | 46.5 | **47.5** | `Main!B32` 46.5 | **BY DESIGN** (+2.15 %) |
| `D_fus` (equivalent) | — | 6.0 | 6.0 | low-fi `D_avg` | — |
| `W_max` / `H_max` fuselage | — | 7.0 / 5.0 | 7.0 / 5.0 | `Main!C32`/`D32` | — |
| `Amax` | — | **27.488936** (envelope ellipse) | **24.703652** (area-ruled) | `Geom!B20` 25.110556 | L2 definitional; L3 **BY DESIGN** (−1.62 %, the 47.5 ft fuselage). Round-trip: at `L_fus` 46.5, L3 returns 25.110534 |
| `L_aircraft` | — | 47.65 | 47.65 | `Geom!B21` 48.303947 | definitional — spec dimension vs a `MAX()` extent |
| `D_inlet` | — | 3.5370222 | 3.5370222 | `Geom!C475` 3.537022 | agreement (positive control on the propulsion DI) |
| `L_engine` | — | — | 15.9166 | `Geom!D475` | — |
| `T_AB_SLS_lb` | — | 23,770 (via `prop.T_SL`) | 23,770 (via `prop.T_SL`) | `Main!D29` | `Dependent`, not an input |

### L3-only inputs (feed the area-ruled `Amax`)

| Input | Value | Citation |
|---|---|---|
| `x_apex_wing` | 17.786 ft | `[Brandt Main!B23]` |
| `x_le_ht` / `x_le_vt` | 36.0 / 36.0 ft | `[Brandt Main!C23 / H23]` |
| `x_inlet` | 15.0 ft | `[Brandt Main!F31]` — not 14.0, which is the duct length |
| `n_engines` | 1 | `[Brandt Main!B28]` |
| `frames_normalized` | 20 × 3 | `[Brandt Main!A34:F53]` ÷ his envelope (46.5 / 7.0 / 5.0) |

Frames are stored **normalized** so `Amax` responds to the fuselage envelope. Stored raw it responded
to `W_max_fuselage` with the wrong sign and to `H_max_fuselage` not at all. `Amax` is deliberately
non-linear in `W_max_fuselage`: a wider fuselage grows every frame section *and* eats more exposed
wing root.

---

## 5. Open items

| Item | Status |
|---|---|
| `Amax` has no pinnable textbook citation at either tier | todo §4; L3's frame-rescaling assumption also uncited |
| `L_aircraft` = 47.65 ft is traceable to no in-repo document | guarded red by `TestGeomL3.testTODO_OverallLengthCitationNotPinned`; todo §6 |
| L1 aileron-area fraction not available | guarded red by `TestGeomL1.testTODO_AileronFractionNotAvailable` |
| `compute_nacelle_diameter` hardcodes 1900, silently assuming an afterburning engine (Brandt uses 2000 when `T_dry = T_AB`) | todo §18 |
| `engine.n_engines` sits in `.geometry` only because no propulsion class exposes an engine count | should migrate to `.propulsion` + DI, as `T_AB_SLS_lb` did; todo §22 |
| `F16GeomL2.mainwheel_S_front` / `nosewheel_S_front` | defined, unused |
| HLD/gear delta methods | implemented and unit-tested, not yet consumed — mission/sizing (steps 7–8) not built |
