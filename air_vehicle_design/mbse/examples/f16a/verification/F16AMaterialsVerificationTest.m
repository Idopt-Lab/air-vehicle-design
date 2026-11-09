classdef F16AMaterialsVerificationTest < matlab.unittest.TestCase
    %F16AMATERIALSVERIFICATIONTEST Verify REQ_F16A_022 (airframe composite <= 20%).
    %   The "Verify" link of REQ_F16A_022 points to this test. The test checks
    %   that the design meets the requirement: the airframe materials roll-up
    %   (F16APhysicalMaterialsRollup) gives a mass-weighted composite fraction
    %   within the 20% cap.
    %
    %   On purpose, this file holds only the REQ_F16A_022 check. It is separate
    %   from:
    %     * F16ABaselineTest              regression: the numbers have not changed.
    %     * F16AFuelVerificationTest      the other requirement (REQ_F16A_P01).
    %   Thus "is REQ_022 met?" is a single, self-contained suite that passes.

    methods (TestClassSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.PathFixture
            % Use a PathFixture, not a bare addpath. Then the suite restores
            % the path to its initial state.
            testCase.applyFixture(PathFixture({f16aRoot(), fullfile(f16aRoot(),"physical")}));
            % Close only the model that the roll-up of this suite loads.
            % bdclose("all") would also discard all other models that the user
            % had open.
            testCase.addTeardown(@() bdclose("F16A_Physical"));
        end
    end

    methods (Test)
        function testAirframeCompositeWithinLimit(testCase)
            % REQ_F16A_022: airframe composite fraction shall be <= 20%.
            cf = F16APhysicalMaterialsRollup().CompositeFraction;

            testCase.assertTrue(isfinite(cf), ...
                sprintf("REQ_F16A_022 UNEVALUATED: the materials roll-up returned %s, " + ...
                "which is not a number. Thus no value was compared with the 20%% cap. " + ...
                "This is a broken analysis, not a violation. Make sure that each " + ...
                "Material part has a readable Mass_lb and CompositeFraction.", num2str(cf)));

            testCase.verifyGreaterThan(cf, 0, ...
                "The composite roll-up returned 0. Possible cause: the CompositeFraction properties are not set.");
            testCase.verifyLessThanOrEqual(cf, 0.20, ...
                sprintf("REQ_F16A_022 NOT MET: the airframe composite fraction %.1f%% is more than the 20%% cap.", ...
                100*cf));
        end
    end
end
