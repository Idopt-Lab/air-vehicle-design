function results = F16APhysicalMassRollup(options)
%F16APHYSICALMASSROLLUP Add the part masses up to the F-16A empty weight (OEW).
%   RESULTS = F16APHYSICALMASSROLLUP() builds a System Composer analysis
%   instance of physical/F16A_Physical.slx and adds Mass_lb up the tree --
%   children before parents -- to a subtotal at every assembly and a grand
%   total at the aircraft: the Operating Empty Weight. It writes OEW into the
%   aircraft's MeasureOfMerit.OEW_lb and saves.
%
%   RESULTS = F16APHYSICALMASSROLLUP(Persist=false) returns the same numbers
%   and WRITES NOTHING. Tests use it: a test may not re-save the artifact it
%   is asserting against (D-029).
%
%   RESULTS fields: OEW, Airframe, Propulsion, Engine, AirframeLessEngine,
%   Table (per-assembly subtotals).
%
%   It runs as six printed steps and prints every mass it reads and every
%   subtotal it forms, so a reader can add the tree up by hand and check it.
%   The instance holds only the ACTIVE choice of each variant role, so the
%   rejected candidates are not in the sum -- step 2 prints which ones were
%   dropped, and that is the whole of D-012 (see also D-058).
%
%   Requires physical/F16A_Physical.slx (run generate_f16a_physical).

arguments
    % Write the OEW Measure of Merit back into the model and save it. True for
    % the generator, false for anything that is only asking what the model says.
    options.Persist (1,1) logical = true
end

% ---------------------------------------------------------------------
% WHAT THIS ROLL-UP IS ABOUT. Three names; the rest of the file is the walk.
% ---------------------------------------------------------------------
MODEL    = "F16A_Physical";                                % the model being measured
PROFILE  = "F16A_PhysicalProps";                           % the profile holding the properties
MASSPROP = "F16A_PhysicalProps.PhysicalItem.Mass_lb";      % what every part carries
OEWPROP  = "F16A_PhysicalProps.MeasureOfMerit.OEW_lb";     % where the answer is recorded

fprintf("\n==========================================================\n");
fprintf("  MASS ROLL-UP\n");
fprintf("  Question: what does this aeroplane weigh empty?\n");
fprintf("  Answer recorded in: Aircraft's MeasureOfMerit.OEW_lb\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

root      = f16aRoot();                    % the example root, via the anchor file
physDir   = fullfile(root, "physical");
modelFile = fullfile(physDir, MODEL + ".slx");
addpath(physDir);

if ~isfile(modelFile)
    error("F16APhysicalMassRollup:noPhysicalModel", ...
        "Missing %s. Run generate_f16a_physical first.", modelFile);
end

m = systemcomposer.loadModel(MODEL);
fprintf("  Model    : %s\n", MODEL);
fprintf("  Property : %s -- every part carries one\n", MASSPROP);
if options.Persist
    fprintf("  Mode     : will WRITE the OEW Measure of Merit and SAVE the model\n");
else
    fprintf("  Mode     : READ-ONLY -- nothing will be written and nothing saved\n");
end

% =====================================================================
% STEP 2 -- BUILD THE ACTIVE-CONFIGURATION INSTANCE
%
% This is the step worth understanding. The MODEL holds every candidate of
% every variant role -- both airframes, both flight control systems, all three
% engines. An analysis INSTANCE holds only the one that is active. Sum the
% model and you get an aeroplane with two airframes and three engines; sum the
% instance and you get the one the trade selected.
% =====================================================================
fprintf("\n[STEP 2] BUILD THE ACTIVE-CONFIGURATION INSTANCE\n");
fprintf("  The model holds every candidate. The instance holds only the chosen one:\n");

nDropped = 0;
for k = m.Architecture.Components
    nDropped = nDropped + printChoices(k);
end

inst = instantiate(m.Architecture, PROFILE, "OEWRollup", ...
    Strict=true, NormalizeUnits=false);
aircraft = lookup(inst, "Path", char(MODEL + "/Aircraft"));

fprintf("  -> %d rejected candidates carry a mass and are NOT in the sum below.\n", nDropped);
fprintf("     That is why the roll-up runs AFTER the trade studies, not before.\n");

% =====================================================================
% STEP 3 -- ADD IT UP, CHILDREN BEFORE PARENTS
%
% One recursion, printed as it goes. A leaf hands its parent the mass it
% carries; an assembly adds up what its parts handed it and hands the total
% one level further up. The aircraft is the last to be added, so its total is
% the Operating Empty Weight.
% =====================================================================
fprintf("\n[STEP 3] ADD IT UP -- CHILDREN BEFORE PARENTS\n\n");
OEW = rollUp(aircraft, 0, MASSPROP);
fprintf("\n  The last line is the Operating Empty Weight: %.2f lb.\n", OEW);

% =====================================================================
% STEP 4 -- THE ASSEMBLY TABLE
% =====================================================================
fprintf("\n[STEP 4] WHAT EACH ASSEMBLY CONTRIBUTES\n");

% Ask the aircraft what it is made of rather than holding a list of names: a
% hard-coded list silently drops a newly added assembly from this table while
% OEW (taken at the root) grows to include it, so the table stops summing to
% the total printed beneath it (D-054).
kids = aircraft.Components;
if isempty(kids)
    error("F16APhysicalMassRollup:noAssemblies", ...
        "%s/Aircraft has no components, so there is nothing to roll up.", MODEL);
end
assemblies = arrayfun(@(k) string(k.Name), kids(:));
asmMass    = arrayfun(@(k) double(k.getValue(char(MASSPROP))), kids(:));

for i = 1:numel(assemblies)
    fprintf("  %s %9.2f lb  (%4.1f%% of OEW)\n", ...
        pad(assemblies(i) + " ", 24, "right", "."), asmMass(i), 100*asmMass(i)/OEW);
end
fprintf("  %s %9.2f lb  <- and that is the same %.2f the walk arrived at\n", ...
    pad("SUM OF THE COLUMN ", 24, "right", "."), sum(asmMass), OEW);

T = table(assemblies, asmMass, 'VariableNames', {'Assembly','Mass_lb'});

% The three figures the docs and the cost model quote, read straight off the
% instance by name -- no path strings, so there is no second path space to
% keep straight.
airframeNode   = childNode(aircraft, "Airframe");
propulsionNode = childNode(aircraft, "Propulsion");
engineNode     = childNode(propulsionNode, "Engine");
airframe   = double(airframeNode.getValue(char(MASSPROP)));
propulsion = double(propulsionNode.getValue(char(MASSPROP)));
engine     = double(engineNode.getValue(char(MASSPROP)));

results = struct( ...
    OEW = OEW, ...
    Airframe = airframe, ...
    Propulsion = propulsion, ...
    Engine = engine, ...
    AirframeLessEngine = OEW - engine, ...   % standard "airframe unit weight" convention
    Table = T);

% =====================================================================
% STEP 5 -- RECORD OEW AS THE MEASURE OF MERIT
% =====================================================================
fprintf("\n[STEP 5] RECORD OEW AS THE MEASURE OF MERIT\n");
if options.Persist
    acComp = lookup(m, Path=char(MODEL + "/Aircraft"));
    setProperty(acComp, char(OEWPROP), string(OEW));
    fprintf("  %s = %.2f  (goal: minimize)\n", OEWPROP, OEW);
else
    fprintf("  Read-only: NOT written. The model still carries whatever OEW it had.\n");
end

% =====================================================================
% STEP 6 -- SAVE
% =====================================================================
fprintf("\n[STEP 6] SAVE\n");
if options.Persist
    save_system(MODEL, char(modelFile));
    fprintf("  Saved %s.slx.\n", MODEL);
else
    fprintf("  Read-only: nothing saved. The model on disk is untouched.\n");
end

fprintf("\n  Airframe subtotal    : %9.2f lb  (the six structural parts)\n", airframe);
fprintf("  Propulsion subtotal  : %9.2f lb  (engine + inlet duct)\n", propulsion);
fprintf("  Airframe less engine : %9.2f lb  = OEW - engine\n", OEW - engine);
fprintf("  Operating Empty Wt   : %9.2f lb  (Measure of Merit: minimize)\n\n", OEW);
fprintf("  One convention, so it is not misread: airframe-less-engine is the standard\n");
fprintf("  'airframe unit weight'. It is NOT the %.2f lb the six structural parts\n", airframe);
fprintf("  add up to -- those are two different questions with two different answers.\n\n");

end

% =====================================================================
function total = rollUp(node, depth, massProp)
%ROLLUP Add up Mass_lb over NODE's subtree, printing every step.
%   A leaf contributes the mass it carries. An assembly is worth what its parts
%   are worth, so its parts are added first -- that is what "children before
%   parents" means, and it is the only reason the order matters.
indent = repmat(' ', 1, 4 + 2*depth);
kids   = node.Components;

if isempty(kids)
    total = 0;
    if node.hasValue(char(massProp))
        total = double(node.getValue(char(massProp)));
    end
    fprintf("%s%s %9.2f lb\n", indent, ...
        pad(string(node.Name) + " ", 30 - 2*depth, "right", "."), total);
    return
end

fprintf("%s%s\n", indent, string(node.Name));
total = 0;
for k = kids
    total = total + rollUp(k, depth + 1, massProp);
end
fprintf("%s= %s %9.2f lb   (sum of the %d above)\n", indent, ...
    pad(string(node.Name) + " ", 28 - 2*depth, "right", "."), total, numel(kids));

% Write the subtotal back so the Analysis Viewer shows the roll-up at every
% level, not just the total at the root.
if node.hasValue(char(massProp))
    node.setValue(char(massProp), total);
end
end

% =====================================================================
function nDropped = printChoices(comp)
%PRINTCHOICES Print each variant role's active choice and the ones it beat.
%   Walks the ARCHITECTURE, which is the only place the rejected candidates
%   still exist -- the instance built in step 2 has already dropped them.
nDropped = 0;
if isa(comp, "systemcomposer.arch.VariantComponent")
    % getChoices, never comp.Architecture.Components: the latter returns ZERO
    % choices on a saved-and-reloaded model.
    active  = getActiveChoice(comp);
    choices = arrayfun(@(c) string(c.Name), getChoices(comp));
    dropped = choices(choices ~= string(active.Name));
    fprintf("    %s kept %-22s dropped %s\n", ...
        pad(string(comp.Name) + " ", 18, "right", "."), string(active.Name), ...
        strjoin(dropped, ", "));
    nDropped = numel(dropped) + printChoices(active);
    return
end
for k = comp.Architecture.Components
    nDropped = nDropped + printChoices(k);
end
end

% =====================================================================
function node = childNode(parent, name)
%CHILDNODE PARENT's child called NAME, by name rather than by path.
for k = parent.Components
    if string(k.Name) == name
        node = k;
        return
    end
end
error("F16APhysicalMassRollup:noSuchChild", ...
    "%s has no child called %s, so its subtotal cannot be reported.", ...
    string(parent.Name), name);
end
