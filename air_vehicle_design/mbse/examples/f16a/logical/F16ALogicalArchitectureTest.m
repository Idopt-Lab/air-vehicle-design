classdef F16ALogicalArchitectureTest < matlab.unittest.TestCase
    %F16ALOGICALARCHITECTURETEST Verify the F-16A Logical-layer model (RFLP "L").
    %   A MACHINERY test: it asks "is the L model built correctly?", never "is
    %   this the right design?". After the L-options / P-trade restructure the
    %   Logical layer enumerates technology-neutral solution KINDS and nothing
    %   else -- no masses, no costs, no TRL, no benefit, no winner -- so this
    %   suite is written to fail the moment a number or a decision creeps back
    %   into L.
    %
    %   COVERED HERE
    %     * Structure -- 9 solution roles at the root, the 4 logical
    %       interfaces, the 6 wired roles fully connected and the 3
    %       constraint-driven roles deliberately port-free.
    %     * Allocation -- the F->L set and its scenario exist; 13 leaf
    %       functions produce 14 edges (Target is the single 1->2 fan-out); no
    %       mission phase or composite capability is ever an allocation source;
    %       sampled endpoints resolve in both models.
    %     * Requirements -- 020/023/024/025 are Implement-linked from L.
    %     * Options -- the three variant roles each expose exactly their two
    %       named kinds with exactly one active; every kind carries the
    %       SolutionOption stereotype with both properties readable; every kind
    %       name is free of vendor, program and digit tokens; and neither the
    %       kinds nor the L profile declares Mass_lb, UnitCost_USD, TRL or
    %       Benefit.
    %     * The decision, IF one has been recorded -- L ships undecided and is
    %       written to later by the physical trade study, so
    %       testSelectedKindIsConsistentWithItsDecisionRef is written to hold
    %       in BOTH states: nothing selected and every DecisionRef 'TBD', or
    %       one kind per role selected, active, and pointing at a well-formed
    %       REQ_F16A_L0x. What it forbids is the state in between.
    %
    %   NOT COVERED HERE -- and why
    %     * WHICH kind wins. L presents options, it does not decide. The trade
    %       runs at P, in physical/F16APhysicalTradeStudy.m (D-001, and
    %       docs/06_methodology.md for the boundary rule).
    %     * The REQ_F16A_L01..L03 decision links. Those links are written by
    %       the physical trade study, so asserting them here would make the L
    %       suite pass or fail depending on whether P had been run -- exactly
    %       the layer coupling this restructure removes. They are asserted in
    %       F16APhysicalArchitectureTest instead (D-010).
    %     * WHETHER anything is selected. Before the trade runs no kind is;
    %       afterwards exactly one per role is. Both are legitimate states of
    %       a correctly built L model, so testEveryKindCarriesSolutionOption
    %       checks only that the property exists and is readable, and
    %       testSelectedKindIsConsistentWithItsDecisionRef checks the
    %       INTERNAL CONSISTENCY of whichever state the model is in rather
    %       than requiring one of them.
    %     * Any design target (mass, cost, static margin). Those live in the
    %       per-requirement verification suites, never in a machinery test.
    %
    %   R2026a APIs exercised here, each isolated in one helper below so a
    %   signature fix touches one place:
    %     * Variants   -- getChoices, getActiveChoice.
    %     * Allocation -- systemcomposer.allocation.load, getScenario,
    %                     scenario.Allocations (Source/Destination).
    %     * Stereotypes-- getStereotypes (returns a cell array of
    %                     '<profile>.<stereotype>'), hasProperty and
    %                     getProperty (both take
    %                     "<profile>.<stereotype>.<property>").
    %     * Profiles   -- model.Profiles -> Profile.Stereotypes ->
    %                     Stereotype.Properties(k).Name, so a numeric property
    %                     re-added to the L PROFILE fails here even before any
    %                     component applies it.

    properties
        Model       % F16A_Logical
        FuncModel   % F16A_Functional (allocation source)
        OrigSet     % f16a.slreqx (deferred reqs land here)
        Alloc       % F16A_FunctionToLogical allocation set
        Profile = "F16A_LogicalOptions";
        Root    = "F16A_Logical/";
    end

    properties (Constant)
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
        % The only stereotype L is allowed to carry, and its two properties.
        OptionStereotype = "SolutionOption";
        OptionProperties = ["Selected","DecisionRef"];
        % Everything L must NOT carry: the retired trade stereotype and the
        % four parameters that now belong to a physical candidate.
        RetiredStereotype = "TradeCandidate";
        TradeNumerics     = ["Mass_lb","UnitCost_USD","TRL","Benefit"];
        % Vendor / programme tokens. Matched CASE-SENSITIVELY on purpose:
        % "ConventionalTrapWing" contains the substring "pW", so a
        % case-insensitive "PW" test would fire on a perfectly good kind name.
        VendorTokens      = ["F100","F110","PW","GE","LWF","Analog"];
        % The DecisionRef an UNDECIDED kind carries, straight from the L
        % generator's DefaultValue="'TBD'". L ships in this state and stays in
        % it until the physical trade study writes a decision back (D-001).
        UndecidedRef       = "TBD";
        % A recorded decision names one of the three L-layer decision
        % requirements. Only the SHAPE is asserted here: which requirement
        % belongs to which role, and whether it is really Implement-linked, is
        % the physical trade study's business and is asserted in
        % F16APhysicalArchitectureTest (D-010). Asserting the mapping here
        % would re-couple the L suite to whether P has run.
        DecisionRefPattern = "^REQ_F16A_L0\d$";
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
            addpath(fullfile(thisDir, "logical"));
            addpath(fullfile(thisDir, "functions"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            % Close any set left open by a prior generate in this session, so
            % allocation.load does not fail with "already an open set".
            try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Logical");
            testCase.FuncModel = systemcomposer.loadModel("F16A_Functional");
            testCase.OrigSet   = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
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
                try testCase.Model.lookup(Path=char(testCase.Root + role)); catch, found = false; end
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
            % 020/023/024/025 are implemented from L. The remaining two
            % (022 materials, 026 cost) are homed at the PHYSICAL layer, so
            % they are not checked here -- L must stay independent of whether
            % P is built.
            for id = ["REQ_F16A_020","REQ_F16A_023","REQ_F16A_024","REQ_F16A_025"]
                r = find(testCase.OrigSet, Id=char(id));
                testCase.verifyNotEmpty(r, "Requirement not found: " + id);
                testCase.verifyNotEmpty(r.inLinks(), "Expected an L Implement link for " + id);
            end
        end

        function testVariantRolesExist(testCase)
            % The three option-bearing roles resolve and expose >=2 kinds.
            for role = string(fieldnames(testCase.Kinds))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyNotEmpty(vc, "Missing variant role: " + role);
                testCase.verifyGreaterThanOrEqual(numel(getChoices(vc)), 2, ...
                    role + " should have >=2 kinds.");
            end
        end

        function testEachVariantHasTwoChoices(testCase)
            % Each variant role has exactly its two named kinds.
            for role = string(fieldnames(testCase.Kinds))'
                expected = testCase.Kinds.(role);
                for cn = expected
                    found = true;
                    try testCase.Model.lookup(Path=char(testCase.Root + role + "/" + cn));
                    catch, found = false; end
                    testCase.verifyTrue(found, "Missing kind " + cn + " in " + role);
                end
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                testCase.verifyEqual(numel(getChoices(vc)), 2, role + " should have 2 kinds.");
            end
        end

        function testExactlyOneActiveChoice(testCase)
            % Each variant role has exactly one active kind, one of its own.
            % WHICH one is not asserted -- that is the physical trade's call.
            for role = string(fieldnames(testCase.Kinds))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                active = getActiveChoice(vc);
                testCase.verifyNumElements(active, 1, role + " must have one active kind.");
                testCase.verifyTrue(ismember(string(active.Name), testCase.Kinds.(role)), ...
                    role + " active kind is not one of its kinds.");
            end
        end

        function testKindsCarryNoTradeNumerics(testCase)
            % L must be free of trade numerics, in the model AND in the
            % profile. The profile half is the load-bearing one: it fails if
            % somebody re-adds Mass_lb to the L profile, even before any
            % component applies it (D-001, D-008).
            profs = testCase.logicalProfiles();
            testCase.verifyNotEmpty(profs, ...
                "No profile resolved for the L model -- expected " + testCase.Profile + ...
                ". Without it the rest of this test would pass vacuously.");

            declaredStereotypes = testCase.profileStereotypeNames();
            testCase.verifyTrue(ismember(testCase.OptionStereotype, declaredStereotypes), ...
                "The L profile must declare " + testCase.OptionStereotype + ...
                ", but declares: " + strjoin(declaredStereotypes, ", ") + ".");
            testCase.verifyFalse(ismember(testCase.RetiredStereotype, declaredStereotypes), ...
                testCase.RetiredStereotype + " is retired from the Logical layer (D-008): " + ...
                "L enumerates options, it does not trade them.");

            declaredNumerics = intersect(testCase.declaredPropertyNames(), testCase.TradeNumerics);
            testCase.verifyEmpty(declaredNumerics, ...
                "The L profile declares trade numerics: " + strjoin(declaredNumerics, ", ") + ...
                ". A logical role has no mass, cost, TRL or benefit -- only a " + ...
                "physical part does. Move the property to the P profile.");

            appliedRetired = testCase.elementsWithStereotype(testCase.RetiredStereotype);
            testCase.verifyEmpty(appliedRetired, ...
                testCase.RetiredStereotype + " is applied in the L model on: " + ...
                strjoin(appliedRetired, ", ") + ".");

            carriedNumerics = testCase.elementsWithAnyProperty(testCase.TradeNumerics);
            testCase.verifyEmpty(carriedNumerics, ...
                "L components carry trade numerics: " + strjoin(carriedNumerics, ", ") + ...
                ". Numbers belong to the physical candidate that realizes the kind.");
        end

        function testKindsAreTechnologyNeutral(testCase)
            % Kind names are read back FROM THE MODEL (not from the Kinds
            % constant) so renaming a kind in the generator is caught here.
            kindNames = testCase.allKindNames();
            testCase.verifyNumElements(kindNames, 6, ...
                "Expected 6 kinds across the 3 variant roles.");

            vendorHits = testCase.vendorTokenHits(kindNames);
            testCase.verifyEmpty(vendorHits, ...
                "A logical kind names a TOPOLOGY, not a product: it must outlive " + ...
                "the technology that implements it (SingleEngine outlives the F100 " + ...
                "-- D-017, docs/06_methodology.md three-question test). " + ...
                "Vendor/programme token(s) found: " + strjoin(vendorHits, "; ") + ...
                ". The technology commitment belongs to a PHYSICAL candidate.");

            digitHits = kindNames(contains(kindNames, digitsPattern));
            testCase.verifyEmpty(digitHits, ...
                "A logical kind name must contain no digits: at L a digit is almost " + ...
                "always a model number or a measured quantity, and both are physical. " + ...
                "Offending kind(s): " + strjoin(digitHits, ", ") + ".");
        end

        function testEveryKindCarriesSolutionOption(testCase)
            % Every kind is a first-class option: SolutionOption applied, both
            % properties present and readable. NO VALUE IS ASSERTED --
            % pre-trade nothing is Selected and DecisionRef is blank;
            % post-trade one kind per role is Selected. Both are legitimate
            % states of a correctly built L model (D-001, D-010).
            missingStereotype = testCase.kindsMissingStereotype(testCase.OptionStereotype);
            testCase.verifyEmpty(missingStereotype, ...
                "Kind(s) without " + testCase.OptionStereotype + ": " + ...
                strjoin(missingStereotype, ", ") + ".");

            missingProperty = testCase.kindsMissingProperty(testCase.OptionProperties);
            testCase.verifyEmpty(missingProperty, ...
                "Kind(s) missing a " + testCase.OptionStereotype + " property: " + ...
                strjoin(missingProperty, ", ") + ".");

            unreadable = testCase.kindsWithUnreadableProperty(testCase.OptionProperties);
            testCase.verifyEmpty(unreadable, ...
                "Kind propert(ies) applied but not readable via getProperty: " + ...
                strjoin(unreadable, ", ") + ".");
        end

        function testSelectedKindIsConsistentWithItsDecisionRef(testCase)
            % L is legitimately UNDECIDED until the physical trade study runs
            % (D-001, D-019), and this test is written so that both states
            % pass. That conditional structure IS the assertion: it encodes
            % that "no kind is selected and every DecisionRef says TBD" is a
            % correct L model, not a broken one -- which is why this suite can
            % still be run on a freshly generated L model with no P layer in
            % existence, exactly as D-010 requires.
            %
            % What it forbids is the state in between, where the decision was
            % started and not finished:
            %   * two kinds of one role claiming to be selected -- a re-run
            %     that recorded a new winner without clearing the old one;
            %   * a selected kind that is not the ACTIVE choice, so the model
            %     is configured as one thing and says it decided another;
            %   * a selected kind whose DecisionRef is still 'TBD', i.e. a
            %     decision with no decision record behind it;
            %   * an UNDECIDED role whose kinds already cite a decision
            %     requirement -- the mirror image, a record with no decision;
            %   * two roles citing the SAME decision requirement, which would
            %     mean one requirement is standing in for two decisions.
            %
            % The decision requirements' Implement links are deliberately NOT
            % checked here. Those are written by P (D-010).
            d = testCase.selectionConsistencyDefects();
            testCase.verifyEmpty(d.MultipleSelected, ...
                "A role must not have more than one selected kind -- the trade picks " + ...
                "one, and a re-run must clear the previous one: " + ...
                strjoin(d.MultipleSelected, "; ") + ".");
            testCase.verifyEmpty(d.NotActive, ...
                "The selected kind must be the role's ACTIVE variant choice, or the " + ...
                "model is configured as one thing while claiming to have decided " + ...
                "another: " + strjoin(d.NotActive, "; ") + ".");
            testCase.verifyEmpty(d.BadDecisionRef, ...
                "A selected kind must cite the decision requirement that records the " + ...
                "choice -- a well-formed REQ_F16A_L0x, never the '" + ...
                testCase.UndecidedRef + "' it ships with: " + ...
                strjoin(d.BadDecisionRef, "; ") + ".");
            testCase.verifyEmpty(d.UndecidedButReferenced, ...
                "This role has selected nothing, yet its kinds already cite a decision " + ...
                "requirement. An undecided option must read '" + testCase.UndecidedRef + ...
                "': a decision record with no decision behind it is worse than a blank " + ...
                "one, because it reads as settled: " + ...
                strjoin(d.UndecidedButReferenced, "; ") + ".");
            testCase.verifyEmpty(d.DuplicateDecisionRef, ...
                "Two roles cite the same decision requirement, so one requirement is " + ...
                "standing in for two independent decisions (D-016 evaluates the three " + ...
                "variation points separately): " + ...
                strjoin(d.DuplicateDecisionRef, "; ") + ".");
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
                try testCase.FuncModel.lookup(Path=char(samples{i,1})); catch, sOK = false; end
                try testCase.Model.lookup(Path=char(samples{i,2}));     catch, tOK = false; end
                testCase.verifyTrue(sOK, "Source not found: " + samples{i,1});
                testCase.verifyTrue(tOK, "Target not found: " + samples{i,2});
            end
        end

    end

    % =================================================================
    % Helpers. All model/profile traversal lives here so the test methods
    % above stay Arrange-Act-Assert and every R2026a API call sits in
    % exactly one place.
    % =================================================================
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

        function s = shortName(~, qualified)
            % Last token of "<profile>.<stereotype>.<property>" (or of a bare
            % name, which is returned unchanged).
            parts = split(string(qualified), ".");
            s = parts(end);
        end

        function list = allElements(testCase)
            % Every stereotype-bearing element of the L model: the root
            % architecture, the 9 roles, and -- via the variant roles -- the
            % 6 kinds. Returned as a cell array because Component and
            % VariantComponent are different classes.
            list = [{testCase.Model.Architecture}, testCase.descend(testCase.Model.Architecture)];
        end

        function list = descend(testCase, arch)
            % Architecture-side walk.
            list = {};
            for c = arch.Components
                list{end+1} = c; %#ok<AGROW>
                list = [list, testCase.descendInto(c)]; %#ok<AGROW>
            end
        end

        function list = descendInto(testCase, comp)
            % The one place that knows about variants. On a saved-and-reloaded
            % model a VariantComponent's .Architecture.Components returns ZERO
            % (Stage-0 finding 6), so getChoices is the only accessor that
            % reaches the kinds -- and the kinds are exactly what a "no trade
            % numerics anywhere at L" sweep is looking for. Same rule as
            % F16APhysicalArchitectureTest.descendInto.
            if isa(comp, "systemcomposer.arch.VariantComponent")
                list = {};
                choices = getChoices(comp);
                for i = 1:numel(choices)
                    list{end+1} = choices(i); %#ok<AGROW>
                    list = [list, testCase.descend(choices(i).Architecture)]; %#ok<AGROW>
                end
            else
                list = testCase.descend(comp.Architecture);
            end
        end

        function list = kindElements(testCase)
            % The 6 variant choices, as a cell array of components.
            list = {};
            for role = string(fieldnames(testCase.Kinds))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                choices = getChoices(vc);
                for i = 1:numel(choices)
                    list{end+1} = choices(i); %#ok<AGROW>
                end
            end
        end

        function names = allKindNames(testCase)
            kinds = testCase.kindElements();
            names = strings(1, numel(kinds));
            for i = 1:numel(kinds)
                names(i) = string(kinds{i}.Name);
            end
        end

        function names = appliedStereotypes(testCase, elem)
            % Short names of the stereotypes applied to one element.
            % getStereotypes returns a cell array of '<profile>.<stereotype>'.
            qualified = reshape(string(getStereotypes(elem)), 1, []);
            names = strings(1, numel(qualified));
            for i = 1:numel(qualified)
                names(i) = testCase.shortName(qualified(i));
            end
        end

        function tf = elementHasProperty(~, elem, qualifiedName)
            % hasProperty is documented to return a logical, but it errors
            % when the named stereotype/property does not exist at all.
            % Either way the element does not carry the property.
            try
                tf = logical(hasProperty(elem, char(qualifiedName)));
            catch
                tf = false;
            end
        end

        function hits = elementsWithStereotype(testCase, stereotypeShortName)
            hits = strings(1,0);
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
            hits = strings(1,0);
            elems = testCase.allElements();
            for i = 1:numel(elems)
                applied = reshape(string(getStereotypes(elems{i})), 1, []);
                for j = 1:numel(applied)
                    for k = 1:numel(propertyShortNames)
                        qualified = applied(j) + "." + propertyShortNames(k);
                        if testCase.elementHasProperty(elems{i}, qualified)
                            hits(end+1) = string(elems{i}.Name) + "." + qualified; %#ok<AGROW>
                        end
                    end
                end
            end
        end

        function profs = logicalProfiles(testCase)
            % Profiles applied to the L model. model.Profiles is the primary
            % source; the fallbacks cover a session where the .xml has not
            % been pulled in yet. An empty result is left empty on purpose --
            % the caller asserts non-empty so the profile checks can never
            % pass vacuously.
            profs = testCase.Model.Profiles;
            if ~isempty(profs); return; end
            try
                profs = systemcomposer.profile.Profile.find(testCase.Profile);
            catch
                try
                    profs = systemcomposer.profile.Profile.load(testCase.Profile);
                catch
                    profs = [];
                end
            end
        end

        function names = profileStereotypeNames(testCase)
            names = strings(1,0);
            profs = testCase.logicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    names(end+1) = testCase.shortName(string(stereotypes(j).Name)); %#ok<AGROW>
                end
            end
            names = unique(names);
        end

        function names = declaredPropertyNames(testCase)
            % Every property DECLARED by every stereotype of every profile the
            % L model applies -- independent of whether anything applies it.
            names = strings(1,0);
            profs = testCase.logicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        names(end+1) = testCase.shortName(string(props(k).Name)); %#ok<AGROW>
                    end
                end
            end
            names = unique(names);
        end

        function hits = kindsMissingStereotype(testCase, stereotypeShortName)
            hits = strings(1,0);
            kinds = testCase.kindElements();
            for i = 1:numel(kinds)
                if ~ismember(stereotypeShortName, testCase.appliedStereotypes(kinds{i}))
                    hits(end+1) = string(kinds{i}.Name); %#ok<AGROW>
                end
            end
        end

        function hits = kindsMissingProperty(testCase, propertyShortNames)
            hits = strings(1,0);
            kinds = testCase.kindElements();
            qualifier = testCase.Profile + "." + testCase.OptionStereotype + ".";
            for i = 1:numel(kinds)
                for k = 1:numel(propertyShortNames)
                    if ~testCase.elementHasProperty(kinds{i}, qualifier + propertyShortNames(k))
                        hits(end+1) = string(kinds{i}.Name) + "." + propertyShortNames(k); %#ok<AGROW>
                    end
                end
            end
        end

        function hits = kindsWithUnreadableProperty(testCase, propertyShortNames)
            % "Readable" = getProperty returns without error, and returns
            % something a caller can use. The VALUE is deliberately not
            % constrained: Selected is false before the physical trade runs
            % and true on one kind per role afterwards, and getProperty may
            % hand back either the property text or an evaluated value.
            hits = strings(1,0);
            kinds = testCase.kindElements();
            qualifier = testCase.Profile + "." + testCase.OptionStereotype + ".";
            for i = 1:numel(kinds)
                for k = 1:numel(propertyShortNames)
                    try
                        v  = getProperty(kinds{i}, char(qualifier + propertyShortNames(k)));
                        ok = ischar(v) || isstring(v) || islogical(v) || isnumeric(v);
                    catch
                        ok = false;
                    end
                    if ~ok
                        hits(end+1) = string(kinds{i}.Name) + "." + propertyShortNames(k); %#ok<AGROW>
                    end
                end
            end
        end

        function s = optionText(testCase, elem, propertyShortName)
            % One SolutionOption property as plain text. A string property
            % stores its value as a MATLAB EXPRESSION, so DefaultValue="'TBD'"
            % reads back as 'TBD' WITH the quotes (Stage-0 finding 7) and they
            % have to be stripped. "" when the property cannot be read, which
            % fails whatever comparison it feeds rather than propagating
            % <missing> through logical indexing.
            qualified = testCase.Profile + "." + testCase.OptionStereotype + "." + ...
                propertyShortName;
            try
                s = strtrim(erase(string(getProperty(elem, char(qualified))), "'"));
            catch
                s = "";
            end
            if ~isscalar(s) || ismissing(s); s = ""; end
        end

        function tf = isSelected(testCase, elem)
            % SolutionOption.Selected as a logical. Read through optionText so
            % it copes with the value arriving as a logical, as "true"/"false"
            % or as a quoted expression, without caring which.
            tf = ismember(lower(testCase.optionText(elem, "Selected")), ["true","1"]);
        end

        function names = namesOf(~, comps)
            names = strings(1,0);
            for i = 1:numel(comps)
                names(end+1) = string(comps(i).Name);   %#ok<AGROW>
            end
        end

        function d = selectionConsistencyDefects(testCase)
            % One pass per variant role, branching on whether that role has
            % been decided. BOTH branches are legitimate -- see the test's
            % comment -- so this collects the ways each state can be
            % internally inconsistent rather than requiring either one.
            d.MultipleSelected       = strings(1,0);
            d.NotActive              = strings(1,0);
            d.BadDecisionRef         = strings(1,0);
            d.UndecidedButReferenced = strings(1,0);
            d.DuplicateDecisionRef   = strings(1,0);
            cited = strings(1,0);   % DecisionRefs claimed by a decided role
            for role = string(fieldnames(testCase.Kinds))'
                vc = testCase.Model.lookup(Path=char(testCase.Root + role));
                choices = getChoices(vc);
                names   = testCase.namesOf(choices);
                picked  = false(1, numel(choices));
                refs    = strings(1, numel(choices));
                for i = 1:numel(choices)
                    picked(i) = testCase.isSelected(choices(i));
                    refs(i)   = testCase.optionText(choices(i), "DecisionRef");
                end
                if sum(picked) == 0
                    stray = names(refs ~= testCase.UndecidedRef);
                    for s = stray
                        d.UndecidedButReferenced(end+1) = role + "/" + s + " -> '" + ...
                            refs(names == s) + "'";
                    end
                    continue
                end
                if sum(picked) > 1
                    d.MultipleSelected(end+1) = role + " -> {" + ...
                        strjoin(names(picked), ", ") + "}";
                    continue
                end
                won    = names(picked);
                ref    = refs(picked);
                active = getActiveChoice(vc);
                if numel(active) ~= 1
                    d.NotActive(end+1) = role + " has " + numel(active) + ...
                        " active kinds, so nothing can agree with it";
                elseif string(active.Name) ~= won
                    d.NotActive(end+1) = role + ": Selected='" + won + ...
                        "' but the active kind is '" + string(active.Name) + "'";
                end
                if isempty(regexp(ref, testCase.DecisionRefPattern, "once"))
                    d.BadDecisionRef(end+1) = role + "/" + won + " -> '" + ref + "'";
                    continue
                end
                if ismember(ref, cited)
                    d.DuplicateDecisionRef(end+1) = role + "/" + won + " -> '" + ...
                        ref + "' (already cited by another role)";
                end
                cited(end+1) = ref;   %#ok<AGROW>
            end
        end

        function hits = vendorTokenHits(testCase, names)
            % Case-sensitive on purpose -- see the VendorTokens comment.
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
