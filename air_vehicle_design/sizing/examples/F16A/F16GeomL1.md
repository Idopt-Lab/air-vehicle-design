# F16GeomL1.m — companion doc

Tier-3 concrete class (`classdef F16GeomL1 < GeometryModelL1`). Every abstract method is a
single delegation line to `GeomL1` statics — no equations duplicated here, as designed.

## Methods in this file

| Method | Computes | Citation (delegates to) |
|---|---|---|
| `get_S_ref(obj)` | Returns `obj.S_ref` | none — property accessor |
| `get_S_wet(obj, W_TO)` | Total `S_wet` | `GeomL1.get_S_wet_statistical` → Roskam Vol. I Table 3.5 / Eq. 3.22 (see `GeomL1.md`) |
| `get_S_wet_statistical(obj, W_TO)` | Same as above (duplicate entry point) | same |
| `get_L_fus(obj, W_TO)` | Fuselage length | `GeomL1.get_L_fus` → Raymer 6th ed. Table 6.3 (see `GeomL1.md`) |

## Properties — hardcoded vs. computed status

| Property | Current value | Status | What a later phase should do |
|---|---|---|---|
| `aircraft_category` | `"jet_fighter"` | Hardcoded literal | JSON-loaded input — genuine spec/category classification, not a derivable quantity |
| `S_ref` | `300` ft² | Hardcoded literal, cited `[T.O. 1F-16A-1, Fig. 1-2]` | JSON-loaded input — genuine spec data |
| `S_wet` | `0` (placeholder) | Correctly left at 0 until `get_S_wet(obj, W_TO)` is called; not a hardcoding bug | No change needed — this is the intended pattern (computed on demand, not stored redundantly) |
| `L_fuselage` | `0` (never updated) | **Bug, not a hardcoding issue**: the docstring (`F16GeomL1.m:19`) claims `get_L_fus` "populates" `obj.L_fuselage`, but `get_L_fus` only *returns* a value — it never assigns `obj.L_fuselage = val`. The property stays `0` forever. Flagged independently in `docs/darshan-verification/2026-07-21_steps_01-05_review.md` (`F16GeomL1.m:19,42-44` entry). | Not a documentation-phase fix (no code changes in this phase) — flagging so the next phase's `L_fuselage` handling doesn't inherit this same silent-no-op bug. Currently harmless only because nothing reads `obj.L_fuselage` directly today. |

## Open TODO already in the file
`F16GeomL1.m:20` carries its own `TODO (7/8/2026)`: "Try finding another way of estimating
S_ref, or show a workflow for students to use at L1." Documenting only, not resolving.
