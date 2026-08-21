%% homework1_refsol.m
% Reference Solution - Homework 1
% Computes takeoff gross weight and fuel burn factor (beta)

% Code made by Quinn McIver
clear; clc; close all

%% ------------------------------------------------------------------------
% Load inputs
json_path = fullfile("Ttpa_requirements.json");
aero = TtpaAero(json_path);
geom = TtpaGeom;
prop = TtpaProp;
wts  = TtpaWeights;
miss = MissionProfileReader.read_profile(json_path,'std_mission');

obj = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, 'miss', miss);

opts = struct('tol', 0.1, 'max_iter', 25);

disp('% -- Disciplines Loaded Successfully -- %')
%% ------------------------------------------------------------------------
% Run analysis

% Initial Weight Guesses based on RFP and Market Analysis
W_TO = 5000;  % Vehicle Weight

[W_TO_final, beta, results_table, fuel_fraction,...
empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf]...
    = missionAnalysis(obj, W_TO, opts);

% Display output
fprintf('----------------------------------------------------------\n')
fprintf('Final Takeoff Gross Weight (W_TO): %.2f lbs\n', W_TO_final);
disp(results_table);

%% Function: Main Mission Analysis
function [W_TO_final, beta, results_table, fuel_fraction,...
    empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf]...
    = missionAnalysis(obj, W_TO, opts)
    
    results = [];
    % ---------------------------------------------------------------------
    % Iteration Loop
    for ii = 1:opts.max_iter       
                
        [W1, f1, WF1] = segment_takeoff(W_TO, obj, 1);
        
        [W2, f2, WF2] = segment_climb(W1, obj, 2);

        [W3, f3, WF3] = segment_cruise(W2, obj, 3);

        [W4, f4, WF4] = segment_descent(W3, obj, 4);

        [W5, f5, WF5] = segment_climb(W4,obj, 5);

        [W6, f6, WF6] = segment_loiter(W5, obj, 6);

        [W7, f7, WF7] = segment_descent(W6, obj, 7);

        [W8, f8, WF8] = segment_landing(W7, obj, 8);

        
        fuel_burned(ii, :) = [f1, f2, f3, f4, f5, f6, f7, f8];
        segment_weight(ii, :) = [W_TO, W1, W2, W3, W4, W5, W6, W7, W8];
        segment_wf(ii, :) = [WF1, WF2, WF3, WF4, WF5, WF6, WF7, WF8];

        fuel_fraction = sum(fuel_burned(ii,:))* 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
        empty_weight_fraction = 0.911 * W_TO^(-0.053); % Nicolai's Light Prop Airplane WF
        empty_weight = empty_weight_fraction * W_TO;
        fuel_weight = fuel_fraction*W_TO;

        W_TO_new = obj.wts.W_payload_fixed / (1 - fuel_fraction - empty_weight_fraction);
        difference = W_TO_new - W_TO;
        percent_diff = 100 * difference / W_TO;

        results(end+1, :) = [W_TO, empty_weight, fuel_weight, empty_weight_fraction, fuel_fraction, W_TO_new, difference, percent_diff];

        if abs(difference) < opts.tol
            break;
        end

        W_TO = W_TO_new;
        % disp(fuel_burned)
    end

    beta = 1 - (sum(fuel_burned) / (2 * W_TO));
    W_TO_final = W_TO;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', 'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff'});
end

%% Supporting Functions
% Simplified WF calculation function
function [fuel_used, W_out] = simple_WF(WF, W_in)
    fuel_used = (1 - WF) * W_in;
    W_out = W_in * WF;
end

function [state] = update_state(seg_no, miss)
    state.seg_type = miss.segments(seg_no).type;
    state.alt = miss.segments(seg_no).alt_ft;
    state.ktas = miss.segments(seg_no).ktas;
    state.time_min = miss.segments(seg_no).time_min;
    state.dist = miss.segments(seg_no).distance_nm;
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
    eta_p = obj.prop.compute_eta_p(state);
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
    eta_p = obj.prop.compute_eta_p(state);
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

