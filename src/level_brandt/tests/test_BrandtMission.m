classdef test_BrandtMission < matlab.unittest.TestCase
% test_BrandtMission  MATLAB unit tests for BrandtMission.
%   Replicates Miss tab validation targets.
%   Run: results = runtests('src/level_brandt/tests/test_BrandtMission.m')
%   Or:  results = run(test_BrandtMission)

    properties (Access = private)
        miss  % BrandtMission handle after run()
    end

    methods (TestClassSetup)
        function buildMission(tc)
            % Build full dependency chain and run mission analysis.
            % W_TO_lb = 31377.0 lb (from f16a_geometry.json, Miss tab baseline)
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), '..'));
            geom = BrandtGeometry(); geom.analyze();
            aero = BrandtAerodynamics(geom); aero.analyze();
            eng  = BrandtEngine();           eng.analyze();
            tc.miss = BrandtMission(aero, eng, geom);
            tc.miss.run(31377.0);   % W_TO_lb as function input
        end
    end

    methods (Test)
        % ── Mission-level summary targets (Miss!O6, O8, O9) ──────────

        function testTotalFuel(tc)
            % Miss!O9 = 6000.43 lb
            tc.verifyEqual(tc.miss.total_fuel_lb, 6000.43, 'RelTol', 0.01, ...
                'Total fuel should match Miss!O9 within 1%');
        end

        function testTotalTime(tc)
            % Miss!O8 = 94.06 min
            tc.verifyEqual(tc.miss.total_time_min, 94.06, 'RelTol', 0.01, ...
                'Total time should match Miss!O8 within 1%');
        end

        function testLandingDist(tc)
            % Miss!O6 = 2884.95 ft
            tc.verifyEqual(tc.miss.landing_dist_ft, 2884.95, 'RelTol', 0.01, ...
                'Landing distance should match Miss!O6 within 1%');
        end

        function testFinalWeightFraction(tc)
            % Miss!O12 = 0.6685 (W/Wto after loiter)
            tc.verifyEqual(tc.miss.W_Wto(end-1), 0.6685, 'RelTol', 0.01, ...
                'Final W/Wto after loiter should match Miss!O12 within 1%');
        end

        % ── Per-segment fuel burns (Miss!B9:N9) ─────────────────────
        % Ground truth: [1540.1, 377.2, 449.1, 1003.3, 0, 484.1, 0, 564.0, 304.6, 0, 0, 789.4, 488.6]
        % Segments:     Takeoff Accel  Climb  Cruise  P1   Dash  P2  Combat Egress P3 Climb2 Cruise2 Loiter
        %
        % NOTE: Climb (-1.06%), Egress (-1.21%), Cruise2 (-1.50%) use 2% tolerance.
        % These deviations trace entirely to the known S_wet discrepancy:
        %   Code: S_wet = 1332.69 ft² (correct — Excel double-counts strakes, documented in readme_geom.md)
        %   Excel: 1371.09 ft² (includes K21 strake chine term twice)
        % This 2.8% lower S_wet → ~2.8% lower CDmin → ~1-1.5% less fuel for cruise/climb/egress.
        % The 2% tolerance is consistent with FR-003 in level-brandt.md (±5% acceptable for known discrepancies).

        function testFuelTakeoff(tc)
            tc.verifyEqual(tc.miss.fuel_lb(1), 1540.1, 'RelTol', 0.01, 'Takeoff fuel Miss!B9');
        end
        function testFuelAccel(tc)
            tc.verifyEqual(tc.miss.fuel_lb(2), 377.2, 'RelTol', 0.01, 'Accel fuel Miss!C9');
        end
        function testFuelClimb(tc)
            % 2% tolerance: known S_wet discrepancy causes ~1.06% deviation
            tc.verifyEqual(tc.miss.fuel_lb(3), 449.1, 'RelTol', 0.02, 'Climb fuel Miss!D9 (2% tol: known S_wet discrepancy)');
        end
        function testFuelCruise(tc)
            tc.verifyEqual(tc.miss.fuel_lb(4), 1003.3, 'RelTol', 0.01, 'Cruise fuel Miss!E9');
        end
        function testFuelPatrol(tc)
            % Zero-fuel segment: absolute tolerance
            tc.verifyEqual(tc.miss.fuel_lb(5), 0.0, 'AbsTol', 5.0, 'Patrol fuel Miss!F9 (zero)');
        end
        function testFuelDash(tc)
            tc.verifyEqual(tc.miss.fuel_lb(6), 484.1, 'RelTol', 0.01, 'Dash fuel Miss!G9');
        end
        function testFuelPatrol2(tc)
            tc.verifyEqual(tc.miss.fuel_lb(7), 0.0, 'AbsTol', 5.0, 'Patrol2 fuel Miss!H9 (zero)');
        end
        function testFuelCombat(tc)
            tc.verifyEqual(tc.miss.fuel_lb(8), 564.0, 'RelTol', 0.01, 'Combat fuel Miss!I9');
        end
        function testFuelEgress(tc)
            % 2% tolerance: known S_wet discrepancy causes ~1.21% deviation
            tc.verifyEqual(tc.miss.fuel_lb(9), 304.6, 'RelTol', 0.02, 'Egress fuel Miss!J9 (2% tol: known S_wet discrepancy)');
        end
        function testFuelPatrol3(tc)
            tc.verifyEqual(tc.miss.fuel_lb(10), 0.0, 'AbsTol', 5.0, 'Patrol3 fuel Miss!K9 (zero)');
        end
        function testFuelClimb2(tc)
            tc.verifyEqual(tc.miss.fuel_lb(11), 0.0, 'AbsTol', 5.0, 'Climb2 fuel Miss!L9 (zero)');
        end
        function testFuelCruise2(tc)
            % 2% tolerance: known S_wet discrepancy causes ~1.50% deviation
            tc.verifyEqual(tc.miss.fuel_lb(12), 789.4, 'RelTol', 0.02, 'Cruise2 fuel Miss!M9 (2% tol: known S_wet discrepancy)');
        end
        function testFuelLoiter(tc)
            tc.verifyEqual(tc.miss.fuel_lb(13), 488.6, 'RelTol', 0.01, 'Loiter fuel Miss!N9');
        end

        % ── Per-segment times (Miss!B8:N8) ──────────────────────────

        function testTimeTakeoff(tc)
            tc.verifyEqual(tc.miss.time_min(1), 0.223, 'RelTol', 0.01, 'Takeoff time Miss!B8');
        end
        function testTimeAccel(tc)
            tc.verifyEqual(tc.miss.time_min(2), 2.256, 'RelTol', 0.01, 'Accel time Miss!C8');
        end
        function testTimeClimb(tc)
            tc.verifyEqual(tc.miss.time_min(3), 4.508, 'RelTol', 0.02, 'Climb time Miss!D8 (2% tol: S_wet discrepancy)');
        end
        function testTimeCruise(tc)
            tc.verifyEqual(tc.miss.time_min(4), 22.95, 'RelTol', 0.01, 'Cruise time Miss!E8');
        end
        function testTimePatrol(tc)
            tc.verifyEqual(tc.miss.time_min(5), 0.0, 'AbsTol', 0.01, 'Patrol time Miss!F8 (zero)');
        end
        function testTimeDash(tc)
            tc.verifyEqual(tc.miss.time_min(6), 6.017, 'RelTol', 0.01, 'Dash time Miss!G8');
        end
        function testTimePatrol2(tc)
            tc.verifyEqual(tc.miss.time_min(7), 0.0, 'AbsTol', 0.01, 'Patrol2 time Miss!H8 (zero)');
        end
        function testTimeCombat(tc)
            tc.verifyEqual(tc.miss.time_min(8), 2.0, 'AbsTol', 0.01, 'Combat time Miss!I8');
        end
        function testTimeEgress(tc)
            tc.verifyEqual(tc.miss.time_min(9), 6.017, 'RelTol', 0.01, 'Egress time Miss!J8');
        end
        function testTimePatrol3(tc)
            tc.verifyEqual(tc.miss.time_min(10), 0.0, 'AbsTol', 0.01, 'Patrol3 time Miss!K8 (zero)');
        end
        function testTimeClimb2(tc)
            tc.verifyEqual(tc.miss.time_min(11), 0.0, 'AbsTol', 0.01, 'Climb2 time Miss!L8 (zero)');
        end
        function testTimeCruise2(tc)
            tc.verifyEqual(tc.miss.time_min(12), 30.08, 'RelTol', 0.02, 'Cruise2 time Miss!M8 (2% tol: S_wet discrepancy)');
        end
        function testTimeLoiter(tc)
            tc.verifyEqual(tc.miss.time_min(13), 20.0, 'AbsTol', 0.01, 'Loiter time Miss!N8');
        end

        % ── Per-segment weight fractions (Miss!B12:N12) ─────────────

        function testWfracTakeoff(tc)
            tc.verifyEqual(tc.miss.W_Wto(1), 0.9509, 'RelTol', 0.01, 'W/Wto after Takeoff Miss!B12');
        end
        function testWfracAccel(tc)
            tc.verifyEqual(tc.miss.W_Wto(2), 0.9389, 'RelTol', 0.01, 'W/Wto after Accel Miss!C12');
        end
        function testWfracClimb(tc)
            tc.verifyEqual(tc.miss.W_Wto(3), 0.9246, 'RelTol', 0.02, 'W/Wto after Climb Miss!D12 (2% tol)');
        end
        function testWfracCruise(tc)
            tc.verifyEqual(tc.miss.W_Wto(4), 0.8926, 'RelTol', 0.01, 'W/Wto after Cruise Miss!E12');
        end
        function testWfracPatrol(tc)
            tc.verifyEqual(tc.miss.W_Wto(5), 0.8926, 'RelTol', 0.01, 'W/Wto after Patrol Miss!F12');
        end
        function testWfracDash(tc)
            tc.verifyEqual(tc.miss.W_Wto(6), 0.8772, 'RelTol', 0.01, 'W/Wto after Dash Miss!G12');
        end
        function testWfracPatrol2(tc)
            tc.verifyEqual(tc.miss.W_Wto(7), 0.8772, 'RelTol', 0.01, 'W/Wto after Patrol2 Miss!H12');
        end
        function testWfracCombat(tc)
            tc.verifyEqual(tc.miss.W_Wto(8), 0.7190, 'RelTol', 0.01, 'W/Wto after Combat Miss!I12');
        end
        function testWfracEgress(tc)
            tc.verifyEqual(tc.miss.W_Wto(9), 0.7093, 'RelTol', 0.02, 'W/Wto after Egress Miss!J12 (2% tol)');
        end
        function testWfracPatrol3(tc)
            tc.verifyEqual(tc.miss.W_Wto(10), 0.7093, 'RelTol', 0.02, 'W/Wto after Patrol3 Miss!K12 (2% tol)');
        end
        function testWfracClimb2(tc)
            tc.verifyEqual(tc.miss.W_Wto(11), 0.7093, 'RelTol', 0.02, 'W/Wto after Climb2 Miss!L12 (2% tol)');
        end
        function testWfracCruise2(tc)
            tc.verifyEqual(tc.miss.W_Wto(12), 0.6841, 'RelTol', 0.02, 'W/Wto after Cruise2 Miss!M12 (2% tol)');
        end
        function testWfracLoiter(tc)
            tc.verifyEqual(tc.miss.W_Wto(13), 0.6685, 'RelTol', 0.01, 'W/Wto after Loiter Miss!N12');
        end
    end
end
