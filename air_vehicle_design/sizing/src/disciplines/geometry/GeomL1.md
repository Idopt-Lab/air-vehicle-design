# GeomL1

Level-1 geometry static toolbox (`classdef GeomL1`, `methods (Static)` only). Called as
`GeomL1.method(...)`; never instantiated and not in the inheritance chain. Concrete classes such as
`F16GeomL1` inherit `GeometryModelL1` and delegate here.

**L1 is a pure statistical tier**: geometry is estimated from takeoff gross weight and design Mach.
There is no planform.

---

## 1. Role

| Layer | Members |
|---|---|
| Low-level — scalars and strings only | `compute_*` |
| Constants | `lookup_*`, one per `compute_*` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `compute_s_wet_regression(aircraft_category, W_TO)` | total wetted area [ft²] | Roskam Vol. I Table 3.5 |
| `compute_l_fus_regression(aircraft_category, W_TO)` | fuselage length [ft] | Raymer 6th ed. Table 6.3 |
| `compute_AR_eq(aircraft_category, M_max)` | equivalent aspect ratio | Raymer 7th ed. Table 4.1 |
| `lookup_control_surface_fraction(aircraft_category, surface)` | chord fraction $C/c$ | Raymer 7th ed. Table 6.5 |

**Tail sizing is not here.** `size_tail`, `compute_tail_volume_coeffs`,
`lookup_tail_volume_coeffs`, `compute_tail_arm`, `compute_S_HT`, and `compute_S_VT` live in
`src/disciplines/tail_sizing/TailL1.m`. Tail sizing and control-surface sizing are standalone
disciplines. See `src/disciplines/tail_sizing/TailSizing_scribe_plan.md` for the equation record.

## 3. Equations

**Wetted area** — Roskam Vol. I Table 3.5:

$$S_{wet} = 10^{c}\,W_{TO}^{\,d}$$

**Fuselage length** — Raymer 6th ed. Table 6.3:

$$L_{fus} = a\,W_{TO}^{\,C}$$

**Equivalent aspect ratio** — Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row:

$$AR_{eq} = a\,M_{max}^{\,C}$$

## 4. Coefficients

`lookup_swet` — Roskam Vol. I Table 3.5:

| Category | $c$ | $d$ |
|---|---|---|
| `jet_fighter` | −0.1289 | 0.7506 |
| `jet_bomber` | 0.1213 | 0.7306 |
| `transport_jet` | 0.0199 | 0.7531 |
| `business_jet` | 0.2263 | 0.6977 |
| `military_cargo` | −0.0866 | 0.8099 |

The `transport_jet` exponent is `d = 0.7531` per disposition D3 (`metabook_data.md` Eq. 4.9 /
Eq. 4.42). It reproduces the printed `S_wet = 10^0.0199 · 766,800^0.7531 = 28,291 ft²`. The
`jet_fighter` row (the F-16A path) is unaffected.

`lookup_lfus` — Raymer 6th ed. Table 6.3 (ft from lbf):

| Category | $a$ | $C$ |
|---|---|---|
| `jet_fighter` | 0.93 | 0.39 |
| `jet_trainer` | 0.79 | 0.41 |
| `transport_jet` | 0.67 | 0.43 |
| `military_cargo` | 0.23 | 0.50 |

Jet-fighter only: `lookup_AR_eq` $a = 5.416$, $C = -0.6222$; `lookup_control_surface_fraction`
elevator 0.30 (the all-moving-tail row value, not a hinged-elevator fraction), rudder 0.33.

Every lookup errors (`GeomL1:unknownCategory`) for an unlisted category rather than guessing.

## 5. To-dos

| Item | Guard |
|---|---|
| Raymer Table 6.5's jet-fighter row carries **no aileron chord fraction**, so `'aileron'` errors rather than returning a fabricated value | `TestGeomL1.testTODO_AileronFractionNotAvailable` |
