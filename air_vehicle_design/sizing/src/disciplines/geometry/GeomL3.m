classdef GeomL3
%GEOML3  Level-3 geometry static toolbox: variable-tc planform + duct formulas.
%
%   Call as GeomL3.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16GeomL3, etc.) inherit
%   from GeometryModelL3 and call these statics to implement each abstract method.
%
%   EQUATIONS:
%     Lifting surfaces: S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.1]
%     Fuselage: same as GeomL2 — Roskam Vol. II Eq. 12.3.
%     Duct (frustum): S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2)
%       [Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Sec. 7.3]

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet(obj, ~)
            val = GeomL3.get_S_wet_wing(obj)   + GeomL3.get_S_wet_HT(obj) + ...
                  GeomL3.get_S_wet_VT(obj)     + GeomL3.get_S_wet_fuselage(obj) + ...
                  GeomL3.get_S_wet_duct(obj);
        end

        function val = get_S_wet_wing(obj)
            val = GeomL3.compute_roskam_planform(obj.S_exposed_wing, ...
                      obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
        end

        function val = get_S_wet_HT(obj)
            val = GeomL3.compute_roskam_planform(obj.S_exposed_HT, ...
                      obj.tc_r_ht, obj.tc_t_ht, obj.lambda_HT);
        end

        function val = get_S_wet_VT(obj)
            val = GeomL3.compute_roskam_planform(obj.S_exposed_VT, ...
                      obj.tc_r_vt, obj.tc_t_vt, obj.lambda_VT);
        end

        function val = get_S_wet_fuselage(obj)
            val = GeomL3.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        function val = get_S_wet_duct(obj)
            val = GeomL3.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        end

        function val = get_S_exposed_wing(obj)
            val = obj.S_exposed_wing;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/arrays, no object access.
        % ================================================================== %

        function val = compute_roskam_planform(S_exp, tc_r, tc_t, lambda)
        %COMPUTE_ROSKAM_PLANFORM  S_wet via Roskam Vol. II Eq. 12.1.
        %   S_exp  — exposed planform area (ft^2)
        %   tc_r   — root t/c ratio
        %   tc_t   — tip  t/c ratio
        %   lambda — taper ratio (c_tip/c_root)
            val = 2 * S_exp * (1 + 0.25*tc_r * (1 + (tc_r/tc_t)*lambda) / (1 + lambda));
        end

        function val = compute_s_wet_fus_cyl(D_fus, L_fus)
        %COMPUTE_S_WET_FUS_CYL  Roskam Vol. II Eq. 12.3 fuselage wetted area.
        %   lambda_f = L/D  (fineness ratio).
            lambda_f = L_fus / D_fus;
            val = pi * D_fus * L_fus ...
                  * (1 - 2/lambda_f)^(2/3) ...
                  * (1 + 1/lambda_f^2);
        end

        function val = compute_s_wet_duct(D_inlet, D_exit, L_duct)
        %COMPUTE_S_WET_DUCT  Lateral area of a right circular frustum (inlet/duct).
        %   Degenerates to pi*D*L for constant-section duct (D_inlet == D_exit).
            r1  = D_inlet / 2;
            r2  = D_exit  / 2;
            val = pi * (r1 + r2) * sqrt((r2 - r1)^2 + L_duct^2);
        end

    end
end
