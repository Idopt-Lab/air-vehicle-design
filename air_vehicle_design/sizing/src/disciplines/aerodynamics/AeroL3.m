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
%   concrete class's get_CD0_component_buildup override, being aircraft-specific. The
%   transonic band is not modelled.
%
%   Companion doc: src/disciplines/aerodynamics/AeroL3.md

    methods (Static)


        function Re = compute_Re(state, l_ref)
        %COMPUTE_RE  Re = rho*V*l/mu  (Raymer Eq. 12.25). Shared L2 primitive.
        % Re-using L2 because it's the same exact equation.
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
            % Source: Raymer, 6th edition, equation 12.26
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
            % Source: Raymer, 6th edition, Eq. 12.31
            % Valid for fuselage and smooth canopies.
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

        function CD0_component = compute_CD0_misc_CD_pi(CD_pi, frontal_area, S_ref)
            % Source: Raymer, 6th edition, Table 12.6
            % Valid for generic physical objects, given a frontal area and a known "CD_pi" value (from table 12.6)
            CD0_component = CD_pi*frontal_area/S_ref;
        end

        function CD0_component = compute_CD0_misc_DQ(D_q, S_ref)
            % Source: Raymer, 6th edition, Table 12.7
            % Valid for general physical objects, given their D_q and a known S_ref.
            CD0_component = D_q/S_ref;
        end

        function LandP_frac = lookup_LandP_frac(LandP_rowname)
            % Looks up the fraction for estimating 
            % the drag component due to leakages and protuberances.
            % ARGS:
            %   LandP_rowname: (string) The aircraft type corresponding to the row name in Table 12.8, Raymer 6th edition.
            % RETURNS:
            %   LandP_frac: (double) Percent of drag that is due to leakages and protuberances (should be added to the total CD0 value)

            switch LandP_rowname
                case "propeller aircraft", LandP_frac = [0.05, 0.10];
                case "jet transport", LandP_frac = [0.02, 0.05];
                case "bomber", LandP_frac = [0.02, 0.05];
                case "non-stealth fighter", LandP_frac = [0.10, 0.15];
                case "stealth fighter", LandP_frac = [0.03, 0.05];
                otherwise
                    error("lookup_LandP_fraction:AeroL3 - failed to identify aircraft type. Accepted types are given by Table 12.8, Raymer, 6th edition. Accepted types are: 'propeller aircraft', 'jet transport', 'bomber', 'non-stealth fighter', & 'stealth fighter'.");
            end
        end

    end
end
