%% run_b777_constraint_diagram
%   Boeing 777-200LR constraint diagram (T/W vs W/S) [metabook Example 4.2,
%   Fig. 4.6]. Builds the B777 L1 discipline stack, aggregates the ten
%   constraint conditions (B777ConstraintSet.constraint_map, reading
%   b777_requirements.json) through the generic ConstraintAnalysis, draws the
%   diagram, and overlays the ACTUAL 777-200LR design point for reference.
%
%   Style/wiring follows examples/F16A/studies/run_F16_constraint_diagram.m
%   (caller owns discipline construction -- dependency injection); the
%   figure/JSON/MD export into the gitignored examples/B777/output/ follows the
%   sanity_checks scripts and run_F16_TS_diagram.m.
%
%   READING THE DIAGRAM. For a transport the min-T/W optimal_point lands at LOW
%   W/S: the takeoff-field-length line rises with W/S and dominates the envelope
%   at high W/S, so the smallest-T/W feasible point sits at the left edge of the
%   sweep. That point is NOT the transport design point -- a transport is
%   designed at HIGH W/S (a small, efficient wing at high wing loading). The
%   diagram is therefore read by INSPECTION against the actual-777 marker at
%   (W/S = 142.45, T/W = 0.287) [metabook Table 4.3 / Fig. 4.7 caption], which
%   the metabook shows sitting inside the feasible region. The reported
%   optimal_point is printed for completeness but flagged as the low-W/S envelope
%   minimum, not the design intent.

% Caller owns discipline construction (dependency injection): build the B777 L1
% aero/prop pair explicitly, then hand it to the constraint set. B777AeroL1
% injects the geometry object so its clean CD0 tracks the wing area.
sp   = b777_spec_path(1);
rp   = b777_requirements_path();
geom = B777GeomL1(sp);
prop = B777PropL1(sp);
aero = B777AeroL1(geom, sp);

% W/S sweep [psf]: 60..300 covers the actual 777 at 142.45 and the landing-wall
% W/S ~ 294.5 [metabook Eq. 4.46, 113.27*2.6]. 241 points -> ~1 psf resolution.
WS_sweep = linspace(20, 340, 321);   % from low W/S so the cruise curve forms the left boundary (metabook Fig 4.6)

ca = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
    B777ConstraintSet.constraint_map(), WS_sweep);

fig = ca.plot_diagram();

% Force a light theme for batch export (plot_diagram, unlike TSDiagram.plot,
% does not set these itself). See run_F16_TS_diagram.m for the idiom.
fig.Color = 'w';
if isprop(fig, 'Theme'), fig.Theme = 'light'; end

% Actual 777-200LR design-point marker [metabook Table 4.3: W/S = 142.45 psf;
% Fig. 4.7 caption: T = 220000 lbf at W0 = 766800 lbf -> T/W = 0.287]. The
% metabook shows it inside the feasible region.
WS_actual = 142.45;
TW_actual = 220000 / 766800;   % = 0.2869
ax = fig.CurrentAxes;
hold(ax, 'on');
plot(ax, WS_actual, TW_actual, 'kp', 'MarkerSize', 16, 'LineWidth', 1.0, ...
    'MarkerFaceColor', [0.95 0.75 0.10], ...
    'DisplayName', sprintf('Actual 777-200LR (W/S=%.1f, T/W=%.3f)', WS_actual, TW_actual));
title(ax, 'B777-200LR Constraint Diagram [metabook Fig. 4.6]');
hold(ax, 'off');

% Envelope minimum (low-W/S; see header -- NOT the transport design point).
[WS_opt, TW_opt] = ca.optimal_point();
fprintf('\nB777 constraint diagram [metabook Fig. 4.6]\n');
fprintf('  Envelope min (low-W/S, NOT the design point): W/S = %.2f psf, T/W = %.4f\n', ...
    WS_opt, TW_opt);
fprintf('  Actual 777-200LR marker: W/S = %.2f psf, T/W = %.4f [metabook Table 4.3]\n', ...
    WS_actual, TW_actual);

% Is the actual-777 point feasible against the live envelope + walls? Read the
% envelope T/W and the tightest wall at the actual W/S by interpolation.
env      = ca.envelope();              % 1 x numel(WS_sweep)
TW_env_at_actual = interp1(WS_sweep, env, WS_actual, 'linear', NaN);
% Tightest W/S wall (smallest WS_max over the Only_WbyS constraints).
walls = ca.constraints(cellfun(@(c) isa(c, 'Only_WbyS'), ca.constraints));
if isempty(walls)
    wall_min = Inf;
else
    wall_min = min(cellfun(@(c) c.WS_max(), walls));
end
actual_feasible = (TW_actual >= TW_env_at_actual) && (WS_actual <= wall_min);
fprintf('  At W/S = %.2f: envelope demands T/W = %.4f, tightest wall W/S = %.2f psf\n', ...
    WS_actual, TW_env_at_actual, wall_min);
fprintf('  Actual 777 marker feasible: %s\n', mat2str(actual_feasible));

% ---- Exports into the gitignored output/ (sanity_checks pattern) ---------- %
outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
if ~exist(outdir, 'dir'), mkdir(outdir); end

exportgraphics(fig, fullfile(outdir, 'b777_constraint_diagram.png'), 'Resolution', 200);

results = struct( ...
    'stack',          'B777 L1 disciplines (metabook Example 4.2)', ...
    'WS_sweep_psf',   WS_sweep, ...
    'envelope_TW',    env, ...
    'wall_min_psf',   wall_min, ...
    'optimum',        struct('WS_psf', WS_opt, 'TW', TW_opt, ...
                         'note', 'low-W/S envelope minimum, NOT the transport design point'), ...
    'actual_777',     struct('WS_psf', WS_actual, 'TW', TW_actual, ...
                         'TW_envelope_at_actual', TW_env_at_actual, ...
                         'feasible', actual_feasible, ...
                         'cite', 'metabook Table 4.3 / Fig. 4.7 caption'));
fid = fopen(fullfile(outdir, 'b777_constraint_diagram.json'), 'w');
fwrite(fid, jsonencode(results, 'PrettyPrint', true));
fclose(fid);

L = strings(0, 1);
L(end+1) = "# B777-200LR Constraint Diagram [metabook Fig. 4.6]";
L(end+1) = "";
L(end+1) = "Generated by `studies/run_b777_constraint_diagram.m` over the B777 L1 stack.";
L(end+1) = "Ten constraints (2 field-length + 6 FAR-25 climb + ceiling + cruise).";
L(end+1) = "";
L(end+1) = sprintf("- W/S sweep: %.0f to %.0f psf (%d points)", ...
    min(WS_sweep), max(WS_sweep), numel(WS_sweep));
L(end+1) = sprintf("- Envelope minimum (LOW W/S, not the design point): W/S = %.2f psf, T/W = %.4f", ...
    WS_opt, TW_opt);
L(end+1) = sprintf("- Tightest W/S wall (landing field length): %.2f psf", wall_min);
L(end+1) = sprintf("- Actual 777-200LR marker: W/S = %.2f psf, T/W = %.4f [metabook Table 4.3]", ...
    WS_actual, TW_actual);
L(end+1) = sprintf("- Envelope T/W demanded at the actual W/S: %.4f -> marker feasible: %s", ...
    TW_env_at_actual, string(actual_feasible));
L(end+1) = "";
L(end+1) = "A transport is designed at HIGH W/S (small efficient wing); the low-W/S envelope";
L(end+1) = "minimum is NOT the design point. Read the diagram by inspection against the marker.";
L(end+1) = "";
L(end+1) = "Figure: `b777_constraint_diagram.png`. Full envelope: `b777_constraint_diagram.json`.";
writelines(L, fullfile(outdir, 'b777_constraint_diagram.md'));

fprintf('\nWrote output/b777_constraint_diagram.png, .json and .md\n');
