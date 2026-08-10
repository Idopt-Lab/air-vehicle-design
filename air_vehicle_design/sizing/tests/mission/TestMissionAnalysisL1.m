classdef TestMissionAnalysisL1 < matlab.unittest.TestCase
%TESTMISSIONANALYSISL1  Unit tests for the L1 mission aggregator.
%   Builds the CAP profile from the requirements JSON with fixed stub
%   disciplines (so the numbers are deterministic) and checks the assembly,
%   the type->class map, the start-condition threading, the weight-threading +
%   payload-drop bookkeeping, the raw-burn/reserve aggregation, and the
%   sizing-loop compute_fuel compatibility shim. Unit tier.

    properties (Constant)
        TOL = 1e-9;
        W_TO = 31377;
    end

    methods (Access = private)
        function m = buildCap(tc) %#ok<MANU>
            m = MissionAnalysisL1.from_requirements( ...
                MissionStubAero(), MissionStubProp(), MissionStubGeom(), ...
                f16a_requirements_path(), "cap");
        end
    end

    methods (Test)

        function testAssemblesTenSegmentsWithRightClasses(tc)
            m = tc.buildCap();
            tc.verifyEqual(numel(m.segments), 10);
            tc.verifyClass(m.segments{1},  'FixedFractionSegment');   % Startup
            tc.verifyClass(m.segments{3},  'FixedFractionSegment');   % Takeoff
            tc.verifyClass(m.segments{4},  'FixedFractionSegment');   % Climb
            tc.verifyClass(m.segments{5},  'BreguetRangeSegment');    % Cruise
            tc.verifyClass(m.segments{6},  'BreguetRangeSegment');    % Dash
            tc.verifyClass(m.segments{7},  'BreguetEnduranceSegment');% Combat
            tc.verifyClass(m.segments{9},  'BreguetEnduranceSegment');% Loiter
            tc.verifyClass(m.segments{10}, 'FixedFractionSegment');   % Landing
        end

        function testStartConditionThreading(tc)
            m = tc.buildCap();
            % Climb (seg4) starts at Takeoff's end: mach 0.282, alt 0.
            tc.verifyEqual(m.segments{4}.mach_start, 0.282, 'RelTol', tc.TOL);
            tc.verifyEqual(m.segments{4}.alt_start_ft, 0, 'AbsTol', tc.TOL);
            % Cruise (seg5) starts at Climb's end: mach 0.87, alt 40000.
            tc.verifyEqual(m.segments{5}.mach_start, 0.87, 'RelTol', tc.TOL);
            tc.verifyEqual(m.segments{5}.alt_start_ft, 40000, 'RelTol', tc.TOL);
        end

        function testRawBurnEqualsSumOfSegmentFuel(tc)
            m = tc.buildCap();
            [~, bd] = m.total_fuel(tc.W_TO);
            tc.verifyEqual(bd.raw_burn, sum(bd.fuel_lbf), 'RelTol', tc.TOL);
        end

        function testReserveMarkup(tc)
            m = tc.buildCap();
            [Wf, bd] = m.total_fuel(tc.W_TO);
            tc.verifyEqual(Wf, bd.raw_burn * 1.06, 'RelTol', tc.TOL);   % 6% reserve
        end

        function testWeightThreadingAndCombatDrop(tc)
            m = tc.buildCap();
            [~, bd] = m.total_fuel(tc.W_TO);
            % Combat is segment 7 and drops 4400 lb payload.
            W_before_combat = bd.W_after(6);
            tc.verifyEqual(bd.W_after(7), ...
                W_before_combat - bd.fuel_lbf(7) - 4400, 'RelTol', tc.TOL);
            % Every other segment: W_after = W_before - fuel (no drop).
            tc.verifyEqual(bd.W_after(5), bd.W_after(4) - bd.fuel_lbf(5), 'RelTol', tc.TOL);
        end

        function testWeightMonotonicallyDecreases(tc)
            m = tc.buildCap();
            [~, bd] = m.total_fuel(tc.W_TO);
            tc.verifyLessThan(bd.W_after(1), tc.W_TO);
            tc.verifyTrue(all(diff([tc.W_TO, bd.W_after]) < 0));
        end

        function testComputeFuelShimMatchesTotalFuel(tc)
            m = tc.buildCap();
            Wf = m.total_fuel(tc.W_TO);
            % compute_fuel accepts (aero, prop, W_TO) for sizing-loop compat and
            % uses the injected handles; the passed [] are ignored.
            tc.verifyEqual(m.compute_fuel([], [], tc.W_TO), Wf, 'RelTol', tc.TOL);
        end

        function testUnknownSegmentTypeErrors(tc)
            % accel/patrol/egress are L2-only -> L1 build_segment must reject them.
            tc.verifyError(@() MissionAnalysisL1.build_segment(struct('type', "accel")), ...
                'MissionAnalysisL1:unknownSegmentType');
        end

    end
end
