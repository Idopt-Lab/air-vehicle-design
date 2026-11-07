classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   Checks that the available internal fuel (F16APhysicalFuelRollup, 6300
    %   lb) is at least the mission fuel required (F16APhysicalMissionFuel,
    %   ~5960 lb from the /sizing/ mission analysis). It passes, with about
    %   340 lb of margin.
    %
    %   Compare F16AStaticMarginVerificationTest, whose landing case is the
    %   example's one intentional red: there both sides are finite, the
    %   comparison was genuinely made, and the design lost. Met and violated are
    %   both answers; a NaN on either side would be neither (UNEVALUATED), and
    %   the roll-ups stop with an error rather than return one.
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16ASTATICMARGINVERIFICATIONTEST.

    methods (TestClassSetup)
        function setup(testCase)
            import matlab.unittest.fixtures.PathFixture
            % A PathFixture, not a bare addpath: the suite leaves the path as
            % it found it.
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
