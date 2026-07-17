classdef (Abstract) PropulsionModelL1 < PropulsionBase
%PROPULSIONMODELL1  Tier-2a abstract enforcer for Level-1 propulsion.
%
%   Inherits PropulsionBase directly (NOT PropulsionModelL2 or L3 — each
%   fidelity enforcer independently satisfies the Tier-1 contract).
%
%   Level-1 propulsion uses two simplified models:
%     thrust_lapse — density-ratio power law: α = σ^0.6   [Raymer 6th §5.4]
%     TSFC         — categorical lookup by engine type      [Raymer 6th Table 3.3]
%
%   Inheritance: PropulsionBase → PropulsionModelL1 → F16PropL1

    properties (Abstract)
        engine_type    % string; selects PropL1 TSFC table row
                       %   (e.g. "low_bypass_turbofan_AB" for the F100-PW-200)
    end

    methods (Abstract)

        %COMPUTE_THRUST_LAPSE  Density-ratio lapse: α = σ^0.6.
        %   σ = ρ/ρ_SL.  No Mach correction.  [Raymer 6th ed. §5.4]
        alpha = compute_thrust_lapse(obj, state)
        % TODO 7/15/2026): This should be "get_thrust_lapse" since it's
        % using state and obj as args.

        %LOOKUP_TSFC  Categorical TSFC from engine-type table.
        %   Returns TSFC in 1/hr appropriate for the flight state.
        %   [Raymer 6th ed. Table 3.3]
        c_t = lookup_TSFC(obj, state)

    end

end
