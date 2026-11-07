function F16ARunAnalyses()
%F16ARUNANALYSES Re-run every F-16A analysis and write the results into the models.
%   Run this after you change a number in a model: a part mass, a candidate's
%   thrust, a trade weight. In order:
%     1. The three trade studies set the active candidate in P and the active
%        kind in L, and link the winning kind to REQ_F16A_L01..L03.
%     2. The mass roll-up writes OEW; the materials and fuel roll-ups report.
%     3. The mission analysis writes MissionFuel_lb and MissionTime_min on the
%        aircraft, and each phase's Duration in the mission activity.
%     4. The cost model writes the four cost Measures of Merit.
%   The order matters: the roll-ups measure the ACTIVE configuration, so they
%   follow the trades, and the cost model reads OEW and mission fuel off the
%   model, so it runs last. Then run_ai_tests reports any number that moved.

% 1) Decide.
trades = {F16AEngineTradeStudy(), F16AAirframeTradeStudy(), F16AFlightControlsTradeStudy()};

pm       = systemcomposer.loadModel("F16A_Physical");
aircraft = lookup(pm, Path="F16A_Physical/Aircraft");
% The cost model's constants describe the reference engine. If the trade picked
% another one, stop here, before any Measure of Merit is written.
F16APhysicalCostModel(pm, PreconditionOnly=true);

% 2) Roll up the configuration the trades chose.
mass = F16APhysicalMassRollup();          % writes OEW_lb and saves
mats = F16APhysicalMaterialsRollup();
fuel = F16APhysicalFuelRollup();

% 3) Fly the mission.
mission = F16AMissionAnalysis();
setMoM(aircraft, "MissionFuel_lb",  mission.TotalFuel_lb);
setMoM(aircraft, "MissionTime_min", mission.TotalTime_min);
am = systemcomposer.loadActivity("F16A_MissionActivity");
for k = 1:height(mission.Table)
    phase = am.Activity.getNode(char(mission.Table.Phase(k)));
    % Combat's behaviour is the kill-chain activity, which leaves it no
    % settable Duration; its 2 min is a mission input, not a computed number.
    if string(phase.ActionBehavior) ~= "Activity"
        phase.Duration = mission.Table.Time_min(k);
    end
end
save(am);

% 4) Price it.
costs = F16APhysicalCostModel(pm);
for name = string(fieldnames(costs)).'
    setMoM(aircraft, name, costs.(name));
end
save_system("F16A_Physical");

fprintf("\n=== F-16A: what the analyses decided ===\n");
for k = 1:numel(trades)
    T = trades{k};
    fprintf("  %-22s kind %-20s score %.5f\n", T.Candidate(1), T.Kind(1), T.Score(1));
end
fprintf("  OEW %.2f lb | composite %.1f%% | fuel %.0f lb available, %.1f lb used in %.1f min\n", ...
    mass.OEW, 100*mats.CompositeFraction, fuel.AvailableFuel_lb, ...
    mission.TotalFuel_lb, mission.TotalTime_min);
fprintf("  Unit cost $%.2fM | life-cycle cost $%.2fM\n\n", ...
    costs.UnitCost_USD/1e6, costs.LifeCycleCost_USD/1e6);

end

% =====================================================================
function setMoM(aircraft, name, value)
% num2str, not string(): string(NaN) is <missing>, which setProperty rejects.
setProperty(aircraft, "F16A_PhysicalProps.MeasureOfMerit." + name, string(num2str(value)));
end
