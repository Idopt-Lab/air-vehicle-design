function [result] = sizing_loop(obj, opts)
%SIZING_LOOP  The preliminary design framework, as a two-state fixed point.
%
%   result = sizing_loop(obj, opts)
%
%   Inputs
%     obj    discipline bundle from ttpa_disciplines. MUTATED IN PLACE - the
%            discipline objects are handle objects, so when this returns,
%            obj.geom.S_ref and obj.prop.P_SL hold the converged airplane and
%            every Dependent property follows.
%     opts   struct, normally built by run_ttpa_sizing from the sizing block
%            of the requirements JSON:
%              .mode         "fixed_wing_area" or "design_point"
%              .S_ref        ft^2, THE DESIGN VARIABLE of "fixed_wing_area"
%              .W_TO_guess   lbf
%              .selected     struct .WS/.WP, used by "design_point" mode and
%                            as the seed for "fixed_wing_area"
%              .WS_sweep     wing-loading sweep, "design_point" mode only
%              .design_point_mode  "selected" or "optimum", ditto
%              .tol_rel .max_iter .relax_W .relax_P
%
%   ==================================================================
%   THE FRAMEWORK
%
%   This is the PRELIMINARY DESIGN FRAMEWORK of the sizing-refinement
%   lecture, in propeller form. Boxes, and where each one lives:
%
%       Tail sizing     TtpaGeom.S_ht / S_vt        Dependent on S_ref
%       Drag polar II   TtpaAero.CD0                Dependent on S_wet/S_ref
%       Wing loading    W_0 / S_ref                 step 3 below
%       Design diagram  design_diagram(WS, obj)     step 4
%       Fuel fraction   mission_fuel(W_0, obj)      step 6
%       Empty weight    obj.wts.OEW(W_0)            step 6
%       MTOW iteration  SizingSteps.togw_update     step 7
%       P_0 iteration   P_0 = W_0 / (W/P)           step 5
%
%   Two red loops, exactly as the lecture draws them: W_0,guess closed by the
%   MTOW iteration, and P_0,guess (the lecture's T_0,guess) closed by the
%   power iteration.
%
%   ==================================================================
%   THE TWO MODES, AND WHY BOTH EXIST
%
%   "fixed_wing_area"  -- THE LECTURE FRAMEWORK, and the default.
%       S_ref is a green INPUT, a design variable you choose. The wing
%       loading is COMPUTED, W/S = W_0/S_ref, and the design diagram is read
%       at that ONE wing loading to get the power the requirements demand.
%       The lecture states the consequence in a footnote on the diagram:
%       "You don't need to draw the entire chart because W/S is fixed."
%       This is the form that makes trade studies possible, because the
%       objective becomes a function of S_ref - see run_ttpa_trade_studies.
%
%   "design_point"  -- the IHW2 route, kept for continuity.
%       The matching diagram is solved for a design point, and
%       S_ref = W_0/(W/S) becomes an OUTPUT. This is what the framework's own
%       SizingLoopL2 does, and what the F-16 and 777 examples drive. It is
%       the special case of the lecture framework in which S_ref happens to
%       land exactly on the envelope corner.
%
%   The two agree when the chosen S_ref equals the one the design-point mode
%   converges to. Run both.
%
%   ==================================================================
%   THE TWO STATES
%
%   W_0 and P_0. A jet loop uses (W_0, T_0) and updates the second state as
%   T_0 = (T/W) W_0. A propeller airplane works in POWER LOADING, which is
%   inverted - a BIGGER W/P means a SMALLER engine - so the second state is
%
%       P_0 = W_0 / (W/P)
%
%   Both must converge before the loop stops.
%
%   ==================================================================
%   ONE ITERATION, IN ORDER. THE ORDER MATTERS.
%
%     1  Engine    P_0 is written BEFORE anything reads the geometry, so the
%                  nacelle and the engine weight are this iteration's.
%     2  Wing      S_ref written. One number resizes the span, the chords,
%                  the MAC, the exposed area, both tails through their volume
%                  coefficients, and every wetted area - all Dependent
%                  properties of TtpaGeom, so none can be stale.
%     3  Wing      W/S = W_0/S_ref.            ("Wing loading" box)
%        loading
%     4  Design    the binding power loading at that single W/S.
%        diagram
%     5  Power     P_0_new = W_0 / (W/P).      ("T_0 iteration")
%     6  Closure   mission fuel and empty weight at the current weight.
%     7  MTOW      the takeoff-weight closure step.
%     8  Test      both relative residuals; then relax both states.
%
%   ==================================================================
%   FAILURE MODES, BOTH REAL
%
%   closureInfeasible: the empty and fuel fractions have consumed the whole
%   takeoff weight, so no positive weight closes the payload. A DESIGN
%   result, not a bug, which is why the loop errors instead of returning a
%   negative weight.
%
%   notConverged: max_iter reached. The unconverged state is returned with
%   converged = false and a warning, never an error.
%
%   See also DESIGN_DIAGRAM, SIZINGSTEPS, MISSION_FUEL, SOLVE_DESIGN_POINT.

    arguments
        obj  (1,1) struct
        opts (1,1) struct
    end

    mode = string(getfield_(opts, 'mode', "design_point"));

    % ---------------------------------------------------------------- setup
    W0 = opts.W_TO_guess;

    switch mode
        case "fixed_wing_area"
            S_ref = opts.S_ref;
            WP    = opts.selected.WP;      % seed only; step 4 replaces it
            WS    = W0 / S_ref;
        case "design_point"
            WS    = opts.selected.WS;
            WP    = opts.selected.WP;
            S_ref = W0 / WS;
        otherwise
            error('sizing_loop:UndefinedMode', ...
                ['Sizing mode "%s" is not defined. Use "fixed_wing_area" ', ...
                 '(the lecture framework, S_ref is an input) or ', ...
                 '"design_point" (the IHW2 route, S_ref is an output).'], mode);
    end
    P0 = W0 / WP;

    converged    = false;
    recover_left = 8;     % budget for the transient recovery in step 7

    row = struct('iter', NaN, 'W_TO', NaN, 'P_SL', NaN, 'S_ref', NaN, ...
                 'WS', NaN, 'WP', NaN, 'driving', "", 'CD0', NaN, 'LD_max', NaN, ...
                 'W_fuel', NaN, 'W_OEW', NaN, 'denom', NaN, ...
                 'W_TO_new', NaN, 'P_SL_new', NaN, 'res_W', NaN, 'res_P', NaN);
    history = repmat(row, 1, opts.max_iter);

    dp = struct([]);

    % ----------------------------------------------------------- iteration
    for iter = 1:opts.max_iter

        % 1  Engine from the current power state, first, so everything that
        %    reads the nacelle or the engine weight sees this iteration's.
        obj.prop.P_SL = P0;

        % 2  Wing area
        if mode == "design_point"
            S_ref = W0 / WS;
        end
        obj.geom.S_ref = S_ref;

        % 3  Wing loading, and 4  the design diagram
        switch mode

            case "fixed_wing_area"
                WS = W0 / S_ref;                       % the "Wing loading" box
                [WP, dd] = design_diagram(WS, obj);    % the "Design diagram" box
                dp = dd;
                dp.mode      = mode;
                dp.feasible  = dd.wall_ok;
                dp.WP_margin = 0;                      % sized exactly to the limit

            case "design_point"
                [WS, WP, dp] = solve_design_point(obj, ...
                    string(opts.design_point_mode), opts.WS_sweep, opts.selected);
                dp.driving = dp.driving;
        end

        % 5  New power state from the design diagram and the current weight
        P_new = W0 / WP;

        % 6  Mission fuel and empty weight, both at the CURRENT weight.
        %    mission_fuel reads the drag polar, which follows the geometry
        %    written in step 2; OEW is the component build-up over that same
        %    geometry plus the engine written in step 1.
        %
        %    TRANSIENT RECOVERY. A weight iterate can pass through a state no
        %    airplane could occupy even though a good fixed point exists
        %    elsewhere, and for this closure the trouble comes from BELOW: the
        %    fuselage and the engine put a FIXED number of pounds into the
        %    empty weight, so at a small W_TO the empty fraction blows up and
        %    the engine sized for that weight is too small to climb. Two
        %    things can go wrong, and both are recoverable the same way -
        %    jump the iterate to a physically sane weight and carry on.
        %      (a) a discipline throws or returns non-finite, e.g. the L2
        %          mission cannot climb on the engine this weight implies;
        %      (b) the closure denominator goes non-positive.
        %    Only when the recovery budget is spent is it a real result.
        blew_up = false;
        W_fuel  = NaN;  W_OEW = NaN;  W_new = NaN;  denom = NaN;

        try
            [W_fuel, ~] = mission_fuel(W0, obj);
            W_OEW       = obj.wts.OEW(W0);
            if ~(isfinite(W_fuel) && isfinite(W_OEW))
                blew_up = true;
            end
        catch
            blew_up = true;
        end

        if ~blew_up
            obj.wts.W_TO     = W0;
            obj.wts.W_energy = W_fuel;

            % 7  Takeoff-weight closure
            [W_new, denom] = SizingSteps.togw_update(obj.wts.payload(), ...
                                                     W_OEW, W_fuel, W0);
            blew_up = isnan(W_new);
        end

        if blew_up && recover_left > 0
            recover_left = recover_left - 1;
            W0 = max(1.5 * W0, obj.wts.payload() / 0.25);
            P0 = W0 / WP;
            continue;
        end

        if blew_up
            error('sizing_loop:closureInfeasible', ...
                ['Takeoff-weight closure is infeasible at iteration %d.\n', ...
                 '  denom = 1 - W_fuel/W_TO - OEW/W_TO = %.4f  (must be > 0)\n', ...
                 '  OEW/W_TO = %.4f, W_fuel/W_TO = %.4f at W_TO = %.1f lbf\n', ...
                 'The empty weight and the fuel together consume the whole ', ...
                 'takeoff weight, so no positive takeoff weight carries the ', ...
                 '%.0f lbf payload with this wing. This is a DESIGN result, ', ...
                 'not a coding error: either the wing area is far from a ', ...
                 'workable value, or the relaxation is too large and an early ', ...
                 'step overshot. Try relax_W = 0.5 first.'], ...
                iter, denom, W_OEW/W0, W_fuel/W0, W0, obj.wts.payload());
        end

        % 8  Residuals of BOTH states, measured before relaxation
        res_W = abs(W_new - W0) / W_new;
        res_P = abs(P_new - P0) / P_new;

        r          = row;
        r.iter     = iter;
        r.W_TO     = W0;
        r.P_SL     = P0;
        r.S_ref    = obj.geom.S_ref;
        r.WS       = WS;
        r.WP       = WP;
        r.driving  = string(dp.driving);
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

        if res_W < opts.tol_rel && res_P < opts.tol_rel
            W0 = W_new;
            P0 = P_new;
            converged = true;
            break;
        end

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
    % them once more at the state actually being returned.
    obj.prop.P_SL = P0;
    if mode == "design_point"
        S_ref = W0 / WS;
    end
    obj.geom.S_ref = S_ref;

    if mode == "fixed_wing_area"
        WS = W0 / S_ref;
        [WP, dd] = design_diagram(WS, obj);
        dp = dd;  dp.mode = mode;  dp.feasible = dd.wall_ok;  dp.WP_margin = 0;

        % The full envelope is not needed to SIZE the airplane in this mode -
        % that is the whole point of reading the design diagram at one wing
        % loading. Solve it once here anyway, purely so the report can say
        % where this design sits relative to the least-engine corner.
        if isfield(opts, 'WS_sweep') && ~isempty(opts.WS_sweep)
            [~, ~, ~, WS_opt, WP_opt] = matching_envelope(opts.WS_sweep, obj);
            dp.WS_optimum = WS_opt;
            dp.WP_optimum = WP_opt;
        else
            dp.WS_optimum = NaN;
            dp.WP_optimum = NaN;
        end
    end

    [W_fuel, fuel_fraction, ~, ~, ~, mission_detail] = mission_fuel(W0, obj);
    W_OEW = obj.wts.OEW(W0);

    obj.wts.W_TO     = W0;
    obj.wts.W_energy = W_fuel;

    [~, denom] = SizingSteps.togw_update(obj.wts.payload(), W_OEW, W_fuel, W0);

    % ------------------------------------------------------------- results
    result.mode          = mode;
    result.converged     = converged;
    result.n_iter        = iter;

    result.W_TO          = W0;
    result.P_SL          = P0;
    result.P_engine      = P0 / obj.prop.n_engines;

    result.WS            = WS;
    result.WP            = WP;
    result.design_point  = dp;

    result.W_fuel        = W_fuel;
    result.W_OEW         = W_OEW;
    result.W_payload     = obj.wts.payload();
    result.fuel_fraction = fuel_fraction;
    result.OEW_fraction  = W_OEW / W0;
    result.useful_load_fraction = denom;
    result.OEW_breakdown = obj.wts.OEW_breakdown(W0);
    result.OEW_statistical = obj.wts.OEW_statistical(W0);
    result.mission_detail  = mission_detail;

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


function v = getfield_(s, name, default)
    if isfield(s, name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end
