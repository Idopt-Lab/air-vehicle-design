classdef TestTailL3 < matlab.unittest.TestCase
%TESTTAILL3  Unit tests for the Level-3 (stability-and-control) tail-sizing
%   documented-TODO stub: TailL3, TailSizingModelL3, F16TailL3.
%
%   L3 ships now as a documented-TODO / deliberately-failing-test structure
%   [src/disciplines/tail_sizing/TailSizing_scribe_plan.md Sec. 6;
%   VnV/BrandtF16A/todo.md 2026-07-28 Finding 3, status RESOLVED-DEFERRED] --
%   exact Raymer 6th ed. Chapter 16 equation numbers for (a) sizing S_HT from
%   a required static margin/C_m_alpha, or (b) sizing S_VT from a required
%   directional-stability derivative, are not verifiable from anything in
%   this repository. This mirrors TestWeightsL1.
%   testTODO_RaymerTable61CoefficientsNotInRepo's convention exactly.
%
%   WHAT IS GREEN vs WHAT IS DELIBERATELY RED, in this file:
%     - Construction and type-contract tests ARE expected to be green:
%       F16TailL3 is constructible and satisfies TailSizingBase/
%       TailSizingModelL3 (so e.g. SizingLoopL2's `tail (1,1) TailSizingBase`
%       type check accepts it) -- only CALLING size() is unimplemented.
%     - testTODO_RaymerChapter16EquationsNotInRepo IS EXPECTED TO BE RED. It
%       is not a regression; it is the labelled marker for the missing
%       citation, exactly like TestWeightsL1's template. Resolving it means
%       either (a) a citable Raymer Ch. 16 equation number is found/supplied
%       and TailL3.size is implemented for real, or (b) the coordinator
%       confirms this discipline stays TODO indefinitely and this test's
%       assertion direction is revisited -- either way, do NOT make this
%       green by fabricating an equation number or a coefficient.

    methods (Test)

        % --- Construction / interface (EXPECTED GREEN) --------------------

        function testF16TailL3IsConstructible(tc)
            obj = F16TailL3();
            tc.verifyTrue(isa(obj, 'F16TailL3'), 'F16TailL3() must construct a real, valid object.');
        end

        function testF16TailL3IsaTailSizingBase(tc)
            tc.verifyTrue(isa(F16TailL3(), 'TailSizingBase'), ...
                'F16TailL3 must satisfy the shared TailSizingBase contract even as a TODO stub, so SizingLoopL2''s tail (1,1) TailSizingBase type check accepts it.');
        end

        function testF16TailL3IsaTailSizingModelL3(tc)
            tc.verifyTrue(isa(F16TailL3(), 'TailSizingModelL3'));
        end

        % --- size() surfaces a clear citation-missing error (EXPECTED GREEN,
        %     this IS the correct, documented behavior of the stub) --------

        function testSizeErrorsWithCitationNotAvailable(tc)
        % TailL3.size (and F16TailL3.size, which delegates to it) must ERROR
        % with a clear, identifiable error ID rather than returning a
        % fabricated S_ht/S_vt or a silent NaN -- same idiom as
        % GeomL1.lookup_control_surface_fraction's error-on-missing-aileron-
        % fraction case.
            obj = F16TailL3();
            tc.verifyError(@() obj.size(), 'TailL3:citationNotAvailable');
        end

        function testStaticSizeErrorsWithCitationNotAvailable(tc)
            tc.verifyError(@() TailL3.size(struct()), 'TailL3:citationNotAvailable');
        end

        function testSizeAcceptsEitherCallingConventionAndStillErrors(tc)
        % F16TailL3.size(obj, varargin) accepts (and ignores) either L1's
        % four-scalar convention or L2/L3's injected-object convention -- a
        % caller using either gets the SAME clear failure either way.
            obj = F16TailL3();
            tc.verifyError(@() obj.size(300, 30, 11, 46.5), 'TailL3:citationNotAvailable');
        end

        % --- DELIBERATE, EXPECTED-RED TODO marker --------------------------

        function testTODO_RaymerChapter16EquationsNotInRepo(tc)
        %TESTTODO_RAYMERCHAPTER16EQUATIONSNOTINREPO  Deliberate, EXPECTED red.
        %
        %   THIS TEST IS EXPECTED TO BE RED. It is not a regression; it is the
        %   labelled marker for a missing citation, following the convention
        %   of TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo.
        %
        %   WHAT IS MISSING: Raymer 6th ed. Chapter 16 equation numbers for
        %   (a) sizing S_HT from a required static margin/C_m_alpha given a
        %   CG estimate, and (b) sizing S_VT from a required directional-
        %   stability derivative (C_n_beta) target plus a crosswind-landing
        %   criterion. Neither temp_AI/docs/disciplines/reference_extracts/
        %   (Nicolai & Carichner, which defers these closed-form criteria to
        %   its own Ch. 21/23, both "pending"/not extracted) nor
        %   raymer_data.md (no Ch. 4/6/16 content) nor temp_Casey's
        %   SandCLevel3.m (unverified citations: "eq 16.25", "fig 16.3",
        %   "fig 16.16", forward-analysis only) nor
        %   VnV/BrandtF16A/BrandtBalanceStabControl.m (also forward-analysis
        %   only, not wired to this framework) supplies a verifiable equation
        %   number. VnV/BrandtF16A/todo.md 2026-07-28 Finding 3
        %   (status RESOLVED-DEFERRED); TailSizing_scribe_plan.md Sec. 6.
        %
        %   HOW THIS TEST DETECTS IT: TailL3.m's own standing header block
        %   states, in words, that "NO REAL EQUATIONS ARE IMPLEMENTED HERE."
        %   While the source itself makes that statement, the citation gap is
        %   open and this test is red. Resolving it means either (a) a real,
        %   citable Raymer Ch. 16 (or equivalent) equation is supplied and
        %   TailL3.size is implemented for real, replacing the error, or
        %   (b) the coordinator makes an explicit decision to leave L3
        %   permanently a stub, in which case THIS test (not the source
        %   comment) is what should be revisited. Do NOT make this green by
        %   deleting the sentence without settling the citation, and do NOT
        %   invent an equation number or a coefficient.
            src = fileread(which('TailL3'));
            tc.verifyFalse(contains(src, 'NO REAL EQUATIONS ARE IMPLEMENTED HERE'), ...
                ['TODO (EXPECTED RED): Raymer Ch. 16 stability-and-control tail-sizing ' ...
                 'equations are not in this repo; TailL3.m still carries the standing TODO. ' ...
                 'VnV/BrandtF16A/todo.md 2026-07-28 Finding 3; TailSizing_scribe_plan.md Sec. 6.']);
        end

    end

end
