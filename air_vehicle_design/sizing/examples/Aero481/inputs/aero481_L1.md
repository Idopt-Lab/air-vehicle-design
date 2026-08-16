# aero481_L1 -- companion doc

Companion to `examples/Aero481/inputs/aero481_L1.json` -- the F-35 Level-1 **SPEC** data (what the
aircraft IS). The F-35 example mirrors the F-16A / B777 L1 discipline pattern
(`Aero481GeomL1` / `Aero481AeroL1` / `Aero481PropL1` / `Aero481WeightsL1`, each a fighter L1 class). All values
trace to the approved scribe plan (`examples/Aero481/aero481_scribe_plan.md`) and the design-source
extract (`docs/reference_extracts/aero481_data.md` Part II).

**SCOPE GUARD.** This file holds SPEC data only -- reference area, aspect ratio, thrust, engine
model, config-polar table, OEW coefficients. It never holds REQUIREMENTS (what the aircraft must
DO -- constraints, missions, cruise/design Mach: those stay in
`examples/Aero481/inputs/aero481_requirements.json`). The `aircraft_category` sits at the top level, not
inside a discipline block.

**Provenance.** The design source is the University of Michigan AEROSP 481 (Fall 2024) starter
code by Max Arnson -- design PROVENANCE, **not** a primary source. Every Design01/A03 value
carries an `[A481 <file>]` tag plus a primary re-citation where one exists, else
`_TODO -- UNCITED`. The published F-35A data (`aero481_data.md` Part I) is a **cross-check only**, not
the design source (with the one S_ref stand-in note below).

**Units.** English throughout, matching the F-16A / B777 JSONs (lbf, ft, ft^2, 1/hr). The Aero
481 source is SI; conversions are noted per row.

**Kind.** `input` = mutable spec property set from JSON (an optimizer varies it); `derived` =
`properties (Dependent)` recomputed live via a `get.` getter (never stored in JSON); `state` =
sizing-loop variable (`W_TO`), NaN until set.

---

## 1. Top-level key + Geometry block (`Aero481GeomL1`)

| Property | Value | Unit | Kind | Citation |
|---|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | -- | input (top-level) | selects the GeomL1 swet/lfus/AR_eq fighter rows, the Roskam CLmax row, the Raymer Table 12.3 Cfe row, the WeightsL1 fighter rows, the mission fighter fixed-fraction row |
| `geometry.AR` | 4 | -- | input | `[A481 Design01.m:49]`; **`_TODO -- UNCITED`** (A5) |
| `geometry.n_engines` | 1 | -- | input | `[A481 NEng=1]`; `aero481_data.md` Part I (single F135-PW-100) |
| `geometry.S_ref` | 460 | ft^2 | input | published F-35A wing area stand-in; **`_TODO -- UNCITED`** (see 1.3) |
| `geometry.Lambda_LE_deg` | 0 | deg | input | wing LE sweep; **`_TODO -- UNCITED`** (unset/0 reproduces A481's sweep-free Oswald, A2) |
| `geometry.M_max` | design Mach | -- | input (from requirements) | fed from `aero481_requirements.json` `design_mach`; feeds `GeomL1.get_AR_eq` (Raymer 7th ed. Table 4.1) |
| `S_wet` | `10^-0.1289 * W_TO^0.7506` | ft^2 | **derived** (`Dependent` on `W_TO`) | **[Roskam Vol. I Table 3.5, jet_fighter]** via `GeomL1.lookup_swet` -- REPLACES `Swet=4*S` (1.4) |
| `L_fuselage` | `0.93 * W_TO^0.39` | ft | **derived** (`Dependent` on `W_TO`) | **[Raymer 6th ed. Table 6.3, jet_fighter]** via `GeomL1.lookup_lfus` |
| `W_TO` | NaN until set | lbf | state | `[WeightsBase]` -- both derived regressions are on TOGW |

`S_wet` and `L_fuselage` are **derived**, not JSON inputs (like `F16GeomL1`): they are
`Dependent` getters on `W_TO`, recomputed live and read-only. They are listed here only to
document the L1 geometry contract; they never appear in the JSON.

### 1.1 SI -> English conversions (geometry)

- `S_ref`: published 460 ft^2 = 42.7 m^2 (`aero481_data.md` Part I). Carried directly in ft^2.

### 1.2 The `AR = 4` `_TODO` (A5)

`AR = 4` `[A481 Design01.m:49]` is a student value, carried faithfully to Design01.
`_TODO -- UNCITED`: the published F-35A AR is approximately 2.66 (35 ft span, 460 ft^2:
35^2/460 = 2.66). The comparison report flags this loudly as a fidelity/design gap; it is NOT
silently overwritten. Confirm the design AR before pinning.

### 1.3 `S_ref` stand-in decision

Design01 fixes the DESIGN POINT (`W/S` = 92.17 psf, `T/W` = 1.2), **not** `S_ref` directly. In
the sizing loop `S_ref = W_TO / (W/S)` changes every iteration -- a sizing-loop output, not a
static input. Because `W_TO` is `state` (NaN at L1, both geometry regressions are on it), a
back-solved `S_ref` cannot be written as a fixed number without inventing a `W_TO`.

**Decision: carry the published F-35A `S_ref = 460 ft^2` as the fixed spec stand-in, marked
`_TODO -- UNCITED`.** This is the design-source note the scribe plan permits (the one place Part I
is used as a stand-in). The design-point back-solve `S_ref = W_TO / 92.17` is documented as the
sizing-loop form but not stored. The T-S study S-range 323-538 ft^2 matches Aero 481's 30-50 m^2
(`T_S.m:23`). Remove/replace `S_ref` when an RFP or a design `S_ref` is pinned.

### 1.4 The `Swet = 4*S` rejection (A1)

`[A481 Design01.m:33-36]`:

```
%% Wetted Surface Area Regression
% I made this up
Aircraft.Swet_Fxn = @ (S) 4*S;
```

Uncited AND self-inconsistent (A03.m:60-61 is unsure area-vs-weight). **REJECTED.** The
framework uses the cited Roskam Table 3.5 jet-fighter TOGW regression in `GeomL1.lookup_swet`, so
`S_wet` is a `Dependent` on `W_TO`, NOT a wing-area multiple and NOT a stored JSON input.

---

## 2. Aerodynamics block (`Aero481AeroL1`)

| Property | Value | Unit | Kind | Citation |
|---|---|---|---|---|
| `Cfe` | 0.0035 | -- | input | **[Raymer Table 12.3 Air Force fighter]** via `AeroL2.lookup_Cfe`; matches A481 `Cf = 0.0035` (Design01.m:73) |
| `AR` | 4 | -- | input | `[A481 Design01.m:49]`; **`_TODO -- UNCITED`** (A5) |
| `Lambda_LE_deg` | 0 | deg | input | wing LE sweep; **`_TODO -- UNCITED`** (unset/0, A2) |
| `e_clean` | 0.9344 | -- | input (informational only) | Raymer 6th ed. Eq. 12.48 at AR = 4, low-sweep branch; = A481 `Utility.Oswald` (A2). Corrected 2026-08-15 (was 0.9153). Class computes `e` live via `AeroL2.oswald_eff` -- this field is documentation only. |
| `CD0_config` | table below | -- | input dict | `[A481 Design01.m:64-68]`; **`_TODO -- UNCITED`** ("thank you Ian") |
| `CLmax_config` | table below | -- | input dict | `[A481 Design01.m:55-61]`; **`_TODO -- UNCITED`** |

`drag_polar(state)` returns `{CD0 = 0.0236, K1, K2 = 0}` with `CD0` CONSTANT (faithful to
Design01, whose constraint set reads `CD0.Clean` directly). `K1 = 1/(pi*AR*e)` with
`e = AeroL2.oswald_eff(AR, Lambda_LE_deg)`; `K2 = 0` (uncambered-basis, no camber/CL_minD data at
L1). `get_CLmax` returns the clean CLmax = 1.8.

### 2.1 CD0 config table (increments over clean = 0.0236)

| config string | CD0 | dCD0 over clean | A481 source |
|---|---|---|---|
| `clean` | 0.0236 | 0 | `CD0.Clean` |
| `takeoff_flaps_gear_up` | 0.0386 | 0.0150 | `CD0.TakeoffNoGear` |
| `takeoff_flaps_gear_down` | 0.0586 | 0.0350 | `CD0.TakeoffGear` |
| `landing_flaps_gear_up` | 0.0886 | 0.0650 | `CD0.LandingNoGear` |
| `landing_flaps_gear_down` | 0.1086 | 0.0850 | `CD0.LandingGear` |
| `approach` | **0.0836** = mean(0.0586, 0.1086) | -- | **derived**, Climb-6/BO mean rule `[A481 Climb.m:63]` |

### 2.2 CLmax config table

| config | CLmax | A481 (Climb) |
|---|---|---|
| `clean` (en-route/EN) | 1.8 | `CLmax.EN` |
| `takeoff_flaps_gear_up` (SS) | 1.8 | `CLmax.SS` |
| `takeoff_flaps_gear_down` (TO/TS) | 2.0 | `CLmax.TO` / `.TS` |
| `landing_flaps_gear_up` (BA) | 2.6 | `CLmax.BA` |
| `landing_flaps_gear_down` (BA) | 2.6 | `CLmax.BA` |
| `approach` (BO) | 2.6 | `CLmax.BO` |

### 2.3 `e_clean` / `K1` via the cited Oswald (A2)

`e = 1.78*(1 - 0.045*AR^0.68) - 0.64 = 0.9344` at AR = 4 **[Raymer 6th ed. Eq. 12.48, low-sweep
branch]** (corrected 2026-08-15; an earlier 0.9153 was an arithmetic slip = AR≈4.56). This is bit-identical to A481's `Utility.Oswald` (which cites a web calculator that IS
Raymer Eq. 12.48). `e_clean` is carried for readers; the live value comes from
`AeroL2.oswald_eff(AR, Lambda_LE_deg)`. If a real F-35 `Lambda_LE >= 30 deg` is supplied, the
framework applies the sweep-corrected Eq. 12.49 (A481 never does) and the report quantifies the
delta. `Lambda_LE_deg` itself is `_TODO -- UNCITED`.

### 2.4 `_TODO -- UNCITED` (aero)

- `AR = 4` (A5).
- `Lambda_LE_deg` (A2) -- carried as 0 (unset).
- `CD0_config` (clean 0.0236 and the increments) -- A481 "thank you Ian" / student values.
- `CLmax_config` (1.8 / 2.0 / 2.6) -- A481 student values.

---

## 3. Propulsion block (`Aero481PropL1`)

| Property | Value | Unit | Kind | Citation |
|---|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | -- | input | F135-PW-100 (`aero481_data.md` Part I); selects the lapse exponent + TSFC handling |
| `T_SL` (AB/max) | 43000 | lbf | input | `aero481_data.md` Part I |
| `T_SL_mil` (dry/intermediate) | 28000 | lbf | input | `aero481_data.md` Part I |
| `n_engines` | 1 | -- | input | Part I; `[A481 NEng=1]` |
| `lapse_exponent_m` | 0.6 | -- | input | `[metabook Eq. 10.9]`; **`_TODO`** whether 0.6 fits the F135 (A6) |
| `tsfc_sls` | 0.35 | 1/hr | input | `[A481 Design01.m:78-80]`; **`_TODO -- UNCITED`** |
| `tsfc_cruise` | 0.65 | 1/hr | input | `[A481 Design01.m:78-80]`; **`_TODO -- UNCITED`** |
| `tsfc_dash` | 1.70 | 1/hr | input | `[A481 Design01.m:78-80]`; **`_TODO -- UNCITED`** (afterburning) |

### 3.1 SI -> English / value notes (propulsion)

- `T_SL` / `T_SL_mil`: 43,000 / 28,000 lbf are already English (Part I). mil/AB ratio =
  28,000/43,000 = **0.6512**.
- TSFC: A481 carries these in Imperial 1/hr (converts to SI via `ConvTSFC`); the framework
  carries 1/hr directly.

### 3.2 The added thrust lapse (A6, largest deliberate deviation)

Aero 481 applies **NO** thrust lapse. The framework applies a density lapse `alpha = sigma^0.6`
on the AB scale `[metabook Eq. 10.9 / PropL1.sigma_lapse]`, plus a mil-on-AB renormalization
`alpha_mil = (T_SL_mil/T_SL)*sigma^0.6 = 0.6512*sigma^0.6` (mirroring
`PropL2.get_thrust_lapse_mil_on_AB_scale`). This is the single largest intentional deviation from
Aero 481 and gets its own section in the comparison report.

### 3.3 `_TODO` (propulsion)

- `lapse_exponent_m = 0.6` (A6) -- modelling choice, same class as B777 D5.
- `tsfc_sls` / `tsfc_cruise` / `tsfc_dash` -- A481 student values (Part I F135 dry deck ~0.886 is
  a DIFFERENT basis, installed cruise).

---

## 4. Weights block (`Aero481WeightsL1`)

Constructor `(json_path, geom, prop)` -- `geom` supplies `dS_wing`, `prop` supplies `T_SL` (DI).
Baseline = the Design01 design point.

| Property | Value | Unit | Kind | Citation |
|---|---|---|---|---|
| `weights.aircraft_category` | `"jet_fighter"` | -- | input | Raymer Table 15.2 fighter row + Sec. 7 LG fraction |
| `weights.oew_coeff_a` | 0.882 | -- | input | `[A481 Design01.m:26 Sainristil]`; **`_TODO -- UNCITED`** (A7) |
| `weights.oew_coeff_c` | -0.055 | -- | input | `[A481 Design01.m:26 Sainristil]`; **`_TODO -- UNCITED`** (A7) |
| `weights.W_payload_expendable` | 18000 | lbf | input | `[A481 WMissile]`; **`_TODO -- UNCITED`** |
| `weights.W_payload_fixed` | 441 | lbf | input | `[A481 WCrew]` (200 kg crew); **`_TODO -- UNCITED`** |
| `weights.design_mach` | 1.6 | -- | input (from requirements) | Raymer Eq. 10.10 `M^0.25` (AB engine-weight path) |
| `geom`, `prop` | injected | -- | DI | supply `dS_wing` (geom) and `T_SL` (prop) |
| `W_TO` | NaN until set | lbf | state | `[WeightsBase]` |

**Note on `design_mach`.** The canonical home for design Mach is
`aero481_requirements.json` `design_mach` (a requirement, fidelity-independent). The value 1.6 is
carried in `.weights.design_mach` per the deliverable spec for the Raymer Eq. 10.10 engine-weight
path; it MUST equal the requirements value (currently 1.6). The implementation may prefer to read
it from the injected requirements path (as `F16WeightsL2/L3` do) rather than duplicate it -- flag
for the implementation phase.

### 4.1 OEW build-up (derived, computed by the class, NOT stored in JSON)

The class computes the **Aero 481 A02 delta model** [A481 +Algorithms/A02.m:37-63] — exactly
THREE terms: the Sainristil empty-weight FRACTION plus a WING delta and an ENGINE delta, each
measured about a SELF-SCALING design-point baseline. There are NO H/V-tail deltas, no
landing-gear fraction, no all-else fraction and no installed-engine factor — those were an
earlier framework addition that the A02 model does not carry.

```
OEW(W_TO) = We_frac(W_TO)*W_TO                        [FRACTION -- A481 Sainristil, _TODO A7]
          + rho_w*( S_ref - W_TO/design_WS_psf )      [WING  delta -- Raymer Table 15.2 fighter]
          + ( Weng(T_SL) - Weng(design_TW*W_TO) )     [ENGINE delta -- Roskam Eqs. 7.13-7.19]
```

| Term | Value / formula | Citation |
|---|---|---|
| FRACTION `We_frac(W_TO)*W_TO` | `We_frac = 0.882 * W_TO^-0.055` | `[A481 Design01.m:26]`; **`_TODO -- UNCITED`** (A7). Framework alternative **[Raymer Table 3.1 jet_fighter]** `2.34 * W_TO^-0.13` -- report shows both |
| WING delta `rho_w*(S_ref - W_TO/design_WS_psf)` | `rho_w = 9.0 lb/ft^2` (44 kg/m^2); baseline area `W_TO/92.17` (self-scaling) | **[Raymer 6th ed. Table 15.2 fighter]** = A481 A02 `WingDensity = 44 kg/m^2` (toolbox Constant, not a JSON input). `S_ref` read LIVE from the injected geom; `design_WS_psf = 92.17` from the `.weights` block |
| ENGINE delta `Weng(T_SL) - Weng(design_TW*W_TO)` | `Weng = WeightsL1.engine_weight_roskam`; baseline thrust `1.2*W_TO` (self-scaling); n_eng = 1 (no count division) | **[Roskam Eqs. 7.13-7.19]** = `Utility.MetaEngine`. `T_SL` read LIVE from the injected prop; `design_TW = 1.2` from the `.weights` block. Keeps the reverser term `W_rev = 0.034*T` -- **`_TODO`** a fighter has none (A9) |

Both delta baselines scale WITH `W_TO`, so each delta stays bounded and OEW never runs away in
the sizing loop (see `Aero481WeightsL1.m` header). The wing areal density and the engine-weight
regression coefficients are toolbox Constants selected by `aircraft_category`, **not** JSON
inputs (same convention as the F-16A L2 weights class). Only the OEW coefficients,
`design_WS_psf`, `design_TW` and the payloads are carried in the `.weights` block.

### 4.2 `_TODO` (weights)

- `oew_coeff_a` / `oew_coeff_c` (0.882 / -0.055) -- Sainristil-team fit, no textbook citation (A7).
- `W_payload_expendable` (18,000 lbf) -- A481 "yields f35 payload" student choice.
- `W_payload_fixed` (441 lbf) -- 200 kg crew, student choice.
- reverser term in `engine_weight_roskam` -- kept for MetaEngine parity, `_TODO` fighter-no-reverser
  variant deferred (A9) -- a code note, not a JSON input.

---

## 5. Tail block (`Aero481TailL1`) -- no JSON input at L1

`Aero481TailL1` sizes the tail by volume coefficients (mirrors `F16TailL1`); the fighter coefficients
(`c_HT = 0.40`, `c_VT = 0.07`, `L_arm = 0.475*L_fus`, both **[Raymer 7th ed. Table 6.4 jet-fighter]**
via `TailL1.lookup_tail_volume_coeffs('jet_fighter')`) are toolbox Constants, not JSON inputs, so
no tail block is required in `aero481_L1.json`. The F-35 RSS / all-moving-tail flags are
`_TODO -- UNCITED`; carry the UNCORRECTED base fighter coefficients until a flag is set (like the
B777). Flagged for the implementation phase.

---

## 6. `_TODO -- UNCITED` summary (spec file)

| Value | Block | Stand-in | Discrepancy | Needs |
|---|---|---|---|---|
| `AR = 4` | geometry / aerodynamics | 4 (Design01) | A5 | student AR vs published 2.66 -- confirm design AR |
| `S_ref = 460` | geometry | published F-35A wing area | -- | RFP / design `S_ref` (design-point back-solve is a sizing-loop output) |
| `Lambda_LE_deg = 0` | geometry / aerodynamics | 0 (unset) | A2 | F-35 planform document |
| `CD0_config` | aerodynamics | Design01 ("thank you Ian") | -- | primary source |
| `CLmax_config` | aerodynamics | Design01 | -- | primary source |
| `lapse_exponent_m = 0.6` | propulsion | metabook Eq. 10.9 | A6 | modelling choice (like B777 D5) |
| `tsfc_sls/cruise/dash` (0.35/0.65/1.70) | propulsion | Design01 | -- | primary F135 deck data |
| `oew_coeff_a/c` (0.882/-0.055) | weights | Sainristil fit | A7 | primary source or adopt Raymer Table 3.1 |
| `W_payload_expendable = 18000` | weights | Design01 | -- | F-35 stores document |
| `W_payload_fixed = 441` | weights | Design01 (200 kg crew) | -- | student choice / doc |
| reverser term (code) | weights | kept (MetaEngine parity) | A9 | fighter no-reverser variant |
| RSS / all-moving-tail flags (code) | tail | uncorrected base coeffs | -- | F-35 planform document |

Every `_TODO -- UNCITED` above needs a deliberately-failing `testTODO` guard (labelled) in the
F-35 tests until a citation is pinned -- the only expected `run_all_tests` exception (CLAUDE.md).
