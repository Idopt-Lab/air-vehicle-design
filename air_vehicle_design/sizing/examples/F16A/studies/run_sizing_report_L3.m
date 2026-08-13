%% F-16A Level 3 Sizing Report
% Runs the L3 (W_TO, T_SL) sizing study (|design_study_03_L3|, which reuses
% SizingLoopL2 wired to F16AeroL3/F16GeomL3/F16WeightsL3 plus the L2 mission
% analysis MissionAnalysisL2 (no L3 mission tier) -- see that driver's header
% for why no separate SizingLoopL3 exists) and
% reports:
%
% * Sizing convergence (W_TO, OEW, fuel weight per iteration)
% * A detailed component/subsystem weight breakdown (F16WeightsL3's Raymer
%   Sec. 15.3.1 buildup: weight_wing/weight_tail/weight_fuselage/
%   weight_landing_gear/weight_engine_section/weight_systems)
% * Real aerodynamic-coefficient breakdown at each mission segment
%   (F16AeroL3.drag_polar component buildup + supersonic wave drag)
% * An internal fuel-volume check (F16WeightsL3's V_t/V_i/V_p inputs vs.
%   the converged mission fuel weight)
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

%% Run the L3 design study
% design_study_03_L3 builds fresh F16AeroL3/F16GeomL3/F16WeightsL3 objects
% plus the L2 mission analysis MissionAnalysisL2 (no L3 mission tier; F16PropL2
% stands in for propulsion -- no L3 propulsion tier, see that driver's header),
% wires them into
% SizingLoopL2, and runs it to convergence. The second output (objs)
% exposes those same objects, already mutated to their converged state.

W_TO_guess = 45000;
T_SL_guess = 20000;
[result, objs] = design_study_03_L3(W_TO_guess, T_SL_guess);

% [WS_opt, TW_opt] = the constraint-diagram-optimal wing and thrust loading.
% SizingLoopL2.run() re-reads them EVERY iteration and re-derives BOTH design
% variables from the CURRENT W_TO -- S_ref = W_TO/WS_opt and T_SL = TW_opt*W_TO
% (see that class's header; design_study_03_L3 reuses SizingLoopL2
% unmodified). S_ref is solved for at L2/L3 as of 2026-08-10, exactly as at
% L1; the JSON .wing.S_ft2 value is only the starting point. Calling objs.con's
% own optimal_point() again here (ConstraintAnalysis is a pure value class, and
% con is never mutated during the run) reproduces the same pair the loop's
% final re-derivation used, since objs are returned in their converged state.
[WS_opt, TW_opt] = objs.con.optimal_point();

fprintf('\n=== F-16A Level 3 Sizing Result ===\n');
fprintf('  Converged:  %d\n', result.converged);
fprintf('  Iterations: %d\n', result.n_iter);
fprintf('  W_TO:       %.1f lbf  (Brandt = 31377 lbf, %+.1f%%)\n', ...
    result.W_TO, 100*(result.W_TO - 31377)/31377);
fprintf('  S_ref:      %.2f ft^2 (SOLVED as W_TO/(W/S)_opt; Brandt = 300 ft^2, %+.1f%%)\n', ...
    result.S_ref, 100*(result.S_ref - 300)/300);
fprintf('  T_SL:       %.1f lbf  (Brandt = 23770 lbf, %+.1f%%; COMPUTED BY F16PropL2, no L3 propulsion tier exists)\n', ...
    result.T_SL, 100*(result.T_SL - 23770)/23770);
fprintf('  Optimum loading: (W/S)_opt = %.4f lbf/ft^2, (T/W)_opt = %.4f  (from ConstraintAnalysis.optimal_point, re-read every iteration)\n', ...
    WS_opt, TW_opt);
fprintf('  T_SL:       initial = %.1f lbf (T_SL_guess)  ->  final = %.1f lbf\n', ...
    result.history(1).T_SL, result.T_SL);
fprintf('  S_ref:      initial = %.2f ft^2  ->  final = %.2f ft^2\n', ...
    result.history(1).S_ref, result.S_ref);

last = result.history(end);
% Tail plus all SIX control-surface areas, every one re-sized each iteration
% from the CURRENT wing and tail. The F-16's four REAL surfaces are the
% flaperon, the leading-edge flap, the all-moving stabilator and the rudder.
% S_ail and S_elev print 0 because this airframe has neither a separate
% aileron (the flaperon serves that role) nor a separate elevator (all-moving
% stabilator) -- see f16a_control_surfaces.m.
fprintf('  S_ht=%.3f ft^2  S_vt=%.3f ft^2\n', last.S_ht, last.S_vt);
fprintf('  S_flaperon=%.3f ft^2  S_lef=%.3f ft^2  S_stab=%.3f ft^2  S_rud=%.3f ft^2\n', ...
    last.S_flaperon, last.S_lef, last.S_stab, last.S_rud);
fprintf('  S_ail=%.3f ft^2  S_elev=%.3f ft^2  (both 0: no separate aileron or elevator)\n', ...
    last.S_ail, last.S_elev);
% L3 ONLY: the three buildups the weight equations actually consume. Dependent
% since 2026-08-10, so they track the resized surfaces above instead of sitting
% frozen at the T.O. figures the JSON seeds them with.
fprintf('  Weights-facing buildups: S_csw=%.3f  S_r=%.3f  S_cs=%.3f ft^2\n', ...
    objs.geom.S_csw, objs.geom.S_r, objs.geom.S_cs);

%% Sizing convergence plots (W_TO, OEW, fuel weight, T_SL, S_ref per iteration)
% Straight from SizingLoopL2.run's own returned history. T_SL and S_ref both
% track W_TO every iteration (T_SL = TW_opt*W_TO, S_ref = W_TO/WS_opt). S_ref
% gets the right-hand axis, matching F16A_Level1_SizingReport.m, since it is
% in ft^2 rather than lbf. Before 2026-08-10 S_ref was loop-invariant and had
% no history field to plot.

iters     = [result.history.iter];
WTO_hist  = [result.history.W_TO];
OEW_hist  = [result.history.W_OEW];
Fuel_hist = [result.history.W_fuel];
TSL_hist  = [result.history.T_SL];
Sref_hist = [result.history.S_ref];

figure('Name', 'L3 Sizing Convergence');
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
legend('W_{TO}', 'OEW', 'W_{fuel}', 'T_{SL} (computed by F16PropL2)', 'S_{ref}', 'Location', 'best');
title(sprintf('F-16A Level 3 Sizing Convergence ((W/S)_{opt} = %.2f lbf/ft^2, (T/W)_{opt} = %.4f)', WS_opt, TW_opt));

%% Detailed component / subsystem weight breakdown
% Calls F16WeightsL3's own group- and subcomponent-weight methods at the
% converged W_TO -- these are the exact terms WeightsL3.OEW sums (see that
% toolbox's OEW method); nothing here is a new equation, just re-reading
% what OEW already computed, broken out down to the individual Raymer
% Sec. 15.3.1 line items (Eqs. 15.7-15.24).

W_TO_final = result.W_TO;
W_wing = objs.wts.weight_wing(W_TO_final);
W_tail = objs.wts.weight_tail(W_TO_final);              % struct(HT, VT)
W_fus  = objs.wts.weight_fuselage(W_TO_final);
W_lg   = objs.wts.weight_landing_gear(W_TO_final);       % struct(main, nose)
W_eng  = objs.wts.weight_engine_section(W_TO_final);     % struct(engine,mounts,firewall,section,induction,tailpipe,cooling,oil,controls,starter,total)
W_sys  = objs.wts.weight_systems(W_TO_final);            % struct(fuel_sys,flight_ctrl,instruments,hydraulics,electrical,avionics,furnishings,ac_antiice,handling,total)

% ---- Group-level breakdown (same granularity as the L2 report) -------- %
groupLabelList = {'Wing', 'Horizontal Tail', 'Vertical Tail', 'Fuselage', ...
    'Main Gear', 'Nose Gear', 'Engine Group', 'Systems Group', 'Mission Fuel', ...
    'Fixed Payload', 'Expendable Payload'};
groupLabels = categorical(groupLabelList, groupLabelList, 'Ordinal', true);
groupValues = [W_wing, W_tail.HT, W_tail.VT, W_fus, W_lg.main, W_lg.nose, ...
    W_eng.total, W_sys.total, result.history(end).W_fuel, ...
    objs.wts.W_payload_fixed, objs.wts.W_payload_expendable];

groupTable = table(groupLabels(:), groupValues(:), 'VariableNames', {'Component', 'Weight_lbf'});
disp('Level 3 group-level weight breakdown:');
disp(groupTable);

figure('Name', 'L3 Group Weight Breakdown', 'Position', [100 100 1100 500]);
bar(groupLabels, groupValues);
grid on; ylabel('Weight [lbf]'); xtickangle(30);
title('F-16A Level 3 Group-Level Weight Breakdown');

fprintf('\n  Check: sum(groups) - OEW(W_TO_final) = %.4f lbf (should be ~0)\n', ...
    (W_wing + W_tail.HT + W_tail.VT + W_fus + W_lg.main + W_lg.nose + W_eng.total + W_sys.total) ...
    - objs.wts.OEW(W_TO_final));

% ---- Detailed subcomponent breakdown (engine section + systems) -------- %
detailLabelList = {'Engine (dry)', 'Engine Mounts', 'Firewall', 'Engine Section', ...
    'Air Induction', 'Tailpipe', 'Engine Cooling', 'Oil Cooling', 'Engine Controls', 'Starter', ...
    'Fuel System', 'Flight Controls', 'Instruments', 'Hydraulics', 'Electrical', ...
    'Avionics', 'Furnishings', 'AC & Anti-Ice', 'Handling Gear'};
detailLabels = categorical(detailLabelList, detailLabelList, 'Ordinal', true);
detailValues = [W_eng.engine, W_eng.mounts, W_eng.firewall, W_eng.section, W_eng.induction, ...
    W_eng.tailpipe, W_eng.cooling, W_eng.oil, W_eng.controls, W_eng.starter, ...
    W_sys.fuel_sys, W_sys.flight_ctrl, W_sys.instruments, W_sys.hydraulics, W_sys.electrical, ...
    W_sys.avionics, W_sys.furnishings, W_sys.ac_antiice, W_sys.handling];

detailTable = table(detailLabels(:), detailValues(:), 'VariableNames', {'Subcomponent', 'Weight_lbf'});
disp('Level 3 detailed engine-section / systems subcomponent breakdown:');
disp(detailTable);

figure('Name', 'L3 Detailed Subcomponent Weight Breakdown', 'Position', [100 100 1500 700]);
bar(detailLabels, detailValues);
grid on; ylabel('Weight [lbf]'); xtickangle(45);
title('F-16A Level 3 Detailed Engine-Section / Systems Subcomponent Weight Breakdown');

%% Mission fuel + key drivers by segment
% MissionAnalysisL2 (the mission fidelity paired with the L3 discipline stack --
% there is no L3 mission tier) calls the injected F16AeroL3/F16PropL2 per leg,
% so the per-segment fuel and the L/D and TSFC that drove it come straight from
% the mission breakdown (total_fuel). Fixed-fraction ground/landing legs have
% no L/D and show blank.

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
disp('Level 3 mission fuel + drivers by segment:');
disp(segTable);

figure('Name', 'L3 Mission Fuel by Segment');
tiledlayout(2, 1);
nexttile;
bar(categorical(seg_names(:), seg_names(:), 'Ordinal', true), breakdown.fuel_lbf(:));
grid on; ylabel('Fuel Used [lbf]'); title('F-16A Level 3 Mission Fuel by Segment');
nexttile;
bar(categorical(seg_names(:), seg_names(:), 'Ordinal', true), LD(:));
grid on; ylabel('L/D'); title('F-16A Level 3 L/D by Mission Segment (component buildup + wave drag)');

%% Internal fuel-volume check
% F16WeightsL3 carries fuel-tank-volume INPUTS (V_t = total internal fuel
% volume, V_i = integral/wing tank volume, V_p = pressurised tank volume;
% see that class's properties block) that feed Raymer Eq. 15.9's fuel-
% system weight, but nothing in the framework compares them against the
% mission's actual fuel burn. This is a diagnostic sanity check only (not
% part of the sizing-loop closure), mirroring the legacy Level 3 example
% script's optional "SubsystemsLevel3.checkfuelvol" section.
%
% FUEL DENSITY: 6.7 lb/gal is NOT a new citation introduced here -- it is
% the exact conversion factor already documented (and flagged OPEN
% provenance, todo section P4-5b) in F16WeightsL3.m's own V_t property
% comment, used there to justify V_t = 940 gal from Brandt Wt!B6 =
% 6296.30 lbf. Reused here only as a diagnostic capacity check, not as a
% new discipline equation.

FUEL_DENSITY_LB_PER_GAL = 6.7;   % [F16WeightsL3.m V_t comment; open provenance, todo P4-5b]

V_t = objs.wts.V_t;
V_i = objs.wts.V_i;
V_p = objs.wts.V_p;
W_fuel_final = result.history(end).W_fuel;
V_required_gal = W_fuel_final / FUEL_DENSITY_LB_PER_GAL;
margin_pct = 100 * (V_t - V_required_gal) / V_required_gal;
isSufficient = V_t >= V_required_gal;

volumeTable = table(V_t, V_i, V_p, W_fuel_final, V_required_gal, margin_pct, isSufficient, ...
    'VariableNames', {'V_t_gal', 'V_i_gal', 'V_p_gal', 'W_fuel_lbf', 'V_required_gal', 'Margin_pct', 'IsSufficient'});
disp('Level 3 internal fuel-volume check:');
disp(volumeTable);

fprintf('\nInternal fuel-volume check: V_t = %.1f gal available vs. %.1f gal required for W_fuel = %.1f lbf (%+.1f%% margin) -> %s\n', ...
    V_t, V_required_gal, W_fuel_final, margin_pct, string(isSufficient));
if ~isSufficient
    warning('run_sizing_report_L3:fuelVolumeShortfall', ...
        'Converged mission fuel requires more volume than the assumed V_t input provides.');
end

%% Final summary
fprintf('\n=== F-16A Level 3 Final Summary ===\n');
fprintf('  W_TO = %.1f lbf, OEW = %.1f lbf, W_fuel = %.1f lbf, S_ref = %.2f ft^2, T_SL = %.1f lbf\n', ...
    result.W_TO, objs.wts.OEW(W_TO_final), W_fuel_final, result.S_ref, result.T_SL);
