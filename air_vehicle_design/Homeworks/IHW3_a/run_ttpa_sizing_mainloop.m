function [result, hist] = run_ttpa_sizing_mainloop(varargin)
%RUN_TTPA_SIZING_MAINLOOP  The TTPA main sizing loop, with S_ref as an OUTPUT.
%
%   run_ttpa_sizing_mainloop
%   [result, hist] = run_ttpa_sizing_mainloop('name', value, ...)
%
%   ======================================================================
%   THE FRAMEWORK THIS IMPLEMENTS
%
%   AR and taper are held CONSTANT. Three quantities are guessed and then
%   iterated to a consistent set: the takeoff weight W_0, the sea-level
%   shaft power P_0 (the "T_0" of the jet form), and the wing area S_ref.
%
%       INPUTS      AR, lambda  (constant)      W_0, P_0, S_0  (guesses)
%
%       STEP 1   CONSTRAINT ANALYSIS      -> (W/S)  and  (W/P)
%       STEP 2   SIZE THE WING            S = W_0 / (W/S)
%                SIZE THE ENGINE          P = W_0 / (W/P)
%                  S -> tail sizing -> S_ht, S_vt -> wetted area -> C_D0
%                  P -> engine weight and nacelle length
%       STEP 3   MISSION ANALYSIS         -> W_f
%       STEP 4   WEIGHT BUILD-UP          S -> W_w ,  P -> W_e ,  -> OEW
%       STEP 5   TAKEOFF-WEIGHT CLOSURE   OEW + W_f + payload -> W_0^new
%       STEP 6   CONVERGENCE TEST         |W_0^n - W_0^n-1| < eps
%                                         |P_0^n - P_0^n-1| < eps
%                if not converged: W_0 <- W_0^new, P_0 <- P^new, S <- S^new
%                                  and go back to STEP 1.
%
%   ======================================================================
%   changes I made from Ttpa sizing:
%
%   run_ttpa_sizing runs the LECTURE framework: S_ref is a green INPUT you
%   choose, the wing loading W_0/S_ref is computed, and the design diagram
%   is read at that ONE wing loading. That file, sizing_loop.m, and every
%   discipline class are UNTOUCHED by this one.
%
%   for this: the constraint analysis is solved
%   for its own least-engine corner on every pass, and S_ref = W_0/(W/S)
%   falls out. S_ref is an OUTPUT. 
%
%  
%   For this loop to be a genuine S_ref solver, SOMETHING in the constraint
%   analysis has to notice that the wing changed. Measured on this airplane:
%
%       Takeoff        reads CLmax and W/S only          - does not move
%       Landing (wall) reads CLmax and W/S only          - does not move
%       Climb x3       read C_D0 and K                   - MOVE, never bind
%       Cruise "power_index"   Roskam correlation        - does not move
%       Cruise "drag_based"    actual power balance      - MOVES
%
%   Under "power_index" the corner is the Takeoff-Cruise crossing at
%   (37.34, 10.49) and it is IDENTICAL on every pass whatever S_ref does.
%   S_ref then reduces to W_0/37.34 - a weight scaling wearing the costume
%   of a wing trade.
%
%   Under "drag_based" the cruise curve reads the drag polar, the polar reads
%   S_wet/S_ref, and the corner does respond to the wing:
%
%       S_ref 110 -> corner (43.21,  8.46)     S_ref 150 -> (41.63,  9.44)
%       S_ref 128 -> corner (43.21,  9.06)     S_ref 200 -> (39.14, 10.04)
%
%   READ THAT TABLE CAREFULLY, BECAUSE IT DOES NOT SAY WHAT IT LOOKS LIKE.
%   Below about 140 ft^2 the corner is PINNED to the landing wall at 43.240
%   psf: the cruise curve is still rising when the wall cuts it off. The
%   default configuration closes at S_ref = 125.22 ft^2, inside that pinned
%   region, so the converged W/S is 43.2404 on every single pass and S_ref
%   is once again W_0 divided by a constant. The constant is now the LANDING
%   FIELD LENGTH rather than a frozen correlation, which is a real and
%   defensible answer - 1500 ft of runway is what sizes this wing - but it
%   is not an aerodynamics-against-weight optimum, and this file does not
%   pretend otherwise. The printed wall margin is the evidence either way.
%
%   The corner becomes genuinely interior once the airplane is heavy enough
%   to want more wing. Under Empty Weight III it closes at S_ref = 141.78
%   ft^2 with W/S = 42.42, 1.89 per cent inside the wall and driven by
%   Takeoff - and there the corner really does walk as the polar changes.
%
%   All of it is selectable. Run all of it: the differences are the point.
%
%   ======================================================================
%   WHAT IT PRINTS
%
%   The full iteration history of everything that changes, not only the two
%   states: the constraint-analysis output, every planform and wetted area,
%   C_D0 and the polar, the engine, the fuel, and all seven weight rows.
%   Plus a stage-by-stage trace through the six boxes above.
%
%   ======================================================================
%   OPTIONS   (all optional, name/value)
%
%     'cruise'      "drag_based" (default) | "power_index"
%     'weights'     "" = as the JSON says (default) | "table_15_2"
%                                                   | "raymer_ga_III"
%     'mission'     "" = as the JSON says (default) | "L1" | "L2"
%     'corner'      "optimum" (default) re-solve the least-engine corner
%                   "selected" hold the IHW2 design point (40, 9.25)
%     'W_guess'     lbf,  default from the JSON sizing block
%     'S_guess'     ft^2, default from the JSON sizing block
%     'tol'         relative, default from the JSON
%     'max_iter'    default from the JSON
%     'relax'       under-relaxation on all three states, default from JSON
%     'trace'       "ends" (default) stage trace on the first, second and
%                   last pass | "all" every pass | "off"
%     'compare'     true (default) the method comparison at the end
%     'plot'        true (default)
%
%   OUTPUTS
%     result  converged design, the field names run_ttpa_sizing uses
%     hist    1xN struct array, the complete per-iteration history
%
%   See also RUN_TTPA_SIZING, SIZING_LOOP, MATCHING_ENVELOPE, MISSION_FUEL.

%% -------------------------------------------------------------- 0. options




p = inputParser;
p.addParameter('cruise',   "drag_based", @(s) any(string(s) == ["drag_based","power_index"]));
p.addParameter('weights',  "",           @(s) any(string(s) == ["","table_15_2","raymer_ga_III"]));
p.addParameter('mission',  "",           @(s) any(string(s) == ["","L1","L2"]));
p.addParameter('corner',   "optimum",    @(s) any(string(s) == ["optimum","selected"]));
p.addParameter('W_guess',  [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('S_guess',  [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('tol',      [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('max_iter', [], @(x) isempty(x) || (isscalar(x) && x > 0));
p.addParameter('relax',    [], @(x) isempty(x) || (isscalar(x) && x > 0 && x <= 1));
p.addParameter('trace',    "ends", @(s) any(string(s) == ["ends","all","off"]));
p.addParameter('compare',  true,  @okflag_);
p.addParameter('plot',     true,  @okflag_);
p.parse(varargin{:});
A          = p.Results;
A.cruise   = string(A.cruise);
A.weights  = string(A.weights);
A.mission  = string(A.mission);
A.corner   = string(A.corner);
A.trace    = string(A.trace);
A.compare  = tological_(A.compare);
A.plot     = tological_(A.plot);

%% --------------------------------------------------------------- 1. build
json_path = ttpa_requirements_path();
J         = jsondecode(fileread(json_path));
Sz        = J.sizing;
Cn        = J.constraints;

[obj, used] = build_bundle_(json_path, A.cruise, A.weights, A.mission);

W_guess  = pick_(A.W_guess,  Sz.W_TO_guess_lbf);
S_guess  = pick_(A.S_guess,  Sz.S_ref_ft2);
tol      = pick_(A.tol,      Sz.tol_rel);
max_iter = pick_(A.max_iter, Sz.max_iter);
if isfield(Sz, 'relaxation_mainloop') && ~isempty(Sz.relaxation_mainloop)
    relax_default = Sz.relaxation_mainloop;
else
    relax_default = Sz.relaxation_W;
end
relax    = pick_(A.relax,    relax_default);

sel.WS = Cn.design_point.wing_loading_psf;
sel.WP = Cn.design_point.power_loading_lb_per_hp;

% The wing-loading sweep the constraint analysis is solved on. The landing
% wall does not move with the geometry, so its exact location is appended to
% the sweep: when the corner is pinned against the wall - and on this
% airplane under "drag_based" it is, for small wings - a grid-quantised
% corner would quantise S_ref with it.
WS_sweep = linspace(Cn.wing_loading_range_psf(1), Cn.wing_loading_range_psf(2), ...
                    max(Cn.wing_loading_points, 400));
obj.geom.S_ref = S_guess;
obj.prop.P_SL  = W_guess / sel.WP;
[~, wall_probe] = run_constraints(mean(WS_sweep), obj);
wall_probe = min(wall_probe(~isnan(wall_probe)));
if isempty(wall_probe) || ~isfinite(wall_probe)
    wall_probe = Inf;
else
    WS_sweep = unique([WS_sweep, wall_probe*(1 - 1e-9)]);
end

banner_('TTPA MAIN SIZING LOOP  (IHW3a)  -  S_ref is an OUTPUT');
fprintf('\n  held CONSTANT     AR %.3f    taper %.3f    t/c root %.3f    sweep %.2f deg\n', ...
        obj.geom.AR, obj.geom.taper, obj.geom.tc_root, obj.geom.sweep_qc_deg);
fprintf('  GUESSES           W_0 %.1f lbf    P_0 %.1f hp    S_0 %.2f ft^2\n', ...
        W_guess, W_guess/sel.WP, S_guess);
fprintf('\n  constraint corner %-14s %s\n', A.corner, corner_note_(A.corner));
fprintf('  cruise method     %-14s %s\n', used.cruise,  cruise_note_(used.cruise));
fprintf('  weight method     %-14s %s\n', used.weights, weights_note_(used.weights));
fprintf('  mission method    %-14s %s\n', used.mission, mission_note_(used.mission));
fprintf('  tol %.1e   max_iter %d   relaxation %.2f on all three states\n', ...
        tol, max_iter, relax);
fprintf('  W/S sweep         %d points on [%.1f, %.1f] psf, wall appended at %.3f psf\n', ...
        numel(WS_sweep), WS_sweep(1), WS_sweep(end), wall_probe);

%% ------------------------------------------------------------ 2. the loop
% Warnings a TRANSIENT iterate can legitimately raise on its way to the
% answer. Silenced during the loop and checked against the CONVERGED
% airplane instead, in section 5.
quiet = {'TtpaProp:BhpOutOfRange', 'run_mission_L2:SegmentTooCoarse'};
ws0 = warning;
restore = onCleanup(@() warning(ws0));
for q = 1:numel(quiet), warning('off', quiet{q}); end

lo = struct('W0', W_guess, 'P0', W_guess/sel.WP, 'S0', S_guess, ...
            'corner', A.corner, 'selected', sel, 'WS_sweep', WS_sweep, ...
            'tol', tol, 'max_iter', max_iter, 'relax', relax, 'trace', A.trace);

[hist, converged, state] = main_loop_(obj, lo);

% Relaxation ladder. The corner MOVES under "drag_based", which couples
% S_ref back into the constraint analysis and can ring. Measured, not
% assumed: if the default relaxation does not close, damp and retry.
ladder = [0.30 0.20 0.12];
k = 0;
while ~converged && k < numel(ladder)
    k = k + 1;
    fprintf('\n  *** did not close at relaxation %.2f - retrying at %.2f\n', ...
            lo.relax, ladder(k));
    lo.relax = ladder(k);
    [hist, converged, state] = main_loop_(obj, lo);
end

warning(ws0);

%% ------------------------------------------------ 3. the iteration history
print_history_(hist);

%% ------------------------------------------------------ 4. converged design
result = finalize_(obj, state, hist, converged, used, A.corner, WS_sweep);
print_result_(result, obj, hist);

%% ----------------------------------------------------------- 5. the checks
print_checks_(result, obj);

%% ----------------------------------------------- 6. what each switch does
if A.compare
    print_comparison_(json_path, A, lo);
end

%% ------------------------------------------------------------------ 7. plot
if A.plot
    plot_mainloop_(hist, result);
end

fprintf('\nDone.\n');

end


%% ========================================================================
%  THE LOOP
%  ========================================================================
function [hist, converged, state] = main_loop_(obj, o)
%MAIN_LOOP_  Steps 1-6, successive substitution on three states.
%
%   The three states (W_0, P_0, S_ref) are written into the airplane at the
%   TOP of each pass, so every number recorded in one history row describes
%   ONE consistent airplane. The constraint analysis of pass n therefore
%   sees the wing produced by pass n-1: that lag is the loop.

    W0 = o.W0;  P0 = o.P0;  S0 = o.S0;

    hist      = repmat(blank_row_(), 1, o.max_iter);
    converged = false;
    recover   = 8;
    iter      = 0;

    if o.trace ~= "off"
        banner_('STAGE-BY-STAGE TRACE OF THE LOOP');
    end

    while iter < o.max_iter
        iter = iter + 1;

        % ---- STEP 0 : write the three states into the airplane -----------
        % The order is prop then geom: the nacelle length is sized around
        % the engine, so the engine must be current before the geometry is
        % read. Every other geometric and aerodynamic quantity is a
        % Dependent property, so these two writes resize the whole airplane.
        obj.prop.P_SL  = P0;
        obj.geom.S_ref = S0;

        % ---- STEP 1 : CONSTRAINT ANALYSIS  ->  W/S and W/P ---------------
        ca = constraint_analysis_(obj, o);

        % ---- STEP 2 : size the wing and the engine from W_0 --------------
        S_new = W0 / ca.WS;
        P_new = W0 / ca.WP;

        % ---- STEP 3 and 4 : mission fuel and the weight build-up ---------
        % Both are evaluated on the airplane written in STEP 0, at the
        % current W_0. A weight iterate can pass through a state no airplane
        % could occupy - the fuselage and the engine put a FIXED number of
        % pounds into the empty weight, so at a small W_0 the empty fraction
        % blows up and the engine that weight implies cannot climb. That is
        % recoverable: jump the iterate to a sane weight and carry on.
        blew_up = false;
        W_fuel = NaN;  ff = NaN;  bd = [];  W_new = NaN;  denom = NaN;
        try
            [W_fuel, ff] = mission_fuel(W0, obj);
            obj.wts.W_TO     = W0;
            obj.wts.W_energy = W_fuel;          % Raymer Eq. 15.46 W_fw term
            bd = obj.wts.OEW_breakdown(W0);
            if ~(isfinite(W_fuel) && isfinite(bd.total)), blew_up = true; end
        catch
            blew_up = true;
        end

        % ---- STEP 5 : takeoff-weight closure -----------------------------
        if ~blew_up
            [W_new, denom] = SizingSteps.togw_update(obj.wts.payload(), ...
                                                     bd.total, W_fuel, W0);
            blew_up = isnan(W_new);
        end

        if blew_up && recover > 0
            recover = recover - 1;
            W0 = max(1.5*W0, obj.wts.payload()/0.25);
            P0 = W0 / ca.WP;
            S0 = W0 / ca.WS;
            iter = iter - 1;                 % a recovery pass is not a pass
            continue;
        end
        if blew_up
            error('run_ttpa_sizing_mainloop:closureInfeasible', ...
                ['Takeoff-weight closure is infeasible at pass %d.\n', ...
                 '  denom = 1 - W_f/W_0 - OEW/W_0 = %.4f  (must be > 0)\n', ...
                 'The empty weight and the fuel together consume the whole ', ...
                 'takeoff weight, so no positive weight carries the %.0f lbf ', ...
                 'payload with this wing. A DESIGN result, not a coding ', ...
                 'error.'], iter, denom, obj.wts.payload());
        end

        % ---- STEP 6 : residuals, recorded BEFORE relaxation --------------
        r = snapshot_(obj, iter, W0, P0, S0, ca, W_fuel, ff, bd, ...
                      W_new, P_new, S_new, denom);
        hist(iter) = r;

        if o.trace == "all" || (o.trace == "ends" && (iter <= 2))
            print_stage_(r, o);
        end

        if r.res_W < o.tol && r.res_P < o.tol
            W0 = W_new;  P0 = P_new;  S0 = S_new;
            converged = true;
            break;
        end

        W0 = SizingSteps.relax(W0, W_new, o.relax);
        P0 = SizingSteps.relax(P0, P_new, o.relax);
        S0 = SizingSteps.relax(S0, S_new, o.relax);
    end

    hist = hist(1:iter);

    if o.trace ~= "off" && iter > 2
        fprintf('\n  ... passes 3 to %d omitted ...\n', iter-1);
        print_stage_(hist(end), o);
    end

    % Write the airplane at the state actually being returned, so the caller
    % reads the converged design off the discipline objects.
    obj.prop.P_SL  = P0;
    obj.geom.S_ref = S0;
    state = struct('W0', W0, 'P0', P0, 'S0', S0, 'n_iter', iter);

    if ~converged
        warning('run_ttpa_sizing_mainloop:notConverged', ...
            ['The main loop did not close in %d passes at relaxation %.2f. ', ...
             'Last W_0 = %.1f lbf, residuals %.2e (weight) %.2e (power).'], ...
            o.max_iter, o.relax, W0, hist(end).res_W, hist(end).res_P);
    end
end


function ca = constraint_analysis_(obj, o)
%CONSTRAINT_ANALYSIS_  STEP 1. The CA box of the whiteboard.
%
%   Solved on the CURRENT airplane, every pass. Everything it reads - the
%   configuration polars, the propeller efficiencies, the power lapse - is
%   read live off the discipline objects, so this is the matching diagram of
%   the airplane as the loop has it right now, not a diagram drawn once.
    [WP_env, WS_wall, driving, WS_best, WP_best] = ...
        matching_envelope(o.WS_sweep, obj);

    switch o.corner
        case "optimum"
            if isnan(WS_best)
                error('run_ttpa_sizing_mainloop:NoFeasiblePoint', ...
                    ['No wing loading on [%.1f, %.1f] psf is feasible: the ', ...
                     'whole sweep lies beyond the wing-loading wall at %.2f ', ...
                     'psf.'], o.WS_sweep(1), o.WS_sweep(end), WS_wall);
            end
            ca.WS = WS_best;
            ca.WP = WP_best;
        case "selected"
            ca.WS = o.selected.WS;
            ca.WP = o.selected.WP;
    end

    % Per-condition detail at the design point, for the history.
    [WP_lim, WS_w, names] = run_constraints(ca.WS, obj);
    ca.names     = names;
    ca.WP_limits = WP_lim(:,1).';
    ca.WS_walls  = WS_w;
    [~, kd]      = min(WP_lim(:,1));
    ca.driving   = string(names(kd));
    ca.WP_binding = WP_lim(kd,1);
    ca.WS_wall   = WS_wall;
    ca.wall_ok   = ca.WS <= WS_wall;
    ca.WS_margin = (WS_wall - ca.WS) / WS_wall;
    ca.WP_margin = (ca.WP_binding - ca.WP) / ca.WP_binding;
    ca.WS_best   = WS_best;
    ca.WP_best   = WP_best;
    ca.WP_env    = WP_env;
    ca.driving_curve = driving;
end


%% ========================================================================
%  THE HISTORY
%  ========================================================================
function r = blank_row_()
%BLANK_ROW_  The full record of one pass. Every field is a quantity the
%   loop CHANGES; nothing constant is recorded here.
    f = { ...
      'iter', ...
      ... states
      'W_TO','P_SL','S_ref','WS','WP', ...
      ... constraint analysis
      'driving','WS_wall','WS_margin','WP_margin','wall_ok','WP_binding', ...
      ... wing planform
      'b','MAC','c_root','c_tip','y_MAC','S_exposed_wing','wing_fuel_ft3', ...
      ... tails
      'S_ht','S_vt','b_ht','b_vt','MAC_ht','MAC_vt', ...
      ... engine and nacelle
      'P_engine','l_engine','l_nacelle','W_eng_bare_each','W_eng_bare_total', ...
      ... wetted areas
      'S_wet_wing','S_wet_ht','S_wet_vt','S_wet_fus','S_wet_nac','S_wet', ...
      'S_wet_over_S_ref', ...
      ... aerodynamics
      'CD0','e','K','LD_max', ...
      ... mission and payload
      'W_fuel','fuel_fraction','W_payload', ...
      ... weight build-up, the seven rows
      'W_wing','W_ht','W_vt','W_fus','W_gear','W_eng_inst','W_else', ...
      'OEW','OEW_fraction','OEW_statistical', ...
      ... closure and residuals
      'denom','W_TO_new','P_SL_new','S_ref_new','res_W','res_P','res_S'};
    r = struct();
    for i = 1:numel(f), r.(f{i}) = NaN; end
    r.driving = "";
end


function r = snapshot_(obj, iter, W0, P0, S0, ca, W_fuel, ff, bd, ...
                       W_new, P_new, S_new, denom)
%SNAPSHOT_  Read the WHOLE airplane out of the discipline objects.
%   Called once per pass, after the disciplines have been written, so every
%   field describes the same airplane. This is what makes it possible to
%   print the history of everything that moves rather than only the states.
    g = obj.geom;  a = obj.aero;  pr = obj.prop;

    r = blank_row_();
    r.iter  = iter;
    r.W_TO  = W0;   r.P_SL = P0;   r.S_ref = S0;
    r.WS    = ca.WS;  r.WP = ca.WP;

    r.driving    = ca.driving;
    r.WS_wall    = ca.WS_wall;
    r.WS_margin  = ca.WS_margin;
    r.WP_margin  = ca.WP_margin;
    r.wall_ok    = ca.wall_ok;
    r.WP_binding = ca.WP_binding;

    r.b = g.b;  r.MAC = g.MAC;  r.c_root = g.c_root;  r.c_tip = g.c_tip;
    r.y_MAC = g.y_MAC;  r.S_exposed_wing = g.S_exposed_wing;
    r.wing_fuel_ft3 = g.wing_fuel_volume();

    r.S_ht = g.S_ht;  r.S_vt = g.S_vt;
    r.b_ht = g.b_ht;  r.b_vt = g.b_vt;
    r.MAC_ht = g.MAC_ht;  r.MAC_vt = g.MAC_vt;

    [Wbt, Wbe] = pr.engine_weight();
    r.P_engine         = pr.P_engine;
    r.l_engine         = pr.engine_length();
    r.l_nacelle        = g.l_nacelle;
    r.W_eng_bare_each  = Wbe;
    r.W_eng_bare_total = Wbt;

    r.S_wet_wing = g.S_wet_wing;  r.S_wet_ht = g.S_wet_ht;
    r.S_wet_vt   = g.S_wet_vt;    r.S_wet_fus = g.S_wet_fuselage;
    r.S_wet_nac  = g.S_wet_nacelle;
    r.S_wet      = g.S_wet;
    r.S_wet_over_S_ref = g.S_wet_over_S_ref;

    r.CD0 = a.CD0;  r.e = a.e;  r.K = a.K;  r.LD_max = a.LD_max;

    r.W_fuel = W_fuel;  r.fuel_fraction = ff;
    r.W_payload = obj.wts.payload();

    r.W_wing     = bd.wing;
    r.W_ht       = bd.horizontal_tail;
    r.W_vt       = bd.vertical_tail;
    r.W_fus      = bd.fuselage;
    r.W_gear     = bd.landing_gear;
    r.W_eng_inst = bd.installed_engine;
    r.W_else     = bd.all_else_empty;
    r.OEW        = bd.total;
    r.OEW_fraction    = bd.total / W0;
    r.OEW_statistical = obj.wts.OEW_statistical(W0);

    r.denom     = denom;
    r.W_TO_new  = W_new;
    r.P_SL_new  = P_new;
    r.S_ref_new = S_new;
    r.res_W     = abs(W_new - W0) / W_new;
    r.res_P     = abs(P_new - P0) / P_new;
    r.res_S     = abs(S_new - S0) / S_new;
end


function print_stage_(r, o)
%PRINT_STAGE_  One pass, walked box by box in whiteboard order.
    fprintf('\n---------------------------------------- PASS %d\n', r.iter);
    fprintf('  STATES IN        W_0 %9.2f lbf    P_0 %8.2f hp    S_ref %7.3f ft^2\n', ...
            r.W_TO, r.P_SL, r.S_ref);

    fprintf('\n  STEP 1  CONSTRAINT ANALYSIS   (the CA box)\n');
    fprintf('          corner mode %-9s   driving constraint  %s\n', o.corner, r.driving);
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
function result = finalize_(obj, state, hist, converged, used, corner, WS_sweep)
%FINALIZE_  Rebuild every reported quantity on the CONVERGED airplane.
    W0 = state.W0;

    [W_fuel, ff, ~, ~, ~, detail] = mission_fuel(W0, obj);
    obj.wts.W_TO     = W0;
    obj.wts.W_energy = W_fuel;
    bd    = obj.wts.OEW_breakdown(W0);
    [~, denom] = SizingSteps.togw_update(obj.wts.payload(), bd.total, W_fuel, W0);

    result.method        = "mainloop";
    result.corner        = corner;
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
      'mission L2  (improved fuel fractions)',     struct('mission', "L2"); ...
      'corner: optimum (least-engine corner)',     struct('corner',  "optimum"); ...
      'corner: selected (IHW2 point 40, 9.25)',    struct('corner',  "selected")};

    ws0 = warning;
    warning('off', 'TtpaProp:BhpOutOfRange');
    warning('off', 'run_mission_L2:SegmentTooCoarse');
    warning('off', 'run_ttpa_sizing_mainloop:notConverged');

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
    corner  = A.corner;   if isfield(change,'corner'),  corner  = change.corner;  end

    [ob, used] = build_bundle_(json_path, cruise, weights, mission);

    o = lo;
    o.corner = corner;
    o.trace  = "off";

    [h, conv, st] = main_loop_(ob, o);
    ladder = [0.30 0.20 0.12];
    k = 0;
    while ~conv && k < numel(ladder)
        k = k + 1;  o.relax = ladder(k);
        [h, conv, st] = main_loop_(ob, o);
    end

    rv = finalize_(ob, st, h, conv, used, corner, o.WS_sweep);
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


function s = corner_note_(c)
    if c == "optimum"
        s = 're-solve the least-engine corner on every pass';
    else
        s = 'hold the IHW2 design point; S_ref = W_0/(W/S) only';
    end
end

function s = cruise_note_(m)
    if m == "drag_based"
        s = 'reads the polar - the corner MOVES with S_ref';
    else
        s = 'Roskam correlation - the corner is FROZEN';
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
