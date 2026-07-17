classdef AeroL2
%AEROL2  Level-2 aerodynamics static toolbox.
%
%   Call as AeroL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL2, etc.) inherit
%   from AeroModelL2 and call these statics to implement each abstract method.
%
%   EQUATIONS ADDED AT L2 vs L1:
%     CL_alpha (finite-wing lift-curve slope, per rad):
%       2*pi*AR / (2 + sqrt(4 + (AR*beta)^2*(1 + tan^2(Λ_tc)/beta^2)))
%       Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., Eq. 12.6
%       where beta = sqrt(1 - M^2) and Λ_tc ≈ Λ_c4 (quarter-chord sweep)
%
%     CLmax (clean, no high-lift devices):
%       0.9 * cl_max_2D * cos(Λ_c4)   [Raymer 6th ed. §12.2]
%
%     Fuselage lift interference factor F  [Raymer 6th ed. Eq. 12.9]:
%       1.07*(1 + d/b)^2
%
%     CL at minimum drag  [Brandt et al.]:
%       CL_minD = CL_alpha * (-deg2rad(alpha_L0))

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
        %DRAG_POLAR  L2 drag polar — same CD0/K1/K2 formulae as L1.
        %   L2 adds CL_alpha and geometry-based CLmax as separate methods.
            polar = AeroL1.drag_polar(obj, state);
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
        %GET_K2  Polar-offset term — same formula as L1.
            val = AeroL1.get_K2(obj, K1_sub, M);
        end

        function val = compute_K(e_osw, AR)
        %COMPUTE_K  Subsonic induced-drag factor K = 1/(pi*e_osw*AR).
            val = AeroL1.K1_subsonic(e_osw, AR);
        end

        function val = compute_CL_minD(CL_alpha, alpha_L0)
        %COMPUTE_CL_MIND  CL at minimum drag.
        %   CL_minD = CL_alpha * (-deg2rad(alpha_L0))  [Brandt et al.]
            val = CL_alpha * (-deg2rad(alpha_L0));
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
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M);
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

        function CL_a = CL_alpha(AR, Lambda_c4_deg, M)
        %CL_ALPHA  Finite-wing CL_alpha via Raymer 6th ed. Eq. 12.6.
        %   AR           — aspect ratio
        %   Lambda_c4_deg— quarter-chord sweep (deg); used as approx. for Λ_tc
        %   M            — Mach number (subsonic; clamped to 0.99 internally)
            M    = min(M, 0.99);
            beta = sqrt(1 - M^2);
            Lambda_c4_rad = Lambda_c4_deg * pi / 180;
            CL_a = 2 * pi * AR / ...
                   (2 + sqrt(4 + (AR * beta)^2 * (1 + tan(Lambda_c4_rad)^2 / beta^2)));
        end

        function CLmax = CLmax_clean(cl_max_2D, Lambda_c4_deg)
        %CLMAX_CLEAN  Wing clean CLmax.  Raymer 6th ed. §12.2.
        %   CLmax = 0.9 * cl_max_2D * cos(Lambda_c4_deg)
            CLmax = 0.9 * cl_max_2D * cosd(Lambda_c4_deg);
        end

    end
end
