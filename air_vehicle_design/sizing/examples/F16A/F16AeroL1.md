# F16AeroL1

Tier-3 concrete class (`classdef F16AeroL1 < AeroModelL1`) for the F-16A. Geometry-free: the drag
polar is the Mattingly type-curve, which consumes no geometry, so this class takes **no** geometry
object (contrast `F16AeroL2`/`F16AeroL3`). Every contract method is a one-line delegation to the
`AeroL1` toolbox.

## Construction

`F16AeroL1(json_path)` — the path is **required** (no silent default; a no-arg call errors). Use
`f16a_spec_path(1)`. Reads the `.aerodynamics` block of `f16a_L1.json`:

| Input property | From JSON |
|---|---|
| `aircraft_type` (`"fighter"`) | selects the Roskam CLmax row + the Mattingly fighter curves |
| `design_type` (`"uncambered"`) | `K2 = 0` (Mattingly §2.3.1) |
| `curve` (`"Current"`) | selects the Mattingly Fig. 2.10/2.11 technology arrays |
| `cd0_curve_mach/value`, `k1_curve_mach/value` | the `(mach, value)` breakpoints of the chosen curve |

No geometry properties exist on this class.

## Methods

| Method | Delegates to / does |
|---|---|
| `drag_polar(state)` | `AeroL1.drag_polar` → `{CD0(M), K1(M), K2=0}` from the Mattingly curves |
| `get_CLmax(~)` | `AeroL1.get_CLmax` → `lookup_CLmax(aircraft_type)` = 0.90 (Roskam Table 3.3) |
| `get_Delta_{e_osw,CD0,CLmax}_{TO,L}`, `get_CLmax_{TO,L}` | high-lift/gear increments from the Roskam Table 3.1 / 3.6 constant tables (`AeroL1.CLmax_table`, `AeroL1.Delta_CD0`) via private `roskam_*` helpers |

## Current limitation

The Mattingly curves in `f16a_L1.json` are placeholder data (see `AeroL1.md`); the labeled
`testTODO_MattinglyCurvesArePlaceholder` stays red until they are replaced with the digitized
figures.
