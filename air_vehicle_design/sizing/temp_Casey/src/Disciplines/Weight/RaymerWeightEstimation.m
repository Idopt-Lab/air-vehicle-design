classdef RaymerWeightEstimation < Disciplines.Weight.WeightEstimationStrategy
    % RAYMERWEIGHTESTIMATION Base class for Raymer regression-based OEW estimation
    %
    % Raymer's method uses power-law regressions fitted to historical aircraft data.
    % The regression formula is:
    %   OEW_fraction = CoefficientA * TOGW^CoefficientB
    %   OEW = OEW_fraction * TOGW

    properties (Abstract, Constant)
        RegressionCoefficientA double
        RegressionCoefficientB double
    end

    methods (Sealed)
        function oew = estimateOEW(obj, togw)
            % ESTIMATEOEW Compute operating empty weight from takeoff gross weight.
            obj.validateInput(togw);

            oew_fraction = obj.RegressionCoefficientA * togw^obj.RegressionCoefficientB;
            oew = oew_fraction * togw;

            obj.validateOutput(oew, togw);
        end

        function info = getMethodInfo(obj)
            % GETMETHODINFO Returns a summary of the estimation method.
            info = struct();
            info.AircraftType = obj.AircraftType;
            info.FidelityLevel = obj.FidelityLevel;
            info.MethodName = obj.MethodName;
            info.Formula = sprintf("OEW = (%.2f * TOGW^%.2f) * TOGW", ...
                obj.RegressionCoefficientA, obj.RegressionCoefficientB);
            info.CoefficientA = obj.RegressionCoefficientA;
            info.CoefficientB = obj.RegressionCoefficientB;
        end
    end
end
