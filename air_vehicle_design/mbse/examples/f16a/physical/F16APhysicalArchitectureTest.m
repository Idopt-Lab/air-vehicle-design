classdef F16APhysicalArchitectureTest < matlab.unittest.TestCase
    %F16APHYSICALARCHITECTURETEST Verify the F-16A Physical-layer model (RFLP "P").
    %   A MACHINERY test: it asks "is the P model built correctly?", never
    %   "is this the right design?". The design verdicts live one per
    %   requirement in verification/.
    %
    %   COVERED HERE
    %     * Structure   -- 30 components: Aircraft, 11 assemblies (three of
    %       them VARIANT roles), the 7 trade candidates those variants hold,
    %       8 parts, 3 fuel tanks, each resolving at its expected path, the
    %       7 non-variant leaf assemblies childless.
    %     * Stereotypes -- PhysicalItem on every component that can carry one
    %       (all 30 minus the 3 variant role wrappers), Material on every
    %       airframe structural part, FuelTank on every tank, TradeCandidate
    %       on each of the 7 candidates.
    %     * Masses      -- the 16 mass-bearing leaves of the ACTIVE
    %       configuration against the Brandt ground truth; FuelSystem and the
    %       tanks carry zero OEW mass because fuel is a consumable.
    %     * Roll-up     -- self-consistency only: each assembly subtotal is
    %       the sum of its parts, OEW is the sum of the ACTIVE leaves (never
    %       the all-candidates sum), and airframe-less-engine is OEW minus
    %       engine.
    %     * Measures of Merit -- OEW and unit cost both exist with
    %       Goal = Minimize; cost is the uncomputed placeholder (NaN).
    %     * Realization -- the L->P allocation set exists, every one of the
    %       9 logical roles is a realization source, and the four
    %       supporting-infrastructure parts are deliberately not targets.
    %     * Requirements -- 022, 026 and P01 are Implement-linked at P.
    %     * Rationale (Stage 2) -- every part the architecture walk reaches
    %       carries the Rationale stereotype with a SourceKind drawn from
    %       the closed F16ASourceKind vocabulary, a non-empty TraceRef and a
    %       Justification of real length; the four infrastructure parts say
    %       SupportingInfrastructure explicitly; and both vocabularies are
    %       real MATLAB enumerations rather than free strings (D-006, D-007,
    %       D-011).
    %     * TradeCandidate (Stage 2) -- DECLARED in the profile with its
    %       eight properties, so the Stage-3 generator cannot quietly invent
    %       a different parameter set.
    %     * Candidates (Stage 3) -- each of the 7 carries TradeCandidate with
    %       a RealizesRole/RealizesKind pair that RESOLVES in the L model, a
    %       positive mass, a Benefit inside the declared 1..10 scale and a
    %       TRL inside the integer 1..9 scale (D-021 and D-033 both make 0
    %       the fail-safe "unset" default, outside the scale on purpose), a
    %       NaN cost, and a DataProvenance from the four-member vocabulary.
    %       Both scales are the ones the trade study's own guards enforce,
    %       and a negative control proves they can still reject.
    %     * Active configuration (Stage 3) -- exactly one active choice per
    %       variant role, and OEW counts THAT configuration only: 19,980.73
    %       lb, demonstrably not the all-candidates sum. The materials
    %       roll-up follows the active airframe candidate's own parts rather
    %       than a hard-coded path.
    %     * TraceRefs (Stage 3) -- every reference in every Rationale.TraceRef
    %       is resolved for real: requirement ids through slreq.load + find in
    %       the OWNING set, model paths through lookup. A negative control in
    %       the same test proves the resolver can still say no, so a rename
    %       breaks the suite instead of breaking traceability silently.
    %     * The decision (Stage 4) -- the trade study records its verdict in
    %       four places, and this file checks all four agree: exactly one
    %       Selected candidate per role AND it is the active variant choice;
    %       TradeWinner/TradeAlternative rationale with the score cited in the
    %       winner's justification; an Implement link on each of
    %       REQ_F16A_L01..L03 (D-010 -- the links are created by the PHYSICAL
    %       trade study, so the assertion lives here and not in the L suite);
    %       and OEW still measuring the configuration that was selected.
    %       The winners are asserted by IDENTITY (F100_PW_200,
    %       BlendedCrankedDelta, FlyByWire -- ground truth about the F-16A);
    %       the scores that produce them only by ORDERING.
    %     * Provenance is COMPLETE (Stage 5) -- the assertion the Stage-5
    %       audit had to make by hand. Every stereotype the P profile
    %       declares that carries engineering values a human chose must
    %       declare DataProvenance typed by F16ADataProvenance; the required
    %       set is COMPUTED (all declared stereotypes minus a named,
    %       commented exemption list) rather than listed, so a stereotype
    %       added tomorrow is in it the day it appears. Every component
    %       carrying one of those stereotypes must hold a tag from the
    %       four-member vocabulary, and the ten values D-030 inventories as
    %       invented -- 7 CompositeFraction, 3 FuelCapacity_lb -- must say
    %       Estimate, with the COUNT pinned so an eleventh cannot arrive
    %       unrecorded (D-030, D-031). Cost DEFAULTS are checked too: a
    %       declared default of 0 is a latent $0 that the value check alone
    %       never sees (D-021, D-032).
    %
    %   THIS FILE NEVER RUNS THE TRADE STUDY. F16APhysicalTradeStudy writes to
    %   two models, a requirement set and a link set; a test that invoked it
    %   would be mutating the artifacts it is meant to be checking, and would
    %   pass even if the shipped model had never had the decision written into
    %   it. Every Stage-4 assertion below reads the SHIPPED model state, which
    %   the generator produced by running the trade before the roll-ups.
    %   Roll-ups are called with Persist=false for the same reason: a test run
    %   must not leave the working tree dirty.
    %
    %   NOT COVERED HERE -- and why
    %     * Any weight or cost TARGET. OEW and unit cost are objectives to
    %       minimize, not thresholds, so a pass/fail budget here would be a
    %       design verdict smuggled into a machinery test.
    %     * The VALUES of the illustrative candidate parameters. Three
    %       candidate masses are Brandt ground truth and are asserted as
    %       numbers; every other TRL, benefit and mass is a teaching Estimate,
    %       so this file asserts its RANGE and its ORDERING (who is lightest,
    %       who has the best benefit) and never the figure itself. Pinning an
    %       Estimate would turn a data revision into a test failure.
    %     * The trade SCORES themselves. 0.879 / 0.913 / 0.856 are what a
    %       declared value function returns from illustrative Estimates
    %       (D-015); pinning them would turn a data revision into a test
    %       failure. What IS asserted is that the winner's justification cites
    %       a score at all, that the winners are the production configuration,
    %       and that the engine is not won on benefit -- the ordering that
    %       carries the lesson.
    %     * The variant ROLE wrappers. A stereotype cannot be applied to a
    %       systemcomposer.arch.VariantComponent at all (D-013), so "every
    %       part has a Rationale" means every part that can carry one; the
    %       wrapper's justification lives in its candidates.
    %     * The "Verified by" links. Those are added by hand in the
    %       Requirements Editor (see README); the "is it met?" answer is the
    %       matching suite in verification/.
    %     * THE TRADE STUDY'S GUARDS FIRING -- now covered ELSEWHERE. Stage 5
    %       gave F16APhysicalTradeStudy guards that stop the run on a
    %       parameter that cannot honestly be scored -- Benefit outside 1..10
    %       (D-033), TRL outside the integer 1..9 (D-021), a non-positive
    %       mass, a role without exactly one Reference baseline, a tie for
    %       first place -- and a warning, without capping, when a value
    %       function exceeds the 1.0 ceiling its declared scale implies
    %       (D-035). This file still pins their INPUT CONTRACT against the
    %       shipped model and still never makes one fire, but that is now a
    %       DIVISION OF LABOUR rather than a limitation.
    %
    %       Three of them -- checkParameters, the tie check and the ceiling
    %       check -- have been lifted into F16APhysicalTradeGuards, a class of
    %       pure static methods with no model handle anywhere in it, and
    %       F16APhysicalTradeGuardsTest makes every one of them fire. That is
    %       where the negative tests belong: they touch no artifact, so they
    %       do not want this file's TestClassSetup, which loads two models,
    %       three requirement sets and an allocation set before anything runs.
    %
    %       Why they were never written HERE, which is still the reason not to
    %       move them back: while the guards lived inside
    %       F16APhysicalTradeStudy.m the only way to reach one was to run the
    %       whole study, and that run is safe only for as long as the guard
    %       still WORKS. A test that set Benefit = 78 would stop early today
    %       and, on the day somebody refactored the bound away -- the exact
    %       defect such a test exists to catch -- would sail past, pick the
    %       wrong winner, and save_system a wrong active choice, a wrong
    %       active kind in the L model and a wrong Implement link on
    %       REQ_F16A_L01 into the shipped artifacts. A negative test whose
    %       failure mode is corrupting the repository is worse than no test.
    %
    %       What is STILL not covered anywhere: the study's guards that are
    %       entangled with the discovery walk (:tooFewCandidates,
    %       :candidateNotAChoice, :splitRole, :baselineNotUnique,
    %       :partialCriterion, :nothingToScore) and those that need a model
    %       handle (:logicalRoleNotVariant, :noSuchKind, :missingRequirement,
    %       the artifact-exists checks). Their input contract is the
    %       "guard rails" section below and that is all there is.
    %
    %   R2026a APIs exercised here, each isolated in one helper below so a
    %   signature fix touches one place:
    %     * Walk        -- a VariantComponent's .Architecture.Components
    %       returns 0 on a LOADED model (Stage-0 finding 6), so every
    %       traversal in this file goes through getChoices. The walk asserts
    %       its own component count, because a walk that silently visits
    %       nothing would make every per-part check pass vacuously.
    %     * Stereotypes -- getStereotypes returns a cell array of
    %       '<profile>.<stereotype>'; getProperty takes
    %       "<profile>.<stereotype>.<property>" and hands ENUMERATION and
    %       STRING values back QUOTED (Stage-0 findings 1 and 7), so they
    %       are read with erase(..., "'").
    %     * Profiles    -- model.Profiles -> Profile.Stereotypes ->
    %       Stereotype.Properties(k).Name/.Type, so the vocabulary is
    %       checked in the PROFILE, before and regardless of what applies it.
    %     * Enumerations -- meta.class.fromName(...).EnumerationMemberList,
    %       which is empty when the classdef is not on the path.
    %     * Variants    -- getChoices for every choice, getActiveChoice for
    %       the active configuration. Two path spaces coexist (Stage-0
    %       finding 3): ARCHITECTURE paths carry the choice level
    %       (.../Airframe/BlendedCrankedDelta/Wing) and are what this file
    %       and lookup use; INSTANCE paths do not (.../Airframe/Wing) and are
    %       what the roll-ups use. Both are exercised here, in
    %       testMassRollupSelfConsistent.
    %     * Requirements-- slreq.load per set + find(set, Id=...), which
    %       returns EMPTY rather than erroring for an unknown id -- which is
    %       what makes it usable as a resolver in testTraceRefsResolve.

    properties
        Model      % F16A_Physical
        LogiModel  % F16A_Logical (realization source)
        OrigSet    % f16a.slreqx (REQ_F16A_022 materials, REQ_F16A_026 cost MoM)
        PhysSet    % f16a_physical_derived.slreqx (REQ_F16A_P01 fuel volume)
        LogiSet    % f16a_logical_derived.slreqx (REQ_F16A_L01..L03 decisions)
        Alloc      % F16A_LogicalToPhysical allocation set
        Profile = "F16A_PhysicalProps";
        AC      = "F16A_Physical/Aircraft/";
    end

    properties (Constant)
        Assemblies = ["Airframe","Propulsion","LandingGear","FuelSystem", ...
            "FlightControls","Avionics","Electrical","Hydraulics","ECS", ...
            "ArmamentSupport","SecondaryStructure"];
        AirframeParts   = ["Wing","Fuselage","HorizontalTail","VerticalTail","Nacelles","Strakes"];
        % Propulsion's own children: the Engine VARIANT ROLE (whose
        % candidates are listed in CandidateRows) plus the inlet duct, which
        % stays a plain part shared by every engine candidate (D-009).
        PropulsionParts = ["Engine","InletDuct"];
        FuelTanks       = ["FwdFuselageTank","AftFuselageTank","WingTank"];
        LogicalRoles = ["Airframe","PropulsionSystem","FuelSystem", ...
            "FlightControlSystem","LandingGear","AvionicsSuite", ...
            "CommunicationSystem","WeaponSystem","MissionSystemsBay"];
        % Parts that realize NO single logical role (supporting infrastructure).
        UnrealizedParts = ["Electrical","Hydraulics","ECS","SecondaryStructure"];
        % The three candidates that carry Brandt ground truth, and therefore
        % the choice level that the airframe/engine/flight-control paths gain
        % (D-003). Named for WHAT THEY ARE, not for "the active one": which
        % candidate is active is read from the model, never assumed here.
        BrandtAirframe       = "BlendedCrankedDelta";   % the only decomposed candidate
        BrandtEngine         = "F100_PW_200";
        BrandtFlightControls = "FlyByWire";
        % Ground-truth mass-bearing leaves {relative path, lbf}. FuelSystem
        % (0 lbf) is intentionally excluded and checked separately. These 16
        % are the ACTIVE configuration; they sum to ExpectedOEW_lb.
        MassRows = { ...
            "Airframe/BlendedCrankedDelta/Wing",1785.95; ...
            "Airframe/BlendedCrankedDelta/Fuselage",3652.11; ...
            "Airframe/BlendedCrankedDelta/HorizontalTail",648.00; ...
            "Airframe/BlendedCrankedDelta/VerticalTail",360.00; ...
            "Airframe/BlendedCrankedDelta/Nacelles",186.82; ...
            "Airframe/BlendedCrankedDelta/Strakes",90.00; ...
            "Propulsion/Engine/F100_PW_200",4730.23; "Propulsion/InletDuct",728.60; ...
            "LandingGear",1066.82; "FlightControls/FlyByWire",472.44; "Avionics",2541.54; ...
            "Electrical",533.41; "Hydraulics",367.11; "ECS",360.84; ...
            "ArmamentSupport",440.00; "SecondaryStructure",2016.86};
        % Brandt ground truth, asserted as NUMBERS because that is what they
        % are. OEW is unchanged by the restructure (D-003) -- that invariance
        % is the whole point of testOEWCountsOnlyTheActiveConfiguration.
        ExpectedOEW_lb            = 19980.73;
        BrandtAirframeMass_lb     =  6722.88;
        ExpectedCompositeFraction =   0.1928;

        % --- Stage 2: rationale and the trade vocabulary -----------------
        % How many components the architecture-side walk must reach: the 23
        % of Stage 2 plus Stage 3's 7 variant choices. Asserted so a walk
        % that silently skips a subtree (the classic getChoices trap) fails
        % loudly instead of passing empty.
        ExpectedComponentCount = 30;
        RationaleStereotype = "Rationale";
        % A rationale that reads "engine" is not a rationale. 20 characters
        % is a floor on effort, not a style rule -- it is deliberately far
        % below the length of any honest justification.
        MinJustificationLength = 20;
        SourceKindClass   = "F16ASourceKind";
        SourceKindMembers = ["ConstraintDriven","RealizesFunction", ...
            "SatisfiesRequirement","SupportingInfrastructure", ...
            "TradeAlternative","TradeWinner"];
        DataProvenanceClass   = "F16ADataProvenance";
        DataProvenanceMembers = ["Datasheet","Estimate","Reference","Simulation"];
        % Declared at Stage 2, applied at Stage 3.
        CandidateStereotype = "TradeCandidate";
        CandidateProperties = ["Benefit","DataProvenance","Mass_lb", ...
            "RealizesKind","RealizesRole","Selected","TRL","UnitCost_USD"];

        % --- Stage 3: the variant roles and their candidates ---------------
        % {variant path under Aircraft, logical role it realizes, #candidates}
        % The variant components themselves carry NO stereotype (D-013), so
        % they are excluded from every per-part check; what they own is the
        % choice, and that is what is asserted about them.
        VariantRows = { ...
            "Airframe",          "Airframe",            2; ...
            "Propulsion/Engine", "PropulsionSystem",    3; ...
            "FlightControls",    "FlightControlSystem", 2};
        % {candidate path under Aircraft, logical role, logical kind,
        %  expected DataProvenance}
        % NO Mass/TRL/Benefit column ON PURPOSE. Three of these masses are
        % Brandt ground truth and are already asserted as numbers in MassRows;
        % every other figure is an illustrative Estimate (D-007), so this file
        % asserts the RELATIONSHIPS between them -- valid range, ordering,
        % agreement with the parts actually modelled -- and never the values.
        % Role and kind ARE asserted exactly: they are structural claims that
        % must resolve in the L model, not numbers.
        CandidateRows = { ...
            "Airframe/BlendedCrankedDelta",           "Airframe",            "BlendedCrankedDelta",  "Reference"; ...
            "Airframe/ConventionalTrapWing",          "Airframe",            "ConventionalTrapWing", "Estimate";  ...
            "Propulsion/Engine/F100_PW_200",          "PropulsionSystem",    "SingleEngine",         "Reference"; ...
            "Propulsion/Engine/F110_GE_100",          "PropulsionSystem",    "SingleEngine",         "Estimate";  ...
            "Propulsion/Engine/TwinEngine_Surrogate", "PropulsionSystem",    "TwinEngine",           "Estimate";  ...
            "FlightControls/FlyByWire",               "FlightControlSystem", "FlyByWire",            "Reference"; ...
            "FlightControls/HydroMechanical",         "FlightControlSystem", "HydroMechanical",      "Estimate"};
        % The TRL scale. 1..9 inclusive AND INTEGER; D-021 deliberately
        % defaults the property to 0 -- OUTSIDE the scale -- so an unset TRL is
        % caught here and by the trade study rather than silently scoring as
        % "mid-pack". Integrality is part of the scale, not a nicety: TRL is an
        % ordinal maturity level and the trade study's guard rejects a
        % fractional one outright.
        %
        % TAKEN FROM THE CODE THAT ENFORCES IT, not restated. These used to be
        % literals with a note explaining that checkParameters was a local
        % function of F16APhysicalTradeStudy.m and could not be imported. It is
        % now F16APhysicalTradeGuards, which exposes its bounds as constants
        % precisely so a test can take them from the enforcer -- so the test
        % and the guard can no longer drift apart, and a scale widened in the
        % code cannot leave this file agreeing with a bound that is gone.
        TRLScale = F16APhysicalTradeGuards.TRLScale;
        % The Benefit scale, D-033. BOXED AT BOTH ENDS, for the same reason TRL
        % is. 0 is the stereotype default and therefore the same "unset"
        % sentinel; the UPPER bound is the one that earns its keep, because
        % v = B/10 carries the heaviest weight in the trade and a slipped
        % decimal point is FINITE and so invisible to every isfinite check --
        % 78 typed for 7.8 contributes 3.90 where 0.50 is the most any
        % criterion may legitimately be worth, which hands the propulsion trade
        % to TwinEngine_Surrogate, flips the L model's active kind and
        % Implement-links REQ_F16A_L01 from the wrong kind.
        BenefitScale = F16APhysicalTradeGuards.BenefitScale;
        % The negative control for both scales. Every value here MUST be
        % rejected and every value in the Accepted* lists MUST pass, judged by
        % the SAME predicates the candidate sweeps use -- so a scale quietly
        % widened to admit awkward data fails here instead of going green.
        %   0     the stereotype default: "nobody set this" (D-021, D-033)
        %   78    7.8 with a slipped decimal point -- D-033's entire case, and
        %         the reason the upper bound exists at all
        %   10.5  just past the top of the declared scale
        %   -1    negative merit is not a point on a 1..10 scale
        %   NaN   an unreadable property must stop the trade, not score as 0
        %   Inf   what the isfinite net is there for
        RejectedBenefits = [0, 78, 10.5, -1, NaN, Inf];
        AcceptedBenefits = [1, 7.8, 10];
        %   0     D-021's "unset" sentinel, the reason TRL is boxed below 1
        %   10    one past the top of the 1..9 scale
        %   4.5   TRL is an ordinal level, not a continuous quantity
        RejectedTRLs = [0, 10, 4.5, -1, NaN, Inf];
        AcceptedTRLs = [1, 6, 9];
        % D-015's ratio baseline: the role's DataProvenance = Reference
        % candidate. The trade study requires exactly one per role -- with none
        % there is no scale, with two there is no answer to "which one" -- and
        % divides every mass ratio by its mass.
        BaselineProvenance = "Reference";
        % How far above 1.0 a value function must land before it counts as
        % exceeding the ceiling its declared scale implies (D-035). The
        % Reference candidate's own M_baseline/M is exactly 1 and must not
        % register as an exceedance. Taken from the guard, for the same reason
        % the two scales above are: this used to MIRROR the trade study's
        % CeilingTol by hand, and a mirror is a copy waiting to disagree.
        ValueCeilingTol = F16APhysicalTradeGuards.CeilingTol;
        % Rationale kinds a trade candidate may legitimately carry. Both are
        % allowed so this assertion survives Stage 4, when the trade study
        % promotes three of the seven from TradeAlternative to TradeWinner.
        CandidateSourceKinds = ["TradeAlternative","TradeWinner"];
        % The three requirement sets a TraceRef can name, keyed by id prefix.
        % Every TraceRef must resolve in the set that OWNS it, not just
        % somewhere: 022/023/024/026 in f16a.slreqx, P01 in the physical
        % derived set, L01..L03 in the logical derived set.
        RequirementPrefix = "REQ_F16A_";
        LogicalPathPrefix  = "F16A_Logical/";
        PhysicalPathPrefix = "F16A_Physical/";
        % Deliberately unresolvable references, used as the negative control
        % INSIDE testTraceRefsResolve so a resolver that says yes to
        % everything cannot make that test pass vacuously. One per form, plus
        % a bare token that matches no form at all.
        BogusTraceRefs = ["REQ_F16A_999", "REQ_F16A_L99", "REQ_F16A_P99", ...
            "F16A_Logical/NoSuchRole", "F16A_Physical/Aircraft/NoSuchPart", ...
            "F16A_Physical/Aircraft/Airframe/NoSuchCandidate", "Wing"];
        % D-023: the 3 x 2100 lb fuel split is an even division of Brandt's
        % 6296.30 lb mission fuel -- an Estimate in substance, so it must say
        % so in the model now that FuelTank has a DataProvenance property.
        FuelTankProvenance = "Estimate";

        % --- Stage 4: the recorded decision ------------------------------
        % The production F-16A. This is GROUND TRUTH about the aeroplane that
        % was actually built, so it is asserted as an IDENTITY -- unlike the
        % scores that produce it, which are illustrative and are asserted only
        % as orderings. Sorted, because selectedCandidateNames sorts.
        ExpectedWinners = ["BlendedCrankedDelta","F100_PW_200","FlyByWire"];
        % The rationale a candidate must carry once the trade has run: the
        % winner won, everybody else is on the record as an alternative that
        % was considered. "TradeAlternative on the losers" is the half that
        % keeps D-002 honest -- a losing candidate that says nothing is just
        % an orphan box.
        WinnerSourceKind      = "TradeWinner";
        AlternativeSourceKind = "TradeAlternative";
        % A winner's justification must CITE the score it won on, so the
        % number in the model and the number in the story cannot drift apart.
        % The PATTERN is asserted, never the value (D-015): a 0.dd token.
        % Anchored to "0." on purpose -- a mass (4730.23), a benefit (8.2) and
        % a TRL (8) all fail to match, so this cannot be satisfied by the
        % other numbers a justification is likely to mention.
        ScoreTokenPattern = "0\.\d\d+";
        % D-010's assertion, in its new home. These three decision
        % requirements are Implement-linked BY THE PHYSICAL TRADE STUDY, which
        % is precisely why the check is here and not in the L suite: asserting
        % it at L would make the L suite pass or fail depending on whether P
        % had been run.
        DecisionRequirements = ["REQ_F16A_L01","REQ_F16A_L02","REQ_F16A_L03"];
        ImplementLinkType    = "Implement";

        % --- Stage 5 audit: no invented number without a tag -------------
        % The property that carries a provenance tag, and the ONE list of
        % stereotypes exempt from carrying it.
        %
        % THE CHECK IS WRITTEN THE OTHER WAY ROUND from the obvious one. It
        % does not enumerate the stereotypes that need provenance; it takes
        % every stereotype the P profile DECLARES, subtracts this exemption
        % list, and requires the remainder to declare DataProvenance. So a
        % stereotype added tomorrow to hold engineering values is in the
        % required set on the day it appears and FAILS until somebody either
        % tags it or writes its name below -- and writing a name below is a
        % visible line in a diff with a reason next to it, which is what an
        % exemption ought to cost. Listing "Material, FuelTank,
        % TradeCandidate need tags" instead would pass by omission forever,
        % which is precisely how the Material gap survived to Stage 5.
        %
        % Why each exemption, so the decision is readable and not inherited:
        %   PhysicalItem   -- Mass_lb is Brandt ground truth throughout the
        %                     as-built decomposition. The four INVENTED
        %                     candidate masses are tagged on TradeCandidate,
        %                     which is where they are scored (D-025).
        %   Rationale      -- SourceKind, Justification, TraceRef: prose and
        %                     references, no numbers to source.
        %   MeasureOfMerit -- OEW_lb is COMPUTED by the roll-up and
        %                     UnitCost_USD is NaN pending a cost model
        %                     (D-005). Neither is a value a human chose, and
        %                     a provenance tag on a computed number would be
        %                     the overclaiming D-025 warns against.
        ProvenanceProperty          = "DataProvenance";
        ProvenanceExemptStereotypes = ["MeasureOfMerit","PhysicalItem","Rationale"];
        % Non-vacuity floor: the stereotypes known TODAY to carry chosen
        % engineering values. Asserted as a SUBSET of the computed required
        % set, never as an equality -- an equality would make the computed
        % set decorative and quietly restore the pass-by-omission this test
        % exists to remove.
        KnownValueBearingStereotypes = ["FuelTank","Material","TradeCandidate"];
        EstimateProvenance = "Estimate";
        % D-030's inventory of invented numbers, as a CENSUS the model must
        % match: {stereotype, the property whose value was invented, how many
        % components carry it}. Every value under these two stereotypes is
        % tagged Estimate without exception, and the count is pinned: an
        % eighth composite fraction or a fourth tank is an eighth or fourth
        % invented number, and D-030 has to grow a row before this can go
        % green again.
        %
        % TradeCandidate is deliberately NOT here. Three of its seven are
        % Brandt figures tagged Reference, so its per-candidate expectation
        % lives in CandidateRows and is asserted by
        % testCandidatesCarryTradeParameters.
        InventedEstimateCensus = { ...
            "Material", "CompositeFraction", 7; ...   % 6 structural parts + the lumped candidate
            "FuelTank", "FuelCapacity_lb",   3};      % the three internal tanks
        % D-021 / D-032: a cost property must DECLARE NaN, not a number that
        % looks like data. Checked in the PROFILE, because the VALUE check
        % (testCostIsNaNEverywhere) passes happily while the default is a
        % latent $0 -- the generator overwrites it every run, so the hole is
        % invisible until some other path applies the stereotype without
        % writing the property.
        CostDefault    = "NaN";
        CostProperties = { ...
            "MeasureOfMerit", "UnitCost_USD"; ...   % D-032, the hole the Stage-5 audit found
            "TradeCandidate", "UnitCost_USD"};      % D-021, closed at Stage 2 -- kept as a regression guard
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
            addpath(thisDir);
            addpath(fullfile(thisDir, "physical"));
            addpath(fullfile(thisDir, "logical"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            try systemcomposer.allocation.AllocationSet.closeAll(); catch, end %#ok<CTCH>
            testCase.Model     = systemcomposer.loadModel("F16A_Physical");
            testCase.LogiModel = systemcomposer.loadModel("F16A_Logical");
            testCase.OrigSet   = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.PhysSet   = slreq.load(fullfile(thisDir, "requirements", "f16a_physical_derived.slreqx"));
            % Loaded for testTraceRefsResolve: the candidates trace to the
            % L01-L03 decision requirements, which live only in this set.
            testCase.LogiSet   = slreq.load(fullfile(thisDir, "requirements", "f16a_logical_derived.slreqx"));
            testCase.Alloc     = systemcomposer.allocation.load("F16A_LogicalToPhysical");
            testCase.addTeardown(@() testCase.Alloc.close());
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testPhysicalComponentsExist(testCase)
            % 30 components; root holds one Aircraft; Aircraft holds 11
            % assemblies; the 3 variant roles hold 2/3/2 candidates; the
            % decomposed airframe candidate holds the 6 structural parts;
            % Propulsion holds the Engine variant plus InletDuct; FuelSystem
            % 3 tanks.
            %
            % Child counts for the variant roles go through getChoices, NOT
            % .Architecture.Components -- the latter returns 0 for a variant
            % on a LOADED model (Stage-0 finding 6), which would turn every
            % count below into a false pass.
            testCase.verifyEqual(testCase.countComps(), testCase.ExpectedComponentCount, ...
                "Expected 30 components (Aircraft + 11 assemblies + 7 candidates + 8 parts + 3 tanks).");
            testCase.verifyEqual(numel(testCase.Model.Architecture.Components), 1, ...
                "Root should hold exactly one component (Aircraft).");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyEqual(numel(ac.Architecture.Components), 11, ...
                "Aircraft should hold 11 assemblies.");
            choiceDefects = testCase.variantChoiceCountDefects();
            testCase.verifyEmpty(choiceDefects, ...
                "Variant role does not hold its expected number of candidates: " + ...
                strjoin(choiceDefects, ", ") + ".");
            bcd = testCase.componentAt(testCase.AC + "Airframe/" + testCase.BrandtAirframe);
            testCase.verifyEqual(numel(bcd.Architecture.Components), 6, ...
                testCase.BrandtAirframe + " should hold the 6 structural parts (D-003).");
            pr = testCase.componentAt(testCase.AC + "Propulsion");
            testCase.verifyEqual(numel(pr.Architecture.Components), 2, ...
                "Propulsion should hold the Engine variant plus InletDuct.");
            fs = testCase.componentAt(testCase.AC + "FuelSystem");
            testCase.verifyEqual(numel(fs.Architecture.Components), 3, "FuelSystem should have 3 tanks.");
        end

        function testHierarchyCorrect(testCase)
            % Every assembly resolves under Aircraft; the 6 structural parts
            % resolve under the DECOMPOSED airframe candidate (the choice
            % level D-003 adds); every candidate resolves under its variant
            % role; the remaining leaf assemblies are childless.
            for a = testCase.Assemblies
                testCase.verifyTrue(testCase.resolves(testCase.AC + a), "Missing assembly: " + a);
            end
            for p = testCase.AirframeParts
                testCase.verifyTrue( ...
                    testCase.resolves(testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/" + p), ...
                    "Missing Airframe part: " + p);
            end
            for p = testCase.PropulsionParts
                testCase.verifyTrue(testCase.resolves(testCase.AC + "Propulsion/" + p), ...
                    "Missing Propulsion child: " + p);
            end
            for i = 1:size(testCase.CandidateRows,1)
                testCase.verifyTrue(testCase.resolves(testCase.AC + string(testCase.CandidateRows{i,1})), ...
                    "Missing candidate: " + string(testCase.CandidateRows{i,1}));
            end
            for t = testCase.FuelTanks
                testCase.verifyTrue(testCase.resolves(testCase.AC + "FuelSystem/" + t), "Missing fuel tank: " + t);
            end
            % The three variant roles must really BE variant components. A
            % plain component with two children would satisfy every path
            % assertion above and still have no notion of an active
            % configuration, so the class is checked explicitly.
            for i = 1:size(testCase.VariantRows,1)
                vc = testCase.componentAt(testCase.AC + string(testCase.VariantRows{i,1}));
                testCase.verifyClass(vc, "systemcomposer.arch.VariantComponent", ...
                    string(testCase.VariantRows{i,1}) + " must be a variant component.");
            end
            % Childlessness is only meaningful for NON-variant components:
            % a variant reports 0 children on a loaded model whether or not
            % it has choices (Stage-0 finding 6), so FlightControls is
            % excluded here and covered by the variant checks instead.
            leafAsm = setdiff(testCase.Assemblies, ...
                ["Airframe","Propulsion","FuelSystem","FlightControls"]);
            for a = leafAsm
                c = testCase.Model.lookup(Path=char(testCase.AC + a));
                testCase.verifyEmpty(c.Architecture.Components, a + " should be a leaf.");
            end
        end

        function testPhysicalItemStereotypeApplied(testCase)
            % Every component that CAN carry a stereotype carries
            % PhysicalItem -- the 30 the walk reaches, minus the 3 variant
            % role wrappers, which applyStereotype rejects outright (D-013).
            % The part list is DISCOVERED by the walk rather than enumerated,
            % so a candidate added without a mass is caught the day it
            % appears; the expected COUNT is asserted first so a walk that
            % reached nothing could not make the sweep pass empty.
            [parts, paths] = testCase.stereotypableParts();
            testCase.verifyEqual(numel(parts), ...
                testCase.ExpectedComponentCount - size(testCase.VariantRows,1), ...
                "Expected " + (testCase.ExpectedComponentCount - size(testCase.VariantRows,1)) + ...
                " stereotype-bearing components (30 walked minus the 3 variant roles), found " + ...
                numel(parts) + ".");
            missing = testCase.partsWithoutStereotype(parts, paths, "PhysicalItem");
            testCase.verifyEmpty(missing, ...
                "PhysicalItem not applied to: " + strjoin(missing, ", ") + ".");
        end

        function testLeafMassesMatchGroundTruth(testCase)
            % The 16 mass-bearing leaves match the Brandt ground truth; the
            % FuelSystem leaf is zero (fuel is a consumable, not empty weight).
            for i = 1:size(testCase.MassRows,1)
                rel = string(testCase.MassRows{i,1});
                exp = testCase.MassRows{i,2};
                c = testCase.componentAt(testCase.AC + rel);
                v = str2double(string(getProperty(c, testCase.Profile + ".PhysicalItem.Mass_lb")));
                testCase.verifyEqual(v, exp, "AbsTol", 0.01, rel + " mass mismatch.");
                testCase.verifyGreaterThan(v, 0, rel + " should be a mass-bearing leaf.");
            end
            fs = testCase.Model.lookup(Path=char(testCase.AC + "FuelSystem"));
            vfs = str2double(string(getProperty(fs, testCase.Profile + ".PhysicalItem.Mass_lb")));
            testCase.verifyEqual(vfs, 0, "AbsTol", 1e-9, "FuelSystem should carry zero OEW mass.");
        end

        function testAirframeCompositeFractionsSet(testCase)
            % Every airframe structural part carries a Material stereotype
            % with a CompositeFraction in [0,1]; at least the tails are
            % composite-heavy. The LUMPED airframe candidate needs one too --
            % without it, switching the active choice would silently drop the
            % airframe composite fraction to zero and REQ_F16A_022 would be
            % "met" by an aircraft with no material data at all.
            afRoot = testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/";
            for p = testCase.AirframeParts
                c = testCase.componentAt(afRoot + p);
                testCase.verifyTrue(any(contains(string(c.getStereotypes()), "Material")), ...
                    "Material stereotype not applied to " + p);
                cf = testCase.propNum(c, testCase.Profile + ".Material.CompositeFraction");
                testCase.verifyGreaterThanOrEqual(cf, 0, p + " CompositeFraction < 0.");
                testCase.verifyLessThanOrEqual(cf, 1, p + " CompositeFraction > 1.");
            end
            vt = testCase.componentAt(afRoot + "VerticalTail");
            cfvt = testCase.propNum(vt, testCase.Profile + ".Material.CompositeFraction");
            testCase.verifyGreaterThan(cfvt, 0.3, "VerticalTail should be composite-heavy (graphite skins).");
            % The lumped candidate: a Material stereotype with a fraction in
            % range. The VALUE is an Estimate (D-007) and is not asserted.
            lumped = testCase.componentAt(testCase.AC + "Airframe/ConventionalTrapWing");
            testCase.verifyTrue(any(contains(string(lumped.getStereotypes()), "Material")), ...
                "Material stereotype not applied to the lumped airframe candidate.");
            cfLumped = testCase.propNum(lumped, testCase.Profile + ".Material.CompositeFraction");
            testCase.verifyGreaterThanOrEqual(cfLumped, 0, "ConventionalTrapWing CompositeFraction < 0.");
            testCase.verifyLessThanOrEqual(cfLumped, 1, "ConventionalTrapWing CompositeFraction > 1.");
        end

        function testFuelTankCapacities(testCase)
            % Each fuel tank carries a FuelTank stereotype with a positive
            % capacity and zero dry (OEW) mass; total ~ 6300 lb.
            total = 0;
            for t = testCase.FuelTanks
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                testCase.verifyTrue(any(contains(string(c.getStereotypes()), "FuelTank")), ...
                    "FuelTank stereotype not applied to " + t);
                cap = str2double(string(getProperty(c, testCase.Profile + ".FuelTank.FuelCapacity_lb")));
                testCase.verifyGreaterThan(cap, 0, t + " should have positive fuel capacity.");
                mass = str2double(string(getProperty(c, testCase.Profile + ".PhysicalItem.Mass_lb")));
                testCase.verifyEqual(mass, 0, "AbsTol", 1e-9, t + " dry mass should be 0 (fuel is a consumable).");
                total = total + cap;
            end
            testCase.verifyGreaterThanOrEqual(total, 6000, "Total internal fuel capacity looks too low.");
        end

        function testMassRollupSelfConsistent(testCase)
            % The roll-up is internally consistent: each assembly subtotal is
            % the sum of its parts and OEW is the sum of all ACTIVE leaves.
            % This checks the traversal, NOT any weight target/budget.
            %
            % It is also where the TWO PATH SPACES meet (Stage-0 finding 3).
            % The roll-up reads INSTANCE paths, in which the active choice
            % node is elided -- .../Airframe and .../Propulsion/Engine are
            % still valid there and already carry the rolled-up value. This
            % test reads ARCHITECTURE paths, which include the choice level.
            % Asserting the two agree is what stops the restructure quietly
            % changing what "the airframe weighs" means.
            r = testCase.massRollup();
            afRoot        = testCase.AC + "Airframe/" + testCase.BrandtAirframe + "/";
            expAirframe   = testCase.sumMasses(afRoot + testCase.AirframeParts);
            expPropulsion = testCase.sumMasses([ ...
                testCase.AC + "Propulsion/Engine/" + testCase.BrandtEngine, ...
                testCase.AC + "Propulsion/InletDuct"]);
            expEngine     = testCase.sumMasses(testCase.AC + "Propulsion/Engine/" + testCase.BrandtEngine);
            expOEW        = sum([testCase.MassRows{:,2}]);   % all active mass-bearing leaves
            testCase.verifyEqual(r.Airframe,   expAirframe,   "AbsTol", 0.01, "Airframe subtotal != sum of parts.");
            testCase.verifyEqual(r.Propulsion, expPropulsion, "AbsTol", 0.01, "Propulsion subtotal != sum of parts.");
            testCase.verifyEqual(r.Engine,     expEngine,     "AbsTol", 0.01, ...
                "The rolled-up Engine mass must be the ACTIVE engine candidate's mass, " + ...
                "not a sum over all three candidates.");
            testCase.verifyEqual(r.OEW,        expOEW,        "AbsTol", 0.05, "OEW != sum of leaf masses.");
            testCase.verifyEqual(r.AirframeLessEngine, r.OEW - r.Engine, "AbsTol", 1e-6, ...
                "Airframe-less-engine must equal OEW - Engine.");
        end

        function testOEWMeasureOfMerit(testCase)
            % The Aircraft carries a MeasureOfMerit with Goal=Minimize, and
            % OEW_lb holds the rolled-up empty weight.
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            testCase.verifyTrue(any(contains(string(ac.getStereotypes()), "MeasureOfMerit")), ...
                "MeasureOfMerit not applied to Aircraft.");
            % String stereotype properties store the value as a quoted MATLAB
            % expression, so strip the surrounding quotes before comparing.
            goal = erase(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.Goal")), "'");
            testCase.verifyEqual(goal, "Minimize", "OEW MoM Goal should be Minimize.");
            oew = str2double(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.OEW_lb")));
            testCase.verifyEqual(oew, sum([testCase.MassRows{:,2}]), "AbsTol", 0.05, ...
                "OEW MoM value should equal the mass roll-up.");
        end

        function testCostMeasureOfMerit(testCase)
            % Unit cost is the OTHER MoM (minimize), sourced from a cost-model
            % FUNCTION (not a roll-up). The stub leaves it uncomputed (NaN);
            % we assert the hook exists and the value is the placeholder, NOT
            % any cost number.
            testCase.verifyEqual(exist("F16APhysicalCostModel", "file"), 2, ...
                "Cost-model hook F16APhysicalCostModel is missing.");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            cost = str2double(string(getProperty(ac, testCase.Profile + ".MeasureOfMerit.UnitCost_USD")));
            testCase.verifyTrue(isnan(cost), ...
                "Cost MoM should be the uncomputed placeholder (NaN) pending a cost model.");
        end

        function testRealizationAllocationExists(testCase)
            scenario = testCase.Alloc.getScenario("Scenario 1");
            testCase.verifyNotEmpty(scenario, "Missing realization allocation scenario.");
        end

        function testRealizationCoversAllLogicalRoles(testCase)
            % Every one of the 9 logical roles is a realization source, and a
            % role with candidates is realized by ALL of them. A losing
            % alternative genuinely does realize the role -- that is what
            % makes the trade a decision rather than a formality -- so
            % narrowing the realization set to the active choice would hide
            % exactly the options L went to the trouble of enumerating
            % (D-002).
            [srcCounts, ~] = testCase.allocEndpoints();
            missing = setdiff(testCase.LogicalRoles, string(keys(srcCounts)));
            testCase.verifyEmpty(missing, "Logical roles not realized: " + strjoin(missing, ", "));
            thin = testCase.rolesNotRealizedByAllTheirCandidates();
            testCase.verifyEmpty(thin, ...
                "A variant role must be realized by every candidate that could fill it: " + ...
                strjoin(thin, ", ") + ".");
            % The 1->many teaching moment MOVED with the restructure: it used
            % to be Airframe decomposing into 6 structural parts (those now
            % sit one level down, under a candidate, and realize the role
            % through it). It is now PropulsionSystem -> 3 mutually exclusive
            % engine candidates plus the InletDuct they all share (D-009).
            testCase.verifyGreaterThanOrEqual(srcCounts("PropulsionSystem"), 4, ...
                "PropulsionSystem should realize to >= 4 parts (3 engine candidates + InletDuct).");
        end

        function testUnrealizedInfrastructureParts(testCase)
            % Electrical, Hydraulics, ECS, SecondaryStructure realize no single
            % logical role -- the symmetric echo of L's constraint-driven roles.
            [~, dstNames] = testCase.allocEndpoints();
            offenders = intersect(testCase.UnrealizedParts, dstNames);
            testCase.verifyEmpty(offenders, ...
                "These parts should realize no logical role: " + strjoin(offenders, ", "));
        end

        function testCostMoMHomedAtPhysical(testCase)
            % REQ_F16A_026 is reclassified as a Measure of Merit (keywords) and
            % is now Implement-linked from the Physical layer (Aircraft).
            req = find(testCase.OrigSet, Id="REQ_F16A_026");
            testCase.verifyNotEmpty(req, "REQ_F16A_026 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_026 should be homed (linked) at P.");
            testCase.verifyTrue(any(string(req.Keywords) == "minimize"), ...
                "REQ_F16A_026 should be marked a Measure of Merit (keyword 'minimize').");
        end

        function testMaterialsRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_022 from the
            % Airframe. The "Verified by" link (to F16AMaterialsVerificationTest)
            % is added MANUALLY in the Requirements Editor (see README), so it is
            % deliberately NOT asserted here -- the actual "is it met?" check is
            % F16AMaterialsVerificationTest.
            req = find(testCase.OrigSet, Id="REQ_F16A_022");
            testCase.verifyNotEmpty(req, "REQ_F16A_022 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_022 should be Implement-linked at P.");
        end

        function testFuelRequirementImplemented(testCase)
            % Machinery: the generator Implement-links REQ_F16A_P01 from the
            % FuelSystem. Its "Verified by" link (F16AFuelVerificationTest) is
            % added manually (see README) and is not asserted here.
            req = find(testCase.PhysSet, Id="REQ_F16A_P01");
            testCase.verifyNotEmpty(req, "REQ_F16A_P01 not found.");
            testCase.verifyNotEmpty(req.inLinks(), "REQ_F16A_P01 should be Implement-linked at P.");
        end

        % ---------------- Stage 2: rationale and trade vocabulary --------

        function testEveryPartHasRationale(testCase)
            % "Why does this part exist?" must be answerable by QUERYING the
            % model, not by reading a code comment (D-006). The part list is
            % DISCOVERED by walking the architecture rather than hard-coded,
            % so Stage 3's candidates are covered the day they appear -- and
            % because a walk that silently visits nothing would make every
            % check below pass vacuously, the walk asserts its own size
            % first (Stage-0 finding 6).
            [~, walked] = testCase.walkComponents();
            testCase.verifyEqual(numel(walked), testCase.ExpectedComponentCount, ...
                "The architecture walk reached " + numel(walked) + " components, expected " + ...
                testCase.ExpectedComponentCount + ". A walk that skips a variant's choices " + ...
                "reports too few and makes every per-part assertion vacuous.");
            [parts, ~] = testCase.stereotypableParts();
            testCase.verifyNotEmpty(parts, ...
                "No stereotype-bearing part found -- the rationale checks would pass vacuously.");
            d = testCase.rationaleDefects();
            testCase.verifyEmpty(d.Missing, ...
                "No " + testCase.RationaleStereotype + " stereotype on: " + ...
                strjoin(d.Missing, ", ") + ".");
            testCase.verifyEmpty(d.BadKind, ...
                "SourceKind outside the " + testCase.SourceKindClass + " vocabulary on: " + ...
                strjoin(d.BadKind, ", ") + ".");
            testCase.verifyEmpty(d.EmptyTrace, ...
                "Empty TraceRef -- a rationale that traces to nothing is not traceable: " + ...
                strjoin(d.EmptyTrace, ", ") + ".");
            testCase.verifyEmpty(d.ThinJustification, ...
                "Justification shorter than " + testCase.MinJustificationLength + ...
                " characters (a part name is not a justification): " + ...
                strjoin(d.ThinJustification, ", ") + ".");
        end

        function testInfrastructurePartsAreSupportingInfrastructure(testCase)
            % The executable half of the claim in docs/05_physical.md that
            % some parts are born of the physics of building an airplane,
            % not of a role above them. testUnrealizedInfrastructureParts
            % says these four realize no logical role; this says the model
            % states WHY. The pair is the point: a part with no realization
            % AND no stated reason is just an unexplained box.
            offenders = testCase.partsWithSourceKindOtherThan( ...
                testCase.UnrealizedParts, "SupportingInfrastructure");
            testCase.verifyEmpty(offenders, ...
                "Expected SourceKind = SupportingInfrastructure on: " + ...
                strjoin(offenders, ", ") + ".");
        end

        function testRationaleVocabularyIsClosed(testCase)
            % The two vocabularies are real MATLAB enumerations, not free
            % strings (D-011). This is what stops the vocabulary drifting:
            % with a string property "SuportingInfrastructure" is a valid
            % value, and every downstream query quietly misses that part.
            % Checked in the PROFILE, so it holds even before Stage 3
            % applies TradeCandidate to anything.
            testCase.verifyNotEmpty(testCase.physicalProfiles(), ...
                "No profile resolved for the P model -- expected " + testCase.Profile + ".");
            testCase.verifyEqual( ...
                testCase.declaredPropertyType(testCase.RationaleStereotype, "SourceKind"), ...
                testCase.SourceKindClass, ...
                testCase.RationaleStereotype + ".SourceKind must be typed " + ...
                testCase.SourceKindClass + ", not a free string.");
            testCase.verifyEqual( ...
                testCase.declaredPropertyType(testCase.CandidateStereotype, "DataProvenance"), ...
                testCase.DataProvenanceClass, ...
                testCase.CandidateStereotype + ".DataProvenance must be typed " + ...
                testCase.DataProvenanceClass + ", not a free string.");
            % D-023 adds the same provenance tag to FuelTank, so the oldest
            % untagged number in the model (the 3 x 2100 lb fuel split) can
            % finally say what it is. Typed, for the same reason as above.
            testCase.verifyEqual( ...
                testCase.declaredPropertyType("FuelTank", "DataProvenance"), ...
                testCase.DataProvenanceClass, ...
                "FuelTank.DataProvenance must be typed " + testCase.DataProvenanceClass + ...
                " (D-023), not a free string.");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.SourceKindClass), ...
                sort(testCase.SourceKindMembers), ...
                testCase.SourceKindClass + " must resolve on the path with exactly the six " + ...
                "agreed members (D-006).");
            testCase.verifyEqual(testCase.enumerationMembers(testCase.DataProvenanceClass), ...
                sort(testCase.DataProvenanceMembers), ...
                testCase.DataProvenanceClass + " must resolve on the path with exactly the four " + ...
                "agreed members (D-007).");
        end

        function testTradeCandidateStereotypeDeclared(testCase)
            % Stage 2 DECLARES the trade vocabulary; Stage 3 populates it.
            % Fixing the eight property names now means the Stage-3
            % generator cannot quietly invent a different parameter set, and
            % the profile is reviewable before any candidate exists.
            % Deliberately NOT asserted: that anything CARRIES the
            % stereotype. Nothing does yet, and that is correct.
            declared = testCase.profileStereotypeNames();
            testCase.verifyTrue(ismember(testCase.CandidateStereotype, declared), ...
                "The P profile must declare " + testCase.CandidateStereotype + ...
                ", but declares: " + strjoin(declared, ", ") + ".");
            missing = setdiff(testCase.CandidateProperties, ...
                testCase.stereotypePropertyNames(testCase.CandidateStereotype));
            testCase.verifyEmpty(missing, ...
                testCase.CandidateStereotype + " must declare all eight trade properties; " + ...
                "missing: " + strjoin(missing, ", ") + ".");
        end

        % ---------------- Stage 3: candidates and the active set ---------

        function testCandidatesCarryTradeParameters(testCase)
            % Each of the seven candidates is a fully constituted trade
            % candidate BEFORE anything scores it: it applies TradeCandidate,
            % it names a role and a kind that actually EXIST in the L model
            % (a typo here would silently drop a candidate out of its role's
            % trade), its mass and benefit are positive, its TRL is inside
            % the 1..9 scale, its cost is the honest NaN of D-005, and its
            % numbers carry a provenance tag from the four-member vocabulary.
            %
            % The RANGE checks matter more than they look. D-021 defaults TRL
            % to 0 -- deliberately OUTSIDE the scale -- precisely so that "we
            % forgot to set it" cannot masquerade as a plausible mid-pack
            % value, and this is the assertion that collects on that choice.
            % Values are never asserted: three masses are Brandt ground truth
            % (asserted in MassRows) and the rest are Estimates.
            T = testCase.candidateTable();
            testCase.verifyEqual(height(T), size(testCase.CandidateRows,1), ...
                "The candidate table must cover all seven candidates.");
            testCase.verifyEmpty(T.Path(~T.Found), ...
                "Candidate not found in the model: " + strjoin(T.Path(~T.Found), ", ") + ".");
            testCase.verifyEmpty(T.Path(~T.HasStereotype), ...
                "TradeCandidate not applied to: " + ...
                strjoin(T.Path(~T.HasStereotype), ", ") + ".");
            testCase.verifyEmpty(T.Path(T.Role ~= T.ExpectedRole), ...
                "RealizesRole mismatch (found -> expected): " + ...
                strjoin(T.Path(T.Role ~= T.ExpectedRole) + " '" + ...
                        T.Role(T.Role ~= T.ExpectedRole) + "' -> '" + ...
                        T.ExpectedRole(T.Role ~= T.ExpectedRole) + "'", ", ") + ".");
            testCase.verifyEmpty(T.Path(~T.RoleResolves), ...
                "RealizesRole does not name a role that exists in the L model: " + ...
                strjoin(T.Path(~T.RoleResolves) + " -> '" + T.Role(~T.RoleResolves) + "'", ", ") + ".");
            testCase.verifyEmpty(T.Path(T.Kind ~= T.ExpectedKind), ...
                "RealizesKind mismatch (found -> expected): " + ...
                strjoin(T.Path(T.Kind ~= T.ExpectedKind) + " '" + ...
                        T.Kind(T.Kind ~= T.ExpectedKind) + "' -> '" + ...
                        T.ExpectedKind(T.Kind ~= T.ExpectedKind) + "'", ", ") + ".");
            testCase.verifyEmpty(T.Path(~T.KindResolves), ...
                "RealizesKind does not name a kind that exists under its role in the L model: " + ...
                strjoin(T.Path(~T.KindResolves) + " -> '" + T.Kind(~T.KindResolves) + "'", ", ") + ".");
            testCase.verifyEmpty(T.Path(~(T.Mass_lb > 0)), ...
                "TradeCandidate.Mass_lb must be positive on: " + ...
                strjoin(T.Path(~(T.Mass_lb > 0)), ", ") + ".");
            % Benefit is BOXED AT BOTH ENDS, matching the trade study's own
            % guard (D-033). "> 0" was the assertion here for five stages and
            % it was WEAKER THAN THE CODE IT CHECKS: it admits 78, and 78 is
            % not a hypothetical -- it is 7.8 with a slipped decimal point,
            % worth 3.90 against a legitimate per-criterion maximum of 0.50,
            % which is enough to hand the propulsion trade to the wrong
            % candidate and Implement-link REQ_F16A_L01 from the wrong kind
            % without anything else in this suite noticing.
            badBenefit = ~arrayfun(@(b) testCase.onBenefitScale(b), T.Benefit);
            testCase.verifyEmpty(T.Path(badBenefit), ...
                "TradeCandidate.Benefit outside the declared " + testCase.BenefitScale(1) + ...
                ".." + testCase.BenefitScale(2) + " scale (D-033). 0 is the stereotype " + ...
                "default and therefore the 'unset' sentinel, exactly as TRL's 0 is under " + ...
                "D-021; the UPPER bound is the one that matters, because v = B/10 is the " + ...
                "heaviest-weighted term in the trade and an out-of-range value is FINITE " + ...
                "and so invisible to every other check: " + ...
                strjoin(T.Path(badBenefit) + " -> " + T.Benefit(badBenefit), ", ") + ".");
            % Range AND integrality, because the trade study's guard checks
            % both and a test weaker than its guard is a test that will one day
            % be cited as evidence the guard is unnecessary.
            badTRL = ~arrayfun(@(t) testCase.onTRLScale(t), T.TRL);
            testCase.verifyEmpty(T.Path(badTRL), ...
                "TRL outside the integer " + testCase.TRLScale(1) + ".." + ...
                testCase.TRLScale(2) + " scale (D-021 defaults it to 0 on purpose, so " + ...
                "this is what an unset TRL looks like; a fractional TRL is not a point " + ...
                "on an ordinal maturity scale at all): " + ...
                strjoin(T.Path(badTRL) + " -> " + T.TRL(badTRL), ", ") + ".");
            badProv = ~ismember(T.DataProvenance, testCase.DataProvenanceMembers);
            testCase.verifyEmpty(T.Path(badProv), ...
                "DataProvenance outside the " + testCase.DataProvenanceClass + " vocabulary: " + ...
                strjoin(T.Path(badProv) + " -> '" + T.DataProvenance(badProv) + "'", ", ") + ".");
            wrongProv = T.DataProvenance ~= T.ExpectedProvenance;
            testCase.verifyEmpty(T.Path(wrongProv), ...
                "DataProvenance mismatch -- a Brandt figure must be tagged Reference and a " + ...
                "teaching value Estimate (D-007): " + ...
                strjoin(T.Path(wrongProv) + " '" + T.DataProvenance(wrongProv) + "' -> '" + ...
                        T.ExpectedProvenance(wrongProv) + "'", ", ") + ".");
            % A candidate must also SAY it is one. TradeWinner is accepted
            % alongside TradeAlternative so this survives Stage 4.
            badKind = ~ismember(T.SourceKind, testCase.CandidateSourceKinds);
            testCase.verifyEmpty(T.Path(badKind), ...
                "Rationale.SourceKind on a candidate must be one of " + ...
                strjoin(testCase.CandidateSourceKinds, "/") + ": " + ...
                strjoin(T.Path(badKind) + " -> '" + T.SourceKind(badKind) + "'", ", ") + ".");
        end

        function testCostIsNaNEverywhere(testCase)
            % D-005 in one assertion: there is NO cost model, therefore there
            % must be NO cost number -- not on the aircraft Measure of Merit,
            % not on any of the seven candidates. A visible NaN is an honest
            % "pending"; a plausible-looking figure would be an invented one,
            % and the ratio value functions of D-015 would happily score it.
            % This is the test that has to fail the day somebody types a
            % dollar amount anywhere in the trade.
            %
            % The DECLARED DEFAULT is checked first, and it is checked
            % because reading the value alone is what let the last hole
            % hide. MeasureOfMerit.UnitCost_USD defaulted to 0 for five
            % stages while this test stayed green, because the generator
            % happens to write NaN over it on every run (D-032). The latent
            % $0 was one code path away: anything that applied the
            % stereotype without writing the property would have shipped a
            % flyaway cost of zero, and under D-015's ratio value functions
            % a $0 is not neutral -- it is a divide-by-zero or an infinitely
            % good score. That is the same bug D-021 closed on
            % TradeCandidate, which is kept in the sweep as a regression
            % guard rather than assumed to stay fixed.
            badDefaults = testCase.costPropertiesNotDefaultingToNaN();
            testCase.verifyEmpty(badDefaults, ...
                "A cost property must DECLARE " + testCase.CostDefault + " as its " + ...
                "default, not a number that reads as data (D-021, D-032). A value " + ...
                "assertion cannot see this: the generator overwrites the default " + ...
                "every run (stereotype.property -> declared default): " + ...
                strjoin(badDefaults, ", ") + ".");
            ac = testCase.Model.lookup(Path="F16A_Physical/Aircraft");
            momCost = testCase.propNum(ac, testCase.Profile + ".MeasureOfMerit.UnitCost_USD");
            testCase.verifyTrue(isnan(momCost), ...
                "Aircraft MeasureOfMerit.UnitCost_USD is " + momCost + ...
                " -- cost must stay NaN until F16APhysicalCostModel computes one (D-005).");
            T = testCase.candidateTable();
            priced = ~isnan(T.UnitCost_USD);
            testCase.verifyEmpty(T.Path(priced), ...
                "Candidates carry a cost number with no cost model behind it (D-005): " + ...
                strjoin(T.Path(priced) + " -> " + T.UnitCost_USD(priced), ", ") + ".");
        end

        function testExactlyOneActiveCandidatePerRole(testCase)
            % Each variant role resolves exactly one active choice, and that
            % choice is one of its OWN candidates. WHICH one is not asserted
            % here -- the active configuration is pinned by the numbers it
            % produces (OEW, the materials roll-up), not by a name in a test.
            %
            % Second half, a GLOBAL count: the trade has run, so the model
            % carries exactly as many selected candidates as there are roles
            % to decide -- no more (two winners for one role) and no fewer (a
            % role the trade never reached). Active choice and Selected remain
            % different things: one is how the model is configured, the other
            % is the trade's recorded verdict. That they must AGREE, per role,
            % is testTradeSelectedExactlyOneWinnerPerRole; this is only the
            % arithmetic that would catch a whole role dropping out.
            d = testCase.activeChoiceDefects();
            testCase.verifyEmpty(d.NoActive, ...
                "Variant role without exactly one active choice: " + ...
                strjoin(d.NoActive, ", ") + ".");
            testCase.verifyEmpty(d.Foreign, ...
                "Active choice is not one of the role's own candidates: " + ...
                strjoin(d.Foreign, ", ") + ".");
            T = testCase.candidateTable();
            testCase.verifyEqual(sum(T.Selected), size(testCase.VariantRows,1), ...
                "Expected one selected candidate per variant role (" + ...
                size(testCase.VariantRows,1) + "), found " + sum(T.Selected) + ...
                ": {" + strjoin(T.Path(T.Selected), ", ") + "}.");
        end

        function testOEWCountsOnlyTheActiveConfiguration(testCase)
            % The load-bearing one. Turning three components into variant
            % roles must not change what the aircraft weighs: OEW is still
            % the Brandt 19,980.73 lb (D-003).
            %
            % The failure this guards against is the quiet one. An
            % architecture-side walk that recurses through getChoices instead
            % of getActiveChoice sums every candidate and inflates OEW by the
            % four losers -- a number that is still a plausible aeroplane, so
            % nothing else in the suite would notice. Both sums are computed
            % here FROM THE MODEL and compared, so the diagnostic names the
            % two figures instead of just reporting a tolerance miss.
            r = testCase.massRollup();
            activeSum = testCase.leafMassSum("active");
            allSum    = testCase.leafMassSum("all");
            testCase.verifyEqual(r.OEW, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "OEW must be the Brandt " + testCase.ExpectedOEW_lb + " lb; the variant " + ...
                "restructure adds candidates, it does not add mass (D-003).");
            testCase.verifyEqual(activeSum, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "The active-configuration leaf sum computed here is " + activeSum + ...
                " lb, not " + testCase.ExpectedOEW_lb + " lb.");
            testCase.verifyEqual(r.OEW, activeSum, "AbsTol", 0.05, ...
                "The roll-up (" + r.OEW + " lb) and the active-only walk (" + activeSum + ...
                " lb) disagree.");
            % Non-vacuity: if the losing candidates carried no PhysicalItem
            % mass, the two sums would be identical and the check below could
            % never detect double counting. A lumped candidate with no mass
            % is also a real bug -- selecting it would delete its weight.
            testCase.verifyGreaterThan(allSum, activeSum + 1, ...
                "The all-candidates sum (" + allSum + " lb) is not meaningfully larger than " + ...
                "the active sum (" + activeSum + " lb): the inactive candidates carry no " + ...
                "PhysicalItem.Mass_lb, so this test cannot detect double counting -- and " + ...
                "activating one of them would silently drop its weight from OEW.");
            testCase.verifyLessThan(r.OEW, allSum - 1, ...
                "OEW (" + r.OEW + " lb) has reached the ALL-CANDIDATES sum (" + allSum + ...
                " lb): the roll-up is counting inactive candidates. Descend into " + ...
                "getActiveChoice, not getChoices (D-012).");
        end

        function testCandidateMassMatchesItsModelledParts(testCase)
            % The mass a candidate is SCORED on must be the mass it would
            % actually contribute. For the decomposed airframe candidate that
            % means TradeCandidate.Mass_lb equals the sum of its six parts;
            % for a lumped candidate it means it equals its own
            % PhysicalItem.Mass_lb. Without this, the trade study can score a
            % candidate on one number while the model builds another, and the
            % roll-up and the decision quietly stop describing the same
            % aeroplane.
            T = testCase.candidateTable();
            off = abs(T.Mass_lb - T.ModelledMass_lb) > 0.01;
            testCase.verifyEmpty(T.Path(off), ...
                "TradeCandidate.Mass_lb disagrees with the mass the model actually " + ...
                "carries (scored -> modelled): " + ...
                strjoin(T.Path(off) + " " + T.Mass_lb(off) + " -> " + T.ModelledMass_lb(off), ", ") + ".");
        end

        function testCandidateOrderingMatchesTheIntendedLesson(testCase)
            % Relationships, not values (the parameters are Estimates). Two
            % orderings carry the teaching content of D-015:
            %   * in every role the production candidate is the lightest, so
            %     the mass-ratio value function points at the F-16A that was
            %     actually built;
            %   * the winning engine does NOT have the best Benefit. That is
            %     the whole point of the engine trade -- it is won on
            %     maturity and installed mass despite a mid-pack benefit --
            %     and if a data revision ever makes the winner best at
            %     everything, the example stops teaching a trade-off.
            heavier = testCase.rolesWhereBrandtCandidateIsNotLightest();
            testCase.verifyEmpty(heavier, ...
                "The production candidate is not the lightest in: " + ...
                strjoin(heavier, ", ") + ". D-015 scores mass as a ratio to the Brandt " + ...
                "baseline, so this changes which candidate the trade should pick.");
            best = testCase.highestBenefitPaths("PropulsionSystem");
            testCase.verifyNotEmpty(best, ...
                "No propulsion candidate has a readable Benefit, so the ordering below " + ...
                "cannot be judged either way.");
            testCase.verifyFalse( ...
                ismember("Propulsion/Engine/" + testCase.BrandtEngine, best), ...
                "The production engine now has the highest Benefit of its role. The engine " + ...
                "trade is supposed to be won on maturity and installed mass DESPITE a " + ...
                "mid-pack benefit (D-015) -- with this data there is no trade-off left to teach.");
        end

        function testMaterialsRollupFollowsActiveAirframe(testCase)
            % REQ_F16A_022's evidence must describe the aeroplane that is
            % actually configured. The roll-up is compared against a fraction
            % this test computes over the ACTIVE airframe candidate's own
            % parts, discovered from the model -- not over a hard-coded
            % .../Airframe/Wing path, which is exactly what would keep
            % working while silently reporting the wrong airframe.
            %
            % The airframe MASS is the sharper discriminator: 6722.88 lb is
            % the decomposed candidate, 7300 lb would be the lumped one, and
            % ~14023 lb would be both at once.
            mats = F16APhysicalMaterialsRollup();
            a = testCase.activeAirframeMaterials();
            % The roll-up now reports WHICH airframe its number describes.
            % Compared against the model's active choice, not a name in this
            % file, so the two cannot drift apart unnoticed.
            testCase.verifyEqual(string(mats.ActiveCandidate), a.ActiveName, ...
                "The materials roll-up says it describes '" + string(mats.ActiveCandidate) + ...
                "' but the model's active airframe candidate is '" + a.ActiveName + "'.");
            testCase.verifyEqual(a.NumParts, numel(testCase.AirframeParts), ...
                "The active airframe candidate exposes " + a.NumParts + " parts, expected " + ...
                numel(testCase.AirframeParts) + " -- the roll-up is not looking at the " + ...
                "decomposed candidate.");
            testCase.verifyEqual(mats.AirframeMass_lb, testCase.BrandtAirframeMass_lb, ...
                "AbsTol", 0.01, ...
                "The materials roll-up weighs " + mats.AirframeMass_lb + " lb of airframe; " + ...
                "the active configuration is " + testCase.BrandtAirframeMass_lb + " lb.");
            testCase.verifyEqual(mats.CompositeFraction, a.CompositeFraction, "AbsTol", 1e-9, ...
                "The roll-up's composite fraction (" + mats.CompositeFraction + ") differs " + ...
                "from the mass-weighted fraction over the active candidate's own parts (" + ...
                a.CompositeFraction + ").");
            testCase.verifyEqual(mats.CompositeFraction, testCase.ExpectedCompositeFraction, ...
                "AbsTol", 5e-4, ...
                "Airframe composite fraction should be ~" + testCase.ExpectedCompositeFraction + ...
                " for the active configuration.");
        end

        function testTraceRefsResolve(testCase)
            % Until now "all 26 TraceRefs resolve" was a one-off manual
            % audit: a renamed component or a re-issued requirement id would
            % have broken traceability while the suite stayed green, because
            % nothing ever tried to FOLLOW a reference. This does. Every
            % reference in every Rationale.TraceRef is split on "; " and
            % resolved for real -- requirement ids through find() in the set
            % that OWNS them, model paths through lookup on the L or P model.
            %
            % The negative control comes first and runs through the SAME
            % resolver. A resolver that returns true unconditionally would
            % make the sweep below meaningless, so the test proves it can
            % still say no before it trusts it saying yes.
            resolvedBogus = testCase.BogusTraceRefs(arrayfun( ...
                @(r) testCase.traceRefResolves(r), testCase.BogusTraceRefs));
            testCase.verifyEmpty(resolvedBogus, ...
                "The TraceRef resolver claims these deliberately bogus references resolve: " + ...
                strjoin(resolvedBogus, ", ") + ". Every assertion below it is worthless.");
            % A requirement id must resolve in its OWN set. If the sets were
            % not really distinct, routing by id prefix would be untested.
            testCase.verifyEmpty(testCase.findRequirement(testCase.OrigSet, "REQ_F16A_P01"), ...
                "REQ_F16A_P01 is visible in f16a.slreqx, so routing a TraceRef to the " + ...
                "physical derived set proves nothing.");
            testCase.verifyEmpty(testCase.findRequirement(testCase.OrigSet, "REQ_F16A_L01"), ...
                "REQ_F16A_L01 is visible in f16a.slreqx, so routing a TraceRef to the " + ...
                "logical derived set proves nothing.");
            % The sweep.
            refs = testCase.allTraceRefs();
            [parts, ~] = testCase.stereotypableParts();
            testCase.verifyGreaterThanOrEqual(numel(refs), numel(parts), ...
                "Collected " + numel(refs) + " references from " + numel(parts) + ...
                " parts -- every part owes at least one, so references are being lost " + ...
                "before they are ever checked.");
            % All three forms must actually be exercised, so dropping a whole
            % form cannot shrink this test into a green subset of itself.
            testCase.verifyTrue(any(startsWith(refs, testCase.RequirementPrefix)), ...
                "No requirement-id TraceRef was checked at all.");
            testCase.verifyTrue(any(startsWith(refs, testCase.LogicalPathPrefix)), ...
                "No logical-model-path TraceRef was checked at all.");
            testCase.verifyTrue(any(startsWith(refs, testCase.PhysicalPathPrefix)), ...
                "No physical-model-path TraceRef was checked at all.");
            unresolved = testCase.unresolvedTraceRefs();
            testCase.verifyEmpty(unresolved, ...
                "TraceRef does not resolve -- the reference names something that no longer " + ...
                "exists, or is not written in a recognised form (REQ_F16A_*, " + ...
                "F16A_Logical/..., F16A_Physical/...): " + strjoin(unresolved, ", ") + ".");
        end

        function testFuelTankProvenanceTagged(testCase)
            % D-023. The 3 x 2100 lb split is an even division of a rounded
            % figure, not Brandt's 6296.30 lb mission fuel -- an Estimate in
            % substance that carried no tag only because FuelTank had nowhere
            % to put one. It is the oldest untagged number in the model, and
            % "no agent invents a number" has to apply retroactively.
            offenders = testCase.tanksWithProvenanceOtherThan(testCase.FuelTankProvenance);
            testCase.verifyEmpty(offenders, ...
                "Expected FuelTank.DataProvenance = " + testCase.FuelTankProvenance + ...
                " on every tank (D-023): " + strjoin(offenders, ", ") + ".");
        end

        % ---------------- Stage 4: the recorded decision -----------------

        function testTradeSelectedExactlyOneWinnerPerRole(testCase)
            % The trade writes its verdict in two independent places -- the
            % candidate's Selected flag and the variant's ACTIVE CHOICE -- and
            % this is the assertion that they say the same thing.
            %
            % Disagreement is the specific failure worth catching, because
            % each half looks fine on its own. A model whose active choice is
            % the F100 while Selected sits on the F110 has a decision that was
            % HALF WRITTEN: every mass number would describe the F100 and
            % every trade report the F110, and nothing else in this suite
            % would notice. Two-selected-in-one-role is the same bug seen from
            % the other side -- a re-run that recorded a new winner without
            % clearing the old one.
            d = testCase.tradeSelectionDefects();
            testCase.verifyEmpty(d.WrongCount, ...
                "A role must have exactly one selected candidate -- the trade picks " + ...
                "one winner, and a re-run must clear the previous one: " + ...
                strjoin(d.WrongCount, "; ") + ".");
            testCase.verifyEmpty(d.Disagree, ...
                "The trade's verdict (TradeCandidate.Selected) and the model's " + ...
                "configuration (the active variant choice) disagree, so the decision " + ...
                "was only half written: " + strjoin(d.Disagree, "; ") + ".");
        end

        function testWinnersCarryTradeWinnerRationale(testCase)
            % D-006 says every part must be able to answer "why do you exist?"
            % by query. After a trade, three of the seven candidates have a
            % new answer and four have a different one, and both matter: the
            % winner says TradeWinner, and every loser says TradeAlternative
            % -- on the record as an option that was considered and rejected,
            % which is the entire reason D-002 keeps losers in the model.
            %
            % The winner must also CITE ITS SCORE. Without that the rationale
            % and the arithmetic are two unrelated artifacts, and a re-scored
            % trade could change the winner while leaving a justification that
            % still argues for the old one. The score VALUE is not asserted
            % (D-015: it is computed from Estimates); only that a score-shaped
            % token is there.
            d = testCase.winnerRationaleDefects();
            testCase.verifyEqual(d.NumWinners, size(testCase.VariantRows,1), ...
                "Found " + d.NumWinners + " selected candidates, expected " + ...
                size(testCase.VariantRows,1) + ". With none, every winner check " + ...
                "below would pass vacuously.");
            testCase.verifyEmpty(d.WrongKind, ...
                "Rationale.SourceKind must be " + testCase.WinnerSourceKind + " on the " + ...
                "selected candidate and " + testCase.AlternativeSourceKind + " on every " + ...
                "other (found -> expected): " + strjoin(d.WrongKind, "; ") + ".");
            testCase.verifyEmpty(d.ThinJustification, ...
                "A winner's Justification is shorter than " + ...
                testCase.MinJustificationLength + " characters -- the trade rewrote it " + ...
                "with something that does not explain anything: " + ...
                strjoin(d.ThinJustification, "; ") + ".");
            testCase.verifyEmpty(d.NoScore, ...
                "A winner's Justification cites no score (no token matching " + ...
                testCase.ScoreTokenPattern + "), so the rationale in the model and the " + ...
                "arithmetic that produced it are not tied together: " + ...
                strjoin(d.NoScore, "; ") + ".");
        end

        function testDecisionRequirementsImplemented(testCase)
            % D-010, arriving in its new home. REQ_F16A_L01..L03 record three
            % decisions L is not allowed to make, and they stay UNIMPLEMENTED
            % from Stage 1 until the physical trade study answers them
            % (D-019). Because it is P that writes these links, this is a P
            % assertion: putting it in the L suite would make L pass or fail
            % according to whether P had been run, which is the layer coupling
            % the whole restructure removes.
            %
            % The link TYPE is checked, not just its existence. A Relate or a
            % Derive link would leave the requirement showing as unimplemented
            % in the Requirements Editor while this test went green.
            d = testCase.decisionRequirementDefects();
            testCase.verifyEmpty(d.Missing, ...
                "Decision requirement not found in f16a_logical_derived.slreqx: " + ...
                strjoin(d.Missing, ", ") + ".");
            testCase.verifyEmpty(d.Unlinked, ...
                "Decision requirement has no incoming link. The physical trade study " + ...
                "is what implements these (D-010, D-019); until it runs they are " + ...
                "correctly un-implemented, and after it runs this is how we know it " + ...
                "did: " + strjoin(d.Unlinked, ", ") + ".");
            testCase.verifyEmpty(d.NotImplement, ...
                "Decision requirement is linked but not by an " + ...
                testCase.ImplementLinkType + " link, so it still reads as " + ...
                "unimplemented (id -> link types found): " + ...
                strjoin(d.NotImplement, "; ") + ".");
        end

        function testProductionConfigurationWins(testCase)
            % The one Stage-4 assertion made on VALUES rather than
            % relationships, because these three names are ground truth about
            % an aeroplane that exists: the F-16A flew with an F100-PW-200, a
            % blended cranked-delta wing with LERX, and fly-by-wire.
            %
            % The scores are NOT asserted. They are computed from illustrative
            % Estimates (D-015) and revising them is legitimate; a revision
            % that changed the WINNER is not, because the example would then
            % be teaching a trade study that picks an aircraft nobody built.
            % That is the line this test draws.
            won = testCase.selectedCandidateNames();
            testCase.verifyEqual(won, sort(testCase.ExpectedWinners), ...
                "The trade must select the production F-16A configuration. Selected: {" + ...
                strjoin(won, ", ") + "}, expected: {" + ...
                strjoin(sort(testCase.ExpectedWinners), ", ") + "}.");
        end

        function testEngineTradeIsNotWonOnBenefit(testCase)
            % The lesson of D-015, made executable. The engine trade exists to
            % show that a weighted trade is not a beauty contest: the F100
            % wins with a MID-PACK benefit (the F110 is rated higher) because
            % it is the most mature and the lightest installed. That is a
            % real trade-off, and it is the only thing in this example that
            % demonstrates one.
            %
            % It is also fragile in a specific way. Nothing stops a future
            % data revision from nudging the F100's benefit to the top of its
            % role: every other test would stay green, the F100 would still
            % win, and the example would quietly have become "the best
            % candidate at everything also scores best" -- which teaches
            % nothing. So the RELATIONSHIP is asserted in both directions:
            % not the best on benefit, uniquely the best on the two criteria
            % it is actually supposed to win on.
            %
            % The winner is read from the model's Selected flag rather than
            % from BrandtEngine, so this describes the trade's real output.
            role   = "PropulsionSystem";
            winner = testCase.selectedPathInRole(role);
            testCase.verifyNumElements(winner, 1, ...
                "Expected exactly one selected propulsion candidate; found " + ...
                numel(winner) + ". Nothing below can be judged without one.");
            testCase.verifyFalse(any(ismember(winner, testCase.highestBenefitPaths(role))), ...
                "The winning engine now has the highest Benefit of its role. The engine " + ...
                "trade is supposed to be won on maturity and installed mass DESPITE a " + ...
                "mid-pack benefit (D-015) -- with this data there is no trade-off left " + ...
                "to teach, only a candidate that is best at everything.");
            testCase.verifyEqual(testCase.highestTRLPaths(role), winner, ...
                "The winning engine must be the uniquely most mature candidate of its " + ...
                "role -- TRL is one of the two criteria it wins on (D-015). Highest " + ...
                "TRL: {" + strjoin(testCase.highestTRLPaths(role), ", ") + "}, winner: " + ...
                strjoin(winner, ", ") + ".");
            testCase.verifyEqual(testCase.lowestMassPaths(role), winner, ...
                "The winning engine must be the uniquely lightest candidate of its role " + ...
                "-- installed mass is the other criterion it wins on (D-015). Lightest: {" + ...
                strjoin(testCase.lowestMassPaths(role), ", ") + "}, winner: " + ...
                strjoin(winner, ", ") + ".");
        end

        function testOEWReflectsTheSelectedConfiguration(testCase)
            % The decision and the measurement, tied together. OEW is still
            % the Brandt 19,980.73 lb -- a trade that picks the production
            % configuration cannot change what the production aeroplane
            % weighs (D-003) -- and it is the sum over the candidates the
            % trade SELECTED.
            %
            % That second sum is what makes this different from
            % testOEWCountsOnlyTheActiveConfiguration, which walks the ACTIVE
            % CHOICE. Here the walk descends by TradeCandidate.Selected
            % instead, so the number is derived from the verdict rather than
            % from the configuration. The two agree only because the decision
            % was written consistently, which is exactly the property worth
            % measuring: if the trade ever selected one candidate while
            % leaving another active, the OEW the aircraft reports would stop
            % describing the aircraft the trade chose.
            r = testCase.massRollup();
            selectedSum = testCase.leafMassSum("selected");
            testCase.verifyEqual(r.OEW, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "OEW must still be the Brandt " + testCase.ExpectedOEW_lb + " lb; the " + ...
                "trade selects the production configuration, so it changes no mass (D-003).");
            testCase.verifyEqual(selectedSum, testCase.ExpectedOEW_lb, "AbsTol", 0.05, ...
                "Summing the leaves under the SELECTED candidates gives " + selectedSum + ...
                " lb, not " + testCase.ExpectedOEW_lb + " lb. Either a winner carries " + ...
                "the wrong PhysicalItem.Mass_lb, or a role has no winner at all and its " + ...
                "whole subtree dropped out of the sum.");
            testCase.verifyEqual(r.OEW, selectedSum, "AbsTol", 0.05, ...
                "The roll-up (" + r.OEW + " lb, which follows the ACTIVE choice) and the " + ...
                "sum over the SELECTED candidates (" + selectedSum + " lb) disagree: the " + ...
                "aircraft is not configured with the candidates the trade chose.");
        end

        % ---------------- Stage 5 audit: provenance is complete ----------

        function testProvenanceDeclaredOnEveryValueBearingStereotype(testCase)
            % The gap the Stage-5 audit had to find BY HAND, made
            % executable. testRationaleVocabularyIsClosed already asserted
            % that TradeCandidate.DataProvenance and Rationale.SourceKind
            % are enum-typed -- but nothing anywhere said WHICH stereotypes
            % owe a DataProvenance at all. So Material could declare
            % CompositeFraction and nothing else, seven invented numbers sat
            % in the shipped model with no tag of any kind, and the whole
            % suite stayed green (D-031). The provenance vocabulary is worth
            % nothing if it is applied only where somebody happened to
            % remember.
            %
            % FAIL-CLOSED, which is the entire design of this test. It does
            % not check a list of stereotypes that need provenance; it takes
            % every stereotype the P profile DECLARES, subtracts
            % ProvenanceExemptStereotypes, and requires the remainder to
            % declare DataProvenance typed by F16ADataProvenance. A
            % stereotype added tomorrow to hold engineering values is
            % therefore in the required set the day it appears and fails
            % until somebody either tags it or names it as an exemption --
            % and naming an exemption is a line in a diff with a reason
            % beside it, which is what an exemption should cost. The
            % obvious alternative, listing the three stereotypes that need
            % tags, passes by omission forever; that is how the Material
            % gap survived five stages.
            profileNames = testCase.physicalProfileNames();
            testCase.verifyTrue(ismember(testCase.Profile, profileNames), ...
                "The P model does not resolve the " + testCase.Profile + " profile, " + ...
                "so there is no declared stereotype set to reason about. Resolved: {" + ...
                strjoin(profileNames, ", ") + "}.");
            d = testCase.provenanceDeclarationDefects();
            % Non-vacuity, from both ends. An empty required set would make
            % the sweep below pass while asserting nothing -- whether it got
            % there because the profile walk found no stereotypes or because
            % the exemption list swallowed them all.
            testCase.verifyNotEmpty(d.Required, ...
                "No stereotype requires provenance, so this test asserts nothing. " + ...
                "Either the profile walk reached no stereotypes or every one of them " + ...
                "has been exempted.");
            missingKnown = setdiff(testCase.KnownValueBearingStereotypes, d.Required);
            testCase.verifyEmpty(missingKnown, ...
                "These stereotypes carry engineering values a human chose and must be " + ...
                "in the required set, but are not: " + strjoin(missingKnown, ", ") + ...
                ". Either they are no longer declared by the profile, or somebody has " + ...
                "exempted them -- and an exemption is how an invented number stops " + ...
                "being checked.");
            testCase.verifyEmpty(d.StaleExemption, ...
                "Exempted stereotype is not declared by the profile at all, so the " + ...
                "exemption is stale -- and a stale exemption is a trap: it silently " + ...
                "exempts whatever takes that name next: " + ...
                strjoin(d.StaleExemption, ", ") + ".");
            testCase.verifyEmpty(d.Undeclared, ...
                "Stereotype carries engineering values but declares no " + ...
                testCase.ProvenanceProperty + " property, so its numbers cannot be " + ...
                "tagged in the model at all -- exactly the D-031 gap. Add the " + ...
                "property, or name the stereotype in ProvenanceExemptStereotypes " + ...
                "with a reason: " + strjoin(d.Undeclared, ", ") + ".");
            testCase.verifyEmpty(d.WrongType, ...
                testCase.ProvenanceProperty + " must be typed " + ...
                testCase.DataProvenanceClass + " so the vocabulary is validated " + ...
                "rather than free text (D-011); with a string property 'Estimte' is " + ...
                "a valid tag and every provenance query quietly misses that part " + ...
                "(stereotype -> declared type): " + strjoin(d.WrongType, ", ") + ".");
        end

        function testInventedNumbersAreTagged(testCase)
            % The other half of D-031, and the half that reads the MODEL.
            % Declaring DataProvenance on a stereotype means nothing if a
            % component can apply that stereotype and leave the tag
            % unreadable, so this walks every component -- through
            % getChoices, so the seven candidates are reached at all
            % (Stage-0 finding 6) -- and requires each one carrying a
            % value-bearing stereotype to hold a tag from the four-member
            % vocabulary.
            %
            % Then the sharper claim, which is what D-030 actually records.
            % The seven CompositeFraction values and the three fuel
            % capacities are not merely tagged, they are tagged ESTIMATE:
            % the composite fractions were tuned until the mass-weighted
            % figure landed just inside REQ_F16A_022's 20% cap, and a number
            % chosen to make a requirement pass is the last number in the
            % model that may look sourced. The fuel split is Brandt's
            % 6296.30 lb rounded and divided three ways (D-023).
            %
            % The COUNT is pinned to the inventory on purpose. Tagging is a
            % property of the values that exist; the census is a property of
            % the LOG. An eighth composite fraction is an eighth invented
            % number, and D-030 has to grow a row for it before this test
            % can go green again -- which is the discipline D-007 asks for
            % and D-030 exists because nobody kept.
            %
            % TradeCandidate is deliberately outside the Estimate census:
            % three of its seven are Brandt figures tagged Reference, so its
            % per-candidate expectation lives in CandidateRows and is
            % asserted by testCandidatesCarryTradeParameters.
            d = testCase.provenanceTagDefects();
            testCase.verifyNotEmpty(d.Checked, ...
                "No component carries a value-bearing stereotype, so nothing was " + ...
                "checked and every assertion below is vacuous. A walk that skips a " + ...
                "variant's choices reports exactly this (Stage-0 finding 6).");
            testCase.verifyEmpty(d.Untagged, ...
                "Component carries a stereotype that holds chosen engineering values, " + ...
                "but its " + testCase.ProvenanceProperty + " is not one of {" + ...
                strjoin(testCase.DataProvenanceMembers, ", ") + "}. An untagged " + ...
                "invented number is what D-007 forbids and what f16a-data vetoes " + ...
                "(path [stereotype] -> found): " + strjoin(d.Untagged, ", ") + ".");
            c = testCase.estimateCensusDefects();
            testCase.verifyEmpty(c.CountMismatch, ...
                "The model carries a different number of invented values than D-030 " + ...
                "inventories. Each of these is a number somebody chose, so the " + ...
                "decision log has to list it before the census can match again " + ...
                "(D-007, D-030): " + strjoin(c.CountMismatch, "; ") + ".");
            testCase.verifyEmpty(c.NotEstimate, ...
                "These values are invented for teaching and must say so: expected " + ...
                testCase.ProvenanceProperty + " = " + testCase.EstimateProvenance + ...
                ". Tagging one of them Reference or Datasheet would claim a source " + ...
                "that does not exist, which is the failure mode D-007 was written to " + ...
                "prevent (path [stereotype.property] -> found): " + ...
                strjoin(c.NotEstimate, ", ") + ".");
        end

        % ------- Stage 5 audit: the trade study's guard rails -------------
        %
        % READ THIS BEFORE ADDING TO THIS SECTION -- it is about what these
        % three tests deliberately do NOT do, and where the other half is.
        %
        % Stage 5 gave F16APhysicalTradeStudy guards that stop the run on a
        % parameter that cannot honestly be scored, and D-035's warning for a
        % value function above its declared ceiling. NONE OF THEM IS MADE TO
        % FIRE HERE, and none should be. What these three pin is the guards'
        % INPUT CONTRACT, read off the SHIPPED MODEL: the same bounds, the
        % same baseline-uniqueness rule, the same ceiling, plus a negative
        % control proving the bounds can still say no. That is the DATA half
        % -- somebody types 78, adds a second Reference candidate, or clones a
        % candidate's parameters -- and it needs the model to be loaded, which
        % is why it lives in this file.
        %
        % THE CODE HALF -- the guard itself being weakened or deleted -- is
        % F16APhysicalTradeGuardsTest, and it is a separate file for a
        % concrete reason. checkParameters, the tie check and the ceiling
        % check now live in F16APhysicalTradeGuards, a class of pure static
        % methods; making one fire is a two-line verifyError on its
        % identifier with no artifact in sight. Attaching that to THIS file's
        % TestClassSetup -- two models, three requirement sets, an allocation
        % set -- would make the one suite whose whole property is touching no
        % artifact fail whenever a model failed to load.
        %
        % Why it was not simply written here in the first place, which is
        % also why it must not be moved back: while the guards were LOCAL
        % functions of F16APhysicalTradeStudy.m the only way to reach one was
        % to run the whole study, and that run stops early only while the
        % guard still works. Feeding it Benefit = 78 would, on the day the
        % bound was refactored away, run to completion and save a wrong
        % winner, a wrong L active kind and a wrong Implement link into the
        % shipped artifacts -- corrupting the repository precisely when the
        % test was supposed to catch something.
        %
        % The bounds these tests judge by are now IMPORTED from the guard
        % (TRLScale / BenefitScale / ValueCeilingTol above), so the data half
        % and the code half cannot be checking different numbers.
        %
        % What is still uncovered in BOTH files: the study's guards that are
        % entangled with the discovery walk or that need a model handle. Those
        % are named in "NOT COVERED HERE" at the top.

        function testTradeParameterScalesRejectWhatTheyExistToReject(testCase)
            % The negative control for the two range sweeps in
            % testCandidatesCarryTradeParameters, in the same shape as
            % testTraceRefsResolve's BogusTraceRefs: a check that can only
            % ever say yes asserts nothing, so the scales are made to say NO
            % before they are trusted to say yes.
            %
            % It also makes the BOUNDS THEMSELVES load-bearing. Without it,
            % the cheapest way to make an awkward Benefit pass is to widen
            % BenefitScale, and every other assertion in this file stays
            % green -- the test would have been quietly converted into the
            % "> 0" it just replaced. The two values that matter are not
            % arbitrary: 0 is the stereotype default meaning "nobody set
            % this" (D-021, D-033), and 78 is 7.8 with a slipped decimal
            % point, which D-033 traces all the way to a wrong Implement
            % link on REQ_F16A_L01.
            %
            % Both directions are asserted. A scale that rejects everything
            % would pass the first half and fail the aeroplane.
            wronglyAccepted = testCase.RejectedBenefits( ...
                arrayfun(@(b) testCase.onBenefitScale(b), testCase.RejectedBenefits));
            testCase.verifyEmpty(wronglyAccepted, ...
                "The Benefit scale accepts values it exists to reject: {" + ...
                testCase.numList(wronglyAccepted) + "}. 0 is the 'unset' sentinel " + ...
                "and 78 is 7.8 with a slipped decimal point (D-033) -- if either passes, " + ...
                "the Benefit sweep in testCandidatesCarryTradeParameters is no stronger " + ...
                "than the '> 0' it replaced.");
            wronglyRejected = testCase.AcceptedBenefits( ...
                ~arrayfun(@(b) testCase.onBenefitScale(b), testCase.AcceptedBenefits));
            testCase.verifyEmpty(wronglyRejected, ...
                "The Benefit scale rejects legitimate values: {" + ...
                testCase.numList(wronglyRejected) + "}. The declared scale is " + ...
                testCase.BenefitScale(1) + ".." + testCase.BenefitScale(2) + " INCLUSIVE, " + ...
                "so a scale that excludes its own endpoints would fail candidates that " + ...
                "are perfectly well specified.");
            wronglyAcceptedTRL = testCase.RejectedTRLs( ...
                arrayfun(@(t) testCase.onTRLScale(t), testCase.RejectedTRLs));
            testCase.verifyEmpty(wronglyAcceptedTRL, ...
                "The TRL scale accepts values it exists to reject: {" + ...
                testCase.numList(wronglyAcceptedTRL) + "}. 0 is D-021's fail-safe " + ...
                "default -- the whole reason TRL is boxed below 1 is that an unset TRL " + ...
                "must not score as a plausible mid-pack value -- and 4.5 is not a point " + ...
                "on an ordinal maturity scale.");
            wronglyRejectedTRL = testCase.AcceptedTRLs( ...
                ~arrayfun(@(t) testCase.onTRLScale(t), testCase.AcceptedTRLs));
            testCase.verifyEmpty(wronglyRejectedTRL, ...
                "The TRL scale rejects legitimate values: {" + ...
                testCase.numList(wronglyRejectedTRL) + "}. The declared scale is " + ...
                testCase.TRLScale(1) + ".." + testCase.TRLScale(2) + " inclusive.");
        end

        function testRatioBaselineIsUniqueAndNothingBeatsIt(testCase)
            % Two of the trade study's guards, checked as preconditions on
            % the shipped data because they cannot be checked as behaviour.
            %
            % FIRST, the baseline is unique per role. Every ratio value
            % function divides by the mass of the role's
            % DataProvenance = Reference candidate (D-015), so with none
            % there is no scale at all and with two there is no answer to
            % "which one" -- which is why the trade study refuses to run.
            % This is a genuinely different claim from
            % rolesWhereBrandtCandidateIsNotLightest, which keys on the
            % hard-coded production names in this file; here the baseline is
            % discovered from the PROVENANCE TAG, exactly as the trade study
            % discovers it, so a retagged candidate is caught.
            %
            % SECOND, D-035's ceiling. v = M_baseline/M has no upper bound,
            % unlike B/10 and (TRL-1)/8 which their declared scales cap at
            % 1.0. A candidate lighter than its baseline scores above 1 and
            % contributes more than its renormalized weight allows, at which
            % point 0.50/0.25/0.25 has stopped describing relative influence.
            %
            % A FAILURE OF THE SECOND HALF IS NOT A BUG IN THE TRADE STUDY.
            % D-035 decided, correctly, neither to cap (that discards a real
            % advantage) nor to error (that rejects a legitimate candidate)
            % but to WARN. So this is a tripwire, not a verdict: it says the
            % known limit has gone from theoretical to armed, the run now
            % emits F16APhysicalTradeStudy:valueAboveCeiling, and the scores
            % must be read knowing the weights understate that criterion.
            % The honest response is to confirm the decision still holds and
            % then to do the deferred fix -- a bounded value function over a
            % declared range per criterion -- not to delete the offending
            % candidate.
            d = testCase.baselineDefects();
            testCase.verifyNotEmpty(d.Checked, ...
                "No candidate was scored against a baseline, so both assertions below " + ...
                "are vacuous. Either the candidate table is empty or no role has a " + ...
                testCase.BaselineProvenance + "-tagged candidate at all.");
            testCase.verifyEmpty(d.NoUniqueBaseline, ...
                "A role must have EXACTLY ONE candidate tagged DataProvenance = " + ...
                testCase.BaselineProvenance + ". It is the baseline every ratio value " + ...
                "function divides by (D-015): with none there is no scale, with two " + ...
                "there is no answer to which one, and the trade study stops rather " + ...
                "than guess: " + strjoin(d.NoUniqueBaseline, "; ") + ".");
            testCase.verifyEmpty(d.AboveCeiling, ...
                "A candidate is LIGHTER THAN ITS ROLE'S BASELINE, so the mass value " + ...
                "function M_baseline/M exceeds the 1.0 ceiling the declared scales " + ...
                "imply and the renormalized weights no longer describe relative " + ...
                "influence (D-035). This is a KNOWN LIMIT, not a defect in the " + ...
                "candidate: nothing is capped and nothing is rejected, the trade study " + ...
                "warns and carries on, and the advantage is real. What it means is that " + ...
                "the scores for this role must be read knowing the weights understate " + ...
                "this criterion, and that D-035's deferred fix -- a bounded value " + ...
                "function over a declared range per criterion -- now has a live case: " + ...
                strjoin(d.AboveCeiling, "; ") + ".");
        end

        function testNoRoleHasTwoIdenticallyParameterizedCandidates(testCase)
            % The tie guard's precondition. The trade study REFUSES to break
            % a tie for first place -- sort order is not a decision, and a
            % model that let one through would record a winner the data
            % never chose -- so the shipped data must not be able to produce
            % one trivially.
            %
            % Two candidates of a role carrying the same Benefit, TRL and
            % Mass_lb tie under ANY weighting, whatever the weights are
            % renormalized to and whichever criteria get dropped. That is
            % the one tie that can be ruled out by looking at inputs alone,
            % and it is the one a copy-paste in generate_f16a_physical.m
            % actually produces.
            %
            % IT DOES NOT PROVE THERE IS NO TIE. Two candidates with
            % different parameters can still score equal, and detecting that
            % needs the score -- which this file deliberately does not
            % recompute, because a test that re-derived the trade study's
            % arithmetic would agree with it by construction and catch
            % nothing (the V&V rule against writing the assertion and the
            % code the same way). The unique winner that the shipped data
            % actually produces is asserted from the MODEL, by
            % testTradeSelectedExactlyOneWinnerPerRole.
            dupes = testCase.duplicateParameterDefects();
            testCase.verifyEmpty(dupes, ...
                "Two candidates of one role carry identical trade parameters, so they " + ...
                "score identically under any weighting and the role is a tie for first " + ...
                "place. The trade study errors rather than break it " + ...
                "(F16APhysicalTradeStudy:tie): sort order is not a decision. Separate " + ...
                "them with data or add a criterion: " + strjoin(dupes, "; ") + ".");
        end

    end

    % =====================================================================
    % Helpers. All model/profile traversal lives here so the test methods
    % above stay Arrange-Act-Assert and every R2026a API call sits in
    % exactly one place.
    % =====================================================================
    methods (Access = private)

        function tf = resolves(testCase, pth)
            tf = ~isempty(testCase.componentAt(pth));
        end

        function c = componentAt(testCase, fullPath)
            % A component by its ARCHITECTURE path -- the path space that
            % carries the variant choice level (Stage-0 finding 3), e.g.
            % .../Airframe/BlendedCrankedDelta/Wing. lookup is tried first;
            % if it cannot cross a variant boundary the getChoices-aware walk
            % resolves the same path, so a candidate, a child of a candidate
            % and a plain part are all reached by one call. Returns EMPTY
            % when the path names nothing, which every caller reports.
            try c = testCase.Model.lookup(Path=char(fullPath)); catch, c = []; end
            if ~isempty(c); return; end
            [comps, paths] = testCase.walkComponents();
            idx = find(paths == erase(string(fullPath), testCase.PhysicalPathPrefix), 1);
            if ~isempty(idx); c = comps{idx}; end
        end

        function v = propNum(~, comp, qualified)
            % A numeric stereotype property. NaN when the property cannot be
            % read at all -- which for UnitCost_USD is indistinguishable from
            % the honest NaN, and for everything else fails the range check
            % it feeds, so nothing is swallowed.
            try v = str2double(string(getProperty(comp, char(qualified)))); catch, v = NaN; end
        end

        function s = propText(~, comp, qualified)
            % An enumeration or string stereotype property as plain text.
            % Both come back QUOTED (Stage-0 findings 1 and 7). "" when the
            % property is absent, so a comparison against it fails rather
            % than propagating <missing> through logical indexing.
            try s = strtrim(erase(string(getProperty(comp, char(qualified))), "'")); catch, s = ""; end
            if ~isscalar(s) || ismissing(s); s = ""; end
        end

        function tf = propBool(testCase, comp, qualified)
            % A boolean stereotype property. Read through propText so it
            % copes with the value arriving as a logical, as "true"/"false"
            % or as a quoted expression, without caring which.
            tf = ismember(lower(testCase.propText(comp, qualified)), ["true","1"]);
        end

        function v = massOf(testCase, comp)
            % A component's own PhysicalItem.Mass_lb; 0 when it carries none
            % (an assembly, or a variant role wrapper that cannot hold the
            % stereotype at all).
            v = testCase.propNum(comp, testCase.Profile + ".PhysicalItem.Mass_lb");
            if isnan(v); v = 0; end
        end

        function s = shortName(~, qualified)
            % Last token of "<profile>.<stereotype>.<property>" (or of a bare
            % name, which is returned unchanged).
            parts = split(string(qualified), ".");
            s = parts(end);
        end

        function n = countComps(testCase)
            % Total components reached by the architecture-side walk.
            % Delegates to walkComponents so there is exactly ONE traversal
            % in this file and no naive .Architecture.Components recursion
            % left to go stale when Stage 3 adds variant components.
            [comps, ~] = testCase.walkComponents();
            n = numel(comps);
        end

        function [comps, paths] = walkComponents(testCase)
            % Every component of the P model, as a cell array (Component and
            % VariantComponent are different classes) plus a parallel array
            % of slash-separated walk paths for failure messages. Variant
            % ROLE wrappers are included in the walk; use
            % stereotypableParts to drop them.
            [comps, paths] = testCase.descend(testCase.Model.Architecture, "");
        end

        function [comps, paths] = descend(testCase, arch, prefix)
            comps = {};
            paths = strings(1,0);
            for c = arch.Components
                here = prefix + string(c.Name);
                comps{end+1} = c;      %#ok<AGROW>
                paths(end+1) = here;   %#ok<AGROW>
                [sub, subPaths] = testCase.descendInto(c, here + "/");
                comps = [comps, sub];        %#ok<AGROW>
                paths = [paths, subPaths];   %#ok<AGROW>
            end
        end

        function [comps, paths] = descendInto(testCase, comp, prefix)
            % The one place that knows about variants. A VariantComponent's
            % .Architecture.Components returned its choices on a freshly
            % built in-memory model but ZERO on the same model saved and
            % reloaded (Stage-0 finding 6), so getChoices is the only
            % reliable accessor -- a plain recursion would silently skip
            % every candidate here and report a smaller component count.
            if isa(comp, "systemcomposer.arch.VariantComponent")
                comps = {};
                paths = strings(1,0);
                choices = getChoices(comp);
                for i = 1:numel(choices)
                    here = prefix + string(choices(i).Name);
                    comps{end+1} = choices(i);   %#ok<AGROW>
                    paths(end+1) = here;         %#ok<AGROW>
                    [sub, subPaths] = testCase.descend(choices(i).Architecture, here + "/");
                    comps = [comps, sub];        %#ok<AGROW>
                    paths = [paths, subPaths];   %#ok<AGROW>
                end
            else
                [comps, paths] = testCase.descend(comp.Architecture, prefix);
            end
        end

        function [parts, paths] = stereotypableParts(testCase)
            % The walk MINUS the variant role wrappers, which cannot carry a
            % stereotype at all (D-013 / Stage-0 finding 4). "Every part has
            % a rationale" means every part that can hold one.
            [comps, allPaths] = testCase.walkComponents();
            keep = false(1, numel(comps));
            for i = 1:numel(comps)
                keep(i) = ~isa(comps{i}, "systemcomposer.arch.VariantComponent");
            end
            parts = comps(keep);
            paths = allPaths(keep);
        end

        function names = appliedStereotypes(testCase, elem)
            % Short names of the stereotypes applied to one element.
            % getStereotypes returns a cell array of '<profile>.<stereotype>'.
            qualified = reshape(string(getStereotypes(elem)), 1, []);
            names = strings(1, numel(qualified));
            for i = 1:numel(qualified)
                names(i) = testCase.shortName(qualified(i));
            end
        end

        function txt = rationaleText(testCase, elem, propertyShortName)
            % One Rationale property as plain text. BOTH the enumeration
            % (SourceKind) and the string properties come back QUOTED --
            % getProperty stores and returns a MATLAB expression, so
            % F16ASourceKind.TradeWinner reads back as 'TradeWinner' and
            % "REQ_F16A_026" as 'REQ_F16A_026' (Stage-0 findings 1 and 7).
            % Returns "" when the property cannot be read at all, which
            % every caller reports as a defect rather than swallowing.
            qualified = testCase.Profile + "." + testCase.RationaleStereotype + "." + ...
                propertyShortName;
            try
                raw = string(getProperty(elem, char(qualified)));
            catch
                txt = "";
                return
            end
            txt = strtrim(erase(raw, "'"));
        end

        function d = rationaleDefects(testCase)
            % One pass over every stereotypable part, collecting defects by
            % kind so a failure names the offenders instead of stopping at
            % the first one.
            d.Missing           = strings(1,0);
            d.BadKind           = strings(1,0);
            d.EmptyTrace        = strings(1,0);
            d.ThinJustification = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                where = paths(i);
                if ~ismember(testCase.RationaleStereotype, testCase.appliedStereotypes(parts{i}))
                    d.Missing(end+1) = where;
                    continue
                end
                kind = testCase.rationaleText(parts{i}, "SourceKind");
                if ~ismember(kind, testCase.SourceKindMembers)
                    d.BadKind(end+1) = where + " -> '" + kind + "'";
                end
                if strlength(testCase.rationaleText(parts{i}, "TraceRef")) == 0
                    d.EmptyTrace(end+1) = where;
                end
                just = testCase.rationaleText(parts{i}, "Justification");
                if strlength(just) < testCase.MinJustificationLength
                    d.ThinJustification(end+1) = where + " (" + strlength(just) + " chars)";
                end
            end
        end

        function hits = partsWithSourceKindOtherThan(testCase, partNames, expectedKind)
            % Named parts (direct children of Aircraft) whose SourceKind is
            % not the expected member. Reported with the value found, so the
            % failure says what the model actually claims.
            hits = strings(1,0);
            for nm = partNames
                c = testCase.componentAt(testCase.AC + nm);
                if isempty(c)
                    hits(end+1) = nm + " (not found)";   %#ok<AGROW>
                    continue
                end
                actual = testCase.rationaleText(c, "SourceKind");
                if actual ~= expectedKind
                    hits(end+1) = nm + " -> '" + actual + "'";   %#ok<AGROW>
                end
            end
        end

        function profs = physicalProfiles(testCase)
            % Profiles applied to the P model. model.Profiles is the primary
            % source; the fallbacks cover a session where the .xml has not
            % been pulled in yet. An empty result is left empty on purpose --
            % the caller asserts non-empty so the profile checks can never
            % pass vacuously.
            profs = testCase.Model.Profiles;
            if ~isempty(profs); return; end
            try
                profs = systemcomposer.profile.Profile.find(testCase.Profile);
            catch
                try
                    profs = systemcomposer.profile.Profile.load(testCase.Profile);
                catch
                    profs = [];
                end
            end
        end

        function names = profileStereotypeNames(testCase)
            names = strings(1,0);
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    names(end+1) = testCase.shortName(string(stereotypes(j).Name));   %#ok<AGROW>
                end
            end
            names = unique(names);
        end

        function names = stereotypePropertyNames(testCase, stereotypeShortName)
            % Properties DECLARED by one stereotype of the P profile,
            % independent of whether any element applies it.
            names = strings(1,0);
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    if testCase.shortName(string(stereotypes(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        names(end+1) = testCase.shortName(string(props(k).Name));   %#ok<AGROW>
                    end
                end
            end
            names = unique(names);
        end

        function t = declaredPropertyType(testCase, stereotypeShortName, propertyShortName)
            % The declared TYPE of one stereotype property, "" when the
            % stereotype or the property is not declared at all -- either way
            % the caller's equality check fails with a readable message.
            t = "";
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    if testCase.shortName(string(stereotypes(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        if testCase.shortName(string(props(k).Name)) == propertyShortName
                            t = testCase.typeName(props(k).Type);
                            return
                        end
                    end
                end
            end
        end

        function n = typeName(testCase, rawType)
            % Property.Type is documented as a char vector / string naming
            % the type -- a built-in ("double", "string") or the name of a
            % MATLAB class that defines an enumeration. Normalised here so a
            % quoted or package-qualified spelling still compares equal, and
            % so a surprise object shape fails on the VALUE rather than
            % erroring out of the test.
            try
                s = string(rawType);
            catch
                s = string(class(rawType));
            end
            n = testCase.shortName(strtrim(erase(s, "'")));
        end

        function names = enumerationMembers(~, className)
            % Members of a MATLAB enumeration class, sorted. Empty when the
            % classdef does not resolve on the path -- which is itself the
            % failure the caller reports, since an unresolvable enumeration
            % means the property has no vocabulary to validate against.
            names = strings(1,0);
            mc = meta.class.fromName(char(className));
            if isempty(mc)
                return
            end
            members = mc.EnumerationMemberList;
            for i = 1:numel(members)
                names(end+1) = string(members(i).Name);   %#ok<AGROW>
            end
            names = sort(names);
        end

        function s = sumMasses(testCase, paths)
            s = 0;
            for pth = paths
                s = s + testCase.massOf(testCase.componentAt(pth));
            end
        end

        % ---------------- Stage 3: variants, candidates, traces ----------

        function choices = choicesOf(~, comp)
            % Every choice of a variant component. getChoices is the ONLY
            % reliable accessor on a LOADED model (Stage-0 finding 6).
            % Returns empty for anything that is not a variant, so a caller
            % reports "0 choices" instead of erroring out of its test.
            try choices = getChoices(comp); catch, choices = []; end
        end

        function active = activeChoiceOf(~, comp)
            % The single active choice of a variant component, or empty.
            try active = getActiveChoice(comp); catch, active = []; end
        end

        function names = namesOf(~, comps)
            names = strings(1,0);
            for i = 1:numel(comps)
                names(end+1) = string(comps(i).Name);   %#ok<AGROW>
            end
        end

        function missing = partsWithoutStereotype(testCase, parts, paths, stereotypeShortName)
            missing = strings(1,0);
            for i = 1:numel(parts)
                if ~ismember(stereotypeShortName, testCase.appliedStereotypes(parts{i}))
                    missing(end+1) = paths(i);   %#ok<AGROW>
                end
            end
        end

        function d = variantChoiceCountDefects(testCase)
            % Each variant role holds the number of candidates it is meant
            % to hold, counted through getChoices.
            d = strings(1,0);
            for i = 1:size(testCase.VariantRows,1)
                rel = string(testCase.VariantRows{i,1});
                expected = testCase.VariantRows{i,3};
                vc = testCase.componentAt(testCase.AC + rel);
                if isempty(vc)
                    d(end+1) = rel + " (not found)";   %#ok<AGROW>
                    continue
                end
                n = numel(testCase.choicesOf(vc));
                if n ~= expected
                    d(end+1) = rel + " holds " + n + ", expected " + expected;   %#ok<AGROW>
                end
            end
        end

        function d = activeChoiceDefects(testCase)
            % One active choice per variant role, and it belongs to that
            % role. Defects are collected by kind so the failure says which
            % of the two things went wrong.
            d.NoActive = strings(1,0);
            d.Foreign  = strings(1,0);
            for i = 1:size(testCase.VariantRows,1)
                rel = string(testCase.VariantRows{i,1});
                vc = testCase.componentAt(testCase.AC + rel);
                active = testCase.activeChoiceOf(vc);
                if numel(active) ~= 1
                    d.NoActive(end+1) = rel + " (" + numel(active) + " active)";
                    continue
                end
                own = testCase.namesOf(testCase.choicesOf(vc));
                if ~ismember(string(active.Name), own)
                    d.Foreign(end+1) = rel + " -> '" + string(active.Name) + ...
                        "' not among {" + strjoin(own, ", ") + "}";
                end
            end
        end

        function T = candidateTable(testCase)
            % Every trade parameter of every candidate, read once, in one
            % place. Each test above then asks a single question of this
            % table instead of re-walking the model -- and every getProperty
            % call for the TradeCandidate stereotype lives here.
            rows = testCase.CandidateRows;
            n = size(rows,1);
            Path = strings(n,1); ExpectedRole = strings(n,1);
            ExpectedKind = strings(n,1); ExpectedProvenance = strings(n,1);
            Found = false(n,1); HasStereotype = false(n,1);
            Role = strings(n,1); Kind = strings(n,1);
            RoleResolves = false(n,1); KindResolves = false(n,1);
            Mass_lb = nan(n,1); Benefit = nan(n,1); TRL = nan(n,1);
            UnitCost_USD = nan(n,1); DataProvenance = strings(n,1);
            Selected = false(n,1); SourceKind = strings(n,1);
            ModelledMass_lb = nan(n,1);
            tc = testCase.Profile + "." + testCase.CandidateStereotype + ".";
            for i = 1:n
                Path(i)               = string(rows{i,1});
                ExpectedRole(i)       = string(rows{i,2});
                ExpectedKind(i)       = string(rows{i,3});
                ExpectedProvenance(i) = string(rows{i,4});
                c = testCase.componentAt(testCase.AC + Path(i));
                Found(i) = ~isempty(c);
                if ~Found(i); continue; end
                HasStereotype(i)   = ismember(testCase.CandidateStereotype, ...
                                              testCase.appliedStereotypes(c));
                Role(i)            = testCase.propText(c, tc + "RealizesRole");
                Kind(i)            = testCase.propText(c, tc + "RealizesKind");
                % Resolved against the L MODEL, not against a list in this
                % file: the claim "this realizes that kind" is only worth
                % anything if the kind is still there under that role.
                RoleResolves(i)    = testCase.pathResolves(testCase.LogiModel, ...
                                        testCase.LogicalPathPrefix + Role(i));
                KindResolves(i)    = testCase.pathResolves(testCase.LogiModel, ...
                                        testCase.LogicalPathPrefix + Role(i) + "/" + Kind(i));
                Mass_lb(i)         = testCase.propNum(c, tc + "Mass_lb");
                Benefit(i)         = testCase.propNum(c, tc + "Benefit");
                TRL(i)             = testCase.propNum(c, tc + "TRL");
                UnitCost_USD(i)    = testCase.propNum(c, tc + "UnitCost_USD");
                DataProvenance(i)  = testCase.propText(c, tc + "DataProvenance");
                Selected(i)        = testCase.propBool(c, tc + "Selected");
                SourceKind(i)      = testCase.rationaleText(c, "SourceKind");
                % What the candidate would actually contribute to OEW: its
                % own mass if it is a lumped block, the sum of its parts if
                % it is decomposed.
                ModelledMass_lb(i) = testCase.subtreeLeafMass(c, "all");
            end
            T = table(Path, ExpectedRole, ExpectedKind, ExpectedProvenance, Found, ...
                HasStereotype, Role, Kind, RoleResolves, KindResolves, Mass_lb, ...
                Benefit, TRL, UnitCost_USD, DataProvenance, Selected, SourceKind, ...
                ModelledMass_lb);
        end

        function s = leafMassSum(testCase, mode)
            % Total leaf Mass_lb over the whole model, under three different
            % readings of what "the aircraft" means at a variant:
            %   "active"   -- getActiveChoice: the aeroplane the model is
            %                 CONFIGURED as. What the roll-up measures.
            %   "selected" -- TradeCandidate.Selected: the aeroplane the trade
            %                 CHOSE. Independent of the configuration, which
            %                 is what makes comparing the two worth doing
            %                 (testOEWReflectsTheSelectedConfiguration).
            %   "all"      -- getChoices: what a walk that forgot about
            %                 variants would count -- three engines and two
            %                 airframes. The D-012 failure mode, computed so
            %                 it can be shown NOT to be happening.
            s = 0;
            for c = testCase.Model.Architecture.Components
                s = s + testCase.subtreeLeafMass(c, mode);
            end
        end

        function s = subtreeLeafMass(testCase, comp, mode)
            % Leaves only: assemblies carry no mass of their own, they are
            % overwritten with the sum of their children by the roll-up.
            if isa(comp, "systemcomposer.arch.VariantComponent")
                branches = testCase.choicesOf(comp);
                if mode == "active";   branches = testCase.activeChoiceOf(comp); end
                if mode == "selected"; branches = testCase.selectedChoices(comp); end
                s = 0;
                for i = 1:numel(branches)
                    s = s + testCase.subtreeLeafMass(branches(i), mode);
                end
                return
            end
            kids = comp.Architecture.Components;
            if isempty(kids)
                s = testCase.massOf(comp);
                return
            end
            s = 0;
            for k = kids
                s = s + testCase.subtreeLeafMass(k, mode);
            end
        end

        function a = activeAirframeMaterials(testCase)
            % The mass-weighted composite fraction of whichever airframe
            % candidate is ACTIVE, computed over the parts that candidate
            % actually exposes. Discovering the parts is the point: a
            % hard-coded .../Airframe/Wing would keep working while
            % describing an airframe the aircraft is not configured with.
            a = struct(CompositeFraction = NaN, AirframeMass_lb = 0, ...
                NumParts = 0, ActiveName = "");
            vc = testCase.componentAt(testCase.AC + "Airframe");
            active = testCase.activeChoiceOf(vc);
            if numel(active) ~= 1; return; end
            a.ActiveName = string(active.Name);
            parts = active.Architecture.Components;
            a.NumParts = numel(parts);
            if a.NumParts == 0; return; end
            m  = zeros(1, a.NumParts);
            cf = zeros(1, a.NumParts);
            for i = 1:a.NumParts
                m(i)  = testCase.massOf(parts(i));
                cf(i) = testCase.propNum(parts(i), testCase.Profile + ".Material.CompositeFraction");
            end
            a.AirframeMass_lb   = sum(m);
            a.CompositeFraction = sum(m .* cf) / sum(m);
        end

        function hits = rolesWhereBrandtCandidateIsNotLightest(testCase)
            % Roles in which the production (Brandt) candidate is not the
            % lightest of its set. A RELATIONSHIP, because the competing
            % masses are Estimates and their values are not assertable.
            hits = strings(1,0);
            T = testCase.candidateTable();
            brandt = ["Airframe/" + testCase.BrandtAirframe, ...
                      "Propulsion/Engine/" + testCase.BrandtEngine, ...
                      "FlightControls/" + testCase.BrandtFlightControls];
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                mine = rows.Path(ismember(rows.Path, brandt));
                if numel(mine) ~= 1
                    hits(end+1) = role + " (no single production candidate)";   %#ok<AGROW>
                    continue
                end
                lightest = rows.Path(rows.Mass_lb == min(rows.Mass_lb));
                if ~ismember(mine, lightest)
                    hits(end+1) = role + " (lightest is " + strjoin(lightest, " / ") + ")";   %#ok<AGROW>
                end
            end
        end

        function paths = highestBenefitPaths(testCase, role)
            % The candidate path(s) with the highest Benefit in one role.
            % EMPTY when no benefit is readable, so a test that asks "is the
            % production candidate the best?" can tell "no" apart from
            % "there is nothing to compare".
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.Benefit == max(rows.Benefit));
        end

        function refs = splitTraceRef(~, txt)
            % One TraceRef may name several things, written "a; b". Split
            % and trimmed, so each reference is resolved on its own.
            refs = strtrim(split(string(txt), ";"))';
            refs = refs(strlength(refs) > 0);
        end

        function refs = allTraceRefs(testCase)
            % Every individual reference carried by every part, flattened.
            refs = strings(1,0);
            [parts, ~] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                refs = [refs, testCase.splitTraceRef( ...
                    testCase.rationaleText(parts{i}, "TraceRef"))];   %#ok<AGROW>
            end
        end

        function bad = unresolvedTraceRefs(testCase)
            % Every reference that does not resolve, reported with the part
            % that carries it so the failure names both ends of the broken
            % link.
            bad = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                for ref = testCase.splitTraceRef(testCase.rationaleText(parts{i}, "TraceRef"))
                    if ~testCase.traceRefResolves(ref)
                        bad(end+1) = paths(i) + " -> '" + ref + "'";   %#ok<AGROW>
                    end
                end
            end
        end

        function tf = traceRefResolves(testCase, ref)
            % The resolver. Three recognised forms, and ONLY three: a
            % requirement id, a logical-model path, a physical-model path.
            % Anything else returns false rather than being waved through --
            % an unrecognised TraceRef is untraceable by definition.
            ref = strtrim(string(ref));
            tf = false;
            if startsWith(ref, testCase.RequirementPrefix)
                tf = ~isempty(testCase.findRequirement(testCase.requirementSetFor(ref), ref));
            elseif startsWith(ref, testCase.LogicalPathPrefix)
                tf = testCase.pathResolves(testCase.LogiModel, ref);
            elseif startsWith(ref, testCase.PhysicalPathPrefix)
                tf = ~isempty(testCase.componentAt(ref));
            end
        end

        function reqSet = requirementSetFor(testCase, ref)
            % Which set OWNS an id. Routing by prefix, so a reference that
            % resolves in the wrong set does not count as resolved:
            % REQ_F16A_P* is physical-derived, REQ_F16A_L* is
            % logical-derived, everything else is the original f16a set.
            reqSet = testCase.OrigSet;
            if startsWith(ref, testCase.RequirementPrefix + "P"); reqSet = testCase.PhysSet; end
            if startsWith(ref, testCase.RequirementPrefix + "L"); reqSet = testCase.LogiSet; end
        end

        function r = findRequirement(~, reqSet, id)
            % find on a requirement set returns EMPTY for an unknown id
            % rather than erroring, which is what makes it usable here.
            try r = find(reqSet, Id=char(id)); catch, r = []; end
        end

        function tf = pathResolves(~, model, pth)
            % Does a component path resolve in the given model? Used for the
            % L model (roles and kinds) and as the negative control's route
            % to a definite "no".
            pth = string(pth);
            tf = false;
            if endsWith(pth, "/") || contains(pth, "//"); return; end
            try c = model.lookup(Path=char(pth)); catch, c = []; end
            tf = ~isempty(c);
        end

        function hits = tanksWithProvenanceOtherThan(testCase, expected)
            hits = strings(1,0);
            for t = testCase.FuelTanks
                c = testCase.componentAt(testCase.AC + "FuelSystem/" + t);
                if isempty(c)
                    hits(end+1) = t + " (not found)";   %#ok<AGROW>
                    continue
                end
                actual = testCase.propText(c, testCase.Profile + ".FuelTank.DataProvenance");
                if actual ~= expected
                    hits(end+1) = t + " -> '" + actual + "'";   %#ok<AGROW>
                end
            end
        end

        function [srcCounts, dstNames] = allocEndpoints(testCase)
            % Tally realization sources (logical roles) and collect the set of
            % destination part names.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            srcCounts = containers.Map();
            dstNames = string.empty;
            for a = scenario.Allocations
                s = char(a.Source.Name);
                if isKey(srcCounts, s); srcCounts(s) = srcCounts(s) + 1;
                else; srcCounts(s) = 1; end
                dstNames(end+1) = string(a.Target.Name); %#ok<AGROW>
            end
            dstNames = unique(dstNames);
        end

        function map = allocTargetsByRole(testCase)
            % Realization targets grouped by the logical role they came
            % from. allocEndpoints only counts and de-duplicates; this keeps
            % the PAIRING, which is what "is this candidate realized?" needs.
            scenario = testCase.Alloc.getScenario("Scenario 1");
            map = containers.Map();
            for a = scenario.Allocations
                s = char(a.Source.Name);
                t = string(a.Target.Name);
                if isKey(map, s); map(s) = [map(s), t]; else; map(s) = t; end
            end
        end

        function hits = rolesNotRealizedByAllTheirCandidates(testCase)
            hits = strings(1,0);
            targets = testCase.allocTargetsByRole();
            for i = 1:size(testCase.CandidateRows,1)
                role = string(testCase.CandidateRows{i,2});
                name = testCase.leafName(string(testCase.CandidateRows{i,1}));
                if ~isKey(targets, char(role))
                    hits(end+1) = role + " (realizes nothing) -> " + name;   %#ok<AGROW>
                    continue
                end
                if ~ismember(name, targets(char(role)))
                    hits(end+1) = role + " -> " + name;   %#ok<AGROW>
                end
            end
        end

        function s = leafName(~, pth)
            % Last token of a slash-separated component path.
            parts = split(string(pth), "/");
            s = parts(end);
        end

        function names = leafNames(testCase, paths)
            % leafName over an array, keeping the caller's orientation so a
            % failure message reads in the order the table produced.
            names = strings(size(paths));
            for i = 1:numel(paths)
                names(i) = testCase.leafName(paths(i));
            end
        end

        % ---------------- Stage 4: the recorded decision -----------------

        function r = massRollup(~)
            % The mass roll-up, run WITHOUT persisting. The roll-up's normal
            % job includes writing OEW back to the aircraft's MeasureOfMerit
            % and saving the model; doing that from a test would leave the
            % working tree dirty after every run and, worse, would mean the
            % suite had modified the artifact it was checking. Persist=false
            % skips both.
            %
            % The fallback is deliberate and NOISY. If the option is ever
            % renamed the suite still produces real assertion results instead
            % of erroring out of three tests, but the warning says plainly
            % that the run has just dirtied the model -- so this cannot go
            % unnoticed the way a silent catch would.
            try
                r = F16APhysicalMassRollup(Persist=false);
            catch ME
                warning("F16APhysicalArchitectureTest:persistOption", ...
                    "F16APhysicalMassRollup(Persist=false) failed (%s); falling back " + ...
                    "to the persisting call, which WILL modify and re-save " + ...
                    "F16A_Physical.slx. Fix the option name in massRollup.", ME.message);
                r = F16APhysicalMassRollup();
            end
        end

        function sel = selectedChoices(testCase, vc)
            % The choices of a variant that the trade SELECTED, read from
            % TradeCandidate.Selected. Deliberately not getActiveChoice: this
            % is the decision, not the configuration, and the whole value of
            % the "selected" mass walk is that it can disagree with the
            % active one.
            choices = testCase.choicesOf(vc);
            keep = false(1, numel(choices));
            qualified = testCase.Profile + "." + testCase.CandidateStereotype + ".Selected";
            for i = 1:numel(choices)
                keep(i) = testCase.propBool(choices(i), qualified);
            end
            sel = choices(keep);
        end

        function d = tradeSelectionDefects(testCase)
            % Per role: exactly one Selected candidate, and it is the active
            % variant choice. Defects are split by kind so the failure says
            % which of the two halves of the decision went wrong.
            d.WrongCount = strings(1,0);
            d.Disagree   = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                rel  = string(testCase.VariantRows{i,1});
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                won  = rows.Path(rows.Selected);
                if numel(won) ~= 1
                    d.WrongCount(end+1) = role + " has " + numel(won) + " selected {" + ...
                        strjoin(testCase.leafNames(won), ", ") + "}";
                    continue
                end
                active = testCase.activeChoiceOf(testCase.componentAt(testCase.AC + rel));
                if numel(active) ~= 1
                    d.Disagree(end+1) = rel + " has " + numel(active) + ...
                        " active choices, so nothing can agree with it";
                    continue
                end
                if string(active.Name) ~= testCase.leafName(won)
                    d.Disagree(end+1) = role + ": Selected='" + testCase.leafName(won) + ...
                        "' but the active choice is '" + string(active.Name) + "'";
                end
            end
        end

        function d = winnerRationaleDefects(testCase)
            % One pass over all seven candidates. Every candidate owes a
            % SourceKind that matches its Selected flag; a winner additionally
            % owes a justification of real length that cites a score.
            d.NumWinners        = 0;
            d.WrongKind         = strings(1,0);
            d.ThinJustification = strings(1,0);
            d.NoScore           = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:height(T)
                expected = testCase.AlternativeSourceKind;
                if T.Selected(i); expected = testCase.WinnerSourceKind; end
                if T.SourceKind(i) ~= expected
                    d.WrongKind(end+1) = T.Path(i) + " '" + T.SourceKind(i) + ...
                        "' -> '" + expected + "'";
                end
                if ~T.Selected(i); continue; end
                d.NumWinners = d.NumWinners + 1;
                c = testCase.componentAt(testCase.AC + T.Path(i));
                just = testCase.rationaleText(c, "Justification");
                if strlength(just) < testCase.MinJustificationLength
                    d.ThinJustification(end+1) = T.Path(i) + " (" + ...
                        strlength(just) + " chars)";
                end
                if isempty(regexp(just, testCase.ScoreTokenPattern, "once"))
                    d.NoScore(end+1) = T.Path(i) + " -> '" + just + "'";
                end
            end
        end

        function names = selectedCandidateNames(testCase)
            % The leaf names of every selected candidate, sorted, so the
            % comparison against ExpectedWinners does not depend on the order
            % CandidateRows happens to list them in.
            T = testCase.candidateTable();
            names = sort(reshape(testCase.leafNames(T.Path(T.Selected)), 1, []));
        end

        function pth = selectedPathInRole(testCase, role)
            % The selected candidate's path within one role, as the table
            % holds it. Returns 0 or >1 elements when the decision is
            % missing or duplicated, which the caller reports rather than
            % papering over.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            pth = rows.Path(rows.Selected);
        end

        function paths = highestTRLPaths(testCase, role)
            % The candidate path(s) with the highest TRL in one role. Plural
            % on purpose: a tie is a real result and the caller's equality
            % check reports it as one.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.TRL == max(rows.TRL));
        end

        function paths = lowestMassPaths(testCase, role)
            % The candidate path(s) with the lowest traded Mass_lb in one
            % role -- the numerator of D-015's mass-ratio value function is
            % the role's baseline, so "lightest" and "best on mass" are the
            % same statement.
            T = testCase.candidateTable();
            rows = T(T.ExpectedRole == string(role), :);
            paths = rows.Path(rows.Mass_lb == min(rows.Mass_lb));
        end

        function d = decisionRequirementDefects(testCase)
            % D-010: REQ_F16A_L01..L03 each carry an incoming Implement link,
            % written by the physical trade study. Split by kind so "the
            % requirement is gone", "nothing links to it" and "something
            % links to it but not as an implementation" are distinguishable.
            d.Missing      = strings(1,0);
            d.Unlinked     = strings(1,0);
            d.NotImplement = strings(1,0);
            for id = testCase.DecisionRequirements
                r = testCase.findRequirement(testCase.LogiSet, id);
                if isempty(r)
                    d.Missing(end+1) = id;
                    continue
                end
                links = testCase.incomingLinks(r);
                if isempty(links)
                    d.Unlinked(end+1) = id;
                    continue
                end
                types = testCase.linkTypes(links);
                if ~ismember(testCase.ImplementLinkType, types)
                    d.NotImplement(end+1) = id + " -> {" + ...
                        strjoin(types, ", ") + "}";
                end
            end
        end

        function links = incomingLinks(~, req)
            % inLinks on a requirement, or empty. Wrapped so a requirement
            % with no link set at all is reported as unlinked rather than
            % erroring out of the test.
            try links = req.inLinks(); catch, links = []; end
        end

        % ---------------- Stage 5 audit: provenance is complete ----------

        function n = profileName(~, prof)
            % One profile's name, "" when it cannot be read -- which the
            % caller reports as "the P profile did not resolve" rather than
            % erroring out of the test.
            try n = string(prof.Name); catch, n = ""; end
            if ~isscalar(n) || ismissing(n); n = ""; end
        end

        function names = physicalProfileNames(testCase)
            % Names of every profile the P model resolves. Used to SCOPE the
            % declared-stereotype set by name: a second profile attached to
            % the model must not be able to widen the set of stereotypes
            % this file demands provenance from, nor to satisfy the demand
            % on another profile's behalf.
            profs = testCase.physicalProfiles();
            names = strings(1, numel(profs));
            for i = 1:numel(profs)
                names(i) = testCase.profileName(profs(i));
            end
        end

        function names = declaredStereotypeNames(testCase)
            % Every stereotype declared by the F16A_PhysicalProps profile,
            % and only that profile. This is the SOURCE of the required set,
            % which is why it is read from the profile rather than from a
            % list in this file: a list would have to be edited for a new
            % stereotype to be checked, and "somebody forgot to edit the
            % list" is the failure this whole test is about.
            names = strings(1,0);
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                if testCase.profileName(profs(i)) ~= testCase.Profile
                    continue
                end
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    names(end+1) = testCase.shortName(string(stereotypes(j).Name));   %#ok<AGROW>
                end
            end
            names = reshape(unique(names), 1, []);
        end

        function d = provenanceDeclarationDefects(testCase)
            % The fail-closed set arithmetic, in one place.
            %   Required       -- declared stereotypes MINUS the exemptions.
            %                     Computed, never listed.
            %   Undeclared     -- required but has no DataProvenance property.
            %   WrongType      -- has one, but not typed by the enumeration.
            %   StaleExemption -- exempts a stereotype that no longer exists,
            %                     which leaves a name primed to exempt
            %                     whatever is called that next.
            declared = testCase.declaredStereotypeNames();
            d.Required       = reshape(setdiff(declared, testCase.ProvenanceExemptStereotypes), 1, []);
            d.StaleExemption = reshape(setdiff(testCase.ProvenanceExemptStereotypes, declared), 1, []);
            d.Undeclared     = strings(1,0);
            d.WrongType      = strings(1,0);
            for i = 1:numel(d.Required)
                stereo = d.Required(i);
                actual = testCase.declaredPropertyType(stereo, testCase.ProvenanceProperty);
                if actual == ""
                    d.Undeclared(end+1) = stereo;
                elseif actual ~= testCase.DataProvenanceClass
                    d.WrongType(end+1) = stereo + " -> '" + actual + "'";
                end
            end
        end

        function d = provenanceTagDefects(testCase)
            % One pass over every stereotype-bearing part. For each
            % value-bearing stereotype a part applies, its DataProvenance
            % must read back inside the four-member vocabulary.
            %
            % Checked records every (part, stereotype) pair actually
            % examined, so the caller can prove the sweep saw something --
            % an empty Untagged list means nothing on its own.
            d.Checked  = strings(1,0);
            d.Untagged = strings(1,0);
            % The SAME computed set the declaration check uses, so the two
            % halves of D-031 can never drift apart: whatever a stereotype
            % is required to declare, its carriers are required to fill in.
            declared = testCase.provenanceDeclarationDefects();
            required = declared.Required;
            [parts, paths] = testCase.stereotypableParts();
            for i = 1:numel(parts)
                applied = testCase.appliedStereotypes(parts{i});
                hits = required(ismember(required, applied));
                for k = 1:numel(hits)
                    where = paths(i) + " [" + hits(k) + "]";
                    d.Checked(end+1) = where;
                    actual = testCase.propText(parts{i}, testCase.Profile + "." + ...
                        hits(k) + "." + testCase.ProvenanceProperty);
                    if ~ismember(actual, testCase.DataProvenanceMembers)
                        d.Untagged(end+1) = where + " -> '" + actual + "'";
                    end
                end
            end
        end

        function d = estimateCensusDefects(testCase)
            % D-030's inventory, checked against the model two ways: the
            % carriers are DISCOVERED by the walk (so a new one cannot hide)
            % and their number is compared with the inventory (so a new one
            % cannot arrive unrecorded). Every value under these stereotypes
            % is invented, so anything other than Estimate is a provenance
            % overclaim rather than a difference of opinion.
            d.CountMismatch = strings(1,0);
            d.NotEstimate   = strings(1,0);
            [parts, paths] = testCase.stereotypableParts();
            for r = 1:size(testCase.InventedEstimateCensus,1)
                stereo    = string(testCase.InventedEstimateCensus{r,1});
                valueProp = string(testCase.InventedEstimateCensus{r,2});
                expected  = testCase.InventedEstimateCensus{r,3};
                carriers  = 0;
                for i = 1:numel(parts)
                    if ~ismember(stereo, testCase.appliedStereotypes(parts{i}))
                        continue
                    end
                    carriers = carriers + 1;
                    actual = testCase.propText(parts{i}, testCase.Profile + "." + ...
                        stereo + "." + testCase.ProvenanceProperty);
                    if actual ~= testCase.EstimateProvenance
                        d.NotEstimate(end+1) = paths(i) + " [" + stereo + "." + ...
                            valueProp + "] -> '" + actual + "'";
                    end
                end
                if carriers ~= expected
                    d.CountMismatch(end+1) = stereo + "." + valueProp + " is carried by " + ...
                        carriers + " components, D-030 inventories " + expected;
                end
            end
        end

        function s = declaredDefaultText(~, prop)
            % Property.DefaultValue is the STORED MATLAB EXPRESSION -- "NaN",
            % "0", "'Minimize'", "F16ADataProvenance.Estimate" -- and is
            % documented as a string or, for a property carrying units, a
            % [value unit] pair, so the first element is the value. A string
            % literal arrives QUOTED (Stage-0 finding 7) and the quotes come
            % off here. "" when it cannot be read at all, which every caller
            % reports as a defect rather than swallowing.
            try
                raw = string(prop.DefaultValue);
            catch
                s = "";
                return
            end
            if isempty(raw); s = ""; return; end
            s = strtrim(erase(raw(1), "'"));
            if ismissing(s); s = ""; end
        end

        function v = declaredPropertyDefault(testCase, stereotypeShortName, propertyShortName)
            % The declared DEFAULT of one stereotype property, read from the
            % PROFILE. The sibling of declaredPropertyType, and the reason
            % both exist: a default is a claim the profile makes about every
            % element that will ever apply the stereotype, and no amount of
            % reading VALUES off today's components can see it.
            v = "";
            profs = testCase.physicalProfiles();
            for i = 1:numel(profs)
                stereotypes = profs(i).Stereotypes;
                for j = 1:numel(stereotypes)
                    if testCase.shortName(string(stereotypes(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = stereotypes(j).Properties;
                    for k = 1:numel(props)
                        if testCase.shortName(string(props(k).Name)) == propertyShortName
                            v = testCase.declaredDefaultText(props(k));
                            return
                        end
                    end
                end
            end
        end

        function hits = costPropertiesNotDefaultingToNaN(testCase)
            % Cost properties whose declared default is not NaN. Reported
            % with what was found, because the values mean different things:
            % '0' is D-021's hole still open, '' is the stereotype or the
            % property not being declared at all. Compared case-insensitively
            % -- MATLAB accepts nan, NaN and NAN as the same expression, and
            % this test is about the VALUE being a non-number, not about how
            % somebody spelled it.
            hits = strings(1,0);
            for r = 1:size(testCase.CostProperties,1)
                stereo = string(testCase.CostProperties{r,1});
                prop   = string(testCase.CostProperties{r,2});
                actual = testCase.declaredPropertyDefault(stereo, prop);
                if upper(actual) ~= upper(testCase.CostDefault)
                    hits(end+1) = stereo + "." + prop + " -> '" + actual + "'";   %#ok<AGROW>
                end
            end
        end

        % ---------------- Stage 5 audit: the guard rails -----------------

        function s = numList(~, values)
            % A numeric array as "0, 78, NaN" for a failure message.
            %
            % NOT string(values). string(NaN) is <missing> (Stage-0 gotcha,
            % the same one that makes setProperty reject it), and strjoin
            % ERRORS on a string array containing a missing element -- so
            % the obvious spelling would blow up the diagnostic in exactly
            % the case that produces it, since NaN is one of the values
            % these controls exist to reject. compose formats it as text
            % instead. reshape because compose follows the input's shape
            % and strjoin wants a row.
            s = strjoin(reshape(compose("%g", values), 1, []), ", ");
        end

        function tf = onBenefitScale(testCase, b)
            % Is a Benefit on its declared scale? THE predicate -- used by
            % the candidate sweep and by the negative control that proves it
            % can reject, so the control cannot drift away from the rule it
            % is controlling. isfinite first, and short-circuited, so NaN
            % (an unreadable property) and Inf are rejected here rather than
            % propagating through the comparison.
            tf = isfinite(b) && b >= testCase.BenefitScale(1) && b <= testCase.BenefitScale(2);
        end

        function tf = onTRLScale(testCase, t)
            % Is a TRL on its declared scale? Range AND integrality, because
            % the trade study's guard checks both: TRL is an ordinal
            % maturity level, so 4.5 is not a low reading, it is not a
            % reading at all.
            tf = isfinite(t) && t >= testCase.TRLScale(1) && t <= testCase.TRLScale(2) && ...
                mod(t, 1) == 0;
        end

        function d = baselineDefects(testCase)
            % Per role: find the ratio baseline the way the TRADE STUDY
            % finds it -- by the DataProvenance tag, not by the production
            % names hard-coded in this file -- require it to be unique, and
            % evaluate D-015's mass value function for every candidate of
            % the role against it.
            %
            % Checked records every candidate actually scored, so the caller
            % can prove the sweep saw something: an empty AboveCeiling list
            % means nothing on its own.
            d.NoUniqueBaseline = strings(1,0);
            d.AboveCeiling     = strings(1,0);
            d.Checked          = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                ref  = rows(rows.DataProvenance == testCase.BaselineProvenance, :);
                if height(ref) ~= 1
                    % reshape because strjoin wants a ROW; candidateTable
                    % holds Path as a column, so the slice arrives as one.
                    d.NoUniqueBaseline(end+1) = role + " has " + height(ref) + ...
                        " candidates tagged " + testCase.BaselineProvenance + " {" + ...
                        strjoin(reshape(testCase.leafNames(ref.Path), 1, []), ", ") + "}";
                    continue
                end
                baseline = ref.Mass_lb;
                for k = 1:height(rows)
                    d.Checked(end+1) = rows.Path(k);
                    % The value function verbatim from D-015. A zero or
                    % negative mass gives Inf or a negative here and lands
                    % in AboveCeiling; that is the trade study's badMass
                    % guard, and the Mass_lb > 0 sweep in
                    % testCandidatesCarryTradeParameters reports it first.
                    v = baseline / rows.Mass_lb(k);
                    if v > 1 + testCase.ValueCeilingTol
                        d.AboveCeiling(end+1) = rows.Path(k) + " -> v = " + ...
                            sprintf("%.4f", v) + " (baseline " + ...
                            testCase.leafName(ref.Path) + " = " + baseline + " lb, this " + ...
                            "candidate = " + rows.Mass_lb(k) + " lb)";
                    end
                end
            end
        end

        function dupes = duplicateParameterDefects(testCase)
            % Pairs of candidates within one role whose scored parameters
            % are indistinguishable. Compared with a tolerance rather than
            % by exact equality: two masses that differ in the last bit
            % would separate the candidates arithmetically while being the
            % same number in every sense the trade study cares about, and a
            % margin that small is not a decision either.
            dupes = strings(1,0);
            T = testCase.candidateTable();
            for i = 1:size(testCase.VariantRows,1)
                role = string(testCase.VariantRows{i,2});
                rows = T(T.ExpectedRole == role, :);
                for a = 1:height(rows)
                    for b = a+1:height(rows)
                        same = abs(rows.Benefit(a) - rows.Benefit(b)) <= 1e-9 && ...
                               abs(rows.TRL(a)     - rows.TRL(b))     <= 1e-9 && ...
                               abs(rows.Mass_lb(a) - rows.Mass_lb(b)) <= 1e-9;
                        if same
                            dupes(end+1) = role + ": " + ...
                                testCase.leafName(rows.Path(a)) + " and " + ...
                                testCase.leafName(rows.Path(b)) + " both carry Benefit=" + ...
                                rows.Benefit(a) + ", TRL=" + rows.TRL(a) + ", Mass_lb=" + ...
                                rows.Mass_lb(a);   %#ok<AGROW>
                        end
                    end
                end
            end
        end

        function types = linkTypes(~, links)
            % The Type of each link ('Implement', 'Verify', 'Derive', ...).
            % An unreadable type is surfaced as a token rather than dropped,
            % so an API change shows up in the failure message instead of
            % quietly emptying the list.
            types = strings(1,0);
            for i = 1:numel(links)
                try
                    types(end+1) = string(links(i).Type);       %#ok<AGROW>
                catch
                    types(end+1) = "<unreadable>";              %#ok<AGROW>
                end
            end
        end
    end
end
