function fig = plot_convergence(result, ttl)
%PLOT_CONVERGENCE  Plot a sizing-loop convergence history.
%
%   fig = PLOT_CONVERGENCE(result) takes the result struct from
%   SizingLoopL1.run or SizingLoopL2.run and draws four panels:
%     1. W_TO against iteration, with the converged value
%     2. the relative residual |W_new - W|/W_new on a log axis
%     3. the weight split: empty, fuel, and what is left for payload
%     4. T_SL against iteration (Level 2) or S_ref against iteration (Level 1)
%
%   The history row holds the PRE-update iterate. Row k shows the guess that
%   pass k started with; W0_new shows what that pass produced.

    arguments
        result (1,1) struct
        ttl    (1,1) string = "Sizing convergence"
    end

    h    = result.history;
    it   = [h.iter];
    W0   = [h.W0];
    Wnew = [h.W0_new];
    res  = abs(Wnew - W0) ./ Wnew;
    isL2 = isfield(result, 'T_SL') && isfield(h, 'T_SL');

    fig = new_figure([80 80 980 680]);
    tl  = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(tl, sprintf('%s  --  %d iterations, converged = %d', ...
        ttl, result.n_iter, result.converged), 'FontWeight', 'bold');

    ax = nexttile; hold(ax, 'on'); grid(ax, 'on');
    plot(ax, it, W0,   '-o', 'LineWidth', 1.4, 'DisplayName', 'W_{TO} guess');
    plot(ax, it, Wnew, '--s', 'LineWidth', 1.0, 'DisplayName', 'W_{TO} from closure');
    yline(ax, result.W_TO, ':', sprintf('converged %.0f lbf', result.W_TO), ...
        'LineWidth', 1.4, 'LabelHorizontalAlignment', 'left');
    xlabel(ax, 'iteration'); ylabel(ax, 'W_{TO} [lbf]');
    title(ax, 'Takeoff weight'); legend(ax, 'Location', 'best');

    ax = nexttile; grid(ax, 'on');
    semilogy(ax, it, max(res, eps), '-o', 'LineWidth', 1.4);
    yline(ax, 1e-6, '--', 'tol\_rel = 10^{-6}');
    xlabel(ax, 'iteration'); ylabel(ax, '|W_{new}-W| / W_{new}');
    title(ax, 'Relative residual');

    ax = nexttile; hold(ax, 'on'); grid(ax, 'on');
    plot(ax, it, [h.W_OEW],  '-o', 'LineWidth', 1.4, 'DisplayName', 'W_{OEW}');
    plot(ax, it, [h.W_fuel], '-s', 'LineWidth', 1.4, 'DisplayName', 'W_{fuel}');
    plot(ax, it, W0 - [h.W_OEW] - [h.W_fuel], '-^', 'LineWidth', 1.0, ...
        'DisplayName', 'W_{TO} - OEW - fuel');
    xlabel(ax, 'iteration'); ylabel(ax, 'weight [lbf]');
    title(ax, 'Weight split'); legend(ax, 'Location', 'best');

    ax = nexttile; grid(ax, 'on');
    if isL2
        hold(ax, 'on');
        plot(ax, it, [h.T_SL],     '-o', 'LineWidth', 1.4, 'DisplayName', 'T_{SL} state');
        plot(ax, it, [h.T_SL_new], '--s', 'LineWidth', 1.0, 'DisplayName', 'T_{SL} from (T/W)*');
        yline(ax, result.T_SL, ':', sprintf('converged %.0f lbf', result.T_SL), ...
            'LineWidth', 1.4, 'LabelHorizontalAlignment', 'left');
        xlabel(ax, 'iteration'); ylabel(ax, 'T_{SL} [lbf]');
        title(ax, 'Sea-level thrust: the SECOND state variable');
        legend(ax, 'Location', 'best');
    else
        plot(ax, it, W0 ./ result.WS, '-o', 'LineWidth', 1.4);
        yline(ax, result.S_ref, ':', sprintf('converged %.0f ft^2', result.S_ref), ...
            'LineWidth', 1.4, 'LabelHorizontalAlignment', 'left');
        xlabel(ax, 'iteration'); ylabel(ax, 'S_{ref} [ft^2]');
        title(ax, 'Wing area: slaved to W_{TO} through S = W_{TO}/(W/S)*');
    end
end
