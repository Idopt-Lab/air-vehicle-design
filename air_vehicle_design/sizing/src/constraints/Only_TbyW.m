classdef (Abstract) Only_TbyW < PointPerformanceBase
%ONLY_TBYW  Abstract category for point-performance conditions that bound
%   thrust-to-weight ratio (T/W) directly, independent of wing loading.
%
%   A concrete subclass implements TW_min(obj), the required T/W; required_TW
%   returns that same value at every W/S. No current F-16 condition uses this
%   category (all thrust conditions depend on W/S through the Master Equation,
%   and Landing/Stall are W/S-only); it is kept for structural completeness of
%   the notebook's three-category hierarchy and for a future flat-T/W-floor
%   condition. Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Only_TbyW class
%   (see Only_WbyS.m for the three-category grouping).

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

        function g = constraint_residual(obj, dp)
        %CONSTRAINT_RESIDUAL  Signed feasibility residual at DesignPoint dp:
        %
        %       g = obj.TW_min() - dp.TW    (g <= 0 feasible)
        %
        %   TW_min is a LOWER bound (a flat T/W floor -- this condition demands
        %   AT LEAST that much T/W, independent of wing loading), so
        %   "available >= required" is the safe direction: g = required -
        %   available = TW_min - dp.TW <= 0 is feasible. dp.WS is unused.
        %   The residual is on the SL-static T_SL/W_TO basis (dp.TW), with NO
        %   thrust-lapse alpha scaling -- consistent with every other category
        %   (see PointPerformanceBase.m). g = -margin.
        %
        %   [Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Only_TbyW.compute_constraint (cell 9): required - available,
        %   feasible <= 0.]
        %
        %   dp -- a DesignPoint (W_TO, T_SL, S_ref); only dp.TW is used.
            arguments
                obj
                dp (1,1) DesignPoint
            end
            g = obj.TW_min() - dp.TW;
        end

    end

end
