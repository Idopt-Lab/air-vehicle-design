classdef F16ABaselineTest < matlab.unittest.TestCase
    %F16ABASELINETEST The F-16A numbers have not moved.
    %   Re-runs every analysis in the example -- the three trade studies, the
    %   mass, materials and fuel roll-ups, the mission and the cost model --
    %   without writing to any model, and compares each result with the
    %   baseline recorded below. The last test checks the Measures of Merit
    %   stored on the Physical model, which is what a student actually sees.
    %
    %   A failure means a number changed. If the change was intended, update
    %   the baseline here in the same commit; if not, it is a regression.
    %
    %   Run: run_ai_tests, or runtests("F16ABaselineTest").

    properties (Constant)
        % The analyses are deterministic, so any real change is far larger.
        RelTol = 1e-6

        Baseline = struct( ...
            "OEW_lb",            19980.73, ...
            "CompositeFraction", 0.1927513952, ...
            "Fuel_lb",           6300, ...
            "MissionFuel_lb",    5959.801726, ...
            "MissionTime_min",   93.99836725, ...
            "UnitCost_USD",      68470498.58, ...
            "OMCostAnnual_USD",  1238649.825, ...
            "OMCostLife_USD",    24772996.49, ...
            "LifeCycleCost_USD", 93243495.07)
    end

    properties (TestParameter)
        % Each trade: its candidates best first, their scores, and where the
        % decision shows in P (active candidate) and in L (active kind).
        Trade = struct( ...
            "Engine", struct("Run", @F16AEngineTradeStudy, ...
                "Candidates", ["F100_PW_200", "TwinEngine_Surrogate", "LowThrustSingle_Surrogate"], ...
                "Scores",     [0.95625, 0.881304878030343, 0.689361216849382], ...
                "PVariant",   "Aircraft/Propulsion/Engine", ...
                "LRole",      "PropulsionSystem", ...
                "Kind",       "SingleEngine"), ...
            "Airframe", struct("Run", @F16AAirframeTradeStudy, ...
                "Candidates", ["BlendedCrankedDelta", "ConventionalTrapWing"], ...
                "Scores",     [0.9125, 0.773985616438356], ...
                "PVariant",   "Aircraft/Airframe", ...
                "LRole",      "Airframe", ...
                "Kind",       "BlendedCrankedDelta"), ...
            "FlightControls", struct("Run", @F16AFlightControlsTradeStudy, ...
                "Candidates", ["FlyByWire", "HydroMechanical"], ...
                "Scores",     [0.85625, 0.718728571428571], ...
                "PVariant",   "Aircraft/FlightControls", ...
                "LRole",      "FlightControlSystem", ...
                "Kind",       "FlyByWire"))
    end

    methods (TestClassSetup)
        function closeWhatThisSuiteOpens(testCase)
            % Models the user already had open stay open.
            before = string(find_system("type", "block_diagram"));
            testCase.addTeardown(@() closeAllBut(before));
            % The mission reference is cached; start from a fresh run.
            F16AMissionReference(Reset=true);
        end
    end

    methods (Test)

        function testTradeStudy(testCase, Trade)
            ranked = quiet(@() Trade.Run("Record", false));
            testCase.verifyEqual(ranked.Candidate.', Trade.Candidates, "Ranking changed.");
            testCase.verifyEqual(ranked.Score.', Trade.Scores, "RelTol", testCase.RelTol);
            testCase.verifyEqual(activeChoice("F16A_Physical", Trade.PVariant), ...
                Trade.Candidates(1), "P does not show the winning candidate.");
            testCase.verifyEqual(activeChoice("F16A_Logical", Trade.LRole), ...
                Trade.Kind, "L does not show the winning kind.");
        end

        function testMassRollup(testCase)
            r = quiet(@() F16APhysicalMassRollup(Persist=false));
            testCase.verifyBaseline(r.OEW, "OEW_lb");
        end

        function testMaterialsRollup(testCase)
            r = quiet(@F16APhysicalMaterialsRollup);
            testCase.verifyBaseline(r.CompositeFraction, "CompositeFraction");
        end

        function testFuelRollup(testCase)
            r = quiet(@F16APhysicalFuelRollup);
            testCase.verifyBaseline(r.AvailableFuel_lb, "Fuel_lb");
        end

        function testMissionAnalysis(testCase)
            r = quiet(@F16AMissionAnalysis);
            testCase.verifyBaseline(r.TotalFuel_lb,  "MissionFuel_lb");
            testCase.verifyBaseline(r.TotalTime_min, "MissionTime_min");
        end

        function testCostModel(testCase)
            m = systemcomposer.loadModel("F16A_Physical");
            r = quiet(@() F16APhysicalCostModel(m));
            for name = ["UnitCost_USD", "OMCostAnnual_USD", "OMCostLife_USD", "LifeCycleCost_USD"]
                testCase.verifyBaseline(r.(name), name);
            end
        end

        function testModelShowsTheseNumbers(testCase)
            % The Measures of Merit stored on the aircraft. These go stale
            % when a model is edited and its analyses are not re-run.
            m  = systemcomposer.loadModel("F16A_Physical");
            ac = lookup(m, Path="F16A_Physical/Aircraft");
            for name = ["OEW_lb", "MissionFuel_lb", "MissionTime_min", "UnitCost_USD", ...
                        "OMCostAnnual_USD", "OMCostLife_USD", "LifeCycleCost_USD"]
                stored = str2double(string(getProperty(ac, ...
                    "F16A_PhysicalProps.MeasureOfMerit." + name)));
                testCase.verifyBaseline(stored, name);
            end
        end

    end

    methods (Access = private)
        function verifyBaseline(testCase, actual, name)
            testCase.verifyEqual(actual, testCase.Baseline.(name), ...
                name + " moved off its baseline.", "RelTol", testCase.RelTol);
        end
    end
end

% =====================================================================
function out = quiet(fn) %#ok<STOUT,INUSD> evalc assigns both
%QUIET Run an analysis without its printed walk-through in the test log.
evalc("out = fn();");
end

function name = activeChoice(modelName, path)
m = systemcomposer.loadModel(modelName);
name = string(getActiveChoice(lookup(m, Path=modelName + "/" + path)).Name);
end

function closeAllBut(keep)
for name = setdiff(string(find_system("type", "block_diagram")), keep).'
    bdclose(name);
end
end
