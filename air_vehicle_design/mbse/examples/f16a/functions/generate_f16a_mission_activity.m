function generate_f16a_mission_activity()
%GENERATE_F16A_MISSION_ACTIVITY Build the mission profile as an ACTIVITY diagram.
%   Creates functions/F16A_MissionActivity.slx: the ten mission phases as
%   activity ACTIONS on a FlightState object flow, with Combat nested into the
%   F2T2EA kill chain.
%
%   Structure:
%     Start -> Takeoff -> Accel -> Climb -> Cruise -> Dash -> Combat
%           -> Egress -> Cruise2 -> Loiter -> Landing -> Done
%     Combat's behaviour IS a child activity:
%           Find -> Fix -> Track -> Target -> Engage -> Assess
%
%   WHY AN ACTIVITY AND NOT COMPONENTS. A mission profile is a behaviour: each
%   phase consumes an aircraft state and produces a lighter one. Modelled as
%   components it could not allocate to anything, which is why the phases were
%   excluded from the F->L allocation. As actions they allocate normally (D-059).
%
%   WHERE THE NUMBERS COME FROM. Each phase action carries
%   F16AMissionSegment('<phase>') as its BehaviorDefinition, so the model
%   records HOW its fuel is computed rather than storing a copy of the answer.
%   Duration is set from the same analysis.
%
%   Idempotent: re-run to regenerate from scratch. Needs functions/
%   F16A_Functional.sldd for the FlightState and EngagementData interfaces.

modelName    = "F16A_MissionActivity";
funcName     = "F16A_Functional";
useAllocName = "F16A_MissionUsesCapability";
thisDir   = f16aRoot();
fcnDir    = fullfile(thisDir, "functions");
reqDir    = fullfile(thisDir, "requirements");
dictFile  = fullfile(fcnDir, "F16A_Functional.sldd");
modelFile = fullfile(fcnDir, modelName + ".slx");
slmxFile  = fullfile(fcnDir, modelName + "~mdl.slmx");
useAllocFile = fullfile(fcnDir, useAllocName + ".mldatx");
origFile  = fullfile(reqDir, "f16a.slreqx");
derFile   = fullfile(reqDir, "f16a_functional_derived.slreqx");

addpath(fcnDir);
addpath(reqDir);

PHASES    = ["Takeoff","Accel","Climb","Cruise","Dash","Combat", ...
             "Egress","Cruise2","Loiter","Landing"];
KILLCHAIN = ["Find","Fix","Track","Target","Engage","Assess"];

% ---------------------------------------------------------------------
% 0) Idempotent cleanup
% ---------------------------------------------------------------------
% DROP IN-MEMORY REQUIREMENT ARTIFACTS FIRST, as every other generator does.
% Deleting the .slmx below is not enough on its own: the caller's slreq.load
% has usually already pulled THIS model's link set into memory, and a file
% delete does not evict it -- so section 6's 18 createLink calls would append
% to the stale set and save 18 MORE links on every run. Everything the caller
% built is saved before it calls this, so clearing costs nothing.
slreq.clear();
try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
try
    am = systemcomposer.openActivity(char(modelName));
    am.close();
catch %#ok<CTCH>
end
try bdclose(char(modelName)); catch, end %#ok<CTCH>
for f = [modelFile, slmxFile, useAllocFile, fullfile(fcnDir, modelName + ".slxc"), ...
         fullfile(thisDir, useAllocName + ".mldatx"), fullfile(pwd, useAllocName + ".mldatx")]
    if isfile(f); delete(f); end
end
if ~isfile(dictFile)
    error("generate_f16a_mission_activity:noDictionary", ...
        "The interface dictionary %s does not exist. Run " + ...
        "generate_f16a_functional first -- the activity reuses its " + ...
        "FlightState and EngagementData rather than declaring a second copy.", dictFile);
end

% ---------------------------------------------------------------------
% 1) Model + the EXISTING dictionary (no second copy of FlightState)
% ---------------------------------------------------------------------
am  = systemcomposer.createActivity(char(modelName));
am.linkDictionary(char(dictFile));
act = am.Activity;
fs  = am.TypesDictionary.getInterface("FlightState");
ed  = am.TypesDictionary.getInterface("EngagementData");

% ---------------------------------------------------------------------
% 2) The mission thread. addNode takes the NAME first, then a lowercase
%    type -- the reverse of what the argument names suggest (08_agent_team.md).
% ---------------------------------------------------------------------
mission = F16AMissionAnalysis();   % the numbers, before the actions that carry them

ini = act.addNode("Start", "initial");
fin = act.addNode("Done",  "activityfinal");

actions = cell(1, numel(PHASES));
for k = 1:numel(PHASES)
    actions{k} = act.addNode(PHASES(k), "action");
end

% FlightState spine: an out pin on every phase but the last, an in pin on every
% phase but the first, joined pin to pin. Takeoff starts the mission so it
% consumes nothing; Landing ends it so it produces nothing.
for k = 1:numel(PHASES)
    if k > 1
        p = actions{k}.addPin("StateIn", "in");    p.ObjectType = fs;
    end
    if k < numel(PHASES)
        p = actions{k}.addPin("StateOut", "out");  p.ObjectType = fs;
    end
end
for k = 1:numel(PHASES)-1
    actions{k}.getPin("StateOut").connect(actions{k+1}.getPin("StateIn"));
end
ini.connect(actions{1});                    % control flow in
actions{end}.connect(fin);                  % control flow out

% ---------------------------------------------------------------------
% 3) Bind each phase to the analysis, and record how long it takes.
%
%    COMBAT IS THE ONE EXCEPTION, and deliberately. An action has exactly one
%    ActionBehavior, and Combat's behaviour is the kill chain (section 4), so
%    it cannot also hold a MATLAB binding. Its fuel is still read from the same
%    analysis -- F16AMissionAnalysis calls F16AMissionSegment for all ten
%    phases regardless of what any action is bound to.
% ---------------------------------------------------------------------
for k = 1:numel(PHASES)
    row = mission.Table(mission.Table.Phase == PHASES(k), :);
    actions{k}.Duration = row.Time_min;
    if PHASES(k) ~= "Combat"
        actions{k}.setBehaviorType("MATLAB");
        actions{k}.BehaviorDefinition = char("F16AMissionSegment('" + PHASES(k) + "')");
    end
end

% ---------------------------------------------------------------------
% 4) Combat -> F2T2EA, as a CHILD ACTIVITY rather than a sub-tree of parts.
%    The engagement stays inside the phase that fights it.
% ---------------------------------------------------------------------
combat = actions{PHASES == "Combat"};
combat.setBehaviorType("Activity");
cAct = combat.ChildActivity;

cIni = cAct.addNode("Start", "initial");
cFin = cAct.addNode("Done",  "activityfinal");
steps = cell(1, numel(KILLCHAIN));
for k = 1:numel(KILLCHAIN)
    steps{k} = cAct.addNode(KILLCHAIN(k), "action");
    if k > 1
        p = steps{k}.addPin("EngagementIn", "in");    p.ObjectType = ed;
    end
    if k < numel(KILLCHAIN)
        p = steps{k}.addPin("EngagementOut", "out");  p.ObjectType = ed;
    end
end
for k = 1:numel(KILLCHAIN)-1
    steps{k}.getPin("EngagementOut").connect(steps{k+1}.getPin("EngagementIn"));
end
cIni.connect(steps{1});
steps{end}.connect(cFin);

% ---------------------------------------------------------------------
% 5) Save
% ---------------------------------------------------------------------
save_system(modelName, char(modelFile));   % save into functions/, like every other generator

% ---------------------------------------------------------------------
% 6) Implement links (action -> requirement).
%
%    THE LINK TAKES THE HANDLE, NOT THE ACTION. slreq.createLink(action, req)
%    fails with APIFailedToCreateLink; action.SimulinkHandle works
%    (08_agent_team.md). Note the asymmetry with the allocation set in
%    generate_f16a_logical, which wants the action OBJECT.
%
%    These eighteen used to hang off phase COMPONENTS in F16A_Functional.
%    They moved with the phases (D-059); nothing about what they assert changed.
% ---------------------------------------------------------------------
origSet = slreq.load(origFile);
derSet  = slreq.load(derFile);

phase = @(nm) actions{PHASES    == nm};
step  = @(nm) steps  {KILLCHAIN == nm};

% {actionObject, requirementSet, requirementId}
links = {
    % The ten mission phases, 1:1
    phase("Takeoff"),origSet,"REQ_F16A_001";  phase("Accel"),  origSet,"REQ_F16A_002";
    phase("Climb"),  origSet,"REQ_F16A_003";  phase("Cruise"), origSet,"REQ_F16A_004";
    phase("Dash"),   origSet,"REQ_F16A_005";  phase("Combat"), origSet,"REQ_F16A_006";
    phase("Egress"), origSet,"REQ_F16A_007";  phase("Cruise2"),origSet,"REQ_F16A_008";
    phase("Loiter"), origSet,"REQ_F16A_009";  phase("Landing"),origSet,"REQ_F16A_010";
    % Field length is phase-specific as well as a point-performance requirement
    phase("Takeoff"),origSet,"REQ_F16A_017";  phase("Landing"),origSet,"REQ_F16A_018";
    % Payload release, and the kill-chain placeholders D05-D09
    step("Engage"),  origSet,"REQ_F16A_021";
    step("Find"),    derSet, "REQ_F16A_D05";  step("Fix"),     derSet, "REQ_F16A_D06";
    step("Track"),   derSet, "REQ_F16A_D07";  step("Target"),  derSet, "REQ_F16A_D08";
    step("Assess"),  derSet, "REQ_F16A_D09";
};

for i = 1:size(links,1)
    req = find(links{i,2}, Id=char(links{i,3}));
    slreq.createLink(links{i,1}.SimulinkHandle, req);
end

save(origSet);
save(derSet);
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets); save(lnkSets(i)); end
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 7) Which capabilities each phase USES.
%
%    THE MECHANISM IS ALLOCATION; THE SEMANTIC IS USE. System Composer's
%    allocation editor is the only many-to-many relationship it offers, so it
%    is what records this -- but "Cruise -> GenerateLift" is not an allocation
%    in the usual sense. GenerateLift is not a part, it is not a decomposition
%    of Cruise (Climb and Dash use it too), and it is not a refinement. Cruise
%    REQUIRES the capability. The set is named for what it means (D-059).
%
%    Phases stop here rather than reaching through to the logical roles:
%    Cruise -> Airframe is just Cruise -> GenerateLift -> Airframe composed,
%    and every phase needs airframe, propulsion and fuel, so storing it would
%    add a nearly-full matrix that says almost nothing.
% ---------------------------------------------------------------------
funcModel = systemcomposer.loadModel(funcName);
AV = funcName + "/ProvideAircraftFunctions/Aviate/";
NC = funcName + "/ProvideAircraftFunctions/";
STRUCTURE = [AV+"GenerateLift", AV+"MaintainStructuralIntegrity"];
POWERED   = [AV+"ProduceThrust", AV+"ManageFuel"];
GUIDED    = [AV+"Maneuver", NC+"Navigate"];

% Every phase flies, so every phase uses the structural pair. What each adds
% beyond that is what distinguishes it.
uses = dictionary( ...
    "Takeoff", {[POWERED, GUIDED]}, ...
    "Accel",   {[POWERED, GUIDED]}, ...
    "Climb",   {[POWERED, GUIDED]}, ...
    "Cruise",  {[POWERED, GUIDED]}, ...
    "Dash",    {[POWERED, GUIDED]}, ...
    "Combat",  {[POWERED, GUIDED, NC+"Communicate"]}, ...
    "Egress",  {[POWERED, GUIDED]}, ...
    "Cruise2", {[POWERED, GUIDED]}, ...
    "Loiter",  {[POWERED, GUIDED]}, ...
    "Landing", {GUIDED});            % engine at idle: the phase does not need thrust

useAlloc = systemcomposer.allocation.createAllocationSet(useAllocName, modelName, funcName);
useScenario = useAlloc.getScenario("Scenario 1");
nUse = 0;
for k = 1:numel(PHASES)
    for capPath = [STRUCTURE, uses{PHASES(k)}]
        useScenario.allocate(actions{k}, funcModel.lookup(Path=char(capPath)));
        nUse = nUse + 1;
    end
end
useAlloc.save();
if isfile(fullfile(pwd, useAllocName + ".mldatx")) && ~isfile(useAllocFile)
    movefile(fullfile(pwd, useAllocName + ".mldatx"), useAllocFile);
end

fprintf("\nBuilt %s: %d phase actions on a FlightState flow, " + ...
    "%d bound to F16AMissionSegment, Combat nested into %d kill-chain actions, " + ...
    "%d Implement links, %d phase-uses-capability edges.\n", ...
    modelName, numel(PHASES), numel(PHASES)-1, numel(KILLCHAIN), size(links,1), nUse);
fprintf("Mission fuel %.2f lb over %.2f min.\n", ...
    mission.TotalFuel_lb, mission.TotalTime_min);

end
