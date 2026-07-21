classdef GeomL2
%GEOML2  Level-2 geometry static toolbox: component-level wetted-area formulas.
%
%   Call as GeomL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16GeomL2, etc.) inherit
%   from GeometryModelL2 and call these statics to implement each abstract method.
%
%   EQUATIONS:
%     Lifting surfaces: S_wet = S_exposed * (1.977 + 0.52 * tc)
%       [S. Brandt et al., Introduction to Aeronautics, AIAA, 2004;
%        F-16A workbook, Geom sheet, cell B13]
%     Fuselage: S_wet = pi*D*L*(1-2/lambda_f)^(2/3)*(1+1/lambda_f^2)
%       where lambda_f = L/D  (fineness ratio)
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.3]

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet(obj, ~)
            val = GeomL2.get_S_wet_wing(obj)     + GeomL2.get_S_wet_HT(obj) + ...
                  GeomL2.get_S_wet_VT(obj)        + GeomL2.get_S_wet_fuselage(obj);
        end

        function val = get_S_wet_wing(obj)
            val = GeomL2.compute_wet_planform(obj.S_exposed_wing, obj.tc_wing);
        end

        function val = get_S_wet_HT(obj)
            val = GeomL2.compute_wet_planform(obj.S_exposed_ht, obj.tc_ht);
        end

        function val = get_S_wet_VT(obj)
            val = GeomL2.compute_wet_planform(obj.S_exposed_vt, obj.tc_vt);
        end

        function val = get_S_wet_fuselage(obj)
            val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/arrays, no object access.
        % ================================================================== %

        function val = compute_wet_planform(S_exp, tc)
        %COMPUTE_WET_PLANFORM  S_wet = S_exposed*(1.977 + 0.52*tc)
        %   [Brandt F-16A workbook, Geom sheet, cell B13]
            val = S_exp * (1.977 + 0.52 * tc);
        end

        function val = compute_s_wet_fus_cyl(D_fus, L_fus)
        %COMPUTE_S_WET_FUS_CYL  Roskam Vol. II Eq. 12.3 cylindrical-midsection fuselage.
        %   lambda_f = L/D  (fineness ratio).
            lambda_f = L_fus / D_fus;
            val = pi * D_fus * L_fus ...
                  * (1 - 2/lambda_f)^(2/3) ...
                  * (1 + 1/lambda_f^2);
        end

    end
end
