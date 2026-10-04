function [fig, S] = plot_what_changed(T, ttl)
%PLOT_WHAT_CHANGED  One chart: which quantities the sizing loop actually moves.
%
%   [fig, S] = PLOT_WHAT_CHANGED(T) where T comes from TRACE_SIZING_L2.
%
%   Every traced quantity, as a percentage change from the first pass to the
%   last, sorted by size. Bars are coloured by what the quantity IS:
%
%     STATE    a genuine unknown the loop under-relaxes. There are two:
%              W_TO and T_SL.
%     SLAVED   computed from the states and the design point every pass.
%              S_ref is the one that matters: S_ref = W_TO / (W/S)*.
%     SOLVED   the design point, re-solved by fmincon every pass.
%     DOWNSTREAM  everything the three above drag along with them.
%
%   The reason to draw it: a bar at zero is a coupling the loop does not
%   have. If the tail areas move but the exposed tail area does not, the tail
%   resize is being written and not consumed. That is a real finding about the
%   model, and it is invisible in the converged answer.
%
%   S is the same information as a sorted table.

    arguments
        T   table
        ttl (1,1) string = "What the loop actually changed"
    end

    kindOf = dictionary( ...
        "W_TO", "STATE",        "T_SL", "STATE", ...
        "S_ref", "SLAVED",      "WS", "SOLVED",  "TW", "SOLVED");

    skip = ["iter", "W_TO_new", "T_SL_new", "res_W", "res_T", "f_payload"];

    names = string(T.Properties.VariableNames);
    names = names(~ismember(names, skip));

    lbl = strings(0); pct = []; knd = strings(0); first = []; last = [];
    for k = 1:numel(names)
        v = T.(names(k));
        if ~isnumeric(v) || all(isnan(v)), continue; end
        v = v(~isnan(v));
        if numel(v) < 2 || v(1) == 0, continue; end
        lbl(end+1)   = names(k);                              %#ok<AGROW>
        first(end+1) = v(1);                                  %#ok<AGROW>
        last(end+1)  = v(end);                                %#ok<AGROW>
        pct(end+1)   = 100*(v(end) - v(1)) / abs(v(1));       %#ok<AGROW>
        if isKey(kindOf, names(k))
            knd(end+1) = kindOf(names(k));                    %#ok<AGROW>
        else
            knd(end+1) = "DOWNSTREAM";                        %#ok<AGROW>
        end
    end

    [~, ord] = sort(abs(pct), 'ascend');
    lbl = lbl(ord); pct = pct(ord); knd = knd(ord);
    first = first(ord); last = last(ord);

    S = table(lbl(:), knd(:), first(:), last(:), pct(:), ...
        'VariableNames', ["Quantity","Kind","First_pass","Last_pass","Percent_change"]);
    S = flipud(S);

    cols = dictionary( ...
        "STATE",      {[0.85 0.33 0.10]}, ...
        "SLAVED",     {[0.47 0.25 0.80]}, ...
        "SOLVED",     {[0.00 0.45 0.74]}, ...
        "DOWNSTREAM", {[0.55 0.60 0.65]});

    fig = new_figure([70 50 1080 900]);
    ax  = axes(fig); hold(ax,'on'); grid(ax,'on');
    y   = 1:numel(lbl);

    shown = strings(0);
    for k = 1:numel(lbl)
        c = cols(knd(k)); c = c{1};
        if ismember(knd(k), shown)
            barh(ax, y(k), pct(k), 0.72, 'FaceColor', c, 'HandleVisibility','off');
        else
            barh(ax, y(k), pct(k), 0.72, 'FaceColor', c, 'DisplayName', knd(k));
            shown(end+1) = knd(k); %#ok<AGROW>
        end
    end

    % Anything that did not move at all: say so in words, not with an
    % invisible bar.
    for k = 1:numel(lbl)
        if abs(pct(k)) < 0.05
            text(ax, 0, y(k), '  did not move', 'FontSize', 8, ...
                'FontAngle','italic', 'Color', [0.35 0.35 0.35], ...
                'VerticalAlignment','middle');
        end
    end

    xline(ax, 0, 'k-', 'LineWidth', 1.0, 'HandleVisibility','off');
    set(ax, 'YTick', y, 'YTickLabel', lbl, 'TickLabelInterpreter','none');
    ylim(ax, [0.4, numel(lbl)+0.6]);
    xlabel(ax, 'change from the first pass to the last  [%]');
    title(ax, sprintf('%s   --   %s', ttl, T.Properties.Description), ...
        'Interpreter','none');
    legend(ax, 'Location','southeast');
end
