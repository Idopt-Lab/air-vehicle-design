function ranked = F16AFlightControlsTradeStudy()
%F16AFLIGHTCONTROLSTRADESTUDY Choose the F-16A flight control system and record it.
%   RANKED = F16AFLIGHTCONTROLSTRADESTUDY() scores every choice of the
%   FlightControls variant on handling qualities, mass and maturity, picks the
%   best, and records that decision in the Physical model, the Logical model and
%   REQ_F16A_L02.
%
%   It runs as six printed steps -- open the models, read the candidates, score
%   them, pick the winner, tell the model, save -- and prints every number it
%   reads and every number it computes, so a reader can recompute the ranking by
%   hand from the output and check it.
%
%   RANKED is the scored table, best first. Re-running is idempotent.
%
%   ONE TRADE, ONE FILE, ONE STEREOTYPE (D-056). Its siblings are
%   F16AEngineTradeStudy and F16AAirframeTradeStudy; F16APhysicalTradeStudy runs
%   all three. Nothing here is shared with them on purpose: this file is meant to
%   be read straight through without opening another one.
%
%   Requires F16A_Physical.slx, F16A_Logical.slx and f16a_logical_derived.slreqx.

% ---------------------------------------------------------------------
% WHAT THIS TRADE IS ABOUT. Four names and a criteria table; the rest of the
% file is mechanics.
% ---------------------------------------------------------------------
VARIANTPATH = "F16A_Physical/Aircraft/FlightControls";   % the P variant holding the candidates
LOGICALROLE = "FlightControlSystem";                     % the L variant holding the kinds
DECISIONREQ = "REQ_F16A_L02";                            % where the decision is recorded
STEREOTYPE  = "FlightControlCandidate";                  % the properties this trade reads

% The criteria (D-015). Value is v(raw, baseline) -- a declared function, so a
% candidate's value does not depend on which rivals it happens to be up against.
% Rule is what gets printed and stored, so the model states its own scheme.
% HandlingBenefit carries half the score, which is why STEP 2 boxes it at BOTH
% ends: 90 typed for 9.0 is finite, so no isfinite check would catch it (D-033).
crit = struct( ...
    "Name",   {"HandlingBenefit",  "Mass_lb",       "TRL"}, ...
    "Weight", {0.50,               0.25,            0.25}, ...
    "Value",  {@(x,b) x/10,        @(x,b) b/x,      @(x,b) (x-1)/8}, ...
    "Rule",   {"B/10",             "M_baseline/M",  "(TRL-1)/8"}, ...
    "Better", {"better handling",  "less mass",     "more mature"});
nCrit = numel(crit);

profileName = "F16A_PhysicalProps";
physName    = "F16A_Physical";
logiName    = "F16A_Logical";
logiProfile = "F16A_LogicalOptions";
prop        = profileName + "." + STEREOTYPE + ".";   % every property this file reads
% Splits this run's verdict from the part's standing "why do I exist" rationale.
% It is what makes STEP 5 a rewrite instead of a pile-up.
SENTINEL    = " || ";

fprintf("\n==========================================================\n");
fprintf("  FLIGHT CONTROL TRADE STUDY\n");
fprintf("  Question: how should the F-16A be flown -- wires or rods?\n");
fprintf("  Answer recorded in: %s\n", DECISIONREQ);
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODELS
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODELS\n");

root     = f16aRoot();                       % the example root, via the anchor file
physFile = fullfile(root, "physical", physName + ".slx");
logiFile = fullfile(root, "logical",  logiName + ".slx");
derFile  = fullfile(root, "requirements", "f16a_logical_derived.slreqx");
addpath(fullfile(root, "physical"), fullfile(root, "logical"), fullfile(root, "requirements"));

if ~isfile(physFile)
    error("F16AFlightControlsTradeStudy:noPhysicalModel", ...
        "Missing %s. Run generate_f16a_physical first.", physFile);
end
if ~isfile(logiFile)
    error("F16AFlightControlsTradeStudy:noLogicalModel", ...
        "Missing %s. Run generate_f16a_logical first.", logiFile);
end
if ~isfile(derFile)
    error("F16AFlightControlsTradeStudy:noDecisionRequirements", ...
        "Missing %s. The trade has nowhere to record its decision without it.", derFile);
end

pm     = systemcomposer.loadModel(physName);   % where the candidates live
lm     = systemcomposer.loadModel(logiName);   % where the kinds live
derSet = slreq.load(derFile);                  % where the decision is recorded
% Load the L model's link set BEFORE any link is queried. STEP 5 checks for an
% existing link first, and an unloaded link set reads as "no links", which would
% quietly duplicate the decision link on every re-run. Guarded because a first
% run may have no link set yet.
try slreq.load(logiName); catch, end %#ok<CTCH>

fprintf("  P model      : %s\n", physName);
fprintf("  L model      : %s\n", logiName);
fprintf("  Requirements : %s\n", "f16a_logical_derived.slreqx");

% =====================================================================
% STEP 2 -- READ THE CANDIDATES AND THEIR NUMBERS
% =====================================================================
fprintf("\n[STEP 2] READ THE CANDIDATES\n");
fprintf("  Variant component : %s\n", VARIANTPATH);
fprintf("  Reading stereotype: %s.%s\n", profileName, STEREOTYPE);

vc = lookup(pm, Path=char(VARIANTPATH));
if ~isa(vc, "systemcomposer.arch.VariantComponent")
    error("F16AFlightControlsTradeStudy:notAVariant", ...
        "%s is not a variant component, so it offers nothing to choose between.", VARIANTPATH);
end
% getChoices, never vc.Architecture.Components: on a saved-and-reloaded model the
% latter returns ZERO choices, and this trade would report nothing to decide.
choices = getChoices(vc);
n = numel(choices);

names = strings(1,n); kinds = strings(1,n); provs = strings(1,n);
raw   = nan(n, nCrit);                       % columns follow crit, in order
for i = 1:n
    c = choices(i);
    % EVERY choice must carry the stereotype. This is what stops an option being
    % silently left out of its own trade: add a third control system to the
    % generator and it is scored here, or this run stops and names the missing one.
    applied = reshape(string(getStereotypes(c)), 1, []);
    if ~any(applied == profileName + "." + STEREOTYPE)
        error("F16AFlightControlsTradeStudy:candidateNotStereotyped", ...
            "Choice %s of %s does not carry %s.%s, so it has no numbers to be scored " + ...
            "on. Every choice of this variant is a candidate in this trade.", ...
            string(c.Name), VARIANTPATH, profileName, STEREOTYPE);
    end
    names(i) = string(c.Name);
    kinds(i) = readStr(c, prop + "RealizesKind");
    provs(i) = readStr(c, prop + "DataProvenance");
    for k = 1:nCrit
        raw(i,k) = readNum(c, prop + crit(k).Name);
    end
    fprintf("  found: %-18s kind=%-18s handling=%4.1f/10  mass=%7.2f lb  TRL=%d  (%s)\n", ...
        names(i), kinds(i), raw(i,1), raw(i,2), raw(i,3), provs(i));
end

% --- Refuse to trade on numbers that cannot be trusted ----------------
if n < 2
    error("F16AFlightControlsTradeStudy:tooFewCandidates", ...
        "%s has %d candidate(s). With one option there is nothing to decide, and " + ...
        "recording a 'winner' would claim a comparison that never happened.", VARIANTPATH, n);
end
for i = 1:n
    if ~isfinite(raw(i,1)) || raw(i,1) < 1 || raw(i,1) > 10
        error("F16AFlightControlsTradeStudy:badHandlingBenefit", ...
            "%s has HandlingBenefit = %g. It must be on the declared 1..10 scale; the " + ...
            "default 0 means 'not set'. It is bounded at BOTH ends because v = B/10 " + ...
            "carries half the score and 90 typed for 9.0 is finite (D-033).", ...
            names(i), raw(i,1));
    end
    if ~isfinite(raw(i,2)) || raw(i,2) <= 0
        error("F16AFlightControlsTradeStudy:badMass", ...
            "%s has Mass_lb = %g. It must be positive -- it is the DENOMINATOR of " + ...
            "M_baseline/M.", names(i), raw(i,2));
    end
    if ~isfinite(raw(i,3)) || mod(raw(i,3),1) ~= 0 || raw(i,3) < 1 || raw(i,3) > 9
        error("F16AFlightControlsTradeStudy:badTRL", ...
            "%s has TRL = %g. It must be a whole number on the 1..9 scale; the default " + ...
            "0 is the deliberate 'not set' sentinel and must stop the trade (D-021).", ...
            names(i), raw(i,3));
    end
end

% --- The baseline the ratio criterion divides by ----------------------
isRef = provs == "Reference";
if sum(isRef) ~= 1
    error("F16AFlightControlsTradeStudy:baselineNotUnique", ...
        "%d candidates are tagged DataProvenance = Reference; exactly one is required. " + ...
        "It is the baseline the ratio value function divides by, so with none there is " + ...
        "no scale and with two there is no answer to which one.", sum(isRef));
end
baseline = raw(isRef, :);
fprintf("  baseline    : %s -- the one candidate tagged DataProvenance = Reference\n", ...
    names(isRef));
fprintf("                mass %.2f lb. It scores exactly 1.0 on mass, by construction.\n", ...
    baseline(2));

% =====================================================================
% STEP 3 -- SCORE THEM
% =====================================================================
fprintf("\n[STEP 3] SCORE THEM\n");
w = [crit.Weight];
if abs(sum(w) - 1) > 1e-12
    error("F16AFlightControlsTradeStudy:weightsDoNotSumToOne", ...
        "The declared weights sum to %.6f, not 1. A weighted score whose weights do " + ...
        "not sum to one is not on the 0..1 scale it is printed on.", sum(w));
end
for k = 1:nCrit
    fprintf("  criterion : %-16s weight %.2f   v = %-14s (%s is better)\n", ...
        crit(k).Name, crit(k).Weight, crit(k).Rule, crit(k).Better);
end

V = zeros(n, nCrit);
for i = 1:n
    for k = 1:nCrit
        V(i,k) = crit(k).Value(raw(i,k), baseline(k));
    end
end
if any(~isfinite(V(:)))
    error("F16AFlightControlsTradeStudy:badValue", ...
        "A value function returned a non-finite result. Check the baseline and the " + ...
        "raw parameters printed above.");
end
score = V * w(:);

% A value above 1.0 WARNS -- it is not capped and not rejected (D-035). Only the
% unbounded ratio criterion can reach here; B/10 and (TRL-1)/8 are boxed by the
% range checks above. Capping would throw away a genuine advantage and erroring
% would reject a legitimate candidate; the honest option left is to say that the
% declared weights have stopped describing influence.
for i = 1:n
    for k = 1:nCrit
        if V(i,k) > 1 + 1e-9
            warning("F16AFlightControlsTradeStudy:valueAboveCeiling", ...
                "%s scores v(%s) = %.5f, above the 1.0 the other criteria cap at. " + ...
                "%s has no ceiling, so this candidate contributes more than its " + ...
                "declared weight of %.2f allows. Not capped, not rejected (D-035).", ...
                names(i), crit(k).Name, V(i,k), crit(k).Rule, crit(k).Weight);
        end
    end
end

% =====================================================================
% STEP 4 -- PICK THE WINNER
% =====================================================================
fprintf("\n[STEP 4] PICK THE WINNER\n");
[sorted, order] = sort(score, "descend");
if abs(sorted(1) - sorted(2)) <= 1e-9
    error("F16AFlightControlsTradeStudy:tie", ...
        "%s and %s tie for first at %.5f. A tie is a decision the data cannot make; " + ...
        "separate the candidates or add a criterion rather than breaking it by " + ...
        "position in a list.", names(order(1)), names(order(2)), sorted(1));
end
rankOf = zeros(n,1);
rankOf(order) = 1:n;
win = order(1);
rup = order(2);

printTable(names, kinds, crit, raw, V, score, rankOf, order);

% The margin decomposed into every criterion. The terms SUM to the margin, so a
% reader can add them up and check the result without re-running anything.
margin = w .* (V(win,:) - V(rup,:));
[~, kBest] = max(margin);
fprintf("\n  -> SELECTED %s (kind %s), score %.5f.\n", names(win), kinds(win), score(win));
fprintf("     Margin over the runner-up %s: %+.5f = %s\n", ...
    names(rup), score(win) - score(rup), terms(margin, crit));
fprintf("     Decided against THAT rival by %s. A different rival can make a different\n", ...
    crit(kBest).Name);
fprintf("     criterion decisive, so this is not a property of the decision (D-034).\n");

ranked = table(names.', kinds.', 'VariableNames', {'Candidate','Kind'});
for k = 1:nCrit
    ranked.(char(crit(k).Name)) = raw(:,k);
end
for k = 1:nCrit
    ranked.(char("v_" + crit(k).Name)) = V(:,k);
end
ranked.Score    = score;
ranked.Rank     = rankOf;
ranked.Selected = (rankOf == 1);
ranked = sortrows(ranked, "Rank");

% =====================================================================
% STEP 5 -- TELL THE MODEL WHAT WAS DECIDED
% =====================================================================
fprintf("\n[STEP 5] TELL THE MODEL WHAT WAS DECIDED\n");

% --- 5a) P: the configuration ----------------------------------------
setActiveChoice(vc, names(win));
for i = 1:n
    setProperty(choices(i), prop + "Selected", string(i == win));
end
fprintf("  P  active choice of %s set to %s; Selected written on all %d candidates.\n", ...
    VARIANTPATH, names(win), n);

% --- 5b) P: why, on every candidate ----------------------------------
% The loser's sentence matters most: it is the ONLY place a rejected option's
% reasoning exists anywhere in the model (D-049).
scheme = "Criteria (D-015): " + strjoin(string({crit.Name}) + " " + string({crit.Rule}) + ...
    " w=" + compose("%.2f", w), "; ") + "; ratio baseline " + names(isRef) + ".";
for i = 1:n
    if i == win
        sourceKind = "F16ASourceKind.TradeWinner";
        verdict = sprintf("Trade study: SELECTED (rank 1 of %d), score %.5f against " + ...
            "%.5f for runner-up %s, margin %+.5f = %s; decided against that rival by " + ...
            "%s. %s Recorded in %s; L active kind %s.", ...
            n, score(win), score(rup), names(rup), score(win) - score(rup), ...
            terms(margin, crit), crit(kBest).Name, scheme, DECISIONREQ, kinds(win));
    else
        sourceKind = "F16ASourceKind.TradeAlternative";
        deficit = w .* (V(i,:) - V(win,:));
        [~, kWorst] = min(deficit);
        verdict = sprintf("Trade study: NOT SELECTED (rank %d of %d), score %.5f " + ...
            "against %.5f for the selected %s, deficit %+.5f (this candidate minus " + ...
            "the winner) = %s; lost most on %s. %s Retained as the traded alternative " + ...
            "(D-002); decision recorded in %s.", ...
            rankOf(i), n, score(i), score(win), names(win), score(i) - score(win), ...
            terms(deficit, crit), crit(kWorst).Name, scheme, DECISIONREQ);
    end
    setProperty(choices(i), profileName + ".Rationale.SourceKind", sourceKind);
    setProperty(choices(i), profileName + ".Rationale.Justification", ...
        quoteLit(verdict + SENTINEL + standingRationale(choices(i), profileName, SENTINEL)));
end
fprintf("  P  Rationale rewritten on all %d: 1 TradeWinner, %d TradeAlternative.\n", n, n-1);

% --- 5c) L: the cross-layer callback ---------------------------------
% Keyed on the winner's KIND, never its name. Here the two happen to match, but
% the engine trade's do not, and the rule is one rule (D-027).
kindComp = writeLogicalDecision(lm, logiName, logiProfile, LOGICALROLE, kinds(win), DECISIONREQ);
fprintf("  L  active kind of %s/%s set to %s; Selected + DecisionRef on every kind.\n", ...
    logiName, LOGICALROLE, kinds(win));
fprintf("     DecisionRef goes on the REJECTED kinds too -- it is the only outbound\n");
fprintf("     reference they carry, and without it they are dead ends (D-027, D-049).\n");

% --- 5d) R: the traceability link ------------------------------------
req = find(derSet, Id=char(DECISIONREQ));
if isempty(req)
    error("F16AFlightControlsTradeStudy:missingRequirement", ...
        "Decision requirement %s is not in %s, so the decision has nowhere to be " + ...
        "recorded.", DECISIONREQ, derFile);
end
linkImplementOnce(kindComp, req, logiName);
fprintf("  R  Implement link created: %s (the winning KIND) -> %s.\n", kinds(win), DECISIONREQ);

% =====================================================================
% STEP 6 -- SAVE
% =====================================================================
fprintf("\n[STEP 6] SAVE\n");
save_system(physName, char(physFile));
save_system(logiName, char(logiFile));
save(derSet);
saveLogicalLinkSets(logiName);
fprintf("  Saved: %s.slx, %s.slx, f16a_logical_derived.slreqx and the L link set.\n", ...
    physName, logiName);
fprintf("  Nothing was deleted. The rejected control system stays in the model carrying\n");
fprintf("  a rationale saying what it lost on and by how much (D-002).\n\n");

end

% =====================================================================
function printTable(names, kinds, crit, raw, V, score, rankOf, order)
%PRINTTABLE The audit trail: every input, every value-function term, the score.
%   Printed wide on purpose. A trade study whose output is only "X won" is not
%   auditable; a reader has to be able to recompute the winner from this table.
hdr = pad("Candidate", 18) + " " + pad("Kind", 18);
for k = 1:numel(crit)
    hdr = hdr + " " + pad(crit(k).Name, 16, "left");
end
for k = 1:numel(crit)
    hdr = hdr + " " + pad("v(" + crit(k).Name + ")", 19, "left");
end
hdr = hdr + " " + pad("Score", 9, "left") + " " + pad("Rank", 5, "left");
fprintf("  %s\n", hdr);
fprintf("  %s\n", string(repmat('-', 1, strlength(hdr))));
for i = 1:numel(names)
    j = order(i);
    line = pad(names(j), 18) + " " + pad(kinds(j), 18);
    for k = 1:numel(crit)
        line = line + " " + pad(sprintf("%g", raw(j,k)), 16, "left");
    end
    for k = 1:numel(crit)
        line = line + " " + pad(sprintf("%.5f", V(j,k)), 19, "left");
    end
    line = line + " " + pad(sprintf("%.5f", score(j)), 9, "left") + ...
        " " + pad(sprintf("%d", rankOf(j)), 5, "left");
    fprintf("  %s\n", line);
end
end

% =====================================================================
function s = terms(d, crit)
%TERMS "HandlingBenefit (+0.15000), Mass_lb (+0.08127), TRL (-0.09375)".
%   EVERY criterion, never a selection: the printed terms must sum to the
%   printed margin, or the sentence starts contradicting itself.
s = strjoin(string({crit.Name}) + " (" + compose("%+.5f", d) + ")", ", ");
end

% =====================================================================
function kindComp = writeLogicalDecision(lm, logiName, logiProfile, role, kindName, reqId)
%WRITELOGICALDECISION Tell the Logical layer which kind the trade chose.
%   Returns the winning kind's component handle, taken from getChoices rather
%   than from a path lookup, so the caller can link it without asking lookup to
%   cross a variant boundary on a loaded model.
lvc = lookup(lm, Path=char(logiName + "/" + role));
if ~isa(lvc, "systemcomposer.arch.VariantComponent")
    error("F16AFlightControlsTradeStudy:logicalRoleNotVariant", ...
        "%s/%s is not a variant component, so it presents no options for P to " + ...
        "decide between.", logiName, role);
end
choices = getChoices(lvc);
names = strings(1, numel(choices));
for i = 1:numel(choices); names(i) = string(choices(i).Name); end
if ~any(names == kindName)
    error("F16AFlightControlsTradeStudy:noSuchKind", ...
        "The winning candidate realizes kind %s, but logical role %s offers only " + ...
        "{%s}. The physical candidates and the logical option set have drifted apart.", ...
        kindName, role, strjoin(names, ", "));
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
%   SRCMODELNAME is removed first, then one fresh link is created, so a re-run
%   cannot accumulate duplicates and a re-run that picked a DIFFERENT winner
%   cannot leave the previous winner still linked. A manual Verify link from a
%   test file is an inbound link too, but its source is the test rather than the
%   model, so it survives untouched.
existing = req.inLinks();
for k = numel(existing):-1:1
    try
        s = source(existing(k));
        if contains(string(s.artifact), srcModelName)
            remove(existing(k));
        end
    catch
        % A source we cannot resolve cannot be attributed to this model, so leave
        % it alone: deleting a link we cannot identify is worse than a duplicate
        % we can see.
    end
end
slreq.createLink(srcComp, req);
end

% =====================================================================
function saveLogicalLinkSets(logiName)
%SAVELOGICALLINKSETS Save only the F16A_Logical MODEL link set.
%   The functional layer's link set must not be re-written by a run that did not
%   change it, and the requirement-set link sets are left alone because they can
%   hold MANUAL Verify links no generator should touch. The match is
%   case-sensitive, so the lowercase f16a_logical_derived.slreqx link set is not
%   caught by it.
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), logiName)
        save(lnkSets(i));
    end
end
end

% =====================================================================
function base = standingRationale(comp, profileName, sentinel)
%STANDINGRATIONALE The part's own "why do I exist" text, minus any old verdict.
%   Everything before the sentinel was written by a previous run and is
%   discarded; everything after it is what the generator wrote and is carried
%   through unchanged. That is what makes the rewrite idempotent.
%
%   THE UNQUOTE IS EXACT HERE, not the usual erase(..., "'"). A string property
%   reads back as the MATLAB expression that produced it, with any internal
%   apostrophe still doubled -- and this reader WRITES IT BACK, so a blanket
%   erase would delete an apostrophe from the rationale on every run.
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
function x = readNum(comp, propName)
%READNUM A stereotype property as a double.
%   Strips the quotes a string or enum property reads back with before
%   converting, so one reader covers every property type.
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
%   must arrive quoted; an apostrophe inside it would close the literal early and
%   is doubled.
s = "'" + replace(string(txt), "'", "''") + "'";
end
