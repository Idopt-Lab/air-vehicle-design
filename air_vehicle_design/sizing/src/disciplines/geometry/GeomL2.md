# GeomL2

Level-2 geometry static toolbox (`classdef GeomL2`, all `methods (Static)`). Called as
`GeomL2.method(...)`; not instantiated and not in the inheritance chain. Concrete classes
(e.g. `F16GeomL2`) inherit from `GeometryModelL2` and delegate to these statics. L2 computes
component-level wetted areas from real planform geometry (exposed areas, thickness ratios,
fuselage envelope, duct dimensions). Geometry has no L3 tier.

## High-level methods (take the concrete object)

| Method | Returns |
|--------|---------|
| `get_S_wet(obj)` | Total: wing + HT + VT + fuselage + duct |
| `get_S_wet_wing(obj)` / `get_S_wet_HT(obj)` / `get_S_wet_VT(obj)` | Surface wetted area via `compute_roskam_planform` |
| `get_S_wet_fuselage(obj)` | Fuselage wetted area via `compute_s_wet_fus_cyl` |
| `get_S_wet_duct(obj)` | Inlet/duct wetted area via `compute_s_wet_duct` |
| `get_S_exposed_wing(obj)` | Passthrough accessor for `obj.S_exposed_wing` |
| `get_S_wet_fuselage_brandt_lowfi(obj)` | Brandt low-fi fuselage alternate |

`get_S_wet` includes the duct term unconditionally; a concrete class with no real duct sets
`D_inlet=D_exit=L_duct=0`, degenerating the frustum to 0 ft^2.

## Low-level methods and their equations

| Method | Formula | Source |
|--------|---------|--------|
| `compute_roskam_planform(S_exp, tc_r, tc_t, lambda)` | `2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))` | Roskam Vol. II, Eq. 12.1 (variable root/tip t/c) |
| `compute_wet_planform(S_exp, tc)` | `S_exp*(1.977 + 0.52*tc)` (uniform t/c) | Brandt F-16A workbook, Geom!B13 |
| `compute_s_wet_fus_cyl(D_fus, L_fus)` | `pi*D*L*(1-2/lambda_f)^(2/3)*(1+1/lambda_f^2)`, `lambda_f=L/D` | Roskam Vol. II, Eq. 12.3 |
| `compute_s_wet_fus_brandt_lowfi(w, h, L)` | `D_avg=(w+h)/2; (5/6)*pi*D_avg*L` | Brandt Geom!B3 ("1/3-cone + 2/3-cylinder") |
| `compute_s_wet_fus_brandt_highfi(frame_x, frame_zchine, frame_z, frame_w, frame_h)` | trapezoidal integration of per-frame perimeter | Brandt Geom!D23 |
| `compute_frame_perimeter(w, h, z_chine, z_center)` | cosine cross-section path length (6 samples/half, mirrored) | Brandt Geom frame model |
| `compute_s_wet_duct(D_inlet, D_exit, L_duct)` | `pi*(r1+r2)*sqrt((r2-r1)^2+L^2)` (frustum lateral area) | Raymer 6th ed., Sec. 7.3 |
| `compute_S_exposed_horizontal(c_root, c_tip, hs, fw)` | exposed area clipped by fuselage half-width, both panels | Brandt; readme_geom.md Sec. 4.3 |
| `compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)` | exposed area clipped by fuselage half-height, single panel | Brandt; readme_geom.md Sec. 4.3 |

## Formula choices and guards
- Wing/HT/VT default to `compute_roskam_planform` (Eq. 12.1); `compute_wet_planform` (Brandt
  uniform-tc) is the special case `tc_r=tc_t` and stays available as a named alternate.
- Fuselage defaults to `compute_s_wet_fus_cyl` (Roskam Eq. 12.3); the two Brandt formulas
  (low-fi, high-fi frame integration) are named alternates.
- `compute_s_wet_fus_cyl` errors (`GeomL2:invalidFinenessRatio`) when `L/D <= 2`, where Eq. 12.3
  is invalid and would otherwise return a complex number.
- `compute_roskam_planform` requires `tc_t` strictly positive (guards the `tc_r/tc_t` division)
  and `lambda` nonnegative.
- `compute_s_wet_fus_brandt_highfi` errors on mismatched per-frame vector lengths.
