# Geometry parameter usage

Which discipline/fidelity/function consumes which geometric quantity, and under what citation.
As-built from the aerodynamics, weights, and propulsion `.m` files. Companion:
`docs/aerodynamics_parameter_usage.md`. (Geometry itself is L1/L2 only — the former L3 was merged
into L2.)

## Data flow (as built)

- **Aerodynamics reads geometry LIVE (dependency injection).** `F16AeroL2/L3` receive an injected
  `F16GeomL2` and read every geometric quantity from it via the concrete class's `Dependent`
  getters — no hardcoded geometry. An optimizer that mutates a geometry input flows straight through
  to the next aero read. (`F16AeroL1` is geometry-free.)
- **Constraints consume aero, not geometry directly.** `ConstraintAnalysis` and the constraint
  classes call `drag_polar`/`get_CLmax`; geometry reaches them through the injected `geom → aero`
  chain.
- **Weights still hardcodes its own geometry copies.** `F16WeightsL2/L3` are not dependency-injected
  (weights hasn't been refactored). Each carries its own `S_w`/`S_ht`/`AR_ht`/`L_fus`/… as cited
  constants, independent of `F16GeomL2` — the remaining "compute once, share" gap.
- **Propulsion consumes zero geometry** (it produces engine geometry as outputs that nothing reads
  back).

---

## Aerodynamics — geometry read live from the injected `F16GeomL2`

Each row is read via a `Dependent` getter on `F16AeroL2`/`F16AeroL3` that returns `obj.geom.<...>`.

| Geometry quantity | via | Used by | Citation |
|---|---|---|---|
| `S_ref` | `geom.S_ref` | CD0 (`Cfe·S_wet/S_ref`), `compute_CL`, L3 buildup normalization | Raymer Eq. 12.23; CL definitional |
| `S_wet` | `geom.S_wet` | L2 subsonic/supersonic CD0 | Raymer Eq. 12.23 |
| `AR` | `geom.AR_wing` | `AeroL2.oswald_eff`, `K1_subsonic`, `K1_supersonic`, `CL_alpha` | Raymer Eq. 12.48–12.51, 12.6 |
| `Lambda_LE_deg` | `geom.LE_sweep_wing` | `oswald_eff`, `K1_supersonic` | Raymer Eq. 12.49 / 12.51 |
| `Lambda_c4_deg` | `geom.QC_sweep_wing` (~32.2°, computed) | `CL_alpha`, `CLmax_clean` | Raymer Eq. 12.6, 12.15 |
| `taper` | `geom.lambda_wing` | HLD flapped-area ratio | Roskam Part II Eq. 7.10 |
| `L_char` | `geom.L_fus` | supersonic aircraft-level Reynolds number | Raymer Eq. 12.25 |
| `S_wet_comp` (wing/HT/VT/fus/duct) | `geom.S_wet_wing/…` | L3 component buildup | Raymer Eq. 12.24 |
| `l_ref_comp` (MAC/length) | `geom.cbar_wing`, HT/VT MAC, `L_fus`, `L_duct` | L3 Re / form factor | Raymer Eq. 12.25/12.30 |
| `D_comp` (body diameters) | `geom.D_fus`, `geom.D_inlet` | L3 body form factor | Raymer Eq. 12.31 |
| `tc_comp` | `geom.tc_wing`, mean HT/VT root-tip t/c | L3 surface form factor | Raymer Eq. 12.30 |
| `Lambda_m_comp` | `GeometryBase.convert_sweep(...x_c_max)` | L3 surface form factor | Raymer Eq. 12.30 |

The DI refactor removed the former hardcoded `S_wet=1371` (Brandt output), `Lambda_c4_deg=37`, and the
hand-copied `S_wet_comp` array — all now live from `geom`. **Exception:** the supersonic wave-drag
`Amax_ft2`/`L_aircraft_ft` are carried as L3 *aero* inputs (the geometry object exposes no area-ruled
max cross-section) — see `F16AeroL3.md`.

---

## Weights — geometry hardcoded independently (not DI)

`F16WeightsL2/L3` carry their own cited geometry constants; nothing reads `F16GeomL2`.

| Geometry quantity | Weights property | Used by | Citation |
|---|---|---|---|
| exposed wing area, AR, LE sweep, taper, `tc_root`, `S_csw` | `S_w`, `AR_w`, `Lambda_LE`, `lambda_w`, `tc_root`, `S_csw` | `WeightsL3.wing` | Raymer Eq. 15.1 |
| fuselage `S_wet`, `L_fus`, `D_fus`, `W_fus` | `S_wet_fus` (L2), `L_fus`, `D_fus`, `W_fus` | `WeightsL2.weight_fuselage` / `WeightsL3.fuselage` | Raymer Table 15.2 / Eq. 15.4 |
| HT/VT areas, aspect ratios, tail arm, sweep | `S_ht`, `S_vt`, `AR_ht`, `AR_vt`, `L_t`, … | `WeightsL2.weight_tail` / `WeightsL3.horizontal_tail`/`vertical_tail` | Raymer Table 15.2 / Eq. 15.2/15.3 |
| engine/duct diameters & lengths | `D_e`, `L_d`, `L_s`, `L_tp`, … | `WeightsL3.air_induction`/`tailpipe`/`engine_cooling` | Raymer Eq. 15.10–15.13 |

Because these are hardcoded independently of `F16GeomL2`, they are not guaranteed to match it — e.g.
`W_fus=7.0` now equals `F16GeomL2.W_max_fuselage=7.0`, but `AR_ht=2.114` (USAF manual) differs from
`F16GeomL2.AR_ht=3.0`. Refactoring weights to read the injected geometry object (as aero does) would
close this gap.

---

## Propulsion — none

`PropulsionBase`, `PropL1/L2`, `F16PropL1/L2` read no geometry. `PropL2` *produces* engine
length/diameter (Raymer Eq. 10.5/10.6/10.11/10.12, functions of thrust/Mach/BPR) as outputs, and
nothing reads them back — `F16GeomL2`'s duct diameter is sized independently by `D=sqrt(T_AB/1900)`.

## Within geometry

`GeomL2`'s fuselage S_wet methods consume `D_fus`/`L_fus` (Roskam Eq. 12.3), and `get_S_wet_duct`
consumes `D_inlet`/`D_exit`/`L_duct` (Raymer §7.3). `W_max_fuselage`/`H_max_fuselage` feed the
`D_fus` Dependent getter (`(W+H)/2`), so they are consumed (not dead).

## Dead / unwired

- `AeroL1.compute_AR_wet` (Eq. 3.11) and `AeroL2/L3.compute_F` (Eq. 12.9) — **removed** in the aero
  refactor.
- The HLD/gear-delta methods (`compute_Delta_CL_max_values`, `get_Delta_*`, `get_CLmax_{TO,L}`) are
  defined and unit-tested but **not consumed by any constraint/orchestrator yet** — the constraint
  classes call only `drag_polar` and clean `get_CLmax`. Mission/sizing (steps 7–8) are not built.
