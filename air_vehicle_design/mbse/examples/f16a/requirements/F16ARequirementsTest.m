classdef F16ARequirementsTest < matlab.unittest.TestCase
    %F16AREQUIREMENTSTEST Machinery checks on the four generated requirement sets.
    %   The R layer is the provenance root of this example and, until now, the
    %   one layer whose output nothing asserted (TODO A10). This suite reads
    %   the four sets AS THEY SHIP -- slreq.load on the .slreqx, never the
    %   generator source -- and pins what everything downstream relies on:
    %
    %     * a decision requirement POSES its question and holds no answer:
    %       nothing in f16a_logical_derived.slreqx names a vendor or programme
    %       (D-020) or states a weight or score (D-037, D-040);
    %     * "todo" means student exercise and nothing else -- eleven of them,
    %       asserted as a SET so one exercise losing the keyword cannot be
    %       masked by another requirement gaining it (D-045, D-046);
    %     * no requirement carries a "verify" keyword: the Verify LINK is the
    %       record that a requirement has a test, and a generator-written
    %       keyword mirroring a hand-made link cannot be kept in step (D-048);
    %     * REQ_F16A_025 keeps its -6 %MAC floor and the illustrative-value
    %       label that cleared the data audit (D-030, D-046), and has lost the
    %       +1 %MAC cap: the upper bound is now zero and strict.
    %
    %   Machinery, not verification: nothing here asks whether the DESIGN meets
    %   a requirement -- that is what verification/ is for. Requirement sets are
    %   in-memory global state, so the suite clears them on the way in AND on
    %   the way out, and puts nothing on the path.

    properties (Access = private)
        TopSet      % f16a.slreqx                    -- sizing-derived
        FuncSet     % f16a_functional_derived.slreqx -- F-layer derived
        LogiSet     % f16a_logical_derived.slreqx    -- the L01-L03 decisions
        PhysSet     % f16a_physical_derived.slreqx   -- P01
    end

    properties (Constant, Access = private)
        % D-020's vendor/programme vocabulary, matched as WHOLE TOKENS.
        % contains(text,"GE") is unsafe here even case-sensitively: these sets
        % already talk about targets (REQ_F16A_D05-D09) and ranges
        % (REQ_F16A_025, REQ_F16A_P01), and this example shouts for emphasis
        % (RELAXED, MINIMIZED, PLACEHOLDER), so one TARGET or RANGE would
        % silently fail the test.
        SolutionTokens = ["F100","F110","PW","GE","LWF","Analog"]

        % A weight or a score, i.e. a decimal literal -- NOT any digit.
        % REQ_F16A_025, F16A_Logical.slx and D-026 all legitimately contain
        % digits.
        NumericAnswer = "\d+\.\d+"

        % REQ_F16A_025's upper bound: the margin must be strictly BELOW zero.
        % An alternation, because the bound is a definition and the shipped
        % requirement may carry it as prose or as algebra -- this suite reads
        % the artifact, it does not dictate its wording. Every alternative is a
        % POSITIVE form, none reachable by a sentence that DENIES the criterion:
        % "shall not be negative" contains "be negative" but not "shall be
        % negative", which is why the bare word is not one of them. If a reword
        % states the ceiling in some other positive form, add that form here --
        % do not fall back on a bare contains().
        NegativeCriterion = "(?i)(SM\s*<\s*0|<\s*0|strictly negative|" + ...
            "(?:shall|must) (?:be|lie|remain) negative|negative static margin)"

        % The eleven standing student exercises: the two balance TBDs (D-046)
        % and the nine derived capability requirements (D-045).
        TodoExercises = sort(["REQ_F16A_023", "REQ_F16A_024", "REQ_F16A_D0" + (1:9)])
    end

    methods (TestClassSetup)
        function loadRequirementSets(testCase)
            reqDir = fileparts(mfilename("fullpath"));   % the sets sit beside this file
            slreq.clear();
            testCase.addTeardown(@() slreq.clear());     % registered BEFORE the loads
            testCase.TopSet  = slreq.load(fullfile(reqDir, "f16a.slreqx"));
            testCase.FuncSet = slreq.load(fullfile(reqDir, "f16a_functional_derived.slreqx"));
            testCase.LogiSet = slreq.load(fullfile(reqDir, "f16a_logical_derived.slreqx"));
            testCase.PhysSet = slreq.load(fullfile(reqDir, "f16a_physical_derived.slreqx"));
        end
    end

    methods (Test)

        function testDecisionRequirementsNameNoSolution(testCase)
            % No vendor or programme token anywhere in the decision set --
            % Summary, Description or Rationale. The root container is scanned
            % too: it carries the framing shared by L01-L03, so it is just as
            % capable of leaking the answer (D-037, D-040).
            hits = testCase.scanDecisionSet( ...
                "(?<![A-Za-z0-9_])" + testCase.SolutionTokens + "(?![A-Za-z0-9_])");
            testCase.verifyEmpty(hits, ...
                "A decision requirement must pose its question without naming a " + ...
                "solution (D-020, D-040). Named: " + listOf(hits));
        end

        function testDecisionRequirementsStateNoNumber(testCase)
            % ...and no weight and no score. The applied trade weights are
            % derived at run time (D-026) and this set is generated before the
            % trade runs, so any number here would be a claim, not a record.
            hits = testCase.scanDecisionSet(testCase.NumericAnswer);
            testCase.verifyEmpty(hits, ...
                "A decision requirement must restate no weight and no score " + ...
                "(D-026, D-037). Found: " + listOf(hits));
        end

        function testTodoMarksExactlyTheStudentExercises(testCase)
            % The "the blanks are the assignment" claim, made executable.
            actual = testCase.idsWithKeyword("todo");
            testCase.verifyEqual(actual, testCase.TodoExercises, ...
                "'todo' must mark exactly the eleven student exercises " + ...
                "(D-045, D-046) -- no more, no fewer.");
            % Spelled out because the REASON these two are excluded is the
            % teaching point: 025 has a real, evaluated criterion (D-046) whose
            % answer happens to be no, and P01's verification is pending BY
            % DESIGN (D-042). A violated requirement and an unevaluated one are
            % both red; neither is outstanding work.
            notExercises = intersect(actual, ["REQ_F16A_025", "REQ_F16A_P01"]);
            testCase.verifyEmpty(notExercises, ...
                "REQ_F16A_025 (D-046) and REQ_F16A_P01 (D-042) are not student " + ...
                "exercises and must not carry 'todo': " + listOf(notExercises));
        end

        function testNoVerifyKeywordAnywhere(testCase)
            % D-048: the Verify LINK is the record that a requirement has a
            % test. Currently zero across all four sets -- pinned so it stays.
            ids = testCase.idsWithKeyword("verify");
            testCase.verifyEmpty(ids, ...
                "No requirement may carry a 'verify' keyword; the Verify link " + ...
                "is the record (D-048): " + listOf(ids));
        end

        function testStaticMarginBandAndEstimateLabel(testCase)
            % REQ_F16A_025 must keep BOTH ends of its band -- now -6 %MAC <= SM
            % < 0, inclusive floor and STRICT ceiling -- and the label that
            % cleared the Stage-0 data veto. Nothing else stops a future edit
            % quietly dropping the provenance and leaving a bare number.
            % The two ends are not the same kind of thing and are not asserted
            % the same way: the floor is an invented figure and is checked
            % literally, the ceiling is a DEFINITION (relaxed static stability
            % IS negative static margin; zero is where the sign changes) and is
            % checked by any of the phrasings that carry it.
            req = find(testCase.TopSet, Id="REQ_F16A_025");
            testCase.assertNotEmpty(req, "REQ_F16A_025 not found in f16a.slreqx.");
            stated = itemText(req);
            testCase.verifySubstring(stated, "-6 %MAC", ...
                "REQ_F16A_025 must state the -6 %MAC lower bound.");
            testCase.verifyNotEmpty(regexp(stated, testCase.NegativeCriterion, "once"), ...
                "REQ_F16A_025 must state that the static margin is required to be " + ...
                "NEGATIVE -- the upper bound is zero and strict, so a neutrally " + ...
                "stable aircraft does not satisfy it.");
            % The withdrawn cap, asserted ABSENT: while +1 %MAC stood, a
            % positive margin satisfied this requirement, which is what
            % F16AStaticMarginVerificationTest's landing case now fails on. Both
            % must not be true at once.
            testCase.verifyEmpty(regexp(stated, "\+1\s*%MAC", "once"), ...
                "REQ_F16A_025 must no longer state a +1 %MAC upper bound: a " + ...
                "conventionally stable aircraft cannot be allowed to satisfy a " + ...
                "relaxed-stability requirement.");
            testCase.verifySubstring(stated, "D-030", ...
                "REQ_F16A_025 must cite D-030, the estimate inventory.");
            % The CANONICAL SENTENCE agreed in D-048, not the bare word
            % "Estimate" -- and the difference is the point. A substring search
            % for a provenance tag cannot tell asserting it from DENYING it: a
            % draft of this requirement that dropped the floor said "nothing
            % here is an Estimate", and a bare contains() would have gone green
            % on the sentence saying the label does not apply. Do not weaken
            % this back to a single word.
            testCase.verifySubstring(stated, "illustrative teaching value, not sourced data", ...
                "REQ_F16A_025's -6 %MAC floor must carry D-048's canonical label -- " + ...
                "'an illustrative teaching value, not sourced data' -- verbatim, not " + ...
                "presented as sourced data and not in a private rewording " + ...
                "(house rule 1).");
        end

        function testCostMeasureOfMeritKeywordsIntact(testCase)
            % A Measure of Merit gets no pass/fail threshold, so the keywords
            % are the only thing in the R artifact that says so (D-043).
            req = find(testCase.TopSet, Id="REQ_F16A_026");
            testCase.assertNotEmpty(req, "REQ_F16A_026 not found in f16a.slreqx.");
            expected = ["moe", "objective", "minimize"];
            missing = setdiff(expected, lower(string(req.Keywords)));
            testCase.verifyEmpty(missing, ...
                "REQ_F16A_026 is a Measure of Merit, not a threshold; missing " + ...
                "keyword(s): " + listOf(missing));
        end

        function testItemCountsPerSet(testCase)
            % Counted by walking children(), not by find(set,Type="Requirement"),
            % so the count does not inherit that call's view of containers.
            testCase.verifyEqual(numel(itemsOf(testCase.TopSet)), 35, ...
                "f16a.slreqx: 26 requirements + 9 containers.");
            testCase.verifyEqual(numel(itemsOf(testCase.FuncSet)), 10, ...
                "f16a_functional_derived.slreqx: REQ_F16A_D01-D09 + root.");
            testCase.verifyEqual(numel(itemsOf(testCase.LogiSet)), 4, ...
                "f16a_logical_derived.slreqx: REQ_F16A_L01-L03 + root.");
            testCase.verifyEqual(numel(itemsOf(testCase.PhysSet)), 2, ...
                "f16a_physical_derived.slreqx: REQ_F16A_P01 + root.");
        end

        function testRequirementIdsUniqueAcrossSets(testCase)
            % Every Implement/Verify link, every doc reference and every
            % trace-ref property in F16A_Physical.slx cites a requirement by
            % id, so an id must mean one thing across all four sets.
            ids = arrayfun(@(r) string(r.Id), testCase.allItems());
            testCase.verifyEqual(numel(unique(ids)), numel(ids), ...
                "Requirement ids must be unique across the four sets.");
        end

        function testEveryRequirementIsStatedAndJustified(testCase)
            % Every non-container item says what it wants (Summary,
            % Description) and why (Rationale). Containers are excluded rather
            % than the assertion weakened: f16a.slreqx's MISSION/PERF/STRUCT
            % and friends deliberately carry a Summary only.
            silent = testCase.itemsMissingText();
            testCase.verifyEmpty(silent, ...
                "Requirement with an empty Summary, Description or Rationale: " + ...
                listOf(silent));
        end

    end

    methods (Access = private)

        function items = allItems(testCase)
            %ALLITEMS Every requirement and container in all four sets.
            items = [itemsOf(testCase.TopSet),  itemsOf(testCase.FuncSet), ...
                     itemsOf(testCase.LogiSet), itemsOf(testCase.PhysSet)];
        end

        function hits = scanDecisionSet(testCase, patterns)
            %SCANDECISIONSET Text in the decision set matching any of PATTERNS.
            %   Covers every item's Summary/Description/Rationale AND the set's
            %   own Description, which introduces the trade in the same words a
            %   requirement would and can leak the answer just as easily.
            %   Returns "where -> what" so a failure names the leak.
            labels = "f16a_logical_derived (set description)";
            texts  = asText(testCase.LogiSet.Description);
            items  = itemsOf(testCase.LogiSet);
            for k = 1:numel(items)
                labels(end+1) = string(items(k).Id); %#ok<AGROW>
                texts(end+1)  = itemText(items(k));  %#ok<AGROW>
            end
            hits = strings(1,0);
            for k = 1:numel(texts)
                for p = patterns
                    found = regexp(texts(k), p, "match", "once");
                    if strlength(found) > 0
                        hits(end+1) = labels(k) + " -> " + found; %#ok<AGROW>
                    end
                end
            end
        end

        function ids = idsWithKeyword(testCase, keyword)
            %IDSWITHKEYWORD Sorted ids carrying KEYWORD, across all four sets.
            ids = strings(1,0);
            items = testCase.allItems();
            for k = 1:numel(items)
                if any(lower(string(items(k).Keywords)) == lower(keyword))
                    ids(end+1) = string(items(k).Id); %#ok<AGROW>
                end
            end
            ids = sort(ids);
        end

        function ids = itemsMissingText(testCase)
            %ITEMSMISSINGTEXT Ids of non-container items with a blank field.
            ids = strings(1,0);
            items = testCase.allItems();
            for k = 1:numel(items)
                if strcmp(asText(items(k).Type), "Container"); continue; end
                stated = [asText(items(k).Summary), asText(items(k).Description), ...
                          asText(items(k).Rationale)];
                if any(strlength(strtrim(stated)) == 0)
                    ids(end+1) = string(items(k).Id); %#ok<AGROW>
                end
            end
        end

    end
end

% ---------------------------------------------------------------------------

function items = itemsOf(node)
%ITEMSOF Every requirement and container at or below NODE.
%   NODE is an slreq.ReqSet or an slreq.Requirement; children() works on both.
%   Used instead of find(set,Type="Requirement") so nothing in this suite
%   depends on how that call classifies a container.
kids = children(node);
items = kids;
for k = 1:numel(kids)
    items = [items, itemsOf(kids(k))]; %#ok<AGROW>
end
end

function stated = itemText(req)
%ITEMTEXT Summary, Description and Rationale as one string scalar.
stated = asText(req.Summary) + " " + asText(req.Description) + " " + asText(req.Rationale);
end

function str = asText(value)
%ASTEXT VALUE as a string scalar, "" when unset.
%   string([]) is 0x0, and concatenating it collapses the whole result -- which
%   would turn a text scan into a silent false pass rather than an error.
str = "";
if ~isempty(value); str = string(value); end
end

function str = listOf(items)
%LISTOF Join for a diagnostic; "" when empty, so the message always evaluates.
str = "";
if ~isempty(items); str = strjoin(string(items), "; "); end
end
