classdef (Abstract) AeroModelL2 < AerodynamicsBase
%AEROMODELL2  Tier-2 abstract enforcer for Level-2 aerodynamics.
%   L2 is the geometry-dependent clean drag polar plus finite-wing lift; the
%   concrete class reads geometry from an injected object and delegates to the
%   AeroL2 toolbox. The base declares drag_polar and get_CLmax; this enforcer
%   adds no further abstract members. See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL2.md

end
