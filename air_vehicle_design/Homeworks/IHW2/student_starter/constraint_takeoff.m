function [WP_max, TOP23] = constraint_takeoff(WS, obj, con_no)
% Takeoff ground-roll constraint on the power loading.
% Roskam Part I, Sec. 3.1:
%   S_TGR = 4.9*TOP23 + 0.009*TOP23^2
%   TOP23 = (W/S)*(W/P)/(sigma*CLmax_TO)

% --- Milestone 1: the condition, its atmosphere, and CLmax ---
con      = ;
state    = ;
CLmax_TO = ;

% --- Milestone 2: solve the quadratic for TOP23, positive root ---
a = 0.009;
b = 4.9;
c = ;

TOP23 = ;

% --- Milestone 3: the largest W/P that still meets the ground roll ---
WP_max = ;

end
