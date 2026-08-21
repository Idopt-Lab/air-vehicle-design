%% TtpaSizing.m
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
                
        [fuel_burned(ii,:), segment_weight(ii,:), segment_wf(ii,:)] = run_mission(W_TO, obj);

        fuel_fraction = sum(fuel_burned(ii,:))* 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
        fuel_weight = fuel_fraction*W_TO;
        
        empty_weight = obj.wts.OEW(W_TO);
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

    beta = 1 - (sum(fuel_burned(ii,:)) / (2 * W_TO));
    W_TO_final = W_TO;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', 'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff'});
end

