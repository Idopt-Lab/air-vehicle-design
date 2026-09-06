function [S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = size_from_design_point(W_TO, WS_pt, WP_pt, obj, con_no_landing)
% First wing and engine size from the design point.

% --- Milestone 1: wing geometry. AR comes from the aerodynamic model. ---
S_ref = ;
b     = GeometryBase.compute_span( , );
c_bar = ;

% --- Milestone 2: installed power, all engines, then per engine ---
P_TO     = ;
P_engine = ;

% --- Milestone 3: write the sized values back into the models ---
obj.geom.S_ref = ;
obj.prop.P_SL  = ;

% --- Milestone 4: close the loop on the landing requirement ---
con     = ;
state   = ;
CLmax_L = ;

V_fps       = ;
Vs_L_kts    = ;
s_LGR_check = ;

end

%% Supporting Functions -- given, do not change
function [kts] = ft_s2kts(ft_s)
    kts = ft_s*3600/6076.115;
end
