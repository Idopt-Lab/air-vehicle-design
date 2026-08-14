# B777PropL1

Boeing 777-200LR Level-1 propulsion — 2× GE90-110B, the metabook Example 4.2 tier. `classdef
B777PropL1 < PropulsionModelL1`; every method delegates to the `PropL1` static toolbox — no equations
are duplicated here.

**NO AFTERBURNER.** A high-bypass transport has no AB, so the wet/mil/AB thrust distinction the F-16
carries collapses to a single basis: `T_SL` is the max SLS thrust, and `thrust_lapse` and
`thrust_lapse_mil_on_AB_scale` are the SAME lapse.

---

## 1. Constructor

```matlab
p1 = B777PropL1(b777_spec_path(1));
```

`B777PropL1(json_path)` — path required, no silent default. Reads the `.propulsion` block of
`b777_L1.json`.

---

## 2. Inputs

Plain mutable `properties`, set once by the constructor.

| Property | Value | Unit | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"high_bypass_turbofan"` | — | `PropulsionModelL1` contract [metabook §4.11, GE90-110B]. Carried for the contract + documentation; the lapse exponent is read from `lapse_exponent_m`, NOT resolved from this key |
| `T_SL` | 220000 | lbf | max SLS thrust, total (2× GE90-110B) [`PropulsionBase` contract; metabook Fig. 4.7 caption] |
| `n_engines` | 2 | — | engine count [metabook §4.11] |
| `lapse_exponent_m` | 0.6 | — | density-ratio lapse exponent `α = σ^m` [metabook Eqs. 4.55/10.9; decision **D5**, `b777_L1.md` §4.2]. Carried as an explicit INPUT rather than a table lookup so the modelling choice is cited |
| `tsfc_cruise` | 0.52 | 1/hr | cruise TSFC [metabook Table 10.1, GE90 cruise rows at 40,000 ft] — see §4 |

There is no `Dependent` block: L1 propulsion holds no derived geometry. Every quantity is either an
input or a per-`state` method.

---

## 3. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `thrust_lapse(state)` | `α = σ^m`, `σ = ρ/ρ_SL`, `m = lapse_exponent_m`, via `PropL1.sigma_lapse(state.rho, m)`. The engine-type table is bypassed on purpose (D5) | [metabook Eqs. 4.55/10.9] |
| `get_thrust_lapse(state)` | alias for `thrust_lapse` | [metabook Eqs. 4.55/10.9] |
| `thrust_lapse_mil_on_AB_scale(state)` | returns `thrust_lapse` — a high-bypass transport has NO afterburner, so mil and AB thrust are one and the same. Overrides the `PropulsionBase` default only to document that this is deliberate, not an omission | one basis; `b777_L1.md` §4 |
| `get_TSFC(~)` | cruise TSFC [1/hr] = `obj.tsfc_cruise` = 0.52. `state` unused | [metabook Table 10.1] — see §4 |
| `lookup_TSFC(state)` | `PropulsionModelL1` contract alias for `get_TSFC` | [metabook Table 10.1] |

### Thrust lapse

`σ = ρ/ρ_SL` comes from the `AircraftState` — so the B777 model uses ISA density from the state, not
the metabook's printed off-ISA density ratios (0.2846 at "40,000 ft", 0.2331 at "42,000 ft"). Those
printed ratios are used ONLY by the comparison report, for parity with the printed equations (D5).

---

## 4. TSFC — the cruise-deck value, NOT the generic Mattingly form

`get_TSFC` returns `tsfc_cruise = 0.52`, the GE90's real deck SFC [metabook Table 10.1, ~0.50–0.524
at 40,000 ft cruise partial power].

**It is deliberately NOT the generic Mattingly high-bypass form** `c = (0.4 + 0.45·M)·sqrt(θ)`
[metabook Eq. 10.11 = Mattingly 1996 Eq. 1.36a], which gives ≈ 0.675 at M 0.84 / 40 kft and
OVERESTIMATES the real GE90 by ≈ 30 %. That overestimate makes the 6,000-nmi (design-range) max-range
mission demand more fuel than the aircraft can carry, so the TOGW closure (`converge_W0`) diverges.
The engine's own Table 10.1 deck value is a metabook-sourced DATA input (not backfilled from the
sizing answer); using it, the modelled 777 closes and sits in the T–S feasible region, matching the
metabook's own feasible-777 Fig. 4.7.

`PropL1.tsfc_mattingly_hibpr` (Eq. 10.11) stays available; the comparison report evaluates it to
quantify the overestimate.

---

## 5. Design decisions

| Decision | Choice | Rationale / citation |
|---|---|---|
| **D5** — thrust-lapse exponent `m` | `m = 0.6` | The metabook Example 4.2 uses `α = σ^0.6` (Eqs. 4.55–4.57), the GENERIC Eq. 10.9 fit, with no engine-type justification. Carried as a cited JSON input (`lapse_exponent_m`) so the choice is explicit. The metabook's OWN GE90 Table 10.1 data fits `m ≈ 1.0–1.1` for a high-BPR turbofan — the printed 0.6 is a metabook-internal choice, adopted for worked-example parity (`b777_L1.md` §4.2) |
| Cruise TSFC | `tsfc_cruise = 0.52` from [metabook Table 10.1] | The generic Eq. 10.11 form overestimates the GE90 by ~30 % and diverges the closure; the engine's own deck SFC is a metabook-DATA value, not a sizing-answer backfill — see §4 |
| No afterburner | single thrust basis | high-BPR transport; `thrust_lapse_mil_on_AB_scale` == `thrust_lapse` |

## 6. To-dos

| Item | Guard |
|---|---|
| The per-engine GE90-110B rating (≈ 110,000 lbf/engine, `T_SL/n_engines`) is a **_TODO** stand-in — the metabook Table 10.1 prints the GE90 SLS range 76,000–115,000 lb, which brackets but does not pin the specific -110B rating. The cited value here is the metabook total `T_SL = 220000 lbf` | `b777_L1.md` §4.1 / §6 — needs a GE / Boeing engine-rating document |
