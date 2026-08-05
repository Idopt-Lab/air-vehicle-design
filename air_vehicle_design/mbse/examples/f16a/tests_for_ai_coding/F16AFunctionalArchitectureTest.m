classdef F16AFunctionalArchitectureTest < F16ATestCase
    %F16AFUNCTIONALARCHITECTURETEST Verify the F-16A Functional model (RFLP "F").
    %   A MACHINERY suite: is the F model built correctly? It checks the 26
    %   functions are present at their paths, that no port is left unconnected,
    %   and that every requirement homed at F carries an Implement link.
    %
    %   Shared helpers are in F16ATestCase. Layer detail: docs/02_functions.md.

    properties
        OrigSet   % f16a.slreqx
        DerSet    % f16a_functional_derived.slreqx
    end

    properties (Constant)
        % The 26 functions: a thin mission-phase spine (whose Combat phase
        % decomposes into the F2T2EA kill chain) plus the reusable
        % Aviate/Navigate/Communicate capability tree.
        ExpectedPaths = [ ...
            "F16A_Functional/ExecuteMissionProfile", ...
            "F16A_Functional/ProvideAircraftFunctions", ...
            "F16A_Functional/ExecuteMissionProfile/" + ["Takeoff","Accel","Climb", ...
                "Cruise","Dash","Combat","Egress","Cruise2","Loiter","Landing"], ...
            "F16A_Functional/ExecuteMissionProfile/Combat/" + ["Find","Fix","Track", ...
                "Target","Engage","Assess"], ...
            "F16A_Functional/ProvideAircraftFunctions/" + ["Aviate","Navigate","Communicate"], ...
            "F16A_Functional/ProvideAircraftFunctions/Aviate/" + ["GenerateLift", ...
                "ProduceThrust","Maneuver","ManageFuel","MaintainStructuralIntegrity"]];
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            import matlab.unittest.fixtures.PathFixture
            root = f16aRoot();
            testCase.applyFixture(PathFixture({root, ...
                fullfile(root,"functions"), fullfile(root,"requirements")}));
            slreq.clear();
            testCase.addTeardown(@() slreq.clear());   % registered before the loads
            testCase.Model = systemcomposer.loadModel("F16A_Functional");
            testCase.addTeardown(@() bdclose("F16A_Functional"));
            testCase.OrigSet = slreq.load(fullfile(root,"requirements","f16a.slreqx"));
            testCase.DerSet  = slreq.load(fullfile(root,"requirements","f16a_functional_derived.slreqx"));
        end
    end

    methods (Test)

        function testComponentsExist(testCase)
            testCase.verifyEqual(numel(testCase.ExpectedPaths), 26, ...
                "Expected 26 component paths.");
            missing = strings(1,0);
            for pth = testCase.ExpectedPaths
                try testCase.Model.lookup(Path=char(pth));
                catch, missing(end+1) = pth; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(missing, "Missing component");
        end

        function testNoUnconnectedPorts(testCase)
            [comps, paths] = testCase.walkComponents();
            testCase.verifyNotVacuous(comps, "the walk reached no components");
            bad = strings(1,0);
            for p = testCase.Model.Architecture.Ports
                if ~p.Connected; bad(end+1) = "ROOT." + string(p.Name); end %#ok<AGROW>
            end
            for i = 1:numel(comps)
                for p = comps{i}.Ports
                    if ~p.Connected
                        bad(end+1) = paths(i) + "." + string(p.Name); %#ok<AGROW>
                    end
                end
            end
            testCase.verifyNoOffenders(bad, "Unconnected ports");
        end

        function testMissionPhaseTraceability(testCase)
            % Mission-phase requirements 001-010, one function each.
            testCase.verifyRequirementsLinked(testCase.OrigSet, ...
                "REQ_F16A_0" + ["01","02","03","04","05","06","07","08","09","10"]);
        end

        function testPointPerformanceTraceability(testCase)
            % 011-018 trace to BOTH GenerateLift and ProduceThrust; 017/018
            % add a mission-phase link on top, hence 2 links versus 3.
            ids      = "REQ_F16A_0" + string(11:18);
            expected = [repmat(2,1,6), 3, 3];
            testCase.verifyRequirementsLinked(testCase.OrigSet, ids);
            wrongCount = strings(1,0);
            for k = 1:numel(ids)
                r = find(testCase.OrigSet, Id=char(ids(k)));
                n = numel(r.inLinks());
                if n ~= expected(k)
                    wrongCount(end+1) = ids(k) + " has " + n + ...
                        ", expected " + expected(k); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrongCount, "Wrong Implement link count");
        end

        function testStructuralAndPayloadTraceability(testCase)
            % 019 -> MaintainStructuralIntegrity; 021 -> Engage.
            testCase.verifyRequirementsLinked(testCase.OrigSet, ...
                ["REQ_F16A_019","REQ_F16A_021"]);
        end

        function testDerivedTraceability(testCase)
            % The nine derived placeholders D01-D09, one function each.
            testCase.verifyRequirementsLinked(testCase.DerSet, ...
                "REQ_F16A_D0" + string(1:9));
        end

    end
end
