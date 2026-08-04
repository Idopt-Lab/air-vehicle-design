function cost = F16APhysicalCostModel(m) %#ok<INUSD>
%F16APHYSICALCOSTMODEL Cost-model hook for the F-16A unit flyaway cost MoM.
%   COST = F16APHYSICALCOSTMODEL(M) returns a unit flyaway cost in USD for the
%   physical model M, to populate MeasureOfMerit.UnitCost_USD on the aircraft.
%
%   The teaching contrast this file exists to draw: OEW is a bottom-up ROLL-UP
%   of the parts (F16APhysicalMassRollup), but cost is NOT a sum of part costs.
%   It is the output of a parametric model -- the DAPCA IV weight-and-quantity
%   regression used by the Brandt reference -- taking empty weight, production
%   quantity, rates and material factors. So OEW <- roll-up, cost <- function.
%
%   STATUS: STUB, returns NaN. We do not invent a cost number. Implementing it
%   is open work (D-043): whole-aircraft Measure of Merit only, tagged
%   Simulation, and the seven trade candidates keep NaN permanently.

cost = NaN;

end
