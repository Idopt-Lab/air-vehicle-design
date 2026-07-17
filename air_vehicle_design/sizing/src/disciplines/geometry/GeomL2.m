classdef GeomL2 < GeometryModelL2
%GEOML2  Level-2 geometry concrete toolbox.
%
%   Instantiable concrete class that implements the Level-2 component S_wet
%   formulas.  Student classes (F16GeomL2, etc.) inherit from this class and
%   provide aircraft-specific property values in their constructors.
%
%   Inheritance: GeometryBase → GeometryModelL2 → GeomL2 → F16GeomL2
%
%   EQUATIONS:
%     Lifting surfaces: S_wet = S_exposed * (1.977 + 0.52 * tc)
%       [S. Brandt et al., Introduction to Aeronautics, AIAA, 2004;
%        F-16A workbook, Geom sheet, cell B13]
%     Fuselage: S_wet = pi*D*L*(1-2/lambda_f)^(2/3)*(1+1/lambda_f^2)
%       where lambda_f = L/D  (fineness ratio)
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.3]

    properties

        S_ref          = NaN    % ft^2 — wing reference area
        S_wet          = NaN    % ft^2 — total wetted area (output of get_S_wet)

        % Wing (abstract in GeometryModelL2 via GeometryBase)
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
        tc_wing        = NaN    % L2 uses a single average t/c per surface

        % Fuselage (abstract in GeometryModelL2)
        L_fuselage     = NaN
        W_max_fuselage = NaN
        H_max_fuselage = NaN
        D_fus          = NaN    % equivalent diameter for Roskam Eq. 12.3
        L_fus          = NaN

        % Horizontal tail (not abstract at L2; needed by L2 planform formula)
        S_exposed_ht   = NaN
        tc_ht          = NaN

        % Vertical tail (not abstract at L2; needed by L2 planform formula)
        S_exposed_vt   = NaN
        tc_vt          = NaN

    end

    % ====================================================================== %
    methods

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
            val = obj.get_S_wet_wing()     + obj.get_S_wet_HT() + ...
                  obj.get_S_wet_VT()       + obj.get_S_wet_fuselage();
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

    end

    % ====================================================================== %
    methods (Static)

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
