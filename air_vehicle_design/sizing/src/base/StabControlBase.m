classdef (Abstract) StabControlBase < handle
%STABCONTROLBASE  Tier-1 abstract enforcer for all stability & control
%   discipline classes.
%
%   Declares the ONE quantity every fidelity level genuinely provides today:
%   x_cg, the aircraft center-of-gravity x-station. Per
%   docs/subplans/10_stability_control.md's "DECIDED (Casey, 2026-08-03):
%   F16SandCL2 is limited to the CG (x_cg) term only" note, F16GeomL2 exposes
%   NO x-station properties at all, so every OTHER Raymer 6th ed. Ch. 16
%   quantity this discipline eventually computes (Cm_alpha, neutral point,
%   static margin, aerodynamic center, CL_w/CL_h, Delta alpha_L0, the full
%   Cm_cg trim buildup) is L3-ONLY. There is therefore no shared
%   Cm_cg/static_margin/neutral_point contract across BOTH tiers to lift onto
%   this Base the way e.g. AerodynamicsBase's drag_polar/get_CLmax are common
%   to every aero fidelity level -- SandCModelL3 declares that full L3-only
%   set independently; SandCModelL2 adds nothing beyond what is declared here.
%
%   Inheritance: StabControlBase -> SandCModelLN (abstract) -> F16SandCLN
%   The SandCL2/SandCL3 static toolboxes are NOT in this chain -- concrete
%   classes delegate to them.
%
%   SCOPE (docs/subplans/10_stability_control.md): LONGITUDINAL STATIC
%   STABILITY ONLY, steady level flight, Raymer 6th ed. Ch. 16 Sec. 16.3.
%   Explicitly OUT of scope for this discipline: downwash (d(epsilon)/d(alpha)
%   -- wherever a full Raymer equation includes a downwash term, the
%   implementation notes the simplification explicitly, never a silent
%   default), ground effect, takeoff rotation, velocity (speed) stability,
%   lateral-directional static stability and control, handling qualities.
%
%   Companion doc: src/base/StabControlBase.md

    properties (Abstract)
        %X_CG  Aircraft center-of-gravity x-station [ft]. Weighted average of
        %   component weights x each component's own x-station:
        %     x_cg = Sum(W_i * x_i) / Sum(W_i)
        %   [no separate Raymer/Roskam equation number -- standard weighted-
        %   average CG identity; matches VnV/BrandtF16A/readme_bsc.md's own
        %   "CG closure" formula x_cg = Sum_i(W_i x_i)/Sum_i(W_i)]. Computed by
        %   the level-agnostic SandCL2.weighted_cg static, called by BOTH
        %   F16SandCL2 and F16SandCL3 (fidelity-collapse rule -- the equation
        %   itself does not vary with fidelity level, only the component
        %   weight/x-station DATA it is fed does).
        %
        %   MUST propagate NaN gracefully, never error, when a component
        %   weight is not yet available (in particular the 'fuel' group's
        %   W_energy, a mission-analysis STATE that reads NaN until the
        %   mission/sizing loop sets it -- see WeightsBase.m).
        x_cg
    end

end
