%% Mission Profile Calculation
function [fuel_burned, segment_weight, segment_wf] = run_mission(W_TO, obj)
        [W1, f1, WF1] = segment_takeoff(W_TO, obj, 1);
        
        [W2, f2, WF2] = segment_climb(W1, obj, 2);

        [W3, f3, WF3] = segment_cruise(W2, obj, 3);

        [W4, f4, WF4] = segment_descent(W3, obj, 4);

        [W5, f5, WF5] = segment_climb(W4, obj, 5);

        [W6, f6, WF6] = segment_loiter(W5, obj, 6);

        [W7, f7, WF7] = segment_descent(W6, obj, 7);

        [W8, f8, WF8] = segment_landing(W7, obj, 8);

        
        fuel_burned = [f1, f2, f3, f4, f5, f6, f7, f8];
        segment_weight = [W_TO, W1, W2, W3, W4, W5, W6, W7, W8];
        segment_wf = [WF1, WF2, WF3, WF4, WF5, WF6, WF7, WF8];

end

%% Supporting Functions
% Simplified WF calculation function
function [fuel_used, W_out] = simple_WF(WF, W_in)
    fuel_used = (1 - WF) * W_in;
    W_out = W_in * WF;
end


function [ft_s] = ktas2ft_s(ktas)
    ft_s = ktas*6076.115/3600;
end

%% Segment Functions 
% Takeoff
function [W_out, fuel_used, WF] = segment_takeoff(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    % Includes Startup, Taxi and Takeoff
    WF = 0.984; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Climb
function [W_out, fuel_used, WF] = segment_climb(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    WF = 0.990; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Cruise
function [W_out, fuel_used, WF] = segment_cruise(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    range = state.dist*1.15077945; % nm -> mi
    eta_p = obj.prop.prop_eff(state);
    WF = exp(-range*obj.prop.C_bhp/(375*eta_p*obj.aero.LD_max)); % Distance must be in MILES
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Descent
function [W_out, fuel_used, WF] = segment_descent(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    WF = 0.992; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Loiter
function [W_out, fuel_used, WF] = segment_loiter(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    % -- VERIFY THAT INPUTS MATCH UNITS -- %
    time = state.time_min/60; %min -> hr 
    V = ktas2ft_s(state.ktas);
    LD = 0.866 * obj.aero.LD_max;
    eta_p = obj.prop.prop_eff(state);
    WF = exp(-time*V*obj.prop.C_bhp/(LD*550*eta_p)); % Velocity must be in ft/s and time in Hrs
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Landing
function [W_out, fuel_used, WF] = segment_landing(W_in, obj, seg_no)
    state = update_state(seg_no, obj.miss);
    % Includes: Landing, Taxi and Shutdown
    WF = 0.992; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

