function results = F16APhysicalMaterialsRollup()
%F16APHYSICALMATERIALSROLLUP Roll up the airframe composite material fraction.
%   RESULTS = F16APHYSICALMATERIALSROLLUP() computes the MASS-WEIGHTED
%   composite fraction of the ACTIVE airframe candidate --
%   sum(Mass_lb .* CompositeFraction) / sum(Mass_lb) over the parts carrying a
%   Material stereotype.
%
%   RESULTS fields: CompositeFraction (0..1), CompositeMass_lb, AirframeMass_lb,
%   ActiveCandidate, Table (per-part mass, fraction, composite mass).
%
%   It runs as five printed steps and prints every number it reads and every
%   product it forms, including the plain unweighted average alongside the
%   weighted one, so a reader can see what "mass-weighted" bought.
%
%   This backs REQ_F16A_022 (airframe composite fraction <= 20%). Unlike OEW
%   and cost -- Measures of Merit to minimize -- this is a CONSTRAINT with an
%   upper bound, so it is checked by a "verified by" test.
%
%   IT FOLLOWS THE ACTIVE CANDIDATE, IT DOES NOT ASSUME ONE (D-003). The walk
%   is at the bottom of this file, on purpose (D-057).
%
%   See also F16APHYSICALFUELROLLUP, F16APHYSICALMASSROLLUP.

% ---------------------------------------------------------------------
% WHAT THIS ROLL-UP IS ABOUT. Four names; the rest of the file is the walk.
% ---------------------------------------------------------------------
MODEL      = "F16A_Physical";
STARTAT    = "F16A_Physical/Aircraft/Airframe";                 % the airframe ROLE
STEREOTYPE = "Material";                                        % what marks a part as declaring one
MASSPROP   = "F16A_PhysicalProps.PhysicalItem.Mass_lb";
CFPROP     = "F16A_PhysicalProps.Material.CompositeFraction";
CAP        = 0.20;                                              % REQ_F16A_022's upper bound

fprintf("\n==========================================================\n");
fprintf("  AIRFRAME MATERIALS ROLL-UP\n");
fprintf("  Question: what fraction of the airframe is composite?\n");
fprintf("  Backs: REQ_F16A_022 (cap %.0f%%)\n", 100*CAP);
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

root = f16aRoot();   % the example root, via the anchor file
addpath(fullfile(root, "physical"));
m = systemcomposer.loadModel(MODEL);

fprintf("  Model     : %s\n", MODEL);
fprintf("  Start at  : %s\n", STARTAT);
fprintf("  Properties: %s\n            : %s\n", MASSPROP, CFPROP);

% =====================================================================
% STEP 2 -- WHICH AIRFRAME?
%
% The airframe is a variant role holding two candidates, so "what fraction of
% the airframe is composite" has no answer until the model says which airframe.
% Ask it rather than assuming.
% =====================================================================
fprintf("\n[STEP 2] WHICH AIRFRAME?\n");

airframe = lookup(m, Path=char(STARTAT));
if isa(airframe, "systemcomposer.arch.VariantComponent")
    candidate = getActiveChoice(airframe);
    others    = arrayfun(@(c) string(c.Name), getChoices(airframe));
    others    = others(others ~= string(candidate.Name));
    fprintf("  %s is a variant role with %d candidates.\n", STARTAT, numel(others) + 1);
    fprintf("  Active   : %s  <- this is the one measured\n", string(candidate.Name));
    fprintf("  Rejected : %s  (its parts are NOT counted below)\n", strjoin(others, ", "));
else
    candidate = airframe;   % tolerate a non-variant airframe
    fprintf("  %s is a plain component, not a variant. Measuring it directly.\n", STARTAT);
end

% =====================================================================
% STEP 3 -- FIND THE PARTS THAT DECLARE A MATERIAL
% =====================================================================
fprintf("\n[STEP 3] FIND THE PARTS THAT DECLARE A MATERIAL\n");
fprintf("  Asking every part below %s: do you carry a %s stereotype?\n\n", ...
    string(candidate.Name), STEREOTYPE);

[names, mass, cf] = findMaterialParts(candidate, 0, STEREOTYPE, MASSPROP, CFPROP);

fprintf("\n  -> %d part(s) answered yes.\n", numel(names));

% Same rule as the fuel roll-up: no parts, or a part whose numbers cannot be
% read, means REQ_F16A_022 has no value to check -- not a value of zero and not
% a NaN the verify test would compare against the cap as if it were an answer
% (D-054).
if isempty(names)
    error("F16APhysicalMaterialsRollup:noMaterialParts", ...
        "No part under the active airframe candidate %s carries a Material " + ...
        "stereotype -- REQ_F16A_022 cannot be evaluated for it.", string(candidate.Name));
end
unreadable = ~isfinite(mass) | ~isfinite(cf);
if any(unreadable)
    error("F16APhysicalMaterialsRollup:unreadableProperty", ...
        "Mass_lb or CompositeFraction is not a readable number on: %s. " + ...
        "REQ_F16A_022 cannot be evaluated.", strjoin(names(unreadable), ", "));
end

% =====================================================================
% STEP 4 -- WEIGHT THE AVERAGE
%
% This is the one roll-up that is not a plain sum. A heavy part made of metal
% pulls the fraction down harder than a light part made of composite pulls it
% up, so each part's fraction counts in proportion to its mass.
% =====================================================================
fprintf("\n[STEP 4] WEIGHT THE AVERAGE BY MASS\n");
fprintf("  Each part contributes mass x fraction pounds of composite:\n\n");

compMass = mass .* cf;
runMass  = 0;
runComp  = 0;
for i = 1:numel(names)
    runMass = runMass + mass(i);
    runComp = runComp + compMass(i);
    fprintf("  %s %8.2f lb x %.2f = %7.2f lb composite   (running: %7.2f / %8.2f)\n", ...
        pad(names(i) + " ", 18, "right", "."), mass(i), cf(i), compMass(i), runComp, runMass);
end

totalMass = sum(mass);
fraction  = sum(compMass) / totalMass;

fprintf("\n  Composite mass / airframe mass = %.2f / %.2f = %.4f\n", ...
    sum(compMass), totalMass, fraction);

% The unweighted average printed beside the weighted one, and the reason they
% differ read off the data rather than asserted -- so the sentence cannot go
% stale when a mass changes.
fprintf("  The plain average of the %d fractions, ignoring mass, would be %.4f.\n", ...
    numel(cf), mean(cf));
if numel(names) >= 2
    [~, heaviest] = sort(mass, "descend");
    top2 = heaviest(1:2);
    fprintf("  They differ because %s and %s carry %.0f%% of the airframe mass\n", ...
        names(top2(1)), names(top2(2)), 100*sum(mass(top2))/totalMass);
    fprintf("  between them at only %.0f%% and %.0f%% composite, while the parts that are\n", ...
        100*cf(top2(1)), 100*cf(top2(2)));
    fprintf("  mostly composite are light. That is what weighting by mass is for.\n");
end

T = table(names, mass, cf, compMass, ...
    'VariableNames', {'Part','Mass_lb','CompositeFraction','CompositeMass_lb'});

results = struct( ...
    CompositeFraction = fraction, ...
    CompositeMass_lb  = sum(compMass), ...
    AirframeMass_lb   = totalMass, ...
    ActiveCandidate   = string(candidate.Name), ...
    Table = T);

% =====================================================================
% STEP 5 -- CHECK AGAINST REQ_F16A_022
% =====================================================================
fprintf("\n[STEP 5] CHECK AGAINST REQ_F16A_022\n");
fprintf("  Airframe composite fraction : %.4f  (%.2f%%)\n", fraction, 100*fraction);
fprintf("  REQ_F16A_022 cap            : %.4f  (%.0f%%)\n", CAP, 100*CAP);
if fraction <= CAP
    fprintf("  -> %.2f%% <= %.0f%%, so REQ_F16A_022 is MET.\n\n", 100*fraction, 100*CAP);
else
    fprintf("  -> %.2f%% > %.0f%%, so REQ_F16A_022 is NOT MET.\n\n", 100*fraction, 100*CAP);
end
fprintf("  Read that carefully: it shows the roll-up and the constraint check work.\n");
fprintf("  It is NOT evidence about the real F-16A, whose airframe is essentially not\n");
fprintf("  composite at all. The fractions are teaching estimates (D-030, D-031).\n\n");

end

% =====================================================================
function [names, mass, cf] = findMaterialParts(comp, depth, stereotype, massProp, cfProp)
%FINDMATERIALPARTS Parts at or under COMP that carry the Material stereotype.
%   Prints each part it looks at. A part carrying the stereotype IS a leaf and
%   is not descended into, so a lumped part stating one whole-block value and a
%   decomposed group stating one per cell use the same walk.
names  = strings(0,1);
mass   = zeros(0,1);
cf     = zeros(0,1);
indent = repmat(' ', 1, 4 + 2*depth);

% A variant role is replaced by its ACTIVE choice, never expanded into all of
% them -- otherwise a rejected candidate's parts would be counted. Its children
% are never reached through .Architecture.Components, which returns zero on a
% saved-and-reloaded model.
if isa(comp, "systemcomposer.arch.VariantComponent")
    active = getActiveChoice(comp);
    fprintf("%s%-20s variant role -- following the active choice, %s\n", ...
        indent, string(comp.Name), string(active.Name));
    [names, mass, cf] = findMaterialParts(active, depth, stereotype, massProp, cfProp);
    return
end

% getStereotypes returns '<profile>.<stereotype>', so compare on the tail.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, "." + stereotype))
    names = string(comp.Name);
    mass  = str2double(string(getProperty(comp, char(massProp))));
    cf    = str2double(string(getProperty(comp, char(cfProp))));
    fprintf("%s%-20s YES -- %8.2f lb, %.0f%% composite\n", ...
        indent, string(comp.Name), mass, 100*cf);
    return
end

kids = comp.Architecture.Components;
fprintf("%s%-20s no %s stereotype, looking inside its %d part(s)\n", ...
    indent, string(comp.Name), stereotype, numel(kids));
for k = kids
    [n, mm, cc] = findMaterialParts(k, depth + 1, stereotype, massProp, cfProp);
    names = [names; n];    %#ok<AGROW>
    mass  = [mass;  mm];   %#ok<AGROW>
    cf    = [cf;    cc];   %#ok<AGROW>
end
end
