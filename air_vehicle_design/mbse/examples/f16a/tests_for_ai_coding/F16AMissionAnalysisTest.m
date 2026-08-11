classdef F16AMissionAnalysisTest < F16ATestCase
    %F16AMISSIONANALYSISTEST Verify the mission numbers, not the wiring.
    %   A MACHINERY suite: does the delegation to /sizing/ still produce the
    %   validated mission? It checks the totals against the spreadsheet the
    %   reference model reproduces, that the four segments the model omits are
    %   free, and that what the actions are bound to agrees with the analysis.
    %
    %   Structure is checked by F16AMissionActivityTest.
    %
    %   Detail: docs/02_functions.md, D-059.

    properties (Constant)
        RefFuel_lb  = 6000.43;   % Miss!O9
        RefTime_min = 94.06;     % Miss!O8
        Tol         = 0.01;      % the band /sizing/ holds itself to
        Omitted     = ["Patrol","Patrol2","Patrol3","Climb2"];
        Phases      = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
                       "Egress","Cruise2","Loiter","Landing"];
    end

    properties
        Mission   % F16AMissionAnalysis() result
        Raw       % F16AMissionReference() result, all 14 segments
    end

    methods (TestClassSetup)
        function runTheAnalysis(testCase)
            import matlab.unittest.fixtures.PathFixture
            root = f16aRoot();
            testCase.applyFixture(PathFixture({root, fullfile(root,"functions")}));
            % The cached reference is a persistent inside F16AMissionReference,
            % so a stale one from an earlier suite would be tested instead of
            % a fresh run. Reset going in, and again on the way out.
            F16AMissionReference(Reset=true);
            testCase.addTeardown(@() F16AMissionReference(Reset=true));
            testCase.Mission = evalc_(@F16AMissionAnalysis);
            testCase.Raw     = F16AMissionReference();
        end
    end

    methods (Test)

        function testTotalFuelMatchesTheSpreadsheet(testCase)
            % The diagnostic is POSITIONAL, before the name-value pair.
            testCase.verifyEqual(testCase.Mission.TotalFuel_lb, testCase.RefFuel_lb, ...
                "Mission fuel has drifted off Miss!O9. The MBSE model delegates " + ...
                "to /sizing/ precisely so this number stays the validated one.", ...
                "RelTol", testCase.Tol);
        end

        function testTotalTimeMatchesTheSpreadsheet(testCase)
            testCase.verifyEqual(testCase.Mission.TotalTime_min, testCase.RefTime_min, ...
                "Sortie time has drifted off Miss!O8. It is a DIVISOR in the O&M " + ...
                "cost, so a wrong value moves the life-cycle cost.", ...
                "RelTol", testCase.Tol);
        end

        function testTheOmittedSegmentsAreFree(testCase)
            % The model flies ten phases; the analysis walks fourteen. Dropping
            % four is only honest while they cost nothing.
            names = string(testCase.Raw.segment_names(:));
            bad = strings(1,0);
            for nm = testCase.Omitted
                k = find(names == nm, 1);
                if isempty(k); bad(end+1) = nm + " is not in the analysis"; continue; end %#ok<AGROW>
                if testCase.Raw.fuel_lb(k) ~= 0 || testCase.Raw.time_min(k) ~= 0
                    bad(end+1) = sprintf("%s costs %.2f lb / %.2f min", nm, ...
                        testCase.Raw.fuel_lb(k), testCase.Raw.time_min(k)); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Omitted segment is no longer free");
        end

        function testEveryPhaseHasAFiniteFuelFigure(testCase)
            T = testCase.Mission.Table;
            testCase.verifyEqual(height(T), numel(testCase.Phases), ...
                "The walk should report one row per mission phase.");
            bad = strings(1,0);
            for i = 1:height(T)
                if ~isfinite(T.Fuel_lb(i)) || T.Fuel_lb(i) < 0
                    bad(end+1) = string(T.Phase(i)); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Phase has no usable fuel figure");
        end

        function testTheActionBindingAgreesWithTheWalk(testCase)
            % F16AMissionSegment is what the actions are bound to. If it and
            % the walk ever disagreed, the model would display one mission and
            % the cost model would price another.
            T = testCase.Mission.Table;
            bad = strings(1,0);
            for i = 1:height(T)
                s = F16AMissionSegment(string(T.Phase(i)));
                if ~isequal(s.Fuel_lb, T.Fuel_lb(i)) || ~isequal(s.Time_min, T.Time_min(i))
                    bad(end+1) = string(T.Phase(i)); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Action binding disagrees with the walk");
        end

        function testAnUnknownPhaseIsRejected(testCase)
            % A typo in a BehaviorDefinition must fail loudly, not return the
            % wrong segment's fuel.
            testCase.verifyError(@() F16AMissionSegment("Cruse"), ...
                "F16AMissionSegment:noSuchPhase");
        end

    end
end

% =====================================================================
function out = evalc_(fn)
%EVALC_ Run a printed-steps function without its output in the test log.
evalc('out = fn();');
end
