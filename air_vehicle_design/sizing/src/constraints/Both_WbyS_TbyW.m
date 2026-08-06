classdef (Abstract) Both_WbyS_TbyW < PointPerformanceBase
%BOTH_WBYS_TBYW  Abstract, generic category for point-performance conditions
%   that impose a required T/W which depends on wing loading W/S.
%
%     T_SL/W_TO = required_TW(W_TO/S)
%
%   Declares required_TW(WS) abstract and supplies the uniform
%   constraint_residual on top of it. It is generic: it knows only that a
%   required T/W exists and varies with W/S. A concrete subclass
%   (MasterEquationConstraint for the Mattingly Master Equation,
%   TakeoffConstraint for the ground-roll relation) supplies required_TW(WS)
%   from its own physics. Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
%   Both_WbyS_TbyW class (see Only_WbyS.m for the three-category grouping).

    methods (Abstract)

        %REQUIRED_TW  Thrust-to-weight ratio required to satisfy this
        %   condition at wing loading(s) WS [lbf/ft^2] (scalar or array);
        %   returns TW the same size. Each concrete subclass builds this from
        %   its own governing equation (MasterEquationConstraint's
        %   A/(W/S)+B*(W/S)+C+D, TakeoffConstraint's ground-roll affine form)
        %   and self-guards any non-finite term there.
        TW = required_TW(obj, WS)

    end

    methods

        function g = constraint_residual(obj, dp)
        %CONSTRAINT_RESIDUAL  Signed feasibility residual at DesignPoint dp:
        %
        %       g = obj.required_TW(dp.WS) - dp.TW    (g <= 0 feasible)
        %
        %   required_TW is a LOWER bound (this condition demands at least that
        %   much T/W at the design point's wing loading dp.WS), so g = required
        %   - available <= 0 is feasible. Both sides sit on the sea-level-static
        %   T_SL/W_TO axis (required_TW divides its thrust demand by the
        %   condition's alpha; available is the installed dp.TW), with no
        %   thrust-lapse scaling -- the same axis the constraint diagram plots.
        %   g = -margin. Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Both_WbyS_TbyW.compute_constraint (cell 9): necessary - actual,
        %   feasible <= 0.
        %
        %   dp -- a DesignPoint (W_TO, T_SL, S_ref); dp.WS and dp.TW are used.
            arguments
                obj
                dp (1,1) DesignPoint
            end
            g = obj.required_TW(dp.WS) - dp.TW;
        end
    end
end
