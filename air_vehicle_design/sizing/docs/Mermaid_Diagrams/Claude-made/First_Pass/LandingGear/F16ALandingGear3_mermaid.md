# F16LandingGearL3: input-to-output data flow

This chart shows the data path for `F16LandingGearL3`, the Level 3 (L3)
landing-gear class.

**The equations are identical to L2.** Tire sizing depends only on `W_TO` and
the gear-load split, and neither changes with geometry fidelity. L3 therefore
calls L2's own static methods rather than repeating the Table 11.1 switch. The
class header records that keeping the two classes separate is a judgment call,
made to match the subplan's file list and the parallel JSON block.

The only differences from [F16ALandingGear2_mermaid.md](F16ALandingGear2_mermaid.md):

1. The constructor reads `f16a_L3.json`, not `f16a_L2.json`.
2. The two tire getters reach into `F16LandingGearL2`'s statics, so the toolbox
   band belongs to the OTHER class.
3. `bay_volume` raises `F16LandingGearL3:bayVolumeNotAvailable`, its own
   identifier, so a caller can tell which class's gap fired.

Everything else holds: no base tier, `< handle` declared directly, no injected
geometry, and the same six yellow inline-arithmetic getters.

**Read this first.**
- The chart runs TOP TO BOTTOM.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green calls another function. Yellow dashed is
  inline arithmetic only. Red dashed has no upstream call.
- Every edge takes the color of the node it POINTS AT.
- The toolbox band is `F16LandingGearL2`, reached from this class. That is
  reuse, not duplication.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L3.json"]
        WTS["Injected object<br/>weights (WeightsBase)"]
    end

    subgraph CLASS["F16LandingGearL3 (no base tier, declares handle directly)"]
        direction TB

        CTOR["Constructor<br/>F16LandingGearL3(json_path, weights)<br/>in: json_path, weights<br/>out: aircraft_category_table_row, main_pct,<br/>nose_pct, nose_tire_fraction_of_main,<br/>stored weights handle"]

        subgraph LOAD["Static loads"]
            D1["get.W_main_total<br/>in: main_pct, weights.W_TO<br/>out: total main-gear load [lbf]"]
            D2["get.W_nose_total<br/>in: nose_pct, weights.W_TO<br/>out: total nose-gear load [lbf]"]
            D3["get.W_w_main<br/>in: W_main_total, N_MAIN_WHEELS = 2<br/>out: load on ONE main wheel"]
            D4["get.W_w_nose<br/>in: W_nose_total, N_NOSE_WHEELS = 1<br/>out: load on the nose wheel"]
        end

        subgraph TIRE["Tire sizing"]
            D5["get.tire_diameter_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: main-tire diameter [in]"]
            D6["get.tire_width_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: main-tire width [in]"]
            D7["get.tire_diameter_nose<br/>in: nose_tire_fraction_of_main, tire_diameter_main<br/>out: nose-tire diameter [in]"]
            D8["get.tire_width_nose<br/>in: nose_tire_fraction_of_main, tire_width_main<br/>out: nose-tire width [in]"]
        end

        BV["bay_volume(obj)<br/>ALWAYS ERRORS, own error identifier<br/>F16LandingGearL3:bayVolumeNotAvailable"]
    end

    subgraph TOOL["F16LandingGearL2 static methods (REUSED by L3)"]
        T1["tire_diameter(A, B, W_w)<br/>Raymer 6th ed. Table 11.1, p.344"]
        T2["tire_width(A, B, W_w)<br/>Raymer 6th ed. Table 11.1, p.344"]
        T3["lookup_tire_sizing_coeffs(table_row)<br/>Jet fighter/trainer: A_d 1.59, B_d 0.302,<br/>A_w 0.0980, B_w 0.467"]
    end

    J -->|"subsystems.landing_gear: tire_sizing.aircraft_category_table_row,<br/>gear_load_split.main_pct = 90, nose_pct = 10,<br/>nose_tire_fraction_of_main = 0.80"| CTOR
    WTS -->|"weights"| CTOR

    WTS -->|"weights.W_TO, must be finite and positive"| D1
    CTOR -->|"main_pct"| D1
    WTS -->|"weights.W_TO, must be finite and positive"| D2
    CTOR -->|"nose_pct"| D2
    D1 -->|"W_main_total"| D3
    D2 -->|"W_nose_total"| D4
    D3 -->|"W_w_main"| D5
    CTOR -->|"aircraft_category_table_row"| D5
    D3 -->|"W_w_main"| D6
    CTOR -->|"aircraft_category_table_row"| D6
    D5 -->|"tire_diameter_main"| D7
    CTOR -->|"nose_tire_fraction_of_main"| D7
    D6 -->|"tire_width_main"| D8
    CTOR -->|"nose_tire_fraction_of_main"| D8

    D5 -->|"get.tire_diameter_main: table_row"| T3
    D5 -->|"get.tire_diameter_main: A_d, B_d, W_w_main"| T1
    D6 -->|"get.tire_width_main: table_row"| T3
    D6 -->|"get.tire_width_main: A_w, B_w, W_w_main"| T2

    CTOR -.->|"no upstream call, NOT IMPLEMENTED"| BV

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 2,3,4,5,6,7,12,13,14,15 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 8,9,10,11,16,17,18,19 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 20 stroke:#ff4040,color:#ff4040,stroke-width:2px,stroke-dasharray:5 5

    classDef dead fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040,stroke-dasharray: 6 4
    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class BV dead
    class CTOR ctor
    class D5,D6,T1,T2,T3 func
    class D1,D2,D3,D4,D7,D8 passthrough
```

## Field-by-field notes

Identical to L2 in every value. See
[F16ALandingGear2_mermaid.md](F16ALandingGear2_mermaid.md). The only field-level
difference is the source file: `f16a_L3.json`, whose
`.subsystems.landing_gear` block carries the same four keys with the same
values.

| Class member | Source | Notes |
| --- | --- | --- |
| All four inputs | `f16a_L3.json`, `.subsystems.landing_gear` | Same keys and same values as the L2 block. |
| `weights` | Constructor argument, injected | `WeightsBase`. Only `W_TO` is read. No geometry is injected. |
| The three statics | `F16LandingGearL2` | Reused directly. L3 defines no equation of its own. |
| `bay_volume` | Not implemented | Errors with `F16LandingGearL3:bayVolumeNotAvailable`, a separate identifier from L2's. |

## Methods with no upstream call at L3

| Method | Why |
| --- | --- |
| `bay_volume` | Nothing calls it in the model. One test asserts both classes' error identifiers. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/landing_gear/F16LandingGearL3.m` |
| Abstract tiers | None, by design |
| Toolbox | `examples/F16A/models/disciplines/landing_gear/F16LandingGearL2.m`, reused |
| Injected weights | `examples/F16A/models/disciplines/weights/F16WeightsL3.m` |
| Input JSON | `examples/F16A/inputs/f16a_L3.json` |
