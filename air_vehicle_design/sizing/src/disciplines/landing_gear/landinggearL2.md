# landinggearL2

Level-2 landing-gear static toolbox (`classdef landinggearL2`, `methods (Static)` only). Called as
`landinggearL2.method(...)`; never instantiated and not in any inheritance chain.

Five statics: the two Table 11.1 tire regressions, the coefficient lookup that feeds them, and the
tipback angle and its check.

Designs without landing gear can set their required properties to 0.

---

## 1. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `tire_diameter` | `A`, `B`, `W_w` [lbf] | tire outside diameter [in] | Raymer 6th ed. Table 11.1, p.344 |
| `tire_width` | `A`, `B`, `W_w` [lbf] | tire width [in] | Raymer 6th ed. Table 11.1, p.344 |
| `lookup_tire_sizing_coeffs` | `table_row` | struct `A_d`, `B_d`, `A_w`, `B_w` | Raymer 6th ed. Table 11.1, p.344 |
| `compute_tipback_angle` | `cg_loc`, `main_wheel_loc` [ft] | `tipback_angle` [deg] | Raymer 6th ed. Fig. 11.5, p.342 |
| `check_tipback_angle` | `tipback_angle` [deg] | true/false [bool] | Logic, Raymer 6th edition p 345 |

The tire lookup returns the row; the two regressions evaluate it. The caller joins them, so choosing the
category stays in the design class.

## 2. Equations

Both regressions are the same power law on the load carried by ONE wheel:

$$D = A_d\,W_w^{B_d} \qquad W = A_w\,W_w^{B_w}$$

`W_w` is the weight on the wheel in lbf; both outputs are inches. Raymer prints a separate metric
coefficient set for kg and cm; this toolbox holds the English set only.

All three inputs are validated `mustBePositive`, so a zero or negative wheel load errors rather than
returning a complex or infinite size.

Tipback angle. Both points are `[x, y]` in ft, with x aft of the nose and y up from the
longitudinal axis. The angle is between the vertical at the main wheel and the line from the main
wheel to the CG:

$$\theta = 180^\circ - \cos^{-1}\!\left(\frac{\mathbf{v}\cdot\mathbf{r}}{|\mathbf{v}|\,|\mathbf{r}|}\right),
\qquad \mathbf{v} = [0,\ y_{mw}],\quad \mathbf{r} = \mathbf{cg} - \mathbf{mw}$$

`v` points down (y_mw < 0), so `acos` gives the supplement, and `180 -` gives the angle. This is
equal to `atan(|x_mw - x_cg| / (y_cg - y_mw))`.

`check_tipback_angle` returns true when 15 < θ < 25 deg. Raymer: at least 15 deg; much over 25 deg
risks nose-up porpoising on takeoff.

## 3. Coefficients

[Raymer 6th ed. Table 11.1, p.344] Full 4-row table, verbatim.

| Aircraft Type | `A_d` | `B_d` | `A_w` | `B_w` |
|---|---|---|---|---|
| General aviation | 1.51 | 0.349 | 0.7150 | 0.312 |
| Business twin | 2.69 | 0.251 | 1.170 | 0.216 |
| Transport/bomber | 1.63 | 0.315 | 0.1043 | 0.480 |
| Jet fighter/trainer | 1.59 | 0.302 | 0.0980 | 0.467 |

Each row's diameter and width coefficients travel together. Reading `A_d` from one row and `A_w`
from another gives a tire that matches no aircraft class.

## 4. Scope of the correlation

Raymer states four limits on p.344 that the equations themselves do not encode. A caller supplies
them.

| Limit | Value |
|---|---|
| The regression sizes the MAIN tire | main tires carry about 90% of aircraft weight |
| Nose tire | 60 to 100% of main-tire size |
| Taildragger tailwheel | 1/4 to 1/3 of main-tire size |
| Rough or unpaved runway | increase diameter and width by about 30% |

Raymer also notes that final tire selection for a real layout comes from a manufacturer's catalog,
sized to the smallest tire rated for the calculated static plus dynamic loads. Table 11.2, pp.346-347
holds that catalog data and is not reproduced here.

## 5. Errors

| Identifier | Raised when |
|---|---|
| `F16LandingGearL2:unknownTireCategory` | the category matches no Table 11.1 row |
| `MATLAB:validators:mustBePositive` | any of `A`, `B`, `W_w` is zero or negative |

## 6. TODOs

| Date | Task | Location/function/context |
|---|---|---|
| 9/16/2026 | The error identifier carries the `F16LandingGearL2` prefix | `lookup_tire_sizing_coeffs`; the static now lives in a generic toolbox |
| 9/16/2026 | Class name is lowercase | every other toolbox is `GeomL2`, `AeroL2`, `SubsystemsL2` |
| 9/29/2026 | Class header lists only the three tire statics | `landinggearL2.m` header block; add the two tipback statics |
| 9/29/2026 | File `LandingGearModelL2.m` holds `classdef landinggearModelL2` | the names differ in case, so MATLAB cannot load the class |
