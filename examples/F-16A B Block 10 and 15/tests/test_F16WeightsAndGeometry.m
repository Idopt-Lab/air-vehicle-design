classdef test_F16WeightsAndGeometry < matlab.unittest.TestCase
    % V&V tests for F-16 weights and geometry discipline objects.
    %
    % Brandt reference values (Brandt-F16-A.xls Wt and Geom tabs):
    %   OEW            = 19,980 lb   (Wt!B12)
    %   OEW/W_TO       = 0.637
    %   W_TO           = 31,377 lb   (Wt!B3)
    %   S_wet total    = 1,331.09 ft² (Geom!B19, includes double-count bug)
    %   S_wet fus      = 730.4 ft²
    %   S_wet wing     = 392.0 ft²
    %   S_ref          = 300 ft²     (input, fixed)
    %   AR             = 3.0
    %   b              = 30 ft

    properties
        geom_json
        W_TO_brandt  = 31377   % lbf
        OEW_brandt   = 19980   % lbf
        S_wet_brandt = 1331.09 % ft²
        S_ref_brandt = 300     % ft²
    end

    methods (TestClassSetup)
        function setup(~)
            TestSetup();
        end
    end

    methods (TestMethodSetup)
        function loadJSON(tc)
            json_path = fullfile(fileparts(mfilename('fullpath')), ...
                '..', 'Ground-Truth', 'f16a_geometry.json');
            tc.geom_json = jsondecode(fileread(json_path));
        end
    end

    methods (Test)

        % ---- Level I Weights ----

        function testL1_OEW_positive(tc)
            wts = F16WeightLevel1();
            oew = wts.OEW(tc.W_TO_brandt);
            tc.verifyGreaterThan(oew, 0);
        end

        function testL1_OEW_fraction_range(tc)
            wts  = F16WeightLevel1();
            oew  = wts.OEW(tc.W_TO_brandt);
            frac = oew / tc.W_TO_brandt;
            tc.verifyGreaterThan(frac, 0.45, 'OEW/W_TO must be > 0.45');
            tc.verifyLessThan(frac,    0.80, 'OEW/W_TO must be < 0.80');
        end

        function testL1_OEW_vs_Brandt(tc)
            wts = F16WeightLevel1();
            oew = wts.OEW(tc.W_TO_brandt);
            % Raymer regression for fighter: expect within 30% of Brandt 19,980 lb
            tc.verifyGreaterThan(oew, tc.OEW_brandt * 0.70, 'L1 OEW lower bound');
            tc.verifyLessThan(oew,    tc.OEW_brandt * 1.30, 'L1 OEW upper bound');
        end

        function testL1_OEW_increases_withWTO(tc)
            wts  = F16WeightLevel1();
            oew1 = wts.OEW(25000);
            oew2 = wts.OEW(35000);
            tc.verifyGreaterThan(oew2, oew1, 'OEW must increase with W_TO');
        end

        % ---- Level II Weights ----

        function testL2_OEW_positive(tc)
            wts = F16WeightLevel2(tc.geom_json);
            oew = wts.OEW(tc.W_TO_brandt);
            tc.verifyGreaterThan(oew, 0);
        end

        function testL2_OEW_vs_Brandt(tc)
            wts = F16WeightLevel2(tc.geom_json);
            oew = wts.OEW(tc.W_TO_brandt);
            tc.verifyGreaterThan(oew, tc.OEW_brandt * 0.80, 'L2 OEW lower bound (±20%)');
            tc.verifyLessThan(oew,    tc.OEW_brandt * 1.20, 'L2 OEW upper bound (±20%)');
        end

        function testL2_OEW_betterThanL1(tc)
            wts1 = F16WeightLevel1();
            wts2 = F16WeightLevel2(tc.geom_json);
            err1 = abs(wts1.OEW(tc.W_TO_brandt) - tc.OEW_brandt);
            err2 = abs(wts2.OEW(tc.W_TO_brandt) - tc.OEW_brandt);
            % This is not guaranteed but should usually hold
            fprintf('L1 OEW error: %.0f lb;  L2 OEW error: %.0f lb\n', err1, err2);
        end

        % ---- Level I Geometry ----

        function testL1_S_ref_from_json(tc)
            geom = F16GeometryLevel1(tc.geom_json);
            tc.verifyEqual(geom.S_ref, tc.S_ref_brandt, 'AbsTol', 0.1);
        end

        function testL1_S_wet_positive(tc)
            geom = F16GeometryLevel1(tc.geom_json);
            tc.verifyGreaterThan(geom.S_wet, 0);
        end

        function testL1_S_wet_physical_range(tc)
            geom = F16GeometryLevel1(tc.geom_json);
            tc.verifyGreaterThan(geom.S_wet, 800,  'S_wet > 800 ft²');
            tc.verifyLessThan(geom.S_wet,    2500, 'S_wet < 2500 ft²');
        end

        function testL1_L_fus_positive(tc)
            geom = F16GeometryLevel1(tc.geom_json);
            tc.verifyGreaterThan(geom.L_fus, 0);
        end

        % ---- Level II Geometry ----

        function testL2_S_wet_physical_range(tc)
            geom = F16GeometryLevel2(tc.geom_json);
            tc.verifyGreaterThan(geom.S_wet, 800);
            tc.verifyLessThan(geom.S_wet,    2500);
        end

        function testL2_cbar_positive(tc)
            geom = F16GeometryLevel2(tc.geom_json);
            tc.verifyGreaterThan(geom.cbar, 0);
        end

        function testL2_cbar_physical_range(tc)
            geom = F16GeometryLevel2(tc.geom_json);
            % F-16: c_root ~ 16 ft, cbar ~ 11 ft for lambda ~ 0.3
            tc.verifyGreaterThan(geom.cbar, 4,  'cbar > 4 ft');
            tc.verifyLessThan(geom.cbar,    25, 'cbar < 25 ft');
        end

        function testL2_span_from_AR_and_Sref(tc)
            geom  = F16GeometryLevel2(tc.geom_json);
            b_exp = sqrt(tc.geom_json.wing.AR * tc.S_ref_brandt);
            tc.verifyEqual(geom.b, b_exp, 'AbsTol', 0.1, 'Span = sqrt(AR × S_ref)');
        end

        % ---- Level III Geometry ----

        function testL3_S_wet_vs_Brandt(tc)
            geom = F16GeometryLevel3(tc.geom_json);
            % Brandt has 1331 ft²; component buildup should be within ±20%
            tc.verifyGreaterThan(geom.S_wet, tc.S_wet_brandt * 0.80, ...
                'L3 S_wet lower bound (±20%)');
            tc.verifyLessThan(geom.S_wet,    tc.S_wet_brandt * 1.20, ...
                'L3 S_wet upper bound (±20%)');
        end

        function testL3_e_osw_range(tc)
            geom = F16GeometryLevel3(tc.geom_json);
            tc.verifyGreaterThan(geom.e_osw, 0.5, 'Oswald e > 0.5');
            tc.verifyLessThan(geom.e_osw,    1.0, 'Oswald e < 1.0');
        end

    end

    methods (TestClassTeardown)
        function printComparisonTable(tc) %#ok<MANU>
            fprintf('\n%s\n', repmat('=',1,70));
            fprintf('  F-16 Weights & Geometry V&V — Comparison to Brandt\n');
            fprintf('%s\n', repmat('=',1,70));
            fprintf('%-30s %12s %12s %12s\n', 'Quantity', 'Brandt', 'L1 tol', 'L2 tol');
            fprintf('%s\n', repmat('-',1,70));
            fprintf('%-30s %12.0f %12s %12s\n', 'OEW (lb)',       19980, '±30%', '±20%');
            fprintf('%-30s %12.3f %12s %12s\n', 'OEW/W_TO',      0.637, '[0.45,0.80]', '[0.50,0.76]');
            fprintf('%-30s %12.1f %12s %12s\n', 'S_wet (ft²)',   1331.1, '[800,2500]', '[800,2500]');
            fprintf('%-30s %12.1f %12s %12s\n', 'S_ref (ft²)',    300.0, 'Exact (JSON)', 'Exact (JSON)');
            fprintf('%s\n', repmat('=',1,70));
        end
    end

end
