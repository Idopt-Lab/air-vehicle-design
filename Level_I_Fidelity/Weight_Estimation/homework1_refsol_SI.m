%% homework1_refsol.m
% Reference Solution - Homework 1
% Computes takeoff gross weight and fuel burn factor (beta)

%clear; clc;

%% -------------------------------------------
% Load mission inputs
thisFolder   = fileparts(mfilename('fullpath'));
parentFolder = fileparts(thisFolder);
dataPath     = fullfile(parentFolder, 'F16', 'mission_inputs.mat');
load("mission_inputs.mat");
%load(dataPath);  % Loads: constraints, aero_constraints, thrust, TO, Landing

%% --------------------------------------------------
% Run analysis
[W_TO, beta, results_table, total_fuel_used, fuel_fraction, weight_fraction, empty_weight, W_Takeoff, W_Climb, W_Cruise, W_Dash, W_Combat, W_Cruise2, W_Loiter, W_Landing, f1, f2, f3, f4, f5, f6, f7, f8] = missionAnalysis(mission, propulsion, aero_mission, air, AR, W_fixed);

% Display output
fprintf('Final Takeoff Gross Weight (W_TO): %.2f N\n', W_TO);
fprintf('Fuel Efficiency Factor (beta): %.4f\n', beta);
disp(results_table);

%% --------------------------------------------------
% Function: Main Mission Analysis
function [W_TO, beta, results_table, total_fuel_used, fuel_fraction, weight_fraction, empty_weight, W_Takeoff, W_Climb, W_Cruise, W_Dash, W_Combat, W_Cruise2, W_Loiter, W_Landing, f1, f2, f3, f4, f5, f6, f7, f8] = missionAnalysis(mission, propulsion, aero_mission, air, AR, W_fixed)
    W_S = 104.59*47.880259;
    W_TO = 45000*4.44822162;
    tol = 1e-3;
    max_iteration = 40;
    results = [];

    for iteration = 1:max_iteration
        S = W_TO / W_S;
        total_fuel_used = 0;

        [W_Takeoff, f1] = segment_takeoff(W_TO);
        [W_Climb, f2]   = segment_climb(W_TO, W_Takeoff, mission.Climb.Mach);
        [W_Cruise, f3]  = segment_cruise(W_Climb, W_S, propulsion.Cruise.TSFC, mission.Cruise.Distance, mission.Cruise.Mach, air.Cruise.a, air.Cruise.q, aero_mission.Cruise.CD0, aero_mission.Cruise.e, AR, W_TO);
        [W_Dash, f4]    = segment_dash(W_Cruise, W_S, W_TO, air.Dash.q, aero_mission.Dash.CD0, aero_mission.Dash.e, AR, propulsion.Dash.TSFC, mission.Dash.Distance, mission.Dash.Mach * air.Dash.a);
        [W_Combat, f5]  = segment_combat(W_Dash, mission.Combat.Time_min, propulsion.Combat.TSFC, mission.Combat.DropPayload_kg, aero_mission.Combat.CD0, aero_mission.Combat.e, AR, W_TO, W_S, air.Combat.q);
        [W_Cruise2, f6] = segment_cruise(W_Combat, W_S, propulsion.Cruise2.TSFC, mission.Cruise2.Distance, mission.Cruise2.Mach, air.Cruise2.a, air.Cruise2.q, aero_mission.Cruise2.CD0, aero_mission.Cruise2.e, AR, W_TO);
        [W_Loiter, f7]  = segment_loiter(W_TO, W_Cruise2, W_S, air.Loiter.q, aero_mission.Loiter.CD0, aero_mission.Loiter.e, AR, mission.Loiter.Time_min, propulsion.Loiter.TSFC);
        [W_Landing, f8]         = segment_landing(W_Loiter, W_TO);

        total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8;

        fuel_fraction = total_fuel_used * 1.06 / W_TO;
        weight_fraction = 2.34 * W_TO^(-0.13);
        empty_weight = weight_fraction * W_TO;
        W_TO_new = W_fixed / (1 - fuel_fraction - weight_fraction);

        difference = W_TO_new - W_TO;
        percent_diff = 100 * difference / W_TO;

        results(end+1, :) = [W_TO, W_fixed, fuel_fraction, weight_fraction, empty_weight, W_TO_new, difference, percent_diff];

        if abs(difference) < tol
            break;
        end
        W_TO = W_TO_new;
    end

    beta = 1 - (total_fuel_used / (2 * W_TO));
    results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
end

%% --------------------------------------------------
% Supporting Functions

function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
    W_by_W_TO = W / W_TO;
    W_by_S = W_by_W_TO * W_S;
    LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
end

function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
    WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
end

%% --------------------------------------------------
% Segment Functions

function [W_out, fuel_used] = segment_takeoff(W_in)
    WF = 0.95;
    W_out = W_in * WF;
    fuel_used = W_in - W_out;
end

function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach)
    WF_Climb = 1.0065 - 0.0325 * Mach;
    fuel_used = (1 - WF_Climb) * W_in;
    W_out = W_in - fuel_used;
end

function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO)
    V = Mach * a;
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF = compute_weightfraction(TSFC, Distance, V, LD);
    fuel_used = W_in * (1 - WF);
    W_out = W_in - fuel_used;
end

function [W_out, fuel_used] = segment_dash(W_in, W_S, W_TO, q, CD0, e, AR, TSFC, Distance, V)
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF = compute_weightfraction(TSFC, Distance, V, LD);
    fuel_used = W_in * (1 - WF);
    W_out = W_in - fuel_used;
end

function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, W_S, q)
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR)
    WF = exp(-(time * 60 * TSFC / LD))
    fuel_used = W_in*(1-WF)
    W_out = W_in - fuel_used - payload;
end

function [W_out, fuel_used] = segment_loiter(W_TO, W_in, W_S, q, CD0, e, AR, time, TSFC)
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF = exp(-(time * 60 * TSFC / LD));
    fuel_used = W_in * (1 - WF);
    W_out = W_in - fuel_used;
end

function [W_out, fuel_used] = segment_landing(W_in, W_TO)
    WF = 0.995;
    fuel_used = W_in * (1 - WF);
    W_out = W_in - fuel_used;
end
