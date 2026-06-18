classdef GeometryBase < handle
    % Abstract base class for all geometry discipline implementations.
    %
    % Concrete subclasses must populate S_ref and S_wet.
    % Higher-fidelity classes add more properties (b, AR, cbar, L_fus, etc.)
    % that are read by the aerodynamics and tail-sizing disciplines.

    properties
        S_ref   % Wing reference area (ft²)
        S_wet   % Total wetted area (ft²)
    end
end
