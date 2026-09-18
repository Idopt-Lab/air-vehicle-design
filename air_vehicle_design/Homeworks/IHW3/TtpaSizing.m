%% TtpaSizing.m
% Reference Solution - Homework 1
% Computes takeoff gross weight and fuel burn factor (beta)

% Code made by Quinn McIver
clear; clc; close all

%% ------------------------------------------------------------------------
% Load inputs
cd .. 
cd IHW3_a
obj = ttpa_disciplines;
json_path = ttpa_requirements_path();

opts = struct('tol', 0.1, 'max_iter', 25);

disp('% -- Disciplines Loaded Successfully -- %')
%% ------------------------------------------------------------------------
% Run analysis

% Initial Weight Guesses based on RFP and Market Analysis
W_TO = 5000;  % Vehicle Weight
P_SL = 550;   % Sea Level Shaft Power [hp]

[W_TO_final, results_table, fuel_fraction,...
empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf]...
    = missionAnalysis(obj, W_TO, P_SL, json_path, opts);

% Display output
fprintf('----------------------------------------------------------\n')
fprintf('Final Takeoff Gross Weight (W_TO): %.2f lbs\n', W_TO_final);
disp(results_table);

%% Function: Main Mission Analysis
function [W_TO_final, results_table, fuel_fraction,...
    empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf]...
    = missionAnalysis(obj, W_TO, P_SL, json_path, opts)
    
    results = [];

    % ---------------------------------------------------------------------
    % Iteration Loop
    for ii = 1:opts.max_iter       

        % -----------------------------------------------------------------
        % Constraint Analysis Call
        J     = jsondecode(fileread(json_path));
        range = J.constraints.wing_loading_range_psf;
        WS = linspace(range(1), range(2), J.constraints.wing_loading_points);

        % Tell Disciplines what W_TO and P_SL guesses are
        obj.wts.W_TO = W_TO;
        obj.prop.P_SL = P_SL;

        [WP_limits, WS_walls, names, types] = run_constraints(WS, obj);
        [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj);
    
        WS_opt = WS_best;
        WP_opt = WP_best;

        obj.geom.S_ref = W_TO/WS_opt;
        obj.prop.P_SL  = P_SL/WP_opt;
    
        % [feasible_opt, driving_opt, WP_margin_opt, WS_margin_opt] = ...
        % design_point_check(WS_opt, WP_opt, obj);


        
                
        [fuel_burned(ii,:), segment_weight(ii,:), segment_wf(ii,:)] = run_mission(W_TO, obj);

        fuel_fraction = sum(fuel_burned(ii,:))* 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
        fuel_weight = fuel_fraction*W_TO;
        
        empty_weight = obj.wts.W_empty;
        empty_weight_fraction = empty_weight/W_TO;
        
        
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

    if ii == opts.max_iter
        fprintf('Max Iteration Reached')
    end

    W_TO_final = W_TO;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', 'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff'});
end

