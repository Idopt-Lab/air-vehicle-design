classdef (Abstract) StabControlBase < handle
%STABCONTROLBASE  Tier-1 abstract enforcer for all stability & control
%   discipline classes.
%
%   Declares the one quantity every fidelity level provides today: x_cg, the
%   aircraft center-of-gravity x-station. L2 geometry exposes no x-station
%   properties, so every other Ch. 16 quantity (Cm_alpha, neutral point,
%   static margin, aerodynamic center, CL_w/CL_h, Delta alpha_L0, the Cm_cg
%   trim buildup) is L3-only and declared on SandCModelL3.
%
%   Inheritance: StabControlBase -> SandCModelLN (abstract) -> F16SandCLN.
%   The SandCL2/SandCL3 static toolboxes are not in this chain.
%
%   SCOPE: longitudinal static stability only, steady level flight, Raymer 6th
%   ed. Ch. 16 Sec. 16.3. Out of scope: downwash (noted explicitly wherever a
%   Raymer equation drops the term), ground effect, takeoff rotation, speed
%   stability, lateral-directional stability and control, handling qualities.
%
%   Companion doc: src/base/StabControlBase.md.
%   History and rationale: docs/decision_log.md.

    properties (Abstract)
        %X_CG  Aircraft center-of-gravity x-station [ft]. Weighted average of
        %   component weights x each component's own x-station:
        %     x_cg = Sum(W_i * x_i) / Sum(W_i)
        %   [standard weighted-average CG identity; matches
        %   VnV/BrandtF16A/readme_bsc.md's "CG closure" formula]. Computed by
        %   the level-agnostic SandCL2.weighted_cg static, called by both
        %   F16SandCL2 and F16SandCL3.
        %
        %   Must propagate NaN gracefully, never error, when a component weight
        %   is not yet available (in particular the 'fuel' group's W_energy,
        %   NaN until the mission/sizing loop sets it -- see WeightsBase.m).
        x_cg
    end

end
