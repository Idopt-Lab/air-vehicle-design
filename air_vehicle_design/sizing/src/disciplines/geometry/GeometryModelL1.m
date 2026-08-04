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

    % ============================ TAIL SIZING (absorbed from the former tail_sizing discipline, 2026-08-03) ============================ %
    % Tail sizing is organizationally part of Geometry (Casey's decision, 2026-08-03):
    % the standalone tail_sizing discipline (TailSizingBase/TailSizingModelL1/TailL1/
    % F16TailL1) is retired and its L1 volume-coefficient method absorbed here.
    % Mirrors TailSizingBase's old contract exactly -- raw scalars, because
    % GeometryModelL1 has no planform of its own (only a W_TO-based S_wet
    % regression), so the caller supplies S_ref/b/cbar/L_fus directly.
    methods (Abstract)
        %SIZE_TAIL  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  Returns struct('S_ht', S_ht,
        %   'S_vt', S_vt) -- lowercase field names, matching GeometryBase-
        %   derived classes' own S_ht/S_vt property casing.
        result = size_tail(obj, S_ref, b, cbar, L_fus)
    end
    % ==================================================================================================================================== %
end
