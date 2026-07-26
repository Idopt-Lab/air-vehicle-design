classdef F16AFuelVerificationTest < matlab.unittest.TestCase
    %F16AFUELVERIFICATIONTEST Verify REQ_F16A_P01 (fuel volume sufficiency).
    %   This is the test that the REQ_F16A_P01 "Verify" link points to. It
    %   checks that the DESIGN MEETS the requirement: the available internal
    %   fuel (F16APhysicalFuelRollup) is at least the mission fuel required
    %   (F16APhysicalMissionFuel).
    %
    %   IT FAILS ON PURPOSE for now. The available side (fuel-capacity roll-up)
    %   is real (~6300 lb), but the required side is a NaN stub until the
    %   /sizing/ mission analysis is wired into F16APhysicalMissionFuel. So the
    %   comparison is available >= NaN, which is false -- an honest, traceable
    %   "verification pending" marker. It goes green once mission fuel is real.
    %
    %   Kept as its own file (separate from F16AMaterialsVerificationTest and
    %   from the machinery in F16APhysicalArchitectureTest) so this intentional,
    %   requirement-specific failure never mixes into another suite's status.

    methods (TestClassSetup)
        function setup(testCase)
            addpath(fileparts(mfilename("fullpath")));   % resolve the roll-up fns
            testCase.addTeardown(@() bdclose("all"));
        end
    end

    methods (Test)
        function testFuelSufficientForMission(testCase)
            % REQ_F16A_P01: available internal fuel shall be >= mission fuel.
            available = F16APhysicalFuelRollup().AvailableFuel_lb;
            required  = F16APhysicalMissionFuel();
            msg = sprintf("REQ_F16A_P01 verification PENDING: available=%.0f lb, " + ...
                "required=%g. Connect F16APhysicalMissionFuel to the /sizing/ " + ...
                "mission analysis (it returns NaN until then).", available, required);
            testCase.verifyGreaterThanOrEqual(available, required, msg);
        end
    end
end
