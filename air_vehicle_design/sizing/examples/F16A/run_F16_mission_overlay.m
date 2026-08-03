%% run_F16_mission_overlay
%   Plot Deliverables (docs/subplans/07_mission_analysis.md, "Plot
%   Deliverables"): (1) a waterfall bar chart of fuel burn per CAP segment,
%   stacked to the total mission fuel; (2) an L1/L2/L3 fidelity overlay
%   showing how the total-fuel estimate changes across fidelity levels --
%   mirroring run_F16_constraint_diagram_overlay.m's fidelity-overlay
%   pattern from Step 6 (same script-not-function convention, same
%   per-level color scheme via `lines`).
%
%   NOT A TEST -- a plotting script only, informational (same category as
%   mission_brandt_comparison.m; see that file for the CAP-vs-Brandt
%   profile-mismatch caveat, which also applies to the L1/L2/L3 total-fuel
%   bars below -- they are NOT compared against Brandt here, only against
%   each other).

levels = ["L1", "L2", "L3"];
colors = lines(numel(levels));
W_TO   = 31377;   % Brandt B38 / F16Baseline TOGW

m1 = F16MissionL1(mission_profile_path());
m2 = F16MissionL2(mission_profile_path());
m3 = F16MissionL3(mission_profile_path());

a1 = F16AeroL1(); p1 = F16PropL1();
a2 = F16AeroL2(); p2 = F16PropL2();
a3 = F16AeroL3(); p3 = F16PropL2();   % no F16PropL3 exists yet -- see mission_brandt_comparison.m header

[Wfuel1, bd1] = MissionL1.get_mission_fuel(m1.missiondata, W_TO, a1, p1);
[Wfuel2, bd2] = MissionL2.get_mission_fuel(m2.missiondata, W_TO, a2, p2);
[Wfuel3, bd3] = MissionL3.get_mission_fuel(m3.missiondata, W_TO, a3, p3);

% ════════════════════════════════════════════════════════════════════════ %
%  Plot Deliverable #1 -- waterfall: fuel burn per segment (L3, most
%  detailed fidelity), stacked to the total mission fuel.
% ════════════════════════════════════════════════════════════════════════ %

fig1 = figure('Name', 'F-16 CAP Mission -- Fuel Burn Waterfall (L3)');
ax1  = axes(fig1);

n_seg    = numel(bd3.segment_names);
fuel_seg = bd3.fuel_used_lbf;

% True "waterfall" floating-bar construction: running_W_before(i) is the
% gross weight at the START of segment i (W_TO minus all prior segments'
% fuel burn); base(i) = running_W_before(i) - fuel_seg(i) is the weight
% AFTER segment i. Plotting [base; fuel_seg] as a STACKED bar with base
% invisible (white/no edge) makes only the fuel_seg portion visible,
% floating at its correct cumulative height -- the classic waterfall look.
running_W_before = zeros(1, n_seg);
running_W_before(1) = W_TO;
for i = 2:n_seg
    running_W_before(i) = running_W_before(i-1) - fuel_seg(i-1);
end
base = running_W_before - fuel_seg;

hold(ax1, 'on');
bh = bar(ax1, 1:n_seg, [base; fuel_seg]', 'stacked', 'BarWidth', 0.6);
bh(1).FaceColor = 'none';
bh(1).EdgeColor = 'none';
bh(2).FaceColor = colors(3,:);
for i = 1:n_seg
    text(ax1, i, running_W_before(i), sprintf('%.0f', fuel_seg(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
end
hold(ax1, 'off');

xticks(ax1, 1:n_seg);
xticklabels(ax1, cellstr(bd3.segment_names));
xtickangle(ax1, 45);
ylim(ax1, [min(base)*0.98, W_TO*1.01]);
ylabel(ax1, 'Aircraft gross weight [lbf] (floating bar height = fuel burned that segment)');
title(ax1, sprintf('F-16 CAP Mission Fuel-Burn Waterfall (L3) -- total = %.0f lbf (excl. reserve)', ...
    bd3.total_fuel_used_lbf));
grid(ax1, 'on');

fprintf('Plot Deliverable #1 (waterfall, L3): total fuel used (excl. reserve) = %.1f lbf, W_fuel (incl. RFF) = %.1f lbf\n', ...
    bd3.total_fuel_used_lbf, Wfuel3);

% ════════════════════════════════════════════════════════════════════════ %
%  Plot Deliverable #2 -- L1/L2/L3 fidelity overlay: total mission fuel.
% ════════════════════════════════════════════════════════════════════════ %

fig2 = figure('Name', 'F-16 CAP Mission -- Fidelity Overlay');
ax2  = axes(fig2);

totals = [Wfuel1, Wfuel2, Wfuel3];
hold(ax2, 'on');
for i = 1:numel(levels)
    bar(ax2, i, totals(i), 'FaceColor', colors(i,:), 'DisplayName', levels(i));
    text(ax2, i, totals(i), sprintf('%.0f lbf', totals(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
end
hold(ax2, 'off');

xticks(ax2, 1:numel(levels));
xticklabels(ax2, cellstr(levels));
ylabel(ax2, 'Total mission fuel W_{fuel} [lbf] (incl. RFF reserve)');
title(ax2, 'F-16 CAP Mission -- Total Fuel by Fidelity Level (L1 vs L2 vs L3)');
grid(ax2, 'on');

fprintf('Plot Deliverable #2 (fidelity overlay): W_fuel  L1=%.1f  L2=%.1f  L3=%.1f lbf\n', ...
    Wfuel1, Wfuel2, Wfuel3);
fprintf('  (CAP-profile totals only -- NOT compared against Brandt''s Miss-tab 6000.43 lb here;\n');
fprintf('   see mission_brandt_comparison.m for that informational, non-pass/fail comparison.)\n');
