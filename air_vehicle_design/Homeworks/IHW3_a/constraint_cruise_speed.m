function [WP_max, slope] = constraint_cruise_speed(WS, obj, con_no)
%CONSTRAINT_CRUISE_SPEED  Cruise-speed constraint on the power loading.
%
%   [WP_max, slope] = constraint_cruise_speed(WS, obj, con_no)
%
%   Inputs
%     WS      takeoff wing loading (W/S)_TO [lbf/ft^2], scalar or row vector
%     obj     discipline bundle from ttpa_disciplines
%     con_no  number of the cruise-speed condition in obj.cons
%   Outputs
%     WP_max  largest (W/P)_TO that meets the cruise speed [lbf/hp]
%     slope   kP / (sigma Ip^3), the slope of the constraint line
%
%   Roskam Part I, Sec. 3.6 relates the cruise speed to the power index
%
%       Ip = [ (W/S) / ( sigma (W/P) ) ]^(1/3)
%
%   which is read from historical data at the required speed, so the
%   requirement is sigma Ip^3 (W/P)_cruise - (W/S)_cruise <= 0. Referring
%   the cruise power to sea-level takeoff power with kP = P_cruise/P_TO
%   gives (W/P)_cruise = (W/P)_TO / kP, and the cruise weight cancels,
%   because it divides the wing loading and the power loading by the same
%   factor. Hence
%
%       (W/P)_TO <= (W/S)_TO kP / ( sigma Ip^3 )
%
%   This is the only constraint that RISES with wing loading: speed can be
%   bought with more power or with a smaller wing. It closes the feasible
%   region from the left.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    kP = obj.prop.power_ratio(state, con);   % P_cruise / P_TO at sea level

    slope  = kP / (state.sigma * con.power_index^3);
    WP_max = slope .* WS;

end
