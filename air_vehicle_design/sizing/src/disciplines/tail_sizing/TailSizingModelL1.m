classdef (Abstract) TailSizingModelL1 < TailSizingBase
%TAILSIZINGMODELL1  Tier-2 abstract enforcer for Level-1 tail sizing
%   (volume-coefficient method, Raymer 7th ed. Table 6.4 + text). Adds no
%   abstract members beyond the base's size(obj, S_ref, b, cbar, L_fus);
%   the L1 caller supplies the wing planform as raw scalars.
%   See docs/decision_log.md. Toolbox companion: TailL1.md

end
