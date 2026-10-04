# F16LandingGearL3: input-to-output data flow

This chart shows the data path for `F16LandingGearL3`, the Level 3 landing-gear class. It
splits the gross weight between main and nose gear and sizes the tires from
Raymer's statistical table.

## Viewing this chart with pan and zoom

Mermaid inside a `.md` renders at a fixed size, so a wide chart is hard to read
in a plain preview. Open `docs/Mermaid_Diagrams/viewer.html` and drag this file
onto it. Wheel or pinch zooms, drag pans, and `f` fits.

The viewer reads the first mermaid fenced block straight out of this file, so
there is no second copy of the diagram to keep in step.

**Read this first.**
- The chart runs LEFT TO RIGHT.
- One function per node. Name, inputs, output, citation. Returned values and
  coefficients live in the notes table, not in the labels.
- No grouped "Inputs" node. Every value rides the arrow that carries it. A
  source node holds only a file, object or constant name.
- **Colour says what kind of member a node is; dash says whether the value was
  worked on.** A box whose body returns a stored field unchanged is a pure
  relay, so it is dashed, and so is every line leaving it. A box that evaluates
  an equation, reads a table, calls a method, or combines its inputs is solid.
- **A line's colour comes from the node it POINTS AT; its dash comes from the
  node it LEAVES.** A source node is not a method, so it takes the solid dash of
  the constructor.
- Constructor cyan. Every other function green. An INJECTOR, meaning any
  `get.<name>` property getter, is magenta, and magenta beats every other node
  colour. All eight injectors are solid: each combines its inputs or calls a
  method.
- A NON-INJECTOR function that calls nothing is YELLOW and points at the
  `no toolbox call` marker. `requireWTO` is the one: it returns
  `weights.W_TO` unchanged after checking that it is set.
- **THERE IS NO ENFORCER.** `F16LandingGearL3` subclasses `handle` directly. The
  `landinggearModelL2` enforcer is not wired to it, so it is not drawn.
- **L3 CALLS THE L2 TOOLBOX.** `F16LandingGearL3` has no statics of its own: both tire
  getters call `landinggearL2.lookup_tire_sizing_coeffs`, `tire_diameter` and
  `tire_width`. The class is otherwise a copy of the tire part of `F16LandingGearL2`.
- **THE JSON TIRE COEFFICIENTS ARE NOT READ.** `.tire_sizing` carries
  `diameter_coeff_A/B` and `width_coeff_A/B`, but the tire getters take the
  coefficients from `lookup_tire_sizing_coeffs` instead. The values agree.
- **THE NOSE TIRE IS SCALED OFF THE MAIN TIRE**, by
  `nose_tire_fraction_of_main`. So `get.W_w_nose` is computed but nothing in the
  class reads it.
- One red node: `bay_volume`, which errors by design. Only a test calls it,
  to check the error.

```mermaid
flowchart LR
    NC["no toolbox call"]

    subgraph SRC["Sources"]
        J["f16a_L3.json"]
        WTS["Injected weights<br/>F16WeightsL3"]
        K["F16LandingGearL3 constants"]
    end

    subgraph CLASS["F16LandingGearL3 (Tier 3, no enforcer)"]
        direction TB

        CTOR["Constructor<br/>F16LandingGearL3(json_path, weights)<br/>in: json_path, weights, both required<br/>out: aircraft_category_table_row, main_pct, nose_pct,<br/>nose_tire_fraction_of_main, weights"]

        subgraph LOAD["Gear load split"]
            G1["get.W_main_total<br/>in: main_pct, W_TO<br/>out: W_main_total"]
            G2["get.W_nose_total<br/>in: nose_pct, W_TO<br/>out: W_nose_total"]
            G3["get.W_w_main<br/>in: W_main_total, N_MAIN_WHEELS<br/>out: W_w_main"]
            G4["get.W_w_nose<br/>in: W_nose_total, N_NOSE_WHEELS<br/>out: W_w_nose"]
        end

        subgraph TIRE["Tire size"]
            G5["get.tire_diameter_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: tire_diameter_main"]
            G6["get.tire_width_main<br/>in: aircraft_category_table_row, W_w_main<br/>out: tire_width_main"]
            G7["get.tire_diameter_nose<br/>in: nose_tire_fraction_of_main, tire_diameter_main<br/>out: tire_diameter_nose"]
            G8["get.tire_width_nose<br/>in: nose_tire_fraction_of_main, tire_width_main<br/>out: tire_width_nose"]
        end

        subgraph MTH["Methods"]
            RQ["requireWTO(obj)<br/>PRIVATE<br/>in: weights.W_TO<br/>out: W_TO"]
            M1["bay_volume(obj)<br/>ALWAYS ERRORS, citation gap<br/>NO UPSTREAM CALL at L3"]
        end
    end

    subgraph STAT["landinggearL2 statics (toolbox)"]
        S1["tire_diameter(A, B, W_w)<br/>out: tire diameter<br/>Raymer 6th ed. Table 11.1, p.344"]
        S2["tire_width(A, B, W_w)<br/>out: tire width<br/>Raymer 6th ed. Table 11.1, p.344"]
        S3["lookup_tire_sizing_coeffs(table_row)<br/>out: A_d, B_d, A_w, B_w<br/>Raymer 6th ed. Table 11.1, p.344"]
    end

    J -->|"subsystems.landing_gear: tire_sizing.aircraft_category_table_row,<br/>gear_load_split.main_pct, gear_load_split.nose_pct, nose_tire_fraction_of_main"| CTOR

    WTS -->|"weights"| CTOR
    WTS -->|"W_TO"| RQ

    CTOR -->|"main_pct"| G1

    G1 -->|"get.W_main_total: no arguments"| RQ

    CTOR -->|"nose_pct"| G2

    G2 -->|"get.W_nose_total: no arguments"| RQ

    G1 -->|"W_main_total"| G3

    K -->|"N_MAIN_WHEELS"| G3

    G2 -->|"W_nose_total"| G4

    K -->|"N_NOSE_WHEELS"| G4

    CTOR -->|"aircraft_category_table_row"| G5

    G3 -->|"W_w_main"| G5

    G5 -->|"get.tire_diameter_main: aircraft_category_table_row"| S3
    G5 -->|"get.tire_diameter_main: A_d, B_d, W_w_main"| S1

    CTOR -->|"aircraft_category_table_row"| G6

    G3 -->|"W_w_main"| G6

    G6 -->|"get.tire_width_main: aircraft_category_table_row"| S3
    G6 -->|"get.tire_width_main: A_w, B_w, W_w_main"| S2

    CTOR -->|"nose_tire_fraction_of_main"| G7

    G5 -->|"tire_diameter_main"| G7

    CTOR -->|"nose_tire_fraction_of_main"| G8

    G6 -->|"tire_width_main"| G8

    RQ -->|"requireWTO: no toolbox call"| NC

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 3,5,7,8,9,10,11,12,15,16,19,20,21,22 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 13,14,17,18 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 2,4,6 stroke:#ffe100,color:#ffe100,stroke-width:2px
    linkStyle 23 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:5 4

    classDef ctorWork fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef funcWork fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef injectorWork fill:#000000,stroke:#ff44cc,stroke-width:3px,color:#ff44cc
    classDef passthroughRelay fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 5 4
    classDef deadWork fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040
    class CTOR ctorWork
    class S1,S2,S3 funcWork
    class G1,G2,G3,G4,G5,G6,G7,G8 injectorWork
    class NC,RQ passthroughRelay
    class M1 deadWork
```

## Field-by-field notes

Values at `W_TO` = 31,377 lbf set on the injected weights object.

| Class member | Source | Value / note |
| --- | --- | --- |
| `aircraft_category_table_row` | `f16a_L3.json` `.subsystems.landing_gear.tire_sizing` | `Jet fighter/trainer`, Raymer's printed row name |
| `main_pct`, `nose_pct` | `.gear_load_split` | 90, 10. Raymer 6th ed. Ch. 11 p.344 prose |
| `nose_tire_fraction_of_main` | `.nose_tire_fraction_of_main` | 0.80, the midpoint of Raymer's 60-100 % range |
| `N_MAIN_WHEELS`, `N_NOSE_WHEELS` | Constants | 2, 1 |
| `weights` | Injected, required | Supplies `W_TO`. `requireWTO` raises `F16LandingGearL3:WTONotSet` while it is `NaN` or non-positive. |
| Tire coefficients | `lookup_tire_sizing_coeffs('Jet fighter/trainer')` | `A_d` 1.59, `B_d` 0.302, `A_w` 0.0980, `B_w` 0.467 |
| `W_main_total`, `W_nose_total` | Computed | 28,239.30 lbf, 3137.70 lbf |
| `W_w_main`, `W_w_nose` | Computed | 14,119.65 lbf, 3137.70 lbf |
| `tire_diameter_main`, `tire_width_main` | Computed | 28.4868 in, 8.4956 in |
| `tire_diameter_nose`, `tire_width_nose` | Computed | 22.7895 in, 6.7965 in |

## Methods with no upstream call at L3

| Member | Home | Note |
| --- | --- | --- |
| `bay_volume` | `F16LandingGearL3` | Errors with `F16LandingGearL3:bayVolumeNotAvailable`: no textbook bay-volume packaging formula exists in this repo. `TestF16LandingGearL2` calls it only to check the error. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/landing_gear/F16LandingGearL3.m` |
| Toolbox | `src/disciplines/landing_gear/landinggearL2.m` |
| Injected weights | `examples/F16A/models/disciplines/weights/F16WeightsL3.m` |
| Input JSON | `examples/F16A/inputs/f16a_L3.json` |
