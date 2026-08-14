# F16LandingGearL2: input-to-output data flow

This chart shows the data path for `F16LandingGearL2`, the Level 2 (L2)
landing-gear class. The method is Raymer Table 11.1 statistical tire sizing on
the per-wheel static load, taken from a 90 / 10 main-to-nose load split of
`W_TO`.

**This class breaks the three-tier pattern, on purpose.** It has no
`LandingGearBase`, no `LandingGearModelL2` enforcer, and no separate toolbox
class. Not every airframe has conventional landing gear, so the discipline gets
no generic `src/disciplines/` home. The equations live in a `methods (Static)`
block inside the same file.

Two consequences:

- The class declares `< handle` directly. Every other stateful discipline class
  inherits handle semantics from its base tier. This one has no base tier, so
  without the declaration it would be a value class, and an optimizer mutating
  it inside a function would not see the change propagate.
- The chart has only two bands, the class and its own statics, instead of the
  usual three or four.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is small.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green is a function that calls another function.
  Yellow dashed is a getter that only does inline arithmetic. Red dashed is a
  method with no upstream call.
- Every edge takes the color of the node it POINTS AT.
- Six of the eight derived getters are yellow. The load split, the per-wheel
  division and the nose-tire fractions are all one line of arithmetic. Only the
  two main-tire getters call anything.
- `bay_volume` ALWAYS ERRORS. It is a documented citation gap, not a stub
  awaiting arithmetic. Raymer Ch. 11 sizes tires, struts and shock absorbers,
  and gives no bay-volume packaging estimate. The method refuses rather than
  inventing a geometric-envelope assumption. Tire and strut SIZE is unaffected.
- `bay_volume` stays a plain METHOD and is deliberately NOT `Dependent`.
  MATLAB evaluates every `Dependent` getter eagerly during object display, so
  an always-erroring `Dependent` property would break `disp(obj)`.
- No geometry object is injected. Nothing implemented here reads geometry, and
  `bay_volume` errors whatever fuselage envelope it might be given.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        WTS["Injected object<br/>weights (WeightsBase)"]
    end

    subgraph CLASS["F16LandingGearL2 (no base tier, declares handle directly)"]
        direction TB

        CTOR["Constructor<br/>F16LandingGearL2(json_path, weights)<br/>in: json_path, weights<br/>out: aircraft_category_table_row, main_pct,<br/>nose_pct, nose_tire_fraction_of_main,<br/>stored weights handle"]

        subgraph LOAD["Static loads"]
            D1["get.W_main_total<br/>in: main_pct, weights.W_TO<br/>out: total main-gear load [lbf]"]
            D2["get.W_nose_total<br/>in: nose_pct, weights.W_TO<br/>out: total nose-gear load [lbf]"]
            D3["get.W_w_main<br/>in: W_main_total, N_MAIN_WHEELS = 2<br/>out: load on ONE main wheel, Table 11.1's W_w"]
            D4["get.W_w_nose<br/>in: W_nose_total, N_NOSE_WHEELS = 1<br/>out: load on the nose wheel"]
        end

        subgraph TIRE["Tire sizing"]
            D5["get.tire_diameter_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: main-tire diameter [in]"]
            D6["get.tire_width_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: main-tire width [in]"]
            D7["get.tire_diameter_nose<br/>in: nose_tire_fraction_of_main, tire_diameter_main<br/>out: nose-tire diameter [in]"]
            D8["get.tire_width_nose<br/>in: nose_tire_fraction_of_main, tire_width_main<br/>out: nose-tire width [in]"]
        end

        BV["bay_volume(obj)<br/>ALWAYS ERRORS, documented citation gap<br/>no bay-volume packaging formula exists in this repo"]
    end

    subgraph TOOL["F16LandingGearL2 static methods (same file)"]
        T1["tire_diameter(A, B, W_w)<br/>D = A times W_w^B<br/>Raymer 6th ed. Table 11.1, p.344"]
        T2["tire_width(A, B, W_w)<br/>Width = A times W_w^B<br/>Raymer 6th ed. Table 11.1, p.344"]
        T3["lookup_tire_sizing_coeffs(table_row)<br/>all four Table 11.1 rows<br/>Jet fighter/trainer: A_d 1.59, B_d 0.302,<br/>A_w 0.0980, B_w 0.467"]
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

| Class member | Source | Notes |
| --- | --- | --- |
| `aircraft_category_table_row` | `f16a_L2.json`, `.subsystems.landing_gear.tire_sizing` | `Jet fighter/trainer`. This is the row name Raymer prints, so the lookup takes it verbatim. |
| `main_pct`, `nose_pct` | `.gear_load_split` | 90 and 10, from Raymer Ch. 11 p.344 prose, not a table. |
| `nose_tire_fraction_of_main` | `.nose_tire_fraction_of_main` | 0.80, a decided point value inside Raymer's stated 60 to 100 percent range. |
| `N_MAIN_WHEELS`, `N_NOSE_WHEELS` | Constant, 2 and 1 | A judgment call, stated as such: ordinary tricycle-gear configuration knowledge, not a pinned citation. It matters because Table 11.1's `W_w` is the PER-WHEEL load, so the main load is halved. |
| `weights` | Constructor argument, injected | `WeightsBase`. Only `W_TO` is read. |
| `W_TO` | `weights.W_TO`, via the private guard | The guard errors if `W_TO` is not finite and positive, so tire sizing cannot silently resolve to `NaN`. |
| `bay_volume` | Not implemented | Errors. The gap is recorded in the subplan and in the JSON's own `_TODO_gear_bay_volume_packaging` key, and pinned by a test that asserts the error identifier. |

## Methods with no upstream call at L2

| Method | Why |
| --- | --- |
| `bay_volume` | Nothing calls it in the model. `TestF16LandingGearL2` calls it to assert that it errors, and `F16SubsystemsL2` documents in prose that it must not be auto-summed until the gap closes. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/landing_gear/F16LandingGearL2.m` |
| Abstract tiers | None, by design |
| Toolbox | None. The statics are in the same file |
| Injected weights | `examples/F16A/models/disciplines/weights/F16WeightsL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
