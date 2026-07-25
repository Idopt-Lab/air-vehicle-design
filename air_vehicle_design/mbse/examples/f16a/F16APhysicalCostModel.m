function cost = F16APhysicalCostModel(m) %#ok<INUSD>
%F16APHYSICALCOSTMODEL Cost-model hook for the F-16A unit flyaway cost MoM.
%   COST = F16APHYSICALCOSTMODEL(M) is where a cost estimate for the
%   physical model M (the F16A_Physical System Composer model) will be
%   computed and returned, in USD, to populate the UnitCost_USD property of
%   the MeasureOfMerit stereotype on the aircraft root.
%
%   Unlike the mass Measure of Merit -- which is a bottom-up ROLL-UP of the
%   parts' Mass_lb (see F16APhysicalMassRollup) -- unit flyaway cost is NOT
%   a simple sum of part costs. It is the output of a parametric cost model
%   (e.g. the DAPCA IV weight-and-quantity regression used by the Brandt
%   F-16A reference, sizing/VnV/BrandtF16A). That model takes empty weight,
%   production quantity, engineering/tooling/manufacturing hours, material
%   factors, etc. -- which is why cost is sourced from a FUNCTION here, not
%   rolled up over the tree. This is the teaching contrast the Physical
%   layer draws: OEW <- roll-up, Cost <- analysis function.
%
%   STATUS: STUB. Returns NaN ("not yet computed") on purpose -- we do not
%   invent a cost number. Implement a DAPCA-IV-style estimate here later
%   (it can read the rolled-up OEW and the material mix from the model).
%
%   Cost is a Measure of Merit to MINIMIZE (see REQ_F16A_026), not a
%   pass/fail threshold, so nothing asserts this value against a limit.

% TODO: implement a DAPCA-IV-style unit flyaway cost model. For now the cost
% MoM is declared on the model but left uncomputed (NaN) pending that model.
cost = NaN;

end
