function [WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, con_no)
% Landing ground-roll constraint on the wing loading.
% Roskam Part I, Sec. 3.2.  S_LGR = 0.265*Vs_L^2  (ft, kt)

% --- Milestone 1: condition, atmosphere, CLmax and the stall speed in kt ---
con     = ;
state   = ;
CLmax_L = ;

Vs_kts = ;

% --- Milestone 2: the same speed in ft/s ---
Vs_fps = ;

% --- Milestone 3: wing loading at landing, then referred to takeoff ---
WS_max_L = ;
WS_max   = ;

end

%% Supporting Functions -- given, do not change
function [ft_s] = kts2ft_s(kts)
    ft_s = kts*6076.115/3600;
end
