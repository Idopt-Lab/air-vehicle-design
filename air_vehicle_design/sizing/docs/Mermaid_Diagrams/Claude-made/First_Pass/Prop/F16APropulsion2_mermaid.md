# F16PropL2: input-to-output data flow

This chart shows the data path for `F16PropL2`, the Level 2 (L2) propulsion
class. L2 is the Mattingly parametric model, with separate mil (dry) and
afterburner (wet) branches for both thrust lapse and TSFC.

**This class also serves the L3 rung.** There is no L3 propulsion tier, so
`F16AeroL3` and `F16WeightsL3` are injected with an `F16PropL2`. Anything
reporting an L3 propulsion number is reporting an L2 computation.

**Read this first.**
- The chart runs LEFT TO RIGHT. The engine-scaling band is 13 nodes wide, so
  the vertical form would not fit.
- EVERY arrow carries a label naming the exact value it moves.
- There is no "Inputs" block. The constructor's outgoing arrows carry the
  field names.
- The constructor is cyan. Every other function is green. Yellow dashed marks
  a getter that calls nothing. Red dashed marks a static with no upstream
  call.
- Every edge takes the color of the node it POINTS AT.
- `PropL2` holds TWO unrelated families. The Mattingly lapse and TSFC statics
  are the live path this class uses. The Raymer Ch. 10 engine-scaling statics
  are a separate group of 13, and `F16PropL2` calls NONE of them.
- Exactly one of those 13 is live: `engine_weight_AB`, reached by
  `F16WeightsL2` and `F16WeightsL3`, which read `prop.T_SL` and
  `prop.bypass_ratio` off this object by injection. That external consumer is
  drawn as a source node, because the call does not pass through this class.
- Three more (`engine_length_AB`, `SFC_max_AB`, `SFC_cruise_AB`) are called
  only by `TestPropL2`, so they have no production caller. The remaining nine
  have no caller anywhere.
- The 12 red arrows all leave the constructor. That is the standing marker for
  a static the class never invokes, and it is verbose here only because the
  unused family is large.
- `thrust_lapse_mil_on_AB_scale` is OVERRIDDEN here. `PropulsionBase` defaults
  it to the afterburner-basis lapse; this class returns the mil lapse
  renormalized onto the afterburner thrust scale, and warns outside a
  plausible band.
- `TR` is the only derived computed quantity, and it equals 1.0, because
  `T_t4_SLS` is unknown and `compute_TR` defaults it to `T_t4_max`.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        J["f16a_L2.json"]
        ST["AircraftState<br/>state"]
        WT["External consumer<br/>F16WeightsL2 and F16WeightsL3"]
    end

    subgraph CLASS["F16PropL2 (Tier 3)"]
        direction LR

        CTOR["Constructor<br/>F16PropL2(json_path)<br/>in: json_path<br/>out: engine_type, T_SL, T_SL_mil,<br/>T_t4_max_F, TSFC_install_factor, bypass_ratio"]

        D1["get.T_SL_wet<br/>in: T_SL<br/>out: T_SL_wet = T_SL (alias)"]
        D2["get.TR<br/>in: T_t4_max_F + 459.67<br/>out: TR = 1.0, Mattingly Eq. D.6"]

        subgraph LAPSE["Thrust lapse"]
            M1["thrust_lapse(obj, state)<br/>required by PropulsionBase<br/>in: delta_0, theta_0, TR<br/>out: alpha_AB"]
            M2["compute_thrust_lapse_mil(obj, state)<br/>required by PropulsionModelL2<br/>in: delta_0, theta_0, TR<br/>out: alpha_mil"]
            M3["compute_thrust_lapse_AB(obj, state)<br/>required by PropulsionModelL2<br/>in: delta_0, theta_0, TR<br/>out: alpha_AB"]
            M4["thrust_lapse_mil_on_AB_scale(obj, state)<br/>OVERRIDE of the PropulsionBase default<br/>in: delta_0, theta_0, TR, T_SL_mil, T_SL_wet<br/>out: alpha_mil on the AB scale"]
        end

        subgraph FUEL["TSFC"]
            M5["get_TSFC(obj, state)<br/>required by PropulsionBase<br/>in: engine_type, mach, theta<br/>out: uninstalled mil TSFC [1/hr]"]
            M6["compute_TSFC_mil(obj, state)<br/>required by PropulsionModelL2<br/>in: engine_type, mach, theta<br/>out: uninstalled mil TSFC"]
            M7["compute_TSFC_AB(obj, state)<br/>required by PropulsionModelL2<br/>in: engine_type, mach, theta<br/>out: uninstalled AB TSFC"]
            M8["compute_TSFC_installed(obj, state)<br/>in: uninstalled mil TSFC, TSFC_install_factor<br/>out: installed mil TSFC"]
            M9["compute_TSFC_AB_installed(obj, state)<br/>in: uninstalled AB TSFC, TSFC_install_factor<br/>out: installed AB TSFC"]
        end
    end

    subgraph TOOL["PropL2 toolbox: Mattingly lapse and TSFC"]
        T1["get_thrust_lapse(obj, state)"]
        T2["get_thrust_lapse_mil(obj, state)"]
        T3["get_thrust_lapse_AB(obj, state)"]
        T4["get_thrust_lapse_mil_on_AB_scale(obj, state)<br/>warns outside (0, 1.5]"]
        T5["get_TSFC(obj, state)"]
        T6["get_TSFC_mil(obj, state)"]
        T7["get_TSFC_AB(obj, state)"]
        T8["get_TSFC_installed(obj, state)"]
        T9["get_TSFC_AB_installed(obj, state)"]
        L1["thrust_lapse_AB(delta_0, theta_0, TR)<br/>Mattingly Eq. 2.54a"]
        L2["thrust_lapse_mil(delta_0, theta_0, TR)<br/>Mattingly Eq. 2.54b"]
        L3["TSFC_mil(C1_mil, C2_mil, M, theta)<br/>Mattingly Eq. 3.12 and 3.55a"]
        L4["TSFC_AB(C1_AB, C2_AB, M, theta)<br/>Mattingly Eq. 3.12 and 3.55b"]
        L5["lookup_TSFC_coeffs(engine_type)<br/>C1_mil 0.90, C2_mil 0.30,<br/>C1_AB 1.60, C2_AB 0.27"]
        L6["compute_TR(T_t4_max_R, T_t4_SLS_R)<br/>Mattingly Eq. D.6"]
    end

    subgraph TOOLE["PropL2 toolbox: Raymer Ch. 10 engine scaling"]
        E1["engine_weight_AB(T, M, BPR)<br/>Raymer Eq. 10.10<br/>reached only by the weights classes"]
        D3["engine_length_AB(T, M)<br/>NO PRODUCTION CALLER, tests only"]
        D4["engine_diam_AB(T, BPR)<br/>NOT CALLED anywhere"]
        D5["SFC_max_AB(BPR)<br/>NO PRODUCTION CALLER, tests only"]
        D6["thrust_cruise_AB(T, BPR)<br/>NOT CALLED anywhere"]
        D7["SFC_cruise_AB(BPR)<br/>NO PRODUCTION CALLER, tests only"]
        D8["engine_weight_nonAB(T, BPR)<br/>NOT CALLED anywhere"]
        D9["engine_length_nonAB(T, M)<br/>NOT CALLED anywhere"]
        D10["engine_diam_nonAB(T, BPR)<br/>NOT CALLED anywhere"]
        D11["SFC_max_nonAB(BPR)<br/>NOT CALLED anywhere"]
        D12["thrust_cruise_nonAB(T, BPR)<br/>NOT CALLED anywhere"]
        D13["SFC_cruise_nonAB(BPR)<br/>NOT CALLED anywhere"]
        D14["warnIfImplausibleEngineDiameter(D, callerName)<br/>NOT CALLED anywhere"]
    end

    J -->|"propulsion: engine_type = low_bypass_turbofan_AB,<br/>T_SL = 23770, T_SL_mil = 15000, T_t4_max_F = 2566,<br/>TSFC_install_factor = 1.08, bypass_ratio = 0.71"| CTOR

    CTOR -->|"T_SL"| D1
    CTOR -->|"T_t4_max_F + 459.67"| D2

    D2 -->|"TR"| M1
    ST -->|"state.delta_0, state.theta_0"| M1
    D2 -->|"TR"| M2
    ST -->|"state.delta_0, state.theta_0"| M2
    D2 -->|"TR"| M3
    ST -->|"state.delta_0, state.theta_0"| M3
    D2 -->|"TR"| M4
    ST -->|"state.delta_0, state.theta_0"| M4
    CTOR -->|"T_SL_mil"| M4
    D1 -->|"T_SL_wet"| M4
    CTOR -->|"engine_type"| M5
    ST -->|"state.mach, state.theta"| M5
    CTOR -->|"engine_type"| M6
    ST -->|"state.mach, state.theta"| M6
    CTOR -->|"engine_type"| M7
    ST -->|"state.mach, state.theta"| M7
    M6 -->|"uninstalled mil TSFC"| M8
    CTOR -->|"TSFC_install_factor = 1.08"| M8
    M7 -->|"uninstalled AB TSFC"| M9
    CTOR -->|"TSFC_install_factor = 1.08"| M9

    D2 -->|"get.TR: T_t4_max_R"| L6
    M1 -->|"thrust_lapse: obj, state"| T1
    M2 -->|"compute_thrust_lapse_mil: obj, state"| T2
    M3 -->|"compute_thrust_lapse_AB: obj, state"| T3
    M4 -->|"thrust_lapse_mil_on_AB_scale: obj, state"| T4
    M5 -->|"get_TSFC: obj, state"| T5
    M6 -->|"compute_TSFC_mil: obj, state"| T6
    M7 -->|"compute_TSFC_AB: obj, state"| T7
    M8 -->|"compute_TSFC_installed: obj, state"| T8
    M9 -->|"compute_TSFC_AB_installed: obj, state"| T9

    T1 -->|"get_thrust_lapse: delta_0, theta_0, TR"| L1
    T2 -->|"get_thrust_lapse_mil: delta_0, theta_0, TR"| L2
    T3 -->|"get_thrust_lapse_AB: delta_0, theta_0, TR"| L1
    T4 -->|"get_thrust_lapse_mil_on_AB_scale: delta_0, theta_0, TR"| L2
    T5 -->|"get_TSFC: engine_type"| L5
    T5 -->|"get_TSFC: C1_mil, C2_mil, mach, theta"| L3
    T6 -->|"get_TSFC_mil: engine_type"| L5
    T6 -->|"get_TSFC_mil: C1_mil, C2_mil, mach, theta"| L3
    T7 -->|"get_TSFC_AB: engine_type"| L5
    T7 -->|"get_TSFC_AB: C1_AB, C2_AB, mach, theta"| L4
    T8 -->|"get_TSFC_installed: obj, state"| T6
    T9 -->|"get_TSFC_AB_installed: obj, state"| T7

    WT -->|"prop.T_SL, design_mach, prop.bypass_ratio"| E1

    CTOR -.->|"no upstream call from F16PropL2"| D3
    CTOR -.->|"no upstream call"| D4
    CTOR -.->|"no upstream call from F16PropL2"| D5
    CTOR -.->|"no upstream call"| D6
    CTOR -.->|"no upstream call from F16PropL2"| D7
    CTOR -.->|"no upstream call"| D8
    CTOR -.->|"no upstream call"| D9
    CTOR -.->|"no upstream call"| D10
    CTOR -.->|"no upstream call"| D11
    CTOR -.->|"no upstream call"| D12
    CTOR -.->|"no upstream call"| D13
    CTOR -.->|"no upstream call"| D14

    linkStyle 0 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 1 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 46,47,48,49,50,51,52,53,54,55,56,57 stroke:#ff4040,color:#ff4040,stroke-width:2px,stroke-dasharray:5 5

    classDef dead fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040,stroke-dasharray: 6 4
    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14 dead
    class CTOR ctor
    class D2,M1,M2,M3,M4,M5,M6,M7,M8,M9,T1,T2,T3,T4,T5,T6,T7,T8,T9,L1,L2,L3,L4,L5,L6,E1 func
    class D1 passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `engine_type` | `f16a_L2.json`, `.propulsion.engine_type` | Selects the four Mattingly TSFC coefficients inside the toolbox. `lookup_TSFC_coeffs` accepts only the two low-bypass rows and errors on anything else. |
| `T_SL` | `.propulsion.T_SL` | 23,770 lbf afterburner. Brandt Main!D29. |
| `T_SL_mil` | `.propulsion.T_SL_mil` | 15,000 lbf mil power. Brandt Main!C29. |
| `T_t4_max_F` | `.propulsion.T_t4_max_F` | 2566 deg F, Mattingly Table C.4. Feeds `get.TR` after conversion to deg R. |
| `TSFC_install_factor` | `.propulsion.TSFC_install_factor` | 1.08. Brandt's own stored SLS TSFCs, 0.70 mil and 2.20 AB, are ALREADY installed, so this factor must not be applied again when comparing against them. |
| `bypass_ratio` | `.propulsion.bypass_ratio` | 0.71. Cited to Nicolai and Carichner Table 14.3 for the F100-PW-100, the direct predecessor of the PW-200 modeled elsewhere. Written into the JSON in Phase 3 with no property to read it, so it sat unread until Phase 4 needed it for the engine-weight estimate. |
| `engine_model` | `.propulsion.engine_model` | `F100-PW-200`. Present in the JSON and NOT read by the constructor. A descriptor with no consumer. |
| `T_SL_wet` (Dependent) | `T_SL` | An alias. Both used to be stored, so an optimizer changing `T_SL` left `T_SL_wet` stale and made the mil-on-AB lapse silently wrong. |
| `TR` (Dependent) | `PropL2.compute_TR` | Equals 1.0. `T_t4_SLS` is unknown, and `compute_TR` defaults its second argument to the first, so the ratio is 1 by construction. Every lapse branch therefore compares `theta_0` against 1.0. |
| `alpha_AB` at 36 kft, M 0.87 | Computed | About 0.37, equal to `delta_0`, because `theta_0` is about 0.867 and so below `TR`. |
| `TSFC_mil` at SLS, M 0 | Computed | 0.90 1/hr uninstalled, 0.972 installed, against Brandt's installed 0.70. Mattingly over-predicts the static sea-level value but follows the correct trend with altitude and Mach. |

## Methods with no upstream call at L2

The Raymer Ch. 10 engine-scaling family. `F16PropL2` calls none of the 13.

| Static | Status |
| --- | --- |
| `engine_weight_AB` | LIVE, but not through this class. `F16WeightsL2` and `F16WeightsL3` call it directly, reading `prop.T_SL`, `design_mach` and `prop.bypass_ratio` off the injected propulsion object. Drawn green. |
| `engine_length_AB`, `SFC_max_AB`, `SFC_cruise_AB` | Called only by `TestPropL2`. No production caller. |
| `engine_diam_AB`, `thrust_cruise_AB` | No caller anywhere. |
| `engine_weight_nonAB`, `engine_length_nonAB`, `engine_diam_nonAB`, `SFC_max_nonAB`, `thrust_cruise_nonAB`, `SFC_cruise_nonAB` | No caller anywhere. The whole non-afterburning half of the family is unused, which follows from the F-16 being an afterburning aircraft. |
| `warnIfImplausibleEngineDiameter` | No caller anywhere. It exists to guard the two `engine_diam_*` statics, neither of which is called either. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/prop/F16PropL2.m` |
| Tier 2, abstract | `src/disciplines/propulsion/PropulsionModelL2.m` |
| Tier 1, base | `src/base/PropulsionBase.m` |
| Toolbox | `src/disciplines/propulsion/PropL2.m` |
| External consumer of the engine-weight static | `examples/F16A/models/disciplines/weights/F16WeightsL2.m`, `F16WeightsL3.m` |
| Input JSON | `examples/F16A/inputs/f16a_L2.json` |
