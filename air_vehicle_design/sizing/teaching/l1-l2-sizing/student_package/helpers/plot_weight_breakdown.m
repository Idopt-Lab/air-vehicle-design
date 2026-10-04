function fig = plot_weight_breakdown(result, wts, ttl)
%PLOT_WEIGHT_BREAKDOWN  Show where the sized takeoff weight went.
%
%   fig = PLOT_WEIGHT_BREAKDOWN(result, wts)
%
%   Left panel:  one stacked bar -- empty + fuel + payload = W_TO. This is the
%                closure, drawn. [Raymer 6th ed. Eq. 3.4; metabook Alg. 1]
%   Right panel: the empty-weight components, when the weights object exposes
%                a component build-up. A Level-1 regression has no components,
%                so that panel says so.

    arguments
        result (1,1) struct
        wts
        ttl    (1,1) string = "Weight breakdown"
    end

    W_payload = wts.W_payload_fixed + wts.W_payload_expendable;
    parts  = [result.W_OEW, result.W_fuel, W_payload];
    labels = ["empty (OEW)", "fuel", "payload"];

    fig = new_figure([90 90 1000 520]);
    tl  = tiledlayout(fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(tl, sprintf('%s  --  W_{TO} = %.0f lbf', ttl, result.W_TO), ...
        'FontWeight', 'bold');

    ax = nexttile; 
    b = bar(ax, 1, parts, 'stacked');
    for k = 1:numel(b), b(k).DisplayName = labels(k); end
    grid(ax, 'on');
    ylabel(ax, 'weight [lbf]');
    set(ax, 'XTick', 1, 'XTickLabel', "sized aircraft");
    legend(ax, 'Location', 'eastoutside');
    title(ax, sprintf('OEW %.3f + fuel %.3f + payload %.3f = 1', ...
        parts(1)/result.W_TO, parts(2)/result.W_TO, parts(3)/result.W_TO));

    ax = nexttile;
    comp = ["W_wings", "W_tail", "W_fuselage", "W_landing_gear", ...
            "W_installed_engine", "W_all_else_empty"];
    have = comp(arrayfun(@(c) isprop(wts, c), comp));

    % Several component properties scale with gross weight, so the object has
    % to be told which weight to report at before they can be read.
    if ~isempty(have)
        try
            wts.W_TO = result.W_TO;
        catch
            % read-only W_TO on this model; the components will speak for
            % themselves or throw below, which is caught next
        end
        try
            arrayfun(@(c) scalarize(wts.(c)), have);
        catch
            have = strings(1,0);      % not readable here; show the note instead
        end
    end

    if isempty(have)
        axis(ax, 'off');
        text(ax, 0.5, 0.5, sprintf(['This weights model is a REGRESSION.\n', ...
            'It returns OEW/W_{TO} as one number\n', ...
            '(Raymer 6th ed. Table 3.1), so it has\n', ...
            'no components to break down.\n\n', ...
            'A Level-2 component build-up does.']), ...
            'HorizontalAlignment', 'center', 'FontSize', 11);
        title(ax, 'Empty-weight components');
    else
        vals = arrayfun(@(c) scalarize(wts.(c)), have);
        lbl  = categorical(have);
        lbl  = reordercats(lbl, have);
        barh(ax, lbl, vals);
        grid(ax, 'on');
        xlabel(ax, 'weight [lbf]');
        title(ax, sprintf('Empty-weight components  (sum %.0f lbf)', sum(vals)));
    end
end

function v = scalarize(x)
%SCALARIZE  Some component properties come back split (W_tail has HT and VT).
    if isstruct(x)
        f = fieldnames(x);
        v = 0;
        for k = 1:numel(f)
            if isnumeric(x.(f{k})), v = v + sum(x.(f{k})(:)); end
        end
    else
        v = sum(x(:));
    end
end
