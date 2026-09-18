%% run_ttpa_sizing.m
%  IHW3a - TTPA sizing loop, end to end.
%
%  Couples the IHW1 mission analysis and the IHW2 constraint analysis into
%  one calculation and iterates it to a converged airplane.
%
%  What this script does, in order:
%     1  builds the discipline bundle
%     2  reads the sizing options out of the requirements JSON
%     3  runs the two-state (W_TO, P_SL) loop
%     4  prints the iteration history
%     5  prints the sized airplane - weights, geometry, propulsion
%     6  prints three independent cross-checks
%     7  runs the two post-convergence checks: wing fuel volume, gear loads
%     8  plots the convergence history
%     9  plots the P-S sizing diagram - the whole design space the converged
%        airplane sits in
%
%  Run it from this folder.  No arguments, no edits needed.

clear; clc; close all

% Step 9 sizes a few thousand airplanes, one per grid cell, and takes about
% 15 seconds. Set this false to skip it. run_ttpa_PS_diagram.m draws the same
% diagram on a finer grid and exports it.
MAKE_PS_DIAGRAM = true;

%% ---------------------------------------------------------------- 1. build
obj = ttpa_disciplines();
json_path = ttpa_requirements_path();
J = jsondecode(fileread(json_path));

fprintf('%% -- Disciplines loaded: %s -- %%\n', class(obj.geom));

%% --------------------------------------------------------- 2. sizing options
S  = J.sizing;
C  = J.constraints;

opts.W_TO_guess        = S.W_TO_guess_lbf;
opts.design_point_mode = string(S.design_point_mode);
opts.tol_rel           = S.tol_rel;
opts.max_iter          = S.max_iter;
opts.relax_W           = S.relaxation_W;
opts.relax_P           = S.relaxation_P;

opts.WS_sweep = linspace(C.wing_loading_range_psf(1), ...
                         C.wing_loading_range_psf(2), ...
                         C.wing_loading_points);

opts.selected.WS = C.design_point.wing_loading_psf;
opts.selected.WP = C.design_point.power_loading_lb_per_hp;

fprintf('\nSizing options\n');
fprintf('  starting guess        %8.1f lbf\n',  opts.W_TO_guess);
fprintf('  design point mode     %8s\n',        opts.design_point_mode);
fprintf('  selected design point %8.2f lbf/ft^2 , %.2f lbf/hp\n', ...
        opts.selected.WS, opts.selected.WP);
fprintf('  tolerance             %8.1e   relaxation  W %.2f  P %.2f\n', ...
        opts.tol_rel, opts.relax_W, opts.relax_P);

%% ------------------------------------------------------------- 3. the loop
result = sizing_loop(obj, opts);

%% ------------------------------------------------------- 4. iteration history
h = result.history;
hist_table = table([h.iter]', [h.W_TO]', [h.P_SL]', [h.S_ref]', ...
                   [h.CD0]',  [h.LD_max]', [h.W_OEW]', [h.W_fuel]', ...
                   [h.denom]', [h.W_TO_new]', [h.res_W]', [h.res_P]', ...
    'VariableNames', {'iter','W_TO','P_SL','S_ref','CD0','LD_max', ...
                      'OEW','W_fuel','useful_frac','W_TO_new','res_W','res_P'});

fprintf('\n============================ ITERATION HISTORY ===========================\n');
if height(hist_table) > 14
    % Long histories are mostly the tail creeping in; show the ends.
    disp(head(hist_table, 7));
    fprintf('   ... %d iterations omitted ...\n\n', height(hist_table) - 14);
    disp(tail(hist_table, 7));
else
    disp(hist_table);
end

if result.converged
    fprintf('CONVERGED in %d iterations.\n', result.n_iter);
else
    fprintf('DID NOT CONVERGE in %d iterations.\n', result.n_iter);
end

%% --------------------------------------------------------- 5. sized airplane
bd = result.OEW_breakdown;

fprintf('\n============================== SIZED AIRPLANE ============================\n');

fprintf('\nWEIGHTS                                     lbf      fraction of W_TO\n');
fprintf('  takeoff gross weight  W_TO           %9.1f\n',            result.W_TO);
fprintf('  operating empty       OEW            %9.1f      %7.4f\n', result.W_OEW,    result.OEW_fraction);
fprintf('  mission fuel          W_fuel         %9.1f      %7.4f\n', result.W_fuel,   result.fuel_fraction);
fprintf('  payload               W_payload      %9.1f      %7.4f\n', result.W_payload, result.W_payload/result.W_TO);
fprintf('  ---------------------------------------------------------\n');
fprintf('  useful-load fraction  (the closure denominator)  %7.4f\n', result.useful_load_fraction);

fprintf('\nEMPTY-WEIGHT BUILD-UP  [Raymer Table 15.2, General Aviation]\n');
fprintf('  wing              2.5 psf x %7.2f ft^2 exposed   %8.1f lbf\n', obj.geom.S_exposed_wing,  bd.wing);
fprintf('  horizontal tail   2.0 psf x %7.2f ft^2           %8.1f lbf\n', obj.geom.S_ht,            bd.horizontal_tail);
fprintf('  vertical tail     2.0 psf x %7.2f ft^2           %8.1f lbf\n', obj.geom.S_vt,            bd.vertical_tail);
fprintf('  fuselage          1.4 psf x %7.2f ft^2 wetted    %8.1f lbf\n', obj.geom.S_wet_fuselage,  bd.fuselage);
fprintf('  landing gear      0.057 x W_TO                    %8.1f lbf\n', bd.landing_gear);
fprintf('  installed engines 1.4 x %6.1f lbf bare            %8.1f lbf\n', bd.engine_bare_total, bd.installed_engine);
fprintf('  all else empty    0.10 x W_TO                     %8.1f lbf\n', bd.all_else_empty);
fprintf('  ---------------------------------------------------------\n');
fprintf('  total OEW                                         %8.1f lbf\n', bd.total);

fprintf('\nDESIGN POINT  (mode: %s)\n', result.design_point.mode);
fprintf('  sized to              W/S = %6.2f lbf/ft^2 , W/P = %5.2f lbf/hp\n', result.WS, result.WP);
fprintf('  least-engine corner   W/S = %6.2f lbf/ft^2 , W/P = %5.2f lbf/hp\n', ...
        result.design_point.WS_optimum, result.design_point.WP_optimum);
fprintf('  wing-loading wall     W/S = %6.2f lbf/ft^2   (landing)\n', result.design_point.WS_wall);
fprintf('  driving condition     %s\n', result.design_point.driving);
if result.design_point.feasible
    fprintf('  FEASIBLE.  power margin %+.1f %%   wing-loading margin %+.1f %%\n', ...
            100*result.design_point.WP_margin, 100*result.design_point.WS_margin);
else
    fprintf('  *** NOT FEASIBLE ***  power margin %+.1f %%   wing-loading margin %+.1f %%\n', ...
            100*result.design_point.WP_margin, 100*result.design_point.WS_margin);
end

fprintf('\nWING\n');
fprintf('  reference area   S_ref  %8.2f ft^2      aspect ratio  %5.2f\n', obj.geom.S_ref, obj.geom.AR);
fprintf('  exposed area            %8.2f ft^2      taper ratio   %5.2f\n', obj.geom.S_exposed_wing, obj.geom.taper);
fprintf('  span             b      %8.2f ft        root chord    %5.2f ft\n', obj.geom.b, obj.geom.c_root);
fprintf('  MAC                     %8.2f ft        tip chord     %5.2f ft\n', obj.geom.MAC, obj.geom.c_tip);
fprintf('  y_MAC                   %8.2f ft\n', obj.geom.y_MAC);

fprintf('\nTAILS  [volume-coefficient method]\n');
fprintf('  horizontal  V_h %.3f, arm %4.1f ft  ->  S_ht %6.2f ft^2 , b %5.2f ft , MAC %4.2f ft\n', ...
        obj.geom.V_ht, obj.geom.L_ht, obj.geom.S_ht, obj.geom.b_ht, obj.geom.MAC_ht);
fprintf('  vertical    V_v %.3f, arm %4.1f ft  ->  S_vt %6.2f ft^2 , b %5.2f ft , MAC %4.2f ft\n', ...
        obj.geom.V_vt, obj.geom.L_vt, obj.geom.S_vt, obj.geom.b_vt, obj.geom.MAC_vt);

fprintf('\nFUSELAGE  [fixed by the cabin - does not change in the loop]\n');
fprintf('  length %5.2f ft , width %4.2f ft , height %4.2f ft , fineness %4.2f\n', ...
        obj.geom.l_fus, obj.geom.w_fus, obj.geom.h_fus, obj.geom.fineness_ratio);

fprintf('\nPROPULSION\n');
fprintf('  installed power  P_SL   %8.1f hp total , %.1f hp per engine (%d engines)\n', ...
        result.P_SL, result.P_engine, obj.prop.n_engines);
fprintf('  bare engine weight      %8.1f lbf each  [Raymer Table 10.4, opposed]\n', bd.engine_bare_each);
fprintf('  bare engine length      %8.2f ft        nacelle %.2f ft\n', ...
        obj.prop.engine_length(), obj.geom.l_nacelle);

fprintf('\nAERODYNAMICS\n');
fprintf('  wetted area      S_wet  %8.2f ft^2      S_wet/S_ref  %5.3f\n', obj.geom.S_wet, obj.geom.S_wet_over_S_ref);
fprintf('    wing %6.1f   HT %5.1f   VT %5.1f   fuselage %6.1f   nacelles %5.1f  ft^2\n', ...
        obj.geom.S_wet_wing, obj.geom.S_wet_ht, obj.geom.S_wet_vt, ...
        obj.geom.S_wet_fuselage, obj.geom.S_wet_nacelle);
fprintf('  clean CD0               %8.5f          [Raymer Eq. 12.23, Cfe = %.4f]\n', result.CD0, obj.aero.Cfe);
fprintf('  Oswald e %.4f , K %.5f , L/D max %.3f\n', obj.aero.e, obj.aero.K, result.LD_max);

%% ------------------------------------------------------------ 6. cross-checks
fprintf('\n=============================== CROSS-CHECKS =============================\n');

d_CD0 = 100 * (result.CD0 - obj.aero.CD0_reference) / obj.aero.CD0_reference;
fprintf('\n1. Drag.  Geometry build-up against the fixed IHW2 value.\n');
fprintf('     CD0 from S_wet/S_ref  %.5f     IHW2 fixed value  %.5f     %+.1f %%\n', ...
        result.CD0, obj.aero.CD0_reference, d_CD0);

d_OEW = 100 * (result.W_OEW - result.OEW_statistical) / result.OEW_statistical;
fprintf('\n2. Empty weight.  Component build-up against the IHW1 regression.\n');
fprintf('     Raymer Table 15.2 build-up  %.1f lbf\n', result.W_OEW);
fprintf('     0.911 * W_TO^0.947          %.1f lbf     %+.1f %%\n', ...
        result.OEW_statistical, d_OEW);
fprintf('     Two independent methods. Agreement within a few percent is the\n');
fprintf('     evidence that the geometry is right.\n');

fprintf('\n3. Closure.  The four weights must add to the takeoff weight.\n');
sum_check = result.W_OEW + result.W_fuel + result.W_payload;
fprintf('     OEW + fuel + payload  %.2f lbf     W_TO  %.2f lbf     residual %.2e lbf\n', ...
        sum_check, result.W_TO, sum_check - result.W_TO);

fprintf('\n4. Against the IHW1/IHW2 baseline, which held W_TO fixed at 5354 lbf.\n');
fprintf('     %-22s %10s %10s %9s\n', '', 'IHW1/IHW2', 'IHW3a', 'change');
base = struct('W_TO', 5354, 'OEW', 3094, 'W_fuel', 1060, ...
              'S_ref', 5354/opts.selected.WS, 'P_SL', 5354/opts.selected.WP);
pr = @(name, b, v, u) fprintf('     %-22s %10.1f %10.1f %8.1f %% %s\n', ...
        name, b, v, 100*(v-b)/b, u);
pr('takeoff weight',   base.W_TO,   result.W_TO,   'lbf');
pr('empty weight',     base.OEW,    result.W_OEW,  'lbf');
pr('mission fuel',     base.W_fuel, result.W_fuel, 'lbf');
pr('wing area',        base.S_ref,  result.S_ref,  'ft^2');
pr('installed power',  base.P_SL,   result.P_SL,   'hp');
fprintf('     The IHW1 answer came from a regression that cannot see the wing,\n');
fprintf('     the tails or the engine. IHW3a can, so a few percent of movement\n');
fprintf('     is the expected result, not an error.\n');

%% ------------------------------------------------- 7. post-convergence checks
fprintf('\n========================= POST-CONVERGENCE CHECKS ========================\n');

[fuel_ok, V_ft3, W_cap, fuel_margin] = wing_fuel_check(result.W_fuel, obj);
fprintf('\nWing fuel volume  [Torenbeek]\n');
fprintf('  usable volume     %6.2f ft^3\n', V_ft3);
fprintf('  capacity          %6.0f lbf at %.1f lb/ft^3\n', W_cap, obj.wts.rho_fuel);
fprintf('  mission needs     %6.0f lbf\n', result.W_fuel);
if fuel_ok
    fprintf('  OK - %.0f %% spare.\n', 100*fuel_margin);
else
    fprintf('  *** SHORT by %.0f %%. Change the planform: thicker root, less\n', -100*fuel_margin);
    fprintf('      taper, or more area.\n');
end

[P_nose, P_main, P_strut] = landing_gear_loads(result.W_TO, obj);
fprintf('\nLanding gear static loads  [Raymer Ch. 11, tricycle]\n');
fprintf('  nose gear                     %7.1f lbf   (W x l_m/l_d = %.2f)\n', P_nose, obj.geom.l_m_over_l_d);
fprintf('  main gear, both struts        %7.1f lbf   (W x l_n/l_d = %.2f)\n', P_main, obj.geom.l_n_over_l_d);
fprintf('  main gear, per strut          %7.1f lbf   -> Raymer Table 11.2 for the tyre\n', P_strut);

%% ------------------------------------------------------------------ 8. plot
plot_sizing_convergence(result);

%% --------------------------------------------------- 9. P-S sizing diagram
%  The sizing loop answers "what airplane meets the requirements?". The P-S
%  diagram answers the wider question: of every (power, wing) combination,
%  which ones give an airplane that closes AND meets the requirements, and
%  what does each one cost in fuel? The converged design is one point in it.
%
%  Every cell is a separately sized airplane, so this is the expensive part
%  of the script.
if MAKE_PS_DIAGRAM
    fprintf('\n=========================== P-S SIZING DIAGRAM ===========================\n');

    d = TtpaPSDiagram(obj);

    % Bracket the converged design. Coarser than run_ttpa_PS_diagram.m uses,
    % to keep this script quick.
    S_grid = linspace(100, 230, 45);    % ft^2
    P_grid = linspace(300, 900, 45);    % hp

    fprintf('\n  sizing %d x %d = %d airplanes, one per cell ...\n', ...
            numel(P_grid), numel(S_grid), numel(P_grid)*numel(S_grid));
    t0 = tic;
    fg = d.fuel_grid(P_grid, S_grid);
    fprintf('  done in %.1f s.  %d of %d cells are feasible', ...
            toc(t0), nnz(fg.feasible), numel(fg.feasible));
    if any(~isfinite(fg.W0), 'all')
        fprintf('; %d do not close at all', nnz(~isfinite(fg.W0)));
    end
    fprintf('.\n');

    markers = struct( ...
        'P', {result.P_SL, 5354 / opts.selected.WP}, ...
        'S', {result.S_ref, 5354 / opts.selected.WS}, ...
        'label', {sprintf('IHW3a sized  (%.0f hp, %.0f ft^2)', result.P_SL, result.S_ref), ...
                  sprintf('IHW1/IHW2 baseline  (%.0f hp, %.0f ft^2)', ...
                          5354/opts.selected.WP, 5354/opts.selected.WS)});

    [~, ps] = d.plot('S_grid', S_grid, 'P_grid', P_grid, ...
                     'markers', markers, 'grid', fg);

    lp = ps.least_power;
    fprintf('\n  least-power airplane    P %7.1f hp , S %6.1f ft^2 , W_TO %7.1f lbf\n', ...
            lp.P, lp.S, lp.W);
    fprintf('  IHW3a design            P %7.1f hp , S %6.1f ft^2 , W_TO %7.1f lbf\n', ...
            result.P_SL, result.S_ref, result.W_TO);
    fprintf('  cost of the margin      %+7.1f hp , %+6.1f ft^2 , %+7.1f lbf\n', ...
            result.P_SL - lp.P, result.S_ref - lp.S, result.W_TO - lp.W);
    fprintf('\n  The least-power point is where Takeoff (power falling with wing\n');
    fprintf('  area) crosses Cruise Speed (power rising with it). It is the same\n');
    fprintf('  corner the IHW2 matching diagram finds at (W/S, W/P) = (%.2f, %.2f),\n', ...
            result.design_point.WS_optimum, result.design_point.WP_optimum);
    fprintf('  now in dimensional form. Sizing to it instead would give the lighter\n');
    fprintf('  airplane above - with zero margin on every requirement.\n');

    % TtpaPSDiagram MUTATES the discipline bundle: it leaves geom/prop at the
    % LAST CELL VISITED. Put the converged design back, so anything that
    % inspects obj after this script still sees the airplane that was sized.
    obj.geom.S_ref = result.S_ref;
    obj.prop.P_SL  = result.P_SL;
end

fprintf('\nDone.\n');
