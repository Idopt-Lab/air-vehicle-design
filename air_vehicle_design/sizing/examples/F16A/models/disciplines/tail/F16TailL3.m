classdef F16TailL3 < TailSizingModelL3
%F16TAILL3  F-16A Level-3 (stability-and-control) tail sizing --
%   DOCUMENTED-TODO STUB, ships now as a citation-missing failure structure,
%   not real equations. See TailSizingModelL3.m's and TailL3.m's headers for
%   the citation-gap record (VnV/BrandtF16A/todo.md Finding 3).
%
%   Constructible (no arguments): a valid F16TailL3 object satisfies the
%   TailSizingBase/TailSizingModelL3 type contract. Calling size(obj) surfaces
%   a clear 'TailL3:citationNotAvailable' error rather than a fabricated value.
%
%   INTENDED FUTURE CONTRACT once real Raymer Ch. 16 equations are pinned down
%   (design intent only -- NOT built now):
%     - HT sizing via required static margin (invert a neutral-point equation
%       for S_HT given SM_required/C_m_alpha and a CG estimate).
%     - VT sizing via directional stability (Nicolai Sec. 11.2: subsonic
%       C_n_beta target 0.08-0.17 rad^-1, M>2 minimum 0.08 rad^-1).
%     - VT sizing via crosswind landing (Nicolai Sec. 11.2 item 1).
%     - One-engine-out yaw balance skipped (F-16 has a single engine).
%   New f16a_requirements.json fields and a Tail-injects-aero DI pattern are
%   deferred, not added speculatively.
%
%   History and rationale: docs/decision_log.md

    methods

        function obj = F16TailL3()
        %F16TAILL3  No-argument constructor -- no real inputs exist yet, and
        %   the deferred fields are not added speculatively, so there is nothing
        %   to inject or configure at construction time.
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
