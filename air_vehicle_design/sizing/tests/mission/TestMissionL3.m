classdef TestMissionL3 < matlab.unittest.TestCase
%TESTMISSIONL3  Unit tests for the MissionL3 static toolbox and the
%   F16MissionL3 concrete (Tier-3) class.
%
%   TIER: unit/correctness -- gates run_all_tests. No deliberately-failing
%   TODO tests in this file.
%
%   *** IMPORTANT FINDING, reported to the coordinator (not fixed here,
%   per test-writer's role -- see final report): there is NO F16PropL3 /
%   PropulsionModelL3 / PropL3 anywhere in this repo (confirmed by
%   directory listing: examples/F16A only has F16PropL1.m and F16PropL2.m;
%   src/disciplines/propulsion only has PropulsionModelL1/L2 and PropL1/L2).
%   Propulsion has not yet been extended to a third fidelity tier, contrary
%   to CLAUDE.md's blanket statement that "Aerodynamics, Propulsion, and
%   Weights... keep their full L1/L2/L3 structure." Since MissionL3 needs a
%   prop_obj exposing get_TSFC/compute_TSFC_AB/thrust_lapse_mil_on_AB_scale/
%   T_SL -- all of which F16PropL2 already implements -- these tests use
%   F16PropL2() as the propulsion stand-in for Mission L3, paired with the
%   real F16AeroL3() aero object. This is a Propulsion-discipline gap, not a
%   Mission-discipline bug; MissionL3's own code is fidelity-generic (it
%   only calls the PropulsionBase-contract methods) and works correctly
%   against whatever concrete prop object is supplied.
%
%   L3 sub-segments Cruise/Dash/Combat/Loiter into N=20 sub-intervals of the
%   same Roskam Eq. 2.10/2.12 Breguet forms L1/L2 already use (re-verified
%   in TestMissionL1.m), and integrates Climb via an energy-height method at
%   its OWN, separately-set N=40 sub-intervals (MissionL3.N_SUBSEGMENTS_CLIMB
%   -- user-directed 2026-07-24, double MissionL2's N=20 climb resolution).
%   These tests focus on the sub-segmentation WIRING (call counts, weight
%   chaining across sub-intervals, drop-vs-fuel accounting) rather than
%   re-deriving the underlying Breguet exponential (already covered).

    properties (Constant)
        TOL_TIGHT = 1e-9
        TOL_FORMULA = 1e-6
    end

    methods (Test)

        % ================================================================== %
        % Low-level pure math
        % ================================================================== %

        function testEnergyHeightRateFormula(tc)
            % dh_e/dt = (T-D)*V/W [Mattingly AED 2nd ed., Case 1/3 forms].
            % Independent numeric case: T=5000 lbf, D=2000 lbf, V=800 ft/s,
            % W=20000 lbf -> (5000-2000)*800/20000 = 120 ft/s.
            expected = (5000-2000)*800/20000;   % = 120
            received = MissionL3.energy_height_rate(5000, 2000, 800, 20000);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testBreguetRangeStepDelegatesToMissionL1(tc)
            % breguet_range_step reuses MissionL1.breguet_range_WF's form
            % exactly -- a delegation check, not a re-derivation.
            [W_out1, fu1] = MissionL3.breguet_range_step(20000, 1.0, 50000, 800, 6);
            WF = MissionL1.breguet_range_WF(1.0, 50000, 800, 6);
            expected_fu = 20000*(1-WF);
            tc.verifyEqual(fu1, expected_fu, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyEqual(W_out1, 20000-expected_fu, 'AbsTol', tc.TOL_FORMULA);
        end

        function testBreguetEnduranceStepDelegatesToMissionL1(tc)
            [W_out1, fu1] = MissionL3.breguet_endurance_step(20000, 0.9, 0.05, 4.5);
            WF = MissionL1.breguet_endurance_WF(0.9, 0.05, 4.5);
            expected_fu = 20000*(1-WF);
            tc.verifyEqual(fu1, expected_fu, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyEqual(W_out1, 20000-expected_fu, 'AbsTol', tc.TOL_FORMULA);
        end

        % ================================================================== %
        % Sub-segmentation call counts (subplan 07 Tests table: "N times at L3")
        % ================================================================== %

        function testSegmentCruiseCallsDragPolarNTimesButTSFCOnce(tc)
            % TSFC depends only on (alt, mach) -- constant across a
            % constant-altitude/speed Cruise leg -- so segment_cruise
            % computes it ONCE before the N-step loop (an efficiency choice,
            % not a bug: re-selecting TSFC N times would return the
            % identical value every time since state never changes within
            % the segment). drag_polar, by contrast, is called once PER
            % sub-interval in the current implementation even though its
            % result (CD0/K1/K2, Mach-dependent only) is also state-invariant
            % across the loop -- see this test's docstring / this file's
            % header for the flagged minor inefficiency (not a correctness
            % bug: recomputing an invariant N times still returns the same
            % value each time).
            N = 5;
            aeroStub = CountingAeroStub();
            propStub = CountingPropStub();
            [~, fu] = MissionL3.segment_cruise(25000, aeroStub, propStub, 40000, 0.87, 189.879*6080, "Dry", N);

            tc.verifyEqual(aeroStub.drag_polar_calls, N, ...
                'drag_polar must be called exactly N times (once per sub-interval).');
            tc.verifyEqual(propStub.get_TSFC_calls, 1, ...
                'get_TSFC must be called exactly ONCE per Cruise segment (state is constant across sub-intervals).');
            tc.verifyEqual(propStub.compute_TSFC_AB_calls, 0);
            tc.verifyGreaterThan(fu, 0);
        end

        function testSegmentClimbCallsDragPolarAndTSFCNTimes(tc)
            % Unlike Cruise/Dash/Combat/Loiter, Climb's state DOES change
            % every sub-interval (altitude/Mach are linearly interpolated
            % start->end) -- so both drag_polar and get_TSFC are correctly
            % called once PER sub-interval here (N times), not once.
            N = 5;
            aeroStub = CountingAeroStub();
            propStub = CountingPropStub();
            [~, fu] = MissionL3.segment_climb(28000, aeroStub, propStub, 0, 40000, 0.282, 0.87, N);

            tc.verifyEqual(aeroStub.drag_polar_calls, N);
            tc.verifyEqual(propStub.get_TSFC_calls, N, ...
                'Climb''s state changes every sub-interval, so get_TSFC must be called N times (unlike Cruise).');
            tc.verifyEqual(propStub.thrust_lapse_mil_AB_calls, N, ...
                'Climb is always mil-power/Dry -- must call thrust_lapse_mil_on_AB_scale N times, not thrust_lapse.');
            tc.verifyEqual(propStub.thrust_lapse_calls, 0, ...
                'Climb must use the mil-on-AB-scale lapse, not the AB-basis thrust_lapse.');
            tc.verifyGreaterThan(fu, 0);
        end

        function testGetMissionFuelCallCountsAcrossFullCapProfile(tc)
            % Full CAP-shaped 10-segment run. Breguet segments needing
            % aero/prop: Cruise(5)/Dash(6)/Combat(7)/Cruise2(8)/Loiter(9) --
            % 5 segments, N=20 drag_polar calls each (MissionL3.N_SUBSEGMENTS).
            % Climb(4) also calls drag_polar N_climb=40 times (its OWN,
            % separately-set sub-interval count, MissionL3.N_SUBSEGMENTS_CLIMB
            % -- user-directed 2026-07-24, decoupled from the Breguet
            % segments' N=20). TSFC: Cruise/Cruise2/Loiter are "Dry" (1
            % get_TSFC call EACH, not N -- see above), Dash/Combat are "Wet"
            % (1 compute_TSFC_AB call EACH); Climb calls get_TSFC N_climb=40
            % times (state changes every sub-interval).
            N       = MissionL3.N_SUBSEGMENTS;
            N_climb = MissionL3.N_SUBSEGMENTS_CLIMB;
            md = TestMissionL3.capLikeMissiondata();
            aeroStub = CountingAeroStub();
            propStub = CountingPropStub();
            [W_fuel, ~] = MissionL3.get_mission_fuel(md, 31377, aeroStub, propStub);

            expected_drag_polar   = 5*N + N_climb;   % 5 Breguet segments (N each) + Climb (N_climb)
            expected_get_TSFC     = 3 + N_climb;     % Cruise/Cruise2/Loiter (1 each) + Climb (N_climb)
            expected_TSFC_AB      = 2;               % Dash/Combat (1 each)
            expected_mil_AB_lapse = N_climb;         % Climb only

            fprintf(['\n    L3 call counts: drag_polar=%d (expected %d), get_TSFC=%d (expected %d), ' ...
                'compute_TSFC_AB=%d (expected %d), thrust_lapse_mil_AB=%d (expected %d)\n'], ...
                aeroStub.drag_polar_calls, expected_drag_polar, propStub.get_TSFC_calls, expected_get_TSFC, ...
                propStub.compute_TSFC_AB_calls, expected_TSFC_AB, propStub.thrust_lapse_mil_AB_calls, expected_mil_AB_lapse);

            tc.verifyEqual(aeroStub.drag_polar_calls, expected_drag_polar);
            tc.verifyEqual(propStub.get_TSFC_calls, expected_get_TSFC);
            tc.verifyEqual(propStub.compute_TSFC_AB_calls, expected_TSFC_AB);
            tc.verifyEqual(propStub.thrust_lapse_mil_AB_calls, expected_mil_AB_lapse);
            tc.verifyGreaterThan(W_fuel, 0);
        end

        % ================================================================== %
        % Sub-segmentation actually changes the result (not a no-op)
        % ================================================================== %

        function testSubSegmentationChangesResultVsSinglePoint(tc)
            % With a FIXED (state-invariant) drag polar from CountingAeroStub
            % (CD0=0.02, K1=0.1, K2=0), any difference between N=1 and N=20
            % must come from the weight-update / CL-recompute effect between
            % sub-intervals (the "cruise-climb" fidelity gain L3 exists to
            % capture) -- not from a changing atmosphere/Mach. If segment_
            % cruise's sub-segmentation were a no-op (e.g. a bug reusing the
            % same weight for every sub-interval), N=1 and N=20 would return
            % IDENTICAL fuel_used.
            aero1 = CountingAeroStub(); prop1 = CountingPropStub();
            aero2 = CountingAeroStub(); prop2 = CountingPropStub();
            [~, fu_N1]  = MissionL3.segment_cruise(25000, aero1, prop1, 40000, 0.87, 189.879*6080, "Dry", 1);
            [~, fu_N20] = MissionL3.segment_cruise(25000, aero2, prop2, 40000, 0.87, 189.879*6080, "Dry", 20);
            fprintf('\n    fuel_used: N=1 -> %.6f lbf,  N=20 -> %.6f lbf\n', fu_N1, fu_N20);
            tc.verifyNotEqual(fu_N1, fu_N20, ...
                'Sub-segmentation must change the result (captures cruise-climb L/D improvement); N=1 and N=20 must differ.');
        end

        % ================================================================== %
        % Drop accounting -- applied ONCE at segment end, not per sub-interval
        % ================================================================== %

        function testSegmentCombatDropAppliedOnceNotPerSubInterval(tc)
            aero = F16AeroL3();
            prop = F16PropL2();
            W_in = 22000; t_min = 2; W_drop = 4400; N = 5;
            [W_out, fuel_used] = MissionL3.segment_combat(W_in, aero, prop, 25000, 0.80, t_min, "Wet", W_drop, N);
            fprintf('\n    L3 segment_combat (N=%d): W_out=%.4f, fuel_used=%.4f\n', N, W_out, fuel_used);
            tc.verifyEqual(W_out, W_in - fuel_used - W_drop, 'AbsTol', 1e-6, ...
                'W_drop must be subtracted exactly ONCE (after the N-sub-interval loop), not per sub-interval.');
            tc.verifyGreaterThan(fuel_used, 0);
        end

        % ================================================================== %
        % Weight continuity across the full dispatch loop (real objects)
        % ================================================================== %

        function testGetMissionFuelWeightMonotonicWithRealObjects(tc)
            md = TestMissionL3.capLikeMissiondata();
            aero = F16AeroL3();
            prop = F16PropL2();   % see file header -- no F16PropL3 exists
            [W_fuel, breakdown] = MissionL3.get_mission_fuel(md, 31377, aero, prop);

            TestMissionL3.print_segment_fuel_and_weight_table(md.segment_names, breakdown.fuel_used_lbf, breakdown.W_after_lbf);
            tc.verifyTrue(all(diff([31377, breakdown.W_after_lbf]) <= 1e-6), ...
                'Running weight must be non-increasing across every CAP segment.');
            tc.verifyTrue(all(breakdown.fuel_used_lbf > 0), ...
                'Every fuel-burning L3 segment must show strictly positive fuel_used.');

            combat_idx = 7;
            W_before_combat = breakdown.W_after_lbf(combat_idx - 1);
            expected_W_after_combat = W_before_combat - breakdown.fuel_used_lbf(combat_idx) - md.drop_lb(combat_idx);
            tc.verifyEqual(breakdown.W_after_lbf(combat_idx), expected_W_after_combat, 'AbsTol', 1e-6, ...
                'W after Combat must equal W before Combat minus fuel_used minus the 4,400 lbf drop -- no double count.');

            expected_Mff = (31377 - breakdown.total_fuel_used_lbf) / 31377;
            tc.verifyEqual(breakdown.Mff, expected_Mff, 'AbsTol', 1e-9);
            tc.verifyGreaterThan(W_fuel, 0);
        end

        % ================================================================== %
        % F16MissionL3 concrete Tier-3 class
        % ================================================================== %

        function testConstructorReadsMissionProfileJSON(tc)
            obj = F16MissionL3();
            tc.verifyEqual(obj.n_segments, 10);
            tc.verifyEqual(obj.segment_names(7), "Combat");
            tc.verifyEqual(obj.drop_lb(7), 4400, 'AbsTol', tc.TOL_TIGHT);
        end

        function testComputeFuelWithRealDisciplineObjectsIsPositive(tc)
            obj  = F16MissionL3();
            aero = F16AeroL3();
            prop = F16PropL2();   % see file header -- no F16PropL3 exists
            W_TO = 31377;
            W_fuel = obj.compute_fuel(aero, prop, W_TO);
            tc.verifyGreaterThan(W_fuel, 0);
            tc.verifyEqual(obj.mission_fuel, W_fuel);
        end

        function testComputeFuelPhysicallyPlausibleRatio(tc)
            % Same wide, subplan-cited bound as L1/L2 -- see TestMissionL2's
            % identical comment for why a narrower bound isn't used here.
            obj  = F16MissionL3();
            aero = F16AeroL3();
            prop = F16PropL2();
            W_TO = 31377;
            W_fuel = obj.compute_fuel(aero, prop, W_TO);
            ratio = W_fuel / W_TO;
            fprintf('\n    F16MissionL3 CAP W_fuel/W_TO = %.4f\n', ratio);
            tc.verifyGreaterThan(ratio, 0.15);
            tc.verifyLessThan(ratio, 0.35);
        end

        function testMissiondataLiveRecomputeOnMutatedInput(tc)
            obj = F16MissionL3();
            obj.RFF = obj.RFF + 0.01;
            tc.verifyEqual(obj.missiondata.RFF, obj.RFF, 'AbsTol', tc.TOL_TIGHT);
        end

        function testDerivedPropertiesAreReadOnly(tc)
            obj = F16MissionL3();
            tc.verifyError(@() setfield(obj, 'missiondata', struct()), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'n_segments', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'total_range_nm_given', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsaMissionBaseAndMissionModelL3(tc)
            tc.verifyTrue(isa(F16MissionL3(), 'MissionBase'));
            tc.verifyTrue(isa(F16MissionL3(), 'MissionModelL3'));
        end

        function testNotIsaMissionModelL1OrL2(tc)
            tc.verifyFalse(isa(F16MissionL3(), 'MissionModelL1'));
            tc.verifyFalse(isa(F16MissionL3(), 'MissionModelL2'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16MissionL3(), 'handle'));
        end

    end

    methods (Static, Access = private)

        function md = capLikeMissiondata()
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
