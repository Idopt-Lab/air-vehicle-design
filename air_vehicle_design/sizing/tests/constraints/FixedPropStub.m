classdef FixedPropStub < PropulsionBase
%FIXEDPROPSTUB  A minimal stand-in propulsion object, used only by tests.
%
%   Mirrors FixedAeroStub.m's rationale: TakeoffConstraint/ThrustConstraint
%   don't take a raw alpha number -- their constructor takes a
%   PropulsionBase discipline object and internally calls
%   obj.thrust_lapse(state). A test reproducing Brandt's own point-
%   performance value (e.g. Takeoff) needs to feed it Brandt's own fixed
%   alpha_AB, not drive it through a real F16PropLN model.
%
%   FixedPropStub(alpha) always returns that alpha from
%   thrust_lapse(state, rating), no matter what state or rating is passed in.
%   T_SL/TSFC are unused placeholders the abstract class demands; they have no
%   effect on any test.

    properties
        T_SL = 1
        TSFC = 0
        alpha
    end

    methods

        function obj = FixedPropStub(alpha)
            arguments
                alpha (1,1) double
            end
            obj.alpha = alpha;
        end

        function a = thrust_lapse(obj, ~, ~)
            a = obj.alpha;
        end

        function c_t = get_TSFC(obj, ~)
            c_t = obj.TSFC;
        end

    end

end
