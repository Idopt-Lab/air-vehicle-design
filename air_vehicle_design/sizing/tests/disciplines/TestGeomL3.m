classdef TestGeomL3 < matlab.unittest.TestCase
%TESTGEOML3  Unit tests for GeomL3 and F16GeomL3.
%
%   Formula references:
%     Lifting surfaces: Roskam, Airplane Design Vol. II, Eq. 12.1
%       S_wet = 2*S_exp*(1 + 0.25*tc_r*(1 + (tc_r/tc_t)*lambda)/(1+lambda))
%     Fuselage: Roskam Vol. II, Eq. 12.3  (same as GeomL2)
%     Duct (frustum): lateral surface of a right circular frustum
%       S_wet = pi*(r1+r2)*sqrt((r2-r1)^2 + L^2)
%
%   Pre-computed F-16A expected component S_wet (F16GeomL3 inputs):
%     Wing:     tc_r=tc_t=0.04, lambda=0.2275, S=196.4
%               2*196.4*(1 + 0.25*0.04) = 2*196.4*1.0100            =  396.7 ft^2
%     HT:       tc_r=0.060, tc_t=0.035, lambda=0.390, S=63.70
%               2*63.70*(1 + 0.25*0.06*(1+1.7143*0.390)/1.390)      =  129.7 ft^2
%     VT:       tc_r=0.053, tc_t=0.030, lambda=0.437, S=54.75
%               2*54.75*(1 + 0.25*0.053*(1+1.7667*0.437)/1.437)     =  111.3 ft^2
%     Fuselage: D=5.0, L=47.5  (same formula as L2)                  =  644.7 ft^2
%     Duct:     D_in=3.4, D_exit=2.9, L=14
%               pi*(1.7+1.45)*sqrt(0.0625+196)                       =  138.6 ft^2
%     Total:                                                           = 1421.0 ft^2
%   Brandt truth: 1371 ft^2.  Difference: +3.7% (within ±15% tolerance;
%   duct dimensions are estimated, not from a primary source).

    properties (Constant)
        TOGW        = 31377
        BRANDT_SWET = 1371.09
        TOL_PCT     = 0.15
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        % --- Roskam Eq. 12.1 formula tests --------------------------------

        function testRoskamPlanformUniformTc(tc)
        % When tc_r == tc_t, the formula reduces to 2*S_exp*(1 + 0.25*tc_r).
        % Inputs: S=200, tc_r=tc_t=0.04, lambda=0.2275
        % Expected: 2*200*(1 + 0.25*0.04) = 2*200*1.0100 = 404.000 ft^2
            g = GeomL3();
            g.S_exposed_wing = 200;
            g.tc_r_wing = 0.04;  g.tc_t_wing = 0.04;  g.lambda_wing = 0.2275;
            expected = 2 * 200 * (1 + 0.25 * 0.04);   % = 404.000 ft^2
            received = g.get_S_wet_wing();
            fprintf('\n    Roskam Eq12.1 (uniform tc=0.04): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'Roskam Eq. 12.1 should reduce to 2*S*(1+0.25*tc_r) when tc_r==tc_t.');
        end

        function testRoskamPlanformVaryingTc(tc)
        % HT inputs: tc_r=0.06, tc_t=0.035, lambda=0.390, S_exp=63.70
        % Expected: 2*63.70*(1 + 0.25*0.06*(1+1.7143*0.390)/1.390)
        %         = 2*63.70*(1 + 0.015*1.6686/1.390)
        %         = 2*63.70*(1 + 0.01800) = 2*63.70*1.01800 = 129.693 ft^2
            g = GeomL3();
            g.S_exposed_HT = 63.70;
            g.tc_r_ht = 0.06;  g.tc_t_ht = 0.035;  g.lambda_HT = 0.390;
            g.D_fus = 5;  g.L_fus = 47.5;
            g.S_exposed_VT=54.75; g.tc_r_vt=0.053; g.tc_t_vt=0.030; g.lambda_VT=0.437;
            g.D_inlet=3.4; g.D_exit=2.9; g.L_duct=14;
            tc_r=0.06; tc_t=0.035; lambda=0.390; S_exp=63.70;
            expected = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda));  % = 129.693 ft^2
            received = g.get_S_wet_HT();
            fprintf('\n    Roskam Eq12.1 HT (varying tc): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'Roskam Eq. 12.1 HT does not match direct formula evaluation.');
        end

        % --- Frustum duct formula tests -----------------------------------

        function testDuctFrustumFormula(tc)
        % F16GeomL3 duct: D_inlet=3.4, D_exit=2.9, L=14
        %   r1=1.7, r2=1.45
        %   (r2-r1)^2 = (-0.25)^2 = 0.0625
        %   sqrt(0.0625 + 196) = sqrt(196.0625) = 14.0022
        %   Expected: pi*(1.7+1.45)*14.0022 = pi*3.15*14.0022 = 138.594 ft^2
            g        = F16GeomL3();
            r1       = 3.4/2;   r2 = 2.9/2;   L = 14.0;
            expected = pi*(r1+r2)*sqrt((r2-r1)^2 + L^2);   % = 138.594 ft^2
            received = g.get_S_wet_duct();
            fprintf('\n    duct frustum: received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'Frustum duct formula does not match expected value.');
        end

        function testDuctCylinderDegenerate(tc)
        % When D_inlet == D_exit = 3.2 ft, frustum reduces to pi*D*L.
        % Expected: pi * 3.2 * 14.0 = 140.743 ft^2
            g = GeomL3();
            g.S_ref=300; g.S_exposed_wing=196; g.tc_r_wing=0.04; g.tc_t_wing=0.04;
            g.lambda_wing=0.2275; g.S_exposed_HT=63.7; g.tc_r_ht=0.06;
            g.tc_t_ht=0.035; g.lambda_HT=0.39; g.S_exposed_VT=54.75;
            g.tc_r_vt=0.053; g.tc_t_vt=0.030; g.lambda_VT=0.437;
            g.D_fus=5; g.L_fus=47.5;
            g.D_inlet = 3.2;   g.D_exit = 3.2;   g.L_duct = 14.0;
            expected = pi * 3.2 * 14.0;   % = 140.743 ft^2
            received = g.get_S_wet_duct();
            fprintf('\n    duct cylinder (D=3.2, L=14): received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'Constant-section duct should give pi*D*L.');
        end

        % --- F-16A component values (formula-level) ----------------------

        function testWingSwet(tc)
        % tc_r=tc_t=0.04, lambda=0.2275, S=196.4
        % Expected: 2*196.4*(1 + 0.25*0.04*(1+1*0.2275)/1.2275)
        %         = 2*196.4*1.0100 = 396.725 ft^2
            g        = F16GeomL3();
            tc_r=0.04; tc_t=0.04; lambda=0.2275; S=196.4;
            expected = 2*S*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda));   % = 396.725 ft^2
            received = g.get_S_wet_wing();
            fprintf('\n    wing S_wet: received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testHTSwet(tc)
        % tc_r=0.060, tc_t=0.035, lambda=0.390, S=63.70
        % Expected: ≈ 129.693 ft^2
            g        = F16GeomL3();
            tc_r=0.060; tc_t=0.035; lambda=0.390; S=63.70;
            expected = 2*S*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda));   % = 129.693 ft^2
            received = g.get_S_wet_HT();
            fprintf('\n    HT S_wet:   received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testVTSwet(tc)
        % tc_r=0.053, tc_t=0.030, lambda=0.437, S=54.75
        % Expected: 2*54.75*(1 + 0.25*0.053*(1+1.7667*0.437)/1.437)
        %         = 2*54.75*(1 + 0.01634) = 2*54.75*1.01634 = 111.290 ft^2
            g        = F16GeomL3();
            tc_r=0.053; tc_t=0.030; lambda=0.437; S=54.75;
            expected = 2*S*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda));   % = 111.290 ft^2
            received = g.get_S_wet_VT();
            fprintf('\n    VT S_wet:   received = %.4f ft^2,  expected = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testFuselageMatchesL2(tc)
        % Fuselage formula is identical to L2 (Roskam Eq. 12.3).
        % Both use D=5.0, L=47.5 → expected ≈ 644.7 ft^2.
            g3       = F16GeomL3();
            g2       = F16GeomL2();
            received = g3.get_S_wet_fuselage();
            expected = g2.get_S_wet_fuselage();
            fprintf('\n    fuselage L3: %.4f ft^2,  L2: %.4f ft^2  (should match)\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'L3 fuselage S_wet should equal L2 for the same D_fus/L_fus inputs.');
        end

        % --- Total S_wet checks ------------------------------------------

        function testTotalSwetWithinTolOfBrandt(tc)
        % Pre-computed total: 396.7+129.7+111.3+644.7+138.6 = 1421.0 ft^2
        % Brandt truth: 1371 ft^2.  Tolerance: ±15% → [1165, 1577] ft^2.
            g        = F16GeomL3();
            received = g.get_S_wet(tc.TOGW);
            lo       = tc.BRANDT_SWET * (1 - tc.TOL_PCT);   % 1165.4 ft^2
            hi       = tc.BRANDT_SWET * (1 + tc.TOL_PCT);   % 1576.8 ft^2
            fprintf('\n    total S_wet L3: received = %.2f ft^2,  Brandt = %.2f ft^2  (%.1f%%)\n', ...
                received, tc.BRANDT_SWET, 100*(received - tc.BRANDT_SWET)/tc.BRANDT_SWET);
            fprintf('    tolerance band: [%.1f, %.1f] ft^2\n', lo, hi);
            tc.verifyGreaterThan(received, lo, ...
                sprintf('Total L3 S_wet %.1f ft^2 is >15%% below Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
            tc.verifyLessThan(received, hi, ...
                sprintf('Total L3 S_wet %.1f ft^2 is >15%% above Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
        end

        function testTotalSwetEqualsSum(tc)
        % get_S_wet() must equal the manual sum of five component methods.
            g      = F16GeomL3();
            manual = g.get_S_wet_wing() + g.get_S_wet_HT() + g.get_S_wet_VT() + ...
                     g.get_S_wet_fuselage() + g.get_S_wet_duct();
            via_method = g.get_S_wet(0);
            fprintf('\n    get_S_wet():    %.6f ft^2\n', via_method);
            fprintf('    component sum:  %.6f ft^2\n', manual);
            tc.verifyEqual(via_method, manual, 'AbsTol', 1e-9);
        end

        function testL3TotalGreaterThanL2Total(tc)
        % L3 adds the duct term (~138.6 ft^2), so L3 total must exceed L2 total.
            g3     = F16GeomL3();
            g2     = F16GeomL2();
            total3 = g3.get_S_wet(0);
            total2 = g2.get_S_wet(0);
            fprintf('\n    L3 total: %.2f ft^2,  L2 total: %.2f ft^2,  diff: +%.2f ft^2 (duct)\n', ...
                total3, total2, total3 - total2);
            tc.verifyGreaterThan(total3, total2, ...
                'L3 total S_wet should exceed L2 (adds duct contribution).');
        end

        % --- W_TO argument ignored at L3 ---------------------------------

        function testGetSwetIgnoresWTO(tc)
            g   = F16GeomL3();
            s0  = g.get_S_wet(0);
            s99 = g.get_S_wet(99999);
            fprintf('\n    get_S_wet(0):      %.6f ft^2\n', s0);
            fprintf('    get_S_wet(99999):  %.6f ft^2  (should match)\n', s99);
            tc.verifyEqual(s0, s99, 'AbsTol', 1e-9);
        end

        % --- S_ref -------------------------------------------------------

        function testGetSref(tc)
        % Expected: 300 ft^2  [T.O. 1F-16A-1, Fig. 1-2]
            g        = F16GeomL3();
            received = g.get_S_ref();
            fprintf('\n    get_S_ref: received = %.2f ft^2,  expected = 300.00 ft^2\n', received);
            tc.verifyEqual(received, 300, 'AbsTol', 1e-9);
        end

        % --- Inheritance / interface compliance --------------------------

        function testIsaGeometryBase(tc)
            g = F16GeomL3();
            tc.verifyTrue(isa(g, 'GeometryBase'));
        end

        function testIsaGeometryModelL3(tc)
            g = F16GeomL3();
            tc.verifyTrue(isa(g, 'GeometryModelL3'));
        end

        function testNotIsaGeometryModelL2(tc)
            g = F16GeomL3();
            tc.verifyFalse(isa(g, 'GeometryModelL2'), ...
                'L3 geometry must NOT inherit from GeometryModelL2.');
        end

        function testIsHandleClass(tc)
            g = F16GeomL3();
            tc.verifyTrue(isa(g, 'handle'));
        end

    end
end
