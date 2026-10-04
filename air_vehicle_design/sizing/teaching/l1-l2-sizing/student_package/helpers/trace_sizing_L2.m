function [T, result] = trace_sizing_L2(stackFcn, W_TO_guess, T_SL_guess, opts)
%TRACE_SIZING_L2  Run the Level-2 sizing loop and record everything it touches.
%
%   [T, result] = TRACE_SIZING_L2(stackFcn, W_TO_guess, T_SL_guess)
%
%   `SizingLoopL2` logs 13 quantities per pass. That is enough to know whether
%   it converged, and not enough to see WHY. This function runs the same loop,
%   step for step, and records about thirty quantities per pass: the two state
%   variables, the slaved wing area, the design point, the whole geometry
%   cascade, the component weight breakdown, and the drag polar.
%
%   It is a REPLICA of `src/sizing/SizingLoopL2.m`, not a wrapper, because the
%   quantities of interest are intermediates the class does not return. The
%   replica is checked against the class at the end of every call: if the two
%   disagree by more than a pound, this function errors. So the trace is the
%   real loop, or you hear about it.
%
%   INPUTS
%     stackFcn     no-argument handle returning [aero, prop, wts, geom, miss,
%                  con, tail], e.g. @build_f16_stack_L2
%     W_TO_guess   lbf
%     T_SL_guess   lbf
%
%   OPTIONS (name-value), matching SizingLoopL2.run
%     tol_rel   default 1e-6
%     max_iter  default 200
%     relax_W   default 0.5
%     relax_T   default 0.5
%     state     AircraftState at which to sample the drag polar each pass.
%               Default: 30,000 ft / M 0.8, which is only a probe -- it does
%               not feed the loop.
%     verify    default true. Set false to skip the check against the class,
%               for example when you deliberately changed the loop.
%
%   OUTPUT
%     T       a table, one row per pass. Read its VariableDescriptions for
%             units. Feed it to PLOT_SIZING_HISTORY and PLOT_WEIGHT_HISTORY.
%     result  the reference struct from SizingLoopL2, for comparison.
%
%   WHICH QUANTITIES ARE UNKNOWNS, AND WHICH ARE SLAVED
%     W_TO and T_SL are the two STATE variables. The loop under-relaxes them.
%     S_ref is SLAVED: S_ref = W_TO / (W/S)*, recomputed every pass. It moves,
%     but it is an output of the other two, not a third unknown. Everything
%     else in the table is downstream of those three.

    arguments
        stackFcn      (1,1) function_handle
        W_TO_guess    (1,1) double {mustBePositive}
        T_SL_guess    (1,1) double {mustBePositive}
        opts.tol_rel  (1,1) double {mustBePositive} = 1e-6
        opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
        opts.relax_W  (1,1) double {mustBePositive} = 0.5
        opts.relax_T  (1,1) double {mustBePositive} = 0.5
        opts.state          = AircraftState(30000, 0.80)
        opts.verify   (1,1) logical = true
    end

    [aero, prop, wts, geom, miss, con, tail] = stackFcn();

    W0   = W_TO_guess;
    T_SL = T_SL_guess;

    prop.T_SL = T_SL;                              % seed before the first solve
    [WS, TW]  = con.optimal_point_continuous();

    rows = {};
    converged = false;

    for iter = 1:opts.max_iter

        % ---- the loop body, exactly as SizingLoopL2 runs it --------------
        geom.S_ref = W0 / WS;                                           % 1

        tail_result = tail.size();                                      % 2
        geom.S_ht = tail_result.S_ht;
        geom.S_vt = tail_result.S_vt;

        prop.T_SL = T_SL;                                               % 3

        [WS, TW] = con.optimal_point_continuous([WS, TW]);              % 4
        T_SL_new = TW * W0;

        [W_fuel, ~] = miss.total_fuel(W0);                              % 5
        W_OEW        = wts.get_OEW(W0);
        wts.W_TO     = W0;
        wts.W_energy = W_fuel;

        W_payload = wts.W_payload_fixed + wts.W_payload_expendable;     % 6
        [W0_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);

        % ---- record ------------------------------------------------------
        rows{end+1} = snapshot(iter, W0, T_SL, WS, TW, W0_new, T_SL_new, ...
            denom, W_OEW, W_fuel, W_payload, aero, prop, wts, geom, opts.state); %#ok<AGROW>

        % ---- converge or relax -------------------------------------------
        if abs(W0_new - W0) / W0_new < opts.tol_rel && ...
           abs(T_SL_new - T_SL) / T_SL_new < opts.tol_rel
            W0 = W0_new;  T_SL = T_SL_new;  converged = true;
            break
        end
        W0   = SizingSteps.relax(W0,   W0_new,   opts.relax_W);
        T_SL = SizingSteps.relax(T_SL, T_SL_new, opts.relax_T);
    end

    T = struct2table([rows{:}]);
    T.Properties.Description = sprintf( ...
        'Level-2 sizing trace, %d passes, converged = %d', iter, converged);
    T = tag_units(T);

    % ---- prove the replica is the real loop -----------------------------
    [a, p, w, g, m, c, t] = stackFcn();
    result = SizingLoopL2(a, p, w, g, m, c, t).run(W_TO_guess, T_SL_guess, ...
        'tol_rel', opts.tol_rel, 'max_iter', opts.max_iter, ...
        'relax_W', opts.relax_W, 'relax_T', opts.relax_T);

    if opts.verify
        dW = abs(W0 - result.W_TO);
        dT = abs(T_SL - result.T_SL);
        if dW > 1 || dT > 1
            error('trace_sizing_L2:driftFromReference', ...
                ['This trace no longer matches SizingLoopL2 ', ...
                 '(W_TO off by %.3f lbf, T_SL off by %.3f lbf). ', ...
                 'The class has changed; update the loop body in ', ...
                 'trace_sizing_L2.m to match it again.'], dW, dT);
        end
    end
end

% =======================================================================
function s = snapshot(iter, W0, T_SL, WS, TW, W0_new, T_SL_new, denom, ...
                      W_OEW, W_fuel, W_payload, aero, prop, wts, geom, st)
%SNAPSHOT  One row. Everything is read live off the mutated objects.

    s.iter = iter;

    % --- the two state variables, and the slaved third output -------------
    s.W_TO   = W0;                 % STATE, under-relaxed
    s.T_SL   = T_SL;               % STATE, under-relaxed
    s.S_ref  = geom.S_ref;         % SLAVED = W_TO / WS

    % --- the design point -------------------------------------------------
    s.WS = WS;
    s.TW = TW;

    % --- what the closure produced, and how far off it is -----------------
    s.W_TO_new   = W0_new;
    s.T_SL_new   = T_SL_new;
    s.res_W      = abs(W0_new   - W0)   / W0_new;
    s.res_T      = abs(T_SL_new - T_SL) / T_SL_new;
    s.denom      = denom;

    % --- the weight split -------------------------------------------------
    s.W_OEW      = W_OEW;
    s.W_fuel     = W_fuel;
    s.W_payload  = W_payload;
    s.f_OEW      = W_OEW     / W0;
    s.f_fuel     = W_fuel    / W0;
    s.f_payload  = W_payload / W0;

    % --- component weight breakdown --------------------------------------
    s.W_wings     = get_or_nan(wts, 'W_wings');
    s.W_tail      = sum_struct(get_or_nan(wts, 'W_tail'));
    s.W_fuselage  = get_or_nan(wts, 'W_fuselage');
    s.W_gear      = get_or_nan(wts, 'W_landing_gear');
    s.W_engine    = get_or_nan(wts, 'W_installed_engine');
    s.W_other     = get_or_nan(wts, 'W_all_else_empty');

    % --- geometry cascade -------------------------------------------------
    s.S_ht        = geom.S_ht;
    s.S_vt        = geom.S_vt;
    s.b_wing      = get_or_nan(geom, 'b_wing');
    s.cbar_wing   = get_or_nan(geom, 'cbar_wing');
    s.S_exp_wing  = get_or_nan(geom, 'S_exposed_wing');
    s.S_exp_ht    = get_or_nan(geom, 'S_exposed_ht');
    s.S_exp_vt    = get_or_nan(geom, 'S_exposed_vt');
    s.S_wet       = get_or_nan(geom, 'S_wet');
    s.S_wet_S_ref = s.S_wet / geom.S_ref;

    % --- drag polar, sampled at the probe condition -----------------------
    s.CD0 = NaN;  s.K1 = NaN;  s.LD_max = NaN;
    try
        pol = aero.drag_polar(st);
        s.CD0 = pol.CD0;
        s.K1  = pol.K1;
        if pol.CD0 > 0 && pol.K1 > 0
            s.LD_max = 1 / (2*sqrt(pol.CD0 * pol.K1));
        end
    catch
        % an aero model that cannot be evaluated at the probe state just
        % leaves these NaN; the loop itself is unaffected
    end
end

% =======================================================================
function v = get_or_nan(obj, name)
    v = NaN;
    if isprop(obj, name)
        try
            v = obj.(name);
        catch
            v = NaN;
        end
    end
end

function v = sum_struct(x)
%SUM_STRUCT  W_tail comes back split into HT and VT on some weights models.
    if isstruct(x)
        f = fieldnames(x);
        v = 0;
        for k = 1:numel(f)
            if isnumeric(x.(f{k})), v = v + sum(x.(f{k})(:)); end
        end
    else
        v = x;
    end
end

% =======================================================================
function T = tag_units(T)
    u = dictionary( ...
        "iter",        "pass", ...
        "W_TO",        "lbf  STATE", ...
        "T_SL",        "lbf  STATE", ...
        "S_ref",       "ft^2  slaved = W_TO/WS", ...
        "WS",          "psf", ...
        "TW",          "-", ...
        "W_TO_new",    "lbf", ...
        "T_SL_new",    "lbf", ...
        "res_W",       "-", ...
        "res_T",       "-", ...
        "denom",       "-", ...
        "W_OEW",       "lbf", ...
        "W_fuel",      "lbf", ...
        "W_payload",   "lbf", ...
        "f_OEW",       "-", ...
        "f_fuel",      "-", ...
        "f_payload",   "-", ...
        "W_wings",     "lbf", ...
        "W_tail",      "lbf  HT+VT", ...
        "W_fuselage",  "lbf", ...
        "W_gear",      "lbf", ...
        "W_engine",    "lbf", ...
        "W_other",     "lbf", ...
        "S_ht",        "ft^2", ...
        "S_vt",        "ft^2", ...
        "b_wing",      "ft", ...
        "cbar_wing",   "ft", ...
        "S_exp_wing",  "ft^2", ...
        "S_exp_ht",    "ft^2", ...
        "S_exp_vt",    "ft^2", ...
        "S_wet",       "ft^2", ...
        "S_wet_S_ref", "-", ...
        "CD0",         "-", ...
        "K1",          "-", ...
        "LD_max",      "-");
    names = string(T.Properties.VariableNames);
    T.Properties.VariableUnits = arrayfun( ...
        @(n) ternary(isKey(u, n), @() u(n), @() ""), names);
end

function v = ternary(c, a, b)
    if c, v = a(); else, v = b(); end
end
