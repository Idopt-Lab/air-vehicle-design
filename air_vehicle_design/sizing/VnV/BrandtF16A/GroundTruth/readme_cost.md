# BrandtCost

## Overview

`BrandtCost` reproduces the Brandt workbook `Cost` tab using a DAPCA IV style acquisition + O&M life-cycle cost build-up. It consumes `BrandtWeight.run()` and `BrandtMission.run()` outputs.
Key Excel anchors are `Wt!B12`, `Miss!O8:O9`, and the `Cost` tab summary cells.

## Equations used

- Material factor:

$$D_{47}=\sum_i \frac{p_i f_i}{100}=1.03$$

- Labor-hour models:

$$H_{eng}=7.07\,W_e^{0.777}V^{0.894}Q^{0.163}D_{47}$$
$$H_{tool}=8.71\,W_e^{0.777}V^{0.696}Q^{0.263}D_{47}$$
$$H_{mfg}=10.72\,W_e^{0.82}V^{0.484}Q^{0.641}D_{47}$$
$$H_{qc}=0.133\,H_{mfg}D_{47}$$

- Program cost:

$$C_{unit}=\frac{(1+EF)(C_{subtotal}+C_{av}+C_{invest})}{Q}$$

- Annual O&M:

$$C_{OM}=\frac{FH_{yr}}{DMT}DMF\,F + CR\,CH_{yr}\,RE(1+EF)+MMH/FH\cdot FH_{yr}\cdot RM(1+EF)$$

## Cross-tab dependencies

- `Wt!B12` → `wt_results.W_empty_lb`
- `Miss!O9` / `O8` → `miss_results.total_fuel_lb`, `miss_results.total_time_min`
- `Engn(s)` / `Main` inputs → thrust, engine count, Mach limit
- `Cost` tab summary cells → unit flyaway, program total, O&M, and LCC validation targets

## Assumptions and discrepancies from Excel

- Max-speed input uses `aircraft.Mmax` and a tropopause speed of sound of 968.1 ft/s.
- Mission fuel/time come from the MATLAB mission model, so tiny differences from the workbook propagate into O&M.
- The class follows the Level-Brandt dual-return pattern: `run()` stores properties and returns the same values in a struct.

## Flowchart

```mermaid
flowchart TD
    A[Constructor] --> B[Load JSON + handles]
    B --> C[analyze()]
    C --> D[Compute D47]
    D --> E[run()]
    E --> F[Read weight + mission results]
    F --> G[Compute labor hours]
    G --> H[Compute acquisition costs]
    H --> I[Compute O&M and LCC]
    I --> J[validate_run_()]
```

## Validation targets

- Unit flyaway: about $68.4M
- Total program: about $13.68B
- Life O&M: about $24.84M
- Life-cycle cost: about $93.26M
