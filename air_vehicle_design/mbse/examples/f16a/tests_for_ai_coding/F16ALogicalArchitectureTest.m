classdef F16ALogicalArchitectureTest < F16ATestCase
    %F16ALOGICALARCHITECTURETEST Verify the F-16A Logical model (RFLP "L").
    %   A MACHINERY suite: is the L model built correctly? L enumerates
    %   technology-neutral solution KINDS and nothing else -- no mass, cost,
    %   TRL, benefit or winner -- so this suite fails the moment a number or a
    %   decision creeps back into L.
    %
    %   Covered: the 9 roles and 4 interfaces; the F->L allocation (14 edges,
    %   Target the only 1->2 fan-out, no mission phase ever a source); the four
    %   requirements homed at L; the three variant roles and their six kinds;
    %   and the internal consistency of the decision IF one has been written
    %   back. Detail: docs/04_logical.md.
    %
    %   NOT covered, on purpose: which kind wins, and the REQ_F16A_L01..L03
    %   decision links. Both are the physical trade study's output, so asserting
    %   them here would couple this suite to whether P has run (D-001, D-010).
    %
    %   Shared helpers are in F16ATestCase.

    properties
        FuncModel   % F16A_Functional (allocation source)
        ActModel    % F16A_MissionActivity (the other allocation source)
        OrigSet     % f16a.slreqx (deferred reqs land here)
        Alloc       % F16A_FunctionToLogical allocation set
        KillAlloc   % F16A_KillChainToLogical allocation set
    end

    properties (Constant)
        Root = "F16A_Logical/";
        % Technology-neutral kinds: a topology, never a product (D-017).
        Kinds = struct( ...
            PropulsionSystem    = {["SingleEngine","TwinEngine"]}, ...
            FlightControlSystem = {["FlyByWire","HydroMechanical"]}, ...
            Airframe            = {["BlendedCrankedDelta","ConventionalTrapWing"]});
        WiredRoles      = ["FuelSystem","PropulsionSystem","Airframe", ...
                           "FlightControlSystem","AvionicsSuite","WeaponSystem"];
        ConstraintRoles = ["LandingGear","CommunicationSystem","MissionSystemsBay"];
        AllRoles        = ["Airframe","PropulsionSystem","FuelSystem", ...
                           "FlightControlSystem","LandingGear","AvionicsSuite", ...
                           "CommunicationSystem","WeaponSystem","MissionSystemsBay"];
        MissionPhases   = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
                           "Egress","Cruise2","Loiter","Landing"];
        % The four logical interfaces and the elements each must carry.
        Interfaces = struct( ...
            FuelFlow       = {["FuelRate_pph","TankState_frac"]}, ...
            ThrustVector   = {"Thrust_lbf"}, ...
            ControlCommand = {"SurfaceDeflect_deg"}, ...
            TargetTrack    = {["Bearing_deg","Range_nm"]});
        % The only stereotype L may carry, and its two properties.
        OptionStereotype = "SolutionOption";
        OptionProperties = ["Selected","DecisionRef"];
        % Everything L must NOT carry: every trade stereotype, and every
        % parameter that belongs to a physical candidate. "TradeCandidate" is
        % the pre-D-056 name and stays on the list -- a retired name that stops
        % being guarded silently exempts whatever takes it next (D-054).
        RetiredStereotypes = ["TradeCandidate","EngineCandidate", ...
            "AirframeCandidate","FlightControlCandidate"];
        TradeNumerics      = ["Mass_lb","UnitCost_USD","TRL","Benefit", ...
            "Thrust_SL_lb","T_SL_lb","AeroBenefit","HandlingBenefit"];
        % The DecisionRef an UNDECIDED kind carries, from the L generator's
        % DefaultValue="'TBD'". L ships undecided and stays so until the
        % physical trade study writes a decision back (D-001).
        UndecidedRef       = "TBD";
        % A recorded decision names one of the three L decision requirements.
        % Only the SHAPE is asserted -- which requirement belongs to which
        % role is P's business (D-010).
        DecisionRefPattern = "^REQ_F16A_L0\d$";
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            import matlab.unittest.fixtures.PathFixture
            root = f16aRoot();
            testCase.applyFixture(PathFixture({root, fullfile(root,"logical"), ...
                fullfile(root,"functions"), fullfile(root,"requirements")}));
            testCase.Profile = "F16A_LogicalOptions";
            slreq.clear();
            testCase.addTeardown(@() slreq.clear());
            % Close any set left open by a prior generate, so allocation.load
            % does not fail with "already an open set".
            try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Logical");
            testCase.FuncModel = systemcomposer.loadModel("F16A_Functional");
            testCase.OrigSet   = slreq.load(fullfile(root,"requirements","f16a.slreqx"));
            testCase.ActModel  = systemcomposer.openActivity("F16A_MissionActivity");
            testCase.Alloc     = systemcomposer.allocation.load("F16A_FunctionToLogical");
            testCase.KillAlloc = systemcomposer.allocation.load("F16A_KillChainToLogical");
            % Close only what this suite opened; bdclose("all") would discard
            % unrelated models the user had open, including F16AOpenForReview's.
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() testCase.KillAlloc.close());
            testCase.addTeardown(@() bdclose("F16A_Logical"));
            testCase.addTeardown(@() bdclose("F16A_Functional"));
            testCase.addTeardown(@() bdclose("F16A_MissionActivity"));
        end
    end

    methods (Test)

        function testLogicalComponentsExist(testCase)
            testCase.verifyNoOffenders(testCase.rolesNotResolving(testCase.AllRoles), ...
                "Missing role");
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 9, ...
                "Expected 9 top-level roles.");
        end

        function testInterfacesDefined(testCase)
            missing = strings(1,0);
            for name = string(fieldnames(testCase.Interfaces))'
                iface = testCase.Model.InterfaceDictionary.getInterface(char(name));
                if isempty(iface); missing(end+1) = name; continue; end %#ok<AGROW>
                elems = string({iface.Elements.Name});
                for e = testCase.Interfaces.(name)
                    if ~ismember(e, elems)
                        missing(end+1) = name + "." + e; %#ok<AGROW>
                    end
                end
            end
            testCase.verifyNoOffenders(missing, "Missing interface or element");
        end

        function testWiredPortsConnected(testCase)
            % The six wired roles have all ports connected; the three
            % constraint roles are intentionally port-free.
            portless = strings(1,0);
            unconnected = strings(1,0);
            for role = testCase.WiredRoles
                c = testCase.Model.lookup(Path=char(testCase.Root + role));
                if isempty(c.Ports); portless(end+1) = role; continue; end %#ok<AGROW>
                for p = c.Ports
                    if ~p.Connected
                        unconnected(end+1) = role + "." + string(p.Name); %#ok<AGROW>
                    end
                end
            end
            stray = strings(1,0);
            for role = testCase.ConstraintRoles
                c = testCase.Model.lookup(Path=char(testCase.Root + role));
                if ~isempty(c.Ports); stray(end+1) = role; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(portless,    "Wired role with no ports");
            testCase.verifyNoOffenders(unconnected, "Unconnected port");
            testCase.verifyNoOffenders(stray,       "Constraint role should be port-free");
        end

        function testAllocationSetExists(testCase)
            testCase.verifyNotEmpty(testCase.Alloc.getScenario("Scenario 1"), ...
                "Missing default allocation scenario.");
            testCase.verifyNotEmpty(testCase.KillAlloc.getScenario("Scenario 1"), ...
                "Missing default scenario in the kill-chain allocation set.");
        end

        function testTheSplitKeptBothHalves(testCase)
            % The 14 edges split 7 / 7 when the kill chain became actions
            % (D-059). Checking each half separately means an empty set cannot
            % hide behind a correct total.
            testCase.verifyNumElements( ...
                testCase.Alloc.getScenario("Scenario 1").Allocations, 7, ...
                "Expected 7 capability-tree edges in F16A_FunctionToLogical.");
            testCase.verifyNumElements( ...
                testCase.KillAlloc.getScenario("Scenario 1").Allocations, 7, ...
                "Expected 7 kill-chain edges in F16A_KillChainToLogical.");
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
            wrong = strings(1,0);
            for k = string(keys(counts))
                if k ~= "Target" && counts(char(k)) ~= 1
                    wrong(end+1) = k + " -> " + counts(char(k)); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrong, "Source should have exactly 1 edge");
        end

        function testMissionPhasesDoNotAllocateStraightToRoles(testCase)
            % A phase reaches a role by composition -- Cruise uses GenerateLift
            % (F16A_MissionUsesCapability) and GenerateLift allocates to
            % Airframe. Storing Cruise -> Airframe as well would be a second
            % home for a derived fact, and since every phase needs airframe,
            % propulsion and fuel the matrix would be nearly full and say
            % almost nothing (D-059). That the phases DO use capabilities is
            % asserted by F16AMissionActivityTest, where the set lives.
            allocated = string(keys(testCase.sourceCounts()));
            testCase.verifyNoOffenders( ...
                intersect(allocated, [testCase.MissionPhases, ...
                    "ProvideAircraftFunctions","Aviate"]), ...
                "Phases and composites must not allocate straight to roles");
        end

        function testDeferredRequirementsPickedUpAtL(testCase)
            % 020/023/024/025 are implemented from L. 022 (materials) and 026
            % (cost) are homed at P, so they are not checked here -- L must
            % stay independent of whether P is built.
            testCase.verifyRequirementsLinked(testCase.OrigSet, ...
                ["REQ_F16A_020","REQ_F16A_023","REQ_F16A_024","REQ_F16A_025"]);
        end

        function testVariantRolesExist(testCase)
            % The three option-bearing roles resolve and expose >=2 kinds.
            thin = strings(1,0);
            for role = testCase.variantRoles()
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                n  = numel(testCase.choicesOf(vc));
                if n < 2; thin(end+1) = role + " has " + n + " kinds"; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(thin, "Variant role must expose >=2 kinds");
        end

        function testEachVariantHasTwoChoices(testCase)
            % Each variant role has exactly its two named kinds.
            defects = strings(1,0);
            for role = testCase.variantRoles()
                for cn = testCase.Kinds.(role)
                    try testCase.Model.lookup(Path=char(testCase.Root + role + "/" + cn));
                    catch, defects(end+1) = "missing kind " + role + "/" + cn; %#ok<AGROW>
                    end
                end
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                n  = numel(testCase.choicesOf(vc));
                if n ~= 2
                    defects(end+1) = role + " has " + n + " kinds, expected 2"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(defects, "Variant kind defect");
        end

        function testExactlyOneActiveChoice(testCase)
            % Each variant role has exactly one active kind, one of its own.
            % WHICH one is not asserted -- that is the physical trade's call.
            defects = strings(1,0);
            for role = testCase.variantRoles()
                vc     = testCase.Model.lookup(Path=char(testCase.Root + role));
                active = testCase.activeChoiceOf(vc);
                if numel(active) ~= 1
                    defects(end+1) = role + " has " + numel(active) + ...
                        " active kinds, expected 1"; %#ok<AGROW>
                elseif ~ismember(string(active.Name), testCase.Kinds.(role))
                    defects(end+1) = role + " active kind '" + string(active.Name) + ...
                        "' is not one of its kinds"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(defects, "Active choice defect");
        end

        function testKindsCarryNoTradeNumerics(testCase)
            % L must be free of trade numerics in the model AND in the profile.
            % The profile half is load-bearing: it fails if somebody re-adds
            % Mass_lb to the L profile, even before anything applies it
            % (D-001, D-008).
            testCase.verifyNotVacuous(testCase.profilesOf(), ...
                "no profile resolved for the L model (expected " + testCase.Profile + ")");

            declaredStereotypes = testCase.profileStereotypeNames();
            testCase.verifyTrue(ismember(testCase.OptionStereotype, declaredStereotypes), ...
                "The L profile must declare " + testCase.OptionStereotype + ...
                ", but declares: " + strjoin(declaredStereotypes, ", ") + ".");
            testCase.verifyNoOffenders( ...
                intersect(testCase.RetiredStereotypes, declaredStereotypes), ...
                "A trade stereotype is declared by the L profile (D-008): L enumerates " + ...
                "options, it does not trade them");

            testCase.verifyNoOffenders( ...
                intersect(testCase.declaredPropertyNames(), testCase.TradeNumerics), ...
                "The L profile declares trade numerics -- a logical role has no mass, " + ...
                "cost, TRL, thrust or benefit; move the property to the P profile");
            applied = strings(1,0);
            for stereo = testCase.RetiredStereotypes
                applied = [applied, reshape(string( ...
                    testCase.elementsWithStereotype(stereo)), 1, [])]; %#ok<AGROW>
            end
            testCase.verifyNoOffenders(applied, ...
                "A trade stereotype is applied in the L model on");
            testCase.verifyNoOffenders( ...
                testCase.elementsWithAnyProperty(testCase.TradeNumerics), ...
                "L components carry trade numerics -- numbers belong to the physical " + ...
                "candidate that realizes the kind");
        end

        function testKindsAreTechnologyNeutral(testCase)
            % Kind names are read back FROM THE MODEL (not from the Kinds
            % constant) so renaming a kind in the generator is caught here.
            kindNames = testCase.namesOf(testCase.kindElements());
            testCase.verifyNumElements(kindNames, 6, ...
                "Expected 6 kinds across the 3 variant roles.");
            testCase.verifyNoOffenders(testCase.vendorTokenHits(kindNames), ...
                "A logical kind names a TOPOLOGY, not a product: it must outlive the " + ...
                "technology that implements it -- SingleEngine outlives the F100 " + ...
                "(D-017, docs/06_methodology.md). Vendor/programme token(s)");
            testCase.verifyNoOffenders(kindNames(contains(kindNames, digitsPattern)), ...
                "A logical kind name must contain no digits: at L a digit is almost " + ...
                "always a model number or a measured quantity, and both are physical");
        end

        function testEveryKindCarriesSolutionOption(testCase)
            % Every kind is a first-class option: SolutionOption applied, both
            % properties present and readable. NO VALUE IS ASSERTED -- pre-trade
            % nothing is Selected, post-trade one kind per role is. Both are
            % legitimate states of a correct L model (D-001, D-010).
            kinds = testCase.kindElements();
            testCase.verifyNotVacuous(kinds, "no kinds were reached");
            missingStereotype = strings(1,0);
            missingProperty   = strings(1,0);
            unreadable        = strings(1,0);
            qualifier = testCase.Profile + "." + testCase.OptionStereotype + ".";
            for i = 1:numel(kinds)
                nm = string(kinds{i}.Name);
                if ~ismember(testCase.OptionStereotype, testCase.appliedStereotypes(kinds{i}))
                    missingStereotype(end+1) = nm; %#ok<AGROW>
                    continue
                end
                for prop = testCase.OptionProperties
                    if ~testCase.hasProp(kinds{i}, qualifier + prop)
                        missingProperty(end+1) = nm + "." + prop; %#ok<AGROW>
                        continue
                    end
                    % "Readable" = getProperty returns something usable. The
                    % VALUE is deliberately unconstrained.
                    try
                        v  = getProperty(kinds{i}, char(qualifier + prop));
                        ok = ischar(v) || isstring(v) || islogical(v) || isnumeric(v);
                    catch
                        ok = false;
                    end
                    if ~ok; unreadable(end+1) = nm + "." + prop; end %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(missingStereotype, ...
                "Kind(s) without " + testCase.OptionStereotype);
            testCase.verifyNoOffenders(missingProperty, ...
                "Kind(s) missing a " + testCase.OptionStereotype + " property");
            testCase.verifyNoOffenders(unreadable, ...
                "Kind propert(ies) applied but not readable via getProperty");
        end

        function testSelectedKindIsConsistentWithItsDecisionRef(testCase)
            % L is legitimately UNDECIDED until the physical trade runs (D-001,
            % D-019), and BOTH states pass here. That conditional structure IS
            % the assertion: "nothing selected, every DecisionRef TBD" is a
            % correct L model, which is why this suite runs on a freshly
            % generated L with no P in existence (D-010).
            %
            % What it forbids is the state in between -- a decision started and
            % not finished. The five defect kinds below are those states.
            % The decision requirements' Implement links are P's (D-010).
            d = testCase.selectionConsistencyDefects();
            testCase.verifyNoOffenders(d.MultipleSelected, ...
                "A role must not have more than one selected kind -- the trade picks " + ...
                "one, and a re-run must clear the previous");
            testCase.verifyNoOffenders(d.NotActive, ...
                "The selected kind must be the role's ACTIVE variant choice, or the " + ...
                "model is configured as one thing while claiming to have decided another");
            testCase.verifyNoOffenders(d.BadDecisionRef, ...
                "A selected kind must cite a well-formed REQ_F16A_L0x, never the '" + ...
                testCase.UndecidedRef + "' it ships with");
            testCase.verifyNoOffenders(d.UndecidedButReferenced, ...
                "This role selected nothing, yet its kinds already cite a decision " + ...
                "requirement. A record with no decision behind it is worse than a blank " + ...
                "one, because it reads as settled");
            testCase.verifyNoOffenders(d.DuplicateDecisionRef, ...
                "Two roles cite the same decision requirement, so one requirement stands " + ...
                "in for two independent decisions (D-016 evaluates the three variation " + ...
                "points separately)");
        end

        function testAllocatedComponentsResolve(testCase)
            % Sampled allocation endpoints resolve, one per SOURCE MODEL --
            % the capability tree and the mission activity now supply seven
            % edges each (D-059).
            %
            % isempty, not try/catch: lookup on a path that does not exist
            % returns EMPTY rather than erroring, so a catch-only check passed
            % vacuously and kept passing after the kill chain moved.
            unresolved = strings(1,0);
            capSrc = "F16A_Functional/ProvideAircraftFunctions/Aviate/ProduceThrust";
            if isempty(lookupOrEmpty(testCase.FuncModel, capSrc))
                unresolved(end+1) = "source " + capSrc;
            end
            killSrc = "Engage";
            if isempty(nodeOrEmpty(testCase.ActModel, killSrc))
                unresolved(end+1) = "source Combat/" + killSrc;
            end
            for target = testCase.Root + ["PropulsionSystem","WeaponSystem"]
                if isempty(lookupOrEmpty(testCase.Model, target))
                    unresolved(end+1) = "target " + target; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(unresolved, "Allocation endpoint not found");
        end

    end

    % =================================================================
    % L-specific helpers. Everything generic (walks, stereotype and profile
    % readers, reporting) is inherited from F16ATestCase.
    % =================================================================
    methods (Access = private)

        function roles = variantRoles(testCase)
            roles = string(fieldnames(testCase.Kinds))';
        end

        function hits = rolesNotResolving(testCase, roles)
            hits = strings(1,0);
            for role = roles
                try testCase.Model.lookup(Path=char(testCase.Root + role));
                catch, hits(end+1) = role; %#ok<AGROW>
                end
            end
        end

        function counts = sourceCounts(testCase)
            % Tally F->L allocation edges by source-function short name, across
            % BOTH sets. An allocation set binds to one source model, and since
            % D-059 the functions live in two: the capability tree in
            % F16A_Functional, the kill chain in F16A_MissionActivity. The
            % fourteen edges are unchanged; only their filing is.
            counts = containers.Map();
            for set = [testCase.Alloc, testCase.KillAlloc]
                for a = set.getScenario("Scenario 1").Allocations
                    nm = char(a.Source.Name);
                    if isKey(counts, nm); counts(nm) = counts(nm) + 1;
                    else;                 counts(nm) = 1;
                    end
                end
            end
        end

        function list = allElements(testCase)
            % Every stereotype-bearing element of L: the root architecture, the
            % 9 roles, and -- via the variant roles -- the 6 kinds.
            [comps, ~] = testCase.walkComponents();
            list = [{testCase.Model.Architecture}, comps];
        end

        function list = kindElements(testCase)
            % The 6 variant choices, as a cell array.
            list = {};
            for role = testCase.variantRoles()
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                for ch = reshape(testCase.choicesOf(vc), 1, [])
                    list{end+1} = ch; %#ok<AGROW>
                end
            end
        end

        function hits = elementsWithStereotype(testCase, stereotypeShortName)
            hits  = strings(1,0);
            elems = testCase.allElements();
            for i = 1:numel(elems)
                if ismember(stereotypeShortName, testCase.appliedStereotypes(elems{i}))
                    hits(end+1) = string(elems{i}.Name); %#ok<AGROW>
                end
            end
        end

        function hits = elementsWithAnyProperty(testCase, propertyShortNames)
            % Any element carrying any of propertyShortNames under ANY of the
            % stereotypes applied to it. Reported as element.stereotype.prop.
            hits  = strings(1,0);
            elems = testCase.allElements();
            for i = 1:numel(elems)
                applied = reshape(string(getStereotypes(elems{i})), 1, []);
                for j = 1:numel(applied)
                    for k = 1:numel(propertyShortNames)
                        qualified = applied(j) + "." + propertyShortNames(k);
                        if testCase.hasProp(elems{i}, qualified)
                            hits(end+1) = string(elems{i}.Name) + "." + qualified; %#ok<AGROW>
                        end
                    end
                end
            end
        end

        function d = selectionConsistencyDefects(testCase)
            % One pass per variant role, branching on whether it has been
            % decided. BOTH branches are legitimate, so this collects the ways
            % each state can be internally inconsistent rather than requiring
            % either one.
            d.MultipleSelected       = strings(1,0);
            d.NotActive              = strings(1,0);
            d.BadDecisionRef         = strings(1,0);
            d.UndecidedButReferenced = strings(1,0);
            d.DuplicateDecisionRef   = strings(1,0);
            cited = strings(1,0);   % DecisionRefs claimed by a decided role
            for role = testCase.variantRoles()
                vc      = testCase.Model.lookup(Path=char(testCase.Root + role));
                choices = testCase.choicesOf(vc);
                names   = testCase.namesOf(choices);
                picked  = false(1, numel(choices));
                refs    = strings(1, numel(choices));
                for i = 1:numel(choices)
                    picked(i) = testCase.propBool(choices(i), ...
                        testCase.Profile + "." + testCase.OptionStereotype + ".Selected");
                    refs(i) = testCase.propOf(choices(i), testCase.OptionStereotype, "DecisionRef");
                end
                if sum(picked) == 0
                    for s = names(refs ~= testCase.UndecidedRef)
                        d.UndecidedButReferenced(end+1) = role + "/" + s + " -> '" + ...
                            refs(names == s) + "'"; %#ok<AGROW>
                    end
                    continue
                end
                if sum(picked) > 1
                    d.MultipleSelected(end+1) = role + " -> {" + ...
                        strjoin(names(picked), ", ") + "}"; %#ok<AGROW>
                    continue
                end
                won    = names(picked);
                ref    = refs(picked);
                active = testCase.activeChoiceOf(vc);
                if numel(active) ~= 1
                    d.NotActive(end+1) = role + " has " + numel(active) + ...
                        " active kinds, so nothing can agree with it"; %#ok<AGROW>
                elseif string(active.Name) ~= won
                    d.NotActive(end+1) = role + ": Selected='" + won + ...
                        "' but the active kind is '" + string(active.Name) + "'"; %#ok<AGROW>
                end
                if isempty(regexp(ref, testCase.DecisionRefPattern, "once"))
                    d.BadDecisionRef(end+1) = role + "/" + won + " -> '" + ref + "'"; %#ok<AGROW>
                    continue
                end
                if ismember(ref, cited)
                    d.DuplicateDecisionRef(end+1) = role + "/" + won + " -> '" + ref + ...
                        "' (already cited by another role)"; %#ok<AGROW>
                end
                cited(end+1) = ref; %#ok<AGROW>
            end
        end

        function hits = vendorTokenHits(testCase, names)
            hits = strings(1,0);
            for i = 1:numel(names)
                for j = 1:numel(testCase.VendorTokens)
                    if contains(names(i), testCase.VendorTokens(j))
                        hits(end+1) = names(i) + " contains '" + ...
                            testCase.VendorTokens(j) + "'"; %#ok<AGROW>
                    end
                end
            end
        end

    end
end

% =====================================================================
function e = lookupOrEmpty(model, path)
%LOOKUPOREMPTY A component, or empty -- never an error and never a surprise.
try e = model.lookup(Path=char(path)); catch, e = []; end
end

% =====================================================================
function n = nodeOrEmpty(activityModel, name)
%NODEOREMPTY A kill-chain action of the mission activity, or empty.
try n = activityModel.Activity.getNode("Combat").ChildActivity.getNode(char(name));
catch, n = [];
end
end
