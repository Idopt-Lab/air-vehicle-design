# F16WeightsL1

F-16A Block 10 Level-1 weight concrete class (`classdef F16WeightsL1 < WeightsModelL1`). Every
abstract method is a single delegation line into the `WeightsL1` static toolbox (statistical
empty-weight regressions); no equations are duplicated here. Trace each method to its `WeightsL1`
static for the cited equation.

> **Edition-label caveat (applies to every weights doc):** in-code and `raymer_data.md` cite
> **Raymer 6th ed.**; the Step-2a plan / CLAUDE.md reference **Raymer 7th ed.** Citations below are
> written as the code has them (6th ed.). The 6th-vs-7th edition + Table 3.1-vs-6.1 drift is logged
> in `VnV/BrandtF16A/todo.md` (2026-07-24 Weights §3c) — user to confirm before implementation.

## Constructor / input mechanism (NOT migrated)
`F16WeightsL1()` — **no-arg constructor**; sets `aircraft_category = 'jet_fighter'`. The weights
classes are **not** on the required-JSON-path + inputs-vs-`Dependent` pattern that `F16GeomL2` /
`F16PropL2` now follow. All spec data is hardcoded as plain property defaults in the classdef; there
is no `.weights` JSON block and no `f16a_spec_path` resolution. (Migration to the JSON + inputs-vs-
`Dependent` split is the later Step 2c implementation task, exactly as propulsion was pre-migration.)

## Property classification (input vs derived)
No `properties (Dependent)` block exists. Everything is a plain, mutable `properties` block. The
inputs below are genuine spec / state data; there are **no live-derived** properties on this class
(L1 OEW is returned by the `OEW` method, not stored on a Dependent getter).

**Inputs** (plain `properties`):
| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `aircraft_category` | `'jet_fighter'` | — | Selects the Raymer Table 3.1 and Roskam Table 2.15 lookup rows. |
| `W_TO` | `NaN` | lbf | Candidate gross takeoff weight; **state variable**, set by the sizing loop (`WeightsBase` contract). |
| `W_energy` | 6296.3 | lbf | Internal fuel weight. [Brandt Wt!B6] |
| `W_payload_expendable` | 0 | lbf | Expendable payload; set by mission profile. [WeightsBase contract] |
| `W_payload_fixed` | 220 | lbf | Fixed equipment + crew. [estimate: 1 pilot + survival gear — not pinned to a repo source] |

## Methods (delegate to `WeightsL1`)
| Method | Delegates to | Computes | Citation | Units |
|---|---|---|---|---|
| `OEW(W_TO)` | `WeightsL1.OEW` → `compute_We_fraction` → `We_fraction_power_law(Kvs,A,C,W_TO)` | OEW = (We/Wto)·W_TO via Raymer power law | [Raymer 6th ed. Table 3.1] | lbf |
| `compute_We_fraction(W_TO[,category])` | `WeightsL1.compute_We_fraction` → `We_fraction_power_law` | We/Wto = Kvs·A·W_TO^C | [Raymer 6th ed. Table 3.1] | — |
| `compute_We_roskam(W_TO)` | `WeightsL1.compute_We_roskam` → `We_roskam(A,B,W_TO)` | log10(W_E) = (log10(W_TO)−A)/B — minimum historical empty weight (lower bound) | [Roskam Airplane Design Part I, Eq. 2.16 + Table 2.15] | lbf |

### Lookup constants
| Lookup | Row used | Values | Citation | Verified? |
|---|---|---|---|---|
| `WeightsL1.lookup_coeffs('jet_fighter')` | jet_fighter | A=2.34, C=−0.13, Kvs=1.00 | [Raymer 6th ed. Table 3.1, via AE481 Metabook Table 3.1] | In-code `⚠ verify against Raymer Table 3.1` (WeightsL1.m:30, :86); other category rows marked `verify`. |
| `WeightsL1.lookup_roskam_coeffs('jet_fighter')` | jet_fighter | A=0.5091, B=0.9505 | [Roskam Airplane Design Part I, Table 2.15, book p.47] | Cited; not independently pinned in a repo extract (no Roskam extract present). |

## Deviations / limitations / TODOs
- **Kvs=1.00 (fixed sweep).** F-16 is fixed-sweep, so Kvs=1.00; the variable-sweep 1.04 factor is
  not exercised. [Raymer Table 3.1]
- **`W_payload_fixed = 220 lbf` is an unpinned estimate** (comment: "1 pilot + survival gear"), not a
  Brandt/T.O. value. Flag for io/implementation to cite or replace.
- **Table 3.1 vs Table 6.1 edition drift.** Code (`WeightsL1.m`) cites Raymer **Table 3.1**; the
  weights subplan (`docs/subplans/05_weights.md`) cites Raymer **Table 6.1** for the same power law.
  Logged in `VnV/BrandtF16A/todo.md` (2026-07-24 §3c) — user to confirm the correct table/edition.
- **Roskam citation not pinned in a repo extract.** No `roskam_data.md` reference extract is present;
  A=0.5091/B=0.9505 rest on the in-code comment only. Not locatable in repo — user to confirm.

## Validation targets (informational — NOT unit-test expecteds)
At W_TO = 31,377 lbf: Raymer power law → OEW ≈ 19,108 lbf; Roskam → W_E_min ≈ 15,660 lbf.
Brandt OEW ground truth = **19,980.70 lbf [Brandt Wt!B12]** (comparison-report Expected); the
`corrections.xls` OEW **19,148.08 lbf** is a labeled other-source column. See
`docs/weights_parameter_usage.md` Part B and `VnV/BrandtF16A/todo.md` (2026-07-24 §3b) for the OEW
provenance decision — the unit tests currently keep 19,148 but mis-cite it as "Brandt Wt!B12".
