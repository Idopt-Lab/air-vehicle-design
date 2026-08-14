classdef TSDiagram < handle
%TSDIAGRAM  Dimensional T-S (thrust vs. wing area) sizing diagram.
%
%   [docs/reference_extracts/metabook_data.md -- Ch. 4, "S4.12 T-S Plot
%   and Objective Function Contours": every point of a T-S plot is a SIZED
%   aircraft with a converged weight estimate; the T/W-vs-W/S constraint
%   equations are reused with iteration to place each constraint in
%   dimensional (T, S) space, and objective contours (fuel burn) are then
%   superimposed. Algorithm 2 converges TOGW at a prescribed (T, S);
%   Algorithm 4 traces each constraint as a T(S) curve; Fig. 4.7 shows the
%   resulting plot with the feasible region shaded and the actual aircraft
%   marked.]
%
%   Injected with the same seven-object stack as SizingLoopL2. SIDE
%   EFFECTS: converge_W0 (and everything built on it) mutates the shared
%   geom/prop/wts objects in place -- after any call they hold the state
%   of the LAST (T, S) cell evaluated, not a design point. Use fresh
%   objects, or re-run a sizing loop, when the diagram scan is done.
%
%   NaN CONVENTION: an infeasible or unconverged (T, S) cell is marked
%   NaN, never an error, so grid scans over aggressive ranges complete and
%   the plot simply leaves those cells blank.

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
        % Per-stack tuning knobs for the INNER TOGW closure (added
        % 2026-08-14). converge_W0's opts default to these, so every grid/
        % curve method inherits them without per-call plumbing. Stacks with
        % a large fixed-OEW content have a steep closure-map slope and need
        % a smaller relaxation -- see SizingSteps.relax's RELAXATION CHOICE
        % note (Brandt F-16A: slope ~= -2.9 -> relax_W0 ~= 0.25).
        relax_W0    (1,1) double {mustBeInRange(relax_W0, 0, 1, "exclude-lower")} = 0.5
        max_iter_W0 (1,1) double {mustBePositive, mustBeInteger} = 200
    end

    properties (Access = private)
        % Warm start for converge_W0: the last converged W0. A neighboring
        % (T, S) cell converges to a nearby weight, so seeding from the
        % last success cuts iterations across a grid scan. NaN until the
        % first success.
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
        %   [metabook S4.12 Algorithm 2: prescribe T and S, then iterate
        %   the TOGW closure to convergence. The fuel fraction is a
        %   function of S because the wing size changes the wetted area
        %   and so CD0 (metabook Eq. 4.58) -- this framework gets that
        %   coupling automatically, because geom.S_ref feeds the aero
        %   object's CD0 live and the mission re-reads it every call.]
        %
        %   Writes geom.S_ref, tail areas (once per call -- they depend on
        %   S_ref, not W0), and prop.T_SL, then runs the same TOGW fixed
        %   point as SizingLoopL1's inner loop (SizingSteps.togw_update /
        %   SizingSteps.relax).
        %
        %   Returns NaN -- NEVER errors -- when the closure denominator
        %   goes non-positive, W0 exceeds opts.W0_cap, a discipline
        %   returns a non-finite weight OR THROWS at the cell's state
        %   (warned, not silent -- e.g. a mission segment hitting negative
        %   fuel at an extreme cell), or max_iter is hit. NaN marks an
        %   infeasible (T, S) cell.
        %
        %   opts.W0_guess   -- lbf. Default: last converged W0 (warm
        %                      start), else W_payload/0.1 (a ~10% payload
        %                      fraction seed heuristic; seed only, the
        %                      converged value does not depend on it).
        %   opts.tol_rel    -- relative tolerance. Default 1e-6 [metabook
        %                      Algorithm 2 uses eps = 1e-6].
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
            if ~isnan(opts.W0_guess)
                W0 = opts.W0_guess;
            elseif ~isnan(obj.last_W0_)
                W0 = obj.last_W0_;
            else
                W0 = W_payload / 0.1;   % seed heuristic (see help above)
            end

            shrink_left = 12;    % seed-path recovery budget (see loop note)
            SHRINK      = 0.7;   % W0 pull-back factor per recovery step
            for iter = 1:opts.max_iter
                if isprop(obj.geom, 'W_TO')
                    % Guarded write, as in SizingLoopL1: L1 regression
                    % geometries carry W_TO as a state variable.
                    obj.geom.W_TO = W0;
                end
                % SEED-PATH RECOVERY (added 2026-08-14). The W0 iterates can
                % transit ABOVE the mission-flyable weight band on the way
                % down from a high seed -- at a transient W0 the mission
                % demands more fuel than the aircraft holds (a landing/climb
                % segment sees a negative weight and throws), or the closure
                % denominator goes non-positive -- even though the FIXED
                % POINT below is perfectly feasible (measured: Max Alt curve
                % cells failing at transient W0 ~ 42,700 whose fixed point is
                % ~30,000). Fuel fraction rises with W0 at fixed (T, S), so
                % the recovery is to SHRINK W0 back into the flyable band and
                % continue; only when the shrink budget is exhausted is the
                % cell truly infeasible -> NaN (warned, never silent).
                blew_up = false;
                try
                    [W_fuel, ~] = obj.miss.total_fuel(W0);
                    W_OEW = obj.wts.OEW(W0);
                    if ~(isfinite(W_fuel) && isfinite(W_OEW))
                        blew_up = true;
                        de_msg = 'non-finite mission fuel or OEW';
                    end
                catch de
                    blew_up = true;
                    de_msg = de.message;
                end
                if blew_up
                    if shrink_left > 0
                        shrink_left = shrink_left - 1;
                        W0 = max(W0 * SHRINK, W_payload * 1.05);
                        continue;
                    end
                    warning('TSDiagram:cellDisciplineError', ...
                        'converge_W0(T=%.6g, S=%.6g) at W0=%.6g: %s -> cell marked NaN (shrink budget exhausted).', ...
                        T_SL, S_ref, W0, de_msg);
                    W0 = NaN;
                    return;
                end
                obj.wts.W_TO     = W0;
                obj.wts.W_energy = W_fuel;

                % TOGW closure step [metabook Algorithm 2 / Algorithm 1;
                % Raymer 6th ed. Eq. 3.4].
                [W0_new, ~] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);
                if isnan(W0_new)
                    % denom <= 0 at THIS W0 (ff + ef >= 1) -- same too-high-
                    % transient symptom; shrink before giving up.
                    if shrink_left > 0
                        shrink_left = shrink_left - 1;
                        W0 = max(W0 * SHRINK, W_payload * 1.05);
                        continue;
                    end
                    W0 = NaN;   % closure infeasible at every tried W0
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
        %   [metabook S4.12: "Each point of the resulting T-S plot
        %   corresponds to a sized aircraft with a converged weight
        %   estimate; objective contours (fuel burn, DOC) can then be
        %   superimposed."]
        %
        %   Returns struct('T_grid', 'S_grid', 'W0', 'W_fuel', 'feasible')
        %   with W0/W_fuel as numel(T_grid) x numel(S_grid) matrices (NaN at
        %   unsized cells) and feasible as the logical CELL-WISE constraint
        %   check: at each SIZED cell the residual of EVERY constraint is
        %   evaluated at that cell's own converged design point
        %   DesignPoint(W0, T, S) (g <= 0 feasible,
        %   PointPerformanceBase convention). Cell-wise evaluation is
        %   deliberate (2026-08-14): deriving feasibility from the traced
        %   constraint_curve lines breaks when a curve point legitimately
        %   does not exist (its boundary aircraft cannot fly the design
        %   mission -- e.g. the takeoff boundary at large S), which would
        %   wrongly poison every cell in that column.
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
        %                  result; must match the grids exactly. Avoids
        %                  recomputing the whole mesh when the caller
        %                  already ran fuel_grid for its own export.
        %
        %   Feasible-region mask: fuel_grid's cell-wise constraint check --
        %   the cell is SIZED (finite converged W0) and every constraint's
        %   signed residual at DesignPoint(W0, T, S) is <= 0. The traced
        %   curves are drawn but deliberately NOT used for the mask (see
        %   fuel_grid's header). The shading image assumes uniformly spaced
        %   grids.
        %
        %   Figure/legend conventions follow
        %   src/constraints/ConstraintAnalysis.plot_diagram.
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

            % Feasible mask: fuel_grid's CELL-WISE constraint_residual check
            % (see fuel_grid's header for why the traced curves are NOT used
            % for feasibility -- a legitimately-nonexistent curve point would
            % poison its whole column).
            if ~isfield(fg, 'feasible')
                error('TSDiagram:staleGrid', ...
                    'opts.grid lacks the feasible field; recompute it with fuel_grid.');
            end
            feasible = fg.feasible;

            fig = figure('Name', 'T-S Diagram', 'Color', 'w');
            if isprop(fig, 'Theme')
                fig.Theme = 'light';   % batch sessions inherit the desktop
            end                        % theme; force light for readable exports
            ax  = axes(fig);
            hold(ax, 'on');

            % UN-SIZED region shading (added 2026-08-14, user review): cells
            % where converge_W0 found NO converged aircraft at ANY weight --
            % for this fighter mission, the M1.6 dash drag (which grows with
            % S) exceeds the maximum available thrust below a T_min(S)
            % boundary. Constraint curves and fuel contours CANNOT exist
            % there; shading it gray makes their termination self-
            % explanatory instead of looking like missing data.
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

            % Feasible-region shading: a flat LIGHT-BLUE image with per-cell
            % transparency [metabook Figs. 4.6/4.7 shade the feasible design
            % space blue]; sized-but-constraint-infeasible cells stay white.
            blue = cat(3, ...
                0.55 * ones(numel(T_grid), numel(S_grid)), ...
                0.70 * ones(numel(T_grid), numel(S_grid)), ...
                0.95 * ones(numel(T_grid), numel(S_grid)));
            % NOTE: image() objects do not accept DisplayName; exclude the
            % shading from the legend (HandleVisibility) and label it via an
            % invisible patch proxy instead.
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

            % Fuel-burn objective contours [S4.12], drawn ONLY over the
            % FEASIBLE region (2026-08-14, user review). Two reasons: (1) a
            % design point is only ever read inside the feasible region, and
            % (2) sized-but-infeasible cells near the mission-flyability
            % boundary have fuel burn that blows up smoothly (dash 1 - D/T ->
            % 0) up to ~1.5x the feasible max, so contouring the full field
            % bunches levels at the boundary and fragments the lines. Masking
            % to the feasible cells gives evenly spaced, unbroken contours
            % over the region that matters.
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
