function F16ARunAnalyses()
%F16ARUNANALYSES Run all F-16A analyses again and write the results into the models.
%   F16ARUNANALYSES() runs the steps below, in this order. Run it after you
%   change a number in a model, for example a part mass, the thrust of a
%   candidate or a trade weight.
%     1. The three trade studies set the active candidate in P and the active
%        kind in L. They link the winning kind to REQ_F16A_L01..L03.
%     2. The mass roll-up writes OEW. The materials and fuel roll-ups report
%        their results.
%     3. The mission analysis writes MissionFuel_lb and MissionTime_min on the
%        aircraft. It also writes the Duration of each phase in the mission
%        activity.
%     4. The cost model writes the four cost Measures of Merit.
%   The order is important. The roll-ups measure the active configuration, so
%   they run after the trades. The cost model reads OEW and mission fuel from
%   the model, so it runs last. Then run_ai_tests reports each number that
%   changed.

% 1) Make the decisions.
trades = {F16AEngineTradeStudy(), F16AAirframeTradeStudy(), F16AFlightControlsTradeStudy()};

pm       = systemcomposer.loadModel("F16A_Physical");
aircraft = lookup(pm, Path="F16A_Physical/Aircraft");
% The constants of the cost model describe the reference engine. If the trade
% selected a different engine, stop here, before a Measure of Merit is written.
F16APhysicalCostModel(pm, PreconditionOnly=true);

% 2) Roll up the configuration that the trades selected.
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
    % The behaviour of Combat is the kill-chain activity, so Combat has no
    % settable Duration. Its 2 min is a mission input, not a computed number.
    if string(phase.ActionBehavior) ~= "Activity"
        phase.Duration = mission.Table.Time_min(k);
    end
end
save(am);

% 4) Calculate the cost.
costs = F16APhysicalCostModel(pm);
for name = string(fieldnames(costs)).'
    setMoM(aircraft, name, costs.(name));
end
save_system("F16A_Physical");

fprintf("\n=== F-16A: results of the analyses ===\n");
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
% Use num2str, not string(). string(NaN) is <missing>, and setProperty does not
% accept <missing>.
setProperty(aircraft, "F16A_PhysicalProps.MeasureOfMerit." + name, string(num2str(value)));
end
