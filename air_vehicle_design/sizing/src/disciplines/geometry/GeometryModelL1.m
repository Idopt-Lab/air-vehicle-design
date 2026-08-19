classdef (Abstract) GeometryModelL1 < GeometryBase
%GEOMETRYMODELL1  Tier-2a abstract enforcer for Level-1 geometry.
%   Declares the methods a concrete L1 geometry must implement. Equations
%   live in GeomL1. See docs/decision_log.md.

    % Abstract properties cannot have validation attributes. The first
    % concrete class (GeomL1) enforces size/type.
    properties (Abstract)
        L_fuselage
    end

    methods (Abstract)
        %GET_S_WET_STATISTICAL  Total wetted area [ft^2] from W_TO [lbf].
        %   Roskam statistical regression.
        val = get_S_wet_statistical(obj, W_TO)

        %GET_L_FUS  Fuselage length [ft] from W_TO [lbf]. Raymer regression.
        val = get_L_fus(obj, W_TO)
    end

    % This enforces that subclasses should use "get_S_wet_statistical" instead
    % of "get_S_wet."
    methods
        function val = get_S_wet(obj, W_TO)
            val = obj.get_S_wet_statistical(W_TO);
        end
    end
end
