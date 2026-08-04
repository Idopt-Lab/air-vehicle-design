function results = F16APhysicalFuelRollup()
%F16APHYSICALFUELROLLUP Roll up the total available internal fuel capacity.
%   RESULTS = F16APHYSICALFUELROLLUP() sums the FuelCapacity_lb of every part
%   under the FuelSystem role that CARRIES a FuelTank stereotype, giving the
%   total available internal fuel capacity for the aircraft.
%
%   RESULTS fields: AvailableFuel_lb (total), Table (per-tank capacity).
%
%   This is the "available" side of REQ_F16A_P01 (fuel volume sufficiency).
%   The "required" side comes from a mission-analysis function
%   (F16APhysicalMissionFuel); the verify test compares the two. Capacity is
%   expressed as fuel weight (lb) -- the practical, volume-limited figure the
%   tanks are specified by -- so it compares directly with mission fuel burn.
%
%   IT ASKS THE MODEL WHICH PARTS HOLD FUEL, IT DOES NOT ASSUME (D-038).
%   The walk used to take every child of FuelSystem and read FuelCapacity_lb
%   off it with no stereotype check, which had two failure modes: a non-tank
%   child (a pump, a manifold) would have been read as a tank, and a variant
%   FuelSystem would have contributed nothing at all -- silently, as a 0 that
%   looks like an answer. Both are removed by the same rule the materials
%   roll-up already uses: a component that carries FuelTank IS a fuel leaf.
%
%   See also F16APHYSICALMATERIALSROLLUP, F16APHYSICALMASSROLLUP.

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
capProp     = profileName + ".FuelTank.FuelCapacity_lb";

thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
addpath(fullfile(thisDir, "physical"));
m = systemcomposer.loadModel(modelName);

fuelSys = lookup(m, Path="F16A_Physical/Aircraft/FuelSystem");
[names, cap] = fuelLeaves(fuelSys, capProp);

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

% =====================================================================
function [names, cap] = fuelLeaves(comp, capProp)
%FUELLEAVES Every part at or under COMP that carries a FuelTank stereotype.
%   Returns column vectors of name and FuelCapacity_lb. The rule is "a
%   component that carries FuelTank IS a fuel leaf" -- it is not descended into
%   further -- so a lumped tank stating one whole-block capacity and a
%   decomposed tank group stating one per cell are both handled by the same
%   walk, with no list of names anywhere.
%
%   Variant-safe on both counts that matter (Stage-0 findings 2 and 6): a
%   VariantComponent is replaced by its ACTIVE choice, never expanded into all
%   of them, and its children are never reached through .Architecture
%   .Components (which returns zero on a saved-and-reloaded model).
names = strings(0,1);
cap   = zeros(0,1);

if isa(comp, "systemcomposer.arch.VariantComponent")
    [names, cap] = fuelLeaves(getActiveChoice(comp), capProp);
    return;
end

% getStereotypes returns a cell array of '<profile>.<stereotype>'.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, ".FuelTank"))
    names = string(comp.Name);
    cap   = str2double(string(getProperty(comp, char(capProp))));
    return;
end

for k = comp.Architecture.Components
    [n, c] = fuelLeaves(k, capProp);
    names = [names; n];   %#ok<AGROW>
    cap   = [cap;   c];   %#ok<AGROW>
end
end
