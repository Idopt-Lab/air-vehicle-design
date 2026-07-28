classdef F16APhysicalArchitectureTest < matlab.unittest.TestCase
    %F16APHYSICALARCHITECTURETEST Verify the F-16A Physical-layer model (RFLP "P").
    %   A MACHINERY test: it asks "is the P model built correctly?", never
    %   "is this the right design?". The design verdicts live one per
    %   requirement in verification/.
    %
    %   COVERED HERE
    %     * Structure   -- 23 components: Aircraft, 11 assemblies, 8 parts,
    %       3 fuel tanks, each resolving at its expected path, the 9 leaf
    %       assemblies childless.
    %     * Stereotypes -- PhysicalItem on Aircraft and all 19 descendants,
    %       Material on every airframe part, FuelTank on every tank.
    %     * Masses      -- the 16 mass-bearing leaves against the Brandt
    %       ground truth; FuelSystem and the tanks carry zero OEW mass
    %       because fuel is a consumable.
    %     * Roll-up     -- self-consistency only: each assembly subtotal is
    %       the sum of its parts, OEW is the sum of all leaves, and
    %       airframe-less-engine is OEW minus engine.
    %     * Measures of Merit -- OEW and unit cost both exist with
    %       Goal = Minimize; cost is the uncomputed placeholder (NaN).
    %     * Realization -- the L->P allocation set exists, every one of the
    %       9 logical roles is a realization source, and the four
    %       supporting-infrastructure parts are deliberately not targets.
    %     * Requirements -- 022, 026 and P01 are Implement-linked at P.
    %     * Rationale (Stage 2) -- every part the architecture walk reaches
    %       carries the Rationale stereotype with a SourceKind drawn from
    %       the closed F16ASourceKind vocabulary, a non-empty TraceRef and a
    %       Justification of real length; the four infrastructure parts say
    %       SupportingInfrastructure explicitly; and both vocabularies are
    %       real MATLAB enumerations rather than free strings (D-006, D-007,
    %       D-011).
    %     * TradeCandidate (Stage 2) -- DECLARED in the profile with its
    %       eight properties, so the Stage-3 generator cannot quietly invent
    %       a different parameter set.
    %
    %   NOT COVERED HERE -- and why
    %     * Any weight or cost TARGET. OEW and unit cost are objectives to
    %       minimize, not thresholds, so a pass/fail budget here would be a
    %       design verdict smuggled into a machinery test.
    %     * Whether TradeCandidate is APPLIED anywhere. Nothing carries it
    %       until Stage 3 creates the candidates, and asserting an empty
    %       application set now would just have to be deleted later.
    %     * The variant ROLE wrappers. A stereotype cannot be applied to a
    %       systemcomposer.arch.VariantComponent at all (D-013), so "every
    %       part has a Rationale" means every part that can carry one; the
    %       wrapper's justification lives in its candidates.
    %     * The "Verified by" links. Those are added by hand in the
    %       Requirements Editor (see README); the "is it met?" answer is the
    %       matching suite in verification/.
    %
    %   R2026a APIs exercised here, each isolated in one helper below so a
    %   signature fix touches one place:
    %     * Walk        -- a VariantComponent's .Architecture.Components
    %       returns 0 on a LOADED model (Stage-0 finding 6), so every
    %       traversal in this file goes through getChoices. The walk asserts
    %       its own component count, because a walk that silently visits
    %       nothing would make every per-part check pass vacuously.
    %     * Stereotypes -- getStereotypes returns a cell array of
    %       '<profile>.<stereotype>'; getProperty takes
    %       "<profile>.<stereotype>.<property>" and hands ENUMERATION and
    %       STRING values back QUOTED (Stage-0 findings 1 and 7), so they
    %       are read with erase(..., "'").
    %     * Profiles    -- model.Profiles -> Profile.Stereotypes ->
    %       Stereotype.Properties(k).Name/.Type, so the vocabulary is
    %       checked in the PROFILE, before and regardless of what applies it.
    %     * Enumerations -- meta.class.fromName(...).EnumerationMemberList,
    %       which is empty when the classdef is not on the path.

    properties
        Model      % F16A_Physical
        LogiModel  % F16A_Logical (realization source)
        OrigSet    % f16a.slreqx (REQ_F16A_022 materials, REQ_F16A_026 cost MoM)
        PhysSet    % f16a_physical_derived.slreqx (REQ_F16A_P01 fuel volume)
        Alloc      % F16A_LogicalToPhysical allocation set
        Profile = "F16A_PhysicalProps";
        AC      = "F16A_Physical/Aircraft/";
    end

    properties (Constant)
        Assemblies = ["Airframe","Propulsion","LandingGear","FuelSystem", ...
            "FlightControls","Avionics","Electrical","Hydraulics","ECS", ...
            "ArmamentSupport","SecondaryStructure"];
        AirframeParts   = ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"];
        PropulsionParts = ["Engine","InletDuct"];
        FuelTanks       = ["FwdFuselageTank","AftFuselageTank","WingTank"];
        LogicalRoles = ["Airframe","PropulsionSystem","FuelSystem", ...
            "FlightControlSystem","LandingGear","AvionicsSuite", ...
            "CommunicationSystem","WeaponSystem","MissionSystemsBay"];
        % Parts that realize NO single logical role (supporting infrastructure).
        UnrealizedParts = ["Electrical","Hydraulics","ECS","SecondaryStructure"];
        % Ground-truth mass-bearing leaves {relative path, lbf}. FuelSystem
        % (0 lbf) is intentionally excluded and checked separately.
        MassRows = { ...
            "Airframe/Wing",1785.95;  "Airframe/Fuselage",3652.11; ...
            "Airframe/HorizontalTail",648.00; "Airframe/VerticalTail",360.00; ...
            "Airframe/Nacelles",186.82; "Airframe/Strakes",90.00; ...
            "Propulsion/Engine",4730.23; "Propulsion/InletDuct",728.60; ...
            "LandingGear",1066.82; "FlightControls",472.44; "Avionics",2541.54; ...
            "Electrical",533.41; "Hydraulics",367.11; "ECS",360.84; ...
            "ArmamentSupport",440.00; "SecondaryStructure",2016.86};

        % --- Stage 2: rationale and the trade vocabulary -----------------
        % How many components the architecture-side walk must reach. Stage 2
        % is purely additive, so it is still 23; Stage 3's variant choices
        % raise it. Asserted so a walk that silently skips a subtree (the
        % classic getChoices trap) fails loudly instead of passing empty.
        ExpectedComponentCount = 23;
        RationaleStereotype = "Rationale";
        % A rationale that reads "engine" is not a rationale. 20 characters
        % is a floor on effort, not a style rule -- it is deliberately far
        % below the length of any honest justification.
        MinJustificationLength = 20;
        SourceKindClass   = "F16ASourceKind";
        SourceKindMembers = ["ConstraintDriven","RealizesFunction", ...
            "SatisfiesRequirement","SupportingInfrastructure", ...
            "TradeAlternative","TradeWinner"];
        DataProvenanceClass   = "F16ADataProvenance";
        DataProvenanceMembers = ["Datasheet","Estimate","Reference","Simulation"];
        % Declared at Stage 2, applied at Stage 3.
        CandidateStereotype = "TradeCandidate";
        CandidateProperties = ["Benefit","DataProvenance","Mass_lb", ...
            "RealizesKind","RealizesRole","Selected","TRL","UnitCost_USD"];
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
            addpath(thisDir);
            addpath(fullfile(thisDir, "physical"));
            addpath(fullfile(thisDir, "logical"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            try, systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Physical");
            testCase.LogiModel = systemcomposer.loadModel("F16A_Logical");
            testCase.OrigSet   = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.PhysSet   = slreq.load(fullfile(thisDir, "requirements", "f16a_physical_derived.slreqx"));
            testCase.Alloc     = systemcomposer.allocation.load("F16A_LogicalToPhysical");
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testPhysicalComponentsExist(testCase)
            % 23 components; root holds one Aircraft; Aircraft holds 11
            % assemblies; Airframe 6 parts, Propulsion 2, FuelSystem 3 tanks.
            testCase.verifyEqual(testCase.countComps(), testCase.ExpectedComponentCount, ...
                "Expected 23 components (Aircraft + 11 assemblies + 8 parts + 3 tanks).");
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 1, ...
                "Root should hold exactly one component (Aircraft).");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyEqual(numel(ac.Architecture.Components), 11, ...
                "Aircraft should hold 11 assemblies.");
            af = testCase.Model.lookup(Path=char(testCase.AC + "Airframe"));
            testCase.verifyEqual(numel(af.Architecture.Components), 6, "Airframe should have 6 parts.");
            pr = testCase.Model.lookup(Path=char(testCase.AC + "Propulsion"));
            testCase.verifyEqual(numel(pr.Architecture.Components), 2, "Propulsion should have 2 parts.");
            fs = testCase.Model.lookup(Path=char(testCase.AC + "FuelSystem"));
            testCase.verifyEqual(numel(fs.Architecture.Components), 3, "FuelSystem should have 3 tanks.");
        end

        function testHierarchyCorrect(testCase)
            % Every assembly resolves under Aircraft; Airframe/Propulsion
            % parts resolve under their parent; the 9 leaf assemblies are
            % childless.
            for a = testCase.Assemblies
                testCase.verifyTrue(testCase.resolves(testCase.AC + a), "Missing assembly: " + a);
            end
            for p = testCase.AirframeParts
                testCase.verifyTrue(testCase.resolves(testCase.AC + "Airframe/" + p), "Missing Airframe part: " + p);
            end
            for p = testCase.PropulsionParts
                testCase.verifyTrue(testCase.resolves(testCase.AC + "Propulsion/" + p), "Missing Propulsion part: " + p);
            end
            for t = testCase.FuelTanks
                testCase.verifyTrue(testCase.resolves(testCase.AC + "FuelSystem/" + t), "Missing fuel tank: " + t);
            end
            leafAsm = setdiff(testCase.Assemblies, ["Airframe","Propulsion","FuelSystem"]);
            for a = leafAsm
                c = testCase.Model.lookup(Path=char(testCase.AC + a));
                testCase.verifyEmpty(c.Architecture.Components, a + " should be a leaf.");
            end
        end

        function testPhysicalItemStereotypeApplied(testCase)
            % Aircraft and every one of its 19 descendants carry PhysicalItem.
            paths = "F16A_Physical/Aircraft";
            paths = [paths, testCase.AC + testCase.Assemblies];
            paths = [paths, testCase.AC + "Airframe/" + testCase.AirframeParts];
            paths = [paths, testCase.AC + "Propulsion/" + testCase.PropulsionParts];
            paths = [paths, testCase.AC + "FuelSystem/" + testCase.FuelTanks];
            for pth = paths
                c = testCase.Model.lookup(Path=char(pth));
                sters = string(c.getStereotypes());
                testCase.verifyTrue(any(contains(sters, "PhysicalItem")), ...
                    "PhysicalItem not applied to " + pth);
            end
        end

        function testLeafMassesMatchGroundTruth(testCase)
            % The 16 mass-bearing leaves match the Brandt ground truth; the
            % FuelSystem leaf is zero (fuel is a consumable, not empty weight).
            for i = 1:size(testCase.MassRows,1)
                rel = string(testCase.MassRows{i,1});
                exp = testCase.MassRows{i,2};
                c = testCase.Model.lookup(Path=char(testCase.AC + rel));
                v = str2double(string(getProperty(c, testCase.Profile + ".PhysicalItem.Mass_lb")));
                testCase.verifyEqual(v, exp, "AbsTol", 0.01, rel + " mass mismatch.");
                testCase.verifyGreaterThan(v, 0, rel + " should be a mass-bearing leaf.");
            end
            fs = testCase.Model.lookup(Path=char(testCase.AC + "FuelSystem"));
            vfs = str2double(string(getProperty(fs, testCase.Profile + ".PhysicalItem.Mass_lb")));
            testCase.verifyEqual(vfs, 0, "AbsTol", 1e-9, "FuelSystem should carry zero OEW mass.");
        end

        function testAirframeCompositeFractionsSet(testCase)
            % Every airframe part carries a Material stereotype with a
            % CompositeFraction in [0,1]; at least the tails are composite-heavy.
            for p = testCase.AirframeParts
                c = testCase.Model.lookup(Path=char(testCase.AC + "Airframe/" + p));
                testCase.verifyTrue(any(contains(string(c.getStereotypes()), "Material")), ...
                    "Material stereotype not applied to " + p);
                cf = str2double(string(getProperty(c, testCase.Profile + ".Material.CompositeFraction")));
                testCase.verifyGreaterThanOrEqual(cf, 0, p + " CompositeFraction < 0.");
                testCase.verifyLessThanOrEqual(cf, 1, p + " CompositeFraction > 1.");
            end
            vt = testCase.Model.lookup(Path=char(testCase.AC + "Airframe/VerticalTail"));
            cfvt = str2double(string(getProperty(vt, testCase.Profile + ".Material.CompositeFraction")));
            testCase.verifyGreaterThan(cfvt, 0.3, "VerticalTail should be composite-heavy (graphite skins).");
        end

        function testFuelTankCapacities(testCase)
            % Each fuel tank carries a FuelTank stereotype with a positive
            % capacity and zero dry (OEW) mass; total ~ 6300 lb.
            total = 0;
            for t = testCase.FuelTanks
                c = testCase.Model.lookup(Path=char(testCase.AC + "FuelSystem/" + t));
                testCase.verifyTrue(any(contains(string(c.getStereotypes()), "FuelTank")), ...
                    "FuelTank stereotype not applied to " + t);
                cap = str2double(string(getProperty(c, testCase.Profile + ".FuelTank.FuelCapacity_lb")));
                testCase.verifyGreaterThan(cap, 0, t + " should have positive fuel capacity.");
                mass = str2double(string(getProperty(c, testCase.Profile + ".PhysicalItem.Mass_lb")));
                testCase.verifyEqual(mass, 0, "AbsTol", 1e-9, t + " dry mass should be 0 (fuel is a consumable).");
                total = total + cap;
            end
            testCase.verifyGreaterThanOrEqual(total, 6000, "Total internal fuel capacity looks too low.");
        end

        function testMassRollupSelfConsistent(testCase)
            % The roll-up is internally consistent: each assembly subtotal is
            % the sum of its parts and OEW is the sum of all leaves. This
            % checks the traversal, NOT any weight target/budget.
            r = F16APhysicalMassRollup();
            expAirframe   = testCase.sumMasses(testCase.AC + "Airframe/" + testCase.AirframeParts);
            expPropulsion = testCase.sumMasses(testCase.AC + "Propulsion/" + testCase.PropulsionParts);
            expOEW        = sum([testCase.MassRows{:,2}]);   % all mass-bearing leaves
            testCase.verifyEqual(r.Airframe,   expAirframe,   "AbsTol", 0.01, "Airframe subtotal != sum of parts.");
            testCase.verifyEqual(r.Propulsion, expPropulsion, "AbsTol", 0.01, "Propulsion subtotal != sum of parts.");
            testCase.verifyEqual(r.OEW,        expOEW,        "AbsTol", 0.05, "OEW != sum of leaf masses.");
            testCase.verifyEqual(r.AirframeLessEngine, r.OEW - r.Engine, "AbsTol", 1e-6, ...
                "Airframe-less-engine must equal OEW - Engine.");
        end

        function testOEWMeasureOfMerit(testCase)
            % The Aircraft carries a MeasureOfMerit with Goal=Minimize, and
            % OEW_lb holds the rolled-up empty weight.
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyTrue(any(contains(string(ac.getStereotypes()), "MeasureOfMerit")), ...
                "MeasureOfMerit not applied to Aircraft.");
            % String stereotype properties store the value as a quoted MATLAB
            % expression, so strip the surrounding quotes before comparing.
            goal = erase(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.Goal")), "'");
            testCase.verifyEqual(goal, "Minimize", "OEW MoM Goal should be Minimize.");
            oew = str2double(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.OEW_lb")));
            testCase.verifyEqual(oew, sum([testCase.MassRows{:,2}]), "AbsTol", 0.05, ...
                "OEW MoM value should equal the mass roll-up.");
        end

        function testCostMeasureOfMerit(testCase)
            % Unit cost is the OTHER MoM (minimize), sourced from a cost-model
            % FUNCTION (not a roll-up). The stub leaves it uncomputed (NaN);
            % we assert the hook exists and the value is the placeholder, NOT
            % any cost number.
            testCase.verifyEqual(exist("F16APhysicalCostModel", "file"), 2, ...
                "Cost-model hook F16APhysicalCostModel is missing.");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            cost = str2double(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.UnitCost_USD")));
            testCase.verifyTrue(isnan(cost), ...
                "Cost MoM should be the uncomputed placeholder (NaN) pending a cost model.");
        end

        function testRealizationAllocationExists(testCase)
            scenario = testCase.Alloc.getScenario("Scenario 1");
            testCase.verifyNotEmpty(scenario, "Missing realization allocation scenario.");
        end

        function testRealizationCoversAllLogicalRoles(testCase)
            % Every one of the 9 logical roles is a realization source; the
            % Airframe role fans out to its 6 structural parts.
            [srcCounts, ~] = testCase.allocEndpoints();
            missing = setdiff(testCase.LogicalRoles, string(keys(srcCounts)));
            testCase.verifyEmpty(missing, "Logical roles not realized: " + strjoin(missing, ", "));
            testCase.verifyGreaterThanOrEqual(srcCounts("Airframe"), 6, ...
                "Airframe should realize to >= 6 parts.");
        end

        function testUnrealizedInfrastructureParts(testCase)
            % Electrical, Hydraulics, ECS, SecondaryStructure realize no single
            % logical role -- the symmetric echo of L's constraint-driven roles.
            [~, dstNames] = testCase.allocEndpoints();
            offenders = intersect(testCase.UnrealizedParts, dstNames);
            testCase.verifyEmpty(offenders, ...
                "These parts should realize no logical role: " + strjoin(offenders, ", "));
        end

        function testCostMoMHomedAtPhysical(testCase)
            % REQ_F16A_026 is reclassified as a Measure of Merit (keywords) and
            % is now Implement-linked from the Physical layer (Aircraft).
            req = find(testCase.OrigSet, Id="REQ_F16A_026");
            testCase.verifyNotEmpty(req, "REQ_F16A_026 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_026 should be homed (linked) at P.");
            testCase.verifyTrue(any(string(req.Keywords) == "minimize"), ...
                "REQ_F16A_026 should be marked a Measure of Merit (keyword 'minimize').");
        end

        function testMaterialsRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_022 from the
            % Airframe. The "Verified by" link (to F16AMaterialsVerificationTest)
            % is added MANUALLY in the Requirements Editor (see README), so it is
            % deliberately NOT asserted here -- the actual "is it met?" check is
            % F16AMaterialsVerificationTest.
            req = find(testCase.OrigSet, Id="REQ_F16A_022");
            testCase.verifyNotEmpty(req, "REQ_F16A_022 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_022 should be Implement-linked at P.");
        end

        function testFuelRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_P01 from the
            % FuelSystem. Its "Verified by" link (F16AFuelVerificationTest) is
            % added manually (see README) and is not asserted here.
            req = find(testCase.PhysSet, Id="REQ_F16A_P01");
            testCase.verifyNotEmpty(req, "REQ_F16A_P01 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_P01 should be Implement-linked at P.");
        end

        % ---------------- Stage 2: rationale and trade vocabulary --------

        function testEveryPartHasRationale(testCase)
            % "Why does this part exist?" must be answerable by QUERYING the
            % model, not by reading a code comment (D-006). The part list is
            % DISCOVERED by walking the architecture rather than hard-coded,
            % so Stage 3's candidates are covered the day they appear -- and
            % because a walk that silently visits nothing would make every
            % check below pass vacuously, the walk asserts its own size
            % first (Stage-0 finding 6).
            [~, walked] = testCase.walkComponents();
            testCase.verifyEqual(numel(walked), testCase.ExpectedComponentCount, ...
                "The architecture walk reached " + numel(walked) + " components, expected " + ...
                testCase.ExpectedComponentCount + ". A walk that skips a variant's choices " + ...
                "reports too few and makes every per-part assertion vacuous.");
            [parts, ~] = testCase.stereotypableParts();
            testCase.verifyNotEmpty(parts, ...
                "No stereotype-bearing part found -- the rationale checks would pass vacuously.");
            d = testCase.rationaleDefects();
            testCase.verifyEmpty(d.Missing, ...
                "No " + testCase.RationaleStereotype + " stereotype on: " + ...
                strjoin(d.Missing, ", ") + ".");
            testCase.verifyEmpty(d.BadKind, ...
                "SourceKind outside the " + testCase.SourceKindClass + " vocabulary on: " + ...
                strjoin(d.BadKind, ", ") + ".");
            testCase.verifyEmpty(d.EmptyTrace, ...
                "Empty TraceRef -- a rationale that traces to nothing is not traceable: " + ...
                strjoin(d.EmptyTrace, ", ") + ".");
            testCase.verifyEmpty(d.ThinJustification, ...
                "Justification shorter than " + testCase.MinJustificationLength + ...
                " characters (a part name is not a justification): " + ...
                strjoin(d.ThinJustification, ", ") + ".");
        end

        function testInfrastructurePartsAreSupportingInfrastructure(testCase)
            % The executable half of the claim in docs/05_physical.md that
            % some parts are born of the physics of building an airplane,
            % not of a role above them. testUnrealizedInfrastructureParts
            % says these four realize no logical role; this says the model
            % states WHY. The pair is the point: a part with no realization
            % AND no stated reason is just an unexplained box.
            offenders = testCase.partsWithSourceKindOtherThan( ...
                testCase.UnrealizedParts, "SupportingInfrastructure");
            testCase.verifyEmpty(offenders, ...
                "Expected SourceKind = SupportingInfrastructure on: " + ...
                strjoin(offenders, ", ") + ".");
        end

        function testRationaleVocabularyIsClosed(testCase)
            % The two vocabularies are real MATLAB enumerations, not free
            % strings (D-011). This is what stops the vocabulary drifting:
            % with a string property "SuportingInfrastructure" is a valid
            % value, and every downstream query quietly misses that part.
            % Checked in the PROFILE, so it holds even before Stage 3
            % applies TradeCandidate to anything.
            testCase.verifyNotEmpty(testCase.physicalProfiles(), ...
                "No profile resolved for the P model -- expected " + testCase.Profile + ".");
            testCase.verifyEqual( ...
                testCase.declaredPropertyType(testCase.RationaleStereotype, "SourceKind"), ...
                testCase.SourceKindClass, ...
                testCase.RationaleStereotype + ".SourceKind must be typed " + ...
                testCase.SourceKindClass + ", not a free string.");
            testCase.verifyEqual( ...
                testCase.declaredPropertyType(testCase.CandidateStereotype, "DataProvenance"), ...
                testCase.DataProvenanceClass, ...
                testCase.CandidateStereotype + ".DataProvenance must be typed " + ...
                testCase.DataProvenanceClass + ", not a free string.");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.SourceKindClass), ...
                sort(testCase.SourceKindMembers), ...
                testCase.SourceKindClass + " must resolve on the path with exactly the six " + ...
                "agreed members (D-006).");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.DataProvenanceClass), ...
                sort(testCase.DataProvenanceMembers), ...
                testCase.DataProvenanceClass + " must resolve on the path with exactly the four " + ...
                "agreed members (D-007).");
        end

        function testTradeCandidateStereotypeDeclared(testCase)
            % Stage 2 DECLARES the trade vocabulary; Stage 3 populates it.
            % Fixing the eight property names now means the Stage-3
            % generator cannot quietly invent a different parameter set, and
            % the profile is reviewable before any candidate exists.
            % Deliberately NOT asserted: that anything CARRIES the
            % stereotype. Nothing does yet, and that is correct.
            declared = testCase.profileStereotypeNames();
            testCase.verifyTrue(ismember(testCase.CandidateStereotype, declared), ...
                "The P profile must declare " + testCase.CandidateStereotype + ...
                ", but declares: " + strjoin(declared, ", ") + ".");
            missing = setdiff(testCase.CandidateProperties, ...
                testCase.stereotypePropertyNames(testCase.CandidateStereotype));
            testCase.verifyEmpty(missing, ...
                testCase.CandidateStereotype + " must declare all eight trade properties; " + ...
                "missing: " + strjoin(missing, ", ") + ".");
        end

    end

    % =====================================================================
    % Helpers. All model/profile traversal lives here so the test methods
    % above stay Arrange-Act-Assert and every R2026a API call sits in
    % exactly one place.
    % =====================================================================
    methods (Access = private)

        function tf = resolves(testCase, pth)
            tf = true;
            try, testCase.Model.lookup(Path=char(pth)); catch, tf = false; end
        end

        function s = shortName(~, qualified)
            % Last token of "<profile>.<stereotype>.<property>" (or of a bare
            % name, which is returned unchanged).
            parts = split(string(qualified), ".");
            s = parts(end);
        end

        function n = countComps(testCase)
            % Total components reached by the architecture-side walk.
            % Delegates to walkComponents so there is exactly ONE traversal
            % in this file and no naive .Architecture.Components recursion
            % left to go stale when Stage 3 adds variant components.
            [comps, ~] = testCase.walkComponents();
            n = numel(comps);
        end

        function [comps, paths] = walkComponents(testCase)
            % Every component of the P model, as a cell array (Component and
            % VariantComponent are different classes) plus a parallel array
            % of slash-separated walk paths for failure messages. Variant
            % ROLE wrappers are included in the walk; use
            % stereotypableParts to drop them.
            [comps, paths] = testCase.descend(testCase.Model.Architecture, "");
        end

        function [comps, paths] = descend(testCase, arch, prefix)
            comps = {};
            paths = strings(1,0);
            for c = arch.Components
                here = prefix + string(c.Name);
                comps{end+1} = c;      %#ok<AGROW>
                paths(end+1) = here;   %#ok<AGROW>
                [sub, subPaths] = testCase.descendInto(c, here + "/");
                comps = [comps, sub];        %#ok<AGROW>
                paths = [paths, subPaths];   %#ok<AGROW>
            end
        end

        function [comps, paths] = descendInto(testCase, comp, prefix)
            % The one place that knows about variants. A VariantComponent's
            % .Architecture.Components returned its choices on a freshly
            % built in-memory model but ZERO on the same model saved and
            % reloaded (Stage-0 finding 6), so getChoices is the only
            % reliable accessor -- a plain recursion would silently skip
            % every candidate here and report a smaller component count.
            if isa(comp, "systemcomposer.arch.VariantComponent")
                comps = {};
                paths = strings(1,0);
                choices = getChoices(comp);
                for i = 1:numel(choices)
                    here = prefix + string(choices(i).Name);
                    comps{end+1} = choices(i);   %#ok<AGROW>
                    paths(end+1) = here;         %#ok<AGROW>
                    [sub, subPaths] = testCase.descend(choices(i).Architecture, here + "/");
                    comps = [comps, sub];        %#ok<AGROW>
                    paths = [paths, subPaths];   %#ok<AGROW>
                end
            else
                [comps, paths] = testCase.descend(comp.Architecture, prefix);
            end
        end

        function [parts, paths] = stereotypableParts(testCase)
            % The walk MINUS the variant role wrappers, which cannot carry a
            % stereotype at all (D-013 / Stage-0 finding 4). "Every part has
            % a rationale" means every part that can hold one.
            [comps, allPaths] = testCase.walkComponents();
            keep = false(1, numel(comps));
            for i = 1:numel(comps)
                keep(i) = ~isa(comps{i}, "systemcomposer.arch.VariantComponent");
            end
            parts = comps(keep);
            paths = allPaths(keep);
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

        function txt = rationaleText(testCase, elem, propertyShortName)
            % One Rationale property as plain text. BOTH the enumeration
            % (SourceKind) and the string properties come back QUOTED --
            % getProperty stores and returns a MATLAB expression, so
            % F16ASourceKind.TradeWinner reads back as 'TradeWinner' and
            % "REQ_F16A_026" as 'REQ_F16A_026' (Stage-0 findings 1 and 7).
            % Returns "" when the property cannot be read at all, which
            % every caller reports as a defect rather than swallowing.
            qualified = testCase.Profile + "." + testCase.RationaleStereotype + "." + ...
                propertyShortName;
            try
                raw = string(getProperty(elem, char(qualified)));
            catch
                txt = "";
                return
            end
            txt = strtrim(erase(raw, "'"));
        end

        function d = rationaleDefects(testCase)
            % One pass over every stereotypable part, collecting defects by
            % kind so a failure names the offenders instead of stopping at
            % the first one.
            d.Missing           = strings(1,0);
            d.BadKind           = strings(1,0);
            d.EmptyTrace        = strings(1,0);
            d.ThinJustification = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                where = paths(i);
                if ~ismember(testCase.RationaleStereotype, testCase.appliedStereotypes(parts{i}))
                    d.Missing(end+1) = where;
                    continue
                end
                kind = testCase.rationaleText(parts{i}, "SourceKind");
                if ~ismember(kind, testCase.SourceKindMembers)
                    d.BadKind(end+1) = where + " -> '" + kind + "'";
                end
                if strlength(testCase.rationaleText(parts{i}, "TraceRef")) == 0
                    d.EmptyTrace(end+1) = where;
                end
                just = testCase.rationaleText(parts{i}, "Justification");
                if strlength(just) < testCase.MinJustificationLength
                    d.ThinJustification(end+1) = where + " (" + strlength(just) + " chars)";
                end
            end
        end

        function hits = partsWithSourceKindOtherThan(testCase, partNames, expectedKind)
            % Named parts (direct children of Aircraft) whose SourceKind is
            % not the expected member. Reported with the value found, so the
            % failure says what the model actually claims.
            hits = strings(1,0);
            for nm = partNames
                found = true;
                try
                    c = testCase.Model.lookup(Path=char(testCase.AC + nm));
                catch
                    found = false;
                end
                if ~found
                    hits(end+1) = nm + " (not found)";   %#ok<AGROW>
                    continue
                end
                actual = testCase.rationaleText(c, "SourceKind");
                if actual ~= expectedKind
                    hits(end+1) = nm + " -> '" + actual + "'";   %#ok<AGROW>
                end
            end
        end

        function profs = physicalProfiles(testCase)
            % Profiles applied to the P model. model.Profiles is the primary
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
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    names(end+1) = testCase.shortName(string(stereotypes(j).Name));   %#ok<AGROW>
                end
            end
            names = unique(names);
        end

        function names = stereotypePropertyNames(testCase, stereotypeShortName)
            % Properties DECLARED by one stereotype of the P profile,
            % independent of whether any element applies it.
            names = strings(1,0);
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    if testCase.shortName(string(stereotypes(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        names(end+1) = testCase.shortName(string(props(k).Name));   %#ok<AGROW>
                    end
                end
            end
            names = unique(names);
        end

        function t = declaredPropertyType(testCase, stereotypeShortName, propertyShortName)
            % The declared TYPE of one stereotype property, "" when the
            % stereotype or the property is not declared at all -- either way
            % the caller's equality check fails with a readable message.
            t = "";
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    if testCase.shortName(string(stereotypes(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        if testCase.shortName(string(props(k).Name)) == propertyShortName
                            t = testCase.typeName(props(k).Type);
                            return
                        end
                    end
                end
            end
        end

        function n = typeName(testCase, rawType)
            % Property.Type is documented as a char vector / string naming
            % the type -- a built-in ("double", "string") or the name of a
            % MATLAB class that defines an enumeration. Normalised here so a
            % quoted or package-qualified spelling still compares equal, and
            % so a surprise object shape fails on the VALUE rather than
            % erroring out of the test.
            try
                s = string(rawType);
            catch
                s = string(class(rawType));
            end
            n = testCase.shortName(strtrim(erase(s, "'")));
        end

        function names = enumerationMembers(~, className)
            % Members of a MATLAB enumeration class, sorted. Empty when the
            % classdef does not resolve on the path -- which is itself the
            % failure the caller reports, since an unresolvable enumeration
            % means the property has no vocabulary to validate against.
            names = strings(1,0);
            mc = meta.class.fromName(char(className));
            if isempty(mc)
                return
            end
            members = mc.EnumerationMemberList;
            for i = 1:numel(members)
                names(end+1) = string(members(i).Name);   %#ok<AGROW>
            end
            names = sort(names);
        end

        function s = sumMasses(testCase, paths)
            s = 0;
            for pth = paths
                c = testCase.Model.lookup(Path=char(pth));
                s = s + str2double(string(getProperty(c, testCase.Profile + ".PhysicalItem.Mass_lb")));
            end
        end

        function [srcCounts, dstNames] = allocEndpoints(testCase)
            % Tally realization sources (logical roles) and collect the set of
            % destination part names.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            srcCounts = containers.Map();
            dstNames = string.empty;
            for a = scenario.Allocations
                s = char(a.Source.Name);
                if isKey(srcCounts, s); srcCounts(s) = srcCounts(s) + 1;
                else; srcCounts(s) = 1; end
                dstNames(end+1) = string(a.Target.Name); %#ok<AGROW>
            end
            dstNames = unique(dstNames);
        end
    end
end
