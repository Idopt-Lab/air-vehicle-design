# SubsystemsL3

Level-3 subsystems static toolbox (`classdef SubsystemsL3`, `methods (Static)` only). Called as
`SubsystemsL3.method(...)`; never instantiated and not in the inheritance chain.

Two unrelated groups live here: fuselage station-table integration, and the Nicolai Table 8.8
avionics equipment statistics. 34 public statics, 6 private helpers.

---

## 1. Fuel volume check

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `fuel_volume_check` | `fuel_vol_required`, `fuel_vol_available` [ft^3] | struct `available_vol_ft3`, `required_vol_ft3`, `sufficient` | none, a comparison |

Two scalars, no design object. Errors on a `NaN` argument.

## 2. Frame-integrated projected areas

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_frame_integrated_projected_areas` | `frames_normalized` (N,3), `L_fus`, `W_max`, `H_max` | `A_top`, `A_side` [ft^2] | definitional; feeds Raymer Eq. 7.14 |

`frames_normalized` columns are `[x/L, w/W_max, h/H_max]`. Denormalized through
`GeomL3.denormalize_frames`, a `(0,0,0)` nose station is prepended, then `trapz` over station `x`:

$$A_{top} = \int_0^{L} w(x)\,dx \qquad A_{side} = \int_0^{L} h(x)\,dx$$

The integration itself has no textbook equation number. The `3.4/(4L)` combination that consumes
these areas is the cited Raymer equation.

## 3. Volume from control stations

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_volume_from_control_stations` | `frame_x`, `frame_w`, `frame_h`, one entry per station | internal volume [ft^3] | Raymer 6th ed. Fig. 7.38, p. 207; worked example Fig. 7.5, p. 171 |

Cross-section area is plotted against station `x`, measured downstream from the nose, and the volume
is the area under that curve. Raymer gives this as more accurate than Eq. 7.14.

Areas come from `GeomL3.compute_frame_cs_area`, the same cosine section the wetted-area path uses,
so the two agree on body shape. A leading `(0, 0)` station closes the nose to a point; a body that
does not close to a point needs a different first station. Errors
`SubsystemsL3:frameVectorLengthMismatch` when the three vectors differ in length.

**Validated against Brandt.** On the F-16A's 20 fuselage stations this returns 764.0820 ft^3 against
Brandt's 745.6994 ft^3, a +2.47 % difference that traces to the L3 fuselage length of 47.5 ft against
Brandt's 46.5 ft, a deliberate tier difference. The per-station areas agree with Brandt's fuselage
cross-section column to 7.11e-15 ft^2. The integration is the same `trapz` Brandt uses for its
whole-aircraft volume `Geom!S47`, which the framework reproduces at 1101.4704 ft^3 against a ground
truth of 1106.306 ft^3.

Raymer Eq. 7.14 on the same body gives 963.9143 ft^3, so the envelope formula reads 26.2 % high.

## 4. Avionics equipment statistics

[Nicolai & Carichner Table 8.8, p. 212] throughout. Weight [lbf], power [W], volume [ft^3] at every
public boundary.

**Any one of the three quantities gives the other two.** Table 8.8 fits weight from power and weight
from volume. Power and volume come back by inverting those fits, so a request for power from volume
chains volume -> weight -> power; the table fits no direct power-to-volume relation.

### 4.1 Per-system entry points

Nine systems x three quantities = 27 methods, each a one-line delegation to the matching generic
solver. Systems: `radar`, `doppler_nav`, `inertial_nav`, `tacan`, `receiver`, `transmitter`,
`identification`, `computer`, `ecm`.

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_<system>_weight` | `power_W`, `volume_ft3`; supply one, `[]` for the other | weight [lbf] | Table 8.8 |
| `compute_<system>_power` | `weight_lb`, `volume_ft3`; supply one, `[]` for the other | power [W] | Table 8.8 |
| `compute_<system>_volume` | `power_W`, `weight_lb`; supply one, `[]` for the other | volume [ft^3] | Table 8.8 |

### 4.2 Generic solvers and the lookup

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `compute_avionics_weight_statistical` | `system`, `power_W`, `volume_ft3` | weight [lbf] | Table 8.8, the fitted direction |
| `compute_avionics_power_statistical` | `system`, `weight_lb`, `volume_ft3` | power [W] | Table 8.8, inverted |
| `compute_avionics_volume_statistical` | `system`, `power_W`, `weight_lb` | volume [ft^3] | Table 8.8, inverted |
| `lookup_avionics_coeffs` | `system` | struct `wp`, `wv`, `v_unit` | Table 8.8 |

### 4.3 Coefficients

`pow`: `Wt = a*X^b`. `lin`: `Wt = a + b*X`. Each row carries its own volume unit; the public
boundary is always ft^3 and converts at 1728 in^3 per ft^3.

| System | Weight from power | Weight from volume | Volume unit |
|---|---|---|---|
| `radar` (less antenna) | `pow` 0.431, 0.777 | `pow` 38.21, 0.873 | ft^3 |
| `doppler_nav` | `pow` 0.408, 0.868 | `pow` 29.67, 0.662 | ft^3 |
| `inertial_nav` | `pow` 0.465, 0.848 | `pow` 51.85, 0.738 | ft^3 |
| `tacan` | `lin` 13.61, 0.104 | `pow` 0.311, 0.704 | in^3 |
| `receiver` | `lin` 6.3, 0.17 | `pow` 44.5, 0.737 | ft^3 |
| `transmitter` | `pow` 0.73, 0.610 | `lin` 6.4, 40.2 | ft^3 |
| `identification` | `pow` 0.607, 0.724 | `pow` 0.069, 0.868 | in^3 |
| `computer` | `pow` 2.246, 0.630 | `pow` 0.123, 0.817 | in^3 |
| `ecm` | `pow` 0.429, 0.771 | `pow` 0.055, 0.912 | in^3 |

### 4.4 Private helpers

`row`, `is_given`, `to_fit_volume`, `from_fit_volume`, `eval_fit`, `solve_fit`. An input counts as
supplied when it is a finite scalar.

## 5. Errors

| Identifier | Raised when |
|---|---|
| `SubsystemsL3:oneInputRequired` | neither of the two optional inputs is a finite scalar |
| `SubsystemsL3:unknownAvionicsSystem` | the system name matches no Table 8.8 row |
| `SubsystemsL3:fitOutOfRange` | a fit inverts to a non-positive quantity, which happens on a `lin` row at or below its intercept |

## 6. Accuracy

Table 8.8 is a statistical fit across all avionics classes, so scatter against any single real unit
is wide and expected. Where both a weight and a volume are known, the two fits will not generally
agree with each other.

## 7. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| — | None open in `SubsystemsL3.m`. | — |

