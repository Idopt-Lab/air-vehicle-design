# AeroL1

Level-1 aerodynamics static toolbox (`classdef AeroL1`, `methods (Static)` only). Call as
`AeroL1.method(...)`; not in the inheritance chain. `F16AeroL1` delegates its two contract methods
here. **L1 is geometry-free** — the drag polar is a Mattingly aircraft-type curve, not a
skin-friction/geometry build-up.

## Equations

`CD = CD0(M) + K1(M)·CL² + K2·CL` — Mattingly, *Aircraft Engine Design* 2nd ed., Eq. 2.9.

- `CD0(M)` interpolated by Mach from Mattingly **Fig. 2.10** (fighter "Current" curve).
- `K1(M)`  interpolated by Mach from Mattingly **Fig. 2.11** (fighter "Current" curve).
- `K2 = 0` for the uncambered fighter type (Mattingly §2.3.1). A non-uncambered `design_type` errors
  loudly (the cambered-type `K2 = −2·K″·CL_min` curve fit is not in the repo).
- `CLmax` — type-based lookup, Roskam Vol. I Table 3.1 / 3.3.

## Methods

| Method | Computes |
|---|---|
| `drag_polar(obj, state)` | `{CD0, K1, K2}` via `mattingly_polar` |
| `get_CLmax(obj)` | `lookup_CLmax(obj.aircraft_type)` |
| `mattingly_polar(cd0_m, cd0_v, k1_m, k1_v, M, design_type)` | assembles `{CD0(M), K1(M), K2}` |
| `interp_curve(mach_pts, val_pts, M)` | linear interp, clamped at curve ends (no transonic pole — a tabulated figure is evaluated across the whole Mach range) |
| `mattingly_K2(design_type)` | `0` for `"uncambered"`, else error |
| `lookup_CLmax(aircraft_type)` | Roskam Vol. I Table 3.3 clean CLmax |

Constant tables consumed by `F16AeroL1`'s high-lift/gear delta methods: `CLmax_table` (Roskam
Table 3.1, clean/TO/landing CLmax by type) and `Delta_CD0` (Roskam Table 3.6, flap/gear ΔCD0 and
Oswald-e by config).

## Current limitation

The Mattingly Fig. 2.10/2.11 curves are **placeholder** data (5 AAF worked points from
`mattingly_data.md`, in `f16a_L1.json`, flagged `"_placeholder": true`), not the digitized figures.
`TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` stays red until the real curves replace them.
