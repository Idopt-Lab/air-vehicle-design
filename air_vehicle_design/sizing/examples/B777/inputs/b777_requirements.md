# b777_requirements — companion doc

Companion to `examples/B777/inputs/b777_requirements.json` (not yet written) — the Boeing
777-200LR top-level design **REQUIREMENTS** (what the aircraft must DO). The file is
fidelity-independent (one file, no `_L{1,2,3}` suffix) and is read the same way as
`f16a_requirements.json`.

**SCOPE GUARD.** This file holds requirements ONLY — never SPEC data (what the aircraft IS —
reference area, AR, taper, fuselage size, thrust, engine model: those stay in
`examples/B777/inputs/b777_L1.json`) and never DISCIPLINE-owned quantities (CLmax, CD0, K,
thrust-lapse alpha, TSFC: those come from the injected aero/prop objects at run time — see §4). The
constraint conditions live here, in the `constraints` block, because each is a requirement (take off
in 12,000 ft, hold the FAR-25 second-segment climb gradient, cruise at M 0.84 / 40,000 ft).

**Citation keys.** `[metabook Eq. N.NN]` / `[metabook §4.11]` = the AE481 metabook worked
Example 4.2, `docs/reference_extracts/metabook_data.md`. `[Roskam Table 3.1]` etc. are the primary
tables the metabook names.

**Discipline-owned exclusions.** CLmax, CD0 and K per config are NOT carried here. They come from
the injected `B777AeroL1` object through `aero.get_config_polar(config)`. Each constraint
row carries only its `config` string; the aero object supplies the polar and CLmax for that config.
See §4.

---

## 1. Top-level requirement keys

| Key | Value | Unit | Consumers | Source |
|-----|-------|------|-----------|--------|
| `cruise.altitude_ft` | 40000 | ft | mission cruise segment; the Cruise constraint | [metabook §4.11 Eq. 4.57] |
| `cruise.mach` | 0.84 | — | " | [metabook §4.11 Eq. 4.57] |
| `design_range_nmi` | 8555 | nmi | mission long_range cruise segment | `_TODO` — see §5.2 |

---

## 2. `constraints` block — schema

The `constraints` block holds the ~10 B777 conditions, each an object under
`constraints.conditions`. Each object holds requirement / condition data ONLY. It is read by
`ConstraintSetImporter.read_conditions` and wired into concrete constraint objects by
`ConstraintAnalysis.from_requirements`, which picks each condition's constraint class from a
caller-supplied condition-name → `ConstraintType` map (the B777's map is `B777ConstraintSet` — a new
map, to be written in the implementation phase, mirroring `F16ConstraintSet.constraint_map`).

### 2.1 Common fields (every condition)

| Field | Type | Meaning | Notes |
|-------|------|---------|-------|
| `name` | string | Human-readable condition name | e.g. `"Takeoff Field Length"`, `"2nd Segment Climb"` |
| `category` | string | Constraint-diagram axis this condition bounds | `"Both_WbyS_TbyW"` / `"Only_WbyS"` / `"Only_TbyW"` |

Unlike the F-16 set, most B777 field/climb conditions do NOT carry `beta` — the metabook field
and climb equations use explicit `weight_ratio` corrections (e.g. 0.65 MLW/MTOW for balked-landing
climbs) rather than the F-16 `beta = W/W_TO` convention. Only the Cruise condition (a
Master-Equation `LevelFlightConstraint`) and the Ceiling condition (an `ExcessPowerConstraint`)
carry `beta`, because those two classes require it.

### 2.2 condition name → concrete class

Chosen EXPLICITLY per condition by the B777 map (implementation phase), not inferred from the data:

- Takeoff Field Length → `TakeoffFieldLengthConstraint` (`Both_WbyS_TbyW`) — the TOP correlation.
- Landing Field Length → `LandingFieldLengthConstraint` (`Only_WbyS`) — a vertical W/S wall.
- Climb 1–6 → `ClimbGradientConstraint` (`Only_TbyW`) — flat T/W floors.
- Ceiling → `ExcessPowerConstraint` (`Both_WbyS_TbyW`, `MasterEquationConstraint` subtree) — via the
  `Ps = G·V` identity (see §3.4).
- Cruise → `LevelFlightConstraint` (`Both_WbyS_TbyW`) — n = 1, Ps = 0.

**Note on the two field-length siblings.** The B777 uses the FAR-25 STATISTICAL field-length
classes (`TakeoffFieldLengthConstraint` / `LandingFieldLengthConstraint`, metabook Eqs.
4.14–4.19/4.45–4.48), NOT the Mattingly/Roskam ground-roll siblings (`TakeoffConstraint` /
`LandingConstraint`) the F-16 uses. These are the correct classes for FAR-25 airliner sizing and
they read the JSON field names below.

---

## 3. Per-condition value table

### 3.1 Takeoff Field Length (category `Both_WbyS_TbyW`)

`TakeoffFieldLengthConstraint.fromCondition` reads `cond.BFL_ft` and `cond.sigma`. CLmax_TO is read
live from the aero object's `takeoff_flaps_gear_down` config (§4).

| Field | Value | Unit | Source |
|---|---|---|---|
| `name` | `"Takeoff Field Length"` | — | — |
| `category` | `"Both_WbyS_TbyW"` | — | class `TakeoffFieldLengthConstraint < Both_WbyS_TbyW` |
| `BFL_ft` | 12000 | ft | [metabook Eq. 4.47] (TOP = 12,000/37.5 = 320) |
| `sigma` | 0.95 | — | [metabook Eq. 4.48] (hot day near sea level; ρ/ρSL = 0.95) |

Hand-check: TOP = 12,000/37.5 = 320 (Eq. 4.47); denominator constant = 0.95·320 = 304
(Eq. 4.48); T/W = (W/S)/(304·CLmax_TO). CLmax_TO = 2.0 from the takeoff config (§4) reproduces
Eq. 4.48.

### 3.2 Landing Field Length (category `Only_WbyS`)

`LandingFieldLengthConstraint.fromCondition` reads `cond.runway_ft`, `cond.Sa_ft`,
`cond.weight_ratio`, `cond.sigma`, and the optional `cond.runway_factor` (defaults to 0.6). CLmax_L
is read live from the aero `landing_flaps_gear_down` config (§4).

| Field | Value | Unit | Source |
|---|---|---|---|
| `name` | `"Landing Field Length"` | — | — |
| `category` | `"Only_WbyS"` | — | class `LandingFieldLengthConstraint < Only_WbyS` |
| `runway_ft` | 12000 | ft | [metabook Eq. 4.46] (S_runway) |
| `Sa_ft` | 1000 | ft | [metabook Eq. 4.19/4.46] (airliner approach distance) |
| `weight_ratio` | 0.65 | — | [metabook Eq. 4.46] (MLW/MTOW for the 777-200LR) |
| `sigma` | 0.95 | — | [metabook Eq. 4.46] (hot day near sea level) |
| `runway_factor` | 0.6 | — | [metabook Eq. 4.46] (FAR landing-field multiple, 0.6 = 1/1.67) — optional, defaults to 0.6 |

Hand-check (Eq. 4.46): W/S = 0.95·CLmax/(80·0.65)·(12,000·0.6 − 1000) = 113.27·CLmax. With
CLmax_L = 2.6 the wall sits at W/S = 294.5 lb/ft² [metabook Fig. 4.6 caption].

### 3.3 The six climb constraints (category `Only_TbyW`)

`ClimbGradientConstraint.fromCondition` reads `cond.G`, `cond.ks`, `cond.config`, and the optional
flags `cond.oei`, `cond.hot_day`, `cond.max_continuous`, `cond.weight_ratio`. CD0/K1/CLmax are read
live from the aero object for `cond.config` (§4). N_eng comes from the injected prop object
(`n_engines = 2`), which sets the OEI factor N/(N−1) = 2/1.

The `hot_day` flag maps the metabook's `(1/0.8)` factor; `max_continuous` maps `(1/0.94)`; `oei`
maps `(N/(N−1))`. All six equations are from metabook §4.11 Eqs. 4.49–4.54 (verified against the
PDF 2026-08-13).

| name | G | ks | config | oei | hot_day | max_continuous | weight_ratio | metabook Eq. |
|---|---|---|---|---|---|---|---|---|
| Climb 1 (takeoff, FAR 25.111) | 0.012 | 1.20 | `takeoff_flaps_gear_up` | true | true | false | 1.0 | 4.49 |
| Climb 2 (transition, FAR 25.121) | 0.0 | 1.15 | `takeoff_flaps_gear_down` | true | true | false | 1.0 | 4.50 |
| Climb 3 (2nd segment, FAR 25.121) | 0.024 | 1.20 | `takeoff_flaps_gear_up` | true | true | false | 1.0 | 4.51 |
| Climb 4 (enroute, FAR 25.121) | 0.012 | 1.25 | `clean` | true | true | true | 1.0 | 4.52 |
| Climb 5 (AEO balked landing, FAR 25.119) | 0.032 | 1.30 | `landing_flaps_gear_down` | false | true | false | 0.65 | 4.53 |
| Climb 6 (OEI balked landing, FAR 25.121) | 0.021 | 1.50 | `approach` | true | true | false | 0.65 | 4.54 |

Notes tying each row to the printed equation:
- Every row applies `hot_day = true` — the `(1/0.8)` factor is present in every one of Eqs.
  4.49–4.54.
- Climb 4 is the only `max_continuous = true` row (the `(1/0.94)` factor, Eq. 4.52) and the only one
  using the `clean` config (flaps and gear retracted).
- Climb 5 (AEO) has NO OEI factor — `oei = false` — because both engines run in the FAR 25.119
  all-engines-operating balked landing.
- Climbs 5 and 6 use `weight_ratio = 0.65` (the MLW/MTOW correction).
- Climb 6 uses the `approach` config: CD0 = 0.08847 = mean(0.06097, 0.11597) and CLmax = 0.85·2.6 =
  2.21 (§4 / `b777_L1.md` §3.3).

**D1 / D2 carried, per their dispositions.** The takeoff-config climb Eqs. 4.49–4.51 use
`CLmax = 2.2` (D1) and Eq. 4.49 uses the gear-UP CD0 (D2). Both are RESOLVED (Sarojini 2026-08-13)
in favour of the PRINTED values for parity. These live in the aero CONFIG POLAR data (the config's
CLmax and CD0), NOT in this requirements file — `ClimbGradientConstraint` reads whatever the config
polar reports. The config-CLmax basis needed to reproduce both the printed climb equations AND the
printed takeoff-field-length equation is a gate decision — see `B777_decisions.md` §2. The rows
above name the FAR-correct config strings; the CLmax value each string carries is the decision to be
confirmed.

### 3.4 Ceiling (category `Both_WbyS_TbyW`, mapped to `ExcessPowerConstraint`)

The metabook ceiling constraint (Eqs. 4.55–4.56) is `T/W = (1/alpha)·(G + 2·sqrt(CD0/(π·AR·e)))`
with `G = 0.001` at 42,000 ft. In this framework it is expressed through the Master Equation as an
`ExcessPowerConstraint` (Ps > 0, n = 1) via the identity `Ps = G·V` (specific excess power =
climb-gradient × speed). `ExcessPowerConstraint.fromCondition` reads `cond.altitude_ft`,
`cond.mach`, `cond.beta`, `cond.Ps_fps`, and `cond.power_setting`.

| Field | Value | Unit | Source |
|---|---|---|---|
| `name` | `"Ceiling"` | — | — |
| `category` | `"Both_WbyS_TbyW"` | — | class `ExcessPowerConstraint < MasterEquationConstraint < Both_WbyS_TbyW` |
| `altitude_ft` | 42000 | ft | [metabook Eq. 4.56] (service ceiling) |
| `mach` | 0.84 | — | ceiling Mach `_TODO` — recommend the cruise Mach 0.84 (see below) |
| `beta` | 1.0 | — | Master-Equation classes require `beta`; ceiling is at full weight, so W/W_TO = 1.0 |
| `Ps_fps` | 0.813 | ft/s | DERIVED `Ps = G·V` — see arithmetic below |
| `power_setting` | `"mil"` | — | high-BPR transports do not use afterburner; mil = max continuous |

**`Ps = G·V` derivation (show the arithmetic).** The metabook sets the ceiling climb gradient
`G = 0.001` [metabook Eq. 4.56]. Ceiling Mach is `_TODO`; recommend the cruise Mach 0.84 (the
metabook does not print a ceiling Mach, and 0.84 is the example's own cruise Mach at high altitude).
At 42,000 ft the atmosphere is in the isothermal stratosphere (T = 389.97 °R, constant above
~36,089 ft), so the speed of sound `a = sqrt(1.4·1716.5·389.97) ≈ 968.1 ft/s`.

```
V   = M * a = 0.84 * 968.1 = 813.2 ft/s
Ps  = G * V = 0.001 * 813.2 = 0.8132 ft/s
```

So `Ps_fps = 0.813 ft/s` (round as carried). This is a DERIVED requirement value, not a metabook
print — the metabook expresses the ceiling as `G = 0.001`, and the `Ps = G·V` mapping onto the
Master Equation's D term is this framework's own. If the confirmed ceiling Mach differs from 0.84,
`Ps_fps` must be recomputed at the new V.

**Parity caveat.** The Master-Equation `ExcessPowerConstraint` uses ISA thrust lapse from
`AircraftState` (via `PropL1.get_thrust_lapse`, `alpha = sigma^m`), NOT the metabook's printed
off-ISA `alpha = 0.2331^0.6`. The comparison report evaluates the printed Eq. 4.56 with the printed
ratio for parity; the framework constraint uses ISA. See D5.

### 3.5 Cruise (category `Both_WbyS_TbyW`, `LevelFlightConstraint`)

`LevelFlightConstraint.fromCondition` reads `cond.altitude_ft`, `cond.mach`, `cond.beta`, and
`cond.power_setting`. n = 1, Ps = 0 are fixed by the class.

| Field | Value | Unit | Source |
|---|---|---|---|
| `name` | `"Cruise"` | — | — |
| `category` | `"Both_WbyS_TbyW"` | — | class `LevelFlightConstraint < MasterEquationConstraint < Both_WbyS_TbyW` |
| `altitude_ft` | 40000 | ft | [metabook Eq. 4.57] |
| `mach` | 0.84 | — | [metabook Eq. 4.57] (q = 228.8 lbf/ft²) |
| `beta` | 1.0 | — | Master-Equation classes require `beta`; take W/W_TO = 1.0 unless a cruise-start fraction is specified |
| `power_setting` | `"mil"` | — | high-BPR transport, no afterburner; mil = max continuous |

Hand-check (Eq. 4.57): `T/W = (1/0.2846^0.6)·(228.8·0.01597/(W/S) + (W/S)/(228.8·π·9.8·0.85))`.
The framework uses ISA lapse rather than the printed 0.2846 ratio (D5); the comparison report uses
the printed ratio for parity.

**`beta` note.** The metabook Example 4.2 evaluates cruise at the actual-aircraft point without an
explicit start-of-cruise weight fraction (it uses the actual W0 for the marker). Carrying
`beta = 1.0` keeps the constraint at full weight, which is conservative. If the mission analysis
later supplies a start-of-cruise weight fraction, use that value instead — but it is a REQUIREMENT
input here, not a mission output backfilled (the same rule the F-16 set follows).

---

## 4. EXCLUDED — because aero/prop-owned (SCOPE GUARD)

These quantities are NOT JSON inputs. They come from the injected `B777AeroL1` / `B777PropL1`
objects at run time.

| Quantity | Owner | Why excluded |
|----------|-------|--------------|
| CLmax per config (0.9 / 2.0 / 2.6 / 2.21) | aero | From `aero.get_config_polar(config).CLmax`. Carried in the config-polar table in `b777_L1.md` §3.1, read live by the field-length and climb constraints. |
| CD0, K1 per config | aero | From `aero.get_config_polar(config)`. The five metabook polars live in the aero object, not here. |
| thrust-lapse alpha | prop | From `prop.thrust_lapse(state)` (AB) / `thrust_lapse_mil_on_AB_scale(state)` (mil), selected by `power_setting`. Uses ISA density from `AircraftState`. |
| TSFC | prop | Mattingly Eq. 10.11 high-BPR form; a discipline internal, never a constraint input. |
| `n_engines` | prop | Read by `ClimbGradientConstraint` from the injected prop object for the OEI factor. Spec data (`b777_L1.json` .propulsion), not a requirement. |

---

## 5. `missions` block

Read by mission analysis. The B777 example has one mission, `long_range`.

### 5.1 Segment list

The `long_range` mission is a standard transport profile [metabook §2 / Algorithm 3; Roskam Table
2.1 historical fractions where a physics equation does not apply]:

| Segment | Method / fraction | Source |
|---|---|---|
| startup / taxi | historical 0.970 (start + warm-up + takeoff) | [Raymer Table 3.4; metabook §2] |
| takeoff | folded into 0.970 above | [Raymer Table 3.4] |
| climb | historical 0.985 | [Raymer Table 3.4; metabook §2] |
| cruise | Breguet range (Eqs. 2.6/2.7) | [metabook Eq. 2.7] — see §5.2 |
| descent | historical 0.990 | [Raymer Table 3.4; metabook §2] |
| loiter / reserve | 6% reserve + trapped fuel (Eq. 2.17) | [metabook Eq. 2.17] — see §5.3 |
| landing / taxi | historical 0.995 | [Raymer Table 3.4; metabook §2] |

Every segment yields a fuel burn (no zero-by-omission): the physics segment (cruise) uses Breguet;
the others use the Raymer Table 3.4 historical fractions. Landing = 0.995.

### 5.2 Cruise range and condition

| Field | Value | Unit | Kind | Source |
|---|---|---|---|---|
| cruise range | 8555 | nmi | `_TODO` | design range — see below |
| cruise Mach | 0.84 | — | input | [metabook Eq. 4.57] |
| cruise altitude | 40000 | ft | input | [metabook Eq. 4.57] |

Cruise range is `_TODO`. The 777-200LR design range is ≈ 8,555 nmi (the "LR" long-range variant);
a typical mission range is ≈ 7,725 nmi. Stand-in: 8,555 nmi (design range). Primary source needed:
a Boeing 777-200LR payload-range chart / Airport Planning document. The metabook Example 4.2 does
not print a design range (it sizes on the constraint diagram, not a range mission). Recommend
carrying 8,555 nmi as the stand-in, marked `_TODO`.

### 5.3 Reserve

| Field | Value | Source |
|---|---|---|
| `reserve_fuel_fraction` | 0.06 | [metabook Eq. 2.17] (6% reserve + trapped fuel) |

`Wf/W0 = (1 − W_final/W0)·1.06` [metabook Eq. 2.17] — the 6% covers reserve and trapped fuel.

### 5.4 Which mission-analysis tier, and a missing equations row (flag)

- The B777 Example 4.2 method is a metabook-Chapter-4 statistical method at "L1" discipline
  fidelity, consumed by BOTH the L1 and L2 sizing algorithms. The mission uses `MissionAnalysisL1`
  for the simple fixed-fraction + single-Breguet-cruise profile above; the L2 sizing algorithm
  (metabook §4.12 Algorithm 2, `We(T, S)`) wraps the same mission with the wing-area-dependent
  `CD0(S)` and L/D (Eq. 4.58 / Algorithm 3).
- **Missing equations row — flag for implementation.** The transport FIXED-FRACTION mission profile
  (startup/climb/descent/landing historical fractions + one Breguet cruise) is NOT yet a row in the
  repo's `MissionEquations`. The F-16 mission uses fighter segments (dash, combat, etc.). A new
  transport fixed-fraction `MissionEquations` entry (Raymer Table 3.4 fractions + metabook Eq. 2.7
  cruise + Eq. 2.17 reserve) MUST be added in the implementation phase before the B777 mission runs.
  This is a code change, not a JSON input — flagged here so it is not missed.

---

## 6. `_TODO` summary (requirements file)

| Value | Block | Stand-in | Primary source needed |
|---|---|---|---|
| ceiling `mach` | constraints (Ceiling) | 0.84 (cruise Mach) | a ceiling Mach for the 777-200LR, or accept the cruise-Mach recommendation |
| `design_range_nmi` / cruise range | top-level / missions | 8555 nmi | 777-200LR payload-range chart / Airport Planning doc |

The `Ps_fps = 0.813` ceiling value is DERIVED from `G·V` (not `_TODO`); it depends on the ceiling
Mach stand-in and must be recomputed if that Mach changes. The D1/D2 config-CLmax/CD0 items live in
the aero data (`b777_L1.md`), not here, and are RESOLVED (printed values) pending the §2 gate
confirmation.
