function [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj)
% Combine every constraint into the matching diagram.
% run_constraints is on the path; call it once.

WS = reshape(WS, 1, []);

% --- Milestone 1: every condition, in one call ---
[WP_limits, WS_walls, names] = ;

% --- Milestone 2: the envelope and the condition that sets it.
%     Rows that are all NaN are wall conditions; leave them out. ---
is_power = ;

[WP_env, idx] = ;

power_names = names(is_power);
driving     = ;

% --- Milestone 3: the tightest wall, Inf if the set has none ---
if all(isnan(WS_walls))
    WS_max = ;
else
    WS_max = ;
end

% --- Milestone 4: the best point inside the feasible set ---
usable = WP_env;
usable(WS > WS_max) = ;

if all(isinf(usable))
    WS_best = NaN;      % nothing feasible on this sweep
    WP_best = NaN;
else
    [WP_best, j_best] = ;
    WS_best           = ;
end

end
