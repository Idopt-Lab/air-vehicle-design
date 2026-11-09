function costs = F16APhysicalCostModel(m, options)
%F16APHYSICALCOSTMODEL Calculate the cost of the F-16A with the DAPCA IV model.
%   COSTS = F16APHYSICALCOSTMODEL(M) calculates the cost of the physical model
%   M. It returns a struct with these fields: UnitCost_USD, OMCostAnnual_USD,
%   OMCostLife_USD, LifeCycleCost_USD.
%
%   F16APHYSICALCOSTMODEL(M, PreconditionOnly=true) only checks that the DAPCA
%   constants still describe this aircraft. It returns NaN costs.
%
%   Teaching point: OEW is a bottom-up roll-up of the parts, but cost is not a
%   sum of part costs. Cost is the output of a parametric model. Here the
%   model is DAPCA IV (sizing/VnV/BrandtF16A/BrandtCost.m), with the OEW and
%   mission of this model as inputs. Thus this function runs after the mass
%   roll-up and the mission analysis. An unset OEW or mission causes an error
%   here. It does not give a low-cost aeroplane.
%
%   See also F16APHYSICALMASSROLLUP, F16AMISSIONANALYSIS, F16ARUNANALYSES.

arguments
    m (1,1) systemcomposer.arch.Model
    options.PreconditionOnly (1,1) logical = false   % check only, calculate no cost
end

profileName = "F16A_PhysicalProps";
SIZING_POINT_LB = 31377;   % Wt!B3, the same point that the other /sizing/ callers use

% Get the sizing cost model through the path. pathGuard restores the path when
% this function returns, so keep it.
[costObj, pathGuard] = loadBrandtCost();   %#ok<ASGLU>
inp = costObj.inp;                         % the same JSON that the reference uses

% --- Do the constants still apply to this aeroplane? ----------------------
% The DAPCA constants describe the reference aircraft. If the trade selects a
% different engine, the constants do not apply. Then this code stops with an
% error. It does not silently calculate the cost of the wrong aeroplane.
[Tmax, engineName] = activeEngineThrust(m, profileName);
TmaxRef = inp.engine.T_AB_SLS_lb * inp.engine.n_engines;
if abs(Tmax - TmaxRef) > 1e-6
    error("F16APhysicalCostModel:engineIsNotTheReference", ...
        "The active engine %s has %g lb of installed thrust, but the DAPCA " + ...
        "constants describe %g lb (%d x %g). These constants are for the reference " + ...
        "aircraft, so they do not apply to a different propulsion choice. " + ...
        "Get new sources for the cost inputs before you use this number.", ...
        engineName, Tmax, TmaxRef, inp.engine.n_engines, inp.engine.T_AB_SLS_lb);
end

if options.PreconditionOnly
    costs = emptyCosts();   % no cost was calculated, and the caller requested no cost
    return
end

% --- We: the rolled-up empty weight of this model -------------------------
aircraft = lookup(m, Path='F16A_Physical/Aircraft');
We = readMoM(aircraft, profileName, "OEW_lb");
if ~isfinite(We) || We <= 0
    error("F16APhysicalCostModel:oewNotRolledUp", ...
        "The OEW Measure of Merit of the aircraft is %s, so there is no empty weight " + ...
        "for the cost calculation. Run F16APhysicalMassRollup before the cost model, " + ...
        "as F16ARunAnalyses does.", string(num2str(We)));
end

% --- The mission that this model flies, read from the aircraft ------------
% The cost model calculates the cost of the mission that the model gives.
% Sortie time is a divisor in BrandtCost. Thus this code rejects a time that
% is not positive, and does not return an infinite life-cycle cost.
fuel_lb  = readMoM(aircraft, profileName, "MissionFuel_lb");
time_min = readMoM(aircraft, profileName, "MissionTime_min");
if ~isfinite(fuel_lb) || fuel_lb <= 0 || ~isfinite(time_min) || time_min <= 0
    error("F16APhysicalCostModel:missionNotAnalysed", ...
        "The mission Measures of Merit of the aircraft are %s lb over %s min, so " + ...
        "there is no sortie for the cost calculation. Run F16AMissionAnalysis and " + ...
        "write these values before the cost model, as F16ARunAnalyses does.", ...
        string(num2str(fuel_lb)), string(num2str(time_min)));
end

% --- Calculate the cost of this model with the code of the reference ------
% (No cost term reads W_TO_lb. The code gives the sizing point because it is
% the correct value.)
r = costObj.run(SIZING_POINT_LB, struct('W_empty_lb', We), ...
    struct('total_fuel_lb', fuel_lb, 'total_time_min', time_min));

costs = struct( ...
    UnitCost_USD      = r.C_unit_flyaway_usd, ...
    OMCostAnnual_USD  = r.C_OM_annual_usd, ...
    OMCostLife_USD    = r.C_OM_life_usd, ...
    LifeCycleCost_USD = r.C_LCC_usd);

fprintf("\n=== F-16A cost (BrandtCost DAPCA IV, with the OEW and mission of this model) ===\n");
fprintf("  We (rolled up)      : %10.2f lb\n", We);
fprintf("  Mission             : %10.2f lb over %.2f min\n", fuel_lb, time_min);
fprintf("  Unit flyaway cost   : $%9.2fM  (Simulation, BrandtCost ref $%.1fM, REQ_F16A_026)\n", ...
    costs.UnitCost_USD/1e6, 68.4);
fprintf("  O&M, annual         : $%9.2fM\n", costs.OMCostAnnual_USD/1e6);
fprintf("  O&M over life       : $%9.2fM  (BrandtCost ref $%.2fM)\n", ...
    costs.OMCostLife_USD/1e6, 24.84);
fprintf("  Life-cycle cost     : $%9.2fM  (BrandtCost ref $%.2fM, REQ_F16A_P02)\n", ...
    costs.LifeCycleCost_USD/1e6, 93.26);
fprintf("  The flyaway cost does NOT change with mission fuel. Only the three costs below it change.\n");

end

% =====================================================================
function c = emptyCosts()
%EMPTYCOSTS Return the struct that the caller expects, with no costs in it.
c = struct(UnitCost_USD = NaN, OMCostAnnual_USD = NaN, ...
           OMCostLife_USD = NaN, LifeCycleCost_USD = NaN);
end

% =====================================================================
function v = readMoM(aircraft, profileName, prop)
%READMOM Read one Measure of Merit from the aircraft, as a number.
v = str2double(string(getProperty(aircraft, ...
    char(profileName + ".MeasureOfMerit." + prop))));
end

% =====================================================================
function [c, guard] = loadBrandtCost()
%LOADBRANDTCOST Return an analyzed BrandtCost from /sizing/, three levels above the root.
%   GUARD is an onCleanup object that restores the path, so sizing/ does not
%   stay on the path after this call. The caller must keep GUARD while it
%   uses the object.
avd = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16APhysicalCostModel:noSizingModel", ...
        "The Brandt cost model is not at %s. The cost model needs /sizing/.", bDir);
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
%ACTIVEENGINETHRUST Return Thrust_SL_lb of the engine that the trade selected (the active choice).
eng = lookup(m, Path='F16A_Physical/Aircraft/Propulsion/Engine');
if isa(eng, "systemcomposer.arch.VariantComponent")
    eng = getActiveChoice(eng);
end
name = string(eng.Name);
T = str2double(string(getProperty(eng, char(profileName + ".EngineCandidate.Thrust_SL_lb"))));
if ~isfinite(T) || T <= 0
    error("F16APhysicalCostModel:noThrust", ...
        "The active engine %s has Thrust_SL_lb = %s. The cost model needs a " + ...
        "thrust that it can measure.", name, string(num2str(T)));
end
end
