# B777PropL1

Boeing 777-200LR Level-1 propulsion — 2× GE90-110B, the metabook Example 4.2 tier.
`classdef B777PropL1 < PropulsionModelL1`.

**No afterburner.** A high-bypass transport uses the transport rating set `"cont"`/`"TO"`/`"max"`,
not the fighter `"mil"`/`"AB"`. `T_SL` is the max (takeoff) SLS thrust; `"TO"`/`"max"` give the full
`σ^m` lapse and `"cont"` applies the 0.94 max-continuous derate [metabook Eq. 4.25].

---

## 1. Constructor

```matlab
p1 = B777PropL1(b777_spec_path(1));
```

`B777PropL1(json_path)` — path required, no silent default. Reads the `.propulsion` block of
`b777_L1.json`. `tsfc_cruise` is the one optional key: the constructor keeps the property default
when the JSON omits it.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"high_bypass_turbofan"` | — | `PropulsionModelL1` contract [metabook §4.11, GE90-110B]. A contract and documentation key only: the lapse exponent is read from `lapse_exponent_m`, not resolved from it |
| `T_SL` | 220000 | lbf | max SLS thrust, total for both engines [`PropulsionBase` contract; metabook Fig. 4.7 caption] |
| `n_engines` | 2 | — | engine count [metabook §4.11] |
| `lapse_exponent_m` | 0.6 | — | density-ratio lapse exponent `α = σ^m` [metabook Eqs. 4.55/10.9; decision **D5**, §5]. An explicit cited input rather than a table lookup, so the modelling choice is visible |
| `tsfc_cruise` | 0.52 | 1/hr | cruise TSFC [metabook Table 10.1, GE90 rows at 40,000 ft] — see §4 |

Private constant: `MAX_CONTINUOUS_FRACTION` = 0.94, max-continuous thrust as a fraction of takeoff
thrust [metabook Eq. 4.25].

## 3. Derived (`Dependent`)

None. L1 propulsion holds no derived geometry; every quantity is an input or a per-`state` method.
There is no `T_SL_wet` alias either — a transport has no wet rating.

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `B777PropL1` (constructor) | input json path | B777 propulsion object |
| `get_thrust_lapse_categorical` | design object, aircraft state, rating (`"cont"`/`"TO"`/`"max"`) | alpha |
| `get_thrust_lapse_base` | design object, aircraft state | alpha, no rating derate |
| `get_TSFC` | design object, ignored state | thrust-specific fuel consumption [1/hr] |
| `lookup_TSFC` | design object, aircraft state | same, an alias for `get_TSFC` |

`get_thrust_lapse_categorical` calls `PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m)`, then
applies the 0.94 factor for `"cont"`. `rating` is validated with
`mustBeMember(rating, ["cont","TO","max"])`. `get_thrust_lapse_base` returns the same `σ^m` with no
derate; it satisfies no contract.

Consumers call the `PropulsionBase` name `get_thrust_lapse`, which `PropulsionModelL1` bridges
to `get_thrust_lapse_categorical`.

`get_TSFC` holds the value and `lookup_TSFC` forwards to it, so the enforcer's concrete `get_TSFC`
bridge is overridden here. `F16PropL1` runs the pair the other way round.

`σ = ρ/ρ_SL` comes from the `AircraftState`, so the model uses ISA density, not the metabook's
printed off-ISA ratios (0.2846 at "40,000 ft", 0.2331 at "42,000 ft"). Those printed ratios are used
only by the comparison report, for parity with the printed equations (D5).

### As-built values

| Quantity | Value |
|---|---|
| `get_thrust_lapse_categorical(SLS M 0.2, "max")` | 0.9999728427 |
| `get_thrust_lapse_categorical(SLS M 0.2, "cont")` | 0.9399744721 |
| `get_thrust_lapse_categorical(35 kft M 0.84, "max")` | 0.4951081703 |
| `get_thrust_lapse_categorical(40 kft M 0.84, "max")` | 0.4312500919 |
| `get_TSFC(any state)` | 0.52 1/hr |

---

## 5. TSFC — the cruise-deck value, not the generic Mattingly form

`get_TSFC` returns `tsfc_cruise = 0.52`, the GE90's real deck SFC [metabook Table 10.1, ≈ 0.50–0.524
at 40,000 ft cruise partial power].

It is deliberately **not** the generic high-bypass form `c = (0.4 + 0.45·M)·√θ` [metabook Eq. 10.11 =
Mattingly 1996 Eq. 1.36a], which gives ≈ 0.675 at M 0.84 / 40 kft and overestimates the real GE90 by
≈ 30 %. That overestimate makes the 6,000-nmi design-range mission demand more fuel than the aircraft
can carry, so `converge_W0` diverges. The engine's own Table 10.1 deck value is a metabook-sourced
DATA input, not a backfill from the sizing answer; with it the modelled 777 closes and sits in the
T–S feasible region, matching the metabook's own Fig. 4.7.

`PropL1.tsfc_mattingly_hibpr_raw(state.mach, state.theta)` evaluates Eq. 10.11 where the comparison
report needs to quantify the overestimate.

---

## 6. Design decisions

| Decision | Choice | Rationale / citation |
|---|---|---|
| **D5** — lapse exponent `m` | 0.6 | Metabook Example 4.2 uses `α = σ^0.6` (Eqs. 4.55–4.57), the generic Eq. 10.9 fit, with no engine-type justification. Carried as a cited JSON input so the choice is explicit. The metabook's own GE90 Table 10.1 data fits `m ≈ 1.0–1.1` for a high-BPR turbofan; the printed 0.6 is a metabook-internal choice, adopted for worked-example parity (`b777_L1.md` §4.2) |
| Cruise TSFC | 0.52 [metabook Table 10.1] | The generic Eq. 10.11 form overestimates the GE90 by ≈ 30 % and diverges the closure — see §5 |
| No afterburner | transport set `{cont, TO, max}` | high-BPR transport; `"TO"` and `"max"` are the same full takeoff value, `"cont"` is 0.94× [Eq. 4.25] |

## 7. To-dos

| Item | Guard |
|---|---|
| The per-engine GE90-110B rating (≈ 110,000 lbf, `T_SL/n_engines`) is a stand-in. Metabook Table 10.1 prints the GE90 SLS range 76,000–115,000 lb, which brackets but does not pin the -110B rating; the cited value is the metabook total 220,000 lbf | `b777_L1.md` §4.1 / §6 — needs a GE or Boeing engine-rating document |
| `testTODO_WingMountedTailArmUncited` in `TestB777Disciplines` is deliberately red, but it belongs to tail sizing, not propulsion | tracked with the geometry example |
