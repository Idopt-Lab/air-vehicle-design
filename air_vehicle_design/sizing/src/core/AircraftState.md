# AircraftState

Immutable ISA atmosphere state at a given altitude and Mach number — the flight condition passed into
most discipline methods. `classdef AircraftState`, a **value** class, so properties are set once in
the constructor and cannot be mutated afterwards.

All outputs are English units: lbf, ft, slug, ft/s, °R.

---

## 1. Constructor

```matlab
st = AircraftState(altitude_ft, mach);
```

Both arguments `mustBeNonnegative`. `altitude_ft` is geometric pressure altitude.

## 2. Properties

| Property | Units | Meaning |
|---|---|---|
| `altitude_ft`, `mach` | ft, — | the two inputs |
| `T_atm`, `P_atm`, `rho`, `a` | °R, lbf/ft², slug/ft³, ft/s | static temperature, pressure, density, speed of sound |
| `V` | ft/s | true airspeed |
| `q` | lbf/ft² | dynamic pressure |
| `theta`, `delta` | — | static temperature and pressure ratios |
| `theta_0`, `delta_0` | — | total (stagnation) ratios |

## 3. Equations

Atmosphere from MATLAB's `atmosisa` (ICAO 1993 standard), converted to English units.

$$V = M\,a \qquad q = \tfrac{1}{2}\rho V^{2}$$

Dimensionless ratios [Mattingly 2nd ed. Eq. 2.52]:

$$\theta = \frac{T}{T_{\text{std}}} \qquad \delta = \frac{P}{P_{\text{std}}}$$

$$\theta_0 = \theta\left(1 + 0.2M^{2}\right) \qquad
  \delta_0 = \delta\left(1 + 0.2M^{2}\right)^{3.5}$$

with $T_{\text{std}} = 518.67\ ^\circ\text{R}$ and $P_{\text{std}} = 2116.22\ \text{lbf/ft}^2$.

The total ratios carry the compressibility factor for $\gamma = 1.4$; `theta_0` and `delta_0` are what
the Mattingly thrust-lapse equations consume, not the static ratios.

## 4. Consumers

`PropL1`/`PropL2` (thrust lapse and TSFC), every `AeroL*` drag polar, the constraint classes, and
`F16WeightsL3` (which builds its own state at the cruise condition for `SFC_mission`).

## 5. To-dos

None.
