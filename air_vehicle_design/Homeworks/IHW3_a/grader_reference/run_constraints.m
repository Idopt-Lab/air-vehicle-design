function [WP_limits, WS_walls, names, types] = run_constraints(WS, obj)
%RUN_CONSTRAINTS  Every constraint condition, over the wing-loading sweep.
%
%   [WP_limits, WS_walls, names, types] = run_constraints(WS, obj)
%
%   The constraint twin of run_mission. run_mission walks the mission
%   profile segment by segment and calls one segment function for each;
%   run_constraints walks the constraint set condition by condition and
%   calls the constraint function that matches its type. The mission
%   profile is a fixed sequence, so run_mission names its segments in
%   order; the constraint set is read from the requirements file, so this
%   function dispatches on con.type with a switch and picks up whatever
%   conditions the file holds.
%
%   Inputs
%     WS         takeoff wing loading sweep (W/S)_TO [lbf/ft^2], 1xM
%     obj        discipline bundle from ttpa_disciplines
%   Outputs
%     WP_limits  NxM largest (W/P)_TO each condition allows [lbf/hp]. A
%                condition that limits the wing loading only (landing) has
%                a row of NaN.
%     WS_walls   1xN largest (W/S)_TO each condition allows [lbf/ft^2]. A
%                condition that limits the power loading has NaN.
%     names      1xN condition labels
%     types      1xN condition types
%
%   Nothing is stored between calls: every call reads the conditions and
%   the models again, so a change to an input shows up in the next call.

    WS = reshape(WS, 1, []);

    n_con = numel(obj.cons);

    WP_limits = NaN(n_con, numel(WS));
    WS_walls  = NaN(1, n_con);
    names     = strings(1, n_con);
    types     = strings(1, n_con);

    for k = 1:n_con

        con = get_con(k, obj.cons);

        names(k) = con.name;
        types(k) = con.type;

        switch con.type

            case "takeoff"
                WP_limits(k,:) = constraint_takeoff(WS, obj, k);

            case "landing"
                WS_walls(k)    = constraint_landing(obj, k);

            case "climb_gradient"
                WP_limits(k,:) = constraint_climb(WS, obj, k);

            case "cruise_speed"
                WP_limits(k,:) = constraint_cruise_speed(WS, obj, k);

            otherwise
                error('run_constraints:UndefinedCondition', ...
                    'Constraint condition type "%s" is not defined.', con.type);

        end

    end

end
