function fig = plot_weight_history(T, ttl)
%PLOT_WEIGHT_HISTORY  How the empty-weight build-up moves, pass by pass.
%
%   fig = PLOT_WEIGHT_HISTORY(T) where T comes from TRACE_SIZING_L2.
%
%   Left:   the components stacked, one column per pass. The top of the stack
%           is W_OEW. Watch which bands breathe and which are dead flat.
%   Right:  each component as a percentage of its own first-pass value, so a
%           small component that halves is as visible as a large one that
%           does not move.
%   Bottom: first pass against last, as a bar pair, with the percent change.
%
%   A dead-flat band means that component is not coupled to the sizing
%   variables at all. That is worth knowing: it says the loop cannot trade
%   against it, and any error in it passes straight through to W_OEW.

    arguments
        T   table
        ttl (1,1) string = "Empty-weight build-up"
    end

    comp  = ["W_wings", "W_tail", "W_fuselage", "W_gear", "W_engine", "W_other"];
    label = ["wings", "tail (HT+VT)", "fuselage", "landing gear", ...
             "installed engine", "all else empty"];

    have  = arrayfun(@(c) ismember(c, string(T.Properties.VariableNames)) ...
                          && ~all(isnan(T.(c))), comp);
    comp  = comp(have);
    label = label(have);

    if isempty(comp)
        fig = new_figure([90 90 900 420]);
        ax = axes(fig); axis(ax,'off');
        text(ax, 0.5, 0.5, ['This weights model reports no components.' newline ...
             'A Level-1 regression returns OEW as a single number.'], ...
             'HorizontalAlignment','center','FontSize',12);
        title(ax, ttl);
        return
    end

    it = T.iter;
    M  = zeros(height(T), numel(comp));
    for k = 1:numel(comp), M(:,k) = T.(comp(k)); end

    fig = new_figure([60 60 1320 820]);
    tl  = tiledlayout(fig, 2, 2, 'Padding','compact', 'TileSpacing','compact');
    title(tl, sprintf('%s   --   %s', ttl, T.Properties.Description), ...
        'FontWeight','bold', 'Interpreter','none');

    % ---- stacked ---------------------------------------------------------
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    ar = area(ax, it, M);
    for k = 1:numel(ar), ar(k).DisplayName = label(k); end
    plot(ax, it, T.W_OEW, 'k-', 'LineWidth', 2.0, 'DisplayName', 'W_{OEW} total');
    xlabel(ax,'pass'); ylabel(ax,'weight [lbf]');
    title(ax, 'components, stacked');
    legend(ax,'Location','eastoutside');

    % ---- normalised ------------------------------------------------------
    ax = nexttile; hold(ax,'on'); grid(ax,'on');
    for k = 1:numel(comp)
        base = M(1,k);
        if base ~= 0
            plot(ax, it, 100*M(:,k)/base, '-o', 'LineWidth',1.4, 'DisplayName', label(k));
        end
    end
    plot(ax, it, 100*T.W_OEW/T.W_OEW(1), 'k-', 'LineWidth',2.0, 'DisplayName','W_{OEW}');
    yline(ax, 100, ':', 'first pass', 'HandleVisibility','off');
    xlabel(ax,'pass'); ylabel(ax,'% of first pass');
    title(ax, 'each component against its own start');
    legend(ax,'Location','eastoutside');

    % ---- first against last ---------------------------------------------
    ax = nexttile; grid(ax,'on');
    cats = categorical(label); cats = reordercats(cats, label);
    bar(ax, cats, [M(1,:)' M(end,:)']);
    ylabel(ax,'weight [lbf]');
    legend(ax, ["first pass","last pass"], 'Location','best');
    title(ax, 'first pass against last');

    % ---- percent change --------------------------------------------------
    ax = nexttile; grid(ax,'on');
    d = 100*(M(end,:) - M(1,:)) ./ max(abs(M(1,:)), eps);
    [ds, ord] = sort(d, 'ascend');
    barh(ax, categorical(label(ord), label(ord)), ds);
    xline(ax, 0, 'k-');
    xlabel(ax,'change over the run [%]');
    title(ax, sprintf('what moved   (W_{OEW} %+.1f%%)', ...
        100*(T.W_OEW(end)-T.W_OEW(1))/T.W_OEW(1)));
end
