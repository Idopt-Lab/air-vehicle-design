classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   This test checks that the available internal fuel
    %   (F16APhysicalFuelRollup, 6300 lb) is at least the required mission fuel
    %   (F16APhysicalMissionFuel, approximately 5960 lb from the /sizing/
    %   mission analysis). It passes with approximately 340 lb of margin.
    %
    %   Compare F16AStaticMarginVerificationTest. Its landing case is the only
    %   intentional red in the example. In that test, both sides are finite,
    %   the comparison was really made, and the design lost. Met and violated
    %   are both answers. A NaN on either side would be neither answer
    %   (UNEVALUATED). The roll-ups stop with an error, and do not return a NaN.
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16ASTATICMARGINVERIFICATIONTEST.

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
        function testFuelSufficientForMission(testCase)
            % REQ_F16A_P01: available internal fuel shall be >= mission fuel.
            available = F16APhysicalFuelRollup().AvailableFuel_lb;
            required  = F16APhysicalMissionFuel();
            msg = sprintf("REQ_F16A_P01 VIOLATED: the aircraft carries %.0f lb of " + ...
                "internal fuel, but the design mission needs %.0f lb. The shortfall " + ...
                "is %.0f lb. Both sides are real numbers, so this result is about " + ...
                "the aircraft. The tanks or the mission must change.", ...
                available, required, required - available);
            testCase.verifyGreaterThanOrEqual(available, required, msg);
        end
    end
end
