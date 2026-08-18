classdef AeroL3
%AEROL3  Level-3 aerodynamics static toolbox: component CD0 buildup.
%
%   Call as AeroL3.method(...); never instantiated, not in the inheritance
%   chain. F16AeroL3 inherits AeroModelL3 and delegates to these statics.
%
%   Replaces L2's type-based Cfe with a per-component Reynolds / skin-friction
%   / form-factor buildup. The induced terms, the shared skin-friction
%   primitives and the regime test stay in AeroL2 as the single source of
%   truth; this toolbox calls them and owns only the buildup-specific pieces:
%   laminar Cf, cutoff Reynolds, form factors, and the component summation.
%
%   All component geometry is read from the injected geometry object through
%   the concrete class's Dependent getters.
%
%   Sources: [Raymer 6th ed. Eq. 12.24] buildup; [Eq. 12.26] laminar Cf;
%   [Eq. 12.28/12.29] cutoff Reynolds; [Eq. 12.30] surface form factor;
%   [Eq. 12.31] body form factor.
%
%   Supersonic wave drag [Raymer 6th ed. Eq. 12.41, M >= 1.2] is added by the
%   concrete class's get_CD0_buildup override, being aircraft-specific. The
%   transonic band is not modelled.
%
%   Companion doc: src/disciplines/aerodynamics/AeroL3.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
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

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
        function val = get_CD0_buildup(obj, state)
            M = state.mach;
            if ~(M > 0)
                error('AeroL3:machOutOfDomain', ...
                    ['The Raymer Eq. 12.24 component buildup requires M > 0 ', ...
                     '(got M = %g): it is Reynolds-based, and at V = 0 every ', ...
                     'component Re is 0, which makes Cf_laminar infinite and the ', ...
                     'Eq. 12.30 form factor zero. Use a small nonzero Mach for a ', ...
                     'brake-release/static condition, or an L1/L2 drag model, ', ...
                     'which do not depend on Reynolds number.'], M);
            end
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

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
        function e = get_e_osw(obj)
        %GET_E_OSW  OFFICIAL Oswald efficiency (Raymer Eq. 12.48/12.49); reads
        %   obj.AR and obj.Lambda_LE_deg (injected geometry).
            e = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);
        end

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
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

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
        function val = get_K2(obj, K1_sub, M)
            CL_alpha_M = obj.get_CL_alpha(M);
            CL_minD    = AeroL2.compute_CL_minD(CL_alpha_M, obj.alpha_L0);
            val        = AeroL2.K2_value(K1_sub, CL_minD, M);
        end

        % TODO (8/14/2026): Again, flagging as artefact of the subclass era. Relocate to F-16 example class,
        % if it hasn't been done already.
        function val = get_CL_alpha(obj, M)
            val = AeroL2.get_CL_alpha(obj, M);
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
            arguments
                Re (1,1) double {mustBePositive}
            end
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
