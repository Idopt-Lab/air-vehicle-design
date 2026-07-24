classdef AeroL3
%AEROL3  Level-3 aerodynamics static toolbox: component CD0 buildup.
%
%   Call as AeroL3.method_name(args) -- no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL3, etc.) inherit
%   from AeroModelL3 and call these statics.
%
%   Replaces the type-based Cf with a per-component Reynolds/skin-friction/
%   form-factor buildup.  The induced (K1/K2/e), the shared skin-friction
%   primitives (dyn_viscosity, compute_Re, Cf_turbulent), and the transonic
%   regime test live in the AeroL2 toolbox (single source of truth); this
%   toolbox calls them.  AeroL3 owns the buildup-specific primitives: laminar
%   Cf, cutoff Reynolds, form factors, and the component summation.
%
%   All component geometry (per-component S_wet, reference length, diameter,
%   t/c, max-thickness-line sweep) is read from the injected geometry object
%   via the student object's Dependent getters -- this toolbox never sees a
%   hardcoded geometry number; it reads whatever obj exposes (duck typing).
%
%   EQUATIONS:
%     CD0 = SUM(Cf_eff*FF*Q*Swet_i)/Sref + CD0_misc + CD0_LandP   Raymer Eq. 12.24
%     Re         = rho*V*l/mu                       Eq. 12.25 (AeroL2.compute_Re)
%     Cf_lam     = 1.328/sqrt(Re)                   Eq. 12.26
%     Cf_turb    = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Eq. 12.27 (AeroL2.Cf_turbulent)
%     Re_cut_sub = 38.21*(l/k)^1.053                Eq. 12.28
%     Re_cut_sup = 44.62*(l/k)^1.053*M^1.16         Eq. 12.29
%     FF_surf    = (1+0.6/x_c_max*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28)  Eq. 12.30
%     FF_body    = 1+5/f^1.5+f/400 (f<=6) or 1+60/f^3+f/400 (f>6), f=L/D    Eq. 12.31
%
%   Supersonic wave drag (Raymer Eq. 12.41, M >= 1.2) is added by the concrete
%   class's get_CD0_buildup override (it is aircraft-specific, not generic).
%   The transonic band (see AeroL2.flight_regime) is NOT modeled.

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  L3 drag polar {CD0, K1, K2} at the flight state.
        %   CD0 from the component buildup (obj.get_CD0_buildup, dynamically
        %   dispatched so a concrete class's wave-drag override is included);
        %   K1/K2 as at L2. Transonic band returns NaN (not modeled).
            M      = state.mach;
            regime = AeroL2.flight_regime(M);
            if regime == "transonic"
                warning('AeroL3:transonicNotModeled', ...
                    ['L3 drag polar is not modeled in the transonic band ' ...
                     '(%.2f < M=%.4f < %.2f): the Raymer Eq. 12.51 supersonic ' ...
                     'K1 is singular near M=1. Returning NaN.'], ...
                    AeroL2.MACH_SUBSONIC_MAX, M, AeroL2.MACH_SUPERSONIC_MIN);
                polar = struct('CD0', NaN, 'K1', NaN, 'K2', NaN);
                return
            end
            cd0 = obj.get_CD0_buildup(state);
            if regime == "subsonic"
                e   = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);
                k1  = AeroL2.K1_subsonic(e, obj.AR);
                k2  = AeroL3.get_K2(obj, k1, M);
            else   % "supersonic"
                k1  = AeroL2.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
                k2  = 0;   % K2=0 for M>=1 (linearized supersonic theory)
            end
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function val = get_CD0_buildup(obj, state)
        %GET_CD0_BUILDUP  Generic Raymer Eq. 12.24 component sum:
        %   SUM(Cf_eff*FF*Q*S_wet)/S_ref + CD0_misc + CD0_LandP.
        %   Reads the per-component arrays from obj (built live from the
        %   injected geometry object). Supersonic wave drag is NOT added here
        %   (it is aircraft-specific -- the concrete class overrides this
        %   method to add it for M >= 1.2).
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
                re_eff = min(AeroL2.compute_Re(state, l_i), re_cut);
                cf_l   = AeroL3.Cf_laminar(re_eff);
                cf_t   = AeroL2.Cf_turbulent(re_eff, M);
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

        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer Eq. 12.25). Shared L2 primitive.
            Re = AeroL2.compute_Re(state, l_ref);
        end

        function Cf_lam = compute_Cf_lam(Re)
        %COMPUTE_CF_LAM  Laminar skin-friction coefficient  (Raymer Eq. 12.26).
            Cf_lam = AeroL3.Cf_laminar(Re);
        end

        function Cf_turb = compute_Cf_turb(Re, M)
        %COMPUTE_CF_TURB  Turbulent skin-friction coefficient (Raymer Eq. 12.27).
            Cf_turb = AeroL2.Cf_turbulent(Re, M);
        end

        function FF = compute_FF_surface(tc, x_c_max, Lambda_m_deg, M)
        %COMPUTE_FF_SURFACE  Form factor for a lifting surface  (Raymer Eq. 12.30).
            FF = AeroL3.FF_surface(tc, x_c_max, Lambda_m_deg, M);
        end

        function FF = compute_FF_fus(L_body, D_body)
        %COMPUTE_FF_FUS  Form factor for a body/fuselage  (Raymer Eq. 12.31).
            FF = AeroL3.FF_body(L_body, D_body);
        end

        function [Cf_lam_result, Cf_turb_result] = compute_Cf(R, M)
        %COMPUTE_CF  Per-component Cf at Reynolds R and Mach M.
        %   Returns [Cf_lam, Cf_turb] (Raymer Eq. 12.26 / 12.27).
            Cf_lam_result  = AeroL3.Cf_laminar(R);
            Cf_turb_result = AeroL2.Cf_turbulent(R, M);
        end

        function val = get_R_cutoff(obj, ref_length, M)
        %GET_R_CUTOFF  Cutoff Reynolds for ref_length at Mach M; reads obj.k.
        %   Raymer 6th ed. Eq. 12.28 (subsonic) / Eq. 12.29 (supersonic).
            if M > 1
                val = AeroL3.Re_cutoff_sup(ref_length, obj.k, M);
            else
                val = AeroL3.Re_cutoff_sub(ref_length, obj.k);
            end
        end

        function e = get_e_osw(obj)
        %GET_E_OSW  OFFICIAL Oswald efficiency (Raymer Eq. 12.48/12.49); reads
        %   obj.AR and obj.Lambda_LE_deg (injected geometry).
            e = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_K1(obj, M)
        %GET_K1  Induced-drag factor at Mach M (subsonic/supersonic branch).
            regime = AeroL2.flight_regime(M);
            switch regime
                case "subsonic"
                    val = AeroL2.K1_subsonic(AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg), obj.AR);
                case "supersonic"
                    val = AeroL2.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
                otherwise
                    error('AeroL3:transonicNotModeled', ...
                        'K1 not modeled in the transonic band (M=%.4f).', M);
            end
        end

        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term (Convention A).
        %   CL_minD = CL_alpha(M)*(-deg2rad(alpha_L0)/2)  [Brandt Sec. 4.3],
        %   evaluated at Mach M via obj.get_CL_alpha (honoring any concrete
        %   override that passes quarter-chord sweep). M>=1: K2=0.
            CL_alpha_M = obj.get_CL_alpha(M);
            CL_minD    = AeroL2.compute_CL_minD(CL_alpha_M, obj.alpha_L0);
            val        = AeroL2.K2_value(K1_sub, CL_minD, M);
        end

        function val = get_CL_alpha(obj, M)
        %GET_CL_ALPHA  Finite-wing lift-curve slope (Raymer Eq. 12.6) using the
        %   injected quarter-chord sweep obj.Lambda_c4_deg (NOT leading-edge --
        %   fixes the former Lambda_LE approximation).
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- buildup-specific primitives (L3-owned).
        % ================================================================== %

        function Re_cut = Re_cutoff_sub(l, k)
        %RE_CUTOFF_SUB  Roughness-limited Re, subsonic.  Raymer 6th ed. Eq. 12.28.
            Re_cut = 38.21 * (l/k)^1.053;
        end

        function Re_cut = Re_cutoff_sup(l, k, M)
        %RE_CUTOFF_SUP  Roughness-limited Re, supersonic.  Raymer 6th ed. Eq. 12.29.
            Re_cut = 44.62 * (l/k)^1.053 * M^1.16;
        end

        function Cf = Cf_laminar(Re)
        %CF_LAMINAR  Laminar flat-plate Cf = 1.328/sqrt(Re).  Raymer 6th ed. Eq. 12.26.
            Cf = 1.328 / sqrt(Re);
        end

        function FF = FF_surface(tc, x_c_max, Lambda_m_deg, M)
        %FF_SURFACE  Lifting-surface form factor.  Raymer 6th ed. Eq. 12.30.
        %   x_c_max guarded positive (0.6/x_c_max denominator).
            arguments
                tc           (1,1) double {mustBeNonnegative}
                x_c_max      (1,1) double {mustBePositive}
                Lambda_m_deg (1,1) double {mustBeReal}
                M            (1,1) double {mustBeNonnegative}
            end
            FF = (1 + 0.6/x_c_max * tc + 100*tc^4) * ...
                 (1.34 * M^0.18 * cosd(Lambda_m_deg)^0.28);
        end

        function FF = FF_body(L_body, D_body)
        %FF_BODY  Body/fuselage form factor.  Raymer 6th ed. Eq. 12.31.
        %   Printed as 1 + 5/f^1.5 + f/400 (f = l/d); the 1 + 60/f^3 + f/400
        %   form is preferred for fineness ratios f > 6, so branch on f.
        %   D_body guarded positive (fineness-ratio denominator).
            arguments
                L_body (1,1) double {mustBePositive}
                D_body (1,1) double {mustBePositive}
            end
            f = L_body / D_body;
            if f > 6
                FF = 1 + 60/f^3 + f/400;
            else
                FF = 1 + 5/f^1.5 + f/400;
            end
        end

    end
end
