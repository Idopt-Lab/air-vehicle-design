function [fig] = plot_sizing_convergence(result)
%PLOT_SIZING_CONVERGENCE  Convergence history of the sizing loop.
%
%   fig = plot_sizing_convergence(result)
%
%   result is the struct sizing_loop returns. Four panels:
%
%     1  takeoff weight against iteration, with the converged value
%     2  installed power against iteration
%     3  the two relative residuals, on a log scale, with the tolerance
%     4  the useful-load fraction - the closure denominator - which is the
%        margin the whole design hangs on. If it ever reaches zero the loop
%        stops, so watching it approach its converged value is the clearest
%        picture of whether the design closes comfortably or barely.
%
%   Read panel 3 first. A straight line on the log scale means the fixed
%   point is being approached at a steady rate; a flat line means the loop
%   has stalled; a rising line means the relaxation factor is too large.

    arguments
        result (1,1) struct
    end

    h = result.history;

    it    = [h.iter];
    W     = [h.W_TO];
    P     = [h.P_SL];
    resW  = [h.res_W];
    resP  = [h.res_P];
    denom = [h.denom];

    fig = figure('Name', 'TTPA sizing convergence', 'Color', 'w');
    tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

    % --- takeoff weight -------------------------------------------------
    nexttile;
    plot(it, W, '-o', 'LineWidth', 1.4, 'MarkerSize', 4); hold on;
    yline(result.W_TO, '--', sprintf('%.0f lbf', result.W_TO), ...
        'LabelHorizontalAlignment', 'left');
    grid on;
    xlabel('iteration'); ylabel('W_{TO}  [lbf]');
    title('Takeoff gross weight');

    % --- installed power ------------------------------------------------
    nexttile;
    plot(it, P, '-o', 'LineWidth', 1.4, 'MarkerSize', 4); hold on;
    yline(result.P_SL, '--', sprintf('%.0f hp', result.P_SL), ...
        'LabelHorizontalAlignment', 'left');
    grid on;
    xlabel('iteration'); ylabel('P_{SL}  [hp]');
    title('Installed power, all engines');

    % --- residuals ------------------------------------------------------
    nexttile;
    semilogy(it, max(resW, eps), '-o', 'LineWidth', 1.4, 'MarkerSize', 4); hold on;
    semilogy(it, max(resP, eps), '-s', 'LineWidth', 1.4, 'MarkerSize', 4);
    grid on;
    xlabel('iteration'); ylabel('relative residual');
    legend({'weight', 'power'}, 'Location', 'northeast');
    title('Convergence');

    % --- useful-load fraction -------------------------------------------
    nexttile;
    plot(it, denom, '-o', 'LineWidth', 1.4, 'MarkerSize', 4); hold on;
    yline(0, 'r--', 'closure fails');
    grid on;
    xlabel('iteration');
    ylabel('1 - W_{fuel}/W_{TO} - OEW/W_{TO}');
    title('Useful-load fraction');

end
