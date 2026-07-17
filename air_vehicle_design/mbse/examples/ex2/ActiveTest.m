classdef ActiveTest < matlab.unittest.TestCase
    % Define a test class that uses MATLAB’s unit test framework.
    % All tests in here must inherit from matlab.unittest.TestCase.
    methods (TestClassSetup)
        % Shared setup for the whole test class.
        % (Empty here — you could add code that runs once before all tests.)
    end

    methods (Test)
        % This block contains actual test methods.

        function verifyActive(testCase)
            % A test function that verifies whether "active" components
            % in the model have a Range greater than 100.

            % Open the System Composer model named "Aircraft".
            model = systemcomposer.openModel("Aircraft"); 

            % Get the component object at the path "Aircraft/Fuselage/Threat/Detect".
            % This corresponds to the "Detect" block inside your architecture.          
            comp  = lookup(model, Path="Aircraft/Fuselage/Threat/Detect");   % get the component
            
            % Access the architecture definition of the "Detect" component.            
            arch = comp.Architecture;

            % Get all the child components of "Detect" (e.g., AESA, PESA).
            child = arch.Components;

            % Loop over each child component (like AESA, PESA).
            for k = 1:numel(child)

                % Get the name of the current child (a string like "AESA")
                indi = child(k).Name;

                % Uncomment to print the child’s name in the command window.
                %disp(child(k).Name)     

                % Look up the full path to the current child component inside the model.
                updated_comp = lookup(model, Path="Aircraft/Fuselage/Threat/Detect/" + indi);

                % Save the full path as text (for display or debugging).
                childPath="Aircraft/Fuselage/Threat/Detect/" + indi;
                
                % Read the stereotype property "Active" from the child.
                % This tells you if the radar (AESA/PESA) is marked as active.
                active_stereo = updated_comp.getPropertyValue('DetectProfile.Physical.Active'); 
                
                % Get the Simulink parameter object called "Range" from the child.
                range_stereo = updated_comp.getParameter("Range");                  % parameter object
                
                % Convert the Range parameter’s stored string into a numeric value.
                % (sscanf reads the number out of the text string.)
                range_stereo_val   = sscanf(range_stereo.Value, '%f', 1);  % read
                
                % Print the numeric range value to the command window.
                disp(range_stereo_val); 

                % If the child’s Active property is set to "true"
                if active_stereo == "true"

                    % Print the full path of the active component (for context).
                    disp(childPath)

                    % Test assertion: check that the range is greater than 100.
                    % If not, the test fails.
                    testCase.verifyGreaterThan(range_stereo_val, 100);
                end
            end              
        end
    end
end
