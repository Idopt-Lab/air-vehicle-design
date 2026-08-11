function results = F16APhysicalFuelRollup()
%F16APHYSICALFUELROLLUP Add up the total available internal fuel capacity.
%   RESULTS = F16APHYSICALFUELROLLUP() adds FuelCapacity_lb over every part
%   under the FuelSystem role that CARRIES a FuelTank stereotype.
%
%   RESULTS fields: AvailableFuel_lb (total), Table (per-tank capacity).
%
%   It runs as four printed steps -- open the model, find the parts that hold
%   fuel, add them up, report -- and prints every capacity it reads and the
%   running total, so a reader can add the tanks up by hand and check it.
%
%   This is the "available" side of REQ_F16A_P01. The "required" side comes
%   from F16APhysicalMissionFuel, and the verify test compares the two.
%   Capacity is expressed as fuel WEIGHT (lb) so it compares directly with
%   mission fuel burn (D-041) -- which since D-059 is a real number.
%
%   It asks the model which parts hold fuel instead of assuming a list of
%   names (D-038). The walk is at the bottom of this file, on purpose: this
%   file is meant to be read straight through (D-057).
%
%   See also F16APHYSICALMATERIALSROLLUP, F16APHYSICALMASSROLLUP.

% ---------------------------------------------------------------------
% WHAT THIS ROLL-UP IS ABOUT. Three names; the rest of the file is the walk.
% ---------------------------------------------------------------------
MODEL      = "F16A_Physical";
STARTAT    = "F16A_Physical/Aircraft/FuelSystem";              % where the walk begins
STEREOTYPE = "FuelTank";                                       % what marks a part as holding fuel
CAPPROP    = "F16A_PhysicalProps.FuelTank.FuelCapacity_lb";    % what those parts carry

fprintf("\n==========================================================\n");
fprintf("  AVAILABLE FUEL ROLL-UP\n");
fprintf("  Question: how much fuel can this aeroplane carry?\n");
fprintf("  Backs: REQ_F16A_P01 (the 'available' side)\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

root = f16aRoot();   % the example root, via the anchor file
addpath(fullfile(root, "physical"));
m = systemcomposer.loadModel(MODEL);

fuelSys = lookup(m, Path=char(STARTAT));
fprintf("  Model     : %s\n", MODEL);
fprintf("  Start at  : %s\n", STARTAT);
fprintf("  Property  : %s\n", CAPPROP);

% =====================================================================
% STEP 2 -- FIND THE PARTS THAT HOLD FUEL
%
% Nothing here knows a tank's name. Each part is asked whether it carries the
% FuelTank stereotype; the ones that say yes are the tanks. Add a fourth tank
% to the generator and it is counted on the next run without editing this file
% (D-038).
% =====================================================================
fprintf("\n[STEP 2] FIND THE PARTS THAT HOLD FUEL\n");
fprintf("  Asking every part below %s: do you carry a %s stereotype?\n\n", ...
    string(fuelSys.Name), STEREOTYPE);

[names, cap] = findFuelTanks(fuelSys, 0, STEREOTYPE, CAPPROP);

fprintf("\n  -> %d part(s) answered yes.\n", numel(names));

% A silent 0 is the failure D-038 removed, and it must not come back in either
% of its two disguises: an empty walk, or an unreadable capacity that sums to
% NaN. Both mean REQ_F16A_P01's available side has no value, and a NaN would
% travel into the verify test and be compared as if it were one (D-054).
if isempty(names)
    error("F16APhysicalFuelRollup:noFuelTanks", ...
        "No part under %s carries a FuelTank stereotype -- the available-fuel " + ...
        "side of REQ_F16A_P01 cannot be evaluated.", string(fuelSys.Name));
end
if any(~isfinite(cap))
    error("F16APhysicalFuelRollup:unreadableCapacity", ...
        "FuelCapacity_lb is not a readable number on: %s. The available-fuel " + ...
        "side of REQ_F16A_P01 cannot be evaluated.", strjoin(names(~isfinite(cap)), ", "));
end

% =====================================================================
% STEP 3 -- ADD THEM UP
% =====================================================================
fprintf("\n[STEP 3] ADD THEM UP\n");
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
fprintf("  This is a plain SUM: tanks do not interact, so capacity simply adds.\n\n");
fprintf("  It is only half of REQ_F16A_P01. The other half -- how much fuel the\n");
fprintf("  mission REQUIRES -- comes from F16APhysicalMissionFuel, which reads the\n");
fprintf("  mission the /sizing/ analysis flew into this model (D-059). The two are\n");
fprintf("  compared by F16AFuelVerificationTest, which passes: the tanks hold more\n");
fprintf("  than the mission burns.\n\n");

end

% =====================================================================
function [names, cap] = findFuelTanks(comp, depth, stereotype, capProp)
%FINDFUELTANKS Parts at or under COMP that carry the FuelTank stereotype.
%   Prints each part it looks at. A part carrying the stereotype IS a tank and
%   is not descended into, so one lumped tank and a group of cells both work
%   without a list of names anywhere.
names  = strings(0,1);
cap    = zeros(0,1);
indent = repmat(' ', 1, 4 + 2*depth);

% A variant role is replaced by its ACTIVE choice, never expanded into all of
% them -- otherwise a rejected candidate's tanks would be counted. Its children
% are never reached through .Architecture.Components, which returns zero on a
% saved-and-reloaded model.
if isa(comp, "systemcomposer.arch.VariantComponent")
    active = getActiveChoice(comp);
    fprintf("%s%-24s variant role -- following the active choice, %s\n", ...
        indent, string(comp.Name), string(active.Name));
    [names, cap] = findFuelTanks(active, depth, stereotype, capProp);
    return
end

% getStereotypes returns '<profile>.<stereotype>', so compare on the tail.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, "." + stereotype))
    names = string(comp.Name);
    cap   = str2double(string(getProperty(comp, char(capProp))));
    fprintf("%s%-24s YES -- holds %.0f lb of fuel\n", indent, string(comp.Name), cap);
    return
end

kids = comp.Architecture.Components;
fprintf("%s%-24s no %s stereotype, looking inside its %d part(s)\n", ...
    indent, string(comp.Name), stereotype, numel(kids));
for k = kids
    [n, c] = findFuelTanks(k, depth + 1, stereotype, capProp);
    names  = [names; n];   %#ok<AGROW>
    cap    = [cap;   c];   %#ok<AGROW>
end
end
