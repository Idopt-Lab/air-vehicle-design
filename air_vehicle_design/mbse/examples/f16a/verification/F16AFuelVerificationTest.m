classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   Checks that the available internal fuel (F16APhysicalFuelRollup, ~6300
    %   lb) is at least the mission fuel required (F16APhysicalMissionFuel).
    %
    %   IT FAILS BY DESIGN, AND PERMANENTLY (D-042). The required side is NaN
    %   and STAYS NaN: F16APhysicalMissionFuel is never wired to the /sizing/
    %   mission analysis -- not now, not later. So the comparison is
    %   available >= NaN, which is false. Do NOT make this green by connecting
    %   mission fuel: the red IS the teaching artifact. It shows verification
    %   that is set up, traceable and NOT YET SATISFIED -- the state a real
    %   programme lives in for most of its life.
    %
    %   WHICH RED IS THIS? The example ships two, and they are different STATES.
    %   This one is UNEVALUATED: required = NaN, so nothing was compared and
    %   REQ_F16A_P01 has not been answered. It is not violated, and no claim
    %   about the aircraft follows from it. The other is VIOLATED --
    %   F16AStaticMarginVerificationTest at landing, where both sides are finite
    %   numbers, the comparison was genuinely made and the design lost (D-051).
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16ASTATICMARGINVERIFICATIONTEST.

    methods (TestClassSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.PathFixture
            % A PathFixture, not a bare addpath: the suite leaves the path as
            % it found it (D-047).
            testCase.applyFixture(PathFixture({f16aRoot(), fullfile(f16aRoot(),"physical")}));
            % Close only the model this suite's roll-up loads. bdclose("all")
            % would also discard whatever else the user had open.
            testCase.addTeardown(@() bdclose("F16A_Physical"));
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
