classdef TestB777Disciplines < matlab.unittest.TestCase
%TESTB777DISCIPLINES  Tier-1 unit/correctness tests for the Boeing 777-200LR
%   Level-1 discipline classes (B777GeomL1 / B777AeroL1 / B777PropL1 /
%   B777WeightsL1 / B777TailL1), metabook worked Example 4.2.
%
%   These are hand-computed spot checks: every "expected" value is derived
%   independently from the cited metabook Eq/Table (or an independent
%   textbook constant), NOT read back out of the class under test. The
%   comment block above properties(Constant) shows each derivation.
%
%   Construction (coordinator-verified stack):
%       sp = b777_spec_path(1);
%       geom = B777GeomL1(sp);  prop = B777PropL1(sp);
%       aero = B777AeroL1(geom, sp);  tail = B777TailL1();
%       wts  = B777WeightsL1(sp, geom, prop);
%
%   ── HAND-COMPUTED EXPECTED VALUES AND THEIR DERIVATIONS ──────────────────
%
%   GEOMETRY [metabook Eq. 4.58; Table 4.3]
%     S_wet = S_wet_rest + 2*S_ref = 19081 + 2*4605 = 28291 ft^2   [Eq. 4.58]
%     b_wing = sqrt(AR*S_ref) = sqrt(9.8*4605) = sqrt(45129)
%            = 212.4359314... ft                        [definitional span]
%     cbar_wing = S_ref/b_wing = 4605 / 212.4359314 = 21.6771299 ft
%            (standard mean chord S/b, no taper at L1)   [metabook Eq. 11.5 note]
%     S_wet tracks S live: set S_ref = 5000 -> S_wet = 19081 + 2*5000
%            = 29081 ft^2  (S_wet_rest unchanged; Dependent getter).
%
%   AERODYNAMICS [metabook Eq. 4.8/4.44; Eq. 4.58; Eq. 2.10; §4.11]
%     CD0_clean = Cfe*(S_wet/S_ref) = 0.0026*(28291/4605)
%               = 0.0026*6.1435396... = 0.01597320...     [Eq. 4.8/4.58]
%     K1_clean  = 1/(pi*AR*e_clean) = 1/(pi*9.8*0.85)
%               = 1/26.1694668... = 0.03821239...          [Eq. 2.10]
%     Five printed metabook config polars' CD0 (Cfe*Swet/Sref + Delta):
%       CD0_clean is 0.01597320; the JSON config table prints 0.01597.
%       The Delta_CD0 increments are (table CD0 - table clean CD0):
%         clean:   +0        -> 0.01597320
%         TO_gu:   +0.02000  -> 0.03597320
%         TO_gd:   +0.04500  -> 0.06097320
%         L_gu:    +0.07500  -> 0.09097320
%         L_gd:    +0.10000  -> 0.11597320
%         approach:+0.07250  -> 0.08847320
%       (the printed metabook rows 0.01597/0.03597/0.06097/0.09097/0.11597/
%        0.08847 differ from these only in the ~3.3e-6 gap between the JSON's
%        rounded clean 0.01597 and the live-computed 0.0159733; the Delta
%        increments are exact table differences -- so get_config_polar's CD0
%        equals live_clean + Delta, checked to AbsTol 1e-5.)
%     Config CLmax (PHYSICAL) [Roskam Table 3.1; USER decision 2026-08-14]:
%       clean 0.9, takeoff (both) 2.0, landing (both) 2.6, approach 2.21.
%     CD0 tracks S (grow S_ref -> S_wet grows -> CD0 changes); K1 tracks AR.
%
%   PROPULSION [metabook Eqs. 4.55/10.9; Table 10.1]
%     thrust_lapse(state) = sigma^m, sigma = rho/rho_SL, m = 0.6.
%       rho_SL = 0.002377 slug/ft^3 [Mattingly App. B, PropL1.RHO_SL]. The
%       expected is computed in-test from the LIVE state.rho with the
%       explicit formula (state.rho/0.002377)^0.6 -- NOT by calling
%       thrust_lapse -- so the test checks the class delegates to the right
%       density-ratio law, independent of the class's own arithmetic.
%     get_TSFC(any) = 0.52 1/hr exactly (the GE90 deck value) [Table 10.1].
%     lapse_exponent_m = 0.6 [metabook Eqs. 4.55-4.57; decision D5].
%
%   WEIGHTS [Raymer Table 3.1 jet_transport; metabook §4.12.1 Algorithm 2]
%     At the BASELINE design point (W_TO = 766800, geom at S_ref = 4605 with
%     the self-consistent baseline tail areas, prop.T_SL = 220000) all four
%     delta terms are zero, so OEW collapses to the pure regression:
%       We/W0 = Kvs*A*W0^C = 1.00*1.02*766800^(-0.06)
%       766800^(-0.06) = exp(-0.06*ln(766800))
%                      = exp(-0.06*13.550048) = exp(-0.8130029)
%                      = 0.4435256...
%       We/W0 = 1.02*0.4435256 = 0.4523961...
%       OEW    = 0.4523961*766800 = 346,897.3... lbf
%     RelTol 2e-3 (not tighter): the baseline tail areas are computed
%     self-consistently through B777TailL1, so the tail delta is zero only to
%     the tail toolbox's own numeric reproduction; 2e-3 covers that
%     self-consistent residual (the brief's stated allowance), while a real
%     wiring error (a missing regression term) would move OEW by >> 0.2%.
%     Monotonic delta checks: OEW(766800) rises when geom.S_ref grows (wing
%     areal delta, +10 lb/ft^2 [Table 15.2]) and when geom.S_ht grows (HT
%     areal delta, +5.5 lb/ft^2 [Table 15.2]).
%
%   TAIL [metabook Ch.8 Eqs. 8.1/8.2 c_HT=1.0, c_VT=0.09; wing-mounted arm]
%     L_arm = 0.525*L_fus = 0.525*209 = 109.725 ft
%       *** the 0.525 wing-mounted-engine arm fraction is UNCITED in the repo
%           extracts (TailL1.compute_tail_arm_wing_mounted's labeled TODO) --
%           guarded by testTODO_WingMountedTailArmUncited below. ***
%     S_ht = c_HT*cbar*S_ref/L_arm
%          = 1.0*21.67692*4605/109.725 = 99822.2/109.725 ~= 909.75 ft^2
%     S_vt = c_VT*b*S_ref/L_arm
%          = 0.09*212.43593*4605/109.725 = 88044.0/109.725 ~= 802.41 ft^2
%     (c_HT=1.0, c_VT=0.09, 0.525 are hardcoded as independent citation
%      literals in the test, NOT read from the object.)

    properties (Constant)
        % ── Independent citation constants (not read from any class) ──────
        RHO_SL        = 0.002377    % slug/ft^3 [Mattingly App. B; PropL1.RHO_SL]
        LAPSE_M       = 0.6         % [metabook Eq. 10.9]
        C_HT          = 1.00        % [metabook Ch.8 Eq. 8.2; Raymer Table 6.4 jet-transport]
        C_VT          = 0.09        % [metabook Ch.8 Eq. 8.1; Raymer Table 6.4 jet-transport]
        ARM_FRAC      = 0.525       % [UNCITED wing-mounted arm; TailL1 TODO]

        % ── Hand-computed geometry (metabook Eq. 4.58, Table 4.3) ─────────
        S_WET_BASE    = 28291       % ft^2  19081 + 2*4605
        B_WING        = 212.4359314 % ft    sqrt(9.8*4605)
        CBAR_WING     = 21.6771299  % ft    4605/sqrt(9.8*4605) = sqrt(4605/9.8)

        % ── Hand-computed aero (metabook Eq. 4.8, Eq. 2.10) ───────────────
        CD0_CLEAN     = 0.0159732030   % 0.0026*(28291/4605) = 0.0026*6.14353963
        K1_CLEAN      = 0.0382123920   % 1/(pi*9.8*0.85) = 1/26.1694668

        % ── Hand-computed weights baseline OEW (Raymer Table 3.1) ─────────
        OEW_BASELINE  = 346897.3    % lbf  1.02*766800^-0.06 * 766800
        W0_BASELINE   = 766800      % lbf  [metabook Table 4.3]
    end

    methods (Static)
        function [geom, prop, aero, tail, wts] = buildStack()
            sp   = b777_spec_path(1);
            geom = B777GeomL1(sp);
            prop = B777PropL1(sp);
            aero = B777AeroL1(geom, sp);
            tail = B777TailL1();
            wts  = B777WeightsL1(sp, geom, prop);
        end
    end

    % ==================================================================== %
    methods (Test)

        % ---- GEOMETRY ---------------------------------------------------- %

        function testSwetBaseline(tc)
        % S_wet = S_wet_rest + 2*S_ref = 19081 + 2*4605 = 28291 ft^2 [Eq. 4.58].
            geom = B777GeomL1(b777_spec_path(1));
            fprintf('\n    S_wet: received = %.4f ft^2,  hand-computed = %d ft^2\n', ...
                geom.get_S_wet(), tc.S_WET_BASE);
            tc.verifyEqual(geom.get_S_wet(), tc.S_WET_BASE, 'AbsTol', 1, ...
                'S_wet must be S_wet_rest + 2*S_ref = 28291 ft^2 [metabook Eq. 4.58].');
            % Dependent property and accessor agree.
            tc.verifyEqual(geom.S_wet, geom.get_S_wet(), 'AbsTol', 1e-9);
        end

        function testSpanAndMeanChord(tc)
        % b = sqrt(AR*S_ref) = sqrt(9.8*4605); cbar = S_ref/b [metabook Eq. 11.5 note].
            geom = B777GeomL1(b777_spec_path(1));
            fprintf('\n    b_wing = %.6f ft (hand %.6f);  cbar_wing = %.6f ft (hand %.6f)\n', ...
                geom.b_wing, tc.B_WING, geom.cbar_wing, tc.CBAR_WING);
            tc.verifyEqual(geom.b_wing, tc.B_WING, 'RelTol', 1e-6, ...
                'b_wing must be sqrt(9.8*4605) = 212.44 ft.');
            tc.verifyEqual(geom.cbar_wing, tc.CBAR_WING, 'RelTol', 1e-6, ...
                'cbar_wing must be S_ref/b_wing = 21.68 ft.');
        end

        function testSwetTracksSrefLive(tc)
        % Dependent S_wet must follow a mutated wing area with NO reconstruction
        % (the live CD0(S) coupling): set S_ref = 5000 -> S_wet = 19081 + 2*5000
        % = 29081 ft^2 (S_wet_rest is unchanged).
            geom = B777GeomL1(b777_spec_path(1));
            geom.S_ref = 5000;               % optimizer-style in-place mutation
            expected = 19081 + 2*5000;       % = 29081, hand-computed [Eq. 4.58]
            fprintf('\n    S_wet after S_ref=5000: received = %.4f ft^2,  hand = %d ft^2\n', ...
                geom.S_wet, expected);
            tc.verifyEqual(geom.S_wet, expected, 'AbsTol', 1e-9, ...
                'S_wet must track a mutated S_ref live (19081 + 2*5000 = 29081).');
        end

        function testGeomDerivedReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning must error.
            geom = B777GeomL1(b777_spec_path(1));
            tc.verifyError(@() setfield(geom, 'S_wet', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(geom, 'b_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testStatisticalMethodsError(tc)
        % The B777 L1 geometry has a real planform; the W_TO-regression methods
        % it inherits from GeometryModelL1 must ERROR (fail loud), not return a
        % wrong-model number.
            geom = B777GeomL1(b777_spec_path(1));
            tc.verifyError(@() geom.get_S_wet_statistical(766800), ...
                'B777GeomL1:notApplicable');
            tc.verifyError(@() geom.get_L_fus(766800), ...
                'B777GeomL1:notApplicable');
        end

        % ---- AERODYNAMICS ------------------------------------------------ %

        function testCleanDragPolar(tc)
        % CD0 = Cfe*(S_wet/S_ref) = 0.0026*28291/4605 = 0.0159733 [Eq. 4.8/4.58];
        % K1 = 1/(pi*AR*e_clean) = 1/(pi*9.8*0.85) = 0.0382103 [Eq. 2.10]; K2 = 0.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            polar = aero.drag_polar(AircraftState(40000, 0.84));
            fprintf('\n    clean CD0 = %.8f (hand %.8f);  K1 = %.8f (hand %.8f);  K2 = %.8f\n', ...
                polar.CD0, tc.CD0_CLEAN, polar.K1, tc.K1_CLEAN, polar.K2);
            tc.verifyEqual(polar.CD0, tc.CD0_CLEAN, 'RelTol', 1e-4, ...
                'Clean CD0 must be Cfe*(S_wet/S_ref) = 0.015973 [metabook Eq. 4.8].');
            tc.verifyEqual(polar.K1, tc.K1_CLEAN, 'RelTol', 1e-4, ...
                'Clean K1 must be 1/(pi*9.8*0.85) = 0.038210 [metabook Eq. 2.10].');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, ...
                'Clean K2 must be 0 (uncambered-basis metabook polar).');
        end

        function testConfigPolarCD0(tc)
        % get_config_polar's CD0 for each config must equal the live clean CD0
        % plus that config's printed Delta_CD0 increment [metabook §4.11].
        % The independent expecteds are live_clean_CD0 + (table CD0 - table
        % clean CD0), the exact printed-table differences.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            clean = tc.CD0_CLEAN;   % hand-computed 0.0026*28291/4605
            configs  = ["clean", "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                        "landing_flaps_gear_up", "landing_flaps_gear_down", "approach"];
            % printed-table CD0 increments over the printed clean 0.01597:
            deltas   = [0.0,    0.02000, 0.04500, 0.07500, 0.10000, 0.07250];
            for i = 1:numel(configs)
                cfg = aero.get_config_polar(configs(i));
                expected = clean + deltas(i);
                fprintf('    %-26s CD0 = %.8f  (hand %.8f)\n', configs(i), cfg.CD0, expected);
                tc.verifyEqual(cfg.CD0, expected, 'AbsTol', 1e-5, ...
                    sprintf('%s CD0 must be clean CD0 + printed Delta.', configs(i)));
            end
        end

        function testConfigCLmaxPhysical(tc)
        % PHYSICAL config CLmax [Roskam Table 3.1; USER decision 2026-08-14]:
        % clean 0.9, takeoff (both) 2.0, landing (both) 2.6, approach 2.21.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(aero.get_config_polar("clean").CLmax, 0.9, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_config_polar("takeoff_flaps_gear_up").CLmax, 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_config_polar("takeoff_flaps_gear_down").CLmax, 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_config_polar("landing_flaps_gear_up").CLmax, 2.6, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_config_polar("landing_flaps_gear_down").CLmax, 2.6, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_config_polar("approach").CLmax, 2.21, 'AbsTol', 1e-12);
            % Clean get_CLmax accessor agrees.
            tc.verifyEqual(aero.get_CLmax(AircraftState(0, 0.3)), 0.9, 'AbsTol', 1e-12);
            % Takeoff/landing thin wrappers.
            tc.verifyEqual(aero.get_CLmax_TO(), 2.0, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_CLmax_L(), 2.6, 'AbsTol', 1e-12);
        end

        function testCD0TracksSrefLive(tc)
        % CD0 = Cfe*S_wet/S_ref and S_wet = S_wet_rest + 2*S_ref, so CD0 is
        % Cfe*(S_wet_rest + 2*S_ref)/S_ref = Cfe*(S_wet_rest/S_ref + 2). Growing
        % S_ref lowers S_wet_rest/S_ref, so clean CD0 DECREASES. Independent
        % hand value at S_ref = 6000: 0.0026*(19081/6000 + 2) = 0.0026*5.180167
        % = 0.01346843.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            st = AircraftState(40000, 0.84);
            cd0_0 = aero.drag_polar(st).CD0;
            geom.S_ref = 6000;                 % in-place mutation, no rebuild
            expected = 0.0026*(19081/6000 + 2);
            cd0_1 = aero.drag_polar(st).CD0;
            fprintf('\n    CD0 at S_ref=4605: %.8f;  at S_ref=6000: %.8f (hand %.8f)\n', ...
                cd0_0, cd0_1, expected);
            tc.verifyEqual(cd0_1, expected, 'RelTol', 1e-6, ...
                'CD0 must track a mutated S_ref live via the Dependent S_wet.');
            tc.verifyLessThan(cd0_1, cd0_0, ...
                'A larger wing has lower Cfe*Swet/Sref clean CD0 (Swet_rest/Sref drops).');
        end

        function testK1TracksAR(tc)
        % K1 = 1/(pi*AR*e_clean); growing AR lowers K1. Independent hand value
        % at AR = 12: 1/(pi*12*0.85) = 1/32.044245 = 0.0312069.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            st = AircraftState(40000, 0.84);
            k1_0 = aero.drag_polar(st).K1;
            geom.AR = 12;                      % in-place mutation
            expected = 1/(pi*12*0.85);
            k1_1 = aero.drag_polar(st).K1;
            fprintf('\n    K1 at AR=9.8: %.8f;  at AR=12: %.8f (hand %.8f)\n', k1_0, k1_1, expected);
            tc.verifyEqual(k1_1, expected, 'RelTol', 1e-9, ...
                'K1 must track a mutated AR live: 1/(pi*12*0.85).');
            tc.verifyLessThan(k1_1, k1_0, 'A higher AR gives a lower induced factor K1.');
        end

        function testConfigPolarRejectsUnknownConfig(tc)
        % get_config_polar validates its config against the six known names.
            [geom, ~, aero] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyError(@() aero.get_config_polar("supersonic_dash"), ...
                'MATLAB:validators:mustBeMember');
        end

        % ---- PROPULSION -------------------------------------------------- %

        function testThrustLapseIsSigmaToTheM(tc)
        % thrust_lapse = (rho/rho_SL)^0.6. Expected is computed from the LIVE
        % state.rho with the explicit formula (not by calling thrust_lapse),
        % using the independent constant rho_SL = 0.002377 and m = 0.6.
            [~, prop] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            st = AircraftState(40000, 0.84);
            sigma    = st.rho / tc.RHO_SL;
            expected = sigma ^ tc.LAPSE_M;
            received = prop.thrust_lapse(st);
            fprintf('\n    thrust_lapse(40kft, M0.84): received = %.8f,  sigma^0.6 = %.8f (sigma=%.6f)\n', ...
                received, expected, sigma);
            tc.verifyEqual(received, expected, 'RelTol', 1e-4, ...
                'thrust_lapse must be (rho/rho_SL)^0.6 [metabook Eq. 10.9].');
            % get_thrust_lapse alias and no-afterburner mil-on-AB scale agree.
            tc.verifyEqual(prop.get_thrust_lapse(st), received, 'AbsTol', 1e-12);
            tc.verifyEqual(prop.thrust_lapse_mil_on_AB_scale(st), received, 'AbsTol', 1e-12, ...
                'A high-bypass transport has no AB: mil-on-AB scale == thrust_lapse.');
        end

        function testTSFCIsDeckValue(tc)
        % get_TSFC = 0.52 1/hr exactly (the GE90 deck value) [metabook Table 10.1],
        % and is state-independent at L1.
            [~, prop] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(prop.get_TSFC(AircraftState(40000, 0.84)), 0.52, 'AbsTol', 1e-12, ...
                'get_TSFC must be the 0.52 1/hr GE90 deck value [metabook Table 10.1].');
            tc.verifyEqual(prop.get_TSFC(AircraftState(0, 0.3)), 0.52, 'AbsTol', 1e-12, ...
                'get_TSFC must be state-independent at L1.');
            tc.verifyEqual(prop.lookup_TSFC(AircraftState(40000, 0.84)), 0.52, 'AbsTol', 1e-12, ...
                'lookup_TSFC alias must match get_TSFC.');
        end

        function testLapseExponentInput(tc)
        % lapse_exponent_m = 0.6 [metabook Eqs. 4.55-4.57; decision D5].
            [~, prop] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(prop.lapse_exponent_m, 0.6, 'AbsTol', 1e-12);
        end

        % ---- WEIGHTS ----------------------------------------------------- %

        function testOEWBaselineRegression(tc)
        % At the baseline design point (all four deltas zero) OEW collapses to
        % We/W0*W0 = 1.02*766800^-0.06 * 766800 = 346,897 lbf [Raymer Table 3.1].
        % The tail must be sized first so the baseline HT/VT delta is zero.
            [geom, ~, ~, tail, wts] = TestB777Disciplines.buildStack();
            t = tail.size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
            geom.S_ht = t.S_ht;   % write the baseline tail areas back
            geom.S_vt = t.S_vt;
            received = wts.OEW(tc.W0_BASELINE);
            fprintf('\n    OEW(766800) baseline = %.2f lbf (hand-computed regression %.1f, %+.3f%%)\n', ...
                received, tc.OEW_BASELINE, 100*(received - tc.OEW_BASELINE)/tc.OEW_BASELINE);
            tc.verifyEqual(received, tc.OEW_BASELINE, 'RelTol', 2e-3, ...
                ['OEW(766800) at baseline geometry must be the pure We/W0 ', ...
                 'regression 1.02*766800^-0.06*766800 = 346,897 lbf ', ...
                 '(deltas ~0; RelTol 2e-3 for the self-consistent tail residual).']);
        end

        function testOEWIncreasesWithWingArea(tc)
        % Growing geom.S_ref adds a POSITIVE wing areal delta
        % (dens_wing = 10 lb/ft^2 [Raymer Table 15.2]) at fixed W_TO, so
        % OEW(766800) must increase. Independent lower bound on the increment:
        % 10*(5000 - 4605) = 3950 lbf.
            [geom, ~, ~, tail, wts] = TestB777Disciplines.buildStack();
            t = tail.size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
            geom.S_ht = t.S_ht;  geom.S_vt = t.S_vt;
            oew_0 = wts.OEW(tc.W0_BASELINE);
            geom.S_ref = 5000;                        % in-place mutation
            oew_1 = wts.OEW(tc.W0_BASELINE);
            fprintf('\n    OEW at S_ref=4605: %.1f;  at S_ref=5000: %.1f (delta %+.1f, hand-min wing delta 3950)\n', ...
                oew_0, oew_1, oew_1 - oew_0);
            tc.verifyGreaterThan(oew_1, oew_0, ...
                'OEW must rise with wing area (positive Table 15.2 areal delta).');
            tc.verifyGreaterThanOrEqual(oew_1 - oew_0, 10*(5000 - 4605) - 1, ...
                'The OEW increment must be at least the 10 lb/ft^2 wing areal delta.');
        end

        function testOEWIncreasesWithTailArea(tc)
        % Growing geom.S_ht adds a POSITIVE HT areal delta (dens_HT = 5.5
        % lb/ft^2 [Raymer Table 15.2]) at fixed W_TO. Independent increment:
        % 5.5*(S_ht + 100 - S_ht) = 550 lbf for a +100 ft^2 bump.
            [geom, ~, ~, tail, wts] = TestB777Disciplines.buildStack();
            t = tail.size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
            geom.S_ht = t.S_ht;  geom.S_vt = t.S_vt;
            oew_0 = wts.OEW(tc.W0_BASELINE);
            geom.S_ht = geom.S_ht + 100;              % in-place mutation
            oew_1 = wts.OEW(tc.W0_BASELINE);
            fprintf('\n    OEW HT +100 ft^2: delta = %+.4f lbf (hand 5.5*100 = 550)\n', oew_1 - oew_0);
            tc.verifyEqual(oew_1 - oew_0, 5.5*100, 'AbsTol', 1e-6, ...
                'A +100 ft^2 HT area must add exactly 5.5*100 = 550 lbf [Table 15.2].');
        end

        function testOEWRejectsNonPositiveWTO(tc)
        % OEW's arguments block guards W_TO (mustBePositive, mustBeFinite).
            [geom, ~, ~, tail, wts] = TestB777Disciplines.buildStack();
            t = tail.size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
            geom.S_ht = t.S_ht;  geom.S_vt = t.S_vt;
            tc.verifyError(@() wts.OEW(-5), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() wts.OEW(Inf), 'MATLAB:validators:mustBeFinite');
        end

        % ---- TAIL -------------------------------------------------------- %

        function testTailAreas(tc)
        % Volume-coefficient tail areas [metabook Ch.8]:
        %   L_arm = 0.525*209 = 109.725 ft   [wing-mounted arm; UNCITED TODO]
        %   S_ht = c_HT*cbar*S/L_arm = 1.0*cbar*4605/109.725
        %   S_vt = c_VT*b*S/L_arm    = 0.09*b*4605/109.725
        % Expected computed from the INDEPENDENT citation literals c_HT=1.0,
        % c_VT=0.09, ARM_FRAC=0.525 (NOT read from the tail object) and the
        % passed geometry, so it cannot fail on a shared coefficient error.
            [geom, ~, ~, tail] = TestB777Disciplines.buildStack(); %#ok<ASGLU>
            S_ref = geom.S_ref;  b = geom.b_wing;  cbar = geom.cbar_wing;  L_fus = geom.L_fus;
            r = tail.size(S_ref, b, cbar, L_fus);

            L_arm       = tc.ARM_FRAC * L_fus;              % 0.525*209 = 109.725
            expected_ht = tc.C_HT * cbar  * S_ref / L_arm;  % ~909.75
            expected_vt = tc.C_VT * b     * S_ref / L_arm;  % ~802.41
            fprintf('\n    S_ht = %.4f ft^2 (hand %.4f);  S_vt = %.4f ft^2 (hand %.4f)\n', ...
                r.S_ht, expected_ht, r.S_vt, expected_vt);
            tc.verifyEqual(r.S_ht, expected_ht, 'RelTol', 1e-9, ...
                'S_ht must be c_HT*cbar*S/(0.525*L_fus) [metabook Ch.8 Eq. 8.2].');
            tc.verifyEqual(r.S_vt, expected_vt, 'RelTol', 1e-9, ...
                'S_vt must be c_VT*b*S/(0.525*L_fus) [metabook Ch.8 Eq. 8.1].');
        end

        function testTailCoefficientsAreUncorrectedJetTransport(tc)
        % A jet transport takes the UNCORRECTED base coefficients
        % (lookup_tail_volume_coeffs, NOT the RSS/all-moving corrected form):
        % c_HT = 1.0, c_VT = 0.09 [metabook Ch.8; Raymer Table 6.4 jet-transport].
            tail = B777TailL1();
            tc.verifyEqual(tail.c_HT, tc.C_HT, 'AbsTol', 1e-12, ...
                'c_HT must be the uncorrected 1.0 jet-transport value.');
            tc.verifyEqual(tail.c_VT, tc.C_VT, 'AbsTol', 1e-12, ...
                'c_VT must be the uncorrected 0.09 jet-transport value.');
        end

        % ---- DELIBERATELY-FAILING TODO (missing citation) ---------------- %

        function testTODO_WingMountedTailArmUncited(tc)
        % DELIBERATELY-FAILING TODO -- repo citation policy.
        %
        % B777TailL1.size uses the wing-mounted-engine tail arm
        %   L_HT = L_VT = 0.525 * L_fus
        % via TailL1.compute_tail_arm_wing_mounted. The 0.525 (midpoint of the
        % 50-55% wing-mounted-engine tail-arm range) is *** UNCITED IN THE REPO
        % EXTRACTS ***: metabook_data.md carries the jet-transport tail-volume
        % coefficients (c_HT=1.0, c_VT=0.09) but NOT the wing-mounted arm
        % fraction, and no other file in docs/reference_extracts/ transcribes
        % it. TailL1.compute_tail_arm_wing_mounted's own header flags it as a
        % labeled TODO.
        %
        % Per repo policy a missing-citation TODO gets a deliberately-failing
        % test, clearly labeled, that turns GREEN only when the primary Raymer
        % text (the wing-mounted-engine 50-55% tail-arm rule) is transcribed
        % into a docs/reference_extracts/ file. This is the ONLY expected
        % failure in this Tier-1 suite. It is NOT a code bug and must NOT be
        % "fixed" by inventing a citation or deleting the test.
            tc.verifyFail(['TODO(citation): the 0.525 wing-mounted-engine tail-arm ', ...
                'fraction in TailL1.compute_tail_arm_wing_mounted is UNCITED in ', ...
                'the repo reference extracts (metabook_data.md has the ', ...
                'jet-transport tail-volume coefficients but not the arm ', ...
                'fraction). Transcribe the primary Raymer wing-mounted-engine ', ...
                '50-55% tail-arm text into docs/reference_extracts/ and cite it ', ...
                'in TailL1.compute_tail_arm_wing_mounted, then delete this test.']);
        end

    end
end
