function F16AOpenForReview()
%F16AOPENFORREVIEW Load the whole F-16A RFLP model so traceability is visible.
%   Loads all four System Composer artifacts (three architectures and the
%   mission activity), all four requirement sets and every verification link
%   set, then opens the Requirements Editor. Run this before reviewing
%   requirements.
%
%   WHY THIS IS NEEDED: a link lives in the link set of the artifact it points
%   FROM, never in the requirement set. An "Implemented by" link ships with the
%   MODEL and a "Verified by" link with the TEST, so a requirement set opened
%   on its own shows neither. Loading the models (including the mission
%   activity, whose actions implement the mission-phase requirements) and the
%   test link sets makes them appear.
%
%   The closing report is read from the artifacts: the requirements that carry
%   a Verify link, any test still waiting for one to be made by hand, and a
%   warning if a test file has CRLF line endings (its links would be off).

thisDir = f16aRoot();
vDir    = fullfile(thisDir,"verification");

% Loading a model loads its requirement link set (the Implement links).
systemcomposer.loadModel("F16A_Functional");
systemcomposer.loadModel("F16A_Logical");
systemcomposer.loadModel("F16A_Physical");
% An activity diagram is opened with openActivity, not loadModel.
systemcomposer.openActivity("F16A_MissionActivity");

% Load every requirement set (base + the three derived sets).
reqFiles = ["f16a.slreqx","f16a_functional_derived.slreqx", ...
    "f16a_logical_derived.slreqx","f16a_physical_derived.slreqx"];
for f = reqFiles
    slreq.load(fullfile(thisDir,"requirements",f));
end

% Load the TESTS' link sets -- the Verify links. Globbed, because a test's
% link set exists only once its Verify link has been made by hand.
lnkSets = dir(fullfile(vDir,"*~m.slmx"));
for k = 1:numel(lnkSets)
    slreq.load(fullfile(lnkSets(k).folder, lnkSets(k).name));
end

fprintf("Loaded 3 architectures + the mission activity, %d requirement sets, " + ...
    "%d verification link set(s).\n", numel(reqFiles), numel(lnkSets));
reportVerifyLinks(vDir);

try slreq.editor(); catch, end   % open the editor if a display is available

end

% =====================================================================
function reportVerifyLinks(vDir)
%REPORTVERIFYLINKS The requirements carrying a Verify link, and the tests without one.
%   Both are read from what is loaded, not from a typed list that would drift.
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
crlf     = strings(1,0);
tests = dir(fullfile(vDir,"*VerificationTest.m"));
for i = 1:numel(tests)
    [~, name] = fileparts(tests(i).name);
    if ~isfile(fullfile(vDir, name + "~m.slmx"))
        unlinked(end+1) = string(name);             %#ok<AGROW>
    end
    if any(fileread(fullfile(vDir, tests(i).name)) == char(13))
        crlf(end+1) = string(name);                 %#ok<AGROW>
    end
end
% A Verify link is a character offset into the test file, so CRLF line
% endings move it off its test method and runTests reports a false fail.
if ~isempty(crlf)
    warning("F16AOpenForReview:crlfTestFile", "CRLF line endings in %s, so " + ...
        "its Verify links point at the wrong lines. Restore LF: check that " + ...
        ".gitattributes has '*.m text eol=lf', delete the file and git " + ...
        "checkout it again.", strjoin(sort(crlf), ", "));
end
if ~isempty(unlinked)
    fprintf("Still to link BY HAND in the Requirements Editor: %s " + ...
        "(no link set on disk).\n", strjoin(sort(unlinked), ", "));
end
end
