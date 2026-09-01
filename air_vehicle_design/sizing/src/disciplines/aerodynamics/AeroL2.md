# AeroL2

Level-2 aerodynamics static toolbox (`classdef AeroL2`, `methods (Static)` only). Called as
`AeroL2.method(...)`; never instantiated, not in the inheritance chain.

Geometry never reaches this toolbox as an object: the concrete class reads its own `Dependent`
getters and passes scalars in. `dyn_viscosity`, `compute_Re` and `Cf_turbulent` are the single source
of truth for skin friction, shared with the L3 buildup.

A toolbox has no constructor, no inputs and no derived properties.

---

## 1. Methods

| Static | Signature | Returns | Source |
|---|---|---|---|
| `compute_Delta_CL_max_values` | `(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)` | wing CLmax increment | Raymer Eq. 12.21 |
| `lookup_Delta_cl_max_values` | `(liftdevice, config, cp_c)` | section `Delta_cl_max` | Raymer Table 12.2 |
| `flight_regime` | `(M)` | `"subsonic"` / `"transonic"` / `"supersonic"` | §3 constants |
| `oswald_eff` | `(AR, Lambda_LE_deg)` | Oswald span efficiency | Raymer Eq. 12.48 / 12.49 |
| `oswald_eff_brandt` | `(AR, Lambda_LE_deg)` | same, floored at 0.4 | Brandt `Aero!G12` |
| `K1_subsonic` | `(e_osw, AR)` | induced-drag factor | Raymer Eq. 12.50 |
| `K1_supersonic` | `(M, AR, Lambda_LE_deg)` | induced-drag factor | Raymer Eq. 12.51 |
| `K2_value` | `(K1_sub, CL_minD, M)` | polar offset, 0 for `M >= 1` | Brandt `Aero!G17` |
| `lookup_Cfe` | `(aircraft_category)` | equivalent skin friction, 10 rows | Raymer Table 12.3 |
| `CD0_from_Cf` | `(Cf, S_wet, S_ref)` | parasite drag | Raymer Eq. 12.23 |
| `compute_CL_minD` | `(CL_alpha, alpha_L0_deg)` | CL at minimum drag | thin-airfoil relation |
| `CL_alpha` | `(AR, Lambda_c4_deg, M, S_exposed, S_ref, F, Cl_alpha_2D)` | lift slope, 1/rad | Raymer Eq. 12.6 / 12.7 / 12.8 |
| `CLmax_clean` | `(cl_max_2D, Lambda_c4_deg)` | clean maximum lift | Raymer Eq. 12.15 |
| `dyn_viscosity` | `(T_atm_R)` | slug/(ft s) | Sutherland, Raymer §12.3.1 |
| `compute_Re` | `(state, l_ref)` | Reynolds number | Raymer Eq. 12.25 |
| `Cf_turbulent` | `(Re, M)` | compressible flat-plate `Cf` | Raymer Eq. 12.27 |

`compute_Re` takes an `AircraftState`. Allowed: the state is framework-owned with fixed field names.
Only a design object is barred.

`properties (Constant)`: `MACH_SUBSONIC_MAX` 0.95, `MACH_SUPERSONIC_MIN` 1.05.

## 2. Equations

$$C_{D_0} = C_{fe}\,\frac{S_{wet}}{S_{ref}} \qquad
  C_{L_{max}} = 0.9\,c_{l_{max}}\cos\Lambda_{c/4} \qquad
  \Delta C_{L_{max}} = 0.9\,\Delta c_{l_{max}}\frac{S_{flapped}}{S_{ref}}\cos\Lambda_{HL}$$

$$e = 1.78\left(1 - 0.045\,AR^{0.68}\right) - 0.64 \quad (\Lambda_{LE} < 30^\circ) \qquad
  e = 4.61\left(1 - 0.045\,AR^{0.68}\right)\cos^{0.15}\Lambda_{LE} - 3.1 \quad (\ge 30^\circ)$$

$$K_1 = \frac{1}{\pi\,AR\,e} \qquad
  K_1 = \frac{AR\left(M^2 - 1\right)\cos\Lambda_{LE}}{4\,AR\,\beta - 2} \qquad
  K_2 = -2\,K_1\,C_{L_{minD}}$$

$$C_f = \frac{0.455}{\left(\log_{10} Re\right)^{2.58}\left(1 + 0.144 M^2\right)^{0.65}}
  \qquad Re = \frac{\rho V l}{\mu}$$

`CD0_from_Cf` serves both the tabulated `Cfe` estimate and the computed `Cf_turbulent` supersonic
value. No wave-drag term lives here.

`CLmax_clean` ignores LEX and strake vortex lift, so it underpredicts the F-16's real value.

`compute_CL_minD` is `CL_alpha * (-deg2rad(alpha_L0)/2)`, the framework's choice over Brandt's
`Aero!G20` NACA-designation method. An uncambered airfoil gives `CL_minD` = 0, so `K2` = 0.

`lookup_Delta_cl_max_values` scales the printed section value by 0.6 for takeoff, 0.8 for landing.

## 3. Guards

- **Transonic band, `0.95 < M < 1.05`, is not modelled.** Eq. 12.51 has a pole at
  $4\,AR\,\beta = 2$, so $M \approx 1.014$ at $AR = 3$; `MACH_SUPERSONIC_MIN` = 1.05 clears it.
  `flight_regime` is subsonic strictly below 0.95, so 0.95 itself is transonic.
- `K1_supersonic` errors for `M <= 1`: `AeroL2:subsonicMach`.
- `lookup_Cfe` errors on an unlisted category: `AeroL2:unknownAircraftCategory`.
- `lookup_Delta_cl_max_values` errors on an unknown device, but **warns and returns the undiminished
  value** on an unrecognised config: a silent 40 % overestimate against the landing case.
- `CD0_from_Cf` guards `S_ref` positive.
- `CL_alpha` clamps `M` at 0.99. Both optional groups **fail open**: no `Cl_alpha_2D` silently takes
  `eta` = 0.95, so `F16AeroL2.get_CL_alpha` raises `AeroL2:missingClAlpha2D` first.
- `oswald_eff_brandt` is floored at 0.4. `oswald_eff` is not.

## 4. As-built values

At AR 3.0, `Lambda_LE` 40 deg, `Lambda_c4` 32.183178 deg.

| Call | Value |
|---|---|
| `oswald_eff(3.0, 40)` | 0.9086192166 |
| `oswald_eff_brandt(3.0, 40)` | 0.9144335518 |
| `K1_subsonic(0.9086192166, 3.0)` | 0.1167742146 |
| `K1_supersonic(1.6, 3.0, 40)` | 0.2760308993 |
| `lookup_Cfe("jet_fighter")` | 0.0035 |
| `CD0_from_Cf(0.0035, 1466.7730567, 300)` | 0.0171123523 |
| `CLmax_clean(1.2, 32.183178)` | 0.9140575483 |
| `CL_alpha(3.0, 32.183178, 0, [], [], [], 6.016057)` | 3.0364651 |

## 5. To-dos

| Item | Guard |
|---|---|
| `oswald_eff_brandt` is Brandt content in a generic toolbox | `% TODO (8/14/2026)` |
| `dyn_viscosity` is not aerodynamics; `AircraftState` already models the atmosphere | `% Note (8/25/2026)(Casey)` |
| Confirm Raymer Table 12.3 has no rows beyond `lookup_Cfe`'s 10 rows | this doc |
| `lookup_Delta_cl_max_values`'s unrecognised-config path warns and continues | this doc |
| `alpha_L0` unverified | `TestAeroL2.testTODO_AlphaL0Unverified` |
| `cl_max_2D` unverified | `TestAeroL2.testTODO_ClMax2DUnverified` |
| `cl_alpha_2D` unverified | `TestAeroL2.testTODO_ClAlpha2DUnverified` |
