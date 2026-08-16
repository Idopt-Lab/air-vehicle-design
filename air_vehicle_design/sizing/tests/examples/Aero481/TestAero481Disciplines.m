classdef TestAero481Disciplines < matlab.unittest.TestCase
%TESTAero481DISCIPLINES  Tier-1 unit/correctness tests for the F-35A (Aero 481
%   Design01 provenance) L1 discipline classes: Aero481GeomL1 (statistical L1
%   geometry, Roskam Table 3.5 / Raymer Table 6.3 TOGW regressions),
%   Aero481AeroL1 (Design01 config tables + live Oswald K1), Aero481PropL1 (NO altitude
%   lapse m=0 + mil-on-AB scale, categorical TSFC), Aero481WeightsL1 (Aero 481 A02
%   DELTA model: Sainristil fraction + wing delta + engine delta),
%   Aero481TailL1 (Raymer Table 6.4 volume coeffs).
%
%   These are hand-computed spot checks: every "expected" value is derived
%   independently from the cited textbook Eq/Table (or an independent
%   constant), NOT read back out of the class under test. The comment block
%   above properties(Constant) shows each derivation.
%
%   Construction (coordinator-verified stack):
%       sp = aero481_spec_path(1);       rp = aero481_requirements_path();
%       geom = Aero481GeomL1(sp, rp);    prop = Aero481PropL1(sp);
%       aero = Aero481AeroL1(sp);        tail = Aero481TailL1();
%       wts  = Aero481WeightsL1(sp, geom, prop);  % A02 delta model (3-arg)
%
%   ── HAND-COMPUTED EXPECTED VALUES AND THEIR DERIVATIONS ──────────────────
%
%   GEOMETRY [Roskam Vol. I Table 3.5; Raymer 6th ed. Table 6.3]
%     S_ref = 460 ft^2 (published F-35A stand-in) -- a plain input.
%     S_wet(W_TO) = 10^-0.1289 * W_TO^0.7506  [Roskam Table 3.5 jet_fighter].
%       At W_TO = 44000: 10^-0.1289 = 0.7432704;  44000^0.7506:
%       ln(44000) = 10.6923150, *0.7506 = 8.0256637, exp = 3057.72;
%       0.7432704 * 3057.72 = 2272.7 ft^2 (hand ~2272.4; RelTol 1e-3 covers
%       the last-digit rounding of the manual log arithmetic).
%     L_fuselage(W_TO) = 0.93 * W_TO^0.39  [Raymer Table 6.3 jet_fighter].
%       At W_TO = 44000: 44000^0.39: ln*0.39 = 4.1700, exp = 64.7175;
%       0.93 * 64.7175 = 60.19 ft.
%     S_wet/L_fuselage are Dependent on W_TO -- reading either with W_TO unset
%     (NaN) errors 'Aero481GeomL1:WTONotSet' (fail loud, not a silent zero).
%
%   AERODYNAMICS [A481 A03.m:60,65; Raymer 6th ed. Eq. 12.48/12.50]
%     drag_polar.CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014 (CONSTANT clean,
%       the A03 MISSION clean drag) [A481 A03.m:60,65; Design01.m:36 Swet=4*S;
%       metabook Eq. 4.8 = Raymer Eq. 12.23]. This is the value drag_polar
%       returns (the mission reads drag_polar). It INTENTIONALLY differs from
%       get_config_polar("clean").CD0 = 0.0236 (the Design01 config table the
%       CONSTRAINTS read) -- A481's own mission-vs-constraint inconsistency
%       (disc A1b). Do NOT reconcile the two.
%     e = AeroL2.oswald_eff(AR=4, Lambda_LE=0) = 1.78*(1-0.045*4^0.68)-0.64.
%       4^0.68 = exp(0.68*ln4) = exp(0.9430) = 2.56773; 1.78*(1-0.045*2.56773)
%       = 1.78*(1-0.1155479) = 1.78*0.8844521 = 1.5743247; -0.64 = 0.9343247.
%       *** USE e = 0.9344 (CORRECT AeroL2.oswald_eff(4,0)), NOT the docs' old
%           0.9153 (a transcription error corresponding to AR ~= 4.56, since
%           corrected 2026-08-15). The class computes e LIVE, so it uses the
%           correct value. ***
%     K1 = 1/(pi*AR*e) = 1/(pi*4*0.9343247) = 1/11.740247 = 0.0851771.
%       (The independent hand K1 uses my own e = 0.9343247, so it cannot fail
%        on a shared coefficient with the class; RelTol 1e-4 covers the
%        4th-decimal e rounding.)
%     K2 = 0 (uncambered-basis) [Mattingly Eq. 2.9 Convention A].
%     get_config_polar CD0/CLmax (absolute Design01 table values):
%       takeoff_flaps_gear_down: CD0 0.0586, CLmax 2.0.
%       approach:                CD0 0.0836 (= mean(0.0586,0.1086)), CLmax 2.6.
%     get_CLmax(clean) = 1.8 [A481 Design01.m:59]; get_CLmax_TO = 2.0;
%     get_CLmax_L = 2.6.
%     K1 tracks a mutated AR live (recompute-on-read): at AR = 8,
%       e8 = 1.78*(1-0.045*8^0.68)-0.64: 8^0.68 = exp(0.68*2.0794) = exp(1.4140)
%       = 4.11217; 1.78*(1-0.045*4.11217)-0.64 = 1.78*0.8149524-0.64 = 0.810615;
%       K1_8 = 1/(pi*8*0.810615) = 1/20.3712 = 0.0490889. (This is the same
%       0.8105923 TestAeroL2 validates at AR=8, confirming the shared static.)
%
%   PROPULSION [metabook Eq. 10.9; A481 Design01.m:78-80; aero481_L1.json .propulsion]
%     lapse_exponent_m = 0 (NO altitude lapse) -- reproduces Aero 481, which
%       applies no thrust derating with altitude (disc A6, USER decision
%       2026-08-15). The JSON sets lapse_exponent_m = 0; the constructor reads
%       it, so the LIVE object exponent is 0 (the class-file default 0.6 is
%       OVERRIDDEN by the JSON -- verify against the constructed object, not the
%       header default).
%     thrust_lapse(state,"AB") = sigma^m = sigma^0 = 1.0 EXACTLY at ANY altitude
%       (m = 0 makes the density ratio drop out -- no ~3e-5 SL-density rounding).
%     thrust_lapse(state,"mil") = (28000/43000)*sigma^0 = 0.6511628 EXACTLY at
%       ANY altitude. The mil-on-AB scale mil/AB = 28000/43000 is the INDEPENDENT
%       ratio, NOT read from thrust_lapse; with m = 0 the absolute mil value is
%       also exactly 0.6511628.
%     get_TSFC by Mach regime [A481 Design01.m:78-80]:
%       M0.05 (< 0.1)   -> tsfc_sls    = 0.35
%       M0.85 (< 1.0)   -> tsfc_cruise = 0.65
%       M1.6  (>= 1.0)  -> tsfc_dash   = 1.70
%     Unknown rating errors mustBeMember.
%
%   WEIGHTS (Aero 481 A02 DELTA model, 3-arg constructor) [A481 A02.m:37-63]
%     OEW is the Sainristil empty-weight FRACTION plus two DELTA terms that
%     measure how far the current design sits from the A481 design point
%     (W/S = 92.17 psf, T/W = 1.2). The class injects the geometry object
%     (S_ref) and the propulsion object (T_SL): Aero481WeightsL1(sp, geom, prop).
%
%       OEW(W0) = We_frac(W0)*W0                              [FRACTION]
%               + rho_w*( geom.S_ref - W0/design_WS_psf )     [WING  delta]
%               + ( Weng(prop.T_SL) - Weng(design_TW*W0) )    [ENGINE delta]
%
%     with (ALL independent literals, NOT read from the class):
%       We_frac(W0)   = 0.882 * W0^-0.055    [A481 Design01.m:26 Sainristil]
%       rho_w         = 9 lbf/ft^2           [Raymer 6th ed. Table 15.2 jet_fighter]
%       design_WS_psf = 92.17 psf, design_TW = 1.2  [A481 Design01 PointPerformance]
%       Weng(T)       = 0.521*T^0.9 + 0.082*T^0.65 + 0.034*T + 0.26*T^0.5
%                       + 9.33*(0.521*T^0.9/1000)^1.078
%                       [Roskam Eqs. 7.13-7.19; the 5-term formula validated in
%                        TestB777Disciplines.testOEWComponentBuildup].
%
%     PER-TERM IDENTITY. At (geom.S_ref = 460, prop.T_SL = 43000, W0):
%       * WING delta at W0 = 62400: 9*(460 - 62400/92.17) = 9*(460 - 677.01)
%         = 9*(-217.01) = -1953.1 lbf (NEGATIVE: the actual 460 ft^2 wing is
%         smaller than the design-W/S baseline area 677 ft^2).
%       * ENGINE delta at W0 = 62400: design_TW*W0 = 1.2*62400 = 74880 lbf, and
%         prop.T_SL = 43000 < 74880, so Weng(43000) - Weng(74880) is strongly
%         NEGATIVE (the real F135 is far below the design-T/W-implied thrust).
%       Both deltas NEGATIVE pull the effective OEW fraction (OEW/W0) BELOW the
%       bare Sainristil We_frac (~0.486 at 62.4k), down to ~0.36 -- which is why
%       Aero 481 sizes the F-35 small (~62.4k lb, A02).
%     The test computes each term INDEPENDENTLY and asserts their sum == wts.OEW.
%     compute_We_fraction(W0) is STILL the FRACTION term = 0.882*W0^-0.055, but
%       OEW is NO LONGER frac*W0 (the deltas shift it).
%     compute_We_fraction_raymer(W0) = 2.34*W0^-0.13 [Raymer Table 3.1] is a
%       DIFFERENT curve -- the framework-cited alternative, NOT the baseline.
%     OEW guards W_TO (mustBePositive/mustBeFinite).
%
%   TAIL [Raymer 7th ed. Table 6.4 jet-fighter; aft-mounted arm]
%     c_HT = 0.40, c_VT = 0.07 (UNCORRECTED base coefficients).
%     L_arm = 0.475*L_fus  [aft-mounted single-engine text rule].
%     S_ht = c_HT*cbar*S_ref/L_arm;  S_vt = c_VT*b*S_ref/L_arm.
%       Expected computed from INDEPENDENT literals c_HT=0.40, c_VT=0.07,
%       ARM_FRAC=0.475 (NOT read from the tail object), so a shared-coefficient
%       error cannot hide. With S_ref=460, b=sqrt(4*460)=42.8952, cbar=
%       460/42.8952=10.7239, L_fus set to 51 ft (arbitrary independent test
%       value): L_arm=24.225; S_ht=0.40*10.7239*460/24.225=81.464;
%       S_vt=0.07*42.8952*460/24.225=57.008.

    properties (Constant)
        % ── Independent citation constants (not read from any class) ──────
        AR_BASE       = 4          % [A481 Design01.m:49]
        E_AR4         = 0.9343247  % AeroL2.oswald_eff(4,0) = 1.78*(1-0.045*4^0.68)-0.64  [Raymer Eq. 12.48]
        E_AR8         = 0.8105923  % AeroL2.oswald_eff(8,0)  (matches TestAeroL2 at AR=8)  [Raymer Eq. 12.48]
        T_SL_AB       = 43000      % lbf  [aero481_data.md Part I]
        T_SL_MIL      = 28000      % lbf  [aero481_data.md Part I]
        LAPSE_M       = 0          % [aero481_L1.json .propulsion: no altitude lapse, disc A6]
        C_HT          = 0.40       % [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected]
        C_VT          = 0.07       % [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected]
        ARM_FRAC      = 0.475      % [Raymer 7th ed. aft-mounted single-engine text rule]

        % ── A02 weights delta-model constants (independent literals) ──────
        RHO_W         = 9.0        % lbf/ft^2  jet_fighter wing areal density [Raymer 6th ed. Table 15.2]
        OEW_COEFF_A   = 0.882      % Sainristil OEW-fraction leading coeff [A481 Design01.m:26]
        OEW_COEFF_C   = -0.055     % Sainristil OEW-fraction exponent      [A481 Design01.m:26]
        DESIGN_WS_PSF = 92.17      % psf  design wing loading (wing-delta baseline) [A481 Design01 PointPerformance]
        DESIGN_TW     = 1.2        % --   design thrust-to-weight (engine-delta baseline) [A481 Design01 PointPerformance]

        % ── Aero clean drag: MISSION vs CONSTRAINT (disc A1b) ─────────────
        CD0_MISSION   = 0.014      % Cfe*swet_over_sref = 0.0035*4 [A481 A03.m:60,65] -- drag_polar returns this
        CD0_CLEAN     = 0.0236     % config-table clean [A481 Design01.m:64] -- get_config_polar("clean") returns this
        CD0_TO_GD     = 0.0586     % takeoff_flaps_gear_down
        CD0_APPROACH  = 0.0836     % = mean(0.0586, 0.1086)  [A481 Climb.m:63]
        CLMAX_CLEAN   = 1.8        % [A481 Design01.m:59 CLmax.EN]
        CLMAX_TO      = 2.0        % takeoff_flaps_gear_down
        CLMAX_L       = 2.6        % landing_flaps_gear_down

        % ── Propulsion deck [A481 Design01.m:78-80] ──────────────────────
        TSFC_SLS      = 0.35       % 1/hr
        TSFC_CRUISE   = 0.65       % 1/hr
        TSFC_DASH     = 1.70       % 1/hr

        % ── Design point reference [A481 Design01 design point] ───────────
        S_REF_BASE    = 460        % ft^2  (also the tail-test reference S_ref)

        % ── Test W_TO for the geometry regressions ────────────────────────
        W_TO_TEST     = 44000      % lbf
    end

    methods (Static)
        function [geom, prop, aero, tail, wts] = buildStack()
            sp   = aero481_spec_path(1);
            rp   = aero481_requirements_path();
            geom = Aero481GeomL1(sp, rp);
            prop = Aero481PropL1(sp);
            aero = Aero481AeroL1(sp);
            tail = Aero481TailL1();
            wts  = Aero481WeightsL1(sp, geom, prop);   % A02 delta model (3-arg): injects geom (S_ref) + prop (T_SL)
        end

        function W = weng_roskam(T)
        %WENG_ROSKAM  INDEPENDENT single-engine dry weight [lbf] from SLS thrust,
        %   the 5-term Roskam regression [Roskam Eqs. 7.13-7.19] -- transcribed
        %   here by hand (NOT read from WeightsL1.engine_weight_roskam), so the
        %   A02 engine-delta expected cannot share a coefficient error with the
        %   class under test. Same formula validated in
        %   TestB777Disciplines.testOEWComponentBuildup.
            dry = 0.521 * T^0.9;
            W   = dry + 0.082*T^0.65 + 0.034*T + 0.26*T^0.5 + 9.33*(dry/1000)^1.078;
        end
    end

    % ==================================================================== %
    methods (Test)

        % ---- GEOMETRY ---------------------------------------------------- %

        function testSrefIsInput(tc)
        % S_ref is a plain input = the published F-35A wing-area stand-in.
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            tc.verifyEqual(geom.S_ref, tc.S_REF_BASE, 'AbsTol', 1e-12, ...
                'S_ref must be the 460 ft^2 published F-35A stand-in [aero481_data.md Part I].');
            tc.verifyEqual(geom.get_S_ref(), tc.S_REF_BASE, 'AbsTol', 1e-12);
        end

        function testSwetTOGWRegression(tc)
        % S_wet = 10^-0.1289 * W_TO^0.7506 [Roskam Table 3.5 jet_fighter].
        % Independent hand value at W_TO = 44000 = 2272.7 ft^2 (see header).
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            expected = 10^(-0.1289) * tc.W_TO_TEST^0.7506;    % hand formula
            received = geom.get_S_wet(tc.W_TO_TEST);
            fprintf('\n    S_wet(44000) = %.4f ft^2 (hand %.4f)\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-3, ...
                'S_wet must be the Roskam Table 3.5 jet-fighter TOGW regression.');
            % The Dependent getter (after W_TO is set) agrees with the accessor.
            geom.W_TO = tc.W_TO_TEST;
            tc.verifyEqual(geom.S_wet, received, 'RelTol', 1e-12, ...
                'The Dependent S_wet must equal get_S_wet(obj.W_TO).');
        end

        function testLfuselageTOGWRegression(tc)
        % L_fuselage = 0.93 * W_TO^0.39 [Raymer 6th ed. Table 6.3 jet_fighter].
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            expected = 0.93 * tc.W_TO_TEST^0.39;              % hand formula
            received = geom.get_L_fus(tc.W_TO_TEST);
            fprintf('\n    L_fuselage(44000) = %.4f ft (hand %.4f)\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-3, ...
                'L_fuselage must be the Raymer Table 6.3 jet-fighter TOGW regression.');
        end

        function testDerivedErrorWhenWTOUnset(tc)
        % Reading S_wet / L_fuselage before W_TO is set errors (fail loud),
        % rather than propagating a silent zero parasite drag.
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            tc.verifyError(@() geom.S_wet, 'Aero481GeomL1:WTONotSet');
            tc.verifyError(@() geom.L_fuselage, 'Aero481GeomL1:WTONotSet');
        end

        function testGeomDerivedReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning must error.
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            geom.W_TO = tc.W_TO_TEST;    % set so a getter would otherwise succeed
            tc.verifyError(@() setfield(geom, 'S_wet', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(geom, 'L_fuselage', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testUnknownCategoryErrors(tc)
        % An unknown aircraft_category must error at the table lookup (fail
        % loud), not silently return a wrong-category regression.
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            geom.aircraft_category = "flying_saucer";
            tc.verifyError(@() geom.get_S_wet(tc.W_TO_TEST), 'GeomL1:unknownCategory');
        end

        % ---- AERODYNAMICS ------------------------------------------------ %

        function testCleanDragPolar(tc)
        % drag_polar CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014 (the A03 MISSION
        % clean value, CONSTANT) [A481 A03.m:60,65]. NOTE this is NOT the
        % config-table 0.0236 -- that lives on get_config_polar (disc A1b). K1 =
        % 1/(pi*4*e) with e = AeroL2.oswald_eff(4,0) = 0.9343247 (CORRECT value,
        % NOT 0.9153); K2 = 0. Independent hand K1 uses my own e = 0.9343247.
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            polar = aero.drag_polar(AircraftState(35000, 0.85));
            k1_hand = 1/(pi*tc.AR_BASE*tc.E_AR4);
            fprintf('\n    clean(mission) CD0 = %.6f (hand %.6f);  K1 = %.7f (hand %.7f, e=%.7f);  K2 = %.3g\n', ...
                polar.CD0, tc.CD0_MISSION, polar.K1, k1_hand, tc.E_AR4, polar.K2);
            tc.verifyEqual(polar.CD0, tc.CD0_MISSION, 'AbsTol', 1e-12, ...
                'drag_polar clean CD0 must be Cfe*swet_over_sref = 0.0035*4 = 0.014 [A481 A03.m:60,65].');
            tc.verifyEqual(polar.K1, k1_hand, 'RelTol', 1e-4, ...
                'Clean K1 must be 1/(pi*4*0.9344) = 0.085177 with the CORRECT e = 0.9344.');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, ...
                'Clean K2 must be 0 (uncambered-basis) [Mattingly Eq. 2.9].');
        end

        function testDragPolarCD0IsConstantInState(tc)
        % The A03 mission clean CD0 (0.014) is a frozen number: it does NOT vary
        % with Mach/altitude (Swet = 4*S makes Swet/S constant, no live coupling).
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            cd0_lo = aero.drag_polar(AircraftState(0, 0.2)).CD0;
            cd0_hi = aero.drag_polar(AircraftState(45000, 1.6)).CD0;
            tc.verifyEqual(cd0_lo, tc.CD0_MISSION, 'AbsTol', 1e-12);
            tc.verifyEqual(cd0_hi, tc.CD0_MISSION, 'AbsTol', 1e-12, ...
                'drag_polar clean CD0 must be state-independent at L1 (constant 0.014).');
        end

        function testConfigPolarValues(tc)
        % get_config_polar returns the absolute Design01 table CD0/CLmax.
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            todo = aero.get_config_polar("takeoff_flaps_gear_down");
            appr = aero.get_config_polar("approach");
            fprintf('\n    TO_gd: CD0=%.4f (hand %.4f) CLmax=%.2f (%.2f);  approach: CD0=%.4f (hand %.4f) CLmax=%.2f (%.2f)\n', ...
                todo.CD0, tc.CD0_TO_GD, todo.CLmax, tc.CLMAX_TO, ...
                appr.CD0, tc.CD0_APPROACH, appr.CLmax, tc.CLMAX_L);
            tc.verifyEqual(todo.CD0, tc.CD0_TO_GD, 'AbsTol', 1e-12, ...
                'takeoff_flaps_gear_down CD0 must be 0.0586 [A481 Design01.m].');
            tc.verifyEqual(todo.CLmax, tc.CLMAX_TO, 'AbsTol', 1e-12, ...
                'takeoff_flaps_gear_down CLmax must be 2.0 [A481 Design01.m].');
            tc.verifyEqual(appr.CD0, tc.CD0_APPROACH, 'AbsTol', 1e-12, ...
                'approach CD0 must be mean(0.0586,0.1086) = 0.0836 [A481 Climb.m:63].');
            tc.verifyEqual(appr.CLmax, tc.CLMAX_L, 'AbsTol', 1e-12, ...
                'approach CLmax must be 2.6 (= BO) [A481 Climb.m].');
        end

        function testCLmaxAccessors(tc)
        % Clean / takeoff / landing CLmax [A481 Design01.m:55-61].
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(aero.get_CLmax(AircraftState(35000, 0.85)), tc.CLMAX_CLEAN, ...
                'AbsTol', 1e-12, 'Clean CLmax must be 1.8 [A481 Design01.m:59].');
            tc.verifyEqual(aero.get_CLmax_TO(), tc.CLMAX_TO, 'AbsTol', 1e-12, ...
                'get_CLmax_TO must be 2.0 (takeoff_flaps_gear_down).');
            tc.verifyEqual(aero.get_CLmax_L(), tc.CLMAX_L, 'AbsTol', 1e-12, ...
                'get_CLmax_L must be 2.6 (landing_flaps_gear_down).');
        end

        function testDeltaCD0Accessors(tc)
        % get_Delta_CD0_TO/_L = config gear-down CD0 minus clean CD0.
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(aero.get_Delta_CD0_TO(), tc.CD0_TO_GD - tc.CD0_CLEAN, ...
                'AbsTol', 1e-12, 'Delta_CD0_TO must be 0.0586 - 0.0236 = 0.0350.');
            tc.verifyEqual(aero.get_Delta_CD0_L(), 0.1086 - tc.CD0_CLEAN, ...
                'AbsTol', 1e-12, 'Delta_CD0_L must be 0.1086 - 0.0236 = 0.0850.');
        end

        function testK1TracksARLive(tc)
        % K1 = 1/(pi*AR*e) recomputes live: mutate AR = 8 in place and verify
        % K1 tracks it, using the INDEPENDENT e(AR=8) = 0.8105923 (the same
        % value TestAeroL2 validates), so no shared-coefficient error can hide.
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            st = AircraftState(35000, 0.85);
            k1_0 = aero.drag_polar(st).K1;
            aero.AR = 8;                        % in-place optimizer-style mutation
            expected = 1/(pi*8*tc.E_AR8);
            k1_1 = aero.drag_polar(st).K1;
            fprintf('\n    K1 at AR=4: %.7f;  at AR=8: %.7f (hand %.7f)\n', k1_0, k1_1, expected);
            tc.verifyEqual(k1_1, expected, 'RelTol', 1e-4, ...
                'K1 must track a mutated AR live: 1/(pi*8*0.8105923).');
            tc.verifyLessThan(k1_1, k1_0, 'A higher AR gives a lower induced factor K1.');
        end

        function testConfigPolarRejectsUnknownConfig(tc)
        % get_config_polar validates its config against the six known names.
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyError(@() aero.get_config_polar("stealth_dash"), ...
                'MATLAB:validators:mustBeMember');
        end

        % ---- PROPULSION -------------------------------------------------- %

        function testThrustLapseABIsUnityAtAllAltitudes(tc)
        % With lapse_exponent_m = 0 (no altitude lapse, disc A6) the density
        % ratio drops out entirely: thrust_lapse("AB") = sigma^0 = 1.0 EXACTLY
        % at ANY altitude, not just approximately at sea level. Check both a
        % sea-level and a high-altitude state to confirm the exponent is 0
        % (a nonzero m would make the 40 kft value clearly < 1).
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            ab_sl = prop.thrust_lapse(AircraftState(0, 0.05),  "AB");
            ab_hi = prop.thrust_lapse(AircraftState(40000, 0.85), "AB");
            fprintf('\n    thrust_lapse("AB"): SL = %.12f,  40kft = %.12f (both 1.0)\n', ...
                ab_sl, ab_hi);
            tc.verifyEqual(ab_sl, 1.0, 'AbsTol', 1e-12, ...
                'thrust_lapse("AB") must be sigma^0 = 1.0 exactly (m = 0, no lapse).');
            tc.verifyEqual(ab_hi, 1.0, 'AbsTol', 1e-12, ...
                'thrust_lapse("AB") must stay 1.0 at 40 kft (m = 0 -> altitude drops out).');
        end

        function testThrustLapseMilScale(tc)
        % The mil-on-AB SCALE is EXACT and altitude-independent:
        %   thrust_lapse("mil") / thrust_lapse("AB") = T_SL_mil/T_SL = 28000/43000.
        % The RATIO holds regardless of the lapse exponent. With m = 0 the
        % ABSOLUTE mil value is ALSO exactly 0.6511628 (sigma^0 = 1), so both are
        % checked here -- at a high-altitude state to prove the exponent is 0.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            expected = tc.T_SL_MIL / tc.T_SL_AB;         % 0.6511628
            st  = AircraftState(40000, 0.85);            % altitude != SL
            mil = prop.thrust_lapse(st, "mil");
            ab  = prop.thrust_lapse(st, "AB");
            fprintf('\n    mil/AB = %.12f (hand 28000/43000 = %.12f);  mil abs = %.12f\n', ...
                mil/ab, expected, mil);
            tc.verifyEqual(mil/ab, expected, 'RelTol', 1e-9, ...
                'mil-on-AB scale (mil/AB) must be 28000/43000 = 0.6512 exactly.');
            tc.verifyEqual(mil, expected, 'AbsTol', 1e-12, ...
                'With m = 0 the absolute mil lapse is 0.6512 at any altitude (sigma^0 = 1).');
        end

        function testGetTSFCByMachRegime(tc)
        % Categorical TSFC [A481 Design01.m:78-80]: 0.35 / 0.65 / 1.70 at
        % M0 / M0.85 / M1.6.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tsfc_static = prop.get_TSFC(AircraftState(0, 0.05));
            tsfc_cruise = prop.get_TSFC(AircraftState(35000, 0.85));
            tsfc_dash   = prop.get_TSFC(AircraftState(35000, 1.6));
            fprintf('\n    TSFC: static=%.2f (0.35)  cruise=%.2f (0.65)  dash=%.2f (1.70)\n', ...
                tsfc_static, tsfc_cruise, tsfc_dash);
            tc.verifyEqual(tsfc_static, tc.TSFC_SLS, 'AbsTol', 1e-12, ...
                'M < 0.1 must return tsfc_sls = 0.35 [A481 Design01.m:78-80].');
            tc.verifyEqual(tsfc_cruise, tc.TSFC_CRUISE, 'AbsTol', 1e-12, ...
                '0.1 <= M < 1.0 must return tsfc_cruise = 0.65.');
            tc.verifyEqual(tsfc_dash, tc.TSFC_DASH, 'AbsTol', 1e-12, ...
                'M >= 1.0 must return tsfc_dash = 1.70 (supersonic AB).');
            % lookup_TSFC alias agrees.
            tc.verifyEqual(prop.lookup_TSFC(AircraftState(35000, 0.85)), tc.TSFC_CRUISE, ...
                'AbsTol', 1e-12, 'lookup_TSFC must alias get_TSFC.');
        end

        function testLapseExponentInput(tc)
        % lapse_exponent_m = 0 (no altitude lapse) -- the constructed object
        % reads it from aero481_L1.json .propulsion (disc A6). This OVERRIDES the
        % class-file default 0.6, so the LIVE object value is 0.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(prop.lapse_exponent_m, tc.LAPSE_M, 'AbsTol', 1e-12, ...
                'lapse_exponent_m must be the JSON-set 0 (no altitude lapse, disc A6).');
        end

        function testThrustLapseRejectsUnknownRating(tc)
        % thrust_lapse validates the fighter rating set ["mil","AB"] -- a
        % transport rating ("cont"/"max"/"TO") the F135 does not carry errors.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyError(@() prop.thrust_lapse(AircraftState(0, 0.05), "cont"), ...
                'MATLAB:validators:mustBeMember');
        end

        function testPropDerivedReadOnly(tc)
        % T_SL_wet is Dependent (an AB-scale alias) -- assigning must error.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyError(@() setfield(prop, 'T_SL_wet', 1), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % ---- WEIGHTS (Aero 481 A02 delta model) -------------------------- %

        function testOEWDeltaModelPerTerm(tc)
        % OEW = FRACTION + WING delta + ENGINE delta [A481 A02.m:37-63]. The
        % expected is reassembled from INDEPENDENT literals (Sainristil 0.882 /
        % -0.055; rho_w = 9; design_WS_psf = 92.17; design_TW = 1.2; the 5-term
        % Roskam engine formula) computed IN-TEST, using the injected geom.S_ref
        % and prop.T_SL (genuine inputs), NOT read back from wts.OEW. Checked at
        % two very different W0 so nothing hides behind one point.
            [geom, prop, ~, ~, wts] = TestAero481Disciplines.buildStack();
            S_ref = geom.get_S_ref();       % injected genuine input (460 ft^2)
            T_SL  = prop.T_SL;              % injected genuine input (43000 lbf)
            for W0 = [30000, tc.W_TO_TEST]
                % FRACTION term (independent Sainristil power law).
                frac_term = (tc.OEW_COEFF_A * W0^tc.OEW_COEFF_C) * W0;
                % WING delta -- rho_w*(S_ref - W0/design_WS_psf), self-scaling base.
                wing_term = tc.RHO_W * (S_ref - W0 / tc.DESIGN_WS_PSF);
                % ENGINE delta -- Weng(T_SL) - Weng(design_TW*W0), 5-term Roskam.
                eng_term  = TestAero481Disciplines.weng_roskam(T_SL) ...
                          - TestAero481Disciplines.weng_roskam(tc.DESIGN_TW * W0);
                expected  = frac_term + wing_term + eng_term;
                received  = wts.OEW(W0);
                fprintf(['\n    OEW(%.0f) = %.2f  (hand %.2f = frac %.2f + wing %.2f ', ...
                    '+ eng %.2f)\n'], W0, received, expected, frac_term, wing_term, eng_term);
                tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                    'OEW must be the A02 sum: Sainristil frac + wing delta + engine delta.');
            end
        end

        function testEngineDeltaNegativePullsFractionDown(tc)
        % At the F-35 design point the ENGINE delta is strongly NEGATIVE (the
        % real F135 T_SL = 43000 sits below the design-T/W-implied thrust
        % design_TW*W0), and the WING delta is also negative (the 460 ft^2 wing
        % is smaller than the design-W/S baseline area), so OEW is pulled BELOW
        % the bare Sainristil fraction*W0 and the effective OEW fraction drops
        % below the bare Sainristil We_frac. Checked at W0 = 62400 (A02 point).
            [geom, prop, ~, ~, wts] = TestAero481Disciplines.buildStack();
            W0    = 62400;
            T_SL  = prop.T_SL;
            eng_delta = TestAero481Disciplines.weng_roskam(T_SL) ...
                      - TestAero481Disciplines.weng_roskam(tc.DESIGN_TW * W0);
            bare  = wts.compute_We_fraction(W0) * W0;   % Sainristil fraction * W0
            oew   = wts.OEW(W0);
            fprintf(['\n    W0=%.0f: engine delta = %+.1f  (design thrust %.0f > T_SL %.0f);  ', ...
                'OEW = %.1f (bare frac*W0 = %.1f);  eff frac = %.4f (bare %.4f)\n'], ...
                W0, eng_delta, tc.DESIGN_TW*W0, T_SL, oew, bare, oew/W0, ...
                wts.compute_We_fraction(W0));
            tc.verifyLessThan(eng_delta, 0, ...
                'The engine delta must be negative (T_SL < design_TW*W0 at the design point).');
            tc.verifyLessThan(oew, bare, ...
                'The negative deltas must pull OEW below the bare Sainristil fraction*W0.');
            tc.verifyLessThan(oew / W0, wts.compute_We_fraction(W0), ...
                'The effective OEW fraction must sit below the bare Sainristil We_frac.');
        end

        function testWeFractionSainristilValue(tc)
        % compute_We_fraction(W0) = 0.882*W0^-0.055 [A481 Design01.m:26] -- STILL
        % the FRACTION term of the A02 model (the deltas are added ON TOP of it,
        % so OEW != compute_We_fraction*W0 any more; that identity is what the
        % A02 delta model replaced). The expected is the INDEPENDENT hand power
        % law, NOT read from the class.
            [~, ~, ~, ~, wts] = TestAero481Disciplines.buildStack();
            W0 = tc.W_TO_TEST;
            expected = 0.882 * W0^(-0.055);                  % independent hand formula
            received = wts.compute_We_fraction(W0);
            fprintf('\n    compute_We_fraction(44000) = %.7f (hand %.7f)\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'compute_We_fraction must be 0.882*W0^-0.055 (Sainristil) [A481 Design01.m:26].');
        end

        function testRaymerFractionDiffersFromSainristil(tc)
        % compute_We_fraction_raymer = 2.34*W0^-0.13 [Raymer Table 3.1] is a
        % DIFFERENT curve (the framework-cited alternative), not the baseline.
        % The independent hand value uses the Raymer coefficients directly.
            [~, ~, ~, ~, wts] = TestAero481Disciplines.buildStack();
            W0 = tc.W_TO_TEST;
            expected_raymer = 2.34 * W0^(-0.13);             % independent hand formula
            received_raymer = wts.compute_We_fraction_raymer(W0);
            fprintf('\n    Raymer frac(44000) = %.7f (hand %.7f);  Sainristil = %.7f\n', ...
                received_raymer, expected_raymer, wts.compute_We_fraction(W0));
            tc.verifyEqual(received_raymer, expected_raymer, 'RelTol', 1e-9, ...
                'compute_We_fraction_raymer must be 2.34*W0^-0.13 [Raymer Table 3.1].');
            tc.verifyNotEqual(received_raymer, wts.compute_We_fraction(W0), ...
                'The Raymer alternative must differ from the Sainristil baseline.');
        end

        function testOEWRejectsNonPositiveWTO(tc)
        % OEW's arguments block guards W_TO (mustBePositive, mustBeFinite).
            [~, ~, ~, ~, wts] = TestAero481Disciplines.buildStack();
            tc.verifyError(@() wts.OEW(-5),  'MATLAB:validators:mustBePositive');
            tc.verifyError(@() wts.OEW(Inf), 'MATLAB:validators:mustBeFinite');
        end

        % ---- TAIL -------------------------------------------------------- %

        function testTailCoefficientsUncorrected(tc)
        % The F-35 takes the UNCORRECTED base jet-fighter coefficients
        % c_HT = 0.40, c_VT = 0.07 [Raymer 7th ed. Table 6.4] -- NOT the F-16's
        % RSS/all-moving-corrected form (see testTODO_TailRSSAllMovingFlags).
            tail = Aero481TailL1();
            tc.verifyEqual(tail.c_HT, tc.C_HT, 'AbsTol', 1e-12, ...
                'c_HT must be the uncorrected 0.40 jet-fighter value [Raymer Table 6.4].');
            tc.verifyEqual(tail.c_VT, tc.C_VT, 'AbsTol', 1e-12, ...
                'c_VT must be the uncorrected 0.07 jet-fighter value [Raymer Table 6.4].');
        end

        function testTailAreas(tc)
        % Volume-coefficient tail areas [Raymer Table 6.4]:
        %   L_arm = 0.475*L_fus  [aft-mounted single-engine text rule]
        %   S_ht  = c_HT*cbar*S_ref/L_arm
        %   S_vt  = c_VT*b*S_ref/L_arm
        % Expected computed from INDEPENDENT literals c_HT=0.40, c_VT=0.07,
        % ARM_FRAC=0.475 (NOT read from the tail object), so a shared-
        % coefficient error cannot hide. S_ref=460, b=sqrt(4*460), cbar=S/b,
        % L_fus = 51 ft (independent test scalar).
            tail  = Aero481TailL1();
            S_ref = tc.S_REF_BASE;
            b     = sqrt(tc.AR_BASE * S_ref);   % sqrt(4*460) = 42.8952
            cbar  = S_ref / b;                  % 10.7239
            L_fus = 51;                         % independent test value
            r = tail.size(S_ref, b, cbar, L_fus);

            L_arm       = tc.ARM_FRAC * L_fus;              % 0.475*51 = 24.225
            expected_ht = tc.C_HT * cbar * S_ref / L_arm;
            expected_vt = tc.C_VT * b    * S_ref / L_arm;
            fprintf('\n    S_ht = %.4f ft^2 (hand %.4f);  S_vt = %.4f ft^2 (hand %.4f)\n', ...
                r.S_ht, expected_ht, r.S_vt, expected_vt);
            tc.verifyEqual(r.S_ht, expected_ht, 'RelTol', 1e-9, ...
                'S_ht must be c_HT*cbar*S/(0.475*L_fus) [Raymer Table 6.4].');
            tc.verifyEqual(r.S_vt, expected_vt, 'RelTol', 1e-9, ...
                'S_vt must be c_VT*b*S/(0.475*L_fus) [Raymer Table 6.4].');
        end

        % ==================================================================
        % DELIBERATELY-FAILING TODO GUARDS (uncited F-35 provenance).
        %
        % The F-35 example's design provenance is Aero 481 Design01 student
        % code; the items below are _TODO -- UNCITED per
        % examples/Aero481/aero481_discrepancies.md and aero481_scribe_plan.md
        % section 9. Per repo policy each gets a clearly-labelled,
        % deliberately-failing test that turns GREEN only when a PRIMARY
        % citation is pinned into docs/reference_extracts/ (or the value is
        % replaced with a cited one). These are the ONLY expected failures in
        % this Tier-1 suite. NONE is a code bug; NONE may be "fixed" by
        % inventing a citation or deleting the test.
        % ==================================================================

        function testTODO_OEWSainristilCoeffsUncited(tc)
        % A7: the Sainristil OEW-fraction coefficients 0.882 / -0.055
        % [A481 Design01.m:26 "regression from Sainristil team"] are a
        % student-team fit with NO textbook citation.
            [~, ~, ~, ~, wts] = TestAero481Disciplines.buildStack();
            tc.verifyEqual(wts.oew_coeff_a, 0.882,  'AbsTol', 1e-12);
            tc.verifyEqual(wts.oew_coeff_c, -0.055, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation A7): the OEW-fraction coefficients ', ...
                '0.882 / -0.055 (Aero481WeightsL1.oew_coeff_a/_c) are the UNCITED ', ...
                'Sainristil-team fit [A481 Design01.m:26]. Pin a primary source ', ...
                '(or adopt the cited Raymer Table 3.1 jet_fighter 2.34*W^-0.13 ', ...
                'curve) and cite it, then delete this test.']);
        end

        function testTODO_CD0ConfigTableUncited(tc)
        % CD0 config table (clean 0.0236, ...) [A481 Design01.m:64-68,
        % "thank you Ian"] and the CLmax config table [A481 Design01.m:55-61]
        % are UNCITED student values. The config-table clean CD0 (0.0236) is read
        % via get_config_polar("clean") -- drag_polar no longer reads the config
        % table (it returns the A03 mission clean 0.014, disc A1b).
            [~, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(aero.get_config_polar("clean").CD0, 0.0236, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.get_CLmax(AircraftState(35000,0.85)), 1.8, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation): the Aero481AeroL1 CD0_config and ', ...
                'CLmax_config tables [A481 Design01.m:55-68, "thank you Ian"] ', ...
                'are UNCITED student values. Pin a primary drag/high-lift ', ...
                'source and cite it, then delete this test.']);
        end

        function testTODO_TSFCDeckUncited(tc)
        % TSFC deck 0.35 / 0.65 / 1.70 [A481 Design01.m:78-80] are UNCITED
        % student values (the Part I F135 dry deck ~0.886 is a DIFFERENT basis).
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(prop.tsfc_sls, 0.35, 'AbsTol', 1e-12);
            tc.verifyEqual(prop.tsfc_cruise, 0.65, 'AbsTol', 1e-12);
            tc.verifyEqual(prop.tsfc_dash, 1.70, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation): the Aero481PropL1 TSFC deck ', ...
                '0.35 / 0.65 / 1.70 1/hr [A481 Design01.m:78-80] are UNCITED ', ...
                'student values. Pin primary F135 deck data and cite it, then ', ...
                'delete this test.']);
        end

        function testTODO_LapseExponentUncited(tc)
        % A6: the lapse exponent m = 0 (NO altitude lapse) reproduces Aero 481,
        % which applies no thrust derating with altitude -- a DELIBERATE
        % deviation from the framework sigma^m convention (B777/F16 use m = 0.6).
        % Whether the F135 truly has no altitude lapse (vs the framework's 0.6)
        % is UNCITED (disc A6). Assert the live JSON-set value (0) so this TODO
        % fails for the citation reason, not an incidental value mismatch.
            [~, prop] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(prop.lapse_exponent_m, 0, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation A6): the Aero481PropL1 lapse exponent ', ...
                'm = 0 (no altitude lapse) reproduces Aero 481 (disc A6) and ', ...
                'deviates from the framework sigma^0.6 convention. Whether the ', ...
                'F135 has no altitude lapse (vs m = 0.6) is UNCITED. Pin an ', ...
                'F135-specific lapse source and cite it, then delete this test.']);
        end

        function testTODO_ARDesignValueUncited(tc)
        % A5: AR = 4 [A481 Design01.m:49] is a student value; the published
        % F-35A AR ~= 2.66 (35 ft span, 460 ft^2). Confirm the design AR.
            [geom, ~, aero] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(geom.AR, 4, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.AR, 4, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation A5): AR = 4 [A481 Design01.m:49] is a ', ...
                'student value; published F-35A AR ~= 2.66 (35 ft span / 460 ', ...
                'ft^2). Confirm/cite the design AR, then delete this test.']);
        end

        function testTODO_ReverserTermForFighter(tc)
        % A9: WeightsL1.engine_weight_roskam KEEPS the thrust-reverser term
        % (0.034*T) for MetaEngine parity -- but a fighter (F135) has NO
        % reverser, so the F-35 engine delta over-counts by that term.
            tc.verifyFail(['TODO(citation A9): the engine-weight delta in ', ...
                'Aero481WeightsL1 (via WeightsL1.engine_weight_roskam) KEEPS the ', ...
                'thrust-reverser term W_rev = 0.034*T [Roskam Eq. 7.15] for ', ...
                'MetaEngine parity, but a fighter (F135) has no reverser. Add a ', ...
                'fighter no-reverser engine-weight variant (or cite retaining ', ...
                'the term), then delete this test.']);
        end

        function testTODO_LambdaLEAndTailFlagsUncited(tc)
        % Lambda_LE_deg = 0 (A2) and the F-35 RSS / all-moving-tail flags are
        % _TODO -- UNCITED (need an F-35 planform document). 0 sweep reproduces
        % A481's sweep-free Oswald; the tail carries the uncorrected base coeffs.
            [geom, ~, aero, tail] = TestAero481Disciplines.buildStack(); %#ok<ASGLU>
            tc.verifyEqual(geom.Lambda_LE_deg, 0, 'AbsTol', 1e-12);
            tc.verifyEqual(aero.Lambda_LE_deg, 0, 'AbsTol', 1e-12);
            tc.verifyFail(['TODO(citation A2/tail-flags): wing Lambda_LE_deg = 0 ', ...
                'and the F-35 RSS / all-moving-tail correction flags are UNCITED ', ...
                '(need an F-35 planform document). Pin the sweep + stability/', ...
                'all-moving flags and cite them, then delete this test.']);
        end

    end
end
