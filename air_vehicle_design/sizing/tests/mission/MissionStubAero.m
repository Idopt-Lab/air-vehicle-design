classdef MissionStubAero < AerodynamicsBase
%MISSIONSTUBAERO  Minimal AerodynamicsBase stub for mission unit tests.
%   Returns a fixed, Mach-independent drag polar and a fixed clean CLmax, and
%   carries the aircraft_category flag the Roskam fixed-fraction lookup reads.
%   compute_CL/compute_CD are inherited from AerodynamicsBase. Chosen so segment
%   tests can independently replay the cited formulas and compare.

    properties (Constant)
        aircraft_category = "jet_fighter"
    end

    properties
        CD0_   = 0.020
        K1_    = 0.100
        K2_    = 0.0
        CLmax_ = 1.5
    end

    properties
        CLmax_TO_ = 1.2
        CLmax_L_  = 1.4
    end

    methods
        function polar = drag_polar(obj, ~)
            polar = struct('CD0', obj.CD0_, 'K1', obj.K1_, 'K2', obj.K2_);
        end
        function CLmax = get_CLmax(obj, ~)
            CLmax = obj.CLmax_;
        end
        function v = get_CLmax_TO(obj)
            v = obj.CLmax_TO_;
        end
        function v = get_CLmax_L(obj)
            v = obj.CLmax_L_;
        end
    end
end
