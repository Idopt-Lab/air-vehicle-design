%RUN_ALL_TESTS  Execute the full aircraft-sizing test suite.
%
%   Run from the repository root:
%     >> cd('<repo>/code/aircraft-sizing')
%     >> run_all_tests
%
%   Returns 0 (success) when all tests pass; non-zero otherwise.
%   Each discipline step adds its test file here as it is completed.

root = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(root, '..', 'src')));
addpath(genpath(fullfile(root, '..', 'baseline')));
addpath(genpath(fullfile(root, '..', 'examples')));
% VnV/BrandtF16A/Brandt*.m classes are wrapped by the mixed_fidelity_tests
% adapters (BrandtGeomAdapter etc.) -- without this, any test constructing
% one fails with "Unrecognized function or variable 'BrandtGeometry'" even
% though the adapter code itself is correct.
addpath(genpath(fullfile(root, '..', 'VnV')));
addpath(genpath(root));

suite = matlab.unittest.TestSuite.fromFolder(root, 'IncludingSubfolders', true);

% mixed_fidelity_tests/ lives under examples/, not under this tests/ root,
% so fromFolder above never sees it -- discovered separately and merged in.
mixedFidelityDir = fullfile(root, '..', 'examples', 'F16A', 'mixed_fidelity_tests');
if exist(mixedFidelityDir, 'dir')
    suite = [suite, matlab.unittest.TestSuite.fromFolder(mixedFidelityDir, 'IncludingSubfolders', true)];
end

runner = matlab.unittest.TestRunner.withTextOutput();
results = runner.run(suite);

disp(results.table());

if any([results.Failed])
    error('run_all_tests:failures', '%d test(s) failed.', sum([results.Failed]));
end