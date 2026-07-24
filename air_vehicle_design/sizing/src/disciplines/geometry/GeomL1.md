# GeomL1

Level-1 geometry static toolbox (`classdef GeomL1`, all `methods (Static)`). Called as
`GeomL1.method(...)`; not instantiated and not in the inheritance chain. Concrete classes
(e.g. `F16GeomL1`) inherit from `GeometryModelL1` and delegate to these statics. L1 is a pure
statistical/regression tier: geometry is estimated from takeoff gross weight and design Mach.

## High-level methods (take the concrete object)

| Method | Returns | Reads |
|--------|---------|-------|
| `get_S_wet_statistical(obj, W_TO)` | Total wetted area | `obj.aircraft_category` |
| `get_L_fus(obj, W_TO)`             | Fuselage length | `obj.aircraft_category` |
| `get_AR_eq(obj)`                   | Equivalent aspect ratio | `obj.aircraft_category`, `obj.M_max` |
| `get_control_surface_fraction(obj, surface)` | Control-surface chord fraction C/c | `obj.aircraft_category` |

## Low-level methods (scalars/strings only) and their equations

| Method | Formula | Source |
|--------|---------|--------|
| `compute_s_wet_regression(cat, W_TO)` | `S_wet = 10^c * W_TO^d` | Roskam, *Airplane Design* Vol. I, Table 3.5 |
| `compute_l_fus_regression(cat, W_TO)` | `L_fus = a * W_TO^C` | Raymer 6th ed., Table 6.3 |
| `compute_AR_eq(cat, M_max)` | `AR_eq = a * M_max^C` | Raymer 7th ed., Table 4.1, "Jet fighter (dogfighter)" row |
| `compute_tail_volume_coeffs(cat, has_rss, has_all_moving_tail)` | base `c_HT`=0.40, `c_VT`=0.07 with corrections (below) | Raymer 7th ed., Table 6.4, "Jet fighter" row |
| `compute_tail_arm(L_fus)` | `L_HT = L_VT = 0.475*L_fus` | Raymer aft-single-engine text rule (midpoint of stated 0.45-0.50 range) |
| `compute_S_HT(c_HT, cbar, S_ref, L_HT)` | `S_HT = c_HT*cbar*S_ref/L_HT` | Raymer 7th ed., Table 6.4 |
| `compute_S_VT(c_VT, b, S_ref, L_VT)` | `S_VT = c_VT*b*S_ref/L_VT` | Raymer 7th ed., Table 6.4 |
| `compute_control_surface_fraction(cat, surface)` | table lookup | Raymer 7th ed., Table 6.5, "Jet fighter" row |

Each `compute_*` delegates to a matching `lookup_*` for its constants.

### Tail-volume text corrections (`compute_tail_volume_coeffs`)
- `has_rss` (active FCS / relaxed static stability): `c_HT, c_VT *= (1 - 0.10)`.
- `has_all_moving_tail` (HT only): `c_HT *= (1 - 0.125)` (midpoint of Raymer's 0.10-0.15 range).
- F-16 (both true): `c_HT = 0.315`, `c_VT = 0.063`.

### Category coverage
- `lookup_swet`: jet_fighter, jet_bomber, transport_jet, business_jet, military_cargo.
- `lookup_lfus`: jet_fighter, jet_trainer, transport_jet, military_cargo.
- `lookup_AR_eq`, `lookup_tail_volume_coeffs`, `lookup_control_surface_fraction`: jet_fighter only.

Every lookup errors explicitly (`GeomL1:unknownCategory`) for an unlisted category rather than
guessing. Control-surface fractions cover elevator (0.30, the all-moving-tail row value) and
rudder (0.33); `'aileron'` errors (`GeomL1:unknownControlSurface`) because Raymer Table 6.5's
"Jet fighter" row does not provide an aileron value, and the code will not fabricate one.
