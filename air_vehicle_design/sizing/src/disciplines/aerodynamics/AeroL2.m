classdef AeroL2
%AEROL2  Level-2 aerodynamics static toolbox.
%
%   Call as AeroL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL2, etc.) inherit
%   from AeroModelL2 and call these statics to implement each abstract method.
%
%   EQUATIONS ADDED AT L2 vs L1:
%     CL_alpha (finite-wing lift-curve slope, per rad):
%       2*pi*AR / (2 + sqrt(4 + (AR*beta/eta)^2*(1 + tan^2(Λ_tc)/beta^2))) * (S_exposed/S_ref)*F
%       Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., Eq. 12.6
%       where beta = sqrt(1 - M^2), Λ_tc ≈ Λ_c4 (quarter-chord sweep),
%       eta = Cl_alpha_2D/(2*pi/beta) or 0.95 if unknown (Eq. 12.8), and
%       (S_exposed/S_ref)*F default to 1 when not supplied by the caller.
%
%     CLmax (clean, no high-lift devices):
%       0.9 * cl_max_2D * cos(Λ_c4)   [Raymer 6th ed. §12.2]
%
%     Fuselage lift interference factor F  [Raymer 6th ed. Eq. 12.9]:
%       1.07*(1 + d/b)^2
%
%     CL at minimum drag  [Brandt et al. §4.3]:
%       CL_minD = CL_alpha * (-deg2rad(alpha_L0) / 2)

% Tables for tabulation.
     properties (Constant)
          k_lambda = [0.88, 0.95]
          k_ww = 1.85; % Part of the wing "buried" in the fuselage (Airplane Design Vol 3, Roskam, p 167)
          Delta_cl_max_table = table({'plain'; 'split'; 'slotted'; 'fowler'; 'double slotted'; 'triple slotted'; 'fixed slat'; 'leading-edge flap'; 'Kruger flap'; 'slat'}, [0.9; 0.9; 1.3; 1.3; 1.6; 1.9; 0.2; 0.3; 0.3; 0.4], 'VariableNames',["High-Lift Device", "Delta_cl_max"]);
     end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  L2 drag polar — CD0/K1 same formulae as L1; K2 uses
        %   L2's own CL_alpha(M)-based CL_minD (see get_K2) rather than L1's
        %   fixed CL_minD=0, since L2 has real lift-curve-slope/alpha_L0 data.
            M      = state.mach;
            cd0    = AeroL2.get_CD0(obj);
            e      = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
            k1_sub = AeroL1.K1_subsonic(e, obj.AR);
            k2     = AeroL2.get_K2(obj, k1_sub, M);
            if M < 1
                k1 = k1_sub;
            else
                k1 = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function CLmax = get_CLmax(obj)
        %GET_CLMAX  Geometry-based clean CLmax.  Raymer 6th ed. §12.2.
        %   Reads obj.cl_max_2D and obj.Lambda_c4_deg.
            CLmax = AeroL2.CLmax_clean(obj.cl_max_2D, obj.Lambda_c4_deg);
        end

        function e = get_e_osw(obj)
        %GET_E_OSW  Oswald efficiency — same Raymer formula as L1.
            e = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_CD0(obj)
        %GET_CD0  CD0 = Cf * S_wet / S_ref  (same formula as L1).
            val = AeroL1.get_CD0(obj);
        end

        function val = get_K1(obj, M)
        %GET_K1  Induced-drag factor — same formula as L1.
            val = AeroL1.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term.
        %   CL_minD = CL_alpha(M) * (-deg2rad(alpha_L0) / 2)  [Brandt et al. §4.3],
        %   evaluated at the current Mach since CL_alpha is Mach-dependent
        %   (Raymer 6th ed. Eq. 12.6). alpha_L0 is a genuine NACA 64A204
        %   airfoil spec value (not a Brandt-calibrated output).
            CL_alpha_M = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M);
            CL_minD    = AeroL2.compute_CL_minD(CL_alpha_M, obj.alpha_L0);
            val        = AeroL1.K2_value(K1_sub, CL_minD, M);
        end

        function val = compute_K(e_osw, AR)
        %COMPUTE_K  Subsonic induced-drag factor K = 1/(pi*e_osw*AR).
            val = AeroL1.K1_subsonic(e_osw, AR);
        end

        function val = compute_CL_minD(CL_alpha, alpha_L0)
        %COMPUTE_CL_MIND  CL at minimum drag.
        %   CL_minD = CL_alpha * (-deg2rad(alpha_L0) / 2)  [Brandt et al. §4.3]
            val = CL_alpha * (-deg2rad(alpha_L0) / 2);
        end

        function val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
        %GET_CL_MAX_VALUES  Clean CLmax via Raymer Fig. 12.13/12.9 AR check.
        %   Reads obj.C1 (tabulated constant from Raymer Fig. 12.12).
            wing_param = (obj.C1 + 1) * AR * cosd(Lambda_LE_deg);
            if wing_param < 2
                val = CL_max_base + Delta_CL_max;
            else
                val = CL_max_cl_max * cl_max + Delta_CL_max;
            end
        end

        function val = get_CL_alpha(obj, M)
        %GET_CL_ALPHA  Finite-wing lift-curve slope; reads geometry from obj.
        %   Passes obj.Cl_alpha_2D (2-D airfoil lift-curve slope, 1/rad)
        %   through to AeroL2.CL_alpha when the student class supplies it;
        %   otherwise the Raymer Eq. 12.8 eta~0.95 default is used.
            if isprop(obj, 'Cl_alpha_2D')
                Cl_alpha_2D = obj.Cl_alpha_2D;
            else
                Cl_alpha_2D = [];
            end
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M, [], [], [], Cl_alpha_2D);
        end

        function val = compute_F(d, b)
        %COMPUTE_F  Fuselage lift interference factor.
        %   F = 1.07*(1 + d/b)^2  [Raymer 6th ed. Eq. 12.9]
            val = 1.07 * (1 + d/b)^2;
        end

        function val = compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
        %COMPUTE_DELTA_CL_MAX_VALUES  Wing CLmax increment from a deployed HLD.
        %   0.9 * Delta_cl_max * (S_flapped/S_ref) * cos(Lambda_HL)
        %   Raymer 6th ed. Eq. 12.21.
            val = 0.9 * Delta_cl_max * (S_flapped / S_ref) * cosd(Lambda_HL_deg);
        end

        function val = lookup_Delta_cl_max_values(liftdevice, config, cp_c)
        %LOOKUP_DELTA_CL_MAX_VALUES  Section cl_max increment for a given HLD type.
        %   liftdevice — "plain","split","slotted","fowler","double slotted",
        %                "triple slotted","fixed slot","leading-edge flap",
        %                "kruger flap","slat"
        %   config     — "takeoff"/"TO" or "landing"/"L"
        %   cp_c       — c'/c for chord-changing devices
        %   Raymer 6th ed. §12.5.
            switch liftdevice
                case {'plain','split'},          base = 0.9;
                case 'slotted',                  base = 1.3;
                case 'fowler',                   base = 1.3 * cp_c;
                case 'double slotted',           base = 1.6 * cp_c;
                case 'triple slotted',           base = 1.9 * cp_c;
                case 'fixed slot',               base = 0.2;
                case {'leading-edge flap','kruger flap'}, base = 0.3;
                case 'slat',                     base = 0.4 * cp_c;
                otherwise
                    error('AeroL2:unknownDevice', ...
                        'Unrecognized lift device "%s".', liftdevice);
            end
            if ismember(config, {'takeoff','TO'})
                val = base * 0.6;
            elseif ismember(config, {'landing','L'})
                val = base * 0.8;
            else
                val = base;
            end
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function CL_a = CL_alpha(AR, Lambda_c4_deg, M, S_exposed, S_ref, F, Cl_alpha_2D)
        %CL_ALPHA  Finite-wing CL_alpha via Raymer 6th ed. Eq. 12.6.
        %   AR           — aspect ratio
        %   Lambda_c4_deg— quarter-chord sweep (deg); used as approx. for Λ_tc
        %   M            — Mach number (subsonic; clamped to 0.99 internally)
        %   S_exposed, S_ref, F — (optional) exposed wing planform area [ft^2],
        %                  reference area [ft^2], and fuselage lift-interference
        %                  factor [Raymer Eq. 12.9, AeroL2.compute_F]. When any
        %                  is omitted, (S_exposed/S_ref)*F defaults to 1 -- Raymer
        %                  notes the true product is capped at ~0.98, so this is
        %                  a documented, cited approximation for callers (no
        %                  current student class supplies real S_exposed/F yet).
        %   Cl_alpha_2D  — (optional) 2-D airfoil lift-curve slope [1/rad].
        %                  eta = Cl_alpha_2D / (2*pi/beta)  [Raymer Eq. 12.8]
        %                  when supplied; eta = 0.95 (Raymer's "if unknown"
        %                  default) otherwise.
            if nargin < 6 || isempty(S_exposed) || isempty(S_ref) || isempty(F)
                exposed_factor = 1;
            else
                exposed_factor = (S_exposed / S_ref) * F;
            end
            M    = min(M, 0.99);
            beta = sqrt(1 - M^2);
            if nargin < 7 || isempty(Cl_alpha_2D)
                eta = 0.95;   % Raymer Eq. 12.8 default when 2-D Cl_alpha is unknown
            else
                eta = Cl_alpha_2D / (2*pi/beta);   % Raymer Eq. 12.8
            end
            Lambda_c4_rad = Lambda_c4_deg * pi / 180;
            CL_a = 2 * pi * AR / ...
                   (2 + sqrt(4 + (AR * beta / eta)^2 * (1 + tan(Lambda_c4_rad)^2 / beta^2))) ...
                   * exposed_factor;
        end

        function CLmax = CLmax_clean(cl_max_2D, Lambda_c4_deg)
        %CLMAX_CLEAN  Wing clean CLmax.  Raymer 6th ed. §12.15.
        % TODO (2026-07-21): Citation "§12.2" appears wrong. Per
        % reference_extracts/raymer_data.md, the swept-wing clean-CLmax relation
        % CL_max = 0.9·Cl_max·cos(Λ_0.25c) is Raymer Eq. 12.15 (§12.4 Lift), not
        % §12.2. Formula itself is correct; fix the equation/section number.
        %   CLmax = 0.9 * cl_max_2D * cos(Lambda_c4_deg)
        % Note (Casey, 7/22/2026): Fixed citation. Equation 12.15 is correct.
            CLmax = 0.9 * cl_max_2D * cosd(Lambda_c4_deg);
        end

    end
end
