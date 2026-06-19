classdef WeightEstimationStrategy
    % WEIGHTESTIMATIONSTRATEGY Abstract base class for OEW estimation strategies
    %
    % This abstract class defines the interface for computing operating empty weight (OEW)
    % given a guess for takeoff gross weight (TOGW). Concrete implementations can use
    % various methods (regression, component buildup, etc.) and support any aircraft
    % type or fidelity level.

    properties
        AircraftType string
        FidelityLevel string
        MethodName string
    end

    methods (Abstract)
        % Estimate operating empty weight given takeoff gross weight.
        % Input:  togw (scalar double) - takeoff gross weight
        % Output: oew (scalar double) - operating empty weight (same units as togw)
        oew = estimateOEW(obj, togw)
    end

    methods (Sealed)
        function validateInput(obj, togw)
            % VALIDATEINPUT Checks that input TOGW is valid.
            if ~isscalar(togw)
                error("WeightEstimationStrategy:InvalidInput", ...
                    "TOGW must be a scalar value.");
            end
            if togw <= 0
                error("WeightEstimationStrategy:InvalidInput", ...
                    "TOGW must be positive.");
            end
        end

        function validateOutput(obj, oew, togw)
            % VALIDATEOUTPUT Checks that output OEW is physically reasonable.
            if oew <= 0
                error("WeightEstimationStrategy:InvalidOutput", ...
                    "Estimated OEW must be positive.");
            end
            if oew >= togw
                error("WeightEstimationStrategy:InvalidOutput", ...
                    "OEW (%.2f) cannot be >= TOGW (%.2f).", oew, togw);
            end
        end
    end
end
