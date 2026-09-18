classdef TtpaPSDiagram < handle
%TTPAPSDIAGRAM  Dimensional P-S (shaft power vs. wing area) sizing diagram.
%
%
%   A jet sizes on THRUST loading T/W, and more T/W means a bigger engine.
%   A propeller airplane sizes on POWER loading W/P, which is INVERTED -
%   a BIGGER W/P means a SMALLER engine. Three things follow.
%
%     1  The curve-tracing step flips. The framework computes
%            T_new = required_TW(W/S) * W
%        Here the constraint returns the LARGEST power loading it allows,
%        so the smallest power that meets it is
%            P_new = W / WP_max(W/S)
%
%     2  The feasible region flips to ABOVE the curves. On the IHW2
%        matching diagram the feasible region lies BELOW the W/P envelope,
%        because a small W/P is a big engine. Dividing through by W to get
%        power turns that upside down: here, more power is always allowed,
%        so feasible is above every curve and to the right of the wall.
%
%     3  The two binding constraints run in opposite directions, which is
%        what gives the diagram its shape:
%            Takeoff       W/P <= TOP23*sigma*CLmax_TO/(W/S)
%                          ->  P >= W^2 / (S * TOP23*sigma*CLmax_TO)
%                          power FALLS as the wing grows
%            Cruise speed  W/P <= (W/S)*kP/(sigma*Ip^3)
%                          ->  P >= S * sigma*Ip^3 / kP
%                          power RISES linearly with the wing
%        The least-power airplane sits where they cross. That crossing is
%        the same corner the IHW2 matching diagram finds at
%        (W/S, W/P) = (37.37, 10.50), now in dimensional form.
%
%   ------------------------------------------------------------------
%   RELATION TO sizing_loop
%
%   sizing_loop SOLVES for the design point and closes the weight on it.
%   This class does the opposite: it PRESCRIBES (P_SL, S_ref) and closes
%   the weight there, once per grid cell. The inner closure is the same
%   fixed point and uses the same SizingSteps.togw_update and
%   SizingSteps.relax, so the cell containing the sizing_loop answer
%   reproduces it.
%
%   ------------------------------------------------------------------
%   MUTATION AND NaN CONVENTION
%
%   Injected with the discipline bundle from ttpa_disciplines and MUTATES
%   IT IN PLACE: after any call, obj.geom.S_ref and obj.prop.P_SL hold the
%   LAST CELL VISITED, not a design point. Re-run sizing_loop, or write
%   them back yourself, before reading the bundle as a design.
%
%   An infeasible or unconverged cell is marked NaN, never an error, so a
%   grid scan always completes and leaves those cells blank.
%
%   See also SIZING_LOOP, SIZINGSTEPS, RUN_CONSTRAINTS, MATCHING_ENVELOPE.

    properties (SetAccess = private)
        obj     % (1,1) struct - the ttpa_disciplines bundle
    end

    properties
        % Inner-closure tuning. A stack with a large fixed empty weight has
        % a steeper closure map and needs a smaller relaxation - see
        % SizingSteps.relax. 0.5 is right for the TTPA.
        relax_W0    (1,1) double {mustBeInRange(relax_W0, 0, 1, "exclude-lower")} = 0.5
        max_iter_W0 (1,1) double {mustBePositive, mustBeInteger} = 200
    end

    properties (Access = private)
        % Warm start for converge_W0: the last converged weight. NaN until
        % the first success. A neighbouring cell closes at a nearby weight,
        % so this cuts the scan cost sharply.
        last_W0_ (1,1) double = NaN
    end

    methods

        function d = TtpaPSDiagram(obj)
            arguments
                obj (1,1) struct
            end
            d.obj = obj;
        end


        %% ---------------- One cell: close the weight ----------------

        function W0 = converge_W0(d, P_SL, S_ref, opts)
        %CONVERGE_W0  Converged takeoff weight [lbf] at a prescribed cell.
        %
        %   W0 = converge_W0(d, P_SL, S_ref)
        %
        %   [metabook S4.12 Algorithm 2: prescribe the engine and the wing,
        %   then iterate the takeoff-weight closure to convergence.]
        %
        %   Writes geom.S_ref and prop.P_SL - which resizes the tails, the
        %   nacelles and every wetted area through the Dependent properties
        %   of TtpaGeom, and moves CD0 and L/D through TtpaAero - then runs
        %   the same fixed point sizing_loop runs, with the design-point
        %   solve removed because (P, S) is given.
        %
        %   NO CONSTRAINT IS CHECKED HERE. A cell can close perfectly well
        %   at a power that fails the takeoff requirement; that is what
        %   makes the constraint curves worth drawing on top. Feasibility is
        %   a separate question, answered cell-wise in fuel_grid.
        %
        %   Returns NaN - never errors - when the cell has no sized
        %   airplane: the closure denominator goes non-positive, the weight
        %   runs past opts.W0_cap, a discipline returns non-finite, or
        %   max_iter is exhausted.
        %
        %   opts.W0_guess   -- lbf. Default: the last converged weight
        %                      (warm start), then two payload-fraction
        %                      seeds, tried in order.
        %   opts.tol_rel    -- relative tolerance. Default 1e-6.
        %   opts.max_iter   -- maximum iterations. Default d.max_iter_W0.
        %   opts.relaxation -- under-relaxation in (0,1]. Default d.relax_W0.
        %   opts.W0_cap     -- lbf, divergence cap. Default 1e6.
            arguments
                d
                P_SL  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                opts.W0_guess   (1,1) double = NaN
                opts.tol_rel    (1,1) double {mustBePositive} = 1e-6
                opts.max_iter   (1,1) double {mustBePositive, mustBeInteger} = d.max_iter_W0
                opts.relaxation (1,1) double {mustBeInRange(opts.relaxation, 0, 1, "exclude-lower")} = d.relax_W0
                opts.W0_cap     (1,1) double {mustBePositive} = 1e6
            end

            if ~isnan(opts.W0_guess) && ~(opts.W0_guess > 0)
                error('TtpaPSDiagram:badW0Guess', ...
                    'opts.W0_guess must be positive when given (got %g).', opts.W0_guess);
            end

            % Prescribe the cell. Everything downstream is Dependent, so
            % these two writes lay out a whole new airplane.
            d.obj.geom.S_ref = S_ref;
            d.obj.prop.P_SL  = P_SL;

            W_payload = d.obj.wts.payload();

            % Bracketed seeds. No single seed works over a whole grid: a
            % low-power cell closes light, a high-power cell closes heavy
            % or not at all. Try the warm start first, then a seed above
            % and a seed below, and take the first that converges.
            if ~isnan(opts.W0_guess)
                seeds = opts.W0_guess;
            else
                seeds = [d.last_W0_, W_payload / 0.23, W_payload / 0.40];
                seeds = seeds(isfinite(seeds) & seeds > 0);
            end

            W0 = NaN;
            for s = seeds
                W0 = d.run_closure_(s, W_payload, opts);
                if isfinite(W0)
                    return;    % run_closure_ has set d.last_W0_
                end
            end
            % Every seed failed. The cell has no sized airplane; leave it
            % NaN and say so once.
            warning('TtpaPSDiagram:cellInfeasible', ...
                ['converge_W0(P = %.4g hp, S = %.4g ft^2): no converged ', ...
                 'airplane from any seed - cell marked NaN. The empty weight ', ...
                 'and fuel consume the whole takeoff weight at this cell.'], ...
                P_SL, S_ref);
        end


        %% ---------------- Which condition is which ----------------

        function [idx, names] = producers(d)
        %PRODUCERS  Conditions that limit the POWER loading.
        %   Returns their indices into d.obj.cons, in file order, and their
        %   names. These become the P(S) curves. Same dispatch rule
        %   run_constraints uses: everything except the landing wall.
            [idx, names] = d.classify_("producer");
        end

        function [idx, names] = walls(d)
        %WALLS  Conditions that limit the WING loading.
        %   Returns their indices into d.obj.cons and their names. These
        %   become the S(P) curves - near-vertical walls on the diagram.
            [idx, names] = d.classify_("wall");
        end


        %% ---------------- Trace one power constraint ----------------

        function curve = constraint_curve(d, con_no, S_grid, opts)
        %CONSTRAINT_CURVE  One power constraint as a P(S) curve.
        %
        %   curve = constraint_curve(d, con_no, S_grid)
        %
        %   [metabook S4.12.2 Algorithm 4, in propeller form: at each
        %   prescribed wing area, iterate
        %       W       = W(P, S)              (Algorithm 2, converge_W0)
        %       WP_max  = f(W/S)               (the constraint itself)
        %       P_new   = W / WP_max           (the least engine that meets it)
        %   until P converges.]
        %
        %   The third line is where this differs from the jet version,
        %   which multiplies. See the class header.
        %
        %   con_no  -- index into d.obj.cons. Use producers() to get the
        %              valid ones. NOT a position in some filtered list:
        %              it is the condition number, the same one get_con
        %              takes, so it matches the requirements file.
        %   S_grid  -- 1xN wing areas [ft^2].
        %   opts.tol_rel  -- relative tolerance on P. Default 1e-6.
        %   opts.max_iter -- maximum P iterations per S point. Default 100.
        %   opts.relax_P  -- P under-relaxation in (0,1]. Default 0.5.
        %   opts.P_init   -- hp, power seed for the FIRST S point. Default:
        %                    the design point of the requirements file at
        %                    that wing area. Later points warm-start from
        %                    the previous converged P.
        %
        %   Returns struct('name','con_no','S','P','W'). P and W are NaN
        %   where the cell has no sized airplane or P did not converge.
            arguments
                d
                con_no  (1,1) double {mustBeInteger, mustBePositive}
                S_grid  (1,:) double {mustBePositive}
                opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 100
                opts.relax_P  (1,1) double {mustBeInRange(opts.relax_P, 0, 1, "exclude-lower")} = 0.5
                opts.P_init   (1,1) double = NaN
            end

            d.check_con_no_(con_no, "producer");
            restore = d.quiet_scan_();  %#ok<NASGU>  restored on exit

            con  = get_con(con_no, d.obj.cons);
            n_S  = numel(S_grid);
            P_vec = NaN(1, n_S);
            W_vec = NaN(1, n_S);

            P_seed = opts.P_init;
            if isnan(P_seed)
                P_seed = d.default_P_seed(S_grid(1));
            end

            for iS = 1:n_S
                S = S_grid(iS);
                P = P_seed;
                W = NaN;
                converged_P = false;

                for it = 1:opts.max_iter
                    if ~(isfinite(P) && P > 0)
                        break;                      % P left the physical range
                    end

                    W = d.converge_W0(P, S);        % [Algorithm 2]
                    if isnan(W)
                        break;                      % no sized airplane here
                    end

                    WP_max = d.WP_limit_(con_no, W / S);
                    if ~(isfinite(WP_max) && WP_max > 0)
                        break;
                    end

                    % PROPELLER FORM: divide, do not multiply.
                    P_new = W / WP_max;
                    if ~(isfinite(P_new) && P_new > 0)
                        break;
                    end

                    if abs(P_new - P) / P_new < opts.tol_rel
                        P = P_new;
                        converged_P = true;
                        break;
                    end
                    P = SizingSteps.relax(P, P_new, opts.relax_P);
                end

                if converged_P
                    P_vec(iS) = P;
                    W_vec(iS) = W;
                    P_seed    = P;                  % warm start the next S
                end
            end

            curve = struct('name', con.name, 'con_no', con_no, ...
                           'S', S_grid, 'P', P_vec, 'W', W_vec);
        end


        %% ---------------- Trace one wing-loading wall ----------------

        function wall = wall_curve(d, con_no, P_grid, opts)
        %WALL_CURVE  One wing-loading wall as an S(P) curve.
        %
        %   [metabook S4.12.2, Algorithm 4 closing note: for a constraint
        %   that depends on W/S alone - the landing field length - prescribe
        %   the engine, guess the wing, close the weight, then solve
        %       S_new = W / WS_max
        %   and iterate. Repeat over a range of engines.]
        %
        %   WS_max is re-read on every pass rather than cached, because it
        %   is a live read off the aerodynamic model.
        %
        %   con_no  -- index into d.obj.cons; use walls() to get it.
        %   P_grid  -- 1xM sea-level powers [hp].
        %   opts    -- tol_rel (1e-6), max_iter (100), relax_S (0.5),
        %              S_init (default: payload-heuristic weight / WS_max).
        %
        %   Returns struct('name','con_no','P','S','W'), NaN where the cell
        %   has no sized airplane.
            arguments
                d
                con_no  (1,1) double {mustBeInteger, mustBePositive}
                P_grid  (1,:) double {mustBePositive}
                opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 100
                opts.relax_S  (1,1) double {mustBeInRange(opts.relax_S, 0, 1, "exclude-lower")} = 0.5
                opts.S_init   (1,1) double = NaN
            end

            d.check_con_no_(con_no, "wall");
            restore = d.quiet_scan_();  %#ok<NASGU>

            con  = get_con(con_no, d.obj.cons);
            n_P  = numel(P_grid);
            S_vec = NaN(1, n_P);
            W_vec = NaN(1, n_P);

            S_seed = opts.S_init;
            if isnan(S_seed)
                ws0 = d.WS_wall_(con_no);
                if ~(isfinite(ws0) && ws0 > 0)
                    wall = struct('name', con.name, 'con_no', con_no, ...
                                  'P', P_grid, 'S', S_vec, 'W', W_vec);
                    return;
                end
                W_est = d.last_W0_;
                if isnan(W_est)
                    W_est = d.obj.wts.payload() / 0.23;
                end
                S_seed = W_est / ws0;
            end

            for iP = 1:n_P
                P = P_grid(iP);
                S = S_seed;
                W = NaN;
                converged_S = false;

                for it = 1:opts.max_iter
                    if ~(isfinite(S) && S > 0)
                        break;
                    end

                    W = d.converge_W0(P, S);        % [Algorithm 2]
                    if isnan(W)
                        break;
                    end

                    ws = d.WS_wall_(con_no);        % live re-read
                    if ~(isfinite(ws) && ws > 0)
                        break;
                    end

                    S_new = W / ws;                 % the wing the wall demands
                    if abs(S_new - S) / S_new < opts.tol_rel
                        S = S_new;
                        converged_S = true;
                        break;
                    end
                    S = SizingSteps.relax(S, S_new, opts.relax_S);
                end

                if converged_S
                    S_vec(iP) = S;
                    W_vec(iP) = W;
                    S_seed    = S;
                end
            end

            wall = struct('name', con.name, 'con_no', con_no, ...
                          'P', P_grid, 'S', S_vec, 'W', W_vec);
        end


        %% ---------------- The grid ----------------

        function fgrid = fuel_grid(d, P_grid, S_grid)
        %FUEL_GRID  Closed weight and mission fuel over a (P, S) mesh.
        %
        %   [metabook S4.12: every grid point is a sized airplane, and the
        %   objective - fuel burn - is contoured over them.]
        %
        %   Returns struct('P_grid','S_grid','W0','W_fuel','feasible').
        %   W0 and W_fuel are numel(P_grid) x numel(S_grid), NaN at cells
        %   with no sized airplane.
        %
        %   feasible is a CELL-WISE constraint check, not something read off
        %   the traced curves: at each sized cell the wing loading and power
        %   loading of THAT cell's own converged weight are tested against
        %   every condition,
        %
        %       W/P <= min over the power conditions of WP_max(W/S)
        %       W/S <= min over the wall conditions of WS_max
        %
        %   Cell-wise matters, because a traced curve can legitimately fail
        %   to exist at some wing areas, and reading feasibility off it
        %   would blank out a whole column that is perfectly fine.
            arguments
                d
                P_grid (1,:) double {mustBePositive}
                S_grid (1,:) double {mustBePositive}
            end

            restore = d.quiet_scan_();  %#ok<NASGU>

            n_P = numel(P_grid);
            n_S = numel(S_grid);
            W0_mat     = NaN(n_P, n_S);
            W_fuel_mat = NaN(n_P, n_S);
            feas_mat   = false(n_P, n_S);
            REL_TOL    = 1e-9;    % slack for a cell sitting exactly on a boundary

            for i = 1:n_P
                for j = 1:n_S
                    w = d.converge_W0(P_grid(i), S_grid(j));
                    if ~isfinite(w)
                        continue;
                    end
                    W0_mat(i, j) = w;

                    % converge_W0 leaves the bundle at this cell's state, so
                    % these reads are consistent with w.
                    W_fuel_mat(i, j) = mission_fuel(w, d.obj);

                    WS = w / S_grid(j);
                    WP = w / P_grid(i);
                    [WP_limits, WS_walls] = run_constraints(WS, d.obj);

                    WP_allowed = min(WP_limits(~isnan(WP_limits)));
                    WS_allowed = min(WS_walls(~isnan(WS_walls)));
                    if isempty(WS_allowed), WS_allowed = Inf; end

                    feas_mat(i, j) = (WP <= WP_allowed * (1 + REL_TOL)) ...
                                  && (WS <= WS_allowed * (1 + REL_TOL));
                end
            end

            fgrid = struct('P_grid', P_grid, 'S_grid', S_grid, ...
                'W0', W0_mat, 'W_fuel', W_fuel_mat, 'feasible', feas_mat);
        end


        %% ---------------- The diagram ----------------

        function [fig, info] = plot(d, opts)
        %PLOT  Draw the P-S sizing diagram.
        %
        %   [fig, info] = plot(d, 'S_grid', ..., 'P_grid', ...)
        %
        %   info returns the traced curves and the LEAST-POWER POINT: the
        %   lowest tip of the feasible wedge, where the Takeoff curve
        %   (falling) crosses the Cruise Speed curve (rising). That point is
        %   the dimensional twin of the corner the IHW2 matching diagram
        %   finds at (W/S, W/P) = (37.37, 10.50), and the gap between it and
        %   the marked design is the factor of safety, drawn to scale.
        %
        %   [metabook Fig. 4.7, in propeller form: constraints as curves in
        %   P (hp) against S (ft^2), the feasible region shaded, fuel-burn
        %   contours superimposed, and the sized airplane marked.]
        %
        %   opts.S_grid  -- 1xN wing areas [ft^2]. REQUIRED, no silent default.
        %   opts.P_grid  -- 1xM sea-level powers [hp]. REQUIRED.
        %   opts.markers -- optional struct array with fields P, S and label.
        %                   Use it to mark the converged design, the IHW1/IHW2
        %                   baseline, or both.
        %   opts.grid    -- optional precomputed fuel_grid result, so the mesh
        %                   is scanned once. Must match the grids exactly.
        %
        %   The shading images assume UNIFORMLY spaced grids; build them
        %   with linspace.
            arguments
                d
                opts.S_grid  (1,:) double {mustBePositive} = double.empty(1, 0)
                opts.P_grid  (1,:) double {mustBePositive} = double.empty(1, 0)
                opts.markers struct = struct([])
                opts.grid    struct = struct([])
            end

            if isempty(opts.S_grid) || isempty(opts.P_grid)
                error('TtpaPSDiagram:gridRequired', ...
                    ['Provide opts.S_grid and opts.P_grid. There is no silent ', ...
                     'default grid: the right range depends on the airplane, ', ...
                     'and a wrong one silently produces an empty diagram.']);
            end
            S_grid = opts.S_grid;
            P_grid = opts.P_grid;

            restore = d.quiet_scan_();  %#ok<NASGU>

            [p_idx, ~] = d.producers();
            [w_idx, ~] = d.walls();

            curves = cell(1, numel(p_idx));
            for kk = 1:numel(p_idx)
                curves{kk} = d.constraint_curve(p_idx(kk), S_grid);
            end
            wall_curves = cell(1, numel(w_idx));
            for kk = 1:numel(w_idx)
                wall_curves{kk} = d.wall_curve(w_idx(kk), P_grid);
            end

            if ~isempty(opts.grid)
                fg = opts.grid;
                if ~isequal(fg.S_grid(:).', S_grid) || ~isequal(fg.P_grid(:).', P_grid)
                    error('TtpaPSDiagram:gridMismatch', ...
                        'opts.grid was computed on different grids than opts.S_grid/opts.P_grid.');
                end
            else
                fg = d.fuel_grid(P_grid, S_grid);
            end
            if ~isfield(fg, 'feasible')
                error('TtpaPSDiagram:staleGrid', ...
                    'opts.grid has no feasible field; recompute it with fuel_grid.');
            end

            n_P = numel(P_grid);
            n_S = numel(S_grid);

            fig = figure('Name', 'TTPA P-S sizing diagram', 'Color', 'w', ...
                         'Position', [80 80 1100 620]);
            if isprop(fig, 'Theme')
                fig.Theme = 'light';    % force light so exports stay readable
            end
            ax = axes(fig);
            hold(ax, 'on');

            % --- no sized airplane: gray ------------------------------------
            % Cells where the weight will not close at any value. Constraint
            % curves and fuel contours cannot exist there, so shading the
            % region makes their termination self-explanatory rather than
            % looking like a plotting bug.
            %
            % For the TTPA the closure boundary sits near 1500 hp, far above
            % any sensible grid, so this region is normally EMPTY. The legend
            % entry is added only when there is something to label - a dead
            % legend entry is worse than no entry.
            unsized = ~isfinite(fg.W0);
            if any(unsized, 'all')
                gray = repmat(0.88, n_P, n_S, 3);
                h = image(ax, 'XData', S_grid, 'YData', P_grid, 'CData', gray, ...
                    'AlphaData', 0.9 * double(unsized));
                h.HandleVisibility = 'off';
                patch(ax, NaN, NaN, [0.88 0.88 0.88], 'FaceAlpha', 0.9, ...
                    'EdgeColor', 'none', ...
                    'DisplayName', 'Weight does not close (no sized airplane)');
            end

            % --- feasible: blue ---------------------------------------------
            blue = cat(3, repmat(0.55, n_P, n_S), ...
                          repmat(0.70, n_P, n_S), ...
                          repmat(0.95, n_P, n_S));
            h = image(ax, 'XData', S_grid, 'YData', P_grid, 'CData', blue, ...
                'AlphaData', 0.40 * double(fg.feasible));
            h.HandleVisibility = 'off';
            patch(ax, NaN, NaN, [0.55 0.70 0.95], 'FaceAlpha', 0.40, ...
                'EdgeColor', 'none', ...
                'DisplayName', 'Feasible region (sized airplane, meets every requirement)');
            set(ax, 'YDir', 'normal');   % keep power increasing upward

            % --- constraint curves ------------------------------------------
            colors = lines(numel(p_idx) + numel(w_idx));
            for kk = 1:numel(p_idx)
                plot(ax, curves{kk}.S, curves{kk}.P, 'LineWidth', 2, ...
                    'Color', colors(kk, :), 'DisplayName', curves{kk}.name);
            end
            for kk = 1:numel(w_idx)
                plot(ax, wall_curves{kk}.S, P_grid, '--', 'LineWidth', 2, ...
                    'Color', colors(numel(p_idx) + kk, :), ...
                    'DisplayName', wall_curves{kk}.name + " (wall)");
            end

            % --- fuel-burn contours over the feasible region ----------------
            % Masked to feasible cells on purpose: over the full field the
            % levels bunch up against the closure boundary, where fuel burn
            % runs away, and the useful detail is lost.
            if any(fg.feasible, 'all')
                wf = fg.W_fuel;
                wf(~fg.feasible) = NaN;
                wf_feas = fg.W_fuel(fg.feasible);
                % Round the levels to whole tens of pounds. linspace over the
                % raw range labels the contours 1193.8609, which is six digits
                % of precision the model does not have and cannot be read at
                % a glance.
                step   = max(10, round((max(wf_feas) - min(wf_feas)) / 8 / 10) * 10);
                levels = ceil(min(wf_feas)/step)*step : step : floor(max(wf_feas)/step)*step;
                if numel(levels) < 2
                    levels = linspace(min(wf_feas), max(wf_feas), 6);
                end
                contour(ax, S_grid, P_grid, wf, levels, 'ShowText', 'on', ...
                    'LineColor', [0.20 0.20 0.20], 'LineWidth', 0.75, ...
                    'LabelSpacing', 288, ...
                    'DisplayName', 'Mission fuel W_{fuel} [lbf], feasible region');
            end

            % --- least-power point: the tip of the wedge ---------------------
            % The envelope of the power constraints is the largest of them at
            % each wing area; its minimum, subject to the wall, is the
            % smallest engine that meets every requirement. Read off the
            % TRACED CURVES, not the shaded cells, so it does not inherit the
            % grid resolution.
            info = struct('curves', {curves}, 'wall_curves', {wall_curves}, ...
                          'least_power', struct('S', NaN, 'P', NaN, 'W', NaN));
            if ~isempty(curves)
                env = -inf(1, n_S);
                envW = NaN(1, n_S);
                for kk = 1:numel(curves)
                    take = curves{kk}.P > env;
                    env(take)  = curves{kk}.P(take);
                    envW(take) = curves{kk}.W(take);
                end
                env(~isfinite(env)) = NaN;
                % Apply the wall: at each S, the wall forbids wing areas below
                % the S it demands at that power.
                for kk = 1:numel(wall_curves)
                    wc = wall_curves{kk};
                    ok = isfinite(wc.S) & isfinite(wc.P);
                    if nnz(ok) >= 2
                        S_req = interp1(wc.P(ok), wc.S(ok), env, 'linear', 'extrap');
                        env(S_grid < S_req) = NaN;
                    end
                end
                [P_min, jmin] = min(env, [], 'omitnan');
                if isfinite(P_min)
                    info.least_power = struct('S', S_grid(jmin), 'P', P_min, ...
                                              'W', envW(jmin));
                    plot(ax, S_grid(jmin), P_min, 'k^', 'MarkerSize', 11, ...
                        'LineWidth', 1.0, 'MarkerFaceColor', [0.90 0.90 0.90], ...
                        'DisplayName', sprintf('Least-power point  (%.0f hp, %.0f ft^2)', ...
                                               P_min, S_grid(jmin)));
                end
            end

            % --- markers -----------------------------------------------------
            mk = {'p', 'o', 's', 'd'};
            fc = {[0.95 0.75 0.10], [0.20 0.70 0.35], [0.85 0.33 0.10], [0.49 0.18 0.56]};
            for m = 1:numel(opts.markers)
                a = opts.markers(m);
                if ~isfield(a, 'P') || ~isfield(a, 'S')
                    error('TtpaPSDiagram:badMarker', ...
                        'Each marker needs fields P [hp] and S [ft^2].');
                end
                lbl = "Design point";
                if isfield(a, 'label') && strlength(string(a.label)) > 0
                    lbl = string(a.label);
                end
                k = mod(m - 1, numel(mk)) + 1;
                plot(ax, a.S, a.P, ['k' mk{k}], 'MarkerSize', 14, ...
                    'LineWidth', 1.0, 'MarkerFaceColor', fc{k}, ...
                    'DisplayName', lbl);
            end

            xlabel(ax, 'Wing Reference Area  S_{ref}  [ft^2]');
            ylabel(ax, 'Sea-Level Shaft Power  P_{SL}  [hp]');
            title(ax, 'TTPA  P-S Sizing Diagram');
            legend(ax, 'Location', 'northeastoutside');
            grid(ax, 'on');
            xlim(ax, [min(S_grid), max(S_grid)]);
            ylim(ax, [min(P_grid), max(P_grid)]);
            hold(ax, 'off');
        end

    end


    methods (Access = private)

        function W0 = run_closure_(d, W0_seed, W_payload, opts)
        %RUN_CLOSURE_  One takeoff-weight fixed point from a single seed.
        %   [metabook Algorithm 2.] Returns the converged weight, or NaN
        %   (silently - converge_W0 warns once) when the seed diverges past
        %   W0_cap, hits a transient the recovery cannot escape, or runs out
        %   of iterations. Sets d.last_W0_ on success.
            W0 = W0_seed;

            % Seed-path recovery. A weight iterate can pass through a state
            % where the fractions exceed one even though a good fixed point
            % exists lower down. Pull the weight back and carry on; give up
            % only when the budget is spent.
            shrink_left = 12;
            SHRINK      = 0.7;

            for iter = 1:opts.max_iter
                blew_up = false;
                try
                    W_fuel = mission_fuel(W0, d.obj);
                    W_OEW  = d.obj.wts.OEW(W0);
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

                d.obj.wts.W_TO     = W0;
                d.obj.wts.W_energy = W_fuel;

                [W0_new, ~] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);

                if isnan(W0_new)
                    % Fractions consume the whole weight - shrink and retry.
                    if shrink_left > 0
                        shrink_left = shrink_left - 1;
                        W0 = max(W0 * SHRINK, W_payload * 1.05);
                        continue;
                    end
                    W0 = NaN;
                    return;
                end

                if W0_new > opts.W0_cap
                    W0 = NaN;      % running away upward
                    return;
                end

                if abs(W0_new - W0) / W0_new < opts.tol_rel
                    W0 = W0_new;
                    d.last_W0_ = W0;    % warm start for the next cell
                    return;
                end

                W0 = SizingSteps.relax(W0, W0_new, opts.relaxation);
                if W0 > opts.W0_cap
                    W0 = NaN;
                    return;
                end
            end

            W0 = NaN;    % max_iter without convergence
        end


        function WP = WP_limit_(d, con_no, WS)
        %WP_LIMIT_  Largest power loading condition con_no allows at WS.
        %   Goes through run_constraints rather than calling the individual
        %   constraint_* function, so the dispatch from condition TYPE to
        %   constraint FUNCTION lives in exactly one place - the same place
        %   the IHW2 matching diagram uses.
            WP_limits = run_constraints(WS, d.obj);
            WP = WP_limits(con_no, 1);
        end

        function WS = WS_wall_(d, con_no)
        %WS_WALL_  Largest wing loading wall condition con_no allows.
        %   The wall does not depend on the wing loading, so the probe value
        %   passed to run_constraints is arbitrary.
            [~, WS_walls] = run_constraints(40, d.obj);
            WS = WS_walls(con_no);
        end

        function [idx, names] = classify_(d, kind)
        %CLASSIFY_  Split the constraint set into power curves and walls.
        %   Dispatches on con.type, the same switch run_constraints uses.
            n = numel(d.obj.cons);
            keep  = false(1, n);
            names = strings(1, n);
            for k = 1:n
                con = get_con(k, d.obj.cons);
                names(k) = con.name;
                switch con.type
                    case "landing"
                        keep(k) = (kind == "wall");
                    case {"takeoff", "climb_gradient", "cruise_speed"}
                        keep(k) = (kind == "producer");
                    otherwise
                        error('TtpaPSDiagram:UndefinedCondition', ...
                            ['Condition type "%s" is not classified as a power ', ...
                             'curve or a wing-loading wall. Add it to ', ...
                             'TtpaPSDiagram.classify_ and to run_constraints.'], ...
                            con.type);
                end
            end
            idx   = find(keep);
            names = names(keep);
        end

        function check_con_no_(d, con_no, kind)
            if con_no > numel(d.obj.cons)
                error('TtpaPSDiagram:badConditionIndex', ...
                    'con_no = %d exceeds the %d conditions in the requirements file.', ...
                    con_no, numel(d.obj.cons));
            end
            [idx, ~] = d.classify_(kind);
            if ~ismember(con_no, idx)
                con = get_con(con_no, d.obj.cons);
                error('TtpaPSDiagram:wrongConditionKind', ...
                    ['Condition %d ("%s", type "%s") is not a %s. Use ', ...
                     'producers() for the P(S) curves and walls() for the ', ...
                     'S(P) curves.'], con_no, con.name, con.type, kind);
            end
        end

        function P = default_P_seed(d, S_first)
        %DEFAULT_P_SEED  Power seed for the first S point of a curve.
        %   Uses the design point of the requirements file: at the wing
        %   loading it names, a wing of S_first carries W = (W/S)*S_first,
        %   and that weight needs P = W/(W/P). A seed only - the converged
        %   curve does not depend on it.
            J  = jsondecode(fileread(ttpa_requirements_path()));
            dp = J.constraints.design_point;
            W_est = dp.wing_loading_psf * S_first;
            P = W_est / dp.power_loading_lb_per_hp;
        end

        function c = quiet_scan_(~)
        %QUIET_SCAN_  Mute the per-cell chatter for the duration of a scan.
        %   A grid scan deliberately visits cells with absurd engines and
        %   wings, so the out-of-range warning from the Raymer Table 10.4
        %   regression and the per-cell infeasibility warning would fire
        %   thousands of times and bury the real output. They are restored
        %   by the onCleanup object when the caller returns, so a SINGLE
        %   call to converge_W0 still warns normally.
            s1 = warning('off', 'TtpaProp:BhpOutOfRange');
            s2 = warning('off', 'TtpaPSDiagram:cellInfeasible');
            c  = onCleanup(@() warning([s1, s2]));
        end

    end

end
