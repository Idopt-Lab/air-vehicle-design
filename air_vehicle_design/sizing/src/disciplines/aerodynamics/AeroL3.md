# AeroL3

Level-3 aerodynamics static toolbox (`classdef AeroL3`, `methods (Static)` only). Call as
`AeroL3.method(...)`; not in the inheritance chain. `F16AeroL3` delegates here.

**L3 is the Raymer component drag build-up.** It replaces L2's equivalent skin friction with a
per-component Reynolds / skin-friction / form-factor sum. The induced terms (K1/K2/e), the shared
skin-friction primitives (`dyn_viscosity`, `compute_Re`, `Cf_turbulent`), and the transonic-band
test all live in `AeroL2` (single source of truth) and are called from here. AeroL3 owns the
build-up-specific primitives: laminar Cf, cutoff Reynolds, form factors, and the component sum.

All component geometry (per-component `S_wet`, reference length, diameter, t/c, max-thickness-line
sweep) is read from the injected geometry object via the student object's getters — the toolbox
never sees a hardcoded geometry number (it reads whatever `obj` exposes).

## Equations

| Quantity | Formula | Source |
|---|---|---|
| CD0 build-up | `Σ_c(Cf_eff·FF·Q·S_wet_c)/S_ref + CD0_misc + CD0_LandP` | Raymer 6th ed. Eq. 12.24 |
| Laminar Cf | `1.328/√Re` | Raymer Eq. 12.26 |
| Turbulent Cf | via `AeroL2.Cf_turbulent` | Raymer Eq. 12.27 |
| Cutoff Re (sub / super) | `38.21(l/k)^1.053` / `44.62(l/k)^1.053·M^1.16` | Raymer Eq. 12.28 / 12.29 |
| Surface form factor | `(1+0.6/x_c_max·tc+100·tc⁴)(1.34·M^0.18·cosΛ_m^0.28)` | Raymer Eq. 12.30 |
| Body form factor | `1+5/f^1.5+f/400` (f≤6) or `1+60/f³+f/400` (f>6), f=L/D | Raymer Eq. 12.31 |

Per-component loop (order wing/HT/VT/fuselage/duct): `re_eff = min(compute_Re, re_cut)`; blend
`cf_eff = f_lam·Cf_lam + (1−f_lam)·Cf_turb`; pick `FF_body` if `is_body_comp` else `FF_surface`.

## Methods

- **High-level:** `drag_polar` (regime switch; transonic → NaN), `get_CD0_buildup`, `get_e_osw`,
  `get_K1`, `get_K2`, `get_CL_alpha`, `get_R_cutoff`, plus thin wrappers `compute_Re`,
  `compute_Cf_lam`, `compute_Cf_turb`, `compute_FF_surface`, `compute_FF_fus`, `compute_Cf`.
- **Low-level (L3-owned):** `Re_cutoff_sub`, `Re_cutoff_sup`, `Cf_laminar`, `FF_surface`, `FF_body`.

## Notes

- **Supersonic wave drag is not here.** It is aircraft-specific: `F16AeroL3` overrides
  `get_CD0_buildup` to add its `compute_CD0_wave` term (Raymer Eqs. 12.44/12.45) for `M ≥ 1.2`.
- **Transonic (1.0 < M < 1.2) is not modeled** — `drag_polar` returns NaN in the `AeroL2`
  transonic band, and no fairing is applied between the subsonic build-up and the M≥1.2 wave-drag
  onset.
