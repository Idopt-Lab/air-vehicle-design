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
%        (SourceKind, Justification, TraceRef) on all 27 stereotypable
%        components -- the 30 in the tree less the 3 variant role wrappers,
%        which can carry no stereotype at all (D-013) -- turns
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
%     4. THE DECISION IS MADE HERE, OVER CONCRETE CANDIDATES. Three roles are
%        VARIANT COMPONENTS, each holding the competing parameterized
%        candidates that could fill it (D-002, D-003). A candidate carries the
%        TradeCandidate stereotype -- RealizesRole, RealizesKind, Mass_lb,
%        Benefit, TRL, UnitCost_USD, DataProvenance, Selected -- which is the
%        data F16APhysicalTradeStudy scores. Every number on it is tagged with
%        the F16ADataProvenance enumeration {Datasheet, Reference, Estimate,
%        Simulation}, because P is the only layer that carries numbers and so
%        the only layer that must say where each one came from (D-007).
%        Section 6c builds those candidates unselected -- nothing has won until
%        something has been scored -- and SECTION 7B THEN RUNS THE TRADE
%        (F16APhysicalTradeStudy), which selects one candidate per role, flips
%        its SourceKind to TradeWinner, and calls back into the Logical layer to
%        set the winning KIND. L presents the options; P decides (D-001).
%        See D-006, D-007, D-011, D-015.
%
%   Structure (30 components; the Aircraft component is the system-of-interest
%   that holds the OEW/cost MoMs). "|=" marks a VARIANT role -- the wrapper is
%   not a part, it is the question "which of these?" made structural:
%     F16A_Physical
%       |- Aircraft
%          |= Airframe        (variant, 2 candidates)
%          |     |- BlendedCrankedDelta -> Wing Fuselage HorizontalTail
%          |     |                         VerticalTail Nacelles Strakes
%          |     |- ConventionalTrapWing  (single lumped block)
%          |- Propulsion
%          |     |= Engine    (variant, 3 candidates)
%          |     |     |- F100_PW_200  F110_GE_100  TwinEngine_Surrogate
%          |     |- InletDuct          (common to all engine candidates, D-009)
%          |= FlightControls  (variant, 2 candidates)
%          |     |- FlyByWire  HydroMechanical
%          |- FuelSystem      |- FwdFuselageTank AftFuselageTank WingTank
%          |- LandingGear  |- Avionics  |- Electrical  |- Hydraulics
%          |- ECS  |- ArmamentSupport  |- SecondaryStructure
%
%   ASYMMETRIC DETAIL IS DELIBERATE (D-003): only the candidate that carries
%   the Brandt decomposition is decomposed. The six structural parts are the
%   same parts, with the same Brandt masses, as before this restructure -- they
%   simply moved one level down, under BlendedCrankedDelta. Detailing
%   ConventionalTrapWing to match would mean inventing six part masses and six
%   composite fractions for an aircraft that was never built.
%
%   The candidates are built with the ACTIVE choice at BlendedCrankedDelta /
%   F100_PW_200 / FlyByWire. Between section 3 and section 7b that is a
%   PLACEHOLDER, NOT A DECISION -- the same convention generate_f16a_logical.m
%   uses -- and section 7b then re-asserts it FROM THE SCORE. The trade picks
%   those same three, which is why the active configuration still rolls up to
%   OEW = 19,980.73 lb: a trade that selects the production configuration
%   cannot change what the production aeroplane weighs. That agreement is the
%   point of a validated example, not a coincidence.
%
%   Leaf masses on the ACTIVE path are Brandt F-16A ground-truth weights (lbf,
%   design point W_TO = 31,377 lb) and sum to OEW ~= 19,980.7 lb. The fuel
%   tanks carry 0 dry mass (tankage is integral to the wet wing/fuselage;
%   internal fuel is a consumable, not empty weight) -- a deliberate "not every
%   part adds to OEW" lesson. Airframe-less-engine = OEW - Engine ~= 15,250.5
%   lb is the standard airframe-unit-weight convention (NOT a structural-group
%   sum).
%
%   Three roll-ups (see F16APhysical*Rollup). All three report the ACTIVE
%   configuration -- a roll-up over every candidate would be meaningless -- and
%   they run in section 9, AFTER the trade study of section 7b, so what they
%   measure is the configuration the trade SELECTED rather than the placeholder
%   the build happened to start from:
%     * Mass    -> OEW (native instantiate/iterate; a MoM to minimize).
%     * Material-> airframe mass-weighted composite fraction (~0.1928 with
%                  BlendedCrankedDelta active), the "verified by" side of
%                  REQ_F16A_022 (composite <= 20%).
%     * Fuel    -> available internal fuel capacity (~6300 lb), the "available"
%                  side of REQ_F16A_P01 (fuel-volume sufficiency).
%
%   Realization (logical role -> physical part), 9 roles, 14 edges. A role is
%   realized by the CANDIDATES that could fill it, not by the variant wrapper:
%     Airframe            -> BlendedCrankedDelta, ConventionalTrapWing;
%     PropulsionSystem    -> Engine/F100_PW_200, Engine/F110_GE_100,
%                            Engine/TwinEngine_Surrogate, InletDuct;
%     FlightControlSystem -> FlyByWire, HydroMechanical;
%     FuelSystem -> FuelSystem; LandingGear -> LandingGear;
%     AvionicsSuite -> Avionics; CommunicationSystem -> Avionics;
%     WeaponSystem -> ArmamentSupport; MissionSystemsBay -> ArmamentSupport.
%   The 1->many teaching moment MOVED: it used to be Airframe fanning out to
%   its six structural parts (decomposition of one role). It is now
%   PropulsionSystem fanning out to FOUR targets, and those four are two
%   different kinds of "many" in one edge set -- three MUTUALLY EXCLUSIVE
%   engine candidates (pick one) plus the InletDuct that every one of them
%   needs (D-009). Realization does not distinguish the two; the variant
%   structure does.
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
%   The DECISION requirements REQ_F16A_L01..L03 are a separate matter: they are
%   Implement-linked from the winning LOGICAL kinds by the trade study in
%   section 7b, not from anything in this model, because what implements
%   "single engine was selected" is the selected option, not a part (D-010).
%
%   BUILD ORDER, and why it is this order:
%     build (3-5) -> stereotypes and parameters (6-6c) -> realization (7)
%     -> TRADE (7b) -> requirement links (8) -> roll-ups (9)
%   The trade needs the stereotypes to have data to read and the allocation set
%   to already name the candidates; the roll-ups need the trade to have run, or
%   they would report a configuration nobody chose.
%
%   Idempotent: re-run to regenerate from scratch. Requires the L model and the
%   requirement sets to exist first (run generate_f16a_logical.m and the three
%   requirement generators before this) -- including
%   requirements/f16a_logical_derived.slreqx, which is where section 7b records
%   the decisions.
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
%       (D-013, Stage-0 finding 4). Reach those choices with getChoices -- NOT
%       with .Architecture.Components, which returns them on a freshly built
%       in-memory model but ZERO on the same model saved and reloaded (finding
%       6). Every tree walk in this file (applyStereotypeToTree,
%       assertRationaleComplete, countComps) special-cases a VariantComponent
%       for exactly those two reasons, and each says so at the point it does.
%     * Variants: addVariantComponent / addChoice / setActiveChoice, wrapped in
%       addVariantRole below (the same helper generate_f16a_logical.m uses).
%       getChoices returns choices ALPHABETICALLY, not in creation order
%       (finding 5), so a choice is always addressed BY NAME. Variant boundary
%       ports are not created by addPort on the variant's architecture: add the
%       port to every choice, then updatePortsFromChoices(vc, Mode="addPorts").
%     * ARCHITECTURE paths gain the choice level
%       ("Aircraft/Airframe/BlendedCrankedDelta/Wing") -- every lookup here is
%       written that way. INSTANCE paths do not: the analysis instance FLATTENS
%       the variant (finding 3), which is why the roll-ups still read
%       ".../Aircraft/Airframe". Two path spaces; use the right one.
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
%   THE THREE VARIANT ROLE WRAPPERS GET NO ROW, AND MUST NOT. Airframe,
%   Propulsion/Engine and FlightControls are systemcomposer.arch.
%   VariantComponent objects, and applyStereotype ERRORS on one (Stage-0
%   finding 4, D-013) -- they have no Rationale property to set. That is not a
%   workaround for a tool limitation, it is the right answer: a variant wrapper
%   is not a part, it is the QUESTION "which of these?", and a question has no
%   reason to exist independent of its answers. Its justification lives in its
%   candidates, one per option. Both tree walks below (applyStereotypeToTree,
%   assertRationaleComplete) skip a VariantComponent BY CLASS and descend into
%   getChoices instead, so this is enforced rather than remembered: 30
%   components minus 3 wrappers = the 27 rows here, and assertRationaleComplete
%   ABORTS the generator if any of the 27 is missing.
%
%   Writing convention: an enum value goes in FULLY QUALIFIED AND UNQUOTED
%   ("F16ASourceKind.TradeWinner"); a string value is evaluated as a MATLAB
%   expression and so must be quoted (quoteLit below). Both read back WITH the
%   quotes -- strip with erase(..., "'"), as MeasureOfMerit.Goal already does.
%
%   CANDIDATE ROWS: all seven candidates are TradeAlternative, not TradeWinner.
%   That is accurate rather than pessimistic -- no trade has run at this point
%   in the build, so nothing has won, and a candidate that claimed to be the
%   winner before the study executed would be recording a decision that was
%   never made. Section 7b runs F16APhysicalTradeStudy, which flips the three
%   winners to TradeWinner and rewrites every Justification here to state the
%   result it got; the text below is what the part says about itself BEFORE the
%   verdict, and the trade preserves it behind its own sentence rather than
%   overwriting it. Their TraceRef is the DECISION requirement for the role
%   (REQ_F16A_L01 propulsion, L02 flight control, L03 airframe), not a logical
%   role: a candidate is answerable to the decision it is an option in.
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
%   This is where the Physical layer earns its definition. A logical option is
%   a name; a physical candidate is a name PLUS the numbers somebody could
%   quote, measure or dispute -- and every one of those numbers arrives with a
%   provenance tag, because a sourced figure and a teaching guess must not look
%   alike in the model.
%
%   PROVENANCE, PLAINLY (D-007). Three candidates are tagged Reference: their
%   masses are the Brandt F-16A component weights already carried by this model
%   (Propulsion 4730.23, Airframe 6722.88, FlightControls 472.44 lb) -- the same
%   figures the mass roll-up produces for the active configuration, which is
%   why the trade's baselines and the model agree by construction. The other
%   four are tagged Estimate: their masses are ILLUSTRATIVE TEACHING VALUES
%   chosen to make the trade instructive. THEY ARE NOT F-16 DATA, no aircraft
%   was ever built to them, and they must never be cited as such. Each one --
%   and every other invented number in this model, including the Benefit and
%   TRL judgements below -- is inventoried in entry D-030 of
%   docs/07_decision_log.md. That entry is what D-007's "every Estimate is
%   listed in the decision log" points at; do not restate the figures here,
%   because a second list is a list that can disagree with the first.
%
%   READ THE TAG NARROWLY. There is ONE DataProvenance per candidate and it
%   qualifies the MASS -- the only measurable, disputable, dimensioned figure a
%   candidate carries. Benefit (1..10, 0 meaning "not set" -- D-033) and TRL
%   (1..9, 0 meaning "not set" -- D-021) are ENGINEERING JUDGEMENT on a declared
%   scale for every candidate including the Reference ones: they are a teaching
%   ranking, not a measured maturity assessment, and no tag on this stereotype
%   would make them otherwise. Do not read "Reference" as "these three numbers
%   are sourced".
%
%   MASS_LB HERE IS NOT PHYSICALITEM.MASS_LB. This is the TRADED figure: the
%   number the candidate is scored on, a property of the candidate as an
%   OPTION. PhysicalItem.Mass_lb is the number the roll-up sums, a property of
%   the candidate as a PART. For the six LEAF candidates the two agree
%   trivially -- a lumped block is its own subtotal. For BlendedCrankedDelta,
%   the one candidate that is decomposed, they differ in kind: its
%   TradeCandidate.Mass_lb is 6722.88 (what the option weighs), while its
%   PhysicalItem.Mass_lb stays 0 because it is an INTERIOR node whose subtotal
%   the roll-up writes -- exactly as Airframe did before this restructure.
%
%   UNITCOST_USD IS NaN ON ALL SEVEN (D-005). Cost is a pending Measure of
%   Merit, not a modelled one; the trade drops it and renormalizes. Note the
%   spelling: string(num2str(NaN)), never string(NaN) -- the latter is
%   <missing> and setProperty rejects it.
%
%   SELECTED IS FALSE ON ALL SEVEN, HERE. The candidates are built unselected
%   because at this line nothing has been scored yet. Section 7b then runs
%   F16APhysicalTradeStudy, which sets Selected from the score -- and only then
%   does the active variant choice above stop being a placeholder. Do not
%   pre-select a winner here to "save a step": the value of this file is that
%   the model is in a defensible state at every line of it, and a candidate
%   marked selected before the trade would be a decision with no arithmetic
%   behind it.
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
%    wrapper is the open question; the candidates are the ways of answering it,
%    and each of them genuinely does realize the role -- which is precisely why
%    the trade is a real decision and not a formality. Allocating to the
%    wrapper instead would say "something in here realizes the role" and hide
%    the options the L layer went to the trouble of enumerating.
%
%    THE 1->MANY TEACHING MOMENT MOVED. It used to be Airframe -> six
%    structural parts: one role DECOMPOSED into the parts that together do the
%    job. It is now PropulsionSystem -> four targets, and those four mean two
%    different things in one edge set: three MUTUALLY EXCLUSIVE engine
%    candidates (exactly one will be built) plus the InletDuct that all three
%    need (D-009). Realization cannot tell those apart -- an allocation edge
%    says only "this part is part of realizing that role". The variant
%    structure is what carries the exclusivity, which is the point worth making
%    to a student: allocation and variation are different relations.
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
%    F16APhysicalTradeStudy discovers the candidates section 6c parameterized
%    (it reads them out of the model -- there is no candidate list in it),
%    scores each role with the declared value functions of D-015, and records
%    the outcome in four places: the active variant choice and
%    TradeCandidate.Selected here at P, the Rationale of every candidate here
%    at P, the active KIND plus SolutionOption.Selected/DecisionRef back at L,
%    and an Implement link from each winning kind to its decision requirement
%    REQ_F16A_L01..L03. It saves the P model, the L model, the decision
%    requirement set and the L model link set itself.
%
%    WHY IT RUNS HERE AND NOT SOMEWHERE ELSE IN THIS FILE.
%      * AFTER 6c, because the trade reads TradeCandidate -- with no parameters
%        there is nothing to score.
%      * AFTER 7, because the allocation edges name the candidates; building
%        realization against a set of options and then deciding is OOSEM's
%        order (allocate to concrete elements first, then evaluate), not ours
%        to reverse (docs/06_methodology.md).
%      * BEFORE 9, and this is the one that matters. The roll-ups measure the
%        ACTIVE configuration. Run them first and they would report whatever
%        placeholder section 3 happened to set; run them after the trade and
%        the OEW, composite fraction and fuel figures the shipped model carries
%        describe the aircraft the trade CHOSE. The whole restructure exists to
%        make that sentence true.
%
%    The trade selects the production configuration, so the active choice does
%    not actually move -- but it is now set BY the score rather than by the
%    order the generator wrote its candidates in, which is the difference
%    between a decision and a default.
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
    "REQ_F16A_P01 -> F16AFuelVerificationTest.");

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
%   VARIANT-SAFE, by construction rather than by luck (Stage-0 probe):
%     * applyStereotype ERRORS on a systemcomposer.arch.VariantComponent, so a
%       variant is skipped rather than stereotyped -- a role wrapper is not a
%       part and has nothing to justify; its candidates do (D-013). The
%       variant's instance node still reports the rolled-up mass.
%     * a variant's children are reached with getChoices, NEVER with
%       .Architecture.Components -- the latter returned the choices on a
%       freshly built in-memory model but ZERO on the same model saved and
%       reloaded, which would silently skip every candidate.
%   Both branches now carry real traffic: the P model has three variant roles,
%   and this walk stereotypes their seven candidates while leaving the three
%   wrappers alone. It was written this way one stage before it was needed and
%   did not have to change when they arrived.
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
%   A variant needs exactly one active choice to be a valid model, so one is
%   set here. Between this line and section 7b that active choice is a
%   PLACEHOLDER, NOT A DECISION -- the identical convention (and wording)
%   generate_f16a_logical.m uses for the kinds -- and section 7b re-asserts it
%   from the score. What makes it a decision is TradeCandidate.Selected, the
%   winner's Rationale.Justification and the Implement link to the decision
%   requirement (D-040); the active flag merely follows.
%
%   Deliberately kept API-compatible with the L generator's helper of the same
%   name, so the two layers' variant mechanics can be read side by side.
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
