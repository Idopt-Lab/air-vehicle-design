classdef F16APhysicalTradeGuardsTest < matlab.unittest.TestCase
    %F16APHYSICALTRADEGUARDSTEST Make the trade study's guard rails actually FIRE.
    %   The negative tests F16APhysicalArchitectureTest could not write. Every
    %   assertion feeds F16APhysicalTradeGuards a value that must be refused and
    %   checks that it IS refused, BY IDENTIFIER -- never by message text. The
    %   identifiers keep the F16APhysicalTradeStudy: prefix because an identifier
    %   names the contract, not the file the code sits in.
    %
    %   NOTHING HERE OPENS, READS OR WRITES AN ARTIFACT, which is why it can
    %   safely feed the guards bad data: while they were local functions of the
    %   study, a negative test had to run the whole study, and on the day a guard
    %   was refactored away Benefit = 78 would sail through to save_system and
    %   put a wrong winner into the repository.
    %
    %   BOUNDS COME FROM THE CODE THAT ENFORCES THEM (TRLScale, BenefitScale,
    %   CeilingTol, TieTol). The REJECTED values are deliberately literal --
    %   each is a specific real mistake. Bounds are INCLUSIVE.
    %
    %   Deliberately NOT a F16ATestCase: that base class exists to read models,
    %   and this suite must keep running on a checkout with none.

    properties (Constant)
        % The two candidates every fixture is written about. STRINGS, not
        % handles: the guards use them solely to name an offender, so a failure
        % message reads like the run it stands in for.
        CandPaths = [ ...
            "F16A_Physical/Aircraft/Propulsion/Engine/F100_PW_200", ...
            "F16A_Physical/Aircraft/Propulsion/Engine/TwinEngine_Surrogate"];
        CandNames = ["F100_PW_200", "TwinEngine_Surrogate"];
        Role      = "PropulsionSystem";

        % A parameter set every guard accepts, used as the BACKGROUND each test
        % mutates one cell of. Mid-scale rather than at an endpoint, so a test
        % meaning to exercise the Benefit bound cannot pass because TRL was also
        % on its limit. The mass is the F100-PW-200's Brandt figure, so the
        % ratios in the ceiling tests are the ones the study computes.
        GoodBenefit =    7.8;
        GoodTRL     =    6;
        GoodMass_lb = 4730.23;

        % The criteria a real run scores: UnitCost_USD is dropped because no
        % candidate carries a cost (D-005), and the weights renormalize (D-015).
        KeptCriteria = ["Benefit", "TRL", "Mass_lb"];
        KeptWeights  = [0.50, 0.25, 0.25];

        % The identifiers under test, named once so a typo cannot become a test
        % that passes by expecting the wrong id.
        BadBenefitId      = "F16APhysicalTradeStudy:badBenefit";
        BadTRLId          = "F16APhysicalTradeStudy:badTRL";
        BadMassId         = "F16APhysicalTradeStudy:badMass";
        NoSuchCriterionId = "F16APhysicalTradeStudy:noSuchCriterion";
        TieId             = "F16APhysicalTradeStudy:tie";
        CeilingId         = "F16APhysicalTradeStudy:valueAboveCeiling";
    end

    properties (TestParameter)
        % The Benefit values D-033 exists to refuse. Literal on purpose: each is
        % a mistake somebody makes, not a restatement of the scale, so widening
        % the scale must break this list.
        %   unsetSentinel   0     the stereotype default -- "nobody set this"
        %   slippedDecimal  78    7.8 with the point dropped: finite, and so
        %                         invisible to every isfinite check
        %   justPastTheTop  10.5  one step past the declared ceiling
        %   negativeMerit   -1    not a point on a 1..10 scale
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
        %   fractional      4.5  TRL is an ordinal maturity LEVEL
        rejectedTRL = struct( ...
            'unsetSentinel',  0, ...
            'justPastTheTop', 10, ...
            'fractional',     4.5, ...
            'negative',       -1, ...
            'unreadable',     NaN, ...
            'infinite',       Inf);

        % Mass_lb is the DENOMINATOR of M_baseline/M, so the rule is strictly
        % positive and finite -- there is no upper bound to overshoot.
        rejectedMass = struct( ...
            'zero',       0, ...
            'negative',   -1, ...
            'unreadable', NaN, ...
            'infinite',   Inf);
    end

    methods (TestClassSetup)
        function makeGuardsReachable(testCase)
            % The ONLY setup: put physical/ on the path so the guards resolve.
            % No project, no models, no requirement sets. PathFixture leaves the
            % path as it found it (D-047).
            import matlab.unittest.fixtures.PathFixture
            testCase.applyFixture(PathFixture(fullfile(f16aRoot(), "physical")));
        end
    end

    methods (Test)

        % ---------------- checkParameters: the bounds refuse --------------

        function testRejectedBenefitStopsTheTrade(testCase, rejectedBenefit)
            % Every other parameter in the row is valid, so a pass here cannot
            % be coming from some other guard firing first.
            raw = testCase.rawWith("Benefit", rejectedBenefit);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadBenefitId, ...
                "Benefit = " + testCase.fmt(rejectedBenefit) + " must stop the trade " + ...
                "(D-033): v = B/10 carries the heaviest weight, so an out-of-range " + ...
                "but FINITE Benefit reaches save_system as a wrong winner.");
        end

        function testRejectedTRLStopsTheTrade(testCase, rejectedTRL)
            % checkParameters tests TRL FIRST, so this is also the one bound
            % that cannot be masked by another.
            raw = testCase.rawWith("TRL", rejectedTRL);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadTRLId, ...
                "TRL = " + testCase.fmt(rejectedTRL) + " must stop the trade (D-021): " + ...
                "an unset TRL must not score as plausible mid-maturity, and a " + ...
                "fractional TRL is not a point on an ordinal scale.");
        end

        function testRejectedMassStopsTheTrade(testCase, rejectedMass)
            raw = testCase.rawWith("Mass_lb", rejectedMass);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, testCase.criteria()), ...
                testCase.BadMassId, ...
                "Mass_lb = " + testCase.fmt(rejectedMass) + " must stop the trade: 0 is " + ...
                "a divide-by-zero and a negative mass inverts the score while still " + ...
                "looking like data.");
        end

        function testBenefitScaleEndpointsAreAccepted(testCase)
            % The other direction, and not decoration: a bound that rejected
            % everything would pass every test above and fail the aeroplane.
            % Endpoints read from BenefitScale, so this cannot drift from the
            % rule it checks. Benefit = 10 is live -- it makes v = B/10 exactly 1.
            ben = F16APhysicalTradeGuards.BenefitScale;
            raw = [testCase.rawWith("Benefit", ben(1)); ...
                   testCase.rawWith("Benefit", ben(2))];
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths, raw, testCase.criteria()), ...
                "The declared Benefit scale " + ben(1) + ".." + ben(2) + " is INCLUSIVE " + ...
                "at both ends; a candidate sitting on an endpoint is well specified.");
        end

        function testTRLScaleEndpointsAreAccepted(testCase)
            % As above, from TRLScale. TRL = 9 is live: HydroMechanical carries
            % it, and (9-1)/8 is exactly 1.0.
            trl = F16APhysicalTradeGuards.TRLScale;
            raw = [testCase.rawWith("TRL", trl(1)); ...
                   testCase.rawWith("TRL", trl(2))];
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths, raw, testCase.criteria()), ...
                "The declared TRL scale " + trl(1) + ".." + trl(2) + " is INCLUSIVE at " + ...
                "both ends; HydroMechanical's TRL of 9 is a shipped value.");
        end

        function testMissingGuardedCriterionStopsTheTrade(testCase)
            % A criteria declaration that has lost Mass_lb must STOP the run,
            % not silently skip the mass check -- the difference between critIdx
            % erroring and returning empty.
            %
            % The values are all NaN because they are irrelevant: checkParameters
            % locates all three guarded parameters BEFORE it reads any of them.
            % That ordering is part of the contract, and this pins it -- a
            % version that read values first would report :badTRL on a NaN and
            % never mention the missing criterion.
            crit = testCase.criteriaWithoutMass();
            raw  = nan(1, numel(crit));
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, crit), ...
                testCase.NoSuchCriterionId, ...
                "A criteria declaration missing one of the three guarded parameters " + ...
                "must stop the trade, not drop the guard silently.");
        end

        function testCritIdxLocatesByNameAndRefusesToGuess(testCase)
            % Both halves: it finds what is there, and errors rather than
            % handing back an empty index for what is not.
            crit = testCase.criteria();
            testCase.verifyEqual(F16APhysicalTradeGuards.critIdx(crit, "Mass_lb"), 3, ...
                "critIdx must return the position of the named criterion.");
            testCase.verifyError( ...
                @() F16APhysicalTradeGuards.critIdx(crit, "NoSuchCriterionName"), ...
                testCase.NoSuchCriterionId, ...
                "critIdx must error on an undeclared criterion; returning empty would " + ...
                "make every check that uses it pass vacuously.");
        end

        function testParametersAreLocatedByNameNotByColumnPosition(testCase)
            % raw's columns must line up with crit's elements and NOTHING
            % validates that coupling, so the guard must honour whatever order
            % the declaration is in. A positional read would find 4730.23 where
            % it expected TRL and report :badTRL -- so the identifier alone
            % separates the two implementations.
            crit = testCase.criteriaReversed();
            raw  = testCase.rawForWith(crit, "Benefit", 78);
            testCase.verifyError(@() F16APhysicalTradeGuards.checkParameters( ...
                testCase.CandPaths(1), raw, crit), ...
                testCase.BadBenefitId, ...
                "Benefit, TRL and Mass_lb must be located BY NAME.");
        end

        % ---------------- rankRefusingTies: ranks, and refuses ------------

        function testTieForFirstPlaceStopsTheTrade(testCase)
            % Two candidates with the same score is a decision the data cannot
            % make, and sort order is not a decision.
            testCase.verifyError(@() F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5], testCase.Role), ...
                testCase.TieId, ...
                "A dead heat for first place must stop the trade; separating the two " + ...
                "by the order they appear in would record a winner the numbers never chose.");
        end

        function testTieWithinToleranceStopsTheTrade(testCase)
            % TieTol is a TOLERANCE, not exact equality: scores print to five
            % decimals, so a margin nobody can see is not one to decide on.
            tol = F16APhysicalTradeGuards.TieTol;
            testCase.verifyError(@() F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5 + tol/2], testCase.Role), ...
                testCase.TieId, ...
                "Two scores within TieTol are a dead heat; exact equality would let a " + ...
                "difference in the last bit decide the trade.");
        end

        function testMarginJustOutsideToleranceIsADecision(testCase)
            % The other side, so the tie guard cannot be satisfied by refusing
            % every close race.
            tol   = F16APhysicalTradeGuards.TieTol;
            order = F16APhysicalTradeGuards.rankRefusingTies( ...
                testCase.CandNames, [0.5, 0.5 + 10*tol], testCase.Role);
            testCase.verifyEqual(order(1), 2, ...
                "A margin larger than TieTol is a real result and the higher score must win.");
        end

        function testRankIsBestFirst(testCase)
            % rankRefusingTies ranks as well as judges. ORDER(1) is the winner
            % and ORDER(2) the runner-up D-034's "decided by" is measured
            % against, so a silently reversed ordering would rewrite every
            % stored justification.
            order = F16APhysicalTradeGuards.rankRefusingTies( ...
                ["Low","High","Mid"], [0.10, 0.90, 0.50], testCase.Role);
            testCase.verifyEqual(order, [2 3 1], ...
                "rankRefusingTies must return indices in DESCENDING score order.");
        end

        function testTieForSecondPlaceIsNotRefused(testCase)
            % Only FIRST place is a decision the data has to make.
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
            % 0.50/0.25/0.25 has stopped describing influence.
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), testCase.ceilingV(1.351), testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "A value function above 1.0 must be reported; silence would leave the " + ...
                "reader believing the declared weights still describe influence (D-035).");
        end

        function testValueAboveCeilingCapsNothing(testCase)
            % THE assertion D-035 turns on. Capping would discard a real
            % advantage and erroring would reject a legitimate candidate, so the
            % decision was to warn and change nothing.
            %
            % The load-bearing half is the OUTPUT LIST: a guard that capped would
            % have to hand the capped values back, so a method with no declared
            % outputs cannot cap however it is rewritten inside. The value
            % comparison is the belt to that braces.
            V      = testCase.ceilingV(1.351);
            before = V;
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), V, testCase.KeptWeights, testCase.criteria(), ...
                testCase.keptIndices(), testCase.Role), testCase.CeilingId);
            testCase.verifyEmpty(testCase.outputNamesOf("warnAboveCeiling"), ...
                "warnAboveCeiling must declare NO outputs: the moment it returns a " + ...
                "value matrix it can cap one, and D-035 decided not to cap.");
            testCase.verifyEqual(V, before, ...
                "warnAboveCeiling must leave the value matrix exactly as it was.");
        end

        function testValueExactlyOnTheCeilingDoesNotWarn(testCase)
            % Sitting ON the ceiling is not an exceedance, and this is not
            % hypothetical: Benefit = 10 gives B/10 = 1, TRL = 9 gives
            % (9-1)/8 = 1, and the Reference candidate's own mass ratio is 1.
            % All three are IEEE-exact and shipped, so a strict "> = warn"
            % would cry wolf on every run.
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1, 1, 1], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                "A value of exactly 1.0 is on the ceiling, not above it.");
        end

        function testValueInsideTheCeilingToleranceDoesNotWarn(testCase)
            % CeilingTol read from the code, so it is the tolerance being
            % checked and not a copy. It guards nothing today -- the three
            % values above are exact -- and exists so a future value function
            % reaching its ceiling through an inexact division does not report
            % itself as broken.
            tol = F16APhysicalTradeGuards.CeilingTol;
            testCase.verifyWarningFree(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1 + tol, 1 - tol, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                "A value within CeilingTol of 1.0 is on the ceiling; reporting rounding " + ...
                "dust would train the reader to ignore the warning that matters.");
        end

        function testValueOutsideTheCeilingToleranceWarns(testCase)
            % The other side, so CeilingTol cannot be widened into silence.
            tol = F16APhysicalTradeGuards.CeilingTol;
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [1 + 10*tol, 0.9, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "A value more than CeilingTol above 1.0 IS an exceedance; a tolerance " + ...
                "that swallowed it would turn the D-035 report off without a decision.");
        end

        function testTheCeilingCheckIsGenericOverCriteria(testCase)
            % D-035 wrote the check over the criteria GENERICALLY rather than
            % against Mass_lb by name, because UnitCost_USD inherits the
            % identical C_baseline/C shape the day a cost model lands. Not a
            % reachable state today -- checkParameters boxes TRL -- which is why
            % it is worth asserting: it proves the check keys on the VALUE, not
            % on which criterion happens to be unbounded right now.
            testCase.verifyWarning(@() F16APhysicalTradeGuards.warnAboveCeiling( ...
                testCase.CandPaths(1), [0.78, 1.20, 0.9], testCase.KeptWeights, ...
                testCase.criteria(), testCase.keptIndices(), testCase.Role), ...
                testCase.CeilingId, ...
                "The ceiling check must fire on ANY criterion whose value exceeds 1.0, " + ...
                "not only on Mass_lb.");
        end

    end

    methods (Access = private)

        function s = fmt(~, value)
            % A number as text. NOT "..." + value: string(NaN) is <missing>,
            % which the diagnostic framework rejects, so the obvious spelling
            % deletes the message on the very inputs these parameters cover.
            s = string(sprintf("%g", value));
        end

        function crit = criteria(~)
            % The criteria declaration in F16APhysicalTradeStudy's own order.
            % Only the two fields the guards READ are here: Name, which they
            % locate parameters by, and Rule, which warnAboveCeiling quotes.
            % Weight and Value are absent -- carrying them would imply the
            % guards consult them, and they do not.
            crit = struct( ...
                "Name", {"Benefit", "TRL",         "Mass_lb",      "UnitCost_USD"}, ...
                "Rule", {"B/10",    "(TRL-1)/8",   "M_baseline/M", "C_baseline/C"});
        end

        function crit = criteriaReversed(testCase)
            crit = fliplr(testCase.criteria());
        end

        function crit = criteriaWithoutMass(~)
            % A declaration that has lost one of the three guarded parameters.
            crit = struct( ...
                "Name", {"Benefit", "TRL",       "UnitCost_USD"}, ...
                "Rule", {"B/10",    "(TRL-1)/8", "C_baseline/C"});
        end

        function raw = validRowFor(testCase, crit)
            % One candidate's parameters, all acceptable. Placed BY NAME through
            % critIdx rather than as a literal row, so the fixture obeys the same
            % raw-columns-follow-crit-order contract the study does -- and so
            % criteriaReversed needs no second copy. UnitCost_USD stays NaN
            % because that is what a candidate carries permanently (D-043).
            raw = nan(1, numel(crit));
            raw(F16APhysicalTradeGuards.critIdx(crit, "Benefit")) = testCase.GoodBenefit;
            raw(F16APhysicalTradeGuards.critIdx(crit, "TRL"))     = testCase.GoodTRL;
            raw(F16APhysicalTradeGuards.critIdx(crit, "Mass_lb")) = testCase.GoodMass_lb;
        end

        function raw = rawForWith(testCase, crit, name, value)
            % A valid row with exactly ONE parameter replaced, so whichever
            % guard fires can only be the one under test.
            raw = testCase.validRowFor(crit);
            raw(F16APhysicalTradeGuards.critIdx(crit, name)) = value;
        end

        function raw = rawWith(testCase, name, value)
            raw = testCase.rawForWith(testCase.criteria(), name, value);
        end

        function keptIdx = keptIndices(testCase)
            % Indices into the full declaration of the criteria a real run
            % scores -- looked up by name, as validRowFor places by name.
            keptIdx = arrayfun( ...
                @(n) F16APhysicalTradeGuards.critIdx(testCase.criteria(), n), ...
                testCase.KeptCriteria);
        end

        function V = ceilingV(testCase, massValue)
            % One candidate's value row in KeptCriteria order, mass ratio set to
            % MASSVALUE. Benefit and TRL are what GoodBenefit and GoodTRL produce
            % through their value functions, so the row is one the study could
            % really compute.
            V = [testCase.GoodBenefit/10, (testCase.GoodTRL - 1)/8, massValue];
        end

        function names = outputNamesOf(~, methodName)
            % The declared OUTPUT list of one guard, from class metadata. A
            % method that returns nothing cannot hand back a capped value
            % matrix, which makes this the durable form of "does not cap". A
            % missing method yields a non-empty placeholder rather than an
            % error, so a renamed guard fails readably.
            mc  = meta.class.fromName("F16APhysicalTradeGuards");
            hit = mc.MethodList(string({mc.MethodList.Name}) == methodName);
            names = {char("<no such method: " + methodName + ">")};
            if isscalar(hit)
                names = hit.OutputNames;
            end
        end

    end
end
