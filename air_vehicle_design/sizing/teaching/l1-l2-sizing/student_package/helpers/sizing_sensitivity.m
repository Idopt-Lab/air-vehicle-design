function [tbl, fig] = sizing_sensitivity(stackFcn, runFcn, knobs, pct)
%SIZING_SENSITIVITY  Re-size the aircraft with one input nudged at a time.
%
%   [tbl, fig] = SIZING_SENSITIVITY(stackFcn, runFcn, knobs, pct)
%
%   Sizing is a LOOP, so a small change in one requirement does not move the
%   takeoff weight by a small amount. It moves it, the weight grows, the wing
%   and the engine grow with it, the fuel grows, and the weight grows again.
%   The amplification is the GROWTH FACTOR. This function measures it.
%
%   INPUTS
%     stackFcn  no-argument handle returning a FRESH stack STRUCT,
%               e.g. @build_b777_stack_s
%     runFcn    handle taking that struct and returning the sizing result,
%               e.g. @(s) SizingLoopL2(s.aero,s.prop,s.wts,s.geom,s.miss, ...
%                                      s.con,s.tail).run(700000, 200000)
%     knobs     n-by-2 cell: {label, mutator}. mutator(s, frac) applies a
%               signed fractional change to the stack struct s.
%     pct       size of the nudge, in percent. Default 10.
%
%   OUTPUTS
%     tbl  one row per knob: sized W_TO low and high, and the percent change
%     fig  a tornado chart, widest bar at the top
%
%   Each evaluation uses a brand-new stack, because the discipline objects
%   are handles and a sizing run leaves them mutated.

    arguments
        stackFcn (1,1) function_handle
        runFcn   (1,1) function_handle
        knobs    cell
        pct      (1,1) double {mustBePositive} = 10
    end

    f     = pct/100;
    base  = runFcn(stackFcn());
    n     = size(knobs, 1);
    lo    = nan(n,1);  hi = nan(n,1);
    label = strings(n,1);

    for k = 1:n
        label(k) = string(knobs{k,1});
        mut      = knobs{k,2};
        s = stackFcn();  mut(s, -f);  lo(k) = runFcn(s).W_TO;
        s = stackFcn();  mut(s, +f);  hi(k) = runFcn(s).W_TO;
    end

    d_lo = 100*(lo - base.W_TO)/base.W_TO;
    d_hi = 100*(hi - base.W_TO)/base.W_TO;

    tbl = table(label, lo, hi, d_lo, d_hi, ...
        'VariableNames', ["Input", "W_TO_low", "W_TO_high", ...
                          "pct_change_low", "pct_change_high"]);
    tbl.Properties.Description = sprintf('baseline W_TO = %.1f lbf, nudge = +/-%g%%', ...
        base.W_TO, pct);

    [~, order] = sort(max(abs(d_lo), abs(d_hi)), 'ascend');
    fig = new_figure([100 100 880 480]);
    ax  = axes(fig); hold(ax, 'on'); grid(ax, 'on');
    y   = 1:n;
    barh(ax, y, d_hi(order), 0.55, 'DisplayName', sprintf('input %+g%%', pct));
    barh(ax, y, d_lo(order), 0.55, 'DisplayName', sprintf('input %+g%%', -pct));
    xline(ax, 0, 'k-', 'LineWidth', 1.0, 'HandleVisibility', 'off');
    set(ax, 'YTick', y, 'YTickLabel', label(order));
    xlabel(ax, 'change in sized W_{TO} [%]');
    title(ax, sprintf('Sizing sensitivity, %+g%% on each input  (baseline W_{TO} = %.0f lbf)', ...
        pct, base.W_TO));
    legend(ax, 'Location', 'best');
end
