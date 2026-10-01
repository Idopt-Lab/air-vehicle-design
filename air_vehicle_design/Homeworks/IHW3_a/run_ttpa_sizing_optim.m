function [result, opt] = run_ttpa_sizing_optim(varargin)
%RUN_TTPA_SIZING_OPTIM  Optimize the design variables, not just size at one.
%
%   run_ttpa_sizing_optim                         % run with the defaults
%   run_ttpa_sizing_optim('objective', "mtow")    % minimise takeoff weight
%   run_ttpa_sizing_optim('dvs', ["S_ref" "AR"])  % optimise a subset
%   [result, opt] = run_ttpa_sizing_optim(...)    % keep the results
%
%  "Optimization with internally satisfied constraints". Once the framework designs a whole
%   airplane from a consistent set of design variables, the objective becomes a
%   function of those variables and an optimizer can be pointed at it.
%
%   NOTHING ELSE IS CHANGED. Self-contained: it writes a temporary requirements
%   file per evaluation and calls the EXISTING sizing_loop, design_diagram,
%   mission_fuel and discipline classes exactly as run_ttpa_sizing does.
%   run_ttpa_sizing and its answers are untouched.
%
%   ------------------------------------------------------------------
%   WHY S_ref CAN BE OPTIMISED AT ALL
%
%   Only in sizing mode "fixed_wing_area". There S_ref is a green INPUT and the
%   wing loading W_0/S_ref is computed, so a different wing gives a different
%   airplane and the objective genuinely moves. In "design_point" mode S_ref is
%   an OUTPUT - whatever W_TO/(W/S) happens to be - so there is nothing to
%   optimise. That is exactly why the lecture makes S_ref an input.
%
%   ------------------------------------------------------------------
%   THE ARCHITECTURE
%
%
%     (a) INTERNALLY SATISFIED CONSTRAINTS   <- this file
%         The framework satisfies the performance constraints itself: the
%         design diagram sizes the engine to EXACTLY meet whichever power
%         requirement binds, so every converged airplane already meets takeoff,
%         all three climbs and cruise. The optimizer never sees them, and only
%         handles what the framework does NOT enforce:
%
%           g1  landing wall   W/S must not exceed the landing limit
%           g2  fuel volume    the wing must hold the fuel the mission needs
%           g3  engine size    power per engine must stay inside the 60-500 bhp
%                              band the Raymer Table 10.4 regression is printed
%                              for. A MODEL-VALIDITY constraint: without it the
%                              optimizer extrapolates the engine-weight fit off
%                              the end of its data and reports the result as an
%                              optimum.
%
%     (b) "PROPER" OPTIMIZATION
%         Expose the power constraints and let the optimizer choose P_SL as a
%         fifth variable. More general, but it discards the structure the
%         sizing loop gives for free. Not implemented here.
%
%   ------------------------------------------------------------------
%   DESIGN VARIABLES
%
%     S_ref       a bigger wing lowers W/S so takeoff needs less power, but
%                 the wing, the tails and the wetted area all grow
%     AR          less induced drag against a heavier wing (Raymer Eq. 15.46
%                 carries (A/cos^2 Lambda)^0.6) and a bigger vertical tail
%     taper       moves the exposed area, the MAC (hence the horizontal tail)
%                 and the wing fuel volume
%     tc_root     a thicker wing is LIGHTER (Eq. 15.46 has (100 t/c)^-0.3) and
%                 holds more fuel, and at M = 0.31 there is no wave drag to
%                 punish it - so EXPECT THIS ONE TO RUN TO ITS UPPER BOUND.
%                 That is a real property of the model, not a bug: nothing in
%                 it represents the buffet and stall penalties that stop a real
%                 designer going much past 18 percent. Read a variable sitting
%                 on a bound as "the bound is holding the design", not as an
%                 optimum.
%
%   The tip thickness is slaved to the root at the baseline ratio, so the
%   airfoil family stays coherent as the root moves.
%
%   ------------------------------------------------------------------
%   THE OBJECTIVE DECIDES WHETHER ASPECT RATIO HAS AN OPTIMUM. MEASURED:
%
%     objective "fuel"   ->  AR runs to its UPPER BOUND (12)
%     objective "mtow"   ->  AR settles at 6.94, an INTERIOR optimum
%
%   Both are correct, and the difference is the same one the aspect-ratio
%   trade study shows: fuel falls with aspect ratio under every weight model,
%   because a longer span always cuts induced drag. It is the TAKEOFF WEIGHT
%   that carries the trade, because that is where the heavier wing is paid
%   for. 6.94 agrees with the 7.5 the trade study finds at fixed S_ref, taper
%   and thickness; here those three moved too.
%
%   So: minimise MTOW if you want aspect-ratio result. Minimise
%   fuel if fuel is genuinely the objective - and then read AR = 12 as "the
%   bound is holding it", not as an optimum.
%
%   ------------------------------------------------------------------
%   TWO VARIABLES SIT ON A BOUND UNDER BOTH OBJECTIVES. BOTH ARE HONEST
%   MODEL LIMITS, NOT SOLVER FAILURES:
%
%     tc_root -> 0.20 (upper).  Raymer Eq. 15.46 has (100 t/c)^-0.3, so a
%       thicker wing is LIGHTER, and it holds more fuel. At M = 0.31 there is
%       no wave drag in the model to push back. Nothing here represents the
%       buffet and drag-rise penalties that stop a real designer past about
%       18 percent, so the bound is doing that job.
%
%     taper -> 0.25 (lower).  Less taper means a smaller root chord, so less
%       exposed area and a lighter wing, and a smaller MAC, so a smaller
%       horizontal tail. Nothing in the model represents the tip stall that
%       punishes a sharply tapered wing, so again the bound is the stand-in.
%
%   A variable resting on a bound is reported as such. Read it as "the model
%   found no interior trade for this one", and tighten the bound to whatever
%   the missing physics would have allowed.
%
%   ------------------------------------------------------------------
%   THE WEIGHTS METHOD IS FORCED TO "raymer_ga_III", NOT OPTIONAL
%
%   Under Empty weight II the wing weight is an areal density times an area and
%   carries no aspect ratio, so the optimizer would drive AR to its upper bound
%   and call that an optimum. The lecture makes exactly this point with its
%   aspect-ratio trade study. Empty weight III uses Raymer Eq. 15.46 and gives
%   a real interior minimum.
%
%   Takes a few minutes.
%
%   See also RUN_TTPA_SIZING, RUN_TTPA_TRADE_STUDIES, SIZING_LOOP.

    p = inputParser;
    addParameter(p, 'objective',  "fuel", @(s) any(string(s)==["fuel","mtow"]));
    addParameter(p, 'dvs',        ["S_ref","AR","taper","tc_root"]);
    % The two flags accept a logical, a number, or text, so that MATLAB's
    % COMMAND syntax works as well as function syntax:
    %     run_ttpa_sizing_optim objective mtow multistart false
    %     run_ttpa_sizing_optim('objective', "mtow", 'multistart', false)
    % Command syntax hands every argument over as a char array, so a bare
    % @islogical validator rejects "false".
    okflag = @(v) islogical(v) || isnumeric(v) || ischar(v) || isstring(v);
    addParameter(p, 'multistart', true,  okflag);
    addParameter(p, 'plots',      true,  okflag);
    parse(p, varargin{:});
    OBJECTIVE  = string(p.Results.objective);
    ACTIVE_DVS = string(p.Results.dvs);
    MULTISTART = tological_(p.Results.multistart);
    MAKE_PLOTS = tological_(p.Results.plots);

    json_path = ttpa_requirements_path();
    J0 = jsondecode(fileread(json_path));

    % ------------------------------------------- design-variable table
    DVall = struct( ...
      'name', {"S_ref", "AR", "taper", "tc_root"}, ...
      'x0',   {J0.sizing.S_ref_ft2, J0.geometry.AR, ...
               J0.geometry.taper_ratio, J0.geometry.thickness_ratio_root}, ...
      'lo',   {100,  6.0,  0.25, 0.12}, ...
      'hi',   {200, 12.0,  0.60, 0.20}, ...
      'unit', {"ft^2", "-", "-", "-"}, ...
      'fmt',  {"%8.2f", "%8.3f", "%8.4f", "%8.4f"});
    DV  = DVall(ismember([DVall.name], ACTIVE_DVS));
    nDV = numel(DV);
    if nDV == 0
        error('run_ttpa_sizing_optim:noDVs', 'No design variable selected.');
    end

    x0 = [DV.x0];  lo = [DV.lo];  hi = [DV.hi];

    % Normalise so every variable starts at 1. Without this fmincon steps 128
    % and 0.18 with the same absolute trust region and the thin variables
    % never move.
    scale = x0;
    n0  = ones(1, nDV);
    nlo = lo ./ scale;
    nhi = hi ./ scale;

    % ------------------------------------------- shared state for the nested fns
    hist    = struct('x', {}, 'f', {}, 'gmax', {});
    warm    = [];                 % warm start for the inner sizing loop
    cache_n = [];  cache_f = [];  cache_g = [];  cache_r = [];

    % ----------------------------------------------------------- banner
    fprintf('=================== TTPA SIZING OPTIMIZATION ===================\n');
    fprintf('\nArchitecture : internally satisfied constraints\n');
    fprintf('Sizing mode  : fixed_wing_area  (S_ref is a design variable)\n');
    fprintf('Weights      : raymer_ga_III    (forced: Empty weight II has no AR)\n');
    fprintf('Mission      : %s\n', string(J0.missions.std_mission.method));
    fprintf('Objective    : minimise %s\n', ...
        ternary_(OBJECTIVE=="fuel", 'mission fuel burn', 'takeoff gross weight'));
    fprintf('\nDesign variables\n');
    for k = 1:nDV
        fprintf('  %-9s start %s   bounds [%g, %g] %s\n', DV(k).name, ...
            sprintf(DV(k).fmt, DV(k).x0), DV(k).lo, DV(k).hi, DV(k).unit);
    end
    fprintf('\nOptimizer constraints (takeoff, the three climbs and cruise are\n');
    fprintf('satisfied INTERNALLY by the design diagram and never seen here)\n');
    fprintf('  g1 landing wall   g2 fuel volume   g3 engine within 60-500 bhp\n');

    % --------------------------------------------------------- baseline
    fprintf('\nEvaluating the baseline ...\n');
    [f0, g0, r0] = probe(n0);
    report_point_('BASELINE', DV, x0, f0, g0, r0, OBJECTIVE);

    % --------------------------------------------------------- optimise
    opts = optimoptions('fmincon', ...
        'Algorithm', 'sqp', ...
        'Display', 'iter', ...
        'FiniteDifferenceType', 'forward', ...
        'FiniteDifferenceStepSize', 3e-4, ...  % well above the loop's 1e-8 noise
        'OptimalityTolerance', 1e-6, ...
        'StepTolerance', 1e-8, ...
        'ConstraintTolerance', 1e-6, ...
        'MaxFunctionEvaluations', 400, ...
        'OutputFcn', @record);

    fprintf('\n------------------------- fmincon -------------------------\n');
    t0 = tic;
    [nstar, fstar, exitflag, output] = fmincon(@objfun, n0, [], [], [], [], ...
                                               nlo, nhi, @confun, opts);
    fprintf('\nfmincon: %.1f s, exitflag %d, %d evaluations\n', ...
            toc(t0), exitflag, output.funcCount);

    xstar = nstar .* scale;
    [fs, gs, rs] = probe(nstar);
    report_point_('OPTIMUM', DV, xstar, fs, gs, rs, OBJECTIVE);

    % ------------------------------------------------------- multistart
    if MULTISTART
        fprintf('\n--------------------- multistart check ---------------------\n');
        o2 = opts; o2.Display = 'none'; o2.OutputFcn = [];
        nb = 0.5*(nlo + nhi);
        [n2, f2] = fmincon(@objfun, nb, [], [], [], [], nlo, nhi, @confun, o2);
        fprintf('  start A (baseline) -> %10.3f   x = [%s]\n', fstar, dvstr_(xstar));
        fprintf('  start B (mid-box)  -> %10.3f   x = [%s]\n', f2,    dvstr_(n2.*scale));
        rel = abs(f2-fstar)/max(abs(fstar),eps);
        fprintf('  relative difference %.2e  ->  %s\n', rel, ...
            ternary_(rel < 1e-4, 'the starts agree; the optimum looks global on this box', ...
                                 'THE STARTS DISAGREE - treat this as a LOCAL optimum'));
    end

    % ---------------------------------------------- baseline vs optimum
    fprintf('\n===================== BASELINE vs OPTIMUM =====================\n');
    fprintf('  %-24s %12s %12s %10s\n', '', 'baseline', 'optimum', 'change');
    fprintf('  %s\n', repmat('-', 1, 62));
    for k = 1:nDV
        row_(sprintf('DV  %s', DV(k).name), x0(k), xstar(k), DV(k).unit);
    end
    fprintf('  %s\n', repmat('-', 1, 62));
    row_('mission fuel',    r0.W_fuel, rs.W_fuel, 'lbf');
    row_('takeoff weight',  r0.W_TO,   rs.W_TO,   'lbf');
    row_('empty weight',    r0.W_OEW,  rs.W_OEW,  'lbf');
    row_('installed power', r0.P_SL,   rs.P_SL,   'hp');
    row_('wing loading',    r0.WS,     rs.WS,     'psf');
    row_('power loading',   r0.WP,     rs.WP,     'lb/hp');
    row_('span',            r0.b,      rs.b,      'ft');
    row_('CD0',             r0.CD0,    rs.CD0,    '-');
    row_('L/D max',         r0.LD_max, rs.LD_max, '-');

    % ------------------------------------------------ constraint status
    fprintf('\nCONSTRAINT STATUS AT THE OPTIMUM   (g <= 0 is satisfied)\n');
    gn = ["g1 landing wall", "g2 fuel volume", "g3 engine size"];
    for k = 1:numel(gs)
        if     gs(k) > -1e-4,  tag = 'ACTIVE  <- this is holding the design back';
        elseif gs(k) > -0.05,  tag = 'near';
        else,                  tag = 'slack'; end
        fprintf('  %-18s g = %+8.5f   %s\n', gn(k), gs(k), tag);
    end
    fprintf('  Internally satisfied, so absent here: takeoff, the three climbs,\n');
    fprintf('  cruise. The design diagram sized the engine to meet whichever one\n');
    fprintf('  binds, which at the optimum is %s.\n', rs.design_point.driving);

    % ------------------------------------------- variables on their bounds
    onb = false(1,nDV);
    for k=1:nDV
        onb(k) = (xstar(k) <= lo(k)*(1+1e-6)) || (xstar(k) >= hi(k)*(1-1e-6));
    end
    if any(onb)
        fprintf('\n  NOTE: %s sitting on a bound. A variable at a bound is held by the\n', ...
            strjoin(cellstr([DV(onb).name]), ', '));
        fprintf('  BOUND, not by a trade - the model found no interior optimum for it.\n');
    end

    % ---------------------------------------------- local sensitivity
    fprintf('\nLOCAL SENSITIVITY  (+1 %% on each variable, at the optimum)\n');
    fprintf('  %-9s %14s %14s\n', 'variable', 'd(obj)/obj %', 'd(W_TO)/W_TO %');
    for k = 1:nDV
        np = nstar; np(k) = np(k)*1.01;
        [fp, ~, rp] = probe(np);
        if isfinite(rp.W_TO)
            fprintf('  %-9s %13.3f  %13.3f\n', DV(k).name, ...
                100*(fp-fs)/fs, 100*(rp.W_TO-rs.W_TO)/rs.W_TO);
        else
            fprintf('  %-9s %13s  %13s\n', DV(k).name, 'no closure', '-');
        end
    end

    % -------------------------------------------- the optimised airplane
    obs = rs.obj;  bd = rs.OEW_breakdown;
    fprintf('\n==================== THE OPTIMISED AIRPLANE ====================\n');
    fprintf('\nWEIGHTS     W_TO %8.1f   OEW %8.1f   fuel %8.1f   payload %7.1f lbf\n', ...
            rs.W_TO, rs.W_OEW, rs.W_fuel, rs.W_payload);
    fprintf('  wing %6.1f  HT %5.1f  VT %5.1f  fus %6.1f  gear %6.1f  eng %7.1f  else %6.1f\n', ...
            bd.wing, bd.horizontal_tail, bd.vertical_tail, bd.fuselage, ...
            bd.landing_gear, bd.installed_engine, bd.all_else_empty);
    fprintf('\nWING        S_ref %7.2f ft^2  AR %5.2f  taper %.3f  t/c root %.3f\n', ...
            obs.geom.S_ref, obs.geom.AR, obs.geom.taper, obs.geom.tc_root);
    fprintf('            b %6.2f ft  c_root %5.2f  c_tip %5.2f  MAC %5.2f  y_MAC %5.2f ft\n', ...
            obs.geom.b, obs.geom.c_root, obs.geom.c_tip, obs.geom.MAC, obs.geom.y_MAC);
    fprintf('\nTAILS       S_ht %6.2f ft^2 (b %5.2f)   S_vt %6.2f ft^2 (b %5.2f)\n', ...
            obs.geom.S_ht, obs.geom.b_ht, obs.geom.S_vt, obs.geom.b_vt);
    fprintf('\nPROPULSION  P_SL %7.1f hp total, %6.1f per engine   bare %6.1f lbf each\n', ...
            rs.P_SL, rs.P_engine, bd.engine_bare_each);
    fprintf('\nAERO        S_wet %7.2f ft^2  S_wet/S_ref %5.3f  CD0 %.5f  L/D max %6.3f\n', ...
            obs.geom.S_wet, obs.geom.S_wet_over_S_ref, rs.CD0, rs.LD_max);

    [fok, Vf, Wcap, fmar] = wing_fuel_check(rs.W_fuel, obs);
    fprintf('\nFUEL VOLUME %6.2f ft^3 -> %6.0f lbf capacity vs %6.0f needed  %+.0f %% %s\n', ...
            Vf, Wcap, rs.W_fuel, 100*fmar, ternary_(fok,'spare','SHORT'));
    [Pn, Pm, Ps] = landing_gear_loads(rs.W_TO, obs);
    fprintf('GEAR LOADS  nose %7.1f   main %7.1f   per strut %7.1f lbf\n', Pn, Pm, Ps);

    % ---------------------------------------------------- results FIRST
    % Assigned BEFORE any plotting. MATLAB's graphics export can time out in
    % an interactive session (a "graphics handshaking" issue), and if that
    % happens after a ten-second optimisation the answers must not go with it.
    result = rs;
    opt = struct('DV',DV,'x0',x0,'xstar',xstar,'f0',f0,'fstar',fstar, ...
                 'g0',g0,'gstar',gs,'exitflag',exitflag,'output',output, ...
                 'history',hist,'baseline',r0,'objective',OBJECTIVE);

    % --------------------------------------------------------- plots
    if MAKE_PLOTS && ~isempty(hist)
      try
        fig = figure('Name','Optimizer history','Color','w','Position',[70 70 1020 420]);
        tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
        nexttile; plot([hist.f],'-o','LineWidth',1.6,'MarkerSize',4); grid on;
        xlabel('fmincon iteration');
        ylabel(ternary_(OBJECTIVE=="fuel",'mission fuel [lbf]','W_{TO} [lbf]'));
        title('Objective');
        nexttile; hold on; grid on;
        X = vertcat(hist.x);
        for k=1:nDV, plot(X(:,k),'-o','LineWidth',1.5,'MarkerSize',4); end
        yline(1,'k:','baseline');
        xlabel('fmincon iteration'); ylabel('design variable / baseline');
        legend(cellstr([DV.name]),'Location','best');
        title('Design variables (normalised)');

        outdir = fullfile(fileparts(mfilename('fullpath')), 'output');
        if ~exist(outdir,'dir'), mkdir(outdir); end
        f_png = fullfile(outdir,'ttpa_optim_history.png');

        % Two export paths. exportgraphics is the better one but goes through
        % the graphics handshake, which can time out in an interactive session;
        % print takes a different route and usually survives. Either way a
        % failed PNG is a warning, never a lost result.
        try
            exportgraphics(fig, f_png, 'Resolution', 200);
            fprintf('\nWrote output/ttpa_optim_history.png\n');
        catch ME1
            try
                print(fig, f_png, '-dpng', '-r200');
                fprintf('\nWrote output/ttpa_optim_history.png (via print)\n');
            catch ME2
                warning('run_ttpa_sizing_optim:exportFailed', ...
                    ['Could not write the history plot (%s / %s). The figure is ', ...
                     'still open and every result is in the returned structs. ', ...
                     'Call with ''plots'', false to skip plotting.'], ...
                    ME1.identifier, ME2.identifier);
            end
        end
      catch MEp
        warning('run_ttpa_sizing_optim:plotFailed', ...
            ['Plotting failed (%s). Every result is still in the returned ', ...
             'structs; call with ''plots'', false to skip it.'], MEp.identifier);
      end
    end

    fprintf('\nDone.\n');


    %% ==================== nested functions ====================
    % Nested, not local, so they share DV / J0 / scale / warm / the cache
    % without any evalin into the base workspace.

    function f = objfun(n)
        [f, ~, ~] = probe(n);
    end

    function [c, ceq] = confun(n)
        [~, c, ~] = probe(n);
        ceq = [];
    end

    function [f, g, r] = probe(n)
    % fmincon calls the objective and the constraints separately at the SAME
    % point, so cache: without this every design is sized twice.
        if ~isempty(cache_n) && isequal(size(cache_n), size(n)) ...
                             && all(abs(cache_n - n) < 1e-14)
            f = cache_f; g = cache_g; r = cache_r; return;
        end
        [f, g, r] = evaluate(n);
        cache_n = n; cache_f = f; cache_g = g; cache_r = r;
    end

    function [f, g, r] = evaluate(n)
    % Size ONE airplane at a normalised design point, by writing a temporary
    % requirements file and calling the existing sizing_loop.
        x = n .* scale;
        J = J0;
        J.sizing.mode    = 'fixed_wing_area';
        J.weights.method = 'raymer_ga_III';        % forced - see the header

        for kk = 1:nDV
            switch DV(kk).name
                case "S_ref",  J.sizing.S_ref_ft2     = x(kk);
                case "AR",     J.geometry.AR          = x(kk);
                case "taper",  J.geometry.taper_ratio = x(kk);
                case "tc_root"
                    % keep the tip/root thickness ratio at its baseline
                    tau = J0.geometry.thickness_ratio_tip / J0.geometry.thickness_ratio_root;
                    J.geometry.thickness_ratio_root = x(kk);
                    J.geometry.thickness_ratio_tip  = tau * x(kk);
            end
        end

        tmp = fullfile(tempdir, sprintf('ttpa_opt_%d.json', feature('getpid')));
        fid = fopen(tmp,'w'); fwrite(fid, jsonencode(J)); fclose(fid);
        ws = warning('off','all');
        restore = onCleanup(@() warning(ws));  %#ok<NASGU>

        try
            prop = TtpaProp(tmp);        geom = TtpaGeom(tmp, prop);
            aero = TtpaAero(tmp, geom);  wts  = TtpaWeights(tmp, geom, prop);
            miss = MissionProfileReader.read_profile(tmp,'std_mission');
            cons = ConstraintSetImporter.read_conditions(tmp);
            ob   = struct('aero',aero,'prop',prop,'wts',wts,'geom',geom, ...
                          'miss',miss,'cons',cons);

            Cc = J.constraints;  Sz = J.sizing;
            guess = Sz.W_TO_guess_lbf;
            if ~isempty(warm) && isfinite(warm) && warm > 0
                guess = warm;                       % warm start from the last design
            end
            relax = Sz.relaxation_W;
            if isfield(Sz,'relaxation_fixed_wing_area')
                relax = Sz.relaxation_fixed_wing_area;
            end

            o = struct('mode',"fixed_wing_area", 'S_ref',Sz.S_ref_ft2, ...
                'W_TO_guess',guess, 'tol_rel',1e-8, 'max_iter',900, ...
                'relax_W',relax, 'relax_P',relax, 'design_point_mode',"selected", ...
                'WS_sweep',linspace(Cc.wing_loading_range_psf(1), ...
                                    Cc.wing_loading_range_psf(2), 200), ...
                'selected',struct('WS',Cc.design_point.wing_loading_psf, ...
                                  'WP',Cc.design_point.power_loading_lb_per_hp));

            r = [];
            for rx = [relax 0.30 0.20 0.12]
                try
                    o.relax_W = rx;  o.relax_P = rx;
                    r = sizing_loop(ob, o);
                    if r.converged, break; end
                catch, r = []; end
            end
            if isempty(r) || ~r.converged
                error('run_ttpa_sizing_optim:noClosure','no converged airplane');
            end

            r.obj = ob;
            warm  = r.W_TO;

            if OBJECTIVE == "fuel", f = r.W_fuel; else, f = r.W_TO; end

            g1 = r.WS / r.design_point.WS_wall - 1;        % landing wall
            [~, ~, Wc] = wing_fuel_check(r.W_fuel, ob);
            g2 = r.W_fuel / Wc - 1;                         % fuel volume
            g3 = r.P_engine / 500 - 1;                      % Raymer Tbl 10.4 range
            g  = [g1 g2 g3];

        catch
            % No airplane here. Hand fmincon a large FINITE objective and a
            % clearly violated constraint - it cannot use NaN.
            f = 1e6;  g = [1 1 1];  r = struct('W_TO', NaN);
        end

        if exist(tmp,'file'), delete(tmp); end
    end

    function stop = record(n, ov, state)
        stop = false;
        if strcmp(state,'iter')
            hist(end+1) = struct('x', n(:).', 'f', ov.fval, ...
                                 'gmax', ov.constrviolation); %#ok<AGROW>
        end
    end

    function row_(nm, a, b, u)
        fprintf('  %-24s %12.3f %12.3f %9.1f %% %s\n', nm, a, b, 100*(b-a)/a, u);
    end

    function s = dvstr_(x)
        s = strtrim(sprintf('%.4g ', x));
    end

end


%% ======================== local functions ========================

function report_point_(label, DV, x, f, g, r, OBJ)
    fprintf('\n--- %s ---\n', label);
    s = '';
    for k = 1:numel(DV)
        s = [s sprintf('%s = %s   ', DV(k).name, sprintf(DV(k).fmt, x(k)))]; %#ok<AGROW>
    end
    fprintf('  %s\n', strtrim(s));
    if ~isfinite(r.W_TO)
        fprintf('  NO CONVERGED AIRPLANE HERE\n');  return;
    end
    fprintf('  objective (%s) %10.2f    W_TO %8.1f   P_SL %7.1f hp   fuel %7.1f lbf\n', ...
        ternary_(OBJ=="fuel",'fuel','MTOW'), f, r.W_TO, r.P_SL, r.W_fuel);
    fprintf('  constraints  g1 %+.4f  g2 %+.4f  g3 %+.4f   (worst %+.4f)\n', ...
        g(1), g(2), g(3), max(g));
end

function s = ternary_(c, a, b)
    if c, s = a; else, s = b; end
end

function b = tological_(v)
%TOLOGICAL_  Accept true/false, 1/0, or the words, so command syntax works.
    if islogical(v)
        b = v;
    elseif isnumeric(v)
        b = logical(v);
    else
        b = any(strcmpi(string(v), ["true" "1" "yes" "on"]));
    end
end
