function results = F16APhysicalFuelRollup()
%F16APHYSICALFUELROLLUP Roll up the total available internal fuel capacity.
%   RESULTS = F16APHYSICALFUELROLLUP() sums FuelCapacity_lb over every part
%   under the FuelSystem role that CARRIES a FuelTank stereotype.
%
%   RESULTS fields: AvailableFuel_lb (total), Table (per-tank capacity).
%
%   This is the "available" side of REQ_F16A_P01. The "required" side comes
%   from F16APhysicalMissionFuel, and the verify test compares the two.
%   Capacity is expressed as fuel WEIGHT (lb) so it compares directly with
%   mission fuel burn.
%
%   It asks the model which parts hold fuel instead of assuming a list of
%   names (D-038). The walk itself is F16AStereotypeLeaves.
%
%   See also F16ASTEREOTYPELEAVES, F16APHYSICALMATERIALSROLLUP.

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
capProp     = profileName + ".FuelTank.FuelCapacity_lb";

thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
addpath(fullfile(thisDir, "physical"));
m = systemcomposer.loadModel(modelName);

fuelSys = lookup(m, Path="F16A_Physical/Aircraft/FuelSystem");
[names, cap] = F16AStereotypeLeaves(fuelSys, "FuelTank", capProp);

% A silent 0 is the failure this replaces -- it must not come back as a
% different silent 0, so an empty walk is an error, not an empty total.
if isempty(names)
    error("F16APhysicalFuelRollup:noFuelTanks", ...
        "No part under %s carries a FuelTank stereotype -- the available-fuel " + ...
        "side of REQ_F16A_P01 cannot be evaluated.", string(fuelSys.Name));
end

total = sum(cap);

T = table(names, cap, 'VariableNames', {'Tank','FuelCapacity_lb'});
results = struct(AvailableFuel_lb = total, Table = T);

fprintf("\n=== F-16A available fuel capacity roll-up ===\n");
disp(T);
fprintf("Total available internal fuel: %.0f lb\n", total);

end
