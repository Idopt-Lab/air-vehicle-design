# PropL2

Level-2 propulsion static toolbox. `classdef PropL2`, `methods (Static)` only; called as
`PropL2.method(...)` and never instantiated.

Every static takes scalars or a category string, never a design object and never an `AircraftState`.
The concrete class reads `state.delta_0`, `state.theta_0`, `state.mach`, `state.theta`, picks the
coefficient row, then evaluates the equation.

**L2 is the Mattingly parametric model**, with separate mil (dry) and AB (wet) branches for both
thrust lapse and TSFC.

---

## 1. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_thrust_lapse_AB` | δ₀, θ₀, throttle ratio | alpha on the AB reference | Mattingly 2nd ed. Eq. 2.54a |
| `compute_thrust_lapse_mil` | δ₀, θ₀, throttle ratio | alpha on the mil reference | Mattingly 2nd ed. Eq. 2.54b |
| `compute_normalized_thrust_lapse` | alpha, rating thrust, reference thrust | alpha rescaled onto the reference | Brandt F-16A.xls `Consts` col AU |
| `TSFC_mil` | C1, C2, Mach, θ | TSFC [1/hr] | Mattingly 2nd ed. Eq. 3.12 + 3.55a |
| `TSFC_AB` | C1, C2, Mach, θ | TSFC [1/hr] | Mattingly 2nd ed. Eq. 3.12 + 3.55b |
| `compute_TSFC_installed` | uninstalled TSFC, install factor | installed TSFC [1/hr] | Brandt `Miss!C25` |
| `lookup_TSFC_coeffs` | engine type | struct with `.C1_mil`, `.C2_mil`, `.C1_AB`, `.C2_AB` | Mattingly 2nd ed. Eq. 3.55a/b |
| `compute_TR` | T_t4_max [°R], T_t4_SLS [°R] optional | throttle ratio | Mattingly 2nd ed. Eq. D.6 |
| `engine_weight_AB` | thrust, Mach, bypass ratio | engine weight [lbf] | Raymer 7th ed. Eq. 10.10 |
| `engine_length_AB` | thrust, Mach | engine length [ft] | Raymer 6th ed. Eq. 10.11 |
| `SFC_max_AB` | bypass ratio | max-throttle SFC [1/hr] | Raymer 6th ed. Eq. 10.13 |
| `SFC_cruise_AB` | bypass ratio | cruise SFC [1/hr] | Raymer 6th ed. Eq. 10.15 |

`lookup_TSFC_coeffs` errors `PropL2:unknownEngineType` on an unlisted type rather than returning a
default. `compute_TR` defaults `T_t4_SLS` to `T_t4_max`, which returns 1.0.

### As-built values

At the live F-16A L2 inputs (thrust 23770 lbf, design Mach 2.0, bypass ratio 0.71):

| Quantity | Value |
|---|---|
| `engine_weight_AB` | 2775.0210039 lbf |
| `engine_length_AB` | 16.4876156 ft |
| `SFC_max_AB` | 1.9284901 1/hr |
| `SFC_cruise_AB` | 0.9113400 1/hr |

---

## 2. Equations

**Thrust lapse.** Both branch on the total temperature ratio against the throttle ratio:

$$\alpha_{AB} = \begin{cases}
  \delta_0 & \theta_0 \le TR\\[3pt]
  \delta_0\left[1 - 3.5\,\dfrac{\theta_0 - TR}{\theta_0}\right] & \theta_0 > TR
\end{cases}
\qquad
\alpha_{mil} = \begin{cases}
  0.6\,\delta_0 & \theta_0 \le TR\\[3pt]
  0.6\,\delta_0\left[1 - 3.8\,\dfrac{\theta_0 - TR}{\theta_0}\right] & \theta_0 > TR
\end{cases}$$

δ₀ and θ₀ are the total pressure and temperature ratios carried on `AircraftState`
[Mattingly 2nd ed. Eq. 2.52].

**Lapse renormalization.** Eq. 2.54a normalizes to the AB SLS thrust and Eq. 2.54b to the mil SLS
thrust, so the two are on different scales. `compute_normalized_thrust_lapse` divides out the rating's
own reference and multiplies in the chosen one:

$$\alpha_{ref} = \alpha_{rating}\,\frac{T_{SL,rating}}{T_{SL,ref}}$$

The caller supplies both thrusts, so which rating shares which axis is the design class's decision.

**TSFC**, with θ the *static* temperature ratio:

$$c_t = \left(C_1 + C_2 M\right)\sqrt{\theta}
\qquad
c_{t,installed} = f_{install}\;c_t$$

**Throttle ratio:** $TR = T_{t4,max} / T_{t4,SLS}$.

**Engine sizing** [Raymer 6th ed. §10.3.2, afterburning]:

$$W = 0.0637\,T^{1.1}M^{0.25}e^{-0.81\,BPR}
\quad L = 0.255\,T^{0.4}M^{0.2}
\quad SFC_{max} = 2.1\,e^{-0.12\,BPR}
\quad SFC_{cr} = 1.04\,e^{-0.186\,BPR}$$

---

## 3. Category coverage

`lookup_TSFC_coeffs` holds one row:

| `engine_type` | C1 mil | C2 mil | C1 AB | C2 AB |
|---|---|---|---|---|
| `low_bypass_turbofan`, `low_bypass_turbofan_AB` | 0.90 | 0.30 | 1.60 | 0.27 |

The coefficients are engine-class constants, not class `Constant`s and not JSON inputs.

---

## 4. Installed vs uninstalled

`TSFC_mil` and `TSFC_AB` return **uninstalled** values. Brandt's stored SLS values (0.70 mil,
2.20 AB) are **already installed**, so the install factor must not be applied on top of them. Compare
the framework's installed rows against Brandt's stored values.

---

## 5. To-dos

| Item | Status |
|---|---|
| `engine_length_AB`, `SFC_max_AB` and `SFC_cruise_AB` have no production consumer; geometry sizes the nacelle from thrust independently | open |
| `compute_TSFC_installed` names its output the same as its input, so the assignment reads as a mutation | open |
| `TSFC_mil` and `TSFC_AB` lack the `compute_` prefix their lapse siblings carry | open |
| Raymer Eq. 10.6 / 10.12 engine diameter is unconfirmed between the 6th and 7th editions | open |

No deliberately-red `testTODO_` tests.
