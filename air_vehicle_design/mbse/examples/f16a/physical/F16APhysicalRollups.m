function results = F16APhysicalRollups(options)
%F16APHYSICALROLLUPS Run the three F-16A roll-up analyses.
%   RESULTS = F16APHYSICALROLLUPS() runs the mass, materials and fuel roll-ups
%   in turn and collects their results. Each of the three does its own work and
%   prints its own steps, so this file has nothing to add beyond the order and
%   a summary.
%
%   RESULTS is a struct with fields Mass, Materials and Fuel, each holding what
%   the corresponding roll-up returned.
%
%   It runs READ-ONLY by default: a reader running this to look at the numbers
%   should not re-save F16A_Physical.slx. Pass Persist=true to write the OEW
%   Measure of Merit, which is what generate_f16a_physical does when it calls
%   the three individually as its section 9.
%
%   The three are INDEPENDENT -- they measure different things and none feeds
%   another. Only two of them are sums; the materials one is a weighted average.
%
%   Read F16APhysicalMassRollup, F16APhysicalMaterialsRollup or
%   F16APhysicalFuelRollup to see how a roll-up actually works (D-057).

arguments
    % Write the OEW Measure of Merit and save. False here, unlike the mass
    % roll-up's own default: this runner exists for reading, not for building.
    options.Persist (1,1) logical = false
end

fprintf("\n##########################################################\n");
fprintf("  THE THREE F-16A ROLL-UP ANALYSES\n");
if options.Persist
    fprintf("  Mode: the OEW Measure of Merit WILL be written and saved\n");
else
    fprintf("  Mode: READ-ONLY -- nothing is written and nothing is saved\n");
end
fprintf("##########################################################\n");

mass      = F16APhysicalMassRollup(Persist=options.Persist);
materials = F16APhysicalMaterialsRollup();
fuel      = F16APhysicalFuelRollup();

results = struct(Mass = mass, Materials = materials, Fuel = fuel);

fprintf("\n########## THREE ANALYSES, THREE ANSWERS ##########\n");
fprintf("  Operating Empty Weight      : %9.2f lb   <- SUM over %d assemblies\n", ...
    mass.OEW, height(mass.Table));
fprintf("  Airframe composite fraction : %9.2f %%    <- mass-WEIGHTED AVERAGE over %d parts\n", ...
    100*materials.CompositeFraction, height(materials.Table));
fprintf("  Available internal fuel     : %9.2f lb   <- SUM over %d tanks\n", ...
    fuel.AvailableFuel_lb, height(fuel.Table));
fprintf("\n  Three roll-ups, and only two of them are sums. A composite fraction is a\n");
fprintf("  ratio, so it is averaged in proportion to mass -- adding fractions up would\n");
fprintf("  be meaningless. What rolls up depends on what the quantity is.\n\n");

end
