classdef (Abstract) PropulsionBase < handle
%PROPULSIONBASE  Tier-1 abstract enforcer for all propulsion discipline classes.
%
%   Declares the two methods orchestrators call plus the sea-level thrust
%   property, and provides one defaulted utility.
%
%   Inheritance: PropulsionBase -> PropulsionModelLN (abstract) -> F16PropLN
%   The PropLN static toolboxes are NOT in this chain.
%
%   Propulsion is L1/L2 only; F16PropL2 also serves the L3 rung.
%
%   Companion doc: src/base/PropulsionBase.md

    properties (Abstract)
        T_SL    % lbf — sea-level static (max/AB) thrust
    end

    methods (Abstract)

        %THRUST_LAPSE  alpha = T(alt,M)/T_SL at AB/max power.
        %   state — AircraftState. Returns scalar alpha in [0, 1].
        alpha = thrust_lapse(obj, state)

        %GET_TSFC  Mil-power thrust-specific fuel consumption [1/hr].
        %   For AB TSFC call compute_TSFC_AB on the concrete class.
        %   TSFC is a function of the flight state, so it is a method here and
        %   deliberately not an abstract property.
        c_t = get_TSFC(obj, state)

    end

    methods

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Mil-power lapse expressed on the AB T_SL
        %   scale: alpha = T_mil(alt,M)/T_SL_AB.  [Brandt F-16A.xls, Consts col AU]
        %
        %   Lets a dry-power condition share the T_SL_AB/W_TO constraint-diagram
        %   axis with AB-flown conditions. Defaults to the AB-basis lapse, which
        %   is correct for a class with no separate mil-power model; override in
        %   a concrete class that has one.
            alpha = obj.thrust_lapse(state);
        end

    end

end
