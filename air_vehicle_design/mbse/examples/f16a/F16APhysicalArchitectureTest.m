classdef F16APhysicalArchitectureTest < matlab.unittest.TestCase
    %F16APHYSICALARCHITECTURETEST Verify the F-16A Physical-layer model.
    %   Checks the physical decomposition, the PhysicalItem masses, the mass
    %   roll-up (Operating Empty Weight) for self-consistency, the two
    %   Measures of Merit (OEW and unit cost, both to MINIMIZE), the
    %   realization allocation (logical role -> physical part), and that the
    %   reclassified cost MoM REQ_F16A_026 is homed at P.
    %
    %   By design there are NO pass/fail assertions against a weight or cost
    %   target: OEW and cost are objectives to minimize, not thresholds. The
    %   roll-up test checks self-consistency (parent == sum of children).

    properties
        Model      % F16A_Physical
        LogiModel  % F16A_Logical (realization source)
        OrigSet    % f16a.slreqx (REQ_F16A_026 cost MoM homes here)
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
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = fileparts(mfilename("fullpath"));
            addpath(thisDir);
            addpath(fullfile(thisDir, "physical"));
            addpath(fullfile(thisDir, "logical"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            try, systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Physical");
            testCase.LogiModel = systemcomposer.loadModel("F16A_Logical");
            testCase.OrigSet   = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.Alloc     = systemcomposer.allocation.load("F16A_LogicalToPhysical");
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testPhysicalComponentsExist(testCase)
            % 20 components; root holds one Aircraft; Aircraft holds 11
            % assemblies; Airframe has 6 parts; Propulsion has 2.
            testCase.verifyEqual(testCase.countComps(testCase.Model.Architecture), 20, ...
                "Expected 20 components (Aircraft + 11 assemblies + 8 parts).");
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 1, ...
                "Root should hold exactly one component (Aircraft).");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyEqual(numel(ac.Architecture.Components), 11, ...
                "Aircraft should hold 11 assemblies.");
            af = testCase.Model.lookup(Path=char(testCase.AC + "Airframe"));
            testCase.verifyEqual(numel(af.Architecture.Components), 6, "Airframe should have 6 parts.");
            pr = testCase.Model.lookup(Path=char(testCase.AC + "Propulsion"));
            testCase.verifyEqual(numel(pr.Architecture.Components), 2, "Propulsion should have 2 parts.");
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
            leafAsm = setdiff(testCase.Assemblies, ["Airframe","Propulsion"]);
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

    end

    methods (Access = private)
        function tf = resolves(testCase, pth)
            tf = true;
            try, testCase.Model.lookup(Path=char(pth)); catch, tf = false; end
        end

        function n = countComps(~, arch)
            n = F16APhysicalArchitectureTest.countCompsStatic(arch);
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

    methods (Static, Access = private)
        function n = countCompsStatic(arch)
            n = 0;
            for c = arch.Components
                n = n + 1 + F16APhysicalArchitectureTest.countCompsStatic(c.Architecture);
            end
        end
    end
end
