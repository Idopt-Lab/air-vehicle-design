classdef FixedMissionStub < MissionBase
%FIXEDMISSIONSTUB  A minimal stand-in mission-analysis object, used only by
%   tests.
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale: SizingLoopL1
%   needs a MissionBase object (compute_fuel(aero, prop, W_TO)), not a real
%   F16MissionLN, to test the sizing loop in isolation.
%
%   compute_fuel ignores aero/prop entirely and returns a fixed fraction of
%   the current W_TO guess -- chosen only to give the generic sizing-loop
%   test a closed-form fixed point to converge to (see
%   TestSizingLoopL1.m header).

    properties
        fuel_fraction = 0.15
    end

    methods

        function W_fuel = compute_fuel(obj, ~, ~, W_TO)
            W_fuel = obj.fuel_fraction * W_TO;
        end

    end

end
