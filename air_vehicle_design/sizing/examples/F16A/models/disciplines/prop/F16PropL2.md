# F16PropL2

F-16A Block 10/15 Level-2 propulsion, the Mattingly parametric engine model.
`classdef F16PropL2 < PropulsionModelL2`.

**`F16PropL2` also serves the L3 rung.** There is no L3 propulsion tier and none is planned, so
anything reporting an L3 propulsion number must label it "computed by `F16PropL2`".

---

## 1. Constructor

```matlab
p2 = F16PropL2(f16a_spec_path(2));
```

`F16PropL2(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.propulsion` block of `f16a_L2.json`. Sets only the input properties; `TR` and `T_SL_wet`
come from their `Dependent` getters.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | Selects the TSFC coefficient row via `PropL2.lookup_TSFC_coeffs` (F100-PW-200 class) |
| `T_SL` | 23770 | lbf | AB (max) SLS thrust; the `PropulsionBase` contract property [Brandt `Main!D29`; T.O. 1F-16A-1 §I] |
| `T_SL_mil` | 15000 | lbf | Military (dry) SLS thrust [Brandt `Main!C29`; T.O. §I] |
| `T_t4_max_F` | 2566 | °F | Burner-exit total temperature; feeds `get.TR` [Mattingly Table C.4] |
| `TSFC_install_factor` | 1.08 | — | Installed = uninstalled × factor [Brandt `Miss!C25`] |
| `bypass_ratio` | 0.71 | — | F100-PW-200 class [Nicolai & Carichner Table 14.3, F100-PW-100]. Read by the weights tier for Raymer Eq. 10.10 |

## 3. Derived (`Dependent`)

| Property | Value | Note |
|---|---|---|
| `TR` | 1.0 | `PropL2.compute_TR(T_t4_max_F + 459.67)` [Mattingly Eq. D.6] |
| `T_SL_wet` | 23770 lbf | ≡ `T_SL`. Kept because call sites read the wet/AB name explicitly. `Dependent`, so it cannot diverge from `T_SL` |

**`TR` is degenerate ≡ 1.0, accepted.** `TR = T_t4_max / T_t4_SLS`, but only `T_t4_max` is an input,
so `compute_TR` defaults `T_t4_SLS` to it. Mutating the input cannot change the value. This matches
Brandt `Engn(s)!S1`.

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `F16PropL2` (constructor) | input json path | F-16 L2 propulsion object |
| `get.T_SL_wet` (getter) | design object | AB SLS thrust [lbf] |
| `get.TR` (getter) | design object | throttle ratio |
| `get_thrust_lapse_parametric` | design object, aircraft state, rating (`"mil"`/`"AB"`) | alpha on the AB `T_SL` axis |
| `get_TSFC_installed` | design object, aircraft state, rating (`"mil"`/`"AB"`) | installed TSFC [1/hr] |

`rating` is validated by `mustBeMember(rating, ["mil","AB"])`. The `PropulsionBase` names
`get_thrust_lapse` and `get_TSFC` reach these two methods through the concrete bridges on
`PropulsionModelL2`; the class does not write them itself.

**Both ratings land on the AB `T_SL` axis.** Mattingly Eq. 2.54b normalizes the mil lapse to
`T_SL_mil`, so the `"mil"` branch passes `T_SL_mil` as its rating thrust to
`PropL2.compute_normalized_thrust_lapse`, giving `α_mil × 15000/23770 = α_mil × 0.6310475`
[Brandt `Consts` col AU]. The `"AB"` branch passes `T_SL`, so its factor is 1 by construction. Without
this, a dry condition and an AB condition would sit on two different thrust scales and could not share
one constraint-diagram axis.

`get_TSFC_installed` reads the coefficient row once, evaluates `PropL2.TSFC_mil` or `PropL2.TSFC_AB`
by rating, then applies `TSFC_install_factor`. Since `get_TSFC` bridges to it, **`get_TSFC` returns an
installed value at L2**, unlike L1.

### As-built values

At 36,000 ft / M 0.87:

| Quantity | Value |
|---|---|
| `get_thrust_lapse_parametric(state, "AB")` | 0.3673955 |
| `get_thrust_lapse_parametric(state, "mil")` | 0.1391064 |
| `get_TSFC_installed(state, "mil")` | 1.0876850 1/hr |
| `get_TSFC_installed(state, "AB")` | 1.7190295 1/hr |

---

## 5. To-dos

| Item | Status |
|---|---|
| `TR` degenerate ≡ 1.0; a separate `T_t4_SLS` input would be needed for real throttle-ratio visibility | deliberately not added |
| `n_engines` is absent, so `ClimbGradientConstraint` guards with `isprop` and errors `ClimbGradientConstraint:missingNEngines` | open |
| The `else` branch in each rating switch is unreachable, because the `arguments` block rejects any other string first | open |

L2 propulsion carries no deliberately-red `testTODO_` tests.
