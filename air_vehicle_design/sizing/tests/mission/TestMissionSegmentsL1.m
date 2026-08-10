classdef TestMissionSegmentsL1 < matlab.unittest.TestCase
%TESTMISSIONSEGMENTSL1  Unit tests for the L1 segment classes.
%   FixedFractionSegment is checked against its hand value; the Breguet segments
%   are checked by independently replaying the cited formulas (Roskam Eq. 2.10 /
%   2.12) off the same stub aero/prop/geom -- this verifies the WIRING (that the
%   segment assembles CL/CD/LD/TSFC and hands them to the Breguet form
%   correctly), while the formulas themselves are hand-checked in
%   TestMissionEquations. Also verifies the payload-drop bookkeeping. Unit tier.

    properties (Constant)
        TOL = 1e-9;
    end

    methods (Access = private)
        function ctx = makeCtx(~)
            ctx = struct('aero', MissionStubAero(), 'prop', MissionStubProp(), ...
                'geom', MissionStubGeom(), 'W_TO', 31377, ...
                'aircraft_category', "jet_fighter", 'n_engines', 1, ...
                'warmup_fuel_per_engine_lb', 1000, 'mu_rolling', 0.03, ...
                'mu_braking', 0.5, 'liftoff_factor', 1.2, 'approach_factor', 1.3);
        end
    end

    methods (Test)

        function testFixedFractionClimb(tc)
            ctx = tc.makeCtx();
            seg = FixedFractionSegment();
            seg.segment_type = "climb";
            fuel = seg.step(30000, ctx);
            tc.verifyEqual(fuel, 30000 * (1 - 0.93), 'RelTol', tc.TOL);
            tc.verifyEqual(seg.W_after, 30000 - fuel, 'RelTol', tc.TOL);
        end

        function testFixedFractionIgnoresAeroProp(tc)
            % Fixed-fraction phases must not touch the drag polar / TSFC: an
            % erroring aero/prop mock proves it (reuses the legacy mocks).
            ctx = tc.makeCtx();
            ctx.aero = ErroringAeroMock();
            ctx.prop = ErroringPropMock();
            seg = FixedFractionSegment();
            seg.segment_type = "landing";
            fuel = seg.step(20000, ctx);
            tc.verifyEqual(fuel, 20000 * (1 - 0.995), 'RelTol', tc.TOL);
        end

        function testBreguetRangeWiring(tc)
            ctx = tc.makeCtx();
            seg = BreguetRangeSegment();
            seg.segment_type = "cruise";
            seg.alt_end_ft = 40000; seg.mach_end = 0.8;
            seg.distance_nm = 100; seg.percent_ab = 0; seg.cd0_increment = 0;
            fuel = seg.step(30000, ctx);

            exp_fuel = tc.replayRange(ctx, 30000, 40000, 0.8, 100, 0, 0);
            tc.verifyEqual(fuel, exp_fuel, 'RelTol', 1e-9);
            tc.verifyGreaterThan(seg.debug.LD, 0);
            tc.verifyFalse(seg.debug.ab_degraded);   % stub has an AB model
        end

        function testBreguetRangeCd0IncrementRaisesFuel(tc)
            ctx = tc.makeCtx();
            clean = tc.replayRange(ctx, 30000, 40000, 0.8, 100, 0, 0.0);
            dirty = tc.replayRange(ctx, 30000, 40000, 0.8, 100, 0, 0.01);
            tc.verifyGreaterThan(dirty, clean);   % extra parasite drag burns more
        end

        function testBreguetRangeAfterburnerTSFC(tc)
            % percent_ab=100 -> the stub's AB TSFC (1.8) is used.
            ctx = tc.makeCtx();
            seg = BreguetRangeSegment();
            seg.segment_type = "dash";
            seg.alt_end_ft = 40000; seg.mach_end = 1.2;
            seg.distance_nm = 50; seg.percent_ab = 100; seg.cd0_increment = 0;
            seg.step(30000, ctx);
            tc.verifyEqual(seg.debug.TSFC_per_hr, 1.8, 'RelTol', tc.TOL);
        end

        function testBreguetEnduranceWiring(tc)
            ctx = tc.makeCtx();
            seg = BreguetEnduranceSegment();
            seg.segment_type = "loiter";
            seg.alt_end_ft = 10000; seg.mach_end = 0.3;
            seg.time_min = 20; seg.percent_ab = 0;
            fuel = seg.step(20000, ctx);

            exp_fuel = tc.replayEndurance(ctx, 20000, 10000, 0.3, 20, 0, 0);
            tc.verifyEqual(fuel, exp_fuel, 'RelTol', 1e-9);
        end

        function testCombatDropBookkeeping(tc)
            % Combat = endurance burn + payload drop. The returned fuel excludes
            % the drop; W_after subtracts BOTH fuel and drop (no double-count).
            ctx = tc.makeCtx();
            seg = BreguetEnduranceSegment();
            seg.segment_type = "combat";
            seg.alt_end_ft = 25000; seg.mach_end = 0.8;
            seg.time_min = 2; seg.drop_lb = 4400; seg.percent_ab = 0;
            fuel = seg.step(25000, ctx);

            exp_fuel = tc.replayEndurance(ctx, 25000, 25000, 0.8, 2, 0, 0);
            tc.verifyEqual(fuel, exp_fuel, 'RelTol', 1e-9);
            tc.verifyEqual(seg.W_after, 25000 - fuel - 4400, 'RelTol', tc.TOL);
        end

    end

    methods (Access = private)

        function f = replayRange(~, ctx, W, alt, mach, dist_nm, pct_ab, cd0inc)
            state = AircraftState(alt, mach);
            polar = ctx.aero.drag_polar(state);
            CL = ctx.aero.compute_CL(W, state.q, ctx.geom.get_S_ref());
            CD = ctx.aero.compute_CD(polar.CD0 + cd0inc, polar.K1, polar.K2, CL);
            LD = CL / CD;
            cT = MissionEquations.select_tsfc(ctx.prop, state, pct_ab);
            R  = dist_nm * MissionEquations.NM_TO_FT;
            wf = MissionEquations.breguet_range_wf(cT, R, state.V, LD);
            f  = W * (1 - wf);
        end

        function f = replayEndurance(~, ctx, W, alt, mach, t_min, pct_ab, cd0inc)
            state = AircraftState(alt, mach);
            polar = ctx.aero.drag_polar(state);
            CL = ctx.aero.compute_CL(W, state.q, ctx.geom.get_S_ref());
            CD = ctx.aero.compute_CD(polar.CD0 + cd0inc, polar.K1, polar.K2, CL);
            LD = CL / CD;
            cT = MissionEquations.select_tsfc(ctx.prop, state, pct_ab);
            wf = MissionEquations.breguet_endurance_wf(cT, t_min, LD);
            f  = W * (1 - wf);
        end

    end
end
