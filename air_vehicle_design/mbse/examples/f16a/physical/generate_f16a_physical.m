function generate_f16a_physical()
%GENERATE_F16A_PHYSICAL Build the F-16A Physical-layer architecture (RFLP "P").
%   Creates physical/F16A_Physical.slx (a System Composer model of the
%   concrete physical decomposition), its interface dictionary
%   physical/F16A_Physical.sldd, the stereotype profile
%   physical/F16A_PhysicalProps.xml, and the realization allocation set
%   physical/F16A_LogicalToPhysical.mldatx that ties each logical role
%   (RFLP "L") to the physical part(s) that realize it. Two of the profile's
%   properties are typed by the enumeration classes physical/F16ASourceKind.m
%   and physical/F16ADataProvenance.m, which must be on the MATLAB path
%   whenever the profile is loaded (physical/ is on the f16a project path).
%
%   Where the Logical layer says HOW in solution roles, the Physical layer
%   gives CONCRETE PARTS. Its three teaching ideas:
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
%     3. EVERY PART CAN ANSWER WHY IT EXISTS. A Rationale stereotype
%        (SourceKind, Justification, TraceRef) on all 23 components turns
%        "why is this here?" from a code comment into a queryable model
%        property (D-006). SourceKind is a validated vocabulary, not free
%        text -- the F16ASourceKind enumeration (D-011):
%          RealizesFunction         a logical role has to be realized
%          SatisfiesRequirement     a requirement demands the part directly
%          TradeWinner              it won the physical trade study
%          TradeAlternative         it lost, and is kept so the decision is
%                                   auditable
%          ConstraintDriven         it comes from a constraint of building an
%                                   airplane, not from a function above it
%          SupportingInfrastructure it exists only to serve other parts
%        TraceRef says what the part is answerable to: a logical role, a
%        requirement, or -- for the four SupportingInfrastructure parts
%        (Electrical, Hydraulics, ECS, SecondaryStructure) -- the physical
%        part it serves. Two of those dependencies are real modelled port
%        connections: Electrical -> Avionics on ElecPower, Hydraulics ->
%        FlightControls on HydPower.
%
%   Also declared here but NOT YET APPLIED TO ANYTHING: the TradeCandidate
%   stereotype (RealizesRole, RealizesKind, Mass_lb, Benefit, TRL,
%   UnitCost_USD, DataProvenance, Selected) and the F16ADataProvenance
%   enumeration {Datasheet, Reference, Estimate, Simulation} that types its
%   provenance tag. They are the data a concrete parameterized candidate
%   carries into the trade study; the candidates themselves arrive in the next
%   stage, and the vocabulary is defined first so the profile is complete
%   before any part depends on it. See D-006, D-007, D-011.
%
%   Structure (23 components; the Aircraft component is the system-of-interest
%   that holds the OEW/cost MoMs), 16 mass-bearing leaves:
%     F16A_Physical
%       |- Aircraft
%          |- Airframe     |- Wing Fuselage HorizontalTail VerticalTail Nacelles Strakes
%          |- Propulsion   |- Engine(F100-PW-200) InletDuct
%          |- FuelSystem   |- FwdFuselageTank AftFuselageTank WingTank
%          |- LandingGear  |- FlightControls  |- Avionics
%          |- Electrical   |- Hydraulics  |- ECS  |- ArmamentSupport  |- SecondaryStructure
%   Leaf masses are Brandt F-16A ground-truth weights (lbf, design point
%   W_TO = 31,377 lb) and sum to OEW ~= 19,980.7 lb. The fuel tanks carry 0
%   dry mass (tankage is integral to the wet wing/fuselage; internal fuel is a
%   consumable, not empty weight) -- a deliberate "not every part adds to OEW"
%   lesson. Airframe-less-engine = OEW - Engine ~= 15,250.5 lb is the standard
%   airframe-unit-weight convention (NOT a structural-group sum).
%
%   Three roll-ups (see F16APhysical*Rollup):
%     * Mass    -> OEW (native instantiate/iterate; a MoM to minimize).
%     * Material-> airframe mass-weighted composite fraction (~0.19), the
%                  "verified by" side of REQ_F16A_022 (composite <= 20%).
%     * Fuel    -> available internal fuel capacity (~6300 lb), the "available"
%                  side of REQ_F16A_P01 (fuel-volume sufficiency).
%
%   Realization (logical role -> physical part), 9 roles, 15 edges:
%     Airframe -> Wing/Fuselage/HorizontalTail/VerticalTail/Nacelles/Strakes;
%     PropulsionSystem -> Engine/InletDuct; FuelSystem -> FuelSystem;
%     FlightControlSystem -> FlightControls; LandingGear -> LandingGear;
%     AvionicsSuite -> Avionics; CommunicationSystem -> Avionics;
%     WeaponSystem -> ArmamentSupport; MissionSystemsBay -> ArmamentSupport.
%   Electrical, Hydraulics, ECS and SecondaryStructure realize NO single
%   logical role -- supporting infrastructure, the symmetric echo of L's
%   constraint-driven (function-less) roles. That is no longer only a comment:
%   each carries Rationale.SourceKind = SupportingInfrastructure and a TraceRef
%   naming the part it serves (section 6b).
%
%   Requirements: REQ_F16A_026 (cost) is a Measure of Merit (minimize), homed
%   here and Implement-linked from the Aircraft. REQ_F16A_022 (materials) is
%   Implement-linked from the Airframe; REQ_F16A_P01 (fuel volume) is
%   Implement-linked from the FuelSystem. Their "Verified by" links to the
%   verification tests (F16AMaterialsVerificationTest / F16AFuelVerificationTest)
%   are added MANUALLY in the Requirements Editor -- see section 8 and
%   docs/README.md (the programmatic slreq API can't set up a working
%   "Verified by" for a MATLAB unit test on its own).
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
%       quote the literal: DefaultValue="'Minimize'". They also READ BACK WITH
%       THE QUOTES, so every reader strips them: erase(value, "'").
%     * ENUMERATION-typed properties work (addProperty(..., Type="F16ASourceKind"))
%       and a plain MATLAB enumeration classdef is enough -- no int32 base
%       needed -- as long as the classdef is on the path. WRITE the value
%       FULLY QUALIFIED AND UNQUOTED ("F16ASourceKind.TradeWinner") or as a
%       QUOTED BARE MEMBER ("'TradeWinner'"); any other form errors. It READS
%       BACK QUOTED, exactly like a string property, so use the same
%       erase(..., "'") on the way out.
%     * applyStereotype ERRORS on a systemcomposer.arch.VariantComponent: a
%       stereotype goes on the variant's CHOICES, never on the role wrapper
%       (D-013). Reach those choices with getChoices -- NOT with
%       .Architecture.Components, which returns them on a freshly built
%       in-memory model but ZERO on the same model saved and reloaded. The
%       tree walks below (applyStereotypeToTree, assertRationaleComplete) are
%       already written that way; the P model has no variants yet.
%     * connect(src,dst) two-argument form only.
%   -----------------------------------------------------------------------

modelName   = "F16A_Physical";
logiName    = "F16A_Logical";
profileName = "F16A_PhysicalProps";
allocName   = "F16A_LogicalToPhysical";

thisDir  = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
physDir  = fullfile(thisDir, "physical");
logiDir  = fullfile(thisDir, "logical");
reqDir   = fullfile(thisDir, "requirements");
dictFile = fullfile(physDir, modelName + ".sldd");
modelFile= fullfile(physDir, modelName + ".slx");
slmxFile = fullfile(physDir, modelName + "~mdl.slmx");
profFile = fullfile(physDir, profileName + ".xml");
allocFile= fullfile(physDir, allocName + ".mldatx");
origFile = fullfile(reqDir, "f16a.slreqx");
physDerFile = fullfile(reqDir, "f16a_physical_derived.slreqx");

if ~isfolder(physDir); mkdir(physDir); end

% Prerequisites: this generator loads the L model (allocation source) and
% links into the base requirement set (cost MoM, materials) and the
% physical-derived set (fuel volume).
if ~isfile(origFile)
    error("Missing %s. Run generate_f16a_requirements first.", origFile);
end
if ~isfile(physDerFile)
    error("Missing %s. Run generate_f16a_physical_derived_requirements first.", physDerFile);
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
    % NOTE: the requirement-set link sets (f16a~slreqx.slmx,
    % f16a_physical_derived~slreqx.slmx) are intentionally NOT deleted here --
    % they can hold MANUAL Verify links (see section 8), which regeneration
    % must preserve.
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
airframe = asm(1); propulsion = asm(2); fuelsys = asm(4);
fctrl = asm(5); avionics = asm(6); elec = asm(7); hyd = asm(8);

addComponent(airframe.Architecture, ...
    ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"]);
addComponent(propulsion.Architecture, ["Engine","InletDuct"]);
% FuelSystem refines into three internal tanks (~2100 lb usable fuel each,
% ~6300 lb total, matching the Brandt internal-fuel weight). Their DRY mass
% is 0 (tankage is integral to the wet wing/fuselage); they carry a fuel
% CAPACITY that the fuel-volume roll-up sums for REQ_F16A_P01.
addComponent(fuelsys.Architecture, ...
    ["FwdFuselageTank","AftFuselageTank","WingTank"]);

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
% Material: composite fraction per part -> airframe composite roll-up (REQ_022).
mat = profile.addStereotype("Material", AppliesTo="Component");
mat.addProperty("CompositeFraction", Type="double", DefaultValue="0");   % 0..1 of part mass
% FuelTank: fuel capacity per tank -> available-fuel roll-up (REQ_P01).
tank = profile.addStereotype("FuelTank", AppliesTo="Component");
tank.addProperty("FuelCapacity_lb", Type="double", DefaultValue="0");
% Rationale: why does this part exist? (D-006). Applied to EVERY component
% below, so the question has a modelled answer rather than a code comment.
% SourceKind is a real MATLAB enumeration (D-011): the vocabulary is validated
% and shows as a dropdown in the Property Inspector instead of a free string.
% Enum and string DEFAULTS are evaluated as MATLAB expressions -- write an enum
% fully qualified and unquoted, a string literal quoted.
rat = profile.addStereotype("Rationale", AppliesTo="Component");
rat.addProperty("SourceKind",    Type="F16ASourceKind", ...
    DefaultValue="F16ASourceKind.RealizesFunction");
rat.addProperty("Justification", Type="string", DefaultValue="'TBD'");
rat.addProperty("TraceRef",      Type="string", DefaultValue="'TBD'");
% TradeCandidate: the parameterized data a physical candidate carries into the
% trade study -- which role and kind it realizes, the numbers it is scored on,
% where each number came from, and whether it won.
% DECLARED HERE, APPLIED TO NOTHING YET. The candidates it belongs on are the
% variant choices added in the next stage; the vocabulary is defined first so
% the profile is complete and the enumeration classes are exercised before any
% part depends on them. This is deliberate, not an oversight.
tc = profile.addStereotype("TradeCandidate", AppliesTo="Component");
tc.addProperty("RealizesRole",   Type="string",  DefaultValue="'TBD'");
tc.addProperty("RealizesKind",   Type="string",  DefaultValue="'TBD'");
tc.addProperty("Mass_lb",        Type="double",  DefaultValue="0");
tc.addProperty("Benefit",        Type="double",  DefaultValue="0");
tc.addProperty("TRL",            Type="int32",   DefaultValue="5");
tc.addProperty("UnitCost_USD",   Type="double",  DefaultValue="0");
tc.addProperty("DataProvenance", Type="F16ADataProvenance", ...
    DefaultValue="F16ADataProvenance.Estimate");
tc.addProperty("Selected",       Type="boolean", DefaultValue="false");
profile.save();
relocate(profileName + ".xml", profFile, thisDir);

applyProfile(m, profileName);

% Apply PhysicalItem AND Rationale to the Aircraft and every component beneath
% it: every part carries a mass (so an assembly can hold its written subtotal)
% and every part carries a reason for existing. The values follow below.
applyStereotype(aircraft, profileName + ".PhysicalItem");
applyStereotypeToTree(ac, profileName + ".PhysicalItem");
applyStereotype(aircraft, profileName + ".Rationale");
applyStereotypeToTree(ac, profileName + ".Rationale");

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

% Airframe material split: CompositeFraction per structural part (fraction of
% the part's mass that is composite). Educated guess grounded in real F-16
% composite usage -- graphite/epoxy tail skins, carbon-fiber wing leading
% edge, fiberglass strakes; aluminum fuselage/nacelles -- tuned so the
% mass-weighted airframe composite fraction (~0.19) sits within the 20% cap
% of the Brandt reference material mix (REQ_F16A_022).
compRows = {
    S+"Airframe/Wing",           0.15;
    S+"Airframe/Fuselage",       0.10;
    S+"Airframe/HorizontalTail", 0.55;
    S+"Airframe/VerticalTail",   0.70;
    S+"Airframe/Nacelles",       0.05;
    S+"Airframe/Strakes",        0.50;
};
for i = 1:size(compRows,1)
    c = lookup(m, Path=char(compRows{i,1}));
    applyStereotype(c, profileName + ".Material");
    setProperty(c, profileName + ".Material.CompositeFraction", string(compRows{i,2}));
end

% Internal fuel tanks: ~2100 lb usable each (~6300 lb total, ~ Brandt fuel).
fuelRows = {
    S+"FuelSystem/FwdFuselageTank", 2100;
    S+"FuelSystem/AftFuselageTank", 2100;
    S+"FuelSystem/WingTank",        2100;
};
for i = 1:size(fuelRows,1)
    c = lookup(m, Path=char(fuelRows{i,1}));
    applyStereotype(c, profileName + ".FuelTank");
    setProperty(c, profileName + ".FuelTank.FuelCapacity_lb", string(fuelRows{i,2}));
end

% ---------------------------------------------------------------------
% 6b) Rationale: why does each of these parts exist? (D-006)
%
%   The whole point is that the answer is a QUERYABLE MODEL PROPERTY and not a
%   comment: you can ask the model for every ConstraintDriven part, or for
%   everything the Electrical system is there to serve. SourceKind is drawn
%   from the F16ASourceKind enumeration, so the vocabulary is validated rather
%   than free text; TraceRef names WHAT the part is answerable to -- a logical
%   role, a requirement, or (for supporting infrastructure) the physical part
%   it serves.
%
%   The four SupportingInfrastructure parts are the interesting ones.
%   Electrical, Hydraulics, ECS and SecondaryStructure realize NO logical role;
%   until now their reason for existing lived only in the comment in section 7.
%   Their TraceRef points at what they serve, and two of those dependencies are
%   real MODELLED port connections built in section 4 -- Electrical -> Avionics
%   on ElecPower, Hydraulics -> FlightControls on HydPower. ECS and
%   SecondaryStructure serve their targets thermally and structurally, with no
%   modelled port.
%
%   Writing convention: an enum value goes in FULLY QUALIFIED AND UNQUOTED
%   ("F16ASourceKind.TradeWinner"); a string value is evaluated as a MATLAB
%   expression and so must be quoted (quoteLit below). Both read back WITH the
%   quotes -- strip with erase(..., "'"), as MeasureOfMerit.Goal already does.
% ---------------------------------------------------------------------
% Logical-role path prefix. Section 7 keeps its own copy (as L) so each section
% stays readable on its own; both are the same string.
LR = "F16A_Logical/";
% {component path, SourceKind (unquoted enum), Justification, TraceRef}
ratRows = {
    "F16A_Physical/Aircraft", "F16ASourceKind.SatisfiesRequirement", ...
        "Exists as the system of interest: the single deliverable the program buys, and therefore the only level at which empty weight and unit flyaway cost can be stated as objectives to minimize.", ...
        "REQ_F16A_026";

    S+"Airframe", "F16ASourceKind.RealizesFunction", ...
        "Exists to carry every flight and ground load through one structural path, realizing the logical Airframe role that must generate lift and maintain structural integrity.", ...
        LR+"Airframe";
    S+"Airframe/Wing", "F16ASourceKind.RealizesFunction", ...
        "Exists because lift has to be produced by a dedicated surface; it also provides the span for roll control, the store stations, and the wet volume the fuel system uses.", ...
        LR+"Airframe";
    S+"Airframe/Fuselage", "F16ASourceKind.RealizesFunction", ...
        "Exists to house the pilot, engine, fuel and avionics in one load-carrying body and to react the wing, tail and landing-gear loads into a single structure.", ...
        LR+"Airframe";
    S+"Airframe/HorizontalTail", "F16ASourceKind.RealizesFunction", ...
        "Exists to supply the pitching moment needed to trim and maneuver the aircraft, which the wing alone cannot generate about the center of gravity.", ...
        LR+"Airframe";
    S+"Airframe/VerticalTail", "F16ASourceKind.RealizesFunction", ...
        "Exists to supply the directional stability and yaw control authority that a wing-body has no way to produce on its own.", ...
        LR+"Airframe";
    S+"Airframe/Nacelles", "F16ASourceKind.RealizesFunction", ...
        "Exists to enclose and support the installed engine, feeding its thrust and inertia loads into the fuselage structure rather than through the engine case.", ...
        LR+"Airframe";
    S+"Airframe/Strakes", "F16ASourceKind.RealizesFunction", ...
        "Exists to shed a controlled vortex over the wing root at high angle of attack, sustaining lift and departure resistance well past the angle at which a plain wing would stall.", ...
        LR+"Airframe";

    S+"Propulsion", "F16ASourceKind.RealizesFunction", ...
        "Exists to realize the logical PropulsionSystem role, turning stored fuel energy into the thrust without which no other flight function is available.", ...
        LR+"PropulsionSystem";
    S+"Propulsion/Engine", "F16ASourceKind.RealizesFunction", ...
        "Exists as the thrust-producing machine itself, the part that fixes installed thrust-to-weight and therefore the acceleration, climb and sustained-turn performance the mission demands.", ...
        LR+"PropulsionSystem";
    S+"Propulsion/InletDuct", "F16ASourceKind.RealizesFunction", ...
        "Exists to deliver the engine its demanded airflow with acceptable pressure recovery and distortion across the whole flight envelope, which a bare engine face cannot do.", ...
        LR+"PropulsionSystem";

    S+"FuelSystem", "F16ASourceKind.RealizesFunction", ...
        "Exists to store the mission fuel and feed it to the engine at the demanded rate in every attitude, realizing the logical FuelSystem role.", ...
        LR+"FuelSystem";
    S+"FuelSystem/FwdFuselageTank", "F16ASourceKind.SatisfiesRequirement", ...
        "Exists to hold the forward share of the internal fuel the mission requires, placed ahead of the center of gravity so that burn sequencing can keep the aircraft in balance.", ...
        "REQ_F16A_P01";
    S+"FuelSystem/AftFuselageTank", "F16ASourceKind.SatisfiesRequirement", ...
        "Exists to hold the aft share of the internal fuel the mission requires, balancing the forward tank so the center of gravity stays within limits as fuel is consumed.", ...
        "REQ_F16A_P01";
    S+"FuelSystem/WingTank", "F16ASourceKind.SatisfiesRequirement", ...
        "Exists to turn volume the wing structure already encloses into usable tankage, meeting the internal-fuel requirement without growing the fuselage and relieving wing bending in flight.", ...
        "REQ_F16A_P01";

    S+"FlightControls", "F16ASourceKind.RealizesFunction", ...
        "Exists to convert pilot commands into surface deflections with the authority, rate and stability augmentation the logical FlightControlSystem role requires.", ...
        LR+"FlightControlSystem";
    S+"Avionics", "F16ASourceKind.RealizesFunction", ...
        "Exists to give the pilot the sensing, navigation and communication picture the kill chain runs on, and is the one part that realizes both the avionics-suite role and the communication role.", ...
        LR+"AvionicsSuite; " + LR+"CommunicationSystem";
    S+"ArmamentSupport", "F16ASourceKind.RealizesFunction", ...
        "Exists to mount, condition and release the stores, realizing both the weapon-employment role and the mission-systems bay that houses the equipment those weapons depend on.", ...
        LR+"WeaponSystem; " + LR+"MissionSystemsBay";

    S+"LandingGear", "F16ASourceKind.ConstraintDriven", ...
        "Exists because the aircraft has to support itself, take off and land on a runway at all; its geometry is set by the tipback and rollover limits, not by any function allocated from above.", ...
        "REQ_F16A_023; REQ_F16A_024";

    S+"Electrical", "F16ASourceKind.SupportingInfrastructure", ...
        "Exists only to serve the parts around it: it generates, converts and distributes the electrical power the avionics cannot run without, a dependency modelled explicitly as the ElecPower connection from its PowerOut port to the Avionics PowerIn port.", ...
        S+"Avionics";
    S+"Hydraulics", "F16ASourceKind.SupportingInfrastructure", ...
        "Exists only to serve the flight controls: it supplies the pressurized hydraulic power the actuators need to drive surfaces against air loads, a dependency modelled explicitly as the HydPower connection from its HydOut port to the FlightControls HydIn port.", ...
        S+"FlightControls";
    S+"ECS", "F16ASourceKind.SupportingInfrastructure", ...
        "Exists only because the avionics and the crew it serves need their bay and cockpit held inside temperature, pressure and humidity limits; unlike the electrical path this dependency is thermal and so carries no modelled port connection.", ...
        S+"Avionics";
    S+"SecondaryStructure", "F16ASourceKind.SupportingInfrastructure", ...
        "Exists to account for the fairings, doors, access panels and mountings that no primary structural member owns but that the airframe cannot be assembled or maintained without.", ...
        S+"Airframe";
};
for i = 1:size(ratRows,1)
    c = lookup(m, Path=char(ratRows{i,1}));
    setProperty(c, profileName + ".Rationale.SourceKind",    ratRows{i,2});
    setProperty(c, profileName + ".Rationale.Justification", quoteLit(ratRows{i,3}));
    setProperty(c, profileName + ".Rationale.TraceRef",      quoteLit(ratRows{i,4}));
end
% Guard: no part may ship with the placeholder rationale. Catches a component
% added without a matching ratRows entry (the failure mode this section exists
% to prevent) before the model is saved.
assertRationaleComplete(m.Architecture, profileName);

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
% 8) Cost Measure of Merit (from a cost-model function) + IMPLEMENT links.
%
%    Implement links (component -> requirement) are created here and show as
%    "Implemented by" in the Requirements Editor once the models are loaded
%    (see F16AOpenForReview).
%
%    "Verified by" links (requirement -> verification test) are NOT created
%    here. ISSUE (R2026a): the programmatic slreq API cannot produce a working
%    "Verified by" for a MATLAB unit test on its own -- that needs the
%    project's Digital Thread artifact tracking, a manual project setting. So
%    verify links are added MANUALLY in the Requirements Editor, linking each
%    requirement to its OWN verification test:
%        REQ_F16A_022  ->  F16AMaterialsVerificationTest
%        REQ_F16A_P01  ->  F16AFuelVerificationTest
%    (see docs/README.md "Verification links are added manually"). The
%    generator no longer touches the requirement-set link sets, so a manual
%    verify link is never overwritten by regeneration.
% ---------------------------------------------------------------------
unitCost = F16APhysicalCostModel(m);   % stub returns NaN ("not yet computed")
% num2str, not string(): string(NaN) is <missing>, which setProperty rejects.
setProperty(aircraft, profileName + ".MeasureOfMerit.UnitCost_USD", string(num2str(unitCost)));
save_system(modelName, char(modelFile));

origSet = slreq.load(origFile);
physSet = slreq.load(physDerFile);

airframeC = lookup(m, Path=char(S + "Airframe"));
fuelSysC  = lookup(m, Path=char(S + "FuelSystem"));

% Cost MoM -> REQ_026 (Implement, from the Aircraft).
linkImplement(aircraft, find(origSet, Id="REQ_F16A_026"));
% Materials -> REQ_022 (Implement, from the Airframe; Verify link added manually).
linkImplement(airframeC, find(origSet, Id="REQ_F16A_022"));
% Fuel volume -> REQ_P01 (Implement, from the FuelSystem; Verify link added manually).
linkImplement(fuelSysC, find(physSet, Id="REQ_F16A_P01"));

save(origSet);
save(physSet);
savePhysicalLinkSets();   % F16A_Physical model link set (Implement links) only
save_system(modelName, char(modelFile));

fprintf("%s\n", "REMINDER: add the Verify links MANUALLY in the Requirements Editor -- " + ...
    "REQ_F16A_022 -> F16AMaterialsVerificationTest, " + ...
    "REQ_F16A_P01 -> F16AFuelVerificationTest.");

% ---------------------------------------------------------------------
% 9) Run the roll-ups so the shipped model already carries subtotals and the
%    OEW Measure of Merit, and print the materials/fuel figures. Each can be
%    re-run standalone.
% ---------------------------------------------------------------------
results = F16APhysicalMassRollup();
mats    = F16APhysicalMaterialsRollup();
fuel    = F16APhysicalFuelRollup();

nComp = countComps(m.Architecture);
fmt = "Built %s with %d components (%d realization L->P edges). " + ...
    "OEW=%.2f lb; airframe composite=%.1f%% (REQ_022 cap 20%%); " + ...
    "available fuel=%.0f lb.\n";
fprintf(fmt, modelName, nComp, size(edges,1), results.OEW, ...
    100*mats.CompositeFraction, fuel.AvailableFuel_lb);
fprintf("Rationale set on %d of %d components. TradeCandidate is DECLARED " + ...
    "but applied to nothing yet -- the candidates it belongs on arrive in the " + ...
    "next stage.\n", size(ratRows,1), nComp);

end

% =====================================================================
function applyStereotypeToTree(arch, qualifiedStereotype)
%APPLYSTEREOTYPETOTREE Apply one stereotype to every component under an arch.
%   QUALIFIEDSTEREOTYPE is "<profile>.<stereotype>", e.g.
%   "F16A_PhysicalProps.Rationale". Used for both PhysicalItem and Rationale:
%   every part must be able to report a mass and a reason for existing.
%
%   VARIANT-SAFE, by construction rather than by luck (Stage-0 probe):
%     * applyStereotype ERRORS on a systemcomposer.arch.VariantComponent, so a
%       variant is skipped rather than stereotyped -- a role wrapper is not a
%       part and has nothing to justify; its candidates do (D-013). The
%       variant's instance node still reports the rolled-up mass.
%     * a variant's children are reached with getChoices, NEVER with
%       .Architecture.Components -- the latter returned the choices on a
%       freshly built in-memory model but ZERO on the same model saved and
%       reloaded, which would silently skip every candidate.
%   The P model has no variant components today; the candidates arrive in the
%   next stage, and this walk is written to meet them without changing.
for c = arch.Components
    if isa(c, "systemcomposer.arch.VariantComponent")
        for ch = getChoices(c)
            applyStereotype(ch, qualifiedStereotype);
            applyStereotypeToTree(ch.Architecture, qualifiedStereotype);
        end
    else
        applyStereotype(c, qualifiedStereotype);
        applyStereotypeToTree(c.Architecture, qualifiedStereotype);
    end
end
end

% =====================================================================
function s = quoteLit(txt)
%QUOTELIT Wrap a literal for a string-typed stereotype property.
%   A string property value is evaluated as a MATLAB expression, so the literal
%   has to arrive quoted ("'text'"); getProperty then hands it back WITH the
%   quotes, and every reader strips them with erase(..., "'") -- the convention
%   MeasureOfMerit.Goal and its test already use. An apostrophe inside the text
%   would close the literal early, so it is doubled (the MATLAB escape).
s = "'" + replace(string(txt), "'", "''") + "'";
end

% =====================================================================
function assertRationaleComplete(arch, profileName, prefix)
%ASSERTRATIONALECOMPLETE Fail if any part still carries the default Rationale.
%   Walks the same variant-safe path as applyStereotypeToTree and errors on the
%   first component whose Justification is still the 'TBD' placeholder, so a
%   newly added part cannot ship without an answer to "why do I exist?".
%   Reads with erase(..., "'"): string properties come back quoted.
%   PREFIX accumulates the component path for the error message (optional).
if nargin < 3; prefix = ""; end
for c = arch.Components
    if isa(c, "systemcomposer.arch.VariantComponent")
        % Variant wrappers carry no Rationale (D-013); their choices do.
        for ch = getChoices(c)
            checkOne(ch, prefix + string(c.Name) + "/" + string(ch.Name));
            assertRationaleComplete(ch.Architecture, profileName, ...
                prefix + string(c.Name) + "/" + string(ch.Name) + "/");
        end
    else
        checkOne(c, prefix + string(c.Name));
        assertRationaleComplete(c.Architecture, profileName, ...
            prefix + string(c.Name) + "/");
    end
end

    function checkOne(comp, pathStr)
        why = erase(string(getProperty(comp, ...
            char(profileName + ".Rationale.Justification"))), "'");
        if why == "" || why == "TBD"
            error("generate_f16a_physical:rationaleMissing", ...
                "Component %s has no Rationale.Justification -- add a row to ratRows.", ...
                pathStr);
        end
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
function linkImplement(srcComp, req)
%LINKIMPLEMENT Implement-link a component to a requirement.
%   Unconditional create: section 0's cleanup deletes the F16A_Physical model
%   link set before this runs, so re-running rebuilds the Implement links from
%   scratch with no duplicates -- the same pattern generate_f16a_functional.m
%   and generate_f16a_logical.m use. An earlier version guarded on
%   isempty(req.inLinks()), but a manual "Verify" link (test -> requirement) is
%   an INBOUND link to the requirement too, so once one existed the guard
%   wrongly skipped the Implement link -- regenerating then dropped
%   "Implemented by" for REQ_F16A_022 and REQ_F16A_P01.
if ~isempty(req)
    slreq.createLink(srcComp, req);
end
end

% =====================================================================
function savePhysicalLinkSets()
%SAVEPHYSICALLINKSETS Save only the F16A_Physical model link set (its Implement
%   links), leaving the functional/logical model link sets and every
%   requirement-set link set (which may hold MANUAL Verify links) untouched.
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), "F16A_Physical")
        save(lnkSets(i));
    end
end
end
