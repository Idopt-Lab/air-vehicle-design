# AeroL2

Level-2 aerodynamics static toolbox (`classdef AeroL2`, `methods (Static)` only). Called as
`AeroL2.method(...)`; never instantiated and not in the inheritance chain. `F16AeroL2` inherits
`AeroModelL2` and delegates here.

L2 is the **geometry-dependent** clean drag polar plus finite-wing lift. Geometry is read from the
injected geometry object through the concrete class's `Dependent` getters.

The skin-friction primitives (`dyn_viscosity`, `compute_Re`, `Cf_turbulent`) are the single source of
truth here and are also called by the L3 buildup.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `drag_polar`, `get_CLmax`, `get_CD0`, `get_CD0_supersonic`, `get_K1`, `get_K2`, `get_e_osw`, `get_CL_alpha` |
| Low-level | `oswald_eff`, `oswald_eff_brandt`, `K1_subsonic`, `K1_supersonic`, `K2_value`, `CL_alpha`, `CLmax_clean`, `CD0_from_Cf`, `compute_CL_minD`, `lookup_Cfe`, `dyn_viscosity`, `compute_Re`, `Cf_turbulent`, `flight_regime` |

## 2. Equations

**Parasite drag** [Raymer 6th ed. Eq. 12.23], with $C_{fe}$ from [Table 12.3] selected by aircraft
category:

$$C_{D_0} = C_{fe}\,\frac{S_{wet}}{S_{ref}}$$

Supersonically the same form is used with the compressible $C_f$ of Eq. 12.27 at the aircraft-level
Reynolds number. There is **no wave-drag term at L2** — that arrives at L3.

**Oswald span efficiency** [Raymer 6th ed. Eq. 12.48 / 12.49]:

$$e = 1.78\left(1 - 0.045\,AR^{0.68}\right) - 0.64
  \qquad \Lambda_{LE} < 30^\circ$$

$$e = 4.61\left(1 - 0.045\,AR^{0.68}\right)\cos^{0.15}\Lambda_{LE} - 3.1
  \qquad \Lambda_{LE} \ge 30^\circ$$

**Induced-drag factor** [Raymer 6th ed. Eq. 12.50 subsonic, Eq. 12.51 supersonic, with
$\beta = \sqrt{M^2 - 1}$]:

$$K_1 = \frac{1}{\pi\,AR\,e} \qquad\qquad
  K_1 = \frac{AR\left(M^2 - 1\right)\cos\Lambda_{LE}}{4\,AR\,\beta - 2}$$

**Camber term** [Brandt Sec. 4.3, Aero!G17], zero supersonically by linearized theory:

$$K_2 = -2\,K_1\,C_{L_{minD}}$$

**Finite-wing lift slope** [Raymer 6th ed. Eq. 12.6], with $\beta$ per Eq. 12.7 and $\eta$ per
Eq. 12.8. Quarter-chord sweep stands in for the max-thickness-line sweep; the optional
$(S_{exposed}/S_{ref})F$ fuselage-lift factor defaults to 1.

**Clean maximum lift** [Raymer 6th ed. Eq. 12.15]:

$$C_{L_{max}} = 0.9\,c_{l_{max}}\cos\Lambda_{c/4}$$

A plain swept-wing relation: it ignores LEX/strake vortex lift, so it underpredicts the F-16's real
whole-aircraft value.

**Skin friction and Reynolds number** [Raymer 6th ed. Eq. 12.27, Eq. 12.25, Sec. 12.3.1]:

$$C_f = \frac{0.455}{\left(\log_{10} Re\right)^{2.58}\left(1 + 0.144 M^2\right)^{0.65}}
  \qquad Re = \frac{\rho V l}{\mu}$$

with $\mu$ from Sutherland's law in English units.

## 3. Transonic band

For $0.95 < M < 1.05$ the polar is **not modelled**: Eq. 12.51 has a pole at $4\,AR\,\beta = 2$, i.e.
$M \approx 1.014$ at $AR = 3$. The band returns `NaN` rather than a singular value.

That `NaN` is caught downstream — both `Both_WbyS_TbyW.required_TW` and `ConstraintAnalysis` refuse
to evaluate rather than propagate it.

## 4. Two things that are not inputs

- **`Cfe`** is the `aircraft_category`-selected Raymer Table 12.3 row, via `lookup_Cfe` — not a JSON
  input. A published table constant is not spec data.
- **`oswald_eff_brandt`** implements Brandt's own correlation [Aero!G12] and exists only for the
  comparison report. `get_e_osw` errors on any `e_method` other than `"official"`.

## 5. To-dos

| Item | Guard |
|---|---|
| `alpha_L0` unverified | `TestAeroL2.testTODO_AlphaL0Unverified` |
| `cl_max_2D` unverified | `TestAeroL2.testTODO_ClMax2DUnverified` |
| `cl_alpha_2D` unverified | `TestAeroL2.testTODO_ClAlpha2DUnverified` |
