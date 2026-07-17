classdef TestGeomL2 < matlab.unittest.TestCase
%TESTGEOML2  Unit tests for GeomL2 and F16GeomL2.
%
%   Formula references:
%     Lifting surfaces: Brandt F-16A workbook, Geom sheet, cell B13
%       S_wet = S_exposed * (1.977 + 0.52 * tc)
%     Fuselage: Roskam, Airplane Design Vol. II, Eq. 12.3
%       S_wet = pi*D*L*(1 - 2/lambda_f)^(2/3)*(1 + 1/lambda_f^2)
%       where lambda_f = L/D  (fineness ratio)
%
%   Pre-computed F-16A expected component S_wet (F16GeomL2 inputs):
%     Wing:      196.4 * (1.977 + 0.52*0.04)  = 196.4 * 1.9978  =  392.4 ft^2
%     HT:         63.7 * (1.977 + 0.52*0.048) =  63.7 * 2.0020  =  127.5 ft^2
%     VT:         54.75* (1.977 + 0.52*0.042) =  54.75* 1.9988  =  109.4 ft^2
%     Fuselage:  D=5.0, L=47.5, lambda_f=9.5
%                pi*5*47.5*(1-2/9.5)^(2/3)*(1+1/9.5^2)           =  644.7 ft^2
%     Total:                                                        = 1274.0 ft^2
%   Brandt truth: 1371 ft^2.  Difference: -7.1% (within ±15% tolerance;
%   fuselage equivalent-diameter approximation accounts for most of the gap).

    properties (Constant)
        TOGW        = 31377     % lbf    — F-16A Brandt TOGW (passed to get_S_wet; unused by L2)
        BRANDT_SWET = 1371.09   % ft^2   — Brandt F-16A workbook [Main!L3]
        TOL_PCT     = 0.15      % —      — ±15% physical-reasonableness tolerance
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        % --- Wet planform formula ----------------------------------------

        function testWetPlanformFormulaZeroTc(tc)
        % tc=0: S_wet = S_exp * 1.977
        % Expected: 100 * 1.977 = 197.700 ft^2
            g = GeomL2();
            g.S_exposed_wing = 100;  g.tc_wing = 0;
            expected = 100 * 1.977;   % = 197.700 ft^2
            received = g.get_S_wet_wing();
            fprintf('\n    wet_planform(S=100, tc=0): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testWetPlanformFormulaTypicalTc(tc)
        % tc=0.04: S_wet = S_exp * (1.977 + 0.52*0.04) = S_exp * 1.9978
        % Expected: 200 * 1.9978 = 399.560 ft^2
            g = GeomL2();
            g.S_exposed_wing = 200;  g.tc_wing = 0.04;
            expected = 200 * (1.977 + 0.52 * 0.04);   % = 399.560 ft^2
            received = g.get_S_wet_wing();
            fprintf('\n    wet_planform(S=200, tc=0.04): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        % --- Roskam Eq. 12.3 fuselage formula ----------------------------

        function testFuselageFormulaKnownFineness(tc)
        % D=5, L=50, lambda_f=10:
        %   pi*5*50 = 785.40 ft^2
        %   (1-2/10)^(2/3) = (0.8)^(2/3) = 0.86177
        %   (1 + 1/100) = 1.01000
        %   Expected: 785.40 * 0.86177 * 1.01000 = 683.4 ft^2
            g = GeomL2();
            g.D_fus = 5.0;  g.L_fus = 50.0;
            lambda_f = 50.0 / 5.0;   % = 10
            expected = pi * 5.0 * 50.0 * (1 - 2/lambda_f)^(2/3) * (1 + 1/lambda_f^2);  % = 683.4 ft^2
            received = g.get_S_wet_fuselage();
            fprintf('\n    fuselage(D=5, L=50, lf=10): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testFuselageFormulaF16(tc)
        % D=5.0, L=47.5, lambda_f = 47.5/5.0 = 9.5:
        %   pi*5*47.5 = 745.35 ft^2
        %   (1-2/9.5)^(2/3) = (0.7895)^(2/3) = 0.85425
        %   (1 + 1/9.5^2) = 1.01108
        %   Expected: 745.35 * 0.85425 * 1.01108 = 644.7 ft^2
            g        = F16GeomL2();
            lambda_f = 47.5 / 5.0;   % = 9.5
            expected = pi * 5.0 * 47.5 * (1 - 2/lambda_f)^(2/3) * (1 + 1/lambda_f^2);  % = 644.7 ft^2
            received = g.get_S_wet_fuselage();
            fprintf('\n    fuselage(D=5, L=47.5, lf=9.5): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'F16GeomL2 fuselage S_wet does not match Roskam Eq. 12.3.');
        end

        % --- F-16A component values (formula-level) ----------------------

        function testWingSwet(tc)
        % S_exposed=196.4 ft^2, tc=0.04
        % Expected: 196.4 * (1.977 + 0.52*0.04) = 196.4 * 1.9978 = 392.4 ft^2
            g        = F16GeomL2();
            expected = 196.4 * (1.977 + 0.52 * 0.04);   % = 392.4 ft^2
            received = g.get_S_wet_wing();
            fprintf('\n    wing S_wet: received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'Wing S_wet does not match Brandt cell B13 formula for F-16A inputs.');
        end

        function testHTSwet(tc)
        % S_exposed=63.70 ft^2, tc=0.048
        % Expected: 63.70 * (1.977 + 0.52*0.048) = 63.70 * 2.0020 = 127.5 ft^2
            g        = F16GeomL2();
            expected = 63.70 * (1.977 + 0.52 * 0.048);   % = 127.5 ft^2
            received = g.get_S_wet_HT();
            fprintf('\n    HT S_wet:   received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testVTSwet(tc)
        % S_exposed=54.75 ft^2, tc=0.042
        % Expected: 54.75 * (1.977 + 0.52*0.042) = 54.75 * 1.9988 = 109.4 ft^2
            g        = F16GeomL2();
            expected = 54.75 * (1.977 + 0.52 * 0.042);   % = 109.4 ft^2
            received = g.get_S_wet_VT();
            fprintf('\n    VT S_wet:   received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        % --- Total S_wet (physical-reasonableness check) -----------------

        function testTotalSwetWithinTolOfBrandt(tc)
        % Pre-computed total: 392.4 + 127.5 + 109.4 + 644.7 = 1274.0 ft^2
        % Brandt truth: 1371 ft^2.  Tolerance: ±15% → [1165, 1577] ft^2.
            g       = F16GeomL2();
            received = g.get_S_wet(tc.TOGW);
            lo      = tc.BRANDT_SWET * (1 - tc.TOL_PCT);   % 1165.4 ft^2
            hi      = tc.BRANDT_SWET * (1 + tc.TOL_PCT);   % 1576.8 ft^2
            fprintf('\n    total S_wet: received = %.2f ft^2,  Brandt = %.2f ft^2  (%.1f%%)\n', ...
                received, tc.BRANDT_SWET, 100*(received - tc.BRANDT_SWET)/tc.BRANDT_SWET);
            fprintf('    tolerance band: [%.1f, %.1f] ft^2\n', lo, hi);
            tc.verifyGreaterThan(received, lo, ...
                sprintf('Total S_wet %.1f ft^2 is more than 15%% below Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
            tc.verifyLessThan(received, hi, ...
                sprintf('Total S_wet %.1f ft^2 is more than 15%% above Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
        end

        function testTotalSwetEqualsSum(tc)
        % get_S_wet() must equal the manual sum of the four component methods.
            g      = F16GeomL2();
            manual = g.get_S_wet_wing() + g.get_S_wet_HT() + ...
                     g.get_S_wet_VT()  + g.get_S_wet_fuselage();
            via_method = g.get_S_wet(0);
            fprintf('\n    get_S_wet():      %.6f ft^2\n', via_method);
            fprintf('    component sum:    %.6f ft^2\n', manual);
            tc.verifyEqual(via_method, manual, 'AbsTol', 1e-9, ...
                'get_S_wet() is not the sum of its four component methods.');
        end

        % --- W_TO argument accepted but ignored --------------------------

        function testGetSwetIgnoresWTO(tc)
            g    = F16GeomL2();
            s0   = g.get_S_wet(0);
            s99  = g.get_S_wet(99999);
            fprintf('\n    get_S_wet(0):      %.6f ft^2\n', s0);
            fprintf('    get_S_wet(99999):  %.6f ft^2  (should match)\n', s99);
            tc.verifyEqual(s0, s99, 'AbsTol', 1e-9, ...
                'L2 get_S_wet should be independent of W_TO argument.');
        end

        % --- S_ref -------------------------------------------------------

        function testGetSref(tc)
        % Expected: 300 ft^2  [T.O. 1F-16A-1, Fig. 1-2]
            g        = F16GeomL2();
            received = g.get_S_ref();
            fprintf('\n    get_S_ref: received = %.2f ft^2,  expected = 300.00 ft^2\n', received);
            tc.verifyEqual(received, 300, 'AbsTol', 1e-9);
        end

        % --- Inheritance / interface compliance --------------------------

        function testIsaGeometryBase(tc)
            g = F16GeomL2();
            tc.verifyTrue(isa(g, 'GeometryBase'));
        end

        function testIsaGeometryModelL2(tc)
            g = F16GeomL2();
            tc.verifyTrue(isa(g, 'GeometryModelL2'));
        end

        function testNotIsaGeometryModelL1(tc)
        % L2 does NOT inherit from the L1 enforcer.
            g = F16GeomL2();
            tc.verifyFalse(isa(g, 'GeometryModelL1'), ...
                'L2 geometry must NOT inherit from GeometryModelL1.');
        end

        function testIsHandleClass(tc)
            g = F16GeomL2();
            tc.verifyTrue(isa(g, 'handle'));
        end

    end
end
