# Geometry parameter usage

Which discipline / fidelity level / function consumes which geometric quantity, and under what
citation. **As-built (2026-07-25, after Phase 2 + sub-step 2h)** from the geometry, aerodynamics,
weights and propulsion `.m` files. Companions: `docs/aerodynamics_parameter_usage.md`,
`docs/weights_parameter_usage.md`, `examples/F16A/F16GeomL3.md`,
`src/disciplines/geometry/GeomL2.md`.

**Tier status.** Geometry is **L1 / L2 / L3**. The 2026-07-22 "Geometry has no L3" decision was
reversed on 2026-07-24, and `GeomL3` (`src/disciplines/geometry/GeomL3.m`, `GeometryModelL3.m`,
`examples/F16A/F16GeomL3.m`, `tests/disciplines/TestGeomL3.m`) is the **full L3 geometry tier**,
built, tested and **wired**. Both items this file previously listed as "not yet true" are now done:

1. **`F16GeomL3` is no longer orphaned.** `geometry_brandt_comparison.m:47` and
   `aerodynamics_brandt_comparison.m:68` build `g3 = F16GeomL3(f16a_spec_path(3), prop)`, so
   `f16a_L3.json .geometry` is live input, not dead input.
2. **L3's contract is aero-shaped as well as weights-shaped.** `AR_ht`/`lambda_ht`/`S_ht`/`S_vt`
   mean **FULL** planform on both tiers; the exposed values are
   `AR_exposed_ht`/`lambda_exposed_ht`/`AR_exposed_vt`/`lambda_exposed_vt`. The aero injection guard
   was narrowed to match: `F16AeroL2.m:101` / `F16AeroL3.m:144` now take
   `geom (1,1) {mustBeA(geom, ["GeometryModelL2","GeometryModelL3"])}` instead of `GeometryBase`.
   Full spec + citations: `examples/F16A/F16GeomL3.md` §B/§C.

**No L3 propulsion tier exists, by locked decision (2026-07-25).** `F16PropL2` *is* the L3
propulsion rung and must be labelled as such wherever L3 is reported.

**Property counts, as built** (`examples/F16A/F16GeomL3.md` §A): `F16GeomL3` carries **38 numeric
INPUTS + one 20×3 normalized frame table (60 numbers) + 1 injected propulsion object**, and
**45 DERIVED** `Dependent` properties. Nothing derivable is stored.

---

## Data flow (as built)

| Direction | Mechanism | Status |
|---|---|---|
| geometry → **aerodynamics** | constructor DI: `F16AeroL2(geom, path)` / `F16AeroL3(geom, path)`; every geometric quantity read live through `Dependent` getters returning `obj.geom.<…>`. No hardcoded geometry on the aero classes. `F16AeroL1` is geometry-free. | **built**, L2 geometry → L2 aero and **L3 geometry → L3 aero** |
| **propulsion → geometry** | constructor DI: `F16GeomL2(json_path, prop)` / `F16GeomL3(json_path, prop)`, **both arguments required, no silent default**. `T_AB_SLS_lb` is `Dependent` on `prop.T_SL`, so `D_inlet` → duct wetted area (155.5664 ft²) → `CD0` now tracks a thrust change instead of a frozen 23,770 lbf copy. | **built** — this is the only propulsion→geometry dependency: geometry needs exactly one number from propulsion, the SLS AB thrust, and only for nacelle diameter. `duct_length_ft` stays a genuine airframe input |
| geometry → **weights** | none today — `F16WeightsL2/L3` carry ~22 of their own cited geometry constants, independent of any geometry object | the DI wiring is **Phase 4**; `F16GeomL3` is what `F16WeightsL3` will inject |
| geometry → **propulsion** | none. `PropL2` *produces* engine length/diameter (Raymer Eq. 10.5/10.6/10.11/10.12) as outputs that nothing reads back | unchanged |
| geometry → **constraints** | indirect only: `ConstraintAnalysis` and the constraint classes call `drag_polar`/`get_CLmax`, so geometry reaches them through the `geom → aero` chain | unchanged |

One residual wrong-direction item: **`engine.n_engines` = 1 lives in `.geometry`** only because no
propulsion class exposes an engine count (`F16PropL2` exposes `engine_type, T_SL, T_SL_wet,
T_SL_mil, T_t4_max_F, TSFC_install_factor, TR` and no count). It is engine data and should migrate
to `.propulsion` + DI, exactly as `T_AB_SLS_lb` did — `VnV/BrandtF16A/todo.md` 2026-07-25 Phase 2
§22.

---

## Aerodynamics — geometry read live from the injected geometry object

Each row is a `Dependent` getter on `F16AeroL2`/`F16AeroL3` returning `obj.geom.<…>`.

| Aero property | ← geometry member | Used by | Citation | `F16GeomL2` | `F16GeomL3` |
|---|---|---|---|---|---|
| `S_ref` | `S_ref` | CD0 (`Cfe·S_wet/S_ref`), `compute_CL`, L3 buildup normalization | Raymer Eq. 12.23; CL definitional | ✅ | ✅ |
| `S_wet` | `S_wet` | L2 subsonic/supersonic CD0 | Raymer Eq. 12.23 | ✅ | ✅ (now **includes the duct**) |
| `AR` | `AR_wing` | `oswald_eff`, `K1_subsonic/_supersonic`, `CL_alpha` | Raymer Eq. 12.48–12.51, 12.6 | ✅ | ✅ |
| `Lambda_LE_deg` | `LE_sweep_wing` | `oswald_eff`, `K1_supersonic`, wave drag | Raymer Eq. 12.49 / 12.51 / 12.45 | ✅ | ✅ |
| `Lambda_c4_deg` | `QC_sweep_wing` (32.183178°) | `CL_alpha`, `CLmax_clean`, Eq. 12.62 | Raymer Eq. 12.6, 12.15 | ✅ | ✅ |
| `taper` | `lambda_wing` | HLD flapped-area ratio | Roskam Part II Eq. 7.10 | ✅ | ✅ |
| `L_char` (L2 only) | `L_fus` | supersonic aircraft-level Reynolds number | Raymer Eq. 12.25 | ✅ | n/a (L3 uses `l_ref_comp`) |
| `S_wet_comp(1..3)` | `S_wet_wing`, `S_wet_ht`, `S_wet_vt` | L3 component buildup | Raymer Eq. 12.24; surfaces via Roskam Vol. II Eq. 12.1 | ✅ | ✅ (HT **104.0349** vs L2's 101.3879) |
| `S_wet_comp(4)` | `get_S_wet_fuselage()` | L3 buildup | Roskam Vol. II Eq. 12.3 | ✅ | ✅ (**749.1337** at `L_fus` 47.5) |
| `S_wet_comp(5)` | `get_S_wet_duct()` | L3 buildup | Raymer 6th ed. §7.3 (frustum) | ✅ | ✅ |
| `l_ref_comp(1)` | `cbar_wing` = 11.320179 | L3 Re / form factor | Raymer 7th ed. Eq. 7.8 (MAC), Eq. 12.25 | ✅ | ✅ |
| `l_ref_comp(2..3)` | `c_root_ht`+`lambda_ht`, `c_root_vt`+`lambda_vt` → `compute_mac` | L3 Re / form factor | Raymer 7th ed. Eq. 7.6 / 7.8 | ✅ | ✅ — HT MAC **6.608537** vs L2's 6.792107 (option B) |
| `l_ref_comp(4..5)` | `L_fus`, `L_duct` | L3 Re / Eq. 12.31 | Raymer Eq. 12.25 | ✅ | ✅ |
| `D_comp(4..5)` | `D_fus`, `D_inlet` | L3 body form factor | Raymer Eq. 12.31 | ✅ | ✅ |
| `tc_comp(1)` | `tc_wing` | L3 surface form factor | Raymer Eq. 12.30 | ✅ | ✅ |
| `tc_comp(2..3)` | `tc_ht` / `tc_vt`, each the **DERIVED** mean of `tc_root`/`tc_tip` | L3 surface form factor | Raymer Eq. 12.30; splits `[T.O. 1F-16A-1 Sec. I]` | ✅ 0.0475 / 0.0415 | ✅ 0.0475 / 0.0415 |
| `Lambda_m_comp(1..2)` | `convert_sweep(LE_sweep, AR, lambda, x_c_max)` — wing/HT, **mirrored 4/AR** | L3 surface form factor | Raymer Eq. 12.30; sweep identity uncited (`GeometryBase.md`) | ✅ HT 28.6086° | ✅ HT **29.2956°** (the derived `AR_ht` = 3.168981) |
| `Lambda_m_comp(3)` | `convert_sweep_panel(LE_sweep_vt, AR_vt, lambda_vt, x_c_max)` — VT, **single-panel 2/AR** | L3 VT form factor | as above (Phase-1b fix) | ✅ at Λ_LE 40° | ✅ at the physical Λ_LE **47.5°** |
| `Amax_ft2` | **`Amax`** | Eq. 12.44 Sears-Haack wave drag | **L2:** `(π/4)·W·H`, no equation number known — standard elliptical identity (todo §4a). **L3:** area-ruled buildup `[Brandt Geom!H26:H45 → H47 → B20]`, two uncited elements (todo §4b, §5) | ✅ **27.488936** | ✅ **24.703652** |
| `L_aircraft_ft` | **`L_aircraft`** | Eq. 12.44 | published F-16A airframe length 47.65 ft — **unsourced in repo** (todo §6) | ✅ | ✅ |

The 2026-07-22 DI refactor removed the hardcoded `S_wet = 1371` (a Brandt output),
`Lambda_c4_deg = 37` and the hand-copied `S_wet_comp` array. **Phase 2 closed the last exception:**
`Amax_ft2` = 25.110556 and `L_aircraft_ft` = 48.304 were frozen Brandt *outputs* on `F16AeroL3` while
the comparison report called `Amax` "NOT MODELED"; both are now `Dependent` on the injected geometry
object and the `.aerodynamics.wave_drag` JSON block is gone.

**The wave-drag consequence, corrected.** Earlier revisions of this file predicted a **+23.15 %**
shift in the Eq. 12.44 term. That figure belonged to the envelope ellipse sitting at L3 and is now
**superseded**. As built, with the area-ruled `Amax`: `(Amax/l)²` = 0.268780 vs the Brandt-referenced
0.270239, i.e. `CD0_wave` **−0.54 %**, and **`E_WD` = 2.2 is unchanged — no retune was applied and
none is needed** (`F16GeomL3.md` §D.4). Note `F16AeroL3.m:226-237,293-300` still carry the old
comment text and are stale.

---

## Weights — geometry arrives by DI (Phase 4, landed 2026-07-25)

**This section previously read "geometry hardcoded independently (not DI yet)". That is no longer
true.** `F16WeightsL2` injects `F16GeomL2` and `F16WeightsL3` injects `F16GeomL3`; the ~22 frozen
geometry constants they used to carry are gone (review finding #11). Constructors are
`F16WeightsL{2,3}(json_path, req_path, geom, prop)`, every argument required.

The last column is now the **as-built** wiring, not a Phase-4 target. The three name traps it calls
out are real and were the main hazard in doing this: each wrong-but-valid wiring produces a plausible
number rather than an error. Two entries below are corrected against as-built:

- `AR_exposed_ht` / `lambda_exposed_ht` are **NOT wired** — `todo` §P4-6 proved the weights-side
  `AR_ht` / `lambda_ht` were dead, and both properties were deleted rather than re-pointed.
  `isprop(w3,'AR_ht')` is 0.
- `S_wet_fus` at L2 comes from `geom.get_S_wet_fuselage()` = **730.3023** (the L2 fuselage,
  `L_fus` = 46.5); the 749.1337 in the row below is the **L3** figure at `L_fus` = 47.5.

| Weights quantity | Weights property | Used by | Citation | Geometry member, AS BUILT (`F16GeomL3` unless noted) |
|---|---|---|---|---|
| exposed wing area, AR, LE sweep, taper, `tc_root`, `S_csw` | `S_w`, `AR_w`, `Lambda_LE_w`, `lambda_w`, `tc_root`, `S_csw` | `WeightsL3.wing` | Raymer Eq. 15.1 | `S_exposed_wing` (196.2261), `AR_wing`, `LE_sweep_wing`, `lambda_wing`, `tc_r_wing`, `S_csw` |
| fuselage `S_wet`, length, **depth**, width | `S_wet_fus` (L2), `L_fus`, `D_fus`, `W_fus` | `WeightsL2.weight_fuselage` / `WeightsL3.fuselage` | Raymer Table 15.2 / Eq. 15.4 | `get_S_wet_fuselage()` (749.1337), `L_fus` (**47.5**), **`H_max_fuselage` = 5.0 — NOT `geom.D_fus` = 6.0**, `W_max_fuselage` |
| HT exposed area / AR / taper / span / fuselage width at HT | `S_ht`, `AR_ht`, `lambda_ht`, `B_h`, `F_w` | `WeightsL3.horizontal_tail` | Raymer Eq. 15.2 | **`S_exposed_ht` (51.1486, DERIVED) — NOT `geom.S_ht` = 108**; `AR_exposed_ht`, `lambda_exposed_ht`, `B_h`, `F_w` |
| VT exposed area / AR / taper / LE sweep / rudder / tail arm / heights | `S_vt`, `AR_vt`, `lambda_vt`, `Lambda_LE_vt`, `S_r`, `L_t`, `H_t`, `H_v` | `WeightsL3.vertical_tail` | Raymer Eq. 15.3 | **`S_exposed_vt` (40.8897, DERIVED) — NOT `geom.S_vt` = 60**; `AR_exposed_vt`, `lambda_exposed_vt`, `LE_sweep_vt` (**47.5**), `S_r`, `L_t`, `H_t`, `H_v` |
| total control-surface area | `S_cs` | `WeightsL3.flight_controls` | Raymer Eq. 15.17 | `S_cs` |
| engine/duct diameters & lengths | `D_e`, `L_d`, `L_s`, `L_tp`, … | `WeightsL3.air_induction`/`tailpipe`/`engine_cooling` | Raymer Eq. 15.10–15.13 | partially available now: `D_inlet` (3.537022), `L_engine` (15.9166), `L_duct` (14.0) are DERIVED/input on `F16GeomL3`; engine thrust `T_max` comes from **propulsion** DI, not geometry |

The three traps, all logged (todo 2026-07-24 GeomL3 §5): `geom.D_fus` is the Roskam-Eq.-12.3
*equivalent diameter* 6.0, not the Raymer-Eq.-15.4 *structural depth* 5.0; and `geom.S_ht`/`geom.S_vt`
are *full reference* areas 108/60, not the *exposed* 51.1486/40.8897 the weights equations want. The
Phase-2 rename removed the AR/taper half of the collision but **not** these three — they need the
correct source property named explicitly at the DI site.

Because weights geometry is hardcoded independently it is not guaranteed to agree with the geometry
tiers. Phase 2 settles the three previously-flagged divergences by making **L3 geometry the 47.5 ft
tier**: weights `L_fus` = 47.5 matches `F16GeomL3.L_fus` = 47.5 (it disagreed with `F16GeomL2`'s
46.5); weights `D_fus` = 5.0 matches `H_max_fuselage`; weights `S_wet_fus` = 750 (an unpinned
estimate) is replaced by the computed **749.1337 ft²** at L3 (Roskam Vol. II Eq. 12.3, `L_fus` 47.5)
— a 0.1 % difference, versus 2.6 % against L2's 730.3023. **One divergence is newly created and is
intentional:** weights' exposed HT area 49.85 vs the L3 DERIVED 51.1486 (+2.6 %, Decision 1 —
`F16GeomL3.md` §A.4).

---

## Propulsion

Propulsion reads **no** geometry. `PropulsionBase`, `PropL1/L2` and `F16PropL1/L2` contain no
geometric input; `PropL2` produces engine length/diameter as outputs nothing reads back.

The reverse direction is real and is **built**: geometry needs exactly one number from propulsion,
the SLS afterburning thrust `prop.T_SL` = 23,770 lbf `[Brandt Engn(s)!T_AB_SLS = Main!D29]`, used
only to size the nacelle diameter `D = sqrt(T/1900)` `[Brandt Geom!C475; Engn(s)!L22 = 1900]`, which
drives `D_inlet`/`D_exit` → duct wetted area (155.5664 ft²) → L3 `S_wet_comp(5)` and `D_comp(5)`, and
since sub-step 2h also `L_engine` = `4.5·D` = 15.9166 `[Geom!D475]` → `x_nacelle_aft` → the nacelle
term of `Amax`. The third hardcoded copy of 23,770 that used to sit on `F16GeomL2` is gone.

Caveat carried from `todo.md` §18: `GeometryBase.compute_nacelle_diameter` hardcodes **1900**
unconditionally, which silently assumes an **afterburning** engine — Brandt uses `Engn(s)!L22` = 1900
only when `T_dry ≠ T_AB`, and `L10` = 2000 otherwise.

`F16PropL2` also serves the **L3** rung (no L3 propulsion tier, locked 2026-07-25). Anything that
reports an L3 propulsion number must label it "computed by `F16PropL2`".

## Within geometry

- `GeomL2`/`GeomL3` fuselage `S_wet` consumes `D_fus`/`L_fus` (Roskam Vol. II Eq. 12.3);
  `get_S_wet_duct` consumes `D_inlet`/`D_exit`/`L_duct` (Raymer 6th ed. §7.3).
- `W_max_fuselage`/`H_max_fuselage` feed the `D_fus` getter (`(W+H)/2`), the exposed-area clips, and
  `Amax` — at **both** tiers, by different routes (see the `Amax` bullet below).
- `W_max_fuselage/2` is the fuselage half-width clipping the exposed wing/HT areas;
  `H_max_fuselage/2` is the half-height clipping the exposed VT area (`readme_geom.md` §4.3).
- `S_exposed_ht`/`S_exposed_vt` are `Dependent` at L3, not stored 49.85 / 40.89 (`F16GeomL3.md` §A.4
  — the VT value cannot change, since the exposed-area formula has no sweep dependence: a genuine
  positive control).
- **The whole L3 HT planform derives from the `S_ht` + `B_h` input pair** (Decision 1):
  `AR_ht` = 3.168981, `b_ht`, `c_root_ht`, `c_tip_ht`, `QC/TE_sweep_ht`, `S_exposed_ht`, HT MAC and
  HT `S_wet` are all `Dependent`. `AR_ht` must never be a stored input at L3.
- **Lifting-surface `S_wet` at L3 uses Roskam Vol. II Eq. 12.1** (Decision 2), fed the T.O. root/tip
  t/c splits — same official formula as L2. Brandt's uniform-t/c `Geom!B13` form is retained only as
  a comparison-report alternate row.
- **`Amax` is tier-split on purpose.** L2 = `GeometryBase.compute_Amax_elliptical(W_max, H_max)` =
  `(π/4)·W·H` = **27.488936**, the low-fidelity fuselage-envelope form (`readme_geom.md` §7).
  L3 = `GeomL3.get_Amax(obj)`, the whole-aircraft **area-ruled** buildup = **24.703652**:
  `MAX` over the 20 rescaled frame stations of (`A_fuse` + `A_wing` + `A_HT` + `A_VT` + `A_nacelle`)
  less `n_engines·π·D²/5` `[Brandt Geom!H26:H45 → H47 → B20; readme_geom.md §§4.2/4.5]`. Full
  writeup, round-trip control and both citation gaps: `F16GeomL3.md` §D.
- **`Amax`'s L3 consumers within geometry** are all `Dependent` and must stay so: `c_exp_root_*`,
  `G_hs_exp_*`, `Xexp_*`, `L_engine`, `x_nacelle_aft` (`F16GeomL3.md` §A.2b, todo §16.1).

## Dead / unwired

- `AeroL1.compute_AR_wet` (Eq. 3.11) and `AeroL2/L3.compute_F` (Eq. 12.9) — **removed** in the aero
  refactor.
- `F16GeomL2.mainwheel_S_front` / `nosewheel_S_front` (`Constant`) — self-labelled unused, carried
  forward from the former `F16GeomL3`.
- The HLD/gear-delta methods (`compute_Delta_CL_max_values`, `get_Delta_*`, `get_CLmax_{TO,L}`) are
  defined and unit-tested but not consumed by any constraint/orchestrator yet. Mission/sizing
  (steps 7–8) are not built.
- `geometry_brandt_comparison.m:135` computes `L_aircraft_l2` and never uses it.
- **No longer dead:** `f16a_L3.json .geometry` is read in production by both comparison reports and
  by the L3 aero path.

---

## Cross-tier value comparison (as built)

Live values, computed 2026-07-25 against the as-built classes. `BY DESIGN` marks an intentional
L2↔L3 fidelity divergence (locked decision); Brandt cell references were read live over Excel COM
the same day. The `Main`-tab taper/sweep/t-c citation fix (rows 20/21/22, not 21/20/24) is
**applied** repo-wide — `examples/F16A/F16GeomL3.md` §F is the authoritative record. Zero computed
values changed from that fix.

| Quantity | L1 | L2 | L3 | Brandt | Divergence |
|---|---|---|---|---|---|
| `S_ref` | 300 (hardcoded, not JSON) | 300 | 300 | `Main!B18` = 300 | — |
| `AR_wing` | `get_AR_eq` (Raymer 7th Table 4.1) | 3.0 | 3.0 | `Main!B19` = 3 | — |
| `lambda_wing` | — | 0.2275 | 0.2275 | `Main!B20` = 0.2275 | — |
| `LE_sweep_wing` | — | 40° | 40° | `Main!B21` = 40 | — |
| `tc_wing` | — | 0.04 | 0.04 | `Main!B22` = 1404 (NACA 4-digit → 4 % t/c) | — |
| `cbar_wing` | — | 11.320179 | 11.320179 | — | — |
| `QC_sweep_wing` | — | 32.183178° | 32.183178° | 28.153° (exposed-panel basis) | definitional |
| `S_exposed_wing` | — | 196.2261 | 196.2261 | `Geom!H7` = 196.22607 | agreement |
| `S_exposed_ht` | — | 49.8473 | **51.1486** | `Geom!H8` = 49.84725 | **BY DESIGN** (+2.611 %) — Decision 1 |
| `S_exposed_vt` | — | 40.8897 | 40.8897 | `Geom!H10` = 40.88967 | agreement (cannot diverge — no sweep term) |
| HT span | — | `b_ht` = 18.0, derived from `AR_ht`·`S_ht` | **`B_h` = 18.5 INPUT (primary)**; `b_ht` mirrors it | `sqrt(AR·S)` = 18.0 | **BY DESIGN** (+2.78 %) — Decision 1 |
| `AR_ht` | — | 3.0 INPUT | **3.168981 DERIVED** = `B_h²/S_ht` | `Main!C19` = 3.0 | **BY DESIGN** (+5.63 %); must NOT be stored at L3 |
| `c_root_ht` / `c_tip_ht` | — | 9.775967 / 2.224033 | **9.511752 / 2.163924** | — | **BY DESIGN** — from the `S_ht`+`B_h` pair |
| HT MAC (`l_ref_comp(2)`) | — | 6.792107 | **6.608537** | — | **BY DESIGN** (−2.703 %) |
| `QC_sweep_ht` / `TE_sweep_ht` | — | 32.183178 / −0.000243 | **32.639955 / 2.561693** | `Main!C27` TE = −0.00024343 | **BY DESIGN** — the derived AR aft-sweeps the L3 HT trailing edge |
| HT `S_wet` | — | 101.3879 | **104.0349** | `Geom!B16` = 99.58484 | **BY DESIGN** (+4.47 % = +1.8 % Roskam Eq. 12.1 + 2.6 % option-B exposed area) |
| wing `S_wet` | — | 396.3767 | 396.3767 | `Geom!B14` = 392.02044 | definitional (+1.11 %, formula family) |
| VT `S_wet` | — | 83.1398 | 83.1398 | `Geom!B17` = 81.68938 | definitional (+1.78 %, formula family) |
| `LE_sweep_vt` | — | 40° | **47.5°** | `Main!H21` = 40 | **BY DESIGN** (+18.75 %) |
| `QC_sweep_vt` / `TE_sweep_vt` | — | 36.313393° / 22.900799° | **44.629262° / 34.005250°** | `Main!H27` TE = 0 (literal) | **BY DESIGN**; both tiers use the single-panel `2/AR` form (Phase 1b) |
| `tc_ht` / `tc_vt` | — | 0.0475 / 0.0415 (DERIVED means) | 0.0475 / 0.0415 (DERIVED means) | `Main!C22`/`H22` = `0004` → 0.04 uniform | definitional — root/tip split `[T.O. 1F-16A-1 Sec. I]` |
| `L_fus` | Raymer Table 6.3 regression on `W_TO` | 46.5 | **47.5** | `Main!B32` = 46.5 | **BY DESIGN** (+2.15 %) |
| `D_fus` (equiv. diameter) | — | 6.0 | 6.0 | Brandt low-fi `D_avg` | — |
| `H_max_fuselage` (depth) | — | 5.0 | 5.0 | `Main!D32` = 5 | — |
| `W_max_fuselage` | — | 7.0 | 7.0 | `Main!C32` = 7 | — |
| fuselage `S_wet` | — | 730.3023 | **749.1337** | `B3` = 730.422 / `D23` = 676.3289 | **BY DESIGN** |
| duct `S_wet` | — | 155.5664 | 155.5664 | `Geom!B4` = 41.515 (nacelle) | definitional (different quantity) |
| total `S_wet` | Roskam Vol. I Table 3.5 regression on `W_TO` | 1466.7731 | **1488.2514** (official Roskam set, incl. duct; Brandt-form alt 1480.8261) | corrected 1331.134 / raw 1371.0946 | definitional — Brandt's total also carries strake + nacelle terms this framework has no component for; **not** an agreement check |
| **`Amax`** | — | **27.488936** (envelope ellipse `(π/4)·W·H`) | **24.703652** (AREA-RULED buildup) | `Geom!B20`/`H47` = 25.110556 | L2 definitional (+9.47 %, different quantity); **L3 BY DESIGN (−1.62 %)** — same quantity, gap is the 47.5 ft fuselage. ROUND-TRIP: at `L_fus` = 46.5, L3 returns **25.110534** (−0.0001 %) |
| `L_aircraft` | — | 47.65 (input, unused by any L2 consumer) | **47.65** (input) | `Geom!B21` = 48.303947 | definitional (−1.35 %) — spec dimension vs a `MAX()` extent |
| `D_inlet` | — | 3.537022 (via injected `prop.T_SL`) | 3.537022 (via injected `prop.T_SL`) | `Geom!C475` = 3.537022 | agreement (positive control that DI reproduces the frozen value) |

### Sub-step 2h inputs — new at L3 only

These exist solely to feed the area-ruled `Amax`; `F16GeomL2` has none of them.

| Input | Value | Citation | Note |
|---|---|---|---|
| `wing.x_apex_ft` → `x_apex_wing` | 17.786 ft | `[Brandt Main!B23 'X Location']` (live cell 17.785833, `=(213.43)/12`) | not derivable in-framework (no MAC x/y stations); the 0.0011 % offset from the live cell is the scoped value, do not silently "correct" |
| `horizontal_tail.x_le_ft` → `x_le_ht` | 36.0 ft | `[Brandt Main!C23]` | fixes `Xexp_ht` = 38.936849 `[Geom!B8 = 38.93685]` |
| `vertical_tail.x_le_ft` → `x_le_vt` | 36.0 ft | `[Brandt Main!H23]`, live `=C23` | fixes `Xexp_vt` = 38.728271; cf. `Geom!B10` = 38.09775 at Brandt's 40° — the same intentional sweep divergence |
| `engine.x_inlet_ft` → `x_inlet` | **15.0 ft** | `[Brandt Main!F31, label E31 = 'Inlet(s):']` | ★ **NOT 14.0** — the read-only `GroundTruth/f16a_geometry.json` key `inlet_x_ft` = 14.0 is mislabelled (14.0 is `Main!F32`, the duct length). todo §18 |
| `engine.n_engines` → `n_engines` | 1 | `[Brandt Main!B28]` | belongs in `.propulsion`; see the Data-flow note. todo §22 |
| `fuselage.frames_normalized` | 20 × 3 = **60 numbers** | `[Brandt Main!A34:F53; readme_geom.md §2]` ÷ his own envelope (46.5 / 7.0 / 5.0) | columns `x_over_L`, `w_over_Wmax`, `h_over_Hmax`; the `z_chine`/`z_center` columns are dropped because they cancel **exactly** out of the area (`readme_geom.md` §4.2). ★ the affine-rescaling assumption is **UNCITED**, todo §4 |

**Why NORMALIZED, in one line:** stored raw, `Amax` responds to `W_max_fuselage` with the **wrong
sign** (−0.561 % for +10 %) and to `H_max_fuselage` not at all. Normalized, the as-built liveness is
`W_max` **+9.164 %**, `H_max` **+9.164 %**, `L_fus` **+12.478 %**, `S_ref` **+4.184 %**,
`LE_sweep_wing` **+7.289 %**, `prop.T_SL` **+0.795 %**; `S_ht`/`B_h`/`S_vt`/`tc_ht` **0.000 %** each
— the last being a true geometric fact (the tail sections start aft of the governing station), not a
dead input. `Amax` is deliberately **no longer linear** in `W_max_fuselage`: stepping 7 → 8 ft gives
a ratio of **1.131077**, not 8/7 = 1.142857, because a wider fuselage grows every frame section *and*
eats more exposed wing root. All live; details in `F16GeomL3.md` §D.5.

Open items behind these numbers (all user-review, none resolved): `VnV/BrandtF16A/todo.md`
2026-07-25 Phase 2, and `examples/F16A/F16GeomL3.md` §H.
