# F-35 example — scribe design document (Gate-1)

Pre-implementation design spec for `examples/Aero481/` (plan Step 4). Mirrors the B777 companion
docs. **No `.m` or `.json` exists yet** — this document tells the `io` agent what JSON to
build and the implementation agents what each `Aero481*L1` class holds, with citations, so that
zero uncited equations reach the final classes.

**Design source:** Aero 481 Design01/A03/+Constraints — extracted in
`docs/reference_extracts/aero481_data.md` Part II. **Discrepancies:**
`aero481_discrepancies.md` (A1-A9). **Published cross-check:** `aero481_data.md` Part I.

Tree (mirrors F16A / B777, all L1 disciplines):
```
examples/Aero481/
  helpers/aero481_spec_path.m  aero481_requirements_path.m
  inputs/aero481_L1.json  aero481_requirements.json  (+ .md companions)
  models/disciplines/{aero,geom,prop,weights,tail}/Aero481*L1.m (+ .md each)
  models/sizing/Aero481ConstraintSet.m
  studies/run_aero481_constraint_diagram.m  run_aero481_sizing_L2.m  run_aero481_TS_diagram.m
  sanity_checks/aero481_comparison.m
  output/.gitkeep  (gitignored)
tests/examples/Aero481/  (hand-computed spot values)
```

Convention: **input** = mutable spec `properties` set from JSON (an optimizer varies it);
**derived** = `properties (Dependent)` recomputed live via a `get.` getter (never frozen).

---

## 1. Geometry — `Aero481GeomL1`

`classdef Aero481GeomL1 < GeometryModelL1` (fighter L1, mirrors `F16GeomL1`). Statistical L1: the
few numeric inputs plus TOGW-regression derived quantities.

### 1.1 Inputs

| Property | Value | Kind | Citation |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | input (top-level canonical key) | selects `GeomL1.lookup_swet` / `lookup_lfus` / `lookup_AR_eq` fighter rows |
| `AR` | 4 | input | `[A481 Design01.m:49]`; `_TODO — UNCITED` (publ. F-35A ≈ 2.66, discrepancy A5) |
| `M_max` | design Mach | input (from requirements) | `_TODO` — F-35 design Mach; feeds `GeomL1.get_AR_eq` (Raymer 7th ed. Table 4.1) |
| `n_engines` | 1 | input | `[A481 Design01.m:44 NEng=1]`; Part I (single F135) — exposed for mission DI |
| `S_ref` | from W/S design point | input (design variable) | see §1.3 |
| `W_TO` | NaN until set | state (sizing loop) | `[WeightsBase]` — both derived regressions are on TOGW |

### 1.2 Derived (`Dependent`)

| Property | Formula | Citation |
|---|---|---|
| `S_wet` | `10^-0.1289·W_TO^0.7506` | **[Roskam Vol. I Table 3.5, jet_fighter]** via `GeomL1.lookup_swet` — REPLACES `Swet=4·S` (§1.4) |
| `L_fuselage` | `0.93·W_TO^0.39` | **[Raymer 6th ed. Table 6.3, jet_fighter]** via `GeomL1.lookup_lfus` |

Both read-only, recomputed live from `W_TO` (like `F16GeomL1`; error if `W_TO` unset).

### 1.3 `S_ref` from the design point

Design01 fixes the DESIGN POINT (W/S = 92.2 psf, T/W = 1.2), not `S_ref` directly. In the
sizing loop `S_ref = W_TO / (W/S)` changes every iteration (plan L2 behaviour). As a fixed
spec stand-in for the constraint/T-S studies, use `S_ref` back-solved at the design point, or
carry the published F-35A `S_ref = 460 ft²` as a `_TODO` reference — flag which. The T-S study
S-range 323-538 ft² matches Aero 481's 30-50 m² (`T_S.m:23`).

### 1.4 The `Swet = 4·S` rejection (record the quote — discrepancy A1)

`[A481 Design01.m:33-36]`:
```
%% Wetted Surface Area Regression
% I made this up
Aircraft.Swet_Fxn = @ (S) 4*S;
```
Uncited AND self-inconsistent (A03.m:60-61 is unsure area-vs-weight). **REJECTED** — use the
cited Roskam Table 3.5 jet-fighter regression in `GeomL1.lookup_swet`. `Aero481GeomL1.md` quotes
this. Note the framework `S_wet` is a TOGW regression (like the F-16 L1), NOT a wing-area
multiple — so it is a `Dependent` on `W_TO`, not on `S_ref`.

---

## 2. Aerodynamics — `Aero481AeroL1`

`classdef Aero481AeroL1 < AeroModelL1`. Design01's config tables as spec inputs; `drag_polar`
uses the constant clean CD0 = 0.0236 (faithful to Design01, whose constraint set reads
`CD0.Clean` directly). Geometry-light L1 — unlike the geometry-COUPLED B777AeroL1.

### 2.1 Inputs

| Property | Value | Kind | Citation |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | input | mission fixed-fraction row selector |
| `AR` | 4 | input | `[A481 Design01.m:49]`; `_TODO` (A5) |
| `Lambda_LE_deg` | `_TODO` | input | F-35 wing LE sweep — unset/0 reproduces A481's sweep-free Oswald (A2) |
| `CD0_config` | table (below) | input dict | `[A481 Design01.m:64-68]`; `_TODO — UNCITED` ("thank you Ian") |
| `CLmax_config` | table (below) | input dict | `[A481 Design01.m:55-61]`; `_TODO — UNCITED` |
| `Cfe` | 0.0035 | derived-once | **[Raymer Table 12.3 Air Force fighter]** via `AeroL2.lookup_Cfe` (matches A481 `Cf=0.0035`) — carried for the comparison report only |

**CD0 config table** (increments computed over clean = 0.0236):

| config string | CD0 | ΔCD0 over clean | A481 source |
|---|---|---|---|
| `clean` | 0.0236 | 0 | `CD0.Clean` |
| `takeoff_flaps_gear_up` | 0.0386 | 0.0150 | `CD0.TakeoffNoGear` |
| `takeoff_flaps_gear_down` | 0.0586 | 0.0350 | `CD0.TakeoffGear` |
| `landing_flaps_gear_up` | 0.0886 | 0.0650 | `CD0.LandingNoGear` |
| `landing_flaps_gear_down` | 0.1086 | 0.0850 | `CD0.LandingGear` |
| `approach` | **0.0836** = mean(0.0586,0.1086) | — | derived, Climb-6/BO mean rule `[A481 Climb.m:63]` |

**CLmax config table**:

| config | CLmax | A481 (Climb) |
|---|---|---|
| `clean` (en-route/EN) | 1.8 | `CLmax.EN` |
| `takeoff_flaps_gear_up` (SS) | 1.8 | `CLmax.SS` |
| `takeoff_flaps_gear_down` (TO/TS) | 2.0 | `CLmax.TO`/`.TS` |
| `landing_flaps_gear_down` (BA) | 2.6 | `CLmax.BA` |
| `approach` (BO) | 2.6 | `CLmax.BO` |

### 2.2 Derived / methods

| Method | Does | Citation |
|---|---|---|
| `drag_polar(state)` | `{CD0 = 0.0236, K1, K2 = 0}`, CD0 CONSTANT | CD0 `[A481 Design01.m:64]`; K1 §2.3 |
| `get_CLmax(~)` | clean CLmax = `CLmax_config("clean")` = 1.8 | `[A481 Design01.m:59]` |
| `get_config_polar(config)` | `struct(CD0, K1, K2, CLmax)` per config incl. `approach` mean rule | `AerodynamicsBase` contract |
| `get_CLmax_TO/_L`, `get_Delta_CD0_TO/_L` | wrappers to the config table | — |

### 2.3 `K1` via the cited Oswald (discrepancy A2)

`K1 = 1/(π·AR·e)`, `e = AeroL2.oswald_eff(AR, Lambda_LE_deg)` = **[Raymer 6th ed. Eq. 12.48
(< 30° sweep) / Eq. 12.49 (≥ 30°)]**. At AR = 4, Λ_LE < 30°: e = 0.9344 (corrected 2026-08-15; was 0.9153) — identical to
A481's `Utility.Oswald` (which IS Raymer Eq. 12.48; §II.5 / A2). If a real F-35 `Λ_LE ≥ 30°`
is supplied, the framework applies the sweep-corrected Eq. 12.49 (A481 never does); the
report quantifies the delta. `K2 = 0` (uncambered-basis, no camber/CL_minD data at L1).

---

## 3. Propulsion — `Aero481PropL1`

`classdef Aero481PropL1 < PropulsionModelL1`. Single F135; density lapse + mil-on-AB scale (the
largest deliberate deviation from Aero 481, which has NO lapse — discrepancy A6).

### 3.1 Inputs

| Property | Value | Kind | Citation |
|---|---|---|---|
| `engine_type` | `"low_bypass_turbofan_AB"` | input | F135-PW-100 (Part I); selects `m` |
| `T_SL` (AB/max) | 43,000 lbf | input (design variable) | Part I `aero481_data.md` |
| `T_SL_mil` (dry) | 28,000 lbf | input | Part I |
| `n_engines` | 1 | input | Part I; `[A481 NEng=1]` |
| `lapse_exponent_m` | 0.6 | input | `[metabook Eq. 10.9]`; `_TODO` whether 0.6 fits the F135 (A6) |
| `tsfc_sls` / `tsfc_cruise` / `tsfc_dash` | 0.35 / 0.65 / 1.70 | input | `[A481 Design01.m:78-80]`; `_TODO — UNCITED` |

### 3.2 Methods

| Method | Does | Citation |
|---|---|---|
| `thrust_lapse(state, "AB")` | `α = σ^0.6`, `σ = ρ/ρ_SL` via `PropL1.sigma_lapse` | `[metabook Eq. 10.9]` |
| `thrust_lapse(state, "mil")` | `α_mil = (T_SL_mil/T_SL)·σ^0.6 = 0.6512·σ^0.6` | mirrors `PropL2.get_thrust_lapse_mil_on_AB_scale` (T_SL_mil/T_SL_AB scale) |
| `get_TSFC(state)` | cruise/dash/SLS TSFC by Mach/AB | `[A481 Design01.m:78-80]`; `_TODO` |

`0.6512 = 28,000/43,000` (§II.7). **Aero 481 applies NO lapse** — this is a deliberate
framework addition; own section in the comparison report (A6).

---

## 4. Weights — `Aero481WeightsL1`

`classdef Aero481WeightsL1 < WeightsModelL1` (fighter L1 fraction + deltas; ctor
`(json_path, geom, prop)`). Baseline = the Design01 design point.

### 4.1 Inputs

| Property | Value | Kind | Citation |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | input | Raymer Table 15.2 fighter row + Sec. 7 LG fraction |
| OEW-fraction coeffs | `0.882 / -0.055` | input | `[A481 Design01.m:26 Sainristil]`; `_TODO — UNCITED` (A7) |
| `design_mach` | from requirements | input | Raymer Eq. 10.10 `M^0.25` (if the AB engine-weight path is used) |
| `W_payload_expendable` | 18,000 lbf | input | `[A481 WMissile]`; `_TODO` |
| `W_payload_fixed` | 441 lbf (200 kg crew) | input | `[A481 WCrew]`; `_TODO` |
| `geom`, `prop` | injected | DI | supply `S_ref` (geom, wing delta) and `T_SL` (prop, engine delta), read LIVE |
| `W_TO` | NaN until set | state | `[WeightsBase]` |

### 4.2 Derived / OEW build-up

The class computes the **Aero 481 A02 delta model** [A481 +Algorithms/A02.m:37-63] — exactly
THREE terms: the Sainristil FRACTION plus a WING delta and an ENGINE delta about self-scaling
baselines. NO H/V-tail delta, NO landing-gear fraction, NO all-else fraction, NO
installed-engine factor (those were an earlier framework addition the A02 model does not carry).

```
OEW(W_TO) = We_frac(W_TO)·W_TO                        [FRACTION — A481 Sainristil, _TODO A7]
          + rho_w·( S_ref - W_TO/design_WS_psf )      [WING  delta — Raymer Table 15.2 fighter]
          + ( Weng(T_SL) - Weng(design_TW·W_TO) )     [ENGINE delta — Roskam Eqs. 7.13-7.19]
```

| Term | Value / formula | Citation |
|---|---|---|
| FRACTION `We_frac·W_TO` | `We_frac = 0.882·W_TO^-0.055` | `[A481 Design01.m:26]`; `_TODO — UNCITED` (A7). Framework alternative `[Raymer Table 3.1 jet_fighter]` `2.34·W_TO^-0.13` — report shows both |
| WING delta `rho_w·(S_ref - W_TO/design_WS_psf)` | `rho_w = 9.0 lb/ft²` (44 kg/m²); baseline area `W_TO/92.17` (self-scaling); `S_ref` LIVE from geom | **[Raymer 6th ed. Table 15.2 fighter; metabook_data.md:483]** — matches A481 A02's `WingDensity=44 kg/m²`. `design_WS_psf=92.17` from the `.weights` block |
| ENGINE delta `Weng(T_SL) - Weng(design_TW·W_TO)` | `Weng = WeightsL1.engine_weight_roskam`; baseline thrust `1.2·W_TO` (self-scaling); n_eng=1 (no count division); `T_SL` LIVE from prop | **[Roskam Eqs. 7.13-7.19]** = `Utility.MetaEngine` (identical 5-term form). `design_TW=1.2` from the `.weights` block. KEEPS reverser term `W_rev=0.034·T` — `_TODO` fighter has none (A9) |

**The A481 vs framework engine-weight match:** `MetaEngine.m` and
`WeightsL1.engine_weight_roskam` compute the SAME dry/oil/rev/control/start terms — the F-35
wires to the shared framework static, it does not re-derive it. **The A481 vs framework wing
density match:** A481 A02 uses 44 kg/m² = the Raymer Table 15.2 fighter 9 lb/ft². Both are
genuine reuse, not coincidence.

---

## 5. Tail — `Aero481TailL1`

`classdef Aero481TailL1 < TailSizingModelL1` (volume-coefficient sizing, mirrors `F16TailL1`).

| Property / method | Value / formula | Citation |
|---|---|---|
| `c_HT` | 0.40 | **[Raymer 7th ed. Table 6.4 jet-fighter; metabook Ch.8]** via `TailL1.lookup_tail_volume_coeffs('jet_fighter')` |
| `c_VT` | 0.07 | **[Raymer 7th ed. Table 6.4 jet-fighter; metabook Ch.8]** |
| `L_arm` | `0.475·L_fus` | **[Raymer 7th ed. aft-mounted single-engine text rule]** via `TailL1.compute_tail_arm` (midpoint of 0.45-0.50) |
| `S_ht` | `c_HT·cbar·S_ref/L_arm` | **[Raymer Table 6.4]** via `TailL1.compute_S_HT` |
| `S_vt` | `c_VT·b·S_ref/L_arm` | **[Raymer Table 6.4]** via `TailL1.compute_S_VT` |

`_TODO`: F-35 RSS (relaxed static stability) / all-moving-tail flags — the F-16 applies −10%
(RSS) and −12.5% (all-moving) corrections via `TailL1.compute_tail_volume_coeffs`. Whether
the F-35 takes these is `_TODO — UNCITED`; carry the UNCORRECTED base fighter coefficients
until a flag is set (like the B777, which takes the uncorrected base). The 0.475 arm is a
CITED fighter default (unlike B777's uncited 0.525 wing-mounted arm).

---

## 6. Constraint mapping — `Aero481ConstraintSet.constraint_map()`

Maps each Aero 481 `+Constraints/*` condition to an EXISTING framework `ConstraintType`
(all already built in Step 2; **NO new constraint class**). 21 condition rows. `oei = false`
throughout (single engine). Power setting: fighter `"mil"`/`"AB"`. `beta` = W/W_TO
requirement input.

| # | A481 condition | flight condition | power | framework class | citation |
|---|---|---|---|---|---|
| 1 | Cruise (Crs) | 35 kft, M0.85 | mil | `LevelFlight` | `[A481 Cruise.m; All.m:66]`; master eq. `[Mattingly]` |
| 2 | Dash (Dsh) | 35 kft, M1.6 | AB | `LevelFlight` | `[A481 All.m:70]` |
| 3 | Sustained turn 1 (Man1) | 35 kft, M0.9, n=2 | AB | `SustainedTurn` | `[A481 SustainedTurn.m; All.m:78]` |
| 4 | Sustained turn 2 (Man2) | 35 kft, M1.2, n=2 | AB | `SustainedTurn` | `[A481 All.m:82]` |
| 5 | SEP1 SL (1g, M0.9, Ps=200 ft/min→3.33 fps) | SL, mil | mil | `ExcessPower` | `[A481 SpecExcessPower.m; All.m:93]` |
| 6 | SEP1 alt (1g, M0.9, 15 kft, Ps=50) | 15 kft, mil | mil | `ExcessPower` | `[A481 All.m:94]` |
| 7 | SEP2 SL (1g, M0.9, Ps=700, max) | SL, AB | AB | `ExcessPower` | `[A481 All.m:97]` |
| 8 | SEP2 alt (1g, M0.9, 15 kft, Ps=400) | 15 kft, AB | AB | `ExcessPower` | `[A481 All.m:98]` |
| 9 | SEP3 SL (5g, M0.9, Ps=300) | SL, AB | AB | `ManeuveringExcessPower` | `[A481 All.m:101]` (n>1 AND Ps>0) |
| 10 | SEP3 alt (5g, M0.9, 15 kft, Ps=50) | 15 kft, AB | AB | `ManeuveringExcessPower` | `[A481 All.m:102]` |
| 11 | Instantaneous turn (Ins) | 35 kft, M1.6, 18°/s | AB | `InstantaneousTurn` | `[A481 InstantaneousTurn.m; All.m:86]` (g typo A3 corrected) |
| 12 | Ceiling (Cei) | 35 kft, M1.6, G=1° | AB | `Ceiling` (or `ExcessPower` via Ps=G·V) | `[A481 Ceiling.m; All.m:74]` |
| 13 | Climb 1 (Clb1, TO) | G=0.6210, ks=1.2, TO-gear | mil | `ClimbGradient` | `[A481 Climb.m "TO"]`; `[metabook Eq. 4.24]` |
| 14 | Climb 2 (Clb2, TS) | G=0.6210, ks=1.15, TO-gear | mil | `ClimbGradient` | `[A481 "TS"]` |
| 15 | Climb 3 (Clb3, SS) | G=0.4033, ks=1.2, TO-no-gear | mil | `ClimbGradient` | `[A481 "SS"]` |
| 16 | Climb 4 (Clb4, EN) | G=0.4033, ks=1.25, clean, mcont | mil | `ClimbGradient` | `[A481 "EN"]` |
| 17 | Climb 5 (Clb5, BA) | G=0.6210, ks=1.3, landing-gear, wr=(1-ff) | mil | `ClimbGradient` | `[A481 "BA"]` |
| 18 | Climb 6 (Clb6, BO) | G=0.6210, ks=1.5, approach, wr=(1-ff) | mil | `ClimbGradient` | `[A481 "BO"]` |
| 19 | Takeoff | SL, BFL / ground roll | AB | `TakeoffFieldLength` (TOP) or military `Takeoff` | `[metabook Eqs. 4.14-4.16]`; A481 unimplemented — `_TODO` distance |
| 20 | Landing | SL, field length | — | `LandingFieldLengthFAR25` or military `Landing` | `[metabook Eqs. 4.19/4.45]`; A481 unimplemented — `_TODO` distance/μ |

**Notes:**
- **Ps unit:** A481 passes `Ps = Ft2M(200)` etc. `Ft2M` converts ft→m, and `SpecExcessPower.m`
  uses `Ps` directly with `v` in m/s (`T_W = Ps/v + …`), so `Ps` is in **m/s** = the ft value
  read as **ft/s**. So the framework `Ps_fps` values are the raw A481 numbers directly: **200 /
  50 / 700 / 400 / 300 / 50 ft/s** (SEP1 SL/alt, SEP2 SL/alt, SEP3 SL/alt). Confirm at Gate-1;
  `_TODO — UNCITED` (student RFP Ps requirement).
- **Climb G = sin γ** (discrepancy A4): 0.6210 = 213/343 (SL), 0.4033 = 121/300 (alt) — the
  SIN-RATIO, NOT A481's `asin`. `oei = false` (single engine — `ClimbGradient` errors if
  `oei && N_eng==1`, so it MUST be false). Climb 5/6 weight_ratio = (1−ff) per `[A481 Climb.m]`.
- **Ceiling** maps to `CeilingConstraint` (reads `cond.G`, the residual gradient 1°=0.01745
  rad); alternatively `ExcessPower` via `Ps = G·V` (B777 pattern). Recommend `CeilingConstraint`
  (direct A481 parity — Ceiling.m = Cruise + G).
- **Instantaneous turn:** `InstantaneousTurnConstraint` already implements the A481 form and
  documents the g=9.087 typo (corrected to 32.174 ft/s²) and the added lapse.
- **Takeoff/Landing:** A481 leaves both unimplemented (`Takeoff.m`/`Landing.m` are stubs).
  Distances/μ/BFL are `_TODO — UNCITED` (need the RFP field requirement). Use the military
  `Takeoff`/`Landing` (F-16 pattern) OR the FAR-25 `TakeoffFieldLength`/`LandingFieldLengthFAR25`
  — recommend the military siblings for a fighter, matching the F-16.

The 6 SEP + 2 sustained-turn + instantaneous rows exercise `ExcessPower`,
`ManeuveringExcessPower`, `SustainedTurn`, `InstantaneousTurn`; the 6 climbs exercise
`ClimbGradient`; cruise/dash exercise `LevelFlight`.

---

## 7. DCA mission — `.missions.dca` on `MissionAnalysisL1`

Segment list from `[A481 A03.m]` (see `aero481_data.md` §II.8). Every segment yields a fuel burn.
Fixed-fraction segments use the CITED Roskam fighter row, NOT A03's uncited values
(discrepancy A8).

| Segment | type | end condition | data | method / citation |
|---|---|---|---|---|
| Startup | `startup` | — | — | Roskam fighter 0.990 `[Roskam Part I Table 2.1]` (A03's 0.995 SUBSTITUTED) |
| Takeoff | `takeoff` | SL | — | Roskam fighter 0.990 (A03's 0.99) |
| Climb | `climb` | 35 kft, M0.85 | — | Roskam fighter 0.93 (mean 0.90-0.96; A03's 0.96 SUBSTITUTED) |
| Cruise-out | `cruise` | 35 kft, M0.85 | 300 nmi | Breguet range `[metabook Eq. 2.7]` |
| Dash | `dash` | 35 kft, M1.6 | 100 nmi, percent_ab 100 | Breguet range (AB TSFC) |
| CAP loiter | `loiter` | `_TODO` alt/Mach | 240 min | Breguet endurance |
| Combat | `combat` | `_TODO` alt/Mach | 2 maneuvers ≈ 2×2 min | `time_min` stand-in; L1 has no fixed-fraction combat row — sized ≈ A03's `0.99·0.99` |
| Cruise-back | `cruise` | 35 kft, M0.85 | 400 nmi | Breguet range |
| Descent | `descent` | — | — | Roskam fighter 0.990 (A03's 0.98 SUBSTITUTED) |
| Landing | `landing` | SL | — | Roskam fighter 0.995 — ADDED (A03 has none; every segment burns fuel) |
| Reserve | — | — | 0.05 | `[A481 A03.m:91]` |

**Substitution (A8):** A03's `ff1=0.995, ff2=0.99, ff3=0.96, ffdescent=0.98` are uncited;
the repo's `MissionEquations.roskam_fixed_fraction('fighter', ...)` supplies the cited
`[Roskam Part I Table 2.1]` fractions. Physics segments (cruise/dash/CAP/cruise-back) stay
Breguet. CAP condition (alt/Mach) and combat time are `_TODO — UNCITED`.

---

## 8. Comparison targets — `aero481_comparison.m` (informational)

Two reference blocks, LOUDLY separated:

### 8.1 Design01 design point (the reproduction target)

- W/S = **92.17 psf**, T/W = **1.2** `[A481 Design01.m:20-21]`.
- Per-constraint T/W at W/S = 92.2 psf: evaluate each framework constraint's `required_TW` at
  the design W/S and compare to the inline A481 `+Constraints/*` formula (the
  `brandt_constraint_reference.m` pattern), annotating each systematic delta:
  - **thrust lapse added** (A6) — framework divides by α, A481 does not. Own section.
  - **SEP maneuver-weight handling** — A481 SpecExcessPower.m uses `W_S·(1+(1-ff))/2·n`
    (50% internal fuel at load factor n); the framework `ExcessPower`/`ManeuveringExcessPower`
    uses `beta` for the weight fraction. Delta annotated.
  - **Oswald form** (A2) — identical if Λ_LE < 30°, diverges if ≥ 30°.
  - **sin-vs-asin climb gradient** (A4) — framework uses sin-ratio; A481 uses asin.
  - **Roskam vs A03 mission fractions** (A8).

### 8.2 Published F-35A block (LOUD cross-check flag)

- MTOW ≈ 65,900-70,000 lb, T = 43,000 lbf, S = 460 ft² → **W/S ≈ 143-152 psf** vs Design01's
  **92.2** (`aero481_data.md` Part I). Flag: Design01 sizes a MUCH lighter-loaded wing than the
  real F-35A. AR 4 vs 2.66 (A5). This is a fidelity/design gap, NOT an error to fix.

---

## 9. `_TODO — UNCITED` sign-off list (Gate-1)

See `aero481_discrepancies.md` §"`_TODO` roll-up" for the full table. Every item there
needs a deliberately-failing `testTODO` guard (labelled) until a citation is pinned — the only
expected `run_all_tests` exception (CLAUDE.md). Key items: AR=4 (A5), OEW `0.882·W^-0.055`
(A7), CD0/CLmax config tables, TSFC 0.35/0.65/1.70, lapse `m=0.6` (A6), climb ratios 213/343 &
121/300 (A4), payload 18,000+441, `Λ_LE`/RSS/all-moving flags, CAP condition, combat time,
takeoff/landing distances/μ, reverser term (A9), Ps unit (§6 note).
