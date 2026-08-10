classdef TestMissionSegmentsL2 < matlab.unittest.TestCase
%TESTMISSIONSEGMENTSL2  Unit tests for the L2 master-equation segment classes.
%   Combat and patrol are hand-computable; the master-equation and takeoff legs
%   are verified by independently replaying their cited formulas off the same
%   fixed stub disciplines (validating the WIRING). Unit tier.

    properties (Constant)
        TOL  = 1e-9;
        W_TO = 31377;
    end

    methods (Access = private)
        function ctx = makeCtx(tc)
            ctx = struct('aero', MissionStubAero(), 'prop', MissionStubProp(), ...
                'geom', MissionStubGeom(), 'W_TO', tc.W_TO, ...
                'aircraft_category', "jet_fighter", 'n_engines', 1, ...
                'warmup_fuel_per_engine_lb', 1000, 'mu_rolling', 0.03, ...
                'mu_braking', 0.5, 'liftoff_factor', 1.2, 'approach_factor', 1.3);
        end
        function s = setCond(~, s, altS, altE, mS, mE)
            s.alt_start_ft = altS; s.alt_end_ft = altE;
            s.mach_start = mS;     s.mach_end = mE;
        end
    end

    methods (Test)

        function testCombatFuelHandComputed(tc)
            % Stub: alpha = 0.6 (mil==AB), T_SL = 20000 -> T_avail = 12000;
            % cT at %AB=100 = compute_TSFC_AB = 1.8. fuel = t/60 * cT * T_avail
            %   = 2/60 * 1.8 * 12000 = 720 lb. Drop is applied by step, not fuel.
            ctx = tc.makeCtx();
            seg = CombatSegment();
            seg = tc.setCond(seg, 25000, 25000, 0.87, 0.87);
            seg.time_min = 2; seg.percent_ab = 100; seg.drop_lb = 4400;
            fuel = seg.step(25000, ctx);
            tc.verifyEqual(fuel, 720, 'RelTol', 1e-9);
            tc.verifyEqual(seg.W_after, 25000 - 720 - 4400, 'RelTol', tc.TOL);
        end

        function testPatrolZeroTimeBurnsZero(tc)
            % Zero given time at unchanged conditions -> zero fuel.
            ctx = tc.makeCtx();
            seg = LoiterSegment();
            seg = tc.setCond(seg, 40000, 40000, 0.87, 0.87);
            seg.time_min = 0;
            fuel = seg.step(28000, ctx);
            tc.verifyEqual(fuel, 0, 'AbsTol', 1e-9);
        end

        function testLoiterBurnsPositiveFuel(tc)
            ctx = tc.makeCtx();
            seg = LoiterSegment();
            seg = tc.setCond(seg, 10000, 10000, 0.30, 0.30);
            seg.time_min = 20;
            fuel = seg.step(22000, ctx);
            tc.verifyGreaterThan(fuel, 0);
            tc.verifyLessThan(fuel, 22000);
        end

        function testCruiseMasterEquationReplay(tc)
            ctx = tc.makeCtx();
            seg = CruiseSegment();
            seg = tc.setCond(seg, 40000, 40000, 0.87, 0.87);
            seg.distance_nm = 190; seg.percent_ab = 0; seg.cd0_increment = 0.01;
            fuel = seg.step(29000, ctx);
            exp_fuel = tc.replayMaster(ctx, 29000, 40000, 40000, 0.87, 0.87, ...
                190, 0, 0.01, false);
            tc.verifyEqual(fuel, exp_fuel, 'RelTol', 1e-9);
        end

        function testEgressCarriesEnergyTermWhenClimbing(tc)
            % A distance-given leg that climbs (25000 -> 40000) must include the
            % energy term (energy_lb > 0), unlike a level cruise.
            ctx = tc.makeCtx();
            seg = CruiseSegment();
            seg = tc.setCond(seg, 25000, 40000, 0.87, 0.87);
            seg.distance_nm = 50;
            seg.step(26000, ctx);
            tc.verifyGreaterThan(seg.debug.energy_lb, 0);
        end

        function testClimbProducesPositiveTimeAndFuel(tc)
            ctx = tc.makeCtx();
            seg = ClimbSegment();
            seg = tc.setCond(seg, 10000, 40000, 0.87, 0.87);
            fuel = seg.step(30000, ctx);
            tc.verifyGreaterThan(seg.debug.t_min, 0);
            tc.verifyGreaterThan(fuel, 0);
        end

        function testClimb2SameConditionsBurnsZero(tc)
            % Ps-based leg with dh = dV = 0 -> t = 0 and no energy -> ~0 fuel.
            ctx = tc.makeCtx();
            seg = ClimbSegment();
            seg = tc.setCond(seg, 40000, 40000, 0.87, 0.87);
            fuel = seg.step(23000, ctx);
            tc.verifyEqual(fuel, 0, 'AbsTol', 1e-9);
        end

        function testTakeoffGroundRollReplayWithWarmup(tc)
            ctx = tc.makeCtx();
            seg = TakeoffSegment();
            seg = tc.setCond(seg, 0, 0, 0, 0.282);
            seg.percent_ab = 100;
            fuel = seg.step(tc.W_TO, ctx);
            exp_fuel = tc.replayTakeoff(ctx, 0.282, 100, true);
            tc.verifyEqual(fuel, exp_fuel, 'RelTol', 1e-9);
        end

        function testTakeoffWithoutWarmupIsSmaller(tc)
            % include_warmup_start=false drops terms 2+3 -> only the ground-roll
            % term remains, so the burn is strictly smaller.
            ctx = tc.makeCtx();
            with = TakeoffSegment(); with = tc.setCond(with, 0, 0, 0, 0.282);
            with.percent_ab = 0;
            f_with = with.step(tc.W_TO, ctx);

            without = TakeoffSegment(); without = tc.setCond(without, 0, 0, 0, 0.282);
            without.percent_ab = 0; without.include_warmup_start = false;
            f_without = without.step(tc.W_TO, ctx);

            tc.verifyLessThan(f_without, f_with);
            tc.verifyEqual(f_without, tc.replayTakeoff(ctx, 0.282, 0, false), 'RelTol', 1e-9);
        end

    end

    methods (Access = private)

        function f = replayMaster(~, ctx, W, altS, altE, mS, mE, dist_nm, pct, cd0inc, avgTsfc)
            g = 32.2;
            st_s = AircraftState(altS, mS); st_e = AircraftState(altE, mE);
            WS = ctx.W_TO / ctx.geom.get_S_ref();
            Wf = W / ctx.W_TO;
            ps = ctx.aero.drag_polar(st_s); pe = ctx.aero.drag_polar(st_e);
            CDo = (ps.CD0 + pe.CD0)/2 + cd0inc;
            k1 = (ps.K1 + pe.K1)/2; k2 = (ps.K2 + pe.K2)/2;
            q_avg = (st_s.q + st_e.q)/2;
            x = Wf/q_avg;
            dc = CDo/WS + k1*x^2*WS + k2*x;
            t = dist_nm * MissionEquations.NM_TO_FT / st_e.V / 60;
            cT_e = MissionEquations.select_tsfc(ctx.prop, st_e, pct);
            if avgTsfc
                cT = (MissionEquations.select_tsfc(ctx.prop, st_s, pct) + cT_e)/2;
            else
                cT = cT_e;
            end
            drag = cT/60 * q_avg * dc * t;
            dh = altE - altS; dV = st_e.V - st_s.V; Vsum = st_s.V + st_e.V;
            energy_s = dh*2/Vsum + dV/g;
            energy = (energy_s > 0) * cT/3600 * Wf * energy_s;
            f = (drag + energy) * ctx.W_TO;
        end

        function f = replayTakeoff(~, ctx, mach, pct, incWarmup)
            g = 32.2;
            rho_SL = AircraftState(0,0).rho;
            st = AircraftState(0, mach);
            WS = ctx.W_TO / ctx.geom.get_S_ref();
            V_stall = sqrt(2*WS/rho_SL/ctx.aero.get_CLmax_TO());
            TW = ctx.prop.T_SL / ctx.W_TO;
            cT_roll = MissionEquations.select_tsfc(ctx.prop, st, pct);
            cT_dry  = MissionEquations.select_tsfc(ctx.prop, st, 0);
            term1 = 1.2*cT_roll/(g*3600)*V_stall;
            if incWarmup
                term2 = TW*cT_dry/60;
                term3 = ctx.warmup_fuel_per_engine_lb * ctx.n_engines / ctx.W_TO;
            else
                term2 = 0; term3 = 0;
            end
            f = (term1+term2+term3) * ctx.W_TO;
        end

    end
end
