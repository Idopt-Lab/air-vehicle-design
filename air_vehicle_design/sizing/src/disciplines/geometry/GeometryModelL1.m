classdef (Abstract) GeometryModelL1 < GeometryBase
%GEOMETRYMODELL1  Tier-2a abstract enforcer for Level-1 geometry.
%   Declares the methods a concrete L1 geometry must implement. Equations
%   live in GeomL1. See docs/decision_log.md.

    % Abstract properties cannot have validation attributes. The first
    % concrete class (GeomL1) enforces size/type.
    properties (Abstract)
        % L_fus % Not all designs will have this, but you can set it to "0" if you don't have it.
    end

    methods (Abstract)
        % Total wetted area [ft^2] from W_TO [lbf].
        %   Roskam statistical regression.
        % At Geometry L1, the level of fidelity expected is
        % - Whole aircraft S_wet computed
        % - Using statistical regressions
        % User is expected to implement the statistical regression for
        % their aircraft
        val = get_design_S_wet_categorical(obj, W_TO)

        % % Fuselage length [ft] from W_TO [lbf]. Raymer regression.
        % val = get_L_fus_statistical(obj, W_TO)

        %GET_S_REF  Planform reference area of the primary lifting surface [ft^2].
        %   User may provide their own method of computing S_ref or use the toolbox's method if it exists.
        val = get_S_ref(obj)
        
        % Note (8/20/2026)(Casey): I'm pretty sure control effector sizing was moved to L1 and L2 (done).
        val = get_control_effectors_size(obj)
    end


    % This enforces that subclasses should use "get_S_wet_statistical" instead
    % of "get_S_wet."
    methods
        function val = get_S_wet(obj, W_TO)
            val = obj.get_design_S_wet_categorical(W_TO);
        end

    end

end
