classdef WeightsBase < handle
    % Abstract base class for all weight discipline implementations.
    %
    % Every fidelity level (WeightLevel1, WeightLevel2, …) inherits from
    % this class and implements OEW.  The sizing loop calls OEW once per
    % iteration to estimate empty weight given the current W_TO guess.

    methods (Abstract)
        % OEW  Returns operating empty weight given takeoff gross weight (lbf).
        %   W_TO  — current takeoff gross weight estimate (lbf)
        %   oew   — operating empty weight (lbf)
        oew = OEW(obj, W_TO)
    end
end
