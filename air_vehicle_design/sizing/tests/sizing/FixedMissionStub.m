classdef FixedMissionStub < MissionAnalysisBase
%FIXEDMISSIONSTUB  A minimal stand-in mission-analysis object, used only by
%   tests.
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale: SizingLoopL1 needs a
%   MissionAnalysisBase object (compute_fuel(aero, prop, W_TO)), not a real
%   MissionAnalysisL1/L2, to test the sizing loop in isolation.
%
%   compute_fuel ignores aero/prop/geom entirely and returns a fixed fraction of
%   the current W_TO guess -- chosen only to give the generic sizing-loop test a
%   closed-form fixed point to converge to (see TestSizingLoopL1.m header). The
%   base constructor is satisfied with the mission test stubs and an empty
%   segment list, since none of them are read once compute_fuel is overridden.

    properties
        fuel_fraction = 0.15
    end

    methods

        function obj = FixedMissionStub()
            obj@MissionAnalysisBase(MissionStubAero(), MissionStubProp(), ...
                MissionStubGeom(), {}, struct());
        end

        function W_fuel = compute_fuel(obj, ~, ~, W_TO)
            W_fuel = obj.fuel_fraction * W_TO;
        end

    end

end
