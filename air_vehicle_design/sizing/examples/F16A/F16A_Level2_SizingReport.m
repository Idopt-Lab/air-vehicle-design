%% F-16A Level 2 Sizing Report
% Runs the L2 (W_TO, T_SL) sizing study (|design_study_02_L2|) and reports:
%
% * Sizing convergence (W_TO, OEW, fuel weight per iteration)
% * A component-level weight breakdown (F16WeightsL2's Dependent
%   W_wings/W_tail/W_fuselage/W_landing_gear/W_installed_engine/
%   W_all_else_empty properties -- Raymer Table 15.2 unit-weight buildup)
% * Real aerodynamic-coefficient breakdown at each mission segment (L2's
%   mission fuel closure calls the injected aero's drag_polar per segment --
%   MissionAnalysisL2)
% * A note on why no internal fuel-volume check is available at this
%   fidelity level (only F16WeightsL3 carries V_t/V_i/V_p)
%
% NOTE ON FILE FORMAT: this file is authored as a plain .m script with
% Live-Editor-compatible "%%" section breaks. Open it in MATLAB and use
% View > Open in Live Editor, or File > Save As > Live Script (.mlx), for
% the rendered inline-figure/rich-text presentation.
%
% Every object/method called below already exists in src/ or examples/F16A/
% -- this script only wires them together and reports; no discipline
% equations are implemented here.

% clear; clc; close all;

%% Run the L2 design study
% design_study_02_L2 builds fresh F16AeroL2/F16PropL2/F16WeightsL2/
% F16GeomL2 objects plus the L2 mission analysis (MissionAnalysisL2), plus
% the separate, dependency-injected
% F16TailL1/ControlSurfaceSizer tail- and control-surface-sizing objects
% (2026-08-03 absorption into Geometry REVERTED, 2026-08-05 -- tail sizing
% is not a method on F16GeomL2 any more), wires them all into SizingLoopL2,
% and runs it to convergence. The second
% output (objs) exposes those same objects, already mutated to their
% converged state, for the reporting below.

W_TO_guess = 30000;
T_SL_guess = 20000;
[result, objs] = design_study_02_L2(W_TO_guess, T_SL_guess);

% [WS_opt, TW_opt] = the constraint-diagram-optimal wing and thrust loading.
% SizingLoopL2.run() re-reads them EVERY iteration (they move as the loop's
% own S_ref/T_SL state changes the wetted area -- see that class's header)
% and re-derives BOTH design variables from the CURRENT W_TO:
%   S_ref = W_TO/WS_opt   and   T_SL = TW_opt*W_TO
% S_ref is solved for at L2/L3 as of 2026-08-10, exactly as at L1; the JSON
% .wing.S_ft2 value is only the starting point. Calling objs.con's own
% optimal_point() again here (ConstraintAnalysis is a pure value class, and
% con is never mutated during the run) reproduces the same pair the loop's
% final re-derivation used, since objs are returned in their converged state.
[WS_opt, TW_opt] = objs.con.optimal_point();

fprintf('\n=== F-16A Level 2 Sizing Result ===\n');
fprintf('  Converged:  %d\n', result.converged);
fprintf('  Iterations: %d\n', result.n_iter);
fprintf('  W_TO:       %.1f lbf  (Brandt = 31377 lbf, %+.1f%%)\n', ...
    result.W_TO, 100*(result.W_TO - 31377)/31377);
fprintf('  S_ref:      %.2f ft^2 (SOLVED as W_TO/(W/S)_opt; Brandt = 300 ft^2, %+.1f%%)\n', ...
    result.S_ref, 100*(result.S_ref - 300)/300);
fprintf('  T_SL:       %.1f lbf  (Brandt = 23770 lbf, %+.1f%%)\n', ...
    result.T_SL, 100*(result.T_SL - 23770)/23770);
fprintf('  Optimum loading: (W/S)_opt = %.4f lbf/ft^2, (T/W)_opt = %.4f  (from ConstraintAnalysis.optimal_point, re-read every iteration)\n', ...
    WS_opt, TW_opt);
fprintf('  S_ref:      initial = %.2f ft^2  ->  final = %.2f ft^2\n', ...
    result.history(1).S_ref, result.S_ref);
fprintf('  T_SL:       initial = %.1f lbf (T_SL_guess)  ->  final = %.1f lbf\n', ...
    result.history(1).T_SL, result.T_SL);

last = result.history(end);
fprintf('  S_ht=%.3f ft^2  S_vt=%.3f ft^2  S_ail=%.3f ft^2  S_elev=%.3f ft^2  S_rud=%.3f ft^2\n', ...
    last.S_ht, last.S_vt, last.S_ail, last.S_elev, last.S_rud);

%% Sizing convergence plots (W_TO, OEW, fuel weight, T_SL, S_ref per iteration)
% Straight from SizingLoopL2.run's own returned history. T_SL and S_ref both
% track W_TO every iteration (T_SL = TW_opt*W_TO, S_ref = W_TO/WS_opt --
% SizingLoopL2.run's own formulas). S_ref gets the right-hand axis, matching
% F16A_Level1_SizingReport.m, since it is in ft^2 rather than lbf. Before
% 2026-08-10 S_ref was loop-invariant and had no history field to plot.

iters     = [result.history.iter];
WTO_hist  = [result.history.W_TO];
OEW_hist  = [result.history.W_OEW];
Fuel_hist = [result.history.W_fuel];
TSL_hist  = [result.history.T_SL];
Sref_hist = [result.history.S_ref];

figure('Name', 'L2 Sizing Convergence');
yyaxis left
plot(iters, WTO_hist, '-o', 'LineWidth', 1.5); hold on;
plot(iters, OEW_hist, '-s', 'LineWidth', 1.5);
plot(iters, Fuel_hist, '-^', 'LineWidth', 1.5);
plot(iters, TSL_hist, '-d', 'LineWidth', 1.5);
ylabel('Weight / Thrust [lbf]');

yyaxis right
plot(iters, Sref_hist, '-v', 'LineWidth', 1.5);
ylabel('S_{ref} [ft^2]');

grid on;
xlabel('Iteration');
legend('W_{TO}', 'OEW', 'W_{fuel}', 'T_{SL}', 'S_{ref}', 'Location', 'best');
title(sprintf('F-16A Level 2 Sizing Convergence ((W/S)_{opt} = %.2f lbf/ft^2, (T/W)_{opt} = %.4f)', WS_opt, TW_opt));

%% Component-level weight breakdown
% Calls F16WeightsL2's own group-weight methods at the converged W_TO --
% these are the exact terms WeightsL2.OEW sums (see that toolbox's OEW
% method); nothing here is a new equation, just re-reading what OEW already
% computed, broken out by component.

W_TO_final = result.W_TO;
W_wing  = objs.wts.weight_wing(W_TO_final);
W_tail  = objs.wts.weight_tail(W_TO_final);       % struct(HT, VT)
W_fus   = objs.wts.weight_fuselage(W_TO_final);
W_lg    = objs.wts.weight_landing_gear(W_TO_final);
W_eng   = objs.wts.W_installed_engine;             % Dependent, reads live obj.W_TO/prop.T_SL
W_else  = objs.wts.W_all_else_empty;                % Dependent, 0.17*W_TO

componentLabelList = {'Wing', 'Horizontal Tail', 'Vertical Tail', 'Fuselage', ...
    'Landing Gear', 'Installed Engine', 'All-Else-Empty', 'Mission Fuel', ...
    'Fixed Payload', 'Expendable Payload'};
componentLabels = categorical(componentLabelList, componentLabelList, 'Ordinal', true);
componentValues = [W_wing, W_tail.HT, W_tail.VT, W_fus, W_lg, W_eng, W_else, ...
    result.history(end).W_fuel, objs.wts.W_payload_fixed, objs.wts.W_payload_expendable];

weightBreakdownTable = table(componentLabels(:), componentValues(:), ...
    'VariableNames', {'Component', 'Weight_lbf'});
disp('Level 2 component-level weight breakdown:');
disp(weightBreakdownTable);

figure('Name', 'L2 Component Weight Breakdown', 'Position', [100 100 1000 500]);
bar(componentLabels, componentValues);
grid on; ylabel('Weight [lbf]'); xtickangle(30);
title('F-16A Level 2 Component-Level Weight Breakdown');

fprintf('\n  Check: sum(components) - OEW(W_TO_final) = %.4f lbf (should be ~0)\n', ...
    (W_wing + W_tail.HT + W_tail.VT + W_fus + W_lg + W_eng + W_else) - objs.wts.OEW(W_TO_final));

%% Mission fuel + key drivers by segment
% MissionAnalysisL2's master-equation legs call the injected aero/prop, so the
% per-segment fuel, and the L/D and TSFC that drove each leg, come straight
% from the mission breakdown (total_fuel) -- no re-evaluation needed. Fixed-
% fraction ground/landing legs have no L/D and show blank.

[~, breakdown] = objs.miss.total_fuel(W_TO_final);

seg_names = breakdown.names;
n = numel(seg_names);
LD = nan(1, n); TSFC = nan(1, n);
for i = 1:n
    d = breakdown.debug{i};
    if isfield(d, 'LD'),          LD(i)   = d.LD; end
    if isfield(d, 'TSFC_per_hr'), TSFC(i) = d.TSFC_per_hr; end
end

segTable = table(seg_names(:), breakdown.fuel_lbf(:), breakdown.W_after(:), LD(:), TSFC(:), ...
    'VariableNames', {'Segment', 'FuelUsed_lbf', 'W_after_lbf', 'L_D', 'TSFC_per_hr'});
disp('Level 2 mission fuel + drivers by segment:');
disp(segTable);

figure('Name', 'L2 Mission Fuel by Segment');
tiledlayout(2, 1);
nexttile;
bar(categorical(seg_names(:), seg_names(:), 'Ordinal', true), breakdown.fuel_lbf(:));
grid on; ylabel('Fuel Used [lbf]'); title('F-16A Level 2 Mission Fuel by Segment');
nexttile;
bar(categorical(seg_names(:), seg_names(:), 'Ordinal', true), LD(:));
grid on; ylabel('L/D'); title('F-16A Level 2 L/D by Mission Segment');

%% Internal fuel-volume check
% NOT MODELED AT L2: F16WeightsL2 carries no fuel-tank-volume inputs (no
% V_t/V_i/V_p) -- those only exist on F16WeightsL3 (see
% F16A_Level3_SizingReport.m's "Internal fuel-volume check" section). L2's
% weight model uses a flat 1.3x installed-engine factor and no fuel-system
% volume equation (Raymer Eq. 15.9, V_t-dependent, is L3-only).
fprintf('\nInternal fuel-volume check: not modeled at L2 (no V_t/V_i/V_p on F16WeightsL2; see F16WeightsL3 at L3).\n');

%% Final summary
fprintf('\n=== F-16A Level 2 Final Summary ===\n');
fprintf('  W_TO = %.1f lbf, OEW = %.1f lbf, W_fuel = %.1f lbf, S_ref = %.2f ft^2, T_SL = %.1f lbf\n', ...
    result.W_TO, objs.wts.OEW(W_TO_final), result.history(end).W_fuel, result.S_ref, result.T_SL);
