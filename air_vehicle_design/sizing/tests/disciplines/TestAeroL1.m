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

     % Brandt "Aero" A6:E10 tabulates the model polar at 5 Mach points
     % (b.brandt.polar_model rows): M = 0.1000, 0.8727(=Mcrit), 1.0547,
     % 1.5000, 2.0000. Tests below that compare against Brandt values use
     % these same rows/Mach numbers rather than arbitrary points.
     properties (TestParameter)
          brandtRow      = {1, 2, 3, 4, 5};
          constraintName = {'cruise', 'combat_sub', 'dash', 'max_alt', 'combat_sup', 'ps'};
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

          % --- K1 subsonic / supersonic ------------------------------------

          function testK1Subsonic(tc)
               % Brandt model: K1 = 0.1160 at M=0.1 (subsonic) [Brandt Aero!D6].
               % Assert within ±20% of Brandt reference. Uses M=0.1 (Brandt's
               % own tabulated row 1 Mach) so the comparison is like-for-like.
               b        = F16Baseline();
               M        = b.brandt.polar_model(1,1);   % 0.1000
               expected = b.brandt.polar_model(1,4);   % 0.1160
               g        = F16AeroL1();
               received = g.get_K1(M);
               fprintf('\n    K1 (M=%.4f): received = %.6f,  expected (Brandt) = %.6f\n', M, received, expected);
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

          % --- Verification across Brandt's tabulated Mach breakpoints -----

          function testK1AtBrandtMachPoints(tc, brandtRow)
               % K1 vs Brandt polar_model at each of Brandt's 5 tabulated
               % Mach points. Raymer's linear theory (Eq. 12.50 subsonic /
               % Eq. 12.51 supersonic, K1 = AR*(M^2-1)*cos(Lambda_LE) /
               % (4*AR*beta - 2) with beta = sqrt(M^2-1)) tracks Brandt
               % within ~20% at all 5 rows, including near M=1 (row 3,
               % M=1.0547) and at M=2.0 (row 5).
               b        = F16Baseline();
               M        = b.brandt.polar_model(brandtRow, 1);
               K1_ref   = b.brandt.polar_model(brandtRow, 4);
               g        = F16AeroL1();
               received = g.get_K1(M);
               fprintf('\n    K1 (M=%.4f): received = %.4f,  Brandt = %.4f  (%+.1f%%)\n', ...
                    M, received, K1_ref, 100*(received-K1_ref)/K1_ref);
               tc.verifyEqual(received, K1_ref, 'RelTol', 0.20, ...
                    sprintf('K1 at M=%.4f deviates >20%% from Brandt.', M));
          end

          function testCD0AtBrandtMachPoints(tc, brandtRow)
               % L1 CD0 = Cf*S_wet/S_ref has no Mach dependence -- there is no
               % transonic/supersonic drag-rise model at this fidelity level
               % (see subplan 03_aerodynamics.md). It only tracks Brandt in
               % the flat subsonic region (rows 1-2, M <= Mcrit=0.8727); rows
               % 3-5 are sanity-checked for physical plausibility only, since
               % L1 is not expected to reproduce Brandt's transonic/
               % supersonic CD0 rise.
               b        = F16Baseline();
               M        = b.brandt.polar_model(brandtRow, 1);
               CD0_ref  = b.brandt.polar_model(brandtRow, 3);
               g        = F16AeroL1();
               received = g.get_CD0();
               fprintf('\n    CD0 (M=%.4f): received = %.4f,  Brandt = %.4f  (%+.1f%%)\n', ...
                    M, received, CD0_ref, 100*(received-CD0_ref)/CD0_ref);
               if ismember(brandtRow, [1, 2])
                    tc.verifyEqual(received, CD0_ref, 'RelTol', 0.20, ...
                         sprintf('CD0 at M=%.4f deviates >20%% from Brandt.', M));
               else
                    tc.verifyGreaterThan(received, 0.005);
                    tc.verifyLessThan(received, 0.030);
               end
          end

          % --- Verification at Brandt's constraint-analysis conditions -----

          function testDragPolarAtConstraintConditions(tc, constraintName)
               % Verification at the six (alt, Mach) points Brandt tabulates
               % on the "Consts" sheet for constraint analysis -- cruise,
               % combat_sub, dash, max_alt, combat_sup, ps. F16Baseline
               % b.constraints.*.CD0/K1/K2 now carry Brandt's own drag-polar
               % coefficients at each condition (Consts sheet), so subsonic
               % points get a real numeric comparison, not just a sanity check.
               b     = F16Baseline();
               c     = b.constraints.(constraintName);
               g     = F16AeroL1();
               state = AircraftState(c.alt_ft, c.mach);
               polar = g.drag_polar(state);
               fprintf('\n    %-11s alt=%6.0f  M=%.2f: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                    constraintName, c.alt_ft, c.mach, polar.CD0, polar.K1, polar.K2, c.CD0, c.K1, c.K2);
               tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
               tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
               tc.verifyTrue(isfinite(polar.CD0) && isfinite(polar.K1) && isfinite(polar.K2), ...
                    'drag_polar outputs must be finite.');
               if c.mach >= 1
                    tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
               end
               % cruise/combat_sub/max_alt/ps sit at M~0.87 (same flat
               % subsonic regime as brandtRow 1-2): L1's Mach-independent CD0
               % and linear-theory K1_sub are expected to track Brandt within
               % ±20%, same tolerance as testCD0/K1AtBrandtMachPoints.
               % dash (M=1.6) and combat_sup (M=1.4) are left sanity-only --
               % Brandt's Consts-sheet K1/CD0 at these points are empirical
               % (not the polar_model linear-theory curve verified in
               % testK1AtBrandtMachPoints) and L1 has no transonic/supersonic
               % CD0 rise, so neither CD0 nor K1 is expected to track closely
               % here.
               if ismember(constraintName, {'cruise', 'combat_sub', 'max_alt', 'ps'})
                    tc.verifyEqual(polar.CD0, c.CD0, 'RelTol', 0.20, ...
                         sprintf('CD0 at %s deviates >20%% from Brandt.', constraintName));
                    tc.verifyEqual(polar.K1, c.K1, 'RelTol', 0.20, ...
                         sprintf('K1 at %s deviates >20%% from Brandt.', constraintName));
               end
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

          % --- drag_polar vs Brandt ACTUAL (flight-measured) polar ---------

          function testDragPolarVsBrandtActualAtDash(tc)
               % Sanity check against Brandt's ACTUAL (flight-measured) polar
               % table [Brandt Aero!M6:Q10] at 36 kft, M=1.6 -- a different
               % reference table than polar_model used elsewhere in this file
               % (see fidelity_comparison.m "[AERO — SUP]" section). Known to
               % diverge from L1's linear supersonic K1 (Raymer Eq. 12.51)
               % near/beyond M=1 -- see testK1AtBrandtMachPoints -- so this is
               % a coarse positivity / order-of-magnitude check only.
               b       = F16Baseline();
               g       = F16AeroL1();
               state   = AircraftState(36000, 1.60);
               polar   = g.drag_polar(state);
               CD0_ref = b.brandt.polar_actual(4,3);   % 0.0461 [Brandt Aero!O9]
               K1_ref  = b.brandt.polar_actual(4,4);   % 0.3400 [Brandt Aero!P9]
               fprintf('\n    dash (actual polar ref): CD0=%.4f (ref %.4f), K1=%.4f (ref %.4f)\n', ...
                    polar.CD0, CD0_ref, polar.K1, K1_ref);
               tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
               tc.verifyGreaterThan(polar.K1, 0, 'K1 must be positive.');
               tc.verifyLessThan(polar.CD0, 5*CD0_ref, ...
                    'CD0 is more than 5x Brandt actual-polar reference -- check for a gross error.');
               tc.verifyLessThan(polar.K1, 5*K1_ref, ...
                    'K1 is more than 5x Brandt actual-polar reference -- check for a gross error.');
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

          % --- High-lift-device / gear deltas (Roskam Part I, Tables 3.1/3.6)

          function testDeltaEoswNegative(tc)
               % Flaps degrade span efficiency: Roskam Table 3.6's "e" column
               % decreases clean -> TO -> landing, so the delta is negative.
               g = F16AeroL1();
               fprintf('\n    Delta_e_osw: TO=%.4f  L=%.4f\n', g.get_Delta_e_osw_TO(), g.get_Delta_e_osw_L());
               tc.verifyLessThan(g.get_Delta_e_osw_TO(), 0);
               tc.verifyLessThan(g.get_Delta_e_osw_L(),  0);
               tc.verifyLessThan(g.get_Delta_e_osw_L(), g.get_Delta_e_osw_TO(), ...
                    'Landing (more flap) should degrade e_osw more than takeoff.');
          end

          function testDeltaCD0PositiveAndOrdered(tc)
               g = F16AeroL1();
               fprintf('\n    Delta_CD0: TO=%.4f  L=%.4f\n', g.get_Delta_CD0_TO(), g.get_Delta_CD0_L());
               tc.verifyGreaterThan(g.get_Delta_CD0_TO(), 0);
               tc.verifyGreaterThan(g.get_Delta_CD0_L(),  0);
               tc.verifyGreaterThan(g.get_Delta_CD0_L(), g.get_Delta_CD0_TO(), ...
                    'Landing config (more flap) should add more CD0 than takeoff.');
          end

          function testDeltaCLmaxPositiveAndOrdered(tc)
               g = F16AeroL1();
               fprintf('\n    Delta_CLmax: TO=%.4f  L=%.4f\n', g.get_Delta_CLmax_TO(), g.get_Delta_CLmax_L());
               tc.verifyGreaterThan(g.get_Delta_CLmax_TO(), 0);
               tc.verifyGreaterThan(g.get_Delta_CLmax_L(),  0);
               tc.verifyGreaterThan(g.get_Delta_CLmax_L(), g.get_Delta_CLmax_TO());
          end

          function testCD0TotalVsBrandtTakeoffLanding(tc)
               % L1 CD0 is a category-mean estimate (Raymer Table 12.3 Cf x
               % Roskam Table 3.6 deltas), not F-16-calibrated -- generous
               % tolerance, consistent with this file's other L1-vs-Brandt tests.
               % TO matches Brandt closely (clean+TO-flap+gear ~= 0.017+0.015+
               % 0.020 = 0.052, vs Brandt 0.052 exactly). Landing does NOT:
               % Roskam Table 3.6's landing-flap Delta_CD0 range (0.055-0.075)
               % reflects generic large (e.g. Fowler-type) flaps, much bigger
               % than the F-16's small flaperon -- L1's category estimate
               % genuinely overshoots Brandt's landing CD0 (0.062). That is
               % the expected L1-vs-real-aircraft gap, not a bug, so the
               % landing case is a sanity bound rather than a tight RelTol
               % (same pattern as e.g. testDragPolarVsBrandtActualAtDash).
               b   = F16Baseline();
               g   = F16AeroL1();
               cd0_TO = g.get_CD0() + g.get_Delta_CD0_TO();
               cd0_L  = g.get_CD0() + g.get_Delta_CD0_L();
               fprintf('\n    CD0_TO: received=%.4f  Brandt=%.4f\n', cd0_TO, b.constraints.takeoff.CD0);
               fprintf('    CD0_L:  received=%.4f  Brandt=%.4f\n', cd0_L, b.constraints.landing.CD0);
               tc.verifyEqual(cd0_TO, b.constraints.takeoff.CD0, 'RelTol', 0.60);
               tc.verifyGreaterThan(cd0_L, b.constraints.landing.CD0, ...
                    'L1''s generic-category landing CD0 should exceed Brandt''s F-16-specific value.');
               tc.verifyLessThan(cd0_L, 3*b.constraints.landing.CD0, ...
                    'L1 landing CD0 is more than 3x Brandt -- check for a gross error.');
          end

          function testCLmaxTotalVsBrandtTakeoffLanding(tc)
               b   = F16Baseline();
               g   = F16AeroL1();
               state = AircraftState(0, 0.2);
               clmax_TO = g.get_CLmax(state) + g.get_Delta_CLmax_TO();
               clmax_L  = g.get_CLmax(state) + g.get_Delta_CLmax_L();
               fprintf('\n    CLmax_TO: received=%.4f  Brandt=%.4f\n', clmax_TO, b.brandt.CLmax_TO);
               fprintf('    CLmax_L:  received=%.4f  Brandt=%.4f\n', clmax_L, b.brandt.CLmax_land);
               tc.verifyEqual(clmax_TO, b.brandt.CLmax_TO,   'RelTol', 0.60);
               tc.verifyEqual(clmax_L,  b.brandt.CLmax_land, 'RelTol', 0.60);
          end

     end
end
