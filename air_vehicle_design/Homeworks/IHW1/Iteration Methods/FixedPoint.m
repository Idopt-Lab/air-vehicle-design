%% FixedPoint.m
% Homework 1 - Iteration Methods
% Solves the takeoff gross weight sizing equation by fixed-point iteration:
%   W_{k+1} = g(W_k),   g(W) = W_payload / (1 - W_f/W - W_e/W)

% Code made by Quinn McIver
clear; clc; close all

%% ------------------------------------------------------------------------
% Load inputs
ihw1_dir = fileparts(fileparts(mfilename('fullpath')));  % IHW1/ holds the disciplines
addpath(ihw1_dir);
json_path = fullfile(ihw1_dir, "Ttpa_requirements.json");
aero = TtpaAero(json_path);
geom = TtpaGeom();
prop = TtpaProp();
wts  = TtpaWeights();
miss = MissionProfileReader.read_profile(json_path,'std_mission');

obj = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, 'miss', miss);

opts = struct('tol', 0.001, 'max_iter', 25);

disp('% -- Disciplines Loaded Successfully -- %')
%% ------------------------------------------------------------------------
% Run analysis

% Initial Weight Guesses based on RFP and Market Analysis
W_TO = 5000;  % Vehicle Weight

[W_TO_final, results_table, fuel_fraction,...
empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf, iter_hist]...
    = missionAnalysis(obj, W_TO, opts);

% Display output
fprintf('----------------------------------------------------------\n')
fprintf('Method: %s\n', iter_hist.method);
fprintf('Final Takeoff Gross Weight (W_TO): %.2f lbs\n', W_TO_final);
fprintf('Iterations: %d, run_mission calls: %d\n', numel(iter_hist.k), iter_hist.n_eval(end));
disp(results_table);

%% Function: Main Mission Analysis
function [W_TO_final, results_table, fuel_fraction,...
    empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf, iter_hist]...
    = missionAnalysis(obj, W_TO, opts)

    results = [];
    iter_hist = struct('method', 'Fixed point', 'k', [], 'W', [], 'g', [], 'r', [], ...
                       'dW', [], 'n_eval', [], 'W_final', NaN, 'converged', false);
    n_eval = 0;
    % ---------------------------------------------------------------------
    % Iteration Loop
    for ii = 1:opts.max_iter

        ev = eval_g(W_TO, obj);
        n_eval = n_eval + 1;
        fuel_burned(ii,:) = ev.fuel_burned;
        segment_weight(ii,:) = ev.segment_weight;
        segment_wf(ii,:) = ev.segment_wf;

        % Fixed-point update: W_{k+1} = g(W_k)
        W_TO_new = ev.g;

        [results, iter_hist] = record_iter(results, iter_hist, ii, W_TO, ev, W_TO_new, n_eval);

        difference = W_TO_new - W_TO;
        W_TO = W_TO_new;
        if abs(difference) < opts.tol
            iter_hist.converged = true;
            break;
        end
    end

    if ~iter_hist.converged
        warning('FixedPoint:noConvergence', ...
            'Fixed point did not converge in %d iterations.', opts.max_iter);
    end

    fuel_fraction = ev.fuel_fraction;
    empty_weight = ev.empty_weight;
    empty_weight_fraction = ev.empty_weight_fraction;

    W_TO_final = W_TO;
    iter_hist.W_final = W_TO_final;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', ...
        'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff', 'Residual', 'N_eval'});
end

%% Function: Evaluate the TOGW update g(W) and the residual r(W) = g(W) - W
function ev = eval_g(W_TO, obj)
    [fuel_burned, segment_weight, segment_wf] = run_mission(W_TO, obj);

    ev.fuel_fraction = sum(fuel_burned) * 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
    ev.fuel_weight = ev.fuel_fraction * W_TO;

    ev.empty_weight = obj.wts.OEW(W_TO);
    ev.empty_weight_fraction = ev.empty_weight / W_TO;

    ev.g = obj.wts.W_payload_fixed / (1 - ev.fuel_fraction - ev.empty_weight_fraction);
    ev.r = ev.g - W_TO;

    ev.fuel_burned = fuel_burned;
    ev.segment_weight = segment_weight;
    ev.segment_wf = segment_wf;
end

%% Function: Record one iteration in the results table and the history
function [results, iter_hist] = record_iter(results, iter_hist, k, W_TO, ev, W_TO_new, n_eval)
    difference = W_TO_new - W_TO;
    percent_diff = 100 * difference / W_TO;
    results(end+1, :) = [W_TO, ev.empty_weight, ev.fuel_weight, ev.empty_weight_fraction, ...
        ev.fuel_fraction, W_TO_new, difference, percent_diff, ev.r, n_eval];

    iter_hist.k(end+1,1) = k;
    iter_hist.W(end+1,1) = W_TO;
    iter_hist.g(end+1,1) = ev.g;
    iter_hist.r(end+1,1) = ev.r;
    iter_hist.dW(end+1,1) = abs(difference);
    iter_hist.n_eval(end+1,1) = n_eval;
end
