classdef (Abstract) PropulsionModelL1 < PropulsionBase
%PROPULSIONMODELL1  Tier-2 abstract enforcer for Level-1 propulsion.
%
%   Inherits PropulsionBase directly, not another PropulsionModelLN.
%
%   L1 is a density-ratio thrust lapse and a two-value TSFC table: no Mach
%   term in the lapse, no afterburner split, no supersonic value.
%
%   Toolbox companion: src/disciplines/propulsion/PropL1.md

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
