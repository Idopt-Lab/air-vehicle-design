classdef F16AeroL2 < AeroModelL2
%F16AEROL2  F-16A Block 10 Level-2 aerodynamics student class.
%
%   Inherits from AeroModelL2 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to AeroL2 statics — no equations
%   are duplicated here.
%
%   Concrete utility methods (compute_CD, compute_CL, compute_CD0, get_CDi) are
%   inherited from AerodynamicsBase.
%
%   SOURCES:
%     S_ref, AR, Lambda_LE: T.O. 1F-16A-1, Fig. 1-2
%     Lambda_c4_deg: approximately 37 deg for F-16 wing (derived from planform)
%     S_wet: Brandt F-16A.xls Main!L3 (1371 ft^2)
%     cl_max_2D: NACA 64A204 thin section, cl_max ≈ 1.20 (estimated;
%                see Abbott & von Doenhoff, Table of Airfoil Data, 1959)
%
%   Expected outputs at M = 0.6 (for validation):
%     beta = sqrt(1 - 0.36) = 0.800
%     CL_alpha ≈ 2*pi*3 / (2 + sqrt(4 + (3*0.8)^2*(1+tan(37°)^2/0.64)))
%              ≈ 18.85 / (2 + sqrt(4 + 5.76*(1+0.565)))  ≈ 2.71 /rad
%     CLmax = 0.9 * 1.20 * cos(37°) = 0.9 * 1.20 * 0.7986 = 0.862

    properties
        % --- Aircraft-specific inputs
        aircraft_category = "jet_fighter"
        S_ref             = 300        % ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet             = 1371       % ft^2  [Brandt F-16A.xls Main!L3]
        AR                = 3.0        % —     [T.O. 1F-16A-1: b=30ft, S=300ft^2]
        Lambda_LE_deg     = 40         % deg   [T.O. 1F-16A-1, Fig. 1-2]
        Lambda_c4_deg     = 37         % deg   [derived from F-16 planform geometry]
        CL_minD           = 0.0        % —     symmetric polar approx.
        cl_max_2D         = 1.20       % —     NACA 64A204 [Abbott & von Doenhoff, 1959]
        % --- Computed aerodynamic quantities (initialise to 0; populate by calling methods)
        e_osw_clean  = 0
        K_LD         = 0
        K            = 0
        K1           = 0
        K2           = 0
        Cf           = 0
        CL_minD_val  = 0
        CL_max_clean = 0
        CD0          = 0
        CDi          = 0
        CD           = 0
        CL           = 0
        F            = 0
    end

    properties (Constant)
        % Tabulated from Raymer figures/tables for the F-16A NACA 64A204 wing.
        airfoiltype     = "cambered"
        C1              = 0.5       % Raymer 6th ed. Fig. 12.12, λ = 0.23
        C2              = 0.65      % Raymer 6th ed. Fig. 12.12, λ = 0.23
        CL_max_base     = 0.91      % Raymer 6th ed. Fig. 12.13
        sharpness_param = 0.7720    % Raymer 6th ed. Table 12.1
        CL_max_cl_max   = 1.1       % Raymer 6th ed. Fig. 12.9, Λ_LE = 40°
        cl_max          = 1.0       % NTRS-19870017427 p. 14 (NACA 64A204)
        alpha_L0        = -1.01     % deg — zero-lift AOA [NACA 64A204 data]
    end

    methods

        function obj = F16AeroL2()
            obj.aircraft_category = "jet_fighter";
            obj.S_ref             = 300;
            obj.S_wet             = 1371;
            obj.AR                = 3.0;
            obj.Lambda_LE_deg     = 40;
            obj.Lambda_c4_deg     = 37;
            obj.CL_minD           = 0.0;
            obj.cl_max_2D         = 1.20;
        end

        function polar = drag_polar(obj, state)
            polar = AeroL2.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL2.get_CLmax(obj);
        end

        function e = get_e_osw(obj)
            e = AeroL2.get_e_osw(obj);
        end

        function val = get_K1(obj, M)
            val = AeroL2.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL2.get_K2(obj, K1_sub, M);
        end

        function val = get_CD0(obj)
            val = AeroL2.get_CD0(obj);
        end

        function val = compute_K(~, e_osw, AR)
            val = AeroL2.compute_K(e_osw, AR);
        end

        function val = compute_CL_minD(~, CL_alpha, alpha_L0)
            val = AeroL2.compute_CL_minD(CL_alpha, alpha_L0);
        end

        function val = lookup_Cf(~, aircraft_type, ~)
            val = AeroL1.lookup_Cf(aircraft_type);
        end

        function val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
            val = AeroL2.get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max);
        end

        function val = get_CL_alpha(obj, M)
            val = AeroL2.get_CL_alpha(obj, M);
        end

        function val = compute_F(~, d, b)
            val = AeroL2.compute_F(d, b);
        end

        function val = compute_Delta_CL_max_values(~, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
            val = AeroL2.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg);
        end

        function val = lookup_Delta_cl_max_values(~, liftdevice, config, cp_c)
            val = AeroL2.lookup_Delta_cl_max_values(liftdevice, config, cp_c);
        end

    end
end
