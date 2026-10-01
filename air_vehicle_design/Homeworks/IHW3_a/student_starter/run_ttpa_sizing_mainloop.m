function [result, hist] = run_ttpa_sizing_mainloop(varargin)
%RUN_TTPA_SIZING_MAINLOOP  IHW3 - size the TTPA with the main sizing loop.
%
%   run_ttpa_sizing_mainloop
%   [result, hist] = run_ttpa_sizing_mainloop('name', value, ...)
%
%   GIVEN - you do not write this file. It runs the twelve files you write,
%   in order, and prints the full iteration history of everything that
%   moves. If your twelve files are right it needs no editing.
%
%   ======================================================================
%   THE FRAMEWORK
%
%   AR and taper are held CONSTANT. Three quantities are guessed and then
%   iterated to a consistent set: the takeoff weight W_0, the sea-level
%   shaft power P_0, and the wing area S_ref.
%
%     STEP 1  CONSTRAINT ANALYSIS     -> (W/S), (W/P)   matching_envelope
%     STEP 2  SIZE THE WING           S   = W_0/(W/S)
%             SIZE THE ENGINE         P_0 = W_0/(W/P)
%               S -> tails -> wetted area -> C_D0       TtpaGeom, TtpaAero
%               P -> engine weight, nacelle length      TtpaProp
%     STEP 3  MISSION ANALYSIS        -> W_f            mission_fuel
%     STEP 4  WEIGHT BUILD-UP         -> W_w, W_e, OEW  TtpaWeights
%     STEP 5  TAKEOFF-WEIGHT CLOSURE  -> W_0^new        SizingSteps
%     STEP 6  CONVERGENCE TEST on W_0 and P_0; if not converged, relax all
%             three states and go back to STEP 1.       sizing_mainloop
%
%   One pass is sizing_pass. The iteration is sizing_mainloop.
%
%   ======================================================================
%   OPTIONS   (all optional, name/value)
%
%     'cruise'    "" = as the requirements file says (default)
%                 | "drag_based" | "power_index"
%     'weights'   "" (default) | "table_15_2" | "raymer_ga_III"
%     'mission'   "" (default) | "L1" | "L2"
%     'W_guess'   lbf,  default sizing.W_TO_guess_lbf
%     'S_guess'   ft^2, default sizing.S_ref_guess_ft2
%     'tol'       default sizing.tol_rel
%     'max_iter'  default sizing.max_iter
%     'relax'     default sizing.relaxation
%     'trace'     "ends" (default) the stage-by-stage trace of the first,
%                 second and last pass | "all" every pass | "off"
%     'compare'   true (default) re-size with each switch moved
%     'plot'      true (default)
%
%   Examples
%     run_ttpa_sizing_mainloop
%     run_ttpa_sizing_mainloop('weights', "raymer_ga_III", 'trace', "all")
%     run_ttpa_sizing_mainloop('relax', 1)        % watch it fail
%
%   OUTPUTS
%     result  the converged design
%     hist    1xN struct array, the complete per-pass history
%
%   See also SIZING_MAINLOOP, SIZING_PASS, MATCHING_ENVELOPE, MISSION_FUEL.

%% -------------------------------------------------------------- 0. options
p = inputParser;
p.addParameter('cruise',   "", @(s) any(string(s) == ["","drag_based","power_index"]));
p.addParameter('weights',  "", @(s) any(string(s) == ["","table_15_2","raymer_ga_III"]));
p.addParameter('mission',  "", @(s) any(string(s) == ["","L1","L2"]));
p.addParameter('W_guess',  [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('S_guess',  [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('tol',      [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('max_iter', [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('relax',    [], @(x) isempty(x) || (isscalar(x) && x > 0 && x <= 1));
p.addParameter('trace',    "ends", @(s) any(string(s) == ["ends","all","off"]));
p.addParameter('compare',  true,  @okflag_);
p.addParameter('plot',     true,  @okflag_);
p.parse(varargin{:});
A         = p.Results;
A.cruise  = string(A.cruise);
A.weights = string(A.weights);
A.mission = string(A.mission);
A.trace   = string(A.trace);
A.compare = tological_(A.compare);
A.plot    = tological_(A.plot);

%% --------------------------------------------------------------- 1. build
json_path = ttpa_requirements_path();
J         = jsondecode(fileread(json_path));
Sz        = J.sizing;
Cn        = J.constraints;

[obj, used] = build_bundle_(json_path, A.cruise, A.weights, A.mission);

W_guess  = pick_(A.W_guess,  Sz.W_TO_guess_lbf);
S_guess  = pick_(A.S_guess,  Sz.S_ref_guess_ft2);
tol      = pick_(A.tol,      Sz.tol_rel);
max_iter = pick_(A.max_iter, Sz.max_iter);
relax    = pick_(A.relax,    Sz.relaxation);

% First power guess: the guessed weight at the IHW2 design power loading.
WP_design = Cn.design_point.power_loading_lb_per_hp;

% The wing-loading sweep the constraint analysis is solved on, with the
% landing wall appended at its exact location (see wing_loading_sweep).
obj.geom.S_ref = S_guess;
obj.prop.P_SL  = W_guess / WP_design;
[WS_sweep, wall_probe] = wing_loading_sweep(obj);

banner_('TTPA MAIN SIZING LOOP  (IHW3)  -  S_ref is an OUTPUT');
fprintf('\n  held CONSTANT     AR %.3f    taper %.3f    t/c root %.3f    sweep %.2f deg\n', ...
        obj.geom.AR, obj.geom.taper, obj.geom.tc_root, obj.geom.sweep_qc_deg);
fprintf('  GUESSES           W_0 %.1f lbf    P_0 %.1f hp    S_0 %.2f ft^2\n', ...
        W_guess, W_guess/WP_design, S_guess);
fprintf('\n  cruise method     %-14s %s\n', used.cruise,  cruise_note_(used.cruise));
fprintf('  weight method     %-14s %s\n', used.weights, weights_note_(used.weights));
fprintf('  mission method    %-14s %s\n', used.mission, mission_note_(used.mission));
fprintf('  tol %.1e   max_iter %d   relaxation %.2f on all three states\n', ...
        tol, max_iter, relax);
fprintf('  W/S sweep         %d points on [%.1f, %.1f] psf, wall appended at %.3f psf\n', ...
        numel(WS_sweep), WS_sweep(1), WS_sweep(end), wall_probe);

%% ------------------------------------------------------------ 2. the loop
% Warnings a TRANSIENT pass can legitimately raise on its way to the answer.
% Silenced during the loop and checked against the CONVERGED airplane below.
quiet = {'TtpaProp:BhpOutOfRange', 'segment_cruise_L2:SegmentTooCoarse'};
ws0 = warning;
restore = onCleanup(@() warning(ws0));
for q = 1:numel(quiet), warning('off', quiet{q}); end

lo = struct('W0', W_guess, 'P0', W_guess/WP_design, 'S0', S_guess, ...
            'WS_sweep', WS_sweep, 'tol', tol, 'max_iter', max_iter, 'relax', relax);

[hist, converged, state] = sizing_mainloop(obj, lo);

% If the chosen relaxation does not close, damp and retry.
ladder = [0.30 0.20 0.12];
k = 0;
while ~converged && k < numel(ladder)
    k = k + 1;
    fprintf('\n  *** did not close at relaxation %.2f - retrying at %.2f\n', ...
            lo.relax, ladder(k));
    lo.relax = ladder(k);
    [hist, converged, state] = sizing_mainloop(obj, lo);
end

warning(ws0);

%% ---------------------------------------------- 3. stage-by-stage trace
print_trace_(hist, A.trace);

%% ------------------------------------------------ 4. the iteration history
print_history_(hist);

%% ------------------------------------------------------ 5. converged design
result = finalize_(obj, state, hist, converged, used, WS_sweep);
print_result_(result, obj, hist);

%% ----------------------------------------------------------- 6. the checks
print_checks_(result, obj);

%% ----------------------------------------------- 7. what each switch does
if A.compare
    print_comparison_(json_path, A, lo);
end

%% ------------------------------------------------------------------ 8. plot
if A.plot
    plot_mainloop_(hist, result);
end

fprintf('\nDone.\n');

end


%% ========================================================================
%  PRINTING
%  ========================================================================
function print_trace_(hist, mode)
%PRINT_TRACE_  The stage-by-stage walk through the six boxes.
    if mode == "off", return; end
    banner_('STAGE-BY-STAGE TRACE OF THE LOOP');
    n = numel(hist);
    if mode == "all"
        show = 1:n;
    else
        show = unique([1, min(2, n), n]);
    end
    for i = 1:numel(show)
        if i > 1 && show(i) > show(i-1) + 1
            fprintf('\n  ... passes %d to %d omitted ...\n', show(i-1)+1, show(i)-1);
        end
        print_stage_(hist(show(i)));
    end
end


function print_stage_(r)
%PRINT_STAGE_  One pass, walked box by box in whiteboard order.
    fprintf('\n---------------------------------------- PASS %d\n', r.iter);
    fprintf('  STATES IN        W_0 %9.2f lbf    P_0 %8.2f hp    S_ref %7.3f ft^2\n', ...
            r.W_TO, r.P_SL, r.S_ref);

    fprintf('\n  STEP 1  CONSTRAINT ANALYSIS   (the CA box)\n');
    fprintf('          least-engine corner     driving constraint  %s\n', r.driving);
    fprintf('          W/S = %8.4f psf        W/P = %8.4f lb/hp\n', r.WS, r.WP);
    fprintf('          wall %7.3f psf  margin %+6.2f %%   power margin %+6.2f %%\n', ...
            r.WS_wall, 100*r.WS_margin, 100*r.WP_margin);

    fprintf('\n  STEP 2  SIZE THE WING AND THE ENGINE\n');
    fprintf('          S = W_0/(W/S) = %9.2f / %7.4f = %8.3f ft^2\n', ...
            r.W_TO, r.WS, r.S_ref_new);
    fprintf('          P = W_0/(W/P) = %9.2f / %7.4f = %8.2f hp  (%.1f hp/engine)\n', ...
            r.W_TO, r.WP, r.P_SL_new, r.P_engine);
    fprintf('          the wing this pass was flown with:  b %6.3f ft   MAC %6.3f ft\n', ...
            r.b, r.MAC);
    fprintf('          tail sizing (volume coefficients)   S_ht %7.3f    S_vt %7.3f ft^2\n', ...
            r.S_ht, r.S_vt);
    fprintf('          wetted area  wing %6.1f + ht %5.1f + vt %5.1f + fus %6.1f + nac %5.1f\n', ...
            r.S_wet_wing, r.S_wet_ht, r.S_wet_vt, r.S_wet_fus, r.S_wet_nac);
    fprintf('                       S_wet %7.2f ft^2    S_wet/S_ref %6.4f\n', ...
            r.S_wet, r.S_wet_over_S_ref);
    fprintf('          drag polar II    C_D0 %7.5f   e %6.4f   K %7.5f   L/D max %6.3f\n', ...
            r.CD0, r.e, r.K, r.LD_max);
    fprintf('          engine       bare %6.1f lbf each   length %5.2f ft   nacelle %5.2f ft\n', ...
            r.W_eng_bare_each, r.l_engine, r.l_nacelle);

    fprintf('\n  STEP 3  MISSION ANALYSIS      (the MA box)\n');
    fprintf('          W_f = %8.2f lbf      W_f/W_0 = %7.5f\n', r.W_fuel, r.fuel_fraction);

    fprintf('\n  STEP 4  WEIGHT BUILD-UP\n');
    fprintf('          W_w  (wing, from S) %8.2f      W_e (engine, from P) %8.2f\n', ...
            r.W_wing, r.W_eng_inst);
    fprintf('          ht %7.2f   vt %7.2f   fus %8.2f   gear %8.2f   else %8.2f\n', ...
            r.W_ht, r.W_vt, r.W_fus, r.W_gear, r.W_else);
    fprintf('          OEW %9.2f lbf     OEW/W_0 %6.4f     (regression cross-check %8.2f)\n', ...
            r.OEW, r.OEW_fraction, r.OEW_statistical);

    fprintf('\n  STEP 5  TAKEOFF-WEIGHT CLOSURE\n');
    fprintf('          denom = 1 - W_f/W_0 - OEW/W_0 = %7.5f\n', r.denom);
    fprintf('          W_0^new = W_payload / denom   = %9.2f lbf\n', r.W_TO_new);

    fprintf('\n  STEP 6  CONVERGENCE TEST\n');
    fprintf('          res_W %9.3e     res_P %9.3e     res_S %9.3e\n', ...
            r.res_W, r.res_P, r.res_S);
end


function print_history_(h)
%PRINT_HISTORY_  Every pass, every quantity that moved. Five tables.

    banner_('FULL ITERATION HISTORY');

    fprintf('\nThe headline table. Left to right: the three states going IN, the\n');
    fprintf('geometry and drag they produce, every row of the weight build-up,\n');
    fprintf('and the closure that hands the next takeoff weight back to STEP 1.\n\n');

    % Two group banners. Column arithmetic for the format below:
    %   the weight build-up occupies columns  60-133  (74 wide)
    %   the closure occupies columns         135-160  (26 wide)
    fprintf('%59s%s %s\n', '', ...
            centred_('  weight build-up  [lbf]  ', 74), ...
            centred_('  closure  [lbf]  ', 26));

    fprintf('  %3s %7s %6s %7s %7s %7s %6s %6s %8s %6s %6s %8s %7s %8s %8s %8s %7s %8s %8s %8s\n', ...
        '#','W_TO in','P_SL','S_ref','S_wet','C_D0','S_HT','S_VT', ...
        'wing','ht','vt','fuselage','gear','engine','all else','OEW','OEW/W_0', ...
        'W_fuel','payload','W_TO out');
    fprintf('  %3s %7s %6s %7s %7s %7s %6s %6s %8s %6s %6s %8s %7s %8s %8s %8s %7s %8s %8s %8s\n', ...
        '','lbf','hp','ft^2','ft^2','-','ft^2','ft^2', ...
        'lbf','lbf','lbf','lbf','lbf','lbf','lbf','lbf','-', ...
        'lbf','lbf','lbf');
    fprintf('  %s\n', repmat('-', 1, 158));
    for i = 1:numel(h)
        fprintf('  %3d %7.1f %6.1f %7.2f %7.2f %7.5f %6.2f %6.2f %8.2f %6.2f %6.2f %8.2f %7.2f %8.2f %8.2f %8.2f %7.5f %8.2f %8.2f %8.2f\n', ...
            h(i).iter, h(i).W_TO, h(i).P_SL, h(i).S_ref, h(i).S_wet, h(i).CD0, ...
            h(i).S_ht, h(i).S_vt, ...
            h(i).W_wing, h(i).W_ht, h(i).W_vt, h(i).W_fus, h(i).W_gear, ...
            h(i).W_eng_inst, h(i).W_else, h(i).OEW, h(i).OEW_fraction, ...
            h(i).W_fuel, h(i).W_payload, h(i).W_TO_new);
    end

    fprintf('\n  W_TO in is the state the pass STARTED from; W_TO out is what STEP 5\n');
    fprintf('  closed to, W_payload/denom. The gap between them is the residual,\n');
    fprintf('  and the next pass starts from a relaxed step between the two, not\n');
    fprintf('  from W_TO out itself. payload is constant by definition - it is the\n');
    fprintf('  one weight the loop is solving AROUND rather than solving for.\n');

    fprintf('\n\nCONSTRAINT ANALYSIS  -  what the CA box returned on each pass.\n');
    fprintf('A moving driving constraint or a moving W/S is the evidence that\n');
    fprintf('the design diagram is actually responding to the geometry.\n\n');
    fprintf('  %3s %9s %9s %9s %9s %9s %-14s\n', ...
        '#','W/S','W/P','wall','WS marg%','WP marg%','driving');
    fprintf('  %s\n', repmat('-', 1, 78));
    for i = 1:numel(h)
        fprintf('  %3d %9.4f %9.4f %9.3f %9.3f %9.3f %-14s\n', ...
            h(i).iter, h(i).WS, h(i).WP, h(i).WS_wall, ...
            100*h(i).WS_margin, 100*h(i).WP_margin, h(i).driving);
    end

    fprintf('\n\nGEOMETRY  -  everything S_ref drives. Note S_ht and S_vt go as\n');
    fprintf('S_ref^1.5, because the volume coefficient multiplies S_ref by MAC\n');
    fprintf('(or by the span), and both of those go as sqrt(S_ref).\n\n');
    fprintf('  %3s %8s %7s %7s %7s %9s %7s %7s %8s %8s\n', ...
        '#','b','MAC','c_root','c_tip','S_exp_w','S_HT','S_VT','l_nac','V_wf');
    fprintf('  %3s %8s %7s %7s %7s %9s %7s %7s %8s %8s\n', ...
        '','ft','ft','ft','ft','ft^2','ft^2','ft^2','ft','ft^3');
    fprintf('  %s\n', repmat('-', 1, 83));
    for i = 1:numel(h)
        fprintf('  %3d %8.4f %7.4f %7.4f %7.4f %9.3f %7.3f %7.3f %8.4f %8.3f\n', ...
            h(i).iter, h(i).b, h(i).MAC, h(i).c_root, h(i).c_tip, ...
            h(i).S_exposed_wing, h(i).S_ht, h(i).S_vt, h(i).l_nacelle, ...
            h(i).wing_fuel_ft3);
    end

    fprintf('\n\nWETTED AREA AND THE DRAG POLAR  -  the coupling that makes this a\n');
    fprintf('Level-2 loop. C_D0 = C_fe * S_wet/S_ref, so a bigger wing lowers\n');
    fprintf('C_D0 even though it adds wetted area, because S_ref grows faster.\n\n');
    fprintf('  %3s %8s %7s %7s %8s %7s %9s %8s %8s %8s %8s\n', ...
        '#','wing','ht','vt','fus','nac','S_wet','Swet/S','C_D0','e','L/D max');
    fprintf('  %s\n', repmat('-', 1, 92));
    for i = 1:numel(h)
        fprintf('  %3d %8.3f %7.3f %7.3f %8.3f %7.3f %9.3f %8.4f %8.5f %8.5f %8.4f\n', ...
            h(i).iter, h(i).S_wet_wing, h(i).S_wet_ht, h(i).S_wet_vt, ...
            h(i).S_wet_fus, h(i).S_wet_nac, h(i).S_wet, h(i).S_wet_over_S_ref, ...
            h(i).CD0, h(i).e, h(i).LD_max);
    end

    fprintf('\n\nENGINE AND MISSION  -  what P_0 drives, and the fuel it burns.\n\n');
    fprintf('  %3s %9s %9s %8s %10s %10s %9s %9s\n', ...
        '#','P_SL','hp/engine','l_eng','W_bare_ea','W_bare_tot','W_fuel','W_f/W_0');
    fprintf('  %s\n', repmat('-', 1, 76));
    for i = 1:numel(h)
        fprintf('  %3d %9.2f %9.2f %8.3f %10.2f %10.2f %9.2f %9.5f\n', ...
            h(i).iter, h(i).P_SL, h(i).P_engine, h(i).l_engine, ...
            h(i).W_eng_bare_each, h(i).W_eng_bare_total, ...
            h(i).W_fuel, h(i).fuel_fraction);
    end

    fprintf('\n\nWEIGHT BUILD-UP  -  all seven rows, every pass.\n\n');
    fprintf('  %3s %9s %7s %7s %8s %8s %9s %8s %9s %8s\n', ...
        '#','wing','ht','vt','fuselage','gear','engine','all else','OEW','OEW/W_0');
    fprintf('  %s\n', repmat('-', 1, 88));
    for i = 1:numel(h)
        fprintf('  %3d %9.2f %7.2f %7.2f %8.2f %8.2f %9.2f %8.2f %9.2f %8.5f\n', ...
            h(i).iter, h(i).W_wing, h(i).W_ht, h(i).W_vt, h(i).W_fus, ...
            h(i).W_gear, h(i).W_eng_inst, h(i).W_else, h(i).OEW, h(i).OEW_fraction);
    end

    fprintf('\n\nCLOSURE AND CONVERGENCE  -  the STEP 5 and STEP 6 columns.\n\n');
    fprintf('  %3s %9s %9s %9s %9s %10s %10s %10s\n', ...
        '#','denom','W_0^new','P^new','S^new','res_W','res_P','res_S');
    fprintf('  %s\n', repmat('-', 1, 81));
    for i = 1:numel(h)
        fprintf('  %3d %9.5f %9.2f %9.2f %9.3f %10.3e %10.3e %10.3e\n', ...
            h(i).iter, h(i).denom, h(i).W_TO_new, h(i).P_SL_new, ...
            h(i).S_ref_new, h(i).res_W, h(i).res_P, h(i).res_S);
    end
end



%% ========================================================================
%  RESULTS
%  ========================================================================
function result = finalize_(obj, state, hist, converged, used, WS_sweep)
%FINALIZE_  Rebuild every reported quantity on the CONVERGED airplane.
    W0 = state.W0;

    [W_fuel, ff, ~, ~, ~, detail] = mission_fuel(W0, obj);
    obj.wts.W_TO     = W0;
    obj.wts.W_energy = W_fuel;
    bd    = obj.wts.OEW_breakdown(W0);
    [~, denom] = SizingSteps.togw_update(obj.wts.payload(), bd.total, W_fuel, W0);

    result.method        = "mainloop";
    result.switches      = used;
    result.converged     = converged;
    result.n_iter        = state.n_iter;

    result.W_TO          = W0;
    result.P_SL          = state.P0;
    result.P_engine      = obj.prop.P_engine;
    result.S_ref         = state.S0;

    result.WS            = hist(end).WS;
    result.WP            = hist(end).WP;
    result.driving       = hist(end).driving;
    result.WS_wall       = hist(end).WS_wall;
    result.WS_margin     = hist(end).WS_margin;
    result.WS_sweep      = WS_sweep;

    result.W_fuel        = W_fuel;
    result.fuel_fraction = ff;
    result.W_OEW         = bd.total;
    result.OEW_fraction  = bd.total / W0;
    result.OEW_breakdown = bd;
    result.OEW_statistical = obj.wts.OEW_statistical(W0);
    result.W_payload     = obj.wts.payload();
    result.useful_load_fraction = denom;
    result.mission_detail = detail;

    result.b      = obj.geom.b;
    result.MAC    = obj.geom.MAC;
    result.S_ht   = obj.geom.S_ht;
    result.S_vt   = obj.geom.S_vt;
    result.S_wet  = obj.geom.S_wet;
    result.CD0    = obj.aero.CD0;
    result.e      = obj.aero.e;
    result.K      = obj.aero.K;
    result.LD_max = obj.aero.LD_max;

    result.history = hist;
end


function print_result_(r, obj, h)
    banner_('CONVERGED DESIGN');

    if r.converged
        fprintf('\n  Closed in %d passes.\n', r.n_iter);
    else
        fprintf('\n  *** DID NOT CLOSE in %d passes. Values below are the last iterate.\n', r.n_iter);
    end

    fprintf('\n  THE THREE ITERATED QUANTITIES\n');
    fprintf('    W_TO      %10.2f lbf        (guess %.1f -> %.1f)\n', ...
            r.W_TO, h(1).W_TO, r.W_TO);
    fprintf('    P_SL      %10.2f hp         (%.1f hp per engine, %d engines)\n', ...
            r.P_SL, r.P_engine, obj.prop.n_engines);
    fprintf('    S_ref     %10.2f ft^2       *** AN OUTPUT OF THIS LOOP ***\n', r.S_ref);
    fprintf('              %10.2f            = W_TO / (W/S) = %.2f / %.4f\n', ...
            r.W_TO/r.WS, r.W_TO, r.WS);

    fprintf('\n  DESIGN POINT ON THE MATCHING DIAGRAM\n');
    fprintf('    W/S       %10.4f psf        W/P %8.4f lb/hp\n', r.WS, r.WP);
    fprintf('    driving constraint    %s\n', r.driving);
    fprintf('    landing wall          %.3f psf, this design sits %+.2f %% inside it\n', ...
            r.WS_wall, 100*r.WS_margin);

    fprintf('\n  WHAT SET THE WING\n');
    if abs(r.WS_margin) < 1e-4
        fprintf('    S_ref is set by the LANDING FIELD LENGTH. The design sits ON the\n');
        fprintf('    wing-loading wall: the cruise requirement wants a smaller wing\n');
        fprintf('    still - at 200 KTAS this airplane flies at C_L near 0.37, well\n');
        fprintf('    below best L/D, so parasite area costs more than the induced drag\n');
        fprintf('    it saves - and landing is the only thing stopping it. S_ref is\n');
        fprintf('    therefore W_TO divided by a CONSTANT, not the result of a trade.\n');
        fprintf('    Loosen the 1500 ft landing requirement and the wing shrinks.\n');
    else
        fprintf('    S_ref is set by a genuine interior corner of the matching\n');
        fprintf('    diagram, driven by %s, %.2f %% inside the landing wall.\n', ...
                r.driving, 100*r.WS_margin);
        fprintf('    Here the design diagram is genuinely trading power against wing\n');
        fprintf('    area, and S_ref is an answer rather than a ratio.\n');
    end
    fprintf('\n  GEOMETRY THAT FELL OUT\n');
    fprintf('    b %8.3f ft    MAC %7.3f ft    S_ht %7.3f ft^2    S_vt %7.3f ft^2\n', ...
            r.b, r.MAC, r.S_ht, r.S_vt);
    fprintf('    S_wet %8.2f ft^2   S_wet/S_ref %6.4f\n', r.S_wet, r.S_wet/r.S_ref);

    fprintf('\n  DRAG POLAR II\n');
    fprintf('    C_D0 %8.5f    e %7.5f    K %8.5f    L/D max %7.4f\n', ...
            r.CD0, r.e, r.K, r.LD_max);

    fprintf('\n  WEIGHT BUILD-UP  [%s]\n', r.OEW_breakdown.method);
    bd = r.OEW_breakdown;
    rows = {'wing', bd.wing; 'horizontal tail', bd.horizontal_tail; ...
            'vertical tail', bd.vertical_tail; 'fuselage', bd.fuselage; ...
            'landing gear', bd.landing_gear; 'installed engine', bd.installed_engine; ...
            'all else empty', bd.all_else_empty};
    for i = 1:size(rows,1)
        fprintf('    %-20s %9.2f lbf   %5.1f %% of OEW\n', ...
                rows{i,1}, rows{i,2}, 100*rows{i,2}/bd.total);
    end
    fprintf('    %-20s %9.2f lbf\n', 'OEW', bd.total);
    fprintf('    %-20s %9.2f lbf   %+.2f %% against the build-up\n', ...
            'regression check', r.OEW_statistical, ...
            100*(r.OEW_statistical - bd.total)/bd.total);

    fprintf('\n  WEIGHT CLOSURE\n');
    fprintf('    payload   %10.2f lbf\n', r.W_payload);
    fprintf('    fuel      %10.2f lbf   W_f/W_0 %7.5f\n', r.W_fuel, r.fuel_fraction);
    fprintf('    OEW       %10.2f lbf   OEW/W_0 %7.5f\n', r.W_OEW, r.OEW_fraction);
    fprintf('    useful load fraction  %7.5f\n', r.useful_load_fraction);
    fprintf('    sum       %10.2f lbf   against W_TO %10.2f  (residual %.2e)\n', ...
            r.W_payload + r.W_fuel + r.W_OEW, r.W_TO, ...
            abs(r.W_payload + r.W_fuel + r.W_OEW - r.W_TO)/r.W_TO);

    fprintf('\n  HOW FAR THE LOOP TRAVELLED\n');
    fprintf('    %-10s %12s %12s %10s\n', '', 'first pass', 'converged', 'change');
    mv = {'W_TO', h(1).W_TO, r.W_TO; 'P_SL', h(1).P_SL, r.P_SL; ...
          'S_ref', h(1).S_ref, r.S_ref; 'W/S', h(1).WS, r.WS; ...
          'W/P', h(1).WP, r.WP; 'C_D0', h(1).CD0, r.CD0; ...
          'S_wet', h(1).S_wet, r.S_wet; 'OEW', h(1).OEW, r.W_OEW; ...
          'W_fuel', h(1).W_fuel, r.W_fuel};
    for i = 1:size(mv,1)
        fprintf('    %-10s %12.4f %12.4f %9.2f %%\n', mv{i,1}, mv{i,2}, mv{i,3}, ...
                100*(mv{i,3}-mv{i,2})/mv{i,2});
    end
end


function print_checks_(r, obj)
    banner_('POST-CONVERGENCE CHECKS');

    [fuel_ok, V_ft3, W_cap, margin] = wing_fuel_check(r.W_fuel, obj);
    fprintf('\n  Wing fuel volume  [Torenbeek]\n');
    fprintf('    usable %6.2f ft^3   capacity %7.1f lbf   mission needs %7.1f lbf\n', ...
            V_ft3, W_cap, r.W_fuel);
    if fuel_ok
        fprintf('    OK - %.1f %% spare.\n', 100*margin);
    else
        fprintf('    *** SHORT by %.1f %%. The wing cannot hold the mission fuel.\n', -100*margin);
    end

    [P_nose, P_main, P_strut] = landing_gear_loads(r.W_TO, obj);
    fprintf('\n  Landing gear static loads  [Raymer Ch. 11, tricycle]\n');
    fprintf('    nose %7.1f lbf   main (both) %7.1f lbf   per strut %7.1f lbf\n', ...
            P_nose, P_main, P_strut);

    fprintf('\n  Engine regression band  [Raymer Table 10.4, opposed piston]\n');
    lo = obj.prop.bhp_range(1);  hi = obj.prop.bhp_range(2);
    fprintf('    converged %.1f hp per engine against the %.0f-%.0f hp band\n', ...
            r.P_engine, lo, hi);
    if r.P_engine < lo || r.P_engine > hi
        fprintf('    *** OUTSIDE the band. The engine weight and length are\n');
        fprintf('        extrapolations of the regression, not interpolations.\n');
    else
        fprintf('    OK - inside the band the regression is printed for.\n');
    end

    fprintf('\n  Weight method\n');
    bd = r.OEW_breakdown;
    fprintf('    installed engine is %.1f %% of OEW, the largest single row.\n', ...
            100*bd.installed_engine/bd.total);
    if bd.method == "table_15_2"
        fprintf('    *** Under Raymer Table 15.2 that row is 1.4 x the bare engine\n');
        fprintf('        weight, which models NO PROPELLER at all. On a propeller\n');
        fprintf('        airplane whose largest empty-weight row is the engine that\n');
        fprintf('        is the weakest number in the build-up. Empty weight III\n');
        fprintf('        (Raymer Eq. 15.52) includes the propeller and the mounts -\n');
        fprintf('        run with ''weights'', ''raymer_ga_III'' and compare.\n');
    else
        fprintf('    Raymer Eq. 15.52 - includes the propeller and the engine mounts.\n');
    end

    fprintf('\n  Wing-loading wall\n');
    if r.WS_margin >= 0
        fprintf('    W/S %.3f psf is %.2f %% inside the landing wall at %.3f psf.\n', ...
                r.WS, 100*r.WS_margin, r.WS_wall);
    else
        fprintf('    *** W/S %.3f psf EXCEEDS the landing wall at %.3f psf by %.2f %%.\n', ...
                r.WS, r.WS_wall, -100*r.WS_margin);
    end
end


%% ========================================================================
%  COMPARISON
%  ========================================================================
function print_comparison_(json_path, A, lo)
%PRINT_COMPARISON_  Re-close the airplane with one switch moved at a time.
    banner_('WHAT EACH SWITCH IS WORTH');

    fprintf('\nEvery row re-runs the WHOLE main loop with one switch moved.\n\n');
    fprintf('  %-42s %9s %8s %8s %9s %9s %5s\n', ...
            'configuration','W_TO','P_SL','S_ref','W_fuel','OEW','pass');
    fprintf('  %s\n', repmat('-', 1, 95));

    V = { ...
      'baseline (as configured above)',            struct(); ...
      'cruise: drag based (power balance)',        struct('cruise', "drag_based"); ...
      'cruise: power index (Roskam correlation)',  struct('cruise', "power_index"); ...
      'weights II  (Raymer Table 15.2)',           struct('weights', "table_15_2"); ...
      'weights III (Raymer Sec. 15.3.3, has AR)',  struct('weights', "raymer_ga_III"); ...
      'mission L1  (IHW1 fixed fractions)',        struct('mission', "L1"); ...
      'mission L2  (improved fuel fractions)',     struct('mission', "L2")};

    ws0 = warning;
    warning('off', 'TtpaProp:BhpOutOfRange');
    warning('off', 'segment_cruise_L2:SegmentTooCoarse');
    warning('off', 'sizing_mainloop:notConverged');

    for v = 1:size(V,1)
        try
            rv = variant_(json_path, A, lo, V{v,2});
            flag = '';
            if ~rv.converged, flag = ' (not closed)'; end
            fprintf('  %-42s %9.1f %8.1f %8.2f %9.1f %9.1f %5d%s\n', ...
                V{v,1}, rv.W_TO, rv.P_SL, rv.S_ref, rv.W_fuel, rv.W_OEW, ...
                rv.n_iter, flag);
        catch ME
            fprintf('  %-42s  FAILED: %s\n', V{v,1}, ME.identifier);
        end
    end
    warning(ws0);

    fprintf('\n  WHAT SETS S_ref, read off the rows above.\n');
    fprintf('    power_index   corner frozen at the Takeoff-Cruise crossing,\n');
    fprintf('                  W/S = 37.375 psf on every pass. S_ref = W_TO/37.375.\n');
    fprintf('    drag_based    cruise wants LESS wing, because 200 KTAS puts this\n');
    fprintf('                  airplane at C_L about 0.37, well below best L/D. The\n');
    fprintf('                  wing shrinks until the LANDING WALL stops it, so\n');
    fprintf('                  W/S = 43.240 psf on every pass. S_ref = W_TO/43.240.\n');
    fprintf('    weights III   heavier airplane, more wing, and the corner finally\n');
    fprintf('                  comes off the wall: W/S 42.42, driven by Takeoff. Only\n');
    fprintf('                  there is S_ref set by a trade rather than by one\n');
    fprintf('                  requirement.\n');
    fprintf('\n  So on THIS airplane the honest statement is that S_ref is set by a\n');
    fprintf('  single binding requirement in most configurations - the landing field\n');
    fprintf('  length under drag_based, the cruise correlation under power_index - and\n');
    fprintf('  not by an aerodynamics-against-weight optimum. The loop is still the\n');
    fprintf('  correct closure; it just has less to say about the wing than the block\n');
    fprintf('  diagram suggests. run_ttpa_sizing_optim is the file for a true optimum.\n');
end


function rv = variant_(json_path, A, lo, change)
%VARIANT_  One re-close with a switch moved. Silent.
    cruise  = A.cruise;   if isfield(change,'cruise'),  cruise  = change.cruise;  end
    weights = A.weights;  if isfield(change,'weights'), weights = change.weights; end
    mission = A.mission;  if isfield(change,'mission'), mission = change.mission; end

    [ob, used] = build_bundle_(json_path, cruise, weights, mission);

    o = lo;
    [h, conv, st] = sizing_mainloop(ob, o);
    ladder = [0.30 0.20 0.12];
    k = 0;
    while ~conv && k < numel(ladder)
        k = k + 1;  o.relax = ladder(k);
        [h, conv, st] = sizing_mainloop(ob, o);
    end

    rv = finalize_(ob, st, h, conv, used, o.WS_sweep);
end


%% ========================================================================
%  PLOT
%  ========================================================================
function plot_mainloop_(h, r)
    it = [h.iter];
    f = figure('Name', 'TTPA main sizing loop', 'Color', 'w', ...
               'Position', [80 80 1180 760]);

    subplot(2,3,1);
    plot(it, [h.W_TO], '-o', 'LineWidth', 1.3, 'MarkerSize', 3); hold on;
    yline(r.W_TO, '--', sprintf('%.1f', r.W_TO));
    grid on; xlabel('pass'); ylabel('W_{TO}  [lbf]'); title('State 1: takeoff weight');

    subplot(2,3,2);
    plot(it, [h.P_SL], '-o', 'LineWidth', 1.3, 'MarkerSize', 3); hold on;
    yline(r.P_SL, '--', sprintf('%.1f', r.P_SL));
    grid on; xlabel('pass'); ylabel('P_{SL}  [hp]'); title('State 2: sea-level power');

    subplot(2,3,3);
    plot(it, [h.S_ref], '-o', 'LineWidth', 1.3, 'MarkerSize', 3); hold on;
    yline(r.S_ref, '--', sprintf('%.2f', r.S_ref));
    grid on; xlabel('pass'); ylabel('S_{ref}  [ft^2]'); title('State 3: wing area (OUTPUT)');

    subplot(2,3,4);
    yyaxis left;  plot(it, [h.CD0], '-o', 'LineWidth', 1.3, 'MarkerSize', 3);
    ylabel('C_{D0}');
    yyaxis right; plot(it, [h.WS], '-s', 'LineWidth', 1.3, 'MarkerSize', 3);
    ylabel('(W/S)  [psf]');
    grid on; xlabel('pass'); title('The coupling: C_{D0} and the design point');

    subplot(2,3,5);
    plot(it, [h.OEW], '-o', 'LineWidth', 1.3, 'MarkerSize', 3); hold on;
    plot(it, [h.W_fuel], '-s', 'LineWidth', 1.3, 'MarkerSize', 3);
    plot(it, [h.W_wing], '-^', 'LineWidth', 1.1, 'MarkerSize', 3);
    plot(it, [h.W_eng_inst], '-v', 'LineWidth', 1.1, 'MarkerSize', 3);
    grid on; xlabel('pass'); ylabel('weight  [lbf]');
    legend({'OEW','W_f','W_w','W_e'}, 'Location', 'best');
    title('Weight build-up');

    subplot(2,3,6);
    semilogy(it, max([h.res_W], eps), '-o', 'LineWidth', 1.3, 'MarkerSize', 3); hold on;
    semilogy(it, max([h.res_P], eps), '-s', 'LineWidth', 1.3, 'MarkerSize', 3);
    semilogy(it, max([h.res_S], eps), '-^', 'LineWidth', 1.3, 'MarkerSize', 3);
    grid on; xlabel('pass'); ylabel('relative residual');
    legend({'W_0','P_0','S_{ref}'}, 'Location', 'best');
    title('Convergence');

    sgtitle(sprintf(['TTPA main sizing loop   W_{TO} %.1f lbf, P_{SL} %.1f hp, ', ...
                     'S_{ref} %.2f ft^2   (%d passes)'], ...
                    r.W_TO, r.P_SL, r.S_ref, r.n_iter));

    out = fullfile(fileparts(mfilename('fullpath')), 'output');
    if ~exist(out, 'dir'), mkdir(out); end
    png = fullfile(out, 'ttpa_mainloop_convergence.png');
    try
        exportgraphics(f, png, 'Resolution', 200);
        fprintf('\n  convergence plot -> %s\n', png);
    catch
        try
            print(f, png, '-dpng', '-r200');
            fprintf('\n  convergence plot -> %s\n', png);
        catch ME
            warning('run_ttpa_sizing_mainloop:exportFailed', ...
                'Could not write the convergence plot: %s', ME.message);
        end
    end
end


%% ========================================================================
%  HELPERS
%  ========================================================================
function [obj, used] = build_bundle_(json_path, cruise, weights, mission)
%BUILD_BUNDLE_  A discipline bundle with the method switches applied.
%   Writes a temporary requirements file rather than mutating anything on
%   disk, so the project JSON, run_ttpa_sizing and every discipline class
%   are untouched. Same pattern run_ttpa_sizing uses for its own comparison.
    J = jsondecode(fileread(json_path));

    if strlength(weights) > 0, J.weights.method = char(weights); end
    if strlength(mission) > 0, J.missions.std_mission.method = char(mission); end
    if strlength(cruise) > 0
        for k = 1:numel(J.constraints.conditions)
            c = J.constraints.conditions{k};
            if isfield(c, 'type') && strcmp(c.type, 'cruise_speed')
                J.constraints.conditions{k}.method = char(cruise);
            end
        end
    end

    tmp = fullfile(tempdir, 'ttpa_mainloop.json');
    fid = fopen(tmp, 'w');
    if fid < 0
        error('run_ttpa_sizing_mainloop:tempFile', ...
            'Could not open "%s" to write the variant requirements file.', tmp);
    end
    fwrite(fid, jsonencode(J));  fclose(fid);

    prop = TtpaProp(tmp);
    geom = TtpaGeom(tmp, prop);
    aero = TtpaAero(tmp, geom);
    wts  = TtpaWeights(tmp, geom, prop);
    miss = MissionProfileReader.read_profile(tmp, 'std_mission');
    cons = ConstraintSetImporter.read_conditions(tmp);
    obj  = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
                  'miss', miss, 'cons', cons);

    used.cruise  = "power_index";
    for k = 1:numel(cons)
        if string(cons(k).type) == "cruise_speed"
            if isfield(cons(k), 'method') && ~isempty(cons(k).method)
                used.cruise = string(cons(k).method);
            end
        end
    end
    used.weights = string(wts.method);
    used.mission = string(miss.method);
end



function s = cruise_note_(m)
    if m == "drag_based"
        s = 'reads the polar - the corner MOVES with S_ref';
    else
        s = 'Roskam correlation - the corner is FROZEN (IHW2)';
    end
end

function s = weights_note_(m)
    if m == "raymer_ga_III"
        s = 'Empty weight III - Eq. 15.46 carries AR, Eq. 15.52 has the propeller';
    else
        s = 'Empty weight II - areal densities, no AR, no propeller';
    end
end

function s = mission_note_(m)
    if m == "L2"
        s = 'improved fractions - C_L recomputed per sub-segment';
    else
        s = 'IHW1 fixed fractions - cruise flown at L/D max';
    end
end

function v = pick_(a, b)
    if isempty(a), v = b; else, v = a; end
end

function tf = okflag_(x)
    tf = islogical(x) || isnumeric(x) || ischar(x) || isstring(x);
end

function tf = tological_(x)
    if islogical(x), tf = x; return; end
    if isnumeric(x), tf = logical(x); return; end
    s = lower(strtrim(string(x)));
    tf = any(s == ["true","1","yes","on"]);
end

function c = centred_(label, width)
%CENTRED_  A label centred in a rule of the given width.
    pad = max(0, width - numel(label));
    c = [repmat('-',1,floor(pad/2)) label repmat('-',1,ceil(pad/2))];
end

function banner_(t)
    n = 74;
    pad = max(0, n - strlength(t) - 2);
    l = floor(pad/2);  r = pad - l;
    fprintf('\n%s %s %s\n', repmat('=', 1, l), t, repmat('=', 1, r));
end
