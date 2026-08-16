# aero481_requirements -- companion doc

Companion to `examples/Aero481/inputs/aero481_requirements.json` -- the F-35 top-level design
**REQUIREMENTS** (what the aircraft must DO). The file is fidelity-independent (one file, no
`_L{1,2,3}` suffix) and is read the same way as `f16a_requirements.json` /
`b777_requirements.json`. All values trace to the approved scribe plan
(`examples/Aero481/aero481_scribe_plan.md` sections 6-7) and `docs/reference_extracts/aero481_data.md`
Part II.

**SCOPE GUARD.** This file holds requirements ONLY -- never SPEC data (AR, `S_ref`, thrust,
engine model, config tables: those stay in `examples/Aero481/inputs/aero481_L1.json`) and never
DISCIPLINE-owned quantities (CLmax, CD0, K1, K2, CDx, thrust-lapse alpha, TSFC: those come from the
injected `Aero481AeroL1` / `Aero481PropL1` objects at run time; `n_engines` from the injected geom/prop
object). The constraint conditions and mission profiles live here because each is a requirement.

**Provenance.** The design source is the Aero 481 (Fall 2024) starter code -- PROVENANCE, not a
primary source. Each row carries an `[A481 <file>]` tag plus a primary re-citation or a
`_TODO -- UNCITED` marker. Constraint-class field names were verified against the
`src/constraints/*.m` `fromCondition` readers (see section 4).

**Units.** English (ft, ft/s, deg for Mach-free rows; the ceiling `G` is in radians as the class
reads it). SI -> English conversions noted per row.

---

## 1. Top-level requirement keys

| Key | Value | Unit | Consumers | Source |
|-----|-------|------|-----------|--------|
| `cruise.altitude_ft` | 35000 | ft | DCA cruise/cruise-back segments; the Cruise constraint | `[A481 Cruise.m; All.m:66]` |
| `cruise.mach` | 0.85 | -- | " | `[A481 Cruise.m]` |
| `design_mach` | 1.6 | -- | `Aero481GeomL1.get_AR_eq`; `Aero481WeightsL1` (Raymer Eq. 10.10) | `[A481 Dash, All.m:70]`; **`_TODO -- UNCITED`** |

35,000 ft = 10,668 m (`[A481 A03.m]` cruise/dash assumption). `design_mach` = 1.6 is the dash
Mach; **`_TODO -- UNCITED`** (student RFP value).

---

## 2. `constraints` block -- schema and class map

The `constraints.conditions` array holds the **12 ACTIVE Aero 481 conditions**. Each maps an
Aero 481 `+Constraints/All.m` condition to an **existing** framework `ConstraintType` (no new
constraint class); the mapping is chosen explicitly by `Aero481ConstraintSet.constraint_map()`,
mirroring `F16ConstraintSet`.

**DROPPED vs the earlier 20-row set (user decision, A481 parity).** Two groups were removed:
(1) the six FAR-25 **climb gradients** (Climb 1-6: TO/TS/SS/EN/BA/BO) are
transport-certification gradients and do **not** apply to a fighter; (2) **Takeoff** and
**Landing** were framework-only additions -- Aero 481 leaves both **unimplemented**
(`All.m:37` sets `ConstraintStruct.TO = 0`; Landing is a stub). The 12 rows below are exactly
the ACTIVE Aero 481 constraints `[A481 All.m]`.

### 2.1 Common fields

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | condition label |
| `category` | string | `"Both_WbyS_TbyW"` / `"Only_TbyW"` / `"Only_WbyS"` -- the constraint-diagram axis, = the class's parent category |

### 2.2 Condition-count note

The file carries **12 rows** -- exactly the ACTIVE Aero 481 `+Constraints/All.m` constraints
(Cruise, Dash, two sustained turns, six SEP points, instantaneous turn, ceiling). The six
FAR-25 climb gradients and the framework-only Takeoff/Landing rows that appeared in an earlier
20-row draft were dropped (see the section 2 note). No row is invented.

### 2.3 Condition name -> concrete class (`ConstraintType`)

| # | Condition (A481) | framework class | `ConstraintType` | category |
|---|---|---|---|---|
| 1 | Cruise | `LevelFlightConstraint` | `LevelFlight` | `Both_WbyS_TbyW` |
| 2 | Dash | `LevelFlightConstraint` | `LevelFlight` | `Both_WbyS_TbyW` |
| 3 | Sustained Turn 1 (subsonic) | `SustainedTurnConstraint` | `SustainedTurn` | `Both_WbyS_TbyW` |
| 4 | Sustained Turn 2 (supersonic) | `SustainedTurnConstraint` | `SustainedTurn` | `Both_WbyS_TbyW` |
| 5 | SEP1 SL | `ExcessPowerConstraint` | `ExcessPower` | `Both_WbyS_TbyW` |
| 6 | SEP1 alt | `ExcessPowerConstraint` | `ExcessPower` | `Both_WbyS_TbyW` |
| 7 | SEP2 SL | `ExcessPowerConstraint` | `ExcessPower` | `Both_WbyS_TbyW` |
| 8 | SEP2 alt | `ExcessPowerConstraint` | `ExcessPower` | `Both_WbyS_TbyW` |
| 9 | SEP3 SL (5g) | `ManeuveringExcessPowerConstraint` | `ManeuveringExcessPower` | `Both_WbyS_TbyW` |
| 10 | SEP3 alt (5g) | `ManeuveringExcessPowerConstraint` | `ManeuveringExcessPower` | `Both_WbyS_TbyW` |
| 11 | Instantaneous Turn | `InstantaneousTurnConstraint` | `InstantaneousTurn` | `Both_WbyS_TbyW` |
| 12 | Ceiling | `CeilingConstraint` | `Ceiling` | `Only_TbyW` |

**Dropped rows.** Climb 1-6 (`ClimbGradientConstraint`) and Takeoff/Landing
(`TakeoffConstraint` / `LandingConstraint`, military) are **no longer carried** -- FAR-25 climbs
are transport-certification gradients not applicable to a fighter, and Aero 481 leaves
Takeoff/Landing unimplemented. See the section 2 note.

---

## 3. Per-condition value table

### 3.1 `beta` and `power_setting` (all thrust rows)

- `beta = W/W_TO` is a SPECIFIED REQUIREMENT INPUT, not a mission output.
  - Cruise / Dash / Ceiling / Sustained-Turn / Instantaneous rows carry `beta = 1.0`
    (**takeoff weight** -- Aero 481 uses the raw takeoff `W/S` for these).
  - The six **SEP** rows carry `beta = 0.8285`: Aero 481's `SpecExcessPower.m` **alone**
    evaluates at the 50%-internal-fuel **combat** weight `W_S_mw = W_S*(1+(1-ff))/2`, with
    `ff = 0.343` (the DCA fuel fraction) => `(1+(1-0.343))/2 = 0.8285`
    `[A481 SpecExcessPower.m:28]`. The framework Master Equation multiplies `W/S` by `beta` in
    its B/C/D terms, so `beta = 0.8285` reproduces the A481 combat-weight basis. The load factor
    `n` is carried and applied **separately** by the master equation, so `beta` is the combat
    fraction only (NOT `combat*n`).
- `power_setting`: fighter `"mil"` (0 % AB) or `"AB"` (100 % AB), per the A481 condition.

### 3.2 Cruise / Dash / Sustained turns / SEP (rows 1-10)

| # | name | alt_ft | mach | n | Ps_fps | power | class fields read | A481 |
|---|---|---|---|---|---|---|---|---|
| 1 | Cruise | 35000 | 0.85 | (1) | (0) | mil | altitude_ft, mach, beta, power_setting | `Cruise.m; All.m:66` |
| 2 | Dash | 35000 | 1.60 | (1) | (0) | AB | altitude_ft, mach, beta, power_setting | `All.m:70` |
| 3 | Sustained Turn 1 | 35000 | 0.90 | 2.0 | (0) | AB | altitude_ft, mach, beta, n, power_setting | `SustainedTurn.m; All.m:78` |
| 4 | Sustained Turn 2 | 35000 | 1.20 | 2.0 | (0) | AB | altitude_ft, mach, beta, n, power_setting | `All.m:82` |
| 5 | SEP1 SL | 0 | 0.90 | 1.0 | 200 | mil | altitude_ft, mach, beta, Ps_fps, power_setting | `SpecExcessPower.m; All.m:93` |
| 6 | SEP1 alt | 15000 | 0.90 | 1.0 | 50 | mil | altitude_ft, mach, beta, Ps_fps, power_setting | `All.m:94` |
| 7 | SEP2 SL | 0 | 0.90 | 1.0 | 700 | AB | altitude_ft, mach, beta, Ps_fps, power_setting | `All.m:97` |
| 8 | SEP2 alt | 15000 | 0.90 | 1.0 | 400 | AB | altitude_ft, mach, beta, Ps_fps, power_setting | `All.m:98` |
| 9 | SEP3 SL (5g) | 0 | 0.90 | 5.0 | 300 | AB | altitude_ft, mach, beta, n, Ps_fps, power_setting | `All.m:101` |
| 10 | SEP3 alt (5g) | 15000 | 0.90 | 5.0 | 50 | AB | altitude_ft, mach, beta, n, Ps_fps, power_setting | `All.m:102` |

`(1)` / `(0)` in parentheses = fixed by the class (LevelFlight fixes n = 1, Ps = 0;
SustainedTurn fixes Ps = 0), not carried in the JSON. **`beta`:** rows 1-4 carry `beta = 1.0`
(takeoff weight); the six SEP rows (5-10) carry `beta = 0.8285` (the Aero 481 combat weight, see
section 3.1).

**Ps unit (`_TODO -- UNCITED`).** A481 passes `Ps = Ft2M(200)` etc. `Ft2M` converts ft -> m, and
`SpecExcessPower.m` uses `Ps` directly with `V` in m/s, so the ft value read as ft/s IS the
framework value: **200 / 50 / 700 / 400 / 300 / 50 ft/s**. These are the raw A481 numbers, marked
`_TODO -- UNCITED` (student RFP Ps requirement).

### 3.3 Instantaneous turn (row 11)

`InstantaneousTurnConstraint.fromCondition` reads `altitude_ft`, `mach`, `turn_rate_dps`,
`power_setting`.

| Field | Value | Source |
|---|---|---|
| `altitude_ft` | 35000 | `[A481 InstantaneousTurn.m; All.m:86]` |
| `mach` | 1.60 | " |
| `turn_rate_dps` | 18.0 | student RFP turn rate; **`_TODO -- UNCITED`** |
| `power_setting` | `"AB"` | full AB maneuver |

The A481 `g = 9.087` typo (disc A3) is already corrected to 32.174 ft/s^2 by the existing class,
and the class adds a thrust lapse A481 omits.

### 3.4 Ceiling (row 12)

`CeilingConstraint.fromCondition` reads `altitude_ft`, `mach`, `G`, `power_setting`.

| Field | Value | Source |
|---|---|---|
| `altitude_ft` | 35000 | `[A481 Ceiling.m; All.m:74]` |
| `mach` | 1.60 | " |
| `G` | 0.01745 | residual climb gradient = 1 deg = 0.01745 rad (Ceiling.m = Cruise + G); **`_TODO -- UNCITED`** |
| `power_setting` | `"AB"` | -- |

Mapped to `CeilingConstraint` (direct A481 parity -- Ceiling.m = Cruise + G) per the Gate-1
decision, rather than the `ExcessPower via Ps = G*V` alternative. `G = 1 deg = 0.01745 rad` (the
class reads `cond.G` as the residual gradient in radians).

### 3.5 Dropped rows -- Climb 1-6, Takeoff, Landing

The six FAR-25 climb gradients and the military Takeoff/Landing rows that an earlier 20-row draft
carried are **removed** (user decision, A481 parity):

- **Climb 1-6** (TO/TS/SS/EN/BA/BO, `ClimbGradientConstraint`) are FAR-25
  transport-certification gradients and do not apply to a fighter. Aero 481's climb rows exist
  only because the starter code is transport-shaped.
- **Takeoff** and **Landing** were framework-only additions. Aero 481 leaves both
  **unimplemented** (`Takeoff.m` / `Landing.m` are stubs; `All.m:37` sets
  `ConstraintStruct.TO = 0`), so neither is a real Aero 481 constraint.

With the climbs gone, the associated `_TODO -- UNCITED` values (climb `G` ratios 213/343 /
121/300, Climb 5/6 `weight_ratio`) and the Takeoff/Landing `distance_ft` / `mu` / `k_factor`
stand-ins no longer appear in the file.

---

## 4. EXCLUDED -- because aero/prop-owned (SCOPE GUARD)

These are NOT JSON inputs; they come from the injected `Aero481AeroL1` / `Aero481PropL1` objects at run
time.

| Quantity | Owner | Why excluded |
|----------|-------|--------------|
| CLmax per config | aero | `aero.get_config_polar(config).CLmax` -- lives in `aero481_L1.json` `.aerodynamics.CLmax_config` |
| CD0, K1, K2 per config | aero | `aero.get_config_polar(config)` / `aero.drag_polar(state)` -- lives in `aero481_L1.json` `.aerodynamics` |
| CDx (external-stores drag increment) | aero | discipline internal |
| thrust-lapse alpha | prop | `prop.thrust_lapse(state, power_setting)` (mil/AB, `sigma^0.6`, mil-on-AB 0.6512 scale) |
| TSFC | prop | `aero481_L1.json` `.propulsion.tsfc_*`; a discipline internal, never a constraint input |
| `n_engines` (OEI factor) | geom/prop | `aero481_L1.json` `.geometry.n_engines` / `.propulsion.n_engines` |

---

## 5. `missions` block -- `dca`

Read by mission analysis (`MissionAnalysisL1`). The F-35 example has one mission, `dca` (defensive
counter-air), from `[A481 A03.m]` (`aero481_data.md` section II.8). Every segment yields a fuel burn.

### 5.1 Segment list

| Segment | type | end condition | data | method / citation |
|---|---|---|---|---|
| Startup | `startup` | -- | -- | Roskam fighter 0.990 `[Roskam Part I Table 2.1]` (A03's 0.995 SUBSTITUTED) |
| Takeoff | `takeoff` | SL, M 0.20 | -- | Roskam fighter 0.990 (A03's 0.99) |
| Climb | `climb` | 35 kft, M 0.85 | -- | Roskam fighter 0.93 (mean 0.90-0.96; A03's 0.96 SUBSTITUTED) |
| Cruise-out | `cruise` | 35 kft, M 0.85 | 300 nmi | Breguet range `[metabook Eq. 2.7]` |
| Dash | `dash` | 35 kft, M 1.60 | 100 nmi, `percent_ab` 100 | Breguet range (AB TSFC) |
| CAP | `loiter` | `_TODO` alt/Mach | 240 min | Breguet endurance |
| Combat | `combat` | `_TODO` alt/Mach | ~2x2 min = 4 min | `time_min` stand-in (L1 has no fixed-fraction combat row) |
| Cruise-back | `cruise` | 35 kft, M 0.85 | 400 nmi | Breguet range |
| Descent | `descent` | -- | -- | Roskam fighter 0.990 (A03's 0.98 SUBSTITUTED) |
| Landing | `landing` | SL | -- | Roskam fighter 0.995 -- ADDED (A03 has none) |
| Reserve | -- | -- | 0.05 | `[A481 A03.m:91]` |

### 5.2 The Roskam substitution (disc A8)

A03's `ff1 = 0.995, ff2 = 0.99, ff3 = 0.96, ffdescent = 0.98` are uncited. The repo's
`MissionEquations.roskam_fixed_fraction('fighter', ...)` supplies the cited
`[Roskam Part I Table 2.1]` fractions (startup/taxi/takeoff 0.990, climb 0.93, descent 0.990,
landing 0.995). Physics segments (cruise-out / dash / CAP / cruise-back) stay Breguet. Landing
(0.995) is ADDED because every segment burns fuel (A03 has no landing segment). This substitution
is a code behaviour (`MissionEquations`), documented here; the JSON carries only the segment
sequence and the per-segment data. A transport/fighter fixed-fraction `MissionEquations` entry may
need extending in the implementation phase -- flagged.

### 5.3 `_TODO -- UNCITED` (mission)

- CAP condition (`alt_ft` / `mach_end`) -- A03 assumes 35 kft for cruise/dash but does not pin the
  CAP condition; carried as 35 kft / M 0.85 stand-in. Duration 240 min (4 hr) is cited
  (`A03 E_CAP = 4*3600 s`).
- Combat `time_min` = 4 min (2 maneuvers x 2 min) -- A03 uses a `0.99*0.99` fixed fraction; L1
  has no fixed-fraction combat row, so `time_min` is a stand-in for the combat energy leg.
- Reserve 0.05 `[A03.m:91]` is a stated design reserve (carried; `_TODO` if a primary basis is
  wanted).

---

## 6. `_TODO -- UNCITED` summary (requirements file)

| Value | Block | Stand-in | Discrepancy | Needs |
|---|---|---|---|---|
| `design_mach = 1.6` | top level | A481 dash Mach | -- | student RFP value |
| SEP `Ps_fps` (200/50/700/400/300/50) | constraints | raw A481 numbers as ft/s | section 3.2 | student RFP Ps requirement |
| `turn_rate_dps = 18.0` | constraints (Instantaneous) | student RFP | -- | RFP turn rate |
| Ceiling `G = 0.01745` | constraints (Ceiling) | 1 deg | -- | RFP residual-gradient value |
| CAP condition (alt/Mach) | missions (dca) | 35 kft / M 0.85 | -- | RFP / doctrine |
| Combat `time_min = 4` | missions (dca) | 2x2 min | -- | RFP / doctrine |

The climb `G` ratios, Climb 5/6 `weight_ratio`, and Takeoff/Landing `distance_ft` / `mu` /
`k_factor` `_TODO` entries are gone with the dropped rows (section 3.5).

Every `_TODO -- UNCITED` above needs a deliberately-failing `testTODO` guard (labelled) in the
F-35 tests until a citation is pinned -- the only expected `run_all_tests` exception (CLAUDE.md).
The Roskam-fraction substitution (A8) is documented in section 5.2.
