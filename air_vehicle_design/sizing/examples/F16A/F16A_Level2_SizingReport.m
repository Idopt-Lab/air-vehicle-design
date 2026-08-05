%% F-16A Level 2 Sizing Report
% Runs the L2 (W_TO, T_SL) sizing study (|design_study_02_L2|) and reports:
%
% * Sizing convergence (W_TO, OEW, fuel weight per iteration)
% * A component-level weight breakdown (F16WeightsL2's Dependent
%   W_wings/W_tail/W_fuselage/W_landing_gear/W_installed_engine/
%   W_all_else_empty properties -- Raymer Table 15.2 unit-weight buildup)
% * Real aerodynamic-coefficient breakdown at each mission segment (L2's
%   mission fuel closure genuinely calls F16AeroL2.drag_polar per segment,
%   unlike L1 -- see F16MissionL2's header)
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
% F16GeomL2/F16MissionL2 objects (tail/control-surface sizing are now
% methods on F16GeomL2 itself -- see that class's TAIL SIZING/CONTROL
% SURFACE SIZING sections, 2026-08-03), wires them into SizingLoopL2, and
% runs it to convergence. The second
% output (objs) exposes those same objects, already mutated to their
% converged state, for the reporting below.

W_TO_guess = 30000;
T_SL_guess = 20000;
[result, objs] = design_study_02_L2(W_TO_guess, T_SL_guess);

% TW_opt = the constraint-diagram-optimal thrust loading SizingLoopL2.run()
% computes ONCE (before iterating) and holds fixed for the whole loop --
% see that class's header. Every iteration re-derives T_SL = TW_opt*W_TO
% from the CURRENT W_TO (SizingLoopL2.run's own formula); S_ref is a fixed
% JSON input here and is never touched by the loop (unlike L1, where it's
% solved for). Calling objs.con's own optimal_point() again here
% (ConstraintAnalysis is a pure value class, and con is never mutated
% during the run) reproduces the identical TW_opt the loop actually used --
% its W/S output is unused at L2/L3, per that class's header.
[~, TW_opt] = objs.con.optimal_point();

fprintf('\n=== F-16A Level 2 Sizing Result ===\n');
fprintf('  Converged:  %d\n', result.converged);
fprintf('  Iterations: %d\n', result.n_iter);
fprintf('  W_TO:       %.1f lbf  (Brandt = 31377 lbf, %+.1f%%)\n', ...
    result.W_TO, 100*(result.W_TO - 31377)/31377);
fprintf('  S_ref:      %.2f ft^2 (fixed JSON input at L2 -- held CONSTANT for the whole run, never solved for)\n', result.S_ref);
fprintf('  T_SL:       %.1f lbf  (Brandt = 23770 lbf, %+.1f%%)\n', ...
    result.T_SL, 100*(result.T_SL - 23770)/23770);
fprintf('  Optimum thrust loading (T/W)_opt = %.4f  (from ConstraintAnalysis.optimal_point, fixed for the whole run)\n', TW_opt);
fprintf('  T_SL:       initial = %.1f lbf (T_SL_guess)  ->  final = %.1f lbf\n', ...
    result.history(1).T_SL, result.T_SL);

last = result.history(end);
fprintf('  S_ht=%.3f ft^2  S_vt=%.3f ft^2  S_ail=%.3f ft^2  S_elev=%.3f ft^2  S_rud=%.3f ft^2\n', ...
    last.S_ht, last.S_vt, last.S_ail, last.S_elev, last.S_rud);

%% Sizing convergence plots (W_TO, OEW, fuel weight, T_SL per iteration)
% Straight from SizingLoopL2.run's own returned history. T_SL tracks W_TO
% every iteration (T_SL = TW_opt*W_TO, SizingLoopL2.run's own formula)
% since TW_opt is fixed for the whole loop -- see that class's header.
% S_ref does NOT get its own convergence plot: it is a fixed JSON input at
% L2 (unlike L1), never touched by SizingLoopL2 -- SizingLoopL2's own
% history struct has no S_ref field to plot, by design.

iters     = [result.history.iter];
WTO_hist  = [result.history.W_TO];
OEW_hist  = [result.history.W_OEW];
Fuel_hist = [result.history.W_fuel];
TSL_hist  = [result.history.T_SL];

% All 4 quantities on one graph -- W_TO, OEW, W_fuel, and T_SL are all in
% lbf, so no secondary axis is needed (unlike L1's S_ref, which is ft^2).

figure('Name', 'L2 Sizing Convergence');
plot(iters, WTO_hist, '-o', 'LineWidth', 1.5); hold on;
plot(iters, OEW_hist, '-s', 'LineWidth', 1.5);
plot(iters, Fuel_hist, '-^', 'LineWidth', 1.5);
plot(iters, TSL_hist, '-d', 'LineWidth', 1.5);
grid on;
xlabel('Iteration'); ylabel('Weight [lbf]');
legend('W_{TO}', 'OEW', 'W_{fuel}', 'T_{SL}', 'Location', 'best');
title(sprintf('F-16A Level 2 Sizing Convergence (T_{SL} = W_{TO} \\times (T/W)_{opt}, (T/W)_{opt} = %.4f; S_{ref} = %.2f ft^2 fixed)', TW_opt, result.S_ref));

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

%% Real aerodynamic-coefficient breakdown at each mission segment
% Unlike L1, F16MissionL2's mission-fuel closure genuinely calls
% F16AeroL2.drag_polar/F16PropL2 per segment (Cruise/Dash/Combat/Loiter;
% Climb is energy-height sub-integrated). This section calls
% MissionL2.get_mission_fuel directly (the same static F16MissionL2.
% compute_fuel delegates to) to recover its second output (breakdown,
% including the per-segment starting weight W_after_lbf), which
% F16MissionL2.compute_fuel itself discards -- then re-evaluates
% F16AeroL2.drag_polar/compute_CL/compute_CD at each segment's tabulated
% condition and the weight AT THE START of that segment (same
% single-point-approximation convention MissionL2 itself uses -- see its
% class header). Ground-roll/fixed-fraction segments (startup/taxi/
% takeoff/landing) are not evaluated -- there is no steady-level-flight
% condition to define CL/CD for them.

[~, breakdown] = MissionL2.get_mission_fuel(objs.miss.missiondata, W_TO_final, objs.aero, objs.prop);

missiondata = objs.miss.missiondata;
names   = missiondata.segment_names;
alt_ft  = missiondata.alt_ft;
mach    = missiondata.mach_end;
n       = numel(names);

W_start = zeros(1, n);
W_start(1) = W_TO_final;
if n > 1
    W_start(2:end) = breakdown.W_after_lbf(1:end-1);
end

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
    CL(i)  = objs.aero.compute_CL(W_start(i), state.q, objs.geom.S_ref);
    CD(i)  = objs.aero.compute_CD(polar.CD0, polar.K1, polar.K2, CL(i));
    LD(i)  = CL(i) / CD(i);
end

aeroTable = table(names(:), alt_ft(:), mach(:), W_start(:), CD0(:), K1(:), K2(:), CL(:), CD(:), LD(:), ...
    'VariableNames', {'Segment', 'Altitude_ft', 'Mach', 'W_start_lbf', 'CD0', 'K1', 'K2', 'CL', 'CD', 'L_D'});
disp('Level 2 aerodynamic-coefficient breakdown by mission segment:');
disp(aeroTable);

figure('Name', 'L2 Aerodynamic Coefficient Breakdown');
tiledlayout(3, 1);
nexttile;
bar(categorical(names, names, 'Ordinal', true), CD0);
grid on; ylabel('CD_0'); title('F-16A Level 2 CD_0 by Mission Segment');
nexttile;
bar(categorical(names, names, 'Ordinal', true), CL);
grid on; ylabel('C_L'); title('F-16A Level 2 C_L by Mission Segment');
nexttile;
bar(categorical(names, names, 'Ordinal', true), LD);
grid on; ylabel('L/D'); title('F-16A Level 2 L/D by Mission Segment');

figure('Name', 'L2 Mission Fuel by Segment');
bar(categorical(names, names, 'Ordinal', true), breakdown.fuel_used_lbf);
grid on; ylabel('Fuel Used [lbf]');
title('F-16A Level 2 Mission Fuel by Segment');

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
