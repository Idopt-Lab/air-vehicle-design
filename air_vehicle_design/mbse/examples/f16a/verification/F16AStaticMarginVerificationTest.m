classdef F16AStaticMarginVerificationTest < matlab.unittest.TestCase
    %F16ASTATICMARGINVERIFICATIONTEST Verify REQ_F16A_025 (relaxed static stability).
    %   Checks SM = (x_np - x_cg)/MAC against REQ_F16A_025's criterion,
    %   -6 %MAC <= SM < 0, at takeoff AND at landing weight -- "across the
    %   operational CG range" (D-046). The upper end is STRICT: neutral is not
    %   negative. Zero sat in the INTERIOR of the old -6 .. +1 %MAC band, so
    %   that edge is new.
    %
    %   THIS SUITE IS EXPECTED TO BE RED -- 2 pass, 1 fail, the failure being
    %   the LANDING case. Measured 2026-08-02: SM_TO = -0.26 %MAC (MET),
    %   SM_land = +0.21 %MAC (VIOLATED). Burning fuel and releasing stores, both
    %   carried aft, move the CG FORWARD (x_cg 26.1979 -> 26.1451 ft), so landing
    %   is the most-stable end of the range -- and the most-stable end is where a
    %   relaxed-stability requirement bites. Do not make it pass: the design does
    %   not meet the requirement, and a Verify-linked test reporting green while
    %   its requirement is violated is the dishonesty this example teaches against.
    %
    %   Three verification states now ship, and the two reds differ. REQ_F16A_022
    %   is MET (F16AMaterialsVerificationTest, green). REQ_F16A_P01 is PENDING --
    %   red because its required value is NaN, so it is UNEVALUATED (D-042). This
    %   one is VIOLATED -- red because it WAS evaluated and the answer is no.
    %   testAnalysisProducedUsableMargins is what separates the last two and must
    %   stay GREEN: it demonstrates, rather than asserts, that the landing margin
    %   is a finite number from an analysis that ran.
    %
    %   The bounds differ in kind. The upper is a DEFINITION -- relaxed static
    %   stability IS negative static margin, zero being where the sign changes,
    %   not a chosen figure. The lower is invented, and is labelled so:
    %   The -6 %MAC figure is an illustrative teaching value, not sourced data
    %   (D-030).
    %
    %   That last sentence is CANONICAL (D-048 part 3): it is copied verbatim
    %   into every artifact that mentions the figure, so that the log, the
    %   requirement and this test cannot drift into three different hedges. Do
    %   not reword it, however much better the rewording reads. The copy in the
    %   requirement artifact is guarded by a test; the copy here and the ones in
    %   docs/ are guarded by nothing, which is why this file is where it drifted.
    %
    %   The one verification that leaves the MBSE model: P holds no neutral
    %   point, CG or MAC, none being a property of a part, so this delegates
    %   read-only to sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m, reached by
    %   PATH rather than project membership (D-047).
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16AFUELVERIFICATIONTEST.

    properties (Constant)
        % REQ_F16A_025's criterion (D-046), as FRACTIONS of MAC to match run()'s
        % SM_TO / SM_land -- so -0.06 is -6 %MAC. The two ends are compared
        % DIFFERENTLY and the names say which: at least the lower bound
        % (inclusive), strictly BELOW the upper one. Declared once each so a
        % bound cannot be relaxed for the failing case and left alone elsewhere
        % (D-047 guarantee 5): the constraint and every message line that names a
        % criterion INTERPOLATE these, none retypes them. SMLower_fracMAC is
        % Estimate-class, inventoried in D-030; its canonical label is in the
        % help block above and is not repeated here.
        SMLower_fracMAC       = -0.06
        SMMustBeBelow_fracMAC =  0

        % The sizing point handed to run() (Wt!B3), and the weight SM_TO is
        % evaluated at -- stated, not assumed. NOT the weight for SM_land:
        % run() derives that case internally, leaving W_land = W_empty +
        % perm_payload, about 20,678 lb computed.
        W_TO_lb = 31377
    end

    properties
        % What run() returns; computed once, being the same for every method.
        Balance struct
    end

    methods (TestClassSetup)
        function loadSizingBalanceModel(testCase)
            import matlab.unittest.fixtures.PathFixture

            brandtDir = F16AStaticMarginVerificationTest.brandtF16ADir();

            % ASSERT, not verify, and loud rather than skipped if /sizing/ is
            % absent: a test that quietly stops verifying reports unearned success.
            testCase.assertTrue(isfolder(brandtDir), ...
                "REQ_F16A_025 cannot be verified: the sizing reference model was not " + ...
                "found at " + brandtDir + ". This test delegates the static-margin " + ...
                "calculation to sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m, which " + ...
                "is outside the f16a project and resolved by path rather than by " + ...
                "project membership. It is NOT skipped when absent -- a verification " + ...
                "test that stops verifying must not report success.");

            % A PathFixture, not a bare addpath: leaving sizing/ (three levels
            % outside the project) on the path makes results order-dependent (D-047).
            testCase.applyFixture(PathFixture(brandtDir));

            % Read-only -- these compute in memory and write no file.
            bsc = BrandtBalanceStabControl();
            bsc.analyze();
            testCase.Balance = bsc.run(testCase.W_TO_lb);
        end
    end

    methods (Test)
        function testAnalysisProducedUsableMargins(testCase)
            % A dependency check run before the requirement is judged: it separates
            % "the aircraft violates REQ_F16A_025" from "the analysis that evaluates
            % it is broken" (D-047 guarantee 3). A NaN margin is not a violation.
            % Now load-bearing rather than precautionary: this suite ships one
            % genuine failure, and this test staying GREEN is what proves the
            % landing red is a violation and not a broken run.
            testCase.assertTrue(isfield(testCase.Balance, "SM_TO") && ...
                isfield(testCase.Balance, "SM_land"), ...
                "BrandtBalanceStabControl.run did not return SM_TO / SM_land. The " + ...
                "sizing model's interface has changed and this verification is reading " + ...
                "the wrong fields -- fix the reader, do not reinterpret the result.");
            % string(num2str(x)), NOT string(x) -- do not revert. string(NaN) is
            % <missing>, which the diagnostic framework rejects, so the obvious
            % spelling deletes this message on the input it exists for (08_agent_team).
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
            % The AFT end of the CG range -- heaviest, full fuel, full stores --
            % and so the LEAST stable end. Stores and fuel sit aft of the CG, so
            % using them moves it forward. EXPECTED TO PASS.
            testCase.verifyThat(testCase.Balance.SM_TO, ...
                testCase.criterionConstraint(), ...
                testCase.criterionMessage("takeoff", testCase.Balance.SM_TO));
        end

        function testLandingStaticMarginIsNegative(testCase)
            % The FORWARD end: fuel burnt, stores released, and so the MOST
            % stable end. EXPECTED TO FAIL -- SM_land is positive and
            % REQ_F16A_025 is violated. "Across the operational CG range" is
            % what puts this end in scope: checking only takeoff verifies half a
            % requirement and would report this design compliant (D-047
            % guarantee 4).
            testCase.verifyThat(testCase.Balance.SM_land, ...
                testCase.criterionConstraint(), ...
                testCase.criterionMessage("landing", testCase.Balance.SM_land));
        end
    end

    methods (Access = private)
        function c = criterionConstraint(testCase)
            %CRITERIONCONSTRAINT REQ_F16A_025's criterion as a unittest
            %   constraint, built from the class constants rather than restated.
            %   Not named "inBand": the two ends are compared differently.
            %   IsGreaterThanOrEqualTo at the lower end, IsLessThan -- NOT
            %   IsLessThanOrEqualTo -- at the upper, because a margin of exactly
            %   zero is neutral, and neutral is not negative. Zero sat in the
            %   interior of the old -6 .. +1 %MAC band, so nothing before now
            %   depended on which comparison was used there.
            import matlab.unittest.constraints.IsGreaterThanOrEqualTo
            import matlab.unittest.constraints.IsLessThan
            c = IsGreaterThanOrEqualTo(testCase.SMLower_fracMAC) & ...
                IsLessThan(testCase.SMMustBeBelow_fracMAC);
        end

        function msg = criterionMessage(testCase, condition, sm)
            %CRITERIONMESSAGE A failure message that says which way it failed
            %   and, for the landing case, teaches why that red is the answer.
            %   Violation has two opposite directions -- below the floor is more
            %   unstable than the FCS is assumed to handle, at or above the
            %   ceiling is not relaxed at all -- plus two further outcomes:
            %   satisfied, which this is never SHOWN for but is BUILT for on
            %   every call and so must stay true, and non-finite, a broken
            %   analysis. That last branch is a bug fix: `NaN < x` is false, so a
            %   NaN margin fell to the else and was reported as a verdict.

            % Both bounds are INTERPOLATED from the constants, never typed:
            % literal text here would name one criterion while "Required:" below
            % named another.
            lowerPct = 100 * testCase.SMLower_fracMAC;
            upperPct = 100 * testCase.SMMustBeBelow_fracMAC;
            if ~isfinite(sm)
                why = "NOT A FINITE NUMBER -- the analysis did not produce a static " + ...
                    "margin, so REQ_F16A_025 has not been evaluated at all, in either " + ...
                    "direction. This is a broken analysis, not a requirement " + ...
                    "violation; read it together with the " + ...
                    "testAnalysisProducedUsableMargins failure in the same run and " + ...
                    "fix the analysis before drawing any conclusion about stability";
            elseif sm < testCase.SMLower_fracMAC
                why = sprintf( ...
                    "BELOW the %g %%MAC lower bound -- more unstable than the flight " + ...
                    "control system is assumed to be able to stabilize", lowerPct);
            elseif sm >= testCase.SMMustBeBelow_fracMAC
                why = sprintf( ...
                    "NOT BELOW the %g %%MAC upper bound -- the aircraft is MORE " + ...
                    "STABLE at this end of the CG range than REQ_F16A_025 allows. " + ...
                    "That bound is STRICT: a margin exactly equal to it does not " + ...
                    "satisfy the requirement, neutral stability not being relaxed " + ...
                    "stability; and a margin at or above zero is conventional " + ...
                    "stability, which is not the relaxed configuration REQ_F16A_L02's " + ...
                    "fly-by-wire selection was justified by. The margin printed above " + ...
                    "is a finite number, so the analysis RAN and the requirement WAS " + ...
                    "evaluated: this red is a genuine VIOLATION, not a broken run. " + ...
                    "Contrast F16AFuelVerificationTest, whose red means UNEVALUATED -- " + ...
                    "its required value is NaN (D-042)", upperPct);
            else
                why = sprintf( ...
                    "within [%g, %g) %%MAC and therefore SATISFIES REQ_F16A_025 here. " + ...
                    "If you are reading this, the check failed for some reason other " + ...
                    "than the criterion: distrust the diagnostic, not the aircraft", ...
                    lowerPct, upperPct);
            end

            % Which weight this condition is. Printing W_TO for landing would
            % name a condition 10,700 lb heavier than the one that failed.
            if strcmp(condition, "takeoff")
                atWeight = sprintf("sizing point W_TO = %d lb", testCase.W_TO_lb);
            elseif strcmp(condition, "landing")
                atWeight = sprintf( ...
                    "landing weight, which run() builds internally from the sizing " + ...
                    "point W_TO = %d lb by zeroing the expendable payload and all " + ...
                    "three fuel thirds: W_land = W_empty + perm_payload, about " + ...
                    "20,678 lb computed", testCase.W_TO_lb);
            else
                % Unknown rather than defaulting to W_TO -- defaulting is how the
                % landing message came to name the wrong weight.
                atWeight = sprintf( ...
                    "run() called at sizing point W_TO = %d lb; the weight of " + ...
                    "condition '%s' is not characterised by this test", ...
                    testCase.W_TO_lb, condition);
            end

            msg = sprintf( ...
                "REQ_F16A_025 %s at %s (%s): static margin %+.4f %%MAC is %s. " + ...
                "Required: %g %%MAC <= SM < %g %%MAC -- inclusive at the lower end, " + ...
                "STRICT at the upper -- at BOTH ends of the operational CG range. " + ...
                "Source: sizing/VnV/BrandtF16A/BrandtBalanceStabControl. %s", ...
                verdictOf(sm, testCase.SMLower_fracMAC, testCase.SMMustBeBelow_fracMAC), ...
                condition, atWeight, 100*sm, why, lowerPct, upperPct, ...
                testCase.acrossTheRangeSentence());
        end

        function s = acrossTheRangeSentence(testCase)
            %ACROSSTHERANGESENTENCE Both ends, both verdicts, and why the CG
            %   moves the way it does. Appended to EVERY failure message, so a
            %   reader who sees only the one red also sees the other end MET --
            %   which is what makes this a requirement violation and not a broken
            %   analysis. Every figure is read back from the run, so it cannot
            %   claim a verdict the constraint disagrees with, nor quote a margin
            %   the analysis no longer computes.
            smTO    = fieldOrNaN(testCase.Balance, "SM_TO");
            smLand  = fieldOrNaN(testCase.Balance, "SM_land");
            loBound = testCase.SMLower_fracMAC;
            hiBound = testCase.SMMustBeBelow_fracMAC;
            s = sprintf( ...
                "ACROSS THE OPERATIONAL CG RANGE: takeoff SM_TO = %+.4f %%MAC (%s); " + ...
                "landing SM_land = %+.4f %%MAC (%s). Burning fuel and releasing " + ...
                "stores -- both carried AFT -- move the CG FORWARD, x_cg %.4f ft at " + ...
                "takeoff to %.4f ft at landing, so landing is the forward, MOST " + ...
                "STABLE end of the range; and the most stable end is where a " + ...
                "requirement for relaxed static stability bites first.", ...
                100*smTO, verdictOf(smTO, loBound, hiBound), ...
                100*smLand, verdictOf(smLand, loBound, hiBound), ...
                fieldOrNaN(testCase.Balance, "xcg_TO_ft"), ...
                fieldOrNaN(testCase.Balance, "xcg_land_ft"));
        end
    end

    methods (Static, Access = private)
        function d = brandtF16ADir()
            %BRANDTF16ADIR Absolute path to sizing/VnV/BrandtF16A.
            %   Anchored on f16aRoot(), the example's single location anchor, so it
            %   survives verification/ being moved. sizing/ is three levels above
            %   the example root, a sibling of mbse/.
            avd = fileparts(fileparts(fileparts(f16aRoot())));
            d = fullfile(avd, "sizing", "VnV", "BrandtF16A");
        end
    end
end

% ---------------------------------------------------------------------------

function word = verdictOf(sm, loBound, hiBound)
%VERDICTOF How one margin stands against REQ_F16A_025, in one word.
%   Derived from the SAME bounds the constraint uses, with the same strictness
%   at each end, so no message reports a verdict the constraint contradicts.
word = "MET";
if ~isfinite(sm)
    word = "NOT EVALUATED";
elseif sm < loBound || sm >= hiBound
    word = "NOT MET";
end
end

function v = fieldOrNaN(s, name)
%FIELDORNAN S.(NAME), or NaN when the field is absent.
%   So that building a DIAGNOSTIC can never itself error and replace a clean
%   failure with a stack trace; NaN prints, and reads as NOT EVALUATED.
v = NaN;
if isfield(s, name); v = s.(name); end
end
