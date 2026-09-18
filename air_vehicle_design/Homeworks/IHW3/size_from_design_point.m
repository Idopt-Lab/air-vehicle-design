function [S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = size_from_design_point(W_TO, WS_pt, WP_pt, obj, con_no_landing)
%SIZE_FROM_DESIGN_POINT  First wing and engine size from the design point.
%
%   [S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = ...
%       size_from_design_point(W_TO, WS_pt, WP_pt, obj, con_no_landing)
%
%   Inputs
%     W_TO            takeoff gross weight from the mission analysis [lbf]
%     WS_pt           selected takeoff wing loading [lbf/ft^2]
%     WP_pt           selected takeoff power loading [lbf/hp]
%     obj             discipline bundle from ttpa_disciplines
%     con_no_landing  number of the landing condition in obj.cons
%   Outputs
%     S_ref           wing reference area [ft^2]
%     b               wing span [ft]
%     c_bar           mean geometric chord [ft]
%     P_TO            installed takeoff power, all engines [hp]
%     P_engine        takeoff power per engine [hp]
%     Vs_L_kts        stall speed with landing flaps at landing weight [kt]
%     s_LGR_check     landing ground roll of that stall speed [ft]
%
%   The design point is a pair of ratios, so the takeoff gross weight of
%   the mission analysis turns it into a size:
%
%       S_ref = W_TO / (W/S)      P_TO = W_TO / (W/P)
%       b     = sqrt(AR S_ref)    [GeometryBase.compute_span]
%
%   The aspect ratio is read from the aerodynamic model, which is the model
%   that reads J.geometry.AR out of the requirements file.
%
%   The two sized values are written back into the discipline objects,
%   which hold them as NaN until this point: the wing area into the
%   geometry model and the sea-level rated power into the propulsion model.
%   Both are handle objects, so the caller sees the update.
%
%   s_LGR_check closes the loop with Roskam Part I, Sec. 3.2: it re-derives
%   the landing ground roll from the airplane that was just sized, running
%   the relation forward instead of backward. It must stay at or below the
%   required landing ground roll.

    % Wing
    S_ref = W_TO / WS_pt;
    b     = GeometryBase.compute_span(obj.aero.AR, S_ref);
    c_bar = S_ref / b;

    % Engine
    P_TO     = W_TO / WP_pt;
    P_engine = P_TO / obj.prop.n_engines;

    % Write the sized values back into the discipline models
    obj.geom.S_ref = S_ref;
    obj.prop.P_SL  = P_TO;

    % Landing check
    con     = get_con(con_no_landing, obj.cons);
    state   = get_state(con.alt);
    CLmax_L = obj.aero.get_CLmax(state, con);

    V_fps    = sqrt(2 * WS_pt * con.beta / (state.rho * CLmax_L));   % ft/s
    Vs_L_kts = ft_s2kts(V_fps);                                      % kt

    s_LGR_check = 0.265 * Vs_L_kts^2;                                % ft

end

%% Supporting Functions
function [kts] = ft_s2kts(ft_s)
    kts = ft_s*3600/6076.115;
end
