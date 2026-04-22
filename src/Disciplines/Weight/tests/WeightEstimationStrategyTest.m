classdef WeightEstimationStrategyTest < matlab.unittest.TestCase
    % WEIGHTESTIMATIONSTRATEGYTESTCLASS Unit tests for WeightEstimationStrategy abstract class
    %
    % This test suite validates the contract defined by WeightEstimationStrategy:
    % - Input validation for TOGW
    % - Output validation for OEW
    % - Sealed methods that enforce safety constraints
    %
    % Concrete test class: F16Level1WeightEstimation (used as reference implementation)

    methods (Test)
        function test_Strategy_ValidateInputRejectsZero(testCase)
            % Verify that zero TOGW is rejected
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateInput(0), ...
                "WeightEstimationStrategy:InvalidInput");
        end

        function test_Strategy_ValidateInputRejectsNegative(testCase)
            % Verify that negative TOGW is rejected
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateInput(-100), ...
                "WeightEstimationStrategy:InvalidInput");
        end

        function test_Strategy_ValidateInputRejectsVector(testCase)
            % Verify that vector TOGW is rejected (scalar required)
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateInput([100 200]), ...
                "WeightEstimationStrategy:InvalidInput");
        end

        function test_Strategy_ValidateInputAcceptsScalar(testCase)
            % Verify that positive scalar TOGW is accepted (no error thrown)
            estimator = F16Level1WeightEstimation();
            testCase.verifyNotEmpty(estimator); % Setup successful
            
            % Call validateInput - should NOT throw
            estimator.validateInput(30000);
            
            % If we get here, validation passed silently (as expected)
            testCase.verifyTrue(true);
        end

        function test_Strategy_ValidateOutputRejectsZero(testCase)
            % Verify that zero OEW is rejected
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateOutput(0, 30000), ...
                "WeightEstimationStrategy:InvalidOutput");
        end

        function test_Strategy_ValidateOutputRejectsNegative(testCase)
            % Verify that negative OEW is rejected
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateOutput(-100, 30000), ...
                "WeightEstimationStrategy:InvalidOutput");
        end

        function test_Strategy_ValidateOutputRejectsOEWGreaterThanTOGW(testCase)
            % Verify that OEW >= TOGW is rejected (physically impossible)
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateOutput(30000, 20000), ...
                "WeightEstimationStrategy:InvalidOutput");
        end

        function test_Strategy_ValidateOutputRejectsOEWEqualTOGW(testCase)
            % Verify that OEW == TOGW is rejected (fuel weight must be positive)
            estimator = F16Level1WeightEstimation();
            testCase.verifyError(@() estimator.validateOutput(30000, 30000), ...
                "WeightEstimationStrategy:InvalidOutput");
        end

        function test_Strategy_ValidateOutputAcceptsValidOEW(testCase)
            % Verify that valid OEW < TOGW is accepted
            estimator = F16Level1WeightEstimation();
            
            % Call validateOutput - should NOT throw
            estimator.validateOutput(20000, 30000);
            
            % If we get here, validation passed
            testCase.verifyTrue(true);
        end

        function test_Strategy_ValidateOutputAccepsEdgeCaseOEW(testCase)
            % Verify edge case where OEW is very close to TOGW
            % (within floating point tolerance, this could fail)
            estimator = F16Level1WeightEstimation();
            
            togw = 30000;
            oew = togw * 0.99999;  % 99.999% of TOGW
            
            % Should pass - still less than TOGW
            estimator.validateOutput(oew, togw);
            testCase.verifyTrue(true);
        end
    end
end
