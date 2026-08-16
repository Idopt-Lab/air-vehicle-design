classdef (Abstract) TailSizingModelL2 < TailSizingBase
%TAILSIZINGMODELL2  Tier-2 abstract enforcer for Level-2 tail sizing.
%
%   Same volume-coefficient form as L1, fed L2 wing geometry and an
%   F-16-specific measured coefficient [Nicolai & Carichner Table 11.6].
%   Geometry is read live from an injected GeometryModelL2 collaborator, so
%   size(obj) takes no further arguments. size(obj) returns
%   struct('S_ht','S_vt'); the caller writes those back into the geometry
%   object.
%
%   Inherits TailSizingBase, which declares size(). Adds no further abstract
%   members. History and rationale: docs/decision_log.md.
%
%   Toolbox companion: src/disciplines/tail_sizing/TailL2.md

end
