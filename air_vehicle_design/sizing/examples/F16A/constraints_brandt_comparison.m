function T = constraints_brandt_comparison()
%CONSTRAINTS_BRANDT_COMPARISON  F-16A constraint analysis vs Brandt ground truth.
%
%   This report proves the src constraint-analysis code reproduces
%   BrandtConstraintAnalysis when both sides read Brandt's OWN aerodynamics and
%   propulsion. It replaces the pass/fail unit test
%   tests/constraints/TestConstraintAnalysisVsBrandt.m: per CLAUDE.md's two-tier
%   rule, a Brandt comparison must be an informational report, NOT a
%   run_all_tests gate.
%
%   ─── WHAT THIS ISOLATES ─────────────────────────────────────────────────
%   The src ConstraintAnalysis aggregator and the src constraint classes
%   (MasterEquationConstraint subtree, TakeoffConstraint, LandingConstraint)
%   assemble Mattingly's Master Equation and the ground-roll relations
%   independently of BrandtConstraintAnalysis, which implements the same
%   equations against the Brandt-F16-A.xls Consts tab. Both sides run on
%   IDENTICAL aerodynamics and propulsion -- Brandt's own BrandtAerodynamics /
%   BrandtEngine, injected into src through BrandtAeroAdapter / BrandtPropAdapter
%   -- so any difference in the constraint curves or the optimum comes from the
%   src constraint-ASSEMBLY logic alone, not from a difference in CD0, K1 or
%   thrust lapse. This report checks the src ASSEMBLY, not the drag or thrust
%   model.
%
%   ─── THE TWO ACCOUNTED-FOR MODELING CHOICES ─────────────────────────────
%   1. K2 = 0. BrandtAeroAdapter.drag_polar returns K2 = 0, because Brandt's
%      Consts tab uses the symmetric parabolic polar (CD0 + K1*CL^2, no linear
%      camber term). That makes the src Master Equation's C term
%      (K2*n*beta/alpha) drop out, so the src equation reduces to Brandt's exact
%      form. The two curves are then algebraically identical given the same
%      CD0/K1/alpha, so the agreement below holds across the WHOLE W/S sweep,
%      not only at the sampled points.
%   2. Shared W/S grid. Both sides sweep the SAME fine wing-loading array, so
%      the two grid-argmin optima are directly comparable. A coarse or
%      mismatched grid would move the argmin independently of any equation
%      difference.
%   The only remaining difference is the dynamic pressure q: src builds it inside
%   AircraftState (atmosisa -> English units via its own conversion factors),
%   while BrandtConstraintAnalysis builds q inline (atmosisa -> rho/515.379,
%   a/0.3048). Both paths use atmosisa, so they agree to well under 1 %.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> constraints_brandt_comparison
%   Or non-interactively:
%     $ matlab -batch "addpath(genpath('src')); addpath(genpath('examples')); constraints_brandt_comparison"
%   The script adds VnV/BrandtF16A (and its GroundTruth folder) to the path
%   itself, so the Brandt classes and the two adapters are found without any
%   extra setup.
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%   Both sides are fed Brandt's OWN disciplines. The Brandt chain builds first
%   (each analyze()d before the next feeds it):
%       geom = BrandtGeometry();            geom.analyze();
%       aero = BrandtAerodynamics(geom);    aero.analyze();
%       eng  = BrandtEngine();              eng.analyze();
%   BrandtConstraintAnalysis(aero, eng) is the REFERENCE. The src side wraps the
%   SAME aero/eng in BrandtAeroAdapter / BrandtPropAdapter and assembles the src
%   constraint set through buildSrcConstraints below. Ground truth is never a
%   src input -- it is only the comparison target.
%
%   The constraint CONDITIONS are read from the requirements JSON
%   (f16a_requirements_path()); the src set mirrors F16ConstraintSet's dispatch
%   and uses the SAME 8 constraints Brandt's envelope uses -- 6 Master-Equation
%   specializations + Takeoff + Landing, with NO Stall (the Brandt reproduction
%   set has none).
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     jsons/constraints_brandt_comparison.json   full table + metadata
%     mds/constraints_brandt_comparison.md        rendered markdown
%   Both via src/reporting/ComparisonReport.m, shared by all discipline reports
%   so their columns cannot drift apart. The script ALSO opens two figures
%   side-by-side: the src constraint diagram (src_ca.plot_diagram) on the left
%   and Brandt's own diagram (brandtCA.plot_constraint_diagram) on the right, so
%   the two envelopes can be read against each other by eye.
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]    Brandt-F16-A.xls Consts tab, replicated in
%                 VnV/BrandtF16A/BrandtConstraintAnalysis.m
%     [Mattingly] Aircraft Engine Design 2nd ed., AIAA, 2002 -- Master Equation
%     [Raymer]    Aircraft Design 6th ed., AIAA, 2018 -- constraint diagram (ch. 5),
%                 takeoff/landing ground-roll relations
%
%   NOT A TEST: informational only, never pass/fail, and no value here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule).

% ── Self-contained path setup: add the Brandt classes + adapters ─────────── %
script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
vnv_dir     = fullfile(sizing_root, 'VnV', 'BrandtF16A');
if isempty(which('BrandtConstraintAnalysis'))
    addpath(vnv_dir);
    addpath(fullfile(vnv_dir, 'GroundTruth'));
end

% Shared fine W/S grid for BOTH sides (psf). Dense enough that the grid argmin
% lands near Brandt's optimum W/S; identical on both sides so the argmina are
% directly comparable (accounted-for modeling choice 2).
WS_GRID = linspace(20, 160, 141);

% W/S at which the per-condition required T/W rows are sampled (psf). A single
% representative wing loading inside the feasible band.
WS_SAMPLE = 90;

% ── Brandt discipline chain (each analyze()d before the next) ────────────── %
geom = BrandtGeometry();              geom.analyze();
brandtAero = BrandtAerodynamics(geom); brandtAero.analyze();
brandtEng  = BrandtEngine();           brandtEng.analyze();

% ── Reference: Brandt's own constraint analysis over the shared grid ─────── %
brandtCA = BrandtConstraintAnalysis(brandtAero, brandtEng);
brandtCA.analyze();
br = brandtCA.run(WS_GRID);

% ── src side: adapters wrap Brandt's aero/prop; build the src set ────────── %
aero_adapter = BrandtAeroAdapter(brandtAero);
prop_adapter = BrandtPropAdapter(brandtEng);
constraints  = buildSrcConstraints(aero_adapter, prop_adapter);
src_ca       = ConstraintAnalysis(constraints, WS_GRID);

% ── Sample Brandt's per-condition curves at WS_SAMPLE (interpolate grid) ─── %
% The Brandt result arrays are over WS_GRID; interp1 reads them at WS_SAMPLE.
brAt = @(col) interp1(WS_GRID(:), col(:), WS_SAMPLE);

% ── src per-condition required T/W at WS_SAMPLE, looked up by name ───────── %
srcTW = @(nm) srcRequiredTW(src_ca, nm, WS_SAMPLE);

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %
T = table();

% ── Optimum design point (shared grid) ──────────────────────────────────── %
[WS_opt_src, TW_opt_src] = src_ca.optimal_point();
T = [T; srow('[OPTIMUM DESIGN POINT (shared W/S grid)]')];
T = [T; arow('Optimum W/S [psf]', 'src', WS_opt_src, br.WS_opt, '%.3f', ...
        'Brandt Size&Opt (grid argmin over shared W/S array)', ...
        ['Both sides argmin the SAME producer envelope over the SAME grid; the ' ...
         'two argmina coincide because the curves are algebraically identical ' ...
         '(K2 = 0). Isolates the src optimum search.'])];
T = [T; arow('Optimum T/W [-]', 'src', TW_opt_src, br.TW_opt, '%.4f', ...
        'Brandt Size&Opt (grid argmin over shared W/S array)', ...
        'src ConstraintAnalysis.optimal_point vs Brandt run().TW_opt on the shared grid.')];

% ── Per-condition required T/W at W/S = WS_SAMPLE ────────────────────────── %
% src name (from requirements JSON) -> Brandt result column at WS_SAMPLE.
T = [T; srow(sprintf('[PER-CONDITION required T/W at W/S = %g psf]', WS_SAMPLE))];
T = [T; arow('Max Mach', 'src', srcTW("Max Mach"), brAt(br.TW_max_mach), '%.4f', ...
        'Brandt Consts!K23 (max_mach row)', ...
        'M=1.6, h=36 kft, n=1, 100% AB. src ExcessPower/LevelFlight Master-Eq row vs Brandt max_mach.')];
T = [T; arow('Cruise', 'src', srcTW("Cruise"), brAt(br.TW_cruise), '%.4f', ...
        'Brandt Consts!K24 (cruise row)', ...
        'M=0.87, h=36 kft, n=1, mil (dry) power. src Cruise Master-Eq row vs Brandt cruise; mil thrust lapse via the prop adapter.')];
T = [T; arow('Max Alt', 'src', srcTW("Max Alt"), brAt(br.TW_max_alt), '%.4f', ...
        'Brandt Consts!K25 (max_alt row)', ...
        'h=50 kft ceiling, M=0.87, n=1, 100% AB, Ps=0. src Max Alt Master-Eq row vs Brandt max_alt.')];
T = [T; arow('Combat Turn 1 (subsonic)', 'src', srcTW("Combat Turn 1 (subsonic)"), brAt(br.TW_combat_turn_sub), '%.4f', ...
        'Brandt Consts!K26 (combat_turn_sub row)', ...
        'h=20 kft, M=0.87, n=4.5, 100% AB, Ps=0. src SustainedTurn Master-Eq row vs Brandt combat_turn_sub.')];
T = [T; arow('Combat Turn 2 (supersonic)', 'src', srcTW("Combat Turn 2 (supersonic)"), brAt(br.TW_combat_turn_sup), '%.4f', ...
        'Brandt Consts!K27 (combat_turn_sup row)', ...
        'h=36 kft, M=1.4, n=1.4, 100% AB, Ps=0. src SustainedTurn Master-Eq row vs Brandt combat_turn_sup.')];
T = [T; arow('Excess Power', 'src', srcTW("Excess Power"), brAt(br.TW_ps500), '%.4f', ...
        'Brandt Consts!K28 (ps_500 row)', ...
        'h=10 kft, M=0.87, n=1, 100% AB, Ps=500 ft/s. src ExcessPower Master-Eq row vs Brandt ps_500.')];
T = [T; arow('Takeoff', 'src', srcTW("Takeoff"), brAt(br.TW_takeoff), '%.4f', ...
        'Brandt Consts!K32 (takeoff row)', ...
        'Ground-roll T/W, S_TO limit, beta=1. src TakeoffConstraint (Raymer ground-roll) vs Brandt takeoff.')];

% ── Field / wall: landing W/S limit ──────────────────────────────────────── %
T = [T; srow('[FIELD / WALL]')];
src = src_ca.constraints;
idx = find(cellfun(@(c) c.name == "Landing", src), 1);
WS_land_src = src{idx}.WS_max();
T = [T; arow('Landing W/S limit [psf]', 'src', WS_land_src, br.WS_landing_max, '%.3f', ...
        'Brandt Consts!K33 (landing wall)', ...
        ['A W/S upper bound (vertical wall), independent of T/W. src ' ...
         'LandingConstraint.WS_max vs Brandt run().WS_landing_max; the src ' ...
         'set skips Stall, so Landing is the only wall here.'])];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY + EXPORT — shared renderer (src/reporting/ComparisonReport.m)
% ════════════════════════════════════════════════════════════════════════ %
meta = struct( ...
    'title',         'F-16A Block 10/15 — Constraint Analysis vs Ground Truth', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('Shared W/S grid linspace(%g,%g,%d) psf; per-condition rows sampled at W/S = %g psf.', ...
                             WS_GRID(1), WS_GRID(end), numel(WS_GRID), WS_SAMPLE), ...
    'referenceDesc', ['Brandt-F16-A.xls Consts tab, replicated in ' ...
                      '`VnV/BrandtF16A/BrandtConstraintAnalysis.m`, run over the SAME W/S grid.'], ...
    'secondDesc',    ['none — both sides are fed Brandt''s OWN aero/prop, so there is no ' ...
                      'independent second source for this assembly check; the `2nd Source` ' ...
                      'column shows `N/A` throughout.'] );

meta.preamble = { ...
    ['**This is an ASSEMBLY check, not a drag/thrust check.** Both sides read Brandt''s own ' ...
     '`BrandtAerodynamics`/`BrandtEngine`, injected into the src constraint classes through ' ...
     '`BrandtAeroAdapter`/`BrandtPropAdapter`. Any residual %Diff comes from the src ' ...
     'constraint-assembly logic (the Master-Equation build and the ground-roll relations), ' ...
     'NOT from CD0, K1 or thrust lapse.'], ...
    ['**Two accounted-for modeling choices make the two sides algebraically identical.** ' ...
     '(1) `K2 = 0`: the adapter returns a symmetric parabolic polar, so the src Master ' ...
     'Equation''s `K2*n*beta/alpha` term drops out and the equation reduces to Brandt''s exact ' ...
     'Consts-tab form. (2) A shared fine W/S grid on both sides, so the two grid argmina are ' ...
     'directly comparable. With those two choices the agreement holds across the WHOLE sweep, ' ...
     'not only at the sampled points — the per-condition rows are sampled at a single ' ...
     'representative W/S only for a compact table. The one remaining difference is the dynamic ' ...
     'pressure q (src builds it in `AircraftState`, Brandt inline), and both use `atmosisa`, so ' ...
     'they agree to well under 1 %.'] };

meta.footer = { ...
    ['**Stall is skipped on both sides.** Brandt''s reproduction envelope has no Stall row, so ' ...
     'the src set drops it too (`buildSrcConstraints`); Landing is then the only W/S wall.'], ...
    ['**Informational only.** No pass/fail here; the deleted unit test ' ...
     '`tests/constraints/TestConstraintAnalysisVsBrandt.m` used a 2 % `RelTol`, but that gate is ' ...
     'now a report per CLAUDE.md''s two-tier rule. No number in this table may backfill a unit ' ...
     'test''s expected value.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, 'jsons', 'constraints_brandt_comparison.json');
out_md   = fullfile(script_dir, 'mds', 'constraints_brandt_comparison.md');
ComparisonReport.writeJson(T, out_json, meta);
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  JSON     -> %s\n', out_json);
fprintf('  Markdown -> %s\n\n', out_md);

% ════════════════════════════════════════════════════════════════════════ %
%  SIDE-BY-SIDE CONSTRAINT DIAGRAMS
%  Left  = framework (src), fed Brandt's disciplines through the adapters.
%  Right = Brandt ground truth, its own plot_constraint_diagram().
%  Neither plotting method is modified. Under a headless `matlab -batch` run
%  the figures are created but not shown -- that is fine; no drawnow / uiwait,
%  so the script still completes without a display.
% ════════════════════════════════════════════════════════════════════════ %
fig_src = src_ca.plot_diagram();
fig_src.Name = 'Framework (src) — Brandt-fed constraint diagram';
fig_src.Position = [80 200 720 560];    % left half of a nominal screen

brandtCA.plot_constraint_diagram();     % opens its own figure
fig_br = gcf;
fig_br.Name = 'Brandt ground truth — plot_constraint_diagram()';
fig_br.Position = [820 200 720 560];    % right half of a nominal screen

end

% ─── local helpers ───────────────────────────────────────────────────────── %

function constraints = buildSrcConstraints(aero, prop)
%BUILDSRCCONSTRAINTS  Build the SAME 8 constraints Brandt's envelope uses --
%   6 Master-Equation specializations + Takeoff + Landing, NO Stall (Brandt has
%   none) -- wired to the injected adapters. Reuses
%   ConstraintSetImporter.read_conditions and mirrors F16ConstraintSet's class
%   dispatch (Ps_fps>0 -> ExcessPower, else n>1 -> SustainedTurn, else
%   LevelFlight; Takeoff/Landing by name), skipping the Stall row.
%
%   Reused verbatim from the retired
%   tests/constraints/TestConstraintAnalysisVsBrandt.buildSrcConstraints.
    cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());

    constraints = {};
    for i = 1:numel(cond)
        c    = cond(i);
        name = string(c.name);
        switch name
            case "Takeoff"
                % Takeoff state at the liftoff Mach 0.2 (Brandt Consts!AT32) --
                % matches BrandtConstraintAnalysis.takeoff.
                state = AircraftState(c.altitude_ft, c.mach_liftoff);
                constraints{end+1} = TakeoffConstraint(name, state, aero, prop, ...
                    c.distance_ft, c.mu, c.beta, c.k_factor); %#ok<AGROW>
            case "Landing"
                % Landing state at M = 0.1 -- BrandtConstraintAnalysis.landing
                % reads the drag polar at run(0.1); the state's Mach only sets
                % rho (sea level, Mach-independent).
                state = AircraftState(0, 0.1);
                constraints{end+1} = LandingConstraint(name, state, aero, ...
                    c.distance_ft, c.mu, c.beta, c.k_factor); %#ok<AGROW>
            case "Stall"
                % SKIP: the Brandt reproduction set has no Stall row.
            otherwise
                state = AircraftState(c.altitude_ft, c.mach);
                powerSetting = string(c.power_setting);
                if c.Ps_fps > 0
                    constraints{end+1} = ExcessPowerConstraint(name, state, aero, prop, ...
                        c.beta, c.Ps_fps, powerSetting); %#ok<AGROW>
                elseif c.n > 1
                    constraints{end+1} = SustainedTurnConstraint(name, state, aero, prop, ...
                        c.beta, c.n, powerSetting); %#ok<AGROW>
                else
                    constraints{end+1} = LevelFlightConstraint(name, state, aero, prop, ...
                        c.beta, powerSetting); %#ok<AGROW>
                end
        end
    end
end

function tw = srcRequiredTW(src_ca, nm, WS)
%SRCREQUIREDTW  Required T/W of the src constraint named `nm` at wing loading
%   `WS`, looked up by .name among the producer constraints.
    src = src_ca.constraints;
    idx = find(cellfun(@(c) c.name == nm, src), 1);
    assert(~isempty(idx), 'src constraint "%s" not built.', nm);
    tw = src{idx}.required_TW(WS);
end

function T = arow(name, fidelity, computed, reference, numfmt, cite, notes)
%AROW  One comparison row. This report has NO second source (both sides read
%   Brandt's own aero/prop), so the `2nd Source` column is always N/A and the
%   `Divergence` column is blank -- every row is a genuine agreement check.
%   See ComparisonReport.row for the full column semantics.
    if nargin < 7; notes = ''; end
    T = ComparisonReport.row(name, fidelity, computed, reference, cite, numfmt, notes, NaN, '');
end

function T = srow(label)
%SROW  Section separator row.
    T = ComparisonReport.section(label);
end
