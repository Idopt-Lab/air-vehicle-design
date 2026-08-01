classdef F16APhysicalTradeGuards
%F16APHYSICALTRADEGUARDS The trade study's numeric guard rails, on their own.
%   The three checks F16APhysicalTradeStudy runs over the NUMBERS it scores --
%   the parameter bounds, the refusal to break a tie, and the D-035 ceiling
%   warning -- lifted out of that file so each one can be made to fire without
%   running it.
%
%   EVERY METHOD HERE IS PURE. Values in; an error thrown, a warning raised, or
%   a clean return. No model handle, no f16aRoot, no file on disk, no
%   save_system, no persistent state. Nothing in this file can change an
%   artifact, which is the entire point of it existing.
%
%     F16APhysicalTradeGuards.checkParameters(candPaths, raw, crit)
%         Stops the trade on a Benefit, TRL or Mass_lb that cannot honestly be
%         scored. Throws :badTRL, :badMass, :badBenefit -- and :noSuchCriterion
%         if the criteria declaration it is handed is missing one of the three.
%
%     order = F16APhysicalTradeGuards.rankRefusingTies(candNames, score, role)
%         Ranks the candidates best-first and refuses to break a tie for first
%         place. Throws :tie.
%
%     F16APhysicalTradeGuards.warnAboveCeiling(candPaths, V, w, crit, keptIdx, role)
%         Reports -- without capping and without erroring -- a value function
%         that landed above the 1.0 its declared scale implies. Warns
%         :valueAboveCeiling.
%
%   -----------------------------------------------------------------------
%   WHY THIS IS NOT A LOCAL FUNCTION OF THE TRADE STUDY
%
%   A guard is only trustworthy once it has been SEEN TO FIRE, and while these
%   three lived inside F16APhysicalTradeStudy.m they could not be. That
%   function takes no arguments and hard-codes its model names, so the only way
%   to reach a guard was to run the whole study against the shipped artifacts
%   -- and that run is safe only for as long as the guard still works. Feed it
%   Benefit = 78 to prove the bound fires and, on the day somebody refactors
%   the bound away, the run does not stop: 78/10 = 7.8 at the heaviest weight
%   in the trade hands propulsion to TwinEngine_Surrogate, the run reaches
%   save_system, and a wrong active choice goes into F16A_Physical.slx, a wrong
%   active kind into F16A_Logical.slx and a wrong Implement link onto
%   REQ_F16A_L01. The negative test's failure mode was CORRUPTING THE
%   REPOSITORY, precisely on the occasion it was supposed to catch something,
%   so no negative test was written and the guards went unexercised in the one
%   direction that mattered (see the guard-rails section of
%   F16APhysicalArchitectureTest.m for the argument in full).
%
%   Nothing about the checks themselves required that. checkParameters never
%   touched a model -- a struct array, a numeric matrix and the criteria
%   declaration -- and the tie check and the ceiling check are arithmetic over
%   score, V and w. Lifting all three here turns each into a two-line
%   verifyError/verifyWarning with no artifact in sight, and leaves the study
%   calling them at exactly the points it called them before.
%
%   THE BOUNDS, AND THE DECISION BEHIND EACH ONE
%
%   TRL, 1..9 inclusive AND INTEGER (D-021). The stereotype property is int32
%   and so cannot hold NaN; D-021 therefore defaults it to 0, DELIBERATELY
%   outside the scale, so that "we forgot" cannot be scored as "mid-maturity".
%   That choice is only worth anything if something rejects the 0, and this is
%   where it is rejected. Integrality is part of the scale rather than a
%   nicety: TRL is an ordinal maturity level, so 4.5 is not a point on it.
%
%   Benefit, 1..10 inclusive, BOXED AT BOTH ENDS (D-033). Its default is 0 too,
%   so 0 is doing exactly the sentinel duty TRL's 0 does. The UPPER bound is
%   the one that earns its keep: v = B/10 carries the heaviest weight in the
%   trade and is the only term an out-of-range value can run away with. 78
%   typed for 7.8 contributes 3.90 against a legitimate per-criterion maximum
%   of 0.50 -- and being FINITE it is invisible to every isfinite check in the
%   study. Only a declared ceiling sees it. D-033 traces that single slipped
%   decimal point all the way to a wrong Implement link on REQ_F16A_L01.
%
%   Mass_lb, strictly positive. It is the DENOMINATOR of the mass value
%   function M_baseline/M, so zero is a divide-by-zero and a negative mass is
%   an inverted score. Worse than wrong: silently plausible.
%
%   The 1.0 ceiling, WARN and do not cap (D-035). Benefit and TRL cannot reach
%   it -- checkParameters boxes them, so B/10 and (TRL-1)/8 top out at exactly
%   1.0. The two RATIO criteria have no ceiling at all: a candidate lighter
%   than its role's baseline scores v > 1 and contributes more than its weight
%   allows, at which point the renormalized 0.50/0.25/0.25 has stopped
%   describing relative influence. Capping would discard a real advantage and
%   erroring would reject a legitimate candidate, so D-035 decided on neither
%   -- the honest response is to say out loud that the weights no longer mean
%   what they say. The check is written over the criteria GENERICALLY rather
%   than against Mass_lb by name, because UnitCost_USD inherits the identical
%   C_baseline/C shape the day a cost model lands.
%
%   The tie. A dead heat for first place is a decision the data cannot make,
%   and sort order is not a decision. Separating two candidates by the order
%   they happen to appear in would record a winner the numbers never chose.
%
%   IDENTIFIERS ARE UNCHANGED, DELIBERATELY. Every error and the one warning
%   still carry the F16APhysicalTradeStudy: prefix -- :badTRL, :badMass,
%   :badBenefit, :noSuchCriterion, :tie, :valueAboveCeiling. An identifier is
%   what a test asserts on and what the decision log quotes; renaming one to
%   match this file's name would break both to gain nothing. They name the
%   CONTRACT, not the file the code currently sits in.
%
%   WHAT IS NOT HERE. The study's other guards -- too few candidates, a
%   candidate that is not a variant choice, a role split across two variation
%   points, a baseline that is not unique, a partial criterion column, nothing
%   left to score -- are checks on the SET OF CANDIDATES THE WALK DISCOVERED
%   rather than on declared numbers. Several are pure as well, but each is
%   entangled with the value it computes on the way past (refIdx, keptIdx, the
%   renormalized weights), so lifting them means lifting the discovery and
%   renormalization pipeline with them. That is a refactor, not an extraction,
%   and it is not what this file is. The guards that touch a model handle or
%   the file system -- the three artifact-exists checks, :logicalRoleNotVariant,
%   :noSuchKind, :missingRequirement -- cannot come here at all.
%
%   See also F16APHYSICALTRADESTUDY, F16ADATAPROVENANCE, F16ASOURCEKIND.

    properties (Constant)

        % The declared TRL scale, 1..9 INCLUSIVE (D-021). Integrality is
        % enforced separately by checkParameters because it is a property of
        % the scale, not of its endpoints. Exposed as a constant so a reader --
        % or a test -- can take the bound from the code that enforces it
        % instead of restating the numbers and hoping the two stay agreed.
        TRLScale = [1 9]

        % The declared Benefit scale, 1..10 INCLUSIVE (D-033). 0 is the
        % stereotype default and therefore the "unset" sentinel, which is why
        % the scale starts at 1 rather than at 0.
        BenefitScale = [1 10]

        % How far above 1.0 a value function has to land before the run reports
        % it as exceeding the ceiling its declared scale implies (D-035).
        % Sitting EXACTLY on the ceiling is not an exceedance and must not
        % warn: the Reference candidate's own M_baseline/M is exactly 1, and
        % HydroMechanical's TRL of 9 gives (9-1)/8 = exactly 1. Both are
        % IEEE-exact, so this tolerance guards nothing today -- it is here so
        % that a future value function which lands on its ceiling through an
        % inexact division cries wolf at nobody.
        CeilingTol = 1e-9

        % How close the top two scores have to be before first place counts as
        % a tie. Scores are printed to five decimals and are sums of a handful
        % of products, so anything this close is a dead heat rather than a
        % margin -- and a margin the reader cannot see in the printed table is
        % not a margin anybody should decide on.
        TieTol = 1e-9

    end

    methods (Static)

        function checkParameters(candPaths, raw, crit)
        %CHECKPARAMETERS Stop the trade on a parameter that cannot honestly be scored.
        %   F16APhysicalTradeGuards.checkParameters(CANDPATHS, RAW, CRIT)
        %   returns silently when every candidate's Benefit, TRL and Mass_lb
        %   lies on its declared scale, and errors naming the offending
        %   candidate otherwise.
        %
        %   CANDPATHS  1-by-n string, the candidates' architecture paths. Used
        %              only to name the offender in the error message -- this
        %              is the whole of the function's contact with the model.
        %   RAW        n-by-numel(CRIT) double, the raw parameter values, one
        %              row per candidate, columns in CRIT order.
        %   CRIT       1-by-m struct with a Name field; the criteria
        %              declaration. Benefit, TRL and Mass_lb are located BY
        %              NAME, so column order is never assumed.
        %
        %   D-021 in force: an unset parameter must fail safe, not fail cheap.
        %   The bounds and the reasoning behind each are in the class help.
        %
        %   Errors: F16APhysicalTradeStudy:badTRL, :badMass, :badBenefit,
        %   :noSuchCriterion.
            arguments
                candPaths (1,:) string
                raw       (:,:) double
                crit      (1,:) struct
            end
            kB  = F16APhysicalTradeGuards.critIdx(crit, "Benefit");
            kT  = F16APhysicalTradeGuards.critIdx(crit, "TRL");
            kM  = F16APhysicalTradeGuards.critIdx(crit, "Mass_lb");
            trl = F16APhysicalTradeGuards.TRLScale;
            ben = F16APhysicalTradeGuards.BenefitScale;
            for i = 1:numel(candPaths)
                t = raw(i, kT);
                if ~isfinite(t) || t < trl(1) || t > trl(2) || mod(t,1) ~= 0
                    error("F16APhysicalTradeStudy:badTRL", ...
                        "Candidate %s carries TRL = %g. TRL must be an integer on the " + ...
                        "declared 1..9 scale; 0 is the D-021 'unset' sentinel and an " + ...
                        "unset parameter stops the trade rather than being scored as a " + ...
                        "plausible mid-pack value.", candPaths(i), t);
                end
                ms = raw(i, kM);
                if ~isfinite(ms) || ms <= 0
                    error("F16APhysicalTradeStudy:badMass", ...
                        "Candidate %s carries Mass_lb = %g. Mass must be positive -- it " + ...
                        "is the denominator of the mass value function M_baseline/M.", ...
                        candPaths(i), ms);
                end
                b = raw(i, kB);
                if ~isfinite(b) || b < ben(1) || b > ben(2)
                    error("F16APhysicalTradeStudy:badBenefit", ...
                        "Candidate %s carries Benefit = %g. Benefit must lie on the " + ...
                        "declared 1..10 scale; 0 is the stereotype default and therefore " + ...
                        "the 'unset' sentinel, exactly as TRL's 0 is under D-021. The " + ...
                        "upper bound is not decoration: at v = B/10 with the heaviest " + ...
                        "weight in the trade, 78 typed for 7.8 contributes 3.90 where " + ...
                        "0.50 is the most any criterion can legitimately be worth, and a " + ...
                        "finite out-of-range value is invisible to every other check in " + ...
                        "the trade study (D-033).", candPaths(i), b);
                end
            end
        end

        function order = rankRefusingTies(candNames, score, role)
        %RANKREFUSINGTIES Rank the candidates, and refuse to break a tie for first.
        %   ORDER = F16APhysicalTradeGuards.rankRefusingTies(CANDNAMES, SCORE,
        %   ROLE) returns the indices of SCORE in descending order -- so
        %   ORDER(1) is the winner and ORDER(2) the runner-up -- and errors
        %   when the top two scores are within TieTol of one another.
        %
        %   It ranks as well as checks ON PURPOSE. The caller needs the same
        %   ordering the tie test was applied to, and a guard that sorted,
        %   judged, and then threw its ordering away would force the caller to
        %   sort again -- two sorts that must agree forever, which is the kind
        %   of duplication that eventually does not.
        %
        %   CANDNAMES  1-by-n string, used only to name the two candidates in
        %              the error message.
        %   SCORE      n numeric scores, in CANDNAMES order.
        %   ROLE       the role being decided, for the message.
        %
        %   Requires at least two candidates; the study's :tooFewCandidates
        %   guard has already refused a one-option "trade" before this is
        %   reached.
        %
        %   Errors: F16APhysicalTradeStudy:tie.
            arguments
                candNames (1,:) string
                score           double
                role      (1,1) string
            end
            [sorted, order] = sort(score, "descend");
            if abs(sorted(1) - sorted(2)) <= F16APhysicalTradeGuards.TieTol
                error("F16APhysicalTradeStudy:tie", ...
                    "Role %s is a tie for first place: %s and %s both score %.6f. Sort " + ...
                    "order is not a decision -- separate them with data or add a " + ...
                    "criterion.", ...
                    role, candNames(order(1)), candNames(order(2)), sorted(1));
            end
        end

        function warnAboveCeiling(candPaths, V, w, crit, keptIdx, role)
        %WARNABOVECEILING Report a value function above the 1.0 its scale implies.
        %   F16APhysicalTradeGuards.warnAboveCeiling(CANDPATHS, V, W, CRIT,
        %   KEPTIDX, ROLE) raises one warning per (candidate, criterion) pair
        %   whose value exceeds 1 + CeilingTol, naming the candidate, the
        %   criterion, the value, and what it contributes against the weight
        %   that was supposed to bound it.
        %
        %   IT WARNS. It does not cap and it does not error, and both of those
        %   are decisions rather than omissions -- see D-035 and the class
        %   help. Nothing about the score changes because this fired.
        %
        %   CANDPATHS  1-by-n string, the candidates' architecture paths.
        %   V          n-by-numel(KEPTIDX) value matrix, in KEPTIDX order.
        %   W          the RENORMALIZED weights of the kept criteria.
        %   CRIT       the full criteria declaration (Name and Rule are read).
        %   KEPTIDX    indices into CRIT of the criteria actually scored.
        %   ROLE       the role being decided, for the message.
        %
        %   Warns: F16APhysicalTradeStudy:valueAboveCeiling.
            arguments
                candPaths (1,:) string
                V         (:,:) double
                w         (1,:) double
                crit      (1,:) struct
                keptIdx   (1,:) double
                role      (1,1) string
            end
            for kk = 1:numel(keptIdx)
                k = keptIdx(kk);
                for i = 1:numel(candPaths)
                    if V(i,kk) > 1 + F16APhysicalTradeGuards.CeilingTol
                        warning("F16APhysicalTradeStudy:valueAboveCeiling", ...
                            "Candidate %s scores v = %.4f on %s (%s), above the 1.0 " + ...
                            "ceiling the declared scales imply. It contributes %.5f to " + ...
                            "the score where its renormalized weight %.3f is the most " + ...
                            "the weighting intends any criterion to be worth, so the " + ...
                            "declared weights no longer describe relative influence for " + ...
                            "role %s. NOTHING IS CAPPED: the value is real and the " + ...
                            "candidate genuinely beats the baseline on this criterion. " + ...
                            "Read the score knowing the weights understate this " + ...
                            "criterion. Recorded as a known limit in D-035 of " + ...
                            "docs/07_decision_log.md; the fix is a bounded value " + ...
                            "function over a declared range per criterion, which is " + ...
                            "deferred.", ...
                            candPaths(i), V(i,kk), crit(k).Name, crit(k).Rule, ...
                            w(kk) * V(i,kk), w(kk), role);
                    end
                end
            end
        end

        function k = critIdx(crit, name)
        %CRITIDX Index of a criterion by name; errors rather than returning empty.
        %   Public rather than private so the guard it throws can be asserted
        %   in two lines like the others. checkParameters locates Benefit, TRL
        %   and Mass_lb through it, which is why a criteria declaration missing
        %   one of them stops the trade instead of silently skipping a check.
        %
        %   Errors: F16APhysicalTradeStudy:noSuchCriterion.
            arguments
                crit (1,:) struct
                name (1,1) string
            end
            k = find([crit.Name] == name, 1);
            if isempty(k)
                error("F16APhysicalTradeStudy:noSuchCriterion", ...
                    "No criterion named %s is declared.", name);
            end
        end

    end

end
