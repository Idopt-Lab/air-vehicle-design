function results = F16APhysicalMassRollup(options)
%F16APHYSICALMASSROLLUP Add the part masses to get the F-16A empty weight (OEW).
%   RESULTS = F16APHYSICALMASSROLLUP() builds a System Composer analysis
%   instance of physical/F16A_Physical.slx. It adds Mass_lb up the tree,
%   children before parents. The result is a subtotal at each assembly and a
%   grand total at the aircraft, which is the Operating Empty Weight. It
%   writes OEW into MeasureOfMerit.OEW_lb of the aircraft and saves the model.
%
%   RESULTS = F16APHYSICALMASSROLLUP(Persist=false) returns the same numbers
%   and writes nothing. RESULTS fields: OEW, Airframe, Propulsion, Engine,
%   AirframeLessEngine, Table (per-assembly subtotals).
%
%   It prints each mass that it reads and each subtotal that it calculates,
%   so that you can add the tree by hand. The sum includes only the active
%   choice of each variant role. Step 2 prints the candidates that are not
%   included (D-012).

arguments
    options.Persist (1,1) logical = true   % write OEW_lb into the model and save
end

% ---------------------------------------------------------------------
% THE SUBJECT OF THIS ROLL-UP: four names. The rest of the file goes through the tree.
% ---------------------------------------------------------------------
MODEL    = "F16A_Physical";                                % the model to measure
PROFILE  = "F16A_PhysicalProps";                           % the profile that holds the properties
MASSPROP = "F16A_PhysicalProps.PhysicalItem.Mass_lb";      % the property that each part carries
OEWPROP  = "F16A_PhysicalProps.MeasureOfMerit.OEW_lb";     % where the result is recorded

fprintf("\n==========================================================\n");
fprintf("  MASS ROLL-UP\n");
fprintf("  Question: what is the empty weight of this aeroplane?\n");
fprintf("  Answer recorded in: MeasureOfMerit.OEW_lb on Aircraft\n");
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");

m = systemcomposer.loadModel(MODEL);
fprintf("  Model    : %s\n", MODEL);
fprintf("  Property : %s (each part has one)\n", MASSPROP);
if options.Persist
    fprintf("  Mode     : writes the OEW Measure of Merit and saves the model\n");
else
    fprintf("  Mode     : READ-ONLY. It writes nothing and saves nothing.\n");
end

% =====================================================================
% STEP 2 -- BUILD THE ACTIVE-CONFIGURATION INSTANCE
%
% This is the important step. The model holds all candidates of all variant
% roles: both airframes, both flight control systems and all three engines.
% An analysis instance holds only the active candidate. If you add the masses
% in the model, you get an aeroplane with two airframes and three engines. If
% you add the masses in the instance, you get the aeroplane that the trades
% selected.
% =====================================================================
fprintf("\n[STEP 2] BUILD THE ACTIVE-CONFIGURATION INSTANCE\n");
fprintf("  The model holds all candidates. The instance holds only the selected one:\n");

nDropped = 0;
for k = m.Architecture.Components
    nDropped = nDropped + printChoices(k);
end

inst = instantiate(m.Architecture, PROFILE, "OEWRollup", ...
    Strict=true, NormalizeUnits=false);
aircraft = lookup(inst, "Path", char(MODEL + "/Aircraft"));

fprintf("  -> %d rejected candidates have a mass, but they are NOT in the sum below.\n", nDropped);
fprintf("     For this reason, the roll-up runs after the trade studies, not before.\n");

% =====================================================================
% STEP 3 -- ADD THE MASSES, CHILDREN BEFORE PARENTS
%
% One recursion, which prints each step. A leaf gives its mass to its parent.
% An assembly adds the masses from its parts and gives the total to the next
% level up. The aircraft is added last, so its total is the Operating Empty
% Weight.
% =====================================================================
fprintf("\n[STEP 3] ADD THE MASSES, CHILDREN BEFORE PARENTS\n\n");
OEW = rollUp(aircraft, 0, MASSPROP);
fprintf("\n  The last line is the Operating Empty Weight: %.2f lb.\n", OEW);

% =====================================================================
% STEP 4 -- THE ASSEMBLY TABLE
% =====================================================================
fprintf("\n[STEP 4] THE MASS OF EACH ASSEMBLY\n");

% Get the assemblies from the aircraft, not from a list of names. Thus a new
% assembly shows here, and you do not have to edit this file.
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
fprintf("  %s %9.2f lb  <- the same value as the %.2f that step 3 calculated\n", ...
    pad("SUM OF THE COLUMN ", 24, "right", "."), sum(asmMass), OEW);

T = table(assemblies, asmMass, 'VariableNames', {'Assembly','Mass_lb'});

% The figures that the docs quote. The code reads them from the instance by name.
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
    fprintf("  Read-only: not written. The model keeps the OEW value that it had before.\n");
end

% =====================================================================
% STEP 6 -- SAVE
% =====================================================================
fprintf("\n[STEP 6] SAVE\n");
if options.Persist
    save_system(MODEL);
    fprintf("  Saved %s.slx.\n", MODEL);
else
    fprintf("  Read-only: nothing saved. The model on disk does not change.\n");
end

fprintf("\n  Airframe subtotal    : %9.2f lb  (the six structural parts)\n", airframe);
fprintf("  Propulsion subtotal  : %9.2f lb  (engine + inlet duct)\n", propulsion);
fprintf("  Airframe less engine : %9.2f lb  = OEW - engine\n", OEW - engine);
fprintf("  Operating Empty Wt   : %9.2f lb  (Measure of Merit: minimize)\n\n", OEW);
fprintf("  Note this convention: airframe-less-engine is the standard 'airframe unit\n");
fprintf("  weight'. It is NOT the %.2f lb sum of the six structural parts. These are\n", airframe);
fprintf("  two different questions with two different answers.\n\n");

end

% =====================================================================
function total = rollUp(node, depth, massProp)
%ROLLUP Add Mass_lb over the subtree of NODE, and print each step.
%   A leaf contributes its mass. The mass of an assembly is the sum of the
%   masses of its parts, so the code adds the parts first. This is the meaning
%   of "children before parents", and it is the only reason that the order is
%   important.
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

% Write the subtotal back, so that the Analysis Viewer shows the roll-up at
% each level, not only the total at the root.
if node.hasValue(char(massProp))
    node.setValue(char(massProp), total);
end
end

% =====================================================================
function nDropped = printChoices(comp)
%PRINTCHOICES Print the active choice of each variant role and the choices that it won against.
%   Goes through the architecture, which is the only location where the
%   rejected candidates still exist. The instance from step 2 does not include
%   them.
nDropped = 0;
if isa(comp, "systemcomposer.arch.VariantComponent")
    % Use getChoices, not comp.Architecture.Components, which is empty on a saved model.
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
%CHILDNODE Return the child of PARENT that has the name NAME (by name, not by path).
for k = parent.Components
    if string(k.Name) == name
        node = k;
        return
    end
end
error("F16APhysicalMassRollup:noSuchChild", ...
    "%s has no child named %s, so its subtotal cannot be reported.", ...
    string(parent.Name), name);
end
