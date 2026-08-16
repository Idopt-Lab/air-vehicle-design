classdef TailL3
%TAILL3  Level-3 tail-sizing static toolbox: stability-and-control-based
%   sizing (Raymer Ch. 16) -- NOT YET IMPLEMENTED (documented-TODO stub).
%
%   NO REAL EQUATIONS ARE IMPLEMENTED HERE. Raymer 6th ed. Chapter 16 equation
%   numbers for sizing S_HT from a required static margin/C_m_alpha, or S_VT
%   from a required directional-stability derivative, are not verifiable
%   from any source in this repository. size(obj) errors with
%   'TailL3:citationNotAvailable' rather than fabricating a value.
%
%   See docs/decision_log.md; VnV/BrandtF16A/todo.md 2026-07-28 Finding 3
%   (RESOLVED-DEFERRED); TailSizing_scribe_plan.md Sec. 6.
%   Companion doc: TailL3.md

    methods (Static)

        function result = size(obj) %#ok<INUSD>
        %SIZE  NOT IMPLEMENTED -- citation gap.  Errors rather than
        %   fabricating S_ht/S_vt. See docs/decision_log.md;
        %   VnV/BrandtF16A/todo.md 2026-07-28 Finding 3.
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
