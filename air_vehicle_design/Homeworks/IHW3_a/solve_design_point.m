function [WS, WP, info] = solve_design_point(obj, mode, WS_sweep, selected)
%SOLVE_DESIGN_POINT  The design point the sizing loop sizes to, this iteration.
%
%   [WS, WP, info] = solve_design_point(obj, mode, WS_sweep, selected)
%
%   Inputs
%     obj       discipline bundle from ttpa_disciplines
%     mode      "selected" or "optimum"
%     WS_sweep  wing-loading sweep of the matching diagram [lbf/ft^2], 1xM
%     selected  struct with fields WS and WP, the point chosen in IHW2
%   Outputs
%     WS, WP    the design point this iteration sizes to
%     info      struct, always fully populated whichever mode is used:
%                 .WS_optimum  .WP_optimum   least-engine corner
%                 .WS_wall                   tightest wing-loading wall
%                 .driving                   condition setting WP at WS
%                 .feasible                  does (WS,WP) meet everything
%                 .WP_margin  .WS_margin     margins at (WS,WP)
%                 .mode
%
%   WHY THIS IS CALLED INSIDE THE LOOP AND NOT ONCE BEFORE IT
%   A Level-1 sizing loop consults the matching diagram once, because
%   nothing in the constraint analysis depends on how big the airplane is.
%   A Level-2 loop cannot assume that: once the drag polar comes from the
%   geometry, the climb constraints move every time the wing is resized, so
%   the envelope - and in general the point on it - has to be re-solved on
%   every iteration. This function is that re-solve.
%
%   FOR THE TTPA THE DESIGN POINT DOES NOT ACTUALLY MOVE, and it is worth
%   knowing why. Of the six conditions, only two ever set the envelope:
%   Takeoff and Cruise Speed. Takeoff reads only CLmax_takeoff; Cruise
%   Speed reads only the power index. Neither touches the drag polar, so
%   neither notices that CD0 has changed. The three climb curves DO move
%   with CD0 - but they are not binding, so the corner stays at the same
%   place. The loop still re-solves, for two reasons: it is the correct
%   Level-2 structure, and info.WS_optimum in the returned history is the
%   evidence that the point did not move, rather than an assumption that it
%   could not.
%
%   Mode "selected" holds the design point at the value chosen in IHW2,
%   (40, 9.25), which was backed off from the corner as a factor of safety.
%   It still checks feasibility on every iteration, because a moving
%   envelope could in principle overtake a fixed point.
%
%   Mode "optimum" sizes to the corner itself - the smallest engine the
%   requirements allow, with no margin at all. Run both and compare: the
%   difference in the converged takeoff weight is the price of the margin.

    arguments
        obj      (1,1) struct
        mode     (1,1) string {mustBeMember(mode, ["selected", "optimum"])}
        WS_sweep (1,:) double
        selected (1,1) struct
    end

    % The envelope of the CURRENT airplane. Everything this reads - the
    % configuration polars, the propeller efficiencies, the power lapse -
    % comes from the discipline objects live, so this is the envelope of
    % the airplane as the loop has it right now.
    [~, WS_wall, ~, WS_optimum, WP_optimum] = matching_envelope(WS_sweep, obj);

    switch mode

        case "optimum"
            if isnan(WS_optimum)
                error('solve_design_point:NoFeasiblePoint', ...
                    ['No wing loading on the sweep [%.1f, %.1f] lbf/ft^2 is ', ...
                     'feasible: the whole sweep lies beyond the wing-loading ', ...
                     'wall at %.2f lbf/ft^2. Widen the sweep or relax the ', ...
                     'landing requirement.'], ...
                    WS_sweep(1), WS_sweep(end), WS_wall);
            end
            WS = WS_optimum;
            WP = WP_optimum;

        case "selected"
            WS = selected.WS;
            WP = selected.WP;

    end

    % Margins of the point actually being sized to
    [feasible, driving, WP_margin, WS_margin] = design_point_check(WS, WP, obj);

    info.mode       = mode;
    info.WS_optimum = WS_optimum;
    info.WP_optimum = WP_optimum;
    info.WS_wall    = WS_wall;
    info.driving    = driving;
    info.feasible   = feasible;
    info.WP_margin  = WP_margin;
    info.WS_margin  = WS_margin;

end
