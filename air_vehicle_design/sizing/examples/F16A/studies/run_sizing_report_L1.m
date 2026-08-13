%% F-16A Level 1 Sizing Report
% Runs the L1 W_TO sizing study (|design_study_01_L1|) and reports:
%
% * Sizing convergence (W_TO, OEW, fuel weight per iteration)
% * A high-level weight breakdown (L1 has no per-component weight model --
%   see F16WeightsL1.m's header: it is a single Raymer Table 3.1 We/Wto
%   regression, with zero Dependent/derived properties by design)
% * Mission fuel burned by segment
% * A supplemental aerodynamic-coefficient sweep at each mission segment's
%   Mach/altitude (diagnostic -- MissionAnalysisL1 uses the injected aero drag
%   polar on its Breguet cruise/dash/loiter/combat legs; the fixed-fraction
%   startup/taxi/takeoff/climb/landing legs use Roskam fractions instead)
% * A note on why no internal fuel-volume check is available at this
%   fidelity level
%
% NOTE ON FILE FORMAT: this file is authored as a plain .m script with
% Live-Editor-compatible "%%" section breaks (same convention MATLAB uses
% to convert a script for the Live Editor). Open it in MATLAB and use
% View > Open in Live Editor, or File > Save As > Live Script (.mlx), if
% you want the rendered inline-figure/rich-text presentation.
%
% Every object/method called below already exists in src/ or examples/F16A/
% -- this script only wires them together and reports; no discipline
% equations are implemented here.

% clear; clc; close all;

%% Run the L1 design study
% design_study_01_L1 builds fresh F16AeroL1/F16PropL1/F16WeightsL1/
% F16GeomL1 objects plus the L1 mission analysis (MissionAnalysisL1), wires
% them into SizingLoopL1, and runs it
% to convergence. The second output (objs) exposes those same objects,
% already mutated to their converged state, for the reporting below.

W_TO_guess = 30000;
[result, objs] = design_study_01_L1(W_TO_guess);

% [WS_opt, TW_opt] = the constraint-diagram-optimal wing-loading/thrust-
% ratio SizingLoopL1.run() computes ONCE (before iterating) and holds fixed
% for the whole loop -- see that class's header. Calling objs.con's own
% optimal_point() again here (ConstraintAnalysis is a pure value class, and
% con is never mutated during the run) reproduces the identical WS_opt the
% loop actually used, without re-deriving anything.
[WS_opt, TW_opt] = objs.con.optimal_point();

fprintf('\n=== F-16A Level 1 Sizing Result ===\n');
fprintf('  Converged:  %d\n', result.converged);
fprintf('  Iterations: %d\n', result.n_iter);
fprintf('  W_TO:       %.1f lbf  (Brandt = 31377 lbf, %+.1f%%)\n', ...
    result.W_TO, 100*(result.W_TO - 31377)/31377);
fprintf('  S_ref:      %.2f ft^2 (Brandt = 300 ft^2, %+.1f%%; L1 solves for S_ref, not an input)\n', ...
    result.S_ref, 100*(result.S_ref - 300)/300);
fprintf('  T_SL:       %.1f lbf\n', result.T_SL);
fprintf('  Optimum wing loading (W/S)_opt = %.3f lbf/ft^2  (Brandt = 104.59 lbf/ft^2; from ConstraintAnalysis.optimal_point, fixed for the whole run)\n', WS_opt);
fprintf('  Optimum thrust loading (T/W)_opt = %.4f\n', TW_opt);
fprintf('  S_ref:      initial = %.2f ft^2 (from W_TO_guess/WS_opt)  ->  final = %.2f ft^2\n', ...
    result.history(1).S_ref, result.S_ref);

%% Sizing convergence plots (W_TO, OEW, fuel weight, S_ref per iteration)
% Straight from SizingLoopL1.run's own returned history -- no
% recomputation, just plotting the struct array it already produced. S_ref
% tracks W_TO every iteration (S_ref = W_TO/WS_opt, SizingLoopL1.run's own
% formula) since WS_opt is fixed for the whole loop -- see that class's
% header.

iters     = [result.history.iter];
WTO_hist  = [result.history.W_TO];
OEW_hist  = [result.history.W_OEW];
Fuel_hist = [result.history.W_fuel];
Sref_hist = [result.history.S_ref];

% All 4 quantities on one graph. W_TO/OEW/W_fuel share units (lbf) and go
% on the left axis; S_ref (ft^2, a very different magnitude) goes on a
% right y-axis (yyaxis) so it stays readable on the same plot.

figure('Name', 'L1 Sizing Convergence');
yyaxis left
plot(iters, WTO_hist, '-o', 'LineWidth', 1.5); hold on;
plot(iters, OEW_hist, '-s', 'LineWidth', 1.5);
plot(iters, Fuel_hist, '-^', 'LineWidth', 1.5);
ylabel('Weight [lbf]');

yyaxis right
plot(iters, Sref_hist, '-d', 'LineWidth', 1.5);
ylabel('S_{ref} [ft^2]');

grid on;
xlabel('Iteration');
legend('W_{TO}', 'OEW', 'W_{fuel}', 'S_{ref}', 'Location', 'best');
title(sprintf('F-16A Level 1 Sizing Convergence (S_{ref} = W_{TO}/(W/S)_{opt}, (W/S)_{opt} = %.2f lbf/ft^2)', WS_opt));

%% High-level weight breakdown
% L1 has no component (wing/tail/fuselage/...) weight model -- OEW is a
% single Table 3.1 empty-weight-fraction regression on W_TO
% (F16WeightsL1.OEW). The breakdown below is therefore at the same
% granularity as the legacy L1 example script: OEW vs. mission fuel vs.
% fixed/expendable payload (objs.wts's own WeightsBase-contract properties).

OEW_final  = result.history(end).W_OEW;
Fuel_final = result.history(end).W_fuel;

weightLabelList = {'OEW', 'Mission Fuel', 'Fixed Payload', 'Expendable Payload'};
weightLabels = categorical(weightLabelList, weightLabelList, 'Ordinal', true);
weightValues = [OEW_final, Fuel_final, objs.wts.W_payload_fixed, objs.wts.W_payload_expendable];

figure('Name', 'L1 Weight Breakdown');
bar(weightLabels, weightValues);
grid on; ylabel('Weight [lbf]');
title('F-16A Level 1 Weight Breakdown (OEW is a single Table 3.1 regression, not a component buildup)');

%% Mission fuel burned by segment
% MissionAnalysisL1.total_fuel returns the per-segment breakdown (names,
% fuel_lbf, W_after) directly -- and, unlike the legacy L1 mission, its
% Breguet legs actually call the injected aero/prop, so each leg's debug
% struct also carries the L/D and TSFC that drove its fuel.

[~, breakdown] = objs.miss.total_fuel(result.W_TO);

segmentTable = table(breakdown.names(:), breakdown.fuel_lbf(:), breakdown.W_after(:), ...
    'VariableNames', {'Segment', 'FuelUsed_lbf', 'W_after_lbf'});
disp('Level 1 mission fuel-by-segment breakdown:');
disp(segmentTable);

figure('Name', 'L1 Mission Fuel by Segment');
bar(categorical(segmentTable.Segment, segmentTable.Segment, 'Ordinal', true), segmentTable.FuelUsed_lbf);
grid on; ylabel('Fuel Used [lbf]');
title('F-16A Level 1 Mission Fuel by Segment');

%% Key aerodynamic drivers by mission segment (from the mission breakdown)
% Unlike the legacy L1 mission, MissionAnalysisL1's Breguet legs DO call the
% injected aero/prop, so the L/D and TSFC that actually drove each leg's fuel
% are read straight from the mission breakdown's per-segment debug struct.
% Fixed-fraction ground/climb/landing legs have no L/D and show blank.

seg_names = breakdown.names;
n = numel(seg_names);
LD = nan(1, n); TSFC = nan(1, n);
for i = 1:n
    d = breakdown.debug{i};
    if isfield(d, 'LD'),          LD(i)   = d.LD; end
    if isfield(d, 'TSFC_per_hr'), TSFC(i) = d.TSFC_per_hr; end
end

aeroTable = table(seg_names(:), LD(:), TSFC(:), ...
    'VariableNames', {'Segment', 'L_D', 'TSFC_per_hr'});
disp('Level 1 key mission-fuel drivers (L/D, TSFC) by segment:');
disp(aeroTable);

figure('Name', 'L1 L/D by Mission Segment');
bar(categorical(seg_names(:), seg_names(:), 'Ordinal', true), LD(:));
grid on; ylabel('L/D'); title('F-16A Level 1 L/D by Mission Segment (from the mission fuel closure)');

%% Internal fuel-volume check
% NOT MODELED AT L1: F16WeightsL1 carries no fuel-tank-volume inputs (no
% V_t/V_i/V_p) -- those only exist on F16WeightsL3 (see
% run_sizing_report_L3.m). L1's weight model is a single empty-weight
% regression with no internal-geometry/volume representation at all.
fprintf('\nInternal fuel-volume check: not modeled at L1 (no V_t/V_i/V_p on F16WeightsL1; see F16WeightsL3 at L3).\n');

%% Final summary
fprintf('\n=== F-16A Level 1 Final Summary ===\n');
fprintf('  W_TO = %.1f lbf, OEW = %.1f lbf, W_fuel = %.1f lbf, S_ref = %.2f ft^2, T_SL = %.1f lbf\n', ...
    result.W_TO, OEW_final, Fuel_final, result.S_ref, result.T_SL);
