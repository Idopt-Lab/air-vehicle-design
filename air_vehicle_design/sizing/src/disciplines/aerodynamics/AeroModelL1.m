classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2 abstract enforcer for Level-1 aerodynamics.
%
%   Inherits AerodynamicsBase directly, not another AeroModelLN.
%
%   L1 is a geometry-FREE aircraft-type drag polar: a concrete class takes no
%   geometry object. It supplies the type-curve and classification inputs from
%   its .aerodynamics JSON block and delegates to the AeroL1 toolbox.
%
%   The base already declares drag_polar and get_CLmax; this enforcer adds no
%   further abstract members.
%
%   Toolbox companion: src/disciplines/aerodynamics/AeroL1.md

end
