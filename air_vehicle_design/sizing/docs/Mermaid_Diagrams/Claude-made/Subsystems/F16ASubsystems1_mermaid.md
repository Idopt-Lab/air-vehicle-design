# F16SubsystemsL1: input-to-output data flow

This chart shows the data path for `F16SubsystemsL1`, the Level 1 (L1)
subsystems class. L1 covers avionics weight and volume from a fraction of empty
weight, and fuel volume from a fuel-type density.

**Read this first.**
- The chart runs TOP TO BOTTOM.
- EVERY arrow carries a label naming the exact value it moves.
- The constructor is cyan. Green calls another function. Yellow dashed returns a
  constant and calls nothing. Red dashed has no upstream call.
- Every edge takes the color of the node it POINTS AT.
- The class reads only TWO JSON fields, both of them strings: a fuel type and a
  table row. Every number comes from a toolbox table.
- `fuselage_raw_volume` and `fuel_volume` return 0, HONESTLY. L1 has no
  geometry, so there is no envelope to derive a volume from. They are zero
  rather than absent so the contract holds at every level.
- `avionics_density` also returns a constant and ignores its object argument.
- `W_empty` is a call argument, not stored state. It arrives once per call at
  each public entry point.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L1.json"]
        WE["Caller<br/>(supplies W_empty and fuel weights as arguments)"]
    end

    subgraph CLASS["F16SubsystemsL1 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16SubsystemsL1(json_path)<br/>in: json_path<br/>out: fuel_type, avionics_table_row"]

        subgraph DER["Derived properties"]
            D1["get.avionics_weight_fraction<br/>in: avionics_table_row<br/>out: decided fraction of W_empty"]
            D2["get.avionics_density<br/>in: none<br/>out: a constant, Raymer Ch. 11 range midpoint"]
            D3["get.fuel_density<br/>in: fuel_type<br/>out: density [lbf/ft^3]"]
            D4["get.fuselage_raw_volume<br/>in: none<br/>out: 0, honestly, no geometry at L1"]
            D5["get.fuel_volume<br/>in: none<br/>out: 0, honestly, no geometry at L1"]
        end

        subgraph MET["Methods"]
            M1["avionics_weight(obj, W_empty)<br/>in: fraction, W_empty<br/>out: avionics weight [lbf]"]
            M2["avionics_volume(obj, W_empty)<br/>in: avionics weight, avionics density<br/>out: avionics volume [ft^3]"]
            M3["fuel_volume_from_weight(obj, fuel_weight_lb)<br/>in: fuel weight, fuel density<br/>out: fuel volume [ft^3]"]
            M4["internal_volume(obj, W_empty)<br/>in: avionics volume<br/>out: internal volume [ft^3]"]
            M5["fuel_volume_check(obj, required_weight_lb)<br/>in: required fuel volume, available volume<br/>out: struct of the comparison"]
        end
    end

    subgraph TOOL["SubsystemsL1 toolbox (static methods)"]
        T1["avionics_weight_fraction(obj)"]
        T2["avionics_density(obj)<br/>ignores obj, returns a constant"]
        T3["avionics_weight(obj, W_empty)"]
        T4["avionics_volume(obj, W_empty)"]
        T5["fuel_density(obj)"]
        T6["fuel_volume_from_weight(obj, fuel_weight_lb)"]
        T7["fuselage_raw_volume(obj)<br/>ignores obj, returns 0 at L1"]
        T8["fuel_volume(obj)<br/>ignores obj, returns 0 at L1"]
        T9["internal_volume(obj, W_empty)"]
        T10["fuel_volume_check(obj, required_weight_lb)"]
        L1["lookup_fuel_density(fuel_type)<br/>Nicolai and Carichner Table 8.6"]
        L2["lookup_avionics_weight_fraction(table_row)<br/>the row's range midpoint"]
        L3["lookup_avionics_weight_fraction_range(table_row)<br/>Raymer 6th ed. Table 11.6, p.375"]
        D6["lookup_fuel_density_lb_per_gal(fuel_type)<br/>NO PRODUCTION CALLER, tests only"]
    end

    subgraph TOOLB["SubsystemsBase toolbox"]
        B1["weight_to_volume(W_lb, density_lb_per_ft3)<br/>definitional, volume = weight / density"]
    end

    J -->|"subsystems.fuel.fuel_type = JP-8,<br/>subsystems.avionics.aircraft_category_table_row = Fighters"| CTOR

    CTOR -->|"avionics_table_row"| D1
    CTOR -->|"obj, ignored"| D2
    CTOR -->|"fuel_type"| D3
    CTOR -->|"obj, ignored"| D4
    CTOR -->|"obj, ignored"| D5

    WE -->|"W_empty"| M1
    D1 -->|"avionics_weight_fraction"| M1
    M1 -->|"avionics weight"| M2
    D2 -->|"avionics_density"| M2
    WE -->|"W_empty"| M2
    D3 -->|"fuel_density"| M3
    WE -->|"fuel_weight_lb"| M3
    M2 -->|"avionics_volume"| M4
    WE -->|"W_empty"| M4
    M3 -->|"required fuel volume"| M5
    D5 -->|"available fuel volume"| M5
    WE -->|"required_weight_lb"| M5

    D1 -->|"get.avionics_weight_fraction: obj"| T1
    D2 -->|"get.avionics_density: obj"| T2
    D3 -->|"get.fuel_density: obj"| T5
    D4 -->|"get.fuselage_raw_volume: obj"| T7
    D5 -->|"get.fuel_volume: obj"| T8
    M1 -->|"avionics_weight: obj, W_empty"| T3
    M2 -->|"avionics_volume: obj, W_empty"| T4
    M3 -->|"fuel_volume_from_weight: obj, fuel_weight_lb"| T6
    M4 -->|"internal_volume: obj, W_empty"| T9
    M5 -->|"fuel_volume_check: obj, required_weight_lb"| T10

    T1 -->|"avionics_weight_fraction: avionics_table_row"| L2
    L2 -->|"lookup_avionics_weight_fraction: table_row"| L3
    T3 -->|"avionics_weight: obj"| T1
    T4 -->|"avionics_volume: obj, W_empty"| T3
    T4 -->|"avionics_volume: obj"| T2
    T4 -->|"avionics_volume: avionics weight, avionics density"| B1
    T5 -->|"fuel_density: fuel_type"| L1
    T6 -->|"fuel_volume_from_weight: obj"| T5
    T6 -->|"fuel_volume_from_weight: fuel_weight_lb, fuel density"| B1
    T9 -->|"internal_volume: obj, W_empty"| T4
    T10 -->|"fuel_volume_check: obj, required_weight_lb"| T6

    L1 -.->|"no upstream call, per-gallon alternate"| D6

    linkStyle 0 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 19,21,22,32 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,20,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 39 stroke:#ff4040,color:#ff4040,stroke-width:2px,stroke-dasharray:5 5

    classDef dead fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040,stroke-dasharray: 6 4
    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class D6 dead
    class CTOR ctor
    class D1,D2,D3,D4,D5,M1,M2,M3,M4,M5,T1,T3,T4,T5,T6,T9,T10,L1,L2,L3,B1 func
    class T2,T7,T8 passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `fuel_type` | `f16a_L1.json`, `.subsystems.fuel.fuel_type` | `JP-8`. Selects the density row. |
| `avionics_table_row` | `.subsystems.avionics.aircraft_category_table_row` | `Fighters`. The row name Raymer prints. |
| `avionics_weight_fraction` (Dependent) | `lookup_avionics_weight_fraction` | The row's range MIDPOINT, a decided value, chosen over the legacy code's low-end value. |
| `avionics_density` (Dependent) | Toolbox constant | The mean of the Raymer range, hardcoded in the toolbox. The JSON also carries an `avionics.density_lb_per_ft3` key with the same number, and the constructor does not read it. |
| `fuel_density` (Dependent) | `lookup_fuel_density` | Nicolai and Carichner Table 8.6, in lbf per cubic foot. |
| `fuselage_raw_volume`, `fuel_volume` (Dependent) | Toolbox constants, 0 | Honest zeros. L1 has no geometry object and no envelope, so there is nothing to derive a volume from. Zero rather than absent keeps the base contract satisfied at every level. |
| `fuel_volume_check` | Method | Compares the required fuel volume against the available volume, which is 0 at L1. The check therefore always reports a shortfall at this tier. |
| Unread JSON keys | `.subsystems.fuel.density_lb_per_gal`, `.subsystems.avionics.weight_fraction`, `.subsystems.avionics.density_lb_per_ft3` | All three are present and none is read. The numbers come from toolbox tables instead. See S-35 in the findings log. |

## Methods with no upstream call at L1

| Method | Why |
| --- | --- |
| `SubsystemsL1.lookup_fuel_density_lb_per_gal` | The per-gallon density alternate. `fuel_density` uses the per-cubic-foot form. Called only by `TestSubsystemsL1`. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/subsystems/F16SubsystemsL1.m` |
| Tier 2, abstract | `src/disciplines/subsystems/SubsystemsModelL1.m` |
| Tier 1, base | `src/base/SubsystemsBase.m` |
| Toolbox | `src/disciplines/subsystems/SubsystemsL1.m` |
| Input JSON | `examples/F16A/inputs/f16a_L1.json` |
