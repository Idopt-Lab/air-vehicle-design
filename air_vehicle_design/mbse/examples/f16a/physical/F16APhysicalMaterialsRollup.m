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
%   This backs REQ_F16A_022 (airframe composite fraction <= 20%). Unlike OEW
%   and cost -- Measures of Merit to minimize -- this is a CONSTRAINT with an
%   upper bound, so it is checked by a "verified by" test.
%
%   IT FOLLOWS THE ACTIVE CANDIDATE, IT DOES NOT ASSUME ONE. Airframe is a
%   variant role holding two candidates (D-003), so the question is only
%   answerable once the model says which airframe. The walk itself is
%   F16AStereotypeLeaves.
%
%   See also F16ASTEREOTYPELEAVES, F16APHYSICALFUELROLLUP.

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
massProp    = profileName + ".PhysicalItem.Mass_lb";
cfProp      = profileName + ".Material.CompositeFraction";

thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
addpath(fullfile(thisDir, "physical"));
m = systemcomposer.loadModel(modelName);

% The airframe ROLE. If it is a variant, the figure belongs to whichever
% candidate is active -- ask the model which one rather than assuming.
airframe = lookup(m, Path="F16A_Physical/Aircraft/Airframe");
if isa(airframe, "systemcomposer.arch.VariantComponent")
    candidate = getActiveChoice(airframe);
else
    candidate = airframe;   % tolerate a non-variant airframe
end

[names, vals] = F16AStereotypeLeaves(candidate, "Material", [massProp, cfProp]);
mass = vals(:,1);
cf   = vals(:,2);

% Same rule as the fuel roll-up: no parts, or a part whose numbers cannot be
% read, means REQ_F16A_022 has no value to check -- not a value of zero and
% not a NaN that the verify test would compare against the cap as if it were
% an answer.
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

compMass  = mass .* cf;
totalMass = sum(mass);
fraction  = sum(compMass) / totalMass;

T = table(names, mass, cf, compMass, ...
    'VariableNames', {'Part','Mass_lb','CompositeFraction','CompositeMass_lb'});

results = struct( ...
    CompositeFraction = fraction, ...
    CompositeMass_lb  = sum(compMass), ...
    AirframeMass_lb   = totalMass, ...
    ActiveCandidate   = string(candidate.Name), ...
    Table = T);

fprintf("\n=== F-16A airframe materials roll-up (active candidate: %s) ===\n", ...
    string(candidate.Name));
disp(T);
fprintf("Airframe composite fraction: %.4f (%.1f%%)  [REQ_F16A_022 cap: 20%%]\n", ...
    fraction, 100*fraction);

end
