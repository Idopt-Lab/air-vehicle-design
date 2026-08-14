# F16PropL1: input-to-output data flow

This chart shows the data path for `F16PropL1`, the Level 1 (L1) propulsion
class. L1 is a density-ratio thrust lapse and a two-value TSFC table: no Mach
term in the lapse, no afterburner split, no supersonic value.

This is the smallest class in the set. It reads two JSON fields, has one
derived property, and every method is a single delegation line.

**Read this first.**
- The chart runs TOP TO BOTTOM. The class is small, so the vertical form
  reads better.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the
  field names.
- The constructor is cyan. Every other function is green. Yellow dashed marks
  a getter that calls nothing.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes. Every `PropL1` static is reached.
- Two method PAIRS do the same job, and both members of each pair are live
  and correct. `thrust_lapse` and `get_thrust_lapse` both call
  `PropL1.get_thrust_lapse`; `get_TSFC` and `lookup_TSFC` both call
  `PropL1.get_TSFC`. This is not an accident: `PropulsionBase` requires the
  names `thrust_lapse` and `get_TSFC`, while `PropulsionModelL1` requires
  `get_thrust_lapse` and `lookup_TSFC`. Two contracts name the same two
  quantities differently, so the class satisfies both.
- `thrust_lapse_mil_on_AB_scale` is INHERITED from `PropulsionBase`, not
  defined here. Its default is the afterburner-basis lapse, which is correct
  for a class with no separate mil-power model. `F16PropL2` overrides it.
- `T_SL_wet` is an alias of `T_SL`, not a second input. Both used to be stored
  and settable, so an optimizer changing one left the other stale.

```mermaid
flowchart TD
    subgraph SRC["Sources"]
        J["f16a_L1.json"]
        ST["AircraftState<br/>state"]
    end

    subgraph CLASS["F16PropL1 (Tier 3)"]
        direction TB

        CTOR["Constructor<br/>F16PropL1(json_path)<br/>in: json_path<br/>out: engine_type, T_SL"]

        D1["get.T_SL_wet<br/>in: T_SL<br/>out: T_SL_wet = T_SL (alias)"]

        subgraph LAPSE["Thrust lapse"]
            M1["thrust_lapse(obj, state)<br/>required by PropulsionBase<br/>in: engine_type, state.rho<br/>out: alpha"]
            M2["get_thrust_lapse(obj, state)<br/>required by PropulsionModelL1<br/>in: engine_type, state.rho<br/>out: alpha"]
            M5["thrust_lapse_mil_on_AB_scale(obj, state)<br/>INHERITED from PropulsionBase<br/>in: state<br/>out: alpha, the AB-basis default"]
        end

        subgraph FUEL["TSFC"]
            M3["get_TSFC(obj, state)<br/>required by PropulsionBase<br/>in: engine_type, state.mach<br/>out: c_t [1/hr]"]
            M4["lookup_TSFC(obj, state)<br/>required by PropulsionModelL1<br/>in: engine_type, state.mach<br/>out: c_t [1/hr]"]
        end
    end

    subgraph TOOL["PropL1 toolbox (static methods)"]
        T1["get_thrust_lapse(obj, state)<br/>Martins metabook Eq. 10.7 and 10.9"]
        T2["get_TSFC(obj, state)<br/>M < 0.4 gives loiter, else cruise"]
        T3["sigma_lapse(rho, m)<br/>alpha = (rho/rho_SL)^m"]
        T4["lookup_lapse_exponent(engine_type)<br/>1.0 turbojet, 0.6 turbofan"]
        T5["lookup_TSFC_table(engine_type)<br/>Raymer 6th ed. Table 3.3"]
    end

    J -->|"propulsion: engine_type = low_bypass_turbofan_AB,<br/>T_SL = 23770 lbf"| CTOR

    CTOR -->|"T_SL"| D1
    CTOR -->|"engine_type"| M1
    ST -->|"state.rho"| M1
    CTOR -->|"engine_type"| M2
    ST -->|"state.rho"| M2
    CTOR -->|"engine_type"| M3
    ST -->|"state.mach"| M3
    CTOR -->|"engine_type"| M4
    ST -->|"state.mach"| M4
    M1 -->|"alpha, the AB-basis lapse"| M5
    ST -->|"state"| M5

    M1 -->|"thrust_lapse: obj, state"| T1
    M2 -->|"get_thrust_lapse: obj, state"| T1
    M3 -->|"get_TSFC: obj, state"| T2
    M4 -->|"lookup_TSFC: obj, state"| T2

    T1 -->|"get_thrust_lapse: engine_type"| T4
    T1 -->|"get_thrust_lapse: state.rho, m"| T3
    T2 -->|"get_TSFC: engine_type"| T5

    linkStyle 0 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 1 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class CTOR ctor
    class M1,M2,M3,M4,M5,T1,T2,T3,T4,T5 func
    class D1 passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `engine_type` | `f16a_L1.json`, `.propulsion.engine_type` | `low_bypass_turbofan_AB`, an F100-PW-200 class engine. Selects both the lapse exponent (0.6) and the TSFC row. |
| `T_SL` | `.propulsion.T_SL` | 23,770 lbf, afterburner sea-level static thrust. Brandt Main!D29 and T.O. 1F-16A-1 Sec. I. |
| `T_SL_wet` (Dependent) | `T_SL` | An alias. Was a stored input duplicating `T_SL` in both the class and the JSON, so the two could diverge under an optimizer. |
| `TSFC` | Removed 2026-07-25 | Used to be a `TSFC = 0` placeholder satisfying an abstract property. TSFC depends on the flight state, so it is a method, not a property. |
| `alpha` at 36 kft, M 0.87 | Computed | About 0.484, from the density ratio alone. There is no Mach correction at L1. |
| `c_t` | `PropL1.lookup_TSFC_table` | 0.80 1/hr cruise, 0.70 1/hr loiter. The M = 0.4 split is an L1 approximation, because the segment type is not carried in `AircraftState`. |
| `rho_SL` | `PropL1`, private constant | 0.002377 slug/ft^3, hardcoded in the toolbox. Two TODOs, dated 2026-07-13 and 2026-08-14, both say sea-level standard conditions should be their own class. |

## Methods with no upstream call at L1

None. Every `PropL1` static is reached: the two high-level wrappers by the
class, and the three low-level statics by those wrappers.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/prop/F16PropL1.m` |
| Tier 2, abstract | `src/disciplines/propulsion/PropulsionModelL1.m` |
| Tier 1, base | `src/base/PropulsionBase.m` |
| Toolbox | `src/disciplines/propulsion/PropL1.m` |
| Input JSON | `examples/F16A/inputs/f16a_L1.json` |
