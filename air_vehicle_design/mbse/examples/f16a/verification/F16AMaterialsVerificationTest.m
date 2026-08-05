classdef F16AMaterialsVerificationTest < matlab.unittest.TestCase
    %F16AMATERIALSVERIFICATIONTEST Verify REQ_F16A_022 (airframe composite <= 20%).
    %   This is the test that the REQ_F16A_022 "Verify" link points to. It
    %   checks that the DESIGN MEETS the requirement: the airframe materials
    %   roll-up (F16APhysicalMaterialsRollup) gives a mass-weighted composite
    %   fraction within the 20% cap.
    %
    %   This file is deliberately kept to ONLY the REQ_F16A_022 check, separate
    %   from:
    %     * F16APhysicalArchitectureTest  -- machinery: the model is built right,
    %       stereotypes/links exist, roll-ups are self-consistent.
    %     * F16AFuelVerificationTest      -- the other requirement (REQ_F16A_P01).
    %   so "is REQ_022 met?" is a single, self-contained, all-green suite.

    methods (TestClassSetup)
        function setup(testCase)
            addpath(f16aRoot(), fullfile(f16aRoot(),"physical"));   % roll-up fn: root now, physical/ after reorg
            testCase.addTeardown(@() bdclose("all"));
        end
    end

    methods (Test)
        function testAirframeCompositeWithinLimit(testCase)
            % REQ_F16A_022: airframe composite fraction shall be <= 20%.
            cf = F16APhysicalMaterialsRollup().CompositeFraction;

            testCase.assertTrue(isfinite(cf), ...
                sprintf("REQ_F16A_022 UNEVALUATED: the materials roll-up returned %s, " + ...
                "not a number, so nothing was compared with the 20%% cap. This is a " + ...
                "broken analysis, not a violation -- check that every Material part " + ...
                "carries a readable Mass_lb and CompositeFraction.", num2str(cf)));

            testCase.verifyGreaterThan(cf, 0, ...
                "Composite roll-up returned 0 -- CompositeFraction properties not set?");
            testCase.verifyLessThanOrEqual(cf, 0.20, ...
                sprintf("REQ_F16A_022 NOT met: airframe composite fraction %.1f%% exceeds the 20%% cap.", ...
                100*cf));
        end
    end
end
