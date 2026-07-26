classdef (Abstract) AeroModelL3 < AerodynamicsBase
%AEROMODELL3  Tier-2 abstract enforcer for Level-3 aerodynamics.
%
%   Inherits AerodynamicsBase directly, not another AeroModelLN.
%
%   L3 replaces L2's type-based Cfe with a per-component Reynolds /
%   skin-friction / form-factor buildup, and adds a supersonic wave-drag term
%   in the concrete class. All geometry, including the per-component arrays,
%   is read live from an injected geometry object.
%
%   The base already declares drag_polar and get_CLmax; this enforcer adds no
%   further abstract members.
%
%   Toolbox companion: src/disciplines/aerodynamics/AeroL3.md

end
