function fig = plot_trend_row(T, band)
%PLOT_TREND_ROW  One row of Nicolai Table 7.1 for the 737: six panels.
%
%   fig = PLOT_TREND_ROW(T) draws each metric of a trend_737 result,
%   divided by its baseline value: Level 3 (solid) and Level 2 (dashed).
%   The grey strip is the "no effect" band (default +/-3 %). Each panel
%   title shows Nicolai's arrow and the Level-3 arrow.
%   fig = PLOT_TREND_ROW(T, band) uses another band (fraction).

    arguments
        T    (1,1) struct
        band (1,1) double {mustBePositive} = 0.03
    end

    nic   = book_data().table7_1;
    row   = find(nic.rows == T.var);
    cols7 = ["CD0_sub", "K", "CL_alpha", "CL_max", "Wing_wt", "Wing_vol"];
    ttl   = ["C_{D0} subsonic", "K", "C_{L\alpha}", "C_{Lmax}", "Wing weight", "Wing volume"];

    fig = new_figure([60 60 1150 640]);
    tl  = tiledlayout(fig, 2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(tl, "737 MAX 8: increase in " + T.var + "   (solid: Level 3, dashed: Level 2)", ...
          'FontWeight', 'bold');

    for k = 1:6
        ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');
        y3 = T.L3{:,k}'/T.base3(k);
        y2 = T.L2{:,k}'/T.base2(k);
        fill(ax, [T.x(1) T.x(end) T.x(end) T.x(1)], [1-band 1-band 1+band 1+band], ...
             [0.9 0.9 0.9], 'EdgeColor', 'none', 'HandleVisibility', 'off');
        if all(isnan(y3))
            text(ax, 0.5, 0.5, "no model", 'Units', 'normalized', ...
                 'HorizontalAlignment', 'center', 'FontSize', 12);
        else
            plot(ax, T.x, y3, '-', 'LineWidth', 2.0);
        end
        if ~all(isnan(y2))
            plot(ax, T.x, y2, '--', 'LineWidth', 1.2);
        end
        xline(ax, T.xb, ':', 'baseline', 'LabelVerticalAlignment', 'bottom');
        want = nic.arrow(row, nic.cols == cols7(k));
        got  = classify_trend(T.L3{:,k}', T.base3(k), band);
        title(ax, ttl(k) + "   Nicolai: " + arrow_text(want) + ",  model: " + arrow_text(got));
        xlabel(ax, T.xlabel);  ylabel(ax, 'value / baseline');
    end
end

function s = arrow_text(a)
    switch a
        case "^",  s = "↑";
        case "v",  s = "↓";
        case "v^", s = "↓↑";
        case "^v", s = "↑↓";
        case "0",  s = "no effect";
        otherwise, s = "—";
    end
end
