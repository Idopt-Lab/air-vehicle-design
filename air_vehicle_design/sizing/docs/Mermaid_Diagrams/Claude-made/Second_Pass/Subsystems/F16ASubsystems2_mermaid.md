# F16SubsystemsL2: input-to-output data flow

This chart shows the data path for `F16SubsystemsL2`, the Level 2 (L2)
subsystems class. L2 is the first tier with real geometry: fuselage volume comes
from the injected geometry's envelope ellipse, wing fuel volume from the wing
planform. Two collaborators are injected and both are required.

## Viewing this chart with pan and zoom

Mermaid inside a `.md` renders at a fixed size, so a wide chart is hard to read
in a plain preview. Open `docs/Mermaid_Diagrams/viewer.html` and drag this file
onto it. Wheel or pinch zooms, drag pans, and `f` fits.

The viewer reads the first mermaid fenced block straight out of this file, so
there is no second copy of the diagram to keep in step.

**Read this first.**
- The chart runs LEFT TO RIGHT. The class is wide, so the horizontal form reads
  on a 1920x1080 screen.
- One function per node. Name, inputs, output, citation. Returned values and
  coefficients live in the notes table, not in the labels.
- No grouped "Inputs" node. Every value rides the arrow that carries it. A
  source node holds only a file or object name.
- **Colour says what kind of member a node is; dash says whether the value was
  worked on.** A box whose body reads a stored field and returns it is a pure
  relay, so it is dashed, and so is every line leaving it. A box that evaluates
  an equation, reads a table, or combines its inputs is solid.
- **A line's colour comes from the node it POINTS AT; its dash comes from the
  node it LEAVES.** A file or object source node is not a method, so it takes
  the dash of the member it feeds.
- Constructor cyan. Every other function green. An INJECTOR, meaning any
  `get.<name>` property getter, is magenta, and magenta beats every other node
  colour.
- **EVERY MEMBER OF THIS CLASS WORKS.** The only red node is
  `compute_battery_volume`, a toolbox static that errors by design.
- **THE STATICS SIT IN THREE HOMES.** `SubsystemsBase` holds the fuel-density
  tables. `SubsystemsL1` holds the avionics equations and the Raymer Table 11.6
  row lookup. `SubsystemsL2` holds the geometry and packaging statics. Three
  toolbox subgraphs.
- **NINE INJECTORS**, one per `Dependent` property. Four forward to a same-named
  method and are dashed relays: `get.fuel_density`, `get.fuselage_fuel_volume`,
  `get.total_design_volume` and `get.total_fuel_volume_occupied`.
- **TWO INJECTORS DUPLICATE A METHOD BODY rather than calling it.**
  `get.avionics_weight_fraction` repeats `get_avionics_weight_fraction`, and
  `get.wing_fuel_volume` repeats `get_wing_fuel_volume_available`. Both pairs
  agree.
- **`get.avionics_weight` AND `get.total_avionics_volume_occupied` ALSO DUPLICATE
  their `_categorical` methods.** The getters read the injected weights object;
  the methods take `W_empty` as an argument. Both routes give the same answer.
- **NOTHING CALLS THE `SubsystemsModelL2` BRIDGES**, so they are not drawn. Both
  are broken, and all three callers of those names are L1 objects. See the note
  below.
- There are NO yellow nodes.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        GEOM["Injected geometry<br/>F16GeomL2"]
        WTS["Injected weights<br/>F16WeightsL2"]
    end

    subgraph CLASS["F16SubsystemsL2 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16SubsystemsL2(json_path, geom, fuel_weight_source)<br/>in: json_path, geom, fuel_weight_source<br/>out: fuel_type, packaging_factor_category, avionics_table_row"]

        subgraph INJ["Injectors (Dependent getters)"]
            G1["get.avionics_weight_fraction<br/>in: avionics_table_row<br/>out: fraction"]
            G2["get.avionics_density<br/>out: 37.5 lb/ft^3"]
            G3["get.avionics_weight<br/>in: fraction, OEW(W_TO)<br/>out: W_avionics"]
            G4["get.total_avionics_volume_occupied<br/>in: W_avionics, AVIONICS_DENSITY<br/>out: avionics volume"]
            G5["get.fuel_density<br/>out: density"]
            G6["get.wing_fuel_volume<br/>in: wing planform<br/>out: wing fuel volume"]
            G8["get.fuselage_fuel_volume<br/>out: usable fuselage fuel volume"]
            G9["get.total_design_volume<br/>out: wing fuel + fuselage raw"]
            G10["get.total_fuel_volume_occupied<br/>in: W_energy<br/>out: fuel volume occupied"]
        end

        subgraph MTH["Methods"]
            M1["get_avionics_weight_fraction(obj)<br/>in: avionics_table_row<br/>out: fraction"]
            M2["get_avionics_weight_categorical(obj, W_empty)<br/>in: fraction, W_empty<br/>out: W_avionics"]
            M3["get_total_avionics_volume_categorical(obj, W_empty)<br/>in: W_avionics, AVIONICS_DENSITY<br/>out: avionics volume"]
            M4["get_wing_fuel_volume_available(obj)<br/>in: wing planform<br/>out: wing fuel volume"]
            M5["get_fuselage_internal_volume(obj)<br/>in: L_fus, W_max_fuselage, H_max_fuselage<br/>out: raw fuselage volume"]
            M6["get_fuselage_fuel_volume(obj)<br/>in: raw volume, packaging factor<br/>out: usable fuselage fuel volume"]
            M7["get_fuel_volume_available(obj)<br/>in: wing fuel volume, fuselage fuel volume<br/>out: total available"]
            M8["get_total_fuel_volume_occupied(obj, fuel_weight_lb)<br/>in: fuel_weight_lb, fuel_density<br/>out: volume occupied"]
            M9["get_total_design_volume(obj)<br/>in: wing fuel volume, raw fuselage volume<br/>out: sum"]
            M10["fuel_volume_check(obj, fuel_weight_lb)<br/>in: occupied, available<br/>out: struct"]
            M11["get_fuel_density(obj)<br/>in: fuel_type<br/>out: density"]
        end
    end

    subgraph TB1["SubsystemsBase"]
        TB_C["lookup_fuel_density_lb_per_ft_3(fuel_type)<br/>in: fuel_type<br/>out: density<br/>Nicolai and Carichner Table 8.6 p.210"]
    end

    subgraph TL1["SubsystemsL1 toolbox"]
        TL1_A["lookup_avionics_weight_fraction_range(aircraft_category)<br/>in: avionics_table_row<br/>out: [low, high]<br/>Raymer 6th ed. Table 11.6 p.375"]
        TL1_B["compute_avionics_weight(avi_WF, W_empty)<br/>in: avi_WF, W_empty<br/>out: W_avionics<br/>Raymer 6th ed. Table 11.6 p.375"]
        TL1_C["compute_avionics_volume(W_avionics, density)<br/>in: W_avionics, density<br/>out: volume<br/>Raymer 6th ed. Ch.11 p.375"]
    end

    subgraph TL2["SubsystemsL2 toolbox"]
        T5["compute_wing_fuel_volume_roskam(S, b, tc_r, tc_t, lambda)<br/>in: wing planform<br/>out: wing fuel volume<br/>Roskam Part II Eq. 6.2/6.3"]
        T6["compute_envelope_projected_areas(L_fus, W_max, H_max)<br/>in: fuselage envelope<br/>out: A_top, A_side"]
        T7["compute_fuselage_volume_raymer(A_top, A_side, L_fus)<br/>in: A_top, A_side, L_fus<br/>out: raw fuselage volume<br/>Raymer 6th ed. Eq. 7.14"]
        T8["lookup_packaging_factor_nicolai(category)<br/>in: packaging_factor_category<br/>out: packaging factor<br/>Nicolai and Carichner p.210"]
        T9["fuel_volume_check(required, available)<br/>in: required, available<br/>out: struct"]
        T10["compute_battery_volume(E_required_kWh)<br/>CITATION GAP, always errors"]
    end

    J -->|"subsystems.fuel.fuel_type, packaging_factor_category"| CTOR
    J -->|"subsystems.avionics.aircraft_category_table_row"| CTOR
    GEOM -->|"injected object"| CTOR
    WTS -->|"injected object"| CTOR

    CTOR -->|"avionics_table_row"| M1
    CTOR -->|"avionics_table_row"| G1
    CTOR -->|"fuel_type"| M11
    CTOR -->|"packaging_factor_category"| M6
    GEOM -->|"S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing"| G6
    GEOM -->|"S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing"| M4
    GEOM -->|"L_fus, W_max_fuselage, H_max_fuselage"| M5
    WTS -->|"get_OEW(W_TO)"| G3
    WTS -.->|"W_energy"| G10

    G1 -->|"lookup_avionics_weight_fraction_range: avionics_table_row"| TL1_A
    G3 -->|"compute_avionics_weight: fraction, W_empty"| TL1_B
    G4 -->|"compute_avionics_volume: W_avionics, AVIONICS_DENSITY"| TL1_C
    G5 -.->|"get_fuel_density"| M11
    G6 -->|"compute_wing_fuel_volume_roskam: wing planform"| T5
    G8 -.->|"get_fuselage_fuel_volume"| M6
    G9 -.->|"get_total_design_volume"| M9
    G10 -.->|"get_total_fuel_volume_occupied: W_energy"| M8

    M1 -->|"lookup_avionics_weight_fraction_range: avionics_table_row"| TL1_A
    M2 -->|"get_avionics_weight_fraction"| M1
    M2 -->|"compute_avionics_weight: avi_WF, W_empty"| TL1_B
    M3 -->|"get_avionics_weight_categorical: W_empty"| M2
    M3 -->|"compute_avionics_volume: avi_weight, AVIONICS_DENSITY"| TL1_C
    M4 -->|"compute_wing_fuel_volume_roskam: wing planform"| T5
    M5 -->|"compute_envelope_projected_areas: L_fus, W_max_fuselage, H_max_fuselage"| T6
    M5 -->|"compute_fuselage_volume_raymer: A_top, A_side, L_fus"| T7
    M6 -->|"get_fuselage_internal_volume"| M5
    M6 -->|"lookup_packaging_factor_nicolai: packaging_factor_category"| T8
    M7 -->|"wing_fuel_volume property"| G6
    M7 -->|"get_fuselage_fuel_volume"| M6
    M8 -->|"fuel_density property"| G5
    M9 -->|"get_wing_fuel_volume_available"| M4
    M9 -->|"get_fuselage_internal_volume"| M5
    M10 -->|"get_total_fuel_volume_occupied: fuel_weight_lb"| M8
    M10 -->|"get_fuel_volume_available"| M7
    M10 -->|"fuel_volume_check: required, available"| T9
    M11 -->|"lookup_fuel_density_lb_per_ft_3: fuel_type"| TB_C

    linkStyle 0,1,2,3 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 4,6,7,9,10,13,14,15,17,21,22,23,24,25,26,27,28,29,30,32,34,35,36,37,38,39 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 5,8,11,31,33 stroke:#ff00ff,color:#ff00ff,stroke-width:2px
    linkStyle 12 stroke:#ff00ff,color:#ff00ff,stroke-width:2px,stroke-dasharray:5 5
    linkStyle 16,18,19,20 stroke:#33cc33,color:#33cc33,stroke-width:2px,stroke-dasharray:5 5

    classDef ctorWork fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef funcWork fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef injWork fill:#000000,stroke:#ff00ff,stroke-width:2px,color:#ff00ff
    classDef injRelay fill:#000000,stroke:#ff00ff,stroke-width:2px,color:#ff00ff,stroke-dasharray:5 5
    classDef deadPath fill:#000000,stroke:#ff3333,stroke-width:2px,color:#ff3333,stroke-dasharray:5 5
    class CTOR ctorWork
    class M1,M2,M3,M4,M5,M6,M7,M8,M9,M10,M11,T5,T6,T7,T8,T9,TB_C,TL1_A,TL1_B,TL1_C funcWork
    class G1,G2,G3,G4,G6 injWork
    class G5,G8,G9,G10 injRelay
    class T10 deadPath
```

## Values

| Member | Value |
| --- | --- |
| `avionics_weight_fraction` | 0.0550 |
| `avionics_density` | 37.5 lb/ft^3 |
| `avionics_weight` | 781.0460 lbf |
| `total_avionics_volume_occupied` | 20.8279 ft^3 |
| `fuel_density` | 50.0 lb/ft^3 |
| `wing_fuel_volume` | 55.0161 ft^3 |
| `fuselage_fuel_volume` | 682.6682 ft^3 |
| `total_design_volume` | 908.3513 ft^3 |
| `get_fuselage_internal_volume` | 853.3352 ft^3, RAW, no packaging factor |
| `get_fuel_volume_available` | 737.6843 ft^3 |
| `get_total_fuel_volume_occupied(14200.84)` | 284.0168 ft^3 |
| `total_fuel_volume_occupied` | 116.1840 ft^3 |
| `fuel_volume_check(5809.2)` | required 116.18, available 737.68, sufficient |

At `W_TO` 23279.4 lbf, `OEW(W_TO)` 14200.84 lbf, `W_energy` 5809.2 lbf.

## A getter cannot take an argument

`get.total_fuel_volume_occupied` needs a fuel weight, and a getter's one and
only argument IS the object: MATLAB fills that slot with the instance whatever
the parameter is named. So the weight has to come from something the object
already holds, which is why the getter reads
`obj.fuel_weight_source.W_energy`. `get.avionics_weight` does the same, reading
`ws.get_OEW(ws.W_TO)`.

Verified live rather than cached: mutating `W_energy` from 5809.2 to 7000 moves
the property to exactly 140.0000 ft^3, which is 7000 / 50.

## The SubsystemsModelL2 bridges are unreached

`SubsystemsModelL2` supplies two concrete bridges, `get_avionics_weight` and
`get_total_avionics_volume_occupied`. Both are broken: the first calls
`get_total_avionics_weight_categorical`, a name that exists nowhere, and the
second calls a one-argument method with no argument.

Neither has a caller. The three call sites that use those names
(`run_sizing_report_L1.m:113`, `:179` and `subsystems_brandt_comparison.m:97`)
all hold an `F16SubsystemsL1` object, which inherits the working L1 versions
instead. So they are unreached dead code in the enforcer, not a live defect in
the L2 path, and they are not drawn.

## Field-by-field notes

| Class member | Source | Value / note |
| --- | --- | --- |
| `fuel_type` | `f16a_L2.json` `.subsystems.fuel.fuel_type` | `JP-8` |
| `packaging_factor_category` | `.subsystems.fuel.packaging_factor_category` | `Integral tank — shallow fuselage`, factor 0.8000 |
| `avionics_table_row` | `.subsystems.avionics.aircraft_category_table_row` | `Fighters`, range `[0.03, 0.08]`, mean 0.0550 |
| `fuselage_packaging_factor_category` | class default | INERT. No member reads it. |
| `wing_packaging_factor_category` | class default | INERT. No member reads it. |
| `AVIONICS_DENSITY` | `SubsystemsL2` constant | `mean([30, 45])` = 37.5, the same Raymer range average `SubsystemsL1` holds. Nothing reaches Nicolai's flat 45. |

## `total_design_volume` sums two different quantities

`get_total_design_volume` adds `get_wing_fuel_volume_available`, a FUEL volume,
to `get_fuselage_internal_volume`, a RAW structural volume: 55.02 + 853.34 =
908.35 ft^3. The property comment still reads
`= fuselage_usable_fuel_volume + wing_fuel_volume`, which is a third thing
again.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/subsystems/F16SubsystemsL2.m` |
| Tier 2, abstract | `src/disciplines/subsystems/SubsystemsModelL2.m` |
| Tier 1, base | `src/base/SubsystemsBase.m` |
| Toolboxes | `src/disciplines/subsystems/SubsystemsL1.m`, `SubsystemsL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
