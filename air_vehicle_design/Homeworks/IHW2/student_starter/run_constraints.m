function [WP_limits, WS_walls, names, types] = run_constraints(WS, obj)
% Every constraint condition, over the wing-loading sweep.
% The constraint twin of run_mission. All four constraint functions are on
% the path; call them.

WS = reshape(WS, 1, []);      % force a row vector

n_con = numel(obj.cons);

% --- Milestone 1: pre-allocate. A condition that sets no limit stays NaN. ---
WP_limits = ;
WS_walls  = ;
names     = strings(1, n_con);
types     = strings(1, n_con);

for k = 1:n_con

    % --- Milestone 2: the condition, its name and its type ---
    con = ;

    names(k) = ;
    types(k) = ;

    % --- Milestone 3: send it to the function that sizes it ---
    switch con.type

        case "takeoff"

        case "landing"

        case "climb_gradient"

        case "cruise_speed"

        otherwise
            error('run_constraints:UndefinedCondition', ...
                'Constraint condition type "%s" is not defined.', con.type);

    end

end

end
