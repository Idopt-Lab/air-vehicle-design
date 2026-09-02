classdef (Abstract) WeightsModelL2 < WeightsBase
%WEIGHTSMODELL2  Tier-2 abstract enforcer for Level-2 weights (surface density
%   x area for structural groups, plus gross-weight fractions for landing gear,
%   installed engine and all-else-empty). Inherits WeightsBase; declares the
%   abstract members a concrete L2 class must supply. The DERIVED properties
%   below must be Dependent getters on the concrete class, never stored values.
%   History and rationale: docs/decision_log.md.
%   Toolbox companion: src/disciplines/weights/WeightsL2.md

    properties (Abstract)
        W_wings            % DERIVED [lbf]
        W_installed_engine % DERIVED [lbf]
        W_all_else_empty   % DERIVED [lbf]
    end

    methods (Abstract)

        %WEIGHT_WING  [Raymer 6th ed. Table 15.2]
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = get_wing_weight(obj, S_wing_exposed)

        % Get the operational empty weight via buildup of major component weights.
        % Includes main wings, tail, fuselage, landing gear, installed engine, and "all-else empty".
        % Users are expected to prune irrelevant models from their design.
        W = get_OEW_major_component_buildup(obj, W_TO, S_wing_exposed)

    end

    methods
        function v = get_OEW(obj, W_TO)
            v = obj.get_OEW_major_component_buildup(W_TO);
        end
    end

end
