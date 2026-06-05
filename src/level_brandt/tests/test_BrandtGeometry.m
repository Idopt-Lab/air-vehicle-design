classdef test_BrandtGeometry < matlab.unittest.TestCase
% test_BrandtGeometry  Unit tests for BrandtGeometry.
%
% Source: Brandt-F16-A.xls Geom tab ground-truth cross-checks.
%
% Run all:
%   results = runtests('test_BrandtGeometry');
%   table(results)
%
% Run one method:
%   runtests('test_BrandtGeometry/testWingSwet')

    properties (Access = private)
        geom   % shared BrandtGeometry instance — analyzed once before any test
    end

    methods (TestClassSetup)
        function buildGeometry(tc)
            addpath(level_brandt_test_src_root());
            g = BrandtGeometry();
            g.analyze();
            tc.geom = g;
        end
    end

    % ------------------------------------------------------------------ %
    %  Wetted surface areas  (Geom!B14:B19)                              %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testWingSwet(tc)
            % Geom!B14 = 392.020 ft²
            tc.verifyEqual(tc.geom.S_wet_wing_ft2, 392.020, 'RelTol', 0.02, ...
                'Wing wetted area (Geom!B14)');
        end

        function testStrakeSwet(tc)
            % Geom!B15 = 39.956 ft²
            tc.verifyEqual(tc.geom.S_wet_strake_ft2, 39.956, 'RelTol', 0.02, ...
                'Strake wetted area (Geom!B15)');
        end

        function testPitchCtrlSwet(tc)
            % Geom!B16 = 99.585 ft²
            tc.verifyEqual(tc.geom.S_wet_pitch_ctrl_ft2, 99.585, 'RelTol', 0.02, ...
                'Pitch-control wetted area (Geom!B16)');
        end

        function testVertTailSwet(tc)
            % Geom!B17 = 81.689 ft²
            tc.verifyEqual(tc.geom.S_wet_vert_tail_ft2, 81.689, 'RelTol', 0.02, ...
                'Vertical tail wetted area (Geom!B17)');
        end

        function testNacelleSwet(tc)
            % Geom nacelle GT = 41.515 ft²
            tc.verifyEqual(tc.geom.S_wet_nacelle_gt_ft2, 41.515, 'RelTol', 0.02, ...
                'Nacelle wetted area');
        end

        function testTotalSwet(tc)
            % Excel B19 = 1371.09 ft² double-counts strake (see readme_geom.md).
            % Corrected GT = 1371.09 - 39.956 = 1331.134 ft²
            corrected_gt = 1371.09 - 39.956;
            tc.verifyEqual(tc.geom.S_wet_total_accurate_ft2, corrected_gt, 'RelTol', 0.02, ...
                'Total wetted area (Geom!B19, strake double-count removed)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Aircraft dimensions                                                %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testAircraftLength(tc)
            tc.verifyEqual(tc.geom.aircraft_length_ft, 48.304, 'RelTol', 0.02, ...
                'Aircraft length (ft)');
        end

        function testAmax(tc)
            % Geom!B20 = 25.110 ft²
            tc.verifyEqual(tc.geom.Amax_ft2, 25.110, 'RelTol', 0.02, ...
                'Maximum cross-section area Amax (Geom!B20)');
        end

        function testNacelleLength(tc)
            % L = 4.5 * D, GT = 15.917 ft  (Engn!L_nac)
            tc.verifyEqual(tc.geom.L_engine_ft, 15.917, 'RelTol', 0.02, ...
                'Nacelle length L = 4.5*D (Engn!L_nac)');
        end

        function testNacelleDiameter(tc)
            % D = sqrt(T_AB_SLS / 1900), GT = 3.537 ft  (Engn!D_nac)
            tc.verifyEqual(tc.geom.D_engine_ft, 3.537, 'RelTol', 0.02, ...
                'Nacelle diameter D = sqrt(T_AB_SLS/1900) (Engn!D_nac)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Fuselage frame spot checks                                         %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testFrame1Perimeter(tc)
            % Geom!G50 = 5.178 ft
            tc.verifyEqual(tc.geom.frame_perimeter(1), 5.178, 'RelTol', 0.02, ...
                'Frame 1 perimeter (Geom!G50)');
        end

        function testFrame9FuselageArea(tc)
            % Frame 9 fuselage-only cross-section area; GT from Geom!H218 = 22.572 ft²
            tc.verifyEqual(tc.geom.frame_area(9), 22.572, 'RelTol', 0.02, ...
                'Frame 9 fuselage cross-section area (Geom!H218)');
        end

    end

    % ------------------------------------------------------------------ %
    %  Whole-aircraft cross-sectional areas  (Geom!H26:H45, frames 1-19) %
    %  Tight tolerance: formula is deterministic against the Excel output  %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testCrossSectionalAreas(tc)
            % GT from Geom!H26:H44 (verified via win32com formula inspection).
            % Frame 20 excluded: Excel uses fuselage width = 2.0 ft (F26 bug) while
            % MATLAB uses the correct input width = 7.0 ft from Main row 53.
            gt = [1.8941, 4.4449, 6.8189, 13.2589, 16.8590, 29.2694, 30.2583, 32.5592, ...
                  32.4564, 31.9069, 31.8904, 32.9711, 32.8535, 31.9311, 31.9239, 31.9412, ...
                  31.5840, 31.7828, 18.9914];
            for k = 1:19
                tc.verifyEqual(tc.geom.frame_area_total(k), gt(k), 'RelTol', 0.001, ...
                    sprintf('Frame %d total cross-section area (Geom!H%d)', k, 25 + k));
            end
        end

    end

    % ------------------------------------------------------------------ %
    %  Aircraft volume (Geom!S47)                                         %
    % ------------------------------------------------------------------ %
    methods (Test)

        function testAircraftVolume(tc)
            % Geom!S47 = trapz(C26:C45, H26:H45) = 1106.306 ft³.
            % Frame-20 Excel bug (F26 width 2 ft vs correct 7 ft) adds ~2 ft³;
            % 2% tolerance covers the known discrepancy.
            vol = trapz(tc.geom.inp.fuselage.frame_x, tc.geom.frame_area_total);
            tc.verifyEqual(vol, 1106.306, 'RelTol', 0.02, ...
                'Aircraft volume trapz (Geom!S47) — frame-20 Excel bug causes ~0.2% deviation');
        end

    end

end
