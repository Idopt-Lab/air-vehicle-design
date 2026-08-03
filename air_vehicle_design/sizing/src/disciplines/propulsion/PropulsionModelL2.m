classdef (Abstract) PropulsionModelL2 < PropulsionBase
%PROPULSIONMODELL2  Tier-2 abstract enforcer for Level-2 propulsion.
%
%   Inherits PropulsionBase directly, not another PropulsionModelLN.
%
%   L2 is the Mattingly parametric model, with separate mil (dry) and AB (wet)
%   branches for both thrust lapse and TSFC.
%
%   The C1/C2 TSFC coefficients are NOT abstract members: they are
%   engine-class constants selected by engine_type inside the PropL2 toolbox.
%   A concrete class supplies engine_type and the throttle ratio.
%
%   Toolbox companion: src/disciplines/propulsion/PropL2.md

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
