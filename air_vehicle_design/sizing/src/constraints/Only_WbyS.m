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
%   StallConstraint's stall-speed requirement).
%
%   NO required_TW (removed 2026-08-04, T9): a W/S-only wall imposes no
%   thrust demand at all, so it has no "required T/W" to report. The old
%   0/Inf "wall curve" hack -- required_TW returning 0 below the limit and
%   Inf above it, so it could ride ConstraintAnalysis's max-envelope
%   uniformly -- is gone. ConstraintAnalysis now reads an Only_WbyS as an
%   EXPLICIT W/S wall via WS_max() (excluding W/S > WS_max from the optimum
%   search) rather than folding a fake curve into the max(). This is exactly
%   equivalent -- below the wall the Inf-curve contributed 0 to the max, at/
%   above it was excluded -- but honest: no condition is asked for a quantity
%   it does not define. See ConstraintAnalysis.m and
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.

    methods (Abstract)

        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] this condition
        %   imposes. Concrete subclasses compute this from their own
        %   governing equation (e.g. landing ground roll, stall speed).
        WS = WS_max(obj)

    end

    methods

        function g = constraint_residual(obj, dp)
        %CONSTRAINT_RESIDUAL  Signed feasibility residual at DesignPoint dp:
        %
        %       g = dp.WS - obj.WS_max()    (g <= 0 feasible)
        %
        %   This is a W/S-WALL condition, so the residual is on the W/S axis,
        %   not T/W: dp.TW is unused. WS_max is an UPPER bound (a design must
        %   be AT MOST this loaded), so "available <= required" is the safe
        %   direction. Writing it as required - available with dp.WS the
        %   "available" wing loading and WS_max the "required" limit gives
        %   g = dp.WS - WS_max <= 0 feasible -- the same sign convention every
        %   other category uses (see PointPerformanceBase.m). g = -margin.
        %
        %   [Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Only_WbyS.compute_constraint (cell 9), whose compute_WbyS_Npm2()
        %   is the "REQUIRED VALUE" (this class's WS_max()); its two draft
        %   formulas are sign negatives of each other -- working the physics
        %   through (WS_max is an upper bound) fixes the sign to the one
        %   returned here.]
        %
        %   dp -- a DesignPoint (W_TO, T_SL, S_ref); only dp.WS is used.
            arguments
                obj
                dp (1,1) DesignPoint
            end
            g = dp.WS - obj.WS_max();
        end

    end

end
