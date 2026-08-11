classdef F16AFunctionalArchitectureTest < F16ATestCase
    %F16AFUNCTIONALARCHITECTURETEST Verify the F-16A capability tree (RFLP "F").
    %   A MACHINERY suite: is the capability half of the F layer built
    %   correctly? It checks the 9 capabilities are present at their paths,
    %   that the tree carries no ports, and that every requirement homed on a
    %   capability carries an Implement link.
    %
    %   The mission thread is NOT here any more -- it is an activity diagram
    %   with its own suite, F16AMissionActivityTest (D-059).
    %
    %   Shared helpers are in F16ATestCase. Layer detail: docs/02_functions.md.

    properties
        OrigSet   % f16a.slreqx
        DerSet    % f16a_functional_derived.slreqx
    end

    properties (Constant)
        % The 9 capabilities: the reusable Aviate/Navigate/Communicate tree.
        ExpectedPaths = [ ...
            "F16A_Functional/ProvideAircraftFunctions", ...
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
            testCase.verifyEqual(numel(testCase.ExpectedPaths), 9, ...
                "Expected 9 component paths.");
            missing = strings(1,0);
            for pth = testCase.ExpectedPaths
                try testCase.Model.lookup(Path=char(pth));
                catch, missing(end+1) = pth; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(missing, "Missing component");
        end

        function testCapabilityTreeHasNoPorts(testCase)
            % A capability is something the aircraft CAN do, not a step with an
            % input and an output -- the flow belongs to the mission activity.
            % This replaced a no-unconnected-ports sweep, which after D-059
            % would have passed by having nothing to check.
            [comps, paths] = testCase.walkComponents();
            testCase.verifyNotVacuous(comps, "the walk reached no components");
            bad = strings(1,0);
            for p = testCase.Model.Architecture.Ports
                bad(end+1) = "ROOT." + string(p.Name); %#ok<AGROW>
            end
            for i = 1:numel(comps)
                for p = comps{i}.Ports
                    bad(end+1) = paths(i) + "." + string(p.Name); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Capability tree should have no ports");
        end

        function testPointPerformanceTraceability(testCase)
            % 011-018 each trace to BOTH GenerateLift and ProduceThrust.
            %
            % Counted PER ARTIFACT, not in total. 017 and 018 also link to the
            % Takeoff and Landing actions, and whether those links resolve
            % depends on whether the activity's link set happens to be loaded
            % -- which would make a total count depend on suite order. This
            % suite owns F16A_Functional, so it counts what starts there.
            ids = "REQ_F16A_0" + string(11:18);
            testCase.verifyRequirementsLinked(testCase.OrigSet, ids);
            wrongCount = strings(1,0);
            for k = 1:numel(ids)
                r = find(testCase.OrigSet, Id=char(ids(k)));
                n = 0;
                for lk = r.inLinks()
                    [~, f] = fileparts(char(lk.source().artifact));
                    if string(f) == "F16A_Functional"; n = n + 1; end
                end
                if n ~= 2
                    wrongCount(end+1) = ids(k) + " has " + n + ...
                        " links from F16A_Functional, expected 2"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrongCount, "Wrong Implement link count");
        end

        function testStructuralTraceability(testCase)
            % 019 -> MaintainStructuralIntegrity. 021 moved to the Engage
            % ACTION and is checked by F16AMissionActivityTest.
            testCase.verifyRequirementsLinked(testCase.OrigSet, "REQ_F16A_019");
        end

        function testDerivedTraceability(testCase)
            % D01-D04, one capability each. D05-D09 moved to the kill-chain
            % actions and are checked by F16AMissionActivityTest.
            testCase.verifyRequirementsLinked(testCase.DerSet, ...
                "REQ_F16A_D0" + string(1:4));
        end

    end
end
