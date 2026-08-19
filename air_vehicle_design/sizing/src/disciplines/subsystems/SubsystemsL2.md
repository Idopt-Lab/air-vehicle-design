# SubsystemsL2

Level-2 subsystems static toolbox (`classdef SubsystemsL2`, `methods (Static)` only). Called as
`SubsystemsL2.method(...)`; never instantiated and not in the inheritance chain. `F16SubsystemsL2`
inherits `SubsystemsModelL2` and delegates here.

**L2 is geometry-derived**: fuselage-internal raw volume off the injected L2 geometry's envelope
ellipse, wing-internal fuel volume off the wing planform, avionics volume off a weight fraction.
Fuel density and the avionics weight-fraction lookup are level-agnostic and are reused directly from
`SubsystemsL1` rather than duplicated.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `avionics_weight_fraction`, `avionics_density`, `avionics_weight`, `avionics_volume`, `fuel_density`, `fuselage_raw_volume`, `fuselage_usable_fuel_volume`, `wing_fuel_volume`, `fuel_volume`, `fuel_volume_from_weight`, `battery_volume`, `internal_volume`, `fuel_volume_check` |
| Low-level — scalars only | `compute_raymer_fuselage_volume`, `compute_envelope_projected_areas`, `compute_wing_fuel_volume`, `lookup_packaging_factor` |

## 2. Methods

| Method | Returns | Source |
|---|---|---|
| `avionics_weight_fraction(obj)` | fraction of `W_empty` | Raymer 6th ed. Table 11.6 (reused from `SubsystemsL1`) |
| `avionics_density(obj)` | 45 lb/ft³ | Nicolai & Carichner Sec.8.1.11, p.210 |
| `avionics_weight(obj)` | lbf | fraction × `fuel_weight_source.OEW(fuel_weight_source.W_TO)` |
| `avionics_volume(obj)` | ft³ | `weight_to_volume` |
| `fuel_density(obj)` | lb/ft³ | Nicolai & Carichner Table 8.6 (reused from `SubsystemsL1`) |
| `fuselage_raw_volume(obj)` | ft³ | Raymer 6th ed. Eq. 7.14, off `geom`'s envelope ellipse |
| `fuselage_usable_fuel_volume(obj)` | ft³ | `fuselage_raw_volume` × packaging factor |
| `wing_fuel_volume(obj)` | ft³ | Roskam Airplane Design Part II Eq. 6.2/6.3 |
| `fuel_volume(obj)` | ft³ | `fuselage_usable_fuel_volume + wing_fuel_volume` — the total `fuel_volume_check` reports as `available_vol_ft3`. Declared on `SubsystemsBase`. |
| `fuel_volume_from_weight(obj, fuel_weight_lb)` | ft³ | `fuel_weight_lb / fuel_density` — the definitional weight→volume conversion. Declared on `SubsystemsBase`. No packaging factor (that applies only to the geometric `fuselage_usable_fuel_volume`). |
| `battery_volume(obj, E_required_kWh)` | — | **ALWAYS ERRORS** — citation GAP, item 7 |
| `internal_volume(obj)` | ft³ | `fuel_volume(obj) + avionics_volume(obj)` |
| `fuel_volume_check(obj)` | struct | `fuel_volume(obj)` vs. `fuel_volume_from_weight(obj, fuel_weight_source.W_energy)` |

## 3. Equations

**Fuselage raw volume** — Raymer 6th ed. Eq. 7.14:

$$V_{fus,raw} = \frac{3.4\,(A_{top}\,A_{side})}{4\,L}$$

$A_{top}$/$A_{side}$ are this toolbox's own elliptical-envelope footprint estimate (no separate
equation number — the natural lengthwise extension of `F16GeomL2.compute_Amax_elliptical`'s
existing $(\pi/4)WH$ cross-section-ellipse assumption to the top-view and side-view projections):

$$A_{top} = \frac{\pi}{4} L_{fus} W_{max} \qquad A_{side} = \frac{\pi}{4} L_{fus} H_{max}$$

**Fuselage usable fuel volume** — packaging factor applied before any sufficiency comparison:

$$V_{fus,usable} = V_{fus,raw} \times PF(category)$$

**Wing fuel volume** — Roskam Airplane Design Part II, Ch.6, p.153, Eq. 6.2/6.3 (attributed by
Roskam to Torenbeek, Ref.17, Eqn. B-12):

$$V_{WF} = 0.54\,\frac{S^2}{b}\,(t/c)_r\,
  \frac{1 + \lambda_w \sqrt{\tau_w} + \lambda_w^2 \tau_w}{(1+\lambda_w)^2}
  \qquad \tau_w = \frac{(t/c)_t}{(t/c)_r}\ \text{[Eq. 6.3]}$$

**⚠ τ_w CONVENTION WARNING**: Eq. 6.3's $\tau_w$ is **tip/root**, the *opposite* of the geometry
discipline's Roskam Vol. II Eq. 12.1 $\tau$ = root/tip. Implemented per Eq. 6.3's stated definition —
Roskam does not use one consistent $\tau$ across his equations. Do not "fix" this to match Eq. 12.1.

**Fuel-volume sufficiency check** — sums both fuselage-internal and wing-internal volume, never just
one:

$$V_{available} = V_{fus,usable} + V_{WF} \qquad
  V_{required} = \frac{W_{energy}}{\rho_{fuel}(type)} \qquad
  \text{sufficient} \iff V_{available} \geq V_{required}$$

## 4. Coefficients

`lookup_packaging_factor` — Nicolai & Carichner, p.210, unnumbered "Fuel Tank Packaging Factors"
table, full 5-row table reproduced verbatim:

| Category | Packaging factor |
|---|---|
| Integral tank — shallow fuselage | 0.80 |
| Integral tank — deep fuselage | 0.85 |
| Integral tank — wing | 0.75 |
| Bladder tank — fuselage | 0.75 |
| Bladder tank — wing | 0.65 |

F-16 example uses **"Integral tank — shallow fuselage" (0.80)**, the row that multiplies the
**fuselage** raw volume. "Shallow" vs. "deep" has no numerical threshold in Nicolai; "shallow" is
taken as more representative of a slender fighter fuselage.

Every lookup errors (`SubsystemsL2:unknownPackagingCategory`) for an unlisted category.

## 5. To-dos (documented citation gaps — ship as deliberately-failing tests)

| Item | Guard |
|---|---|
| **Battery volumetric energy density** — no citable kWh/ft³, kWh/L, or lb/ft³ pack density exists in this repo; only gravimetric specific energy is cited (Nicolai & Carichner Table 14.2, p.363, 0.27 kWh/lb). `battery_volume` errors with `SubsystemsL2:batteryVolumetricDensityNotAvailable` rather than fabricate a coefficient. | `TestSubsystemsL2.testTODO_BatteryVolumetricDensityNotInRepo` |
| **Landing-gear bay-volume packaging** — no textbook tire+strut stowage-volume formula exists in this repo. Lives on `F16LandingGearL2.bay_volume` (`F16LandingGearL2:bayVolumeNotAvailable`), not this toolbox — `internal_volume()` deliberately does NOT auto-sum a gear-bay term. | `TestF16LandingGearL2.testTODO_BayVolumePackagingNotInRepo` |
