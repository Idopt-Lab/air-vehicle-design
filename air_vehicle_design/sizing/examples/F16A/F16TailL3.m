classdef F16TailL3 < TailSizingModelL3
%F16TAILL3  F-16A Level-3 (stability-and-control) tail sizing --
%   DOCUMENTED-TODO STUB, ships now as a citation-missing failure structure,
%   not real equations. See TailSizingModelL3.m's header and TailL3.m's
%   header for the full citation-gap record
%   (VnV/BrandtF16A/todo.md 2026-07-28 Finding 3;
%   src/disciplines/tail_sizing/TailSizing_scribe_plan.md Sec. 6).
%
%   Constructible (no arguments): a valid, real F16TailL3 object can be
%   created and satisfies the TailSizingBase/TailSizingModelL3 type
%   contract (e.g. SizingLoopL2's tail (1,1) TailSizingBase check). Calling
%   size(obj), however, surfaces a clear 'TailL3:citationNotAvailable'
%   error rather than a fabricated value or a silent NaN.
%
%   INTENDED FUTURE CONTRACT once real Raymer Ch. 16 equations are pinned
%   down (design intent only -- NOT built now):
%     - HT sizing via required static margin (invert a neutral-point
%       equation for S_HT given SM_required/C_m_alpha and a CG estimate).
%     - VT sizing via directional stability (Nicolai Sec. 11.2 criteria:
%       subsonic C_n_beta target 0.08-0.17 rad^-1, M>2 minimum 0.08 rad^-1;
%       invert a C_n_beta buildup for S_VT).
%     - VT sizing via crosswind landing (Nicolai Sec. 11.2 item 1).
%     - One-engine-out yaw balance SKIPPED (not physically applicable --
%       the F-16 has a single engine).
%   New f16a_requirements.json fields (CG range, SM_required,
%   C_n_beta,required, crosswind design condition) and a Tail-injects-aero
%   DI pattern are DEFERRED, NOT added speculatively -- see
%   TailSizing_scribe_plan.md Sec. 6 for the full deferral list and
%   rationale.

    methods

        function obj = F16TailL3()
        %F16TAILL3  No-argument constructor -- no real inputs exist yet.
        %   Sec. 6's deferral list (CG range, SM_required, C_n_beta,required,
        %   crosswind design condition, and a Tail-injects-aero DI pattern)
        %   is explicitly NOT added speculatively, so there is nothing to
        %   inject or configure at construction time.
        end

        function result = size(obj, varargin)
        %SIZE  NOT IMPLEMENTED -- delegates to TailL3.size, which errors
        %   with a clear citation-missing message. Accepts (and ignores)
        %   any extra arguments so a caller using either L1's four-scalar
        %   convention (obj, S_ref, b, cbar, L_fus) or L2/L3's
        %   injected-object convention (obj) gets the same clear failure
        %   either way.
            result = TailL3.size(obj);
        end

    end

end
