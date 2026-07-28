classdef FixedWeightsStub < WeightsBase
%FIXEDWEIGHTSSTUB  A minimal stand-in weights object, used only by tests.
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale: SizingLoopL1
%   needs a WeightsBase object (OEW(W_TO), W_TO, W_energy, W_payload_fixed,
%   W_payload_expendable), not a real F16WeightsLN, to test the sizing loop
%   in isolation from any particular aircraft's regressions.
%
%   OEW(W_TO) = oew_fraction * W_TO -- a simple constant empty-weight
%   fraction, chosen only to give the generic sizing-loop test a
%   closed-form fixed point to converge to (see TestSizingLoopL1.m header).

    properties
        W_TO = NaN
        W_energy = NaN
        W_payload_expendable = 300
        W_payload_fixed = 500
        oew_fraction = 0.6
    end

    methods

        function oew = OEW(obj, W_TO)
            oew = obj.oew_fraction * W_TO;
        end

    end

end
