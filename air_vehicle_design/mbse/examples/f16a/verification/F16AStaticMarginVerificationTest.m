classdef F16AStaticMarginVerificationTest < matlab.unittest.TestCase
    %F16ASTATICMARGINVERIFICATIONTEST Verify REQ_F16A_025 (relaxed static stability).
    %   This test checks SM = (x_np - x_cg)/MAC against -6 %MAC <= SM < 0 at
    %   takeoff weight and at landing weight. This is the meaning of "across
    %   the operational CG range". The upper end is strict, because neutral is
    %   not negative.
    %
    %   EXPECTED RED: 2 tests pass and 1 test fails. The failure is the landing
    %   case, which is the only intentional red in the example. When the
    %   aircraft burns fuel and releases stores, the CG moves forward. Thus
    %   landing is the most stable end, and the relaxed-stability requirement
    %   is most difficult to meet there. Do not make this test pass. A
    %   Verify-linked test that passes while its requirement is violated is the
    %   dishonesty that this example teaches against.
    %   testAnalysisProducedUsableMargins must continue to pass. It separates
    %   "the design violates this requirement" from "the analysis is broken".
    %
    %   The -6 %MAC figure is an illustrative teaching value (D-030). P holds
    %   no neutral point, CG or MAC. Thus this test calls
    %   sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m, and only reads from it.

    properties (Constant)
        % The criterion of REQ_F16A_025, as fractions of MAC to agree with SM_TO
        % and SM_land from run(). Thus -0.06 is -6 %MAC. The code compares the
        % two ends in different ways, and the names tell which: at least the
        % lower bound (inclusive), and strictly below the upper bound. They are
        % declared one time, so the constraint and all messages use the same
        % bounds.
        SMLower_fracMAC       = -0.06
        SMMustBeBelow_fracMAC =  0

        % The sizing point given to run() (Wt!B3), and the weight at which SM_TO
        % is evaluated. This value is stated, not assumed. It is NOT the weight
        % for SM_land. run() calculates that case internally, with W_land =
        % W_empty + perm_payload, approximately 20,678 lb computed.
        W_TO_lb = 31377
    end

    properties
        % The output of run(). It is computed one time, because it is the same
        % for all methods.
        Balance struct
    end

    methods (TestClassSetup)
        function loadSizingBalanceModel(testCase)
            import matlab.unittest.fixtures.PathFixture

            brandtDir = F16AStaticMarginVerificationTest.brandtF16ADir();

            % Use assert, not verify. If /sizing/ is absent, fail clearly and do
            % not skip. A test that silently stops verifying reports a success
            % that it did not earn.
            testCase.assertTrue(isfolder(brandtDir), ...
                "REQ_F16A_025 cannot be verified: the sizing reference model is not " + ...
                "at " + brandtDir + ". This test uses " + ...
                "sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m for the static-margin " + ...
                "calculation. That file is outside the f16a project, and the test finds " + ...
                "it by path, not by project membership. The test is NOT skipped when " + ...
                "the file is absent. A verification test that stops verifying must not " + ...
                "report success.");

            % Use a PathFixture, not a bare addpath. If sizing/ (three levels
            % outside the project) stays on the path, the results depend on the
            % test order.
            testCase.applyFixture(PathFixture(brandtDir));

            % Read-only. These objects compute in memory and write no file.
            bsc = BrandtBalanceStabControl();
            bsc.analyze();
            testCase.Balance = bsc.run(testCase.W_TO_lb);
        end
    end

    methods (Test)
        function testAnalysisProducedUsableMargins(testCase)
            % A dependency check that runs before the requirement is judged. It
            % separates "the aircraft violates REQ_F16A_025" from "the analysis
            % that evaluates it is broken". A NaN margin is not a violation. When
            % this test passes, it shows that the landing red is a violation, not
            % a broken run.
            testCase.assertTrue(isfield(testCase.Balance, "SM_TO") && ...
                isfield(testCase.Balance, "SM_land"), ...
                "BrandtBalanceStabControl.run did not return SM_TO and SM_land. The " + ...
                "interface of the sizing model changed, and this verification reads " + ...
                "the wrong fields. Correct the reader. Do not interpret the result in " + ...
                "a different way.");
            % Use string(num2str(x)), not string(x). string(NaN) is <missing>, and
            % the diagnostic framework rejects <missing>. NaN is the input that
            % this check is for.
            testCase.verifyTrue(isfinite(testCase.Balance.SM_TO), ...
                "Static margin at takeoff is not finite (" + ...
                string(num2str(testCase.Balance.SM_TO)) + "). This is a broken " + ...
                "analysis, not a requirement violation.");
            testCase.verifyTrue(isfinite(testCase.Balance.SM_land), ...
                "Static margin at landing is not finite (" + ...
                string(num2str(testCase.Balance.SM_land)) + "). This is a broken " + ...
                "analysis, not a requirement violation.");
        end

        function testTakeoffStaticMarginIsNegative(testCase)
            % The aft end of the CG range: heaviest, with full fuel and full
            % stores. Thus it is the least stable end. Stores and fuel are aft of
            % the CG, so when the aircraft uses them, the CG moves forward.
            % EXPECTED TO PASS.
            testCase.verifyThat(testCase.Balance.SM_TO, ...
                testCase.criterionConstraint(), ...
                testCase.criterionMessage("takeoff", testCase.Balance.SM_TO));
        end

        function testLandingStaticMarginIsNegative(testCase)
            % The forward end: fuel burned and stores released. Thus it is the
            % most stable end. EXPECTED TO FAIL: SM_land is positive and
            % REQ_F16A_025 is violated. "Across the operational CG range" puts
            % this end in scope. A check of only takeoff verifies half of the
            % requirement, and would report that this design complies.
            testCase.verifyThat(testCase.Balance.SM_land, ...
                testCase.criterionConstraint(), ...
                testCase.criterionMessage("landing", testCase.Balance.SM_land));
        end
    end

    methods (Access = private)
        function c = criterionConstraint(testCase)
            %CRITERIONCONSTRAINT Return the criterion of REQ_F16A_025 as a unittest constraint.
            %   The constraint uses the class constants, and does not restate
            %   them. It is not named "inBand", because the two ends are
            %   compared in different ways: IsGreaterThanOrEqualTo at the lower
            %   end, and IsLessThan (NOT IsLessThanOrEqualTo) at the upper end.
            %   A margin of exactly zero is neutral, and neutral is not negative.
            import matlab.unittest.constraints.IsGreaterThanOrEqualTo
            import matlab.unittest.constraints.IsLessThan
            c = IsGreaterThanOrEqualTo(testCase.SMLower_fracMAC) & ...
                IsLessThan(testCase.SMMustBeBelow_fracMAC);
        end

        function msg = criterionMessage(testCase, condition, sm)
            %CRITERIONMESSAGE Return a failure message that tells the direction of the failure.
            %   For the landing case, the message also teaches why that red is
            %   the answer. A violation has two opposite directions:
            %     * Below the floor: more unstable than the FCS is assumed to
            %       handle.
            %     * At or above the ceiling: not relaxed at all.
            %   There are two more outcomes:
            %     * Satisfied. The test never shows this message, but it builds
            %       the message on every call, so the message must stay true.
            %     * Not finite: a broken analysis. The code checks this outcome
            %       first, because `NaN < x` is false. Otherwise a NaN would
            %       fall through and be reported as a verdict.

            % Both bounds come from the constants. They are never typed. Typed
            % text here could give one criterion while "Required:" below gave a
            % different one.
            lowerPct = 100 * testCase.SMLower_fracMAC;
            upperPct = 100 * testCase.SMMustBeBelow_fracMAC;
            if ~isfinite(sm)
                why = "NOT A FINITE NUMBER. The analysis did not produce a static " + ...
                    "margin, so REQ_F16A_025 was not evaluated in either direction. " + ...
                    "This is a broken analysis, not a requirement violation. Read it " + ...
                    "together with the testAnalysisProducedUsableMargins failure in " + ...
                    "the same run. Correct the analysis before you make a conclusion " + ...
                    "about stability";
            elseif sm < testCase.SMLower_fracMAC
                why = sprintf( ...
                    "BELOW the %g %%MAC lower bound. The aircraft is more unstable " + ...
                    "than the flight control system is assumed to be able to " + ...
                    "stabilize", lowerPct);
            elseif sm >= testCase.SMMustBeBelow_fracMAC
                why = sprintf( ...
                    "NOT BELOW the %g %%MAC upper bound. At this end of the CG range, " + ...
                    "the aircraft is MORE STABLE than REQ_F16A_025 allows. That bound " + ...
                    "is strict. A margin exactly equal to it does not satisfy the " + ...
                    "requirement, because neutral stability is not relaxed stability. " + ...
                    "A margin at or above zero is conventional stability. That is not " + ...
                    "the relaxed configuration that justified the fly-by-wire selection " + ...
                    "of REQ_F16A_L02. The margin printed above is a finite number, so " + ...
                    "the analysis RAN and the requirement WAS evaluated. This red is a " + ...
                    "real VIOLATION, not a broken run. It is the only intentional red " + ...
                    "in the example", upperPct);
            else
                why = sprintf( ...
                    "within [%g, %g) %%MAC, so it SATISFIES REQ_F16A_025 here. If you " + ...
                    "read this, the check failed for a reason other than the " + ...
                    "criterion. Suspect the diagnostic, not the aircraft", ...
                    lowerPct, upperPct);
            end

            % The weight of this condition. If the message printed W_TO for
            % landing, it would give a condition 10,700 lb heavier than the
            % condition that failed.
            if strcmp(condition, "takeoff")
                atWeight = sprintf("sizing point W_TO = %d lb", testCase.W_TO_lb);
            elseif strcmp(condition, "landing")
                atWeight = sprintf( ...
                    "landing weight. run() builds it internally from the sizing " + ...
                    "point W_TO = %d lb: it sets the expendable payload and all " + ...
                    "three fuel thirds to zero. W_land = W_empty + perm_payload, " + ...
                    "approximately 20,678 lb computed", testCase.W_TO_lb);
            else
                % Say that the weight is unknown. Do not use W_TO as the
                % default, because it would give the wrong weight.
                atWeight = sprintf( ...
                    "run() called at sizing point W_TO = %d lb. This test does not " + ...
                    "characterise the weight of condition '%s'", ...
                    testCase.W_TO_lb, condition);
            end

            msg = sprintf( ...
                "REQ_F16A_025 %s at %s (%s): static margin %+.4f %%MAC is %s. " + ...
                "Required: %g %%MAC <= SM < %g %%MAC, inclusive at the lower end and " + ...
                "strict at the upper end, at BOTH ends of the operational CG range. " + ...
                "Source: sizing/VnV/BrandtF16A/BrandtBalanceStabControl. %s", ...
                verdictOf(sm, testCase.SMLower_fracMAC, testCase.SMMustBeBelow_fracMAC), ...
                condition, atWeight, 100*sm, why, lowerPct, upperPct, ...
                testCase.acrossTheRangeSentence());
        end

        function s = acrossTheRangeSentence(testCase)
            %ACROSSTHERANGESENTENCE Return text with both ends, both verdicts, and why the CG moves.
            %   The code adds this text to each failure message. Thus a reader
            %   who sees only the one red also sees that the other end is MET.
            %   This shows a requirement violation, not a broken analysis. Each
            %   figure comes from the run. Thus the text cannot give a verdict
            %   that the constraint does not agree with, or a margin that the
            %   analysis no longer computes.
            smTO    = fieldOrNaN(testCase.Balance, "SM_TO");
            smLand  = fieldOrNaN(testCase.Balance, "SM_land");
            loBound = testCase.SMLower_fracMAC;
            hiBound = testCase.SMMustBeBelow_fracMAC;
            s = sprintf( ...
                "ACROSS THE OPERATIONAL CG RANGE: takeoff SM_TO = %+.4f %%MAC (%s), " + ...
                "landing SM_land = %+.4f %%MAC (%s). The fuel and the stores are both " + ...
                "aft. When the aircraft burns fuel and releases stores, the CG moves " + ...
                "FORWARD, from x_cg %.4f ft at takeoff to %.4f ft at landing. Thus " + ...
                "landing is the forward, MOST STABLE end of the range. A requirement " + ...
                "for relaxed static stability is most difficult to meet at the most " + ...
                "stable end.", ...
                100*smTO, verdictOf(smTO, loBound, hiBound), ...
                100*smLand, verdictOf(smLand, loBound, hiBound), ...
                fieldOrNaN(testCase.Balance, "xcg_TO_ft"), ...
                fieldOrNaN(testCase.Balance, "xcg_land_ft"));
        end
    end

    methods (Static, Access = private)
        function d = brandtF16ADir()
            %BRANDTF16ADIR Return the absolute path to sizing/VnV/BrandtF16A.
            %   The path starts at f16aRoot(), the single location anchor of the
            %   example. Thus the path stays correct if verification/ moves.
            %   sizing/ is three levels above the example root, at the same level
            %   as mbse/.
            avd = fileparts(fileparts(fileparts(f16aRoot())));
            d = fullfile(avd, "sizing", "VnV", "BrandtF16A");
        end
    end
end

% ---------------------------------------------------------------------------

function word = verdictOf(sm, loBound, hiBound)
%VERDICTOF Return the verdict of one margin against REQ_F16A_025, in one word.
%   It uses the same bounds as the constraint, with the same strictness at
%   each end. Thus no message reports a verdict that the constraint
%   contradicts.
word = "MET";
if ~isfinite(sm)
    word = "NOT EVALUATED";
elseif sm < loBound || sm >= hiBound
    word = "NOT MET";
end
end

function v = fieldOrNaN(s, name)
%FIELDORNAN Return S.(NAME), or NaN when the field is absent.
%   Thus the code that builds a diagnostic cannot cause an error and replace a
%   clean failure with a stack trace. NaN prints, and reads as NOT EVALUATED.
v = NaN;
if isfield(s, name); v = s.(name); end
end
