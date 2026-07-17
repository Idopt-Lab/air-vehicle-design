classdef F16AeroL1 < AeroModelL1
%F16AEROL1  F-16A Block 10 Level-1 aerodynamics student class.
%
%   Inherits from AeroModelL1 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to AeroL1 statics — no equations
%   are duplicated here.
%
%   Concrete utility methods (compute_CD, compute_CL, compute_CD0, get_CDi) are
%   inherited from AerodynamicsBase.
%
%   SOURCES:
%     S_ref    : T.O. 1F-16A-1, Fig. 1-2 (300 ft^2)
%     AR       : T.O. 1F-16A-1, Fig. 1-2 (AR = b^2/S = 30^2/300 = 3.0)
%     Lambda_LE: T.O. 1F-16A-1, Fig. 1-2 (40 deg)
%     S_wet    : Brandt F-16A.xls Main!L3 (1371 ft^2)
%
%   Expected outputs (for validation):
%     CD0 = 0.0035 * 1371/300 = 0.0160
%     e   = 4.61*(1-0.045*3^0.68)*cos(40)^0.15 - 3.1 ≈ 0.908  [Raymer Eq 12.49]
%     K1  = 1/(pi*3*0.908) ≈ 0.1169  (subsonic)
%     K2  = 0  (CL_minD = 0, symmetric polar)

    properties
        % --- Aircraft-specific inputs
        aircraft_category = "jet_fighter"
        S_ref             = 300       % ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet             = 1371      % ft^2  [Brandt F-16A.xls Main!L3]
        AR                = 3.0       % —     [T.O. 1F-16A-1: b=30ft, S=300ft^2]
        Lambda_LE_deg     = 40        % deg   [T.O. 1F-16A-1, Fig. 1-2]
        CL_minD           = 0.0       % —     symmetric polar approx.
        % --- Computed quantities (initialise to 0; populate by calling methods)
        e_osw_clean  = 0
        LD_max       = 0
        AR_wet       = 0
        K_LD         = 0
        K            = 0
        K1           = 0
        K2           = 0
        Cf           = 0
        CL_max_clean = 0
        CD0          = 0
        CDi          = 0
        CD           = 0
        CL           = 0
    end

    methods

        function obj = F16AeroL1()
            obj.aircraft_category = "jet_fighter";
            obj.S_ref             = 300;
            obj.S_wet             = 1371;
            obj.AR                = 3.0;
            obj.Lambda_LE_deg     = 40;
            obj.CL_minD           = 0.0;
        end

        function polar = drag_polar(obj, state)
            polar = AeroL1.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL1.get_CLmax(obj);
        end

        function e = get_e_osw(obj)
            e = AeroL1.get_e_osw(obj);
        end

        function val = get_K1(obj, M)
            val = AeroL1.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL1.get_K2(obj, K1_sub, M);
        end

        function val = get_CD0(obj)
            val = AeroL1.get_CD0(obj);
        end

        function val = compute_K(~, e_osw, AR)
            val = AeroL1.compute_K(e_osw, AR);
        end

        function val = compute_LD_max(~, K_LD, AR_wet)
            val = AeroL1.compute_LD_max(K_LD, AR_wet);
        end

        function val = compute_AR_wet(~, b, S_wet)
            val = AeroL1.compute_AR_wet(b, S_wet);
        end

        function val = compute_CL_minD(~, airfoil_type, CL_min, ~)
            val = AeroL1.compute_CL_minD(airfoil_type, CL_min);
        end

        function val = lookup_Cf(~, aircraft_type, ~)
            val = AeroL1.lookup_Cf(aircraft_type);
        end

        function val = lookup_CLmax(~, aircraft_type, ~, ~)
            val = AeroL1.lookup_CLmax(aircraft_type);
        end

    end
end
