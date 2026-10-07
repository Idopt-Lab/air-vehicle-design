%% compare_iteration_methods.m
% Homework 1 - Iteration Methods
% Runs FixedPoint, Aitken_accel, Broyden and Newton, and compares their
% iterate, residual and convergence histories for the W_TO sizing equation
%   r(W) = g(W) - W = 0,   g(W) = W_payload / (1 - W_f/W - W_e/W)

% Code made by Quinn McIver
clear; clc; close all

%% ------------------------------------------------------------------------
% Paths and disciplines (used for the reference solution and final residuals)
here = fileparts(mfilename('fullpath'));
ihw1_dir = fileparts(here);
addpath(ihw1_dir);
json_path = fullfile(ihw1_dir, "Ttpa_requirements.json");
aero = TtpaAero(json_path);
geom = TtpaGeom();
prop = TtpaProp();
wts  = TtpaWeights();
miss = MissionProfileReader.read_profile(json_path,'std_mission');
obj = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, 'miss', miss);

tol = 0.001;              % lbf, the stopping tolerance in every method script
err_floor = 1e-7;       % lbf, errors below this are round-off, not convergence

%% ------------------------------------------------------------------------
% Run each method script
scripts = {'FixedPoint', 'Aitken_accel', 'Broyden', 'Newton'};
runs = cell(1, numel(scripts));
for m = 1:numel(scripts)
    runs{m} = run_method(fullfile(here, [scripts{m} '.m']));
end
clc

%% ------------------------------------------------------------------------
% Reference solution: Newton to round-off
W_ref = reference_solution(5000, obj);
fprintf('Reference solution (Newton to round-off): W_TO = %.6f lbs\n\n', W_ref);

%% ------------------------------------------------------------------------
% Build the histories that the plots and the summary use.
% Point j is the iterate W_j (j = 0 is the initial guess); cost(j) is the
% number of run_mission calls the method used to produce W_j.
hist = struct([]);
for m = 1:numel(runs)
    h = runs{m}.iter_hist;
    r_final = residual(h.W_final, obj);

    hist(m).method = h.method;
    hist(m).j      = (0:numel(h.W))';
    hist(m).W      = [h.W; h.W_final];
    hist(m).r      = [h.r; r_final];
    hist(m).cost   = [0; h.n_eval];
    hist(m).err    = abs(hist(m).W - W_ref);
    hist(m).n_iter = numel(h.k);
    hist(m).n_eval = h.n_eval(end);
    hist(m).n_diag = 0;
    hist(m).W_final = h.W_final;
    hist(m).r_final = r_final;
    hist(m).converged = h.converged;

    if isfield(h, 'W_acc')
        % Aitken: the accelerated sequence is the answer; the base fixed-point
        % sequence is kept for the dashed reference line. Its last point is
        % the last base iterate g(W_{K-1}), not the accelerated answer.
        W_base_last = h.g(end);
        hist(m).base = hist(m);
        hist(m).base.W   = [h.W; W_base_last];
        hist(m).base.r   = [h.r; residual(W_base_last, obj)];
        hist(m).base.err = abs(hist(m).base.W - W_ref);
        hist(m).n_diag = h.n_eval_diag;
        hist(m).j    = h.k_acc;
        hist(m).W    = h.W_acc;
        hist(m).r    = h.r_acc;
        hist(m).cost = h.n_eval_acc;
        hist(m).err  = abs(h.W_acc - W_ref);
    else
        hist(m).base = [];
    end
    hist(m).order = observed_order(hist(m).err, err_floor);
end

%% ------------------------------------------------------------------------
% Summary table
summary = table(string({hist.method})', [hist.n_iter]', [hist.n_eval]', [hist.n_diag]', ...
    [hist.W_final]', abs([hist.r_final])', abs([hist.W_final] - W_ref)', [hist.order]', [hist.converged]', ...
    'VariableNames', {'Method', 'Iterations', 'Mission_calls', 'Diagnostic_calls', ...
    'W_TO_final', 'Abs_residual', 'Abs_error_vs_ref', 'Observed_order', 'Converged'});
format longG
fprintf('Stopping rule: |W_{k+1} - W_k| < %.2g lbs (Aitken: successive accelerated values)\n', tol);
fprintf('Observed order p = log(e_{k+1}/e_k) / log(e_k/e_{k-1}), last three errors above %.0e lbs\n', err_floor);
disp(summary);

for m = 1:numel(hist)
    fprintf('\n-- %s iteration history --\n', hist(m).method);
    disp(table(hist(m).j, hist(m).cost, hist(m).W, hist(m).r, hist(m).err, ...
        'VariableNames', {'k', 'Mission_calls', 'W_TO', 'Residual', 'Abs_error'}));
end

%% ------------------------------------------------------------------------
% Plots
colors  = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100"];   % categorical slots 1-4
markers = {'o', 's', '^', 'd'};
ink_muted = [0.32 0.32 0.31];

fig = figure('Color', 'w', 'Position', [100 100 1150 820]);
tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'W_{TO} sizing loop: iteration method comparison', 'FontWeight', 'bold');

panels = {
    'Iterate history',                 'Iteration k',            'W_{TO} (lbs)',             'W',   'j',    false
    'Residual history',                'Iteration k',            '|r| = |g(W) - W| (lbs)',   'r',   'j',    true
    'Residual vs. cost',               'run\_mission calls',     '|r| = |g(W) - W| (lbs)',   'r',   'cost', true
    'Convergence (error vs. reference)','Iteration k',           '|W_k - W_{ref}| (lbs)',    'err', 'j',    true
    };

h_leg = gobjects(0);
leg_txt = {};
for p = 1:size(panels, 1)
    ax = nexttile(tl);
    hold(ax, 'on');
    [ttl, xl, yl, yfield, xfield, use_log] = panels{p, :};

    for m = 1:numel(hist)
        x = hist(m).(xfield);
        y = hist(m).(yfield);
        if use_log, y = abs(y); y(y == 0) = NaN; end

        if ~isempty(hist(m).base)
            xb = hist(m).base.(xfield);
            yb = hist(m).base.(yfield);
            if use_log, yb = abs(yb); yb(yb == 0) = NaN; end
            hb = plot(ax, xb, yb, '--', 'Color', colors(m), 'LineWidth', 1);
            if p == 1
                h_leg(end+1) = hb; %#ok<SAGROW>
                leg_txt{end+1} = [hist(m).method ' base sequence']; %#ok<SAGROW>
            end
        end

        hm = plot(ax, x, y, '-', 'Color', colors(m), 'LineWidth', 2, ...
            'Marker', markers{m}, 'MarkerSize', 7, 'MarkerFaceColor', colors(m), ...
            'MarkerEdgeColor', 'w');
        if p == 1
            h_leg(end+1) = hm; %#ok<SAGROW>
            leg_txt{end+1} = hist(m).method; %#ok<SAGROW>
        end
    end

    if p == 1
        % Zoom on the converging part; the common start W_0 is below the axis
        yline(ax, W_ref, ':', sprintf('W_{ref} = %.2f', W_ref), 'Color', ink_muted, ...
            'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'top');
        ylim(ax, W_ref + [-25 60]);
        text(ax, 0.98, 0.95, sprintf('All methods start at W_0 = %.0f lbs (below axis)', hist(1).W(1)), ...
            'Units', 'normalized', 'HorizontalAlignment', 'right', 'Color', ink_muted);
    else
        yline(ax, tol, ':', sprintf('tol = %.3f lbs', tol), 'Color', ink_muted, ...
            'LabelHorizontalAlignment', 'right');
    end

    if use_log, set(ax, 'YScale', 'log'); end
    grid(ax, 'on');
    set(ax, 'GridAlpha', 0.12, 'MinorGridAlpha', 0.05, 'Box', 'off', ...
        'XColor', ink_muted, 'YColor', ink_muted);
    title(ax, ttl);
    xlabel(ax, xl);
    ylabel(ax, yl);
end

lg = legend(h_leg, leg_txt, 'Orientation', 'horizontal', 'Box', 'off');
lg.Layout.Tile = 'south';

out_dir = fullfile(here, 'output');
if ~isfolder(out_dir), mkdir(out_dir); end
png_path = fullfile(out_dir, 'iteration_methods_comparison.png');
exportgraphics(fig, png_path, 'Resolution', 200);
fprintf('\nFigure saved: %s\n', png_path);

%% Function: Run one method script and collect its outputs
% The script runs in this function's workspace, so its "clear" does not
% remove the comparison data in the base workspace.
function out = run_method(script_path)
    run(script_path);
    out.iter_hist     = eval('iter_hist');
    out.W_TO_final    = eval('W_TO_final');
    out.results_table = eval('results_table');
end

%% Function: Residual r(W) = g(W) - W (same equations as eval_g in the method scripts)
function r = residual(W_TO, obj)
    fuel_burned = run_mission(W_TO, obj);
    fuel_fraction = sum(fuel_burned) * 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
    empty_weight_fraction = obj.wts.OEW(W_TO) / W_TO;
    r = obj.wts.W_payload_fixed / (1 - fuel_fraction - empty_weight_fraction) - W_TO;
end

%% Function: Reference root, Newton with a central difference, to round-off
function W = reference_solution(W, obj)
    for ii = 1:50
        h = 1e-4 * W;
        drdW = (residual(W + h, obj) - residual(W - h, obj)) / (2*h);
        dW = -residual(W, obj) / drdW;
        W = W + dW;
        if abs(dW) < 1e-10 * W
            return
        end
    end
    warning('compare:refNoConvergence', 'Reference Newton solve did not converge.');
end

%% Function: Observed order of convergence from the last three errors above the floor
function p = observed_order(err, err_floor)
    last = find(err <= err_floor, 1) - 1;
    if isempty(last), last = numel(err); end
    e = err(1:last);
    p = NaN;
    if numel(e) >= 3
        p = log(e(end)/e(end-1)) / log(e(end-1)/e(end-2));
    end
end
