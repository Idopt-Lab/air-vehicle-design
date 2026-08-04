function F16AOpenForReview()
%F16AOPENFORREVIEW Load the whole F-16A RFLP model so traceability is visible.
%   Loads all three System Composer models, all four requirement sets and every
%   verification link set, then opens the Requirements Editor. Run this before
%   reviewing requirements.
%
%   WHY THIS IS NEEDED: a link lives in the link set of the artifact it points
%   FROM, never in the requirement set. An "Implemented by" link therefore ships
%   with the MODEL and a "Verified by" link with the TEST, so a requirement set
%   opened on its own shows neither -- REQ_F16A_020/023/024/025 (L) and
%   REQ_F16A_022/026 + REQ_F16A_P01 (P) read as un-implemented, and every Verify
%   link is invisible. Loading the models and the test link sets makes them appear.
%
%   Regenerating is link-safe: slreq.new builds each requirement set from
%   scratch, but a full rebuild of all four was measured to leave the hand-made
%   Verify links still resolving. Regenerate without fear for them.
%
%   The closing report is READ from the artifacts, not asserted: it names the
%   requirements that carry a Verify link and the tests still waiting for one to
%   be made by hand (docs/README.md, "Verification links are added manually").

thisDir = f16aRoot();   % example root, via anchor (f16aRoot.m) -- not this file's folder
vDir    = fullfile(thisDir,"verification");
addpath(thisDir, ...
    fullfile(thisDir,"requirements"), fullfile(thisDir,"functions"), ...
    fullfile(thisDir,"logical"), fullfile(thisDir,"physical"), vDir);

% Loading a model loads its requirement link set (the Implement links).
systemcomposer.loadModel("F16A_Functional");
systemcomposer.loadModel("F16A_Logical");
systemcomposer.loadModel("F16A_Physical");

% Load every requirement set (base + the three derived sets).
reqFiles = ["f16a.slreqx","f16a_functional_derived.slreqx", ...
    "f16a_logical_derived.slreqx","f16a_physical_derived.slreqx"];
for f = reqFiles
    slreq.load(fullfile(thisDir,"requirements",f));
end

% Load the TESTS' link sets -- the Verify links. Globbed rather than named on
% purpose: a test's link set exists only once its Verify link has been made by
% hand, so a literal filename would error on a checkout where it has not been,
% and a fourth verification test would need an edit here to be seen.
lnkSets = dir(fullfile(vDir,"*~m.slmx"));
for k = 1:numel(lnkSets)
    slreq.load(fullfile(lnkSets(k).folder, lnkSets(k).name));
end

fprintf("Loaded 3 models, %d requirement sets, %d verification link set(s).\n", ...
    numel(reqFiles), numel(lnkSets));
reportVerifyLinks(vDir);

try slreq.editor(); catch, end   % open the editor if a display is available

end

% =====================================================================
function reportVerifyLinks(vDir)
%REPORTVERIFYLINKS Report the Verify links as they are, not as they were.
%   Two halves, both measured from what is loaded rather than from a typed list
%   that would drift: the requirements now carrying an inbound Verify link, and
%   the verification tests with no link set at all -- i.e. whose link nobody has
%   made yet. In R2026a a MATLAB test cannot be a link SOURCE programmatically,
%   so the second list is hand work in the Requirements Editor and nothing here
%   can close it.
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
    fprintf("Still to link BY HAND in the Requirements Editor: %s " + ...
        "(no link set on disk).\n", strjoin(sort(unlinked), ", "));
end
end
