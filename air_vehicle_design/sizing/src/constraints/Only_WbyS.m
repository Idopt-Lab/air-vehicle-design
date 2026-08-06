classdef (Abstract) Only_WbyS < PointPerformanceBase
%ONLY_WBYS  Abstract category for point-performance conditions that bound
%   wing loading (W/S) directly, with no thrust dependence.
%
%   A concrete subclass implements WS_max(obj), the upper bound this condition
%   imposes on wing loading (e.g. LandingConstraint's braking ground roll,
%   StallConstraint's stall-speed requirement). An Only_WbyS imposes no thrust
%   demand, so it has no required_TW; ConstraintAnalysis reads it as an
%   explicit W/S wall via WS_max() (excluding W/S > WS_max from the optimum
%   search), not as a curve.
%
%   Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Only_WbyS class -- the
%   notebook groups point-performance conditions into three categories
%   (Only_WbyS, Only_TbyW, Both_WbyS_TbyW) by which of W/S and T/W each
%   condition's governing equation depends on (see the sibling category
%   classes Only_TbyW.m / Both_WbyS_TbyW.m).

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
        %   A W/S-wall condition: the residual is on the W/S axis, dp.TW
        %   unused. WS_max is an upper bound (the design must be AT MOST this
        %   loaded), so g = dp.WS - WS_max <= 0 is feasible -- the same
        %   required - available sign convention every category uses
        %   (PointPerformanceBase.m). g = -margin. Mirrors
        %   NPTEL_Fighter_Aircraft_Sizing.ipynb's Only_WbyS.compute_constraint
        %   (cell 9).
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
