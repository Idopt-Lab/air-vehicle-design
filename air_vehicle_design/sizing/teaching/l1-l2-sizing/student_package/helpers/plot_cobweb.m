function fig = plot_cobweb(stackFcn, WS, TW, W0_range, W0_start, w, n_steps)
%PLOT_COBWEB  Draw the sizing closure as a fixed-point map.
%
%   fig = PLOT_COBWEB(stackFcn, WS, TW, W0_range, W0_start, w, n_steps)
%
%   The sizing loop solves  W = f(W), where f is one closure pass. This plot
%   draws f against the 45-degree line. Where the two cross is the sized
%   aircraft. The staircase shows the iterates walking to that crossing.
%
%   Read the slope of f at the crossing:
%     slope below 1   the plain iteration converges
%     slope above 1   the plain iteration diverges; under-relaxation rescues it
%   The slope is also the GROWTH FACTOR: how many pounds of takeoff weight one
%   more pound of payload buys.
%
%   INPUTS
%     stackFcn  function handle returning [aero, prop, wts, geom, miss, ...]
%     WS, TW    the frozen design point [psf], [-]
%     W0_range  takeoff weights to evaluate the map at [lbf]
%     W0_start  where the staircase starts [lbf]
%     w         under-relaxation weight on the NEW value (1 = undamped)
%     n_steps   how many staircase steps to draw

    arguments
        stackFcn  (1,1) function_handle
        WS        (1,1) double {mustBePositive}
        TW        (1,1) double {mustBePositive}
        W0_range  (1,:) double {mustBePositive}
        W0_start  (1,1) double {mustBePositive}
        w         (1,1) double {mustBePositive} = 0.5
        n_steps   (1,1) double {mustBePositive, mustBeInteger} = 12
    end

    % The map f(W0). One fresh stack per point, so no state leaks across.
    f = nan(size(W0_range));
    for k = 1:numel(W0_range)
        try
            [a, p, wt, g, m] = stackFcn();
            s = one_closure_step(a, p, wt, g, m, WS, TW, W0_range(k));
            f(k) = s.W0_new;      % NaN here means the closure has no solution
        catch
            f(k) = NaN;
        end
    end

    % The staircase. It is allowed to escape: an undamped run on a steep
    % closure map diverges, and seeing that is the point of the picture.
    xs = nan(1, 2*n_steps + 1);  ys = xs;
    W  = W0_start;  xs(1) = W;  ys(1) = W;
    for k = 1:n_steps
        try
            [a, p, wt, g, m] = stackFcn();
            s  = one_closure_step(a, p, wt, g, m, WS, TW, W);
        catch
            break
        end
        if ~isfinite(s.W0_new), break; end
        Wr = SizingSteps.relax(W, s.W0_new, w);
        if ~(isfinite(Wr) && Wr > 0), break; end
        xs(2*k)   = W;   ys(2*k)   = Wr;    % up to the relaxed map value
        xs(2*k+1) = Wr;  ys(2*k+1) = Wr;    % across to the 45-degree line
        W = Wr;
    end

    fig = new_figure([100 100 780 680]);
    ax  = axes(fig); hold(ax, 'on'); grid(ax, 'on'); axis(ax, 'square');

    % The map is very steep away from the crossing, so let the SWEEP set the
    % window. Otherwise one far-off point flattens everything worth seeing.
    lo = min(W0_range);
    hi = max(W0_range);

    plot(ax, [lo hi], [lo hi], 'k--', 'LineWidth', 1.4, ...
        'DisplayName', 'W_{new} = W   (45 deg)');
    plot(ax, W0_range, f, '-', 'Color', [0.00 0.35 0.70], 'LineWidth', 2.4, ...
        'DisplayName', 'closure map   W_{new} = f(W)');
    plot(ax, xs, ys, '-', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6, ...
        'DisplayName', sprintf('iterates, w = %.2f', w));
    plot(ax, xs(1), ys(1), 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7, ...
        'DisplayName', 'start');

    % Mark the crossing.
    good  = isfinite(f);
    cross = NaN;
    if nnz(good) > 1
        d = f(good) - W0_range(good);
        if any(d > 0) && any(d < 0)
            cross = interp1(d, W0_range(good), 0, 'linear', NaN);
        end
    end
    if isfinite(cross)
        plot(ax, cross, cross, 'p', 'MarkerSize', 20, 'LineWidth', 1.0, ...
            'MarkerFaceColor', [0.95 0.75 0.10], 'MarkerEdgeColor', 'k', ...
            'DisplayName', sprintf('fixed point   %.0f lbf', cross));
    end

    xlim(ax, [lo hi]);  ylim(ax, [lo hi]);
    xlabel(ax, 'W_{TO} going in  [lbf]');
    ylabel(ax, 'W_{TO} coming out,  f(W_{TO})  [lbf]');
    title(ax, 'The sizing closure as a fixed-point map');

    legend(ax, 'Location', 'southeast');
end
