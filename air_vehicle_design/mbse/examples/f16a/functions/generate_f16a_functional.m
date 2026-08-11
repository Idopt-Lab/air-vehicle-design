function generate_f16a_functional()
%GENERATE_F16A_FUNCTIONAL Build the F-16A Functional-layer architecture (RFLP "F").
%   Creates functions/F16A_Functional.slx (the capability tree) and its
%   interface dictionary functions/F16A_Functional.sldd, links the capabilities
%   to the requirements they implement, then builds the mission activity.
%
%   Structure (root architecture = PerformF16AMission):
%     ProvideAircraftFunctions      (shared capability tree)
%       Aviate: GenerateLift, ProduceThrust, Maneuver, ManageFuel,
%               MaintainStructuralIntegrity
%       Navigate, Communicate
%
%   THE F LAYER IS TWO ARTIFACTS, because functions come in two kinds. This
%   model holds the CAPABILITIES -- what the aircraft can do, at any moment,
%   reused across every phase. F16A_MissionActivity holds the mission
%   BEHAVIOUR -- what it does, in order, over time. They were one model until
%   D-059; the metaclass now makes the distinction the prose used to.
%
%   Requirements traceability (Implement links, capability -> requirement):
%     - Point-performance 011-018 map to BOTH GenerateLift and ProduceThrust.
%     - 019 -> MaintainStructuralIntegrity.
%     - Derived placeholders D01-D04 map to the remaining capabilities.
%     The mission phases carry 001-010, 017, 018, 021 and D05-D09, and those
%     links are created by the activity generator, next to the actions.
%
%   Idempotent: re-run to regenerate from scratch. Requires the requirement
%   sets to exist (run generate_f16a_requirements.m and
%   generate_f16a_derived_requirements.m first), and /sizing/ present, since
%   the activity it finishes with delegates the mission analysis there.

modelName = "F16A_Functional";
thisDir   = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
fcnDir    = fullfile(thisDir, "functions");
reqDir    = fullfile(thisDir, "requirements");
dictFile  = fullfile(fcnDir, modelName + ".sldd");
modelFile = fullfile(fcnDir, modelName + ".slx");
slmxFile  = fullfile(fcnDir, modelName + "~mdl.slmx");
origFile  = fullfile(reqDir, "f16a.slreqx");
derFile   = fullfile(reqDir, "f16a_functional_derived.slreqx");

% Make the model, dictionary, and requirement sets resolvable by name.
addpath(fcnDir);
addpath(reqDir);

% ---------------------------------------------------------------------
% 0) Idempotent cleanup
% ---------------------------------------------------------------------
slreq.clear();
try systemcomposer.close(modelName, true); catch, end %#ok<CTCH>
bdclose("all");
Simulink.data.dictionary.closeAll("-discard");
staleRoot = fullfile(thisDir, modelName);   % guard against artifacts saved to cwd
cleanupFiles = [dictFile, modelFile, slmxFile, ...
    fullfile(fcnDir, modelName + ".slxc"), ...
    staleRoot + ".slx", staleRoot + ".slxc", staleRoot + "~mdl.slmx"];
for f = cleanupFiles
    if isfile(f); delete(f); end
end
if isfolder(fullfile(thisDir, "slprj")); rmdir(fullfile(thisDir, "slprj"), "s"); end

% ---------------------------------------------------------------------
% 1) Interface dictionary.
%
%    Built here because the F layer owns its interfaces, but CONSUMED by
%    F16A_MissionActivity: FlightState types the object flow between mission
%    phases, EngagementData the kill chain. The capability tree below has no
%    ports of its own, so it does not link the dictionary -- one dictionary,
%    one user, no dead link (D-059).
% ---------------------------------------------------------------------
dict = systemcomposer.createDictionary(dictFile);
fs = addInterface(dict, "FlightState");
addElement(fs, "Time_s",         Type="double");
addElement(fs, "Altitude_ft",    Type="double");
addElement(fs, "Mach",           Type="double");
addElement(fs, "WeightFraction", Type="double");
ed = addInterface(dict, "EngagementData");
addElement(ed, "TargetDetected",   Type="double");
addElement(ed, "TargetIdentified", Type="double");
addElement(ed, "WeaponReleased",   Type="double");
dict.save();

% ---------------------------------------------------------------------
% 2) Capability tree: Aviate / Navigate / Communicate (pure decomposition).
%
%    NO PORTS, on purpose. A capability is something the aircraft can do, not
%    a step with an input and an output -- the flow belongs to the mission
%    activity. This is what "shared across all phases" looks like in a model.
% ---------------------------------------------------------------------
m = systemcomposer.createModel(modelName);
root = m.Architecture;

paf = addComponent(root, "ProvideAircraftFunctions");
pafArch = paf.Architecture;
aviate = addComponent(pafArch, "Aviate");
aviateArch = aviate.Architecture;
addComponent(aviateArch, ["GenerateLift","ProduceThrust","Maneuver", ...
                          "ManageFuel","MaintainStructuralIntegrity"]);
addComponent(pafArch, ["Navigate","Communicate"]);

% ---------------------------------------------------------------------
% 3) Auto-layout + save
% ---------------------------------------------------------------------
systems = ["F16A_Functional", ...
           "F16A_Functional/ProvideAircraftFunctions", ...
           "F16A_Functional/ProvideAircraftFunctions/Aviate"];
for s = systems
    try Simulink.BlockDiagram.arrangeSystem(s); catch, end %#ok<CTCH>
end
% No "SimulationCommand","update" here any more: a model whose components are
% all virtual and which has no root ports has nothing to update, and asking
% errors with NoBehaviorsForArchitectureModel. The mission activity is where
% the flow now lives.
save_system(modelName, char(modelFile));   % save into functions/

% ---------------------------------------------------------------------
% 4) Requirements traceability (Implement links: capability -> requirement).
%
%    Only the capability links live here. The ten mission phases, the field
%    lengths that are phase-specific, the payload release and the kill chain
%    are ACTIONS now, and their links are created in
%    generate_f16a_mission_activity next to the actions they attach to.
% ---------------------------------------------------------------------
origSet = slreq.load(origFile);
derSet  = slreq.load(derFile);

P  = "F16A_Functional/";
AV = P + "ProvideAircraftFunctions/Aviate/";
NC = P + "ProvideAircraftFunctions/";

% {componentPath, requirementSet, requirementId}
links = {
    % Point performance 011-018 -> BOTH lift and thrust
    AV+"GenerateLift", origSet,"REQ_F16A_011";  AV+"ProduceThrust",origSet,"REQ_F16A_011";
    AV+"GenerateLift", origSet,"REQ_F16A_012";  AV+"ProduceThrust",origSet,"REQ_F16A_012";
    AV+"GenerateLift", origSet,"REQ_F16A_013";  AV+"ProduceThrust",origSet,"REQ_F16A_013";
    AV+"GenerateLift", origSet,"REQ_F16A_014";  AV+"ProduceThrust",origSet,"REQ_F16A_014";
    AV+"GenerateLift", origSet,"REQ_F16A_015";  AV+"ProduceThrust",origSet,"REQ_F16A_015";
    AV+"GenerateLift", origSet,"REQ_F16A_016";  AV+"ProduceThrust",origSet,"REQ_F16A_016";
    AV+"GenerateLift", origSet,"REQ_F16A_017";  AV+"ProduceThrust",origSet,"REQ_F16A_017";
    AV+"GenerateLift", origSet,"REQ_F16A_018";  AV+"ProduceThrust",origSet,"REQ_F16A_018";
    % Structural
    AV+"MaintainStructuralIntegrity", origSet,"REQ_F16A_019";
    % Derived placeholders D01-D04
    AV+"Maneuver",    derSet,"REQ_F16A_D01";  AV+"ManageFuel", derSet,"REQ_F16A_D02";
    NC+"Navigate",    derSet,"REQ_F16A_D03";  NC+"Communicate",derSet,"REQ_F16A_D04";
};

for i = 1:size(links,1)
    comp = lookup(m, Path=char(links{i,1}));
    req  = find(links{i,2}, Id=links{i,3});
    slreq.createLink(comp, req);
end

save(origSet);
save(derSet);
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets); save(lnkSets(i)); end
save_system(modelName, char(modelFile));

fprintf("Built %s with %d capability components and %d Implement links.\n", ...
    modelName, countComps(m.Architecture), size(links,1));

% ---------------------------------------------------------------------
% 5) The mission behaviour, in the metaclass that fits it.
% ---------------------------------------------------------------------
generate_f16a_mission_activity();

end

% =====================================================================
function n = countComps(arch)
%COUNTCOMPS Recursively count components under an architecture.
n = 0;
for c = arch.Components
    n = n + 1 + countComps(c.Architecture);
end
end
