# F16GeomL3: input-to-output data flow (second pass)

This chart shows the data path for `F16GeomL3`, the Level 3 (L3) geometry class,
**as the code stands after the toolbox trim of 2026-08-17 to 2026-08-19**. The
first-pass chart is kept unchanged at
`Claude-made/First_Pass/Geom/F16AGeom3_mermaid.md`.

L3 is the higher-fidelity PHYSICAL / T.O.-geometry tier, consumed by L3 geometry,
aerodynamics and weights. Where a physical or T.O. 1F-16A-1 value differs from
Brandt's, this tier uses the physical one. Those divergences are intentional
fidelity differences, not errors.

## Viewing this chart with pan and zoom

Mermaid inside a `.md` renders at a fixed size, so a wide chart is hard to read in
a plain preview. Open `docs/Mermaid_Diagrams/viewer.html` and drag this file onto
it. Wheel or pinch zooms, drag pans, and `f` fits.

The viewer reads the first ```` ```mermaid ```` block straight out of this file, so
there is no second copy of the diagram to keep in step.

## What changed since the first pass

| First pass | Now |
| --- | --- |
| `GeomL3` held `get_S_wet` plus six narrow object-taking pass-throughs, and `get_Amax`, which read about 20 fields off a design object | Every one is gone from the toolbox. `get_Amax` moved onto `F16GeomL3`, which closes the last object-taking static in the geometry toolboxes. A design class may read its own properties, so the "deferred wide static" problem did not need solving |
| The constructor was `F16GeomL3(json_path, prop)` | Now `F16GeomL3(json_path, prop, req_path)`, every argument required, no silent default. The third path supplies `design_mach` for the engine-length equation |
| `L_engine` was Brandt's `4.5*D_inlet` | **Raymer 6th ed. Eq. 10.11**, `0.255*T^0.4*M^0.2`, through the existing cited `PropL2.engine_length_AB`. 15.9166 to 16.4876 ft, +3.59 %. `Amax` did NOT move: no frame station falls in the 0.57 ft the nacelle gained |
| Fuselage wetted area came from Roskam Eq. 12.3 on a diameter and a length | Comes from integrating the CONTROL-STATION perimeter curve, per **Raymer 6th ed. Fig. 7.37**. Roskam gave 749.1337 ft²; the station integration gives 692.5050, which is -7.56 % |
| The station table, once added, was frozen at the size it was drawn for | SCALED by ratio to the live fuselage, so wetted area now tracks `L_fus`, `W_max_fuselage` and `H_max_fuselage`. Frozen, an optimizer saw no drag change from stretching the fuselage |
| No strake | Strakes are a full component: 8 inputs, 7 getters, and a sixth term in the wetted-area sum. Verified exact against Brandt for span, root chord, tip chord and exposed area |
| `F16AeroL3` accepted an L2 OR an L3 geometry, and silently took the envelope `Amax` when given L2 | Finding S-19 CLOSED. The aero guard is L3 only. The wave-drag term moved from +23.15 % to -0.54 % against Brandt's own `Amax`, with the calibration factor untouched |

**Read this first.** Same rule set as the L1 and L2 charts, plus two notes this
chart needs:
- **Arrow meaning.** Inside a class box, a solid arrow is a VALUE that a getter
  reads. An arrow into a toolbox box, or into another function box, is a CALL,
  labeled with the calling function's name and the actual arguments at that call
  site.
- **One marker is left.** Six were needed while every no-call getter wired to one;
  now that injectors are exempt, only `get_S_ref` reaches a marker.

Everything else is as before: one function per node; name, inputs, output and
citation only, with values in the notes tables; no grouped "Inputs" node; source
nodes hold only a name; constructor cyan; other functions green; no-toolbox-call
functions yellow dashed at the end of their row; a black node with a red dashed
border for a static `F16GeomL3` never calls; and every edge takes the colour and
dash of the node it points at.

**A NO UPSTREAM CALL node has NO CONNECTOR.** A connector shows data flowing between
method functions that are actively used, so drawing one into an unused static would
assert a flow that does not happen. Those nodes stand alone inside the toolbox box,
and the fact is written in the label.

**The Tier-2 enforcer is NOT drawn.** `get.S_wet` is shown calling
`get_design_S_wet_components` directly. The real path takes one hop through
`GeometryModelL3.get_S_wet(obj)`, a concrete bridge that forwards to it. The
bridge holds no equation and adds no data, so it is recorded here rather than
drawn as a box.

```mermaid
flowchart LR
    NCF["no toolbox call"]

    J1["f16a_L3.json"]
    J2["f16a_requirements.json"]
    J3["F16_geom_stations.json"]
    PROP["prop (PropulsionBase, injected)"]

    subgraph CLASS["F16GeomL3 (Tier 3, concrete)"]
        direction TB

        CTOR["Constructor<br/>F16GeomL3(json_path, prop, req_path)<br/>in: json_path, prop, req_path<br/>out: wing / HT / VT / strake / fuselage / engine inputs,<br/>frames_normalized, fuselage_stations,<br/>fuselage_station_ref, M_max, stored prop handle"]

        subgraph WING["Wing"]
            W1["get.b_wing<br/>in: AR_wing, S_ref<br/>out: b_wing"]
            W2["get.c_root_wing<br/>in: S_ref, b_wing, lambda_wing<br/>out: c_root_wing"]
            W3["get.c_tip_wing<br/>in: c_root_wing, lambda_wing<br/>out: c_tip_wing"]
            W4["get.cbar_wing<br/>in: c_root_wing, lambda_wing<br/>out: cbar_wing"]
            W5["get.QC_sweep_wing<br/>in: LE_sweep_wing, AR_wing, lambda_wing<br/>out: QC_sweep_wing"]
            W6["get.TE_sweep_wing<br/>in: LE_sweep_wing, AR_wing, lambda_wing<br/>out: TE_sweep_wing"]
            W7["get.S_exposed_wing<br/>in: c_root_wing, c_tip_wing, b_wing, W_max_fuselage<br/>out: S_exposed_wing"]
            W10["get.S_wet_wing<br/>in: S_exposed_wing, tc_r_wing, tc_t_wing, lambda_wing<br/>out: S_wet_wing"]
            W8["get.tc_r_wing<br/>in: tc_wing<br/>out: tc_r_wing"]
            W9["get.tc_t_wing<br/>in: tc_wing<br/>out: tc_t_wing"]
        end

        subgraph HT["Horizontal tail"]
            H3["get.c_root_ht<br/>in: S_ht, b_ht, lambda_ht<br/>out: c_root_ht"]
            H4["get.c_tip_ht<br/>in: c_root_ht, lambda_ht<br/>out: c_tip_ht"]
            H5["get.QC_sweep_ht<br/>in: LE_sweep_ht, AR_ht, lambda_ht<br/>out: QC_sweep_ht"]
            H6["get.TE_sweep_ht<br/>in: LE_sweep_ht, AR_ht, lambda_ht<br/>out: TE_sweep_ht"]
            H7["get.S_exposed_ht<br/>in: c_root_ht, c_tip_ht, b_ht, W_max_fuselage<br/>out: S_exposed_ht"]
            H8["get.S_wet_ht<br/>in: S_exposed_ht, tc_r_ht, tc_t_ht, lambda_ht<br/>out: S_wet_ht"]
            H1["get.AR_ht<br/>in: B_h, S_ht<br/>out: AR_ht, DERIVED at this tier"]
            H2["get.b_ht<br/>in: B_h<br/>out: b_ht"]
            H9["get.tc_ht<br/>in: tc_r_ht, tc_t_ht<br/>out: tc_ht"]
        end

        subgraph VT["Vertical tail"]
            V2["get.c_root_vt<br/>in: S_vt, b_vt, lambda_vt<br/>out: c_root_vt"]
            V3["get.c_tip_vt<br/>in: c_root_vt, lambda_vt<br/>out: c_tip_vt"]
            V4["get.QC_sweep_vt<br/>in: LE_sweep_vt, AR_vt, lambda_vt<br/>out: QC_sweep_vt"]
            V5["get.TE_sweep_vt<br/>in: LE_sweep_vt, AR_vt, lambda_vt<br/>out: TE_sweep_vt"]
            V6["get.S_exposed_vt<br/>in: S_vt, AR_vt, c_root_vt, c_tip_vt, H_max_fuselage<br/>out: S_exposed_vt"]
            V7["get.S_wet_vt<br/>in: S_exposed_vt, tc_r_vt, tc_t_vt, lambda_vt<br/>out: S_wet_vt"]
            V1["get.b_vt<br/>in: S_vt, AR_vt<br/>out: b_vt"]
            V8["get.tc_vt<br/>in: tc_r_vt, tc_t_vt<br/>out: tc_vt"]
        end

        subgraph STRAKE["Strake (LERX)"]
            K1["get.b_strake<br/>in: AR_strake, S_strake<br/>out: b_strake"]
            K2["get.c_root_strake<br/>in: S_strake, b_strake, lambda_strake<br/>out: c_root_strake"]
            K3["get.c_tip_strake<br/>in: c_root_strake, lambda_strake<br/>out: c_tip_strake"]
            K4["get.S_exposed_strake<br/>in: c_root_strake, c_tip_strake, b_strake, W_max_fuselage<br/>out: S_exposed_strake"]
            K5["get.S_wet_strake<br/>in: S_exposed_strake, tc_r_strake, tc_t_strake, lambda_strake<br/>out: S_wet_strake"]
            K6["get.AR_exposed_strake<br/>in: AR_strake<br/>out: AR_exposed_strake"]
            K7["get.lambda_exposed_strake<br/>in: lambda_strake<br/>out: lambda_exposed_strake"]
        end

        subgraph FUS["Fuselage, control-station method"]
            F1["get_S_wet_fuselage_stations(obj)<br/>in: fuselage_stations, fuselage_station_ref,<br/>L_fus, W_max_fuselage, H_max_fuselage<br/>out: S_wet_fuselage<br/>Raymer 6th ed. Fig. 7.37, p. 206"]
            F2["get.S_wet_fuselage<br/>in: obj<br/>out: S_wet_fuselage"]
            F3["get.D_fus<br/>in: W_max_fuselage, H_max_fuselage<br/>out: D_fus"]
            F4["get.L_fuselage<br/>in: L_fus<br/>out: L_fuselage"]
        end

        subgraph DUCT["Inlet, duct and nacelle"]
            E2["get.D_inlet<br/>in: T_AB_SLS_lb<br/>out: D_inlet"]
            E4["get.L_engine<br/>in: T_AB_SLS_lb, M_max<br/>out: L_engine<br/>Raymer 6th ed. Eq. 10.11"]
            E6["get.S_wet_duct<br/>in: D_inlet, D_exit, L_duct<br/>out: S_wet_duct"]
            E1["get.T_AB_SLS_lb<br/>in: prop.T_SL<br/>out: T_AB_SLS_lb"]
            E3["get.D_exit<br/>in: D_inlet<br/>out: D_exit"]
            E5["get.x_nacelle_aft<br/>in: x_inlet, L_duct, L_engine<br/>out: x_nacelle_aft"]
        end

        subgraph EXP["Exposed-root geometry for the area rule"]
            X1["get.c_exp_root_wing<br/>in: c_root_wing, c_tip_wing, b_wing, G_hs_exp_wing<br/>out: c_exp_root_wing"]
            X2["get.c_exp_root_ht<br/>in: c_root_ht, c_tip_ht, b_ht, G_hs_exp_ht<br/>out: c_exp_root_ht"]
            X3["get.c_exp_root_vt<br/>in: c_root_vt, c_tip_vt, b_vt, G_hs_exp_vt<br/>out: c_exp_root_vt"]
            X4["get.G_hs_exp_wing<br/>in: b_wing, W_max_fuselage<br/>out: G_hs_exp_wing"]
            X5["get.G_hs_exp_ht<br/>in: b_ht, W_max_fuselage<br/>out: G_hs_exp_ht"]
            X6["get.G_hs_exp_vt<br/>in: b_vt<br/>out: G_hs_exp_vt"]
            X7["get.Xexp_wing<br/>in: x_apex_wing, W_max_fuselage, LE_sweep_wing<br/>out: Xexp_wing"]
            X8["get.Xexp_ht<br/>in: x_le_ht, LE_sweep_ht<br/>out: Xexp_ht"]
            X9["get.Xexp_vt<br/>in: x_le_vt, LE_sweep_vt<br/>out: Xexp_vt"]
        end

        subgraph AREA["Area rule"]
            A1["get_Amax(obj)<br/>in: frames_normalized, L_fus, W_max_fuselage,<br/>H_max_fuselage, exposed-root geometry,<br/>n_engines, D_inlet, x_inlet, x_nacelle_aft<br/>out: Amax<br/>Brandt Geom!H26:H45 -> H47"]
            A2["get.Amax<br/>in: obj<br/>out: Amax"]
        end

        AGG["get_design_S_wet_components(obj)<br/>in: exposed areas, t/c, taper for four surfaces,<br/>plus the fuselage and duct areas<br/>out: S_wet total"]
        PSW["get.S_wet<br/>in: obj<br/>out: S_wet"]
        GSR["get_S_ref(obj)<br/>in: obj.S_ref<br/>out: S_ref"]
    end


    subgraph TB["GeometryBase (static methods)"]
        TB1["compute_span(AR, S_ref)<br/>out: b<br/>definitional"]
        TB2["compute_root_chord(S_ref, b, lambda)<br/>out: c_root<br/>Raymer 7th ed. Eq. 7.6"]
        TB3["compute_tip_chord(c_root, lambda)<br/>out: c_tip<br/>definitional"]
        TB4["compute_mac(c_root, lambda)<br/>out: cbar<br/>Raymer 7th ed. Eq. 7.8"]
        TB5["convert_sweep(Lambda_LE, AR, lambda, x)<br/>out: Lambda_x<br/>MIRRORED 4/AR"]
        TB6["convert_sweep_panel(Lambda_LE, AR, lambda, x)<br/>out: Lambda_x<br/>SINGLE PANEL 2/AR"]
    end

    subgraph TG2["GeomL2 toolbox (static methods)"]
        G1["compute_S_exposed_horizontal(c_root, c_tip, hs, fw)<br/>out: S_exposed, both panels<br/>Brandt readme_geom.md Sec. 4.3"]
        G2["compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)<br/>out: S_exposed, one panel<br/>Brandt readme_geom.md Sec. 4.3"]
        G3["compute_S_wet_planform_roskam(S_exp, tc_r, tc_t, lambda)<br/>out: S_wet<br/>Roskam Vol. II Eq. 12.1, UNVERIFIED"]
        G4["compute_s_wet_duct(D_inlet, D_exit, L_duct)<br/>out: S_wet_duct<br/>Raymer 6th ed. Sec. 7.3"]
    end

    subgraph TG3["GeomL3 toolbox (static methods)"]
        GL1["denormalize_frames(frames_normalized, L_fus, W_max, H_max)<br/>out: x, w, h<br/>unit scaling, needs no citation"]
        GL2["compute_frame_cs_area(w, h)<br/>out: A_fuse<br/>Brandt 6-point cosine section"]
        GL3["compute_surface_cs_area(x, Xexp, c_exp_root, c_tip, ...)<br/>out: A_surface<br/>Brandt area-distribution model, UNCITED"]
        GL4["compute_nacelle_cs_area(x, n_engines, D_engine, x_start, x_end)<br/>out: A_nacelle"]
        GL5["compute_Amax_area_ruled(A_total_stations, n_engines, D_engine)<br/>out: Amax<br/>Raymer 6th ed. Eq. 12.44 input"]
        GL6["compute_c_root_exposed(c_root, c_tip, span_root_to_tip, span_clipped)<br/>out: c_exp_root"]
        GL7["compute_frame_perimeter(w, h, z_chine, z_center)<br/>out: P per station<br/>Brandt cosine section, UNCITED"]
        GL8["compute_s_wet_from_perimeter_curve(x, P)<br/>out: S_wet<br/>Raymer 6th ed. Fig. 7.37, p. 206"]
        DE1["compute_frame_cs_area_exact(w, h)<br/>no call from F16GeomL3"]
        DE2["compute_engine_length(D_engine)<br/>no call from F16GeomL3"]
        DE3["compute_s_wet_from_control_stations(frame_x, frame_zchine, frame_z, frame_w, frame_h)<br/>no call from F16GeomL3"]
    end

    subgraph OTHER["Other homes this tier calls"]
        S1["F16GeomL2.compute_nacelle_diameter(T_AB_SLS_lb)<br/>out: D_nacelle<br/>Brandt Engn(s) D_engine"]
        P1["PropL2.engine_length_AB(T, M)<br/>out: L_engine<br/>Raymer 6th ed. Eq. 10.11"]
    end

    J1 -->|"wing / horizontal_tail / vertical_tail / strake /<br/>fuselage / engine blocks, frames_normalized"| CTOR
    J2 -->|"design_mach -> M_max"| CTOR
    J3 -->|"fuselage.stations, fuselage.reference"| CTOR
    PROP -->|"prop handle stored, not copied"| CTOR

    CTOR -->|"AR_wing, S_ref"| W1
    W1 -->|"b_wing"| W2
    CTOR -->|"S_ref, lambda_wing"| W2
    W2 -->|"c_root_wing"| W3
    CTOR -->|"lambda_wing"| W3
    W2 -->|"c_root_wing"| W4
    CTOR -->|"lambda_wing"| W4
    CTOR -->|"LE_sweep_wing, AR_wing, lambda_wing"| W5
    CTOR -->|"LE_sweep_wing, AR_wing, lambda_wing"| W6
    W1 -->|"b_wing/2"| W7
    W2 -->|"c_root_wing"| W7
    W3 -->|"c_tip_wing"| W7
    CTOR -->|"W_max_fuselage/2"| W7
    W7 -->|"S_exposed_wing"| W10
    W8 -.->|"tc_r_wing"| W10
    W9 -.->|"tc_t_wing"| W10
    CTOR -->|"lambda_wing"| W10

    H2 -.->|"b_ht"| H3
    CTOR -->|"S_ht, lambda_ht"| H3
    H3 -->|"c_root_ht"| H4
    CTOR -->|"lambda_ht"| H4
    CTOR -->|"LE_sweep_ht, lambda_ht"| H5
    H1 -->|"AR_ht"| H5
    CTOR -->|"LE_sweep_ht, lambda_ht"| H6
    H1 -->|"AR_ht"| H6
    H2 -.->|"b_ht/2"| H7
    H3 -->|"c_root_ht"| H7
    H4 -->|"c_tip_ht"| H7
    CTOR -->|"W_max_fuselage/2"| H7
    H7 -->|"S_exposed_ht"| H8
    CTOR -->|"tc_r_ht, tc_t_ht, lambda_ht"| H8

    V1 -->|"b_vt"| V2
    CTOR -->|"S_vt, lambda_vt"| V2
    V2 -->|"c_root_vt"| V3
    CTOR -->|"lambda_vt"| V3
    CTOR -->|"LE_sweep_vt, AR_vt, lambda_vt"| V4
    CTOR -->|"LE_sweep_vt, AR_vt, lambda_vt"| V5
    CTOR -->|"S_vt, AR_vt"| V6
    V2 -->|"c_root_vt"| V6
    V3 -->|"c_tip_vt"| V6
    CTOR -->|"H_max_fuselage/2"| V6
    V6 -->|"S_exposed_vt"| V7
    CTOR -->|"tc_r_vt, tc_t_vt, lambda_vt"| V7

    CTOR -->|"AR_strake, S_strake"| K1
    K1 -->|"b_strake"| K2
    CTOR -->|"S_strake, lambda_strake"| K2
    K2 -->|"c_root_strake"| K3
    CTOR -->|"lambda_strake"| K3
    K2 -->|"c_root_strake"| K4
    K3 -->|"c_tip_strake"| K4
    K1 -->|"b_strake/2"| K4
    CTOR -->|"W_max_fuselage/2"| K4
    K4 -->|"S_exposed_strake"| K5
    CTOR -->|"tc_r_strake, tc_t_strake, lambda_strake"| K5

    CTOR -->|"fuselage_stations, fuselage_station_ref,<br/>L_fus, W_max_fuselage, H_max_fuselage"| F1
    F1 -->|"S_wet_fuselage"| F2

    E1 -.->|"T_AB_SLS_lb"| E2
    E1 -.->|"T_AB_SLS_lb"| E4
    CTOR -->|"M_max"| E4
    E2 -->|"D_inlet"| E6
    E3 -.->|"D_exit"| E6
    CTOR -->|"L_duct"| E6

    W2 -->|"c_root_wing"| X1
    W3 -->|"c_tip_wing"| X1
    X4 -->|"G_hs_exp_wing"| X1
    H3 -->|"c_root_ht"| X2
    H4 -->|"c_tip_ht"| X2
    X5 -->|"G_hs_exp_ht"| X2
    V2 -->|"c_root_vt"| X3
    V3 -->|"c_tip_vt"| X3
    X6 -->|"G_hs_exp_vt"| X3

    CTOR -->|"frames_normalized, L_fus, W_max_fuselage,<br/>H_max_fuselage, n_engines, x_inlet"| A1
    X1 -->|"c_exp_root_wing"| A1
    X2 -->|"c_exp_root_ht"| A1
    X3 -->|"c_exp_root_vt"| A1
    X7 -->|"Xexp_wing"| A1
    X8 -->|"Xexp_ht"| A1
    X9 -->|"Xexp_vt"| A1
    E2 -->|"D_inlet"| A1
    E5 -->|"x_nacelle_aft"| A1
    A1 -->|"Amax"| A2

    F1 -->|"S_wet_fuselage"| AGG
    E6 -->|"S_wet_duct"| AGG
    W7 -->|"S_exposed_wing"| AGG
    H7 -->|"S_exposed_ht"| AGG
    V6 -->|"S_exposed_vt"| AGG
    K4 -->|"S_exposed_strake"| AGG
    CTOR -->|"tc and taper for all four surfaces"| AGG
    PSW -->|"get.S_wet: obj"| AGG

    W1 -->|"get.b_wing: obj.AR_wing, obj.S_ref"| TB1
    W2 -->|"get.c_root_wing: obj.S_ref, obj.b_wing, obj.lambda_wing"| TB2
    W3 -->|"get.c_tip_wing: obj.c_root_wing, obj.lambda_wing"| TB3
    W4 -->|"get.cbar_wing: obj.c_root_wing, obj.lambda_wing"| TB4
    W5 -->|"get.QC_sweep_wing: obj.LE_sweep_wing, obj.AR_wing, obj.lambda_wing, 0.25"| TB5
    W6 -->|"get.TE_sweep_wing: obj.LE_sweep_wing, obj.AR_wing, obj.lambda_wing, 1.0"| TB5
    W7 -->|"get.S_exposed_wing: obj.c_root_wing, obj.c_tip_wing, obj.b_wing/2, fw"| G1
    W10 -->|"get.S_wet_wing: obj.S_exposed_wing, obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing"| G3
    H3 -->|"get.c_root_ht: obj.S_ht, obj.b_ht, obj.lambda_ht"| TB2
    H4 -->|"get.c_tip_ht: obj.c_root_ht, obj.lambda_ht"| TB3
    H5 -->|"get.QC_sweep_ht: obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 0.25"| TB5
    H6 -->|"get.TE_sweep_ht: obj.LE_sweep_ht, obj.AR_ht, obj.lambda_ht, 1.0"| TB5
    H7 -->|"get.S_exposed_ht: obj.c_root_ht, obj.c_tip_ht, obj.b_ht/2, fw"| G1
    H8 -->|"get.S_wet_ht: obj.S_exposed_ht, obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht"| G3
    V2 -->|"get.c_root_vt: obj.S_vt, obj.b_vt, obj.lambda_vt"| TB2
    V3 -->|"get.c_tip_vt: obj.c_root_vt, obj.lambda_vt"| TB3
    V4 -->|"get.QC_sweep_vt: obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 0.25"| TB6
    V5 -->|"get.TE_sweep_vt: obj.LE_sweep_vt, obj.AR_vt, obj.lambda_vt, 1.0"| TB6
    V6 -->|"get.S_exposed_vt: obj.S_vt, obj.AR_vt, obj.c_root_vt, obj.c_tip_vt, fh"| G2
    V7 -->|"get.S_wet_vt: obj.S_exposed_vt, obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt"| G3
    K1 -->|"get.b_strake: obj.AR_strake, obj.S_strake"| TB1
    K2 -->|"get.c_root_strake: obj.S_strake, obj.b_strake, obj.lambda_strake"| TB2
    K3 -->|"get.c_tip_strake: obj.c_root_strake, obj.lambda_strake"| TB3
    K4 -->|"get.S_exposed_strake: obj.c_root_strake, obj.c_tip_strake, obj.b_strake/2, fw"| G1
    K5 -->|"get.S_wet_strake: obj.S_exposed_strake, obj.tc_r_strake, obj.tc_t_strake, obj.lambda_strake"| G3
    F1 -->|"get_S_wet_fuselage_stations: w*kw, h*kh, z_chine*kh, z_center*kh"| GL7
    F1 -->|"get_S_wet_fuselage_stations: x*kx, P"| GL8
    E2 -->|"get.D_inlet: obj.T_AB_SLS_lb"| S1
    E4 -->|"get.L_engine: obj.T_AB_SLS_lb, obj.M_max"| P1
    E6 -->|"get.S_wet_duct: obj.D_inlet, obj.D_exit, obj.L_duct"| G4
    X1 -->|"get.c_exp_root_wing: obj.c_root_wing, obj.c_tip_wing, obj.b_wing/2, obj.G_hs_exp_wing"| GL6
    X2 -->|"get.c_exp_root_ht: obj.c_root_ht, obj.c_tip_ht, obj.b_ht/2, obj.G_hs_exp_ht"| GL6
    X3 -->|"get.c_exp_root_vt: obj.c_root_vt, obj.c_tip_vt, obj.b_vt, obj.G_hs_exp_vt"| GL6
    A1 -->|"get_Amax: obj.frames_normalized, obj.L_fus, obj.W_max_fuselage, obj.H_max_fuselage"| GL1
    A1 -->|"get_Amax: w, h"| GL2
    A1 -->|"get_Amax: x, obj.Xexp_wing, obj.c_exp_root_wing, obj.c_tip_wing, ... (x3, one per surface)"| GL3
    A1 -->|"get_Amax: x, obj.n_engines, obj.D_inlet, obj.x_inlet, obj.x_nacelle_aft"| GL4
    A1 -->|"get_Amax: A_total, obj.n_engines, obj.D_inlet"| GL5
    AGG -->|"get_design_S_wet_components: obj.S_exposed_wing, obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing"| G3
    AGG -->|"get_design_S_wet_components: obj.S_exposed_ht, obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht"| G3
    AGG -->|"get_design_S_wet_components: obj.S_exposed_vt, obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt"| G3
    AGG -->|"get_design_S_wet_components: obj.S_exposed_strake, obj.tc_r_strake, obj.tc_t_strake, obj.lambda_strake"| G3

    CTOR -->|"tc_wing"| W8
    CTOR -->|"tc_wing"| W9
    CTOR -->|"B_h, S_ht"| H1
    CTOR -->|"B_h"| H2
    CTOR -->|"tc_r_ht, tc_t_ht"| H9
    CTOR -->|"S_vt, AR_vt"| V1
    CTOR -->|"tc_r_vt, tc_t_vt"| V8
    CTOR -->|"AR_strake"| K6
    CTOR -->|"lambda_strake"| K7
    CTOR -->|"W_max_fuselage, H_max_fuselage"| F3
    CTOR -->|"L_fus"| F4
    CTOR -->|"obj.S_ref"| GSR
    GSR -.->|"get_S_ref: no toolbox call"| NCF
    PROP -->|"prop.T_SL"| E1
    E2 -->|"D_inlet"| E3
    CTOR -->|"x_inlet, L_duct"| E5
    E4 -->|"L_engine"| E5
    W1 -->|"b_wing/2"| X4
    CTOR -->|"W_max_fuselage/2"| X4
    H2 -.->|"b_ht/2"| X5
    V1 -->|"b_vt"| X6
    CTOR -->|"x_apex_wing, LE_sweep_wing, W_max_fuselage/2"| X7
    CTOR -->|"x_le_ht, LE_sweep_ht"| X8
    CTOR -->|"x_le_vt, LE_sweep_vt"| X9








    linkStyle 0,1,2,3 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 58,75,76,77,78,79,80,81,82,83,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,84,135,136,137,138,139,140,141,142,143,144,145,148,149,150,151,152,153,154,155,156,157,158 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 146,147 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3


    linkStyle 0,1,2,3 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 58,75,91 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 76,77,78,79,80,81,82,83,85,86,87,88,89,90,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134 stroke:#33cc33,color:#33cc33,stroke-width:2px,stroke-dasharray:5 4
    linkStyle 4,6,8,10,11,12,16,20,22,24,25,27,32,34,36,38,39,40,41,44,46,47,49,51,55,57,62,65,135,136,137,138,139,140,141,142,143,144,145,150,153,156,157,158 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 5,7,9,13,14,15,17,18,19,21,23,26,28,29,30,31,33,35,37,42,43,45,48,50,52,53,54,56,59,60,61,63,64,66,67,68,69,70,71,72,73,74,84,148,149,151,152,154,155 stroke:#ff44cc,color:#ff44cc,stroke-width:2px,stroke-dasharray:5 4
    linkStyle 146 stroke:#ffe100,color:#ffe100,stroke-width:2px
    linkStyle 147 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:5 4


    linkStyle 0,1,2,3 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 58,75,76,77,78,79,80,81,82,83,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 4,5,6,7,8,9,10,11,12,13,14,15,16,17,20,22,23,24,25,26,27,28,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,59,62,63,65,66,67,68,69,70,71,72,73,74,84,135,136,137,138,139,140,141,142,143,144,145,148,149,150,151,152,153,155,156,157,158 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 18,19,21,29,60,61,64,154 stroke:#ff44cc,color:#ff44cc,stroke-width:2px,stroke-dasharray:5 4
    linkStyle 146 stroke:#ffe100,color:#ffe100,stroke-width:2px
    linkStyle 147 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:5 4

    class DE1,DE2,DE3 deadWork

    linkStyle 0,1,2,3 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 58,75,76,77,78,79,80,81,82,83,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 4,5,6,7,8,9,10,11,12,13,14,15,16,17,20,22,23,24,25,26,27,28,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,59,62,63,65,66,67,68,69,70,71,72,73,74,84,135,136,137,138,139,140,141,142,143,144,145,148,149,150,151,152,153,155,156,157,158 stroke:#ff44cc,color:#ff44cc,stroke-width:2px
    linkStyle 18,19,21,29,60,61,64,154 stroke:#ff44cc,color:#ff44cc,stroke-width:2px,stroke-dasharray:5 4
    linkStyle 146 stroke:#ffe100,color:#ffe100,stroke-width:2px
    linkStyle 147 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:5 4

    classDef ctorWork fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef funcWork fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef injectorWork fill:#000000,stroke:#ff44cc,stroke-width:3px,color:#ff44cc
    classDef injectorRelay fill:#000000,stroke:#ff44cc,stroke-width:3px,color:#ff44cc,stroke-dasharray: 5 4
    classDef passthroughRelay fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 5 4
    classDef deadWork fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040
    class CTOR ctorWork
    class A1,AGG,F1,G1,G2,G3,G4,GL1,GL2,GL3,GL4,GL5,GL6,GL7,GL8,P1,S1,TB1,TB2,TB3,TB4,TB5,TB6 funcWork
    class A2,E2,E4,E5,E6,F2,F3,H1,H3,H4,H5,H6,H7,H8,H9,K1,K2,K3,K4,K5,PSW,V1,V2,V3,V4,V5,V6,V7,V8,W1,W10,W2,W3,W4,W5,W6,W7,X1,X2,X3,X4,X5,X6,X7,X8,X9 injectorWork
    class E1,E3,F4,H2,K6,K7,W8,W9 injectorRelay
    class GSR,NCF passthroughRelay
    class DE1,DE2,DE3 deadWork
```

## The four things this chart is meant to make obvious

1. **The fuselage wetted area no longer comes from a diameter and a length.**
   `F1` takes the station table, scales it to the live fuselage, calls
   `compute_frame_perimeter` once for all stations, and integrates the perimeter
   curve. `GeomL2.compute_s_wet_fus_cyl` does not appear in this chart at all.
2. **The scaling is what makes the fuselage a design variable.** `L_fus`,
   `W_max_fuselage` and `H_max_fuselage` all enter `F1`. Without them the table
   would be frozen at the size it was drawn for, and an optimizer would see no
   drag change from stretching the fuselage.
3. **`Amax` at this tier is the whole-aircraft area-ruled buildup, not the
   envelope ellipse.** Nine arrows feed `get_Amax`, one per contributing shape.
   `F16GeomL2.compute_Amax_elliptical` is absent here on purpose. Do not unify
   the two tiers: the envelope form at L3 is a fidelity inversion, and was a real
   bug.
4. **Two calls leave the F-16 L3 class for another home.** `get.D_inlet` reaches
   `F16GeomL2`, and `get.L_engine` reaches `PropL2`. Both are drawn outside the
   L3 boxes so the crossing is visible.

## Deliberate divergences from L2, all BY DESIGN

| Quantity | L2 | L3 | Why |
| --- | --- | --- | --- |
| VT leading-edge sweep | 40.0 deg | 47.5 deg | The physical value. |
| `L_fus` | 46.5 ft | 47.5 ft | The physical value. |
| HT span | derived from `AR_ht` and `S_ht` | `B_h` = 18.5 ft is the PRIMARY input, so `AR_ht` = `B_h^2/S_ht` = 3.169 is DERIVED, not Brandt's 3.0 | The T.O. gives the span. |
| `Amax` | 27.4889357189 ft², fuselage-envelope ellipse | 24.7036516658 ft², whole-aircraft area-ruled | Raymer Eq. 12.44's Sears-Haack term wants the area-ruled figure. |
| Fuselage wetted area | Roskam Eq. 12.3 | control-station integration | Higher fidelity at the higher tier. |

Naming note: the exposed-planform members carry an explicit `_exposed_` infix, so
`AR_ht`, `lambda_ht`, `S_ht` and `S_vt` mean FULL planform at BOTH tiers. An
earlier version had the same names meaning different things on the two tiers,
which silently fed exposed values into full-planform equations.

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `fuselage_stations` | `F16_geom_stations.json`, `.fuselage.stations` | 21 stations, read once in the constructor. The nose has zero width, so its perimeter stays 0 and the curve closes to a point. |
| `fuselage_station_ref` | `.fuselage.reference` | L 46.5, W_max 7.0, H_max 5.0 ft. Scaling is by RATIO to these, never by the table's own extents: five stations are TALLER than `H_max`, up to 7.5 ft at x = 15 in the chin-inlet region. |
| `S_wet_fuselage` | `get_S_wet_fuselage_stations` | 692.5050310889 ft². Roskam Eq. 12.3 on the same fuselage gives 749.1336817716, so the station method reads 7.56 % lower. |
| `S_wet` | `get.S_wet` -> enforcer -> `get_design_S_wet_components` | 1472.0227642029 ft². Six components: wing, HT, VT, strake, fuselage, duct. |
| `S_wet_strake` | `get.S_wet_strake` | 40.4000 ft², against Brandt's 39.9560. `b_strake` 5.4772, `c_root_strake` 7.3030, `c_tip_strake` 0.0000 and `S_exposed_strake` 20.0000 are all EXACT against Brandt. |
| `L_engine` | `PropL2.engine_length_AB(T_AB_SLS_lb, M_max)` | 16.4876 ft, from Raymer Eq. 10.11. Was Brandt's `4.5*D_inlet` = 15.9166 ft. |
| `D_inlet` | `F16GeomL2.compute_nacelle_diameter` | 3.5370222385 ft, identical at both tiers. |
| `Amax` | `get_Amax` | 24.7036516658 ft². Rescaling with `L_fus` = 46.5 reproduces Brandt's `Geom!B20` to six figures, which independently supports the uncited `/5` engine flow-through deduction. |
| `S_ail`, `S_elev` | Plain properties, both `NaN` | No closed-form getter exists from this tier's inputs. `S_elev` is 0 for the F-16 anyway: it has an all-moving stabilator and no separate elevator. |

## Toolbox notes, all flagged and none resolved in this pass

| Static | Open item |
| --- | --- |
| `denormalize_frames` | UNCITED, and it needs no citation: it is unit scaling. The flag was withdrawn after checking the references. |
| `compute_frame_cs_area` | Its `I_cos` = 0.63137515 is Brandt's 6-point trapezoid of an integral whose exact value is `2/pi` = 0.63661977, so it reads 0.82 % low. The cosine SECTION is Brandt's and is 19 % smaller than an ellipse, so the shape keeps its citation. |
| `compute_frame_cs_area_exact` | Holds the exact `2/pi` form and has NO CONSUMER. Pick one of the two at the next `Amax` review. |
| `compute_surface_cs_area` | Its `(1 - cos(2*pi*xi))` model has no textbook substitute. Raymer Fig. 7.38 expects MEASURED areas, not a formula. |
| `compute_Amax_area_ruled` | The `/5` engine flow-through divisor is bare and uncited. The station extraction reproduces Brandt's `Amax` to six figures, which supports it but does not source it. |
| `compute_engine_length` | Brandt's `4.5*D`. SUPERSEDED by Raymer Eq. 10.11 and NO CONSUMER. Kept as the record, per the flag-do-not-delete rule. |
| `compute_frame_perimeter` | The cosine section model is Brandt's and uncited. Measured behaviour worth knowing: setting `z_chine` = 0 to model a round section gives 17.5275 against a true circle's 18.8496, which is 7.01 % low, converging to 17.5643. So it is not a general round-section perimeter. |
| `compute_s_wet_from_control_stations` | The older whole-table form. Report and test only; `F16GeomL3` uses the two-static path instead. |

## Open items carried out of the geometry stage

- **21 live `GeomL2.` call sites remain in `F16GeomL3`.** Casey deferred this on
  2026-08-19: *"Item C will be worked on later, since I have to verify other
  parts of the disciplines and then link them correctly."* The options on the
  table are to promote the shared identities to `GeometryBase`, to give `GeomL3`
  its own copies, or to leave them.
- **`get.D_inlet` calling into `F16GeomL2` is SIGNED OFF.** Casey accepted the
  L3-to-L2 link on 2026-08-19. `F16PropL2` was offered as the link-free home and
  not taken.
- **`get_design_S_wet_components` never fires during `f16_sizing_L3`.** The six
  components ARE recomputed live, 22,434 times per run, and `F16AeroL3` reads
  every one, because Raymer Eq. 12.24 needs per-component terms. What has no
  consumer at L3 is the TOTAL. Casey's own note in the source says to update the
  sizing loop when all the disciplines are straightened out.
- **`GeometryModelL3.get_control_surfaces`** calls
  `get_design_control_mechanisms`, which no concrete class defines, so calling it
  errors. `GeometryModelL2` has the identical pair. Not fixed: the enforcers were
  ruled off-limits on 2026-08-18.

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/geom/F16GeomL3.m` |
| Tier 2, abstract | `src/disciplines/geometry/GeometryModelL3.m` |
| Tier 1, base | `src/base/GeometryBase.m` |
| Toolboxes | `src/disciplines/geometry/GeomL3.m`, `src/disciplines/geometry/GeomL2.m` |
| Other homes called | `examples/F16A/models/disciplines/geom/F16GeomL2.m`, `src/disciplines/propulsion/PropL2.m` |
| Companion docs | `src/disciplines/geometry/GeomL3.md`, `examples/F16A/models/disciplines/geom/F16GeomL3.md` |
| Input JSON | `examples/F16A/inputs/f16a_L3.json`, `f16a_requirements.json`, `F16_geom_stations.json` |
