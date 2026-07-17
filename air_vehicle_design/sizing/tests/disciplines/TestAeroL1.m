classdef TestAeroL1 < matlab.unittest.TestCase
     %TESTAERO L1  Unit tests for AeroL1 toolbox and F16AeroL1 student class.
     %
     %   Formula references:
     %     CD0 = Cf * S_wet / S_ref               Raymer 6th ed. §12.3
     %     e   = 4.61*(1-0.045*AR^0.68)*cos(LE)^0.15 - 3.1  Raymer Eq. 12.49
     %     K1_sub = 1/(pi*AR*e)                   Raymer Eq. 12.50
     %     K1_sup = AR*beta*cos(LE)/(4*AR*beta-2) Raymer Eq. 12.51
     %     K2_sub = -2*K1_sub*CL_minD             Brandt §4.3
     %     K2_sup = 0                             linearized supersonic theory
     %
     %   Pre-computed F-16A expected values:
     %     AR=3.0, Lambda_LE=40 deg, S_wet=1371 ft^2, S_ref=300 ft^2
     %
     %     CD0 = 0.0035 * 1371/300 = 0.016002
     %
     %     e:  3^0.68 = 2.1107,  0.045*2.1107 = 0.09498,  1-0.09498 = 0.9050
     %         cos(40)^0.15 = 0.9607
     %         e = 4.61 * 0.9050 * 0.9607 - 3.1 = 4.0080 - 3.1 = 0.9080
     %
     %     K1_sub = 1/(pi*3*0.9080) = 0.11687
     %
     %     K1_sup at M=1.5:
     %         beta = sqrt(1.5^2-1) = 1.11803
     %         K1 = 3*1.11803*cos(40)/(4*3*1.11803-2)
     %            = 3*1.11803*0.76604/(13.4164-2) = 2.5701/11.4164 = 0.22512
     %
     %     K2_sub = -2*0.11687*0.0 = 0.0 (CL_minD=0 for F-16 at L1)
     %     K2_sup = 0  (supersonic)

     properties (Constant)
          TOGW    = 31377    % lbf  — F-16A Brandt TOGW
          TOL_ABS = 1e-6     % formula-level tight tolerance
     end

     % ------------------------------------------------------------------ %
     methods (Test)

          % --- CD0 formula -------------------------------------------------

          function testCD0Formula(tc)
               % CD0 = Cf * S_wet / S_ref.  Raymer Cfe=0.0035 → 0.0160;
               % Brandt workbook uses Cfe=0.0037 → 0.0170 [Brandt Aero!C6].
               % Assert within ±20% of Brandt model reference.
               b        = F16Baseline();
               expected = b.brandt.polar_model(1,3);   % 0.0170
               g        = F16AeroL1();
               received = g.get_CD0();
               fprintf('\n    CD0: received = %.6f,  expected (Brandt) = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                    'CD0 deviates >20% from Brandt workbook value.');
          end

          % --- Oswald efficiency -------------------------------------------

          function testEoswFormula(tc)
               % Raymer Eq. 12.49: e = 4.61*(1-0.045*AR^0.68)*cos(LE)^0.15 - 3.1 ≈ 0.9080
               % Brandt-implied e: derived from Brandt K1=0.1160 → e=1/(π·3·0.1160) ≈ 0.9146.
               % Assert within ±20% of Brandt-derived reference.
               b        = F16Baseline();
               K1_b     = b.brandt.polar_model(1,4);      % 0.1160 [Brandt Aero!D6]
               expected = 1 / (pi * 3.0 * K1_b);         % ≈ 0.9146
               g        = F16AeroL1();
               received = g.get_e_osw();
               fprintf('\n    e_osw: received = %.6f,  expected (Brandt-derived) = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20);
          end

          % Note (Casey): This test IS numerically valid, BUT invalid for
          % the F-16 test case. Valid for... Cessna 172. Consider adding as
          % a test case, later.
          function testEoswStraightWingBranch(tc)
               % Raymer Eq. 12.48 (Lambda_LE < 30 deg):
               % For AR=6, Lambda_LE=0: e = 1.78*(1-0.045*6^0.68) - 0.64
               AR       = 6.0;
               expected = 1.78 * (1 - 0.045*AR^0.68) - 0.64;
               received = AeroL1.oswald_eff(6.0, 0);
               fprintf('\n    e_osw (straight): received = %.6f,  expected = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          % --- K1 subsonic / supersonic ------------------------------------

          function testK1Subsonic(tc)
               % Brandt model: K1 = 0.1160 at M=0.1 (subsonic) [Brandt Aero!D6].
               % Assert within ±20% of Brandt reference.
               b        = F16Baseline();
               expected = b.brandt.polar_model(1,4);   % 0.1160
               g        = F16AeroL1();
               received = g.get_K1(0.6);           % subsonic
               fprintf('\n    K1 (M=0.6): received = %.6f,  expected (Brandt) = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20);
          end

          function testK1Supersonic(tc)
               % Brandt model: K1 = 0.2516 at M=1.5 (supersonic) [Brandt Aero!D9].
               % Raymer Eq. 12.51 gives 0.2251 — within 10.5% of Brandt.
               % Assert within ±20% of Brandt reference.
               b        = F16Baseline();
               expected = b.brandt.polar_model(4,4);   % 0.2516 at M=1.5
               g        = F16AeroL1();
               received = g.get_K1(1.5);
               fprintf('\n    K1 (M=1.5): received = %.6f,  expected (Brandt) = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20);
          end

          function testK1GreaterSubsonicThanSupersonic(tc)
               % For F-16 geometry, K1_sub < K1_sup (low AR, highly swept).
               g     = F16AeroL1();
               K1_sub = g.get_K1(0.6);
               K1_sup = g.get_K1(1.5);
               fprintf('\n    K1_sub=%.5f  K1_sup=%.5f\n', K1_sub, K1_sup);
               tc.verifyLessThan(K1_sub, K1_sup, ...
                    'K1 subsonic should be less than K1 supersonic for low-AR swept wing.');
          end

          % --- K2 ----------------------------------------------------------

          function testK2SubsonicZeroCLminD(tc)
               % CL_minD=0 → K2 = 0 even subsonic.
               g        = F16AeroL1();
               e        = g.get_e_osw();
               K1_sub   = AeroL1.K1_subsonic(e, g.AR);
               expected = 0;
               received = g.get_K2(K1_sub, 0.6);
               fprintf('\n    K2 (M=0.6, CL_minD=0): received = %.6f,  expected = %.6f\n', received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testK2SupersonicIsZero(tc)
               % K2 = 0 for all M >= 1 regardless of CL_minD.
               K1_sub   = AeroL1.K1_subsonic(AeroL1.oswald_eff(3, 40), 3);
               received = AeroL1.K2_value(K1_sub, 0.2, 1.2);   % CL_minD=0.2, M=1.2
               fprintf('\n    K2 (M=1.2, supersonic): received = %.6f,  expected = 0\n', received);
               tc.verifyEqual(received, 0, 'AbsTol', tc.TOL_ABS, ...
                    'K2 must be 0 at supersonic speeds (linearized theory).');
          end

          % --- drag_polar struct -------------------------------------------

          function testDragPolarReturnsStruct(tc)
               g     = F16AeroL1();
               state = AircraftState(0, 0.5);
               polar = g.drag_polar(state);
               tc.verifyTrue(isstruct(polar), 'drag_polar must return a struct.');
               tc.verifyTrue(isfield(polar, 'CD0'), 'polar missing field CD0.');
               tc.verifyTrue(isfield(polar, 'K1'),  'polar missing field K1.');
               tc.verifyTrue(isfield(polar, 'K2'),  'polar missing field K2.');
          end

          function testDragPolarConsistency(tc)
               % polar.CD0 must equal get_CD0(); polar.K1 must equal get_K1(M).
               g     = F16AeroL1();
               state = AircraftState(0, 0.6);
               polar = g.drag_polar(state);
               fprintf('\n    drag_polar: CD0=%.5f  K1=%.5f  K2=%.5f\n', ...
                    polar.CD0, polar.K1, polar.K2);
               tc.verifyEqual(polar.CD0, g.get_CD0(), 'AbsTol', 1e-12);
               tc.verifyEqual(polar.K1,  g.get_K1(0.6), 'AbsTol', 1e-12);
          end

          % --- CLmax -------------------------------------------------------

          function testCLmaxJetFighter(tc)
               % Historical value from Roskam Vol. I Table 3.3: 0.90
               g        = F16AeroL1();
               state    = AircraftState(0, 0.2);
               % Roskam table: 0.90 for jet fighter. Brandt model: 0.9869 (~9% gap).
               % L1 is categorical — assert within ±20% of Brandt clean CLmax.
               b        = F16Baseline();
               expected = b.brandt.CLmax_clean;   % 0.9869 [Brandt L8]
               received = g.get_CLmax(state);
               fprintf('\n    CLmax: received = %.4f,  expected (Brandt) = %.4f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                    'CLmax deviates >20% from Brandt clean CLmax (Roskam table gives 0.90, Brandt 0.987).');
          end

          % --- Physical range ----------------------------------------------

          function testCD0PhysicalRange(tc)
               % Expected ~0.016 for F-16 L1; bounds: 0.005 to 0.030.
               g        = F16AeroL1();
               received = g.get_CD0();
               fprintf('\n    CD0 = %.5f  [bounds: 0.005, 0.030]\n', received);
               tc.verifyGreaterThan(received, 0.005);
               tc.verifyLessThan(received,   0.030);
          end

          function testEoswPhysicalRange(tc)
               % Oswald efficiency for a well-designed wing: 0.5 < e < 1.0.
               g        = F16AeroL1();
               received = g.get_e_osw();
               fprintf('\n    e_osw = %.4f  [bounds: 0.50, 1.00]\n', received);
               tc.verifyGreaterThan(received, 0.50);
               tc.verifyLessThan(received,   1.00);
          end

          % --- Unknown category error --------------------------------------

          function testUnknownCategoryCD0Throws(tc)
               g = F16AeroL1();
               g.aircraft_category = "dirigible";
               tc.verifyError(@() g.get_CD0(), 'AeroL1:unknownCategory');
          end

          function testUnknownCategoryCLmaxThrows(tc)
               g     = F16AeroL1();
               g.aircraft_category = "dirigible";
               state = AircraftState(0, 0.2);
               tc.verifyError(@() g.get_CLmax(state), 'AeroL1:unknownCategory');
          end

          % --- Inheritance / interface compliance --------------------------

          function testIsaAerodynamicsBase(tc)
               g = F16AeroL1();
               tc.verifyTrue(isa(g, 'AerodynamicsBase'), ...
                    'F16AeroL1 must satisfy AerodynamicsBase contract.');
          end

          function testIsaAeroModelL1(tc)
               g = F16AeroL1();
               tc.verifyTrue(isa(g, 'AeroModelL1'));
          end

          function testNotIsaAeroL1(tc)
               % Student class inherits from the abstract enforcer, not the toolbox.
               g = F16AeroL1();
               tc.verifyFalse(isa(g, 'AeroL1'), ...
                    'F16AeroL1 must NOT inherit from the toolbox AeroL1.');
          end

          function testIsHandleClass(tc)
               g = F16AeroL1();
               tc.verifyTrue(isa(g, 'handle'));
          end

     end
end
