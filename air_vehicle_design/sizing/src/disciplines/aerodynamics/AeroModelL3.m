classdef (Abstract) AeroModelL3 < AerodynamicsBase
%AEROMODELL3  Tier-2 abstract enforcer for Level-3 aerodynamics.
%   L3 replaces L2's type-based Cfe with a per-component Reynolds /
%   skin-friction / form-factor buildup, plus a supersonic wave-drag term in
%   the concrete class; geometry is read from an injected object. The base
%   declares drag_polar and get_CLmax; this enforcer adds no further abstract
%   members. See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL3.md

methods (Abstract)
    val = get_CD0_component_buildup(obj, state)
    val = get_CD0_LandP(obj) % Compute the CD0 contribution of leakages and protuberances
    val = get_CD0_misc(obj) % Compute the CD0 contribution of miscellaneous objects
end

% This makes it so that subclasses of AeroModelL1 have to use the "rough" version of the CD0 estimation.
% "Rough," for now, unless it's changed to the Mattingly CD0 curve.
methods 
    function val = get_CD0(obj, state) % At this point, CD0 IS a function of aerodynamic state.
        val = obj.get_CD0_component_buildup(state);
    end
end

end
