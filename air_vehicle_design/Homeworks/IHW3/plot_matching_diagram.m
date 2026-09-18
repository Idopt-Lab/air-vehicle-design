function [fig] = plot_matching_diagram(WS, obj, points)
%PLOT_MATCHING_DIAGRAM  Matching diagram of the TTPA airplane.
%
%   fig = plot_matching_diagram(WS, obj)
%   fig = plot_matching_diagram(WS, obj, points)
%
%   Inputs
%     WS      takeoff wing loading sweep (W/S)_TO [lbf/ft^2], 1xM
%     obj     discipline bundle from ttpa_disciplines
%     points  optional 1xP struct array of points to mark, with fields
%               WS     wing loading of the point [lbf/ft^2]
%               WP     power loading of the point [lbf/hp]
%               label  legend entry of the point
%   Output
%     fig     figure handle
%
%   One curve per condition that limits the power loading, one vertical
%   dashed line per condition that limits the wing loading, the feasible
%   region shaded, and every point of points marked. The feasible region of
%   a propeller-driven airplane is BELOW the power-loading envelope and
%   LEFT of the wing-loading wall.
%
%   Two points are usually marked: the corner of the feasible region, which
%   needs the smallest engine, and the point the designer selects, which is
%   moved away from that corner to keep a margin.

    if nargin < 3
        points = struct('WS', {}, 'WP', {}, 'label', {});
    end

    WS = reshape(WS, 1, []);

    [WP_limits, WS_walls, names] = run_constraints(WS, obj);
    [WP_env, WS_max]             = matching_envelope(WS, obj);

    % Vertical range: twice the largest power loading the envelope allows,
    % which keeps every curve of the diagram readable
    y_max = 2 * max(WP_env);

    fig = figure('Name', 'Matching Diagram');
    ax  = axes(fig);
    hold(ax, 'on');

    % Feasible region
    is_feasible = WS <= WS_max;
    WS_f        = WS(is_feasible);
    WP_f        = min(WP_env(is_feasible), y_max);

    fill(ax, [WS_f, fliplr(WS_f)], [zeros(size(WP_f)), fliplr(WP_f)], ...
        [0.60 0.85 0.60], 'FaceAlpha', 0.25, 'EdgeColor', 'none', ...
        'DisplayName', 'Feasible region');

    % One curve or one wall per condition
    colors = lines(numel(names));

    for k = 1:numel(names)

        if ~isnan(WS_walls(k))
            xline(ax, WS_walls(k), '--', 'LineWidth', 2, ...
                'Color', colors(k,:), 'DisplayName', names(k));
        else
            plot(ax, WS, WP_limits(k,:), 'LineWidth', 2, ...
                'Color', colors(k,:), 'DisplayName', names(k));
        end

    end

    % Marked points
    markers = {'o', 'p', 's', 'd'};
    faces   = {[0.20 0.80 0.20], [1.00 0.90 0.10], [0.30 0.75 0.95], [0.95 0.55 0.20]};
    sizes   = [10, 16, 11, 11];

    for k = 1:numel(points)

        m = mod(k-1, numel(markers)) + 1;

        plot(ax, points(k).WS, points(k).WP, ['k' markers{m}], ...
            'MarkerSize', sizes(m), 'MarkerFaceColor', faces{m}, ...
            'DisplayName', sprintf('%s (W/S=%.1f, W/P=%.2f)', ...
            points(k).label, points(k).WS, points(k).WP));

    end

    xlabel(ax, 'Wing Loading W_{TO}/S [lbf/ft^2]');
    ylabel(ax, 'Power Loading W_{TO}/P [lbf/hp]');
    title(ax, 'Matching Diagram for the TTPA Airplane');
    legend(ax, 'Location', 'northeastoutside');
    grid(ax, 'on');
    xlim(ax, [min(WS), max(WS)]);
    ylim(ax, [0, y_max]);
    hold(ax, 'off');

end
