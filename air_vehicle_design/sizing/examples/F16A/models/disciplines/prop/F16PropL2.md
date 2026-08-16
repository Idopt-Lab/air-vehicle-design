# F16PropL2

F-16A Block 10/15 Level-2 propulsion — the Mattingly parametric engine model. `classdef F16PropL2 <
PropulsionModelL2`; every abstract method is a one-line delegation into the `PropL2` static toolbox.

**`F16PropL2` also serves the L3 rung.** There is no L3 propulsion tier and none is planned, so
anything reporting an L3 propulsion number must label it "computed by `F16PropL2`".

---

## 1. Constructor

```matlab
p2 = F16PropL2(f16a_spec_path(2));
```

`F16PropL2(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.propulsion` block of `f16a_L2.json`. Sets only the input properties; `TR` and `T_SL_wet`
are produced live by their `Dependent` getters.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | Selects the Mattingly TSFC coefficient set via `PropL2.lookup_TSFC_coeffs` (F100-PW-200 class) |
| `T_SL` | 23770 | lbf | AB (max) SLS thrust; `PropulsionBase` contract [Brandt `Engn!T_AB_SLS = Main!D29`; T.O. 1F-16A-1 §I] |
| `T_SL_mil` | 15000 | lbf | Military (dry) SLS thrust [Brandt `Engn!T_mil_SLS = Main!C29`; T.O. §I] |
| `T_t4_max_F` | 2566 | °F | Burner-exit total temperature; feeds `get.TR` [Mattingly Table C.4, F100-PW-100] |
| `TSFC_install_factor` | 1.08 | — | Installed = uninstalled × factor [Brandt `Miss!C25 = Main!C25`] |
| `bypass_ratio` | 0.71 | — | F100-PW-200. Feeds Raymer Eq. 10.10, which the weights tier calls through propulsion DI |

## 3. Derived (`Dependent`)

| Property | Value | Getter / citation |
|---|---|---|
| `TR` | 1.0 | `PropL2.compute_TR(T_t4_max_F + 459.67)` [Mattingly Eq. D.6] |
| `T_SL_wet` | 23770 lbf | ≡ `T_SL`. It was a self-documented alias stored as a separate JSON input — the same number keyed twice with nothing keeping the copies in sync |

**`TR` is degenerate ≡ 1.0, accepted.** `TR = T_t4_max / T_t4_SLS`, but only `T_t4_max` is an input;
`T_t4_SLS` is unknown, so `compute_TR` defaults it to `T_t4_max`. Mutating the input therefore cannot
change the value. This matches Brandt (`Engn(s)!S1`) and is a known limitation, not a bug — genuine
optimization visibility would need a separate `T_t4_SLS` input, deliberately not added. The
`Dependent` form is still correct-by-construction.

---

## 4. Methods

| Method | Delegates to | Formula | Source |
|---|---|---|---|
| `thrust_lapse(state, "AB")` / `compute_thrust_lapse_AB` | `PropL2.thrust_lapse_AB(δ₀, θ₀, TR)` | θ₀ ≤ TR → δ₀; θ₀ > TR → `δ₀(1 − 3.5(θ₀−TR)/θ₀)` | Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54a |
| `compute_thrust_lapse_mil` | `PropL2.thrust_lapse_mil` | θ₀ ≤ TR → 0.6δ₀; θ₀ > TR → `0.6δ₀(1 − 3.8(θ₀−TR)/θ₀)` | Mattingly Eq. 2.54b |
| `thrust_lapse(state, "mil")` | `PropL2.get_thrust_lapse_mil_on_AB_scale` | `α_mil·(T_SL_mil/T_SL_wet)` — mil lapse on the AB `T_SL` axis (was `thrust_lapse_mil_on_AB_scale`) | Mattingly Eq. 2.54b + Brandt `Consts` col AU convention |
| `get_TSFC(state)` / `compute_TSFC_mil` | `PropL2.TSFC_mil(C1, C2, M, θ)` | `(0.90 + 0.30M)√θ` | Mattingly Eq. 3.12 + 3.55a |
| `compute_TSFC_AB` | `PropL2.TSFC_AB` | `(1.60 + 0.27M)√θ` | Mattingly Eq. 3.12 + 3.55b |
| `compute_TSFC_installed` / `compute_TSFC_AB_installed` | — | uninstalled × `TSFC_install_factor` | Brandt `Miss!C25` |

`δ₀`, `θ₀` are total pressure/temperature ratios [Mattingly Eq. 2.52], carried on `AircraftState`;
`θ` is the static temperature ratio.

**The `C1/C2` coefficients (mil 0.90/0.30, AB 1.60/0.27) are engine-class constants** selected by
`engine_type` inside the toolbox — not class `Constant`s and not in the JSON.

**Installed vs uninstalled matters here.** The Mattingly TSFC is uninstalled; Brandt's stored SLS
values (0.70 mil / 2.20 AB) are *already* installed, so the 1.08 factor must not be applied on top of
them.

### As-built values

At 36,000 ft / M 0.87:

| Quantity | Value |
|---|---|
| `thrust_lapse` (AB) | 0.36739545 |
| `get_TSFC` (mil, uninstalled) | 1.0071158 1/hr |
| `PropL2.engine_weight_AB(T_SL, 2.0, 0.71)` | 2775.021 lbf (Raymer Eq. 10.10) |

---

## 5. To-dos

| Item | Status |
|---|---|
| `bypass_ratio` = 0.71 | pinned to `[Nicolai & Carichner Table 14.3, F100-PW-100]`, `_cite_bypass_ratio` in `f16a_L2.json` |
| `TR` is degenerate ≡ 1.0 — a separate `T_t4_SLS` input would be needed for real throttle-ratio visibility | accepted, deliberately not added |
| `PropL2`'s parametric engine sizing beyond Eq. 10.10 (length, diameter, cruise SFC/thrust — Eq. 10.4–10.15) is implemented and unit-tested but **unwired**; geometry sizes the nacelle independently from `T_SL` | — |

L2 propulsion carries no deliberately-red `testTODO_` tests.
