classdef TestMissionProfileReader < matlab.unittest.TestCase
%TESTMISSIONPROFILEREADER  Unit tests for MissionProfileReader.read_profile.
%
%   Verifies the reader decodes the two mission profiles in
%   examples/F16A/jsons/f16a_requirements.json (.missions block) into the
%   expected ordered segment struct arrays + mission-level scalars, and that it
%   errors clearly on a missing profile / file / segment type.
%
%   Expected values are hand-copied from the JSON (the CAP profile mirrors the
%   retired mission_profile.json; the Brandt-14 profile mirrors
%   VnV/BrandtF16A/GroundTruth/f16a_geometry.json .mission). This is a unit test
%   (gate run_all_tests), not the informational Brandt comparison report.

    properties (Constant)
        CAP_TYPES = ["startup" "taxi" "takeoff" "climb" "cruise" "dash" ...
                     "combat" "cruise" "loiter" "landing"];
        BRANDT_TYPES = ["takeoff" "accel" "climb" "cruise" "patrol" "dash" ...
                        "patrol" "combat" "egress" "patrol" "climb" "cruise" ...
                        "loiter" "landing"];
    end

    methods (Test)

        function testCapSegmentCountAndOrder(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "cap");
            tc.verifyEqual(numel(p.segments), 10);
            types = string({p.segments.type});
            tc.verifyEqual(types, tc.CAP_TYPES);
            tc.verifyEqual(p.name, "cap");
        end

        function testCapScalars(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "cap");
            tc.verifyEqual(p.warmup_fuel_per_engine_lb, 1000.0);
            tc.verifyEqual(p.reserve_fuel_fraction, 0.06);
            tc.verifyEqual(p.mu_rolling, 0.03);
            tc.verifyEqual(p.mu_braking, 0.5);
            tc.verifyEqual(p.liftoff_factor, 1.2);
            tc.verifyEqual(p.approach_factor, 1.3);
        end

        function testCapCruiseSegment(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "cap");
            s = p.segments(5);   % Cruise
            tc.verifyEqual(string(s.name), "Cruise");
            tc.verifyEqual(s.alt_ft, 40000);
            tc.verifyEqual(s.mach_end, 0.87);
            tc.verifyEqual(s.distance_nm, 189.879);
        end

        function testCapCombatSegment(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "cap");
            s = p.segments(7);   % Combat
            tc.verifyEqual(string(s.name), "Combat");
            tc.verifyEqual(s.time_min, 2.0);
            tc.verifyEqual(s.drop_lb, 4400);
            tc.verifyEqual(s.percent_ab, 100);
        end

        function testCapStartupHasNoFlightCondition(tc)
            % A segment that omits an optional key comes back with that key
            % present-but-empty (union-of-fields struct array); callers must
            % test isfield + ~isempty, which this documents.
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "cap");
            s = p.segments(1);   % Startup -- no alt_ft/mach_end in the JSON
            tc.verifyTrue(~isfield(s, 'alt_ft') || isempty(s.alt_ft));
        end

        function testBrandtSegmentCountAndOrder(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "brandt_14seg");
            tc.verifyEqual(numel(p.segments), 14);
            types = string({p.segments.type});
            tc.verifyEqual(types, tc.BRANDT_TYPES);
        end

        function testBrandtCruiseCd0Increment(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "brandt_14seg");
            s = p.segments(4);   % Cruise
            tc.verifyEqual(s.distance_nm, 190.8);
            tc.verifyEqual(s.cd0_increment, 0.010);
        end

        function testBrandtEgressHasNoCd0Increment(tc)
            % Egress onward carry no cd0_increment (Brandt CDx = 0 there).
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "brandt_14seg");
            s = p.segments(9);   % Egress
            tc.verifyEqual(string(s.name), "Egress");
            tc.verifyTrue(~isfield(s, 'cd0_increment') || isempty(s.cd0_increment));
        end

        function testBrandtCombatDropAndAB(tc)
            p = MissionProfileReader.read_profile(f16a_requirements_path(), "brandt_14seg");
            s = p.segments(8);   % Combat
            tc.verifyEqual(s.time_min, 2.0);
            tc.verifyEqual(s.drop_lb, 4400);
            tc.verifyEqual(s.percent_ab, 50);
        end

        function testProfileNotFoundErrors(tc)
            tc.verifyError(@() MissionProfileReader.read_profile(f16a_requirements_path(), "nope"), ...
                'MissionProfileReader:profileNotFound');
        end

        function testFileNotFoundErrors(tc)
            tc.verifyError(@() MissionProfileReader.read_profile("no_such_file_xyz.json", "cap"), ...
                'MissionProfileReader:fileNotFound');
        end

    end

end
