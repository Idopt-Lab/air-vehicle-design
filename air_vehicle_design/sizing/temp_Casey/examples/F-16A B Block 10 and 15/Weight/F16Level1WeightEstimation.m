classdef F16Level1WeightEstimation < Disciplines.Weight.RaymerWeightEstimation
    % F16LEVEL1WEIGHTESTIMATION F-16 operating empty weight estimation using Raymer regression
    %
    % This class implements Raymer's regression-based OEW estimation specifically
    % for the F-16 fighter aircraft at conceptual design (Level I) fidelity.
    %
    % The regression coefficients are:
    %   a = 2.34 (typical for fighter aircraft per Raymer)
    %   b = -0.13 (negative exponent, indicating economy of scale)
    %
    % Reference: Historical F-16 aircraft data and Raymer's fighter aircraft correlations
    %
    % Example:
    %   estimator = F16Level1WeightEstimation();
    %   oew = estimator.estimateOEW(30106);  % Returns ~18435 lbm

    properties (Constant)
        % Raymer regression coefficients for F-16 fighter aircraft
        RegressionCoefficientA = 2.34
        RegressionCoefficientB = -0.13
    end

    methods
        function obj = F16Level1WeightEstimation()
            % Constructor initializes metadata for F-16 Level-I analysis
            obj.AircraftType = "F-16";
            obj.MethodName = "Raymer Regression";
            obj.FidelityLevel = "Level-I";
        end
    end
end
