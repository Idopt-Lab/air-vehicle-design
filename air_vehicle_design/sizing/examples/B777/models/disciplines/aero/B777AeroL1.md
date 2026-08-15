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

Plain mutable `properties`, set once by the constructor. NO live geometry here (see §3).

| Property | Value | Meaning / citation |
|---|---|---|
| `geom` | injected | geometry object — all live geometry read from it |
| `aircraft_category` | `"jet_transport"` | canonical class flag; read by the mission to pick the transport fixed-fraction row [top-level canonical key] |
| `Cfe` | 0.0026 | equivalent skin-friction coefficient [Raymer Table 12.3 civil transport; metabook Eq. 4.43] |
| `e_clean` | 0.85 | clean-config Oswald efficiency [metabook Table 4.2]; sets the live clean `K1 = 1/(π·AR·e_clean)` |
| `Delta_CD0_config` | derived-once | per-config parasite-drag increment over clean; dictionary config → double |
| `e_config` | derived-once | per-config Oswald efficiency implied by the printed K1 row; dictionary config → double |
| `CLmax_config` | derived-once | per-config max lift (PHYSICAL values); dictionary config → double |

**The three config dictionaries are DERIVED ONCE, not live.** They are computed in the constructor from
the JSON config-polar table plus the baseline `AR`, and stored — they are functions of the JSON inputs
alone (NOT of live geometry), so computing them once is correct. This is the "derive once from inputs"
case, distinct from the live geometry in §3:

```
Delta_CD0_config(cfg) = table.CD0[cfg] − table.CD0[clean]     [metabook §4.11 config increment]
e_config(cfg)         = 1 / (π·AR_baseline·table.K1[cfg])      [metabook Eq. 2.10]
CLmax_config(cfg)     = table.CLmax[cfg]                        [Roskam Table 3.1] — PHYSICAL values
```

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

### As-built values (baseline S_ref = 4605, AR = 9.8)

Clean polar:

| Quantity | Value | Source |
|---|---|---|
| `CD0_clean` | **0.01597** = `0.0026·(28291/4605)` | [metabook Eq. 4.8/4.58 / Eq. 4.44] |
| `K1_clean` | 0.03815 = `1/(π·9.8·0.85)` | [metabook Eq. 2.10] |
| `K2` | 0 | uncambered-basis |

The five printed metabook polars plus the derived approach polar reproduce exactly from
`get_config_polar` (metabook §4.11, five-polar table, printed p. 44):

| config | CD0 | K1 | CLmax | Source |
|---|---|---|---|---|
| `clean` | 0.01597 | 0.03815 | 0.9 | [metabook Eq. 4.44 / five-polar table]; CLmax [Roskam Table 3.1] |
| `takeoff_flaps_gear_up` | 0.03597 | 0.04054 | 2.0 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `takeoff_flaps_gear_down` | 0.06097 | 0.04054 | 2.0 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `landing_flaps_gear_up` | 0.09097 | 0.04324 | 2.6 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `landing_flaps_gear_down` | 0.11597 | 0.04324 | 2.6 | [metabook five-polar table]; CLmax [Roskam Table 3.1] |
| `approach` | 0.08847 | 0.04324 | 2.21 | DERIVED [metabook §4.11 Climb 6 note] — see §5 |

The config ΔCD0 increments add to the live clean CD0 (0.01597), e.g. `+0.020 → 0.03597` (takeoff
gear-up), `+0.100 → 0.11597` (landing gear-down).

### Approach polar (derived, not an independent input)

The metabook approximates the balked-landing (Climb 6) approach config as the mean of the takeoff and
landing gear-down CD0, and approach CLmax as 0.85 of landing CLmax [metabook §4.11 Climb 6 note]:

```
CD0_approach   = mean(0.06097, 0.11597) = 0.08847
CLmax_approach = 0.85 · 2.6 = 2.21
K1_approach    = 0.04324    (landing-flaps induced factor)
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
