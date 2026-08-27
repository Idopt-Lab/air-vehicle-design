classdef (Abstract) PropulsionModelL2 < PropulsionBase
%PROPULSIONMODELL2  Tier-2 abstract enforcer for Level-2 propulsion.
%   Declares the L2 propulsion contract (Mattingly parametric model, separate
%   mil/AB branches for lapse and TSFC). A concrete class supplies engine_type
%   and throttle ratio. See docs/decision_log.md. Toolbox companion: PropL2.md

    properties (Abstract)
        engine_type % string; selects the PropL2 TSFC coefficient set
        TR          % throttle ratio
    end

    methods (Abstract)

        c_t = get_TSFC_installed(obj, state, rating)

        alpha = get_thrust_lapse_parametric(obj, state, rating)

    end

    methods
        function v = get_thrust_lapse(obj, state, rating)
            v = obj.get_thrust_lapse_parametric(state, rating);
        end
        function v = get_TSFC(obj, state, rating)
            v = obj.get_TSFC_installed(state, rating);
        end
    end

end
