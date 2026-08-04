function generate_f16a_functional()
%GENERATE_F16A_FUNCTIONAL Build the F-16A Functional-layer architecture (RFLP "F").
%   Creates architecture/F16A_Functional.slx (a System Composer model) and
%   its interface dictionary architecture/F16A_Functional.sldd, then links
%   the functions back to the requirements (RFLP "R") they implement.
%
%   Structure (root architecture = PerformF16AMission):
%     PerformF16AMission
%       |- ExecuteMissionProfile   (the temporal mission thread, FlightState)
%       |    Takeoff -> Accel -> Climb -> Cruise -> Dash -> Combat
%       |    -> Egress -> Cruise2 -> Loiter -> Landing
%       |    Combat decomposes into the F2T2EA kill chain:
%       |       Find -> Fix -> Track -> Target -> Engage -> Assess
%       |- ProvideAircraftFunctions  (shared capability tree; Aviate/Nav/Comm)
%            Aviate: GenerateLift, ProduceThrust, Maneuver, ManageFuel,
%                    MaintainStructuralIntegrity
%            Navigate, Communicate
%
%   The mission thread carries typed information flows (FlightState and, for
%   the kill chain, EngagementData). The capability tree is a pure
%   functional decomposition (no ports) -- it shows WHAT the aircraft does,
%   reused across all phases.
%
%   Requirements traceability (Implement links, function -> requirement):
%     - Mission phases 001-010 map 1:1 to the ten phase functions.
%     - Point-performance 011-018 map to BOTH GenerateLift and ProduceThrust;
%       017/018 (field length) additionally map to Takeoff/Landing.
%     - 019 -> MaintainStructuralIntegrity; 021 -> Engage.
%     - Derived placeholders D01-D09 (f16a_functional_derived.slreqx) map to
%       the functions the sizing-derived requirements did not cover.
%
%   Idempotent: re-run to regenerate from scratch. Requires the requirement
%   sets to exist (run generate_f16a_requirements.m and
%   generate_f16a_derived_requirements.m first).

modelName = "F16A_Functional";
thisDir   = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
archDir   = fullfile(thisDir, "architecture");
reqDir    = fullfile(thisDir, "requirements");
dictFile  = fullfile(archDir, modelName + ".sldd");
modelFile = fullfile(archDir, modelName + ".slx");
slmxFile  = fullfile(archDir, modelName + "~mdl.slmx");
origFile  = fullfile(reqDir, "f16a.slreqx");
derFile   = fullfile(reqDir, "f16a_functional_derived.slreqx");

% Make the model, dictionary, and requirement sets resolvable by name.
addpath(archDir);
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
    fullfile(archDir, modelName + ".slxc"), ...
    staleRoot + ".slx", staleRoot + ".slxc", staleRoot + "~mdl.slmx"];
for f = cleanupFiles
    if isfile(f); delete(f); end
end
if isfolder(fullfile(thisDir, "slprj")); rmdir(fullfile(thisDir, "slprj"), "s"); end

% ---------------------------------------------------------------------
% 1) Interface dictionary
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
% 2) Model + dictionary link (link BEFORE typing ports)
% ---------------------------------------------------------------------
m = systemcomposer.createModel(modelName);
linkDictionary(m, dictFile);
fs = m.InterfaceDictionary.getInterface("FlightState");    % re-fetch handles
ed = m.InterfaceDictionary.getInterface("EngagementData");
root = m.Architecture;

% ---------------------------------------------------------------------
% 3) Top level: ExecuteMissionProfile + ProvideAircraftFunctions
% ---------------------------------------------------------------------
addP(root, "MissionStart",     "in",  fs);
addP(root, "MissionComplete",  "out", fs);
addP(root, "EngagementResult", "out", ed);

emp = addComponent(root, "ExecuteMissionProfile");
addP(emp.Architecture, "In",              "in",  fs);
addP(emp.Architecture, "Out",             "out", fs);
addP(emp.Architecture, "EngagementResult","out", ed);

% ---------------------------------------------------------------------
% 4) Mission-phase chain (FlightState spine)
% ---------------------------------------------------------------------
empArch = emp.Architecture;
phases = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
          "Egress","Cruise2","Loiter","Landing"];
prevOut = empArch.getPort("In");                 % internal input acts as source
combat = [];
for k = 1:numel(phases)
    c = addComponent(empArch, phases(k));
    addP(c.Architecture, "In",  "in",  fs);
    addP(c.Architecture, "Out", "out", fs);
    if phases(k) == "Combat"
        addP(c.Architecture, "EngagementResult", "out", ed);
        combat = c;
    end
    connect(prevOut, c.getPort("In"));
    prevOut = c.getPort("Out");
end
connect(prevOut, empArch.getPort("Out"));
connect(combat.getPort("EngagementResult"), empArch.getPort("EngagementResult"));

% ---------------------------------------------------------------------
% 5) Combat -> F2T2EA kill chain (EngagementData). Combat also passes the
%    FlightState through (the aircraft keeps flying during combat).
% ---------------------------------------------------------------------
combatArch = combat.Architecture;
connect(combatArch.getPort("In"), combatArch.getPort("Out"));  % FlightState passthrough
killChain = ["Find","Fix","Track","Target","Engage","Assess"];
prev = [];
for k = 1:numel(killChain)
    c = addComponent(combatArch, killChain(k));
    if killChain(k) == "Find"
        addP(c.Architecture, "Out", "out", ed);          % origin: output only
    else
        addP(c.Architecture, "In",  "in",  ed);
        addP(c.Architecture, "Out", "out", ed);
        connect(prev.getPort("Out"), c.getPort("In"));
    end
    prev = c;
end
connect(prev.getPort("Out"), combatArch.getPort("EngagementResult"));  % Assess -> result

% ---------------------------------------------------------------------
% 6) Capability tree: Aviate / Navigate / Communicate (pure decomposition)
% ---------------------------------------------------------------------
paf = addComponent(root, "ProvideAircraftFunctions");
pafArch = paf.Architecture;
aviate = addComponent(pafArch, "Aviate");
aviateArch = aviate.Architecture;
addComponent(aviateArch, ["GenerateLift","ProduceThrust","Maneuver", ...
                          "ManageFuel","MaintainStructuralIntegrity"]);
addComponent(pafArch, ["Navigate","Communicate"]);

% ---------------------------------------------------------------------
% 7) Top-level wiring
% ---------------------------------------------------------------------
connect(root.getPort("MissionStart"),        emp.getPort("In"));
connect(emp.getPort("Out"),                  root.getPort("MissionComplete"));
connect(emp.getPort("EngagementResult"),     root.getPort("EngagementResult"));

% ---------------------------------------------------------------------
% 8) Auto-layout + save
% ---------------------------------------------------------------------
systems = ["F16A_Functional", ...
           "F16A_Functional/ExecuteMissionProfile", ...
           "F16A_Functional/ExecuteMissionProfile/Combat", ...
           "F16A_Functional/ProvideAircraftFunctions", ...
           "F16A_Functional/ProvideAircraftFunctions/Aviate"];
for s = systems
    try Simulink.BlockDiagram.arrangeSystem(s); catch, end %#ok<CTCH>
end
save_system(modelName, char(modelFile));   % save into architecture/
set_param(modelName, "SimulationCommand", "update");

% ---------------------------------------------------------------------
% 9) Requirements traceability (Implement links: function -> requirement)
% ---------------------------------------------------------------------
origSet = slreq.load(origFile);
derSet  = slreq.load(derFile);

P = "F16A_Functional/";
MP = P + "ExecuteMissionProfile/";
CB = MP + "Combat/";
AV = P + "ProvideAircraftFunctions/Aviate/";
NC = P + "ProvideAircraftFunctions/";

% {componentPath, requirementSet, requirementId}
links = {
    MP+"Takeoff",  origSet,"REQ_F16A_001";  MP+"Accel",  origSet,"REQ_F16A_002";
    MP+"Climb",    origSet,"REQ_F16A_003";  MP+"Cruise", origSet,"REQ_F16A_004";
    MP+"Dash",     origSet,"REQ_F16A_005";  MP+"Combat", origSet,"REQ_F16A_006";
    MP+"Egress",   origSet,"REQ_F16A_007";  MP+"Cruise2",origSet,"REQ_F16A_008";
    MP+"Loiter",   origSet,"REQ_F16A_009";  MP+"Landing",origSet,"REQ_F16A_010";
    % Point performance 011-018 -> BOTH lift and thrust
    AV+"GenerateLift", origSet,"REQ_F16A_011";  AV+"ProduceThrust",origSet,"REQ_F16A_011";
    AV+"GenerateLift", origSet,"REQ_F16A_012";  AV+"ProduceThrust",origSet,"REQ_F16A_012";
    AV+"GenerateLift", origSet,"REQ_F16A_013";  AV+"ProduceThrust",origSet,"REQ_F16A_013";
    AV+"GenerateLift", origSet,"REQ_F16A_014";  AV+"ProduceThrust",origSet,"REQ_F16A_014";
    AV+"GenerateLift", origSet,"REQ_F16A_015";  AV+"ProduceThrust",origSet,"REQ_F16A_015";
    AV+"GenerateLift", origSet,"REQ_F16A_016";  AV+"ProduceThrust",origSet,"REQ_F16A_016";
    AV+"GenerateLift", origSet,"REQ_F16A_017";  AV+"ProduceThrust",origSet,"REQ_F16A_017";
    AV+"GenerateLift", origSet,"REQ_F16A_018";  AV+"ProduceThrust",origSet,"REQ_F16A_018";
    % Field length also phase-specific
    MP+"Takeoff",  origSet,"REQ_F16A_017";  MP+"Landing", origSet,"REQ_F16A_018";
    % Structural + payload release
    AV+"MaintainStructuralIntegrity", origSet,"REQ_F16A_019";
    CB+"Engage",   origSet,"REQ_F16A_021";
    % Derived placeholders D01-D09
    AV+"Maneuver",    derSet,"REQ_F16A_D01";  AV+"ManageFuel", derSet,"REQ_F16A_D02";
    NC+"Navigate",    derSet,"REQ_F16A_D03";  NC+"Communicate",derSet,"REQ_F16A_D04";
    CB+"Find",        derSet,"REQ_F16A_D05";  CB+"Fix",        derSet,"REQ_F16A_D06";
    CB+"Track",       derSet,"REQ_F16A_D07";  CB+"Target",     derSet,"REQ_F16A_D08";
    CB+"Assess",      derSet,"REQ_F16A_D09";
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

fprintf("Built %s with %d components and %d Implement links.\n", ...
    modelName, countComps(m.Architecture), size(links,1));

end

% =====================================================================
function p = addP(archObj, name, dir, iface)
%ADDP Add a typed architecture port (dictionary must be linked first).
p = addPort(archObj, name, dir);
p.setInterface(iface);
end

% =====================================================================
function n = countComps(arch)
%COUNTCOMPS Recursively count components under an architecture.
n = 0;
for c = arch.Components
    n = n + 1 + countComps(c.Architecture);
end
end
