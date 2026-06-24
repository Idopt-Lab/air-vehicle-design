classdef Test_structural_integrity < matlab.unittest.TestCase
    % A unit test class that checks outputs of the Load components
    % (nine_g, three_g) inside the Aircraft model.

    methods (TestClassSetup)
        % Runs once before all tests in this class.
        % Right now it’s empty, but you could open the model here.
    end

    methods (Test)
        function verify_Structural_Test(testCase)
            % A test that loops through each child of the Load component
            % and verifies its final simulation output.

            % --- Open the top-level System Composer model
            model = systemcomposer.openModel("Aircraft");

            % --- Look up the "Load" component inside the model
            comp  = lookup(model, Path="Aircraft/Wing/Wingbox/Load");

            % --- Get its architecture and all child components
            arch  = comp.Architecture;
            child = arch.Components;

            % --- Loop over each child (e.g., nine_g, three_g)
            for k = 1:numel(child)
                indi = child(k).Name;    % Get the child’s name
                disp(class(indi))        % Show the datatype of the name

                % --- Look up the full child component object
                updated_comp = lookup(model, Path="Aircraft/Wing/Wingbox/Load/" + indi);

                % --- Get Simulink block handle and referenced model name
                blkH   = updated_comp.SimulinkHandle;    % Handle to the Simulink block
                mdlRef = get_param(blkH, "ModelName");   % Name of referenced model (e.g., 'nine_g')
                disp(mdlRef)

                % --- Convert to char (some Simulink APIs don’t accept string)
                mdlRef_c = char(mdlRef);

                % --- Load the referenced model so it’s ready to simulate
                load_system(mdlRef_c);

                % --- Find Scope and Time Scope blocks in the model
                scopeBlks = [ ...
                    find_system(mdlRef_c,'LookUnderMasks','all','FollowLinks','on','BlockType','Scope'); ...
                    find_system(mdlRef_c,'LookUnderMasks','all','FollowLinks','on','Regexp','on','MaskType','Time Scope') ];
                scopeBlks = cellfun(@char, scopeBlks, 'UniformOutput', false);  % Ensure char format

                % --- Comment out all scopes to avoid GUI errors in tests
                origComment = cell(size(scopeBlks));
                for i = 1:numel(scopeBlks)
                    if isempty(scopeBlks{i}), continue; end
                    origComment{i} = get_param(scopeBlks{i}, 'Commented');  % Save original state
                    set_param(scopeBlks{i}, 'OpenAtSimulationStart','off'); % Prevent auto-opening
                    set_param(scopeBlks{i}, 'Commented','on');              % Comment (disable) block
                end

                try
                    % --- Prepare simulation input object for the model
                    in = Simulink.SimulationInput(mdlRef_c);
                    in = in.setModelParameter('ReturnWorkspaceOutputs','on', ...
                                              'SaveOutput','on', ...
                                              'OutputSaveName','yout', ...
                                              'SaveFormat','Array');

                    % --- Run the simulation
                    out   = sim(in);

                    % --- Get outputs: numeric array from root Outports
                    yout  = out.yout;
                    final = yout(end,:);   % Take the last row (final time sample)

                    disp(final)            % Print the final value

                    % --- Verify that the final output equals 1
                    testCase.verifyEqual(final,1);

                catch ME
                    % --- On error: restore scopes, then rethrow error
                    for i = 1:numel(scopeBlks)
                        if isempty(scopeBlks{i}), continue; end
                        set_param(scopeBlks{i}, 'Commented', origComment{i});
                    end
                    rethrow(ME)
                end

                % --- After success: restore scopes back to original state
                for i = 1:numel(scopeBlks)
                    if isempty(scopeBlks{i}), continue; end
                    set_param(scopeBlks{i}, 'Commented', origComment{i});
                end
            end  % end for-loop
        end      % end test function
    end          % end methods (Test)
end              % end classdef
