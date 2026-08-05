function results = F16APhysicalTradeStudy()
%F16APHYSICALTRADESTUDY Score the F-16A physical candidates and record the decision.
%   RESULTS = F16APHYSICALTRADESTUDY() finds every component in F16A_Physical
%   carrying the TradeCandidate stereotype, groups them by the role each says
%   it realizes, scores each role's candidates, and writes the winner into P
%   (active choice, Selected, rationales), L (active kind, SolutionOption
%   .Selected, DecisionRef) and R (an Implement link from the winning KIND to
%   REQ_F16A_L01..L03).
%
%   RESULTS is a dictionary from role to ranked table. A table cannot live in a
%   dictionary's value array, so read it WITH BRACES: results{"Airframe"}.
%
%   Teaching point: this is the file the layer split exists for. L enumerates
%   technology-neutral kinds; P holds the parameterized candidates and is the
%   only layer that can decide (D-001). Losers are kept, not deleted (D-002),
%   and no candidate name appears here -- they are DISCOVERED.
%
%   Scoring uses declared value functions, not min-max (D-015); the guard rails
%   live in F16APhysicalTradeGuards.m. Re-running is idempotent. Requires the P
%   and L models and the decision requirement set; generate_f16a_physical.m
%   calls this as its section 7b.

modelName   = "F16A_Physical";
profileName = "F16A_PhysicalProps";
logiName    = "F16A_Logical";
logiProfile = "F16A_LogicalOptions";

% Separator between the trade verdict and the part's standing rationale in
% Rationale.Justification. It is what makes the rewrite idempotent: everything
% before it is regenerated, everything after it is carried through untouched.
JUSTSENTINEL = " || ";

% Role -> the requirement the decision is recorded in. The ONLY declared
% mapping in this file (see the header): candidates are discovered, decision
% requirements cannot be.
DECISIONREQS = { ...
    "PropulsionSystem",    "REQ_F16A_L01"; ...
    "FlightControlSystem", "REQ_F16A_L02"; ...
    "Airframe",            "REQ_F16A_L03"};

thisDir   = f16aRoot();   % example root, via anchor (f16aRoot.m)
physDir   = fullfile(thisDir, "physical");
logiDir   = fullfile(thisDir, "logical");
reqDir    = fullfile(thisDir, "requirements");
modelFile = fullfile(physDir, modelName + ".slx");
logiFile  = fullfile(logiDir, logiName + ".slx");
derFile   = fullfile(reqDir, "f16a_logical_derived.slreqx");
addpath(physDir); addpath(logiDir); addpath(reqDir);

if ~isfile(modelFile)
    error("F16APhysicalTradeStudy:noPhysicalModel", ...
        "Missing %s. Run generate_f16a_physical first.", modelFile);
end
if ~isfile(logiFile)
    error("F16APhysicalTradeStudy:noLogicalModel", ...
        "Missing %s. Run generate_f16a_logical first.", logiFile);
end
if ~isfile(derFile)
    error("F16APhysicalTradeStudy:noDecisionRequirements", ...
        "Missing %s. Run generate_f16a_logical_derived_requirements first -- the " + ...
        "trade has nowhere to record its decisions without it.", derFile);
end

m      = systemcomposer.loadModel(modelName);
lm     = systemcomposer.loadModel(logiName);
derSet = slreq.load(derFile);

% Load the L model's link set BEFORE any link is queried. Creating a link would
% load it implicitly, but the idempotency check in linkImplementOnce reads
% req.inLinks() FIRST, and an unloaded link set reads as "this requirement has
% no incoming links" -- which would quietly duplicate every decision link on the
% second run. Guarded because on a first run there may be no link set yet, and
% the L model's link set also holds the L generator's own Implement links
% (REQ_F16A_020/023/024/025), which must survive this run untouched.
try slreq.load(logiName); catch, end %#ok<CTCH>

% --- The criteria, declared once -----------------------------------------
% Weight is the DECLARED weight, before any criterion is dropped; Value is the
% value function v(raw, baseline) of D-015; Rule is what gets printed and
% written into the rationale, so the model states its own scoring scheme.
% Benefit and TRL ignore the baseline argument -- their scale is absolute, and
% because F16APhysicalTradeGuards.checkParameters boxes both of them at both
% ends their value cannot exceed 1.0. The two ratio criteria have no such
% ceiling, which is what the D-035 check below exists to report.
crit = struct( ...
    "Name",   {"Benefit",   "TRL",         "Mass_lb",      "UnitCost_USD"}, ...
    "Weight", {0.40,        0.20,          0.20,           0.20}, ...
    "Value",  {@(x,b) x/10, @(x,b) (x-1)/8, @(x,b) b/x,    @(x,b) b/x}, ...
    "Rule",   {"B/10",      "(TRL-1)/8",   "M_baseline/M", "C_baseline/C"});
nCrit = numel(crit);

% --- Discover the candidates ---------------------------------------------
cands = collectCandidates(m.Architecture, modelName, profileName);
if isempty(cands)
    error("F16APhysicalTradeStudy:noCandidates", ...
        "No component in %s carries the %s.TradeCandidate stereotype. Either the " + ...
        "model was built without candidates or the walk failed to reach them -- a " + ...
        "variant's choices are reachable only through getChoices.", modelName, profileName);
end
roles = unique([cands.Role]);   % sorted, so the report order is deterministic

fprintf("\n########## F-16A PHYSICAL TRADE STUDY ##########\n");
fprintf("%d candidates discovered across %d roles in %s.\n", ...
    numel(cands), numel(roles), modelName);
fprintf("Scoring: declared value functions, weights renormalized over the criteria " + ...
    "that carry values (D-005, D-015).\n");

% The ranked table of each role, collected here and handed back as a DICTIONARY
% (roles -> table) built in one call below. Two properties of dictionary drove
% the shape of this, and both differ from the containers.Map it replaced:
%   * VALUES ARE CELL-WRAPPED. A dictionary keeps its values in a value ARRAY,
%     and a table cannot live in one, so a table is held in a cell -- which is
%     what makes BRACES the accessor: results{role} hands back the table itself,
%     results(role) would hand back the 1x1 cell around it.
%   * KEY ORDER IS INSERTION ORDER, where containers.Map sorted its keys.
%     MEASURED, Stage 3: inserting PropulsionSystem, Airframe,
%     FlightControlSystem reads back from keys() in exactly that order, and
%     from a containers.Map alphabetically. The two agree here only because
%     roles came from unique() above and is therefore already sorted, so the
%     reported role order is unchanged (docs/05_physical.md reproduces that
%     table). Keep roles sorted, or that order moves.
roleTables  = cell(1, numel(roles));
winnerNames = strings(1, numel(roles));

for r = 1:numel(roles)
    role  = roles(r);
    reqId = decisionRequirementFor(DECISIONREQS, role);
    rc    = cands([cands.Role] == role);
    n     = numel(rc);

    % ---- guard: a role with one option is not a trade --------------------
    if n < 2
        error("F16APhysicalTradeStudy:tooFewCandidates", ...
            "Role %s has %d candidate(s) (%s). A trade needs at least two: with one " + ...
            "option there is nothing to decide, and recording a 'winner' would claim a " + ...
            "comparison that never happened.", role, n, strjoin([rc.Name], ", "));
    end

    % ---- the variant that owns them --------------------------------------
    % Taken from the walk, not from the role name: the propulsion candidates
    % live under a variant called Engine, not one called PropulsionSystem.
    ownerPaths = unique([rc.OwnerPath]);
    if any(ownerPaths == "")
        error("F16APhysicalTradeStudy:candidateNotAChoice", ...
            "A candidate of role %s is not a variant choice, so there is no variation " + ...
            "point to set: %s. A candidate must be a choice of the variant component " + ...
            "that models its role (D-002).", role, strjoin([rc([rc.OwnerPath] == "").Path], ", "));
    end
    if numel(ownerPaths) > 1
        error("F16APhysicalTradeStudy:splitRole", ...
            "Role %s has candidates under %d different variant components (%s). One " + ...
            "role is one decision, so its candidates must be choices of one variation " + ...
            "point.", role, numel(ownerPaths), strjoin(ownerPaths, ", "));
    end
    vc = rc(1).Owner;

    % ---- read the raw parameters -----------------------------------------
    raw = nan(n, nCrit);
    for i = 1:n
        for k = 1:nCrit
            raw(i,k) = readNum(rc(i).Comp, profileName + ".TradeCandidate." + crit(k).Name);
        end
    end
    % Only the candidates' PATHS go across, never the struct that holds their
    % component handles: the guard names an offender in its message and has no
    % other business with the model (D-021, D-033).
    F16APhysicalTradeGuards.checkParameters([rc.Path], raw, crit);

    % ---- the baseline for the ratio criteria -----------------------------
    isRef = [rc.Provenance] == "Reference";
    if sum(isRef) ~= 1
        error("F16APhysicalTradeStudy:baselineNotUnique", ...
            "Role %s has %d candidates tagged DataProvenance = Reference {%s}; exactly " + ...
            "one is required. It is the baseline every ratio value function divides by " + ...
            "(D-015), so with none there is no scale and with two there is no answer to " + ...
            "which one.", role, sum(isRef), strjoin([rc(isRef).Name], ", "));
    end
    refIdx   = find(isRef);
    baseline = raw(refIdx, :);

    % ---- drop the criteria nobody carries, renormalize the rest ----------
    keep = true(1, nCrit);
    for k = 1:nCrit
        nGood = sum(isfinite(raw(:,k)));
        if nGood == 0
            keep(k) = false;
        elseif nGood < n
            error("F16APhysicalTradeStudy:partialCriterion", ...
                "Criterion %s has a value on %d of the %d candidates of role %s. A " + ...
                "criterion is scored when every candidate has a value and dropped when " + ...
                "none does; a partial column would score the candidates that happen to " + ...
                "carry data against the ones that do not.", crit(k).Name, nGood, n, role);
        end
    end
    if ~any(keep)
        error("F16APhysicalTradeStudy:nothingToScore", ...
            "Every criterion is empty for role %s, so there is nothing to score.", role);
    end
    keptIdx = find(keep);
    nKept   = numel(keptIdx);
    w       = [crit(keptIdx).Weight];
    w       = w / sum(w);           % renormalized over what is left (D-005)
    dropped = [crit(~keep).Name];

    % ---- value functions and the weighted score --------------------------
    V = zeros(n, nKept);
    for kk = 1:nKept
        k = keptIdx(kk);
        for i = 1:n
            V(i,kk) = crit(k).Value(raw(i,k), baseline(k));
        end
    end
    if any(~isfinite(V(:)))
        error("F16APhysicalTradeStudy:badValue", ...
            "A value function returned a non-finite result for role %s. Check the " + ...
            "baseline and the raw parameters.", role);
    end

    % ---- a value above its declared ceiling weakens the weights (D-035) ---
    % WARN, do not cap and do not error. Benefit and TRL cannot get here --
    % the parameter guard boxes them, so B/10 and (TRL-1)/8 top out at 1.0.
    % The RATIO criteria have no ceiling at all: a candidate lighter than the
    % baseline scores v > 1 and contributes more than its weight allows, so
    % the renormalized 0.50/0.25/0.25 stops describing relative influence.
    % Capping would throw away a genuine advantage and erroring would reject a
    % legitimate candidate; the only honest option left is to say so. The
    % check is written over the criteria GENERICALLY rather than against
    % Mass_lb by name, because UnitCost_USD inherits the identical
    % C_baseline/C shape the day a cost model lands and would otherwise arrive
    % with the check missing. It says nothing today: no candidate is lighter
    % than its role's baseline.
    F16APhysicalTradeGuards.warnAboveCeiling([rc.Path], V, w, crit, keptIdx, role);

    score = V * w(:);

    % ---- rank, and refuse to break a tie ---------------------------------
    % The guard ranks as well as checks, so this file does not sort a second
    % time: the ordering the tie test was applied to IS the ordering used
    % below to pick the winner and the runner-up.
    order  = F16APhysicalTradeGuards.rankRefusingTies([rc.Name], score, role);
    rankOf = zeros(n,1);
    rankOf(order) = 1:n;
    win = order(1);
    rup = order(2);
    kindName = rc(win).Kind;
    winnerNames(r) = rc(win).Name;

    % ---- the auditable table ---------------------------------------------
    T = table([rc.Name].', [rc.Kind].', 'VariableNames', {'Candidate','Kind'});
    for k = 1:nCrit
        T.(char(crit(k).Name)) = raw(:,k);
    end
    for kk = 1:nKept
        T.(char("v_" + crit(keptIdx(kk)).Name)) = V(:,kk);
    end
    T.Score    = score;
    T.Rank     = rankOf;
    T.Selected = (rankOf == 1);
    T = sortrows(T, "Rank");
    roleTables{r} = T;

    printRole(role, reqId, rc, refIdx, crit, keep, keptIdx, w, baseline, ...
        raw, V, score, rankOf, order);

    % ---- (1) P side: configuration ---------------------------------------
    setActiveChoice(vc, rc(win).Name);
    for i = 1:n
        setProperty(rc(i).Comp, profileName + ".TradeCandidate.Selected", ...
            string(i == win));
    end

    % ---- (2) P side: rationale -------------------------------------------
    % The verdict is regenerated every run and the part's standing rationale
    % is preserved behind the sentinel, so this is a rewrite and not a pile-up.
    critText = criteriaSentence(crit, keptIdx, w, dropped, rc(refIdx).Name);
    for i = 1:n
        if i == win
            kind = "F16ASourceKind.TradeWinner";
            verdict = winnerSentence(rc, win, rup, n, score, V, w, crit, keptIdx, ...
                critText, reqId, kindName);
        else
            kind = "F16ASourceKind.TradeAlternative";
            verdict = loserSentence(rc, i, win, n, score, rankOf, V, w, crit, keptIdx, ...
                critText, reqId);
        end
        setProperty(rc(i).Comp, profileName + ".Rationale.SourceKind", kind);
        setProperty(rc(i).Comp, profileName + ".Rationale.Justification", ...
            quoteLit(verdict + JUSTSENTINEL + ...
                standingRationale(rc(i).Comp, profileName, JUSTSENTINEL)));
    end

    % ---- (3) L side: the cross-layer callback ----------------------------
    % Keyed on the winner's KIND, never on its name: the mapping is many-to-one
    % (two engine candidates both realize SingleEngine), so the candidate name
    % is not a valid key into the L option set. The winning kind's component
    % handle comes back out, because section (4) needs it and re-finding it by
    % path would mean a lookup across a variant boundary on a loaded model --
    % the exact thing getChoices exists to avoid (finding 6).
    kindComp = writeLogicalDecision(lm, logiName, logiProfile, role, kindName, reqId);

    % ---- (4) R side: Implement-link the winning kind ---------------------
    req = find(derSet, Id=char(reqId));
    if isempty(req)
        error("F16APhysicalTradeStudy:missingRequirement", ...
            "Decision requirement %s is not in %s, so the decision for role %s has " + ...
            "nowhere to be recorded.", reqId, derFile, role);
    end
    linkImplementOnce(kindComp, req, logiName);
end

% --- The return value ----------------------------------------------------
% Built in one call from the sorted role list and the cell of ranked tables,
% which is the documented constructor for a dictionary whose values are held in
% a cell array. Insertion order is therefore roles' order, i.e. sorted.
results = dictionary(roles, roleTables);

% --- Persist -------------------------------------------------------------
% Both models, the decision requirement set, and ONLY the F16A_Logical model
% link set. The functional layer's link set is never written here: the trade
% has no business touching it, and re-saving it would churn a file this run
% did not change.
save_system(modelName, char(modelFile));
save_system(logiName, char(logiFile));
save(derSet);
saveLogicalLinkSets(logiName);

fprintf("\n########## DECISION RECORDED ##########\n");
fprintf("%d roles decided: %s.\n", numel(roles), strjoin(winnerNames, ", "));
fprintf("P: active choice + TradeCandidate.Selected + Rationale (TradeWinner / " + ...
    "TradeAlternative) written to %s.\n", modelName);
fprintf("L: active kind + SolutionOption.Selected/DecisionRef written back to %s " + ...
    "(D-001: L presents the options, P decides).\n", logiName);
fprintf("R: the winning kinds Implement-link %s.\n", ...
    strjoin([DECISIONREQS{:,2}], ", "));

end

% =====================================================================
function out = collectCandidates(arch, prefix, profileName)
%COLLECTCANDIDATES Every component under ARCH that carries TradeCandidate.
%   Returns a struct array with one element per candidate: the component
%   handle, the variant component that owns it (empty if it is not a variant
%   choice) and that variant's path, its own architecture path and name, and
%   the three string/enum properties the trade groups and baselines by.
%
%   VARIANT-SAFE BY NECESSITY, NOT BY CAUTION. Every candidate in this model IS
%   a variant choice, and a variant's choices are reachable ONLY through
%   getChoices: .Architecture.Components returns them on a freshly built
%   in-memory model but ZERO on the same model saved and reloaded (Stage-0
%   finding 6). A recursion written the obvious way would therefore find no
%   candidates at all on the model as shipped, and this study would cheerfully
%   report that there was nothing to trade.
out = emptyCandidate();
for c = arch.Components
    if isa(c, "systemcomposer.arch.VariantComponent")
        vcPath = prefix + "/" + string(c.Name);
        for ch = getChoices(c)
            p = vcPath + "/" + string(ch.Name);
            out = [out, candidateAt(ch, c, vcPath, p, profileName)];        %#ok<AGROW>
            out = [out, collectCandidates(ch.Architecture, p, profileName)];%#ok<AGROW>
        end
    else
        p = prefix + "/" + string(c.Name);
        out = [out, candidateAt(c, [], "", p, profileName)];                %#ok<AGROW>
        out = [out, collectCandidates(c.Architecture, p, profileName)];     %#ok<AGROW>
    end
end
end

% =====================================================================
function out = candidateAt(comp, owner, ownerPath, pth, profileName)
%CANDIDATEAT A one-element candidate struct if COMP is one, else empty.
out = emptyCandidate();
applied = reshape(string(getStereotypes(comp)), 1, []);
if ~any(applied == profileName + ".TradeCandidate"); return; end
tc = profileName + ".TradeCandidate.";
out = struct( ...
    "Comp",       {comp}, ...
    "Owner",      {owner}, ...
    "OwnerPath",  ownerPath, ...
    "Path",       pth, ...
    "Name",       string(comp.Name), ...
    "Role",       readStr(comp, tc + "RealizesRole"), ...
    "Kind",       readStr(comp, tc + "RealizesKind"), ...
    "Provenance", readStr(comp, tc + "DataProvenance"));
end

% =====================================================================
function out = emptyCandidate()
%EMPTYCANDIDATE The 0x0 struct array collectCandidates accumulates into.
%   Field order must match candidateAt exactly, or the concatenation fails.
out = struct("Comp", {}, "Owner", {}, "OwnerPath", {}, "Path", {}, ...
    "Name", {}, "Role", {}, "Kind", {}, "Provenance", {});
end

% =====================================================================
function reqId = decisionRequirementFor(map, role)
%DECISIONREQUIREMENTFOR The requirement a role records its decision in.
idx = find([map{:,1}] == role, 1);
if isempty(idx)
    error("F16APhysicalTradeStudy:noDecisionRequirementForRole", ...
        "Role %s has trade candidates but no decision requirement. Candidates are " + ...
        "discovered, but the requirement a decision is recorded in cannot be: add " + ...
        "the role and its REQ id to DECISIONREQS, and add the requirement to " + ...
        "requirements/generate_f16a_logical_derived_requirements.m.", role);
end
reqId = string(map{idx,2});
end

% =====================================================================
function printRole(role, reqId, rc, refIdx, crit, keep, keptIdx, w, baseline, ...
    raw, V, score, rankOf, order)
%PRINTROLE The audit trail: every input, every value-function term, the score.
%   Printed wide on purpose. A trade study whose output is only "X won" is not
%   auditable; a reader has to be able to recompute the winner from the table.
n     = numel(rc);
nKept = numel(keptIdx);

fprintf("\n=== Trade: %s  (%d candidates, decision recorded in %s) ===\n", role, n, reqId);
fprintf("  baseline  : %s -- the role's DataProvenance = Reference candidate\n", rc(refIdx).Name);
for kk = 1:nKept
    k = keptIdx(kk);
    line = sprintf("  criterion : %-13s w = %.3f (declared %.2f, renormalized)   v = %s", ...
        crit(k).Name, w(kk), crit(k).Weight, crit(k).Rule);
    if contains(crit(k).Rule, "baseline")
        line = line + sprintf("   [baseline = %g]", baseline(k));
    end
    fprintf("%s\n", line);
end
for k = find(~keep)
    fprintf("  criterion : %-13s DROPPED -- no candidate of this role carries a value; " + ...
        "its declared weight %.2f is renormalized across the criteria that do (D-005).\n", ...
        crit(k).Name, crit(k).Weight);
end

hdr = pad("Candidate", 21) + " " + pad("Kind", 20);
for k = 1:numel(crit)
    hdr = hdr + " " + pad(shortLabel(crit(k).Name), 10, "left");
end
for kk = 1:nKept
    hdr = hdr + " " + pad("v(" + shortLabel(crit(keptIdx(kk)).Name) + ")", 12, "left");
end
hdr = hdr + " " + pad("Score", 9, "left") + " " + pad("Rank", 5, "left") + " " + ...
    pad("Sel", 4, "left");
fprintf("  %s\n", hdr);
fprintf("  %s\n", string(repmat('-', 1, strlength(hdr))));

for i = 1:n
    j = order(i);
    line = pad(rc(j).Name, 21) + " " + pad(rc(j).Kind, 20);
    for k = 1:numel(crit)
        line = line + " " + pad(sprintf("%g", raw(j,k)), 10, "left");
    end
    for kk = 1:nKept
        line = line + " " + pad(sprintf("%.4f", V(j,kk)), 12, "left");
    end
    mark = "";
    if rankOf(j) == 1; mark = "*"; end
    line = line + " " + pad(fmtScore(score(j)), 9, "left") + ...
        " " + pad(sprintf("%d", rankOf(j)), 5, "left") + " " + pad(mark, 4, "left");
    fprintf("  %s\n", line);
end

win = order(1);
rup = order(2);
[dName, dDelta] = decisiveCriterion(V, w, crit, keptIdx, win, rup);
fprintf("  -> SELECTED %s (kind %s), score %s, margin %s over %s; decided AGAINST " + ...
    "THAT RUNNER-UP by %s (%s).\n", ...
    rc(win).Name, rc(win).Kind, fmtScore(score(win)), ...
    fmtDelta(score(win) - score(rup)), rc(rup).Name, dName, fmtDelta(dDelta));
fprintf("     (decisiveness is measured against %s only -- a different rival can make a " + ...
    "different criterion decisive, so this is not a property of the decision as a " + ...
    "whole; D-034.)\n", rc(rup).Name);
end

% =====================================================================
function [name, delta] = decisiveCriterion(V, w, crit, keptIdx, win, other)
%DECISIVECRITERION The criterion carrying most of the winner's margin over ONE rival.
%   Weighted, because an unweighted comparison would credit a criterion the
%   trade barely cares about.
%
%   IT IS RIVAL-RELATIVE, AND EVERY CALLER MUST SAY SO (D-034). This answers
%   "what separated WIN from OTHER", not "what decided the trade". Callers pass
%   the rank-2 candidate, and the answer changes with the rival: the F100 beats
%   LowThrustSingle_Surrogate on TRL (+0.12500) but beats TwinEngine_Surrogate on Mass_lb (+0.06523,
%   ahead of TRL's +0.06250). Same winner, same scores, different "deciding"
%   criterion. So the printed line and the stored Justification both name the
%   runner-up rather than stating this as a property of the decision -- the
%   scores were never wrong here, the AUDIT TRAIL was, and the audit trail is
%   what this script exists to produce.
%
%   A rival-independent answer -- which criterion, if removed, would change the
%   winner -- is a genuine sensitivity calculation and is deferred rather than
%   faked (D-034).
d = w .* (V(win,:) - V(other,:));
[delta, kk] = max(d);
name = crit(keptIdx(kk)).Name;
end

% =====================================================================
% docs/04_logical.md claims the winner's Justification states the value functions
% and the weights it was scored on. This clause is the only thing that makes that
% true -- trim it there too, or not at all.
function txt = criteriaSentence(crit, keptIdx, w, dropped, refName)
%CRITERIASENTENCE The scoring scheme the model carries: functions, weights, baseline.
%   ONE SENTENCE. It states the scheme; it does not explain it. Why declared
%   value functions rather than min-max, and why a criterion nobody carries is
%   dropped and the rest renormalized, are D-015 and D-005 in
%   docs/07_decision_log.md -- cited, not restated (D-036's rule for numbers,
%   applied to prose).
parts = strings(1, numel(keptIdx));
for kk = 1:numel(keptIdx)
    k = keptIdx(kk);
    parts(kk) = crit(k).Name + " " + crit(k).Rule + " w=" + sprintf("%.3f", w(kk));
end
txt = "Criteria (D-015): " + strjoin(parts, "; ") + "; ratio baseline " + refName;
if ~isempty(dropped)
    txt = txt + "; " + strjoin(dropped, ", ") + " dropped, no values (D-005)";
end
txt = txt + ".";
end

% =====================================================================
function txt = winnerSentence(rc, win, rup, n, score, V, w, crit, keptIdx, ...
    critText, reqId, kindName)
%WINNERSENTENCE What the winner says about itself afterwards. Three sentences.
%   THE MARGIN IS DECOMPOSED INTO EVERY KEPT CRITERION, so the terms printed in
%   the sentence add up to the margin printed in the same sentence and a reader
%   can check it without re-running the trade. That closure is the property to
%   protect here: drop a term to shorten this and the sentence starts
%   contradicting itself. Naming the rival keeps the claim honest -- decisiveness
%   is rival-relative, and D-034 says why.
d = w .* (V(win,:) - V(rup,:));
dName = decisiveCriterion(V, w, crit, keptIdx, win, rup);
% Every kept criterion, in declared order (the order printRole's columns use).
% The "" excludes nothing: this is the whole decomposition, not a selection.
terms  = otherCriteria(d, crit, keptIdx, "", @(x) true);
trails = criteriaNamesWhere(d, crit, keptIdx, @(x) x < 0);

txt = "Trade study: SELECTED (rank 1 of " + n + "), score " + fmtScore(score(win)) + ...
    " against " + fmtScore(score(rup)) + " for runner-up " + rc(rup).Name + ", margin " + ...
    fmtDelta(score(win) - score(rup)) + " = " + terms + "; decided against that rival by " + ...
    dName;
if strlength(trails) > 0
    txt = txt + ", despite trailing it on " + trails;
end
txt = txt + ". " + critText + " Recorded in " + reqId + "; L active kind " + kindName + ".";
end

% =====================================================================
function txt = loserSentence(rc, i, win, n, score, rankOf, V, w, crit, keptIdx, ...
    critText, reqId)
%LOSERSENTENCE What a rejected candidate says about itself afterwards. Three sentences.
%   HOP 2 OF THE D-049 TRAIL, and the only place a rejected option's reasoning
%   exists anywhere: DecisionRef sends a losing kind to a requirement that poses
%   the question and holds no answer (D-040), so the trail ends at this string.
%   The deficit therefore DECOMPOSES INTO EVERY KEPT CRITERION and the printed
%   terms sum to the printed deficit -- drop one to shorten this and the single
%   artifact an auditor has stops adding up (D-002). Signs are this candidate's
%   own, it minus the winner, and the sentence says so: decomposed with the
%   WINNER's signs every term would flip and the total would still look right.
d = w .* (V(i,:) - V(win,:));
[~, kk] = min(d);
wName  = crit(keptIdx(kk)).Name;
% Same two calls, same reasons, as winnerSentence: the whole decomposition,
% then names only for the clause that follows it.
terms  = otherCriteria(d, crit, keptIdx, "", @(x) true);
leads  = criteriaNamesWhere(d, crit, keptIdx, @(x) x > 0);

txt = "Trade study: NOT SELECTED (rank " + rankOf(i) + " of " + n + "), score " + ...
    fmtScore(score(i)) + " against " + fmtScore(score(win)) + " for the selected " + ...
    rc(win).Name + ", deficit " + fmtDelta(score(i) - score(win)) + ...
    " (this candidate minus the winner) = " + terms + "; lost most on " + wName;
if strlength(leads) > 0
    txt = txt + ", though it leads the winner on " + leads;
end
txt = txt + ". " + critText + " Retained as the traded alternative (D-002); decision " + ...
    "recorded in " + reqId + ".";
end

% =====================================================================
function s = otherCriteria(d, crit, keptIdx, excludeName, test)
%OTHERCRITERIA "Mass_lb (+0.01813), Benefit (-0.02000)" for the criteria that pass TEST.
%   Pass excludeName = "" and a test of @(x) true to get the WHOLE
%   decomposition, which is what winnerSentence's margin closure needs.
parts = strings(1,0);
for kk = 1:numel(keptIdx)
    nm = crit(keptIdx(kk)).Name;
    if nm == excludeName || ~test(d(kk)); continue; end
    parts(end+1) = nm + " (" + fmtDelta(d(kk)) + ")";   %#ok<AGROW>
end
s = strjoin(parts, ", ");
end

% =====================================================================
function s = criteriaNamesWhere(d, crit, keptIdx, test)
%CRITERIANAMESWHERE "Benefit" -- the NAMES of the criteria whose delta passes TEST.
%   Names only, no numbers: winnerSentence has already printed every delta in
%   its margin decomposition, and reprinting one two clauses later is the
%   padding this file just spent a pass removing.
parts = strings(1,0);
for kk = 1:numel(keptIdx)
    if test(d(kk)); parts(end+1) = crit(keptIdx(kk)).Name; end   %#ok<AGROW>
end
s = strjoin(parts, ", ");
end

% =====================================================================
function base = standingRationale(comp, profileName, sentinel)
%STANDINGRATIONALE The part's own "why do I exist" text, minus any old verdict.
%   Everything before the sentinel is a verdict written by a previous run and is
%   discarded; everything after it is the rationale generate_f16a_physical.m
%   wrote and is carried through unchanged. That is what makes the rewrite
%   idempotent instead of cumulative.
%
%   THE UNQUOTE IS EXACT HERE, not the usual erase(..., "'"). A string property
%   reads back as the MATLAB expression that produced it: outer quotes, and any
%   internal apostrophe still doubled. Every other reader in this example only
%   DISPLAYS the text, so erasing all quotes costs nothing; this one WRITES IT
%   BACK, and a blanket erase would delete an apostrophe from the rationale on
%   every run -- a slow corruption that no test would notice.
raw = string(getProperty(comp, char(profileName + ".Rationale.Justification")));
if strlength(raw) >= 2 && startsWith(raw, "'") && endsWith(raw, "'")
    if strlength(raw) == 2
        raw = "";
    else
        raw = extractBetween(raw, 2, strlength(raw) - 1);
    end
end
base = replace(raw, "''", "'");
if contains(base, sentinel)
    base = extractAfter(base, sentinel);
end
end

% =====================================================================
function kindComp = writeLogicalDecision(lm, logiName, logiProfile, role, kindName, reqId)
%WRITELOGICALDECISION The cross-layer callback: tell L what P decided.
%   Returns the winning KIND's component handle, taken from getChoices rather
%   than from a path lookup, so the caller can Implement-link it without asking
%   lookup to cross a variant boundary on a loaded model.
%   Keyed on the KIND, not on the winning candidate name. The mapping is
%   many-to-one -- F100_PW_200 and LowThrustSingle_Surrogate both realize
%   SingleEngine -- so a
%   callback keyed on the candidate would fail to find its option the moment the
%   other single-engine candidate won, which is exactly when you would want it
%   to work.
%
%   DecisionRef is written to EVERY kind of the role, not only the winner
%   (D-027) -- it is the only outbound reference a rejected kind carries, so
%   without it that kind is a 'TBD' dead end. The requirement it points at is a
%   JUNCTION, NOT A TERMINUS: D-040 keeps REQ_F16A_L01..L03 pure questions, so
%   a rejected kind reaches the question and, one hop further, the rejected P
%   candidate realizing it, whose Justification holds the reasoning (D-049).
%   Caveat: that second hop is a property match (RealizesKind = the kind's
%   name), asserted by the P suite but not a link any tool can follow.
lvc = lookup(lm, Path=char(logiName + "/" + role));
if ~isa(lvc, "systemcomposer.arch.VariantComponent")
    error("F16APhysicalTradeStudy:logicalRoleNotVariant", ...
        "%s/%s is not a variant component, so it presents no options for P to " + ...
        "decide between.", logiName, role);
end
choices = getChoices(lvc);
names = strings(1, numel(choices));
for i = 1:numel(choices); names(i) = string(choices(i).Name); end
if ~any(names == kindName)
    error("F16APhysicalTradeStudy:noSuchKind", ...
        "The winning candidate realizes kind %s, but logical role %s offers only " + ...
        "{%s}. The physical candidates and the logical option set have drifted apart " + ...
        "-- one of the two is wrong.", kindName, role, strjoin(names, ", "));
end
setActiveChoice(lvc, kindName);
kindComp = choices(find(names == kindName, 1));
for i = 1:numel(choices)
    setProperty(choices(i), logiProfile + ".SolutionOption.Selected", ...
        string(names(i) == kindName));
    setProperty(choices(i), logiProfile + ".SolutionOption.DecisionRef", quoteLit(reqId));
end
end

% =====================================================================
function linkImplementOnce(srcComp, req, srcModelName)
%LINKIMPLEMENTONCE Implement-link SRCCOMP to REQ, exactly once, every run.
%   Rebuild rather than guard. Any existing inbound link whose source lives in
%   SRCMODELNAME is removed first, then one fresh link is created:
%     * re-running cannot accumulate duplicates;
%     * a re-run that picked a DIFFERENT winner cannot leave the previous
%       winner still linked, which a create-if-absent guard would;
%     * a manual "Verify" link from a test file is an inbound link too, but its
%       source artifact is the test, not the model, so it survives untouched --
%       the failure mode generate_f16a_physical.m records in linkImplement.
existing = req.inLinks();
for k = numel(existing):-1:1
    try
        s = source(existing(k));
        if contains(string(s.artifact), srcModelName)
            remove(existing(k));
        end
    catch
        % An unresolvable source cannot be attributed to this model, so leave
        % it alone: deleting a link we cannot identify would be worse than a
        % duplicate we can see.
    end
end
slreq.createLink(srcComp, req);
end

% =====================================================================
function saveLogicalLinkSets(logiName)
%SAVELOGICALLINKSETS Save only the F16A_Logical MODEL link set.
%   Same pattern (and same reason) as generate_f16a_logical.m: the functional
%   layer's link set must not be re-written by a run that did not change it.
%   The requirement-set link sets are left alone too -- they can hold MANUAL
%   Verify links that no generator should touch. Note that the match is
%   case-sensitive, so the lowercase f16a_logical_derived.slreqx link set is
%   not caught by it.
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), logiName)
        save(lnkSets(i));
    end
end
end

% =====================================================================
function x = readNum(comp, propName)
%READNUM A stereotype property as a double.
%   Strips the quotes a string/enum property reads back with (findings 1 and 7)
%   before converting, so one reader covers every property type. An unset
%   double property reads back the char 'NaN' and lands here as NaN, which is
%   how the cost column is recognized as empty rather than as zero.
x = str2double(erase(string(getProperty(comp, char(propName))), "'"));
end

% =====================================================================
function s = readStr(comp, propName)
%READSTR A string or enumeration stereotype property, unquoted.
s = erase(string(getProperty(comp, char(propName))), "'");
end

% =====================================================================
function s = quoteLit(txt)
%QUOTELIT Wrap a literal for a string-typed stereotype property.
%   A string property value is evaluated as a MATLAB expression, so the literal
%   must arrive quoted; an apostrophe inside it would close the literal early
%   and is doubled. Same helper, same reason, as generate_f16a_physical.m.
s = "'" + replace(string(txt), "'", "''") + "'";
end

% =====================================================================
function s = shortLabel(name)
%SHORTLABEL Column heading: "Mass_lb" -> "Mass", "UnitCost_USD" -> "UnitCost".
s = extractBefore(string(name) + "_", "_");
end

% =====================================================================
function s = fmtScore(x)
%FMTSCORE A score, five decimals.
%   Five, not four, on purpose: several of these scores land exactly on a
%   four-decimal rounding boundary (0.87875, 0.9125, 0.85625), so a four-decimal
%   print would show a last digit that depends on binary representation and
%   invite a reader to think the arithmetic had drifted. Five decimals states
%   the value exactly.
s = string(sprintf("%.5f", x));
end

% =====================================================================
function s = fmtDelta(x)
%FMTDELTA A signed margin or per-criterion contribution, five decimals.
%   Same precision as a score, because it lives in score units and has to add
%   up to one.
s = string(sprintf("%+.5f", x));
end
