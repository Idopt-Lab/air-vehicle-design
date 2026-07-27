classdef (Abstract) AeroModelL2 < AerodynamicsBase
%AEROMODELL2  Tier-2 abstract enforcer for Level-2 aerodynamics.
%
%   Inherits AerodynamicsBase directly, not another AeroModelLN.
%
%   L2 is the geometry-DEPENDENT clean drag polar plus finite-wing lift. All
%   geometry is read live from an injected geometry object; a concrete L2 class
%   owns no geometry numbers. It supplies the aero-only inputs (airfoil section
%   data, Oswald-e selector) from its .aerodynamics JSON block and delegates to
%   the AeroL2 toolbox.
%
%   The base already declares drag_polar and get_CLmax; this enforcer adds no
%   further abstract members.
%
%   Toolbox companion: src/disciplines/aerodynamics/AeroL2.md

end
