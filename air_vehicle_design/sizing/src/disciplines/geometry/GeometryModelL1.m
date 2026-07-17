classdef (Abstract) GeometryModelL1 < GeometryBase
%GEOMETRYMODELL1  Tier-2a abstract enforcer for Level-1 geometry.
%
%   Declares the sub-methods a concrete L1 geometry toolbox must implement.
%   No equations, no coefficient tables — those live in GeomL1 only.
%
%   Inheritance: GeometryBase → GeometryModelL1 → GeomL1 → F16GeomL1

    % Student class sets these; toolbox resolves coefficients from them.
    % MATLAB restriction: Abstract properties cannot have validation attributes.
    % Size/type validation is enforced in the first concrete class (GeomL1).
    properties (Abstract)
        L_fuselage
    end

    methods (Abstract)
        %GET_S_WET_STATISTICAL  Total S_wet from Roskam statistical regression.
        %   W_TO  — takeoff gross weight, lbf
        %   val   — total aircraft wetted area, ft^2
        val = get_S_wet_statistical(obj, W_TO)

        %GET_L_FUS  Fuselage length from Raymer type regression.
        %   W_TO  — takeoff gross weight, lbf
        %   val   — fuselage length, ft
        val = get_L_fus(obj, W_TO)

        % It doesnt need to have get_s_ref because it's a sub-abstract class, not a concrete implementation.
    end
end
