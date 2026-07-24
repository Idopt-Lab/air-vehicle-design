classdef TestMissionProfileImporter < matlab.unittest.TestCase
%TESTMISSIONPROFILEIMPORTER  Unit tests for the generic MissionProfileImporter
%   (reads a mission_profile.json-style file into a struct), exercised
%   against the F-16's examples/F16A/mission_profile.json.
%
%   TIER: unit/correctness -- gates run_all_tests.
%
%   Expected values below are hand-copied LITERALLY from
%   examples/F16A/mission_profile.json's own text (read directly, not
%   produced by calling read_json a second time) -- this test verifies
%   read_json's file-decoding mechanics (does jsondecode correctly parse
%   this schema, including null->NaN conversion for the range/time
%   "not-given" sentinels?), not any computed quantity.

    properties (Constant)
        TOL_TIGHT = 1e-9
    end

    methods (Test)

        function testSegmentNamesMatchJSON(tc)
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            expected = ["Startup", "Taxi", "Takeoff", "Climb", "Cruise", "Dash", "Combat", "Cruise2", "Loiter", "Landing"];
            tc.verifyEqual(string(S.segment_names(:)'), expected);
        end

        function testAltFtAndMachEndMatchJSON(tc)
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            expected_alt  = [0, 0, 0, 40000, 40000, 40000, 25000, 40000, 10000, 0];
            expected_mach = [0, 0, 0.282, 0.87, 0.87, 1.60, 0.80, 0.87, 0.31, 0.3];
            tc.verifyEqual(S.alt_ft(:)', expected_alt, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.mach_end(:)', expected_mach, 'AbsTol', tc.TOL_TIGHT);
        end

        function testDistNmGivenNullsBecomeNaN(tc)
            % JSON: [null, null, null, null, 189.879, 49.968, null, 239.847, null, null].
            % MissionProfileImporter is "deliberately thin" (no atmosphere
            % computation) but DOES rely on jsondecode's null->NaN behavior
            % for range/time "not applicable" sentinels -- F16MissionL1's
            % own total_range_nm_given getter calls sum(...,'omitnan'),
            % which only works if these really do decode to NaN (not [] or
            % a cell array), so this test pins that behavior down explicitly.
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            dist = S.dist_nm_given(:)';
            tc.verifyTrue(isnumeric(dist), 'dist_nm_given must decode to a numeric array, not a cell array.');
            tc.verifyTrue(isnan(dist(1)), 'Startup has no given range -- must decode to NaN.');
            tc.verifyTrue(isnan(dist(2)));
            tc.verifyTrue(isnan(dist(3)));
            tc.verifyTrue(isnan(dist(4)));
            tc.verifyEqual(dist(5), 189.879, 'AbsTol', tc.TOL_TIGHT);   % Cruise
            tc.verifyEqual(dist(6), 49.968,  'AbsTol', tc.TOL_TIGHT);   % Dash
            tc.verifyTrue(isnan(dist(7)));                              % Combat (time-given, not range)
            tc.verifyEqual(dist(8), 239.847, 'AbsTol', tc.TOL_TIGHT);   % Cruise2
            tc.verifyTrue(isnan(dist(9)));
            tc.verifyTrue(isnan(dist(10)));
        end

        function testTimeMinGivenNullsBecomeNaN(tc)
            % JSON: [null, null, null, null, null, null, 2.0, null, 20.0, null].
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            t = S.time_min_given(:)';
            tc.verifyTrue(isnan(t(1)));
            tc.verifyTrue(isnan(t(5)));   % Cruise (range-given, not time)
            tc.verifyEqual(t(7), 2.0, 'AbsTol', tc.TOL_TIGHT);    % Combat
            tc.verifyEqual(t(9), 20.0, 'AbsTol', tc.TOL_TIGHT);   % Loiter
            tc.verifyTrue(isnan(t(10)));
        end

        function testDropLbAndDryOrWetMatchJSON(tc)
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            expected_drop = [0, 0, 0, 0, 0, 0, 4400, 0, 0, 0];
            expected_dow  = ["Dry","Dry","Dry","Dry","Dry","Wet","Wet","Dry","Dry","Dry"];
            tc.verifyEqual(S.drop_lb(:)', expected_drop, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(string(S.dry_or_wet(:)'), expected_dow);
        end

        function testScalarSpecConstantsMatchJSON(tc)
            S = MissionProfileImporter.read_json(TestMissionProfileImporter.jsonPath());
            tc.verifyEqual(S.CLmax_TO, 1.2757, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.CLmax_land, 1.4259, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.mu_rolling, 0.03, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.liftoff_factor, 1.2, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.warmup_fuel_per_engine_lb, 1000.0, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(S.RFF, 0.06, 'AbsTol', tc.TOL_TIGHT);
        end

        function testFileNotFoundErrors(tc)
            bogus = fullfile(fileparts(TestMissionProfileImporter.jsonPath()), 'does_not_exist_mission_profile.json');
            tc.verifyError(@() MissionProfileImporter.read_json(bogus), 'MissionProfileImporter:fileNotFound');
        end

        function testReadExcelIsAnExplicitlyFlaggedStub(tc)
            % read_excel is documented as a deliberate not-yet-implemented
            % stub (see MissionProfileImporter.m header) -- verify it errors
            % clearly rather than silently returning empty/wrong data.
            tc.verifyError(@() MissionProfileImporter.read_excel(TestMissionProfileImporter.jsonPath(), "CAP"), ...
                'MissionProfileImporter:notImplemented');
        end

    end

    methods (Static, Access = private)

        function p = jsonPath()
            p = fullfile(fileparts(mfilename('fullpath')), '..', '..', ...
                'examples', 'F16A', 'mission_profile.json');
        end

    end

end
