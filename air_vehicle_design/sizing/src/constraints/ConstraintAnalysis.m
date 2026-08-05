classdef ConstraintAnalysis
%CONSTRAINTANALYSIS  Aggregates point-performance constraints into a
%   constraint diagram and reports the optimum (W/S, T/W) design point.
%
%   obj = ConstraintAnalysis(constraints, WS_range) builds the aggregator from
%   a live list of constraint conditions:
%     constraints -- 1xN cell array of PointPerformanceBase objects. They
%                    split into two kinds:
%                    (1) required_TW PRODUCERS -- anything not an Only_WbyS
%                        (MasterEquationConstraint specializations,
%                        TakeoffConstraint, Only_TbyW): each supplies a
%                        required_TW(WS) curve the diagram plots and the
%                        max-envelope combines.
%                    (2) W/S WALLS -- Only_WbyS conditions (Landing, Stall):
%                        each supplies a WS_max() upper bound and no thrust
%                        demand; the aggregator treats it as a vertical wall.
%                    The physics lives in the constraint objects, not here.
%     WS_range    -- 1xM double, wing loading W_TO/S sweep, lbf/ft^2.
%
%   DESIGN POINT [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed.,
%   AIAA, 2018, ch. 5 -- constraint-diagram methodology: the feasible region
%   is bounded below by the upper envelope of all T/W-vs-W/S constraint curves
%   (an aircraft must satisfy every constraint at once, so it needs at least
%   the largest T/W any one condition demands at a given W/S) and on the right
%   by the tightest W/S wall; the design point that minimizes required engine
%   size is the point on that envelope with the smallest T/W in the feasible
%   W/S band]:
%
%     TW_envelope(WS) = max_i required_TW_i(WS)              (producers only)
%     WS_feasible     = { WS in WS_range : WS <= min_j WS_max_j }   (walls)
%     [WS_opt, TW_opt] = argmin_{WS in WS_feasible} TW_envelope(WS)
%
%   optimal_point() finds [WS_opt, TW_opt] by direct grid search over the
%   feasible part of WS_range (no interpolation; resolution is the caller's).
%   envelope() exposes TW_envelope(WS) over the full WS_range and is the
%   reusable helper the other reads call. plot_diagram() draws each producer
%   curve, each wall as a vertical line, the shaded feasible region, and the
%   optimum.
%
%   RECOMPUTE-ON-READ. This class stores only the inputs (the constraint list
%   and the sweep); it caches no rows/envelope. Every public read rebuilds the
%   rows live from the constraint objects, matching the project's inputs-vs-
%   Dependent philosophy (CLAUDE.md, F16GeomL2.m): the sizing loop mutates the
%   injected aero/prop objects in place, so a cached table would go stale the
%   instant a design variable changed. The formulas are cheap, so
%   recompute-on-read costs nothing measurable and removes the staleness bug by
%   construction. producer_rows()/min_wall() are the shared private helpers.
%
%   Generic Layer-1 aggregator: does not know which aircraft or fidelity level
%   produced the constraints.

    properties (SetAccess = private)
        constraints (1,:) cell
        WS_range    (1,:) double
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
        end

        function env = envelope(obj)
        %ENVELOPE  Upper envelope TW_envelope(WS) = max_i required_TW_i(WS)
        %   over the producers only, recomputed live over the full WS_range
        %   (the wall restriction is applied in optimal_point). Exposed
        %   publicly so fidelity-overlay callers can plot it directly. Returns
        %   -Inf at every W/S if there are no producers (walls only).
            TW_table = obj.producer_rows();
            if isempty(TW_table)
                env = -Inf(1, numel(obj.WS_range));
            else
                env = max(TW_table, [], 1);
            end
        end

        function [WS_opt, TW_opt] = optimal_point(obj)
        %OPTIMAL_POINT  [W/S, T/W] at the minimum of the constraint envelope,
        %   restricted to W/S at or below the tightest wall. Grid argmin over
        %   the feasible part of WS_range (no continuous optimizer -- the sweep
        %   resolution is the caller's choice). See class header for the
        %   envelope/wall/argmin definition, the recompute-on-read note, and
        %   the citation.
            env      = obj.envelope();
            wall_min = obj.min_wall();

            feasible = obj.WS_range <= wall_min;
            [TW_opt, local_idx] = min(env(feasible));
            feasible_WS = obj.WS_range(feasible);
            WS_opt      = feasible_WS(local_idx);
        end

        function fig = plot_diagram(obj)
        %PLOT_DIAGRAM  Draw the constraint diagram: shaded feasible region, one
        %   curve per required_TW producer, a vertical dashed line per wall
        %   constraint, plus the optimum design point, with axis labels,
        %   legend, grid. The shading fills between the producer envelope and a
        %   fixed ceiling only for W/S at or below the tightest wall, so it
        %   highlights the feasible region (Raymer ch. 5) and stops at the wall.
            TW_table = obj.producer_rows();
            env      = obj.envelope();
            wall_min = obj.min_wall();
            [WS_opt, TW_opt] = obj.optimal_point();

            names = obj.constraint_names();

            finite_env = env(isfinite(env));
            if isempty(finite_env)
                y_max = 1.15 * max([TW_opt, 1]);
            else
                y_max = 1.15 * max([TW_opt, finite_env]);
            end
            env_capped = min(env, y_max);
            % Shade only where W/S is at or below the tightest wall (feasible);
            % beyond the wall, collapse the fill to zero height (top == bottom).
            left_of_wall = obj.WS_range <= wall_min;
            fill_bottom  = env_capped;
            fill_bottom(~left_of_wall) = y_max;

            fig = figure('Name', 'Constraint Diagram');
            ax  = axes(fig);
            hold(ax, 'on');

            fill(ax, [obj.WS_range, fliplr(obj.WS_range)], ...
                [fill_bottom, y_max * ones(1, numel(fill_bottom))], ...
                [0.60 0.85 0.60], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
                'DisplayName', 'Feasible region');

            colors  = lines(numel(obj.constraints));
            row_idx = 0;
            for i = 1:numel(obj.constraints)
                if isa(obj.constraints{i}, 'Only_WbyS')
                    xline(ax, obj.constraints{i}.WS_max(), '--', ...
                        'LineWidth', 2, 'Color', colors(i,:), 'DisplayName', names(i));
                else
                    row_idx = row_idx + 1;
                    plot(ax, obj.WS_range, TW_table(row_idx,:), 'LineWidth', 2, ...
                        'DisplayName', names(i), 'Color', colors(i,:));
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

        function TW_table = producer_rows(obj)
        %PRODUCER_ROWS  Build the per-constraint required_TW rows live over
        %   WS_range, for the producers only (everything not an Only_WbyS
        %   wall). Returns an (n_producers x numel(WS_range)) matrix in
        %   producer order; empty if there are none. No cached table, so a
        %   mutated discipline shows up on the next read. Each producer
        %   self-guards a non-finite required_TW, so no aggregator NaN guard is
        %   needed here.
            is_producer = ~cellfun(@(c) isa(c, 'Only_WbyS'), obj.constraints);
            producers   = obj.constraints(is_producer);
            n_p = numel(producers);
            TW_table = zeros(n_p, numel(obj.WS_range));
            for i = 1:n_p
                TW_table(i,:) = producers{i}.required_TW(obj.WS_range);
            end
        end

        function ws = min_wall(obj)
        %MIN_WALL  Tightest (smallest) W/S wall over all Only_WbyS
        %   constraints, or +Inf if there are none (no W/S ceiling). Used to
        %   restrict the optimum search and shade the feasible region.
            is_wall = cellfun(@(c) isa(c, 'Only_WbyS'), obj.constraints);
            walls   = obj.constraints(is_wall);
            if isempty(walls)
                ws = Inf;
            else
                ws = min(cellfun(@(c) c.WS_max(), walls));
            end
        end

        function names = constraint_names(obj)
        %CONSTRAINT_NAMES  Derive the constraint labels on demand from each
        %   constraint's .name property (used for the diagram legend).
            n_c = numel(obj.constraints);
            names = strings(1, n_c);
            for i = 1:n_c
                names(i) = obj.constraints{i}.name;
            end
        end

    end

end
