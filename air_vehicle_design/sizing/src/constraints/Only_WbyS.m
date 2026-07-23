classdef (Abstract) Only_WbyS < PointPerformanceBase
%ONLY_WBYS  Abstract category for point-performance conditions that bound
%   wing loading (W/S) directly, with no thrust dependence at all.
%
%   Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Only_WbyS class (the
%   notebook groups its point-performance conditions into three categories --
%   Only_WbyS, Only_TbyW, Both_WbyS_TbyW -- by which of W/S and T/W each
%   condition's governing equation actually depends on; see
%   sizing/docs/subplans/06_constraint_analysis.md's Design Notes and this
%   class's siblings Only_TbyW.m/Both_WbyS_TbyW.m). A concrete subclass need
%   only implement WS_max(obj), the upper bound this condition imposes on
%   wing loading (e.g. LandingConstraint's braking ground roll,
%   StallConstraint's stall-speed requirement) -- this class supplies the
%   uniform required_TW(WS) interface every PointPerformanceBase condition
%   must expose (see that class's header and ConstraintAnalysis.m), encoding
%   the W/S limit as a vertical wall: required_TW returns 0 (no thrust
%   penalty) at or below the limit and Inf (infeasible) above it, so
%   ConstraintAnalysis's max-envelope combination (TW_envelope(WS) =
%   max_i required_TW_i(WS)) excludes infeasible W/S without any special-
%   casing (see ConstraintAnalysis.m's header). This wall encoding was
%   previously implemented ad hoc inside LandingConstraint itself; it is
%   factored out here so every W/S-only condition (Landing, Stall, ...)
%   shares one implementation instead of each re-deriving it.

    methods (Abstract)

        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] this condition
        %   imposes. Concrete subclasses compute this from their own
        %   governing equation (e.g. landing ground roll, stall speed).
        WS = WS_max(obj)

    end

    methods

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  Vertical-wall encoding of this condition's W/S limit:
        %   0 (no thrust penalty) at or below the limit, Inf (infeasible)
        %   above it. WS may be scalar or array; TW is returned the same size.
            WS_limit = obj.WS_max();
            TW = zeros(size(WS));
            TW(WS > WS_limit) = Inf;
        end

    end

end
