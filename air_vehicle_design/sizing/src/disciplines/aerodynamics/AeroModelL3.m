classdef (Abstract) AeroModelL3 < AerodynamicsBase
%AEROMODELL3  Tier-2 abstract enforcer for Level-3 aerodynamics.
%
%   Properties (Constant, Abstract):
%       LandP_rowname (string): aircraft-type row of Raymer 6th ed. Table 12.8.
%
%   Methods (Abstract):
%       get_CD0_component_buildup(state): component-buildup CD0 at a flight state.
%       get_CD0_LandP(CD0_parasite): leakage and protuberance CD0.
%       get_CD0_misc: miscellaneous-object CD0.
%
%   Methods:
%       get_CD0(state): returns get_CD0_component_buildup(state).
%
%   Companion doc: src/disciplines/aerodynamics/AeroL3.md.
%   History and rationale: docs/decision_log.md.

properties (Constant, Abstract)
    LandP_rowname % The aircraft type corresponding to the closest-matching row in Table 12.8, Raymer, 6th edition.
end

methods (Abstract)
    val = get_CD0_component_buildup(obj, state)
    val = get_CD0_LandP(obj, CD0_parasite) % Compute the CD0 contribution of leakages and protuberances
    val = get_CD0_misc(obj) % Compute the CD0 contribution of miscellaneous objects
end

methods
    function val = get_CD0(obj, state) % At this point, CD0 IS a function of aerodynamic state.
        val = obj.get_CD0_component_buildup(state);
    end
end

end
