classdef F16APhysicalArchitectureTest < F16ATestCase
    %F16APHYSICALARCHITECTURETEST Verify the F-16A Physical model (RFLP "P").
    %   A MACHINERY suite: it asks "is the P model built correctly?", never "is
    %   this the right design?". Design verdicts live one per requirement in
    %   verification/.
    %
    %   Covers structure (30 components), stereotypes, the 16 active-leaf masses
    %   against the Brandt ground truth, roll-up self-consistency, the Measures
    %   of Merit, the L->P realization, the Implement links, the Rationale and
    %   DataProvenance every part carries, the 7 candidates' parameter contract,
    %   and the four places the trade records its verdict.
    %
    %   It asserts NO weight or cost target (those are objectives, not
    %   thresholds), no illustrative parameter VALUE or trade score (ranges and
    %   orderings instead), and nothing about variant role wrappers, which
    %   cannot carry a stereotype at all (D-013). Since D-056 each trade script
    %   carries its own guards inline, so this file pins the DATA they act on.
    %
    %   IT NEVER RUNS THE TRADE STUDY and calls the roll-ups with Persist=false:
    %   a test that mutated the artifact it checks would pass on a model the
    %   generator never wrote the decision into.
    %
    %   Shared helpers are in F16ATestCase.

    properties
        LogiModel  % F16A_Logical (realization source)
        OrigSet    % f16a.slreqx (022 materials, 026 cost MoM)
        PhysSet    % f16a_physical_derived.slreqx (P01 fuel volume)
        LogiSet    % f16a_logical_derived.slreqx (L01..L03 decisions)
        Alloc      % F16A_LogicalToPhysical allocation set
        BrandtWt   % BrandtWeight.run(W_TO_lb) -- the ground truth, executed
    end

    properties (TestParameter)
        % The 16 mass-bearing leaves of the ACTIVE configuration, each checked
        % as its own case so a failure names the part rather than the sweep.
        massLeaf = F16APhysicalArchitectureTest.massLeafTable();
    end

    properties (Constant)
        AC = "F16A_Physical/Aircraft/";
        Assemblies = ["Airframe","Propulsion","LandingGear","FuelSystem", ...
            "FlightControls","Avionics","Electrical","Hydraulics","ECS", ...
            "ArmamentSupport","SecondaryStructure"];
        AirframeParts   = ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"];
        % Propulsion's own children: the Engine VARIANT ROLE plus the inlet
        % duct, which stays a plain part shared by every candidate (D-009).
        PropulsionParts = ["Engine","InletDuct"];
        FuelTanks       = ["FwdFuselageTank","AftFuselageTank","WingTank"];
        LogicalRoles = ["Airframe","PropulsionSystem","FuelSystem", ...
            "FlightControlSystem","LandingGear","AvionicsSuite", ...
            "CommunicationSystem","WeaponSystem","MissionSystemsBay"];
        % Parts that realize NO single logical role (supporting infrastructure).
        UnrealizedParts = ["Electrical","Hydraulics","ECS","SecondaryStructure"];
        % The three candidates carrying Brandt ground truth. Named for WHAT
        % THEY ARE, not for "the active one": which candidate is active is read
        % from the model, never assumed here (D-003).
        BrandtAirframe       = "BlendedCrankedDelta";
        BrandtEngine         = "F100_PW_200";
        BrandtFlightControls = "FlyByWire";
        % Same table as massLeaf above, for the sweeps that need all 16 at once.
        MassLeafRows = F16APhysicalArchitectureTest.massLeafTable();

        % Brandt ground truth, asserted as NUMBERS because that is what they
        % are. OEW is unchanged by the variant restructure (D-003).
        ExpectedOEW_lb            = 19980.73;
        BrandtAirframeMass_lb     =  6722.88;
        ExpectedCompositeFraction =   0.1928;
        % The sizing point BrandtWeight.run is evaluated at (Wt!B3) -- the same
        % one F16AStaticMarginVerificationTest uses, stated rather than assumed.
        W_TO_lb                   = 31377;

        % 30 = the 23 of Stage 2 plus Stage 3's 7 variant choices. Asserted so
        % a walk that silently skips a subtree fails loudly instead of empty.
        ExpectedComponentCount = 30;
        RationaleStereotype = "Rationale";
        % A rationale that reads "engine" is not a rationale. A floor on effort,
        % deliberately far below any honest justification.
        MinJustificationLength = 20;
        SourceKindClass   = "F16ASourceKind";
        SourceKindMembers = ["ConstraintDriven","RealizesFunction", ...
            "SatisfiesRequirement","SupportingInfrastructure", ...
            "TradeAlternative","TradeWinner"];
        DataProvenanceClass   = "F16ADataProvenance";
        DataProvenanceMembers = ["Datasheet","Estimate","Reference","Simulation"];
        % ONE CANDIDATE STEREOTYPE PER TRADE (D-056): {logical role, stereotype,
        % the criterion that is that trade's OWN, every property it must
        % declare}. There is no RealizesRole -- the stereotype names the role,
        % which is what the Role column of candidateTable now reads. Fixing the
        % property names here means a later generator cannot quietly invent a
        % different parameter set for one of the three.
        CandidateStereotypes = { ...
            "Airframe",            "AirframeCandidate",      "AeroBenefit", ...
                ["AeroBenefit","DataProvenance","Mass_lb","RealizesKind","Selected","TRL"]; ...
            "PropulsionSystem",    "EngineCandidate",        "Thrust_SL_lb", ...
                ["DataProvenance","Mass_lb","RealizesKind","Selected","Thrust_SL_lb","TRL"]; ...
            "FlightControlSystem", "FlightControlCandidate", "HandlingBenefit", ...
                ["DataProvenance","HandlingBenefit","Mass_lb","RealizesKind","Selected","TRL"]};
        % The two trades whose own criterion is a 1..10 judgement. The engine
        % trade scores installed thrust instead, so the benefit sweeps below
        % must not be applied to it.
        BenefitScoredRoles = ["Airframe","FlightControlSystem"];

        % {variant path under Aircraft, logical role realized, #candidates}.
        % The variant components carry NO stereotype (D-013); what they own is
        % the choice, and that is what is asserted about them.
        VariantRows = { ...
            "Airframe",          "Airframe",            2; ...
            "Propulsion/Engine", "PropulsionSystem",    3; ...
            "FlightControls",    "FlightControlSystem", 2};
        % {candidate path, logical role, logical kind, expected DataProvenance}.
        % No mass, TRL or merit column: those are Estimates, so this file asserts
        % their range and ordering, never their values. Role and kind ARE exact
        % -- they are structural claims that must resolve in the L model.
        CandidateRows = { ...
            "Airframe/BlendedCrankedDelta",                "Airframe",            "BlendedCrankedDelta",  "Reference"; ...
            "Airframe/ConventionalTrapWing",               "Airframe",            "ConventionalTrapWing", "Estimate";  ...
            "Propulsion/Engine/F100_PW_200",               "PropulsionSystem",    "SingleEngine",         "Reference"; ...
            "Propulsion/Engine/LowThrustSingle_Surrogate", "PropulsionSystem",    "SingleEngine",         "Estimate";  ...
            "Propulsion/Engine/TwinEngine_Surrogate",      "PropulsionSystem",    "TwinEngine",           "Estimate";  ...
            "FlightControls/FlyByWire",                    "FlightControlSystem", "FlyByWire",            "Reference"; ...
            "FlightControls/HydroMechanical",              "FlightControlSystem", "HydroMechanical",      "Estimate"};
        % {engine path, sea-level static thrust, provenance}. Only one is a real
        % engine (D-053); the other two are declared hypotheticals. Since D-056
        % Thrust_SL_lb is the engine trade's OWN criterion, and no other
        % candidate stereotype declares it.
        EngineThrustRows = { ...
            "Propulsion/Engine/F100_PW_200",               23770, "Reference"; ...
            "Propulsion/Engine/LowThrustSingle_Surrogate", 18500, "Estimate";  ...
            "Propulsion/Engine/TwinEngine_Surrogate",      32000, "Estimate"};
        NonEngineCandidates = ["Airframe/BlendedCrankedDelta", ...
            "Airframe/ConventionalTrapWing", "FlightControls/FlyByWire", ...
            "FlightControls/HydroMechanical"];
        % The two hypothetical engines. Their Justification must name no real
        % manufacturer -- inventing a number and attaching it to a real product
        % is the defect this pair exists to keep out.
        SurrogateEngines = ["Propulsion/Engine/LowThrustSingle_Surrogate", ...
            "Propulsion/Engine/TwinEngine_Surrogate"];
        % The scales the three trade scripts check inline. Stated here as
        % literals since D-056 retired the shared guard class: a test that
        % imports the bound it is checking proves nothing about the bound.
        TRLScale     = [1 9];
        BenefitScale = [1 10];
        % Negative controls for both scales, judged by the SAME predicates the
        % candidate sweeps use -- so a scale quietly widened fails here.
        RejectedBenefits = [0, 78, 10.5, -1, NaN, Inf];
        AcceptedBenefits = [1, 7.8, 10];
        RejectedTRLs = [0, 10, 4.5, -1, NaN, Inf];
        AcceptedTRLs = [1, 6, 9];
        % D-015's ratio baseline: the role's Reference candidate. Exactly one
        % per role -- with none there is no scale, with two no answer.
        BaselineProvenance = "Reference";
        % How far above 1.0 a value function must land to count as exceeding
        % the ceiling its declared scale implies (D-035). Same literal the three
        % trade scripts use.
        ValueCeilingTol = 1e-9;
        % Both accepted so this survives Stage 4, when the trade promotes three
        % of the seven from TradeAlternative to TradeWinner.
        CandidateSourceKinds = ["TradeAlternative","TradeWinner"];
        % Every TraceRef must resolve in the set that OWNS it, not just
        % somewhere; routing is by id prefix.
        RequirementPrefix  = "REQ_F16A_";
        LogicalPathPrefix  = "F16A_Logical/";
        PhysicalPathPrefix = "F16A_Physical/";
        % Deliberately unresolvable, used as the negative control INSIDE
        % testTraceRefsResolve so a resolver that says yes to everything cannot
        % make that test pass vacuously. One per form, plus a bare token.
        BogusTraceRefs = ["REQ_F16A_999", "REQ_F16A_L99", "REQ_F16A_P99", ...
            "F16A_Logical/NoSuchRole", "F16A_Physical/Aircraft/NoSuchPart", ...
            "F16A_Physical/Aircraft/Airframe/NoSuchCandidate", "Wing"];
        % D-023: the 3 x 2100 lb split is an even division of Brandt's 6296.30
        % lb mission fuel -- an Estimate in substance, so it must say so.
        FuelTankProvenance = "Estimate";

        % The production F-16A: GROUND TRUTH about an aeroplane that was built,
        % so asserted as an IDENTITY -- unlike the scores that produce it.
        ExpectedWinners = ["BlendedCrankedDelta","F100_PW_200","FlyByWire"];
        WinnerSourceKind      = "TradeWinner";
        AlternativeSourceKind = "TradeAlternative";
        % A winner must CITE the score it won on. The PATTERN is asserted,
        % never the value (D-015). Anchored to "0." so a mass (4730.23), a
        % benefit (8.2) and a TRL (8) all fail to match.
        ScoreTokenPattern = "0\.\d\d+";
        % Implement-linked BY THE PHYSICAL TRADE STUDY, which is why this lives
        % here and not in the L suite (D-010).
        DecisionRequirements = ["REQ_F16A_L01","REQ_F16A_L02","REQ_F16A_L03"];
        ImplementLinkType    = "Implement";

        % FAIL-CLOSED: the check takes every stereotype the profile declares and
        % subtracts this list, so a stereotype added tomorrow is in the required
        % set the day it appears. Enumerating the other way passes by omission
        % forever -- which is how the Material gap survived five stages (D-031).
        % The two exemptions hold no chosen number: Rationale holds prose,
        % MeasureOfMerit holds two COMPUTED numbers (D-052).
        ProvenanceProperty          = "DataProvenance";
        ProvenanceExemptStereotypes = ["MeasureOfMerit","Rationale"];
        % Non-vacuity floor, asserted as a SUBSET of the computed required set
        % -- an equality would make the computed set decorative.
        KnownValueBearingStereotypes = ["AirframeCandidate","EngineCandidate", ...
            "FlightControlCandidate","FuelTank","Material","PhysicalItem"];
        EstimateProvenance = "Estimate";
        % D-030's inventory as a CENSUS the model must match: {stereotype,
        % invented property, how many components carry it}. The count is pinned,
        % so an eighth composite fraction means D-030 grows a row first.
        InventedEstimateCensus = { ...
            "Material", "CompositeFraction", 7; ...   % 6 structural parts + the lumped candidate
            "FuelTank", "FuelCapacity_lb",   3};      % the three internal tanks
        % D-021 / D-032: a cost property must DECLARE NaN, not a number that
        % looks like data. Checked in the PROFILE, because the generator
        % overwrites the default every run and hides the hole from a value check.
        % Only the aircraft's Measure of Merit is left: D-056 stopped declaring
        % a cost on the candidates, which is the stronger form of the same rule.
        CostDefault    = "NaN";
        CostProperties = {"MeasureOfMerit", "UnitCost_USD"};
        CostPropertyName = "UnitCost_USD";
        % BrandtCost's own unit flyaway figure, as quoted in REQ_F16A_026 -- the
        % CROSS-CHECK, not the source. The 0.5% band: the two evaluate the same
        % DAPCA IV formulation on different empty weights (19,980.73 vs
        % 19,977.61 lb, D-036), about $7.3k or 0.01%.
        BrandtCostReference_USD = 68.4e6;
        CostCrossCheckRelTol    = 0.005;
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            import matlab.unittest.fixtures.PathFixture
            root = f16aRoot();
            testCase.applyFixture(PathFixture({root, fullfile(root,"physical"), ...
                fullfile(root,"logical"), fullfile(root,"requirements")}));
            testCase.Profile = "F16A_PhysicalProps";
            slreq.clear();
            testCase.addTeardown(@() slreq.clear());
            try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Physical");
            testCase.LogiModel = systemcomposer.loadModel("F16A_Logical");
            testCase.OrigSet   = slreq.load(fullfile(root,"requirements","f16a.slreqx"));
            testCase.PhysSet   = slreq.load(fullfile(root,"requirements","f16a_physical_derived.slreqx"));
            % Loaded for testTraceRefsResolve: candidates trace to L01-L03,
            % which live only in this set.
            testCase.LogiSet   = slreq.load(fullfile(root,"requirements","f16a_logical_derived.slreqx"));
            testCase.Alloc     = systemcomposer.allocation.load("F16A_LogicalToPhysical");
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() bdclose("F16A_Physical"));
            testCase.addTeardown(@() bdclose("F16A_Logical"));

            testCase.BrandtWt = testCase.loadBrandtWeights();
        end
    end

    methods (Test)

        function testPhysicalComponentsExist(testCase)
            % 30 components: Aircraft holds 11 assemblies; the 3 variant roles
            % hold 2/3/2 candidates; the decomposed airframe candidate holds the
            % 6 structural parts; Propulsion holds Engine + InletDuct;
            % FuelSystem 3 tanks. Variant child counts go through getChoices.
            testCase.verifyEqual(testCase.countComps(), testCase.ExpectedComponentCount, ...
                "Expected 30 components (Aircraft + 11 assemblies + 7 candidates + 8 parts + 3 tanks).");
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 1, ...
                "Root should hold exactly one component (Aircraft).");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyEqual(numel(ac.Architecture.Components), 11, ...
                "Aircraft should hold 11 assemblies.");
            testCase.verifyNoOffenders(testCase.variantChoiceCountDefects(), ...
                "Variant role does not hold its expected number of candidates");
            bcd = testCase.componentAt(testCase.AC + "Airframe/" + testCase.BrandtAirframe);
            testCase.verifyEqual(numel(bcd.Architecture.Components), 6, ...
                testCase.BrandtAirframe + " should hold the 6 structural parts (D-003).");
            pr = testCase.componentAt(testCase.AC + "Propulsion");
            testCase.verifyEqual(numel(pr.Architecture.Components), 2, ...
                "Propulsion should hold the Engine variant plus InletDuct.");
            fs = testCase.componentAt(testCase.AC + "FuelSystem");
            testCase.verifyEqual(numel(fs.Architecture.Components), 3, ...
                "FuelSystem should have 3 tanks.");
        end

        function testHierarchyCorrect(testCase)
            % Every assembly resolves under Aircraft; the 6 structural parts
            % under the DECOMPOSED airframe candidate (the choice level D-003
            % adds); every candidate under its variant role.
            missing = strings(1,0);
            for a = testCase.Assemblies
                if ~testCase.resolves(testCase.AC + a)
                    missing(end+1) = "assembly " + a; %#ok<AGROW>
                end
            end
            for p = testCase.AirframeParts
                if ~testCase.resolves(testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/" + p)
                    missing(end+1) = "airframe part " + p; %#ok<AGROW>
                end
            end
            for p = testCase.PropulsionParts
                if ~testCase.resolves(testCase.AC + "Propulsion/" + p)
                    missing(end+1) = "propulsion child " + p; %#ok<AGROW>
                end
            end
            for i = 1:size(testCase.CandidateRows,1)
                rel = string(testCase.CandidateRows{i,1});
                if ~testCase.resolves(testCase.AC + rel)
                    missing(end+1) = "candidate " + rel; %#ok<AGROW>
                end
            end
            for t = testCase.FuelTanks
                if ~testCase.resolves(testCase.AC + "FuelSystem/" + t)
                    missing(end+1) = "fuel tank " + t; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(missing, "Missing from the hierarchy");
            % The three variant roles must really BE variant components: a plain
            % component with two children satisfies every path assertion above
            % and still has no notion of an active configuration.
            notVariant = strings(1,0);
            for i = 1:size(testCase.VariantRows,1)
                rel = string(testCase.VariantRows{i,1});
                if ~isa(testCase.componentAt(testCase.AC + rel), ...
                        "systemcomposer.arch.VariantComponent")
                    notVariant(end+1) = rel; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(notVariant, "Must be a variant component");
            % Childlessness is only meaningful for NON-variant components: a
            % variant reports 0 children on a loaded model whether or not it has
            % choices, so FlightControls is excluded and covered above.
            notLeaf = strings(1,0);
            for a = setdiff(testCase.Assemblies, ...
                    ["Airframe","Propulsion","FuelSystem","FlightControls"])
                c = testCase.Model.lookup(Path=char(testCase.AC + a));
                if ~isempty(c.Architecture.Components)
                    notLeaf(end+1) = a; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(notLeaf, "Should be a leaf");
        end

        function testPhysicalItemStereotypeApplied(testCase)
            % Every component that CAN carry a stereotype carries PhysicalItem
            % -- the 30 the walk reaches, minus the 3 variant role wrappers,
            % which applyStereotype rejects outright (D-013). The part list is
            % DISCOVERED by the walk, so a candidate added without a mass is
            % caught the day it appears.
            [parts, paths] = testCase.stereotypableParts();
            expected = testCase.ExpectedComponentCount - size(testCase.VariantRows,1);
            testCase.verifyEqual(numel(parts), expected, ...
                "Expected " + expected + " stereotype-bearing components (30 walked " + ...
                "minus the 3 variant roles), found " + numel(parts) + ".");
            testCase.verifyNoOffenders( ...
                testCase.partsWithoutStereotype(parts, paths, "PhysicalItem"), ...
                "PhysicalItem not applied to");
        end

        function testLeafMassMatchesGroundTruth(testCase, massLeaf)
            % One leaf per case. A genuinely CROSS-MODEL check: the MBSE model's
            % stated part mass against sizing/'s own calculation (D-036), so a
            % drift between the two representations is what fails.
            testCase.assertTrue(isfield(testCase.BrandtWt, massLeaf.Prop), ...
                "BrandtWeight.run returned no field '" + massLeaf.Prop + "'. The " + ...
                "sizing model's interface changed and this mapping reads the wrong " + ...
                "property -- fix the mapping, do not loosen the tolerance.");
            exp = testCase.BrandtWt.(massLeaf.Prop);
            c   = testCase.componentAt(testCase.AC + massLeaf.Path);
            v   = testCase.propNum(c, testCase.Profile + ".PhysicalItem.Mass_lb");
            testCase.verifyEqual(v, exp, "RelTol", massLeaf.RelTol, ...
                massLeaf.Path + " states " + v + " lb; BrandtWeight." + massLeaf.Prop + ...
                " computes " + exp + " lb (RelTol " + massLeaf.RelTol + ").");
            testCase.verifyGreaterThan(v, 0, ...
                massLeaf.Path + " should be a mass-bearing leaf.");
        end

        function testFuelSystemCarriesZeroOEWMass(testCase)
            % Fuel is a consumable, not empty weight.
            fs = testCase.Model.lookup(Path=char(testCase.AC + "FuelSystem"));
            testCase.verifyEqual( ...
                testCase.propNum(fs, testCase.Profile + ".PhysicalItem.Mass_lb"), 0, ...
                "AbsTol", 1e-9, "FuelSystem should carry zero OEW mass.");
        end

        function testEveryMassCarriesItsOwnProvenance(testCase)
            % Each of the 16 masses summing to OEW says where IT came from. They
            % are the ones this suite just checked against BrandtWeight, so
            % Reference is a claim the same test proves.
            wrong = strings(1,0);
            for leaf = testCase.massLeafRows()
                c  = testCase.componentAt(testCase.AC + leaf.Path);
                dp = testCase.provenanceOf(c, "PhysicalItem");
                if dp ~= "Reference"
                    wrong(end+1) = leaf.Path + " -> '" + dp + "'"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrong, ...
                "Mass verified against BrandtWeight must be tagged Reference");
            % The four invented candidate masses say so, and are in D-030.
            wrong = strings(1,0);
            for rel = ["Airframe/ConventionalTrapWing", ...
                       "Propulsion/Engine/LowThrustSingle_Surrogate", ...
                       "Propulsion/Engine/TwinEngine_Surrogate", ...
                       "FlightControls/HydroMechanical"]
                dp = testCase.provenanceOf(testCase.componentAt(testCase.AC + rel), "PhysicalItem");
                if dp ~= "Estimate"
                    wrong(end+1) = rel + " -> '" + dp + "'"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrong, ...
                "A losing candidate's invented mass must be tagged Estimate");
        end

        function testEngineThrustIsDeclaredAndOnlyOneIsReal(testCase)
            % D-053. Each engine states a thrust, and since D-056 that thrust is
            % the engine trade's own criterion. The four non-engine candidates
            % do not carry NaN thrust any more -- their stereotypes do not
            % declare thrust at all, which is the stronger form of the same
            % claim: a wing is not an engine with an unknown thrust.
            wrong = strings(1,0);
            for i = 1:size(testCase.EngineThrustRows,1)
                rel = string(testCase.EngineThrustRows{i,1});
                exp = testCase.EngineThrustRows{i,2};
                t   = testCase.propNum(testCase.componentAt(testCase.AC + rel), ...
                    testCase.Profile + ".EngineCandidate.Thrust_SL_lb");
                if abs(t - exp) > 1e-6
                    wrong(end+1) = rel + " states " + t + ", expected " + exp; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrong, "Thrust_SL_lb mismatch");
            wrong = strings(1,0);
            for i = 1:size(testCase.CandidateStereotypes,1)
                stereo = string(testCase.CandidateStereotypes{i,2});
                if stereo == "EngineCandidate"; continue; end
                if ismember("Thrust_SL_lb", testCase.declaredPropertyNames(stereo))
                    wrong(end+1) = stereo; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrong, ...
                "A non-engine candidate stereotype declares Thrust_SL_lb; only the engine " + ...
                "trade has a thrust to score (D-056); offending stereotype");
        end

        function testEachTradeScoresOnlyItsOwnCriteria(testCase)
            % The split made executable, read from the criteria line each trade
            % script WRITES into every candidate's rationale -- so this checks
            % the studies that actually ran, not the tables in this file.
            % Thrust is the ENGINE trade's criterion (D-056) and must appear in
            % no other; a benefit is the other two trades' and must not have
            % crept back into the engine trade, where it would re-decide it.
            wrong = strings(1,0);
            for i = 1:size(testCase.CandidateRows,1)
                rel  = string(testCase.CandidateRows{i,1});
                role = string(testCase.CandidateRows{i,2});
                crit = testCase.criteriaClauseOf(rel);
                % strlength, not verifyNotEmpty: criteriaClauseOf returns the
                % string SCALAR "" on no match, and isempty("") is false -- so
                % verifyNotEmpty would pass on exactly the input this catches.
                testCase.assertGreaterThan(strlength(crit), 0, ...
                    rel + "'s rationale carries no 'Criteria (D-015):' clause, so this " + ...
                    "test would pass vacuously.");
                mine  = string(testCase.CandidateStereotypes{ ...
                    strcmp(string(testCase.CandidateStereotypes(:,1)), role), 3});
                theirs = setdiff(string(testCase.CandidateStereotypes(:,3)), mine);
                if ~contains(crit, mine)
                    wrong(end+1) = rel + " does not score on " + mine + " -> " + crit; %#ok<AGROW>
                end
                for other = reshape(theirs, 1, [])
                    if contains(crit, other)
                        wrong(end+1) = rel + " scores on " + other + " -> " + crit; %#ok<AGROW>
                    end
                end
            end
            testCase.verifyNoOffenders(wrong, ...
                "A trade scores a criterion belonging to a different trade, or has lost " + ...
                "its own. Each trade asks for the numbers its decision turns on (D-056)");
        end

        function testSurrogateEnginesClaimNoRealHardware(testCase)
            % The two hypothetical engines carry invented numbers, so their
            % narratives must not attach those numbers to a real product. Only
            % the AUTHORED half is checked: the trade study prepends its own
            % verdict, which legitimately names the winner.
            defects = strings(1,0);
            for rel = testCase.SurrogateEngines
                authored = testCase.authoredJustificationOf(rel);
                testCase.assertGreaterThan(strlength(authored), 0, ...
                    rel + " has no authored justification to check.");
                for tok = testCase.VendorTokens(contains(authored, testCase.VendorTokens))
                    defects(end+1) = rel + " names real hardware '" + tok + "'"; %#ok<AGROW>
                end
                if ~contains(lower(authored), "hypothetical")
                    defects(end+1) = rel + " does not say it is hypothetical"; %#ok<AGROW>
                end
            end
            % The other half of the claim: the real one keeps its real
            % designation precisely because its figures are sourced.
            if contains(lower(testCase.authoredJustificationOf( ...
                    "Propulsion/Engine/F100_PW_200")), "hypothetical")
                defects(end+1) = "F100_PW_200 describes itself as hypothetical";
            end
            testCase.verifyNoOffenders(defects, ...
                "A reader who does not already know which candidates are real cannot " + ...
                "tell from the numbers");
        end

        function testNoPartCarriesDisagreeingProvenance(testCase)
            % THE POINT OF GIVING PhysicalItem ITS OWN TAG. The six airframe
            % leaves carry BOTH Material.DataProvenance (composite fraction,
            % invented -> Estimate) and PhysicalItem.DataProvenance (mass,
            % Brandt -> Reference). Two tags on one part is only honest while
            % each names a different property, so the expected MIXED pairing is
            % asserted -- if a change ever makes them agree, this fails.
            defects = strings(1,0);
            afRoot = testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/";
            for p = testCase.AirframeParts
                c = testCase.componentAt(afRoot + p);
                defects = [defects, testCase.expectProvenance(c, p + " MASS", ...
                    "PhysicalItem", "Reference")]; %#ok<AGROW>
                defects = [defects, testCase.expectProvenance(c, p + " COMPOSITE FRACTION", ...
                    "Material", "Estimate")]; %#ok<AGROW>
            end
            % Same shape on the fuel tanks, the other way round: an Estimate
            % CAPACITY (D-023) beside a Reference dry mass -- the definitional
            % zero Brandt's breakdown implies. Left at the PhysicalItem default
            % these would read Simulation, claiming a roll-up produced a zero
            % nothing computed.
            for t = testCase.FuelTanks
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                defects = [defects, testCase.expectProvenance(c, t + " CAPACITY", ...
                    "FuelTank", "Estimate")]; %#ok<AGROW>
                defects = [defects, testCase.expectProvenance(c, t + " DRY MASS", ...
                    "PhysicalItem", "Reference")]; %#ok<AGROW>
            end
            testCase.verifyNoOffenders(defects, "Provenance describes the wrong property");
        end

        function testAirframeCompositeFractionsSet(testCase)
            % Every airframe structural part carries a Material stereotype with
            % a CompositeFraction in [0,1]. The LUMPED candidate needs one too
            % -- without it, switching the active choice would silently drop the
            % airframe composite fraction to zero and REQ_F16A_022 would be
            % "met" by an aircraft with no material data at all.
            defects = strings(1,0);
            afRoot = testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/";
            for p = [testCase.AirframeParts, "../ConventionalTrapWing"]
                if startsWith(p, "..")
                    c = testCase.componentAt(testCase.AC + "Airframe/ConventionalTrapWing");
                    nm = "ConventionalTrapWing";
                else
                    c = testCase.componentAt(afRoot + p);
                    nm = p;
                end
                if ~ismember("Material", testCase.appliedStereotypes(c))
                    defects(end+1) = nm + " has no Material stereotype"; %#ok<AGROW>
                    continue
                end
                cf = testCase.propNum(c, testCase.Profile + ".Material.CompositeFraction");
                if ~(cf >= 0 && cf <= 1)
                    defects(end+1) = nm + " CompositeFraction = " + cf + ...
                        ", outside [0,1]"; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(defects, "Material defect");
            % The tails are composite-heavy (graphite skins). The lumped
            % candidate's VALUE is an Estimate (D-007) and is not asserted.
            cfvt = testCase.propNum(testCase.componentAt(afRoot + "VerticalTail"), ...
                testCase.Profile + ".Material.CompositeFraction");
            testCase.verifyGreaterThan(cfvt, 0.3, ...
                "VerticalTail should be composite-heavy (graphite skins).");
        end

        function testFuelTankCapacities(testCase)
            % Each fuel tank carries a FuelTank stereotype with a positive
            % capacity and zero dry (OEW) mass; total ~ 6300 lb.
            defects = strings(1,0);
            total = 0;
            for t = testCase.FuelTanks
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                if ~ismember("FuelTank", testCase.appliedStereotypes(c))
                    defects(end+1) = t + " has no FuelTank stereotype"; %#ok<AGROW>
                    continue
                end
                cap = testCase.propNum(c, testCase.Profile + ".FuelTank.FuelCapacity_lb");
                if ~(cap > 0)
                    defects(end+1) = t + " capacity = " + cap; %#ok<AGROW>
                end
                mass = testCase.propNum(c, testCase.Profile + ".PhysicalItem.Mass_lb");
                if abs(mass) > 1e-9
                    defects(end+1) = t + " dry mass = " + mass + ", expected 0"; %#ok<AGROW>
                end
                total = total + cap;
            end
            testCase.verifyNoOffenders(defects, "Fuel tank defect");
            testCase.verifyGreaterThanOrEqual(total, 6000, ...
                "Total internal fuel capacity looks too low.");
        end

        function testFuelRollupDiscoversTanksByStereotype(testCase)
            % What is asserted is the DISCOVERY RULE, not the number: the
            % roll-up must return exactly the parts under FuelSystem carrying a
            % FuelTank stereotype. The walk it replaced took every child and
            % read a capacity off it regardless -- a different function that
            % happens to agree while every child is a tank (D-038).
            r = F16APhysicalFuelRollup();
            found       = sort(string(r.Table.Tank));
            stereotyped = sort(testCase.fuelTankLeafNames());
            testCase.verifyEqual(found, stereotyped, ...
                "The roll-up returned {" + strjoin(found, ", ") + "} but the parts " + ...
                "under FuelSystem carrying a FuelTank stereotype are {" + ...
                strjoin(stereotyped, ", ") + "}.");
            unstereotyped = strings(1,0);
            for t = found'
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                if ~ismember("FuelTank", testCase.appliedStereotypes(c))
                    unstereotyped(end+1) = t; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(unstereotyped, ...
                "The roll-up counted a part carrying no FuelTank stereotype");
            % A silent 0 is the defect being removed; it must not return as a
            % different silent 0.
            testCase.verifyGreaterThan(r.AvailableFuel_lb, 0, ...
                "The roll-up totalled 0 lb. An empty walk is supposed to raise " + ...
                "F16APhysicalFuelRollup:noFuelTanks, not report a total.");
            testCase.verifyEqual(r.AvailableFuel_lb, sum(r.Table.FuelCapacity_lb), ...
                "AbsTol", 1e-9, "Total does not equal the sum of the per-tank rows.");
        end

        function testMassRollupSelfConsistent(testCase)
            % Each assembly subtotal is the sum of its parts and OEW the sum of
            % all ACTIVE leaves. This is where the two path spaces meet: the
            % roll-up reads INSTANCE paths (choice node elided), this test reads
            % ARCHITECTURE paths (choice level included). Asserting they agree
            % is what stops the variant restructure quietly changing what "the
            % airframe weighs" means.
            r = testCase.massRollup();
            afRoot        = testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/";
            expAirframe   = testCase.sumMasses(afRoot + testCase.AirframeParts);
            expPropulsion = testCase.sumMasses([ ...
                testCase.AC + "Propulsion/Engine/" + testCase.BrandtEngine, ...
                testCase.AC + "Propulsion/InletDuct"]);
            expEngine     = testCase.sumMasses(testCase.AC + "Propulsion/Engine/" + testCase.BrandtEngine);
            testCase.verifyEqual(r.Airframe,   expAirframe,   "AbsTol", 0.01, ...
                "Airframe subtotal != sum of parts.");
            testCase.verifyEqual(r.Propulsion, expPropulsion, "AbsTol", 0.01, ...
                "Propulsion subtotal != sum of parts.");
            testCase.verifyEqual(r.Engine,     expEngine,     "AbsTol", 0.01, ...
                "The rolled-up Engine mass must be the ACTIVE engine candidate's mass, " + ...
                "not a sum over all three candidates.");
            testCase.verifyEqual(r.OEW, testCase.sumOfLeafMasses(), "AbsTol", 0.05, ...
                "OEW != sum of leaf masses.");
            testCase.verifyEqual(r.AirframeLessEngine, r.OEW - r.Engine, "AbsTol", 1e-6, ...
                "Airframe-less-engine must equal OEW - Engine.");
        end

        function testOEWMeasureOfMerit(testCase)
            % The Aircraft carries a MeasureOfMerit with Goal=Minimize, and
            % OEW_lb holds the rolled-up empty weight.
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyTrue(ismember("MeasureOfMerit", testCase.appliedStereotypes(ac)), ...
                "MeasureOfMerit not applied to Aircraft.");
            testCase.verifyEqual( ...
                testCase.propOf(ac, "MeasureOfMerit", "Goal"), "Minimize", ...
                "OEW MoM Goal should be Minimize.");
            testCase.verifyEqual( ...
                testCase.propNum(ac, testCase.Profile + ".MeasureOfMerit.OEW_lb"), ...
                testCase.sumOfLeafMasses(), "AbsTol", 0.05, ...
                "OEW MoM value should equal the mass roll-up.");
        end

        function testCostMeasureOfMerit(testCase)
            % Unit cost is the OTHER MoM, and unlike OEW it comes from a
            % parametric FUNCTION rather than a roll-up -- the contrast the two
            % Measures of Merit exist to teach (D-043).
            testCase.verifyEqual(exist("F16APhysicalCostModel", "file"), 2, ...
                "Cost-model hook F16APhysicalCostModel is missing.");
            ac   = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            cost = testCase.propNum(ac, testCase.Profile + ".MeasureOfMerit.UnitCost_USD");
            testCase.verifyTrue(isfinite(cost) && cost > 0, ...
                "The aircraft's cost MoM is " + string(num2str(cost)) + ". Since D-043 " + ...
                "it must hold a computed DAPCA IV flyaway cost, not a placeholder.");
            % A CROSS-CHECK between two independent evaluations of the same
            % formulation, not a restatement: ours runs on the MBSE model's
            % rolled-up OEW, and the residual is that 3.12 lb gap (D-036)
            % propagated through the regression -- about $7.3k.
            testCase.verifyEqual(cost, testCase.BrandtCostReference_USD, ...
                "RelTol", testCase.CostCrossCheckRelTol, ...
                "The cost model gives $" + string(num2str(cost/1e6)) + "M against " + ...
                "BrandtCost's $" + string(num2str(testCase.BrandtCostReference_USD/1e6)) + ...
                "M (REQ_F16A_026). A divergence beyond " + ...
                string(num2str(100*testCase.CostCrossCheckRelTol)) + "% means the two no " + ...
                "longer evaluate the same model -- explain it before widening this.");
        end

        function testFlyawayCostIgnoresTheMissionPlaceholder(testCase)
            % F16APhysicalCostModel hands BrandtCost.run a PLACEHOLDER mission,
            % because run() demands one only so validate_run_ can assert the O&M
            % terms are non-NaN -- the flyaway never reads it. Mission fuel is
            % deliberately not computed here (D-042), so that placeholder must
            % not be able to move the cost. Measured, not asserted: run the
            % reference model twice with wildly different mission inputs and
            % require an IDENTICAL flyaway.
            import matlab.unittest.fixtures.PathFixture
            brandtDir = F16APhysicalArchitectureTest.brandtF16ADir();
            testCase.assumeTrue(isfolder(brandtDir), ...
                "The sizing reference model is absent; the cost model itself fails " + ...
                "loudly on this, so there is nothing left for this test to add.");
            testCase.applyFixture(PathFixture(brandtDir));

            geom = BrandtGeometry(); geom.analyze();
            eng  = BrandtEngine();   eng.analyze();
            c    = BrandtCost(geom, eng); c.analyze();
            We   = struct('W_empty_lb', testCase.ExpectedOEW_lb);

            a = c.run(testCase.W_TO_lb, We, struct('total_fuel_lb',1,     'total_time_min',1));
            b = c.run(testCase.W_TO_lb, We, struct('total_fuel_lb',9.9e4, 'total_time_min',7.5e3));

            testCase.verifyEqual(b.C_unit_flyaway_usd, a.C_unit_flyaway_usd, ...
                "The unit flyaway cost moved from $" + a.C_unit_flyaway_usd + " to $" + ...
                b.C_unit_flyaway_usd + " when only the MISSION input changed, so the " + ...
                "aircraft's cost MoM is being computed from an invented fuel burn.");
            % ... and the O&M terms DO move, which is what makes the check above
            % non-vacuous: the two runs really did differ.
            testCase.verifyNotEqual(b.C_OM_life_usd, a.C_OM_life_usd, ...
                "The two runs produced identical O&M costs, so the mission inputs did " + ...
                "not actually differ and the invariance check above proved nothing.");
        end

        function testRealizationAllocationExists(testCase)
            testCase.verifyNotEmpty(testCase.Alloc.getScenario("Scenario 1"), ...
                "Missing realization allocation scenario.");
        end

        function testRealizationCoversAllLogicalRoles(testCase)
            % Every one of the 9 logical roles is a realization source, and a
            % role with candidates is realized by ALL of them. A losing
            % alternative genuinely does realize the role -- that is what makes
            % the trade a decision rather than a formality -- so narrowing to
            % the active choice would hide exactly the options L enumerated
            % (D-002).
            [srcCounts, ~] = testCase.allocEndpoints();
            testCase.verifyNoOffenders( ...
                setdiff(testCase.LogicalRoles, string(keys(srcCounts))), ...
                "Logical roles not realized");
            testCase.verifyNoOffenders(testCase.rolesNotRealizedByAllTheirCandidates(), ...
                "A variant role must be realized by every candidate that could fill it");
            % The 1->many teaching moment MOVED with the restructure: it is now
            % PropulsionSystem -> 3 mutually exclusive engine candidates plus
            % the InletDuct they all share (D-009).
            testCase.verifyGreaterThanOrEqual(srcCounts("PropulsionSystem"), 4, ...
                "PropulsionSystem should realize to >= 4 parts (3 engine candidates + InletDuct).");
        end

        function testUnrealizedInfrastructureParts(testCase)
            % Electrical, Hydraulics, ECS, SecondaryStructure realize no single
            % logical role -- the symmetric echo of L's constraint-driven roles.
            [~, dstNames] = testCase.allocEndpoints();
            testCase.verifyNoOffenders(intersect(testCase.UnrealizedParts, dstNames), ...
                "These parts should realize no logical role");
        end

        function testCostMoMHomedAtPhysical(testCase)
            % REQ_F16A_026 is reclassified as a Measure of Merit (keywords) and
            % is Implement-linked from the Physical layer (Aircraft).
            testCase.verifyRequirementsLinked(testCase.OrigSet, "REQ_F16A_026");
            req = find(testCase.OrigSet, Id="REQ_F16A_026");
            testCase.verifyTrue(any(string(req.Keywords) == "minimize"), ...
                "REQ_F16A_026 should be marked a Measure of Merit (keyword 'minimize').");
        end

        function testMaterialsRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_022 from the
            % Airframe. The "Verified by" link is added MANUALLY (see README),
            % so it is deliberately NOT asserted here -- the "is it met?" check
            % is F16AMaterialsVerificationTest.
            testCase.verifyRequirementsLinked(testCase.OrigSet, "REQ_F16A_022");
        end

        function testFuelRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_P01 from the
            % FuelSystem. Its Verify link is added manually and is not asserted.
            testCase.verifyRequirementsLinked(testCase.PhysSet, "REQ_F16A_P01");
        end

        % ---------------- Stage 2: rationale and trade vocabulary --------

        function testEveryPartHasRationale(testCase)
            % "Why does this part exist?" must be answerable by QUERYING the
            % model, not by reading a code comment (D-006). The part list is
            % DISCOVERED by walking, so Stage 3's candidates are covered the day
            % they appear -- and the walk asserts its own size first, because a
            % walk that silently visits nothing makes every check below vacuous.
            [~, walked] = testCase.walkComponents();
            testCase.verifyEqual(numel(walked), testCase.ExpectedComponentCount, ...
                "The architecture walk reached " + numel(walked) + " components, " + ...
                "expected " + testCase.ExpectedComponentCount + ". A walk that skips a " + ...
                "variant's choices reports too few and makes every per-part assertion vacuous.");
            [parts, ~] = testCase.stereotypableParts();
            testCase.verifyNotVacuous(parts, "no stereotype-bearing part was found");
            d = testCase.rationaleDefects();
            testCase.verifyNoOffenders(d.Missing, ...
                "No " + testCase.RationaleStereotype + " stereotype on");
            testCase.verifyNoOffenders(d.BadKind, ...
                "SourceKind outside the " + testCase.SourceKindClass + " vocabulary on");
            testCase.verifyNoOffenders(d.EmptyTrace, ...
                "Empty TraceRef -- a rationale that traces to nothing is not traceable");
            testCase.verifyNoOffenders(d.ThinJustification, ...
                "Justification shorter than " + testCase.MinJustificationLength + ...
                " characters (a part name is not a justification)");
        end

        function testInfrastructurePartsAreSupportingInfrastructure(testCase)
            % The executable half of docs/05_physical.md's claim that some parts
            % are born of the physics of building an airplane, not of a role
            % above them. testUnrealizedInfrastructureParts says these four
            % realize no logical role; this says the model states WHY. A part
            % with no realization AND no stated reason is an unexplained box.
            testCase.verifyNoOffenders( ...
                testCase.partsWithSourceKindOtherThan(testCase.UnrealizedParts, ...
                    "SupportingInfrastructure"), ...
                "Expected SourceKind = SupportingInfrastructure on");
        end

        function testRationaleVocabularyIsClosed(testCase)
            % The two vocabularies are real MATLAB enumerations, not free
            % strings (D-011): with a string property "SuportingInfrastructure"
            % is a valid value and every downstream query quietly misses that
            % part. Checked in the PROFILE, so it holds even before Stage 3
            % applies a candidate stereotype to anything.
            testCase.verifyNotVacuous(testCase.profilesOf(), ...
                "no profile resolved for the P model (expected " + testCase.Profile + ")");
            wrongType = strings(1,0);
            typed = { ...
                testCase.RationaleStereotype, "SourceKind",      testCase.SourceKindClass; ...
                "EngineCandidate",            "DataProvenance",  testCase.DataProvenanceClass; ...
                "AirframeCandidate",          "DataProvenance",  testCase.DataProvenanceClass; ...
                "FlightControlCandidate",     "DataProvenance",  testCase.DataProvenanceClass; ...
                "FuelTank",                   "DataProvenance",  testCase.DataProvenanceClass};
            for i = 1:size(typed,1)
                actual = testCase.declaredPropertyType(string(typed{i,1}), string(typed{i,2}));
                if actual ~= string(typed{i,3})
                    wrongType(end+1) = string(typed{i,1}) + "." + string(typed{i,2}) + ...
                        " is typed '" + actual + "', expected " + string(typed{i,3}); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(wrongType, ...
                "A vocabulary property must be typed by its enumeration, not a free string");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.SourceKindClass), ...
                sort(testCase.SourceKindMembers), ...
                testCase.SourceKindClass + " must resolve on the path with exactly the " + ...
                "six agreed members (D-006).");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.DataProvenanceClass), ...
                sort(testCase.DataProvenanceMembers), ...
                testCase.DataProvenanceClass + " must resolve on the path with exactly " + ...
                "the four agreed members (D-007).");
        end

        function testCandidateStereotypesDeclared(testCase)
            % Stage 2 DECLARES the trade vocabulary; Stage 3 populates it.
            % THREE stereotypes, one per trade (D-056), and each is pinned to
            % its own property set BOTH ways: everything it must declare, and
            % nothing beyond it. The second half is what keeps the split real --
            % re-adding Benefit to EngineCandidate would otherwise pass. The old
            % single-stereotype version could not express that at all.
            % Deliberately NOT asserted: that anything CARRIES a stereotype.
            declared = testCase.profileStereotypeNames();
            for i = 1:size(testCase.CandidateStereotypes,1)
                stereo   = string(testCase.CandidateStereotypes{i,2});
                expected = testCase.CandidateStereotypes{i,4};
                testCase.verifyTrue(ismember(stereo, declared), ...
                    "The P profile must declare " + stereo + ", but declares: " + ...
                    strjoin(declared, ", ") + ".");
                found = testCase.declaredPropertyNames(stereo);
                testCase.verifyNoOffenders(setdiff(expected, found), ...
                    stereo + " must declare all " + numel(expected) + ...
                    " of its trade properties; missing");
                testCase.verifyNoOffenders(setdiff(found, expected), ...
                    stereo + " declares a property its trade does not use. A trade asks " + ...
                    "for the numbers its own decision turns on, which is the whole point " + ...
                    "of the split (D-056); unexpected");
            end
        end

        % ---------------- Stage 3: candidates and the active set ---------

        function testCandidatesCarryTradeParameters(testCase)
            % Each candidate is fully constituted BEFORE anything scores it:
            % its own trade's stereotype applied, a kind that EXISTS in the L model
            % (a typo would silently drop it out of its role's trade), positive
            % mass and benefit, TRL in scale, the honest NaN cost, a provenance
            % tag. Ranges only -- values are Estimates, and the three Brandt
            % masses are asserted against the sizing model per leaf above.
            T = testCase.candidateTable();
            testCase.verifyEqual(height(T), size(testCase.CandidateRows,1), ...
                "The candidate table must cover all seven candidates.");
            testCase.verifyNoOffenders(T.Path(~T.Found), "Candidate not found in the model");
            testCase.verifyNoOffenders(T.Path(~T.HasStereotype), ...
                "No candidate stereotype applied to (one per trade, D-056)");
            testCase.verifyNoOffenders(testCase.mismatches(T, "Role", "ExpectedRole"), ...
                "The candidate carries the stereotype of a DIFFERENT trade, so it would " + ...
                "be scored in the wrong one (role implied by stereotype -> expected)");
            testCase.verifyNoOffenders(T.Path(~T.RoleResolves) + " -> '" + T.Role(~T.RoleResolves) + "'", ...
                "The stereotype implies a role that does not exist in the L model");
            testCase.verifyNoOffenders(testCase.mismatches(T, "Kind", "ExpectedKind"), ...
                "RealizesKind mismatch (found -> expected)");
            testCase.verifyNoOffenders(T.Path(~T.KindResolves) + " -> '" + T.Kind(~T.KindResolves) + "'", ...
                "RealizesKind does not name a kind that exists under its role in the L model");
            testCase.verifyNoOffenders(T.Path(~(T.Mass_lb > 0)), ...
                "Mass_lb must be positive on");
            % A benefit is boxed at BOTH ends (D-033). "> 0" would be weaker
            % than the code it checks -- it admits 78, which is 7.8 with a
            % slipped decimal and enough to pick the wrong winner. Applied only
            % to the two trades that HAVE a benefit; the engine trade's own
            % criterion is thrust, checked by its own test below.
            isBen = ismember(T.ExpectedRole, testCase.BenefitScoredRoles);
            testCase.verifyNotVacuous(T.Path(isBen), ...
                "no candidate is scored on a 1..10 benefit, so the scale sweep is empty");
            bad = isBen & ~arrayfun(@(b) testCase.onBenefitScale(b), T.Merit);
            testCase.verifyNoOffenders(T.Path(bad) + " (" + T.MeritName(bad) + ") -> " + T.Merit(bad), ...
                "A benefit criterion is outside the declared " + testCase.BenefitScale(1) + ...
                ".." + testCase.BenefitScale(2) + " scale (D-033); an out-of-range value " + ...
                "is FINITE and so invisible to every other check");
            % Range AND integrality, because the guard checks both and a test
            % weaker than its guard will one day be cited as evidence the guard
            % is unnecessary.
            bad = ~arrayfun(@(t) testCase.onTRLScale(t), T.TRL);
            testCase.verifyNoOffenders(T.Path(bad) + " -> " + T.TRL(bad), ...
                "TRL outside the integer " + testCase.TRLScale(1) + ".." + ...
                testCase.TRLScale(2) + " scale (D-021 defaults it to 0 on purpose)");
            bad = ~ismember(T.DataProvenance, testCase.DataProvenanceMembers);
            testCase.verifyNoOffenders(T.Path(bad) + " -> '" + T.DataProvenance(bad) + "'", ...
                "DataProvenance outside the " + testCase.DataProvenanceClass + " vocabulary");
            testCase.verifyNoOffenders( ...
                testCase.mismatches(T, "DataProvenance", "ExpectedProvenance"), ...
                "DataProvenance mismatch -- a Brandt figure is Reference and a teaching " + ...
                "value Estimate (D-007) (found -> expected)");
            % A candidate must also SAY it is one. TradeWinner is accepted
            % alongside TradeAlternative so this survives Stage 4.
            bad = ~ismember(T.SourceKind, testCase.CandidateSourceKinds);
            testCase.verifyNoOffenders(T.Path(bad) + " -> '" + T.SourceKind(bad) + "'", ...
                "Rationale.SourceKind on a candidate must be one of " + ...
                strjoin(testCase.CandidateSourceKinds, "/"));
        end

        function testCostIsOnTheAircraftOnly(testCase)
            % THE DISTINCTION D-043 DREW, closed by D-056. The AIRCRAFT carries a
            % real DAPCA IV flyaway cost; no CANDIDATE carries one, and now none
            % can -- the three candidate stereotypes do not declare the property
            % at all. Cost is priced for an airframe, not a part, and a
            % per-candidate 0 would be an unbeatably good score under a ratio
            % value function.
            %
            % The DECLARED DEFAULT is checked first, because reading the value
            % alone is what let the last hole hide: MeasureOfMerit.UnitCost_USD
            % defaulted to 0 for five stages while this test stayed green, the
            % generator happening to write NaN over it every run (D-032).
            testCase.verifyNoOffenders(testCase.costPropertiesNotDefaultingToNaN(), ...
                "A cost property must DECLARE " + testCase.CostDefault + " as its " + ...
                "default, not a number that reads as data (D-021, D-032); a value " + ...
                "assertion cannot see this (stereotype.property -> declared default)");
            declaresCost = strings(1,0);
            for i = 1:size(testCase.CandidateStereotypes,1)
                stereo = string(testCase.CandidateStereotypes{i,2});
                if ismember(testCase.CostPropertyName, testCase.declaredPropertyNames(stereo))
                    declaresCost(end+1) = stereo; %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(declaresCost, ...
                "A candidate stereotype declares " + testCase.CostPropertyName + ". It " + ...
                "could only ever be NaN (D-043), and a column that can never be scored " + ...
                "is not a criterion -- D-056 stopped declaring it");
            % ... and the other half: the aircraft's is real. Asserted here as
            % well as in testCostMeasureOfMerit so "cost is NaN" can never
            % quietly become true everywhere again.
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyTrue( ...
                isfinite(testCase.propNum(ac, testCase.Profile + ".MeasureOfMerit.UnitCost_USD")), ...
                "The aircraft's cost MoM went back to NaN, so the cost model stopped running.");
        end

        function testExactlyOneActiveCandidatePerRole(testCase)
            % Each variant role resolves exactly one active choice, and it is
            % one of its OWN candidates. Then a global count: as many selected
            % candidates as roles to decide. Active choice and Selected stay
            % different things (configuration vs recorded verdict); that they
            % AGREE per role is testTradeSelectedExactlyOneWinnerPerRole.
            d = testCase.activeChoiceDefects();
            testCase.verifyNoOffenders(d.NoActive, ...
                "Variant role without exactly one active choice");
            testCase.verifyNoOffenders(d.Foreign, ...
                "Active choice is not one of the role's own candidates");
            T = testCase.candidateTable();
            testCase.verifyEqual(sum(T.Selected), size(testCase.VariantRows,1), ...
                "Expected one selected candidate per variant role (" + ...
                size(testCase.VariantRows,1) + "), found " + sum(T.Selected) + ...
                ": {" + strjoin(T.Path(T.Selected), ", ") + "}.");
        end

        function testOEWCountsOnlyTheActiveConfiguration(testCase)
            % Turning three components into variant roles must not change what
            % the aircraft weighs. The failure guarded against is the quiet one
            % -- a walk using getChoices instead of getActiveChoice sums every
            % candidate and inflates OEW by the four losers, which is still a
            % plausible aeroplane (D-003, D-012).
            r         = testCase.massRollup();
            activeSum = testCase.leafMassSum("active");
            allSum    = testCase.leafMassSum("all");
            testCase.verifyEqual(r.OEW, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "OEW must be the Brandt " + testCase.ExpectedOEW_lb + " lb; the variant " + ...
                "restructure adds candidates, it does not add mass (D-003).");
            testCase.verifyEqual(activeSum, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "The active-configuration leaf sum computed here is " + activeSum + " lb.");
            testCase.verifyEqual(r.OEW, activeSum, "AbsTol", 0.05, ...
                "The roll-up (" + r.OEW + " lb) and the active-only walk (" + activeSum + ...
                " lb) disagree.");
            % Non-vacuity: if the losing candidates carried no PhysicalItem
            % mass the two sums would be identical and the check below could
            % never detect double counting -- and a lumped candidate with no
            % mass is itself a real bug, since selecting it would delete weight.
            testCase.verifyGreaterThan(allSum, activeSum + 1, ...
                "The all-candidates sum (" + allSum + " lb) is not meaningfully larger " + ...
                "than the active sum (" + activeSum + " lb): the inactive candidates " + ...
                "carry no PhysicalItem.Mass_lb, so this test cannot detect double counting.");
            testCase.verifyLessThan(r.OEW, allSum - 1, ...
                "OEW (" + r.OEW + " lb) has reached the ALL-CANDIDATES sum (" + allSum + ...
                " lb): the roll-up is counting inactive candidates. Descend into " + ...
                "getActiveChoice, not getChoices (D-012).");
        end

        function testCandidateMassMatchesItsModelledParts(testCase)
            % The mass a candidate is SCORED on must be the mass it would
            % actually contribute. Without this the trade scores one number
            % while the model builds another, and the roll-up and the decision
            % stop describing the same aeroplane.
            T = testCase.candidateTable();
            off = abs(T.Mass_lb - T.ModelledMass_lb) > 0.01;
            testCase.verifyNoOffenders( ...
                T.Path(off) + " " + T.Mass_lb(off) + " -> " + T.ModelledMass_lb(off), ...
                "The candidate's traded Mass_lb disagrees with the mass the model " + ...
                "actually carries (scored -> modelled)");
        end

        function testCandidateOrderingMatchesTheIntendedLesson(testCase)
            % Relationships, not values. Two orderings carry D-015's teaching:
            % in every role the production candidate is the lightest, and the
            % winning engine does NOT have the most thrust. If a data revision
            % makes the winner best at everything, the example stops teaching a
            % trade-off.
            testCase.verifyNoOffenders(testCase.rolesWhereBrandtCandidateIsNotLightest(), ...
                "The production candidate is not the lightest in this role; D-015 scores " + ...
                "mass as a ratio to the Brandt baseline, so this changes which candidate " + ...
                "the trade should pick");
            best = testCase.highestMeritPaths("PropulsionSystem");
            testCase.verifyNotVacuous(best, ...
                "no propulsion candidate has a readable Thrust_SL_lb");
            testCase.verifyFalse( ...
                ismember("Propulsion/Engine/" + testCase.BrandtEngine, best), ...
                "The production engine now has the most thrust of its role. The engine " + ...
                "trade is supposed to be won on maturity and installed mass DESPITE a " + ...
                "thrust deficit against the twin (D-015, D-056).");
        end

        function testMaterialsRollupFollowsActiveAirframe(testCase)
            % REQ_F16A_022's evidence must describe the aeroplane actually
            % configured, so the fraction is computed over the ACTIVE airframe
            % candidate's own parts, DISCOVERED from the model -- a hard-coded
            % .../Airframe/Wing path would keep working while silently reporting
            % the wrong airframe. Airframe MASS is the sharper discriminator:
            % 6722.88 decomposed, 7300 lumped, ~14023 both at once.
            mats = F16APhysicalMaterialsRollup();
            a    = testCase.activeAirframeMaterials();
            testCase.verifyEqual(string(mats.ActiveCandidate), a.ActiveName, ...
                "The materials roll-up says it describes '" + string(mats.ActiveCandidate) + ...
                "' but the model's active airframe candidate is '" + a.ActiveName + "'.");
            testCase.verifyEqual(a.NumParts, numel(testCase.AirframeParts), ...
                "The active airframe candidate exposes " + a.NumParts + " parts, expected " + ...
                numel(testCase.AirframeParts) + " -- the roll-up is not looking at the " + ...
                "decomposed candidate.");
            testCase.verifyEqual(mats.AirframeMass_lb, testCase.BrandtAirframeMass_lb, ...
                "AbsTol", 0.01, ...
                "The materials roll-up weighs " + mats.AirframeMass_lb + " lb of airframe; " + ...
                "the active configuration is " + testCase.BrandtAirframeMass_lb + " lb.");
            testCase.verifyEqual(mats.CompositeFraction, a.CompositeFraction, "AbsTol", 1e-9, ...
                "The roll-up's composite fraction (" + mats.CompositeFraction + ") differs " + ...
                "from the mass-weighted fraction over the active candidate's own parts (" + ...
                a.CompositeFraction + ").");
            testCase.verifyEqual(mats.CompositeFraction, testCase.ExpectedCompositeFraction, ...
                "AbsTol", 5e-4, "Airframe composite fraction should be ~" + ...
                testCase.ExpectedCompositeFraction + " for the active configuration.");
        end

        function testTraceRefsResolve(testCase)
            % Every reference in every Rationale.TraceRef is FOLLOWED, not just
            % counted: requirement ids through find() in the set that OWNS them,
            % model paths through lookup. Otherwise a renamed component breaks
            % traceability while the suite stays green.
            %
            % The negative control runs first, through the SAME resolver -- a
            % resolver that can only say yes asserts nothing.
            testCase.verifyNoOffenders( ...
                testCase.BogusTraceRefs(arrayfun(@(r) testCase.traceRefResolves(r), ...
                    testCase.BogusTraceRefs)), ...
                "The TraceRef resolver claims these deliberately bogus references " + ...
                "resolve, so every assertion below it is worthless");
            % A requirement id must resolve in its OWN set. If the sets were not
            % really distinct, routing by id prefix would be untested.
            testCase.verifyEmpty(testCase.findRequirement(testCase.OrigSet, "REQ_F16A_P01"), ...
                "REQ_F16A_P01 is visible in f16a.slreqx, so routing a TraceRef to the " + ...
                "physical derived set proves nothing.");
            testCase.verifyEmpty(testCase.findRequirement(testCase.OrigSet, "REQ_F16A_L01"), ...
                "REQ_F16A_L01 is visible in f16a.slreqx, so routing a TraceRef to the " + ...
                "logical derived set proves nothing.");
            refs = testCase.allTraceRefs();
            [parts, ~] = testCase.stereotypableParts();
            testCase.verifyGreaterThanOrEqual(numel(refs), numel(parts), ...
                "Collected " + numel(refs) + " references from " + numel(parts) + ...
                " parts -- every part owes at least one, so references are being lost " + ...
                "before they are ever checked.");
            % All three forms must actually be exercised, so dropping a whole
            % form cannot shrink this test into a green subset of itself.
            unexercised = strings(1,0);
            forms = ["requirement id", testCase.RequirementPrefix; ...
                     "logical path",   testCase.LogicalPathPrefix; ...
                     "physical path",  testCase.PhysicalPathPrefix];
            for i = 1:size(forms,1)
                if ~any(startsWith(refs, forms(i,2)))
                    unexercised(end+1) = forms(i,1); %#ok<AGROW>
                end
            end
            testCase.verifyNoOffenders(unexercised, "No TraceRef of this form was checked");
            testCase.verifyNoOffenders(testCase.unresolvedTraceRefs(), ...
                "TraceRef does not resolve -- it names something that no longer exists, " + ...
                "or is not in a recognised form (REQ_F16A_*, F16A_Logical/..., F16A_Physical/...)");
        end

        function testFuelTankProvenanceTagged(testCase)
            % D-023. The 3 x 2100 lb split is an even division of a rounded
            % figure, not Brandt's 6296.30 lb mission fuel -- an Estimate in
            % substance that carried no tag only because FuelTank had nowhere to
            % put one. It is the oldest untagged number in the model.
            testCase.verifyNoOffenders( ...
                testCase.tanksWithProvenanceOtherThan(testCase.FuelTankProvenance), ...
                "Expected FuelTank.DataProvenance = " + testCase.FuelTankProvenance + ...
                " on every tank (D-023)");
        end

        % ---------------- Stage 4: the recorded decision -----------------

        function testTradeSelectedExactlyOneWinnerPerRole(testCase)
            % The trade writes its verdict in two independent places -- the
            % candidate's Selected flag and the variant's ACTIVE CHOICE -- and
            % this asserts they say the same thing. Each half looks fine alone:
            % active F100 with Selected on the surrogate is a HALF-WRITTEN
            % decision in which every mass describes one engine and every trade
            % report the other.
            d = testCase.tradeSelectionDefects();
            testCase.verifyNoOffenders(d.WrongCount, ...
                "A role must have exactly one selected candidate -- the trade picks one " + ...
                "winner, and a re-run must clear the previous");
            testCase.verifyNoOffenders(d.Disagree, ...
                "The trade's verdict (the candidate stereotype's Selected) and the " + ...
                "model's configuration (the active variant choice) disagree, so the " + ...
                "decision was only half written");
        end

        function testWinnersCarryTradeWinnerRationale(testCase)
            % After the trade the winner says TradeWinner and every loser says
            % TradeAlternative -- on the record as considered and rejected,
            % which is why D-002 keeps losers in the model. The winner must also
            % CITE ITS SCORE, or the rationale and the arithmetic are unrelated
            % artifacts. Only that a score-shaped token is there, not its value.
            d = testCase.winnerRationaleDefects();
            testCase.verifyEqual(d.NumWinners, size(testCase.VariantRows,1), ...
                "Found " + d.NumWinners + " selected candidates, expected " + ...
                size(testCase.VariantRows,1) + ". With none, every winner check below " + ...
                "would pass vacuously.");
            testCase.verifyNoOffenders(d.WrongKind, ...
                "Rationale.SourceKind must be " + testCase.WinnerSourceKind + " on the " + ...
                "selected candidate and " + testCase.AlternativeSourceKind + " on every " + ...
                "other (found -> expected)");
            testCase.verifyNoOffenders(d.ThinJustification, ...
                "A winner's Justification is shorter than " + ...
                testCase.MinJustificationLength + " characters -- the trade rewrote it " + ...
                "with something that does not explain anything");
            testCase.verifyNoOffenders(d.NoScore, ...
                "A winner's Justification cites no score (no token matching " + ...
                testCase.ScoreTokenPattern + "), so the rationale in the model and the " + ...
                "arithmetic that produced it are not tied together");
        end

        function testDecisionRequirementsImplemented(testCase)
            % D-010: REQ_F16A_L01..L03 record three decisions L may not make,
            % and P writes their Implement links -- so this is a P assertion. In
            % the L suite it would make L pass or fail according to whether P
            % had run. The link TYPE is checked, not just its existence: a
            % Relate or Derive link leaves the requirement showing as
            % unimplemented in the Requirements Editor while this test goes green.
            d = testCase.decisionRequirementDefects();
            testCase.verifyNoOffenders(d.Missing, ...
                "Decision requirement not found in f16a_logical_derived.slreqx");
            testCase.verifyNoOffenders(d.Unlinked, ...
                "Decision requirement has no incoming link. The physical trade study is " + ...
                "what implements these (D-010, D-019); after it runs this is how we know " + ...
                "it did");
            testCase.verifyNoOffenders(d.NotImplement, ...
                "Decision requirement is linked but not by an " + testCase.ImplementLinkType + ...
                " link, so it still reads as unimplemented (id -> link types found)");
        end

        function testProductionConfigurationWins(testCase)
            % Asserted on VALUES rather than relationships, because these three
            % names are ground truth about an aeroplane that exists: the F-16A
            % flew with an F100-PW-200, a blended cranked delta, and
            % fly-by-wire. The scores are NOT asserted -- revising an Estimate
            % is legitimate; a revision that changed the WINNER would make the
            % example teach a trade study that picks an aircraft nobody built.
            won = testCase.selectedCandidateNames();
            testCase.verifyEqual(won, sort(testCase.ExpectedWinners), ...
                "The trade must select the production F-16A configuration. Selected: {" + ...
                strjoin(won, ", ") + "}, expected: {" + ...
                strjoin(sort(testCase.ExpectedWinners), ", ") + "}.");
        end

        function testEngineTradeIsNotWonOnThrust(testCase)
            % D-015's lesson made executable: a weighted trade is not a contest
            % of the headline number. The F100 wins while the twin out-thrusts
            % it by 35%, because it is the most mature and the lightest
            % installed -- the trade-off this example exists to demonstrate.
            % Asserted in BOTH directions, because a data revision nudging the
            % F100's thrust to the top would leave every other test green and
            % quietly turn this into "the best candidate at everything wins".
            role   = "PropulsionSystem";
            winner = testCase.selectedPathInRole(role);
            testCase.verifyNumElements(winner, 1, ...
                "Expected exactly one selected propulsion candidate; found " + ...
                numel(winner) + ". Nothing below can be judged without one.");
            testCase.verifyFalse(any(ismember(winner, testCase.highestMeritPaths(role))), ...
                "The winning engine now has the most thrust of its role, so there is " + ...
                "no trade-off left to teach (D-015, D-056).");
            testCase.verifyEqual(testCase.highestTRLPaths(role), winner, ...
                "The winning engine must be the uniquely most mature candidate of its " + ...
                "role -- TRL is one of the two criteria it wins on (D-015). Highest TRL: {" + ...
                strjoin(testCase.highestTRLPaths(role), ", ") + "}.");
            testCase.verifyEqual(testCase.lowestMassPaths(role), winner, ...
                "The winning engine must be the uniquely lightest candidate of its role " + ...
                "-- installed mass is the other criterion it wins on (D-015). Lightest: {" + ...
                strjoin(testCase.lowestMassPaths(role), ", ") + "}.");
        end

        function testOEWReflectsTheSelectedConfiguration(testCase)
            % The decision and the measurement tied together. Unlike
            % testOEWCountsOnlyTheActiveConfiguration, which walks the active
            % CHOICE, this walk descends by the candidate's Selected -- so the
            % number comes from the verdict rather than the configuration. They
            % agree only because the decision was written consistently, which is
            % the property worth measuring.
            r           = testCase.massRollup();
            selectedSum = testCase.leafMassSum("selected");
            testCase.verifyEqual(r.OEW, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "OEW must still be the Brandt " + testCase.ExpectedOEW_lb + " lb.");
            testCase.verifyEqual(selectedSum, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "Summing the leaves under the SELECTED candidates gives " + selectedSum + ...
                " lb. Either a winner carries the wrong PhysicalItem.Mass_lb, or a role " + ...
                "has no winner at all and its whole subtree dropped out of the sum.");
            testCase.verifyEqual(r.OEW, selectedSum, "AbsTol", 0.05, ...
                "The roll-up (" + r.OEW + " lb, which follows the ACTIVE choice) and the " + ...
                "sum over the SELECTED candidates (" + selectedSum + " lb) disagree: the " + ...
                "aircraft is not configured with the candidates the trade chose.");
        end

        % ---------------- Stage 5 audit: provenance is complete ----------

        function testProvenanceDeclaredOnEveryValueBearingStereotype(testCase)
            % WHICH stereotypes owe a DataProvenance at all. Nothing said so,
            % and seven invented numbers sat in the shipped model untagged while
            % the suite stayed green (D-031). FAIL-CLOSED by design: every
            % stereotype the profile DECLARES, minus the exemptions.
            profileNames = testCase.physicalProfileNames();
            testCase.verifyTrue(ismember(testCase.Profile, profileNames), ...
                "The P model does not resolve the " + testCase.Profile + " profile, so " + ...
                "there is no declared stereotype set to reason about. Resolved: {" + ...
                strjoin(profileNames, ", ") + "}.");
            d = testCase.provenanceDeclarationDefects();
            % Non-vacuity from both ends: an empty required set would make the
            % sweep pass while asserting nothing, whether because the profile
            % walk found no stereotypes or the exemptions swallowed them all.
            testCase.verifyNotVacuous(d.Required, ...
                "no stereotype requires provenance");
            testCase.verifyNoOffenders( ...
                setdiff(testCase.KnownValueBearingStereotypes, d.Required), ...
                "These stereotypes carry engineering values a human chose and must be in " + ...
                "the required set, but are not -- either they are no longer declared, or " + ...
                "somebody exempted them, and an exemption is how an invented number stops " + ...
                "being checked");
            testCase.verifyNoOffenders(d.StaleExemption, ...
                "Exempted stereotype is not declared by the profile at all, so the " + ...
                "exemption is stale -- and a stale exemption silently exempts whatever " + ...
                "takes that name next");
            testCase.verifyNoOffenders(d.Undeclared, ...
                "Stereotype carries engineering values but declares no " + ...
                testCase.ProvenanceProperty + " property, so its numbers cannot be tagged " + ...
                "at all -- exactly the D-031 gap. Add the property, or name the " + ...
                "stereotype in ProvenanceExemptStereotypes with a reason");
            testCase.verifyNoOffenders(d.WrongType, ...
                testCase.ProvenanceProperty + " must be typed " + testCase.DataProvenanceClass + ...
                " so the vocabulary is validated rather than free text (D-011); with a " + ...
                "string property 'Estimte' is a valid tag (stereotype -> declared type)");
        end

        function testInventedNumbersAreTagged(testCase)
            % The other half of D-031, the half that reads the MODEL. Declaring
            % DataProvenance means nothing if a component can apply the
            % stereotype and leave the tag unreadable.
            %
            % Then the sharper claim: the seven CompositeFractions and three
            % fuel capacities are tagged ESTIMATE specifically. The fractions
            % were tuned until the mass-weighted figure landed just inside
            % REQ_F16A_022's cap, and a number chosen to make a requirement pass
            % is the last one in the model that may look sourced. The COUNT is
            % pinned to D-030 because tagging is a property of the values and
            % the census is a property of the LOG.
            d = testCase.provenanceTagDefects();
            testCase.verifyNotVacuous(d.Checked, ...
                "no component carries a value-bearing stereotype");
            testCase.verifyNoOffenders(d.Untagged, ...
                "Component carries a stereotype holding chosen engineering values, but " + ...
                "its " + testCase.ProvenanceProperty + " is not one of {" + ...
                strjoin(testCase.DataProvenanceMembers, ", ") + "} (path [stereotype] -> found)");
            c = testCase.estimateCensusDefects();
            testCase.verifyNoOffenders(c.CountMismatch, ...
                "The model carries a different number of invented values than D-030 " + ...
                "inventories; the decision log has to list each one before the census " + ...
                "can match again (D-007, D-030)");
            testCase.verifyNoOffenders(c.NotEstimate, ...
                "These values are invented for teaching and must say so: expected " + ...
                testCase.ProvenanceProperty + " = " + testCase.EstimateProvenance + ...
                ". Tagging one Reference or Datasheet would claim a source that does not " + ...
                "exist (path [stereotype.property] -> found)");
        end

        % ------- The trade study's guard rails ----------------------------
        %
        % These three pin the guards' INPUT CONTRACT against the shipped model
        % -- the DATA half (somebody types 78, or adds a second Reference
        % candidate), which needs a loaded model, which is why it lives here.
        % NONE OF THE GUARDS IS MADE TO FIRE: since D-056 each trade script
        % checks its own parameters inline, and making an inline check fire
        % would mean running the trade, which this suite must not do.

        function testTradeParameterScalesRejectWhatTheyExistToReject(testCase)
            % The negative control for the range sweeps in
            % testCandidatesCarryTradeParameters: a check that can only say yes
            % asserts nothing. It also makes the BOUNDS load-bearing -- without
            % it, the cheapest way to pass an awkward Benefit is to widen
            % BenefitScale and every other assertion stays green. Both
            % directions, because a scale that rejects everything would pass the
            % first half and fail the aeroplane.
            testCase.verifyNoOffenders(testCase.numStrings(testCase.RejectedBenefits( ...
                arrayfun(@(b) testCase.onBenefitScale(b), testCase.RejectedBenefits))), ...
                "The Benefit scale accepts values it exists to reject (0 is the 'unset' " + ...
                "sentinel, 78 is 7.8 with a slipped decimal point -- D-033)");
            testCase.verifyNoOffenders(testCase.numStrings(testCase.AcceptedBenefits( ...
                ~arrayfun(@(b) testCase.onBenefitScale(b), testCase.AcceptedBenefits))), ...
                "The Benefit scale rejects legitimate values; the declared scale is " + ...
                testCase.BenefitScale(1) + ".." + testCase.BenefitScale(2) + " INCLUSIVE");
            testCase.verifyNoOffenders(testCase.numStrings(testCase.RejectedTRLs( ...
                arrayfun(@(t) testCase.onTRLScale(t), testCase.RejectedTRLs))), ...
                "The TRL scale accepts values it exists to reject (0 is D-021's fail-safe " + ...
                "default; 4.5 is not a point on an ordinal maturity scale)");
            testCase.verifyNoOffenders(testCase.numStrings(testCase.AcceptedTRLs( ...
                ~arrayfun(@(t) testCase.onTRLScale(t), testCase.AcceptedTRLs))), ...
                "The TRL scale rejects legitimate values; the declared scale is " + ...
                testCase.TRLScale(1) + ".." + testCase.TRLScale(2) + " inclusive");
        end

        function testRatioBaselineIsUniqueAndNothingBeatsIt(testCase)
            % Two guards checked as preconditions on the shipped data, because
            % they cannot be checked as behaviour.
            %
            % FIRST, the baseline is unique per role: every ratio value function
            % divides by the role's Reference candidate's mass, so none means no
            % scale and two means no answer. Discovered from the PROVENANCE TAG,
            % exactly as the trade study discovers it, so a retagged candidate
            % is caught.
            %
            % SECOND, D-035's ceiling, on the MASS ratio. A failure of this half
            % is not a bug -- D-035 chose to warn rather than cap or error, so
            % it is a tripwire saying the known limit has spread to a second
            % criterion. The honest response is the deferred bounded-value-
            % function fix, not deleting the offending candidate.
            %
            % THIRD, the same ceiling on the THRUST ratio, asserted the other
            % way round: it must be BREACHED. Since D-056 the twin out-thrusts
            % the baseline and scores v > 1, which is what turned D-035 from a
            % dormant check into something the example actually demonstrates.
            % If this ever goes quiet, the run stops warning and the lesson is
            % gone with it.
            d = testCase.baselineDefects();
            testCase.verifyNotVacuous(d.Checked, ...
                "no candidate was scored against a baseline");
            testCase.verifyNoOffenders(d.NoUniqueBaseline, ...
                "A role must have EXACTLY ONE candidate tagged DataProvenance = " + ...
                testCase.BaselineProvenance + "; it is the baseline every ratio value " + ...
                "function divides by (D-015), and the trade study stops rather than guess");
            testCase.verifyNoOffenders(d.AboveCeiling, ...
                "A candidate is LIGHTER THAN ITS ROLE'S BASELINE, so M_baseline/M exceeds " + ...
                "the 1.0 ceiling the declared scales imply and the renormalized weights no " + ...
                "longer describe relative influence (D-035). This is a KNOWN LIMIT, not a " + ...
                "defect in the candidate: nothing is capped, the advantage is real, and " + ...
                "D-035's deferred bounded-value-function fix now has a live case");
            testCase.verifyNotVacuous(d.ThrustAboveCeiling, ...
                "no engine out-thrusts the baseline, so T/T_baseline never exceeds 1.0 and " + ...
                "D-035's ceiling warning cannot fire. The live demonstration of an " + ...
                "unbounded ratio criterion is gone, and with it the reason the engine " + ...
                "trade teaches anything (D-035, D-056)");
        end

        function testNoRoleHasTwoIdenticallyParameterizedCandidates(testCase)
            % The tie guard's precondition. The trade study REFUSES to break a
            % tie for first place -- sort order is not a decision -- so the
            % shipped data must not produce one trivially. Two candidates with
            % identical Benefit, TRL and Mass_lb tie under ANY weighting, and
            % that is the tie a copy-paste in the generator actually produces.
            %
            % IT DOES NOT PROVE THERE IS NO TIE. Different parameters can still
            % score equal, and detecting that needs the score -- which this file
            % will not recompute, because a test that re-derived the trade
            % study's arithmetic would agree with it by construction. The unique
            % winner is asserted from the MODEL, by
            % testTradeSelectedExactlyOneWinnerPerRole.
            testCase.verifyNoOffenders(testCase.duplicateParameterDefects(), ...
                "Two candidates of one role carry identical trade parameters, so they " + ...
                "score identically under any weighting and the role is a tie for first " + ...
                "place. The trade study errors rather than break it. Separate them with " + ...
                "data or add a criterion");
        end

    end

    % =====================================================================
    % P-specific helpers. Everything generic (walks, stereotype and profile
    % readers, reporting) is inherited from F16ATestCase.
    % =====================================================================
    methods (Access = private)

        function rows = massLeafRows(testCase)
            % The 16 mass leaves as a struct array, for the sweeps that want
            % all of them rather than one parameterized case.
            s    = testCase.MassLeafRows;
            keys = string(fieldnames(s))';
            rows = arrayfun(@(k) s.(k), keys);
        end

        function hits = mismatches(~, T, actualCol, expectedCol)
            % "path 'found' -> 'expected'" for every row where two columns of
            % the candidate table disagree.
            off  = T.(actualCol) ~= T.(expectedCol);
            hits = T.Path(off) + " '" + T.(actualCol)(off) + "' -> '" + ...
                T.(expectedCol)(off) + "'";
        end

        function hits = expectProvenance(testCase, comp, what, stereotype, expected)
            % One provenance expectation, as an offender string or empty.
            actual = testCase.provenanceOf(comp, stereotype);
            hits = strings(1,0);
            if actual ~= expected
                hits = what + " (" + stereotype + ") says '" + actual + "', expected '" + ...
                    expected + "'";
            end
        end

        function s = numStrings(~, values)
            % A numeric array as "0", "78", "NaN" for a diagnostic. NOT
            % string(values): string(NaN) is <missing> and strjoin errors on a
            % missing element -- and NaN is one of the values these controls
            % exist to reject.
            s = reshape(compose("%g", values), 1, []);
        end

        function tf = resolves(testCase, pth)
            tf = ~isempty(testCase.componentAt(pth));
        end

        function c = componentAt(testCase, fullPath)
            % A component by its ARCHITECTURE path -- the path space that
            % carries the variant choice level, e.g.
            % .../Airframe/BlendedCrankedDelta/Wing. lookup is tried first; if
            % it cannot cross a variant boundary the getChoices-aware walk
            % resolves the same path. EMPTY when the path names nothing.
            try c = testCase.Model.lookup(Path=char(fullPath)); catch, c = []; end
            if ~isempty(c); return; end
            [comps, paths] = testCase.walkComponents();
            idx = find(paths == erase(string(fullPath), testCase.PhysicalPathPrefix), 1);
            if ~isempty(idx); c = comps{idx}; end
        end

        function v = massOf(testCase, comp)
            % A component's own PhysicalItem.Mass_lb; 0 when it carries none
            % (an assembly, or a variant role wrapper).
            v = testCase.propNum(comp, testCase.Profile + ".PhysicalItem.Mass_lb");
            if isnan(v); v = 0; end
        end

        function n = countComps(testCase)
            % Delegates to walkComponents so there is exactly ONE traversal in
            % this file and no naive recursion left to go stale.
            [comps, ~] = testCase.walkComponents();
            n = numel(comps);
        end

        function txt = rationaleText(testCase, elem, propertyShortName)
            txt = testCase.propOf(elem, testCase.RationaleStereotype, propertyShortName);
        end

        function d = rationaleDefects(testCase)
            % One pass over every stereotypable part, collecting defects by kind
            % so a failure names the offenders instead of stopping at the first.
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
            hits = strings(1,0);
            for nm = partNames
                c = testCase.componentAt(testCase.AC + nm);
                if isempty(c)
                    hits(end+1) = nm + " (not found)"; %#ok<AGROW>
                    continue
                end
                actual = testCase.rationaleText(c, "SourceKind");
                if actual ~= expectedKind
                    hits(end+1) = nm + " -> '" + actual + "'"; %#ok<AGROW>
                end
            end
        end

        function t = declaredPropertyType(testCase, stereotypeShortName, propertyShortName)
            % The declared TYPE of one stereotype property, "" when the
            % stereotype or the property is not declared at all.
            t = "";
            profs = testCase.profilesOf();
            for i = 1:numel(profs)
                st = profs(i).Stereotypes;
                for j = 1:numel(st)
                    if testCase.shortName(string(st(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = st(j).Properties;
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
            % Property.Type names the type -- a built-in or an enumeration
            % class. Normalised so a quoted or package-qualified spelling still
            % compares equal, and so a surprise shape fails on the VALUE rather
            % than erroring out of the test.
            try s = string(rawType); catch, s = string(class(rawType)); end
            n = testCase.shortName(strtrim(erase(s, "'")));
        end

        function names = enumerationMembers(~, className)
            % Members of a MATLAB enumeration class, sorted. Empty when the
            % classdef does not resolve on the path -- itself the failure the
            % caller reports, since an unresolvable enumeration means the
            % property has no vocabulary to validate against.
            names = strings(1,0);
            mc = meta.class.fromName(char(className));
            if isempty(mc); return; end
            members = mc.EnumerationMemberList;
            for i = 1:numel(members)
                names(end+1) = string(members(i).Name); %#ok<AGROW>
            end
            names = sort(names);
        end

        function s = sumMasses(testCase, paths)
            s = 0;
            for pth = paths
                s = s + testCase.massOf(testCase.componentAt(pth));
            end
        end

        function j = justificationOf(testCase, rel)
            j = testCase.rationaleText(testCase.componentAt(testCase.AC + rel), "Justification");
        end

        function a = authoredJustificationOf(testCase, rel)
            % The half a human wrote. The trade study PREPENDS its verdict and
            % separates the two with " || ", so the authored text is what
            % follows the last separator (and the whole string before it ran).
            parts = split(testCase.justificationOf(rel), "||");
            a = strtrim(parts(end));
        end

        function c = criteriaClauseOf(testCase, rel)
            % The "Criteria (D-015): ..." sentence the trade study writes into
            % the rationale -- its own statement of what it scored on.
            tok = regexp(testCase.justificationOf(rel), "Criteria \(D-015\):[^|]*", ...
                "match", "once");
            c = string(tok);
            if ismissing(c); c = ""; end
        end

        function dp = provenanceOf(testCase, comp, stereotype)
            dp = testCase.propOf(comp, stereotype, testCase.ProvenanceProperty);
        end

        function s = sumOfLeafMasses(testCase)
            % OEW as the model states it: the sum of its OWN 16 active leaves.
            % Deliberately NOT the sum of the Brandt figures -- that is the
            % other model, and conflating the two would let a cross-model
            % difference read as an internal inconsistency (or hide one).
            s = testCase.sumMasses(testCase.AC + [testCase.massLeafRows().Path]);
        end

        function w = loadBrandtWeights(testCase)
            % EXECUTE the sizing reference model rather than transcribe it
            % (D-036). No skip and no fallback to literals: falling back would
            % restore the transcription D-036 removed, silently.
            import matlab.unittest.fixtures.PathFixture
            brandtDir = F16APhysicalArchitectureTest.brandtF16ADir();
            testCase.assertTrue(isfolder(brandtDir), ...
                "The Brandt mass ground truth cannot be read: the sizing reference model " + ...
                "was not found at " + brandtDir + ". This suite executes " + ...
                "sizing/VnV/BrandtF16A/BrandtWeight.m, resolved by path rather than " + ...
                "project membership (D-036). It is NOT skipped when absent.");
            % A PathFixture, not a bare addpath: sizing/ is three levels outside
            % the project and leaving it on the path makes results
            % order-dependent (D-047).
            testCase.applyFixture(PathFixture(brandtDir));
            wt = BrandtWeight();   % read-only: computes in memory, writes no file
            wt.analyze();
            w = wt.run(testCase.W_TO_lb);
        end

        function missing = partsWithoutStereotype(testCase, parts, paths, stereotypeShortName)
            missing = strings(1,0);
            for i = 1:numel(parts)
                if ~ismember(stereotypeShortName, testCase.appliedStereotypes(parts{i}))
                    missing(end+1) = paths(i); %#ok<AGROW>
                end
            end
        end

        function d = variantChoiceCountDefects(testCase)
            d = strings(1,0);
            for i = 1:size(testCase.VariantRows,1)
                rel      = string(testCase.VariantRows{i,1});
                expected = testCase.VariantRows{i,3};
                vc = testCase.componentAt(testCase.AC + rel);
                if isempty(vc)
                    d(end+1) = rel + " (not found)"; %#ok<AGROW>
                    continue
                end
                n = numel(testCase.choicesOf(vc));
                if n ~= expected
                    d(end+1) = rel + " holds " + n + ", expected " + expected; %#ok<AGROW>
                end
            end
        end

        function d = activeChoiceDefects(testCase)
            d.NoActive = strings(1,0);
            d.Foreign  = strings(1,0);
            for i = 1:size(testCase.VariantRows,1)
                rel    = string(testCase.VariantRows{i,1});
                vc     = testCase.componentAt(testCase.AC + rel);
                active = testCase.activeChoiceOf(vc);
                if numel(active) ~= 1
                    d.NoActive(end+1) = rel + " (" + numel(active) + " active)";
                    continue
                end
                own = testCase.namesOf(testCase.choicesOf(vc));
                if ~ismember(string(active.Name), own)
                    d.Foreign(end+1) = rel + " -> '" + string(active.Name) + ...
                        "' not among {" + strjoin(own, ", ") + "}";
                end
            end
        end

        function T = candidateTable(testCase)
            % Every trade parameter of every candidate, read once, in one place.
            % Each test then asks a single question of this table instead of
            % re-walking the model.
            %
            % ROLE IS DERIVED FROM THE STEREOTYPE THE CANDIDATE CARRIES, not
            % from a property (D-056 retired RealizesRole). So a candidate given
            % the wrong stereotype reports the wrong role and the Role vs
            % ExpectedRole sweep catches it -- the same failure the old property
            % mismatch caught, one layer earlier.
            %
            % MERIT is whatever criterion is that trade's own: AeroBenefit,
            % HandlingBenefit or Thrust_SL_lb. MeritName says which, so a
            % failure message names the property that was actually read.
            rows = testCase.CandidateRows;
            n = size(rows,1);
            Path = strings(n,1); ExpectedRole = strings(n,1);
            ExpectedKind = strings(n,1); ExpectedProvenance = strings(n,1);
            Found = false(n,1); HasStereotype = false(n,1);
            Stereotype = strings(n,1); Role = strings(n,1); Kind = strings(n,1);
            RoleResolves = false(n,1); KindResolves = false(n,1);
            Mass_lb = nan(n,1); Merit = nan(n,1); MeritName = strings(n,1);
            TRL = nan(n,1); DataProvenance = strings(n,1);
            Selected = false(n,1); SourceKind = strings(n,1);
            ModelledMass_lb = nan(n,1);
            for i = 1:n
                Path(i)               = string(rows{i,1});
                ExpectedRole(i)       = string(rows{i,2});
                ExpectedKind(i)       = string(rows{i,3});
                ExpectedProvenance(i) = string(rows{i,4});
                c = testCase.componentAt(testCase.AC + Path(i));
                Found(i) = ~isempty(c);
                if ~Found(i); continue; end
                [Stereotype(i), Role(i), MeritName(i)] = testCase.candidateStereotypeOf(c);
                HasStereotype(i) = strlength(Stereotype(i)) > 0;
                if ~HasStereotype(i); continue; end
                st = testCase.Profile + "." + Stereotype(i) + ".";
                Kind(i) = testCase.propText(c, st + "RealizesKind");
                % Resolved against the L MODEL, not a list in this file: the
                % claim "this realizes that kind" is only worth anything if the
                % kind is still there under that role.
                RoleResolves(i) = testCase.pathResolves(testCase.LogiModel, ...
                                     testCase.LogicalPathPrefix + Role(i));
                KindResolves(i) = testCase.pathResolves(testCase.LogiModel, ...
                                     testCase.LogicalPathPrefix + Role(i) + "/" + Kind(i));
                Mass_lb(i)        = testCase.propNum(c, st + "Mass_lb");
                Merit(i)          = testCase.propNum(c, st + MeritName(i));
                TRL(i)            = testCase.propNum(c, st + "TRL");
                DataProvenance(i) = testCase.propText(c, st + "DataProvenance");
                Selected(i)       = testCase.propBool(c, st + "Selected");
                SourceKind(i)     = testCase.rationaleText(c, "SourceKind");
                % What the candidate would actually contribute to OEW: its own
                % mass if lumped, the sum of its parts if decomposed.
                ModelledMass_lb(i) = testCase.subtreeLeafMass(c, "all");
            end
            T = table(Path, ExpectedRole, ExpectedKind, ExpectedProvenance, Found, ...
                HasStereotype, Stereotype, Role, Kind, RoleResolves, KindResolves, ...
                Mass_lb, Merit, MeritName, TRL, DataProvenance, Selected, SourceKind, ...
                ModelledMass_lb);
        end

        function [stereo, role, meritName] = candidateStereotypeOf(testCase, comp)
            % Which of the three candidate stereotypes COMP carries, and what
            % that implies. Empty strings when it carries none, so a candidate
            % the generator forgot to stereotype is reported rather than read
            % against a property that does not exist.
            stereo = ""; role = ""; meritName = "";
            applied = testCase.appliedStereotypes(comp);
            for i = 1:size(testCase.CandidateStereotypes,1)
                name = string(testCase.CandidateStereotypes{i,2});
                if ismember(name, applied)
                    stereo    = name;
                    role      = string(testCase.CandidateStereotypes{i,1});
                    meritName = string(testCase.CandidateStereotypes{i,3});
                    return
                end
            end
        end

        function s = leafMassSum(testCase, mode)
            % Total leaf Mass_lb under three readings of what "the aircraft"
            % means at a variant:
            %   "active"   -- getActiveChoice: the aeroplane the model is
            %                 CONFIGURED as. What the roll-up measures.
            %   "selected" -- the candidate's Selected: the aeroplane the trade
            %                 CHOSE, independent of the configuration.
            %   "all"      -- getChoices: what a walk that forgot about variants
            %                 would count. The D-012 failure mode, computed so
            %                 it can be shown NOT to be happening.
            s = 0;
            for c = testCase.Model.Architecture.Components
                s = s + testCase.subtreeLeafMass(c, mode);
            end
        end

        function s = subtreeLeafMass(testCase, comp, mode)
            % Leaves only: assemblies carry no mass of their own, the roll-up
            % overwrites them with the sum of their children.
            if isa(comp, "systemcomposer.arch.VariantComponent")
                branches = testCase.choicesOf(comp);
                if mode == "active";   branches = testCase.activeChoiceOf(comp); end
                if mode == "selected"; branches = testCase.selectedChoices(comp); end
                s = 0;
                for i = 1:numel(branches)
                    s = s + testCase.subtreeLeafMass(branches(i), mode);
                end
                return
            end
            kids = comp.Architecture.Components;
            if isempty(kids); s = testCase.massOf(comp); return; end
            s = 0;
            for k = kids
                s = s + testCase.subtreeLeafMass(k, mode);
            end
        end

        function a = activeAirframeMaterials(testCase)
            % The mass-weighted composite fraction of whichever airframe
            % candidate is ACTIVE, over the parts that candidate actually
            % exposes. Discovering the parts is the point: a hard-coded
            % .../Airframe/Wing would keep working while describing an airframe
            % the aircraft is not configured with.
            a = struct(CompositeFraction = NaN, AirframeMass_lb = 0, ...
                NumParts = 0, ActiveName = "");
            active = testCase.activeChoiceOf(testCase.componentAt(testCase.AC + "Airframe"));
            if numel(active) ~= 1; return; end
            a.ActiveName = string(active.Name);
            parts = active.Architecture.Components;
            a.NumParts = numel(parts);
            if a.NumParts == 0; return; end
            m  = zeros(1, a.NumParts);
            cf = zeros(1, a.NumParts);
            for i = 1:a.NumParts
                m(i)  = testCase.massOf(parts(i));
                cf(i) = testCase.propNum(parts(i), testCase.Profile + ".Material.CompositeFraction");
            end
            a.AirframeMass_lb   = sum(m);
            a.CompositeFraction = sum(m .* cf) / sum(m);
        end

        function names = fuelTankLeafNames(testCase)
            % Names of the parts under FuelSystem that CARRY a FuelTank
            % stereotype, discovered from the model. Deliberately a flat scan of
            % the role's children, not a copy of the roll-up's recursion: if
            % both were written the same way a common mistake would agree with
            % itself.
            names = strings(0,1);
            fs = testCase.componentAt(testCase.AC + "FuelSystem");
            for c = fs.Architecture.Components
                if ismember("FuelTank", testCase.appliedStereotypes(c))
                    names = [names; string(c.Name)]; %#ok<AGROW>
                end
            end
        end

        function hits = rolesWhereBrandtCandidateIsNotLightest(testCase)
            % A RELATIONSHIP, because the competing masses are Estimates and
            % their values are not assertable.
            hits = strings(1,0);
            T = testCase.candidateTable();
            brandt = ["Airframe/" + testCase.BrandtAirframe, ...
                      "Propulsion/Engine/" + testCase.BrandtEngine, ...
                      "FlightControls/" + testCase.BrandtFlightControls];
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                mine = rows.Path(ismember(rows.Path, brandt));
                if numel(mine) ~= 1
                    hits(end+1) = role + " (no single production candidate)"; %#ok<AGROW>
                    continue
                end
                lightest = rows.Path(rows.Mass_lb == min(rows.Mass_lb));
                if ~ismember(mine, lightest)
                    hits(end+1) = role + " (lightest is " + strjoin(lightest, " / ") + ")"; %#ok<AGROW>
                end
            end
        end

        function paths = highestMeritPaths(testCase, role)
            % Best on the criterion that is THIS trade's own -- thrust for the
            % engines, a benefit for the other two. EMPTY when nothing is
            % readable, so a caller can tell "no" apart from "there is nothing
            % to compare".
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.Merit == max(rows.Merit));
        end

        function refs = splitTraceRef(~, txt)
            % One TraceRef may name several things, written "a; b".
            refs = strtrim(split(string(txt), ";"))';
            refs = refs(strlength(refs) > 0);
        end

        function refs = allTraceRefs(testCase)
            refs = strings(1,0);
            [parts, ~] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                refs = [refs, testCase.splitTraceRef( ...
                    testCase.rationaleText(parts{i}, "TraceRef"))]; %#ok<AGROW>
            end
        end

        function bad = unresolvedTraceRefs(testCase)
            % Reported with the part that carries it, so the failure names both
            % ends of the broken link.
            bad = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                for ref = testCase.splitTraceRef(testCase.rationaleText(parts{i}, "TraceRef"))
                    if ~testCase.traceRefResolves(ref)
                        bad(end+1) = paths(i) + " -> '" + ref + "'"; %#ok<AGROW>
                    end
                end
            end
        end

        function tf = traceRefResolves(testCase, ref)
            % Three recognised forms, and ONLY three. Anything else returns
            % false rather than being waved through -- an unrecognised TraceRef
            % is untraceable by definition.
            ref = strtrim(string(ref));
            tf = false;
            if startsWith(ref, testCase.RequirementPrefix)
                tf = ~isempty(testCase.findRequirement(testCase.requirementSetFor(ref), ref));
            elseif startsWith(ref, testCase.LogicalPathPrefix)
                tf = testCase.pathResolves(testCase.LogiModel, ref);
            elseif startsWith(ref, testCase.PhysicalPathPrefix)
                tf = ~isempty(testCase.componentAt(ref));
            end
        end

        function reqSet = requirementSetFor(testCase, ref)
            % Which set OWNS an id. Routing by prefix, so a reference that
            % resolves in the wrong set does not count as resolved.
            reqSet = testCase.OrigSet;
            if startsWith(ref, testCase.RequirementPrefix + "P"); reqSet = testCase.PhysSet; end
            if startsWith(ref, testCase.RequirementPrefix + "L"); reqSet = testCase.LogiSet; end
        end

        function r = findRequirement(~, reqSet, id)
            % find returns EMPTY for an unknown id rather than erroring, which
            % is what makes it usable here.
            try r = find(reqSet, Id=char(id)); catch, r = []; end
        end

        function tf = pathResolves(~, model, pth)
            pth = string(pth);
            tf = false;
            if endsWith(pth, "/") || contains(pth, "//"); return; end
            try c = model.lookup(Path=char(pth)); catch, c = []; end
            tf = ~isempty(c);
        end

        function hits = tanksWithProvenanceOtherThan(testCase, expected)
            hits = strings(1,0);
            for t = testCase.FuelTanks
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                if isempty(c)
                    hits(end+1) = t + " (not found)"; %#ok<AGROW>
                    continue
                end
                actual = testCase.propOf(c, "FuelTank", testCase.ProvenanceProperty);
                if actual ~= expected
                    hits(end+1) = t + " -> '" + actual + "'"; %#ok<AGROW>
                end
            end
        end

        function [srcCounts, dstNames] = allocEndpoints(testCase)
            scenario = testCase.Alloc.getScenario("Scenario 1");
            srcCounts = containers.Map();
            dstNames = string.empty;
            for a = scenario.Allocations
                s = char(a.Source.Name);
                if isKey(srcCounts, s); srcCounts(s) = srcCounts(s) + 1;
                else;                   srcCounts(s) = 1;
                end
                dstNames(end+1) = string(a.Target.Name); %#ok<AGROW>
            end
            dstNames = unique(dstNames);
        end

        function map = allocTargetsByRole(testCase)
            % allocEndpoints counts and de-duplicates; this keeps the PAIRING,
            % which is what "is this candidate realized?" needs.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            map = containers.Map();
            for a = scenario.Allocations
                s = char(a.Source.Name);
                t = string(a.Target.Name);
                if isKey(map, s); map(s) = [map(s), t]; else; map(s) = t; end
            end
        end

        function hits = rolesNotRealizedByAllTheirCandidates(testCase)
            hits = strings(1,0);
            targets = testCase.allocTargetsByRole();
            for i = 1:size(testCase.CandidateRows,1)
                role = string(testCase.CandidateRows{i,2});
                name = testCase.leafName(string(testCase.CandidateRows{i,1}));
                if ~isKey(targets, char(role))
                    hits(end+1) = role + " (realizes nothing) -> " + name; %#ok<AGROW>
                    continue
                end
                if ~ismember(name, targets(char(role)))
                    hits(end+1) = role + " -> " + name; %#ok<AGROW>
                end
            end
        end

        function s = leafName(~, pth)
            parts = split(string(pth), "/");
            s = parts(end);
        end

        function names = leafNames(testCase, paths)
            % Keeps the caller's orientation so a failure message reads in the
            % order the table produced.
            names = strings(size(paths));
            for i = 1:numel(paths)
                names(i) = testCase.leafName(paths(i));
            end
        end

        function r = massRollup(~)
            % Run WITHOUT persisting. The roll-up's normal job includes writing
            % OEW back and saving the model; a test may not modify the artifact
            % it is checking. There is deliberately NO fallback -- if the option
            % is ever renamed this errors, and erroring is right, because the
            % only other call available WRITES AND SAVES F16A_Physical.slx.
            r = F16APhysicalMassRollup(Persist=false);
        end

        function sel = selectedChoices(testCase, vc)
            % The choices the trade SELECTED, read from whichever candidate
            % stereotype each choice carries. Deliberately not getActiveChoice:
            % this is the decision, not the configuration, and the whole value
            % of the "selected" mass walk is that it can disagree with the
            % active one. A choice carrying no candidate stereotype counts as
            % not selected, and is reported by testCandidatesCarryTradeParameters.
            choices = testCase.choicesOf(vc);
            keep = false(1, numel(choices));
            for i = 1:numel(choices)
                stereo = testCase.candidateStereotypeOf(choices(i));
                if strlength(stereo) == 0; continue; end
                keep(i) = testCase.propBool(choices(i), ...
                    testCase.Profile + "." + stereo + ".Selected");
            end
            sel = choices(keep);
        end

        function d = tradeSelectionDefects(testCase)
            d.WrongCount = strings(1,0);
            d.Disagree   = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                rel  = string(testCase.VariantRows{i,1});
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                won  = rows.Path(rows.Selected);
                if numel(won) ~= 1
                    d.WrongCount(end+1) = role + " has " + numel(won) + " selected {" + ...
                        strjoin(testCase.leafNames(won), ", ") + "}";
                    continue
                end
                active = testCase.activeChoiceOf(testCase.componentAt(testCase.AC + rel));
                if numel(active) ~= 1
                    d.Disagree(end+1) = rel + " has " + numel(active) + ...
                        " active choices, so nothing can agree with it";
                    continue
                end
                if string(active.Name) ~= testCase.leafName(won)
                    d.Disagree(end+1) = role + ": Selected='" + testCase.leafName(won) + ...
                        "' but the active choice is '" + string(active.Name) + "'";
                end
            end
        end

        function d = winnerRationaleDefects(testCase)
            % One pass over all seven candidates. Every candidate owes a
            % SourceKind matching its Selected flag; a winner additionally owes
            % a justification of real length that cites a score.
            d.NumWinners        = 0;
            d.WrongKind         = strings(1,0);
            d.ThinJustification = strings(1,0);
            d.NoScore           = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:height(T)
                expected = testCase.AlternativeSourceKind;
                if T.Selected(i); expected = testCase.WinnerSourceKind; end
                if T.SourceKind(i) ~= expected
                    d.WrongKind(end+1) = T.Path(i) + " '" + T.SourceKind(i) + ...
                        "' -> '" + expected + "'";
                end
                if ~T.Selected(i); continue; end
                d.NumWinners = d.NumWinners + 1;
                just = testCase.justificationOf(T.Path(i));
                if strlength(just) < testCase.MinJustificationLength
                    d.ThinJustification(end+1) = T.Path(i) + " (" + strlength(just) + " chars)";
                end
                if isempty(regexp(just, testCase.ScoreTokenPattern, "once"))
                    d.NoScore(end+1) = T.Path(i) + " -> '" + just + "'";
                end
            end
        end

        function names = selectedCandidateNames(testCase)
            % Sorted, so the comparison against ExpectedWinners does not depend
            % on the order CandidateRows happens to list them in.
            T = testCase.candidateTable();
            names = sort(reshape(testCase.leafNames(T.Path(T.Selected)), 1, []));
        end

        function pth = selectedPathInRole(testCase, role)
            % Returns 0 or >1 elements when the decision is missing or
            % duplicated, which the caller reports rather than papering over.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            pth = rows.Path(rows.Selected);
        end

        function paths = highestTRLPaths(testCase, role)
            % Plural on purpose: a tie is a real result and the caller's
            % equality check reports it as one.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.TRL == max(rows.TRL));
        end

        function paths = lowestMassPaths(testCase, role)
            % The numerator of D-015's mass-ratio value function is the role's
            % baseline, so "lightest" and "best on mass" are the same statement.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.Mass_lb == min(rows.Mass_lb));
        end

        function d = decisionRequirementDefects(testCase)
            % Split by kind so "the requirement is gone", "nothing links to it"
            % and "something links to it but not as an implementation" are
            % distinguishable.
            d.Missing      = strings(1,0);
            d.Unlinked     = strings(1,0);
            d.NotImplement = strings(1,0);
            for id = testCase.DecisionRequirements
                r = testCase.findRequirement(testCase.LogiSet, id);
                if isempty(r); d.Missing(end+1) = id; continue; end
                links = testCase.incomingLinks(r);
                if isempty(links); d.Unlinked(end+1) = id; continue; end
                types = testCase.linkTypes(links);
                if ~ismember(testCase.ImplementLinkType, types)
                    d.NotImplement(end+1) = id + " -> {" + strjoin(types, ", ") + "}";
                end
            end
        end

        function links = incomingLinks(~, req)
            % Wrapped so a requirement with no link set at all is reported as
            % unlinked rather than erroring out of the test.
            try links = req.inLinks(); catch, links = []; end
        end

        function n = profileName(~, prof)
            try n = string(prof.Name); catch, n = ""; end
            if ~isscalar(n) || ismissing(n); n = ""; end
        end

        function names = physicalProfileNames(testCase)
            % Used to SCOPE the declared-stereotype set by name: a second
            % profile attached to the model must not widen the set of
            % stereotypes this file demands provenance from.
            profs = testCase.profilesOf();
            names = strings(1, numel(profs));
            for i = 1:numel(profs)
                names(i) = testCase.profileName(profs(i));
            end
        end

        function names = declaredStereotypeNames(testCase)
            % Every stereotype declared by F16A_PhysicalProps, and only that
            % profile. Read from the profile rather than a list here: a list
            % would have to be edited for a new stereotype to be checked, and
            % "somebody forgot to edit the list" is what this test is about.
            names = strings(1,0);
            profs = testCase.profilesOf();
            for i = 1:numel(profs)
                if testCase.profileName(profs(i)) ~= testCase.Profile; continue; end
                st = profs(i).Stereotypes;
                for j = 1:numel(st)
                    names(end+1) = testCase.shortName(string(st(j).Name)); %#ok<AGROW>
                end
            end
            names = reshape(unique(names), 1, []);
        end

        function d = provenanceDeclarationDefects(testCase)
            % The fail-closed set arithmetic, in one place.
            %   Required       -- declared stereotypes MINUS the exemptions.
            %   Undeclared     -- required but has no DataProvenance property.
            %   WrongType      -- has one, but not typed by the enumeration.
            %   StaleExemption -- exempts a stereotype that no longer exists,
            %                     leaving a name primed to exempt whatever is
            %                     called that next.
            declared = testCase.declaredStereotypeNames();
            d.Required       = reshape(setdiff(declared, testCase.ProvenanceExemptStereotypes), 1, []);
            d.StaleExemption = reshape(setdiff(testCase.ProvenanceExemptStereotypes, declared), 1, []);
            d.Undeclared     = strings(1,0);
            d.WrongType      = strings(1,0);
            for i = 1:numel(d.Required)
                stereo = d.Required(i);
                actual = testCase.declaredPropertyType(stereo, testCase.ProvenanceProperty);
                if actual == ""
                    d.Undeclared(end+1) = stereo;
                elseif actual ~= testCase.DataProvenanceClass
                    d.WrongType(end+1) = stereo + " -> '" + actual + "'";
                end
            end
        end

        function d = provenanceTagDefects(testCase)
            % One pass over every stereotype-bearing part. Checked records every
            % (part, stereotype) pair actually examined, so the caller can prove
            % the sweep saw something -- an empty Untagged list means nothing on
            % its own. Uses the SAME computed set as the declaration check, so
            % the two halves of D-031 cannot drift apart.
            d.Checked  = strings(1,0);
            d.Untagged = strings(1,0);
            required = testCase.provenanceDeclarationDefects().Required;
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                applied = testCase.appliedStereotypes(parts{i});
                hits = required(ismember(required, applied));
                for k = 1:numel(hits)
                    where = paths(i) + " [" + hits(k) + "]";
                    d.Checked(end+1) = where;
                    actual = testCase.propOf(parts{i}, hits(k), testCase.ProvenanceProperty);
                    if ~ismember(actual, testCase.DataProvenanceMembers)
                        d.Untagged(end+1) = where + " -> '" + actual + "'";
                    end
                end
            end
        end

        function d = estimateCensusDefects(testCase)
            % D-030's inventory checked against the model two ways: the carriers
            % are DISCOVERED by the walk (so a new one cannot hide) and their
            % number is compared with the inventory (so a new one cannot arrive
            % unrecorded). Every value under these stereotypes is invented, so
            % anything other than Estimate is a provenance overclaim.
            d.CountMismatch = strings(1,0);
            d.NotEstimate   = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for r = 1:size(testCase.InventedEstimateCensus,1)
                stereo    = string(testCase.InventedEstimateCensus{r,1});
                valueProp = string(testCase.InventedEstimateCensus{r,2});
                expected  = testCase.InventedEstimateCensus{r,3};
                carriers  = 0;
                for i = 1:numel(parts)
                    if ~ismember(stereo, testCase.appliedStereotypes(parts{i})); continue; end
                    carriers = carriers + 1;
                    actual = testCase.propOf(parts{i}, stereo, testCase.ProvenanceProperty);
                    if actual ~= testCase.EstimateProvenance
                        d.NotEstimate(end+1) = paths(i) + " [" + stereo + "." + ...
                            valueProp + "] -> '" + actual + "'";
                    end
                end
                if carriers ~= expected
                    d.CountMismatch(end+1) = stereo + "." + valueProp + " is carried by " + ...
                        carriers + " components, D-030 inventories " + expected;
                end
            end
        end

        function s = declaredDefaultText(~, prop)
            % Property.DefaultValue is the STORED MATLAB EXPRESSION -- "NaN",
            % "0", "'Minimize'" -- and for a property carrying units arrives as
            % a [value unit] pair, so the first element is the value. A string
            % literal arrives QUOTED and the quotes come off here.
            try raw = string(prop.DefaultValue); catch, s = ""; return; end
            if isempty(raw); s = ""; return; end
            s = strtrim(erase(raw(1), "'"));
            if ismissing(s); s = ""; end
        end

        function v = declaredPropertyDefault(testCase, stereotypeShortName, propertyShortName)
            % The sibling of declaredPropertyType, and the reason both exist: a
            % default is a claim the profile makes about every element that will
            % ever apply the stereotype, and no amount of reading VALUES off
            % today's components can see it.
            v = "";
            profs = testCase.profilesOf();
            for i = 1:numel(profs)
                st = profs(i).Stereotypes;
                for j = 1:numel(st)
                    if testCase.shortName(string(st(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = st(j).Properties;
                    for k = 1:numel(props)
                        if testCase.shortName(string(props(k).Name)) == propertyShortName
                            v = testCase.declaredDefaultText(props(k));
                            return
                        end
                    end
                end
            end
        end

        function hits = costPropertiesNotDefaultingToNaN(testCase)
            % Reported with what was found, because the values mean different
            % things: '0' is D-021's hole still open, '' is the stereotype or
            % property not being declared at all. Compared case-insensitively --
            % MATLAB accepts nan, NaN and NAN as the same expression.
            hits = strings(1,0);
            for r = 1:size(testCase.CostProperties,1)
                stereo = string(testCase.CostProperties{r,1});
                prop   = string(testCase.CostProperties{r,2});
                actual = testCase.declaredPropertyDefault(stereo, prop);
                if upper(actual) ~= upper(testCase.CostDefault)
                    hits(end+1) = stereo + "." + prop + " -> '" + actual + "'"; %#ok<AGROW>
                end
            end
        end

        function tf = onBenefitScale(testCase, b)
            % THE predicate -- used by the candidate sweep AND by the negative
            % control that proves it can reject, so the control cannot drift
            % away from the rule it is controlling. isfinite first, and
            % short-circuited, so NaN and Inf are rejected here.
            tf = isfinite(b) && b >= testCase.BenefitScale(1) && b <= testCase.BenefitScale(2);
        end

        function tf = onTRLScale(testCase, t)
            % Range AND integrality, because the trade study's guard checks
            % both: TRL is an ordinal maturity level, so 4.5 is not a low
            % reading, it is not a reading at all.
            tf = isfinite(t) && t >= testCase.TRLScale(1) && t <= testCase.TRLScale(2) && ...
                mod(t, 1) == 0;
        end

        function d = baselineDefects(testCase)
            % Per role: find the ratio baseline the way the TRADE STUDY finds it
            % -- by the DataProvenance tag, not by the production names
            % hard-coded here -- require it to be unique, and evaluate D-015's
            % mass value function for every candidate against it. Checked
            % records every candidate actually scored, so the caller can prove
            % the sweep saw something.
            d.NoUniqueBaseline   = strings(1,0);
            d.AboveCeiling       = strings(1,0);
            d.ThrustAboveCeiling = strings(1,0);
            d.Checked            = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                ref  = rows(rows.DataProvenance == testCase.BaselineProvenance, :);
                if height(ref) ~= 1
                    d.NoUniqueBaseline(end+1) = role + " has " + height(ref) + ...
                        " candidates tagged " + testCase.BaselineProvenance + " {" + ...
                        strjoin(reshape(testCase.leafNames(ref.Path), 1, []), ", ") + "}";
                    continue
                end
                baseline = ref.Mass_lb;
                for k = 1:height(rows)
                    d.Checked(end+1) = rows.Path(k);
                    % The value function verbatim from D-015. A zero or negative
                    % mass gives Inf or a negative here and lands in
                    % AboveCeiling; the Mass_lb > 0 sweep reports it first.
                    v = baseline / rows.Mass_lb(k);
                    if v > 1 + testCase.ValueCeilingTol
                        d.AboveCeiling(end+1) = rows.Path(k) + " -> v = " + ...
                            sprintf("%.4f", v) + " (baseline " + ...
                            testCase.leafName(ref.Path) + " = " + baseline + " lb, this " + ...
                            "candidate = " + rows.Mass_lb(k) + " lb)";
                    end
                end
                % The engine trade's second ratio criterion, T/T_baseline. Same
                % value function shape, same unbounded-above problem -- but this
                % one is EXPECTED to breach, which is why it is collected apart
                % from the mass breaches rather than mixed in with them.
                if role ~= "PropulsionSystem"; continue; end
                tBase = ref.Merit;
                for k = 1:height(rows)
                    v = rows.Merit(k) / tBase;
                    if v > 1 + testCase.ValueCeilingTol
                        d.ThrustAboveCeiling(end+1) = rows.Path(k) + " -> v = " + ...
                            sprintf("%.4f", v) + " (baseline " + ...
                            testCase.leafName(ref.Path) + " = " + tBase + " lbf, this " + ...
                            "candidate = " + rows.Merit(k) + " lbf)";
                    end
                end
            end
        end

        function dupes = duplicateParameterDefects(testCase)
            % Compared with a tolerance rather than exact equality: two masses
            % differing in the last bit would separate the candidates
            % arithmetically while being the same number in every sense the
            % trade study cares about.
            dupes = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                for a = 1:height(rows)
                    for b = a+1:height(rows)
                        % Merit is whichever criterion is this trade's own, so
                        % the check follows the split without knowing about it.
                        same = abs(rows.Merit(a)   - rows.Merit(b))   <= 1e-9 && ...
                               abs(rows.TRL(a)     - rows.TRL(b))     <= 1e-9 && ...
                               abs(rows.Mass_lb(a) - rows.Mass_lb(b)) <= 1e-9;
                        if same
                            dupes(end+1) = role + ": " + ...
                                testCase.leafName(rows.Path(a)) + " and " + ...
                                testCase.leafName(rows.Path(b)) + " both carry " + ...
                                rows.MeritName(a) + "=" + rows.Merit(a) + ", TRL=" + ...
                                rows.TRL(a) + ", Mass_lb=" + rows.Mass_lb(a); %#ok<AGROW>
                        end
                    end
                end
            end
        end

        function types = linkTypes(~, links)
            % An unreadable type is surfaced as a token rather than dropped, so
            % an API change shows up in the failure message instead of quietly
            % emptying the list.
            types = strings(1,0);
            for i = 1:numel(links)
                try types(end+1) = string(links(i).Type);   %#ok<AGROW>
                catch, types(end+1) = "<unreadable>";        %#ok<AGROW>
                end
            end
        end
    end

    methods (Static, Access = private)

        function s = massLeafTable()
            %MASSLEAFTABLE The 16 mass-bearing leaves of the ACTIVE configuration.
            %   {Path relative to Aircraft, BrandtWeight property, RelTol}.
            %
            %   NO MASS IS TYPED HERE (D-036). The column that used to hold 16
            %   numbers held a SECOND copy of the generator's, so the test
            %   verified a transcription. The figures come from executing
            %   sizing/VnV/BrandtF16A/BrandtWeight.m; this is the MAPPING
            %   between the two models.
            %
            %   THE TOLERANCES ARE BRANDT'S OWN (tests/test_BrandtWeight.m):
            %   1e-2 where the weight is physics-computed and the reference
            %   spreadsheet's arithmetic differs slightly (its nacelle area uses
            %   3.1516, not pi), 1e-3 where it is an exact algebraic fraction of
            %   W_TO or a flat figure. InletDuct is 3.9x Nacelles and
            %   SecondaryStructure derives from W_structure, so both inherit the
            %   nacelle formula difference and are classed with it.
            leaf = @(p, w, t) struct(Path = p, Prop = w, RelTol = t);
            af   = "Airframe/BlendedCrankedDelta/";
            s = struct( ...
                Wing               = leaf(af + "Wing",           "W_wing_lb",       1e-2), ...
                Fuselage           = leaf(af + "Fuselage",       "W_fuse_lb",       1e-2), ...
                HorizontalTail     = leaf(af + "HorizontalTail", "W_pitch_lb",      1e-3), ...
                VerticalTail       = leaf(af + "VerticalTail",   "W_vert_lb",       1e-3), ...
                Nacelles           = leaf(af + "Nacelles",       "W_nacelles_lb",   1e-2), ...
                Strakes            = leaf(af + "Strakes",        "W_strakes_lb",    1e-3), ...
                Engine             = leaf("Propulsion/Engine/F100_PW_200", "W_engine_lb", 1e-3), ...
                InletDuct          = leaf("Propulsion/InletDuct","W_inlet_duct_lb", 1e-2), ...
                LandingGear        = leaf("LandingGear",         "W_gear_lb",       1e-3), ...
                FlightControls     = leaf("FlightControls/FlyByWire", "W_ctrl_lb",  1e-2), ...
                Avionics           = leaf("Avionics",            "W_avionics_lb",   1e-3), ...
                Electrical         = leaf("Electrical",          "W_elec_lb",       1e-3), ...
                Hydraulics         = leaf("Hydraulics",          "W_hyd_lb",        1e-3), ...
                ECS                = leaf("ECS",                 "W_ECS_lb",        1e-3), ...
                ArmamentSupport    = leaf("ArmamentSupport",     "W_armament_lb",   1e-3), ...
                SecondaryStructure = leaf("SecondaryStructure",  "W_other_lb",      1e-2));
        end

        function d = brandtF16ADir()
            %BRANDTF16ADIR Absolute path to sizing/VnV/BrandtF16A.
            %   Anchored on f16aRoot(), the example's single location anchor, so
            %   it survives this file being moved. sizing/ is three levels above
            %   the example root, a sibling of mbse/.
            avd = fileparts(fileparts(fileparts(f16aRoot())));
            d = fullfile(avd, "sizing", "VnV", "BrandtF16A");
        end
    end
end
