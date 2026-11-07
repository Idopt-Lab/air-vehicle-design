function F16ARecordTradeDecision(trade, crit, ranked)
%F16ARECORDTRADEDECISION Write a trade study's decision into P, L and R.
%   F16ARECORDTRADEDECISION(TRADE, CRIT, RANKED) is steps 5 and 6 of every
%   trade study. TRADE names the variant, logical role, decision requirement
%   and candidate stereotype; CRIT is the criteria table; RANKED is the scored
%   table, best first. It records the decision in three places:
%     P  the winner becomes the variant's active choice, and every candidate
%        gets Selected and a Rationale saying how it scored and why;
%     L  the winner's KIND becomes the logical role's active choice, and every
%        kind gets Selected and a DecisionRef to the requirement;
%     R  an Implement link from the winning kind to the decision requirement.
%   Then it saves. Nothing is deleted: the losing candidates stay in the model,
%   each with a rationale saying what it lost on and by how much (D-002).
%
%   See also F16AENGINETRADESTUDY, F16AAIRFRAMETRADESTUDY, F16AFLIGHTCONTROLSTRADESTUDY.

PROFILE  = "F16A_PhysicalProps";
LPROFILE = "F16A_LogicalOptions";
SENTINEL = " || ";   % separates this run's verdict from the part's standing rationale

fprintf("\n[STEP 5] RECORD THE DECISION\n");
pm     = systemcomposer.loadModel("F16A_Physical");
lm     = systemcomposer.loadModel("F16A_Logical");
derSet = slreq.load(fullfile(f16aRoot(), "requirements", "f16a_logical_derived.slreqx"));
% Load the L link set BEFORE looking for an existing decision link: an unloaded
% link set reads as "no links", and the link would be duplicated on every run.
try slreq.load("F16A_Logical"); catch, end %#ok<CTCH>

names  = ranked.Candidate;
n      = numel(names);
w      = [crit.Weight];
V      = ranked{:, "v_" + string({crit.Name})};
score  = ranked.Score;
margin = w .* (V(1,:) - V(2,:));            % winner minus runner-up, per criterion
[~, kBest] = max(margin);
scheme = "Criteria (D-015): " + strjoin(string({crit.Name}) + " " + string({crit.Rule}) + ...
    " w=" + compose("%.2f", w), "; ") + "; ratio baseline " + names(ranked.Baseline) + ".";

% --- P: the configuration, and why, on every candidate -------------------
vc = lookup(pm, Path=trade.VariantPath);
setActiveChoice(vc, names(1));
for c = reshape(getChoices(vc), 1, [])
    i = find(names == string(c.Name));
    if i == 1
        sourceKind = "F16ASourceKind.TradeWinner";
        verdict = sprintf("Trade study: SELECTED (rank 1 of %d), score %.5f against " + ...
            "%.5f for runner-up %s, margin %+.5f = %s; decided against that rival by " + ...
            "%s. %s Recorded in %s; L active kind %s.", ...
            n, score(1), score(2), names(2), score(1) - score(2), terms(margin, crit), ...
            crit(kBest).Name, scheme, trade.DecisionReq, ranked.Kind(1));
    else
        sourceKind = "F16ASourceKind.TradeAlternative";
        deficit = w .* (V(i,:) - V(1,:));
        [~, kWorst] = min(deficit);
        verdict = sprintf("Trade study: NOT SELECTED (rank %d of %d), score %.5f " + ...
            "against %.5f for the selected %s, deficit %+.5f (this candidate minus " + ...
            "the winner) = %s; lost most on %s. %s Retained as the traded alternative " + ...
            "(D-002); decision recorded in %s.", ...
            i, n, score(i), score(1), names(1), score(i) - score(1), ...
            terms(deficit, crit), crit(kWorst).Name, scheme, trade.DecisionReq);
    end
    setProperty(c, PROFILE + "." + trade.Stereotype + ".Selected", string(i == 1));
    setProperty(c, PROFILE + ".Rationale.SourceKind", sourceKind);
    setProperty(c, PROFILE + ".Rationale.Justification", ...
        quoteLit(verdict + SENTINEL + standingRationale(c, PROFILE, SENTINEL)));
end
fprintf("  P  %s -> %s; Selected and Rationale written on all %d candidates.\n", ...
    trade.VariantPath, names(1), n);

% --- L: the winning KIND, never the candidate name ------------------------
lvc   = lookup(lm, Path="F16A_Logical/" + trade.LogicalRole);
kinds = reshape(getChoices(lvc), 1, []);
kindNames = string({kinds.Name});
winKind   = ranked.Kind(1);
if ~any(kindNames == winKind)
    error("F16ARecordTradeDecision:noSuchKind", ...
        "The winner realizes kind %s, but logical role %s offers only {%s}.", ...
        winKind, trade.LogicalRole, strjoin(kindNames, ", "));
end
setActiveChoice(lvc, winKind);
for k = 1:numel(kinds)
    setProperty(kinds(k), LPROFILE + ".SolutionOption.Selected", string(kindNames(k) == winKind));
    setProperty(kinds(k), LPROFILE + ".SolutionOption.DecisionRef", quoteLit(trade.DecisionReq));
end
fprintf("  L  F16A_Logical/%s -> %s; Selected and DecisionRef written on every kind.\n", ...
    trade.LogicalRole, winKind);

% --- R: the traceability link ---------------------------------------------
req = find(derSet, Id=char(trade.DecisionReq));
linkImplementOnce(kinds(kindNames == winKind), req, "F16A_Logical");
fprintf("  R  Implement link: %s -> %s.\n", winKind, trade.DecisionReq);

fprintf("\n[STEP 6] SAVE\n");
save_system("F16A_Physical");
save_system("F16A_Logical");
save(derSet);
% Only the L model's link set. The case-sensitive match leaves the
% requirement sets' link sets, which hold the manual Verify links, alone.
for ls = reshape(slreq.find(Type="LinkSet"), 1, [])
    if contains(string(ls.Artifact), "F16A_Logical"); save(ls); end
end
fprintf("  Saved F16A_Physical, F16A_Logical, f16a_logical_derived and the L link set.\n\n");

end

% =====================================================================
function s = terms(d, crit)
%TERMS "Mass_lb (+0.09132), TRL (+0.08750), ..." -- every criterion, so the
%   printed terms always sum to the printed margin.
s = strjoin(string({crit.Name}) + " (" + compose("%+.5f", d) + ")", ", ");
end

function linkImplementOnce(srcComp, req, srcModelName)
%LINKIMPLEMENTONCE Remove this model's old links into REQ, then link once.
%   A re-run cannot pile up duplicates, and a re-run with a different winner
%   cannot leave the old one linked. Verify links come from test files, not
%   this model, so they are untouched.
existing = req.inLinks();
for k = numel(existing):-1:1
    try
        src = source(existing(k));
        if contains(string(src.artifact), srcModelName)
            remove(existing(k));
        end
    catch %#ok<CTCH> an unresolvable source is not ours to delete
    end
end
slreq.createLink(srcComp, req);
end

function base = standingRationale(comp, profile, sentinel)
%STANDINGRATIONALE The part's own "why do I exist" text, minus an old verdict.
%   A string property reads back quoted, with inner apostrophes doubled, and
%   this text is written back -- so unquote exactly, not with erase(.., "'").
raw = string(getProperty(comp, char(profile + ".Rationale.Justification")));
if strlength(raw) >= 2 && startsWith(raw, "'") && endsWith(raw, "'")
    raw = extractAfter(extractBefore(raw, strlength(raw)), 1);   % drop the outer quotes
end
base = replace(raw, "''", "'");
if contains(base, sentinel)
    base = extractAfter(base, sentinel);
end
end

function s = quoteLit(txt)
%QUOTELIT A literal for a string stereotype property (its value is evaluated).
s = "'" + replace(string(txt), "'", "''") + "'";
end
