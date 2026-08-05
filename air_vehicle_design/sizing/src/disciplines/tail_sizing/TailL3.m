classdef TailL3
%TAILL3  Level-3 tail-sizing static toolbox: stability-and-control-based
%   sizing (Raymer Ch. 16) -- DOCUMENTED-TODO STUB, ships now as a
%   citation-missing failure structure per CLAUDE.md's testing-rule
%   exception ("deliberately-failing TODO tests for missing citations...
%   clearly labeled").
%
%   Call as TailL3.method(...); never instantiated, not in the inheritance
%   chain. F16TailL3 inherits TailSizingModelL3 and delegates here.
%
%   NO REAL EQUATIONS ARE IMPLEMENTED HERE. Exact Raymer 6th ed. Chapter 16
%   equation numbers for (a) sizing S_HT from a required static margin /
%   C_m_alpha, or (b) sizing S_VT from a required directional-stability
%   derivative, are not verifiable from anything in this repository:
%     - docs/reference_extracts/ is Nicolai & Carichner,
%       not Raymer, and defers the closed-form criteria-based equations to
%       its own Ch. 21/23, both "pending" (not extracted).
%     - raymer_data.md's actual Raymer OCR extract has no Ch. 4/6/16
%       content.
%     - temp_Casey's SandCLevel3.m citations ("eq 16.25", "fig 16.3",
%       "fig 16.16") are unverified against the book and are forward-
%       analysis only.
%     - VnV/BrandtF16A/BrandtBalanceStabControl.m is likewise forward-
%       analysis only and not wired to this framework's own weights
%       classes.
%   Full record: VnV/BrandtF16A/todo.md 2026-07-28 Finding 3 (status
%   RESOLVED-DEFERRED); TailSizing_scribe_plan.md Sec. 6.
%
%   INTENDED FUTURE CONTRACT (design intent, NOT built): see
%   TailSizingModelL3.m's header for the full HT-via-static-margin /
%   VT-via-C_n_beta-and-crosswind description this will implement once real
%   equations are pinned down.
%
%   size(obj) ERRORS with 'TailL3:citationNotAvailable' rather than
%   returning a fabricated value or a silent NaN -- same idiom as
%   GeomL1.lookup_control_surface_fraction's error-on-missing-aileron-
%   fraction case.
%
%   Companion doc: src/disciplines/tail_sizing/TailL3.md

    methods (Static)

        function result = size(obj) %#ok<INUSD>
        %SIZE  NOT IMPLEMENTED -- citation gap.
        %   Raymer Ch. 16 stability-and-control tail-sizing equations (HT via
        %   required static margin/C_m_alpha; VT via required C_n_beta target
        %   + crosswind) are not verifiable from any source in this
        %   repository. Errors rather than fabricating S_ht/S_vt. See
        %   VnV/BrandtF16A/todo.md 2026-07-28 Finding 3 and
        %   TailSizing_scribe_plan.md Sec. 6 for the full citation-gap record
        %   and what would resolve it.
            error('TailL3:citationNotAvailable', ...
                ['Raymer Ch. 16 stability-and-control tail-sizing equations ' ...
                 '(HT sizing via required static margin/C_m_alpha; VT sizing ' ...
                 'via required C_n_beta target + crosswind) are not ' ...
                 'verifiable from any source in this repository -- not ' ...
                 'implemented, not guessed. See VnV/BrandtF16A/todo.md ' ...
                 '2026-07-28 Finding 3 and ' ...
                 'src/disciplines/tail_sizing/TailSizing_scribe_plan.md ' ...
                 'Sec. 6 for the citation-gap record and what would resolve it.']);
        end

    end
end
