# F16WeightsL2

F-16A Block 10/15 Level-2 weights. `classdef F16WeightsL2 < WeightsModelL2`; every abstract method is
a one-line delegation into the `WeightsL2` static toolbox.

**L2 is surface-density × area plus fractions:** structural groups use Raymer Table 15.2 psf
coefficients on real areas; engine and all-else use the AE481 metabook §7 fractions.

---

## 1. Constructor

```matlab
prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);
w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g2, prop);
```

`F16WeightsL2(json_path, req_path, geom, prop)` — all four required, no silent default.

| Argument | Guard | Supplies |
|---|---|---|
| `json_path` | text | top-level `aircraft_category` + `.weights.{N_en, W_payload_fixed, W_payload_expendable}` |
| `req_path` | text | `design_mach` — a design *requirement*, not weights spec data, hence the separate file |
| `geom` | `GeometryModelL2` | the four geometry quantities in §3 |
| `prop` | `PropulsionBase` | `prop.T_SL`, `prop.bypass_ratio` for the engine weight |

The `geom` guard is the L2 **enforcer**, not `GeometryBase`: `GeometryModelL2` abstractly declares
all four members L2 weights reads, so a wrong tier fails at **construction** rather than mid-run.

---

## 2. Inputs

7 numeric/string + 2 injected objects.

| Property | Value | Meaning / citation |
|---|---|---|
| `aircraft_category` | `"jet_fighter"` | Selects the Raymer Table 15.2 psf row and the metabook §7 LG fraction |
| `N_en` | 1 | Engine count [T.O. 1F-16A-1 §I]. Not derivable — no propulsion class exposes a count |
| `W_payload_fixed` | 700 lbf | [Brandt `Wt!B4 = Main!O16`] |
| `W_payload_expendable` | 4400 lbf | [Brandt `Wt!B5 = Main!O17`] |
| `W_TO` | `NaN` lbf | Sizing-loop state, mutated in place |
| `W_energy` | `NaN` lbf | Sizing-loop state, set by mission analysis |
| `design_mach` | 2.0 | From `f16a_requirements.json`. Feeds Raymer Eq. 10.10's `M^0.25` |
| `geom`, `prop` | objects | injected collaborators |

## 3. Derived (`Dependent`) — 12

| Property | Source / formula | Value at `W_TO` = 31,377 |
|---|---|---|
| `S_w` | `geom.S_exposed_wing` | 196.2261 ft² |
| `S_ht` | `geom.S_exposed_ht` — **not** `geom.S_ht` = 108 | 49.8473 ft² |
| `S_vt` | `geom.S_exposed_vt` — **not** `geom.S_vt` = 60 | 40.8897 ft² |
| `S_wet_fus` | `geom.get_S_wet_fuselage()` [Roskam Vol. II Eq. 12.3] | 730.3023 ft² |
| `W_en` | `PropL2.engine_weight_AB(prop.T_SL, design_mach, prop.bypass_ratio)` — **uninstalled** [Raymer 7th ed. Eq. 10.10] | 2775.021 lbf |
| `W_en_brandt` | `0.199·prop.T_SL` [Brandt `Wt!B11`] | 4730.230 lbf |
| `W_wings` | `9.0·S_w` [Raymer Table 15.2] | 1766.035 lbf |
| `W_tail` | `4.0·S_ht` / `5.3·S_vt` (struct with `.HT`, `.VT`) | 199.389 / 216.715 lbf |
| `W_fuselage` | `4.8·S_wet_fus` | 3505.451 lbf |
| `W_landing_gear` | `0.033·W_TO` [AE481 metabook §7] | 1035.441 lbf |
| `W_installed_engine` | `1.3·N_en·W_en` | 3607.527 lbf |
| `W_all_else_empty` | `0.17·W_TO` | 5334.090 lbf |

**`W_en_brandt` is report-only and is never summed into `OEW`** — guarded by
`TestWeightsL2.testBrandtEngineAlternateIsNeverSummedIntoOEW`. It doubles as a positive control on
the propulsion DI.

`requireWTO` guards **only** `W_landing_gear` and `W_all_else_empty` — the two that genuinely carry a
gross weight. `W_wings`/`W_tail`/`W_fuselage` are pure area × density and declare their `W_TO`
argument as `~`; guarding them would assert a dependency the formulas do not have. A guard must
encode a real dependency, not a house style.

---

## 4. Methods

| Method | Delegates to | Formula |
|---|---|---|
| `OEW(W_TO)` | `WeightsL2.OEW` | sum of the seven component terms |
| `weight_wing(W_TO)` | `WeightsL2.weight_wing` | `ρ_w·S_w`, 9 lb/ft² |
| `weight_tail(W_TO)` | `WeightsL2.weight_tail` | `4.0·S_ht`, `5.3·S_vt` |
| `weight_fuselage(W_TO)` | `WeightsL2.weight_fuselage` | `4.8·S_wet_fus` |
| `weight_landing_gear(W_TO)` | `WeightsL2.weight_landing_gear` | `f_lg·W_TO` |

**`OEW(W_TO)` recomputes both fraction terms at the passed argument** and must not read the
`W_all_else_empty` / `W_installed_engine` properties, which are pinned to the object's own `W_TO`.
The all-else term was once frozen at `0.17 × 31377` — a Brandt *output* used as a calibration input.
Guards: `testOEWScalesWithItsArgumentNotAFrozenWTO` and
`testOEWDoesNotUnderstateByTheFrozenAllElseAmount` assert
`OEW(45000) − OEW(31377) == (0.17 + 0.033)·13623`.

### Lookup constants

Raymer Table 15.2 psf, from `metabook_data.md`: fighter 9 / 4 / 5.3 / 4.8 (wing / HT / VT /
fuselage); `jet_transport` 10 / 5.5 / 5.5 / 5.0; `general_aviation` 2.5 / 2 / 2 / 1.4.

Metabook §7 fractions: LG `jet_fighter` 0.033, `jet_transport` 0.043; installed-engine 1.3;
all-else 0.17. **These three are not Raymer Table 15.2** — in the repo extract that table is the psf
surface-density table only, and the fractions are a separate unnumbered metabook table.

### As-built values

| Quantity | Value |
|---|---|
| `OEW(31377)` | **15664.648 lbf** (−21.60 % vs Brandt `Wt!B12` 19980.70) |
| `OEW(45000)` | 18430.117 lbf |

Brandt uses 0.034 for the landing-gear fraction where the framework uses the metabook's 0.033;
different models, reported side by side. Brandt's own psf coefficients (6.75 / 5.0 / 6.0 / 6.0) also
differ from Raymer Table 15.2's, and his tail rows use **full** planform areas where Raymer's
definition wants exposed — so those rows are `DEFINITIONAL`, not a divergence.

The OEW-vs-Brandt agreement check lives in `weights_brandt_comparison.{m,json,md}`, not in the unit
tier.

---

## 5. To-dos

| Item | Status |
|---|---|
| **Darshan → Krish, HIGH PRIORITY: cross-check L2 weights.** `OEW` comes out significantly lower than Brandt (15664.65 vs 19980.70, −21.60 %). Note ~2733.68 lbf of that gap is Brandt line items with no framework analog, but that leaves the rest unexplained | open |
| `WeightsL2.LG_fraction('general_aviation') = 0.057` is **uncited** — the metabook extract has no GA landing-gear row | todo §P4-7; in-code TODO |
| `LG_fraction` carries **no `navy_fighter` row** despite the extract having one (0.045) | pinned as a known absence by `testLGFractionHasNoNavyFighterRow` |
| `design_mach` = 2.0 is cited to Brandt; the T.O. operating limit is 2.05, −2.44 % apart. Sensitivity: `W_en` 2775.02 → 2792.20 (+0.62 %) | todo §P4-13 — user to confirm which is the design requirement |
| The metabook is a secondary source citing Raymer, not Raymer itself | in-code `⚠ verify` markers |
