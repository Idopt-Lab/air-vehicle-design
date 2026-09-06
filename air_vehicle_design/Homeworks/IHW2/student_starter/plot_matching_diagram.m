function [fig] = plot_matching_diagram(WS, obj, points)
% Matching diagram of the TTPA airplane.
% run_constraints and matching_envelope are on the path.
%
% points - optional 1xP struct array with fields WS, WP, label

if nargin < 3
    points = struct('WS', {}, 'WP', {}, 'label', {});
end

WS = reshape(WS, 1, []);

% --- Milestone 1: the curves, the walls and the envelope ---
[WP_limits, WS_walls, names] = ;
[WP_env, WS_max]             = ;

y_max = 2 * max(WP_env);

fig = figure('Name', 'Matching Diagram');
ax  = axes(fig);
hold(ax, 'on');

% --- Milestone 2: shade the feasible region FIRST, so the curves sit on top ---


% --- Milestone 3: one curve per power condition, one dashed line per wall ---
for k = 1:numel(names)

end

% --- Milestone 4: mark every point of points ---
for k = 1:numel(points)

end

xlabel(ax, '');
ylabel(ax, '');
title(ax, '');
legend(ax, 'Location', 'northeastoutside');
grid(ax, 'on');
xlim(ax, [min(WS), max(WS)]);
ylim(ax, [0, y_max]);
hold(ax, 'off');

end
