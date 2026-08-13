classdef (Abstract) TailSizingModelL1 < TailSizingBase
%TAILSIZINGMODELL1  Tier-2 abstract enforcer for Level-1 tail sizing.
%
%   Inherits TailSizingBase directly.
%
%   L1 is the volume-coefficient method [Raymer 7th ed. Table 6.4 + text; 6th
%   ed. Sec. 6.5.2, Eqs. (6.28)/(6.29)]: sizes S_ht/S_vt from a tail volume
%   coefficient, the tail moment arms, and the wing planform (S_ref, b, cbar)
%   -- all supplied as RAW SCALARS by the caller. GeometryModelL1 has no
%   planform at all (only a W_TO-based S_wet regression), so a concrete L1
%   tail class cannot be geometry-object-driven the way L2/L3 are.
%
%   MOMENT ARM (clarified 2026-08-11): the arms are now ARGUMENTS, not
%   computed here from L_fus. A caller that genuinely has no layout -- the L1
%   case Raymer wrote the rule for -- gets both from
%   TailL1.compute_tail_arm(L_fus) = 0.475*L_fus and passes the same value
%   twice. A caller that HAS a layout (any L2/L3 geometry object) passes that
%   object's Dependent L_HT/L_VT, which are the real
%   wing-c/4-to-tail-c/4 distances Raymer Sec. 6.5.2 p.158 defines. See
%   TailL1.m's header for why those are not two competing definitions.
%
%   The base already declares size(obj, S_ref, b, cbar, L_HT, L_VT); this
%   enforcer adds no further abstract members.
%
%   Toolbox companion: src/disciplines/tail_sizing/TailL1.md

end
