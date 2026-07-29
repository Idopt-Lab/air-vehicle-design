function results = F16APhysicalMaterialsRollup()
%F16APHYSICALMATERIALSROLLUP Roll up the airframe composite material fraction.
%   RESULTS = F16APHYSICALMATERIALSROLLUP() computes the MASS-WEIGHTED
%   composite fraction of the ACTIVE airframe candidate -- a roll-up over the
%   parts that carry a Material stereotype of each part's CompositeFraction
%   weighted by its Mass_lb:
%
%       CompositeFraction_airframe = sum(Mass_lb .* CompositeFraction)
%                                    -----------------------------------
%                                            sum(Mass_lb)
%
%   RESULTS fields: CompositeFraction (0..1), CompositeMass_lb, AirframeMass_lb,
%   ActiveCandidate (the airframe candidate the figure describes), Table
%   (per-part mass, composite fraction, composite mass).
%
%   This backs REQ_F16A_022 (airframe composite fraction <= 20%). Unlike OEW
%   and cost -- which are Measures of Merit to minimize -- the material
%   fraction is a genuine design CONSTRAINT with an upper bound, so it is
%   checked with a "verified by" test (F16AMaterialsVerificationTest).
%
%   IT FOLLOWS THE ACTIVE CANDIDATE, IT DOES NOT ASSUME ONE.
%   Airframe is a VARIANT role holding two candidates (D-003), so "the
%   airframe's composite fraction" is only a question you can answer once you
%   say which airframe. This function asks the model: it takes the variant's
%   ACTIVE choice and walks that candidate's subtree. Two consequences worth
%   understanding before changing anything here:
%     * It walks the ARCHITECTURE, not an analysis instance, so it must descend
%       through getActiveChoice at a variant component. A plain recursion would
%       average BOTH candidates together and produce a number describing no
%       aircraft at all (D-012 / Stage-0 finding 2).
%     * It no longer hard-codes the six structural part names. That list was
%       only ever valid for one candidate; the lumped ConventionalTrapWing has
%       no parts, and a future candidate might have a different set. The rule
%       is now structural: sum every leaf under the active candidate that
%       CARRIES a Material stereotype, whatever and however many they are.
%
%   With BlendedCrankedDelta active the answer is 0.1928 over its six Brandt
%   structural parts. With ConventionalTrapWing active it is that candidate's
%   single whole-block value, 0.12 -- an Estimate, so the constraint stays
%   DEFINED on either branch of the trade rather than becoming unanswerable the
%   moment the decision goes the other way.
%
%   Per-part CompositeFraction values are an educated-guess split (set in
%   generate_f16a_physical.m) grounded in real F-16 composite usage: the
%   vertical- and horizontal-tail skins are graphite/epoxy, the wing leading
%   edge is a carbon-fiber laminate, the strakes/ventral use fiberglass, and
%   the fuselage/nacelles are largely aluminum. They mass-weight to ~0.19,
%   within (and close to) the 20% cap in the Brandt reference material mix.

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

[names, mass, cf] = materialLeaves(candidate, massProp, cfProp);
if isempty(names)
    error("F16APhysicalMaterialsRollup:noMaterialParts", ...
        "No part under the active airframe candidate %s carries a Material " + ...
        "stereotype -- REQ_F16A_022 cannot be evaluated for it.", string(candidate.Name));
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

% =====================================================================
function [names, mass, cf] = materialLeaves(comp, massProp, cfProp)
%MATERIALLEAVES Every part at or under COMP that carries a Material stereotype.
%   Returns column vectors of name, Mass_lb and CompositeFraction. The rule is
%   "a component that carries Material IS a material leaf" -- it is not
%   descended into further -- so a lumped candidate that states one whole-block
%   fraction and a decomposed candidate that states one per structural part are
%   both handled by the same walk, with no list of names anywhere.
%
%   Variant-safe on both counts that matter (Stage-0 findings 2 and 6): a
%   VariantComponent is replaced by its ACTIVE choice, never expanded into all
%   of them, and its children are never reached through .Architecture
%   .Components (which returns zero on a saved-and-reloaded model).
names = strings(0,1);
mass  = zeros(0,1);
cf    = zeros(0,1);

if isa(comp, "systemcomposer.arch.VariantComponent")
    [names, mass, cf] = materialLeaves(getActiveChoice(comp), massProp, cfProp);
    return;
end

% getStereotypes returns a cell array of '<profile>.<stereotype>'.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, ".Material"))
    names = string(comp.Name);
    mass  = str2double(string(getProperty(comp, char(massProp))));
    cf    = str2double(string(getProperty(comp, char(cfProp))));
    return;
end

for k = comp.Architecture.Components
    [n, mss, c] = materialLeaves(k, massProp, cfProp);
    names = [names; n];    %#ok<AGROW>
    mass  = [mass;  mss];  %#ok<AGROW>
    cf    = [cf;    c];    %#ok<AGROW>
end
end
