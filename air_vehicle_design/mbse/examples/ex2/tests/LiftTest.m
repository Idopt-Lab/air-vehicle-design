classdef LiftTest < matlab.unittest.TestCase

    methods (Test)

        function lift_test_1(testCase)
            actual_lift = lift_function();
            testCase.verifyGreaterThan(actual_lift, 100)
        end
    end

end