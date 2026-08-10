classdef TestMissionAnalysisL2 < matlab.unittest.TestCase
%TESTMISSIONANALYSISL2  Unit tests for the L2 mission aggregator.
%   Builds both the CAP (10-seg) and Brandt (14-seg) profiles with fixed stub
%   disciplines and checks the type->class map, the Roskam fallback, the
%   ground-fuel double-count guard, the zero-fuel patrol legs, the weight /
%   payload-drop threading, and the raw-burn/reserve aggregation. Unit tier.

    properties (Constant)
        TOL = 1e-9;
        W_TO = 31377;
    end

    methods (Access = private)
        function m = build(tc, profile) %#ok<INUSD>
            m = MissionAnalysisL2.from_requirements( ...
                MissionStubAero(), MissionStubProp(), MissionStubGeom(), ...
                f16a_requirements_path(), profile);
        end
        function seg = findByName(~, m, nm)
            seg = [];
            for i = 1:numel(m.segments)
                if m.segments{i}.name == nm
                    seg = m.segments{i};
                    return
                end
            end
        end
    end

    methods (Test)

        function testCapClassMap(tc)
            m = tc.build("cap");
            tc.verifyEqual(numel(m.segments), 10);
            tc.verifyClass(m.segments{1},  'FixedFractionSegment');  % Startup
            tc.verifyClass(m.segments{3},  'TakeoffSegment');        % Takeoff
            tc.verifyClass(m.segments{4},  'ClimbSegment');          % Climb
            tc.verifyClass(m.segments{5},  'CruiseSegment');         % Cruise
            tc.verifyClass(m.segments{7},  'CombatSegment');         % Combat
            tc.verifyClass(m.segments{9},  'LoiterSegment');         % Loiter
            tc.verifyClass(m.segments{10}, 'FixedFractionSegment');  % Landing
        end

        function testBrandtClassMap(tc)
            m = tc.build("brandt_14seg");
            tc.verifyEqual(numel(m.segments), 14);
            tc.verifyClass(tc.findByName(m, "Accel"),   'ClimbSegment');   % Ps-based
            tc.verifyClass(tc.findByName(m, "Patrol"),  'LoiterSegment');  % time-given
            tc.verifyClass(tc.findByName(m, "Egress"),  'CruiseSegment');  % distance-given
            tc.verifyClass(tc.findByName(m, "Climb2"),  'ClimbSegment');
        end

        function testDoubleCountGuardCap(tc)
            % CAP has explicit Startup/Taxi -> takeoff must NOT re-add warmup/start.
            m = tc.build("cap");
            tk = tc.findByName(m, "Takeoff");
            tc.verifyFalse(tk.include_warmup_start);
        end

        function testDoubleCountGuardBrandt(tc)
            % Brandt-14 has no Startup/Taxi -> takeoff keeps warmup/start.
            m = tc.build("brandt_14seg");
            tk = tc.findByName(m, "Takeoff");
            tc.verifyTrue(tk.include_warmup_start);
        end

        function testPatrolLegsBurnZero(tc)
            m = tc.build("brandt_14seg");
            [~, bd] = m.total_fuel(tc.W_TO);
            for nm = ["Patrol", "Patrol2", "Patrol3"]
                idx = find(bd.names == nm, 1);
                tc.verifyEqual(bd.fuel_lbf(idx), 0, 'AbsTol', 1e-6, ...
                    sprintf('%s should burn ~0 fuel', nm));
            end
        end

        function testRawBurnAndReserve(tc)
            m = tc.build("cap");
            [Wf, bd] = m.total_fuel(tc.W_TO);
            tc.verifyEqual(bd.raw_burn, sum(bd.fuel_lbf), 'RelTol', tc.TOL);
            tc.verifyEqual(Wf, bd.raw_burn * 1.06, 'RelTol', tc.TOL);
        end

        function testCombatDropThreading(tc)
            m = tc.build("brandt_14seg");
            [~, bd] = m.total_fuel(tc.W_TO);
            i = find(bd.names == "Combat", 1);
            tc.verifyEqual(bd.W_after(i), bd.W_after(i-1) - bd.fuel_lbf(i) - 4400, ...
                'RelTol', tc.TOL);
        end

        function testEverySegmentBurnsNonNegativeAndTotalPositive(tc)
            m = tc.build("brandt_14seg");
            [~, bd] = m.total_fuel(tc.W_TO);
            tc.verifyTrue(all(bd.fuel_lbf >= 0));
            tc.verifyGreaterThan(bd.raw_burn, 0);
        end

        function testUnknownSegmentTypeErrors(tc)
            tc.verifyError(@() MissionAnalysisL2.build_segment(struct('type', "hover")), ...
                'MissionAnalysisL2:unknownSegmentType');
        end

    end
end
