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
%   by assertNoNaN below (on every read, not just at construction -- see
%   "LIVE RE-EVALUATION" below) -- see that method for why the distinction
%   matters and why the check cannot be a plain ~isfinite.
%
%   LIVE RE-EVALUATION (added 2026-08-03): TW_table is a Dependent property,
%   recomputed from obj.constraints on every read, not cached from
%   construction. Each constraint's required_TW already pulls its own
%   aero/prop fresh on every call (e.g. ThrustConstraint.m reads
%   obj.aero.drag_polar(obj.state) live) -- so a caller sharing those same
%   handle objects with a live design process, e.g. SizingLoopL2 (whose
%   prop.T_SL assignment each iteration flows into F16GeomL2/L3's nacelle
%   diameter -> duct wetted area -> S_wet -> aero.CD0, per that geometry
%   class's T_AB_SLS_lb property), sees the shift reflected in the very
%   next envelope()/optimal_point()/plot_diagram() call. [see
%   F16ConstraintSet.build()'s header, "aero/prop are typically handle
%   objects mutated in place"] Before this change, TW_table was computed
%   once in the constructor and frozen, which silently defeated that
%   liveness -- optimal_point() returned the same numbers no matter how
%   often, or when, it was called. Construction still evaluates the table
%   once, purely to fail fast on a NaN constraint (assertNoNaN) before
%   handing the object back to a caller; that first evaluation's result is
%   discarded, since TW_table itself is Dependent and will recompute on the
%   caller's first real read anyway.
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
%   envelope() exposes TW_envelope(WS) directly (e.g. for fidelity-overlay
%   callers that want the envelope curve without every individual
%   constraint). plot_diagram() draws the shaded feasible region (the area
%   at/above the envelope, capped where a wall constraint makes it Inf), each
%   constraint curve, and the optimum point.
%
%   Generic Layer-1 aggregator: does not know which aircraft or fidelity
%   level produced the constraints -- see
%   sizing/docs/subplans/06_constraint_analysis.md.

    properties (SetAccess = private)
        constraints (1,:) cell
        WS_range    (1,:) double
        names       (1,:) string
    end

    properties (Dependent)
        TW_table    % (:,:) double -- recomputed live on every read; see class header "LIVE RE-EVALUATION"
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
            for i = 1:numel(constraints)
                obj.names(i) = constraints{i}.name;
            end

            obj.evaluate_table(); % fail fast on a NaN row now; result discarded (TW_table recomputes on the caller's own first read)
        end

        function table = get.TW_table(obj)
            table = obj.evaluate_table();
        end

        function env = envelope(obj)
        %ENVELOPE  Upper envelope TW_envelope(WS) = max_i required_TW_i(WS)
        %   used by both optimal_point() and plot_diagram() (feasible-region
        %   shading); exposed publicly so callers comparing fidelity levels
        %   (e.g. run_F16_constraint_diagram_overlay.m) can plot it directly
        %   without recomputing required_TW themselves.
            env = max(obj.TW_table, [], 1);
        end

        function [WS_opt, TW_opt] = optimal_point(obj)
        %OPTIMAL_POINT  [W/S, T/W] at the minimum of the constraint envelope.
        %   See class header for the envelope/argmin definition and citation.
            env           = obj.envelope();
            [TW_opt, idx] = min(env);
            WS_opt        = obj.WS_range(idx);
        end

        function fig = plot_diagram(obj)
        %PLOT_DIAGRAM  Draw the constraint diagram: shaded feasible region,
        %   one curve per thrust-type constraint, a vertical dashed line per
        %   wall-type (WS-bounding) constraint, plus the optimum design point
        %   -- with axis labels, legend, grid.
        %
        %   FEASIBLE REGION [Raymer ch. 5]: the set of (W/S, T/W) points
        %   satisfying every constraint simultaneously is bounded below by
        %   the envelope (see class header) and, where a wall constraint
        %   makes the envelope Inf, bounded on the right by that wall -- so
        %   shading the area between the envelope and a fixed ceiling
        %   (capping the wall's Inf at that ceiling) both highlights the
        %   feasible region and naturally stops the shading at the wall.
        %
        %   Reads obj.TW_table into a LOCAL variable once (rather than
        %   through obj.optimal_point()/obj.envelope(), each of which would
        %   trigger its own live recompute -- see class header "LIVE
        %   RE-EVALUATION") so every curve/marker drawn here comes from the
        %   same evaluation instant.
            tw_table      = obj.TW_table;
            env           = max(tw_table, [], 1);
            [TW_opt, idx] = min(env);
            WS_opt        = obj.WS_range(idx);
            y_max = 1.15 * max([TW_opt, env(isfinite(env))]);
            env_capped = min(env, y_max);

            fig = figure('Name', 'Constraint Diagram');
            ax  = axes(fig);
            hold(ax, 'on');

            fill(ax, [obj.WS_range, fliplr(obj.WS_range)], ...
                [env_capped, y_max * ones(1, numel(env_capped))], ...
                [0.60 0.85 0.60], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
                'DisplayName', 'Feasible region');

            colors = lines(numel(obj.constraints));
            for i = 1:numel(obj.constraints)
                if ismethod(obj.constraints{i}, 'WS_max')
                    xline(ax, obj.constraints{i}.WS_max(), '--', ...
                        'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', obj.names(i));
                else
                    plot(ax, obj.WS_range, tw_table(i,:), 'LineWidth', 2, ...
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
            ylim(ax, [0, y_max]);
            hold(ax, 'off');
        end

        function report(obj)
        %REPORT  Print the optimum W/S and T/W to the console.
            [WS_opt, TW_opt] = obj.optimal_point();
            fprintf('Optimum design point: W/S = %.2f lbf/ft^2, T/W = %.4f\n', WS_opt, TW_opt);
        end

    end

    methods (Access = private)

        function table = evaluate_table(obj)
        %EVALUATE_TABLE  Loop every constraint's required_TW(WS_range) fresh
        %   and assemble+validate the T/W table -- called by get.TW_table on
        %   every read (see class header "LIVE RE-EVALUATION") and once more
        %   at construction purely to validate the constraint set up front.
            table = zeros(numel(obj.constraints), numel(obj.WS_range));
            for i = 1:numel(obj.constraints)
                row = obj.constraints{i}.required_TW(obj.WS_range);
                ConstraintAnalysis.assertNoNaN(row, obj.WS_range, obj.names(i), i);
                table(i,:) = row;
            end
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
