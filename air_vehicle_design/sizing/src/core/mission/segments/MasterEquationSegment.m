classdef (Abstract) MasterEquationSegment < MissionSegment
%MASTEREQUATIONSEGMENT  Abstract mid-tier for the L2 "master" mission fuel form.
%
%   Mission analogue of MasterEquationConstraint: it centralizes Brandt's
%   generic per-segment fuel equation (Miss-tab, readme_mission.md "Generic"),
%   and each concrete subclass supplies only the segment TIME:
%
%     dW/W_TO = cT/60 * q_avg * ( CDo_avg/WS + k1_avg*(Wf/q_avg)^2*WS
%                                            + k2_avg*(Wf/q_avg) ) * t_min   [drag]
%             + cT/3600 * Wf * ( dh*2/(Vs+Ve) + dV/g )                        [energy, climbs]
%     fuel   = dW/W_TO * W_TO           (payload drop handled by step, not here)
%
%   where Wf = W_before/W_TO (weight fraction at segment START), WS = W_TO/S_ref,
%   q_avg / CDo_avg / k1_avg / k2_avg are averages of the start- and end-condition
%   values, and cd0_increment (en-route stores) adds to CDo. TSFC is the
%   end-condition value, except Ps-based climbs which average start/end
%   (average_tsfc = true) -- matching the Miss-tab D33/L33 rule. The energy term
%   is added only when the segment gains energy (climb/accel, energy_s > 0);
%   descents are not credited, matching the Miss tab.
%
%   L/D is NOT used to size the burn here (the dc term is); it is computed only
%   for the comparison-report debug struct.

    properties (Access = protected)
        average_tsfc (1,1) logical = false   % Ps-based climbs set this true
    end

    methods (Abstract)
        %SEGMENT_TIME  Segment duration [min] for this subclass's time source
        %   (given distance, given time, or Ps-based).
        t = segment_time(obj, ctx)
    end

    methods

        function fuel = fuel_burn(obj, ctx)
            [q_s, q_e, V_s, V_e, st_s, st_e] = obj.flight_states();
            S_ref = ctx.geom.get_S_ref();
            WS = ctx.W_TO / S_ref;
            Wf = obj.W_before / ctx.W_TO;

            ps = ctx.aero.drag_polar(st_s);
            pe = ctx.aero.drag_polar(st_e);
            CDo_avg = (ps.CD0 + pe.CD0) / 2 + obj.cd0_increment;
            k1_avg  = (ps.K1  + pe.K1)  / 2;
            k2_avg  = (ps.K2  + pe.K2)  / 2;

            q_avg = (q_s + q_e) / 2;
            x  = Wf / q_avg;
            dc = CDo_avg / WS + k1_avg * x^2 * WS + k2_avg * x;

            t_min = obj.segment_time(ctx);

            pct  = obj.percent_ab;
            cT_e = MissionEquations.select_tsfc(ctx.prop, st_e, pct);
            if obj.average_tsfc
                cT_s = MissionEquations.select_tsfc(ctx.prop, st_s, pct);
                cT = (cT_s + cT_e) / 2;
            else
                cT = cT_e;
            end

            drag_frac = cT / 60 * q_avg * dc * t_min;

            g  = 32.2;
            dh = obj.alt_end_ft - obj.alt_start_ft;
            dV = V_e - V_s;
            Vsum = V_s + V_e;
            if Vsum > 0
                energy_s = dh * 2 / Vsum + dV / g;
            else
                energy_s = 0;
            end
            if energy_s > 0
                energy_frac = cT / 3600 * Wf * energy_s;
            else
                energy_frac = 0;
            end

            fuel = (drag_frac + energy_frac) * ctx.W_TO;

            CL_e = ctx.aero.compute_CL(obj.W_before, q_e, S_ref);
            CD_e = ctx.aero.compute_CD(CDo_avg, k1_avg, k2_avg, CL_e);
            obj.debug = struct('method', "master_eq", 'LD', CL_e / CD_e, ...
                'TSFC_per_hr', cT, 't_min', t_min, 'q_avg', q_avg, ...
                'drag_lb', drag_frac * ctx.W_TO, 'energy_lb', energy_frac * ctx.W_TO, ...
                'ab_degraded', pct > 0 && ~MissionEquations.has_ab_model(ctx.prop));
        end

    end

    methods (Access = protected)
        function [q_s, q_e, V_s, V_e, st_s, st_e] = flight_states(obj)
        %FLIGHT_STATES  Start/end AircraftState + their q and V.
            st_s = obj.start_state();
            st_e = obj.end_state();
            q_s = st_s.q;  q_e = st_e.q;
            V_s = st_s.V;  V_e = st_e.V;
        end
    end

end
