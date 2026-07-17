classdef (Abstract) PropulsionModelL2 < PropulsionBase
%PROPULSIONMODELL2  Tier-2a abstract enforcer for Level-2 propulsion.
%
%   Inherits PropulsionBase directly (NOT PropulsionModelL1 — each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-2 propulsion uses the Mattingly analytical engine model:
%     thrust_lapse — Mattingly AED 2nd ed. Eq. 2.54 (low-BPR mixed turbofan)
%     TSFC         — Mattingly AED 2nd ed. Eq. 3.12 + 3.55 coefficients
%
%   Student classes supply the engine-specific constants (C1_mil, C2_mil,
%   C1_AB, C2_AB, TR) as Constant properties.
%
%   Inheritance: PropulsionBase → PropulsionModelL2 → F16PropL2

    properties (Abstract)
        TR          % double; — throttle ratio (typical AAF: 1.05–1.08)
    end

    
    properties (Abstract, Constant)
        C1      % TSFC model: mil/AB power, Eq. 3.55a coefficient 1
        C2      % TSFC model: mil/AB power, Eq. 3.55a coefficient 2
        % F-16 example shoudl include C1_mil, C2_mil, C1_AB, C2_AB.
        
    end

    methods (Abstract)
         % Note: citations not required for abstract enforcers because it's
         % not a concrete implementation, just a requirement.

         % TODO (7/15/2026): "mil" and "AB" are too specific. These must be
         % broadly applicable across many design categories. Remove the
         % "mil" and "AB" suffix.
        %COMPUTE_THRUST_LAPSE_MIL  Mil-power lapse α_mil.
        alpha_mil = compute_thrust_lapse_mil(obj, state)

        %COMPUTE_THRUST_LAPSE_AB  Afterburner lapse α_AB.
        alpha_AB = compute_thrust_lapse_AB(obj, state)

        %COMPUTE_TSFC_MIL  Mil-power TSFC in 1/hr.
        c_t_mil = compute_TSFC_mil(obj, state)

        %COMPUTE_TSFC_AB  Afterburner TSFC in 1/hr.
        c_t_AB = compute_TSFC_AB(obj, state)

    end

end
