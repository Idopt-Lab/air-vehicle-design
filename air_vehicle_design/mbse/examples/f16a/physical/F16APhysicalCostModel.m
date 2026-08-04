function cost = F16APhysicalCostModel(m)
%F16APHYSICALCOSTMODEL Unit flyaway cost for the F-16A, by the DAPCA IV model.
%   COST = F16APHYSICALCOSTMODEL(M) returns a unit flyaway cost in USD for the
%   physical model M, to populate MeasureOfMerit.UnitCost_USD on the aircraft.
%
%   The teaching contrast this file exists to draw: OEW is a bottom-up ROLL-UP
%   of the parts (F16APhysicalMassRollup), but cost is NOT a sum of part costs.
%   It is the output of a parametric model -- the DAPCA IV weight-and-quantity
%   regression -- taking empty weight, production quantity, rates and material
%   factors. So OEW <- roll-up, cost <- function.
%
%   IT CALLS sizing/VnV/BrandtF16A/BrandtCost.m; IT DOES NOT RESTATE IT.
%   The DAPCA formulation lives in one place, the same rule D-036 applied to the
%   Brandt masses. What this function contributes is the MBSE side: which empty
%   weight to price, and the checks that the model and the reference still
%   describe the same aeroplane.
%
%   HOW THE MODEL'S OWN OEW GETS IN. BrandtCost.run reads W_empty_lb out of the
%   wt_results struct it is handed, so passing a minimal struct carrying THIS
%   model's rolled-up OEW prices this model rather than re-fetching Brandt's own
%   figure. That is what keeps the result a Simulation and keeps the comparison
%   with BrandtCost's own number a real cross-check instead of a tautology --
%   measured: 19,980.73 lb gives $68.4705M, Brandt's 19,977.61 lb gives
%   $68.4632M, a $7.3k spread that is exactly the D-036 OEW gap.
%
%   IT MUST RUN AFTER THE MASS ROLL-UP (D-043). The generator used to set cost
%   in section 8 and roll up in section 9, so the OEW did not exist yet; the
%   cost write moved to section 9b. An unset OEW is an ERROR here, not a
%   silently cheap aeroplane.
%
%   TAGGED Simulation, NOT Reference -- DAPCA IV evaluated over THIS model's
%   OEW is an analysis output of this repo. BrandtCost's own figure (~$68.4M,
%   quoted in REQ_F16A_026) is the CROSS-CHECK, not the value.
%
%   THE MISSION ARGUMENT IS A PLACEHOLDER, AND PROVABLY INERT. BrandtCost.run
%   demands a miss_results only because its validate_run_ asserts the O&M and
%   life-cycle terms are non-NaN; C_unit_flyaway_usd never reads it
%   (BrandtCost.m:128-131 are its only consumers). Mission fuel is not wired
%   into this model yet -- REQ_F16A_P01 is deliberately unevaluated (D-042) --
%   so a placeholder goes in and only the flyaway comes out. The O&M and LCC
%   figures BrandtCost computes from it are meaningless and are discarded.
%   testFlyawayCostIgnoresTheMissionPlaceholder proves the flyaway is invariant
%   to this input rather than asking a reader to take it on trust. When mission
%   fuel is eventually computed and fed back, replace the placeholder here and
%   the O&M figures become real too.
%
%   NEW BUILD-TIME DEPENDENCY. The generator chain now needs /sizing/ present.
%   Absent, this errors and names it rather than inventing a rate.
%
%   TradeCandidate.UnitCost_USD stays NaN on all seven candidates, permanently
%   (D-005, D-021, D-032, D-043). DAPCA IV prices an airframe, not a part.
%
%   See also F16APHYSICALMASSROLLUP, F16ADATAPROVENANCE.

arguments
    m (1,1) systemcomposer.arch.Model
end

profileName = "F16A_PhysicalProps";
SIZING_POINT_LB = 31377;   % Wt!B3, the same point the other /sizing/ callers use

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

% --- The sizing cost model, reached by PATH (D-047's pattern) -------------
costObj = loadBrandtCost();
inp     = costObj.inp;     % the same JSON the reference is built from

% --- Cross-check: is this still the aeroplane those constants price? ------
% Post-D-053 the winning engine carries its own T_SL_lb, so the architecture
% can be asked whether it still matches the reference. The DAPCA constants
% describe the REFERENCE aircraft; if the trade ever selects a different
% engine they stop applying, and that fails loudly instead of quietly pricing
% the wrong aeroplane.
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
%   and life-cycle terms are non-NaN. The FLYAWAY cost never reads these two
%   fields -- BrandtCost.m:128-131 are their only consumers -- so they cannot
%   move the number this function returns, and
%   testFlyawayCostIgnoresTheMissionPlaceholder measures that rather than
%   asserting it.
%
%   The values are 1, not a plausible fuel burn and sortie time, ON PURPOSE:
%   mission fuel is not computed in this model (D-042), and a realistic-looking
%   placeholder would be a number a reader could mistake for one. NaN is not
%   available -- validate_run_ rejects it, which is the whole reason a
%   placeholder is needed at all.
%
%   WHEN MISSION FUEL IS WIRED, replace this with the real BrandtMission
%   result. The flyaway will not move; the O&M and LCC figures currently
%   discarded by the caller become meaningful.
miss = struct('total_fuel_lb', 1, 'total_time_min', 1);
end

% =====================================================================
function c = loadBrandtCost()
%LOADBRANDTCOST An analyzed BrandtCost, reached by path, not project membership.
%   /sizing/ is three levels above the example root -- the same delegation
%   D-047 uses for the static-margin verification.
avd = fileparts(fileparts(fileparts(f16aRoot())));
bDir = fullfile(avd, "sizing", "VnV", "BrandtF16A");
if ~isfolder(bDir)
    error("F16APhysicalCostModel:noSizingModel", ...
        "The Brandt cost model was not found at %s. The generator chain needs " + ...
        "/sizing/ present at build time (D-043) -- restating the DAPCA IV " + ...
        "formulation here instead is not an option.", bDir);
end
addpath(bDir);
geom = BrandtGeometry(); geom.analyze();
eng  = BrandtEngine();   eng.analyze();
c    = BrandtCost(geom, eng);
c.analyze();
end

% =====================================================================
function [T, name] = activeEngineThrust(m, profileName)
%ACTIVEENGINETHRUST Installed thrust of the engine the trade selected.
%   Reads T_SL_lb off the ACTIVE choice of the Engine variant -- getActiveChoice,
%   never getChoices, for the reason every walk in physical/ uses it.
eng = lookup(m, Path='F16A_Physical/Aircraft/Propulsion/Engine');
if isa(eng, "systemcomposer.arch.VariantComponent")
    eng = getActiveChoice(eng);
end
name = string(eng.Name);
T = str2double(string(getProperty(eng, char(profileName + ".TradeCandidate.T_SL_lb"))));
if ~isfinite(T) || T <= 0
    error("F16APhysicalCostModel:noThrust", ...
        "The active engine %s carries T_SL_lb = %s. The cost model prices an " + ...
        "engine it can measure.", name, string(num2str(T)));
end
end
