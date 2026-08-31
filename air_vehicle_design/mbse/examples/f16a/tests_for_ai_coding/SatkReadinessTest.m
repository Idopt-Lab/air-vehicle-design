classdef SatkReadinessTest < matlab.unittest.TestCase
    %SATKREADINESSTEST  Checks that the MCP model_* tools can actually run.
    %   Toolchain test, not a model test: it verifies the MATLAB-side half of
    %   the MCP setup, which fails silently in a way that looks like an MCP
    %   problem ("Unrecognized function or variable 'model_overview'") but is
    %   not. Run it in whatever MATLAB session Claude is attached to.
    %
    %   Failures here mean startup.m did not run -- usually because MATLAB was
    %   not started in the repo root. Run `startup` manually to recover.

    properties (Constant)
        % One entry point per tool declared in the SATK tools.json extension.
        ToolEntryPoints = ["model_check", "model_edit", "model_overview", ...
            "model_query_params", "model_read", "model_resolve_params", "model_test"]

        % Models the tools must be able to find by bare filename.
        ExampleModels = ["F16A_Functional.slx", "F16A_MissionActivity.slx", ...
            "F16A_Logical.slx", "F16A_Physical.slx"]
    end

    methods (Test)

        function satkIsInitialized(testCase)
            testCase.verifyNotEmpty(which('satk_initialize'), ...
                'SATK is not on the path. Run startup from the repo root.');
        end

        function allToolEntryPointsResolve(testCase)
            for name = testCase.ToolEntryPoints
                testCase.verifyNotEmpty(which(name), ...
                    sprintf('Tool entry point %s does not resolve.', name));
            end
        end

        function exampleModelsResolveByFilename(testCase)
            % The MCP tools take a bare filename, so the examples must be on
            % the path -- not merely present on disk.
            for name = testCase.ExampleModels
                testCase.verifyNotEmpty(which(name), ...
                    sprintf('Model %s is not on the path.', name));
            end
        end

        function modelOverviewReturnsHierarchy(testCase)
            % End-to-end: the tool runs and reports the components it should.
            overview = model_overview('F16A_Logical.slx', 'root', 'tree');
            testCase.verifySubstring(char(overview), 'FlightControlSystem');
            testCase.verifySubstring(char(overview), 'PropulsionSystem');
        end

    end
end
