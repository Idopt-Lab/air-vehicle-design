classdef TestMissionL1 < matlab.unittest.TestCase
%TESTMISSIONL1  Unit tests for the MissionL1 static toolbox and the
%   F16MissionL1 concrete (Tier-3) class.
%
%   TIER: unit/correctness -- gates run_all_tests. No deliberately-failing
%   TODO tests in this file (all cited equations below have a resolved
%   citation per docs/subplans/07_mission_analysis.md).
%
%   Hand-computed expected values (independent arithmetic, NOT read from
%   MissionL1.m's own Constant tables a second time -- these are the literal
%   Roskam Airplane Design Part I values docs/subplans/07_mission_analysis.md
%   itself independently re-verified against the book, 2026-07-24):
%
%     Table 2.1, Fighters row (p.12):
%       Startup=0.990, Taxi=0.990, Takeoff=0.990, Climb=mean([0.90,0.96])=0.93,
%       Descent=0.990, Landing=0.995
%     Table 2.2, Fighters row (p.14):
%       cruise LD=mean([4,7])=5.5, cruise cj=mean([0.6,1.4])=1.0
%       loiter LD=mean([6,9])=7.5, loiter cj=mean([0.6,0.8])=0.7
%     Sec. 2.6.3 Example 3 "Strafe" phase (Table 2.19): LD=4.5, cj=0.9
%
%   Pure-math formula checks (breguet_range_WF/breguet_endurance_WF/
%   apply_best_range_correction) re-implement Roskam Eq. 2.10/2.12's
%   rearranged exponential form INLINE with the test's own arithmetic
%   (matching the established convention in tests/disciplines/TestPropL1.m,
%   e.g. its testSigmaLapseFormula) -- this is a formula-correctness check
%   (does the code implement the cited equation?), not a re-derivation of
%   physical truth, so recomputing the same closed-form expression with
%   MATLAB's own exp()/^ operators here is not "self-referential" in the
%   sense CLAUDE.md's Tier-1 rule warns against (that rule targets reusing a
%   CALIBRATED table/coefficient the code-under-test also reads -- these are
%   pure, uncalibrated math identities).

    properties (Constant)
        TOL_TIGHT = 1e-9
        TOL_FORMULA = 1e-6
    end

    methods (Test)

        % ================================================================== %
        % Low-level: Roskam Table 2.1 fixed-fraction lookup
        % ================================================================== %

        function testFixedFractionFighterValues(tc)
            % Source: Roskam Airplane Design Part I, Table 2.1, Fighters row
            % (independently re-verified against the book, subplan 07).
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "startup"), 0.990, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "taxi"),    0.990, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "takeoff"), 0.990, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "climb"),   0.93,  'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "descent"), 0.990, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_fixed_fraction("fighter", "landing"), 0.995, 'AbsTol', tc.TOL_TIGHT);
        end

        function testFixedFractionTakeoffCorrectsLegacyBug(tc)
            % Known Issues #1: legacy code hardcoded WF=0.95 for Takeoff.
            % Roskam Table 2.1's real fighter Takeoff value is 0.990.
            received = MissionL1.lookup_fixed_fraction("fighter", "takeoff");
            tc.verifyNotEqual(received, 0.95, 'Must NOT reproduce the legacy 0.95 bug.');
            tc.verifyEqual(received, 0.990, 'AbsTol', tc.TOL_TIGHT);
        end

        function testFixedFractionDescentCorrectsLegacyPlaceholder(tc)
            % Known Issues #5: prior draft used WF=1.0 (no-fuel-burn
            % placeholder) for Descent. Roskam Table 2.1's real fighter
            % Descent value is 0.990 (a real 1% fuel burn).
            received = MissionL1.lookup_fixed_fraction("fighter", "descent");
            tc.verifyNotEqual(received, 1.0, 'Must NOT be an unimplemented WF=1.0 placeholder.');
            tc.verifyEqual(received, 0.990, 'AbsTol', tc.TOL_TIGHT);
        end

        function testFixedFractionUnknownCategoryErrors(tc)
            tc.verifyError(@() MissionL1.lookup_fixed_fraction("spaceship", "startup"), ...
                'MissionL1:unknownCategory');
        end

        function testFixedFractionUnknownSegmentErrors(tc)
            tc.verifyError(@() MissionL1.lookup_fixed_fraction("fighter", "orbit"), ...
                'MissionL1:unknownSegment');
        end

        % ================================================================== %
        % Low-level: Roskam Table 2.2 tabulated cruise/loiter L/D and cj
        % ================================================================== %

        function testTable22FighterValues(tc)
            % Source: Roskam Airplane Design Part I, Table 2.2, Fighters row.
            tc.verifyEqual(MissionL1.lookup_table22("fighter", "cruise", "LD"), 5.5, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_table22("fighter", "cruise", "cj"), 1.0, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_table22("fighter", "loiter", "LD"), 7.5, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(MissionL1.lookup_table22("fighter", "loiter", "cj"), 0.7, 'AbsTol', tc.TOL_TIGHT);
        end

        function testTable22UnknownInputsError(tc)
            tc.verifyError(@() MissionL1.lookup_table22("spaceship", "cruise", "LD"), 'MissionL1:unknownCategory');
            tc.verifyError(@() MissionL1.lookup_table22("fighter", "descent", "LD"), 'MissionL1:unknownPhase');
            tc.verifyError(@() MissionL1.lookup_table22("fighter", "cruise", "cd0"), 'MissionL1:unknownQuantity');
        end

        % ================================================================== %
        % Low-level: combat/strafe condition (Roskam Sec. 2.6.3 Example 3)
        % ================================================================== %

        function testCombatConditionFighter(tc)
            % Source: Roskam Airplane Design Part I, Table 2.19 "Strafe" phase.
            val = MissionL1.lookup_combat_condition("fighter");
            tc.verifyEqual(val.LD, 4.5, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(val.cj, 0.9, 'AbsTol', tc.TOL_TIGHT);
        end

        function testCombatConditionUnknownCategoryErrors(tc)
            % Roskam's Strafe worked example only covers "fighter" -- no
            % citation exists for any other category (Known Issues #3).
            tc.verifyError(@() MissionL1.lookup_combat_condition("business_jet"), 'MissionL1:unknownCategory');
        end

        % ================================================================== %
        % Low-level: pure-math Breguet formulas
        % ================================================================== %

        function testBreguetRangeWFFormula(tc)
            % Roskam Eq. 2.10 (rearranged): WF = exp(-(R*TSFC)/(V*LD)).
            % Independent numeric case: TSFC=1.2 1/hr, R=500,000 ft,
            % V=800 ft/s, LD=6.
            TSFC = 1.2; R_ft = 500000; V_fts = 800; LD = 6;
            t_hr = (R_ft / V_fts) / 3600;              % = 0.17361111 hr
            expected = exp(-(TSFC * t_hr) / LD);         % = exp(-0.034722...) = 0.965870...
            received = MissionL1.breguet_range_WF(TSFC, R_ft, V_fts, LD);
            fprintf('\n    breguet_range_WF: received=%.9f, expected=%.9f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyLessThan(received, 1.0, 'A fuel-burning range segment must have WF < 1.');
        end

        function testBreguetEnduranceWFFormula(tc)
            % Roskam Eq. 2.12 (rearranged): WF = exp(-(t*TSFC)/LD).
            % Independent numeric case: TSFC=0.8 1/hr, t=0.5 hr, LD=5.
            TSFC = 0.8; t_hr = 0.5; LD = 5;
            expected = exp(-(TSFC * t_hr) / LD);   % = exp(-0.08) = 0.923116...
            received = MissionL1.breguet_endurance_WF(TSFC, t_hr, LD);
            fprintf('\n    breguet_endurance_WF: received=%.9f, expected=%.9f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_FORMULA);
            tc.verifyLessThan(received, 1.0, 'A fuel-burning endurance segment must have WF < 1.');
        end

        function testApplyBestRangeCorrection(tc)
            % 0.866 = sqrt(3)/2 best-range correction factor (Known Issues
            % #3 secondary flag -- Cruise/Dash ONLY). LD_max=10 -> 8.66.
            expected = 10 * 0.866;
            received = MissionL1.apply_best_range_correction(10);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testNormalizeSegmentName(tc)
            % Legacy dispatch-loop convention: lowercase, strip digits/underscores.
            tc.verifyEqual(MissionL1.normalize_segment_name("Cruise2"), "cruise");
            tc.verifyEqual(MissionL1.normalize_segment_name("Combat"),  "combat");
            tc.verifyEqual(MissionL1.normalize_segment_name("Cruise_Outbound2"), "cruiseoutbound");
        end

        % ================================================================== %
        % Low-level: mission aggregate formulas
        % ================================================================== %

        function testComputeMissionFuelFractionFormula(tc)
            % Roskam Eq. 2.13's telescoping product collapses to W_final/W_TO.
            % W_TO=50000, W_final=42000 -> Mff=0.84.
            expected = 0.84;
            received = MissionL1.compute_mission_fuel_fraction(50000, 42000);
            tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_TIGHT);
        end

        function testComputeMissionFuelWeightFormula(tc)
            % Roskam Eq. 2.14/2.15 + RFF reserve term.
            % W_TO=50000, Mff=0.84, RFF=0.06:
            %   W_F_no_reserve = (1-0.84)*50000 = 8000
            %   W_Fres = 0.06*8000 = 480
            %   W_F = 8480
            expected = 8480;
            received = MissionL1.compute_mission_fuel_weight(50000, 0.84, 0.06);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        % ================================================================== %
        % Low-level: segment_combat drop-vs-fuel accounting
        % ================================================================== %

        function testSegmentCombatFuelUsedExcludesDropButWOutIncludesIt(tc)
            % Design Notes: W_drop reduces weight at the END of the segment
            % directly, NOT routed through the fuel fraction. This is the
            % single most important behavior to pin down precisely: a bug
            % here would either double-count the drop (W_out reduced twice)
            % or silently omit it (W_out only reflects fuel burn).
            W_in = 20000; t_min = 2; TSFC = 0.9; LD = 4.5; W_drop = 4400;
            t_hr = t_min / 60;
            expected_WF = exp(-(TSFC * t_hr) / LD);        % Roskam Eq. 2.12 form
            expected_fuel_used = W_in * (1 - expected_WF);
            expected_W_out = W_in - expected_fuel_used - W_drop;

            [W_out, fuel_used] = MissionL1.segment_combat(W_in, t_min, TSFC, LD, W_drop);

            fprintf('\n    segment_combat: fuel_used=%.6f (expected %.6f), W_out=%.6f (expected %.6f)\n', ...
                fuel_used, expected_fuel_used, W_out, expected_W_out);
            tc.verifyEqual(fuel_used, expected_fuel_used, 'AbsTol', tc.TOL_FORMULA, ...
                'fuel_used must reflect ONLY the Breguet-computed burn, not the payload drop.');
            tc.verifyEqual(W_out, expected_W_out, 'AbsTol', tc.TOL_FORMULA, ...
                'W_out must subtract BOTH fuel_used AND W_drop exactly once each.');
            % Explicit anti-double-count / anti-omission guards:
            tc.verifyNotEqual(W_out, W_in - fuel_used, ...
                'W_out must NOT omit the payload drop.');
            tc.verifyNotEqual(W_out, W_in - fuel_used - 2*W_drop, ...
                'W_out must NOT double-count the payload drop.');
        end

        % ================================================================== %
        % High-level: get_mission_fuel dispatch-loop wiring
        % ================================================================== %

        function testGetMissionFuelWeightContinuityAndDropAccounting(tc)
            % Builds a small 4-segment missiondata (Startup/Taxi/Cruise/
            % Combat) and independently replays the SAME already-unit-tested
            % low-level statics by hand, exactly the aggregation-test pattern
            % TestConstraintAnalysis.m uses (build ThrustConstraint objects,
            % replay required_TW independently, compare to
            % ConstraintAnalysis's aggregation) -- this exercises the LOOP's
            % wiring (does segment i+1 receive segment i's W_out as its
            % W_in?), not the low-level formulas themselves (already covered
            % above).
            md = struct( ...
                'segment_names',  ["Startup","Taxi","Cruise","Combat"], ...
                'alt_ft',         [0, 0, 40000, 25000], ...
                'mach_end',       [0, 0, 0.87, 0.80], ...
                'dist_nm_given',  [NaN, NaN, 100, NaN], ...
                'time_min_given', [NaN, NaN, NaN, 2], ...
                'drop_lb',        [0, 0, 0, 4400], ...
                'dry_or_wet',     ["Dry","Dry","Dry","Wet"], ...
                'aircraft_category', "fighter", ...
                'RFF', 0.06);

            W0 = 100000;
            [W1, fu1] = MissionL1.segment_startup(W0, "fighter");
            [W2, fu2] = MissionL1.segment_taxi(W1, "fighter");

            TSFC_c = MissionL1.lookup_table22("fighter", "cruise", "cj");
            LD_c   = MissionL1.apply_best_range_correction(MissionL1.lookup_table22("fighter", "cruise", "LD"));
            state  = AircraftState(40000, 0.87);
            R_ft   = 100 * 6080;
            [W3, fu3] = MissionL1.segment_cruise(W2, TSFC_c, R_ft, state.V, LD_c);

            combat = MissionL1.lookup_combat_condition("fighter");
            [W4, fu4] = MissionL1.segment_combat(W3, 2, combat.cj, combat.LD, 4400);

            aeroMock = ErroringAeroMock();
            propMock = ErroringPropMock();
            [W_fuel, breakdown] = MissionL1.get_mission_fuel(md, W0, aeroMock, propMock);

            fprintf('\n    Weight chain (independent replay): %.4f -> %.4f -> %.4f -> %.4f\n', W1, W2, W3, W4);
            fprintf('    breakdown.W_after_lbf:                 %.4f -> %.4f -> %.4f -> %.4f\n', breakdown.W_after_lbf);

            tc.verifyEqual(breakdown.W_after_lbf, [W1, W2, W3, W4], 'AbsTol', 1e-6, ...
                'Dispatch loop must chain W_out from each segment into the next segment''s W_in.');
            tc.verifyEqual(breakdown.fuel_used_lbf, [fu1, fu2, fu3, fu4], 'AbsTol', 1e-6);
            tc.verifyEqual(breakdown.total_fuel_used_lbf, fu1+fu2+fu3+fu4, 'AbsTol', 1e-6, ...
                'total_fuel_used must EXCLUDE the 4,400 lbf Combat payload drop.');

            expected_Mff = (W0 - (fu1+fu2+fu3+fu4)) / W0;
            expected_Wfuel = (1 - expected_Mff)*W0 * (1 + 0.06);
            tc.verifyEqual(breakdown.Mff, expected_Mff, 'AbsTol', 1e-9);
            tc.verifyEqual(W_fuel, expected_Wfuel, 'AbsTol', 1e-6);

            % Explicit "no double count into the fuel-fraction total" guard:
            % Mff computed from the RAW final running weight (which DOES
            % include the drop) would be a DIFFERENT, smaller number --
            % verify get_mission_fuel does NOT do that.
            wrong_Mff_if_using_raw_running_weight = W4 / W0;
            tc.verifyNotEqual(breakdown.Mff, wrong_Mff_if_using_raw_running_weight, ...
                'Mff must be computed from FUEL-ONLY final weight, not the raw (drop-inclusive) running weight.');
        end

        function testGetMissionFuelWFLessThanOneAndTotalFuelPositive(tc)
            % Full 10-segment CAP-shaped missiondata (fighter category) --
            % every Roskam-tabulated WF is < 1 (all Table 2.1/2.2/Sec.2.6.3
            % values cited above are less than unity), so every segment must
            % burn strictly positive fuel, and the mission total must be
            % strictly positive.
            md = TestMissionL1.capLikeMissiondata();
            aeroMock = ErroringAeroMock();
            propMock = ErroringPropMock();
            [W_fuel, breakdown] = MissionL1.get_mission_fuel(md, 31377, aeroMock, propMock);

            TestMissionL1.print_segment_fuel_and_weight_table(md.segment_names, breakdown.fuel_used_lbf, breakdown.W_after_lbf);
            fprintf('    Total fuel used (excl. drop): %.2f lbf,  W_fuel (incl. reserve): %.2f lbf\n', ...
                breakdown.total_fuel_used_lbf, W_fuel);

            tc.verifyTrue(all(breakdown.fuel_used_lbf > 0), ...
                'Every CAP segment must burn strictly positive fuel at L1 (all Roskam WF < 1).');
            tc.verifyGreaterThan(breakdown.total_fuel_used_lbf, 0);
            tc.verifyGreaterThan(W_fuel, 0);
        end

        function testGetMissionFuelUnknownSegmentErrors(tc)
            md = struct( ...
                'segment_names',  ["Startup","Orbit"], ...
                'alt_ft',         [0, 0], ...
                'mach_end',       [0, 0], ...
                'dist_nm_given',  [NaN, NaN], ...
                'time_min_given', [NaN, NaN], ...
                'drop_lb',        [0, 0], ...
                'dry_or_wet',     ["Dry","Dry"], ...
                'aircraft_category', "fighter", ...
                'RFF', 0.06);
            tc.verifyError(@() MissionL1.get_mission_fuel(md, 31377, ErroringAeroMock(), ErroringPropMock()), ...
                'MissionL1:unknownSegment');
        end

        % ================================================================== %
        % High-level: L1 must NEVER call aero_obj/prop_obj
        % ================================================================== %

        function testGetMissionFuelNeverCallsAeroOrProp(tc)
            % Design Notes: "L1 does NOT call aero.drag_polar or
            % prop.get_TSFC/compute_TSFC_AB. Arguments accepted but unused."
            % ErroringAeroMock/ErroringPropMock throw on ANY method call --
            % if get_mission_fuel completes without error, L1 never touched
            % either discipline object.
            md = TestMissionL1.capLikeMissiondata();
            [W_fuel, ~] = MissionL1.get_mission_fuel(md, 31377, ErroringAeroMock(), ErroringPropMock());
            tc.verifyGreaterThan(W_fuel, 0, ...
                'get_mission_fuel must complete successfully using only mock objects that error on any call.');
        end

        % ================================================================== %
        % F16MissionL1 concrete Tier-3 class
        % ================================================================== %

        function testConstructorReadsMissionProfileJSON(tc)
            obj = F16MissionL1(mission_profile_path());
            tc.verifyEqual(obj.n_segments, 10);
            tc.verifyEqual(obj.segment_names(1), "Startup");
            tc.verifyEqual(obj.segment_names(7), "Combat");
            tc.verifyEqual(obj.drop_lb(7), 4400, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(obj.aircraft_category, "fighter");
        end

        function testTotalRangeNmGivenMatchesHandSum(tc)
            % examples/F16A/mission_profile.json: Cruise=189.879,
            % Dash=49.968, Cruise2=239.847 nm; all other segments NaN
            % (omitted). Hand sum: 189.879+49.968+239.847 = 479.694.
            obj = F16MissionL1(mission_profile_path());
            tc.verifyEqual(obj.total_range_nm_given, 479.694, 'AbsTol', 1e-3);
        end

        function testMissiondataPackagingMatchesInputs(tc)
            obj = F16MissionL1(mission_profile_path());
            v = obj.missiondata;
            tc.verifyEqual(v.RFF, obj.RFF, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(v.CLmax_TO, obj.CLmax_TO, 'AbsTol', tc.TOL_TIGHT);
            tc.verifyEqual(v.aircraft_category, obj.aircraft_category);
            tc.verifyEqual(v.segment_names, obj.segment_names);
        end

        function testComputeFuelNeverCallsMocksAndSetsMissionFuel(tc)
            obj  = F16MissionL1(mission_profile_path());
            W_TO = 31377;
            W_fuel = obj.compute_fuel(ErroringAeroMock(), ErroringPropMock(), W_TO);
            tc.verifyGreaterThan(W_fuel, 0);
            tc.verifyEqual(obj.mission_fuel, W_fuel, ...
                'compute_fuel must store its result on obj.mission_fuel (dual-return contract).');
        end

        function testComputeFuelPhysicallyPlausibleRatio(tc)
            % Subplan 07 Tests table: W_fuel/W_TO roughly 0.15-0.35 for a
            % fighter CAP mission (physics bounds, wide -- not a tight
            % Brandt-matching target; CAP and Brandt's Miss tab are
            % deliberately different profiles, see subplan's CAP-vs-Brandt
            % section).
            obj  = F16MissionL1(mission_profile_path());
            W_TO = 31377;   % F16Baseline TOGW [Brandt B38] -- common starting-weight assumption across L1/L2/L3 unit tests (user-directed 2026-07-24)
            W_fuel = obj.compute_fuel(ErroringAeroMock(), ErroringPropMock(), W_TO);
            ratio = W_fuel / W_TO;
            fprintf('\n    F16MissionL1 CAP W_fuel/W_TO = %.4f\n', ratio);
            tc.verifyGreaterThan(ratio, 0.15);
            tc.verifyLessThan(ratio, 0.35);
        end

        function testMissiondataLiveRecomputeOnMutatedInput(tc)
            % Optimization-ready property design (CLAUDE.md): a Dependent
            % property must track a mutated input live, no reconstruction.
            obj = F16MissionL1(mission_profile_path());
            obj.RFF = obj.RFF + 0.01;
            tc.verifyEqual(obj.missiondata.RFF, obj.RFF, 'AbsTol', tc.TOL_TIGHT, ...
                'missiondata.RFF must track a mutated obj.RFF with no reconstruction.');

            old_total = obj.total_range_nm_given;
            obj.dist_nm_given(5) = obj.dist_nm_given(5) + 100;   % Cruise leg
            tc.verifyEqual(obj.total_range_nm_given, old_total + 100, 'AbsTol', tc.TOL_TIGHT, ...
                'total_range_nm_given must recompute live from the mutated dist_nm_given array.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
            obj = F16MissionL1(mission_profile_path());
            tc.verifyError(@() setfield(obj, 'missiondata', struct()), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'n_segments', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(obj, 'total_range_nm_given', 5), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsaMissionBase(tc)
            tc.verifyTrue(isa(F16MissionL1(mission_profile_path()), 'MissionBase'));
        end

        function testIsaMissionModelL1(tc)
            tc.verifyTrue(isa(F16MissionL1(mission_profile_path()), 'MissionModelL1'));
        end

        function testNotIsaMissionModelL2OrL3(tc)
            tc.verifyFalse(isa(F16MissionL1(mission_profile_path()), 'MissionModelL2'));
            tc.verifyFalse(isa(F16MissionL1(mission_profile_path()), 'MissionModelL3'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16MissionL1(mission_profile_path()), 'handle'));
        end

    end

    methods (Static, Access = private)

        function md = capLikeMissiondata()
        %CAPLIKEMISSIONDATA  Hand-built 10-segment CAP-shaped missiondata
        %   struct (same segment types/order as examples/F16A/
        %   mission_profile.json) for generic-toolbox tests that shouldn't
        %   depend on the JSON file itself.
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
        %PRINT_SEGMENT_FUEL_AND_WEIGHT_TABLE  Standardized command-window
        %   table -- one row per mission segment, columns "Weight of fuel
        %   burned, per segment (lbf)" and "Aircraft weight, per segment
        %   (lbf)" (user-directed 2026-07-24: consistent format across
        %   TestMissionL1/L2/L3, replacing the previously-inconsistent ad hoc
        %   prints -- L1 printed an arrow-separated weight chain plus a
        %   separate fuel array, L2/L3 printed only a bare weight array with
        %   no fuel column and no segment-name labels).
            fprintf('\n    %-14s  %-38s  %-32s\n', 'Segment', ...
                'Weight of fuel burned, per segment (lbf)', 'Aircraft weight, per segment (lbf)');
            for i = 1:numel(names)
                fprintf('    %-14s  %38.2f  %32.2f\n', names(i), fuel_used(i), W_after(i));
            end
        end

    end

end
