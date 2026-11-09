function F16ARecordTradeDecision(trade, crit, ranked)
%F16ARECORDTRADEDECISION Write the decision of a trade study into P, L and R.
%   F16ARECORDTRADEDECISION(TRADE, CRIT, RANKED) does steps 5 and 6 of each
%   trade study. TRADE gives the names of the variant, the logical role, the
%   decision requirement and the candidate stereotype. CRIT is the criteria
%   table. RANKED is the scored table, with the best candidate first. The
%   function records the decision in three places:
%     P  The winner becomes the active choice of the variant. Each candidate
%        gets Selected and a Rationale that gives its score and the reason.
%     L  The kind of the winner becomes the active choice of the logical role.
%        Each kind gets Selected and a DecisionRef to the requirement.
%     R  An Implement link from the winning kind to the decision requirement.
%   Then it saves the models. It deletes nothing. The losing candidates stay in
%   the model. Each one has a rationale that gives where it lost and by how
%   much (D-002).
%
%   See also F16AENGINETRADESTUDY, F16AAIRFRAMETRADESTUDY, F16AFLIGHTCONTROLSTRADESTUDY.

PROFILE  = "F16A_PhysicalProps";
LPROFILE = "F16A_LogicalOptions";
SENTINEL = " || ";   % separates the verdict of this run from the standing rationale of the part

fprintf("\n[STEP 5] RECORD THE DECISION\n");
pm     = systemcomposer.loadModel("F16A_Physical");
lm     = systemcomposer.loadModel("F16A_Logical");
derSet = slreq.load(fullfile(f16aRoot(), "requirements", "f16a_logical_derived.slreqx"));
% Load the L link set before you look for an existing decision link. An
% unloaded link set reads as "no links", and then each run would duplicate
% the link.
try slreq.load("F16A_Logical"); catch, end %#ok<CTCH>

names  = ranked.Candidate;
n      = numel(names);
w      = [crit.Weight];
V      = ranked{:, "v_" + string({crit.Name})};
score  = ranked.Score;
margin = w .* (V(1,:) - V(2,:));            % winner minus runner-up, per criterion
[~, kBest] = max(margin);
scheme = "Criteria (D-015): " + strjoin(string({crit.Name}) + " " + string({crit.Rule}) + ...
    " w=" + compose("%.2f", w), ", ") + ". Ratio baseline: " + names(ranked.Baseline) + ".";

% --- P: the configuration, and the reason, on each candidate -------------
vc = lookup(pm, Path=trade.VariantPath);
setActiveChoice(vc, names(1));
for c = reshape(getChoices(vc), 1, [])
    i = find(names == string(c.Name));
    if i == 1
        sourceKind = "F16ASourceKind.TradeWinner";
        verdict = sprintf("Trade study: SELECTED (rank 1 of %d). Score %.5f, against " + ...
            "%.5f for the runner-up %s. Margin %+.5f = %s. Criterion that decided " + ...
            "against that rival: %s. %s Recorded in %s. Active kind in L: %s.", ...
            n, score(1), score(2), names(2), score(1) - score(2), terms(margin, crit), ...
            crit(kBest).Name, scheme, trade.DecisionReq, ranked.Kind(1));
    else
        sourceKind = "F16ASourceKind.TradeAlternative";
        deficit = w .* (V(i,:) - V(1,:));
        [~, kWorst] = min(deficit);
        verdict = sprintf("Trade study: NOT SELECTED (rank %d of %d). Score %.5f, " + ...
            "against %.5f for the selected %s. Deficit %+.5f (this candidate minus " + ...
            "the winner) = %s. Criterion with the largest loss: %s. %s Kept as the " + ...
            "traded alternative (D-002). Decision recorded in %s.", ...
            i, n, score(i), score(1), names(1), score(i) - score(1), ...
            terms(deficit, crit), crit(kWorst).Name, scheme, trade.DecisionReq);
    end
    setProperty(c, PROFILE + "." + trade.Stereotype + ".Selected", string(i == 1));
    setProperty(c, PROFILE + ".Rationale.SourceKind", sourceKind);
    setProperty(c, PROFILE + ".Rationale.Justification", ...
        quoteLit(verdict + SENTINEL + standingRationale(c, PROFILE, SENTINEL)));
end
fprintf("  P  %s -> %s. Selected and Rationale written on all %d candidates.\n", ...
    trade.VariantPath, names(1), n);

% --- L: the winning kind, never the candidate name ------------------------
lvc   = lookup(lm, Path="F16A_Logical/" + trade.LogicalRole);
kinds = reshape(getChoices(lvc), 1, []);
kindNames = string({kinds.Name});
winKind   = ranked.Kind(1);
if ~any(kindNames == winKind)
    error("F16ARecordTradeDecision:noSuchKind", ...
        "The winner realizes kind %s, but logical role %s has only these kinds: {%s}.", ...
        winKind, trade.LogicalRole, strjoin(kindNames, ", "));
end
setActiveChoice(lvc, winKind);
for k = 1:numel(kinds)
    setProperty(kinds(k), LPROFILE + ".SolutionOption.Selected", string(kindNames(k) == winKind));
    setProperty(kinds(k), LPROFILE + ".SolutionOption.DecisionRef", quoteLit(trade.DecisionReq));
end
fprintf("  L  F16A_Logical/%s -> %s. Selected and DecisionRef written on each kind.\n", ...
    trade.LogicalRole, winKind);

% --- R: the traceability link ---------------------------------------------
req = find(derSet, Id=char(trade.DecisionReq));
linkImplementOnce(kinds(kindNames == winKind), req, "F16A_Logical");
fprintf("  R  Implement link: %s -> %s.\n", winKind, trade.DecisionReq);

fprintf("\n[STEP 6] SAVE\n");
save_system("F16A_Physical");
save_system("F16A_Logical");
save(derSet);
% Save only the link set of the L model. The case-sensitive match does not
% touch the link sets of the requirement sets, which hold the manual Verify
% links.
for ls = reshape(slreq.find(Type="LinkSet"), 1, [])
    if contains(string(ls.Artifact), "F16A_Logical"); save(ls); end
end
fprintf("  Saved F16A_Physical, F16A_Logical, f16a_logical_derived and the L link set.\n\n");

end

% =====================================================================
function s = terms(d, crit)
%TERMS Format the term of each criterion, for example "Mass_lb (+0.09132), TRL (+0.08750), ...".
%   The text includes all criteria, so the sum of the printed terms is always
%   the printed margin.
s = strjoin(string({crit.Name}) + " (" + compose("%+.5f", d) + ")", ", ");
end

function linkImplementOnce(srcComp, req, srcModelName)
%LINKIMPLEMENTONCE Remove the old links from this model into REQ, then make one link.
%   Thus a new run cannot make duplicate links. A new run with a different
%   winner cannot leave the old winner linked. Verify links come from test
%   files, not from this model, so this function does not change them.
existing = req.inLinks();
for k = numel(existing):-1:1
    try
        src = source(existing(k));
        if contains(string(src.artifact), srcModelName)
            remove(existing(k));
        end
    catch %#ok<CTCH> do not delete a link whose source cannot be resolved
    end
end
slreq.createLink(srcComp, req);
end

function base = standingRationale(comp, profile, sentinel)
%STANDINGRATIONALE Return the "why do I exist" text of the part, without an old verdict.
%   A string property reads back with quotes, and with each inner apostrophe
%   doubled. This text is written back, so remove the quotes exactly. Do not
%   use erase(.., "'").
raw = string(getProperty(comp, char(profile + ".Rationale.Justification")));
if strlength(raw) >= 2 && startsWith(raw, "'") && endsWith(raw, "'")
    raw = extractAfter(extractBefore(raw, strlength(raw)), 1);   % remove the outer quotes
end
base = replace(raw, "''", "'");
if contains(base, sentinel)
    base = extractAfter(base, sentinel);
end
end

function s = quoteLit(txt)
%QUOTELIT Make a literal for a string stereotype property (the property value is evaluated).
s = "'" + replace(string(txt), "'", "''") + "'";
end
