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


        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer Eq. 12.25). Shared L2 primitive.
            Re = AeroL2.compute_Re(state, l_ref);
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
