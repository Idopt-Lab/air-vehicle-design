# Aero481AeroL1

F-35A Level-1 aerodynamics — the Aero 481 Design01 tier. `classdef Aero481AeroL1 < AeroModelL1`.
`AeroModelL1` adds no abstract members beyond `AerodynamicsBase`'s `drag_polar` / `get_CLmax`.

**Design provenance:** University of Michigan AEROSP 481 (Fall 2024) Design01 starter code
(`docs/reference_extracts/aero481_data.md` Part II). Design provenance is not a primary source; every
value carries a primary re-cite where one exists and is marked `_TODO — UNCITED` where none does.

This class **combines the two existing L1 aero patterns**:

- **geometry-LIGHT**, like `F16AeroL1` — the constructor takes NO injected geometry object; `AR`
  and `Lambda_LE_deg` are two scalar wing-spec inputs read directly from the `.aerodynamics` JSON
  block.
- **config TABLES**, like `B777AeroL1` — CD0 and CLmax per high-lift config come from the Design01
  config tables (JSON dictionaries), NOT from the Roskam type-curves the F-16 uses.

The clean drag polar (`drag_polar`) uses the **A03 MISSION clean CD0 = `Cf·(Swet/S)` = 0.0035·4 =
0.014** (CONSTANT). This is the value Aero 481's A03 mission burns fuel against: `CD0 = Cf·Swet/S`
with `Swet = 4·S` [A481 Design01.m:36, A03.m:60,65] makes `Swet/S` a constant 4, so
`CD0 = Cfe·swet_over_sref` is S-independent — no geometry injection is needed and CD0 does not track
wing area. This is the equivalent-skin-friction method [metabook Eq. 4.8 = Raymer 6th ed. Eq. 12.23,
`CD0 = Cfe·(Swet/Sref)`].

> **A481 clean-CD0 inconsistency (disc A1b) — preserved, NOT reconciled.** Aero 481 uses TWO
> DIFFERENT clean CD0 values for the F-35, and the framework reproduces BOTH faithfully:
> - the **MISSION (A03)** uses `CD0_clean = Cf·Swet/S = 0.014` [A03.m:60,65] → **`drag_polar`
>   returns 0.014** (the mission reads `drag_polar`);
> - the **CONSTRAINTS (`+Constraints/*`)** instead read the config-table `CD0.Clean = 0.0236`
>   [Design01.m:64] → **`get_config_polar("clean")` returns 0.0236** (the FAR-25 field-length /
>   climb-gradient constraints read `get_config_polar`).
>
> So `drag_polar` clean (0.014) **INTENTIONALLY** differs from `get_config_polar("clean")` (0.0236).
> Do NOT unify the two — the divergence is A481's own mission-vs-constraint inconsistency, faithfully
> carried.

The geometry `Swet = 4·S` regression is separately REJECTED for the geometry wetted-area path (disc
A1, Roskam Table 3.5 used instead); `swet_over_sref = 4` is kept HERE only for A03 mission fidelity.

---

## 1. Constructor

```matlab
a1 = Aero481AeroL1(aero481_spec_path(1));
```

`Aero481AeroL1(json_path)` — required, no silent default. Reads the `.aerodynamics` block: `AR`,
`Lambda_LE_deg`, `Cfe`, `swet_over_sref`, and the `CD0_config` / `CLmax_config` dictionaries. Takes
NO injected geometry object.

`aircraft_category = "jet_fighter"`: the mission analysis reads this off the aero object
(`MissionAnalysisBase`, `isprop(aero,'aircraft_category')`) to select the fighter fixed-fraction
`MissionEquations` row.

---

## 2. Inputs

Plain mutable `properties`, set once by the constructor. NO live geometry (contrast `B777AeroL1`).

| Property | Value | Meaning / citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | canonical top-level class flag; read by the mission [top-level key] |
| `AR` | 4 | wing aspect ratio [A481 Design01.m:49]; **`_TODO — UNCITED`** (publ. F-35A ≈ 2.66, disc A5) |
| `Lambda_LE_deg` | 0 | wing leading-edge sweep [F-35 planform]; **`_TODO — UNCITED`** (0 reproduces A481's sweep-free Oswald, disc A2) |
| `Cfe` | 0.0035 | equivalent skin-friction coefficient [Raymer Table 12.3 Air Force fighter; matches A481 `Cf`]. **USED by `drag_polar`**: clean mission `CD0 = Cfe·swet_over_sref` |
| `swet_over_sref` | 4 | wetted/reference-area ratio Swet/Sref feeding the clean mission `CD0 = Cfe·swet_over_sref = 0.014` [A481 A03.m:60,65; Swet=4·S at Design01.m:36]. **`_TODO — UNCITED`** (A481's "I made this up" Swet=4·S, kept for A03 fidelity; distinct from the REJECTED geometry Swet regression, disc A1b) |
| `CD0_config` | dict (below) | per-config absolute clean-basis CD0 [A481 Design01.m:64-68]; **`_TODO — UNCITED`** ("thank you Ian"). The `clean` row (0.0236) is read by `get_config_polar` for the CONSTRAINTS, NOT by `drag_polar` |
| `CLmax_config` | dict (below) | per-config max lift [A481 Design01.m:55-61]; **`_TODO — UNCITED`** |

Unlike `B777AeroL1`, there is **no derive-once step**: the config dictionaries are pure Design01
tabulated inputs (absolute CD0, not increments off a live geometry-tracking clean), so they are read
verbatim from the JSON via the private `struct_to_dict` helper.

### CD0 config table [A481 Design01.m:64-68]

| config string | CD0 | ΔCD0 over clean | A481 source |
|---|---|---|---|
| `clean` | 0.0236 | 0 | `CD0.Clean` |
| `takeoff_flaps_gear_up` | 0.0386 | 0.0150 | `CD0.TakeoffNoGear` |
| `takeoff_flaps_gear_down` | 0.0586 | 0.0350 | `CD0.TakeoffGear` |
| `landing_flaps_gear_up` | 0.0886 | 0.0650 | `CD0.LandingNoGear` |
| `landing_flaps_gear_down` | 0.1086 | 0.0850 | `CD0.LandingGear` |
| `approach` | **0.0836** = mean(0.0586, 0.1086) | — | DERIVED, Climb-6/BO mean rule [A481 Climb.m:63] |

### CLmax config table [A481 Design01.m:55-61]

| config | CLmax | A481 (Climb) |
|---|---|---|
| `clean` (en-route/EN) | 1.8 | `CLmax.EN` |
| `takeoff_flaps_gear_up` (SS) | 1.8 | `CLmax.SS` |
| `takeoff_flaps_gear_down` (TO/TS) | 2.0 | `CLmax.TO`/`.TS` |
| `landing_flaps_gear_up` | 2.6 | `CLmax.BA`-basis |
| `landing_flaps_gear_down` (BA) | 2.6 | `CLmax.BA` |
| `approach` (BO) | 2.6 | `CLmax.BO` |

---

## 3. Methods

| Method | Does | Source |
|---|---|---|
| `drag_polar(~)` | CLEAN MISSION polar `{CD0, K1, K2=0}`. `CD0 = Cfe·swet_over_sref = 0.0035·4 = 0.014` (CONSTANT); `e = AeroL2.oswald_eff(AR, Lambda_LE_deg)`; `K1 = AeroL2.K1_subsonic(e, AR) = 1/(π·AR·e)`; `K2 = 0`. `state` unused (no Mach/altitude dependence). **Read by the MISSION** — intentionally 0.014, NOT the config-table 0.0236 (disc A1b) | CD0 [A481 A03.m:60,65; metabook Eq. 4.8 = Raymer Eq. 12.23]; e [Raymer Eq. 12.48/12.49]; K1 [Raymer Eq. 12.50]; K2 Convention A [Mattingly AED 2nd ed. Eq. 2.9] |
| `get_CLmax(~)` | clean (en-route) max lift = `CLmax_config("clean")` = 1.8 | [A481 Design01.m:59 `CLmax.EN`] |
| `get_config_polar(config)` | `struct(CD0, K1, K2, CLmax)` per config — overrides the `AerodynamicsBase` contract. `CD0 = CD0_config(config)`; `K1 =` live clean K1; `K2 = 0`; `CLmax = CLmax_config(config)`. All six configs share the same live clean K1 (Design01 does not vary induced drag by config). **Read by the CONSTRAINTS** — the `"clean"` row is 0.0236 (config table), intentionally != `drag_polar`'s 0.014 (disc A1b) | CD0/CLmax [A481 Design01.m:55-68]; K1 [Raymer Eq. 12.50] |
| `get_CLmax_TO()` | takeoff-config max lift = `CLmax_config("takeoff_flaps_gear_down")` = 2.0 | [A481 `CLmax.TO`/`.TS`] |
| `get_CLmax_L()` | landing-config max lift = `CLmax_config("landing_flaps_gear_down")` = 2.6 | [A481 `CLmax.BA`] |
| `get_Delta_CD0_TO()` | takeoff gear-down ΔCD0 = `CD0_config(TO gear-down) − CD0_config(clean)` = 0.0350 | [A481 Design01.m:64-68] |
| `get_Delta_CD0_L()` | landing gear-down ΔCD0 = `CD0_config(landing gear-down) − CD0_config(clean)` = 0.0850 | [A481 Design01.m:64-68] |

`get_config_polar` accepts the six config strings `clean`, `takeoff_flaps_gear_up`,
`takeoff_flaps_gear_down`, `landing_flaps_gear_up`, `landing_flaps_gear_down`, `approach` — the set
`AerodynamicsBase.get_config_polar` validates. The `get_CLmax_TO/_L` + `get_Delta_CD0_TO/_L`
wrappers let the F-35 work with the MILITARY Takeoff/Landing constraints and the mission (F-16
pattern), even though the FAR-25 path prefers `get_config_polar`.

---

## 4. Induced-drag factor K1 — equation-based, not frozen (disc A2)

`K1 = 1/(π·AR·e)` with `e = AeroL2.oswald_eff(AR, Lambda_LE_deg)` computed **live** on every read —
Raymer 6th ed. Eq. 12.48 (Λ_LE < 30°) / Eq. 12.49 (Λ_LE ≥ 30°), then Eq. 12.50 for K1. This keeps
K1 optimization-ready: when an optimizer mutates `AR` or `Lambda_LE_deg`, the next `drag_polar`
reflects it. **The frozen `e_clean = 0.9153` field in the JSON is a reader's convenience only — this
class never reads it.**

**The re-cite (disc A2):** Aero 481's `Utility.Oswald(AR) = 1.78·(1−0.045·AR^0.68)−0.64` cites a web
calculator (`calculator.academy`); that formula IS Raymer 6th ed. Eq. 12.48 (the low-sweep branch of
`AeroL2.oswald_eff`). The framework re-cites the A481 Oswald to **[Raymer 6th ed. Eq. 12.48]** and
reuses the shared `AeroL2` static. At Λ_LE < 30° the framework value equals the A481 value (no sweep
correction); if a real F-35 Λ_LE ≥ 30° is supplied, the framework applies Eq. 12.49 (A481 never
does) and the comparison report quantifies the delta.

### NUMERICAL DISCREPANCY — flagged, not reconciled

The scribe plan and input JSON assert `AeroL2.oswald_eff(4, 0) = 0.9153`. **The formula
`1.78·(1−0.045·AR^0.68)−0.64` at AR = 4 actually evaluates to ≈ 0.9344**, not 0.9153:

```
4^0.68        = 2.566834
0.045·2.566834 = 0.115508
1 − 0.115508   = 0.884492
1.78·0.884492  = 1.574395
− 0.64         = 0.934395
```

The documented 0.9153 corresponds to AR ≈ 4.56, not 4 — a transcription error in the F-35 docs
(`aero481_discrepancies.md` A2 and the JSON `e_clean` field). This class computes `e` **live**, so it
uses the correct ≈ 0.9344 and `K1 ≈ 0.08516`. The 0.9153 / `K1 = 0.08694` pairing in the docs must be
corrected; the equation here is correct.

`K2 = 0` (uncambered-basis; no camber / CL_minD data at L1) — Convention A `CD = CD0 + K1·CL² + K2·CL`
[Mattingly AED 2nd ed. Eq. 2.9].

---

## 5. As-built baseline values (AR = 4, Λ_LE = 0°)

Clean MISSION polar (`drag_polar` — read by the mission):

| Quantity | Value | Source |
|---|---|---|
| `CD0` | **0.014** = `Cfe·swet_over_sref` = 0.0035·4 (constant) | [A481 A03.m:60,65; metabook Eq. 4.8 = Raymer Eq. 12.23] |
| `e` | 0.934395 | [Raymer Eq. 12.48, `AeroL2.oswald_eff(4,0)`] |
| `K1` | **0.085165** = `1/(π·4·0.934395)` | [Raymer Eq. 12.50, `AeroL2.K1_subsonic`] |
| `K2` | 0 | uncambered-basis [Mattingly Eq. 2.9] |
| `L/D_max` | **14.48** = `1/(2·√(0.014·0.085165))` | derived |

`get_CLmax` = 1.8; `get_CLmax_TO` = 2.0; `get_CLmax_L` = 2.6.

`get_config_polar` (read by the CONSTRAINTS) reproduces the six Design01 configs from the config
table (CD0 from the table — note the `clean` row is **0.0236**, intentionally != `drag_polar`'s 0.014
per disc A1b — common live K1 = 0.085165, K2 = 0):

| config | CD0 | K1 | CLmax |
|---|---|---|---|
| `clean` | 0.0236 | 0.085165 | 1.8 |
| `takeoff_flaps_gear_up` | 0.0386 | 0.085165 | 1.8 |
| `takeoff_flaps_gear_down` | 0.0586 | 0.085165 | 2.0 |
| `landing_flaps_gear_up` | 0.0886 | 0.085165 | 2.6 |
| `landing_flaps_gear_down` | 0.1086 | 0.085165 | 2.6 |
| `approach` | 0.0836 | 0.085165 | 2.6 |

---

## 6. `_TODO — UNCITED` items carried

Each needs a labelled deliberately-failing `testTODO` guard until a primary source is pinned (the
only expected `run_all_tests` exception, per CLAUDE.md):

| Item | Where | Stand-in | Needs |
|---|---|---|---|
| `AR = 4` (disc A5) | input | Design01 student value | confirm design AR vs publ. ≈ 2.66 |
| `Lambda_LE_deg = 0` (disc A2) | input | unset | F-35 planform document |
| `swet_over_sref = 4` (disc A1b) | input | A481 A03 `Swet=4·S` ("I made this up") | primary Swet/Sref for the mission clean CD0 |
| CD0 config table (0.0236 …) | input | Design01 ("thank you Ian") | primary source |
| CLmax config table (1.8 …) | input | Design01 | primary source |

Plus the **documented `e_clean = 0.9153` numerical error** (§4) — a docs/JSON correction, not a
`testTODO`: a hand-value test must assert `K1 ≈ 0.08516` (the correct live value), which will loudly
fail any expected value transcribed from the wrong 0.9153.

---

## Inheritance

`AerodynamicsBase → AeroModelL1 → Aero481AeroL1`. The `AeroL2` static toolbox (`oswald_eff`,
`K1_subsonic`) is reused cross-tier but is NOT in this inheritance chain.
