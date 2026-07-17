classdef TestAircraftState < matlab.unittest.TestCase
%TESTAIRCRAFTSTATE  Unit tests for AircraftState.
%
%   Reference values from:
%     Mattingly, "Aircraft Engine Design" 2nd ed., AIAA, 2002,
%     Appendix B (standard atmosphere tables).

    methods (Test)

        % -------------------------------------------------------------- %
        function testSeaLevelStaticTemperature(tc)
            s = AircraftState(0, 0);
            % ISA SL: T = 288.15 K = 518.67 deg R
            tc.verifyEqual(s.T_atm, 518.67, 'AbsTol', 0.10, ...
                'Sea-level static temperature outside ISA tolerance.');
        end

        function testSeaLevelStaticPressure(tc)
            s = AircraftState(0, 0);
            % ISA SL: P = 101325 Pa = 2116.22 lbf/ft^2
            tc.verifyEqual(s.P_atm, 2116.22, 'AbsTol', 0.5, ...
                'Sea-level static pressure outside ISA tolerance.');
        end

        function testSeaLevelDensity(tc)
            s = AircraftState(0, 0);
            % ISA SL: rho = 1.225 kg/m^3 = 0.002377 slug/ft^3
            tc.verifyEqual(s.rho, 0.002377, 'AbsTol', 1e-5, ...
                'Sea-level density outside ISA tolerance.');
        end

        function testSeaLevelSpeedOfSound(tc)
            s = AircraftState(0, 0);
            % ISA SL: a = 340.29 m/s = 1116.45 ft/s
            tc.verifyEqual(s.a, 1116.45, 'AbsTol', 0.5, ...
                'Sea-level speed of sound outside ISA tolerance.');
        end

        function testSeaLevelStaticVelocityAndDynPressure(tc)
            s = AircraftState(0, 0);
            % M=0 → V=0, q=0
            tc.verifyEqual(s.V, 0, 'AbsTol', 1e-10);
            tc.verifyEqual(s.q, 0, 'AbsTol', 1e-10);
        end

        % -------------------------------------------------------------- %
        function testSLThetaDelta(tc)
            s = AircraftState(0, 0);
            % At SLS: theta=1, delta=1, theta_0=1, delta_0=1
            tc.verifyEqual(s.theta,   1.0, 'AbsTol', 1e-3);
            tc.verifyEqual(s.delta,   1.0, 'AbsTol', 1e-3);
            tc.verifyEqual(s.theta_0, 1.0, 'AbsTol', 1e-3);
            tc.verifyEqual(s.delta_0, 1.0, 'AbsTol', 1e-3);
        end

        % -------------------------------------------------------------- %
        function testTropopauseThetaDelta(tc)
            % At 36,000 ft: Mattingly App B gives theta=0.7529, delta=0.2250
            s = AircraftState(36000, 0);
            tc.verifyEqual(s.theta, 0.7529, 'AbsTol', 0.003, ...
                'theta at 36 kft deviates from Mattingly Appendix B.');
            tc.verifyEqual(s.delta, 0.2250, 'AbsTol', 0.003, ...
                'delta at 36 kft deviates from Mattingly Appendix B.');
        end

        % -------------------------------------------------------------- %
        function testTheta0Delta0AtSupersonic(tc)
            % At 30,000 ft, M=1.5:
            %   Mattingly App B: theta=0.7940, delta=0.2975
            %   theta_0 = 0.7940*(1+0.2*1.5^2) = 0.7940*1.45 = 1.1513
            %   delta_0 = 0.2975*(1+0.2*1.5^2)^3.5 = 0.2975*3.671 = 1.0921
            s = AircraftState(30000, 1.5);
            tc.verifyEqual(s.theta_0, 1.1513, 'AbsTol', 0.015, ...
                'theta_0 at 30 kft M=1.5 deviates from Mattingly App B.');
            tc.verifyEqual(s.delta_0, 1.0921, 'AbsTol', 0.025, ...
                'delta_0 at 30 kft M=1.5 deviates from Mattingly App B.');
        end

        % -------------------------------------------------------------- %
        function testCruiseDynamicPressure(tc)
            % F-16 nominal cruise: 36,000 ft, M=0.87
            % At tropopause a ≈ 968 ft/s, V ≈ 842 ft/s, rho ≈ 0.000706 slug/ft^3
            % q = 0.5*0.000706*842^2 ≈ 250 lbf/ft^2 (order of magnitude check)
            s = AircraftState(36000, 0.87);
            tc.verifyGreaterThan(s.q, 150,  'q too low at cruise.');
            tc.verifyLessThan(s.q,    500,  'q too high at cruise.');
        end

        % -------------------------------------------------------------- %
        function testDynamicPressureFormula(tc)
            % Verify q = 0.5*rho*V^2 for arbitrary condition
            s = AircraftState(20000, 0.6);
            expected_q = 0.5 * s.rho * s.V^2;
            tc.verifyEqual(s.q, expected_q, 'AbsTol', 1e-8);
        end

        function testVelocityFormula(tc)
            % Verify V = mach * a
            s = AircraftState(15000, 0.8);
            tc.verifyEqual(s.V, s.mach * s.a, 'AbsTol', 1e-8);
        end

        function testTheta0Formula(tc)
            % Verify theta_0 = theta*(1 + 0.2*M^2)
            s = AircraftState(25000, 1.2);
            expected = s.theta * (1 + 0.2 * s.mach^2);
            tc.verifyEqual(s.theta_0, expected, 'AbsTol', 1e-10);
        end

        function testDelta0Formula(tc)
            % Verify delta_0 = delta*(1 + 0.2*M^2)^3.5
            s = AircraftState(25000, 1.2);
            expected = s.delta * (1 + 0.2 * s.mach^2)^3.5;
            tc.verifyEqual(s.delta_0, expected, 'AbsTol', 1e-10);
        end

        % -------------------------------------------------------------- %
        function testNegativeAltitudeRejected(tc)
            tc.verifyError(@() AircraftState(-1, 0), ?MException);
        end

        function testNegativeMachRejected(tc)
            tc.verifyError(@() AircraftState(0, -0.1), ?MException);
        end

        % -------------------------------------------------------------- %
        function testAltitudeAndMachStored(tc)
            s = AircraftState(10000, 0.5);
            tc.verifyEqual(s.altitude_ft, 10000);
            tc.verifyEqual(s.mach, 0.5);
        end

        function testIsValueClass(tc)
            % Copy should be independent (value semantics)
            s1 = AircraftState(0, 0);
            s2 = s1;
            tc.verifyEqual(s1.T_atm, s2.T_atm);
            tc.verifyFalse(isa(s1, 'handle'));
        end

    end
end
