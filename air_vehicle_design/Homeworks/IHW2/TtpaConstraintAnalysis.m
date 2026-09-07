%% TtpaConstraintAnalysis.m
% Reference Solution - Homework 2
% Constraint (matching) analysis of the Test Twin Propeller Aircraft
%
% Builds on Homework 1: the same discipline objects, the same obj bundle,
% and the takeoff gross weight the mission analysis converges to. What is
% new is the constraint set, which the requirements file of IHW2 carries,
% and the wing loading and power loading the airplane must be designed to.
%
% Each step below is one of the functions written for this assignment:
%
%   get_con, get_state          one condition and its atmosphere
%   constraint_takeoff          takeoff ground roll
%   constraint_landing          landing ground roll
%   constraint_climb            the three FAR 23 climb gradients
%   constraint_cruise_speed     cruise speed
%   run_constraints             every condition, over the sweep
%   matching_envelope           the envelope, the wall and the best point
%   design_point_check          margins of a chosen point
%   size_from_design_point      wing area and installed power
%   plot_matching_diagram       the diagram

clear; clc; close all

%% ------------------------------------------------------------------------
% Load inputs
json_path = ttpa_requirements_path();

% The same bundle the mission analysis of IHW1 uses, with the constraint
% set added
obj  = ttpa_disciplines();
cons = obj.cons;

opts = struct('tol', 0.1, 'max_iter', 25);

disp('% -- Disciplines Loaded Successfully -- %')

%% ------------------------------------------------------------------------
% Takeoff gross weight, from the mission analysis of Homework 1

W_TO = 5000;   % initial guess, lbs

[W_TO_final, beta_mission, ~, fuel_fraction, empty_weight_fraction, ...
    ~, ~, segment_weight, ~] = missionAnalysis(obj, W_TO, opts);

% Weight fraction at the start of cruise, that is after startup, taxi,
% takeoff and the initial climb. The constraint conditions carry
% beta = 0.975 for the same point of the mission.
beta_start_cruise = segment_weight(end, 3) / W_TO_final;

fprintf('\n==========================================================\n');
fprintf('Mission analysis (Homework 1)\n');
fprintf('==========================================================\n');
fprintf('  Takeoff gross weight W_TO        : %8.1f lbs\n', W_TO_final);
fprintf('  Fuel fraction                    : %8.4f\n',     fuel_fraction);
fprintf('  Empty weight fraction            : %8.4f\n',     empty_weight_fraction);
fprintf('  Average weight fraction beta     : %8.4f\n',     beta_mission);
fprintf('  W/W_TO at the start of cruise    : %8.4f  (the conditions use 0.975)\n', ...
    beta_start_cruise);

%% ------------------------------------------------------------------------
% Wing-loading sweep of the matching diagram

J     = jsondecode(fileread(json_path));
range = J.constraints.wing_loading_range_psf;

WS = linspace(range(1), range(2), J.constraints.wing_loading_points);

%% ------------------------------------------------------------------------
% Every constraint condition, one by one

[WP_limits, WS_walls, names, types] = run_constraints(WS, obj);

%% ------------------------------------------------------------------------
% The matching envelope and the best point

[WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj);

%% ------------------------------------------------------------------------
% Two design points
%
% The BEST point is the corner of the feasible region that matching_envelope
% returns: it needs the smallest engine, and it sits exactly on the
% constraints, so it keeps no margin. The SELECTED design point comes from
% the requirements file, moved away from that corner as a factor of safety.

WS_opt = WS_best;
WP_opt = WP_best;

WS_pt = J.constraints.design_point.wing_loading_psf;
WP_pt = J.constraints.design_point.power_loading_lb_per_hp;

[feasible_opt, driving_opt, WP_margin_opt, WS_margin_opt] = ...
    design_point_check(WS_opt, WP_opt, obj);

[feasible, driving_pt, WP_margin, WS_margin] = ...
    design_point_check(WS_pt, WP_pt, obj);

%% ------------------------------------------------------------------------
% First wing and engine size, at the SELECTED design point

con_no_landing = find(types == "landing", 1);
con_landing    = get_con(con_no_landing, cons);

[S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = ...
    size_from_design_point(W_TO_final, WS_pt, WP_pt, obj, con_no_landing);

%% ------------------------------------------------------------------------
% Report

fprintf('\n==========================================================\n');
fprintf('Constraint limits at the design point (W/S = %.1f lbf/ft^2)\n', WS_pt);
fprintf('==========================================================\n');

for k = 1:numel(names)
    if ~isnan(WS_walls(k))
        fprintf('  %-14s wall   W/S <= %7.2f lbf/ft^2\n', names(k), WS_walls(k));
    else
        fprintf('  %-14s limit  W/P <= %7.2f lbf/hp\n', names(k), ...
            interp1(WS, WP_limits(k,:), WS_pt));
    end
end

fprintf('\n==========================================================\n');
fprintf('Best point of the feasible region (smallest engine)\n');
fprintf('==========================================================\n');
fprintf('  Wing loading  (W/S)_TO           : %8.2f lbf/ft^2\n', WS_opt);
fprintf('  Power loading (W/P)_TO           : %8.2f lbf/hp\n',   WP_opt);
fprintf('  Driving power condition          : %s\n',             driving_opt);
fprintf('  Power-loading margin             : %8.4f\n',          WP_margin_opt);
fprintf('  Wing-loading margin              : %8.4f\n',          WS_margin_opt);
fprintf('  This point sits ON the constraints, so it keeps no margin.\n');

fprintf('\n==========================================================\n');
fprintf('Selected design point (margin kept)\n');
fprintf('==========================================================\n');
fprintf('  Wing loading  (W/S)_TO           : %8.2f lbf/ft^2\n', WS_pt);
fprintf('  Power loading (W/P)_TO           : %8.2f lbf/hp\n',   WP_pt);
fprintf('  Driving power condition          : %s\n',             driving_pt);
fprintf('  Wing-loading wall                : %8.2f lbf/ft^2\n', WS_max);
fprintf('  Power-loading margin             : %8.4f\n',          WP_margin);
fprintf('  Wing-loading margin              : %8.4f\n',          WS_margin);

if feasible
    fprintf('  The design point meets every constraint.\n');
else
    fprintf('  WARNING: the design point violates a constraint.\n');
end

fprintf('\n==========================================================\n');
fprintf('First size from the selected design point\n');
fprintf('==========================================================\n');
fprintf('  Wing reference area S_ref        : %8.1f ft^2\n', S_ref);
fprintf('  Wing span b                      : %8.2f ft\n',   b);
fprintf('  Mean geometric chord             : %8.2f ft\n',   c_bar);
fprintf('  Takeoff power, all engines       : %8.1f hp\n',   P_TO);
fprintf('  Takeoff power per engine         : %8.1f hp\n',   P_engine);
fprintf('  Stall speed, landing flaps       : %8.1f kt\n',   Vs_L_kts);
fprintf('  Landing ground roll of that speed: %8.0f ft   (requirement %.0f ft)\n', ...
    s_LGR_check, con_landing.distance_ft);

%% ------------------------------------------------------------------------
% Final plot

points = struct( ...
    'WS',    {WS_opt, WS_pt}, ...
    'WP',    {WP_opt, WP_pt}, ...
    'label', {'Best point, smallest engine', 'Design point, margin kept'});

fig = plot_matching_diagram(WS, obj, points);
fig.Color = 'w';

%% Function: Main Mission Analysis
% Unchanged from Homework 1 (TtpaSizing.m), repeated here so that this
% script runs on its own.
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
    end

    beta = 1 - (sum(fuel_burned(ii,:)) / (2 * W_TO));
    W_TO_final = W_TO;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', 'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff'});
end
