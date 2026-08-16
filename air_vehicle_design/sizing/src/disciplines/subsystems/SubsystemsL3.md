# SubsystemsL3

Level-3 subsystems static toolbox (`classdef SubsystemsL3`, `methods (Static)` only). Called as
`SubsystemsL3.method(...)`; never instantiated and not in the inheritance chain. `F16SubsystemsL3`
inherits `SubsystemsModelL3` and delegates here.

**L3 differs from L2 in exactly one respect**: the fuselage raw-volume term (Raymer Eq. 7.14) is fed
`A_top`/`A_side` from the injected L3 geometry's frame-integrated station table instead of L2's
envelope-ellipse approximation. Every other equation is level-agnostic and is **reused by direct
cross-toolbox call to `SubsystemsL2`**, not duplicated — the same reuse pattern `GeomL3` uses against
`GeomL1`/`GeomL2` (e.g. `GeomL3.size_tail` → `GeomL1.size_tail`).

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object (mostly thin wrappers around `SubsystemsL2`) | `avionics_weight_fraction`, `avionics_density`, `avionics_weight`, `avionics_volume`, `fuel_density`, `fuselage_raw_volume`, `fuselage_usable_fuel_volume`, `wing_fuel_volume`, `fuel_volume`, `fuel_volume_from_weight`, `battery_volume`, `internal_volume`, `fuel_volume_check` |
| Low-level — originates here | `compute_frame_integrated_projected_areas` |

## 2. Methods

| Method | Reuses `SubsystemsL2`? | Notes |
|---|---|---|
| `avionics_weight_fraction/_density/_weight/_volume` | Yes (fully) | Identical equations at every level |
| `fuel_density` | Reuses `SubsystemsL1` (via the same path `SubsystemsL2` uses) | |
| `fuselage_raw_volume` | **No** — own frame-integrated `A_top`/`A_side` | Combination formula (`3.4·A_top·A_side/(4L)`) IS reused from `SubsystemsL2.compute_raymer_fuselage_volume` |
| `fuselage_usable_fuel_volume` | Packaging-factor lookup reused; `fuselage_raw_volume` is L3's own | |
| `wing_fuel_volume` | Yes (fully) — `GeometryModelL3` exposes the same `S_ref`/`b_wing`/`tc_r_wing`/`tc_t_wing`/`lambda_wing` member names as `GeometryModelL2` | |
| `fuel_volume` | **No** — own thin wrapper (`fuselage_usable_fuel_volume(obj) + wing_fuel_volume(obj)`, both this class's own) | Deliberately NOT delegated to `SubsystemsL2.fuel_volume`, which would silently substitute L2's envelope-ellipse fuselage term |
| `fuel_volume_from_weight` | Yes (fully) — same `fuel_density` path | |
| `battery_volume` | Yes (fully, including the error) | Same citation GAP as L2 |
| `internal_volume`, `fuel_volume_check` | Own thin wrappers, built on this class's own `fuel_volume`/`avionics_volume` | Same sum/sufficiency logic as L2 |

## 3. Equations

Every equation is `SubsystemsL2`'s — see `SubsystemsL2.md` §3 for the Raymer Eq. 7.14, Roskam
Eq. 6.2/6.3, and fuel-volume-check formulas. What follows is unique to this tier.

**Frame-integrated projected areas** — trapezoidal integration of `GeomL3`'s per-frame normalized
width/height profile (`frames_normalized`, columns `[x/L, w/W_max, h/H_max]`), rescaled by the
fuselage envelope and integrated against station `x`:

$$A_{top} = \int_0^{L} w(x)\,dx \qquad A_{side} = \int_0^{L} h(x)\,dx$$

A $(x{=}0,\,w{=}0,\,h{=}0)$ nose station is prepended before integrating. No separate textbook
equation number — a definitional trapezoidal integration to obtain the `A_top`/`A_side` quantities
Raymer Eq. 7.14 calls for; the `3.4/(4L)` formula remains the cited Raymer equation.

## 4. Coefficients

None originate here — see `SubsystemsL1.md` §4 (fuel density, avionics weight-fraction range) and
`SubsystemsL2.md` §4 (fuel-tank packaging factor), both reused verbatim.

## 5. To-dos

Same two documented citation gaps as L2 (`SubsystemsL2.md` §5). `battery_volume` reuses
`SubsystemsL2`'s error identically; `F16LandingGearL3.bay_volume` carries its own error
(`F16LandingGearL3:bayVolumeNotAvailable`), so a caller can tell which class's gap fired.
