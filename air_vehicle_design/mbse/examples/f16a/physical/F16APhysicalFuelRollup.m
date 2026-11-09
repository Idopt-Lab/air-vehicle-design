function results = F16APhysicalFuelRollup()
%F16APHYSICALFUELROLLUP Add the tank capacities to get the total available internal fuel.
%   RESULTS = F16APHYSICALFUELROLLUP() adds FuelCapacity_lb over each part
%   under the FuelSystem role that has a FuelTank stereotype.
%
%   RESULTS fields: AvailableFuel_lb (total), Table (per-tank capacity).
%
%   It prints each capacity that it reads and the running total, so that you
%   can add the tanks by hand.
%
%   This value is the "available" side of REQ_F16A_P01. The "required" side
%   comes from F16APhysicalMissionFuel. F16AFuelVerificationTest compares the
%   two sides. Capacity is a fuel weight (lb), so you can compare it directly
%   with fuel burn.
%
%   See also F16APHYSICALMATERIALSROLLUP, F16APHYSICALMASSROLLUP.

% ---------------------------------------------------------------------
% THE SUBJECT OF THIS ROLL-UP: four names. The rest of the file goes through the tree.
% ---------------------------------------------------------------------
MODEL      = "F16A_Physical";
STARTAT    = "F16A_Physical/Aircraft/FuelSystem";              % where the search starts
STEREOTYPE = "FuelTank";                                       % the stereotype of a part that holds fuel
CAPPROP    = "F16A_PhysicalProps.FuelTank.FuelCapacity_lb";    % the property of those parts

fprintf("\n==========================================================\n");
fprintf("  AVAILABLE FUEL ROLL-UP\n");
fprintf("  Question: how much fuel can this aeroplane carry?\n");
fprintf("  Supports: REQ_F16A_P01 (the 'available' side)\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

m = systemcomposer.loadModel(MODEL);

fuelSys = lookup(m, Path=char(STARTAT));
fprintf("  Model     : %s\n", MODEL);
fprintf("  Start at  : %s\n", STARTAT);
fprintf("  Property  : %s\n", CAPPROP);

% =====================================================================
% STEP 2 -- FIND THE PARTS THAT HOLD FUEL
%
% This code does not know the name of a tank. It asks each part if it has the
% FuelTank stereotype. The parts that have it are the tanks. If you add a
% fourth tank to the model, the next run counts it, and you do not have to
% edit this file.
% =====================================================================
fprintf("\n[STEP 2] FIND THE PARTS THAT HOLD FUEL\n");
fprintf("  Question to each part below %s: do you have a %s stereotype?\n\n", ...
    string(fuelSys.Name), STEREOTYPE);

[names, cap] = findFuelTanks(fuelSys, 0, STEREOTYPE, CAPPROP);

fprintf("\n  -> %d part(s) answered yes.\n", numel(names));

% If there are no tanks, or if a capacity cannot be read, there is no
% available side to check REQ_F16A_P01 against. This is not an available side
% of zero.
if isempty(names)
    error("F16APhysicalFuelRollup:noFuelTanks", ...
        "No part under %s has a FuelTank stereotype. Thus the available-fuel " + ...
        "side of REQ_F16A_P01 cannot be evaluated.", string(fuelSys.Name));
end
if any(~isfinite(cap))
    error("F16APhysicalFuelRollup:unreadableCapacity", ...
        "FuelCapacity_lb is not a readable number on: %s. The available-fuel " + ...
        "side of REQ_F16A_P01 cannot be evaluated.", strjoin(names(~isfinite(cap)), ", "));
end

% =====================================================================
% STEP 3 -- ADD THE CAPACITIES
% =====================================================================
fprintf("\n[STEP 3] ADD THE CAPACITIES\n");
total = 0;
for i = 1:numel(names)
    total = total + cap(i);
    fprintf("  %s + %7.0f  =  %7.0f lb\n", ...
        pad(names(i) + " ", 22, "right", "."), cap(i), total);
end

T = table(names, cap, 'VariableNames', {'Tank','FuelCapacity_lb'});
results = struct(AvailableFuel_lb = total, Table = T);

% =====================================================================
% STEP 4 -- REPORT
% =====================================================================
fprintf("\n[STEP 4] REPORT\n");
fprintf("  Total available internal fuel: %.0f lb, in %d tanks.\n", total, numel(names));
fprintf("  This is a plain SUM. The tanks do not interact, so their capacities add.\n\n");
fprintf("  This is only half of REQ_F16A_P01. The other half is the fuel that the\n");
fprintf("  mission requires. It comes from F16APhysicalMissionFuel, which reads the\n");
fprintf("  mission that the /sizing/ analysis wrote into this model.\n");
fprintf("  F16AFuelVerificationTest compares the two halves.\n\n");

end

% =====================================================================
function [names, cap] = findFuelTanks(comp, depth, stereotype, capProp)
%FINDFUELTANKS Find the parts at or under COMP that have the FuelTank stereotype.
%   It prints each part that it examines. A part with the stereotype is a
%   tank, and the search does not go into it. Thus one lumped tank and a
%   group of cells both operate correctly, without a list of names.
names  = strings(0,1);
cap    = zeros(0,1);
indent = repmat(' ', 1, 4 + 2*depth);

% Replace a variant role with its active choice. Never expand it into all of
% its choices. If you do, the tanks of a rejected candidate are counted.
if isa(comp, "systemcomposer.arch.VariantComponent")
    active = getActiveChoice(comp);
    fprintf("%s%-24s variant role. Following the active choice, %s\n", ...
        indent, string(comp.Name), string(active.Name));
    [names, cap] = findFuelTanks(active, depth, stereotype, capProp);
    return
end

% getStereotypes returns '<profile>.<stereotype>', so compare the end of the text.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, "." + stereotype))
    names = string(comp.Name);
    cap   = str2double(string(getProperty(comp, char(capProp))));
    fprintf("%s%-24s YES. Holds %.0f lb of fuel\n", indent, string(comp.Name), cap);
    return
end

kids = comp.Architecture.Components;
fprintf("%s%-24s no %s stereotype. Looking inside its %d part(s)\n", ...
    indent, string(comp.Name), stereotype, numel(kids));
for k = kids
    [n, c] = findFuelTanks(k, depth + 1, stereotype, capProp);
    names  = [names; n];   %#ok<AGROW>
    cap    = [cap;   c];   %#ok<AGROW>
end
end
