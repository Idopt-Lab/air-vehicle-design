classdef (Abstract) AeroModelL2 < AerodynamicsBase
%AEROMODELL2  Tier-2 abstract enforcer for Level-2 aerodynamics.
%   L2 is the geometry-dependent clean drag polar plus finite-wing lift; the
%   concrete class reads geometry from an injected object and delegates to the
%   AeroL2 toolbox. The base declares drag_polar and get_CLmax; this enforcer
%   adds no further abstract members. See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL2.md

% methods (Abstract)
%     val = get_CD0_rough()
% end

% This makes it so that subclasses of AeroModelL1 have to use the "rough" version of the CD0 estimation.
% "Rough," for now, unless it's changed to the Mattingly CD0 curve.
% methods 
%     function val = get_CD0(obj)
%         val = obj.get_CD0_rough();
%     end
% end

end


