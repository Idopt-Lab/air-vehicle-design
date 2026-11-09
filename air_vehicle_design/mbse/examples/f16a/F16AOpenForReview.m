function F16AOpenForReview()
%F16AOPENFORREVIEW Load the full F-16A RFLP model so that traceability is visible.
%   F16AOPENFORREVIEW() loads all four System Composer artifacts (three
%   architectures and the mission activity), all four requirement sets and
%   all verification link sets. Then it opens the Requirements Editor. Run
%   this function before you review requirements.
%
%   Why this is necessary: a link is stored in the link set of the artifact
%   that it starts from. It is never stored in the requirement set. An
%   "Implemented by" link is stored with the model, and a "Verified by" link
%   is stored with the test. Thus a requirement set that you open alone shows
%   neither link. The links appear when you load the models and the test link
%   sets. The models include the mission activity, whose actions implement
%   the mission-phase requirements.
%
%   The report at the end comes from the loaded artifacts. It lists the
%   requirements that have a Verify link, and each test that does not yet
%   have its Verify link, which you make by hand.

thisDir = f16aRoot();
vDir    = fullfile(thisDir,"verification");

% When you load a model, its requirement link set (the Implement links) also loads.
systemcomposer.loadModel("F16A_Functional");
systemcomposer.loadModel("F16A_Logical");
systemcomposer.loadModel("F16A_Physical");
% Use openActivity, not loadModel, to open an activity diagram.
systemcomposer.openActivity("F16A_MissionActivity");

% Load all requirement sets (the base set and the three derived sets).
reqFiles = ["f16a.slreqx","f16a_functional_derived.slreqx", ...
    "f16a_logical_derived.slreqx","f16a_physical_derived.slreqx"];
for f = reqFiles
    slreq.load(fullfile(thisDir,"requirements",f));
end

% Load the link sets of the tests. They hold the Verify links. Find them with a
% file pattern, because the link set of a test exists only after someone makes
% its Verify link by hand.
lnkSets = dir(fullfile(vDir,"*~m.slmx"));
for k = 1:numel(lnkSets)
    slreq.load(fullfile(lnkSets(k).folder, lnkSets(k).name));
end

fprintf("Loaded 3 architectures, the mission activity, %d requirement sets " + ...
    "and %d verification link set(s).\n", numel(reqFiles), numel(lnkSets));
reportVerifyLinks(vDir);

try slreq.editor(); catch, end   % open the editor only if a display is available

end

% =====================================================================
function reportVerifyLinks(vDir)
%REPORTVERIFYLINKS Print the requirements that have a Verify link, and the tests without one.
%   Both lists come from the loaded artifacts, not from a typed list that can
%   become out of date.
verified = strings(1,0);
reqs = slreq.find(Type="Requirement");
for i = 1:numel(reqs)
    try links = reqs(i).inLinks(); catch, links = []; end
    for j = 1:numel(links)
        if string(links(j).Type) == "Verify"
            verified(end+1) = string(reqs(i).Id);   %#ok<AGROW>
            break
        end
    end
end
if isempty(verified)
    fprintf("Verified by a test: none.\n");
else
    fprintf("Verified by a test: %s.\n", strjoin(sort(verified), ", "));
end

unlinked = strings(1,0);
tests = dir(fullfile(vDir,"*VerificationTest.m"));
for i = 1:numel(tests)
    [~, name] = fileparts(tests(i).name);
    if ~isfile(fullfile(vDir, name + "~m.slmx"))
        unlinked(end+1) = string(name);             %#ok<AGROW>
    end
end
if ~isempty(unlinked)
    fprintf("These tests have no link set on disk. Link them by hand in the " + ...
        "Requirements Editor: %s.\n", strjoin(sort(unlinked), ", "));
end
end
