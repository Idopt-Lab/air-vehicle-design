classdef test_BrandtCost < matlab.unittest.TestCase

    properties
        geom  BrandtGeometry
        eng   BrandtEngine
        wt    BrandtWeight
        aero  BrandtAerodynamics
        miss  BrandtMission
        cost  BrandtCost
        wt_r  struct
        miss_r struct
        r     struct
    end

    methods (TestMethodSetup)
        function buildObjects(tc)
            addpath(level_brandt_test_src_root());
            tc.geom = BrandtGeometry();
            tc.geom.analyze();
            tc.eng = BrandtEngine();
            tc.eng.analyze();
            tc.wt = BrandtWeight(tc.geom);
            tc.wt.analyze();
            tc.aero = BrandtAerodynamics(tc.geom);
            tc.aero.analyze();
            tc.miss = BrandtMission(tc.aero, tc.eng, tc.geom);
            tc.miss.analyze();
            tc.wt_r = tc.wt.run(31377);
            tc.miss_r = tc.miss.run(31377);
            tc.cost = BrandtCost(tc.geom, tc.eng);
            tc.cost.analyze();
            tc.r = tc.cost.run(31377, tc.wt_r, tc.miss_r);
        end
    end

    methods (Test)
        function test_constructorDefault(tc)
            cost2 = BrandtCost();
            cost2.analyze();
            r2 = cost2.run(31377, tc.wt_r, tc.miss_r);
            tc.verifyEqual(r2.C_unit_flyaway_usd, tc.r.C_unit_flyaway_usd, 'RelTol', 1e-10);
        end

        function test_analyzeRequiredBeforeRun(tc)
            cost2 = BrandtCost(tc.geom, tc.eng);
            tc.verifyError(@() cost2.run(31377, tc.wt_r, tc.miss_r), 'LevelBrandt:notAnalyzed');
        end

        function test_resultStructFields(tc)
            expected = {'D47','C_unit_flyaway_usd','C_total_program_usd','C_OM_life_usd','C_LCC_usd','We_lb','V_max_kts'};
            actual = fieldnames(tc.r);
            for k = 1:numel(expected)
                tc.verifyTrue(ismember(expected{k}, actual));
            end
        end

        function test_materialFactor(tc)
            tc.verifyEqual(tc.r.D47, 1.03, 'AbsTol', 1e-12);
        end

        function test_unitFlyawayCost(tc)
            tc.verifyEqual(tc.r.C_unit_flyaway_usd, 68.4e6, 'RelTol', 0.05);
        end

        function test_totalProgramCost(tc)
            tc.verifyEqual(tc.r.C_total_program_usd, 13.68e9, 'RelTol', 0.05);
        end

        function test_OMlifeCost(tc)
            tc.verifyEqual(tc.r.C_OM_life_usd, 24.84e6, 'RelTol', 0.05);
        end

        function test_LCC(tc)
            tc.verifyEqual(tc.r.C_LCC_usd, 93.26e6, 'RelTol', 0.05);
        end

        function test_propertiesMatchResults(tc)
            tc.verifyEqual(tc.cost.C_unit_flyaway_usd, tc.r.C_unit_flyaway_usd, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.cost.C_total_program_usd, tc.r.C_total_program_usd, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.cost.C_LCC_usd, tc.r.C_LCC_usd, 'AbsTol', 1e-10);
        end
    end
end
