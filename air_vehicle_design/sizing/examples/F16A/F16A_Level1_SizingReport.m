%% F-16A Level 1 Sizing Report
% Runs the L1 W_TO sizing study (|design_study_01_L1|) and reports:
%
% * Sizing convergence (W_TO, OEW, fuel weight per iteration)
% * A high-level weight breakdown (L1 has no per-component weight model --
%   see F16WeightsL1.m's header: it is a single Raymer Table 3.1 We/Wto
%   regression, with zero Dependent/derived properties by design)
% * Mission fuel burned by segment
% * A supplemental aerodynamic-coefficient sweep at each mission segment's
%   tabulated Mach/altitude (diagnostic only -- F16MissionL1 does NOT call
%   the aero object internally, per its own header, so this is NOT the
%   same drag polar the sizing loop's mission-fuel closure actually used)
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
% F16GeomL1/F16MissionL1 objects, wires them into SizingLoopL1, and runs it
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
% Calls MissionL1.get_mission_fuel directly (the same static
% F16MissionL1.compute_fuel delegates to) to get its second output
% (breakdown), which F16MissionL1.compute_fuel discards.

[~, breakdown] = MissionL1.get_mission_fuel(objs.miss.missiondata, result.W_TO, objs.aero, objs.prop);

segmentTable = table(breakdown.segment_names(:), breakdown.fuel_used_lbf(:), breakdown.W_after_lbf(:), ...
    'VariableNames', {'Segment', 'FuelUsed_lbf', 'W_after_lbf'});
disp('Level 1 mission fuel-by-segment breakdown:');
disp(segmentTable);

figure('Name', 'L1 Mission Fuel by Segment');
bar(categorical(segmentTable.Segment, segmentTable.Segment, 'Ordinal', true), segmentTable.FuelUsed_lbf);
grid on; ylabel('Fuel Used [lbf]');
title('F-16A Level 1 Mission Fuel by Segment');

%% Supplemental aerodynamic-coefficient sweep at each mission segment
% DIAGNOSTIC ONLY: F16MissionL1.compute_fuel (per its own header) never
% calls the aero object -- L1 mission fuel is a Table 2.1/2.2 fixed-
% fraction/tabulated-Breguet estimate, independent of geometry or the real
% drag polar. This section separately evaluates F16AeroL1's OWN drag_polar
% (Mattingly Fig. 2.10/2.11 type curves, a function of Mach only) at each
% segment's tabulated end condition, plus CL/CD/L-D at that condition using
% the CONVERGED W_TO as a constant single-point weight approximation (L1
% has no per-segment weight history to draw on). Ground-roll/fixed-fraction
% segments (startup/taxi/takeoff/landing) are not evaluated -- there is no
% steady-level-flight condition to define CL/CD for them, matching how
% MissionL1/L2/L3's own dispatch loops treat those segments.

missiondata = objs.miss.missiondata;
names   = missiondata.segment_names;
alt_ft  = missiondata.alt_ft;
mach    = missiondata.mach_end;
n       = numel(names);

aero_segments = ["climb", "cruise", "dash", "combat", "loiter"];

CD0 = nan(1, n); K1 = nan(1, n); K2 = nan(1, n);
CL  = nan(1, n); CD = nan(1, n); LD = nan(1, n);

for i = 1:n
    seg = MissionL1.normalize_segment_name(names(i));
    if ~ismember(seg, aero_segments)
        continue
    end
    state = AircraftState(alt_ft(i), mach(i));
    polar = objs.aero.drag_polar(state);
    CD0(i) = polar.CD0;
    K1(i)  = polar.K1;
    K2(i)  = polar.K2;
    CL(i)  = objs.aero.compute_CL(result.W_TO, state.q, objs.geom.S_ref);
    CD(i)  = objs.aero.compute_CD(polar.CD0, polar.K1, polar.K2, CL(i));
    LD(i)  = CL(i) / CD(i);
end

aeroTable = table(names(:), alt_ft(:), mach(:), CD0(:), K1(:), K2(:), CL(:), CD(:), LD(:), ...
    'VariableNames', {'Segment', 'Altitude_ft', 'Mach', 'CD0', 'K1', 'K2', 'CL', 'CD', 'L_D'});
disp('Level 1 supplemental aerodynamic-coefficient sweep (diagnostic; NOT used by the L1 mission closure):');
disp(aeroTable);

figure('Name', 'L1 Aerodynamic Coefficient Breakdown');
tiledlayout(2, 1);
nexttile;
bar(categorical(names, names, 'Ordinal', true), CD0);
grid on; ylabel('CD_0'); title('F-16A Level 1 CD_0 by Mission Segment (F16AeroL1.drag\_polar)');
nexttile;
bar(categorical(names, names, 'Ordinal', true), LD);
grid on; ylabel('L/D'); title('F-16A Level 1 L/D by Mission Segment (at converged W_{TO})');

%% Internal fuel-volume check
% NOT MODELED AT L1: F16WeightsL1 carries no fuel-tank-volume inputs (no
% V_t/V_i/V_p) -- those only exist on F16WeightsL3 (see
% F16A_Level3_SizingReport.m). L1's weight model is a single empty-weight
% regression with no internal-geometry/volume representation at all.
fprintf('\nInternal fuel-volume check: not modeled at L1 (no V_t/V_i/V_p on F16WeightsL1; see F16WeightsL3 at L3).\n');

%% Final summary
fprintf('\n=== F-16A Level 1 Final Summary ===\n');
fprintf('  W_TO = %.1f lbf, OEW = %.1f lbf, W_fuel = %.1f lbf, S_ref = %.2f ft^2, T_SL = %.1f lbf\n', ...
    result.W_TO, OEW_final, Fuel_final, result.S_ref, result.T_SL);
