# B777WeightsL1

Boeing 777-200LR Level-1 weight estimation — the metabook §4.12.1 Algorithm 2 delta-weight model.
`classdef B777WeightsL1 < WeightsModelL1`. The empty-weight-fraction and Roskam-lower-bound methods
delegate to `WeightsL1` statics; `OEW` implements the metabook §4.12.1 Algorithm 2 model directly (a
B777-example composition of toolbox statics, not a single toolbox equation).

---

## 1. Constructor

```matlab
g1 = B777GeomL1(b777_spec_path(1));
p1 = B777PropL1(b777_spec_path(1));
w1 = B777WeightsL1(b777_spec_path(1), g1, p1);
```

`B777WeightsL1(json_path, geom, prop)` — all three REQUIRED, no silent default. Reads the top-level
`aircraft_category` + the `.weights` baseline block; the baseline tail areas are computed ONCE here
(see §4).

**DEPENDENCY INJECTION.** Geometry and propulsion are INJECTED, not re-read from JSON — the CURRENT
wing/tail areas come from `geom`, the CURRENT thrust from `prop.T_SL` (mirroring `F16WeightsL2`). The
`.weights` block's `T_baseline_per_engine` is the BASELINE ONLY (the fixed reference point of the delta
model), never the current thrust.

---

## 2. Inputs

Plain mutable `properties`, set once by the constructor.

| Property | Value | Unit | Meaning / citation |
|---|---|---|---|
| `aircraft_category` | `"jet_transport"` | — | `WeightsModelL1` contract; selects the Raymer Table 3.1 We/W0 row + the Table 15.2 areal densities [top-level canonical key] |
| `W0_baseline` | 766800 | lbf | design-point MTOW [metabook Table 4.3 / Fig. 4.7] |
| `S_ref_baseline` | 4605 | ft² | design-point wing area [metabook Table 4.3] |
| `T_baseline_per_engine` | 110000 | lbf | design-point per-engine SLS thrust [**_TODO** stand-in; metabook Fig. 4.7 caption total 220000 / 2] |
| `S_ht_baseline` | NaN → computed | ft² | baseline HT area — computed SELF-CONSISTENTLY in the constructor, NOT a JSON input (see §4) |
| `S_vt_baseline` | NaN → computed | ft² | baseline VT area — computed SELF-CONSISTENTLY in the constructor (see §4) |
| `W_TO` | NaN | lbf | candidate gross takeoff weight; STATE, mutated by the sizing loop [`WeightsBase` contract] |
| `W_energy` | NaN | lbf | internal fuel; STATE, set by mission analysis [`WeightsBase` contract] |
| `W_payload_expendable` | 0 | lbf | a transport carries none in this model (all payload is fixed) [`b777_L1.md` §5.3] |
| `W_payload_fixed` | 145000 | lbf | design payload at the range point [**_TODO** order-of-magnitude stand-in; `b777_L1.md` §5.3] |
| `geom` | injected | — | `GeometryBase` — supplies the CURRENT S_ref / S_ht / S_vt live |
| `prop` | injected | — | `PropulsionBase` — supplies the CURRENT T_SL and n_engines for the engine-weight delta |

**Bare abstract weight properties.** `W_TO`, `W_energy`, `W_payload_*` are inherited `WeightsBase`
abstract properties. An abstract property cannot carry `size`/`type` validation, so the concrete
override declares them plainly (`W_TO = NaN` etc.), matching `BrandtWeightAdapter`. `W_TO` and
`W_energy` are deliberately NOT read from JSON — both are sizing-loop / mission STATE.

## 3. Derived

None. `OEW` is a METHOD taking `W_TO` (the `WeightsBase` contract), so it recomputes on every call and
cannot go stale — there is nothing to cache and no `Dependent` block is needed (same as
`WeightsModelL1`'s note).

---

## 4. The OEW delta-weight model [metabook §4.12.1 Algorithm 2]

`OEW(W_TO)` — recomputed every call, no cache. Empty weight is the Raymer Table 3.1 regression at
`W_TO`, plus linear corrections for how far the current wing area, tail areas and engine thrust sit
from the baseline 777-200LR design point:

```
OEW(W_TO) = (We/W0)(W_TO) · W_TO                                   [Raymer Table 3.1]
          + dens_wing · (geom.S_ref − S_ref_baseline)             [Table 15.2 wing 10]
          + dens_HT   · (geom.S_ht  − S_ht_baseline)              [Table 15.2 HT 5.5]
          + dens_VT   · (geom.S_vt  − S_vt_baseline)              [Table 15.2 VT 5.5]
          + n_eng · ( Weng_roskam(prop.T_SL/n_eng)
                    − Weng_roskam(T_baseline_per_engine) )        [Roskam Eqs. 7.13-7.19]
```

with `(We/W0)(W_TO) = Kvs·A·W_TO^C`, jet_transport row `A = 1.02`, `C = −0.06`, `Kvs = 1.00`
[Raymer Table 3.1; `WeightsL1.lookup_coeffs`].

The four deltas read the live injected `geom`/`prop`, so an optimizer mutating `geom.S_ref` or
`prop.T_SL` flows straight through here. The regression term uses the PASSED `W_TO`, not `obj.W_TO`.

**Baseline collapse.** At the BASELINE design point (`W_TO = 766800`, `geom` at `S_ref = 4605` and
baseline tail areas, `prop.T_SL = 220000` → `110000/engine = T_baseline`) ALL FOUR deltas are zero, so
`OEW(766800)` collapses to the pure regression `We = A·W_TO^C · W_TO ≈ 346,898 lbf`.

**Self-consistent baseline tail areas.** `S_ht_baseline` / `S_vt_baseline` are NOT JSON inputs — they
are computed in the constructor from a baseline `B777GeomL1`-equivalent geometry (S_ref/AR/S_wet_rest/
L_fus at the actual 777-200LR design point) sized through `B777TailL1`. This guarantees the baseline
tail delta is exactly zero when `geom`'s tail areas equal the baseline sizing, rather than depending on
a hand-entered baseline that could drift from the tail toolbox.

---

## 5. Methods

| Method | Delegates to / does | Source |
|---|---|---|
| `compute_We_fraction(W_TO, [category])` | `We/W_TO = Kvs·A·W_TO^C`; `category` defaults to `obj.aircraft_category` | [Raymer Table 3.1] |
| `compute_We_roskam(W_TO)` | Roskam log-log minimum empty weight [lbf] — a LOWER BOUND, never summed into OEW | [Roskam Part I Eq. 2.16] |
| `OEW(W_TO)` | metabook §4.12.1 Algorithm 2 delta model — see §4 | [metabook §4.12.1; Raymer Table 3.1 / Table 15.2; Roskam Eqs. 7.13-7.19] |

`OEW`'s areal-density coefficients come from `WeightsL2` statics: `wing_unit_weight` = 10,
`HT_unit_weight` = 5.5, `VT_unit_weight` = 5.5 [Raymer Table 15.2], selected by `aircraft_category`.
The engine-weight delta uses `WeightsL1.engine_weight_roskam` (the Roskam Eqs. 7.13–7.19 sum), with the
CURRENT per-engine thrust `prop.T_SL / n_engines` from the injected prop, NOT the JSON baseline.

### As-built values

| Quantity | Value | Source |
|---|---|---|
| `OEW(766800)` | **≈ 346,898 lbf** (pure regression; all four deltas zero at baseline) | [Raymer Table 3.1: `1.02·766800^(−0.06)·766800`] |

---

## 6. Fidelity caveat (BY DESIGN)

`WeightsL1.engine_weight_roskam` (Roskam Eqs. 7.13–7.19) and `PropL1.tsfc_mattingly_hibpr` (Eq. 10.11)
are metabook-method regressions; both OVERESTIMATE the real GE90 — the Roskam engine-weight sum
overshoots the ≈ 17,300 lb metabook Table 10.1 uninstalled figure. That is a metabook-fidelity choice,
not an error; the comparison report annotates it.

## 7. To-dos

| Item | Guard |
|---|---|
| `W_payload_fixed` = 145,000 lbf is a **_TODO** stand-in — the metabook Example 4.2 does not print a payload | `b777_L1.md` §5.3 / §6 — needs a Boeing 777-200LR payload-range chart |
| `T_baseline_per_engine` = 110,000 lbf is a **_TODO** stand-in (metabook total 220,000 / 2) | `b777_L1.md` §4.1 / §6 — needs a GE / Boeing engine-rating document |
| `engine_weight_roskam` overestimates the real GE90 (Roskam sum vs. ≈ 17,300 lb Table 10.1) | BY DESIGN — comparison report annotates; not a unit-test failure |

---

## 8. Full-design sizing outcome (informational)

Wired through `converge_W0` (mission + weights closure), the L1/L2 B777 model closes at
`converge_W0(220000, 4605) ≈ 701,081 lbf` at the actual-777 design point (T = 220,000 lbf, S = 4605
ft²) — **−8.6 % vs the actual 766,800 lbf** (metabook Table 4.3). The closure sits in the T–S feasible
region, matching the metabook's own feasible-777 Fig. 4.7. This is a comparison-report figure, not a
unit-test target.
