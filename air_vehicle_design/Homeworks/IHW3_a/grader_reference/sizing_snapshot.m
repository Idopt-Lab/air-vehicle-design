function row = sizing_snapshot(obj, core)
%SIZING_SNAPSHOT  Record the whole airplane at the end of one sizing pass.
%
%   row = sizing_snapshot(obj, core)
%
%   GIVEN - you do not write this. sizing_pass calls it as its last line.
%
%   core is the struct sizing_pass builds: the numbers the loop itself
%   computes on this pass.
%       .W_TO .P_SL .S_ref          the three states the pass STARTED from
%       .WS .WP .WS_wall            the constraint-analysis corner and wall
%       .W_fuel .fuel_fraction      mission fuel at W_TO
%       .OEW_breakdown              struct from obj.wts.OEW_breakdown(W_TO)
%       .denom .W_TO_new            the takeoff-weight closure
%       .P_SL_new .S_ref_new        the new engine and wing
%       .res_W .res_P .res_S        relative residuals, BEFORE relaxation
%
%   row adds to that everything the airplane is at this pass - span, MAC,
%   tails, wetted areas, C_D0, engine, all seven weight rows - read live off
%   the discipline objects. Call it while the airplane is still in the state
%   this pass flew, which is why it is inside sizing_pass and not after it:
%   every field of one row then describes ONE airplane.

    g = obj.geom;  a = obj.aero;  pr = obj.prop;  bd = core.OEW_breakdown;

    % ---- the loop's own numbers --------------------------------------------
    row.iter  = NaN;                         % set by sizing_mainloop
    row.W_TO  = core.W_TO;
    row.P_SL  = core.P_SL;
    row.S_ref = core.S_ref;
    row.WS    = core.WS;
    row.WP    = core.WP;

    % ---- which constraint sets the corner, and the margins -----------------
    [WP_lim, ~, names] = run_constraints(core.WS, obj);
    [WP_binding, kd]   = min(WP_lim(:, 1));
    row.driving    = string(names(kd));
    row.WS_wall    = core.WS_wall;
    row.WS_margin  = (core.WS_wall - core.WS) / core.WS_wall;
    row.WP_margin  = (WP_binding - core.WP) / WP_binding;
    row.wall_ok    = core.WS <= core.WS_wall;
    row.WP_binding = WP_binding;

    % ---- wing planform -----------------------------------------------------
    row.b              = g.b;
    row.MAC            = g.MAC;
    row.c_root         = g.c_root;
    row.c_tip          = g.c_tip;
    row.y_MAC          = g.y_MAC;
    row.S_exposed_wing = g.S_exposed_wing;
    row.wing_fuel_ft3  = g.wing_fuel_volume();

    % ---- tails -------------------------------------------------------------
    row.S_ht   = g.S_ht;
    row.S_vt   = g.S_vt;
    row.b_ht   = g.b_ht;
    row.b_vt   = g.b_vt;
    row.MAC_ht = g.MAC_ht;
    row.MAC_vt = g.MAC_vt;

    % ---- engine and nacelle ------------------------------------------------
    [W_bare_total, W_bare_each] = pr.engine_weight();
    row.P_engine         = pr.P_engine;
    row.l_engine         = pr.engine_length();
    row.l_nacelle        = g.l_nacelle;
    row.W_eng_bare_each  = W_bare_each;
    row.W_eng_bare_total = W_bare_total;

    % ---- wetted areas ------------------------------------------------------
    row.S_wet_wing       = g.S_wet_wing;
    row.S_wet_ht         = g.S_wet_ht;
    row.S_wet_vt         = g.S_wet_vt;
    row.S_wet_fus        = g.S_wet_fuselage;
    row.S_wet_nac        = g.S_wet_nacelle;
    row.S_wet            = g.S_wet;
    row.S_wet_over_S_ref = g.S_wet_over_S_ref;

    % ---- aerodynamics ------------------------------------------------------
    row.CD0    = a.CD0;
    row.e      = a.e;
    row.K      = a.K;
    row.LD_max = a.LD_max;

    % ---- mission and payload -----------------------------------------------
    row.W_fuel        = core.W_fuel;
    row.fuel_fraction = core.fuel_fraction;
    row.W_payload     = obj.wts.payload();

    % ---- the seven rows of the weight build-up -----------------------------
    row.W_wing          = bd.wing;
    row.W_ht            = bd.horizontal_tail;
    row.W_vt            = bd.vertical_tail;
    row.W_fus           = bd.fuselage;
    row.W_gear          = bd.landing_gear;
    row.W_eng_inst      = bd.installed_engine;
    row.W_else          = bd.all_else_empty;
    row.OEW             = bd.total;
    row.OEW_fraction    = bd.total / core.W_TO;
    row.OEW_statistical = obj.wts.OEW_statistical(core.W_TO);

    % ---- closure and residuals ---------------------------------------------
    row.denom     = core.denom;
    row.W_TO_new  = core.W_TO_new;
    row.P_SL_new  = core.P_SL_new;
    row.S_ref_new = core.S_ref_new;
    row.res_W     = core.res_W;
    row.res_P     = core.res_P;
    row.res_S     = core.res_S;
end
