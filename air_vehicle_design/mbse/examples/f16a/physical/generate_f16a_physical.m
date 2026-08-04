function generate_f16a_physical()
%GENERATE_F16A_PHYSICAL Build the F-16A Physical-layer architecture (RFLP "P").
%   Creates physical/F16A_Physical.slx and .sldd, the stereotype profile
%   F16A_PhysicalProps.xml, and the F16A_LogicalToPhysical.mldatx realization
%   allocation set (9 logical roles -> 14 edges). Two profile properties are
%   typed by the enumerations F16ASourceKind.m and F16ADataProvenance.m, which
%   must be on the path whenever the profile loads.
%
%   Where L says HOW in solution roles, P gives CONCRETE PARTS. Four teaching
%   ideas:
%     1. Roll-up analysis  -- a native System Composer parametric analysis sums
%        part masses up the tree to OEW at the Aircraft root.
%     2. Measures of Merit -- OEW and unit cost are objectives to MINIMIZE, not
%        thresholds. OEW comes from the roll-up; cost from a FUNCTION
%        (F16APhysicalCostModel), which is the contrast being drawn.
%     3. Every part answers why it exists -- a Rationale stereotype turns "why
%        is this here?" from a comment into a queryable property (D-006), with
%        SourceKind drawn from a validated enumeration rather than free text.
%     4. The decision is made HERE, over concrete candidates. Three roles are
%        VARIANT COMPONENTS holding the competing candidates that could fill
%        them; section 7b runs F16APhysicalTradeStudy, which selects one per
%        role and calls back to set the winning KIND at L. L presents the
%        options; P decides (D-001).
%
%   Structure (30 components). "|=" marks a VARIANT role -- not a part, but the
%   question "which of these?" made structural:
%     F16A_Physical
%       |- Aircraft
%          |= Airframe        (2 candidates)
%          |     |- BlendedCrankedDelta -> Wing Fuselage HorizontalTail
%          |     |                         VerticalTail Nacelles Strakes
%          |     |- ConventionalTrapWing  (single lumped block)
%          |- Propulsion
%          |     |= Engine    (3 candidates: F100_PW_200 F110_GE_100
%          |     |             TwinEngine_Surrogate)
%          |     |- InletDuct          (common to all engine candidates, D-009)
%          |= FlightControls  (2 candidates: FlyByWire HydroMechanical)
%          |- FuelSystem      |- FwdFuselageTank AftFuselageTank WingTank
%          |- LandingGear  |- Avionics  |- Electrical  |- Hydraulics
%          |- ECS  |- ArmamentSupport  |- SecondaryStructure
%
%   ASYMMETRIC DETAIL IS DELIBERATE (D-003): only the candidate carrying the
%   Brandt decomposition is decomposed. Detailing ConventionalTrapWing to match
%   would mean inventing six part masses for an aircraft never built.
%
%   Leaf masses on the ACTIVE path are Brandt ground truth (lbf, W_TO = 31,377
%   lb) and sum to OEW ~= 19,980.7 lb. The fuel tanks carry ZERO dry mass --
%   tankage is integral to the wet structure and fuel is a consumable, a
%   deliberate "not every part adds to OEW" lesson.
%
%   BUILD ORDER, and why: build (3-5) -> stereotypes and parameters (6-6c) ->
%   realization (7) -> TRADE (7b) -> requirement links (8) -> roll-ups (9).
%   The trade needs the stereotypes to have data to read and the allocation set
%   to name the candidates; the roll-ups must run after the trade or they
%   report a configuration nobody chose.
%
%   Idempotent. Requires the L model and the requirement sets to exist first.
%
%   Two R2026a traps this file is written around, both in 08_agent_team.md:
%   a stereotype cannot be applied to a VariantComponent (reach its choices
%   with getChoices, never .Architecture.Components, which returns ZERO on a
%   reloaded model); and ARCHITECTURE paths carry the choice level while
%   INSTANCE paths do not, so the roll-ups read ".../Aircraft/Airframe".

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
logiDerFile = fullfile(reqDir, "f16a_logical_derived.slreqx");

if ~isfolder(physDir); mkdir(physDir); end

% Prerequisites: this generator loads the L model (allocation source, and the
% model the trade study writes its decision back into) and links into the base
% requirement set (cost MoM, materials), the physical-derived set (fuel volume)
% and -- through section 7b -- the logical-derived DECISION set.
if ~isfile(origFile)
    error("Missing %s. Run generate_f16a_requirements first.", origFile);
end
if ~isfile(physDerFile)
    error("Missing %s. Run generate_f16a_physical_derived_requirements first.", physDerFile);
end
% D-019 moved this dependency from L to P: L no longer needs the decision
% requirements, the trade study in section 7b does. Checked here rather than
% inside the trade so the generator fails before it has built anything.
if ~isfile(logiDerFile)
    error("Missing %s. Run generate_f16a_logical_derived_requirements first -- the " + ...
        "trade study in section 7b records its decisions there.", logiDerFile);
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
try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
try systemcomposer.profile.Profile.closeAll();          catch, end %#ok<CTCH>
try systemcomposer.close(modelName, true);              catch, end %#ok<CTCH>
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
%    interest that carries OEW + the MoMs) holds 11 assemblies. Two of them
%    (Airframe, FlightControls) are VARIANT roles holding competing
%    candidates; a third variant (Engine) sits one level down inside
%    Propulsion. See addVariantRole for the R2026a mechanics.
% ---------------------------------------------------------------------
aircraft = addComponent(root, "Aircraft");
ac = aircraft.Architecture;
% The nine assemblies that are plain components. Airframe and FlightControls
% are added just below as variant ROLES -- a role with more than one candidate
% is not a part, it is an open question, and it is modelled as one (D-002).
asmNames = ["Propulsion","LandingGear","FuelSystem","Avionics", ...
    "Electrical","Hydraulics","ECS","ArmamentSupport","SecondaryStructure"];
asm = addComponent(ac, asmNames);
propulsion = asm(1); fuelsys = asm(3); avionics = asm(4);
elec = asm(5); hyd = asm(6);

% --- The three variation points (D-003) -------------------------------
% Candidate names are addressed BY NAME everywhere below: getChoices returns
% them alphabetically, never in creation order (Stage-0 finding 5). The third
% argument names the ACTIVE choice explicitly rather than relying on position.
%
% Airframe: 2 candidates. Only the winner-shaped one is decomposed (D-003);
% ConventionalTrapWing is a single lumped block, because detailing it would
% mean inventing six part masses for an aircraft nobody built.
airframe = addVariantRole(ac, "Airframe", ...
    ["BlendedCrankedDelta","ConventionalTrapWing"], "BlendedCrankedDelta", ...
    {"ThrustIn","in",tm});
bcd = choiceNamed(airframe, "BlendedCrankedDelta");
% The six Brandt structural parts. SAME parts, SAME masses as before this
% restructure -- they moved one level down, under the candidate that owns them.
addComponent(bcd.Architecture, ...
    ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"]);

% FlightControls: 2 candidates, both leaves.
fctrl = addVariantRole(ac, "FlightControls", ...
    ["FlyByWire","HydroMechanical"], "FlyByWire", {"HydIn","in",hp});

% Propulsion: the ENGINE is the variation point, not the whole assembly. The
% InletDuct stays a plain part beside it, common to all three engine
% candidates (D-009) -- duplicating it inside each candidate would triple a
% part for no lesson, and pricing an inlet delta into the twin-engine
% surrogate would invent a number we cannot defend.
addVariantRole(propulsion.Architecture, "Engine", ...
    ["F100_PW_200","F110_GE_100","TwinEngine_Surrogate"], "F100_PW_200");
addComponent(propulsion.Architecture, "InletDuct");

% FuelSystem refines into three internal tanks (~2100 lb usable fuel each,
% ~6300 lb total). Their DRY mass is 0 (tankage is integral to the wet
% wing/fuselage); they carry a fuel CAPACITY that the fuel-volume roll-up sums
% for REQ_F16A_P01. That 3 x 2100 split is an ESTIMATE, and is tagged as one
% in section 6 -- see the comment there for why (D-023).
addComponent(fuelsys.Architecture, ...
    ["FwdFuselageTank","AftFuselageTank","WingTank"]);

% ---------------------------------------------------------------------
% 4) Light physical backbone (a few typed connections so interfaces exist).
%    Most parts stay port-free -- the teaching focus of P is decomposition,
%    roll-up and realization, not internal data flow.
%    NOTE: two-argument connect() only.
%    The two VARIANT roles already have their boundary ports: Airframe's
%    ThrustIn and FlightControls' HydIn were declared in section 3 and lifted
%    onto the variant boundary by updatePortsFromChoices, so a variant role
%    wires exactly like a plain component from here on.
% ---------------------------------------------------------------------
addP(propulsion.Architecture, "ThrustOut", "out", tm);
addP(elec.Architecture,       "PowerOut",  "out", ep);
addP(avionics.Architecture,   "PowerIn",   "in",  ep);
addP(hyd.Architecture,        "HydOut",    "out", hp);

connect(propulsion.getPort("ThrustOut"), airframe.getPort("ThrustIn"));
connect(elec.getPort("PowerOut"),        avionics.getPort("PowerIn"));
connect(hyd.getPort("HydOut"),           fctrl.getPort("HydIn"));

% ---------------------------------------------------------------------
% 5) Auto-layout + save
% ---------------------------------------------------------------------
% Cosmetic only; every call is guarded because a variant's choice subsystem is
% not always an arrangeable system path.
arrangePaths = modelName + [ "", "/Aircraft", "/Aircraft/Airframe", ...
    "/Aircraft/Airframe/BlendedCrankedDelta", "/Aircraft/Propulsion", ...
    "/Aircraft/Propulsion/Engine", "/Aircraft/FlightControls", ...
    "/Aircraft/FuelSystem"];
for p = arrangePaths
    try Simulink.BlockDiagram.arrangeSystem(p); catch, end %#ok<CTCH>
end
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
% UNITCOST_USD DEFAULTS TO NaN, NOT 0 (D-032) -- the same fail-safe rule D-021
% applied to TradeCandidate, closed here on the aircraft-level Measure of Merit.
% Nothing reads this default today: section 8 writes the cost-model result
% explicitly, and that result is NaN by D-005. It matters for the path that does
% not exist yet -- anything that applies MeasureOfMerit without writing the
% property would otherwise ship $0 as the aircraft's flyaway cost, and $0 is not
% a neutral placeholder but an unbeatably good one. A default that silently
% produces a plausible number is worse than one that stops the run.
mom.addProperty("UnitCost_USD", Type="double", DefaultValue="NaN"); % <- cost-model function
% String defaults are evaluated as MATLAB expressions, so quote the literal.
mom.addProperty("Goal",         Type="string", DefaultValue="'Minimize'");
% Material: composite fraction per part -> airframe composite roll-up (REQ_022).
% DataProvenance is on this stereotype too (D-031). Every composite fraction in
% this model is an invented number; until D-031 they carried no provenance tag
% at all -- precisely the gap D-023 closed for FuelTank, left open one
% stereotype over. An untagged invented number is not a smaller problem than a
% mistagged one.
mat = profile.addStereotype("Material", AppliesTo="Component");
mat.addProperty("CompositeFraction", Type="double", DefaultValue="0");   % 0..1 of part mass
mat.addProperty("DataProvenance",    Type="F16ADataProvenance", ...
    DefaultValue="F16ADataProvenance.Estimate");
% FuelTank: fuel capacity per tank -> available-fuel roll-up (REQ_P01).
% DataProvenance is on this stereotype too (D-023). A tank capacity is a number
% like any other, and "no agent invents a number" has to apply to the numbers
% that were already in the model, not only to the ones a new stage adds.
tank = profile.addStereotype("FuelTank", AppliesTo="Component");
tank.addProperty("FuelCapacity_lb", Type="double", DefaultValue="0");
tank.addProperty("DataProvenance",  Type="F16ADataProvenance", ...
    DefaultValue="F16ADataProvenance.Estimate");
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
% where each number came from, and whether it won. Applied to the seven
% candidates in section 6c.
%
% UNSET PARAMETERS MUST FAIL SAFE, NOT FAIL CHEAP (D-021). Three defaults here
% look wrong on purpose:
%   * UnitCost_USD defaults to NaN, not 0. Cost is NaN everywhere by D-005, and
%     under a ratio value function a silent $0 is not neutral -- it is either a
%     divide-by-zero or an infinitely good score. (DefaultValue="NaN" is
%     accepted on a double property; probe-confirmed.)
%   * TRL defaults to 0, which is OUTSIDE the valid 1..9 scale. int32 cannot
%     hold NaN, so the next best thing is a value that cannot be mistaken for
%     data: the trade study ERRORS on a candidate still carrying TRL 0 rather
%     than scoring it. The previous default of 5 was an invented number that
%     would have scored as a plausible mid-maturity candidate.
%   * Benefit defaults to 0, which is likewise OUTSIDE its usable 1..10 scale
%     and means "not set" (D-033). The trade study boxes Benefit at BOTH ends,
%     as it does TRL: v = B/10 carries the heaviest weight in the score, so an
%     out-of-range benefit is the one parameter a slipped decimal point can win
%     a trade with, and it is finite so no isfinite check would catch it.
tc = profile.addStereotype("TradeCandidate", AppliesTo="Component");
tc.addProperty("RealizesRole",   Type="string",  DefaultValue="'TBD'");
tc.addProperty("RealizesKind",   Type="string",  DefaultValue="'TBD'");
tc.addProperty("Mass_lb",        Type="double",  DefaultValue="0");
tc.addProperty("Benefit",        Type="double",  DefaultValue="0");     % <- outside 1..10 on purpose
tc.addProperty("TRL",            Type="int32",   DefaultValue="0");     % <- outside 1..9 on purpose
tc.addProperty("UnitCost_USD",   Type="double",  DefaultValue="NaN");   % <- D-005: cost is pending
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

% Leaf masses, lbf. Paths are ARCHITECTURE paths, so a candidate's parts sit
% one level deeper than before (".../Airframe/BlendedCrankedDelta/Wing").
% FuelSystem = 0 on purpose.
%
% PROVENANCE. Every mass below is a Brandt F-16A ground-truth weight
% (Reference) EXCEPT the four losing-candidate masses, which are illustrative
% teaching ESTIMATES and are marked inline. They are not F-16 data and must
% never be cited as such (D-007); each is inventoried, with the reasoning
% behind the figure, in entry D-030 of docs/07_decision_log.md -- the single
% place every invented number in this model is recorded.
%
% INTERIOR NODES ARE NOT LISTED. BlendedCrankedDelta is an interior node: its
% PhysicalItem.Mass_lb stays at the default 0 and the roll-up writes its
% subtotal (6722.88), exactly as Airframe did before this restructure. Do not
% confuse that with its TradeCandidate.Mass_lb in section 6c, which is also
% 6722.88 but means something different -- that is the TRADED figure, the
% number the candidate is scored on, and it is a property of the candidate as
% an option rather than a rolled-up sum of parts. They agree here because the
% traded figure was taken from the decomposition; for the lumped candidates
% (which have no parts) only the traded figure exists.
S = "F16A_Physical/Aircraft/";
AFC = S + "Airframe/BlendedCrankedDelta/";   % the decomposed airframe candidate
massRows = {
    AFC+"Wing",                    1785.95;
    AFC+"Fuselage",                3652.11;
    AFC+"HorizontalTail",           648.00;
    AFC+"VerticalTail",             360.00;
    AFC+"Nacelles",                 186.82;
    AFC+"Strakes",                   90.00;
    S+"Airframe/ConventionalTrapWing", 7300.00;  % ESTIMATE (teaching value)
    S+"Propulsion/Engine/F100_PW_200",         4730.23;
    S+"Propulsion/Engine/F110_GE_100",         5100.00;  % ESTIMATE (teaching value)
    S+"Propulsion/Engine/TwinEngine_Surrogate",6400.00;  % ESTIMATE (teaching value)
    S+"Propulsion/InletDuct",       728.60;
    S+"LandingGear",               1066.82;
    S+"FuelSystem",                   0.00;   % dry tankage integral to airframe; fuel is consumable
    S+"FlightControls/FlyByWire",   472.44;
    S+"FlightControls/HydroMechanical", 700.00;  % ESTIMATE (teaching value)
    S+"Avionics",                  2541.54;
    S+"Electrical",                 533.41;
    S+"Hydraulics",                 367.11;
    S+"ECS",                        360.84;
    S+"ArmamentSupport",            440.00;
    S+"SecondaryStructure",        2016.86;
};
for i = 1:size(massRows,1)
    c = lookup(m, Path=char(massRows{i,1}));
    setProperty(c, profileName + ".PhysicalItem.Mass_lb", string(massRows{i,2}));
end

% Airframe material split: CompositeFraction per structural part (fraction of
% the part's mass that is composite).
%
% EVERY FRACTION BELOW IS AN INVENTED NUMBER. Not one is F-16 data. All of them
% are tagged Estimate in the model (D-031) and inventoried in entry D-030 of
% docs/07_decision_log.md, which records why each was chosen.
%
% The six on the decomposed candidate are an educated guess grounded in real
% F-16 composite usage -- graphite/epoxy tail skins, carbon-fiber wing leading
% edge, fiberglass strakes; aluminum fuselage/nacelles -- AND THEN TUNED SO THE
% MASS-WEIGHTED AIRFRAME COMPOSITE FRACTION SITS WITHIN THE 20% CAP OF
% REQ_F16A_022. Read that literally: these are numbers picked to make a
% requirement pass. The materials roll-up therefore demonstrates that the
% roll-up and the constraint check WORK; it is not evidence that the F-16A
% meets a composite cap, and must not be quoted as if it were.
%
% ConventionalTrapWing gets ONE fraction for the whole lumped block, so the
% materials roll-up is DEFINED whichever airframe candidate is active -- an
% undefined constraint on the inactive branch would be a hole in REQ_F16A_022
% the moment the trade picked differently. Its value is an ESTIMATE on the
% argument that a conventional aluminium trapezoidal-wing airframe of this era
% carries less composite than the blended cranked delta, whose graphite/epoxy
% tail skins dominate that candidate's fraction; see D-030.
compRows = {
    AFC+"Wing",                        0.15;
    AFC+"Fuselage",                    0.10;
    AFC+"HorizontalTail",              0.55;
    AFC+"VerticalTail",                0.70;
    AFC+"Nacelles",                    0.05;
    AFC+"Strakes",                     0.50;
    S+"Airframe/ConventionalTrapWing", 0.12;   % ESTIMATE (whole-block value)
};
for i = 1:size(compRows,1)
    c = lookup(m, Path=char(compRows{i,1}));
    applyStereotype(c, profileName + ".Material");
    setProperty(c, profileName + ".Material.CompositeFraction", string(compRows{i,2}));
    % Tagged, not assumed (D-031): the tag is written on every row rather than
    % left to the stereotype default, so the model states the provenance of
    % each fraction even if the default is ever changed. Enum value written
    % fully qualified and unquoted.
    setProperty(c, profileName + ".Material.DataProvenance", "F16ADataProvenance.Estimate");
end

% Internal fuel tanks: 2100 lb usable each, 6300 lb total.
%
% TAGGED Estimate, NOT Reference (D-023). Brandt's mission fuel is 6296.30 lb
% (BrandtF16A worksheet Wt!B6). 3 x 2100 = 6300 is an EVEN SPLIT OF A ROUNDED
% NUMBER: neither the total nor the per-tank share is a sourced figure -- the
% real F-16A tankage is not three equal tanks -- so the honest tag is Estimate.
% The number is close enough to be useful for the fuel-volume roll-up and
% dishonest to present as ground truth, which is exactly the distinction the
% provenance vocabulary exists to make.
fuelRows = {
    S+"FuelSystem/FwdFuselageTank", 2100;
    S+"FuelSystem/AftFuselageTank", 2100;
    S+"FuelSystem/WingTank",        2100;
};
for i = 1:size(fuelRows,1)
    c = lookup(m, Path=char(fuelRows{i,1}));
    applyStereotype(c, profileName + ".FuelTank");
    setProperty(c, profileName + ".FuelTank.FuelCapacity_lb", string(fuelRows{i,2}));
    setProperty(c, profileName + ".FuelTank.DataProvenance", "F16ADataProvenance.Estimate");
end

% ---------------------------------------------------------------------
% 6b) Rationale: why does each of these parts exist? (D-006)
%
%   The point is that the answer is a QUERYABLE MODEL PROPERTY and not a
%   comment: you can ask the model for every ConstraintDriven part, or for
%   everything Electrical is there to serve. SourceKind is drawn from the
%   F16ASourceKind enumeration, so the vocabulary is validated; TraceRef names
%   what the part is answerable to -- a logical role, a requirement, or (for
%   supporting infrastructure) the physical part it serves.
%
%   The four SupportingInfrastructure parts realize NO logical role. Two of
%   their dependencies are real MODELLED port connections from section 4 --
%   Electrical -> Avionics on ElecPower, Hydraulics -> FlightControls on
%   HydPower; ECS and SecondaryStructure serve thermally and structurally with
%   no modelled port.
%
%   THE THREE VARIANT ROLE WRAPPERS GET NO ROW, AND MUST NOT (D-013). That is
%   not a workaround for applyStereotype erroring on them -- it is the right
%   answer: a wrapper is not a part, it is the QUESTION "which of these?", and
%   a question has no reason to exist independent of its answers. 30 components
%   minus 3 wrappers = the 27 rows here, and assertRationaleComplete ABORTS the
%   generator if any is missing.
%
%   Writing convention: an enum value goes in fully qualified and UNQUOTED
%   ("F16ASourceKind.TradeWinner"); a string value is evaluated as an
%   expression and must be QUOTED (quoteLit below). Both read back with the
%   quotes -- strip with erase(..., "'").
%
%   ALL SEVEN CANDIDATES ARE TradeAlternative HERE, not TradeWinner: no trade
%   has run at this point, so nothing has won. Section 7b flips the three
%   winners and adds its own sentence in front of the text below rather than
%   overwriting it. Their TraceRef is the DECISION requirement for the role,
%   not a logical role -- a candidate is answerable to the decision it is an
%   option in.
% ---------------------------------------------------------------------
% Logical-role path prefix. Section 7 keeps its own copy (as L) so each section
% stays readable on its own; both are the same string.
LR = "F16A_Logical/";
% {component path, SourceKind (unquoted enum), Justification, TraceRef}
ratRows = {
    "F16A_Physical/Aircraft", "F16ASourceKind.SatisfiesRequirement", ...
        "Exists as the system of interest: the single deliverable the program buys, and therefore the only level at which empty weight and unit flyaway cost can be stated as objectives to minimize.", ...
        "REQ_F16A_026";

    S+"Airframe/BlendedCrankedDelta", "F16ASourceKind.TradeAlternative", ...
        "Exists as the airframe candidate that blends a cranked-delta wing into the fuselage: it buys a large wing area and vortex-stable high-alpha behaviour for very little wetted area, carries its fuel and stores inside the blend rather than in add-on volume, and is the only candidate whose structure is decomposed here because it is the one the Brandt component weights describe.", ...
        "REQ_F16A_L03";
    AFC+"Wing", "F16ASourceKind.RealizesFunction", ...
        "Exists because lift has to be produced by a dedicated surface; it also provides the span for roll control, the store stations, and the wet volume the fuel system uses.", ...
        LR+"Airframe";
    AFC+"Fuselage", "F16ASourceKind.RealizesFunction", ...
        "Exists to house the pilot, engine, fuel and avionics in one load-carrying body and to react the wing, tail and landing-gear loads into a single structure.", ...
        LR+"Airframe";
    AFC+"HorizontalTail", "F16ASourceKind.RealizesFunction", ...
        "Exists to supply the pitching moment needed to trim and maneuver the aircraft, which the wing alone cannot generate about the center of gravity.", ...
        LR+"Airframe";
    AFC+"VerticalTail", "F16ASourceKind.RealizesFunction", ...
        "Exists to supply the directional stability and yaw control authority that a wing-body has no way to produce on its own.", ...
        LR+"Airframe";
    AFC+"Nacelles", "F16ASourceKind.RealizesFunction", ...
        "Exists to enclose and support the installed engine, feeding its thrust and inertia loads into the fuselage structure rather than through the engine case.", ...
        LR+"Airframe";
    AFC+"Strakes", "F16ASourceKind.RealizesFunction", ...
        "Exists to shed a controlled vortex over the wing root at high angle of attack, sustaining lift and departure resistance well past the angle at which a plain wing would stall.", ...
        LR+"Airframe";
    S+"Airframe/ConventionalTrapWing", "F16ASourceKind.TradeAlternative", ...
        "Exists as the conservative airframe candidate: a discrete aluminium trapezoidal wing bolted to a conventional fuselage, which buys a mature, low-risk structure that any 1970s airframer could build and stress, at the cost of more structural weight, less internal volume and none of the vortex-lift high-alpha behaviour the blended layout gets for free. Kept in the model so the airframe decision stays auditable.", ...
        "REQ_F16A_L03";

    S+"Propulsion", "F16ASourceKind.RealizesFunction", ...
        "Exists to realize the logical PropulsionSystem role, turning stored fuel energy into the thrust without which no other flight function is available.", ...
        LR+"PropulsionSystem";
    S+"Propulsion/Engine/F100_PW_200", "F16ASourceKind.TradeAlternative", ...
        "Exists as the single-engine candidate already in production and already qualified: one high-bypass-for-its-class afterburning turbofan sized to give this airframe a thrust-to-weight above one, which is what buys the acceleration, climb and sustained-turn performance the mission demands. Its appeal is maturity and installed mass, not peak thrust.", ...
        "REQ_F16A_L01";
    S+"Propulsion/Engine/F110_GE_100", "F16ASourceKind.TradeAlternative", ...
        "Exists as the higher-thrust single-engine candidate: it would buy more installed thrust and a wider stall-free operating margin from the same single-engine installation, at the cost of a heavier engine and a maturity level that does not yet support a production commitment. It is the option that asks whether performance is worth waiting for.", ...
        "REQ_F16A_L01";
    S+"Propulsion/Engine/TwinEngine_Surrogate", "F16ASourceKind.TradeAlternative", ...
        "Exists as the twin-engine candidate: two smaller engines instead of one, which buys engine-out survivability and lets each engine run at a lower rating, at the cost of substantially more installed mass, a second set of accessories and a duplicated installation. It is the candidate that makes the single-vs-twin architectural question a real comparison rather than an assumption.", ...
        "REQ_F16A_L01";
    S+"Propulsion/InletDuct", "F16ASourceKind.RealizesFunction", ...
        "Exists to deliver the engine its demanded airflow with acceptable pressure recovery and distortion across the whole flight envelope, which a bare engine face cannot do. It sits beside the engine variant rather than inside any candidate because every engine candidate needs one, and the twin-engine surrogate's mass is deliberately not adjusted to absorb an inlet delta (D-009).", ...
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

    S+"FlightControls/FlyByWire", "F16ASourceKind.TradeAlternative", ...
        "Exists as the electrically signalled flight-control candidate: computers between the stick and the actuators, which buys the artificial stability that lets the aircraft be flown relaxed-static-stability -- smaller tail, less trim drag, better instantaneous turn -- and buys it in software rather than in structure. It is also the lightest candidate, because signal wires replace push rods, bellcranks and cable runs.", ...
        "REQ_F16A_L02";
    S+"FlightControls/HydroMechanical", "F16ASourceKind.TradeAlternative", ...
        "Exists as the mechanically signalled flight-control candidate: rods, cables and hydraulic boost from stick to surface, which buys a fully mature control path with no computer in the loop and no software to qualify, at the cost of extra weight and of forcing the aircraft to be statically stable in its own right. Kept in the model so the fly-by-wire decision is visibly a choice and not an assumption.", ...
        "REQ_F16A_L02";
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

% ---------------------------------------------------------------------
% 6c) TradeCandidate: the parameters the trade study scores (D-002, D-007).
%
%   A logical option is a name; a physical candidate is a name PLUS numbers
%   somebody could quote, measure or dispute -- each arriving with a provenance
%   tag, so a sourced figure and a teaching guess cannot look alike.
%
%   Three candidates are Reference (Brandt masses: Propulsion 4730.23, Airframe
%   6722.88, FlightControls 472.44 lb). The other four are Estimate --
%   ILLUSTRATIVE TEACHING VALUES, not F-16 data, inventoried in D-030. Do not
%   restate the figures anywhere: a second list can disagree with the first.
%
%   READ THE TAG NARROWLY. One DataProvenance per candidate, and it qualifies
%   the MASS. Benefit and TRL are engineering JUDGEMENT on a declared scale for
%   every candidate including the Reference ones (D-025).
%
%   MASS_LB HERE IS NOT PHYSICALITEM.MASS_LB. This is the TRADED figure, a
%   property of the candidate as an OPTION; PhysicalItem.Mass_lb is what the
%   roll-up sums, a property of it as a PART. They agree trivially for the six
%   leaf candidates. For BlendedCrankedDelta they differ in kind: 6722.88 as an
%   option, 0 as an interior node whose subtotal the roll-up writes.
%
%   Note the NaN spelling: string(num2str(NaN)), never string(NaN) -- the
%   latter is <missing> and setProperty rejects it.
%
%   SELECTED IS FALSE ON ALL SEVEN HERE, because nothing has been scored yet.
%   Section 7b sets it from the score. Do not pre-select a winner to save a
%   step -- the value of this file is that the model is defensible at every
%   line of it, and a candidate selected before the trade is a decision with no
%   arithmetic behind it.
%
%   {path, RealizesRole, RealizesKind, Mass_lb, TRL, Benefit, DataProvenance}
% ---------------------------------------------------------------------
candRows = {
    S+"Propulsion/Engine/F100_PW_200",          "PropulsionSystem", "SingleEngine",          4730.23, 8, 8.2, "F16ADataProvenance.Reference";
    S+"Propulsion/Engine/F110_GE_100",          "PropulsionSystem", "SingleEngine",          5100.00, 4, 8.6, "F16ADataProvenance.Estimate";
    S+"Propulsion/Engine/TwinEngine_Surrogate", "PropulsionSystem", "TwinEngine",            6400.00, 6, 7.8, "F16ADataProvenance.Estimate";
    S+"Airframe/BlendedCrankedDelta",           "Airframe",         "BlendedCrankedDelta",   6722.88, 7, 9.5, "F16ADataProvenance.Reference";
    S+"Airframe/ConventionalTrapWing",          "Airframe",         "ConventionalTrapWing",  7300.00, 8, 6.5, "F16ADataProvenance.Estimate";
    S+"FlightControls/FlyByWire",               "FlightControlSystem", "FlyByWire",           472.44, 6, 9.0, "F16ADataProvenance.Reference";
    S+"FlightControls/HydroMechanical",         "FlightControlSystem", "HydroMechanical",     700.00, 9, 6.0, "F16ADataProvenance.Estimate";
};
for i = 1:size(candRows,1)
    c = lookup(m, Path=char(candRows{i,1}));
    applyStereotype(c, profileName + ".TradeCandidate");
    setProperty(c, profileName + ".TradeCandidate.RealizesRole",   quoteLit(candRows{i,2}));
    setProperty(c, profileName + ".TradeCandidate.RealizesKind",   quoteLit(candRows{i,3}));
    setProperty(c, profileName + ".TradeCandidate.Mass_lb",        string(candRows{i,4}));
    setProperty(c, profileName + ".TradeCandidate.TRL",            string(candRows{i,5}));
    setProperty(c, profileName + ".TradeCandidate.Benefit",        string(candRows{i,6}));
    setProperty(c, profileName + ".TradeCandidate.DataProvenance", candRows{i,7});
    % Cost: NaN via num2str -- string(NaN) is <missing> and setProperty rejects it.
    setProperty(c, profileName + ".TradeCandidate.UnitCost_USD",   string(num2str(NaN)));
    % Nothing has won yet; the trade study writes the winners.
    setProperty(c, profileName + ".TradeCandidate.Selected",       "false");
end

% Declare the two Measures of Merit on the Aircraft (Goal defaults to
% "Minimize"; values filled later: OEW by the roll-up, UnitCost_USD by the
% cost-model function).
applyStereotype(aircraft, profileName + ".MeasureOfMerit");
save_system(modelName, char(modelFile));

% ---------------------------------------------------------------------
% 7) Realization allocation: logical role -> physical part(s).
%
%    A ROLE IS REALIZED BY ITS CANDIDATES, NOT BY THE VARIANT WRAPPER. The
%    wrapper is the open question; each candidate genuinely does realize the
%    role, which is why the trade is a real decision. Allocating to the wrapper
%    would say "something in here realizes the role" and hide the options L
%    went to the trouble of enumerating.
%
%    PropulsionSystem -> four targets is the 1->many teaching moment, and those
%    four mean two different things in one edge set: three MUTUALLY EXCLUSIVE
%    engine candidates plus the InletDuct all three need (D-009). Realization
%    cannot tell them apart -- an edge says only "this part helps realize that
%    role". The variant structure carries the exclusivity. Allocation and
%    variation are different relations.
% ---------------------------------------------------------------------
srcModel = systemcomposer.loadModel(logiName);
L = "F16A_Logical/";
edges = {
    L+"Airframe",            S+"Airframe/BlendedCrankedDelta";
    L+"Airframe",            S+"Airframe/ConventionalTrapWing";
    L+"PropulsionSystem",    S+"Propulsion/Engine/F100_PW_200";
    L+"PropulsionSystem",    S+"Propulsion/Engine/F110_GE_100";
    L+"PropulsionSystem",    S+"Propulsion/Engine/TwinEngine_Surrogate";
    L+"PropulsionSystem",    S+"Propulsion/InletDuct";     % common to all three (D-009)
    L+"FuelSystem",          S+"FuelSystem";
    L+"FlightControlSystem", S+"FlightControls/FlyByWire";
    L+"FlightControlSystem", S+"FlightControls/HydroMechanical";
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
% 7b) THE DECISION. Everything above builds the question; this makes the call.
%
%    F16APhysicalTradeStudy DISCOVERS the candidates section 6c parameterized
%    (there is no candidate list in it), scores each role with D-015's declared
%    value functions, and records the outcome in four places: the active
%    variant choice and TradeCandidate.Selected at P, every candidate's
%    Rationale at P, the active KIND plus SolutionOption.Selected/DecisionRef
%    back at L, and an Implement link from each winning kind to REQ_F16A_L01..L03.
%
%    WHY IT RUNS HERE:
%      * AFTER 6c -- the trade reads TradeCandidate; no parameters, nothing to
%        score.
%      * AFTER 7 -- the allocation edges name the candidates. Allocate to
%        concrete elements, then evaluate, is OOSEM's order (06_methodology.md).
%      * BEFORE 9, and this is the one that matters. The roll-ups measure the
%        ACTIVE configuration, so running them first would report whatever
%        placeholder section 3 set. After the trade, the OEW, composite
%        fraction and fuel figures describe the aircraft the trade CHOSE.
%
%    The trade selects the production configuration, so the active choice does
%    not move -- but it is now set BY the score rather than by the order the
%    generator wrote its candidates in, which is the difference between a
%    decision and a default.
% ---------------------------------------------------------------------
trades = F16APhysicalTradeStudy();

% ---------------------------------------------------------------------
% 8) Cost Measure of Merit (from a cost-model function) + IMPLEMENT links.
%
%    Implement links (component -> requirement) are created here and show as
%    "Implemented by" in the Requirements Editor once the models are loaded
%    (see F16AOpenForReview).
%
%    "Verified by" links (requirement -> verification test) are NOT created
%    here. R2026a limitation: a MATLAB test file cannot be a link SOURCE, so
%    the programmatic slreq API cannot mint a working "Verified by" for a unit
%    test. Each is added MANUALLY in the Requirements Editor, linking a
%    requirement to its OWN verification test -- see docs/README.md. (Project
%    artifact tracking is NOT what makes them work; that was measured.)
%    This generator never touches the requirement-set link sets, so a manual
%    verify link is not overwritten by regeneration.
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
% The link stays on the VARIANT ROLE, not on a candidate. The composite cap
% binds the airframe whichever candidate wins -- which is why both candidates
% carry a CompositeFraction and the materials roll-up follows the active one.
% Linking it to BlendedCrankedDelta would leave REQ_F16A_022 unimplemented the
% moment the trade picked the other candidate. (A requirement link attaches to
% the block, not to a stereotype, so the D-013 restriction on applyStereotype
% does not apply here.)
linkImplement(airframeC, find(origSet, Id="REQ_F16A_022"));
% Fuel volume -> REQ_P01 (Implement, from the FuelSystem; Verify link added manually).
linkImplement(fuelSysC, find(physSet, Id="REQ_F16A_P01"));

save(origSet);
save(physSet);
savePhysicalLinkSets();   % F16A_Physical model link set (Implement links) only
save_system(modelName, char(modelFile));

fprintf("%s\n", "REMINDER: add the Verify links MANUALLY in the Requirements Editor -- " + ...
    "REQ_F16A_022 -> F16AMaterialsVerificationTest, " + ...
    "REQ_F16A_P01 -> F16AFuelVerificationTest, " + ...
    "REQ_F16A_025 -> F16AStaticMarginVerificationTest (one per test method).");

% ---------------------------------------------------------------------
% 9) Run the roll-ups so the shipped model already carries subtotals and the
%    OEW Measure of Merit, and print the materials/fuel figures. Each can be
%    re-run standalone.
%
%    THEY MEASURE THE DECIDED CONFIGURATION. All three follow the ACTIVE
%    choice, and section 7b has just set that from the score, so these are not
%    "the numbers of some configuration" -- they are the numbers of the one the
%    trade selected. Running them before 7b would have measured a placeholder.
% ---------------------------------------------------------------------
results = F16APhysicalMassRollup();
mats    = F16APhysicalMaterialsRollup();
fuel    = F16APhysicalFuelRollup();

nComp = countComps(m.Architecture);
% The CTPCT this fprintf draws is a FALSE POSITIVE -- 6 conversion specs, 6
% arguments -- and is deliberately left in place. THE MECHANISM IS NOT
% ESTABLISHED: three attempts to name the trigger were each refuted by a later
% probe. Two things are measured, and only these: it clears if the format is a
% single literal, and, separately, it clears if section 5's arrangePaths
% assignment is removed. No account yet explains both. DO NOT ACT ON A STATED
% CAUSE -- and do not restructure this call to chase it.
fmt = "Built %s with %d components (%d realization L->P edges). " + ...
    "OEW=%.2f lb; airframe composite=%.1f%% (REQ_022 cap 20%%); " + ...
    "available fuel=%.0f lb.\n";
fprintf(fmt, modelName, nComp, size(edges,1), results.OEW, ...
    100*mats.CompositeFraction, fuel.AvailableFuel_lb);
fprintf("Rationale set on %d of %d components (the %d variant role wrappers " + ...
    "cannot carry one -- D-013).\n", size(ratRows,1), nComp, nComp - size(ratRows,1));
% The trade has run (section 7b): report what it decided, read back from the
% ranked tables it returned rather than restated here.
% trades is a cell-valued dictionary: keys() already hands back a string array
% (reshaped to a row here only to keep the shape this line always had), and the
% ranked table is read with BRACES -- trades(role) would return the 1x1 cell
% holding it. The key order is the dictionary's INSERTION order (measured,
% Stage 3 -- a containers.Map would have sorted instead), which is the trade's
% own sorted role order, so this list still reads Airframe,
% FlightControlSystem, PropulsionSystem.
tradedRoles = reshape(keys(trades), 1, []);
picks = strings(1, numel(tradedRoles));
for i = 1:numel(tradedRoles)
    T = trades{tradedRoles(i)};
    picks(i) = tradedRoles(i) + " -> " + T.Candidate(T.Rank == 1) + ...
        " (" + T.Kind(T.Rank == 1) + ", score " + sprintf("%.5f", T.Score(T.Rank == 1)) + ")";
end
fprintf("%d TradeCandidates parameterized across %d variation points and TRADED " + ...
    "(section 7b): %s.\nThe active choice is now the trade's OUTPUT, not a " + ...
    "placeholder, and the roll-ups above measure it. The alternatives stay in the " + ...
    "model as the options that were rejected (D-002).\n", ...
    size(candRows,1), numel(tradedRoles), strjoin(picks, "; "));

end

% =====================================================================
function applyStereotypeToTree(arch, qualifiedStereotype)
%APPLYSTEREOTYPETOTREE Apply one stereotype to every component under an arch.
%   QUALIFIEDSTEREOTYPE is "<profile>.<stereotype>", e.g.
%   "F16A_PhysicalProps.Rationale". Used for both PhysicalItem and Rationale:
%   every part must be able to report a mass and a reason for existing.
%
%   VARIANT-SAFE by construction:
%     * applyStereotype ERRORS on a VariantComponent, so a variant is skipped
%       rather than stereotyped -- a role wrapper is not a part (D-013). Its
%       instance node still reports the rolled-up mass.
%     * a variant's children are reached with getChoices, NEVER with
%       .Architecture.Components, which returns ZERO on a reloaded model and
%       would silently skip every candidate.
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
%
%   IT MUST SKIP VARIANT WRAPPERS BY CLASS, or the generator aborts on a model
%   that is perfectly correct. A VariantComponent cannot have a stereotype
%   applied at all (Stage-0 finding 4), so it has no Rationale.Justification to
%   read and getProperty would fail on it -- and there is nothing to read even
%   in principle, because a wrapper is a question, not a part (D-013). The
%   check descends into getChoices instead, which is where the answers live.
if nargin < 3; prefix = ""; end
for c = arch.Components
    if isa(c, "systemcomposer.arch.VariantComponent")
        % Variant wrappers carry no Rationale (D-013); their choices do. Note
        % the wrapper's own name still appears in the error path below, so a
        % missing candidate rationale reads "Airframe/ConventionalTrapWing".
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
function vc = addVariantRole(parentArch, roleName, choiceNames, activeName, portSpecs)
%ADDVARIANTROLE Add a variant component (a role with competing candidates).
%   choiceNames : string array of candidate names.
%   activeName  : which candidate is made active. Named EXPLICITLY, never by
%                 position -- getChoices returns choices alphabetically, not in
%                 creation order (Stage-0 finding 5), and "first in the list"
%                 is not a decision.
%   portSpecs   : Nx3 cell {name, dir, iface}; added to EVERY candidate and
%                 propagated to the variant boundary so the role wires like a
%                 plain component. Omit or pass {} for a port-free variant.
%
%   A variant needs one active choice to be a valid model, so one is set here.
%   Between this line and section 7b it is a PLACEHOLDER, NOT A DECISION -- the
%   same convention generate_f16a_logical.m uses for the kinds. What makes it a
%   decision is TradeCandidate.Selected, the winner's Justification and the
%   Implement link (D-040); the active flag merely follows.
%
%   Kept API-compatible with the L generator's helper of the same name.
%   R2026a specifics learned the hard way (same as L):
%     * addVariantComponent seeds default choices ("Component", "Component1");
%       destroy any choice we did not ask for.
%     * setActiveChoice matches the name created by addChoice, so addChoice
%       rather than renaming the defaults.
%     * Variant boundary ports are NOT created by addPort on the variant's
%       architecture: add ports to each choice, then updatePortsFromChoices
%       (Mode="addPorts") lifts them onto the boundary.
if nargin < 5; portSpecs = {}; end
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
setActiveChoice(vc, activeName);
if ~isempty(portSpecs)
    updatePortsFromChoices(vc, Mode="addPorts");
end
end

% =====================================================================
function ch = choiceNamed(vc, name)
%CHOICENAMED One variant choice, addressed by NAME.
%   getChoices returns choices ALPHABETICALLY rather than in creation order
%   (Stage-0 finding 5), so indexing into it is a latent bug waiting for
%   somebody to rename a candidate. Every choice in this file is fetched here.
for c = getChoices(vc)
    if string(c.Name) == string(name); ch = c; return; end
end
% No silent empty return: an unmatched name is a typo in a path further down,
% and it must fail here rather than at a confusing lookup twenty lines later.
error("generate_f16a_physical:noSuchChoice", ...
    "Variant %s has no choice named %s.", string(vc.Name), string(name));
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
%   VARIANT-SAFE, and it has to be: a plain recursion over .Architecture
%   .Components returns the choices on a freshly built in-memory model but ZERO
%   on the same model saved and reloaded (Stage-0 finding 6), so this generator
%   would report 30 while a test reloading the model reported 17: the 7
%   candidates vanish, and so do the 6 structural parts beneath the decomposed
%   airframe candidate -- the two disagreeing for a reason nobody would find
%   quickly. (L's twin of this sentence loses only its 6 kinds, because they are
%   leaves; P's gap is bigger for exactly that reason.) getChoices is the only
%   reliable accessor. The variant WRAPPER is counted as a component (it is one
%   in the model tree) even though it can carry no stereotype.
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
