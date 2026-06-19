classdef test_BrandtPerformance < matlab.unittest.TestCase

    properties
        geom  BrandtGeometry
        aero  BrandtAerodynamics
        eng   BrandtEngine
        wt    BrandtWeight
        perf  BrandtPerformance
        r     struct
    end

    methods (TestMethodSetup)
        function buildObjects(tc)
            addpath(level_brandt_test_src_root());
            tc.geom = BrandtGeometry();
            tc.geom.analyze();
            tc.aero = BrandtAerodynamics(tc.geom);
            tc.aero.analyze();
            tc.eng = BrandtEngine();
            tc.eng.analyze();
            tc.wt = BrandtWeight(tc.geom);
            tc.wt.analyze();
            tc.perf = BrandtPerformance(tc.geom, tc.aero, tc.eng, tc.wt);
            tc.perf.analyze();
            tc.r = tc.perf.run(31377);
        end
    end

    methods (Test)
        function test_constructorDefault(tc)
            perf2 = BrandtPerformance();
            perf2.analyze();
            r2 = perf2.run(31377);
            tc.verifyGreaterThan(r2.Ps_peak_fps, 0);
        end

        function test_analyzeRequiredBeforeRun(tc)
            perf2 = BrandtPerformance(tc.geom, tc.aero, tc.eng, tc.wt);
            tc.verifyError(@() perf2.run(31377), 'LevelBrandt:notAnalyzed');
        end

        function test_resultStructFields(tc)
            expected = {'perf_table','Ps_grid','mach_ps','alt_ps_ft','turn_rate_table','vn_diagram','Ps_peak_fps','turn_rate_peak_deg_s'};
            actual = fieldnames(tc.r);
            for k = 1:numel(expected)
                tc.verifyTrue(ismember(expected{k}, actual));
            end
        end

        function test_cruiseSpecificExcessPowerPositive(tc)
            perf_table = tc.perf.run_perf(31377, 40000, 0);
            [~, idx] = min(abs(perf_table.mach - 0.87));
            tc.verifyGreaterThan(perf_table.Ps_fps(idx), 0);
        end

        function test_turnRateAtCombatCondition(tc)
            maneuv = tc.perf.run_maneuv(31377, 10000, 100, 9);
            [~, idx] = min(abs(maneuv.mach - 0.87));
            tc.verifyGreaterThan(maneuv.turn_rate_sustained_deg_s(idx), 10);
        end

        function test_psGridPopulated(tc)
            tc.verifyGreaterThan(size(tc.r.Ps_grid, 1), 5);
            tc.verifyGreaterThan(size(tc.r.Ps_grid, 2), 5);
            tc.verifyGreaterThan(tc.r.Ps_peak_fps, 0);
        end

        function test_vnOutputs(tc)
            vn = tc.r.vn_diagram;
            tc.verifyGreaterThan(vn.V_corner_fps, vn.V_stall_pos_fps);
            tc.verifyLessThanOrEqual(vn.V_corner_fps, vn.V_qmax_fps);
        end

        function test_propertiesMatchResults(tc)
            tc.verifyEqual(tc.perf.Ps_peak_fps, tc.r.Ps_peak_fps, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.perf.turn_rate_peak_deg_s, tc.r.turn_rate_peak_deg_s, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.perf.vn_diagram.V_corner_fps, tc.r.vn_diagram.V_corner_fps, 'AbsTol', 1e-10);
        end
    end
end
