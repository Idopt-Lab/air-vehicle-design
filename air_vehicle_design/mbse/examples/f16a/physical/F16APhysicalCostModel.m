function cost = F16APhysicalCostModel(m, options)
%F16APHYSICALCOSTMODEL Unit flyaway cost for the F-16A, by the DAPCA IV model.
%   COST = F16APHYSICALCOSTMODEL(M) returns a unit flyaway cost in USD for the
%   physical model M, to populate MeasureOfMerit.UnitCost_USD on the aircraft.
%
%   F16APHYSICALCOSTMODEL(M, PreconditionOnly=true) checks only that the DAPCA
%   constants still describe this aircraft, and returns without pricing. The
%   generator calls it that way as soon as the trade has a winner, so a build
%   that CANNOT be priced stops there instead of saving a model whose cost
%   Measure of Merit it will never fill in.
%
%   Teaching point: OEW is a bottom-up ROLL-UP of the parts
%   (F16APhysicalMassRollup), but cost is not a sum of part costs -- it is the
%   output of a parametric model. OEW <- roll-up, cost <- function.
%
%   It CALLS sizing/VnV/BrandtF16A/BrandtCost.m rather than restating DAPCA IV,
%   handing it THIS model's rolled-up OEW, so the result is a Simulation and
%   BrandtCost's own ~$68.4M stays a real cross-check. It must run AFTER the
%   mass roll-up: an unset OEW is an error here, not a cheap aeroplane (D-043).
%
%   See also F16APHYSICALMASSROLLUP, F16ADATAPROVENANCE.

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
    cost = NaN;   % nothing was priced, and the caller asked for nothing
    return
end

% --- We: this model's own rolled-up empty weight --------------------------
aircraft = lookup(m, Path='F16A_Physical/Aircraft');
We = str2double(string(getProperty(aircraft, ...
    char(profileName + ".MeasureOfMerit.OEW_lb"))));
if ~isfinite(We) || We <= 0
    error("F16APhysicalCostModel:oewNotRolledUp", ...
        "The aircraft's OEW Measure of Merit is %s, so there is no empty weight " + ...
        "to price. Run F16APhysicalMassRollup before the cost model -- this is " + ...
        "the section 8 / section 9 ordering D-043 corrected.", string(num2str(We)));
end

% --- Price THIS model's empty weight with the reference's own code --------
% W_TO_lb is validated by run() and then never read by any cost term
% (BrandtCost.m:78-80 is its only appearance); the sizing point is passed
% because it is the honest value, not because the arithmetic needs it.
r = costObj.run(SIZING_POINT_LB, struct('W_empty_lb', We), missionPlaceholder());
cost = r.C_unit_flyaway_usd;

fprintf("\n=== F-16A unit flyaway cost (BrandtCost DAPCA IV, this model's OEW) ===\n");
fprintf("  We (rolled up)      : %10.2f lb\n", We);
fprintf("  Unit flyaway cost   : $%9.2fM  (Simulation)\n", cost/1e6);
fprintf("  BrandtCost reference: $%9.2fM  (cross-check, REQ_F16A_026)\n", 68.4);
fprintf("  O&M / LCC           : discarded -- computed from a placeholder mission (D-042)\n");

end

% =====================================================================
function miss = missionPlaceholder()
%MISSIONPLACEHOLDER The inert mission argument BrandtCost.run insists on.
%   run() demands a miss_results only so its validate_run_ can assert the O&M
%   and life-cycle terms are non-NaN. The FLYAWAY cost never reads them
%   (BrandtCost.m:128-131 are their only consumers), so they cannot move the
%   number returned above -- testFlyawayCostIgnoresTheMissionPlaceholder
%   measures that rather than asking a reader to take it on trust.
%
%   The values are 1, not a plausible fuel burn and sortie time, ON PURPOSE:
%   mission fuel is not computed in this model (D-042), and a realistic-looking
%   placeholder would be a number a reader could mistake for one. NaN is not
%   available -- validate_run_ rejects it, which is why a placeholder is needed.
miss = struct('total_fuel_lb', 1, 'total_time_min', 1);
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
