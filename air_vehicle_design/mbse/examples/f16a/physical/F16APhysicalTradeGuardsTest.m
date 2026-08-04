classdef F16APhysicalTradeGuardsTest < matlab.unittest.TestCase
    %F16APHYSICALTRADEGUARDSTEST Make the trade study's guard rails actually FIRE.
    %   The negative tests F16APhysicalArchitectureTest could not write. Every
    %   assertion feeds F16APhysicalTradeGuards a value that must be refused and
    %   checks that it IS refused, BY IDENTIFIER.
    %
    %   NOTHING HERE OPENS, READS OR WRITES AN ARTIFACT -- no model, no
    %   requirement set, no file. The candidate "paths" below are plain strings
    %   the guards use only to name an offender. That is the whole point: this
    %   suite runs green on a checkout with no models in it, and folding it into
    %   the architecture suite would attach it to a TestClassSetup that loads two
    %   models and three requirement sets, so these tests would start failing for
    %   reasons unrelated to whether a bound still rejects 78.
    %
    %   It is also why the guards were extracted at all. While they were local
    %   functions of F16APhysicalTradeStudy.m, the equivalent negative test had
    %   to run the whole study -- and it stopped early only while the guard still
    %   worked. On the day the guard was refactored away, the day the test exists
    %   to catch, Benefit = 78 would sail through to save_system and put a wrong
    %   winner into the shipped artifacts. A negative test whose failure mode is
    %   corrupting the repository is worse than no test.
    %
    %   IDENTIFIERS, NEVER MESSAGE TEXT, and they keep the
    %   F16APhysicalTradeStudy: prefix even though the code moved -- an
    %   identifier names the CONTRACT, not the file.
    %
    %   BOUNDS COME FROM THE CODE THAT ENFORCES THEM (TRLScale, BenefitScale,
    %   CeilingTol, TieTol), so widening a scale cannot leave a test agreeing
    %   with a bound that no longer exists. The REJECTED values are deliberately
    %   literal, because each is a specific real mistake: 0 is "nobody set this",
    %   78 is 7.8 with a slipped decimal point, 4.5 is not a point on an ordinal
    %   scale. Widening a scale to admit one must turn this suite red.
    %
    %   Boundary-INCLUSIVE is not a detail: three real value functions sit
    %   exactly on 1.0 today (Benefit 10, TRL 9, and the Reference candidate's
    %   own M/M), so an exclusive bound would fail the shipped model.
    %
    %   NOT TESTED HERE: rankRefusingTies on a SINGLE candidate throws
    %   MATLAB:badsubscript, and pinning that would cement an accident as a
    %   contract. The study's discovery-walk guards need the model, and their
    %   input contract is pinned in F16APhysicalArchitectureTest instead.
    %
    %   See also F16APHYSICALTRADEGUARDS, F16APHYSICALTRADESTUDY,
    %   F16APHYSICALARCHITECTURETEST.

    properties (Constant)
        % The two candidates every fixture below is written about. STRINGS,
        % not handles and not paths anything resolves: the guards use them
        % solely to name an offender in a message. Real names, so a failure
        % message reads like the run it is standing in for.
        CandPaths = [ ...
            "F16A_Physical/Aircraft/Propulsion/Engine/F100_PW_200", ...
            "F16A_Physical/Aircraft/Propulsion/Engine/TwinEngine_Surrogate"];
        CandNames = ["F100_PW_200", "TwinEngine_Surrogate"];
        Role      = "PropulsionSystem";

        % A parameter set every guard accepts, used as the BACKGROUND that
        % each test mutates one cell of. Deliberately mid-scale rather than at
        % an endpoint, so a test that means to exercise the Benefit bound
        % cannot accidentally be passing because TRL was also on its limit.
        % The mass is the F100-PW-200's Brandt figure -- a real number, so the
        % ratios in the ceiling tests below are the ones the study computes.
        GoodBenefit =    7.8;
        GoodTRL     =    6;
        GoodMass_lb = 4730.23;

        % The criteria actually scored in a real run: UnitCost_USD is dropped
        % because no candidate carries a cost (D-005), and the remaining
        % weights renormalize to these (D-015).
        KeptCriteria = ["Benefit", "TRL", "Mass_lb"];
        KeptWeights  = [0.50, 0.25, 0.25];

        % The identifiers under test. Named once so a typo is a compile-time
        % thing rather than a test that passes by expecting the wrong ID.
        BadBenefitId      = "F16APhysicalTradeStudy:badBenefit";
        BadTRLId          = "F16APhysicalTradeStudy:badTRL";
        BadMassId         = "F16APhysicalTradeStudy:badMass";
        NoSuchCriterionId = "F16APhysicalTradeStudy:noSuchCriterion";
        TieId             = "F16APhysicalTradeStudy:tie";
        CeilingId         = "F16APhysicalTradeStudy:valueAboveCeiling";
    end

    properties (TestParameter)
        % The Benefit values D-033 exists to refuse. Literal on purpose (see
        % the class help): each is a mistake somebody makes, not a restatement
        % of the scale, so widening the scale must break this list.
        %   unsetSentinel   0     the stereotype default -- "nobody set this"
        %   slippedDecimal  78    7.8 with the decimal point dropped: D-033's
        %                         entire case, and finite, so invisible to
        %                         every isfinite check in the trade study
        %   justPastTheTop  10.5  one step past the declared ceiling
        %   negativeMerit   -1    negative merit is not a point on a 1..10 scale
        %   unreadable      NaN   an unreadable property must stop the trade
        %   infinite        Inf   what the isfinite net is there for
        rejectedBenefit = struct( ...
            'unsetSentinel',  0, ...
            'slippedDecimal', 78, ...
            'justPastTheTop', 10.5, ...
            'negativeMerit',  -1, ...
            'unreadable',     NaN, ...
            'infinite',       Inf);

        % The TRL values D-021 exists to refuse.
        %   unsetSentinel   0    int32 cannot hold NaN, so 0 is the fail-safe
        %                        default and is outside the scale ON PURPOSE
        %   justPastTheTop  10   one past the top of the 1..9 scale
        %   fractional      4.5  TRL is an ordinal maturity LEVEL
        rejectedTRL = struct( ...
            'unsetSentinel',  0, ...
            'justPastTheTop', 10, ...
            'fractional',     4.5, ...
            'negative',       -1, ...
            'unreadable',     NaN, ...
            'infinite',       Inf);

        % Mass_lb is the denominator of M_baseline/M, so the rule is strictly
        % positive and finite -- there is no upper bound to overshoot.
        %   zero      a divide-by-zero dressed as a parameter
        %   negative  an inverted score that still looks plausible
        rejectedMass = struct( ...
            'zero',       0, ...
            'negative',   -1, ...
            'unreadable', NaN, ...
            'infinite',   Inf);
    end

    methods (TestClassSetup)
        function makeGuardsReachable(testCase)
            % The ONLY setup. Puts this file's own folder on the path so the
            % suite runs standalone -- no project, no models, no requirement
            % sets. PathFixture restores the path on teardown, so even this
            % leaves nothing behind.
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(fileparts(mfilename("fullpath"))));
        end
    end

    methods (Test)

        % ---------------- checkParameters: the bounds refuse --------------

        function testRejectedBenefitStopsTheTrade(testCase, rejectedBenefit)
            % D-033. Every other parameter in the row is valid, so the only
            % thing that can stop the run is the Benefit -- which means a
            % PASS here cannot be coming from some other guard firing first.
            raw = testCase.rawWith("Benefit", rejectedBenefit);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadBenefitId, ...
                "Benefit = " + testCase.fmt(rejectedBenefit) + " must stop the trade " + ...
                "(D-033). The upper bound is the one that earns its keep: v = B/10 carries the " + ...
                "heaviest weight, so an out-of-range but FINITE Benefit is invisible " + ...
                "to every other check and reaches save_system as a wrong winner, a " + ...
                "wrong L active kind and a wrong Implement link on REQ_F16A_L01.");
        end

        function testRejectedTRLStopsTheTrade(testCase, rejectedTRL)
            % D-021. Note that checkParameters tests TRL FIRST, so this is
            % also the one bound that cannot be masked by another.
            raw = testCase.rawWith("TRL", rejectedTRL);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadTRLId, ...
                "TRL = " + testCase.fmt(rejectedTRL) + " must stop the trade (D-021). 0 is the " + ...
                "int32 property's fail-safe default and is outside the scale on " + ...
                "purpose, so that an unset TRL cannot be scored as plausible " + ...
                "mid-maturity; a fractional TRL is not a point on an ordinal scale.");
        end

        function testRejectedMassStopsTheTrade(testCase, rejectedMass)
            raw = testCase.rawWith("Mass_lb", rejectedMass);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadMassId, ...
                "Mass_lb = " + testCase.fmt(rejectedMass) + " must stop the trade. Mass is the " + ...
                "DENOMINATOR of M_baseline/M: 0 is a divide-by-zero and a negative " + ...
                "mass inverts the score while still looking like data.");
        end

        function testBenefitScaleEndpointsAreAccepted(testCase)
            % The other direction, and it is not decoration: a bound that
            % rejects everything would pass every test above and fail the
            % aeroplane. Boundary-INCLUSIVE, and the endpoints are read from
            % BenefitScale rather than typed, so this cannot drift from the
            % rule it is checking. Benefit = 10 is a live case -- it is what
            % makes v = B/10 land on exactly 1.0.
            ben = F16APhysicalTradeGuards.BenefitScale;
            raw = [testCase.rawWith("Benefit", ben(1)); ...
                   testCase.rawWith("Benefit", ben(2))];
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths, raw, testCase.criteria()), ...
                "The declared Benefit scale " + ben(1) + ".." + ben(2) + " is " + ...
                "INCLUSIVE at both ends, so a candidate sitting exactly on an " + ...
                "endpoint is perfectly well specified and must not be refused.");
        end

        function testTRLScaleEndpointsAreAccepted(testCase)
            % As above, from TRLScale. TRL = 9 is live: HydroMechanical
            % carries it, and (9-1)/8 is exactly 1.0.
            trl = F16APhysicalTradeGuards.TRLScale;
            raw = [testCase.rawWith("TRL", trl(1)); ...
                   testCase.rawWith("TRL", trl(2))];
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths, raw, testCase.criteria()), ...
                "The declared TRL scale " + trl(1) + ".." + trl(2) + " is INCLUSIVE " + ...
                "at both ends; HydroMechanical's TRL of 9 is a shipped value.");
        end

        function testMissingGuardedCriterionStopsTheTrade(testCase)
            % A criteria declaration that has lost Mass_lb must stop the run,
            % not silently skip the mass check. This is the difference
            % between critIdx erroring and returning empty: with an empty
            % index the loop would compare against nothing and every mass
            % would pass, which is the quietest possible way to lose a guard.
            %
            % The VALUES are deliberately all NaN, because they are
            % irrelevant: checkParameters locates all three guarded
            % parameters through critIdx BEFORE it reads a single one of
            % them. That ordering is part of the contract, and this is what
            % pins it -- a version that read values first would report
            % :badTRL on the NaN it found and never mention that a criterion
            % was missing at all.
            crit = testCase.criteriaWithoutMass();
            raw  = nan(1, numel(crit));
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, crit), ...
                testCase.NoSuchCriterionId, ...
                "A criteria declaration missing one of the three guarded parameters " + ...
                "must stop the trade. Skipping the check for a criterion nobody " + ...
                "declared would drop the guard without anything saying so.");
        end

        function testCritIdxLocatesByNameAndRefusesToGuess(testCase)
            % Both halves of critIdx: it finds what is there, and it errors
            % rather than handing back an empty index for what is not.
            crit = testCase.criteria();
            testCase.verifyEqual(F16APhysicalTradeGuards.critIdx(crit, "Mass_lb"), 3, ...
                "critIdx must return the position of the named criterion.");
            testCase.verifyError( ...
                @() F16APhysicalTradeGuards.critIdx(crit, "NoSuchCriterionName"), ...
                testCase.NoSuchCriterionId, ...
                "critIdx must error on an undeclared criterion. Returning empty " + ...
                "would make every check that uses it pass vacuously.");
        end

        function testParametersAreLocatedByNameNotByColumnPosition(testCase)
            % raw's columns must line up with crit's elements, and NOTHING
            % validates that coupling -- so the least the guard can do is
            % honour whatever order the declaration is in. Here the criteria
            % are reversed and the row is built by name to match, then
            % Benefit (now the LAST column) is set to 78.
            %
            % A guard that read columns positionally would find 4730.23 where
            % it expected TRL and report :badTRL, so the identifier alone
            % separates the two implementations.
            crit = testCase.criteriaReversed();
            raw  = testCase.rawForWith(crit, "Benefit", 78);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, crit), ...
                testCase.BadBenefitId, ...
                "Benefit, TRL and Mass_lb must be located BY NAME. With the criteria " + ...
                "declared in a different order a positional read would blame TRL for " + ...
                "a Benefit that is out of range -- or miss it entirely.");
        end

        % ---------------- rankRefusingTies: ranks, and refuses ------------

        function testTieForFirstPlaceStopsTheTrade(testCase)
            % The dead heat. Two candidates with the same score is a decision
            % the data cannot make, and sort order is not a decision.
            testCase.verifyError(@() F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5], testCase.Role), ...
                testCase.TieId, ...
                "A dead heat for first place must stop the trade. Separating the two " + ...
                "by the order they happen to appear in would record a winner the " + ...
                "numbers never chose.");
        end

        function testTieWithinToleranceStopsTheTrade(testCase)
            % TieTol is a TOLERANCE, not exact equality. Scores are printed
            % to five decimals, so a margin nobody can see in the table is
            % not a margin anybody should decide on. Read from TieTol so a
            % change to the tolerance cannot leave this test behind.
            tol = F16APhysicalTradeGuards.TieTol;
            testCase.verifyError(@() F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5 + tol/2], testCase.Role), ...
                testCase.TieId, ...
                "Two scores within TieTol are a dead heat, not a margin. Exact " + ...
                "equality would let a difference in the last bit decide the trade.");
        end

        function testMarginJustOutsideToleranceIsADecision(testCase)
            % And the other side of it, so the tie guard cannot be satisfied
            % by refusing every close race.
            tol   = F16APhysicalTradeGuards.TieTol;
            order = F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5 + 10*tol], testCase.Role);
            testCase.verifyEqual(order(1), 2, ...
                "A margin larger than TieTol is a real result and the higher score " + ...
                "must win. A tie guard that refused every close race would stop " + ...
                "legitimate trades.");
        end

        function testRankIsBestFirst(testCase)
            % rankRefusingTies is not a pure predicate -- it ranks as well as
            % judges, and the caller uses the ordering it returns. Pin it:
            % ORDER(1) is the winner and ORDER(2) the runner-up that D-034's
            % "decided by" is measured against, so an ordering silently
            % reversed would rewrite every stored justification.
            order = F16APhysicalTradeGuards.rankRefusingTies( ...
                ["Low","High","Mid"], [0.10, 0.90, 0.50], testCase.Role);
            testCase.verifyEqual(order, [2 3 1], ...
                "rankRefusingTies must return indices in DESCENDING score order.");
        end

        function testTieForSecondPlaceIsNotRefused(testCase)
            % Only FIRST place is a decision the data has to make. Two
            % candidates tied for second have not stopped anybody from
            % knowing who won, and refusing that would reject a perfectly
            % decidable trade.
            order = F16APhysicalTradeGuards.rankRefusingTies( ...
                ["Winner","AlsoRan","AlsoRanToo"], [0.90, 0.50, 0.50], testCase.Role);
            testCase.verifyEqual(order(1), 1, ...
                "A tie for SECOND place is not a tie for first: the winner is " + ...
                "unambiguous and the trade must proceed.");
        end

        % ---------------- warnAboveCeiling: warns, and only warns ---------

        function testValueAboveCeilingWarns(testCase)
            % D-035, armed. The mass ratio has no ceiling, so a candidate
            % lighter than its role's baseline scores above 1 and contributes
            % more than its renormalized weight allows -- at which point
            % 0.50/0.25/0.25 has stopped describing relative influence and
            % the run has to say so out loud.
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), testCase.ceilingV(1.351), testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "A value function above 1.0 must be reported. Silence would leave " + ...
                "the reader believing the declared weights still describe relative " + ...
                "influence when they no longer do (D-035).");
        end

        function testValueAboveCeilingCapsNothing(testCase)
            % THE assertion D-035 turns on. Capping would discard a real
            % advantage -- the candidate genuinely IS lighter than baseline --
            % and erroring would reject a legitimate candidate, so the
            % decision was to warn and change nothing.
            %
            % The load-bearing half is the output list: a guard that capped
            % would have to hand the capped values back, so a method with NO
            % declared outputs cannot cap however it is rewritten inside. The
            % value comparison is the belt to that braces -- it would catch a
            % move to a handle object or any in-place design.
            V      = testCase.ceilingV(1.351);
            before = V;
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), V, testCase.KeptWeights, testCase.criteria(), ...
                testCase.keptIndices(), testCase.Role), testCase.CeilingId);
            testCase.verifyEmpty(testCase.outputNamesOf("warnAboveCeiling"), ...
                "warnAboveCeiling must declare NO outputs. The moment it returns a " + ...
                "value matrix it can cap one, and D-035 decided not to cap: a capped " + ...
                "1.351 would throw away the fact that this candidate really is " + ...
                "lighter than its role's baseline.");
            testCase.verifyEqual(V, before, ...
                "warnAboveCeiling must leave the value matrix exactly as it was. " + ...
                "Nothing about the score changes because this fired.");
        end

        function testValueExactlyOnTheCeilingDoesNotWarn(testCase)
            % Sitting ON the ceiling is not an exceedance, and this is not a
            % hypothetical: Benefit = 10 gives B/10 = 1, TRL = 9 gives
            % (9-1)/8 = 1, and the Reference candidate's own M_baseline/M is
            % 1. All three are IEEE-exact and all three are shipped values,
            % so a strict "> = warn" would cry wolf on every run.
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1, 1, 1], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                "A value of exactly 1.0 is on the ceiling, not above it. Benefit 10, " + ...
                "TRL 9 and the baseline's own mass ratio all land here today.");
        end

        function testValueInsideTheCeilingToleranceDoesNotWarn(testCase)
            % CeilingTol read from the code, so it is the tolerance that is
            % being checked and not a copy of it. It guards nothing today --
            % the three values above are exact -- and exists so a future
            % value function that reaches its ceiling through an inexact
            % division does not report itself as broken.
            tol = F16APhysicalTradeGuards.CeilingTol;
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1 + tol, 1 - tol, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                "A value within CeilingTol of 1.0 is on the ceiling. Reporting " + ...
                "rounding dust as a known-limit exceedance would train the reader " + ...
                "to ignore the warning that matters.");
        end

        function testValueOutsideTheCeilingToleranceWarns(testCase)
            % The other side, so CeilingTol cannot be widened into silence.
            tol = F16APhysicalTradeGuards.CeilingTol;
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1 + 10*tol, 0.9, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "A value more than CeilingTol above 1.0 IS an exceedance. A tolerance " + ...
                "that swallowed it would turn the D-035 report off without a decision.");
        end

        function testTheCeilingCheckIsGenericOverCriteria(testCase)
            % D-035 wrote the check over the criteria GENERICALLY rather than
            % against Mass_lb by name, because UnitCost_USD inherits the
            % identical C_baseline/C shape the day a cost model lands. This
            % puts the exceedance on the TRL column instead.
            %
            % Not a reachable state today -- checkParameters boxes TRL, so
            % (TRL-1)/8 cannot exceed 1 -- which is exactly why it is worth
            % asserting: it proves the check keys on the VALUE and not on
            % which criterion happens to be unbounded right now.
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [0.78, 1.20, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "The ceiling check must fire on ANY criterion whose value exceeds " + ...
                "1.0, not only on Mass_lb. UnitCost_USD gets the same unbounded " + ...
                "ratio shape the day F16APhysicalCostModel returns a number.");
        end

    end

    methods (Access = private)

        function s = fmt(~, value)
            % A number as text for a failure message.
            %
            % NOT "..." + value. string(NaN) is <missing> and the same
            % conversion lurks behind string concatenation, so the obvious
            % spelling risks producing a missing diagnostic in exactly the
            % cases these parameters exist to cover -- NaN and Inf are two of
            % the six. sprintf formats them as text.
            s = string(sprintf("%g", value));
        end

        function crit = criteria(~)
            % The criteria declaration, in F16APhysicalTradeStudy's own order.
            %
            % Only the two fields the guards READ are here: Name, which
            % checkParameters and critIdx locate the guarded parameters by,
            % and Rule, which warnAboveCeiling quotes in its message. Weight
            % and Value are deliberately absent -- carrying them would imply
            % the guards consult them, and they do not.
            crit = struct( ...
                "Name", {"Benefit", "TRL",         "Mass_lb",      "UnitCost_USD"}, ...
                "Rule", {"B/10",    "(TRL-1)/8",   "M_baseline/M", "C_baseline/C"});
        end

        function crit = criteriaReversed(testCase)
            % The same declaration in the opposite order, for the test that
            % proves the guards locate parameters by name.
            crit = fliplr(testCase.criteria());
        end

        function crit = criteriaWithoutMass(~)
            % A declaration that has lost one of the three guarded
            % parameters, for the :noSuchCriterion test.
            crit = struct( ...
                "Name", {"Benefit", "TRL",       "UnitCost_USD"}, ...
                "Rule", {"B/10",    "(TRL-1)/8", "C_baseline/C"});
        end

        function raw = validRowFor(testCase, crit)
            % One candidate's parameters, all of them acceptable.
            %
            % Placed BY NAME through critIdx rather than by writing a literal
            % row, so the fixture obeys the same raw-columns-follow-crit-order
            % contract the trade study does -- and so criteriaReversed needs
            % no second copy of it. UnitCost_USD is left NaN: that is D-005's
            % honest "no cost model", and checkParameters never reads it.
            %
            % CRIT must declare all three guarded parameters; critIdx errors
            % otherwise, which is correct for a fixture but is why the
            % :noSuchCriterion test builds its own row instead of calling
            % this -- it needs the error to come out of the UNIT under test,
            % not out of the fixture that set it up.
            raw = nan(1, numel(crit));
            raw(F16APhysicalTradeGuards.critIdx(crit, "Benefit")) = testCase.GoodBenefit;
            raw(F16APhysicalTradeGuards.critIdx(crit, "TRL"))     = testCase.GoodTRL;
            raw(F16APhysicalTradeGuards.critIdx(crit, "Mass_lb")) = testCase.GoodMass_lb;
        end

        function raw = rawForWith(testCase, crit, name, value)
            % A valid row with exactly ONE parameter replaced. Everything
            % else stays acceptable, so whichever guard fires can only be the
            % one under test.
            raw = testCase.validRowFor(crit);
            raw(F16APhysicalTradeGuards.critIdx(crit, name)) = value;
        end

        function raw = rawWith(testCase, name, value)
            % rawForWith against the standard criteria order.
            raw = testCase.rawForWith(testCase.criteria(), name, value);
        end

        function keptIdx = keptIndices(testCase)
            % Indices into the full declaration of the criteria a real run
            % actually scores -- looked up by name, for the same reason
            % validRowFor places by name.
            keptIdx = arrayfun( ...
                @(n) F16APhysicalTradeGuards.critIdx(testCase.criteria(), n), ...
                testCase.KeptCriteria);
        end

        function V = ceilingV(testCase, massValue)
            % One candidate's value row in KeptCriteria order, with the mass
            % ratio set to MASSVALUE. The Benefit and TRL entries are what
            % GoodBenefit and GoodTRL produce through their declared value
            % functions, so the row is one the study could really compute.
            V = [testCase.GoodBenefit/10, (testCase.GoodTRL - 1)/8, massValue];
        end

        function names = outputNamesOf(~, methodName)
            % The declared OUTPUT list of one of the guards' static methods,
            % read from class metadata.
            %
            % A method that returns nothing cannot hand back a capped value
            % matrix, which is what makes this the durable form of "does not
            % cap": it survives any rewrite of the method body. A missing
            % method yields a non-empty placeholder rather than an error, so
            % a renamed guard fails with a readable value instead of a
            % metadata exception.
            mc  = meta.class.fromName("F16APhysicalTradeGuards");
            hit = mc.MethodList(string({mc.MethodList.Name}) == methodName);
            names = {char("<no such method: " + methodName + ">")};
            if isscalar(hit)
                names = hit.OutputNames;
            end
        end

    end
end
