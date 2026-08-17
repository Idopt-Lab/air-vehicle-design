classdef TestB777Disciplines < matlab.unittest.TestCase
%TESTB777DISCIPLINES  Tier-1 unit/correctness tests for the Boeing 777-200LR
%   discipline classes: L2 geometry (B777GeomL2, real trapezoidal planform +
%   exposed areas, metabook Table 7.2/7.3) and L2 component-build-up weights
%   (B777WeightsL2, Algorithm 5), plus L1 aero/prop/tail (B777AeroL1 /
%   B777PropL1 / B777TailL1). metabook worked Examples 4.2 and 7.1.
%
%   These are hand-computed spot checks: every "expected" value is derived
%   independently from the cited metabook Eq/Table (or an independent
%   textbook constant), NOT read back out of the class under test. The
%   comment block above properties(Constant) shows each derivation.
%
%   Construction (coordinator-verified stack):
%       sp = b777_spec_path(1);
%       geom = B777GeomL2(sp);  prop = B777PropL1(sp);
%       aero = B777AeroL1(geom, sp);  tail = B777TailL1();
%       wts  = B777WeightsL2(sp, geom, prop);
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
%   GEOMETRY L2 -- EXPOSED AREAS + MAC [metabook Table 7.2/7.3, Eq. 7.2-7.9]
%     From the Table 7.2 trapezoids B777GeomL2 computes the EXPOSED planform
%     areas (wing 3923, H-tail 903, V-tail 604 ft^2) and the fuselage WETTED
%     area (13125 ft^2) -- metabook Table 7.3 -- and the MAC / 40%-MAC location
%     (Eq. 7.5-7.9: MAC_W 27.9, x40%MAC_W 100.4, x40%MAC_HT 192.1, x40%MAC_VT
%     187.6). The exposed WING area scales with S_ref (the fixed fuselage
%     covers relatively less as the wing grows); the H/V-tail and fuselage are
%     held. The metabook prints the exposed areas but NOT the exposed-area
%     equations, so the geometry reproduces Table 7.3 by construction (the local
%     body widths are tuned to it) -- these tests assert the reproduction.
%
%   WEIGHTS L2 -- COMPONENT BUILD-UP [metabook §7.2 Algorithm 5, Table 7.1/7.3]
%     OEW is the sum of individual component weights (NOT the L1 empty-weight
%     fraction), so it responds to W0, S_ref (via the exposed wing) and T0 (via
%     the engine). At the baseline (W_TO = 766800, S_ref = 4605, prop.T_SL =
%     220000 -> T0 = 110000/engine):
%       installed engine = 1.3 * n * Wengine(T0)          [Roskam 7.13-7.19; Table 7.1 1.3x]
%       wing 10*3923 + ht 5.5*903 + vt 5.5*604 + fus 5*13125    [Table 7.1 areal x Table 7.3 areas]
%       + 0.043*W0 (gear) + 0.17*W0 (all-else)            [Table 7.1 fractions]
%       OEW ~ 334,043 lbf  (+4% vs actual 320,000: the Roskam engine
%       over-predicts the modern GE90 at the sizing 110k thrust; NOT Table 7.3's
%       323,778, which used 89k/engine -- USER decision to use the sizing T_SL).
%     Coupling checks: OEW(766800) rises when geom.S_ref grows (exposed wing,
%     10 lb/ft^2) and when prop.T_SL grows (heavier engine).
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

        % ── metabook Table 7.3 exposed planform / fuselage wetted areas ───
        S_EXP_WING    = 3923        % ft^2  [metabook Table 7.3]
        S_EXP_HT      = 903         % ft^2  [metabook Table 7.3]
        S_EXP_VT      = 604         % ft^2  [metabook Table 7.3]
        S_WET_FUS     = 13125       % ft^2  [metabook Table 7.3]

        % ── metabook Eq. 7.5-7.9 MAC / 40%-MAC location ───────────────────
        MAC_W         = 27.9        % ft    [metabook Eq. 7.5]
        X40MAC_W      = 100.4       % ft    [metabook Eq. 7.6]
        X40MAC_HT     = 192.1       % ft    [metabook Eq. 7.7]
        X40MAC_VT     = 187.6       % ft    [metabook Eq. 7.9]

        % ── L2 component-build-up baseline OEW (Algorithm 5) ──────────────
        OEW_L2_BASELINE = 334043    % lbf  Algorithm 5 sum at W0=766800, T_SL=220000 (see header)
        W0_BASELINE     = 766800    % lbf  [metabook Table 4.3]
    end

    methods (Static)
        function [geom, prop, aero, tail, wts] = buildStack()
            sp   = b777_spec_path(1);
            geom = B777GeomL2(sp);
            prop = B777PropL1(sp);
            aero = B777AeroL1(geom, sp);
            tail = B777TailL1(geom);
            wts  = B777WeightsL2(sp, geom, prop);
        end
    end

    % ==================================================================== %
    methods (Test)

        % ---- GEOMETRY ---------------------------------------------------- %

        function testSwetBaseline(tc)
        % S_wet = S_wet_rest + 2*S_ref = 19081 + 2*4605 = 28291 ft^2 [Eq. 4.58].
            geom = B777GeomL2(b777_spec_path(1));
            fprintf('\n    S_wet: received = %.4f ft^2,  hand-computed = %d ft^2\n', ...
                geom.get_S_wet(), tc.S_WET_BASE);
            tc.verifyEqual(geom.get_S_wet(), tc.S_WET_BASE, 'AbsTol', 1, ...
                'S_wet must be S_wet_rest + 2*S_ref = 28291 ft^2 [metabook Eq. 4.58].');
            % Dependent property and accessor agree.
            tc.verifyEqual(geom.S_wet, geom.get_S_wet(), 'AbsTol', 1e-9);
        end

        function testSpanAndMeanChord(tc)
        % b = sqrt(AR*S_ref) = sqrt(9.8*4605); cbar = S_ref/b [metabook Eq. 11.5 note].
            geom = B777GeomL2(b777_spec_path(1));
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
            geom = B777GeomL2(b777_spec_path(1));
            geom.S_ref = 5000;               % optimizer-style in-place mutation
            expected = 19081 + 2*5000;       % = 29081, hand-computed [Eq. 4.58]
            fprintf('\n    S_wet after S_ref=5000: received = %.4f ft^2,  hand = %d ft^2\n', ...
                geom.S_wet, expected);
            tc.verifyEqual(geom.S_wet, expected, 'AbsTol', 1e-9, ...
                'S_wet must track a mutated S_ref live (19081 + 2*5000 = 29081).');
        end

        function testGeomDerivedReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning must error.
            geom = B777GeomL2(b777_spec_path(1));
            tc.verifyError(@() setfield(geom, 'S_wet', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(geom, 'b_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testStatisticalMethodsError(tc)
        % The B777 L1 geometry has a real planform; the W_TO-regression methods
        % it inherits from GeometryModelL1 must ERROR (fail loud), not return a
        % wrong-model number.
            geom = B777GeomL2(b777_spec_path(1));
            tc.verifyError(@() geom.get_S_wet_statistical(766800), ...
                'B777GeomL2:notApplicable');
            tc.verifyError(@() geom.get_L_fus(766800), ...
                'B777GeomL2:notApplicable');
        end

        % ---- GEOMETRY L2: exposed areas + MAC ---------------------------- %

        function testExposedAreasMatchTable73(tc)
        % The exposed planform areas (wing/HT/VT) and the fuselage wetted area
        % must reproduce metabook Table 7.3: 3923 / 903 / 604 / 13125 ft^2.
            geom = B777GeomL2(b777_spec_path(1));
            fprintf('\n    exposed wing=%.1f (T7.3 %d)  ht=%.1f (%d)  vt=%.1f (%d)  fus_wet=%.1f (%d)\n', ...
                geom.S_exposed_wing, tc.S_EXP_WING, geom.S_exposed_ht, tc.S_EXP_HT, ...
                geom.S_exposed_vt, tc.S_EXP_VT, geom.S_wet_fus, tc.S_WET_FUS);
            tc.verifyEqual(geom.S_exposed_wing,  tc.S_EXP_WING, 'RelTol', 2e-3, ...
                'Exposed wing area must match Table 7.3 (3923 ft^2).');
            tc.verifyEqual(geom.S_exposed_ht,    tc.S_EXP_HT,   'RelTol', 2e-3, ...
                'Exposed H-tail area must match Table 7.3 (903 ft^2).');
            tc.verifyEqual(geom.S_exposed_vt,    tc.S_EXP_VT,   'RelTol', 2e-3, ...
                'Exposed V-tail area must match Table 7.3 (604 ft^2).');
            tc.verifyEqual(geom.S_wet_fus,       tc.S_WET_FUS,  'RelTol', 2e-3, ...
                'Fuselage wetted area must match Table 7.3 (13125 ft^2).');
        end

        function testMACAndX40MAC(tc)
        % MAC and 40%-MAC location must match the worked Eq. 7.5-7.9 values.
            geom = B777GeomL2(b777_spec_path(1));
            fprintf('\n    MAC_W=%.2f (Eq7.5 %.1f)  x40W=%.1f (Eq7.6 %.1f)  x40HT=%.1f (Eq7.7 %.1f)  x40VT=%.1f (Eq7.9 %.1f)\n', ...
                geom.MAC_wing, tc.MAC_W, geom.x40MAC_wing, tc.X40MAC_W, ...
                geom.x40MAC_htail, tc.X40MAC_HT, geom.x40MAC_vtail, tc.X40MAC_VT);
            tc.verifyEqual(geom.MAC_wing,     tc.MAC_W,     'RelTol', 3e-3, 'MAC_wing [Eq. 7.5].');
            tc.verifyEqual(geom.x40MAC_wing,  tc.X40MAC_W,  'RelTol', 3e-3, 'x40MAC_wing [Eq. 7.6].');
            tc.verifyEqual(geom.x40MAC_htail, tc.X40MAC_HT, 'RelTol', 3e-3, 'x40MAC_htail [Eq. 7.7].');
            tc.verifyEqual(geom.x40MAC_vtail, tc.X40MAC_VT, 'RelTol', 3e-3, ...
                'x40MAC_vtail must use TWICE the span [Eq. 7.9].');
        end

        function testExposedWingScalesWithSref(tc)
        % The exposed wing area tracks a mutated S_ref: a larger wing has a
        % larger exposed area, and the exposed FRACTION rises (the fixed
        % fuselage covers relatively less).
            geom = B777GeomL2(b777_spec_path(1));
            exp0 = geom.S_exposed_wing;  frac0 = exp0 / geom.S_ref;
            geom.S_ref = 5200;
            exp1 = geom.S_exposed_wing;  frac1 = exp1 / geom.S_ref;
            fprintf('\n    S_ref 4605->5200: exposed %.1f->%.1f, fraction %.4f->%.4f\n', ...
                exp0, exp1, frac0, frac1);
            tc.verifyGreaterThan(exp1, exp0, 'Exposed wing area must grow with S_ref.');
            tc.verifyGreaterThan(frac1, frac0, ...
                'Exposed fraction must rise (fixed fuselage covers relatively less).');
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
            received = prop.thrust_lapse(st, "max");
            fprintf('\n    thrust_lapse(40kft, M0.84, "max"): received = %.8f,  sigma^0.6 = %.8f (sigma=%.6f)\n', ...
                received, expected, sigma);
            tc.verifyEqual(received, expected, 'RelTol', 1e-4, ...
                'thrust_lapse("max") must be (rho/rho_SL)^0.6 [metabook Eq. 10.9].');
            % get_thrust_lapse alias agrees; the transport rating set is
            % {cont, TO, max}: "TO"=="max" (full takeoff), "cont" the 0.94 derate.
            tc.verifyEqual(prop.get_thrust_lapse(st), received, 'AbsTol', 1e-12);
            tc.verifyEqual(prop.thrust_lapse(st, "TO"), received, 'AbsTol', 1e-12, ...
                '"TO" and "max" are both full takeoff thrust for a transport.');
            tc.verifyEqual(prop.thrust_lapse(st, "cont"), 0.94 * received, 'RelTol', 1e-12, ...
                '"cont" (max continuous) is 0.94x takeoff thrust [metabook Eq. 4.25].');
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

        % ---- WEIGHTS (L2 component build-up, Algorithm 5) ---------------- %

        function testOEWComponentBuildup(tc)
        % OEW is the metabook Algorithm 5 component sum. The independent
        % expected reassembles it from the geom's exposed areas, the Roskam
        % engine formula (evaluated IN-TEST, not read from the class), and the
        % Table 7.1 areal densities / fractions / installed 1.3x factor -- and
        % must equal wts.OEW. NO tail sizing is needed: the component build-up
        % uses the EXPOSED tail areas (Table 7.3), not the tail write-back slots.
            [geom, prop, ~, ~, wts] = TestB777Disciplines.buildStack();
            W0 = tc.W0_BASELINE;
            n  = prop.n_engines;
            T0 = prop.T_SL / n;                         % per-engine SLS thrust
            % Independent Roskam single-engine uninstalled weight [Eqs. 7.13-7.19].
            dry  = 0.521*T0^0.9;
            Weng = dry + 0.082*T0^0.65 + 0.034*T0 + 0.26*T0^0.5 + 9.33*(dry/1000)^1.078;
            expected = 1.3*n*Weng ...                   % installed engine [Table 7.1 1.3x]
                     + 10.0*geom.S_exposed_wing ...      % wing     [Table 7.1]
                     + 5.5 *geom.S_exposed_ht ...        % H-tail   [Table 7.1]
                     + 5.5 *geom.S_exposed_vt ...        % V-tail   [Table 7.1]
                     + 5.0 *geom.S_wet_fus ...           % fuselage [Table 7.1]
                     + 0.043*W0 + 0.17*W0;               % gear + all-else [Table 7.1]
            received = wts.OEW(W0);
            fprintf('\n    OEW(766800) build-up: received=%.1f  hand=%.1f (~%d; %+.1f%% vs actual 320000)\n', ...
                received, expected, tc.OEW_L2_BASELINE, 100*(received-320000)/320000);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'OEW must equal the Algorithm 5 component sum (installed engine + areal + fractions).');
            tc.verifyEqual(received, tc.OEW_L2_BASELINE, 'RelTol', 5e-3, ...
                'OEW at baseline is ~334,043 lbf (Roskam GE90 over-prediction at the 110k sizing thrust).');
        end

        function testOEWIncreasesWithWingArea(tc)
        % The component build-up responds to S_ref: growing geom.S_ref grows the
        % EXPOSED wing area, so the wing weight (10 lb/ft^2 [Table 7.1]) rises.
        % Independent increment: exactly 10 * (exposed(5000) - exposed(4605)).
            [geom, ~, ~, ~, wts] = TestB777Disciplines.buildStack();
            oew_0 = wts.OEW(tc.W0_BASELINE);  exp_0 = geom.S_exposed_wing;
            geom.S_ref = 5000;                          % in-place mutation
            oew_1 = wts.OEW(tc.W0_BASELINE);  exp_1 = geom.S_exposed_wing;
            fprintf('\n    OEW S_ref 4605->5000: %.1f -> %.1f (delta %+.1f; 10*dExposed = %.1f)\n', ...
                oew_0, oew_1, oew_1 - oew_0, 10*(exp_1 - exp_0));
            tc.verifyGreaterThan(oew_1, oew_0, 'OEW must rise with wing area.');
            tc.verifyEqual(oew_1 - oew_0, 10*(exp_1 - exp_0), 'AbsTol', 1e-6, ...
                'The OEW increment must be exactly 10 lb/ft^2 * the exposed-wing-area increment.');
        end

        function testOEWIncreasesWithThrust(tc)
        % The component build-up responds to T0: growing prop.T_SL grows the
        % Roskam installed-engine weight, so OEW rises (the T0 sizing coupling).
            [~, prop, ~, ~, wts] = TestB777Disciplines.buildStack();
            oew_0 = wts.OEW(tc.W0_BASELINE);
            prop.T_SL = prop.T_SL * 1.2;                % +20% thrust, in-place
            oew_1 = wts.OEW(tc.W0_BASELINE);
            fprintf('\n    OEW T_SL +20%%: %.1f -> %.1f (delta %+.1f)\n', oew_0, oew_1, oew_1 - oew_0);
            tc.verifyGreaterThan(oew_1, oew_0, ...
                'OEW must rise with T_SL (heavier Roskam engine).');
        end

        function testOEWRejectsNonPositiveWTO(tc)
        % OEW's arguments block guards W_TO (mustBePositive, mustBeFinite).
            [~, ~, ~, ~, wts] = TestB777Disciplines.buildStack();
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
            r = tail.size();

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
            geom = B777GeomL2(b777_spec_path(1));
            tail = B777TailL1(geom);
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
