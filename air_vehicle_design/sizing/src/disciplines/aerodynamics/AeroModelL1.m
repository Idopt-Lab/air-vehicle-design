classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2 abstract enforcer for Level-1 aerodynamics.
%   The base declares drag_polar and get_CLmax; this enforcer adds no further
%   abstract members. The concrete class delegates to the AeroL1 toolbox.
%   See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL1.md


% methods (Abstract)
%     val = get_CD0_rough(obj, state)
% end

% This makes it so that subclasses of AeroModelL1 have to use the "rough" version of the CD0 estimation.
% "Rough," for now, unless it's changed to the Mattingly CD0 curve.
% methods 
%     function val = get_CD0(obj, state)
%         val = obj.get_CD0_rough(state);
%     end
% end

end


