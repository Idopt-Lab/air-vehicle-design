# Aero481PropL1

F-35A (Aero 481 Design01 provenance) Level-1 propulsion. `classdef Aero481PropL1 < PropulsionModelL1`;
every contract method delegates to the `PropL1` static toolbox (no equation is duplicated in the
class). A single afterburning F135-PW-100.

**L1 is the simplest usable engine model:** a density-ratio thrust lapse and a categorical TSFC
selected by Mach regime.

**Provenance.** The design source is University of Michigan AEROSP 481 (Fall 2024) starter code by
Max Arnson (Design01.m) -- design PROVENANCE, not a primary source. Every carried value keeps its
`[A481 ...]` tag plus a primary re-cite where one exists, else `_TODO -- UNCITED`. The published
F-35A / F135 data (`docs/reference_extracts/aero481_data.md` Part I) is a cross-check, wired here as
the thrust stand-in.

---

## 1. Constructor

```matlab
p1 = Aero481PropL1(aero481_spec_path(1));
```

`Aero481PropL1(json_path)` -- path required, no silent default (a no-arg call errors `MATLAB:minrhs`).
Reads the `.propulsion` block of `aero481_L1.json`; the same file's `.geometry` / `.aerodynamics` /
`.weights` blocks feed `Aero481GeomL1` / `Aero481AeroL1` / `Aero481WeightsL1`. The F-35 example is **L1-only**
(no `aero481_L2.json`), so `aero481_spec_path` pins the level to 1.

---

## 2. Inputs

Plain mutable `properties` block, set once by the constructor. An optimizer (the sizing loop) may
mutate them; `T_SL` in particular is the design variable the loop overwrites in place, so it is not
defensively guarded.

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | -- | `PropulsionModelL1` contract; F135-PW-100 [aero481_data.md Part I]. Documentation/contract key; the lapse exponent is read from `lapse_exponent_m`, not resolved from this key. |
| `T_SL` (AB / max) | 43000 | lbf | AB (max) SLS thrust; the `PropulsionBase` contract property AND the sizing design variable [aero481_data.md Part I] |
| `T_SL_mil` (dry) | 28000 | lbf | mil (dry / intermediate) SLS thrust [aero481_data.md Part I] |
| `n_engines` | 1 | -- | engine count (single F135) [aero481_data.md Part I; A481 `NEng=1`] |
| `lapse_exponent_m` | 0.6 | -- | density-ratio lapse exponent `alpha = sigma^m` [metabook Eq. 10.9]. Carried as an explicit INPUT (like `B777PropL1`) so the modelling choice is cited, not hidden in a table lookup. **`_TODO`** (A6) |
| `tsfc_sls` | 0.35 | 1/hr | static / SLS TSFC [A481 Design01.m:78-80]. **`_TODO -- UNCITED`** |
| `tsfc_cruise` | 0.65 | 1/hr | subsonic cruise TSFC [A481 Design01.m:78-80]. **`_TODO -- UNCITED`** |
| `tsfc_dash` | 1.70 | 1/hr | supersonic afterburning dash TSFC [A481 Design01.m:78-80]. **`_TODO -- UNCITED`** (afterburning) |

There is **no stored `TSFC` property**: TSFC is state-dependent, so it is a method (`get_TSFC`), not
a property. This matches `F16PropL1` / `B777PropL1`.

## 3. Derived (`Dependent`)

| Property | Value | Note |
|---|---|---|
| `T_SL_wet` | 43000 lbf | An AB-scale alias for `T_SL`. Kept because the mil-on-AB scale and other call sites read the wet/AB name explicitly. It is `Dependent` on `T_SL`, so an optimizer changing `T_SL` cannot leave it stale (mirrors `F16PropL1`). |

---

## 4. Methods

| Method | Delegates to | Formula | Source |
|---|---|---|---|
| `thrust_lapse(state, "AB")` | `PropL1.sigma_lapse(rho, m)` | `alpha = sigma^0.6`, `sigma = rho/rho_SL` | metabook Eq. 10.9 |
| `thrust_lapse(state, "mil")` | `PropL1.sigma_lapse(rho, m)` then `x (T_SL_mil/T_SL)` | `alpha_mil = 0.6512 * sigma^0.6` | metabook Eq. 10.9 + mil-on-AB scale (mirrors `PropL2.get_thrust_lapse_mil_on_AB_scale`) |
| `get_thrust_lapse(state)` | `PropL1.sigma_lapse(rho, m)` | `alpha = sigma^0.6` (base AB/max, no mil scale) | metabook Eq. 10.9 |
| `get_TSFC(state)` / `lookup_TSFC` | in-class Mach regime selector | see 4.2 | [A481 Design01.m:78-80] |

`rho_SL` = 0.002377 slug/ft^3 [Mattingly App. B], inside `PropL1.sigma_lapse`.

### 4.1 Thrust-lapse rating handling (fighter set)

`thrust_lapse(obj, state, rating)` -- the `rating` argument is **required** (set in the constraint
architecture cleanup) and validated with `mustBeMember(rating, ["mil","AB"])`, exactly as
`F16PropL1` does. An unknown rating errors loudly at the `arguments` block.

- **`"AB"`** -> `alpha = sigma^0.6` -- the full AB / max scale, used with `T_SL` for constraint
  analysis and sizing.
- **`"mil"`** -> `alpha_mil = (T_SL_mil/T_SL) * sigma^0.6 = 0.6512 * sigma^0.6` -- the mil-power
  lapse renormalized onto the ONE max/AB `T_SL` basis, so a dry condition stays comparable with an
  AB one on the same `T_SL/W_TO` constraint-diagram axis. This mirrors
  `PropL2.get_thrust_lapse_mil_on_AB_scale`.

**Mil-on-AB scale value:** `T_SL_mil / T_SL = 28000 / 43000 = 0.651163` (**0.6512**).

The constraint infrastructure passes the requirements-JSON `power_setting` string straight through
to `thrust_lapse(state, rating)`, and the F-35 `aero481_requirements.json` carries only `"mil"` / `"AB"`
(Takeoff hardcodes `"AB"`). So the rating set that actually reaches this class is exactly the
validated `["mil","AB"]` pair.

### 4.2 TSFC by Mach regime

`get_TSFC(state)` returns the categorical value for the Mach band, reproducing the A481
static / cruise / dash grouping (`aero481_data.md` II.6, II.8):

| Mach band | Value | Regime | A481 row |
|---|---|---|---|
| `M < 0.1` | 0.35 1/hr | static / SLS (static, takeoff) | SLS |
| `0.1 <= M < 1.0` | 0.65 1/hr | subsonic cruise (e.g. M0.85 cruise) | Cruise |
| `M >= 1.0` | 1.70 1/hr | supersonic afterburning dash (e.g. M1.6 dash) | Dash |

The band boundaries (0.1 static/cruise split, 1.0 cruise/dash split) are an L1 approximation: A481
groups its three TSFC values by segment (static/takeoff, subsonic cruise, supersonic AB dash)
without an explicit Mach boundary. The boundaries reproduce that grouping -- M0.85 -> cruise,
M1.6 -> dash. There is no AB Mach-correction term at L1 (that is L2 Mattingly Eq. 3.55). Units are
**1/hr** throughout (no `/3600` conversion), matching the rest of the framework.

### As-built values (hand-computed cross-checks for the test-writer)

At 35,000 ft ISA, `sigma = rho/rho_SL = 0.0007382/0.002377 = 0.31056`, so `sigma^0.6 = 0.4952`
(atmosphere via `AircraftState`; the exact `rho` is whatever `atmosisa` returns at 35 kft, so the
test-writer should recompute from the state, not from this rounded figure).

| Quantity | Formula | Value |
|---|---|---|
| `thrust_lapse(SLS, "AB")` | `sigma^0.6`, sigma = 1 | 1.0 |
| `thrust_lapse(SLS, "mil")` | `0.6512 * 1` | 0.6512 |
| mil-on-AB scale | `28000/43000` | 0.651163 |
| `thrust_lapse(35 kft, "AB")` | `sigma^0.6` | ~= 0.4952 |
| `thrust_lapse(35 kft, "mil")` | `0.6512 * sigma^0.6` | ~= 0.3225 |
| `get_TSFC(M0)` | tsfc_sls | 0.35 1/hr |
| `get_TSFC(M0.85)` | tsfc_cruise | 0.65 1/hr |
| `get_TSFC(M1.6)` | tsfc_dash | 1.70 1/hr |

---

## 5. Deliberate deviation from Aero 481 -- ADDED THRUST LAPSE (A6)

**This is the single largest intentional deviation of the whole F-35 example from its Aero 481
design source, and it lives in this class.** It is USER-APPROVED (Gate-1, discrepancy A6).

Aero 481 applies **NO** thrust lapse: every `+Constraints/*` file uses installed thrust at altitude
with no `alpha = T(alt)/T_SL` term at all. This class applies the framework density lapse
`alpha = sigma^0.6` on the AB scale [metabook Eq. 10.9 / `PropL1.sigma_lapse`], plus the mil-on-AB
renormalization `alpha_mil = 0.6512 * sigma^0.6`.

Why: this puts every F-35 constraint onto the same sea-level-static `T_SL/W_TO` axis the framework
constraint diagram uses, so the F-35 conditions are directly comparable with the F-16A / B777
diagrams. It shifts every altitude constraint (the higher the altitude, the lower `sigma`, the lower
`alpha`, the higher the required `T_SL/W_TO`), so it cannot be silent.

Disposition: apply the lapse (framework convention), document it here prominently, and give it its
**own section** in the comparison report `sanity_checks/aero481_comparison.m`. See
`aero481_discrepancies.md` A6 and `aero481_L1.md` section 3.2.

---

## 6. `_TODO -- UNCITED` items carried by this class

Each needs a deliberately-failing, clearly-labelled `testTODO` guard until a primary source is
pinned -- the only expected `run_all_tests` exception (CLAUDE.md).

| Item | Value | Stand-in | Discrepancy | Needs |
|---|---|---|---|---|
| `lapse_exponent_m` | 0.6 | metabook Eq. 10.9 | A6 | whether 0.6 fits the F135 vs a higher `m` -- a modelling choice (same class as B777 D5) |
| `tsfc_sls` | 0.35 1/hr | A481 Design01 | -- | primary F135 deck data (Part I dry deck ~0.886 is a DIFFERENT, installed-cruise basis) |
| `tsfc_cruise` | 0.65 1/hr | A481 Design01 | -- | primary F135 deck data |
| `tsfc_dash` | 1.70 1/hr | A481 Design01 | -- | primary F135 deck data (afterburning) |
| TSFC Mach-band boundaries | 0.1 / 1.0 | L1 regime approximation | -- | segment-type is not on `AircraftState`; Mach stands in for it |

The **added thrust lapse (A6)** and the **mil-on-AB `m = 0.6` scale** are the framework's approved
modelling additions, not errors -- they are documented in section 5 and quantified in the comparison
report, not carried as red `testTODO` correctness failures beyond the `lapse_exponent_m` guard above.
