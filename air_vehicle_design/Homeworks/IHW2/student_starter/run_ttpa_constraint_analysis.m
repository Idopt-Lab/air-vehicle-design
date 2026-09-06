%% run_ttpa_constraint_analysis.m
% IHW2 - Constraint (matching) analysis of the Test Twin Propeller Aircraft
%
% Runs the twelve functions of this homework end to end. Fill in the twelve
% files first; this script needs no editing except the takeoff weight in the
% first section.
%
% This is the constraint twin of the TtpaSizing.m script of IHW1.

clear; clc; close all

%% ------------------------------------------------------------------------
% Load inputs
json_path = ttpa_requirements_path();

obj  = ttpa_disciplines();
cons = obj.cons;

disp('% -- Disciplines Loaded Successfully -- %')

%% ------------------------------------------------------------------------
% Takeoff gross weight
%
% The design point is a pair of RATIOS. A weight turns it into an airplane,
% and that weight is the one your mission analysis of IHW1 converged to.
%
% Either paste your IHW1 missionAnalysis function at the bottom of this file
% and uncomment the two lines below, or leave the fixed value in place.

W_TO_final = 5354;   % lbf, from the IHW1 mission analysis

% opts = struct('tol', 0.1, 'max_iter', 25);
% W_TO_final = missionAnalysis(obj, 5000, opts);

fprintf('\nTakeoff gross weight W_TO : %.1f lbs\n', W_TO_final);

%% ------------------------------------------------------------------------
% Wing-loading sweep, from the requirements file

J     = jsondecode(fileread(json_path));
range = J.constraints.wing_loading_range_psf;

WS = linspace(range(1), range(2), J.constraints.wing_loading_points);

%% ------------------------------------------------------------------------
% Every condition, then the envelope

[WP_limits, WS_walls, names, types] = run_constraints(WS, obj);

[WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj);

%% ------------------------------------------------------------------------
% Two design points
%
% The BEST point is the corner of the feasible region: the smallest engine
% the requirements permit, sitting exactly on the constraints with no margin.
% The SELECTED design point comes from the requirements file, moved away from
% that corner as a factor of safety.

WS_pt = J.constraints.design_point.wing_loading_psf;
WP_pt = J.constraints.design_point.power_loading_lb_per_hp;

[feasible_best, driving_best, WP_margin_best, WS_margin_best] = ...
    design_point_check(WS_best, WP_best, obj);

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
fprintf('  Wing loading  (W/S)_TO           : %8.2f lbf/ft^2\n', WS_best);
fprintf('  Power loading (W/P)_TO           : %8.2f lbf/hp\n',   WP_best);
fprintf('  Driving power condition          : %s\n',             driving_best);
fprintf('  Power-loading margin             : %8.4f\n',          WP_margin_best);
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
% The matching diagram

points = struct( ...
    'WS',    {WS_best, WS_pt}, ...
    'WP',    {WP_best, WP_pt}, ...
    'label', {'Best point, smallest engine', 'Design point, margin kept'});

fig = plot_matching_diagram(WS, obj, points);
fig.Color = 'w';

%% ------------------------------------------------------------------------
% Paste your IHW1 missionAnalysis function below this line, if you want the
% takeoff weight to come from your own mission analysis instead of the fixed
% value at the top.
