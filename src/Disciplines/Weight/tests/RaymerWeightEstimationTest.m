classdef RaymerWeightEstimationTest < matlab.unittest.TestCase
    % RAYMERWEIGHTESTIMATIONTEST Unit tests for Raymer regression-based weight estimation
    %
    % This test suite validates the Raymer weight estimation method:
    % - Power-law regression implementation
    % - Sealed estimateOEW method
    % - Method information documentation
    % - F-16 concrete implementation

    methods (Test)
        function test_Raymer_F16_BasicEstimation(testCase)
            % TEST_RAYMER_F16_BASICESTIMATION: Known F-16 reference data
            %
            % F-16A Block 10/15 specifications:
            % - TOGW: 30,106 lbm
            % - Expected OEW: ~18,435 lbm (from historical data)
            % - Raymer coefficients: a=2.34, b=-0.13

            togw = 30106;
            expected_oew = 18435;
            rel_tol = 0.001;  % 0.1% tolerance

            estimator = F16Level1WeightEstimation();
            actual_oew = estimator.estimateOEW(togw);

            testCase.verifyEqual(actual_oew, expected_oew, ...
                "RelTol", rel_tol, ...
                sprintf("F-16 OEW mismatch. Expected %.1f, got %.1f", expected_oew, actual_oew));
        end

        function test_Raymer_F16_PhysicalConstraints(testCase)
            % TEST_RAYMER_F16_PHYSICALCONSTRAINTS: OEW must satisfy physical bounds
            %
            % For any valid aircraft:
            % - OEW > 0
            % - OEW < TOGW (fuel weight must be positive)
            % - OEW/TOGW ratio typical for fighters: 50-90%

            togw_cases = [5000, 15000, 30106, 50000, 80000];
            estimator = F16Level1WeightEstimation();

            for togw = togw_cases
                oew = estimator.estimateOEW(togw);
                oew_fraction = oew / togw;

                % Check bounds
                testCase.verifyGreaterThan(oew, 0, ...
                    sprintf("TOGW %.0f: OEW must be positive", togw));
                testCase.verifyLessThan(oew, togw, ...
                    sprintf("TOGW %.0f: OEW must be < TOGW", togw));

                % Check typical fighter range
                testCase.verifyGreaterThan(oew_fraction, 0.50, ...
                    sprintf("TOGW %.0f: OEW/TOGW should be > 50%% for fighter", togw));
                testCase.verifyLessThan(oew_fraction, 0.95, ...
                    sprintf("TOGW %.0f: OEW/TOGW should be < 95%% for fighter", togw));
            end
        end

        function test_Raymer_F16_MonotonicIncrease(testCase)
            % TEST_RAYMER_F16_MONOTONICINCREASE: OEW increases with TOGW
            %
            % Larger aircraft have larger OEW. The Raymer regression ensures
            % monotonic relationship: if TOGW_1 < TOGW_2, then OEW_1 < OEW_2

            togw_values = [10000, 20000, 30106, 40000, 50000];
            estimator = F16Level1WeightEstimation();
            oew_values = arrayfun(@(tw) estimator.estimateOEW(tw), togw_values);

            % Verify monotonic increase
            for i = 1:(length(oew_values)-1)
                testCase.verifyLessThan(oew_values(i), oew_values(i+1), ...
                    sprintf("OEW not monotonic at TOGW %.0f -> %.0f", ...
                    togw_values(i), togw_values(i+1)));
            end
        end

        function test_Raymer_RegressionCoefficients(testCase)
            % TEST_RAYMER_REGRESSIONCOEFFICIENTS: Verify Raymer coefficients
            %
            % Raymer's formula for fighters: OEW = 2.34 * TOGW^-0.13 * TOGW

            estimator = F16Level1WeightEstimation();
            
            % Manually compute what the formula should give
            togw = 30106;
            a = 2.34;
            b = -0.13;
            expected = (a * togw^b) * togw;

            actual = estimator.estimateOEW(togw);

            testCase.verifyEqual(actual, expected, ...
                sprintf("Raymer formula mismatch. Got %.2f, expected %.2f", actual, expected));
        end

        function test_Raymer_Deterministic(testCase)
            % TEST_RAYMER_DETERMINISTIC: Same input produces same output
            %
            % Regression formula is deterministic - repeated calls with
            % same TOGW must return identical OEW

            togw = 30106;
            estimator = F16Level1WeightEstimation();

            oew_1 = estimator.estimateOEW(togw);
            oew_2 = estimator.estimateOEW(togw);
            oew_3 = estimator.estimateOEW(togw);

            testCase.verifyEqual(oew_1, oew_2);
            testCase.verifyEqual(oew_2, oew_3);
        end

        function test_Raymer_MethodInfo(testCase)
            % TEST_RAYMER_METHODINFO: Method metadata correctly identifies Raymer approach
            %
            % The getMethodInfo struct should document the estimation method,
            % fidelity, and regression coefficients for reproducibility

            estimator = F16Level1WeightEstimation();
            info = estimator.getMethodInfo();

            % Check method is identified as Raymer
            testCase.verifyEqual(info.MethodName, "Raymer Regression");

            % Check aircraft type
            testCase.verifyEqual(info.AircraftType, "F-16");

            % Check fidelity level
            testCase.verifyEqual(info.FidelityLevel, "Level-I");

            % Check coefficients
            testCase.verifyEqual(info.CoefficientA, 2.34);
            testCase.verifyEqual(info.CoefficientB, -0.13);

            % Check formula string is present
            testCase.verifyTrue(contains(info.Formula, "TOGW"), ...
                "Formula should reference TOGW");
        end

        function test_Raymer_SealedMethod(testCase)
            % TEST_RAYMER_SEALEDMETHOD: estimateOEW is sealed (cannot be overridden)
            %
            % The sealed method ensures subclasses cannot bypass the validation
            % contracts defined in WeightEstimationStrategy. This test verifies
            % that the sealed method is correctly called (indirectly tested by
            % validation tests)

            estimator = F16Level1WeightEstimation();
            
            % Attempt to estimate OEW with invalid input
            % The sealed method should catch this via validateInput
            testCase.verifyError(@() estimator.estimateOEW(-100), ...
                "WeightEstimationStrategy:InvalidInput");

            % Valid call should succeed
            oew = estimator.estimateOEW(30000);
            testCase.verifyGreaterThan(oew, 0);
        end

        function test_Raymer_F16_TypicalMissionSizes(testCase)
            % TEST_RAYMER_F16_TYPICALMISSIONSIZES: Test over typical F-16 operating range
            %
            % F-16A typical mission weights:
            % - Air combat mission: ~20,000-25,000 lbm
            % - Deep strike: ~28,000-30,000 lbm
            % - Ferry (max): ~30,106 lbm

            typical_weights = [ ...
                20000;  % Air combat
                25000;  % Intercept
                28000;  % Strike
                30106;  % Ferry/max
            ];

            estimator = F16Level1WeightEstimation();

            expected_ranges = [ ...
                12000, 14000;  % Air combat OEW
                14000, 16000;  % Intercept OEW
                16500, 18000;  % Strike OEW
                17500, 19000;  % Ferry OEW
            ];

            for i = 1:length(typical_weights)
                togw = typical_weights(i);
                oew = estimator.estimateOEW(togw);
                min_expected = expected_ranges(i, 1);
                max_expected = expected_ranges(i, 2);

                testCase.verifyGreaterThanOrEqual(oew, min_expected, ...
                    sprintf("Mission %d: OEW %.0f below expected range [%.0f, %.0f]", ...
                    i, oew, min_expected, max_expected));
                testCase.verifyLessThanOrEqual(oew, max_expected, ...
                    sprintf("Mission %d: OEW %.0f above expected range [%.0f, %.0f]", ...
                    i, oew, min_expected, max_expected));
            end
        end
    end
end
