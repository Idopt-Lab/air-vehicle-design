function results = F16APhysicalMassRollup(options)
%F16APHYSICALMASSROLLUP Roll part masses up to the F-16A empty weight (OEW).
%   RESULTS = F16APHYSICALMASSROLLUP() instantiates physical/F16A_Physical.slx
%   and rolls each part's Mass_lb up the tree (children before parents) to a
%   subtotal at every assembly and a grand total -- the Operating Empty
%   Weight -- at the aircraft root. It writes OEW into the aircraft's
%   MeasureOfMerit.OEW_lb and saves, so the shipped model carries the MoM.
%
%   RESULTS = F16APHYSICALMASSROLLUP(Persist=false) returns the same numbers
%   but WRITES NOTHING. Tests use it: a test may not re-save the artifact it
%   is asserting against.
%
%   RESULTS fields: OEW, Airframe, Propulsion, Engine, AirframeLessEngine,
%   Table (per-assembly subtotals).
%
%   Teaching point: this is a NATIVE System Composer parametric analysis
%   (instantiate + iterate, Postorder). The instance contains only the ACTIVE
%   choice of each variant role, so no "Selected" filtering appears anywhere
%   below -- deliberate, not an omission (D-012).
%
%   Requires physical/F16A_Physical.slx (run generate_f16a_physical).

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

% Top-level assemblies for the reported table, READ FROM THE MODEL. A
% hard-coded list silently drops a newly added assembly from the table while
% OEW (read at the root) grows to include it, so the table stops summing to
% the total printed beneath it; and a renamed assembly aborts the roll-up
% mid-generate. Asking the aircraft what it is made of cannot do either.
% Airframe and FlightControls are VARIANT nodes here, which is fine: the
% variant node itself is listed by its parent, and its instance node carries
% the active candidate's rolled-up mass.
aircraft   = lookup(m, Path=char(acPath));
assemblies = string({aircraft.Architecture.Components.Name});
if isempty(assemblies)
    error("F16APhysicalMassRollup:noAssemblies", ...
        "%s has no components, so there is nothing to roll up.", acPath);
end

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

% Every path in this file is an INSTANCE path. The instance flattens a variant
% -- the active choice node is elided and its children lifted under the variant
% node -- so "Airframe" and "Propulsion/Engine" name the variant nodes and
% carry the active candidate's rolled-up mass. Naming a candidate here
% (".../Airframe/BlendedCrankedDelta") would be wrong twice over: it is an
% architecture path, and it would hard-code one candidate into a roll-up whose
% job is to follow whichever one is active.
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
    setProperty(aircraft, char(oewMomProp), string(OEW));
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
