function fig = plot_sizing_history(T, ttl)
%PLOT_SIZING_HISTORY  Twelve panels of a Level-2 sizing trace.
%
%   fig = PLOT_SIZING_HISTORY(T) where T comes from TRACE_SIZING_L2.
%
%   Panel by panel:
%     1  W_TO       the first state variable, with what the closure returned
%     2  T_SL       the second state variable, with what the design point demanded
%     3  S_ref      SLAVED, not a state: S_ref = W_TO / (W/S)*
%     4  (W/S)* and (T/W)*   the design point. At Level 1 these are flat lines.
%     5  residuals  both states, log axis, against the tolerance
%     6  S_ht, S_vt the tail, resized every pass
%     7  b_wing, cbar_wing   the wing planform following S_ref
%     8  exposed and wetted area
%     9  S_wet/S_ref         the ratio that sets parasite drag
%    10  CD0 and L/D_max     the drag polar moving under the loop
%    11  weight fractions and the closure denominator
%    12  W_OEW and W_fuel
%
%   A flat line is as informative as a moving one. Panel 4 flat means the
%   design point never moved, so a Level-1 loop would have got the same
%   answer. Panel 6 moving while panel 8 does not means the tail areas are
%   being written but not consumed.

    arguments
        T   table
        ttl (1,1) string = "Level-2 sizing history"
    end

    it = T.iter;
    fig = new_figure([50 40 1500 940]);
    tl  = tiledlayout(fig, 4, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(tl, sprintf('%s   --   %s', ttl, T.Properties.Description), ...
        'FontWeight', 'bold', 'Interpreter', 'none');

    % 1 --------------------------------------------------------------- W_TO
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    plot(ax, it, T.W_TO,     '-o', 'LineWidth', 1.6, 'DisplayName', 'W_{TO} state');
    plot(ax, it, T.W_TO_new, '--s', 'LineWidth', 1.0, 'DisplayName', 'from the closure');
    ylabel(ax, 'lbf'); title(ax, '1.  W_{TO}   (STATE)');
    legend(ax, 'Location','best'); xlabel(ax,'pass');

    % 2 --------------------------------------------------------------- T_SL
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    plot(ax, it, T.T_SL,     '-o', 'LineWidth', 1.6, 'DisplayName', 'T_{SL} state');
    plot(ax, it, T.T_SL_new, '--s', 'LineWidth', 1.0, 'DisplayName', 'from (T/W)*');
    ylabel(ax, 'lbf'); title(ax, '2.  T_{SL}   (STATE)');
    legend(ax, 'Location','best'); xlabel(ax,'pass');

    % 3 -------------------------------------------------------------- S_ref
    ax = nexttile; grid(ax,'on');
    plot(ax, it, T.S_ref, '-o', 'LineWidth', 1.6, 'Color', [0.47 0.25 0.80]);
    ylabel(ax, 'ft^2'); xlabel(ax,'pass');
    title(ax, '3.  S_{ref}   (SLAVED = W_{TO} / (W/S)^*)');

    % 4 -------------------------------------------------- the design point
    ax = nexttile; grid(ax,'on');
    yyaxis(ax,'left');  plot(ax, it, T.WS, '-o', 'LineWidth', 1.6); ylabel(ax,'(W/S)^*  [psf]');
    yyaxis(ax,'right'); plot(ax, it, T.TW, '-s', 'LineWidth', 1.6); ylabel(ax,'(T/W)^*  [-]');
    xlabel(ax,'pass');
    title(ax, sprintf('4.  design point   (W/S %+.2f%%, T/W %+.2f%%)', ...
        pctchange(T.WS), pctchange(T.TW)));

    % 5 ---------------------------------------------------------- residuals
    ax = nexttile; grid(ax,'on'); hold(ax,'on');
    semilogy(ax, it, max(T.res_W, eps), '-o', 'LineWidth', 1.6, 'DisplayName', 'W_{TO}');
    semilogy(ax, it, max(T.res_T, eps), '-s', 'LineWidth', 1.6, 'DisplayName', 'T_{SL}');
    yline(ax, 1e-6, '--', 'tol\_rel', 'HandleVisibility','off');
    set(ax,'YScale','log');
    ylabel(ax,'relative residual'); xlabel(ax,'pass');
    title(ax, '5.  convergence   (the loop needs BOTH)');
    legend(ax,'Location','best');

    % 6 -------------------------------------------------------- tail areas
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    plot(ax, it, T.S_ht, '-o', 'LineWidth', 1.6, 'DisplayName', 'S_{ht}');
    plot(ax, it, T.S_vt, '-s', 'LineWidth', 1.6, 'DisplayName', 'S_{vt}');
    ylabel(ax,'ft^2'); xlabel(ax,'pass');
    title(ax, '6.  tail   (resized every pass)');
    legend(ax,'Location','best');

    % 7 ---------------------------------------------------- wing planform
    ax = nexttile; grid(ax,'on');
    yyaxis(ax,'left');  plot(ax, it, T.b_wing,    '-o', 'LineWidth',1.6); ylabel(ax,'b_{wing}  [ft]');
    yyaxis(ax,'right'); plot(ax, it, T.cbar_wing, '-s', 'LineWidth',1.6); ylabel(ax,'c_{bar}  [ft]');
    xlabel(ax,'pass'); title(ax, '7.  wing planform   (follows S_{ref})');

    % 8 --------------------------------------------- exposed / wetted area
    % Separate axes: the total wetted area is an order of magnitude larger
    % than the exposed wing, and on one scale the smaller one looks flat.
    ax = nexttile; grid(ax,'on');
    yyaxis(ax,'left');  plot(ax, it, T.S_exp_wing, '-o','LineWidth',1.6);
    ylabel(ax,'S_{exposed,wing}  [ft^2]');
    yyaxis(ax,'right'); plot(ax, it, T.S_wet, '-s','LineWidth',1.6);
    ylabel(ax,'S_{wet} total  [ft^2]');
    xlabel(ax,'pass'); title(ax, '8.  exposed and wetted area');

    % 9 ------------------------------------------------------ wetted ratio
    ax = nexttile; grid(ax,'on');
    plot(ax, it, T.S_wet_S_ref, '-o', 'LineWidth',1.6, 'Color',[0.85 0.33 0.10]);
    ylabel(ax,'S_{wet} / S_{ref}  [-]'); xlabel(ax,'pass');
    title(ax, '9.  the ratio that sets C_{D0}');

    % 10 ---------------------------------------------------------- the polar
    ax = nexttile; grid(ax,'on');
    if all(isnan(T.CD0))
        axis(ax,'off');
        text(ax,0.5,0.5,'drag polar not sampled', 'HorizontalAlignment','center');
        title(ax,'10.  drag polar');
    else
        yyaxis(ax,'left');  plot(ax, it, T.CD0,    '-o','LineWidth',1.6); ylabel(ax,'C_{D0}');
        yyaxis(ax,'right'); plot(ax, it, T.LD_max, '-s','LineWidth',1.6); ylabel(ax,'L/D_{max}');
        xlabel(ax,'pass');
        title(ax, sprintf('10.  drag polar   (C_{D0} %+.1f%%)', pctchange(T.CD0)));
    end

    % 11 --------------------------------------------- fractions and denom
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    plot(ax, it, T.f_OEW,     '-o','LineWidth',1.6,'DisplayName','W_{OEW}/W_{TO}');
    plot(ax, it, T.f_fuel,    '-s','LineWidth',1.6,'DisplayName','W_{fuel}/W_{TO}');
    plot(ax, it, T.f_payload, '-^','LineWidth',1.0,'DisplayName','W_{pay}/W_{TO}');
    plot(ax, it, T.denom,     '-d','LineWidth',1.6,'DisplayName','denom');
    ylabel(ax,'-'); xlabel(ax,'pass');
    title(ax, '11.  the closure fractions');
    legend(ax,'Location','best');

    % 12 ---------------------------------------------------- OEW and fuel
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    plot(ax, it, T.W_OEW,  '-o','LineWidth',1.6,'DisplayName','W_{OEW}');
    plot(ax, it, T.W_fuel, '-s','LineWidth',1.6,'DisplayName','W_{fuel}');
    ylabel(ax,'lbf'); xlabel(ax,'pass');
    title(ax, '12.  empty weight and fuel');
    legend(ax,'Location','best');
end

function p = pctchange(v)
    v = v(~isnan(v));
    if numel(v) < 2 || v(1) == 0, p = 0; else, p = 100*(v(end)-v(1))/abs(v(1)); end
end
