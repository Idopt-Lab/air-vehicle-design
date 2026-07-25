function results = F16APhysicalFuelRollup()
%F16APHYSICALFUELROLLUP Roll up the total available internal fuel capacity.
%   RESULTS = F16APHYSICALFUELROLLUP() sums the FuelCapacity_lb of the
%   internal fuel tanks (the children of FuelSystem) to a total available
%   fuel capacity for the aircraft.
%
%   RESULTS fields: AvailableFuel_lb (total), Table (per-tank capacity).
%
%   This is the "available" side of REQ_F16A_P01 (fuel volume sufficiency).
%   The "required" side comes from a mission-analysis function
%   (F16APhysicalMissionFuel); the verify test compares the two. Capacity is
%   expressed as fuel weight (lb) -- the practical, volume-limited figure the
%   tanks are specified by -- so it compares directly with mission fuel burn.

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
capProp     = profileName + ".FuelTank.FuelCapacity_lb";

thisDir = fileparts(mfilename("fullpath"));
addpath(fullfile(thisDir, "physical"));
m = systemcomposer.loadModel(modelName);

fuelSys = lookup(m, Path="F16A_Physical/Aircraft/FuelSystem");
tanks = fuelSys.Architecture.Components;

names = strings(numel(tanks),1);
cap   = zeros(numel(tanks),1);
for i = 1:numel(tanks)
    names(i) = string(tanks(i).Name);
    cap(i)   = str2double(string(getProperty(tanks(i), char(capProp))));
end
total = sum(cap);

T = table(names, cap, 'VariableNames', {'Tank','FuelCapacity_lb'});
results = struct(AvailableFuel_lb = total, Table = T);

fprintf("\n=== F-16A available fuel capacity roll-up ===\n");
disp(T);
fprintf("Total available internal fuel: %.0f lb\n", total);

end
