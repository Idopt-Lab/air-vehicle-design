function results = F16APhysicalMaterialsRollup()
%F16APHYSICALMATERIALSROLLUP Roll up the airframe composite material fraction.
%   RESULTS = F16APHYSICALMATERIALSROLLUP() computes the MASS-WEIGHTED
%   composite fraction of the airframe structure -- a roll-up over the
%   airframe parts of each part's CompositeFraction weighted by its Mass_lb:
%
%       CompositeFraction_airframe = sum(Mass_lb .* CompositeFraction)
%                                    -----------------------------------
%                                            sum(Mass_lb)
%
%   RESULTS fields: CompositeFraction (0..1), CompositeMass_lb, AirframeMass_lb,
%   Table (per-part mass, composite fraction, composite mass).
%
%   This backs REQ_F16A_022 (airframe composite fraction <= 20%). Unlike OEW
%   and cost -- which are Measures of Merit to minimize -- the material
%   fraction is a genuine design CONSTRAINT with an upper bound, so it is
%   checked with a "verified by" test (F16AMaterialsVerificationTest).
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

thisDir = fileparts(mfilename("fullpath"));
addpath(fullfile(thisDir, "physical"));
m = systemcomposer.loadModel(modelName);

AF = "F16A_Physical/Aircraft/Airframe/";
parts = ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"];

mass = zeros(numel(parts),1);
cf   = zeros(numel(parts),1);
for i = 1:numel(parts)
    c = lookup(m, Path=char(AF + parts(i)));
    mass(i) = str2double(string(getProperty(c, char(massProp))));
    cf(i)   = str2double(string(getProperty(c, char(cfProp))));
end
compMass  = mass .* cf;
totalMass = sum(mass);
fraction  = sum(compMass) / totalMass;

T = table(parts(:), mass, cf, compMass, ...
    'VariableNames', {'Part','Mass_lb','CompositeFraction','CompositeMass_lb'});

results = struct( ...
    CompositeFraction = fraction, ...
    CompositeMass_lb  = sum(compMass), ...
    AirframeMass_lb   = totalMass, ...
    Table = T);

fprintf("\n=== F-16A airframe materials roll-up ===\n");
disp(T);
fprintf("Airframe composite fraction: %.4f (%.1f%%)  [REQ_F16A_022 cap: 20%%]\n", ...
    fraction, 100*fraction);

end
