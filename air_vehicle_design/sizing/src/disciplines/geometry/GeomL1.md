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
| High-level — take the concrete object | `get_S_wet_statistical`, `get_L_fus`, `get_AR_eq`, `get_control_surface_fraction` |
| Low-level — scalars and strings only | `compute_*` |
| Constants | `lookup_*`, one per `compute_*` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `get_S_wet_statistical(obj, W_TO)` | total wetted area [ft²] | Roskam Vol. I Table 3.5 |
| `get_L_fus(obj, W_TO)` | fuselage length [ft] | Raymer 6th ed. Table 6.3 |
| `get_AR_eq(obj)` | equivalent aspect ratio | Raymer 7th ed. Table 4.1 |
| `get_control_surface_fraction(obj, surface)` | chord fraction $C/c$ | Raymer 7th ed. Table 6.5 |

**TAIL SIZING — RE-RETIRED 2026-08-05** (RESTORED 2026-08-03, RETIRED 2026-07-28 before that):
`size_tail`, `compute_tail_volume_coeffs`, `lookup_tail_volume_coeffs`, `compute_tail_arm`,
`compute_S_HT`, `compute_S_VT` briefly lived on this toolbox (2026-08-03 through 2026-08-05) under
Casey's 2026-08-03 decision that tail sizing was organizationally part of Geometry. That decision is
reversed again: tail sizing (and control-surface sizing) are back to being their own standalone
objects, so these methods are gone from `GeomL1` a second time and live again in
`src/disciplines/tail_sizing/TailL1.m` (restored verbatim from git history, same bodies/citations as
before the 2026-08-03 absorption — nothing about the equations changed across either move). See
`src/disciplines/tail_sizing/TailSizing_scribe_plan.md` for the historical discrepancy-resolution
record (two competing L1 tail-sizing implementations existed in this repo before 2026-07-28 — the one
that survived is what's implemented in `TailL1.m` today).

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
| `transport_jet` | 0.0199 | 0.7351 |
| `business_jet` | 0.2263 | 0.6977 |
| `military_cargo` | −0.0866 | 0.8099 |

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
