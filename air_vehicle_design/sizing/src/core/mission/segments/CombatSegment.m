classdef CombatSegment < MissionSegment
%COMBATSEGMENT  L2 combat leg (Brandt Miss!I9/I13 form):
%
%     T_avail = prop.T_SL * alpha        (alpha = select_alpha at percent_ab)
%     fuel    = t_min/60 * cT * T_avail
%
%   i.e. fuel = TSFC[1/hr] * time[hr] * available thrust[lb]. alpha is the
%   AB-normalized thrust lapse (mil/AB blended by percent_ab), so
%   T_avail = T_SL*alpha is the actual thrust at the combat condition and power
%   -- no *n_engines (T_SL is already total, alpha total-normalized). The
%   payload drop (drop_lb) is applied by MissionSegment.step (W_after subtracts
%   both this fuel and the drop), so the drop is never counted as fuel.

    methods
        function fuel = fuel_burn(obj, ctx)
            st = obj.end_state();
            alpha   = MissionEquations.select_alpha(ctx.prop, st, obj.percent_ab);
            T_avail = ctx.prop.T_SL * alpha;
            cT      = MissionEquations.select_tsfc(ctx.prop, st, obj.percent_ab);
            fuel    = obj.time_min / 60 * cT * T_avail;

            S_ref = ctx.geom.get_S_ref();
            polar = ctx.aero.drag_polar(st);
            CL = ctx.aero.compute_CL(obj.W_before, st.q, S_ref);
            CD = ctx.aero.compute_CD(polar.CD0 + obj.cd0_increment, polar.K1, polar.K2, CL);
            obj.debug = struct('method', "combat", 'T_avail', T_avail, ...
                'alpha', alpha, 'TSFC_per_hr', cT, 'LD', CL / CD, ...
                'ab_degraded', obj.percent_ab > 0 && ~MissionEquations.has_ab_model(ctx.prop));
        end
    end
end
