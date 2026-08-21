classdef F16AeroL3 < AeroModelL3
%F16AEROL3  F-16A Block 10 Level-3 aerodynamics student class.
%
%   Inherits AeroModelL3 (abstract enforcer).  L3 is the Raymer Eq. 12.24
%   component drag build-up plus the F-16's own supersonic wave-drag term
%   (Raymer Eq. 12.41, M >= 1.2). Most methods delegate to the AeroL3 static
%   toolbox; drag_polar/get_CD0_buildup add the wave-drag term on top.
%
%   DEPENDENCY INJECTION + INPUT vs DERIVED (optimization-ready design).
%   Constructor takes a required injected geometry object and a required
%   unified L3 input JSON path (f16a_spec_path(3); reads its .aerodynamics
%   block; no silent defaults). Properties split:
%     (1) INPUTS -- plain/Constant blocks of aero constants only (per-component
%         interference Q, laminar fraction, body/surface flag, surface
%         roughness, max-thickness station, airfoil section data, wave-drag
%         factor, misc/leakage drag allowances, high-lift/gear estimates).
%     (2) DERIVED (Dependent) -- all geometry read live from the injected
%         geometry object: reference area/AR/sweep/taper and the per-component
%         wetted-area / reference-length / diameter / t-c / max-thickness-line-
%         sweep arrays (order: wing, HT, VT, fuselage, duct). No geometry
%         number is stored on this class; each is rebuilt live on every read.
%
%   Inheritance: AerodynamicsBase -> AeroModelL3 -> F16AeroL3
%   Component order: [1] wing, [2] HT, [3] VT, [4] fuselage, [5] duct
%
%   History and rationale: docs/decision_log.md

    % INPUTS -- aero-only constants (from the unified L3 JSON's .aerodynamics
    % block). No geometry.
    properties
        geom              % injected geometry object (all geometry read live from it)

        aircraft_category % string; canonical top-level class flag. Not used by any L3 aero equation -- exposed so mission analysis can read it by DI for the Roskam Table 2.1/2.2 row.

        % Airfoil (NACA 64A204).
        alpha_L0          % deg; zero-lift AOA (drives CL_minD -> K2)
        cl_max_2D         % 2-D section cl_max (feeds clean CLmax, Eq. 12.15)
        cl_alpha_2D       % 1/rad; 2-D lift slope -> eta term (Raymer Eq. 12.8)

        % Per-component aero constants (component order above).
        x_c_max_comp      % — chordwise max-thickness station (surfaces; 0 for bodies)
        Q_comp            % — interference factor            [Raymer Table 12.6]
        f_lam_comp        % — laminar-flow fraction
        is_body_comp      % logical — true selects the body form factor (Eq. 12.31)

        k                 % ft  — equivalent surface roughness (smooth paint) [Raymer Table 12.4/12.5]
        E_WD              % — wave-drag efficiency factor (TUNED calibration input) [Raymer Eq. 12.45]
        CD0_LandP         % — leakage & protuberance allowance [Raymer Sec. 12.5]

        % Miscellaneous drag areas (D/q, ft^2) composing CD0_misc [Raymer Table 12.7].
        Dq_gun_port       % single cannon port
        Dq_hook_USAF      % arresting hook, USAF
    end

    properties (Constant)
        % --- Trailing-edge flaperon control-surface estimates (aero spec, not
        % geometry; not in the aero JSON).
        % delta_flap_TO/L_deg = 20 deg, both takeoff and landing [f-16.net
        % forum + Aerosoft F-16 simulator manual]: gear down, the flaperons go
        % to 20 deg as trailing-edge flaps; ground roll before liftoff is also
        % 20 deg down (retracting above 240-370 kt once airborne).
        hld_TE            = "plain"
        c_flap_over_c     = 0.25
        eta_flap_in       = 0.10
        eta_flap_out      = 0.90
        delta_flap_TO_deg = 20
        delta_flap_L_deg  = 20
        k_f_flap          = 0.28    % Raymer 6th ed. Eq. 12.62 (partial-span)

        % --- Leading-edge slat (maneuvering flap) estimates.
        % TODO: verify vs T.O. 1F-16A-1. The LEF is auto-scheduled by the flight
        % control computer as a function of AoA and Mach, not a fixed TO/L
        % value. delta_slat_TO/L_deg = 17 is a stand-in for the LEF position
        % near the high-AoA rotation/touchdown condition these CLmax_TO/CLmax_L
        % values represent. Still unpinned against a primary schedule.
        hld_LE            = "slat"
        c_slat_over_c     = 0.15
        eta_slat_in       = 0.0
        eta_slat_out      = 0.98
        F_slat            = 0.0144  % Raymer Eq. 12.61 "F_flap" analog (plain, un-slotted)
        delta_slat_TO_deg = 17
        delta_slat_L_deg  = 17
        k_slat            = 0.14    % Raymer Eq. 12.62 "k_f" analog (full-span)

        % --- Landing-gear component-buildup inputs [Raymer Table 12.6].
        Dq_wheels        = 0.18     % regular wheel + tire
        Dq_strut_highRE  = 0.30     % round strut, high Re
        Dq_strut_lowRE   = 1.17     % round strut, low Re
        strut_ref_length = 0.3      % ft (estimated strut diameter) -- TODO verify
        n_nosewheel      = 1
        n_mainwheel      = 2
        n_gear_legs      = 3
    end

    % DERIVED -- geometry read live from obj.geom on every read (no cache).
    % Read-only. Component arrays are in the order wing/HT/VT/fuselage/duct.
    properties (Dependent)
        S_ref             % ft^2  <- geom.S_ref
        AR                % —     <- geom.AR_wing
        Lambda_LE_deg     % deg   <- geom.LE_sweep_wing
        Lambda_c4_deg     % deg   <- geom.QC_sweep_wing (~32.2)
        taper             % —     <- geom.lambda_wing

        S_wet_comp        % ft^2  per-component wetted area   <- geom (Roskam Eq.12.1/12.3, frustum)
        l_ref_comp        % ft    per-component MAC / length  <- geom (MAC = Raymer Eq. 7.8)
        D_comp            % ft    per-component body diameter  <- geom (0 for surfaces)
        tc_comp           % —     per-component thickness ratio<- geom (mean root/tip for HT/VT)
        Lambda_m_comp     % deg   per-component max-thickness-line sweep <- geom (convert_sweep at x_c_max)

        % Mod (08/19/2026) (Claude)
        % Mod (08/19/2026) (Claude) -- the five S_wet_comp terms are now DI reads
        %   off the injected F16GeomL3, not GeomL2 toolbox calls made here.
        S_wet_wing        % ft^2  <- geom.S_wet_wing  [Roskam Vol. II Eq. 12.1]
        S_wet_ht          % ft^2  <- geom.S_wet_ht    [Roskam Vol. II Eq. 12.1]
        S_wet_vt          % ft^2  <- geom.S_wet_vt    [Roskam Vol. II Eq. 12.1]
        S_wet_strake      % ft^2  <- geom.S_wet_strake [Roskam Vol. II Eq. 12.1]
        S_wet_duct        % ft^2  <- geom.S_wet_duct  [Raymer 6th ed. Sec. 7.3]
        S_wet_fuselage    % ft^2  fuselage wetted area, BY THE TIER'S OWN METHOD.
                          %       L2 geometry -> Roskam Vol. II Eq. 12.3.
                          %       L3 geometry -> control stations, Raymer Fig. 7.37.

        %AMAX_FT2, L_AIRCRAFT_FT  Whole-aircraft wave-drag geometry, read live
        %   from the injected geometry object so the Sears-Haack term responds
        %   to a fuselage change.
        Amax_ft2          % ft^2 <- geom.Amax. TIER-SPECIFIC: area-ruled buildup at L3 (24.7037, what Eq. 12.44 wants), fuselage-envelope ellipse at L2 (27.4889). See get.Amax_ft2.
        L_aircraft_ft     % ft   <- geom.L_aircraft (overall length input, distinct from the fuselage L_fus)

        CD0_misc          % — (Dq_gun_port + Dq_hook_USAF)/S_ref  [Raymer Table 12.7], live (S_ref from geom)
    end

    methods

        function obj = F16AeroL3(geom, json_path)
        %F16AEROL3  Construct from a required injected geometry object and a
        %   required unified L3 input JSON path (f16a_spec_path(3)); reads its
        %   .aerodynamics block. No silent defaults: both the geometry object
        %   and the path must be supplied. Sets ONLY the aero constants; all
        %   geometry (incl. per-component arrays) is produced live by the
        %   Dependent getters from obj.geom.
            arguments
                % Mod (08/19/2026) (Claude) -- L3 ONLY. This closes finding S-19.
                % An L2 geometry used to construct cleanly here and then feed
                % two silently wrong numbers: Amax became the envelope ellipse
                % 27.4889 instead of the area-ruled 24.7037, which inflates wave
                % drag by about 23 %, and S_wet_fuselage became Roskam Eq. 12.3
                % (730.30) instead of the control-station value (677.93).
                geom      (1,1) {mustBeA(geom, "GeometryModelL3")}
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            obj.geom = geom;

            Jfull = jsondecode(fileread(json_path));
            obj.aircraft_category = string(Jfull.aircraft_category);
            J = Jfull.aerodynamics;
            obj.alpha_L0    = J.airfoil.alpha_L0_deg;   % [NACA 64A204]
            obj.cl_max_2D   = J.airfoil.cl_max_2D;      % 1.20 (locked, matches L2)
            obj.cl_alpha_2D = J.airfoil.cl_alpha_per_deg * 180/pi;   % deg -> rad, same conversion as F16AeroL2

            % Per-component constants (order: wing, HT, VT, fuselage, duct).
            % Mod (08/19/2026) (Claude) -- SIX components. The strake sits
            % 4th, matching the S_wet_comp order.
            obj.x_c_max_comp = [J.x_c_max.wing, J.x_c_max.horizontal_tail, ...
                                J.x_c_max.vertical_tail, J.x_c_max.strake, ...
                                J.x_c_max.fuselage, J.x_c_max.duct];
            obj.Q_comp       = [J.interference_factor_Q.wing, J.interference_factor_Q.horizontal_tail, ...
                                J.interference_factor_Q.vertical_tail, J.interference_factor_Q.strake, ...
                                J.interference_factor_Q.fuselage, J.interference_factor_Q.duct];
            obj.f_lam_comp   = [J.laminar_fraction_f_lam.wing, J.laminar_fraction_f_lam.horizontal_tail, ...
                                J.laminar_fraction_f_lam.vertical_tail, J.laminar_fraction_f_lam.strake, ...
                                J.laminar_fraction_f_lam.fuselage, J.laminar_fraction_f_lam.duct];
            obj.is_body_comp = logical([J.is_body.wing, J.is_body.horizontal_tail, ...
                                J.is_body.vertical_tail, J.is_body.strake, ...
                                J.is_body.fuselage, J.is_body.duct]);
            obj.k            = J.surface_roughness_k_ft.wing;   % uniform roughness
            obj.E_WD         = J.wave_drag_factor_E_WD;
            % Amax_ft2 / L_aircraft_ft are Dependent on obj.geom, not read here.
            obj.CD0_LandP    = J.CD0_LandP;
            obj.Dq_gun_port  = J.misc_drag_areas.Dq_gun_port_ft2;
            obj.Dq_hook_USAF = J.misc_drag_areas.Dq_hook_USAF_ft2;
        end

        % ---- Dependent scalar geometry getters (live from obj.geom) -------- %
        function v = get.S_ref(obj);         v = obj.geom.S_ref;         end
        function v = get.AR(obj);            v = obj.geom.AR_wing;       end
        function v = get.Lambda_LE_deg(obj); v = obj.geom.LE_sweep_wing; end
        function v = get.Lambda_c4_deg(obj); v = obj.geom.QC_sweep_wing; end
        function v = get.taper(obj);         v = obj.geom.lambda_wing;   end

        % ---- Dependent per-component geometry arrays (live from obj.geom) -- %
        % Mod (08/19/2026) (Claude)
        %   g.get_S_wet_fuselage() and g.get_S_wet_duct() were removed from the
        %   geometry class, so this reads the toolbox directly. D_fus is the
        %   equivalent diameter (W+H)/2, NOT the max width -- passing the width
        %   reads about 12.8% high.
        %
        %   _TODO -- S-19 in first_pass_findings.md is still open. The
        %   constructor accepts GeometryModelL2 OR GeometryModelL3. With an L2
        %   object, Amax silently becomes the envelope ellipse (27.4889) instead
        %   of the area-ruled buildup (24.7037), which inflates wave drag by
        %   about 23% with no warning. Resolve in the gate-4b sweep.
        function v = get.S_wet_comp(obj)
            % Mod (08/19/2026) (Claude) -- every term is a DI read off the
            % injected F16GeomL3. This class no longer calls a GeomL2 static, so
            % each number carries the geometry tier's own method.
            %
            % Mod (08/19/2026) (Claude) -- the STRAKE is now the 6th component.
            % Its four aero constants were added to f16a_L3.json; see the
            % _strake_src key under each block for the citation. Before this the
            % buildup omitted 40.4000 ft^2, about 2.8 % of wetted area, so that
            % area produced no skin friction.
            v = [obj.S_wet_wing, ...  % [Roskam Vol. II Eq. 12.1]
                 obj.S_wet_ht,   ...
                 obj.S_wet_vt,   ...
                 obj.S_wet_strake, ...
                 obj.S_wet_fuselage, ...                                                                         % Mod (08/19/2026) (Claude) -- the tier's own method
                 obj.S_wet_duct];                                      % [Raymer 6th ed. Sec. 7.3]
        end
        function v = get.l_ref_comp(obj)
            % Reference length per component: wing/HT/VT MAC (Raymer Eq. 7.8),
            % fuselage/duct length. HT/VT MAC is not exposed by the geometry
            % object directly, so it is recomputed from the injected root chord
            % and taper via the shared GeometryBase.compute_mac static.
            g = obj.geom;
            mac_ht  = GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht);
            mac_vt  = GeometryBase.compute_mac(g.c_root_vt, g.lambda_vt);
            mac_str = GeometryBase.compute_mac(g.c_root_strake, g.lambda_strake);   % Mod (08/19/2026) (Claude)
            v = [g.cbar_wing, mac_ht, mac_vt, mac_str, g.L_fus, g.L_duct];
        end
        function v = get.D_comp(obj)
            g = obj.geom;
            v = [0, 0, 0, 0, g.D_fus, g.D_inlet];   % Mod (08/19/2026) (Claude) -- strake 4th, a surface
        end
        function v = get.tc_comp(obj)
            % Wing modeled uniform-tc; HT/VT use the mean of the injected
            % root/tip t/c pair; bodies use 0 (they take the body form factor).
            g = obj.geom;
            v = [g.tc_wing, (g.tc_r_ht + g.tc_t_ht)/2, (g.tc_r_vt + g.tc_t_vt)/2, ...
                 (g.tc_r_strake + g.tc_t_strake)/2, 0, 0];   % Mod (08/19/2026) (Claude)
        end
        function v = get.Lambda_m_comp(obj)
            % Max-thickness-line sweep per surface: convert the injected LE
            % sweep to the chordwise max-thickness station x_c_max via the
            % shared GeometryBase sweep identities. Wing/HT are mirrored
            % surfaces (4/AR form); the VT is a single panel, so it takes
            % convert_sweep_panel's 2/AR form (feeds the Raymer Eq. 12.30 VT
            % form factor). Bodies: 0.
            g = obj.geom;
            wing = GeometryBase.convert_sweep(g.LE_sweep_wing, g.AR_wing, g.lambda_wing, obj.x_c_max_comp(1));
            ht   = GeometryBase.convert_sweep(g.LE_sweep_ht,   g.AR_ht,   g.lambda_ht,   obj.x_c_max_comp(2));
            vt   = GeometryBase.convert_sweep_panel(g.LE_sweep_vt, g.AR_vt, g.lambda_vt, obj.x_c_max_comp(3));
            % Mod (08/19/2026) (Claude) -- the strake is a MIRRORED pair, so it
            % takes convert_sweep 4/AR form, like the wing and HT.
            str  = GeometryBase.convert_sweep(g.LE_sweep_strake, g.AR_strake, g.lambda_strake, obj.x_c_max_comp(4));
            v = [wing, ht, vt, str, 0, 0];
        end
        function v = get.CD0_misc(obj)
            v = (obj.Dq_gun_port + obj.Dq_hook_USAF) / obj.S_ref;   % [Raymer Table 12.7]
        end

        function v = get.Amax_ft2(obj)
            % Whole-aircraft max cross-section, live from the injected geometry.
            % Tier-specific, deliberately:
            %   F16GeomL3 -> area-ruled buildup (24.7037 ft^2), the quantity
            %      Raymer Eq. 12.44 wants -- correct for an L3 aero object.
            %   F16GeomL2 -> fuselage-envelope ellipse (pi/4)*W*H = 27.4889, the
            %      low-fidelity form -- wrong for L3 (inflates CD0_wave ~23%).
            % See F16GeomL3.md §4 and VnV/BrandtF16A/todo.md Phase 2 Sec 4b/5.
            v = obj.geom.Amax;
        end

        function v = get.L_aircraft_ft(obj)
            % Overall aircraft length, live from geometry (47.65 ft published
            % airframe length). Distinct from the fuselage L_fus used for the
            % component skin-friction Re and FF_body -- do not conflate the two
            % length scales. Provenance is a standing open item (todo.md Phase
            % 2 §6).
            v = obj.geom.L_aircraft;
        end

        % ---- Core contract (base) ----------------------------------------- %
        % TODO (8/19/2026)(Casey): So the drag polar shouldn't be in the toolbox.
        function polar = drag_polar(obj, state)
        %DRAG_POLAR  L3 component buildup + F-16 supersonic wave drag.
        %   Delegates the regime handling and K1/K2 to AeroL3.drag_polar, which
        %   calls obj.get_CD0_buildup (this class's override, adding wave drag
        %   for M >= 1.2) via dynamic dispatch.
            polar = AeroL3.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Geometry-based clean CLmax, Raymer 6th ed. Eq. 12.15
        %   (0.9*cl_max_2D*cos(Lambda_c/4)), same basis as L2. See
        %   AeroL2.CLmax_clean for the F-16 vortex-lift (LEX/strake) limitation.
            CLmax = AeroL2.CLmax_clean(obj.cl_max_2D, obj.Lambda_c4_deg);
        end

        function val = get_CD0_buildup(obj, state)
        %GET_CD0_BUILDUP  Generic Raymer Eq. 12.24 buildup (AeroL3) + the F-16's
        %   own supersonic wave-drag term (Eq. 12.41), added only for M >= 1.2
        %   (Eq. 12.41's own domain). No transonic fairing (1.0 < M < 1.2).
            val = AeroL3.get_CD0_buildup(obj, state);
            if state.mach >= 1.2
                val = val + obj.compute_CD0_wave(state);
            end
        end

        function val = compute_CD0_wave(obj, state)
        %COMPUTE_CD0_WAVE  Supersonic wave drag due to volume distribution.
        %   Raymer 6th ed. Eq. 12.44 (Sears-Haack) + Eq. 12.45 (E_WD / sweep /
        %   Mach correction), valid M >= 1.2:
        %     (D/q)_SH   = (9*pi/2)*(Amax/l)^2                                  [12.44]
        %     (D/q)_wave = E_WD*[1 - 0.386*(M-1.2)^0.57*(1 - pi*Lambda_LE^0.77/100)]*(D/q)_SH  [12.45]
        %     CD0_wave   = (D/q)_wave / S_ref
        %   Amax/l are whole-aircraft quantities read live from the injected
        %   geometry via obj.Amax_ft2 / obj.L_aircraft_ft, so this term responds
        %   to a fuselage change. Distinct from the fuselage-component L_fus/D_fus
        %   used for the skin-friction Re/FF_body calc; do not conflate.
        %   E_WD = 2.2 is a tuned calibration input (the _TODO_wave_drag_factor_E_WD
        %   marker stays open for whether 2.2 is sourceable at all).
            M     = state.mach;
            Dq_SH = (9*pi/2) * (obj.Amax_ft2 / obj.L_aircraft_ft)^2;
            val   = obj.E_WD ...
                * (1 - 0.386 * (M - 1.2)^0.57 * (1 - (pi*obj.Lambda_LE_deg^0.77)/100)) ...
                * Dq_SH / obj.S_ref;
        end

        % ---- Auxiliary accessors + buildup primitives (delegations) ------- %
        function e = get_e_osw(obj)
            e = AeroL3.get_e_osw(obj);
        end

        function e = get_e_osw_brandt(obj)
        %GET_E_OSW_BRANDT  Brandt Aero!G12 alternate (comparison report ONLY).
            e = AeroL2.oswald_eff_brandt(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_K1(obj, M)
            val = AeroL3.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL3.get_K2(obj, K1_sub, M);
        end

        function val = get_CL_alpha(obj, M)
            val = AeroL3.get_CL_alpha(obj, M);
        end

        function Re = compute_Re(~, state, l_ref)
            Re = AeroL3.compute_Re(state, l_ref);
        end

        % ================================================================ %
        % High-lift-device / gear deltas (L3: TE flaperon + LE slat from real
        % geometry; gear from the Reynolds-based component buildup). Geometry
        % (taper, S_ref, sweeps) read live via the Dependent getters above.
        % ================================================================ %

        function val = compute_S_flapped_ratio(~, eta_out, eta_in, lambda_taper)
        %COMPUTE_S_FLAPPED_RATIO  S_device/S_ref for a device spanning
        %   [eta_in, eta_out] of the semispan.  Roskam Part II Eq. 7.10.
            val = (eta_out - eta_in) * (2 - (1 - lambda_taper) * (eta_in + eta_out)) / (1 + lambda_taper);
        end

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (plain flap, F_flap=0.0144).
            F_flap = 0.0144;
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62 (wing quarter-chord sweep).
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CD0_slat(obj, delta_slat_deg)
        %DELTA_CD0_SLAT  Raymer 6th ed. Eq. 12.61 FORM, adapted for the F-16 LE
        %   device (no separately-cited LE analog exists in the text).
            S_slatted_ratio = obj.compute_S_flapped_ratio(obj.eta_slat_out, obj.eta_slat_in, obj.taper);
            val = obj.F_slat * obj.c_slat_over_c * S_slatted_ratio * (delta_slat_deg - 10);
        end

        function val = Delta_CDi_slat(obj, Delta_CL_slat)
        %DELTA_CDI_SLAT  Raymer 6th ed. Eq. 12.62 FORM, adapted for the LE device.
            val = obj.k_slat * Delta_CL_slat^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21.  config 'TO'/'L'.
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = AeroL2.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_slat(obj, config)
        %DELTA_CLMAX_SLAT  Raymer 6th ed. Table 12.2 + Eq. 12.21 for the LE
        %   device (full-span; hinge line = wing LE sweep).
            S_slatted_ratio = obj.compute_S_flapped_ratio(obj.eta_slat_out, obj.eta_slat_in, obj.taper);
            S_slatted       = S_slatted_ratio * obj.S_ref;
            Delta_cl_max    = AeroL2.lookup_Delta_cl_max_values(obj.hld_LE, config, obj.c_slat_over_c);
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_slatted, obj.S_ref, obj.Lambda_LE_deg);
        end

        function val = compute_Delta_CD0_geardown(obj, state)
        %COMPUTE_DELTA_CD0_GEARDOWN  Landing-gear parasite-drag increment via
        %   the Reynolds-based component machinery + Dq_wheels/Dq_strut_*
        %   [Raymer Table 12.6]. F-16 tricycle gear: 1 nose + 2 main, 3 struts.
            Re = obj.compute_Re(state, obj.strut_ref_length);
            if Re > 3.0e5
                CD0_strut = obj.Dq_strut_highRE / obj.S_ref;
            else
                CD0_strut = obj.Dq_strut_lowRE / obj.S_ref;
            end
            CD0_wheels = obj.Dq_wheels / obj.S_ref;
            val = CD0_wheels * (obj.n_nosewheel + obj.n_mainwheel) + CD0_strut * obj.n_gear_legs;
        end

        function val = get_Delta_e_osw_TO(obj)
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj, state)
        %GET_DELTA_CD0_TO  Flap (Eq. 12.61) + slat (Eq. 12.61 form) + gear (buildup).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.Delta_CD0_slat(obj.delta_slat_TO_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CD0_L(obj, state)
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.Delta_CD0_slat(obj.delta_slat_L_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CLmax_TO(obj)
            val = obj.Delta_CLmax_flap('TO') + obj.Delta_CLmax_slat('TO');
        end

        function val = get_Delta_CLmax_L(obj)
            val = obj.Delta_CLmax_flap('L') + obj.Delta_CLmax_slat('L');
        end

        function val = get_Delta_CDi_TO(obj)
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('TO')) + obj.Delta_CDi_slat(obj.Delta_CLmax_slat('TO'));
        end

        function val = get_Delta_CDi_L(obj)
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('L')) + obj.Delta_CDi_slat(obj.Delta_CLmax_slat('L'));
        end

        function val = get_CLmax_TO(obj)
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Per-high-lift-config polar, built on the F-16 L3 clean
        %   drag polar plus this class's config-distinguishing methods
        %   (get_CLmax_TO/_L, get_Delta_CD0_TO/_L) -- the AerodynamicsBase
        %   contract the FAR-25 field-length/climb constraints read. The six
        %   configs are low-speed high-lift states, so the clean polar and the
        %   L3 gear-down buildup are evaluated at a nominal takeoff/landing
        %   condition (sea level, M = 0.2). Both takeoff_* configs map to the
        %   takeoff deltas, both landing_* plus approach to the landing deltas.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            ref   = AircraftState(0, 0.2);   % nominal low-speed takeoff/landing condition
            clean = obj.drag_polar(ref);
            switch config
                case "clean"
                    CD0 = clean.CD0;                             CLmax = obj.get_CLmax(ref);
                case {"takeoff_flaps_gear_up", "takeoff_flaps_gear_down"}
                    CD0 = clean.CD0 + obj.get_Delta_CD0_TO(ref); CLmax = obj.get_CLmax_TO();
                otherwise   % landing_flaps_gear_up/down, approach
                    CD0 = clean.CD0 + obj.get_Delta_CD0_L(ref);  CLmax = obj.get_CLmax_L();
            end
            cfg = struct('CD0', CD0, 'K1', clean.K1, 'K2', clean.K2, 'CLmax', CLmax);
        end

        % Mod (08/19/2026) (Claude) -- one DI read each, no toolbox call here.
        function v = get.S_wet_wing(obj)
            v = obj.geom.S_wet_wing;
        end
        function v = get.S_wet_ht(obj)
            v = obj.geom.S_wet_ht;
        end
        function v = get.S_wet_vt(obj)
            v = obj.geom.S_wet_vt;
        end
        function v = get.S_wet_strake(obj)
            v = obj.geom.S_wet_strake;
        end
        function v = get.S_wet_duct(obj)
            v = obj.geom.S_wet_duct;
        end
        function v = get.S_wet_fuselage(obj)
            v = obj.geom.S_wet_fuselage;
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range (Roskam Table 3.6).
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

    end
end
