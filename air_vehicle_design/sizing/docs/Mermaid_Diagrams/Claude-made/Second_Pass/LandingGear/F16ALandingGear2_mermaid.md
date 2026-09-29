# F16LandingGearL2: input-to-output data flow

This chart shows the data path for `F16LandingGearL2`, the Level 2 landing-gear class. It
splits the gross weight between main and nose gear, sizes the tires from Raymer's statistical
table, and finds and checks the tipback angle.

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
- **THERE IS NO ENFORCER.** `F16LandingGearL2` subclasses `handle` directly. The
  `landinggearModelL2` enforcer is not wired to it, so it is not drawn. The tire
  and tipback statics live in the `landinggearL2` toolbox.
- **`get_tipback_angle` holds its own literals**: the four MAC leading-edge
  stations and the two gear stations. See the notes table. Everything else comes
  through the injected weights object, including `weights.geom` and
  `weights.prop`.
- **`check_tipback_angle` takes the angle from its caller**, not from
  `get_tipback_angle`. `run_sizing_report_L2` calls the two in turn.
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
        J["f16a_L2.json"]
        WTS["Injected weights<br/>F16WeightsL2"]
        K["F16LandingGearL2 constants"]
    end

    subgraph CLASS["F16LandingGearL2 (Tier 3, no enforcer)"]
        direction TB

        CTOR["Constructor<br/>F16LandingGearL2(json_path, weights)<br/>in: json_path, weights, both required<br/>out: aircraft_category_table_row, main_pct, nose_pct,<br/>nose_tire_fraction_of_main, weights"]

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
            GT["get_tipback_angle(obj)<br/>in: weights (prop, geom, component weights)<br/>out: tipback_angle"]
            CK["check_tipback_angle(obj, tipback_angle)<br/>in: tipback_angle<br/>out: isTipBackAngleSatisfied"]
            RQ["requireWTO(obj)<br/>PRIVATE<br/>in: weights.W_TO<br/>out: W_TO"]
            M1["bay_volume(obj)<br/>ALWAYS ERRORS, citation gap<br/>NO UPSTREAM CALL at L2"]
        end
    end

    subgraph STAT["landinggearL2 statics (toolbox)"]
        S1["tire_diameter(A, B, W_w)<br/>out: tire diameter<br/>Raymer 6th ed. Table 11.1, p.344"]
        S2["tire_width(A, B, W_w)<br/>out: tire width<br/>Raymer 6th ed. Table 11.1, p.344"]
        S3["lookup_tire_sizing_coeffs(table_row)<br/>out: A_d, B_d, A_w, B_w<br/>Raymer 6th ed. Table 11.1, p.344"]
        TB["compute_tipback_angle(cg_loc, main_wheel_loc)<br/>out: tipback_angle<br/>Raymer 6th ed. Fig. 11.5, p.342"]
        TC["check_tipback_angle(tipback_angle)<br/>out: true if 15 < angle < 25 deg<br/>Raymer 6th ed. p.345"]
    end

    subgraph OTH["Other statics called"]
        ENG["PropL2.engine_length_AB(T, M)<br/>out: L_eng<br/>Raymer 6th ed. Eq. 10.11"]
        MAC["GeometryBase.compute_mac(c_root, lambda)<br/>out: MAC<br/>Raymer 7th ed. Eq. 7.8"]
        CGW["WeightsL2.compute_cg_x_loc_wing(x_root, MAC)<br/>out: x_cg<br/>Raymer 6th ed. Table 15.2"]
        CGF["WeightsL2.compute_cg_x_loc_fuselage(L_fus)<br/>out: x_cg_fus<br/>Raymer 6th ed. Table 15.2"]
        CGE["WeightsL2.compute_cg_x_loc_engine(x_eng, L_eng)<br/>out: x_cg_eng<br/>Raymer 6th ed. Table 15.2"]
        WCG["StabControlBase.compute_weighted_cg(weights_vec, x_vec)<br/>out: cg_x<br/>weighted-average CG identity"]
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

    WTS -->|"prop.T_SL, design_mach, geom.cbar_wing, geom.cbar_strake,<br/>geom.c_root_ht, geom.lambda_ht, geom.c_root_vt, geom.lambda_vt, geom.L_fus,<br/>W_wings, W_tail.HT, W_tail.VT, W_fuselage, W_landing_gear,<br/>W_installed_engine, W_strake"| GT

    GT -->|"get_tipback_angle: T_SL, design_mach"| ENG
    GT -->|"get_tipback_angle: c_root_ht, lambda_ht; c_root_vt, lambda_vt"| MAC
    GT -->|"get_tipback_angle: x_le_mac and MAC for wing, HT, VT, strake"| CGW
    GT -->|"get_tipback_angle: L_fus"| CGF
    GT -->|"get_tipback_angle: L_fus - L_eng, L_eng"| CGE
    GT -->|"get_tipback_angle: component weights, component x_cg"| WCG
    GT -->|"get_tipback_angle: cg_loc = [cg_x, 0], maingear_loc"| TB

    CK -->|"check_tipback_angle: tipback_angle"| TC

    RQ -->|"requireWTO: no toolbox call"| NC

    linkStyle 0,1 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 3,5,7,8,9,10,11,12,15,16,19,20,21,22 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 13,14,17,18,23,24,25,26,27,28,29,30,31 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 2,4,6 stroke:#ffe100,color:#ffe100,stroke-width:2px
    linkStyle 32 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:5 4

    classDef ctorWork fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef funcWork fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef injectorWork fill:#000000,stroke:#ff44cc,stroke-width:3px,color:#ff44cc
    classDef passthroughRelay fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 5 4
    classDef deadWork fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040
    class CTOR ctorWork
    class GT,CK,S1,S2,S3,TB,TC,ENG,MAC,CGW,CGF,CGE,WCG funcWork
    class G1,G2,G3,G4,G5,G6,G7,G8 injectorWork
    class NC,RQ passthroughRelay
    class M1 deadWork
```

## Field-by-field notes

Tire values at `W_TO` = 31,377 lbf set on the injected weights object.

| Class member | Source | Value / note |
| --- | --- | --- |
| `aircraft_category_table_row` | `f16a_L2.json` `.subsystems.landing_gear.tire_sizing` | `Jet fighter/trainer`, Raymer's printed row name |
| `main_pct`, `nose_pct` | `.gear_load_split` | 90, 10. Raymer 6th ed. Ch. 11 p.344 prose |
| `nose_tire_fraction_of_main` | `.nose_tire_fraction_of_main` | 0.80, the midpoint of Raymer's 60-100 % range |
| `N_MAIN_WHEELS`, `N_NOSE_WHEELS` | Constants | 2, 1 |
| `weights` | Injected, required | Supplies `W_TO`, the component weights, `design_mach`, `geom` and `prop`. `requireWTO` raises `F16LandingGearL2:WTONotSet` while `W_TO` is `NaN` or non-positive. |
| Tire coefficients | `lookup_tire_sizing_coeffs('Jet fighter/trainer')` | `A_d` 1.59, `B_d` 0.302, `A_w` 0.0980, `B_w` 0.467 |
| `W_main_total`, `W_nose_total` | Computed | 28,239.30 lbf, 3137.70 lbf |
| `W_w_main`, `W_w_nose` | Computed | 14,119.65 lbf, 3137.70 lbf |
| `tire_diameter_main`, `tire_width_main` | Computed | 28.4868 in, 8.4956 in |
| `tire_diameter_nose`, `tire_width_nose` | Computed | 22.7895 in, 6.7965 in |

Tipback values from the converged L2 sizing run, `W_TO` = 23,279.4 lbf. Stations are ft aft of the nose.

| Item | Source | Value |
| --- | --- | --- |
| `x_le_mac_wing`, `_ht`, `_vt`, `_strake` | `get_tipback_angle` literals | 23.3, 39.8, 38.8, 12.0 ft |
| `x_cg_lg_nose`, `x_cg_lg_main` | `get_tipback_angle` literals | 15.5264, 30.5677 ft |
| `x_cg_lg` | `(x_cg_lg_nose + 2 x_cg_lg_main)/3` | 25.554 ft |
| `maingear_loc` | `[x_cg_lg_main, -4.3668]` | y is ft below the longitudinal axis |
| Component x_cg | Computed | wing 26.759, HT 41.015, VT 39.909, fuselage 23.250, gear 25.554, engine 38.789, strake 13.947 ft |
| `cg_x` | `compute_weighted_cg` | 29.2599 ft |
| `tipback_angle` | `compute_tipback_angle` | 16.6721 deg, check passes |

## Methods with no upstream call at L2

| Member | Home | Note |
| --- | --- | --- |
| `bay_volume` | `F16LandingGearL2` | Errors with `F16LandingGearL2:bayVolumeNotAvailable`: no textbook bay-volume packaging formula exists in this repo. `TestF16LandingGearL2` calls it only to check the error. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/landing_gear/F16LandingGearL2.m` |
| Toolbox | `src/disciplines/landing_gear/landinggearL2.m` |
| Other statics | `src/disciplines/weights/WeightsL2.m`, `src/base/StabControlBase.m`, `src/disciplines/propulsion/PropL2.m`, `src/base/GeometryBase.m` |
| Injected weights | `examples/F16A/models/disciplines/weights/F16WeightsL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
| Tipback caller | `examples/F16A/studies/run_sizing_report_L2.m` |
