classdef TestWeightsL1 < matlab.unittest.TestCase
%TESTWEIGHTSL1  Unit tests for the Level-1 weight estimation toolbox.
%
%   Tests: WeightsL1 (static toolbox) + F16WeightsL1 (student class).
%
%   TWO L1 METHODS tested here:
%     (1) Raymer 7th ed. Table 3.1 power law -- central estimate
%         (We/Wto = Kvs * A * W_TO^C).  OEW delegates to this one.
%     (2) Roskam Part I Eq. 2.16 log-log   -- MINIMUM achievable W_E bound.
%
%   CONSTRUCTOR (Phase 4, 2026-07-25): F16WeightsL1(json_path), json_path
%   REQUIRED -- f16a_spec_path(1).  L1 reads no requirements file and injects
%   nothing (no geometry, no propulsion): both regressions take only W_TO and
%   aircraft_category.
%
%   ======================================================================== %
%   ! THE OEW-vs-BRANDT AGREEMENT CHECK IS NOT IN THIS FILE ANY MORE.
%
%   Removed in Phase 4 (LOCKED; F16WeightsL1.md Sec. F, docs/
%   weights_parameter_usage.md §4, todo 2026-07-25 Phase 4 review
%   finding #14):
%       testOEWWithinBrandsValue    (expected = 19148, +-8 %)
%       testRoskamMinBoundBelowBrandt (expected_brandt = 19148)
%   Both asserted 19,148 lbf citing "Brandt F-16A.xls, sheet Wt, B12". That
%   cell is 19980.700578 (live-read 2026-07-25); 19,148.08 is corrections.xls
%   Wt!B12, Casey's revised-weight workbook (F16Baseline.m:136). Two distinct
%   provenances ~4.3 % apart, so the citation was a wrong-workbook
%   attribution -- AND, per CLAUDE.md's two-tier rule, an agreement check
%   against ground truth is not a unit test at all. Both figures now appear as
%   labelled columns of examples/F16A/weights_brandt_comparison.m
%   (Brandt = 19,980.70, Alt = 19,148.08).
%
%   NOTHING IN THIS FILE MAY TAKE AN EXPECTED VALUE FROM
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json OR FROM THE COMPARISON
%   REPORT. Every expected value below is either a structural invariant, an
%   internal identity, a table constant transcribed from a named repo extract
%   with file:line, or hand-arithmetic recorded in the comment above the test.
%   ======================================================================== %
%
%   HAND-COMPUTED EXPECTED VALUES (decimal arithmetic done in this comment
%   block, NOT by calling the code under test and NOT copied from any .json):
%
%   (A) Raymer Table 3.1 jet-fighter row, transcribed from the named repo
%       extract temp_AI/docs/disciplines/reference_extracts/metabook_data.md:22
%       -> A(US) = 2.34, C = -0.13, Kvs(fixed) = 1.00.
%
%       We/Wto at W_TO = 31,377 lbf:
%         ln(31377) = ln(3.1377) + ln(1e4)
%                   = [ln 3 + ln(1.0459)] + 9.21034037
%           ln(1.0459), series x - x^2/2 + x^3/3 - x^4/4 + x^5/5 with x=0.0459:
%             0.0459 - 0.00105341 + 0.00003224 - 0.00000111 + 0.00000004
%                   = 0.04487776
%           ln(3.1377) = 1.09861229 + 0.04487776 = 1.14349005
%         ln(31377)   = 1.14349005 + 9.21034037 = 10.35383042
%         -0.13 * 10.35383042 = -1.34599795
%         exp(0.34599797) = 1 + 0.34599797 + 0.05985930 + 0.00690372
%                             + 0.00059716 + 0.00004132 + 0.00000238
%                             + 0.00000012 = 1.41340197
%         exp(1.34599797) = e * 1.41340197 = 2.71828183 * 1.41340197
%                         = 3.84202456
%         31377^(-0.13)   = 1 / 3.84202456 = 0.26027944
%         We/Wto = 1.00 * 2.34 * 0.26027944 = 0.60905389
%         OEW    = 0.60905389 * 31377
%                = 18826.2 + 282.393 + 1.6909 = 19110.284 lbf
%
%   (B) Roskam Table 2.15 jet-fighter row, transcribed from
%       temp_AI/docs/disciplines/reference_extracts/roskam_vol1_data.md:57
%       -> A = 0.5091, B = 0.9505.  Eq. 2.16 (roskam_vol1_data.md:47):
%         log10(W_E) = (log10(W_TO) - A) / B
%         log10(31377) = ln(31377)/ln(10) = 10.35383042 / 2.30258509
%                      = 4.49661229
%         (4.49661229 - 0.5091) / 0.9505 = 3.98751229 / 0.9505 = 4.19517338
%         10^0.19517338 = exp(0.19517338 * 2.30258509) = exp(0.44940341)
%                       = exp(0.45) * exp(-0.00059659)
%                       = 1.56831219 * 0.99940359 = 1.56737656
%         W_E_min = 1.56737656e4 = 15673.77 lbf
%
%   TOLERANCE RATIONALE. The two hand values above carry ~7 significant
%   figures through 2-3 chained exp/ln series evaluations, so their own
%   arithmetic truncation is of order 1e-6 relative. RelTol = 1e-5 is that
%   truncation with an order of margin. It is NOT reverse-engineered from the
%   code's output, and it is deliberately far TIGHTER than the +-8 %
%   "statistical scatter" tolerance the removed Brandt-agreement test used:
%   these are exact-formula checks, not regression-scatter checks. The
%   statistical scatter of Raymer Table 3.1 is a property of the METHOD, not
%   of the arithmetic, and belongs in the comparison report.

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            g = TestWeightsL1.makeW1();
            tc.verifyTrue(isa(g, 'WeightsBase'), ...
                'F16WeightsL1 must inherit WeightsBase (Tier-1 contract).');
        end

        function testIsaWeightsModelL1(tc)
            g = TestWeightsL1.makeW1();
            tc.verifyTrue(isa(g, 'WeightsModelL1'), ...
                'F16WeightsL1 must inherit WeightsModelL1 (Tier-2a contract).');
        end

        function testNotIsaWeightsModelL2(tc)
            g = TestWeightsL1.makeW1();
            tc.verifyFalse(isa(g, 'WeightsModelL2'), ...
                'F16WeightsL1 must NOT inherit WeightsModelL2.');
        end

        function testConstructorRequiresJSONPath(tc)
        %TESTCONSTRUCTORREQUIRESJSONPATH  No silent default (Phase 4 contract).
        %   F16WeightsL1() used to be a no-argument constructor with hardcoded
        %   classdef defaults. The spec path is now required, matching
        %   F16PropL2(json_path) / F16GeomL2(json_path, prop).
            tc.verifyError(@() F16WeightsL1(), 'MATLAB:minrhs', ...
                'F16WeightsL1 must require a spec JSON path (no silent default).');
        end

    end

    % ------------------------------------------------------------------ %
    % Low-level: Raymer Table 3.1 power-law formula
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWeFractionIsLessThanOne(tc)
            % Sanity: no aircraft can have empty weight >= takeoff weight.
            frac = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 31377);
            tc.verifyLessThan(frac, 1.0, ...
                'We/Wto fraction must be < 1 for all physical designs.');
        end

        function testWeFractionDecreasesWithWTO(tc)
            % For C<0, fraction falls as W_TO grows (heavier aircraft are
            % proportionally lighter).
            frac_small = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 10000);
            frac_large = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 50000);
            tc.verifyGreaterThan(frac_small, frac_large, ...
                'Jet-fighter fraction must decrease with W_TO (C = -0.13 < 0).');
        end

        function testWeFractionPowerLawHandComputed(tc)
        %TESTWEFRACTIONPOWERLAWHANDCOMPUTED  Header derivation (A), the formula.
        %   Expected 0.60905389 is the hand arithmetic in the class header,
        %   evaluated from the metabook_data.md:22 constants -- not by calling
        %   We_fraction_power_law and not from a ground-truth file.
            frac = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 31377);
            tc.verifyEqual(frac, 0.60905389, 'RelTol', 1e-5, ...
                ['We/Wto must equal 1.00*2.34*31377^(-0.13) = 0.60905389 ' ...
                 '[Raymer 7th ed. Tbl 3.1; metabook_data.md:22].']);
        end

        function testWeRoskamHandComputed(tc)
        %TESTWEROSKAMHANDCOMPUTED  Header derivation (B), the formula.
            W_E = WeightsL1.We_roskam(0.5091, 0.9505, 31377);
            tc.verifyEqual(W_E, 15673.77, 'RelTol', 1e-5, ...
                ['Roskam Eq. 2.16 min W_E at W_TO=31377 must equal ' ...
                 '10^((log10(31377)-0.5091)/0.9505) = 15673.77 lbf ' ...
                 '[roskam_vol1_data.md:47 (eq) + :57 (row)].']);
        end

    end

    % ------------------------------------------------------------------ %
    % Low-level: Roskam Eq. 2.16 vs Raymer Table 3.1 -- ordering property
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWeRoskamLowerThanRaymerL1(tc)
            % Roskam gives a MINIMUM bound; Raymer Table 3.1 gives a higher
            % central estimate. Property of the two formulas, no external
            % expected value involved.
            W_roskam = WeightsL1.We_roskam(0.5091, 0.9505, 31377);
            W_raymer = WeightsL1.We_fraction_power_law(1.00, 2.34, -0.13, 31377) * 31377;
            tc.verifyLessThan(W_roskam, W_raymer, ...
                'Roskam L1 min W_E must be below Raymer L1 central estimate.');
        end

    end

    % ------------------------------------------------------------------ %
    % High-level: F-16A student class (Raymer power law)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            g = TestWeightsL1.makeW1();
            oew = g.OEW(31377);
            tc.verifyLessThan(oew, 31377, ...
                'OEW must be less than W_TO for any physical design.');
        end

        function testOEWGreaterThanZero(tc)
            g = TestWeightsL1.makeW1();
            oew = g.OEW(31377);
            tc.verifyGreaterThan(oew, 0, 'OEW must be positive.');
        end

        function testOEWHandComputed(tc)
        %TESTOEWHANDCOMPUTED  Replaces the removed Brandt-agreement gate.
        %   Expected 19110.284 lbf is header derivation (A), carried through
        %   the multiplication by W_TO by hand. This is the L1 correctness
        %   evidence: an internal check against the cited formula and the
        %   extract's own coefficients, with no external target.
            g = TestWeightsL1.makeW1();
            tc.verifyEqual(g.OEW(31377), 19110.284, 'RelTol', 1e-5, ...
                ['L1 OEW(31377) must equal (1.00*2.34*31377^-0.13)*31377 = ' ...
                 '19110.284 lbf [Raymer 7th ed. Tbl 3.1; metabook_data.md:22].']);
        end

        function testRoskamBoundHandComputed(tc)
        %TESTROSKAMBOUNDHANDCOMPUTED  Header derivation (B) via the class.
        %   Replaces the removed testRoskamMinBoundBelowBrandt, which compared
        %   the bound against the mis-cited 19,148.
            g = TestWeightsL1.makeW1();
            tc.verifyEqual(g.compute_We_roskam(31377), 15673.77, 'RelTol', 1e-5, ...
                ['L1 Roskam minimum W_E(31377) must equal 15673.77 lbf ' ...
                 '[Roskam Part I Eq. 2.16 + Tbl 2.15; roskam_vol1_data.md:47,:57].']);
        end

        function testOEWIsPureFunctionOfItsArgument(tc)
        %TESTOEWISPUREFUNCTIONOFITSARGUMENT  W_TO comes from the ARGUMENT.
        %   The L1 analog of review finding #5's guard: OEW must not read
        %   obj.W_TO. obj.W_TO stays NaN (sizing-loop state), and OEW(31377)
        %   must still return the hand-computed value -- and OEW(2*W_TO) must
        %   differ from OEW(W_TO).
            g = TestWeightsL1.makeW1();
            tc.verifyTrue(isnan(g.W_TO), ...
                'obj.W_TO must be NaN until the sizing loop sets it.');
            tc.verifyEqual(g.OEW(31377), 19110.284, 'RelTol', 1e-5, ...
                'OEW must work with obj.W_TO unset -- it is a pure function of its argument.');
            tc.verifyNotEqual(g.OEW(62754), g.OEW(31377), ...
                'OEW must respond to its argument.');
        end

        function testWeFractionMatchesOEW(tc)
            % Internal-consistency identity: frac * W_TO == OEW.
            g = TestWeightsL1.makeW1();
            W_TO     = 31377;
            expected = g.compute_We_fraction(W_TO) * W_TO;
            tc.verifyEqual(g.OEW(W_TO), expected, 'AbsTol', 1e-9, ...
                'OEW must equal compute_We_fraction * W_TO exactly.');
        end

        function testComputeWeFractionWithExplicitCategory(tc)
            % compute_We_fraction(W_TO, category) overrides obj.aircraft_category.
            g = TestWeightsL1.makeW1();
            W_TO = 31377;
            frac_fighter   = g.compute_We_fraction(W_TO, 'jet_fighter');
            frac_transport = g.compute_We_fraction(W_TO, 'jet_transport');
            tc.verifyNotEqual(frac_fighter, frac_transport, ...
                'Explicit aircraft_category argument must change the fraction.');
        end

        function testJetFighterCategorySetCorrectly(tc)
            g = TestWeightsL1.makeW1();
            tc.verifyEqual(lower(g.aircraft_category), 'jet_fighter', ...
                'F16WeightsL1 aircraft_category must be "jet_fighter".');
        end

        function testPayloadInputsComeFromJSON(tc)
        %TESTPAYLOADINPUTSCOMEFROMJSON  Constructor reads .weights, not defaults.
        %   700 / 4400 are Brandt Wt!B4 / Wt!B5 GIVEN inputs (mission spec), not
        %   Brandt outputs, so reading them from the JSON is legitimate. The
        %   check is that the JSON is actually read -- compare against the file,
        %   not against a literal, so a JSON edit cannot silently desync.
            J = jsondecode(fileread(f16a_spec_path(1)));
            g = TestWeightsL1.makeW1();
            tc.verifyEqual(g.W_payload_fixed, J.weights.W_payload_fixed, ...
                'W_payload_fixed must come from f16a_L1.json .weights.');
            tc.verifyEqual(g.W_payload_expendable, J.weights.W_payload_expendable, ...
                'W_payload_expendable must come from f16a_L1.json .weights.');
        end

        function testStateVariablesAreNotReadFromJSON(tc)
        %TESTSTATEVARIABLESARENOTREADFROMJSON  W_energy is a Brandt OUTPUT.
        %   Brandt Wt!B6 = =B3-B4-B5-B12, i.e. back-calculated fuel. Phase 3
        %   deleted the 6296.3 default; both state variables must stay NaN
        %   until the mission / sizing loop sets them.
            g = TestWeightsL1.makeW1();
            tc.verifyTrue(isnan(g.W_energy), ...
                'W_energy must be NaN: it is mission state, not a spec input.');
            tc.verifyTrue(isnan(g.W_TO), ...
                'W_TO must be NaN: it is sizing-loop state, not a spec input.');
        end

    end

    % ------------------------------------------------------------------ %
    % Lookup tables: Raymer Table 3.1 coefficients
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLookupJetFighterCoeffs(tc)
            % Expecteds transcribed from metabook_data.md:22 (the AE481
            % metabook's copy of Raymer Table 3.1), not from the code.
            c = WeightsL1.lookup_coeffs('jet_fighter');
            tc.verifyEqual(c.A,   2.34,  'AbsTol', 1e-6, ...
                'jet_fighter A must be 2.34 [metabook_data.md:22].');
            tc.verifyEqual(c.C,  -0.13,  'AbsTol', 1e-6, ...
                'jet_fighter C must be -0.13 [metabook_data.md:22].');
            tc.verifyEqual(c.Kvs, 1.00,  'AbsTol', 1e-6, ...
                'jet_fighter Kvs must be 1.00 (fixed sweep) [metabook_data.md:22].');
        end

        function testLookupOtherCategoryCoeffs(tc)
            % The other three coded rows, transcribed from metabook_data.md:23
            % (military cargo/bomber), :24 (jet transport), :26 (jet trainer).
            c_mcb = WeightsL1.lookup_coeffs('military_cargo_bomber');
            tc.verifyEqual([c_mcb.A c_mcb.C], [0.93 -0.07], 'AbsTol', 1e-6, ...
                'military_cargo_bomber must be A=0.93, C=-0.07 [metabook_data.md:23].');
            c_jt = WeightsL1.lookup_coeffs('jet_transport');
            tc.verifyEqual([c_jt.A c_jt.C], [1.02 -0.06], 'AbsTol', 1e-6, ...
                'jet_transport must be A=1.02, C=-0.06 [metabook_data.md:24].');
            c_tr = WeightsL1.lookup_coeffs('jet_trainer');
            tc.verifyEqual([c_tr.A c_tr.C], [1.59 -0.10], 'AbsTol', 1e-6, ...
                'jet_trainer must be A=1.59, C=-0.10 [metabook_data.md:26].');
        end

        function testLookupUnknownCategoryErrors(tc)
            tc.verifyError(@() WeightsL1.lookup_coeffs('spaceship'), ...
                'WeightsL1:UnknownCategory', ...
                'Unknown category must throw WeightsL1:UnknownCategory.');
        end

    end

    % ------------------------------------------------------------------ %
    % Lookup tables: Roskam Table 2.15 coefficients
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLookupRoskamJetFighterCoeffs(tc)
            c = WeightsL1.lookup_roskam_coeffs('jet_fighter');
            tc.verifyEqual(c.A, 0.5091, 'AbsTol', 1e-6, ...
                'jet_fighter Roskam A must be 0.5091 [roskam_vol1_data.md:57].');
            tc.verifyEqual(c.B, 0.9505, 'AbsTol', 1e-6, ...
                'jet_fighter Roskam B must be 0.9505 [roskam_vol1_data.md:57].');
        end

        function testLookupRoskamUnknownCategoryErrors(tc)
            tc.verifyError(@() WeightsL1.lookup_roskam_coeffs('spaceship'), ...
                'WeightsL1:UnknownRoskamCategory', ...
                'Unknown Roskam category must throw WeightsL1:UnknownRoskamCategory.');
        end

    end

    % ------------------------------------------------------------------ %
    % DELIBERATELY-FAILING TODO (missing coefficients) -- EXPECTED RED
    % ------------------------------------------------------------------ %

    methods (Test)

        function testTODO_RaymerTable61CoefficientsNotInRepo(tc)
        %TESTTODO_RAYMERTABLE61COEFFICIENTSNOTINREPO  Deliberate, EXPECTED red.
        %
        %   THIS TEST IS EXPECTED TO BE RED. It is not a regression; it is the
        %   labelled marker for a missing citation, following the convention of
        %   TestGeomL3.testTODO_OverallLengthCitationNotPinned and
        %   TestAeroL2.testTODO_ClAlpha2DUnverified.
        %
        %   WHAT IS MISSING: docs/subplans/05_weights.md:81,88 cites Raymer
        %   *Table 6.1* for the same empty-weight-fraction power law that
        %   WeightsL1 cites as *Table 3.1*. Locked decision (user 2026-07-24):
        %   keep Table 3.1 plus the Roskam bound; Table 6.1's coefficients are
        %   NOT present anywhere in this repo, so the user must supply them.
        %   Neither temp_AI/docs/disciplines/reference_extracts/raymer_data.md
        %   nor metabook_data.md carries a Table 6.1 empty-weight-fraction
        %   table (grepped 2026-07-25 -- "Table 6.1" appears only in prose:
        %   WeightsL1.m, todo.md, docs/, temp_Casey/, temp_AI/docs/).
        %   todo 2026-07-25 Phase 4 Sec. P4-8.
        %
        %   HOW THIS TEST DETECTS IT: WeightsL1.m's own standing-TO-DO block
        %   asserts, in words, that the coefficients "are NOT present anywhere
        %   in this repo". While the source itself makes that statement, the
        %   TO-DO is open and this test is red. Resolving it means either
        %   (a) the user supplies the Table 6.1 coefficients with a citation
        %   and the block is rewritten, or (b) the user confirms Table 3.1 is
        %   the correct attribution and the block is deleted. Either way the
        %   sentence goes. Do NOT make this green by deleting the sentence
        %   without settling the citation, and do NOT invent coefficients.
            src = fileread(which('WeightsL1'));
            tc.verifyFalse(contains(src, 'Table 6.1''s coefficients are NOT present'), ...
                ['TODO (EXPECTED RED): Raymer Table 6.1 empty-weight-fraction ' ...
                 'coefficients are not in this repo; WeightsL1.m still carries ' ...
                 'the standing TO-DO. todo 2026-07-25 Phase 4 Sec. P4-8.']);
        end

    end

    % ------------------------------------------------------------------ %
    % Fixture helper
    % ------------------------------------------------------------------ %

    methods (Static, Access = private)

        function w = makeW1()
        %MAKEW1  Build the F-16A L1 weights object from its required spec path.
            w = F16WeightsL1(f16a_spec_path(1));
        end

    end

end
