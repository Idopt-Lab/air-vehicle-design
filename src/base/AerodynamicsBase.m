classdef AerodynamicsBase < handle
    % Abstract base class for all aerodynamics discipline implementations.
    %
    % Every fidelity level (AeroLevel1, AeroLevel2, …) inherits from this
    % class and implements the two abstract methods below.  The sizing loop,
    % mission analysis, and constraint analysis call ONLY these two methods,
    % so they work identically regardless of which fidelity level is plugged in.
    %
    % Drag model used throughout the framework:
    %   CD = CD0 + K1*CL + K2*CL^2
    %
    % At Level I and II, K1 = 0 (symmetric polar).
    % At Level III+, K1 captures the CL_minD shift of cambered airfoils.

    methods (Abstract)
        % drag_polar  Returns drag polar coefficients at the given flight state.
        %   state  — AircraftState object (altitude, Mach, q, etc.)
        %   polar  — struct with fields:
        %              polar.CD0  zero-lift drag coefficient
        %              polar.K1   linear CL term (0 at L1/L2)
        %              polar.K2   induced drag factor, ≈ 1/(π·e·AR)
        polar = drag_polar(obj, state)

        % CLmax  Returns maximum usable lift coefficient at the given state.
        %   Used by stall-speed and landing constraints, and climb ceiling.
        CL = CLmax(obj, state)
    end
end
