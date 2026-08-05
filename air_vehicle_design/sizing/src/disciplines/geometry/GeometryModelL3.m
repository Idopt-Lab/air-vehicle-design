classdef (Abstract) GeometryModelL3 < GeometryBase
%GEOMETRYMODELL3  Tier-2 abstract enforcer for Level-3 geometry.
%
%   Inherits GeometryBase directly, not GeometryModelL2: each fidelity level
%   satisfies the Tier-1 contract independently.
%
%   L3 is the physical / T.O. tier, consumed by L3 geometry, aerodynamics and
%   weights. Divergences from L2 are intentional fidelity differences.
%
%   NAMING. AR_ht / lambda_ht / S_ht / S_vt mean FULL planform at both tiers;
%   the exposed values carry an explicit _exposed_ infix. Members marked
%   [DERIVED] below must be Dependent getters on the concrete class, never
%   stored values.
%
%   Authoritative spec: examples/F16A/F16GeomL3.md
%   Toolbox companion:  src/disciplines/geometry/GeomL3.md


    % Abstract properties cannot have validation attributes in MATLAB.
    % Size/type validation is enforced in the concrete class (F16GeomL3).

    % ── Fuselage / whole aircraft ───────────────────────────────────────── %
    properties (Abstract)
        L_fus             % Fuselage length (ft)               [INPUT]  47.5, physical
        L_fuselage        % Mirrors L_fus (GeometryModelL2 contract parity) [DERIVED]
        W_max_fuselage    % Maximum fuselage width (ft)        [INPUT]
        H_max_fuselage    % Maximum fuselage DEPTH (ft)        [INPUT]  weights' "D_fus"
        frames_normalized % (N,3) NORMALIZED frame table       [INPUT]  cols [x/L, w/W_max, h/H_max]
        D_fus             % Equivalent diameter (W+H)/2 (ft)   [DERIVED] Roskam Eq. 12.3 term only
        Amax              % Max cross-sectional area (ft²)     [DERIVED] AREA-RULED buildup; Raymer Eq. 12.44
        L_aircraft        % Overall aircraft length (ft)       [INPUT]  Raymer Eq. 12.44 only; NOT L_fus
    end

    % ── Main wing (full-planform inputs; everything else DERIVED) ───────── %
    properties (Abstract)
        AR_wing        % Wing aspect ratio                     [INPUT]  weights' "AR_w"
        lambda_wing    % Wing taper ratio (FULL planform)      [INPUT]  weights' "lambda_w"
        LE_sweep_wing  % Wing LE sweep (deg)                   [INPUT]  weights' "Lambda_LE_w"
        tc_wing        % Wing uniform t/c                      [INPUT]  wing has no root/tip split
        S_csw          % Wing control-surface area (ft²)       [INPUT]  weights' "S_csw"
        x_apex_wing    % Wing apex (root LE) x-station (ft)    [INPUT]  17.786 [Brandt Main!B23]
        b_wing         % Wing span (ft)                        [DERIVED]
        c_root_wing    % Wing root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_wing     % Wing tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        cbar_wing      % Wing MAC (ft)                         [DERIVED] Raymer Eq. 7.8; aero l_ref_comp(1)
        QC_sweep_wing  % Wing Λ_c/4 (deg)                      [DERIVED] convert_sweep(x=0.25)
        TE_sweep_wing  % Wing Λ_TE (deg)                       [DERIVED] convert_sweep(x=1.0)
        tc_r_wing      % Wing root t/c (mirrors tc_wing)       [DERIVED] weights' "tc_root"
        tc_t_wing      % Wing tip  t/c (mirrors tc_wing)       [DERIVED]
        S_exposed_wing % Exposed wing planform area (ft²)      [DERIVED] weights' "S_w"
        S_wet_wing     % Wing wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Horizontal tail — FULL planform from the S_ht + B_h pair ────────── %
    properties (Abstract)
        S_ht              % FULL reference planform area (ft²)  [INPUT]  108; same meaning as L2
        B_h               % HT full span (ft)                   [INPUT]  18.5, PRIMARY (Decision 1)
        lambda_ht         % FULL-planform taper ratio           [INPUT]  0.2275
        LE_sweep_ht       % HT LE sweep (deg)                   [INPUT]  40
        tc_r_ht           % HT root t/c                         [INPUT]  0.060 [T.O. Sec. I]
        tc_t_ht           % HT tip  t/c                         [INPUT]  0.035 [T.O. Sec. I]
        F_w               % Fuselage width at HT (ft)           [INPUT]  weights' "F_w"
        AR_exposed_ht     % HT EXPOSED aspect ratio             [INPUT]  2.114; weights' "AR_ht"
        lambda_exposed_ht % HT EXPOSED taper ratio              [INPUT]  0.390; weights' "lambda_ht"
        x_le_ht           % HT root LE x-station (ft)           [INPUT]  36.0 [Brandt Main!C23]
        AR_ht             % FULL aspect ratio = B_h²/S_ht       [DERIVED] 3.1690 (Decision 1)
        b_ht              % HT span (ft), mirrors B_h           [DERIVED]
        c_root_ht         % HT root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_ht          % HT tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        QC_sweep_ht       % HT Λ_c/4 (deg)                      [DERIVED] convert_sweep(x=0.25)
        TE_sweep_ht       % HT Λ_TE (deg)                       [DERIVED] convert_sweep(x=1.0)
        tc_ht             % HT uniform t/c = (tc_r+tc_t)/2      [DERIVED] 0.0475
        S_exposed_ht      % Exposed HT planform area (ft²)      [DERIVED] 51.1486; weights' "S_ht"
        S_wet_ht          % HT wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Vertical tail — FULL planform, single panel ─────────────────────── %
    properties (Abstract)
        S_vt              % FULL reference planform area (ft²)  [INPUT]  60; same meaning as L2
        AR_vt             % FULL aspect ratio (single panel)    [INPUT]  1.6
        lambda_vt         % FULL-planform taper ratio           [INPUT]  0.5
        LE_sweep_vt       % VT LE sweep (deg)                   [INPUT]  47.5, physical; weights' "Lambda_LE_vt"
        tc_r_vt           % VT root t/c                         [INPUT]  0.053 [T.O. Sec. I]
        tc_t_vt           % VT tip  t/c                         [INPUT]  0.030 [T.O. Sec. I]
        S_r               % VT rudder area (ft²)                [INPUT]  weights' "S_r"
        H_t               % HT height above fuselage CL (ft)    [INPUT]  weights' "H_t"
        H_v               % VT height / nonzero denominator (ft)[INPUT]  weights' "H_v"
        AR_exposed_vt     % VT EXPOSED aspect ratio             [INPUT]  1.294; weights' "AR_vt"
        lambda_exposed_vt % VT EXPOSED taper ratio              [INPUT]  0.437; weights' "lambda_vt"
        x_le_vt           % VT root LE x-station (ft)           [INPUT]  36.0 [Brandt Main!H23]
        b_vt              % VT span (ft), full single panel     [DERIVED] sqrt(S_vt*AR_vt), NOT halved
        c_root_vt         % VT root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_vt          % VT tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        QC_sweep_vt       % VT Λ_c/4 (deg)                      [DERIVED] convert_sweep_PANEL(x=0.25)
        TE_sweep_vt       % VT Λ_TE (deg)                       [DERIVED] convert_sweep_PANEL(x=1.0)
        tc_vt             % VT uniform t/c = (tc_r+tc_t)/2      [DERIVED] 0.0415
        S_exposed_vt      % Exposed VT planform area (ft²)      [DERIVED] 40.8897; weights' "S_vt"
        S_wet_vt          % VT wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Inlet + engine duct ─────────────────────────────────────────────── %
    % T_AB_SLS_lb and the injected propulsion object are deliberately NOT here
    % (engine, not airframe, data — see the class header). D_inlet/D_exit/
    % L_duct are, because L3 aero reads them as D_comp(5) / l_ref_comp(5).
    properties (Abstract)
        L_duct         % Inlet-duct length (ft)                [INPUT]  14.0 [Brandt Main!F32]
        x_inlet        % Inlet-lip x-station (ft)              [INPUT]  15.0 [Brandt Main!F31] — NOT 14.0
        n_engines      % Number of engines (--)                [INPUT]  1 [Brandt Main!B28]
        D_inlet        % Nacelle/inlet diameter (ft)           [DERIVED] sqrt(T_AB_SLS_lb/1900)
        D_exit         % Duct exit diameter (ft) = D_inlet     [DERIVED] constant-section nacelle
        L_engine       % Engine length (ft) = 4.5*D_inlet      [DERIVED] [Brandt Geom!D475]
        x_nacelle_aft  % Nacelle aft limit (ft)                [DERIVED] x_inlet+L_duct+L_engine [Geom!C484]
    end

    % ── Area-ruled Amax buildup — DERIVED intermediates ─────────────────── %
    % These nine, plus L_engine and x_nacelle_aft declared with the duct above,
    % are recomputed live from the inputs; todo.md 2026-07-25 Phase 2 §16.1
    % verified every one is derivable, so none may be stored.
    % Declared in the contract (rather than left as concrete-only locals)
    % because they are also the Brandt comparison-report rows — Geom!F/G/B
    % columns of the Geom!A5:I10 exposed-lifting-surface table.
    % Formulas + citations: GeomL3.compute_c_root_exposed and the class header.
    properties (Abstract)
        c_exp_root_wing % Wing exposed root chord (ft)   [DERIVED] 13.3564 [Brandt Geom!F7]
        c_exp_root_ht   % HT exposed root chord (ft)     [DERIVED] 6.7315  [cf. Geom!F8 = 6.8391]
        c_exp_root_vt   % VT exposed root chord (ft)     [DERIVED] 7.1233  [Brandt Geom!F10]
        G_hs_exp_wing   % Wing exposed half-span (ft)    [DERIVED] 11.5    [Brandt Geom!G7]
        G_hs_exp_ht     % HT exposed half-span (ft)      [DERIVED] 5.75    [cf. Geom!G8 = 5.5]
        G_hs_exp_vt     % VT exposed span (ft), 1 panel  [DERIVED] 7.2980  [Brandt Geom!G10]
        Xexp_wing       % Wing exposed-root LE x (ft)    [DERIVED] 20.7226 [Brandt Geom!B7]
        Xexp_ht         % HT exposed-root LE x (ft)      [DERIVED] 38.9368 [Brandt Geom!B8]
        Xexp_vt         % VT exposed-root LE x (ft)      [DERIVED] 38.7283 [cf. Geom!B10 = 38.0978]
    end

    % ── Configuration ──────────────────────────────────────────────────── %
    properties (Abstract)
        L_t            % Tail arm, wing ¼-MAC → HT ¼-MAC (ft)  [INPUT]  weights' "L_t"
        S_cs           % Total control-surface area (ft²)      [INPUT]  weights' "S_cs"
    end

    methods (Abstract)
        %GET_S_WET_WING  Wing wetted area (ft²). OFFICIAL formula at L3
        %   (Decision 2, user 2026-07-25): Roskam Vol. II Eq. 12.1, variable
        %   root/tip t/c. Brandt's uniform-t/c Geom!B13 form is a
        %   comparison-report alternate only.
        val = get_S_wet_wing(obj)

        %GET_S_WET_HT  Horizontal-tail wetted area (ft²). Roskam Eq. 12.1.
        val = get_S_wet_HT(obj)

        %GET_S_WET_VT  Vertical-tail wetted area (ft²). Roskam Eq. 12.1.
        val = get_S_wet_VT(obj)

        %GET_S_WET_FUSELAGE  Fuselage wetted area (ft²). Roskam Eq. 12.3.
        val = get_S_wet_fuselage(obj)

        %GET_S_WET_DUCT  Inlet + engine-duct wetted area (ft²), frustum lateral
        %   area [Raymer 6th ed. Sec. 7.3]. ADDED in Phase 2 (2026-07-25): L3
        %   aero reads it as S_wet_comp(5).
        val = get_S_wet_duct(obj)

        %GET_S_EXPOSED_WING  Passthrough accessor for the wing exposed area.
        val = get_S_exposed_wing(obj)
    end

    % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
    % Tail sizing is organizationally part of Geometry (Casey's decision, 2026-08-03):
    % the standalone tail_sizing discipline (TailSizingBase/TailSizingModelL3/TailL3/
    % F16TailL3) is retired. Two methods, mirroring the production-vs-stub split
    % that already existed in the deleted discipline:
    %     size_tail(obj)                    -- PRIMARY, WORKING (Raymer 7th ed.
    %                                           Table 6.4 volume-coefficient method,
    %                                           self-referencing obj's own planform)
    %     size_tail_stability_control(obj)  -- documented-TODO stub (Raymer Ch. 16
    %                                           S&C-based sizing -- no citable
    %                                           equation number found anywhere in
    %                                           this repo)
    methods (Abstract)
        %SIZE_TAIL  Horizontal- and vertical-tail reference areas [ft^2],
        %   self-referencing obj's own planform. Also self-mutates obj.S_ht/
        %   obj.S_vt. Returns struct('S_ht', S_ht, 'S_vt', S_vt).
        result = size_tail(obj)

        %SIZE_TAIL_STABILITY_CONTROL  NOT IMPLEMENTED -- citation gap. Raymer
        %   Ch. 16 stability-and-control tail-sizing equations (HT via required
        %   static margin/C_m_alpha; VT via required C_n_beta target +
        %   crosswind) are not verifiable from any source in this repository.
        %   Errors rather than fabricating S_ht/S_vt.
        result = size_tail_stability_control(obj)
    end
    % ==================================================================================================================================== %

    % ======================= CONTROL SURFACE SIZING (absorbed from the former src/sizing/ControlSurfaceSizer.m, 2026-08-03) ============= %
    % Control-surface sizing is organizationally part of Geometry (Casey's decision,
    % 2026-08-03): the standalone ControlSurfaceSizer handle class is retired.
    methods (Abstract)
        %SIZE_CONTROL_SURFACES  Aileron/elevator/rudder areas [ft^2] from
        %   obj's own S_ref/S_ht/S_vt and chord/span fraction properties.
        %   Also self-mutates obj.S_ail/obj.S_elev/obj.S_rud. Returns
        %   struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud).
        result = size_control_surfaces(obj)
    end
    % ==================================================================================================================================== %
end
