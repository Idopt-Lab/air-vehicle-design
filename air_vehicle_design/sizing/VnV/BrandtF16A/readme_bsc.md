# BrandtBalanceStabControl

## Overview

`BrandtBalanceStabControl` combines the workbook balance, stability/control, and landing-gear checks. It computes surface MAC/AC stations, a simplified neutral point, takeoff/landing CG, static margin, gear load split, tipback, and rollover.
Key Excel anchors are the `BSC` / balance-control cells for MAC, CG, gear split, tipback, and rollover plus `Geom!`, `Wt!`, and `Aero!` inputs.

## Equations used

- Mean aerodynamic chord:

$$\mathrm{MAC}=\frac{2}{3}c_r\frac{1+\lambda+\lambda^2}{1+\lambda}$$

- MAC station and aerodynamic center:

$$x_{MAC}=x_{LE,r}+y_{MAC}\tan\Lambda_{LE}, \qquad x_{ac}=x_{MAC}+0.25\,\mathrm{MAC}$$

- Neutral point approximation:

$$x_{np}=x_{ac,w+s+f}+\frac{S_H}{S_W}\frac{l_H}{MAC_W}(1-d\varepsilon/d\alpha)MAC_W$$

- CG closure:

$$x_{cg}=\frac{\sum_i W_i x_i}{\sum_i W_i}$$

- Static margin:

$$SM=\frac{x_{np}-x_{cg}}{MAC_W}$$

- Gear load split:

$$\%W_{main}=100\frac{x_{cg}-x_{nose}}{x_{main}-x_{nose}}$$

## Cross-tab dependencies

- `BrandtGeometry` → frame data, surface chords/spans, nacelle length convention
- `BrandtAerodynamics` → downwash estimate for the tail contribution
- `BrandtWeight.run(W_TO_lb)` → component weights and payload/fuel masses
- `gear` JSON section → longitudinal / lateral gear geometry
- Workbook balance-control cells → xcg, xnp, gear-load, tipback, and rollover outputs

## Assumptions and discrepancies from Excel

- Vertical-tail MAC station uses an exposed-span correction so the arm matches the worksheet better than a full-span formula.
- Installed-component balance arms include a small datum shift (`-0.522 ft`) to match the workbook CG closure; raw component stations are still stored as properties.
- The fuselage destabilizing correction is simplified to a width-scaled offset.

## Flowchart

```mermaid
flowchart TD
    A[Constructor] --> B[Store geom/wt/aero handles]
    B --> C[analyze()]
    C --> D[Compute MAC, xMAC, xac]
    D --> E[Compute component stations + xnp]
    E --> F[run(W_TO)]
    F --> G[Get BrandtWeight component masses]
    G --> H[Compute takeoff/landing CG]
    H --> I[Compute static margins + gear metrics]
    I --> J[validate_run_()]
```

## Validation targets

- `xnp` about 26.168 ft
- `xcg_TO` about 26.193 ft
- `xcg_land` about 26.137 ft
- Gear split about 26.7% main / 73.3% nose
- Tipback about 21.5 deg; rollover about 74.4 deg
