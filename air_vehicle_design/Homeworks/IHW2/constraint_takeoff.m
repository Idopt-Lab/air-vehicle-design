function [WP_max, TOP23] = constraint_takeoff(WS, obj, con_no)
%CONSTRAINT_TAKEOFF  Takeoff ground-roll constraint on the power loading.
%
%   [WP_max, TOP23] = constraint_takeoff(WS, obj, con_no)
%
%   Inputs
%     WS      takeoff wing loading (W/S)_TO [lbf/ft^2], scalar or row vector
%     obj     discipline bundle from ttpa_disciplines
%     con_no  number of the takeoff condition in obj.cons
%   Outputs
%     WP_max  largest (W/P)_TO that meets the ground roll [lbf/hp]
%     TOP23   FAR 23 takeoff parameter of the required ground roll
%
%   Roskam Part I, Sec. 3.1:
%
%       S_TGR = 4.9 TOP23 + 0.009 TOP23^2
%       TOP23 = (W/S)_TO (W/P)_TO / ( sigma CLmax_TO )
%
%   with S_TGR in ft, W/S in lbf/ft^2 and W/P in lbf/hp. The first relation
%   is solved for TOP23, keeping the positive root, and the second one is
%   inverted for the largest power loading the requirement allows:
%
%       (W/P)_TO <= TOP23 sigma CLmax_TO / (W/S)_TO
%
%   Takeoff is at takeoff weight by definition, so no weight referral is
%   needed. CLmax_TO is the CLmax of the takeoff configuration, which the
%   aerodynamic model returns for the configuration of this condition.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    CLmax_TO = obj.aero.get_CLmax(state, con);

    % Coefficients of S_TGR = 4.9 TOP23 + 0.009 TOP23^2
    a = 0.009;
    b = 4.9;
    c = -con.distance_ft;

    % TOP23 solution; the other root is negative
    TOP23 = (-b + sqrt(b^2 - 4*a*c)) / (2*a);

    WP_max = TOP23 * state.sigma * CLmax_TO ./ WS;

end
