classdef (Abstract) TailSizingModelL3 < TailSizingBase
%TAILSIZINGMODELL3  Tier-2 abstract enforcer for Level-3 tail sizing.
%
%   Inherits TailSizingBase directly.
%
%   *** DOCUMENTED-TODO STUB *** -- ships now as a citation-missing failure
%   structure, not real equations [scribe plan Sec. 6; CLAUDE.md's testing
%   rule explicitly allows "deliberately-failing TODO tests for missing
%   citations... clearly labeled" as the sole exception to "zero uncited
%   equations"].
%
%   INTENDED FUTURE CONTRACT (design intent only -- NOT implemented by
%   TailL3/F16TailL3 today):
%     - HT sizing via required static margin: invert a neutral-point
%       equation of the general form demonstrated (uncited-per-equation-
%       number) in temp_Casey's SandCLevel3.compute_Xbar_np and
%       BrandtBalanceStabControl.analyze's xnp_ft formula, for S_HT given a
%       target static margin SM_required (or target C_m_alpha) and a CG
%       estimate.
%     - VT sizing via directional stability: Nicolai Sec. 11.2 (in-repo,
%       citable as narrative, p.284) gives the criteria -- subsonic cruise
%       C_n_beta target 0.08-0.17 rad^-1, high-speed (M>2) minimum
%       C_n_beta=0.08 rad^-1. Invert a C_n_beta buildup (VT contribution +
%       wing/fuselage baseline) for S_VT.
%     - VT sizing via crosswind landing: Nicolai Sec. 11.2 item 1 --
%       applicable to the F-16, narrative only.
%     - One-engine-out yaw balance is SKIPPED for the F-16 (single engine,
%       not physically applicable). May remain in the generic contract for
%       a future multi-engine airframe (parallels ControlSurfaceSizer's
%       documented F-16 all-moving-tail exception to Raymer Table 6.5).
%   None of the above is implemented: exact Raymer Ch. 16 equation numbers
%   are not verifiable from anything in this repository (see
%   VnV/BrandtF16A/todo.md 2026-07-28 Finding 3 and the scribe plan Sec. 6
%   for the full citation-gap record). New f16a_requirements.json fields
%   (CG range, SM_required, C_n_beta,required, crosswind design condition)
%   and a Tail-injects-aero DI pattern are DEFERRED, not added
%   speculatively.
%
%   The base already declares size(obj, S_ref, b, cbar, L_fus); this
%   enforcer adds no further abstract members -- F16TailL3 exists and is
%   constructible, but calling its size() surfaces a clear citation-missing
%   error rather than a fabricated value or a silent NaN.
%
%   Toolbox companion: src/disciplines/tail_sizing/TailL3.md

end
