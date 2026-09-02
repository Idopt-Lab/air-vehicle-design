# F16WeightsL2: input-to-output data flow

This chart shows the data path for `F16WeightsL2`, the Level 2 (L2) weights
class. L2 is an area-based group buildup: Raymer Table 15.2 surface densities
on the exposed and wetted areas, plus the Table 15.2 fraction sub-tables for
the landing gear, the installed engine and the all-else-empty group.

L2 reads TWO JSON files and takes TWO injected objects. It stores no geometry
number and no engine number.

**Read this first.**
- The chart runs LEFT TO RIGHT.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the field
  names.
- The constructor is cyan. Every other function is green.
- Every edge takes the color of the node it POINTS AT.
- THERE ARE NO RED NODES. Every live static is reached. The five getters that
  still named deleted statics were repointed on 2026-09-02, so reading a
  property and calling `get_OEW` now give the same number: the getter sum and
  `get_OEW(31377)` agree at 15844.648310 exactly.
- THE OBJECT-TAKING WRAPPERS ARE GONE. The first pass drew seven of them
  (`OEW`, `weight_wing`, `weight_tail`, `weight_fuselage`,
  `weight_landing_gear`, `weight_installed_engine`, `weight_all_else_empty`),
  each taking `obj`. Every live static now takes explicit scalars, so the
  buildup passes `aircraft_category` and an area or a `W_TO`.
- `OEW` IS NO LONGER AN OVERRIDE. `WeightsModelL2` supplies a concrete
  `get_OEW` bridge onto `get_OEW_major_component_buildup`, which sums the seven
  groups plus the strake itself. There is no toolbox `OEW` static to call.
- EVERY GEOMETRIC VALUE IS INJECTED. The five area getters read `geom`, and the
  `.weights` block now holds only `N_en` and the two payloads.
- `design_mach` comes from the REQUIREMENTS file, not the spec file. It says
  what the aircraft must do, not what it is.
- `W_TO` enters from the sizing loop, not the JSON. Two getters demand a
  non-`NaN` value and error otherwise.
- The strake takes the WING density, 9.0 psf on the exposed strake area, so it
  reads 180.00 lbf. Brandt's own coefficient is 4.5 psf, giving 90.00. That is
  a deliberate model choice and the one term that puts L2 off the 2026-08-18
  baseline.
- `W_en` and `W_en_brandt` are NOT alternatives to pick between. `W_en` is the
  official uninstalled engine weight and is the only one that enters the
  buildup. `W_en_brandt` is already installed, and it is for the comparison
  report only.
- The private `requireWTO` guard is not drawn, to match the geometry charts.
  The two getters that use it take their `W_TO` arrow straight from the loop.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        REQ["f16a_requirements.json"]
        GEOM["Injected object<br/>geom (GeometryModelL2)"]
        PROP["Injected object<br/>prop (PropulsionBase)"]
        SL["Sizing loop<br/>(mutates W_TO in place)"]
    end

    subgraph CLASS["F16WeightsL2 (Tier 3)"]
        direction LR

        CTOR["Constructor<br/>F16WeightsL2(json_path, req_path, geom, prop)<br/>in: all four, none defaulted<br/>out: aircraft_category, N_en, design_mach,<br/>payload weights,<br/>stored geom and prop handles"]

        subgraph AREA["Injected geometry"]
            G1["get.S_exposed_planform_wing<br/>in: geom<br/>out: 196.2261 ft^2, EXPOSED"]
            G2["get.S_exposed_planform_ht<br/>in: geom<br/>out: 49.8473 ft^2, EXPOSED"]
            G3["get.S_exposed_planform_vt<br/>in: geom<br/>out: 40.8897 ft^2, EXPOSED"]
            G4["get.S_exposed_planform_strakes<br/>in: geom<br/>out: 20.0000 ft^2, EXPOSED"]
            G5["get.S_wet_fus<br/>in: geom<br/>out: 730.3023 ft^2, WETTED"]
        end

        subgraph ENG["Engine weight"]
            E1["get.W_en<br/>in: prop.T_SL, design_mach, prop.bypass_ratio<br/>out: 2775.02 lbf, UNINSTALLED, Raymer Eq. 10.10"]
            E2["get.W_en_brandt<br/>in: prop.T_SL<br/>out: 4730.23 lbf, already installed, REPORT ONLY"]
        end

        subgraph GRP["Group weights"]
            W1["get.W_wings<br/>in: aircraft_category, S_exposed_planform_wing<br/>out: wing group [lbf]"]
            W2["get.W_tail<br/>in: aircraft_category, S_exposed_planform_ht, _vt<br/>out: struct(HT = 199.39, VT = 216.72)"]
            W3["get.W_fuselage<br/>in: aircraft_category, S_wet_fus<br/>out: fuselage group [lbf]"]
            W4["get.W_landing_gear<br/>in: aircraft_category, W_TO<br/>out: 0.033 times W_TO"]
            W5["get.W_installed_engine<br/>in: aircraft_category, N_en, W_en<br/>out: 1.3 times N_en times W_en"]
            W6["get.W_all_else_empty<br/>in: aircraft_category, W_TO<br/>out: 0.17 times W_TO"]
            W7["get.W_strake<br/>in: aircraft_category, S_exposed_planform_strakes<br/>out: 180.00 lbf"]
        end

        subgraph CON["Contract methods"]
            M0["get_OEW(obj, W_TO)<br/>INHERITED bridge from WeightsModelL2<br/>in: W_TO<br/>out: OEW [lbf]"]
            M1["get_OEW_major_component_buildup(obj, W_TO)<br/>required by WeightsModelL2<br/>in: aircraft_category, areas, N_en, W_en, W_TO<br/>out: OEW [lbf], sums seven groups plus the strake"]
            M2["get_wing_weight(obj, S_w_exposed)<br/>in: aircraft_category, S_w_exposed<br/>out: wing weight [lbf]"]
        end
    end

    subgraph TOOL["WeightsL2 toolbox (static methods)"]
        T1["compute_weight_wing(aircraft_category, S_w)<br/>Raymer 6th ed. Table 15.2"]
        T2["compute_weight_HT(aircraft_category, S_ht)<br/>Raymer 6th ed. Table 15.2"]
        T3["compute_weight_VT(aircraft_category, S_vt)<br/>Raymer 6th ed. Table 15.2"]
        T4["compute_weight_fuselage(aircraft_category, S_wet_fus)<br/>on WETTED area, Table 15.2"]
        T5["compute_weight_landing_gear(aircraft_category, W_TO, isNavy)<br/>Table 15.2 fraction sub-table"]
        T6["compute_weight_installed_engine(aircraft_category, N_en, W_en, isNavy)<br/>Table 15.2 fraction sub-table"]
        T7["compute_weight_all_else_empty(aircraft_category, W_TO, isNavy)<br/>Table 15.2 fraction sub-table"]
        L1["lookup_component_density(aircraft_category, component, unit_system)<br/>private, Raymer Table 15.2 density grid"]
        L2["lookup_weight_ratio(aircraft_category, component, isNavy)<br/>private, Table 15.2 fraction grid"]
        L3["engine_weight_brandt(T_AB_SLS)<br/>Brandt Wt!B11"]
    end

    subgraph TOOLP["PropL2 toolbox"]
        P1["engine_weight_AB(T, M, BPR)<br/>Raymer 7th ed. Eq. 10.10"]
    end

    J -->|"aircraft_category: jet_fighter"| CTOR
    J -->|"weights: N_en = 1, W_payload_fixed = 700,<br/>W_payload_expendable = 4400"| CTOR
    REQ -->|"design_mach = 2.0"| CTOR
    GEOM -->|"geom"| CTOR
    PROP -->|"prop"| CTOR

    GEOM -->|"geom.S_exposed_wing"| G1
    GEOM -->|"geom.S_exposed_ht"| G2
    GEOM -->|"geom.S_exposed_vt"| G3
    GEOM -->|"geom.S_exposed_strake"| G4
    GEOM -->|"geom.S_wet_fuselage"| G5

    PROP -->|"prop.T_SL, prop.bypass_ratio"| E1
    CTOR -->|"design_mach = 2.0"| E1
    PROP -->|"prop.T_SL"| E2

    SL -->|"W_TO, argument of the get_OEW call"| M0
    M0 -->|"get_OEW: W_TO"| M1
    CTOR -->|"aircraft_category, N_en"| M1
    E1 -->|"W_en"| M1
    G2 -->|"S_exposed_planform_ht"| M1
    G3 -->|"S_exposed_planform_vt"| M1
    G4 -->|"S_exposed_planform_strakes"| M1
    G5 -->|"S_wet_fus"| M1
    M1 -->|"get_wing_weight: S_exposed_planform_wing"| M2
    G1 -->|"S_exposed_planform_wing"| M2
    CTOR -->|"aircraft_category"| M2

    M2 -->|"compute_weight_wing: aircraft_category, S_w_exposed"| T1
    M1 -->|"compute_weight_wing: aircraft_category, S_exposed_planform_strakes"| T1
    M1 -->|"compute_weight_HT: aircraft_category, S_exposed_planform_ht"| T2
    M1 -->|"compute_weight_VT: aircraft_category, S_exposed_planform_vt"| T3
    M1 -->|"compute_weight_fuselage: aircraft_category, S_wet_fus"| T4
    M1 -->|"compute_weight_landing_gear: aircraft_category, W_TO, false"| T5
    M1 -->|"compute_weight_installed_engine: aircraft_category, N_en, W_en, false"| T6
    M1 -->|"compute_weight_all_else_empty: aircraft_category, W_TO, false"| T7

    CTOR -->|"aircraft_category"| W2
    G2 -->|"S_exposed_planform_ht"| W2
    G3 -->|"S_exposed_planform_vt"| W2
    W2 -->|"get.W_tail: aircraft_category, S_exposed_planform_ht"| T2
    W2 -->|"get.W_tail: aircraft_category, S_exposed_planform_vt"| T3

    CTOR -->|"aircraft_category"| W7
    G4 -->|"S_exposed_planform_strakes"| W7
    W7 -->|"get.W_strake: aircraft_category, S_exposed_planform_strakes"| T1

    CTOR -->|"aircraft_category"| W1
    G1 -->|"S_exposed_planform_wing"| W1
    CTOR -->|"aircraft_category"| W3
    G5 -->|"S_wet_fus"| W3
    CTOR -->|"aircraft_category"| W4
    SL -->|"W_TO, must not be NaN"| W4
    CTOR -->|"aircraft_category, N_en"| W5
    E1 -->|"W_en"| W5
    CTOR -->|"aircraft_category"| W6
    SL -->|"W_TO, must not be NaN"| W6

    E1 -->|"get.W_en: T_SL, design_mach, bypass_ratio"| P1
    E2 -->|"get.W_en_brandt: T_SL"| L3

    T1 -->|"compute_weight_wing: aircraft_category, wing, imperial"| L1
    T2 -->|"compute_weight_HT: aircraft_category, horizontal_tail, imperial"| L1
    T3 -->|"compute_weight_VT: aircraft_category, vertical_tail, imperial"| L1
    T4 -->|"compute_weight_fuselage: aircraft_category, fuselage, imperial"| L1
    T5 -->|"compute_weight_landing_gear: aircraft_category, landing_gear, isNavy"| L2
    T6 -->|"compute_weight_installed_engine: aircraft_category, installed_engine, isNavy"| L2
    T7 -->|"compute_weight_all_else_empty: aircraft_category, all_else_empty, isNavy"| L2

    W1 -->|"get.W_wings: aircraft_category, S_exposed_planform_wing"| T1
    W3 -->|"get.W_fuselage: aircraft_category, S_wet_fus"| T4
    W4 -->|"get.W_landing_gear: aircraft_category, requireWTO, false"| T5
    W5 -->|"get.W_installed_engine: aircraft_category, N_en, W_en, false"| T6
    W6 -->|"get.W_all_else_empty: aircraft_category, requireWTO, false"| T7

    linkStyle 0,1,2,3,4 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63 stroke:#33cc33,color:#33cc33,stroke-width:2px

    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    class CTOR ctor
    class G1,G2,G3,G4,G5,E1,E2,W1,W2,W3,W4,W5,W6,W7,M0,M1,M2,T1,T2,T3,T4,T5,T6,T7,L1,L2,L3,P1 func
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `aircraft_category` | `f16a_L2.json`, top-level field | `jet_fighter`. Selects the Table 15.2 density column and the fraction column. |
| `N_en` | `.weights.N_en` | 1, T.O. 1F-16A-1 Sec. I. Still a weights input because no propulsion class exposes an engine count. |
| `design_mach` | `f16a_requirements.json` | 2.0. Feeds Raymer Eq. 10.10 only. |
| `W_payload_fixed` | `.weights.W_payload_fixed` | 700 lbf, Brandt Wt!B4. |
| `W_payload_expendable` | `.weights.W_payload_expendable` | 4400 lbf, Brandt Wt!B5. |
| `W_TO` | Sizing loop, mutated in place | `NaN` until the loop sets it. `get.W_landing_gear` and `get.W_all_else_empty` route through the private `requireWTO`, which errors on `NaN`. |
| `S_exposed_planform_wing` | `geom.S_exposed_wing` | 196.2261 ft^2, EXPOSED. |
| `S_exposed_planform_ht` | `geom.S_exposed_ht` | 49.8473 ft^2, EXPOSED. NOT `geom.S_ht` = 108, which is the FULL reference. |
| `S_exposed_planform_vt` | `geom.S_exposed_vt` | 40.8897 ft^2, EXPOSED. NOT `geom.S_vt` = 60. |
| `S_exposed_planform_strakes` | `geom.S_exposed_strake` | 20.0000 ft^2. A body surface, so the fuselage does not clip it and exposed equals the reference area. |
| `S_wet_fus` | `geom.S_wet_fuselage` | 730.3023 ft^2. A WETTED area: the Table 15.2 fuselage row takes wetted, not planform. |
| `S_strake`, `k_strake` | Removed 2026-09-02 | Were weights inputs holding 20.0 and 4.5. The area is a geometric value, so it moved to `f16a_L2.json` `.geometry.strake`. The density is no longer used, because the strake takes the wing density. |
| `W_en` | `PropL2.engine_weight_AB` | 2775.0210 lbf, UNINSTALLED. The 1.3 installed factor is applied separately by `compute_weight_installed_engine`. |
| `W_en_brandt` | `WeightsL2.engine_weight_brandt` | 4730.2300 lbf, already installed, so no 1.3. Comparison report only, never summed. |
| Group weights at `W_TO` = 31,377 | Computed | Wing 1766.03, HT 199.39, VT 216.72, fuselage 3505.45, gear 1035.44, installed engine 3607.53, all-else 5334.09, strake 180.00. |
| `get_OEW` at `W_TO` = 31,377 | Computed | 15,844.65 lbf. |
| L2 sizing closure | Computed | `W_TO` 23,279.4 lbf, `S_ref` 175.0151 ft^2, `T_SL` 20,112.5 lbf, OEW 12,322.0 lbf, `W_fuel` 5857.4 lbf, 14 iterations. |
| Strake basis | Model choice | The wing density gives 180.00 lbf. Brandt's Wt!H7 coefficient of 4.5 psf gives 90.00. The 90 lbf difference is the only term putting L2 off the 2026-08-18 baseline, where `W_TO` closes at 23,087.2 lbf. |

## Methods with no upstream call at L2

Two `WeightsL2` statics are not reached from inside this class, so neither
appears in the chart: they carry no arrow out of `F16WeightsL2`. Both are live
and correct.

| Static | Reached by |
| --- | --- |
| `jet_engine_weight_roskam(T0_lbf)` | `Aero481WeightsL1` engine delta, and `B777WeightsL2.get.W_en`, across the injection boundary |
| `turboprop_engine_weight_roskam(P_shp)` | Nothing. No example aircraft is a turboprop. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/weights/F16WeightsL2.m` |
| Tier 2, abstract | `src/disciplines/weights/WeightsModelL2.m` |
| Tier 1, base | `src/base/WeightsBase.m` |
| Toolbox | `src/disciplines/weights/WeightsL2.m` |
| Engine weight | `src/disciplines/propulsion/PropL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
| Requirements JSON | `examples/F16A/inputs/f16a_requirements.json` |
