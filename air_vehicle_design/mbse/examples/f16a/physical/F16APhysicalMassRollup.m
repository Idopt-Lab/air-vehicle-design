function results = F16APhysicalMassRollup(options)
%F16APHYSICALMASSROLLUP Roll part masses up to the F-16A empty weight (OEW).
%   RESULTS = F16APHYSICALMASSROLLUP() instantiates the physical architecture
%   physical/F16A_Physical.slx and rolls each part's Mass_lb up the tree
%   (children before parents) to a subtotal at every assembly and a grand
%   total -- the Operating Empty Weight -- at the aircraft root. It returns a
%   struct with the key figures and a per-assembly table, and it writes the
%   computed OEW into the aircraft root's MeasureOfMerit.OEW_lb so the shipped
%   model already carries the mass Measure of Merit.
%
%   RESULTS = F16APHYSICALMASSROLLUP(Persist=false) computes and returns
%   exactly the same numbers but WRITES NOTHING: it skips both the setProperty
%   of the OEW Measure of Merit and the save_system. Default is true, so the
%   generator is unaffected.
%
%   READ-ONLY MODE EXISTS FOR THE TEST SUITE. This function is called by tests
%   that are asserting on the very model it would otherwise re-save, which
%   makes a test run a WRITE to the artifact under test: the .slx changes
%   timestamp (and, if a value ever differed, content) simply because somebody
%   ran the suite. Reading the model and modifying it are separate jobs, and a
%   test may only do the first. Persist=false is that separation.
%   The other two roll-ups (F16APhysicalMaterialsRollup,
%   F16APhysicalFuelRollup) need no such option -- they already only read.
%
%   RESULTS fields: OEW, Airframe, Propulsion, Engine, AirframeLessEngine, Table.
%
%   This is the Physical-layer teaching capability: a NATIVE System Composer
%   parametric analysis. It mirrors mbse/examples/ex2 (CostAndWeightRollup-
%   Analysis.m + model_instance.m), the proven R2026a pattern:
%     instantiate(arch, PROFILE, name, Function=@fn, Direction="Postorder")
%     iterate(instance, "Postorder", @fn, Recurse=true)
%   then read each node's rolled value with getValue. Postorder guarantees a
%   node's children are summed before the node itself.
%
%   OEW is a Measure of Merit to MINIMIZE (there is no target/threshold and
%   nothing is asserted against a limit). Unit flyaway cost is the OTHER MoM,
%   but it is NOT rolled up here -- it comes from a cost-model function
%   (F16APhysicalCostModel); see the Physical-layer doc for that contrast.
%
%   THIS IS AN ACTIVE-CONFIGURATION ROLL-UP, AND IT IS ONE FOR FREE.
%   The physical model has three variant roles (Airframe, Propulsion/Engine,
%   FlightControls) holding seven candidates between them, and summing all
%   seven would be meaningless -- an aircraft has one engine fit, not three.
%   The native path needs no filter to get that right: instantiate/iterate
%   traverses ONLY the active choice (Stage-0 finding 2, D-012), so the
%   analysis function below is a plain postorder sum with no "Selected"
%   handling anywhere in it. Deliberate, not an omission.
%
%   The instance also FLATTENS a variant (finding 3): the active choice node is
%   elided and its children lifted under the variant node, so the INSTANCE path
%   is ".../Aircraft/Airframe/Wing" while the ARCHITECTURE path is now
%   ".../Aircraft/Airframe/BlendedCrankedDelta/Wing". Every path in this file
%   is an instance path and therefore did NOT change when the candidates were
%   introduced -- rd("...Airframe") and rd("...Propulsion/Engine") still name
%   the variant node and still return the active configuration's mass. Only the
%   archMass fallback, which walks the ARCHITECTURE, had to learn about
%   variants; see its comment.
%
%   Requires physical/F16A_Physical.slx to exist (run generate_f16a_physical,
%   which itself calls this as its final step).

arguments
    % Write the OEW Measure of Merit back into the model and save it. True for
    % the generator, false for anything that is only asking what the model says.
    options.Persist (1,1) logical = true
end

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
massProp    = profileName + ".PhysicalItem.Mass_lb";
oewMomProp  = profileName + ".MeasureOfMerit.OEW_lb";

thisDir   = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
physDir   = fullfile(thisDir, "physical");
modelFile = fullfile(physDir, modelName + ".slx");
addpath(physDir);

m = systemcomposer.loadModel(modelName);
acPath = modelName + "/Aircraft";     % the system-of-interest component
S = acPath + "/";

% Names of the top-level assemblies, for the reported table. Each is read by
% path, so this is presentation order only -- it no longer matches the order
% the generator creates them in (the two variant roles are added after the nine
% plain ones), and nothing depends on it. Airframe and FlightControls name
% VARIANT nodes here; see the note above on why that path still resolves.
assemblies = ["Airframe","Propulsion","LandingGear","FuelSystem", ...
    "FlightControls","Avionics","Electrical","Hydraulics","ECS", ...
    "ArmamentSupport","SecondaryStructure"];

% --- Roll up: native System Composer analysis (ex2 pattern) --------------
% Fall back to a plain recursion over the model if instantiate/iterate is
% unavailable; both return identical numbers, so callers/tests are agnostic.
useNative = true;
try
    inst = instantiate(m.Architecture, profileName, "OEWRollup", ...
        Function=@f16aMassRollup, Strict=true, NormalizeUnits=false, ...
        Direction="Postorder");
    iterate(inst, "Postorder", @f16aMassRollup, Recurse=true);
    rd = @(p) instMass(inst, p, massProp);   % read a rolled value by path
catch ME
    useNative = false;
    warning("F16APhysicalMassRollup:native", ...
        "Native instantiate/iterate unavailable (%s); using hand recursion.", ...
        ME.message);
    rd = @(p) archMass(lookup(m, Path=char(p)), massProp);
end

% These four paths are unchanged by the variant restructure, and that is a
% consequence of the flattening described above rather than an accident:
% "Airframe" and "Propulsion/Engine" name the VARIANT NODES, whose instance
% nodes carry the active candidate's rolled-up mass. Reading
% ".../Airframe/BlendedCrankedDelta" here would be wrong twice over -- it is an
% architecture path, and it would hard-code one candidate into a roll-up whose
% whole job is to follow whichever one is active.
OEW        = rd(acPath);
airframe   = rd(S + "Airframe");
propulsion = rd(S + "Propulsion");
engine     = rd(S + "Propulsion/Engine");

% Per-assembly rolled masses (for the printed/returned summary).
asmMass = zeros(numel(assemblies), 1);
for i = 1:numel(assemblies)
    asmMass(i) = rd(S + assemblies(i));
end
T = table(assemblies(:), asmMass, 'VariableNames', {'Assembly','Mass_lb'});

results = struct( ...
    OEW = OEW, ...
    Airframe = airframe, ...
    Propulsion = propulsion, ...
    Engine = engine, ...
    AirframeLessEngine = OEW - engine, ...   % standard "airframe unit weight" convention
    Table = T);

% --- Record OEW as the mass Measure of Merit on the Aircraft component ----
% Both statements are inside the guard, and both have to be: writing the
% property without saving would leave the in-memory model dirty for whatever
% runs next, which is its own kind of side effect.
if options.Persist
    setProperty(lookup(m, Path=char(acPath)), char(oewMomProp), string(OEW));
    save_system(modelName, char(modelFile));
end

method = "native System Composer analysis";
if ~useNative; method = "hand recursion (native fallback)"; end
mode = "";
if ~options.Persist; mode = ", read-only: OEW MoM not written, model not saved"; end
fprintf("\n=== F-16A mass roll-up (%s%s) ===\n", method, mode);
disp(T);
fprintf("Airframe subtotal   : %10.2f lb\n", airframe);
fprintf("Propulsion subtotal : %10.2f lb\n", propulsion);
fprintf("Airframe less engine: %10.2f lb  (OEW - engine)\n", OEW - engine);
fprintf("Operating Empty Wt  : %10.2f lb  (MoM: minimize)\n", OEW);

end

% =====================================================================
function f16aMassRollup(instance, varargin)
%F16AMASSROLLUP Analysis function: sum Mass_lb bottom-up, write each subtotal.
%   Mirrors ex2/CostAndWeightRollupAnalysis: a leaf keeps its own Mass_lb; an
%   assembly (and the root) is overwritten with the sum of its children, so
%   the Analysis Viewer shows the roll-up at every level. Weight only, and NO
%   variant "active" filtering ON PURPOSE: the instance the iterator walks
%   already contains only the active choice (D-012 / Stage-0 finding 2), so a
%   filter here would be dead code that looked load-bearing.
    if ~instance.isComponent(); return; end
    rollupAndSet(instance);

    function s = rollupAndSet(node)
        prop = "F16A_PhysicalProps.PhysicalItem.Mass_lb";
        kids = node.Components;
        if isempty(kids)
            % Leaf: its own mass is its contribution.
            s = 0;
            if node.hasValue(char(prop)); s = double(node.getValue(char(prop))); end
        else
            % Assembly/root: sum children, then write the subtotal back.
            s = 0;
            for ch = kids; s = s + rollupAndSet(ch); end
            if node.hasValue(char(prop)); node.setValue(char(prop), s); end
        end
    end
end

% =====================================================================
function v = instMass(inst, pth, prop)
%INSTMASS Read a rolled mass from an instance node by path.
node = lookup(inst, "Path", char(pth));
v = double(node.getValue(char(prop)));
end

% =====================================================================
function v = archMass(comp, prop)
%ARCHMASS Fallback: recursively sum leaf Mass_lb under a model component.
%   Used only when instantiate/iterate is unavailable. Unlike the native path
%   above, this walks the ARCHITECTURE, which contains EVERY candidate of every
%   variant role -- so without the first branch it would add the F100, the
%   low-thrust surrogate AND the twin-engine surrogate together and report an
%   aircraft with three
%   engines and two airframes (D-012 / Stage-0 finding 2 is exactly this
%   asymmetry: the instance filters, the architecture does not).
%
%   getActiveChoice is the right accessor here rather than getChoices: this
%   function must reproduce the native path's number, and the native path sees
%   the active configuration. It also sidesteps finding 6 -- a variant's
%   .Architecture.Components returns ZERO on a saved-and-reloaded model, so the
%   old code would have silently treated every variant role as a massless leaf
%   instead of loudly over-counting. Both failure modes are gone.
if isa(comp, "systemcomposer.arch.VariantComponent")
    v = archMass(getActiveChoice(comp), prop);
    return;
end
kids = comp.Architecture.Components;
if isempty(kids)
    v = str2double(string(getProperty(comp, char(prop))));
    if isnan(v); v = 0; end
else
    v = 0;
    for k = kids; v = v + archMass(k, prop); end
end
end
