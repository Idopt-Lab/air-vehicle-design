function results = F16APhysicalMaterialsRollup()
%F16APHYSICALMATERIALSROLLUP Roll up the composite material fraction of the airframe.
%   RESULTS = F16APHYSICALMATERIALSROLLUP() computes the mass-weighted
%   composite fraction of the active airframe candidate. The equation is
%   sum(Mass_lb .* CompositeFraction) / sum(Mass_lb), over the parts that
%   have a Material stereotype.
%
%   RESULTS fields: CompositeFraction (0..1), CompositeMass_lb, AirframeMass_lb,
%   ActiveCandidate, Table (per-part mass, fraction, composite mass).
%   It prints each number that it reads and each product that it calculates.
%   It also prints the plain average next to the weighted average, so that
%   you can see the effect of "mass-weighted".
%
%   This value supports REQ_F16A_022 (composite fraction <= 20%). OEW and cost
%   are Measures of Merit to minimize. This value is different: it is a
%   constraint, so a verification test (F16AMaterialsVerificationTest) checks
%   it.
%
%   See also F16APHYSICALFUELROLLUP, F16APHYSICALMASSROLLUP.

% ---------------------------------------------------------------------
% THE SUBJECT OF THIS ROLL-UP: five names and the cap. The rest of the file goes through the tree.
% ---------------------------------------------------------------------
MODEL      = "F16A_Physical";
STARTAT    = "F16A_Physical/Aircraft/Airframe";                 % the airframe role
STEREOTYPE = "Material";                                        % the stereotype of a part that declares a material
MASSPROP   = "F16A_PhysicalProps.PhysicalItem.Mass_lb";
CFPROP     = "F16A_PhysicalProps.Material.CompositeFraction";
CAP        = 0.20;                                              % the upper bound of REQ_F16A_022

fprintf("\n==========================================================\n");
fprintf("  AIRFRAME MATERIALS ROLL-UP\n");
fprintf("  Question: what fraction of the airframe is composite?\n");
fprintf("  Supports: REQ_F16A_022 (cap %.0f%%)\n", 100*CAP);
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

m = systemcomposer.loadModel(MODEL);

fprintf("  Model     : %s\n", MODEL);
fprintf("  Start at  : %s\n", STARTAT);
fprintf("  Properties: %s\n            : %s\n", MASSPROP, CFPROP);

% =====================================================================
% STEP 2 -- WHICH AIRFRAME?
%
% The airframe is a variant role with two candidates. Thus the question "what
% fraction of the airframe is composite" has no answer until the model gives
% the airframe. Get the airframe from the model. Do not assume it.
% =====================================================================
fprintf("\n[STEP 2] WHICH AIRFRAME?\n");

airframe = lookup(m, Path=char(STARTAT));
if isa(airframe, "systemcomposer.arch.VariantComponent")
    candidate = getActiveChoice(airframe);
    others    = arrayfun(@(c) string(c.Name), getChoices(airframe));
    others    = others(others ~= string(candidate.Name));
    fprintf("  %s is a variant role with %d candidates.\n", STARTAT, numel(others) + 1);
    fprintf("  Active   : %s  <- this candidate is measured\n", string(candidate.Name));
    fprintf("  Rejected : %s  (its parts are NOT counted below)\n", strjoin(others, ", "));
else
    candidate = airframe;   % also accept an airframe that is not a variant
    fprintf("  %s is a plain component, not a variant. Measuring it directly.\n", STARTAT);
end

% =====================================================================
% STEP 3 -- FIND THE PARTS THAT DECLARE A MATERIAL
% =====================================================================
fprintf("\n[STEP 3] FIND THE PARTS THAT DECLARE A MATERIAL\n");
fprintf("  Question to each part below %s: do you have a %s stereotype?\n\n", ...
    string(candidate.Name), STEREOTYPE);

[names, mass, cf] = findMaterialParts(candidate, 0, STEREOTYPE, MASSPROP, CFPROP);

fprintf("\n  -> %d part(s) answered yes.\n", numel(names));

% If there are no parts, or if a number cannot be read, there is no value to
% check REQ_F16A_022 against. This is not a value of zero.
if isempty(names)
    error("F16APhysicalMaterialsRollup:noMaterialParts", ...
        "No part under the active airframe candidate %s has a Material " + ...
        "stereotype. Thus REQ_F16A_022 cannot be evaluated for this candidate.", ...
        string(candidate.Name));
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
% This is the only roll-up that is not a plain sum. A heavy metal part
% decreases the fraction more than a light composite part increases it. Thus
% the fraction of each part counts in proportion to its mass.
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

% The reason that the two averages are different comes from the data. Thus
% the text stays true when a mass changes.
fprintf("  The plain average of the %d fractions, without mass, would be %.4f.\n", ...
    numel(cf), mean(cf));
if numel(names) >= 2
    [~, heaviest] = sort(mass, "descend");
    top2 = heaviest(1:2);
    fprintf("  They are different because %s and %s together have %.0f%% of the airframe\n", ...
        names(top2(1)), names(top2(2)), 100*sum(mass(top2))/totalMass);
    fprintf("  mass, with only %.0f%% and %.0f%% composite. The parts that are mostly\n", ...
        100*cf(top2(1)), 100*cf(top2(2)));
    fprintf("  composite are light. This is the purpose of weighting by mass.\n");
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
fprintf("  Read this carefully. It shows that the roll-up and the constraint check work.\n");
fprintf("  It is NOT evidence about the real F-16A, whose airframe has almost no\n");
fprintf("  composite. The fractions are teaching estimates (D-030).\n\n");

end

% =====================================================================
function [names, mass, cf] = findMaterialParts(comp, depth, stereotype, massProp, cfProp)
%FINDMATERIALPARTS Find the parts at or under COMP that have the Material stereotype.
%   It prints each part that it examines. A part with the stereotype is a
%   leaf, and the search does not go into it. Thus a lumped part with one
%   value for the whole block, and a decomposed group with one value for each
%   cell, use the same search.
names  = strings(0,1);
mass   = zeros(0,1);
cf     = zeros(0,1);
indent = repmat(' ', 1, 4 + 2*depth);

% Replace a variant role with its active choice. Never expand it into all of
% its choices. If you do, the parts of a rejected candidate are counted.
if isa(comp, "systemcomposer.arch.VariantComponent")
    active = getActiveChoice(comp);
    fprintf("%s%-20s variant role. Following the active choice, %s\n", ...
        indent, string(comp.Name), string(active.Name));
    [names, mass, cf] = findMaterialParts(active, depth, stereotype, massProp, cfProp);
    return
end

% getStereotypes returns '<profile>.<stereotype>', so compare the end of the text.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, "." + stereotype))
    names = string(comp.Name);
    mass  = str2double(string(getProperty(comp, char(massProp))));
    cf    = str2double(string(getProperty(comp, char(cfProp))));
    fprintf("%s%-20s YES. %8.2f lb, %.0f%% composite\n", ...
        indent, string(comp.Name), mass, 100*cf);
    return
end

kids = comp.Architecture.Components;
fprintf("%s%-20s no %s stereotype. Looking inside its %d part(s)\n", ...
    indent, string(comp.Name), stereotype, numel(kids));
for k = kids
    [n, mm, cc] = findMaterialParts(k, depth + 1, stereotype, massProp, cfProp);
    names = [names; n];    %#ok<AGROW>
    mass  = [mass;  mm];   %#ok<AGROW>
    cf    = [cf;    cc];   %#ok<AGROW>
end
end
