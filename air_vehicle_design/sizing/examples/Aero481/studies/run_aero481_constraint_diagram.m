%% run_aero481_constraint_diagram
%   F-35 (Aero 481 Design01 provenance) constraint diagram (T/W vs W/S). Builds
%   the F-35 L1 discipline stack, aggregates the 12 Aero 481 constraint conditions
%   (Aero481ConstraintSet.constraint_map, reading aero481_requirements.json) through the
%   generic ConstraintAnalysis, draws the diagram, and marks the Design01 design
%   point.
%
%   TWELVE CONSTRAINTS -- ALIGNED WITH AERO 481. The diagram carries exactly the
%   12 ACTIVE Aero 481 constraints: Cruise, Dash, two sustained turns, six SEP
%   points, instantaneous turn, and ceiling. The six FAR-25 climb gradients and
%   the framework-only Takeoff/Landing were dropped (user decision; see
%   Aero481ConstraintSet). The six SEP rows evaluate at the Aero 481 50%-fuel COMBAT
%   weight (beta = 0.8285 in the requirements JSON); the other rows stay at
%   takeoff weight, matching Aero 481.
%
%   W/S SWEEP -- AERO 481 RANGE. Aero 481's TW_WS.m sweeps 200-700 kgf/m^2 =
%   200*9.807/47.880 .. 700*9.807/47.880 psf ~ 41 .. 143 psf. This script uses
%   linspace(41, 143, 200) psf to match.
%
%   NO OPTIMUM MARKER. Aero 481 computes no optimum, and for a fighter the
%   least-T/W ("small-engine") corner is meaningless -- the design region is a
%   HIGH T/W, moderate W/S corner set by the maneuver / SEP / dash constraints.
%   This script therefore marks only the DESIGNER'S chosen Design01 point, read
%   off the diagram, at (W/S = 92.17 psf, T/W = 1.2) [A481 Design01.m:20-21] --
%   NOT an optimum computed by the aggregator.
%
%   Style/wiring follows examples/B777/studies/run_b777_constraint_diagram.m and
%   examples/F16A/studies/run_F16_constraint_diagram.m (caller owns discipline
%   construction -- dependency injection); the figure/JSON/MD export into the
%   gitignored examples/Aero481/output/ follows the sanity_checks scripts.
%
%   READING THE DIAGRAM -- THIS IS A FIGHTER, NOT A JET TRANSPORT. For a jet
%   transport (the B777) down-and-to-the-right is better (low T/W = small engine,
%   high W/S = small efficient wing). A FIGHTER reads the OPPOSITE way for T/W:
%   sustained-turn / specific-excess-power / dash requirements DEMAND a high T/W,
%   so the design region is a HIGH T/W, moderate W/S corner. The binding
%   producers here are the maneuver constraints (sustained turn, SEP, dash),
%   which push the envelope UP.

% Caller owns discipline construction (dependency injection): build the F-35 L1
% aero/prop pair explicitly, then hand it to the constraint set. Aero481AeroL1 is
% geometry-light (no injected geometry object): AR and Lambda_LE_deg are scalar
% wing-spec inputs read straight from the .aerodynamics JSON block.
sp   = aero481_spec_path(1);
rp   = aero481_requirements_path();
prop = Aero481PropL1(sp);
aero = Aero481AeroL1(sp);

% W/S sweep [psf]: Aero 481's TW_WS.m range 200-700 kgf/m^2 = ~41..143 psf
% (200*9.807/47.880 .. 700*9.807/47.880). 200 points.
WS_sweep = linspace(41, 143, 200);

ca = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
    Aero481ConstraintSet.constraint_map(), WS_sweep);

fig = ca.plot_diagram();

% Force a light theme for batch export (plot_diagram, unlike TSDiagram.plot,
% does not set these itself). See run_b777_constraint_diagram.m for the idiom.
fig.Color = 'w';
if isprop(fig, 'Theme'), fig.Theme = 'light'; end

% NO design point is marked (removed 2026-08-15, user request -- a single marked
% point on top of the constraint curves was confusing). The diagram shows only
% the constraint curves + the feasible envelope; the meaningful design-driving
% numbers (the binding T/W floor, the stall/approach W/S wall, and the corner
% where they meet) are reported below and exported.
ax = fig.CurrentAxes;
title(ax, 'Aero 481 Design01 Constraint Diagram');

% Design-driving numbers off the live envelope: the binding T/W floor, the
% stall/approach W/S wall, and the least-T/W feasible corner (wall / floor).
env = ca.envelope();                       % 1 x numel(WS_sweep)
[env_min, i_min] = min(env);
walls   = ca.constraints(cellfun(@(c) isa(c, 'Only_WbyS'), ca.constraints));
WS_wall = min(cellfun(@(c) c.WS_max(), walls));       % stall/approach wall [psf]
TW_wall = interp1(WS_sweep, env, WS_wall, 'linear', NaN);

fprintf('\nAero 481 Design01 constraint diagram\n');
fprintf('  13 constraints (12 Aero 481 active + Stall approach wall); W/S sweep %.0f..%.0f psf (Aero 481 range)\n', ...
    min(WS_sweep), max(WS_sweep));
fprintf('  Stall/approach W/S wall: %.1f psf\n', WS_wall);
fprintf('  Envelope T/W floor: min %.4f at W/S %.1f psf; at the wall T/W = %.4f\n', ...
    env_min, WS_sweep(i_min), TW_wall);
fprintf('  Design corner (wall / binding-floor intersection): W/S = %.1f psf, T/W = %.4f\n', WS_wall, TW_wall);

% ---- Exports into the gitignored output/ (sanity_checks pattern) ---------- %
outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
if ~exist(outdir, 'dir'), mkdir(outdir); end

exportgraphics(fig, fullfile(outdir, 'aero481_constraint_diagram.png'), 'Resolution', 200);

results = struct( ...
    'stack',            'Aero 481 Design01 L1 disciplines', ...
    'n_constraints',    numel(ca.constraints), ...
    'WS_sweep_psf',     WS_sweep, ...
    'envelope_TW',      env, ...
    'stall_wall_WS_psf', WS_wall, ...
    'design_corner',    struct('WS_psf', WS_wall, 'TW', TW_wall, ...
                         'note', 'wall / binding-floor intersection -- the least-T/W feasible point; no arbitrary design point is marked'));
fid = fopen(fullfile(outdir, 'aero481_constraint_diagram.json'), 'w');
fwrite(fid, jsonencode(results, 'PrettyPrint', true));
fclose(fid);

L = strings(0, 1);
L(end+1) = "# Aero 481 Design01 Constraint Diagram";
L(end+1) = "";
L(end+1) = "Generated by `studies/run_aero481_constraint_diagram.m` over the Aero 481 Design01 L1 stack.";
L(end+1) = "Thirteen constraints: cruise/dash + 2 sustained turns + 6 SEP + instantaneous turn +";
L(end+1) = "ceiling (12 Aero 481 active) + a Stall (approach) W/S wall. The 6 FAR-25 climb gradients";
L(end+1) = "and the framework-only Takeoff/Landing were dropped (user decision; see Aero481ConstraintSet).";
L(end+1) = "The 6 SEP rows use the Aero 481 50%-fuel combat weight (beta = 0.8285).";
L(end+1) = "";
L(end+1) = "FIGHTER reading: high T/W is the design region (maneuver/SEP/dash push the envelope UP).";
L(end+1) = "No design point is marked. The design-driving numbers are the binding T/W floor (SEP2 SL),";
L(end+1) = "the stall/approach W/S wall, and the corner where they meet.";
L(end+1) = "";
L(end+1) = sprintf("- W/S sweep: %.0f to %.0f psf (%d points, Aero 481 range)", ...
    min(WS_sweep), max(WS_sweep), numel(WS_sweep));
L(end+1) = sprintf("- Stall/approach W/S wall: %.1f psf", WS_wall);
L(end+1) = sprintf("- Design corner (wall / binding-floor): W/S = %.1f psf, T/W = %.4f", WS_wall, TW_wall);
L(end+1) = "";
L(end+1) = "The framework applies a thrust lapse Aero 481 does NOT (discrepancy A6), so its";
L(end+1) = "envelope sits at a different T/W than the raw A481 curves. See `sanity_checks/aero481_comparison.m`.";
L(end+1) = "";
L(end+1) = "Figure: `aero481_constraint_diagram.png`. Full envelope: `aero481_constraint_diagram.json`.";
writelines(L, fullfile(outdir, 'aero481_constraint_diagram.md'));

fprintf('\nWrote output/aero481_constraint_diagram.png, .json and .md\n');
