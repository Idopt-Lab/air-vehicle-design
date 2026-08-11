classdef F16AMissionActivityTest < F16ATestCase
    %F16AMISSIONACTIVITYTEST Verify the F-16A mission activity (RFLP "F").
    %   A MACHINERY suite: is the mission behaviour built correctly? It checks
    %   the ten phase actions exist in flow order on a typed FlightState flow,
    %   that each is bound to the analysis, that Combat nests the F2T2EA kill
    %   chain, and that the eighteen requirements homed on actions are linked.
    %
    %   It does NOT check the fuel numbers -- that is F16AMissionAnalysisTest.
    %   This suite asks whether the model is wired, not whether it is right.
    %
    %   Layer detail: docs/02_functions.md. Activity API: docs/08_agent_team.md.

    properties
        ActModel  % systemcomposer.activity.Model
        Act       % its root activity
        OrigSet
        DerSet
    end

    properties (Constant)
        Phases    = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
                     "Egress","Cruise2","Loiter","Landing"];
        KillChain = ["Find","Fix","Track","Target","Engage","Assess"];
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            import matlab.unittest.fixtures.PathFixture
            root = f16aRoot();
            testCase.applyFixture(PathFixture({root, ...
                fullfile(root,"functions"), fullfile(root,"requirements")}));
            slreq.clear();
            testCase.addTeardown(@() slreq.clear());   % registered before the loads
            testCase.ActModel = systemcomposer.openActivity("F16A_MissionActivity");
            testCase.Act = testCase.ActModel.Activity;
            testCase.addTeardown(@() bdclose("F16A_MissionActivity"));
            testCase.OrigSet = slreq.load(fullfile(root,"requirements","f16a.slreqx"));
            testCase.DerSet  = slreq.load(fullfile(root,"requirements","f16a_functional_derived.slreqx"));
        end
    end

    methods (Access = private)
        function n = node(testCase, name)
            try n = testCase.Act.getNode(char(name)); catch, n = []; end
        end
        function n = killNode(testCase, name)
            try n = testCase.node("Combat").ChildActivity.getNode(char(name));
            catch, n = []; end
        end
    end

    methods (Test)

        function testPhaseActionsExist(testCase)
            missing = strings(1,0);
            for p = testCase.Phases
                if isempty(testCase.node(p)); missing(end+1) = p; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(missing, "Missing phase action");
        end

        function testPhasesRunInMissionOrder(testCase)
            % The spine is an OBJECT flow: each phase's StateOut pin feeds the
            % next phase's StateIn. Walking it is how the order is checked --
            % the node list itself comes back alphabetical.
            bad = strings(1,0);
            for k = 1:numel(testCase.Phases)-1
                here = testCase.node(testCase.Phases(k));
                next = testCase.node(testCase.Phases(k+1));
                if isempty(here) || isempty(next); continue; end
                reached = false;
                for f = here.getFlows()
                    % A Flow names its ends SourceNode/DestinationNode, and for
                    % an object flow those ends are PINS -- the actions they
                    % join are the pins' parents.
                    if string(parentName(f.SourceNode)) == testCase.Phases(k) && ...
                       string(parentName(f.DestinationNode)) == testCase.Phases(k+1)
                        reached = true;
                    end
                end
                if ~reached
                    bad(end+1) = testCase.Phases(k) + " -> " + testCase.Phases(k+1); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Mission flow is broken between");
        end

        function testFlowIsTypedFlightState(testCase)
            % An untyped pin would let the phases pass anything to each other.
            bad = strings(1,0);
            nPins = 0;
            for p = testCase.Phases
                a = testCase.node(p);
                if isempty(a); continue; end
                for pin = a.Pins
                    nPins = nPins + 1;
                    if string(pin.ObjectType.Name) ~= "FlightState"
                        bad(end+1) = p + "." + string(pin.Name); %#ok<AGROW>
                    end
                end
            end
            testCase.verifyNotVacuous(nPins, "no phase carries a pin");
            testCase.verifyNoOffenders(bad, "Pin is not typed FlightState");
        end

        function testEveryPhaseIsBoundToTheAnalysis(testCase)
            % THE POINT OF D-059: the model records how each number is
            % computed. Combat is the documented exception -- an action has
            % one behaviour and Combat's is the kill chain.
            bad = strings(1,0);
            for p = setdiff(testCase.Phases, "Combat", "stable")
                a = testCase.node(p);
                if isempty(a); continue; end
                expected = "F16AMissionSegment('" + p + "')";
                if string(a.ActionBehavior) ~= "MATLAB"
                    bad(end+1) = p + " behaviour is " + string(a.ActionBehavior); %#ok<AGROW>
                elseif string(a.BehaviorDefinition) ~= expected
                    bad(end+1) = p + " is bound to '" + ...
                        string(a.BehaviorDefinition) + "'"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Phase not bound to F16AMissionSegment");
        end

        function testEveryPhaseHasADuration(testCase)
            bad = strings(1,0);
            for p = testCase.Phases
                a = testCase.node(p);
                if isempty(a); continue; end
                if ~isfinite(a.Duration) || a.Duration < 0
                    bad(end+1) = p + " = " + string(num2str(a.Duration)); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(bad, "Phase duration is not a usable number");
        end

        function testCombatNestsTheKillChain(testCase)
            combat = testCase.node("Combat");
            testCase.assertNotEmpty(combat, "Combat action is missing.");
            testCase.verifyEqual(string(combat.ActionBehavior), "Activity", ...
                "Combat should carry the kill chain as a child activity.");
            missing = strings(1,0);
            for s = testCase.KillChain
                if isempty(testCase.killNode(s)); missing(end+1) = s; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(missing, "Missing kill-chain action");
        end

        function testMissionPhaseTraceability(testCase)
            % 001-010, one action each; 017/018 add the field-length link.
            testCase.verifyRequirementsLinked(testCase.OrigSet, ...
                "REQ_F16A_0" + ["01","02","03","04","05","06","07","08","09","10"]);
        end

        function testKillChainTraceability(testCase)
            % 021 -> Engage; D05-D09 -> the other five kill-chain actions.
            testCase.verifyRequirementsLinked(testCase.OrigSet, "REQ_F16A_021");
            testCase.verifyRequirementsLinked(testCase.DerSet, ...
                "REQ_F16A_D0" + string(5:9));
        end

        function testEveryPhaseUsesAtLeastOneCapability(testCase)
            % The gap D-059 closed. As components the phases could not be
            % allocation sources at all, which is why they were excluded; as
            % actions they can, and every one of them is.
            try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            set = systemcomposer.allocation.load("F16A_MissionUsesCapability");
            cleanup = onCleanup(@() set.close()); %#ok<NASGU>
            sources = strings(1,0);
            for a = set.getScenario("Scenario 1").Allocations
                sources(end+1) = string(a.Source.Name); %#ok<AGROW>
            end
            testCase.verifyNotVacuous(sources, "the use set holds no edges");
            testCase.verifyNoOffenders(setdiff(testCase.Phases, sources), ...
                "Phase uses no capability");
        end

        function testTheLinkSetHasExactlyEighteenLinks(testCase)
            % IDEMPOTENCE, asserted rather than assumed. Deleting the .slmx in
            % the generator's section 0 does not evict an already-loaded copy
            % of it, so before that was fixed each re-run appended another 18
            % links to a stale in-memory set and saved the total. The
            % requirement-linked tests above stayed green throughout, because
            % a duplicated link still resolves -- only the count shows it.
            found = [];
            for ls = slreq.find(Type="LinkSet")
                [~, nm] = fileparts(char(ls.Artifact));
                if string(nm) == "F16A_MissionActivity"
                    found = numel(ls.getLinks());
                end
            end
            testCase.assertNotEmpty(found, ...
                "No link set loaded for F16A_MissionActivity.");
            testCase.verifyEqual(found, 18, ...
                "The mission activity's link set holds " + found + " links, not 18. " + ...
                "A multiple of 18 means the generator appended to a link set it " + ...
                "did not clear -- re-run generate_f16a_functional after deleting " + ...
                "functions/F16A_MissionActivity~mdl.slmx.");
        end

        function testLinksPointAtThisModel(testCase)
            % A requirement linked to SOMETHING passes verifyRequirementsLinked
            % even if D-059 had left the link on a deleted component. These
            % have to resolve into the activity itself.
            ids = "REQ_F16A_0" + ["01","04","10"];
            bad = strings(1,0);
            for id = ids
                r = find(testCase.OrigSet, Id=char(id));
                hits = 0;
                for lk = r.inLinks()
                    [~, f] = fileparts(char(lk.source().artifact));
                    if string(f) == "F16A_MissionActivity"; hits = hits + 1; end
                end
                if hits == 0; bad(end+1) = id; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(bad, "Not linked into the mission activity");
        end

    end
end

% =====================================================================
function n = parentName(pinOrNode)
%PARENTNAME The action a flow end belongs to, or the node's own name.
%   An object flow ends on a PIN whose Parent is the action; a control flow
%   ends on the node itself.
try n = string(pinOrNode.Parent.Name); catch, n = string(pinOrNode.Name); end
end
