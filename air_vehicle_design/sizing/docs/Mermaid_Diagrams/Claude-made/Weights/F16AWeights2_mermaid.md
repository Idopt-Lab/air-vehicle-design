# F16WeightsL2: input-to-output data flow

This chart shows the data path for `F16WeightsL2`, the Level 2 (L2) weights
class. L2 is an area-based group buildup: Raymer Table 15.2 surface densities
on the exposed and wetted areas, plus metabook fractions for the landing gear,
the installed engine and the all-else-empty group.

L2 reads TWO JSON files and takes TWO injected objects. It stores no geometry
number and no engine number.

**Read this first.**
- The chart runs LEFT TO RIGHT.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the field
  names.
- The constructor is cyan. Every other function is green. Yellow dashed marks a
  getter that calls nothing.
- Every edge takes the color of the node it POINTS AT.
- There are NO red nodes. All 13 `WeightsL2` statics are reached.
- `design_mach` comes from the REQUIREMENTS file, not the spec file. It says
  what the aircraft must do, not what it is.
- `W_TO` enters from the sizing loop, not the JSON. Two getters demand a
  non-`NaN` value and error otherwise.
- `OEW` is OVERRIDDEN. It calls the toolbox sum, then adds `W_strake`. The
  strake is not in Raymer Table 15.2, so its coefficient comes from Brandt.
- `W_en` and `W_en_brandt` are NOT alternatives to pick between. `W_en` is the
  official uninstalled engine weight and is the only one that enters `OEW`.
  `W_en_brandt` is already installed, and it is for the comparison report only.
- The private `requireWTO` guard is not drawn, to match the geometry charts.
  The two getters that use it take their `W_TO` arrow straight from the loop.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        REQ["f16a_requirements.json"]
        GEOM["Injected object<br/>geom (GeometryModelL2 or L3)"]
        PROP["Injected object<br/>prop (PropulsionBase)"]
        SL["Sizing loop<br/>(mutates W_TO in place)"]
    end

    subgraph CLASS["F16WeightsL2 (Tier 3)"]
        direction LR

        CTOR["Constructor<br/>F16WeightsL2(json_path, req_path, geom, prop)<br/>in: all four, none defaulted<br/>out: aircraft_category, N_en, design_mach,<br/>payload weights, S_strake, k_strake,<br/>stored geom and prop handles"]

        G1["get.S_w, get.S_ht, get.S_vt, get.S_wet_fus<br/>in: geom<br/>out: three EXPOSED areas plus the fuselage WETTED area"]

        subgraph ENG["Engine weight"]
            E1["get.W_en<br/>in: prop.T_SL, design_mach, prop.bypass_ratio<br/>out: W_en = 2775.02, UNINSTALLED, Raymer Eq. 10.10"]
            E2["get.W_en_brandt<br/>in: prop.T_SL<br/>out: 4730.23, already installed, REPORT ONLY"]
        end

        subgraph GRP["Group weights"]
            W1["get.W_wings<br/>in: aircraft_category, S_w<br/>out: 1766.03 lbf"]
            W2["get.W_tail<br/>in: aircraft_category, S_ht, S_vt<br/>out: struct(HT = 199.39, VT = 216.72)"]
            W3["get.W_fuselage<br/>in: aircraft_category, S_wet_fus<br/>out: 3505.45 lbf"]
            W4["get.W_landing_gear<br/>in: aircraft_category, W_TO<br/>out: 0.033 times W_TO"]
            W5["get.W_installed_engine<br/>in: N_en, W_en<br/>out: 1.3 times N_en times W_en"]
            W6["get.W_all_else_empty<br/>in: W_TO<br/>out: 0.17 times W_TO"]
            W7["get.W_strake<br/>in: k_strake, S_strake<br/>out: 90.00 lbf"]
        end

        subgraph CON["Contract methods"]
            M1["OEW(obj, W_TO)<br/>OVERRIDE, adds W_strake<br/>in: W_TO, W_strake<br/>out: OEW [lbf]"]
            M2["weight_wing(obj, W_TO)<br/>in: obj<br/>out: wing weight"]
            M3["weight_tail(obj, W_TO)<br/>in: obj<br/>out: struct(HT, VT)"]
            M4["weight_fuselage(obj, W_TO)<br/>in: obj<br/>out: fuselage weight"]
            M5["weight_landing_gear(obj, W_TO)<br/>in: obj, W_TO<br/>out: landing-gear weight"]
        end
    end

    subgraph TOOL["WeightsL2 toolbox (static methods)"]
        T1["OEW(obj, W_TO)<br/>sums the seven groups"]
        T2["weight_wing(obj, ~)<br/>Raymer 6th ed. Table 15.2"]
        T3["weight_tail(obj, ~)<br/>Raymer 6th ed. Table 15.2"]
        T4["weight_fuselage(obj, ~)<br/>on WETTED area, Table 15.2"]
        T5["weight_landing_gear(obj, W_TO)<br/>AE481 metabook Sec. 7"]
        T6["weight_installed_engine(obj)<br/>1.3 times N_en times W_en"]
        T7["weight_all_else_empty(~, W_TO)<br/>0.17 times W_TO"]
        L1["wing_unit_weight(aircraft_category)<br/>9.0 lbf/ft^2"]
        L2["HT_unit_weight(aircraft_category)<br/>4.0 lbf/ft^2"]
        L3["VT_unit_weight(aircraft_category)<br/>5.3 lbf/ft^2"]
        L4["fus_unit_weight(aircraft_category)<br/>4.8 lbf/ft^2"]
        L5["LG_fraction(aircraft_category)<br/>0.033"]
        L6["engine_weight_brandt(T_AB_SLS)<br/>Brandt Wt!B11"]
    end

    subgraph TOOLP["PropL2 toolbox"]
        P1["engine_weight_AB(T, M, BPR)<br/>Raymer 7th ed. Eq. 10.10"]
    end

    J -->|"aircraft_category: jet_fighter"| CTOR
    J -->|"weights: N_en = 1, W_payload_fixed = 700,<br/>W_payload_expendable = 4400,<br/>S_strake_ft2 = 20.0, k_strake_psf = 4.5"| CTOR
    REQ -->|"design_mach = 2.0"| CTOR
    GEOM -->|"geom"| CTOR
    PROP -->|"prop"| CTOR

    CTOR -->|"geom"| G1
    CTOR -->|"k_strake, S_strake"| W7

    G1 -->|"S_w"| W1
    G1 -->|"S_ht, S_vt"| W2
    G1 -->|"S_wet_fus"| W3
    SL -->|"W_TO, must not be NaN"| W4
    SL -->|"W_TO, must not be NaN"| W6
    E1 -->|"W_en"| W5
    CTOR -->|"N_en"| W5
    CTOR -->|"aircraft_category"| W1
    CTOR -->|"aircraft_category"| W2
    CTOR -->|"aircraft_category"| W3
    CTOR -->|"aircraft_category"| W4

    PROP -->|"prop.T_SL, prop.bypass_ratio"| E1
    CTOR -->|"design_mach = 2.0"| E1
    PROP -->|"prop.T_SL"| E2

    SL -->|"W_TO"| M1
    W7 -->|"W_strake"| M1
    SL -->|"W_TO"| M2
    SL -->|"W_TO"| M3
    SL -->|"W_TO"| M4
    SL -->|"W_TO"| M5

    M1 -->|"OEW: obj, W_TO"| T1
    M2 -->|"weight_wing: obj, W_TO"| T2
    M3 -->|"weight_tail: obj, W_TO"| T3
    M4 -->|"weight_fuselage: obj, W_TO"| T4
    M5 -->|"weight_landing_gear: obj, W_TO"| T5
    W1 -->|"get.W_wings: obj, obj.W_TO"| T2
    W2 -->|"get.W_tail: obj, obj.W_TO"| T3
    W3 -->|"get.W_fuselage: obj, obj.W_TO"| T4
    W4 -->|"get.W_landing_gear: obj, W_TO"| T5
    W5 -->|"get.W_installed_engine: obj"| T6
    W6 -->|"get.W_all_else_empty: obj, W_TO"| T7
    E1 -->|"get.W_en: T_SL, design_mach, bypass_ratio"| P1
    E2 -->|"get.W_en_brandt: T_SL"| L6

    T1 -->|"OEW: obj, W_TO"| T2
    T1 -->|"OEW: obj, W_TO"| T3
    T1 -->|"OEW: obj, W_TO"| T4
    T1 -->|"OEW: obj, W_TO"| T5
    T1 -->|"OEW: obj"| T6
    T1 -->|"OEW: obj, W_TO"| T7
    T2 -->|"weight_wing: aircraft_category"| L1
    T3 -->|"weight_tail: aircraft_category"| L2
    T3 -->|"weight_tail: aircraft_category"| L3
    T4 -->|"weight_fuselage: aircraft_category"| L4
    T5 -->|"weight_landing_gear: aircraft_category"| L5

    linkStyle 0,1,2,3,4 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 5,6 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class CTOR ctor
    class W1,W2,W3,W4,W5,W6,E1,E2,M1,M2,M3,M4,M5,T1,T2,T3,T4,T5,T6,T7,L1,L2,L3,L4,L5,L6,P1 func
    class G1,W7 passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `aircraft_category` | `f16a_L2.json`, top-level field | Selects five separate lookups: the four Table 15.2 surface densities and the metabook landing-gear fraction. |
| `N_en` | `.weights.N_en` | 1. Not derivable: no propulsion class exposes an engine count. `geom.n_engines` exists only as a geometry stopgap. |
| `design_mach` | `f16a_requirements.json`, `.design_mach` | 2.0, cited to Brandt. It is NOT the T.O. operating Mach limit, which is 2.05, a different number. Citing 2.0 to the T.O. would attribute a Brandt input to a document that says otherwise. The difference moves `W_en` by 0.62 percent. |
| `S_strake`, `k_strake` | `.weights.S_strake_ft2`, `.k_strake_psf` | 20 ft^2 and 4.5 lbf/ft^2, both Brandt. A deliberate cross-model borrow: Raymer Table 15.2 has no strake row, so no Raymer alternative exists. This is not the forbidden back-calculated pattern, because Brandt applies these as genuine inputs in his own worksheet. The strake was the largest single item in the earlier "NOT MODELED" gap, 13.68 percent of Brandt Wt!B12. |
| `W_TO`, `W_energy` | Sizing loop and mission analysis | `NaN` until set. `W_energy` was previously a back-calculated Brandt output and was deleted from the JSON. |
| Payload weights | `.weights` | INERT at every level. See S-29 in the findings log. |
| `S_w`, `S_ht`, `S_vt` (Dependent) | `geom.S_exposed_*` | EXPOSED areas, 196.23, 49.85 and 40.89. Not `geom.S_ht` = 108 or `geom.S_vt` = 60, which are FULL planform. |
| `S_wet_fus` (Dependent) | `geom.get_S_wet_fuselage()` | 730.30 ft^2. |
| `W_en` (Dependent) | `PropL2.engine_weight_AB` | 2775.02 lbf, uninstalled. Replaced a hardcoded 3030 estimate. |
| `W_en_brandt` (Dependent) | `WeightsL2.engine_weight_brandt` | 4730.23 lbf, already installed. Comparison report only, never summed into `OEW`. |
| `W_all_else_empty` (Dependent) | `0.17` times `W_TO` | Was frozen in the constructor at `W_TO` = 31,377, which is Brandt Wt!B3, a sizing OUTPUT. Two defects in one line: a forbidden input, and a value that went stale under mutation. At `W_TO` = 45,000 the frozen version understated the group by 2315.91 lbf. Every test called `OEW(31377)`, the one argument where the error is invisible. |
| `W_wings`, `W_landing_gear`, `W_tail`, `W_fuselage` | Now Dependent | All four were declared as computed totals, satisfied with `= NaN`, and never assigned, because the toolbox `OEW` computed them locally and discarded them. A consumer reading the documented contract got `NaN`. |

## Methods with no upstream call at L2

None. All 13 `WeightsL2` statics are reached.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/weights/F16WeightsL2.m` |
| Tier 2, abstract | `src/disciplines/weights/WeightsModelL2.m` |
| Tier 1, base | `src/base/WeightsBase.m` |
| Toolbox | `src/disciplines/weights/WeightsL2.m` |
| Toolbox, engine weight | `src/disciplines/propulsion/PropL2.m` |
| Injected geometry | `examples/F16A/models/disciplines/geom/F16GeomL2.m` |
| Injected propulsion | `examples/F16A/models/disciplines/prop/F16PropL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json`, `f16a_requirements.json` |
