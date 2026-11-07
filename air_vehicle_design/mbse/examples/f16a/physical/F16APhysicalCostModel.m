function costs = F16APhysicalCostModel(m, options)
%F16APHYSICALCOSTMODEL Cost of the F-16A, by the DAPCA IV model.
%   COSTS = F16APHYSICALCOSTMODEL(M) prices the physical model M and returns a
%   struct: UnitCost_USD, OMCostAnnual_USD, OMCostLife_USD, LifeCycleCost_USD.
%
%   F16APHYSICALCOSTMODEL(M, PreconditionOnly=true) only checks that the DAPCA
%   constants still describe this aircraft, and returns NaN costs.
%
%   Teaching point: OEW is a bottom-up ROLL-UP of the parts, but cost is not a
%   sum of part costs -- it is the output of a parametric model, here DAPCA IV
%   (sizing/VnV/BrandtF16A/BrandtCost.m), fed THIS model's OEW and mission.
%   So it runs after the mass roll-up and the mission analysis, and an unset
%   OEW or mission is an error here, not a cheap aeroplane.
%
%   See also F16APHYSICALMASSROLLUP, F16AMISSIONANALYSIS, F16ARUNANALYSES.

arguments
    m (1,1) systemcomposer.arch.Model
    options.PreconditionOnly (1,1) logical = false   % check, price nothing
end

profileName = "F16A_PhysicalProps";
SIZING_POINT_LB = 31377;   % Wt!B3, the same point the other /sizing/ callers use

% The sizing cost model, reached by path. pathGuard restores the path when
% this function returns, so hold it.
[costObj, pathGuard] = loadBrandtCost();   %#ok<ASGLU>
inp = costObj.inp;                         % the same JSON the reference is built from

% --- Is this still the aeroplane those constants price? -------------------
% The DAPCA constants describe the REFERENCE aircraft. If the trade selects a
% different engine they stop applying, and that fails loudly instead of
% quietly pricing the wrong aeroplane.
[Tmax, engineName] = activeEngineThrust(m, profileName);
TmaxRef = inp.engine.T_AB_SLS_lb * inp.engine.n_engines;
if abs(Tmax - TmaxRef) > 1e-6
    error("F16APhysicalCostModel:engineIsNotTheReference", ...
        "The active engine %s states %g lb of installed thrust, but the DAPCA " + ...
        "constants describe %g lb (%d x %g). Those constants price the REFERENCE " + ...
        "aircraft, so they do not apply to a different propulsion choice. " + ...
        "Re-source the cost inputs before trusting this number.", ...
        engineName, Tmax, TmaxRef, inp.engine.n_engines, inp.engine.T_AB_SLS_lb);
end

if options.PreconditionOnly
    costs = emptyCosts();   % nothing was priced, and the caller asked for nothing
    return
end

% --- We: this model's own rolled-up empty weight --------------------------
aircraft = lookup(m, Path='F16A_Physical/Aircraft');
We = readMoM(aircraft, profileName, "OEW_lb");
if ~isfinite(We) || We <= 0
    error("F16APhysicalCostModel:oewNotRolledUp", ...
        "The aircraft's OEW Measure of Merit is %s, so there is no empty weight " + ...
        "to price. Run F16APhysicalMassRollup before the cost model, as " + ...
        "F16ARunAnalyses does.", string(num2str(We)));
end

% --- The mission THIS model flies, read back off the aircraft --------------
% The cost model prices what the model says it flies. Sortie time is a
% divisor in BrandtCost, so a non-positive time is rejected here rather than
% returning an infinite life-cycle cost.
fuel_lb  = readMoM(aircraft, profileName, "MissionFuel_lb");
time_min = readMoM(aircraft, profileName, "MissionTime_min");
if ~isfinite(fuel_lb) || fuel_lb <= 0 || ~isfinite(time_min) || time_min <= 0
    error("F16APhysicalCostModel:missionNotAnalysed", ...
        "The aircraft's mission Measures of Merit are %s lb over %s min, so " + ...
        "there is no sortie to cost. Run F16AMissionAnalysis and write them " + ...
        "before the cost model, as F16ARunAnalyses does.", ...
        string(num2str(fuel_lb)), string(num2str(time_min)));
end

% --- Price THIS model with the reference's own code -----------------------
% (No cost term reads W_TO_lb; the sizing point is passed as the honest value.)
r = costObj.run(SIZING_POINT_LB, struct('W_empty_lb', We), ...
    struct('total_fuel_lb', fuel_lb, 'total_time_min', time_min));

costs = struct( ...
    UnitCost_USD      = r.C_unit_flyaway_usd, ...
    OMCostAnnual_USD  = r.C_OM_annual_usd, ...
    OMCostLife_USD    = r.C_OM_life_usd, ...
    LifeCycleCost_USD = r.C_LCC_usd);

fprintf("\n=== F-16A cost (BrandtCost DAPCA IV, this model's OEW and mission) ===\n");
fprintf("  We (rolled up)      : %10.2f lb\n", We);
fprintf("  Mission             : %10.2f lb over %.2f min\n", fuel_lb, time_min);
fprintf("  Unit flyaway cost   : $%9.2fM  (Simulation; BrandtCost ref $%.1fM, REQ_F16A_026)\n", ...
    costs.UnitCost_USD/1e6, 68.4);
fprintf("  O&M, annual         : $%9.2fM\n", costs.OMCostAnnual_USD/1e6);
fprintf("  O&M over life       : $%9.2fM  (BrandtCost ref $%.2fM)\n", ...
    costs.OMCostLife_USD/1e6, 24.84);
fprintf("  Life-cycle cost     : $%9.2fM  (BrandtCost ref $%.2fM, REQ_F16A_P02)\n", ...
    costs.LifeCycleCost_USD/1e6, 93.26);
fprintf("  The flyaway does NOT move with mission fuel -- only the three below it do.\n");

end

% =====================================================================
function c = emptyCosts()
%EMPTYCOSTS The shape the caller expects, with nothing priced in it.
c = struct(UnitCost_USD = NaN, OMCostAnnual_USD = NaN, ...
           OMCostLife_USD = NaN, LifeCycleCost_USD = NaN);
end

% =====================================================================
function v = readMoM(aircraft, profileName, prop)
%READMOM One Measure of Merit off the aircraft, as a number.
v = str2double(string(getProperty(aircraft, ...
    char(profileName + ".MeasureOfMerit." + prop))));
end

% =====================================================================
function [c, guard] = loadBrandtCost()
%LOADBRANDTCOST An analyzed BrandtCost from /sizing/, three levels above the root.
%   GUARD is an onCleanup that restores the path, so sizing/ does not stay on
%   it after this call. The caller must hold it while it uses the object.
avd = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16APhysicalCostModel:noSizingModel", ...
        "The Brandt cost model was not found at %s; the cost model needs /sizing/.", bDir);
end
oldPath = path();
guard   = onCleanup(@() path(oldPath));
addpath(bDir);
geom = BrandtGeometry(); geom.analyze();
eng  = BrandtEngine();   eng.analyze();
c    = BrandtCost(geom, eng);
c.analyze();
end

% =====================================================================
function [T, name] = activeEngineThrust(m, profileName)
%ACTIVEENGINETHRUST Thrust_SL_lb of the engine the trade selected (the ACTIVE choice).
eng = lookup(m, Path='F16A_Physical/Aircraft/Propulsion/Engine');
if isa(eng, "systemcomposer.arch.VariantComponent")
    eng = getActiveChoice(eng);
end
name = string(eng.Name);
T = str2double(string(getProperty(eng, char(profileName + ".EngineCandidate.Thrust_SL_lb"))));
if ~isfinite(T) || T <= 0
    error("F16APhysicalCostModel:noThrust", ...
        "The active engine %s carries Thrust_SL_lb = %s. The cost model prices an " + ...
        "engine it can measure.", name, string(num2str(T)));
end
end
