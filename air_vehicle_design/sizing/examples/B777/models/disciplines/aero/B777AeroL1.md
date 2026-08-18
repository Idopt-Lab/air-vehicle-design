# B777AeroL1

Boeing 777-200LR Level-1 aerodynamics — the metabook Example 4.2 tier. `classdef B777AeroL1 <
AeroModelL1`. `AeroModelL1` adds no abstract members beyond `AerodynamicsBase`'s `drag_polar` /
`get_CLmax`.

**L1 is the geometry-COUPLED metabook drag polar.** Unlike `F16AeroL1` — which is geometry-FREE
(Roskam-table CD0/CLmax type curves) — `B777AeroL1` INJECTS a geometry object so its clean CD0 tracks
the wing area an optimizer mutates:

```
CD0_clean = Cfe · (S_wet / S_ref)          [metabook Eq. 4.8 = Raymer Eq. 12.23]
```

with `geom.S_wet = S_wet_rest + 2·S_ref` [metabook Eq. 4.58], so `CD0` tracks `S`.

This class follows the **DEPENDENCY INJECTION + INPUT vs DERIVED pattern**, mirroring `F16AeroL2`. The
constructor takes a REQUIRED injected geometry object and a REQUIRED L1 JSON path (`.aerodynamics`
block). No silent defaults.

---

## 1. Constructor

```matlab
g1 = B777GeomL2(b777_spec_path(1));
a1 = B777AeroL1(g1, b777_spec_path(1));
```

`B777AeroL1(geom, json_path)` — both required. Sets the aero inputs and derives the per-config scalars
ONCE from the config-polar table; all live geometry is produced by the `Dependent` getters from
`obj.geom`.

`aircraft_category = "jet_transport"`: the mission analysis reads this off the aero object
(`MissionAnalysisBase`, `isprop(aero,'aircraft_category')`) to select the transport fixed-fraction
`MissionEquations` row.

---

## 2. Inputs

Plain mutable `properties`, set once by the constructor. NO live geometry here (see §3). TARGET
DESIGN (D10, 2026-08-17): the JSON `.aerodynamics` block carries ONLY the three physical CLmax
overrides; `Cfe`, `e_clean` and the `config_polars` table are REMOVED and DERIVED from the shared
toolboxes, mirroring how `F16AeroL1` hardcodes nothing and looks every per-config number up from
`AeroL1.Delta_CD0` / `AeroL1.CLmax_table`. See `B777_decisions.md` D10 and `inputs/b777_L1.md` §3.

| Property | Value | Kind | Meaning / citation |
|---|---|---|---|
| `geom` | injected | input | geometry object — all live geometry read from it |
| `aircraft_category` | `"jet_transport"` | input | canonical class flag; read by the mission to pick the transport fixed-fraction row; translated to `civil_transport` for the `AeroL2.lookup_Cfe` row [top-level canonical key] |
| `CLmax_clean` | 0.9 | **input** | clean physical CLmax override [Roskam Table 3.1] — USER decision, deviates from the `transport_jet` table row |
| `CLmax_takeoff` | 2.0 | **input** | takeoff physical CLmax override [Roskam Table 3.1] — USER decision |
| `CLmax_landing` | 2.6 | **input** | landing physical CLmax override [Roskam Table 3.1] — USER decision |

The three CLmax overrides are the ONLY genuine aero inputs — a deliberate USER deviation from the
Roskam `transport_jet` table row, so they must be carried in JSON. `Cfe`, `e_clean` and the per-config
ΔCD0/e are no longer inputs; they are derived from `AeroL2.lookup_Cfe` + `AeroL1.Delta_CD0` (see §2.1).

### 2.1 Derived-once config scalars (from toolbox tables + baseline AR, NOT from JSON)

The per-config drag scalars are still computed ONCE in the constructor (they are functions of the
Roskam Table 3.6 Constant + the three CLmax inputs + baseline `AR`, not of live geometry, so freezing
them is correct — the "derive once from inputs" case, distinct from the live geometry in §3). But the
SOURCE is now the shared toolbox tables, not a JSON `config_polars` table:

| Property | Kind | Source |
|---|---|---|
| `Delta_CD0_config` | derived-once | UPPER bound of `AeroL1.Delta_CD0` ΔCD0 column, with the 6→4 config map |
| `e_config` | derived-once | UPPER bound of `AeroL1.Delta_CD0` e_osw column, with the 6→4 config map |
| `CLmax_config` | derived-once | the three `CLmax_*` overrides; approach = 0.85·`CLmax_landing` |
| `Cfe` | derived-once | `AeroL2.lookup_Cfe(translate(aircraft_category))` = `civil_transport` row = 0.0026 |
| `e_clean` | derived-once | UPPER bound of `AeroL1.Delta_CD0` clean e_osw row = 0.85 |

```
Cfe                   = AeroL2.lookup_Cfe(jet_transport→civil_transport)  = 0.0026   [Raymer Table 12.3]
e_clean               = upper(AeroL1.Delta_CD0.e_osw[clean])              = 0.85     [Roskam Table 3.6]
Delta_CD0_config(cfg) = upper(AeroL1.Delta_CD0.Delta_CD0[flap]) + gear    [Roskam Table 3.6, 6→4 map]
e_config(cfg)         = upper(AeroL1.Delta_CD0.e_osw[flap])               [Roskam Table 3.6, 6→4 map]
CLmax_config(cfg)     = CLmax_clean / CLmax_takeoff / CLmax_landing / 0.85·CLmax_landing  [Roskam Table 3.1, USER]
```

**6→4 config map** (six B777 configs onto four Roskam Table 3.6 rows, gear-down adds the
`landing_gear` upper bound 0.025; approach = metabook Climb-6 mean of the two gear-down rows):

| config | ΔCD0 (upper) | e (upper) | CLmax |
|---|---|---|---|
| `clean` | 0.000 | 0.85 | `CLmax_clean` |
| `takeoff_flaps_gear_up` | 0.020 | 0.80 | `CLmax_takeoff` |
| `takeoff_flaps_gear_down` | 0.020 + 0.025 = 0.045 | 0.80 | `CLmax_takeoff` |
| `landing_flaps_gear_up` | 0.075 | 0.75 | `CLmax_landing` |
| `landing_flaps_gear_down` | 0.075 + 0.025 = 0.100 | 0.75 | `CLmax_landing` |
| `approach` | mean(0.045, 0.100) = 0.0725 | 0.75 | 0.85 · `CLmax_landing` |

**Upper bound vs. F16's mean (the one design choice).** `F16AeroL1`'s private `roskam_Delta_CD0` /
`roskam_e_osw` read the MEAN of each Table 3.6 range; `B777AeroL1` reads the UPPER bound (metabook
Example 4.2 convention). Both read the SAME `AeroL1.Delta_CD0` Constant — no toolbox edit.

## 3. Derived (`Dependent`)

Geometry read LIVE from `obj.geom` on every read (no cache, never stale). Read-only. `CD0` tracks `S`
because `geom.S_wet = S_wet_rest + 2·S_ref`; `K1` tracks `AR`.

| Property | Source | Unit |
|---|---|---|
| `S_ref` | ← `geom.S_ref` | ft² |
| `S_wet` | ← `geom.S_wet` (= `S_wet_rest + 2·S_ref`) | ft² |
| `AR` | ← `geom.AR` | — |

---

## 4. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `drag_polar(~)` | CLEAN polar `{CD0, K1, K2=0}`, tracking `S` live. `CD0 = AeroL2.CD0_from_Cf(Cfe, S_wet, S_ref)`; `K1 = 1/(π·AR·e_clean)`; `K2 = 0` (uncambered-basis metabook polar). `state` unused at L1 (no Mach/altitude dependence in the clean polar) | [metabook Eq. 4.8/4.58; Eq. 2.10] |
| `get_CLmax(~)` | clean max lift = `CLmax_config("clean")` = 0.9. `state` unused (config-independent clean value) | [Roskam Table 3.1; metabook §4.11] |
| `get_config_polar(config)` | `struct(CD0, K1, K2, CLmax)` for a named high-lift config — overrides the `AerodynamicsBase.get_config_polar` contract. Tracks BOTH `S` and `AR` live: `CD0 = CD0_clean_live + Delta_CD0_config(config)`; `K1 = 1/(π·AR_live·e_config(config))`; `CLmax = CLmax_config(config)` | [metabook §4.11; Eq. 2.10; Roskam Table 3.1] |
| `get_CLmax_TO()` | takeoff-config max lift = `CLmax_config("takeoff_flaps_gear_down")` = 2.0 | [Roskam Table 3.1] |
| `get_CLmax_L()` | landing-config max lift = `CLmax_config("landing_flaps_gear_down")` = 2.6 | [Roskam Table 3.1] |
| `get_Delta_CD0_TO()` | takeoff-config ΔCD0 (gear-down row) | [metabook §4.11 config increment] |
| `get_Delta_CD0_L()` | landing-config ΔCD0 (gear-down row) | [metabook §4.11 config increment] |

`get_config_polar` accepts the six config strings `clean`, `takeoff_flaps_gear_up`,
`takeoff_flaps_gear_down`, `landing_flaps_gear_up`, `landing_flaps_gear_down`, `approach` — the set
`AerodynamicsBase.get_config_polar` validates. The `get_CLmax_TO/_L` + `get_Delta_CD0_TO/_L` wrappers let the
B777 also work with the MILITARY Takeoff/Landing constraints and the mission, even though the FAR-25
path prefers `get_config_polar`. Takeoff ⇒ gear-down takeoff config; Landing ⇒ gear-down landing.

### 4.1 Private toolbox-lookup helpers (mirror `F16AeroL1`'s `roskam_*`)

The constructor derives the config scalars through private helpers that read the shared read-only
toolbox tables, mirroring `F16AeroL1`'s private `roskam_Delta_CD0` / `roskam_e_osw` / `roskam_CLmax`.
The only difference from F16 is the range statistic and the Cfe translation:

| Helper (outline) | Reads | Statistic | Source |
|---|---|---|---|
| `roskam_Delta_CD0_upper(flapconfig)` | `AeroL1.Delta_CD0` ΔCD0 column | `max(row.Delta_CD0{1})` (UPPER, vs F16's `mean`) | [Roskam Table 3.6] |
| `roskam_e_osw_upper(flapconfig)` | `AeroL1.Delta_CD0` e_osw column | `max(row.e_osw{1})` (UPPER, vs F16's `mean`) | [Roskam Table 3.6] |
| `cfe_from_category(aircraft_category)` | `AeroL2.lookup_Cfe` | translate `jet_transport → civil_transport`, then look up | [Raymer Table 12.3] |

`Delta_CD0_config` / `e_config` are then assembled from `roskam_*_upper` per the 6→4 map (§2.1);
`Cfe` = `cfe_from_category(aircraft_category)` = 0.0026; `e_clean` = `roskam_e_osw_upper("clean")` =
0.85. `CLmax_config` comes from the three `CLmax_*` JSON overrides (approach = 0.85·`CLmax_landing`).
No edit to `AeroL1.m` / `AeroL2.m` — both are read as shared Constants/statics.

### As-built values (baseline S_ref = 4605, AR = 9.8)

Clean polar:

| Quantity | Value | Source |
|---|---|---|
| `CD0_clean` | **0.01597** = `0.0026·(28291/4605)` | [metabook Eq. 4.8/4.58 = Raymer Eq. 12.23] |
| `K1_clean` | **0.03821** = `1/(π·9.8·0.85)` | [metabook Eq. 2.10 = Raymer Eq. 12.50] |
| `K2` | 0 | uncambered-basis |

`K1_clean = 0.03821` is the value the current `e_clean = 0.85` input ALREADY produces through
`drag_polar` (this class header documents `K1_clean ~ 0.03821`). It differs from the removed
`config_polars.clean.K1 = 0.03815`, which was computed from the metabook's rounded-up "e implied"
0.8515 — a pre-existing inconsistency in the JSON that the derived path removes. See `b777_L1.md` §3.5.

The five printed metabook polars plus the derived approach polar reproduce from `get_config_polar`
(metabook §4.11, five-polar table, printed p. 44). CD0 reproduces EXACTLY; K1 shifts in the 4th–5th
decimal (derived from the exact Table 3.6 upper-bound e, not the rounded "e implied"):

| config | CD0 | K1 (derived) | K1 (removed JSON) | CLmax | Source |
|---|---|---|---|---|---|
| `clean` | 0.01597 | 0.03821 | 0.03815 | 0.9 | [metabook Eq. 4.44]; CLmax [Roskam Table 3.1] |
| `takeoff_flaps_gear_up` | 0.03597 | 0.04060 | 0.04054 | 2.0 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `takeoff_flaps_gear_down` | 0.06097 | 0.04060 | 0.04054 | 2.0 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `landing_flaps_gear_up` | 0.09097 | 0.04331 | 0.04324 | 2.6 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `landing_flaps_gear_down` | 0.11597 | 0.04331 | 0.04324 | 2.6 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `approach` | 0.08847 | 0.04331 | 0.04324 | 2.21 | DERIVED [metabook §4.11 Climb 6 note] — see §5 |

The config ΔCD0 increments (Roskam Table 3.6 upper bound, §2.1) add to the live clean CD0 (0.01597),
e.g. `+0.020 → 0.03597` (takeoff gear-up), `+0.100 → 0.11597` (landing gear-down).

### Approach polar (derived, not an independent input)

The metabook approximates the balked-landing (Climb 6) approach config as the mean of the takeoff and
landing gear-down CD0, and approach CLmax as 0.85 of landing CLmax [metabook §4.11 Climb 6 note]:

```
CD0_approach   = mean(0.06097, 0.11597) = 0.08847     (equivalently 0.01597 + mean(0.045, 0.100))
CLmax_approach = 0.85 · CLmax_landing = 0.85 · 2.6 = 2.21
K1_approach    = 1/(π·9.8·0.75) = 0.04331    (landing-flaps induced factor)
```

---

## 5. Notes / decisions

- **PHYSICAL CLmax carried** (USER decision 2026-08-14, `b777_L1.md` §3.2): 2.0 both takeoff configs,
  2.6 both landing, 0.9 clean, 2.21 approach. The table above carries these PHYSICAL values so the
  takeoff/landing FIELD-LENGTH constraints reproduce metabook Eqs. 4.46/4.48.
- **D1 / D2 are the comparison report's concern, NOT hardcoded here.** The metabook printed climb
  Eqs. 4.49–4.51 use `CLmax = 2.2` in the takeoff-config slot (D1) and Eq. 4.49 uses the gear-UP
  `CD0 = 0.03597` for a gear-down FAR segment (D2). Both are metabook-internal discrepancies, logged
  D1/D2 in `metabook_data.md`, RESOLVED 2026-08-13 in favour of the PRINTED values for worked-example
  parity. They live in the config-polar handling for the comparison report, not in the physical CLmax
  this class carries.
