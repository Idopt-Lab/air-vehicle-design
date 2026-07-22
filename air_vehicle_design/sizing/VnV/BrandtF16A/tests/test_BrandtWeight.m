classdef test_BrandtWeight < matlab.unittest.TestCase
% test_BrandtWeight   MATLAB unittest for BrandtWeight (Brandt Wt tab).
%
% Ground-truth values from Brandt-F16-A.xls, Wt tab, W_TO = 31377 lb.
% Tolerance: 1% RelTol for all component weights (accommodates minor
% formula differences vs Excel, e.g., π vs 3.1516 in nacelle area).
%
% Run:  runtests('test_BrandtWeight')

    properties (TestParameter)
        W_TO_gt = {31377};   % Wt!B3
    end

    properties
        geom   BrandtGeometry
        wt     BrandtWeight
        r      struct
    end

    % ------------------------------------------------------------------ %
    %  SETUP
    % ------------------------------------------------------------------ %

    methods (TestMethodSetup)
        function buildObjects(tc)
            addpath(level_brandt_test_src_root());
            tc.geom = BrandtGeometry();
            tc.geom.analyze();
            tc.wt = BrandtWeight(tc.geom);
            tc.wt.analyze();
            tc.r = tc.wt.run(31377);
        end
    end

    % ------------------------------------------------------------------ %
    %  CONSTRUCTOR / SETUP TESTS
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_constructorDefault(tc)
            % No-arg constructor auto-creates and analyzes BrandtGeometry.
            wt2 = BrandtWeight();
            wt2.analyze();
            r2  = wt2.run(31377);
            tc.verifyEqual(r2.W_empty_lb, tc.r.W_empty_lb, 'RelTol', 1e-10);
        end

        function test_analyzeRequiredBeforeRun(tc)
            wt2 = BrandtWeight(tc.geom);
            tc.verifyError(@() wt2.run(31377), 'LevelBrandt:notAnalyzed');
        end

        function test_resultStructFields(tc)
            expected = {'W_wing_lb','W_fuse_lb','W_pitch_lb','W_vert_lb', ...
                'W_nacelles_lb','W_strakes_lb','W_structure_lb','W_engine_lb', ...
                'W_inlet_duct_lb','W_gear_lb','W_ctrl_lb','W_elec_lb', ...
                'W_hyd_lb','W_ECS_lb','W_other_lb','W_avionics_lb', ...
                'W_armament_lb','W_airframe_lb','W_empty_lb','W_fuel_lb','W_TO_lb'};
            actual = fieldnames(tc.r);
            for k = 1:numel(expected)
                tc.verifyTrue(ismember(expected{k}, actual), ...
                    sprintf('Missing field: %s', expected{k}));
            end
        end
    end

    % ------------------------------------------------------------------ %
    %  STRUCTURAL WEIGHT COMPONENTS  (analyze outputs — GT from Wt C9:H9)
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_wingWeight(tc)
            % Wt!C9 = 1785.95 lb
            tc.verifyEqual(tc.r.W_wing_lb, 1785.95, 'RelTol', 0.01, ...
                'Wing weight deviates > 1% from ground truth');
        end

        function test_fuselageWeight(tc)
            % Wt!D9 = 3652.11 lb
            tc.verifyEqual(tc.r.W_fuse_lb, 3652.11, 'RelTol', 0.01, ...
                'Fuselage weight deviates > 1% from ground truth');
        end

        function test_pitchControlWeight(tc)
            % Wt!E9 = 648.00 lb  (exact: k_pitch × S_pitch = 6.0 × 108)
            tc.verifyEqual(tc.r.W_pitch_lb, 648.00, 'RelTol', 0.001, ...
                'Pitch control weight should be exact');
        end

        function test_vertTailWeight(tc)
            % Wt!F9 = 360.00 lb  (exact: k_vert × S_vert = 6.0 × 60)
            tc.verifyEqual(tc.r.W_vert_lb, 360.00, 'RelTol', 0.001, ...
                'Vertical tail weight should be exact');
        end

        function test_nacelleWeight(tc)
            % Wt!G9 = 186.82 lb.  ~0.4% deviation expected (π vs 3.1516).
            tc.verifyEqual(tc.r.W_nacelles_lb, 186.82, 'RelTol', 0.01, ...
                'Nacelle weight deviates > 1% from ground truth');
        end

        function test_strakeWeight(tc)
            % Wt!H9 = 90.00 lb  (exact: k_strake × S_strakes = 4.5 × 20)
            tc.verifyEqual(tc.r.W_strakes_lb, 90.00, 'RelTol', 0.001, ...
                'Strake weight should be exact');
        end

        function test_structureTotal(tc)
            % Wt!B9 = 6722.87 lb  = SUM(C9:H9)
            tc.verifyEqual(tc.r.W_structure_lb, 6722.87, 'RelTol', 0.01, ...
                'W_structure deviates > 1% from ground truth');
        end

        function test_engineWeight(tc)
            % Wt!B11 = 4730.23 lb  (0.199 × 23770)
            tc.verifyEqual(tc.r.W_engine_lb, 4730.23, 'RelTol', 0.001, ...
                'Engine weight should be near-exact');
        end

        function test_inletDuctWeight(tc)
            % Wt!B24 = 3.9 × W_nacelles ≈ 728.60 lb
            tc.verifyEqual(tc.r.W_inlet_duct_lb, 3.9 * tc.r.W_nacelles_lb, ...
                'AbsTol', 1e-6, 'Inlet duct must be exactly 3.9 × W_nacelles');
        end

        function test_structureConsistency(tc)
            % W_structure = sum of six structural components
            W_sum = tc.r.W_wing_lb + tc.r.W_fuse_lb + tc.r.W_pitch_lb ...
                + tc.r.W_vert_lb + tc.r.W_nacelles_lb + tc.r.W_strakes_lb;
            tc.verifyEqual(tc.r.W_structure_lb, W_sum, 'AbsTol', 1e-6, ...
                'W_structure must equal sum of six structural components');
        end
    end

    % ------------------------------------------------------------------ %
    %  W_TO-DEPENDENT COMPONENTS  (run outputs — GT from Wt B23:B31)
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_gearWeight(tc)
            % Wt!B23 = 1066.82 lb  (0.034 × 31377)
            tc.verifyEqual(tc.r.W_gear_lb, 1066.82, 'RelTol', 0.001);
        end

        function test_controlsWeight(tc)
            % Wt!B25 = 472.44 lb  (two-term formula)
            tc.verifyEqual(tc.r.W_ctrl_lb, 472.44, 'RelTol', 0.01);
        end

        function test_electricalWeight(tc)
            % Wt!B26 = 533.41 lb  (0.017 × 31377)
            tc.verifyEqual(tc.r.W_elec_lb, 533.41, 'RelTol', 0.001);
        end

        function test_hydraulicsWeight(tc)
            % Wt!B27 = 367.11 lb  (0.0117 × 31377)
            tc.verifyEqual(tc.r.W_hyd_lb, 367.11, 'RelTol', 0.001);
        end

        function test_ECSweight(tc)
            % Wt!B28 = 360.84 lb  (0.0115 × 31377)
            tc.verifyEqual(tc.r.W_ECS_lb, 360.84, 'RelTol', 0.001);
        end

        function test_otherWeight(tc)
            % Wt!B29 = 2016.86 lb  (0.30 × W_structure)
            tc.verifyEqual(tc.r.W_other_lb, 0.30 * tc.r.W_structure_lb, ...
                'AbsTol', 1e-6, 'W_other must be exactly 0.30 × W_structure');
        end

        function test_avionicsWeight(tc)
            % Wt!B30 = 2541.54 lb  (0.081 × 31377)
            tc.verifyEqual(tc.r.W_avionics_lb, 2541.54, 'RelTol', 0.001);
        end

        function test_armamentWeight(tc)
            % Wt!B31 = 440.00 lb  (0.10 × 4400)
            tc.verifyEqual(tc.r.W_armament_lb, 440.00, 'RelTol', 0.001);
        end
    end

    % ------------------------------------------------------------------ %
    %  SUMMARY WEIGHTS  (GT: OEW=19980.70, W_fuel=6296.30)
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_airframeWeight(tc)
            % Wt!B10 = 15250.47 lb  (structure + systems, engine excluded)
            tc.verifyEqual(tc.r.W_airframe_lb, 15250.47, 'RelTol', 0.01);
        end

        function test_emptyWeight_OEW(tc)
            % Wt!B12 = 19980.70 lb  = W_airframe + W_engine
            tc.verifyEqual(tc.r.W_empty_lb, 19980.70, 'RelTol', 0.01, ...
                'OEW deviates > 1% from ground truth 19980.70 lb');
        end

        function test_fuelWeight(tc)
            % Wt!B6 = 6296.30 lb
            tc.verifyEqual(tc.r.W_fuel_lb, 6296.30, 'RelTol', 0.01, ...
                'W_fuel deviates > 1% from ground truth 6296.30 lb');
        end

        function test_airframeConsistency(tc)
            % W_airframe = W_structure + gear + inlet + ctrl + elec + hyd + ECS + other + avionics + armament
            W_expected = tc.r.W_structure_lb + tc.r.W_gear_lb + tc.r.W_inlet_duct_lb ...
                + tc.r.W_ctrl_lb + tc.r.W_elec_lb + tc.r.W_hyd_lb + tc.r.W_ECS_lb ...
                + tc.r.W_other_lb + tc.r.W_avionics_lb + tc.r.W_armament_lb;
            tc.verifyEqual(tc.r.W_airframe_lb, W_expected, 'AbsTol', 1e-6, ...
                'W_airframe must equal sum of all airframe components');
        end

        function test_OEWconsistency(tc)
            % W_empty = W_airframe + W_engine
            tc.verifyEqual(tc.r.W_empty_lb, tc.r.W_airframe_lb + tc.r.W_engine_lb, ...
                'AbsTol', 1e-6, 'OEW must equal W_airframe + W_engine');
        end

        function test_fuelConsistency(tc)
            % W_fuel = W_TO - perm_payload - exp_payload - W_empty
            W_fuel_expected = tc.r.W_TO_lb - 700 - 4400 - tc.r.W_empty_lb;
            tc.verifyEqual(tc.r.W_fuel_lb, W_fuel_expected, 'AbsTol', 1e-6, ...
                'W_fuel must equal W_TO minus payloads minus OEW');
        end

        function test_WTO_sumVerification(tc)
            % Sum of all weight items = W_TO (Wt B38 = SUM(B16:B37))
            % Components: W_structure + W_engine + W_gear + W_inlet + W_ctrl + W_elec
            %           + W_hyd + W_ECS + W_other + W_avionics + W_armament
            %           + perm_payload + exp_payload + W_fuel
            r = tc.r;
            W_sum = r.W_wing_lb + r.W_fuse_lb + r.W_pitch_lb + r.W_vert_lb ...
                + r.W_nacelles_lb + r.W_strakes_lb + r.W_engine_lb ...
                + r.W_gear_lb + r.W_inlet_duct_lb + r.W_ctrl_lb + r.W_elec_lb ...
                + r.W_hyd_lb + r.W_ECS_lb + r.W_other_lb + r.W_avionics_lb ...
                + r.W_armament_lb + 700 + 4400 + r.W_fuel_lb;
            tc.verifyEqual(W_sum, r.W_TO_lb, 'AbsTol', 1e-4, ...
                'Sum of all weight items must equal W_TO (closure check)');
        end
    end

    % ------------------------------------------------------------------ %
    %  SIZING ITERATION: run() called multiple times
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_runMultipleTimes(tc)
            % run() should be re-callable with different W_TO values.
            r1 = tc.wt.run(31377);
            r2 = tc.wt.run(35000);
            % Geometry-dependent outputs must not change between calls.
            tc.verifyEqual(r2.W_structure_lb, r1.W_structure_lb, 'AbsTol', 1e-6);
            tc.verifyEqual(r2.W_engine_lb,    r1.W_engine_lb,    'AbsTol', 1e-6);
            % W_TO-dependent outputs must scale with W_TO.
            tc.verifyEqual(r2.W_gear_lb, 0.034 * 35000, 'AbsTol', 1e-6);
            tc.verifyEqual(r2.W_empty_lb + r2.W_fuel_lb + 700 + 4400, 35000, 'AbsTol', 1e-4);
        end

        function test_fuelPositive(tc)
            % W_fuel must be positive for a valid W_TO.
            tc.verifyGreaterThan(tc.r.W_fuel_lb, 0);
        end
    end

    % ------------------------------------------------------------------ %
    %  RESULTS STORED AS PROPERTIES
    % ------------------------------------------------------------------ %

    methods (Test)
        function test_propertiesMatchResults(tc)
            % run() stores results as properties AND returns them.
            tc.verifyEqual(tc.wt.W_empty_lb, tc.r.W_empty_lb, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.wt.W_fuel_lb,  tc.r.W_fuel_lb,  'AbsTol', 1e-10);
            tc.verifyEqual(tc.wt.W_TO_lb,    tc.r.W_TO_lb,    'AbsTol', 1e-10);
        end
    end

end
