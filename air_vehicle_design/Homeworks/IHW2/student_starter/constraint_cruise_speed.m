function [WP_max, slope] = constraint_cruise_speed(WS, obj, con_no)
% Cruise-speed constraint on the power loading.
% Roskam Part I, Sec. 3.6.  Ip = [ (W/S)/(sigma*(W/P)) ]^(1/3)

% --- Milestone 1: the condition, its atmosphere and the cruise power ratio ---
con   = ;
state = ;
kP    = ;

% --- Milestone 2: the slope of the constraint line ---
slope = ;

% --- Milestone 3: the largest W/P at takeoff for each wing loading ---
WP_max = ;

end
