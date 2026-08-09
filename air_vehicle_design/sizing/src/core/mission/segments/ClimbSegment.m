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
%   Uses the standard dynamic pressure q = 0.5*rho*V^2 (via AircraftState), not
%   Brandt's Miss-tab "Row 43" averaged-speed q override, and handles ACCEL with
%   this same drag+energy master equation rather than Brandt's separate
%   thrust-based accel form (fuel = alpha*T_SL*cT*t, Miss!C13). Both are
%   deliberate generalizations (user decision 2026-08-09: keep the physically-
%   clean, general L2 form over reproducing those Brandt-Excel idiosyncrasies).
%
%   CONSEQUENCE for the Brandt-stack comparison (INFORMATIONAL, not a bug): with
%   the Brandt discipline stack, L2 reproduces BrandtMission.m to ~0-4% on
%   takeoff/cruise/dash/combat/cruise2/loiter, but ACCEL runs ~+20% and CLIMB
%   ~+62% high (total ~+8.9%, 6532 vs 6000.4 lb) precisely because of the two
%   generalizations above -- porting q_43 + the thrust-accel form would close
%   that gap but was explicitly declined. See mission_comparison_report.m.

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
