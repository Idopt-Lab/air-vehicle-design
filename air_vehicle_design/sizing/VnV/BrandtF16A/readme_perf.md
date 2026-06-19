# BrandtPerformance

## Overview

`BrandtPerformance` reproduces the workbook performance views behind the `Perf`, `Ps`, `Maneuv`, and `Struct` tabs. It uses existing `BrandtAerodynamics` and `BrandtEngine` outputs rather than re-implementing those models.
Key Excel outputs referenced here are the performance/PS/maneuver tables in `Perf`, `Ps`, `Maneuv`, and `Struct`, plus `Aero!H25:H29` and `Miss!O6:O9`.

## Equations used

- Dynamic pressure:

$$q=\tfrac{1}{2}\rho V^2$$

- Lift coefficient from weight balance:

$$C_L=\frac{W}{qS}$$

- Drag polar:

$$C_D=C_{D0}+K_1C_L^2+K_2C_L$$

- Specific excess power:

$$P_s=\frac{(T-D)V}{W}$$

- Turn rate:

$$\omega=\frac{g\sqrt{n^2-1}}{V}$$

- Sea-level stall / corner speeds:

$$V_{stall}=\sqrt{\frac{2W}{\rho S C_{L,max}}}, \qquad V_{corner}=V_{stall}\sqrt{n_{max}}$$

## Cross-tab dependencies

- `BrandtAerodynamics.run(M)` → `CD0`, `K1`, `K2`, `CLmax_clean`
- `BrandtEngine.run(h,M,AB)` → thrust `T`
- `performance` JSON section → altitudes, load-factor limits, `q_max`
- `Miss!O6:O9` → validation anchors for speed, turn, and excess-power outputs

## Assumptions and discrepancies from Excel

- Atmosphere uses MATLAB `atmosisa`, so contour values can differ slightly from Brandt's hand-entered atmosphere table.
- Sustained-turn `n` is solved from the quadratic drag polar at `Ps = 0`.
- The negative-stall boundary uses `0.8 * CLmax_clean` as a Level-Brandt approximation.

## Flowchart

```mermaid
flowchart TD
    A[Constructor] --> B[Store geom/aero/eng/wt handles]
    B --> C[analyze()]
    C --> D[Build Mach and altitude grids]
    D --> E[run()]
    E --> F[run_perf]
    E --> G[run_ps]
    E --> H[run_maneuv]
    E --> I[run_struct]
    F --> J[validate_run_()]
    G --> J
    H --> J
    I --> J
```

## Validation targets

- Positive `Ps` near Mach 0.87 at 40,000 ft
- Sustained turn rate above 10 deg/s near Mach 0.87 at 10,000 ft
- Finite V-n corner speed and `q_max` cutoff
