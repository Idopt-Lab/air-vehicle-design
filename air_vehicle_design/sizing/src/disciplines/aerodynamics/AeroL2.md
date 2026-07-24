# AeroL2

Level-2 aerodynamics static toolbox (`classdef AeroL2`, `methods (Static)` only). Call as
`AeroL2.method(...)`; not in the inheritance chain. `F16AeroL2` delegates here.

**L2 is the geometry-dependent clean drag polar + finite-wing lift.** All geometry (`S_ref`,
`S_wet`, `AR`, `Lambda_LE_deg`, `Lambda_c4_deg`, `taper`, `L_char`) is read from the injected
geometry object via the student object's getters — this toolbox never sees a hardcoded geometry
number. It is also the single home of the skin-friction primitives (`dyn_viscosity`, `compute_Re`,
`Cf_turbulent`) that the L3 buildup reuses.

## Equations

| Quantity | Formula | Source |
|---|---|---|
| Subsonic clean CD0 | `Cfe·(S_wet/S_ref)` | Raymer 6th ed. Eq. 12.23 / Table 12.3 |
| Supersonic CD0 | `Cf(Re,M)·(S_wet/S_ref)` | Raymer Eq. 12.27 (Cf), Eq. 12.23 (form) |
| Turbulent Cf | `0.455/[(log₁₀Re)^2.58·(1+0.144·M²)^0.65]` | Raymer Eq. 12.27 |
| Reynolds | `ρ·V·l/μ`, μ from Sutherland's law | Raymer Eq. 12.25, §12.3.1 |
| Oswald e (official) | `1.78(1−0.045AR^0.68)−0.64` (Λ<30°) / `4.61(1−0.045AR^0.68)cosΛ^0.15−3.1` (Λ≥30°) | Raymer Eq. 12.48 / 12.49 |
| K1 subsonic | `1/(π·AR·e)` | Raymer Eq. 12.50 |
| K1 supersonic | `AR(M²−1)cosΛ_LE/(4·AR·β−2)`, β=√(M²−1) | Raymer Eq. 12.51 |
| K2 subsonic | `−2·K1·CL_minD`, `CL_minD = CL_alpha·(−α_L0[rad]/2)` | Brandt §4.3 / Aero!G17 |
| K2 supersonic | `0` | linearized theory |
| Lift-curve slope | finite-wing Datcom `CL_alpha` | Raymer Eq. 12.6 (β Eq. 12.7, η Eq. 12.8) |
| Clean CLmax | `0.9·cl_max_2D·cos Λ_c4` | Raymer Eq. 12.15 |

## Methods

- **Contract / high-level:** `drag_polar` (regime switch), `get_CLmax`, `get_e_osw`, `get_CD0`,
  `get_CD0_supersonic`, `get_K1`, `get_K2`, `get_CL_alpha`, `compute_Delta_CL_max_values`,
  `lookup_Delta_cl_max_values`.
- **Low-level:** `flight_regime`, `oswald_eff`, `oswald_eff_brandt`, `K1_subsonic`,
  `K1_supersonic`, `K2_value`, `CD0_from_Cf`, `compute_CL_minD`, `CL_alpha`, `CLmax_clean`,
  `dyn_viscosity`, `compute_Re`, `Cf_turbulent`.

## Transonic band (not modeled)

`flight_regime` splits Mach at the `properties (Constant)` bounds `MACH_SUBSONIC_MAX = 0.95` and
`MACH_SUPERSONIC_MIN = 1.05`. In between, `drag_polar` returns `NaN` with a warning: the Eq. 12.51
supersonic K1 has a pole at `4·AR·β = 2` (M ≈ 1.014 for AR=3), and 1.05 clears it.

## Notes

- **Oswald e — official vs Brandt.** `get_e_osw` returns the official Raymer value (`e_method =
  "official"`; any other value errors). `oswald_eff_brandt` (Brandt Aero!G12, `e0 ≈ 0.914`) is a
  separately-cited alternate for the comparison report only — never what `drag_polar` returns.
- **`CLmax_clean` limitation.** Eq. 12.15 is a plain swept-wing relation; it ignores the F-16's
  leading-edge-extension (strake/LEX) vortex lift, so it gives ≈0.91 where the real whole-aircraft
  CLmax is ≈1.6. No vortex-lift correction is modeled.
- **`CL_alpha`** uses quarter-chord sweep `Λ_c4` as the stand-in for Eq. 12.6's max-thickness-line
  sweep (documented approximation).
