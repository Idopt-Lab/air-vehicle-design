# PropL1

Level-1 propulsion static toolbox (`classdef PropL1`, `methods (Static)` only). Called as
`PropL1.method(...)`; never instantiated. `F16PropL1` inherits `PropulsionModelL1` and delegates here.

L1 is the simplest usable engine model: a density-ratio thrust lapse and a two-value TSFC table.
No Mach term, no afterburner split, no supersonic value.

---

## 1. Role

| Layer | Members |
|---|---|
| High-level — take the concrete object | `get_thrust_lapse`, `get_TSFC` |
| Low-level | `sigma_lapse`, `lookup_lapse_exponent`, `lookup_TSFC` |

## 2. Equations

**Thrust lapse** [Martins AE481 metabook Eq. 10.9], with the exponent by engine type per Eq. 10.7:

$$\alpha = \sigma^{m} \qquad \sigma = \frac{\rho}{\rho_{SL}}$$

$m = 0.6$ for a turbofan, $1.0$ for a turbojet. $\rho_{SL} = 0.002377$ slug/ft³
[Mattingly: Aircraft Engine Design, 2nd edition App. B].

The lapse has no Mach term, so it cannot distinguish dry from afterburning power, and it degrades at
extreme altitude and supersonic Mach. This is the L1 limitation, not a defect.

**TSFC** [Raymer 6th ed. Table 3.3, low-bypass turbofan] — a two-value table:

$$c_t = \begin{cases}
  0.70\ \text{hr}^{-1} & M < 0.4 \quad(\text{loiter})\\[2pt]
  0.80\ \text{hr}^{-1} & M \ge 0.4 \quad(\text{cruise})
\end{cases}$$

## 3. As-built values

At 36,000 ft / M 0.87: $\alpha = 0.48374118$, $c_t = 0.80$ hr⁻¹.

## 4. Category coverage

`engine_type` selects both the lapse exponent and the TSFC row. Unlisted types error.

## 5. To-dos

| Item | Status |
|---|---|
| The $M = 0.4$ TSFC threshold is an L1 approximation: the segment type (cruise vs loiter) is not carried on `AircraftState`, so Mach stands in for it | accepted L1 limitation |

No deliberately-red `testTODO_` tests.
