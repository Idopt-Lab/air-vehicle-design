function [WP_allowed, info] = design_diagram(WS, obj)
%DESIGN_DIAGRAM  The design-diagram box, read at ONE wing loading.
%
%   [WP_allowed, info] = design_diagram(WS, obj)
%
%   Inputs
%     WS   takeoff wing loading (W/S)_TO [lbf/ft^2], SCALAR
%     obj  discipline bundle from ttpa_disciplines
%   Outputs
%     WP_allowed  the largest (W/P)_TO every power condition permits at this
%                 wing loading [lbf/hp] - i.e. the smallest engine that meets
%                 every requirement
%     info        struct:
%                   .driving      name of the condition that sets WP_allowed
%                   .WS_wall      tightest wing-loading wall [lbf/ft^2]
%                   .wall_ok      does WS satisfy the wall
%                   .WS_margin    (WS_wall - WS)/WS_wall
%                   .names        every condition name
%                   .WP_limits    every condition's limit, NaN for walls
%
%   THIS IS THE "Design diagram" BOX OF THE PRELIMINARY DESIGN FRAMEWORK.
%   The lecture's own note on that box is the reason this function takes a
%   SCALAR wing loading rather than a sweep:
%
%       "You don't need to draw the entire chart because W/S is fixed."
%
%   In the lecture framework S_ref is an input and W_0 is iterated, so the
%   wing loading W_0/S_ref is a COMPUTED number, not a chosen one. There is
%   exactly one wing loading per iteration, and all the design diagram has to
%   do is report the power loading the requirements allow there. Sweeping the
%   whole chart - which is what IHW2 did, and what matching_envelope still
%   does - answers a different question: where is the best point over ALL
%   wing loadings.
%
%   The envelope itself is unchanged from IHW2. Every condition is evaluated
%   by the same constraint_* function through run_constraints, so the number
%   this returns is a point on the same matching diagram the students drew.
%
%   See also RUN_CONSTRAINTS, MATCHING_ENVELOPE, SIZING_LOOP.

    arguments
        WS  (1,1) double {mustBePositive}
        obj (1,1) struct
    end

    [WP_limits, WS_walls, names] = run_constraints(WS, obj);

    % Conditions that limit the POWER loading. A wall returns a row of NaN.
    is_power = ~all(isnan(WP_limits), 2);

    if ~any(is_power)
        error('design_diagram:NoPowerConstraint', ...
            'The constraint set has no condition that limits the power loading.');
    end

    power_limits = WP_limits(is_power, 1);
    power_names  = names(is_power);

    % The binding condition is the SMALLEST allowed power loading: the
    % requirement that demands the biggest engine.
    [WP_allowed, k] = min(power_limits);

    % Conditions that limit the WING loading. These do not size the engine;
    % they say whether this wing loading is legal at all.
    if all(isnan(WS_walls))
        WS_wall = Inf;
    else
        WS_wall = min(WS_walls(~isnan(WS_walls)));
    end

    info.driving   = power_names(k);
    info.WS_wall   = WS_wall;
    info.wall_ok   = WS <= WS_wall;
    info.WS_margin = (WS_wall - WS) / WS_wall;
    info.names     = names;
    info.WP_limits = WP_limits(:, 1).';
    info.WS        = WS;

end
