classdef BreguetEnduranceSegment < MissionSegment
%BREGUETENDURANCESEGMENT  A time-given loiter/combat leg sized by the Breguet
%   endurance equation, with L/D from the injected aero object and TSFC from the
%   injected prop object.
%
%   fuel = W_before * (1 - WF), WF = exp(-c_j E / (L/D)),  E = time_min/60
%   [Roskam Airplane Design Part I, Eq. 2.12; MissionEquations.breguet_endurance_wf].
%
%   Combat is modeled as an endurance burn plus a payload drop: this class
%   returns the endurance fuel only, and the payload jettison (drop_lb) is
%   applied by MissionSegment.step (W_after = W_before - fuel - drop_lb), so the
%   drop is never double-counted as fuel. L/D is the actual operating value at
%   the leg's condition and start weight (same basis as BreguetRangeSegment).

    methods
        function fuel = fuel_burn(obj, ctx)
            state = obj.end_state();
            polar = ctx.aero.drag_polar(state);
            CD0   = polar.CD0 + obj.cd0_increment;
            S_ref = ctx.geom.get_S_ref();

            CL = ctx.aero.compute_CL(obj.W_before, state.q, S_ref);
            CD = ctx.aero.compute_CD(CD0, polar.K1, polar.K2, CL);
            LD = CL / CD;

            cT   = MissionEquations.select_tsfc(ctx.prop, state, obj.percent_ab);
            wf   = MissionEquations.breguet_endurance_wf(cT, obj.time_min, LD);
            fuel = obj.W_before * (1 - wf);

            obj.debug = struct('method', "breguet_endurance", 'LD', LD, 'CL', CL, ...
                'CD', CD, 'TSFC_per_hr', cT, 'time_min', obj.time_min, ...
                'ab_degraded', obj.percent_ab > 0 && ~MissionEquations.has_ab_model(ctx.prop));
        end
    end

end
