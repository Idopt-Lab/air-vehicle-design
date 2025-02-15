classdef F16ATests < matlab.unittest.TestCase

    methods (Test)

        function propulsion_test_1(testCase)
            [T_dry, T_AB, ~, ~] = f100_engine_model(35000, 0.524147536);
            testCase.verifyEqual(T_dry, 3582, "RelTol", 0.005)
            testCase.verifyEqual(T_AB, 6248, "RelTol", 0.005)
        end

        function propulsion_test_2(testCase)
            [T_dry, T_AB, ~, ~] = f100_engine_model(35000, 1.77862213);
            testCase.verifyEqual(T_dry, 2682, "RelTol", 0.01)
            testCase.verifyEqual(T_AB, 13671, "RelTol", 0.005)
        end

    end

end