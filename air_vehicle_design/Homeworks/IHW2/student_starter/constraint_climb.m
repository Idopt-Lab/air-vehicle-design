function [WP_max, CGRP, LD, cfg] = constraint_climb(WS, obj, con_no)
% Climb-gradient constraint on the power loading.
% Roskam Part I, Sec. 3.3:
%   CD   = CD0 + CL^2/(pi*AR*e)
%   CGRP = (CGR + 1/(L/D))/sqrt(CL)
%   CGRP = 18.97*eta_p*sqrt(sigma)/((W/P)*sqrt(W/S))
%
% beta = W_condition/W_TO,  kP = P_condition/P_TO at sea level

% --- Milestone 1: the condition, its atmosphere and its polar ---
con   = ;
state = ;
cfg   = ;

% --- Milestone 2: the climb CL, the drag coefficient and L/D ---
CL = ;
CD = ;
LD = ;

% --- Milestone 3: the required climb gradient parameter ---
CGRP = ;

% --- Milestone 4: propeller efficiency and power ratio, from the model ---
eta_p = ;
kP    = ;

% --- Milestone 5: the largest W/P at takeoff that meets the gradient ---
WP_max = ;

end
