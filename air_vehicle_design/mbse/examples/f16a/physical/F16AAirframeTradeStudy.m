function ranked = F16AAirframeTradeStudy(options)
%F16AAIRFRAMETRADESTUDY Choose the F-16A airframe and record the choice in the model.
%   RANKED = F16AAIRFRAMETRADESTUDY() scores every candidate of the Airframe
%   variant on aerodynamic merit, mass and maturity, picks the best, and
%   records the decision in P, in L and against REQ_F16A_L03. It prints every number it
%   reads and computes, so the ranking can be checked by hand.
%
%   RANKED = F16AAIRFRAMETRADESTUDY(Record=false) stops after STEP 4: it scores
%   and ranks but writes nothing (F16ABaselineTest runs it so).
%
%   RANKED is the scored table, best first. Steps 1-4 are in this file. Steps
%   5-6, recording the decision, are the same for every trade and live in
%   F16ARecordTradeDecision.
%
%   See also F16AAIRFRAMETRADESTUDY, F16AFLIGHTCONTROLSTRADESTUDY, F16ARUNANALYSES.

arguments
    options.Record (1,1) logical = true   % false: score and rank only
end

% ---------------------------------------------------------------------
% WHAT THIS TRADE IS ABOUT: four names and a criteria table.
% ---------------------------------------------------------------------
trade = struct( ...
    "VariantPath", "F16A_Physical/Aircraft/Airframe", ...  % P: the candidates
    "LogicalRole", "Airframe", ...                         % L: the kinds
    "DecisionReq", "REQ_F16A_L03", ...                     % R: where it is recorded
    "Stereotype",  "AirframeCandidate");                   % the properties scored

% Each criterion turns a raw property into a value v(raw, baseline) by a
% declared rule, so a candidate's value does not depend on which rivals it
% faces (D-015). Valid says what a usable raw value is: an unset property
% reads as 0 and must stop the trade, not score as zero (D-021). AeroBenefit
% carries half the score, so it is boxed at BOTH ends: 65 typed for 6.5 is
% finite and positive (D-033). The ratio criterion (mass) has no ceiling, so
% STEP 3 warns if it passes 1.0 (D-035).
crit = struct( ...
    "Name",    {"AeroBenefit",          "Mass_lb",       "TRL"}, ...
    "Weight",  {0.50,                   0.25,            0.25}, ...
    "Value",   {@(x,b) x/10,            @(x,b) b/x,      @(x,b) (x-1)/8}, ...
    "Rule",    {"B/10",                 "M_baseline/M",  "(TRL-1)/8"}, ...
    "Better",  {"better aero",          "less mass",     "more mature"}, ...
    "Valid",   {@(x) x >= 1 && x <= 10, @(x) x > 0,      @(x) ismember(x, 1:9)}, ...
    "Allowed", {"on the 1..10 scale",   "> 0",           "a whole number 1..9"});

fprintf("\n==========================================================\n");
fprintf("  AIRFRAME TRADE STUDY\n");
fprintf("  Question: what shape of airframe should the F-16A have?\n");
fprintf("  Answer recorded in: %s\n", trade.DecisionReq);
fprintf("==========================================================\n");

% =====================================================================
% STEP 1 -- OPEN THE MODEL
% =====================================================================
fprintf("\n[STEP 1] OPEN THE MODEL\n");
pm   = systemcomposer.loadModel("F16A_Physical");
prop = "F16A_PhysicalProps." + trade.Stereotype + ".";   % every property read below
fprintf("  F16A_Physical, variant %s\n", trade.VariantPath);

% =====================================================================
% STEP 2 -- READ THE CANDIDATES
% =====================================================================
fprintf("\n[STEP 2] READ THE CANDIDATES (stereotype %s)\n", trade.Stereotype);
% getChoices, not .Architecture.Components: on a saved model the latter
% returns no choices at all.
choices = getChoices(lookup(pm, Path=trade.VariantPath));
n = numel(choices);
names = strings(n,1); kinds = strings(n,1); provs = strings(n,1);
raw = nan(n, numel(crit));                       % one column per criterion
for i = 1:n
    c = choices(i);
    % Every choice is a candidate: one without the stereotype stops the trade
    % instead of being silently left out of it.
    if ~any(string(getStereotypes(c)) == "F16A_PhysicalProps." + trade.Stereotype)
        error("F16AAirframeTradeStudy:notStereotyped", ...
            "%s carries no %s, so it has no numbers to be scored on.", c.Name, trade.Stereotype);
    end
    names(i) = string(c.Name);
    kinds(i) = F16AKindOf(c);                    % the L kind this candidate realizes
    provs(i) = readStr(c, prop + "DataProvenance");
    for k = 1:numel(crit)
        raw(i,k) = readNum(c, prop + crit(k).Name);
    end
    fprintf("  found %-24s kind %-22s %s  (%s)\n", names(i), kinds(i), ...
        strjoin(string({crit.Name}) + "=" + compose("%g", raw(i,:)), "  "), provs(i));
end

% Refuse to trade on numbers that cannot be trusted.
if n < 2
    error("F16AAirframeTradeStudy:tooFewCandidates", ...
        "%s has %d candidate(s): with one option there is nothing to decide.", trade.VariantPath, n);
end
for k = 1:numel(crit)
    for i = 1:n
        if ~isfinite(raw(i,k)) || ~crit(k).Valid(raw(i,k))
            error("F16AAirframeTradeStudy:badInput", "%s has %s = %g; it must be %s.", ...
                names(i), crit(k).Name, raw(i,k), crit(k).Allowed);
        end
    end
end
% The ratio criterion divides by ONE reference candidate.
isRef = provs == "Reference";
if nnz(isRef) ~= 1
    error("F16AAirframeTradeStudy:baselineNotUnique", ...
        "%d candidates are tagged DataProvenance = Reference; the ratio criterion " + ...
        "needs exactly one baseline.", nnz(isRef));
end
baseline = raw(isRef, :);
fprintf("  baseline: %s, the one candidate tagged DataProvenance = Reference\n", names(isRef));

% =====================================================================
% STEP 3 -- SCORE THEM
% =====================================================================
fprintf("\n[STEP 3] SCORE THEM\n");
w = [crit.Weight];
assert(abs(sum(w) - 1) < 1e-12, "The weights sum to %.6f, not 1.", sum(w));
V = zeros(n, numel(crit));                       % V(i,k): value of candidate i on criterion k
for k = 1:numel(crit)
    fprintf("  %-12s weight %.2f   v = %-14s (%s is better)\n", ...
        crit(k).Name, w(k), crit(k).Rule, crit(k).Better);
    for i = 1:n
        V(i,k) = crit(k).Value(raw(i,k), baseline(k));
    end
end
score = V * w(:);                                % the weighted sum
% A value above 1.0 is neither capped nor rejected, but that criterion now
% counts for more than its declared weight, which the reader should know.
[iHi, kHi] = find(V > 1 + 1e-9);
for j = 1:numel(iHi)
    warning("F16AAirframeTradeStudy:valueAboveCeiling", ...
        "%s scores v(%s) = %.5f > 1, so it counts for more than weight %.2f.", ...
        names(iHi(j)), crit(kHi(j)).Name, V(iHi(j),kHi(j)), w(kHi(j)));
end

% =====================================================================
% STEP 4 -- PICK THE WINNER
% =====================================================================
fprintf("\n[STEP 4] PICK THE WINNER\n");
[sorted, order] = sort(score, "descend");
if sorted(1) - sorted(2) <= 1e-9
    error("F16AAirframeTradeStudy:tie", "%s and %s tie at %.5f: the data cannot decide.", ...
        names(order(1)), names(order(2)), sorted(1));
end
ranked = table(names, kinds, VariableNames=["Candidate", "Kind"]);
for k = 1:numel(crit)
    ranked.(crit(k).Name) = raw(:,k);
end
for k = 1:numel(crit)
    ranked.("v_" + crit(k).Name) = V(:,k);
end
ranked.Score    = score;
ranked.Baseline = isRef;
ranked = ranked(order, :);
ranked.Rank = (1:n).';
disp(ranked)

% The margin over the runner-up, split by criterion: the terms sum to it.
margin = w .* (V(order(1),:) - V(order(2),:));
[~, kBest] = max(margin);
fprintf("  -> SELECTED %s (kind %s), score %.5f.\n", ...
    ranked.Candidate(1), ranked.Kind(1), ranked.Score(1));
fprintf("     Margin over %s: %+.5f = %s\n", ranked.Candidate(2), sorted(1) - sorted(2), ...
    strjoin(string({crit.Name}) + " (" + compose("%+.5f", margin) + ")", ", "));
fprintf("     Decided against that rival by %s.\n", crit(kBest).Name);

if options.Record
    F16ARecordTradeDecision(trade, crit, ranked);
end

end

% =====================================================================
function x = readNum(comp, propName)
%READNUM A stereotype property as a double (string and enum values read back quoted).
x = str2double(erase(string(getProperty(comp, char(propName))), "'"));
end

function s = readStr(comp, propName)
%READSTR A string or enumeration stereotype property, unquoted.
s = erase(string(getProperty(comp, char(propName))), "'");
end
