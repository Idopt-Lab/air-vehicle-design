classdef F16ALogicalArchitectureTest < matlab.unittest.TestCase
    %F16ALOGICALARCHITECTURETEST Verify the F-16A Logical-layer model.
    %   Checks the solution-role decomposition, the light logical backbone,
    %   the function->logical allocation set, the deferred requirements now
    %   homed at L, and the design-alternatives (variant) + trade + selection
    %   machinery.
    %
    %   R2026a API to confirm (new to this repo): variant component queries
    %   getChoices / getActiveChoice; allocation-set queries systemcomposer.
    %   allocation.load, getScenario, scenario.Allocations (Source/Destination),
    %   and stereotype getProperty. Each is used in exactly one place below.

    properties
        Model       % F16A_Logical
        FuncModel   % F16A_Functional (allocation source)
        OrigSet     % f16a.slreqx (deferred reqs land here)
        DerSet      % f16a_logical_derived.slreqx (decision reqs L01-L03)
        Alloc       % F16A_FunctionToLogical allocation set
        Profile = "F16A_LogicalTrades";
        Root    = "F16A_Logical/";
    end

    properties (Constant)
        Variants = struct( ...
            PropulsionSystem    = {["SingleEngine_F100","TwinEngine_LWF"]}, ...
            FlightControlSystem = {["AnalogFBW","HydroMechanical"]}, ...
            Airframe            = {["BlendedCrankedDelta","ConventionalTrapWing"]});
        WiredRoles      = ["FuelSystem","PropulsionSystem","Airframe", ...
                           "FlightControlSystem","AvionicsSuite","WeaponSystem"];
        ConstraintRoles = ["LandingGear","CommunicationSystem","MissionSystemsBay"];
        AllRoles        = ["Airframe","PropulsionSystem","FuelSystem", ...
                           "FlightControlSystem","LandingGear","AvionicsSuite", ...
                           "CommunicationSystem","WeaponSystem","MissionSystemsBay"];
        MissionPhases   = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
                           "Egress","Cruise2","Loiter","Landing"];
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = fileparts(mfilename("fullpath"));
            addpath(fullfile(thisDir, "logical"));
            addpath(fullfile(thisDir, "architecture"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            % Close any set left open by a prior generate in this session, so
            % allocation.load does not fail with "already an open set".
            try, systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Logical");
            testCase.FuncModel = systemcomposer.loadModel("F16A_Functional");
            testCase.OrigSet   = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.DerSet    = slreq.load(fullfile(thisDir, "requirements", "f16a_logical_derived.slreqx"));
            testCase.Alloc     = systemcomposer.allocation.load("F16A_FunctionToLogical");
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testLogicalComponentsExist(testCase)
            % All 9 solution roles exist; the root has exactly 9 components.
            for role = testCase.AllRoles
                found = true;
                try, testCase.Model.lookup(Path=char(testCase.Root + role)); catch, found = false; end
                testCase.verifyTrue(found, "Missing role: " + role);
            end
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 9, ...
                "Expected 9 top-level roles.");
        end

        function testInterfacesDefined(testCase)
            % The four logical interfaces exist with the expected elements.
            expected = struct( ...
                FuelFlow       = ["FuelRate_pph","TankState_frac"], ...
                ThrustVector   = "Thrust_lbf", ...
                ControlCommand = "SurfaceDeflect_deg", ...
                TargetTrack    = ["Bearing_deg","Range_nm"]);
            for name = string(fieldnames(expected))'
                iface = testCase.Model.InterfaceDictionary.getInterface(char(name));
                testCase.verifyNotEmpty(iface, "Missing interface: " + name);
                elems = string({iface.Elements.Name});
                for e = expected.(name)
                    testCase.verifyTrue(ismember(e, elems), name + " missing element " + e);
                end
            end
        end

        function testWiredPortsConnected(testCase)
            % The six wired roles have all ports connected; the three
            % constraint roles are intentionally port-free.
            for role = testCase.WiredRoles
                c = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyNotEmpty(c.Ports, role + " should have ports.");
                for p = c.Ports
                    testCase.verifyTrue(p.Connected, ...
                        "Unconnected port: " + role + "." + string(p.Name));
                end
            end
            for role = testCase.ConstraintRoles
                c = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyEmpty(c.Ports, role + " should be port-free.");
            end
        end

        function testAllocationSetExists(testCase)
            % The allocation set targets F->L and has a scenario.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            testCase.verifyNotEmpty(scenario, "Missing default allocation scenario.");
        end

        function testAllocationCoverageFunctions(testCase)
            % 13 leaf functions are allocation sources; 14 edges total;
            % Target fans out to 2, every other source to exactly 1.
            counts = testCase.sourceCounts();
            testCase.verifyEqual(sum(cell2mat(values(counts))), 14, ...
                "Expected 14 allocation edges (13 leaves; Target fans out to 2).");
            testCase.verifyEqual(numel(keys(counts)), 13, ...
                "Expected 13 distinct source functions.");
            testCase.verifyEqual(counts("Target"), 2, "Target should fan out to 2 roles.");
            for k = string(keys(counts))
                if k ~= "Target"
                    testCase.verifyEqual(counts(char(k)), 1, k + " should have 1 edge.");
                end
            end
        end

        function testMissionPhasesNotAllocated(testCase)
            % No temporal phase (or composite) is an allocation source.
            counts = testCase.sourceCounts();
            allocated = string(keys(counts));
            offenders = intersect(allocated, [testCase.MissionPhases, ...
                "ExecuteMissionProfile","ProvideAircraftFunctions","Aviate","Combat"]);
            testCase.verifyEmpty(offenders, ...
                "Phases/composites must not be allocated: " + strjoin(offenders, ", "));
        end

        function testDeferredRequirementsPickedUpAtL(testCase)
            % 020/023/024/025 now implemented from L. 022 (materials) stays a
            % deferred requirement for P. 026 (cost) is reclassified as a
            % Measure of Merit and homed at P, so it is NOT checked here (its
            % inLinks depend on whether the P layer is built, and L must stay
            % independent of P).
            for id = ["REQ_F16A_020","REQ_F16A_023","REQ_F16A_024","REQ_F16A_025"]
                r = find(testCase.OrigSet, Id=char(id));
                testCase.verifyNotEmpty(r, "Requirement not found: " + id);
                testCase.verifyNotEmpty(r.inLinks(), "Expected an L Implement link for " + id);
            end
            r = find(testCase.OrigSet, Id="REQ_F16A_022");
            testCase.verifyEmpty(r.inLinks(), "REQ_F16A_022 should stay deferred to P (no link).");
        end

        function testVariantRolesExist(testCase)
            % The three trade roles resolve and expose >=2 choices.
            for role = string(fieldnames(testCase.Variants))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyNotEmpty(vc, "Missing variant role: " + role);
                testCase.verifyGreaterThanOrEqual(numel(getChoices(vc)), 2, ...
                    role + " should have >=2 choices.");
            end
        end

        function testEachVariantHasTwoChoices(testCase)
            % Each variant role has exactly its two named choices.
            for role = string(fieldnames(testCase.Variants))'
                expected = testCase.Variants.(role);
                for cn = expected
                    found = true;
                    try, testCase.Model.lookup(Path=char(testCase.Root + role + "/" + cn));
                    catch, found = false; end
                    testCase.verifyTrue(found, "Missing choice " + cn + " in " + role);
                end
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyEqual(numel(getChoices(vc)), 2, role + " should have 2 choices.");
            end
        end

        function testExactlyOneActiveChoice(testCase)
            % Each variant role has exactly one active choice, one of its own.
            for role = string(fieldnames(testCase.Variants))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                active = getActiveChoice(vc);
                testCase.verifyNumElements(active, 1, role + " must have one active choice.");
                testCase.verifyTrue(ismember(string(active.Name), testCase.Variants.(role)), ...
                    role + " active choice is not one of its choices.");
            end
        end

        function testTradeCandidateStereotypeApplied(testCase)
            % Every choice carries TradeCandidate with sensible numbers.
            for role = string(fieldnames(testCase.Variants))'
                for cn = testCase.Variants.(role)
                    c = testCase.Model.lookup(Path=char(testCase.Root + role + "/" + cn));
                    for pr = ["Mass_lb","UnitCost_USD","TRL","Benefit"]
                        v = str2double(string(getProperty(c, ...
                            testCase.Profile + ".TradeCandidate." + pr)));
                        testCase.verifyGreaterThan(v, 0, cn + "." + pr + " should be > 0.");
                    end
                end
            end
        end

        function testTradeStudyRunsAndRanks(testCase)
            % The trade study returns a ranking with a unique winner per role.
            results = F16ALogicalTradeStudy();
            for role = string(fieldnames(testCase.Variants))'
                testCase.verifyTrue(isKey(results, char(role)), "No ranking for " + role);
                T = results(char(role));
                testCase.verifyEqual(sum(T.Rank == 1), 1, "One rank-1 winner expected for " + role);
            end
        end

        function testSelectedMatchesHighestScore(testCase)
            % Selected flag + active variant choice == the top-scored option.
            results = F16ALogicalTradeStudy();
            for role = string(fieldnames(testCase.Variants))'
                T = results(char(role));
                winner = string(T.Choice(T.Rank == 1));
                selected = string(T.Choice(logical(T.Selected)));
                testCase.verifyEqual(selected, winner, "Selected != rank-1 for " + role);
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyEqual(string(getActiveChoice(vc).Name), winner, ...
                    "Active choice != winner for " + role);
            end
        end

        function testTradeDecisionTraceability(testCase)
            % Each decision requirement is Implement-linked from its winner.
            for id = ["REQ_F16A_L01","REQ_F16A_L02","REQ_F16A_L03"]
                r = find(testCase.DerSet, Id=char(id));
                testCase.verifyNotEmpty(r, "Decision requirement not found: " + id);
                testCase.verifyNotEmpty(r.inLinks(), "No decision link for " + id);
            end
        end

        function testAllocatedComponentsResolve(testCase)
            % Sampled allocation endpoints resolve in both models.
            samples = { ...
                "F16A_Functional/ProvideAircraftFunctions/Aviate/ProduceThrust", ...
                    testCase.Root + "PropulsionSystem"; ...
                "F16A_Functional/ExecuteMissionProfile/Combat/Engage", ...
                    testCase.Root + "WeaponSystem"};
            for i = 1:size(samples,1)
                sOK = true; tOK = true;
                try, testCase.FuncModel.lookup(Path=char(samples{i,1})); catch, sOK = false; end
                try, testCase.Model.lookup(Path=char(samples{i,2}));     catch, tOK = false; end
                testCase.verifyTrue(sOK, "Source not found: " + samples{i,1});
                testCase.verifyTrue(tOK, "Target not found: " + samples{i,2});
            end
        end

    end

    methods (Access = private)
        function counts = sourceCounts(testCase)
            % Tally allocation edges by source-function short name.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            counts = containers.Map();
            for a = scenario.Allocations
                nm = char(a.Source.Name);
                if isKey(counts, nm); counts(nm) = counts(nm) + 1;
                else; counts(nm) = 1; end
            end
        end
    end
end
