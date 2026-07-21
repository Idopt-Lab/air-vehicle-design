classdef AeroL3
%AEROL3  Level-3 aerodynamics static toolbox: component CD0 buildup.
%
%   Call as AeroL3.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL3, etc.) inherit
%   from AeroModelL3 and call these statics to implement each abstract method.
%
%   Replaces the type-based Cf with per-component Reynolds number, skin
%   friction blend, and form factors.  K1 and K2 delegate to AeroL1 statics.
%
%   Component arrays (l_ref_comp, D_comp, S_wet_comp, tc_comp, …) are read
%   from the student object via duck typing.  Surfaces have is_body_comp=false;
%   bodies (fuselage, engine duct) have is_body_comp=true and use
%   l_ref_comp/D_comp as L/D for Raymer Eq. 12.31.
%
%   EQUATIONS:
%     Re = rho*V*l/mu                       Raymer 6th ed. Eq. 12.25
%     mu = Sutherland's law (English units)  Raymer 6th ed. §12.3.1
%     Re_cut_sub = 38.21*(l/k)^1.053        Raymer 6th ed. Eq. 12.28
%     Re_cut_sup = 44.62*(l/k)^1.053*M^1.16 Raymer 6th ed. Eq. 12.29
%     Cf_lam  = 1.328/sqrt(Re)              Raymer 6th ed. Eq. 12.26
%     Cf_turb = 0.455/(log10(Re)^2.58*(1+0.144*M^2)^0.65)  Eq. 12.27
%     FF_surf = (1+0.6/x_c_max*tc+100*tc^4)*(1.34*M^0.18*cos(Lm50)^0.28)  Eq. 12.30
%     FF_body = 1+5/f^1.5+f/400 (f<=6), or 1+60/f^3+f/400 (f>6),
%               f=L/D                    Raymer 6th ed. Eq. 12.31
%     CD0 = SUM(Cf_eff*FF*Q*Swet_i)/Sref + CD0_misc + CD0_LandP

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Full L3 drag polar via component CD0 buildup.
            M      = state.mach;
            cd0    = AeroL3.get_CD0_buildup(obj, state);
            e      = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
            k1_sub = AeroL1.K1_subsonic(e, obj.AR);
            k2     = AeroL3.get_K2(obj, k1_sub, M);
            if M < 1
                k1 = k1_sub;
            else
                k1 = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer Eq. 12.25).
            mu = AeroL3.dyn_viscosity(state.T_atm);
            Re = state.rho * state.V * l_ref / mu;
        end

        function Cf_lam = compute_Cf_lam(Re)
        %COMPUTE_CF_LAM  Laminar skin-friction coefficient  (Raymer Eq. 12.26).
            Cf_lam = AeroL3.Cf_laminar(Re);
        end

        function Cf_turb = compute_Cf_turb(Re, M)
        %COMPUTE_CF_TURB  Turbulent skin-friction coefficient  (Raymer Eq. 12.27).
            Cf_turb = AeroL3.Cf_turbulent(Re, M);
        end

        function FF = compute_FF_surface(tc, x_c_max, Lambda_m_deg, M)
        %COMPUTE_FF_SURFACE  Form factor for a lifting surface  (Raymer Eq. 12.30).
            FF = AeroL3.FF_surface(tc, x_c_max, Lambda_m_deg, M);
        end

        function FF = compute_FF_fus(L_body, D_body)
        %COMPUTE_FF_FUS  Form factor for a body/fuselage  (Raymer Eq. 12.31).
            FF = AeroL3.FF_body(L_body, D_body);
        end

        function val = get_K1(obj, M)
        %GET_K1  Induced-drag factor at Mach M; reads obj.AR and obj.Lambda_LE_deg.
            e = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
            if M < 1
                val = AeroL1.K1_subsonic(e, obj.AR);
            else
                val = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
        end

        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term; reads obj.CL_minD.
            val = AeroL1.K2_value(K1_sub, obj.CL_minD, M);
        end

        function val = compute_K(e_osw, AR)
        %COMPUTE_K  Subsonic induced-drag factor K = 1/(pi*e_osw*AR).
            val = AeroL1.K1_subsonic(e_osw, AR);
        end

        function val = compute_CL_minD(airfoil_type, CL_min)
        %COMPUTE_CL_MIND  CL at minimum drag.
        %   Cambered: caller supplies CL_min.  Uncambered/symmetric: 0.
            if strcmp(airfoil_type, 'cambered')
                val = CL_min;
            else
                val = 0;
            end
        end

        function [Cf_lam_result, Cf_turb_result] = compute_Cf(R, M)
        %COMPUTE_CF  Per-component Cf at Reynolds R and Mach M.
        %   Returns [Cf_lam, Cf_turb] as separate outputs.
        %   Raymer 6th ed. Eq. 12.26 (laminar), Eq. 12.27 (turbulent).
            Cf_lam_result  = AeroL3.Cf_laminar(R);
            Cf_turb_result = AeroL3.Cf_turbulent(R, M);
        end

        function val = get_R_cutoff(obj, ref_length, M)
        %GET_R_CUTOFF  Cutoff Reynolds for ref_length at Mach M; reads obj.k.
        %   Raymer 6th ed. Eq. 12.28 (subsonic), Eq. 12.29 (supersonic).
            if M > 1
                val = AeroL3.Re_cutoff_sup(ref_length, obj.k, M);
            else
                val = AeroL3.Re_cutoff_sub(ref_length, obj.k);
            end
        end

        function val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
        %GET_CL_MAX_VALUES  Clean CLmax via Raymer Fig. 12.13/12.9 AR check.
        %   Reads obj.C1.
            wing_param = (obj.C1 + 1) * AR * cosd(Lambda_LE_deg);
            if wing_param < 2
                val = CL_max_base + Delta_CL_max;
            else
                val = CL_max_cl_max * cl_max + Delta_CL_max;
            end
        end

        function val = get_CL_alpha(obj, M)
        %GET_CL_ALPHA  Finite-wing lift-curve slope; reads obj.AR, obj.Lambda_LE_deg.
        %   Uses Raymer Eq. 12.6 via AeroL2.CL_alpha static.
        %   NOTE: uses Lambda_LE_deg as approximation; override in student class
        %   to pass Lambda_c4_deg for better accuracy.
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_LE_deg, M);
        end

        function val = compute_F(d, b)
        %COMPUTE_F  Fuselage lift interference factor.
        %   F = 1.07*(1 + d/b)^2  [Raymer 6th ed., Eq. 12.9]
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
        %   Raymer 6th ed. §12.5.
            switch liftdevice
                case {'plain','split'},                   base = 0.9;
                case 'slotted',                           base = 1.3;
                case 'fowler',                            base = 1.3 * cp_c;
                case 'double slotted',                    base = 1.6 * cp_c;
                case 'triple slotted',                    base = 1.9 * cp_c;
                case 'fixed slot',                        base = 0.2;
                case {'leading-edge flap','kruger flap'}, base = 0.3;
                case 'slat',                              base = 0.4 * cp_c;
                otherwise
                    error('AeroL3:unknownDevice', ...
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

        function val = get_CD0_buildup(obj, state)
        %GET_CD0_BUILDUP  Sum Cf_eff*FF*Q*S_wet per component.
        %   Reads component arrays from obj via duck typing.
            M       = state.mach;
            n_comp  = numel(obj.l_ref_comp);
            cd0_sum = 0;
            for i = 1:n_comp
                l_i = obj.l_ref_comp(i);
                if M < 1
                    re_cut = AeroL3.Re_cutoff_sub(l_i, obj.k);
                else
                    re_cut = AeroL3.Re_cutoff_sup(l_i, obj.k, M);
                end
                re_eff = min(AeroL3.compute_Re(state, l_i), re_cut);
                cf_l   = AeroL3.Cf_laminar(re_eff);
                cf_t   = AeroL3.Cf_turbulent(re_eff, M);
                cf_eff = obj.f_lam_comp(i) * cf_l + (1 - obj.f_lam_comp(i)) * cf_t;
                if obj.is_body_comp(i)
                    ff_i = AeroL3.FF_body(l_i, obj.D_comp(i));
                else
                    ff_i = AeroL3.FF_surface(obj.tc_comp(i), obj.x_c_max_comp(i), ...
                                             obj.Lambda_m_comp(i), M);
                end
                cd0_sum = cd0_sum + cf_eff * ff_i * obj.Q_comp(i) * obj.S_wet_comp(i);
            end
            val = cd0_sum / obj.S_ref + obj.CD0_misc + obj.CD0_LandP;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function mu = dyn_viscosity(T_atm_R)
        %DYN_VISCOSITY  Sutherland's law in English units (Raymer 6th ed. §12.3.1).
        %   Returns mu in slug/(ft·s).
        %   mu_ref = 3.737e-7 slug/(ft·s) at T_ref = 518.67 R; C_suth = 198.6 R.
            mu_ref = 3.737e-7;
            T_ref  = 518.67;
            C_suth = 198.6;
            mu     = mu_ref * (T_atm_R/T_ref)^1.5 * (T_ref+C_suth)/(T_atm_R+C_suth);
        end

        function Re_cut = Re_cutoff_sub(l, k)
        %RE_CUTOFF_SUB  Roughness-limited Re, subsonic.  Raymer 6th ed. Eq. 12.28.
            Re_cut = 38.21 * (l/k)^1.053;
        end

        function Re_cut = Re_cutoff_sup(l, k, M)
        %RE_CUTOFF_SUP  Roughness-limited Re, supersonic.  Raymer 6th ed. Eq. 12.29.
            Re_cut = 44.62 * (l/k)^1.053 * M^1.16;
        end

        function Cf = Cf_laminar(Re)
        %CF_LAMINAR  Raymer 6th ed. Eq. 12.26.
            Cf = 1.328 / sqrt(Re);
        end

        function Cf = Cf_turbulent(Re, M)
        %CF_TURBULENT  Raymer 6th ed. Eq. 12.27.
            Cf = 0.455 / (log10(Re)^2.58 * (1 + 0.144*M^2)^0.65);
        end

        function FF = FF_surface(tc, x_c_max, Lambda_m_deg, M)
        %FF_SURFACE  Form factor for lifting surface.  Raymer 6th ed. Eq. 12.30.
            FF = (1 + 0.6/x_c_max * tc + 100*tc^4) * ...
                 (1.34 * M^0.18 * cosd(Lambda_m_deg)^0.28);
        end

        function FF = FF_body(L_body, D_body)
        %FF_BODY  Form factor for body/fuselage.  Raymer 6th ed. Eq. 12.31.
        %   The equation as printed is 1 + 5/f^1.5 + f/400 (f = l/d); Raymer
        %   notes the 1 + 60/f^3 + f/400 form is preferred for fineness
        %   ratios f > 6. Branch on f so each body uses whichever form
        %   applies to its own fineness ratio.
            f = L_body / D_body;
            if f > 6
                FF = 1 + 60/f^3 + f/400;
            else
                FF = 1 + 5/f^1.5 + f/400;
            end
        end

    end
end
