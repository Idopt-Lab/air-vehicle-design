classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   This is the test that the REQ_F16A_P01 "Verify" link points to. It
    %   checks that the DESIGN MEETS the requirement: the available internal
    %   fuel (F16APhysicalFuelRollup) is at least the mission fuel required
    %   (F16APhysicalMissionFuel).
    %
    %   IT FAILS BY DESIGN, AND PERMANENTLY (D-042). The available side
    %   (fuel-capacity roll-up) is real, ~6300 lb; the required side is NaN and
    %   STAYS NaN, because D-042 decided F16APhysicalMissionFuel is never wired
    %   to the /sizing/ mission analysis -- not now, not later. So the
    %   comparison is available >= NaN, which is false. Do NOT make this green
    %   by connecting mission fuel: the red IS the teaching artifact. It shows
    %   verification that is set up, traceable and NOT YET SATISFIED -- the
    %   state a real programme lives in for most of its life, and the one no
    %   other artifact in this example demonstrates.
    %
    %   WHICH RED IS THIS? The example ships two, and they are different
    %   STATES, not two shades of the same one. The discriminator is the
    %   REQUIRED side of the comparison:
    %     * UNEVALUATED -- THIS suite. Required = NaN, so nothing has been
    %       compared with anything and REQ_F16A_P01 has not been answered.
    %       It is not violated. NO claim about the aircraft follows from this
    %       red; the only thing it reports is that the analysis is absent.
    %     * VIOLATED -- F16AStaticMarginVerificationTest, landing case. Both
    %       sides are finite numbers, the comparison was genuinely made, and
    %       the design lost (D-051). That red IS a claim about the aircraft.
    %   That suite proves its own case with testAnalysisProducedUsableMargins,
    %   which must stay GREEN precisely so its red cannot be mistaken for this
    %   one. This suite has no counterpart to it, because here there is nothing
    %   to prove usable -- which is the distinction, stated as code.
    %
    %   Kept as its own file (separate from F16AMaterialsVerificationTest and
    %   from the machinery in F16APhysicalArchitectureTest) so this intentional,
    %   requirement-specific failure never mixes into another suite's status.
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16ASTATICMARGINVERIFICATIONTEST.

    methods (TestClassSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.PathFixture
            % A PathFixture, not a bare addpath: the suite leaves the path as
            % it found it (D-047).
            testCase.applyFixture(PathFixture({f16aRoot(), fullfile(f16aRoot(),"physical")}));
            testCase.addTeardown(@() bdclose("all"));
        end
    end

    methods (Test)
        function testFuelSufficientForMission(testCase)
            % REQ_F16A_P01: available internal fuel shall be >= mission fuel.
            available = F16APhysicalFuelRollup().AvailableFuel_lb;
            required  = F16APhysicalMissionFuel();
            % The diagnostic names the STATE, not a repair. Telling a reader to
            % connect the mission analysis would instruct them to do the one
            % thing D-042 decided against, and would present an unevaluated
            % requirement as an outstanding chore.
            msg = sprintf("REQ_F16A_P01 UNEVALUATED -- this failure is EXPECTED and " + ...
                "PERMANENT (D-042): available=%.0f lb, required=%g. Nothing has been " + ...
                "compared: F16APhysicalMissionFuel returns NaN BY DESIGN, so this red " + ...
                "is not a violation and says nothing about the aircraft. Do NOT clear " + ...
                "it by wiring mission fuel to the /sizing/ analysis. Contrast the " + ...
                "landing red in F16AStaticMarginVerificationTest, where both sides are " + ...
                "finite numbers and the design genuinely fails.", available, required);
            testCase.verifyGreaterThanOrEqual(available, required, msg);
        end
    end
end
