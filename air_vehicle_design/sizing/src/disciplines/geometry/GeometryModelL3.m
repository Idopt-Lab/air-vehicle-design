classdef (Abstract) GeometryModelL3 < GeometryBase
%GEOMETRYMODELL3  Tier-2 abstract enforcer for Level-3 geometry.
%   L3 is the physical / T.O. tier, consumed by L3 geometry, aerodynamics
%   and weights. Divergences from L2 are intentional fidelity differences.
%
%   AR_ht / lambda_ht / S_ht / S_vt mean FULL planform at both tiers; the
%   exposed values carry an explicit _exposed_ infix. Members marked
%   [DERIVED] must be Dependent getters on the concrete class, never stored.
%
%   Authoritative spec: examples/F16A/models/disciplines/geom/F16GeomL3.md
%   Toolbox companion:  src/disciplines/geometry/GeomL3.md

    % Abstract properties cannot have validation attributes in MATLAB.
    % The concrete class (F16GeomL3) enforces size/type.

    % ── Fuselage / whole aircraft ───────────────────────────────────────── %
    properties (Abstract)
        frames_normalized % (N,3) NORMALIZED frame table       [INPUT]  cols [x/Length_of_aircraft, w/Width_max_fuselage, h/Height_max_fuselage]
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

    % ── Inlet + engine duct ─────────────────────────────────────────────── %
    % T_AB_SLS_lb and the injected propulsion object are NOT here (engine, not
    % airframe, data). D_inlet/D_exit/L_duct are: L3 aero reads them as
    % D_comp(5) / l_ref_comp(5).
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
    % Recomputed live from the inputs; none may be stored. Declared in the
    % contract because they are also Brandt comparison-report rows (Geom!F/G/B
    % columns of the Geom!A5:I10 exposed-lifting-surface table).
    % Formulas + citations: GeomL3.compute_c_root_exposed and the class header.
    properties (Abstract)
        c_exp_root_wing % Wing exposed root chord (ft)   [DERIVED] 13.3564 [Brandt Geom!F7]
        G_hs_exp_wing   % Wing exposed half-span (ft)    [DERIVED] 11.5    [Brandt Geom!G7]
        Xexp_wing       % Wing exposed-root LE x (ft)    [DERIVED] 20.7226 [Brandt Geom!B7]
    end

    % ── Configuration ──────────────────────────────────────────────────── %
    properties (Abstract)
        S_cs           % Total control-effectors area (ft²)      [INPUT]  weights' "S_cs"
    end

        methods
        % See if you can merge both the fuselage and exposed wing wetted functions.
        % TODO (8/19/2026)(Casey): Add documentation explicitly stating intended usage and expectations.
        function val = get_S_wet(obj)
            val = obj.get_design_S_wet_components();
        end

        % TODO (8/19/2026)(Casey): There should be a method function for the control surfaces.
        % (Placeholder) Basically, size the mechanisms that enable control authority for your design.
        % This remains inactive until a suitable replacement is found.
        % function val = get_control_surfaces(obj)
        %     val = obj.get_design_control_mechanisms();
        % end
    end
end
