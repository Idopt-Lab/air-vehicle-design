function [result] = sizing_loop(obj, opts)
%SIZING_LOOP  Two-state (W_TO, P_SL) sizing loop for the TTPA.
%
%   result = sizing_loop(obj, opts)
%
%   Inputs
%     obj    discipline bundle from ttpa_disciplines. MUTATED IN PLACE -
%            the discipline objects are handle objects, so when this
%            returns, obj.geom.S_ref and obj.prop.P_SL hold the converged
%            airplane and every Dependent property follows.
%     opts   struct, normally built by run_ttpa_sizing from the sizing
%            block of the requirements JSON:
%              .W_TO_guess        lbf, starting guess
%              .design_point_mode "selected" or "optimum"
%              .WS_sweep          wing-loading sweep, 1xM
%              .selected          struct with .WS and .WP
%              .tol_rel           relative tolerance on BOTH states
%              .max_iter          iteration ceiling
%              .relax_W .relax_P  under-relaxation factors in (0,1]
%
%   Output: result, a struct with the converged airplane, the full
%   iteration history, and the design-point information of the last
%   iteration. See the bottom of this file for the field list.
%
%   ------------------------------------------------------------------
%   WHAT THE LOOP IS FOR
%
%   IHW1 produced a takeoff weight and no airplane. IHW2 produced an
%   airplane shape - a wing loading and a power loading - and no weight; it
%   borrowed W_TO = 5354 lbf from IHW1 and typed it in. Neither result knew
%   about the other. That is fine as far as it goes, because at Level 1
%   they genuinely are independent: the IHW1 empty-weight regression sees
%   only the weight, and the IHW2 constraints work in ratios.
%
%   IHW3a makes them one calculation. The empty weight now comes from a
%   component build-up over real geometry, the drag now comes from the
%   wetted area of that geometry, and the geometry comes from the weight.
%   That circle has to be closed by iteration, and this is the iteration.
%
%   ------------------------------------------------------------------
%   THE TWO STATES
%
%   W_TO and P_SL. A jet sizing loop uses (W_TO, T_SL) and updates the
%   second state as T_SL = (T/W) * W_TO. A propeller airplane works in
%   POWER LOADING, which is inverted - a BIGGER W/P means a SMALLER engine
%   - so the second state is
%
%       P_SL = W_TO / (W/P)
%
%   Both states must converge before the loop stops.
%
%   ------------------------------------------------------------------
%   ONE ITERATION, IN ORDER. THE ORDER MATTERS.
%
%     1  Wing        S_ref = W_TO / (W/S). Writing this one number resizes
%                    the span, the chords, the MAC, the exposed area, both
%                    tails through their volume coefficients, and every
%                    wetted area - all of them Dependent properties of
%                    TtpaGeom, so none of them can be stale.
%     2  Engine      P_SL is written BEFORE the design point is solved, so
%                    that the solve reads this iteration's engine and not
%                    the last one's. This is the classic ordering trap in a
%                    two-state loop.
%     3  Design pt   Re-solve the matching envelope on the airplane as it
%                    now stands, and take the new (W/S, W/P) from it.
%     4  Power       P_SL_new = W_TO / (W/P), from the design point just
%                    solved and the CURRENT weight.
%     5  Closure     Mission fuel and empty weight at the current weight,
%                    then the takeoff-weight closure step.
%     6  Test        Both relative residuals against tol_rel.
%     7  Relax       Damp both states and go again.
%
%   ------------------------------------------------------------------
%   FAILURE MODES, BOTH REAL
%
%   closureInfeasible: the empty and fuel fractions have consumed the whole
%   takeoff weight, so no positive weight closes the payload. This is a
%   DESIGN result, not a bug in the code, and it is why the loop errors
%   instead of returning a negative weight.
%
%   notConverged: max_iter reached. The unconverged state is returned with
%   converged = false and a warning, never an error, so the history can be
%   inspected.
%
%   See also SIZINGSTEPS, SOLVE_DESIGN_POINT, MISSION_FUEL.

    arguments
        obj  (1,1) struct
        opts (1,1) struct
    end

    % ---------------------------------------------------------------- setup
    W0 = opts.W_TO_guess;

    % Seed the design point from the point chosen in IHW2, so that the very
    % first geometry write has a wing loading to use. Step 3 replaces it
    % immediately; in "optimum" mode the seed is discarded on iteration 1.
    WS = opts.selected.WS;
    WP = opts.selected.WP;
    P0 = W0 / WP;

    converged = false;

    row = struct('iter', NaN, 'W_TO', NaN, 'P_SL', NaN, 'S_ref', NaN, ...
                 'WS', NaN, 'WP', NaN, 'CD0', NaN, 'LD_max', NaN, ...
                 'W_fuel', NaN, 'W_OEW', NaN, 'denom', NaN, ...
                 'W_TO_new', NaN, 'P_SL_new', NaN, ...
                 'res_W', NaN, 'res_P', NaN);
    history = repmat(row, 1, opts.max_iter);

    % ----------------------------------------------------------- iteration
    for iter = 1:opts.max_iter

        % 1  Wing area from the current weight and the current wing loading
        obj.geom.S_ref = W0 / WS;

        % 2  Engine from the current power state. BEFORE the design-point
        %    solve, so the solve sees this iteration's engine.
        obj.prop.P_SL = P0;

        % 3  Re-solve the design point on the airplane as it now stands
        [WS, WP, dp] = solve_design_point(obj, opts.design_point_mode, ...
                                          opts.WS_sweep, opts.selected);

        % 4  New power state from the design point and the current weight
        P_new = W0 / WP;

        % 5  Mission fuel and empty weight, both at the CURRENT weight.
        %    mission_fuel reads LD_max, which follows CD0, which follows
        %    the geometry written in step 1. OEW is the component build-up
        %    over that same geometry plus the engine written in step 2.
        [W_fuel, ~] = mission_fuel(W0, obj);
        W_OEW       = obj.wts.OEW(W0);

        % Bookkeeping on the weights object
        obj.wts.W_TO     = W0;
        obj.wts.W_energy = W_fuel;

        % 6  Takeoff-weight closure
        [W_new, denom] = SizingSteps.togw_update(obj.wts.payload(), ...
                                                 W_OEW, W_fuel, W0);

        if isnan(W_new)
            error('sizing_loop:closureInfeasible', ...
                ['Takeoff-weight closure is infeasible at iteration %d.\n', ...
                 '  denom = 1 - W_fuel/W_TO - OEW/W_TO = %.4f  (must be > 0)\n', ...
                 '  OEW/W_TO = %.4f, W_fuel/W_TO = %.4f at W_TO = %.1f lbf\n', ...
                 'The empty weight and the fuel together consume the whole ', ...
                 'takeoff weight, so no positive takeoff weight carries the ', ...
                 '%.0f lbf payload at this design point. This is a DESIGN ', ...
                 'result, not a coding error. Two things cause it here: an ', ...
                 'under-relaxation factor close to 1, which lets an early ', ...
                 'step overshoot into this region, and a design point that ', ...
                 'genuinely does not close. Try relax_W = 0.5 first.'], ...
                iter, denom, W_OEW/W0, W_fuel/W0, W0, obj.wts.payload());
        end

        % Residuals of BOTH states, measured before relaxation
        res_W = abs(W_new - W0) / W_new;
        res_P = abs(P_new - P0) / P_new;

        % History
        r          = row;
        r.iter     = iter;
        r.W_TO     = W0;
        r.P_SL     = P0;
        r.S_ref    = obj.geom.S_ref;
        r.WS       = WS;
        r.WP       = WP;
        r.CD0      = obj.aero.CD0;
        r.LD_max   = obj.aero.LD_max;
        r.W_fuel   = W_fuel;
        r.W_OEW    = W_OEW;
        r.denom    = denom;
        r.W_TO_new = W_new;
        r.P_SL_new = P_new;
        r.res_W    = res_W;
        r.res_P    = res_P;
        history(iter) = r;

        % 7  Converged?
        if res_W < opts.tol_rel && res_P < opts.tol_rel
            W0 = W_new;
            P0 = P_new;
            converged = true;
            break;
        end

        % 8  Damp both states and go again
        W0 = SizingSteps.relax(W0, W_new, opts.relax_W);
        P0 = SizingSteps.relax(P0, P_new, opts.relax_P);

    end

    history = history(1:iter);

    if ~converged
        warning('sizing_loop:notConverged', ...
            ['The sizing loop did not converge in %d iterations. Last ', ...
             'W_TO = %.1f lbf, last residuals %.2e (weight) and %.2e ', ...
             '(power). The unconverged state is returned with ', ...
             'converged = false; inspect result.history.'], ...
            opts.max_iter, W0, history(end).res_W, history(end).res_P);
    end

    % --------------------------------------------------- final write-through
    % The loop body wrote the disciplines at the PRE-update state, so write
    % them once more at the state actually being returned. Without this the
    % geometry the caller inspects would be one iteration stale.
    obj.geom.S_ref = W0 / WS;
    obj.prop.P_SL  = P0;

    [W_fuel, fuel_fraction] = mission_fuel(W0, obj);
    W_OEW = obj.wts.OEW(W0);

    obj.wts.W_TO     = W0;
    obj.wts.W_energy = W_fuel;

    [~, denom] = SizingSteps.togw_update(obj.wts.payload(), W_OEW, W_fuel, W0);

    % ------------------------------------------------------------- results
    result.converged     = converged;
    result.n_iter        = iter;

    % states
    result.W_TO          = W0;
    result.P_SL          = P0;
    result.P_engine      = P0 / obj.prop.n_engines;

    % design point sized to
    result.WS            = WS;
    result.WP            = WP;
    result.design_point  = dp;

    % weight breakdown
    result.W_fuel        = W_fuel;
    result.W_OEW         = W_OEW;
    result.W_payload     = obj.wts.payload();
    result.fuel_fraction = fuel_fraction;
    result.OEW_fraction  = W_OEW / W0;
    result.useful_load_fraction = denom;
    result.OEW_breakdown = obj.wts.OEW_breakdown(W0);
    result.OEW_statistical = obj.wts.OEW_statistical(W0);

    % the airplane
    result.S_ref         = obj.geom.S_ref;
    result.b             = obj.geom.b;
    result.MAC           = obj.geom.MAC;
    result.S_ht          = obj.geom.S_ht;
    result.S_vt          = obj.geom.S_vt;
    result.S_wet         = obj.geom.S_wet;
    result.CD0           = obj.aero.CD0;
    result.LD_max        = obj.aero.LD_max;

    result.history       = history;

end
