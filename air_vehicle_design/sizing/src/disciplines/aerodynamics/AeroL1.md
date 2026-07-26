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
- `CLmax` — type-based lookup, Roskam Vol. I **Table 3.1**, one table throughout (see below).

## Methods

| Method | Computes |
|---|---|
| `drag_polar(obj, state)` | `{CD0, K1, K2}` via `mattingly_polar` |
| `get_CLmax(obj)` | `roskam_CLmax_value(obj.aircraft_category, "CL_max_clean")` — Roskam Table 3.1 |
| `mattingly_polar(cd0_m, cd0_v, k1_m, k1_v, M, design_type)` | assembles `{CD0(M), K1(M), K2}` |
| `interp_curve(mach_pts, val_pts, M)` | linear interp, clamped at curve ends (no transonic pole — a tabulated figure is evaluated across the whole Mach range) |
| `mattingly_K2(design_type)` | `0` for `"uncambered"`, else error |
| `lookup_CLmax(aircraft_type)` | Roskam Vol. I Table 3.3 clean CLmax — **standalone utility, NOT wired into `get_CLmax`** (see below) |

Constant tables consumed by `F16AeroL1`'s high-lift/gear delta methods: `CLmax_table` (Roskam
Table 3.1, clean/TO/landing CLmax by type) and `Delta_CD0` (Roskam Table 3.6, flap/gear ΔCD0 and
Oswald-e by config).

## One table, one provenance (2026-07-25)

`get_CLmax` reads **Table 3.1** — the same table the takeoff/landing increments are differenced
from:

```
get_Delta_CLmax_TO = mean(CL_max_TO) - mean(CL_max_clean)
get_Delta_CLmax_L  = mean(CL_max_L)  - mean(CL_max_clean)
```

Fighter totals are therefore **clean 1.50 / takeoff 1.70 / landing 2.10**, all from Table 3.1.

Previously `get_CLmax` returned Table 3.3's **0.90** while the increments were Table 3.1
differences off a 1.50 clean base, so the totals (0.90 + 0.20 = 1.10 TO, 0.90 + 0.60 = 1.50
landing) belonged to *neither* table. Two unit tests locked each half independently, so nothing
caught the sum. `lookup_CLmax` still implements Table 3.3 and is still tested
(`TestAeroL1.testCLmaxFighterLookup`), but it is deliberately not called by `get_CLmax`.

### The L1↔L2 discontinuity is deliberate

L1 clean CLmax **1.50** vs L2/L3's geometry-based **0.913** (Raymer Eq. 12.15,
`0.9·cl_max_2D·cos Λ_c/4`) is the largest single step in the fidelity ladder, and it reads as a bug
if you meet it without this note. It is not one: 1.50 is the honest size of a *type-only
statistical* estimate — the mean of Roskam's whole fighter column, which is dominated by
straight/moderately-swept wings — applied to a thin, 40°-swept wing that Raymer's geometry method
correctly penalises. The two numbers answer different questions at different fidelities. Neither
is calibrated to the other, and neither should be.

Consequence to expect downstream: the L1 stall, takeoff and landing constraint rows move against
their pre-2026-07-25 values. That fallout is tracked separately and is not chased here.

## Current limitation

The Mattingly Fig. 2.10/2.11 curves are **placeholder** data (5 AAF worked points from
`mattingly_data.md`, in `f16a_L1.json`, flagged `"_placeholder": true`), not the digitized figures.
`TestAeroL1.testTODO_MattinglyCurvesArePlaceholder` stays red until the real curves replace them.
