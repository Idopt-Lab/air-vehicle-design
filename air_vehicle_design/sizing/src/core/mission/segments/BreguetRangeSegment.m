classdef BreguetRangeSegment < MissionSegment
%BREGUETRANGESEGMENT  A range-given cruise/dash leg sized by the Breguet range
%   equation, with L/D from the injected aero object and TSFC from the injected
%   prop object.
%
%   fuel = W_before * (1 - WF), WF = exp(-c_j (R/V) / (L/D))
%   [Roskam Airplane Design Part I, Eq. 2.10; see MissionEquations.breguet_range_wf].
%
%   L/D is the ACTUAL operating value at this leg's flight condition and weight:
%     state = AircraftState(alt_end, mach_end)          (end-of-segment waypoint)
%     CL    = aero.compute_CL(W_before, state.q, geom.get_S_ref())
%     CD    = aero.compute_CD(CD0 + cd0_increment, K1, K2, CL)   [aero.drag_polar]
%     L/D   = CL / CD
%   -- so no separate best-range (0.866 * L/D_max) correction is applied: the
%   real Mach/altitude/weight are known, giving the real cruise L/D directly.
%   Weight is taken at segment START (W_before), matching Brandt's Miss-tab
%   "Wf at start" convention.

    methods
        function fuel = fuel_burn(obj, ctx)
            state = obj.end_state();
            polar = ctx.aero.drag_polar(state);
            CD0   = polar.CD0 + obj.cd0_increment;
            S_ref = ctx.geom.get_S_ref();

            CL = ctx.aero.compute_CL(obj.W_before, state.q, S_ref);
            CD = ctx.aero.compute_CD(CD0, polar.K1, polar.K2, CL);
            LD = CL / CD;

            cT    = MissionEquations.select_tsfc(ctx.prop, state, obj.percent_ab);
            R_ft  = obj.distance_nm * MissionEquations.NM_TO_FT;
            wf    = MissionEquations.breguet_range_wf(cT, R_ft, state.V, LD);
            fuel  = obj.W_before * (1 - wf);

            obj.debug = struct('method', "breguet_range", 'LD', LD, 'CL', CL, ...
                'CD', CD, 'TSFC_per_hr', cT, 'V_fts', state.V, 'range_ft', R_ft, ...
                'ab_degraded', obj.percent_ab > 0 && ~MissionEquations.has_ab_model(ctx.prop));
        end
    end

end
