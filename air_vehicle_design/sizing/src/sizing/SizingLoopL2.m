classdef SizingLoopL2 < handle
%SIZINGLOOPL2  Level-2 takeoff-gross-weight and sea-level-thrust sizing
%   loop. Also serves the L3 rung.
%
%   Two-state (W_TO, T_SL) fixed-point iteration [martins_slides_data.md
%   Slide 8]: two coupled iterations, a tail-sizing box feeding the
%   empty-weight and drag-polar boxes, and point-performance (constraint)
%   checks EACH iteration. Unlike L1 the design point is re-solved every
%   iteration: the wing resizes from the evolving W0, and the thrust write
%   feeds geometry (nacelle sizing) and so CD0, so the constraint envelope
%   moves as the loop state evolves.
%
%   Weight closure per iteration: TOGW step [metabook_data.md Ch. 2 "TOGW
%   Iteration Algorithm (Algorithm 1)"; Raymer 6th ed. Eq. 3.4] via
%   SizingSteps.togw_update.
%
%   No ControlSurfaceSizer here: Slide 8 has no control-surface box and
%   those areas feed no OEW term. No WS_design input: the (W/S, T/W) point
%   comes from obj.con.optimal_point_continuous every iteration.
%
%   Flat orchestrator, not a discipline -- see SizingLoopL1.m's header.

    % TODO (8/3/2026): You could move this section (72 - 100) (constructor and
    % properties) into some sort of base enforcer class that is also accessible
    % to subclasses. Apply this to SizingLoopL1, too.
    properties (SetAccess = private)
        aero    % (1,1) AerodynamicsBase
        prop    % (1,1) PropulsionBase
        wts     % (1,1) WeightsBase
        geom    % (1,1) GeometryBase
        miss    % (1,1) MissionAnalysisBase
        con     % (1,1) ConstraintAnalysis
        tail    % (1,1) TailSizingBase
    end

    methods

        function obj = SizingLoopL2(aero, prop, wts, geom, miss, con, tail)
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

        function result = run(obj, W_TO_guess, T_SL_guess, opts)
        %RUN  Iterate (W_TO, T_SL) to convergence.  [martins slides
        %   Slide 8; metabook Algorithm 1 -- see class header for full
        %   citations]
        %
        %   W_TO_guess, T_SL_guess -- lbf, initial guesses. Both required
        %                             (no silent defaults).
        %   opts.tol_rel  -- relative convergence tolerance, applied to
        %                    BOTH |W0_new - W0|/W0_new and
        %                    |T_SL_new - T_SL|/T_SL_new. Default 1e-6.
        %   opts.max_iter -- maximum iterations. Default 200.
        %   opts.relax_W  -- W_TO under-relaxation in (0,1]. Default 0.5.
        %   opts.relax_T  -- T_SL under-relaxation in (0,1]. Default 0.5.
        %
        %   Returns struct with fields:
        %     W_TO, T_SL, S_ref, WS, TW, S_ht, S_vt, W_fuel, W_OEW,
        %     n_iter, converged, history.
        %   history is a struct array (one row per completed iteration)
        %   with fields: iter, W0, T_SL, WS, TW, S_ref, S_ht, S_vt, W_OEW,
        %   W_fuel, W0_new, T_SL_new, denom.
        %
        %   If max_iter is reached without convergence, the result is
        %   returned with converged = false and a
        %   'SizingLoopL2:notConverged' warning (no error). Errors with
        %   'SizingLoopL2:closureInfeasible' if the TOGW closure
        %   denominator goes non-positive.
            arguments
                obj
                W_TO_guess    (1,1) double {mustBePositive}
                T_SL_guess    (1,1) double {mustBePositive}
                opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relax_W  (1,1) double {mustBeInRange(opts.relax_W, 0, 1, "exclude-lower")} = 0.5
                opts.relax_T  (1,1) double {mustBeInRange(opts.relax_T, 0, 1, "exclude-lower")} = 0.5
            end

            W0   = W_TO_guess;
            T_SL = T_SL_guess;

            % Seed the design point once before the loop. Write the thrust
            % guess into prop FIRST so the seed solve reads a fresh CD0
            % (F16GeomL2/L3's nacelle diameter is Dependent on prop.T_SL);
            % iteration 1 re-solves with the resized wing.
            obj.prop.T_SL = T_SL;
            [WS, TW] = obj.con.optimal_point_continuous();

            converged = false;
            row_template = struct('iter', NaN, 'W0', NaN, 'T_SL', NaN, ...
                'WS', NaN, 'TW', NaN, 'S_ref', NaN, 'S_ht', NaN, 'S_vt', NaN, ...
                'W_OEW', NaN, 'W_fuel', NaN, 'W0_new', NaN, 'T_SL_new', NaN, ...
                'denom', NaN);
            history = repmat(row_template, 1, opts.max_iter);

            for iter = 1:opts.max_iter
                % 1. Wing resize from the current design point: S_ref
                %    CHANGES every iteration [Slide 8, wing-loading box].
                obj.geom.S_ref = W0 / WS;

                % 2. Tail resize -> OEW coupling [Slide 8: the tail-sizing
                %    box feeds the empty-weight and drag-polar boxes]. The
                %    weights class reads geom's tail areas live, so OEW
                %    below already reflects this iteration's tail.
                tail_result = obj.tail.size();
                obj.geom.S_ht = tail_result.S_ht;
                obj.geom.S_vt = tail_result.S_vt;

                % 3. Thrust write BEFORE the constraint solve, so the
                %    solve reads THIS iteration's nacelle-driven CD0, not a
                %    stale one.
                obj.prop.T_SL = T_SL;

                % 4. Re-solve the design point, warm-started at the
                %    previous iterate [Slide 8: point-performance checks
                %    each iteration]. Errors loudly if infeasible.
                [WS, TW] = obj.con.optimal_point_continuous([WS, TW]); % TODO (8/10/2026): Is this ACTUALLY recomputing the optimum point, or is it just checking if the  point is phyusically feasible? It doesn't seem like it's actually recomputing it!
                % TODO (8/13/2026): Remember, if the S_ref is changing,
                % then all the wing dimensions should change from that.
                % Ensure that these updates are firing.
                T_SL_new = TW * W0; % TODO (8/13/2026): This isn't even using the new T_SL, and this STILL BOTHERS ME.
                if ~(isfinite(T_SL_new) && T_SL_new > 0)
                    error('SizingLoopL2:badThrust', ...
                        ['Constraint solve returned a non-physical thrust demand ', ...
                         'at iteration %d: TW = %.4g, W0 = %.1f lbf.'], iter, TW, W0);
                end

                % 5. Mission fuel + empty weight at the current W0, then
                %    WeightsBase bookkeeping.
                [W_fuel, ~] = obj.miss.total_fuel(W0);
                W_OEW = obj.wts.OEW(W0);
                obj.wts.W_TO     = W0;
                obj.wts.W_energy = W_fuel;

                % 6. TOGW closure step [metabook Algorithm 1; Raymer 6th
                %    ed. Eq. 3.4 -- see SizingSteps.togw_update].
                W_payload = obj.wts.W_payload_fixed + obj.wts.W_payload_expendable;
                [W0_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);
                if isnan(W0_new)
                    error('SizingLoopL2:closureInfeasible', ...
                        ['TOGW closure infeasible at iteration %d: denom = ', ...
                         '1 - W_fuel/W_TO - W_OEW/W_TO = %.4f <= 0 ', ...
                         '(W_OEW/W_TO = %.4f, W_fuel/W_TO = %.4f at W_TO = %.1f lbf). ', ...
                         'The empty and fuel fractions consume the whole takeoff ', ...
                         'weight; no positive W_TO closes the payload at this design point.'], ...
                        iter, denom, W_OEW/W0, W_fuel/W0, W0);
                end

                row = row_template;
                row.iter     = iter;
                row.W0       = W0;
                row.T_SL     = T_SL;
                row.WS       = WS;
                row.TW       = TW;
                row.S_ref    = obj.geom.S_ref;
                row.S_ht     = tail_result.S_ht;
                row.S_vt     = tail_result.S_vt;
                row.W_OEW    = W_OEW;
                row.W_fuel   = W_fuel;
                row.W0_new   = W0_new;
                row.T_SL_new = T_SL_new;
                row.denom    = denom;
                history(iter) = row;

                if abs(W0_new - W0) / W0_new < opts.tol_rel && ...
                        abs(T_SL_new - T_SL) / T_SL_new < opts.tol_rel
                    W0   = W0_new;
                    T_SL = T_SL_new;
                    converged = true;
                    break;
                end
                W0   = SizingSteps.relax(W0,   W0_new,   opts.relax_W);
                T_SL = SizingSteps.relax(T_SL, T_SL_new, opts.relax_T);
            end
            history = history(1:iter);

            if ~converged
                warning('SizingLoopL2:notConverged', ...
                    ['(W_TO, T_SL) iteration did not converge in %d iterations ', ...
                     '(last W0 = %.1f lbf, last T_SL = %.1f lbf). ', ...
                     'Returning the unconverged state (converged = false).'], ...
                    opts.max_iter, W0, T_SL);
            end

            % Final write-through: steps 1-3 at the converged point, then one
            % final design-point solve and mission/OEW read so the result
            % and wts bookkeeping match the returned (W_TO, T_SL).
            obj.geom.S_ref = W0 / WS;
            tail_result = obj.tail.size();
            obj.geom.S_ht = tail_result.S_ht;
            obj.geom.S_vt = tail_result.S_vt;
            obj.prop.T_SL = T_SL;
            [WS, TW] = obj.con.optimal_point_continuous([WS, TW]);
            [W_fuel, ~] = obj.miss.total_fuel(W0);
            W_OEW = obj.wts.OEW(W0);
            obj.wts.W_TO     = W0;
            obj.wts.W_energy = W_fuel;

            result = struct( ...
                'W_TO',      W0, ...
                'T_SL',      T_SL, ...
                'S_ref',     obj.geom.S_ref, ...
                'WS',        WS, ...
                'TW',        TW, ...
                'S_ht',      obj.geom.S_ht, ...
                'S_vt',      obj.geom.S_vt, ...
                'W_fuel',    W_fuel, ...
                'W_OEW',     W_OEW, ...
                'n_iter',    iter, ...
                'converged', converged, ...
                'history',   history);
        end

    end

end
