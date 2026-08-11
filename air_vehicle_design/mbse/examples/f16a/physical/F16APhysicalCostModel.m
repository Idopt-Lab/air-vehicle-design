function costs = F16APhysicalCostModel(m, options)
%F16APHYSICALCOSTMODEL Cost of the F-16A, by the DAPCA IV model.
%   COSTS = F16APHYSICALCOSTMODEL(M) prices the physical model M and returns a
%   struct: UnitCost_USD, OMCostAnnual_USD, OMCostLife_USD, LifeCycleCost_USD.
%
%   F16APHYSICALCOSTMODEL(M, PreconditionOnly=true) checks only that the DAPCA
%   constants still describe this aircraft, and returns a struct of NaN without
%   pricing. The generator calls it that way as soon as the trade has a winner,
%   so a build that CANNOT be priced stops there instead of saving a model
%   whose cost Measures of Merit it will never fill in.
%
%   Teaching point: OEW is a bottom-up ROLL-UP of the parts
%   (F16APhysicalMassRollup), but cost is not a sum of part costs -- it is the
%   output of a parametric model. OEW <- roll-up, cost <- function.
%
%   It CALLS sizing/VnV/BrandtF16A/BrandtCost.m rather than restating DAPCA IV,
%   handing it THIS model's rolled-up OEW and THIS model's mission fuel, so the
%   results are Simulations and BrandtCost's own figures stay real
%   cross-checks. It runs AFTER the mass roll-up and after section 9c: an unset
%   OEW or mission is an error here, not a cheap aeroplane (D-043, D-059).
%
%   See also F16APHYSICALMASSROLLUP, F16AMISSIONANALYSIS, F16ADATAPROVENANCE.

arguments
    m (1,1) systemcomposer.arch.Model
    % Check the DAPCA precondition and return; price nothing. Lets the
    % generator fail at the cause, before the sections that save the model.
    options.PreconditionOnly (1,1) logical = false
end

profileName = "F16A_PhysicalProps";
SIZING_POINT_LB = 31377;   % Wt!B3, the same point the other /sizing/ callers use

% --- The sizing cost model, reached by PATH (D-047's pattern) -------------
% pathGuard restores the path when this function returns; hold it, do not
% discard it.
[costObj, pathGuard] = loadBrandtCost();   %#ok<ASGLU>
inp = costObj.inp;                         % the same JSON the reference is built from

% --- Cross-check: is this still the aeroplane those constants price? ------
% Checked FIRST, because it needs no OEW and it is the precondition the
% generator wants answered before it saves anything. Post-D-053 the winning
% engine carries its own Thrust_SL_lb, so the architecture can be asked whether it
% still matches the reference. The DAPCA constants describe the REFERENCE
% aircraft; if the trade ever selects a different engine they stop applying,
% and that fails loudly instead of quietly pricing the wrong aeroplane.
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
        "to price. Run F16APhysicalMassRollup before the cost model -- this is " + ...
        "the section 8 / section 9 ordering D-043 corrected.", string(num2str(We)));
end

% --- The mission THIS model flies, read back off the aircraft --------------
% Not recomputed here: section 9c wrote it, and the cost model prices what the
% model says it flies. total_time_min is a DIVISOR in BrandtCost.m:128 with no
% zero guard of its own, so a non-positive time is rejected here rather than
% silently returning an infinite life-cycle cost.
fuel_lb  = readMoM(aircraft, profileName, "MissionFuel_lb");
time_min = readMoM(aircraft, profileName, "MissionTime_min");
if ~isfinite(fuel_lb) || fuel_lb <= 0 || ~isfinite(time_min) || time_min <= 0
    error("F16APhysicalCostModel:missionNotAnalysed", ...
        "The aircraft's mission Measures of Merit are %s lb over %s min, so " + ...
        "there is no sortie to cost. Run F16AMissionAnalysis and write them " + ...
        "before the cost model -- this is the section 9c / 9d ordering (D-059).", ...
        string(num2str(fuel_lb)), string(num2str(time_min)));
end

% --- Price THIS model with the reference's own code -----------------------
% W_TO_lb is validated by run() and then never read by any cost term
% (BrandtCost.m:78-80 is its only appearance); the sizing point is passed
% because it is the honest value, not because the arithmetic needs it.
r = costObj.run(SIZING_POINT_LB, struct('W_empty_lb', We), ...
    struct('total_fuel_lb', fuel_lb, 'total_time_min', time_min));

costs = struct( ...
    UnitCost_USD      = r.C_unit_flyaway_usd, ...
    OMCostAnnual_USD  = r.C_OM_annual_usd, ...
    OMCostLife_USD    = r.C_OM_life_usd, ...
    LifeCycleCost_USD = r.C_LCC_usd);

fprintf("\n=== F-16A cost (BrandtCost DAPCA IV, this model's OEW and mission) ===\n");
fprintf("  We (rolled up)      : %10.2f lb\n", We);
fprintf("  Mission (9c)        : %10.2f lb over %.2f min\n", fuel_lb, time_min);
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
%LOADBRANDTCOST An analyzed BrandtCost, reached by path, not project membership.
%   /sizing/ is three levels above the example root -- the same delegation
%   D-047 uses for the static-margin verification.
%
%   GUARD is an onCleanup that puts the path back. A bare addpath would leave
%   sizing/ permanently resolvable, which is exactly what D-047's PathFixtures
%   exist to prevent: the verification suites would then keep passing with
%   their own fixture deleted, and a savepath after a build would bake a
%   directory outside the project into pathdef.m for every future session.
%   The caller must HOLD the guard for as long as it uses the returned object.
avd = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16APhysicalCostModel:noSizingModel", ...
        "The Brandt cost model was not found at %s. The generator chain needs " + ...
        "/sizing/ present at build time (D-043) -- restating the DAPCA IV " + ...
        "formulation here instead is not an option.", bDir);
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
%ACTIVEENGINETHRUST Installed thrust of the engine the trade selected.
%   Reads Thrust_SL_lb off the ACTIVE choice of the Engine variant --
%   getActiveChoice, never getChoices, for the reason every walk in physical/
%   uses it. The property lives on EngineCandidate, the engine trade's own
%   stereotype (D-056); no other candidate in the model declares a thrust.
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
