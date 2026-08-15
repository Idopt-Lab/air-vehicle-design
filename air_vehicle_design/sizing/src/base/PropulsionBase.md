# PropulsionBase

Tier-1 abstract enforcer (`classdef (Abstract) PropulsionBase < handle`) for every propulsion
discipline class. It declares only the two methods orchestrators call plus the sea-level thrust
property, and provides one defaulted utility. No equations, no coefficients.

---

## 1. Inheritance

```
PropulsionBase → PropulsionModelLN (abstract) → F16PropLN (concrete)
```

Each `PropulsionModelLN` enforcer inherits `PropulsionBase` **directly**, not
`PropulsionModelL(N-1)`.

The `PropL1` / `PropL2` static toolboxes hold the equations and are **not** in this chain — concrete
classes call them as `PropLN.method(obj, state)`.

**Propulsion is L1 / L2 only.** There is no L3 tier and none is planned: `F16PropL2` serves the L3
rung, and anything reporting an L3 propulsion number must label it "computed by `F16PropL2`".

## 2. Abstract contract

Property every concrete class must define:

| Property | Meaning |
|---|---|
| `T_SL` | sea-level static (max / AB) thrust, lbf |

Methods every concrete class must implement:

| Method | Returns | Used by |
|---|---|---|
| `thrust_lapse(obj, state, rating)` | `α = T_at_rating(alt, M)/T_SL`, scalar in [0, 1], on the one max-power `T_SL` basis | constraint analysis, the sizing loop, mission `select_alpha` |
| `get_TSFC(obj, state)` | mil-power TSFC, `lbf_fuel/(hr·lbf_thrust)` | the future Breguet-range mission analysis; weights L3 reads it at the cruise condition |

**`TSFC` is not an abstract property**, deliberately. It was one until 2026-07-25 and was removed:
TSFC is a function of the flight state, not a stored scalar, so there was nothing meaningful for a
concrete class to put in it. `F16PropL1` satisfied it with a self-labelled "PLACEHOLDER:
abstract-contract artifact" `TSFC = 0` while the real value came from `get_TSFC(obj, state)` — so any
consumer trusting the documented property contract read **0** instead of a TSFC. The abstract
*method* is the contract.

## 3. Thrust rating

`thrust_lapse` takes a `rating` string naming the engine power setting; each concrete class
validates it against the ratings its engine actually has:

| Aircraft class | Ratings | Meaning |
|---|---|---|
| jet fighter (afterburning) | `"mil"`, `"AB"` | military/dry, full afterburner |
| transport (no afterburner) | `"cont"`, `"TO"`, `"max"` | max continuous (0.94× takeoff), takeoff |

All ratings are expressed on the **one max-power `T_SL` basis** (`α = T_at_rating(alt,M) / T_SL`,
with `T_SL` the max/AB SLS thrust), so every rating lands on the same `T_SL/W_TO` constraint-diagram
axis — a dry/`"mil"` fighter condition (e.g. Cruise) stays comparable with an AB-flown one. This
replaces the former `thrust_lapse_mil_on_AB_scale` utility: `thrust_lapse(state, "mil")` now returns
`T_mil(alt,M)/T_SL_AB`. `F16PropL1`'s density-only lapse cannot distinguish power settings, so its
`"mil"` and `"AB"` return the same value; `F16PropL2` returns the real
`α_mil·(T_SL_mil/T_SL_wet)` for `"mil"`.

The reason this exists: a dry-power point-performance condition (cruise is flown at 0 % AB) has to
be expressed on the same `T_SL_AB / W_TO` axis as the AB-flown conditions, or the constraint diagram
mixes two thrust scales.

## 4. Conventions

Applied at every fidelity level:

- **`thrust_lapse` is always on the AB/max basis.** `T_SL` is the afterburning sea-level static
  thrust; `α` is dimensionless and normalized to it. Mil-power lapse is a separate accessor.
- **TSFC is always mil-power and always 1/hr** (`lbf_fuel/(hr·lbf_thrust)`). Concrete classes expose
  `compute_TSFC_AB` separately where an afterburning value is needed.
- **Installed vs uninstalled is a live trap.** The Mattingly TSFC at L2 is *uninstalled*; Brandt's
  stored SLS values (0.70 mil / 2.20 AB) are *already installed*, so the 1.08 factor must not be
  applied on top of them. The base does not police this — see `F16PropL2.md`.

## 5. To-dos

None. This file is a contract, not a model.
