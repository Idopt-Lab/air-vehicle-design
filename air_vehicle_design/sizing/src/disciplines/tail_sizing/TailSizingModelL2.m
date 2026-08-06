classdef (Abstract) TailSizingModelL2 < TailSizingBase
%TAILSIZINGMODELL2  Tier-2 abstract enforcer for Level-2 tail sizing.
%
%   Inherits TailSizingBase directly.
%
%   L2 is the same volume-coefficient functional form as L1, fed real L2
%   wing geometry and an F-16-specific measured coefficient [Nicolai &
%   Carichner Table 11.6] instead of a generic Raymer category row. All
%   geometry (b_wing, cbar_wing, S_ref, L_fus) is read LIVE from an
%   INJECTED, read-only GeometryModelL2 collaborator supplied at
%   CONSTRUCTION -- a concrete L2 class owns no geometry numbers of its
%   own, matching the DI pattern F16WeightsL2 already uses for its geometry
%   collaborator. size(obj) therefore takes no further arguments (MATLAB
%   does not enforce matching arity against the base's wider abstract
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
