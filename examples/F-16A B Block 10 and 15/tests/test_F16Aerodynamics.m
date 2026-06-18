classdef test_F16Aerodynamics < matlab.unittest.TestCase
    % V&V tests for F-16 aerodynamics discipline objects.
    %
    % Brandt reference values (f16a_geometry.json / Brandt-F16-A.xls Aero tab):
    %   CD0 (Miss tab, mission-effective) = 0.0270
    %   CD0 (Aero tab, CDmin subsonic)   = 0.0170
    %   K2                               = 0.1160
    %   K1                               = -0.00630
    %   CLmax clean                      = 0.984
    %   CLmax takeoff                    = 1.276
    %   CLmax landing                    = 1.426
    %   L/D_max                          ~ 8.9

    properties
        geom_json
        CD0_miss   = 0.0270   % effective mission CD0
        CD0_aero   = 0.0170   % clean CDmin
        K2_brandt  = 0.1160
        CLmax_clean = 0.984
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

        % ---- Level I ----

        function testL1_drag_polar_hasRequiredFields(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyTrue(isfield(polar, 'CD0'), 'polar must have CD0');
            tc.verifyTrue(isfield(polar, 'K1'),  'polar must have K1');
            tc.verifyTrue(isfield(polar, 'K2'),  'polar must have K2');
        end

        function testL1_CD0_positive(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive');
        end

        function testL1_K2_positive(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.K2, 0, 'K2 must be positive');
        end

        function testL1_K1_zero(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyEqual(polar.K1, 0, 'K1 must be 0 at L1 (symmetric polar)');
        end

        function testL1_CD0_within40pct_of_Brandt(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.CD0, 0.0270 * 0.6,   'L1 CD0 lower bound');
            tc.verifyLessThan(polar.CD0,    0.0270 * 1.4,   'L1 CD0 upper bound');
        end

        function testL1_K2_within40pct_of_Brandt(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.K2, tc.K2_brandt * 0.6,  'L1 K2 lower bound');
            tc.verifyLessThan(polar.K2,    tc.K2_brandt * 1.4,  'L1 K2 upper bound');
        end

        function testL1_CLmax_clean_range(tc)
            aero  = F16AeroLevel1(tc.geom_json);
            state = AircraftState(0, 0.3);
            CL    = aero.CLmax(state);
            tc.verifyGreaterThan(CL, 0.8,  'CLmax clean lower bound');
            tc.verifyLessThan(CL,    2.0,  'CLmax clean upper bound (Roskam range)');
        end

        % ---- Level II ----

        function testL2_drag_polar_hasRequiredFields(tc)
            aero  = F16AeroLevel2(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyTrue(isfield(polar, 'CD0'));
            tc.verifyTrue(isfield(polar, 'K1'));
            tc.verifyTrue(isfield(polar, 'K2'));
        end

        function testL2_CD0_within30pct_of_Brandt(tc)
            aero  = F16AeroLevel2(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.CD0, 0.0270 * 0.70, 'L2 CD0 lower bound');
            tc.verifyLessThan(polar.CD0,    0.0270 * 1.30, 'L2 CD0 upper bound');
        end

        function testL2_K2_within20pct_of_Brandt(tc)
            aero  = F16AeroLevel2(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.K2, tc.K2_brandt * 0.80);
            tc.verifyLessThan(polar.K2,    tc.K2_brandt * 1.20);
        end

        function testL2_K1_zero(tc)
            aero  = F16AeroLevel2(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyEqual(polar.K1, 0, 'K1 must be 0 at L2 (symmetric polar)');
        end

        function testL2_LDmax_reasonable(tc)
            aero  = F16AeroLevel2(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            LD_max = 1 / (2 * sqrt(polar.CD0 * polar.K2));
            tc.verifyGreaterThan(LD_max, 6,  'L/D_max must be > 6');
            tc.verifyLessThan(LD_max,    14, 'L/D_max must be < 14');
        end

        % ---- Level III ----

        function testL3_drag_polar_positive(tc)
            aero  = F16AeroLevel3(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            tc.verifyGreaterThan(polar.CD0, 0);
            tc.verifyGreaterThan(polar.K2,  0);
        end

        function testL3_CD0_near_CDmin(tc)
            aero  = F16AeroLevel3(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            % L3 component buildup gives CDmin (Aero tab ≈ 0.0170), not mission CD0
            tc.verifyGreaterThan(polar.CD0, 0.010, 'L3 CD0 too low');
            tc.verifyLessThan(polar.CD0,    0.030, 'L3 CD0 too high');
        end

        function testL3_K1_possibly_nonzero(tc)
            aero  = F16AeroLevel3(tc.geom_json);
            state = AircraftState(40000, 0.87);
            polar = aero.drag_polar(state);
            % K1 should be non-zero for a cambered airfoil at L3
            % (just verify it is a finite real number — sign depends on implementation)
            tc.verifyTrue(isfinite(polar.K1), 'K1 must be finite at L3');
        end

        % ---- Cross-level consistency ----

        function testPolarIsConsistentAcrossLevels(tc)
            state = AircraftState(40000, 0.87);
            p1 = F16AeroLevel1(tc.geom_json).drag_polar(state);
            p2 = F16AeroLevel2(tc.geom_json).drag_polar(state);
            p3 = F16AeroLevel3(tc.geom_json).drag_polar(state);
            % L1 and L2 use the same mission-effective CD0 basis → should agree within 50%
            tc.verifyLessThan(abs(p1.CD0 - p2.CD0) / p2.CD0, 0.5, ...
                'L1 and L2 CD0 should agree within 50%');
            % L3 computes clean CDmin; L2 uses mission-effective CD0.
            % These represent different physical quantities by design — just verify
            % L3 CD0 is a positive, physically plausible CDmin value.
            tc.verifyGreaterThan(p3.CD0, 0.008, 'L3 CDmin must be > 0.008');
            tc.verifyLessThan(p3.CD0,    0.030, 'L3 CDmin must be < 0.030');
        end

    end

    methods (TestClassTeardown)
        function printComparisonTable(tc) %#ok<MANU>
            fprintf('\n%s\n', repmat('=',1,70));
            fprintf('  F-16 Aerodynamics V&V — Comparison to Brandt\n');
            fprintf('%s\n', repmat('=',1,70));
            fprintf('%-30s %10s %10s %10s\n', 'Quantity', 'Brandt', 'L1 (tol)', 'L2 (tol)');
            fprintf('%s\n', repmat('-',1,70));
            fprintf('%-30s %10.4f %10s %10s\n', 'CD0 (mission, Miss tab)', 0.0270, '±40%', '±30%');
            fprintf('%-30s %10.4f %10s %10s\n', 'CD0 (clean, Aero tab)',  0.0170, 'N/A', 'N/A');
            fprintf('%-30s %10.4f %10s %10s\n', 'K2',                     0.1160, '±40%', '±20%');
            fprintf('%-30s %10.4f %10s %10s\n', 'K1',                    -0.0063, '= 0', '= 0');
            fprintf('%-30s %10.3f %10s %10s\n', 'CLmax clean',            0.984,  '[0.8,2.0]', 'N/A');
            fprintf('%s\n', repmat('=',1,70));
        end
    end

end
