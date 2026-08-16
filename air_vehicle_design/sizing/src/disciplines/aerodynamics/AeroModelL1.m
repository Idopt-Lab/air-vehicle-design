classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2 abstract enforcer for Level-1 aerodynamics.
%   The base declares drag_polar and get_CLmax; this enforcer adds no further
%   abstract members. The concrete class delegates to the AeroL1 toolbox.
%   See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL1.md

end
