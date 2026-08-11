classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   Checks that the available internal fuel (F16APhysicalFuelRollup, 6300
    %   lb) is at least the mission fuel required (F16APhysicalMissionFuel,
    %   ~5960 lb from the /sizing/ mission analysis). It passes, with about
    %   340 lb of margin.
    %
    %   IT USED TO FAIL BY DESIGN. Until D-060 the required side was NaN, so
    %   nothing was compared and REQ_F16A_P01 was UNEVALUATED -- a deliberate
    %   teaching artifact showing verification that is set up and traceable but
    %   not yet satisfied. D-059 connected the mission analysis, so there is now
    %   a real number to compare and the requirement is answered.
    %
    %   THE EXAMPLE STILL SHIPS ONE INTENTIONAL RED, and it is a different
    %   state: F16AStaticMarginVerificationTest's landing case is VIOLATED --
    %   both sides are finite, the comparison was genuinely made, and the design
    %   lost (D-051). Met and violated are not the same as unevaluated, and the
    %   UNEVALUATED branch survives in the roll-up guards (D-054).
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
            msg = sprintf("REQ_F16A_P01 VIOLATED: the aircraft carries %.0f lb of " + ...
                "internal fuel but the design mission needs %.0f lb, a shortfall " + ...
                "of %.0f lb. Both sides are real numbers, so this is a statement " + ...
                "about the aircraft: either the tanks or the mission has to " + ...
                "change.", available, required, required - available);
            testCase.verifyGreaterThanOrEqual(available, required, msg);
        end
    end
end
