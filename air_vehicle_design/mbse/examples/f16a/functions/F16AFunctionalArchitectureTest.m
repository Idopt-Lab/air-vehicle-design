classdef F16AFunctionalArchitectureTest < matlab.unittest.TestCase
    %F16AFUNCTIONALARCHITECTURETEST Verify the F-16A Functional-layer model.
    %   Checks that the System Composer model F16A_Functional has the
    %   expected functional decomposition, that its ports are all connected,
    %   and that every requirement the Functional layer is responsible for
    %   traces to at least one function via an Implement link.

    properties
        Model
        OrigSet
        DerSet
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
            addpath(fullfile(thisDir, "functions"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            testCase.Model   = systemcomposer.loadModel("F16A_Functional");
            testCase.OrigSet = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.DerSet  = slreq.load(fullfile(thisDir, "requirements", "f16a_functional_derived.slreqx"));
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testComponentsExist(testCase)
            % Every expected function is present at its path in the tree.
            P  = "F16A_Functional/";
            MP = P + "ExecuteMissionProfile/";
            CB = MP + "Combat/";
            AV = P + "ProvideAircraftFunctions/Aviate/";
            NC = P + "ProvideAircraftFunctions/";
            expected = [ ...
                P+"ExecuteMissionProfile", P+"ProvideAircraftFunctions", ...
                MP+"Takeoff", MP+"Accel", MP+"Climb", MP+"Cruise", MP+"Dash", ...
                MP+"Combat", MP+"Egress", MP+"Cruise2", MP+"Loiter", MP+"Landing", ...
                CB+"Find", CB+"Fix", CB+"Track", CB+"Target", CB+"Engage", CB+"Assess", ...
                NC+"Aviate", NC+"Navigate", NC+"Communicate", ...
                AV+"GenerateLift", AV+"ProduceThrust", AV+"Maneuver", ...
                AV+"ManageFuel", AV+"MaintainStructuralIntegrity"];
            testCase.verifyEqual(numel(expected), 26, "Expected 26 component paths.");
            for pth = expected
                found = true;
                try testCase.Model.lookup(Path=char(pth)); catch, found = false; end
                testCase.verifyTrue(found, "Missing component: " + pth);
            end
        end

        function testNoUnconnectedPorts(testCase)
            % Walk the whole tree; every port must be connected.
            m = testCase.Model;
            stack = {m.Architecture}; comps = {};
            while ~isempty(stack)
                a = stack{end}; stack(end) = [];
                for c = a.Components
                    comps{end+1} = c; %#ok<AGROW>
                    stack{end+1} = c.Architecture; %#ok<AGROW>
                end
            end
            bad = strings(0,1);
            for p = m.Architecture.Ports
                if ~p.Connected; bad(end+1) = "ROOT." + string(p.Name); end %#ok<AGROW>
            end
            for i = 1:numel(comps)
                for p = comps{i}.Ports
                    if ~p.Connected
                        bad(end+1) = string(comps{i}.Name) + "." + string(p.Name); %#ok<AGROW>
                    end
                end
            end
            testCase.verifyEmpty(bad, "Unconnected ports: " + strjoin(bad, ", "));
        end

        function testMissionPhaseTraceability(testCase)
            % Mission-phase requirements 001-010 each implemented by a function.
            ids = "REQ_F16A_0" + ["01","02","03","04","05","06","07","08","09","10"];
            testCase.verifyRequirementsLinked(testCase.OrigSet, ids);
        end

        function testPointPerformanceTraceability(testCase)
            % Point-performance requirements 011-018 each implemented (lift+thrust).
            ids = "REQ_F16A_0" + string(11:18);
            testCase.verifyRequirementsLinked(testCase.OrigSet, ids);
            % 011-016 map to exactly lift+thrust (2); 017/018 add a phase link (3).
            for id = "REQ_F16A_0" + string(11:16)
                r = find(testCase.OrigSet, Id=char(id));
                testCase.verifyEqual(numel(r.inLinks()), 2, id + " should have 2 links.");
            end
            for id = ["REQ_F16A_017","REQ_F16A_018"]
                r = find(testCase.OrigSet, Id=char(id));
                testCase.verifyEqual(numel(r.inLinks()), 3, id + " should have 3 links.");
            end
        end

        function testStructuralAndPayloadTraceability(testCase)
            % 019 -> MaintainStructuralIntegrity; 021 -> Engage.
            testCase.verifyRequirementsLinked(testCase.OrigSet, ["REQ_F16A_019","REQ_F16A_021"]);
        end

        function testDerivedTraceability(testCase)
            % Derived placeholders D01-D09 each implemented by a function.
            ids = "REQ_F16A_D0" + string(1:9);
            testCase.verifyRequirementsLinked(testCase.DerSet, ids);
        end

    end

    methods (Access = private)
        function verifyRequirementsLinked(testCase, rs, ids)
            for id = ids
                r = find(rs, Id=char(id));
                testCase.verifyNotEmpty(r, "Requirement not found: " + id);
                if ~isempty(r)
                    testCase.verifyNotEmpty(r.inLinks(), "No Implement link for: " + id);
                end
            end
        end
    end
end
