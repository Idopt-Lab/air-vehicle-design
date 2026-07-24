%% run_F16_constraint_diagram_overlay
%   Plot Deliverable #2 (docs/subplans/06_constraint_analysis.md): builds the
%   F-16's constraint set at L1, L2, and L3 fidelity (F16ConstraintSet,
%   reading Constraints.xlsx) and overlays all three constraint envelopes --
%   plus each fidelity's optimum design point -- on one figure, to show
%   fidelity sensitivity of the design point.
%
%   Plots the envelope curve per level (TW_envelope(WS) = max_i
%   required_TW_i(WS), see ConstraintAnalysis.m's header), not all 8
%   individual constraint curves per level -- 24 curves on one figure would
%   be unreadable, and the envelope is exactly what optimal_point() reduces
%   to for the design-point decision.
%
%   The envelope goes to Inf past a wall constraint's (e.g. Landing) W/S
%   limit -- plotted as-is, MATLAB would stretch the y-axis to Inf and
%   flatten every curve. As in ConstraintAnalysis.plot_diagram(), Inf is
%   capped at a common ceiling (headroom above the largest finite value
%   across all three levels) before plotting.
%
%   Includes Stall (F16ConstraintSet's 9th, sanity-check-only condition --
%   not one of Constraints.xlsx's 8 rows, no Brandt reference row exists for
%   it) alongside the 8 Constraints.xlsx-derived conditions.

levels = ["L1", "L2", "L3"];
colors = lines(numel(levels));

WS_range = PointPerformanceBase.WS_RANGE_BRANDT;
cas      = cell(1, numel(levels));
for i = 1:numel(levels)
    constraints = F16ConstraintSet.build(levels(i));
    cas{i} = ConstraintAnalysis(constraints, WS_range);
end

y_max = 0;
for i = 1:numel(levels)
    [~, TW_opt] = cas{i}.optimal_point();
    env = cas{i}.envelope();
    y_max = max([y_max, TW_opt, env(isfinite(env))]);
end
y_max = 1.15 * y_max;

fig = figure('Name', 'F-16 Constraint Diagram -- Fidelity Overlay');
ax  = axes(fig);
hold(ax, 'on');

for i = 1:numel(levels)
    [WS_opt, TW_opt] = cas{i}.optimal_point();
    env_capped = min(cas{i}.envelope(), y_max);

    plot(ax, WS_range, env_capped, 'LineWidth', 2, 'Color', colors(i,:), ...
        'DisplayName', sprintf('%s envelope', levels(i)));
    plot(ax, WS_opt, TW_opt, 'o', 'MarkerSize', 9, 'Color', colors(i,:), ...
        'MarkerFaceColor', colors(i,:), 'MarkerEdgeColor', 'k', ...
        'DisplayName', sprintf('%s optimum (W/S=%.1f, T/W=%.3f)', levels(i), WS_opt, TW_opt));

    fprintf('%s optimum design point: W/S = %.2f lbf/ft^2, T/W = %.4f\n', levels(i), WS_opt, TW_opt);
end

xlabel(ax, 'Wing Loading W_{TO}/S [lbf/ft^2]');
ylabel(ax, 'Thrust-to-Weight Ratio T/W');
title(ax, 'F-16 Constraint Envelope -- Fidelity Sensitivity (L1 vs L2 vs L3)');
legend(ax, 'Location', 'northeastoutside');
grid(ax, 'on');
ylim(ax, [0, y_max]);
hold(ax, 'off');
