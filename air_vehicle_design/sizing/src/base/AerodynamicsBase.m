classdef (Abstract) AerodynamicsBase < handle
%AERODYNAMICSBASE  Tier-1 abstract enforcer for all aerodynamics discipline classes.
%
%   Declares the two-method contract orchestrators call, plus two
%   fidelity-independent utilities every level inherits unchanged.
%
%   Inheritance: AerodynamicsBase -> AeroModelLN (abstract) -> F16AeroLN
%   The AeroLN static toolboxes are NOT in this chain.
%
%   K-convention: CD = CD0 + K1*CL^2 + K2*CL, K1 quadratic/induced and K2
%   linear/camber.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9]
%
%   Companion doc: src/base/AerodynamicsBase.md

    methods (Abstract)

        %DRAG_POLAR  Drag polar at the given flight state.
        %   Returns struct with fields CD0, K1, K2.
        polar = drag_polar(obj, state)

        %GET_CLMAX  Maximum usable lift coefficient at the given flight state.
        CLmax = get_CLmax(obj, state)

    end

    methods

        function CD = compute_CD(~, CD0, K1, K2, CL)
        %COMPUTE_CD  Drag coefficient.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9]
            CD = CD0 + K1*CL^2 + K2*CL;
        end

        function CL = compute_CL(~, L, q, S_ref)
        %COMPUTE_CL  Lift coefficient in steady level flight.  [Nicolai Eq. 2.1]
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
