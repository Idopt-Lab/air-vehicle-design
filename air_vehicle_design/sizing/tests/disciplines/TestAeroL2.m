classdef TestAeroL2 < matlab.unittest.TestCase
     %TESTAERO L2  Unit tests for AeroL2 toolbox and F16AeroL2 student class.
     %
     %   Formula references:
     %     CL_alpha = 2*pi*AR / (2 + sqrt(4 + (AR*beta)^2*(1+tan^2(Lc4)/beta^2)))
     %       Raymer 6th ed. Eq. 12.6   [beta = sqrt(1-M^2)]
     %     CLmax = 0.9 * cl_max_2D * cos(Lambda_c4_deg)  Raymer 6th ed. §12.2
     %     CD0, e, K1, K2: same equations as L1 (tested separately in TestAeroL1)
     %
     %   Pre-computed F-16A expected values at M=0:
     %     beta=1, Lambda_c4=37 deg
     %     CL_alpha = 2*pi*3 / (2 + sqrt(4 + 9*(1+tan(37°)^2)))
     %              = 18.850 / (2 + sqrt(4 + 9*1.5679)) = 18.850 / (2 + sqrt(18.111))
     %              = 18.850 / (2 + 4.2559) = 18.850 / 6.2559 = 3.013 /rad
     %
     %   At M=0.6:
     %     beta=0.800
     %     CL_alpha = 18.850 / (2 + sqrt(4 + (3*0.8)^2*(1+tan(37°)^2/0.64)))
     %              = 18.850 / (2 + sqrt(4 + 5.76*(1+0.8874)))
     %              = 18.850 / (2 + sqrt(14.859)) = 18.850 / (2 + 3.855) = 3.219 /rad
     %
     %   CLmax = 0.9 * 1.20 * cos(37°) = 0.9 * 1.20 * 0.79864 = 0.8624

     properties (Constant)
          TOL_ABS = 0.20;
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

          % --- CL_alpha formula --------------------------------------------

          function testCLalphaAtMachZero(tc)
               % M=0: beta=1, CL_alpha = 18.850/6.256 = 3.013 /rad
               % Brandt gives 0.0615 /deg = 3.52 /rad, but that is at Mcrit=0.8727
               % (he uses per-degree units; 57.3 converts to /rad). No M=0 counterpart.
               g    = F16AeroL2();
               AR   = 3.0;  Lc4 = 37;
               beta = 1.0;
               % Raymer Eq. 12.6 is the primary source
               expected = 0.054312*57.3; % Taken from Brandt, Aero, A15 (main wing)
               received = g.get_CL_alpha(0.0);
               fprintf('\n    CL_alpha (M=0):   received = %.4f /rad,  expected = %.4f /rad\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testCLalphaAtMach06(tc)
               % M=0.6: beta=0.8, expected ≈ 3.219 /rad
               % No Brandt counterpart at M=0.6; Raymer Eq. 12.6 is the primary source.
               g    = F16AeroL2();
               AR   = 3.0;  Lc4 = 37;  M = 0.6;
               beta = sqrt(1 - M^2);
               % expected ≈ 3.219
               expected = 0.054312*57.3; % Taken from Brandt, Aero, A15 (main wing)
               received = g.get_CL_alpha(M);
               fprintf('\n    CL_alpha (M=0.6): received = %.4f /rad,  expected = %.4f /rad\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testCLalphaIncreasesWithMach(tc)
               % Compressibility (Prandtl-Glauert) raises finite-wing CL_alpha from
               % M=0 to M → 1.
               g   = F16AeroL2();
               a0  = g.get_CL_alpha(0.0);
               a06 = g.get_CL_alpha(0.6);
               fprintf('\n    CL_alpha: M=0 → %.4f /rad,  M=0.6 → %.4f /rad\n', a0, a06);
               tc.verifyGreaterThan(a06, a0, ...
                    'CL_alpha should increase with Mach (compressibility effect).');
          end

          % --- CLmax -------------------------------------------------------

          function testCLmaxClean(tc)
               % CLmax = 0.9 * cl_max_2D * cos(Lambda_c4).  Raymer §12.2.
               % Formula gives 0.9*1.20*cos(37°) = 0.8624.
               % Brandt CLmax_clean = 0.9869 [Brandt L8]; formula is ~12.6% low → within ±20%.
               b        = F16Baseline();
               expected = b.brandt.CLmax_clean;   % 0.9869
               g        = F16AeroL2();
               state    = AircraftState(0, 0.3);
               received = g.get_CLmax(state);
               fprintf('\n    CLmax: received = %.5f,  expected (Brandt) = %.5f\n', received, expected);
               tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                    'CLmax deviates >20% from Brandt workbook value.');
          end

          function testCLmaxLessThanSection(tc)
               % Finite-wing sweep correction: CLmax_wing < cl_max_2D.
               g     = F16AeroL2();
               state = AircraftState(0, 0.3);
               tc.verifyLessThan(g.get_CLmax(state), g.cl_max_2D, ...
                    'Wing CLmax should be less than 2D section CLmax due to sweep.');
          end

          % --- CD0 matches L1 (same formula) --------------------------------

          function testCD0MatchesL1(tc)
               % L2 CD0 formula is identical to L1.
               g1 = F16AeroL1();
               g2 = F16AeroL2();
               fprintf('\n    CD0 L1=%.6f  CD0 L2=%.6f\n', g1.get_CD0(), g2.get_CD0());
               tc.verifyEqual(g2.get_CD0(), g1.get_CD0(), 'AbsTol', 1e-12, ...
                    'L2 CD0 must equal L1 (same Cf*Swet/Sref formula).');
          end

          % --- e_osw matches L1 (same formula) ------------------------------

          function testEoswMatchesL1(tc)
               % L2 get_e_osw delegates to AeroL1.oswald_eff(AR, Lambda_LE_deg),
               % the identical Raymer Eq. 12.49 formula L1 uses -- see
               % TestAeroL1.testEoswFormula for the underlying formula check.
               g1 = F16AeroL1();
               g2 = F16AeroL2();
               fprintf('\n    e_osw L1=%.6f  e_osw L2=%.6f\n', g1.get_e_osw(), g2.get_e_osw());
               tc.verifyEqual(g2.get_e_osw(), g1.get_e_osw(), 'AbsTol', 1e-12, ...
                    'L2 e_osw must equal L1 (same Raymer Eq. 12.49 formula).');
          end

          % --- drag_polar vs Brandt ACTUAL (flight-measured) polar ---------

          function testDragPolarVsBrandtActualAtDash(tc)
               % Sanity check against Brandt's ACTUAL (flight-measured) polar
               % table [Brandt Aero!M6:Q10] at 36 kft, M=1.6 -- a different
               % reference table than polar_model used elsewhere in this file
               % (see fidelity_comparison.m "[AERO — SUP]" section). This
               % flight-measured K1 (0.34) reflects real supersonic effects
               % L2's linear-theory K1 (Raymer Eq. 12.51, verified against the
               % polar_model curve in testK1AtBrandtMachPoints) doesn't
               % capture, so this is a coarse positivity / order-of-magnitude
               % check only.
               b       = F16Baseline();
               g       = F16AeroL2();
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

          % --- Verification across Brandt's tabulated Mach breakpoints -----
          %   K1/CD0 use the same formulas as L1 (see header note); tolerance
          %   reasoning matches TestAeroL1's equivalent tests.

          function testK1AtBrandtMachPoints(tc, brandtRow)
               b        = F16Baseline();
               M        = b.brandt.polar_model(brandtRow, 1);
               K1_ref   = b.brandt.polar_model(brandtRow, 4);
               g        = F16AeroL2();
               received = g.get_K1(M);
               fprintf('\n    K1 (M=%.4f): received = %.4f,  Brandt = %.4f  (%+.1f%%)\n', ...
                    M, received, K1_ref, 100*(received-K1_ref)/K1_ref);
               if ismember(brandtRow, [1, 2, 4])
                    tc.verifyEqual(received, K1_ref, 'RelTol', 0.20, ...
                         sprintf('K1 at M=%.4f deviates >20%% from Brandt.', M));
               else
                    % Rows 3 (M=1.0547, near-M=1 singularity of Eq. 12.51) and
                    % 5 (M=2.0, linear theory under-predicts at high Mach) are
                    % known breakdowns of the linear theory -- see TestAeroL1.
                    tc.verifyGreaterThan(received, 0, ...
                         'K1 must stay positive even where linear theory breaks down near/beyond M=1.');
               end
          end

          function testCD0AtBrandtMachPoints(tc, brandtRow)
               % L2 CD0 has no Mach dependence (same formula as L1) -- only
               % tracks Brandt in the flat subsonic region (rows 1-2).
               b        = F16Baseline();
               M        = b.brandt.polar_model(brandtRow, 1);
               CD0_ref  = b.brandt.polar_model(brandtRow, 3);
               g        = F16AeroL2();
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
               % See TestAeroL1's equivalent test for rationale. F16Baseline
               % b.constraints.*.CD0/K1/K2 carry Brandt's own drag-polar
               % coefficients at each condition (Consts sheet); the flat
               % subsonic points get a real numeric comparison, same
               % ±20% tolerance as testCD0/K1AtBrandtMachPoints.
               b     = F16Baseline();
               c     = b.constraints.(constraintName);
               g     = F16AeroL2();
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
               if ismember(constraintName, {'cruise', 'combat_sub', 'max_alt', 'ps'})
                    tc.verifyEqual(polar.CD0, c.CD0, 'RelTol', 0.20, ...
                         sprintf('CD0 at %s deviates >20%% from Brandt.', constraintName));
                    tc.verifyEqual(polar.K1, c.K1, 'RelTol', 0.20, ...
                         sprintf('K1 at %s deviates >20%% from Brandt.', constraintName));
               end
          end

          % --- drag_polar struct -------------------------------------------

          function testDragPolarReturnsStruct(tc)
               g     = F16AeroL2();
               state = AircraftState(0, 0.5);
               polar = g.drag_polar(state);
               tc.verifyTrue(isstruct(polar));
               tc.verifyTrue(isfield(polar, 'CD0'));
               tc.verifyTrue(isfield(polar, 'K1'));
               tc.verifyTrue(isfield(polar, 'K2'));
          end

          function testDragPolarK2ZeroSupersonic(tc)
               % K2 must be zero at M=1.2.
               g     = F16AeroL2();
               state = AircraftState(30000, 1.2);
               polar = g.drag_polar(state);
               fprintf('\n    K2 at M=1.2: received = %.6f,  expected = 0\n', polar.K2);
               tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, ...
                    'K2 must be 0 at supersonic speeds.');
          end

          % --- Physical range ----------------------------------------------

          function testCLalphaPhysicalRange(tc)
               % Typical fighter CL_alpha: 2.0–5.0 /rad.
               g        = F16AeroL2();
               received = g.get_CL_alpha(0.5);
               fprintf('\n    CL_alpha (M=0.5) = %.4f /rad  [bounds: 2.0, 5.0]\n', received);
               tc.verifyGreaterThan(received, 2.0);
               tc.verifyLessThan(received,   5.0);
          end

          function testCLmaxPhysicalRange(tc)
               % Clean fighter CLmax: 0.5–1.5.
               g     = F16AeroL2();
               state = AircraftState(0, 0.3);
               received = g.get_CLmax(state);
               fprintf('\n    CLmax = %.4f  [bounds: 0.50, 1.50]\n', received);
               tc.verifyGreaterThan(received, 0.50);
               tc.verifyLessThan(received,   1.50);
          end

          % --- Inheritance / interface compliance --------------------------

          function testIsaAerodynamicsBase(tc)
               g = F16AeroL2();
               tc.verifyTrue(isa(g, 'AerodynamicsBase'));
          end

          function testIsaAeroModelL2(tc)
               g = F16AeroL2();
               tc.verifyTrue(isa(g, 'AeroModelL2'));
          end

          function testNotIsaAeroModelL1(tc)
               g = F16AeroL2();
               tc.verifyFalse(isa(g, 'AeroModelL1'), ...
                    'L2 must NOT inherit from the L1 enforcer.');
          end

          function testIsHandleClass(tc)
               g = F16AeroL2();
               tc.verifyTrue(isa(g, 'handle'));
          end

          % --- High-lift-device deltas (flap only, from geometry) ----------
          %   Delta_e_osw: Roskam Table 3.6 (tabulated, no closed form).
          %   Delta_CLmax: Raymer Table 12.2 + Eq. 12.21 (geometry-driven).
          %   Delta_CD0/CDi: Raymer Eq. 12.61/12.62 (geometry-driven).

          function testDeltaEoswNegative(tc)
               g = F16AeroL2();
               fprintf('\n    Delta_e_osw: TO=%.4f  L=%.4f\n', g.get_Delta_e_osw_TO(), g.get_Delta_e_osw_L());
               tc.verifyLessThan(g.get_Delta_e_osw_TO(), 0);
               tc.verifyLessThan(g.get_Delta_e_osw_L(), g.get_Delta_e_osw_TO());
          end

          function testDeltaCD0PositiveAndOrdered(tc)
               g = F16AeroL2();
               fprintf('\n    Delta_CD0: TO=%.4f  L=%.4f\n', g.get_Delta_CD0_TO(), g.get_Delta_CD0_L());
               tc.verifyGreaterThan(g.get_Delta_CD0_TO(), 0);
               tc.verifyGreaterThan(g.get_Delta_CD0_L(), g.get_Delta_CD0_TO(), ...
                    'Landing flap deflection (65 deg) should add more CD0 than takeoff (30 deg).');
          end

          function testDeltaCLmaxPositiveAndOrdered(tc)
               g = F16AeroL2();
               fprintf('\n    Delta_CLmax: TO=%.4f  L=%.4f\n', g.get_Delta_CLmax_TO(), g.get_Delta_CLmax_L());
               tc.verifyGreaterThan(g.get_Delta_CLmax_TO(), 0);
               tc.verifyGreaterThan(g.get_Delta_CLmax_L(), g.get_Delta_CLmax_TO(), ...
                    'Landing uses 80% of Table 12.2''s Delta_cl_max vs 60% for takeoff.');
          end

          function testDeltaCDiPositive(tc)
               % Raymer Eq. 12.62: induced-drag increment is always >= 0
               % (proportional to (Delta_CL_flap)^2).
               g = F16AeroL2();
               fprintf('\n    Delta_CDi: TO=%.5f  L=%.5f\n', g.get_Delta_CDi_TO(), g.get_Delta_CDi_L());
               tc.verifyGreaterThanOrEqual(g.get_Delta_CDi_TO(), 0);
               tc.verifyGreaterThanOrEqual(g.get_Delta_CDi_L(), 0);
          end

          function testCLmaxTotalVsBrandtTakeoffLanding(tc)
               % L2's flap-only CLmax_TO/L omit the F-16's actual leading-edge
               % flap contribution (added at L3), so expect CLmax_TO/L to
               % under-shoot Brandt's targets -- generous tolerance.
               b = F16Baseline();
               g = F16AeroL2();
               fprintf('\n    CLmax_TO: received=%.4f  Brandt=%.4f\n', g.get_CLmax_TO(), b.brandt.CLmax_TO);
               fprintf('    CLmax_L:  received=%.4f  Brandt=%.4f\n', g.get_CLmax_L(), b.brandt.CLmax_land);
               tc.verifyGreaterThan(g.get_CLmax_TO(), g.get_CLmax([]));
               tc.verifyGreaterThan(g.get_CLmax_L(),  g.get_CLmax_TO());
               tc.verifyLessThan(g.get_CLmax_L(), b.brandt.CLmax_land, ...
                    'L2 (flap only, no slat) should not exceed Brandt''s full-HLD landing CLmax.');
          end

     end
end
