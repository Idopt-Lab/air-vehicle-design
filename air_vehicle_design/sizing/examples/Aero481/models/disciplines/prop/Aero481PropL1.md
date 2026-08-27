# Aero481PropL1

F-35A (Aero 481 Design01 provenance) Level-1 propulsion. `classdef Aero481PropL1 < PropulsionModelL1`.
A single afterburning F135-PW-100.

**L1 is the simplest usable engine model:** a density-ratio thrust lapse and a categorical TSFC
selected by Mach regime.

**Provenance.** The design source is University of Michigan AEROSP 481 (Fall 2024) starter code by
Max Arnson (`Design01.m`) — design provenance, not a primary source. Every carried value keeps its
`[A481 ...]` tag plus a primary re-cite where one exists, else `_TODO -- UNCITED`. The published
F-35A / F135 data (`docs/reference_extracts/aero481_data.md` Part I) is the thrust stand-in.

---

## 1. Constructor

```matlab
p1 = Aero481PropL1(aero481_spec_path(1));
```

`Aero481PropL1(json_path)` — path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.propulsion` block of `aero481_L1.json`; the same file's `.geometry` / `.aerodynamics` /
`.weights` blocks feed `Aero481GeomL1` / `Aero481AeroL1` / `Aero481WeightsL1`. The F-35 example is
**L1-only**, so `aero481_spec_path` pins the level to 1.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | — | `PropulsionModelL1` contract; F135-PW-100 [aero481_data.md Part I]. A contract and documentation key only: the lapse exponent is read from `lapse_exponent_m`, not resolved from it |
| `T_SL` | 43000 | lbf | AB (max) SLS thrust; the `PropulsionBase` contract property AND the design variable the sizing loop overwrites in place [aero481_data.md Part I] |
| `T_SL_mil` | 28000 | lbf | mil (dry / intermediate) SLS thrust [aero481_data.md Part I] |
| `n_engines` | 1 | — | engine count, single F135 [aero481_data.md Part I; A481 `NEng=1`] |
| `lapse_exponent_m` | **0** | — | density-ratio lapse exponent. `α = σ⁰ = 1`, so there is **no altitude lapse** — faithful to Aero 481 (§5). Carried as an explicit cited input so the choice is visible. **`_TODO`** (A6) |
| `tsfc_sls` | 0.35 | 1/hr | static / SLS TSFC [A481 `Design01.m:78-80`]. **`_TODO -- UNCITED`** |
| `tsfc_cruise` | 0.65 | 1/hr | subsonic cruise TSFC [A481 `Design01.m:78-80`]. **`_TODO -- UNCITED`** |
| `tsfc_dash` | 1.70 | 1/hr | supersonic afterburning dash TSFC [A481 `Design01.m:78-80`]. **`_TODO -- UNCITED`** |

Private constants: `MACH_STATIC_MAX` = 0.1 and `MACH_SUPERSONIC_MIN` = 1.0, the two Mach-band splits
in §4.2.

There is **no stored `TSFC` property** — TSFC is state-dependent, so it is a method.

## 3. Derived (`Dependent`)

| Property | Value | Note |
|---|---|---|
| `T_SL_wet` | 43000 lbf | ≡ `T_SL`. Kept because the mil-on-AB scale and other call sites read the wet/AB name explicitly. `Dependent`, so an optimizer changing `T_SL` cannot leave it stale |

---

## 4. Methods

| Method | Arguments | Outputs |
|---|---|---|
| `Aero481PropL1` (constructor) | input json path | Aero481 propulsion object |
| `get.T_SL_wet` (getter) | design object | `T_SL` (AB / max SLS thrust) |
| `get_thrust_lapse_categorical` | design object, aircraft state, rating (`"mil"`/`"AB"`) | alpha |
| `get_thrust_lapse_base` | design object, aircraft state | alpha, undERated |
| `get_TSFC` | design object, aircraft state | thrust-specific fuel consumption [1/hr] |
| `lookup_TSFC` | design object, aircraft state | same, an alias for `get_TSFC` |

`get_thrust_lapse_categorical` calls `PropL1.sigma_lapse(state.rho, obj.lapse_exponent_m)`, then
scales by `T_SL_mil/T_SL` for `"mil"` [metabook Eq. 10.9]. `get_thrust_lapse_base` returns that same
`σ^m` with no rating scale; it satisfies no contract.

`get_TSFC` holds the Mach-band selector and `lookup_TSFC` forwards to it, so the enforcer's concrete
`get_TSFC` bridge is overridden here. `F16PropL1` runs the pair the other way round.

`ρ_SL` = 0.002377 slug/ft³ [Mattingly App. B], inside `PropL1.sigma_lapse`.

### 4.1 Thrust-lapse rating handling (fighter set)

`rating` is required and validated with `mustBeMember(rating, ["mil","AB"])`, as `F16PropL1` does.
Consumers reach the method by the `PropulsionBase` name `get_thrust_lapse`, which
`PropulsionModelL1` bridges.

- **`"AB"`** → `α = σ^m` — the full AB / max scale, used with `T_SL`.
- **`"mil"`** → `α_mil = (T_SL_mil/T_SL)·σ^m` — the mil-power lapse renormalized onto the one max/AB
  `T_SL` basis, so a dry condition stays comparable with an AB one on the same `T_SL/W_TO` axis.
  Mirrors `PropL2.get_thrust_lapse_mil_on_AB_scale`.

`T_SL_mil / T_SL = 28000/43000 = 0.6511627907`. With `m = 0` this scale is the **only** difference
between the two ratings.

The constraint infrastructure passes the requirements-JSON `power_setting` string straight through,
and `aero481_requirements.json` carries only `"mil"` / `"AB"` (Takeoff hardcodes `"AB"`).

### 4.2 TSFC by Mach regime

| Mach band | Value | Regime | A481 row |
|---|---|---|---|
| `M < 0.1` | 0.35 1/hr | static / SLS | SLS |
| `0.1 ≤ M < 1.0` | 0.65 1/hr | subsonic cruise | Cruise |
| `M ≥ 1.0` | 1.70 1/hr | supersonic AB dash | Dash |

A481 groups its three values by segment with no printed Mach boundary; these splits reproduce that
grouping (M0.85 → cruise, M1.6 → dash) [aero481_data.md II.6, II.8]. No AB Mach-correction term at
L1 — that is L2 [Mattingly Eq. 3.55]. Units are 1/hr throughout.

### As-built values

| Quantity | Value |
|---|---|
| `get_thrust_lapse_categorical(any state, "AB")` | 1.0 |
| `get_thrust_lapse_categorical(any state, "mil")` | 0.6511627907 |
| `get_thrust_lapse_base(any state)` | 1.0 |
| `get_TSFC(M 0.05)` | 0.35 1/hr |
| `get_TSFC(M 0.85)` | 0.65 1/hr |
| `get_TSFC(M 1.6)` | 1.70 1/hr |

The lapse is altitude-independent because `m = 0`.

---

## 5. Thrust lapse vs Aero 481 (A6)

Aero 481 applies **no** thrust lapse: every `+Constraints/*` file uses installed thrust at altitude
with no `α = T(alt)/T_SL` term. `lapse_exponent_m = 0` reproduces that, so `α = 1` at every altitude
and only the mil-on-AB thrust setting varies. The framework convention is `m = 0.6`
(`F16PropL1`, `B777PropL1`); the F-35 example deviates on purpose, for A481 fidelity.

See `aero481_discrepancies.md` A6; `sanity_checks/aero481_comparison.m` quantifies it.

---

## 6. `_TODO -- UNCITED` items

Each carries a deliberately-failing, labelled `testTODO_` guard until a primary source is pinned —
the only expected `run_all_tests` exception (CLAUDE.md).

| Item | Value | Stand-in | Needs |
|---|---|---|---|
| `lapse_exponent_m` | 0 | A481 fidelity (A6) | whether the F-35 example keeps A481's no-lapse model or moves to the framework `m = 0.6` |
| `tsfc_sls` | 0.35 1/hr | A481 Design01 | primary F135 deck data (Part I's dry deck ≈ 0.886 is a different, installed-cruise basis) |
| `tsfc_cruise` | 0.65 1/hr | A481 Design01 | primary F135 deck data |
| `tsfc_dash` | 1.70 1/hr | A481 Design01 | primary F135 deck data, afterburning |
| Mach-band boundaries | 0.1 / 1.0 | L1 regime approximation | segment type is not on `AircraftState`, so Mach stands in for it |
