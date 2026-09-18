function [WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, con_no)
%CONSTRAINT_LANDING  Landing ground-roll constraint on the wing loading.
%
%   [WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, con_no)
%
%   Inputs
%     obj     discipline bundle from ttpa_disciplines
%     con_no  number of the landing condition in obj.cons
%   Outputs
%     WS_max  largest (W/S)_TO that meets the ground roll [lbf/ft^2]
%     Vs_kts  largest permitted stall speed, landing flaps [kt]
%     Vs_fps  the same speed [ft/s]
%
%   Roskam Part I, Sec. 3.2:
%
%       S_LGR = 0.265 Vs_L^2                      S_LGR in ft, Vs_L in KNOTS
%       Vs_L  = sqrt( (W/S)_L (2/rho) (1/CLmax_L) )      Vs_L in FT/S
%
%   The two relations use different speed units, so convert between them.
%   Combining them and referring the landing weight to the takeoff weight
%   with beta = W_L/W_TO gives the wing-loading wall
%
%       (W/S)_TO <= 0.5 rho Vs_L^2 CLmax_L / beta
%
%   The airplane is lighter at landing, so the takeoff wing loading it
%   permits is LARGER than the value at landing weight.
%
%   The landing distance depends on the wing loading only, so this
%   condition does NOT constrain the power loading. It is a vertical wall
%   on the matching diagram, which is why this function takes no wing
%   loading and returns no curve.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    CLmax_L = obj.aero.get_CLmax(state, con);

    % Largest stall speed that still meets the ground roll
    Vs_kts = sqrt(con.distance_ft / 0.265);   % kt
    Vs_fps = kts2ft_s(Vs_kts);                % ft/s

    % Wing loading at landing weight, then referred to takeoff weight
    WS_max_L = 0.5 * state.rho * Vs_fps^2 * CLmax_L;
    WS_max   = WS_max_L / con.beta;

end

%% Supporting Functions
function [ft_s] = kts2ft_s(kts)
    ft_s = kts*6076.115/3600;
end
