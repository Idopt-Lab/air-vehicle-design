function F16AOpenForReview()
%F16AOPENFORREVIEW Load the whole F-16A RFLP model so traceability is visible.
%   Loads all three System Composer models and all requirement sets, then
%   opens the Requirements Editor. Run this before reviewing requirements.
%
%   WHY THIS IS NEEDED: in Requirements Toolbox, an "Implemented by" link is
%   stored in the link set of the IMPLEMENTING artifact (the model), not the
%   requirement set. So if you open only f16a.slreqx, the Functional /
%   Logical / Physical model link sets are not loaded, and the requirements
%   look un-implemented -- e.g. REQ_F16A_020/023/024/025 (Logical) and
%   REQ_F16A_022/026 + REQ_F16A_P01 (Physical) show no implement link. Once
%   the models are loaded (below), those links appear. "Verified by" links
%   live in the requirement set's own link set, so they show either way.

thisDir = fileparts(mfilename("fullpath"));
addpath(thisDir, ...
    fullfile(thisDir,"requirements"), fullfile(thisDir,"architecture"), ...
    fullfile(thisDir,"logical"), fullfile(thisDir,"physical"));

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

fprintf(['Loaded 3 models + %d requirement sets.\n' ...
    'The Requirements Editor now shows every Implement and Verify link.\n' ...
    'Try: REQ_F16A_022 (Implemented by Airframe; Verified by ' ...
    'F16APhysicalVerificationTest) and REQ_F16A_P01.\n'], numel(reqFiles));

try, slreq.editor(); catch, end   % open the editor if a display is available

end
