classdef (Abstract) SandCModelL2 < StabControlBase
%SANDCMODELL2  Tier-2 abstract enforcer for Level-2 stability & control.
%
%   Adds nothing beyond the inherited x_cg. L2 geometry exposes no
%   x-station properties, so the CG term is the only Ch. 16 quantity that
%   can run at this tier:
%     x_cg = Sum(W_i * x_i) / Sum(W_i)
%   over the component groups, with each group weight read live from an
%   injected weights object and each x-station read once from the JSON.
%
%   Inherits StabControlBase, which declares x_cg. History and rationale:
%   docs/decision_log.md.
%
%   Toolbox companion: src/disciplines/stability_control/SandCL2.md

end

