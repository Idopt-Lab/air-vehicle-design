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
            addpath(fileparts(mfilename("fullpath")));   % resolve the roll-up fn
            testCase.addTeardown(@() bdclose("all"));
        end
    end

    methods (Test)
        function testAirframeCompositeWithinLimit(testCase)
            % REQ_F16A_022: airframe composite fraction shall be <= 20%.
            mats = F16APhysicalMaterialsRollup();
            testCase.verifyGreaterThan(mats.CompositeFraction, 0, ...
                "Composite roll-up returned 0 -- CompositeFraction properties not set?");
            testCase.verifyLessThanOrEqual(mats.CompositeFraction, 0.20, ...
                sprintf("REQ_F16A_022 NOT met: airframe composite fraction %.1f%% exceeds the 20%% cap.", ...
                100*mats.CompositeFraction));
        end
    end
end
