classdef (Abstract) TailSizingModelL2 < TailSizingBase
%TAILSIZINGMODELL2  Tier-2 abstract enforcer for Level-2 tail sizing.
%
%   Inherits TailSizingBase directly.
%
%   L2 is the same volume-coefficient functional form as L1, fed real L2
%   wing geometry and an F-16-specific measured coefficient [Nicolai &
%   Carichner Table 11.6] instead of a generic Raymer category row, AND
%   (since 2026-08-11) Nicolai's own c.g.-referenced moment arm
%   [Eqs. (11.1)/(11.2)] instead of a Raymer fuselage-length fraction. All
%   geometry (S_ref, b_wing, cbar_wing, x_mac_le_wing, x_c4_ht, x_c4_vt) is
%   read LIVE from an INJECTED, read-only GeometryModelL2 collaborator
%   supplied at CONSTRUCTION -- a concrete L2 class owns no geometry numbers
%   of its own, matching the DI pattern F16WeightsL2 already uses for its
%   geometry collaborator. size(obj) therefore takes no further arguments
%   (MATLAB does not enforce matching arity against the base's wider abstract
%   declaration -- see TailSizingBase.m's header).
%
%   AREA REUSE IS INDIRECT ONLY: size(obj) returns struct('S_ht','S_vt')
%   and nothing else -- no exposed/wetted-area fields, no
%   get_S_exposed_ht-style accessor. The caller writes S_ht/S_vt back into
%   the geometry object; that object's own Dependent properties do the rest
%   [scribe plan Sec. 5.2].
%
%   The base already declares size(...); this enforcer adds no further
%   abstract members.
%
%   Toolbox companion: src/disciplines/tail_sizing/TailL2.md

end
