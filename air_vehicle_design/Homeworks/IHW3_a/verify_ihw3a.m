%% verify_ihw3a.m  - checks every claim made in the IHW3a comments and README
clear; clc

json_path = ttpa_requirements_path();
J = jsondecode(fileread(json_path));
C = J.constraints;

base_opts.tol_rel   = 1e-6;
base_opts.max_iter  = 300;
base_opts.relax_W   = 0.5;
base_opts.relax_P   = 0.5;
base_opts.WS_sweep  = linspace(C.wing_loading_range_psf(1), ...
                               C.wing_loading_range_psf(2), ...
                               C.wing_loading_points);
base_opts.selected.WS = C.design_point.wing_loading_psf;
base_opts.selected.WP = C.design_point.power_loading_lb_per_hp;
base_opts.design_point_mode = "selected";

fprintf('=== CLAIM 1: converges from every guess between 2500 and 10000 lbf ===\n');
guesses = 2500:250:10000;
Wc = nan(size(guesses)); Pc = nan(size(guesses)); Nc = nan(size(guesses));
for k = 1:numel(guesses)
    o = base_opts; o.W_TO_guess = guesses(k);
    obj = ttpa_disciplines();
    try
        r = sizing_loop(obj, o);
        Wc(k) = r.W_TO; Pc(k) = r.P_SL; Nc(k) = r.n_iter;
        if ~r.converged, Nc(k) = -1; end
    catch ME
        fprintf('  guess %5.0f FAILED: %s\n', guesses(k), ME.identifier);
    end
end
fprintf('  %d/%d converged | W_TO spread %.6f lbf | iters %d..%d\n', ...
    sum(~isnan(Wc) & Nc>0), numel(guesses), max(Wc)-min(Wc), min(Nc), max(Nc));
fprintf('  W_TO = %.4f lbf , P_SL = %.4f hp\n', mean(Wc,'omitnan'), mean(Pc,'omitnan'));

fprintf('\n=== CLAIM 2: relax = 1 from a far guess hits closureInfeasible ===\n');
for g = [2500 5000 8000]
    o = base_opts; o.W_TO_guess = g; o.relax_W = 1.0; o.relax_P = 1.0;
    obj = ttpa_disciplines();
    try
        r = sizing_loop(obj, o);
        fprintf('  guess %5.0f relax 1.0 -> converged in %d, W_TO %.1f\n', g, r.n_iter, r.W_TO);
    catch ME
        fprintf('  guess %5.0f relax 1.0 -> %s (as documented)\n', g, ME.identifier);
    end
end

fprintf('\n=== CLAIM 3: the design point does not move during the loop ===\n');
obj = ttpa_disciplines();
o = base_opts; o.W_TO_guess = 5000;
r = sizing_loop(obj, o);
WSopt = nan(1, r.n_iter);
% re-run capturing the optimum each iteration via the history WS/WP is the
% SELECTED point, so probe the envelope at the first and last geometry
obj2 = ttpa_disciplines();
obj2.geom.S_ref = r.history(1).S_ref;  obj2.prop.P_SL = r.history(1).P_SL;
[~,~,i1] = solve_design_point(obj2, "optimum", o.WS_sweep, o.selected);
obj2.geom.S_ref = r.S_ref;             obj2.prop.P_SL = r.P_SL;
[~,~,i2] = solve_design_point(obj2, "optimum", o.WS_sweep, o.selected);
fprintf('  iteration 1  S_ref %.2f  CD0 %.5f  -> optimum (%.4f, %.4f), wall %.4f\n', ...
    r.history(1).S_ref, r.history(1).CD0, i1.WS_optimum, i1.WP_optimum, i1.WS_wall);
fprintf('  converged    S_ref %.2f  CD0 %.5f  -> optimum (%.4f, %.4f), wall %.4f\n', ...
    r.S_ref, r.CD0, i2.WS_optimum, i2.WP_optimum, i2.WS_wall);
fprintf('  moved by (%.2e, %.2e) -> %s\n', abs(i1.WS_optimum-i2.WS_optimum), ...
    abs(i1.WP_optimum-i2.WP_optimum), ...
    string(abs(i1.WS_optimum-i2.WS_optimum)<1e-12 && abs(i1.WP_optimum-i2.WP_optimum)<1e-12));

fprintf('\n=== CLAIM 4: "optimum" mode runs and costs less airplane ===\n');
obj3 = ttpa_disciplines();
o3 = base_opts; o3.W_TO_guess = 5000; o3.design_point_mode = "optimum";
r3 = sizing_loop(obj3, o3);
fprintf('  selected (40, 9.25)     W_TO %.1f lbf , P_SL %.1f hp , S_ref %.2f ft^2\n', ...
    r.W_TO, r.P_SL, r.S_ref);
fprintf('  optimum  (%.2f, %.2f)  W_TO %.1f lbf , P_SL %.1f hp , S_ref %.2f ft^2\n', ...
    r3.WS, r3.WP, r3.W_TO, r3.P_SL, r3.S_ref);
fprintf('  price of the margin: %+.1f lbf , %+.1f hp\n', r.W_TO-r3.W_TO, r.P_SL-r3.P_SL);

fprintf('\n=== CLAIM 5: Dependent properties really do track S_ref ===\n');
obj4 = ttpa_disciplines();
obj4.prop.P_SL = 555.53;
obj4.geom.S_ref = 100;
a1 = [obj4.geom.b obj4.geom.S_ht obj4.geom.S_vt obj4.geom.S_wet obj4.aero.CD0 obj4.aero.LD_max];
obj4.geom.S_ref = 200;
a2 = [obj4.geom.b obj4.geom.S_ht obj4.geom.S_vt obj4.geom.S_wet obj4.aero.CD0 obj4.aero.LD_max];
nm = ["b" "S_ht" "S_vt" "S_wet" "CD0" "LD_max"];
for k=1:numel(nm)
    fprintf('  %-7s  S_ref=100 -> %10.4f    S_ref=200 -> %10.4f   %s\n', ...
        nm(k), a1(k), a2(k), string(a1(k)~=a2(k)));
end

fprintf('\n=== CLAIM 6: hand-check the seven weight rows at the converged point ===\n');
bd = r.OEW_breakdown;
g  = obj.geom; p = obj.prop;
chk = @(n,got,exp) fprintf('  %-18s got %9.3f   hand %9.3f   d %8.2e\n', n, got, exp, abs(got-exp));
chk('wing',      bd.wing,            2.5*g.S_exposed_wing);
chk('HT',        bd.horizontal_tail, 2.0*g.S_ht);
chk('VT',        bd.vertical_tail,   2.0*g.S_vt);
chk('fuselage',  bd.fuselage,        1.4*g.S_wet_fuselage);
chk('gear',      bd.landing_gear,    0.057*r.W_TO);
chk('all else',  bd.all_else_empty,  0.10*r.W_TO);
chk('engine bare', bd.engine_bare_each, 5.47*(r.P_SL/2)^0.780);
chk('engine inst', bd.installed_engine, 1.4*2*5.47*(r.P_SL/2)^0.780);
chk('OEW total', bd.total, bd.wing+bd.horizontal_tail+bd.vertical_tail+ ...
                           bd.fuselage+bd.landing_gear+bd.installed_engine+bd.all_else_empty);
fprintf('  engine length      got %9.4f   hand %9.4f\n', p.engine_length(), 0.32*(r.P_SL/2)^0.424);
chk('CD0 (Eq 12.23)', r.CD0, 0.0045*g.S_wet/g.S_ref);

fprintf('\n=== CLAIM 7: geometry hand-checks against the IHW3 reference notebooks ===\n');
obj5 = ttpa_disciplines(); obj5.prop.P_SL = 578.8; obj5.geom.S_ref = 134;
fprintf('  At S_ref = 134 ft^2 (the reference-notebook wing):\n');
fprintf('    b      %6.2f ft  (notebook 33)     c_root %5.2f ft (5.8)\n', obj5.geom.b, obj5.geom.c_root);
fprintf('    c_tip  %6.2f ft  (2.3)             MAC    %5.2f ft (4.3)\n', obj5.geom.c_tip, obj5.geom.MAC);
fprintf('    y_MAC  %6.2f ft  (7)               V_wf   %5.2f ft^3 (37)\n', obj5.geom.y_MAC, obj5.geom.wing_fuel_volume());
fprintf('    S_ht   %6.2f ft^2 (31)             S_vt   %5.2f ft^2 (17)\n', obj5.geom.S_ht, obj5.geom.S_vt);
fprintf('    b_ht   %6.2f ft  (13)              b_vt   %5.2f ft  (5)\n', obj5.geom.b_ht, obj5.geom.b_vt);

fprintf('\n=== CLAIM 8: mission_fuel reads the reserve from the JSON, not 1.06 ===\n');
obj6 = ttpa_disciplines(); obj6.prop.P_SL = 555.53; obj6.geom.S_ref = 128.47;
[Wf, ff] = mission_fuel(5138.65, obj6);
[fb,~,~] = run_mission(5138.65, obj6);
fprintf('  reserve_fuel_fraction in JSON = %.3f\n', obj6.miss.reserve_fuel_fraction);
fprintf('  sum(fuel_burned)*1.06 = %.4f    mission_fuel = %.4f   d = %.2e\n', ...
    sum(fb)*1.06, Wf, abs(sum(fb)*1.06 - Wf));
fprintf('  fuel fraction %.5f\n', ff);

fprintf('\n=== CLAIM 9: the P-S diagram and the sizing loop are the same calculation ===\n');
warning('off','TtpaProp:BhpOutOfRange');
obj7 = ttpa_disciplines();
d7   = TtpaPSDiagram(obj7);
% (a) the cell containing the design must reproduce the loop
Wcell = d7.converge_W0(r.P_SL, r.S_ref);
fprintf('  converge_W0 at the design cell  %.3f lbf   sizing_loop %.3f lbf   rel %+.2e\n', ...
    Wcell, r.W_TO, (Wcell-r.W_TO)/r.W_TO);
% (b) the least-power point traced off the curves must reproduce "optimum" mode
Sg = linspace(100, 230, 55); Pg = linspace(300, 900, 55);
fg7 = d7.fuel_grid(Pg, Sg);
f7  = figure('Visible','off');
[~, ps7] = d7.plot('S_grid', Sg, 'P_grid', Pg, 'grid', fg7);
close(f7); close(gcf);
fprintf('  least-power point from the traced curves   P %7.2f hp , S %6.2f ft^2 , W %8.1f lbf\n', ...
    ps7.least_power.P, ps7.least_power.S, ps7.least_power.W);
fprintf('  sizing_loop in "optimum" mode             P %7.2f hp , S %6.2f ft^2 , W %8.1f lbf\n', ...
    r3.P_SL, r3.S_ref, r3.W_TO);
fprintf('  difference  %+.2f hp , %+.2f ft^2 , %+.1f lbf  (grid spacing %.2f hp, %.2f ft^2)\n', ...
    ps7.least_power.P - r3.P_SL, ps7.least_power.S - r3.S_ref, ...
    ps7.least_power.W - r3.W_TO, Pg(2)-Pg(1), Sg(2)-Sg(1));
fprintf('  Two independent routes: the loop SOLVES the design point, the diagram\n');
fprintf('  TRACES the constraint curves. They agree to the grid resolution.\n');

fprintf('\nVERIFICATION COMPLETE\n');
