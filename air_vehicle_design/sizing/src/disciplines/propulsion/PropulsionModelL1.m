classdef (Abstract) PropulsionModelL1 < PropulsionBase
%PROPULSIONMODELL1  Tier-2 abstract enforcer for Level-1 propulsion.
%   Declares the L1 propulsion contract (density-ratio lapse, two-value TSFC
%   table). See docs/decision_log.md. Toolbox companion: PropL1.md

    properties (Abstract)
        engine_type    % string; selects the PropL1 lapse exponent and TSFC row
    end

    methods (Abstract)

        %GET_THRUST_LAPSE  Density-ratio lapse.  [Martins AE481 metabook Eq. 10.9]
        alpha = get_thrust_lapse(obj, state)

        %LOOKUP_TSFC  Categorical TSFC [1/hr].  [Raymer 6th ed. Table 3.3]
        c_t = lookup_TSFC(obj, state)

    end

end
