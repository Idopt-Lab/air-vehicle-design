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
%   The Mattingly TSFC coefficients (C1/C2 mil+AB) are NOT declared here as
%   abstract Constants: they are engine-class constants selected by
%   engine_type inside the PropL2 toolbox (PropL2.lookup_TSFC_coeffs),
%   mirroring PropL1's engine_type-keyed lapse/TSFC tables (user decision
%   2026-07-24).  Student classes supply engine_type; the throttle ratio TR
%   is a per-aircraft derived quantity supplied by the concrete class.
%
%   Inheritance: PropulsionBase → PropulsionModelL2 → F16PropL2

    properties (Abstract)
        engine_type % string; selects the PropL2 TSFC coefficient set
                    %   (e.g. "low_bypass_turbofan_AB" for the F100-PW-200)
        TR          % double; — throttle ratio (typical AAF: 1.05–1.08)
    end

    methods (Abstract)
         % Note: citations not required for abstract enforcers because it's
         % not a concrete implementation, just a requirement.

         % DECISION (2026-07-24, matlab-oop-expert): keep the "mil"/"AB"
         % power-setting suffixes. The earlier TODO (7/15/2026) proposed a
         % generic power-setting-agnostic rename, but "mil" (military/dry) and
         % "AB" (afterburner) are the correct, meaningful vocabulary for an
         % AB-equipped fighter and match the Mattingly Eq. 2.54a/b and Eq.
         % 3.55a/b two-branch (dry vs. wet) model these methods implement. A
         % sweeping rename would change the public API (compute_thrust_lapse_*,
         % compute_TSFC_*) that constraints/tests already target and would
         % ripple across src/constraints + examples mid-loop for no fidelity
         % gain. If a genuinely power-setting-generic contract is ever wanted
         % (e.g. an arbitrary throttle parameter), that is a separate dedicated
         % refactor with its own test pass -- not this convergence loop.
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
