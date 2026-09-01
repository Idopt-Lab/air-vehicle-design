classdef (Abstract) WeightsModelL1 < WeightsBase
%WEIGHTSMODELL1  Tier-2 abstract enforcer for Level-1 weights (statistical
%   empty-weight fraction). Inherits WeightsBase; declares the abstract members
%   a concrete L1 class must supply. No DERIVED properties.
%   History and rationale: docs/decision_log.md.
%   Toolbox companion: src/disciplines/weights/WeightsL1.md

    properties (Abstract)
        aircraft_category   % string; selects the coefficient rows
    end

    methods (Abstract)

        %GET_OEW  OEW
        OEW = get_OEW_categorical(obj, W_TO)

    end

    methods
        function v = get_OEW(obj, W_TO)
            v = obj.get_OEW_categorical(W_TO);
        end
    end

end
