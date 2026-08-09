classdef ClimbSegment < MasterEquationSegment
%CLIMBSEGMENT  L2 climb / accel / climb2 leg. Time comes from specific excess
%   power (Ps), matching Brandt's Miss-tab row-45/44/8 chain:
%
%     Ps      = 0.5*( Ps_end + Ps_start )
%     Ps_i    = V_i * ( alpha_i/Wf * T/W - q_i * dc_i )
%     dV/dt   = 32.2 * Ps / (V_s + V_e) * 2
%     t_min   = |dh / Ps / 60| + |dV / (dV/dt) / 60|
%
%   where T/W = prop.T_SL/W_TO, alpha_i = MissionEquations.select_alpha (mil/AB
%   blend by percent_ab), and dc_i is the per-condition (NOT averaged) drag term.
%   Ps-based climbs also average TSFC between start and end (average_tsfc = true,
%   Miss-tab D33/L33). A same-condition leg (Climb2: dh = dV = 0) yields t = 0.
%
%   Uses the standard dynamic pressure q = 0.5*rho*V^2 and handles ACCEL with
%   this same drag+energy master equation, not Brandt's Miss-tab q_43 override
%   or its separate thrust-based accel form (fuel = alpha*T_SL*cT*t, Miss!C13).
%   These generalizations make the L2 Brandt-stack total run ~+8.9% high vs
%   BrandtMission.m; see mission_comparison_report.m for the per-leg breakdown.

    methods
        function obj = ClimbSegment()
            obj.average_tsfc = true;
        end

        function t = segment_time(obj, ctx)
            st_s = obj.start_state();
            st_e = obj.end_state();
            V_s = st_s.V;  V_e = st_e.V;

            WS = ctx.W_TO / ctx.geom.get_S_ref();
            Wf = obj.W_before / ctx.W_TO;
            TW = ctx.prop.T_SL / ctx.W_TO;

            ps = ctx.aero.drag_polar(st_s);
            pe = ctx.aero.drag_polar(st_e);
            CDo_s = ps.CD0 + obj.cd0_increment;
            CDo_e = pe.CD0 + obj.cd0_increment;
            xs = Wf / st_s.q;
            xe = Wf / st_e.q;
            dc_s = CDo_s / WS + ps.K1 * xs^2 * WS + ps.K2 * xs;
            dc_e = CDo_e / WS + pe.K1 * xe^2 * WS + pe.K2 * xe;

            a_s = MissionEquations.select_alpha(ctx.prop, st_s, obj.percent_ab);
            a_e = MissionEquations.select_alpha(ctx.prop, st_e, obj.percent_ab);

            Ps_s = V_s * (a_s / Wf * TW - st_s.q * dc_s);
            Ps_e = V_e * (a_e / Wf * TW - st_e.q * dc_e);
            Ps = (Ps_s + Ps_e) / 2;

            dh = obj.alt_end_ft - obj.alt_start_ft;
            dV = V_e - V_s;
            Vsum = V_s + V_e;

            t_alt = 0;
            t_vel = 0;
            if abs(Ps) > 1e-6
                t_alt = abs(dh / Ps / 60);
                dVdt = 32.2 * Ps / Vsum * 2;
                if abs(dVdt) > 1e-6
                    t_vel = abs(dV / dVdt / 60);
                end
            end
            t = t_alt + t_vel;
        end
    end
end
