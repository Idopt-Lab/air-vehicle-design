classdef TakeoffSegment < MissionSegment
%TAKEOFFSEGMENT  L2 takeoff leg (Brandt Miss!B13 ground-roll form):
%
%     V_stall_TO = sqrt( 2 * (W_TO/S_ref) / rho_SL / CLmax_TO )
%     dW/W_TO    = 1.2 * cT_roll/(g*3600) * V_stall_TO      [ground-roll fuel]
%                + T/W * cT_dry/60                            [1-min dry warm-up]
%                + warmup_fuel_per_engine_lb * n_eng / W_TO   [fixed start fuel]
%     fuel       = dW/W_TO * W_TO
%
%   CLmax_TO comes from aero.get_CLmax_TO(); rho_SL from AircraftState(0,0);
%   cT_roll is the TSFC at the segment's power setting, cT_dry the mil TSFC;
%   T/W = prop.T_SL/W_TO; n_eng = geom.n_engines (via ctx).
%
%   include_warmup_start toggles terms 2+3 (the ground phase). It is set false
%   by MissionAnalysisL2.from_requirements when the profile has explicit
%   Startup/Taxi legs (which already carry the ground fuel via their Roskam
%   fractions), leaving only the ground-roll term. See that method for the guard.

    properties
        include_warmup_start (1,1) logical = true
    end

    methods
        function fuel = fuel_burn(obj, ctx)
            g = 32.2;
            rho_SL = AircraftState(0, 0).rho;
            st_TO  = AircraftState(0, obj.mach_end);   % liftoff Mach

            CLmax_TO = ctx.aero.get_CLmax_TO();
            WS = ctx.W_TO / ctx.geom.get_S_ref();
            V_stall = sqrt(2 * WS / rho_SL / CLmax_TO);
            TW = ctx.prop.T_SL / ctx.W_TO;

            cT_roll = MissionEquations.select_tsfc(ctx.prop, st_TO, obj.percent_ab);
            cT_dry  = MissionEquations.select_tsfc(ctx.prop, st_TO, 0);

            term1 = 1.2 * cT_roll / (g * 3600) * V_stall;   % ground-roll fuel frac
            if obj.include_warmup_start
                term2 = TW * cT_dry / 60;
                term3 = ctx.warmup_fuel_per_engine_lb * ctx.n_engines / ctx.W_TO;
            else
                term2 = 0;
                term3 = 0;
            end

            fuel = (term1 + term2 + term3) * ctx.W_TO;

            obj.debug = struct('method', "takeoff", 'V_stall_TO', V_stall, ...
                'CLmax_TO', CLmax_TO, 'TSFC_roll', cT_roll, ...
                'warmup_start_included', obj.include_warmup_start);
        end
    end
end
