classdef GeomL3 < GeometryModelL3
%GEOML3  Level-3 geometry concrete toolbox.
%
%   Instantiable concrete class that implements the Level-3 component S_wet
%   formulas.  Student classes (F16GeomL3, etc.) inherit from this class and
%   provide aircraft-specific property values in their constructors.
%
%   Inheritance: GeometryBase → GeometryModelL3 → GeomL3 → F16GeomL3
%
%   EQUATIONS:
%     Lifting surfaces: S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.1]
%     Fuselage: same as GeomL2 — Roskam Vol. II Eq. 12.3.
%     Duct (frustum): S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2)
%       [Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Sec. 7.3]
%
%   Property naming convention:
%     HT/VT properties use UPPERCASE suffixes (S_exposed_HT, lambda_HT, etc.)
%     to match the abstract declarations in GeometryModelL3.
%     t/c properties use lowercase (tc_r_ht, tc_t_ht, etc.) — not abstract.

    properties

        S_ref          = NaN
        S_wet          = NaN

        % Fuselage (abstract in GeometryModelL3)
        L_fuselage     = NaN
        W_max_fuselage = NaN
        H_max_fuselage = NaN
        D_fus          = NaN
        L_fus          = NaN

        % Wing (abstract in GeometryModelL3)
        S_exposed_wing = NaN
        S_wet_wing     = NaN
        QC_sweep_wing  = NaN
        lambda_wing    = NaN
        b_wing         = NaN
        AR_wing        = NaN
        LE_sweep_wing  = NaN
        TE_sweep_wing  = NaN
        c_tip_wing     = NaN
        c_root_wing    = NaN
        tc_r_wing      = NaN    % root t/c (not abstract; L3 uses separate root/tip)
        tc_t_wing      = NaN    % tip  t/c

        % Horizontal tail (abstract in GeometryModelL3 — uppercase HT)
        S_exposed_HT   = NaN
        S_wet_HT       = NaN
        QC_sweep_HT    = NaN
        lambda_HT      = NaN
        b_HT           = NaN
        AR_HT          = NaN
        LE_sweep_HT    = NaN
        TE_sweep_HT    = NaN
        c_tip_HT       = NaN
        c_root_HT      = NaN
        tc_r_ht        = NaN    % root t/c (lowercase; not abstract)
        tc_t_ht        = NaN    % tip  t/c

        % Vertical tail (abstract in GeometryModelL3 — uppercase VT)
        S_exposed_VT   = NaN
        S_wet_VT       = NaN
        QC_sweep_VT    = NaN
        lambda_VT      = NaN
        b_VT           = NaN
        AR_VT          = NaN
        LE_sweep_VT    = NaN
        TE_sweep_VT    = NaN
        c_tip_VT       = NaN
        c_root_VT      = NaN
        tc_r_vt        = NaN    % root t/c (lowercase; not abstract)
        tc_t_vt        = NaN    % tip  t/c

        % Duct
        D_inlet        = NaN
        D_exit         = NaN
        L_duct         = NaN

    end

    % ====================================================================== %
    methods

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
            val = obj.get_S_wet_wing()   + obj.get_S_wet_HT() + ...
                  obj.get_S_wet_VT()     + obj.get_S_wet_fuselage() + ...
                  obj.get_S_wet_duct();
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

    end

    % ====================================================================== %
    methods (Static)

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
