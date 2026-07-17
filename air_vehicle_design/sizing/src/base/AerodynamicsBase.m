classdef (Abstract) AerodynamicsBase < handle
%AERODYNAMICSBASE  Tier-1 base enforcer for all aerodynamics discipline classes.
%
%   Declares the two methods orchestrators call (drag_polar, get_CLmax) as
%   abstract, and provides concrete utility methods that every fidelity level
%   inherits unchanged.
%
%   Inheritance chain per fidelity level:
%     AerodynamicsBase → AeroModelLN (abstract) → F16AeroLN (student class)
%
%   AeroL1/L2/L3 are standalone static toolboxes — they are NOT in this
%   inheritance chain.  Student classes call them via AeroL1.method().

% Properties - these are here for now, until I'm able to find fidelity-specific substitutes for each equation.
% Also so each fidelity level has some consistent property enforcement across each fidelity level.
properties (Abstract)
     e_osw_clean
     CD0
     CDi
     CL
     CD
     CL_minD
     CL_max_clean
     Cf % Skin friction coefficient
     K1
     K2
end


    methods (Abstract)

        %DRAG_POLAR  Drag polar coefficients at the given flight state.
        %   Returns struct with fields CD0, K1, K2.
        polar = drag_polar(obj, state)

        %GET_CLMAX  Maximum usable lift coefficient at the given flight state.
        CLmax = get_CLmax(obj, state)

    end

    methods

        function CD = compute_CD(~, CD0, K1, K2, CL)
        %COMPUTE_CD  CD = CD0 + K1*CL^2 + K2*CL  (cambered polar).
        %   Identical across all fidelity levels.
            CD = CD0 + K1*CL^2 + K2*CL;
        end

        function CL = compute_CL(~, L, q, S_ref)
        %COMPUTE_CL  Lift coefficient from aero forces.
        %   CL = L / (q * S_ref)
        %   Identical across all fidelity levels.
        %   Steady, level flight assumption.
        %   TODO (7/10/2026): Incorporate the version expressing CL as a func of lift slope curve and angle of attack.
            CL = L / (q * S_ref);
        end

        function CD0 = compute_CD0(~, Cf, S_wet, S_ref)
        %COMPUTE_CD0  Simplified CD0 estimate: CD0 = Cf * S_wet / S_ref.
        %   Raymer 6th ed. §12.3.  Useful for L1/L2 quick estimates and for
        %   L3 comparison against the component buildup result.
            CD0 = Cf * S_wet / S_ref;
        end

        function CDi = get_CDi(obj, state, CL)
        %GET_CDI  Induced drag coefficient at the given state and lift coefficient.
        %   Uses the drag polar assembled by drag_polar(state) so the result is
        %   consistent with the active fidelity level.
        %   CDi = K1*CL^2 + K2*CL
            polar = obj.drag_polar(state);
            CDi   = polar.K1 * CL^2 + polar.K2 * CL;
        end

    end

end
