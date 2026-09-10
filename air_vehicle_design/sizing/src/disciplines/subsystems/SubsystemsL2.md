# SubsystemsL2

Level-2 subsystems static toolbox. Called as `SubsystemsL2.method(...)`; never instantiated, not in
the inheritance chain. Holds the L2 volume equations on scalars, one coefficient table, one
constant. The design class assembles them.

---

## 1. Constant

| Name | Value | Citation |
|---|---|---|
| `AVIONICS_DENSITY` | 45 lb/ft^3 | Nicolai & Carichner Sec. 8.1.11, p. 210 |

L1 uses 37.5 (Raymer's 30-45 average). The tiers differ on purpose.

## 2. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_fuselage_volume_raymer` | `A_top` [ft^2], `A_side` [ft^2], `L_fus` [ft] | raw fuselage volume [ft^3] | Raymer 6th ed. Eq. 7.14 |
| `compute_envelope_projected_areas` | `L_fus`, `W_max`, `H_max` [ft] | `[A_top, A_side]` [ft^2] | none, see §3 |
| `compute_wing_fuel_volume_roskam` | `S` [ft^2], `b` [ft], `tc_r`, `tc_t`, `lambda_w` | wing fuel volume [ft^3] | Roskam Part II, Ch. 6, p. 153, Eq. 6.2/6.3 |
| `lookup_packaging_factor_nicolai` | `category` | packaging factor | Nicolai p. 210, unnumbered table |
| `fuel_volume_check` | `fuel_vol_required`, `fuel_vol_available` [ft^3] | struct: `available_vol_ft3`, `required_vol_ft3`, `sufficient` | none, a comparison |
| `compute_battery_volume` | `E_required_kWh` | always errors, see §5 | Nicolai Table 14.2, p. 363 |

## 3. Equations

Fuselage raw volume [Raymer Eq. 7.14]:

$$V_{fus,raw} = \frac{3.4\,(A_{top}\,A_{side})}{4\,L}$$

`compute_envelope_projected_areas` supplies its `A_top` / `A_side`. No equation number: it extends
`F16GeomL2.compute_Amax_elliptical`'s $(\pi/4)WH$ ellipse lengthwise, same citation status.

$$A_{top} = \frac{\pi}{4} L_{fus} W_{max} \qquad A_{side} = \frac{\pi}{4} L_{fus} H_{max}$$

Wing fuel volume [Roskam Eq. 6.2/6.3, attributed to Torenbeek Ref. 17 Eqn. B-12]:

$$V_{WF} = 0.54\,\frac{S^2}{b}\,(t/c)_r\,
  \frac{1 + \lambda_w \sqrt{\tau_w} + \lambda_w^2 \tau_w}{(1+\lambda_w)^2}
  \qquad \tau_w = \frac{(t/c)_t}{(t/c)_r}$$

**TAU WARNING.** Eq. 6.3's $\tau_w$ is tip/root, the opposite of Roskam Vol. II Eq. 12.1's root/tip.
Do not "fix" it to match.

No packaging factor on the wing term: Roskam already returns a usable volume.

## 4. Coefficients

`lookup_packaging_factor_nicolai` [Nicolai p. 210], all five rows verbatim:

| Category | Factor |
|---|---|
| Integral tank — shallow fuselage | 0.80 |
| Integral tank — deep fuselage | 0.85 |
| Integral tank — wing | 0.75 |
| Bladder tank — fuselage | 0.75 |
| Bladder tank — wing | 0.65 |

Unlisted category raises `SubsystemsL2:unknownPackagingCategory`.

Nicolai's form is `Tank volume = (fuel volume) / (packaging factor)`, covering structure, pumps,
baffles, fuel lines and tank inefficiency. The code applies the reciprocal, `usable = raw * PF`.

**Shallow versus deep is undefined.** Those words appear once in Nicolai Vol. I, as these two row
labels. No threshold is given there or anywhere in this repo. Picking a row is a judgment call.

**A wing row applied to a fuselage volume is a silent error.** The lookup cannot detect it.

## 5. Citation gap

`compute_battery_volume` raises `SubsystemsL2:batteryVolumetricDensityNotAvailable`. Only
gravimetric specific energy is cited in this repo (Nicolai Table 14.2, p. 363, 0.27 kWh/lb); no
volumetric energy density or pack density exists, so energy cannot become volume. Full record:
`f16a_L2.json` `.subsystems._TODO_battery_specific_volume`.
