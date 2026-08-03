classdef TestMissionL2 < matlab.unittest.TestCase
%TESTMISSIONL2  Unit tests for the MissionL2 static toolbox and the
%   F16MissionL2 concrete (Tier-3) class.
%
%   TIER: unit/correctness -- gates run_all_tests. No deliberately-failing
%   TODO tests in this file.
%
%   L2 replaces L1's Table 2.2 lookups with REAL aero_obj.drag_polar(state)/
%   prop_obj.get_TSFC(state)/compute_TSFC_AB(state) calls for Cruise/Dash/
%   Combat/Loiter, still using MissionL1's already-unit-tested Breguet
%   exponential forms underneath (Roskam Eq. 2.10/2.12). These tests
%   therefore focus on the WIRING (does MissionL2 correctly assemble
%   CD0/K1/K2/CL/TSFC from the real discipline objects and hand them to the
%   Breguet form?) and the CALL-COUNT contract (subplan 07 Tests table),
%   not re-deriving the Breguet math itself (already independently
%   hand-verified in TestMissionL1.m).
%
%   Wiring tests below independently call aero_obj.drag_polar/compute_CL and
%   prop_obj.get_TSFC/compute_TSFC_AB THEMSELVES (the same real F16AeroL2/
%   F16PropL2 objects MissionL2 is handed), then feed those values into
%   MissionL1's already-verified Breguet formula, and compare the result to
%   MissionL2's own segment_* output -- this is the same "replay
%   independently, compare to the aggregator" pattern
%   TestConstraintAnalysis.m uses, not a self-referential check (a bug in
%   MissionL2's wiring -- e.g. wrong CL basis, wrong TSFC dispatch -- would
%   make this fail even though the underlying Breguet math is untouched).

    properties (Constant)
        TOL_TIGHT = 1e-9
        TOL_FORMULA = 1e-6
    end

    methods (Test)

        % ================================================================== %
        % Low-level pure math / dispatch
        % ================================================================== %

        function testLDFromPolarFormula(tc)
            % LD = CL / (CD0 + K1*CL^2 + K2*CL). Independent numeric case:
            % CD0=0.02, K1=0.1, K2=0, CL=0.3 -> CD=0.02+0.1*0.09=0.029,
            % LD=0.3/0.029=10.344827586206897.
            expected = 0.3 / (0.02 + 0.1*0.3^2 + 0*0.3);
            received = MissionL2.LD_from_polar(0.3, 0.02, 0.1, 0);
            fprintf('\n    LD_from_polar: received=%.9f, expected=%.9f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_FORMULA);
        end

        function testSelectTSFCDryDispatchesToGetTSFC(tc)
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 0.87);
            expected = prop.get_TSFC(state);
            received = MissionL2.select_TSFC(prop, state, "Dry");
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testSelectTSFCWetDispatchesToComputeTSFCAB(tc)
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 1.60);
            expected = prop.compute_TSFC_AB(state);
            received = MissionL2.select_TSFC(prop, state, "Wet");
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyNotEqual(received, prop.get_TSFC(state), ...
                'AB TSFC must differ from mil-power TSFC (not silently falling back to Dry).');
        end

        function testSelectTSFCUnknownFlagErrors(tc)
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.5);
            tc.verifyError(@() MissionL2.select_TSFC(prop, state, "Moist"), 'MissionL2:unknownDryOrWet');
        end

        % ================================================================== %
        % Segment wiring -- real F16AeroL2/F16PropL2 objects
        % ================================================================== %

        function testSegmentCruiseWiring(tc)
            aero  = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(40000, 0.87);
            W_in  = 25000;
            R_ft  = 189.879 * 6080;

            polar = aero.drag_polar(state);
            CL    = aero.compute_CL(W_in, state.q, aero.S_ref);
            LD    = CL / (polar.CD0 + polar.K1*CL^2 + polar.K2*CL);
            TSFC  = prop.get_TSFC(state);   % "Dry"
            expected_WF = MissionL1.breguet_range_WF(TSFC, R_ft, state.V, LD);
            expected_fuel_used = W_in * (1 - expected_WF);
            expected_W_out = W_in - expected_fuel_used;

            [W_out, fuel_used] = MissionL2.segment_cruise(W_in, aero, prop, state, R_ft, "Dry");
            fprintf('\n    segment_cruise: W_out=%.4f (expected %.4f), fuel_used=%.4f (expected %.4f)\n', ...
                W_out, expected_W_out, fuel_used, expected_fuel_used);
            tc.verifyEqual(W_out, expected_W_out, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyEqual(fuel_used, expected_fuel_used, 'AbsTol', tc.TOL_FORMULA);
        end

        function testSegmentDashWiringUsesABTsfc(tc)
            aero  = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(40000, 1.60);
            W_in  = 24000;
            R_ft  = 49.968 * 6080;

            polar = aero.drag_polar(state);
            CL    = aero.compute_CL(W_in, state.q, aero.S_ref);
            LD    = CL / (polar.CD0 + polar.K1*CL^2 + polar.K2*CL);
            TSFC  = prop.compute_TSFC_AB(state);   % "Wet"
            expected_WF = MissionL1.breguet_range_WF(TSFC, R_ft, state.V, LD);
            expected_fuel_used = W_in * (1 - expected_WF);

            [~, fuel_used] = MissionL2.segment_dash(W_in, aero, prop, state, R_ft, "Wet");
            tc.verifyEqual(fuel_used, expected_fuel_used, 'AbsTol', tc.TOL_FORMULA);
        end

        function testSegmentCombatWiringAppliesDropCorrectly(tc)
            aero  = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(25000, 0.80);
            W_in  = 22000; t_min = 2; W_drop = 4400;

            polar = aero.drag_polar(state);
            CL    = aero.compute_CL(W_in, state.q, aero.S_ref);
            LD    = CL / (polar.CD0 + polar.K1*CL^2 + polar.K2*CL);
            TSFC  = prop.compute_TSFC_AB(state);   % Combat is "Wet" on the CAP profile
            expected_WF = MissionL1.breguet_endurance_WF(TSFC, t_min/60, LD);
            expected_fuel_used = W_in * (1 - expected_WF);
            expected_W_out = W_in - expected_fuel_used - W_drop;

            [W_out, fuel_used] = MissionL2.segment_combat(W_in, aero, prop, state, t_min, "Wet", W_drop);
            fprintf('\n    segment_combat: W_out=%.4f (expected %.4f), fuel_used=%.4f (expected %.4f)\n', ...
                W_out, expected_W_out, fuel_used, expected_fuel_used);
            tc.verifyEqual(fuel_used, expected_fuel_used, 'AbsTol', tc.TOL_FORMULA, ...
                'fuel_used must exclude the payload drop.');
            tc.verifyEqual(W_out, expected_W_out, 'AbsTol', tc.TOL_FORMULA, ...
                'W_out must subtract both fuel_used and W_drop exactly once each.');
        end

        function testSegmentLoiterWiring(tc)
            aero  = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.31);
            W_in  = 21000; t_min = 20;

            polar = aero.drag_polar(state);
            CL    = aero.compute_CL(W_in, state.q, aero.S_ref);
            LD    = CL / (polar.CD0 + polar.K1*CL^2 + polar.K2*CL);
            TSFC  = prop.get_TSFC(state);   % "Dry"
            expected_WF = MissionL1.breguet_endurance_WF(TSFC, t_min/60, LD);
            expected_fuel_used = W_in * (1 - expected_WF);

            [~, fuel_used] = MissionL2.segment_loiter(W_in, aero, prop, state, t_min, "Dry");
            tc.verifyEqual(fuel_used, expected_fuel_used, 'AbsTol', tc.TOL_FORMULA);
        end

        % ================================================================== %
        % High-level dispatch loop: call counts (subplan 07 Tests table)
        % ================================================================== %

        function testGetMissionFuelCallsAeroAndPropExpectedNumberOfTimes(tc)
            % CAP-shaped 10-segment missiondata: Cruise/Dash/Combat/Cruise2/
            % Loiter (5 single-point segments, since "Cruise2" normalizes to
            % "cruise" and dispatches through the SAME case as "Cruise") each
            % call drag_polar ONCE; Climb (user-directed 2026-07-24: now
            % discretized, N=20) calls drag_polar N=20 times, once per
            % sub-interval (state changes every sub-interval, same reasoning
            % as MissionL3's Climb -- see MissionL3.segment_climb's header).
            % Startup/Taxi/Takeoff/Landing (4 segments) never call aero/prop.
            % dry_or_wet: Cruise/Cruise2/Loiter=Dry (3 single get_TSFC calls);
            % Climb is Dry-only by scope (MissionL3.m's SCOPE NOTE) and calls
            % get_TSFC N=20 times (once per sub-interval, TSFC not hoisted
            % since state changes); Dash/Combat=Wet (2 compute_TSFC_AB calls).
            N_climb = MissionL2.N_SUBSEGMENTS_CLIMB;
            md = TestMissionL2.capLikeMissiondata();
            aeroStub = CountingAeroStub();
            propStub = CountingPropStub();
            [W_fuel, ~] = MissionL2.get_mission_fuel(md, 31377, aeroStub, propStub);

            expected_drag_polar = 5 + N_climb;
            expected_get_TSFC   = 3 + N_climb;

            fprintf('\n    drag_polar calls=%d (expected %d), get_TSFC calls=%d (expected %d), compute_TSFC_AB calls=%d (expected 2)\n', ...
                aeroStub.drag_polar_calls, expected_drag_polar, propStub.get_TSFC_calls, expected_get_TSFC, propStub.compute_TSFC_AB_calls);
            tc.verifyEqual(aeroStub.drag_polar_calls, expected_drag_polar, ...
                'drag_polar must be called once per Cruise/Dash/Combat/Cruise2/Loiter, plus N=20 times for Climb''s sub-intervals.');
            tc.verifyEqual(propStub.get_TSFC_calls, expected_get_TSFC, ...
                'get_TSFC ("Dry") must be called for Cruise/Cruise2/Loiter (1 each) plus Climb (N=20 times).');
            tc.verifyEqual(propStub.compute_TSFC_AB_calls, 2, ...
                'compute_TSFC_AB ("Wet") must be called for Dash/Combat only.');
            tc.verifyGreaterThan(W_fuel, 0);
        end

        % ================================================================== %
        % Climb: discretized energy-height integration, N=20 (user-directed
        % 2026-07-24 -- NOT the fixed-fraction Table 2.1 lookup L1 uses)
        % ================================================================== %

        function testSegmentClimbIsDiscretizedNotFixedFraction(tc)
            % MissionL2.segment_climb must delegate to MissionL3's
            % energy-height integrator with N=20 (MissionL2.N_SUBSEGMENTS_CLIMB),
            % NOT MissionL1's fixed-fraction Table 2.1 lookup -- this is the
            % single most important behavior change this test file checks:
            % a regression back to the old "unchanged fixed-fraction" L2
            % climb would make this test's two computed values disagree from
            % what MissionL3.segment_climb (the shared integrator) returns
            % directly at N=20, since the two methods use entirely different
            % physics (Roskam Table 2.1 percentage vs. real T/D/TSFC).
            aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop = F16PropL2(f16a_spec_path(2));
            W_in = 30000;

            [W_out_L2, fuel_used_L2] = MissionL2.segment_climb(W_in, aero, prop, 0, 40000, 0.282, 0.87);
            [W_out_ref, fuel_used_ref] = MissionL3.segment_climb(W_in, aero, prop, 0, 40000, 0.282, 0.87, MissionL2.N_SUBSEGMENTS_CLIMB);

            fprintf('\n    MissionL2.segment_climb (N=%d): W_out=%.4f, fuel_used=%.4f\n', ...
                MissionL2.N_SUBSEGMENTS_CLIMB, W_out_L2, fuel_used_L2);
            tc.verifyEqual(W_out_L2, W_out_ref, 'AbsTol', tc.TOL_FORMULA, ...
                'MissionL2.segment_climb must match MissionL3''s energy-height integrator evaluated at N=20.');
            tc.verifyEqual(fuel_used_L2, fuel_used_ref, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyGreaterThan(fuel_used_L2, 0, 'Climb must burn strictly positive fuel.');

            % Anti-regression guard: the OLD L1-delegating fixed-fraction
            % climb would have returned a materially different fuel_used
            % (Roskam Table 2.1 fighter climb ~7% of W_in, vs. the real
            % energy-height integration's actual physics-based burn) --
            % verify this test would actually catch a regression back to it.
            [~, fuel_used_old_fixed_fraction] = MissionL1.segment_climb(W_in, "fighter");
            tc.verifyNotEqual(fuel_used_L2, fuel_used_old_fixed_fraction, ...
                'MissionL2.segment_climb must NOT silently fall back to the L1 fixed-fraction method.');
        end

        function testSegmentClimbCallsDragPolarAndTSFCNTimesAtL2(tc)
            % Mirrors TestMissionL3's identical check -- Climb's state
            % changes every sub-interval, so drag_polar/get_TSFC are called
            % N=20 times (MissionL2.N_SUBSEGMENTS_CLIMB), not once.
            N = MissionL2.N_SUBSEGMENTS_CLIMB;
            aeroStub = CountingAeroStub();
            propStub = CountingPropStub();
            [~, fu] = MissionL2.segment_climb(28000, aeroStub, propStub, 0, 40000, 0.282, 0.87);

            tc.verifyEqual(aeroStub.drag_polar_calls, N);
            tc.verifyEqual(propStub.get_TSFC_calls, N);
            tc.verifyEqual(propStub.thrust_lapse_mil_AB_calls, N);
            tc.verifyGreaterThan(fu, 0);
        end

        % ================================================================== %
        % Weight continuity + drop accounting, using REAL discipline objects
        % ================================================================== %

        function testGetMissionFuelWeightMonotonicAndDropAccounting(tc)
            md = TestMissionL2.capLikeMissiondata();
            aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop = F16PropL2(f16a_spec_path(2));
            [W_fuel, breakdown] = MissionL2.get_mission_fuel(md, 31377, aero, prop);

            TestMissionL2.print_segment_fuel_and_weight_table(md.segment_names, breakdown.fuel_used_lbf, breakdown.W_after_lbf);
            tc.verifyTrue(all(diff([31377, breakdown.W_after_lbf]) <= 0), ...
                'Running weight must be non-increasing across every CAP segment.');
            tc.verifyTrue(all(breakdown.fuel_used_lbf > 0), ...
                'Every fuel-burning L2 segment must show strictly positive fuel_used.');

            combat_idx = 7;   % Combat is segment 7 in capLikeMissiondata's order
            W_before_combat = breakdown.W_after_lbf(combat_idx - 1);
            expected_W_after_combat = W_before_combat - breakdown.fuel_used_lbf(combat_idx) - md.drop_lb(combat_idx);
            tc.verifyEqual(breakdown.W_after_lbf(combat_idx), expected_W_after_combat, 'AbsTol', 1e-6, ...
                'W after Combat must equal W before Combat minus fuel_used minus the 4,400 lbf drop -- no double count.');

            expected_Mff = (31377 - breakdown.total_fuel_used_lbf) / 31377;
            tc.verifyEqual(breakdown.Mff, expected_Mff, 'AbsTol', 1e-9, ...
                'Mff must be computed from the fuel-only total, excluding the payload drop.');
            tc.verifyGreaterThan(breakdown.total_fuel_used_lbf, 0);
            tc.verifyGreaterThan(W_fuel, 0);
        end

        % ================================================================== %
        % F16MissionL2 concrete Tier-3 class
        % ================================================================== %

        function testConstructorReadsMissionProfileJSON(tc)
            obj = F16MissionL2(mission_profile_path());
            tc.verifyEqual(obj.n_segments, 10);
            tc.verifyEqual(obj.segment_names(7), "Combat");
            tc.verifyEqual(obj.drop_lb(7), 4400, 'AbsTol', tc.TOL_TIGHT);
        end

        function testMissiondataPackagingMatchesInputs(tc)
            obj = F16MissionL2(mission_profile_path());
            v = obj.missiondata;
            tc.verifyEqual(v.RFF, obj.RFF, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(v.aircraft_category, obj.aircraft_category);
        end

        function testComputeFuelWithRealDisciplineObjectsIsPositive(tc)
            obj  = F16MissionL2(mission_profile_path());
            aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop = F16PropL2(f16a_spec_path(2));
            W_TO = 31377;
            W_fuel = obj.compute_fuel(aero, prop, W_TO);
            tc.verifyGreaterThan(W_fuel, 0);
            tc.verifyEqual(obj.mission_fuel, W_fuel, ...
                'compute_fuel must store its result on obj.mission_fuel (dual-return contract).');
        end

        function testComputeFuelPhysicallyPlausibleRatio(tc)
            % Subplan 07 Tests table calls for "same range, tighter" bounds
            % than L1 -- but gives no specific narrower numeric bound in the
            % text itself, and CLAUDE.md's Tier-1 rule requires tolerances to
            % be justified, not reverse-engineered from this run's own
            % output. Re-using L1's same cited wide band (0.15-0.35) here is
            % the defensible choice absent a more specific citation; a truly
            % tighter, justified bound is left as a follow-up if the
            % coordinator wants one derived from a real reference mission.
            obj  = F16MissionL2(mission_profile_path());
            aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
            prop = F16PropL2(f16a_spec_path(2));
            W_TO = 31377;
            W_fuel = obj.compute_fuel(aero, prop, W_TO);
            ratio = W_fuel / W_TO;
            fprintf('\n    F16MissionL2 CAP W_fuel/W_TO = %.4f\n', ratio);
            tc.verifyGreaterThan(ratio, 0.15);
            tc.verifyLessThan(ratio, 0.35);
        end

        function testMissiondataLiveRecomputeOnMutatedInput(tc)
            obj = F16MissionL2(mission_profile_path());
            obj.RFF = obj.RFF + 0.01;
            tc.verifyEqual(obj.missiondata.RFF, obj.RFF, 'AbsTol', tc.TOL_TIGHT);
        end

        function testDerivedPropertiesAreReadOnly(tc)
            obj = F16MissionL2(mission_profile_path());
            tc.verifyError(@() setfield(obj, 'missiondata', struct()), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'n_segments', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'total_range_nm_given', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsaMissionBaseAndMissionModelL2(tc)
            tc.verifyTrue(isa(F16MissionL2(mission_profile_path()), 'MissionBase'));
            tc.verifyTrue(isa(F16MissionL2(mission_profile_path()), 'MissionModelL2'));
        end

        function testNotIsaMissionModelL1OrL3(tc)
            tc.verifyFalse(isa(F16MissionL2(mission_profile_path()), 'MissionModelL1'));
            tc.verifyFalse(isa(F16MissionL2(mission_profile_path()), 'MissionModelL3'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16MissionL2(mission_profile_path()), 'handle'));
        end

    end

    methods (Static, Access = private)

        function md = capLikeMissiondata()
        %CAPLIKEMISSIONDATA  Same hand-built 10-segment struct as
        %   TestMissionL1's private helper (duplicated here since MATLAB
        %   private statics aren't shared across classdef files -- matches
        %   this repo's existing convention of small, self-contained test
        %   files, e.g. FixedAeroStub/FixedPropStub are the only SHARED test
        %   helpers, kept as their own classdef files).
            md = struct( ...
                'segment_names',  ["Startup","Taxi","Takeoff","Climb","Cruise","Dash","Combat","Cruise2","Loiter","Landing"], ...
                'alt_ft',         [0, 0, 0, 40000, 40000, 40000, 25000, 40000, 10000, 0], ...
                'mach_end',       [0, 0, 0.282, 0.87, 0.87, 1.60, 0.80, 0.87, 0.31, 0.3], ...
                'dist_nm_given',  [NaN, NaN, NaN, NaN, 189.879, 49.968, NaN, 239.847, NaN, NaN], ...
                'time_min_given', [NaN, NaN, NaN, NaN, NaN, NaN, 2.0, NaN, 20.0, NaN], ...
                'drop_lb',        [0, 0, 0, 0, 0, 0, 4400, 0, 0, 0], ...
                'dry_or_wet',     ["Dry","Dry","Dry","Dry","Dry","Wet","Wet","Dry","Dry","Dry"], ...
                'aircraft_category', "fighter", ...
                'RFF', 0.06);
        end

        function print_segment_fuel_and_weight_table(names, fuel_used, W_after)
        %PRINT_SEGMENT_FUEL_AND_WEIGHT_TABLE  Same standardized table as
        %   TestMissionL1's identical helper -- see that file for rationale.
            fprintf('\n    %-14s  %-38s  %-32s\n', 'Segment', ...
                'Weight of fuel burned, per segment (lbf)', 'Aircraft weight, per segment (lbf)');
            for i = 1:numel(names)
                fprintf('    %-14s  %38.2f  %32.2f\n', names(i), fuel_used(i), W_after(i));
            end
        end

    end

end
