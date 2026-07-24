function results = F16ALogicalTradeStudy()
%F16ALOGICALTRADESTUDY Trade and select among the F-16A logical options.
%   For each VARIANT role in logical/F16A_Logical.slx (a role with more than
%   one credible solution), this reads the TradeCandidate stereotype
%   properties of the competing choices, computes a weighted score, prints a
%   trade table, and SELECTS the winner by:
%     (1) setting it as the active variant choice   (in-model decision),
%     (2) setting its Selected stereotype flag true  (queryable),
%     (3) Implement-linking it to a decision requirement REQ_F16A_L0x
%         in f16a_logical_derived.slreqx             (traceable rationale).
%
%   This is the "options, plural -> pick one" teaching step of the Logical
%   layer. The alternatives are NOT deleted: they remain in the model as the
%   choices that were traded, so the decision stays auditable.
%
%   RESULTS = F16ALogicalTradeStudy() returns a containers.Map from role
%   name to a ranked table (Choice, Mass_lb, UnitCost_USD, TRL, Benefit,
%   Score, Rank, Selected), so tests can assert on the ranking directly.
%
%   Scoring: each criterion is min-max normalized across the choices of one
%   role; Benefit and TRL are more-is-better, Mass_lb and UnitCost_USD are
%   less-is-better; the weighted sum picks the winner. Weights and the
%   illustrative property values (set in generate_f16a_logical.m) are tuned
%   so the production-F-16A choice wins each trade -- but for a different
%   dominant reason each time.
%
%   Requires the L model, the trade profile, and the decision requirement
%   set to exist (run generate_f16a_logical.m, which itself calls this).

modelName   = "F16A_Logical";
profileName = "F16A_LogicalTrades";

thisDir  = fileparts(mfilename("fullpath"));
logiDir  = fullfile(thisDir, "logical");
reqDir   = fullfile(thisDir, "requirements");
modelFile= fullfile(logiDir, modelName + ".slx");
derFile  = fullfile(reqDir, "f16a_logical_derived.slreqx");
addpath(logiDir); addpath(reqDir);

m       = systemcomposer.loadModel(modelName);
derSet  = slreq.load(derFile);

% Weighted-score criteria (weights sum to 1). "hi" = more-is-better.
crit = struct( ...
    Benefit      = struct(w=0.40, hi=true), ...
    TRL          = struct(w=0.20, hi=true), ...
    Mass_lb      = struct(w=0.20, hi=false), ...
    UnitCost_USD = struct(w=0.20, hi=false));
props = ["Benefit","TRL","Mass_lb","UnitCost_USD"];

% {roleName, [choice names, production first], decisionRequirementId}
roles = {
    "PropulsionSystem",    ["SingleEngine_F100","TwinEngine_LWF"],       "REQ_F16A_L01";
    "FlightControlSystem", ["AnalogFBW","HydroMechanical"],              "REQ_F16A_L02";
    "Airframe",            ["BlendedCrankedDelta","ConventionalTrapWing"],"REQ_F16A_L03";
};

S = "F16A_Logical/";
results = containers.Map();

for i = 1:size(roles,1)
    role    = roles{i,1};
    choices = roles{i,2};
    lId     = roles{i,3};
    n = numel(choices);

    % Read the raw property matrix (rows = choices, cols = props).
    raw = zeros(n, numel(props));
    for r = 1:n
        c = lookup(m, Path=char(S + role + "/" + choices(r)));
        for p = 1:numel(props)
            raw(r,p) = readNum(c, profileName + ".TradeCandidate." + props(p));
        end
    end

    % Normalize each criterion and accumulate the weighted score.
    score = zeros(n,1);
    for p = 1:numel(props)
        col = raw(:,p);
        norm = minmax(col);                    % 0..1, more-is-better
        cinfo = crit.(props(p));
        if ~cinfo.hi; norm = 1 - norm; end     % flip less-is-better criteria
        score = score + cinfo.w * norm;
    end

    [~, order] = sort(score, "descend");
    rank = zeros(n,1); rank(order) = 1:n;
    winnerIdx  = order(1);
    winnerName = choices(winnerIdx);

    % Build the ranked table for this role.
    T = table(choices(:), raw(:,3), raw(:,4), raw(:,2), raw(:,1), score, rank, ...
        (rank==1), 'VariableNames', ...
        {'Choice','Mass_lb','UnitCost_USD','TRL','Benefit','Score','Rank','Selected'});
    T = sortrows(T, "Rank");
    results(char(role)) = T;

    % Print the trade table.
    fprintf("\n=== Trade: %s ===\n", role);
    disp(T);
    fprintf("Selected: %s (rank 1)\n", winnerName);

    % (1) active variant choice; (2) Selected stereotype flag.
    vc = lookup(m, Path=char(S + role));
    setActiveChoice(vc, winnerName);
    for r = 1:n
        c = lookup(m, Path=char(S + role + "/" + choices(r)));
        setProperty(c, profileName + ".TradeCandidate.Selected", ...
            string(r == winnerIdx));   % "true"/"false"
    end

    % (3) Implement-link the winner to its decision requirement (idempotent:
    %     only create if the requirement has no incoming link yet).
    req = find(derSet, Id=char(lId));
    if ~isempty(req) && isempty(req.inLinks())
        winnerComp = lookup(m, Path=char(S + role + "/" + winnerName));
        slreq.createLink(winnerComp, req);
    end
end

% Persist the selection (active choices, Selected flags) and the links.
save_system(modelName, char(modelFile));
save(derSet);
% Save only the F16A_Logical link set (leave the functional layer's untouched).
lnkSets = slreq.find(Type="LinkSet");
for i = 1:numel(lnkSets)
    if contains(string(lnkSets(i).Artifact), "F16A_Logical")
        save(lnkSets(i));
    end
end

fprintf("\nTrade study complete: %d roles traded and selected.\n", size(roles,1));

end

% =====================================================================
function x = readNum(comp, propName)
%READNUM Read a stereotype property as a double (handles string/char/num).
raw = getProperty(comp, propName);
x = str2double(string(raw));
end

% =====================================================================
function y = minmax(col)
%MINMAX Min-max normalize a column to 0..1; a flat column maps to 0.5.
lo = min(col); hi = max(col);
if hi > lo
    y = (col - lo) ./ (hi - lo);
else
    y = 0.5 * ones(size(col));
end
end
