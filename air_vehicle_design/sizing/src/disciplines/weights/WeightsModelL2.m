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
        W_landing_gear     % DERIVED [lbf]
        W_tail             % DERIVED struct(HT, VT) [lbf]
        W_fuselage         % DERIVED [lbf]
        W_installed_engine % DERIVED [lbf]
        W_all_else_empty   % DERIVED [lbf]
    end

    methods (Abstract)

        %WEIGHT_WING  [Raymer 6th ed. Table 15.2]
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_wing(obj, W_TO)

        %WEIGHT_TAIL  Struct with fields HT and VT.  [Raymer 6th ed. Table 15.2]
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_tail(obj, W_TO)

        %WEIGHT_FUSELAGE  On WETTED area.  [Raymer 6th ed. Table 15.2]
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_fuselage(obj, W_TO)

        %WEIGHT_LANDING_GEAR  [AE481 metabook Sec. 7]
        %   Must be evaluated at the PASSED W_TO: this term genuinely scales
        %   with gross weight.
        W = weight_landing_gear(obj, W_TO)

    end

end
