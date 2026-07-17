classdef (Abstract) GeometryBase < handle
%GEOMETRYBASE  Tier-1 abstract enforcer for all geometry discipline classes.
%
%   Declares ONLY the methods orchestrators (ConstraintAnalysis, SizingLoop,
%   MissionAnalysis) call. No equations, no coefficients.
%
%   Inheritance chain per fidelity level:
%     GeometryBase → GeometryModelLN (abstract) → GeomLN (toolbox) → F16GeomLN

properties (Abstract)
    S_ref
    S_wet
end

    methods (Abstract)
        %GET_S_REF  Wing reference area, ft^2.
        val = get_S_ref(obj)

        %GET_S_WET  Total aircraft wetted area, ft^2.
        %   W_TO is takeoff gross weight in lbf.  L1 uses W_TO for a
        %   statistical regression; L2/L3 use stored planform properties and
        %   accept W_TO only to satisfy this shared signature.
        val = get_S_wet(obj, W_TO) % W_TO not an input here due to potential signature conflict with L3. L1 and L2 need W_TO.
        %  TODO (7/8/2026): remove W_TO from subsequent dependents.
    end
end
