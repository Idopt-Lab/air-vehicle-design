classdef TSDiagram < handle
%TSDIAGRAM  Dimensional T-S (thrust vs. wing area) sizing diagram.
%   [metabook_data.md Ch. 4 "S4.12 T-S Plot and Objective Function
%   Contours": each T-S point is a sized aircraft. Algorithm 2 converges
%   TOGW at a prescribed (T, S); Algorithm 4 traces each constraint as a
%   T(S) curve; Fig. 4.7 shades the feasible region and marks the aircraft.]
%
%   Injected with the same seven-object stack as SizingLoopL2. converge_W0
%   mutates the shared geom/prop/wts objects in place: after any call they
%   hold the LAST (T, S) cell state, not a design point.
%
%   NaN convention: an infeasible or unconverged (T, S) cell is marked NaN,
%   never an error, so a grid scan completes and leaves those cells blank.
%   History and rationale: docs/decision_log.md

    properties (SetAccess = private)
        aero    % (1,1) AerodynamicsBase
        prop    % (1,1) PropulsionBase
        wts     % (1,1) WeightsBase
        geom    % (1,1) GeometryBase
        miss    % (1,1) MissionAnalysisBase
        con     % (1,1) ConstraintAnalysis
        tail    % (1,1) TailSizingBase
    end

    properties
        % Per-stack tuning knobs for the inner TOGW closure. converge_W0's
        % opts default to these. Stacks with a large fixed-OEW content need
        % a smaller relaxation -- see SizingSteps.relax.
        relax_W0    (1,1) double {mustBeInRange(relax_W0, 0, 1, "exclude-lower")} = 0.5
        max_iter_W0 (1,1) double {mustBePositive, mustBeInteger} = 200
    end

    properties (Access = private)
        % Warm start for converge_W0: the last converged W0. NaN until the
        % first success. A neighbouring cell converges to a nearby weight.
        last_W0_ (1,1) double = NaN
    end

    methods

        function obj = TSDiagram(aero, prop, wts, geom, miss, con, tail)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                wts  (1,1) WeightsBase
                geom (1,1) GeometryBase
                miss (1,1) MissionAnalysisBase
                con  (1,1) ConstraintAnalysis
                tail (1,1) TailSizingBase
            end
            obj.aero = aero;
            obj.prop = prop;
            obj.wts  = wts;
            obj.geom = geom;
            obj.miss = miss;
            obj.con  = con;
            obj.tail = tail;
        end

        function W0 = converge_W0(obj, T_SL, S_ref, opts)
        %CONVERGE_W0  Converged TOGW [lbf] at a prescribed (T_SL, S_ref).
        %   [metabook S4.12 Algorithm 2: prescribe T and S, iterate the
        %   TOGW closure to convergence. Fuel fraction depends on S through
        %   the wetted area and CD0 (metabook Eq. 4.58); geom.S_ref feeds
        %   the aero CD0 live and the mission re-reads it each call.]
        %
        %   Writes geom.S_ref, tail areas, and prop.T_SL, then runs the same
        %   TOGW fixed point as SizingLoopL1 (SizingSteps.togw_update/relax).
        %
        %   Returns NaN -- never errors -- for an infeasible (T, S) cell:
        %   non-positive closure denominator, W0 past opts.W0_cap, a
        %   discipline returning non-finite or throwing (warned), or
        %   max_iter hit.
        %
        %   opts.W0_guess   -- lbf. Default: last converged W0 (warm start),
        %                      else W_payload/0.1 (~10% payload fraction).
        %   opts.tol_rel    -- relative tolerance. Default 1e-6 [Algorithm 2].
        %   opts.max_iter   -- maximum iterations. Default 200.
        %   opts.relaxation -- under-relaxation in (0,1]. Default 0.5.
        %   opts.W0_cap     -- lbf, divergence cap. Default 1e7.
            arguments
                obj
                T_SL  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                opts.W0_guess   (1,1) double = NaN
                opts.tol_rel    (1,1) double {mustBePositive} = 1e-6
                opts.max_iter   (1,1) double {mustBePositive, mustBeInteger} = obj.max_iter_W0
                opts.relaxation (1,1) double {mustBeInRange(opts.relaxation, 0, 1, "exclude-lower")} = obj.relax_W0
                opts.W0_cap     (1,1) double {mustBePositive} = 1e7
            end
            if ~isnan(opts.W0_guess) && ~(opts.W0_guess > 0)
                error('TSDiagram:badW0Guess', ...
                    'opts.W0_guess must be positive when given (got %g).', opts.W0_guess);
            end

            % Prescribe the (T, S) cell [Algorithm 2, step "prescribe"].
            obj.geom.S_ref = S_ref;
            tail_result = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, ...
                obj.geom.cbar_wing, obj.geom.L_fus);
            obj.geom.S_ht = tail_result.S_ht;
            obj.geom.S_vt = tail_result.S_vt;
            obj.prop.T_SL = T_SL;

            W_payload = obj.wts.W_payload_fixed + obj.wts.W_payload_expendable;

            % Bracketed seed selection: no single seed works for every
            % aircraft. Fighters (fixed OEW) need a seed above the fixed
            % point; transports (OEW scales with W0) need one below. Try
            % candidate seeds in order, take the first that converges:
            % explicit W0_guess, else warm-start last_W0_, else
            % W_payload/0.1 (~10% fraction, above) then /0.25 (~25%, below).
            if ~isnan(opts.W0_guess)
                seeds = opts.W0_guess;
            else
                seeds = [obj.last_W0_, W_payload / 0.1, W_payload / 0.25];
                seeds = seeds(isfinite(seeds) & seeds > 0);
            end

            W0 = NaN;
            for s = seeds
                W0 = obj.run_closure_(s, W_payload, T_SL, S_ref, opts);
                if isfinite(W0)
                    return;   % run_closure_ set obj.last_W0_ on success
                end
            end
            % Every seed failed -> the cell is infeasible. NaN, warned once.
            warning('TSDiagram:cellInfeasible', ...
                ['converge_W0(T=%.6g, S=%.6g): no converged aircraft from any ', ...
                 'seed -- cell marked NaN (mission-infeasible or diverging ', ...
                 'closure).'], T_SL, S_ref);
        end

        function list = producers(obj)
        %PRODUCERS  The required_TW producer constraints (Both_WbyS_TbyW or
        %   Only_TbyW members of obj.con.constraints), in constraint-list
        %   order. constraint_curve's k indexes THIS list.
            is_p = cellfun(@(c) isa(c, 'Both_WbyS_TbyW') || isa(c, 'Only_TbyW'), ...
                obj.con.constraints);
            list = obj.con.constraints(is_p);
        end

        function list = walls(obj)
        %WALLS  The W/S wall constraints (Only_WbyS members of
        %   obj.con.constraints), in constraint-list order. wall_curve's k
        %   indexes THIS list.
            is_w = cellfun(@(c) isa(c, 'Only_WbyS'), obj.con.constraints);
            list = obj.con.constraints(is_w);
        end

        function curve = constraint_curve(obj, k, S_grid, opts)
        %CONSTRAINT_CURVE  One producer constraint as a T(S) curve.
        %   [metabook S4.12.2 Algorithm 4: for each prescribed S, iterate
        %     W = W(S, T)                (Algorithm 2, converge_W0 here)
        %     (T/W)_new = f(W/S)         (the constraint's required_TW)
        %     T_new = (T/W)_new * W
        %   until T converges.]
        %
        %   k      -- index into obj.producers() (NOT obj.con.constraints).
        %   S_grid -- 1xN wing areas, ft^2.
        %   opts.tol_rel  -- relative tolerance on T. Default 1e-6.
        %   opts.max_iter -- maximum T iterations per S point. Default 200.
        %   opts.relax_T  -- T under-relaxation in (0,1]. Default 0.5.
        %   opts.T_init   -- lbf, thrust seed for the FIRST S point.
        %                    Default: derived from the grid design point
        %                    (T = TW*WS*S), else a payload-heuristic guess.
        %                    Later S points warm-start from the previous
        %                    converged T.
        %
        %   Returns struct('name', 'S', 'T', 'W'): T(iS)/W(iS) are NaN
        %   where the cell is infeasible or unconverged (NaN-tolerant, no
        %   error).
            arguments
                obj
                k       (1,1) double {mustBeInteger, mustBePositive}
                S_grid  (1,:) double {mustBePositive}
                opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relax_T  (1,1) double {mustBeInRange(opts.relax_T, 0, 1, "exclude-lower")} = 0.5
                opts.T_init   (1,1) double = NaN
            end
            producer_list = obj.producers();
            if k > numel(producer_list)
                error('TSDiagram:badProducerIndex', ...
                    'k = %d exceeds the number of producer constraints (%d).', ...
                    k, numel(producer_list));
            end
            if ~isnan(opts.T_init) && ~(opts.T_init > 0)
                error('TSDiagram:badTInit', ...
                    'opts.T_init must be positive when given (got %g).', opts.T_init);
            end
            c = producer_list{k};

            n_S   = numel(S_grid);
            T_vec = NaN(1, n_S);
            W_vec = NaN(1, n_S);

            T_seed = opts.T_init;
            if isnan(T_seed)
                T_seed = obj.default_T_seed(S_grid(1));
            end

            for iS = 1:n_S
                S = S_grid(iS);
                T = T_seed;
                W = NaN;
                converged_T = false;
                for it = 1:opts.max_iter
                    if ~(isfinite(T) && T > 0)
                        break;   % T iterate left the physical range
                    end
                    W = obj.converge_W0(T, S);   % [Algorithm 2]
                    if isnan(W)
                        break;   % infeasible (T, S) cell
                    end
                    % [Algorithm 4: T_new = f(W/S) * W]
                    T_new = c.required_TW(W / S) * W;
                    if ~(isfinite(T_new) && T_new > 0)
                        break;
                    end
                    if abs(T_new - T) / T_new < opts.tol_rel
                        T = T_new;
                        converged_T = true;
                        break;
                    end
                    T = SizingSteps.relax(T, T_new, opts.relax_T);
                end
                if converged_T
                    T_vec(iS) = T;
                    W_vec(iS) = W;
                    T_seed = T;   % warm start the next S point
                end
            end

            curve = struct('name', string(c.name), 'S', S_grid, 'T', T_vec, 'W', W_vec);
        end

        function wall = wall_curve(obj, k, T_grid, opts)
        %WALL_CURVE  One W/S wall constraint as an S(T) curve.
        %   [metabook S4.12.2, Algorithm 4 closing note: "For constraints
        %   that depend on W/S alone (e.g., landing field length):
        %   prescribe T, guess S, compute W, solve for S_new, and iterate
        %   until convergence. Repeat for a range of T values." Here
        %   S_new = W / WS_max, with WS_max re-read live each iterate.]
        %
        %   k      -- index into obj.walls() (NOT obj.con.constraints).
        %   T_grid -- 1xN sea-level thrusts, lbf.
        %   opts.tol_rel  -- relative tolerance on S. Default 1e-6.
        %   opts.max_iter -- maximum S iterations per T point. Default 200.
        %   opts.relax_S  -- S under-relaxation in (0,1]. Default 0.5.
        %   opts.S_init   -- ft^2, wing-area seed for the FIRST T point.
        %                    Default: payload-heuristic weight / WS_max.
        %                    Later T points warm-start from the previous
        %                    converged S.
        %
        %   Returns struct('name', 'T', 'S', 'W'): S(iT)/W(iT) are NaN
        %   where the cell is infeasible or unconverged (NaN-tolerant, no
        %   error).
            arguments
                obj
                k       (1,1) double {mustBeInteger, mustBePositive}
                T_grid  (1,:) double {mustBePositive}
                opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relax_S  (1,1) double {mustBeInRange(opts.relax_S, 0, 1, "exclude-lower")} = 0.5
                opts.S_init   (1,1) double = NaN
            end
            wall_list = obj.walls();
            if k > numel(wall_list)
                error('TSDiagram:badWallIndex', ...
                    'k = %d exceeds the number of wall constraints (%d).', ...
                    k, numel(wall_list));
            end
            if ~isnan(opts.S_init) && ~(opts.S_init > 0)
                error('TSDiagram:badSInit', ...
                    'opts.S_init must be positive when given (got %g).', opts.S_init);
            end
            c = wall_list{k};

            n_T   = numel(T_grid);
            S_vec = NaN(1, n_T);
            W_vec = NaN(1, n_T);

            S_seed = opts.S_init;
            if isnan(S_seed)
                ws0 = c.WS_max();
                if ~(isfinite(ws0) && ws0 > 0)
                    % Wall gives no usable bound at the initial state:
                    % return the all-NaN curve (NaN-tolerant contract).
                    wall = struct('name', string(c.name), 'T', T_grid, 'S', S_vec, 'W', W_vec);
                    return;
                end
                W_est = obj.last_W0_;
                if isnan(W_est)
                    % Same ~10% payload-fraction seed heuristic as
                    % converge_W0 (seed only).
                    W_est = (obj.wts.W_payload_fixed + obj.wts.W_payload_expendable) / 0.1;
                end
                S_seed = W_est / ws0;
            end

            for iT = 1:n_T
                T = T_grid(iT);
                S = S_seed;
                W = NaN;
                converged_S = false;
                for it = 1:opts.max_iter
                    if ~(isfinite(S) && S > 0)
                        break;   % S iterate left the physical range
                    end
                    W = obj.converge_W0(T, S);   % [Algorithm 2]
                    if isnan(W)
                        break;
                    end
                    % Re-read the wall live: WS_max can depend on the
                    % mutated aero/geom state (recompute-on-read).
                    ws = c.WS_max();
                    if ~(isfinite(ws) && ws > 0)
                        break;
                    end
                    S_new = W / ws;   % wing area the wall demands at this W
                    if abs(S_new - S) / S_new < opts.tol_rel
                        S = S_new;
                        converged_S = true;
                        break;
                    end
                    S = SizingSteps.relax(S, S_new, opts.relax_S);
                end
                if converged_S
                    S_vec(iT) = S;
                    W_vec(iT) = W;
                    S_seed = S;   % warm start the next T point
                end
            end

            wall = struct('name', string(c.name), 'T', T_grid, 'S', S_vec, 'W', W_vec);
        end

        function fgrid = fuel_grid(obj, T_grid, S_grid)
        %FUEL_GRID  Converged TOGW and mission fuel burn over a (T, S) mesh.
        %   [metabook S4.12: each T-S point is a sized aircraft; objective
        %   contours (fuel burn) are superimposed.]
        %
        %   Returns struct('T_grid', 'S_grid', 'W0', 'W_fuel', 'feasible').
        %   W0/W_fuel are numel(T_grid) x numel(S_grid) matrices (NaN at
        %   unsized cells). feasible is the CELL-WISE constraint check: at
        %   each sized cell every constraint residual is evaluated at that
        %   cell's own DesignPoint(W0, T, S) (g <= 0 feasible,
        %   PointPerformanceBase convention). Cell-wise, not curve-derived:
        %   a traced curve point may legitimately not exist and would
        %   otherwise poison its whole column.
            arguments
                obj
                T_grid (1,:) double {mustBePositive}
                S_grid (1,:) double {mustBePositive}
            end
            n_T = numel(T_grid);
            n_S = numel(S_grid);
            W0_mat     = NaN(n_T, n_S);
            W_fuel_mat = NaN(n_T, n_S);
            feas_mat   = false(n_T, n_S);
            G_TOL      = 1e-9;   % residual slack for exactly-on-boundary cells
            for i = 1:n_T
                for j = 1:n_S
                    w = obj.converge_W0(T_grid(i), S_grid(j));
                    if isfinite(w)
                        W0_mat(i, j) = w;
                        % converge_W0 leaves geom/prop at this cell's
                        % state, so these reads are consistent with w.
                        [wf, ~] = obj.miss.total_fuel(w);
                        W_fuel_mat(i, j) = wf;
                        dp = DesignPoint(w, T_grid(i), S_grid(j));
                        g  = cellfun(@(con) con.constraint_residual(dp), ...
                            obj.con.constraints);
                        feas_mat(i, j) = all(g <= G_TOL);
                    end
                end
            end
            fgrid = struct('T_grid', T_grid, 'S_grid', S_grid, ...
                'W0', W0_mat, 'W_fuel', W_fuel_mat, 'feasible', feas_mat);
        end

        function fig = plot(obj, opts)
        %PLOT  Draw the T-S diagram.  [metabook Fig. 4.7: constraints as
        %   curves in T (lbf) vs S (ft^2) space, feasible region shaded,
        %   fuel-burn contours superimposed (S4.12), and a marker for the
        %   actual aircraft.]
        %
        %   opts.S_grid -- 1xN wing areas, ft^2. REQUIRED (no silent
        %                  default grid).
        %   opts.T_grid -- 1xM sea-level thrusts, lbf. REQUIRED.
        %   opts.actual -- optional struct('T', lbf, 'S', ft^2, 'label',
        %                  text) marking a real aircraft [Fig. 4.7's
        %                  "Actual 777-200LR" marker precedent].
        %   opts.grid   -- optional precomputed fuel_grid(T_grid, S_grid)
        %                  result; must match the grids exactly.
        %
        %   Feasible-region mask uses fuel_grid's cell-wise constraint check,
        %   not the traced curves (see fuel_grid's header). The shading
        %   image assumes uniformly spaced grids. Figure/legend conventions
        %   follow ConstraintAnalysis.plot_diagram.
            arguments
                obj
                opts.S_grid (1,:) double {mustBePositive} = double.empty(1, 0)
                opts.T_grid (1,:) double {mustBePositive} = double.empty(1, 0)
                opts.actual struct = struct([])
                opts.grid   struct = struct([])   % precomputed fuel_grid result
            end
            if isempty(opts.S_grid) || isempty(opts.T_grid)
                error('TSDiagram:gridRequired', ...
                    'Provide opts.S_grid and opts.T_grid; there is no silent default grid.');
            end
            S_grid = opts.S_grid;
            T_grid = opts.T_grid;

            producer_list = obj.producers();
            wall_list     = obj.walls();
            n_p = numel(producer_list);
            n_w = numel(wall_list);

            curves = cell(1, n_p);
            for kk = 1:n_p
                curves{kk} = obj.constraint_curve(kk, S_grid);   % [Algorithm 4]
            end
            wall_curves = cell(1, n_w);
            for kk = 1:n_w
                wall_curves{kk} = obj.wall_curve(kk, T_grid);
            end
            if ~isempty(opts.grid)
                fg = opts.grid;
                if ~isequal(fg.S_grid(:).', S_grid) || ~isequal(fg.T_grid(:).', T_grid)
                    error('TSDiagram:gridMismatch', ...
                        'opts.grid was computed on different S/T grids than opts.S_grid/T_grid.');
                end
            else
                fg = obj.fuel_grid(T_grid, S_grid);   % [S4.12 objective contours]
            end

            % Feasible mask: fuel_grid's cell-wise constraint check.
            if ~isfield(fg, 'feasible')
                error('TSDiagram:staleGrid', ...
                    'opts.grid lacks the feasible field; recompute it with fuel_grid.');
            end
            feasible = fg.feasible;

            fig = figure('Name', 'T-S Diagram', 'Color', 'w');
            if isprop(fig, 'Theme')
                fig.Theme = 'light';   % force light for readable exports
            end
            ax  = axes(fig);
            hold(ax, 'on');

            % Un-sized region shading: cells with no converged aircraft at
            % any weight. Constraint curves and fuel contours cannot exist
            % there; gray shading makes their termination self-explanatory.
            unsized = ~isfinite(fg.W0);
            gray = cat(3, ...
                0.88 * ones(numel(T_grid), numel(S_grid)), ...
                0.88 * ones(numel(T_grid), numel(S_grid)), ...
                0.88 * ones(numel(T_grid), numel(S_grid)));
            h_gray = image(ax, 'XData', S_grid, 'YData', T_grid, 'CData', gray, ...
                'AlphaData', 0.9 * double(unsized));
            h_gray.HandleVisibility = 'off';
            patch(ax, NaN, NaN, [0.88 0.88 0.88], 'FaceAlpha', 0.9, ...
                'EdgeColor', 'none', ...
                'DisplayName', 'Mission infeasible (no sized aircraft)');

            % Feasible-region shading: a flat light-blue image with per-cell
            % transparency [metabook Figs. 4.6/4.7 shade feasible space blue];
            % sized-but-constraint-infeasible cells stay white.
            blue = cat(3, ...
                0.55 * ones(numel(T_grid), numel(S_grid)), ...
                0.70 * ones(numel(T_grid), numel(S_grid)), ...
                0.95 * ones(numel(T_grid), numel(S_grid)));
            % image() takes no DisplayName; label via an invisible patch proxy.
            h_img = image(ax, 'XData', S_grid, 'YData', T_grid, 'CData', blue, ...
                'AlphaData', 0.40 * double(feasible));
            h_img.HandleVisibility = 'off';
            patch(ax, NaN, NaN, [0.55 0.70 0.95], 'FaceAlpha', 0.40, ...
                'EdgeColor', 'none', 'DisplayName', 'Feasible region (sized aircraft)');
            set(ax, 'YDir', 'normal');   % keep thrust increasing upward

            colors = lines(n_p + n_w);
            for kk = 1:n_p
                plot(ax, S_grid, curves{kk}.T, 'LineWidth', 2, ...
                    'Color', colors(kk, :), 'DisplayName', curves{kk}.name);
            end
            for kk = 1:n_w
                plot(ax, wall_curves{kk}.S, T_grid, '--', 'LineWidth', 2, ...
                    'Color', colors(n_p + kk, :), 'DisplayName', wall_curves{kk}.name);
            end

            % Fuel-burn objective contours [S4.12], drawn only over the
            % feasible region: masking to feasible cells gives evenly spaced,
            % unbroken contours (the full field bunches levels at the
            % mission-flyability boundary where fuel burn blows up).
            if any(fg.feasible, 'all')
                wf_masked = fg.W_fuel;
                wf_masked(~fg.feasible) = NaN;     % contour skips NaN cells
                wf_feas = fg.W_fuel(fg.feasible);
                levels  = linspace(min(wf_feas), max(wf_feas), 10);
                contour(ax, S_grid, T_grid, wf_masked, levels, 'ShowText', 'on', ...
                    'LineColor', [0.20 0.20 0.20], 'LineWidth', 0.75, ...
                    'LabelSpacing', 288, ...
                    'DisplayName', 'Fuel burn W_{fuel} [lbf], feasible region');
            end

            % Optional actual-aircraft marker [Fig. 4.7 precedent].
            if ~isempty(opts.actual)
                a = opts.actual;
                if ~isfield(a, 'T') || ~isfield(a, 'S')
                    error('TSDiagram:badActual', ...
                        'opts.actual must carry fields T [lbf] and S [ft^2].');
                end
                lbl = "Actual aircraft";
                if isfield(a, 'label') && strlength(string(a.label)) > 0
                    lbl = string(a.label);
                end
                plot(ax, a.S, a.T, 'kp', 'MarkerSize', 16, 'LineWidth', 1.0, ...
                    'MarkerFaceColor', [0.95 0.75 0.10], 'DisplayName', lbl);
            end

            xlabel(ax, 'Wing Area S [ft^2]');
            ylabel(ax, 'Sea-Level Thrust T_{SL} [lbf]');
            title(ax, 'T-S Sizing Diagram');
            legend(ax, 'Location', 'northeastoutside');
            grid(ax, 'on');
            xlim(ax, [min(S_grid), max(S_grid)]);
            ylim(ax, [min(T_grid), max(T_grid)]);
            hold(ax, 'off');
        end

    end

    methods (Access = private)

        function W0 = run_closure_(obj, W0_seed, W_payload, T_SL, S_ref, opts) %#ok<INUSD>
        %RUN_CLOSURE_  One TOGW fixed-point solve [metabook Algorithm 2] from
        %   a single seed. Returns the converged W0, or NaN (silently --
        %   converge_W0 warns once) when the seed diverges past W0_cap, hits
        %   an infeasible transient recovery cannot escape, or exhausts
        %   max_iter. Sets obj.last_W0_ on success.
            W0 = W0_seed;
            shrink_left = 12;    % seed-path recovery budget
            SHRINK      = 0.7;   % W0 pull-back factor per recovery step
            for iter = 1:opts.max_iter
                if isprop(obj.geom, 'W_TO')
                    % Guarded write: L1 regression geometries carry W_TO.
                    obj.geom.W_TO = W0;
                end
                % Seed-path recovery: a W0 iterate can transit above the
                % mission-flyable band even though a feasible fixed point
                % exists lower down. Shrink W0 back and continue; give up to
                % NaN only when the shrink budget is spent.
                blew_up = false;
                try
                    [W_fuel, ~] = obj.miss.total_fuel(W0);
                    W_OEW = obj.wts.OEW(W0);
                    if ~(isfinite(W_fuel) && isfinite(W_OEW))
                        blew_up = true;
                    end
                catch
                    blew_up = true;
                end
                if blew_up
                    if shrink_left > 0
                        shrink_left = shrink_left - 1;
                        W0 = max(W0 * SHRINK, W_payload * 1.05);
                        continue;
                    end
                    W0 = NaN;
                    return;
                end
                obj.wts.W_TO     = W0;
                obj.wts.W_energy = W_fuel;

                % TOGW closure step [metabook Algorithm 1; Raymer 6th ed.
                % Eq. 3.4].
                [W0_new, ~] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);
                if isnan(W0_new)
                    % denom <= 0 (ff + ef >= 1) -- shrink before giving up.
                    if shrink_left > 0
                        shrink_left = shrink_left - 1;
                        W0 = max(W0 * SHRINK, W_payload * 1.05);
                        continue;
                    end
                    W0 = NaN;
                    return;
                end
                if W0_new > opts.W0_cap
                    W0 = NaN;   % diverging upward
                    return;
                end
                if abs(W0_new - W0) / W0_new < opts.tol_rel
                    W0 = W0_new;
                    obj.last_W0_ = W0;   % warm start for the next cell
                    return;
                end
                W0 = SizingSteps.relax(W0, W0_new, opts.relaxation);
                if W0 > opts.W0_cap
                    W0 = NaN;
                    return;
                end
            end
            W0 = NaN;   % max_iter hit without convergence
        end

        function T = default_T_seed(obj, S_first)
        %DEFAULT_T_SEED  Thrust seed for constraint_curve's first S point.
        %   Prefers the grid design point: T = TW*(W/S)*S at the first S.
        %   Falls back to T/W = 0.5 at the payload-heuristic weight when
        %   the grid design point is unavailable (e.g. empty feasible
        %   set). Seed only; the converged curve does not depend on it.
            T = NaN;
            try
                [WS0, TW0] = obj.con.optimal_point();
                T = TW0 * WS0 * S_first;
            catch
                % fall through to the heuristic below
            end
            % isscalar guards an empty return from a degenerate grid
            % optimal_point (empty feasible set).
            if ~(isscalar(T) && isfinite(T) && T > 0)
                W_est = (obj.wts.W_payload_fixed + obj.wts.W_payload_expendable) / 0.1;
                T = 0.5 * W_est;
            end
        end

    end

end
