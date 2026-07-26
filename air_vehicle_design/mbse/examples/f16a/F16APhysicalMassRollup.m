function results = F16APhysicalMassRollup()
%F16APHYSICALMASSROLLUP Roll part masses up to the F-16A empty weight (OEW).
%   RESULTS = F16APHYSICALMASSROLLUP() instantiates the physical architecture
%   physical/F16A_Physical.slx and rolls each part's Mass_lb up the tree
%   (children before parents) to a subtotal at every assembly and a grand
%   total -- the Operating Empty Weight -- at the aircraft root. It returns a
%   struct with the key figures and a per-assembly table, and it writes the
%   computed OEW into the aircraft root's MeasureOfMerit.OEW_lb so the shipped
%   model already carries the mass Measure of Merit.
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
%   Requires physical/F16A_Physical.slx to exist (run generate_f16a_physical,
%   which itself calls this as its final step).

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

% Names of the top-level assemblies (order matches the model).
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
setProperty(lookup(m, Path=char(acPath)), char(oewMomProp), string(OEW));
save_system(modelName, char(modelFile));

method = "native System Composer analysis";
if ~useNative; method = "hand recursion (native fallback)"; end
fprintf("\n=== F-16A mass roll-up (%s) ===\n", method);
disp(T);
fprintf("Airframe subtotal   : %10.2f lb\n", airframe);
fprintf("Propulsion subtotal : %10.2f lb\n", propulsion);
fprintf("Airframe less engine: %10.2f lb  (OEW - engine)\n", OEW - engine);
fprintf("Operating Empty Wt  : %10.2f lb  (MoM: minimize)\n", OEW);

end

% =====================================================================
function f16aMassRollup(instance, varargin) %#ok<INUSD>
%F16AMASSROLLUP Analysis function: sum Mass_lb bottom-up, write each subtotal.
%   Mirrors ex2/CostAndWeightRollupAnalysis: a leaf keeps its own Mass_lb; an
%   assembly (and the root) is overwritten with the sum of its children, so
%   the Analysis Viewer shows the roll-up at every level. Weight only, no
%   variant "active" filtering (the Physical layer has no variants).
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
kids = comp.Architecture.Components;
if isempty(kids)
    v = str2double(string(getProperty(comp, char(prop))));
    if isnan(v); v = 0; end
else
    v = 0;
    for k = kids; v = v + archMass(k, prop); end
end
end
