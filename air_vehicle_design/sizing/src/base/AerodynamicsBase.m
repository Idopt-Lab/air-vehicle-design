classdef (Abstract) AerodynamicsBase < handle
%AERODYNAMICSBASE  Tier-1 base enforcer for all aerodynamics discipline classes.
%
%   Enforces ONLY the two-method contract every orchestrator (ConstraintAnalysis,
%   MissionAnalysis, SizingLoop) actually calls:
%
%     drag_polar(state) -> struct(CD0, K1, K2)   Convention A (see below)
%     get_CLmax(state)  -> scalar
%
%   and provides two universal, fidelity-independent utility methods
%   (compute_CD, compute_CL) that every level inherits unchanged.
%
%   Inheritance chain per fidelity level:
%     AerodynamicsBase -> AeroModelLN (abstract) -> F16AeroLN (student class)
%
%   AeroL1/L2/L3 are standalone static toolboxes -- they are NOT in this
%   inheritance chain.  Student classes call them via AeroLN.method().
%
%   ---------------------------------------------------------------------------
%   K-CONVENTION (SETTLED -- Convention A):
%     CD = CD0 + K1*CL^2 + K2*CL
%   K1 is the quadratic/induced factor, K2 the linear/camber-offset term. This
%   matches Mattingly AED 2nd ed. Eq. 2.9, Brandt Aero!G17, ThrustConstraint,
%   and every AeroLN toolbox. (The K1/K2-swapped "Convention B" in the stale
%   temp_AI/docs is NOT followed here.)
%
%   DESIGN NOTE (Aero deep-dive Phase C, 2026-07-23): the former abstract
%   computed-quantity property block (e_osw_clean, CD0, CDi, CL, CD, CL_minD,
%   CL_max_clean, Cf, K1, K2) was REMOVED. Those are derived outputs, not
%   stored inputs; forcing every concrete class to carry them as frozen "=0"
%   plain properties was stale-by-construction (a frozen K1=0 never reflected a
%   mutated AR). Derived quantities now live either in the struct returned by
%   drag_polar or in the concrete class's own properties (Dependent) getters
%   that recompute live from the injected geometry object. Author-specific K
%   decompositions (Mattingly K'/K'', Brandt single-e0, Raymer single-K) stay
%   inside the level toolboxes; the base sees only the assembled {CD0,K1,K2}.

    methods (Abstract)

        %DRAG_POLAR  Drag polar coefficients at the given flight state.
        %   Returns struct with fields CD0, K1, K2 (Convention A).
        polar = drag_polar(obj, state)

        %GET_CLMAX  Maximum usable lift coefficient at the given flight state.
        CLmax = get_CLmax(obj, state)

    end

    methods

        function CD = compute_CD(~, CD0, K1, K2, CL)
        %COMPUTE_CD  CD = CD0 + K1*CL^2 + K2*CL   (Convention A).
        %   Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002, Eq. 2.9
        %   (Brandt Aero!G17 form). Identical across all fidelity levels.
            CD = CD0 + K1*CL^2 + K2*CL;
        end

        function CL = compute_CL(~, L, q, S_ref)
        %COMPUTE_CL  Lift coefficient from aero forces.
        %   CL = L / (q * S_ref)   -- definitional (Nicolai Eq. 2.1).
        %   Steady, level-flight assumption. Identical across all fidelity
        %   levels. S_ref and q guarded positive (division denominators).
            arguments
                ~
                L     (1,1) double
                q     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            CL = L / (q * S_ref);
        end

    end

end
