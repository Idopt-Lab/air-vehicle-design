classdef (Abstract) AeroModelL3 < AerodynamicsBase
%AEROMODELL3  Tier-2 abstract enforcer for Level-3 aerodynamics.
%   L3 replaces L2's type-based Cfe with a per-component Reynolds /
%   skin-friction / form-factor buildup, plus a supersonic wave-drag term in
%   the concrete class; geometry is read from an injected object. The base
%   declares drag_polar and get_CLmax; this enforcer adds no further abstract
%   members. See docs/decision_log.md.
%   Toolbox companion: src/disciplines/aerodynamics/AeroL3.md

end
