function [WP_max, CGRP, LD, cfg] = constraint_climb(WS, obj, con_no)
%CONSTRAINT_CLIMB  Climb-gradient constraint on the power loading.
%
%   [WP_max, CGRP, LD, cfg] = constraint_climb(WS, obj, con_no)
%
%   Inputs
%     WS      takeoff wing loading (W/S)_TO [lbf/ft^2], scalar or row vector
%     obj     discipline bundle from ttpa_disciplines
%     con_no  number of the climb-gradient condition in obj.cons
%   Outputs
%     WP_max  largest (W/P)_TO that meets the gradient [lbf/hp]
%     CGRP    climb gradient parameter of the condition
%     LD      lift-to-drag ratio in the climb
%     cfg     configuration polar the condition is flown in
%
%   Roskam Part I, Sec. 3.3 writes the requirement through the climb
%   gradient parameter. The first form is what the rules demand, the second
%   is what the propeller delivers:
%
%       CGRP = ( CGR + 1/(L/D) ) / sqrt(CL)
%       CGRP = 18.97 eta_p sqrt(sigma) / ( (W/P) sqrt(W/S) )
%
%   with CD = CD0 + CL^2/(pi AR e) of that configuration and CL its CLmax
%   less the stall margin. The W/P and the W/S of the second form are the
%   values IN THE CLIMB. Referring them to takeoff weight and to sea-level
%   takeoff power with beta = W_condition/W_TO and kP = P_condition/P_TO,
%   using (W/P)_climb = (W/P)_TO beta/kP and (W/S)_climb = (W/S)_TO beta,
%
%       (W/P)_TO <= 18.97 eta_p sqrt(sigma) kP / ( CGRP beta^1.5 sqrt(W/S)_TO )
%
%   beta appears twice, once through W/P and once inside the square root of
%   W/S, which is where the exponent 1.5 comes from. The constant 18.97 is
%   dimensional: keep W/S in lbf/ft^2 and W/P in lbf/hp.
%
%   One function serves all three climb conditions - all engines
%   operating, one engine inoperative and balked landing - because every
%   difference between them is carried by the condition and by the models.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    % Aerodynamics of the configuration
    cfg = obj.aero.get_config_polar(state, con);

    CL = cfg.CL_climb;                  % CLmax of the configuration - margin
    CD = cfg.CD0 + cfg.K1 * CL^2;       % CD0 + CL^2/(pi AR e)
    LD = CL / CD;

    CGRP = (con.G + 1/LD) / sqrt(CL);

    % Propulsion at the condition
    eta_p = obj.prop.prop_eff(state, con);      % propeller efficiency in climb
    kP    = obj.prop.power_ratio(state, con);   % P_condition / P_TO at sea level

    WP_max = 18.97 * eta_p * sqrt(state.sigma) * kP ...
        ./ (CGRP * con.beta^1.5 * sqrt(WS));

end
