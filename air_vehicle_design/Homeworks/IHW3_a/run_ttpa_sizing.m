%% run_ttpa_sizing.m
%  IHW3a - TTPA sizing, end to end, on the PRELIMINARY DESIGN FRAMEWORK.
%
%  The framework, box by box, and where each one lives:
%
%      Tail sizing     TtpaGeom.S_ht / S_vt        Dependent on S_ref
%      Drag polar II   TtpaAero.CD0                Dependent on S_wet/S_ref
%      Wing loading    W_0 / S_ref                 inside sizing_loop
%      Design diagram  design_diagram(WS, obj)     read at ONE wing loading
%      Fuel fraction   mission_fuel(W_0, obj)      L1 or L2
%      Empty weight    TtpaWeights.OEW(W_0)        II or III
%      MTOW iteration  SizingSteps.togw_update     red loop on W_0
%      P_0 iteration   P_0 = W_0/(W/P)             red loop on P_0
%
%  Steps:
%     1  build the discipline bundle
%     2  read the sizing options
%     3  run the loop
%     4  iteration history
%     5  the sized airplane
%     6  cross-checks
%     7  METHOD COMPARISON - every switch, on and off
%     8  post-convergence checks
%     9  convergence plot
%    10  P-S sizing diagram
%
%  Run it from this folder. No arguments, no edits needed.

clear; clc; close all

MAKE_PS_DIAGRAM = true;    % step 10 sizes a few thousand airplanes (~1 min)
RUN_COMPARISON  = true;    % step 7 re-sizes the airplane four more times

%% ---------------------------------------------------------------- 1. build
obj = ttpa_disciplines();
json_path = ttpa_requirements_path();
J = jsondecode(fileread(json_path));

%% --------------------------------------------------------- 2. sizing options
S = J.sizing;
C = J.constraints;

opts.mode              = string(S.mode);
opts.S_ref             = S.S_ref_ft2;
opts.W_TO_guess        = S.W_TO_guess_lbf;
opts.design_point_mode = string(S.design_point_mode);
opts.tol_rel           = S.tol_rel;
opts.max_iter          = S.max_iter;
% Relaxation is mode-dependent, and measurably so - see the JSON note. The
% fixed-wing-area mode rings, because a heavier airplane raises W/S, which
% the takeoff constraint answers with a bigger engine, which is heavier again.
opts.relax_W = S.relaxation_W;
opts.relax_P = S.relaxation_P;
if opts.mode == "fixed_wing_area" && isfield(S, 'relaxation_fixed_wing_area')
    opts.relax_W = S.relaxation_fixed_wing_area;
    opts.relax_P = S.relaxation_fixed_wing_area;
end
opts.WS_sweep = linspace(C.wing_loading_range_psf(1), ...
                         C.wing_loading_range_psf(2), ...
                         C.wing_loading_points);
opts.selected.WS = C.design_point.wing_loading_psf;
opts.selected.WP = C.design_point.power_loading_lb_per_hp;

cruise_method = "power_index";
for k = 1:numel(obj.cons)
    c = get_con(k, obj.cons);
    if c.type == "cruise_speed" && strlength(c.method) > 0
        cruise_method = c.method;
    end
end

fprintf('=========================== TTPA SIZING (IHW3a) ==========================\n');
fprintf('\nFramework configuration\n');
fprintf('  sizing mode         %-16s %s\n', opts.mode, ...
    ternary_(opts.mode == "fixed_wing_area", ...
        '(lecture framework: S_ref is the design variable)', ...
        '(IHW2 route: S_ref is an output of the design point)'));
if opts.mode == "fixed_wing_area"
    fprintf('  S_ref  (INPUT)      %8.2f ft^2\n', opts.S_ref);
else
    fprintf('  design point        %8.2f lbf/ft^2 , %.2f lbf/hp  (%s)\n', ...
        opts.selected.WS, opts.selected.WP, opts.design_point_mode);
end
fprintf('  mission method      %-16s %s\n', string(obj.miss.method), ...
    ternary_(string(obj.miss.method) == "L2", ...
        '(improved fuel fractions: C_L from the real wing loading)', ...
        '(IHW1: fixed fractions, cruise at L/D_max)'));
fprintf('  weights method      %-16s %s\n', obj.wts.method, ...
    ternary_(obj.wts.method == "raymer_ga_III", ...
        '(Empty weight III: wing carries AR)', ...
        '(Empty weight II: Raymer Table 15.2)'));
fprintf('  cruise constraint   %-16s %s\n', cruise_method, ...
    ternary_(cruise_method == "drag_based", ...
        '(actual power balance)', '(Roskam power-index correlation)'));
fprintf('  guess %.0f lbf , tol %.0e , relaxation W %.2f / P %.2f\n', ...
    opts.W_TO_guess, opts.tol_rel, opts.relax_W, opts.relax_P);

%% ------------------------------------------------------------- 3. the loop
result = sizing_loop(obj, opts);

%% ------------------------------------------------------- 4. iteration history
h = result.history;
hist_table = table([h.iter]', [h.W_TO]', [h.P_SL]', [h.S_ref]', [h.WS]', [h.WP]', ...
                   [h.CD0]', [h.W_OEW]', [h.W_fuel]', [h.denom]', [h.res_W]', [h.res_P]', ...
    'VariableNames', {'iter','W_TO','P_SL','S_ref','WS','WP','CD0', ...
                      'OEW','W_fuel','useful_frac','res_W','res_P'});

fprintf('\n============================ ITERATION HISTORY ===========================\n');
if height(hist_table) > 14
    disp(head(hist_table, 7));
    fprintf('   ... %d iterations omitted ...\n\n', height(hist_table) - 14);
    disp(tail(hist_table, 7));
else
    disp(hist_table);
end
fprintf('%s in %d iterations.\n', ...
    ternary_(result.converged, 'CONVERGED', 'DID NOT CONVERGE'), result.n_iter);

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

fprintf('\nEMPTY-WEIGHT BUILD-UP  [method: %s]\n', bd.method);
fprintf('  wing                                              %8.1f lbf\n', bd.wing);
fprintf('  horizontal tail   2.0 psf x %7.2f ft^2           %8.1f lbf\n', obj.geom.S_ht,           bd.horizontal_tail);
fprintf('  vertical tail     2.0 psf x %7.2f ft^2           %8.1f lbf\n', obj.geom.S_vt,           bd.vertical_tail);
fprintf('  fuselage          1.4 psf x %7.2f ft^2 wetted    %8.1f lbf\n', obj.geom.S_wet_fuselage, bd.fuselage);
fprintf('  landing gear      0.057 x W_TO                    %8.1f lbf\n', bd.landing_gear);
fprintf('  installed engines       (%6.1f lbf bare each)     %8.1f lbf\n', bd.engine_bare_each, bd.installed_engine);
fprintf('  all else empty    0.10 x W_TO                     %8.1f lbf\n', bd.all_else_empty);
fprintf('  ---------------------------------------------------------\n');
fprintf('  total OEW                                         %8.1f lbf\n', bd.total);

fprintf('\nDESIGN DIAGRAM\n');
fprintf('  sized at              W/S = %6.2f lbf/ft^2 , W/P = %6.3f lbf/hp\n', result.WS, result.WP);
fprintf('  driving condition     %s\n', result.design_point.driving);
if isfield(result.design_point, 'WS_optimum') && isfinite(result.design_point.WS_optimum)
    fprintf('  least-engine corner   W/S = %6.2f lbf/ft^2 , W/P = %6.3f lbf/hp\n', ...
        result.design_point.WS_optimum, result.design_point.WP_optimum);
end
fprintf('  wing-loading wall     W/S = %6.2f lbf/ft^2   (landing)   margin %+.1f %%\n', ...
    result.design_point.WS_wall, 100*result.design_point.WS_margin);
if opts.mode == "fixed_wing_area"
    fprintf('  NOTE: this mode sizes the engine EXACTLY to the binding constraint, so\n');
    fprintf('        the power margin is zero by construction. The IHW2 design point\n');
    fprintf('        (40, 9.25) deliberately backs off from that; run mode\n');
    fprintf('        "design_point" to size to it instead.\n');
end

fprintf('\nWING\n');
fprintf('  reference area   S_ref  %8.2f ft^2      aspect ratio  %5.2f\n', obj.geom.S_ref, obj.geom.AR);
fprintf('  exposed area            %8.2f ft^2      taper ratio   %5.2f\n', obj.geom.S_exposed_wing, obj.geom.taper);
fprintf('  span             b      %8.2f ft        root chord    %5.2f ft\n', obj.geom.b, obj.geom.c_root);
fprintf('  MAC                     %8.2f ft        tip chord     %5.2f ft\n', obj.geom.MAC, obj.geom.c_tip);

fprintf('\nTAILS  [volume-coefficient method, Raymer Eqs. 6.29 and 6.28]\n');
fprintf('  horizontal  V_h %.3f, arm %4.1f ft  ->  S_ht %6.2f ft^2 , b %5.2f ft\n', ...
        obj.geom.V_ht, obj.geom.L_ht, obj.geom.S_ht, obj.geom.b_ht);
fprintf('  vertical    V_v %.3f, arm %4.1f ft  ->  S_vt %6.2f ft^2 , b %5.2f ft\n', ...
        obj.geom.V_vt, obj.geom.L_vt, obj.geom.S_vt, obj.geom.b_vt);

fprintf('\nPROPULSION\n');
fprintf('  installed power  P_SL   %8.1f hp total , %.1f hp per engine (%d engines)\n', ...
        result.P_SL, result.P_engine, obj.prop.n_engines);
fprintf('  bare engine weight      %8.1f lbf each  [Raymer Table 10.4, opposed]\n', bd.engine_bare_each);

fprintf('\nAERODYNAMICS\n');
fprintf('  wetted area      S_wet  %8.2f ft^2      S_wet/S_ref  %5.3f\n', obj.geom.S_wet, obj.geom.S_wet_over_S_ref);
fprintf('  clean CD0               %8.5f          [Raymer Eq. 12.23, Cfe = %.4f]\n', result.CD0, obj.aero.Cfe);
fprintf('  Oswald e %.4f , K %.5f , L/D max %.3f\n', obj.aero.e, obj.aero.K, result.LD_max);

if ~isempty(result.mission_detail)
    fprintf('\nMISSION, SEGMENT BY SEGMENT  [method L2]\n');
    fprintf('  %-9s %-10s %8s %9s %8s %8s\n', 'type','name','WF','fuel lbf','C_L','L/D');
    for k = 1:numel(result.mission_detail)
        d = result.mission_detail(k);
        fprintf('  %-9s %-10s %8.5f %9.2f %8s %8s\n', d.type, d.name, d.WF, d.fuel, ...
            num_(d.CL, '%.4f'), num_(d.LD, '%.3f'));
    end
end

%% ------------------------------------------------------------ 6. cross-checks
fprintf('\n=============================== CROSS-CHECKS =============================\n');

d_CD0 = 100 * (result.CD0 - obj.aero.CD0_reference) / obj.aero.CD0_reference;
fprintf('\n1. Drag.  Geometry build-up against the fixed IHW2 value.\n');
fprintf('     CD0 from S_wet/S_ref  %.5f     IHW2 fixed value  %.5f     %+.1f %%\n', ...
        result.CD0, obj.aero.CD0_reference, d_CD0);

d_OEW = 100 * (result.W_OEW - result.OEW_statistical) / result.OEW_statistical;
fprintf('\n2. Empty weight.  Component build-up against the IHW1 regression.\n');
fprintf('     component build-up          %.1f lbf\n', result.W_OEW);
fprintf('     0.911 * W_TO^0.947          %.1f lbf     %+.1f %%\n', result.OEW_statistical, d_OEW);

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

%% ------------------------------------------------------- 7. method comparison
if RUN_COMPARISON
    fprintf('\n========================== METHOD COMPARISON =============================\n');
    fprintf('\nEach row re-sizes the whole airplane with ONE switch moved.\n');
    fprintf('\n  %-34s %9s %8s %8s %9s\n', 'configuration', 'W_TO', 'P_SL', 'S_ref', 'W_fuel');
    fprintf('  %s\n', repmat('-', 1, 72));

    variants = { ...
      'baseline (as configured above)',            struct(), ...
      'mission L1  (IHW1 fixed fractions)',        struct('mission', "L1"), ...
      'mission L2  (improved fuel fractions)',     struct('mission', "L2"), ...
      'weights II  (Raymer Table 15.2)',           struct('weights', "table_15_2"), ...
      'weights III (Raymer Sec. 15.3.3, has AR)',  struct('weights', "raymer_ga_III"), ...
      'cruise: power index (Roskam correlation)',  struct('cruise', "power_index"), ...
      'cruise: drag based (power balance)',        struct('cruise', "drag_based"), ...
      'mode: design_point (IHW2 route)',           struct('mode', "design_point"), ...
      'mode: fixed_wing_area (lecture)',           struct('mode', "fixed_wing_area")};

    for v = 1:2:numel(variants)
        try
            rv = size_variant_(json_path, opts, variants{v+1});
            fprintf('  %-34s %9.1f %8.1f %8.2f %9.1f\n', variants{v}, ...
                rv.W_TO, rv.P_SL, rv.S_ref, rv.W_fuel);
        catch ME
            fprintf('  %-34s  FAILED: %s\n', variants{v}, ME.identifier);
        end
    end
    fprintf('\n  The mission switch is the biggest single effect: L1 flies cruise at\n');
    fprintf('  L/D_max = %.2f, but 200 KTAS at 8000 ft puts this airplane at C_L near\n', result.LD_max);
    fprintf('  0.37 where the real L/D is about 10.5. Best-L/D speed is 139 kt.\n');
end

%% ------------------------------------------------- 8. post-convergence checks
fprintf('\n========================= POST-CONVERGENCE CHECKS ========================\n');

[fuel_ok, V_ft3, W_cap, fuel_margin] = wing_fuel_check(result.W_fuel, obj);
fprintf('\nWing fuel volume  [Torenbeek]\n');
fprintf('  usable volume     %6.2f ft^3    capacity %6.0f lbf    mission needs %6.0f lbf\n', ...
        V_ft3, W_cap, result.W_fuel);
if fuel_ok
    fprintf('  OK - %.0f %% spare.\n', 100*fuel_margin);
else
    fprintf('  *** SHORT by %.0f %%. Change the planform.\n', -100*fuel_margin);
end

[P_nose, P_main, P_strut] = landing_gear_loads(result.W_TO, obj);
fprintf('\nLanding gear static loads  [Raymer Ch. 11, tricycle]\n');
fprintf('  nose %7.1f lbf    main (both) %7.1f lbf    per strut %7.1f lbf\n', ...
        P_nose, P_main, P_strut);

%% ------------------------------------------------------------------ 9. plot
plot_sizing_convergence(result);

%% -------------------------------------------------- 10. P-S sizing diagram
if MAKE_PS_DIAGRAM
    fprintf('\n=========================== P-S SIZING DIAGRAM ===========================\n');
    d = TtpaPSDiagram(obj);
    S_grid = linspace(100, 230, 35);
    P_grid = linspace(300, 900, 35);
    fprintf('\n  sizing %d x %d = %d airplanes, one per cell ...\n', ...
            numel(P_grid), numel(S_grid), numel(P_grid)*numel(S_grid));
    t0 = tic;
    fg = d.fuel_grid(P_grid, S_grid);
    fprintf('  done in %.1f s.  %d of %d cells feasible.\n', ...
            toc(t0), nnz(fg.feasible), numel(fg.feasible));

    markers = struct('P', {result.P_SL}, 'S', {result.S_ref}, ...
        'label', {sprintf('IHW3a sized  (%.0f hp, %.0f ft^2)', result.P_SL, result.S_ref)});
    [~, ps] = d.plot('S_grid', S_grid, 'P_grid', P_grid, 'markers', markers, 'grid', fg);
    lp = ps.least_power;
    fprintf('\n  least-power airplane    P %7.1f hp , S %6.1f ft^2 , W_TO %7.1f lbf\n', lp.P, lp.S, lp.W);
    fprintf('  this design             P %7.1f hp , S %6.1f ft^2 , W_TO %7.1f lbf\n', ...
            result.P_SL, result.S_ref, result.W_TO);

    % TtpaPSDiagram MUTATES the bundle: put the converged design back.
    obj.geom.S_ref = result.S_ref;
    obj.prop.P_SL  = result.P_SL;
end

fprintf('\nDone.\n');


%% ============================ local functions ============================

function r = size_variant_(json_path, opts, change)
%SIZE_VARIANT_  Re-size the airplane with one switch moved.
%   Writes a temporary requirements file so nothing on disk is disturbed.
    J = jsondecode(fileread(json_path));

    if isfield(change, 'mission'), J.missions.std_mission.method = char(change.mission); end
    if isfield(change, 'weights'), J.weights.method = char(change.weights); end
    if isfield(change, 'cruise')
        for k = 1:numel(J.constraints.conditions)
            c = J.constraints.conditions{k};
            if isfield(c, 'type') && strcmp(c.type, 'cruise_speed')
                J.constraints.conditions{k}.method = char(change.cruise);
            end
        end
    end

    tmp = fullfile(tempdir, 'ttpa_variant.json');
    fid = fopen(tmp, 'w'); fwrite(fid, jsonencode(J)); fclose(fid);

    prop = TtpaProp(tmp);
    geom = TtpaGeom(tmp, prop);
    aero = TtpaAero(tmp, geom);
    wts  = TtpaWeights(tmp, geom, prop);
    miss = MissionProfileReader.read_profile(tmp, 'std_mission');
    cons = ConstraintSetImporter.read_conditions(tmp);
    ob   = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
                  'miss', miss, 'cons', cons);

    o = opts;
    if isfield(change, 'mode')
        o.mode = change.mode;
        if o.mode == "fixed_wing_area" && isfield(J.sizing, 'relaxation_fixed_wing_area')
            o.relax_W = J.sizing.relaxation_fixed_wing_area;
            o.relax_P = o.relax_W;
        elseif o.mode == "design_point"
            o.relax_W = J.sizing.relaxation_W;
            o.relax_P = J.sizing.relaxation_P;
        end
    end
    o.max_iter = max(o.max_iter, 600);

    % A variant deliberately walks through engine sizes the Raymer Table 10.4
    % regression is not printed for; the per-iterate warning would bury the
    % table. Restored when this function returns.
    ws = warning('off', 'TtpaProp:BhpOutOfRange');
    restore = onCleanup(@() warning(ws));   %#ok<NASGU>

    r = sizing_loop(ob, o);
    delete(tmp);
end

function s = ternary_(cond, a, b)
    if cond, s = a; else, s = b; end
end

function s = num_(v, fmt)
    if isnan(v), s = '-'; else, s = sprintf(fmt, v); end
end
