%% run_ttpa_trade_studies.m
%  IHW3a - trade studies on the preliminary design framework.
%
%  The lecture's closing argument: once the framework designs a whole
%  airplane from a consistent set of design variables, the objective becomes
%  a FUNCTION of those variables, and you can ask "what if". That is a trade
%  study, and the lecture calls it the simplest form of optimization.
%
%  This only works in sizing mode "fixed_wing_area". In "design_point" mode
%  S_ref is an output, so there is nothing to sweep: the answer is whatever
%  the envelope corner dictates. That is exactly why the lecture makes S_ref
%  a green input.
%
%  Three studies:
%
%    1  WING AREA.  Sweep S_ref, size the airplane at each one, and plot the
%       objective. The minimum is the best wing for this mission - and it is
%       NOT the constraint-envelope corner, because the corner minimizes the
%       ENGINE, not the fuel.
%
%    2  ASPECT RATIO, both weight methods.  This reproduces the lecture's own
%       aspect-ratio trade study, and its point. With Empty weight II the
%       wing weight is an areal density times an area, so it carries no
%       aspect ratio at all, and the study concludes that more AR is always
%       better. With Empty weight III the wing weight is Raymer Eq. 15.46,
%       which carries (A/cos^2 Lambda)^0.6, and a real minimum appears where
%       the induced-drag saving stops paying for the structure.
%
%    3  CONTOUR.  Fuel burn over the (S_ref, AR) plane - the lecture's
%       "contour plots" slide. Every point is a separately sized airplane.
%
%  Takes a few minutes: each point is a full sizing solve.

clear; clc; close all

json_path = ttpa_requirements_path();
J0 = jsondecode(fileread(json_path));

if ~strcmp(J0.sizing.mode, 'fixed_wing_area')
    warning('run_ttpa_trade_studies:ModeOverridden', ...
        ['The requirements file has sizing.mode = "%s". Trade studies need ', ...
         '"fixed_wing_area", because that is the mode in which S_ref is a ', ...
         'design variable. Overriding for this script only.'], J0.sizing.mode);
end

%% ------------------------------------------------------ 1. wing-area sweep
S_sweep = linspace(105, 190, 22);
fprintf('=== STUDY 1: wing area ===\n');
fprintf('  sweeping S_ref over %.0f to %.0f ft^2, %d points\n', ...
        S_sweep(1), S_sweep(end), numel(S_sweep));

r1 = sweep_(json_path, 'S_ref', S_sweep, struct());

[fuel_min, i1] = min(r1.W_fuel);
fprintf('  minimum fuel  %.1f lbf at S_ref = %.1f ft^2 (W_TO %.1f lbf, P_SL %.1f hp)\n', ...
        fuel_min, S_sweep(i1), r1.W_TO(i1), r1.P_SL(i1));
[wto_min, i1b] = min(r1.W_TO);
fprintf('  minimum W_TO  %.1f lbf at S_ref = %.1f ft^2\n', wto_min, S_sweep(i1b));

fig1 = figure('Name','Trade study: wing area','Color','w','Position',[60 60 1000 420]);
tiledlayout(fig1,1,2,'TileSpacing','compact','Padding','compact');
nexttile; hold on; grid on;
plot(S_sweep, r1.W_fuel, '-o', 'LineWidth', 1.6, 'MarkerSize', 4);
plot(S_sweep(i1), fuel_min, 'p', 'MarkerSize', 16, 'MarkerFaceColor',[0.95 0.75 0.10], ...
     'MarkerEdgeColor','k');
xlabel('S_{ref}  [ft^2]'); ylabel('mission fuel  W_{fuel}  [lbf]');
title(sprintf('Objective: minimum %.0f lbf at S_{ref} = %.0f ft^2', fuel_min, S_sweep(i1)));
nexttile; hold on; grid on;
yyaxis left;  plot(S_sweep, r1.W_TO, '-o', 'LineWidth', 1.6, 'MarkerSize', 4);
ylabel('W_{TO}  [lbf]');
yyaxis right; plot(S_sweep, r1.P_SL, '-s', 'LineWidth', 1.6, 'MarkerSize', 4);
ylabel('P_{SL}  [hp]');
xlabel('S_{ref}  [ft^2]'); title('The airplane the framework builds at each wing');

%% -------------------------------------------- 2. aspect ratio, both methods
AR_sweep = 6:0.5:12;
fprintf('\n=== STUDY 2: aspect ratio, both weight methods ===\n');
fprintf('  THE LECTURE''S POINT: Empty weight II has no AR in the wing weight.\n');

r2a = sweep_(json_path, 'AR', AR_sweep, struct('weights', "table_15_2"));
r2b = sweep_(json_path, 'AR', AR_sweep, struct('weights', "raymer_ga_III"));

% THE OBJECTIVE HERE IS MTOW, not fuel, because that is what the lecture
% plots on its aspect-ratio slide - and the distinction matters. Fuel keeps
% falling with aspect ratio under BOTH weight models, because a longer span
% always cuts induced drag. It is the TAKEOFF WEIGHT that shows the trade:
% the wing must get heavier to carry that span, and only a wing weight that
% knows about aspect ratio can charge for it.
report_min_('  Empty weight II  (Table 15.2)  ', AR_sweep, r2a.W_TO, 'lbf MTOW');
report_min_('  Empty weight III (Raymer 15.46)', AR_sweep, r2b.W_TO, 'lbf MTOW');

fig2 = figure('Name','Trade study: aspect ratio','Color','w','Position',[80 80 1000 420]);
tiledlayout(fig2,1,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; grid on;
plot(AR_sweep, r2a.W_TO, '-o', 'LineWidth', 1.8, 'MarkerSize', 4);
xlabel('aspect ratio'); ylabel('MTOW  [lbf]');
title({'Empty weight II  (Raymer Table 15.2)', 'wing = 2.5 psf x area, NO aspect ratio  ->  "more AR is always better"'});
nexttile; hold on; grid on;
plot(AR_sweep, r2b.W_TO, '-o', 'LineWidth', 1.8, 'MarkerSize', 4, 'Color', [0.85 0.33 0.10]);
[fb, ib] = min(r2b.W_TO);
plot(AR_sweep(ib), fb, 'p', 'MarkerSize', 16, 'MarkerFaceColor',[0.95 0.75 0.10], 'MarkerEdgeColor','k');
xlabel('aspect ratio'); ylabel('MTOW  [lbf]');
title({'Empty weight III  (Raymer Eq. 15.46)', ['wing carries (A/cos^2\Lambda)^{0.6}  ->  real minimum at AR = ' sprintf('%.1f', AR_sweep(ib))]});

%% ------------------------------------------------------- 3. contour, S x AR
S_c  = linspace(110, 175, 12);
AR_c = 6:1:11;
fprintf('\n=== STUDY 3: fuel-burn contours over (S_ref, AR) ===\n');
fprintf('  %d x %d = %d sizing solves, Empty weight III ...\n', ...
        numel(S_c), numel(AR_c), numel(S_c)*numel(AR_c));

Fuel = nan(numel(AR_c), numel(S_c));
WTO  = nan(numel(AR_c), numel(S_c));
t0 = tic;
for ia = 1:numel(AR_c)
    for is = 1:numel(S_c)
        try
            rv = size_one_(json_path, struct('S_ref', S_c(is), 'AR', AR_c(ia), ...
                                             'weights', "raymer_ga_III"));
            Fuel(ia, is) = rv.W_fuel;
            WTO(ia, is)  = rv.W_TO;
        catch
            % leave NaN - the airplane does not close there
        end
    end
end
fprintf('  done in %.1f s.  %d of %d points closed.\n', toc(t0), nnz(isfinite(Fuel)), numel(Fuel));

fig3 = figure('Name','Trade study: fuel burn over (S_ref, AR)','Color','w', ...
              'Position',[100 100 820 560]);
ax = axes(fig3); hold(ax,'on'); grid(ax,'on');
[Cc, hc] = contour(ax, S_c, AR_c, Fuel, 14, 'ShowText', 'on', 'LineWidth', 1.1);
clabel(Cc, hc, 'FontSize', 8);
[~, imin] = min(Fuel(:));
[ia, is] = ind2sub(size(Fuel), imin);
plot(ax, S_c(is), AR_c(ia), 'p', 'MarkerSize', 18, ...
     'MarkerFaceColor',[0.95 0.75 0.10], 'MarkerEdgeColor','k');
xlabel(ax, 'S_{ref}  [ft^2]'); ylabel(ax, 'aspect ratio');
title(ax, sprintf(['Mission fuel [lbf] over the design space   (Empty weight III)\n' ...
                   'minimum %.0f lbf at S_{ref} = %.0f ft^2, AR = %.1f'], ...
                   Fuel(imin), S_c(is), AR_c(ia)));

fprintf('\n  best point on the grid: S_ref %.0f ft^2, AR %.1f -> fuel %.1f lbf, W_TO %.1f lbf\n', ...
        S_c(is), AR_c(ia), Fuel(imin), WTO(imin));

%% ---------------------------------------------------------------- exports
outdir = fullfile(fileparts(mfilename('fullpath')), 'output');
if ~exist(outdir,'dir'), mkdir(outdir); end
exportgraphics(fig1, fullfile(outdir,'ttpa_trade_wing_area.png'),  'Resolution', 200);
exportgraphics(fig2, fullfile(outdir,'ttpa_trade_aspect_ratio.png'),'Resolution', 200);
exportgraphics(fig3, fullfile(outdir,'ttpa_trade_contour.png'),     'Resolution', 200);
fprintf('\nWrote output/ttpa_trade_*.png\n');


%% ============================ local functions ============================

function out = sweep_(json_path, var, values, change)
%SWEEP_  Size the airplane once per value of one design variable.
    n = numel(values);
    out.W_TO = nan(1,n); out.P_SL = nan(1,n); out.S_ref = nan(1,n);
    out.W_fuel = nan(1,n); out.W_OEW = nan(1,n);
    for i = 1:n
        ch = change;
        ch.(var) = values(i);
        try
            r = size_one_(json_path, ch);
            out.W_TO(i)=r.W_TO; out.P_SL(i)=r.P_SL; out.S_ref(i)=r.S_ref;
            out.W_fuel(i)=r.W_fuel; out.W_OEW(i)=r.W_OEW;
        catch
            % leave NaN
        end
    end
end

function r = size_one_(json_path, change)
%SIZE_ONE_  One full sizing solve with the given design variables applied.
    J = jsondecode(fileread(json_path));
    J.sizing.mode = 'fixed_wing_area';

    if isfield(change,'S_ref'),   J.sizing.S_ref_ft2 = change.S_ref; end
    if isfield(change,'AR'),      J.geometry.AR      = change.AR;    end
    if isfield(change,'weights'), J.weights.method   = char(change.weights); end
    if isfield(change,'mission'), J.missions.std_mission.method = char(change.mission); end

    tmp = fullfile(tempdir, sprintf('ttpa_trade_%d.json', feature('getpid')));
    fid = fopen(tmp,'w'); fwrite(fid, jsonencode(J)); fclose(fid);

    prop = TtpaProp(tmp);  geom = TtpaGeom(tmp, prop);
    aero = TtpaAero(tmp, geom);  wts = TtpaWeights(tmp, geom, prop);
    miss = MissionProfileReader.read_profile(tmp, 'std_mission');
    cons = ConstraintSetImporter.read_conditions(tmp);
    ob = struct('aero',aero,'prop',prop,'wts',wts,'geom',geom,'miss',miss,'cons',cons);

    C = J.constraints;  S = J.sizing;

    % The fixed-wing-area mode needs its OWN relaxation - it rings, because a
    % heavier airplane raises W/S, which the takeoff constraint answers with a
    % bigger and heavier engine. Using the design-point value of 0.5 here made
    % every Empty-weight-III point in the aspect-ratio study fail to converge.
    relax = S.relaxation_W;
    if isfield(S, 'relaxation_fixed_wing_area')
        relax = S.relaxation_fixed_wing_area;
    end

    o = struct('mode', "fixed_wing_area", 'S_ref', S.S_ref_ft2, ...
        'W_TO_guess', S.W_TO_guess_lbf, 'tol_rel', S.tol_rel, 'max_iter', 800, ...
        'relax_W', relax, 'relax_P', relax, ...
        'design_point_mode', "selected", ...
        'WS_sweep', linspace(C.wing_loading_range_psf(1), C.wing_loading_range_psf(2), 200), ...
        'selected', struct('WS', C.design_point.wing_loading_psf, ...
                           'WP', C.design_point.power_loading_lb_per_hp));

    ws = warning('off','all');
    cleanup = onCleanup(@() warning(ws));   %#ok<NASGU>

    % A trade study deliberately visits airplanes near the edge of what
    % closes, and the closure map gets stiffer as the design moves away from
    % the baseline. Back the damping off and retry before declaring a point
    % dead, so a gap in the plot means "no airplane exists here", not "the
    % solver gave up".
    r = [];
    for rx = [relax, 0.30, 0.20, 0.12]
        try
            o.relax_W = rx; o.relax_P = rx;
            r = sizing_loop(ob, o);
            if r.converged, break; end
        catch
            r = [];
        end
    end
    delete(tmp);
    if isempty(r) || ~r.converged
        error('run_ttpa_trade_studies:noClosure', 'no converged airplane here');
    end
end

function report_min_(label, x, y, unit)
    if all(isnan(y)), fprintf('%s  (no point closed)\n', label); return; end
    [ymin, i] = min(y);
    at_edge = (i == 1) || (i == numel(y));
    if at_edge
        fprintf('%s  minimum %.1f %s AT THE EDGE (AR = %.1f) - no interior optimum\n', ...
                label, ymin, unit, x(i));
    else
        fprintf('%s  minimum %.1f %s at AR = %.1f  <- a REAL interior optimum\n', ...
                label, ymin, unit, x(i));
    end
end
