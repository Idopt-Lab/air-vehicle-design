# Weights parameter usage

Which weight quantity is produced at which fidelity level, by which function, under what citation —
and the Brandt ground-truth "expected" values the later `weights_brandt_comparison` report will
target. As-built from `src/base/WeightsBase.m`, `src/disciplines/weights/WeightsL{1,2,3}.m` +
`WeightsModelL{1,2,3}.m`, and `examples/F16A/F16WeightsL{1,2,3}.m`. Companions:
`docs/propulsion_parameter_usage.md`, `docs/geometry_parameter_usage.md`.

> **Edition-label caveat:** code + `raymer_data.md` cite **Raymer 6th ed.** (§15.3.1 Eqs. 15.1–15.24,
> book pp.572–573 / PDF pp.602–603; Table 3.1 for L1; Table 15.2 for L2). The Step-2a plan / CLAUDE.md
> reference **Raymer 7th ed.** and the L1 subplan cites **Table 6.1**. Citations here are as-built
> (6th ed.); the edition/table drift is logged in `VnV/BrandtF16A/todo.md` 2026-07-24 §3c.
>
> **Input mechanism:** the weights classes are **not** migrated to the required-JSON-path +
> inputs-vs-`Dependent` pattern. All spec data is hardcoded as no-arg-constructor property defaults;
> there is no `.weights` JSON block yet (that is Step 2b/2c). Abstract "computed" component properties
> are vestigial NaN placeholders (never populated live) — see the companion docs.

## Downstream consumers
`OEW(W_TO)` is the only weights output the constraint analysis / (future) mission + sizing loop read.
The per-component `weight_*` methods are used by the tests and the comparison report. Weights
consumes geometry as **exposed planform / wetted areas** hardcoded as its own inputs — it does not
hold a geometry object **yet**.

> **Correction (2026-07-25).** This line previously read "geometry has no L3". That is **reversed**:
> `GeomL3` / `GeometryModelL3` / `F16GeomL3` exist, are green, and are the **full L3 geometry tier**
> (built 2026-07-24, promoted from weights-only to full in Phase 2 2026-07-25, area-ruled `Amax`
> added in sub-step 2h). **`F16GeomL3` is the object `F16WeightsL3` will be dependency-injected in
> Phase 4** — see `docs/geometry_parameter_usage.md` → "Weights" for the member-by-member `[P4]`
> mapping and `examples/F16A/F16GeomL3.md` §A for the full input/derived table. Three name traps
> must be named explicitly at the DI site (todo 2026-07-24 GeomL3 §5): weights' `D_fus` is the
> Raymer Eq. 15.4 structural **depth** → `geom.H_max_fuselage` = 5.0, **not** the Dependent
> `geom.D_fus` = 6.0 (a Roskam Eq. 12.3 equivalent diameter); and weights' `S_ht`/`S_vt` are
> **exposed** areas → `geom.S_exposed_ht` = 51.1486 / `geom.S_exposed_vt` = 40.8897, **not**
> `geom.S_ht`/`geom.S_vt` = 108/60 (full planform). Note `S_exposed_ht` = 51.1486 is +2.6 % above
> the 49.85 currently hardcoded in weights — an intentional Decision-1 divergence, not an error.
> **No weights re-planning is implied by this correction.**

---

## Part A — Quantity → (level, class/method, citation)

### L1 — statistical empty-weight regressions
| Quantity | Function | Formula | Citation |
|---|---|---|---|
| OEW (central) | `WeightsL1.OEW` → `We_fraction_power_law(Kvs,A,C,W_TO)` | OEW = (Kvs·A·W_TO^C)·W_TO; jet_fighter A=2.34, C=−0.13, Kvs=1.00 | [Raymer 6th ed. Table 3.1] (in-code `⚠verify`; subplan says Table 6.1) |
| W_E (min bound) | `WeightsL1.We_roskam(A,B,W_TO)` | log10(W_E)=(log10(W_TO)−A)/B; jet_fighter A=0.5091, B=0.9505 | [Roskam Airplane Design Part I Eq. 2.16 + Table 2.15] (no repo extract — unpinned) |

### L2 — Raymer Table 15.2 surface-density + AE481 §7 fractions
| Quantity | Function | Formula | Citation |
|---|---|---|---|
| Wing | `WeightsL2.weight_wing` | ρ_w·S_w, ρ_w=9.0 lbf/ft² | [Raymer 6th ed. Table 15.2, fighter] |
| HT | `WeightsL2.weight_tail`.HT | ρ_ht·S_ht, ρ_ht=4.0 | [Raymer 6th ed. Table 15.2] |
| VT | `WeightsL2.weight_tail`.VT | ρ_vt·S_vt, ρ_vt=5.3 | [Raymer 6th ed. Table 15.2] |
| Fuselage | `WeightsL2.weight_fuselage` | ρ_fus·S_wet_fus, ρ_fus=4.8 | [Raymer 6th ed. Table 15.2] |
| Landing gear | `WeightsL2.weight_landing_gear` | f_lg·W_TO, f_lg=**0.033** | [AE481 metabook §7] — **Brandt/subplan use 0.034**, see todo §3c |
| Installed engine | `WeightsL2.weight_installed_engine` | 1.3·N_en·W_en | [AE481 metabook §7] — frozen in constructor (W_TO-independent, OK) |
| All-else-empty | `WeightsL2.weight_all_else_empty` | 0.17·W_TO | [AE481 metabook §7] — **frozen at baseline 31377 → BUG**, see todo §3c |

### L3 — Raymer §15.3.1 fighter component build-up
| Group | Component (Eq.) | Function | Citation | Exponent status |
|---|---|---|---|---|
| Structural | Wing (15.1) | `WeightsL3.wing` | [Raymer 6th ed. Eq. 15.1] | UNVERIFIED (§3a: [verify]+tc_root legibility+sweep-station) |
| Structural | HT (15.2) | `WeightsL3.horizontal_tail` | [Raymer 6th ed. Eq. 15.2] | UNVERIFIED (§3a: image-only, extract [verify]) |
| Structural | VT (15.3) | `WeightsL3.vertical_tail` | [Raymer 6th ed. Eq. 15.3] | UNVERIFIED + CONFLICT (§3a: cos(Λ_vt) −0.323 vs extract −1.0) |
| Structural | Fuselage (15.4) | `WeightsL3.fuselage` | [Raymer 6th ed. Eq. 15.4] | UNVERIFIED (§3a: image-only, extract [verify]) |
| Landing gear | Main (15.5) | `WeightsL3.main_gear` | [Raymer 6th ed. Eq. 15.5] | UNVERIFIED (§3a: L_m^0.973 not in extract) |
| Landing gear | Nose (15.6) | `WeightsL3.nose_gear` | [Raymer 6th ed. Eq. 15.6] | UNVERIFIED (§3a: N_nw^0.525 not in extract) |
| Engine group | Dry engine | vendor data (W_en·N_en) | — (not a §15.3.1 eq) | n/a (spec data) |
| Engine group | Mounts (15.7) | `WeightsL3.engine_mounts` | [Raymer 6th ed. Eq. 15.7] | UNVERIFIED (§3a: image-only, extract [verify]) |
| Engine group | Firewall (15.8) | `WeightsL3.firewall` | [Raymer 6th ed. Eq. 15.8] | **VERIFIED** (extract clean) |
| Engine group | Section (15.9) | `WeightsL3.engine_section` | [Raymer 6th ed. Eq. 15.9] | UNVERIFIED (§3a: extract [verify]) |
| Engine group | Air induction (15.10) | `WeightsL3.air_induction` | [Raymer 6th ed. Eq. 15.10] | UNVERIFIED (§3a: −0.373/1.498 from code) |
| Engine group | Tailpipe (15.11) | `WeightsL3.tailpipe` | [Raymer 6th ed. Eq. 15.11] | **VERIFIED** (extract clean) |
| Engine group | Cooling (15.12) | `WeightsL3.engine_cooling` | [Raymer 6th ed. Eq. 15.12] | **VERIFIED** (extract clean) |
| Engine group | Oil cooling (15.13) | `WeightsL3.oil_cooling` | [Raymer 6th ed. Eq. 15.13] | UNVERIFIED + CONFLICT (§3a: 1.023 vs extract 1.078) |
| Engine group | Controls (15.14) | `WeightsL3.engine_controls` | [Raymer 6th ed. Eq. 15.14] | UNVERIFIED (§3a: 1.008/0.222 not in extract) |
| Engine group | Starter (15.15) | `WeightsL3.starter` | [Raymer 6th ed. Eq. 15.15] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Fuel system (15.16) | `WeightsL3.fuel_system` | [Raymer 6th ed. Eq. 15.16] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Flight controls (15.17) | `WeightsL3.flight_controls` | [Raymer 6th ed. Eq. 15.17] | UNVERIFIED (§3a: N_c^0.127 from code) |
| Systems | Instruments (15.18) | `WeightsL3.instruments` | [Raymer 6th ed. Eq. 15.18] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Hydraulics (15.19) | `WeightsL3.hydraulics` | [Raymer 6th ed. Eq. 15.19] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Electrical (15.20) | `WeightsL3.electrical` | [Raymer 6th ed. Eq. 15.20] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Avionics (15.21) | `WeightsL3.avionics` | [Raymer 6th ed. Eq. 15.21] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Furnishings (15.22) | `WeightsL3.furnishings` | [Raymer 6th ed. Eq. 15.22] | **VERIFIED** (extract clean) |
| Systems | AC/anti-ice (15.23) | `WeightsL3.ac_antiice` | [Raymer 6th ed. Eq. 15.23] | UNVERIFIED (§3a: extract [verify]) |
| Systems | Handling gear (15.24) | `WeightsL3.handling_gear` | [Raymer 6th ed. Eq. 15.24] | **VERIFIED** (extract clean) |

---

## Part B — Brandt ground-truth "expected" values (for the comparison report)

All Brandt values below cited to the VnV/BrandtF16A docs (`readme_wt.md` §8, `GroundTruth/cell-map.md`
Wt sheet, `BrandtWeight.m`) — **never** copied from `tests/disciplines/TestWeights*.m`. W_TO = 31,377 lb.

> **Method mismatch note.** Brandt's structural line-items use a **psf × area** model (Wt!C9:H9,
> coefficients Wt!C7:H7) — closest to the framework's **L2** (Raymer Table 15.2 psf). The framework's
> **L3** uses the Raymer §15.3.1 statistical build-up, which groups mass differently (no separate
> "nacelle" or "strake" line; LG split main/nose; systems as ~9 sub-items). The comparison report maps
> framework groups → Brandt line-items; exact per-component agreement is **not** expected (documented
> ±20–40% scatter). Brandt's own `corrections.xls` recomputes several components with revised psf
> coefficients (see the last column).

### Structural components (Brandt psf × area, Wt C9:H9)
| Component | Framework computed-by | Brandt value (lb) | Brandt Wt!cell | Framework Raymer eq (L3 / L2) | corrections.xls (lb) |
|---|---|---|---|---|---|
| Wing | L3 `weight_wing` / L2 `weight_wing` | 1785.95 | Wt!C9 | Eq. 15.1 / Table 15.2 | 1852.09 (C9) |
| Fuselage | L3 `weight_fuselage` / L2 `weight_fuselage` | 3652.11 | Wt!D9 | Eq. 15.4 / Table 15.2 | 3506.03 (D9) |
| Pitch control (HT/stabilator) | L3 `weight_tail`.HT / L2 `weight_tail`.HT | 648.00 | Wt!E9 | Eq. 15.2 / Table 15.2 | 199.39 (E9) |
| Vertical tail | L3 `weight_tail`.VT / L2 `weight_tail`.VT | 360.00 | Wt!F9 | Eq. 15.3 / Table 15.2 | 245.34 (F9) |
| Nacelles | *(no framework analog)* | 186.82 | Wt!G9 | — (framework has no nacelle-weight component) | 186.82 (G9, unchanged) |
| Strakes | *(no framework analog)* | 90.00 | Wt!H9 | — (not modeled) | 90.00 (H9, unchanged) |
| **Structural subtotal** | — | **6722.87** | Wt!B9 | — | — |

### Engine + systems (Brandt fractions / formulas, Wt B11, B22:B31)
| Component | Framework computed-by | Brandt value (lb) | Brandt Wt!cell | Brandt formula | Framework Raymer eq |
|---|---|---|---|---|---|
| Engine (dry/installed) | L3 engine-group `.engine` | 4730.23 | Wt!B11/B22 | 0.199·T_AB | vendor data (not §15.3.1) |
| Landing gear | L3 `weight_landing_gear` (main+nose) / L2 `weight_landing_gear` | 1066.82 | Wt!B23 | **0.034**·W_TO | Eqs. 15.5+15.6 / 0.033·W_TO (L2) |
| Inlet duct | L3 engine-group `.induction` | 728.60 | Wt!B24 | 3.9·W_nacelles | Eq. 15.10 |
| Flight controls | L3 systems `.flight_ctrl` | 472.44 | Wt!B25 | 0.012·W_TO + (S_LE/S_w)·6.75·200 | Eq. 15.17 |
| Electrical | L3 systems `.electrical` | 533.41 | Wt!B26 | 0.017·W_TO | Eq. 15.20 |
| Hydraulics | L3 systems `.hydraulics` | 367.11 | Wt!B27 | 0.0117·W_TO | Eq. 15.19 |
| ECS / AC-anti-ice | L3 systems `.ac_antiice` | 360.84 | Wt!B28 | 0.0115·W_TO | Eq. 15.23 |
| Other structure | *(distributed in framework)* | 2016.86 | Wt!B29 | 0.30·W_structure | — (no single analog) |
| Avionics | L3 systems `.avionics` | 2541.54 | Wt!B30 | 0.081·W_TO | Eq. 15.21 |
| Armament support | *(no framework analog)* | 440.00 | Wt!B31 | 0.10·exp_payload | — (not modeled) |
| Fuel system, instruments, oil, mounts, firewall, section, tailpipe, cooling, starter, furnishings, handling | L3 groups `.fuel_sys/.instruments/.oil/.mounts/.firewall/.section/.tailpipe/.cooling/.starter/.furnishings/.handling` | *(subsumed in Brandt's fraction items above / not separately tabulated)* | — | (Brandt lumps these into the fraction items) | Eqs. 15.16/15.18/15.13/15.7/15.8/15.9/15.11/15.12/15.15/15.22/15.24 |

### Summary weights (Wt B10, B12, B6, B3)
| Quantity | Framework computed-by | Brandt value (lb) | Brandt Wt!cell | corrections.xls (lb) |
|---|---|---|---|---|
| Airframe (struct + systems, no engine) | — | 15250.47 | Wt!B10 | — |
| **OEW** (airframe + engine) | `OEW(W_TO)` (all levels) | **19980.70** | **Wt!B12** | **19148.08 (corrections.xls Wt!B12)** |
| Fuel (W_TO − payload − OEW) | (mission) | 6296.30 | Wt!B6 | — |
| TOGW | (sizing state) | 31377.00 | Wt!B3 / B38 | — |

### OEW provenance (the 19,148 vs 19,980.70 issue)
- **Comparison-report Expected column = 19,980.70 lb [Brandt Wt!B12]** — the original `Brandt-F16-A.xls`
  OEW, agreed by `readme_wt.md` §8, `cell-map.md:142`, `BrandtWeight.m` (`W_empty=19980.70`), and
  `F16Baseline.m:93` (`[Brandt F-16A.xls Wt!B12]`).
- **Other-source column = 19,148.08 lb [corrections.xls Wt!B12]** — Casey's revised-weight workbook,
  per `F16Baseline.m:136` (corrected variant).
- **The unit tests (`TestWeightsL1.m:117`, `TestWeightsL2.m:79`, `TestWeightsL3.m:203`) assert
  `expected = 19148` but mis-cite it as "Brandt F-16A.xls sheet Wt B12"** — that cell is actually
  19,980.70. Locked user decision: keep 19,148 as the unit-test expected but **re-cite it to
  `corrections.xls`** per `F16Baseline.m`; do not chase the corrections.xls file. Logged in
  `VnV/BrandtF16A/todo.md` 2026-07-24 §3b.

---

## Not consumed / gaps
- Brandt models **nacelles** (Wt!G9), **strakes** (Wt!H9), **armament support** (Wt!B31), and a lumped
  **other structure** (Wt!B29) that have **no direct analog** in the framework's component set —
  known gaps when summing components against Brandt.
- Framework L3 produces per-item engine/systems weights (mounts, firewall, oil, starter, instruments,
  furnishings, handling…) that Brandt does not tabulate separately (Brandt uses W_TO fractions) — so
  those rows compare only at the group/OEW level.
