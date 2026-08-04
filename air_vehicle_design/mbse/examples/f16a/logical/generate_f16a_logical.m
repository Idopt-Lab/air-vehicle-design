function generate_f16a_logical()
%GENERATE_F16A_LOGICAL Build the F-16A Logical-layer architecture (RFLP "L").
%   Creates logical/F16A_Logical.slx (a System Composer model of solution-
%   role components), its interface dictionary logical/F16A_Logical.sldd, the
%   solution-option stereotype profile logical/F16A_LogicalOptions.xml, and
%   the allocation set logical/F16A_FunctionToLogical.mldatx that ties
%   each function (RFLP "F") to the logical role that realizes it. It also
%   Implement-links the logical roles back to the requirements (RFLP "R")
%   that only a solution role can satisfy.
%
%   Where the Functional layer says WHAT the aircraft must do, the Logical
%   layer says HOW -- in solution roles -- and, crucially, records that a
%   role can usually be realized more than one way. Three roles are modelled
%   as VARIANT COMPONENTS, each holding two competing KINDS.
%
%   L PRESENTS THE OPTIONS; L DOES NOT DECIDE.
%   A logical option is an architectural KIND -- a configuration commitment
%   that is free of technology, vendor and numbers. "SingleEngine" is a kind;
%   "F100-PW-200" is a product, and products live at P. So nothing built here
%   carries a mass, a cost, a TRL or a benefit score, and nothing here picks a
%   winner. The decision is made one layer down, by
%   physical/F16APhysicalTradeStudy.m: it scores the concrete parameterized
%   candidates at P and writes the outcome back into this model -- the active
%   variant choice, SolutionOption.Selected, SolutionOption.DecisionRef, and an
%   Implement link from the winning kind to its decision requirement
%   (REQ_F16A_L01..L03). Until that has run, this model ships UNRESOLVED.
%   For the boundary rule and its grounding, see docs/06_methodology.md.
%
%   Structure (root architecture = F16ASolutionRoles):
%     F16ASolutionRoles
%       |- Airframe               (VARIANT: BlendedCrankedDelta | ConventionalTrapWing)
%       |- PropulsionSystem       (VARIANT: SingleEngine        | TwinEngine)
%       |- FuelSystem
%       |- FlightControlSystem    (VARIANT: FlyByWire           | HydroMechanical)
%       |- LandingGear            (constraint-driven; no function allocated)
%       |- AvionicsSuite
%       |- CommunicationSystem
%       |- WeaponSystem
%       |- MissionSystemsBay      (constraint-driven; no function allocated)
%
%   Allocation (function -> logical role), 13 leaf functions, 14 edges:
%     GenerateLift -> Airframe; ProduceThrust -> PropulsionSystem;
%     Maneuver -> FlightControlSystem; ManageFuel -> FuelSystem;
%     MaintainStructuralIntegrity -> Airframe; Navigate -> AvionicsSuite;
%     Communicate -> CommunicationSystem; Find/Fix/Track/Assess -> AvionicsSuite;
%     Target -> AvionicsSuite + WeaponSystem (the one 1->2 fan-out);
%     Engage -> WeaponSystem. The ten temporal mission phases are NOT
%     allocated -- they are orchestration realized BY these capabilities.
%
%   Deferred requirements now homed at L (Implement links, role -> requirement):
%     020 -> MissionSystemsBay; 023,024 -> LandingGear; 025 -> Airframe.
%     022 (materials) and 026 (cost) stay deferred to the Physical layer.
%
%   Idempotent: re-run to regenerate from scratch. Requires the F model and
%   the origin requirement set to exist first (run generate_f16a_requirements.m
%   and generate_f16a_functional.m before this). It does NOT need the decision
%   requirements REQ_F16A_L01..L03 -- those are linked by the physical trade
%   study, so L stays independent of whether P has run (D-010).
%
%   -----------------------------------------------------------------------
%   R2026a API NOTES -- these calls are new to this repo (the F layer used
%   only plain components + slreq links). Confirm on first run; each is
%   isolated in a helper below so a signature fix touches one place:
%     * Variants:   addVariantComponent, addChoice, setActiveChoice
%                   (helper addVariantRole). getChoices returns the choices
%                   ALPHABETICALLY, not in creation order, so never rely on
%                   creation order -- always address a choice by name.
%                   getChoices is also the ONLY reliable way to reach the
%                   choices at all: .Architecture.Components hands them back on
%                   a freshly built in-memory model but ZERO on the same model
%                   saved and reloaded (Stage-0 finding 6). Every walk over this
%                   architecture -- addVariantRole and countComps below --
%                   therefore special-cases a VariantComponent.
%     * Profile:    systemcomposer.profile.Profile.createProfile, addStereotype
%                   (AppliesTo=), addStereotype-property addProperty(Type=,
%                   DefaultValue=), applyProfile, applyStereotype, setProperty.
%                   A stereotype CANNOT be applied to a variant component
%                   (applyStereotype errors on systemcomposer.arch.
%                   VariantComponent) -- it goes on the variant's CHOICES,
%                   which is exactly where SolutionOption belongs anyway.
%                   Property values and defaults are evaluated as MATLAB
%                   expressions, so a string literal must be quoted: "'TBD'".
%     * Allocation: systemcomposer.allocation.createAllocationSet, getScenario,
%                   scenario.allocate(srcElem, dstElem), alloc.save.
%   As in generate_f16a_functional.m, connect ports with the TWO-argument
%   form connect(srcPort, dstPort); the three-argument form silently leaves
%   ports unwired in R2026a.
%   -----------------------------------------------------------------------

modelName   = "F16A_Logical";
funcName    = "F16A_Functional";
profileName = "F16A_LogicalOptions";
oldProfName = "F16A_LogicalTrades";   % retired (D-008); cleaned up, never written
allocName   = "F16A_FunctionToLogical";

thisDir  = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
logiDir  = fullfile(thisDir, "logical");
archDir  = fullfile(thisDir, "architecture");
reqDir   = fullfile(thisDir, "requirements");
dictFile = fullfile(logiDir, modelName + ".sldd");
modelFile= fullfile(logiDir, modelName + ".slx");
slmxFile = fullfile(logiDir, modelName + "~mdl.slmx");
profFile = fullfile(logiDir, profileName + ".xml");
allocFile= fullfile(logiDir, allocName + ".mldatx");   % allocation sets save as .mldatx
origFile = fullfile(reqDir, "f16a.slreqx");

if ~isfolder(logiDir); mkdir(logiDir); end

% Prerequisites: this generator Implement-links into the ORIGIN requirement set
% and loads the F model. The decision requirements (f16a_logical_derived.slreqx)
% are deliberately NOT required here -- they are linked by the physical trade
% study, so L neither reads nor depends on them (D-010).
if ~isfile(origFile)
    error("Missing %s. Run generate_f16a_requirements first.", origFile);
end
if ~isfile(fullfile(archDir, funcName + ".slx"))
    error("Missing %s.slx. Run generate_f16a_functional first.", funcName);
end

% Make the models, dictionary, profile and requirement sets resolvable by name.
addpath(logiDir);
addpath(archDir);
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
    fullfile(thisDir, allocName + ".mldatx"), fullfile(pwd, allocName + ".mldatx")];
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
%    Deliberately minimal: a kind carries NO Mass_lb, NO UnitCost_USD, NO
%    TRL and NO Benefit -- those are properties of a part, and a part exists
%    only at P (docs/06_methodology.md). All this stereotype records is
%    WHETHER a kind was selected and WHERE the decision is written down;
%    both are left open here and filled in by F16APhysicalTradeStudy.
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
srcModel = systemcomposer.loadModel(funcName);

FP = "F16A_Functional/";
AV = FP + "ProvideAircraftFunctions/Aviate/";
NC = FP + "ProvideAircraftFunctions/";
CB = FP + "ExecuteMissionProfile/Combat/";

% {functionPath, logicalRolePath}
edges = {
    AV+"GenerateLift",                 S+"Airframe";
    AV+"ProduceThrust",                S+"PropulsionSystem";
    AV+"Maneuver",                     S+"FlightControlSystem";
    AV+"ManageFuel",                   S+"FuelSystem";
    AV+"MaintainStructuralIntegrity",  S+"Airframe";
    NC+"Navigate",                     S+"AvionicsSuite";
    NC+"Communicate",                  S+"CommunicationSystem";
    CB+"Find",                         S+"AvionicsSuite";
    CB+"Fix",                          S+"AvionicsSuite";
    CB+"Track",                        S+"AvionicsSuite";
    CB+"Target",                       S+"AvionicsSuite";      % Target is the one
    CB+"Target",                       S+"WeaponSystem";       % 1 -> 2 fan-out
    CB+"Assess",                       S+"AvionicsSuite";
    CB+"Engage",                       S+"WeaponSystem";
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
fprintf("Built %s with %s, %d allocation edges, %d L Implement links.\n", ...
    modelName, census, size(edges,1), size(lLinks,1));
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
