classdef test_BrandtConstraintAnalysis < matlab.unittest.TestCase
% test_BrandtConstraintAnalysis  Unit tests for BrandtConstraintAnalysis.
%
% Verifies the Consts-tab reimplementation against Excel ground-truth values.
%
% TOLERANCE RATIONALE:
%   Excel ground-truth uses Brandt's polynomial atmosphere model. MATLAB
%   uses atmosisa.  Resulting deviations in ρ and a are ≤2%.  A 5% tolerance
%   is applied for subsonic constraints; 8% for supersonic (max_mach,
%   combat_turn_sup) to account for compressibility model differences.
%
% GROUND-TRUTH SOURCE:
%   Brandt-F16-A.xls, Consts tab.  β = 0.89966696 (B23).
%   See readme_consts.md for full derivation.

    properties (TestParameter)
        % Ground truth T/W values from Consts tab at these W/S points
        % Columns: [WS, max_mach, cruise, max_alt, combat_turn_sub, ps_500, takeoff]
        gt_rows = {
            [20,  2.9012, 1.2912, 0.7274, 0.7500, 1.3323, 0.1357], ...
            [27,  2.1533, 0.9831, 0.5911, 0.6216, 1.1344, 0.1628], ...
            [34,  1.7144, 0.8081, 0.5233, 0.5617, 1.0184, 0.1898], ...
            [41,  1.4262, 0.6981, 0.4888, 0.5352, 0.9424, 0.2168], ...
            [48,  1.2228, 0.6247, 0.4732, 0.5274, 0.8888, 0.2438], ...
            [55,  1.0718, 0.5738, 0.4692, 0.5314, 0.8491, 0.2709], ...
            [62,  0.9555, 0.5379, 0.4729, 0.5430, 0.8186, 0.2979], ...
            [69,  0.8632, 0.5124, 0.4819, 0.5599, 0.7945, 0.3249]  ...
        };
    end

    properties
        geom
        aero
        eng
        constr
        WS_test  = [20, 27, 34, 41, 48, 55, 62, 69]  % psf
    end

    methods (TestMethodSetup)
        function buildChain(tc)
            addpath(level_brandt_test_src_root());
            tc.geom  = BrandtGeometry();    tc.geom.analyze();
            tc.aero  = BrandtAerodynamics(tc.geom); tc.aero.analyze();
            tc.eng   = BrandtEngine();      tc.eng.analyze();
            tc.constr = BrandtConstraintAnalysis(tc.aero, tc.eng);
            tc.constr.analyze();
        end
    end

    % ------------------------------------------------------------------ %
    %  Construction and analysis                                          %
    % ------------------------------------------------------------------ %

    methods (Test)

        function testConstructorCreatesObject(tc)
            tc.assertClass(tc.constr, 'BrandtConstraintAnalysis');
        end

        function testConstructorNoArgs(tc)
            c = BrandtConstraintAnalysis();
            c.analyze();
            tc.assertFalse(isnan(c.beta_perf));
        end

        function testAnalyzePopulatesProperties(tc)
            tc.assertFalse(isnan(tc.constr.beta_perf));
            tc.assertFalse(isnan(tc.constr.S_ref_ft2));
            tc.assertFalse(isnan(tc.constr.CLmax_TO));
            tc.assertFalse(isnan(tc.constr.CLmax_land));
            tc.assertFalse(isnan(tc.constr.mu_rolling));
            tc.assertFalse(isnan(tc.constr.mu_braking));
        end

        function testAnalyzeValues(tc)
            % Verify extracted values match JSON / aero object
            tc.assertEqual(tc.constr.beta_perf, 0.89966696, 'RelTol', 1e-6);
            tc.assertGreaterThan(tc.constr.CLmax_TO, 1.1);
            tc.assertLessThan(tc.constr.CLmax_TO, 1.5);
            tc.assertGreaterThan(tc.constr.CLmax_land, tc.constr.CLmax_TO);
        end

        function testRequireAnalyzedGuard(tc)
            c = BrandtConstraintAnalysis(tc.aero, tc.eng);  % not analyzed
            tc.assertError(@() c.max_mach(48), 'LevelBrandt:notAnalyzed');
            tc.assertError(@() c.run(48), 'LevelBrandt:notAnalyzed');
        end

    end  % construction tests

    % ------------------------------------------------------------------ %
    %  Per-constraint T/W values vs ground truth                         %
    % ------------------------------------------------------------------ %

    methods (Test, ParameterCombination = 'sequential')

        function testMaxMach(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(2);
            TW = tc.constr.max_mach(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.08, ...
                sprintf('max_mach at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

        function testCruise(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(3);
            TW = tc.constr.cruise(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.05, ...
                sprintf('cruise at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

        function testMaxAlt(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(4);
            TW = tc.constr.max_alt(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.05, ...
                sprintf('max_alt at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

        function testCombatTurnSub(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(5);
            TW = tc.constr.combat_turn_sub(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.05, ...
                sprintf('combat_turn_sub at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

        function testPs500(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(6);
            TW = tc.constr.ps_500(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.05, ...
                sprintf('ps_500 at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

        function testTakeoff(tc, gt_rows)
            WS = gt_rows(1);  GT = gt_rows(7);
            TW = tc.constr.takeoff(WS);
            tc.verifyEqual(TW, GT, 'RelTol', 0.05, ...
                sprintf('takeoff at W/S=%g: MATLAB=%.4f, GT=%.4f', WS, TW, GT));
        end

    end  % parametric tests

    % ------------------------------------------------------------------ %
    %  Landing constraint                                                 %
    % ------------------------------------------------------------------ %

    methods (Test)

        function testLandingWingLoadingMax(tc)
            % Excel ground truth: 138.4794 psf (Consts!K33)
            WS_max = tc.constr.landing();
            tc.verifyEqual(WS_max, 138.4794, 'RelTol', 0.05, ...
                sprintf('landing W/S_max: MATLAB=%.4f, GT=138.4794', WS_max));
        end

        function testLandingScalar(tc)
            WS_max = tc.constr.landing();
            tc.assertScalarOf(WS_max, 'double');
        end

    end  % landing tests

    % ------------------------------------------------------------------ %
    %  run() contract                                                     %
    % ------------------------------------------------------------------ %

    methods (Test)

        function testRunReturnsDualContract(tc)
            WS = linspace(10, 160, 51);
            r = tc.constr.run(WS);
            % Struct fields exist
            tc.assertField(r, 'TW_max_mach');
            tc.assertField(r, 'TW_cruise');
            tc.assertField(r, 'TW_max_alt');
            tc.assertField(r, 'TW_combat_turn_sub');
            tc.assertField(r, 'TW_combat_turn_sup');
            tc.assertField(r, 'TW_ps500');
            tc.assertField(r, 'TW_takeoff');
            tc.assertField(r, 'WS_landing_max');
            tc.assertField(r, 'TW_envelope');
            tc.assertField(r, 'WS_opt');
            tc.assertField(r, 'TW_opt');
        end

        function testRunStoresProperties(tc)
            WS = linspace(10, 160, 51);
            tc.constr.run(WS);
            tc.assertFalse(isempty(tc.constr.run_TW_max_mach));
            tc.assertFalse(isnan(tc.constr.run_WS_opt));
        end

        function testRunEquivalence(tc)
            % Returned struct and stored properties hold the same values
            WS = linspace(10, 160, 51);
            r = tc.constr.run(WS);
            tc.assertEqual(r.TW_max_mach, tc.constr.run_TW_max_mach);
            tc.assertEqual(r.WS_opt, tc.constr.run_WS_opt);
        end

        function testRunNoNaN(tc)
            WS = linspace(10, 160, 51);
            r = tc.constr.run(WS);
            tc.assertFalse(any(isnan(r.TW_max_mach)));
            tc.assertFalse(any(isnan(r.TW_envelope)));
        end

        function testRunEnvelopeGeqAllConstraints(tc)
            WS = linspace(10, 150, 141);
            r = tc.constr.run(WS);
            tc.assertGreaterThanOrEqual(r.TW_envelope, r.TW_max_mach - 1e-12);
            tc.assertGreaterThanOrEqual(r.TW_envelope, r.TW_cruise - 1e-12);
            tc.assertGreaterThanOrEqual(r.TW_envelope, r.TW_ps500 - 1e-12);
            tc.assertGreaterThanOrEqual(r.TW_envelope, r.TW_takeoff - 1e-12);
        end

        function testRunColumnOutput(tc)
            WS_row = [20, 48, 69];
            r = tc.constr.run(WS_row);
            tc.assertEqual(size(r.TW_max_mach, 1), 3);
            tc.assertEqual(size(r.TW_max_mach, 2), 1);
        end

    end  % run() tests

    % ------------------------------------------------------------------ %
    %  Optimal design point                                               %
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOptimalPointRange(tc)
            WS = linspace(10, 160, 301);
            tc.constr.run(WS);
            pt = tc.constr.optimal_point();
            % Expected from Size&Opt sheet: WS≈104.59, TW≈0.7576
            tc.assertGreaterThan(pt.WS, 70, 'WS_opt below expected range');
            tc.assertLessThan(pt.WS, 140, 'WS_opt above expected range');
            tc.assertGreaterThan(pt.TW, 0.5, 'TW_opt below expected range');
            tc.assertLessThan(pt.TW, 1.2, 'TW_opt above expected range');
        end

        function testOptimalPointStruct(tc)
            WS = linspace(10, 160, 151);
            tc.constr.run(WS);
            pt = tc.constr.optimal_point();
            tc.assertField(pt, 'WS');
            tc.assertField(pt, 'TW');
        end

        function testOptimalPointBelowLandingLimit(tc)
            WS = linspace(10, 160, 151);
            r = tc.constr.run(WS);
            pt = tc.constr.optimal_point();
            tc.assertLessThanOrEqual(pt.WS, r.WS_landing_max + 1e-6, ...
                'Optimal W/S must not exceed landing limit');
        end

        function testOptimalPointPreRunError(tc)
            c = BrandtConstraintAnalysis(tc.aero, tc.eng);
            c.analyze();
            tc.assertError(@() c.optimal_point(), 'LevelBrandt:notRun');
        end

    end  % optimal point tests

    % ------------------------------------------------------------------ %
    %  Physical sanity checks                                             %
    % ------------------------------------------------------------------ %

    methods (Test)

        function testMaxMachHigherThanCruise(tc)
            % Max Mach (100%AB, M=1.6) requires higher T/W than cruise (0%AB)
            WS = 48;
            tc.assertGreaterThan(tc.constr.max_mach(WS), tc.constr.cruise(WS));
        end

        function testTakeoffMonotonicallyIncreasing(tc)
            WS = 20:5:80;
            TW = tc.constr.takeoff(WS);
            tc.assertTrue(all(diff(TW) > 0), ...
                'Takeoff T/W should increase with W/S (heavier per unit area)');
        end

        function testCruiseMonotonicallyDecreasingThenIncreasing(tc)
            % At low W/S, parasite drag dominates (T/W decreases with W/S).
            % At high W/S, induced drag dominates (T/W increases with W/S).
            WS = linspace(10, 120, 111);
            TW = tc.constr.cruise(WS);
            [~, i_min] = min(TW);
            tc.assertGreaterThan(i_min, 1, 'No minimum found for cruise');
            tc.assertLessThan(i_min, length(WS), 'Minimum is at end of range');
        end

        function testAllTWPositive(tc)
            WS = linspace(10, 130, 121);
            tc.assertGreaterThan(tc.constr.max_mach(WS), 0);
            tc.assertGreaterThan(tc.constr.cruise(WS), 0);
            tc.assertGreaterThan(tc.constr.ps_500(WS), 0);
            tc.assertGreaterThan(tc.constr.takeoff(WS), 0);
        end

        function testLandingWingLoadingPositive(tc)
            WS_max = tc.constr.landing();
            tc.assertGreaterThan(WS_max, 0);
        end

        function testAtWS48SpecificValues(tc)
            % Spot-check at W/S = 48 psf with wider tolerance
            WS = 48;
            tc.verifyEqual(tc.constr.max_mach(WS),        1.2228, 'RelTol', 0.08);
            tc.verifyEqual(tc.constr.cruise(WS),           0.6247, 'RelTol', 0.05);
            tc.verifyEqual(tc.constr.max_alt(WS),          0.4732, 'RelTol', 0.05);
            tc.verifyEqual(tc.constr.combat_turn_sub(WS),  0.5274, 'RelTol', 0.05);
            tc.verifyEqual(tc.constr.ps_500(WS),           0.8888, 'RelTol', 0.05);
            tc.verifyEqual(tc.constr.takeoff(WS),          0.2438, 'RelTol', 0.05);
        end

    end  % sanity checks

    % ------------------------------------------------------------------ %
    %  Helper assertions                                                  %
    % ------------------------------------------------------------------ %
    methods (Access = private)
        function assertField(tc, s, fname)
            tc.assertTrue(isfield(s, fname), ...
                sprintf('Expected field "%s" missing from struct', fname));
        end

        function assertScalarOf(tc, val, cls)
            tc.assertEqual(class(val), cls);
            tc.assertEqual(numel(val), 1);
        end
    end

end
