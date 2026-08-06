classdef (Abstract) TailSizingModelL1 < TailSizingBase
%TAILSIZINGMODELL1  Tier-2 abstract enforcer for Level-1 tail sizing.
%
%   Inherits TailSizingBase directly.
%
%   L1 is the volume-coefficient method [Raymer 7th ed. Table 6.4 + text]:
%   sizes S_ht/S_vt from a tail volume coefficient, an assumed tail moment
%   arm (a fraction of fuselage length), and the wing planform (S_ref, b,
%   cbar) supplied as RAW SCALARS by the caller. GeometryModelL1 has no
%   planform at all (only a W_TO-based S_wet regression), so a concrete L1
%   tail class cannot be geometry-object-driven the way L2/L3 are.
%
%   The base already declares size(obj, S_ref, b, cbar, L_fus); this
%   enforcer adds no further abstract members.
%
%   Toolbox companion: src/disciplines/tail_sizing/TailL1.md

end
