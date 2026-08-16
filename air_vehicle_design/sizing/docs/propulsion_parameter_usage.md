# Propulsion parameter usage

Which propulsion quantity is produced at which fidelity level, by which function, under what
citation, and who consumes it. As-built from `src/base/PropulsionBase.m`,
`src/disciplines/propulsion/PropL{1,2}.m` + `PropulsionModelL{1,2}.m`, and
`examples/F16A/models/disciplines/prop/F16Prop{L1,L2}.m`. Companions: `geometry_parameter_usage.md`,
`aerodynamics_parameter_usage.md`, `weights_parameter_usage.md`.

**Propulsion is L1 / L2 only — there is no L3 tier and none is planned.** `F16PropL2` *is* the L3
rung; anything reporting an L3 propulsion number must label it "computed by `F16PropL2`".

---

## 1. Downstream consumers

| Consumer | Reads | Via |
|---|---|---|
| Constraint classes | `thrust_lapse(state)` (AB/max), `T_SL` | `ThrustConstraint` through `ConstraintAnalysis` |
| Geometry L2 / L3 | `T_SL` only | constructor DI — sizes the nacelle diameter |
| Weights L2 / L3 | `T_SL`, `bypass_ratio` | constructor DI — Raymer Eq. 10.10 engine weight |
| Weights L3 | `get_TSFC(state)` at the cruise condition | constructor DI — `SFC_mission` |
| Comparison reports | `compute_thrust_lapse_mil`, `compute_TSFC_AB`, `thrust_lapse_mil_on_AB_scale` | auxiliary accessors |

---

## 2. Dependency injection

| Direction | Mechanism | What crosses |
|---|---|---|
| propulsion → geometry | `F16GeomL{2,3}(json_path, prop)` | `prop.T_SL` → `T_AB_SLS_lb` (`Dependent`) → `D_inlet`, `L_engine` |
| propulsion → weights | `F16WeightsL{2,3}(json_path, req_path, geom, prop)` | `prop.T_SL`, `prop.bypass_ratio`, and at L3 `prop.get_TSFC(cruise)` |
| geometry → propulsion | none | — |

Propulsion consumes **zero** geometry. `PropL2` *produces* engine length/diameter
(Raymer Eq. 10.5/10.6/10.11/10.12) as outputs nothing reads back — geometry sizes the nacelle
independently from thrust.

---

## 3. Quantity → level, member, citation

### Thrust lapse α

| Level | Function | Formula | Citation |
|---|---|---|---|
| L1 | `PropL1.get_thrust_lapse` → `sigma_lapse(ρ, m)` | `α = σ^m`, `σ = ρ/ρ_SL`; `m` by engine type | Martins AE481 metabook Eq. 10.9 (turbofan m = 0.6; turbojet m = 1.0 per Eq. 10.7) |
| L2 AB/max | `PropL2.thrust_lapse_AB(δ₀, θ₀, TR)` | θ₀ ≤ TR → δ₀; θ₀ > TR → `δ₀(1 − 3.5(θ₀−TR)/θ₀)` | Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54a |
| L2 mil (dry) | `PropL2.thrust_lapse_mil(δ₀, θ₀, TR)` | θ₀ ≤ TR → 0.6δ₀; θ₀ > TR → `0.6δ₀(1 − 3.8(θ₀−TR)/θ₀)` | Mattingly Eq. 2.54b |
| L2 mil-on-AB scale | `PropL2.get_thrust_lapse_mil_on_AB_scale` | `α_mil·(T_SL_mil/T_SL_wet)` | Mattingly Eq. 2.54b + Brandt `Consts` col AU convention |

`ρ_SL` = 0.002377 slug/ft³ [Mattingly App. B]. `δ₀`, `θ₀` are total pressure/temperature ratios
[Mattingly Eq. 2.52], carried on `AircraftState`.

### TSFC

| Level | Function | Formula | Citation | Units |
|---|---|---|---|---|
| L1 | `PropL1.get_TSFC` (table) | M < 0.4 → 0.70 loiter; M ≥ 0.4 → 0.80 cruise | Raymer 6th ed. Table 3.3, low-bypass turbofan | 1/hr |
| L2 mil | `PropL2.TSFC_mil(C1, C2, M, θ)` | `(0.90 + 0.30M)√θ` | Mattingly Eq. 3.12 + 3.55a | 1/hr |
| L2 AB | `PropL2.TSFC_AB(C1, C2, M, θ)` | `(1.60 + 0.27M)√θ` | Mattingly Eq. 3.12 + 3.55b | 1/hr |
| L2 installed | `compute_TSFC_installed` / `_AB_installed` | uninstalled × `TSFC_install_factor` (1.08) | Brandt `Miss!C25` | 1/hr |

`θ` = static temperature ratio. The `C1/C2` coefficients are engine-class constants selected by
`engine_type` via `PropL2.lookup_TSFC_coeffs` — not class `Constant`s and not in the JSON. Mattingly
TSFC is **uninstalled** by default; Brandt's stored 0.70 / 2.20 are already **installed**, so the 1.08
factor must not be applied on top of them. The L1 M = 0.4 threshold is an L1 approximation (segment
type is not on `AircraftState`).

### Parametric engine sizing

| Quantity | Function | Citation |
|---|---|---|
| Throttle ratio TR | `PropL2.compute_TR(T_t4_max_R, T_t4_SLS_R)` = `T_t4_max/T_t4_SLS` | Mattingly Eq. D.6 |
| Engine W / L, SFC (AB) | `PropL2.engine_{weight,length}_AB`, `SFC_{max,cruise}_AB` | Raymer §10.3.2, Eq. 10.10/10.11/10.13/10.15 |

`engine_weight_AB` = `0.0637·T^1.1·M^0.25·e^(−0.81·BPR)` (Eq. 10.10) is wired: weights calls it
through propulsion DI. `engine_length_AB`, `SFC_max_AB`, `SFC_cruise_AB` are unit-tested but not yet
wired. The unused non-afterburning family and the diameter / cruise-thrust regressions were removed
(see `docs/decision_log.md`).

---

## 4. As-built values

Computed live 2026-07-26 at 36,000 ft / M 0.87 unless noted.

| Quantity | Property / function | L1 | L2 | Brandt | Brandt cell |
|---|---|---|---|---|---|
| AB SLS thrust | `T_SL` (input) | 23,770 lbf | 23,770 lbf | 23,770 | `Engn!T_AB_SLS = Main!D29` |
| AB SLS thrust alias | `T_SL_wet` (**`Dependent`** on `T_SL`) | 23,770 lbf | 23,770 lbf | 23,770 | as above |
| mil SLS thrust | `T_SL_mil` (input) | — | 15,000 lbf | 15,000 | `Engn!T_mil_SLS` |
| throttle ratio | `TR` (`Dependent`) | — | 1.0 | 1.0 | `Engn!S1` |
| bypass ratio | `bypass_ratio` (input) | — | 0.71 | — | F100-PW-200 |
| TSFC install factor | `TSFC_install_factor` (input) | — | 1.08 | 1.08 | `Miss!C25 = Main!C25` |
| thrust lapse α (AB) | `thrust_lapse` | 0.48374118 | 0.36739545 | 0.33264 (`AT24`) | `Consts!AT` |
| TSFC (mil) | `get_TSFC` | 0.80 | 1.0071158 | 0.70 SLS | `Engn!TSFC_mil` |
| engine weight | `PropL2.engine_weight_AB(T_SL, 2.0, 0.71)` | — | 2775.021 lbf | 4730.23 (`0.199·T_AB`) | `Wt!B22` |
| nacelle diameter | (geometry, from `T_SL`) | — | 3.5370222 ft | 3.537 | `Engn!D_nac` |

`T_SL_wet` is **`Dependent`, not a JSON input** — it was a self-documented alias of `T_SL`, i.e. the
same number keyed twice with nothing keeping the copies in sync. `TR` is degenerate ≡ 1.0 because
only `T_t4_max` is an input and `compute_TR` defaults `T_t4_SLS` to it; this matches Brandt and is an
accepted limitation, not a bug. The `Dependent` form is still correct-by-construction.

### Brandt lapse at the six constraint conditions

Live-verified from `Brandt-F16-A.xls` `Consts` rows 23–28. **AS** = dry lapse (δ₀ basis, normalized to
`T_SL_dry`); **AT** = AB lapse (normalized to `T_SL_AB`); **AU** = effective lapse on the `T_SL_AB`
axis, `=(AS·T_dry + %AB/100·(AT·T_AB − AS·T_dry))/T_AB`. For 100 %-AB rows AU = AT; for the 0 %-AB
cruise row AU = AS·(T_dry/T_AB).

| Condition | Row | alt (ft) | M | %AB | n | AS | AT | AU |
|---|---|---|---|---|---|---|---|---|
| dash / max Mach | 23 | 36,000 | 1.60 | 100 | 1.0 | 0.29829 | 0.57698 | 0.57698 |
| cruise | 24 | 36,000 | 0.87 | 0 | 1.0 | 0.27111 | 0.33264 | 0.17108 |
| max altitude | 25 | 50,000 | 0.87 | 100 | 1.0 | 0.13879 | 0.17029 | 0.17029 |
| combat turn, subsonic | 26 | 20,000 | 0.87 | 100 | 4.5 | 0.55566 | 0.68178 | 0.68178 |
| combat turn, supersonic | 27 | 36,000 | 1.40 | 100 | 1.4 | 0.35786 | 0.55656 | 0.55656 |
| Ps = 500 | 28 | 10,000 | 0.87 | 100 | 1.0 | 0.70273 | 0.85355 | 0.85355 |

The framework's Mattingly α_AB compares against **AT**; a dry point (cruise) compares against **AU**.

### Brandt's own engine model (reference, for the Mattingly-vs-Brandt contrast)

- Dry: θ₀ ≤ TR → `α = δ₀(1 − 0.3M)`; θ₀ > TR → `δ₀(1 − 0.3M − 1.7(θ₀−TR)/θ₀)` [`Engn(s)` row 4]
- AB: θ₀ ≤ TR → `α = δ₀(1 − 0.1√M)`; θ₀ > TR → `δ₀(1 − 0.1√M − 2.2(θ₀−TR)/θ₀)` [`Engn(s)` row 15]
- `TSFC_dry = 0.70(1 + 0.35|M|)√α_dry` [row 7]; `TSFC_AB = 2.20(1 + 0.35|M−0.4|)√α_AB` [row 19]

---

## 5. Open items

| Item | Status |
|---|---|
| ~~`bypass_ratio` = 0.71 is traceable to no in-repo source~~ **FIXED 2026-07-30** | pinned to `[Nicolai & Carichner Table 14.3, F100-PW-100]`, `_cite_bypass_ratio` in `f16a_L2.json` |
| `PropL2` parametric sizing beyond Eq. 10.10 (engine length, diameter, cruise SFC/thrust) is implemented and unit-tested but **unwired** | geometry sizes the nacelle independently |
| No L3 propulsion tier | by decision, not an omission — label L3 propulsion numbers "computed by `F16PropL2`" |

Propulsion carries no deliberately-red `testTODO_` tests.
