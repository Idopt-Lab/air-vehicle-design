function s = one_closure_step(aero, prop, wts, geom, miss, WS, TW, W0)
%ONE_CLOSURE_STEP  Do ONE pass of the sizing closure and return every number.
%
%   s = ONE_CLOSURE_STEP(aero, prop, wts, geom, miss, WS, TW, W0)
%
%   This is the body of SizingLoopL1, unrolled one time, with nothing hidden.
%   Give it a guess W0 and a design point (W/S, T/W); it returns the next
%   guess W0_new plus every intermediate the closure used.
%
%   Steps, in the order the loop does them:
%     1. S_ref = W0 / (W/S)          size the wing        [Martins slide 6]
%     2. T_SL  = (T/W) * W0          size the engine      [Martins slide 6]
%     3. W_fuel = mission fuel at W0                      [Roskam / Breguet]
%     4. W_OEW  = empty weight at W0
%     5. denom  = 1 - W_OEW/W0 - W_fuel/W0
%        W0_new = W_payload / denom  [Raymer 6th ed. Eq. 3.4; metabook Alg. 1]
%
%   Returns a struct with: S_ref, T_SL, W_fuel, W_OEW, W_payload, denom,
%   W0_new, and the fuel/empty fractions.
%
%   NOTE: this MUTATES geom, prop and wts, exactly as the real loop does.

    arguments
        aero, prop, wts, geom, miss
        WS (1,1) double {mustBePositive}
        TW (1,1) double {mustBePositive}
        W0 (1,1) double {mustBePositive}
    end
    %#ok<*INUSA>  aero is read live by miss; it is listed to show the stack

    s.W0    = W0;
    s.WS    = WS;
    s.TW    = TW;

    % 1-2. Size the wing and the engine from the design point.
    geom.S_ref = W0 / WS;
    if isprop(geom, 'W_TO')          % L1 regression geometries carry W_TO
        geom.W_TO = W0;
    end
    prop.T_SL  = TW * W0;
    s.S_ref = geom.S_ref;
    s.T_SL  = prop.T_SL;

    % 3-4. Ask the mission and the weights model.
    [s.W_fuel, ~] = miss.total_fuel(W0);
    s.W_OEW       = wts.get_OEW(W0);
    wts.W_TO      = W0;
    wts.W_energy  = s.W_fuel;

    % 5. Close the weight.
    s.W_payload = wts.W_payload_fixed + wts.W_payload_expendable;
    [s.W0_new, s.denom] = SizingSteps.togw_update(s.W_payload, s.W_OEW, s.W_fuel, W0);

    s.empty_fraction = s.W_OEW  / W0;
    s.fuel_fraction  = s.W_fuel / W0;
    s.residual       = s.W0_new - W0;
end
