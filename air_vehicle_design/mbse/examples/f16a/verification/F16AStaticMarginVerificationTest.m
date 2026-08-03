classdef F16AStaticMarginVerificationTest < matlab.unittest.TestCase
    %F16ASTATICMARGINVERIFICATIONTEST Verify REQ_F16A_025 (relaxed static stability).
    %   Checks SM = (x_np - x_cg)/MAC against the -6..+1 %MAC band at takeoff
    %   AND landing weight -- "across the operational CG range" (D-046).
    %
    %   The only verification here that leaves the MBSE model: P holds no
    %   neutral point, CG or MAC, none being a property of a part, so the check
    %   delegates read-only to sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m,
    %   reached by PATH rather than project membership (D-047).
    %
    %   Computed SM_TO = -0.26 %MAC, SM_land = +0.21 %MAC (2026-08-02): both in
    %   band, so REQ_F16A_025 is MET -- but from the near-neutral STABLE end,
    %   Brandt's neutral point being a simplified approximation, not as evidence
    %   of the strongly relaxed static stability the F-16A is generally
    %   described as having. The -6 %MAC figure is an illustrative teaching
    %   value, not sourced data (D-030, D-048).
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16AFUELVERIFICATIONTEST.

    properties (Constant)
        % REQ_F16A_025's band (D-046), a FRACTION of MAC to match run()'s SM_TO
        % / SM_land -- so -0.06 is -6 %MAC. Declared once so it cannot be widened
        % in one test and left alone elsewhere (D-047 guarantee 5). Both bounds are
        % Estimate-class, inventoried in D-030, not traceable to /sizing/.
        SMLower_fracMAC = -0.06
        SMUpper_fracMAC =  0.01

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

        function testTakeoffStaticMarginWithinBand(testCase)
            % The AFT end of the CG range -- heaviest, full fuel, full stores.
            % Stores and fuel sit aft of the CG, so using them moves it forward.
            testCase.verifyThat(testCase.Balance.SM_TO, ...
                testCase.inBandConstraint(), ...
                testCase.bandMessage("takeoff", testCase.Balance.SM_TO));
        end

        function testLandingStaticMarginWithinBand(testCase)
            % The FORWARD end: fuel burnt, stores released. "Across the
            % operational CG range" means both ends must hold -- checking only
            % takeoff verifies half a requirement (D-047 guarantee 4).
            testCase.verifyThat(testCase.Balance.SM_land, ...
                testCase.inBandConstraint(), ...
                testCase.bandMessage("landing", testCase.Balance.SM_land));
        end
    end

    methods (Access = private)
        function c = inBandConstraint(testCase)
            %INBANDCONSTRAINT The REQ_F16A_025 band as a unittest constraint,
            %   built from the class constants rather than restated.
            import matlab.unittest.constraints.IsGreaterThanOrEqualTo
            import matlab.unittest.constraints.IsLessThanOrEqualTo
            c = IsGreaterThanOrEqualTo(testCase.SMLower_fracMAC) & ...
                IsLessThanOrEqualTo(testCase.SMUpper_fracMAC);
        end

        function msg = bandMessage(testCase, condition, sm)
            %BANDMESSAGE A failure message that says which way it failed.
            %   Three outcomes, not two: below the lower bound is too unstable for
            %   the assumed FCS authority; above the upper is conventionally stable,
            %   not the relaxed configuration REQ_F16A_L02 was justified by; and
            %   non-finite is a broken analysis. That third branch is a bug fix --
            %   `NaN < x` is false, so a NaN margin fell to the else and was
            %   reported as conventionally stable.

            % Bounds INTERPOLATED from the constants, never typed: literal text
            % here would name one band while "Required:" below named another.
            lowerPct = 100 * testCase.SMLower_fracMAC;
            upperPct = 100 * testCase.SMUpper_fracMAC;
            if ~isfinite(sm)
                why = "NOT A FINITE NUMBER -- the analysis did not produce a static " + ...
                    "margin, so REQ_F16A_025 has not been evaluated at all, in either " + ...
                    "direction. This is a broken analysis, not a requirement " + ...
                    "violation; read it together with the " + ...
                    "testAnalysisProducedUsableMargins failure in the same run and " + ...
                    "fix the analysis before drawing any conclusion about stability";
            elseif sm < testCase.SMLower_fracMAC
                why = sprintf( ...
                    "MORE NEGATIVE than the %+.1f %%MAC lower bound -- more unstable " + ...
                    "than the flight control system is assumed to be able to stabilize", ...
                    lowerPct);
            else
                why = sprintf( ...
                    "MORE POSITIVE than the %+.1f %%MAC upper bound -- conventionally " + ...
                    "stable, which is not the relaxed configuration REQ_F16A_L02's " + ...
                    "fly-by-wire selection was justified by", upperPct);
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
                "REQ_F16A_025 NOT met at %s (%s): static margin %.4f %%MAC is %s. " + ...
                "Required: %+.1f %%MAC <= SM <= %+.1f %%MAC. Source: " + ...
                "sizing/VnV/BrandtF16A/BrandtBalanceStabControl.", ...
                condition, atWeight, 100*sm, why, lowerPct, upperPct);
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
