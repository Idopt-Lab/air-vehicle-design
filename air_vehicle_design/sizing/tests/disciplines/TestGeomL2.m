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
%
%   Component-level Brandt reference [Brandt Geom sheet, via F16Baseline.m
%   b.brandt.S_wet_*]: Wing=392.02 (B14), HT=99.59 (B16), VT=81.69 (B17),
%   Fuselage(more-accurate)=676.33 (D23). HT/VT compare loosely against
%   this framework's formula output because S_exposed_HT/VT here are full
%   T.O. reference planform areas, not Brandt's fuselage-excluded "exposed"
%   areas (49.85/40.89) -- see per-test comments.

    properties (Constant)
        TOGW        = 31377     % lbf    — F-16A Brandt TOGW (passed to get_S_wet; unused by L2)
        BRANDT_SWET = 1371.09   % ft^2   — Brandt F-16A workbook [Main!L3]
        TOL_PCT     = 0.15      % —      — ±15% physical-reasonableness tolerance
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        function testFuselageSwetVsBrandt(tc)
        % Roskam Eq. 12.3 equivalent-diameter fuselage (644.7 ft^2) vs
        % Brandt's "More Accurate Fuselage Swet"  [Geom!D23] = 676.33 ft^2.
        % Difference is the equivalent-diameter approximation (~5%).
            b        = F16Baseline();
            g        = F16GeomL2();
            expected = b.brandt.S_wet_fus_alt;
            received = g.get_S_wet_fuselage();
            fprintf('\n    fuselage S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.1, ...
                'Fuselage S_wet does not match Brandt Geom!D23 within 10%.');
        end

        % --- F-16A component values vs Brandt Geom-sheet truth ------------
        %
        %   [Brandt] Geom sheet component wetted areas (extract_brandt.m,
        %   data.geom_wet), transcribed into F16Baseline.m as b.brandt.S_wet_*.
        %   Wing matches tightly (both use ~the same exposed planform area).
        %   HT/VT diverge because this framework's S_exposed_HT/VT inputs
        %   (63.70/54.75, full T.O. reference planform area) are NOT the
        %   same quantity as Brandt's true "exposed" (fuselage-blanketing
        %   excluded) areas (49.85/40.89) -- a documented input-data gap,
        %   not a formula bug -- so the tolerance below is loose by design.

        function testWingSwet(tc)
        % S_exposed=196.4 ft^2, tc=0.04
        % Formula: 196.4 * (1.977 + 0.52*0.04) = 196.4 * 1.9978 = 392.4 ft^2
        % Brandt:  392.020 ft^2  [Geom!B14] -- tight agreement (~0.1%)
            b        = F16Baseline();
            g        = F16GeomL2();
            expected = b.brandt.S_wet_wing;
            received = g.get_S_wet_wing();
            fprintf('\n    wing S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.03, ...
                'Wing S_wet does not match Brandt Geom!B14 within 3%.');
        end

        function testHTSwet(tc)
        % S_exposed=63.70 ft^2, tc=0.048
        % Formula: 63.70 * (1.977 + 0.52*0.048) = 63.70 * 2.0020 = 127.5 ft^2
        % Brandt:  99.585 ft^2  [Geom!B16] -- loose tolerance; see header note.
            b        = F16Baseline();
            g        = F16GeomL2();
            expected = b.brandt.S_wet_HT;
            received = g.get_S_wet_HT();
            fprintf('\n    HT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.35, ...
                'HT S_wet does not match Brandt Geom!B16 within 35%.');
        end

        function testVTSwet(tc)
        % S_exposed=54.75 ft^2, tc=0.042
        % Formula: 54.75 * (1.977 + 0.52*0.042) = 54.75 * 1.9988 = 109.4 ft^2
        % Brandt:  81.689 ft^2  [Geom!B17] -- loose tolerance; see header note.
            b        = F16Baseline();
            g        = F16GeomL2();
            expected = b.brandt.S_wet_VT;
            received = g.get_S_wet_VT();
            fprintf('\n    VT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.4, ...
                'VT S_wet does not match Brandt Geom!B17 within 40%.');
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

        % --- L_fus (used directly by fidelity_comparison.m) --------------

        function testLfusMatchesTO(tc)
        % L2 exposes L_fus as a plain property (not a method, unlike L1's
        % get_L_fus). Expected: 47.5 ft  [T.O. 1F-16A-1, Fig. 1-2].
            b        = F16Baseline();
            g        = F16GeomL2();
            expected = b.geom.L_fus;   % 47.50 ft [TO Fig. 1-2]
            received = g.L_fus;
            fprintf('\n    L_fus: received = %.2f ft,  expected (TO) = %.2f ft\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'F16GeomL2.L_fus does not match T.O. 1F-16A-1 overall length.');
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
