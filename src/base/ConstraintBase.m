classdef ConstraintBase < handle
    % Abstract base class for constraint analysis discipline.
    %
    % A constraint analysis sweeps wing loading (W/S) and determines the
    % thrust-to-weight ratio required to satisfy every performance
    % constraint.  The optimal_point method returns the design point that
    % minimises T/W while meeting all constraints.

    methods (Abstract)
        % optimal_point  Returns the best design point from the constraint diagram.
        %   aero   — AerodynamicsBase subclass instance
        %   prop   — PropulsionBase subclass instance
        %
        %   result.W_S  — optimal wing loading (lbf/ft²)
        %   result.T_W  — required thrust-to-weight at that W/S
        result = optimal_point(obj, aero, prop)
    end
end
