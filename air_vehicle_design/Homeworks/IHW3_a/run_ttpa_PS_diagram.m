%% run_ttpa_PS_diagram.m
%  IHW3a - TTPA dimensional P-S sizing diagram.
%
%    gray    the weight does not close at all - no airplane exists there
%    blue    a sized airplane that also meets every requirement
%    white   a sized airplane that FAILS at least one requirement
%    curves  the least engine each requirement allows, at that wing
%    the feasible region is ABOVE every curve and RIGHT of the wall,
%    because for a propeller more power and more wing are always allowed
%
%  The lowest point of the blue region is the least-power airplane. It is
%  where Takeoff (power falling with wing area) crosses Cruise Speed (power
%  rising with wing area), and it is the same corner the IHW2 matching
%  diagram finds at (W/S, W/P) = (37.37, 10.50) - now in dimensional form.
%
%  RELAXATION. The TTPA closure needs damping: at relax_W0 = 1 an early step
%  overshoots into the region where the empty weight and the fuel consume
%  the whole takeoff weight. The default 0.5 is kept here.
%
%  Run it from this folder. Takes a minute or two - it sizes a few thousand
%  airplanes.

clear; clc; close all

%% -------------------------------------------------------- 1. build and size
obj = ttpa_disciplines();
J   = jsondecode(fileread(ttpa_requirements_path()));
S   = J.sizing;
C   = J.constraints;

opts.W_TO_guess        = S.W_TO_guess_lbf;
opts.design_point_mode = string(S.design_point_mode);
opts.tol_rel           = S.tol_rel;
opts.max_iter          = S.max_iter;
opts.relax_W           = S.relaxation_W;
opts.relax_P           = S.relaxation_P;
opts.WS_sweep          = linspace(C.wing_loading_range_psf(1), ...
                                  C.wing_loading_range_psf(2), ...
                                  C.wing_loading_points);
opts.selected.WS = C.design_point.wing_loading_psf;
opts.selected.WP = C.design_point.power_loading_lb_per_hp;

result = sizing_loop(obj, opts);

fprintf('\nTTPA P-S sizing diagram\n');
fprintf('  sizing_loop converged: W_TO %.1f lbf , P_SL %.1f hp , S_ref %.2f ft^2\n', ...
        result.W_TO, result.P_SL, result.S_ref);

%% ------------------------------------------------------------- 2. the grids
% Uniform grids (the shading images assume uniform spacing), bracketing the
% converged design so it sits well inside the picture. 55 x 55 keeps the
% stair-step edge of the shaded region fine enough to read against the
% traced curves; the whole scan is about half a minute.
%
% The upper limit is a READABILITY choice, not a physical one. The TTPA
% weight stops closing near 1500 hp, so a grid that reached it would squash
% the wedge that matters into the bottom sliver of the axes.
S_grid = linspace(100, 230, 55);    % ft^2
P_grid = linspace(300, 900, 55);    % hp

d = TtpaPSDiagram(obj);
% relax_W0 and max_iter_W0 left at their defaults - see the header.

%% ------------------------------------------ 3. the cell containing the design
% converge_W0 at the sized cell must reproduce sizing_loop, because the inner
% fixed point is the same one. This is the check that the diagram and the
% loop are the same calculation.
W0_cell = d.converge_W0(result.P_SL, result.S_ref);
fprintf('  converge_W0 at that cell:   %.1f lbf  (sizing_loop %.1f, %+.2e relative)\n', ...
        W0_cell, result.W_TO, (W0_cell - result.W_TO) / result.W_TO);

%% -------------------------------------------------------------- 4. the scan
fprintf('  scanning %d x %d = %d cells ...\n', numel(P_grid), numel(S_grid), ...
        numel(P_grid) * numel(S_grid));
t0 = tic;
fg = d.fuel_grid(P_grid, S_grid);
fprintf('  done in %.1f s.  no sized airplane in %d of %d cells; %d feasible.\n', ...
        toc(t0), nnz(~isfinite(fg.W0)), numel(fg.W0), nnz(fg.feasible));

%% ------------------------------------------------------------- 5. the markers
markers = struct( ...
    'P', {result.P_SL, 5354 / opts.selected.WP}, ...
    'S', {result.S_ref, 5354 / opts.selected.WS}, ...
    'label', {sprintf('IHW3a sized  (%.0f hp, %.0f ft^2)', result.P_SL, result.S_ref), ...
              sprintf('IHW1/IHW2 baseline  (%.0f hp, %.0f ft^2)', ...
                      5354/opts.selected.WP, 5354/opts.selected.WS)});

%% -------------------------------------------------------------- 6. the plot
[fig, info] = d.plot('S_grid', S_grid, 'P_grid', P_grid, ...
                     'markers', markers, 'grid', fg);

lp = info.least_power;
fprintf('\n  least-power airplane   P = %.1f hp , S = %.1f ft^2 , W_TO = %.1f lbf\n', ...
        lp.P, lp.S, lp.W);
fprintf('  IHW3a design           P = %.1f hp , S = %.1f ft^2 , W_TO = %.1f lbf\n', ...
        result.P_SL, result.S_ref, result.W_TO);
fprintf('  price of the margin    %+.1f hp , %+.1f ft^2 , %+.1f lbf\n', ...
        result.P_SL - lp.P, result.S_ref - lp.S, result.W_TO - lp.W);
fprintf('  (the same margin the IHW2 matching diagram shows as +5.9%% on power)\n');

%% ------------------------------------------------------------- 7. the exports
outdir = fullfile(fileparts(mfilename('fullpath')), 'output');
if ~exist(outdir, 'dir'), mkdir(outdir); end

exportgraphics(fig, fullfile(outdir, 'ttpa_PS_diagram.png'), 'Resolution', 200);

results = struct( ...
    'stack',       'TTPA IHW3a: L2 geometry, Raymer Tbl 15.2 weights, L1 mission, IHW2 constraints', ...
    'S_grid_ft2',  S_grid, ...
    'P_grid_hp',   P_grid, ...
    'W0_lbf',      fg.W0, ...        % closed takeoff weight per cell, NaN = none
    'W_fuel_lbf',  fg.W_fuel, ...    % mission fuel per cell
    'feasible',    fg.feasible, ...
    'relax_W0',    d.relax_W0, ...
    'design',      struct('P_SL_hp', result.P_SL, 'S_ref_ft2', result.S_ref, ...
                          'W_TO_lbf', result.W_TO, 'W_TO_from_cell_lbf', W0_cell), ...
    'least_power', info.least_power);
fid = fopen(fullfile(outdir, 'ttpa_PS_diagram.json'), 'w');
fwrite(fid, jsonencode(results, 'PrettyPrint', true));
fclose(fid);

L = strings(0, 1);
L(end+1) = "# TTPA P-S Sizing Diagram";
L(end+1) = "";
L(end+1) = "Generated by `run_ttpa_PS_diagram.m`. The propeller form of the metabook";
L(end+1) = "T-S diagram (Fig. 4.7): every grid point is a sized airplane.";
L(end+1) = "";
L(end+1) = sprintf("- S grid: %.0f to %.0f ft^2 (%d points)", min(S_grid), max(S_grid), numel(S_grid));
L(end+1) = sprintf("- P grid: %.0f to %.0f hp (%d points)", min(P_grid), max(P_grid), numel(P_grid));
L(end+1) = sprintf("- relax_W0 = %.2f", d.relax_W0);
L(end+1) = sprintf("- IHW3a design: P_SL = %.1f hp, S_ref = %.2f ft^2, W_TO = %.1f lbf", ...
    result.P_SL, result.S_ref, result.W_TO);
L(end+1) = sprintf("- converge_W0 at that cell reproduces the loop to %+.2e relative", ...
    (W0_cell - result.W_TO) / result.W_TO);
L(end+1) = sprintf("- cells with no sized airplane: %d of %d", nnz(~isfinite(fg.W0)), numel(fg.W0));
L(end+1) = sprintf("- feasible cells: %d of %d", nnz(fg.feasible), numel(fg.feasible));
L(end+1) = sprintf("- least-power airplane: P = %.1f hp, S = %.1f ft^2, W_TO = %.1f lbf", ...
    info.least_power.P, info.least_power.S, info.least_power.W);
L(end+1) = sprintf("- price of the design margin: %+.1f hp, %+.1f ft^2, %+.1f lbf", ...
    result.P_SL - info.least_power.P, result.S_ref - info.least_power.S, ...
    result.W_TO - info.least_power.W);
L(end+1) = "";
L(end+1) = "Feasible is ABOVE every curve and RIGHT of the wall: for a propeller,";
L(end+1) = "more power and more wing are always allowed.";
L(end+1) = "";
L(end+1) = "Figure: `ttpa_PS_diagram.png`. Full grids: `ttpa_PS_diagram.json`.";
writelines(L, fullfile(outdir, 'ttpa_PS_diagram.md'));

fprintf('\nWrote output/ttpa_PS_diagram.png, .json and .md\n');
