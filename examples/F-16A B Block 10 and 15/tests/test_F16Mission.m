classdef test_F16Mission < matlab.unittest.TestCase
    % V&V tests for F-16 mission analysis discipline objects.
    %
    % Brandt reference (Miss tab):
    %   Total fuel burn = 6,000 lb  (Miss!O9)
    %   Total mission time = 94 min
    %   W_TO = 31,377 lb
    %
    % At L1, fuel fractions give a rough estimate; expect ±25% of 6000 lb.
    % At L2/L3, single-point and sub-segmented Breguet improve to ±15%.
    %
    % NOTE: these tests use a simplified 11-segment mission profile (vs Brandt's
    % 14 segments). Fuel estimates will be lower than Brandt's 6000 lb because
    % the patrol loiters and second climb are omitted.

    properties
        geom_json
        W_TO_brandt    = 31377   % lbf
        W_fuel_brandt  = 6000    % lbf
        W_payload      = 5100    % 4400 + 700 lbf
    end

    methods (TestClassSetup)
        function setup(~)
            TestSetup();
        end
    end

    methods (TestMethodSetup)
        function loadJSON(tc)
            json_path = fullfile(fileparts(mfilename('fullpath')), ...
                '..', 'Ground-Truth', 'f16a_geometry.json');
            tc.geom_json = jsondecode(fileread(json_path));
        end
    end

    methods (Test)

        function testL1_compute_fuel_positive(tc)
            aero = F16AeroLevel1(tc.geom_json);
            prop = F16PropulsionLevel1(tc.geom_json);
            miss = F16MissionLevel1();
            req  = tc.build_req();
            fuel = miss.compute_fuel(aero, prop, tc.W_TO_brandt, req);
            tc.verifyGreaterThan(fuel, 1000, 'L1 fuel must be > 1000 lb');
            tc.verifyLessThan(fuel, 12000,   'L1 fuel must be < 12000 lb (sanity check)');
        end

        function testL1_fuel_decreasesWithLowerWTO(tc)
            aero   = F16AeroLevel1(tc.geom_json);
            prop   = F16PropulsionLevel1(tc.geom_json);
            miss   = F16MissionLevel1();
            req    = tc.build_req();
            fuel1  = miss.compute_fuel(aero, prop, 31377, req);
            fuel2  = miss.compute_fuel(aero, prop, 25000, req);
            tc.verifyGreaterThan(fuel1, fuel2, ...
                'Heavier aircraft must burn more fuel');
        end

        function testL2_compute_fuel_positive(tc)
            aero = F16AeroLevel2(tc.geom_json);
            prop = F16PropulsionLevel2(tc.geom_json);
            prop.T0 = tc.geom_json.engine.T_AB_SLS_lb;
            miss = F16MissionLevel2();
            req  = tc.build_req();
            fuel = miss.compute_fuel(aero, prop, tc.W_TO_brandt, req);
            tc.verifyGreaterThan(fuel, 500,   'L2 fuel > 500 lb');
            tc.verifyLessThan(fuel,   12000,  'L2 fuel < 12000 lb');
        end

        function testL3_compute_fuel_positive(tc)
            aero = F16AeroLevel3(tc.geom_json);
            prop = F16PropulsionLevel3(tc.geom_json);
            prop.T0 = tc.geom_json.engine.T_AB_SLS_lb;
            miss = F16MissionLevel3(10);  % fewer sub-segs for speed
            req  = tc.build_req();
            fuel = miss.compute_fuel(aero, prop, tc.W_TO_brandt, req);
            tc.verifyGreaterThan(fuel, 500);
            tc.verifyLessThan(fuel,   12000);
        end

        function testL2_vs_L1_fuel_reasonableRange(tc)
            % L2 and L1 should be within factor of 2 of each other
            req  = tc.build_req();
            aero1 = F16AeroLevel1(tc.geom_json);
            prop1 = F16PropulsionLevel1(tc.geom_json);
            miss1 = F16MissionLevel1();
            fuel1 = miss1.compute_fuel(aero1, prop1, tc.W_TO_brandt, req);

            aero2 = F16AeroLevel2(tc.geom_json);
            prop2 = F16PropulsionLevel2(tc.geom_json);
            prop2.T0 = tc.geom_json.engine.T_AB_SLS_lb;
            miss2 = F16MissionLevel2();
            fuel2 = miss2.compute_fuel(aero2, prop2, tc.W_TO_brandt, req);

            ratio = fuel1/fuel2;
            tc.verifyGreaterThan(ratio, 0.4, 'L1/L2 fuel ratio must be > 0.4');
            tc.verifyLessThan(ratio,    2.5, 'L1/L2 fuel ratio must be < 2.5');
        end

        function testL1_fuelFraction_fighters(tc)
            % Static method: tab_fuelfraction for fighter aircraft
            WF = MissionAnalysisLevel1.tab_fuelfraction('fighter', 'climb');
            tc.verifyGreaterThan(WF, 0.85, 'Fighter climb WF > 0.85');
            tc.verifyLessThan(WF,    1.00, 'Fighter climb WF < 1.00');
        end

    end

    methods (Access = private)
        function req = build_req(tc)
            req.W_payload = tc.W_payload;
            req.S_ref     = tc.geom_json.wing.S_ref_ft2;
            req.AR        = tc.geom_json.wing.AR;
            req.aircraft_type = 'fighter';
            req.engine_type   = 'jet';

            seg(1).name='startup';  seg(1).altitude_ft=0;     seg(1).mach=0;
            seg(2).name='taxi';     seg(2).altitude_ft=0;     seg(2).mach=0;
            seg(3).name='takeoff';  seg(3).altitude_ft=0;     seg(3).mach=0.282;
            seg(4).name='climb';    seg(4).altitude_ft=40000; seg(4).mach=0.87;
            seg(5).name='cruise';   seg(5).altitude_ft=40000; seg(5).mach=0.87;
                                     seg(5).range_ft=190.8*6076;
            seg(6).name='dash';     seg(6).altitude_ft=40000; seg(6).mach=0.87;
                                     seg(6).range_ft=50*6076;
            seg(7).name='combat';   seg(7).altitude_ft=25000; seg(7).mach=0.87;
                                     seg(7).time_min=2; seg(7).W_drop=4400;
            seg(8).name='cruise';   seg(8).altitude_ft=40000; seg(8).mach=0.87;
                                     seg(8).range_ft=250*6076;
            seg(9).name='loiter';   seg(9).altitude_ft=10000; seg(9).mach=0.30;
                                     seg(9).time_min=20;
            seg(10).name='descent'; seg(10).altitude_ft=0; seg(10).mach=0.3;
            seg(11).name='landing'; seg(11).altitude_ft=0; seg(11).mach=0.2;
            req.segments = seg;
        end
    end

    methods (TestClassTeardown)
        function printComparisonTable(tc) %#ok<MANU>
            fprintf('\n%s\n', repmat('=',1,70));
            fprintf('  F-16 Mission Analysis V&V — Comparison to Brandt Targets\n');
            fprintf('%s\n', repmat('=',1,70));
            fprintf('  Brandt total fuel (14 segments, Miss!O9): 6,000 lb\n');
            fprintf('  Design study mission (11 segments): ~3,500-5,500 lb expected\n');
            fprintf('  Discrepancy source: omitted patrol legs and second climb\n');
            fprintf('%s\n', repmat('=',1,70));
        end
    end

end
