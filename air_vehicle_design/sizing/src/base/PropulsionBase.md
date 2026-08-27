# PropulsionBase

Tier-1 abstract enforcer (`classdef (Abstract) PropulsionBase < handle`) for every propulsion
discipline class. It declares one property and the two methods orchestrators call. No equations, no
coefficients.

---

## 1. Inheritance

```
PropulsionBase → PropulsionModelLN (abstract) → F16PropLN (concrete)
```

Each `PropulsionModelLN` enforcer inherits `PropulsionBase` **directly**, not
`PropulsionModelL(N-1)`. The `PropL1` / `PropL2` static toolboxes hold the equations and are **not**
in this chain.

Both enforcers declare a fidelity-specific method and supply a concrete bridge for the base name, so a
concrete class writes one method per quantity:

| Base name | L1 method | L2 method |
|---|---|---|
| `get_thrust_lapse` | `get_thrust_lapse_categorical` | `get_thrust_lapse_parametric` |
| `get_TSFC` | `lookup_TSFC` | `get_TSFC_installed` |

**Propulsion is L1 / L2 only.** There is no L3 tier and none is planned: `F16PropL2` serves the L3
rung, and anything reporting an L3 propulsion number must label it "computed by `F16PropL2`".

## 2. Abstract contract

| Property | Meaning |
|---|---|
| `T_SL` | sea-level static (max / AB) thrust, lbf |

| Method | Arguments | Outputs |
|---|---|---|
| `get_thrust_lapse` | design object, aircraft state, thrust rating | alpha, scalar in [0, 1] on the max-power `T_SL` basis |
| `get_TSFC` | design object, aircraft state | TSFC, `lbf_fuel/(hr·lbf_thrust)` |

`get_thrust_lapse` is read by constraint analysis, the sizing loop and mission `select_alpha`.
`get_TSFC` is read by the mission analysis and by weights L3 at the cruise condition.

`TSFC` is a method, not an abstract property: it is a function of the flight state, so there is
nothing meaningful for a concrete class to store.

## 3. Thrust rating

`get_thrust_lapse` takes a `rating` string naming the engine power setting; each concrete class
validates it against the ratings its engine actually has:

| Aircraft class | Ratings | Meaning |
|---|---|---|
| jet fighter (afterburning) | `"mil"`, `"AB"` | military/dry, full afterburner |
| transport (no afterburner) | `"cont"`, `"TO"`, `"max"` | max continuous (0.94× takeoff), takeoff |

All ratings are expressed on the **one max-power `T_SL` basis**, `α = T_at_rating(alt,M) / T_SL` with
`T_SL` the max/AB SLS thrust, so every rating lands on the same `T_SL/W_TO` constraint-diagram axis. A
dry-power condition such as Cruise is flown at 0 % AB, and it has to share the axis with the AB-flown
conditions or the diagram mixes two thrust scales.

`F16PropL1`'s density-only lapse cannot distinguish power settings, so its `"mil"` and `"AB"` return
the same value. `F16PropL2` renormalizes, returning `α_mil·(T_SL_mil/T_SL)` for `"mil"`.

## 4. Conventions

- **`get_thrust_lapse` is always on the AB/max basis.** `T_SL` is the afterburning sea-level static
  thrust and alpha is normalized to it.
- **TSFC is always 1/hr** (`lbf_fuel/(hr·lbf_thrust)`). The rating a `get_TSFC` call resolves to is
  the enforcer's decision: L1 has one categorical value, L2 takes an explicit rating.
- **Installed vs uninstalled is a live trap.** The Mattingly TSFC at L2 is uninstalled, and
  `get_TSFC_installed` applies the 1.08 factor; Brandt's stored SLS values (0.70 mil, 2.20 AB) are
  already installed, so the factor must not be applied on top of them. The base does not police this.

## 5. To-dos

| Item | Status |
|---|---|
| The two abstract declarations are 2-argument, but `get_thrust_lapse` is implemented and called with 3 at both levels, and `get_TSFC` with 3 at L2. MATLAB does not enforce abstract arity, so the declarations are documentation only, and they disagree with every implementer | open |
| The commented-out `TSFC_unagumented` abstract property carries two spelling errors and gives lbf/hour where TSFC is 1/hr | open |
