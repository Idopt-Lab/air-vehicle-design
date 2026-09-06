function [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj)
%MATCHING_ENVELOPE  Combine every constraint into the matching diagram.
%
%   [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj)
%
%   Inputs
%     WS       takeoff wing loading sweep (W/S)_TO [lbf/ft^2], 1xM
%     obj      discipline bundle from ttpa_disciplines
%   Outputs
%     WP_env   1xM smallest of the power-loading limits [lbf/hp]
%     WS_max   tightest wing-loading wall [lbf/ft^2], Inf if there is none
%     driving  1xM label of the condition that gives WP_env
%     WS_best  wing loading of the feasible point with the largest power
%              loading [lbf/ft^2], NaN if no point of the sweep is feasible
%     WP_best  the matching power loading [lbf/hp], NaN in the same case
%
%   The feasible region of a propeller-driven airplane lies BELOW the
%   power-loading envelope and LEFT of the wing-loading wall: a smaller W/P
%   means a larger engine, and a larger W/S means a smaller wing.
%
%       WP_env(WS) = smallest of the power-condition limits at that W/S
%       feasible   = wing loadings at or below the tightest wall
%       best point = the feasible wing loading where WP_env is largest
%
%   The best point needs the smallest engine that still meets every
%   requirement. It is not automatically the point to design to: it sits
%   exactly on the constraints and keeps no margin.

    WS = reshape(WS, 1, []);

    [WP_limits, WS_walls, names] = run_constraints(WS, obj);

    % Conditions that limit the power loading
    is_power = ~all(isnan(WP_limits), 2);

    if ~any(is_power)
        error('matching_envelope:NoPowerConstraint', ...
            'The constraint set has no condition that limits the power loading.');
    end

    [WP_env, idx] = min(WP_limits(is_power,:), [], 1);

    power_names = names(is_power);
    driving     = power_names(idx);

    % Conditions that limit the wing loading
    if all(isnan(WS_walls))
        WS_max = Inf;
    else
        WS_max = min(WS_walls(~isnan(WS_walls)));
    end

    % Best feasible point: largest power loading left of the wall
    usable = WP_env;
    usable(WS > WS_max) = -Inf;

    if all(isinf(usable))
        % No wing loading of this sweep is left of the wall. The envelope,
        % the wall and the driving condition are still defined, so they are
        % returned and the best point is reported as not available.
        % design_point_check depends on this when it tests a point that
        % lies beyond the wall.
        WS_best = NaN;
        WP_best = NaN;
    else
        [WP_best, j_best] = max(usable);
        WS_best           = WS(j_best);
    end

end
