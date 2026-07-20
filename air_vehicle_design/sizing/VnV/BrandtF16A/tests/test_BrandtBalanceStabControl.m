classdef test_BrandtBalanceStabControl < matlab.unittest.TestCase

    properties
        geom  BrandtGeometry
        wt    BrandtWeight
        aero  BrandtAerodynamics
        bsc   BrandtBalanceStabControl
        r     struct
    end

    methods (TestMethodSetup)
        function buildObjects(tc)
            addpath(level_brandt_test_src_root());
            tc.geom = BrandtGeometry();
            tc.geom.analyze();
            tc.wt = BrandtWeight(tc.geom);
            tc.wt.analyze();
            tc.aero = BrandtAerodynamics(tc.geom);
            tc.aero.analyze();
            tc.bsc = BrandtBalanceStabControl(tc.geom, tc.wt, tc.aero);
            tc.bsc.analyze();
            tc.r = tc.bsc.run(31377);
        end
    end

    methods (Test)
        function test_constructorDefault(tc)
            bsc2 = BrandtBalanceStabControl();
            bsc2.analyze();
            r2 = bsc2.run(31377);
            tc.verifyEqual(r2.xcg_TO_ft, tc.r.xcg_TO_ft, 'RelTol', 1e-10);
        end

        function test_analyzeRequiredBeforeRun(tc)
            bsc2 = BrandtBalanceStabControl(tc.geom, tc.wt, tc.aero);
            tc.verifyError(@() bsc2.run(31377), 'LevelBrandt:notAnalyzed');
        end

        function test_wingMAC(tc)
            tc.verifyEqual(tc.bsc.MAC_wing_ft, 11.3202, 'RelTol', 0.01);
        end

        function test_wingXMAC(tc)
            tc.verifyEqual(tc.bsc.xMAC_wing_ft, 22.7591, 'RelTol', 0.01);
        end

        function test_wingXAC(tc)
            tc.verifyEqual(tc.bsc.x_ac_wing_ft, 25.5891, 'RelTol', 0.01);
        end

        function test_fuselageCentroid(tc)
            tc.verifyEqual(tc.bsc.fuselage_xcg_ft, 26.18, 'RelTol', 0.01);
        end

        function test_neutralPoint(tc)
            tc.verifyEqual(tc.bsc.xnp_ft, 26.168, 'RelTol', 0.005);
        end

        function test_takeoffCG(tc)
            tc.verifyEqual(tc.r.xcg_TO_ft, 26.1925, 'RelTol', 0.01);
        end

        function test_landingCG(tc)
            tc.verifyEqual(tc.r.xcg_land_ft, 26.1369, 'RelTol', 0.01);
        end

        function test_takeoffStaticMargin(tc)
            tc.verifyEqual(tc.r.SM_TO, -0.00219, 'AbsTol', 0.001);
        end

        function test_landingStaticMargin(tc)
            tc.verifyEqual(tc.r.SM_land, 0.00272, 'AbsTol', 0.001);
        end

        function test_gearLoads(tc)
            tc.verifyEqual(tc.r.gear_main_pct, 26.70, 'RelTol', 0.02);
            tc.verifyEqual(tc.r.gear_nose_pct, 73.30, 'RelTol', 0.02);
        end

        function test_tipback(tc)
            tc.verifyEqual(tc.r.tipback_deg, 21.49, 'RelTol', 0.03);
        end

        function test_rollover(tc)
            tc.verifyEqual(tc.r.rollover_deg, 74.43, 'RelTol', 0.03);
        end

        function test_propertiesMatchResults(tc)
            tc.verifyEqual(tc.bsc.xcg_TO_ft, tc.r.xcg_TO_ft, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.bsc.xcg_land_ft, tc.r.xcg_land_ft, 'AbsTol', 1e-10);
            tc.verifyEqual(tc.bsc.xnp_ft, tc.r.xnp_ft, 'AbsTol', 1e-10);
        end
    end
end
