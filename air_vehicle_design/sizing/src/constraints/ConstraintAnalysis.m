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
%   obj = ConstraintAnalysis.from_requirements(aero, prop, json_path, classMap,
%   WS_range) is a convenience factory that reads the conditions from a
%   requirements JSON and builds each via a name->ConstraintType map (see that
%   method and ConstraintType); the two-arg constructor above stays the entry
%   point for a hand-built or pre-trimmed constraint list.
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

        function [WS_opt, TW_opt, info] = optimal_point_continuous(obj, x0, opts)
        %OPTIMAL_POINT_CONTINUOUS  Continuous, sweep-free refinement of
        %   optimal_point(): minimize T/W over x = [W/S, T/W] subject to every
        %   constraint's signed residual, via fmincon. Same design-point
        %   definition and citation as optimal_point [Raymer, "Aircraft
        %   Design: A Conceptual Approach," 6th ed., AIAA, 2018, ch. 5 -- the
        %   design point that minimizes required engine size is the feasible
        %   point with the smallest T/W]; where optimal_point is limited to
        %   the WS_range grid nodes, this method locates the exact envelope
        %   minimum between them.
        %
        %       min  T/W                       over x = [W/S, T/W]
        %       s.t. g_i = constraints{i}.constraint_residual(dp(x)) <= 0
        %            min(WS_range) <= W/S <= max(WS_range),  T/W >= TW_FLOOR
        %
        %   ALL constraints enter fmincon's nonlcon uniformly -- required_TW
        %   producers and W/S walls alike -- through the signed residual
        %   g = required - available, g <= 0 FEASIBLE, which
        %   PointPerformanceBase.m defines as exactly the fmincon nonlcon
        %   sign convention. No max-envelope is formed here; fmincon sees
        %   each condition as its own smooth inequality.
        %
        %   dp(x): DesignPoint's constructor takes physical (W_TO, T_SL,
        %   S_ref), but every category's constraint_residual reads dp only
        %   through the dimensionless dp.WS and dp.TW (see Only_WbyS.m,
        %   Both_WbyS_TbyW.m, Only_TbyW.m -- each documents which of the two
        %   it uses), so the absolute scale is arbitrary: a unit-weight point
        %   W_TO = 1 lbf, T_SL = T/W, S_ref = 1/(W/S) reproduces any
        %   (W/S, T/W) exactly.
        %
        %   x0   -- optional (1,2) seed [W/S, T/W]. Omitted or empty: seeded
        %           from obj.optimal_point(), the grid argmin -- a robust
        %           global seed, since the grid search cannot be trapped in a
        %           local basin. Callers like the sizing loop pass the
        %           previous iterate to warm-start.
        %   opts -- name-value options; Display (default "none") is passed
        %           through to fmincon.
        %
        %   Algorithm 'sqp' because the residuals are smooth closed-form
        %   curves, the problem is small and dense (2 variables, a handful of
        %   constraints), and sqp is robust to the seed lying ON the
        %   constraint envelope -- the grid-argmin seed always does.
        %
        %   SCALING (essential, 2026-08-14 fix): fmincon works on
        %   z = [W/S / WS_s, T/W / TW_s] with WS_s, TW_s taken from the seed,
        %   not on [W/S, T/W] directly. Near the envelope minimum the
        %   residual's W/S-gradient vanishes by definition, so in raw units
        %   the Lagrangian curvature is O(TW/WS^2) ~ 1e-5 and sqp's
        %   BFGS/identity Hessian produces steps of that same tiny order --
        %   the solver stalls at the seed (observed: 97 -> 97.00006 on a toy
        %   whose true optimum is 100). In seed-normalized variables the
        %   curvature is O(TW) ~ 0.1-1 and sqp converges in a few
        %   iterations. Central finite differences for the same
        %   shallow-envelope accuracy reason.
        %
        %   Returns WS_opt, TW_opt plus an info struct: exitflag, iterations,
        %   funcCount (from fmincon's output), the final residual vector g in
        %   constraint order, and the near-active mask |g| < ACTIVE_TOL with
        %   the matching constraint names (which constraints bind). Errors
        %   with identifier ConstraintAnalysis:optimalPointContinuousInfeasible
        %   if exitflag <= 0 -- never returns a silent bad point -- and
        %   errors up front if fmincon (Optimization Toolbox) is absent.
        %   Recompute-on-read like the rest of the class (see header):
        %   nothing is cached; every call re-reads the live constraint
        %   objects, so a mutated aero/prop shows up immediately.
        %
        %   Added 2026-08-13 (user-directed): continuous, sweep-free
        %   refinement of optimal_point(); realizes docs/ToDo_Darshan.md
        %   item 2.
            arguments
                obj (1,1) ConstraintAnalysis
                x0 double {mustBeReal, mustBeFinite, mustBeNonnegative} = []
                opts.Display (1,1) string = "none"
            end
            if ~exist('fmincon', 'file')
                error('ConstraintAnalysis:optimizationToolboxRequired', ...
                    ['optimal_point_continuous requires fmincon ', ...
                     '(Optimization Toolbox), which is not on the MATLAB path.']);
            end
            if isempty(x0)
                [WS_seed, TW_seed] = obj.optimal_point();
                if isempty(WS_seed) || isempty(TW_seed)
                    % Grid seed found no feasible node (all WS_range above the
                    % tightest wall, or no producers): fail loudly here rather
                    % than inside reshape with an unrelated identifier.
                    error('ConstraintAnalysis:optimalPointContinuousInfeasible', ...
                        ['optimal_point() found no feasible grid node to seed ', ...
                         'from (empty feasible set on WS_range).']);
                end
                x0 = [WS_seed, TW_seed];
            elseif numel(x0) ~= 2
                error('ConstraintAnalysis:invalidSeed', ...
                    'x0 must be a 2-element [W/S, T/W] seed; got %d element(s).', ...
                    numel(x0));
            end
            x0 = reshape(x0, 1, 2);

            % T/W floor: strictly positive (not 0) because DesignPoint
            % requires T_SL > 0 (mustBePositive), and sqp honors bounds at
            % every iterate, so make_dp is never handed T/W = 0.
            TW_FLOOR   = 1e-6;   % dimensionless T/W lower bound
            ACTIVE_TOL = 1e-6;   % |g| below this counts as a binding constraint

            % Seed-normalized variables z = x ./ s -- see SCALING note in the
            % header. The seed is feasible and positive, so s is a valid
            % characteristic scale for both variables.
            s = [x0(1), max(x0(2), TW_FLOOR)];

            % Unit-weight DesignPoint reproducing (W/S, T/W) -- see header.
            make_dp   = @(x) DesignPoint(1, x(2), 1 / x(1));
            residuals = @(dp) cellfun(@(con) con.constraint_residual(dp), ...
                obj.constraints);
            nonlcon   = @(z) deal(residuals(make_dp(z .* s)), []);
            objective = @(z) z(2);   % minimize T/W (scale factor s(2) > 0 drops
                                     % out of the argmin) [Raymer ch. 5]

            lb = [min(obj.WS_range), TW_FLOOR] ./ s;
            ub = [max(obj.WS_range), Inf] ./ s;

            fmincon_opts = optimoptions('fmincon', 'Algorithm', 'sqp', ...
                'Display', opts.Display, ...
                'FiniteDifferenceType', 'central', ...  % shallow-envelope accuracy
                'OptimalityTolerance', 1e-8, ...
                'StepTolerance', 1e-12, ...
                'MaxIterations', 500);
            [z_opt, ~, exitflag, output] = fmincon(objective, x0 ./ s, ...
                [], [], [], [], lb, ub, nonlcon, fmincon_opts);
            x_opt = z_opt .* s;

            if exitflag <= 0
                error('ConstraintAnalysis:optimalPointContinuousInfeasible', ...
                    ['fmincon did not converge to a feasible design point ', ...
                     '(exitflag = %d): %s'], exitflag, output.message);
            end

            WS_opt = x_opt(1);
            TW_opt = x_opt(2);

            g_final     = residuals(make_dp(x_opt));   % 1 x n, constraint order
            names       = obj.constraint_names();
            active_mask = abs(g_final) < ACTIVE_TOL;
            info = struct( ...
                'exitflag',     exitflag, ...
                'iterations',   output.iterations, ...
                'funcCount',    output.funcCount, ...
                'residuals',    g_final, ...
                'active_mask',  active_mask, ...
                'active_names', names(active_mask));
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

    methods (Static)

        function obj = from_requirements(aero, prop, json_path, classMap, WS_range)
        %FROM_REQUIREMENTS  Build a ConstraintAnalysis directly from a
        %   requirements JSON plus a condition-name -> ConstraintType map,
        %   wiring the injected aero/prop into every constraint.
        %
        %   aero, prop -- the discipline objects injected into each constraint
        %                 (dependency injection; typically handle objects a
        %                 sizing loop mutates in place, so each constraint's
        %                 next read tracks the current design -- see the class
        %                 header "RECOMPUTE-ON-READ").
        %   json_path  -- requirements JSON path (e.g. f16a_requirements_path()).
        %   classMap   -- dictionary(string -> ConstraintType). Each JSON
        %                 condition whose name is a key is built via that
        %                 ConstraintType; a condition ABSENT from the map is
        %                 intentionally excluded (this is how e.g. a Stall wall
        %                 is left out -- there is no includeStall flag). Keying
        %                 on the ConstraintType enum means only IMPLEMENTED
        %                 constraint classes can be selected.
        %   WS_range   -- wing-loading sweep handed to the aggregator.
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                json_path (1,1) string {mustBeNonzeroLengthText}
                classMap  (1,1) dictionary
                WS_range  (1,:) double {mustBePositive}
            end
            constraints = ConstraintAnalysis.build_constraints(aero, prop, json_path, classMap);
            obj = ConstraintAnalysis(constraints, WS_range);
        end

        function constraints = build_constraints(aero, prop, json_path, classMap)
        %BUILD_CONSTRAINTS  Read the requirements JSON and return the 1xN cell
        %   array of constraint objects the map selects, WITHOUT aggregating.
        %   Same selection rules as from_requirements (a condition absent from
        %   the map is excluded); exposed for callers that want to inspect or
        %   trim the list before handing it to the plain
        %   ConstraintAnalysis(constraints, WS_range) constructor. A map key
        %   that names no JSON condition errors -- a typo guard, since a
        %   mistyped key would otherwise silently select nothing.
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                json_path (1,1) string {mustBeNonzeroLengthText}
                classMap  (1,1) dictionary
            end
            cond      = ConstraintSetImporter.read_conditions(json_path);
            condNames = arrayfun(@(c) string(c.name), cond);

            mapKeys = keys(classMap);
            unknown = mapKeys(~ismember(mapKeys, condNames));
            if ~isempty(unknown)
                error('ConstraintAnalysis:mapKeyNotInRequirements', ...
                    ['classMap names condition(s) not present in the ', ...
                     'requirements JSON "%s": %s. Every map key must match a ', ...
                     'condition name in the JSON.'], ...
                    json_path, strjoin(unknown, ', '));
            end

            constraints = cell(1, 0);
            for i = 1:numel(cond)
                nm = string(cond(i).name);
                if isKey(classMap, nm)
                    ct = classMap(nm);
                    constraints{end+1} = ct.build(cond(i), aero, prop); %#ok<AGROW>
                end
            end
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
