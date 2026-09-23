function [WP_max, extra] = constraint_cruise_speed(WS, obj, con_no)
%CONSTRAINT_CRUISE_SPEED  Cruise-speed constraint on the power loading.
%
%   [WP_max, extra] = constraint_cruise_speed(WS, obj, con_no)
%
%   Inputs
%     WS      takeoff wing loading (W/S)_TO [lbf/ft^2], scalar or row vector
%     obj     discipline bundle from ttpa_disciplines
%     con_no  number of the cruise-speed condition in obj.cons
%   Outputs
%     WP_max  largest (W/P)_TO that meets the cruise speed [lbf/hp]
%     extra   struct with the working: .method, .kP, and either .slope
%             (power-index) or .CL/.CD/.LD/.q (drag-based)
%
%   TWO METHODS, selected by the condition's "method" key.
%
%   ------------------------------------------------------------------
%   "power_index"  - the IHW2 method, unchanged, and still the default.
%
%   Roskam Part I, Sec. 3.6 relates the cruise speed to the power index
%
%       Ip = [ (W/S) / ( sigma (W/P) ) ]^(1/3)
%
%   read from historical data at the required speed, so the requirement is
%   sigma Ip^3 (W/P)_cruise - (W/S)_cruise <= 0. Referring the cruise power
%   to sea-level takeoff power with kP = P_cruise/P_TO gives
%   (W/P)_cruise = (W/P)_TO / kP, and the cruise weight cancels because it
%   divides the wing loading and the power loading by the same factor:
%
%       (W/P)_TO <= (W/S)_TO kP / ( sigma Ip^3 )
%
%   ------------------------------------------------------------------
%   "drag_based"  - the refinement.
%
%   The power index is a correlation. It does not read the drag polar, which
%   has two consequences: it cannot notice that the airplane's wetted area
%   changed, and it cannot be checked against the airplane's own physics.
%   Replacing it with the actual power balance at the required speed:
%
%       q    = 0.5 rho V^2
%       C_L  = beta (W/S)_TO / q                  lift equals weight
%       C_D  = C_D0 + K1 C_L^2                    the airplane's own polar
%       P_req/W = V (C_D/C_L) / (550 eta_p)       shaft power per unit weight
%
%   and requiring P_req <= kP P_TO gives
%
%       (W/P)_TO <= 550 eta_p kP / ( beta V (C_D/C_L) )
%
%   THE TWO DISAGREE, AND IT MATTERS. On the sized TTPA the correlation
%   allows (W/P)_TO <= 11.24 at a wing loading of 40, while the drag
%   calculation demands <= 8.67. The IHW2 design point of 9.25 therefore
%   falls about 6 percent short of 200 KTAS at the specified 80 percent power
%   setting; it makes the speed at full throttle with 17 percent margin. So
%   either the Ip = 1.4 reading or the 0.8 power setting is optimistic.
%
%   The drag-based form also reads C_D0 and K, so the cruise curve MOVES as
%   the sizing loop resizes the wing. Under "power_index" it does not, which
%   is why the TTPA design point is stationary through the whole loop.
%
%   Unlike the power-index form, the drag-based form is NOT linear in wing
%   loading and does not rise without limit: past the best-L/D wing loading
%   a bigger wing costs power again.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    kP = obj.prop.power_ratio(state, con);   % P_cruise / P_TO at sea level

    % get_con returns "" when the condition carries no method key. Test with
    % strlength, not isempty: an empty STRING SCALAR is not empty to isempty.
    if isfield(con, 'method') && strlength(string(con.method)) > 0
        method = string(con.method);
    else
        method = "power_index";
    end

    switch method

        case "power_index"
            slope  = kP / (state.sigma * con.power_index^3);
            WP_max = slope .* WS;

            extra = struct('method', method, 'kP', kP, 'slope', slope);

        case "drag_based"
            if isempty(con.ktas)
                error('constraint_cruise_speed:MissingSpeed', ...
                    ['The drag-based cruise constraint needs the required ', ...
                     'speed, but condition %d carries no ktas.'], con_no);
            end

            V     = con.ktas * 6076.115 / 3600;          % ft/s
            q     = 0.5 * state.rho * V^2;               % lbf/ft^2
            eta_p = obj.prop.prop_eff(state, struct('type', "cruise"));
            polar = obj.aero.drag_polar(state);

            CL = con.beta .* WS ./ q;
            CD = polar.CD0 + polar.K1 .* CL.^2;

            WP_max = 550 * eta_p * kP ./ (con.beta .* V .* (CD ./ CL));

            extra = struct('method', method, 'kP', kP, 'q', q, ...
                'CL', CL, 'CD', CD, 'LD', CL ./ CD, 'V_fps', V, 'eta_p', eta_p);

        otherwise
            error('constraint_cruise_speed:UndefinedMethod', ...
                ['Cruise-speed method "%s" is not defined. Use ', ...
                 '"power_index" or "drag_based".'], method);
    end

end
