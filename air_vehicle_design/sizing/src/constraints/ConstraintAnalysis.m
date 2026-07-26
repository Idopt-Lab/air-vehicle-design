classdef ConstraintAnalysis
%CONSTRAINTANALYSIS  Aggregates point-performance constraints into a
%   constraint diagram and reports the optimum (W/S, T/W) design point.
%
%   obj = ConstraintAnalysis(constraints, WS_range) builds the aggregator
%   from a live list of constraint conditions:
%     constraints -- 1xN cell array of PointPerformanceBase objects (e.g.
%                    ThrustConstraint, TakeoffConstraint, LandingConstraint
%                    instances). Each supplies a .name and a
%                    .required_TW(WS) method; ConstraintAnalysis calls
%                    required_TW(WS_range) on every element itself -- the
%                    physics (which aero/prop discipline objects, which
%                    flight condition) lives entirely in the constraint
%                    objects, not here.
%     WS_range    -- 1xM double, wing loading W_TO/S sweep, lbf/ft^2.
%
%   Constraints that bound W/S directly rather than requiring thrust (e.g.
%   LandingConstraint) encode that as a vertical wall: required_TW returns 0
%   at or below their limit and Inf above it (see LandingConstraint.m's
%   header). This lets every constraint, thrust-type or wing-loading-type,
%   be combined uniformly through the same max-envelope below -- no special
%   numerical handling is needed for the optimum; plot_diagram() only
%   special-cases the RENDERING of wall-type constraints (a vertical dashed
%   line rather than a curve).
%
%   Inf is therefore MEANINGFUL and is accepted; NaN is not, and is rejected
%   at construction by assertNoNaN below -- see that method for why the
%   distinction matters and why the check cannot be a plain ~isfinite.
%
%   DESIGN POINT [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed.,
%   AIAA, 2018, ch. 5 -- constraint diagram methodology: the feasible region
%   is bounded below by the upper envelope of all T/W-vs-W/S constraint
%   curves, since an aircraft must satisfy every constraint simultaneously
%   and therefore needs at least the largest T/W any one condition demands
%   (or an infeasible Inf, for a violated wall constraint) at a given W/S;
%   the design point that minimizes required engine size is the point on
%   that envelope with the smallest T/W]:
%
%     TW_envelope(WS) = max_i required_TW_i(WS)
%     [WS_opt, TW_opt] = argmin_WS TW_envelope(WS)
%
%   optimal_point() finds [WS_opt, TW_opt] by direct search over the supplied
%   WS_range (no interpolation -- resolution is set by the caller's sweep).
%   plot_diagram() draws each constraint curve plus the optimum point.
%
%   Generic Layer-1 aggregator: does not know which aircraft or fidelity
%   level produced the constraints -- see
%   sizing/docs/subplans/06_constraint_analysis.md.

    properties (SetAccess = private)
        constraints (1,:) cell
        WS_range    (1,:) double
        names       (1,:) string
        TW_table    (:,:) double
    end

    methods

        function obj = ConstraintAnalysis(constraints, WS_range)
            arguments
                constraints (1,:) cell
                WS_range    (1,:) double {mustBePositive}
            end
            for i = 1:numel(constraints)
                if ~isa(constraints{i}, 'PointPerformanceBase')
                    error('ConstraintAnalysis:InvalidConstraint', ...
                        'constraints{%d} must be a PointPerformanceBase object.', i);
                end
            end

            obj.constraints = constraints;
            obj.WS_range    = WS_range;

            obj.names = strings(1, numel(constraints));
            obj.TW_table = zeros(numel(constraints), numel(WS_range));
            for i = 1:numel(constraints)
                obj.names(i)      = constraints{i}.name;
                row               = constraints{i}.required_TW(WS_range);
                ConstraintAnalysis.assertNoNaN(row, WS_range, constraints{i}.name, i);
                obj.TW_table(i,:) = row;
            end
        end

        function [WS_opt, TW_opt] = optimal_point(obj)
        %OPTIMAL_POINT  [W/S, T/W] at the minimum of the constraint envelope.
        %   See class header for the envelope/argmin definition and citation.
            envelope     = max(obj.TW_table, [], 1);
            [TW_opt, idx] = min(envelope);
            WS_opt        = obj.WS_range(idx);
        end

        function fig = plot_diagram(obj)
        %PLOT_DIAGRAM  Draw the constraint diagram: one curve per thrust-type
        %   constraint, a vertical dashed line per wall-type (WS-bounding)
        %   constraint, plus the optimum design point -- with axis labels,
        %   legend, grid.
            [WS_opt, TW_opt] = obj.optimal_point();

            fig = figure('Name', 'Constraint Diagram');
            ax  = axes(fig);
            hold(ax, 'on');
            colors = lines(numel(obj.constraints));
            for i = 1:numel(obj.constraints)
                if ismethod(obj.constraints{i}, 'WS_max')
                    xline(ax, obj.constraints{i}.WS_max(), '--', ...
                        'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', obj.names(i));
                else
                    plot(ax, obj.WS_range, obj.TW_table(i,:), 'LineWidth', 2, ...
                        'DisplayName', obj.names(i), 'Color', colors(i,:));
                end
            end
            plot(ax, WS_opt, TW_opt, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'g', ...
                'DisplayName', sprintf('Optimum (W/S=%.1f, T/W=%.3f)', WS_opt, TW_opt));

            xlabel(ax, 'Wing Loading W_{TO}/S [lbf/ft^2]');
            ylabel(ax, 'Thrust-to-Weight Ratio T/W');
            title(ax, 'Constraint Diagram with Optimal Design Point');
            legend(ax, 'Location', 'northeastoutside');
            grid(ax, 'on');
            hold(ax, 'off');
        end

        function report(obj)
        %REPORT  Print the optimum W/S and T/W to the console.
            [WS_opt, TW_opt] = obj.optimal_point();
            fprintf('Optimum design point: W/S = %.2f lbf/ft^2, T/W = %.4f\n', WS_opt, TW_opt);
        end

    end

    methods (Static, Access = private)

        function assertNoNaN(row, WS_range, name, idx)
        %ASSERTNONAN  Reject a NaN required_TW curve at aggregation time.
        %
        %   WHY NaN AND NOT ~isfinite (added 2026-07-26). Inf is a LEGAL,
        %   documented value here: wall-type constraints encode "infeasible
        %   above my W/S limit" as Inf (class header above; LandingConstraint.m).
        %   Erroring on Inf would break every wall constraint. NaN carries no
        %   such meaning and is always a modelling failure.
        %
        %   WHY IT MUST BE CAUGHT: MATLAB's max/min OMIT NaN by default, so a
        %   NaN row silently drops out of the envelope
        %   `max(obj.TW_table, [], 1)` -- the aggregate reads as if that
        %   condition had never been supplied, and optimal_point() returns a
        %   design point that satisfies one fewer constraint than the caller
        %   asked for, with no warning. That is the same "unevaluable reads as
        %   satisfied" failure mode Both_WbyS_TbyW.required_TW guards against;
        %   this is the second layer, at the one place every constraint TYPE
        %   (thrust, wall, takeoff, landing) funnels through -- including the
        %   ones that never route through the Master Equation and so never see
        %   the Both_WbyS_TbyW check at all.
            bad = isnan(row);
            if any(bad)
                first = find(bad, 1);
                error('ConstraintAnalysis:nanConstraintCurve', ...
                    ['Constraint "%s" (constraints{%d}) returned NaN required_TW at ', ...
                     '%d of %d wing loadings (first at W/S = %g lbf/ft^2). NaN would be ', ...
                     'silently OMITTED from the max() envelope, so the design point would ', ...
                     'be computed as though this condition did not exist. Inf is the ', ...
                     'legal way to say "infeasible here" (see LandingConstraint); NaN ', ...
                     'means the condition could not be evaluated -- usually a drag polar ', ...
                     'or thrust lapse that is not modeled at this flight condition.'], ...
                    name, idx, sum(bad), numel(row), WS_range(first));
            end
        end

    end

end
