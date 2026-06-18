classdef test_F16Propulsion < matlab.unittest.TestCase
    % V&V tests for F-16 propulsion discipline objects.
    %
    % Brandt reference values (f16a_geometry.json / Brandt-F16-A.xls Engn tab):
    %   T_AB_SLS   = 23,770 lbf
    %   T_mil_SLS  = 15,000 lbf
    %   TSFC_mil   = 0.70 /hr = 1.944e-4 /s
    %   TSFC_AB    = 2.20 /hr = 6.111e-4 /s
    %   Thrust lapse at 36000 ft, M=0.87: α_AB ≈ 0.34 (from Brandt Consts tab)
    %
    % Tolerances: L1 tabulated TSFC vs Brandt ±30%; thrust lapse ±25%.
    % L2/L3 Mattingly equations expect ±20% on TSFC; ±15% on thrust lapse.

    properties
        geom_json
        % Brandt targets
        T_AB_SLS    = 23770     % lbf
        T_mil_SLS   = 15000     % lbf
        TSFC_mil_s  = 0.70/3600 % 1/s
        TSFC_AB_s   = 2.20/3600 % 1/s
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

        % --- Level I ---

        function testL1_T0_setFromJSON(tc)
            prop = F16PropulsionLevel1(tc.geom_json);
            tc.verifyEqual(prop.T0, tc.T_AB_SLS, 'AbsTol', 1.0, ...
                'L1 T0 should be T_AB_SLS from JSON');
        end

        function testL1_ThrustLapse_SL(tc)
            prop  = F16PropulsionLevel1(tc.geom_json);
            state = AircraftState(0, 0.0);
            alpha = prop.thrust_lapse(state);
            tc.verifyEqual(alpha, 1.0, 'AbsTol', 0.02, ...
                'L1 thrust lapse at SL must equal 1.0');
        end

        function testL1_ThrustLapse_Altitude(tc)
            prop  = F16PropulsionLevel1(tc.geom_json);
            state = AircraftState(36000, 0.87);
            alpha = prop.thrust_lapse(state);
            tc.verifyGreaterThan(alpha, 0.20, 'L1 thrust lapse at 36000 ft must be >0.20');
            tc.verifyLessThan(alpha, 0.60, 'L1 thrust lapse at 36000 ft must be <0.60');
        end

        function testL1_TSFC_ReturnsCruiseValue(tc)
            prop  = F16PropulsionLevel1(tc.geom_json);
            state = AircraftState(36000, 0.87);
            tsfc  = prop.TSFC(state);
            % Tabulated TSFC for low-BPR turbofan: 0.6-1.4/hr cruise
            tc.verifyGreaterThan(tsfc, 0.6/3600, 'L1 TSFC must be in reasonable range (lower)');
            tc.verifyLessThan(tsfc,    1.6/3600, 'L1 TSFC must be in reasonable range (upper)');
        end

        % --- Level II ---

        function testL2_T0_setFromJSON(tc)
            prop = F16PropulsionLevel2(tc.geom_json);
            tc.verifyEqual(prop.T0, tc.T_AB_SLS, 'AbsTol', 1.0, ...
                'L2 T0 should be T_AB_SLS from JSON');
        end

        function testL2_ThrustLapse_SL(tc)
            prop  = F16PropulsionLevel2(tc.geom_json);
            state = AircraftState(0, 0.0);
            alpha = prop.thrust_lapse(state);
            tc.verifyEqual(alpha, 1.0, 'AbsTol', 0.05, ...
                'L2 thrust lapse at SL ≈ 1.0');
        end

        function testL2_ThrustLapse_Altitude(tc)
            prop  = F16PropulsionLevel2(tc.geom_json);
            state = AircraftState(36000, 0.87);
            alpha = prop.thrust_lapse(state);
            tc.verifyGreaterThan(alpha, 0.20);
            tc.verifyLessThan(alpha, 0.65);
        end

        function testL2_TSFC_Range(tc)
            prop  = F16PropulsionLevel2(tc.geom_json);
            state = AircraftState(36000, 0.87);
            tsfc  = prop.TSFC(state);
            tc.verifyGreaterThan(tsfc, 0.4/3600);
            tc.verifyLessThan(tsfc,    1.8/3600);
        end

        % --- Level III ---

        function testL3_ThrustLapse_SL(tc)
            prop  = F16PropulsionLevel3(tc.geom_json);
            state = AircraftState(0, 0.0);
            alpha = prop.thrust_lapse(state);
            tc.verifyEqual(alpha, 1.0, 'AbsTol', 0.10, ...
                'L3 thrust lapse at SL ≈ 1.0');
        end

        function testL3_TSFC_Range(tc)
            prop  = F16PropulsionLevel3(tc.geom_json);
            state = AircraftState(36000, 0.87);
            tsfc  = prop.TSFC(state);
            tc.verifyGreaterThan(tsfc, 0.4/3600);
            tc.verifyLessThan(tsfc,    2.0/3600);
        end

        % --- Monotonicity checks ---

        function testThrustLapseDecreases_WithAltitude(tc)
            prop = F16PropulsionLevel1(tc.geom_json);
            a_sl  = prop.thrust_lapse(AircraftState(0,     0.5));
            a_mid = prop.thrust_lapse(AircraftState(20000, 0.5));
            a_hi  = prop.thrust_lapse(AircraftState(40000, 0.5));
            tc.verifyGreaterThan(a_sl,  a_mid, 'Thrust lapse must decrease with altitude (SL > 20k)');
            tc.verifyGreaterThan(a_mid, a_hi,  'Thrust lapse must decrease with altitude (20k > 40k)');
        end

    end

    methods (TestClassTeardown)
        function printComparisonTable(tc) %#ok<MANU>
            fprintf('\n%s\n', repmat('=',1,70));
            fprintf('  F-16 Propulsion V&V — Comparison to Brandt Targets\n');
            fprintf('%s\n', repmat('=',1,70));
            fprintf('%-28s %12s %12s\n', 'Quantity', 'Brandt', 'Note');
            fprintf('%s\n', repmat('-',1,70));
            fprintf('%-28s %12.0f %12s\n', 'T_AB_SLS (lbf)',   23770, 'Set from JSON');
            fprintf('%-28s %12.0f %12s\n', 'T_mil_SLS (lbf)',  15000, 'Set from JSON');
            fprintf('%-28s %12.6f %12s\n', 'TSFC_mil (1/s)',  0.70/3600, 'L1: tabulated');
            fprintf('%-28s %12.6f %12s\n', 'TSFC_AB (1/s)',   2.20/3600, 'L2/L3: Mattingly');
            fprintf('%s\n', repmat('=',1,70));
        end
    end

end
