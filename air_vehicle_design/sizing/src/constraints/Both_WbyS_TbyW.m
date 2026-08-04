classdef (Abstract) Both_WbyS_TbyW < PointPerformanceBase
%BOTH_WBYS_TBYW  Abstract, GENERIC category for point-performance conditions
%   that impose a required T/W which depends on wing loading W/S.
%
%   Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Both_WbyS_TbyW class -- see
%   Only_WbyS.m's header for the three-category grouping this and its
%   siblings (Only_WbyS, Only_TbyW) implement.
%
%   GENERIC (2026-08-04): this class knows ONLY that a required T/W exists and
%   varies with W/S. It declares required_TW(WS) abstract and supplies the one
%   uniform constraint_residual on top of it. It NO LONGER bakes in the
%   Mattingly "Master Equation" -- that A/B/C/D assembly, its compute_A/B/C/D
%   and get_alpha hooks, and its non-finite self-guard all moved DOWN into the
%   new MasterEquationConstraint subclass (which every thrust condition --
%   LevelFlight/SustainedTurn/ExcessPower -- now specializes). This keeps
%   TakeoffConstraint, whose required_TW is a ground-roll relation and not the
%   Master Equation, a clean sibling under this same generic category rather
%   than a special case of a Master-Equation base. See
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.
%
%     T_SL/W_TO = required_TW(W_TO/S)
%
%   A concrete subclass (MasterEquationConstraint, TakeoffConstraint) supplies
%   required_TW(WS) from its own condition's physics; this class assembles it
%   into the uniform feasibility residual every PointPerformanceBase exposes.

    methods (Abstract)

        %REQUIRED_TW  Thrust-to-weight ratio required to satisfy this
        %   condition at the given wing loading(s).
        %   WS -- wing loading W_TO/S_ref, lbf/ft^2 (scalar or array).
        %   Returns TW the same size as WS. Each concrete subclass builds this
        %   from its own governing equation (MasterEquationConstraint's
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
        %   required_TW is a LOWER bound -- this condition demands AT LEAST
        %   that much T/W at the design point's wing loading dp.WS -- so
        %   "available >= required" is the safe direction, i.e. g = required -
        %   available <= 0 is feasible. g = -margin (the negative of the old
        %   "T/W to spare" reading), per PointPerformanceBase.m's g <= 0
        %   convention.
        %
        %   BASIS: both sides sit on the sea-level-static T_SL/W_TO axis --
        %   required_TW already expresses its thrust demand there (its terms
        %   divide thrust by the condition's alpha), and available is the flat
        %   installed dp.TW = T_SL/W_TO. There is NO thrust-lapse alpha scaling
        %   here: the residual lives on the same SL-static axis the constraint
        %   diagram plots, which settles the old finding #9 (the previous
        %   alpha-scaled margin basis). Because a strictly-positive alpha is a
        %   common factor, dropping it never changes a feasibility conclusion,
        %   only the reported number.
        %
        %   [Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Both_WbyS_TbyW.compute_constraint (cell 9): TbyW_necessary =
        %   compute_TbyW(WbyS) is "Required"; TbyW_actual is "Available"; the
        %   notebook's own constraint = necessary - actual, feasible <= 0 --
        %   the identical sign this method returns.]
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
