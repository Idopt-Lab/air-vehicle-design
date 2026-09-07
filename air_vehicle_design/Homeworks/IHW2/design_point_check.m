function [feasible, driving, WP_margin, WS_margin] = design_point_check(WS_pt, WP_pt, obj)
%DESIGN_POINT_CHECK  Test one design point against every constraint.
%
%   [feasible, driving, WP_margin, WS_margin] = design_point_check(WS_pt, WP_pt, obj)
%
%   Inputs
%     WS_pt      candidate takeoff wing loading [lbf/ft^2]
%     WP_pt      candidate takeoff power loading [lbf/hp]
%     obj        discipline bundle from ttpa_disciplines
%   Outputs
%     feasible   true only when BOTH limits are satisfied
%     driving    condition that limits the power loading at WS_pt
%     WP_margin  (WP_limit - WP_pt)/WP_limit, positive when feasible
%     WS_margin  (WS_max - WS_pt)/WS_max, positive when feasible
%
%   matching_envelope accepts a scalar wing loading, so one call gives the
%   ceiling, the wall and the active condition at that single point.
%
%   A negative margin means the point violates that constraint, and says by
%   how much. The margins are returned for any point, feasible or not: a
%   negative margin is information, and this function has to stay useful
%   during a trade study.

    [WP_limit, WS_max, driving] = matching_envelope(WS_pt, obj);

    WP_margin = (WP_limit - WP_pt) / WP_limit;

    if isinf(WS_max)
        WS_margin = Inf;   % no wall in the constraint set
    else
        WS_margin = (WS_max - WS_pt) / WS_max;
    end

    feasible = (WP_pt <= WP_limit) && (WS_pt <= WS_max);

end
