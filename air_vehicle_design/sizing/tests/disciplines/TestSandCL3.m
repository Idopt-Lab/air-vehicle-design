classdef TestSandCL3 < matlab.unittest.TestCase
%TESTSANDCL3  Unit tests for SandCL3 (the Raymer 6th ed. Ch. 16 static
%   toolbox) and F16SandCL3 (the F-16 concrete class).
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests. Every test here is green: the last
%   remaining deliberately-failing TODO test (Cm_acw/Cm_cg_trim) was closed
%   2026-08-04 once Raymer Eq. 16.19 was found to be a real, citable
%   formula -- the pipeline now returns NaN gracefully rather than erroring
%   until the one open user-supplied input (Cm0_airfoil_wing) is filled in.
%
%   Every hand-computed "expected" value below is derived independently, by
%   plugging the CITED formula (see each SandCL3 static's own header) into a
%   synthetic set of small, round numbers and computing the arithmetic by
%   hand in this file's comments -- NEVER by calling the SandCL3/SandCL2
%   static under test a second time and calling that "expected" (CLAUDE.md's
%   "never self-referential" rule).

    methods (TestClassSetup)

        function printFidelityBanner(~)
        %PRINTFIDELITYBANNER  Banner announcing this file's fidelity level
        %   and discipline before any test in it runs, so console output is
        %   clearly organized/delimited by fidelity level.
            fprintf('\n============================================================\n');
            fprintf(' FIDELITY LEVEL 3 -- Stability & Control\n');
            fprintf('============================================================\n');
        end

    end

    methods (Test)

        % ================================================================== %
        % weighted_cg reuse -- F16SandCL3.x_cg calls SandCL2.weighted_cg
        % directly (confirmed by reading F16SandCL3.m's get.x_cg), the SAME
        % static F16SandCL2 uses (fidelity-collapse rule: the identity itself
        % is level-agnostic). Style mirrors TestSandCL2's own integration
        % test.
        % ================================================================== %

        function testF16SandCL3XCgMatchesIndependentRecompute(tc)
        % Same independent-recompute pattern as
        % TestSandCL2.testF16SandCL2XCgMatchesIndependentRecompute -- reads
        % the 10 group weights off the PUBLIC F16WeightsL3 API and pairs them
        % with the JSON's own cg_x_ft stations (hand-transcribed from
        % examples/F16A/inputs/f16a_L3.json .stability_control
        % .component_x_stations.groups -- IDENTICAL values to f16a_L2.json's,
        % per that file's own note), then computes the weighted average by
        % hand here, NOT via SandCL2.weighted_cg or F16SandCL3's own private
        % group_weight switch.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);

            x = [27.28, 41.0, 40.0, 26.0, 26.0, 31.45, 21.11, 17.0, 24.63, 26.0];
            lg = w3.weight_landing_gear(w3.W_TO);
            w = [w3.W_wings, w3.W_tail.HT, w3.W_tail.VT, w3.W_fuselage, ...
                 lg.main + lg.nose, w3.W_installed_engine, w3.W_subsystems, ...
                 w3.W_strake, w3.W_payload_fixed + w3.W_payload_expendable, w3.W_energy];
            expected = sum(w .* x) / sum(w);

            received = s3.x_cg;
            fprintf('  [L3-S&C] testF16SandCL3XCgMatchesIndependentRecompute: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'F16SandCL3.x_cg must equal the independently-recomputed weighted average of the live L3 group weights and JSON cg_x_ft stations.');
        end

        % ================================================================== %
        % Eq. 16.12 "where" coefficients -- SandCL3.delta_x_ac(M), all three
        % Mach regimes.
        % ================================================================== %

        function testDeltaXAcBelow04IsZero(tc)
            received = SandCL3.delta_x_ac(0.3);
            expected = 0;
            fprintf('  [L3-S&C] testDeltaXAcBelow04IsZero: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
        end

        function testDeltaXAcSubsonicTransonicRegime(tc)
        % M = 0.87 (in [0.4, 1.1]): 0.26*(0.87-0.4)^2.5 = 0.26*(0.47)^2.5.
        % Hand computation: sqrt(0.47) = 0.6855654 (Newton-iterated by hand:
        % 0.6855^2=0.46991025, 0.6856^2=0.47004736, interpolate -> 0.6855654);
        % 0.47^2 = 0.2209; 0.47^2.5 = 0.2209*0.6855654 = 0.1514414;
        % 0.26*0.1514414 = 0.0393748.
            received = SandCL3.delta_x_ac(0.87);
            expected = 0.0393748;
            fprintf('  [L3-S&C] testDeltaXAcSubsonicTransonicRegime: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'delta_x_ac(0.87) must equal the hand-computed 0.26*(M-0.4)^2.5.');
        end

        function testDeltaXAcSupersonicRegime(tc)
        % M = 1.5 (> 1.1): 0.112 - 0.004*1.5 = 0.112 - 0.006 = 0.106.
            received = SandCL3.delta_x_ac(1.5);
            expected = 0.106;
            fprintf('  [L3-S&C] testDeltaXAcSupersonicRegime: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
        end

        function testDeltaXAcRegimeBoundariesAreContinuousAtBreakpoints(tc)
        % Guard: the two breakpoints (0.4, 1.1) must not introduce a spurious
        % jump beyond what the two different formulas themselves produce --
        % at M=0.4 the subsonic branch gives exactly 0 (matching the M<0.4
        % branch), and at M=1.1 the subsonic branch's value should be close
        % to (not identical to, since it's a different formula family) the
        % supersonic branch's value at the same M.
            received = SandCL3.delta_x_ac(0.4);
            expected = 0;
            fprintf('  [L3-S&C] testDeltaXAcRegimeBoundariesAreContinuousAtBreakpoints: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12, ...
                'At M=0.4 exactly, 0.26*(0.4-0.4)^2.5 = 0 must match the M<0.4 branch.');
        end

        % ================================================================== %
        % Eq. 16.12 -- x_ac_wing, full formula (apex + quarter-MAC offset +
        % Mach shift), synthetic small planform, hand-computed independently.
        % ================================================================== %

        function testXAcWingFullFormulaHandComputed(tc)
        % Synthetic inputs: x_apex=10 ft, LE_sweep=30 deg, b=20 ft (full
        % span), lambda=0.5, cbar=4 ft, S_wing=80 ft^2, M=0.87.
        %
        % y_mac = (b/6)*(1+2*lambda)/(1+lambda) = (20/6)*(2/1.5)
        %       = 3.333333*1.333333 = 4.444444
        % x_LE_MAC = x_apex + y_mac*tan(30 deg) = 10 + 4.444444*0.5773503
        %          = 10 + 2.566001 = 12.566001
        % x_c/4 = x_LE_MAC + 0.25*cbar = 12.566001 + 1.0 = 13.566001
        % delta_x_ac(0.87) = 0.0393748 (hand-computed above)
        % sqrt(S_wing) = sqrt(80) = 8.9442719
        % shift = 0.0393748 * 8.9442719 = 0.3521790
        % x_ac_wing = 13.566001 + 0.3521790 = 13.9181800
            received = SandCL3.x_ac_wing(10, 30, 20, 0.5, 4, 80, 0.87);
            expected = 13.9181800;
            fprintf('  [L3-S&C] testXAcWingFullFormulaHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 2e-4, ...
                'x_ac_wing must equal the hand-computed apex + quarter-MAC offset + Mach-shift sum (tolerance covers hand-arithmetic rounding at the 6th significant digit of the manual sqrt/power evaluations).');
        end

        function testXAcWingAtLowMachDropsTheShiftTerm(tc)
        % Same planform, M=0.2 (<0.4): shift term is exactly 0, so
        % x_ac_wing must equal the bare quarter-MAC point 13.566001.
            received = SandCL3.x_ac_wing(10, 30, 20, 0.5, 4, 80, 0.2);
            expected = 13.566001197;
            fprintf('  [L3-S&C] testXAcWingAtLowMachDropsTheShiftTerm: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testXAcSurfaceHasNoMachShiftTerm(tc)
        % x_ac_surface (used for the tail) must equal x_ac_wing's own
        % quarter-MAC term (no Mach-shift addition) at ANY Mach -- documented
        % simplification. Same synthetic planform as above.
            received = SandCL3.x_ac_surface(10, 30, 20, 0.5, 4);
            expected = 13.566001197;
            fprintf('  [L3-S&C] testXAcSurfaceHasNoMachShiftTerm: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        % ================================================================== %
        % Eq. 16.25 -- Cm_alpha_fus, per-deg formula and the (180/pi)
        % conversion (the legacy /57.3 bug fix this discipline exists for).
        % ================================================================== %

        function testCmAlphaFusPerDegHandComputed(tc)
        % Synthetic inputs: K_fus=0.02, W_f=6 ft, L_f=40 ft, c=5 ft, S_w=200 ft^2.
        %   val = 0.02*6^2*40/(5*200) = 0.02*36*40/1000 = 28.8/1000 = 0.0288
            received = SandCL3.Cm_alpha_fus_per_deg(0.02, 6, 40, 5, 200);
            expected = 0.0288;
            fprintf('  [L3-S&C] testCmAlphaFusPerDegHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
        end

        function testCmAlphaFusPerRadIsExactly180OverPiTimesPerDeg(tc)
        % The exact missing conversion factor the legacy temp_Casey code
        % never applies -- per_rad must be EXACTLY 180/pi (~57.29578) times
        % per_deg, not an approximation and not the reverse ratio.
            per_deg = SandCL3.Cm_alpha_fus_per_deg(0.02, 6, 40, 5, 200);
            per_rad = SandCL3.Cm_alpha_fus_per_rad(0.02, 6, 40, 5, 200);
            expected1 = per_deg * (180/pi);
            fprintf('  [L3-S&C] testCmAlphaFusPerRadIsExactly180OverPiTimesPerDeg: expected=%.6g, received=%.6g\n', expected1, per_rad);
            tc.verifyEqual(per_rad, expected1, 'AbsTol', 1e-12, ...
                'Cm_alpha_fus_per_rad must equal per_deg * (180/pi) exactly.');
            ratio = per_rad / per_deg;
            expected2 = 57.29577951308232;
            fprintf('  [L3-S&C] testCmAlphaFusPerRadIsExactly180OverPiTimesPerDeg: expected=%.6g, received=%.6g\n', expected2, ratio);
            tc.verifyEqual(ratio, expected2, 'AbsTol', 1e-9, ...
                'The per-rad/per-deg ratio must be exactly 180/pi, the missing legacy conversion factor.');
        end

        % ================================================================== %
        % Eqs. 16.8/16.9 -- Cm_alpha, neutral_point. Synthetic small round
        % numbers, hand-computed for BOTH a power-off (thrust term = 0) and a
        % power-on (thrust term != 0) case, confirming the thrust term
        % genuinely enters the sum when nonzero (not just a dead argument).
        % ================================================================== %

        function testNeutralPointPowerOffHandComputed(tc)
        % CL_alpha=4, Xacw_bar=2, Cm_alpha_fus_rad=0.1, eta_h=0.9, Sh_Sw=0.2,
        % CL_alpha_h=3, dalphah_dalpha=1, Xach_bar=5, thrust term = 0.
        %   eta_h*Sh_Sw*CL_alpha_h*dalphah_dalpha = 0.9*0.2*3*1 = 0.54
        %   num = 4*2 - 0.1 + 0.54*5 + 0 = 8 - 0.1 + 2.7 = 10.6
        %   den = 4 + 0.54 + 0 = 4.54
        %   Xnp_bar = 10.6/4.54 = 530/227 = 2.334801762...
            received = SandCL3.neutral_point(4, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0, 0, 0);
            expected = 530/227;
            fprintf('  [L3-S&C] testNeutralPointPowerOffHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testNeutralPointPowerOnThrustTermGenuinelyEntersTheSum(tc)
        % SAME inputs as the power-off case, but Fp_alpha_over_qSw=0.05,
        % dalphap_dalpha=0.8, Xp_bar=1 (thrust factor = 0.05*0.8 = 0.04).
        %   num = 8 - 0.1 + 2.7 + 0.04*1 = 10.64
        %   den = 4 + 0.54 + 0.04 = 4.58
        %   Xnp_bar = 10.64/4.58 = 1064/458 = 532/229 = 2.323144...
            received = SandCL3.neutral_point(4, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0.05, 0.8, 1);
            expected = 532/229;
            fprintf('  [L3-S&C] testNeutralPointPowerOnThrustTermGenuinelyEntersTheSum: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'The thrust term must actually shift Xnp_bar when nonzero, not be silently dropped.');
            % Confirm the two cases genuinely differ -- guards against a
            % toolbox bug that ignores the last three arguments entirely.
            power_off = SandCL3.neutral_point(4, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0, 0, 0);
            fprintf('  [L3-S&C] testNeutralPointPowerOnThrustTermGenuinelyEntersTheSum: power_on=%.6g, power_off=%.6g (must differ)\n', received, power_off);
            tc.verifyNotEqual(received, power_off, ...
                'Power-on and power-off neutral points must differ once a nonzero thrust term is supplied.');
        end

        function testCmAlphaPowerOffHandComputed(tc)
        % Same coefficients as the neutral-point test, plus Xcg_bar=2.1.
        %   Cma = 4*(2.1-2) + 0.1 - 0.54*(5-2.1) + 0
        %       = 0.4 + 0.1 - 0.54*2.9 = 0.5 - 1.566 = -1.066
            received = SandCL3.Cm_alpha(4, 2.1, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0, 0, 0);
            expected = -1.066;
            fprintf('  [L3-S&C] testCmAlphaPowerOffHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testCmAlphaPowerOnThrustTermGenuinelyEntersTheSum(tc)
        % Same as above but Fp_alpha_over_qSw=0.05, dalphap_dalpha=0.8,
        % Xp_bar=1:
        %   Cma = 4*0.1 + 0.1 - 0.54*2.9 + 0.05*0.8*(2.1-1)
        %       = 0.4 + 0.1 - 1.566 + 0.04*1.1 = 0.5 - 1.566 + 0.044 = -1.022
            received = SandCL3.Cm_alpha(4, 2.1, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0.05, 0.8, 1);
            expected = -1.022;
            fprintf('  [L3-S&C] testCmAlphaPowerOnThrustTermGenuinelyEntersTheSum: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            power_off = SandCL3.Cm_alpha(4, 2.1, 2, 0.1, 0.9, 0.2, 3, 1, 5, 0, 0, 0);
            fprintf('  [L3-S&C] testCmAlphaPowerOnThrustTermGenuinelyEntersTheSum: power_on=%.6g, power_off=%.6g (must differ)\n', received, power_off);
            tc.verifyNotEqual(received, power_off, ...
                'Power-on and power-off Cm_alpha must differ once a nonzero thrust term is supplied.');
        end

        % ================================================================== %
        % Eq. 16.11 -- static_margin, trivial hand-check AND the legacy
        % /100 bug guard.
        % ================================================================== %

        function testStaticMarginHandComputed(tc)
            received = SandCL3.static_margin(2.5, 2.3);
            expected = 0.2;
            fprintf('  [L3-S&C] testStaticMarginHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
        end

        function testStaticMarginHasNoDivideBy100Scaling(tc)
        % The legacy temp_Casey compute_SM bug: dividing the correct ratio
        % by an extra, uncited 100. Feed Xnp_bar=2.5, Xcg_bar=2.3 and demand
        % EXACTLY 0.2, not 0.002 -- if the bug were reintroduced, this fails
        % loudly (received 0.002 != expected 0.2, not a subtle RelTol miss).
            received = SandCL3.static_margin(2.5, 2.3);
            expected = 0.2;
            fprintf('  [L3-S&C] testStaticMarginHasNoDivideBy100Scaling: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
            fprintf('  [L3-S&C] testStaticMarginHasNoDivideBy100Scaling: received=%.6g must NOT equal the buggy value=%.6g\n', received, 0.002);
            tc.verifyNotEqual(received, 0.002, ...
                'static_margin must NOT divide by an extra 100 (the legacy compute_SM bug).');
        end

        % ================================================================== %
        % Eqs. 16.13/16.14 -- CL_w, CL_h. Pure toolbox-static tests, real and
        % complete even though the F-16 wrapper is GAP-blocked.
        % ================================================================== %

        function testCLWingHandComputed(tc)
        % CL_alpha=5 (1/rad), alpha=2 deg, i_w=1 deg, alpha_0L=-2 deg.
        %   CLw = 5 * deg2rad(2+1-(-2)) = 5*deg2rad(5) = 5*0.08726646 = 0.4363323
            received = SandCL3.CL_w(5, 2, 1, -2);
            expected = 5 * deg2rad(5);
            fprintf('  [L3-S&C] testCLWingHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            expected2 = 0.436332313;
            fprintf('  [L3-S&C] testCLWingHandComputed: expected=%.6g, received=%.6g\n', expected2, received);
            tc.verifyEqual(received, expected2, 'AbsTol', 1e-6);
        end

        function testCLTailHandComputed(tc)
        % CL_alpha_h=4, alpha=4 deg, i_h=-2 deg, epsilon=1 deg, alpha_0Lh=-3 deg.
        %   sum = 4 + (-2) - 1 - (-3) = 4 deg
        %   CLh = 4 * deg2rad(4) = 4*0.06981317 = 0.27925268
            received = SandCL3.CL_h(4, 4, -2, 1, -3);
            expected = 4 * deg2rad(4);
            fprintf('  [L3-S&C] testCLTailHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            expected2 = 0.279252680;
            fprintf('  [L3-S&C] testCLTailHandComputed: expected=%.6g, received=%.6g\n', expected2, received);
            tc.verifyEqual(received, expected2, 'AbsTol', 1e-6);
        end

        % ================================================================== %
        % Eqs. 16.16/16.18 -- delta_alpha_L0_elevator, cubic polynomial,
        % nonzero c_e/c (the real F-16 case, c_e/c=0, is trivially 0 and
        % never exercises this formula -- covered separately below).
        % ================================================================== %

        function testDeltaAlphaL0ElevatorNonzeroChordRatioHandComputed(tc)
        % c_e/c = 0.3, delta_e = 10 deg.
        %   bracket = 1.576*0.3^3 - 3.458*0.3^2 + 2.882*0.3
        %           = 1.576*0.027 - 3.458*0.09 + 0.8646
        %           = 0.042552 - 0.31122 + 0.8646 = 0.595932
        %   val = -0.595932 * 10 = -5.95932
            received = SandCL3.delta_alpha_L0_elevator(0.3, 10);
            expected = -5.95932;
            fprintf('  [L3-S&C] testDeltaAlphaL0ElevatorNonzeroChordRatioHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        % ================================================================== %
        % Eq. 16.19 -- Cm_acw_wing, wing zero-lift moment about its own AC.
        % Synthetic inputs, hand-computed. Found 2026-08-04 while closing
        % x_p/i_w/i_h (Casey's instruction: search Raymer for an equation;
        % this one exists -- SEE Cm0_airfoil_wing for the still-open,
        % USER-SUPPLIED numeric input it needs).
        % ================================================================== %

        function testCmAcwWingHandComputed(tc)
        % Cm0_airfoil=-0.01, AR=3, sweep=40 deg.
        %   cos(40deg) = 0.7660444431
        %   Cm_acw = -0.01 * (3*cos^2) / (3 + 2*cos)
        %          = -0.01 * 1.76047227 / 4.53208889 = -0.0038844610...
            received = SandCL3.Cm_acw_wing(-0.01, 3, 40);
            expected = -0.003884461030422876;
            fprintf('  [L3-S&C] testCmAcwWingHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testCmAcwWingZeroAirfoilMomentGivesZero(tc)
        % A symmetric section (Cm0_airfoil=0) must give Cm_acw=0 regardless
        % of AR/sweep -- the formula is a pure multiplicative scaling.
            received = SandCL3.Cm_acw_wing(0, 3, 40);
            expected = 0;
            fprintf('  [L3-S&C] testCmAcwWingZeroAirfoilMomentGivesZero: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Eqs. 16.5/16.7 -- Cm_cg_coefficient, full trim buildup including
        % the direct thrust-moment terms. Synthetic inputs, hand-computed.
        % ================================================================== %

        function testCmCgCoefficientFullBuildupHandComputed(tc)
        % CL=0.5, x_cg=20, x_acw=18, cbar=5, Cm_acw=-0.02, Cm_w_delta_f=0.01,
        % delta_f=5 deg, eta_h=0.9, S_h=20, S_w=100, CL_h=0.3, x_ach=45,
        % q=300, T=1000, z_t=1, F_p=50, x_p=10.
        %
        %   term1 = 0.5*(20-18)/5           = 0.2
        %   term2 = Cm_acw                  = -0.02
        %   term3 = 0.01*5                  = 0.05
        %   term4 = 0.9*(20/100)*0.3*(45-20)/5 = 0.9*0.2*0.3*25/5 = 0.27  (subtracted)
        %   term5 = (1000*1)/(300*100*5)    = 1000/150000 = 1/150 (subtracted)
        %   term6 = (50*(20-10))/(300*100*5)= 500/150000  = 1/300 (added)
        %
        %   Cmcg = 0.2 - 0.02 + 0.05 - 0.27 - 1/150 + 1/300
        %        = (60 - 6 + 15 - 81 - 2 + 1)/300 = -13/300 = -0.043333...
            received = SandCL3.Cm_cg_coefficient(0.5, 20, 18, 5, -0.02, 0.01, 5, ...
                0.9, 20, 100, 0.3, 45, 300, 1000, 1, 50, 10);
            expected = -13/300;
            fprintf('  [L3-S&C] testCmCgCoefficientFullBuildupHandComputed: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
        end

        function testCmCgCoefficientThrustTermGenuinelyEnters(tc)
        % Same inputs but F_p=0, T=0 -- the two DIRECT thrust-moment terms
        % must both vanish, giving a DIFFERENT (and computable) result:
        %   Cmcg' = 0.2 - 0.02 + 0.05 - 0.27 - 0 + 0 = -0.04
            received = SandCL3.Cm_cg_coefficient(0.5, 20, 18, 5, -0.02, 0.01, 5, ...
                0.9, 20, 100, 0.3, 45, 300, 0, 1, 0, 10);
            expected = -0.04;
            fprintf('  [L3-S&C] testCmCgCoefficientThrustTermGenuinelyEnters: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9);
            with_thrust = SandCL3.Cm_cg_coefficient(0.5, 20, 18, 5, -0.02, 0.01, 5, ...
                0.9, 20, 100, 0.3, 45, 300, 1000, 1, 50, 10);
            fprintf('  [L3-S&C] testCmCgCoefficientThrustTermGenuinelyEnters: no-thrust=%.6g, with-thrust=%.6g (must differ)\n', received, with_thrust);
            tc.verifyNotEqual(received, with_thrust, ...
                'Zeroing T and F_p must change Cm_cg_coefficient relative to the nonzero-thrust case.');
        end

        % ================================================================== %
        % Integration-style sanity checks on the real F16SandCL3 object.
        % RelTol-LOOSE per CLAUDE.md -- these check finiteness and physical
        % plausibility, NEVER an exact Brandt match (that belongs only in
        % sandc_brandt_comparison.m, informational, Tier 2).
        % ================================================================== %

        function testF16SandCL3XAcwFiniteAndNearBrandtWithinAFewPercent(tc)
        % x_acw includes Eq. 16.12's Mach-shift term evaluated at the real
        % cruise Mach (0.87, in the transonic-shift regime), which Brandt's
        % own simplified xacW=25.589 ft apparently omits (F16SandCL3.md's own
        % hand-check note) -- so a FEW-PERCENT gap (not an exact match) is
        % the expected, physically-explained result. 8% band chosen to
        % comfortably bracket the ~0.68 ft Mach-shift addition on a ~26 ft
        % baseline (~2.7%) while still catching a genuinely wrong wing
        % apex/sweep/MAC wiring bug (which would produce a much larger gap).
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.x_acw;
            expected = 25.589;
            fprintf('  [L3-S&C] testF16SandCL3XAcwFiniteAndNearBrandtWithinAFewPercent: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'RelTol', 0.08, ...
                'x_acw should land within a few % of Brandt''s xacW=25.589 ft (docs/subplans/10_stability_control.md "Ground Truth"), modulo the documented Mach-shift-term gap.');
            fprintf('  [L3-S&C] testF16SandCL3XAcwFiniteAndNearBrandtWithinAFewPercent: x_acw=%.6g must exceed x_apex_wing=%.6g\n', received, g3.x_apex_wing);
            tc.verifyGreaterThan(received, g3.x_apex_wing, ...
                'The wing aerodynamic center must lie aft of the wing apex.');
        end

        function testF16SandCL3XAchAftOfHtLeadingEdge(tc)
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.x_ach;
            fprintf('  [L3-S&C] testF16SandCL3XAchAftOfHtLeadingEdge: received=%.6g, expecting isfinite=true\n', received);
            tc.verifyTrue(isfinite(received));
            fprintf('  [L3-S&C] testF16SandCL3XAchAftOfHtLeadingEdge: x_ach=%.6g must exceed x_le_ht=%.6g\n', received, g3.x_le_ht);
            tc.verifyGreaterThan(received, g3.x_le_ht, ...
                'The HT aerodynamic center (quarter-MAC point) must lie aft of the HT leading edge.');
        end

        function testF16SandCL3CmAlphaFusIsPositiveAndFinite(tc)
        % Every factor in Eq. 16.25 (K_fus, W_f^2, L_f, c, S_w) is positive
        % for a real airframe, so Cm_alpha_fus must be strictly positive.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.Cm_alpha_fus;
            fprintf('  [L3-S&C] testF16SandCL3CmAlphaFusIsPositiveAndFinite: received=%.6g, expecting isfinite=true\n', received);
            tc.verifyTrue(isfinite(received));
            fprintf('  [L3-S&C] testF16SandCL3CmAlphaFusIsPositiveAndFinite: received=%.6g, expecting >0\n', received);
            tc.verifyGreaterThan(received, 0);
        end

        function testF16SandCL3XNpFiniteAndWithinFuselage(tc)
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.x_np;
            fprintf('  [L3-S&C] testF16SandCL3XNpFiniteAndWithinFuselage: received=%.6g, expecting isfinite=true\n', received);
            tc.verifyTrue(isfinite(received));
            fprintf('  [L3-S&C] testF16SandCL3XNpFiniteAndWithinFuselage: received=%.6g, expecting >0\n', received);
            tc.verifyGreaterThan(received, 0);
            fprintf('  [L3-S&C] testF16SandCL3XNpFiniteAndWithinFuselage: x_np=%.6g must be < L_fus=%.6g\n', received, g3.L_fus);
            tc.verifyLessThan(received, g3.L_fus, ...
                'x_np must be a physically plausible station within the fuselage length.');
        end

        function testF16SandCL3SMFiniteAndPhysicallyBounded(tc)
        % A physically-plausible static margin for ANY conventional aircraft
        % (stable or not) lies well within +-0.5 MAC; this is a broad,
        % independently-justified engineering bound, NOT the framework's own
        % specific computed number (which is separately, informationally,
        % reported and discussed in sandc_brandt_comparison.md per CLAUDE.md
        % -- never backfilled into this unit test).
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.SM;
            fprintf('  [L3-S&C] testF16SandCL3SMFiniteAndPhysicallyBounded: received=%.6g, expecting isfinite=true\n', received);
            tc.verifyTrue(isfinite(received));
            fprintf('  [L3-S&C] testF16SandCL3SMFiniteAndPhysicallyBounded: received=%.6g, expecting > -0.5\n', received);
            tc.verifyGreaterThan(received, -0.5);
            fprintf('  [L3-S&C] testF16SandCL3SMFiniteAndPhysicallyBounded: received=%.6g, expecting < 0.5\n', received);
            tc.verifyLessThan(received, 0.5);
        end

        function testF16SandCL3CmAlphaMatchesEq1610CrossCheck(tc)
        % Eq. 16.10 (Cm_alpha restated via the neutral point) is
        % ALGEBRAICALLY EQUIVALENT to Eq. 16.8 at the SAME inputs -- a real
        % internal-consistency check, not a Brandt comparison: if either
        % SandCL3.Cm_alpha or SandCL3.neutral_point/Cm_alpha_from_neutral_point
        % had a wiring bug, these two independently-implemented formulas
        % would very likely disagree.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received = s3.Cm_alpha;
            expected = s3.Cm_alpha_via_neutral_point();
            fprintf('  [L3-S&C] testF16SandCL3CmAlphaMatchesEq1610CrossCheck: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'Eq. 16.8 (Cm_alpha) and Eq. 16.10 (Cm_alpha via the neutral point) must agree at the same inputs.');
        end

        function testF16SandCL3DeltaAlphaL0IsExactlyZeroForAllMovingStabilator(tc)
        % Documented behavior: c_elev_frac=0 (F-16 all-moving stabilator, no
        % separate elevator) makes Eqs. 16.16/16.18 evaluate to exactly 0,
        % for ANY delta_e -- a real answer for THIS airframe, not a gap.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received1 = s3.Delta_alpha_L0(5);
            fprintf('  [L3-S&C] testF16SandCL3DeltaAlphaL0IsExactlyZeroForAllMovingStabilator: expected=0, received=%.6g\n', received1);
            tc.verifyEqual(received1, 0, 'AbsTol', 1e-12);
            received2 = s3.Delta_alpha_L0(-12.3);
            fprintf('  [L3-S&C] testF16SandCL3DeltaAlphaL0IsExactlyZeroForAllMovingStabilator: expected=0, received=%.6g\n', received2);
            tc.verifyEqual(received2, 0, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Constructor / DI / optimization-ready property design.
        % ================================================================== %

        function testConstructorRequiresAllSixArgs(tc)
        % geom/weights/aero/prop/ctrl are all REQUIRED injected collaborators
        % -- no silent default on any of them (same DI convention as
        % F16WeightsL3's four required arguments). ctrl (ControlSurfaceSizer)
        % is the newest of the five: F16SandCL3.Delta_alpha_L0 reads
        % obj.ctrl.c_elev_frac, so a caller who omits it must get
        % MATLAB:minrhs, not a silently-frozen c_elev_frac.
            expectedErrId = 'MATLAB:minrhs';
            try
                F16SandCL3();
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs (no args): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs: expecting error %s\n', 'MATLAB:minrhs');
            tc.verifyError(@() F16SandCL3(), expectedErrId);

            try
                F16SandCL3(f16a_spec_path(3));
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs (one arg): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs: expecting error %s\n', 'MATLAB:minrhs');
            tc.verifyError(@() F16SandCL3(f16a_spec_path(3)), expectedErrId);

            [g3, w3, a3, prop, ~] = TestSandCL3.makeF16Objects();
            try
                F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs (five args, ctrl omitted): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testConstructorRequiresAllSixArgs: expecting error %s\n', 'MATLAB:minrhs');
            tc.verifyError(@() F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop), expectedErrId, ...
                'ctrl (ControlSurfaceSizer) must be a required argument, not silently defaulted.');
        end

        function testConstructorRejectsWrongGeomTier(tc)
            [~, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            g2 = F16GeomL2(f16a_spec_path(2), prop);
            expectedErrId = 'MATLAB:validation:UnableToConvert';
            try
                F16SandCL3(f16a_spec_path(3), g2, w3, a3, prop, ctrl);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testConstructorRejectsWrongGeomTier: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testConstructorRejectsWrongGeomTier: expecting error %s\n', 'MATLAB:validation:UnableToConvert');
            tc.verifyError(@() F16SandCL3(f16a_spec_path(3), g2, w3, a3, prop, ctrl), ...
                expectedErrId);
        end

        function testDerivedPropertiesAreReadOnly(tc)
        % Mirrors TestGeomL2's testDerivedPropertiesAreReadOnly template.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);

            expectedErrId = 'MATLAB:class:noSetMethod';
            try
                setfield(s3, 'x_cg', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (x_cg): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property x_cg\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'x_cg', 1), expectedErrId); %#ok<SFLD>

            try
                setfield(s3, 'x_acw', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (x_acw): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property x_acw\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'x_acw', 1), expectedErrId); %#ok<SFLD>

            try
                setfield(s3, 'x_ach', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (x_ach): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property x_ach\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'x_ach', 1), expectedErrId); %#ok<SFLD>

            try
                setfield(s3, 'x_np', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (x_np): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property x_np\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'x_np', 1), expectedErrId); %#ok<SFLD>

            try
                setfield(s3, 'SM', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (SM): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property SM\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'SM', 1), expectedErrId); %#ok<SFLD>

            try
                setfield(s3, 'Cm_alpha', 1); %#ok<STFLD>
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly (Cm_alpha): expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testDerivedPropertiesAreReadOnly: expecting error %s for property Cm_alpha\n', 'MATLAB:class:noSetMethod');
            tc.verifyError(@() setfield(s3, 'Cm_alpha', 1), expectedErrId); %#ok<SFLD>
        end

        function testDerivedPropertiesLiveRecompute(tc)
        % Mirrors TestGeomL2's testWettedAreasLiveOnRead template -- mutate
        % an input IN PLACE and confirm the derived value tracks it with no
        % reconstruction of the object.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            v0 = s3.x_acw;
            g3.x_apex_wing = g3.x_apex_wing + 5;   % optimizer-style mutation
            received = s3.x_acw;
            expected = v0 + 5;
            fprintf('  [L3-S&C] testDerivedPropertiesLiveRecompute: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'x_acw must recompute live after geom.x_apex_wing mutates (a pure translation of the apex shifts x_ac_wing by the same amount).');
        end

        function testDerivedPropertiesLiveRecomputeXCg(tc)
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            v0 = s3.x_cg;
            w3.W_TO = w3.W_TO + 5000;   % optimizer-style mutation of the sizing-loop STATE
            received = s3.x_cg;
            fprintf('  [L3-S&C] testDerivedPropertiesLiveRecomputeXCg: baseline=%.6g, received=%.6g (must differ)\n', v0, received);
            tc.verifyNotEqual(received, v0, ...
                'x_cg must recompute live after weights.W_TO mutates.');
        end

        function testIsaChecks(tc)
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            r1 = isa(s3, 'StabControlBase');
            fprintf('  [L3-S&C] testIsaChecks: expected=true, received=%s for isa(s3, ''StabControlBase'')\n', mat2str(r1));
            tc.verifyTrue(r1);
            r2 = isa(s3, 'SandCModelL3');
            fprintf('  [L3-S&C] testIsaChecks: expected=true, received=%s for isa(s3, ''SandCModelL3'')\n', mat2str(r2));
            tc.verifyTrue(r2);
            r3 = isa(s3, 'handle');
            fprintf('  [L3-S&C] testIsaChecks: expected=true, received=%s for isa(s3, ''handle'')\n', mat2str(r3));
            tc.verifyTrue(r3);
        end

        % ================================================================== %
        % CL_w/CL_h -- CLOSED 2026-08-04 (were deliberately-failing TODO
        % tests; i_w/i_h are now real/reframed, see F16SandCL3.CL_w/CL_h).
        % ================================================================== %

        function testCLwUsesCitedWingIncidenceAndZeroLiftAoA(tc)
        %TESTCLWUSESCITEDWINGINCIDENCEANDZEROLIFTAOA  [Raymer 6th ed. Eq.
        %   16.13], i_w=0deg [T.O. 1F-16A-1], alpha_0L=-1.33deg [NACA 64A204,
        %   F16AeroL3.alpha_L0]. Expected value independently recomputed from
        %   the real CL_alpha_wing/alpha_L0 the object itself reports, never
        %   by calling CL_w a second time.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            fprintf('  [L3-S&C] testCLwUsesCitedWingIncidenceAndZeroLiftAoA: expected=0, received=%.6g for i_w_deg\n', s3.i_w_deg);
            tc.verifyEqual(s3.i_w_deg, 0, 'i_w must be 0deg per T.O. 1F-16A-1.');
            expected = s3.CL_alpha_wing * deg2rad(5 + s3.i_w_deg - a3.alpha_L0);
            received = s3.CL_w(5);
            fprintf('  [L3-S&C] testCLwUsesCitedWingIncidenceAndZeroLiftAoA: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'CL_w must equal CL_alpha_wing*deg2rad(alpha+i_w-alpha_0L) with the cited i_w/alpha_0L.');
        end

        function testCLhTakesIncidenceAsRequiredCallerArgument(tc)
        %TESTCLHTAKESINCIDENCEASREQUIREDCALLERARGUMENT  [Raymer 6th ed. Eq.
        %   16.14]. i_h is NOT a spec constant (all-moving stabilator) --
        %   CL_h(obj, alpha_deg, i_h_deg) requires the caller to supply the
        %   trim-condition incidence. epsilon/alpha_0Lh are both 0 (downwash
        %   out of scope; symmetric biconvex tail section). Expected value
        %   independently recomputed from the real CL_alpha_tail.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            expected = s3.CL_alpha_tail * deg2rad(5 + (-2) - 0 - 0);
            received = s3.CL_h(5, -2);
            fprintf('  [L3-S&C] testCLhTakesIncidenceAsRequiredCallerArgument: expected=%.6g, received=%.6g\n', expected, received);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'CL_h must equal CL_alpha_tail*deg2rad(alpha+i_h-epsilon-alpha_0Lh).');
            expectedErrId = 'MATLAB:minrhs';
            try
                s3.CL_h(5);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testCLhTakesIncidenceAsRequiredCallerArgument: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testCLhTakesIncidenceAsRequiredCallerArgument: expecting error %s\n', 'MATLAB:minrhs');
            tc.verifyError(@() s3.CL_h(5), expectedErrId, ...
                'CL_h must require i_h_deg as an explicit argument -- there is no spec default to fall back on.');
        end

        % ================================================================== %
        % Cm_cg_trim / Cm_acw -- CLOSED 2026-08-04 (Casey's follow-up
        % instruction: "Search Raymer's text for an equation for it. If you
        % cannot find it, then the users/students must be able to supply
        % their own value."). Raymer Eq. 16.19 IS a citable equation for
        % Cm_acw, so this is no longer a citation-GAP TODO test -- it is a
        % real, complete pipeline that gracefully returns NaN (not an error)
        % until the one remaining airfoil-table input, Cm0_airfoil_wing, is
        % user-supplied (defaults to NaN; f16a_L3.json
        % .stability_control.Cm0_airfoil_wing = null).
        % ================================================================== %

        function testF16SandCL3CmAcwIsNaNByDefault(tc)
        %TESTF16SANDCL3CMACWISNANBYDEFAULT  With no Cm0_airfoil_wing
        %   supplied in f16a_L3.json (null), obj.Cm_acw must be NaN, not an
        %   error -- SandCL3.Cm_acw_wing itself is real and complete
        %   (testCmAcwWingHandComputed proves that); only this one numeric
        %   input is currently missing.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            received1 = s3.Cm0_airfoil_wing;
            fprintf('  [L3-S&C] testF16SandCL3CmAcwIsNaNByDefault: expected=NaN, received=%.6g for Cm0_airfoil_wing\n', received1);
            tc.verifyTrue(isnan(received1), ...
                'Cm0_airfoil_wing must default to NaN -- no citable NACA 64A204 value exists in this repo/session.');
            received2 = s3.Cm_acw;
            fprintf('  [L3-S&C] testF16SandCL3CmAcwIsNaNByDefault: expected=NaN, received=%.6g for Cm_acw\n', received2);
            tc.verifyTrue(isnan(received2), ...
                'Cm_acw must propagate NaN gracefully while Cm0_airfoil_wing is unsupplied, not error.');
        end

        function testF16SandCL3CmCgTrimReturnsNaNUntilCm0AirfoilWingSupplied(tc)
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            val = s3.Cm_cg_trim(5, -2);
            fprintf('  [L3-S&C] testF16SandCL3CmCgTrimReturnsNaNUntilCm0AirfoilWingSupplied: expected=NaN, received=%.6g\n', val);
            tc.verifyTrue(isnan(val), ...
                'Cm_cg_trim must return NaN (not error) while Cm0_airfoil_wing is unsupplied.');
            expectedErrId = 'MATLAB:minrhs';
            try
                s3.Cm_cg_trim(5);
                actualErrId = '(none thrown)';
                actualErrMsg = '(none thrown)';
            catch ME
                actualErrId = ME.identifier;
                actualErrMsg = ME.message;
            end
            fprintf('  [L3-S&C] testF16SandCL3CmCgTrimReturnsNaNUntilCm0AirfoilWingSupplied: expected_error=%s, received_error=%s (%s)\n', ...
                expectedErrId, actualErrId, actualErrMsg);
            fprintf('  [L3-S&C] testF16SandCL3CmCgTrimReturnsNaNUntilCm0AirfoilWingSupplied: expecting error %s\n', 'MATLAB:minrhs');
            tc.verifyError(@() s3.Cm_cg_trim(5), expectedErrId, ...
                'Cm_cg_trim must require i_h_deg as an explicit argument, same reframing as CL_h.');
        end

        function testF16SandCL3CmCgTrimIsFiniteOnceCm0AirfoilWingIsSupplied(tc)
        %TESTF16SANDCL3CMCGTRIMISFINITEONCECM0AIRFOILWINGISSUPPLIED
        %   Cm0_airfoil_wing is a plain mutable input property -- once the
        %   user/student fills it in (here, an arbitrary synthetic test
        %   value, NOT a citation for the real F-16 airfoil), the full
        %   Eq. 16.5/16.7 pipeline must produce a real, finite, physically
        %   bounded trim-moment coefficient.
            [g3, w3, a3, prop, ctrl] = TestSandCL3.makeF16Objects();
            s3 = F16SandCL3(f16a_spec_path(3), g3, w3, a3, prop, ctrl);
            s3.Cm0_airfoil_wing = -0.01;   % synthetic test value, not a citation
            val = s3.Cm_cg_trim(5, -2);
            fprintf('  [L3-S&C] testF16SandCL3CmCgTrimIsFiniteOnceCm0AirfoilWingIsSupplied: received=%.6g, expecting isfinite=true\n', val);
            tc.verifyTrue(isfinite(val), ...
                'Cm_cg_trim must be finite once Cm0_airfoil_wing is supplied.');
            fprintf('  [L3-S&C] testF16SandCL3CmCgTrimIsFiniteOnceCm0AirfoilWingIsSupplied: |received|=%.6g, expected < 5\n', abs(val));
            tc.verifyLessThan(abs(val), 5, ...
                'A pitching-moment coefficient this large would be physically implausible.');
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function [g3, w3, a3, prop, ctrl] = makeF16Objects()
        %MAKEF16OBJECTS  Real F16GeomL3 + F16WeightsL3 (W_TO/W_energy set to
        %   plausible sizing-loop STATE values, mirroring
        %   TestSubsystemsL3.makeGeomAndWeights) + F16AeroL3 + F16PropL2 (no
        %   L3 propulsion tier exists repo-wide) + ControlSurfaceSizer, the
        %   SAME f16a_control_surfaces() factory
        %   design_study_02_L2.m/design_study_03_L3.m use -- c_elev_frac=0
        %   [Raymer 6th ed. Table 6.5, F-16 all-moving stabilator] is the
        %   ONLY entry F16SandCL3.Delta_alpha_L0 reads off this object.
            prop = F16PropL2(f16a_spec_path(2));
            g3   = F16GeomL3(f16a_spec_path(3), prop);
            w3   = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), g3, prop);
            w3.W_TO     = 31377;    % Brandt F-16A TOGW [readme_wt.md]
            w3.W_energy = 6294;     % legacy Fuel1+2+3 = 2098*3, same anchor as TestSandCL2
            a3   = F16AeroL3(g3, f16a_spec_path(3), f16a_control_surfaces());
            ctrl = f16a_control_surfaces();
        end

    end

end
