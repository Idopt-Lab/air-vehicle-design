classdef (Abstract) TailSizingModelL1 < TailSizingBase
%TAILSIZINGMODELL1  Tier-2 abstract enforcer for Level-1 tail sizing
%   (volume-coefficient method, Raymer 7th ed. Table 6.4 + text). Adds no
%   abstract members beyond the base's size(obj); the concrete class holds an
%   injected geometry object and reads the wing planform (S_ref, b_wing,
%   cbar_wing, L_fus) from it live. See docs/decision_log.md.
%   Toolbox companion: TailL1.md

end
