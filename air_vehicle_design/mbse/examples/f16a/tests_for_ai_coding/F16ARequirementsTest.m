classdef F16ARequirementsTest < F16ATestCase
    %F16AREQUIREMENTSTEST Machinery checks on the four generated requirement sets.
    %   The R layer is this example's provenance root. This suite reads the four
    %   sets AS THEY SHIP -- slreq.load on the .slreqx, never the generator
    %   source -- and pins what everything downstream relies on:
    %
    %     * a decision requirement POSES its question and holds no answer: no
    %       vendor token (D-020, D-040) and no weight or score (D-026, D-037);
    %     * "todo" means student exercise and nothing else -- eleven of them,
    %       asserted as a SET so one losing the keyword cannot be masked by
    %       another gaining it (D-045, D-046);
    %     * no "verify" keyword anywhere: the Verify LINK is the record (D-048);
    %     * REQ_F16A_025 keeps its -6 %MAC floor, its strict zero ceiling and
    %       its illustrative-value label (D-030, D-046, D-048).
    %
    %   Machinery, not verification: nothing here asks whether the DESIGN meets
    %   a requirement. Requirement sets are in-memory global state, so the suite
    %   clears them on the way in AND out, and puts nothing on the path.

    properties (Access = private)
        TopSet      % f16a.slreqx                    -- sizing-derived
        FuncSet     % f16a_functional_derived.slreqx -- F-layer derived
        LogiSet     % f16a_logical_derived.slreqx    -- the L01-L03 decisions
        PhysSet     % f16a_physical_derived.slreqx   -- P01
    end

    properties (Constant, Access = private)
        % A weight or a score, i.e. a decimal literal -- NOT any digit.
        % REQ_F16A_025 and D-026 legitimately contain digits.
        NumericAnswer = "\d+\.\d+"

        % REQ_F16A_025's upper bound. An alternation because the bound is a
        % definition and the shipped requirement may carry it as prose or as
        % algebra. Every alternative is a POSITIVE form, none reachable by a
        % sentence that DENIES the criterion -- "shall not be negative"
        % contains "be negative", which is why the bare word is not one of
        % them. Add new positive forms here; do not fall back on contains().
        NegativeCriterion = "(?i)(SM\s*<\s*0|<\s*0|strictly negative|" + ...
            "(?:shall|must) (?:be|lie|remain) negative|negative static margin)"

        % The eleven standing student exercises: two balance TBDs (D-046) and
        % the nine derived capability requirements (D-045).
        TodoExercises = sort(["REQ_F16A_023", "REQ_F16A_024", "REQ_F16A_D0" + (1:9)])
    end

    methods (TestClassSetup)
        function loadRequirementSets(testCase)
            reqDir = fullfile(f16aRoot(), "requirements");
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
            % Matched as WHOLE TOKENS. contains(text,"GE") is unsafe even
            % case-sensitively: these sets talk about tarGEts and ranGEs, and
            % the example shouts for emphasis (RELAXED, MINIMIZED).
            hits = testCase.scanDecisionSet( ...
                "(?<![A-Za-z0-9_])" + testCase.VendorTokens + "(?![A-Za-z0-9_])");
            testCase.verifyNoOffenders(hits, ...
                "A decision requirement must pose its question without naming a " + ...
                "solution (D-020, D-040). Named");
        end

        function testDecisionRequirementsStateNoNumber(testCase)
            % The applied trade weights are derived at run time (D-026) and
            % this set is generated before the trade runs, so a number here
            % would be a claim rather than a record.
            hits = testCase.scanDecisionSet(testCase.NumericAnswer);
            testCase.verifyNoOffenders(hits, ...
                "A decision requirement must restate no weight and no score " + ...
                "(D-026, D-037). Found");
        end

        function testTodoMarksExactlyTheStudentExercises(testCase)
            % The "the blanks are the assignment" claim, made executable.
            actual = testCase.idsWithKeyword("todo");
            testCase.verifyEqual(actual, testCase.TodoExercises, ...
                "'todo' must mark exactly the eleven student exercises " + ...
                "(D-045, D-046) -- no more, no fewer.");
            % 025 has a real evaluated criterion whose answer is no (D-046);
            % P01 is verified and met (D-060). Neither is outstanding student
            % work, and one of them being red does not make it so.
            testCase.verifyNoOffenders(intersect(actual, ["REQ_F16A_025","REQ_F16A_P01"]), ...
                "REQ_F16A_025 (D-046) and REQ_F16A_P01 (D-060) are not student " + ...
                "exercises and must not carry 'todo'");
        end

        function testNoVerifyKeywordAnywhere(testCase)
            % D-048: the Verify LINK is the record that a requirement has a
            % test. Currently zero across all four sets -- pinned so it stays.
            testCase.verifyNoOffenders(testCase.idsWithKeyword("verify"), ...
                "No requirement may carry a 'verify' keyword; the Verify link " + ...
                "is the record (D-048)");
        end

        function testStaticMarginBandAndEstimateLabel(testCase)
            % The two ends of REQ_F16A_025's band are not the same kind of
            % thing and are not asserted the same way: the floor is an invented
            % figure, checked literally; the ceiling is a DEFINITION (relaxed
            % static stability IS negative static margin) and is checked by any
            % of the phrasings that carry it.
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
            % positive margin satisfied this requirement -- which is what
            % F16AStaticMarginVerificationTest's landing case now fails on.
            testCase.verifyEmpty(regexp(stated, "\+1\s*%MAC", "once"), ...
                "REQ_F16A_025 must no longer state a +1 %MAC upper bound: a " + ...
                "conventionally stable aircraft cannot satisfy a relaxed-stability " + ...
                "requirement.");
            testCase.verifySubstring(stated, "D-030", ...
                "REQ_F16A_025 must cite D-030, the estimate inventory.");
            % D-048's CANONICAL SENTENCE, not the bare word "Estimate", and the
            % difference is the point: a substring search for a provenance tag
            % cannot tell asserting it from DENYING it. A draft that dropped the
            % floor said "nothing here is an Estimate", and contains() would
            % have gone green on it. Do not weaken this to a single word.
            testCase.verifySubstring(stated, "illustrative teaching value, not sourced data", ...
                "REQ_F16A_025's -6 %MAC floor must carry D-048's canonical label " + ...
                "verbatim, not a private rewording (house rule 1).");
        end

        function testCostMeasureOfMeritKeywordsIntact(testCase)
            % A Measure of Merit gets no pass/fail threshold, so the keywords
            % are the only thing in the R artifact that says so (D-043).
            req = find(testCase.TopSet, Id="REQ_F16A_026");
            testCase.assertNotEmpty(req, "REQ_F16A_026 not found in f16a.slreqx.");
            missing = setdiff(["moe","objective","minimize"], lower(string(req.Keywords)));
            testCase.verifyNoOffenders(missing, ...
                "REQ_F16A_026 is a Measure of Merit, not a threshold; missing keyword(s)");
        end

        function testItemCountsPerSet(testCase)
            % Counted by walking children(), not find(set,Type="Requirement"),
            % so the count does not inherit that call's view of containers.
            testCase.verifyEqual(numel(itemsOf(testCase.TopSet)), 35, ...
                "f16a.slreqx: 26 requirements + 9 containers.");
            testCase.verifyEqual(numel(itemsOf(testCase.FuncSet)), 10, ...
                "f16a_functional_derived.slreqx: REQ_F16A_D01-D09 + root.");
            testCase.verifyEqual(numel(itemsOf(testCase.LogiSet)), 4, ...
                "f16a_logical_derived.slreqx: REQ_F16A_L01-L03 + root.");
            testCase.verifyEqual(numel(itemsOf(testCase.PhysSet)), 3, ...
                "f16a_physical_derived.slreqx: REQ_F16A_P01, P02 + root.");
        end

        function testRequirementIdsUniqueAcrossSets(testCase)
            % Every link, doc reference and TraceRef property cites a
            % requirement by id, so an id must mean one thing across all four.
            ids = arrayfun(@(r) string(r.Id), testCase.allItems());
            testCase.verifyEqual(numel(unique(ids)), numel(ids), ...
                "Requirement ids must be unique across the four sets.");
        end

        function testEveryRequirementIsStatedAndJustified(testCase)
            % Every non-container item says what it wants (Summary,
            % Description) and why (Rationale). Containers are excluded rather
            % than the assertion weakened -- MISSION/PERF/STRUCT and friends
            % deliberately carry a Summary only.
            testCase.verifyNoOffenders(testCase.itemsMissingText(), ...
                "Requirement with an empty Summary, Description or Rationale");
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
            %   requirement would. Returns "where -> what" so a failure names it.
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
%   Used instead of find(set,Type="Requirement") so nothing here depends on
%   how that call classifies a container.
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
%   string([]) is 0x0, and concatenating it collapses the whole result --
%   turning a text scan into a silent false pass rather than an error.
str = "";
if ~isempty(value); str = string(value); end
end
