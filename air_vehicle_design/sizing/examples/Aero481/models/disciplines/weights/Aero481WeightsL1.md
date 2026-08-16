# Aero481WeightsL1

F-35A (Aero 481 Design01/A02 provenance) Level-1 weights. `classdef Aero481WeightsL1 < WeightsModelL1`;
every equation body reuses a shared `src/` static (`WeightsL1` / `WeightsL2`) -- no equation is
re-derived in the class.

**L1 is the Aero 481 A02 empty-weight DELTA model** [`+Algorithms/A02.m:37-63`]: the Sainristil
empty-weight FRACTION plus two DELTA terms that measure how far the current design sits from the
fixed A481 design point (W/S = 92.17 psf, T/W = 1.2). It is faithful to the design source in the same
way B777 = metabook and F-16 = Brandt.

```
OEW(W_TO) = We_frac(W_TO) * W_TO                              [FRACTION -- Sainristil]
          + rho_w * ( geom.S_ref - W_TO / design_WS_psf )    [WING   delta]
          + ( engine_weight_roskam( prop.T_SL )
            - engine_weight_roskam( design_TW * W_TO ) )      [ENGINE delta -- single engine]
```

Design provenance is the University of Michigan AEROSP 481 (Fall 2024) starter code by Max Arnson
(Design01 / `+Algorithms/A02.m`) -- a design PROVENANCE, not a primary source. Each A481 value carries
an `[A481 ...]` tag; the OEW coefficients, `design_WS_psf` and `design_TW` have no textbook citation
and are marked `_TODO -- UNCITED` (A7). See `examples/Aero481/aero481_scribe_plan.md` section 4 and
`examples/Aero481/aero481_discrepancies.md` (A7, A9).

---

## The self-scaling baselines keep A02 stable

Both A02 delta baselines self-scale with `W_TO`, so each delta stays BOUNDED and OEW does not run away:

- **The WING baseline `W_TO / design_WS_psf`** is the wing area the current `W_TO` wants at the design
  wing loading. The wing delta `rho_w*(S_ref - W_TO/design_WS_psf)` tracks only the deviation of the
  ACTUAL `S_ref` from that area.
- **The ENGINE baseline `design_TW * W_TO`** is the design-T/W-implied thrust. The engine delta
  measures only how far the ACTUAL thrust `prop.T_SL` sits from it.

Verified: `A02(Design01, T_SL = 43000 lbf, S = 50 m^2)` sizes the F-35 to **62,399 lb**.

---

## 1. Constructor and injection

```matlab
g1 = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
p1 = Aero481PropL1(aero481_spec_path(1));
w1 = Aero481WeightsL1(aero481_spec_path(1), g1, p1);
```

`Aero481WeightsL1(json_path, geom, prop)` -- **three arguments**, all required, no silent default.

- `json_path` -- reads the top-level `aircraft_category` and the `.weights` block of `aero481_L1.json`
  (OEW coefficients, `design_WS_psf`, `design_TW`, payload).
- `geom` -- a `GeometryModelL1` subclass (`Aero481GeomL1`). OEW reads `geom.get_S_ref()` LIVE for the
  wing-delta ACTUAL area.
- `prop` -- a `PropulsionBase` subclass (`Aero481PropL1`). OEW reads `prop.T_SL` LIVE for the engine-delta
  ACTUAL thrust.

Both `geom` and `prop` are read **live inside `OEW`** on every call (no cache), so a sizing-loop or
optimizer change to either injected object is reflected on the next `OEW(W_TO)` read. This mirrors the
F-16 L2/L3 weights DI pattern (`geom` supplies areas, `prop` supplies `T_SL`), scaled down to the two
quantities L1's A02 model needs.

---

## 2. Inputs

| Property | Value | Units | Meaning / citation |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | -- | Selects the Raymer Table 15.2 wing areal density (`WeightsL2.wing_unit_weight`), the Raymer Table 3.1 fraction row and the Roskam Table 2.15 row `[aero481_L1.json top-level]` |
| `oew_coeff_a` | 0.882 | -- | Sainristil OEW-fraction leading coefficient `[A481 Design01.m:26]`. **`_TODO -- UNCITED`** (A7) |
| `oew_coeff_c` | -0.055 | -- | Sainristil OEW-fraction exponent `[A481 Design01.m:26]`. **`_TODO -- UNCITED`** (A7) |
| `design_WS_psf` | 92.17 | psf | Design wing loading (= 450 kgf/m^2); wing-delta baseline area = `W_TO/design_WS_psf` `[A481 Design01.m PointPerformance]`. **`_TODO -- UNCITED`** |
| `design_TW` | 1.2 | -- | Design thrust-to-weight; engine-delta baseline thrust = `design_TW*W_TO` `[A481 Design01.m PointPerformance]`. **`_TODO -- UNCITED`** |
| `geom` | injected | -- | `GeometryModelL1` (Aero481GeomL1); supplies `S_ref` via `get_S_ref()` (wing-delta actual area) |
| `prop` | injected | -- | `PropulsionBase` (Aero481PropL1); supplies `T_SL` (engine-delta actual thrust) |
| `W_TO` | `NaN` | lbf | Sizing-loop state, mutated in place; deliberately not read from JSON |
| `W_energy` | `NaN` | lbf | Sizing-loop state, set by mission analysis |
| `W_payload_expendable` | 18000 | lbf | Missiles `[A481 WMissile = 18000 lbm, Design01.m:41-49]`. **`_TODO -- UNCITED`** (student choice) |
| `W_payload_fixed` | 441 | lbf | 200 kg crew `[A481 WCrew, Design01.m]`. **`_TODO -- UNCITED`** (student choice) |

`rho_w` is **not** a stored input: it is looked up live from `aircraft_category` via the shared
`WeightsL2.wing_unit_weight` static (= 9 lbf/ft^2 for `jet_fighter`, `[Raymer 6th ed. Table 15.2]`;
this equals the A481 A02 WingDensity 44 kg/m^2).

Both payload values are **inert** for the OEW build-up (no term reads them). They satisfy the
`WeightsBase` closure `W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable` used by the
sizing loop.

---

## 3. Derived

**None stored.** `OEW`, `compute_We_fraction`, `compute_We_fraction_raymer` and `compute_We_roskam`
are all **methods taking `W_TO`**, not properties: each recomputes per call and cannot go stale.
`OEW` additionally reads `geom.get_S_ref()` and `prop.T_SL` LIVE, so the wing/engine deltas always
reflect the current injected geometry/propulsion state.

---

## 4. Methods -- the OEW build-up

`OEW(W_TO)` is a method (takes `W_TO`, recomputes per call, reads `geom`/`prop` live, never cached):

```
OEW(W_TO) = compute_We_fraction(W_TO) * W_TO                        [FRACTION]
          + rho_w * ( geom.get_S_ref() - W_TO / design_WS_psf )     [WING  delta]
          + ( engine_weight_roskam( prop.T_SL )
            - engine_weight_roskam( design_TW * W_TO ) )            [ENGINE delta]
```

| Term | Formula | Reuses (src/ static) | Citation |
|---|---|---|---|
| FRACTION | `0.882*W0^-0.055 * W0` | `WeightsL1.We_fraction_power_law` (Kvs = 1) | A481 Design01.m:26 Sainristil (`_TODO -- UNCITED`, A7) |
| WING delta | `rho_w*(S_ref - W_TO/design_WS_psf)`, `rho_w = 9` | `WeightsL2.wing_unit_weight` | A481 A02.m:37-63; Raymer 6th ed. Table 15.2 (`rho_w`) |
| ENGINE delta | `Weng(T_SL) - Weng(design_TW*W_TO)`, single engine | `WeightsL1.engine_weight_roskam` | A481 A02.m:37-63; Roskam Eqs. 7.13-7.19 (`Weng`) |

The single-engine assumption (`n = 1`, `[A481 NEng = 1]`) means the engine delta has **no division by
an engine count** -- the actual and baseline engines are each ONE whole `engine_weight_roskam` value.

### Two OEW fractions -- baseline vs framework-cited alternative

- **`compute_We_fraction`** -- the Sainristil curve `We/W0 = 0.882*W0^-0.055`, the FRACTION term of the
  A02 model and the class's official/design-baseline answer. A power law of exactly the
  `WeightsL1.We_fraction_power_law(Kvs, A, C, W_TO)` shape, so it reuses that shared low-level static
  with `Kvs = 1`. The coefficient basis is `W0` in **lbm**, numerically equal to lbf at standard
  gravity, so `W_TO[lbf]` passes straight through (no conversion factor).
- **`compute_We_fraction_raymer`** -- the framework-cited `[Raymer 6th ed. Table 3.1 jet_fighter]`
  curve `We/W0 = 2.34*W0^-0.13`. **Not** the design baseline -- exposed only so the comparison report
  can quantify the Sainristil-vs-Raymer delta.

### Roskam lower bound

`compute_We_roskam` is the `[Roskam Part I Eq. 2.16 + Table 2.15]` jet_fighter log-log **minimum**
empty weight -- an independent lower bound, **never summed into OEW**. Carried only to satisfy the
`WeightsModelL1` contract.

---

## 5. Why the F-35 sizes small (~62.4 klb) -- the negative engine delta

At the F-35 design point the ENGINE delta is strongly **NEGATIVE**. The real F135 (`prop.T_SL =
43,000 lbf`) is far below the design-T/W-implied thrust `design_TW*W_TO` (~74,880 lbf at `W_TO ~ 62k`),
so `engine_weight_roskam(43000) - engine_weight_roskam(74880) < 0` -- a large negative engine credit.
That credit pulls the EFFECTIVE OEW fraction from the bare Sainristil ~0.486 down to ~0.37, which is
exactly why Aero 481 converges the F-35 to ~62,400 lb rather than a much heavier point.

## 6. As-built values (hand-computed; validated with `matlab -batch` by the coordinator)

At the design point **`W_TO = 62,400 lbf`, `S_ref = 538 ft^2`, `T_SL = 43,000 lbf`**:

| Quantity | Value | Note |
|---|---|---|
| `compute_We_fraction(62400)` | 0.48049 | Sainristil fraction (dimensionless) |
| FRACTION term = frac * W_TO | +29,982.5 lbf | bare Sainristil empty weight |
| `rho_w` (`WeightsL2.wing_unit_weight`) | 9.0 lbf/ft^2 | Raymer Table 15.2 jet_fighter |
| wing baseline area = `W_TO/design_WS_psf` | 677.01 ft^2 | self-scaling with W_TO |
| WING delta = `9*(538 - 677.01)` | -1,251.1 lbf | S_ref below the design-W/S area |
| `engine_weight_roskam(43000)` | ~9,375.7 lbf | actual F135 |
| baseline thrust = `design_TW*W_TO` | 74,880 lbf | self-scaling with W_TO |
| `engine_weight_roskam(74880)` | ~15,560 lbf | design-T/W engine |
| ENGINE delta | ~-6,185 lbf | strongly NEGATIVE (F135 far below design thrust) |
| **`OEW(62400)`** | **~22,546 lbf** | FRACTION + WING delta + ENGINE delta |
| effective OEW fraction = OEW / W_TO | **~0.361** | ~0.37, pulled DOWN from ~0.486 by the engine credit |

The bare-Sainristil-vs-effective-fraction gap (~0.486 -> ~0.37) and the Sainristil-vs-Raymer fraction
delta are topics of `aero481_comparison.m`, not unit tests. The unit tier keeps the per-term
build-up identity, the hand power-law value, the sign of the engine delta at the design point, and the
`mustBePositive/mustBeFinite` guards on `W_TO`.

---

## 7. `_TODO -- UNCITED` roll-up

| # | Item | Where | Guard |
|---|---|---|---|
| A7 | OEW coefficients `0.882 / -0.055` (Sainristil) | `oew_coeff_a` / `oew_coeff_c`, `compute_We_fraction` | labelled `testTODO_OEWSainristilCoeffsUncited` -- deliberately red until a primary source is pinned or Raymer Table 3.1 is adopted |
| -- | `design_WS_psf = 92.17` / `design_TW = 1.2` (A481 design point) | inputs, wing/engine delta baselines | student design choices, `_TODO -- UNCITED` |
| -- | `W_payload_expendable = 18000` (missiles) | input | student choice, `_TODO -- UNCITED` |
| -- | `W_payload_fixed = 441` (200 kg crew) | input | student choice, `_TODO -- UNCITED` |
| A9 | thrust-reverser term `0.034*T` kept in `WeightsL1.engine_weight_roskam` | shared static, used by BOTH engine-delta evaluations | labelled `testTODO_ReverserTermForFighter` -- a shared-static caveat; the reverser term cancels almost exactly in the delta (it appears in both `Weng(T_SL)` and `Weng(design_TW*W_TO)`), but it over-counts each absolute engine weight |
