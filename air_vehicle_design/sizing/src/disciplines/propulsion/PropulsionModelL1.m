classdef (Abstract) PropulsionModelL1 < PropulsionBase
%PROPULSIONMODELL1  Tier-2 abstract enforcer for Level-1 propulsion.
%   Declares the L1 propulsion contract (density-ratio lapse, two-value TSFC
%   table). See docs/decision_log.md. Toolbox companion: PropL1.md

    properties (Abstract)
        engine_type    % string; selects the PropL1 lapse exponent and TSFC row
    end

    methods (Abstract)

        c_t = lookup_TSFC(obj, state)

        %GET_THRUST_LAPSE_CATEGORICAL  Density-ratio lapse at a power rating.
        %   [Martins AE481 metabook Eq. 10.9]
        alpha = get_thrust_lapse_categorical(obj, state, rating)

    end

    methods
        function v = get_thrust_lapse(obj, state, rating)
        %GET_THRUST_LAPSE  PropulsionBase name; forwards to the L1 method.
            v = obj.get_thrust_lapse_categorical(state, rating);
        end

        function v = get_TSFC(obj, state)
            v = obj.lookup_TSFC(state);
        end

    end

end
