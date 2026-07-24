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

        %GET_ALPHA  Thrust lapse alpha this condition's own required_TW
        %   (TW_min) uses internally, mirroring Both_WbyS_TbyW.get_alpha --
        %   see that method's header for why TW_margin below reads alpha
        %   from here rather than taking an independently-supplied value.
        alpha = get_alpha(obj)

    end

    methods

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  Constant T/W requirement, independent of WS. WS may be
        %   scalar or array; TW is returned the same size.
            TW = repmat(obj.TW_min(), size(WS));
        end

        function [margin, TW_available, TW_required] = TW_margin(obj, T_SL, W_TO)
        %TW_MARGIN  Extra thrust-to-weight "wiggle room" a candidate design
        %   has at this condition, beyond TW_min() -- mirrors
        %   Both_WbyS_TbyW.TW_margin (simplified since TW_min() has no
        %   wing-loading dependence to evaluate at): TW_available is the
        %   ACTUAL thrust delivered at this condition (T_SL lapsed by
        %   get_alpha()), and TW_min() is rescaled by the same alpha so both
        %   sides land on that same actual-thrust basis. See
        %   Both_WbyS_TbyW.TW_margin's header for the full derivation and why
        %   this doesn't change any feasibility conclusion, only the
        %   reported number.
        %
        %   T_SL -- the candidate design's actual sea-level-static thrust
        %           [lbf] (e.g. PropulsionBase.T_SL).
        %   W_TO -- the candidate design's actual gross takeoff weight
        %           [lbf] (e.g. WeightsBase.W_TO).
        %   Returns margin = TW_available - TW_required, where TW_available
        %   = alpha*T_SL/W_TO and TW_required = alpha*TW_min() -- both
        %   returned as optional 2nd/3rd outputs so callers (tests in
        %   particular) can inspect the two values a margin was computed
        %   from, not just their difference. margin >= 0 means the design
        %   meets or exceeds this condition's requirement.
            arguments
                obj
                T_SL (1,1) double {mustBePositive}
                W_TO (1,1) double {mustBePositive}
            end
            alpha = obj.get_alpha();
            TW_available = alpha * T_SL / W_TO;
            TW_required  = alpha * obj.TW_min();
            margin = TW_available - TW_required;
        end

    end

end
