function ranked = F16AAirframeTradeStudy(options)
%F16AAIRFRAMETRADESTUDY Select the F-16A airframe and record the decision in the model.
%   RANKED = F16AAIRFRAMETRADESTUDY() scores each candidate of the Airframe
%   variant on aerodynamic merit, mass and maturity, and selects the best
%   candidate. Then it records the decision in P, in L and against
%   REQ_F16A_L03. It prints each number that it reads and computes, so that
%   you can check the ranking by hand.
%
%   RANKED = F16AAIRFRAMETRADESTUDY(Record=false) stops after STEP 4. It
%   scores and ranks the candidates, but it writes nothing. F16ABaselineTest
%   uses this syntax.
%
%   RANKED is the scored table, with the best candidate first. Steps 1-4 are
%   in this file. Steps 5-6 record the decision. They are the same for all
%   trades, so they are in F16ARecordTradeDecision.
%
%   See also F16AENGINETRADESTUDY, F16AFLIGHTCONTROLSTRADESTUDY, F16ARUNANALYSES.

arguments
    options.Record (1,1) logical = true   % false: score and rank only
end

% ---------------------------------------------------------------------
% THE SUBJECT OF THIS TRADE: four names and a criteria table.
% ---------------------------------------------------------------------
trade = struct( ...
    "VariantPath", "F16A_Physical/Aircraft/Airframe", ...  % P: the candidates
    "LogicalRole", "Airframe", ...                         % L: the kinds
    "DecisionReq", "REQ_F16A_L03", ...                     % R: where the decision is recorded
    "Stereotype",  "AirframeCandidate");                   % the properties to score

% Each criterion uses a declared rule to change a raw property into a value
% v(raw, baseline). Thus the value of a candidate does not depend on the other
% candidates (D-015). Valid gives the usable range of a raw value. An unset
% property reads as 0. It must stop the trade. It must not get a score of zero
% (D-021). AeroBenefit is half of the score, so it has limits at both ends. A
% typing error of 65 for 6.5 is finite and positive (D-033). The ratio
% criterion (mass) has no upper limit, so STEP 3 gives a warning if its value
% is more than 1.0 (D-035).
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
prop = "F16A_PhysicalProps." + trade.Stereotype + ".";   % prefix of each property read below
fprintf("  F16A_Physical, variant %s\n", trade.VariantPath);

% =====================================================================
% STEP 2 -- READ THE CANDIDATES
% =====================================================================
fprintf("\n[STEP 2] READ THE CANDIDATES (stereotype %s)\n", trade.Stereotype);
% Use getChoices, not .Architecture.Components. On a saved model,
% .Architecture.Components returns no choices.
choices = getChoices(lookup(pm, Path=trade.VariantPath));
n = numel(choices);
names = strings(n,1); kinds = strings(n,1); provs = strings(n,1);
raw = nan(n, numel(crit));                       % one column per criterion
for i = 1:n
    c = choices(i);
    % Each choice is a candidate. A choice without the stereotype stops the
    % trade. The trade does not silently ignore it.
    if ~any(string(getStereotypes(c)) == "F16A_PhysicalProps." + trade.Stereotype)
        error("F16AAirframeTradeStudy:notStereotyped", ...
            "%s has no %s stereotype, so it has no numbers to score.", c.Name, trade.Stereotype);
    end
    names(i) = string(c.Name);
    kinds(i) = F16AKindOf(c);                    % the L kind that this candidate realizes
    provs(i) = readStr(c, prop + "DataProvenance");
    for k = 1:numel(crit)
        raw(i,k) = readNum(c, prop + crit(k).Name);
    end
    fprintf("  found %-24s kind %-22s %s  (%s)\n", names(i), kinds(i), ...
        strjoin(string({crit.Name}) + "=" + compose("%g", raw(i,:)), "  "), provs(i));
end

% Do not trade on numbers that are not reliable.
if n < 2
    error("F16AAirframeTradeStudy:tooFewCandidates", ...
        "%s has %d candidate(s). With only one option, there is no decision " + ...
        "to make.", trade.VariantPath, n);
end
for k = 1:numel(crit)
    for i = 1:n
        if ~isfinite(raw(i,k)) || ~crit(k).Valid(raw(i,k))
            error("F16AAirframeTradeStudy:badInput", "%s has %s = %g. The value must be %s.", ...
                names(i), crit(k).Name, raw(i,k), crit(k).Allowed);
        end
    end
end
% The ratio criterion divides by one reference candidate.
isRef = provs == "Reference";
if nnz(isRef) ~= 1
    error("F16AAirframeTradeStudy:baselineNotUnique", ...
        "%d candidates have the tag DataProvenance = Reference. The ratio criterion " + ...
        "needs exactly one baseline.", nnz(isRef));
end
baseline = raw(isRef, :);
fprintf("  baseline: %s, the only candidate with the tag DataProvenance = Reference\n", names(isRef));

% =====================================================================
% STEP 3 -- SCORE THE CANDIDATES
% =====================================================================
fprintf("\n[STEP 3] SCORE THE CANDIDATES\n");
w = [crit.Weight];
assert(abs(sum(w) - 1) < 1e-12, "The sum of the weights is %.6f, not 1.", sum(w));
V = zeros(n, numel(crit));                       % V(i,k): value of candidate i on criterion k
for k = 1:numel(crit)
    fprintf("  %-12s weight %.2f   v = %-14s (%s is better)\n", ...
        crit(k).Name, w(k), crit(k).Rule, crit(k).Better);
    for i = 1:n
        V(i,k) = crit(k).Value(raw(i,k), baseline(k));
    end
end
score = V * w(:);                                % the weighted sum
% The code does not cap or reject a value above 1.0. But that criterion then
% has more effect than its declared weight, and the reader should know this.
[iHi, kHi] = find(V > 1 + 1e-9);
for j = 1:numel(iHi)
    warning("F16AAirframeTradeStudy:valueAboveCeiling", ...
        "%s has v(%s) = %.5f > 1, so this criterion has more effect than its weight %.2f.", ...
        names(iHi(j)), crit(kHi(j)).Name, V(iHi(j),kHi(j)), w(kHi(j)));
end

% =====================================================================
% STEP 4 -- SELECT THE WINNER
% =====================================================================
fprintf("\n[STEP 4] SELECT THE WINNER\n");
[sorted, order] = sort(score, "descend");
if sorted(1) - sorted(2) <= 1e-9
    error("F16AAirframeTradeStudy:tie", "%s and %s have the same score, %.5f. " + ...
        "The data cannot make the decision.", names(order(1)), names(order(2)), sorted(1));
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

% The margin over the runner-up, divided by criterion. The sum of the terms is
% the margin.
margin = w .* (V(order(1),:) - V(order(2),:));
[~, kBest] = max(margin);
fprintf("  -> SELECTED %s (kind %s), score %.5f.\n", ...
    ranked.Candidate(1), ranked.Kind(1), ranked.Score(1));
fprintf("     Margin over %s: %+.5f = %s\n", ranked.Candidate(2), sorted(1) - sorted(2), ...
    strjoin(string({crit.Name}) + " (" + compose("%+.5f", margin) + ")", ", "));
fprintf("     Criterion that decided against that rival: %s.\n", crit(kBest).Name);

if options.Record
    F16ARecordTradeDecision(trade, crit, ranked);
end

end

% =====================================================================
function x = readNum(comp, propName)
%READNUM Read a stereotype property as a double (string and enumeration values read back with quotes).
x = str2double(erase(string(getProperty(comp, char(propName))), "'"));
end

function s = readStr(comp, propName)
%READSTR Read a string or enumeration stereotype property, without quotes.
s = erase(string(getProperty(comp, char(propName))), "'");
end
