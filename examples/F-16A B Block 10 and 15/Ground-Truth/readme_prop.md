# Brandt F-16A Propulsion — Engn(s) Tab Reference

Source: `Brandt-F16-A.xls`, sheet **Engn(s)**

---

## SLS Engine Parameters

These values are read directly from the spreadsheet and stored in `f16a_geometry.json`.

| Parameter             | Symbol       | Value  | Excel Cell     | Units |
|-----------------------|--------------|--------|----------------|-------|
| Dry (mil) SLS thrust  | T_sl_dry     | 15,000 | Engn!T_mil_SLS | lbf   |
| AB SLS thrust         | T_sl_AB      | 23,770 | Engn!T_AB_SLS  | lbf   |
| Dry TSFC, SLS ref     | TSFC_sl_dry  | 0.70   | Engn!TSFC_mil  | 1/hr  |
| AB TSFC, ref          | TSFC_sl_AB   | 2.20   | Engn!TSFC_AB   | 1/hr  |
| Throttle ratio        | TR           | 1.0    | Engn!S1        | —     |
| Engine count          | n_engines    | 1      | Main!B28       | —     |

---

## Standard Atmosphere Ratios

All thrust and TSFC equations are written in terms of four dimensionless ISA ratios
computed via MATLAB `atmosisa` (SI input: altitude in metres).
Reference sea-level values: T_SL = 288.15 K, P_SL = 101,325 Pa.

```
alt_m  = altitude_ft × 0.3048
[T_K, ~, P_Pa, ~] = atmosisa(alt_m)

theta  = T_K  / 288.15               (static temperature ratio)
delta  = P_Pa / 101325               (static pressure ratio)
theta0 = theta × (1 + 0.2 × M²)     (total temperature ratio)
delta0 = delta × (1 + 0.2 × M²)^3.5 (total pressure ratio)
```

Implemented in `BrandtEngine.atmosphereRatios(altitude_ft, mach)`.

---

## Throttle Ratio TR  (Engn!S1)

TR is the **total-temperature throttle limit** of the engine.  It governs a
correction term that appears in **both** the dry and AB thrust equations:

- When **θ₀ ≤ TR** — the engine operates below its temperature limit.
  No correction is applied; thrust scales with δ₀ only.
- When **θ₀ > TR** — the engine is temperature-limited.
  A correction proportional to `(θ₀ − TR) / θ₀` reduces thrust below the
  uncorrected value.  The correction coefficient differs between dry (1.7) and AB (2.2).

For the F-16A, TR = 1.0 (Engn!S1).  This means the engine is flat-rated to the
standard sea-level day total temperature.  At very high altitude or high Mach the
total temperature ratio θ₀ can rise above 1.0, activating the correction.

TR is an external input stored in `f16a_geometry.json` under `engine.TR` and read
by `BrandtEngine.compute()`.

---

## Thrust Equations — Four Cases

Every thrust call evaluates **one** of four equations depending on engine mode (dry/AB)
and whether θ₀ exceeds TR.  The four equations are listed below with their source cells.

### Dry (military) thrust  (Engn!row 4)

| Branch         | Condition   | Excel cells  | Equation                                                                    |
|----------------|-------------|--------------|-----------------------------------------------------------------------------|
| Uncorrected    | θ₀ ≤ TR     | Engn!A4:G4   | `alpha_dry = delta0 × (1 − 0.3 × M)`                                       |
| Temp-limited   | θ₀ > TR     | Engn!H4:S4   | `alpha_dry = delta0 × (1 − 0.3 × M − 1.7 × (theta0 − TR) / theta0)`       |

```
T_dry = T_sl_dry × n_engines × alpha_dry                              [lbf]
```

### Afterburner thrust  (Engn!row 6)

| Branch         | Condition   | Excel cells  | Equation                                                                         |
|----------------|-------------|--------------|----------------------------------------------------------------------------------|
| Uncorrected    | θ₀ ≤ TR     | Engn!A6:G6   | `alpha_AB = delta0 × (1 − 0.1 × sqrt(M))`                                       |
| Temp-limited   | θ₀ > TR     | Engn!H6:S6   | `alpha_AB = delta0 × (1 − 0.1 × sqrt(M) − 2.2 × (theta0 − TR) / theta0)`       |

```
T_AB = T_sl_AB × n_engines × alpha_AB                                 [lbf]
```

The two equations in each mode share the same TR threshold.  The correction
coefficients (1.7 for dry, 2.2 for AB) reflect the greater sensitivity of the
afterburner to total temperature limits.

---

## TSFC Equations

### Dry TSFC  (Engn!row 5)

```
tsfc_dry = TSFC_sl_dry × (1 + 0.35 × |M|) × sqrt(alpha_dry)          [1/hr]
```

`TSFC_sl_dry = 0.70 hr⁻¹` is calibrated at M = 0, sea level, where `|M| = 0`
and `alpha_dry = 1`, recovering the tabulated SLS value exactly.

### AB TSFC  (Engn!row 7)

```
tsfc_AB = TSFC_sl_AB × (1 + 0.35 × |M − 0.4|) × sqrt(alpha_AB)      [1/hr]
```

`TSFC_sl_AB = 2.20 hr⁻¹` is calibrated at M = 0.4, sea level, where
`|M − 0.4| = 0` and `alpha_AB = 1`, recovering the tabulated SLS value exactly.

In both cases `sqrt(alpha) < 1` at altitude, so TSFC decreases with altitude
(lower total temperature improves specific impulse).

---

## MATLAB Implementation

`BrandtEngine` merges the two θ₀ branches into a single expression using `max(0, ...)`,
which evaluates to zero when θ₀ ≤ TR and to the actual excess when θ₀ > TR:

```matlab
% Dry — thrust_dry()
correction = max(0, 1.7 .* (theta0 - TR) ./ theta0);
alpha_dry  = delta0 .* (1 - 0.3.*M - correction);
T_dry      = T_sl_dry .* n_engines .* alpha_dry;
tsfc_dry   = TSFC_sl_dry .* (1 + 0.35.*abs(M)) .* sqrt(max(0, alpha_dry));

% AB — thrust_AB()
correction = max(0, 2.2 .* (theta0 - TR) ./ theta0);
alpha_AB   = delta0 .* (1 - 0.1.*sqrt(M) - correction);
T_AB       = T_sl_AB .* n_engines .* alpha_AB;
tsfc_AB    = TSFC_sl_AB .* (1 + 0.35.*abs(M - 0.4)) .* sqrt(max(0, alpha_AB));
```

---

## Nacelle Geometry  (computed in BrandtGeometry)

Nacelle dimensions are **calculated** from SLS thrust; they are not given inputs.
For the F-16A (AB engine):

| Quantity       | Formula                         | Value    | Excel Cell |
|----------------|---------------------------------|----------|------------|
| D_nacelle      | `sqrt(T_sl_AB / 1900)`          | 3.537 ft | Engn!D_nac |
| L_nacelle      | `4.5 × D_nacelle`               | 15.917 ft| Engn!L_nac |

Dry-engine sizing (reference, not used for F-16A): `D = sqrt(T_sl_dry / 2000)`, `L = 3 × D`.

Implemented in `BrandtGeometry.computeNacelle()`.

---

## Engine Weight  (Wt tab)

| Aircraft type  | Formula                      | Value     | Excel source |
|----------------|------------------------------|-----------|--------------|
| AB (F-16A)     | `W_engine = 0.199 × T_sl_AB` | 4730.23 lb| Wt tab row 22|
| Dry (reference)| `W_engine = 0.199 × T_sl_dry`| —         | Wt tab row 10|

Implemented in `BrandtWeight.compute()`.

---

## Ground-Truth Cross-Check Values

| Quantity              | Value      | Excel source       | Tolerance |
|-----------------------|------------|--------------------|-----------|
| T_sl_dry              | 15,000 lbf | Engn!T_mil_SLS     | exact     |
| T_sl_AB               | 23,770 lbf | Engn!T_AB_SLS      | exact     |
| TSFC_sl_dry           | 0.70 1/hr  | Engn!TSFC_mil      | exact     |
| TSFC_sl_AB            | 2.20 1/hr  | Engn!TSFC_AB       | exact     |
| TR                    | 1.0        | Engn!S1            | exact     |
| T_dry at h=0, M=0     | 15,000 lbf | alpha=1 identity   | ±1%       |
| T_AB  at h=0, M=0     | 23,770 lbf | alpha=1 identity   | ±1%       |
| tsfc_dry at h=0, M=0  | 0.70 1/hr  | alpha=1 identity   | ±1%       |
| D_nacelle             | 3.537 ft   | Engn!D_nac         | ±1%       |
| L_nacelle             | 15.917 ft  | Engn!L_nac         | ±1%       |
| W_engine              | 4730.23 lb | Wt tab row 22      | ±1%       |

> Thrust and TSFC at 40,000 ft / M=0.87 are model-derived (no separate GT cell).
> Run `test_BrandtEngine.m` TABLE 3 to read those values from the MATLAB model.
