# F-35 Lightning II — Extracted Reference Data

**Source:** F-35 Lightning II Aircraft User Manual (Microsoft Flight Simulator add-on). Based on publicly available information; not officially endorsed by Lockheed Martin. Use as reference data only — treat with appropriate uncertainty for design work.

---

## Geometry & Weights by Variant

| Parameter | F-35A (CTOL) | F-35B (STOVL) | F-35C (CATOBAR) |
|---|---|---|---|
| Length | 50.5 ft (15.4 m) | 50.5 ft (15.4 m) | 50.8 ft (15.5 m) |
| Wingspan | 35 ft (10.7 m) | 35 ft (10.7 m) | 43 ft (13.1 m) |
| Wing Area | 460 ft² (42.7 m²) | 460 ft² (42.7 m²) | 668 ft² (62.1 m²) |
| Empty Weight | 29,098 lb | 32,300 lb | 34,800 lb |
| Internal Fuel | 18,498 lb | 13,326 lb | 19,624 lb |
| Max Takeoff | ~70,000 lb | ~60,000 lb | ~70,000 lb |
| Range | 1,200 nmi | 900 nmi | 1,400 nmi |
| Combat Radius | 613 nmi | 469 nmi | 610 nmi |
| T/W (full fuel) | 0.87 | 0.90 | 0.75 |
| T/W (50% fuel) | 1.07 | 1.04 | 0.91 |
| G-limit | 9g | 7g | — |

Note: Diagram in manual gives slightly different values — F-35A: W_empty=29,036 lb, fuel=18,460 lb; F-35B: W_empty=32,161 lb, fuel=14,003 lb; F-35C: W_empty=32,072 lb, fuel=20,035 lb. Use the table values as primary reference.

F-35C folded wingspan: 31.1 ft

---

## Engine Data

### F135-PW-100 (F-35A and F-35C)
- Type: Afterburning turbofan
- Length: 220 in (559 cm)
- Diameter: 46 in max, 43 in fan inlet
- Dry weight: 3,750 lb (1,700 kg)
- Compressor: 3-stage fan + 6-stage HP
- Turbine: 1-stage HP + 1-stage LP
- Combustor: annular
- Max thrust: 43,000 lbf (AB) / 28,000 lbf (dry intermediate)
- OPR: 28:1
- TSFC (dry): 0.886 lb/hr·lbf (25.0 g/kN·s)
- T/W (dry): 7.47:1
- T/W (wet/AB): 11.467:1

### F135-PW-600 (F-35B only — includes lift fan)
- Type: Afterburning turbofan + shaft-driven lift fan
- Length: 369 in (937.3 cm)
- Diameter: 46 in max, 43 in fan inlet, 53 in lift fan inlet
- Compressor: 3-stage fan + 6-stage HP + 2-stage contra-rotating lift fan
- Turbine: 1-stage HP + 2-stage LP
- Max thrust: 41,000 lbf (AB) / 27,000 lbf (dry intermediate)
- OPR: 28:1 (conventional), 29:1 (powered lift)
- TSFC: ~0.886 lb/(hr·lbf) w/o afterburner

---

## External Payload Weights
- AIM-9X Sidewinder: 200 lb
- AIM-120 AMRAAM: 350 lb
- Centerline gunpod: 550 lb
- GBU-12 laser-guided bomb: 550 lb
- GBU-31 GPS-guided bomb (JDAM): 2,000 lb

---

## Key Variant Differences
- F-35A: only variant with internal gun (GAU-22/A); uses refuel receptacle; lightest/fastest
- F-35B: VTOL capable below 40,600 lb gross weight; smaller internal weapons bay; refuel probe
- F-35C: largest wing for low approach speed; wing folds; catapult launch bar; tail hook; longest range

---

## Derived sizing parameters (useful for framework validation)

F-35A:
- W/S = 29,098 / 460 ≈ 63.3 lb/ft² (empty weight basis; MTOW/S ≈ 152 lb/ft²)
- Fuel fraction ≈ 18,498 / 70,000 ≈ 0.264

F-35C:
- W/S = 34,800 / 668 ≈ 52.1 lb/ft² (empty); MTOW/S ≈ 104.8 lb/ft²
- Larger wing → lower wing loading → better range/lower approach speed

---

# PART II — Aero 481 Design01 / A03 (the DESIGN SOURCE for `examples/Aero481/`)

**This is a SEPARATE data source from Part I above.** Part I is a published flight-sim
manual (a cross-check). **Part II is the actual design provenance** for the framework's
`examples/Aero481/` example: the University of Michigan AEROSP 481 (Fall 2024) starter code by
Max Arnson, `C:\Users\darsh\Downloads\Aero 481 Code\`. Keep the two clearly apart — the
Design01 point (92.2 psf, T/W 1.2) is what the framework reproduces; the published F-35A
point (~143 psf) is only a loud cross-check flag in the comparison report.

**Provenance tag used below:** `[A481 <file>]` = the Aero 481 code location; a primary
textbook re-citation is added where identifiable, else `_TODO — UNCITED`.

> **PROVENANCE, not primary reference.** Design01's own header reads "this is based off of
> the Aero481". Its numbers are a student starter set (Sainristil-team OEW regression, Ian's CD0
> table, a made-up wetted-area rule). Every value carries a `[A481 …]` provenance tag plus a
> primary re-citation where one exists. The Aero 481 code is NOT a primary source.

## II.1 Point-performance design point [A481 +Designs/Design01.m:20-21]

| Quantity | A481 value | Framework value (English) | Primary re-cite |
|---|---|---|---|
| `T/W` design point | 1.2 | 1.2 | `_TODO — UNCITED` (student design choice) |
| `W/S` design point | 450 kgf/m² = 4413.2 N/m² | **92.17 psf** | `_TODO — UNCITED` (student design choice) |

`W/S`: 450·9.807 N/m² ÷ 47.880 (N/m² per psf) = **92.17 psf**. Cross-check: published F-35A
MTOW/S ≈ 143 psf (Part I) — Design01 sizes a LIGHTER-loaded wing; flag loudly.

## II.2 Regressions [A481 +Designs/Design01.m:23-36, +Utility/MetaEngine.m]

| Regression | A481 form | Framework decision | Primary re-cite |
|---|---|---|---|
| OEW fraction | `We/W0 = 0.882·W0[lbm]^-0.055` [Design01.m:26, "Sainristil team"] | keep as fighter OEW-fraction | `_TODO — UNCITED` (Sainristil-team fit; Raymer Table 3.1 `jet_fighter` A=2.34/C=-0.13 is the cited framework alternative, quantify delta in report) |
| Engine weight | `Utility.MetaEngine(T)` [MetaEngine.m] | shared `WeightsL1.engine_weight_roskam(T0)` | **[Roskam Airplane Design Part V, Eqs. 7.13-7.19]** — identical 5-term form (dry 0.521·T^0.9 / oil 0.082·T^0.65 / rev 0.034·T / control 0.26·T^0.5 / start 9.33·(W_dry/1000)^1.078); metabook_data.md Eqs. 7.13-7.19. NOTE: keeps the thrust-reverser term (0.034·T) — a fighter has no reverser; `_TODO` |
| Wetted area | `Swet = 4·S` [Design01.m:36, **"I made this up"**] | **REJECTED** → cited Roskam fighter regression | **[Roskam Vol. I Table 3.5, jet_fighter]** `Swet = 10^-0.1289·W_TO^0.7506` via `GeomL1.lookup_swet('jet_fighter')` — see §II.9 rejection note |

## II.3 Design decisions / payload [A481 +Designs/Design01.m:41-49]

| Quantity | A481 value | Framework value | Primary re-cite |
|---|---|---|---|
| `NoMissiles` (payload multiplier) | 1 | 1 | student choice |
| `WMissile` (expendable payload) | 18,000 lbm | **18,000 lbf** | `_TODO — UNCITED` ("yields f35 payload"); publ. F-35A internal+external stores order-of-magnitude cross-check only |
| `WCrew` | 200 kg | **441 lbf** | `_TODO — UNCITED` (student choice) |
| `NEng` | 1 | 1 (single F135) | Part I (F135-PW-100, single engine) |
| `AR` (aspect ratio) | 4 | 4 | `_TODO — UNCITED` — **published F-35A AR ≈ 2.66** (35 ft span, 460 ft²: 35²/460 = 2.66); Design01's 4 is a student value, flag (§ discrepancy A5) |
| `LD.Cruise` / `LD.Dash` | 12 / 10 | not used (L/D is derived from the polar) | student estimates; superseded by the drag polar |

## II.4 Aerodynamics config tables [A481 +Designs/Design01.m:55-73]

**CLmax by config** (Design01.m:55-61) — spec inputs to `Aero481AeroL1`:

| config | A481 CLmax | maps to framework config |
|---|---|---|
| TO (Climb 1) | 2.0 | `takeoff_flaps_gear_down` |
| TS (Climb 2) | 2.0 | `takeoff_flaps_gear_down` |
| SS (Climb 3) | 1.8 | `takeoff_flaps_gear_up` |
| EN (Climb 4) | 1.8 | `clean` (en-route) |
| BA (Climb 5) | 2.6 | `landing_flaps_gear_down` |
| BO (Climb 6) | 2.6 | `approach` / balked landing |

**CD0 by config** (Design01.m:64-68) — spec inputs; `_TODO — UNCITED` ("thank you Ian"):

| config | A481 CD0 | maps to framework config |
|---|---|---|
| Clean | 0.0236 | `clean` (the constant `get_config_polar("clean")` CD0, read by the CONSTRAINTS) |
| TakeoffGear | 0.0586 | `takeoff_flaps_gear_down` (ΔCD0 = 0.0350 over clean) |
| TakeoffNoGear | 0.0386 | `takeoff_flaps_gear_up` (ΔCD0 = 0.0150) |
| LandingGear | 0.1086 | `landing_flaps_gear_down` (ΔCD0 = 0.0850) |
| LandingNoGear | 0.0886 | `landing_flaps_gear_up` (ΔCD0 = 0.0650) |
| approach (derived) | **0.0836** = mean(0.0586, 0.1086) | `approach` — Climb-6 (BO) mean rule [A481 Climb.m:63] |

`Cf = 0.0035` [Design01.m:73] — **[Raymer Table 12.3, Air Force fighter]** (framework
`AeroL2.lookup_Cfe('jet_fighter')` = 0.0035, exact match). Design01 uses it inside
`CD0 = Cf·Swet/S` in A03's cruise BRE; the framework `drag_polar` reproduces THAT mission
value: `CD0 = Cfe·swet_over_sref = 0.0035·4 = 0.014` (A03's `Swet = 4·S`, so `Swet/S = 4`).
This is INTENTIONALLY distinct from `get_config_polar("clean").CD0 = 0.0236`, the config-table
value the CONSTRAINTS read (Aero 481's own mission-vs-constraint inconsistency, disc A1b —
do NOT reconcile).

## II.5 Oswald efficiency [A481 +Utility/Oswald.m]

`Utility.Oswald(AR) = 1.78·(1-0.045·AR^0.68) - 0.64`, source annotated
`https://calculator.academy/oswald-efficiency-factor-calculator/` [Oswald.m:5].

- At AR=4: e = **0.9344** (corrected 2026-08-15; an earlier 0.9153 was an arithmetic slip corresponding to AR≈4.56 — the formula `1.78·(1−0.045·4^0.68)−0.64 = 0.9344`).
- **This is bit-identical to the framework `AeroL2.oswald_eff(AR, Λ_LE)` low-sweep branch**
  (Λ_LE < 30°), which is **[Raymer 6th ed. Eq. 12.48]** — same `1.78(1-0.045·AR^0.68)-0.64`.
  So the "calculator.academy" formula IS Raymer Eq. 12.48. The framework re-cites it to
  Raymer, and applies the ≥30°-sweep branch (Eq. 12.49) when a wing sweep is supplied. If
  the F-35 Λ_LE is set ≥ 30° the framework value diverges from A481's (which ignores sweep);
  the report quantifies that delta.

## II.6 TSFC [A481 +Designs/Design01.m:78-80]

| Setting | A481 (Imperial 1/hr) | Framework | Primary re-cite |
|---|---|---|---|
| SLS | 0.35 | 0.35 | `_TODO — UNCITED` (Part I F135 dry deck ≈ 0.886 is a DIFFERENT basis — installed cruise) |
| Cruise | 0.65 | 0.65 | `_TODO — UNCITED` |
| Dash | 1.70 | 1.70 | `_TODO — UNCITED` (afterburning) |

A481 converts these to SI via `ConvTSFC(x,'Imp','SI')`; the framework carries them in 1/hr.

## II.7 Engine (F135) — from Part I, wired to `Aero481PropL1`

| Quantity | Value | Source |
|---|---|---|
| `T_SL` (AB / max) | **43,000 lbf** | Part I (F135-PW-100) |
| `T_SL_mil` (dry / intermediate) | **28,000 lbf** | Part I |
| `n_engines` | 1 | Part I; A481 `NEng=1` |
| mil/AB ratio | 28,000/43,000 = **0.6512** | derived; feeds the mil-on-AB lapse scale (§II.10) |

## II.8 DCA mission [A481 +Algorithms/A03.m]

Assumes 35,000 ft (10,668 m) for cruise/dash. Segment fuel fractions [A03.m:24-91]:

| Segment | A481 fraction / method | A03 line | Framework decision |
|---|---|---|---|
| Idle/startup | 0.995 | ff1 | Roskam fighter row (startup 0.990) — SUBSTITUTE cited fraction |
| Takeoff | 0.99 | ff2 | Roskam fighter (takeoff 0.990) |
| Climb | 0.96 | ff3 | Roskam fighter (climb 0.93, mean of Roskam 0.90-0.96) |
| Cruise-out 300 nmi, M0.85 | Breguet range (BRE) | ffcruiseout | physics: Breguet range |
| Dash 100 nmi, M1.6 | Breguet range (AB TSFC) | ffdash | physics: Breguet range, percent_ab 100 |
| CAP endurance 4 hr (240 min) | Breguet endurance | ffcap | physics: Breguet endurance |
| Combat, 2 maneuvers | 0.99·0.99 = 0.9801 | ff4 | 2 combat maneuvers; `_TODO` combat time/condition |
| Cruise-back 400 nmi, M0.85 | Breguet range | ffcruiseback | physics: Breguet range |
| Descent | 0.98 | ffdescent | Roskam fighter (descent 0.990) — SUBSTITUTE |
| Reserve | 0.95 | ffres | reserve 0.05 [A03.m:91] |
| Landing | — (not in A03) | — | Roskam fighter (landing 0.995) — every segment burns fuel |

`Range_c` cruise-out = 300 nmi, cruise-back = 400 nmi, dash = 100 nmi; `E_CAP` = 4·3600 s.
`Vc = 0.85·a`, `Vd = 1.6·a` at 35 kft. **The uncited fixed fractions (0.995/0.99/0.96/0.98)
are SUBSTITUTED with the repo's cited Roskam Table 2.1 fighter row** [Roskam Part I Table 2.1
via `MissionEquations.roskam_fixed_fraction`], per plan Step 4. A03's `LD = 0.94·CL/(CD0+k·CL²)`
uses the made-up `Swet=4·S` inside `CD0 = Cf·Swet/S`; the geometry wetted-area regression
rejects `Swet=4·S` (§II.9), but the MISSION L/D deliberately keeps it — the framework
computes mission L/D from `Aero481AeroL1.drag_polar`, whose clean `CD0 = Cfe·swet_over_sref =
0.0035·4 = 0.014` (A03's `Swet=4·S`), NOT the config-table `CD0.Clean = 0.0236` (which the
constraints read). See disc A1b.

## II.9 The `Swet = 4·S` rejection (record the quote)

Design01.m:33-36:
```
%% Wetted Surface Area Regression
% I made this up
Aircraft.Swet_Fxn = @ (S) 4*S;
```
This is (a) explicitly uncited/"made up", and (b) self-inconsistent — A03.m:60 feeds it wing
area `S`, but its comment line 61 offers to feed it `MTOW` instead, i.e. the author was unsure
whether it is a function of area or weight. **REJECTED.** The F-35 example uses the cited
Roskam Table 3.5 jet-fighter wetted-area regression already in `GeomL1.lookup_swet`
(`Swet = 10^-0.1289·W_TO^0.7506`, on TOGW). Logged as discrepancy A1 in
`examples/Aero481/aero481_discrepancies.md` (and cross-referenced by metabook_data.md D4c).

## II.10 The added thrust lapse (largest deliberate deviation)

**Aero 481 models NO thrust lapse** — every `+Constraints/*` uses installed thrust at altitude
with no `α = T(alt)/T_SL` term. The framework applies a density lapse `α = σ^0.6` on the AB
scale [metabook Eq. 10.9 / `PropL1.sigma_lapse`], plus a mil-on-AB renormalization
`α_mil = 0.6512·σ^0.6` (the `T_SL_mil/T_SL_AB = 28000/43000` ratio, mirroring
`PropL2.get_thrust_lapse_mil_on_AB_scale`). This is the SINGLE LARGEST intentional deviation
from Aero 481; it gets its own section in `aero481_comparison.m`. Logged as discrepancy
A6.

## II.11 Aero 481 driver / algorithms (context only)

`Driver.m`, `TW_WS.m`, `T_S.m` build the constraint (T/W-vs-W/S) diagram, the MTOW contour
grid, and the T-S diagram; `+Algorithms/A01` (weight iteration), `A02` (MTOW at prescribed
T,S — uses `WingDensity = 44 kg/m²` = **9 lb/ft²**, the cited Raymer Table 15.2 fighter wing
density, and `MetaEngine` deltas), `A03` (DCA fuel fraction), `A04` (thrust per constraint at
a given S). These map to the framework's constraint diagram / T-S diagram / sizing loop; they
are context for the studies, not new equations.
