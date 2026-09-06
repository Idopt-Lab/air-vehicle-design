function [feasible, driving, WP_margin, WS_margin] = design_point_check(WS_pt, WP_pt, obj)
% Test one design point against every constraint.
% matching_envelope is on the path and accepts a scalar wing loading.

% --- Milestone 1: the limits at this wing loading ---
[WP_limit, WS_max, driving] = ;

% --- Milestone 2: the margins, signed, each divided by its own limit ---
WP_margin = ;

if isinf(WS_max)
    WS_margin = Inf;      % no wall in the constraint set
else
    WS_margin = ;
end

% --- Milestone 3: the verdict. BOTH limits must be satisfied. ---
feasible = ;

% Answer in one sentence: why choose (40, 9.25) over the best point?
%

end
