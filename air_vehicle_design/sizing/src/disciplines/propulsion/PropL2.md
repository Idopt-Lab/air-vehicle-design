# PropL2

Level-2 propulsion static toolbox (`classdef PropL2`, `methods (Static)` only). Called as
`PropL2.method(...)`; never instantiated. `F16PropL2` inherits `PropulsionModelL2` and delegates here.

L2 is the **Mattingly parametric model**, with separate mil (dry) and AB (wet) branches for both
thrust lapse and TSFC. `F16PropL2` also serves the L3 rung — there is no L3 propulsion tier.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `get_thrust_lapse`, `get_thrust_lapse_mil/_AB`, `get_thrust_lapse_mil_on_AB_scale`, `get_TSFC`, `get_TSFC_mil/_AB`, `get_TSFC_installed`, `get_TSFC_AB_installed` |
| Low-level — lapse and TSFC | `thrust_lapse_AB`, `thrust_lapse_mil`, `TSFC_mil`, `TSFC_AB`, `lookup_TSFC_coeffs`, `compute_TR` |
| Low-level — parametric sizing | `engine_{weight,length,diam}_{nonAB,AB}`, `SFC_{max,cruise}_{nonAB,AB}`, `thrust_cruise_{nonAB,AB}` |

## 2. Equations

**Thrust lapse** [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54a afterburning, Eq. 2.54b military]. Both branch on the
total temperature ratio against the throttle ratio:

$$\alpha_{AB} = \begin{cases}
  \delta_0 & \theta_0 \le TR\\[3pt]
  \delta_0\left[1 - 3.5\,\dfrac{\theta_0 - TR}{\theta_0}\right] & \theta_0 > TR
\end{cases}$$

$$\alpha_{mil} = \begin{cases}
  0.6\,\delta_0 & \theta_0 \le TR\\[3pt]
  0.6\,\delta_0\left[1 - 3.8\,\dfrac{\theta_0 - TR}{\theta_0}\right] & \theta_0 > TR
\end{cases}$$

$\delta_0$ and $\theta_0$ are the total pressure and temperature ratios carried on `AircraftState`
[Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.52].

**Mil lapse on the AB scale** [Brandt F-16A.xls, Consts col AU] — lets a dry-power condition share the
$T_{SL,AB}/W_{TO}$ constraint-diagram axis with AB-flown conditions:

$$\alpha_{mil\to AB} = \alpha_{mil}\,\frac{T_{SL,mil}}{T_{SL,wet}}$$

**TSFC** [Mattingly: Aircraft Engine Design, 2nd edition Eq. 3.12 with the coefficients of Eq. 3.55a mil / 3.55b AB], with
$\theta$ the *static* temperature ratio:

$$c_t = \left(C_1 + C_2 M\right)\sqrt{\theta}$$

For a low-bypass afterburning turbofan: $C_1/C_2$ = 0.90 / 0.30 mil, 1.60 / 0.27 AB. `engine_type`
selects these engine-class constants inside `lookup_TSFC_coeffs` — not class `Constant`s, not in the JSON.

**Installed TSFC** [Brandt Miss!C25]: $c_{t,installed} = 1.08\,c_{t,uninstalled}$.

**Throttle ratio** [Mattingly: Aircraft Engine Design, 2nd edition Eq. D.6]:

$$TR = \frac{T_{t4,max}}{T_{t4,SLS}}$$

**Parametric engine sizing** [Raymer 6th ed. Sec. 10.3.2]. Eq. 10.4–10.9 non-afterburning, Eq.
10.10–10.15 afterburning. Only the afterburning engine weight [Eq. 10.10] is wired — the weights tier
calls it through propulsion DI:

$$W_{engine} = 0.0637\,T^{1.1}\,M^{0.25}\,e^{-0.81\,BPR}$$

## 3. Installed vs uninstalled

The Mattingly TSFC above is **uninstalled**. Brandt's stored SLS values (0.70 mil / 2.20 AB) are
**already installed** — they include the 1.08 factor. Applying 1.08 again double-counts. Compare the
framework's *installed* rows against Brandt's stored values.

## 4. As-built values

At 36,000 ft / M 0.87: $\alpha_{AB} = 0.36739545$, $c_{t,mil} = 1.0071158$ hr⁻¹ (uninstalled).
`engine_weight_AB(23770, 2.0, 0.71)` = 2775.021 lbf.

**`TR` is degenerate at 1.0.** Only $T_{t4,max}$ is an input; $T_{t4,SLS}$ is unknown, so
`compute_TR` defaults it to $T_{t4,max}$. This matches Brandt (Engn(s)!S1). A separate $T_{t4,SLS}$
input would be needed for genuine throttle-ratio visibility.

## 5. To-dos

| Item | Status |
|---|---|
| Everything in the parametric-sizing block except Eq. 10.10 is implemented and unit-tested but **unwired** — geometry sizes the nacelle independently from thrust | — |
| `TR` degenerate at 1.0; a separate $T_{t4,SLS}$ input would be needed | deliberately not added |

No deliberately-red `testTODO_` tests.
