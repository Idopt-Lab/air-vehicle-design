classdef RadarRangeTest < matlab.unittest.TestCase
    % Define a test class that uses MATLAB's unit test framework.
    % All tests in here must inherit from matlab.unittest.TestCase.
    methods (TestClassSetup)
        % Shared setup for the whole test class.
        % (Empty here — you could add code that runs once before all tests.)
    end

    methods (Test)
        % This block contains actual test methods.

        function verifyRange(testCase)
            % A test function that verifies whether "active" components
            % in the model have a Range greater than 100.

            % Open the System Composer model named "Aircraft".
            model = systemcomposer.openModel("Aircraft"); 

            % Get the component object at the path "Aircraft/Fuselage/AESARadar"
            comp  = lookup(model, Path="Aircraft/Fuselage/AESARadar");   % get the component
            
            % Access the architecture definition of the "AESARadar" component.            
            % arch = comp.Architecture;

            % Get the Simulink parameter object called "Range" from the child.
            range_param = comp.getParameter("DetectionRange");                  % parameter object

            % Convert the Range parameter's stored string into a numeric value.
            % (sscanf reads the number out of the text string.)
            range_param_val   = sscanf(range_param.Value, '%f', 1);  % read

            % Test assertion: check that the range is greater than 100.
            % If not, the test fails.
            testCase.verifyGreaterThan(range_param_val, 100);  
        end
    end
end
