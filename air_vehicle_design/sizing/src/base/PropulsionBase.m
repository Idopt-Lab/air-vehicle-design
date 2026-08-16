classdef (Abstract) PropulsionBase < handle
%PROPULSIONBASE  Tier-1 abstract enforcer for all propulsion discipline classes.
%
%   Declares the two methods orchestrators call plus the sea-level thrust
%   property.
%
%   Inheritance: PropulsionBase -> PropulsionModelLN (abstract) -> F16PropLN
%   The PropLN static toolboxes are NOT in this chain.
%
%   Propulsion is L1/L2 only; F16PropL2 also serves the L3 rung.
%
%   THRUST RATING. thrust_lapse takes a rating string naming the engine power
%   setting; each concrete class validates it against the ratings its engine
%   has:
%     - jet fighter (afterburning): "mil" (military/dry) and "AB" (afterburner)
%     - transport (no afterburner):  "cont" (max continuous), "TO"/"max" (takeoff)
%   All ratings use the one max-power T_SL basis (lapse =
%   T_at_rating(alt,M) / T_SL, T_SL the max/AB sea-level static thrust), so
%   every rating lands on the same T_SL/W_TO constraint-diagram axis.
%
%   Companion doc: src/base/PropulsionBase.md

    properties (Abstract)
        T_SL    % lbf — sea-level static (max/AB) thrust
    end

    methods (Abstract)

        %THRUST_LAPSE  alpha = T_at_rating(alt,M)/T_SL at the given power rating.
        %   state — AircraftState. rating — engine power-setting string the
        %   concrete class validates (fighter "mil"/"AB"; transport
        %   "cont"/"TO"/"max"). Returns scalar alpha in [0, 1].
        alpha = thrust_lapse(obj, state, rating)

        %GET_TSFC  Mil-power thrust-specific fuel consumption [1/hr].
        %   For AB TSFC call compute_TSFC_AB on the concrete class.
        %   TSFC is a function of the flight state, so it is a method here and
        %   deliberately not an abstract property.
        c_t = get_TSFC(obj, state)

    end

end
