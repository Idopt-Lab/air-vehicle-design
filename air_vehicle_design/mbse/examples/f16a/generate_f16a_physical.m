function generate_f16a_physical()
%GENERATE_F16A_PHYSICAL Build the F-16A Physical-layer architecture (RFLP "P").
%   Creates physical/F16A_Physical.slx (a System Composer model of the
%   concrete physical decomposition), its interface dictionary
%   physical/F16A_Physical.sldd, the stereotype profile
%   physical/F16A_PhysicalProps.xml, and the realization allocation set
%   physical/F16A_LogicalToPhysical.mldatx that ties each logical role
%   (RFLP "L") to the physical part(s) that realize it.
%
%   Where the Logical layer says HOW in solution roles, the Physical layer
%   gives CONCRETE PARTS. Its two teaching ideas:
%     1. Roll-up analysis. Each part carries a Mass_lb; a NATIVE System
%        Composer parametric analysis (F16APhysicalMassRollup, the ex2
%        instantiate/iterate pattern) sums part masses up the tree to a
%        subtotal at every assembly and the Operating Empty Weight (OEW) at
%        the Aircraft root component.
%     2. Measures of Merit. OEW and unit flyaway cost are objectives to
%        MINIMIZE, not pass/fail thresholds. They are carried on a
%        MeasureOfMerit stereotype on the Aircraft component. OEW comes from
%        the mass roll-up; cost comes from a cost-model FUNCTION
%        (F16APhysicalCostModel, a stub for now) -- NOT a roll-up.
%
%   Structure (20 components; the Aircraft component is the system-of-interest
%   that holds the roll-up total and the MoMs), 16 mass-bearing leaves
%   (FuelSystem is a 17th, zero-OEW leaf -- see below):
%     F16A_Physical
%       |- Aircraft
%          |- Airframe     |- Wing Fuselage HorizontalTail VerticalTail Nacelles Strakes
%          |- Propulsion   |- Engine(F100-PW-200) InletDuct
%          |- LandingGear  |- FuelSystem  |- FlightControls  |- Avionics
%          |- Electrical   |- Hydraulics  |- ECS             |- ArmamentSupport
%          |- SecondaryStructure
%   Leaf masses are Brandt F-16A ground-truth weights (lbf, design point
%   W_TO = 31,377 lb) and sum to OEW ~= 19,980.7 lb. FuelSystem carries 0:
%   its dry tankage is integral to the wet wing/fuselage and internal fuel is
%   a consumable, not empty weight -- a deliberate "not every part adds to
%   OEW" lesson. Airframe-less-engine = OEW - Engine ~= 15,250.5 lb is the
%   standard airframe-unit-weight convention (NOT a structural-group sum).
%
%   Realization (logical role -> physical part), 9 roles, 15 edges:
%     Airframe -> Wing/Fuselage/HorizontalTail/VerticalTail/Nacelles/Strakes;
%     PropulsionSystem -> Engine/InletDuct; FuelSystem -> FuelSystem;
%     FlightControlSystem -> FlightControls; LandingGear -> LandingGear;
%     AvionicsSuite -> Avionics; CommunicationSystem -> Avionics;
%     WeaponSystem -> ArmamentSupport; MissionSystemsBay -> ArmamentSupport.
%   Electrical, Hydraulics, ECS and SecondaryStructure realize NO single
%   logical role -- supporting infrastructure, the symmetric echo of L's
%   constraint-driven (function-less) roles.
%
%   Requirements: REQ_F16A_026 (unit flyaway cost) is a Measure of Merit
%   (minimize), homed here and Implement-linked from the Aircraft component.
%   REQ_F16A_022 (materials) remains a deferred requirement.
%
%   Idempotent: re-run to regenerate from scratch. Requires the L model and
%   the requirement set to exist first (run generate_f16a_logical.m and the
%   requirement generators before this).
%
%   -----------------------------------------------------------------------
%   R2026a API NOTES (see generate_f16a_logical.m for the shared ones):
%     * Requirement links attach to a COMPONENT, not the root architecture
%       (slreq.createLink rejects systemcomposer.arch.Architecture), so the
%       Aircraft component -- not the model root -- anchors the MoMs and the
%       REQ_F16A_026 link.
%     * Native roll-up: instantiate(arch, PROFILE_NAME, name, Function=@fn,
%       Direction="Postorder") then iterate(inst,"Postorder",@fn,Recurse=true)
%       then getValue -- see F16APhysicalMassRollup.
%     * String stereotype-property defaults are evaluated as expressions, so
%       quote the literal: DefaultValue="'Minimize'".
%     * connect(src,dst) two-argument form only.
%   -----------------------------------------------------------------------

modelName   = "F16A_Physical";
logiName    = "F16A_Logical";
profileName = "F16A_PhysicalProps";
allocName   = "F16A_LogicalToPhysical";

thisDir  = fileparts(mfilename("fullpath"));
physDir  = fullfile(thisDir, "physical");
logiDir  = fullfile(thisDir, "logical");
reqDir   = fullfile(thisDir, "requirements");
dictFile = fullfile(physDir, modelName + ".sldd");
modelFile= fullfile(physDir, modelName + ".slx");
slmxFile = fullfile(physDir, modelName + "~mdl.slmx");
profFile = fullfile(physDir, profileName + ".xml");
allocFile= fullfile(physDir, allocName + ".mldatx");
origFile = fullfile(reqDir, "f16a.slreqx");

if ~isfolder(physDir); mkdir(physDir); end

% Prerequisites: this generator loads the L model (allocation source) and
% links into the base requirement set (cost MoM).
if ~isfile(origFile)
    error("Missing %s. Run generate_f16a_requirements first.", origFile);
end
if ~isfile(fullfile(logiDir, logiName + ".slx"))
    error("Missing %s.slx. Run generate_f16a_logical first.", logiName);
end

addpath(thisDir);   % so F16APhysicalMassRollup / F16APhysicalCostModel resolve
addpath(physDir);
addpath(logiDir);
addpath(reqDir);

% ---------------------------------------------------------------------
% 0) Idempotent cleanup (unload in-memory sets/profiles BEFORE models/dicts;
%    see generate_f16a_logical.m for why the order matters).
% ---------------------------------------------------------------------
slreq.clear();
try, systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
try, systemcomposer.profile.Profile.closeAll();          catch, end %#ok<CTCH>
try, systemcomposer.close(modelName, true);              catch, end %#ok<CTCH>
bdclose("all");
Simulink.data.dictionary.closeAll("-discard");
staleRoot = fullfile(thisDir, modelName);
cleanupFiles = [dictFile, modelFile, slmxFile, profFile, allocFile, ...
    fullfile(physDir, modelName + ".slxc"), ...
    staleRoot + ".slx", staleRoot + ".slxc", staleRoot + "~mdl.slmx", ...
    fullfile(thisDir, profileName + ".xml"), fullfile(pwd, profileName + ".xml"), ...
    fullfile(thisDir, allocName + ".mldatx"), fullfile(pwd, allocName + ".mldatx")];
for f = cleanupFiles
    if isfile(f); delete(f); end
end
if isfolder(fullfile(thisDir, "slprj")); rmdir(fullfile(thisDir, "slprj"), "s"); end

% ---------------------------------------------------------------------
% 1) Interface dictionary (a small, curated physical backbone)
% ---------------------------------------------------------------------
dict = systemcomposer.createDictionary(dictFile);
tm = addInterface(dict, "ThrustMech");
addElement(tm, "Thrust_lbf", Type="double");
ep = addInterface(dict, "ElecPower");
addElement(ep, "Power_kW", Type="double");
hp = addInterface(dict, "HydPower");
addElement(hp, "Pressure_psi", Type="double");
dict.save();

% ---------------------------------------------------------------------
% 2) Model + dictionary link (link BEFORE typing ports)
% ---------------------------------------------------------------------
m = systemcomposer.createModel(modelName);
linkDictionary(m, dictFile);
tm = m.InterfaceDictionary.getInterface("ThrustMech");
ep = m.InterfaceDictionary.getInterface("ElecPower");
hp = m.InterfaceDictionary.getInterface("HydPower");
root = m.Architecture;

% ---------------------------------------------------------------------
% 3) Physical decomposition. A single Aircraft component (the system-of-
%    interest that carries OEW + the MoMs) holds 11 assemblies; two of the
%    assemblies are refined one level.
% ---------------------------------------------------------------------
aircraft = addComponent(root, "Aircraft");
ac = aircraft.Architecture;
asmNames = ["Airframe","Propulsion","LandingGear","FuelSystem", ...
    "FlightControls","Avionics","Electrical","Hydraulics","ECS", ...
    "ArmamentSupport","SecondaryStructure"];
asm = addComponent(ac, asmNames);
airframe = asm(1); propulsion = asm(2);
fctrl = asm(5); avionics = asm(6); elec = asm(7); hyd = asm(8);

addComponent(airframe.Architecture, ...
    ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"]);
addComponent(propulsion.Architecture, ["Engine","InletDuct"]);

% ---------------------------------------------------------------------
% 4) Light physical backbone (a few typed connections so interfaces exist).
%    Most parts stay port-free -- the teaching focus of P is decomposition,
%    roll-up and realization, not internal data flow.
%    NOTE: two-argument connect() only.
% ---------------------------------------------------------------------
addP(propulsion.Architecture, "ThrustOut", "out", tm);
addP(airframe.Architecture,   "ThrustIn",  "in",  tm);
addP(elec.Architecture,       "PowerOut",  "out", ep);
addP(avionics.Architecture,   "PowerIn",   "in",  ep);
addP(hyd.Architecture,        "HydOut",    "out", hp);
addP(fctrl.Architecture,      "HydIn",     "in",  hp);

connect(propulsion.getPort("ThrustOut"), airframe.getPort("ThrustIn"));
connect(elec.getPort("PowerOut"),        avionics.getPort("PowerIn"));
connect(hyd.getPort("HydOut"),           fctrl.getPort("HydIn"));

% ---------------------------------------------------------------------
% 5) Auto-layout + save
% ---------------------------------------------------------------------
try, Simulink.BlockDiagram.arrangeSystem(modelName); catch, end %#ok<CTCH>
try, Simulink.BlockDiagram.arrangeSystem(modelName + "/Aircraft"); catch, end %#ok<CTCH>
try, Simulink.BlockDiagram.arrangeSystem(modelName + "/Aircraft/Airframe");   catch, end %#ok<CTCH>
try, Simulink.BlockDiagram.arrangeSystem(modelName + "/Aircraft/Propulsion"); catch, end %#ok<CTCH>
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 6) Stereotype profile + part masses + Measure-of-Merit declaration.
%    PhysicalItem.Mass_lb drives the roll-up (applied to EVERY component so
%    interior nodes can hold their written subtotal).
%    MeasureOfMerit declares OEW and unit cost as objectives to MINIMIZE.
% ---------------------------------------------------------------------
profile = systemcomposer.profile.Profile.createProfile(profileName);
pit = profile.addStereotype("PhysicalItem", AppliesTo="Component");
pit.addProperty("Mass_lb", Type="double", DefaultValue="0");
mom = profile.addStereotype("MeasureOfMerit", AppliesTo="Component");
mom.addProperty("OEW_lb",       Type="double", DefaultValue="0");   % <- mass roll-up
mom.addProperty("UnitCost_USD", Type="double", DefaultValue="0");   % <- cost-model function
% String defaults are evaluated as MATLAB expressions, so quote the literal.
mom.addProperty("Goal",         Type="string", DefaultValue="'Minimize'");
profile.save();
relocate(profileName + ".xml", profFile, thisDir);

applyProfile(m, profileName);

% Apply PhysicalItem to the Aircraft and every component beneath it.
applyStereotype(aircraft, profileName + ".PhysicalItem");
applyPhysItemToTree(ac, profileName);

% Leaf masses (Brandt ground truth, lbf). FuelSystem = 0 on purpose.
S = "F16A_Physical/Aircraft/";
massRows = {
    S+"Airframe/Wing",           1785.95;
    S+"Airframe/Fuselage",       3652.11;
    S+"Airframe/HorizontalTail",  648.00;
    S+"Airframe/VerticalTail",    360.00;
    S+"Airframe/Nacelles",        186.82;
    S+"Airframe/Strakes",          90.00;
    S+"Propulsion/Engine",       4730.23;
    S+"Propulsion/InletDuct",     728.60;
    S+"LandingGear",             1066.82;
    S+"FuelSystem",                 0.00;   % dry tankage integral to airframe; fuel is consumable
    S+"FlightControls",           472.44;
    S+"Avionics",                2541.54;
    S+"Electrical",               533.41;
    S+"Hydraulics",               367.11;
    S+"ECS",                      360.84;
    S+"ArmamentSupport",          440.00;
    S+"SecondaryStructure",      2016.86;
};
for i = 1:size(massRows,1)
    c = lookup(m, Path=char(massRows{i,1}));
    setProperty(c, profileName + ".PhysicalItem.Mass_lb", string(massRows{i,2}));
end

% Declare the two Measures of Merit on the Aircraft (Goal defaults to
% "Minimize"; values filled later: OEW by the roll-up, UnitCost_USD by the
% cost-model function).
applyStereotype(aircraft, profileName + ".MeasureOfMerit");
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 7) Realization allocation: logical role -> physical part(s).
% ---------------------------------------------------------------------
srcModel = systemcomposer.loadModel(logiName);
L = "F16A_Logical/";
edges = {
    L+"Airframe",            S+"Airframe/Wing";
    L+"Airframe",            S+"Airframe/Fuselage";
    L+"Airframe",            S+"Airframe/HorizontalTail";
    L+"Airframe",            S+"Airframe/VerticalTail";
    L+"Airframe",            S+"Airframe/Nacelles";
    L+"Airframe",            S+"Airframe/Strakes";
    L+"PropulsionSystem",    S+"Propulsion/Engine";
    L+"PropulsionSystem",    S+"Propulsion/InletDuct";
    L+"FuelSystem",          S+"FuelSystem";
    L+"FlightControlSystem", S+"FlightControls";
    L+"LandingGear",         S+"LandingGear";
    L+"AvionicsSuite",       S+"Avionics";
    L+"CommunicationSystem", S+"Avionics";           % comms realized within the avionics suite
    L+"WeaponSystem",        S+"ArmamentSupport";
    L+"MissionSystemsBay",   S+"ArmamentSupport";
};
alloc = systemcomposer.allocation.createAllocationSet(allocName, logiName, modelName);
scenario = alloc.getScenario("Scenario 1");
for i = 1:size(edges,1)
    srcElem = srcModel.lookup(Path=char(edges{i,1}));
    dstElem = m.lookup(Path=char(edges{i,2}));
    scenario.allocate(srcElem, dstElem);
end
alloc.save();
relocate(allocName + ".mldatx", allocFile, thisDir);

% ---------------------------------------------------------------------
% 8) Cost Measure of Merit (from a cost-model function, not a roll-up) and
%    the Implement link that homes REQ_F16A_026 at the Physical layer.
% ---------------------------------------------------------------------
unitCost = F16APhysicalCostModel(m);   % stub returns NaN ("not yet computed")
% num2str, not string(): string(NaN) is <missing>, which setProperty rejects.
setProperty(aircraft, profileName + ".MeasureOfMerit.UnitCost_USD", string(num2str(unitCost)));
save_system(modelName, char(modelFile));

origSet = slreq.load(origFile);
req = find(origSet, Id="REQ_F16A_026");
if ~isempty(req) && isempty(req.inLinks())
    slreq.createLink(aircraft, req);   % cost MoM (Aircraft) -> REQ_F16A_026
end
save(origSet);
savePhysicalLinkSets();   % only the F16A_Physical link set (leave F/L untouched)
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 9) Run the mass roll-up so the shipped model already carries subtotals and
%    the OEW Measure of Merit. Can be re-run standalone.
% ---------------------------------------------------------------------
results = F16APhysicalMassRollup();

nComp = countComps(m.Architecture);
fprintf("Built %s with %d components (%d realization L->P edges), OEW=%.2f lb, airframe=%.2f, propulsion=%.2f.\n", ...
    modelName, nComp, size(edges,1), results.OEW, results.Airframe, results.Propulsion);

end

% =====================================================================
function applyPhysItemToTree(arch, profileName)
%APPLYPHYSITEMTOTREE Apply PhysicalItem to every component under an arch.
for c = arch.Components
    applyStereotype(c, profileName + ".PhysicalItem");
    applyPhysItemToTree(c.Architecture, profileName);
end
end

% =====================================================================
function p = addP(archObj, name, dir, iface)
%ADDP Add a typed architecture port (dictionary must be linked first).
p = addPort(archObj, name, dir);
p.setInterface(iface);
end

% =====================================================================
function relocate(fileName, destFull, thisDir)
%RELOCATE Move a just-saved artifact into physical/ if the API wrote it to
%   the current folder or the script folder instead. No-op if already there.
if isfile(destFull); return; end
cands = [string(fullfile(pwd, fileName)), string(fullfile(thisDir, fileName))];
for c = cands
    if isfile(c); movefile(c, destFull, "f"); return; end
end
end

% =====================================================================
function n = countComps(arch)
%COUNTCOMPS Recursively count components under an architecture.
n = 0;
for c = arch.Components
    n = n + 1 + countComps(c.Architecture);
end
end

% =====================================================================
function savePhysicalLinkSets()
%SAVEPHYSICALLINKSETS Save only link sets belonging to F16A_Physical, so the
%   functional and logical layers' link sets are not re-written.
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), "F16A_Physical")
        save(lnkSets(i));
    end
end
end
