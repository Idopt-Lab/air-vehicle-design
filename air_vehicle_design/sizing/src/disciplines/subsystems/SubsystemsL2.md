# SubsystemsL2

Level-2 subsystems static toolbox (`classdef SubsystemsL2`, `methods (Static)` plus one constant).
Called as `SubsystemsL2.method(...)`.

L2 is the first tier with real geometry. Everything here is a volume from a shape, plus the fuel-tank
packaging factor.

---

## 1. Constant

| Name | Value | Citation |
|---|---|---|
| `AVIONICS_DENSITY` | `mean([30, 45])` = 37.5 lb/ft^3 | Raymer 6th ed. Ch.11 p.375 |

This is exactly the same as in L1. Intentional.

## 2. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_fuselage_volume_raymer` | `A_top`, `A_side` [ft^2], `L_fus` [ft] | raw fuselage volume [ft^3] | Raymer 6th ed. Eq. 7.14 |
| `compute_envelope_projected_areas` | `L_fus`, `W_max`, `H_max` [ft] | `A_top`, `A_side` [ft^2] | envelope ellipse |
| `compute_wing_fuel_volume_roskam` | `S`, `b`, `tc_r`, `tc_t`, `lambda_w` | wing fuel volume [ft^3] | Roskam Part II Eq. 6.2/6.3, p.153 (Torenbeek Ref.17 Eqn. B-12) |
| `lookup_packaging_factor_nicolai` | `category` | usable fraction of raw volume | Nicolai & Carichner p.210 |
| `fuel_volume_check` | `fuel_vol_required`, `fuel_vol_available` [ft^3] | struct: `available_vol_ft3`, `required_vol_ft3`, `sufficient` | none, a comparison |
| `compute_battery_volume` | `E_required_kWh` | none, always errors | see §5 |

## 3. Equations

**Fuselage raw volume** [Raymer Eq. 7.14]:

$$V_{fus} = \frac{3.4\,A_{top}\,A_{side}}{4\,L_{fus}}$$

**Wing fuel volume** [Roskam Eq. 6.2/6.3], with `tau_w = tc_t / tc_r`:

$$V_{wing} = 0.54\,\frac{S^2}{b}\,(t/c)_r\,\frac{1 + \lambda\sqrt{\tau_w} + \lambda^2\tau_w}{(1 + \lambda)^2}$$

**`tau_w` convention.** Eq. 6.3 defines `tau_w` as tip over root. Roskam Vol. II Eq. 12.1, used by
the geometry discipline, defines `tau` as root over tip, the opposite way. This file follows Eq. 6.3
as printed. Do not "fix" it to match Eq. 12.1: Roskam does not use one consistent `tau` across his
equations.

## 4. Coefficients

Nicolai's fuel-tank packaging factors.

| Category | Factor |
|---|---|
| Integral tank — shallow fuselage | 0.80 |
| Integral tank — deep fuselage | 0.85 |
| Integral tank — wing | 0.75 |
| Bladder tank — fuselage | 0.75 |
| Bladder tank — wing | 0.65 |

Nicolai prints the relation as `tank volume = fuel volume / packaging factor`. This code uses the
reciprocal form, `tank volume x packaging factor =  useable fuel volume`.

## 5. Citation gap

`compute_battery_volume` is not implemented and errors with
`SubsystemsL2:batteryVolumetricDensityNotAvailable`.

Nicolai Table 14.2 p.363 gives batteries at 0.27 kWh/lb, which is **gravimetric** specific energy.
Converting required energy into a volume needs a **volumetric** density (kWh/ft^3) or a pack density
(lb/ft^3), and neither is cited anywhere in this repository. It errors rather than fabricate a
coefficient. `TestSubsystemsL2` guards that it keeps erroring.

## 6. TODOs

| Date | Task|
|---|---|
| 9/15/2026 | Allow users to specify both fuel tank type and location separately |