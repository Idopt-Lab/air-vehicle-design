function generate_f16a_logical()
%GENERATE_F16A_LOGICAL Build the F-16A Logical-layer architecture (RFLP "L").
%   Creates logical/F16A_Logical.slx, its interface dictionary
%   F16A_Logical.sldd, the solution-option profile F16A_LogicalOptions.xml and
%   TWO allocation sets tying each function (F) to the role that realizes it:
%   F16A_FunctionToLogical.mldatx from the capability tree, and
%   F16A_KillChainToLogical.mldatx from the mission activity's kill chain. It
%   also Implement-links roles back to the requirements (R) that only a
%   solution role can satisfy.
%
%   Where F says WHAT the aircraft must do, L says HOW -- in nine solution
%   roles -- and records that a role can usually be realized more than one way.
%   Three of them (Airframe, PropulsionSystem, FlightControlSystem) are VARIANT
%   COMPONENTS, each holding two competing KINDS.
%
%   L PRESENTS THE OPTIONS; L DOES NOT DECIDE. A logical option is an
%   architectural KIND, free of technology, vendor and numbers: "SingleEngine"
%   is a kind, "F100-PW-200" is a product, and products live at P. So nothing
%   built here carries a mass, cost, TRL or benefit, and nothing here picks a
%   winner. physical/F16APhysicalTradeStudy.m decides and writes the outcome
%   back into this model, which therefore ships UNRESOLVED until P has run
%   (D-001, D-010).
%
%   13 leaf functions allocate to the roles over 14 edges -- the one 1->2
%   fan-out being Target -> AvionicsSuite + WeaponSystem. 7 start in the
%   capability tree and 7 in the kill chain, which is why there are two sets.
%
%   The ten mission phases do not allocate to roles HERE. They are
%   orchestration: each one uses capabilities, and those capabilities allocate
%   to roles. That chain is recorded by F16A_MissionUsesCapability, built with
%   the activity (D-059) -- storing phase -> role as well would be a second
%   home for a fact the two existing hops already give.
%
%   Roles, allocation matrix and the deferred requirements homed here:
%   docs/04_logical.md and docs/03_traceability.md. R2026a variant and
%   stereotype traps this file is written around: docs/08_agent_team.md.
%
%   Idempotent: re-run to regenerate from scratch. Requires the F model and the
%   origin requirement set (run generate_f16a_requirements.m and
%   generate_f16a_functional.m first).

modelName   = "F16A_Logical";
funcName    = "F16A_Functional";
actName     = "F16A_MissionActivity";
profileName = "F16A_LogicalOptions";
oldProfName = "F16A_LogicalTrades";   % retired (D-008); cleaned up, never written
allocName   = "F16A_FunctionToLogical";
killAllocName = "F16A_KillChainToLogical";

thisDir  = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
logiDir  = fullfile(thisDir, "logical");
fcnDir   = fullfile(thisDir, "functions");
reqDir   = fullfile(thisDir, "requirements");
dictFile = fullfile(logiDir, modelName + ".sldd");
modelFile= fullfile(logiDir, modelName + ".slx");
slmxFile = fullfile(logiDir, modelName + "~mdl.slmx");
profFile = fullfile(logiDir, profileName + ".xml");
allocFile= fullfile(logiDir, allocName + ".mldatx");   % allocation sets save as .mldatx
killAllocFile = fullfile(logiDir, killAllocName + ".mldatx");
origFile = fullfile(reqDir, "f16a.slreqx");

if ~isfolder(logiDir); mkdir(logiDir); end

% Prerequisites: this generator Implement-links into the ORIGIN requirement set
% and loads the F model. The decision requirements (f16a_logical_derived.slreqx)
% are deliberately NOT required here -- they are linked by the physical trade
% study, so L neither reads nor depends on them (D-010).
if ~isfile(origFile)
    error("Missing %s. Run generate_f16a_requirements first.", origFile);
end
if ~isfile(fullfile(fcnDir, funcName + ".slx"))
    error("Missing %s.slx. Run generate_f16a_functional first.", funcName);
end
if ~isfile(fullfile(fcnDir, actName + ".slx"))
    error("Missing %s.slx. Run generate_f16a_functional first -- the kill-chain " + ...
        "functions live in the mission activity now, and half this generator's " + ...
        "allocation edges start there (D-059).", actName);
end

% Make the models, dictionary, profile and requirement sets resolvable by name.
addpath(logiDir);
addpath(fcnDir);
addpath(reqDir);

% ---------------------------------------------------------------------
% 0) Idempotent cleanup
% ---------------------------------------------------------------------
slreq.clear();
% Unload prior in-memory artifacts FIRST -- loading an allocation set (or the
% profile) can reopen both linked models and their dictionaries, so this must
% happen before we close models/dictionaries, not after (otherwise the
% dictionary is re-locked and createDictionary below fails "file already open").
try  % close any in-memory allocation sets so createAllocationSet can reuse the name
    systemcomposer.allocation.AllocationSet.closeAll();
catch %#ok<CTCH>
end
try  % drop any in-memory copies of previously-loaded profiles (closeAll
     % discards unsaved changes, so a later createProfile can reuse the name)
    systemcomposer.profile.Profile.closeAll();
catch %#ok<CTCH>
end
% Now close every model and dictionary so nothing holds the files open.
try systemcomposer.close(modelName, true); catch, end %#ok<CTCH>
bdclose("all");
Simulink.data.dictionary.closeAll("-discard");
staleRoot = fullfile(thisDir, modelName);   % guard against artifacts saved to cwd
% Both the current profile and the RETIRED F16A_LogicalTrades profile are
% deleted from all three places a save can land, so a re-run of an older
% working copy leaves no stale profile behind for applyProfile to find.
cleanupFiles = [dictFile, modelFile, slmxFile, profFile, allocFile, ...
    fullfile(logiDir, modelName + ".slxc"), ...
    staleRoot + ".slx", staleRoot + ".slxc", staleRoot + "~mdl.slmx", ...
    fullfile(thisDir, profileName + ".xml"), fullfile(pwd, profileName + ".xml"), ...
    fullfile(logiDir, oldProfName + ".xml"), ...
    fullfile(thisDir, oldProfName + ".xml"), fullfile(pwd, oldProfName + ".xml"), ...
    fullfile(thisDir, allocName + ".mldatx"), fullfile(pwd, allocName + ".mldatx"), ...
    killAllocFile, fullfile(thisDir, killAllocName + ".mldatx"), ...
    fullfile(pwd, killAllocName + ".mldatx")];
for f = cleanupFiles
    if isfile(f); delete(f); end
end
if isfolder(fullfile(thisDir, "slprj")); rmdir(fullfile(thisDir, "slprj"), "s"); end

% ---------------------------------------------------------------------
% 1) Interface dictionary (a small, curated logical backbone)
% ---------------------------------------------------------------------
dict = systemcomposer.createDictionary(dictFile);
ff = addInterface(dict, "FuelFlow");
addElement(ff, "FuelRate_pph",  Type="double");
addElement(ff, "TankState_frac",Type="double");
tv = addInterface(dict, "ThrustVector");
addElement(tv, "Thrust_lbf",    Type="double");
cc = addInterface(dict, "ControlCommand");
addElement(cc, "SurfaceDeflect_deg", Type="double");
tt = addInterface(dict, "TargetTrack");
addElement(tt, "Bearing_deg",   Type="double");
addElement(tt, "Range_nm",      Type="double");
dict.save();

% ---------------------------------------------------------------------
% 2) Model + dictionary link (link BEFORE typing ports)
% ---------------------------------------------------------------------
m = systemcomposer.createModel(modelName);
linkDictionary(m, dictFile);
ff = m.InterfaceDictionary.getInterface("FuelFlow");        % re-fetch handles
tv = m.InterfaceDictionary.getInterface("ThrustVector");
cc = m.InterfaceDictionary.getInterface("ControlCommand");
tt = m.InterfaceDictionary.getInterface("TargetTrack");
root = m.Architecture;

% ---------------------------------------------------------------------
% 3) Solution-role components (6 single-solution + 3 variant roles)
% ---------------------------------------------------------------------
fuel   = addComponent(root, "FuelSystem");
gear   = addComponent(root, "LandingGear");             %#ok<NASGU> constraint-driven, no ports
avionics = addComponent(root, "AvionicsSuite");
comms  = addComponent(root, "CommunicationSystem");     %#ok<NASGU> constraint-driven, no ports
weapon = addComponent(root, "WeaponSystem");
bay    = addComponent(root, "MissionSystemsBay");       %#ok<NASGU> constraint-driven, no ports

% Variant roles: each holds two competing KINDS -- architectural topologies,
% named without reference to any technology, supplier or programme. The first
% name listed becomes the active choice (see addVariantRole), which before the
% physical trade has run is a PLACEHOLDER, NOT A DECISION.
% Boundary ports are declared here (added to every choice and propagated to
% the variant boundary -- see addVariantRole), so the wiring below can use
% them exactly like a plain component's ports.
airframe = addVariantRole(root, "Airframe", ...
    ["BlendedCrankedDelta","ConventionalTrapWing"], {"ThrustIn","in",tv; "ControlIn","in",cc});
prop     = addVariantRole(root, "PropulsionSystem", ...
    ["SingleEngine","TwinEngine"], {"FuelIn","in",ff; "ThrustOut","out",tv});
fcs      = addVariantRole(root, "FlightControlSystem", ...
    ["FlyByWire","HydroMechanical"], {"ControlOut","out",cc});

% ---------------------------------------------------------------------
% 4) Light logical backbone (typed connections between 6 of the 9 roles).
%    LandingGear, CommunicationSystem, MissionSystemsBay stay port-free --
%    a deliberate echo of the F-layer capability tree, and a marker that
%    they are constraint-driven, not flow-driven.
%    NOTE: two-argument connect() only (see R2026a note above).
% ---------------------------------------------------------------------
% Single-role ports (variant-role ports were declared in step 3).
addP(fuel.Architecture,     "FuelOut",  "out", ff);
addP(avionics.Architecture, "TrackOut", "out", tt);
addP(weapon.Architecture,   "TrackIn",  "in",  tt);

connect(fuel.getPort("FuelOut"),      prop.getPort("FuelIn"));
connect(prop.getPort("ThrustOut"),    airframe.getPort("ThrustIn"));
connect(fcs.getPort("ControlOut"),    airframe.getPort("ControlIn"));
connect(avionics.getPort("TrackOut"), weapon.getPort("TrackIn"));

% ---------------------------------------------------------------------
% 5) Auto-layout + save
% ---------------------------------------------------------------------
try Simulink.BlockDiagram.arrangeSystem(modelName); catch, end %#ok<CTCH>
save_system(modelName, char(modelFile));   % save into logical/
% Cosmetic diagram refresh; skip quietly if the model has no root behavior
% (this architecture has no root-level ports, unlike the F model).
try set_param(modelName, "SimulationCommand", "update"); catch, end %#ok<CTCH>

% ---------------------------------------------------------------------
% 6) Solution-option stereotype profile, applied to every kind.
%    Deliberately minimal: a kind carries NO mass, NO cost, NO TRL, NO thrust
%    and NO benefit rating -- those are properties of a part, and a part exists
%    only at P (docs/06_methodology.md). All this stereotype records is
%    WHETHER a kind was selected and WHERE the decision is written down;
%    both are left open here and filled in by the physical trade studies.
%    Generated programmatically (no fragile hand-written XML), consistent
%    with the repo's idempotent-generator philosophy.
% ---------------------------------------------------------------------
profile = systemcomposer.profile.Profile.createProfile(profileName);
st = profile.addStereotype("SolutionOption", AppliesTo="Component");
st.addProperty("Selected",    Type="boolean", DefaultValue="false");
% String defaults are evaluated as MATLAB expressions, so quote the literal.
st.addProperty("DecisionRef", Type="string",  DefaultValue="'TBD'");
profile.save();
relocate(profileName + ".xml", profFile, thisDir);   % ensure it lands in logical/

applyProfile(m, profileName);

% Apply SolutionOption to the six kinds. It goes on the CHOICES, never on the
% variant role itself: applyStereotype errors on a VariantComponent in R2026a
% (Stage-0 probe) -- and a role is not an option, so it has nothing to select.
% Every kind starts unselected with DecisionRef 'TBD': the L layer presents the
% options and leaves the decision open. F16APhysicalTradeStudy writes the
% winner's Selected=true and its DecisionRef (the id of the decision
% requirement, e.g. "'REQ_F16A_L01'" -- string values are evaluated, so the
% same quoting applies there).
S = "F16A_Logical/";
kinds = [
    S+"PropulsionSystem/SingleEngine"
    S+"PropulsionSystem/TwinEngine"
    S+"FlightControlSystem/FlyByWire"
    S+"FlightControlSystem/HydroMechanical"
    S+"Airframe/BlendedCrankedDelta"
    S+"Airframe/ConventionalTrapWing"
];
for i = 1:numel(kinds)
    c = lookup(m, Path=char(kinds(i)));
    applyStereotype(c, profileName + ".SolutionOption");
    setProperty(c, profileName + ".SolutionOption.Selected",    "false");
    setProperty(c, profileName + ".SolutionOption.DecisionRef", "'TBD'");
end
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 7) Allocation set: function -> logical role (targets the ROLE, i.e. the
%    variant container, independent of which choice is active).
% ---------------------------------------------------------------------
%    TWO SETS, BECAUSE AN ALLOCATION SET BINDS TO A SOURCE MODEL and the
%    functions no longer live in one. The capabilities are components in
%    F16A_Functional; the kill chain became ACTIONS in F16A_MissionActivity
%    (D-059). Nothing about what these fourteen edges assert has changed --
%    only which file each starts in.
srcModel = systemcomposer.loadModel(funcName);
actModel = systemcomposer.openActivity(char(actName));
killChain = actModel.Activity.getNode("Combat").ChildActivity;

AV = "F16A_Functional/ProvideAircraftFunctions/Aviate/";
NC = "F16A_Functional/ProvideAircraftFunctions/";

% Capability tree -> roles. {functionPath, logicalRolePath}
edges = {
    AV+"GenerateLift",                 S+"Airframe";
    AV+"ProduceThrust",                S+"PropulsionSystem";
    AV+"Maneuver",                     S+"FlightControlSystem";
    AV+"ManageFuel",                   S+"FuelSystem";
    AV+"MaintainStructuralIntegrity",  S+"Airframe";
    NC+"Navigate",                     S+"AvionicsSuite";
    NC+"Communicate",                  S+"CommunicationSystem";
};

alloc = systemcomposer.allocation.createAllocationSet(allocName, funcName, modelName);
scenario = alloc.getScenario("Scenario 1");
for i = 1:size(edges,1)
    srcElem = srcModel.lookup(Path=char(edges{i,1}));
    dstElem = m.lookup(Path=char(edges{i,2}));
    scenario.allocate(srcElem, dstElem);
end
alloc.save();
relocate(allocName + ".mldatx", allocFile, thisDir);  % ensure it lands in logical/

% Kill chain -> roles. The allocation editor takes the action OBJECT here,
% where slreq.createLink wanted its handle (08_agent_team.md).
% {killChainActionName, logicalRolePath}
killEdges = {
    "Find",   S+"AvionicsSuite";
    "Fix",    S+"AvionicsSuite";
    "Track",  S+"AvionicsSuite";
    "Target", S+"AvionicsSuite";      % Target is the one
    "Target", S+"WeaponSystem";       % 1 -> 2 fan-out
    "Assess", S+"AvionicsSuite";
    "Engage", S+"WeaponSystem";
};

killAlloc = systemcomposer.allocation.createAllocationSet(killAllocName, actName, modelName);
killScenario = killAlloc.getScenario("Scenario 1");
for i = 1:size(killEdges,1)
    srcElem = killChain.getNode(killEdges{i,1});
    dstElem = m.lookup(Path=char(killEdges{i,2}));
    killScenario.allocate(srcElem, dstElem);
end
killAlloc.save();
relocate(killAllocName + ".mldatx", killAllocFile, thisDir);

% ---------------------------------------------------------------------
% 8) L-layer Implement links: deferred requirements a solution role owns.
% ---------------------------------------------------------------------
origSet = slreq.load(origFile);
lLinks = {
    S+"MissionSystemsBay", "REQ_F16A_020";   % permanent payload carriage
    S+"LandingGear",       "REQ_F16A_023";   % tipback angle
    S+"LandingGear",       "REQ_F16A_024";   % rollover angle
    S+"Airframe",          "REQ_F16A_025";   % static margin (CG vs neutral point)
};
for i = 1:size(lLinks,1)
    comp = lookup(m, Path=char(lLinks{i,1}));
    req  = find(origSet, Id=char(lLinks{i,2}));
    slreq.createLink(comp, req);
end
save(origSet);
saveLogicalLinkSets();   % only the F16A_Logical link set (leave F's slmx untouched)
save_system(modelName, char(modelFile));

% Component census. Every number below is counted from the model, and the
% printed line SAYS WHICH NUMBER IS WHICH: a bare "15" does not reveal whether
% the kinds are in it, and that ambiguity is half of what made the pre-fix
% countComps (see the helper) hard to catch.
% The census is composed on its own line purely for readability -- it keeps both
% format strings down to one short literal each, and seven conversion specs
% spread over a continuation are hard to check against seven arguments by eye.
roles    = m.Architecture.Components;   % the top-level solution roles
nRole    = numel(roles);
nVariant = 0;
nKind    = 0;
for r = roles
    if isa(r, "systemcomposer.arch.VariantComponent")
        nVariant = nVariant + 1;
        nKind    = nKind + numel(getChoices(r));   % getChoices, not .Architecture.Components
    end
end
nComp = countComps(m.Architecture);     % roles AND the kinds they present
census = sprintf("%d components (%d solution roles, %d of them variant, plus %d kinds)", ...
    nComp, nRole, nVariant, nKind);
fprintf("Built %s with %s, %d allocation edges (%d from the capability tree, " + ...
    "%d from the kill chain), %d L Implement links.\n", ...
    modelName, census, size(edges,1)+size(killEdges,1), size(edges,1), ...
    size(killEdges,1), size(lLinks,1));
fprintf("Options are UNRESOLVED: every kind has Selected=false, DecisionRef='TBD', " + ...
    "and the active choice is a placeholder.\nRun F16APhysicalTradeStudy to decide.\n");

end

% =====================================================================
function vc = addVariantRole(parentArch, roleName, choiceNames, portSpecs)
%ADDVARIANTROLE Add a variant component (a role with competing kinds).
%   choiceNames : string array of choice names; the first is made active.
%   portSpecs   : Nx3 cell {name, dir, iface}; added to EVERY choice and
%                 propagated to the variant boundary so the role can be wired
%                 like a plain component. Pass {} for a port-free variant.
%
%   A variant needs exactly one active choice to be a valid model, so one is
%   set here. Before the physical trade study has run that active choice is a
%   PLACEHOLDER, NOT A DECISION -- it says only "first in the list". The
%   decision, when it is made at P, is recorded by SolutionOption.Selected,
%   SolutionOption.DecisionRef and the decision requirement it points at; the
%   active flag merely follows.
%
%   R2026a specifics learned the hard way:
%     * addVariantComponent seeds two default choices ("Component",
%       "Component1"); we destroy any choice we did not ask for.
%     * setActiveChoice matches the choice NAME created by addChoice (not a
%       renamed component), so we addChoice rather than rename the defaults.
%     * Variant boundary ports are NOT created by addPort on the variant's
%       architecture; add ports to each choice, then updatePortsFromChoices
%       (Mode="addPorts") lifts them onto the boundary.
if nargin < 4; portSpecs = {}; end
vc = addVariantComponent(parentArch, roleName);
addChoice(vc, choiceNames);
for c = getChoices(vc)
    if ~ismember(string(c.Name), choiceNames); destroy(c); end
end
for c = getChoices(vc)
    for i = 1:size(portSpecs,1)
        addP(c.Architecture, portSpecs{i,1}, portSpecs{i,2}, portSpecs{i,3});
    end
end
setActiveChoice(vc, choiceNames(1));
if ~isempty(portSpecs)
    updatePortsFromChoices(vc, Mode="addPorts");
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
%RELOCATE Move a just-saved artifact into logical/ if the API wrote it to
%   the current folder or the script folder instead. No-op if already there.
if isfile(destFull); return; end
cands = [string(fullfile(pwd, fileName)), string(fullfile(thisDir, fileName))];
for c = cands
    if isfile(c)
        movefile(c, destFull, "f");
        return;
    end
end
end

% =====================================================================
function n = countComps(arch)
%COUNTCOMPS Recursively count components under an architecture.
%   VARIANT-SAFE, and it has to be: a plain recursion over .Architecture
%   .Components returns a variant's choices on a freshly built in-memory model
%   but ZERO on the same model saved and reloaded (Stage-0 finding 6). This
%   generator would therefore have reported 15 (the 9 roles plus their 6 kinds)
%   while anything reloading the model reported 9 -- the two disagreeing for a
%   reason nobody would find quickly. getChoices is the only reliable accessor.
%   The variant WRAPPER is counted as a component (it is one in the model tree)
%   even though it can carry no stereotype.
%
%   Same body as countComps in physical/generate_f16a_physical.m: the trap and
%   the fix are identical, and the F layer needs neither because the functional
%   model has no variants.
n = 0;
for c = arch.Components
    n = n + 1;
    if isa(c, "systemcomposer.arch.VariantComponent")
        for ch = getChoices(c)
            n = n + 1 + countComps(ch.Architecture);
        end
    else
        n = n + countComps(c.Architecture);
    end
end
end

% =====================================================================
function saveLogicalLinkSets()
%SAVELOGICALLINKSETS Save only link sets belonging to F16A_Logical, so the
%   functional layer's link set (F16A_Functional~mdl.slmx) is not re-written.
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), "F16A_Logical")
        save(lnkSets(i));
    end
end
end
