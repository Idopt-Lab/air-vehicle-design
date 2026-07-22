classdef F16AeroL2 < AeroModelL2
%F16AEROL2  F-16A Block 10 Level-2 aerodynamics student class.
%
%   Inherits from AeroModelL2 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to AeroL2 statics — no equations
%   are duplicated here.
%
%   Concrete utility methods (compute_CD, compute_CL, compute_CD0, get_CDi) are
%   inherited from AerodynamicsBase.
%
%   SOURCES:
%     S_ref, AR, Lambda_LE: T.O. 1F-16A-1, Fig. 1-2
%     Lambda_c4_deg: approximately 37 deg for F-16 wing (derived from planform)
%     S_wet: Brandt F-16A.xls Main!L3 (1371 ft^2)
%     cl_max_2D: NACA 64A204 thin section, cl_max ≈ 1.20 (estimated;
%                see Abbott & von Doenhoff, Table of Airfoil Data, 1959)
%
%   Expected outputs at M = 0.6 (for validation):
%     beta = sqrt(1 - 0.36) = 0.800
%     CL_alpha ≈ 2*pi*3 / (2 + sqrt(4 + (3*0.8)^2*(1+tan(37°)^2/0.64)))
%              ≈ 18.85 / (2 + sqrt(4 + 5.76*(1+0.887)))  ≈ 3.2187 /rad
%     CLmax = 0.9 * 1.20 * cos(37°) = 0.9 * 1.20 * 0.7986 = 0.862

    properties
        % --- Aircraft-specific inputs
        aircraft_category = "jet_fighter"
        S_ref             = 300        % ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet             = 1371       % ft^2  [Brandt F-16A.xls Main!L3]
        AR                = 3.0        % —     [T.O. 1F-16A-1: b=30ft, S=300ft^2]
        Lambda_LE_deg     = 40         % deg   [T.O. 1F-16A-1, Fig. 1-2]
        Lambda_c4_deg     = 37         % deg   [derived from F-16 planform geometry]
        taper             = 0.2275     % —     wing taper ratio [T.O. 1F-16A-1; F16Baseline b.geom.taper]
        CL_minD           = 0.0        % —     symmetric polar approx.
        cl_max_2D         = 1.20       % —     NACA 64A204 [Abbott & von Doenhoff, 1959]

        % --- Trailing-edge flap (flaperon) geometry -- estimates, F-16
        % flap-panel dimensions not in Brandt workbook / F16Baseline.
        % TODO: verify against T.O. 1F-16A-1 general-arrangement drawing.
        hld_TE            = "plain"    % F-16 flaperon type [legacy F16AeroLevel2 constant]
        c_flap_over_c     = 0.25       % —     flap chord ratio c'/c, estimated
        eta_flap_in       = 0.10       % —     flap inboard span station (frac. semispan), estimated
        eta_flap_out      = 0.90       % —     flap outboard span station (frac. semispan), estimated
        % F-16 flaperons are a small-authority camber-changing device (max
        % ~20 deg down), NOT a dedicated high-lift Fowler/slotted-flap
        % system -- Raymer 6th ed. Sec.12.6.5's stated "typical" 20-40 deg
        % TO / 60-70 deg landing ranges assume the latter and are far too
        % aggressive here (verified: using those midpoints overshoots
        % Brandt's TO/landing CD0 by 80-210%). TODO: verify against T.O.
        % 1F-16A-1 flaperon deflection schedule.
        delta_flap_TO_deg = 15         % deg
        delta_flap_L_deg  = 20         % deg
        k_f_flap          = 0.28       % —     Raymer 6th ed. Eq. 12.62; F-16 flaperon treated as partial-span

        % --- Computed aerodynamic quantities (initialise to 0; populate by calling methods)
        e_osw_clean  = 0
        K_LD         = 0
        K            = 0
        K1           = 0
        K2           = 0
        Cf           = 0
        CL_minD_val  = 0
        CL_max_clean = 0
        CD0          = 0
        CDi          = 0
        CD           = 0
        CL           = 0
        F            = 0
    end

    properties (Constant)
        % Tabulated from Raymer figures/tables for the F-16A NACA 64A204 wing.
        airfoiltype     = "cambered"
        C1              = 0.5       % Raymer 6th ed. Fig. 12.12, λ = 0.23
        C2              = 0.65      % Raymer 6th ed. Fig. 12.12, λ = 0.23
        CL_max_base     = 0.91      % Raymer 6th ed. Fig. 12.13
        sharpness_param = 0.7720    % Raymer 6th ed. Table 12.1
        CL_max_cl_max   = 1.1       % Raymer 6th ed. Fig. 12.9, Λ_LE = 40°
        cl_max          = 1.0       % NTRS-19870017427 p. 14 (NACA 64A204)
        % TODO (2026-07-22): alpha_L0 now matches PLAN.md's authoritative NACA
        % 1404 value (-1.047°), but cl_max_2D (=1.20, above) and cl_max (below)
        % are still cited to NACA 64A204 -- this class now mixes two airfoil
        % sources rather than fully reconciling to one. Update cl_max_2D/cl_max
        % to NACA 1404 data (or document why the mix is intentional) before
        % relying on the drag-polar/CLmax outputs together.
        alpha_L0 = -1.047; % Deg - zero-lift AOA (NACA 1404, per PLAN.md)
    end

    methods

        function obj = F16AeroL2()
            obj.aircraft_category = "jet_fighter";
            obj.S_ref             = 300;
            obj.S_wet             = 1371;
            obj.AR                = 3.0;
            obj.Lambda_LE_deg     = 40;
            obj.Lambda_c4_deg     = 37;
            obj.taper             = 0.2275;
            obj.CL_minD           = 0.0;
            obj.cl_max_2D         = 1.20;
        end

        function polar = drag_polar(obj, state)
            polar = AeroL2.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL2.get_CLmax(obj);
        end

        function e = get_e_osw(obj)
            e = AeroL2.get_e_osw(obj);
        end

        function val = get_K1(obj, M)
            val = AeroL2.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL2.get_K2(obj, K1_sub, M);
        end

        function val = get_CD0(obj)
            val = AeroL2.get_CD0(obj);
        end

        function val = compute_K(~, e_osw, AR)
            val = AeroL2.compute_K(e_osw, AR);
        end

        function val = compute_CL_minD(~, CL_alpha, alpha_L0)
            val = AeroL2.compute_CL_minD(CL_alpha, alpha_L0);
        end

        function val = lookup_Cf(~, aircraft_type, ~)
            val = AeroL1.lookup_Cf(aircraft_type);
        end

        function val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
            val = AeroL2.get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max);
        end

        function val = get_CL_alpha(obj, M)
            val = AeroL2.get_CL_alpha(obj, M);
        end

        function val = compute_F(~, d, b)
            val = AeroL2.compute_F(d, b);
        end

        function val = compute_Delta_CL_max_values(~, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg);
        end

        function val = lookup_Delta_cl_max_values(~, liftdevice, config, cp_c)
            val = AeroL2.lookup_Delta_cl_max_values(liftdevice, config, cp_c);
        end

        % ================================================================ %
        % High-lift-device deltas (L2: trailing-edge flap only, from real
        % flap geometry). Delta_e_osw is still tabulated -- Raymer has no
        % closed-form Oswald-efficiency-with-flaps formula.
        % ================================================================ %

        function val = compute_S_flapped_ratio(~, eta_out, eta_in, lambda_taper)
        %COMPUTE_S_FLAPPED_RATIO  S_flapped/S_ref for a flap spanning
        %   [eta_in, eta_out] of the semispan on a straight-tapered wing.
        %   Roskam, Airplane Design Part II, Eq. 7.10.
            val = (eta_out - eta_in) * (2 - (1 - lambda_taper) * (eta_in + eta_out)) / (1 + lambda_taper);
        end

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (Sec. 12.6.5, "Flap Drag").
        %   F_flap = 0.0144 (plain) / 0.0074 (slotted); F-16 flaperon = plain.
            F_flap = 0.0144;
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62.  Lambda is the WING
        %   quarter-chord sweep (not the flap hinge line).
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21 (via the
        %   AeroL2 toolbox, already delegated by lookup_Delta_cl_max_values /
        %   compute_Delta_CL_max_values above).  config: 'TO' or 'L'.
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = obj.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = obj.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = get_Delta_e_osw_TO(obj)
        %GET_DELTA_E_OSW_TO  Roskam Table 3.6: e(TO flaps) - e(clean).
        %   No closed-form flapped-wing Oswald-efficiency formula exists in
        %   Raymer Ch. 12, so this stays tabulated at L2 (same as L1).
            val = obj.roskam_e_osw('takeoff_flaps') - obj.roskam_e_osw('clean');
        end

        function val = get_Delta_e_osw_L(obj)
        %GET_DELTA_E_OSW_L  Roskam Table 3.6: e(landing flaps) - e(clean).
            val = obj.roskam_e_osw('landing_flaps') - obj.roskam_e_osw('clean');
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Flap (Raymer Eq. 12.61) + gear (Roskam Table 3.6,
        %   tabulated -- no closed-form gear-CD0 model exists before L3's
        %   component buildup).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.roskam_Delta_CD0('landing_gear');
        end

        function val = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Flap (Raymer Eq. 12.61) + gear (Roskam Table 3.6).
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.roskam_Delta_CD0('landing_gear');
        end

        function val = get_Delta_CLmax_TO(obj)
        %GET_DELTA_CLMAX_TO  Flap contribution, Raymer Table 12.2 + Eq. 12.21.
            val = obj.Delta_CLmax_flap('TO');
        end

        function val = get_Delta_CLmax_L(obj)
        %GET_DELTA_CLMAX_L  Flap contribution, Raymer Table 12.2 + Eq. 12.21.
            val = obj.Delta_CLmax_flap('L');
        end

        function val = get_Delta_CDi_TO(obj)
        %GET_DELTA_CDI_TO  Raymer 6th ed. Eq. 12.62, using this flap's own Delta_CLmax_TO.
            val = obj.Delta_CDi_flap(obj.get_Delta_CLmax_TO());
        end

        function val = get_Delta_CDi_L(obj)
        %GET_DELTA_CDI_L  Raymer 6th ed. Eq. 12.62, using this flap's own Delta_CLmax_L.
            val = obj.Delta_CDi_flap(obj.get_Delta_CLmax_L());
        end

        function val = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Clean CLmax + Delta_CLmax_TO.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
        %GET_CLMAX_L  Clean CLmax + Delta_CLmax_L.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range for flapconfig.
        %   Roskam, Airplane Design Part I, Table 3.6. Reads AeroL1's
        %   existing Constant table directly; no toolbox change.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

        function val = roskam_Delta_CD0(~, flapconfig)
        %ROSKAM_DELTA_CD0  Mean of AeroL1.Delta_CD0's "Delta_CD0" range for flapconfig.
        %   Roskam, Airplane Design Part I, Table 3.6.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.Delta_CD0{1});
        end

    end
end
