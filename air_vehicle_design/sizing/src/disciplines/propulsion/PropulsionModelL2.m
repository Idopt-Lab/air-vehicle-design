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

        %COMPUTE_THRUST_LAPSE_MIL  Mil-power lapse.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54b]
        alpha_mil = compute_thrust_lapse_mil(obj, state)

        %COMPUTE_THRUST_LAPSE_AB  Afterburner lapse.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.54a]
        alpha_AB = compute_thrust_lapse_AB(obj, state)

        %COMPUTE_TSFC_MIL  Mil-power TSFC [1/hr].  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 3.55a]
        c_t_mil = compute_TSFC_mil(obj, state)

        %COMPUTE_TSFC_AB  Afterburner TSFC [1/hr].  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 3.55b]
        c_t_AB = compute_TSFC_AB(obj, state)

    end

end
