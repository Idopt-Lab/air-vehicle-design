# F16GeomL3: input-to-output data flow

This chart shows the data path for `F16GeomL3`, the Level 3 (L3) geometry
class. It shows the input JSON, the injected propulsion object, the class
inputs by component, the `Dependent` cascade each component drives, and the
three toolboxes that compute them.

L3 is the physical / T.O. tier. Where a physical or T.O. 1F-16A-1 value
differs from Brandt's, this tier uses the physical one. Those differences are
intentional fidelity differences, not errors.

L3 is much larger than L2: 38 numeric inputs plus a 20x3 frame table, six
sizing-loop control-surface outputs, 45 `Dependent` properties, and three
separate toolboxes (`GeometryBase`, `GeomL2`, `GeomL3`) plus one call into
`TailL1`. The chart is therefore large. It is drawn LEFT TO RIGHT so that the
component groups stack vertically instead of spreading sideways. The
remaining size problems are logged in
[first_pass_findings.md](../../first_pass_findings.md).

**Read this first.**
- The chart runs LEFT TO RIGHT (`flowchart LR`). Data enters at the left and
  leaves at the right: input file, then the constructor, then each component
  group's getter chain, then the toolboxes. The component groups (wing,
  horizontal tail, vertical tail, fuselage, duct, area-rule intermediates,
  control surfaces, MAC) are parallel branches off the constructor, so they
  stack VERTICALLY, one band per group. This trades an unreadable width for
  height, which a display can scroll.
- EVERY arrow carries a label that names the exact value it moves. This
  includes every arrow that leaves an "Inputs" block: each one says which
  field goes to which getter.
- Every node inside the `F16GeomL3` block is one function: its name, its
  inputs, and its output. Only the plain-property nodes (`INW`, `INHT`,
  `INVT`, `INFUS`, `INENG`, `INCS`) are not functions.
- The constructor gets its own black box, outlined and colored in cyan
  (whole node, name and details both).
- Every other function, class-level or toolbox, is outlined and colored in
  green (whole node).
- Every edge is colored to match the node it POINTS AT, not the node it
  leaves. Edges into the plain per-component "Inputs" nodes stay the default
  color, since those nodes carry no class of their own.
- An edge from a class-level function into a toolbox is labeled with the
  name of the function it came FROM, followed by the arguments it passes.
- A function that calls no toolbox method and no other code is outlined in
  yellow with a dashed border. L3 has many of these, because the tier does
  much of its simple algebra inline: `get.AR_ht` (`B_h^2/S_ht`), `get.b_ht`
  and `get.L_fuselage` (mirrors), `get.b_vt` (`sqrt(S_vt*AR_vt)`),
  `get.tc_ht` / `get.tc_vt` / `get.D_fus` (means), the nine area-rule
  intermediates that are pure subtraction or a `tand` term, and the three
  control-surface buildups.
- Only the two zero-call ACCESSOR methods get an explicit "no external
  calls" marker node: `get_S_ref` and the toolbox's
  `GeomL3.get_S_exposed_wing`, which only reads the `S_exposed_wing`
  property back out. The yellow inline-arithmetic getters do not each get
  their own marker, the same treatment
  [F16AGeom2_mermaid.md](F16AGeom2_mermaid.md) uses.
- A dashed arrow into a black node with a red dashed border marks a method
  with no upstream call at L3. Everything about this treatment is red.
- `F16GeomL3` takes one dependency injection: the constructor requires a
  `PropulsionBase` object, `prop`. It reads only `prop.T_SL`. At the L3 rung
  that object is an `F16PropL2`, because no L3 propulsion tier exists.
- `Amax` at L3 is the whole-aircraft AREA-RULED buildup, not the
  fuselage-envelope ellipse. `GeometryBase.compute_Amax_elliptical` is
  L2's answer and has no upstream call here. This is a deliberate fidelity
  split. Do not unify the two.
- `AR_ht` is DERIVED at L3 (`B_h^2/S_ht` = 3.169), because the measured
  area and span fix the planform. The L3 JSON deliberately carries no
  `horizontal_tail.AR` key.
- `S_ail` and `S_elev` stay `NaN` after construction. Only `S_rud`,
  `S_flaperon`, `S_lef` and `S_stab` are seeded.

```mermaid
flowchart LR
    NC["no external calls"]

    subgraph JSON["Input files"]
        J["f16a_L3.json"]
    end

    PROP["Injected object<br/>prop (PropulsionBase, an F16PropL2 at the L3 rung)"]

    subgraph CLASS["F16GeomL3 (Tier 3)"]
        direction LR

        CTOR["Constructor<br/>F16GeomL3(json_path, prop)<br/>in: json_path, prop<br/>out: 38 spec inputs, the 20x3 frame table,<br/>stored prop handle, seeded S_flaperon/S_lef/S_rud/S_stab<br/>(S_ail, S_elev stay NaN)"]

        SREF["get_S_ref(obj)<br/>in: obj.S_ref<br/>out: S_ref"]

        subgraph WING["Wing"]
            INW["Inputs<br/>S_ref, AR_wing, lambda_wing,<br/>LE_sweep_wing, tc_wing, x_apex_wing"]
            W1["get.b_wing<br/>in: AR_wing, S_ref<br/>out: b_wing"]
            W2["get.c_root_wing<br/>in: S_ref, b_wing, lambda_wing<br/>out: c_root_wing"]
            W3["get.c_tip_wing<br/>in: c_root_wing, lambda_wing<br/>out: c_tip_wing"]
            W4["get.cbar_wing<br/>in: c_root_wing, lambda_wing<br/>out: cbar_wing"]
            W5["get.QC_sweep_wing<br/>in: LE_sweep_wing, AR_wing, lambda_wing<br/>out: QC_sweep_wing (mirrored 4/AR)"]
            W6["get.TE_sweep_wing<br/>in: LE_sweep_wing, AR_wing, lambda_wing<br/>out: TE_sweep_wing"]
            W7["get.tc_r_wing, get.tc_t_wing<br/>in: tc_wing<br/>out: tc_r_wing = tc_t_wing = tc_wing"]
            W8["get.S_exposed_wing<br/>in: c_root_wing, c_tip_wing,<br/>b_wing/2, W_max_fuselage/2<br/>out: S_exposed_wing"]
            W9["get.S_wet_wing<br/>in: obj<br/>out: S_wet_wing"]
            W10["get_S_wet_wing(obj)<br/>in: S_exposed_wing, tc_r_wing,<br/>tc_t_wing, lambda_wing<br/>out: S_wet_wing"]
            W11["get_S_exposed_wing(obj)<br/>in: S_exposed_wing<br/>out: S_exposed_wing"]
        end

        subgraph HT["Horizontal tail"]
            INHT["Inputs<br/>S_ht, B_h, lambda_ht, LE_sweep_ht,<br/>tc_r_ht, tc_t_ht, F_w, x_le_ht,<br/>AR_exposed_ht, lambda_exposed_ht"]
            H0["get.AR_ht<br/>in: B_h, S_ht<br/>out: AR_ht = B_h^2/S_ht = 3.169 (derived)"]
            H1["get.b_ht<br/>in: B_h<br/>out: b_ht = B_h (primary span)"]
            H2["get.c_root_ht<br/>in: S_ht, b_ht, lambda_ht<br/>out: c_root_ht"]
            H3["get.c_tip_ht<br/>in: c_root_ht, lambda_ht<br/>out: c_tip_ht"]
            H4["get.QC_sweep_ht<br/>in: LE_sweep_ht, AR_ht, lambda_ht<br/>out: QC_sweep_ht (mirrored 4/AR)"]
            H5["get.TE_sweep_ht<br/>in: LE_sweep_ht, AR_ht, lambda_ht<br/>out: TE_sweep_ht"]
            H6["get.tc_ht<br/>in: tc_r_ht, tc_t_ht<br/>out: tc_ht = mean = 0.0475"]
            H7["get.S_exposed_ht<br/>in: c_root_ht, c_tip_ht,<br/>b_ht/2, W_max_fuselage/2<br/>out: S_exposed_ht"]
            H8["get.S_wet_ht<br/>in: obj<br/>out: S_wet_ht"]
            H9["get_S_wet_HT(obj)<br/>in: S_exposed_ht, tc_r_ht,<br/>tc_t_ht, lambda_ht<br/>out: S_wet_ht"]
        end

        subgraph VT["Vertical tail"]
            INVT["Inputs<br/>S_vt, AR_vt, lambda_vt, LE_sweep_vt = 47.5,<br/>tc_r_vt, tc_t_vt, H_t, H_v, x_le_vt,<br/>AR_exposed_vt, lambda_exposed_vt"]
            V1["get.b_vt<br/>in: S_vt, AR_vt<br/>out: b_vt = sqrt(S_vt*AR_vt), not halved"]
            V2["get.c_root_vt<br/>in: S_vt, b_vt, lambda_vt<br/>out: c_root_vt"]
            V3["get.c_tip_vt<br/>in: c_root_vt, lambda_vt<br/>out: c_tip_vt"]
            V4["get.QC_sweep_vt<br/>in: LE_sweep_vt, AR_vt, lambda_vt<br/>out: QC_sweep_vt (single panel 2/AR)"]
            V5["get.TE_sweep_vt<br/>in: LE_sweep_vt, AR_vt, lambda_vt<br/>out: TE_sweep_vt (single panel 2/AR)"]
            V6["get.tc_vt<br/>in: tc_r_vt, tc_t_vt<br/>out: tc_vt = mean = 0.0415"]
            V7["get.S_exposed_vt<br/>in: S_vt, AR_vt, c_root_vt,<br/>c_tip_vt, H_max_fuselage/2<br/>out: S_exposed_vt"]
            V8["get.S_wet_vt<br/>in: obj<br/>out: S_wet_vt"]
            V9["get_S_wet_VT(obj)<br/>in: S_exposed_vt, tc_r_vt,<br/>tc_t_vt, lambda_vt<br/>out: S_wet_vt"]
        end

        subgraph FUS["Fuselage and whole aircraft"]
            INFUS["Inputs<br/>L_fus = 47.5, W_max_fuselage, H_max_fuselage,<br/>frames_normalized (20x3), L_aircraft"]
            FU1["get.L_fuselage<br/>in: L_fus<br/>out: L_fuselage = L_fus"]
            FU2["get.D_fus<br/>in: W_max_fuselage, H_max_fuselage<br/>out: D_fus = mean (Roskam Eq. 12.3 term only)"]
            FU3["get_S_wet_fuselage(obj)<br/>in: D_fus, L_fus<br/>out: S_wet_fuselage"]
            FU4["get.Amax<br/>in: frames_normalized, envelope, the nine<br/>area-rule intermediates, chords, sweeps,<br/>t/c, D_inlet, x_inlet, x_nacelle_aft, n_engines<br/>out: Amax (area-ruled)"]
        end

        subgraph DUCT["Inlet and engine duct"]
            INENG["Inputs<br/>L_duct, x_inlet = 15.0, n_engines"]
            E1["get.T_AB_SLS_lb<br/>in: prop.T_SL<br/>out: T_AB_SLS_lb"]
            E2["get.D_inlet<br/>in: T_AB_SLS_lb<br/>out: D_inlet"]
            E3["get.D_exit<br/>in: D_inlet<br/>out: D_exit = D_inlet"]
            E4["get.L_engine<br/>in: D_inlet<br/>out: L_engine"]
            E5["get.x_nacelle_aft<br/>in: x_inlet, L_duct, L_engine<br/>out: x_nacelle_aft"]
            E6["get_S_wet_duct(obj)<br/>in: D_inlet, D_exit, L_duct<br/>out: S_wet_duct"]
        end

        subgraph AREA["Area-ruled Amax intermediates"]
            A1["get.c_exp_root_wing<br/>in: c_root_wing, c_tip_wing,<br/>b_wing/2, W_max_fuselage/2<br/>out: c_exp_root_wing"]
            A2["get.c_exp_root_ht<br/>in: c_root_ht, c_tip_ht,<br/>b_ht/2, W_max_fuselage/2<br/>out: c_exp_root_ht"]
            A3["get.c_exp_root_vt<br/>in: c_root_vt, c_tip_vt,<br/>b_vt, H_max_fuselage/2<br/>out: c_exp_root_vt"]
            A4["get.G_hs_exp_wing<br/>in: b_wing, W_max_fuselage<br/>out: b_wing/2 - W_max/2"]
            A5["get.G_hs_exp_ht<br/>in: b_ht, W_max_fuselage<br/>out: b_ht/2 - W_max/2"]
            A6["get.G_hs_exp_vt<br/>in: b_vt, H_max_fuselage<br/>out: b_vt - H_max/2"]
            A7["get.Xexp_wing<br/>in: x_apex_wing, W_max_fuselage/2, LE_sweep_wing<br/>out: Xexp_wing"]
            A8["get.Xexp_ht<br/>in: x_le_ht, W_max_fuselage/2, LE_sweep_ht<br/>out: Xexp_ht"]
            A9["get.Xexp_vt<br/>in: x_le_vt, H_max_fuselage/2, LE_sweep_vt<br/>out: Xexp_vt"]
        end

        subgraph CS["Control-surface areas"]
            INCS["Sizing-loop outputs, seeded<br/>S_rud = 11.65, S_flaperon = 31.32,<br/>S_lef = 36.71, S_stab = S_ht = 108<br/>S_ail = NaN, S_elev = NaN"]
            C1["get.S_csw<br/>in: S_flaperon, S_lef<br/>out: S_csw = 68.03"]
            C2["get.S_r<br/>in: S_rud<br/>out: S_r = S_rud"]
            C3["get.S_cs<br/>in: S_csw, S_stab, S_rud<br/>out: S_cs = 187.68"]
        end

        subgraph MAC["MAC stations and tail moment arms"]
            M1["get.x_mac_le_wing<br/>in: b_wing, lambda_wing,<br/>x_apex_wing, LE_sweep_wing<br/>out: x_mac_le_wing"]
            M2["get.x_c4_wing<br/>in: x_mac_le_wing, cbar_wing<br/>out: x_c4_wing = 25.5891"]
            M3["get.x_c4_ht<br/>in: c_root_ht, lambda_ht,<br/>b_ht, x_le_ht, LE_sweep_ht<br/>out: x_c4_ht (mirrored form)"]
            M4["get.x_c4_vt<br/>in: c_root_vt, lambda_vt,<br/>b_vt, x_le_vt, LE_sweep_vt<br/>out: x_c4_vt (panel form)"]
            M5["get.L_HT<br/>in: x_c4_ht, x_c4_wing<br/>out: L_HT"]
            M6["get.L_VT<br/>in: x_c4_vt, x_c4_wing<br/>out: L_VT"]
            M7["get.L_t<br/>in: L_HT<br/>out: L_t = L_HT (Raymer Eq. 15.3 symbol)"]
        end

        TOT["get.S_wet<br/>in: obj<br/>out: S_wet"]
        TOTM["get_S_wet(obj)<br/>in: obj<br/>out: wing + HT + VT + fuselage + duct"]
    end

    subgraph TOOLBASE["GeometryBase toolbox (static methods)"]
        B1["compute_span(AR, S_ref)"]
        B2["compute_root_chord(S_ref, b, lambda)<br/>Raymer 7th ed. Eq. 7.6"]
        B3["compute_tip_chord(c_root, lambda)<br/>Raymer 7th ed. Eq. 7.7"]
        B4["compute_mac(c_root, lambda)<br/>Raymer 7th ed. Eq. 7.8"]
        B5["convert_sweep(Lambda_LE, AR, lambda, x)<br/>mirrored 4/AR form"]
        B6["convert_sweep_panel(Lambda_LE, AR, lambda, x)<br/>single-panel 2/AR form"]
        B7["compute_y_mac(b, lambda)"]
        B8["compute_y_mac_panel(b_panel, lambda)"]
        B9["compute_x_mac_le(x_apex, y_mac, LE_sweep_deg)"]
        B10["compute_x_mac_quarter_chord(x_mac_le, cbar)"]
        B11["compute_nacelle_diameter(T_AB_SLS_lb)"]
        D7["compute_Amax_elliptical(W_max, H_max)<br/>NOT CALLED at L3 (this is L2's form)"]
    end

    subgraph TOOLL3["GeomL3 toolbox (static methods)"]
        L3S["get_S_wet(obj)<br/>sum of the five terms"]
        L3W["get_S_wet_wing(obj)<br/>Roskam Vol. II Eq. 12.1"]
        L3H["get_S_wet_HT(obj)<br/>Roskam Vol. II Eq. 12.1"]
        L3V["get_S_wet_VT(obj)<br/>Roskam Vol. II Eq. 12.1"]
        L3F["get_S_wet_fuselage(obj)<br/>Roskam Vol. II Eq. 12.3"]
        L3D["get_S_wet_duct(obj)<br/>Raymer 6th ed. Sec. 7.3"]
        L3A["get_Amax(obj)<br/>Brandt Geom!H26:H45 -> H47"]
        L3CR["compute_c_root_exposed(c_root, c_tip,<br/>span_root_to_tip, span_clipped)"]
        L3EL["compute_engine_length(D_engine)<br/>4.5*D, uncited"]
        L3DN["denormalize_frames(frames_normalized,<br/>L_fus, W_max, H_max)<br/>affine rescale, uncited"]
        L3FA["compute_frame_cs_area(w, h)<br/>six-point cosine grid"]
        L3SA["compute_surface_cs_area(x, Xexp, c_exp_root,<br/>c_tip, G_hs_exp, sweep_LE, tc)"]
        L3NA["compute_nacelle_cs_area(x, n_engines,<br/>D_engine, x_start, x_end)"]
        L3AR["compute_Amax_area_ruled(A_total_stations,<br/>n_engines, D_engine)<br/>bare /5 divisor, uncited"]
        L3EW["get_S_exposed_wing(obj)<br/>in: obj.S_exposed_wing<br/>out: the same value"]
        D1["compute_frame_cs_area_exact(w, h)<br/>NOT CALLED at L3"]
    end

    subgraph TOOLL2["GeomL2 toolbox (static methods reused by L3)"]
        L2RP["compute_roskam_planform(S_exp, tc_r, tc_t, lambda)<br/>Roskam Vol. II Eq. 12.1"]
        L2FC["compute_s_wet_fus_cyl(D_fus, L_fus)<br/>Roskam Vol. II Eq. 12.3"]
        L2DU["compute_s_wet_duct(D_inlet, D_exit, L_duct)"]
        L2H["compute_S_exposed_horizontal(c_root, c_tip, hs, fw)"]
        L2V["compute_S_exposed_vertical(S, AR, c_root, c_tip, fh)"]
        D2["compute_wet_planform(S_exp, tc)<br/>NOT CALLED at L3"]
        D3["get_S_wet_fuselage_brandt_lowfi(obj)<br/>NOT CALLED at L3"]
        D4["compute_s_wet_fus_brandt_lowfi(...)<br/>NOT CALLED at L3"]
        D5["compute_s_wet_fus_brandt_highfi(...)<br/>NOT CALLED at L3"]
        D6["compute_frame_perimeter(w, h, z_chine, z_center)<br/>NOT CALLED at L3"]
    end

    subgraph TOOLTAIL["TailL1 toolbox"]
        TA1["compute_tail_arm_quarter_chord(x_c4_a, x_c4_b)<br/>Raymer 6th ed. Sec. 6.5.2"]
    end

    J -->|"wing: S_ft2=300, AR=3.0, taper=0.2275, sweep_LE_deg=40,<br/>tc_ratio=0.04, x_apex_ft=17.786,<br/>flaperon_area_ft2=31.32, LEF_area_ft2=36.71"| CTOR
    J -->|"horizontal_tail: S_ft2=108, span_ft=18.5, taper=0.2275,<br/>sweep_LE_deg=40, tc_root=0.060, tc_tip=0.035,<br/>F_w_ft=7.0, AR_exposed=2.114, taper_exposed=0.390,<br/>x_le_ft=36.0 (no AR key by design)"| CTOR
    J -->|"vertical_tail: S_ft2=60, AR=1.6, taper=0.5,<br/>sweep_LE_deg=47.5, tc_root=0.053, tc_tip=0.030,<br/>rudder_area_ft2=11.65, H_t_ft=0, H_v_ft=1,<br/>AR_exposed=1.294, taper_exposed=0.437, x_le_ft=36.0"| CTOR
    J -->|"fuselage: length_ft=47.5, max_width_ft=7.0,<br/>max_depth_ft=5.0, frames_normalized (20 rows)"| CTOR
    J -->|"engine: duct_length_ft=14.0,<br/>x_inlet_ft=15.0, n_engines=1"| CTOR
    J -->|"overall_length_ft=47.65 -> L_aircraft"| CTOR
    PROP -->|"prop"| CTOR

    CTOR -->|"S_ref, AR_wing, lambda_wing,<br/>LE_sweep_wing, tc_wing, x_apex_wing"| INW
    CTOR -->|"S_ht, B_h, lambda_ht, LE_sweep_ht, tc_r_ht,<br/>tc_t_ht, F_w, x_le_ht, AR_exposed_ht, lambda_exposed_ht"| INHT
    CTOR -->|"S_vt, AR_vt, lambda_vt, LE_sweep_vt, tc_r_vt,<br/>tc_t_vt, H_t, H_v, x_le_vt, AR_exposed_vt, lambda_exposed_vt"| INVT
    CTOR -->|"L_fus, W_max_fuselage, H_max_fuselage,<br/>frames_normalized, L_aircraft"| INFUS
    CTOR -->|"L_duct, x_inlet, n_engines"| INENG
    CTOR -->|"S_rud, S_flaperon, S_lef, S_stab (seeded)<br/>S_ail, S_elev (NaN)"| INCS
    CTOR -->|"prop.T_SL"| E1
    CTOR -->|"obj.S_ref"| SREF

    INW -->|"AR_wing, S_ref"| W1
    W1 -->|"b_wing"| W2
    W2 -->|"c_root_wing"| W3
    W2 -->|"c_root_wing"| W4
    INW -->|"LE_sweep_wing, AR_wing, lambda_wing"| W5
    INW -->|"LE_sweep_wing, AR_wing, lambda_wing"| W6
    INW -->|"tc_wing"| W7
    W1 -->|"b_wing/2"| W8
    W2 -->|"c_root_wing"| W8
    W3 -->|"c_tip_wing"| W8
    INFUS -->|"W_max_fuselage/2"| W8
    W7 -->|"tc_r_wing, tc_t_wing"| W10
    W8 -->|"S_exposed_wing"| W10
    INW -->|"lambda_wing"| W10
    W9 -->|"calls get_S_wet_wing"| W10
    W8 -->|"S_exposed_wing"| W11

    INHT -->|"B_h, S_ht"| H0
    INHT -->|"B_h"| H1
    INHT -->|"S_ht, lambda_ht"| H2
    H1 -->|"b_ht"| H2
    H2 -->|"c_root_ht"| H3
    H0 -->|"AR_ht"| H4
    INHT -->|"LE_sweep_ht, lambda_ht"| H4
    H0 -->|"AR_ht"| H5
    INHT -->|"LE_sweep_ht, lambda_ht"| H5
    INHT -->|"tc_r_ht, tc_t_ht"| H6
    H2 -->|"c_root_ht"| H7
    H3 -->|"c_tip_ht"| H7
    H1 -->|"b_ht/2"| H7
    INFUS -->|"W_max_fuselage/2"| H7
    H7 -->|"S_exposed_ht"| H9
    INHT -->|"tc_r_ht, tc_t_ht, lambda_ht"| H9
    H8 -->|"calls get_S_wet_HT"| H9

    INVT -->|"S_vt, AR_vt"| V1
    V1 -->|"b_vt"| V2
    INVT -->|"S_vt, lambda_vt"| V2
    V2 -->|"c_root_vt"| V3
    INVT -->|"LE_sweep_vt, AR_vt, lambda_vt"| V4
    INVT -->|"LE_sweep_vt, AR_vt, lambda_vt"| V5
    INVT -->|"tc_r_vt, tc_t_vt"| V6
    V2 -->|"c_root_vt"| V7
    V3 -->|"c_tip_vt"| V7
    INVT -->|"S_vt, AR_vt"| V7
    INFUS -->|"H_max_fuselage/2"| V7
    V7 -->|"S_exposed_vt"| V9
    INVT -->|"tc_r_vt, tc_t_vt, lambda_vt"| V9
    V8 -->|"calls get_S_wet_VT"| V9

    INFUS -->|"L_fus"| FU1
    INFUS -->|"W_max_fuselage, H_max_fuselage"| FU2
    FU2 -->|"D_fus"| FU3
    INFUS -->|"L_fus"| FU3
    INFUS -->|"frames_normalized, L_fus, W_max, H_max"| FU4

    W2 -->|"c_root_wing"| A1
    W3 -->|"c_tip_wing"| A1
    W1 -->|"b_wing/2"| A1
    INFUS -->|"W_max_fuselage/2"| A1
    H2 -->|"c_root_ht"| A2
    H3 -->|"c_tip_ht"| A2
    H1 -->|"b_ht/2"| A2
    INFUS -->|"W_max_fuselage/2"| A2
    V2 -->|"c_root_vt"| A3
    V3 -->|"c_tip_vt"| A3
    V1 -->|"b_vt"| A3
    INFUS -->|"H_max_fuselage/2"| A3
    W1 -->|"b_wing"| A4
    INFUS -->|"W_max_fuselage"| A4
    H1 -->|"b_ht"| A5
    INFUS -->|"W_max_fuselage"| A5
    V1 -->|"b_vt"| A6
    INFUS -->|"H_max_fuselage"| A6
    INW -->|"x_apex_wing, LE_sweep_wing"| A7
    INFUS -->|"W_max_fuselage/2"| A7
    INHT -->|"x_le_ht, LE_sweep_ht"| A8
    INFUS -->|"W_max_fuselage/2"| A8
    INVT -->|"x_le_vt, LE_sweep_vt"| A9
    INFUS -->|"H_max_fuselage/2"| A9

    A1 -->|"c_exp_root_wing"| FU4
    A2 -->|"c_exp_root_ht"| FU4
    A3 -->|"c_exp_root_vt"| FU4
    A4 -->|"G_hs_exp_wing"| FU4
    A5 -->|"G_hs_exp_ht"| FU4
    A6 -->|"G_hs_exp_vt"| FU4
    A7 -->|"Xexp_wing"| FU4
    A8 -->|"Xexp_ht"| FU4
    A9 -->|"Xexp_vt"| FU4
    E2 -->|"D_inlet"| FU4
    E5 -->|"x_nacelle_aft"| FU4
    INENG -->|"x_inlet, n_engines"| FU4
    W3 -->|"c_tip_wing"| FU4
    H3 -->|"c_tip_ht"| FU4
    V3 -->|"c_tip_vt"| FU4
    INW -->|"tc_wing, LE_sweep_wing"| FU4
    INHT -->|"LE_sweep_ht"| FU4
    H6 -->|"tc_ht"| FU4
    INVT -->|"LE_sweep_vt"| FU4
    V6 -->|"tc_vt"| FU4

    E1 -->|"T_AB_SLS_lb"| E2
    E2 -->|"D_inlet"| E3
    E2 -->|"D_inlet"| E4
    E4 -->|"L_engine"| E5
    INENG -->|"x_inlet, L_duct"| E5
    E2 -->|"D_inlet"| E6
    E3 -->|"D_exit"| E6
    INENG -->|"L_duct"| E6

    INCS -->|"S_flaperon, S_lef"| C1
    INCS -->|"S_rud"| C2
    C1 -->|"S_csw"| C3
    INCS -->|"S_stab, S_rud"| C3

    W1 -->|"b_wing"| M1
    INW -->|"lambda_wing, x_apex_wing, LE_sweep_wing"| M1
    M1 -->|"x_mac_le_wing"| M2
    W4 -->|"cbar_wing"| M2
    INHT -->|"lambda_ht, x_le_ht, LE_sweep_ht"| M3
    H1 -->|"b_ht"| M3
    H2 -->|"c_root_ht"| M3
    INVT -->|"lambda_vt, x_le_vt, LE_sweep_vt"| M4
    V1 -->|"b_vt"| M4
    V2 -->|"c_root_vt"| M4
    M2 -->|"x_c4_wing"| M5
    M3 -->|"x_c4_ht"| M5
    M2 -->|"x_c4_wing"| M6
    M4 -->|"x_c4_vt"| M6
    M5 -->|"L_HT"| M7

    TOT -->|"calls get_S_wet"| TOTM

    W1 -->|"get.b_wing: AR_wing, S_ref"| B1
    W2 -->|"get.c_root_wing: S_ref, b_wing, lambda_wing"| B2
    W3 -->|"get.c_tip_wing: c_root_wing, lambda_wing"| B3
    W4 -->|"get.cbar_wing: c_root_wing, lambda_wing"| B4
    W5 -->|"get.QC_sweep_wing: LE_sweep_wing, AR_wing, lambda_wing, 0.25"| B5
    W6 -->|"get.TE_sweep_wing: LE_sweep_wing, AR_wing, lambda_wing, 1.0"| B5
    W8 -->|"get.S_exposed_wing: c_root_wing, c_tip_wing, b_wing/2, W_max_fuselage/2"| L2H
    W10 -->|"get_S_wet_wing: obj"| L3W
    W11 -->|"get_S_exposed_wing: obj"| L3EW

    H2 -->|"get.c_root_ht: S_ht, b_ht, lambda_ht"| B2
    H3 -->|"get.c_tip_ht: c_root_ht, lambda_ht"| B3
    H4 -->|"get.QC_sweep_ht: LE_sweep_ht, AR_ht, lambda_ht, 0.25"| B5
    H5 -->|"get.TE_sweep_ht: LE_sweep_ht, AR_ht, lambda_ht, 1.0"| B5
    H7 -->|"get.S_exposed_ht: c_root_ht, c_tip_ht, b_ht/2, W_max_fuselage/2"| L2H
    H9 -->|"get_S_wet_HT: obj"| L3H

    V2 -->|"get.c_root_vt: S_vt, b_vt, lambda_vt"| B2
    V3 -->|"get.c_tip_vt: c_root_vt, lambda_vt"| B3
    V4 -->|"get.QC_sweep_vt: LE_sweep_vt, AR_vt, lambda_vt, 0.25"| B6
    V5 -->|"get.TE_sweep_vt: LE_sweep_vt, AR_vt, lambda_vt, 1.0"| B6
    V7 -->|"get.S_exposed_vt: S_vt, AR_vt, c_root_vt, c_tip_vt, H_max_fuselage/2"| L2V
    V9 -->|"get_S_wet_VT: obj"| L3V

    FU3 -->|"get_S_wet_fuselage: obj"| L3F
    FU4 -->|"get.Amax: obj"| L3A

    E2 -->|"get.D_inlet: T_AB_SLS_lb"| B11
    E4 -->|"get.L_engine: D_inlet"| L3EL
    E6 -->|"get_S_wet_duct: obj"| L3D

    A1 -->|"get.c_exp_root_wing: c_root_wing, c_tip_wing, b_wing/2, W_max_fuselage/2"| L3CR
    A2 -->|"get.c_exp_root_ht: c_root_ht, c_tip_ht, b_ht/2, W_max_fuselage/2"| L3CR
    A3 -->|"get.c_exp_root_vt: c_root_vt, c_tip_vt, b_vt, H_max_fuselage/2"| L3CR

    M1 -->|"get.x_mac_le_wing: b_wing, lambda_wing"| B7
    M1 -->|"get.x_mac_le_wing: x_apex_wing, y_mac, LE_sweep_wing"| B9
    M2 -->|"get.x_c4_wing: x_mac_le_wing, cbar_wing"| B10
    M3 -->|"get.x_c4_ht: c_root_ht, lambda_ht"| B4
    M3 -->|"get.x_c4_ht: b_ht, lambda_ht"| B7
    M3 -->|"get.x_c4_ht: x_le_ht, y_mac, LE_sweep_ht"| B9
    M3 -->|"get.x_c4_ht: x_mac_le, cbar_ht"| B10
    M4 -->|"get.x_c4_vt: c_root_vt, lambda_vt"| B4
    M4 -->|"get.x_c4_vt: b_vt, lambda_vt"| B8
    M4 -->|"get.x_c4_vt: x_le_vt, y_mac, LE_sweep_vt"| B9
    M4 -->|"get.x_c4_vt: x_mac_le, cbar_vt"| B10
    M5 -->|"get.L_HT: x_c4_ht, x_c4_wing"| TA1
    M6 -->|"get.L_VT: x_c4_vt, x_c4_wing"| TA1

    TOTM -->|"get_S_wet: obj"| L3S
    SREF -.->|"get_S_ref: no external calls"| NC

    L3S -->|"get_S_wet: obj"| L3W
    L3S -->|"get_S_wet: obj"| L3H
    L3S -->|"get_S_wet: obj"| L3V
    L3S -->|"get_S_wet: obj"| L3F
    L3S -->|"get_S_wet: obj"| L3D
    L3W -->|"S_exposed_wing, tc_r_wing, tc_t_wing, lambda_wing"| L2RP
    L3H -->|"S_exposed_ht, tc_r_ht, tc_t_ht, lambda_ht"| L2RP
    L3V -->|"S_exposed_vt, tc_r_vt, tc_t_vt, lambda_vt"| L2RP
    L3F -->|"D_fus, L_fus"| L2FC
    L3D -->|"D_inlet, D_exit, L_duct"| L2DU
    L3A -->|"frames_normalized, L_fus,<br/>W_max_fuselage, H_max_fuselage"| L3DN
    L3A -->|"w, h (denormalized frames)"| L3FA
    L3A -->|"x, Xexp, c_exp_root, c_tip,<br/>G_hs_exp, sweep_LE, tc (per surface)"| L3SA
    L3A -->|"x, n_engines, D_inlet,<br/>x_inlet, x_nacelle_aft"| L3NA
    L3A -->|"A_fuse + A_wing + A_HT + A_VT + A_nac,<br/>n_engines, D_inlet"| L3AR

    L3FA -.->|"no upstream call, exact 2/pi alternate"| D1
    L3W -.->|"no upstream call, Brandt uniform-tc alternate"| D2
    L3F -.->|"no upstream call"| D3
    D3 -.->|"no upstream call"| D4
    D3 -.->|"no upstream call"| D5
    D5 -.->|"no upstream call"| D6
    FU4 -.->|"no upstream call at L3, L2's envelope form"| D7
    L3EW -.->|"GeomL3.get_S_exposed_wing: no external calls"| NC

    linkStyle 0,1,2,3,4,5,6 stroke:#00e5ff,color:#00e5ff,stroke-width:2px
    linkStyle 13,14,21,31,32,40,48,54,62,63,79,80,81,82,83,84,85,86,87,88,89,90,112,114,115,119,120,121,122,137,182,205 stroke:#ffe100,color:#ffe100,stroke-width:2px,stroke-dasharray:4 3
    linkStyle 15,16,17,18,19,20,22,23,24,25,26,27,28,29,30,33,34,35,36,37,38,39,41,42,43,44,45,46,47,49,50,51,52,53,55,56,57,58,59,60,61,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,113,116,117,118,123,124,125,126,127,128,129,130,131,132,133,134,135,136,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197 stroke:#33cc33,color:#33cc33,stroke-width:2px
    linkStyle 198,199,200,201,202,203,204 stroke:#ff4040,color:#ff4040,stroke-width:2px,stroke-dasharray:5 5

    classDef dead fill:#000000,stroke:#ff4040,stroke-width:3px,color:#ff4040,stroke-dasharray: 6 4
    classDef ctor fill:#000000,stroke:#00e5ff,stroke-width:3px,color:#00e5ff
    classDef func fill:#000000,stroke:#33cc33,stroke-width:2px,color:#33cc33
    classDef passthrough fill:#000000,stroke:#ffe100,stroke-width:2px,color:#ffe100,stroke-dasharray: 4 3
    class D1,D2,D3,D4,D5,D6,D7 dead
    class CTOR ctor
    class W1,W2,W3,W4,W5,W6,W8,W9,W10,W11,H2,H3,H4,H5,H7,H8,H9,V2,V3,V4,V5,V7,V8,V9,FU3,FU4,A1,A2,A3,E2,E4,E6,M1,M2,M3,M4,M5,M6,TOT,TOTM,B1,B2,B3,B4,B5,B6,B7,B8,B9,B10,B11,L3S,L3W,L3H,L3V,L3F,L3D,L3A,L3CR,L3EL,L3DN,L3FA,L3SA,L3NA,L3AR,L2RP,L2FC,L2DU,L2H,L2V,TA1 func
    class W7,H0,H1,H6,V1,V6,FU1,FU2,A4,A5,A6,A7,A8,A9,E1,E3,E5,C1,C2,C3,M7,SREF,L3EW,NC passthrough
```

## Field-by-field notes

| Class member | Source | Notes |
| --- | --- | --- |
| `S_ref, AR_wing, lambda_wing, LE_sweep_wing, tc_wing, x_apex_wing` | `f16a_L3.json`, `.geometry.wing` | Wing spec data. `x_apex_wing` was added for the area-ruled `Amax`. |
| `S_flaperon, S_lef` | `.geometry.wing.flaperon_area_ft2`, `.LEF_area_ft2` | T.O. 1F-16A-1 Fig. 1-2 measured areas. Seeded, then overwritten by the sizing loop. |
| `S_ht, B_h, lambda_ht, LE_sweep_ht, tc_r_ht, tc_t_ht, F_w, AR_exposed_ht, lambda_exposed_ht, x_le_ht` | `.geometry.horizontal_tail` | The JSON has NO `AR` key here by design. `S_ft2` plus `span_ft` fix the planform. |
| `AR_ht` (Dependent) | `B_h^2 / S_ht` | 3.1690, Decision 1. Brandt's 3.0 is a comparison reference only, not an input. |
| `S_vt, AR_vt, lambda_vt, LE_sweep_vt, tc_r_vt, tc_t_vt, H_t, H_v, AR_exposed_vt, lambda_exposed_vt, x_le_vt` | `.geometry.vertical_tail` | `LE_sweep_vt` = 47.5 deg, the physical value. L2 uses Brandt's 40. Intentional. |
| `S_rud` | `.geometry.vertical_tail.rudder_area_ft2` | Seeded 11.65, then a sizing-loop output. |
| `L_fus, W_max_fuselage, H_max_fuselage` | `.geometry.fuselage` | `L_fus` = 47.5 ft, the physical value. L2 uses Brandt's 46.5. Intentional. `max_depth_ft` is the Raymer Eq. 15.4 structural depth, NOT the Dependent `D_fus`. |
| `frames_normalized` | `.geometry.fuselage.frames_normalized` | 20 rows, flattened to an (N,3) numeric table `[x/L, w/W_max, h/H_max]`. Stored NORMALIZED so the envelope inputs rescale it. The affine rescaling has no textbook citation and is an OPEN item. |
| `L_aircraft` | `.geometry.overall_length_ft` | 47.65 ft. Feeds only the Raymer Eq. 12.44 Sears-Haack term. Citation NOT pinned, an OPEN item. |
| `L_duct, x_inlet, n_engines` | `.geometry.engine` | `x_inlet` = 15.0 ft. A read-only ground-truth JSON key says 14.0, which is mislabelled. |
| `prop` | Constructor argument, injected | `PropulsionBase`. Only `prop.T_SL` is read. An `F16PropL2` at this rung. |
| `Amax` (Dependent) | `GeomL3.get_Amax` | Whole-aircraft AREA-RULED buildup, 24.7037 ft^2. NOT the L2 envelope ellipse. The `/5` flow-through divisor is an uncited literal, an OPEN item. |
| `S_wet_wing, S_wet_ht, S_wet_vt` (Dependent) | `GeomL3.get_S_wet_*` then `GeomL2.compute_roskam_planform` | Roskam Vol. II Eq. 12.1 on the T.O. root/tip t/c splits. |
| `S_csw, S_r, S_cs` (Dependent) | `S_flaperon + S_lef`; `S_rud`; `S_csw + S_stab + S_rud` | All three were frozen inputs until 2026-08-10. The stabilator enters `S_cs` at full `S_ht`. |
| `L_HT, L_VT, L_t` (Dependent) | `TailL1.compute_tail_arm_quarter_chord` | `L_t` is an alias of `L_HT`, kept because Raymer Eq. 15.3 uses that symbol. |
| `S_ail`, `S_elev` | Never set by the constructor | Stay `NaN`. The class header and the enforcer both describe them as 0 for the F-16. |

## Methods with no upstream call at L3

| Method | Why it has no upstream call at L3 |
| --- | --- |
| `GeometryBase.compute_Amax_elliptical` | The L2 envelope-ellipse form. L3 uses the area-ruled buildup instead. A deliberate fidelity split. |
| `GeomL3.compute_frame_cs_area_exact` | The exact `(2/pi)*w*h` form. `get_Amax` calls the six-point cosine grid form to match Brandt's own sampling. No caller anywhere in the repo. |
| `GeomL2.compute_wet_planform` | Brandt's uniform-t/c wetted-area form. A comparison-report alternate only, per Decision 2. Called by `geometry_brandt_comparison.m`, never by a discipline class. |
| `GeomL2.get_S_wet_fuselage_brandt_lowfi` | Comparison-only alternate to `get_S_wet_fuselage`. |
| `GeomL2.compute_s_wet_fus_brandt_lowfi` | Only reachable through `get_S_wet_fuselage_brandt_lowfi`. |
| `GeomL2.compute_s_wet_fus_brandt_highfi` | Only reachable through `get_S_wet_fuselage_brandt_lowfi`. |
| `GeomL2.compute_frame_perimeter` | Only reachable through `compute_s_wet_fus_brandt_highfi`. |

## Source files

| Item | File |
| --- | --- |
| Concrete class | `examples/F16A/models/disciplines/geom/F16GeomL3.m` |
| Tier 2, abstract | `src/disciplines/geometry/GeometryModelL3.m` |
| Tier 1, base | `src/base/GeometryBase.m` |
| Toolbox, L3 | `src/disciplines/geometry/GeomL3.m` |
| Toolbox, L2 reused | `src/disciplines/geometry/GeomL2.m` |
| Tail-arm helper | `src/disciplines/tail_sizing/TailL1.m` |
| Injected propulsion | `examples/F16A/models/disciplines/prop/F16PropL2.m` |
| Input JSON | `examples/F16A/inputs/f16a_L3.json` |
