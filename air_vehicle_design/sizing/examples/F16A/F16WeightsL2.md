# F16WeightsL2

F-16A Block 10 Level-2 weight concrete class (`classdef F16WeightsL2 < WeightsModelL2`). Structural
groups use Raymer Table 15.2 surface-density (psf × area) estimates; engine + all-else use AE481
metabook §7 fractions. Every abstract method is a single delegation line into the `WeightsL2` static
toolbox. See the edition-label caveat in `F16WeightsL1.md` (code cites Raymer 6th ed.).

## Constructor / input mechanism (NOT migrated)
`F16WeightsL2()` — **no-arg constructor** (hardcoded property defaults; no `.weights` JSON, no
`f16a_spec_path`). Not on the required-JSON-path + inputs-vs-`Dependent` pattern. The constructor
does two things:
- `obj.W_installed_engine = WeightsL2.weight_installed_engine(obj)` → 1.3·N_en·W_en = 1.3·1·3030 =
  **3939 lbf** (frozen; W_TO-independent, so freezing is harmless).
- `obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377)` → 0.17·31377 = **5334.09 lbf**
  (frozen at the **baseline** W_TO=31,377, NOT the W_TO passed to `OEW`). **⚠ This is the frozen-under-
  mutation sizing bug — see Deviations.**

## Property classification (input vs derived)
No `properties (Dependent)` block. The abstract-declared "computed" component properties
(`W_wings`, `W_landing_gear`, `W_tail`, `W_fuselage`) are plain properties left at **NaN** and never
populated live — `OEW` recomputes them locally via `weight_wing`/`weight_tail`/… and discards them,
so they are **vestigial placeholders**, not live-derived outputs. `W_installed_engine` /
`W_all_else_empty` are frozen in the constructor (one correctly, one buggily). This is precisely the
stale-under-mutation anti-pattern the inputs-vs-`Dependent` design removes; migration is Step 2c.

**Inputs** (plain `properties`, hardcoded):
| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `aircraft_category` | `'jet_fighter'` | — | Selects Raymer Table 15.2 psf row + AE481 LG fraction. |
| `S_w` | 196.23 | ft² | **Exposed** wing planform area (fuselage-excluded, per Raymer Table 15.2). [Brandt Geom "Exposed S" Wing row; F16Baseline b.geom.S_exposed_wing] |
| `S_ht` | 49.85 | ft² | Exposed HT planform area. [Brandt Geom "Exposed S" Pitch Control Surface row; F16Baseline b.geom.S_exposed_ht] |
| `S_vt` | 40.89 | ft² | Exposed VT planform area. [Brandt Geom "Exposed S" Vertical Tail row; F16Baseline b.geom.S_exposed_vt] |
| `S_wet_fus` | 750 | ft² | Fuselage wetted area. [estimate; "verify TO 1F-16A-1" — not pinned. NB Brandt Geom!B3 = 730.42 ft²] |
| `N_en` | 1 | — | Number of engines. [TO 1F-16A-1] |
| `W_en` | 3030 | lbf | Bare/dry engine weight. [estimate; "verify TO 1F-16A-1 or Jane's" — not pinned] |
| `W_TO` | `NaN` | lbf | Candidate gross weight; state variable set by sizing loop. |
| `W_energy` | 6296.3 | lbf | Internal fuel. [Brandt Wt!B6] |
| `W_payload_expendable` | 0 | lbf | Set by mission profile. |
| `W_payload_fixed` | 220 | lbf | Fixed equipment + crew. [estimate — not pinned] |

**Frozen constructor "derived" (should be Dependent / live):**
| Property | Frozen value | Should be | Citation |
|---|---|---|---|
| `W_installed_engine` | 3939 lbf (=1.3·1·3030) | live from N_en/W_en (harmless: W_TO-independent) | [AE481 metabook §7, installed=1.3×bare] |
| `W_all_else_empty` | 5334.09 lbf (=0.17·**31377**) | **0.17·W_TO (live)** — currently frozen at baseline W_TO → BUG | [AE481 metabook §7, all-else=0.17·W_TO] |

## Methods (delegate to `WeightsL2`)
| Method | Delegates to | Computes | Formula | Citation | Units |
|---|---|---|---|---|---|
| `OEW(W_TO)` | `WeightsL2.OEW` | Σ structural + frozen engine + frozen all-else | W_wing+W_HT+W_VT+W_fus+W_LG+W_installed_engine+W_all_else_empty | [Raymer 6th ed. Table 15.2 + AE481 §7] | lbf |
| `weight_wing(W_TO)` | `WeightsL2.weight_wing` | ρ_w·S_w | 9.0·196.23 = 1766.1 | [Raymer 6th ed. Table 15.2, fighter ρ_w=9 lbf/ft²] | lbf |
| `weight_tail(W_TO)` | `WeightsL2.weight_tail` | ρ_ht·S_ht, ρ_vt·S_vt (struct HT/VT) | 4.0·49.85=199.4; 5.3·40.89=216.7 | [Raymer 6th ed. Table 15.2, ρ_ht=4, ρ_vt=5.3 lbf/ft²] | lbf |
| `weight_fuselage(W_TO)` | `WeightsL2.weight_fuselage` | ρ_fus·S_wet_fus | 4.8·750 = 3600 | [Raymer 6th ed. Table 15.2, ρ_fus=4.8 lbf/ft²] | lbf |
| `weight_landing_gear(W_TO)` | `WeightsL2.weight_landing_gear` | f_lg·W_TO | 0.033·W_TO | [AE481 metabook §7, non-Navy fighter fraction] | lbf |

`W_TO` args on `weight_wing`/`weight_tail`/`weight_fuselage` are ignored (`~`) — those are pure
area·density and do not scale with W_TO. Only `weight_landing_gear` and the (frozen) all-else term
are W_TO-dependent.

## Deviations / limitations / TODOs
- **★ `W_all_else_empty` frozen-at-baseline sizing bug (CODE BUG — flag only, do not fix here).**
  `F16WeightsL2.m:76` freezes `W_all_else_empty = 0.17·31377 = 5334.09 lbf` in the constructor, and
  `WeightsL2.OEW` (`WeightsL2.m:49-50`) reads that frozen property — so `OEW(W_TO)` does **not**
  recompute the 0.17·W_TO term at the passed W_TO. The static `WeightsL2.weight_all_else_empty(obj,
  W_TO)` (`WeightsL2.m:97-101`) computes it correctly but is only ever called once (constructor). Under
  sizing-loop mutation the all-else group is stale. Logged in `VnV/BrandtF16A/todo.md` (2026-07-24
  §3c) for the Step-2c equations-expert.
- **LG fraction 0.033 vs Brandt/subplan 0.034.** `WeightsL2.LG_fraction` uses **0.033** for
  jet_fighter (`WeightsL2.m:171`, cited "AE481 metabook §7"); Brandt Wt!B23 uses **0.034·W_TO**
  (readme_wt §5.11 / cell-map / BrandtWeight.m:219), and the subplan cites 0.034 "Roskam Part I".
  Conflict logged in todo §3c.
- **Table 15.2 ρ coefficients differ from Brandt's own psf coefficients.** Framework uses Raymer
  Table 15.2 (wing 9.0, HT 4.0, VT 5.3, fus 4.8); Brandt Wt!C7:H7 uses 6.75 / 6.0 / 6.0 / 5.0
  (F16Baseline b.brandt.rho_*_model). These are two different psf models — comparison, not error.
- **`S_wet_fus = 750 ft²` and `W_en = 3030 lbf` are unpinned estimates** ("verify TO 1F-16A-1").
  Brandt Geom!B3 fuselage S_wet = 730.42 ft². Flag for io/implementation.

## Validation targets (informational)
L2 component OEW at W_TO=31,377 ≈ within ±20% of Brandt. Brandt OEW = **19,980.70 [Brandt Wt!B12]**
is the comparison Expected; **19,148.08 [corrections.xls Wt!B12]** is the other-source column. The
unit test currently asserts 19,148 mis-cited as "Brandt Wt!B12" — see `docs/weights_parameter_usage.md`
Part B and `VnV/BrandtF16A/todo.md` (2026-07-24 §3b).
