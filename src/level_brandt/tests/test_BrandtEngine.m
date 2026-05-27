classdef test_BrandtEngine < matlab.unittest.TestCase
% test_BrandtEngine  MATLAB unit tests for BrandtEngine.
%
% Run: results = runtests('src/level_brandt/tests/test_BrandtEngine.m')
% Or:  results = run(test_BrandtEngine)

    properties (Access = private)
        eng  % shared BrandtEngine after analyze()
    end

    methods (TestClassSetup)
        function buildEngine(tc)
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), '..'));
            tc.eng = BrandtEngine();
            tc.eng.analyze();
        end
    end

    methods (Test)
        % ── SLS parameters (loaded from JSON) ──────────────────────────
        function testTslDry(tc)
            tc.verifyEqual(tc.eng.T_sl_dry, 15000.0, 'RelTol', 0.01);
        end
        function testTslAB(tc)
            tc.verifyEqual(tc.eng.T_sl_AB, 23770.0, 'RelTol', 0.01);
        end
        function testTSFCslDry(tc)
            tc.verifyEqual(tc.eng.TSFC_sl_dry, 0.70, 'RelTol', 0.01);
        end
        function testTSFCslAB(tc)
            tc.verifyEqual(tc.eng.TSFC_sl_AB, 2.20, 'RelTol', 0.01);
        end
        function testTR(tc)
            tc.verifyEqual(tc.eng.TR, 1.0, 'RelTol', 0.01);
        end

        % ── SLS thrust recovery (h=0, M=0) ───────────────────────────
        function testThrustDrySLS(tc)
            % T_dry at SLS = T_sl_dry within 1%
            [T, ~] = tc.eng.thrust_dry(0, 0);
            tc.verifyEqual(T, 15000.0, 'RelTol', 0.01);
        end
        function testThrustABSLS(tc)
            [T, ~] = tc.eng.thrust_AB(0, 0);
            tc.verifyEqual(T, 23770.0, 'RelTol', 0.01);
        end
        function testTSFCdrySLS(tc)
            [~, tsfc] = tc.eng.thrust_dry(0, 0);
            tc.verifyEqual(tsfc, 0.70, 'RelTol', 0.01);
        end

        % ── run() struct interface ─────────────────────────────────────
        function testRunDryStruct(tc)
            % run() returns struct with correct fields
            r = tc.eng.run(0, 0, 0.0);  % SLS, dry
            tc.verifyTrue(isfield(r, 'alpha'));
            tc.verifyTrue(isfield(r, 'alpha_AB_ref'));
            tc.verifyTrue(isfield(r, 'T'));
            tc.verifyTrue(isfield(r, 'TSFC'));
        end
        function testRunDrySLSValues(tc)
            % run() at SLS, dry: T=15000, alpha~1, TSFC=0.70
            % alpha_AB_ref = T_sl_dry/T_sl_AB = 15000/23770 = 0.6311
            r = tc.eng.run(0, 0, 0.0);
            tc.verifyEqual(r.T,            15000.0, 'RelTol', 0.01);
            tc.verifyEqual(r.TSFC,         0.70,    'RelTol', 0.01);
            tc.verifyEqual(r.alpha,        1.0,     'RelTol', 0.01);
            tc.verifyEqual(r.alpha_AB_ref, 15000/23770, 'RelTol', 0.01);
        end
        function testRunABSLSValues(tc)
            % run() at SLS, full AB: T=23770, alpha_AB_ref=1.0
            r = tc.eng.run(0, 0, 1.0);
            tc.verifyEqual(r.T,            23770.0, 'RelTol', 0.01);
            tc.verifyEqual(r.alpha_AB_ref, 1.0,     'RelTol', 0.01);
        end
        function testRunDualReturn(tc)
            % Properties updated by run() match returned struct
            r = tc.eng.run(20000, 0.8, 0.0);
            tc.verifyEqual(tc.eng.run_T_lb,         r.T);
            tc.verifyEqual(tc.eng.run_TSFC,         r.TSFC);
            tc.verifyEqual(tc.eng.run_alpha,        r.alpha);
            tc.verifyEqual(tc.eng.run_alpha_AB_ref, r.alpha_AB_ref);
        end
        function testAlphaABRefLessThanAlphaDry(tc)
            % At SLS dry, alpha=1 but alpha_AB_ref < 1 (since T_sl_AB > T_sl_dry)
            r = tc.eng.run(0, 0, 0.0);
            tc.verifyLessThan(r.alpha_AB_ref, r.alpha);
        end
        function testAlphaABRefEqualsOneAtFullABSLS(tc)
            % At SLS full AB, alpha_AB_ref should equal 1.0
            r = tc.eng.run(0, 0, 1.0);
            tc.verifyEqual(r.alpha_AB_ref, 1.0, 'RelTol', 0.01);
        end
        function testRunPartialAB(tc)
            % Partial AB (50%) gives T between dry and full AB
            [T_dry, ~] = tc.eng.thrust_dry(20000, 0.8);
            [T_AB,  ~] = tc.eng.thrust_AB(20000,  0.8);
            r = tc.eng.run(20000, 0.8, 0.5);
            tc.verifyGreaterThan(r.T, T_dry);
            tc.verifyLessThan(r.T, T_AB);
        end
        function testRunTDecreaseWithAlt(tc)
            r_sl  = tc.eng.run(0,     0.5, 0.0);
            r_20k = tc.eng.run(20000, 0.5, 0.0);
            r_40k = tc.eng.run(40000, 0.5, 0.0);
            tc.verifyGreaterThan(r_sl.T,  r_20k.T);
            tc.verifyGreaterThan(r_20k.T, r_40k.T);
        end
        function testRunABGreaterThanDry(tc)
            r_dry = tc.eng.run(30000, 0.8, 0.0);
            r_AB  = tc.eng.run(30000, 0.8, 1.0);
            tc.verifyGreaterThan(r_AB.T, r_dry.T);
        end
    end
end
