# f16a_requirements — companion doc

Companion to `examples/F16A/jsons/f16a_requirements.json` — the F-16A Block 10/15 top-level
design **REQUIREMENTS** (what the aircraft must DO). The file is fidelity-independent (one
file, no `_L{1,2,3}` suffix) and is read via `f16a_requirements_path()`.

**SCOPE GUARD.** This file holds requirements ONLY — never SPEC data (what the aircraft IS —
reference areas, AR, taper, sweep, t/c, fuselage envelope, thrust, engine model: those stay in
`examples/F16A/f16a_L{1,2,3}.json`) and never DISCIPLINE-owned quantities (CLmax, CD0, K1, K2,
CDx, thrust-lapse alpha, TSFC: those come from the injected aero/prop objects at run time — see
§4). The constraint conditions live here too, in the `constraints` block, because each is a
requirement (sustain 4.5 g at 20 kft, cruise at M 0.87 / 36 kft, take off in 4000 ft).

**Citation keys.** `Consts!` / `Main!` / `Ps!` / `Aero!` = tabs/cells in
`VnV/BrandtF16A/GroundTruth/Brandt-F16-A.xls`. `f16a_geometry.json` =
`VnV/BrandtF16A/GroundTruth/f16a_geometry.json`. `f16a_ground_truth.json` =
`VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json`. `cell-map` =
`VnV/BrandtF16A/GroundTruth/cell-map.md`.

---

## 1. Top-level requirement keys

| Key | Value | Consumers | Source |
|-----|-------|-----------|--------|
| `cruise.altitude_ft` | 36000 | `F16WeightsL3` (builds the `AircraftState` for `SFC_mission = prop.get_TSFC(cruise)`) | Brandt `Consts!` row 24 (pct_AB = 0, dry/mil); `f16a_ground_truth.json` `.propulsion...rows[cruise]` |
| `cruise.mach` | 0.87 | " | " |
| `design_mach` | 2.0 | `F16WeightsL2`/`L3` (Raymer Eq. 10.10 `W_en`, Eq. 15.3 VT, Eq. 15.17 flight controls); `F16GeomL1` (Raymer Tbl 4.1 `AR_eq`) | Brandt `Main!` `aircraft.Mmax`; `f16a_geometry.json:9` `"Mmax": 2.0` |

**`design_mach` citation caveat** (from the JSON's `_TODO_design_mach` key). The repo carries
the design max Mach as TWO numbers — Brandt's `2.0` (used here) and the T.O. 1F-16A-1 operating
limit `2.05` (−2.44 %). `2.0` must be cited to Brandt and must NOT be cited to the T.O. (that
would attribute a Brandt input to a primary document stating something else). Sensitivity is
minor (Raymer Eq. 10.10 `W_en` +0.62 % at 2.05; L3 OEW 15705.33 → 15725.41). The
`_TODO_design_mach` key is removed once the professor confirms which figure is the requirement.

---

## 2. `constraints` block — schema

The `constraints` block holds the 8 F-16A conditions, each an object under
`constraints.conditions`. Each object holds requirement / condition data ONLY. The block stays
inside this file (not a sibling `f16a_constraints.json`); it is small today (8 conditions, ~6
fields each). It is read by `ConstraintSetImporter.read_conditions` and wired into concrete
constraint objects by `ConstraintAnalysis.from_requirements`, which picks each condition's
constraint class from a caller-supplied condition-name → `ConstraintType` map (the F-16's map is
`F16ConstraintSet.constraint_map`).

### 2.1 Common fields (every condition)

| Field | Type | Meaning | Notes |
|-------|------|---------|-------|
| `name` | string | Human-readable condition name | e.g. `"Max Mach"`, `"Combat Turn 1 (subsonic)"` |
| `category` | string | Constraint-diagram axis this condition bounds | `"Both_WbyS_TbyW"` / `"Only_WbyS"` / `"Only_TbyW"` |
| `altitude_ft` | number | Flight/field altitude | ft |
| `mach` | number | Flight Mach number | — (Takeoff carries `mach_liftoff` instead; Landing carries none) |
| `beta` | number | W/W_TO at which the condition must be met | **SPECIFIED REQUIREMENT INPUT**, not a mission-analysis output (user directive 2026-08-04). Operational rows = 0.89966696; field/stall rows = 1.0 |

**condition name → concrete class.** The concrete class is chosen EXPLICITLY per condition by the
`F16ConstraintSet.constraint_map` (a `string` → `ConstraintType` map), not inferred from the data;
`category` only names the constraint-diagram axis the condition bounds. The F-16's map:
- `Both_WbyS_TbyW` rows → the `MasterEquationConstraint` subtree — Max Mach/Cruise/Max Alt →
  `LevelFlightConstraint` (n = 1, Ps = 0); Combat Turn 1/2 → `SustainedTurnConstraint` (n > 1);
  Excess Power → `ExcessPowerConstraint` (Ps > 0) — plus Takeoff → `TakeoffConstraint` (a direct
  `Both_WbyS_TbyW` sibling, ground-roll equation).
- `Only_WbyS` rows → Landing → `LandingConstraint`. (Stall is NOT an F-16 diagram condition — the
  JSON carries none; its L2/L3 clean-CLmax wall would spuriously bind the optimum, ToDo_Darshan.md §3.
  `StallConstraint` still exists and is unit-tested standalone.)
- `Only_TbyW` → none used by the F-16 set today.

[src: `F16ConstraintSet.m`, `src/constraints/ConstraintType.m`, `src/constraints/ConstraintAnalysis.m`, `src/constraints/MasterEquationConstraint.m`,
`LevelFlightConstraint.m`, `SustainedTurnConstraint.m`, `ExcessPowerConstraint.m`,
`TakeoffConstraint.m`, `LandingConstraint.m`, `StallConstraint.m`]

### 2.2 Thrust-condition fields (the 6 point-performance rows, all `Both_WbyS_TbyW`)

| Field | Type | Meaning | Notes |
|-------|------|---------|-------|
| `n` | number | Load factor | selects `LevelFlight` (1) vs `SustainedTurn` (>1) |
| `Ps_fps` | number | Specific excess power required | ft/s; > 0 selects `ExcessPowerConstraint` |
| `power_setting` | string | Engine power state | `"AB"` or `"mil"`, stored directly in the JSON and validated by `MasterEquationConstraint.requirePowerSetting` (no AB%→setting mapping) |

`power_setting` selects the thrust-lapse basis (`"mil"` →
`PropulsionBase.thrust_lapse_mil_on_AB_scale`, `"AB"` → `PropulsionBase.thrust_lapse`). It
replaces the raw AB% number: the framework models only the two discrete bases, so a partial-AB
value errors.

### 2.3 Field-condition fields (Takeoff, Landing)

| Field | Type | Meaning | Notes |
|-------|------|---------|-------|
| `distance_ft` | number | Ground-roll distance requirement | ft. Brandt `S_TO_ft` / `S_land_ft` |
| `mu` | number | Surface friction coefficient | rolling (Takeoff) / braking (Landing) |
| `k_factor` | number | Speed margin V/V_stall | k_TO = 1.2 (Takeoff) / k_L = 1.3 (Landing) |
| `mach_liftoff` | number | **Takeoff only** — liftoff Mach ≈ 0.2 | condition kinematic approximation V_liftoff/a_SL, NOT an aero quantity |

Takeoff's `category` is `Both_WbyS_TbyW` (it bounds the T/W-vs-W/S curve — `TakeoffConstraint <
Both_WbyS_TbyW`), but it takes the field fields above, not the thrust fields, and carries no
`power_setting` key because the takeoff class always evaluates at full AB [`Consts!AT32`].
Landing is power-off, so it carries no `mach` / `power_setting` / `n` / `Ps_fps` — only
`altitude_ft` (0), `beta` (1.0), `distance_ft`, `mu`, `k_factor`.

### 2.4 Stall — not carried as a condition

Stall is NOT an F-16 diagram condition and is absent from `constraints.conditions`. At L2/L3 the
aero object's geometry-based clean CLmax (~0.91) would put the stall wall at W/S ~ 62 psf and
spuriously bind the optimum; the fix belongs in aerodynamics (ToDo_Darshan.md §3). `StallConstraint`
still exists and is unit-tested standalone. Reference stall-speed value, for when it is re-added:
Mach 0.217466 at sea level [Brandt `Ps!B10`] (see §3.3).

---

## 3. Per-condition value table

Operational (thrust) rows use `beta = 0.89966696` [Brandt `Consts!B23`; `f16a_geometry.json`
`constraints.beta_perf`]; field/stall rows use `beta = 1.0`. The full-precision `0.89966696` is
carried (not the rounded `0.8997`).

### 3.1 Thrust conditions (category `Both_WbyS_TbyW`)

| name | alt_ft | mach | n | Ps_fps | power_setting | beta | class (T9) | Brandt row |
|------|--------|------|---|--------|---------------|------|------------|------------|
| Max Mach | 36000 | 1.60 | 1.0 | 0 | `"AB"` | 0.89966696 | LevelFlight | `Consts!23` |
| Cruise | 36000 | 0.87 | 1.0 | 0 | `"mil"` | 0.89966696 | LevelFlight | `Consts!24` |
| Max Alt (ceiling) | 50000 | 0.87 | 1.0 | 0 | `"AB"` | 0.89966696 | LevelFlight | `Consts!25` |
| Combat Turn 1 (subsonic) | 20000 | 0.87 | 4.5 | 0 | `"AB"` | 0.89966696 | SustainedTurn | `Consts!26` |
| Combat Turn 2 (supersonic) | 36000 | 1.40 | 1.4 | 0 | `"AB"` | 0.89966696 | SustainedTurn | `Consts!27` |
| Excess Power | 10000 | 0.87 | 1.0 | 500 | `"AB"` | 0.89966696 | ExcessPower | `Consts!28` |

Source for every alt/mach/n/pct_AB/Ps_fps cell:
`f16a_geometry.json` `constraints.conditions.{max_mach,cruise,max_alt,combat_turn_sub,combat_turn_sup,ps_500}`,
corroborated by `cell-map` `Consts!C23:F28`.
`power_setting` is derived from `pct_AB` per §2.2.

### 3.2 Field conditions

| name | category | alt_ft | mach / mach_liftoff | beta | distance_ft | mu | k_factor | Brandt row |
|------|----------|--------|---------------------|------|-------------|-----|----------|------------|
| Takeoff | Both_WbyS_TbyW | 0 | `mach_liftoff` = 0.2 | 1.0 | 4000 | 0.03 | 1.2 (k_TO) | `Consts!32` |
| Landing | Only_WbyS | 0 | — (power-off) | 1.0 | 4000 | 0.50 | 1.3 (k_L) | `Consts!33` |

- `distance_ft` = 4000 (ground roll) [`f16a_geometry.json` `constraints.takeoff.S_TO_ft` /
  `constraints.landing.S_land_ft`; `cell-map` `Consts!G32` (`S_TO`), `Consts!E33` (`S_land`)].
- `mu`: Takeoff `mu_rolling` = 0.03 [`Main!V12`]; Landing `mu_braking` = 0.50 [`Main!V13`].
- `k_factor`: k_TO = 1.2 [`Main!U12`, liftoff_factor]; k_L = 1.3 [`Main!U13`, approach_factor].
  These match the src class defaults [`TakeoffConstraint.m`, `LandingConstraint.m`].
- `mach_liftoff` = 0.2 (Takeoff only): Brandt's approximation for V_liftoff/a_SL — a condition
  kinematic approximation, NOT an aero quantity [`Consts!AT32`;
  `f16a_geometry.json` `constraints.takeoff.mach_liftoff`].

### 3.3 Stall — not a current condition

Not carried in `constraints.conditions` (see §2.4). Reference value for a future re-add: Mach
0.217466 at sea level, category `Only_WbyS` [Brandt `Ps!B10`]; not a Brandt `Consts`-sheet row and
not in `f16a_geometry.json`.

---

## 4. EXCLUDED — because aero/prop-owned (SCOPE GUARD)

These quantities are **NOT** JSON inputs. They come from the injected aero / prop discipline
objects at run time. The Brandt `Consts`-tab columns that hold them are
verification targets, not inputs.

| Quantity | Owner | Why excluded |
|----------|-------|--------------|
| `CLmax`, `CLmax_TO`, `CLmax_land` | aero | Computed by the aero object (`aero.get_CLmax` / `get_CLmax_TO` / `get_CLmax_L`). Brandt's `Aero!H27` = 1.276 / `H29` = 1.426 are verification targets. |
| `CD0`, `K1`, `K2` | aero | From `aero.drag_polar(state)` (Aero-tab CDmin_sub basis), supplied live. |
| `CDx` (takeoff/landing gear+flap drag = 0.035 / 0.045) | aero | Already provided by aero via `get_Delta_CD0_TO()` / `get_Delta_CD0_L()` at L1/L2/L3, so NOT a JSON input. |
| `CDx` (six thrust rows) | — | Brandt's per-condition `CDx` is **0.0** for all six thrust rows [`f16a_geometry.json` `conditions.*.CDx` = 0.0], so there is nothing to carry. |
| `alpha` (thrust lapse) | prop | From `prop.thrust_lapse(state)` (AB) / `thrust_lapse_mil_on_AB_scale(state)` (mil), selected by `power_setting` [`Consts!AU`]. |
| `thrust`, `TSFC`, `Cfe` | prop / aero | Discipline internals; never constraint inputs. |
| `Vstall` | aero (derived) | The Brandt `Consts`-tab `Vstall` column is not read — the speed margins live in `k_factor`. |

---

## 5. Resolved decisions (provenance, user directive 2026-08-04)

- **`beta` precision.** Full-precision `0.89966696` (operational) / `1.0` (field/stall), cited
  `Consts!B23`.
- **`k_factor` citation.** k_TO = 1.2 → Brandt `Main!U12`; k_L = 1.3 → Brandt `Main!U13` (the
  ground-truth source). The NPTEL notebook quotes the same 1.2 / 1.3; the primary
  citation is Brandt.
- **Stall Mach.** `0.217466` cited to `Ps!B10` (not a `Consts` row; not in `f16a_geometry.json`).
  A future cross-check against the live `Brandt-F16-A.xls` is still advisable; the citation is
  final.
- **Field length.** `distance_ft` = 4000 ft ground roll (final) — the value the constraint
  equations consume. No alternative field-length figure is carried.

No entries were logged to `VnV/BrandtF16A/todo.md` for this data — every value is single-sourced
from `f16a_geometry.json` (or `Ps!B10` for Stall) and corroborated by `cell-map`
without conflict.
