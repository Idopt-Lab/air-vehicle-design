# F16SandCL2: input-to-output data flow

This chart shows the data path for `F16SandCL2`, the Level 2 (L2) stability and
control class.

**L2 computes ONE quantity: the centre of gravity.** That is not a scope
choice. `F16GeomL2` exposes no x-station properties at all, so every other
Raymer Ch. 16 quantity genuinely cannot run at this tier. The L2 enforcer adds
nothing beyond the inherited `x_cg`.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is small.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green calls another function. Yellow dashed only
  reads and returns.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes. The toolbox holds one static, and it is reached.
- The two private helpers ARE drawn. They carry the mapping from ten weight
  groups to ten numbers, so hiding them would show `x_cg` reading the weights
  object directly, which is not what happens.
- The weight of each group is read LIVE from the injected weights object. Each
  station is read ONCE from the JSON at construction, because a station is spec
  data, not a recomputed quantity.
- `x_cg` returns `NaN` while the fuel group is unset, and that is deliberate.
  `W_energy` is mission-analysis state and reads `NaN` until the mission loop
  sets it. `weighted_cg` carries no `NaN`-rejecting validator, so IEEE
  arithmetic propagates the `NaN` into `x_cg` as a graceful signal instead of
  an error.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        WTS["Injected object<br/>weights (F16WeightsL2)"]
    end

    subgraph CLASS["F16SandCL2 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16SandCL2(json_path, weights)<br/>in: json_path, weights<br/>out: component_cg_x_ft (10 stations),<br/>stored weights handle"]

        P2["group_weight(obj, name)<br/>private<br/>in: one group name<br/>out: that group's weight off the weights object"]
        P1["component_weights(obj)<br/>private<br/>in: the 10 group names<br/>out: 10 weights, in COMPONENT_GROUP_NAMES order"]
        D1["get.x_cg<br/>in: 10 component weights, 10 stations<br/>out: x_cg [ft]"]
    end

    subgraph TOOL["SandCL2 toolbox (static methods)"]
        T1["weighted_cg(weights_vec, x_vec)<br/>x_cg = sum(W_i x_i) / sum(W_i)<br/>no equation number, standard CG identity"]
    end

    J -->|"stability_control.component_x_stations.groups:<br/>10 cg_x_ft stations, in wing, horizontal_tail,<br/>vertical_tail, fuselage, landing_gear, installed_engine,<br/>subsystems_lump, strake, payload, fuel order"| CTOR
    WTS -->|"weights"| CTOR

    WTS -->|"W_wings, W_tail.HT, W_tail.VT, W_fuselage,<br/>W_landing_gear, W_installed_engine, W_all_else_empty,<br/>W_strake, the payload sum, W_energy"| P2
    P2 -->|"one group's weight"| P1
    P1 -->|"10 component weights"| D1
    CTOR -->|"component_cg_x_ft"| D1

    D1 -->|"get.x_cg: component weights, component_cg_x_ft"| T1

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 2 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 3,4,5,6 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class CTOR ctor
    class P1,D1,T1 func
    class P2 passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `COMPONENT_GROUP_NAMES` | Constant, 10 names | The order matters. It fixes which station pairs with which weight. |
| `component_cg_x_ft` | `f16a_L2.json`, `.stability_control.component_x_stations.groups.*.cg_x_ft` | Ten stations, read once at construction. |
| `weights` | Constructor argument, injected | Typed to `F16WeightsL2` exactly, not `WeightsBase`. A tighter guard than the other disciplines use, because the ten group weights it reads are that class's own derived properties. |
| The ten group weights | `weights.*`, live | Eight come from L2 group getters. `payload` is the sum of the two payload properties, which are inert everywhere else. `fuel` is `W_energy`. |
| `x_cg` (Dependent) | `SandCL2.weighted_cg` | `NaN` until the mission loop sets `W_energy`. Deliberate, and documented in the toolbox. |
| `SandCL2.weighted_cg` | | Also called by `F16SandCL3` for its own `x_cg`. The equation is level-agnostic, so it lives here once. |

## Methods with no upstream call at L2

None. `SandCL2` holds one static, and `x_cg` calls it.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/sandc/F16SandCL2.m` |
| Tier 2, abstract | `src/disciplines/stability_control/SandCModelL2.m` |
| Tier 1, base | `src/base/StabControlBase.m` |
| Toolbox | `src/disciplines/stability_control/SandCL2.m` |
| Injected weights | `examples/F16A/models/disciplines/weights/F16WeightsL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
