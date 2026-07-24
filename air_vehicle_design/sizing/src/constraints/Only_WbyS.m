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

        function [margin, WS_available, WS_required] = WS_margin(obj, W_TO, S_ref)
        %WS_MARGIN  Extra wing-loading "wiggle room" a candidate design has
        %   before hitting this condition's W/S wall.
        %
        %   [Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Only_WbyS.compute_constraint (cell 9): compute_WbyS_Npm2() --
        %   this class's WS_max(), the upper bound the condition's own
        %   physics imposes, independent of any candidate design -- is
        %   labeled "REQUIRED VALUE" there. The notebook's two versions of
        %   its constraint formula (one commented out as "THIS IS THE
        %   ORIGINAL", one live) are literal sign negatives of each other
        %   despite sharing the identical "constraint = required -
        %   available" comment -- an authoring inconsistency, not a
        %   deliberate convention. Working the physics through resolves it:
        %   WS_max is an UPPER bound (a design must be AT MOST this loaded),
        %   so "safe" means actual <= limit, i.e. margin = required -
        %   available (limit minus actual) -- the notebook's commented-out
        %   "ORIGINAL" line -- the opposite sign from
        %   Both_WbyS_TbyW.TW_margin, whose required_TW is a LOWER bound.
        %   margin >= 0 reads as "feasible, with this much W/S to spare" in
        %   both cases, the uniform convention this framework uses (see
        %   PointPerformanceBase.m).]
        %
        %   W_TO  -- the candidate design's actual gross takeoff weight
        %            [lbf] (e.g. WeightsBase.W_TO).
        %   S_ref -- the candidate design's actual wing reference area
        %            [ft^2] (e.g. GeometryBase.S_ref).
        %   Returns margin = WS_required - WS_available, where WS_required =
        %   WS_max() and WS_available = W_TO/S_ref -- both returned as
        %   optional 2nd/3rd outputs so callers (tests in particular) can
        %   inspect the two values a margin was computed from, not just
        %   their difference. margin >= 0 means the design is at or below
        %   this condition's wing-loading limit; margin < 0 means it already
        %   exceeds the limit by that much.
            arguments
                obj
                W_TO  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            WS_available = W_TO / S_ref;
            WS_required  = obj.WS_max();
            margin = WS_required - WS_available;
        end

    end

end
