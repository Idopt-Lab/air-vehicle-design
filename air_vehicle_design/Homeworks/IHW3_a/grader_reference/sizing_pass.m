function row = sizing_pass(obj, W0, P0, S0, WS_sweep)
%SIZING_PASS  One pass of the main sizing loop, box by box.
%
%   row = sizing_pass(obj, W0, P0, S0, WS_sweep)
%
%   Inputs
%     obj       discipline bundle from ttpa_disciplines. MUTATED: this pass
%               writes P_SL and S_ref into it.
%     W0        takeoff weight this pass starts from [lbf]
%     P0        total sea-level shaft power this pass starts from [hp]
%     S0        wing reference area this pass starts from [ft^2]
%     WS_sweep  wing-loading sweep for the constraint analysis [lbf/ft^2]
%   Output
%     row       the full record of this pass, from sizing_snapshot
%
%   THE SIX STEPS, IN ORDER. THE ORDER IS THE WHOLE POINT.
%
%     0  Write the airplane.  P_SL first, then S_ref. Every geometric and
%        aerodynamic quantity is a Dependent property of these two, so these
%        two writes resize the whole airplane: span, tails, wetted area,
%        nacelles, C_D0.
%     1  Constraint analysis on THAT airplane. matching_envelope returns the
%        least-engine corner (W/S, W/P) and the wing-loading wall. Because
%        the cruise constraint reads C_D0, the corner belongs to this wing.
%     2  Size the wing and the engine from the CURRENT weight:
%            S_new = W0 / (W/S)        P_new = W0 / (W/P)
%        Power loading is inverted - a bigger W/P is a SMALLER engine - so
%        the power is W0 DIVIDED by W/P. A jet multiplies T/W by W.
%     3  Mission fuel at W0, flown by the airplane written in step 0.
%     4  Empty weight at W0, built up from that same airplane.
%     5  Close the takeoff weight:
%            W_new = W_payload / (1 - W_fuel/W0 - OEW/W0)
%     6  Residuals, measured BEFORE any relaxation, and the record.
%
%   S_new and P_new are NOT written into the airplane here. They are this
%   pass's answer; sizing_mainloop decides what the next pass starts from.

    % ---- STEP 0: write the three states into the airplane ------------------
    obj.prop.P_SL  = P0;
    obj.geom.S_ref = S0;

    % ---- STEP 1: constraint analysis on the current airplane ---------------
    [~, WS_wall, ~, WS, WP] = matching_envelope(WS_sweep, obj);
    if isnan(WS)
        error('sizing_pass:NoFeasiblePoint', ...
            ['No wing loading on [%.1f, %.1f] lbf/ft^2 is feasible: the ', ...
             'whole sweep lies beyond the wing-loading wall at %.2f.'], ...
            WS_sweep(1), WS_sweep(end), WS_wall);
    end

    % ---- STEP 2: size the wing and the engine from W0 ----------------------
    S_new = W0 / WS;
    P_new = W0 / WP;

    % ---- STEP 3: mission fuel ----------------------------------------------
    [W_fuel, fuel_fraction] = mission_fuel(W0, obj);
    obj.wts.W_TO     = W0;
    obj.wts.W_energy = W_fuel;          % the wing-fuel term of Raymer Eq. 15.46

    % ---- STEP 4: empty weight ----------------------------------------------
    bd = obj.wts.OEW_breakdown(W0);

    % ---- STEP 5: takeoff-weight closure ------------------------------------
    [W_new, denom] = SizingSteps.togw_update(obj.wts.payload(), ...
                                             bd.total, W_fuel, W0);
    if isnan(W_new)
        error('sizing_pass:closureInfeasible', ...
            ['Takeoff-weight closure is infeasible at W0 = %.1f lbf: ', ...
             'denom = 1 - W_f/W0 - OEW/W0 = %.4f must be > 0. The empty ', ...
             'weight and the fuel consume the whole takeoff weight.'], ...
            W0, denom);
    end

    % ---- STEP 6: residuals and the record ----------------------------------
    core.W_TO          = W0;
    core.P_SL          = P0;
    core.S_ref         = S0;
    core.WS            = WS;
    core.WP            = WP;
    core.WS_wall       = WS_wall;
    core.W_fuel        = W_fuel;
    core.fuel_fraction = fuel_fraction;
    core.OEW_breakdown = bd;
    core.denom         = denom;
    core.W_TO_new      = W_new;
    core.P_SL_new      = P_new;
    core.S_ref_new     = S_new;
    core.res_W         = abs(W_new - W0) / W_new;
    core.res_P         = abs(P_new - P0) / P_new;
    core.res_S         = abs(S_new - S0) / S_new;

    row = sizing_snapshot(obj, core);
end
