classdef (Abstract) Only_TbyW < PointPerformanceBase
%ONLY_TBYW  Abstract category for point-performance conditions that bound
%   thrust-to-weight ratio (T/W) directly, independent of wing loading.
%
%   Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Only_TbyW class -- see
%   Only_WbyS.m's header for the three-category grouping this and its
%   siblings (Only_WbyS, Both_WbyS_TbyW) implement. No F-16 constraint
%   condition currently needs this category (Max Mach/Cruise/Max Alt/Combat
%   Turn 1-2/Excess Power/Takeoff all depend on W/S through the Mattingly
%   Master Equation, and Landing/Stall are W/S-only, see LandingConstraint.m/
%   StallConstraint.m); it is provided for structural completeness, matching
%   the notebook's three-category hierarchy, and for a future condition
%   whose requirement is a flat T/W floor with no aerodynamic/wing-loading
%   term. A concrete subclass need only implement TW_min(obj), the required
%   T/W; this class returns that same value at every W/S.

    methods (Abstract)

        %TW_MIN  Thrust-to-weight ratio [dimensionless] this condition
        %   requires, independent of wing loading.
        TW = TW_min(obj)

    end

    methods

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  Constant T/W requirement, independent of WS. WS may be
        %   scalar or array; TW is returned the same size.
            TW = repmat(obj.TW_min(), size(WS));
        end

    end

end
