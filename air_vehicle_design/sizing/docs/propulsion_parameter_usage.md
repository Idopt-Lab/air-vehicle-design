# Propulsion parameter usage

Which propulsion quantity is produced at which fidelity level, by which function, under what
citation — and the Brandt ground-truth "expected" values the later `*_brandt_comparison` report will
target. As-built from `src/base/PropulsionBase.m`, `src/disciplines/propulsion/PropL{1,2}.m` +
`PropulsionModelL{1,2}.m`, and `examples/F16A/F16Prop{L1,L2}.m`. Companions:
`docs/geometry_parameter_usage.md`, `docs/aerodynamics_parameter_usage.md`.
(Propulsion is L1/L2 only — there is no L3, per CLAUDE.md.)

## Downstream consumers

`thrust_lapse(state)` (AB/max lapse) and `get_TSFC(state)` (mil-power TSFC) plus the sea-level thrust
property are the only propulsion outputs the constraint analysis and (future) mission/sizing loop
read. `compute_thrust_lapse_mil` / `compute_TSFC_AB` / `thrust_lapse_mil_on_AB_scale` are auxiliary
accessors used by constraint analysis and the comparison report. Propulsion consumes **zero
geometry**; `PropL2` *produces* engine length/diameter (Raymer Eqs. 10.5/10.6/10.11/10.12) as
outputs that nothing reads back.

---

## Part A — Quantity → (level, function, citation)

### Thrust lapse α
| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `PropL1.get_thrust_lapse` → `sigma_lapse(ρ, m)` | α = σ^m, σ = ρ/ρ_SL; m by engine type | [Martins AE481 metabook Eq. 10.9] (turbofan m=0.6; turbojet m=1.0 per Eq. 10.7) |
| L2 AB/max | `PropL2.thrust_lapse_AB(δ₀, θ₀, TR)` | θ₀≤TR → δ₀; θ₀>TR → δ₀(1−3.5(θ₀−TR)/θ₀) | [Mattingly 2nd ed. Eq. 2.54a] |
| L2 mil (dry) | `PropL2.thrust_lapse_mil(δ₀, θ₀, TR)` | θ₀≤TR → 0.6δ₀; θ₀>TR → 0.6δ₀(1−3.8(θ₀−TR)/θ₀) | [Mattingly Eq. 2.54b] |
| L2 mil-on-AB-scale | `PropL2.get_thrust_lapse_mil_on_AB_scale` | α_mil·(T_SL_mil/T_SL_wet) | [Mattingly Eq. 2.54b + Brandt Consts col AU convention] |

ρ_SL = 0.002377 slug/ft³ [Mattingly App. B]. δ₀, θ₀ = total pressure/temperature ratios
[Mattingly Eq. 2.52], carried on `AircraftState`.

### TSFC
| Level | Function | Formula | Citation | Units |
|---|---|---|---|---|
| L1 | `PropL1.get_TSFC` (table) | M<0.4 → loiter 0.70; M≥0.4 → cruise 0.80 | [Raymer 6th ed. Table 3.3, low-bypass turbofan] | 1/hr |
| L2 mil | `PropL2.TSFC_mil(C1_mil, C2_mil, M, θ)` | (0.90 + 0.30·M)·√θ | [Mattingly Eq. 3.12 + 3.55a] | 1/hr |
| L2 AB | `PropL2.TSFC_AB(C1_AB, C2_AB, M, θ)` | (1.60 + 0.27·M)·√θ | [Mattingly Eq. 3.12 + 3.55b] | 1/hr |

θ = T_atm/T_SL (static temperature ratio). The L2 `C1/C2` coefficients (mil 0.90/0.30, AB 1.60/0.27)
are engine-class constants selected by `engine_type` via `PropL2.lookup_TSFC_coeffs` [Mattingly
Eq. 3.55a/b] — not stored on the class or in the JSON. **L2 Mattingly TSFC is uninstalled** by
default; the installed path (`compute_TSFC_installed` / `compute_TSFC_AB_installed` = uninstalled ×
1.08) is wired (see Part B install factor). L1 M-threshold 0.4 is an L1 approximation (segment type
not on `AircraftState`).

### Throttle ratio / parametric sizing
| Quantity | Function | Formula | Citation |
|---|---|---|---|
| TR | `PropL2.compute_TR(T_t4_max_R, T_t4_SLS_R)` | T_t4_max/T_t4_SLS (→1.0 when T_t4_SLS unknown) | [Mattingly Eq. D.6] |
| Engine W/L/D, SFC (nonAB) | `PropL2.engine_{weight,length,diam}_nonAB`, `SFC_{max,cruise}_nonAB`, `thrust_cruise_nonAB` | Eqs. 10.4–10.9 | [Raymer 6th ed. §10.3.2, p. 284] |
| Engine W/L/D, SFC (AB) | `PropL2.engine_{weight,length,diam}_AB`, `SFC_{max,cruise}_AB`, `thrust_cruise_AB` | Eqs. 10.10–10.15 | [Raymer 6th ed. §10.3.2, p. 284] |

`engine_diam_nonAB` (Eq. 10.6, coeff 0.033) and `engine_diam_AB` (Eq. 10.12, coeff 0.024) are
**correct for imperial units** (diameter in ft; user, Raymer 7th ed.) — the in-code metric-cross-check
note is to be removed in Step 1c. See `VnV/BrandtF16A/todo.md` 2026-07-24 entry 3 (RESOLVED).

---

## Part B — Brandt ground-truth "expected" values (for the comparison report)

All Brandt values cited to the VnV/BrandtF16A docs (`readme_prop.md`, `GroundTruth/cell-map.md`,
`BrandtEngine.m`, `readme_mission.md`) — **never** copied from `tests/disciplines/TestProp*.m`.

| Quantity | Computed-by (framework) | Brandt value | Brandt cell | Mattingly / Raymer | T.O. 1F-16A-1 |
|---|---|---|---|---|---|
| T_SL_wet (AB SLS thrust) | `F16Prop{L1,L2}.T_SL_wet` | 23,770 lbf | Engn!T_AB_SLS (cell-map §Engn(s); readme_prop tbl) | — | §I |
| T_SL_mil (dry SLS thrust) | `F16PropL2.T_SL_mil` | 15,000 lbf | Engn!T_mil_SLS | — | §I |
| TSFC_mil SLS (installed) | `F16PropL2.get_TSFC` | 0.70 1/hr | Engn!TSFC_mil | Eq. 3.55a → 0.90 (uninstalled; +29%) | — |
| TSFC_AB ref, M=0.4 (installed) | `F16PropL2.compute_TSFC_AB` | 2.20 1/hr | Engn!TSFC_AB | Eq. 3.55b → 1.60 @ M=0 (uninstalled) | — |
| TR (throttle ratio) | `F16PropL2.TR` | 1.0 | Engn!S1 | Eq. D.6 (T_t4_SLS unknown → 1.0) | — |
| n_engines | — | 1 | Main!B28 | — | — |
| TSFC install factor | `F16PropL2.TSFC_install_factor` (input); applied by `compute_TSFC_installed` / `_AB_installed` | 1.08 | Miss!C25 = Main!C25 (readme_mission §Engine Model; JSON `.propulsion.TSFC_install_factor`) | — | — |
| D_nacelle | `F16GeomL2.D_inlet` (= sqrt(T_AB/1900)) | 3.537 ft | Engn!D_nac (readme_prop §Nacelle) | Raymer Eq. 10.12 → ~3.8 ft (unwired) | compressor-face 34.8 in (inlet, not comparable) |
| L_nacelle | `F16GeomL2` duct (= 4.5·D) | 15.917 ft | Engn!L_nac | Raymer Eq. 10.11 → ~16.5 ft (unwired) | 15.93 ft (191.16 in total length) |
| W_engine | (weights discipline) | 4730.23 lb | Wt!B22 (= 0.199·T_AB) | — | — |

### Installed vs uninstalled TSFC (user decision 2026-07-24)
The stored Brandt TSFCs 0.70 (mil) / 2.20 (AB) are **installed** values — they already include the
1.08 installation factor (`GroundTruth/cell-map.md`: "the stored values (0.70, 2.20 hr⁻¹) already
include the 1.08× correction factor"; `BrandtEngine.m` TSFC_sl_dry/TSFC_sl_AB marked "installed";
`readme_prop.md` shows SLS recovers 0.70/2.20 exactly with no extra multiply). So the Brandt
"expected" TSFC column above is on the **installed** basis. `PropL2`'s Mattingly TSFC is
**uninstalled**; the framework wires `TSFC_installed = TSFC_uninstalled × 1.08` (factor from Miss!C25)
via `compute_TSFC_installed` / `compute_TSFC_AB_installed`. A doc-vs-doc conflict
(README/readme_mission/BrandtMission apply 1.08 *on top* of 0.70/2.20) was logged and resolved — see
`VnV/BrandtF16A/todo.md` 2026-07-24 entry 4.

### Thrust lapse α at the 6 constraint conditions (Brandt Consts sheet — live-xls verified 2026-07-24)
Column semantics confirmed from the live workbook formulas (Excel COM read of `Brandt-F16-A.xls`):
- **Consts!AS = α_dry** (dry/mil lapse, δ₀ basis, normalized to T_SL_dry) — uses Engn(s) row-4 coeffs.
- **Consts!AT = α_AB** (AB lapse, δ₀ basis, normalized to T_SL_AB) — uses Engn(s) row-15 coeffs.
- **Consts!AU = effective lapse on the T_SL_AB axis** = `alpha_AB_ref`:
  `=(AS·T_dry + %AB/100·(AT·T_AB − AS·T_dry))/T_AB` (T_dry = Main!C29 = 15,000; T_AB = Main!D29 =
  23,770). For 100%-AB rows AU = AT; for the 0%-AB cruise row AU = AS·(T_dry/T_AB).

So `cell-map.md:208` (AU = `alpha_AB_ref`) is correct. `F16Baseline.m`/`TestPropL2.m` label
α_mil-on-AB (= AS·T_dry/T_AB) as "Consts AU", which is a mislabel — that derived value is not in cell
AU (see `VnV/BrandtF16A/todo.md` 2026-07-24 entry A).

| Condition | Consts row | alt (ft) | M | %AB | n | α_dry (AS) | α_AB (AT) | α_eff on T_AB (AU) |
|---|---|---|---|---|---|---|---|---|
| dash / max_mach | 23 | 36,000 | 1.60 | 100 | 1.0 | 0.29829 | 0.57698 | 0.57698 |
| cruise | 24 | 36,000 | 0.87 | 0 | 1.0 | 0.27111 | 0.33264 | 0.17108 |
| max_alt | 25 | 50,000 | 0.87 | 100 | 1.0 | 0.13879 | 0.17029 | 0.17029 |
| combat_turn_sub | 26 | 20,000 | 0.87 | 100 | 4.5 | 0.55566 | 0.68178 | 0.68178 |
| combat_turn_sup | 27 | 36,000 | 1.40 | 100 | 1.4 | 0.35786 | 0.55656 | 0.55656 |
| ps_500 | 28 | 10,000 | 0.87 | 100 | 1.0 | 0.70273 | 0.85355 | 0.85355 |

The framework's Mattingly α_AB (`F16PropL2.thrust_lapse`) compares against **α_AB (AT)** at each
condition; a dry/mil point (cruise) compares against **AU** (effective lapse on the T_SL_AB axis).
Values read directly from the live `Brandt-F16-A.xls` Consts sheet, cells AS/AT/AU rows 23–28.

### Brandt engine-model lapse/TSFC formulas (reference — Mattingly-vs-Brandt comparison)
For the later report contrasting the framework's Mattingly model against Brandt's Engn(s) model
(`readme_prop.md`):
- Dry: θ₀≤TR → α_dry = δ₀(1 − 0.3·M); θ₀>TR → δ₀(1 − 0.3·M − 1.7(θ₀−TR)/θ₀). [Brandt Engn(s) row 4]
- AB: θ₀≤TR → α_AB = δ₀(1 − 0.1·√M); θ₀>TR → δ₀(1 − 0.1·√M − 2.2(θ₀−TR)/θ₀). [Brandt Engn(s) row 15]
- TSFC_dry = 0.70·(1 + 0.35·|M|)·√α_dry [Brandt Engn(s) row 7]; TSFC_AB = 2.20·(1 + 0.35·|M−0.4|)·√α_AB
  [Brandt Engn(s) row 19]. Brandt α_dry normalized by T_SL_dry (15,000); α_AB by T_SL_AB (23,770).

> Cell rows live-xls verified (2026-07-24): the AB thrust equation is Engn(s) **row 15** (coeffs
> D15=0.1, F15=0.5 [√M], R15=2.2), NOT row 6 — `readme_prop.md`'s "row 6" is the dry-TSFC section
> header (empty coeff cells). `F16Baseline.m`'s row-15 citation is correct. See
> `VnV/BrandtF16A/todo.md` 2026-07-24 entry B.

---

## Not consumed / gaps
- `PropL2` parametric engine sizing (Eqs. 10.4–10.15) is implemented and unit-tested but **unwired** —
  no orchestrator reads engine weight/length/diameter; `F16GeomL2` sizes the nacelle independently.

## Migration status (Step 1c — COMPLETE)
- `F16PropL1`/`F16PropL2` use **required-JSON-path constructors** reading the `.propulsion` block of
  `f16a_L{1,2}.json` (no silent default; no-arg errors `MATLAB:minrhs`), with the inputs-vs-
  `Dependent` split applied (`examples/F16A/F16GeomL2.m` is the reference).
- `F16PropL2.TR` is a `properties (Dependent)` `get.TR` (recomputes live from `T_t4_max_F` on read),
  no longer a frozen constructor value. It is degenerate ≡ 1.0 by construction (`T_t4_SLS` unknown) —
  an accepted known limitation, not a bug (see `examples/F16A/F16PropL2.md`).
- The 1.08 installation factor is wired: `compute_TSFC_installed` / `compute_TSFC_AB_installed` =
  uninstalled × `TSFC_install_factor` (Brandt Miss!C25). Uninstalled `get_TSFC` / `compute_TSFC_mil` /
  `compute_TSFC_AB` are kept.
- The Mattingly `C1/C2` coefficients are selected by `engine_type` via `PropL2.lookup_TSFC_coeffs`
  (engine-class constants — not class `Constant`s, not in the JSON).
